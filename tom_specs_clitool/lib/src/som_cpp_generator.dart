/// Runs the full `v0` Spec-Object-Model generation for **C++** and writes the
/// committed artefact tree (spec §2.3): the `tom_som_cpp_<label>` project (a
/// `Makefile` + the generated typed header/source pair), the lossless
/// object-model **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the C++ counterpart of `som_generator.dart` / `som_c_generator.dart`
/// (som_multiplatform_spec_model.md §10). The **meta-data file and the DocSpecs schemas are
/// language-agnostic**, so this reuses the exact same [ModelJsonExporter] +
/// [DocSpecsSchemaGenerator] the other paths use (byte-identical across
/// languages); only the typed source emitter ([SomCppEmitter]) and the build
/// manifest differ. Generation is deterministic and idempotency-stabilised (the
/// wall-clock `generatedAt` is overridden with the model build instant), so
/// re-running over an unchanged model is a byte-for-byte no-op.
///
/// C++ resolves the generic runtime header purely through the **include path**.
/// This generator wires resolution by writing a `Makefile` whose `RUNTIME_DIR`
/// defaults to a relative path to the local runtime checkout (computed from
/// [outputRoot]); the build adds `-I$(RUNTIME_DIR)/include`, builds the runtime
/// static library on demand, and archives the generated translation unit into a
/// static (`build/libtom_som_cpp_v0.a`) and a shared (`build/libtom_som_cpp_v0.so`)
/// library. C++ has no universal package registry, so the `Makefile` also emits a
/// `pkg-config` file (`tom_som_cpp_v0.pc`, `Version` = the model version,
/// `Requires: tom_som_cpp_runtime`) and provides `make install` (headers +
/// libraries + `.pc`) and `make dist` (versioned source tarball) targets,
/// mirroring the hand-authored runtime. The emitted C++ source carries no on-disk
/// path and stays layout-independent / golden-stable.
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
import 'som_cpp_emitter.dart';
import 'som_cpp_meta_emitter.dart';
import 'spec_model_meta_validator.dart';

