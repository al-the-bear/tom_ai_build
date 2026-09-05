// Exercise-sample generator (SOM §19).
//
// Emits `samples/exercise_full_model.docspecs.yaml`: a specialized exercise
// specification whose sole purpose is to instantiate every model structure
// reachable from the `D00SolutionBlueprint` root — the remainder that the
// narrative samples (Meridian, the UAM access hub) do not plausibly reach.
// Together with them it drives `tool/sample_coverage_manifest.yaml` to empty,
// which is full instantiation coverage under the sample-coverage gate
// (`tool/check_sample_coverage.dart`).
//
// The walk mirrors the gate's exactly (same meta, same root, same kind
// switch), and the emission mirrors the hierarchical format v2 the Dart codec
// writes (SOM §12), so the output both *counts* lexically and *decodes*
// through `D00SolutionBlueprint.loadFile` (gated by
// `tom_som_dart_v0/tool/verify_samples.dart`):
//
//   * every field with a `sectionId` emits its `<ID> <name>:` key once per
//     class body — this is what the gate counts;
//   * `section`/`complex` fields without a field id fall back to the target
//     class's id (`<classId> <name>:`), which is how class-level ids are
//     covered; on a revisit the key is emitted with a null value (legal — the
//     decoder early-returns on null);
//   * each class body is emitted once, at its first encounter (visited-set,
//     like the gate's walk);
//   * `list` fields emit one item: keyed by the element class's id when it
//     has one (covering that class id; any non-anonymous key is stored as the
//     item's sectionId), else by the anonymous `<stem>-1` key the codec
//     itself writes (`<listId minus -LST>-1`); scalar-element lists emit a
//     direct scalar value;
//   * `form` fields with an id emit a map with only the optional `content`
//     preamble leaf — form leaves carry no ids, so none are demanded;
//   * prose values are short plain scalars — the gate's scanner only skips
//     block-scalar bodies, and plain scalars keep the file small.
//
// This file is generated content by design: re-run after model changes,
// commit the diff. Like its neighbours the tool is dependency-free.
//
// Usage: dart tool/build_exercise_sample.dart [confDir]
//   confDir defaults to this script's parent (tom_som_conformance).
library;

import 'dart:convert';
import 'dart:io';

const _root = 'D00SolutionBlueprint';

void main(List<String> args) {
  final confDir = args.isNotEmpty
      ? args.first
      : Directory(File(Platform.script.toFilePath()).parent.path).parent.path;
  final metaFile = File(
      '${Directory(confDir).parent.path}/tom_som_dart_v0/meta/spec_model.meta.json');
  final outFile = File('$confDir/samples/exercise_full_model.docspecs.yaml');

  if (!metaFile.existsSync()) {
    stderr.writeln('model meta missing: ${metaFile.path}');
    exit(1);
  }

  final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
  final classes = meta['classes'] as Map<String, dynamic>;
  final rootClass = classes[_root] as Map<String, dynamic>?;
  if (rootClass == null) {
    stderr.writeln('root class $_root missing from ${metaFile.path}');
    exit(1);
  }

  final b = StringBuffer()
    ..writeln('# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.')
    ..writeln('#')
    ..writeln('# GENERATED exercise sample — instantiates every model structure')
    ..writeln('# reachable from the D00SolutionBlueprint root, for the sample')
    ..writeln('# instantiation-coverage gate (SOM §19). Not a narrative')
    ..writeln('# specification: every value is placeholder prose.')
    ..writeln('# Regenerate with: dart tool/build_exercise_sample.dart')
    ..writeln('version: 2')
    ..writeln('modelVersion: "1.0"')
    ..writeln('document:');

  final visited = <String>{};
  var classBodies = 0;
  var keysEmitted = 0;

  /// Emits the body of [type] into [out] at [indent].
  void emitBody(StringBuffer out, String type, int indent) {
    final cls = classes[type] as Map<String, dynamic>?;
    if (cls == null) return;
    classBodies++;
    final pad = ' ' * indent;
    for (final f in (cls['fields'] as List<dynamic>? ?? const [])) {
      final field = f as Map<String, dynamic>;
      final name = field['name'] as String;
      final fieldId = field['sectionId'] as String?;
      final kind = field['kind'] as String;
      switch (kind) {
        case 'content':
          final key = fieldId == null ? name : '$fieldId $name';
          out.writeln('$pad$key: Exercise text.');
          keysEmitted++;
        case 'form':
          if (fieldId == null) break; // id-less leaves are not demanded
          out
            ..writeln('$pad$fieldId $name:')
            ..writeln('$pad  content: Exercise form preamble.');
          keysEmitted++;
        case 'complex':
        case 'section':
          final target =
              (kind == 'complex' ? field['type'] : field['sectionType'])
                  as String;
          final targetId =
              (classes[target] as Map<String, dynamic>?)?['sectionId']
                  as String?;
          final id = fieldId ?? targetId;
          final key = id == null ? name : '$id $name';
          out.writeln('$pad$key:');
          keysEmitted++;
          if (visited.add(target)) {
            emitBody(out, target, indent + 2);
            // An empty first-visit body leaves the value null — legal for
            // section/complex nodes, so nothing to patch up.
          }
        case 'list':
          final listId = field['sectionId'] as String;
          final element = field['elementType'] as String;
          final elementCls = classes[element] as Map<String, dynamic>?;
          final elementId = elementCls?['sectionId'] as String?;
          final stem = listId.endsWith('-LST')
              ? listId.substring(0, listId.length - 4)
              : listId;
          out.writeln('$pad$listId $name:');
          keysEmitted++;
          if (elementCls == null) {
            // Scalar-element list: one direct scalar item.
            out.writeln('$pad  $stem-1: Exercise item.');
          } else {
            final itemKey = elementId ?? '$stem-1';
            if (visited.add(element)) {
              final body = StringBuffer();
              emitBody(body, element, indent + 4);
              if (body.isEmpty) {
                // Empty item bodies must be maps (`{}`), not null.
                out.writeln('$pad  $itemKey: {}');
              } else {
                out
                  ..writeln('$pad  $itemKey:')
                  ..write(body);
              }
            } else {
              out.writeln('$pad  $itemKey: {}');
            }
          }
      }
    }
  }

  final rootId = rootClass['sectionId'] as String?;
  final rootKey = rootId == null ? _root : '$rootId $_root';
  b.writeln('  $rootKey:');
  visited.add(_root);
  emitBody(b, _root, 4);

  outFile.writeAsStringSync(b.toString());
  stdout.writeln('wrote ${outFile.path}');
  stdout.writeln('class bodies emitted: $classBodies '
      '(visited ${visited.length}), keys emitted: $keysEmitted');
}
