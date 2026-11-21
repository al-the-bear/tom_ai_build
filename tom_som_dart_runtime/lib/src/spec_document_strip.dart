/// Stripped renditions (SOM §11.10; the reading view's part *Stripped
/// renditions and the merge back*): a copy of a document with the secondary
/// prose of named kinds dropped, unmarked or moved to an appendix, for a
/// reader who wants the specification without its working notes.
///
/// The kinds are the four the reading notation registers as secondary
/// (`provenance`, `trace`, `editorial`, `aside`, DocSpecs RN-5) plus
/// `comments`, the review annotations (SOM §11.9). A citation shape counts as
/// a span of its kind. `refs`, `records` and `rejected` are never secondary:
/// no name drops or unmarks them, and `all` leaves them in place (RN-11).
///
/// [stripNotationText] strips one value; [SpecDocumentStrip.strip] strips a
/// whole document and, given the model, applies the emptying rule, numbers
/// the appendix, renders the `.readable.md` and checks it. Every removal is
/// recorded as a [SpecStripPiece] anchored in the stripped text, which is
/// what a merge of an edited rendition back onto the original needs.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'docspecs_validator.dart';
import 'spec_document.dart';
import 'spec_document_markdown.dart';
import 'spec_model.dart';
import 'spec_notation.dart';
import 'spec_review_annotations.dart'
    show annotationIssuesText, countAnnotationsText, stripAnnotationsText;
import 'spec_schema_validation.dart';
import 'spec_validator.dart';

part 'spec_document_merge.dart';

/// The kind names a strip takes, in the order a report and the readable header
/// list them; `all` is shorthand for every name a list can hold.
const List<String> specStripKindNames = [
  'provenance',
  'trace',
  'editorial',
  'aside',
  'comments',
];

/// The notation kinds a strip can drop, unmark or move to the appendix.
const List<String> specStripNotationKinds = [
  'provenance',
  'trace',
  'editorial',
  'aside',
];

/// A strip asked for something it cannot do: an unknown name, a name in two
/// lists, `comments` to unmark or to move. The message says which.
class SpecStripUsageError implements Exception {
  /// The error, with [message].
  const SpecStripUsageError(this.message);

  /// What is wrong, naming the valid names where a name was unknown.
  final String message;

  @override
  String toString() => 'SpecStripUsageError: $message';
}

/// What a strip does with each kind.
class SpecStripOptions {
  /// The options as sets of kind names; see [SpecStripOptions.fromNames] for
  /// the checked form that expands `all`.
  const SpecStripOptions({
    this.drop = const {},
    this.unmark = const {},
    this.appendix = const {},
    this.appendixReferences = false,
    this.headingDivs = false,
  });

  /// The options from the names a user gives, each list item possibly
  /// comma-joined (`-drop:provenance,trace`). `all` stands for every kind the
  /// list can hold that no other list names explicitly: in [drop] the four
  /// notation kinds and `comments`, in [unmark] and [appendix] the four
  /// notation kinds.
  ///
  /// Throws [SpecStripUsageError] for an unknown name (the message lists the
  /// known ones), a name given in two lists, `comments` in [unmark] or
  /// [appendix], and [appendixReferences] without an appendix.
  factory SpecStripOptions.fromNames({
    Iterable<String> drop = const [],
    Iterable<String> unmark = const [],
    Iterable<String> appendix = const [],
    bool appendixReferences = false,
    bool headingDivs = false,
  }) {
    List<String> names(Iterable<String> list) => [
      for (final item in list)
        for (final n in item.split(','))
          if (n.trim().isNotEmpty) n.trim(),
    ];
    final lists = {
      'drop': names(drop),
      'unmark': names(unmark),
      'appendix': names(appendix),
    };
    const known = [...specStripKindNames, 'all'];
    for (final e in lists.entries) {
      for (final n in e.value) {
        if (!known.contains(n)) {
          throw SpecStripUsageError(
            'unknown kind name "$n" in ${e.key}; known names: '
            '${known.join(', ')}',
          );
        }
      }
    }
    final keys = lists.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      for (var j = i + 1; j < keys.length; j++) {
        for (final n in lists[keys[i]]!) {
          if (lists[keys[j]]!.contains(n)) {
            throw SpecStripUsageError(
              'kind name "$n" is in both ${keys[i]} and ${keys[j]}',
            );
          }
        }
      }
    }
    if (lists['unmark']!.contains('comments')) {
      throw const SpecStripUsageError(
        'comments cannot be unmarked: a review annotation has no reading '
        'without its markers; drop it or leave it',
      );
    }
    if (lists['appendix']!.contains('comments')) {
      throw const SpecStripUsageError(
        'comments cannot be moved to the appendix; drop them or leave them',
      );
    }
    final explicit = {
      for (final l in lists.values)
        for (final n in l)
          if (n != 'all') n,
    };
    Set<String> expand(String list, List<String> all) {
      final out = <String>{};
      for (final n in lists[list]!) {
        if (n == 'all') {
          out.addAll(all.where((k) => !explicit.contains(k)));
        } else {
          out.add(n);
        }
      }
      return out;
    }

    final appendixSet = expand('appendix', specStripNotationKinds);
    if (appendixReferences && appendixSet.isEmpty) {
      throw const SpecStripUsageError(
        'appendix references need an appendix: name its kinds',
      );
    }
    return SpecStripOptions(
      drop: expand('drop', specStripKindNames),
      unmark: expand('unmark', specStripNotationKinds),
      appendix: appendixSet,
      appendixReferences: appendixReferences,
      headingDivs: headingDivs,
    );
  }

  /// The kinds removed with their content.
  final Set<String> drop;

  /// The kinds whose markers go and whose content stays.
  final Set<String> unmark;

  /// The kinds moved, with their content, into the appendix *Notes*.
  final Set<String> appendix;

  /// Whether each moved element leaves a link `[n]` to its appendix entry,
  /// and the entry links back.
  final bool appendixReferences;

  /// Whether the rendition writes sections deeper than level 6 as styled-div
  /// headings (SOM §11.2).
  final bool headingDivs;

  /// The options of the emptying rule: every notation kind that would be
  /// dropped or moved is unmarked instead; `comments` stays dropped.
  SpecStripOptions get keeping => SpecStripOptions(
    drop: drop.contains('comments') ? const {'comments'} : const {},
    unmark: {
      ...unmark,
      ...drop.difference({'comments'}),
      ...appendix,
    },
    headingDivs: headingDivs,
  );

  /// The options an appendix entry's own content is stripped with: what is
  /// moved is unmarked there, so an entry holds no entry of its own.
  SpecStripOptions get _inEntry => SpecStripOptions(
    drop: drop.difference({'comments'}),
    unmark: {...unmark, ...appendix},
  );

  /// The names in the canonical order of [specStripKindNames].
  static List<String> ordered(Set<String> names) => [
    for (final k in specStripKindNames)
      if (names.contains(k)) k,
  ];
}

/// The source a readable rendition was made from, for its header.
class SpecReadableSource {
  /// The source file [file] at [revision], from [commit] (with [dirty] when
  /// the working tree had uncommitted changes).
  const SpecReadableSource({
    required this.file,
    this.revision,
    this.commit,
    this.dirty = false,
  });

  /// The file name of the document of record (`tom_uam.rsp.tomspecs.yaml`).
  final String file;

  /// The document's revision, when known.
  final String? revision;

