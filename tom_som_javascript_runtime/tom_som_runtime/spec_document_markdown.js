'use strict';

/**
 * DocSpecs-conform Markdown codec for a TomSpecs document (DR1 §1) — a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_document_markdown.dart`
 * (and `spec_document_markdown.py`).
 *
 * The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
 * the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is one markdown heading whose machine-readable identity is the
 * DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
 * human-readable Title-Case member name. Content values are **normal markdown
 * text** under their heading (no fences, no anchors); `@Form` sections use the
 * DocSpecs plain-text `FieldName: value` format; a list emits its `-LST`
 * **container heading** (the id the DR3 schema keys its container type by),
 * with the numbered items one level deeper, each carrying the item's
 * **anonymous positional** section id — the `@SectionIdPattern` resolved with
 * the 1-based position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`), else `<member>-<pos>`
 * for a pattern-less list. The container carries no content of its own; a
 * stored `@SectionId` is **not** surfaced in md (it lives losslessly in the
 * `*.docspecs.yaml` format, DR1 §2) so the generated schema's `pattern-check-id`
 * stays a clean `^<stem>-[0-9]+$`. Id-less members are **transparent** (mirroring
 * the DR3 schema generator): a transparent value member's text or form block
 * is the owner's body region, emitted without a heading and bound at its own
 * path; a transparent section/complex member never heads — its id-bearing
 * descendants hoist to the owner's child level (paths keep the transparent
 * segments). Section/complex headings without a field-level `@SectionId`
 * carry the target class's `@SectionId`.
 *
 * Escaping (DR1 §1.3): a content line starting with `#` at column 0 is
 * emitted as `\#` (and a leading `\#`… run gains one more backslash), except
 * inside fenced code blocks, which shield their lines verbatim. Consecutive
 * blank lines are collapsed to one on emit; parse trims each value of
 * leading/trailing blank lines and does not re-collapse.
 *
 * The codec is free of any UI: it reads from / resolves against a
 * {@link SpecModel} (through the {@link buildSomMetaTree} metadata tree) and a
 * {@link SpecDocument}. {@link SpecDocumentMarkdown#parse} does **not** mutate
 * the document — it returns staged values keyed exactly like
 * {@link SpecDocument#toJson} plus a rejection report; the caller applies
 * them. Anything that cannot be mapped — an unknown section id, a child
 * heading under a value leaf, orphaned text — is collected into
 * {@link SpecMarkdownResult#rejections} rather than dropped (DR1 §1.7).
 */

const { SomMetaKind } = require('./spec_meta');
const { buildSomMetaTree } = require('./spec_meta_bridge');

/** Why an imported Markdown block was rejected (DR1 §1.7 rejection protocol). */
const SpecMarkdownRejectReason = Object.freeze({
  /** The heading's section id does not resolve against the schema tree at its
   *  nesting position. */
  UNKNOWN_SECTION: 'unknownSection',
  /** A structurally impossible combination — e.g. a child heading nested
   *  under a value-leaf (content/scalar/enum) section. */
  KIND_MISMATCH: 'kindMismatch',
  /** Body text with no owning value slot — e.g. prose inside a `@Form`
   *  section before the first `FieldName:` line. */
  ORPHAN_CONTENT: 'orphanContent',
  /** A value-leaf section heading with an empty body. */
  MISSING_VALUE: 'missingValue',
  /** A heading line without a parseable `<!--[id]-->` headline comment. */
  MALFORMED_HEADING: 'malformedHeading',
  /** A `FieldName:` form line for a title/id **role field** (YRD6): the
   *  field's value is the section heading / id comment and must never be
   *  duplicated as a form line. */
  ROLE_FIELD_FORM_LINE: 'roleFieldFormLine',
});

/**
 * One rejected block in a Markdown import (DR1 §1.7). Reported, never silently
 * dropped: each carries the source `line`, the offending `anchor` (section
 * path or id), the `reason`, and a human-readable `message`.
 */
class SpecMarkdownRejection {
  constructor(line, reason, message, anchor = null) {
    this.line = line;
    this.reason = reason;
    this.message = message;
    this.anchor = anchor;
  }

  toString() {
    const anchor = this.anchor !== null ? ` (${this.anchor})` : '';
    return `line ${this.line}: ${this.reason}${anchor} — ${this.message}`;
  }
}

/**
 * The outcome of parsing a Markdown document (DR1 §1.7): the staged values
 * plus every rejected block. The values are keyed exactly like
 * {@link SpecDocument#toJson} so a caller can merge them into a live document
 * as a full overwrite of the covered scope.
 */
class SpecMarkdownResult {
  constructor() {
    /** Content/scalar/enum leaf values (and section body text): path → value.
     *  @type {Object<string, string>} */
    this.content = {};
    /** Form values: form path → (field name → value).
     *  @type {Object<string, Object<string, string>>} */
    this.forms = {};
    /** List membership: list path → `{seq, items, ids?}` (the
     *  {@link SpecDocument#toJson} shape), recovered from the item headings.
     *  @type {Object<string, Object>} */
    this.lists = {};
    /** Stored headlines recovered from headings (YRD3): path → headline.
     *  Only headings whose text differs from the effective default title are
     *  staged, so a default-rendered document stays byte-stable.
     *  @type {Object<string, string>} */
    this.headlines = {};
    /** Every rejected block, in source order.
     *  @type {SpecMarkdownRejection[]} */
    this.rejections = [];
    /** The root segment(s) the import covers (the first segment of each
     *  accepted path) — the scope a full-overwrite apply purges first.
     *  @type {Set<string>} */
    this.rootPrefixes = new Set();
  }

