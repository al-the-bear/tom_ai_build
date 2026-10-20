/// The `validate_spec` command: one project's TomSpecs document checked on all
/// three tiers, so a project never writes its own runner.
///
/// The tiers ask disjoint questions, so all three run every time:
///
/// 1. **decode** — the file loads against the object model: every key of a
///    `*.docspecs.yaml` sits where the model says it may; every block of a
///    SOM-rendered `*.md` resolves to a section (SOM §11.7);
/// 2. **schema** — the document's markdown rendition against its generated
///    DocSpecs schema: required sections and required form fields
///    (completeness, SOM §13);
/// 3. **instance** — `validateDocument`: field kinds, enum values, list
///    minima, `refersTo` resolution (values, SOM §9).
///
/// The root is detected from the document — the root key of a YAML file, the
/// title id of a markdown file — and `--root` overrides it. The model and the
/// fourteen schemas are the ones `tom_som_dart_v0` embeds.
///
/// Exit codes: `0` all tiers clean, `1` at least one finding, `2` bad usage or
/// an unreadable file. `--json` writes the same result in the shape
/// `validate_codespecs --json` uses.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_schemas.dart';
import 'package:yaml/yaml.dart';

/// The `format` of the `--json` report.
const String kSpecValidationFormat = 'spec-validation';

/// The `formatVersion` of the `--json` report. Bumped only on a breaking
/// change.
const int kSpecValidationFormatVersion = 1;

/// The three tiers, in the order they run.
const List<String> kSpecValidationTiers = ['decode', 'schema', 'instance'];

class _UsageError implements Exception {
  final String message;
  final bool showUsage;
  const _UsageError(this.message, {this.showUsage = false});
}

/// One finding of one tier.
class SpecValidationFinding {
  /// `decode`, `schema` or `instance`.
  final String tier;

  /// The rule (schema), validation code (instance) or rejection reason
  /// (decode).
  final String code;

  /// The document path concerned, when the tier knows one. A schema finding
  /// names the path of the section its rendition line belongs to, not only a
  /// section id, because section ids repeat across a document.
  final String? location;

  /// The DocSpecs section id a schema finding names, when it has one.
  final String? sectionId;

  /// The 1-based line of the file or rendition, when the tier knows one.
  final int? line;

  /// The fragment a decode finding belongs to; `null` for a finding about
  /// the (assembled) document as a whole.
  final String? file;

  /// One sentence.
  final String message;

  /// Creates a finding.
  const SpecValidationFinding({
    required this.tier,
    required this.code,
    required this.message,
    this.location,
    this.sectionId,
    this.line,
    this.file,
  });
}

/// The option set — read by the README correspondence test.
ArgParser validateSpecParser() => ArgParser()
  ..addOption(
    'root',
    help:
        'The document root, as a type name (D00SolutionBlueprint) or section '
        'id (SBP). Default: detected from the document.',
  )
  ..addOption(
    'assembled-out',
    help:
        'Write the assembled document as a *.docspecs.yaml to this file. With '
        'one input it is that document, re-encoded.',
  )
  ..addOption(
    'markdown-out',
    help: 'Also write the document\'s markdown rendition to this file.',
  )
  ..addFlag(
    'json',
    help:
        'Write one JSON report to stdout (format `$kSpecValidationFormat`, '
        'version $kSpecValidationFormatVersion), in the shape '
        'validate_codespecs --json uses. Exit codes are unchanged.',
    negatable: false,
  )
  ..addFlag(
    'help',
    abbr: 'h',
    help: 'Show usage information.',
    negatable: false,
  );

