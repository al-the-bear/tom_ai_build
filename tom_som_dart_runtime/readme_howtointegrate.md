# Integrating tom_som_dart_runtime

`tom_som_dart_runtime` is the generic Dart runtime for the TomSpecs object
model. The typed facade `tom_som_dart_v0` depends on it; depend on the runtime
directly only when you want the generic `SpecDocument` / meta-model API. Both
packages are versioned to the TomSpecs **model version** — pin to that version
so your document reads and writes match the model.

## Quick start

Add `tom_som_dart_runtime` to your `pubspec.yaml`
(`dart pub add tom_som_dart_runtime`), then:

```dart
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  final doc = SpecDocument();
  doc.setContent('SBP00/content', 'A platform that unifies our order systems.');
  print(doc.content('SBP00/content'));
}
```

## Dependency routes

### From pub.dev

```bash
dart pub add tom_som_dart_runtime
```

or pin it explicitly in `pubspec.yaml`:

```yaml
dependencies:
  tom_som_dart_runtime: ^1.0.0
```

### Git dependency

```yaml
dependencies:
  tom_som_dart_runtime:
    git:
      url: https://github.com/al-the-bear/tom_ai_build.git
      path: tom_ai/ai_build/tom_som_dart_runtime
```

### Path dependency (monorepo / vendored)

```yaml
dependencies:
  tom_som_dart_runtime:
    path: ../tom_som_dart_runtime
```

## Pinning the version

The runtime carries a version taken from the TomSpecs model version, and the
typed `tom_som_dart_v0` facade carries the same version. When you upgrade the
model, move both to the new matching version so the facade and your stored
documents stay in step.

## Building from source

```bash
cd tom_som_dart_runtime
dart pub get
dart pub publish --dry-run
```