  /** Whether the parse was clean (no rejections). */
  get isClean() {
    return this.rejections.length === 0;
  }

  /** The number of leaf values successfully parsed (content + form fields). */
  get appliedCount() {
    let n = Object.keys(this.content).length;
    for (const m of Object.values(this.forms)) {
      n += Object.keys(m).length;
    }
    return n;
  }
}

/**
 * Fence state machine (CommonMark-ish): a line whose first non-space run (up
 * to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
 * same-character run at least as long closes it.
 *
 * Public so other markdown-processing modules (the DocSpecs validator's
 * generic parser) share exactly the same fence semantics as this codec.
 */
class MarkdownFenceTracker {
  constructor() {
    this._char = null;
    this._len = 0;
  }

  get inFence() {
    return this._char !== null;
  }

  feed(line) {
    const m = /^ {0,3}(`{3,}|~{3,})/.exec(line);
    if (m === null) {
      return;
    }
    const run = m[1];
    if (this._char === null) {
      this._char = run.charAt(0);
      this._len = run.length;
    } else if (
      run.charAt(0) === this._char &&
      run.length >= this._len &&
      line.trim() === this._char.repeat(line.trim().length)
    ) {
      this._char = null;
      this._len = 0;
    }
  }
}

/** A tiny StringBuffer with Dart-style `writeln` semantics. */
class _Buffer {
  constructor() {
    this._parts = [];
  }

  writeln(text = '') {
    this._parts.push(text);
    this._parts.push('\n');
  }

  toString() {
    return this._parts.join('');
  }
}

function _escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// A line the emitter must escape: an optional run of backslashes followed by
// `#` at column 0 (the escape itself must survive the round-trip).
const _ESCAPABLE = /^\\*#/;

// A line that would parse as a form-field label: `Word:` at column 0
// (optionally already space-prefixed — each emit pass adds one more space).
const _LABEL_SHAPED = /^ *[A-Za-z][A-Za-z0-9_]*:/;

const _FIELD_LABEL = /^([A-Za-z][A-Za-z0-9_]*): ?(.*)$/;
const _CONTINUATION_LABEL = /^ +[A-Za-z][A-Za-z0-9_]*:/;
const _ESCAPED_HEADING = /^\\+#/;

/**
 * Codec binding a {@link SpecModel} and a concrete {@link SpecDocument} to the
 * DocSpecs Markdown import/export format (DR1 §1).
 */
class SpecDocumentMarkdown {
  constructor(model, document) {
    this.model = model;
    this.document = document;
    // Metadata trees per root type, built lazily (DR8's generated facades
    // will hand these in directly; until then the bridge derives them).
    /** @type {Map<string, import('./spec_meta').SomMetaTree>} */
    this._trees = new Map();
  }

  _treeFor(rootType) {
    let tree = this._trees.get(rootType);
    if (!tree) {
      tree = buildSomMetaTree(this.model, rootType);
      this._trees.set(rootType, tree);
    }
    return tree;
  }

  // --- Naming helpers (DR1 §1.2 / §1.5) ------------------------------------

  /**
   * `introductionAndScope` / `DemoItem` → `Introduction And Scope` /
   * `Demo Item`: a camel/Pascal-case identifier expanded into Title Case.
   */
  static titleCase(name) {
    const words = [];
    let buf = '';
    for (const c of name) {
      const isUpper = c.toUpperCase() === c && c.toLowerCase() !== c;
      if (isUpper && buf) {
        words.push(buf);
        buf = '';
      }
      buf += c;
    }
    if (buf) {
      words.push(buf);
    }
    return words
      .map((w) => (w ? w.charAt(0).toUpperCase() + w.slice(1) : w))
      .join(' ');
  }

  /**
   * `Demo Document` → `demo-document`: the DocSpecs schema id of a
   * `@Document` name (DR1 §1.1).
   */
  static kebabCase(title) {
    return title
      .trim()
      .replace(/[\s_]+/g, '-')
      .replace(/[^A-Za-z0-9-]/g, '')
      .toLowerCase();
  }

  /**
   * The item heading title stem: Title-Case element class name with a
   * trailing `Entry` dropped (DR1 §1.5, normative).
   */
  static itemTitleStem(elementClassName) {
    let stem = elementClassName;
    if (stem.length > 5 && stem.endsWith('Entry')) {
      stem = stem.slice(0, -5);
    }
    return SpecDocumentMarkdown.titleCase(stem);
  }

  /**
   * The `FieldName` label written for a form field: the model field name with
   * the first letter upper-cased (DR1 §1.4.1).
   */
  static formLabel(fieldName) {
    if (!fieldName) {
      return fieldName;
    }
    return fieldName.charAt(0).toUpperCase() + fieldName.slice(1);
  }

  // --- Export (DR1 §1.1–§1.6) ----------------------------------------------

  /**
   * The section id written into (and matched from) a heading for `node`
   * (DR1 §1.2/§1.6): the field-level `@SectionId` when present; for
   * section/complex nodes whose field carries none, the target **class**'s
   * `@SectionId` (the id the DR3 schema types are keyed by); else the path
   * segment (the member name).
   */
  _headingIdOf(node) {
    if (node.sectionId !== null && node.sectionId !== undefined) {
      return node.sectionId;
    }
    if (node.kind === SomMetaKind.SECTION || node.kind === SomMetaKind.COMPLEX) {
      const cls = this.model.classNamed(node.className);
      if (cls !== null && cls.sectionId !== null && cls.sectionId !== undefined) {
        return cls.sectionId;
      }
    }
    return node.segment;
  }

  // --- Transparency (DR1 §1.2, mirroring the DR3 schema generator) ---------
  //
  // The DR3 `docspecs-schema` generator is normative: only **section-bearing**
  // nodes (those with a real `@SectionId`, field- or class-level) become
  // section types; id-less members are *transparent* — they are not sections
  // of their own. The markdown format mirrors that exactly:
  //
  //   * a transparent value member (content/scalar/enum/form without an id)
  //     is emitted headinglessly into its owner's *body region* (text, or a
  //     `FieldName: value` form block);
  //   * a transparent section/complex member gets no heading; its id-bearing
  //     descendants surface as the owner's direct child headings (the
  //     schema's "nearest section-bearing descendant" hoisting), with document
  //     paths still running through the transparent segments;
  //   * lists are never transparent — the `-LST` container always heads (its
  //     `@SectionId`, else the member segment) and its numbered items head one
  //     level deeper (pattern-numbered / `<member>-<pos>`).
  //
  // Principled canonicalisation losses (documented, accepted): multiple
  // transparent content members of one owner merge into the first on parse,
  // and a form-field label colliding across an owner's transparent forms
  // binds to the nearest form in slot order.

  /**
   * A section/complex member with no field- or class-level `@SectionId`:
   * heading-less, its children hoist to the owner.
   */
  _isTransparentSection(n) {
    if (n.kind !== SomMetaKind.SECTION && n.kind !== SomMetaKind.COMPLEX) {
      return false;
    }
    if (n.sectionId !== null && n.sectionId !== undefined) {
      return false;
    }
    const cls = this.model.classNamed(n.className);
    return cls === null || cls.sectionId === null || cls.sectionId === undefined;
  }

  /**
   * A value member (content/scalar/enum/form) with no `@SectionId`: emitted
   * into the owner's body region instead of under an own heading.
   */
  static _isTransparentValue(n) {
    return (
      (n.sectionId === null || n.sectionId === undefined) &&
      (n.kind === SomMetaKind.CONTENT ||
        n.kind === SomMetaKind.SCALAR ||
        n.kind === SomMetaKind.ENUM_VALUE ||
        n.kind === SomMetaKind.FORM)
    );
  }

  /**
   * The ordered *body slots* of `node`: every transparent value member and
   * every transparent section (whose own path may carry body text), collected
   * depth-first through transparent sections. These are the value positions
   * that share the owner's heading body.
   *
   * @returns {Array<[import('./spec_meta').SomMetaNode, string]>}
   */
  _bodySlots(node) {
    const out = [];
    const collect = (n, prefix) => {
      for (const c of n.children) {
        if (c.recursive) {
          continue;
        }
        const rel = prefix ? `${prefix}/${c.segment}` : c.segment;
        if (SpecDocumentMarkdown._isTransparentValue(c)) {
          out.push([c, rel]);
        } else if (this._isTransparentSection(c)) {
          out.push([c, rel]);
          collect(c, rel);
        }
      }
    };
    collect(node, '');
    return out;
  }

  /**
   * The ordered *effective children* of `node`: every section-bearing child
   * and every list, hoisted through transparent sections — exactly the
   * headings (and item-heading owners) the DR3 schema knows at this position.
   * Each entry carries the relative path from `node` (which runs through the
   * transparent segments).
   *
   * @returns {Array<[import('./spec_meta').SomMetaNode, string]>}
   */
  _effectiveChildren(node) {
    const out = [];
    const collect = (n, prefix) => {
      for (const c of n.children) {
        if (c.recursive) {
          continue;
        }
        const rel = prefix ? `${prefix}/${c.segment}` : c.segment;
        if (SpecDocumentMarkdown._isTransparentValue(c)) {
          continue; // body region
        }
        if (this._isTransparentSection(c)) {
          collect(c, rel);
        } else {
          out.push([c, rel]);
        }
      }
    };
    collect(node, '');
    return out;
  }

  /**
   * Renders the populated subtree of `root` as a DocSpecs-conform Markdown
   * document. Throws an {@link Error} when a content value contains an
   * unterminated fenced code block (which would shield the remainder of the
   * document from heading detection and break the round-trip).
   */
  exportRoot(root) {
    const tree = this._treeFor(root.type);
    const node = tree.root;
    const b = new _Buffer();
    b.writeln(
      `<!-- docspec: ${SpecDocumentMarkdown.kebabCase(root.title)}/` +
        `${this.model.modelVersionString} -->`,
    );
    const rootSeg = node.segment;
    SpecDocumentMarkdown._writeHeading(
      b,
      1,
      rootSeg,
      this.document.headline(rootSeg) || node.headline || root.title,
    );
    this._writeSectionBody(b, node, rootSeg);
    this._writeChildren(b, node, rootSeg, 2);
    return b.toString();
  }

  /**
   * Writes the body region of a section heading: the section path's own
   * content value plus every transparent body slot (id-less content text and
   * form blocks, hoisted through transparent sections) in model order.
   */
  _writeSectionBody(b, node, path) {
    this._writeBody(b, this.document.content(path), path);
    for (const [slot, rel] of this._bodySlots(node)) {
      const slotPath = `${path}/${rel}`;
      if (slot.kind === SomMetaKind.FORM) {
        if (this._formHasValues(slot, slotPath)) {
          this._writeForm(b, slot, slotPath);
        }
      } else {
        this._writeBody(b, this.document.content(slotPath), slotPath);
      }
    }
  }

  _writeChildren(b, node, basePath, depth) {
    for (const [child, rel] of this._effectiveChildren(node)) {
      const path = `${basePath}/${rel}`;
      if (!this.document.hasValuesUnder(path)) {
        continue;
      }
      const kind = child.kind;
      if (
        kind === SomMetaKind.CONTENT ||
        kind === SomMetaKind.SCALAR ||
        kind === SomMetaKind.ENUM_VALUE
      ) {
        const value = this.document.content(path);
        if (value === null) {
          continue;
        }
        SpecDocumentMarkdown._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          this.document.headline(path) || SpecDocumentMarkdown._titleOf(child),
        );
        this._writeBody(b, value, path);
      } else if (kind === SomMetaKind.FORM) {
        if (!this._formHasValues(child, path)) {
          continue;
        }
        SpecDocumentMarkdown._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          this.document.headline(path) || SpecDocumentMarkdown._titleOf(child),
        );
        this._writeForm(b, child, path);
      } else if (kind === SomMetaKind.SECTION || kind === SomMetaKind.COMPLEX) {
        SpecDocumentMarkdown._writeHeading(
          b,
          depth,
          this._headingIdOf(child),
          this.document.headline(path) || SpecDocumentMarkdown._titleOf(child),
        );
        this._writeSectionBody(b, child, path);
        this._writeChildren(b, child, path, depth + 1);
      } else if (kind === SomMetaKind.LIST) {
        this._writeListItems(b, child, path, depth);
      }
    }
  }

  /**
   * Emits list `node` as its `-LST` container heading (DR1 §1.2/§1.5) at
   * `depth`, wrapping the numbered item headings one level deeper. The
   * container is a real section — the id the DR3 schema keys its container
   * type by — but carries **no content of its own** (schema content
   * min/max-text-length 0). Item identity is purely positional.
   */
  _writeListItems(b, node, listPath, depth) {
    const items = this.document.listItems(listPath);
    if (items.length === 0) return;
    // The container heading: its id is the list's `-LST` `@SectionId` (else the
    // member segment for a pattern-less list); its title is the member name.
    SpecDocumentMarkdown._writeHeading(
      b,
      depth,
      this._headingIdOf(node),
      this.document.headline(listPath) || SpecDocumentMarkdown._titleOf(node),
    );
    // Item heading stem. Complex lists derive it from the element class name
    // (DR1 §1.5, `Entry` dropped). A scalar list (shape 6) has no element class
    // — its element `typeName` is literally `String`, which would render
    // "String 1", "String 2". Derive the stem from the list FIELD instead (its
    // member name, Title-Cased like the container heading) so a populated
    // scalar list gets meaningful per-item headings (YRC5).
    const element = node.elementNode;
    const stem = SpecDocumentMarkdown._itemStemOf(node);
    const pattern =
      node.sectionIdPattern ||
      (element !== null && element !== undefined
        ? element.sectionIdPattern
        : null) ||
      null;
    for (let i = 0; i < items.length; i++) {
      const itemPath = items[i];
      const pos = i + 1;
      // YRD3 (superseding DRC5): a stored `@SectionId` (AA1 generated or a
      // criterion-5 override) IS the md heading id. Only items without one
      // fall back to the `@SectionIdPattern` resolved with the 1-based
      // position (`GOAL-ITEM-xxx` → `GOAL-ITEM-1`), then to `<member>-<pos>`
      // for pattern-less lists. Items sit one level below the container.
      const storedId = this.document.itemSectionId(itemPath);
      let itemId;
      if (storedId !== null) {
        itemId = storedId;
      } else if (pattern !== null) {
        itemId = pattern.split('xxx').join(String(pos));
      } else {
        itemId = `${node.memberName || node.segment}-${pos}`;
      }
      SpecDocumentMarkdown._writeHeading(
        b,
        depth + 1,
        itemId,
        this.document.headline(itemPath) || `${stem} ${pos}`,
      );
      if (element === null || element === undefined) {
        // Scalar list: the item's value is its body.
        this._writeBody(b, this.document.content(itemPath) || '', itemPath);
      } else {
        this._writeSectionBody(b, element, itemPath);
        if (!element.recursive) {
          this._writeChildren(b, element, itemPath, depth + 2);
        }
      }
    }
  }

  _formHasValues(node, path) {
    const fields = node.form !== null && node.form !== undefined ? node.form.fields : [];
    for (const f of fields) {
      if (f.role !== null) {
        continue; // YRD6: role values live in the heading.
      }
      if (this.document.formField(path, f.name) !== null) {
        return true;
      }
    }
    return false;
  }

  _writeForm(b, node, path) {
    const fields = node.form !== null && node.form !== undefined ? node.form.fields : [];
    for (const f of fields) {
      // YRD6: a role field's value is emitted exactly once — as the owning
      // section's heading text / id comment — never as a form line.
      if (f.role !== null) {
        continue;
      }
      const value = this.document.formField(path, f.name);
      if (value === null) {
        continue;
      }
      const lines = this._prepareValue(value, path).split('\n');
      b.writeln(`${SpecDocumentMarkdown.formLabel(f.name)}: ${lines[0]}`);
      for (const line of lines.slice(1)) {
        // §1.4.3 generalised: any continuation line that could be mistaken
        // for a field-label line gains one leading space; parse strips it.
        b.writeln(_LABEL_SHAPED.test(line) ? ` ${line}` : line);
      }
    }
    b.writeln();
  }

  /**
   * `## <!--[ID]--> Title` at `depth`. DR1 §1.2 is normative — heading level
   * = 1 + section depth, **uncapped**: deep models (the Solution Blueprint
   * nests past markdown's native 6 levels) keep their structure; the parse
   * grammar accepts `#{7,}` accordingly. Capping would silently flatten
   * distinct nesting positions into siblings and break schema validation.
   */
  static _writeHeading(b, depth, id, title) {
    b.writeln(`${'#'.repeat(depth)} <!--[${id}]--> ${title}`);
    b.writeln();
  }

  /**
   * Writes `value` as a section body followed by a blank line; no-op for
   * `null`/blank values.
   */
  _writeBody(b, value, path) {
    if (value === null || value === undefined) {
      return;
    }
    const prepared = this._prepareValue(value, path);
    if (!prepared) {
      return;
    }
    b.writeln(prepared);
    b.writeln();
  }

  /**
   * Emit-side value normalisation (DR1 §1.3): collapse 2+ blank lines to one,
   * trim leading/trailing blank lines, escape heading-like lines outside
   * fences. Throws an {@link Error} for an unterminated fence.
   */
  _prepareValue(value, path) {
    let collapsed = value.replace(/\n{3,}/g, '\n\n');
    collapsed = collapsed.replace(/^\n+/, '');
    collapsed = collapsed.replace(/\n+$/, '');
    const fence = new MarkdownFenceTracker();
    const out = [];
    for (const line of collapsed.split('\n')) {
      if (fence.inFence) {
        out.push(line); // §1.3.4: fences shield their lines.
      } else if (_ESCAPABLE.test(line)) {
        out.push(`\\${line}`);
      } else {
        out.push(line);
      }
      fence.feed(line);
    }
    if (fence.inFence) {
      throw new Error(
        `content at "${path}" contains an unterminated fenced code block; ` +
          'it cannot be represented in the DocSpecs markdown format',
      );
    }
    return out.join('\n');
  }

  /**
   * The effective DEFAULT title of `node` (YRD4): the `@Headline` default
   * when authored, else the name derivation. The stored headline (checked by
   * callers first) always wins over this.
   */
  static _titleOf(node) {
    return (
      node.headline ||
      SpecDocumentMarkdown.titleCase(node.memberName || node.className)
    );
  }

  /**
   * The effective default item-title stem of list `node` (YRD4): the element
   * class's `@Headline` default when authored, else the DR1 §1.5 derivation
   * (element class name with `Entry` dropped; member name for scalar lists).
   */
  static _itemStemOf(node) {
    const element = node.elementNode;
    return element !== null && element !== undefined
      ? element.headline ||
          SpecDocumentMarkdown.itemTitleStem(element.className)
      : SpecDocumentMarkdown.titleCase(node.memberName || node.segment);
  }

  // --- Import (DR1 §1.7) ----------------------------------------------------

  /**
   * Parses `text` into staged values + a rejection report, **without**
   * mutating the document. The caller applies the result as a full overwrite.
   *
   * @returns {SpecMarkdownResult}
   */
  parse(text) {
    const p = new _Parser(this);
    p.run(text.split('\n'));
    const result = new SpecMarkdownResult();
    result.content = p.content;
    result.forms = p.forms;
    result.lists = p.listsJson();
    result.headlines = p.headlines;
    result.rejections = p.rejections;
    result.rootPrefixes = p.rootPrefixes;
    return result;
  }
}

// Shared with the parser and the DocSpecs validator.
SpecDocumentMarkdown.headingLine = /^(#+)\s+(.*)$/;
SpecDocumentMarkdown.headlineComment = /^<!--\[([^\]]+)\]-->\s*(.*)$/;
SpecDocumentMarkdown.docspecComment = /^<!--\s*docspec:.*-->\s*$/;

/**
 * One open section during the parse: its heading level, resolved node (`null`
 * for an unresolvable/ignored section), path, and accumulated body lines.
 */
class _Frame {
  constructor(level, node, path, line, ignored = false) {
    this.level = level;
    this.node = node;
    this.path = path;
    this.line = line;
    this.ignored = ignored;
    /** @type {string[]} */
    this.body = [];
  }
}

/**
 * Per-list bookkeeping while parsing: ordered item paths, stored ids, and the
 * highest item number handed out (drives both fresh numbers for stored-id
 * items and the resulting `seq`).
 */
class _ListState {
  constructor() {
    /** @type {string[]} */
    this.items = [];
    /** @type {Object<string, string>} */
    this.ids = {};
    this.maxN = 0;
  }
}

class _Parser {
  constructor(codec) {
    this.codec = codec;
    /** @type {Object<string, string>} */
    this.content = {};
    /** @type {Object<string, Object<string, string>>} */
    this.forms = {};
    /** @type {Map<string, _ListState>} */
    this.lists = new Map();
    /** Stored headlines staged from heading text (YRD3): path → headline.
     *  @type {Object<string, string>} */
    this.headlines = {};
    /** @type {SpecMarkdownRejection[]} */
    this.rejections = [];
    /** @type {Set<string>} */
    this.rootPrefixes = new Set();
    /** @type {_Frame[]} */
    this._stack = [];
    this._fence = new MarkdownFenceTracker();
    // Rolling pointer into a body region's transparent form slots — labels
    // bind to the nearest form at or after the last hit (wrapping), so
    // repeated field names across an owner's transparent forms follow emit
    // order.
    this._currentFormIdx = 0;
  }

