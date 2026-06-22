/// A sparse, live instance of a TomSpecs document (§8, §13).
///
/// The structure is defined by the `SpecModel` class graph; this holds only the
/// *values* the user/agent has actually set, keyed by the globally-unique
/// section-ID path (D3). Nothing is materialised until written, so an untouched
/// document is empty (matching the "empty = no value" rule, D4).
///
/// Three sparse stores cover the writable field kinds:
///   * [_content] — `content`/`scalar` leaves: path → string value.
///   * [_form] — `@Form` sections: path → (form-field name → value).
///   * [_listItems] — lists: list path → ordered item paths.
///
/// List item paths are `"$listPath-$seq"` where `seq` is a per-list monotonic
/// counter ([_listSeq]). The counter never reuses a number, so a path is stable
/// for the item's lifetime and never silently re-points after a removal — the
/// `-1`, `-2` suffixes in the spec are these sequence numbers (D3).
class SpecDocument {
  final Map<String, String> _content = {};
  final Map<String, Map<String, String>> _form = {};
  final Map<String, List<String>> _listItems = {};
  final Map<String, int> _listSeq = {};

  /// The content string at [path], or `null` if unset.
  String? content(String path) => _content[path];

  /// Sets the content string at [path]. An empty value clears it (D4).
  void setContent(String path, String value) {
    if (value.isEmpty) {
      _content.remove(path);
    } else {
      _content[path] = value;
    }
  }

  /// The value of form [field] at [path], or `null` if unset.
  String? formField(String path, String field) => _form[path]?[field];

  /// Sets form [field] at [path]. An empty value clears that field (and the
  /// whole form entry once its last field is gone).
  void setFormField(String path, String field, String value) {
    final fields = _form.putIfAbsent(path, () => {});
    if (value.isEmpty) {
      fields.remove(field);
      if (fields.isEmpty) _form.remove(path);
    } else {
      fields[field] = value;
    }
  }

  /// The ordered item paths of the list at [listPath] (empty if none).
  List<String> listItems(String listPath) =>
      List.unmodifiable(_listItems[listPath] ?? const []);

  /// Appends a new item to the list at [listPath] and returns its stable path.
  String addListItem(String listPath) {
    final seq = (_listSeq[listPath] ?? 0) + 1;
    _listSeq[listPath] = seq;
    final itemPath = '$listPath-$seq';
    _listItems.putIfAbsent(listPath, () => []).add(itemPath);
    return itemPath;
  }

  /// Removes the list item at [itemPath] along with every value nested beneath
  /// it. Returns `true` if an item was found and removed.
  ///
  /// The owning list is the entry in [_listItems] that contains [itemPath]; the
  /// counter is deliberately left untouched so future items keep getting fresh
  /// sequence numbers (no renumbering — D3).
  bool removeListItem(String itemPath) {
    String? owningList;
    for (final entry in _listItems.entries) {
      if (entry.value.contains(itemPath)) {
        owningList = entry.key;
        break;
      }
    }
    if (owningList == null) return false;
    _listItems[owningList]!.remove(itemPath);
    if (_listItems[owningList]!.isEmpty) _listItems.remove(owningList);
    _purgeUnder(itemPath);
    return true;
  }

  /// Drops every content/form/list value at [prefix] or nested under it
  /// (`"$prefix/…"` for descendants, `"$prefix-…"` for the item's own lists).
  void _purgeUnder(String prefix) {
    bool isUnder(String key) =>
        key == prefix ||
        key.startsWith('$prefix/') ||
        key.startsWith('$prefix-');
    _content.removeWhere((k, _) => isUnder(k));
    _form.removeWhere((k, _) => isUnder(k));
    _listItems.removeWhere((k, _) => isUnder(k));
    _listSeq.removeWhere((k, _) => isUnder(k));
  }

  /// Whether the document holds no values at all.
  bool get isEmpty => _content.isEmpty && _form.isEmpty && _listItems.isEmpty;

