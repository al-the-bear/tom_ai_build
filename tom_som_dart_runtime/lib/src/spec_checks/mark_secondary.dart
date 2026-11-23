// Marks the secondary prose of a `*.tomspecs.yaml` in place: provenance notes,
// trace citations, the editorial convention preamble and section references
// are written in the reading notation (the DocSpecs specification's *Reading
// Notation*, RN-1 … RN-4) inside the values that hold them. Like
// `acceptMarksInPlace` it rewrites only the block scalars it changes and keeps
// every other byte of the file.
//
// The patterns are fixed rules of the tool:
//
// - **P1** (provenance): a paragraph whose whole text is
//   `_Extrapolated — see <target>._` becomes `(<~ <target>)`;
// - **T1** (trace): a parenthesised run of ids whose families are all in
//   [secondaryIdFamilies], standing after text in its value, becomes
//   `(-> ids)`; runs separated by single spaces become one citation;
// - **E1** (editorial): a paragraph of the document root's own content that
//   opens with `**The provenance notes.**` becomes a `::: {.editorial}` div;
// - **R1** (references): ``(`<doc>.md`, `A > … > B`)`` becomes
//   `[B](<doc>.tomspecs.md#B)`, and a code-span section path `` `A > … > B` ``
//   whose ids are sections of the same document becomes `[B](#B)`.
//
// What a pattern recognises but must not change is reported as a candidate
// (an author decides), what it never touches as a skip by reason. Text inside
// the notation, in code, in a question or comment block, and every headline
// are never marked, so a second run marks nothing new.
//
// `reflow` joins the soft-wrapped lines of one-paragraph values (a
// whitespace-only change).
//
// Before the text is handed back, every changed value is verified
// ([verifyMarkSecondary]): undoing the run's edits gives back the stored value
// byte for byte, each edit is the one its pattern makes, the value has no
// notation finding it did not have, and the rewritten YAML decodes to the
// document with exactly the changed values changed.
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

import 'sbp_yaml_locator.dart';
import 'sbp_yaml_writer.dart';

/// The id families a parenthesised run may hold to be converted into a trace
/// citation (the families TomSpecs documents use).
const List<String> secondaryIdFamilies = [
  'FR',
  'C',
  'BQ',
  'RC',
  'D',
  'N',
  'SR',
  'UC',
  'TR',
  'TD',
  'DQ',
  'G',
  'CL',
  'OR',
  'X',
  'S',
  'PR',
  'AC',
];

/// What the marker marks.
enum SecondaryKind {
  /// P1: provenance notes become `(<~ target)`.
  provenance,

  /// T1: parenthesised id runs become `(-> ids)`.
  trace,

  /// E1: the root's provenance-notes preamble becomes an editorial div.
  editorial,

  /// R1: section references become links.
  references,
}

/// The kind named [name] (`provenance`, `trace`, `editorial`, `references`),
/// or null.
SecondaryKind? secondaryKindNamed(String name) {
  for (final k in SecondaryKind.values) {
    if (k.name == name) return k;
  }
  return null;
}

/// One text edit of a value: `[start, end)` of the old text replaced by
/// [text].
class SecondaryEdit {
  /// The edit.
  const SecondaryEdit(this.start, this.end, this.text);

  /// The first offset replaced, in the value before the run's edits.
  final int start;

  /// The offset after the last one replaced.
  final int end;

  /// What is written instead.
  final String text;
}

/// One change the marker makes: one pattern applied once.
class SecondaryChange {
  /// The change.
  const SecondaryChange({
    required this.kind,
    required this.value,
    required this.line,
    required this.original,
    required this.edits,
    required this.before,
    required this.after,
  });

  /// The pattern's kind.
  final SecondaryKind kind;

  /// The value changed: its section-id path and field (`… / description`).
  final String value;

  /// The 1-based line of the YAML file the change starts on.
  final int line;

  /// The text the change replaces (for an editorial div: the paragraph).
  final String original;

  /// The edits, in the value before the run's edits.
  final List<SecondaryEdit> edits;

  /// An excerpt of the line before the change.
  final String before;

  /// The same excerpt after it.
  final String after;
}

/// A place a pattern recognises and does not change: an author decides.
class SecondaryCandidate {
  /// The candidate.
  const SecondaryCandidate({
    required this.kind,
    required this.reason,
    required this.value,
    required this.line,
    required this.text,
  });

  /// The pattern's kind.
  final SecondaryKind kind;

  /// Why it is not changed (`afterPreposition`, `worded`, `codeSpanInRun`,
  /// `moreText`, `boldLed`, `noSuchSection`).
  final String reason;

  /// The value: its section-id path and field.
  final String value;

  /// The 1-based line of the YAML file.
  final int line;

  /// The text recognised.
  final String text;
}

/// A value whose soft-wrapped lines were joined.
class SecondaryReflow {
  /// The reflow.
  const SecondaryReflow(this.value, this.line, this.lines);

  /// The value: its section-id path and field.
  final String value;

  /// The 1-based line of the YAML file of its first line.
  final int line;

