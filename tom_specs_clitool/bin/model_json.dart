import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Exports the tom_specs_model class graph as JSON.
///
/// Two modes, because a **committed** copy of this export must carry the model's
/// own version stamp and an ad-hoc one need not:
///
///   * `--target editor|reviewer` — refreshes a committed asset. The path and
///     the stamp both follow from the target, so neither can be given wrongly;
///     the stamp is always derived from the model's `version.versioner.dart`.
///   * `--package` + `--output` — an ad-hoc export anywhere else, freely
///     stampable via `--model-version` / `--model-label`. Pointing it at a
///     committed asset is refused: use `--target` for those.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'target',
      allowed: [for (final t in ModelJsonTarget.values) t.id],
      help: 'Refresh a committed spec_model.json asset. Determines both the '
          'output path and the version stamp; cannot be combined with '
          '--output / --model-version / --model-label.',
    )
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Path to the target Dart package (its lib/ directory is scanned). '
          'With --target, defaults to the sibling tom_specs_model package.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output JSON file path (ad-hoc exports only).',
    )
    ..addOption(
      'model-version',
      help: 'S2 model-version counter to stamp into the JSON (integer). '
          'Ad-hoc exports only. Default: 0.',
    )
    ..addOption(
      'model-label',
      help: 'Human-readable build label for the model version stamp '
          '(ad-hoc exports only).',
    )
    ..addFlag('help', abbr: 'h', help: 'Show usage information.', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/model_json.dart --target editor|reviewer');
    stdout.writeln('       dart run bin/model_json.dart '
        '--package <path> --output <file.json>');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final containerRoot = _containerRoot();
  final targetId = results.option('target');
  final target = targetId == null ? null : ModelJsonTarget.byId(targetId);

  final String packagePath;
  final String outputPath;
  final ModelJsonStamp stamp;

  if (target != null) {
    for (final opt in const ['output', 'model-version', 'model-label']) {
      if (results.wasParsed(opt)) {
        _fail('--$opt cannot be combined with --target: the ${target.id} '
            'asset owns its path and its version stamp.');
      }
    }
    packagePath = p.normalize(p.absolute(results.option('package') ??
        p.join(containerRoot, 'tom_ai', 'ai_build', 'tom_specs_model')));
    outputPath = target.outputPathIn(containerRoot);
    try {
      stamp = ModelJsonStamp.from(readModelVersionStamp(packagePath));
    } on ModelVersionStampException catch (e) {
      _fail(e.message);
    }
  } else {
    if (results.option('package') == null || results.option('output') == null) {
      _fail('Give either --target <${ModelJsonTarget.values.map((t) => t.id).join('|')}> '
          'or both --package and --output.');
    }
    packagePath = p.normalize(p.absolute(results.option('package')!));
    outputPath = p.normalize(p.absolute(results.option('output')!));
    // The guard the whole two-mode split exists for: a committed asset may only
    // be written through its target, so it cannot acquire another target's
    // stamp (or the un-stamped default) by way of a hand-written --output.
    final committed = targetForOutputPath(outputPath);
    if (committed != null) {
      _fail('$outputPath is the committed "${committed.id}" asset. '
          'Refresh it with `--target ${committed.id}` so it keeps its own '
          'version stamp.');
    }
    final version = int.tryParse(results.option('model-version') ?? '0') ?? 0;
    final label = results.option('model-label');
    stamp = ModelJsonStamp(
        version, (label?.isNotEmpty ?? false) ? label : null);
  }

  final libPath = p.join(packagePath, 'lib');
  if (!Directory(libPath).existsSync()) {
    _fail('lib/ directory not found at $libPath');
  }

  stdout.writeln('model_json: analyzing $packagePath ...');
  final driver = createAnalysisDriver(packagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);
  stdout.writeln('Found ${reader.classes.length} classes, '
      '${reader.enums.length} enums.');

  final json = ModelJsonExporter(
    reader.classes,
    modelVersion: stamp.version,
    modelVersionLabel: stamp.label,
  ).export();
  final encoded = const JsonEncoder.withIndent('  ').convert(json);

  final outFile = File(outputPath);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync('$encoded\n');

  stdout.writeln('Wrote ${json['rootCount']} roots, '
      '${json['classCount']} classes to $outputPath (model version $stamp)');
}

/// The workspace container root, derived from this script's location
/// (`<container>/tom_ai/ai_build/tom_specs_clitool/bin/model_json.dart`).
String _containerRoot() {
  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  return p.normalize(p.join(clitoolRoot, '..', '..', '..'));
}

Never _fail(String msg) {
  stderr.writeln('model_json error: $msg');
  exit(1);
}
