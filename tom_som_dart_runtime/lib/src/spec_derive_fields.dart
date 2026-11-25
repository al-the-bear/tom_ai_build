part of 'spec_links_validator.dart';

// ---------------------------------------------------------------------------
// deriveFields: the derived places of one document, written
// ---------------------------------------------------------------------------

/// One place [deriveFields] wrote.
class SpecDeriveChange {
  /// The step that wrote it: 1 (link ends and rows), 2 (derived values,
  /// repeats, `@SameAs` copies), 3 (counts, products, ranks).
  final int step;

  /// `value` (a value written), `rowAdded`, `rowRemoved`.
  final String kind;

  /// The value's path, or the row's.
  final String path;

  /// The form field ([kSpecHeadlineField] for a headline), or null.
  final String? field;

  /// The value before and after (for a row, empty).
  final String oldValue, newValue;

  /// The parts of a change.
  const SpecDeriveChange({
    required this.step,
    required this.kind,
    required this.path,
    this.field,
    this.oldValue = '',
    this.newValue = '',
  });

  /// The canonical JSON form.
  Map<String, Object?> toJson() => {
    'step': step,
    'kind': kind,
    'path': path,
    if (field != null) 'field': field,
    'old': oldValue,
    'new': newValue,
  };
}

/// What [deriveFields] did.
class SpecDeriveResult {
  /// The document written: the one given, or its copy on a dry run.
  final SpecDocument document;

  /// Every place written, in the order written.
  final List<SpecDeriveChange> changes;

  /// What it could not write, with the code: `unmarkable` (a change it cannot
  /// mark exactly in a document under review, left as it was),
  /// `derivedLookupMiss` (a lookup without exactly one row).
  final List<SpecValidationError> unresolved;

  /// The parts of a result.
  const SpecDeriveResult({
    required this.document,
    required this.changes,
    required this.unresolved,
  });

  /// The canonical JSON form (the document as its stores).
  Map<String, Object?> toJson() => {
    'changes': [for (final c in changes) c.toJson()],
    'unresolved': [
      for (final e in unresolved)
        {'path': e.path, 'code': e.code.name, 'message': e.message},
    ],
    'document': document.toJson(),
  };
}

/// Recomputes the derived places of [doc] (`tom_specs_model_rules.md` §9.7)
/// in three steps, each reading the result of the one before:
///
/// 1. the missing `inverseOf` ends inside the document, the missing
///    `@ExtractsLinks` rows in `generate` mode, and the stale generated rows
///    removed (a link row left with no value at all goes too);
/// 2. `@DerivedFrom` values and lists, `@SummaryOf` `repeats`, and every
///    `@SameAs` copy from its holder;
/// 3. `countOf`, `productOf` and `rankOf`.
///
/// [marked] (a document under review) writes every change as inline marks
/// (SOM §11.9.3) — text, typed values and headlines alike; a new row's values
/// as insertions, a removed row's as deletions — attributed to [author] at
/// [at], and reads values as proposed (pending marks accepted). Without it
/// values are written plain. A change it cannot mark exactly is left as it was
/// and listed as `unmarkable`. It never writes another document: an end
/// whose registry the document does not hold stays the set's finding. A
/// second run right after the first writes nothing. [dryRun] works on a copy.
SpecDeriveResult deriveFields(
  SpecModel model,
  SpecDocument doc, {
  bool marked = true,
  String? author,
  String? at,
  bool dryRun = false,
}) {
  final target = dryRun ? (SpecDocument()..loadJson(doc.toJson())) : doc;
  final d = _Deriver(model, target, marked, author, at);
  d.run();
  return SpecDeriveResult(
    document: target,
    changes: d.changes,
    unresolved: d.unresolved,
  );
}

/// A write [deriveFields] makes, collected beside the finding it resolves.
class _Fix {
  _Fix._(
    this.step,
    this.kind,
    this.path, {
    this.field,
    this.value,
    this.values,
    this.tuples,
    this.holder,
    this.empty = false,
  });

  /// Set the value at [path] / [field] to [value].
  _Fix.set(int step, String path, String? field, String value)
    : this._(step, 'set', path, field: field, value: value);

  /// Add [value] to the ids of the reference field at [path] / [field].
  _Fix.append(String path, String field, String value)
    : this._(1, 'append', path, field: field, value: value);

  /// Add a row to the list at [path]: `<member>#<field>` (or `<member>`, a
  /// content value) → value.
  _Fix.addRow(int step, String path, Map<String, String> values)
    : this._(step, 'addRow', path, values: values);

  /// Remove the row at [path]; [empty]: it holds no value already.
  _Fix.removeRow(String path, {bool empty = false})
    : this._(1, 'removeRow', path, empty: empty);

  /// Make the list at [path] hold one element per tuple (target place →
  /// value).
  _Fix.list(String path, List<Map<String, String>> tuples)
    : this._(2, 'list', path, tuples: tuples);

  /// Write the copy at [path] from the [holder].
  _Fix.copy(String path, String holder)
    : this._(2, 'copy', path, holder: holder);