  /// How many lines it had.
  final int lines;
}

/// The outcome of [markSecondaryInPlace].
class MarkSecondaryResult {
  /// The outcome.
  const MarkSecondaryResult({
    required this.text,
    required this.changes,
    required this.candidates,
    required this.skips,
    required this.unknownFamilies,
    required this.reflows,
    required this.changedValues,
    required this.rewrites,
    required this.failures,
  });

  /// The rewritten YAML (the input when nothing changes or a check failed).
  final String text;

  /// Every change, in file order.
  final List<SecondaryChange> changes;

  /// Every candidate, in file order.
  final List<SecondaryCandidate> candidates;

  /// Per kind, the places left alone by reason.
  final Map<SecondaryKind, Map<String, int>> skips;

  /// The families of id-shaped parenthesised runs not in
  /// [secondaryIdFamilies], with how often each was seen.
  final Map<String, int> unknownFamilies;

  /// The values reflowed.
  final List<SecondaryReflow> reflows;

  /// How many values change.
  final int changedValues;

  /// Each changed value: its old and new text and its changes.
  final List<SecondaryValueRewrite> rewrites;

  /// Why the rewrite may not be written; empty when it was verified.
  final List<String> failures;

  /// Whether the rewrite passed every check.
  bool get verified => failures.isEmpty;

  /// The changes of [kind].
  List<SecondaryChange> changesOf(SecondaryKind kind) => [
    for (final c in changes)
      if (c.kind == kind) c,
  ];

  /// The candidates of [kind].
  List<SecondaryCandidate> candidatesOf(SecondaryKind kind) => [
    for (final c in candidates)
      if (c.kind == kind) c,
  ];
}

/// An `--under` section path that names no section.
class SecondarySectionNotFound implements Exception {
  /// The path not found.
  const SecondarySectionNotFound(this.under);

  /// The `/`-separated section ids.
  final String under;

  @override
  String toString() => 'no value lies under $under';
}

/// One value's rewrite: the old text, the new one and the changes between.
class SecondaryValueRewrite {
  /// The rewrite of the value at [location].
  const SecondaryValueRewrite({
    required this.location,
    required this.field,
    required this.label,
    required this.oldValue,
    required this.reflowed,
    required this.newValue,
    required this.changes,
  });

  /// Where the value sits in the YAML.
  final ValueLocation location;

  /// The form field the value is, or null for content (a section's or a
  /// form's own text, a scalar leaf, a scalar list item).
  final String? field;

  /// The value's section-id path and field.
  final String label;

  /// The stored value.
  final String oldValue;

  /// The value after the reflow (the stored one without it).
  final String reflowed;

  /// The value after the run.
  final String newValue;

  /// The changes from [reflowed] to [newValue].
  final List<SecondaryChange> changes;
}

/// Marks the secondary prose of [yamlText] (decoded against [tree]) in place;
/// see the file comment.
///
/// [kinds] are the patterns applied (none: only the reflow); [reflow] joins
/// soft-wrapped one-paragraph values; [under] limits the run to the values
/// under that section-id path (`/`-separated ids, each nested in the one
/// before).
///
/// Throws [SecondarySectionNotFound] when [under] names no section.
MarkSecondaryResult markSecondaryInPlace(
  String yamlText,
  SomMetaTree tree, {
  Set<SecondaryKind> kinds = const {
    SecondaryKind.provenance,
    SecondaryKind.trace,
    SecondaryKind.editorial,
    SecondaryKind.references,
  },
  bool reflow = false,
  String? under,
}) {
  final located = locateAllValues(yamlText, tree);
  final rootContent = specPathJoin(tree.root.segment, 'content');
  final values = <(ValueLocation, String, bool, String?)>[];
  for (final l in located.content.values) {
    final label = l.idPath.endsWith(' > content')
        ? l.idPath.substring(0, l.idPath.length - ' > content'.length)
        : l.idPath;
    values.add((l, label, l.role == ValueRole.scalar, null));
  }
  for (final fields in located.formFields.values) {
    for (final MapEntry(key: name, value: l) in fields.entries) {
      final at = l.idPath.lastIndexOf(' > ');
      final label = '${l.idPath.substring(0, at)} / $name';
      values.add((l, label, true, name));
    }
  }
  values.sort((a, b) => a.$1.keyLine.compareTo(b.$1.keyLine));
  final sectionIds = <String>{
    for (final v in values)
      for (final t in v.$1.idPath.split(' > '))
        if (_sectionId.hasMatch(t)) t,
  };
  final underIds = under?.split('/');
  if (underIds != null && !values.any((v) => _under(v.$1.idPath, underIds))) {
    throw SecondarySectionNotFound(under!);
  }
  final collector = _Collector(kinds);
  final rewrites = <SecondaryValueRewrite>[];
  final reflows = <SecondaryReflow>[];
  for (final (loc, label, whole, field) in values) {
    if (underIds != null && !_under(loc.idPath, underIds)) continue;
    final old = loc.value;
    var text = old;
    if (reflow) {
      final r = reflowText(text);
      if (r != text) {
        reflows.add(
          SecondaryReflow(
            label,
            loc.keyLine + 2,
            '\n'.allMatches(text).length + 1,
          ),
        );
        text = r;
      }
    }
    final changes = collector.value(
      text,
      label: label,
      firstLine: loc.keyLine + 2,
      isRoot: field == null && loc.path == rootContent,
      wholeValueRule: whole,
      sectionIds: sectionIds,
    );
    if (text == old && changes.isEmpty) continue;
    rewrites.add(
      SecondaryValueRewrite(
        location: loc,
        field: field,
        label: label,
        oldValue: old,
        reflowed: text,
        newValue: applySecondaryEdits(text, [
          for (final c in changes) ...c.edits,
        ]),
        changes: changes,
      ),
    );
  }
  final failures = <String>[];
  String rewritten = yamlText;
  if (rewrites.isNotEmpty) {
    try {
      rewritten = rewriteSecondaryValues(yamlText, rewrites);
      failures.addAll(verifyMarkSecondary(yamlText, rewritten, tree, rewrites));
    } on YamlRewriteException catch (x) {
      failures.add('$x');
    }
  }
  return MarkSecondaryResult(
    text: failures.isEmpty ? rewritten : yamlText,
    changes: [for (final r in rewrites) ...r.changes],
    candidates: collector.candidates,
    skips: collector.skips,
    unknownFamilies: collector.unknownFamilies,
    reflows: reflows,
    changedValues: rewrites.length,
    rewrites: rewrites,
    failures: failures,
  );
}

