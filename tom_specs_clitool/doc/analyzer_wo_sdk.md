# Using the Dart Analyzer for Type and Annotation Reading

This guide explains how to use `package:analyzer` for Dart type resolution, annotation reading, and element model traversal in `tom_specs_clitool`. Two approaches are covered: the standard `AnalysisContextCollection` (primary) and the summary-based approach for SDK-free environments (fallback).

## Dependencies

```yaml
dependencies:
  analyzer: ^10.0.0
```

---

## Approach 1: AnalysisContextCollection (Primary)

On any machine with a Dart SDK installed (typical dev environment), the simplest approach is `AnalysisContextCollection`. The SDK is auto-detected from `Platform.resolvedExecutable` — no configuration needed, no `.sum` files required.

### Setup

```dart
import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

Future<void> analyzePackage(String packagePath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [packagePath],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  for (final context in collection.contexts) {
    final analyzedFiles = context.contextRoot.analyzedFiles();
    for (final filePath in analyzedFiles) {
      if (!filePath.endsWith('.dart')) continue;
      final result = await context.currentSession.getResolvedUnit(filePath);
      // Traverse element model, read annotations, inspect types
      final unit = result.unit;
      for (final declaration in unit.declarations) {
        // ... inspect classes, fields, annotations
      }
    }
  }
}
```

### Prerequisites

1. Run `dart pub get` in the target package so `.dart_tool/package_config.json` exists.
2. The Dart SDK must be installed (but this is always the case on a dev machine).

### Characteristics

- **Full type resolution** — all types, generics, and imports are resolved.
- **Full annotation reading** — annotation constructors, arguments, and constant values are available.
- **Full error reporting** — the analyzer produces the same diagnostics as `dart analyze`.
- **No build step** — no `.sum` files to generate or maintain.
- **Note on errors**: For the outliner's purposes (reading types and annotations), analyzer errors in the target code do not prevent traversal. The element model is still constructed even if some expressions fail to resolve.

### For tom_specs_clitool

The outliner generator will:

1. Accept the `tom_specs_model` package path as input.
2. Create an `AnalysisContextCollection` with that path.
3. Iterate over analyzed files and use `getResolvedUnit()` to read class declarations, field types, and annotations.

This is the recommended approach for all development-time use.

---

## Approach 2: Summary Bundles (SDK-Free Fallback)

For environments where no Dart SDK is installed (compiled CLI binaries, CI containers, mobile/web), the analyzer can load **pre-serialized summary bundles** (`.sum` files) instead.

This approach is based on the `tom_dart_editor` implementation.

### Two Summary Files

| File | Contents | Typical size |
|------|----------|-------------|
| `sdk_summary.sum` | Dart SDK core libraries (`dart:core`, `dart:async`, etc.) | ~3 MB |
| `packages.sum` | All pub packages the target code depends on | ~31 MB |

Reference copies exist in `tom_forge/tom_dart_editor_test/assets/`.

### Step 1: Build the SDK Summary

Create a build tool (e.g., `tool/build_sdk_summary.dart`):

```dart
import 'dart:io';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

Future<void> main(List<String> args) async {
  final outputPath = args.isNotEmpty ? args.first : 'assets/sdk_summary.sum';

  final sdkPath = Platform.environment['DART_SDK'] ??
      File(Platform.resolvedExecutable).parent.parent.path;

  final bytes = await buildSdkSummary(
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    sdkPath: sdkPath,
  );

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  print('SDK summary written to $outputPath (${bytes.length} bytes)');
}
```

Run once on a machine with the SDK:

```bash
dart run tool/build_sdk_summary.dart assets/sdk_summary.sum
```

### Step 2: Build the Packages Summary

Create `tool/build_packages_summary.dart`:

```dart
import 'dart:io';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final targetPackagePath = args.isNotEmpty ? args.first : '.';
  final outputPath = args.length > 1 ? args[1] : 'assets/packages.sum';

  // Read package_config.json to discover all dependencies
  // ... parse packages, collect all library URIs recursively ...

  // List ALL .dart files under each package's lib/ (recursive!)
  final libraryUris = <Uri>[];
  for (final pkg in packages) {
    final libDir = Directory(p.join(pkg.rootPath, 'lib'));
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final relativePath = p.relative(entity.path, from: libDir.path);
        libraryUris.add(Uri.parse(
          'package:${pkg.name}/${relativePath.replaceAll('\\', '/')}',
        ));
      }
    }
  }

  final bytes = await analysisDriver.buildPackageBundle(uriList: libraryUris);
  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  print('Package summary written to $outputPath (${bytes.length} bytes)');
}
```

Run once after `dart pub get`:

