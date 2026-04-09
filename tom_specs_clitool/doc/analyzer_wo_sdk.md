# Using the Dart Analyzer Without an Installed SDK

This guide explains how to use `package:analyzer` for Dart type resolution, annotation reading, and element model traversal in `tom_specs_clitool` **without requiring a Dart SDK on the target machine**. The approach uses pre-serialized summary bundles (`.sum` files) and is based on the `tom_dart_editor` implementation.

## Dependencies

```yaml
dependencies:
  analyzer: ^10.0.0
```

The analyzer's internal summary APIs are used. These are not public API, so pin the version carefully.

---

## Summary Files

The analyzer loads element models from binary `.sum` files instead of reading SDK/package source files.

| File | Contents | Typical size |
|------|----------|-------------|
| `sdk_summary.sum` | Dart SDK core libraries (`dart:core`, `dart:async`, etc.) | ~3 MB |
| `packages.sum` | All pub packages the target code depends on (optional — may not be needed if the model has no external dependencies beyond the SDK) | ~31 MB |

Reference copies exist in `tom_forge/tom_dart_editor_test/assets/`.

For `tom_specs_clitool`, only the SDK summary is strictly required. The model classes (`tom_specs_model`) are analyzed from source files directly — the `.sum` file provides type resolution for SDK types (`String`, `List`, `int`, etc.) and annotations.

## Bundling the SDK Summary Into the Application

The `sdk_summary.sum` file (~3 MB) is embedded directly in the compiled application so no external files are needed at runtime. The binary is split into chunks and stored as base64-encoded string constants across multiple Dart source files.

### Build-Time Splitting

A build tool (`tool/split_sdk_summary.dart`) performs:

1. Read `sdk_summary.sum` as bytes.
2. Base64-encode the full byte array.
3. Split the base64 string into chunks of ~60 KB each (~50 files for a 3 MB summary).
4. Generate one Dart file per chunk in `lib/src/sdk_summary/`:

```dart
// lib/src/sdk_summary/chunk_001.dart
const sdkSummaryChunk001 =
    'UEsDBBQAAAAIAIRzY1kA... (base64 data) ...AAAA==';
```

5. Generate a barrel file `lib/src/sdk_summary/sdk_summary_chunks.dart`:

```dart
import 'chunk_001.dart';
import 'chunk_002.dart';
// ... all chunks

const sdkSummaryChunks = [
  sdkSummaryChunk001,
  sdkSummaryChunk002,
  // ...
];
```

### Runtime Reassembly

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'sdk_summary/sdk_summary_chunks.dart';

Uint8List loadSdkSummary() {
  final base64String = sdkSummaryChunks.join();
  return base64Decode(base64String);
}
```

### Regeneration

Whenever the Dart SDK version changes, regenerate the chunks:

```bash
dart run tool/build_sdk_summary.dart assets/sdk_summary.sum
dart run tool/split_sdk_summary.dart assets/sdk_summary.sum lib/src/sdk_summary/
```

The chunk files are checked into version control.

---

## Step 1: Build the SDK Summary

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

Run once on a dev machine with the SDK:

```bash
dart run tool/build_sdk_summary.dart assets/sdk_summary.sum
```

## Step 2: Split the Summary Into Dart Chunks

Create `tool/split_sdk_summary.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args.first : 'assets/sdk_summary.sum';
  final outputDir = args.length > 1 ? args[1] : 'lib/src/sdk_summary';

  final bytes = File(inputPath).readAsBytesSync();
  final base64String = base64Encode(bytes);

  const chunkSize = 60000; // ~60 KB per chunk
  final chunks = <String>[];
  for (var i = 0; i < base64String.length; i += chunkSize) {
    final end = (i + chunkSize).clamp(0, base64String.length);
    chunks.add(base64String.substring(i, end));
  }

  final dir = Directory(outputDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);

  final imports = StringBuffer();
  final list = StringBuffer();

  for (var i = 0; i < chunks.length; i++) {
    final index = (i + 1).toString().padLeft(3, '0');
    final fileName = 'chunk_$index.dart';
    final constName = 'sdkSummaryChunk$index';

    File(p.join(outputDir, fileName)).writeAsStringSync(
      "const $constName =\n    '${chunks[i]}';\n",
    );

    imports.writeln("import '$fileName';");
    list.writeln('  $constName,');
  }

  File(p.join(outputDir, 'sdk_summary_chunks.dart')).writeAsStringSync(
    '${imports}\n'
    'const sdkSummaryChunks = [\n'
    '$list];\n',
  );

  print('Split ${bytes.length} bytes into ${chunks.length} chunks in $outputDir');
}
```

## Step 3: Load Summary and Create the Analysis Driver

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/source/source.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';

import 'sdk_summary/sdk_summary_chunks.dart';

AnalysisDriver createDriver() {
  // 1. Reassemble SDK summary from embedded chunks
  final base64String = sdkSummaryChunks.join();
  final sdkSummaryBytes = base64Decode(base64String) as Uint8List;

  final resourceProvider = PhysicalResourceProvider.INSTANCE;

  // 2. Load SDK from summary
  final sdkBundle = PackageBundleReader(sdkSummaryBytes);
  final sdk = SummaryBasedDartSdk.forBundle(sdkBundle);

  // 3. Create data store and register SDK bundle
  final dataStore = SummaryDataStore();
  dataStore.addBundle('sdk', sdkBundle);

  // 4. Set up source resolution
  final sourceFactory = SourceFactory([
    DartUriResolver(sdk),
    ResourceUriResolver(resourceProvider),
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
  final driver = createDriver();

  // Add source files to analyze
  driver.addFile('/path/to/tom_specs_model/lib/src/some_model.dart');
  final result = await driver.currentSession.getResolvedUnit(
    '/path/to/tom_specs_model/lib/src/some_model.dart',
  );

  // Traverse element model, read annotations, etc.
  final unit = result.unit;
  for (final declaration in unit.declarations) {
    // ... inspect classes, fields, annotations
  }
}
```

## Optional: Adding a Packages Summary

If the model depends on external packages beyond the SDK, add a `packages.sum` bundle. This can be bundled the same way (split into base64 chunks), or loaded from disk.

```dart
AnalysisDriver createDriverWithPackages({
  required Uint8List packageSummaryBytes,
}) {
  // ... same SDK setup as above ...

  final packageBundle = PackageBundleReader(packageSummaryBytes);
  dataStore.addBundle('packages', packageBundle);

  // Register package: URIs (workaround)
  for (final library in packageBundle.libraries) {
    final uriStr = library.uriStr;
    if (!dataStore.uriToSummaryPath.containsKey(uriStr)) {
      dataStore.uriToSummaryPath[uriStr] = 'packages';
    }
  }

  // Add PackageSummaryUriResolver to source factory (see below)
  // ...
}
```

### The PackageSummaryUriResolver (Required Workaround)

Only needed when loading a `packages.sum`. The standard `InSummaryUriResolver` only resolves URIs explicitly registered in `uriToSummaryPath`. Without a fallback resolver, deserialization of internal `src/` files fails.

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
| Base64 overhead | ~33% size increase over raw binary | Acceptable for ~3 MB SDK summary; consider gzip if needed |

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
