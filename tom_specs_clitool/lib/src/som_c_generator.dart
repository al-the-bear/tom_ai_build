/// Runs the full `v0` Spec-Object-Model generation for **C** and writes the
/// committed artefact tree (spec §2.3): the `tom_som_c_<label>` project (a
/// `Makefile` + the generated typed header/source pair), the lossless
/// object-model **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the C counterpart of `som_generator.dart` /
/// `som_python_generator.dart` / `som_java_generator.dart` /
/// `som_javascript_generator.dart` / `som_typescript_generator.dart` /
/// `som_go_generator.dart` / `som_rust_generator.dart` (plan item #11). The
/// **meta-data file and the DocSpecs schemas are language-agnostic**, so this
/// reuses the exact same [ModelJsonExporter] + [DocSpecsSchemaGenerator] the
/// other paths use (byte-identical across languages); only the typed source
/// emitter ([SomCEmitter]) and the build manifest differ. Generation is
/// deterministic and idempotency-stabilised (the wall-clock `generatedAt` is
/// overridden with the model build instant), so re-running over an unchanged
/// model is a byte-for-byte no-op.
///
/// C has no module system, so the generated `#include "tom_som_c_runtime.h"`
/// resolves purely through the **include path**. This generator wires resolution
/// by writing a `Makefile` whose `RUNTIME_DIR` defaults to a relative path to the
/// local runtime checkout (computed from [outputRoot]); the build adds
/// `-I$(RUNTIME_DIR)/include`, builds the runtime static library on demand, and
/// archives the generated translation unit into `build/libtom_som_c_v0.a`. The
/// emitted C source carries no on-disk path and stays layout-independent /
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
import 'som_c_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the C generator.
class SomCGenerationResult {
  SomCGenerationResult({
    required this.outputRoot,
    required this.makefilePath,
    required this.headerPath,
    required this.sourcePath,
    required this.metaJsonPath,
    required this.schemaPaths,
    required this.classCount,
    required this.rootCount,
    required this.modelVersion,
    required this.modelLabel,
  });

  final String outputRoot;
  final String makefilePath;
  final String headerPath;
  final String sourcePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the C `v0` artefact tree from [modelPackagePath] into [outputRoot].
///
/// * [outputRoot] — the `tom_som_c_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_c_runtime`; the generated `Makefile`
///   records it as a relative `RUNTIME_DIR` default (computed from [outputRoot])
///   so the committed file is portable across machines/checkout roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomCGenerationResult> generateSomCProject({
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

  return writeSomCProject(
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

/// Writes the C artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomCProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic write
/// step without re-analysing.
SomCGenerationResult writeSomCProject({
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

  // ── typed C facade (editing facade over the generic runtime) ───────────────
  final model = SpecModel.fromJson(meta);
  final emitter = SomCEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  );
  final headerPath = p.join(outputRoot, 'include', 'tom_som_c_v0.h');
  File(headerPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(emitter.generateHeader());
  final sourcePath = p.join(outputRoot, 'src', 'tom_som_c_v0.c');
  File(sourcePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(emitter.generateSource());

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to every other language path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── Makefile (relative RUNTIME_DIR include/link wiring) ────────────────────
  // C has no module system: the generated source resolves the runtime header
  // purely through the include path. A relative `RUNTIME_DIR` default points the
  // build at the local runtime checkout (overridable on the command line), so
  // the committed file is portable across machines and checkout roots.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll('\\', '/');
  final makefilePath = p.join(outputRoot, 'Makefile');
  File(makefilePath).writeAsStringSync(_makefile(runtimeRel));

  return SomCGenerationResult(
    outputRoot: outDir.path,
    makefilePath: makefilePath,
    headerPath: headerPath,
    sourcePath: sourcePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _makefile(String runtimeRel) {
  // The generated translation unit compiles against the runtime headers and
  // archives into a static library; the runtime's own static library is built on
  // demand via a recursive make. `RUNTIME_DIR` is relative for portability and
  // overridable (e.g. `make RUNTIME_DIR=/abs/path`).
  return '# GENERATED by tom_specs_clitool SomCGenerator — do not edit by hand.\n'
      '# Builds the generated tom_som_c_v0 typed facade against tom_som_c_runtime.\n'
      '\n'
      'RUNTIME_DIR ?= $runtimeRel\n'
      'CC ?= cc\n'
      'CFLAGS ?= -std=c11 -Wall -Wextra -O2\n'
      'CPPFLAGS += -Iinclude -I\$(RUNTIME_DIR)/include\n'
      '\n'
      'BUILD := build\n'
      'LIB := \$(BUILD)/libtom_som_c_v0.a\n'
      'RUNTIME_LIB := \$(RUNTIME_DIR)/build/libtom_som_c_runtime.a\n'
      'OBJ := \$(BUILD)/tom_som_c_v0.o\n'
      '\n'
      '.PHONY: all clean runtime\n'
      'all: \$(LIB)\n'
      '\n'
      '# Build the generic runtime static library on demand.\n'
      'runtime:\n'
      '\t\$(MAKE) -C \$(RUNTIME_DIR)\n'
      '\n'
      '\$(RUNTIME_LIB): runtime\n'
      '\n'
      '\$(OBJ): src/tom_som_c_v0.c include/tom_som_c_v0.h | \$(BUILD)\n'
      '\t\$(CC) \$(CFLAGS) \$(CPPFLAGS) -c \$< -o \$@\n'
      '\n'
      '\$(LIB): \$(OBJ)\n'
      '\tar rcs \$@ \$^\n'
      '\n'
      '\$(BUILD):\n'
      '\tmkdir -p \$(BUILD)\n'
      '\n'
      'clean:\n'
      '\trm -rf \$(BUILD)\n';
}
