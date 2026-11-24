part of 'spec_document_set.dart';

// ---------------------------------------------------------------------------
// backfill: the accepted end state of the Phase 3 documents, carried into the
// Blueprint
// ---------------------------------------------------------------------------

/// Why [backfill] refuses a set.
class SpecBackfillError implements Exception {
  /// `setHasMarks`: a document holds an inline mark or an annotation block;
  /// `noBlueprint`: the set has no Blueprint.
  final String code;

  /// The places holding them, in document order.
  final List<SpecSyncPlace> places;

  /// Prose for the reader.
  final String message;

  /// All parts are known where it is raised.
  const SpecBackfillError(this.code, this.places, this.message);

  /// The canonical JSON form (no message).
  Map<String, Object?> toJson() => {
    'code': code,
    'places': [for (final p in places) p.toJson()],
  };

  @override
  String toString() => 'SpecBackfillError($code): $message';
}

/// One place [backfill] wrote in the Blueprint.
class SpecBackfillChange {
  /// The pair the change belongs to; empty for the revision entry and the
  /// derived places written after it.
  final String pair;

  /// `value` (a value written or cleared), `elementAdded`, `elementRemoved`,
  /// `revision` (the history entry), `derived` (a derived place rewritten).
  final String kind;

  /// The value's path, or the element's.
  final String path;

  /// The form field ([kSpecHeadlineField] for a headline), or null.
  final String? field;

  /// The value before and after (for an element, its id after).
  final String oldValue, newValue;

  /// The parts of a change.
  const SpecBackfillChange({
    required this.pair,
    required this.kind,
    required this.path,
    this.field,
    this.oldValue = '',
    this.newValue = '',
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'pair': pair,
    'kind': kind,
    'path': path,
    if (field != null) 'field': field,
    'old': oldValue,
    'new': newValue,
  };
}

/// A finding [backfill] left, with the reason.
class SpecBackfillLeft {
  /// The finding.
  final SpecSyncFinding finding;

  /// `heldHere` (the Blueprint holds the value: the agent corrects the Phase
  /// 3 document), `mayBeAdded` (under `subset`, not carried in), or the
  /// finding's resolution (`agent`, `info`).
  final String reason;

  /// Both parts.
  const SpecBackfillLeft(this.finding, this.reason);

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'finding': finding.toJson(),
    'reason': reason,
  };
}

/// What [backfill] did.
class SpecBackfillResult {
  /// The Blueprint written: the set's own, or its copy on a dry run.
  final SpecDocument blueprint;

  /// Every place written, in the order written.
  final List<SpecBackfillChange> changes;

  /// Every finding in scope it did not resolve, with the reason.
  final List<SpecBackfillLeft> left;

  /// The parts of a result.
  const SpecBackfillResult({
    required this.blueprint,
    required this.changes,
    required this.left,
  });

  /// The canonical JSON form (the Blueprint as its stores).
  Map<String, Object?> toJson() => {
    'changes': [for (final c in changes) c.toJson()],
    'left': [for (final l in left) l.toJson()],
    'blueprint': blueprint.toJson(),
  };
}

