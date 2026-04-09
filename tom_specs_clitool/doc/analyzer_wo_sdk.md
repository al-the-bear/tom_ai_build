# Using the Dart Analyzer Without an Installed SDK

This guide explains how to use `package:analyzer` for full Dart analysis (type resolution, annotation reading, element model traversal) **without requiring a Dart SDK on the target machine**. The approach is based on the `tom_dart_editor` implementation.

## Overview

The strategy replaces the on-disk SDK with **pre-serialized summary bundles** (`.sum` files):

1. **Build time** — run a tool that serializes the SDK and package element models into binary `.sum` files.
2. **Runtime** — the analyzer loads these summaries in memory instead of reading SDK/package source files.

For `tom_specs_clitool`, this means the outliner can analyze model classes from summary files without needing `dart` on the PATH.

## Dependencies

```yaml
dependencies:
  analyzer: ^10.0.0
```

The analyzer's internal summary APIs are used. These are not public API, so pin the version carefully.

## Two Summary Files

| File | Contents | Typical size |
|------|----------|-------------|
| `sdk_summary.sum` | Dart SDK core libraries (`dart:core`, `dart:async`, etc.) | ~3 MB |
| `packages.sum` | All pub packages the target code depends on | Varies (5–30+ MB) |

## Step 1: Build the SDK Summary

Create a build tool (e.g., `tool/build_sdk_summary.dart`):

```dart
import 'dart:io';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';

Future<void> main(List<String> args) async {
  final outputPath = args.isNotEmpty ? args.first : 'assets/sdk_summary.sum';

  // Uses the currently installed SDK to BUILD the summary
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

Run once on a machine that has the SDK:

```bash
dart run tool/build_sdk_summary.dart assets/sdk_summary.sum
```

## Step 2: Build the Packages Summary

Create `tool/build_packages_summary.dart`:

```dart
import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final targetPackagePath = args.isNotEmpty ? args.first : '.';
  final outputPath = args.length > 1 ? args[1] : 'assets/packages.sum';

  // Read package_config.json to discover all dependencies
  final packageConfigFile = File(
    p.join(targetPackagePath, '.dart_tool', 'package_config.json'),
  );
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

  // Build the bundle
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

## Step 3: Load Summaries at Runtime

The core setup uses `SummaryBasedDartSdk` and `SummaryDataStore` instead of the real SDK:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:analyzer/dart/analysis/analysis_options.dart';
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

### Using the Driver

```dart
void main() async {
  final sdkBytes = File('assets/sdk_summary.sum').readAsBytesSync();
  final pkgBytes = File('assets/packages.sum').readAsBytesSync();

  final driver = createDriverFromSummaries(
    sdkSummaryBytes: Uint8List.fromList(sdkBytes),
    packageSummaryBytes: Uint8List.fromList(pkgBytes),
  );

  // Analyze a file
  driver.addFile('/path/to/source.dart');
  final result = await driver.currentSession.getResolvedUnit('/path/to/source.dart');

  // Traverse element model, read annotations, etc.
  final unit = result.unit;
  for (final declaration in unit.declarations) {
    // ... inspect classes, fields, annotations
  }
}
```

## The PackageSummaryUriResolver (Required Workaround)

The standard `InSummaryUriResolver` only resolves URIs explicitly registered in `uriToSummaryPath`. But bundle resolution bytes reference **all** imported/exported URIs including internal `src/` files. Without a fallback resolver, deserialization fails.

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

## Key Gotchas

| Issue | Cause | Solution |
|-------|-------|----------|
| `package:` URIs not found | `addBundle()` registers file URIs, not `package:` URIs | Manually register via `uriToSummaryPath[uriStr] = 'packages'` loop |
| Null check error on deserialization | Internal `src/` files missing from bundle | List files **recursively** with `listSync(recursive: true)` |
| Unresolved `package:X/src/...` at runtime | Standard resolver doesn't know internal files | Use `PackageSummaryUriResolver` fallback for known packages |
| SDK path needed | Only for building the summary, not at runtime | Use `Platform.resolvedExecutable` parent to find SDK during build |

## For tom_specs_clitool

The outliner generator will:

1. Ship `sdk_summary.sum` and `packages.sum` alongside the CLI binary (or generate them as a setup step).
2. At runtime, load both summaries from disk and create an `AnalysisDriver`.
3. Use `getResolvedUnit()` to traverse the `tom_specs_model` element model — reading class declarations, field types, and annotations.
4. No Dart SDK installation required on the machine running the outliner.

Alternatively, if the SDK **is** available (typical dev machine), the tool can use the standard `AnalysisContextCollection` path — the summary approach is an optimization for constrained environments.

## Reference

- Implementation: `tom_forge/tom_dart_editor/lib/src/analyzer_with_packages.dart`
- Adapter: `tom_forge/tom_dart_editor/lib/src/summary_analysis_adapter.dart`
- Build tool: `tom_forge/tom_dart_editor_test/tool/build_packages_summary.dart`
- Diagnostics: `tom_forge/tom_dart_editor_test/tool/diagnose_packages_sum.dart`
- Usage guide: `tom_forge/tom_dart_editor/doc/dart_editor_usage_guide.md`
