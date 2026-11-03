/// Builds each governed package's API documentation and reports every warning
/// `dart doc` prints and every doc-comment link into a package the writer did
/// not choose; exits non-zero when there is one.
///
/// The gate over `tool/dartdoc_build_set.yaml`. `test/dartdoc_build_test.dart`
/// runs the same check in the default `dart test` run; this is the command a
/// person runs to read the warnings, or — with `--package` — to survey a
/// package before it joins the set. A package joins only once it is silent.
///
/// The rendered HTML is read and deleted; nothing is kept.
///
/// Exit codes: `0` silent, `1` a warning, error or stray link, `2` the check
/// could not run (a failed build with no verdict, pages with no doc prose).
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'manifest',
      help: 'Path to the set. Default: <clitool>/$dartdocBuildSetPath.',
    )
    ..addOption(
      'container-root',
      help:
          'Workspace container root. Default: three levels above this '
          'package.',
    )
    ..addMultiOption(
      'package',
      help: 'Build this package (container-relative) instead of the set.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  final results = parser.parse(arguments);
  if (results['help'] as bool) {
    stdout.writeln('Usage: dart run bin/check_dartdoc_build.dart [options]');
    stdout.writeln(parser.usage);
    return;
  }

  final clitoolRoot = _clitoolRoot();
  final containerRoot =
      (results['container-root'] as String?) ??
      p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  var packages = results['package'] as List<String>;
  if (packages.isEmpty) {
    final manifest = File(
      (results['manifest'] as String?) ??
          p.join(clitoolRoot, dartdocBuildSetPath),
    );
    if (!manifest.existsSync()) {
      stderr.writeln('dartdoc build set not found: ${manifest.path}');
      exit(2);
    }
    packages = DartdocBuildSet.parse(manifest.readAsStringSync()).packages;
  }

  final scratch = Directory.systemTemp.createTempSync('dartdoc_build_');
  try {
    // Each build is single-threaded analysis, so a few side by side.
    final reports = <DartdocBuildReport>[];
    for (var i = 0; i < packages.length; i += 4) {
      reports.addAll(
        await Future.wait([
          for (final package in packages.skip(i).take(4))
            buildDartdoc(
              packageDir: p.join(containerRoot, package),
              scratchDir: scratch.path,
            ),
        ]),
      );
    }
    var faults = 0;
    for (final (i, report) in reports.indexed) {
      final name = packages[i];
      if (report.failedSilently) {
        stderr.writeln('=== dart doc failed for $name ===\n${report.log}');
        exit(2);
      }
      if (report.proseBlocks == 0) {
        stderr.writeln(
          '$name: no doc-comment prose in the generated pages, '
          'so no link was judged; not measured',
        );
        exit(2);
      }
      for (final w in report.warnings) {
        stdout.writeln('$name: warning: $w');
      }
      for (final link in report.strayLinks) {
        stdout.writeln('$name: link outside the dependencies: $link');
      }
      stdout.writeln(
        '$name: ${report.warningCount} warning(s), ${report.errorCount} '
        'error(s), ${report.strayLinks.length} stray link(s)',
      );
      faults += report.faults;
    }
    if (faults > 0) exitCode = 1;
  } finally {
    scratch.deleteSync(recursive: true);
  }
}

String _clitoolRoot() {
  var dir = p.dirname(p.fromUri(Platform.script));
  while (dir != p.dirname(dir)) {
    if (File(p.join(dir, 'pubspec.yaml')).existsSync()) return dir;
    dir = p.dirname(dir);
  }
  return Directory.current.path;
}
