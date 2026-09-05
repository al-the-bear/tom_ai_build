// Sample instantiation-coverage gate (SOM §19).
//
// The nine-way parity proof is bounded by what the shared samples instantiate:
// a model structure no sample populates is generated into all nine languages
// and compared nine ways against golden logs that never mention it, so the
// bound is invisible from the logs themselves. This check makes the bound a
// measured, enforced quantity instead of a prose number that decays.
//
// What it measures — both metrics, from the full model meta
// (`tom_som_dart_v0/meta/spec_model.meta.json`, held fresh by the clitool's
// model-freshness stamp), walking the class graph from the
// `D00SolutionBlueprint` root (complex field `type`, section field
// `sectionType`, list field `elementType`):
//
//   * list structures — every `list` field's `sectionId` (the `…-LST` ids);
//     a structure is instantiated when its id appears as a mapping key in any
//     `samples/*.docspecs.yaml`.
//   * section ids — every reachable class or field `sectionId`; covered under
//     the same key-appearance rule.
//
// What it enforces — staged totality. The committed manifest
// (`tool/sample_coverage_manifest.yaml`) is the *remaining set*: every
// reachable id the samples are known not to instantiate yet. The gate is red
// when reality and the manifest disagree in either direction:
//
//   * an uncovered id missing from the manifest — a structure was added to the
//     model and nobody instantiated it (nor consciously recorded the gap);
//   * a manifest id that is now covered — coverage only ratchets forward; the
//     entry must be deleted, so the manifest shrinks toward empty;
//   * a manifest id that is no longer reachable — the structure was removed or
//     renamed and the manifest is stale.
//
// An empty manifest is full coverage. Growing the samples and deleting the
// corresponding manifest lines is the act that brings a structure under the
// parity proof (SOM §19).
//
// `--write-manifest` regenerates the manifest from the current model + samples.
// That is a deliberate act whose diff is reviewed — added lines are newly
// recorded gaps, removed lines are coverage gained — never a way to silence a
// red run without looking at what went red.
//
// Usage: dart tool/check_sample_coverage.dart [--write-manifest] [confDir]
//   confDir defaults to this script's parent (tom_som_conformance).
library;

import 'dart:convert';
import 'dart:io';

/// The document root the samples are instances of. Samples for other roots
/// would extend this walk, not replace it.
const _root = 'D00SolutionBlueprint';

