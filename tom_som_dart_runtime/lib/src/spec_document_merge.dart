// The merge back (SOM §11.10; the reading view's part *Stripped renditions
// and the merge back*): an edited readable rendition merged onto the
// document of record, every piece the strip removed put back.
part of 'spec_document_strip.dart';

/// A piece put back after an edited run rather than between unchanged
/// neighbours: an author confirms or moves it (`PLACED <value> — check`).
class SpecStripMergePlaced {
  /// [piece], put back at [at] in the merged text.
  const SpecStripMergePlaced(this.piece, this.at);

  /// The piece.
  final SpecStripPiece piece;

  /// The offset in the merged value the piece's text starts at.
  final int at;

  /// The placement as the conformance corpus writes it.
  Map<String, Object?> toJson() => {'at': at, 'removed': piece.removed};
}

/// Why a value, or the whole merge, cannot be merged.
///
/// The [code]s: `crossesBoundary` (an edit crosses the start or end of an
/// unmarked element, or the gap between two), `sentenceRemoved` (the edit
/// removed the whole sentence holding a span's gap), `stripTextEdited` (the
/// reader changed text the strip wrote in a piece's place), `unplaceable`
/// (a block whose place in the edited text is no line boundary),
/// `notation` / `annotations` (the merged value has findings neither the
/// original nor the edited text has), `changedBothSides` (the value changed
/// in the original since the export and in the rendition),
/// `notStrippedBack` (stripping the merged value does not give the edited
/// text) and `newFinding` (the merged document has a finding of a tier the
/// original has not).
class SpecStripMergeConflict {
  /// A conflict.
  const SpecStripMergeConflict({
    required this.code,
    required this.message,
    this.ref,
    this.piece,
    this.excerptO = '',
    this.excerptB = '',
    this.excerptE = '',
  });

  /// What kind of conflict; see the class comment.
  final String code;

  /// The conflict in words.
  final String message;

  /// The value, when the conflict is about one.
  final SpecStripValueRef? ref;

  /// The piece that could not be placed, when one is concerned.
  final SpecStripPiece? piece;

  /// The original (O), the stripped baseline (B) and the edited text (E)
  /// around the place concerned; empty when not about one place.
  final String excerptO, excerptB, excerptE;

  /// The conflict about value [value].
  SpecStripMergeConflict about(SpecStripValueRef value) =>
      SpecStripMergeConflict(
        code: code,
        message: message,
        ref: value,
        piece: piece,
        excerptO: excerptO,
        excerptB: excerptB,
        excerptE: excerptE,
      );

  /// The report lines: `CONFLICT <value> — <reason>`, then the three
  /// excerpts and the piece.
  List<String> get reportLines => [
    'CONFLICT ${ref == null ? '(document)' : specStripMergeLabel(ref!)} — $message',
    if (piece != null || excerptB.isNotEmpty) ...[
      '  O: $excerptO',
      '  B: $excerptB',
      '  E: $excerptE',
    ],
    if (piece != null) '  piece: ${_visible(piece!.removed)}',
  ];

  /// The conflict as the conformance corpus writes it.
  Map<String, Object?> toJson() => {
    'code': code,
    if (ref != null) 'value': ref!.toJson(),
    if (piece != null) 'removed': piece!.removed,
  };
}

/// The result of [mergeStrippedValue].
class SpecStripValueMerge {
  /// A result.
  const SpecStripValueMerge({
    required this.text,
    required this.restored,
    required this.placed,
    required this.conflicts,
  });

  /// The merged value; null when there are [conflicts].
  final String? text;

  /// How many pieces were put back.
  final int restored;

  /// The pieces put back after an edited run, to be checked.
  final List<SpecStripMergePlaced> placed;

  /// Why the value cannot be merged; empty when it can.
  final List<SpecStripMergeConflict> conflicts;

  /// Whether the value merged.
  bool get ok => conflicts.isEmpty;

  /// The result as the conformance corpus writes it.
  Map<String, Object?> toJson() => {
    'text': text,
    'restored': restored,
    'placed': [for (final p in placed) p.toJson()],
    'conflicts': [for (final c in conflicts) c.toJson()],
  };
}

/// The name of value [ref] in a merge report: `<path>`, `<path> / <field>`
/// or `<path> (headline)`.
String specStripMergeLabel(SpecStripValueRef ref) => ref.headline
    ? '${ref.path} (headline)'
    : ref.field != null
    ? '${ref.path} / ${ref.field}'
    : ref.path;

