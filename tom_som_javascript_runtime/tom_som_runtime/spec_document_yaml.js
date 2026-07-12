'use strict';

/**
 * Generic YAML codec for the native `*.docspecs.yaml` document format —
 * **hierarchical format v2** (DR1 §2); a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_document_yaml.dart` (and
 * `spec_document_yaml.py`).
 *
 * One nested YAML tree whose indentation mirrors the document structure: every
 * model node becomes a mapping key (`<section-id> <member-name>`, DR1 §2.2),
 * sections nest their children, list items appear under their container keyed
 * by their stored section id (or an anonymous positional `<member>-<n>` key), a
 * node's own body text uses the literal key `content`, and form fields use
 * their bare field names. The former flat two-level path-map format
 * (`document: {content: {"A/b": …}}`) is **retired**; readers reject
 * `version: 1` files with a clear error (no compatibility path).
 *
 * Text values are written as literal block scalars (`|2-`), with the DR1 §2.4
 * escaping rules: the emitter is **self-verifying** (it re-parses each scalar
 * it produces via the hand-rolled {@link yaml} — the runtime ships no external
 * YAML library — and falls back to a double-quoted JSON-escaped flow scalar
 * when the parse differs), and **runs of 2+ consecutive empty lines are
 * collapsed to one** before serialization (a deliberate, documented lossy
 * normalization — round-trip guarantees are stated "modulo empty-line dedup").
 * Non-text values (`int`/`double`/`bool`, enum member names) are plain scalars
 * when they self-verify (§2.5).
 *
 * Both {@link encode} and {@link decode} walk the {@link SomMetaTree} of the
 * document root: the file carries **no paths** — the runtime reconstructs them
 * by matching keys against the metadata tree, and a key that matches nothing
 * at its position is a structured load error
 * ({@link SpecYamlFormatException}; no silent skips). Symmetrically,
 * {@link encode} throws when the document holds values the tree cannot place
 * (nothing is silently dropped).
 *
 * The optional `review:` pass stays opaque to the runtime ({@link decode}
 * returns it as a raw map for the editor to interpret).
 */

const yaml = require('./yaml');
const { SpecDocument } = require('./spec_document');
const { SomFormMeta, SomMetaKind } = require('./spec_meta');
const { specPathJoin } = require('./spec_paths');

/**
 * The on-disk format version (independent of the model-version stamp).
 * Version 2 is the hierarchical tree format; version-1 flat files are rejected
 * on read.
 */
const FORMAT_VERSION = 2;

/**
 * A structural error in a `*.docspecs.yaml` file: wrong/unsupported format
 * version, a key that does not match the metadata tree at its position, a
 * malformed value shape, or (on encode) document values the tree cannot place.
 */
class SpecYamlFormatException extends Error {
  constructor(message) {
    super(message);
    this.name = 'SpecYamlFormatException';
    /** What went wrong, naming the offending path/key where applicable. */
    this.message = message;
  }

  toString() {
    return `SpecYamlFormatException: ${this.message}`;
  }
}

/**
 * The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
 * populated {@link SpecDocument}, the `review:` pass as a raw map (the runtime
 * is review-agnostic), and the optional authoring model-version stamp.
 */
class SpecYamlContents {
  constructor(document, review, modelVersion = null) {
    /** The `document:` pass, loaded into a live document (its
     *  {@link SpecDocument#modelVersion} is already set from the file
     *  stamp). */
    this.document = document;
    /** The `review:` pass exactly as parsed (empty when absent). The runtime
     *  does not interpret it; the editor maps it onto its own review
     *  entries. */
    this.review = review;
    /** The authoring object-model version (`major.minor`) this document was
     *  last written against, or `null` for an unstamped/hand-written file.
     *  Distinct from {@link FORMAT_VERSION} (the on-disk format version). */
    this.modelVersion = modelVersion;
  }
}

// --- Shared scalar machinery (public for the editor's review writer) ---------

/**
 * The mapping key a metadata node writes (DR1 §2.2): its effective section id,
 * one space, then the exact member name (class name on the document root);
 * just the name when the node carries no id.
 */
function nodeKey(node) {
  const name = node.memberName !== null && node.memberName !== undefined
    ? node.memberName
    : node.className;
  const id = node.sectionId;
  return id === null || id === undefined ? name : `${id} ${name}`;
}

