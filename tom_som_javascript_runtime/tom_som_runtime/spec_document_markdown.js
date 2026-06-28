'use strict';

/**
 * Generic, meta-data-driven Markdown codec for a TomSpecs document — a faithful
 * port of `tom_som_dart_runtime/lib/src/spec_document_markdown.dart` (and
 * `spec_document_markdown.py`).
 *
 * A `<!-- docspec: -->` header, then one heading per **populated** section
 * (sparse, in schema order), with each section's machine-readable **section
 * path** as the first token of its heading so import maps back unambiguously.
 * Leaf values live in **fenced code blocks** whose fence is widened past any
 * backtick run in the value, so embedded code bodies round-trip **verbatim**.
 * Form fields are introduced by a `<!-- field: name -->` anchor; list items
 * appear as nested `…-N` sections, so list membership is recovered from the paths
 * alone on import.
 *
 * {@link SpecDocumentMarkdown#parse} does **not** mutate the document — it returns
 * staged values keyed exactly like {@link SpecDocument#toJson} plus a rejection
 * report; the caller applies them.
 */

const { SpecFieldKind } = require('./spec_model');
const { SpecNodeKind, SpecReflection } = require('./spec_reflection');

const _HEADING_RE = /^(#{1,6})\s+(\S+)/;
const _FIELD_ANCHOR_RE = /^<!--\s*field:\s*(\S+)\s*-->$/;
const _FENCE_OPEN_RE = /^(`{3,})/;
const _ITEM_SEG_RE = /^(.+)-(\d+)$/;

/** Why an imported Markdown block was rejected. */
const SpecMarkdownRejectReason = Object.freeze({
  UNKNOWN_SECTION: 'unknownSection',
  KIND_MISMATCH: 'kindMismatch',
  ORPHAN_BLOCK: 'orphanBlock',
  MISSING_VALUE: 'missingValue',
  MALFORMED_HEADING: 'malformedHeading',
});

/** One rejected block in a Markdown import. Reported, never silently dropped. */
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
 * The outcome of parsing a Markdown document: the staged values plus every
 * rejected block. The values are keyed exactly like {@link SpecDocument#toJson}.
 */
class SpecMarkdownResult {
  constructor() {
    /** @type {Object<string, string>} */
    this.content = {};
    /** @type {Object<string, Object<string, string>>} */
    this.forms = {};
    /** @type {Object<string, {seq: number, items: string[]}>} */
    this.lists = {};
    /** @type {SpecMarkdownRejection[]} */
    this.rejections = [];
    /** @type {Set<string>} */
    this.rootPrefixes = new Set();
  }

  get isClean() {
    return this.rejections.length === 0;
  }

  get appliedCount() {
    let n = Object.keys(this.content).length;
    for (const m of Object.values(this.forms)) {
      n += Object.keys(m).length;
    }
    return n;
  }
}

/** A pending value target between a section/field anchor and its fenced block. */
class _Pending {
  constructor(line, path, field) {
    this.line = line;
    this.path = path;
    this.field = field;
    this.filled = false;
  }

  get anchor() {
    return this.field !== null ? `${this.path} :: ${this.field}` : this.path;
  }
}

/**
 * A fenced code block holding `value` verbatim. The fence is one backtick longer
 * than the longest backtick run in `value` (min 3).
 */
function _fence(value, info = '') {
  let maxRun = 0;
  let run = 0;
  for (const ch of value) {
    if (ch === '`') {
      run++;
      if (run > maxRun) {
        maxRun = run;
      }
    } else {
      run = 0;
    }
  }
  const n = maxRun + 1 >= 3 ? maxRun + 1 : 3;
  const f = '`'.repeat(n);
  const parts = [`${f}${info}\n`];
  for (const line of value.split('\n')) {
    parts.push(`${line}\n`);
  }
  parts.push(f);
  return parts.join('');
}

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

function _heading(b, depth, path, name) {
  const hashes = '#'.repeat(depth > 6 ? 6 : depth);
  b.writeln(`${hashes} ${path} — ${name}`);
}

/**
 * Codec binding a {@link SpecModel} and a concrete {@link SpecDocument} to the
 * Markdown import/export format.
 */
class SpecDocumentMarkdown {
  constructor(model, document) {
    this.model = model;
    this.document = document;
    this._reflection = new SpecReflection(model);
  }