/// Merges the edited text [e] of one value back onto its original [o]
/// (SOM §11.10): [b] is [o] stripped and [pieces] what the strip removed,
/// anchored in [b] ([SpecStrippedValue.pieces]).
///
/// When [e] equals [b] the result is [o], byte for byte. Otherwise [b] is
/// diffed against [e] (by line, then by word inside changed lines) and each
/// piece goes back where the diff moves its anchor:
///
/// - where both neighbouring characters of its gap are unchanged, exactly
///   there;
/// - a block (a removed div or comment block, rotated to a line start) goes
///   back between the same paragraphs; before a paragraph the reader removed
///   it goes after the preceding one, else at the start of the value;
/// - an unmarked element's markers (and an accepted mark's delimiters) wrap
///   their mapped range again, any edit inside it included; an edit across
///   the range's start or end is a `crossesBoundary` conflict;
/// - any other span or mark goes after the edited run and is listed in
///   [SpecStripValueMerge.placed], a `sentenceRemoved` conflict when the
///   edit removed the whole sentence holding its gap;
/// - a piece with text in its place (a converted mark's delimiters, an
///   appendix reference) is replaced only when that text is unchanged;
/// - whitespace a strip normalised away is not put back next to an edit.
///
/// A merged value with notation or annotation findings that neither [o] nor
/// [e] has is a conflict.
SpecStripValueMerge mergeStrippedValue(
  String o,
  String b,
  String e,
  List<SpecStripPiece> pieces,
) {
  if (e == b) {
    return SpecStripValueMerge(
      text: o,
      restored: pieces.length,
      placed: const [],
      conflicts: const [],
    );
  }
  final roles = _pieceRoles(o, pieces);
  final ops = _diff(b, e, 'edit');
  final map = _EditMap(ops, b.length);
  // An opening marker is judged on the script whose whitespace edits trail
  // their run, a closing one on the script whose whitespace edits lead it:
  // `quick brown fox` to `quick fox` deletes `brown ` or ` brown` alike, and
  // only one of the two keeps the edit off the marker's outer side.
  final trailing = _EditMap(_slide(ops, leading: false), b.length);
  final leading = _EditMap(_slide(ops, leading: true), b.length);
  _LineEditMap? lines;
  final puts = <_Put>[];
  final placedAt = <int, SpecStripPiece>{};
  final conflicts = <SpecStripMergeConflict>[];
  var restored = 0;
  for (var i = 0; i < pieces.length; i++) {
    final p = pieces[i];
    SpecStripMergeConflict conflict(String code, String message, int eAt) =>
        SpecStripMergeConflict(
          code: code,
          message: message,
          piece: p,
          excerptO: _excerpt(o, p.origin),
          excerptB: _excerpt(b, p.anchor),
          excerptE: _excerpt(e, eAt),
        );

    if (p.inserted.isNotEmpty) {
      final at = map.keptRange(p.anchor, p.anchor + p.inserted.length);
      if (at < 0) {
        conflicts.add(
          conflict(
            'stripTextEdited',
            'the text the strip wrote in place of a piece was edited',
            map.gap(p.anchor).start,
          ),
        );
        continue;
      }
      puts.add(_Put(at, i, p.removed, replace: p.inserted.length));
      restored++;
      continue;
    }

    final role = roles[i];
    var g = p.anchor;
    var text = p.removed;
    if (role == _roleWhole && text.contains('\n')) {
      while (g > 0 && b[g - 1] != '\n' && g < b.length && text[0] == b[g]) {
        text = text.substring(1) + text[0];
        g++;
      }
      if (g == 0 || b[g - 1] == '\n' || g == b.length) {
        lines ??= _LineEditMap(b, e);
        final k = _lineIndex(b, g);
        final gap = lines.gap(k);
        if (gap.unchanged) {
          puts.add(_Put(gap.at, i, text));
          restored++;
          continue;
        }
        final at = !gap.leftEdited
            ? gap.start
            : !gap.rightEdited
            ? gap.end
            : lines.paragraphPlace(gap, k);
        if (at > 0 && at < e.length && e[at - 1] != '\n') {
          conflicts.add(
            conflict(
              'unplaceable',
              'the block has no line boundary to go back to',
              at,
            ),
          );
          continue;
        }
        // The block keeps the distance it had from the text around it in the
        // original: a blank line, or none when it stood right against a line.
        final core = p.origin + _leadingBreaks(p.removed);
        final coreEnd =
            p.origin + p.removed.length - _trailingBreaks(p.removed);
        int distance(int breaks, bool edge) =>
            edge ? 2 : math.min(2, math.max(1, breaks));
        puts.add(
          _Put(
            at,
            i,
            text,
            normalize: true,
            before: distance(_trailingBreaks(o.substring(0, core)), core == 0),
            after: distance(
              _leadingBreaks(o.substring(coreEnd)),
              coreEnd >= o.length,
            ),
          ),
        );
        restored++;
        continue;
      }
      g = p.anchor;
      text = p.removed;
    }

    final gap =
        (role == _roleOpener
                ? trailing
                : role == _roleCloser
                ? leading
                : map)
            .gap(g);
    if (gap.unchanged) {
      puts.add(_Put(gap.at, i, text));
      restored++;
      continue;
    }
    if (text.trim().isEmpty) continue; // normalised whitespace at an edit
    switch (role) {
      case _roleOpener || _roleCloser:
        if (gap.leftEdited && gap.rightEdited) {
          conflicts.add(
            conflict(
              'crossesBoundary',
              'an edit crosses the boundary of an unmarked element',
              gap.start,
            ),
          );
          continue;
        }
        // The edit on the inner side of the marker goes inside the element.
        final at = role == _roleOpener
            ? (!gap.leftEdited ? gap.start : gap.end)
            : (!gap.rightEdited ? gap.end : gap.start);
        puts.add(_Put(at, i, text));
        restored++;
      case _roleBoth:
        conflicts.add(
          conflict(
            'crossesBoundary',
            'an edit touches the boundary between two unmarked elements',
            gap.start,
          ),
        );
      default:
        if (_sentenceRemoved(b, g, map)) {
          conflicts.add(
            conflict(
              'sentenceRemoved',
              'the edit removed the whole sentence holding the piece',
              gap.start,
            ),
          );
          continue;
        }
        puts.add(_Put(gap.end, i, text));
        placedAt[i] = p;
        restored++;
    }
  }
  if (conflicts.isNotEmpty) {
    return SpecStripValueMerge(
      text: null,
      restored: 0,
      placed: const [],
      conflicts: conflicts,
    );
  }

  puts.sort((x, y) => x.at != y.at ? x.at - y.at : x.order - y.order);
  final out = StringBuffer();
  final placed = <SpecStripMergePlaced>[];
  var pos = 0;
  for (final put in puts) {
    if (put.at < pos) {
      conflicts.add(
        SpecStripMergeConflict(
          code: 'stripTextEdited',
          message: 'two pieces claim the same text',
          piece: pieces[put.order],
        ),
      );
      continue;
    }
    out.write(e.substring(pos, put.at));
    pos = put.at;
    if (put.normalize) {
      final core = put.text.replaceAll(RegExp(r'^\n+|\n+$'), '');
      final left = out.toString();
      if (left.isNotEmpty) {
        out.write('\n' * math.max(0, put.before - _trailingBreaks(left)));
      }
      if (placedAt.containsKey(put.order)) {
        placed.add(SpecStripMergePlaced(pieces[put.order], out.length));
      }
      out.write(core);
      final right = e.substring(pos);
      if (right.isNotEmpty) {
        out.write('\n' * math.max(0, put.after - _leadingBreaks(right)));
      }
    } else {
      if (placedAt.containsKey(put.order)) {
        placed.add(SpecStripMergePlaced(pieces[put.order], out.length));
      }
      out.write(put.text);
    }
    pos += put.replace;
  }
  out.write(e.substring(pos));
  final merged = out.toString();

  int notationErrors(String s) => scanNotation(s, tomSpecs: true).findings
      .where(
        (f) =>
            f.severity == NotationSeverity.error &&
            f.code != NotationFindingCode.rejectedBlock,
      )
      .length;
  if (notationErrors(merged) > notationErrors(e) + notationErrors(o)) {
    conflicts.add(
      SpecStripMergeConflict(
        code: 'notation',
        message:
            'the merged value has a notation error neither the original nor '
            'the edited text has',
      ),
    );
  }
  if (annotationIssuesText(merged).length >
      annotationIssuesText(e).length + annotationIssuesText(o).length) {
    conflicts.add(
      SpecStripMergeConflict(
        code: 'annotations',
        message:
            'the merged value has a malformed review annotation neither the '
            'original nor the edited text has',
      ),
    );
  }
  if (conflicts.isNotEmpty) {
    return SpecStripValueMerge(
      text: null,
      restored: 0,
      placed: const [],
      conflicts: conflicts,
    );
  }
  return SpecStripValueMerge(
    text: merged,
    restored: restored,
    placed: placed,
    conflicts: const [],
  );
}