/**
 * A safely-quoted mapping key. JSON strings are valid YAML flow scalars, so
 * this both quotes and escapes any path/field name unambiguously.
 */
function yamlKey(key) {
  return JSON.stringify(key);
}

const _PLAIN_KEY_PATTERN = /^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$/;

/**
 * A plain key when the key is YAML-safe by construction (section ids, member
 * names, `<id> <name>` pairs), else a JSON-quoted one.
 */
function plainKey(key) {
  return _PLAIN_KEY_PATTERN.test(key) ? key : yamlKey(key);
}

const _BLANK_RUNS = /\n{3,}/g;

/**
 * Collapses runs of two or more consecutive empty lines to a single empty line
 * (DR1 §2.4.3 — the deliberate lossy normalization applied to every text value
 * before serialization).
 */
function dedupEmptyLines(value) {
  return value.replace(_BLANK_RUNS, '\n\n');
}

/**
 * The Dart-`toString`-compatible string of a parsed YAML scalar
 * (`true`/`false` for booleans, matching the document's string-typed stores).
 */
function _parsedScalarStr(v) {
  if (typeof v === 'boolean') {
    return v ? 'true' : 'false';
  }
  return String(v);
}

function _trailingNewlines(value) {
  let n = 0;
  let i = value.length;
  while (i > 0 && value.charAt(i - 1) === '\n') {
    n++;
    i--;
  }
  return n;
}

/**
 * Builds a literal block scalar (`|2<chomp>`) with body at relative indent 2,
 * or `null` when chomping can't reproduce the value's trailing newlines (two
 * or more) — those fall back to JSON quoting.
 */
function _literalBlock(value) {
  const trailing = _trailingNewlines(value);
  let chomp;
  let core;
  if (trailing === 0) {
    chomp = '-';
    core = value;
  } else if (trailing === 1) {
    chomp = '';
    core = value.slice(0, value.length - 1);
  } else {
    return null;
  }
  const parts = [`|2${chomp}`];
  for (const line of core.split('\n')) {
    parts.push('\n');
    if (line !== '') {
      parts.push(`  ${line}`);
    }
  }
  return parts.join('');
}

function _isMapping(v) {
  return v !== null && v !== undefined && typeof v === 'object' && !Array.isArray(v);
}

/**
 * Whether re-parsing `_v: <block>` yields exactly `value` (the emitter's
 * correctness guard).
 */
function _roundTrips(block, value) {
  try {
    const parsed = yaml.parse(`_v: ${block}\n`);
    return _isMapping(parsed) && parsed['_v'] === value;
  } catch (e) {
    return false;
  }
}

/**
 * The scalar representation of `value`: a literal block at relative indent 2
 * when that round-trips, else a JSON-quoted scalar.
 */
function _scalar(value) {
  const block = _literalBlock(value);
  if (block !== null && _roundTrips(block, value)) {
    return block;
  }
  return JSON.stringify(value);
}

/**
 * A plain one-line scalar for a non-text value (int/double/bool/enum member
 * name, §2.5) when writing it plainly re-parses to exactly `value` (string
 * compare, matching the document's string-typed stores); `null` otherwise.
 */
function _plainScalar(value) {
  if (value === '' || value.includes('\n')) {
    return null;
  }
  try {
    const parsed = yaml.parse(`_v: ${value}\n`);
    if (!_isMapping(parsed)) {
      return null;
    }
    const v = parsed['_v'];
    if (v === null || v === undefined || typeof v === 'object') {
      return null;
    }
    return _parsedScalarStr(v) === value ? value : null;
  } catch (e) {
    return null;
  }
}

/** A minimal stand-in for Dart's `StringBuffer` (writeln semantics). */
class _Buffer {
  constructor() {
    this._parts = [];
  }

  writeln(text = '') {
    this._parts.push(text);
    this._parts.push('\n');
  }

  write(text) {
    this._parts.push(text);
  }

  toString() {
    return this._parts.join('');
  }
}

function _writeRendered(b, keyIndent, renderedKey, repr) {
  const pad = ' '.repeat(keyIndent);
  const lines = repr.split('\n');
  b.writeln(`${pad}${renderedKey}: ${lines[0]}`);
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '') {
      b.writeln('');
    } else {
      b.writeln(`${pad}${lines[i]}`);
    }
  }
}

