import 'dart:io';

import 'spec_document_markdown.dart';
import 'spec_document_yaml.dart';
import 'spec_meta.dart';
import 'spec_model.dart';
import 'spec_section_id.dart';

/// A sparse, live instance of a TomSpecs document
/// (tom_specs_editor_specification.md §8, §13).
///
/// The structure is defined by the `SpecModel` class graph; this holds only the
/// *values* the user/agent has actually set, keyed by the globally-unique
/// section-ID path (D3). Nothing is materialised until written, so an untouched
/// document is empty (matching the "empty = no value" rule, D4).
///
/// Four sparse stores cover the writable field kinds:
///   * [_content] — `content`/`scalar` leaves: path → string value.
///   * [_form] — `@Form` sections: path → (form-field name → value).
///   * [_listItems] — lists: list path → ordered item paths.
///   * [_headline] — stored headlines (YRD3): any section path → the headline
///     the document actually renders/rendered. Sparse like content: unset means
///     "use the effective default" (`@Headline` default, else name derivation).
///
/// List item paths are `"$listPath-$seq"` where `seq` is a per-list monotonic
/// counter ([_listSeq]). The counter never reuses a number, so a path is stable
/// for the item's lifetime and never silently re-points after a removal — the
/// `-1`, `-2` suffixes in the spec are these sequence numbers (D3).
///
/// Each list item also carries a **section id** (AA1 criteria 3–6): the
/// document-semantic identity generated from the list field's
/// `@SectionIdPattern` (prefix + two-letter-date + within-day number, see
/// [generateListItemSectionId]). This is distinct from the internal `-$seq`
/// path key: the seq path keeps nested values attached across edits (never
/// renumbered), while the section id is what the document exposes and may be
/// overridden ([setItemSectionId], criterion 5) or reused same-day after the
/// last item is deleted (criterion 6). Section ids live in [_itemSectionId],
/// keyed by the internal item path.
class SpecDocument {
  /// An optional host-supplied **storage-key normalizer**: every path entering
  /// this store is passed through it before a map is touched.
  ///
  /// The store itself is route-agnostic — it knows nothing about how a host
  /// arrived at a path. A host whose object model reaches the *same* section
  /// along several routes (the TomSpecs editor's projection roots, see
  /// tom_specs_editor_specification.md §14) installs a normalizer that folds
  /// those routes onto the one storage path, so an edit made along any route
  /// mutates the identical entry. Unset means identity — the store keys by the
  /// path it is given, which is what every non-projecting host wants.
  ///
  /// The normalizer must be **idempotent** (`f(f(p)) == f(p)`) and
  /// **prefix-preserving** — `f` maps a subtree onto a subtree, so
  /// `f('$p/$rest')` starts with `f(p)`. [hasValuesUnder] and [_purgeUnder] are
  /// prefix scans over normalized keys; a normalizer that broke either property
  /// would silently break the emptiness/purge invariant.
  ///
  /// Install it with [installPathNormalizer], which also migrates whatever the
  /// store already holds.
  String Function(String path)? get pathNormalizer => _pathNormalizer;

  String Function(String path)? _pathNormalizer;

