/// Runs the full `v0` Spec-Object-Model generation for **Python** and writes the
/// committed artefact tree (SOM §4.3): the `tom_som_python_<label>` project
/// (`pyproject.toml` + generated typed module), the lossless object-model
/// **meta-data file**, and the **DocSpecs schemas**.
///
/// This is the Python counterpart of `som_generator.dart` (som_multiplatform_spec_model.md §10). The
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
import 'packaging.dart' show packageVersionFromModel;
import 'som_python_emitter.dart';
import 'som_python_meta_emitter.dart';
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

  // ── generated metadata module (SOM §8): populated SomMetaTrees (SOM §7.2)
  //    plus the dot-notation and ID-tree access surfaces (SOM §8), re-exported
  //    from the main facade module ─────────────────────────────────────────────
  final metaSource = SomPythonMetaEmitter(
    model,
    versionLabel: versionLabel,
    documentRoots: documentRoots,
  ).generateLibrary();
  File(p.join(outputRoot, '${packageName}_meta.py')).writeAsStringSync(metaSource);

  // ── DocSpecs schemas (one per @Document root) ──────────────────────────────
  // Identical to the Dart path — schemas are language-agnostic.
  final schemas =
      DocSpecsSchemaGenerator(classes).generateAll(modelVersion: modelVersion);
  final schemaPaths =
      DocSpecsSchemaGenerator.writeSchemaTree(outputRoot, schemas);

  // ── wheel data inclusion + installed-location resolution ──────────────────
  // A `py-modules` distribution ships only the listed .py files, so without
  // these the wheel would carry neither meta/ nor schemas/ (the tspubb1 PyPI
  // data gap). The two data trees become importable data packages via the
  // `[tool.setuptools.package-dir]` mapping in the manifest below; the
  // `__init__.py` markers make them packageable, and `<package>_data.py` is
  // the resolution front door that works in both layouts (checkout sibling
  // folders vs installed packages).
  File(p.join(outputRoot, 'meta', '__init__.py'))
      .writeAsStringSync(_dataPackageInit(
    packageName,
    folder: 'meta',
    dataPackage: '${packageName}_meta_data',
    contents: 'the lossless object-model meta-data (spec_model.meta.json)',
  ));
  File(p.join(outputRoot, 'schemas', '__init__.py'))
      .writeAsStringSync(_dataPackageInit(
    packageName,
    folder: 'schemas',
    dataPackage: '${packageName}_schemas',
    contents: 'the DocSpecs schemas (one folder per document root)',
  ));
  File(p.join(outputRoot, '${packageName}_data.py'))
      .writeAsStringSync(_dataResolutionModule(packageName));

  // ── project manifest (relative runtime path for portability) ───────────────
  final runtimeRel =
      p.relative(p.normalize(runtimePackagePath), from: p.normalize(outputRoot));
  final packageVersion = packageVersionFromModel(modelLabel.split('+').first);
  final pyprojectPath = p.join(outputRoot, 'pyproject.toml');
  File(pyprojectPath).writeAsStringSync(_pyproject(
    packageName,
    runtimeRel.replaceAll(r'\\', '/'),
    version: packageVersion,
  ));

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