  run(lines) {
    for (let i = 0; i < lines.length; i++) {
      const raw = lines[i];
      const lineNo = i + 1;
      const trimmed = raw.replace(/\s+$/, '');

      if (!this._fence.inFence) {
        if (
          this._stack.length === 0 &&
          SpecDocumentMarkdown.docspecComment.test(trimmed)
        ) {
          continue; // §1.1 header — informational.
        }
        const h = SpecDocumentMarkdown.headingLine.exec(trimmed);
        if (h !== null) {
          this._closeTo(h[1].length);
          this._openHeading(h[1].length, h[2], lineNo);
          continue;
        }
      }
      if (this._stack.length > 0) {
        this._stack[this._stack.length - 1].body.push(raw);
      } else if (trimmed) {
        this.rejections.push(
          new SpecMarkdownRejection(
            lineNo,
            SpecMarkdownRejectReason.ORPHAN_CONTENT,
            'text before the document root heading',
          ),
        );
      }
      this._fence.feed(raw);
    }
    this._closeTo(1);
    if (this._stack.length > 0) {
      this._finalize(this._stack.pop());
    }
  }

  /** Pops (and finalizes) every frame at `level` or deeper. */
  _closeTo(level) {
    while (
      this._stack.length > 0 &&
      this._stack[this._stack.length - 1].level >= level
    ) {
      this._finalize(this._stack.pop());
    }
  }