/// Runs the command over [arguments] and returns the exit code.
Future<int> runValidateSpec(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
  SpecModel? model,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  final parser = validateSpecParser();
  try {
    final ArgResults results;
    try {
      results = parser.parse(arguments);
    } on FormatException catch (e) {
      throw _UsageError(e.message, showUsage: true);
    }
    if (results.flag('help')) {
      _printUsage(parser, stdoutSink);
      return 0;
    }
    if (results.rest.isEmpty) {
      throw const _UsageError(
        'give at least one document: a *.docspecs.yaml or a SOM-rendered *.md. '
        'Several are fragments of one document and are assembled first.',
        showUsage: true,
      );
    }
    final specModel = model ?? somSpecModel;
    final paths = results.rest;
    final texts = <String, String>{};
    for (final path in paths) {
      if (texts.containsKey(path)) {
        throw _UsageError('$path is given twice');
      }
      final file = File(path);
      if (!file.existsSync()) throw _UsageError('document not found: $path');
      texts[path] = file.readAsStringSync();
    }

    // Every fragment must be the same root: an assembly of two documents is
    // not a document.
    final roots = {
      for (final path in paths)
        path: _resolveRoot(
          specModel,
          results.option('root'),
          texts[path]!,
          path.toLowerCase().endsWith('.md'),
        ),
    };
    final root = roots[paths.first]!;
    for (final MapEntry(key: path, value: r) in roots.entries) {
      if (r.type != root.type) {
        throw _UsageError(
          '$path is a ${r.type}, but ${paths.first} is a ${root.type} — '
          'fragments of one document share its root',
        );
      }
    }
    final schemaId = specSchemaIdFor(root);
    final tree = buildSomMetaTree(specModel, rootType: root.type);

    final findings = <SpecValidationFinding>[];
    final notRun = <Map<String, Object?>>[];

    // Tier 1 — decode every fragment, then assemble them.
    final decoded = <String, SpecDocument>{};
    for (final path in paths) {
      final text = texts[path]!;
      if (path.toLowerCase().endsWith('.md')) {
        final imported = SpecDocument.fromMarkdown(text, specModel);
        decoded[path] = imported.document;
        for (final r in imported.rejections) {
          findings.add(
            SpecValidationFinding(
              tier: 'decode',
              code: r.reason.name,
              line: r.line,
              file: path,
              message: r.message,
            ),
          );
        }
      } else {
        try {
          decoded[path] = SpecDocument.fromYaml(text, tree);
        } on SpecYamlFormatException catch (e) {
          findings.add(
            SpecValidationFinding(
              tier: 'decode',
              code: 'format',
              file: path,
              message: e.message,
            ),
          );
        }
      }
    }

    SpecDocument? doc;
    String? notRunReason;
    if (decoded.length < paths.length) {
      notRunReason = paths.length == 1
          ? 'the document did not decode, so there is nothing to check'
          : 'a fragment did not decode, so there is no assembled document to '
                'check';
    } else if (paths.length == 1) {
      doc = decoded[paths.single];
    } else {
      final assembly = SpecDocument.assemble(decoded);
      for (final o in assembly.overlaps) {
        findings.add(
          SpecValidationFinding(
            tier: 'decode',
            code: 'overlap',
            location: o.field == null ? o.path : '${o.path}/${o.field}',
            message: o.message,
          ),
        );
      }
      doc = assembly.document;
      if (doc == null) {
        notRunReason =
            'the fragments overlap, so they do not assemble into one document';
      }
    }

    String? markdown;
    if (doc == null) {
      for (final tier in ['schema', 'instance']) {
        notRun.add({'tier': tier, 'reason': notRunReason});
      }
    } else {
      final assembledOut = results.option('assembled-out');
      if (assembledOut != null) {
        File(assembledOut).writeAsStringSync(
          SpecDocumentYaml.encode(
            document: doc,
            tree: tree,
            modelVersion: decoded.values.first.modelVersion,
          ),
        );
      }
      // Rendered once: the same text the schema tier judges is what
      // `--markdown-out` writes, so a finding's line points into that file.
      markdown = doc.toMarkdown(specModel, rootType: root.type);
      final out = results.option('markdown-out');
      if (out != null) File(out).writeAsStringSync(markdown);

      // Tier 2 — the DocSpecs schema over the rendition.
      if (!somDocSpecsSchemaIds.contains(schemaId)) {
        notRun.add({
          'tier': 'schema',
          'reason': 'no DocSpecs schema `$schemaId` ships for ${root.type}',
        });
      } else {
        for (final v in validateSpecDocument(
          specModel,
          doc,
          somDocSpecsSchema(schemaId),
          rootType: root.type,
        )) {
          findings.add(
            SpecValidationFinding(
              tier: 'schema',
              code: v.rule.name,
              location: v.path ?? v.sectionId,
              sectionId: v.sectionId,
              line: v.line,
              message: v.message,
            ),
          );
        }
      }

      // Tier 3 — the instance tier.
      for (final e in validateDocument(specModel, doc)) {
        findings.add(
          SpecValidationFinding(
            tier: 'instance',
            code: e.code.name,
            location: e.path,
            message: e.message,
          ),
        );
      }
    }

    final passed = findings.isEmpty && notRun.isEmpty;
    final counts = {
      for (final t in kSpecValidationTiers)
        t: findings.where((f) => f.tier == t).length,
    };
    final summary = passed
        ? 'validate_spec: all three tiers clean'
        : 'validate_spec: ${findings.length} finding(s) — '
              '${kSpecValidationTiers.map((t) => '$t ${counts[t]}').join(', ')}'
              '${notRun.isEmpty ? '' : '; ${notRun.length} tier(s) not run'}';

    if (results.flag('json')) {
      stdoutSink.writeln(
        const JsonEncoder.withIndent('  ').convert({
          'format': kSpecValidationFormat,
          'formatVersion': kSpecValidationFormatVersion,
          'inputs': {
            'documents': paths,
            'root': results.option('root'),
            'assembled-out': results.option('assembled-out'),
            'markdown-out': results.option('markdown-out'),
          },
          'root': {
            'type': root.type,
            'sectionId': root.sectionId,
            'title': root.title,
            'schemaId': schemaId,
          },
          'passed': passed,
          'summary': summary,
          'tiers': [
            for (final t in kSpecValidationTiers)
              {
                'tier': t,
                'ran': !notRun.any((n) => n['tier'] == t),
                'findings': counts[t],
              },
          ],
          'notRun': notRun,
          'violations': [
            for (final f in findings)
              {
                'tier': f.tier,
                'code': f.code,
                'severity': 'error',
                // A decode finding names its fragment; a schema or instance
                // finding is about the (assembled) document, so it names the
                // file only when there is a single one.
                'file': f.file ?? (paths.length == 1 ? paths.single : null),
                'line': f.line,
                'location': f.location,
                'sectionId': f.sectionId,
                'message': f.message,
              },
          ],
        }),
      );
    } else {
      stdoutSink.writeln(
        'validate_spec ${paths.join(' + ')} — root ${root.type} '
        '(${root.sectionId}), schema $schemaId'
        '${paths.length > 1 ? ' — ${paths.length} fragments assembled' : ''}',
      );
      for (final f in findings) {
        final where = [
          if (f.file != null && paths.length > 1) f.file!,
          if (f.line != null) 'line ${f.line}',
          if (f.location != null) f.location!,
          if (f.sectionId != null && f.sectionId != f.location)
            '[${f.sectionId}]',
        ].join(' ');
        stderrSink.writeln(
          '${f.tier.toUpperCase().padRight(8)} [${f.code}]'
          '${where.isEmpty ? '' : ' $where'}: ${f.message}',
        );
      }
      for (final t in kSpecValidationTiers) {
        final skipped = notRun.where((n) => n['tier'] == t).firstOrNull;
        stdoutSink.writeln(
          '${t.padRight(9)}${skipped != null ? 'not run — ${skipped['reason']}' : '${counts[t]} finding(s)'}',
        );
      }
      if (results.option('markdown-out') != null && markdown != null) {
        stdoutSink.writeln('rendition ${results.option('markdown-out')}');
      }
      stdoutSink.writeln(summary);
    }
    return passed ? 0 : 1;
  } on _UsageError catch (e) {
    stderrSink.writeln('Error: ${e.message}');
    if (e.showUsage) {
      stderrSink.writeln();
      _printUsage(parser, stderrSink);
    }
    return 2;
  }
}