/**
 * Writes `<indent><key>: <scalar>` where the scalar is a self-verified block
 * scalar (or a JSON-quoted fallback). Block body lines, which the builder
 * emits at a relative indent of 2, are re-indented past `keyIndent`.
 */
function writeScalar(b, keyIndent, key, value) {
  _writeRendered(b, keyIndent, yamlKey(key), _scalar(value));
}

/**
 * Writes the file header comment + `version:` line, and the optional
 * `modelVersion:` stamp when `modelVersion` is non-empty.
 */
function writeHeader(b, modelVersion = null) {
  b.writeln('# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.');
  b.writeln(`version: ${FORMAT_VERSION}`);
  if (modelVersion) {
    b.writeln(`modelVersion: ${JSON.stringify(modelVersion)}`);
  }
}

// --- Encode -------------------------------------------------------------------

function _isNumericOrBool(typeName) {
  return (
    typeName === 'int' ||
    typeName === 'double' ||
    typeName === 'num' ||
    typeName === 'bool'
  );
}

/**
 * Serializes `document` to a header + `version:` (+ `modelVersion:`) +
 * hierarchical `document:` pass, walking `tree` (the metadata tree of the
 * document's root).
 *
 * Sibling order is the tree's child order (`@SerializationOrder`), list items
 * follow their stored sequence; emission is sparse (only populated subtrees
 * appear). Throws {@link SpecYamlFormatException} when the document holds
 * values `tree` cannot place — nothing is silently dropped.
 *
 * @param {import('./spec_document').SpecDocument} document
 * @param {import('./spec_meta').SomMetaTree} tree
 * @param {string|null} [modelVersion]
 * @returns {string}
 */
function encode(document, tree, modelVersion = null) {
  const b = new _Buffer();
  writeHeader(b, modelVersion);
  new _Encoder(document, tree).writeDocumentPass(b);
  return b.toString();
}

/**
 * One encode run: walks the metadata tree, consuming values from snapshots of
 * the document's stores so anything left unconsumed at the end is a structured
 * error (nothing is silently dropped).
 */
class _Encoder {
  constructor(doc, tree) {
    this.doc = doc;
    this.tree = tree;
    /** @type {Map<string, string>} */
    this._content = new Map();
    for (const p of doc.contentPaths) {
      const v = doc.content(p);
      this._content.set(p, v !== null ? v : '');
    }
    /** @type {Map<string, Map<string, string>>} */
    this._forms = new Map();
    for (const p of doc.formPaths) {
      const fields = new Map();
      for (const f of doc.formFieldNames(p)) {
        const v = doc.formField(p, f);
        fields.set(f, v !== null ? v : '');
      }
      this._forms.set(p, fields);
    }
    /** @type {Set<string>} */
    this._lists = new Set(doc.listPaths);
  }

  writeDocumentPass(b) {
    const root = this.tree.root;
    const body = this._mappingBody(root, root.segment, 4);
    this._assertNothingLeft();
    if (body === '') {
      b.writeln('document: {}');
      return;
    }
    b.writeln('document:');
    b.writeln(`  ${plainKey(nodeKey(root))}:`);
    b.write(body);
  }

  /**
   * Renders the mapping body of `node` at `path` (root, a collapsed
   * section/complex field, or a list item's element), one line per populated
   * entry at `indent`. Empty when nothing under the node is populated.
   */
  _mappingBody(node, path, indent) {
    const b = new _Buffer();

    // The node's own body text — the literal `content` key (DR1 §2.2).
    if (this._content.has(path)) {
      const own = this._content.get(path);
      this._content.delete(path);
      if (node.children.some((c) => nodeKey(c) === 'content')) {
        throw new SpecYamlFormatException(
          `cannot emit body text at \`${path}\`: a child of ` +
            `${node.debugName} also serializes as key \`content\``,
        );
      }
      this._writeText(b, indent, 'content', own);
    }

    for (const child of node.children) {
      const childPath = specPathJoin(path, child.segment);
      const key = nodeKey(child);
      if (child.kind === SomMetaKind.CONTENT) {
        if (this._content.has(childPath)) {
          const v = this._content.get(childPath);
          this._content.delete(childPath);
          this._writeText(b, indent, key, v);
        }
      } else if (
        child.kind === SomMetaKind.SCALAR ||
        child.kind === SomMetaKind.ENUM_VALUE
      ) {
        if (this._content.has(childPath)) {
          const v = this._content.get(childPath);
          this._content.delete(childPath);
          this._writeValue(b, indent, key, v);
        }
      } else if (child.kind === SomMetaKind.FORM) {
        this._writeForm(b, indent, key, child, childPath);
      } else if (
        child.kind === SomMetaKind.SECTION ||
        child.kind === SomMetaKind.COMPLEX
      ) {
        const sub = this._mappingBody(child, childPath, indent + 2);
        if (sub !== '') {
          b.writeln(`${' '.repeat(indent)}${plainKey(key)}:`);
          b.write(sub);
        }
      } else if (child.kind === SomMetaKind.LIST) {
        this._writeList(b, indent, key, child, childPath);
      }
    }
    return b.toString();
  }