/// One value a document merge changed.
class SpecStripMergedValue {
  /// [ref] merged into [text], with [restored] pieces put back and the
  /// [placed] ones to check.
  const SpecStripMergedValue({
    required this.ref,
    required this.text,
    required this.restored,
    required this.placed,
  });

  /// Which value.
  final SpecStripValueRef ref;

  /// The merged value written into the document of record.
  final String text;

  /// How many pieces were put back.
  final int restored;

  /// The pieces put back after an edited run.
  final List<SpecStripMergePlaced> placed;
}

/// An edit a merge refuses: structural, or a stale original without a base.
///
/// The [code]s: `sectionAdded`, `sectionRemoved`, `sectionMoved`,
/// `listItems` (a list item added, removed or moved), `codeSpec`, `units`,
/// `rejected` (the rendition has blocks the parser rejects), `stale` (the
/// original moved since the export and no base is at hand) and `strip` (the
/// base does not strip into a valid rendition).
class SpecStripMergeRefusal {
  /// A refusal.
  const SpecStripMergeRefusal(this.code, this.path, this.message);

  /// What is refused; see the class comment.
  final String code;

  /// The section, list or value concerned (`''` for the document).
  final String path;

  /// The refusal in words.
  final String message;

  /// The report line.
  String get reportLine =>
      'REFUSED ${path.isEmpty ? '(document)' : path} — $message';

  /// The refusal as the conformance corpus writes it.
  Map<String, Object?> toJson() => {'code': code, 'path': path};
}

/// The result of [SpecStripMerge.merge].
class SpecStripMergeResult {
  /// A result.
  const SpecStripMergeResult({
    required this.document,
    required this.options,
    required this.stale,
    required this.merged,
    required this.conflicts,
    required this.refusals,
  });

  /// The merged document of record; null when the merge has conflicts or
  /// refusals (nothing is written: the merge is all or nothing).
  final SpecDocument? document;

  /// The switches the rendition was stripped with.
  final SpecStripOptions options;

  /// Whether the original had moved since the export, so the merge was
  /// three-way from its state at the export.
  final bool stale;

  /// The values merged, in document order.
  final List<SpecStripMergedValue> merged;

  /// The conflicts.
  final List<SpecStripMergeConflict> conflicts;

  /// The refused edits.
  final List<SpecStripMergeRefusal> refusals;

