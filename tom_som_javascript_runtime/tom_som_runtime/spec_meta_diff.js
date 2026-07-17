'use strict';

/**
 * Structural comparison of two {@link SomMetaNode} subtrees; a faithful port
 * of `tom_som_dart_runtime/lib/src/spec_meta_diff.dart` (and the Python/Java
 * ports).
 *
 * {@link somMetaNodeDiff} is the agreement oracle for DR8: the generated
 * facades embed populated metadata trees as static code (DR1 §3.2), while
 * {@link module:spec_meta_bridge.buildSomMetaTree} derives the same tree from
 * the exported meta-JSON at runtime — the two must be field-for-field
 * identical for every node. Tests compare them with this function, which
 * returns a human-readable description of the **first** difference found
 * (with the node's position), or `null` when the subtrees agree completely.
 */

/**
 * Compares the `a` and `b` subtrees field by field (annotations, names,
 * kinds, form/document metadata, children and list element subtrees).
 *
 * Returns `null` when the subtrees are structurally identical, else a
 * description of the first difference, prefixed with the position `at`
 * (a `/`-joined member-name chain, defaulting to the root marker).
 *
 * @param {import('./spec_meta').SomMetaNode} a
 * @param {import('./spec_meta').SomMetaNode} b
 * @param {string} [at]
 * @returns {string|null}
 */
function somMetaNodeDiff(a, b, at = '<root>') {
  function diff(field, va, vb) {
    return _valueEq(va, vb) ? null : `${at}: ${field} differs — ${va} != ${vb}`;
  }

  const checks = [
    () => diff('className', a.className, b.className),
    () => diff('memberName', a.memberName, b.memberName),
    () => diff('sectionId', a.sectionId, b.sectionId),
    () => diff('sectionIdPattern', a.sectionIdPattern, b.sectionIdPattern),
    () => diff('kind', a.kind, b.kind),
    () => diff('typeName', a.typeName, b.typeName),
    () =>
      diff('serializationOrder', a.serializationOrder, b.serializationOrder),
    () => diff('min', a.min, b.min),
    () => diff('unused', a.unused, b.unused),
    () =>
      diff(
        'contentType.type',
        a.contentType ? a.contentType.type : null,
        b.contentType ? b.contentType.type : null,
      ),
    () =>
      diff(
        'contentType.description',
        a.contentType ? a.contentType.description : null,
        b.contentType ? b.contentType.description : null,
      ),
    () => diff('contentHelp', a.contentHelp, b.contentHelp),
    () => diff('headline', a.headline, b.headline),
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
  for (const check of checks) {
    const d = check();
    if (d !== null) {
      return d;
    }
  }

  if (a.children.length !== b.children.length) {
    return (
      `${at}: children count differs — ` +
      `${a.children.length} != ${b.children.length} ` +
      `(${JSON.stringify(a.children.map((c) => c.memberName))} vs ` +
      `${JSON.stringify(b.children.map((c) => c.memberName))})`
    );
  }
  for (let i = 0; i < a.children.length; i++) {
    const ca = a.children[i];
    const d = somMetaNodeDiff(
      ca,
      b.children[i],
      `${at}/${ca.memberName !== null ? ca.memberName : ca.className}`,
    );
    if (d !== null) {
      return d;
    }
  }

  const aElem = a.elementNode !== null && a.elementNode !== undefined;
  const bElem = b.elementNode !== null && b.elementNode !== undefined;
  if (aElem !== bElem) {
    return `${at}: elementNode presence differs — ${aElem} != ${bElem}`;
  }
  if (aElem) {
    return somMetaNodeDiff(a.elementNode, b.elementNode, `${at}/§element`);
  }
  return null;
}

function _formDiff(at, a, b) {
  const aSet = a !== null && a !== undefined;
  const bSet = b !== null && b !== undefined;
  if (aSet !== bSet) {
    return `${at}: form presence differs — ${aSet} != ${bSet}`;
  }
  if (!aSet) {
    return null;
  }
  if (a.fields.length !== b.fields.length) {
    return (
      `${at}: form field count differs — ` +
      `${a.fields.length} != ${b.fields.length}`
    );
  }
  for (let i = 0; i < a.fields.length; i++) {
    const fa = a.fields[i];
    const fb = b.fields[i];
    if (
      fa.name !== fb.name ||
      fa.typeName !== fb.typeName ||
      fa.description !== fb.description ||
      fa.required !== fb.required ||
      fa.hint !== fb.hint ||
      fa.role !== fb.role ||
      fa.initial !== fb.initial ||
      fa.order !== fb.order
    ) {
      return `${at}: form field ${fa.name} differs`;
    }
  }
  return null;
}

function _documentDiff(at, a, b) {
  const aSet = a !== null && a !== undefined;
  const bSet = b !== null && b !== undefined;
  if (aSet !== bSet) {
    return `${at}: document presence differs — ${aSet} != ${bSet}`;
  }
  if (!aSet) {
    return null;
  }
  if (a.name !== b.name) {
    return `${at}: document.name differs — ${a.name} != ${b.name}`;
  }
  if (a.description !== b.description) {
    return `${at}: document.description differs`;
  }
  if (!_listEq(a.basedOn, b.basedOn)) {
    return (
      `${at}: document.basedOn differs — ` +
      `${JSON.stringify(a.basedOn)} != ${JSON.stringify(b.basedOn)}`
    );
  }
  return null;
}

function _secondLevelDiff(at, a, b) {
  if (a.length !== b.length) {
    return `${at}: secondLevelIds count differs — ${a.length} != ${b.length}`;
  }
  for (let i = 0; i < a.length; i++) {
    if (a[i].documentClass !== b[i].documentClass || a[i].id !== b[i].id) {
      return `${at}: secondLevelIds[${i}] differs`;
    }
  }
  return null;
}

function _extraDiff(at, a, b) {
  if (a.length !== b.length) {
    return (
      `${at}: extra annotation count differs — ${a.length} != ${b.length} ` +
      `(${JSON.stringify(a.map((e) => e.annotation))} vs ` +
      `${JSON.stringify(b.map((e) => e.annotation))})`
    );
  }
  for (let i = 0; i < a.length; i++) {
    if (
      a[i].annotation !== b[i].annotation ||
      !_valueEq(a[i].args, b[i].args)
    ) {
      return (
        `${at}: extra annotation ${a[i].annotation} differs — ` +
        `${JSON.stringify(a[i].args)} != ${JSON.stringify(b[i].args)}`
      );
    }
  }
  return null;
}

/** Deep structural equality over JSON-shaped values (the annotation-argument
 *  shapes: scalars, arrays, plain objects). */
function _valueEq(a, b) {
  if (Array.isArray(a) && Array.isArray(b)) {
    return _listEq(a, b);
  }
  if (_isPlainObject(a) && _isPlainObject(b)) {
    const aKeys = Object.keys(a);
    if (aKeys.length !== Object.keys(b).length) {
      return false;
    }
    for (const k of aKeys) {
      if (!Object.prototype.hasOwnProperty.call(b, k) || !_valueEq(a[k], b[k])) {
        return false;
      }
    }
    return true;
  }
  return a === b;
}

function _listEq(a, b) {
  if (a.length !== b.length) {
    return false;
  }
  for (let i = 0; i < a.length; i++) {
    if (!_valueEq(a[i], b[i])) {
      return false;
    }
  }
  return true;
}

function _isPlainObject(v) {
  return v !== null && typeof v === 'object' && !Array.isArray(v);
}

module.exports = {
  somMetaNodeDiff,
};
