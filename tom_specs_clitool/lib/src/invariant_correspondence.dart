/// The gate over `tom_specs_model_rules.md` §10.2 — the seventeen mechanical
/// structural invariants — and everything that cites them.
///
/// §10.2 states three meta-rules: a structural rule lives in the validator, not
/// only in a test; *the validator is the contract, this document follows it*;
/// and an invariant is cited by its **id**, never by its list position. The
/// second and third are only true if something checks them. Left unchecked, the
/// first two drifted apart in both directions at once — the document carried a
/// detail-count budget the code never enforced, and the code ran three checks
/// the document never listed.
///
/// This library answers two questions, both by reading §10.2 as the register of
/// what exists:
///
/// 1. **Correspondence** — does every check in the validator name an invariant
///    §10.2 defines, and does every invariant §10.2 defines have a check? The
///    correspondence is made mechanical by *tagging*: every check carries a
///    comment naming the invariant it implements, and every numbered entry in
///    §10.2 opens with that invariant's id. Comparing the two sets catches a new
///    check that was never written up, and a written-up rule whose check was
///    removed or never existed.
/// 2. **Citation resolution** — does every `§10.2 invariant <ID>` citation
///    *anywhere in the corpus* name an id §10.2 actually defines? This is the
///    half the ordinals could not have: a citation used to be a list position,
///    so deleting one entry silently re-pointed eleven citations across six
///    files at the wrong rule, and nothing anywhere went red. An id survives a
///    reordering; a citation of an id that was never allocated, or that has been
///    retired, is now a test failure.
///
/// A citation written the **old** way — an ordinal where the id belongs — is
/// reported specifically rather than ignored, so the habit cannot quietly
/// return. (This comment states the retired form in words rather than showing
/// it, because the scan below reads this file too and would resolve the example
/// as a real citation.)
///
/// Both checks deliberately verify the *pointer*, not the claim: a tag can be
/// applied to the wrong check and a citation can describe the invariant it names
/// incorrectly, and no parser can tell. What they buy is that neither side can
/// grow an entry the other does not know about, and that no citation can point
/// at nothing — which is precisely the failure mode that produced the drift.
library;

import 'dart:io';

/// The shape of a §10.2 invariant id: uppercase, hyphen-separated words.
///
/// The four-character floor keeps a short all-caps word in ordinary prose (and
/// the `<ID>` metavariable in §10.2's own description of the tag format) from
/// being read as a citation.
final RegExp _idShape = RegExp(r'^[A-Z][A-Z0-9]*(-[A-Z0-9]+)*$');

bool _isInvariantId(String token) =>
    token.length >= 4 && _idShape.hasMatch(token);

/// Id namespaces that are **not** §10.2 invariants but share its id shape.
///
/// A *bare* head — one that does not name §10.2 — followed by one of these is
/// prose about that other thing, not a citation of an invariant. The corpus has
/// exactly one such collision: the CodeSpecs part codes (`codespecs_mapping.md`
/// §4.1), as in "the *stated everywhere* invariant CE-TX/CE-ER already follow".
/// A **qualified** citation of a part code is still reported, because there the
/// sentence does claim to be naming an invariant of this list. (Stated in words
/// rather than shown, since the scan below reads this file too.)
const List<String> _foreignIdNamespaces = ['CE-'];

/// A `§10.2 invariant <ID>` citation found in some source.
class InvariantCitation {
  InvariantCitation({
    required this.id,
    required this.source,
    required this.line,
    required this.text,
  });

  /// The invariant id the citation names, or the ordinal it wrote instead when
  /// [isOrdinal] is true.
  final String id;

  /// A human-readable name for the file the citation was found in.
  final String source;

  /// 1-based line number within that file.
  final int line;

  /// The full trimmed line, for the failure message.
  final String text;

  /// True when the citation names a **list position** rather than an id — the
  /// pre-`tscompc9` form, which §10.2's third meta-rule forbids.
  bool get isOrdinal => int.tryParse(id) != null;

  @override
  String toString() => '$source:$line: $text';
}

/// One numbered entry of §10.2's invariant list.
class InvariantEntry {
  InvariantEntry(this.id, this.number, this.title);

  /// The stable invariant id — the entry's first inline-code span, and the only
  /// thing anything is allowed to cite it by.
  final String id;

  /// The list ordinal, as written in the markdown. Presentational only: it is
  /// deliberately not citable, and is carried solely so a failure message can
  /// point a reader at the right place in the list.
  final int number;