  /// The commit the file was read at, when known.
  final String? commit;

  /// Whether the file had uncommitted changes at that commit.
  final bool dirty;
}

/// The readable header line of a stripped rendition (SOM §11.1): the
/// switches it was made with and its source, `<!-- readable: drop=…;
/// unmark=…; appendix=…; appendix-references; headings=divs;
/// of=<file>@<revision>; commit=<sha>[+dirty] -->`. Parts that do not apply
/// are left out; [format] and [parse] are inverse.
class SpecReadableHeader {
  /// A header for [options] and [source].
  const SpecReadableHeader(this.options, {this.source});

  /// The switches.
  final SpecStripOptions options;

  /// The source, when known.
  final SpecReadableSource? source;

  /// The header line.
  String format() {
    final parts = <String>[
      if (options.drop.isNotEmpty)
        'drop=${SpecStripOptions.ordered(options.drop).join(',')}',
      if (options.unmark.isNotEmpty)
        'unmark=${SpecStripOptions.ordered(options.unmark).join(',')}',
      if (options.appendix.isNotEmpty)
        'appendix=${SpecStripOptions.ordered(options.appendix).join(',')}',
      if (options.appendixReferences) 'appendix-references',
      if (options.headingDivs) 'headings=divs',
      if (source != null)
        'of=${source!.file}'
            '${source!.revision != null ? '@${source!.revision}' : ''}',
      if (source?.commit != null)
        'commit=${source!.commit}${source!.dirty ? '+dirty' : ''}',
    ];
    return parts.isEmpty
        ? '<!-- readable: -->'
        : '<!-- readable: ${parts.join('; ')} -->';
  }

  /// [line] read as a readable header, or null when it is none or names an
  /// unknown part or kind.
  static SpecReadableHeader? parse(String line) {
    final m = RegExp(r'^<!--\s*readable:(.*)-->$').firstMatch(line.trim());
    if (m == null) return null;
    final drop = <String>[], unmark = <String>[], appendix = <String>[];
    var refs = false, divs = false;
    String? file, revision, commit;
    var dirty = false;
    for (final raw in m.group(1)!.split(';')) {
      final part = raw.trim();
      if (part.isEmpty) continue;
      final eq = part.indexOf('=');
      final key = eq < 0 ? part : part.substring(0, eq);
      final value = eq < 0 ? '' : part.substring(eq + 1);
      switch (key) {
        case 'drop':
          drop.add(value);
        case 'unmark':
          unmark.add(value);
        case 'appendix':
          appendix.add(value);
        case 'appendix-references' when eq < 0:
          refs = true;
        case 'headings' when value == 'divs':
          divs = true;
        case 'of':
          final at = value.lastIndexOf('@');
          file = at < 0 ? value : value.substring(0, at);
          revision = at < 0 ? null : value.substring(at + 1);
        case 'commit':
          dirty = value.endsWith('+dirty');
          commit = dirty ? value.substring(0, value.length - 6) : value;
        default:
          return null;
      }
    }
    if (file == null && commit != null) return null;
    try {
      return SpecReadableHeader(
        SpecStripOptions.fromNames(
          drop: drop,
          unmark: unmark,
          appendix: appendix,
          appendixReferences: refs,
          headingDivs: divs,
        ),
        source: file == null
            ? null
            : SpecReadableSource(
                file: file,
                revision: revision,
                commit: commit,
                dirty: dirty,
              ),
      );
    } on SpecStripUsageError {
      return null;
    }
  }
}

/// One piece a strip removed from a value: the original text at [origin]
/// that went ([removed]), the text written in its place ([inserted], usually
/// empty), anchored at [anchor] in the stripped text. Applying every piece
/// at its anchor gives the original back.
class SpecStripPiece {
  /// A piece.
  const SpecStripPiece({
    required this.anchor,
    required this.origin,
    required this.removed,
    required this.inserted,
    required this.labels,
  });

  /// The offset in the stripped text the piece stands at.
  final int anchor;

  /// The offset in the original text the piece starts at.
  final int origin;

  /// The original text the piece removed.
  final String removed;

  /// The text the stripped value holds in its place.
  final String inserted;

  /// What removed it, sorted: `<kind>:drop`, `<kind>:unmark`,
  /// `<kind>:appendix`, `comments`, `mark` (a review mark a dropped span
  /// emptied or halved) and `whitespace` (the normalisation).
  final List<String> labels;

  /// The piece as the conformance corpus writes it.
  Map<String, Object?> toJson() => {
    'anchor': anchor,
    'origin': origin,
    'removed': removed,
    'inserted': inserted,
    'labels': labels,
  };
}

/// One entry of a stripped rendition's appendix *Notes*.
class SpecAppendixEntry {
  /// Entry [number] of [kind] with [text], moved out of the value [value].
  const SpecAppendixEntry({
    required this.number,
    required this.kind,
    required this.text,
    this.value,
  });

  /// The entry's number, counted through the rendition from 1.
  final int number;

  /// The kind of the element moved.
  final String kind;

  /// The entry's text: the element's content (a citation as written), its
  /// own nested elements stripped by the same switches.
  final String text;

  /// The value the element came from; null from [stripNotationText].
  final SpecStripValueRef? value;

  /// The entry as the conformance corpus writes it.
  Map<String, Object?> toJson() => {
    'number': number,
    'kind': kind,
    'text': text,
    if (value != null) 'value': value!.toJson(),
  };
}

/// The result of stripping one value ([stripNotationText]).
class SpecStripTextResult {
  /// A result.
  const SpecStripTextResult({
    required this.text,
    required this.pieces,
    required this.dropped,
    required this.unmarked,
    required this.appended,
    required this.marksDropped,
    required this.appendix,
    required this.findings,
  });

  /// The stripped text; the input unchanged when [refused].
  final String text;

  /// What went, anchored in [text].
  final List<SpecStripPiece> pieces;

  /// Elements dropped per kind (`comments`: blocks and marks).
  final Map<String, int> dropped;

  /// Elements unmarked per kind.
  final Map<String, int> unmarked;

  /// Elements moved to the appendix per kind.
  final Map<String, int> appended;

  /// Review marks that went with a dropped element they stood in.
  final int marksDropped;

  /// The appendix entries, numbered from 1 in the value's order.
  final List<SpecAppendixEntry> appendix;

  /// The notation's error findings in the input (other than `rejectedBlock`):
  /// a value with any is refused and left as it is.
  final List<NotationFinding> findings;

  /// Whether the value was refused for its [findings].
  bool get refused => findings.isNotEmpty;

  /// The result as the conformance corpus writes it.
  Map<String, Object?> toJson() => {
    'text': text,
    'dropped': dropped,
    'unmarked': unmarked,
    'appended': appended,
    'marksDropped': marksDropped,
    'appendix': [for (final e in appendix) e.toJson()],
    'pieces': [for (final p in pieces) p.toJson()],
    'refused': [for (final f in findings) f.code.name],
  };
}

/// Strips one value with [options] (SOM §11.10): comments first
/// ([stripAnnotationsText]), then the notation from the outside in — an
/// element of a dropped kind goes with everything in it, a moved one goes to
/// the appendix, an unmarked one loses its markers and keeps its content —
/// then the whitespace the removals leave is normalised. Appendix entries
/// are numbered from 1 and, with [SpecStripOptions.appendixReferences],
/// linked from their places.
///
/// A value whose notation has an error finding (other than `rejectedBlock`)
/// is refused: the result holds it unchanged with its findings.
SpecStripTextResult stripNotationText(String value, SpecStripOptions options) {
  final plan = _Plan(value, options);
  return plan.finish((i) => i + 1);
}

