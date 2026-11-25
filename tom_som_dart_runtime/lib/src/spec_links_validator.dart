/// The link checks of one document (`tom_specs_model_rules.md` §9.7):
/// [validateLinks] holds a document's values to the link annotations of the
/// model — derived values to their sources, summaries to their detail lists,
/// each end of a link to the other, the ids named in a text to the link rows,
/// and a `@SameAs` copy to its holder.
///
/// Values are read in their reviewed state: a value holding pending change
/// marks is read with every mark rejected, and listed as
/// [SpecValidationCode.linkValuePending]. A `@SummaryOf` naming another
/// document is skipped here; the document set checks it.
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_place.dart';
import 'spec_reflection.dart';
import 'spec_review_annotations.dart';
import 'spec_section_id.dart';
import 'spec_validator.dart';

part 'spec_derive_fields.dart';

/// Runs the link checks of [doc] against [model]; the findings sorted by
/// path, then by code.
List<SpecValidationError> validateLinks(SpecModel model, SpecDocument doc) {
  final v = _LinkValidator(model, doc);
  v.run();
  final out = v.errors.toList()
    ..sort((a, b) {
      final p = a.path.compareTo(b.path);
      if (p != 0) return p;
      final c = a.code.index.compareTo(b.code.index);
      return c != 0 ? c : a.message.compareTo(b.message);
    });
  return out;
}

/// Every concrete path of [pattern] in [doc]: each `<list>-*` segment
/// expanded over the document's items.
List<String> specExpandPattern(SpecDocument doc, String pattern) {
  var paths = <String>[''];
  for (final seg in pattern.split('/')) {
    final next = <String>[];
    for (final p in paths) {
      final base = p.isEmpty ? seg : '$p/$seg';
      if (seg.endsWith('-*')) {
        next.addAll(doc.listItems(base.substring(0, base.length - 2)));
      } else {
        next.add(base);
      }
    }
    paths = next;
  }
  return paths;
}

/// [place] resolved under [anchor], or null when it does not resolve.
SpecPlaceResolution? specResolvePlaceAt(
  SpecReflection refl,
  String place,
  String anchor,
) {
  try {
    return SpecPlace.parse(place).resolve(refl, anchor);
  } on SpecPlaceException {
    return null;
  }
}

/// [place] resolved for a link annotated at [anchor], as the link checks
/// and the rendition's `linked` marker (SOM §11.11) read it: a `./` place
/// beneath the nearest list element of [anchor]; any other place inside
/// [anchor]'s subtree when it is there, else anywhere beneath the document
/// root [root] — a bare id wherever it is reached once, a `/` path from the
/// section its first segment names, through the first item [doc] holds of a
/// list there (no [doc]: such a path does not resolve).
SpecPlaceResolution? specResolveLinkPlace(
  SpecReflection refl,
  SpecDocument? doc,
  String place,
  String root,
  String anchor,
) {
  if (place.startsWith('./')) return specResolvePlaceAt(refl, place, anchor);
  // The grammar's own scope first: the subtree of the annotated section.
  final local = anchor == root ? null : specResolvePlaceAt(refl, place, anchor);
  if (local != null) return local;
  final slash = place.indexOf('/');
  if (slash < 0) return specResolvePlaceAt(refl, place, root);
  final head = specResolvePlaceAt(refl, place.substring(0, slash), root);
  if (head == null) return null;
  final scope = head.kind == SpecPlaceKind.list ? '${head.path}-*' : head.path;
  // A pattern anchor resolves through its first concrete instance; the rest
  // of the place is relative, so the pattern is rebuilt below.
  final concrete = doc == null
      ? (scope.contains('-*') ? const <String>[] : [scope])
      : specExpandPattern(doc, scope);
  if (concrete.isEmpty) return null;
  final rest = specResolvePlaceAt(
    refl,
    place.substring(slash + 1),
    concrete.first,
  );
  if (rest == null) return null;
  return SpecPlaceResolution(
    place: rest.place,
    kind: rest.kind,
    path: scope + rest.path.substring(concrete.first.length),
    className: rest.className,
    sectionIds: rest.sectionIds,
    formField: rest.formField,
  );
}

/// A class instance of the document: the path it is reached at and its class.
class _Instance {
  _Instance(this.path, this.cls, this.root);
  final String path;
  final SpecClass cls;
  final String root;
}

class _LinkValidator {
  _LinkValidator(this.model, this.doc, {this.readProposed = false})
    : refl = SpecReflection(model);

  final SpecModel model;
  final SpecDocument doc;
  final SpecReflection refl;

  /// Read values with their pending marks accepted (the proposal), as
  /// `deriveFields` does in a document under review, instead of the reviewed
  /// state; no value is then listed as pending.
  final bool readProposed;

  /// What `deriveFields` would write for each finding, collected beside it.
  final List<_Fix> fixes = [];
  final List<SpecValidationError> errors = [];
  final Set<String> _reported = {};
  final Set<String> _pending = {};