  final int step;
  final String kind;
  final String path;
  final String? field;
  final String? value;
  final Map<String, String>? values;
  final List<Map<String, String>>? tuples;
  final String? holder;
  final bool empty;
}

class _Deriver {
  _Deriver(this.model, this.doc, this.marked, this.author, this.at)
    : api = SpecReviewAnnotations(doc, clock: at == null ? null : () => at);

  final SpecModel model;
  final SpecDocument doc;
  final bool marked;
  final String? author;
  final String? at;
  final SpecReviewAnnotations api;
  final List<SpecDeriveChange> changes = [];
  final List<SpecValidationError> unresolved = [];
  final Set<String> _unresolvedKeys = {};

  _LinkValidator _check() =>
      _LinkValidator(model, doc, readProposed: marked)..run();

  void run() {
    // Step 1: link ends and rows. Removals first, so a row removed and a row
    // added for the same id do not cancel out.
    var v = _check();
    final step1 = v.fixes.where((f) => f.step == 1).toList();
    for (final f in step1.where((f) => f.kind == 'removeRow')) {
      _removeRow(1, f.path, empty: f.empty);
    }
    for (final f in step1.where((f) => f.kind != 'removeRow')) {
      _apply(f, v);
    }

    // Step 2: derived values and lists, then (reading them) the repeats and
    // the copies; again until nothing moves, which DERIVE-ACYCLIC bounds.
    for (var round = 0; round < 4; round++) {
      v = _check();
      final before = changes.length;
      for (final f in v.fixes.where((f) => f.step == 2 && f.kind != 'copy')) {
        _apply(f, v);
      }
      v = _check();
      for (final f in v.fixes.where((f) => f.kind == 'copy')) {
        _apply(f, v);
      }
      if (changes.length == before) break;
    }
    for (final e in v.errors) {
      if (e.code == SpecValidationCode.derivedLookupMiss) _unresolved(e);
    }

    // Step 3: counts, products, ranks.
    for (final n in specDerivedNumbers(model, doc, readProposed: marked)) {
      _write(3, n.path, n.field, n.value);
    }
  }

  void _unresolved(SpecValidationError e) {
    if (_unresolvedKeys.add('${e.code.name} ${e.path} ${e.message}')) {
      unresolved.add(e);
    }
  }

  // --- the writes ----------------------------------------------------------

  String _get(String path, String? field) =>
      (field == kSpecHeadlineField
          ? doc.headline(path)
          : field == null
          ? doc.content(path)
          : doc.formField(path, field)) ??
      '';

  void _setPlain(String path, String? field, String value) {
    if (field == kSpecHeadlineField) {
      doc.setHeadline(path, value);
    } else if (field == null) {
      doc.setContent(path, value);
    } else {
      doc.setFormField(path, field, value);
    }
  }

  /// Writes [value] at [path] / [field]: plainly, or marked against the value
  /// there (compared from its original, so a change already proposed is not
  /// proposed again).
  void _write(int step, String path, String? field, String value) {
    final current = _get(path, field);
    if (!marked) {
      if (current.trim() == value.trim()) return;
      _setPlain(path, field, value);
    } else {
      if (applyInlineMarksText(current, accept: true).trim() == value.trim()) {
        return;
      }
      final original = applyInlineMarksText(current, accept: false);
      if (!markChangeText(original, value).exact) {
        _unresolved(
          SpecValidationError(
            path: path,
            code: SpecValidationCode.unmarkable,
            message:
                '${field == null ? 'the content' : 'form field "$field"'} '
                'would become "$value", a change that cannot be marked '
                'exactly; it is left for the agent',
          ),
        );
        return;
      }
      api.setMarked(
        path: path,
        field: field,
        text: value,
        author: author,
        at: at,
      );
    }
    final now = _get(path, field);
    if (now != current) {
      changes.add(
        SpecDeriveChange(
          step: step,
          kind: 'value',
          path: path,
          field: field,
          oldValue: current,
          newValue: now,
        ),
      );
    }
  }

  void _addRow(
    int step,
    String list,
    Map<String, String> values, {
    String? sectionId,
  }) {
    final item = doc.addListItem(list, sectionId: sectionId);
    changes.add(SpecDeriveChange(step: step, kind: 'rowAdded', path: item));
    for (final e in values.entries) {
      final hash = e.key.indexOf('#');
      final rel = hash < 0 ? e.key : e.key.substring(0, hash);
      final field = hash < 0 ? null : e.key.substring(hash + 1);
      _write(step, '$item/$rel', field, e.value);
    }
  }

  void _removeRow(int step, String row, {bool empty = false}) {
    if (!marked || empty) {
      if (!doc.removeListItem(row)) return;
      changes.add(SpecDeriveChange(step: step, kind: 'rowRemoved', path: row));
      return;
    }
    // Under review: every value of the row is proposed for deletion; once
    // accepted, the empty row goes with the next run.
    final before = changes.length;
    bool under(String p) => p == row || p.startsWith('$row/');
    for (final p in doc.contentPaths.toList()..sort()) {
      if (under(p)) _write(step, p, null, '');
    }
    for (final p in doc.formPaths.toList()..sort()) {
      if (!under(p)) continue;
      for (final f in doc.formFieldNames(p).toList()..sort()) {
        _write(step, p, f, '');
      }
    }
    if (changes.length > before) {
      changes.insert(
        before,
        SpecDeriveChange(step: step, kind: 'rowRemoved', path: row),
      );
    }
  }

