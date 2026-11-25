part of 'spec_document_markdown.dart';

// ---------------------------------------------------------------------------
// Navigation between linked places (SOM §11.2 qualified anchors, SOM §11.11
// the `linked` marker)
// ---------------------------------------------------------------------------
//
// Both are written from the model and the document's own values, and nothing
// of either is stored: the parser removes the anchors and the marker.

/// Written by the emitter where a markable place has no entry: replaced by
/// `[]{.linked}` when the value written after it begins with a `linked` span,
/// else removed with its blank line (SOM §11.11).
const String _kLinkedPlaceholder = '\u0000linked\u0000';

/// The anchor of a heading [id] and the scope its descendants are qualified
/// with (SOM §11.2): below a list item, and below a `@SameAs` copy, a heading's
/// anchor is the `/`-joined ids from the outermost item (or from the copy's
/// nearest enclosing section) down to it, list containers left out of the
/// descendants' anchors. [scope] is the parent's scope, [section] the id of
/// the nearest heading above that is no list container.
(String, List<String>?) _qualifyAnchor(
  List<String>? scope,
  String? section,
  String id, {
  bool container = false,
  bool item = false,
  bool copy = false,
}) {
  String joined(List<String>? s) => s == null ? id : [...s, id].join('/');
  if (container) return (joined(scope), scope);
  if (item) return (joined(scope), [...?scope, id]);
  if (copy) {
    final s = [
      ...?(scope ?? (section == null ? null : [section])),
      id,
    ];
    return (s.join('/'), s);
  }
  return (joined(scope), scope == null ? null : [...scope, id]);
}

/// Where a path lands in a root's tree: the heading at or above it.
class _Walk {
  _Walk({
    required this.anchor,
    required this.headingId,
    required this.headingPath,
    required this.pattern,
    required this.itemIds,
    required this.node,
  });

  /// The anchor of the heading at or above the path.
  final String anchor;

  /// That heading's section id.
  final String headingId;

  /// That heading's path (the path itself when it has a heading).
  final String headingPath;

  /// The path with every list item written `<list>-*`.
  final String pattern;

  /// The ids of the list items on the way, in order.
  final List<String> itemIds;

  /// The node the whole path reaches, or null when it reaches none.
  final SomMetaNode? node;
}

/// One root's navigation: anchors, markable places and marker entries.
class _Navigation {
  _Navigation(this.codec, this.root)
    : refl = SpecReflection(codec.model),
      tree = codec._treeFor(root.type);

  final SpecDocumentMarkdown codec;
  final SpecRoot root;
  final SpecReflection refl;
  final SomMetaTree tree;

  SpecModel get model => codec.model;
  SpecDocument get doc => codec.document;
  String get rootSeg => refl.rootSegment(root);

  // --- anchors -------------------------------------------------------------

  final Map<String, _Walk> _walks = {};

  /// Whether [node] is a `@SameAs` copy (its member carries the annotation).
  bool isCopy(SomMetaNode node) => codec._isCopyNode(node);

  /// The heading id of the item at [itemPath] of [listNode] in [doc], as
  /// `_writeList` writes it.
  String itemId(SpecDocument? d, SomMetaNode listNode, String itemPath) {
    final split = splitListItemSegment(itemPath.split('/').last)!;
    final listPath =
        '${itemPath.substring(0, itemPath.lastIndexOf('/') + 1)}${split.base}';
    final pos = d == null ? 0 : d.listItems(listPath).indexOf(itemPath) + 1;
    return effectiveListItemSectionId(
      storedId: d?.itemSectionId(itemPath),
      pattern:
          listNode.sectionIdPattern ?? listNode.elementNode?.sectionIdPattern,
      position: pos == 0 ? split.seq : pos,
      fallbackStem: listNode.memberName ?? listNode.segment,
    );
  }

