/// Checks that every quest-todo id cited in a documentation folder still
/// resolves to an **open** todo.
///
/// ## Why this exists
///
/// The TomSpecs documents cite quest-todo ids inline — "still to become
/// annotation attributes (`csrb4`)", "Raised by `csra12`", and the whole open-work
/// index of `codespecs_mapping.md`. Those citations decay silently: the todo
/// completes and is archived, and the document keeps pointing a reader at closed
/// work as if it were open.
///
/// Two sweeps found eleven instances of exactly that, both times by a human
/// reading the documents end to end. That detection scales with attention rather
/// than with the number of citations, which only ever grows.
///
/// ## What it does *not* do
///
/// This checks **citations, not claims**. It cannot notice that a sentence about
/// a todo has become false, only that the id it names is closed or does not
/// exist. Growing it into a claim checker would trade a cheap, reliable check for
/// an unreliable one; the mechanical two thirds is the whole value.
///
/// ## How a citation is recognised
///
/// The id shapes are **discovered, not enumerated**. An enumerated list only ever
/// knows the series someone remembered to add — the sweep that motivated this
/// checker found eight citations of a series (`csex*`) that no enumeration
/// contained. So [findTodoCitations] matches any inline-code token of the general
/// todo-id shape (see [todoIdShape]) and then asks the corpus about it, which
/// makes an id from *another quest's* corpus resolvable rather than invisible,
/// and an invented id visible rather than silently skipped.
///
/// The cost of a shape rule is that ordinary technical terms share the shape
/// (`vec0`, `arm64`, `python3`). Those are named in a **token vocabulary**
/// ([TodoCitationVocabulary]) — a list of words, not a list of files, so nothing
/// is blanket-exempted.
///
/// ## The two exemptions
///
/// A citation of a closed todo is a defect *except* in two cases, both marked
/// inline so the exemption travels with the line rather than with a path:
///
/// - `<!-- todo-cite: provenance -->` on the line — the cited todo is named as
///   the *raiser* or the landed *prerequisite* of an item ("Raised by
///   `csra12`"). The named todo is history; the item it produced is open.
///
///   The marker only applies when the same line **also cites an open todo**.
///   Without that condition it would be a blanket "ignore me" that any line
///   could wear, and a real staleness would hide behind it forever; with it, a
///   provenance note has to point somewhere live, which is the only thing that
///   makes naming history worth the reader's time.
/// - `<!-- todo-cite: history -->` on a line of its own — the whole document is a
///   changelog or history record, which is exempt from the current-state rule by
///   definition. No such condition applies: a history record has no open items.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The general shape of a quest-todo id stem: at least two lowercase letters
/// (the series) followed by one to three digits (the number).
///
/// Deliberately generic. Narrowing it to the known series would defeat the point
/// — see the library doc.
final RegExp todoIdShape = RegExp(r'^([a-z]{2,})([0-9]{1,3})$');

/// The full on-disk id form, `<stem>_<datecode>-<slug>`. Documents usually cite
/// the bare stem, but a full id is a citation too.
final RegExp _fullTodoId = RegExp(r'^([a-z]{2,}[0-9]{1,3})_[^\s`]+$');

/// Statuses that mean the todo is finished, wherever the file it lives in sits.
///
/// A completed todo that has not been archived yet is just as closed as one that
/// has; keying only on the file would let a document keep citing it until someone
/// ran an archive pass.
const _closedStatuses = {'completed', 'cancelled'};

/// The quests whose todo ids the TomSpecs documents cite.
///
/// Scoped rather than "every quest in the workspace" for one concrete reason:
/// stems are only unique **within** a quest. `qrc1` exists in both `tom_specs`
/// and `webwork`, so a corpus spanning every quest would let an unrelated
/// quest's open todo vouch for a citation of a closed one.
///
/// `tom_core` is in because the CodeSpecs mapping's open-work index tracks items
/// that wait on `tcca*` ids owned by that quest.
const defaultCitedQuests = ['tom_specs', 'tom_core'];

