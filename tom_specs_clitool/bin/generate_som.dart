import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Runs the `v0` Spec-Object-Model generator from a `tom-spec-object-model`
/// config (plan item #7) and writes the committed artefact tree for every
/// configured language target (Dart only in Phase B).
///
/// Per target it produces, under the config's resolved output root, the
/// `tom_som_<slug>_<label>` project (`pubspec.yaml` + generated typed `lib/`),
/// the lossless meta-data file, and the DocSpecs schemas. The model version
/// stamp is read from the model's `version.versioner.dart` so the committed
/// meta-data is stable/idempotent (spec §2.3).
Future<void> main(List<String> arguments) async {
  final clitoolRoot = _clitoolRoot();
  final aiBuild = p.dirname(clitoolRoot);

  final parser = ArgParser()
    ..addOption('config',
        abbr: 'c',
        help: 'Path to the tom-spec-object-model config YAML. '
            'Default: <clitool>/tom_som.yaml.')
    ..addOption('model',
        help: 'Path to the tom_specs_model package. '
            'Default: <ai_build>/tom_specs_model.')
    ..addOption('runtime',
        help: 'Path to the tom_som_dart_runtime package (pubspec dep target). '
            'Default: <ai_build>/tom_som_dart_runtime.')
    ..addOption('py-runtime',
        help: 'Path to the tom_som_python_runtime package (manifest dep '
            'target). Default: <ai_build>/tom_som_python_runtime.')
    ..addOption('java-runtime',
        help: 'Path to the tom_som_java_runtime package (manifest dep '
            'target). Default: <ai_build>/tom_som_java_runtime.')
    ..addOption('js-runtime',
        help: 'Path to the tom_som_javascript_runtime package (manifest dep '
            'target). Default: <ai_build>/tom_som_javascript_runtime.')
    ..addOption('ts-runtime',
        help: 'Path to the tom_som_typescript_runtime package (file: dep '
            'target). Default: <ai_build>/tom_som_typescript_runtime.')
    ..addOption('go-runtime',
        help: 'Path to the tom_som_go_runtime module (go.mod replace '
            'target). Default: <ai_build>/tom_som_go_runtime.')
    ..addOption('rust-runtime',
        help: 'Path to the tom_som_rust_runtime crate (Cargo.toml path dep '
            'target). Default: <ai_build>/tom_som_rust_runtime.')
    ..addOption('model-version',
        help: 'Override the integer model-version stamp. '
            'Default: major component of the model version.')
    ..addFlag('help', abbr: 'h', help: 'Show usage information.',
        negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stdout.writeln(parser.usage);
    exit(2);
  }
  if (args.flag('help')) {
    stdout.writeln('Usage: dart run bin/generate_som.dart [options]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final configPath = p.normalize(p.absolute(
      args.option('config') ?? p.join(clitoolRoot, 'tom_som.yaml')));
  if (!File(configPath).existsSync()) {
    _fail('Config not found: $configPath');
  }
  final modelDir = p.normalize(p.absolute(
      args.option('model') ?? p.join(aiBuild, 'tom_specs_model')));
  final runtimeDir = p.normalize(p.absolute(
      args.option('runtime') ?? p.join(aiBuild, 'tom_som_dart_runtime')));
  final pyRuntimeDir = p.normalize(p.absolute(
      args.option('py-runtime') ?? p.join(aiBuild, 'tom_som_python_runtime')));
  final javaRuntimeDir = p.normalize(p.absolute(
      args.option('java-runtime') ?? p.join(aiBuild, 'tom_som_java_runtime')));
  final jsRuntimeDir = p.normalize(p.absolute(args.option('js-runtime') ??
      p.join(aiBuild, 'tom_som_javascript_runtime')));
  final tsRuntimeDir = p.normalize(p.absolute(args.option('ts-runtime') ??
      p.join(aiBuild, 'tom_som_typescript_runtime')));
  final goRuntimeDir = p.normalize(p.absolute(args.option('go-runtime') ??
      p.join(aiBuild, 'tom_som_go_runtime')));
  final rustRuntimeDir = p.normalize(p.absolute(args.option('rust-runtime') ??
      p.join(aiBuild, 'tom_som_rust_runtime')));
  for (final dir in [modelDir, runtimeDir]) {
    if (!Directory(dir).existsSync()) _fail('Directory not found: $dir');
  }

  final config = SpecObjectModelConfig.fromYaml(File(configPath).readAsStringSync());

  // The model version stamp drives the meta-data + schema version and the
  // idempotency-stable `generatedAt`.
  final stamp = _readStamp(modelDir);
  final modelVersion =
      int.tryParse(args.option('model-version') ?? '') ?? stamp.majorVersion;
  if (modelVersion < 1) {
    _fail('Resolved model version $modelVersion is invalid (must be ≥ 1).');
  }

  // `output-base` is resolved relative to the config file's directory.
  final configDir = p.dirname(configPath);

  stdout.writeln('generate_som: config $configPath');
  stdout.writeln('  model:   $modelDir');
  stdout.writeln('  runtime: $runtimeDir');
  stdout.writeln('  version: $modelVersion  (label: ${stamp.label})');
  stdout.writeln('  roots:   '
      '${config.generatesAllRoots ? 'all' : config.documentRoots.join(', ')}');

  for (final target in config.languages) {
    final outputRoot = p.normalize(p.join(configDir, target.outputRoot));
    switch (target.language) {
      case SomLanguage.dart:
        stdout.writeln('\n── generating ${target.language.slug} → $outputRoot');
        final result = await generateSomDartProject(
          modelPackagePath: modelDir,
          runtimePackagePath: runtimeDir,
          outputRoot: outputRoot,
          modelVersion: modelVersion,
          modelLabel: stamp.label,
          generatedAt: stamp.buildTime,
          versionLabel: config.versionLabel,
          documentRoots: config.documentRoots,
        );
        stdout.writeln('  classes: ${result.classCount}  '
            'roots: ${result.rootCount}  schemas: ${result.schemaPaths.length}');
        stdout.writeln('  meta:    ${result.metaJsonPath}');
        stdout.writeln('  lib:     ${result.libPath}');
        stdout.writeln('  pubspec: ${result.pubspecPath}');
      case SomLanguage.python:
        stdout.writeln('\n── generating ${target.language.slug} → $outputRoot');
        final result = await generateSomPythonProject(
          modelPackagePath: modelDir,
          runtimePackagePath: pyRuntimeDir,
          outputRoot: outputRoot,
          modelVersion: modelVersion,
          modelLabel: stamp.label,
          generatedAt: stamp.buildTime,
          versionLabel: config.versionLabel,
          documentRoots: config.documentRoots,
        );
        stdout.writeln('  classes: ${result.classCount}  '
            'roots: ${result.rootCount}  schemas: ${result.schemaPaths.length}');
        stdout.writeln('  meta:      ${result.metaJsonPath}');
        stdout.writeln('  module:    ${result.modulePath}');
        stdout.writeln('  pyproject: ${result.pyprojectPath}');
      case SomLanguage.java:
        stdout.writeln('\n── generating ${target.language.slug} → $outputRoot');
        final result = await generateSomJavaProject(
          modelPackagePath: modelDir,
          runtimePackagePath: javaRuntimeDir,
          outputRoot: outputRoot,
          modelVersion: modelVersion,
          modelLabel: stamp.label,
          generatedAt: stamp.buildTime,
          versionLabel: config.versionLabel,
          documentRoots: config.documentRoots,
        );
        stdout.writeln('  classes: ${result.classCount}  '
            'roots: ${result.rootCount}  schemas: ${result.schemaPaths.length}');
        stdout.writeln('  meta:     ${result.metaJsonPath}');
        stdout.writeln('  source:   ${result.sourcePath}');
        stdout.writeln('  manifest: ${result.manifestPath}');
      case SomLanguage.javascript:
        stdout.writeln('\n── generating ${target.language.slug} → $outputRoot');
        final result = await generateSomJavaScriptProject(
          modelPackagePath: modelDir,
          runtimePackagePath: jsRuntimeDir,
          outputRoot: outputRoot,
          modelVersion: modelVersion,
          modelLabel: stamp.label,
          generatedAt: stamp.buildTime,
          versionLabel: config.versionLabel,
          documentRoots: config.documentRoots,
        );
        stdout.writeln('  classes: ${result.classCount}  '
            'roots: ${result.rootCount}  schemas: ${result.schemaPaths.length}');
        stdout.writeln('  meta:     ${result.metaJsonPath}');
        stdout.writeln('  module:   ${result.modulePath}');
        stdout.writeln('  package:  ${result.packageJsonPath}');
      case SomLanguage.typescript:
        stdout.writeln('\n── generating ${target.language.slug} → $outputRoot');
        final result = await generateSomTypeScriptProject(
          modelPackagePath: modelDir,
          runtimePackagePath: tsRuntimeDir,
          outputRoot: outputRoot,
          modelVersion: modelVersion,
          modelLabel: stamp.label,
          generatedAt: stamp.buildTime,
          versionLabel: config.versionLabel,
          documentRoots: config.documentRoots,
        );
        stdout.writeln('  classes: ${result.classCount}  '
            'roots: ${result.rootCount}  schemas: ${result.schemaPaths.length}');
        stdout.writeln('  meta:     ${result.metaJsonPath}');
        stdout.writeln('  module:   ${result.modulePath}');
        stdout.writeln('  package:  ${result.packageJsonPath}');
        stdout.writeln('  tsconfig: ${result.tsconfigPath}');
      case SomLanguage.go:
        stdout.writeln('\n── generating ${target.language.slug} → $outputRoot');
        final result = await generateSomGoProject(
          modelPackagePath: modelDir,
          runtimePackagePath: goRuntimeDir,
          outputRoot: outputRoot,
          modelVersion: modelVersion,
          modelLabel: stamp.label,
          generatedAt: stamp.buildTime,
          versionLabel: config.versionLabel,
          documentRoots: config.documentRoots,
        );
        stdout.writeln('  classes: ${result.classCount}  '
            'roots: ${result.rootCount}  schemas: ${result.schemaPaths.length}');
        stdout.writeln('  meta:     ${result.metaJsonPath}');
        stdout.writeln('  module:   ${result.modulePath}');
        stdout.writeln('  go.mod:   ${result.goModPath}');
      case SomLanguage.rust:
        stdout.writeln('\n── generating ${target.language.slug} → $outputRoot');
        final result = await generateSomRustProject(
          modelPackagePath: modelDir,
          runtimePackagePath: rustRuntimeDir,
          outputRoot: outputRoot,
          modelVersion: modelVersion,
          modelLabel: stamp.label,
          generatedAt: stamp.buildTime,
          versionLabel: config.versionLabel,
          documentRoots: config.documentRoots,
        );
        stdout.writeln('  classes: ${result.classCount}  '
            'roots: ${result.rootCount}  schemas: ${result.schemaPaths.length}');
        stdout.writeln('  meta:     ${result.metaJsonPath}');
        stdout.writeln('  lib:      ${result.libPath}');
        stdout.writeln('  Cargo:    ${result.cargoTomlPath}');
      case SomLanguage.c:
      case SomLanguage.cpp:
        stdout.writeln('  (skipping ${target.language.slug}: '
            'no emitter yet — Phase C)');
    }
  }

  stdout.writeln('\nDone.');
}