  _rootSeg(r) {
    return this._reflection.rootSegment(r);
  }

  _fieldSeg(f) {
    return this._reflection.fieldSegment(f);
  }

  // --- Export -------------------------------------------------------------

  /**
   * Renders the populated subtree of `root` as a schema-conformant Markdown
   * document with a `<!-- docspec: -->` header.
   */
  exportRoot(root) {
    const b = new _Buffer();
    const seg = this._rootSeg(root);
    b.writeln(`<!-- docspec: ${seg.toLowerCase()}/1 -->`);
    b.writeln(`# ${seg} — ${root.title}`);
    const cls = this.model.classNamed(root.type);
    if (root.description !== null && root.description.trim() !== '') {
      b.writeln();
      b.writeln(root.description.trim());
    }
    if (cls !== null) {
      this._exportClass(b, cls, seg, 2, new Set([root.type]));
    }
    return b.toString();
  }

  _exportClass(b, cls, basePath, depth, seenTypes) {
    for (const field of cls.fields) {
      const path = `${basePath}/${this._fieldSeg(field)}`;
      if (!this.document.hasValuesUnder(path)) {
        continue;
      }
      const kind = field.kind;
      if (
        kind === SpecFieldKind.CONTENT ||
        kind === SpecFieldKind.SCALAR ||
        kind === SpecFieldKind.ENUM
      ) {
        const value = this.document.content(path);
        if (value === null) {
          continue;
        }
        _heading(b, depth, path, field.name);
        b.writeln(_fence(value, field.contentType || ''));
        b.writeln();
      } else if (kind === SpecFieldKind.FORM) {
        _heading(b, depth, path, field.name);
        for (const ff of field.formFields) {
          const value = this.document.formField(path, ff.name);
          if (value === null) {
            continue;
          }
          b.writeln(`<!-- field: ${ff.name} -->`);
          b.writeln(_fence(value));
          b.writeln();
        }
      } else if (kind === SpecFieldKind.LIST) {
        const elem = this.model.classNamed(field.elementType);
        const recursive =
          field.elementType !== null && seenTypes.has(field.elementType);
        _heading(b, depth, path, field.name);
        b.writeln();
        if (elem === null || recursive) {
          continue;
        }
        const nextSeen = new Set(seenTypes);
        nextSeen.add(field.elementType);
        for (const itemPath of this.document.listItems(path)) {
          _heading(b, depth + 1, itemPath, field.elementType || 'item');
          b.writeln();
          this._exportClass(b, elem, itemPath, depth + 2, nextSeen);
        }
      } else if (kind === SpecFieldKind.COMPLEX || kind === SpecFieldKind.SECTION) {
        const nested = this.model.classNamed(field.type);
        const recursive = field.type !== null && seenTypes.has(field.type);
        if (nested === null || recursive) {
          continue;
        }
        _heading(b, depth, path, field.name);
        b.writeln();
        const nextSeen = new Set(seenTypes);
        nextSeen.add(field.type);
        this._exportClass(b, nested, path, depth + 1, nextSeen);
      }
    }
  }

  // --- Import -------------------------------------------------------------