  /// Whether the merge may be written.
  bool get ok => conflicts.isEmpty && refusals.isEmpty;

  /// `0` merged or nothing to merge, `1` conflicts or refusals.
  int get exitCode => ok ? 0 : 1;

  /// The report: one `MERGED` line per value (with its `PLACED` lines), the
  /// conflicts with their excerpts, then the refusals.
  List<String> get report => [
    for (final m in merged) ...[
      'MERGED ${specStripMergeLabel(m.ref)} — ${m.restored} pieces put back',
      for (final _ in m.placed) 'PLACED ${specStripMergeLabel(m.ref)} — check',
    ],
    for (final c in conflicts) ...c.reportLines,
    for (final r in refusals) r.reportLine,
  ];
}

/// Merging an edited readable rendition back onto its document of record
/// (SOM §11.10).
abstract final class SpecStripMerge {
  /// Merges [edited], a `.readable.md` made from [original] and changed by a
  /// reader, back onto [original].
  ///
  /// The switches come from the rendition's readable header; [options], when
  /// given, must agree with it, or stand in for a missing one. A rendition
  /// with neither is a [SpecStripUsageError], and so is one whose switches
  /// disagree.
  ///
  /// The original is **stale** when the header's revision differs from
  /// [currentRevision]. A stale original is merged three ways from its state
  /// at the export: [base] when given, else what [loadBase] returns for the
  /// header's source (its commit; not a `+dirty` one) — see [gitShowFile].
  /// The reader's changes against the stripped base are applied onto the
  /// current original, and a value changed on both sides is a conflict.
  /// Without a base the merge is refused, naming both revisions. A [base]
  /// given for a current original is used the same way.
  ///
  /// The base is stripped again with the switches ([model], [schema] and
  /// [rootType] as for [SpecDocumentStrip.strip]); every value of the
  /// rendition is matched to it by path. Structural edits — a section or
  /// list item added, removed or moved, a changed id, `codeSpec` or `units`
  /// — are refused. Each changed value is merged with [mergeStrippedValue];
  /// a value the reader added to a section the rendition shows is added.
  ///
  /// All or nothing: with any conflict or refusal no document is returned.
  /// Before one is, it is verified: it differs from [original] in exactly the
  /// merged values, stripping it gives back the edited values, and it has no
  /// finding of the instance or (with [schema]) the DocSpecs tier that
  /// [original] has not.
  static SpecStripMergeResult merge(
    SpecDocument original,
    String edited, {
    required SpecModel model,
    DocSpecsSchema? schema,
    String? rootType,
    SpecStripOptions? options,
    String? currentRevision,
    SpecDocument? base,
    SpecDocument? Function(SpecReadableSource source)? loadBase,
    String? fileStem,
    Map<String, String> documentFiles = const {},
  }) {
    final parsed = SpecDocumentMarkdown(
      model,
      SpecDocument(),
      fileStem: fileStem,
      documentFiles: documentFiles,
    ).parse(edited);
    final headerLine = parsed.readableHeader;
    final header = headerLine == null
        ? null
        : SpecReadableHeader.parse(headerLine);
    if (headerLine != null && header == null) {
      throw SpecStripUsageError(
        'the readable header cannot be read: $headerLine',
      );
    }
    final SpecStripOptions opts;
    if (options != null) {
      if (header != null && !_sameOptions(header.options, options)) {
        throw SpecStripUsageError(
          'the switches given (${_optionsText(options)}) disagree with the '
          'readable header (${_optionsText(header.options)})',
        );
      }
      opts = options;
    } else if (header != null) {
      opts = header.options;
    } else {
      throw const SpecStripUsageError(
        'the rendition has no readable header: name the switches it was '
        'stripped with',
      );
    }

    SpecStripMergeResult refused(List<SpecStripMergeRefusal> r, bool stale) =>
        SpecStripMergeResult(
          document: null,
          options: opts,
          stale: stale,
          merged: const [],
          conflicts: const [],
          refusals: r,
        );

    if (parsed.rejections.isNotEmpty) {
      return refused([
        for (final r in parsed.rejections)
          SpecStripMergeRefusal('rejected', '', 'line ${r.line}: ${r.message}'),
      ], false);
    }

    final source = header?.source;
    final stale =
        base != null ||
        (source?.revision != null &&
            currentRevision != null &&
            source!.revision != currentRevision);
    var origin = original;
    if (stale) {
      final b =
          base ??
          (source?.commit != null && !source!.dirty && loadBase != null
              ? loadBase(source)
              : null);
      if (b == null) {
        return refused([
          SpecStripMergeRefusal(
            'stale',
            '',
            'the original moved since the export (revision '
                '${source?.revision} then, $currentRevision now) and there is '
                'no base: the header ${source?.commit == null
                    ? 'names no commit'
                    : source!.dirty
                    ? 'names a dirty commit'
                    : 'names a commit that could not be read'}; give the '
                'original as it was at the export',
          ),
        ], true);
      }
      origin = b;
    }

