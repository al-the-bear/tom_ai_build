/// The gate that keeps `tom_specs_model_rules.md` §10.2's numbered list and
/// `validator.dart`'s checks the same set **in both directions**.
///
/// §10.2 states two meta-rules: a structural rule lives in the validator, not
/// only in a test; and *the validator is the contract, this document follows
/// it*. The second is only true if something checks it. Left unchecked, the two
/// drifted apart in both directions at once — the document carried a
/// detail-count budget the code never enforced, and the code ran three checks
/// the document never listed.
///
/// The correspondence is made mechanical by *tagging*: every check in the
/// validator carries a comment naming the invariant it implements, and every
/// numbered entry in §10.2 is one invariant. Comparing the two sets catches a
/// new check that was never written up, and a written-up rule whose check was
/// removed or never existed.
///
/// This deliberately checks the *tags*, not the behaviour: a tag can be applied
/// to the wrong check, and no parser can tell. What it does buy is that neither
/// side can grow an entry the other does not know about — which is precisely
/// the failure mode that produced the drift.
library;

import 'dart:io';

/// A `// … §10.2 invariant N …` tag found in the validator source.
class InvariantTag {
  InvariantTag(this.invariant, this.line, this.text);

  /// The §10.2 ordinal the tag cites.
  final int invariant;

  /// 1-based line number in the scanned source.
  final int line;

  /// The full trimmed source line, for the failure message.
  final String text;

  @override
  String toString() => 'line $line: $text';
}

/// One numbered entry of §10.2's invariant list.
class InvariantEntry {
  InvariantEntry(this.number, this.title);

  /// The list ordinal, as written in the markdown.
  final int number;

  /// The entry's leading text, trimmed to a single readable line.
  final String title;

  @override
  String toString() => '$number. $title';
}

/// The result of comparing the two sides.
class InvariantCorrespondence {
  InvariantCorrespondence({
    required this.entries,
    required this.tags,
    required this.undocumented,
    required this.unimplemented,
    required this.misnumbered,
  });

  /// The §10.2 entries, in document order.
  final List<InvariantEntry> entries;

  /// Every tag found in the validator source.
  final List<InvariantTag> tags;

  /// Ordinals cited by a tag but absent from §10.2 — a check whose write-up is
  /// missing, or a citation of an ordinal that has since been renumbered.
  final List<InvariantTag> undocumented;

  /// Ordinals listed in §10.2 that no tag cites — a documented rule with no
  /// check behind it, which §10.2's first meta-rule calls a gap, not a rule.
  final List<InvariantEntry> unimplemented;

  /// §10.2's numbering is not `1..n` — a hand-edited list that skipped or
  /// repeated an ordinal, which would make every citation of it ambiguous.
  final List<String> misnumbered;

  bool get isConsistent =>
      undocumented.isEmpty && unimplemented.isEmpty && misnumbered.isEmpty;

  /// A human-readable report of every disagreement; empty when consistent.
  List<String> get problems => [
        ...misnumbered,
        for (final e in unimplemented)
          '§10.2 invariant ${e.number} ("${e.title}") is documented but no '
              'check in the validator cites it — either implement it or remove '
              'the entry (§10.2 meta-rule: a structural rule lives in the '
              'validator, not only in a test)',
        for (final t in undocumented)
          'validator $t cites §10.2 invariant ${t.invariant}, which the '
              'numbered list does not contain — add the entry, or correct the '
              'citation if the list was renumbered',
      ];
}

final RegExp _tagPattern = RegExp(r'§10\.2\s+invariants?\s+([0-9,\s+and]+)');
final RegExp _entryPattern = RegExp(r'^([0-9]+)\. (.+)$');

/// Extracts every `§10.2 invariant N` citation from Dart [source].
///
/// A single comment may cite several (`§10.2 invariants 11 + 12` on the routing
/// pair), so the trailing number run is split rather than parsed as one value.
List<InvariantTag> parseInvariantTags(String source) {
  final tags = <InvariantTag>[];
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    for (final match in _tagPattern.allMatches(lines[i])) {
      for (final token in match.group(1)!.split(RegExp(r'[^0-9]+'))) {
        if (token.isEmpty) continue;
        tags.add(InvariantTag(int.parse(token), i + 1, lines[i].trim()));
      }
    }
  }
  return tags;
}

/// Extracts §10.2's numbered invariant list from the rules document [source].
///
/// The list is the numbered block that follows the heading `### 10.2 …`, and it
/// ends at the first non-indented line that is neither a numbered entry nor a
/// continuation of one — in practice the `**Deliberately not an invariant:**`
/// paragraph that closes it.
List<InvariantEntry> parseInvariantEntries(String source) {
  final lines = source.split('\n');
  var start = lines.indexWhere((l) => l.startsWith('### 10.2 '));
  if (start < 0) return const [];

  final entries = <InvariantEntry>[];
  var seenList = false;
  for (var i = start + 1; i < lines.length; i++) {
    final line = lines[i];
    if (line.startsWith('### ') || line.startsWith('## ')) break;
    final match = _entryPattern.firstMatch(line);
    if (match != null) {
      seenList = true;
      entries.add(InvariantEntry(
        int.parse(match.group(1)!),
        _titleOf(match.group(2)!),
      ));
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

/// Compares §10.2's list against the validator's tags.
InvariantCorrespondence compareInvariants({
  required String rulesMarkdown,
  required String validatorSource,
}) {
  final entries = parseInvariantEntries(rulesMarkdown);
  final tags = parseInvariantTags(validatorSource);

  final misnumbered = <String>[];
  for (var i = 0; i < entries.length; i++) {
    if (entries[i].number != i + 1) {
      misnumbered.add(
        '§10.2 entry ${i + 1} of the list is numbered ${entries[i].number} '
        '("${entries[i].title}") — the list must run 1..n so a citation of an '
        'ordinal is unambiguous',
      );
    }
  }

  final documented = entries.map((e) => e.number).toSet();
  final cited = tags.map((t) => t.invariant).toSet();

  return InvariantCorrespondence(
    entries: entries,
    tags: tags,
    undocumented: [
      for (final t in tags)
        if (!documented.contains(t.invariant)) t,
    ],
    unimplemented: [
      for (final e in entries)
        if (!cited.contains(e.number)) e,
    ],
    misnumbered: misnumbered,
  );
}

/// Reads the two canonical sources and compares them.
///
/// [clitoolRoot] is the `tom_specs_clitool` package root; the rules document is
/// resolved relative to it, so the check follows a package move rather than
/// hard-coding a workspace path.
InvariantCorrespondence checkInvariantCorrespondence(String clitoolRoot) {
  final validator = File('$clitoolRoot/lib/src/validator.dart');
  final rules = File(
    '$clitoolRoot/../tom_specs_model/doc/tom_specs_model_rules.md',
  );
  return compareInvariants(
    rulesMarkdown: rules.readAsStringSync(),
    validatorSource: validator.readAsStringSync(),
  );
}