  /// Derived values computed so far (`path#field` → value), read before the
  /// stored value so a derivation from a derived place sees its derived value.
  final Map<String, String> _derived = {};

  void report(SpecValidationCode code, String path, String message) {
    if (_reported.add('${code.name} $path $message')) {
      errors.add(SpecValidationError(path: path, code: code, message: message));
    }
  }

  // -------------------------------------------------------------------------
  // The document's instances
  // -------------------------------------------------------------------------

  void run() {
    final instances = <_Instance>[];
    for (final root in model.roots) {
      final seg = refl.rootSegment(root);
      if (!_populated(seg)) continue;
      final cls = refl.classNamed(root.type);
      if (cls == null) continue;
      _walk(cls, seg, seg, instances, {});
    }
    _checkDerivations(instances);
    for (final i in instances) {
      for (final f in i.cls.fields) {
        _checkSummary(i, f);
        _checkExtracts(i, f);
        for (final ff in f.formFields) {
          final form = _formPath(i, f);
          if (ff.inverseOf != null) _checkInverse(i, form, ff);
          if (ff.summaryOf != null) _checkFieldSummary(i, form, ff);
        }
      }
    }
    for (final root in model.roots) {
      final seg = refl.rootSegment(root);
      if (_populated(seg)) _checkSameAs(root.type);
    }
  }

  bool _populated(String seg) {
    bool under(Iterable<String> paths) =>
        paths.any((p) => p == seg || p.startsWith('$seg/'));
    return under(doc.contentPaths) ||
        under(doc.formPaths) ||
        under(doc.listPaths) ||
        under(doc.headlinePaths);
  }

  void _walk(
    SpecClass cls,
    String path,
    String root,
    List<_Instance> out,
    Set<String> onPath,
  ) {
    out.add(_Instance(path, cls, root));
    for (final f in cls.fields) {
      final memberPath = '$path/${refl.fieldSegment(f)}';
      if (f.hasAnnotation('Reference')) continue;
      if (f.kind == SpecFieldKind.list && f.elementIsComplex) {
        final el = refl.classNamed(f.elementType);
        if (el == null) continue;
        for (final item in doc.listItems(memberPath)) {
          _walk(el, item, root, out, {});
        }
      } else if (f.kind == SpecFieldKind.complex ||
          f.kind == SpecFieldKind.section) {
        final child = refl.classNamed(f.type?.replaceAll('?', ''));
        if (child == null || onPath.contains(child.name)) continue;
        _walk(child, memberPath, root, out, {...onPath, cls.name});
      }
    }
  }

  String _formPath(_Instance i, SpecField f) =>
      '${i.path}/${refl.fieldSegment(f)}';

  // -------------------------------------------------------------------------
  // Reading values
  // -------------------------------------------------------------------------

  /// The reviewed reading of a raw value; a value with pending marks is
  /// listed once.
  String _reviewed(String? raw, String path, String what) {
    if (raw == null) return '';
    if (readProposed) return applyInlineMarksText(raw, accept: true).trim();
    final rejected = applyInlineMarksText(raw, accept: false);
    if (applyInlineMarksText(raw, accept: true) != rejected &&
        _pending.add('$path $what')) {
      report(
        SpecValidationCode.linkValuePending,
        path,
        '$what holds pending change marks; it is read with every mark '
        'rejected',
      );
    }
    return rejected.trim();
  }

  String _formValue(String path, String field) {
    final derived = _derived['$path#$field'];
    if (derived != null) return derived;
    return _reviewed(doc.formField(path, field), path, 'form field "$field"');
  }

  String _contentValue(String path) {
    final derived = _derived['$path#'];
    if (derived != null) return derived;
    return _reviewed(doc.content(path), path, 'the content');
  }

  String _headlineValue(String path) =>
      _reviewed(doc.headline(path), path, 'the headline');

  final Map<String, String> _itemIds = {};
  final Map<String, bool> _items = {};
  Map<String, List<String>>? _formsByOwner;
  final Map<String, Map<String, String>> _entriesCache = {};

  /// The effective section id of the list item at [itemPath].
  String _itemId(String itemPath) =>
      _itemIds.putIfAbsent(itemPath, () => _computeItemId(itemPath));

  String _computeItemId(String itemPath) {
    final stored = doc.itemSectionId(itemPath);
    if (stored != null) return stored;
    final dash = itemPath.lastIndexOf('-');
    final list = itemPath.substring(0, dash);
    final items = doc.listItems(list);
    final field = refl.resolve(list)?.field;
    return effectiveListItemSectionId(
      storedId: null,
      pattern: field?.sectionIdPattern,
      position: items.indexOf(itemPath) + 1,
      fallbackStem: field?.name ?? list.split('/').last,
    );
  }

  bool _isItem(String path) => _items.putIfAbsent(
    path,
    () => refl.resolve(path)?.kind == SpecNodeKind.listItemComplex,
  );