/// The committed paths and counts produced by the C++ generator.
class SomCppGenerationResult {
  SomCppGenerationResult({
    required this.outputRoot,
    required this.makefilePath,
    required this.headerPath,
    required this.sourcePath,
    required this.metaModuleHeaderPath,
    required this.metaModuleSourcePath,
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

  /// The generated metadata module header/source pair (`tom_som_cpp_v0_meta.hpp`
  /// / `.cpp`): the populated SomMetaTrees plus the dot-notation and ID-tree
  /// access surfaces.
  final String metaModuleHeaderPath;
  final String metaModuleSourcePath;
  final String metaJsonPath;
  final List<String> schemaPaths;
  final int classCount;
  final int rootCount;
  final int modelVersion;
  final String modelLabel;
}

/// Generates the C++ `v0` artefact tree from [modelPackagePath] into
/// [outputRoot].
///
/// * [outputRoot] — the `tom_som_cpp_<label>` project directory (created).
/// * [runtimePackagePath] — `tom_som_cpp_runtime`; the generated `Makefile`
///   records it as a relative `RUNTIME_DIR` default (computed from [outputRoot])
///   so the committed file is portable across machines/checkout roots.
/// * [versionLabel] — `v0` (drives the generated model-version major).
/// * [documentRoots] — empty ⇒ every document root.
/// * [modelVersion] / [modelLabel] / [generatedAt] — the model version stamp
///   baked into the meta-data (kept stable for idempotency).
Future<SomCppGenerationResult> generateSomCppProject({
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

  return writeSomCppProject(
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

/// Writes the C++ artefact tree from an already-analysed [classes] graph.
///
/// Split out from [generateSomCppProject] so callers that have already run the
/// analyzer (or tests with a hand-built graph) can drive the deterministic write
/// step without re-analysing.
SomCppGenerationResult writeSomCppProject({
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
  // Every SOM package (runtime + facade) is stamped with the TomSpecs model
  // version — the facade Makefile's `VERSION` and the emitted pkg-config
  // `Version` both use it so the facade, the runtime, and the `.pc` agree.
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

  // ── typed C++ facade (editing facade over the generic runtime) ─────────────
  final model = SpecModel.fromJson(meta);
  final emitter = SomCppEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  );
  final headerPath = p.join(outputRoot, 'include', 'tom_som_cpp_v0.hpp');
  File(headerPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(emitter.generateHeader());
  final sourcePath = p.join(outputRoot, 'src', 'tom_som_cpp_v0.cpp');
  File(sourcePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(emitter.generateSource());

  // ── generated metadata module: populated SomMetaTrees plus the dot-notation
  //    and ID-tree access surfaces, required by the facade's load functions
  //    (which thread the per-root tree into the runtime decoder) ──────────────
  final metaEmitter = SomCppMetaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  );
  final metaModuleHeaderPath =
      p.join(outputRoot, 'include', 'tom_som_cpp_v0_meta.hpp');
  File(metaModuleHeaderPath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(metaEmitter.generateHeader());
  final metaModuleSourcePath =
      p.join(outputRoot, 'src', 'tom_som_cpp_v0_meta.cpp');
  File(metaModuleSourcePath)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(metaEmitter.generateSource());

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to every other language path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── Makefile (relative RUNTIME_DIR include/link wiring) ────────────────────
  // C++ has no module system: the generated source resolves the runtime header
  // purely through the include path. A relative `RUNTIME_DIR` default points the
  // build at the local runtime checkout (overridable on the command line), so
  // the committed file is portable across machines and checkout roots.
  final runtimeRel = p
      .relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot))
      .replaceAll('\\', '/');
  final makefilePath = p.join(outputRoot, 'Makefile');
  File(makefilePath).writeAsStringSync(_makefile(runtimeRel, packageVersion));

  return SomCppGenerationResult(
    outputRoot: outDir.path,
    makefilePath: makefilePath,
    headerPath: headerPath,
    sourcePath: sourcePath,
    metaModuleHeaderPath: metaModuleHeaderPath,
    metaModuleSourcePath: metaModuleSourcePath,
    metaJsonPath: metaJsonPath,
    schemaPaths: schemaPaths,
    classCount: classes.length,
    rootCount: meta['rootCount'] as int,
    modelVersion: modelVersion,
    modelLabel: modelLabel,
  );
}

String _makefile(String runtimeRel, String version) {
  // The generated translation unit compiles against the runtime headers and is
  // archived into a static library (`.a`) and linked into a shared library
  // (`.so`); the runtime's own static library is built on demand via a recursive
  // make. `RUNTIME_DIR` is relative for portability and overridable (e.g.
  // `make RUNTIME_DIR=/abs/path`). C++ has no universal registry, so packaging is
  // a library + headers + pkg-config file (installed or vendored) plus a source
  // tarball: `VERSION` (= the model version) stamps both the `.pc` `Version` and
  // the `make dist` tarball, and `make install` / `make dist` mirror the runtime.
  return '# GENERATED by tom_specs_clitool SomCppGenerator — do not edit by hand.\n'
      '# Builds the generated tom_som_cpp_v0 typed facade against tom_som_cpp_runtime.\n'
      '\n'
      '# VERSION is the TomSpecs model version; the pkg-config Version and the\n'
      '# dist tarball both track it, matching the runtime.\n'
      'VERSION := $version\n'
      'NAME := tom_som_cpp_v0\n'
      '\n'
      'RUNTIME_DIR ?= $runtimeRel\n'
      'CXX ?= g++\n'
      'AR ?= ar\n'
      'CXXFLAGS ?= -std=c++17 -Wall -Wextra -O2\n'
      'PICFLAGS := -fPIC\n'
      'CPPFLAGS += -Iinclude -I\$(RUNTIME_DIR)/include\n'
      '\n'
      '# Install layout (GNU-standard; DESTDIR-aware for staged installs).\n'
      'PREFIX       ?= /usr/local\n'
      'INCLUDEDIR   ?= \$(PREFIX)/include\n'
      'LIBDIR       ?= \$(PREFIX)/lib\n'
      'PKGCONFIGDIR ?= \$(LIBDIR)/pkgconfig\n'
      '\n'
      'BUILD := build\n'
      'STATIC := \$(BUILD)/lib\$(NAME).a\n'
      'SHARED := \$(BUILD)/lib\$(NAME).so\n'
      '# soname carries only the major version (ABI compatibility boundary).\n'
      'SONAME := lib\$(NAME).so.\$(firstword \$(subst ., ,\$(VERSION)))\n'
      "# Apple's ld spells the soname option -install_name; GNU ld uses -soname.\n"
      "# Apple's ld also rejects undefined symbols in a dylib by default, while GNU\n"
      '# ld allows them for -shared — the facade deliberately leaves the runtime\n'
      '# symbols undefined (the consumer links the runtime), so ask for dynamic lookup.\n'
      'ifeq (\$(shell uname -s),Darwin)\n'
      'SONAME_FLAG := -Wl,-install_name,\$(SONAME)\n'
      'UNDEF_FLAG  := -Wl,-undefined,dynamic_lookup\n'
      'else\n'
      'SONAME_FLAG := -Wl,-soname,\$(SONAME)\n'
      'UNDEF_FLAG  :=\n'
      'endif\n'
      'PC     := \$(BUILD)/\$(NAME).pc\n'
      'OBJ    := \$(BUILD)/tom_som_cpp_v0.o \$(BUILD)/tom_som_cpp_v0_meta.o\n'
      'PICOBJ := \$(BUILD)/tom_som_cpp_v0.pic.o \$(BUILD)/tom_som_cpp_v0_meta.pic.o\n'
      'RUNTIME_LIB := \$(RUNTIME_DIR)/build/libtom_som_cpp_runtime.a\n'
      'HEADER := include/tom_som_cpp_v0.hpp include/tom_som_cpp_v0_meta.hpp\n'
      '\n'
      '.PHONY: all clean runtime install dist FORCE\n'
      'all: \$(STATIC) \$(SHARED) \$(PC)\n'
      '\n'
      'FORCE:\n'
      '\n'
      '# Build the generic runtime static library on demand.\n'
      'runtime:\n'
      '\t\$(MAKE) -C \$(RUNTIME_DIR)\n'
      '\n'
      '\$(RUNTIME_LIB): runtime\n'
      '\n'
      '\$(BUILD)/%.o: src/%.cpp \$(HEADER) | \$(BUILD)\n'
      '\t\$(CXX) \$(CXXFLAGS) \$(CPPFLAGS) -c \$< -o \$@\n'
      '\n'
      '\$(BUILD)/%.pic.o: src/%.cpp \$(HEADER) | \$(BUILD)\n'
      '\t\$(CXX) \$(CXXFLAGS) \$(PICFLAGS) \$(CPPFLAGS) -c \$< -o \$@\n'
      '\n'
      '\$(STATIC): \$(OBJ)\n'
      '\t\$(AR) rcs \$@ \$^\n'
      '\n'
      '# The shared facade leaves the runtime symbols undefined; they are resolved\n'
      '# when the consumer links the runtime library (matching the static path).\n'
      '\$(SHARED): \$(PICOBJ)\n'
      '\t\$(CXX) -shared \$(SONAME_FLAG) \$(UNDEF_FLAG) -o \$@ \$^\n'
      '\n'
      '# pkg-config metadata; Version tracks the model version, Requires pulls the\n'
      '# runtime .pc so consumers get its include/link flags too. Regenerated on\n'
      '# every build (FORCE) so an install-time PREFIX override lands in the .pc.\n'
      '\$(PC): FORCE | \$(BUILD)\n'
      '\t@printf \'%s\\n\' \\\n'
      '\t  \'prefix=\$(PREFIX)\' \\\n'
      '\t  \'exec_prefix=\$\${prefix}\' \\\n'
      '\t  \'libdir=\$(LIBDIR)\' \\\n'
      '\t  \'includedir=\$(INCLUDEDIR)\' \\\n'
      '\t  \'\' \\\n'
      '\t  \'Name: \$(NAME)\' \\\n'
      '\t  \'Description: Generated typed TomSpecs object-model facade (C++).\' \\\n'
      '\t  \'Version: \$(VERSION)\' \\\n'
      '\t  \'Requires: tom_som_cpp_runtime\' \\\n'
      '\t  \'Libs: -L\$\${libdir} -l\$(NAME)\' \\\n'
      '\t  \'Cflags: -I\$\${includedir}\' \\\n'
      '\t  > \$@\n'
      '\n'
      '\$(BUILD):\n'
      '\tmkdir -p \$(BUILD)\n'
      '\n'
      '# Install the header, the static + shared libraries (with the versioned\n'
      '# soname symlinks), and the pkg-config file. Honours DESTDIR.\n'
      'install: all\n'
      '\tinstall -d \$(DESTDIR)\$(INCLUDEDIR) \$(DESTDIR)\$(LIBDIR) \$(DESTDIR)\$(PKGCONFIGDIR)\n'
      '\tinstall -m 0644 \$(HEADER) \$(DESTDIR)\$(INCLUDEDIR)/\n'
      '\tinstall -m 0644 \$(STATIC) \$(DESTDIR)\$(LIBDIR)/\n'
      '\tinstall -m 0755 \$(SHARED) \$(DESTDIR)\$(LIBDIR)/lib\$(NAME).so.\$(VERSION)\n'
      '\tln -sf lib\$(NAME).so.\$(VERSION) \$(DESTDIR)\$(LIBDIR)/\$(SONAME)\n'
      '\tln -sf \$(SONAME) \$(DESTDIR)\$(LIBDIR)/lib\$(NAME).so\n'
      '\tinstall -m 0644 \$(PC) \$(DESTDIR)\$(PKGCONFIGDIR)/\n'
      '\n'
      '# Source distribution tarball, versioned by the model version.\n'
      'DIST := \$(NAME)-\$(VERSION)\n'
      'DIST_FILES := Makefile \$(wildcard README.md LICENSE CHANGELOG.md readme_howtointegrate.md)\n'
      'DIST_DIRS := src include \$(wildcard meta schemas examples)\n'
      'dist:\n'
      '\trm -rf \$(BUILD)/\$(DIST) \$(BUILD)/\$(DIST).tar.gz\n'
      '\tmkdir -p \$(BUILD)/\$(DIST)\n'
      '\tcp -r \$(DIST_DIRS) \$(DIST_FILES) \$(BUILD)/\$(DIST)/\n'
      '\ttar -czf \$(BUILD)/\$(DIST).tar.gz -C \$(BUILD) \$(DIST)\n'
      '\trm -rf \$(BUILD)/\$(DIST)\n'
      '\n'
      'clean:\n'
      '\trm -rf \$(BUILD)\n';
}