/// Carries the end state of the Phase 3 documents into the Blueprint, as
/// plain values (DP-part-operations-2): for every shared place whose holder
/// is the Phase 3 document, the holder's value — a differing or missing
/// value written, a value the Phase 3 document emptied cleared, an element
/// only in the Phase 3 document added (with its stored section id, after its
/// nearest preceding neighbour the Blueprint holds, or first), an element
/// only in the Blueprint removed (DP-part-operations-3).
///
/// It leaves `detailOnly` places, a `heldHere` place the documents disagree
/// on (the agent corrects the Phase 3 document), an element that under
/// `subset` may be added, and every finding across two documents: each is
/// listed in [SpecBackfillResult.left] with the reason.
///
/// It refuses a set holding any inline mark or annotation block
/// ([SpecBackfillError], `setHasMarks`, the places named): it carries the end
/// state of an accepted review, never a review in progress. It writes only
/// the Blueprint; when it changed anything it adds one entry to the
/// Blueprint's revision history (the list of `RVENT` entries) naming the
/// pairs, by [author] on [date], and rewrites the Blueprint's derived places
/// (`deriveFields`, plain). [pairs] and [path] (a Blueprint path) scope it;
/// [dryRun] writes a copy. A second run right after the first writes nothing.
SpecBackfillResult backfill(
  SpecDocumentSet set, {
  Set<String>? pairs,
  String? path,
  bool dryRun = false,
  String? author,
  String? date,
}) {
  final bpRoot = set.blueprintRoot;
  final bpName = bpRoot == null ? null : set.nameOf(bpRoot);
  if (bpName == null) {
    throw const SpecBackfillError(
      'noBlueprint',
      [],
      'the set holds no Blueprint',
    );
  }
  final refl = set.refl;

  // No review in progress.
  final marked = <SpecSyncPlace>[];
  for (final name in set.names) {
    final doc = set[name]!;
    final root = refl.rootSegment(
      refl.model.roots.firstWhere((r) => r.type == set.rootOf(name)),
    );
    final seen = <String>{};
    for (final a in SpecReviewAnnotations(doc).list()) {
      if (!seen.add('${a.path}#${a.field ?? ''}')) continue;
      marked.add(
        SpecSyncPlace(document: name, root: root, path: a.path, field: a.field),
      );
    }
  }
  if (marked.isNotEmpty) {
    throw SpecBackfillError(
      'setHasMarks',
      marked,
      'the set holds ${marked.length} value(s) with inline marks or '
          'annotation blocks; backfill carries the end state of an accepted '
          'review, so decide them first',
    );
  }

  final target = dryRun
      ? (SpecDocument()..loadJson(set[bpName]!.toJson()))
      : set[bpName]!;
  final c = _SetCheck(set);
  var index = 0;
  for (final p in set.pairs) {
    if (pairs == null || pairs.contains(p.sectionId)) c.comparePair(p, index);
    index++;
  }
  // The links across two documents are the agent's; they are listed as left.
  c.crossChecks(pairs, index);
  c.out.sort((a, b) {
    final i = a.order.compareTo(b.order);
    if (i != 0) return i;
    final k = a.key.compareTo(b.key);
    return k != 0 ? k : a.finding.code.index.compareTo(b.finding.code.index);
  });
  bool inScope(SpecSyncFinding f) =>
      path == null ||
      f.blueprint.path == path ||
      f.blueprint.path.startsWith('$path/');

  final w = _Backfill(set, target, bpName);
  final left = <SpecBackfillLeft>[];
  final apply = <_Ordered>[];
  for (final o in c.out) {
    final f = o.finding;
    if (!inScope(f)) continue;
    if (f.resolution == SpecSyncResolution.backfill) {
      apply.add(o);
    } else {
      left.add(
        SpecBackfillLeft(
          f,
          f.holder == SpecSyncHolder.blueprint
              ? 'heldHere'
              : f.code == SpecSyncCode.sharedElementMayBeAdded
              ? 'mayBeAdded'
              : f.resolution.name,
        ),
      );
    }
  }
  w.apply(apply);
  if (w.changes.isNotEmpty) {
    w.revisionEntry(author ?? 'backfill', date ?? _today());
    for (final d in deriveFields(set.model, target, marked: false).changes) {
      w.changes.add(
        SpecBackfillChange(
          pair: '',
          kind: 'derived',
          path: d.path,
          field: d.field,
          oldValue: d.oldValue,
          newValue: d.newValue,
        ),
      );
    }
  }
  return SpecBackfillResult(blueprint: target, changes: w.changes, left: left);
}