/// A value of a document: its content, a form field or its headline.
class SpecStripValueRef {
  /// The value at [path]: a form field when [field] is given, the stored
  /// headline when [headline], else the content.
  const SpecStripValueRef(this.path, {this.field, this.headline = false});

  /// The path of the section, form or item.
  final String path;

  /// The form field's name, or null.
  final String? field;

  /// Whether the value is the section's stored headline.
  final bool headline;

  /// The value in [doc], or `''` when unset.
  String read(SpecDocument doc) =>
      (headline
          ? doc.headline(path)
          : field != null
          ? doc.formField(path, field!)
          : doc.content(path)) ??
      '';

  /// Writes [value] into [doc]; an empty one clears it.
  void write(SpecDocument doc, String value) {
    if (headline) {
      doc.setHeadline(path, value);
    } else if (field != null) {
      doc.setFormField(path, field!, value);
    } else {
      doc.setContent(path, value);
    }
  }

  /// The value's place as a report names it.
  String get label =>
      headline ? '$path (headline)' : (field != null ? '$path/$field' : path);

  /// The reference as the conformance corpus writes it.
  Map<String, Object?> toJson() => {
    'path': path,
    if (field != null) 'field': field,
    if (headline) 'headline': true,
  };

  @override
  bool operator ==(Object other) =>
      other is SpecStripValueRef &&
      other.path == path &&
      other.field == field &&
      other.headline == headline;

  @override
  int get hashCode => Object.hash(path, field, headline);

  @override
  String toString() => label;
}

/// One value a strip changed, with what went.
class SpecStrippedValue {
  /// The value [ref], [original] and [stripped], with its [pieces].
  const SpecStrippedValue({
    required this.ref,
    required this.original,
    required this.stripped,
    required this.pieces,
  });

  /// Which value.
  final SpecStripValueRef ref;

  /// The value before the strip.
  final String original;

  /// The value after it.
  final String stripped;

  /// What went, anchored in [stripped].
  final List<SpecStripPiece> pieces;
}

/// A value the emptying rule kept: removing its secondary prose would have
/// emptied a value the model or the schema requires, so the kinds that would
/// have gone were unmarked instead (or, with nothing to unmark, the value was
/// left as it was).
class SpecStripKept {
  /// [ref] kept because of [finding].
  const SpecStripKept(this.ref, this.finding);

  /// The value kept.
  final SpecStripValueRef ref;

  /// The finding its removal would have added.
  final String finding;

  /// The report line.
  @override
  String toString() => 'KEPT (would empty a required value): $ref — $finding';
}

/// A reason a stripped document is not valid: the input's notation, a new
/// finding of the output, or a value `parse(readable)` stages differently.
class SpecStripFinding {
  /// A finding of [kind] about [ref] (or the document) with [message].
  const SpecStripFinding(this.kind, this.message, {this.ref});

  /// `notation` (an input value refused), `instance` / `schema` (a finding
  /// the output adds), `parse` (the rendition does not read back as the
  /// stripped document).
  final String kind;

  /// What is wrong.
  final String message;

  /// The value concerned, when one is.
  final SpecStripValueRef? ref;

  @override
  String toString() => '$kind: ${ref != null ? '$ref: ' : ''}$message';
}

/// The result of [SpecDocumentStrip.strip].
class SpecStripResult {
  /// A result.
  const SpecStripResult({
    required this.document,
    required this.values,
    required this.kept,
    required this.removedItems,
    required this.appendix,
    required this.dropped,
    required this.unmarked,
    required this.appended,
    required this.marksDropped,
    required this.readableHeader,
    required this.readable,
    required this.findings,
  });

  /// The stripped copy; the input document is unchanged.
  final SpecDocument document;

  /// Every value the strip changed, in document order.
  final List<SpecStrippedValue> values;

  /// The values the emptying rule kept.
  final List<SpecStripKept> kept;

  /// The list items removed because nothing was left in them.
  final List<String> removedItems;

  /// The appendix entries, numbered through the rendition.
  final List<SpecAppendixEntry> appendix;

  /// Elements dropped per kind.
  final Map<String, int> dropped;

  /// Elements unmarked per kind.
  final Map<String, int> unmarked;

  /// Elements moved to the appendix per kind.
  final Map<String, int> appended;

  /// Review marks that went with a dropped element.
  final int marksDropped;

  /// The readable header line.
  final String readableHeader;

  /// The `.readable.md`: the stripped document rendered with the header, the
  /// heading divs when asked and the appendix; null without a model.
  final String? readable;

  /// Why the output is not valid; empty when it is.
  final List<SpecStripFinding> findings;

  /// Whether the stripped document is valid and may be written.
  bool get ok => findings.isEmpty;

  /// The report: what was dropped, unmarked, moved and kept per kind.
  List<String> get report => [
    for (final k in specStripKindNames)
      if ((dropped[k] ?? 0) + (unmarked[k] ?? 0) + (appended[k] ?? 0) > 0)
        '$k: ${dropped[k] ?? 0} dropped, ${unmarked[k] ?? 0} unmarked, '
            '${appended[k] ?? 0} moved',
    if (marksDropped > 0) 'review marks inside dropped elements: $marksDropped',
    for (final k in kept) '$k',
  ];
}