/// One todo as found in the corpus.
class TodoRecord {
  const TodoRecord({
    required this.id,
    required this.stem,
    required this.status,
    required this.sourcePath,
    required this.closed,
  });

  /// The full id, e.g. `qr4_agno-doc-todo-citation-checker`.
  final String id;

  /// The part before the first underscore — what documents cite.
  final String stem;

  /// The todo's `status:` field, or `''` when it has none.
  final String status;

  /// Path of the todo file this record came from.
  final String sourcePath;

  /// True when the todo is archived, deleted, completed or cancelled.
  final bool closed;
}

/// Every todo id reachable from a set of `*.todo.yaml` files.
class TodoCorpus {
  TodoCorpus._(this._byStem, this.seriesPrefixes, this.sourceFiles);

  final Map<String, List<TodoRecord>> _byStem;

  /// The letter part of every stem in the corpus — `csrb`, `qr`, `tcca`, …
  ///
  /// Used only to phrase a failure: an unresolved `csrb99` is a wrong number in a
  /// series that exists, while an unresolved `csex7` is a series that never did.
  final Set<String> seriesPrefixes;

  /// The files that were read, in the order given.
  final List<String> sourceFiles;

  /// Records for [stem], empty when the corpus does not know it.
  List<TodoRecord> operator [](String stem) => _byStem[stem] ?? const [];

  /// Total number of distinct stems.
  int get stemCount => _byStem.length;

  /// Reads every todo in [todoFiles].
  ///
  /// A file that does not exist is skipped rather than fatal: the corpus is
  /// naturally sparse (not every quest has an archived or a deleted file), and a
  /// missing optional file must not be reported as a missing todo.
  static TodoCorpus load(List<String> todoFiles) {
    final byStem = <String, List<TodoRecord>>{};
    final prefixes = <String>{};
    final read = <String>[];

    for (final path in todoFiles) {
      final file = File(path);
      if (!file.existsSync()) continue;
      read.add(path);

      final closedFile = _isClosedTodoFile(path);
      final doc = loadYaml(file.readAsStringSync());
      if (doc is! YamlMap) continue;
      final todos = doc['todos'];
      if (todos is! YamlList) continue;

      for (final entry in todos) {
        if (entry is! YamlMap) continue;
        final id = entry['id'];
        if (id is! String || id.isEmpty) continue;
        final stem = id.split('_').first;
        final status = entry['status'] is String ? entry['status'] as String : '';

        byStem.putIfAbsent(stem, () => []).add(TodoRecord(
              id: id,
              stem: stem,
              status: status,
              sourcePath: path,
              closed: closedFile || _closedStatuses.contains(status),
            ));
        final shape = todoIdShape.firstMatch(stem);
        if (shape != null) prefixes.add(shape.group(1)!);
      }
    }

    return TodoCorpus._(byStem, prefixes, read);
  }

  /// The three todo files of a quest folder: active, archived, deleted.
  static List<String> questTodoFiles(String questDir) {
    final quest = p.basename(questDir);
    return [
      p.join(questDir, 'todos.$quest.todo.yaml'),
      p.join(questDir, 'todos-archived.$quest.todo.yaml'),
      p.join(questDir, 'todos-deleted.$quest.todo.yaml'),
    ];
  }
}

/// What the checker concluded about one citation.
enum CitationVerdict {
  /// Resolves to a todo that is still open. Nothing to do.
  open,

  /// Resolves, but every todo carrying the id is archived, deleted, completed or
  /// cancelled — the document points a reader at finished work.
  closed,

  /// The series exists in the corpus but this number does not: a typo, or an id
  /// that was renamed.
  unresolved,

  /// Nothing in the corpus uses this series at all — an invented id, or a corpus
  /// that is missing the quest it belongs to.
  unknownSeries,
}

/// Why a [CitationVerdict.closed] citation is allowed to stand.
enum CitationExemption {
  /// `<!-- todo-cite: provenance -->` — the id names who raised an item, or the
  /// prerequisite that unblocked it, not what is open.
  ///
  /// Conditional: the line must also cite an open todo (see the library doc).
  provenance,

  /// `<!-- todo-cite: history -->` — the whole document is a history record.
  history,
}