  /// Walks [path] (concrete, or a pattern whose `<list>-*` segments take
  /// [ids] in order) through [inTree], the items' ids read from [d].
  _Walk walk(
    String path, {
    SomMetaTree? inTree,
    SpecDocument? d,
    List<String> ids = const [],
  }) {
    final t = inTree ?? tree;
    final cacheable = inTree == null && ids.isEmpty && identical(d, doc);
    if (cacheable) {
      final hit = _walks[path];
      if (hit != null) return hit;
    }
    final queue = [...ids];
    final segs = path.split('/');
    var node = t.root;
    var cur = segs.first;
    var pattern = segs.first;
    var anchor = node.segment;
    var headingId = node.segment;
    var headingPath = cur;
    List<String>? scope;
    String? section = node.segment;
    final itemIds = <String>[];
    SomMetaNode? reached = node;
    for (var i = 1; i < segs.length; i++) {
      final seg = segs[i];
      final child = node.childBySegment(seg);
      if (child != null) {
        cur = '$cur/$seg';
        pattern = '$pattern/$seg';
        node = child;
        reached = child;
        if (codec._isTransparentSection(child) ||
            codec._isTransparentValue(child)) {
          continue;
        }
        final id = codec._headingIdOf(child);
        final container = child.kind == SomMetaKind.list;
        final (a, s) = _qualifyAnchor(
          scope,
          section,
          id,
          container: container,
          copy: !container && isCopy(child),
        );
        anchor = a;
        scope = s;
        headingId = id;
        headingPath = cur;
        if (!container) section = id;
        continue;
      }
      final star = seg.endsWith('-*');
      final base = star
          ? seg.substring(0, seg.length - 2)
          : splitListItemSegment(seg)?.base;
      final listNode = base == null ? null : node.childBySegment(base);
      if (listNode == null || listNode.kind != SomMetaKind.list) {
        reached = null;
        break;
      }
      final itemPath = '$cur/$seg';
      final id = star
          ? (queue.isEmpty ? '' : queue.removeAt(0))
          : itemId(d, listNode, itemPath);
      itemIds.add(id);
      final (a, s) = _qualifyAnchor(scope, section, id, item: true);
      anchor = a;
      scope = s;
      headingId = id;
      section = id;
      cur = itemPath;
      headingPath = itemPath;
      pattern = '$pattern/$base-*';
      final element = listNode.elementNode;
      node = element ?? listNode;
      reached = node;
      if (element == null && i < segs.length - 1) {
        reached = null;
        break;
      }
    }
    final w = _Walk(
      anchor: anchor,
      headingId: headingId,
      headingPath: headingPath,
      pattern: pattern,
      itemIds: itemIds,
      node: reached,
    );
    if (cacheable) _walks[path] = w;
    return w;
  }

  /// The anchor of the heading [path] names in this document.
  String anchorOf(String path) => walk(path, d: doc).anchor;

  /// [path] cut before its first `<list>-*` segment, that list's path.
  static String cutPattern(String path) {
    final i = path.indexOf('-*');
    return i < 0 ? path : path.substring(0, i);
  }

  // --- the model's links, per root -----------------------------------------

  /// Every `@SyncedWith` pair this root is a side of: (its anchor here, the
  /// other root, the anchor there, whether this side holds the values, the
  /// sync).
  late final List<
    ({String mine, SpecRoot other, String theirs, bool holder, SpecSync sync})
  >
  sides = () {
    final out =
        <
          ({
            String mine,
            SpecRoot other,
            String theirs,
            bool holder,
            SpecSync sync,
          })
        >[];
    final (bp, pairs) = codec._syncPairs;
    if (bp == null) return out;
    SpecRoot? rootOf(String type) =>
        model.roots.where((r) => r.type == type).firstOrNull;
    for (final p in pairs) {
      final sync = p.sync;
      if (sync == null) continue;
      if (root.type == bp) {
        final other = rootOf(p.detailRoot);
        if (other == null) continue;
        out.add((
          mine: p.blueprintAnchor,
          other: other,
          theirs: p.detailAnchor,
          holder: false,
          sync: sync,
        ));
      } else if (root.type == p.detailRoot) {
        final other = rootOf(bp);
        if (other == null) continue;
        out.add((
          mine: p.detailAnchor,
          other: other,
          theirs: p.blueprintAnchor,
          holder: true,
          sync: sync,
        ));
      }
    }
    return out;
  }();

  /// The `@SameAs` copies of this root with their holders.
  late final List<SpecSameAsBinding> sameAs = specSameAsBindings(
    refl,
    root.type,
  );

  bool _underCopy(String pattern) => sameAs.any(
    (b) => pattern == b.copyPath || pattern.startsWith('${b.copyPath}/'),
  );