/// Stripping a whole document (SOM §11.10).
abstract final class SpecDocumentStrip {
  /// Strips every value of [document] — content, form-field values, scalar
  /// list items and stored headlines — with [options], into a copy.
  ///
  /// Given [model], it also applies the emptying rule (a value whose removal
  /// would add a finding of the instance tier or, with [schema], the DocSpecs
  /// tier keeps its prose unmarked and is reported in
  /// [SpecStripResult.kept]); removes a list item left with nothing in it;
  /// numbers the appendix through the rendition; renders the `.readable.md`
  /// of [rootType] (else the single populated root) with the readable header
  /// for [source]; and checks the output: no new finding on any tier and
  /// `parse(readable)` staging exactly the stripped values. Without a model
  /// none of these run and [SpecStripResult.readable] is null.
  static SpecStripResult strip(
    SpecDocument document,
    SpecStripOptions options, {
    SpecModel? model,
    DocSpecsSchema? schema,
    String? rootType,
    String? fileStem,
    Map<String, String> documentFiles = const {},
    SpecReadableSource? source,
  }) {
    final refs = _valueRefs(document);
    final findings = <SpecStripFinding>[];
    final plans = <SpecStripValueRef, _Plan>{};
    for (final ref in refs) {
      final text = ref.read(document);
      if (text.isEmpty) continue;
      final plan = _Plan(text, options);
      if (plan.findings.isNotEmpty) {
        for (final f in plan.findings) {
          findings.add(SpecStripFinding('notation', '$f', ref: ref));
        }
        continue;
      }
      if (plan.changes) plans[ref] = plan;
    }

    final copy = SpecDocument()..loadJson(document.toJson());
    final provisional = <(SpecStripValueRef, int), int>{};
    var next = 1;
    for (final ref in refs) {
      final plan = plans[ref];
      if (plan == null) continue;
      for (var i = 0; i < plan.entries.length; i++) {
        provisional[(ref, i)] = next++;
      }
    }
    void apply(Map<(SpecStripValueRef, int), int> numbers) {
      for (final e in plans.entries) {
        e.key.write(copy, e.value.finish((i) => numbers[(e.key, i)] ?? 0).text);
      }
    }

    apply(provisional);
    final kept = <SpecStripKept>[];
    final base = model == null
        ? const <String, String>{}
        : _tierFindings(model, schema, rootType, document);
    final removedItems = model == null
        ? const <String>[]
        : _emptyingRule(
            model,
            schema,
            rootType,
            base,
            document,
            copy,
            refs,
            plans,
            kept,
            options,
          );

    // The appendix, numbered through the rendition.
    final entries = <(SpecStripValueRef, int)>[
      for (final ref in refs)
        if (plans[ref] != null)
          for (var i = 0; i < plans[ref]!.entries.length; i++) (ref, i),
    ];
    SpecRoot? root;
    if (model != null) {
      try {
        root = copy.rootToExport(model, rootType: rootType);
      } on StateError catch (e) {
        findings.add(SpecStripFinding('parse', e.message));
      }
    }
    final titles = <String, String>{};
    if (entries.isNotEmpty && model != null && root != null) {
      final map = SpecDocumentMarkdown(
        model,
        copy,
        fileStem: fileStem,
        documentFiles: documentFiles,
      ).exportRootWithMap(root);
      final lines = map.markdown.split('\n');
      final order = <String, int>{};
      for (final e in map.headingPaths.entries) {
        order[e.value] = e.key;
        titles[e.value] = _headingTitle(lines[e.key - 1]);
      }
      int sectionLine(SpecStripValueRef ref) {
        var best = 0, bestLength = -1;
        for (final e in order.entries) {
          final p = e.key;
          if ((ref.path == p || ref.path.startsWith('$p/')) &&
              p.length > bestLength) {
            best = e.value;
            bestLength = p.length;
          }
        }
        return best;
      }

      final position = {for (var i = 0; i < refs.length; i++) refs[i]: i};
      entries.sort((a, b) {
        final c = sectionLine(a.$1).compareTo(sectionLine(b.$1));
        if (c != 0) return c;
        final d = position[a.$1]!.compareTo(position[b.$1]!);
        return d != 0 ? d : a.$2.compareTo(b.$2);
      });
    }
    final numbers = {
      for (var i = 0; i < entries.length; i++) entries[i]: i + 1,
    };
    apply(numbers);

    final values = <SpecStrippedValue>[];
    final appendix = <SpecAppendixEntry>[];
    final dropped = <String, int>{},
        unmarked = <String, int>{},
        appended = <String, int>{};
    var marksDropped = 0;
    void add(Map<String, int> into, Map<String, int> from) {
      for (final e in from.entries) {
        into[e.key] = (into[e.key] ?? 0) + e.value;
      }
    }

    for (final ref in refs) {
      final plan = plans[ref];
      if (plan == null) continue;
      final r = plan.finish((i) => numbers[(ref, i)] ?? 0);
      values.add(
        SpecStrippedValue(
          ref: ref,
          original: plan.o,
          stripped: r.text,
          pieces: r.pieces,
        ),
      );
      add(dropped, r.dropped);
      add(unmarked, r.unmarked);
      add(appended, r.appended);
      marksDropped += r.marksDropped;
      for (final e in r.appendix) {
        appendix.add(
          SpecAppendixEntry(
            number: e.number,
            kind: e.kind,
            text: e.text,
            value: ref,
          ),
        );
      }
    }
    appendix.sort((a, b) => a.number.compareTo(b.number));

    final header = SpecReadableHeader(options, source: source).format();
    String? readable;
    if (model != null && root != null) {
      final rendition = SpecDocumentMarkdown(
        model,
        copy,
        fileStem: fileStem,
        documentFiles: documentFiles,
        headingDivs: options.headingDivs,
        readableHeader: header,
      ).exportRootWithMap(root);
      if (titles.isEmpty && appendix.isNotEmpty) {
        final lines = rendition.markdown.split('\n');
        for (final e in rendition.headingPaths.entries) {
          titles[e.value] = _headingTitle(lines[e.key - 1]);
        }
      }
      readable = appendix.isEmpty
          ? rendition.markdown
          : _withAppendix(
              rendition.markdown,
              appendix,
              titles,
              options.appendixReferences,
            );
      _checkOutput(
        model,
        schema,
        root,
        rootType,
        base,
        document,
        copy,
        readable,
        fileStem,
        documentFiles,
        findings,
      );
    }
    return SpecStripResult(
      document: copy,
      values: values,
      kept: kept,
      removedItems: removedItems,
      appendix: appendix,
      dropped: dropped,
      unmarked: unmarked,
      appended: appended,
      marksDropped: marksDropped,
      readableHeader: header,
      readable: readable,
      findings: findings,
    );
  }

  /// Every value of [doc]: headlines, content (scalar list items included),
  /// form fields, each sorted by path, fields by name.
  static List<SpecStripValueRef> _valueRefs(SpecDocument doc) => [
    for (final p in doc.headlinePaths.toList()..sort())
      SpecStripValueRef(p, headline: true),
    for (final p in doc.contentPaths.toList()..sort()) SpecStripValueRef(p),
    for (final p in doc.formPaths.toList()..sort())
      for (final f in doc.formFieldNames(p).toList()..sort())
        SpecStripValueRef(p, field: f),
  ];

  /// The emptying rule: while the copy has a finding the document had not,
  /// the emptied values it concerns keep their prose, unmarked, and the list
  /// items it concerns are not removed. Returns the list items removed: those
  /// the strip left with nothing in them.
  static List<String> _emptyingRule(
    SpecModel model,
    DocSpecsSchema? schema,
    String? rootType,
    Map<String, String> base,
    SpecDocument document,
    SpecDocument copy,
    List<SpecStripValueRef> refs,
    Map<SpecStripValueRef, _Plan> plans,
    List<SpecStripKept> kept,
    SpecStripOptions options,
  ) {
    final keptRefs = <SpecStripValueRef>{};
    final keepItems = <String>{};
    final candidates = _itemsAbove(copy, plans.keys);
    List<String> emptiedItems() => [
      for (final item in candidates)
        if (!keepItems.contains(item) &&
            document.hasValuesUnder(item) &&
            !copy.hasValuesUnder(item))
          item,
    ];
    List<String> finish() {
      final items = emptiedItems();
      for (final item in items) {
        copy.removeListItem(item);
      }
      return items;
    }

    bool concerns(String findingPath, String path) =>
        findingPath.isEmpty ||
        path == findingPath ||
        path.startsWith('$findingPath/') ||
        path.startsWith('$findingPath-') ||
        findingPath.startsWith('$path/');
    for (var round = 0; round < 8; round++) {
      final items = emptiedItems();
      final scratch = items.isEmpty
          ? copy
          : (SpecDocument()..loadJson(copy.toJson()));
      for (final item in items) {
        scratch.removeListItem(item);
      }
      final now = _tierFindings(model, schema, rootType, scratch);
      final added = {
        for (final e in now.entries)
          if (!base.containsKey(e.key)) e.key: e.value,
      };
      if (added.isEmpty) break;
      final emptied = [
        for (final ref in refs)
          if (plans[ref] != null &&
              !keptRefs.contains(ref) &&
              ref.read(copy).trim().isEmpty)
            ref,
      ];
      var changed = false;
      for (final e in added.entries) {
        for (final item in items) {
          if (concerns(e.value, item) && keepItems.add(item)) changed = true;
        }
        for (final ref in emptied) {
          if (keptRefs.contains(ref) || !concerns(e.value, ref.path)) continue;
          keptRefs.add(ref);
          kept.add(SpecStripKept(ref, e.key));
          final keeping = _Plan(plans[ref]!.o, options.keeping);
          final text = keeping.finish((i) => 0).text;
          if (text.trim().isEmpty) {
            plans.remove(ref);
            ref.write(copy, ref.read(document));
          } else {
            plans[ref] = keeping;
            ref.write(copy, text);
          }
          changed = true;
        }
      }
      if (!changed) break;
    }
    return finish();
  }