/// The resolved root of the `tom_specs_clitool` package (parent of `bin/`).
String _clitoolRoot() {
  final scriptPath = p.fromUri(Platform.script);
  return p.normalize(p.dirname(p.dirname(scriptPath)));
}

/// The parsed model version stamp from `version.versioner.dart`.
class _Stamp {
  _Stamp(this.version, this.buildNumber, this.gitCommit, this.buildTime);
  final String version;
  final int buildNumber;
  final String gitCommit;
  final String buildTime;

  int get majorVersion => int.tryParse(version.split('.').first.trim()) ?? 1;

  String get label {
    final commit = gitCommit.isEmpty ? '' : '.$gitCommit';
    return '$version+$buildNumber$commit';
  }
}

_Stamp _readStamp(String modelDir) {
  final file = File(p.join(modelDir, 'lib', 'src', 'version.versioner.dart'));
  if (!file.existsSync()) {
    _fail('Version stamp not found at ${file.path}.');
  }
  final src = file.readAsStringSync();
  String str(String field) =>
      RegExp("$field\\s*=\\s*'([^']*)'").firstMatch(src)?.group(1) ?? '';
  int num(String field) =>
      int.tryParse(RegExp('$field\\s*=\\s*(\\d+)').firstMatch(src)?.group(1) ??
              '') ??
          0;
  final version = str('version');
  if (version.isEmpty) _fail('Could not parse `version` from ${file.path}.');
  return _Stamp(version, num('buildNumber'), str('gitCommit'), str('buildTime'));
}

Never _fail(String msg) {
  stderr.writeln('generate_som error: $msg');
  exit(1);
}