  _openHeading(level, rest, lineNo) {
    const m = SpecDocumentMarkdown.headlineComment.exec(rest.trim());
    if (m === null) {
      this.rejections.push(
        new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.MALFORMED_HEADING,
          'heading carries no <!--[SECTION-ID]--> headline comment',
          rest.trim(),
        ),
      );
      this._stack.push(new _Frame(level, null, '', lineNo, true));
      return;
    }
    const id = m[1];
    const title = m[2].trim();

    if (this._stack.length === 0) {
      this._openRoot(level, id, title, lineNo);
      return;
    }

    const parent = this._stack[this._stack.length - 1];
    if (parent.ignored) {
      this.rejections.push(
        new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.UNKNOWN_SECTION,
          'section nested under an unresolvable parent',
          id,
        ),
      );
      this._stack.push(new _Frame(level, null, '', lineNo, true));
      return;
    }
    const pNode = parent.node;
    if (pNode === null || _Parser._isValueLeaf(pNode.kind)) {
      this.rejections.push(
        new SpecMarkdownRejection(
          lineNo,
          SpecMarkdownRejectReason.KIND_MISMATCH,
          'child heading under a value-leaf or form section',
          id,
        ),
      );
      this._stack.push(new _Frame(level, null, '', lineNo, true));
      return;
    }