    final strip = SpecDocumentStrip.strip(
      origin,
      opts,
      model: model,
      schema: schema,
      rootType: rootType,
      fileStem: fileStem,
      documentFiles: documentFiles,
    );
    if (!strip.ok || strip.readable == null) {
      return refused([
        for (final f in strip.findings)
          SpecStripMergeRefusal('strip', f.ref?.label ?? '', '$f'),
        if (strip.findings.isEmpty)
          const SpecStripMergeRefusal(
            'strip',
            '',
            'the base renders no rendition',
          ),
      ], stale);
    }
    final bDoc = strip.document;
    final eDoc = SpecDocument()..applyMarkdownResult(parsed);
    final roots = parsed.rootPrefixes;
    bool inRoot(String p) =>
        roots.any((r) => p == r || p.startsWith('$r/') || p.startsWith('$r-'));

    // Structural edits.
    final refusals = <SpecStripMergeRefusal>[];
    final bHeadings = _headingPaths(strip.readable!);
    final eHeadings = _headingPaths(edited);
    if (!_listEq(bHeadings, eHeadings)) {
      final bSet = bHeadings.toSet(), eSet = eHeadings.toSet();
      for (final p in eHeadings) {
        if (!bSet.contains(p)) {
          refusals.add(
            SpecStripMergeRefusal('sectionAdded', p, 'a section added'),
          );
        }
      }
      for (final p in bHeadings) {
        if (!eSet.contains(p)) {
          refusals.add(
            SpecStripMergeRefusal('sectionRemoved', p, 'a section removed'),
          );
        }
      }
      if (refusals.isEmpty) {
        final common = [
          for (final p in eHeadings)
            if (bSet.contains(p)) p,
        ];
        final want = [
          for (final p in bHeadings)
            if (eSet.contains(p)) p,
        ];
        for (var i = 0; i < common.length; i++) {
          if (common[i] != want[i]) {
            refusals.add(
              SpecStripMergeRefusal(
                'sectionMoved',
                common[i],
                'a section moved',
              ),
            );
            break;
          }
        }
      }
    }
    final bLists = _listsUnder(bDoc, inRoot),
        eLists = _listsUnder(eDoc, inRoot);
    for (final l in {...bLists.keys, ...eLists.keys}.toList()..sort()) {
      if (bLists[l] != eLists[l]) {
        refusals.add(
          SpecStripMergeRefusal(
            'listItems',
            l,
            'list items added, removed, moved or renamed',
          ),
        );
      }
    }
    for (final (code, read, paths) in [
      (
        'codeSpec',
        (SpecDocument d, String p) => d.codeSpec(p),
        (SpecDocument d) => d.codeSpecPaths,
      ),
      (
        'units',
        (SpecDocument d, String p) => d.units(p),
        (SpecDocument d) => d.unitsPaths,
      ),
    ]) {
      final all = {...paths(bDoc), ...paths(eDoc)}.where(inRoot).toList()
        ..sort();
      for (final p in all) {
        if (read(bDoc, p) != read(eDoc, p)) {
          refusals.add(SpecStripMergeRefusal(code, p, 'a changed $code'));
        }
      }
    }
    final refs =
        <SpecStripValueRef>{
          ...SpecDocumentStrip._valueRefs(bDoc),
          ...SpecDocumentStrip._valueRefs(eDoc),
        }.where((r) => inRoot(r.path)).toList()..sort((x, y) {
          final c = x.path.compareTo(y.path);
          if (c != 0) return c;
          if (x.headline != y.headline) return x.headline ? -1 : 1;
          return (x.field ?? '').compareTo(y.field ?? '');
        });
    for (final ref in refs) {
      if (ref.read(bDoc).isEmpty &&
          ref.read(eDoc).isNotEmpty &&
          !bDoc.hasValuesUnder(ref.path) &&
          !refusals.any((r) => r.path == ref.path)) {
        refusals.add(
          SpecStripMergeRefusal(
            'sectionAdded',
            ref.path,
            'a value in a section the rendition does not show',
          ),
        );
      }
    }

    // The values.
    final pieces = {for (final v in strip.values) v.ref: v.pieces};
    final merged = <SpecStripMergedValue>[];
    final conflicts = <SpecStripMergeConflict>[];
    for (final ref in refs) {
      final bText = ref.read(bDoc), eText = ref.read(eDoc);
      if (bText == eText) continue;
      if (refusals.any((r) => r.path == ref.path)) continue;
      // A value whose section came or went with a refused edit is that edit.
      if (refusals.isNotEmpty &&
          (!bDoc.hasValuesUnder(ref.path) || !eDoc.hasValuesUnder(ref.path))) {
        continue;
      }
      final o = ref.read(origin);
      if (stale && ref.read(original) != o) {
        conflicts.add(
          SpecStripMergeConflict(
            code: 'changedBothSides',
            message:
                'the value changed in the original since the export, '
                'and in the rendition',
            ref: ref,
            excerptO: _excerpt(ref.read(original), 0),
            excerptB: _excerpt(bText, 0),
            excerptE: _excerpt(eText, 0),
          ),
        );
        continue;
      }
      final r = mergeStrippedValue(o, bText, eText, pieces[ref] ?? const []);
      if (!r.ok) {
        conflicts.addAll([for (final c in r.conflicts) c.about(ref)]);
        continue;
      }
      merged.add(
        SpecStripMergedValue(
          ref: ref,
          text: r.text!,
          restored: r.restored,
          placed: r.placed,
        ),
      );
    }
    if (conflicts.isNotEmpty || refusals.isNotEmpty) {
      return SpecStripMergeResult(
        document: null,
        options: opts,
        stale: stale,
        merged: merged,
        conflicts: conflicts,
        refusals: refusals,
      );
    }

