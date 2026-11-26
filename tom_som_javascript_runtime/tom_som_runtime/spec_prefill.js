'use strict';

/**
 * prefill: a Phase 3 document started from the Blueprint (BP-8).
 *
 * A port of `tom_som_dart_runtime/lib/src/spec_prefill.dart` (a `part of`
 * `spec_document_set.dart` there); it reads the comparison internals
 * {@link SpecSetCheck} and {@link SpecSetSide} the set exports.
 */

const { deriveFields } = require('./spec_derive_fields');
const { SpecDocument } = require('./spec_document');
const { SpecSetCheck } = require('./spec_document_set');
const { validateLinks } = require('./spec_links_validator');
const { K_SPEC_HEADLINE_FIELD } = require('./spec_review_annotations');
const { validateDocument } = require('./spec_validator');

/** Why {@link prefill} refuses. */
class SpecPrefillError extends Error {
  constructor(code, message) {
    super(message);
    this.name = 'SpecPrefillError';
    /**
     * `noBlueprint` (the set holds no Blueprint) or `unknownRoot` (the root
     * names no root of the model, or the Blueprint's own).
     */
    this.code = code;
  }

  toString() {
    return `SpecPrefillError(${this.code}): ${this.message}`;
  }
}

/** What {@link prefill} did. */
class SpecPrefillResult {
  constructor(props) {
    /** The document filled: the set's own, or the one created. */
    this.document = props.document;
    /** Its name in the set. */
    this.name = props.name;
    /** Whether it was created by this call. */
    this.created = props.created;
    /** The pairs it filled, by section id, in the Blueprint's order. */
    this.filledPairs = props.filledPairs;
    /** The pairs it left because their anchor already holds a value. */
    this.skippedPairs = props.skippedPairs;
    /** The `deriveFields` run (plain) on the document after the copy. */
    this.derived = props.derived;
    /**
     * The document's findings after it (`validateDocument`, then
     * `validateLinks`): the agent's work list.
     */
    this.findings = props.findings;
  }

  /** The canonical JSON form. */
  toJson() {
    const err = (e) => ({ path: e.path, code: e.code, message: e.message });
    return {
      name: this.name,
      created: this.created,
      filledPairs: this.filledPairs,
      skippedPairs: this.skippedPairs,
      derived: {
        changes: this.derived.changes.map((c) => c.toJson()),
        unresolved: this.derived.unresolved.map(err),
      },
      findings: this.findings.map(err),
      document: this.document.toJson(),
    };
  }
}

/**
 * Fills the pairs of `rootType` (a root's type name or section id) that hold
 * nothing yet from the Blueprint, once, at the start of a Phase 3 document
 * (BP-8): every value, element (with its stored section id) and headline
 * beneath each pair's Blueprint anchor, outside `detailOnly`, copied as plain
 * values. Derived places are not copied; they are derived in the document
 * (`deriveFields`, plain) after the copy.
 *
 * A pair whose anchor already holds any value is skipped, not merged, so a
 * second run writes nothing. The document's front matter is left empty for
 * the agent. When the set has no document of the root, it is created as
 * `name` (default: the root's type name) and added to the set once it holds
 * a value. `pairs` keeps those pairs (by section id) only.
 */
