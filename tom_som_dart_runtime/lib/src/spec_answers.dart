/// The answers of a review round, extracted for a step folder (SOM §11.9.7).
///
/// A step of the TomSpecs process starts by collecting what the reviewer
/// wrote into the document — answers to the agent's questions, comments, and
/// optionally the questions still open and the inline marks — into the
/// step folder's `answers.md`. The annotations stay in the document; this
/// reads them through [SpecReviewAnnotations.list] and never writes.
library;

import 'spec_document.dart';
import 'spec_document_markdown.dart';
import 'spec_model.dart';
import 'spec_review_annotations.dart';

/// What an extracted entry is.
enum SpecAnswerKind {
  /// A question with an answer.
  answered,

  /// A question without an answer.
  open,

  /// A comment block.
  comment,

  /// An inline mark.
  mark,
}

/// One extracted entry.
class SpecAnswerEntry {
  /// What it is.
  final SpecAnswerKind kind;

  /// The question or comment id (`BQ-81`, `C-12`), or `M-<n>` for a mark;
  /// null for a comment without an id.
  final String? id;

  /// The section-id chain of the rendition heading the entry sits under
  /// (`SBP > INSC > SYSUM`).
  final String section;

  /// The 1-based line in the document's Markdown rendition.
  final int line;

  /// The document path of the value holding the entry.
  final String path;

  /// The form field holding it, or null for content.
  final String? field;

  /// A question's topic.
  final String? topic;

  /// Whether a question is part of a combined form block (its topic is then
  /// the field it asks about).
  final bool combined;

  /// A question's text, a comment's text, or a mark's markup.
  final String text;

  /// A question's answer (empty when open).
  final String answer;

  /// A comment's author.
  final String? author;

  /// A mark's kind.
  final SpecMarkKind? markKind;

  /// A mark's text when rejected / accepted.
  final String? oldText;

  /// See [oldText].
  final String? newText;

  /// A mark's comment.
  final String? comment;

  /// Creates an entry.
  const SpecAnswerEntry({
    required this.kind,
    this.id,
    required this.section,
    required this.line,
    required this.path,
    this.field,
    this.topic,
    this.combined = false,
    this.text = '',
    this.answer = '',
    this.author,
    this.markKind,
    this.oldText,
    this.newText,
    this.comment,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'id': id,
    'section': section,
    'line': line,
    'path': path,
    'field': field,
    'topic': topic,
    'combined': combined,
    'text': text,
    'answer': answer,
    'author': author,
    'markKind': markKind?.name,
    'oldText': oldText,
    'newText': newText,
    'comment': comment,
  };
}

/// The counts a step's closing item reports.
class SpecAnswerCounts {
  /// Questions with an answer.
  final int answered;

  /// Questions without one.
  final int open;

  /// Comment blocks.
  final int comments;

  /// Inline marks.
  final int marks;

  /// Creates counts.
  const SpecAnswerCounts({
    this.answered = 0,
    this.open = 0,
    this.comments = 0,
    this.marks = 0,
  });

  /// The sum of two counts.
  SpecAnswerCounts operator +(SpecAnswerCounts o) => SpecAnswerCounts(
    answered: answered + o.answered,
    open: open + o.open,
    comments: comments + o.comments,
    marks: marks + o.marks,
  );

  /// The canonical JSON form.
  Map<String, int> toJson() => {
    'answered': answered,
    'open': open,
    'comments': comments,
    'marks': marks,
  };
}

/// The extraction of one document.
class SpecAnswerExtract {
  /// The document's label in `answers.md` (its file name, e.g.
  /// `tom_uam.sbp`).
  final String label;

  /// The document root's section id, written in front of a comment id
  /// (`SBP C-12`).
  final String qualifier;

  /// Every entry, in document order.
  final List<SpecAnswerEntry> entries;

  /// Creates an extract.
  const SpecAnswerExtract({
    required this.label,
    required this.qualifier,
    required this.entries,
  });

  /// The counts over [entries].
  SpecAnswerCounts get counts {
    var a = 0, o = 0, c = 0, m = 0;
    for (final e in entries) {
      switch (e.kind) {
        case SpecAnswerKind.answered:
          a++;
        case SpecAnswerKind.open:
          o++;
        case SpecAnswerKind.comment:
          c++;
        case SpecAnswerKind.mark:
          m++;
      }
    }
    return SpecAnswerCounts(answered: a, open: o, comments: c, marks: m);
  }

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'label': label,
    'qualifier': qualifier,
    'entries': [for (final e in entries) e.toJson()],
    'counts': counts.toJson(),
  };
}

final _heading = RegExp(r'^(#+) <!--\[([^\]]+)\]-->');

