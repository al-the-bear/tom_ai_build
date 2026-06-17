// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io' as io;

import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/file_system.dart'
    show Folder, ResourceProvider;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/file_source.dart' show FileSource;
import 'package:analyzer/source/source.dart' show Source;
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/analysis_options.dart';
import 'package:analyzer/src/dart/analysis/analysis_options_map.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/file_system/file_system.dart'
    show ResourceUriResolver;
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, SourceFactory, UriResolver;
import 'package:analyzer/src/util/sdk.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// TomSpecs analyzer-summary generator (OE-1 / B1).
///
/// Produces the two pre-generated `.sum` bundles `tom_dart_editor` loads at
/// runtime for SDK-free Dart analysis inside the editor's code-typed fields:
///
///   * `sdk_summary.sum`  — the Dart SDK core libraries (`buildSdkSummary`).
///   * `packages.sum`     — every package reachable from the target package's
///                          resolved `.dart_tool/package_config.json`.
///
/// This is the **one-time / per-developer** generation step of the B1 pipeline:
/// the resulting assets are committed (their canonical home is the tom_binaries
/// L2 layer — see the OE-1 questions note) and the per-OS build merely *copies*
/// them (`build.dart --summaries`). The analyzer is therefore never run per-OS.
///
/// Resolver order is load-bearing: `_PackageMapUriResolver` MUST precede
/// `ResourceUriResolver`, otherwise `pathToUri()` emits `file:///` URIs instead
/// of `package:` URIs and the bundle is non-portable. (Verified the hard way in
/// `tom_dart_editor_test`; see its `package_summary_uri_resolution.md`.)
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package',
        help: 'Target package directory whose resolved '
            '.dart_tool/package_config.json drives package coverage. '
            'Run `flutter pub get` / `dart pub get` there first.',
        defaultsTo: '.')
    ..addOption('out-dir',
        help: 'Directory to write sdk_summary.sum + packages.sum into.',
        defaultsTo: p.join('assets', 'summaries'))
    ..addFlag('sdk-only',
        help: 'Generate only sdk_summary.sum (skip the heavy package bundle).',
        negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    io.stderr.writeln('Error: ${e.message}\n');
    io.stdout.writeln(parser.usage);
    io.exit(2);
  }
  if (args.flag('help')) {
    io.stdout.writeln('Usage: dart run bin/summaries.dart [options]\n');
    io.stdout.writeln(parser.usage);
    io.exit(0);
  }

  final packageDir = p.normalize(p.absolute(args.option('package')!));
  final outDir = p.normalize(p.absolute(args.option('out-dir')!));
  final sdkOnly = args.flag('sdk-only');

  final resourceProvider = PhysicalResourceProvider.INSTANCE;
  final sdkPath = getSdkPath();
  print('Using SDK: $sdkPath');
  io.Directory(outDir).createSync(recursive: true);

  // ── sdk_summary.sum ───────────────────────────────────────────────────────
  print('\nBuilding SDK summary...');
  final sdkSummaryBytes = await buildSdkSummary(
    resourceProvider: resourceProvider,
    sdkPath: sdkPath,
  );
  final sdkOut = io.File(p.join(outDir, 'sdk_summary.sum'));
  sdkOut.writeAsBytesSync(sdkSummaryBytes);
  print('  → ${sdkOut.path} (${sdkSummaryBytes.length} bytes)');

  if (sdkOnly) {
    print('\n--sdk-only: skipping packages.sum.');
    return;
  }

  // ── packages.sum ──────────────────────────────────────────────────────────
  final packageConfigFile =
      io.File(p.join(packageDir, '.dart_tool', 'package_config.json'));
  if (!packageConfigFile.existsSync()) {
    io.stderr.writeln('ERROR: ${packageConfigFile.path} not found — run '
        '`flutter pub get` / `dart pub get` in $packageDir first.');
    io.exit(1);
  }
  final packageConfig =
      jsonDecode(packageConfigFile.readAsStringSync()) as Map<String, dynamic>;
  final packageList = packageConfig['packages'] as List<dynamic>;

  final packageRoots = <String, String>{};
  for (final pkg in packageList) {
    final pkgMap = pkg as Map<String, dynamic>;
    final name = pkgMap['name'] as String;
    // rootUri may be relative to the package_config.json location.
    final rootUri = pkgMap['rootUri'] as String;
    final resolved = Uri.parse(packageConfigFile.uri.toString())
        .resolve(rootUri.endsWith('/') ? rootUri : '$rootUri/');
    packageRoots[name] = resolved.toFilePath();
  }
  print('\nFound ${packageRoots.length} packages in $packageDir config');

  final packages = Packages({
    for (final entry in packageRoots.entries)
      entry.key: Package(
        name: entry.key,
        rootFolder: resourceProvider.getFolder(p.normalize(entry.value)),
        libFolder:
            resourceProvider.getFolder(p.join(entry.value, 'lib')),
        languageVersion: null,
      ),
  });

  // List ALL .dart files recursively under each lib/ (including src/): the
  // resolution bytes reference imported/exported internal URIs, so each must be
  // a library entry or the consumer's InSummaryUriResolver fails to deserialize.
  final libraryUris = <Uri>[];
  for (final entry in packageRoots.entries) {
    final libDir = io.Directory(p.join(entry.value, 'lib'));
    if (!libDir.existsSync()) continue;
    var count = 0;
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is io.File && entity.path.endsWith('.dart')) {
        final rel = p.relative(entity.path, from: libDir.path);
        libraryUris.add(Uri.parse('package:${entry.key}/'
            '${rel.replaceAll('\\', '/')}'));
        count++;
      }
    }
    if (count > 0) print('  ${entry.key}: $count dart files');
  }
  print('\nTotal libraries to summarize: ${libraryUris.length}');
  if (libraryUris.isEmpty) {
    io.stderr.writeln('ERROR: No libraries found to summarize.');
    io.exit(1);
  }

  final sdk = FolderBasedDartSdk(
      resourceProvider, resourceProvider.getFolder(sdkPath));
  final logger = PerformanceLog(StringBuffer());
  final scheduler = AnalysisDriverScheduler(logger);
  final byteStore = MemoryByteStore();
  final optionsMap = AnalysisOptionsMap.forSharedOptions(AnalysisOptionsImpl());

  // _PackageMapUriResolver MUST come before ResourceUriResolver (see header).
  final sourceFactory = SourceFactory([
    DartUriResolver(sdk),
    _PackageMapUriResolver(resourceProvider, {
      for (final entry in packageRoots.entries)
        entry.key: resourceProvider.getFolder(p.join(entry.value, 'lib')),
    }),
    ResourceUriResolver(resourceProvider),
  ]);

  final analysisDriver = AnalysisDriver(
    scheduler: scheduler,
    logger: logger,
    resourceProvider: resourceProvider,
    byteStore: byteStore,
    sourceFactory: sourceFactory,
    analysisOptionsMap: optionsMap,
    packages: packages,
    withFineDependencies: false,
  );
  scheduler.start();

  print('\nBuilding package bundle...');
  final sw = Stopwatch()..start();
  try {
    final bytes = await analysisDriver.buildPackageBundle(uriList: libraryUris);
    final pkgOut = io.File(p.join(outDir, 'packages.sum'));
    pkgOut.writeAsBytesSync(bytes);
    print('Done in ${sw.elapsedMilliseconds}ms');
    print('  → ${pkgOut.path} (${bytes.length} bytes)');
  } catch (e, s) {
    io.stderr.writeln('ERROR building package bundle: $e\n$s');
    io.exit(1);
  }
}

/// Maps `package:` URIs to file-system paths (and back) for the bundle build.
class _PackageMapUriResolver extends UriResolver {
  _PackageMapUriResolver(this._resourceProvider, this._packageMap);

  final ResourceProvider _resourceProvider;
  final Map<String, Folder> _packageMap;

  @override
  Uri? pathToUri(String path) {
    for (final entry in _packageMap.entries) {
      final pkgPath = entry.value.path;
      if (path.startsWith(pkgPath)) {
        final relative = path.substring(pkgPath.length);
        if (relative.startsWith('/') ||
            relative.startsWith(io.Platform.pathSeparator)) {
          return Uri.parse(
              'package:${entry.key}${relative.replaceAll('\\', '/')}');
        }
      }
    }
    return null;
  }

  @override
  Source? resolveAbsolute(Uri uri) {
    if (uri.scheme != 'package') return null;
    final parts = uri.pathSegments;
    if (parts.isEmpty) return null;
    final folder = _packageMap[parts[0]];
    if (folder == null) return null;
    final file =
        _resourceProvider.getFile('${folder.path}/${parts.skip(1).join('/')}');
    if (!file.exists) return null;
    return FileSource(file, uri);
  }
}
