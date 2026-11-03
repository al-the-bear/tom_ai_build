/// Reports every signature an API summary quotes that disagrees with the code,
/// and exits non-zero when there is one.
///
/// The gate over `tool/api_signature_set.yaml`. `test/api_signatures_test.dart`
/// runs the same check in the default `dart test` run; this is the command a
/// person runs to see the list, or — with `--package` — to survey a package
/// before it joins the set. A package joins only once it reads zero.
///
/// Exit codes: `0` clean, `1` a signature disagrees, `2` the check could not
/// run (a barrel that does not resolve, a run that compared nothing).
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'manifest',
      help: 'Path to the set. Default: <clitool>/$apiSignatureSetPath.',
    )
    ..addOption(
      'container-root',
      help:
          'Workspace container root. Default: three levels above this '
          'package.',
    )
    ..addMultiOption(
      'package',
      help:
          'Check this package (container-relative) instead of the set; '
          'its summaries are read from doc/api.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage.');

  final results = parser.parse(arguments);
  if (results['help'] as bool) {
    stdout.writeln('Usage: dart run bin/check_api_signatures.dart [options]');
    stdout.writeln(parser.usage);
    return;
  }

  final clitoolRoot = _clitoolRoot();
  final containerRoot =
      (results['container-root'] as String?) ??
      p.normalize(p.join(clitoolRoot, '..', '..', '..'));
  final adHoc = results['package'] as List<String>;
  final List<({String package, String docs})> entries;
  if (adHoc.isNotEmpty) {
    entries = [
      for (final package in adHoc) (package: package, docs: 'doc/api'),
    ];
  } else {
    final manifest = File(
      (results['manifest'] as String?) ??
          p.join(clitoolRoot, apiSignatureSetPath),
    );
    if (!manifest.existsSync()) {
      stderr.writeln('api-signature set not found: ${manifest.path}');
      exit(2);
    }
    entries = ApiSignatureSet.parse(manifest.readAsStringSync()).entries;
  }

  var faults = 0;
  var members = 0;
  for (final entry in entries) {
    final dir = p.join(containerRoot, entry.package);
    final ApiSignatureReport report;
    try {
      report = await checkApiSignatures(
        packageDir: dir,
        docDir: p.join(dir, entry.docs),
      );
    } on Object catch (e) {
      stderr.writeln('${entry.package}: $e');
      exit(2);
    }
    for (final fault in report.faults) {
      stdout.writeln('${entry.package}/$fault');
    }
    stdout.writeln(
      '${entry.package}: ${report.fences} fence(s), ${report.programs} usage '
      'sample(s), ${report.members} member(s) compared, '
      '${report.faults.length} disagree',
    );
    faults += report.faults.length;
    members += report.members;
  }
  // A run that compared nothing would report a clean tree.
  if (members == 0) {
    stderr.writeln('no quoted signature was compared');
    exit(2);
  }
  if (faults > 0) exitCode = 1;
}

String _clitoolRoot() {
  var dir = p.dirname(p.fromUri(Platform.script));
  while (dir != p.dirname(dir)) {
    if (File(p.join(dir, 'pubspec.yaml')).existsSync()) return dir;
    dir = p.dirname(dir);
  }
  return Directory.current.path;
}