/// True for a `todos-archived.*` / `todos-deleted.*` file — every todo in it is
/// closed regardless of the `status:` it carries.
bool _isClosedTodoFile(String path) {
  final name = p.basename(path);
  return name.startsWith('todos-archived.') || name.startsWith('todos-deleted.');
}

/// One todo-id citation found in one document line.
class TodoCitation {
  const TodoCitation({
    required this.token,
    required this.stem,
    required this.file,
    required this.line,
    required this.verdict,
    this.exemption,
  });

  /// The inline-code token exactly as written, e.g. `tcca14`.
  final String token;

  /// The stem the token resolves through — equal to [token] unless a full id was
  /// cited.
  final String stem;

  /// Path of the document the citation is in.
  final String file;

  /// 1-based line number.
  final int line;

  final CitationVerdict verdict;

  /// Set only when [verdict] is [CitationVerdict.closed] and the citation is
  /// marked.
  final CitationExemption? exemption;

  /// True when this citation must fail the check.
  bool get isViolation => switch (verdict) {
        CitationVerdict.open => false,
        CitationVerdict.closed => exemption == null,
        CitationVerdict.unresolved || CitationVerdict.unknownSeries => true,
      };

  /// A one-line, `file:line`-prefixed description suitable for a build log.
  String describe({String? relativeTo}) {
    final where = relativeTo == null ? file : p.relative(file, from: relativeTo);
    return '$where:$line: `$token` — ${_reason()}';
  }

  String _reason() => switch (verdict) {
        CitationVerdict.open => 'OPEN',
        CitationVerdict.closed => exemption == null
            ? 'CLOSED — the todo is finished; state the outcome instead of '
                'citing open work, or, if it names the raiser or a landed '
                'prerequisite, cite the open todo that owns the follow-up on '
                'the same line and mark it <!-- todo-cite: provenance -->'
            : 'CLOSED (${exemption!.name})',
        CitationVerdict.unresolved =>
          'UNRESOLVED — no todo with this number exists in the series',
        CitationVerdict.unknownSeries =>
          'UNRESOLVED — no todo file in the corpus uses this series; if it is '
              'not a todo id, add it to the vocabulary',
      };
}

/// Tokens that share the todo-id shape but are not todo ids.
///
/// A **token** list, not a path list: naming `vec0` exempts the word wherever it
/// appears, and exempts nothing else on the line. A file-scoped exemption would
/// hide the next real citation defect in that file.
class TodoCitationVocabulary {
  const TodoCitationVocabulary(this.tokens);

  const TodoCitationVocabulary.empty() : tokens = const {};

  final Set<String> tokens;

  bool contains(String token) => tokens.contains(token);

  /// Reads a newline-separated token list. `#` starts a comment; blank lines are
  /// ignored. Returns an empty vocabulary when the file is absent.
  static TodoCitationVocabulary load(String path) {
    final file = File(path);
    if (!file.existsSync()) return const TodoCitationVocabulary.empty();
    final tokens = <String>{};
    for (var line in file.readAsLinesSync()) {
      final hash = line.indexOf('#');
      if (hash >= 0) line = line.substring(0, hash);
      final token = line.trim();
      if (token.isNotEmpty) tokens.add(token);
    }
    return TodoCitationVocabulary(tokens);
  }
}

/// The `<!-- todo-cite: … -->` marker.
final RegExp _citeMarker = RegExp(r'<!--\s*todo-cite:\s*([a-z-]+)\s*-->');

/// Inline code spans. Fenced blocks are skipped before this runs.
final RegExp _inlineCode = RegExp(r'`([^`\n]{1,80})`');

final RegExp _fence = RegExp(r'^\s{0,3}(```|~~~)');