    // Write and verify.
    final out = SpecDocument()..loadJson(original.toJson());
    for (final m in merged) {
      m.ref.write(out, m.text);
    }
    final expected = {
      for (final m in merged)
        if (m.text != m.ref.read(original)) m.ref,
    };
    final changed = {
      for (final r in {
        ...SpecDocumentStrip._valueRefs(original),
        ...SpecDocumentStrip._valueRefs(out),
      })
        if (r.read(original) != r.read(out)) r,
    };
    if (changed.length != expected.length || !changed.containsAll(expected)) {
      conflicts.add(
        const SpecStripMergeConflict(
          code: 'newFinding',
          message:
              'the merged document changes other values than the merged '
              'ones',
        ),
      );
    }
    final again = SpecDocumentStrip.strip(
      out,
      opts,
      model: model,
      schema: schema,
      rootType: rootType,
      fileStem: fileStem,
      documentFiles: documentFiles,
    );
    for (final m in merged) {
      if (m.ref.read(again.document) != m.ref.read(eDoc)) {
        conflicts.add(
          SpecStripMergeConflict(
            code: 'notStrippedBack',
            message: 'the merged value does not strip back to the edited text',
            ref: m.ref,
            excerptO: _excerpt(m.text, 0),
            excerptB: _excerpt(m.ref.read(again.document), 0),
            excerptE: _excerpt(m.ref.read(eDoc), 0),
          ),
        );
      }
    }
    final before = SpecDocumentStrip._tierFindings(
      model,
      schema,
      rootType,
      original,
    );
    for (final k in SpecDocumentStrip._tierFindings(
      model,
      schema,
      rootType,
      out,
    ).keys) {
      if (!before.containsKey(k)) {
        conflicts.add(
          SpecStripMergeConflict(
            code: 'newFinding',
            message: 'the merged document has a new finding: $k',
          ),
        );
      }
    }
    return SpecStripMergeResult(
      document: conflicts.isEmpty ? out : null,
      options: opts,
      stale: stale,
      merged: merged,
      conflicts: conflicts,
      refusals: const [],
    );
  }

  /// The file at [path] as it was at [commit] (`git show <commit>:<path>`,
  /// run in the file's folder), or null when git cannot give it. What
  /// [merge]'s `loadBase` decodes into the base of a stale original.
  static String? gitShowFile(String commit, String path) {
    final file = File(path).absolute;
    try {
      final r = Process.runSync('git', [
        'show',
        '$commit:./${file.uri.pathSegments.last}',
      ], workingDirectory: file.parent.path);
      return r.exitCode == 0 ? r.stdout as String : null;
    } on ProcessException {
      return null;
    }
  }

  static bool _sameOptions(SpecStripOptions a, SpecStripOptions b) =>
      _optionsText(a) == _optionsText(b);

  static String _optionsText(SpecStripOptions o) {
    final s = SpecReadableHeader(o).format();
    return s.substring('<!-- readable:'.length, s.length - 3).trim();
  }

  /// The section-id paths of [markdown]'s headings, in order.
  static List<String> _headingPaths(String markdown) {
    final out = <String>[];
    void walk(List<DocSpecsSection> list, String prefix) {
      for (final s in list) {
        final p = prefix.isEmpty ? s.id ?? '?' : '$prefix/${s.id ?? '?'}';
        out.add(p);
        walk(s.children, p);
      }
    }

    walk(DocSpecsDocument.parse(markdown).sections, '');
    return out;
  }

  /// The lists of [doc] under the roots, each as its items and their ids.
  static Map<String, String> _listsUnder(
    SpecDocument doc,
    bool Function(String) inRoot,
  ) {
    final lists = doc.toJson()['lists'];
    return {
      if (lists is Map)
        for (final e in lists.entries)
          if (inRoot('${e.key}'))
            '${e.key}':
                '${(e.value as Map)['items']} ${(e.value as Map)['ids']}',
    };
  }
}

const _roleWhole = 0, _roleOpener = 1, _roleCloser = 2, _roleBoth = 3;