  _writeForm(b, indent, key, node, path) {
    const fields = this._forms.get(path);
    this._forms.delete(path);
    if (!fields || fields.size === 0) {
      return;
    }
    const meta = node.form !== null && node.form !== undefined
      ? node.form
      : new SomFormMeta([]);
    for (const name of fields.keys()) {
      if (meta.fieldNamed(name) === null) {
        throw new SpecYamlFormatException(
          `form \`${path}\` holds a field \`${name}\` unknown to the model`,
        );
      }
    }
    b.writeln(`${' '.repeat(indent)}${plainKey(key)}:`);
    for (const f of meta.fields) {
      if (!fields.has(f.name)) {
        continue;
      }
      const v = fields.get(f.name);
      if (_isNumericOrBool(f.typeName)) {
        this._writeValue(b, indent + 2, f.name, v);
      } else {
        this._writeText(b, indent + 2, f.name, v);
      }
    }
  }

  _writeList(b, indent, key, node, path) {
    this._lists.delete(path);
    const items = this.doc.listItems(path);
    if (items.length === 0) {
      return;
    }
    b.writeln(`${' '.repeat(indent)}${plainKey(key)}:`);
    const used = new Set();
    let pos = 0;
    for (const itemPath of items) {
      pos += 1;
      const storedId = this.doc.itemSectionId(itemPath);
      let itemKey = storedId !== null ? storedId : `${node.memberName}-${pos}`;
      if (storedId !== null) {
        if (used.has(itemKey)) {
          throw new SpecYamlFormatException(
            `duplicate list item key \`${itemKey}\` at \`${path}\``,
          );
        }
        used.add(itemKey);
      } else {
        let bump = pos;
        while (used.has(itemKey)) {
          bump += 1;
          itemKey = `${node.memberName}-${bump}`;
        }
        used.add(itemKey);
      }
      const element = node.elementNode;
      if (element === null || element === undefined) {
        // Scalar list: the item is a direct value.
        let v = '';
        if (this._content.has(itemPath)) {
          v = this._content.get(itemPath);
          this._content.delete(itemPath);
        }
        this._writeValue(b, indent + 2, itemKey, v);
      } else {
        const sub = this._mappingBody(element, itemPath, indent + 4);
        if (sub === '') {
          b.writeln(`${' '.repeat(indent + 2)}${plainKey(itemKey)}: {}`);
        } else {
          b.writeln(`${' '.repeat(indent + 2)}${plainKey(itemKey)}:`);
          b.write(sub);
        }
      }
    }
  }

  /**
   * Text value: empty-line dedup, then a self-verified block scalar (or the
   * JSON-quoted fallback).
   */
  _writeText(b, indent, key, value) {
    _writeRendered(b, indent, plainKey(key), _scalar(dedupEmptyLines(value)));
  }

  /** Non-text value (§2.5): plain when it self-verifies, else the text path. */
  _writeValue(b, indent, key, value) {
    const plain = _plainScalar(value);
    if (plain !== null) {
      b.writeln(`${' '.repeat(indent)}${plainKey(key)}: ${plain}`);
    } else {
      this._writeText(b, indent, key, value);
    }
  }

  _assertNothingLeft() {
    const leftovers = [
      ...Array.from(this._content.keys()).map((p) => `content at \`${p}\``),
      ...Array.from(this._forms.keys()).map((p) => `form values at \`${p}\``),
      ...Array.from(this._lists).map((p) => `list items at \`${p}\``),
    ].sort();
    if (leftovers.length > 0) {
      throw new SpecYamlFormatException(
        'document holds values the metadata tree cannot place: ' +
          leftovers.join('; '),
      );
    }
  }
}