  /// The side whose shared list [listPattern] is: the innermost pair anchor
  /// holding it, when the list lies directly beneath it (not below an item of
  /// it), outside a copy and outside the pair's `detailOnly` places.
  ({String mine, SpecRoot other, String theirs, bool holder, SpecSync sync})?
  sharedListSide(String listPattern, String concreteList) {
    if (_underCopy(listPattern)) return null;
    ({String mine, SpecRoot other, String theirs, bool holder, SpecSync sync})?
    best;
    for (final s in sides) {
      if (!listPattern.startsWith('${s.mine}/')) continue;
      if (best == null || s.mine.length > best.mine.length) best = s;
    }
    if (best == null) return null;
    final rel = listPattern.substring(best.mine.length + 1);
    if (rel.contains('-*')) return null;
    // The anchor's concrete path: the list's as long as the anchor is.
    final depth = best.mine.split('/').length;
    final anchor = concreteList.split('/').take(depth).join('/');
    for (final place in best.sync.detailOnly) {
      final r = specResolvePlaceAt(refl, place, anchor);
      if (r == null) continue;
      final p = walk(r.path, d: doc).pattern;
      if (listPattern == p || listPattern.startsWith('$p/')) return null;
    }
    return best;
  }

  /// The `@SummaryOf` of the list member at [listPath], if any.
  SpecSummaryOf? summaryOfList(String listPath) =>
      refl.resolve(listPath)?.field?.summaryOf;

  /// Whether a summary names its detail elements in this document.
  bool _sameDocument(SpecSummaryOf s) =>
      s.document == null || s.document == root.type;

  /// Detail-list pattern → the summary lists (patterns) of this document
  /// naming its elements.
  late final Map<String, List<String>> detailLists = () {
    final out = <String, List<String>>{};
    for (final n in tree.allNodes) {
      if (n.kind != SomMetaKind.list || n.path == null) continue;
      final s = summaryOfList(n.path!);
      if (s == null || !_sameDocument(s)) continue;
      final owner = n.path!.substring(0, n.path!.lastIndexOf('/'));
      final r = specResolveLinkPlace(refl, null, s.detail, rootSeg, owner);
      if (r == null) continue;
      (out[walk(cutPattern(r.path), d: doc).pattern] ??= []).add(n.path!);
    }
    return out;
  }();

  // --- markable places (structural: the parser and the emitter agree) -----

  final Map<String, bool> _markable = {};

  /// Whether the heading at [path] carries one of the links of SOM §11.11:
  /// a `@SyncedWith` anchor or an element of one of its shared lists, an
  /// element of a summary list or of a detail list a summary of this
  /// document names, a heading holding a derived value, a list of link rows
  /// extracted from text, a `@SameAs` copy or its holder.
  bool markable(String path) => _markable.putIfAbsent(path, () {
    final w = walk(path, d: doc);
    final node = w.node;
    if (node == null || w.headingPath != path) return false;
    final pattern = w.pattern;
    if (sides.any((s) => s.mine == pattern)) return true;
    final item = _itemParts(path);
    if (item != null) {
      final listPattern = _listPatternOf(pattern);
      if (sharedListSide(listPattern, item.$1) != null) return true;
      if (summaryOfList(item.$1) != null) return true;
      if (detailLists.containsKey(listPattern)) return true;
    }
    if (_derivedSources(path, node, probe: true).isNotEmpty) return true;
    if (node.kind == SomMetaKind.list && _extractFrom(path).isNotEmpty) {
      return true;
    }
    if (sameAs.any((b) => b.copyPath == pattern || b.holderPath == pattern)) {
      return true;
    }
    return false;
  });

  /// For an item path, (its list's path, its segment); null otherwise.
  (String, String)? _itemParts(String path) {
    final slash = path.lastIndexOf('/');
    if (slash < 0) return null;
    final seg = path.substring(slash + 1);
    final split = splitListItemSegment(seg);
    if (split == null) return null;
    final parent = path.substring(0, slash);
    final node = tree.byPath(parent);
    if (node != null && node.childBySegment(seg) != null) return null;
    final listPath = '$parent/${split.base}';
    if (tree.byPath(listPath)?.kind != SomMetaKind.list) return null;
    return (listPath, seg);
  }

  /// An item pattern's list pattern (`a/L-*` → `a/L`).
  static String _listPatternOf(String itemPattern) => itemPattern.endsWith('-*')
      ? itemPattern.substring(0, itemPattern.length - 2)
      : itemPattern;

  // --- the marker ------------------------------------------------------------