function prefill(
  set,
  rootType,
  options = {},
) {
  const pairs = options.pairs != null ? new Set(options.pairs) : null;
  const bpRoot = set.blueprintRoot;
  const bpName = bpRoot === null ? null : set.nameOf(bpRoot);
  if (bpRoot === null || bpName === null) {
    throw new SpecPrefillError('noBlueprint', 'the set holds no Blueprint');
  }
  const root = set.model.roots.find((r) => r.type === rootType || r.sectionId === rootType);
  if (root === undefined || root.type === bpRoot) {
    throw new SpecPrefillError('unknownRoot', `${rootType} names no Phase 3 root of the model`);
  }
  const existing = set.nameOf(root.type);
  const docName = existing ?? options.name ?? root.type;
  const doc = existing === null ? new SpecDocument() : set.get(existing);
  const bp = set.get(bpName);
  const c = new SpecSetCheck(set);

  const filled = [];
  const skipped = [];
  for (const pair of set.pairs) {
    if (pair.detailRoot !== root.type) {
      continue;
    }
    if (pairs !== null && !pairs.has(pair.sectionId)) {
      continue;
    }
    // Nested pairs are filled on their own (when they are this root's).
    const nested = [];
    for (const other of set.pairs) {
      if (other !== pair) {
        nested.push(...c.expand(bp, other.blueprintAnchor));
      }
    }
    let wrote = false;
    let held = false;
    for (const ba of c.expand(bp, pair.blueprintAnchor)) {
      const ids = c.anchorKey(bp, ba);
      const created = [];
      const da = _anchorIn(c, doc, pair.detailAnchor, ids, created);
      if (doc.hasValuesUnder(da) && created.length === 0) {
        held = true;
        continue;
      }
      const side = c.collect(
        bpName,
        bp,
        bpRoot,
        ba,
        pair,
        nested.filter((p) => p.startsWith(`${ba}/`)),
      );
      if (_copy(c, bp, side, doc, da)) {
        wrote = true;
      } else {
        // Nothing to copy: the anchor items made for it go again.
        for (const item of [...created].reverse()) {
          doc.removeListItem(item);
        }
      }
    }
    if (wrote) {
      filled.push(pair.sectionId);
    }
    if (held && !wrote) {
      skipped.push(pair.sectionId);
    }
  }

  const created = existing === null && doc.hasValuesUnder(set.refl.rootSegment(root));
  if (created) {
    set.put(docName, doc);
  }
  const derived = deriveFields(set.model, doc, { marked: false });
  return new SpecPrefillResult({
    document: doc,
    name: docName,
    created,
    filledPairs: filled,
    skippedPairs: skipped,
    derived,
    findings: [...validateDocument(set.model, doc), ...validateLinks(set.model, doc)],
  });
}

/**
 * The concrete detail anchor of `pattern` in `doc` for a Blueprint anchor
 * whose list items carry `ids` (`a/b`, in order): each `<list>-*` taken as
 * the item of that id, created with it when missing.
 */
function _anchorIn(
  c,
  doc,
  pattern,
  ids,
  created,
) {
  const want = ids === '' ? [] : ids.split('/');
  let k = 0;
  let cur = '';
  for (const seg of pattern.split('/')) {
    if (!seg.endsWith('-*')) {
      cur = cur === '' ? seg : `${cur}/${seg}`;
      continue;
    }
    const list = `${cur}/${seg.substring(0, seg.length - 2)}`;
    const id = k < want.length ? want[k++] : '';
    const found = doc.listItems(list).find((i) => c.itemId(doc, i) === id);
    if (found !== undefined) {
      cur = found;
    } else {
      cur = doc.addListItem(list, id);
      created.push(cur);
    }
  }
  return cur;
}

/**
 * Copies the Blueprint values of `side` beneath `anchor` of `doc`: list items
 * first, in the Blueprint's order and with their section ids, then every
 * value. Whether anything was written.
 */
function _copy(
  c,
  bp,
  side,
  doc,
  anchor,
) {
  let wrote = false;
  const mapped = new Map([[side.anchor, anchor]]);
  const into = (bpPath) => {
    let best = null;
    for (const k of mapped.keys()) {
      if ((bpPath === k || bpPath.startsWith(`${k}/`)) && (best === null || k.length > best.length)) {
        best = k;
      }
    }
    return best === null ? null : `${mapped.get(best)}${bpPath.substring(best.length)}`;
  };

  // Items, outer lists first, each list in the Blueprint's order.
  const listSet = new Set();
  const itemPaths = new Set();
  for (const item of side.items.values()) {
    itemPaths.add(item);
    if (item !== side.anchor) {
      listSet.add(item.substring(0, item.lastIndexOf('-')));
    }
  }
  const lists = Array.from(listSet).sort((a, b) => a.length - b.length);
  for (const list of lists) {
    const target = into(list);
    if (target === null) {
      continue;
    }
    for (const item of bp.listItems(list)) {
      if (!itemPaths.has(item)) {
        continue;
      }
      mapped.set(item, doc.addListItem(target, c.itemId(bp, item)));
      wrote = true;
    }
  }
  for (const v of side.values.values()) {
    if (v.value === '') {
      continue;
    }
    const p = into(v.path);
    if (p === null) {
      continue;
    }
    if (v.field === K_SPEC_HEADLINE_FIELD) {
      doc.setHeadline(p, v.value);
    } else if (v.field === null) {
      doc.setContent(p, v.value);
    } else {
      doc.setFormField(p, v.field, v.value);
    }
    wrote = true;
  }
  return wrote;
}

module.exports = {
  SpecPrefillError,
  SpecPrefillResult,
  prefill,
};
