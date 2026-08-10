import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Checks that every `OE-` id cited in the editor's source, in the TomSpecs doc
/// folder and in the quest's bookkeeping resolves to a row in the Open-Ends
/// Register (`tom_specs_editor_specification.md`).
///
///   dart run bin/check_oe_citations.dart
///   dart run bin/check_oe_citations.dart --verbose
///
/// Exits 1 on any citation with no register row, and on a register that defines
/// one id twice. See `lib/src/oe_citations.dart` for why the check runs in one
/// direction only.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'register',
      help: 'Document owning the Open-Ends Register. Default: '
          '$oeRegisterDocument.',
    )
    ..addMultiOption(
      'root',
      help: 'File or folder whose citations are checked. Repeatable. '
          'Default: the editor project, the TomSpecs doc folder and the quest '
          "files that cite OE ids.",
    )
    ..addFlag('verbose', abbr: 'v',
        help: 'List resolved citations too.', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage information.',
        negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }

  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/check_oe_citations.dart [options]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));

  final registerPath = p.normalize(p.absolute(results.option('register') ??
      p.join(containerRoot, p.joinAll(p.posix.split(oeRegisterDocument)))));

  final roots = results.multiOption('root').isNotEmpty
      ? [for (final r in results.multiOption('root')) p.normalize(p.absolute(r))]
      : [
          for (final root in defaultCitingRoots)
            p.join(containerRoot, p.joinAll(p.posix.split(root))),
        ];

  final OeRegister register;
  try {
    register = OeRegister.read(registerPath);
  } on FileSystemException catch (e) {
    stderr.writeln('check_oe_citations error: cannot read $registerPath — '
        '${e.message}');
    exit(1);
  } on StateError catch (e) {
    stderr.writeln('check_oe_citations error: ${e.message}');
    exit(1);
  }

  final OeCitationReport report;
  try {
    report = checkOeCitations(roots: roots, register: register);
  } on ArgumentError catch (e) {
    stderr.writeln('check_oe_citations error: ${e.message} '
        '(${e.invalidValue})');
    exit(1);
  }

  stdout.writeln('Scanned ${report.fileCount} file(s) against '
      '${register.length} registered id(s) from '
      '${p.relative(registerPath, from: containerRoot)}.');
  stdout.writeln('  citations  ${report.citations.length} '
      '(${report.citedIds.length} distinct id(s))');
  stdout.writeln('  undefined  ${report.violations.length}');

  if (results.flag('verbose')) {
    for (final citation in report.citations) {
      stdout.writeln('  ${citation.describe(relativeTo: containerRoot)}');
    }
  }

  if (report.isClean) {
    stdout.writeln('OK — every cited OE id resolves to a register row.');
    exit(0);
  }

  stderr.writeln('');
  if (register.duplicates.isNotEmpty) {
    stderr.writeln('The register defines ${register.duplicates.length} id(s) '
        'twice; an id names one thing only: '
        '${register.duplicates.join(', ')}');
  }
  if (report.violations.isNotEmpty) {
    stderr.writeln('${report.violations.length} citation(s) resolve to no '
        'register row:');
    for (final violation in report.violations) {
      stderr.writeln('  ${violation.describe(relativeTo: containerRoot)}');
    }
  }
  exit(1);
}