  /// Installs [normalizer] as the storage-key normalizer and **re-keys every
  /// value already held** onto the normalized keys.
  ///
  /// The migration matters because a host whose normalizer is derived from an
  /// asynchronously-resolved model (the TomSpecs editor's projection mapping,
  /// which needs the loaded object model) cannot install it at construction:
  /// edits made in the gap are keyed raw and would become unreachable the moment
  /// the normalizer arrived. Re-keying here folds them in instead.
  ///
  /// Where two raw keys collapse onto one, the first in sorted-key order wins —
  /// a normalizer folds *routes to the same section*, so the loser is a
  /// duplicate of the winner, not a distinct value.
  void installPathNormalizer(String Function(String path) normalizer) {
    _pathNormalizer = normalizer;
    _migrate(_content, normalizer);
    _migrate(_form, normalizer);
    _migrate(_itemSectionId, normalizer);
    _migrate(_headline, normalizer);
    _migrate(_codeSpec, normalizer);
    // List item paths are keys in their own right, so they move with their list.
    _migrate(_listItems, normalizer);
    for (final items in _listItems.values) {
      for (var i = 0; i < items.length; i++) {
        items[i] = normalizer(items[i]);
      }
    }
    // The seq counter merges by **max**, not first-wins: it is the high-water
    // mark that keeps [addListItem] from re-issuing a path a deleted item once
    // held, so two folded lists must not lose the higher of their two marks.
    final seqs = <String, int>{};
    for (final e in _listSeq.entries) {
      final key = normalizer(e.key);
      final held = seqs[key];
      if (held == null || e.value > held) seqs[key] = e.value;
    }
    _listSeq
      ..clear()
      ..addAll(seqs);
  }

  /// Re-keys [map] in place through [normalizer], first-in-sorted-order winning
  /// a collision.
  void _migrate<V>(Map<String, V> map, String Function(String) normalizer) {
    final migrated = <String, V>{};
    for (final key in map.keys.toList()..sort()) {
      migrated.putIfAbsent(normalizer(key), () => map[key] as V);
    }
    map
      ..clear()
      ..addAll(migrated);
  }

  /// [path] as this store keys it (see [pathNormalizer]; identity when unset).
  String _key(String path) => _pathNormalizer?.call(path) ?? path;

  final Map<String, String> _content = {};
  final Map<String, Map<String, String>> _form = {};
  final Map<String, List<String>> _listItems = {};
  final Map<String, int> _listSeq = {};
  final Map<String, String> _itemSectionId = {};
  final Map<String, String> _headline = {};

  /// The concrete instance-level forward DocSpecs→CodeSpecs link
  /// (codespecs_mapping.md §9.2): any section path → the comma-joined list of
  /// CodeSpecs code locations that section maps to. Sparse like [_headline]:
  /// unset means "no code mapping".
  final Map<String, String> _codeSpec = {};

  /// The authoring object-model version (`major.minor`) this document was loaded
  /// from, or `null` for a brand-new / unstamped document. Retained here by
  /// [fromYaml] so a consumer need not thread `decoded.modelVersion` to the
  /// typed facade by hand (the "forgot the stamp" class of bug); the generated
  /// `loadYaml` / `loadFile` statics apply it automatically.
  String? modelVersion;

  /// Loads a hierarchical-v2 `*.docspecs.yaml` document in one call: decode
  /// the YAML against [tree] (the metadata tree of the document's root),
  /// populate the sparse stores, and retain the parsed [modelVersion] on the
  /// document. Throws [SpecYamlFormatException] for version-1 files or
  /// structurally invalid keys (see [SpecDocumentYaml.decode]).
  static SpecDocument fromYaml(String yaml, SomMetaTree tree) =>
      SpecDocumentYaml.decode(yaml, tree).document;

  /// Loads a `*.docspecs.yaml` document from the file at [path] — the file
  /// companion to [fromYaml] the generated `loadFile` static delegates to.
  static SpecDocument fromFile(String path, SomMetaTree tree) =>
      fromYaml(File(path).readAsStringSync(), tree);

  /// Renders this document to Markdown in one call (SOM §21).
  ///
  /// Collapses the former `SpecDocumentMarkdown(model, doc).exportRoot(
  /// model.roots.firstWhere((r) => r.type == …))` incantation. When [rootType]
  /// is given, that root is exported (via [SpecModel.rootByType]); when omitted,
  /// the document's single **populated** root is used — a root is populated when
  /// it has any value beneath its segment ([hasValuesUnder]). Throws
  /// [StateError] when the default is ambiguous — zero populated roots, or more
  /// than one — so the caller names the [rootType] explicitly.
  String toMarkdown(SpecModel model, {String? rootType}) {
    final root = rootType != null
        ? model.rootByType(rootType)
        : _singlePopulatedRoot(model);
    return SpecDocumentMarkdown(model, this).exportRoot(root);
  }

