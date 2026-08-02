/// Runs the full `v0` Spec-Object-Model generation for a single language and
/// writes the committed artefact tree (SOM §4.3): the `tom_som_<slug>_<label>`
/// project (`pubspec.yaml` + generated typed `lib/`), the lossless object-model
/// **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the wiring layer of the multi-platform generation: it composes the
/// already-tested pieces — [ModelReader] (analysis), [ModelJsonExporter]
/// (meta-data), [SpecModel] + [SomDartEmitter] (typed Dart facade), and
/// [DocSpecsSchemaGenerator] (schemas) — analysing the model **once** and
/// emitting deterministically so re-running over an unchanged model is a no-op.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'analyzer_bootstrap.dart';
import 'docspecs_schema_generator.dart';
import 'model_json_exporter.dart';
import 'model_reader.dart';
import 'packaging.dart' show packageVersionFromModel;
import 'som_dart_emitter.dart';
import 'som_dart_meta_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by [generateSomDartProject].
class SomGenerationResult {
  SomGenerationResult({
    required this.outputRoot,
    required this.pubspecPath,
    required this.libPath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  final String outputRoot;
  final String pubspecPath;
  final String libPath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the Dart `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_dart_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_dart_runtime`; the generated `pubspec.yaml`
///   depends on it by a **relative** path (computed from [outputRoot]) so the
///   committed file is portable across machines/checkout roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data. Provided by the caller (read from the model's
///   `version.versioner.dart`) so the committed meta-data is **stable**: the
///   exporter's wall-clock `generatedAt` is overridden with [generatedAt] (the
///   model build instant) to keep regeneration idempotent.
Future<SomGenerationResult> generateSomDartProject({
  required String modelPackagePath,
  required String runtimePackagePath,
  required String outputRoot,
  required int modelVersion,
  required String modelLabel,
  required String generatedAt,
  String versionLabel = 'v0',
  List<String> documentRoots = const [],
}) async {
  final libDir = p.join(modelPackagePath, 'lib');
  if (!Directory(libDir).existsSync()) {
    throw ArgumentError('model lib/ not found at $libDir');
  }

  final driver = createAnalysisDriver(modelPackagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libDir);

  return writeSomDartProject(
    classes: reader.classes,
    runtimePackagePath: runtimePackagePath,
    outputRoot: outputRoot,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
    generatedAt: generatedAt,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  );
}

/// Writes the artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomDartProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic
/// write step without re-analysing.
SomGenerationResult writeSomDartProject({
  required Map<String, ModelClass> classes,
  required String runtimePackagePath,
  required String outputRoot,
  required int modelVersion,
  required String modelLabel,
  required String generatedAt,
  String versionLabel = 'v0',
  List<String> documentRoots = const [],
}) {
  final outDir = Directory(outputRoot)..createSync(recursive: true);
  final packageName = 'tom_som_dart_$versionLabel';

  // ── meta-data (lossless object-model graph), idempotency-stabilised ────────
  final meta = ModelJsonExporter(
    classes,
    modelVersion: modelVersion,
    modelVersionLabel: modelLabel,
  ).export();
  // Override the exporter's wall-clock stamp with the model build instant so
  // the committed file does not churn on every run.
  meta['generatedAt'] = generatedAt;
  final metaErrors = validateSpecModelMeta(meta);
  if (metaErrors.isNotEmpty) {
    throw StateError('generated meta-data is invalid:\n  '
        '${metaErrors.join('\n  ')}');
  }
  final metaJsonPath = p.join(outputRoot, 'meta', 'spec_model.meta.json');
  final metaFile = File(metaJsonPath)..parent.createSync(recursive: true);
  metaFile.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(meta)}\n');

  // ── typed Dart facade (editing facade over the generic runtime) ────────────
  final model = SpecModel.fromJson(meta);
  final source = SomDartEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final libPath = p.join(outputRoot, 'lib', '$packageName.dart');
  File(libPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── generated metadata library (SOM §8): populated SomMetaTrees (SOM §7.2)
  //    plus the dot-notation and ID-tree access surfaces (SOM §8), exported
  //    from the main facade library ───────────────────────────────────────────
  final metaSource = SomDartMetaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  File(p.join(outputRoot, 'lib', '${packageName}_meta.dart'))
      .writeAsStringSync(metaSource);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── project pubspec (publishable: hosted runtime dep pinned to the model
  //    version) + a pubspec_overrides.yaml so the co-developed runtime resolves
  //    by path locally without breaking publishability ─────────────────────────
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll(r'\', '/');
  final packageVersion = packageVersionFromModel(modelLabel.split('+').first);
  final pubspecPath = p.join(outputRoot, 'pubspec.yaml');
  File(pubspecPath)
      .writeAsStringSync(_pubspec(packageName, version: packageVersion));
  File(p.join(outputRoot, 'pubspec_overrides.yaml'))
      .writeAsStringSync(_pubspecOverrides(runtimeRel));

  // Pin the analyzer config so a committed checkout analyses identically to the
  // emitter's own clean-analysis guarantee.
  File(p.join(outputRoot, 'analysis_options.yaml'))
      .writeAsStringSync(_analysisOptions);

  return SomGenerationResult(
    outputRoot: outDir.path,
    pubspecPath: pubspecPath,
    libPath: libPath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _pubspec(String name, {required String version}) => '''
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
name: $name
description: >-
  Generated typed TomSpecs object model (v0). An editing facade over the
  generic tom_som_dart_runtime; see the meta-data file and DocSpecs schemas in
  this package. Regenerate with tom_specs_clitool/bin/generate_som.dart.
version: $version
repository: https://github.com/al-the-bear/tom_ai_build

environment:
  sdk: ^3.11.4

dependencies:
  # Hosted so the package is publishable; the co-developed runtime is resolved
  # by path locally via pubspec_overrides.yaml (excluded from publish).
  tom_som_dart_runtime: ^$version

dev_dependencies:
  # So the hand-authored `test/` suite (preserved across regeneration — the
  # generator only rewrites lib/, meta/, schemas/ and this pubspec) resolves
  # under `dart test`. The typed facade itself carries no test-time code.
  test: ^1.25.6
''';

/// The local-development override: resolves the co-developed runtime by path so
/// `dart pub get` / `dart test` work in the monorepo before the runtime is
/// published. `pubspec_overrides.yaml` is excluded from `dart pub publish`, so
/// the published package keeps the hosted constraint from [_pubspec].
String _pubspecOverrides(String runtimeRel) => '''
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
# Local-development override: resolve the co-developed runtime by path. This
# file is excluded from `dart pub publish`; the published package uses the
# hosted `tom_som_dart_runtime` constraint declared in pubspec.yaml.
dependency_overrides:
  tom_som_dart_runtime:
    path: $runtimeRel
''';

const String _analysisOptions = '''
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
analyzer:
  errors:
    # The generated facade is machine-authored; style lints do not apply.
    todo: ignore
''';
