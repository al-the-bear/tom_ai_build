import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'package',
      abbr: 'p',
      help: 'Path to the target Dart package (its lib/ directory is scanned).',
      mandatory: true,
    )
    ..addOption(
      'root-type',
      abbr: 'r',
      help: 'Name of the root class to start the outline from.',
      defaultsTo: 'D00SolutionBlueprint',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output file path. Defaults to doc/<root_type>_outline.md.',
    )
    ..addOption(
      'max-line-length',
      help: 'Maximum line length before wrapping.',
      defaultsTo: '120',
    )
    ..addFlag(
      'show-schema-annotations',
      help: 'Show schema-only annotations inline (§4.14).',
      defaultsTo: false,
    )
    ..addFlag(
      'stop-at-detailed-in',
      abbr: 'c',
      help: 'Stop tree traversal at sections annotated with @DetailedIn — '
          'show the section heading with a → DocId suffix but do not expand '
          'the sub-tree. Produces a compact high-level outline.',
      defaultsTo: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show usage information.',
      negatable: false,
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage(parser);
    exit(2);
  }

  if (results.flag('help')) {
    _printUsage(parser);
    exit(0);
  }

  final packagePath = p.normalize(p.absolute(results.option('package')!));
  final rootType = results.option('root-type')!;
  final maxLineLength = int.tryParse(results.option('max-line-length')!) ?? 120;
  final showSchemaAnnotations = results.flag('show-schema-annotations');
  final stopAtDetailedIn = results.flag('stop-at-detailed-in');

  // Default output path
  final outputPath = results.option('output') ??
      p.join(
        packagePath,
        'doc',
        '${_toSnakeCase(rootType)}_outline.md',
      );

  final libPath = p.join(packagePath, 'lib');
  if (!Directory(libPath).existsSync()) {
    stderr.writeln('Error: lib/ directory not found at $libPath');
    exit(1);
  }

  stdout.writeln('Outliner: analyzing $packagePath ...');

  // 1. Create analyzer driver with embedded SDK summary
  final driver = createAnalysisDriver(packagePath);

  // 2. Read model classes and enums
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);

  stdout.writeln(
    'Found ${reader.classes.length} classes and '
    '${reader.enums.length} enums.',
  );

  // 3. Validate model (§6)
  final validation = validateModel(reader.classes, rootType);
  if (validation.warnings.isNotEmpty) {
    stderr.writeln('');
    stderr.writeln('Model warnings:');
    for (final warning in validation.warnings) {
      stderr.writeln('  WARN: $warning');
    }
  }
  if (validation.errors.isNotEmpty) {
    stderr.writeln('');
    stderr.writeln('Model validation errors:');
    for (final error in validation.errors) {
      stderr.writeln('  ERROR: $error');
    }
    exit(1);
  }

  // 4. Generate outline
  final writer = OutlineWriter(
    classes: reader.classes,
    enums: reader.enums,
    maxLineLength: maxLineLength,
    showSchemaAnnotations: showSchemaAnnotations,
    stopAtDetailedIn: stopAtDetailedIn,
  );

  final outline = writer.generate(rootType);

  // 5. Write output
  final outputFile = File(outputPath);
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(outline);

  stdout.writeln('Outline written to $outputPath');
}

void _printUsage(ArgParser parser) {
  stdout.writeln('Usage: dart run bin/outliner.dart --package <path> [options]');
  stdout.writeln();
  stdout.writeln(parser.usage);
}

String _toSnakeCase(String name) {
  return name
      .replaceAllMapped(
        RegExp(r'(?<=[a-z0-9])([A-Z])'),
        (m) => '_${m.group(1)}',
      )
      .toLowerCase();
}