  /// The one root under which this document holds any value, for [toMarkdown]'s
  /// default. Throws [StateError] when zero or more than one root is populated.
  SpecRoot _singlePopulatedRoot(SpecModel model) {
    final populated = [
      for (final r in model.roots)
        if (hasValuesUnder(r.sectionId ?? r.type)) r,
    ];
    if (populated.length == 1) return populated.single;
    if (populated.isEmpty) {
      throw StateError('document has no populated root to export; '
          'pass rootType to choose one');
    }
    throw StateError('document has ${populated.length} populated roots '
        '(${populated.map((r) => r.type).join(', ')}); '
        'pass rootType to choose one');
  }

  /// The content string at [path], or `null` if unset.
  String? content(String path) => _content[_key(path)];

  /// Whether a non-empty `content`/`scalar` leaf value exists at exactly
  /// [path] — the null-free companion to [content] (SOM §21).
  ///
  /// This is the one shared definition of "is this content leaf filled?": the
  /// typed facade's `.content` getter coalesces a missing value to `''` while
  /// the generic [content] returns `null`, so a consumer asking "is this
  /// section filled?" gets different-looking answers depending on the path.
  /// Routing both through [hasContent] removes that divergence — it is `true`
  /// exactly when [content] would return a non-empty string.
  bool hasContent(String path) => (_content[_key(path)] ?? '').isNotEmpty;

  /// Sets the content string at [path]. An empty value clears it (D4).
  void setContent(String path, String value) {
    final key = _key(path);
    if (value.isEmpty) {
      _content.remove(key);
    } else {
      _content[key] = value;
    }
  }

  /// The stored headline at [path], or `null` when the section renders its
  /// effective default title (YRD3 — headlines are sparse like content).
  String? headline(String path) => _headline[_key(path)];

  /// Sets the stored headline at [path]. An empty value clears it, returning
  /// the section to its effective default title (YRD3).
  void setHeadline(String path, String value) {
    final key = _key(path);
    if (value.isEmpty) {
      _headline.remove(key);
    } else {
      _headline[key] = value;
    }
  }

  /// All section paths currently carrying a stored headline (unordered
  /// snapshot).
  Iterable<String> get headlinePaths => _headline.keys;

  /// The stored codeSpec mapping at [path] as the comma-joined list of
  /// CodeSpecs code locations, or `null` when the section carries no mapping
  /// (codespecs_mapping.md §9.2 — codeSpec is sparse like the headline).
  String? codeSpec(String path) => _codeSpec[_key(path)];

  /// Sets the stored codeSpec mapping at [path] (the comma-joined list of
  /// CodeSpecs code locations). An empty value clears it, returning the section
  /// to "no code mapping" (codespecs_mapping.md §9.2).
  void setCodeSpec(String path, String value) {
    final key = _key(path);
    if (value.isEmpty) {
      _codeSpec.remove(key);
    } else {
      _codeSpec[key] = value;
    }
  }

  /// All section paths currently carrying a stored codeSpec mapping (unordered
  /// snapshot).
  Iterable<String> get codeSpecPaths => _codeSpec.keys;

  /// The value of form [field] at [path], or `null` if unset.
  String? formField(String path, String field) => _form[_key(path)]?[field];

  /// Sets form [field] at [path]. An empty value clears that field (and the
  /// whole form entry once its last field is gone).
  void setFormField(String path, String field, String value) {
    final key = _key(path);
    final fields = _form.putIfAbsent(key, () => {});
    if (value.isEmpty) {
      fields.remove(field);
      if (fields.isEmpty) _form.remove(key);
    } else {
      fields[field] = value;
    }
  }