  /// The entry's leading text after the id, trimmed to a single readable line.
  final String title;

  @override
  String toString() => '$number. `$id` — $title';
}

/// The result of comparing the two sides, plus the corpus citation scan.
class InvariantCorrespondence {
  InvariantCorrespondence({
    required this.entries,
    required this.tags,
    required this.citations,
    required this.undocumented,
    required this.unimplemented,
    required this.malformed,
  });

  /// The §10.2 entries, in document order.
  final List<InvariantEntry> entries;

  /// Every citation found in the validator source — the tags.
  final List<InvariantCitation> tags;

  /// Every citation found anywhere in the scanned corpus, tags included.
  final List<InvariantCitation> citations;

  /// Citations naming an id §10.2 does not define, or written as an ordinal —
  /// a pointer at nothing, or at whatever now happens to sit in that position.
  final List<InvariantCitation> undocumented;

  /// Ids listed in §10.2 that no validator tag cites — a documented rule with no
  /// check behind it, which §10.2's first meta-rule calls a gap, not a rule.
  final List<InvariantEntry> unimplemented;

  /// §10.2 entries that do not open with a well-formed id, and ids defined
  /// twice — either would make a citation ambiguous or unresolvable.
  final List<String> malformed;

  /// The ids §10.2 defines.
  Set<String> get definedIds => entries.map((e) => e.id).toSet();

  bool get isConsistent =>
      undocumented.isEmpty && unimplemented.isEmpty && malformed.isEmpty;

  /// A human-readable report of every disagreement; empty when consistent.
  List<String> get problems => [
    ...malformed,
    for (final e in unimplemented)
      '§10.2 invariant `${e.id}` ("${e.title}") is documented but no check '
          'in the validator cites it — either implement it or remove the '
          'entry (§10.2 meta-rule: a structural rule lives in the '
          'validator, not only in a test)',
    for (final c in undocumented)
      if (c.isOrdinal)
        '$c cites §10.2 invariant ${c.id} by list position — §10.2 is cited '
            'by id, never by ordinal, because a reordering silently '
            're-points an ordinal at a different rule'
      else
        '$c cites §10.2 invariant `${c.id}`, which §10.2 does not define — '
            'correct the citation, or add the invariant (ids are allocated '
            'once and never reused, so a retired id stays retired)',
  ];
}

/// Matches the head of a citation, with the section reference optional.
///
/// A citation is **qualified** when it names §10.2 (`§10.2 invariant …`) and
/// **bare** when it does not (`invariant `PART-ROUTED`'s exemption`, or the
/// cross-references inside §10.2 itself, where the workspace citation
/// convention lets a reference to one's own document drop the file name).
///
/// The distinction decides how an *ordinal* follower is read. Only a qualified
/// head may report one: `codespecs_derivation_contract.md` §2.4 has its own
/// numbered invariant list, cited as `§2.4 invariant 2`, and a bare
/// `invariant 2` from that document is a correct citation of a different list,
/// not a lapsed citation of this one. An uppercase id-shaped follower is
/// unambiguous either way — no other list in the corpus uses ids.
final RegExp _citationHead = RegExp(r'(§10\.2,?\s+)?[Ii]nvariants?\s+');

/// Consumes one joiner run plus one bare token from the tail of a citation.
///
/// The joiners are what separates several ids in one citation — `,`, `+`, the
/// word `and`, markdown ticks and emphasis, and any comment continuation
/// (`///`, `//`, `#`) a multi-line citation crosses. Anything else — a colon, a
/// dash, `)` , `'s`, a lowercase word — ends the run, which is what keeps the
/// scan from swallowing the sentence that follows the citation.
final RegExp _citationToken = RegExp(
  r'^(?:[\s`*,+/#]|and\b)*([A-Za-z0-9][A-Za-z0-9-]*)',
);