void main(List<String> args) {
  var writeManifest = false;
  String? confArg;
  for (final a in args) {
    if (a == '--write-manifest') {
      writeManifest = true;
    } else if (confArg == null) {
      confArg = a;
    } else {
      stderr.writeln('unexpected argument: $a');
      exit(2);
    }
  }

  final confDir = confArg ??
      Directory(File(Platform.script.toFilePath()).parent.path).parent.path;
  final metaFile = File(
      '${Directory(confDir).parent.path}/tom_som_dart_v0/meta/spec_model.meta.json');
  final samplesDir = Directory('$confDir/samples');
  final manifestFile = File('$confDir/tool/sample_coverage_manifest.yaml');

  if (!metaFile.existsSync()) {
    stderr.writeln('model meta missing: ${metaFile.path}');
    exit(1);
  }
  if (!samplesDir.existsSync()) {
    stderr.writeln('samples folder missing: ${samplesDir.path}');
    exit(1);
  }

  // --- Walk the model: reachable list structures and section ids. ---
  final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
  final classes = meta['classes'] as Map<String, dynamic>;
  final listIds = <String>{};
  final sectionIds = <String>{};
  final visited = <String>{};

  void walk(String type) {
    if (!visited.add(type)) return;
    final cls = classes[type] as Map<String, dynamic>?;
    if (cls == null) return;
    final classId = cls['sectionId'] as String?;
    if (classId != null) sectionIds.add(classId);
    for (final f in (cls['fields'] as List<dynamic>? ?? const [])) {
      final field = f as Map<String, dynamic>;
      final fieldId = field['sectionId'] as String?;
      if (fieldId != null) sectionIds.add(fieldId);
      switch (field['kind'] as String) {
        case 'complex':
          walk(field['type'] as String);
        case 'section':
          walk(field['sectionType'] as String);
        case 'list':
          listIds.add(field['sectionId'] as String);
          walk(field['elementType'] as String);
      }
    }
  }

  walk(_root);

  // --- Scan the samples: every id token appearing as a mapping key. ---
  final sampleFiles = samplesDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.docspecs.yaml'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (sampleFiles.isEmpty) {
    stderr.writeln('no *.docspecs.yaml samples under ${samplesDir.path}');
    exit(1);
  }
  final keyTokens = <String>{};
  for (final f in sampleFiles) {
    keyTokens.addAll(_scanKeyTokens(f.readAsLinesSync()));
  }

  final coveredLists = listIds.where(keyTokens.contains).toSet();
  final coveredSections = sectionIds.where(keyTokens.contains).toSet();
  final uncoveredLists = listIds.difference(coveredLists);
  final uncoveredSections = sectionIds.difference(coveredSections);

  if (writeManifest) {
    manifestFile.writeAsStringSync(
        _renderManifest(uncoveredLists, uncoveredSections));
    stdout.writeln('wrote ${manifestFile.path}');
    _report(listIds, coveredLists, sectionIds, coveredSections, sampleFiles);
    return;
  }

  // --- Compare against the committed remaining set. ---
  if (!manifestFile.existsSync()) {
    stderr.writeln('manifest missing: ${manifestFile.path}');
    stderr.writeln('run with --write-manifest to create it, and review '
        'the result before committing.');
    exit(1);
  }
  final manifest = _readManifest(manifestFile.readAsLinesSync());
  final manifestLists = manifest.$1;
  final manifestSections = manifest.$2;

  var failures = 0;
  void fail(String metric, String verdict, Iterable<String> ids, String hint) {
    final sorted = ids.toList()..sort();
    if (sorted.isEmpty) return;
    failures += sorted.length;
    stderr.writeln('$metric — $verdict (${sorted.length}): $hint');
    for (final id in sorted) {
      stderr.writeln('  $id');
    }
  }

  fail(
      'list structures',
      'uncovered and not in the manifest',
      uncoveredLists.difference(manifestLists),
      'instantiate them in a sample, or record the gap in '
          '${manifestFile.path} (reviewed, not reflexive)');
  fail(
      'list structures',
      'in the manifest but now covered',
      manifestLists.intersection(coveredLists),
      'coverage only ratchets forward — delete these manifest lines');
  fail(
      'list structures',
      'in the manifest but not reachable in the model',
      manifestLists.difference(listIds),
      'the structure was removed or renamed — delete these manifest lines');
  fail(
      'section ids',
      'uncovered and not in the manifest',
      uncoveredSections.difference(manifestSections),
      'instantiate them in a sample, or record the gap in '
          '${manifestFile.path} (reviewed, not reflexive)');
  fail(
      'section ids',
      'in the manifest but now covered',
      manifestSections.intersection(coveredSections),
      'coverage only ratchets forward — delete these manifest lines');
  fail(
      'section ids',
      'in the manifest but not reachable in the model',
      manifestSections.difference(sectionIds),
      'the id was removed or renamed — delete these manifest lines');

  _report(listIds, coveredLists, sectionIds, coveredSections, sampleFiles);
  if (failures > 0) {
    stderr.writeln('FAILED: $failures disagreement(s) between the samples, '
        'the model, and the manifest.');
    exit(1);
  }
  stdout.writeln('OK — the manifest is exactly the remaining set.');
}