/// What each piece is, read from the original [o]: the opening markers of an
/// element (a notation div, span or citation, or a review mark) whose closing
/// markers went in another piece, the closing ones, both, or a whole element
/// (or anything else).
List<int> _pieceRoles(String o, List<SpecStripPiece> pieces) {
  final at = List<int>.filled(o.length, -1);
  for (var i = 0; i < pieces.length; i++) {
    final p = pieces[i];
    for (
      var k = p.origin;
      k < p.origin + p.removed.length && k < o.length;
      k++
    ) {
      at[k] = i;
    }
  }
  final opener = List<bool>.filled(pieces.length, false);
  final closer = List<bool>.filled(pieces.length, false);
  int first(int s, int e) {
    for (var k = s; k < e && k < o.length; k++) {
      if (o[k].trim().isNotEmpty) return at[k];
    }
    return -1;
  }

  void pair(int start, int openEnd, int closeStart, int end) {
    if (start < end && at[start] >= 0) {
      var whole = true;
      for (var k = start; k < end; k++) {
        if (at[k] != at[start]) {
          whole = false;
          break;
        }
      }
      if (whole) return;
    }
    final po = first(start, openEnd), pc = first(closeStart, end);
    if (po >= 0 && po != pc) opener[po] = true;
    if (pc >= 0 && pc != po) closer[pc] = true;
  }

  void walk(List<NotationElement> list) {
    for (final e in list) {
      if (e.type == NotationElementType.citation) {
        if (e.start < e.end && at[e.start] >= 0) {
          var whole = true;
          for (var k = e.start; k < e.end; k++) {
            if (at[k] != at[e.start]) whole = false;
          }
          if (whole) continue;
        }
        final po = first(e.start + 1, e.contentStart);
        if (po >= 0) opener[po] = true;
      } else {
        pair(e.start, e.contentStart, e.contentEnd, e.end);
      }
      walk(e.children);
    }
  }

  walk(scanNotation(o, tomSpecs: true).elements);
  for (final m in _findMarks(o)) {
    pair(m.start, m.sep >= 0 ? m.sep + 2 : m.bodyStart, m.bodyEnd, m.end);
  }
  return [
    for (var i = 0; i < pieces.length; i++)
      opener[i] && closer[i]
          ? _roleBoth
          : opener[i]
          ? _roleOpener
          : closer[i]
          ? _roleCloser
          : _roleWhole,
  ];
}

/// Where a gap of the baseline lies in the edited text.
class _Gap {
  const _Gap(this.leftEdited, this.rightEdited, this.start, this.end)
    : at = start;
  const _Gap.unchanged(this.at)
    : leftEdited = false,
      rightEdited = false,
      start = at,
      end = at;

  /// Whether the character before (after) the gap was deleted or changed.
  final bool leftEdited, rightEdited;

  /// The edited run touching the gap, in the edited text; equal when both
  /// neighbours are unchanged.
  final int start, end;

  /// The gap's place in the edited text, when [unchanged].
  final int at;

  bool get unchanged => !leftEdited && !rightEdited && start == end;
}

/// An edit script from a baseline to an edited text, indexed by baseline
/// offset.
class _EditMap {
  _EditMap(this.ops, int bLength) {
    after = List<int>.filled(bLength + 1, 0);
    eBefore = List<int>.filled(ops.length + 1, 0);
    deleted = List<bool>.filled(bLength, false);
    var g = 0;
    for (var i = 0; i < ops.length; i++) {
      eBefore[i + 1] = eBefore[i] + (ops[i].type == _Op.del ? 0 : 1);
      if (ops[i].type != _Op.ins) {
        if (ops[i].type == _Op.del) deleted[g] = true;
        g++;
        after[g] = i + 1;
      }
    }
  }

  final List<_Op> ops;

  /// The op index right after the g-th baseline character's op.
  late final List<int> after;

  /// The edited-text offset before op i.
  late final List<int> eBefore;

  /// Per baseline character: deleted by the edit.
  late final List<bool> deleted;

  _Gap gap(int g) {
    final p = after[g];
    final leftEdited = g > 0 && ops[p - 1].type == _Op.del;
    var r = p;
    while (r < ops.length && ops[r].type == _Op.ins) {
      r++;
    }
    final rightEdited = r < ops.length && ops[r].type == _Op.del;
    if (!leftEdited && r == p && !rightEdited)
      return _Gap.unchanged(eBefore[p]);
    var s = p;
    while (s > 0 && ops[s - 1].type != _Op.keep) {
      s--;
    }
    var t = p;
    while (t < ops.length && ops[t].type != _Op.keep) {
      t++;
    }
    return _Gap(leftEdited, rightEdited, eBefore[s], eBefore[t]);
  }

  /// The edited-text offset of baseline range `[a, z)` when it is kept whole
  /// and unbroken, else -1.
  int keptRange(int a, int z) {
    final first = after[a + 1] - 1;
    for (var k = a; k < z; k++) {
      final i = after[k + 1] - 1;
      if (ops[i].type != _Op.keep || i != first + (k - a)) return -1;
    }
    return eBefore[first];
  }
}

/// A line edit script from a baseline to an edited text.
class _LineEditMap {
  _LineEditMap(String b, String e) {
    final bl = _lines(b), el = _lines(e);
    ops = _myers(bl, el);
    after = List<int>.filled(bl.length + 1, 0);
    eBefore = List<int>.filled(ops.length + 1, 0);
    var k = 0;
    for (var i = 0; i < ops.length; i++) {
      final (type, line) = ops[i];
      eBefore[i + 1] = eBefore[i] + (type == _Op.del ? 0 : line.length);
      if (type != _Op.ins) {
        k++;
        after[k] = i + 1;
      }
    }
  }

  late final List<(int, String)> ops;
  late final List<int> after;
  late final List<int> eBefore;

  _Gap gap(int k) {
    final p = after[k];
    final leftEdited = k > 0 && ops[p - 1].$1 == _Op.del;
    var r = p;
    while (r < ops.length && ops[r].$1 == _Op.ins) {
      r++;
    }
    final rightEdited = r < ops.length && ops[r].$1 == _Op.del;
    if (!leftEdited && r == p && !rightEdited)
      return _Gap.unchanged(eBefore[p]);
    var s = p;
    while (s > 0 && ops[s - 1].$1 != _Op.keep) {
      s--;
    }
    var t = p;
    while (t < ops.length && ops[t].$1 != _Op.keep) {
      t++;
    }
    return _Gap(leftEdited, rightEdited, eBefore[s], eBefore[t]);
  }

