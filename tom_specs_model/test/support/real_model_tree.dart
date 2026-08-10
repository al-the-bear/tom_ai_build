/// The real model's SOM metadata tree, for tests that serialize.
///
/// `SpecYaml` writes through `SpecDocumentYaml`, which needs the metadata tree
/// of the root being written (SOM §12). The tree the *production* callers pass
/// comes from the generated facade; a test can build the same tree from the
/// committed `spec_model.meta.json` via [buildSomMetaTree], which is the exact
/// input the other eight runtimes read.
///
/// A [SomMetaNode] belongs to **one** [SomMetaTree] — wiring it into a second
/// throws — so [treeFor] builds a fresh tree on every call and only the parsed
/// [SpecModel] is cached.
library;

import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SomMetaTree, SpecModel, buildSomMetaTree;

/// The committed meta export the nine runtimes are generated from. Resolved
/// relative to the package root (tests run with that as the cwd), the same way
/// `tom_specs_clitool`'s meta-driven tests resolve it.
final String realModelMetaPath = Directory.current.path.endsWith('tom_specs_model')
    ? '${Directory.current.path}/../tom_som_dart_v0/meta/spec_model.meta.json'
    : '${Directory.current.path}/tom_som_dart_v0/meta/spec_model.meta.json';

SpecModel? _cached;

/// The parsed meta export, read once per test process.
SpecModel realModel() => _cached ??= SpecModel.fromJson(
    jsonDecode(File(realModelMetaPath).readAsStringSync())
        as Map<String, dynamic>);

/// A freshly wired metadata tree for [rootType] (one of the fourteen document
/// roots, e.g. `D00SolutionBlueprint`).
SomMetaTree treeFor(String rootType) =>
    buildSomMetaTree(realModel(), rootType: rootType);