  /// The list items of [doc] that hold one of [refs] (or are one).
  static List<String> _itemsAbove(
    SpecDocument doc,
    Iterable<SpecStripValueRef> refs,
  ) {
    final items = <String>{
      for (final list in doc.listPaths) ...doc.listItems(list),
    };
    final out = <String>{};
    for (final ref in refs) {
      final p = ref.path;
      if (items.contains(p)) out.add(p);
      for (var i = 0; i < p.length; i++) {
        if (p.codeUnitAt(i) == 0x2f && items.contains(p.substring(0, i))) {
          out.add(p.substring(0, i));
        }
      }
    }
    return out.toList()..sort();
  }

  /// The findings of the instance tier and, with [schema], the DocSpecs tier
  /// of [doc], keyed by what they say, each with the path it is about.
  static Map<String, String> _tierFindings(
    SpecModel model,
    DocSpecsSchema? schema,
    String? rootType,
    SpecDocument doc,
  ) {
    final out = <String, String>{};
    for (final e in validateDocument(model, doc)) {
      out['instance ${e.code.name} ${e.path}: ${e.message}'] = e.path;
    }
    if (schema != null) {
      try {
        for (final v in validateSpecDocument(
          model,
          doc,
          schema,
          rootType: rootType,
        )) {
          out['schema ${v.rule.name} ${v.sectionId ?? ''}: ${v.message}'] =
              v.path ?? '';
        }
      } on StateError {
        // No single root to render: the schema tier cannot judge it.
      }
    }
    return out;
  }

  /// The output checks: the readable rendition parses back to exactly the
  /// stripped values, and no tier finds what it did not find in [document].
  static void _checkOutput(
    SpecModel model,
    DocSpecsSchema? schema,
    SpecRoot root,
    String? rootType,
    Map<String, String> before,
    SpecDocument document,
    SpecDocument copy,
    String readable,
    String? fileStem,
    Map<String, String> documentFiles,
    List<SpecStripFinding> findings,
  ) {
    final parsed = SpecDocumentMarkdown(
      model,
      SpecDocument(),
      fileStem: fileStem,
      documentFiles: documentFiles,
    ).parse(readable);
    for (final r in parsed.rejections) {
      findings.add(SpecStripFinding('parse', 'the rendition rejects: $r'));
    }
    final prefix = root.sectionId ?? root.type;
    bool inRoot(String p) => p == prefix || p.startsWith('$prefix/');
    void compare(
      String what,
      Map<String, String> want,
      Map<String, String> got,
    ) {
      for (final k in {...want.keys, ...got.keys}.toList()..sort()) {
        if (!inRoot(k) || want[k] == got[k]) continue;
        findings.add(
          SpecStripFinding(
            'parse',
            '$what at $k reads back as ${got[k] == null ? 'nothing' : '"${got[k]}"'}'
                ' instead of ${want[k] == null ? 'nothing' : '"${want[k]}"'}',
          ),
        );
      }
    }

    compare('content', {
      for (final p in copy.contentPaths) p: copy.content(p)!,
    }, parsed.content);
    compare(
      'the form field',
      {
        for (final p in copy.formPaths)
          for (final f in copy.formFieldNames(p))
            '$p/$f': copy.formField(p, f)!,
      },
      {
        for (final e in parsed.forms.entries)
          for (final f in e.value.entries) '${e.key}/${f.key}': f.value,
      },
    );
    for (final e in _tierFindings(model, schema, rootType, copy).entries) {
      if (!before.containsKey(e.key)) {
        findings.add(
          SpecStripFinding(
            e.key.startsWith('schema') ? 'schema' : 'instance',
            e.key,
          ),
        );
      }
    }
    if (schema != null) {
      final original = SpecDocumentMarkdown(
        model,
        document,
        fileStem: fileStem,
        documentFiles: documentFiles,
      ).exportRoot(root);
      String key(DocSpecsViolation v) =>
          '${v.rule.name} ${v.sectionId ?? ''}: ${v.message}';
      final had = {
        for (final v in DocSpecsValidator(
          schema,
          tomSpecs: true,
        ).validateMarkdown(original))
          key(v),
      };
      for (final v in DocSpecsValidator(
        schema,
        tomSpecs: true,
      ).validateMarkdown(readable)) {
        if (!had.contains(key(v))) {
          findings.add(
            SpecStripFinding(
              'schema',
              'the rendition: line ${v.line}: ${key(v)}',
            ),
          );
        }
      }
    }
  }

  /// The title of a heading line as the codec writes it.
  static String _headingTitle(String line) {
    final div = SpecDocumentMarkdown.headingDiv(line);
    final rest = div != null
        ? div.$2
        : (SpecDocumentMarkdown.headingLine.firstMatch(line)?.group(2) ?? line);
    final c = SpecDocumentMarkdown.headlineComment.firstMatch(rest.trim());
    final title = c == null ? rest.trim() : c.group(3)!.trim();
    return DocSpecsDocument.stripOwnAnchor(title, c?.group(1) ?? '');
  }

  /// [markdown] followed by the appendix *Notes*: after the marker, each
  /// entry under the title of the section it came from.
  static String _withAppendix(
    String markdown,
    List<SpecAppendixEntry> entries,
    Map<String, String> titles,
    bool references,
  ) {
    /// The section [ref] stands in: its path and title.
    (String, String) sectionOf(SpecStripValueRef ref) {
      var best = '', title = ref.path;
      for (final e in titles.entries) {
        if ((ref.path == e.key || ref.path.startsWith('${e.key}/')) &&
            e.key.length > best.length) {
          best = e.key;
          title = e.value;
        }
      }
      return (best.isEmpty ? ref.path : best, title);
    }

    final b = StringBuffer(markdown.replaceAll(RegExp(r'\n+$'), ''))
      ..write('\n\n${SpecDocumentMarkdown.appendixMarker}\n\n## Notes\n');
    String? section;
    for (final e in entries) {
      final (path, title) = e.value == null ? ('', '') : sectionOf(e.value!);
      if (path != section) {
        b.write('\n### $title\n');
        section = path;
      }
      final text = [
        for (final l in e.text.split('\n')) l.startsWith('#') ? '\\$l' : l,
      ].join('\n');
      b.write(
        references
            ? '\n<a id="note-${e.number}"></a>**[${e.number}]** $text '
                  '[↩](#note-${e.number}-ref)\n'
            : '\n**[${e.number}]** $text\n',
      );
    }
    return b.toString();
  }
}

// ---------------------------------------------------------------------------
// One value's strip.