  /// The ordered item paths of the list at [listPath] (empty if none).
  ///
  /// The returned item paths are **storage paths** (see [pathNormalizer]) — the
  /// caller can feed them straight back into this store, and a normalizer is
  /// idempotent so re-normalizing them is a no-op.
  List<String> listItems(String listPath) =>
      List.unmodifiable(_listItems[_key(listPath)] ?? const []);

  /// Appends a new item to the list at [listPath] and returns its stable path.
  ///
  /// When [sectionId] is given it becomes the item's section id after a
  /// uniqueness check against the list's other items (AA1 criterion 5); a
  /// collision raises [SpecSectionIdCollision]. Section-id *generation* from a
  /// `@SectionIdPattern` lives in the caller (it needs the pattern); this layer
  /// only stores and guards uniqueness.
  String addListItem(String listPath, {String? sectionId}) {
    final key = _key(listPath);
    if (sectionId != null) _assertSectionIdFree(key, sectionId, null);
    final seq = (_listSeq[key] ?? 0) + 1;
    _listSeq[key] = seq;
    final itemPath = '$key-$seq';
    _listItems.putIfAbsent(key, () => []).add(itemPath);
    if (sectionId != null) _itemSectionId[itemPath] = sectionId;
    return itemPath;
  }

  /// The section id assigned to the list item at [itemPath], or `null` if none
  /// has been set (AA1 criterion 1 read path).
  String? itemSectionId(String itemPath) => _itemSectionId[_key(itemPath)];

  /// Overrides the section id of the list item at [itemPath] (AA1 criterion 5).
  ///
  /// Validates that the new [id] is unique among the *other* items of the same
  /// owning list; a collision raises [SpecSectionIdCollision]. Assigning an id
  /// equal to the item's current id is a no-op. Throws [ArgumentError] if
  /// [itemPath] is not a live list item.
  void setItemSectionId(String itemPath, String id) {
    final key = _key(itemPath);
    final owningList = _owningListOf(key);
    if (owningList == null) {
      throw ArgumentError.value(
          itemPath, 'itemPath', 'not a live list item');
    }
    if (_itemSectionId[key] == id) return;
    _assertSectionIdFree(owningList, id, key);
    _itemSectionId[key] = id;
  }

  /// The section ids currently assigned within the list at [listPath], in item
  /// order (items without an id are skipped). Feeds both id generation
  /// (`existingIds`) and uniqueness checks.
  List<String> listItemSectionIds(String listPath) => [
        for (final itemPath in _listItems[_key(listPath)] ?? const [])
          if (_itemSectionId[itemPath] != null) _itemSectionId[itemPath]!,
      ];

  /// The internal `_listItems` entry that owns [itemPath], or `null`.
  String? _owningListOf(String itemPath) {
    for (final entry in _listItems.entries) {
      if (entry.value.contains(itemPath)) return entry.key;
    }
    return null;
  }

  /// Throws [SpecSectionIdCollision] if [id] is already used by an item of
  /// [listPath] other than [exceptItemPath].
  void _assertSectionIdFree(
      String listPath, String id, String? exceptItemPath) {
    for (final itemPath in _listItems[listPath] ?? const []) {
      if (itemPath == exceptItemPath) continue;
      if (_itemSectionId[itemPath] == id) {
        throw SpecSectionIdCollision(id, listPath);
      }
    }
  }

  /// Removes the list item at [itemPath] along with every value nested beneath
  /// it. Returns `true` if an item was found and removed.
  ///
  /// The owning list is the entry in [_listItems] that contains [itemPath]; the
  /// counter is deliberately left untouched so future items keep getting fresh
  /// sequence numbers (no renumbering — D3).
  bool removeListItem(String itemPath) {
    final key = _key(itemPath);
    final owningList = _owningListOf(key);
    if (owningList == null) return false;
    _listItems[owningList]!.remove(key);
    if (_listItems[owningList]!.isEmpty) _listItems.remove(owningList);
    _purgeUnder(key);
    return true;
  }

