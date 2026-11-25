part of 'spec_document_set.dart';

// ---------------------------------------------------------------------------
// prefill: a Phase 3 document started from the Blueprint
// ---------------------------------------------------------------------------

/// Why [prefill] refuses.
class SpecPrefillError implements Exception {
  /// `noBlueprint` (the set holds no Blueprint) or `unknownRoot` (the root
  /// names no root of the model, or the Blueprint's own).
  final String code;

  /// Prose for the reader.
  final String message;

  /// Both known where it is raised.
  const SpecPrefillError(this.code, this.message);

  @override
  String toString() => 'SpecPrefillError($code): $message';
}

/// What [prefill] did.
class SpecPrefillResult {
  /// The document filled: the set's own, or the one created.
  final SpecDocument document;

  /// Its name in the set.
  final String name;

  /// Whether it was created by this call.
  final bool created;

  /// The pairs it filled, by section id, in the Blueprint's order.
  final List<String> filledPairs;

  /// The pairs it left because their anchor already holds a value.
  final List<String> skippedPairs;

  /// The `deriveFields` run (plain) on the document after the copy.
  final SpecDeriveResult derived;

  /// The document's findings after it (`validateDocument`, then
  /// `validateLinks`): the agent's work list.
  final List<SpecValidationError> findings;