// --- Decode -------------------------------------------------------------------

/**
 * Parses a `*.docspecs.yaml` file into its passes, matching every `document:`
 * key against `tree`.
 *
 * Throws {@link SpecYamlFormatException} for a missing/unsupported `version:`
 * (version 1 is rejected explicitly — the flat format has no compatibility
 * path), for any key the metadata tree cannot place, and for malformed value
 * shapes. A missing/empty `document:` pass decodes as an empty document.
 *
 * @param {string} yamlText
 * @param {import('./spec_meta').SomMetaTree} tree
 * @returns {SpecYamlContents}
 */
function decode(yamlText, tree) {
  const root = yamlText.trim() === '' ? null : yaml.parse(yamlText);
  if (!_isMapping(root)) {
    throw new SpecYamlFormatException(
      'not a *.docspecs.yaml mapping (expected version/document keys)',
    );
  }
  const version = root['version'];
  if (
    version === null ||
    version === undefined ||
    _parsedScalarStr(version) !== String(FORMAT_VERSION)
  ) {
    if (version === null || version === undefined) {
      throw new SpecYamlFormatException(
        `missing \`version:\` (expected version: ${FORMAT_VERSION})`,
      );
    }
    if (_parsedScalarStr(version) === '1') {
      throw new SpecYamlFormatException(
        'format version 1 (flat path-map) is no longer supported; ' +
          're-save the document in the hierarchical v2 format',
      );
    }
    throw new SpecYamlFormatException(
      `unsupported format version \`${version}\` (expected ${FORMAT_VERSION})`,
    );
  }

  const stampRaw = root['modelVersion'];
  const stamp =
    stampRaw !== null &&
    stampRaw !== undefined &&
    _parsedScalarStr(stampRaw) !== ''
      ? _parsedScalarStr(stampRaw)
      : null;
  const rev = root['review'];

  const document = new SpecDocument();
  document.modelVersion = stamp;
  const docPass = root['document'];
  if (docPass !== null && docPass !== undefined && !_isMapping(docPass)) {
    throw new SpecYamlFormatException('`document:` must be a mapping');
  }
  if (_isMapping(docPass) && Object.keys(docPass).length > 0) {
    const rootKey = nodeKey(tree.root);
    const keys = Object.keys(docPass);
    if (keys.length !== 1 || String(keys[0]) !== rootKey) {
      const found = keys.map((k) => `\`${k}\``).join(', ');
      throw new SpecYamlFormatException(
        `expected the single document root key \`${rootKey}\`, found: ${found}`,
      );
    }
    const body = docPass[keys[0]];
    if (body !== null && body !== undefined) {
      if (!_isMapping(body)) {
        throw new SpecYamlFormatException(
          `root \`${rootKey}\` must hold a mapping, not a scalar`,
        );
      }
      new _Decoder(document, tree).loadMapping(tree.root, tree.root.segment, body);
    }
  }

  return new SpecYamlContents(document, _isMapping(rev) ? rev : {}, stamp);
}

/**
 * One decode run: walks a parsed YAML mapping alongside the metadata tree and
 * populates `doc`. Any key that matches nothing at its position throws.
 */
class _Decoder {
  constructor(doc, tree) {
    this.doc = doc;
    this.tree = tree;
  }

  loadMapping(node, path, body) {
    for (const [rawKey, value] of Object.entries(body)) {
      const key = String(rawKey);
      const child = _Decoder._childByKey(node, key);
      if (child !== null) {
        this._loadChild(child, specPathJoin(path, child.segment), key, value);
        continue;
      }
      if (key === 'content') {
        this.doc.setContent(path, _Decoder._scalarOf(value, `${path}/content`));
        continue;
      }
      const expected = _Decoder._expectedKeys(node).join(', ');
      throw new SpecYamlFormatException(
        `key \`${key}\` under \`${path}\` matches no member of ` +
          `${node.debugName} (expected one of: ${expected})`,
      );
    }
  }

  static _childByKey(node, key) {
    return node.children.find((c) => nodeKey(c) === key) || null;
  }

