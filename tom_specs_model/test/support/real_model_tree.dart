/// The real model's SOM metadata tree, for tests that serialize.
///
/// `SpecYaml` writes through `SpecDocumentYaml`, which needs the metadata tree
/// of the root being written (SOM §12). The tree the *production* callers pass
/// comes from the generated facade; a test can build the same tree from the
/// committed `spec_model.meta.json` via [buildSomMetaTree], which is the exact
/// input the other eight runtimes read.
///
/// A `SomMetaNode` belongs to **one** `SomMetaTree` — wiring it into a second
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
final String realModelMetaPath =
    Directory.current.path.endsWith('tom_specs_model')
    ? '${Directory.current.path}/../tom_som_dart_v0/meta/spec_model.meta.json'
    : '${Directory.current.path}/tom_som_dart_v0/meta/spec_model.meta.json';

/// Whether that file is actually there.
///
/// It is a **workspace sibling**, so it exists in a checkout and does not exist
/// in a hosted install of this package — and these tests ship in the published
/// archive. Before this check they threw `PathNotFoundException` there: a
/// consumer running `dart test` on what pub.dev carries saw seven crashes and
/// no explanation. Found by `tom_specs_clitool/tool/verify_published_tests.sh`,
/// which runs the published archive the way a consumer would.
///
/// The path is assembled from `Directory.current` rather than written as a
/// literal, which is exactly why the lexical `check_shipped_paths` gate could
/// not see it — the blind spot that tool exists to cover.
bool get hasRealModel => File(realModelMetaPath).existsSync();

/// Why the real-model groups skip when [hasRealModel] is false.
///
/// Stated rather than silent: a skipped group must say what would have to be
/// true for it to run, or a reader cannot tell an unrunnable test from a
/// deleted one.
const String realModelAbsentReason =
    'needs the generated tom_som_dart_v0/meta/spec_model.meta.json, which is a '
    'workspace sibling — present in a checkout, absent in a hosted install of '
    'this package';

SpecModel? _cached;

/// The parsed meta export, read once per test process.
SpecModel realModel() => _cached ??= SpecModel.fromJson(
  jsonDecode(File(realModelMetaPath).readAsStringSync())
      as Map<String, dynamic>,
);

/// A freshly wired metadata tree for [rootType] (one of the fourteen document
/// roots, e.g. `D00SolutionBlueprint`).
SomMetaTree treeFor(String rootType) =>
    buildSomMetaTree(realModel(), rootType: rootType);