  /// The parts of a result.
  const SpecPrefillResult({
    required this.document,
    required this.name,
    required this.created,
    required this.filledPairs,
    required this.skippedPairs,
    required this.derived,
    required this.findings,
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'name': name,
    'created': created,
    'filledPairs': filledPairs,
    'skippedPairs': skippedPairs,
    'derived': {
      'changes': [for (final c in derived.changes) c.toJson()],
      'unresolved': [
        for (final e in derived.unresolved)
          {'path': e.path, 'code': e.code.name, 'message': e.message},
      ],
    },
    'findings': [
      for (final e in findings)
        {'path': e.path, 'code': e.code.name, 'message': e.message},
    ],
    'document': document.toJson(),
  };
}

/// Fills the pairs of [rootType] (a root's type name or section id) that
/// hold nothing yet from the Blueprint, once, at the start of a Phase 3
/// document (BP-8): every value, element (with its stored section id) and
/// headline beneath each pair's Blueprint anchor, outside `detailOnly`,
/// copied as plain values — nothing to mark against, the product owner
/// reviews the new document as a whole. Derived places are not copied; they
/// are derived in the document (`deriveFields`, plain) after the copy.
///
/// A pair whose anchor already holds any value is skipped, not merged, so a
/// second run writes nothing; later Blueprint changes reach the document
/// through the set's validation. The document's front matter (everything
/// outside the pairs: its header, its revision history) is left empty for
/// the agent. When the set has no document of the root, it is created as
/// [name] (default: the root's type name) and added to the set once it holds
/// a value. [pairs] keeps those pairs (by section id) only.
SpecPrefillResult prefill(
  SpecDocumentSet set,
  String rootType, {
  String? name,
  Set<String>? pairs,
}) {
  final bpRoot = set.blueprintRoot;
  final bpName = bpRoot == null ? null : set.nameOf(bpRoot);
  if (bpName == null) {
    throw const SpecPrefillError('noBlueprint', 'the set holds no Blueprint');
  }
  final root = set.model.roots
      .where((r) => r.type == rootType || r.sectionId == rootType)
      .firstOrNull;
  if (root == null || root.type == bpRoot) {
    throw SpecPrefillError(
      'unknownRoot',
      '$rootType names no Phase 3 root of the model',
    );
  }
  final existing = set.nameOf(root.type);
  final docName = existing ?? name ?? root.type;
  final doc = existing == null ? SpecDocument() : set[existing]!;
  final bp = set[bpName]!;
  final c = _SetCheck(set);

  final filled = <String>[];
  final skipped = <String>[];
  for (final pair in set.pairs) {
    if (pair.detailRoot != root.type) continue;
    if (pairs != null && !pairs.contains(pair.sectionId)) continue;
    // Nested pairs are filled on their own (when they are this root's).
    final nested = [
      for (final other in set.pairs)
        if (other != pair) ...c._expand(bp, other.blueprintAnchor),
    ];
    var wrote = false;
    var held = false;
    for (final ba in c._expand(bp, pair.blueprintAnchor)) {
      final ids = c._anchorKey(bp, ba);
      final created = <String>[];
      final da = _anchorIn(c, doc, pair.detailAnchor, ids, created);
      if (doc.hasValuesUnder(da) && created.isEmpty) {
        held = true;
        continue;
      }
      final side = c._collect(
        bpName,
        bp,
        bpRoot!,
        ba,
        pair,
        nested.where((p) => p.startsWith('$ba/')).toList(),
      );
      if (_copy(c, bp, side, doc, da)) {
        wrote = true;
      } else {
        // Nothing to copy: the anchor items made for it go again.
        for (final item in created.reversed) {
          doc.removeListItem(item);
        }
      }
    }
    if (wrote) filled.add(pair.sectionId);
    if (held && !wrote) skipped.add(pair.sectionId);
  }

  final created =
      existing == null && doc.hasValuesUnder(set.refl.rootSegment(root));
  if (created) set.put(docName, doc);
  final derived = deriveFields(set.model, doc, marked: false);
  return SpecPrefillResult(
    document: doc,
    name: docName,
    created: created,
    filledPairs: filled,
    skippedPairs: skipped,
    derived: derived,
    findings: [
      ...validateDocument(set.model, doc),
      ...validateLinks(set.model, doc),
    ],
  );
}

/// The concrete detail anchor of [pattern] in [doc] for a Blueprint anchor
/// whose list items carry [ids] (`a/b`, in order): each `<list>-*` taken as
/// the item of that id, created with it when missing.
String _anchorIn(
  _SetCheck c,
  SpecDocument doc,
  String pattern,
  String ids,
  List<String> created,
) {
  final want = ids.isEmpty ? <String>[] : ids.split('/');
  var k = 0;
  var cur = '';
  for (final seg in pattern.split('/')) {
    if (!seg.endsWith('-*')) {
      cur = cur.isEmpty ? seg : '$cur/$seg';
      continue;
    }
    final list = '$cur/${seg.substring(0, seg.length - 2)}';
    final id = k < want.length ? want[k++] : '';
    final found = doc
        .listItems(list)
        .where((i) => c._itemId(doc, i) == id)
        .firstOrNull;
    if (found != null) {
      cur = found;
    } else {
      cur = doc.addListItem(list, sectionId: id);
      created.add(cur);
    }
  }
  return cur;
}

/// Copies the Blueprint values of [side] beneath [anchor] of [doc]: list
/// items first, in the Blueprint's order and with their section ids, then
/// every value. Whether anything was written.
bool _copy(
  _SetCheck c,
  SpecDocument bp,
  _Side side,
  SpecDocument doc,
  String anchor,
) {
  var wrote = false;
  final mapped = <String, String>{side.anchor: anchor};
  String? into(String bpPath) {
    String? best;
    for (final k in mapped.keys) {
      if ((bpPath == k || bpPath.startsWith('$k/')) &&
          (best == null || k.length > best.length)) {
        best = k;
      }
    }
    return best == null
        ? null
        : '${mapped[best]}${bpPath.substring(best.length)}';
  }

  // Items, outer lists first, each list in the Blueprint's order.
  final lists = <String>{
    for (final item in side.items.values)
      if (item != side.anchor) item.substring(0, item.lastIndexOf('-')),
  }.toList()..sort((a, b) => a.length.compareTo(b.length));
  for (final list in lists) {
    final target = into(list);
    if (target == null) continue;
    for (final item in bp.listItems(list)) {
      if (!side.items.containsValue(item)) continue;
      mapped[item] = doc.addListItem(target, sectionId: c._itemId(bp, item));
      wrote = true;
    }
  }
  for (final v in side.values.values) {
    if (v.value.isEmpty) continue;
    final p = into(v.path);
    if (p == null) continue;
    if (v.field == kSpecHeadlineField) {
      doc.setHeadline(p, v.value);
    } else if (v.field == null) {
      doc.setContent(p, v.value);
    } else {
      doc.setFormField(p, v.field!, v.value);
    }
    wrote = true;
  }
  return wrote;
}