void _report(Set<String> listIds, Set<String> coveredLists,
    Set<String> sectionIds, Set<String> coveredSections, List<File> samples) {
  stdout.writeln('samples: ${samples.map((f) => f.uri.pathSegments.last).join(', ')}');
  stdout.writeln('list structures instantiated: '
      '${coveredLists.length}/${listIds.length} '
      '(${listIds.length - coveredLists.length} remaining)');
  stdout.writeln('section ids instantiated:     '
      '${coveredSections.length}/${sectionIds.length} '
      '(${sectionIds.length - coveredSections.length} remaining)');
}

/// Every token appearing as the id part of a mapping key, skipping the inside
/// of block scalars so an id mentioned in prose never counts as instantiated.
///
/// The hierarchical format (SOM §12) writes keys as `<ID> <fieldName>:`,
/// `<ID>:` or `<fieldName>:`; block scalars are opened by a value starting
/// with `|` or `>` and run while lines are blank or indented deeper than the
/// opening key.
Set<String> _scanKeyTokens(List<String> lines) {
  final tokens = <String>{};
  final keyPattern = RegExp(r'^([A-Za-z0-9_.\-]+)(?: [A-Za-z0-9_]+)?:(.*)$');
  final idPattern = RegExp(r'^[A-Z][A-Z0-9\-]*$');
  int? blockIndent; // indent of the key that opened the current block scalar
  for (final line in lines) {
    if (line.trim().isEmpty) continue; // blank: neutral inside and outside
    final indent = line.length - line.trimLeft().length;
    if (blockIndent != null) {
      if (indent > blockIndent) continue; // still inside the block scalar
      blockIndent = null;
    }
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('#')) continue;
    final m = keyPattern.firstMatch(trimmed);
    if (m == null) continue;
    final token = m.group(1)!;
    if (idPattern.hasMatch(token)) tokens.add(token);
    final rest = m.group(2)!.trim();
    if (rest.startsWith('|') || rest.startsWith('>')) blockIndent = indent;
  }
  return tokens;
}

String _renderManifest(Set<String> lists, Set<String> sections) {
  final b = StringBuffer()
    ..writeln('# Sample instantiation-coverage manifest (SOM §19).')
    ..writeln('#')
    ..writeln('# The remaining set: every model structure reachable from the')
    ..writeln('# D00SolutionBlueprint root that no sample under samples/ yet')
    ..writeln('# instantiates. Held against reality by')
    ..writeln('# tool/check_sample_coverage.dart — an uncovered id missing here,')
    ..writeln('# an entry that became covered, or an entry the model no longer')
    ..writeln('# reaches all fail the gate. Coverage only ratchets forward:')
    ..writeln('# growing the samples deletes lines here, and an empty manifest')
    ..writeln('# is full coverage.')
    ..writeln('#')
    ..writeln('# Regenerate deliberately with:')
    ..writeln('#   dart tool/check_sample_coverage.dart --write-manifest')
    ..writeln('# and review the diff: added lines are newly recorded gaps,')
    ..writeln('# removed lines are coverage gained.')
    ..writeln('uncoveredListStructures:');
  for (final id in lists.toList()..sort()) {
    b.writeln('  - $id');
  }
  b.writeln('uncoveredSectionIds:');
  for (final id in sections.toList()..sort()) {
    b.writeln('  - $id');
  }
  return b.toString();
}

/// Reads the two id lists back. The manifest is machine-written simple YAML —
/// two keys, `- id` items, `#` comments — so no YAML package is needed (this
/// tool, like its neighbours, is dependency-free).
(Set<String>, Set<String>) _readManifest(List<String> lines) {
  final lists = <String>{};
  final sections = <String>{};
  Set<String>? current;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    if (trimmed == 'uncoveredListStructures:') {
      current = lists;
    } else if (trimmed == 'uncoveredSectionIds:') {
      current = sections;
    } else if (trimmed.startsWith('- ') && current != null) {
      current.add(trimmed.substring(2).trim());
    } else {
      stderr.writeln('unrecognized manifest line: $line');
      exit(1);
    }
  }
  return (lists, sections);
}