/// Extracts the annotations of [doc] (or of the subtree at [path]) with their
/// place in the document's Markdown rendition under [model], in rendition
/// order (by line).
SpecAnswerExtract extractAnswers(
  SpecModel model,
  SpecDocument doc, {
  required String label,
  String? path,
}) {
  final root = model.roots.firstWhere(
    (r) => doc.hasValuesUnder(r.sectionId ?? r.type),
    orElse: () => model.roots.first,
  );
  final qualifier = root.sectionId ?? root.type;
  final rendition = SpecDocumentMarkdown(model, doc).exportRootWithMap(root);
  final lines = rendition.markdown.split('\n');

  // The section-id chain of every heading line (1-based).
  final chains = <int, String>{};
  final stack = <(int, String)>[];
  for (var i = 0; i < lines.length; i++) {
    final m = _heading.firstMatch(lines[i]);
    if (m == null) continue;
    final level = m.group(1)!.length;
    while (stack.isNotEmpty && stack.last.$1 >= level) {
      stack.removeLast();
    }
    stack.add((level, m.group(2)!));
    chains[i + 1] = stack.map((e) => e.$2).join(' > ');
  }

  // The heading line of a value: the heading whose path is the longest
  // prefix of the value's path (on equal length, the first).
  int headingLine(String valuePath) {
    var best = 0, bestLen = -1;
    final keys = rendition.headingPaths.keys.toList()..sort();
    for (final l in keys) {
      final hp = rendition.headingPaths[l]!;
      if ((valuePath == hp || valuePath.startsWith('$hp/')) &&
          hp.length > bestLen) {
        best = l;
        bestLen = hp.length;
      }
    }
    return best;
  }

  String chainAt(int line) {
    for (var l = line; l >= 1; l--) {
      final c = chains[l];
      if (c != null) return c;
    }
    return qualifier;
  }

  final claimed = <int>{};
  // The rendition line of an annotation: the first unclaimed line after the
  // value's heading whose trimmed text is the annotation's first line.
  // A form field's first line renders behind its label (`Owner: …`, the
  // field name with its first letter upper-cased).
  int locate(String valuePath, String? field, int valueLine, String firstLine) {
    final h = headingLine(valuePath);
    final want = firstLine.trim();
    final labelled = field == null || valueLine != 0
        ? null
        : '${field[0].toUpperCase()}${field.substring(1)}: $want'.trim();
    for (var i = h; i < lines.length; i++) {
      final l = i + 1;
      if (l <= h || claimed.contains(l)) continue;
      final t = lines[i].trim();
      if (t == want || (labelled != null && t == labelled)) {
        claimed.add(l);
        return l;
      }
    }
    return h == 0 ? 1 : h;
  }

  bool inScope(String p) => path == null || p == path || p.startsWith('$path/');

  final api = SpecReviewAnnotations(doc);
  // `list()` and `listMarks()` give the marks in the same order.
  final marks = api.listMarks();
  var markIndex = 0;
  final entries = <SpecAnswerEntry>[];
  for (final a in api.list()) {
    // Every mark consumes its listing entry, in scope or not, so the ids of
    // the marks in a subtree stay their document-wide `M-<n>`.
    final m = a.kind == SpecReviewAnnotationKind.mark
        ? marks[markIndex++]
        : null;
    if (!inScope(a.path)) continue;
    final value =
        (a.field == null
            ? doc.content(a.path)
            : doc.formField(a.path, a.field!)) ??
        '';
    final first = value.split('\n')[a.line];
    switch (a.kind) {
      case SpecReviewAnnotationKind.question:
        final line = locate(a.path, a.field, a.line, first);
        entries.add(
          SpecAnswerEntry(
            kind: a.open ? SpecAnswerKind.open : SpecAnswerKind.answered,
            id: a.id,
            section: chainAt(line),
            line: line,
            path: a.path,
            field: a.field,
            topic: a.topic,
            combined: a.combined,
            text: a.text,
            answer: a.answer,
          ),
        );
      case SpecReviewAnnotationKind.comment:
        final line = locate(a.path, a.field, a.line, first);
        entries.add(
          SpecAnswerEntry(
            kind: SpecAnswerKind.comment,
            id: a.id,
            section: chainAt(line),
            line: line,
            path: a.path,
            field: a.field,
            text: a.text,
            author: a.author,
          ),
        );
      case SpecReviewAnnotationKind.mark:
        final line = locate(a.path, a.field, a.line, first);
        // A line holding several marks is found once; later marks on it
        // share the line.
        claimed.remove(line);
        entries.add(
          SpecAnswerEntry(
            kind: SpecAnswerKind.mark,
            id: m!.id,
            section: chainAt(line),
            line: line,
            path: a.path,
            field: a.field,
            text: m.markup,
            markKind: a.markKind,
            oldText: m.oldText,
            newText: m.newText,
            comment: a.comment,
          ),
        );
    }
  }
  // Rendition order: by line; entries on one line keep their order.
  final ordered = [for (var i = 0; i < entries.length; i++) (i, entries[i])]
    ..sort((a, b) {
      final c = a.$2.line.compareTo(b.$2.line);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  return SpecAnswerExtract(
    label: label,
    qualifier: qualifier,
    entries: [for (final e in ordered) e.$2],
  );
}

/// What `answers.md` includes besides the answered questions and comments.
class SpecAnswerRenderOptions {
  /// List the questions still open.
  final bool includeOpen;

  /// List the inline marks.
  final bool includeMarks;

  /// The file's title.
  final String title;

  /// Creates options.
  const SpecAnswerRenderOptions({
    this.includeOpen = false,
    this.includeMarks = false,
    this.title = 'Answers',
  });
}

/// A labelled value: `- **Label:** first line`, further lines indented two
/// spaces.
String _item(String label, String value) {
  final ls = value.split('\n');
  final b = StringBuffer('- **$label:**');
  if (ls.first.isNotEmpty) b.write(' ${ls.first}');
  for (final l in ls.skip(1)) {
    b.write(l.isEmpty ? '\n' : '\n  $l');
  }
  return b.toString();
}

/// Renders [extracts] as a step folder's `answers.md`: deterministic, grouped
/// per document in the order given, entries in document order.
String renderAnswers(
  List<SpecAnswerExtract> extracts, {
  SpecAnswerRenderOptions options = const SpecAnswerRenderOptions(),
}) {
  var total = const SpecAnswerCounts();
  for (final x in extracts) {
    total = total + x.counts;
  }
  final out = <String>['# ${options.title}', '', _countLine(total, options)];
  for (final x in extracts) {
    out
      ..add('')
      ..add('## ${x.label}')
      ..add('')
      ..add(_countLine(x.counts, options));
    void section(String heading, SpecAnswerKind kind) {
      final es = [
        for (final e in x.entries)
          if (e.kind == kind) e,
      ];
      out
        ..add('')
        ..add('### $heading');
      if (es.isEmpty) {
        out
          ..add('')
          ..add('None.');
        return;
      }
      for (final e in es) {
        out
          ..add('')
          ..add('#### ${_entryHeading(x, e)}')
          ..add('')
          ..add(_item('Section', '`${e.section}`'))
          ..add(_item('Line', '${e.line}'));
        if (e.field != null) out.add(_item('Field', '`${e.field}`'));
        switch (kind) {
          case SpecAnswerKind.answered:
          case SpecAnswerKind.open:
            out.add(_item('Question', e.text));
            if (kind == SpecAnswerKind.answered) {
              out.add(_item('Answer', e.answer));
            }
          case SpecAnswerKind.comment:
            if (e.author != null) out.add(_item('Author', e.author!));
            out.add(_item('Comment', e.text));
          case SpecAnswerKind.mark:
            out
              ..add(_item('Markup', '`${e.text}`'))
              ..add(_item('Old', e.oldText ?? ''))
              ..add(_item('New', e.newText ?? ''));
            if (e.comment != null) out.add(_item('Note', e.comment!));
        }
      }
    }

    section('Answered questions', SpecAnswerKind.answered);
    section('Comments', SpecAnswerKind.comment);
    if (options.includeOpen) section('Open questions', SpecAnswerKind.open);
    if (options.includeMarks) section('Inline marks', SpecAnswerKind.mark);
  }
  return '${out.join('\n')}\n';
}

String _countLine(SpecAnswerCounts c, SpecAnswerRenderOptions o) {
  final parts = [
    '${c.answered} answered question${c.answered == 1 ? '' : 's'}',
    '${c.open} open question${c.open == 1 ? '' : 's'}',
    '${c.comments} comment${c.comments == 1 ? '' : 's'}',
    if (o.includeMarks) '${c.marks} inline mark${c.marks == 1 ? '' : 's'}',
  ];
  return '${parts.join(', ')}.';
}

String _entryHeading(SpecAnswerExtract x, SpecAnswerEntry e) =>
    switch (e.kind) {
      SpecAnswerKind.answered || SpecAnswerKind.open => '${e.id} — ${e.topic}',
      SpecAnswerKind.comment =>
        e.id == null
            ? 'Comment without id (line ${e.line})'
            : '${x.qualifier} ${e.id}',
      SpecAnswerKind.mark => '${e.id} — ${e.markKind!.name}',
    };