```bash
dart pub get
dart run tool/build_packages_summary.dart . assets/packages.sum
```

**Critical**: Use `recursive: true` when listing files. If internal `src/` files are missing, deserialization will fail.

### Step 3: Load Summaries at Runtime

The core setup uses `SummaryBasedDartSdk` and `SummaryDataStore` instead of the real SDK:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/source/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';

AnalysisDriver createDriverFromSummaries({
  required Uint8List sdkSummaryBytes,
  required Uint8List packageSummaryBytes,
}) {
  final resourceProvider = PhysicalResourceProvider.INSTANCE;

  // 1. Load SDK from summary
  final sdkBundle = PackageBundleReader(sdkSummaryBytes);
  final sdk = SummaryBasedDartSdk.forBundle(sdkBundle);

  // 2. Create data store and register bundles
  final dataStore = SummaryDataStore();
  dataStore.addBundle('sdk', sdkBundle);

  final packageBundle = PackageBundleReader(packageSummaryBytes);
  dataStore.addBundle('packages', packageBundle);

  // 3. WORKAROUND: Manually register package: URIs
  //    addBundle() registers file URIs, not package: URIs
  for (final library in packageBundle.libraries) {
    final uriStr = library.uriStr;
    if (!dataStore.uriToSummaryPath.containsKey(uriStr)) {
      dataStore.uriToSummaryPath[uriStr] = 'packages';
    }
  }

  // 4. Set up source resolution
  final sourceFactory = SourceFactory([
    DartUriResolver(sdk),
    ResourceUriResolver(resourceProvider),
    PackageSummaryUriResolver(dataStore),  // Custom fallback (see below)
  ]);

  // 5. Create analysis driver
  final scheduler = AnalysisDriverScheduler()..start();
  return AnalysisDriver(
    scheduler: scheduler,
    resourceProvider: resourceProvider,
    sourceFactory: sourceFactory,
    externalSummaries: dataStore,
    packages: Packages.empty,
    analysisOptions: AnalysisOptionsImpl(),
  );
}
```

### The PackageSummaryUriResolver (Required Workaround)

The standard `InSummaryUriResolver` only resolves URIs explicitly registered in `uriToSummaryPath`. Without a fallback resolver, deserialization of internal `src/` files fails.

```dart
class PackageSummaryUriResolver extends UriResolver {
  final SummaryDataStore _dataStore;
  late final Set<String> _knownPackages;

  PackageSummaryUriResolver(this._dataStore) {
    _knownPackages = _dataStore.uriToSummaryPath.keys
        .where((uri) => uri.startsWith('package:'))
        .map((uri) => Uri.parse(uri).pathSegments.first)
        .toSet();
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (uri.scheme != 'package') return null;

    final uriString = uri.toString();

    // Exact match first
    final summaryPath = _dataStore.uriToSummaryPath[uriString];
    if (summaryPath != null) {
      return InSummarySource(
        uri: uri,
        summaryPath: summaryPath,
        kind: InSummarySourceKind.library,
      );
    }

    // Fallback: known package but unregistered internal file
    if (uri.pathSegments.isNotEmpty) {
      final packageName = uri.pathSegments.first;
      if (_knownPackages.contains(packageName)) {
        return InSummarySource(
          uri: uri,
          summaryPath: 'packages',
          kind: InSummarySourceKind.library,
        );
      }
    }

    return null;
  }
}
```

### Key Gotchas

| Issue | Cause | Solution |
|-------|-------|----------|
| `package:` URIs not found | `addBundle()` registers file URIs, not `package:` URIs | Manually register via `uriToSummaryPath[uriStr] = 'packages'` loop |
| Null check error on deserialization | Internal `src/` files missing from bundle | List files **recursively** with `listSync(recursive: true)` |
| Unresolved `package:X/src/...` at runtime | Standard resolver doesn't know internal files | Use `PackageSummaryUriResolver` fallback for known packages |
| SDK path needed | Only for building the summary, not at runtime | Use `Platform.resolvedExecutable` parent to find SDK during build |

---

## Reference Implementation

- `tom_dart_editor`: `tom_forge/tom_dart_editor/` — reference for summary-based analysis
  - `lib/src/analyzer_with_packages.dart` — summary driver setup
  - `lib/src/summary_analysis_adapter.dart` — adapter layer
  - `doc/dart_editor_usage_guide.md` — usage guide
- `tom_dart_editor_test`: `tom_forge/tom_dart_editor_test/`
  - `assets/sdk_summary.sum` (~3 MB) — pre-built SDK summary
  - `assets/packages.sum` (~31 MB) — pre-built packages summary
  - `tool/build_packages_summary.dart` — build tool
  - `tool/diagnose_packages_sum.dart` — diagnostics tool
