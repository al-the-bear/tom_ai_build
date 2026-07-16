/**
 * Generic YAML codec for the native `*.docspecs.yaml` document format —
 * **hierarchical format v2** (DR1 §2); a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_document_yaml.dart` (and the JavaScript
 * `spec_document_yaml.js`).
 *
 * One nested YAML tree whose indentation mirrors the document structure: every
 * model node becomes a mapping key (`<section-id> <member-name>`, DR1 §2.2),
 * sections nest their children, list items appear under their container keyed
 * by their stored section id (or an anonymous positional `<member>-<n>` key), a
 * node's own body text uses the literal key `content`, a node's **stored
 * headline** (YRD3) uses the literal key `headline`, and form fields use
 * their bare field names. A scalar-valued node (content/scalar/enum leaf or
 * scalar list item) that carries a stored headline is emitted as a
 * `{headline: …, content: …}` mapping. The former flat two-level path-map format
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

/* eslint-disable @typescript-eslint/no-explicit-any */

import * as yaml from './yaml';
import { SpecDocument } from './spec_document';
import { SomFormMeta, SomMetaKind, SomMetaNode, SomMetaTree } from './spec_meta';
import { specPathJoin } from './spec_paths';

/**
 * The on-disk format version (independent of the model-version stamp).
 * Version 2 is the hierarchical tree format; version-1 flat files are rejected
 * on read.
 */
export const FORMAT_VERSION = 2;

/**
 * A structural error in a `*.docspecs.yaml` file: wrong/unsupported format
 * version, a key that does not match the metadata tree at its position, a
 * malformed value shape, or (on encode) document values the tree cannot place.
 */
export class SpecYamlFormatException extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SpecYamlFormatException';
    /** What went wrong, naming the offending path/key where applicable. */
    this.message = message;
    // Restore the prototype chain across the ES5 `Error` boundary.
    Object.setPrototypeOf(this, SpecYamlFormatException.prototype);
  }

  toString(): string {
    return `SpecYamlFormatException: ${this.message}`;
  }
}

/**
 * The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
 * populated {@link SpecDocument}, the `review:` pass as a raw map (the runtime
 * is review-agnostic), and the optional authoring model-version stamp.
 */
export class SpecYamlContents {
  /** The `document:` pass, loaded into a live document (its
   *  {@link SpecDocument.modelVersion} is already set from the file
   *  stamp). */
  document: SpecDocument;
  /** The `review:` pass exactly as parsed (empty when absent). The runtime
   *  does not interpret it; the editor maps it onto its own review
   *  entries. */
  review: any;
  /** The authoring object-model version (`major.minor`) this document was
   *  last written against, or `null` for an unstamped/hand-written file.
   *  Distinct from {@link FORMAT_VERSION} (the on-disk format version). */
  modelVersion: string | null;

  constructor(document: SpecDocument, review: any, modelVersion: string | null = null) {
    this.document = document;
    this.review = review;
    this.modelVersion = modelVersion;
  }
}

// --- Shared scalar machinery (public for the editor's review writer) ---------

/**
 * The mapping key a metadata node writes (DR1 §2.2): its effective section id,
 * one space, then the exact member name (class name on the document root);
 * just the name when the node carries no id.
 *
 * The id is the field-level {@link SomMetaNode.sectionId} when present; for a
 * section/complex node whose field carries none, the target **class**'s id
 * ({@link SomMetaNode.classSectionId}) — the id its DR3 schema type is keyed
 * by. This mirrors the markdown codec's heading rule exactly. Content, scalar,
 * enum, form and list keys keep only their field-level id (no class fallback),
 * and the path {@link SomMetaNode.segment} is unaffected in every case.
 */
export function nodeKey(node: SomMetaNode): string {
  const name = node.memberName !== null && node.memberName !== undefined
    ? node.memberName
    : node.className;
  let id = node.sectionId;
  if ((id === null || id === undefined) &&
      (node.kind === SomMetaKind.SECTION || node.kind === SomMetaKind.COMPLEX)) {
    id = node.classSectionId;
  }
  return id === null || id === undefined ? name : `${id} ${name}`;
}

/**
 * A safely-quoted mapping key. JSON strings are valid YAML flow scalars, so
 * this both quotes and escapes any path/field name unambiguously.
 */