  /// The value a resolved place holds at its concrete [path].
  String _value(SpecPlaceResolution r, String path) => switch (r.kind) {
    SpecPlaceKind.formField => _formValue(path, r.field!),
    SpecPlaceKind.content => _contentValue(path),
    SpecPlaceKind.headline => _headlineValue(path),
    SpecPlaceKind.sectionId => _isItem(path) ? _itemId(path) : '',
    _ => '',
  };

  /// Every concrete path of a resolved pattern (`<list>-*` expanded over the
  /// document's items).
  List<String> _expand(String pattern) => specExpandPattern(doc, pattern);

  /// [place] resolved under [anchor], or null when it does not resolve.
  SpecPlaceResolution? _at(String place, String anchor) =>
      specResolvePlaceAt(refl, place, anchor);

  /// [place] resolved for a link annotated at [anchor] ([specResolveLinkPlace]).
  SpecPlaceResolution? _global(String place, String root, String anchor) =>
      specResolveLinkPlace(refl, doc, place, root, anchor);

  /// The values a row's own forms (`<row>/<member>`) hold in [field].
  List<String> _ownValues(String row, String field) {
    final index = _formsByOwner ??= () {
      final out = <String, List<String>>{};
      for (final p in doc.formPaths) {
        final slash = p.lastIndexOf('/');
        if (slash > 0) (out[p.substring(0, slash)] ??= []).add(p);
      }
      return out;
    }();
    return [
      for (final p in index[row] ?? const <String>[])
        if (doc.formField(p, field) != null) _formValue(p, field),
    ];
  }

  bool _passes(String? where, String row) {
    if (where == null) return true;
    final filter = SpecPlaceFilter.tryParse(where);
    if (filter == null || filter.field == null) return true;
    return filter.matches(_ownValues(row, filter.field!));
  }

  /// The nearest list item at or above [path] (itself included).
  String? _nearestItem(String path) {
    var p = path;
    while (true) {
      if (_isItem(p)) return p;
      final slash = p.lastIndexOf('/');
      if (slash < 0) return null;
      p = p.substring(0, slash);
    }
  }

  static List<String> _ids(String value) => [
    for (final s in value.split(','))
      if (s.trim().isNotEmpty) s.trim(),
  ];

  // -------------------------------------------------------------------------
  // @DerivedFrom and derivedFrom:
  // -------------------------------------------------------------------------

  void _checkDerivations(List<_Instance> instances) {
    final scalar =
        <
          ({
            String path,
            String? field,
            SpecDerivation d,
            String anchor,
            String root,
            FormFieldSpec? spec,
          })
        >[];
    for (final i in instances) {
      for (final f in i.cls.fields) {
        final d = f.derivedFrom;
        final memberPath = _formPath(i, f);
        if (d != null) {
          if (f.kind == SpecFieldKind.list) {
            _checkDerivedList(i, memberPath, d);
          } else if (f.kind == SpecFieldKind.content) {
            scalar.add((
              path: memberPath,
              field: null,
              d: d,
              anchor: i.path,
              root: i.root,
              spec: null,
            ));
          }
        }
        for (final ff in f.formFields) {
          final q = ff.derivedFrom;
          if (q == null) continue;
          scalar.add((
            path: memberPath,
            field: ff.name,
            d: q,
            anchor: i.path,
            root: i.root,
            spec: ff,
          ));
        }
      }
    }
    // Dependency order: every derivation is recomputed from the values the
    // ones before it gave, until nothing moves. DERIVE-ACYCLIC bounds the
    // rounds by the number of derivations.
    final expected = <int, String?>{};
    for (var round = 0; round <= scalar.length; round++) {
      var moved = false;
      for (var k = 0; k < scalar.length; k++) {
        final t = scalar[k];
        final value = _derive(t.d, t.anchor, t.root, t.spec, t.path);
        if (expected[k] != value) {
          expected[k] = value;
          moved = true;
          if (value != null) _derived['${t.path}#${t.field ?? ''}'] = value;
        }
      }
      if (!moved) break;
    }
    _derived.clear();
    for (var k = 0; k < scalar.length; k++) {
      final t = scalar[k];
      final want = expected[k];
      if (want == null) continue;
      final have = t.field == null
          ? _contentValue(t.path)
          : _formValue(t.path, t.field!);
      if (!_sameValue(have, want, t.spec)) {
        fixes.add(_Fix.set(2, t.path, t.field, want));
      }
      if (have.isEmpty) continue; // not derived yet: deriveFields writes it
      if (!_sameValue(have, want, t.spec)) {
        report(
          SpecValidationCode.derivedValueMismatch,
          t.path,
          '${t.field == null ? 'the content' : 'form field "${t.field}"'} is '
          'derived (${t.d.kind} of ${t.d.source}) as "$want", but holds '
          '"$have"',
        );
      }
    }
  }

