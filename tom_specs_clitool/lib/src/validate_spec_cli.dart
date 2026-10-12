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

  /// The section id or document path concerned, when the tier knows one.
  final String? location;

  /// The 1-based line of the file or rendition, when the tier knows one.
  final int? line;

  /// One sentence.
  final String message;

  /// Creates a finding.
  const SpecValidationFinding({
    required this.tier,
    required this.code,
    required this.message,
    this.location,
    this.line,
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
    if (results.rest.length != 1) {
      throw const _UsageError(
        'give exactly one document: a *.docspecs.yaml or a SOM-rendered *.md.',
        showUsage: true,
      );
    }
    final path = results.rest.single;
    final file = File(path);
    if (!file.existsSync()) throw _UsageError('document not found: $path');
    final text = file.readAsStringSync();
    final isMarkdown = path.toLowerCase().endsWith('.md');
    final specModel = model ?? somSpecModel;

    final root = _resolveRoot(
      specModel,
      results.option('root'),
      text,
      isMarkdown,
    );
    final schemaId = specSchemaIdFor(root);

    final findings = <SpecValidationFinding>[];
    final notRun = <Map<String, Object?>>[];

    // Tier 1 — decode.
    SpecDocument? doc;
    if (isMarkdown) {
      final imported = SpecDocument.fromMarkdown(text, specModel);
      doc = imported.document;
      for (final r in imported.rejections) {
        findings.add(
          SpecValidationFinding(
            tier: 'decode',
            code: r.reason.name,
            line: r.line,
            message: r.message,
          ),
        );
      }
    } else {
      try {
        doc = SpecDocument.fromYaml(
          text,
          buildSomMetaTree(specModel, rootType: root.type),
        );
      } on SpecYamlFormatException catch (e) {
        findings.add(
          SpecValidationFinding(
            tier: 'decode',
            code: 'format',
            message: e.message,
          ),
        );
      }
    }

    String? markdown;
    if (doc == null) {
      for (final tier in ['schema', 'instance']) {
        notRun.add({
          'tier': tier,
          'reason': 'the document did not decode, so there is nothing to check',
        });
      }
    } else {
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
        for (final v in DocSpecsValidator(
          somDocSpecsSchema(schemaId),
        ).validateMarkdown(markdown)) {
          findings.add(
            SpecValidationFinding(
              tier: 'schema',
              code: v.rule.name,
              location: v.sectionId ?? v.path,
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
            'document': path,
            'root': results.option('root'),
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
                'file': path,
                'line': f.line,
                'location': f.location,
                'message': f.message,
              },
          ],
        }),
      );
    } else {
      stdoutSink.writeln(
        'validate_spec $path — root ${root.type} (${root.sectionId}), '
        'schema $schemaId',
      );
      for (final f in findings) {
        final where = [
          if (f.line != null) 'line ${f.line}',
          if (f.location != null) f.location!,
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
  sink.writeln('Usage: validate_spec <document> [options]');
  sink.writeln();
  sink.writeln(
    'Checks one TomSpecs document — a *.docspecs.yaml or a SOM-rendered *.md — '
    'on three tiers: decode, the DocSpecs schema over its rendition, and the '
    'instance tier. All three run every time. Exit 0 clean, 1 with findings, '
    '2 on bad usage.',
  );
  sink.writeln();
  sink.writeln(parser.usage);
}