  /// Whether any value exists at [prefix] or nested beneath it — the structural
  /// "empty = no value" test (§13.1, D4).
  ///
  /// A node's path is the prefix; a value counts when its key is the path
  /// itself (a `content`/`scalar`/`enum` leaf or a `@Form` entry), a descendant
  /// (`"$prefix/…"` for a complex/section child), or a list item of the node
  /// (`"$prefix-…"`). This is the exact inverse of the predicate [_purgeUnder]
  /// uses, so emptiness and purge stay in lock-step.
  bool hasValuesUnder(String prefix) {
    bool isUnder(String key) =>
        key == prefix ||
        key.startsWith('$prefix/') ||
        key.startsWith('$prefix-');
    return _content.keys.any(isUnder) ||
        _form.keys.any(isUnder) ||
        _listItems.keys.any(isUnder);
  }

  /// All content-leaf paths currently set (unordered snapshot).
  Iterable<String> get contentPaths => _content.keys;

  /// All `@Form`-section paths currently set (unordered snapshot).
  Iterable<String> get formPaths => _form.keys;

  /// All list-container paths currently holding items (unordered snapshot).
  Iterable<String> get listPaths => _listItems.keys;

  /// The form-field names currently set at [path] (unordered snapshot, empty
  /// when no form entry exists there).
  Iterable<String> formFieldNames(String path) => _form[path]?.keys ?? const [];

  /// The number of items currently held by the list at [listPath].
  int listItemCount(String listPath) => _listItems[listPath]?.length ?? 0;

  /// A plain-data view of every value held, for persistence (§15.1 `document:`
  /// pass). Only non-empty stores are included, and each is sorted by full
  /// section-ID path so the saved file diffs/merges cleanly. The shape is the
  /// inverse of [loadJson]:
  ///
  /// ```
  /// {
  ///   content: { "<path>": "<value>", ... },
  ///   forms:   { "<path>": { "<field>": "<value>", ... }, ... },
  ///   lists:   { "<path>": { seq: <int>, items: ["<path-1>", ...] }, ... },
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
            },
        },
    };
  }

  /// Replaces every store from a [toJson]-shaped map (§15.1 load pass). Tolerant
  /// of the YAML parser's `Map`/`List` views and coerces leaf values to strings
  /// (block scalars always parse back as strings). Unknown/empty entries are
  /// skipped so a hand-edited file can't smuggle in malformed state.
  void loadJson(Map<dynamic, dynamic> json) {
    _content.clear();
    _form.clear();
    _listItems.clear();
    _listSeq.clear();

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
        }
      });
    }
  }

  /// A deep-copied snapshot of the whole document, for the undo stack (§10).
  ///
  /// Every map is copied so the returned state is independent of subsequent
  /// edits — restoring it returns the document to exactly this picture.
  SpecDocumentState captureState() => SpecDocumentState._(
        content: Map.of(_content),
        form: {for (final e in _form.entries) e.key: Map.of(e.value)},
        listItems: {for (final e in _listItems.entries) e.key: List.of(e.value)},
        listSeq: Map.of(_listSeq),
      );

  /// Replaces the document's contents with a previously [captureState]d
  /// snapshot (§10). The restore is absolute: every store is overwritten, so a
  /// snapshot can be applied regardless of intervening edits.
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
  }
}

/// An immutable deep-copied snapshot of a [SpecDocument] (§10 undo stack).
///
/// Produced by [SpecDocument.captureState] and consumed by
/// [SpecDocument.restoreState]; the maps are private so a state can only be
/// applied wholesale, never mutated in place.
class SpecDocumentState {
  final Map<String, String> _content;
  final Map<String, Map<String, String>> _form;
  final Map<String, List<String>> _listItems;
  final Map<String, int> _listSeq;

  SpecDocumentState._({
    required Map<String, String> content,
    required Map<String, Map<String, String>> form,
    required Map<String, List<String>> listItems,
    required Map<String, int> listSeq,
  })  : _content = content,
        _form = form,
        _listItems = listItems,
        _listSeq = listSeq;

  /// The content value at [path] as of this snapshot (the review's base pane).
  String? contentAt(String path) => _content[path];

  /// The form [field] value at [path] as of this snapshot.
  String? formFieldAt(String path, String field) => _form[path]?[field];

  /// A stable fingerprint of the snapshot's values, used to tell whether an
  /// edit actually changed anything (no-op edits must not snapshot, §10).
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
    return [enc(_content), enc(formFlat), enc(listFlat)].join('\u0002');
  }
}