  static bool _sameValue(String a, String b, FormFieldSpec? spec) {
    if (spec != null && spec.multiple && spec.refersTo.isNotEmpty) {
      return (_ids(a).toSet()..removeAll(_ids(b))).isEmpty &&
          (_ids(b).toSet()..removeAll(_ids(a))).isEmpty;
    }
    final t = spec?.type;
    if (t == 'int' || t == 'double' || t == 'num') {
      final x = num.tryParse(a), y = num.tryParse(b);
      if (x != null && y != null) return x == y;
    }
    String norm(String s) =>
        s.split('\n').map((l) => l.trimRight()).join('\n').trim();
    return norm(a) == norm(b);
  }

  /// The rows a `rows` / `lookup` derivation reads, in document order; null
  /// when the document's root does not reach the source (undecidable here).
  List<String>? _rows(SpecDerivation d, String anchor, String root) {
    final src = _global(d.source, root, anchor);
    if (src == null) return null;
    final keyBy = d.key != null && d.by != null;
    final byValue = keyBy ? _placeValue(d.by!, anchor) : null;
    return [
      for (final row in _expand(src.path))
        if (_passes(d.where, row) &&
            (!keyBy || _placeValue(d.key!, row) == byValue))
          row,
    ];
  }

  /// The value of [place] resolved under the concrete [anchor].
  String _placeValue(String place, String anchor) {
    final r = _at(place, anchor);
    if (r == null) return '';
    final paths = _expand(r.path);
    return paths.length == 1 ? _value(r, paths.single) : '';
  }

  /// The value a scalar derivation gives, or null when undecidable.
  String? _derive(
    SpecDerivation d,
    String anchor,
    String root,
    FormFieldSpec? spec,
    String targetPath,
  ) {
    switch (d.kind) {
      case 'copy':
        final src = _global(d.source, root, anchor);
        if (src == null) return null;
        final paths = _expand(src.path);
        return paths.length == 1 ? _value(src, paths.single) : null;
      case 'rows':
        final rows = _rows(d, anchor, root);
        if (rows == null) return null;
        if (spec != null && spec.multiple) {
          return [
            for (final row in rows)
              for (final t in d.take) ..._ids(_placeValue(t, row)),
          ].join(', ');
        }
        return [
          for (final row in rows)
            [
              for (final t in d.take) _placeValue(t, row),
            ].where((s) => s.isNotEmpty).join(' — '),
        ].where((s) => s.isNotEmpty).join('\n');
      case 'lookup':
        final rows = _rows(d, anchor, root);
        if (rows == null) return null;
        final keyBy = d.key != null && d.by != null;
        if (keyBy && rows.length != 1) {
          report(
            SpecValidationCode.derivedLookupMiss,
            targetPath,
            'the lookup in ${d.source} by ${d.key} = '
            '"${_placeValue(d.by!, anchor)}" finds ${rows.length} rows, not '
            'one',
          );
          return null;
        }
        if (rows.isEmpty) return '';
        final row = rows.last;
        return [
          for (final t in d.take) _placeValue(t, row),
        ].where((s) => s.isNotEmpty).join(' — ');
    }
    return null;
  }

  /// A `@DerivedFrom.rows` with `map` on a list: one element per row.
  void _checkDerivedList(_Instance i, String listPath, SpecDerivation d) {
    if (d.kind != 'rows' || d.map.isEmpty) return;
    final elements = doc.listItems(listPath);
    final rows = _rows(d, i.path, i.root);
    if (rows == null) return; // the source is not in this document
    final wanted = [
      for (final row in rows)
        {for (final e in d.map.entries) e.key: _placeValue(e.value, row)},
    ];
    final current = [
      for (final el in elements)
        {for (final e in d.map.entries) e.key: _placeValue(e.key, el)},
    ];
    String key(Map<String, String> t) =>
        [for (final k in d.map.keys) t[k]].join(' | ');
    if (([for (final t in wanted) key(t)]..sort()).join('\n') !=
        ([for (final t in current) key(t)]..sort()).join('\n')) {
      fixes.add(_Fix.list(listPath, wanted));
    }
    if (elements.isEmpty) return; // not derived yet
    String tuple(Iterable<String> values) => values.join(' | ');
    final want = [
      for (final row in rows)
        tuple([for (final e in d.map.entries) _placeValue(e.value, row)]),
    ]..sort();
    final have = [
      for (final el in elements)
        tuple([for (final e in d.map.entries) _placeValue(e.key, el)]),
    ]..sort();
    if (want.join('\n') != have.join('\n')) {
      report(
        SpecValidationCode.derivedValueMismatch,
        listPath,
        'the list is derived (rows of ${d.source}) as [${want.join('; ')}], '
        'but holds [${have.join('; ')}]',
      );
    }
  }

  // -------------------------------------------------------------------------
  // @SummaryOf and summaryOf:
  // -------------------------------------------------------------------------

  /// The detail elements of a summary: item path → id.
  Map<String, String>? _detailElements(SpecSummaryOf s, String root) {
    final r = _global(s.detail, root, root);
    if (r == null || r.kind != SpecPlaceKind.list) return null;
    return {
      for (final list in _expand(r.path))
        for (final item in doc.listItems(list)) item: _itemId(item),
    };
  }