  static _expectedKeys(node) {
    return node.children.map((c) => `\`${nodeKey(c)}\``).concat(['`content`']);
  }

  _loadChild(child, path, key, value) {
    if (
      child.kind === SomMetaKind.CONTENT ||
      child.kind === SomMetaKind.SCALAR ||
      child.kind === SomMetaKind.ENUM_VALUE
    ) {
      this.doc.setContent(path, _Decoder._scalarOf(value, path));
    } else if (child.kind === SomMetaKind.FORM) {
      if (!_isMapping(value)) {
        throw new SpecYamlFormatException(
          `form \`${key}\` at \`${path}\` must hold a field mapping`,
        );
      }
      const meta = child.form !== null && child.form !== undefined
        ? child.form
        : new SomFormMeta([]);
      for (const [f, v] of Object.entries(value)) {
        const name = String(f);
        if (meta.fieldNamed(name) === null) {
          throw new SpecYamlFormatException(
            `form \`${path}\` has no field \`${name}\` in the model`,
          );
        }
        this.doc.setFormField(path, name, _Decoder._scalarOf(v, `${path}.${name}`));
      }
    } else if (
      child.kind === SomMetaKind.SECTION ||
      child.kind === SomMetaKind.COMPLEX
    ) {
      if (value === null || value === undefined) {
        return;
      }
      if (!_isMapping(value)) {
        throw new SpecYamlFormatException(
          `section \`${key}\` at \`${path}\` must hold a mapping, not a scalar`,
        );
      }
      this.loadMapping(child, path, value);
    } else if (child.kind === SomMetaKind.LIST) {
      if (value === null || value === undefined) {
        return;
      }
      if (!_isMapping(value)) {
        throw new SpecYamlFormatException(
          `list \`${key}\` at \`${path}\` must hold an item mapping`,
        );
      }
      this._loadList(child, path, value);
    }
  }

  _loadList(node, path, items) {
    const member = node.memberName !== null && node.memberName !== undefined
      ? node.memberName
      : '';
    const anonymous = new RegExp(
      '^' + member.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '-[0-9]+$',
    );
    for (const [rawKey, value] of Object.entries(items)) {
      const key = String(rawKey);
      const itemPath = this.doc.addListItem(
        path,
        anonymous.test(key) ? null : key,
      );
      const element = node.elementNode;
      if (element === null || element === undefined) {
        // Scalar list item: the value is the item itself. The hand-rolled
        // parser cannot distinguish a bare `key:` (null) from `key: {}`, so an
        // empty mapping counts as "no value" here (Python raises on an
        // explicit `{}`).
        if (Array.isArray(value) || (_isMapping(value) && Object.keys(value).length > 0)) {
          throw new SpecYamlFormatException(
            `scalar list item \`${key}\` at \`${path}\` must hold a scalar`,
          );
        }
        if (value !== null && value !== undefined && !_isMapping(value)) {
          this.doc.setContent(itemPath, _parsedScalarStr(value));
        }
        continue;
      }
      if (value === null || value === undefined) {
        continue;
      }
      if (!_isMapping(value)) {
        throw new SpecYamlFormatException(
          `list item \`${key}\` at \`${path}\` must hold a mapping ` +
            '(use `{}` for an empty item)',
        );
      }
      this.loadMapping(element, itemPath, value);
    }
  }

  /**
   * Coerces a parsed leaf value to the document's string store. The
   * hand-rolled parser yields an empty mapping for a bare `key:` (where a real
   * YAML parser yields null), so an *empty* mapping counts as the empty
   * string; a populated mapping or a sequence is still a structural error.
   */
  static _scalarOf(value, where) {
    if (value === null || value === undefined) {
      return '';
    }
    if (Array.isArray(value)) {
      throw new SpecYamlFormatException(`expected a scalar value at \`${where}\``);
    }
    if (_isMapping(value)) {
      if (Object.keys(value).length === 0) {
        return '';
      }
      throw new SpecYamlFormatException(`expected a scalar value at \`${where}\``);
    }
    return _parsedScalarStr(value);
  }
}

module.exports = {
  FORMAT_VERSION,
  SpecYamlFormatException,
  SpecYamlContents,
  nodeKey,
  yamlKey,
  plainKey,
  dedupEmptyLines,
  writeScalar,
  writeHeader,
  encode,
  decode,
};
