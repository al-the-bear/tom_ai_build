/// Runs the full `v0` Spec-Object-Model generation for **JavaScript** and writes
/// the committed artefact tree (SOM §4.3): the `tom_som_javascript_<label>`
/// project (a `package.json` + the generated typed CommonJS module), the lossless
/// object-model **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the JavaScript counterpart of `som_generator.dart` /
/// `som_python_generator.dart` / `som_java_generator.dart` (som_multiplatform_spec_model.md §10). The
/// **meta-data file and the DocSpecs schemas are language-agnostic**, so this
/// reuses the exact same [ModelJsonExporter] + [DocSpecsSchemaGenerator] the
/// Dart/Python/Java paths use (byte-identical across languages); only the typed
/// source emitter ([SomJavaScriptEmitter]) and the project manifest differ.
/// Generation is deterministic and idempotency-stabilised (the wall-clock
/// `generatedAt` is overridden with the model build instant), so re-running over
/// an unchanged model is a byte-for-byte no-op.
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
import 'som_javascript_emitter.dart';
import 'som_javascript_meta_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the JavaScript generator.
class SomJavaScriptGenerationResult {
  /// Every field is required: this is the *complete* record of one run, so a
  /// caller can report and check the written project without re-walking it.
  /// There is no partial success — [writeSomJavaScriptProject] either throws or
  /// returns a fully populated result.
  SomJavaScriptGenerationResult({
    required this.outputRoot,
    required this.packageJsonPath,
    required this.modulePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  /// The created `tom_som_javascript_<label>` project directory. Every other
  /// path in this result lies underneath it.
  final String outputRoot;

  /// The written `package.json` — the Node analogue of `pubspec.yaml`, with no
  /// external dependencies. Unlike the TypeScript path it does not wire
  /// `node_modules`: it *records* where the generic runtime lives relative to
  /// the project root, and the generated module resolves that at load time via
  /// `tomSom.runtimePath`. So no `npm install` is needed, but moving either
  /// directory without regenerating breaks loading.
  final String packageJsonPath;

  /// The generated typed facade module, `tom_som_javascript_<label>.js` at the
  /// project root. The metadata module written beside it (`..._meta.js`) is not
  /// reported separately, but it is not optional: the facade requires it.
  final String modulePath;

  /// The lossless object-model graph, `meta/spec_model.meta.json` (SOM §5.3).
  /// It is validated by `validateSpecModelMeta` *before* it is written, so a
  /// path returned here always names a file that passed validation. Being
  /// language-agnostic, it is byte-identical to the Dart/Python/Rust path's.
  final String metaJsonPath;

  /// One written `*.docspecs-schema.yaml` per `@Document` root (SOM §5.4), in
  /// the order `DocSpecsSchemaGenerator.writeSchemaTree` produced them. Also
  /// language-agnostic: identical to what every other language path writes.
  final List<String> schemaPaths;

  /// How many classes the analyzer resolved in the model package — **not** how
  /// many classes were emitted. The emitter walks only what is reachable from
  /// the selected roots, so the generated module can hold fewer.
  final int classCount;

  /// How many `@Document` roots the exported meta-data declares. Read from the
  /// meta rather than from the emitter, so it counts every root in the model
  /// even when `documentRoots` narrowed the typed module to a subset.
  final int rootCount;

  /// The model major version stamped into the meta-data and into every
  /// generated DocSpecs schema. Each generated root class checks a document's
  /// authoring stamp against it at construction time, which is what makes an
  /// out-of-date document fail loudly instead of mis-reading (SOM §4.2).
  final int modelVersion;

  /// The model's full version label (`1.2.3+45`) as recorded in the meta-data.
  /// The `+build` tail is stripped before it becomes the npm package version,
  /// so a rebuild of the same source version publishes the same version.
  final String modelLabel;
}

/// Generates the JavaScript `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_javascript_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_javascript_runtime`; the generated
///   `package.json` records its root by a **relative** path (computed from
///   [outputRoot]) so the committed file is portable across machines/checkout
///   roots and the module resolves the runtime at load time.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomJavaScriptGenerationResult> generateSomJavaScriptProject({
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

  return writeSomJavaScriptProject(
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

/// Writes the JavaScript artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomJavaScriptProject] so callers that have already run
/// the analyzer (or tests with a hand-built graph) can drive the deterministic
/// write step without re-analysing.
SomJavaScriptGenerationResult writeSomJavaScriptProject({
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
  final packageName = 'tom_som_javascript_$versionLabel';

  // ── meta-data (lossless object-model graph), idempotency-stabilised ────────
  // Identical to the Dart/Python/Java path — the meta-data is language-agnostic.
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

  // ── typed JavaScript facade (editing facade over the generic runtime) ──────
  final model = SpecModel.fromJson(meta);
  final source = SomJavaScriptEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final modulePath = p.join(outputRoot, '$packageName.js');
  File(modulePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── generated metadata module (SOM §8): populated SomMetaTrees plus the
  //    dot-notation and ID-tree access surfaces, required by the facade ───────
  final metaModuleSource = SomJavaScriptMetaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  File(p.join(outputRoot, '${packageName}_meta.js'))
      .writeAsStringSync(metaModuleSource);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to the Dart/Python/Java path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── package.json (relative runtime path for portability) ───────────────────
  // The Node analog of pubspec.yaml / pyproject.toml: zero external deps. It
  // records where the generic runtime package lives (relative to this project
  // root); the generated module resolves it at load time via `tomSom.runtimePath`.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll(r'\', '/');
  final packageVersion = packageVersionFromModel(modelLabel.split('+').first);
  final packageJsonPath = p.join(outputRoot, 'package.json');
  File(packageJsonPath).writeAsStringSync(
      _packageJson(packageName, runtimeRel, version: packageVersion));

  return SomJavaScriptGenerationResult(
    outputRoot: outDir.path,
    packageJsonPath: packageJsonPath,
    modulePath: modulePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _packageJson(String name, String runtimeRel, {required String version}) {
  final manifest = <String, Object?>{
    'name': name,
    // The TomSpecs model version — the facade is regenerated per model version
    // and always reports it (never maintained independently).
    'version': version,
    // BSD-3-Clause per the release-1 licence decision; still `private` because
    // release 1 ships the non-Dart runtimes source-only — npm publication is a
    // separate follow-up, and `private: true` makes an accidental `npm publish`
    // refuse while `npm pack` keeps working.
    'private': true,
    'license': 'BSD-3-Clause',
    'repository': <String, Object?>{
      'type': 'git',
      'url': 'git+https://github.com/al-the-bear/tom_ai_build.git',
      'directory': name,
    },
    'description': 'Generated typed TomSpecs object model (v0). An editing '
        'facade over the generic tom_som_javascript_runtime; see the meta-data '
        'file and DocSpecs schemas in this package. Regenerate with '
        'tom_specs_clitool/bin/generate_som.dart.',
    'main': '$name.js',
    // The tarball payload: the typed module, the lossless meta-data, the
    // DocSpecs schemas, the examples, plus docs/license (npm always adds
    // package.json, README and LICENSE, but CHANGELOG and directories must be
    // listed explicitly).
    'files': <String>[
      '$name.js',
      '${name}_meta.js',
      'meta/',
      'schemas/',
      'examples/',
      'README.md',
      'readme_howtointegrate.md',
      'CHANGELOG.md',
      'LICENSE',
    ],
    'exports': <String, Object?>{
      '.': './$name.js',
      './meta': './meta/spec_model.meta.json',
      './package.json': './package.json',
    },
    'engines': <String, Object?>{'node': '>=18'},
    // The generic runtime this facade edits over, pinned to the same model
    // version. The module itself resolves the runtime by the relative
    // `tomSom.runtimePath` below (works in an un-installed checkout); this
    // dependency declares the requirement for registry installs.
    'dependencies': <String, Object?>{
      'tom_som_javascript_runtime': '>=$version',
    },
    'tomSom': <String, Object?>{
      // The generic runtime package this typed facade edits over. The module
      // resolves it relative to its own directory at load time. Relative for
      // portability across machines and checkout roots.
      'runtimePath': runtimeRel,
    },
  };
  return '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
}
