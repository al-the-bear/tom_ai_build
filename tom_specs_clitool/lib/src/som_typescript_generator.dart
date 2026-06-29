/// Runs the full `v0` Spec-Object-Model generation for **TypeScript** and writes
/// the committed artefact tree (spec §2.3): the `tom_som_typescript_<label>`
/// project (a `package.json` + a `tsconfig.json` + the generated typed TypeScript
/// module), the lossless object-model **meta-data file**, and the **DocSpecs
/// schemas**.
///
/// This is the TypeScript counterpart of `som_generator.dart` /
/// `som_python_generator.dart` / `som_java_generator.dart` /
/// `som_javascript_generator.dart` (plan item #11). The **meta-data file and the
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
import 'som_typescript_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the TypeScript generator.
class SomTypeScriptGenerationResult {
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

  final String outputRoot;
  final String packageJsonPath;
  final String tsconfigPath;
  final String modulePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
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
  final packageJsonPath = p.join(outputRoot, 'package.json');
  File(packageJsonPath)
      .writeAsStringSync(_packageJson(packageName, runtimeRel));

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

String _packageJson(String name, String runtimeRel) {
  final manifest = <String, Object?>{
    'name': name,
    'version': '0.0.0',
    'private': true,
    'description': 'Generated typed TomSpecs object model (v0). An editing '
        'facade over the generic tom_som_typescript_runtime; see the meta-data '
        'file and DocSpecs schemas in this package. Regenerate with '
        'tom_specs_clitool/bin/generate_som.dart.',
    'main': 'dist/$name.js',
    'types': 'dist/$name.d.ts',
    'type': 'commonjs',
    'engines': <String, Object?>{'node': '>=18'},
    'scripts': <String, Object?>{'build': 'tsc'},
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
    'include': <String>['*.ts', 'tests/**/*.ts', 'examples/**/*.ts'],
  };
  return '${const JsonEncoder.withIndent('  ').convert(config)}\n';
}
