/// Structural comparison of two [SomMetaNode] subtrees.
///
/// [somMetaNodeDiff] is the agreement oracle for DR8: the generated facades
/// embed populated metadata trees as static code (DR1 §3.2), while
/// `buildSomMetaTree` derives the same tree from the exported meta-JSON at
/// runtime — the two must be field-for-field identical for every node. Tests
/// compare them with this function, which returns a human-readable description
/// of the **first** difference found (with the node's position), or `null`
/// when the subtrees agree completely.
library;

import 'spec_meta.dart';

/// Compares the [a] and [b] subtrees field by field (annotations, names,
/// kinds, form/document metadata, children and list element subtrees).
///
/// Returns `null` when the subtrees are structurally identical, else a
/// description of the first difference, prefixed with the position [at]
/// (a `/`-joined member-name chain, defaulting to the root marker).
String? somMetaNodeDiff(SomMetaNode a, SomMetaNode b, {String at = '<root>'}) {
  String? diff<T>(String field, T va, T vb) =>
      va == vb ? null : '$at: $field differs — $va != $vb';

  final checks = <String? Function()>[
    () => diff('className', a.className, b.className),
    () => diff('memberName', a.memberName, b.memberName),
    () => diff('sectionId', a.sectionId, b.sectionId),
    () => diff('sectionIdPattern', a.sectionIdPattern, b.sectionIdPattern),
    () => diff('kind', a.kind, b.kind),
    () => diff('typeName', a.typeName, b.typeName),
    () => diff('serializationOrder', a.serializationOrder,
        b.serializationOrder),
    () => diff('min', a.min, b.min),
    () => diff('unused', a.unused, b.unused),
    () => diff('contentType.type', a.contentType?.type, b.contentType?.type),
    () => diff('contentType.description', a.contentType?.description,
        b.contentType?.description),
    () => diff('contentHelp', a.contentHelp, b.contentHelp),
    () => diff('comment', a.comment, b.comment),
    () => diff('docComment', a.docComment, b.docComment),
    () => diff('classDocComment', a.classDocComment, b.classDocComment),
    () => diff('mapsTo', a.mapsTo, b.mapsTo),
    () => diff('detailedIn', a.detailedIn, b.detailedIn),
    () => diff('recursive', a.recursive, b.recursive),
    () => _formDiff(at, a.form, b.form),
    () => _documentDiff(at, a.document, b.document),
    () => _secondLevelDiff(at, a.secondLevelIds, b.secondLevelIds),
    () => _extraDiff(at, a.extra, b.extra),
  ];
  for (final check in checks) {
    final d = check();
    if (d != null) return d;
  }

  if (a.children.length != b.children.length) {
    return '$at: children count differs — '
        '${a.children.length} != ${b.children.length} '
        '(${a.children.map((c) => c.memberName).toList()} vs '
        '${b.children.map((c) => c.memberName).toList()})';
  }
  for (var i = 0; i < a.children.length; i++) {
    final ca = a.children[i];
    final d = somMetaNodeDiff(ca, b.children[i],
        at: '$at/${ca.memberName ?? ca.className}');
    if (d != null) return d;
  }

  if ((a.elementNode == null) != (b.elementNode == null)) {
    return '$at: elementNode presence differs — '
        '${a.elementNode != null} != ${b.elementNode != null}';
  }
  if (a.elementNode != null) {
    return somMetaNodeDiff(a.elementNode!, b.elementNode!,
        at: '$at/§element');
  }
  return null;
}

String? _formDiff(String at, SomFormMeta? a, SomFormMeta? b) {
  if ((a == null) != (b == null)) {
    return '$at: form presence differs — ${a != null} != ${b != null}';
  }
  if (a == null || b == null) return null;
  if (a.fields.length != b.fields.length) {
    return '$at: form field count differs — '
        '${a.fields.length} != ${b.fields.length}';
  }
  for (var i = 0; i < a.fields.length; i++) {
    final fa = a.fields[i];
    final fb = b.fields[i];
    if (fa.name != fb.name ||
        fa.typeName != fb.typeName ||
        fa.description != fb.description ||
        fa.required != fb.required ||
        fa.hint != fb.hint ||
        fa.order != fb.order) {
      return '$at: form field ${fa.name} differs';
    }
  }
  return null;
}

String? _documentDiff(String at, SomDocMeta? a, SomDocMeta? b) {
  if ((a == null) != (b == null)) {
    return '$at: document presence differs — ${a != null} != ${b != null}';
  }
  if (a == null || b == null) return null;
  if (a.name != b.name) {
    return '$at: document.name differs — ${a.name} != ${b.name}';
  }
  if (a.description != b.description) return '$at: document.description differs';
  if (!_listEq(a.basedOn, b.basedOn)) {
    return '$at: document.basedOn differs — ${a.basedOn} != ${b.basedOn}';
  }
  return null;
}

String? _secondLevelDiff(
    String at, List<SomSecondLevelId> a, List<SomSecondLevelId> b) {
  if (a.length != b.length) {
    return '$at: secondLevelIds count differs — ${a.length} != ${b.length}';
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].documentClass != b[i].documentClass || a[i].id != b[i].id) {
      return '$at: secondLevelIds[$i] differs';
    }
  }
  return null;
}

String? _extraDiff(String at, List<SomMetaExtra> a, List<SomMetaExtra> b) {
  if (a.length != b.length) {
    return '$at: extra annotation count differs — ${a.length} != ${b.length} '
        '(${a.map((e) => e.annotation).toList()} vs '
        '${b.map((e) => e.annotation).toList()})';
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].annotation != b[i].annotation ||
        !_mapEq(a[i].args, b[i].args)) {
      return '$at: extra annotation ${a[i].annotation} differs — '
          '${a[i].args} != ${b[i].args}';
    }
  }
  return null;
}

bool _listEq(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_valueEq(a[i], b[i])) return false;
  }
  return true;
}

bool _mapEq(Map<String, Object?> a, Map<String, Object?> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || !_valueEq(e.value, b[e.key])) return false;
  }
  return true;
}

bool _valueEq(Object? a, Object? b) {
  if (a is List && b is List) return _listEq(a, b);
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    return _mapEq(a, b);
  }
  return a == b;
}
