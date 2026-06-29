/// Runs the full `v0` Spec-Object-Model generation for **Python** and writes the
/// committed artefact tree (spec §2.3): the `tom_som_python_<label>` project
/// (`pyproject.toml` + generated typed module), the lossless object-model
/// **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the Python counterpart of `som_generator.dart` (plan item #11). The
/// **meta-data file and the DocSpecs schemas are language-agnostic**, so this
/// reuses the exact same [ModelJsonExporter] + [DocSpecsSchemaGenerator] the Dart
/// path uses (byte-identical across languages); only the typed source emitter
/// ([SomPythonEmitter]) and the project manifest differ. Generation is
/// deterministic and idempotency-stabilised (the wall-clock `generatedAt` is
/// overridden with the model build instant), so re-running over an unchanged
/// model is a byte-for-byte no-op.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'analyzer_bootstrap.dart';
import 'docspecs_schema_generator.dart';
import 'model_json_exporter.dart';
import 'model_reader.dart';
import 'som_python_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the Python generator.
class SomPythonGenerationResult {
  SomPythonGenerationResult({
    required this.outputRoot,
    required this.pyprojectPath,
    required this.modulePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  final String outputRoot;
  final String pyprojectPath;
  final String modulePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the Python `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_python_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_python_runtime`; the generated
///   `pyproject.toml` records it by a **relative** path (computed from
///   [outputRoot]) so the committed file is portable across machines/checkout
///   roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomPythonGenerationResult> generateSomPythonProject({
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

  return writeSomPythonProject(
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

/// Writes the Python artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomPythonProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic write
/// step without re-analysing.
SomPythonGenerationResult writeSomPythonProject({
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
  final packageName = 'tom_som_python_$versionLabel';

  // ── meta-data (lossless object-model graph), idempotency-stabilised ────────
  // Identical to the Dart path — the meta-data is language-agnostic.
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

  // ── typed Python facade (editing facade over the generic runtime) ──────────
  final model = SpecModel.fromJson(meta);
  final source = SomPythonEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final modulePath = p.join(outputRoot, '$packageName.py');
  File(modulePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to the Dart path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── project manifest (relative runtime path for portability) ───────────────
  final runtimeRel =
      p.relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot));
  final pyprojectPath = p.join(outputRoot, 'pyproject.toml');
  File(pyprojectPath)
      .writeAsStringSync(_pyproject(packageName, runtimeRel.replaceAll(r'\\', '/')));

  return SomPythonGenerationResult(
    outputRoot: outDir.path,
    pyprojectPath: pyprojectPath,
    modulePath: modulePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _pyproject(String name, String runtimeRel) => '''
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
[project]
name = "$name"
version = "0.0.0"
description = "Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_python_runtime; see the meta-data file and DocSpecs schemas in this package. Regenerate with tom_specs_clitool/bin/generate_som.dart."
requires-python = ">=3.9"

[tool.tom_som]
# The generic runtime this typed facade edits over. Add it to PYTHONPATH (or
# install it) so `import tom_som_runtime` resolves. The path is relative to this
# project root for portability across machines and checkout roots.
runtime-path = "$runtimeRel/tom_som_runtime"
''';
