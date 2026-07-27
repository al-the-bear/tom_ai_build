# tom_som_dart_runtime

The generic, hand-written Dart runtime for the TomSpecs Specification Object
Model (SOM). It is the language-independent core shared by every generated typed
`tom_som_dart_v0` facade and by both TomSpecs Flutter apps — the editor
(`tom_specs_editor`) and the model reviewer (`tom_specs_reviewer`): the
path-keyed in-memory document representation, the meta-model ("reflection")
classes that load the exported spec-model meta-data, the markdown /
DocSpecs-YAML readers and writers, and the document validator. Pure Dart, no
Flutter dependency.

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

## Versioning

The runtime version tracks the TomSpecs **model version**. The typed
`tom_som_dart_v0` facade pins the same version; upgrade both together when the
model version changes.