/// Finds and classifies every todo-id citation in [markdown].
///
/// [path] is recorded on each citation and is not read.
List<TodoCitation> classifyMarkdown(
  String markdown, {
  required String path,
  required TodoCorpus corpus,
  TodoCitationVocabulary vocabulary = const TodoCitationVocabulary.empty(),
}) {
  final lines = markdown.split('\n');

  // A document-level `<!-- todo-cite: history -->` exempts the whole file. Read
  // it before classifying so its position in the file does not matter.
  final documentExemption = lines.any((l) {
        final m = _citeMarker.firstMatch(l.trim());
        return m != null && m.group(1) == 'history' && l.trim() == m.group(0);
      })
      ? CitationExemption.history
      : null;

  final citations = <TodoCitation>[];
  var inFence = false;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (_fence.hasMatch(line)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    // Classify the whole line first: a provenance marker only takes effect when
    // the line also cites an open todo, which is not known until every token on
    // it has been resolved.
    final onLine = <(String token, String stem, CitationVerdict verdict)>[];
    for (final match in _inlineCode.allMatches(line)) {
      final token = match.group(1)!.trim();
      if (vocabulary.contains(token)) continue;
      final stem = _stemOf(token);
      if (stem == null) continue;
      onLine.add((token, stem, _verdictFor(stem, corpus)));
    }
    if (onLine.isEmpty) continue;

    final CitationExemption? exemption;
    if (documentExemption != null) {
      exemption = documentExemption;
    } else if (_citeMarker
            .allMatches(line)
            .any((m) => m.group(1) == 'provenance') &&
        onLine.any((c) => c.$3 == CitationVerdict.open)) {
      exemption = CitationExemption.provenance;
    } else {
      exemption = null;
    }

    for (final (token, stem, verdict) in onLine) {
      citations.add(TodoCitation(
        token: token,
        stem: stem,
        file: path,
        line: i + 1,
        verdict: verdict,
        exemption: verdict == CitationVerdict.closed ? exemption : null,
      ));
    }
  }

  return citations;
}

/// The stem [token] cites, or `null` when it is not shaped like a todo id.
String? _stemOf(String token) {
  if (todoIdShape.hasMatch(token)) return token;
  return _fullTodoId.firstMatch(token)?.group(1);
}

CitationVerdict _verdictFor(String stem, TodoCorpus corpus) {
  final records = corpus[stem];
  if (records.isNotEmpty) {
    return records.any((r) => !r.closed)
        ? CitationVerdict.open
        : CitationVerdict.closed;
  }
  final series = todoIdShape.firstMatch(stem)!.group(1)!;
  return corpus.seriesPrefixes.contains(series)
      ? CitationVerdict.unresolved
      : CitationVerdict.unknownSeries;
}

/// The result of checking a whole documentation folder.
class TodoCitationReport {
  const TodoCitationReport({
    required this.citations,
    required this.documentCount,
    required this.corpus,
  });

  /// Every citation found, in document then line order.
  final List<TodoCitation> citations;

  /// Markdown files scanned.
  final int documentCount;

  final TodoCorpus corpus;

  List<TodoCitation> get violations =>
      [for (final c in citations) if (c.isViolation) c];

  bool get isClean => violations.isEmpty;

  int countOf(CitationVerdict verdict) =>
      citations.where((c) => c.verdict == verdict).length;
}

/// Scans every `*.md` directly inside [docDir] and classifies its citations.
///
/// Only the folder itself: the TomSpecs doc set is flat by design, and generator
/// output lives in a sibling tree that must not be checked (a generated file is
/// regenerated, not edited).
TodoCitationReport checkDocFolder({
  required String docDir,
  required TodoCorpus corpus,
  TodoCitationVocabulary vocabulary = const TodoCitationVocabulary.empty(),
}) {
  final dir = Directory(docDir);
  if (!dir.existsSync()) {
    throw ArgumentError.value(docDir, 'docDir', 'documentation folder not found');
  }

  final files = dir
      .listSync()
      .whereType<File>()
      .where((f) => p.extension(f.path) == '.md')
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  final citations = <TodoCitation>[];
  for (final file in files) {
    citations.addAll(classifyMarkdown(
      file.readAsStringSync(),
      path: file.path,
      corpus: corpus,
      vocabulary: vocabulary,
    ));
  }

  return TodoCitationReport(
    citations: citations,
    documentCount: files.length,
    corpus: corpus,
  );
}
