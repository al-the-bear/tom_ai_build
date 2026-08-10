import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Resolves every `§` citation in the TomSpecs doc folder against `index.md`'s
/// citation convention.
///
///   dart run bin/check_section_citations.dart
///   dart run bin/check_section_citations.dart --verbose
///   dart run bin/check_section_citations.dart --no-default-readmes
///
/// The project READMEs that cite the doc set ([defaultCitedReadmes]) are scanned
/// by default, so the command and the gate test cover the same files without the
/// list having to be repeated on a command line.
///
/// A bare `§N` means *this* document, so it resolves against the headings of the
/// file it is written in; a citation with a document name in front of it
/// resolves against that document. Exits 1 on any citation that resolves to no
/// heading. See `lib/src/section_citations.dart` for the run rule and for what a
/// section id is allowed to look like.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'doc',
      help: 'Documentation folder to scan. Default: the sibling '
          'tom_specs_model/doc.',
    )
    ..addMultiOption(
      'extra',
      help: 'Additional file to scan, resolved against the same corpus. '
          'Repeatable. Defaults to the project READMEs that cite the doc set; '
          'pass --no-default-readmes to scan the doc folder alone.',
    )
    ..addFlag('default-readmes',
        defaultsTo: true,
        help: 'Also scan the project READMEs that cite the doc set.')
    ..addFlag('verbose', abbr: 'v',
        help: 'List every citation, not only the unresolved ones.',
        negatable: false)
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
    stdout.writeln('Usage: dart run bin/check_section_citations.dart [options]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));

  final docDir = p.normalize(p.absolute(results.option('doc') ??
      p.join(containerRoot, 'tom_ai', 'ai_build', 'tom_specs_model', 'doc')));

  final SectionCitationReport report;
  try {
    report = checkSectionCitations(
      docDir: docDir,
      extraFiles: [
        if (results.flag('default-readmes'))
          for (final readme in defaultCitedReadmes)
            p.normalize(p.join(containerRoot, readme)),
        for (final path in results.multiOption('extra'))
          p.normalize(p.absolute(path)),
      ],
    );
  } on ArgumentError catch (e) {
    stderr.writeln('check_section_citations error: ${e.message}');
    exit(1);
  }

  stdout.writeln('Scanned ${report.files.length} file(s) against '
      '${report.corpus.length} document(s) in '
      '${p.relative(docDir, from: containerRoot)}; '
      '${report.citations.length} citation(s).');
  stdout.writeln('  self          '
      '${report.countOf(SectionCitationVerdict.self)}');
  stdout.writeln('  cross-document '
      '${report.countOf(SectionCitationVerdict.crossDocument)}');
  stdout.writeln('  unverifiable  '
      '${report.countOf(SectionCitationVerdict.unverifiable)}');
  stdout.writeln('  dangling      '
      '${report.countOf(SectionCitationVerdict.dangling)}');
  stdout.writeln('  no such section '
      '${report.countOf(SectionCitationVerdict.wrongSection)}');

  if (results.flag('verbose')) {
    for (final citation in report.citations) {
      stdout.writeln('  ${citation.describe(relativeTo: containerRoot)}');
    }
  }

  if (report.isClean) {
    stdout.writeln('OK — every § citation resolves to a heading.');
    exit(0);
  }

  stderr.writeln('');
  stderr.writeln('${report.violations.length} citation(s) resolve to no '
      'heading:');
  for (final violation in report.violations) {
    stderr.writeln('  ${violation.describe(relativeTo: containerRoot)}');
  }
  exit(1);
}
