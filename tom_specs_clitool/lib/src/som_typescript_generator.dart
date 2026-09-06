/// Runs the full `v0` Spec-Object-Model generation for **TypeScript** and writes
/// the committed artefact tree (SOM §4.3): the `tom_som_typescript_<label>`
/// project (a `package.json` + a `tsconfig.json` + the generated typed TypeScript
/// module), the lossless object-model **meta-data file**, and the **DocSpecs
/// schemas**.
///
/// This is the TypeScript counterpart of `som_generator.dart` /
/// `som_python_generator.dart` / `som_java_generator.dart` /
/// `som_javascript_generator.dart` (som_multiplatform_spec_model.md §10). The **meta-data file and the
/// DocSpecs schemas are language-agnostic**, so this reuses the exact same
/// [ModelJsonExporter] + [DocSpecsSchemaGenerator] the other paths use
/// (byte-identical across languages); only the typed source emitter
/// ([SomTypeScriptEmitter]) and the project manifests differ. Generation is
/// deterministic and idempotency-stabilised (the wall-clock `generatedAt` is
/// overridden with the model build instant), so re-running over an unchanged
/// model is a byte-for-byte no-op.
///
/// Unlike the JavaScript path (which resolves the runtime at load time via a
/// `tomSom.runtimePath` recorded in `package.json`), TypeScript is statically
/// compiled like Java: the generated module imports the runtime through a **fixed
/// bare specifier** (`tom_som_typescript_runtime`), and this generator wires
/// resolution by writing a `package.json` with a relative **`file:` dependency**
/// on the runtime plus a `tsconfig.json`. `tsc` resolves the import through
/// `node_modules` (the runtime's `dist/src/index.d.ts`) and `node` resolves the
/// compiled JS the same way (`dist/src/index.js`), keeping the emitted source
/// path-free and golden-stable.
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
import 'som_typescript_emitter.dart';
import 'som_typescript_meta_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the TypeScript generator.
class SomTypeScriptGenerationResult {
  /// Every field is required: this is the *complete* record of one run, so a
  /// caller can report and check the written project without re-walking it.
  /// There is no partial success — [writeSomTypeScriptProject] either throws or
  /// returns a fully populated result.
  SomTypeScriptGenerationResult({
    required this.outputRoot,
    required this.packageJsonPath,
    required this.tsconfigPath,
    required this.modulePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  /// The created `tom_som_typescript_<label>` project directory. Every other
  /// path in this result lies underneath it.
  final String outputRoot;

  /// The written `package.json`. It carries a relative `file:` dependency on
  /// `tom_som_typescript_runtime`: the generated module imports the runtime by
  /// a **fixed bare specifier**, so without an `npm install` against this file
  /// neither `tsc` (`dist/src/index.d.ts`) nor `node` (`dist/src/index.js`) can
  /// resolve it. The path is relative so the committed file stays portable.
  final String packageJsonPath;

  /// The written `tsconfig.json` — deterministic, and compiling the generated
  /// module together with the committed tests/examples into `dist/`. It is
  /// generated rather than hand-kept so a checkout type-checks identically to
  /// the emitter's own clean-compile guarantee.
  final String tsconfigPath;

  /// The generated typed facade module, `tom_som_typescript_<label>.ts` at the
  /// project root. The metadata module written beside it (`..._meta.ts`) is not
  /// reported separately, but it is not optional: the facade imports it.
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

/// Generates the TypeScript `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_typescript_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_typescript_runtime`; the generated
///   `package.json` records it as a **relative `file:` dependency** (computed from
///   [outputRoot]) so the committed file is portable across machines/checkout
///   roots and both `tsc` and `node` resolve the runtime through `node_modules`.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomTypeScriptGenerationResult> generateSomTypeScriptProject({
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

  return writeSomTypeScriptProject(
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

/// Writes the TypeScript artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomTypeScriptProject] so callers that have already run
/// the analyzer (or tests with a hand-built graph) can drive the deterministic
/// write step without re-analysing.
SomTypeScriptGenerationResult writeSomTypeScriptProject({
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
  final packageName = 'tom_som_typescript_$versionLabel';

  // ── meta-data (lossless object-model graph), idempotency-stabilised ────────
  // Identical to the Dart/Python/Java/JavaScript path — meta-data is
  // language-agnostic.
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

  // ── typed TypeScript facade (editing facade over the generic runtime) ──────
  final model = SpecModel.fromJson(meta);
  final source = SomTypeScriptEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  final modulePath = p.join(outputRoot, '$packageName.ts');
  File(modulePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(source);

  // ── generated metadata module (SOM §8): populated SomMetaTrees plus the
  //    dot-notation and ID-tree access surfaces, required by the facade ───────
  final metaModuleSource = SomTypeScriptMetaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  File(p.join(outputRoot, '${packageName}_meta.ts'))
      .writeAsStringSync(metaModuleSource);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to the Dart/Python/Java/JavaScript path — schemas are
  // language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── package.json (relative `file:` dependency on the runtime) ──────────────
  // Unlike the JS path, the generated TS module imports the runtime by a fixed
  // bare specifier, so resolution is wired through node_modules: a `file:`
  // dependency makes both `tsc` (via the runtime's `dist/src/index.d.ts`) and
  // `node` (via `dist/src/index.js`) resolve it. Relative for portability.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll('\\', '/');
  final packageVersion = packageVersionFromModel(modelLabel.split('+').first);
  final packageJsonPath = p.join(outputRoot, 'package.json');
  File(packageJsonPath).writeAsStringSync(
      _packageJson(packageName, runtimeRel, version: packageVersion));

  // ── tsconfig.json (deterministic; compiles src + tests/examples to dist) ───
  final tsconfigPath = p.join(outputRoot, 'tsconfig.json');
  File(tsconfigPath).writeAsStringSync(_tsconfig());

  return SomTypeScriptGenerationResult(
    outputRoot: outDir.path,
    packageJsonPath: packageJsonPath,
    tsconfigPath: tsconfigPath,
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
        'facade over the generic tom_som_typescript_runtime; see the meta-data '
        'file and DocSpecs schemas in this package. Regenerate with '
        'tom_specs_clitool/bin/generate_som.dart.',
    'main': 'dist/$name.js',
    'types': 'dist/$name.d.ts',
    'type': 'commonjs',
    // The tarball payload: the compiled facade (`.js` + `.d.ts`), the lossless
    // meta-data, the DocSpecs schemas, plus docs/license (npm always adds
    // package.json, README and LICENSE, but the compiled outputs, CHANGELOG and
    // directories must be listed explicitly). `dist/` is built on `prepack`.
    'files': <String>[
      'dist/$name.js',
      'dist/$name.d.ts',
      'dist/${name}_meta.js',
      'dist/${name}_meta.d.ts',
      'meta/',
      'schemas/',
      'README.md',
      'readme_howtointegrate.md',
      'CHANGELOG.md',
      'LICENSE',
    ],
    'exports': <String, Object?>{
      '.': <String, Object?>{
        'types': './dist/$name.d.ts',
        'default': './dist/$name.js',
      },
      './meta': './meta/spec_model.meta.json',
      './package.json': './package.json',
    },
    'engines': <String, Object?>{'node': '>=18'},
    // `prebuild` runs automatically before `build` (npm lifecycle). The facade
    // imports the runtime by bare specifier, resolving to the runtime's
    // git-ignored `dist/src/index.d.ts`; on a clean checkout that file does not
    // exist yet, so `tsc` on the facade would fail against a missing/stale
    // runtime `dist/`. Building the runtime first makes `npm run build` work
    // with no manual pre-step (CS4-D6). Same relative path as the `file:` dep.
    // `prepack` runs before `npm pack`/`npm publish` builds the tarball, so a
    // published/git install always ships freshly-compiled `dist/`.
    'scripts': <String, Object?>{
      'prebuild': 'npm --prefix $runtimeRel run build',
      'build': 'tsc',
      'prepack': 'npm run build',
    },
    'dependencies': <String, Object?>{
      // The generic runtime package this typed facade edits over. A relative
      // `file:` dependency wires bare-specifier resolution through node_modules
      // for both `tsc` and `node`. Relative for portability across machines and
      // checkout roots.
      'tom_som_typescript_runtime': 'file:$runtimeRel',
    },
    'devDependencies': <String, Object?>{
      'typescript': '6.0.3',
      '@types/node': '^22',
    },
  };
  return '${const JsonEncoder.withIndent('  ').convert(manifest)}\n';
}

String _tsconfig() {
  final config = <String, Object?>{
    'compilerOptions': <String, Object?>{
      'target': 'ES2020',
      'lib': <String>['ES2020'],
      'module': 'commonjs',
      'moduleResolution': 'node',
      'ignoreDeprecations': '6.0',
      'rootDir': '.',
      'outDir': 'dist',
      'declaration': true,
      'declarationMap': false,
      'sourceMap': false,
      'strict': true,
      'esModuleInterop': true,
      'forceConsistentCasingInFileNames': true,
      'skipLibCheck': true,
      'types': <String>['node'],
    },
    // `tool/**/*.ts` covers the SOM §19 golden-harness generator so `tsc`
    // typechecks it too; keeping it here makes regeneration idempotent against
    // the tracked tsconfig instead of stripping the golden tool on every run.
    'include': <String>[
      '*.ts',
      'tests/**/*.ts',
      'examples/**/*.ts',
      'tool/**/*.ts',
    ],
  };
  return '${const JsonEncoder.withIndent('  ').convert(config)}\n';
}