/// An insertion into the text after the comments step: literal [text], or
/// the reference to appendix entry [entry] (resolved when numbered).
class _Insert {
  const _Insert(this.label, {this.text, this.entry});
  final String label;
  final String? text;
  final int? entry;
}

/// An appendix entry before numbering.
class _Entry {
  const _Entry(this.kind, this.text);
  final String kind;
  final String text;
}

/// One step of an edit script: keep, delete or insert a code unit.
class _Op {
  const _Op(this.type, this.char, [this.label]);
  static const keep = 0, del = 1, ins = 2;
  final int type;
  final String char;
  final String? label;
}

/// The strip of one value, planned once and finished for any numbering.
class _Plan {
  _Plan(this.o, this.options) {
    findings = [
      for (final f in scanNotation(o, tomSpecs: true).findings)
        if (f.severity == NotationSeverity.error &&
            f.code != NotationFindingCode.rejectedBlock)
          f,
    ];
    if (findings.isNotEmpty) {
      t = o;
      del = List<String?>.filled(o.length, null);
      return;
    }
    if (options.drop.contains('comments')) {
      t = stripAnnotationsText(o);
      if (t != o) {
        final c = countAnnotationsText(o);
        dropped['comments'] = c;
        script1 = _diff(o, t, 'comments');
      }
    } else {
      t = o;
    }
    del = List<String?>.filled(t.length, null);
    blockDel = List<bool>.filled(t.length, false);
    _process(scanNotation(t, tomSpecs: true).elements);
    if (!options.drop.contains('comments')) _marks();
    if (del.any((d) => d != null)) _normalise();
  }

  /// The original value.
  final String o;
  final SpecStripOptions options;

  /// The value after the comments step.
  late final String t;

  /// The edit script from [o] to [t]; null when they are equal.
  List<_Op>? script1;

  /// Per code unit of [t]: what deletes it, or null to keep it.
  late final List<String?> del;

  /// Per code unit of [t]: deleted as part of a whole line of a div.
  late final List<bool> blockDel;

  /// Insertions before an offset of [t].
  final Map<int, List<_Insert>> ins = {};

  final Map<String, int> dropped = {}, unmarked = {}, appended = {};
  int marksDropped = 0;
  final List<_Entry> entries = [];
  late final List<NotationFinding> findings;

  /// Whether the strip changes the value.
  bool get changes =>
      findings.isEmpty &&
      (script1 != null || del.any((d) => d != null) || ins.isNotEmpty);

  static bool _space(String c) => c == ' ' || c == '\t';

  void _mark(int s, int e, String label, {bool block = false}) {
    for (var i = s; i < e && i < t.length; i++) {
      del[i] ??= label;
      if (block) blockDel[i] = true;
    }
  }

  void _insert(int at, _Insert i) => (ins[at] ??= []).add(i);

  void _count(Map<String, int> m, String k) => m[k] = (m[k] ?? 0) + 1;

  void _process(List<NotationElement> list) {
    for (final e in list) {
      final k = e.kind;
      final secondary =
          e.isRegistered && k != null && specStripNotationKinds.contains(k);
      if (!secondary) {
        _process(e.children);
        continue;
      }
      if (options.drop.contains(k)) {
        _remove(e, '$k:drop');
        _count(dropped, k);
        continue;
      }
      if (options.appendix.contains(k)) {
        final content = e.type == NotationElementType.citation
            ? t.substring(e.start, e.end)
            : t
                  .substring(e.contentStart, e.contentEnd)
                  .replaceAll(RegExp(r'\n+$'), '');
        entries.add(
          _Entry(k, stripNotationText(content, options._inEntry).text),
        );
        _remove(e, '$k:appendix', entry: entries.length - 1);
        _count(appended, k);
        continue;
      }
      if (options.unmark.contains(k)) {
        _unmark(e, '$k:unmark');
        _count(unmarked, k);
      }
      _process(e.children);
    }
  }

  /// Removes [e] whole; a moved element leaves its reference with
  /// [SpecStripOptions.appendixReferences].
  void _remove(NotationElement e, String label, {int? entry}) {
    final reference = entry != null && options.appendixReferences;
    if (e.type == NotationElementType.div) {
      _mark(e.start, e.end, label, block: true);
      if (reference) _insert(e.start, _Insert(label, entry: entry));
      return;
    }
    final s = e.start;
    if (s > 0 && _space(t[s - 1]) && del[s - 1] == null) {
      del[s - 1] = label;
    } else if (!reference &&
        (s == 0 || t[s - 1] == '\n') &&
        e.end < t.length &&
        _space(t[e.end])) {
      del[e.end] = label;
    }
    _mark(e.start, e.end, label);
    if (reference) _insert(e.start, _Insert(label, entry: entry));
  }

  /// Removes [e]'s markers and keeps its content.
  void _unmark(NotationElement e, String label) {
    switch (e.type) {
      case NotationElementType.div:
        if (e.contentStart >= e.contentEnd) {
          _mark(e.start, e.end, label, block: true);
        } else {
          _mark(e.start, e.contentStart, label, block: true);
          _mark(e.contentEnd - 1, e.end, label, block: true);
        }
      case NotationElementType.span:
        _mark(e.start, e.start + 1, label);
        _mark(e.contentEnd, e.end, label);
      case NotationElementType.citation:
        _mark(e.start + 1, e.contentStart, label);
    }
  }

  /// The review marks around and inside removed elements, when comments stay:
  /// a mark wholly inside a removed element went with it (counted); a mark a
  /// removal emptied goes; a substitution that lost one side becomes the
  /// insertion or deletion of the side that remains.
  void _marks() {
    for (final m in _findMarks(t)) {
      if (_allDeleted(m.start, m.end)) {
        marksDropped++;
        continue;
      }
      if (m.sep < 0) {
        if (_hadText(m.bodyStart, m.bodyEnd) &&
            !_survives(m.bodyStart, m.bodyEnd)) {
          _removeMark(m);
        }
        continue;
      }
      final oldHad = _hadText(m.bodyStart, m.sep);
      final newHad = _hadText(m.sep + 2, m.bodyEnd);
      final oldLeft = _survives(m.bodyStart, m.sep);
      final newLeft = _survives(m.sep + 2, m.bodyEnd);
      if (!oldLeft && !newLeft && (oldHad || newHad)) {
        _removeMark(m);
      } else if (oldHad && !oldLeft) {
        _convert(m, '++', m.bodyStart, m.sep + 2);
      } else if (newHad && !newLeft) {
        _convert(m, '--', m.sep, m.bodyEnd);
      }
    }
  }

  /// Removes mark [m] whole, with the space before it as a span's.
  void _removeMark(_MarkAt m) {
    final s = m.start;
    if (s > 0 && _space(t[s - 1]) && del[s - 1] == null) {
      del[s - 1] = 'mark';
    } else if ((s == 0 || t[s - 1] == '\n') &&
        m.end < t.length &&
        _space(t[m.end])) {
      del[m.end] = 'mark';
    }
    _mark(m.start, m.end, 'mark');
  }

  /// Rewrites substitution [m] as a mark with [delimiter], removing
  /// `[s, e)` (the lost side and the arrow).
  void _convert(_MarkAt m, String delimiter, int s, int e) {
    _mark(m.start + 1, m.start + 3, 'mark');
    _insert(m.start + 3, _Insert('mark', text: delimiter));
    _mark(s, e, 'mark');
    _mark(m.end - 3, m.end - 1, 'mark');
    _insert(m.end - 1, _Insert('mark', text: delimiter));
  }