  void _apply(_Fix f, _LinkValidator v) {
    switch (f.kind) {
      case 'set':
        _write(f.step, f.path, f.field, f.value!);
      case 'append':
        final ids = _LinkValidator._ids(v._formValue(f.path, f.field!));
        if (ids.contains(f.value)) return;
        _write(f.step, f.path, f.field, [...ids, f.value!].join(', '));
      case 'addRow':
        _addRow(f.step, f.path, f.values!);
      case 'removeRow':
        _removeRow(f.step, f.path, empty: f.empty);
      case 'list':
        _applyList(f, v);
      case 'copy':
        _applyCopy(f.path, f.holder!, v);
    }
  }

  /// Makes the list hold one element per wanted tuple: elements matching no
  /// tuple removed, tuples matching no element added.
  void _applyList(_Fix f, _LinkValidator v) {
    final places = f.tuples!.isEmpty
        ? const <String>[]
        : f.tuples!.first.keys.toList();
    String key(Map<String, String> t) =>
        [for (final p in places) t[p]].join(' | ');
    final wanted = [for (final t in f.tuples!) key(t)];
    final keep = <String>[];
    for (final el in doc.listItems(f.path).toList()) {
      final k = key({for (final p in places) p: v._placeValue(p, el)});
      final i = wanted.indexOf(k);
      if (i < 0) {
        _removeRow(2, el);
      } else {
        wanted.removeAt(i);
        keep.add(k);
      }
    }
    for (final t in f.tuples!) {
      final k = key(t);
      if (keep.remove(k)) continue;
      final values = <String, String>{};
      for (final p in places) {
        final r = v._at(p, '${f.path}-0');
        if (r == null) continue;
        final rel = r.path.substring('${f.path}-0'.length + 1);
        values[r.field == null ? rel : '$rel#${r.field}'] = t[p]!;
      }
      _addRow(2, f.path, values);
    }
  }

  /// Writes the copy at [copy] from its [holder]: every value and element
  /// the holder has, in the copy, and nothing else.
  void _applyCopy(String copy, String holder, _LinkValidator v) {
    final theirs = v._subtree(holder);
    final mine = v._subtree(copy);
    String? pathIn(String rel, {required bool create}) {
      var cur = copy;
      if (rel.isEmpty) return cur;
      for (final seg in rel.split('/')) {
        final bracket = seg.indexOf('[');
        if (bracket < 0) {
          cur = '$cur/$seg';
          continue;
        }
        final list = '$cur/${seg.substring(0, bracket)}';
        final id = seg.substring(bracket + 1, seg.length - 1);
        final found = doc
            .listItems(list)
            .where((i) => v._itemId(i) == id)
            .firstOrNull;
        if (found != null) {
          cur = found;
        } else if (!create) {
          return null;
        } else {
          cur = doc.addListItem(list, sectionId: id);
          v._itemIds[cur] = id;
          changes.add(SpecDeriveChange(step: 2, kind: 'rowAdded', path: cur));
        }
      }
      return cur;
    }

    (String rel, String? field)? split(String key) {
      final kind = key[0];
      final body = key.substring(2);
      return switch (kind) {
        'f' => (
          body.substring(0, body.indexOf('#')),
          body.substring(body.indexOf('#') + 1),
        ),
        'c' => (body, null),
        'h' => (body, kSpecHeadlineField),
        _ => null,
      };
    }

    // Elements the holder lacks go first, and nothing beneath them is
    // written.
    final gone = <String>[];
    for (final k in mine.keys.toList()..sort()) {
      if (!k.startsWith('i:') || theirs.containsKey(k)) continue;
      final rel = k.substring(2);
      if (gone.any((g) => rel.startsWith('$g/'))) continue;
      gone.add(rel);
      _removeRow(2, mine[k]!.path);
    }
    bool beneathGone(String rel) =>
        gone.any((g) => rel == g || rel.startsWith('$g/'));

    for (final k in theirs.keys.toList()..sort()) {
      if (k.startsWith('i:')) {
        pathIn(k.substring(2), create: true);
        continue;
      }
      final s = split(k);
      if (s == null) continue;
      final path = pathIn(s.$1, create: true);
      if (path == null) continue;
      _write(2, path, s.$2, theirs[k]!.value);
    }
    for (final k in mine.keys.toList()..sort()) {
      if (theirs.containsKey(k) || k.startsWith('i:')) continue;
      final s = split(k);
      if (s == null || beneathGone(s.$1)) continue;
      final path = pathIn(s.$1, create: false);
      if (path != null) _write(2, path, s.$2, '');
    }
  }
}
