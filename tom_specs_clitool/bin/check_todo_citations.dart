import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Checks that every quest-todo id cited in the TomSpecs doc folder still
/// resolves to an **open** todo.
///
///   dart run bin/check_todo_citations.dart
///   dart run bin/check_todo_citations.dart --verbose
///
/// Exits 1 on any citation that resolves to closed work without an inline
/// exemption marker, and on any citation that resolves to nothing at all. See
/// `lib/src/todo_citations.dart` for the two markers and why the id shapes are
/// discovered rather than enumerated.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'doc',
      help: 'Documentation folder to scan. Default: the sibling '
          'tom_specs_model/doc.',
    )
    ..addMultiOption(
      'quest',
      help: 'Quest folder contributing todos (active + archived + deleted). '
          'Repeatable. Default: the tom_specs and tom_core quests, the two the '
          'TomSpecs documents cite.',
    )
    ..addOption(
      'vocabulary',
      help: 'Token list of non-todo words sharing the id shape. '
          'Default: tool/todo_citation_vocabulary.txt.',
    )
    ..addFlag('verbose', abbr: 'v',
        help: 'List resolved-open citations too.', negatable: false)
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
    stdout.writeln('Usage: dart run bin/check_todo_citations.dart [options]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final clitoolRoot = p.dirname(p.dirname(p.fromUri(Platform.script)));
  final containerRoot = p.normalize(p.join(clitoolRoot, '..', '..', '..'));

  final docDir = p.normalize(p.absolute(results.option('doc') ??
      p.join(containerRoot, 'tom_ai', 'ai_build', 'tom_specs_model', 'doc')));

  final questDirs = results.multiOption('quest').isNotEmpty
      ? [for (final q in results.multiOption('quest')) p.normalize(p.absolute(q))]
      : [
          for (final quest in defaultCitedQuests)
            p.join(containerRoot, '_ai', 'quests', quest),
        ];

  final vocabularyPath = p.normalize(p.absolute(results.option('vocabulary') ??
      p.join(clitoolRoot, 'tool', 'todo_citation_vocabulary.txt')));

  final corpus = TodoCorpus.load([
    for (final dir in questDirs) ...TodoCorpus.questTodoFiles(dir),
  ]);
  if (corpus.sourceFiles.isEmpty) {
    stderr.writeln('check_todo_citations error: no todo file found under '
        '${questDirs.join(', ')} — every citation would look unresolved.');
    exit(1);
  }

  final TodoCitationReport report;
  try {
    report = checkDocFolder(
      docDir: docDir,
      corpus: corpus,
      vocabulary: TodoCitationVocabulary.load(vocabularyPath),
    );
  } on ArgumentError catch (e) {
    stderr.writeln('check_todo_citations error: ${e.message}');
    exit(1);
  }

  stdout.writeln('Scanned ${report.documentCount} document(s) in '
      '${p.relative(docDir, from: containerRoot)} against '
      '${corpus.stemCount} todo id(s) from ${corpus.sourceFiles.length} file(s).');
  stdout.writeln('  open       ${report.countOf(CitationVerdict.open)}');
  stdout.writeln('  closed     ${report.countOf(CitationVerdict.closed)}');
  stdout.writeln('  unresolved ${report.countOf(CitationVerdict.unresolved) + report.countOf(CitationVerdict.unknownSeries)}');

  if (results.flag('verbose')) {
    for (final citation in report.citations) {
      stdout.writeln('  ${citation.describe(relativeTo: containerRoot)}');
    }
  }

  if (report.isClean) {
    stdout.writeln('OK — every cited todo id resolves to open work.');
    exit(0);
  }

  stderr.writeln('');
  stderr.writeln('${report.violations.length} citation(s) point at closed or '
      'non-existent todos:');
  for (final violation in report.violations) {
    stderr.writeln('  ${violation.describe(relativeTo: containerRoot)}');
  }
  exit(1);
}