export function yamlKey(key: string): string {
  return JSON.stringify(key);
}

const _PLAIN_KEY_PATTERN = /^[A-Za-z0-9_][A-Za-z0-9_. -]*[A-Za-z0-9_.\-]$|^[A-Za-z0-9_]$/;

/**
 * A plain key when the key is YAML-safe by construction (section ids, member
 * names, `<id> <name>` pairs), else a JSON-quoted one.
 */
export function plainKey(key: string): string {
  return _PLAIN_KEY_PATTERN.test(key) ? key : yamlKey(key);
}

const _BLANK_RUNS = /\n{3,}/g;

/**
 * Collapses runs of two or more consecutive empty lines to a single empty line
 * (DR1 §2.4.3 — the deliberate lossy normalization applied to every text value
 * before serialization).
 */
export function dedupEmptyLines(value: string): string {
  return value.replace(_BLANK_RUNS, '\n\n');
}

/**
 * The Dart-`toString`-compatible string of a parsed YAML scalar
 * (`true`/`false` for booleans, matching the document's string-typed stores).
 */
function _parsedScalarStr(v: any): string {
  if (typeof v === 'boolean') {
    return v ? 'true' : 'false';
  }
  return String(v);
}

function _trailingNewlines(value: string): number {
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
function _literalBlock(value: string): string | null {
  const trailing = _trailingNewlines(value);
  let chomp: string;
  let core: string;
  if (trailing === 0) {
    chomp = '-';
    core = value;
  } else if (trailing === 1) {
    chomp = '';
    core = value.slice(0, value.length - 1);
  } else {
    return null;
  }
  const parts: string[] = [`|2${chomp}`];
  for (const line of core.split('\n')) {
    parts.push('\n');
    if (line !== '') {
      parts.push(`  ${line}`);
    }
  }
  return parts.join('');
}

function _isMapping(v: any): boolean {
  return v !== null && v !== undefined && typeof v === 'object' && !Array.isArray(v);
}

/**
 * Whether re-parsing `_v: <block>` yields exactly `value` (the emitter's
 * correctness guard).
 */
function _roundTrips(block: string, value: string): boolean {
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
function _scalar(value: string): string {
  const block = _literalBlock(value);
  if (block !== null && _roundTrips(block, value)) {
    return block;
  }
  return JSON.stringify(value);
}

const _YAML11_BOOL = /^(y|Y|yes|Yes|YES|n|N|no|No|NO|on|On|ON|off|Off|OFF)$/;
const _YAML11_SEXAGESIMAL_INT = /^[-+]?[1-9][0-9_]*(:[0-5]?[0-9])+$/;
const _YAML11_SEXAGESIMAL_FLOAT = /^[-+]?[0-9][0-9_]*(:[0-5]?[0-9])+\.[0-9_]*$/;

/**
 * Whether `value`'s text is a YAML 1.1 special that a 1.1 parser would resolve
 * to a non-string, so it must never be emitted as a plain scalar (DR1 §2.5).
 * Covers the 1.1-only boolean words and sexagesimal int/float literals.
 * Mirrors the Dart reference rule so every emitter's plain-scalar decision is
 * identical regardless of the local YAML library's schema.
 */
function _isYaml11Special(value: string): boolean {
  return (
    _YAML11_BOOL.test(value) ||
    _YAML11_SEXAGESIMAL_INT.test(value) ||
    _YAML11_SEXAGESIMAL_FLOAT.test(value)
  );
}

/**
 * A plain one-line scalar for a non-text value (int/double/bool/enum member
 * name, §2.5) when writing it plainly re-parses to exactly `value` (string
 * compare, matching the document's string-typed stores); `null` otherwise.
 * Values whose text is a YAML 1.1 special are forced to the quoted/block path
 * so cross-language round-trips stay identical.
 */
function _plainScalar(value: string): string | null {
  if (value === '' || value.includes('\n')) {
    return null;
  }
  if (_isYaml11Special(value)) {
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
  private _parts: string[] = [];

  writeln(text = ''): void {
    this._parts.push(text);
    this._parts.push('\n');
  }

  write(text: string): void {
    this._parts.push(text);
  }

  toString(): string {
    return this._parts.join('');
  }
}

function _writeRendered(
  b: _Buffer,
  keyIndent: number,
  renderedKey: string,
  repr: string,
): void {
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
export function writeScalar(
  b: { writeln(text?: string): void; write(text: string): void },
  keyIndent: number,
  key: string,
  value: string,
): void {
  _writeRendered(b as _Buffer, keyIndent, yamlKey(key), _scalar(value));
}

/**
 * Writes the file header comment + `version:` line, and the optional
 * `modelVersion:` stamp when `modelVersion` is non-empty.
 */
export function writeHeader(
  b: { writeln(text?: string): void },
  modelVersion: string | null = null,
): void {
  b.writeln('# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.');
  b.writeln(`version: ${FORMAT_VERSION}`);
  if (modelVersion) {
    b.writeln(`modelVersion: ${JSON.stringify(modelVersion)}`);
  }
}

// --- Encode -------------------------------------------------------------------

function _isNumericOrBool(typeName: string): boolean {
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
 */
export function encode(
  document: SpecDocument,
  tree: SomMetaTree,
  modelVersion: string | null = null,
): string {
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
  doc: SpecDocument;
  tree: SomMetaTree;
  private _content: Map<string, string> = new Map();
  private _forms: Map<string, Map<string, string>> = new Map();
  private _lists: Set<string>;
  private _headlines: Map<string, string> = new Map();

  constructor(doc: SpecDocument, tree: SomMetaTree) {
    this.doc = doc;
    this.tree = tree;
    for (const p of doc.contentPaths) {
      const v = doc.content(p);
      this._content.set(p, v !== null ? v : '');
    }
    for (const p of doc.formPaths) {
      const fields = new Map<string, string>();
      for (const f of doc.formFieldNames(p)) {
        const v = doc.formField(p, f);
        fields.set(f, v !== null ? v : '');
      }
      this._forms.set(p, fields);
    }
    this._lists = new Set(doc.listPaths);
    for (const p of doc.headlinePaths) {
      const h = doc.headline(p);
      this._headlines.set(p, h !== null ? h : '');
    }
  }

  writeDocumentPass(b: _Buffer): void {
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
  private _mappingBody(node: SomMetaNode, path: string, indent: number): string {
    const b = new _Buffer();

    // The node's own stored headline — the literal `headline` key (YRD3).
    if (this._headlines.has(path)) {
      const ownHeadline = this._headlines.get(path) as string;
      this._headlines.delete(path);
      if (node.children.some((c) => nodeKey(c) === 'headline')) {
        throw new SpecYamlFormatException(
          `cannot emit the stored headline at \`${path}\`: a child of ` +
            `${node.debugName} also serializes as key \`headline\``,
        );
      }
      this._writeText(b, indent, 'headline', ownHeadline);
    }

    // The node's own body text — the literal `content` key (DR1 §2.2).
    if (this._content.has(path)) {
      const own = this._content.get(path) as string;
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
        const hasV = this._content.has(childPath);
        const v = hasV ? (this._content.get(childPath) as string) : null;
        this._content.delete(childPath);
        const hasH = this._headlines.has(childPath);
        const h = hasH ? (this._headlines.get(childPath) as string) : null;
        this._headlines.delete(childPath);
        if (hasH) {
          this._writeScalarWithHeadline(b, indent, key, h as string, v, true);
        } else if (hasV) {
          this._writeText(b, indent, key, v as string);
        }
      } else if (
        child.kind === SomMetaKind.SCALAR ||
        child.kind === SomMetaKind.ENUM_VALUE
      ) {
        const hasV = this._content.has(childPath);
        const v = hasV ? (this._content.get(childPath) as string) : null;
        this._content.delete(childPath);
        const hasH = this._headlines.has(childPath);
        const h = hasH ? (this._headlines.get(childPath) as string) : null;
        this._headlines.delete(childPath);
        if (hasH) {
          this._writeScalarWithHeadline(b, indent, key, h as string, v, false);
        } else if (hasV) {
          this._writeValue(b, indent, key, v as string);
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

  /**
   * Emits a scalar-valued node (content/scalar/enum leaf or scalar list item)
   * that carries a stored headline as a `{headline: …, content: …}` mapping
   * (YRD3).
   */
  private _writeScalarWithHeadline(
    b: _Buffer,
    indent: number,
    key: string,
    headline: string,
    value: string | null,
    text: boolean,
  ): void {
    b.writeln(`${' '.repeat(indent)}${plainKey(key)}:`);
    this._writeText(b, indent + 2, 'headline', headline);
    if (value !== null && value !== undefined) {
      if (text) {
        this._writeText(b, indent + 2, 'content', value);
      } else {
        this._writeValue(b, indent + 2, 'content', value);
      }
    }
  }

  private _writeForm(
    b: _Buffer,
    indent: number,
    key: string,
    node: SomMetaNode,
    path: string,
  ): void {
    const fields = this._forms.get(path) || new Map<string, string>();
    this._forms.delete(path);
    const hasHeadline = this._headlines.has(path);
    const headline = hasHeadline ? (this._headlines.get(path) as string) : null;
    this._headlines.delete(path);
    if (fields.size === 0 && !hasHeadline) {
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
    if (hasHeadline && meta.fieldNamed('headline') !== null) {
      throw new SpecYamlFormatException(
        `cannot emit the stored headline at \`${path}\`: the form declares a ` +
          'field literally named `headline`',
      );
    }
    b.writeln(`${' '.repeat(indent)}${plainKey(key)}:`);
    if (hasHeadline) {
      this._writeText(b, indent + 2, 'headline', headline as string);
    }
    for (const f of meta.fields) {
      if (!fields.has(f.name)) {
        continue;
      }
      const v = fields.get(f.name) as string;
      if (_isNumericOrBool(f.typeName)) {
        this._writeValue(b, indent + 2, f.name, v);
      } else {
        this._writeText(b, indent + 2, f.name, v);
      }
    }
  }

  private _writeList(
    b: _Buffer,
    indent: number,
    key: string,
    node: SomMetaNode,
    path: string,
  ): void {
    this._lists.delete(path);
    const hasHeadline = this._headlines.has(path);
    const headline = hasHeadline ? (this._headlines.get(path) as string) : null;
    this._headlines.delete(path);
    const items = this.doc.listItems(path);
    if (items.length === 0 && !hasHeadline) {
      return;
    }
    b.writeln(`${' '.repeat(indent)}${plainKey(key)}:`);
    if (hasHeadline) {
      this._writeText(b, indent + 2, 'headline', headline as string);
    }
    const used = new Set<string>(['headline']);
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
        // Scalar list: the item is a direct value — unless it carries a
        // stored headline, in which case it becomes a
        // `{headline: …, content: …}` mapping (YRD3).
        const hasV = this._content.has(itemPath);
        const v = hasV ? (this._content.get(itemPath) as string) : null;
        this._content.delete(itemPath);
        const hasIh = this._headlines.has(itemPath);
        const ih = hasIh ? (this._headlines.get(itemPath) as string) : null;
        this._headlines.delete(itemPath);
        if (hasIh) {
          this._writeScalarWithHeadline(
            b, indent + 2, itemKey, ih as string, v, false,
          );
        } else {
          this._writeValue(b, indent + 2, itemKey, hasV ? (v as string) : '');
        }
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
  private _writeText(b: _Buffer, indent: number, key: string, value: string): void {
    _writeRendered(b, indent, plainKey(key), _scalar(dedupEmptyLines(value)));
  }

  /** Non-text value (§2.5): plain when it self-verifies, else the text path. */
  private _writeValue(b: _Buffer, indent: number, key: string, value: string): void {
    const plain = _plainScalar(value);
    if (plain !== null) {
      b.writeln(`${' '.repeat(indent)}${plainKey(key)}: ${plain}`);
    } else {
      this._writeText(b, indent, key, value);
    }
  }

  private _assertNothingLeft(): void {
    const leftovers = [
      ...Array.from(this._content.keys()).map((p) => `content at \`${p}\``),
      ...Array.from(this._forms.keys()).map((p) => `form values at \`${p}\``),
      ...Array.from(this._lists).map((p) => `list items at \`${p}\``),
      ...Array.from(this._headlines.keys()).map((p) => `headline at \`${p}\``),
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
 */
export function decode(yamlText: string, tree: SomMetaTree): SpecYamlContents {
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
  doc: SpecDocument;
  tree: SomMetaTree;

  constructor(doc: SpecDocument, tree: SomMetaTree) {
    this.doc = doc;
    this.tree = tree;
  }

  loadMapping(node: SomMetaNode, path: string, body: any): void {
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
      if (key === 'headline') {
        this.doc.setHeadline(
          path,
          _Decoder._scalarOf(value, `${path} (headline)`),
        );
        continue;
      }
      const expected = _Decoder._expectedKeys(node).join(', ');
      throw new SpecYamlFormatException(
        `key \`${key}\` under \`${path}\` matches no member of ` +
          `${node.debugName} (expected one of: ${expected})`,
      );
    }
  }

  private static _childByKey(node: SomMetaNode, key: string): SomMetaNode | null {
    return node.children.find((c) => nodeKey(c) === key) || null;
  }

  private static _expectedKeys(node: SomMetaNode): string[] {
    return node.children
      .map((c) => `\`${nodeKey(c)}\``)
      .concat(['`content`', '`headline`']);
  }

  private _loadChild(
    child: SomMetaNode,
    path: string,
    key: string,
    value: any,
  ): void {
    if (
      child.kind === SomMetaKind.CONTENT ||
      child.kind === SomMetaKind.SCALAR ||
      child.kind === SomMetaKind.ENUM_VALUE
    ) {
      // A populated mapping is a headline-extended scalar node (YRD3):
      // `{headline: …, content: …}`. An empty mapping is the hand-rolled
      // parser's spelling of a bare `key:` and stays the empty scalar.
      if (_isMapping(value) && Object.keys(value).length > 0) {
        this._loadScalarWithHeadline(path, key, value);
      } else {
        this.doc.setContent(path, _Decoder._scalarOf(value, path));
      }
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
          if (name === 'headline') {
            this.doc.setHeadline(
              path,
              _Decoder._scalarOf(v, `${path} (headline)`),
            );
            continue;
          }
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

  private _loadList(node: SomMetaNode, path: string, items: any): void {
    const member = node.memberName !== null && node.memberName !== undefined
      ? node.memberName
      : '';
    const anonymous = new RegExp(
      '^' + member.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '-[0-9]+$',
    );
    for (const [rawKey, value] of Object.entries(items)) {
      const key = String(rawKey);
      if (key === 'headline') {
        // The list container's own stored headline (YRD3), not an item.
        this.doc.setHeadline(
          path,
          _Decoder._scalarOf(value, `${path} (headline)`),
        );
        continue;
      }
      const itemPath = this.doc.addListItem(
        path,
        anonymous.test(key) ? null : key,
      );
      const element = node.elementNode;
      if (element === null || element === undefined) {
        // Scalar list item: the value is the item itself — or a
        // `{headline: …, content: …}` mapping when it carries a stored
        // headline (YRD3). The hand-rolled parser cannot distinguish a bare
        // `key:` (null) from `key: {}`, so an empty mapping counts as
        // "no value" here (Python raises on an explicit `{}`).
        if (Array.isArray(value)) {
          throw new SpecYamlFormatException(
            `scalar list item \`${key}\` at \`${path}\` must hold a scalar`,
          );
        }
        if (_isMapping(value) && Object.keys(value as object).length > 0) {
          this._loadScalarWithHeadline(itemPath, key, value);
          continue;
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
   * Loads a headline-extended scalar node (YRD3): a mapping holding only the
   * literal keys `headline` and `content`.
   */
  private _loadScalarWithHeadline(path: string, key: string, value: any): void {
    for (const [k, v] of Object.entries(value)) {
      const name = String(k);
      if (name === 'headline') {
        this.doc.setHeadline(
          path,
          _Decoder._scalarOf(v, `${path} (headline)`),
        );
      } else if (name === 'content') {
        this.doc.setContent(path, _Decoder._scalarOf(v, `${path}/content`));
      } else {
        throw new SpecYamlFormatException(
          `scalar node \`${key}\` at \`${path}\` may only hold ` +
            `\`headline\`/\`content\` keys when written as a mapping, ` +
            `found \`${name}\``,
        );
      }
    }
  }

  /**
   * Coerces a parsed leaf value to the document's string store. The
   * hand-rolled parser yields an empty mapping for a bare `key:` (where a real
   * YAML parser yields null), so an *empty* mapping counts as the empty
   * string; a populated mapping or a sequence is still a structural error.
   */
  private static _scalarOf(value: any, where: string): string {
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