  bool _allDeleted(int s, int e) {
    for (var i = s; i < e; i++) {
      if (del[i] == null) return false;
    }
    return true;
  }

  bool _hadText(int s, int e) => t.substring(s, e).trim().isNotEmpty;

  bool _survives(int s, int e) {
    for (var i = s; i < e; i++) {
      if (del[i] == null && t[i].trim().isNotEmpty) return true;
    }
    return false;
  }

  /// The whitespace removals leave: a line a span removal emptied goes with
  /// its line break; blank lines around a removal collapse to one, and none
  /// is left at the start or end of the value.
  void _normalise() {
    final starts = <int>[0];
    for (var i = 0; i < t.length; i++) {
      if (t[i] == '\n') starts.add(i + 1);
    }
    for (var l = 0; l < starts.length; l++) {
      final s = starts[l];
      final e = l + 1 < starts.length ? starts[l + 1] - 1 : t.length;
      if (t.substring(s, e).trim().isEmpty) continue;
      var touched = false, survives = false, allBlock = true;
      for (var i = s; i < e; i++) {
        if (del[i] != null) {
          touched = true;
        } else if (t[i].trim().isNotEmpty) {
          survives = true;
        }
        if (!blockDel[i]) allBlock = false;
      }
      for (var i = s; i <= e; i++) {
        if (ins.containsKey(i)) survives = true;
      }
      if (!touched || survives || allBlock) continue;
      _mark(s, e, 'whitespace');
      if (e < t.length) {
        del[e] ??= 'whitespace';
      } else if (s > 0) {
        del[s - 1] ??= 'whitespace';
      }
    }
    // Blank-line runs, read on the text as it now stands.
    final kept = <int>[]; // offsets of t kept, in order
    final text = StringBuffer();
    for (var i = 0; i <= t.length; i++) {
      for (final x in ins[i] ?? const <_Insert>[]) {
        final s = x.text ?? 'x'; // a reference is never blank
        for (var k = 0; k < s.length; k++) {
          kept.add(-1);
        }
        text.write(s);
      }
      if (i < t.length && del[i] == null) {
        kept.add(i);
        text.write(t[i]);
      }
    }
    final b = text.toString();
    var firstSolid = 0;
    while (firstSolid < b.length && b[firstSolid].trim().isEmpty) {
      firstSolid++;
    }
    if (firstSolid == b.length) {
      for (final i in kept) {
        if (i >= 0) del[i] ??= 'whitespace';
      }
      return;
    }
    var lastSolid = b.length - 1;
    while (b[lastSolid].trim().isEmpty) {
      lastSolid--;
    }
    // Leading and trailing blank lines (and the spaces on them) go.
    final lead = b.lastIndexOf('\n', firstSolid);
    for (var k = 0; k <= lead; k++) {
      if (kept[k] >= 0) del[kept[k]] ??= 'whitespace';
    }
    final trail = b.indexOf('\n', lastSolid);
    if (trail >= 0) {
      for (var k = trail; k < b.length; k++) {
        if (kept[k] >= 0) del[kept[k]] ??= 'whitespace';
      }
    }
    // Inner runs: between two solid characters, more than two line breaks at
    // a removal collapse to two.
    var k = firstSolid;
    while (k < lastSolid) {
      if (b[k].trim().isNotEmpty) {
        k++;
        continue;
      }
      final runStart = k;
      while (b[k].trim().isEmpty) {
        k++;
      }
      final runEnd = k; // b[runEnd] is solid
      final breaks = [
        for (var j = runStart; j < runEnd; j++)
          if (b[j] == '\n') j,
      ];
      if (breaks.length <= 2) continue;
      final from = kept[runStart - 1], to = kept[runEnd];
      var atRemoval = false;
      if (from >= 0 && to >= 0) {
        for (var i = from + 1; i < to; i++) {
          if (del[i] != null && del[i] != 'whitespace') atRemoval = true;
        }
      } else {
        atRemoval = true;
      }
      if (!atRemoval) continue;
      // Keep the first line break and the last; the lines between go.
      for (var j = breaks.first + 1; j <= breaks.last - 1; j++) {
        if (kept[j] >= 0) del[kept[j]] ??= 'whitespace';
      }
    }
  }

  /// The value for [number] (the entry index → its number), with its pieces
  /// and counts.
  SpecStripTextResult finish(int Function(int entry) number) {
    if (findings.isNotEmpty) {
      return SpecStripTextResult(
        text: o,
        pieces: const [],
        dropped: const {},
        unmarked: const {},
        appended: const {},
        marksDropped: 0,
        appendix: const [],
        findings: findings,
      );
    }
    String insertText(_Insert x) {
      if (x.text != null) return x.text!;
      final n = number(x.entry!);
      return '<a id="note-$n-ref"></a>[\\[$n\\]](#note-$n)';
    }

    final script2 = <_Op>[];
    for (var i = 0; i <= t.length; i++) {
      for (final x in ins[i] ?? const <_Insert>[]) {
        final s = insertText(x);
        for (var k = 0; k < s.length; k++) {
          script2.add(_Op(_Op.ins, s[k], x.label));
        }
      }
      if (i < t.length) {
        script2.add(
          del[i] == null ? _Op(_Op.keep, t[i]) : _Op(_Op.del, t[i], del[i]),
        );
      }
    }
    final ops = script1 == null ? script2 : _compose(script1!, script2);
    final out = StringBuffer();
    final pieces = <SpecStripPiece>[];
    var oPos = 0, bPos = 0;
    var i = 0;
    while (i < ops.length) {
      if (ops[i].type == _Op.keep) {
        out.write(ops[i].char);
        oPos++;
        bPos++;
        i++;
        continue;
      }
      final anchor = bPos, origin = oPos;
      final removed = StringBuffer(), inserted = StringBuffer();
      final labels = <String>{};
      while (i < ops.length && ops[i].type != _Op.keep) {
        final op = ops[i];
        if (op.label != null) labels.add(op.label!);
        if (op.type == _Op.del) {
          removed.write(op.char);
          oPos++;
        } else {
          inserted.write(op.char);
          out.write(op.char);
          bPos++;
        }
        i++;
      }
      pieces.add(
        SpecStripPiece(
          anchor: anchor,
          origin: origin,
          removed: removed.toString(),
          inserted: inserted.toString(),
          labels: labels.toList()..sort(),
        ),
      );
    }
    return SpecStripTextResult(
      text: out.toString(),
      pieces: pieces,
      dropped: Map.of(dropped),
      unmarked: Map.of(unmarked),
      appended: Map.of(appended),
      marksDropped: marksDropped,
      appendix: [
        for (var k = 0; k < entries.length; k++)
          SpecAppendixEntry(
            number: number(k),
            kind: entries[k].kind,
            text: entries[k].text,
          ),
      ],
      findings: const [],
    );
  }
}

/// The edit script from [o] to [b] after [a] → [o] … composed: [s1] takes the
/// original to the middle text, [s2] the middle text to the result.
List<_Op> _compose(List<_Op> s1, List<_Op> s2) {
  final out = <_Op>[];
  var j = 0;
  void flushInserts() {
    while (j < s2.length && s2[j].type == _Op.ins) {
      out.add(s2[j++]);
    }
  }

  for (final a in s1) {
    if (a.type == _Op.del) {
      out.add(a);
      continue;
    }
    flushInserts();
    final b = s2[j++];
    if (a.type == _Op.keep) {
      out.add(b.type == _Op.keep ? a : _Op(_Op.del, a.char, b.label));
    } else if (b.type == _Op.keep) {
      out.add(a);
    }
  }
  flushInserts();
  return out;
}