/// Whether [idPath] (` > `-separated) holds [ids] in order, each after the
/// one before.
bool _under(String idPath, List<String> ids) {
  final tokens = idPath.split(' > ');
  var i = 0;
  for (final t in tokens) {
    if (i < ids.length && t == ids[i]) i++;
  }
  return i == ids.length;
}

final RegExp _sectionId = RegExp(r'^[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*$');

/// [text] with every edit applied (edits do not overlap; insertions at one
/// offset keep their order).
String applySecondaryEdits(String text, List<SecondaryEdit> edits) {
  final ordered = [...edits]
    ..sort((a, b) {
      final s = a.start.compareTo(b.start);
      return s != 0 ? s : a.end.compareTo(b.end);
    });
  final out = StringBuffer();
  var at = 0;
  for (final e in ordered) {
    out.write(text.substring(at, e.start));
    out.write(e.text);
    at = e.end;
  }
  out.write(text.substring(at));
  return out.toString();
}

/// [newText] with the edits undone: what each edit wrote, found where it was
/// written, replaced by what it replaced in [oldText].
String undoSecondaryEdits(
  String newText,
  String oldText,
  List<SecondaryEdit> edits,
) {
  final ordered = [...edits]
    ..sort((a, b) {
      final s = a.start.compareTo(b.start);
      return s != 0 ? s : a.end.compareTo(b.end);
    });
  final out = StringBuffer();
  var shift = 0, at = 0;
  for (final e in ordered) {
    final writtenAt = e.start + shift;
    out.write(newText.substring(at, writtenAt));
    out.write(oldText.substring(e.start, e.end));
    at = writtenAt + e.text.length;
    shift += e.text.length - (e.end - e.start);
  }
  out.write(newText.substring(at));
  return out.toString();
}