  /// Drops every content/form/list value at [prefix] or nested under it
  /// (`"$prefix/…"` for descendants, `"$prefix-…"` for the item's own lists).
  ///
  /// [prefix] must already be a **storage key** — every caller normalizes
  /// first, because the scan is a raw prefix match over the stores.
  void _purgeUnder(String prefix) {
    bool isUnder(String key) =>
        key == prefix ||
        key.startsWith('$prefix/') ||
        key.startsWith('$prefix-');
    _content.removeWhere((k, _) => isUnder(k));
    _form.removeWhere((k, _) => isUnder(k));
    _listItems.removeWhere((k, _) => isUnder(k));
    _listSeq.removeWhere((k, _) => isUnder(k));
    _itemSectionId.removeWhere((k, _) => isUnder(k));
    _headline.removeWhere((k, _) => isUnder(k));
    _codeSpec.removeWhere((k, _) => isUnder(k));
  }

  /// Drops every value at [prefix] or nested beneath it — content, form
  /// entries, list items (with their nested values, ids and counters), and
  /// stored headlines (YRD7 generic modification API: "clear section").
  ///
  /// The predicate is the same one [hasValuesUnder] uses, so after this call
  /// `hasValuesUnder(prefix)` is `false`. Note this clears *values under a
  /// section path*; removing a single list item from its owning list is
  /// [removeListItem].
  void removeValuesUnder(String prefix) => _purgeUnder(_key(prefix));

  /// Whether the document holds no values at all.
  bool get isEmpty =>
      _content.isEmpty &&
      _form.isEmpty &&
      _listItems.isEmpty &&
      _headline.isEmpty &&
      _codeSpec.isEmpty;

  /// Whether any value exists at [prefix] or nested beneath it — the structural
  /// "empty = no value" test (tom_specs_editor_specification.md §13.1, D4).
  ///
  /// A node's path is the prefix; a value counts when its key is the path
  /// itself (a `content`/`scalar`/`enum` leaf or a `@Form` entry), a descendant
  /// (`"$prefix/…"` for a complex/section child), or a list item of the node
  /// (`"$prefix-…"`). This is the exact inverse of the predicate [_purgeUnder]
  /// uses, so emptiness and purge stay in lock-step.
  ///
  /// The scan runs in **storage space**: [prefix] is normalized first, and a
  /// [pathNormalizer] is required to be prefix-preserving, so a subtree of the
  /// caller's paths is still a subtree of the keys held here.
  bool hasValuesUnder(String prefix) {
    final root = _key(prefix);
    bool isUnder(String key) =>
        key == root || key.startsWith('$root/') || key.startsWith('$root-');
    return _content.keys.any(isUnder) ||
        _form.keys.any(isUnder) ||
        _listItems.keys.any(isUnder) ||
        _headline.keys.any(isUnder) ||
        _codeSpec.keys.any(isUnder);
  }

  /// All content-leaf paths currently set (unordered snapshot).
  Iterable<String> get contentPaths => _content.keys;

  /// All `@Form`-section paths currently set (unordered snapshot).
  Iterable<String> get formPaths => _form.keys;

  /// All list-container paths currently holding items (unordered snapshot).
  Iterable<String> get listPaths => _listItems.keys;

  /// The form-field names currently set at [path] (unordered snapshot, empty
  /// when no form entry exists there).
  Iterable<String> formFieldNames(String path) =>
      _form[_key(path)]?.keys ?? const [];

  /// The number of items currently held by the list at [listPath].
  int listItemCount(String listPath) => _listItems[_key(listPath)]?.length ?? 0;