    // 1. Under a `-LST` container frame (DR1 §1.2), every child heading is one
    //    of that list's items — resolved positionally, not by the schema tree.
    if (pNode.kind === SomMetaKind.LIST) {
      this._openItemHeading(level, parent, pNode, id, title, lineNo);
      return;
    }

    // 2. A regular (non-list) or list-**container** *effective* child —
    //    section-bearing children hoisted through transparent sections — whose
    //    heading id matches. A list heads its `-LST` container here; its items
    //    are resolved above once the container frame is open. Transparent value
    //    members never head, so they never match; the bound path runs through
    //    the transparent segments.
    const effective = this.codec._effectiveChildren(pNode);
    for (const [c, rel] of effective) {
      if (this.codec._headingIdOf(c) === id) {
        // Stage the heading text as a stored headline only when it differs
        // from the effective default title (YRD3 §8.7 — byte-stability).
        if (title && title !== SpecDocumentMarkdown._titleOf(c)) {
          this.headlines[`${parent.path}/${rel}`] = title;
        }
        this._stack.push(
          new _Frame(level, c, `${parent.path}/${rel}`, lineNo),
        );
        return;
      }
    }

    this.rejections.push(
      new SpecMarkdownRejection(
        lineNo,
        SpecMarkdownRejectReason.UNKNOWN_SECTION,
        'section id does not resolve against the schema tree at this ' +
          `position (under "${parent.path}")`,
        id,
      ),
    );
    this._stack.push(new _Frame(level, null, '', lineNo, true));
  }

  /**
   * Opens a list-item frame under a `-LST` container frame (DR1 §1.2). The
   * heading `id` is matched positionally against the container's list: the
   * `<member>-<n>` fallback id, the `@SectionIdPattern` resolved with a number
   * (`GOAL-ITEM-3`, parses back as item `<n>`), a pattern-shaped stored id, or
   * — for any other id — an anonymous next item carrying the stored id.
   */
  _openItemHeading(level, container, listNode, id, title, lineNo) {
    const listPath = container.path;
    const anon = new RegExp(
      '^' + _escapeRegExp(listNode.memberName || listNode.segment) + '-([0-9]+)$',
    ).exec(id);
    if (anon !== null) {
      this._openItem(
        level, listPath, listNode, parseInt(anon[1], 10), null, title, lineNo,
      );
      return;
    }
    const element = listNode.elementNode;
    const pattern =
      listNode.sectionIdPattern ||
      (element !== null && element !== undefined
        ? element.sectionIdPattern
        : null) ||
      null;
    if (pattern !== null) {
      // Canonical anonymous id: the pattern with `xxx` as a number — parses
      // back as item <n>, NOT as a stored id (DR1 §1.2 round-trip).
      const parts = pattern.split('xxx');
      if (parts.length === 2) {
        const numbered = new RegExp(
          '^' + parts.map(_escapeRegExp).join('([0-9]+)') + '$',
        ).exec(id);
        if (numbered !== null) {
          this._openItem(
            level,
            listPath,
            listNode,
            parseInt(numbered[1], 10),
            null,
            title,
            lineNo,
          );
          return;
        }
      }
      if (_Parser._patternMatches(pattern, id)) {
        this._openItem(level, listPath, listNode, null, id, title, lineNo);
        return;
      }
    }
    // Any other id under the container is an anonymous next item carrying the
    // stored id — stored ids round-trip through Markdown too (YRD3).
    this._openItem(level, listPath, listNode, null, id, title, lineNo);
  }

  _openRoot(level, id, title, lineNo) {
    for (const root of this.codec.model.roots) {
      const seg = root.sectionId || root.type;
      if (seg === id) {
        const tree = this.codec._treeFor(root.type);
        this.rootPrefixes.add(seg);
        // YRD3: stage a renamed root heading as a stored headline —
        // "renamed" relative to the effective default (YRD4: `@Headline`
        // default, else the `@Document` title).
        if (title && title !== (tree.root.headline || root.title)) {
          this.headlines[seg] = title;
        }
        this._stack.push(new _Frame(level, tree.root, seg, lineNo));
        return;
      }
    }
    const known = this.codec.model.roots
      .map((r) => r.sectionId || r.type)
      .join(', ');
    this.rejections.push(
      new SpecMarkdownRejection(
        lineNo,
        SpecMarkdownRejectReason.UNKNOWN_SECTION,
        `no document root with this section id (known: ${known})`,
        id,
      ),
    );
    this._stack.push(new _Frame(level, null, '', lineNo, true));
  }

  /**
   * Opens a list-item frame. `n` is the anonymous heading number (also the
   * path number); a stored-id item gets the next free number instead.
   */
  _openItem(level, listPath, listNode, n, storedId, title, lineNo) {
    let state = this.lists.get(listPath);
    if (!state) {
      state = new _ListState();
      this.lists.set(listPath, state);
    }
    const number = n !== null ? n : state.maxN + 1;
    if (number > state.maxN) {
      state.maxN = number;
    }
    const itemPath = `${listPath}-${number}`;
    state.items.push(itemPath);
    // Stage the item heading text as a stored headline only when it differs
    // from the effective default `<stem> <n>` title (YRD3 §8.7).
    const stem = SpecDocumentMarkdown._itemStemOf(listNode);
    if (title && title !== `${stem} ${number}`) {
      this.headlines[itemPath] = title;
    }
    if (storedId !== null) {
      state.ids[itemPath] = storedId;
    }
    this._stack.push(new _Frame(level, listNode.elementNode, itemPath, lineNo));
  }

  /**
   * `GOAL-ITEM-xxx` → `^GOAL-ITEM-.+$` — the `@SectionIdPattern` wildcard.
   */
  static _patternMatches(pattern, id) {
    const regex = new RegExp(
      '^' + pattern.split('xxx').map(_escapeRegExp).join('.+') + '$',
    );
    return regex.test(id);
  }

  static _isValueLeaf(kind) {
    return (
      kind === SomMetaKind.CONTENT ||
      kind === SomMetaKind.SCALAR ||
      kind === SomMetaKind.ENUM_VALUE
    );
  }

  // --- Body finalisation ----------------------------------------------------

  _finalize(frame) {
    if (frame.ignored) {
      return;
    }
    const node = frame.node;
    if (node !== null && node.kind === SomMetaKind.FORM) {
      this._finalizeForm(frame, node, frame.path);
      return;
    }
    const slots = node === null ? [] : this.codec._bodySlots(node);
    if (slots.length === 0) {
      const value = _Parser._restoreValue(frame.body);
      if (value) {
        this.content[frame.path] = value;
      } else if (node !== null && _Parser._isValueLeaf(node.kind)) {
        this.rejections.push(
          new SpecMarkdownRejection(
            frame.line,
            SpecMarkdownRejectReason.MISSING_VALUE,
            'no value text under this section heading',
            frame.path,
          ),
        );
      }
      return;
    }
    this._finalizeBodySlots(frame, slots);
  }

  /**
   * Binds a heading's body region against the owner's transparent body slots
   * (DR1 §1.2 transparency): `FieldName:` lines matching a transparent form's
   * fields route to that form (nearest form in slot order, wrapping); all
   * other text binds to the first non-form slot — or to the owner's own path
   * when no such slot exists.
   */
  _finalizeBodySlots(frame, slots) {
    const formSlots = slots.filter(([s]) => s.kind === SomMetaKind.FORM);
    const contentSlots = slots.filter(([s]) => s.kind !== SomMetaKind.FORM);
    const contentPath =
      contentSlots.length > 0
        ? `${frame.path}/${contentSlots[0][1]}`
        : frame.path;

    if (formSlots.length === 0) {
      const value = _Parser._restoreValue(frame.body);
      if (value) {
        this.content[contentPath] = value;
      }
      return;
    }

    const findField = (label) => {
      const lower = label.toLowerCase();
      for (let k = 0; k < formSlots.length; k++) {
        const idx = (this._currentFormIdx + k) % formSlots.length;
        const form = formSlots[idx][0].form;
        const fields = form !== null && form !== undefined ? form.fields : [];
        for (const f of fields) {
          if (f.name.toLowerCase() === lower) {
            return [idx, f];
          }
        }
      }
      return null;
    };

    const fence = new MarkdownFenceTracker();
    let currentField = null;
    let currentFormPath = null;
    let dropping = false;
    let currentLines = [];
    const contentLines = [];

    const flush = () => {
      if (currentField !== null && currentFormPath !== null) {
        const value = _Parser._restoreValue(currentLines);
        if (value) {
          if (!this.forms[currentFormPath]) {
            this.forms[currentFormPath] = {};
          }
          this.forms[currentFormPath][currentField] = value;
        }
      }
      currentLines = [];
    };

    this._currentFormIdx = 0;
    for (let i = 0; i < frame.body.length; i++) {
      const line = frame.body[i];
      if (!fence.inFence) {
        const m = _FIELD_LABEL.exec(line);
        if (m !== null) {
          const hit = findField(m[1]);
          if (hit !== null) {
            flush();
            // YRD6: a title/id role field's value is the owning section's
            // heading / id comment — a form line duplicating it is rejected,
            // never stored (continuation lines are dropped with it).
            if (hit[1].role !== null) {
              this.rejections.push(
                new SpecMarkdownRejection(
                  frame.line + i,
                  SpecMarkdownRejectReason.ROLE_FIELD_FORM_LINE,
                  `form field \`${hit[1].name}\` is a title/id role field — ` +
                    'its value is the section heading, not a form line',
                  `${frame.path}/${formSlots[hit[0]][1]}`,
                ),
              );
              currentField = null;
              currentFormPath = null;
              dropping = true;
              currentLines = [];
              fence.feed(line);
              continue;
            }
            this._currentFormIdx = hit[0];
            currentField = hit[1].name;
            currentFormPath = `${frame.path}/${formSlots[hit[0]][1]}`;
            currentLines = [m[2]];
            dropping = false;
            fence.feed(line);
            continue;
          }
        }
      }
      if (dropping) {
        fence.feed(line);
        continue;
      }
      const target = currentField === null ? contentLines : currentLines;
      // Continuation: strip the one escape space of a label-shaped line.
      if (
        !fence.inFence &&
        currentField !== null &&
        _CONTINUATION_LABEL.test(line)
      ) {
        target.push(line.slice(1));
      } else {
        target.push(line);
      }
      fence.feed(line);
    }
    flush();
    const value = _Parser._restoreValue(contentLines);
    if (value) {
      this.content[contentPath] = value;
    }
  }

  _finalizeForm(frame, node, path) {
    const form = node.form;
    const fields = form !== null && form !== undefined ? form.fields : [];
    const fieldsByLower = new Map(
      fields.map((f) => [f.name.toLowerCase(), f.name]),
    );
    // YRD6: role fields (title/id) are represented by the section heading /
    // id comment — a form line duplicating one is rejected, never stored.
    const roleFields = new Set(
      fields.filter((f) => f.role !== null).map((f) => f.name),
    );
    const fence = new MarkdownFenceTracker();
    let currentField = null;
    let dropping = false;
    let currentLines = [];

    const flush = (lineNo) => {
      if (currentField !== null) {
        const value = _Parser._restoreValue(currentLines);
        if (value) {
          if (!this.forms[path]) {
            this.forms[path] = {};
          }
          this.forms[path][currentField] = value;
        }
      } else if (!dropping && currentLines.some((l) => l.trim())) {
        this.rejections.push(
          new SpecMarkdownRejection(
            lineNo,
            SpecMarkdownRejectReason.ORPHAN_CONTENT,
            'text in a @Form section before the first field label',
            path,
          ),
        );
      }
      dropping = false;
      currentLines = [];
    };

    for (let i = 0; i < frame.body.length; i++) {
      const line = frame.body[i];
      if (!fence.inFence) {
        const m = _FIELD_LABEL.exec(line);
        const fieldName =
          m !== null ? fieldsByLower.get(m[1].toLowerCase()) : undefined;
        if (fieldName !== undefined && m !== null) {
          flush(frame.line + i);
          if (roleFields.has(fieldName)) {
            this.rejections.push(
              new SpecMarkdownRejection(
                frame.line + i,
                SpecMarkdownRejectReason.ROLE_FIELD_FORM_LINE,
                `form field \`${fieldName}\` is a title/id role field — ` +
                  'its value is the section heading, not a form line',
                path,
              ),
            );
            currentField = null;
            dropping = true;
            currentLines = [];
            fence.feed(line);
            continue;
          }
          currentField = fieldName;
          currentLines = [m[2]];
          fence.feed(line);
          continue;
        }
      }
      // Continuation: strip the one escape space of a label-shaped line.
      if (!fence.inFence && _CONTINUATION_LABEL.test(line)) {
        currentLines.push(line.slice(1));
      } else {
        currentLines.push(line);
      }
      fence.feed(line);
    }
    flush(frame.line + frame.body.length);
  }

  /**
   * Parse-side value restoration (DR1 §1.3): trim leading/trailing blank
   * lines and unescape `\#`-escaped heading lines outside fences.
   */
  static _restoreValue(body) {
    const fence = new MarkdownFenceTracker();
    const out = [];
    for (const line of body) {
      if (!fence.inFence && _ESCAPED_HEADING.test(line)) {
        out.push(line.slice(1));
      } else {
        out.push(line);
      }
      fence.feed(line);
    }
    let joined = out.join('\n');
    joined = joined.replace(/^([ \t]*\n)+/, '');
    joined = joined.replace(/(\n[ \t]*)+$/, '');
    return joined;
  }

  listsJson() {
    const out = {};
    for (const [key, state] of this.lists) {
      const entry = { seq: state.maxN, items: state.items.slice() };
      if (Object.keys(state.ids).length > 0) {
        entry.ids = { ...state.ids };
      }
      out[key] = entry;
    }
    return out;
  }
}

module.exports = {
  SpecMarkdownRejectReason,
  SpecMarkdownRejection,
  SpecMarkdownResult,
  MarkdownFenceTracker,
  SpecDocumentMarkdown,
};
