// ignore_for_file: avoid_print
import 'dart:io' as io;

import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/util/sdk.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_analyzer_shared/tom_analyzer_shared.dart'
    show GroupedPackageBundleBuilder, SummaryConfigException;

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
/// The grouped `packages.sum` build lives in `tom_analyzer_shared`'s
/// [GroupedPackageBundleBuilder] (the base-first home), so the load-bearing
/// resolver order and package-config merge are implemented exactly once. This
/// CLI is the thin TomSpecs front-end that also emits `sdk_summary.sum`.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addMultiOption('package',
        help: 'Target package directory whose resolved '
            '.dart_tool/package_config.json drives package coverage. '
            'Run `flutter pub get` / `dart pub get` there first. '
            'Repeatable: the bundle covers the UNION of every given '
            'package\'s dependency closure (e.g. the editor plus '
            'tom_flutter_ui for the CodeSpecs Flutter code fields).',
        defaultsTo: const ['.'])
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

  final packageDirs = args.multiOption('package');
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
  // Delegate the union build to the shared GroupedPackageBundleBuilder: it
  // merges every given package's resolved config, collects all lib/ libraries,
  // and runs the analyzer with the load-bearing package-resolver-before-
  // ResourceUriResolver order so emitted URIs are portable `package:` URIs.
  print('\nBuilding package bundle...');
  final sw = Stopwatch()..start();
  try {
    final bundle = await GroupedPackageBundleBuilder(
      resourceProvider: resourceProvider,
    ).buildFromDirs(packageDirs, sdkPath: sdkPath, onLog: print);
    final pkgOut = io.File(p.join(outDir, 'packages.sum'));
    pkgOut.writeAsBytesSync(bundle.bytes);
    print('Done in ${sw.elapsedMilliseconds}ms');
    print('  → ${pkgOut.path} (${bundle.bytes.length} bytes, '
        '${bundle.packageCount} packages, ${bundle.libraryCount} libraries)');
  } on SummaryConfigException catch (e) {
    io.stderr.writeln('ERROR: ${e.message}');
    io.exit(1);
  } catch (e, s) {
    io.stderr.writeln('ERROR building package bundle: $e\n$s');
    io.exit(1);
  }
}