/// An edit script from [a] to [b], each change labelled [label]: Myers'
/// O(ND) diff by line, then, inside each run of changed lines, by word token
/// (a run of letters and digits, a run of whitespace, any other single code
/// unit), so a piece starts and ends at a token boundary. A run that differs
/// in more than 2000 edits is one deletion and one insertion.
List<_Op> _diff(String a, String b, String label) {
  final out = <_Op>[];
  void chars(int type, String s) {
    for (var k = 0; k < s.length; k++) {
      out.add(_Op(type, s[k], type == _Op.keep ? null : label));
    }
  }

  final deleted = StringBuffer(), inserted = StringBuffer();
  void flush() {
    if (deleted.isEmpty && inserted.isEmpty) return;
    for (final (type, token) in _myers(
      _tokens(deleted.toString()),
      _tokens(inserted.toString()),
    )) {
      chars(type, token);
    }
    deleted.clear();
    inserted.clear();
  }

  for (final (type, line) in _myers(_lines(a), _lines(b))) {
    switch (type) {
      case _Op.keep:
        flush();
        chars(_Op.keep, line);
      case _Op.del:
        deleted.write(line);
      default:
        inserted.write(line);
    }
  }
  flush();
  return out;
}

/// [s] as lines, each with its line break.
List<String> _lines(String s) {
  final out = <String>[];
  var i = 0;
  while (i < s.length) {
    final n = s.indexOf('\n', i);
    final e = n < 0 ? s.length : n + 1;
    out.add(s.substring(i, e));
    i = e;
  }
  return out;
}

/// The token kind of code unit [c]: 1 a word character (ASCII letter, digit,
/// `_`, or any code unit from U+0080 that is not whitespace), 2 whitespace,
/// 0 anything else.
int _tokenKind(int c) {
  if (c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D) return 2;
  if ((c >= 0x30 && c <= 0x39) ||
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      c == 0x5F ||
      c >= 0x80) {
    return 1;
  }
  return 0;
}

/// [s] as word tokens.
List<String> _tokens(String s) {
  final out = <String>[];
  var i = 0;
  while (i < s.length) {
    final k = _tokenKind(s.codeUnitAt(i));
    var j = i + 1;
    if (k != 0) {
      while (j < s.length && _tokenKind(s.codeUnitAt(j)) == k) {
        j++;
      }
    }
    out.add(s.substring(i, j));
    i = j;
  }
  return out;
}

/// Myers' diff of token lists [a] and [b]: (op type, token) in order.
List<(int, String)> _myers(List<String> a, List<String> b) {
  final n = a.length, m = b.length;
  final max = n + m;
  if (max == 0) return const [];
  const cap = 2000;
  final off = max + 1;
  final v = Int32List(2 * max + 3);
  final trace = <Int32List>[];
  var found = -1;
  for (var d = 0; d <= max && d <= cap; d++) {
    // Before step d: the window k in [-(d-1), d-1].
    if (d > 0) {
      final snap = Int32List(2 * d - 1);
      for (var k = -(d - 1); k <= d - 1; k++) {
        snap[k + d - 1] = v[k + off];
      }
      trace.add(snap);
    }
    for (var k = -d; k <= d; k += 2) {
      var x = (k == -d || (k != d && v[k - 1 + off] < v[k + 1 + off]))
          ? v[k + 1 + off]
          : v[k - 1 + off] + 1;
      var y = x - k;
      while (x < n && y < m && a[x] == b[y]) {
        x++;
        y++;
      }
      v[k + off] = x;
      if (x >= n && y >= m) {
        found = d;
        break;
      }
    }
    if (found >= 0) break;
  }
  if (found < 0) {
    return [for (final t in a) (_Op.del, t), for (final t in b) (_Op.ins, t)];
  }
  final rev = <(int, String)>[];
  var x = n, y = m;
  for (var d = found; d > 0; d--) {
    final snap = trace[d - 1];
    int at(int k) => snap[k + d - 1];
    final k = x - y;
    final prevK = (k == -d || (k != d && at(k - 1) < at(k + 1)))
        ? k + 1
        : k - 1;
    final prevX = at(prevK);
    final prevY = prevX - prevK;
    while (x > prevX && y > prevY) {
      rev.add((_Op.keep, a[x - 1]));
      x--;
      y--;
    }
    if (x == prevX) {
      rev.add((_Op.ins, b[y - 1]));
    } else {
      rev.add((_Op.del, a[x - 1]));
    }
    x = prevX;
    y = prevY;
  }
  while (x > 0 && y > 0) {
    rev.add((_Op.keep, a[x - 1]));
    x--;
    y--;
  }
  return rev.reversed.toList();
}

/// A review mark in a text: `[start, end)`, its body `[bodyStart, bodyEnd)`
/// and, for a substitution, the offset of its `~>` ([sep], else -1).
class _MarkAt {
  const _MarkAt(this.start, this.end, this.bodyStart, this.bodyEnd, this.sep);
  final int start, end, bodyStart, bodyEnd, sep;
}

const Map<String, String> _markClose = {
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
  '{==': '==}',
  '{>>': '<<}',
};

/// The review marks of [t] outside code (SOM §11.9.3): an opener, then its
/// closer before the paragraph ends.
List<_MarkAt> _findMarks(String t) {
  final code = List<bool>.filled(t.length, false);
  final fence = MarkdownFenceTracker();
  var s = 0;
  for (final line in t.split('\n')) {
    final inFence = fence.inFence;
    fence.feed(line);
    if (inFence || fence.inFence) {
      for (var i = s; i < s + line.length; i++) {
        code[i] = true;
      }
    } else {
      // Inline code spans: a backtick run up to the next run of its length.
      var i = 0;
      while (i < line.length) {
        if (line[i] != '`') {
          i++;
          continue;
        }
        var j = i;
        while (j < line.length && line[j] == '`') {
          j++;
        }
        final ticks = line.substring(i, j);
        final close = line.indexOf(ticks, j);
        if (close < 0) {
          i = j;
          continue;
        }
        for (var k = s + i; k < s + close + ticks.length; k++) {
          code[k] = true;
        }
        i = close + ticks.length;
      }
    }
    s += line.length + 1;
  }
  final out = <_MarkAt>[];
  var i = 0;
  while (i + 3 <= t.length) {
    final opener = t.substring(i, i + 3);
    final closer = _markClose[opener];
    if (closer == null || code[i]) {
      i++;
      continue;
    }
    final paragraphEnd = RegExp(r'\n[ \t]*\n').firstMatch(t.substring(i));
    final limit = paragraphEnd == null ? t.length : i + paragraphEnd.start;
    final close = t.indexOf(closer, i + 3);
    if (close < 0 || close + 3 > limit) {
      i++;
      continue;
    }
    var sep = -1;
    if (opener == '{~~') {
      sep = t.indexOf('~>', i + 3);
      if (sep < 0 || sep >= close) {
        i++;
        continue;
      }
    }
    out.add(_MarkAt(i, close + 3, i + 3, close, sep));
    i = close + 3;
  }
  return out;
}