  /// A link to [anchor] in [other] (null: this document), its text [id]
  /// prefixed by the other root's id.
  String _link(String id, String anchor, [SpecRoot? other]) {
    if (other == null) return '[$id](#$anchor)';
    final file = codec._fileOfRoot(other);
    return '[${other.sectionId ?? other.type} $id]($file#$anchor)';
  }

  /// The marker's entries at the heading [path], in the order of SOM §11.11;
  /// empty when [path] is not markable or carries no link this time.
  /// [sectionTable]: the heading's children are written as a section table.
  List<String> entries(String path, {bool sectionTable = false}) {
    if (!markable(path)) return const [];
    final w = walk(path, d: doc);
    final node = w.node!;
    final pattern = w.pattern;
    final out = <String>[];

    // Also in (@SyncedWith).
    String note(
      ({String mine, SpecRoot other, String theirs, bool holder, SpecSync sync})
      s,
    ) {
      final held = s.holder ? 'held here' : 'held there';
      return s.sync.heldHere.isEmpty
          ? held
          : '$held except ${s.sync.heldHere.join(', ')}';
    }

    for (final s in sides) {
      if (s.mine != pattern) continue;
      final there = walk(
        s.theirs,
        inTree: codec._treeFor(s.other.type),
        ids: w.itemIds,
      );
      out.add(
        'Also in ${_link(w.headingId, there.anchor, s.other)}, ${note(s)}',
      );
    }
    final item = _itemParts(path);
    if (item != null) {
      final listPattern = _listPatternOf(pattern);
      final s = sharedListSide(listPattern, item.$1);
      if (s != null) {
        final rel = listPattern.substring(s.mine.length);
        final there = walk(
          '${s.theirs}$rel-*',
          inTree: codec._treeFor(s.other.type),
          ids: w.itemIds,
        );
        out.add(
          'Also in ${_link(w.headingId, there.anchor, s.other)}, ${note(s)}',
        );
      }

      // Summary of (@SummaryOf on the list).
      final summary = summaryOfList(item.$1);
      if (summary != null) {
        final links = _summaryTargets(path, item.$1, w.headingId, summary);
        if (links.isNotEmpty) out.add('Summary of ${links.join(', ')}');
      }

      // Summarised in: the summary elements of this document naming it.
      final named = summaryLinks['${item.$1}#${w.headingId}'];
      if (named != null) out.add('Summarised in ${named.join(', ')}');
    }

    // Derived from.
    final derived = _derivedSources(path, node, sectionTable: sectionTable);
    if (derived.isNotEmpty) {
      final links = <String>[];
      final fields = <String>[];
      for (final (link, field) in derived) {
        if (link != null && !links.contains(link)) links.add(link);
        if (field != null && !fields.contains(field)) fields.add(field);
      }
      if (links.isNotEmpty) {
        out.add(
          'Derived from ${links.join(', ')}'
          '${fields.isEmpty ? '' : ': ${fields.join(', ')}'}',
        );
      }
    }

    // Extracted from (@ExtractsLinks, generate).
    if (node.kind == SomMetaKind.list) {
      final from = _extractFrom(path);
      if (from.isNotEmpty) out.add('Extracted from ${from.join(', ')}');
    }

    // Copy of / Copied to (@SameAs).
    for (final b in sameAs) {
      if (b.copyPath != pattern || b.holderPath == null) continue;
      final h = walk(b.holderPath!, d: doc, ids: w.itemIds);
      out.add('Copy of ${_link(h.headingId, h.anchor)}, edit it there');
    }
    final copies = [
      for (final b in sameAs)
        if (b.holderPath == pattern) b,
    ];
    if (copies.isNotEmpty) {
      out.add(
        'Copied to ${[for (final b in copies) () {
            final c = walk(b.copyPath, d: doc, ids: w.itemIds);
            return _link(c.headingId, c.anchor);
          }()].join(', ')}',
      );
    }
    return out;
  }

  /// `<detail list path>#<element id>` → the links to the summary elements
  /// of this document naming that element, in document order.
  late final Map<String, List<String>> summaryLinks = () {
    final out = <String, List<String>>{};
    final summaries = {for (final lists in detailLists.values) ...lists};
    for (final summaryList in summaries) {
      for (final concrete in specExpandPattern(doc, summaryList)) {
        final s = summaryOfList(concrete);
        if (s == null) continue;
        final owner = concrete.substring(0, concrete.lastIndexOf('/'));
        final r = specResolveLinkPlace(refl, doc, s.detail, rootSeg, owner);
        if (r == null) continue;
        final detail = cutPattern(r.path);
        for (final e in doc.listItems(concrete)) {
          final ew = walk(e, d: doc);
          for (final id in _summaryIds(e, s, ew.headingId)) {
            final links = out['$detail#$id'] ??= [];
            final link = _link(ew.headingId, ew.anchor);
            if (!links.contains(link)) links.add(link);
          }
        }
      }
    }
    return out;
  }();

  /// The ids summary element [element] names: its `match` field's ids, else
  /// its own [ownId].
  List<String> _summaryIds(String element, SpecSummaryOf s, String ownId) {
    final match = s.match;
    if (match == null) return [ownId];
    final r = specResolvePlaceAt(refl, match, element);
    if (r == null || r.field == null) return const [];
    final raw = doc.formField(r.path, r.field!);
    if (raw == null) return const [];
    return [
      for (final id in raw.split(','))
        if (id.trim().isNotEmpty) id.trim(),
    ];
  }

  /// The `Summary of` links of summary element [element] of [listPath].
  List<String> _summaryTargets(
    String element,
    String listPath,
    String ownId,
    SpecSummaryOf s,
  ) => [
    for (final (id, anchor, other) in summaryTargets(
      element,
      listPath,
      ownId,
      s,
    ))
      _link(id, anchor, other),
  ];

  /// The detail elements summary element [element] of [listPath] names: each
  /// id, its anchor and the other root it is in (null: this document).
  List<(String, String, SpecRoot?)> summaryTargets(
    String element,
    String listPath,
    String ownId,
    SpecSummaryOf s,
  ) {
    final ids = _summaryIds(element, s, ownId);
    if (ids.isEmpty) return const [];
    final owner = listPath.substring(0, listPath.lastIndexOf('/'));
    if (_sameDocument(s)) {
      final r = specResolveLinkPlace(refl, doc, s.detail, rootSeg, owner);
      if (r == null) return const [];
      final list = cutPattern(r.path);
      return [
        for (final id in ids)
          (id, walk('$list-*', d: doc, ids: [id]).anchor, null),
      ];
    }
    final other = model.roots.where((r) => r.type == s.document).firstOrNull;
    if (other == null) return const [];
    final r = specResolveLinkPlace(
      refl,
      null,
      s.detail,
      refl.rootSegment(other),
      refl.rootSegment(other),
    );
    return [
      for (final id in ids)
        (
          id,
          r == null || r.path.contains('-*')
              ? id
              : walk(
                  '${r.path}-*',
                  inTree: codec._treeFor(other.type),
                  ids: [id],
                ).anchor,
          other,
        ),
    ];
  }

  /// The `Id` cell of a records row standing for summary element [item] of
  /// [listPath] whose `@SummaryOf` has no `match` (SOM §11.5, §11.11): its
  /// anchor, then its id as a link to the detail element it names. Null when
  /// the list is no such summary.
  String? summaryIdCell(String item, String listPath, String id) {
    final s = summaryOfList(listPath);
    if (s == null || s.match != null) return null;
    final targets = summaryTargets(item, listPath, id, s);
    if (targets.isEmpty) return null;
    final (_, anchor, other) = targets.single;
    final href = other == null
        ? '#$anchor'
        : '${codec._fileOfRoot(other)}#$anchor';
    return '<a id="${anchorOf(item)}"></a>[$id]($href)';
  }

  /// The derived values at the heading [path]: (a link to a source, or null;
  /// the derived field's name, or null for a derived section) per source.
  /// [probe]: answer whether there is any, structurally (no links built).
  List<(String?, String?)> _derivedSources(
    String path,
    SomMetaNode node, {
    bool probe = false,
    bool sectionTable = false,
  }) {
    final out = <(String?, String?)>[];
    String? linkTo(String target) {
      final t = walk(cutPattern(target), d: doc);
      return _link(t.headingId, t.anchor);
    }

    String? source(String place, String owner) {
      if (probe) return null;
      final r = specResolveLinkPlace(refl, doc, place, rootSeg, owner);
      return r == null ? null : linkTo(r.path);
    }

    void form(String formPath, SomMetaNode formNode, String? prefix) {
      final owner = formPath.substring(0, formPath.lastIndexOf('/'));
      final spec = refl.resolve(formPath)?.field;
      for (final ff in spec?.formFields ?? const <FormFieldSpec>[]) {
        final name = prefix == null ? ff.name : '$prefix.${ff.name}';
        final d = ff.derivedFrom;
        if (d != null) out.add((source(d.source, owner), name));
        for (final t in ff.countOf) {
          final f = SpecPlaceFilter.tryParse(t);
          if (f == null) continue;
          out.add((
            source(f.scoped ? './${f.sectionId}' : f.sectionId, owner),
            name,
          ));
        }
        for (final operand in ff.productOf) {
          final dot = operand.indexOf('.');
          out.add((
            probe
                ? null
                : linkTo(
                    dot < 0 ? formPath : '$owner/${operand.substring(0, dot)}',
                  ),
            name,
          ));
        }
        if (ff.rankOf != null) {
          final item = _itemParts(owner);
          out.add((probe ? null : linkTo(item?.$1 ?? formPath), name));
        }
      }
    }

    // A member carrying `@DerivedFrom`: [name] for one written in its
    // owner's body (no heading of its own), null for the heading itself.
    void member(String memberPath, String? name) {
      final d = refl.resolve(memberPath)?.field?.derivedFrom;
      if (d == null) return;
      final owner = memberPath.substring(0, memberPath.lastIndexOf('/'));
      out.add((source(d.source, owner), name));
    }

    final isItem = _itemParts(path) != null;
    if (node.kind == SomMetaKind.form) form(path, node, null);
    if (!isItem && path.contains('/')) member(path, null);
    if (node.kind == SomMetaKind.section ||
        node.kind == SomMetaKind.complex ||
        isItem) {
      for (final (slot, rel) in codec._bodySlots(node)) {
        final slotPath = '$path/$rel';
        if (slot.kind == SomMetaKind.form) {
          form(slotPath, slot, null);
        } else {
          member(slotPath, slot.memberName ?? slot.segment);
        }
      }
      if (sectionTable || probe) {
        for (final (child, rel) in codec._effectiveChildren(node)) {
          if (child.kind != SomMetaKind.form) continue;
          if (probe || doc.hasValuesUnder('$path/$rel')) {
            form('$path/$rel', child, codec._headingIdOf(child));
          }
        }
      }
    }
    return out;
  }

  /// The `Extracted from` links of the link-row list at [path]: the text
  /// places of its `@ExtractsLinks` in `generate` mode.
  List<String> _extractFrom(String path) {
    final f = refl.resolve(path)?.field;
    if (f == null) return const [];
    final owner = path.substring(0, path.lastIndexOf('/'));
    final out = <String>[];
    for (final e in f.extractsLinks) {
      if (e.mode != 'generate') continue;
      for (final place in e.from) {
        final r = specResolveLinkPlace(refl, doc, place, rootSeg, owner);
        if (r == null) continue;
        final t = walk(cutPattern(r.path), d: doc);
        final link = _link(t.headingId, t.anchor);
        if (!out.contains(link)) out.add(link);
      }
    }
    return out;
  }
}

