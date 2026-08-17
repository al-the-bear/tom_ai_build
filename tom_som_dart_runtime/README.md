# tom_som_dart_runtime

The generic, hand-written Dart runtime for the TomSpecs Specification Object
Model (SOM). It is the language-independent core shared by every generated typed
`tom_som_dart_v0` facade and by both TomSpecs Flutter apps — the editor
(`tom_specs_editor`) and the model reviewer (`tom_specs_reviewer`): the
path-keyed in-memory document representation, the meta-model ("reflection")
classes that load the exported spec-model meta-data, the markdown /
DocSpecs-YAML readers and writers, the document validator, the Phase-4 CodeSpecs
extractor (`spec_codespecs_extract`, which routes a filled document by
`@CodeSpecKind` into one bounded, cited extract per CodeSpecs area — the machine
half of Phase 4, and the reason that phase is not Dart-only), and the scripting
surface a sandboxed layer needs — the lexical/structural query facility
(`SpecQueryEngine`, matching over the portable `SomTextPattern` subset) and the
model-constrained node-creation gate (`SpecNodeCreator`). Pure Dart, no Flutter
dependency.

This package is the **reference** for the other eight SOM runtimes: everything
they mirror, they mirror from here (SOM §9), and the shared corpus in
`tom_som_conformance` is computed from this runtime rather than hand-written.

Because it is the shared layer, **readers for the spec model belong here rather
than in either app** — an accessor added here is inherited by both, whereas one
added in an app has to be duplicated to reach the other.

Most users depend on the typed facade `tom_som_dart_v0` (which re-exports this
runtime), not on this package directly. Reach for the runtime when you need the
**generic**, untyped document API (`SpecDocument`) or the meta-model.

## How to use

Add `tom_som_dart_runtime` to your `pubspec.yaml`
(`dart pub add tom_som_dart_runtime`), then:

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  // The generic, path-keyed document store underneath every typed facade.
  final doc = SpecDocument();
  doc.setContent('SBP/content', 'A platform that unifies our order systems.');

  print(doc.content('SBP/content'));
}
```

See **readme_howtointegrate.md** for full integration instructions — every
dependency route and how to pin the version.

## Changing the public surface

This package's public surface is the source for the generated D4rt bridges in
`tom_spec_engine` (`lib/src/bridges/som_runtime_bridges.b.dart`), which are
generated **there**, not here. Adding, removing or re-signing anything reachable
from the barrel makes those bridges stale, so follow the edit with:

```bash
cd ../tom_spec_engine && dart run tool/regenerate_bridges.dart
```

The engine's test suite fails until this is done — see
`tom_spec_engine/_copilot_guidelines/bridge_regeneration.md` § "How staleness is
caught" — but it fails only for whoever next runs *that* suite, which is why the
regen belongs here, at the point of editing.

## Versioning

The runtime version tracks the TomSpecs **model version**. The typed
`tom_som_dart_v0` facade pins the same version; upgrade both together when the
model version changes.
