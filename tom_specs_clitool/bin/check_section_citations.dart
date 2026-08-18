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
/// The project READMEs that cite the doc set ([defaultCitedReadmes]) and the
/// doc comments of the CodeSpecs source packages ([defaultCitedSourceRoots])
/// are scanned by default, so the command and the gate test cover the same
/// files without the lists having to be repeated on a command line.
///
/// A bare `§N` means *this* document, so it resolves against the headings of
/// the file it is written in; a citation with a document name in front of it
/// resolves against that document. Exits 1 on any citation that resolves to no
/// heading. See `lib/src/section_citations.dart` for the run rule and for what
/// a section id is allowed to look like.
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
    ..addMultiOption(
      'source',
      help: 'Additional Dart file — or a directory of them — whose `///` '
          'comments are scanned. Repeatable. Defaults to the CodeSpecs source '
          'packages; pass --no-default-sources to scan markdown alone.',
    )
    ..addFlag('default-sources',
        defaultsTo: true,
        help: 'Also scan the doc comments of the CodeSpecs source packages.')
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
      extraSources: [
        if (results.flag('default-sources'))
          for (final root in defaultCitedSourceRoots)
            ...listDartSources(p.normalize(p.join(containerRoot, root))),
        // A `--source` may name a file or a directory. Expanding a directory
        // here rather than rejecting it keeps the option the same shape as
        // [defaultCitedSourceRoots], and stops a directory argument from
        // silently scanning nothing.
        for (final path in results.multiOption('source'))
          ...(() {
            final resolved = p.normalize(p.absolute(path));
            return Directory(resolved).existsSync()
                ? listDartSources(resolved)
                : [resolved];
          })(),
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
  stdout.writeln('  exhibit       ${report.exempted.length}');

  if (results.flag('verbose')) {
    for (final citation in report.citations) {
      stdout.writeln('  ${citation.describe(relativeTo: containerRoot)}');
    }
  }

  if (report.isClean) {
    stdout.writeln('OK — every § citation resolves to a heading, and every '
        'exhibit marker covers one that cannot.');
    exit(0);
  }

  stderr.writeln('');
  if (report.violations.isNotEmpty) {
    stderr.writeln('${report.violations.length} citation(s) resolve to no '
        'heading:');
    for (final violation in report.violations) {
      stderr.writeln('  ${violation.describe(relativeTo: containerRoot)}');
    }
  }
  if (report.staleExemptions.isNotEmpty) {
    stderr.writeln('${report.staleExemptions.length} exhibit marker id(s) '
        'excuse nothing:');
    for (final stale in report.staleExemptions) {
      stderr.writeln('  ${stale.describe(relativeTo: containerRoot)}');
    }
  }
  exit(1);
}
