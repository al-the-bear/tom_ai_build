/// Runs the full `v0` Spec-Object-Model generation for **Rust** and writes the
/// committed artefact tree (spec §2.3): the `tom_som_rust_<label>` crate (a
/// `Cargo.toml` + the generated typed crate root `src/lib.rs`), the lossless
/// object-model **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the Rust counterpart of `som_generator.dart` /
/// `som_python_generator.dart` / `som_java_generator.dart` /
/// `som_javascript_generator.dart` / `som_typescript_generator.dart` /
/// `som_go_generator.dart` (plan item #11). The **meta-data file and the
/// DocSpecs schemas are language-agnostic**, so this reuses the exact same
/// [ModelJsonExporter] + [DocSpecsSchemaGenerator] the other paths use
/// (byte-identical across languages); only the typed source emitter
/// ([SomRustEmitter]) and the crate manifest differ. Generation is deterministic
/// and idempotency-stabilised (the wall-clock `generatedAt` is overridden with
/// the model build instant), so re-running over an unchanged model is a
/// byte-for-byte no-op.
///
/// Like the statically-compiled Java/TypeScript/Go paths, the generated Rust
/// source depends on the runtime through a **fixed crate name**
/// (`tom_som_rust_runtime`); this generator wires resolution by writing a
/// `Cargo.toml` with a relative **`path` dependency** on the runtime, so the
/// emitted source carries no on-disk path and stays layout-independent /
/// golden-stable.
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
import 'som_rust_emitter.dart';
import 'som_rust_meta_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the Rust generator.
class SomRustGenerationResult {
  SomRustGenerationResult({
    required this.outputRoot,
    required this.cargoTomlPath,
    required this.libPath,
    required this.metaModulePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  final String outputRoot;
  final String cargoTomlPath;
  final String libPath;

  /// The generated metadata module (`src/meta.rs`): populated §3.2 metadata
  /// trees plus the dot-notation (§4.1) and ID-tree (§4.2) navigation surfaces.
  final String metaModulePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the Rust `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_rust_<label>` crate directory (created).
/// * [runtimePackagePath] — `tom_som_rust_runtime`; the generated `Cargo.toml`
///   records it as a relative `path` dependency (computed from [outputRoot]) so
///   the committed file is portable across machines/checkout roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomRustGenerationResult> generateSomRustProject({
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

  return writeSomRustProject(
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

/// Writes the Rust artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomRustProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic write
/// step without re-analysing.
SomRustGenerationResult writeSomRustProject({
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
  final crateName = 'tom_som_rust_$versionLabel';
  // Every SOM package (runtime + facade) is stamped with the TomSpecs model
  // version — the crate version and the versioned runtime dependency both use it
  // so `cargo package` (which requires a version on every dependency) is clean.
  final packageVersion = packageVersionFromModel(modelLabel.split('+').first);

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

  // ── typed Rust facade (editing facade over the generic runtime) ────────────
  final model = SpecModel.fromJson(meta);
  final source = SomRustEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final libPath = p.join(outputRoot, 'src', 'lib.rs');
  File(libPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── metadata module (populated §3.2 trees + §4.1/§4.2 navigation) ──────────
  // A sibling file-module declared `pub mod meta;` by the generated lib.rs.
  final metaSource = SomRustMetaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final metaModulePath = p.join(outputRoot, 'src', 'meta.rs');
  File(metaModulePath).writeAsStringSync(metaSource);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to every other language path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── Cargo.toml (relative `path` dependency on the runtime) ─────────────────
  // The generated Rust source depends on the runtime by a fixed crate name, so
  // resolution is wired through Cargo.toml: a relative `path` dependency points
  // it at the local runtime checkout. Relative for portability across machines
  // and checkout roots.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll('\\', '/');
  final cargoTomlPath = p.join(outputRoot, 'Cargo.toml');
  File(cargoTomlPath)
      .writeAsStringSync(_cargoToml(crateName, runtimeRel, packageVersion));

  return SomRustGenerationResult(
    outputRoot: outDir.path,
    cargoTomlPath: cargoTomlPath,
    libPath: libPath,
    metaModulePath: metaModulePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _cargoToml(String crateName, String runtimeRel, String version) {
  // The runtime is declared in `[dependencies]` (the generated `lib.rs` uses it)
  // *and* in `[dev-dependencies]` so the committed integration test under
  // `tests/` can name `tom_som_rust_runtime` directly — a package's regular
  // dependencies are not in scope by name for its integration-test crates.
  //
  // Each runtime dependency carries **both** a relative `path` (resolves in-repo)
  // *and* a `version` requirement (= the model version). `cargo package` requires
  // every dependency to specify a version; the `path` is stripped from the
  // packaged manifest, leaving the version. `publish = false` keeps the
  // proprietary crate out of `cargo publish`; `license-file` points at the
  // LICENSE the packaging hook writes, so `cargo package` carries no metadata
  // warning.
  final runtimeDep =
      'tom_som_rust_runtime = { path = "$runtimeRel", version = "$version" }';
  return '[package]\n'
      'name = "$crateName"\n'
      'version = "$version"\n'
      'edition = "2021"\n'
      'description = "Generated typed TomSpecs object-model facade (Rust)."\n'
      'license-file = "LICENSE"\n'
      'repository = "https://github.com/al-the-bear/tom_ai_build"\n'
      'publish = false\n'
      '\n'
      '[lib]\n'
      'path = "src/lib.rs"\n'
      '\n'
      '[dependencies]\n'
      '$runtimeDep\n'
      '\n'
      '[dev-dependencies]\n'
      '$runtimeDep\n';
}