String _pyproject(String name, String runtimeRel, {required String version}) =>
    '''
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
[build-system]
# setuptools >= 77 for PEP 639 SPDX licence-expression metadata (the plain
# `license = "BSD-3-Clause"` string below).
requires = ["setuptools>=77"]
build-backend = "setuptools.build_meta"

[project]
name = "$name"
# Version is the TomSpecs model version — the facade is regenerated per model
# version and always reports it (never maintained independently).
version = "$version"
description = "Generated typed TomSpecs object model (v0). An editing facade over the generic tom_som_python_runtime; see the meta-data file and DocSpecs schemas in this package. Regenerate with tom_specs_clitool/bin/generate_som.dart."
requires-python = ">=3.9"
readme = "README.md"
# PEP 639 SPDX licence expression, per the release-1 licence decision.
license = "BSD-3-Clause"
license-files = ["LICENSE"]
# The generic runtime this facade edits over, pinned to the same model version.
# For local, unpublished development resolve it via `[tool.tom_som] runtime-path`
# below (add it to PYTHONPATH) or `pip install -e ../tom_som_python_runtime`.
dependencies = ["tom_som_python_runtime>=$version"]

# Three top-level modules (not a package) — the typed facade, its generated
# metadata module and the data-file resolution module — listed explicitly so
# setuptools does not attempt flat-layout auto-discovery over the sibling data
# folders (meta/, schemas/, examples/, tests/).
[tool.setuptools]
py-modules = ["$name", "${name}_meta", "${name}_data"]
# The two data trees ship inside the wheel as importable data packages, mapped
# from their checkout folder names. `${name}_data` resolves them in either
# layout (installed packages first, then the checkout sibling folders).
packages = ["${name}_meta_data", "${name}_schemas"]

[tool.setuptools.package-dir]
"${name}_meta_data" = "meta"
"${name}_schemas" = "schemas"

[tool.setuptools.package-data]
"${name}_meta_data" = ["*.json"]
"${name}_schemas" = ["**/*.yaml"]

[project.urls]
Repository = "https://github.com/al-the-bear/tom_ai_build"

[tool.tom_som]
# The generic runtime this typed facade edits over. Add it to PYTHONPATH (or
# install it) so `import tom_som_runtime` resolves. The path is relative to this
# project root for portability across machines and checkout roots.
runtime-path = "$runtimeRel/tom_som_runtime"
''';

/// The `__init__.py` marker that turns a checkout data folder (`meta/`,
/// `schemas/`) into the buildable data package the wheel ships it as.
String _dataPackageInit(
  String packageName, {
  required String folder,
  required String dataPackage,
  required String contents,
}) =>
    '''
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
"""Data package for $contents.

In an installed wheel this folder is the importable package ``$dataPackage``
(mapped from `$folder/` in pyproject.toml's ``[tool.setuptools.package-dir]``);
in a source checkout it is the plain ``$folder/`` sibling of the
``$packageName`` module. Resolve it through ``${packageName}_data`` rather than
importing it directly — the folder is data, not code.
"""
''';

/// The `<package>_data.py` module: installed-location resolution for the two
/// shipped data trees, working in both the source-checkout layout (sibling
/// `meta/` + `schemas/` folders) and the installed-wheel layout (the mapped
/// data packages).
String _dataResolutionModule(String packageName) => '''
# GENERATED by tom_specs_clitool generate_som — do not edit by hand.
"""Installed-location resolution for the data files shipped with
``$packageName`` (SOM §17.3).

The distribution carries two non-code data trees: ``meta/`` (the lossless
object-model meta-data, ``spec_model.meta.json``) and ``schemas/`` (the
DocSpecs schemas, one folder per document root). In a source checkout they are
sibling folders of this module; in an installed wheel they are the importable
data packages ``${packageName}_meta_data`` and ``${packageName}_schemas``
(mapped in pyproject.toml). These helpers resolve either layout — installed
package first, checkout sibling second — so consumers never hard-code a
checkout-relative path.
"""

from __future__ import annotations

import importlib.util
import os

_HERE = os.path.dirname(os.path.abspath(__file__))


def _resolve(dir_name, package_name, probe):
    """The on-disk folder holding the ``dir_name`` data tree.

    Tries the installed data package first (a wheel install), then the
    source-checkout sibling folder. ``probe`` is a file expected inside a
    correct resolution, so an unrelated top-level package cannot shadow the
    data by name alone.
    """
    spec = importlib.util.find_spec(package_name)
    if spec is not None and spec.origin:
        root = os.path.dirname(os.path.abspath(spec.origin))
        if os.path.exists(os.path.join(root, probe)):
            return root
    sibling = os.path.join(_HERE, dir_name)
    if os.path.exists(os.path.join(sibling, probe)):
        return sibling
    raise FileNotFoundError(
        "cannot resolve the '%s' data tree of $packageName: neither the "
        "installed package '%s' nor the checkout sibling '%s' carries '%s'"
        % (dir_name, package_name, sibling, probe))


def spec_model_meta_path():
    """Path of the shipped ``spec_model.meta.json`` (the lossless class graph)."""
    return os.path.join(
        _resolve("meta", "${packageName}_meta_data", "spec_model.meta.json"),
        "spec_model.meta.json")


def schemas_root():
    """Root folder of the shipped DocSpecs schemas (one subfolder per root)."""
    return _resolve("schemas", "${packageName}_schemas", "__init__.py")
''';