/// [text] with the soft-wrapped lines of a one-paragraph value joined by a
/// space; [text] itself when it is not such a value (a blank line, a list, a
/// table, a quote, a heading, a fence, a hard break or an indented line).
String reflowText(String text) {
  if (!text.contains('\n') || text.contains('\n\n')) return text;
  final lines = text.split('\n');
  for (final l in lines) {
    if (l.isEmpty ||
        l != l.trim() ||
        l.endsWith(r'\') ||
        _blockStart.hasMatch(l)) {
      return text;
    }
  }
  return lines.join(' ');
}

final RegExp _blockStart = RegExp(
  r'^(?:[-*+] |\d+[.)] |\||>|#|```|~~~|:::|<!--)',
);

/// The YAML [yamlText] with every value of [rewrites] rewritten: a `|2-`
/// block scalar in place, a one-line plain scalar turned into one.
///
/// Throws [YamlRewriteException] when a value has another layout.
String rewriteSecondaryValues(
  String yamlText,
  List<SecondaryValueRewrite> rewrites,
) {
  final lines = yamlText.split('\n');
  final ordered = [...rewrites]
    ..sort((a, b) => b.location.keyLine.compareTo(a.location.keyLine));
  for (final r in ordered) {
    final loc = r.location;
    final header = lines[loc.keyLine];
    if (header.endsWith(': |2-')) {
      // The block scalar's body, checked line for line against the
      // encoder's shape of the stored value (as rewriteValues does).
      final oldBody = blockBody(loc.value, loc.keyColumn);
      for (var i = 0; i < oldBody.length; i++) {
        final at = loc.keyLine + 1 + i;
        if (at >= lines.length || lines[at] != oldBody[i]) {
          throw YamlRewriteException(
            loc.path,
            'line ${at + 1} differs from the encoder\'s shape of the value',
          );
        }
      }
      lines.replaceRange(
        loc.keyLine + 1,
        loc.keyLine + 1 + oldBody.length,
        blockBody(r.newValue, loc.keyColumn),
      );
      continue;
    }
    final colon = header.indexOf(': ', loc.keyColumn);
    final rest = colon < 0 ? '' : header.substring(colon + 2);
    final next = loc.keyLine + 1 < lines.length ? lines[loc.keyLine + 1] : '';
    final nextIndent = next.length - next.trimLeft().length;
    if (colon < 0 ||
        loc.value.contains('\n') ||
        rest.isEmpty ||
        rest.startsWith('|') ||
        rest.startsWith('>') ||
        (next.trim().isNotEmpty && nextIndent > loc.keyColumn)) {
      throw YamlRewriteException(
        loc.path,
        'line ${loc.keyLine + 1} is neither a `key: |2-` block scalar nor a '
        'one-line scalar',
      );
    }
    lines.replaceRange(loc.keyLine, loc.keyLine + 1, [
      '${header.substring(0, colon)}: |2-',
      ...blockBody(r.newValue, loc.keyColumn),
    ]);
  }
  return lines.join('\n');
}

Map<String, String> _snapshot(SpecDocument d) => {
  for (final p in d.contentPaths) 'C|$p': d.content(p) ?? '',
  for (final p in d.formPaths)
    for (final f in d.formFieldNames(p)) 'F|$p|$f': d.formField(p, f) ?? '',
};

/// The checks a rewrite must pass before it is written; the failures, none
/// when it passed:
///
/// - each value: undoing its edits gives back the value before them, each
///   edit is the one its pattern makes, a reflow only turned line breaks into
///   spaces, and the value has no notation error it did not have;
/// - the file: [rewritten] decodes to the document of [original] with exactly
///   the rewritten values changed, each to its new text.
List<String> verifyMarkSecondary(
  String original,
  String rewritten,
  SomMetaTree tree,
  List<SecondaryValueRewrite> rewrites,
) {
  final failures = <String>[];
  for (final r in rewrites) {
    if (r.reflowed != r.oldValue &&
        r.reflowed != r.oldValue.replaceAll('\n', ' ')) {
      failures.add('${r.label}: the reflow changed more than line breaks');
    }
    final edits = [for (final c in r.changes) ...c.edits];
    if (applySecondaryEdits(r.reflowed, edits) != r.newValue) {
      failures.add('${r.label}: the new value is not the edits applied');
    }
    if (undoSecondaryEdits(r.newValue, r.reflowed, edits) != r.reflowed) {
      failures.add(
        '${r.label}: removing the markers does not give the value back',
      );
    }
    for (final c in r.changes) {
      final problem = _patternProblem(c, r.reflowed);
      if (problem != null) failures.add('${r.label}: $problem');
    }
    final before = scanNotation(r.reflowed, tomSpecs: true);
    final after = scanNotation(r.newValue, tomSpecs: true);
    final was = {
      for (final f in before.findings)
        if (f.severity == NotationSeverity.error) f.code,
    };
    for (final f in after.findings) {
      if (f.severity == NotationSeverity.error && !was.contains(f.code)) {
        failures.add('${r.label}: new notation finding ${f.code.name}');
      }
    }
    final added = r.changes
        .where((c) => c.kind != SecondaryKind.references)
        .length;
    if (after.all.length - before.all.length != added) {
      failures.add(
        '${r.label}: ${after.all.length - before.all.length} notation '
        'element(s) added, $added expected',
      );
    }
  }
  final SpecDocument a, b;
  try {
    a = SpecDocumentYaml.decode(original, tree).document;
    b = SpecDocumentYaml.decode(rewritten, tree).document;
  } on Object catch (x) {
    return [...failures, 'the rewritten YAML does not decode: $x'];
  }
  final expected = _snapshot(a);
  final got = _snapshot(b);
  final changed = <String, String>{};
  for (final r in rewrites) {
    final loc = r.location;
    final field = r.field;
    changed[field == null ? 'C|${loc.path}' : 'F|${loc.path}|$field'] =
        r.newValue;
  }
  for (final k in {...expected.keys, ...got.keys}) {
    final want = changed[k] ?? expected[k] ?? '';
    if ((got[k] ?? '') != want) {
      failures.add('$k: the rewritten YAML holds another value');
    }
  }
  return failures;
}

/// Why [c] is not the edit its pattern makes of [text], or null.
String? _patternProblem(SecondaryChange c, String text) {
  final e = c.edits;
  switch (c.kind) {
    case SecondaryKind.trace:
      final old = text.substring(e.single.start, e.single.end);
      final ids = _idsOf(old);
      if (ids.isEmpty ||
          old != _runsOf(old) ||
          e.single.text != '(-> ${ids.join(', ')})' ||
          !ids.every(_knownId)) {
        return 'the trace citation $old → ${e.single.text} is not the pattern';
      }
    case SecondaryKind.provenance:
      final old = text.substring(e.single.start, e.single.end);
      final m = _p1.firstMatch(old.replaceAll('\n', ' '));
      if (m == null || e.single.text != '(<~ ${m.group(1)})') {
        return 'the provenance note $old → ${e.single.text} is not the pattern';
      }
    case SecondaryKind.editorial:
      if (e.length != 2 ||
          e[0].start != e[0].end ||
          e[1].start != e[1].end ||
          e[0].text != '::: {.editorial}\n' ||
          e[1].text != '\n:::' ||
          !text.substring(e[0].start).startsWith(_e1)) {
        return 'the editorial div is not the pattern';
      }
    case SecondaryKind.references:
      final old = text.substring(e.single.start, e.single.end);
      final cross = _r1Cross.firstMatch(old);
      final same = _r1Same.firstMatch(old);
      final path = (cross?.group(2) ?? same?.group(1))?.split(' > ');
      final want = path == null
          ? null
          : cross != null
          ? '[${path.last}](${_docTarget(cross.group(1)!)}#${path.last})'
          : '[${path.last}](#${path.last})';
      if (want == null ||
          (cross?.group(0) ?? same?.group(0)) != old ||
          e.single.text != want) {
        return 'the reference $old → ${e.single.text} is not the pattern';
      }
  }
  return null;
}

/// The contents of the top-level parenthesised groups of [s] when [s] is one
/// or more balanced groups separated by single spaces, else null.
List<String>? _groupsOf(String s) {
  final groups = <String>[];
  var i = 0;
  while (true) {
    if (i >= s.length || s[i] != '(') return null;
    var depth = 0;
    var j = i;
    for (; j < s.length; j++) {
      if (s[j] == '(') depth++;
      if (s[j] == ')' && --depth == 0) break;
    }
    if (j >= s.length || j == i + 1) return null;
    groups.add(s.substring(i + 1, j));
    i = j + 1;
    if (i == s.length) return groups;
    if (s[i] != ' ') return null;
    i++;
  }
}

/// The items of the parenthesised runs of [run], in order: each an id, or an
/// id with the option taken (`DQ-115 (b)`).
List<String> _idsOf(String run) => [
  for (final g in _groupsOf(run) ?? const <String>[])
    ...g.split(RegExp(r',\s*')),
];

/// [s] itself when it is one or more parenthesised runs separated by single
/// spaces, else an empty string.
String _runsOf(String s) => _groupsOf(s) == null ? '' : s;

final RegExp _idShape = RegExp(r'^([A-Z][A-Za-z]*)-?\d+(?:\.\d+)*[a-z]?$');

/// A decision cited with the option taken: an id, one space, `(<letter>)`
/// (DocSpecs RN-3).
final RegExp _optionTaken = RegExp(r'^(.+) \([a-z]\)$');

/// [item] without the option taken it carries, if any.
String _bareId(String item) {
  final m = _optionTaken.firstMatch(item);
  return m != null && _idShape.hasMatch(m.group(1)!) ? m.group(1)! : item;
}

bool _knownId(String item) {
  final m = _idShape.firstMatch(_bareId(item));
  return m != null && secondaryIdFamilies.contains(m.group(1));
}

final RegExp _p1 = RegExp(r'^_Extrapolated — see (.+)\._$');
const String _e1 = '**The provenance notes.**';
final RegExp _r1Cross = RegExp(
  r'\(`([^`\s]+\.md)`, `([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*(?: > [A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*)*)`\)',
);
final RegExp _r1Same = RegExp(
  r'`([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*(?: > [A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*)+)`',
);
final RegExp _preposition = RegExp(
  r'(?:^|[\s(])(?:see|per|under|cf\.)$',
  caseSensitive: false,
);
final RegExp _knownFamilyToken = RegExp(
  '\\b(?:${secondaryIdFamilies.join('|')})-?\\d',
);

/// `<doc>.tomspecs.md` for a document named `<doc>.md` or
/// `<doc>.tomspecs.md`.
String _docTarget(String doc) {
  final base = doc.endsWith('.tomspecs.md')
      ? doc.substring(0, doc.length - '.tomspecs.md'.length)
      : doc.substring(0, doc.length - '.md'.length);
  return '$base.tomspecs.md';
}

/// A range `[start, end)` of a value.
typedef _Range = (int, int);

bool _overlaps(_Range r, int s, int e) => r.$1 < e && s < r.$2;

bool _inside(_Range r, int s, int e) => r.$1 <= s && e <= r.$2;

/// Collects the changes, candidates and skips of one run.
class _Collector {
  _Collector(this.kinds);

  final Set<SecondaryKind> kinds;
  final List<SecondaryCandidate> candidates = [];
  final Map<SecondaryKind, Map<String, int>> skips = {
    for (final k in SecondaryKind.values) k: {},
  };
  final Map<String, int> unknownFamilies = {};

  void _skip(SecondaryKind k, String reason) {
    final m = skips[k]!;
    m[reason] = (m[reason] ?? 0) + 1;
  }

  /// The changes of one value.
  List<SecondaryChange> value(
    String text, {
    required String label,
    required int firstLine,
    required bool isRoot,
    required bool wholeValueRule,
    required Set<String> sectionIds,
  }) {
    final v = _Value(text);
    final changes = <SecondaryChange>[];
    final taken = <_Range>[];

    SecondaryChange change(
      SecondaryKind kind,
      String original,
      List<SecondaryEdit> edits,
    ) {
      final s = edits.first.start;
      final lineStart = _lastBefore(text, '\n', s) + 1;
      var lineEnd = text.indexOf('\n', edits.last.end);
      if (lineEnd < 0) lineEnd = text.length;
      final line = text.substring(lineStart, lineEnd);
      final local = [
        for (final e in edits)
          SecondaryEdit(e.start - lineStart, e.end - lineStart, e.text),
      ];
      return SecondaryChange(
        kind: kind,
        value: label,
        line: firstLine + '\n'.allMatches(text.substring(0, s)).length,
        original: original,
        edits: edits,
        before: _excerpt(line, local.first.start),
        after: _excerpt(applySecondaryEdits(line, local), local.first.start),
      );
    }

    void candidate(SecondaryKind kind, String reason, int at, String t) {
      candidates.add(
        SecondaryCandidate(
          kind: kind,
          reason: reason,
          value: label,
          line: firstLine + '\n'.allMatches(text.substring(0, at)).length,
          text: t,
        ),
      );
    }

    // E1 and P1, per paragraph.
    for (final (ps, pe) in v.paragraphs) {
      final para = text.substring(ps, pe);
      if (v.protectedLine(ps)) continue;
      if (kinds.contains(SecondaryKind.editorial) && isRoot) {
        if (para.startsWith(_e1)) {
          if (v.inNotation(ps, pe)) {
            _skip(SecondaryKind.editorial, 'alreadyMarked');
          } else {
            changes.add(
              change(SecondaryKind.editorial, para, [
                SecondaryEdit(ps, ps, '::: {.editorial}\n'),
                SecondaryEdit(pe, pe, '\n:::'),
              ]),
            );
          }
        } else if (para.startsWith('**')) {
          candidate(SecondaryKind.editorial, 'boldLed', ps, _first(para));
        }
      }
      if (kinds.contains(SecondaryKind.provenance) &&
          para.contains('_Extrapolated — see ')) {
        final m = _p1.firstMatch(para.replaceAll('\n', ' '));
        final target = m?.group(1);
        if (v.inNotation(ps, pe)) {
          _skip(SecondaryKind.provenance, 'alreadyMarked');
        } else if (m != null &&
            target != null &&
            !target.contains('._') &&
            _balanced(target) &&
            !v.inCodeSpan(ps, pe)) {
          changes.add(
            change(SecondaryKind.provenance, para, [
              SecondaryEdit(ps, pe, '(<~ $target)'),
            ]),
          );
          taken.add((ps, pe));
        } else {
          final at = para.indexOf('_Extrapolated — see ');
          if (v.inCodeSpan(ps + at, ps + at + 1)) {
            _skip(SecondaryKind.provenance, 'inCodeSpan');
          } else {
            candidate(SecondaryKind.provenance, 'moreText', ps + at, para);
          }
        }
      }
    }

    // R1: cross-document references, then same-document section paths.
    if (kinds.contains(SecondaryKind.references)) {
      for (final m in _r1Cross.allMatches(text)) {
        if (v.protectedLine(m.start) ||
            v.inNotation(m.start, m.end) ||
            v.straddlesMark(m.start, m.end) ||
            v.inCodeSpanExceptOwn(m.start, m.end)) {
          _skip(SecondaryKind.references, 'protected');
          continue;
        }
        final last = m.group(2)!.split(' > ').last;
        changes.add(
          change(SecondaryKind.references, m.group(0)!, [
            SecondaryEdit(
              m.start,
              m.end,
              '[$last](${_docTarget(m.group(1)!)}#$last)',
            ),
          ]),
        );
        taken.add((m.start, m.end));
      }
      for (final m in _r1Same.allMatches(text)) {
        if (taken.any((r) => _overlaps(r, m.start, m.end))) continue;
        if (!v.isCodeSpan(m.start, m.end) ||
            v.protectedLine(m.start) ||
            v.inNotation(m.start, m.end) ||
            v.straddlesMark(m.start, m.end)) {
          _skip(SecondaryKind.references, 'protected');
          continue;
        }
        final ids = m.group(1)!.split(' > ');
        if (!ids.every(sectionIds.contains)) {
          candidate(
            SecondaryKind.references,
            'noSuchSection',
            m.start,
            m.group(0)!,
          );
          continue;
        }
        changes.add(
          change(SecondaryKind.references, m.group(0)!, [
            SecondaryEdit(m.start, m.end, '[${ids.last}](#${ids.last})'),
          ]),
        );
        taken.add((m.start, m.end));
      }
    }

    // T1: parenthesised id runs.
    if (kinds.contains(SecondaryKind.trace)) {
      final runs = <_Range>[];
      for (final (s, e) in v.parentheses) {
        if (taken.any((r) => _overlaps(r, s, e))) continue;
        final inner = text.substring(s + 1, e - 1);
        if (inner.startsWith('->') ||
            inner.startsWith('<-') ||
            inner.startsWith('<~')) {
          continue;
        }
        final items = inner.split(RegExp(r',\s*'));
        final shaped = items.every((i) => _idShape.hasMatch(_bareId(i)));
        final known = items.every(_knownId);
        final mentions = _knownFamilyToken.hasMatch(inner);
        if (shaped && !known) {
          for (final i in items) {
            final f = _idShape.firstMatch(_bareId(i))!.group(1)!;
            if (!secondaryIdFamilies.contains(f)) {
              unknownFamilies[f] = (unknownFamilies[f] ?? 0) + 1;
            }
          }
          _skip(SecondaryKind.trace, 'unknownFamily');
          continue;
        }
        if (!known && !mentions) continue;
        if (v.protectedLine(s) || v.inCodeSpan(s, s + 1)) {
          _skip(SecondaryKind.trace, 'inCode');
          continue;
        }
        if (v.inNotation(s, e)) {
          _skip(SecondaryKind.trace, 'alreadyMarked');
          continue;
        }
        if (!known) {
          final reason = inner.contains('`') ? 'codeSpanInRun' : 'worded';
          candidate(SecondaryKind.trace, reason, s, text.substring(s, e));
          continue;
        }
        if (v.straddlesMark(s, e)) {
          _skip(SecondaryKind.trace, 'straddlesMark');
          continue;
        }
        runs.add((s, e));
      }
      // Adjacent runs separated by single spaces become one.
      final groups = <_Range>[];
      for (final r in runs) {
        if (groups.isNotEmpty &&
            groups.last.$2 + 1 == r.$1 &&
            text[groups.last.$2] == ' ' &&
            !v.straddlesMark(groups.last.$1, r.$2)) {
          groups[groups.length - 1] = (groups.last.$1, r.$2);
        } else {
          groups.add(r);
        }
      }
      for (final (s, e) in groups) {
        final run = text.substring(s, e);
        if (wholeValueRule && text.trim() == run) {
          _skip(SecondaryKind.trace, 'wholeValue');
          continue;
        }
        final before = v.textBefore(s, e);
        if (before == null) {
          _skip(SecondaryKind.trace, 'wholeCell');
          continue;
        }
        if (before.trim().isEmpty) {
          _skip(SecondaryKind.trace, 'noTextBefore');
          continue;
        }
        if (_preposition.hasMatch(before.trimRight())) {
          candidate(SecondaryKind.trace, 'afterPreposition', s, run);
          continue;
        }
        final ids = _idsOf(run);
        changes.add(
          change(SecondaryKind.trace, run, [
            SecondaryEdit(s, e, '(-> ${ids.join(', ')})'),
          ]),
        );
      }
    }
    changes.sort((a, b) => a.edits.first.start.compareTo(b.edits.first.start));
    return changes;
  }
}

String _first(String para) {
  final nl = para.indexOf('\n');
  final line = nl < 0 ? para : para.substring(0, nl);
  return line.length > 120 ? '${line.substring(0, 120)}…' : line;
}

/// The last offset of [c] before [at] in [text], or -1.
int _lastBefore(String text, String c, int at) =>
    at <= 0 ? -1 : text.lastIndexOf(c, at - 1);

bool _balanced(String s) {
  var d = 0;
  for (final c in s.codeUnits) {
    if (c == 0x28) d++;
    if (c == 0x29 && --d < 0) return false;
  }
  return d == 0;
}

/// A window of [line] around [at], at most 160 characters.
String _excerpt(String text, int at) {
  var line = text;
  line = line.replaceAll('\n', '⏎');
  if (line.length <= 160) return line;
  final s = (at - 60).clamp(0, line.length);
  final e = (s + 160).clamp(0, line.length);
  return '${s > 0 ? '…' : ''}${line.substring(s, e)}${e < line.length ? '…' : ''}';
}

/// One value's text and the places in it no pattern may touch.
class _Value {
  _Value(this.text) {
    final lines = text.split('\n');
    var offset = 0;
    var fence = '';
    var paraStart = -1;
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      final start = offset;
      final end = offset + l.length;
      offset = end + 1;
      final t = l.trimLeft();
      final fenceMatch = RegExp(r'^(`{3,}|~{3,})').firstMatch(t);
      var prot = false;
      if (fence.isNotEmpty) {
        prot = true;
        if (fenceMatch != null &&
            fenceMatch.group(1)![0] == fence[0] &&
            fenceMatch.group(1)!.length >= fence.length &&
            t.trim() == fenceMatch.group(1)) {
          fence = '';
        }
      } else if (fenceMatch != null) {
        prot = true;
        fence = fenceMatch.group(1)!;
      } else if (t.startsWith('>') || t.startsWith(':::')) {
        prot = true;
      }
      if (prot) _protectedLines.add((start, end));
      // A list item or a table row starts a block of its own.
      if (paraStart >= 0 && !prot && _blockStart.hasMatch(t)) {
        paragraphs.add((paraStart, _trimEnd(paraStart, start - 1)));
        paraStart = -1;
      }
      if (l.trim().isEmpty || prot) {
        if (paraStart >= 0) {
          paragraphs.add((paraStart, _trimEnd(paraStart, start - 1)));
          paraStart = -1;
        }
      } else if (paraStart < 0) {
        paraStart = start;
      }
    }
    if (paraStart >= 0) {
      paragraphs.add((paraStart, _trimEnd(paraStart, text.length)));
    }
    _scanCodeSpans();
    _scanMarks();
    _scanParentheses();
    for (final e in scanNotation(text).elements) {
      _notation.add((e.start, e.end));
    }
  }

  final String text;
  final List<_Range> paragraphs = [];
  final List<_Range> _protectedLines = [];
  final List<_Range> _codeSpans = [];
  final List<_Range> _marks = [];
  final List<_Range> _notation = [];
  final List<_Range> parentheses = [];

  int _trimEnd(int start, int end) {
    var e = end;
    while (e > start && (text[e - 1] == ' ' || text[e - 1] == '\n')) {
      e--;
    }
    return e;
  }

  bool protectedLine(int at) =>
      _protectedLines.any((r) => r.$1 <= at && at <= r.$2);

  bool inNotation(int s, int e) => _notation.any((r) => _overlaps(r, s, e));

  bool inCodeSpan(int s, int e) => _codeSpans.any((r) => _overlaps(r, s, e));

  /// Whether `[s, e)` touches a code span it does not contain whole.
  bool inCodeSpanExceptOwn(int s, int e) =>
      _codeSpans.any((r) => _overlaps(r, s, e) && !_inside((s, e), r.$1, r.$2));

  /// Whether `[s, e)` is exactly a code span.
  bool isCodeSpan(int s, int e) =>
      _codeSpans.any((r) => r.$1 == s && r.$2 == e);

  /// Whether `[s, e)` overlaps an inline review mark without lying wholly
  /// inside or outside it.
  bool straddlesMark(int s, int e) => _marks.any(
    (r) =>
        _overlaps(r, s, e) && !_inside(r, s, e) && !_inside((s, e), r.$1, r.$2),
  );

  /// The text before [at] in its paragraph — in a table row, in its cell;
  /// after a list marker — or null when [at] stands in a table cell that holds
  /// nothing else.
  String? textBefore(int at, int end) {
    final lineStart = _lastBefore(text, '\n', at) + 1;
    var lineEnd = text.indexOf('\n', at);
    if (lineEnd < 0) lineEnd = text.length;
    final line = text.substring(lineStart, lineEnd);
    if (line.trimLeft().startsWith('|')) {
      final cellStart = _lastBefore(text, '|', at) + 1;
      var cellEnd = text.indexOf('|', at);
      if (cellEnd < 0 || cellEnd > lineEnd) cellEnd = lineEnd;
      final before = text.substring(cellStart, at);
      final rest = end < cellEnd ? text.substring(end, cellEnd) : '';
      if (before.trim().isEmpty && rest.trim().isEmpty) return null;
      return before;
    }
    final para = paragraphs.firstWhere(
      (p) => p.$1 <= at && at <= p.$2,
      orElse: () => (lineStart, lineEnd),
    );
    return text
        .substring(para.$1, at)
        .replaceFirst(RegExp(r'^\s*(?:[-*+]|\d+[.)])\s+'), '');
  }

  void _scanCodeSpans() {
    for (final (ps, pe) in paragraphs) {
      var i = ps;
      while (i < pe) {
        if (text[i] == '\\') {
          i += 2;
          continue;
        }
        if (text[i] != '`') {
          i++;
          continue;
        }
        var n = 0;
        while (i + n < pe && text[i + n] == '`') {
          n++;
        }
        var j = i + n;
        var close = -1;
        while (j < pe) {
          if (text[j] == '`') {
            var m = 0;
            while (j + m < pe && text[j + m] == '`') {
              m++;
            }
            if (m == n) {
              close = j;
              break;
            }
            j += m;
          } else {
            j++;
          }
        }
        if (close < 0) {
          i += n;
          continue;
        }
        _codeSpans.add((i, close + n));
        i = close + n;
      }
    }
  }

  void _scanMarks() {
    final re = RegExp(r'\{(\+\+|--|~~|==|>>)[\s\S]*?(\+\+|--|~~|==|<<)\}');
    for (final m in re.allMatches(text)) {
      _marks.add((m.start, m.end));
    }
  }

  void _scanParentheses() {
    final stack = <int>[];
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '\n') {
        stack.clear();
      } else if (c == '(') {
        stack.add(i);
      } else if (c == ')' && stack.isNotEmpty) {
        final s = stack.removeLast();
        if (!inCodeSpan(s, s + 1) || inCodeSpan(i, i + 1)) {
          parentheses.add((s, i + 1));
        }
      }
    }
    parentheses.sort((a, b) => a.$1.compareTo(b.$1));
  }
}