/// Extracts every `§10.2 invariant <ID>` citation from [source].
///
/// A single citation may name several ids (`§10.2 invariants KIND-EXCLUSIVE +
/// PART-ROUTED` on the routing pair), and may wrap across lines, so the run
/// after the head is consumed token by token rather than matched as one value.
///
/// A leading **ordinal** is captured as a citation too, flagged by
/// [InvariantCitation.isOrdinal]: it is a defect worth naming, not noise to
/// skip. A head followed by ordinary prose (`the one §10.2 rule enforced here`)
/// yields nothing — it is a reference to the section, not to an invariant.
List<InvariantCitation> parseInvariantCitations(
  String source, {
  String sourceName = 'source',
}) {
  final citations = <InvariantCitation>[];
  final lineStarts = _lineStarts(source);

  for (final head in _citationHead.allMatches(source)) {
    final qualified = head.group(1) != null;
    var offset = head.end;
    while (true) {
      final token = _citationToken.firstMatch(source.substring(offset));
      if (token == null) break;
      final value = token.group(1)!;
      final isOrdinal = int.tryParse(value) != null;
      if (isOrdinal && !qualified) break;
      if (!isOrdinal && !_isInvariantId(value)) break;
      if (!qualified && _foreignIdNamespaces.any(value.startsWith)) break;
      citations.add(
        InvariantCitation(
          id: value,
          source: sourceName,
          line: _lineOf(lineStarts, head.start),
          text: _lineAt(source, lineStarts, head.start),
        ),
      );
      offset += token.end;
      // An ordinal is a defect on its own; do not keep walking a run that the
      // scan cannot reliably delimit ("invariants 11 and 12" vs "11 and later").
      if (isOrdinal) break;
    }
  }
  return citations;
}

List<int> _lineStarts(String source) {
  final starts = <int>[0];
  for (var i = 0; i < source.length; i++) {
    if (source.codeUnitAt(i) == 0x0a) starts.add(i + 1);
  }
  return starts;
}

int _lineOf(List<int> starts, int offset) {
  var lo = 0, hi = starts.length - 1;
  while (lo < hi) {
    final mid = (lo + hi + 1) ~/ 2;
    if (starts[mid] <= offset) {
      lo = mid;
    } else {
      hi = mid - 1;
    }
  }
  return lo + 1;
}

String _lineAt(String source, List<int> starts, int offset) {
  final line = _lineOf(starts, offset) - 1;
  final start = starts[line];
  final end = line + 1 < starts.length ? starts[line + 1] - 1 : source.length;
  return source.substring(start, end).trim();
}

final RegExp _entryPattern = RegExp(r'^([0-9]+)\. (.+)$');
final RegExp _leadingCode = RegExp(r'^\**`([^`]+)`\**\s*(?:—|-)?\s*');

/// Extracts §10.2's numbered invariant list from the rules document [source].
///
/// The list is the numbered block that follows the heading `### 10.2 …`, and it
/// ends at the first non-indented line that is neither a numbered entry nor a
/// continuation of one — in practice the `**Deliberately not an invariant:**`
/// paragraph that closes it.
///
/// Each entry **defines its id by opening with it in an inline-code span**, the
/// same convention the `OE-` open-ends register uses. An entry that does not is
/// reported by [compareInvariants] rather than silently skipped: an invariant
/// with no id is one nothing can cite.
List<InvariantEntry> parseInvariantEntries(String source) {
  final lines = source.split('\n');
  final start = lines.indexWhere((l) => l.startsWith('### 10.2 '));
  if (start < 0) return const [];

  final entries = <InvariantEntry>[];
  var seenList = false;
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('### ') || line.startsWith('## ')) break;
    final match = _entryPattern.firstMatch(line);
    if (match != null) {
      seenList = true;
      final body = match.group(2)!;
      final id = _leadingCode.firstMatch(body);
      entries.add(
        InvariantEntry(
          id == null ? '' : id.group(1)!,
          int.parse(match.group(1)!),
          _titleOf(id == null ? body : body.substring(id.end)),
        ),
      );
      continue;
    }
    // A blank line or an indented continuation keeps the list open; any other
    // flush-left prose after the list has started closes it.
    if (!seenList) continue;
    if (line.trim().isEmpty) continue;
    if (line.startsWith('   ')) continue;
    break;
  }
  return entries;
}

/// The first sentence-ish fragment of an entry, stripped of markdown emphasis
/// and code ticks — enough to identify the entry in a failure message.
String _titleOf(String raw) {
  var text = raw.replaceAll('**', '').replaceAll('`', '').trim();
  final stop = text.indexOf(RegExp(r' — |\. '));
  if (stop > 0) text = text.substring(0, stop);
  return text.trim();
}

