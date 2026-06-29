/// Runs the full `v0` Spec-Object-Model generation for **Java** and writes the
/// committed artefact tree (spec §2.3): the `tom_som_java_<label>` project (a
/// build manifest + the generated typed `src/` source), the lossless
/// object-model **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the Java counterpart of `som_generator.dart` / `som_python_generator.dart`
/// (plan item #11). The **meta-data file and the DocSpecs schemas are
/// language-agnostic**, so this reuses the exact same [ModelJsonExporter] +
/// [DocSpecsSchemaGenerator] the Dart/Python paths use (byte-identical across
/// languages); only the typed source emitter ([SomJavaEmitter]) and the project
/// manifest differ. Generation is deterministic and idempotency-stabilised (the
/// wall-clock `generatedAt` is overridden with the model build instant), so
/// re-running over an unchanged model is a byte-for-byte no-op.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'analyzer_bootstrap.dart';
import 'docspecs_schema_generator.dart';
import 'model_json_exporter.dart';
import 'model_reader.dart';
import 'som_java_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the Java generator.
class SomJavaGenerationResult {
  SomJavaGenerationResult({
    required this.outputRoot,
    required this.manifestPath,
    required this.sourcePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  final String outputRoot;
  final String manifestPath;
  final String sourcePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the Java `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_java_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_java_runtime`; the generated build manifest
///   records its `src/` by a **relative** path (computed from [outputRoot]) so
///   the committed file is portable across machines/checkout roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomJavaGenerationResult> generateSomJavaProject({
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

  return writeSomJavaProject(
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

/// Writes the Java artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomJavaProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic write
/// step without re-analysing.
SomJavaGenerationResult writeSomJavaProject({
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
  final packageName = 'tom_som_java_$versionLabel';

  // ── meta-data (lossless object-model graph), idempotency-stabilised ────────
  // Identical to the Dart/Python path — the meta-data is language-agnostic.
  final meta = ModelJsonExporter(
    classes,
    modelVersion: modelVersion,
    modelVersionLabel: modelLabel,
  ).export();
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

  // ── typed Java facade (editing facade over the generic runtime) ────────────
  // A single outer class `TomSomV0` (Java's one-public-class-per-file rule), in
  // package `tom_som_java_v0`, so the source path mirrors the package.
  final model = SpecModel.fromJson(meta);
  final source = SomJavaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final sourcePath =
      p.join(outputRoot, 'src', 'tom_som_java_$versionLabel', 'TomSomV0.java');
  File(sourcePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to the Dart/Python path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── build manifest (relative runtime src for portability) ──────────────────
  // The Java analog of pubspec.yaml / pyproject.toml: zero external deps, so the
  // manifest just records where the generic runtime source lives (relative to
  // this project root) for the compile step to add to the javac source path.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll(r'\\', '/');
  final manifest = <String, Object?>{
    'package': packageName,
    'mainClass': 'tom_som_java_$versionLabel.TomSomV0',
    'generator': 'tom_specs_clitool generate_som',
    'runtimeSourcePath': '$runtimeRel/src',
  };
  final manifestPath = p.join(outputRoot, 'tom_som_build.json');
  File(manifestPath).writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n');

  return SomJavaGenerationResult(
    outputRoot: outDir.path,
    manifestPath: manifestPath,
    sourcePath: sourcePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}