  /**
   * Parses `text` into staged values + a rejection report, **without** mutating
   * the document.
   *
   * @returns {SpecMarkdownResult}
   */
  parse(text) {
    const lines = text.split('\n');
    const result = new SpecMarkdownResult();
    const content = result.content;
    const forms = result.forms;
    const rejections = result.rejections;
    const rootPrefixes = result.rootPrefixes;

    let pending = null;

    const flushMissing = () => {
      if (pending !== null && !pending.filled) {
        rejections.push(
          new SpecMarkdownRejection(
            pending.line,
            SpecMarkdownRejectReason.MISSING_VALUE,
            'no fenced value followed this anchor',
            pending.anchor,
          ),
        );
      }
      pending = null;
    };

    let i = 0;
    let currentKind = null;
    let currentPath = null;
    while (i < lines.length) {
      const raw = lines[i];
      const lineNo = i + 1;
      const trimmed = raw.replace(/\s+$/, '');

      // Heading.
      const heading = _headingPath(trimmed);
      if (heading !== null) {
        flushMissing();
        const path = heading;
        const node = this._reflection.resolve(path);
        if (node === null) {
          rejections.push(
            new SpecMarkdownRejection(
              lineNo,
              SpecMarkdownRejectReason.UNKNOWN_SECTION,
              'section path does not resolve against the model',
              path,
            ),
          );
          currentKind = null;
          currentPath = null;
          i += 1;
          continue;
        }
        currentKind = node.kind;
        currentPath = path;
        rootPrefixes.add(path.split('/')[0]);
        if (node.isValueLeaf) {
          pending = new _Pending(lineNo, path, null);
        }
        i += 1;
        continue;
      }

      // Form-field anchor.
      const fieldName = _fieldAnchor(trimmed);
      if (fieldName !== null) {
        flushMissing();
        if (currentPath === null || currentKind !== SpecNodeKind.FORM) {
          rejections.push(
            new SpecMarkdownRejection(
              lineNo,
              SpecMarkdownRejectReason.KIND_MISMATCH,
              'form-field anchor outside a `@Form` section',
              fieldName,
            ),
          );
          i += 1;
          continue;
        }
        pending = new _Pending(lineNo, currentPath, fieldName);
        i += 1;
        continue;
      }

      // Fence opener.
      const fenceLen = _fenceOpen(trimmed);
      if (fenceLen !== null) {
        const body = [];
        let j = i + 1;
        const closer = '`'.repeat(fenceLen);
        while (j < lines.length && lines[j].replace(/\s+$/, '') !== closer) {
          body.push(lines[j]);
          j += 1;
        }
        const value = body.join('\n');
        if (pending === null) {
          rejections.push(
            new SpecMarkdownRejection(
              lineNo,
              SpecMarkdownRejectReason.ORPHAN_BLOCK,
              'fenced value with no owning section or field',
            ),
          );
        } else if (pending.field !== null) {
          if (!forms[pending.path]) {
            forms[pending.path] = {};
          }
          forms[pending.path][pending.field] = value;
          pending.filled = true;
        } else {
          content[pending.path] = value;
          pending.filled = true;
        }
        pending = null;
        i = j < lines.length ? j + 1 : j;
        continue;
      }

      i += 1;
    }
    flushMissing();

    result.lists = this._reconstructLists(Object.keys(content), Object.keys(forms));
    return result;
  }

  /**
   * Recovers list membership from the leaf paths: any `<base>-<n>` segment whose
   * `<base>` ancestor resolves to a list field denotes item `<n>` of that list.
   */
  _reconstructLists(contentKeys, formKeys) {
    const items = {};
    const seq = {};

    const scan = (path) => {
      const segs = path.split('/');
      let prefix = segs[0];
      for (let k = 1; k < segs.length; k++) {
        const seg = segs[k];
        const m = _ITEM_SEG_RE.exec(seg);
        if (m !== null) {
          const listPath = `${prefix}/${m[1]}`;
          const itemPath = `${prefix}/${seg}`;
          const node = this._reflection.resolve(listPath);
          if (node !== null && node.kind === SpecNodeKind.LIST) {
            if (!items[listPath]) {
              items[listPath] = [];
            }
            const bucket = items[listPath];
            if (!bucket.includes(itemPath)) {
              bucket.push(itemPath);
            }
            const n = parseInt(m[2], 10);
            if (n > (seq[listPath] || 0)) {
              seq[listPath] = n;
            }
          }
        }
        prefix = `${prefix}/${seg}`;
      }
    };

    for (const p of contentKeys) {
      scan(p);
    }
    for (const p of formKeys) {
      scan(p);
    }
    const out = {};
    for (const [key, value] of Object.entries(items)) {
      out[key] = { seq: seq[key] != null ? seq[key] : value.length, items: value };
    }
    return out;
  }
}

/** The section path of a heading line (`#{1,6} <path> …`), or `null`. */
function _headingPath(line) {
  const m = _HEADING_RE.exec(line);
  return m ? m[2] : null;
}

/** The field name of a `<!-- field: name -->` anchor line, or `null`. */
function _fieldAnchor(line) {
  const m = _FIELD_ANCHOR_RE.exec(line.trim());
  return m ? m[1] : null;
}

/** The fence length of a fence-opener line (3+ backticks), or `null`. */
function _fenceOpen(line) {
  const m = _FENCE_OPEN_RE.exec(line);
  return m ? m[1].length : null;
}

module.exports = {
  SpecMarkdownRejectReason,
  SpecMarkdownRejection,
  SpecMarkdownResult,
  SpecDocumentMarkdown,
};