/// Compares §10.2's list against the validator's tags and the corpus citations.
///
/// [corpus] maps a display name to that file's text. The validator source is
/// added to it automatically, so a caller that only wants the correspondence can
/// leave it empty.
InvariantCorrespondence compareInvariants({
  required String rulesMarkdown,
  required String validatorSource,
  Map<String, String> corpus = const {},
}) {
  final entries = parseInvariantEntries(rulesMarkdown);
  final tags = parseInvariantCitations(
    validatorSource,
    sourceName: 'validator.dart',
  );

  final malformed = <String>[];
  final seen = <String, InvariantEntry>{};
  for (final e in entries) {
    if (e.id.isEmpty || !_isInvariantId(e.id)) {
      malformed.add(
        '§10.2 entry ${e.number} ("${e.title}") does not open with an '
        'invariant id in an inline-code span — every entry must define the id '
        'it is cited by, since the list position is not citable',
      );
      continue;
    }
    final prior = seen[e.id];
    if (prior != null) {
      malformed.add(
        '§10.2 defines the id `${e.id}` twice (entries ${prior.number} and '
        '${e.number}) — an id is allocated once, so a citation of it resolves '
        'to exactly one invariant',
      );
      continue;
    }
    seen[e.id] = e;
  }

  final citations = <InvariantCitation>[
    ...tags,
    for (final entry in corpus.entries)
      ...parseInvariantCitations(entry.value, sourceName: entry.key),
  ];

  final defined = seen.keys.toSet();
  final cited = tags.map((t) => t.id).toSet();

  return InvariantCorrespondence(
    entries: entries,
    tags: tags,
    citations: citations,
    undocumented: [
      for (final c in citations)
        if (c.isOrdinal || !defined.contains(c.id)) c,
    ],
    unimplemented: [
      for (final e in seen.values)
        if (!cited.contains(e.id)) e,
    ],
    malformed: malformed,
  );
}

/// The files scanned for citations, relative to the `tom_specs_clitool` root.
///
/// A closed set rather than a whole-workspace walk: these are the projects that
/// are *about* the model, and a citation elsewhere would be a copy of one of
/// these rather than an independent pointer. Directories are walked for the
/// extensions in [_scannedExtensions]; plain files are read as given.
const List<String> defaultCitingPaths = [
  'lib',
  'bin',
  'test',
  'pubspec.yaml',
  '../tom_specs_model/doc',
  '../tom_specs_model/lib',
  '../tom_specs_core/lib',
  '../tom_specs_core/README.md',
  '../tom_code_specs/lib',
];

const Set<String> _scannedExtensions = {'.dart', '.md', '.yaml'};

/// The one file held out of the corpus: this library's own test, whose fixtures
/// are synthetic §10.2 sections defining synthetic ids. Scanning it would
/// resolve those fixtures against the *real* §10.2 and fail on every one.
const String _corpusExemption = 'test/invariant_correspondence_test.dart';

/// Reads the corpus files under [clitoolRoot], keyed by a path for messages.
Map<String, String> readCitingCorpus(String clitoolRoot) {
  final corpus = <String, String>{};
  void add(File file) {
    final path = file.path
        .replaceFirst(RegExp('^${RegExp.escape(clitoolRoot)}/'), '')
        .replaceAll('/../', '/');
    if (path.endsWith(_corpusExemption)) return;
    corpus[path] = file.readAsStringSync();
  }

  for (final relative in defaultCitingPaths) {
    final path = '$clitoolRoot/$relative';
    final directory = Directory(path);
    if (directory.existsSync()) {
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!_scannedExtensions.any((e) => entity.path.endsWith(e))) continue;
        add(entity);
      }
      continue;
    }
    final file = File(path);
    if (file.existsSync()) add(file);
  }
  return corpus;
}

/// Reads the canonical sources and checks §10.2 against the validator and the
/// citing corpus.
///
/// [clitoolRoot] is the `tom_specs_clitool` package root; everything else is
/// resolved relative to it, so the check follows a package move rather than
/// hard-coding a workspace path.
InvariantCorrespondence checkInvariantCorrespondence(String clitoolRoot) {
  final validator = File('$clitoolRoot/lib/src/validator.dart');
  final rules = File(
    '$clitoolRoot/../tom_specs_model/doc/tom_specs_model_rules.md',
  );
  final corpus = readCitingCorpus(clitoolRoot)
    ..remove('lib/src/validator.dart'); // scanned separately, as the tags
  return compareInvariants(
    rulesMarkdown: rules.readAsStringSync(),
    validatorSource: validator.readAsStringSync(),
    corpus: corpus,
  );
}