/// Whether [paragraph] is exactly one span of kind `linked`.
bool _isLinkedParagraph(String paragraph) {
  final text = paragraph.trim();
  if (!text.startsWith('[') || !text.endsWith('{.linked}')) return false;
  final scan = scanNotation(text);
  if (scan.elements.length != 1) return false;
  final e = scan.elements.single;
  return e.type == NotationElementType.span &&
      e.kind == 'linked' &&
      e.start == 0 &&
      e.end == text.length;
}

/// [markdown] with every placeholder resolved: `[]{.linked}` where the
/// paragraph after it is a `linked` span, else removed with its blank line.
String _resolveLinkedPlaceholders(String markdown) {
  if (!markdown.contains(_kLinkedPlaceholder)) return markdown;
  final lines = markdown.split('\n');
  final out = <String>[];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i] != _kLinkedPlaceholder) {
      out.add(lines[i]);
      continue;
    }
    // The placeholder, its blank line, then the paragraph that follows.
    var k = i + 1;
    while (k < lines.length && lines[k].trim().isEmpty) {
      k++;
    }
    final para = <String>[];
    for (var j = k; j < lines.length && lines[j].trim().isNotEmpty; j++) {
      para.add(lines[j]);
    }
    if (para.isNotEmpty && _isLinkedParagraph(para.join('\n'))) {
      out.add('[]{.linked}');
    } else {
      i++; // the blank line after the placeholder goes with it
    }
  }
  return out.join('\n');
}