  void _checkSummary(_Instance i, SpecField f) {
    final s = f.summaryOf;
    if (s == null || s.document != null || f.kind != SpecFieldKind.list) {
      return;
    }
    final detail = _detailElements(s, i.root);
    if (detail == null) return;
    final byId = {for (final e in detail.entries) e.value: e.key};
    final named = <String, String>{};
    for (final el in doc.listItems(_formPath(i, f))) {
      final ids = s.match == null
          ? [_itemId(el)]
          : _ids(_placeValue(s.match!, el));
      for (final id in ids) {
        final target = byId[id];
        if (target == null) {
          report(
            SpecValidationCode.summaryNotInDetail,
            el,
            'the summary row names $id, which is no element of ${s.detail}',
          );
          continue;
        }
        if (named.containsKey(id)) {
          report(
            SpecValidationCode.summaryDuplicate,
            el,
            'the summary row names $id, which ${named[id]} names already',
          );
          continue;
        }
        named[id] = el;
        _checkRepeats(s, el, target);
      }
    }
    if (s.relation == 'equal') {
      for (final e in detail.entries) {
        if (!named.containsKey(e.value)) {
          report(
            SpecValidationCode.detailNotInSummary,
            e.key,
            'the detail element ${e.value} is named by no row of the summary '
            '${_formPath(i, f)} (relation: equal)',
          );
        }
      }
    }
  }

  /// The values a summary row repeats agree with its detail element's.
  void _checkRepeats(SpecSummaryOf s, String row, String detail) {
    for (final e in s.repeats.entries) {
      final mine = _at(e.key, row);
      final theirs = _at(e.value, detail);
      if (mine == null || theirs == null) continue;
      final mp = _expand(mine.path), tp = _expand(theirs.path);
      if (mp.length != 1 || tp.length != 1) continue;
      final have = _value(mine, mp.single);
      final want = _value(theirs, tp.single);
      if (have != want) {
        fixes.add(_Fix.set(2, mp.single, _fieldOf(mine), want));
      }
      if (have.isEmpty) continue; // not repeated yet: deriveFields writes it
      if (have != want) {
        report(
          SpecValidationCode.derivedValueMismatch,
          mp.single,
          '${e.key} repeats ${e.value} of $detail as "$have", but the detail '
          'element holds "$want"',
        );
      }
    }
  }