/// The DocSpecs schema id of [root]: its `@Document` title, lower-cased and
/// hyphenated (`Solution Blueprint` → `solution-blueprint`), the same
/// derivation the schema generator uses.
String specSchemaIdFor(SpecRoot root) => root.title
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// The root [explicit] names, else the one the document declares: the key
/// under `document:` in a YAML file (`SBP D00SolutionBlueprint`), the id of the
/// title heading in a markdown rendition (`# <!--[SBP]--> …`).
/// The root of a specification document: [explicit] (a root type or section
/// id) when given, else the one the text declares — the first heading of a
/// Markdown rendition, the `document:` key of a `*.docspecs.yaml`. Throws an
/// [ArgumentError] naming the problem when it cannot be found.
SpecRoot resolveSpecDocumentRoot(
  SpecModel model,
  String? explicit,
  String text, {
  required bool isMarkdown,
}) {
  try {
    return _resolveRoot(model, explicit, text, isMarkdown);
  } on _UsageError catch (e) {
    throw ArgumentError(e.message);
  }
}

SpecRoot _resolveRoot(
  SpecModel model,
  String? explicit,
  String text,
  bool isMarkdown,
) {
  SpecRoot? find(String token) {
    for (final r in model.roots) {
      if (r.type == token || r.sectionId == token) return r;
    }
    return null;
  }

  String known() =>
      model.roots.map((r) => '${r.type} (${r.sectionId})').join(', ');

  if (explicit != null) {
    final r = find(explicit);
    if (r == null) {
      throw _UsageError(
        '--root `$explicit` names no root; the roots are ${known()}',
      );
    }
    return r;
  }

  final tokens = <String>[];
  if (isMarkdown) {
    final m = RegExp(
      r'^#\s+<!--\[([^\]]+)\]-->',
      multiLine: true,
    ).firstMatch(text);
    if (m != null) tokens.add(m.group(1)!);
  } else {
    Object? parsed;
    try {
      parsed = loadYaml(text);
    } on YamlException catch (e) {
      throw _UsageError('the document is not valid YAML: ${e.message}');
    }
    final document = parsed is YamlMap ? parsed['document'] : null;
    if (document is YamlMap) {
      for (final key in document.keys) {
        tokens.addAll('$key'.split(RegExp(r'\s+')).reversed);
      }
    }
  }
  for (final t in tokens) {
    final r = find(t);
    if (r != null) return r;
  }
  throw _UsageError(
    'cannot tell which root the document is — name it with --root; the roots '
    'are ${known()}',
  );
}

void _printUsage(ArgParser parser, StringSink sink) {
  sink.writeln('Usage: validate_spec <document> [<fragment> ...] [options]');
  sink.writeln();
  sink.writeln(
    'Checks one TomSpecs document — a *.docspecs.yaml or a SOM-rendered *.md — '
    'on three tiers: decode, the DocSpecs schema over its rendition, and the '
    'instance tier. All three run every time. Several documents are fragments '
    'of one document: they are assembled first — a place two fragments both '
    'write is refused — and references are judged on the assembly. Exit 0 '
    'clean, 1 with findings, 2 on bad usage.',
  );
  sink.writeln();
  sink.writeln(parser.usage);
}
