/// `extract_answers`: a review round's answers as a step folder's
/// `answers.md` (SOM §11.9.7, `tom_specs_project_flow.md` PF-ITR-REV).
///
/// Every document given is read; files of the same root are fragments of one
/// document and are assembled, and documents of different roots each get
/// their own group, in the order their first file was given (Phase 3: the
/// twelve D01–D12 in dependency order). The extraction never writes to a
/// document.
library;

import 'dart:io';

import 'package:args/args.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

import 'validate_spec_cli.dart';

/// The command's options.
ArgParser extractAnswersParser() => ArgParser()
  ..addOption(
    'output',
    abbr: 'o',
    help: 'Write answers.md here (default: stdout).',
    valueHelp: 'file',
  )
  ..addOption(
    'path',
    help: 'Only the subtree at this document path.',
    valueHelp: 'path',
  )
  ..addOption(
    'title',
    help: 'The first heading of answers.md.',
    defaultsTo: 'Answers',
  )
  ..addFlag(
    'open',
    help: 'Also list the questions still open.',
    negatable: false,
  )
  ..addFlag('marks', help: 'Also list the inline marks.', negatable: false)
  ..addFlag(
    'counts',
    help: 'Print the counts (answered, open, comments, marks) to stdout.',
    negatable: false,
  )
  ..addFlag('help', abbr: 'h', help: 'Show this help.', negatable: false);

/// Runs `extract_answers` over [arguments]. Exit codes: `0` written, `1` a
/// document is unreadable or holds a malformed annotation, `2` bad usage.
Future<int> runExtractAnswers(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
  SpecModel? model,
}) async {
  final stdoutSink = out ?? stdout;
  final stderrSink = err ?? stderr;
  final parser = extractAnswersParser();
  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderrSink
      ..writeln('extract_answers: ${e.message}')
      ..writeln(parser.usage);
    return 2;
  }
  if (results.flag('help')) {
    stdoutSink
      ..writeln(
        'Usage: extract_answers <doc.md|doc.docspecs.yaml>... '
        '[-o answers.md] [--path <subtree>] [--open] [--marks] [--counts]',
      )
      ..writeln(parser.usage);
    return 0;
  }
  if (results.rest.isEmpty) {
    stderrSink.writeln('extract_answers: give at least one document');
    return 2;
  }
  final specModel = model ?? somSpecModel;

  // Read every file and group the fragments by root, in the order given.
  final groups = <String, Map<String, SpecDocument>>{};
  final labels = <String, String>{};
  for (final path in results.rest) {
    final file = File(path);
    if (!file.existsSync()) {
      stderrSink.writeln('extract_answers: document not found: $path');
      return 1;
    }
    final text = file.readAsStringSync();
    final isMd = path.toLowerCase().endsWith('.md');
    final SpecRoot root;
    try {
      root = resolveSpecDocumentRoot(specModel, null, text, isMarkdown: isMd);
    } on ArgumentError catch (e) {
      stderrSink.writeln('extract_answers: $path: ${e.message}');
      return 1;
    }
    final key = root.type;
    SpecDocument doc;
    if (isMd) {
      final imported = SpecDocument.fromMarkdown(text, specModel);
      doc = imported.document;
    } else {
      try {
        doc = SpecDocument.fromYaml(
          text,
          buildSomMetaTree(specModel, rootType: root.type),
        );
      } on SpecYamlFormatException catch (e) {
        stderrSink.writeln('extract_answers: $path: ${e.message}');
        return 1;
      }
    }
    (groups[key] ??= {})[path] = doc;
    labels.putIfAbsent(key, () => _label(path));
  }

  final extracts = <SpecAnswerExtract>[];
  var failed = false;
  for (final MapEntry(key: rootType, value: fragments) in groups.entries) {
    SpecDocument doc;
    if (fragments.length == 1) {
      doc = fragments.values.single;
    } else {
      final assembly = SpecDocument.assemble(fragments);
      final assembled = assembly.document;
      if (assembled == null) {
        for (final o in assembly.overlaps) {
          stderrSink.writeln('extract_answers: ${o.message}');
        }
        return 1;
      }
      doc = assembled;
    }
    // A malformed or misplaced annotation is the validator's finding; the
    // extraction would silently miss it, so it fails the run.
    for (final e in SpecReviewAnnotations(doc).validate()) {
      if (e.code == SpecValidationCode.annotationMalformed ||
          e.code == SpecValidationCode.annotationMisplaced ||
          e.code == SpecValidationCode.duplicateAnnotationId) {
        stderrSink.writeln(
          'extract_answers: ${labels[rootType]}: [${e.code.name}] '
          '${e.message}',
        );
        failed = true;
      }
    }
    extracts.add(
      extractAnswers(
        specModel,
        doc,
        label: labels[rootType]!,
        path: results.option('path'),
      ),
    );
  }

  final markdown = renderAnswers(
    extracts,
    options: SpecAnswerRenderOptions(
      includeOpen: results.flag('open'),
      includeMarks: results.flag('marks'),
      title: results.option('title')!,
    ),
  );
  final output = results.option('output');
  if (output == null) {
    stdoutSink.write(markdown);
  } else {
    File(output)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(markdown);
  }
  if (results.flag('counts')) {
    var total = const SpecAnswerCounts();
    for (final x in extracts) {
      total = total + x.counts;
    }
    stdoutSink.writeln(
      'answered ${total.answered}, open ${total.open}, '
      'comments ${total.comments}, marks ${total.marks}',
    );
  }
  return failed ? 1 : 0;
}

/// A document's label: its file name without the format suffix
/// (`tom_uam.sbp.docspecs.yaml` → `tom_uam.sbp`).
String _label(String path) {
  var name = path.split(Platform.pathSeparator).last.split('/').last;
  for (final suffix in ['.docspecs.yaml', '.yaml', '.md']) {
    if (name.endsWith(suffix)) {
      name = name.substring(0, name.length - suffix.length);
      break;
    }
  }
  return name;
}