  void _checkFieldSummary(_Instance i, String form, FormFieldSpec ff) {
    final s = ff.summaryOf!;
    if (s.document != null) return;
    final raw = doc.formField(form, ff.name);
    if (raw == null) return;
    final detail = _detailElements(s, i.root);
    if (detail == null) return;
    final known = detail.values.toSet();
    final seen = <String>{};
    for (final id in _ids(_formValue(form, ff.name))) {
      if (!known.contains(id)) {
        report(
          SpecValidationCode.summaryNotInDetail,
          form,
          'form field "${ff.name}" names $id, which is no element of '
          '${s.detail}',
        );
      } else if (!seen.add(id)) {
        report(
          SpecValidationCode.summaryDuplicate,
          form,
          'form field "${ff.name}" names $id twice',
        );
      }
    }
    if (s.relation == 'equal') {
      for (final e in detail.entries) {
        if (!seen.contains(e.value)) {
          report(
            SpecValidationCode.detailNotInSummary,
            e.key,
            'the detail element ${e.value} is not named in "${ff.name}" of '
            '$form (relation: equal)',
          );
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // inverseOf:
  // -------------------------------------------------------------------------

  /// The entries a reference field names, by its `refersTo` registries: id
  /// → item path. An entry of `<X>.@sectionId` is named by its section id,
  /// one of `<X>.<field>` by the value its own forms hold in that field.
  Map<String, String> _entries(List<String> refersTo) => _entriesCache
      .putIfAbsent(refersTo.join(','), () => _computeEntries(refersTo));

  Map<String, String> _computeEntries(List<String> refersTo) {
    final out = <String, String>{};
    for (final list in doc.listPaths.toList()..sort()) {
      for (final item in doc.listItems(list)) {
        final id = refl.resolve(item)?.targetClass?.sectionId;
        if (id == null) continue;
        for (final t in refersTo) {
          if (t.split('.').first != id) continue;
          final name = _identity(item, t);
          if (name != null && name.isNotEmpty)
            out.putIfAbsent(name, () => item);
        }
      }
    }
    return out;
  }

  /// How the registry key [target] (`<X>.@sectionId` or `<X>.<field>`) names
  /// the entry at [item].
  String? _identity(String item, String target) {
    final field = target.substring(target.indexOf('.') + 1);
    if (field == kSectionIdSlot) return _itemId(item);
    final values = _ownValues(item, field);
    return values.isEmpty ? null : values.first;
  }

  /// The nearest item at or above [path] whose class is one of [classes].
  String? _owner(String path, Set<String> classes) {
    var p = _nearestItem(path);
    while (p != null) {
      final id = refl.resolve(p)?.targetClass?.sectionId;
      if (id != null && classes.contains(id)) return p;
      final slash = p.lastIndexOf('/');
      if (slash < 0) return null;
      p = _nearestItem(p.substring(0, slash));
    }
    return null;
  }

  static Set<String> _registryClasses(List<String> refersTo) => {
    for (final t in refersTo) t.split('.').first,
  };

  void _checkInverse(_Instance i, String form, FormFieldSpec ff) {
    final raw = doc.formField(form, ff.name);
    if (raw == null) return;
    final value = _formValue(form, ff.name);
    if (value.isEmpty) return;
    final inv = ff.inverseOf!;
    final entries = _entries(ff.refersTo);
    if (inv.symmetric) {
      _checkSymmetric(form, ff, inv, value, entries);
      return;
    }
    // The entry this field belongs to, as the other ends name it.
    for (final b in _ids(value)) {
      final bPath = entries[b];
      if (bPath == null) continue; // a registry this document does not hold
      var resolved = false;
      var namesBack = false;
      String? aId;
      (String, String)? writable;
      for (final end in inv.fields) {
        final r = _at(end, bPath);
        if (r == null || r.formField == null) continue;
        final owner = _owner(form, _registryClasses(r.formField!.refersTo));
        if (owner == null) continue;
        if (inv.where != null && !_passes(inv.where, owner)) return;
        aId = r.formField!.refersTo
            .map((t) => _identity(owner, t))
            .whereType<String>()
            .firstOrNull;
        if (aId == null) continue;
        resolved = true;
        final ends = _expand(r.path);
        if (ends.isNotEmpty) writable ??= (ends.first, r.field!);
        for (final p in ends) {
          if (_ids(_formValue(p, r.field!)).contains(aId)) namesBack = true;
        }
      }
      if (resolved && !namesBack && writable != null) {
        fixes.add(_Fix.append(writable.$1, writable.$2, aId!));
      }
      if (resolved && !namesBack) {
        report(
          SpecValidationCode.inverseMissing,
          form,
          'form field "${ff.name}" names $b, but $b does not name $aId back '
          '(${inv.fields.join(', ')})',
        );
      }
    }
  }

  void _checkSymmetric(
    String form,
    FormFieldSpec ff,
    SpecInverseOf inv,
    String value,
    Map<String, String> entries,
  ) {
    final row = _nearestItem(form);
    if (row == null || !_passes(inv.where, row)) return;
    final a = _owner(
      row.substring(0, row.lastIndexOf('/')),
      _registryClasses(ff.refersTo),
    );
    if (a == null) return;
    final aId = ff.refersTo
        .map((t) => _identity(a, t))
        .whereType<String>()
        .firstOrNull;
    if (aId == null) return;
    final filter = inv.where == null
        ? null
        : SpecPlaceFilter.tryParse(inv.where!);
    final whereValues = filter?.field == null
        ? const <String>{}
        : _ownValues(row, filter!.field!).toSet();
    // The same place beneath the named entry, every row of it.
    final rel = form
        .substring(a.length)
        .split('/')
        .map((s) {
          final dash = s.lastIndexOf('-');
          return dash > 0 && int.tryParse(s.substring(dash + 1)) != null
              ? '${s.substring(0, dash)}-*'
              : s;
        })
        .join('/');
    for (final b in _ids(value)) {
      final bPath = entries[b];
      if (bPath == null || bPath == a) continue;
      final counterpart = _expand('$bPath$rel').any((p) {
        final r = _nearestItem(p);
        if (r == null || !_passes(inv.where, r)) return false;
        if (filter?.field != null &&
            !_ownValues(r, filter!.field!).toSet().containsAll(whereValues)) {
          return false;
        }
        return _ids(_formValue(p, ff.name)).contains(aId);
      });
      if (!counterpart) {
        final star = rel.indexOf('-*');
        if (star > 0) {
          final list = '$bPath${rel.substring(0, star)}';
          final below = rel.substring(star + 3);
          fixes.add(
            _Fix.addRow(1, list, {
              '$below#${ff.name}': aId,
              if (filter?.field != null)
                for (final p in _ownForms(row))
                  if (doc.formField(p, filter!.field!) != null)
                    '${p.substring(row.length + 1)}#${filter.field}':
                        _formValue(p, filter.field!),
            }),
          );
        }
        report(
          SpecValidationCode.inverseMissing,
          form,
          'the row names $b, but $b holds no row naming $aId back'
          '${inv.where == null ? '' : ' (${inv.where})'}',
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // @ExtractsLinks and the link rows
  // -------------------------------------------------------------------------

  void _checkExtracts(_Instance i, SpecField f) {
    final all = f.extractsLinks;
    if (all.isEmpty || f.kind != SpecFieldKind.list) return;
    final listPath = _formPath(i, f);
    final rows = doc.listItems(listPath);
    final element = _nearestItem(i.path);
    final own = element == null ? null : _itemId(element);

    // A link row holding no value at all (what accepting the marked removal
    // of a row leaves) is removed.
    for (final row in rows) {
      if (!_holdsValue(row)) fixes.add(_Fix.removeRow(row, empty: true));
    }

    // The ids each row names, and its type (the values `set` writes).
    final setKeys = {for (final e in all) ...e.set.keys}.toList()..sort();
    final named = <String, List<String>>{};
    final seen = <String, String>{};
    for (final row in rows) {
      final ids = <String>[];
      for (final e in all) {
        final r = _at(e.ref, row);
        if (r == null) continue;
        for (final p in _expand(r.path)) {
          ids.addAll(_ids(_value(r, p)));
        }
      }
      named[row] = ids.toSet().toList();
      final type = [for (final k in setKeys) _placeValue(k, row)].join(' | ');
      for (final id in named[row]!) {
        final key = '$id // $type';
        final first = seen[key];
        if (first != null) {
          report(
            SpecValidationCode.duplicateLinkRow,
            row,
            'the row names $id with the type "$type", as $first does',
          );
        } else {
          seen[key] = row;
        }
      }
    }
    final rowed = {for (final ids in named.values) ...ids};

    final textIds = <String>{};
    for (final e in all) {
      final refSpec = rows.isEmpty
          ? _refSpecFromModel(f, e.ref)
          : _at(e.ref, rows.first)?.formField;
      if (refSpec == null) continue;
      final registry = _entries(refSpec.refersTo).keys.toSet();
      final found = <String>[];
      for (final place in e.from) {
        final p = place.startsWith('./') ? place : './$place';
        final r = _at(p, i.path);
        if (r == null) continue;
        for (final path in _expand(r.path)) {
          for (final id in _idsIn(_value(r, path), registry)) {
            if (id != own && !found.contains(id)) found.add(id);
          }
        }
      }
      textIds.addAll(found);
      for (final id in found) {
        if (rowed.contains(id)) continue;
        if (e.mode == 'generate') {
          final values = <String, String>{};
          for (final entry in {e.ref: id, ...e.set}.entries) {
            final r = _at(entry.key, '$listPath-0');
            if (r == null || r.field == null) continue;
            final rel = r.path.substring('$listPath-0'.length + 1);
            values['$rel#${r.field}'] = entry.value;
          }
          fixes.add(_Fix.addRow(1, listPath, values));
        }
        report(
          SpecValidationCode.extractedLinkMissing,
          listPath,
          '$id is named in ${e.from.join(' / ')} but has no row'
          '${e.mode == 'warn' ? ' (warn: the agent adds it)' : ''}',
        );
      }
    }
    // A generated row: every `set` value of a generate-mode use matches.
    for (final e in all.where((e) => e.mode == 'generate')) {
      final mine = <String>{};
      for (final place in e.from) {
        final p = place.startsWith('./') ? place : './$place';
        final r = _at(p, i.path);
        if (r == null) continue;
        final refSpec = rows.isEmpty ? null : _at(e.ref, rows.first)?.formField;
        final registry = refSpec == null
            ? const <String>{}
            : _entries(refSpec.refersTo).keys.toSet();
        for (final path in _expand(r.path)) {
          mine.addAll(_idsIn(_value(r, path), registry));
        }
      }
      for (final row in rows) {
        final generated = e.set.entries.every(
          (s) => _placeValue(s.key, row) == s.value,
        );
        if (!generated) continue;
        for (final id in named[row]!) {
          if (!mine.contains(id)) {
            fixes.add(_Fix.removeRow(row));
            report(
              SpecValidationCode.extractedLinkStale,
              row,
              'the generated row names $id, which ${e.from.join(' / ')} no '
              'longer names',
            );
          }
        }
      }
    }
  }

  FormFieldSpec? _refSpecFromModel(SpecField list, String ref) {
    final el = refl.classNamed(list.elementType);
    if (el == null) return null;
    final dot = ref.indexOf('.');
    if (dot < 0) return null;
    final id = ref.substring(0, dot), name = ref.substring(dot + 1);
    for (final f in el.fields) {
      final fid = f.name == 'content' ? el.sectionId : f.sectionId;
      if (fid != id) continue;
      for (final ff in f.formFields) {
        if (ff.name == name) return ff;
      }
    }
    return null;
  }

  /// The ids of [registry] named in [text], each matched exactly (not as a
  /// part of a longer id), in order of first appearance.
  static List<String> _idsIn(String text, Set<String> registry) {
    final out = <String>[];
    final token = RegExp(r'[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]|[A-Za-z0-9]');
    for (final m in token.allMatches(text)) {
      final id = m.group(0)!;
      if (registry.contains(id) && !out.contains(id)) out.add(id);
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // @SameAs
  // -------------------------------------------------------------------------

  void _checkSameAs(String rootType) {
    for (final b in specSameAsBindings(refl, rootType)) {
      if (b.holderPath == null) continue;
      final copies = _expand(b.copyPath);
      final holders = _expand(b.holderPath!);
      if (copies.length != holders.length) continue;
      for (var k = 0; k < copies.length; k++) {
        if (_compareSubtrees(copies[k], holders[k])) {
          fixes.add(_Fix.copy(copies[k], holders[k]));
        }
      }
    }
  }

  /// Every value beneath [root] (itself included), keyed by its path relative
  /// to [root] with list items written by their section id, so two subtrees
  /// compare element by element.
  Map<String, ({String path, String value})> _subtree(String root) {
    String key(String path) {
      final rel = path == root ? '' : path.substring(root.length + 1);
      if (rel.isEmpty) return '';
      final out = <String>[];
      var at = root;
      for (final seg in rel.split('/')) {
        at = '$at/$seg';
        out.add(
          _isItem(at)
              ? '${seg.substring(0, seg.lastIndexOf('-'))}[${_itemId(at)}]'
              : seg,
        );
      }
      return out.join('/');
    }

    bool under(String p) => p == root || p.startsWith('$root/');
    final out = <String, ({String path, String value})>{};
    for (final p in doc.contentPaths) {
      if (under(p)) out['c:${key(p)}'] = (path: p, value: _contentValue(p));
    }
    for (final p in doc.formPaths) {
      if (!under(p)) continue;
      for (final field in doc.formFieldNames(p)) {
        out['f:${key(p)}#$field'] = (path: p, value: _formValue(p, field));
      }
    }
    for (final p in doc.headlinePaths) {
      if (under(p)) out['h:${key(p)}'] = (path: p, value: _headlineValue(p));
    }
    for (final l in doc.listPaths) {
      if (!under(l)) continue;
      for (final item in doc.listItems(l)) {
        out['i:${key(item)}'] = (path: item, value: _itemId(item));
      }
    }
    out.removeWhere((_, v) => v.value.isEmpty);
    return out;
  }

  /// Reports every difference of [copy] from [holder]; whether there is one.
  bool _compareSubtrees(String copy, String holder) {
    final mine = _subtree(copy);
    final theirs = _subtree(holder);
    final keys = {...mine.keys, ...theirs.keys}.toList()..sort();
    // An element on one side only is one finding; its values are not
    // compared.
    final oneSided = [
      for (final k in keys)
        if (k.startsWith('i:') && (mine[k] == null) != (theirs[k] == null))
          k.substring(2),
    ];
    bool beneath(String k) {
      final rel = k.substring(2).split('#').first;
      return !k.startsWith('i:') &&
          oneSided.any((o) => rel == o || rel.startsWith('$o/'));
    }

    var differs = false;
    for (final k in keys) {
      final a = mine[k], b = theirs[k];
      if (a?.value == b?.value || beneath(k)) continue;
      differs = true;
      final what = k.startsWith('i:')
          ? 'element ${(a ?? b)!.value}'
          : k.startsWith('h:')
          ? 'the headline'
          : k.startsWith('c:')
          ? 'the content'
          : 'form field "${k.substring(k.indexOf('#') + 1)}"';
      report(
        SpecValidationCode.sameAsMismatch,
        a?.path ?? copy,
        'the copy of $holder differs in $what: the copy holds '
        '"${a?.value ?? ''}", the holder "${b?.value ?? ''}"',
      );
    }
    return differs;
  }

  // -------------------------------------------------------------------------
  // Helpers of the fixes
  // -------------------------------------------------------------------------

  /// The field a resolved value place names for a write: the form field, the
  /// headline's reserved field, or null for content.
  static String? _fieldOf(SpecPlaceResolution r) => switch (r.kind) {
    SpecPlaceKind.formField => r.field,
    SpecPlaceKind.headline => kSpecHeadlineField,
    _ => null,
  };

  /// The forms directly beneath [row] (`<row>/<member>`).
  List<String> _ownForms(String row) => [
    for (final p in doc.formPaths)
      if (p.startsWith('$row/') && !p.substring(row.length + 1).contains('/'))
        p,
  ];

  /// Every path at or above a value the document holds (marks included);
  /// a headline counts for the sections above its own.
  Set<String>? _valued;

  /// Whether anything beneath [path] holds a value (marks included).
  bool _holdsValue(String path) {
    final valued = _valued ??= () {
      final out = <String>{};
      void up(String p, {bool self = true}) {
        var cur = self
            ? p
            : (p.contains('/') ? p.substring(0, p.lastIndexOf('/')) : '');
        while (cur.isNotEmpty && out.add(cur)) {
          final slash = cur.lastIndexOf('/');
          cur = slash < 0 ? '' : cur.substring(0, slash);
        }
      }

      for (final p in doc.contentPaths) {
        if ((doc.content(p) ?? '').trim().isNotEmpty) up(p);
      }
      for (final p in doc.formPaths) {
        if (doc
            .formFieldNames(p)
            .any((f) => (doc.formField(p, f) ?? '').trim().isNotEmpty)) {
          up(p);
        }
      }
      for (final p in doc.headlinePaths) {
        if ((doc.headline(p) ?? '').isNotEmpty) up(p, self: false);
      }
      for (final l in doc.listPaths) {
        if (doc.listItems(l).isNotEmpty) up(l);
      }
      return out;
    }();
    return valued.contains(path);
  }
}
