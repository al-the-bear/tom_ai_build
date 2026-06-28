/// Runs the full `v0` Spec-Object-Model generation for **Go** and writes the
/// committed artefact tree (spec §2.3): the `tom_som_go_<label>` module (a
/// `go.mod` + the generated typed Go source file), the lossless object-model
/// **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the Go counterpart of `som_generator.dart` /
/// `som_python_generator.dart` / `som_java_generator.dart` /
/// `som_javascript_generator.dart` / `som_typescript_generator.dart` (plan
/// item #11). The **meta-data file and the DocSpecs schemas are
/// language-agnostic**, so this reuses the exact same [ModelJsonExporter] +
/// [DocSpecsSchemaGenerator] the other paths use (byte-identical across
/// languages); only the typed source emitter ([SomGoEmitter]) and the module
/// manifest differ. Generation is deterministic and idempotency-stabilised (the
/// wall-clock `generatedAt` is overridden with the model build instant), so
/// re-running over an unchanged model is a byte-for-byte no-op.
///
/// Like the statically-compiled Java/TypeScript paths, the generated Go source
/// imports the runtime through a **fixed import path** (`tom_som_go_runtime`);
/// this generator wires resolution by writing a `go.mod` with a `require` plus a
/// relative **`replace` directive** on the runtime, so the emitted source carries
/// no on-disk path and stays layout-independent / golden-stable.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'analyzer_bootstrap.dart';
import 'docspecs_schema_generator.dart';
import 'model_json_exporter.dart';
import 'model_reader.dart';
import 'som_go_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the Go generator.
class SomGoGenerationResult {
  SomGoGenerationResult({
    required this.outputRoot,
    required this.goModPath,
    required this.modulePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  final String outputRoot;
  final String goModPath;
  final String modulePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the Go `v0` artefact tree from [modelPackagePath] into [outputRoot].
///
/// * [outputRoot] — the `tom_som_go_<label>` module directory (created).
/// * [runtimePackagePath] — `tom_som_go_runtime`; the generated `go.mod` records
///   it as a relative `replace` directive (computed from [outputRoot]) so the
///   committed file is portable across machines/checkout roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomGoGenerationResult> generateSomGoProject({
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

  return writeSomGoProject(
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

/// Writes the Go artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomGoProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic write
/// step without re-analysing.
SomGoGenerationResult writeSomGoProject({
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
  final moduleName = 'tom_som_go_$versionLabel';
  const packageName = 'somv0';

  // ── meta-data (lossless object-model graph), idempotency-stabilised ────────
  // Identical to every other language path — meta-data is language-agnostic.
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

  // ── typed Go facade (editing facade over the generic runtime) ──────────────
  final model = SpecModel.fromJson(meta);
  final source = SomGoEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
    packageName: packageName,
  ).generateLibrary();
  final modulePath = p.join(outputRoot, '$moduleName.go');
  File(modulePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to every other language path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths = <String>[];
  for (final schema in schemas.values) {
    final fileName = DocSpecsSchemaGenerator.fileNameFor(schema);
    final file = File(p.join(outputRoot, 'schemas', schema.id, fileName))
      ..parent.createSync(recursive: true);
    file.writeAsStringSync(DocSpecsSchemaGenerator.toYamlString(schema));
    schemaPaths.add(file.path);
  }
  schemaPaths.sort();

  // ── go.mod (relative `replace` directive on the runtime) ───────────────────
  // The generated Go source imports the runtime by a fixed import path, so
  // resolution is wired through go.mod: a `require` pins the module name and a
  // relative `replace` points it at the local runtime checkout. Relative for
  // portability across machines and checkout roots.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll('\\', '/');
  final goModPath = p.join(outputRoot, 'go.mod');
  File(goModPath).writeAsStringSync(_goMod(moduleName, runtimeRel));

  return SomGoGenerationResult(
    outputRoot: outDir.path,
    goModPath: goModPath,
    modulePath: modulePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _goMod(String moduleName, String runtimeRel) {
  // A leading "./" keeps the replace target an explicit relative path; Go
  // requires relative replace targets to start with "./" or "../".
  final target = runtimeRel.startsWith('.') ? runtimeRel : './$runtimeRel';
  return 'module $moduleName\n'
      '\n'
      'go 1.21\n'
      '\n'
      'require tom_som_go_runtime v0.0.0\n'
      '\n'
      'replace tom_som_go_runtime => $target\n';
}
