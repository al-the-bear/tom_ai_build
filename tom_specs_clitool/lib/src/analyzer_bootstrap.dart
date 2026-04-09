import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:analyzer/src/summary2/package_bundle_format.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import 'sdk_summary/sdk_summary_chunks.dart';

/// Creates an [AnalysisDriver] using the embedded SDK summary.
///
/// [packagePath] is the root of the target Dart package. Its
/// `.dart_tool/package_config.json` is parsed to resolve `package:` URIs.
///
/// No installed Dart SDK is required at runtime — the SDK element model
/// is loaded from base64-encoded chunks compiled into the binary.
AnalysisDriver createAnalysisDriver(String packagePath) {
  final sdkSummaryBytes = _loadEmbeddedSdkSummary();
  final resourceProvider = PhysicalResourceProvider.INSTANCE;

  final sdkBundle = PackageBundleReader(sdkSummaryBytes);
  final sdk = SummaryBasedDartSdk.forBundle(sdkBundle);

  final dataStore = SummaryDataStore();
  dataStore.addBundle('sdk', sdkBundle);

  // Parse package_config.json to resolve package: URIs
  final packageConfig = _parsePackageConfig(packagePath, resourceProvider);

  final sourceFactory = SourceFactory([
    DartUriResolver(sdk),
    PackageMapUriResolver(resourceProvider, packageConfig.packageMap),
    ResourceUriResolver(resourceProvider),
  ]);

  final logger = PerformanceLog(null);
  final scheduler = AnalysisDriverScheduler(logger);
  scheduler.events.drain<void>().ignore();

  final analysisOptions = AnalysisOptionsImpl();
  final optionsMap =
      AnalysisOptionsMap.forSharedOptions(analysisOptions);

  final driver = AnalysisDriver(
    scheduler: scheduler,
    logger: logger,
    resourceProvider: resourceProvider,
    byteStore: MemoryByteStore(),
    sourceFactory: sourceFactory,
    analysisOptionsMap: optionsMap,
    externalSummaries: dataStore,
    packages: packageConfig.packages,
    shouldReportInconsistentAnalysisException: false,
    withFineDependencies: false,
  );

  scheduler.start();
  return driver;
}

Uint8List _loadEmbeddedSdkSummary() {
  final base64String = sdkSummaryChunks.join();
  return base64Decode(base64String);
}

({Map<String, List<Folder>> packageMap, Packages packages})
    _parsePackageConfig(
  String packagePath,
  PhysicalResourceProvider resourceProvider,
) {
  final configFile = io.File(
    p.join(packagePath, '.dart_tool', 'package_config.json'),
  );

  if (!configFile.existsSync()) {
    return (packageMap: {}, packages: Packages({}));
  }

  final json = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
  final configUri = configFile.parent.uri;
  final packageEntries = json['packages'] as List<dynamic>? ?? [];

  final packageMap = <String, List<Folder>>{};
  final packagesMap = <String, Package>{};

  for (final entry in packageEntries) {
    final map = entry as Map<String, dynamic>;
    final name = map['name'] as String;
    final rootUriStr = map['rootUri'] as String;

    // Resolve relative rootUri against the .dart_tool/ directory
    final rootUri = configUri.resolve(rootUriStr);
    final rootPath = rootUri.toFilePath();
    final libPath = p.join(rootPath, 'lib');

    if (!io.Directory(libPath).existsSync()) continue;

    final rootFolder = resourceProvider.getFolder(rootPath);
    final libFolder = resourceProvider.getFolder(libPath);

    packageMap[name] = [libFolder];

    // Parse language version if present
    final langVersionStr = map['languageVersion'] as String?;
    Version? langVersion;
    if (langVersionStr != null) {
      final parts = langVersionStr.split('.');
      if (parts.length >= 2) {
        langVersion = Version(
          int.tryParse(parts[0]) ?? 3,
          int.tryParse(parts[1]) ?? 0,
          0,
        );
      }
    }

    packagesMap[name] = Package(
      name: name,
      rootFolder: rootFolder,
      libFolder: libFolder,
      languageVersion: langVersion,
    );
  }

  return (packageMap: packageMap, packages: Packages(packagesMap));
}