  /// Where a block anchored at line [k] goes when the lines on both sides of
  /// it were edited: after as many paragraphs of the edited run as the
  /// baseline run had before the anchor.
  int paragraphPlace(_Gap gap, int k) {
    final p = after[k];
    var s = p;
    while (s > 0 && ops[s - 1].$1 != _Op.keep) {
      s--;
    }
    var before = 0;
    var blank = true;
    for (var i = s; i < p; i++) {
      final (type, line) = ops[i];
      if (type != _Op.del) continue;
      final isBlank = line.trim().isEmpty;
      if (!isBlank && blank) before++;
      blank = isBlank;
    }
    if (before == 0) return gap.start;
    var count = 0;
    blank = true;
    for (var i = s; i < ops.length && ops[i].$1 != _Op.keep; i++) {
      final (type, line) = ops[i];
      if (type != _Op.ins) continue;
      final isBlank = line.trim().isEmpty;
      if (!isBlank && blank) {
        if (count == before) return eBefore[i];
        count++;
      }
      blank = isBlank;
    }
    return gap.end;
  }
}

/// [ops] with every run of only deletions (or only insertions) slid along
/// equal text so that whitespace at its end moves to its start ([leading]) or
/// whitespace at its start moves to its end; the texts on both sides stay the
/// same.
List<_Op> _slide(List<_Op> ops, {required bool leading}) {
  final out = List<_Op>.of(ops);
  bool ws(String c) => c.trim().isEmpty;
  var s = 0;
  while (s < out.length) {
    if (out[s].type == _Op.keep) {
      s++;
      continue;
    }
    var t = s;
    while (t < out.length && out[t].type == out[s].type) {
      t++;
    }
    if (t < out.length && out[t].type != _Op.keep) {
      // A mixed run: left as the diff wrote it.
      while (t < out.length && out[t].type != _Op.keep) {
        t++;
      }
      s = t;
      continue;
    }
    final type = out[s].type;
    if (leading) {
      while (s > 0 &&
          out[s - 1].type == _Op.keep &&
          ws(out[t - 1].char) &&
          out[s - 1].char == out[t - 1].char) {
        out[t - 1] = _Op(_Op.keep, out[t - 1].char);
        out[s - 1] = _Op(type, out[s - 1].char, 'edit');
        s--;
        t--;
      }
    } else {
      while (t < out.length &&
          out[t].type == _Op.keep &&
          ws(out[s].char) &&
          out[s].char == out[t].char) {
        out[s] = _Op(_Op.keep, out[s].char);
        out[t] = _Op(type, out[t].char, 'edit');
        s++;
        t++;
      }
    }
    s = t;
  }
  return out;
}

/// The number of lines of [b] before offset [g] (a line start or the end).
int _lineIndex(String b, int g) {
  var k = 0;
  for (var i = 0; i < g; i++) {
    if (b.codeUnitAt(i) == 0x0a) k++;
  }
  if (g == b.length && b.isNotEmpty && !b.endsWith('\n')) k++;
  return k;
}

/// Whether the edit deleted every character of the sentence of [b] holding
/// gap [g]: from after the last sentence end (`.`, `!` or `?` before
/// whitespace) or line break before the gap to the next one after it.
bool _sentenceRemoved(String b, int g, _EditMap map) {
  bool ends(int i) =>
      '.!?'.contains(b[i]) && (i + 1 >= b.length || b[i + 1].trim().isEmpty);
  var s = g;
  while (s > 0 && b[s - 1] != '\n' && !(s - 1 < g - 1 && ends(s - 1))) {
    s--;
  }
  var e = g;
  while (e < b.length && b[e] != '\n') {
    if (ends(e)) {
      e++;
      break;
    }
    e++;
  }
  var any = false;
  for (var i = s; i < e; i++) {
    if (b[i].trim().isEmpty) continue;
    any = true;
    if (!map.deleted[i]) return false;
  }
  return any;
}

/// A piece's text going into the edited text at [at] (replacing [replace]
/// characters there), in piece order [order]; a moved block is [normalize]d
/// to stand between blank lines.
class _Put {
  _Put(
    this.at,
    this.order,
    this.text, {
    this.replace = 0,
    this.normalize = false,
    this.before = 2,
    this.after = 2,
  });
  final int at, order, replace;

  /// The line breaks a [normalize]d block wants before and after it.
  final int before, after;
  final String text;
  final bool normalize;
}

int _trailingBreaks(String s) {
  var n = 0;
  for (var i = s.length - 1; i >= 0 && s[i] == '\n'; i--) {
    n++;
  }
  return n;
}

int _leadingBreaks(String s) {
  var n = 0;
  for (var i = 0; i < s.length && s[i] == '\n'; i++) {
    n++;
  }
  return n;
}

/// Up to 30 characters of [s] on each side of [at], line breaks shown.
String _excerpt(String s, int at) {
  final a = math.max(0, math.min(at, s.length) - 30);
  final z = math.min(s.length, at + 30);
  return _visible(s.substring(a, z));
}

String _visible(String s) => '«${s.replaceAll('\n', '⏎')}»';

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