  /// A plain-data view of every value held, for persistence
  /// (tom_specs_editor_specification.md §15.1 `document:` pass). Only non-empty
  /// stores are included, and each is sorted by full section-ID path so the
  /// saved file diffs/merges cleanly. The shape is the inverse of [loadJson]:
  ///
  /// ```
  /// {
  ///   content:   { "<path>": "<value>", ... },
  ///   forms:     { "<path>": { "<field>": "<value>", ... }, ... },
  ///   lists:     { "<path>": { seq: <int>, items: ["<path-1>", ...] }, ... },
  ///   headlines: { "<path>": "<stored headline>", ... },
  ///   codeSpecs: { "<path>": "<comma-joined code locations>", ... },
  /// }
  /// ```
  ///
  /// The list `seq` is the monotonic counter ([_listSeq]); persisting it keeps
  /// item paths from colliding after a load→add (D3 stability survives a save).
  Map<String, Object?> toJson() {
    List<String> sorted(Iterable<String> keys) => keys.toList()..sort();
    return {
      if (_content.isNotEmpty)
        'content': {for (final k in sorted(_content.keys)) k: _content[k]},
      if (_form.isNotEmpty)
        'forms': {
          for (final k in sorted(_form.keys))
            k: {for (final f in sorted(_form[k]!.keys)) f: _form[k]![f]},
        },
      if (_listItems.isNotEmpty)
        'lists': {
          for (final k in sorted(_listItems.keys))
            k: {
              'seq': _listSeq[k] ?? _listItems[k]!.length,
              'items': List.of(_listItems[k]!),
              if (_listItems[k]!.any(_itemSectionId.containsKey))
                'ids': {
                  for (final itemPath in _listItems[k]!)
                    if (_itemSectionId.containsKey(itemPath))
                      itemPath: _itemSectionId[itemPath],
                },
            },
        },
      if (_headline.isNotEmpty)
        'headlines': {
          for (final k in sorted(_headline.keys)) k: _headline[k],
        },
      if (_codeSpec.isNotEmpty)
        'codeSpecs': {
          for (final k in sorted(_codeSpec.keys)) k: _codeSpec[k],
        },
    };
  }

  /// Replaces every store from a [toJson]-shaped map
  /// (tom_specs_editor_specification.md §15.1 load pass). Tolerant of the YAML
  /// parser's `Map`/`List` views and coerces leaf values to strings (block
  /// scalars always parse back as strings). Unknown/empty entries are skipped
  /// so a hand-edited file can't smuggle in malformed state.
  void loadJson(Map<dynamic, dynamic> json) {
    _content.clear();
    _form.clear();
    _listItems.clear();
    _listSeq.clear();
    _itemSectionId.clear();
    _headline.clear();
    _codeSpec.clear();

    final content = json['content'];
    if (content is Map) {
      content.forEach((k, v) {
        if (v != null) _content['$k'] = '$v';
      });
    }

    final forms = json['forms'];
    if (forms is Map) {
      forms.forEach((k, fields) {
        if (fields is Map) {
          final entry = <String, String>{};
          fields.forEach((f, v) {
            if (v != null) entry['$f'] = '$v';
          });
          if (entry.isNotEmpty) _form['$k'] = entry;
        }
      });
    }

    final lists = json['lists'];
    if (lists is Map) {
      lists.forEach((k, spec) {
        if (spec is Map) {
          final items = spec['items'];
          final list = <String>[];
          if (items is List) {
            for (final it in items) {
              list.add('$it');
            }
          }
          if (list.isNotEmpty) _listItems['$k'] = list;
          final seq = spec['seq'];
          _listSeq['$k'] = seq is int
              ? seq
              : (seq is String ? int.tryParse(seq) ?? list.length : list.length);
          final ids = spec['ids'];
          if (ids is Map) {
            ids.forEach((itemPath, id) {
              if (id != null) _itemSectionId['$itemPath'] = '$id';
            });
          }
        }
      });
    }

    final headlines = json['headlines'];
    if (headlines is Map) {
      headlines.forEach((k, v) {
        if (v != null && '$v'.isNotEmpty) _headline['$k'] = '$v';
      });
    }

    final codeSpecs = json['codeSpecs'];
    if (codeSpecs is Map) {
      codeSpecs.forEach((k, v) {
        if (v != null && '$v'.isNotEmpty) _codeSpec['$k'] = '$v';
      });
    }
  }