String _today() {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

class _Backfill {
  _Backfill(this.set, this.doc, this.name);

  final SpecDocumentSet set;
  final SpecDocument doc;
  final String name;
  final List<SpecBackfillChange> changes = [];
  final Set<String> _pairs = {};

  SpecReflection get refl => set.refl;

  String _get(String path, String? field) =>
      (field == kSpecHeadlineField
          ? doc.headline(path)
          : field == null
          ? doc.content(path)
          : doc.formField(path, field)) ??
      '';

  void _set(String path, String? field, String value) {
    if (field == kSpecHeadlineField) {
      doc.setHeadline(path, value);
    } else if (field == null) {
      doc.setContent(path, value);
    } else {
      doc.setFormField(path, field, value);
    }
  }

  void _write(String pair, String path, String? field, String value) {
    final old = _get(path, field);
    if (old.trim() == value.trim()) return;
    _set(path, field, value);
    _pairs.add(pair);
    changes.add(
      SpecBackfillChange(
        pair: pair,
        kind: 'value',
        path: path,
        field: field,
        oldValue: old,
        newValue: value,
      ),
    );
  }

  String _idOf(String item) => _idIn(doc, item);

  String _idIn(SpecDocument doc, String item) {
    final stored = doc.itemSectionId(item);
    if (stored != null) return stored;
    final list = item.substring(0, item.lastIndexOf('-'));
    final field = refl.resolve(list)?.field;
    return effectiveListItemSectionId(
      storedId: null,
      pattern: field?.sectionIdPattern,
      position: doc.listItems(list).indexOf(item) + 1,
      fallbackStem: field?.name ?? list.split('/').last,
    );
  }

  static String _rel(String key) {
    final body = key.substring(2);
    final hash = body.indexOf('#');
    return hash < 0 ? body : body.substring(0, hash);
  }

  void apply(List<_Ordered> found) {
    // 1. Elements only in the Blueprint go, first.
    for (final o in found) {
      if (o.finding.code != SpecSyncCode.sharedElementOnlyInBlueprint ||
          !o.key.startsWith('i:')) {
        continue;
      }
      final item = o.b!.items[o.key.substring(2)];
      if (item == null || !doc.removeListItem(item)) continue;
      _pairs.add(o.finding.pair);
      changes.add(
        SpecBackfillChange(
          pair: o.finding.pair,
          kind: 'elementRemoved',
          path: item,
          oldValue: o.finding.blueprint.value ?? '',
        ),
      );
    }

    // 2. Values, and the ids of reference fields.
    final ids = <String, ({String pair, Set<String> add, Set<String> drop})>{};
    for (final o in found) {
      final f = o.finding;
      if (o.key.startsWith('i:')) continue;
      final field = f.blueprint.field;
      switch (f.code) {
        case SpecSyncCode.sharedValueDiffers || SpecSyncCode.sharedValueMissing:
          _write(f.pair, f.blueprint.path, field, o.d!.values[o.key]!.value);
        case SpecSyncCode.sharedValueOnlyInBlueprint:
          _write(f.pair, f.blueprint.path, field, '');
        case SpecSyncCode.sharedElementMissing:
          final e = ids['${f.blueprint.path}#$field'] ??= (
            pair: f.pair,
            add: {},
            drop: {},
          );
          e.add.add(f.detail.value!);
        case SpecSyncCode.sharedElementOnlyInBlueprint:
          final e = ids['${f.blueprint.path}#$field'] ??= (
            pair: f.pair,
            add: {},
            drop: {},
          );
          e.drop.add(f.blueprint.value!);
        default:
          break;
      }
    }
    for (final e in ids.entries) {
      final hash = e.key.lastIndexOf('#');
      final path = e.key.substring(0, hash);
      final field = e.key.substring(hash + 1);
      final now = [
        for (final s in _get(path, field).split(','))
          if (s.trim().isNotEmpty && !e.value.drop.contains(s.trim())) s.trim(),
      ];
      for (final x in e.value.add) {
        if (!now.contains(x)) now.add(x);
      }
      _write(e.value.pair, path, field, now.join(', '));
    }

    // 3. Elements only in the Phase 3 document come in, each with every value
    // the pair shares beneath it, then take their place.
    final added = <({String list, String id, List<String> order})>[];
    for (final o in found) {
      if (o.finding.code != SpecSyncCode.sharedElementMissing ||
          !o.key.startsWith('i:')) {
        continue;
      }
      final rel = o.key.substring(2);
      final id = rel.substring(rel.lastIndexOf('[') + 1, rel.length - 1);
      final list = o.finding.blueprint.path;
      final detailItem = o.d!.items[rel]!;
      final item = doc.addListItem(list, sectionId: id);
      _pairs.add(o.finding.pair);
      changes.add(
        SpecBackfillChange(
          pair: o.finding.pair,
          kind: 'elementAdded',
          path: item,
          newValue: id,
        ),
      );
      // Nested elements first (shortest key first), then the values.
      final mapped = <String, String>{detailItem: item};
      final nested = [
        for (final k in o.d!.items.keys)
          if (k.startsWith('$rel/')) k,
      ]..sort((a, b) => a.length.compareTo(b.length));
      for (final k in nested) {
        final dPath = o.d!.items[k]!;
        final parent = mapped.entries
            .where((m) => dPath.startsWith('${m.key}/'))
            .fold<MapEntry<String, String>?>(
              null,
              (best, m) =>
                  best == null || m.key.length > best.key.length ? m : best,
            );
        if (parent == null) continue;
        final seg = dPath.substring(parent.key.length + 1);
        final nestedId = k.substring(k.lastIndexOf('[') + 1, k.length - 1);
        mapped[dPath] = doc.addListItem(
          '${parent.value}/${seg.substring(0, seg.lastIndexOf('-'))}',
          sectionId: nestedId,
        );
      }
      String? into(String dPath) {
        MapEntry<String, String>? best;
        for (final m in mapped.entries) {
          if ((dPath == m.key || dPath.startsWith('${m.key}/')) &&
              (best == null || m.key.length > best.key.length)) {
            best = m;
          }
        }
        return best == null
            ? null
            : '${best.value}${dPath.substring(best.key.length)}';
      }

      for (final e in o.d!.values.entries) {
        final r = _rel(e.key);
        if (r != rel && !r.startsWith('$rel/')) continue;
        final p = into(e.value.path);
        if (p == null || e.value.value.isEmpty) continue;
        _set(p, e.value.field, e.value.value);
      }
      // The detail list's order, by id.
      final detailDoc = set[o.finding.detail.document!]!;
      final detailList = detailItem.substring(0, detailItem.lastIndexOf('-'));
      added.add((
        list: list,
        id: id,
        order: [
          for (final it in detailDoc.listItems(detailList))
            _idIn(detailDoc, it),
        ],
      ));
    }
    // Each list takes its new elements in one reorder: an element goes after
    // its nearest preceding neighbour (in the Phase 3 order) the Blueprint
    // holds, or first.
    final byList = <String, List<({String id, List<String> order})>>{};
    for (final a in added) {
      (byList[a.list] ??= []).add((id: a.id, order: a.order));
    }
    final orders = <String, List<String>>{};
    for (final e in byList.entries) {
      final newIds = {for (final a in e.value) a.id};
      final items = doc.listItems(e.key);
      final order = [
        for (final i in items)
          if (!newIds.contains(_idOf(i))) i,
      ];
      for (final a in e.value) {
        final item = items.firstWhere((i) => _idOf(i) == a.id);
        final before = a.order.sublist(0, a.order.indexOf(a.id));
        var at = 0;
        for (final prev in before.reversed) {
          final k = order.indexWhere((x) => _idOf(x) == prev);
          if (k >= 0) {
            at = k + 1;
            break;
          }
        }
        order.insert(at, item);
      }
      orders[e.key] = order;
    }
    _reorder(orders);
    // Each added element is reported at the place it took.
    for (var i = 0; i < changes.length; i++) {
      final c = changes[i];
      if (c.kind != 'elementAdded') continue;
      final list = c.path.substring(0, c.path.lastIndexOf('-'));
      final now = doc
          .listItems(list)
          .where((x) => _idOf(x) == c.newValue)
          .firstOrNull;
      if (now == null || now == c.path) continue;
      changes[i] = SpecBackfillChange(
        pair: c.pair,
        kind: c.kind,
        path: now,
        newValue: c.newValue,
      );
    }
  }

  /// Puts the items of each list in [orders] in the order given, in one pass
  /// over the document's stores: the lists renumbered `<list>-1 … <list>-n`,
  /// every value beneath an item travelling with it, an anonymous item whose
  /// positional id would change keeping its old id (as `moveListItem` does).
  /// Inner lists go first, so an outer rename carries their new paths.
  void _reorder(Map<String, List<String>> orders) {
    if (orders.isEmpty) return;
    final lists = orders.keys.toList()
      ..sort((a, b) => b.split('/').length.compareTo(a.split('/').length));
    final ids = {
      for (final l in lists)
        for (final i in doc.listItems(l)) i: _idOf(i),
    };
    final json = doc.toJson();
    String rename(String key, Map<String, String> map) {
      for (final e in map.entries) {
        if (key == e.key) return e.value;
        if (key.startsWith('${e.key}/')) {
          return '${e.value}${key.substring(e.key.length)}';
        }
      }
      return key;
    }

    for (final list in lists) {
      final order = orders[list]!;
      final listJson = (json['lists'] as Map)[list] as Map;
      final map = <String, String>{};
      for (var i = 0; i < order.length; i++) {
        final to = '$list-${i + 1}';
        if (order[i] != to) map[order[i]] = to;
      }
      if (map.isEmpty) continue;
      final storedIds = <String, Object?>{
        ...?(listJson['ids'] as Map?)?.cast<String, Object?>(),
      };
      final original = doc.listItems(list);
      for (var i = 0; i < order.length; i++) {
        if (original.indexOf(order[i]) != i) {
          storedIds.putIfAbsent(order[i], () => ids[order[i]]);
        }
      }
      for (final store in [
        'content',
        'forms',
        'headlines',
        'codeSpecs',
        'units',
      ]) {
        final m = json[store] as Map?;
        if (m == null) continue;
        json[store] = {
          for (final e in m.entries) rename('${e.key}', map): e.value,
        };
      }
      final newLists = <String, Object?>{};
      for (final e in (json['lists'] as Map).entries) {
        final key = '${e.key}';
        final spec = Map<String, Object?>.from(e.value as Map);
        if (key == list) {
          spec['items'] = [for (final i in order) rename(i, map)];
          spec['ids'] = {for (final i in order) rename(i, map): storedIds[i]};
        } else {
          spec['items'] = [
            for (final i in spec['items'] as List) rename('$i', map),
          ];
          if (spec['ids'] is Map) {
            spec['ids'] = {
              for (final x in (spec['ids'] as Map).entries)
                rename('${x.key}', map): x.value,
            };
          }
        }
        newLists[rename(key, map)] = spec;
      }
      json['lists'] = newLists;
    }
    doc.loadJson(json);
  }

  /// One entry in the Blueprint's revision history naming the pairs.
  void revisionEntry(String author, String date) {
    final root = set.blueprintRoot!;
    String? list;
    for (final p in specSectionPositions(refl, root)) {
      if (!p.isMember || p.member?.kind != SpecFieldKind.list) continue;
      if (p.path.contains('-*')) continue;
      if (refl.classNamed(p.member!.elementType)?.sectionId != 'RVENT') {
        continue;
      }
      list = p.path;
      break;
    }
    if (list == null) return;
    final items = doc.listItems(list);
    final last = items.isEmpty
        ? ''
        : doc.formField('${items.last}/content', 'version') ?? '';
    final version = _bump(last);
    final item = doc.addListItem(list);
    final names = [
      for (final p in set.pairs)
        if (_pairs.contains(p.sectionId)) p.sectionId,
    ].toSet().toList();
    final summary =
        'Backfilled from ${[for (final n in set.names)
          if (n != name) n].join(', ')}: '
        '${names.join(', ')}';
    for (final (f, v) in [
      ('version', version),
      ('date', date),
      ('author', author),
      ('summary', summary),
    ]) {
      doc.setFormField('$item/content', f, v);
    }
    changes.add(
      SpecBackfillChange(
        pair: '',
        kind: 'revision',
        path: item,
        newValue: version,
      ),
    );
  }

  /// The version after [v]: its last number raised by one (`1.2` → `1.3`),
  /// `1` when it holds none.
  static String _bump(String v) {
    final m = RegExp(r'(\d+)(?!.*\d)').firstMatch(v);
    if (m == null) return v.isEmpty ? '1' : '$v.1';
    final n = int.parse(m.group(1)!) + 1;
    return '${v.substring(0, m.start)}$n${v.substring(m.end)}';
  }
}
