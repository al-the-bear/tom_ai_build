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
import 'som_dart_model_emitter.dart';
import 'som_emitted_surface.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by [generateSomDartProject].
class SomGenerationResult {
  /// Every field is required: this is the *complete* record of one run, so a
  /// caller (the CLI summary, the regeneration gate) can report and check the
  /// written tree without re-walking the output directory. There are no
  /// defaults because there is no partial success — [writeSomDartProject]
  /// either throws or returns a fully populated result.
  SomGenerationResult({
    required this.outputRoot,
    required this.pubspecPath,
    required this.libPath,
    required this.metaModulePath,
    required this.modelModulePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.emittedClassCount,
    required this.emittedRootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  /// The created `tom_som_dart_<label>` project directory. Every other path in
  /// this result lies underneath it.
  final String outputRoot;

  /// The written `pubspec.yaml`. Its `tom_som_dart_runtime` dependency is
  /// **hosted**, so the package stays publishable; the path resolution used in
  /// the monorepo lives in the sibling `pubspec_overrides.yaml`, which this
  /// result deliberately does not name because it is excluded from publish.
  final String pubspecPath;

  /// The generated typed facade library, `lib/tom_som_dart_<label>.dart`. The
  /// facade exports the metadata library written beside it, so one import
  /// reaches both; that file is reported as [metaModulePath].
  final String libPath;

  /// The generated metadata library, `lib/<package>_meta.dart` — the populated
  /// SOM §7.2 metadata trees plus the SOM §8 navigation surfaces. The facade
  /// exports it, so a consumer never imports it directly; it is reported here
  /// because a caller verifying the committed tree from this result alone
  /// otherwise cannot check that the file it depends on exists.
  final String metaModulePath;

  /// The generated whole-model accessor library, `lib/<package>_model.dart`
  /// (SOM §10.3) — `somSpecModel` plus the embedded `somSpecModelJson`.
  ///
  /// Unlike [metaModulePath] the facade does **not** export this one: the
  /// payload is 6.4 MB, so a consumer opts in with a second import and everyone
  /// else pays nothing for a model they never read. Reported for the same
  /// reason as the metadata library — a caller checking the committed tree from
  /// this result alone would otherwise have no name for the file.
  final String modelModulePath;

  /// The lossless object-model graph, `meta/spec_model.meta.json` (SOM §5.3).
  /// It is validated by `validateSpecModelMeta` *before* it is written, so a
  /// path returned here always names a file that passed validation.
  final String metaJsonPath;

  /// One written `*.docspecs-schema.yaml` per `@Document` root (SOM §5.4), in
  /// the order `DocSpecsSchemaGenerator.writeSchemaTree` produced them. Schemas
  /// are language-agnostic, so this set is byte-identical to the one the Rust /
  /// TypeScript / JavaScript generators write for the same model.
  ///
  /// **Written for every `@Document` root, filter or no filter** — schemas
  /// are selection-agnostic by design, so this list is the one place a
  /// narrowed run still reports the model's full root count.
  final List<String> schemaPaths;

  /// How many **model classes** this run's library covers — the closure
  /// reachable from the [emittedRootCount] selected roots.
  ///
  /// Not the number of generated classes: a `@Form` field and an enum each add
  /// a type beyond their model class, so the emitted library always holds more.
  /// Not the model's own size either — that is stamped in the meta-data named
  /// by [metaJsonPath], and is *higher* even for an unfiltered run, because a
  /// model class no `@Document` root reaches is never emitted.
  final int emittedClassCount;

  /// How many `@Document` roots this run generated a typed root class for —
  /// every root in the model unless `documentRoots` narrowed it.
  ///
  /// The model's *full* root count is [schemaPaths].length: schemas are written
  /// for every root regardless of the filter, so under a narrowed run the two
  /// deliberately disagree.
  final int emittedRootCount;

  /// The model major version stamped into the meta-data and into every
  /// generated DocSpecs schema. A document's authoring stamp is checked against
  /// it at instantiation time, which is what makes an out-of-date document fail
  /// loudly instead of silently mis-reading (SOM §4.2).
  final int modelVersion;

  /// The model's full version label (`1.2.3+45`) as recorded in the meta-data.
  /// The `+build` tail is stripped before it becomes the generated package's
  /// pub version, so a rebuild of the same source version publishes the same
  /// package version.
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
    throw StateError(
      'generated meta-data is invalid:\n  '
      '${metaErrors.join('\n  ')}',
    );
  }
  final metaJsonPath = p.join(outputRoot, 'meta', 'spec_model.meta.json');
  final metaFile = File(metaJsonPath)..parent.createSync(recursive: true);
  metaFile.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(meta)}\n',
  );

  // ── typed Dart facade (editing facade over the generic runtime) ────────────
  final model = SpecModel.fromJson(meta);
  // What this run covers — the selected roots and the model classes
  // reachable from them. Computed once, from the same two rules the
  // emitters below apply, so the reported figures cannot disagree with
  // what was written.
  final emitted = somEmittedSurface(model, documentRoots: documentRoots);
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
  final metaModulePath = p.join(outputRoot, 'lib', '${packageName}_meta.dart');
  File(metaModulePath).writeAsStringSync(metaSource);

  // ── whole-model accessor (SOM §10.3) ──────────────────────────────────────
  // Deliberately NOT exported from the facade: the payload is 6.4 MB, so a
  // consumer opts in with a second import and everyone else pays nothing. It
  // embeds `meta` — the same map just written to spec_model.meta.json — rather
  // than reading that file back, because `Isolate.resolvePackageUri` returns
  // null in an AOT binary and a file-reading accessor would silently read
  // nothing there.
  final modelModulePath = p.join(
    outputRoot,
    'lib',
    '${packageName}_model.dart',
  );
  File(modelModulePath).writeAsStringSync(
    SomDartModelEmitter(
      meta,
      packageName: packageName,
      versionLabel: versionLabel,
    ).generateLibrary(),
  );

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  final schemas = DocSpecsSchemaGenerator(
    classes,
  ).generateAll(modelVersion: modelVersion, modelLabel: modelLabel);
  final schemaPaths = DocSpecsSchemaGenerator.writeSchemaTree(
    outputRoot,
    schemas,
  );

  // ── project pubspec (publishable: hosted runtime dep pinned to the model
  //    version) + a pubspec_overrides.yaml so the co-developed runtime resolves
  //    by path locally without breaking publishability ─────────────────────────
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll(r'\', '/');
  final packageVersion = packageVersionFromModel(modelLabel.split('+').first);
  final pubspecPath = p.join(outputRoot, 'pubspec.yaml');
  File(
    pubspecPath,
  ).writeAsStringSync(_pubspec(packageName, version: packageVersion));
  File(
    p.join(outputRoot, 'pubspec_overrides.yaml'),
  ).writeAsStringSync(_pubspecOverrides(runtimeRel));

  // Pin the analyzer config so a committed checkout analyses identically to the
  // emitter's own clean-analysis guarantee.
  File(
    p.join(outputRoot, 'analysis_options.yaml'),
  ).writeAsStringSync(_analysisOptions);

  return SomGenerationResult(
    outputRoot: outDir.path,
    pubspecPath: pubspecPath,
    libPath: libPath,
    metaModulePath: metaModulePath,
    modelModulePath: modelModulePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    emittedClassCount: emitted.classCount,
    emittedRootCount: emitted.rootCount,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _pubspec(String name, {required String version}) =>
    '''
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
String _pubspecOverrides(String runtimeRel) =>
    '''
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