  /// A deep-copied snapshot of the whole document, for the undo stack
  /// (tom_specs_editor_specification.md §10).
  ///
  /// Every map is copied so the returned state is independent of subsequent
  /// edits — restoring it returns the document to exactly this picture.
  SpecDocumentState captureState() => SpecDocumentState._(
        content: Map.of(_content),
        form: {for (final e in _form.entries) e.key: Map.of(e.value)},
        listItems: {for (final e in _listItems.entries) e.key: List.of(e.value)},
        listSeq: Map.of(_listSeq),
        itemSectionId: Map.of(_itemSectionId),
        headline: Map.of(_headline),
        codeSpec: Map.of(_codeSpec),
      );

  /// Replaces the document's contents with a previously [captureState]d
  /// snapshot (tom_specs_editor_specification.md §10). The restore is absolute:
  /// every store is overwritten, so a snapshot can be applied regardless of
  /// intervening edits.
  void restoreState(SpecDocumentState state) {
    _content
      ..clear()
      ..addAll(state._content);
    _form
      ..clear()
      ..addAll({for (final e in state._form.entries) e.key: Map.of(e.value)});
    _listItems
      ..clear()
      ..addAll(
          {for (final e in state._listItems.entries) e.key: List.of(e.value)});
    _listSeq
      ..clear()
      ..addAll(state._listSeq);
    _itemSectionId
      ..clear()
      ..addAll(state._itemSectionId);
    _headline
      ..clear()
      ..addAll(state._headline);
    _codeSpec
      ..clear()
      ..addAll(state._codeSpec);
  }
}

/// An immutable deep-copied snapshot of a [SpecDocument]
/// (tom_specs_editor_specification.md §10 undo stack).
///
/// Produced by [SpecDocument.captureState] and consumed by
/// [SpecDocument.restoreState]; the maps are private so a state can only be
/// applied wholesale, never mutated in place.
class SpecDocumentState {
  final Map<String, String> _content;
  final Map<String, Map<String, String>> _form;
  final Map<String, List<String>> _listItems;
  final Map<String, int> _listSeq;
  final Map<String, String> _itemSectionId;
  final Map<String, String> _headline;
  final Map<String, String> _codeSpec;

  SpecDocumentState._({
    required Map<String, String> content,
    required Map<String, Map<String, String>> form,
    required Map<String, List<String>> listItems,
    required Map<String, int> listSeq,
    required Map<String, String> itemSectionId,
    required Map<String, String> headline,
    required Map<String, String> codeSpec,
  })  : _content = content,
        _form = form,
        _listItems = listItems,
        _listSeq = listSeq,
        _itemSectionId = itemSectionId,
        _headline = headline,
        _codeSpec = codeSpec;

  /// The content value at [path] as of this snapshot (the review's base pane).
  String? contentAt(String path) => _content[path];

  /// The form [field] value at [path] as of this snapshot.
  String? formFieldAt(String path, String field) => _form[path]?[field];

  /// A stable fingerprint of the snapshot's values, used to tell whether an
  /// edit actually changed anything (no-op edits must not snapshot,
  /// tom_specs_editor_specification.md §10).
  String get fingerprint {
    String enc(Map<String, Object?> m) {
      final keys = m.keys.toList()..sort();
      return [for (final k in keys) '$k=${m[k]}'].join('\u0001');
    }

    final formFlat = <String, Object?>{
      for (final e in _form.entries) e.key: enc(e.value),
    };
    final listFlat = <String, Object?>{
      for (final e in _listItems.entries) e.key: e.value.join(','),
    };
    return [
      enc(_content),
      enc(formFlat),
      enc(listFlat),
      enc(_itemSectionId),
      enc(_headline),
      enc(_codeSpec),
    ].join('\u0002');
  }
}
