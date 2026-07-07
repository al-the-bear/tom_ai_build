# tom_som_dart_runtime

The generic, hand-written Dart runtime for the TomSpecs Specification Object
Model (SOM). It is the language-independent core shared by every generated typed
`tom_som_dart_v0` facade and the TomSpecs editor: the path-keyed in-memory
document representation, the meta-model ("reflection") classes that load the
exported spec-model meta-data, the markdown / DocSpecs-YAML readers and writers,
and the document validator. Pure Dart, no Flutter dependency.

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
  doc.setContent('SBP00/content', 'A platform that unifies our order systems.');

  print(doc.content('SBP00/content'));
}
```

See **readme_howtointegrate.md** for full integration instructions — every
dependency route and how to pin the version.

## Versioning

The runtime version tracks the TomSpecs **model version**. The typed
`tom_som_dart_v0` facade pins the same version; upgrade both together when the
model version changes.
