/**
 * Generic YAML codec for the native `*.docspecs.yaml` document format — a
 * faithful port of `tom_som_dart_runtime/lib/src/spec_document_yaml.dart` (and
 * the JavaScript `spec_document_yaml.js`).
 *
 * A header comment, `version:` (the on-disk format version), an optional
 * `modelVersion:` stamp (the authoring object-model `major.minor`), then the
 * `document:` pass — the live object-model values, sorted by full section path.
 *
 * **All text values are written as literal block scalars (`|2-`)** so multi-line
 * content round-trips verbatim. The emitter is **self-verifying**: it re-parses
 * each block it produces (via the hand-rolled {@link yaml}) and falls back to a
 * JSON-quoted scalar (always valid YAML) for any value a clean block can't
 * represent — values with two or more trailing newlines, or anything the parser
 * doesn't reproduce exactly. Native `JSON.stringify` provides the JSON-quoting.
 */

import { SpecDocument } from './spec_document';
import * as yaml from './yaml';

/** The on-disk format version (independent of the model-version stamp). */
export const FORMAT_VERSION = 1;

/**
 * The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
 * {@link SpecDocument.loadJson}-shaped object, the `review:` pass as a raw object
 * (the runtime is review-agnostic), and the optional authoring model-version
 * stamp.
 */
export class SpecYamlContents {
  document: any;
  review: any;
  modelVersion: string | null;

  constructor(document: any, review: any, modelVersion: string | null = null) {
    this.document = document;
    this.review = review;
    this.modelVersion = modelVersion;
  }
}

/**
 * A safely-quoted mapping key. JSON strings are valid YAML flow scalars, so this
 * both quotes and escapes any path/field name unambiguously.
 */
function _yamlKey(key: string): string {
  return JSON.stringify(key);
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
 * Builds a literal block scalar (`|2<chomp>`) with body at relative indent 2, or
 * `null` when chomping can't reproduce the value's trailing newlines (two or
 * more) — those fall back to JSON quoting.
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

/** Whether re-parsing `_v: <block>` yields exactly `value`. */
function _roundTrips(block: string, value: string): boolean {
  try {
    const parsed = yaml.parse(`_v: ${block}\n`);
    return (
      parsed !== null && typeof parsed === 'object' && parsed['_v'] === value
    );
  } catch (e) {
    return false;
  }
}

/**
 * The scalar representation of `value`: a literal block at relative indent 2 when
 * that round-trips, else a JSON-quoted scalar.
 */
function _scalar(value: string): string {
  const block = _literalBlock(value);
  if (block !== null && _roundTrips(block, value)) {
    return block;
  }
  return JSON.stringify(value);
}

class _Buffer {
  private _parts: string[] = [];

  writeln(text = ''): void {
    this._parts.push(text);
    this._parts.push('\n');
  }

  toString(): string {
    return this._parts.join('');
  }
}

/**
 * Writes `<indent><key>: <scalar>` where the scalar is a self-verified block
 * scalar (or a JSON-quoted fallback). Body lines, emitted at a relative indent of
 * 2, are re-indented to `keyIndent` + 2.
 */
function _writeScalar(
  b: _Buffer,
  keyIndent: number,
  key: string,
  value: string,
): void {
  const pad = ' '.repeat(keyIndent);
  const repr = _scalar(value);
  const lines = repr.split('\n');
  b.writeln(`${pad}${_yamlKey(key)}: ${lines[0]}`);
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === '') {
      b.writeln('');
    } else {
      b.writeln(`${pad}${lines[i]}`);
    }
  }
}

function _sortedStringKeys(m: Record<string, unknown>): string[] {
  return Object.keys(m)
    .map((k) => String(k))
    .sort();
}

function _writeHeader(b: _Buffer, modelVersion: string | null): void {
  b.writeln('# TomSpecs document (*.docspecs.yaml).');
  b.writeln(
    '# `document:` holds the object-model values, sorted by section id; text',
  );
  b.writeln(
    '# values use block scalars so multi-line content round-trips verbatim (\u00A715.1).',
  );
  b.writeln(`version: ${FORMAT_VERSION}`);
  if (modelVersion) {
    b.writeln(`modelVersion: ${JSON.stringify(modelVersion)}`);
  }
}

function _writeDocumentPass(b: _Buffer, doc: any): void {
  const content = doc.content;
  const forms = doc.forms;
  const lists = doc.lists;
  if (content == null && forms == null && lists == null) {
    b.writeln('document: {}');
    return;
  }
  b.writeln('document:');

  if (
    content &&
    typeof content === 'object' &&
    Object.keys(content).length > 0
  ) {
    b.writeln('  content:');
    for (const k of _sortedStringKeys(content)) {
      _writeScalar(b, 4, k, String(content[k]));
    }
  }

  if (forms && typeof forms === 'object' && Object.keys(forms).length > 0) {
    b.writeln('  forms:');
    for (const k of _sortedStringKeys(forms)) {
      const fields = forms[k];
      if (
        !fields ||
        typeof fields !== 'object' ||
        Object.keys(fields).length === 0
      ) {
        continue;
      }
      b.writeln(`    ${_yamlKey(k)}:`);
      for (const f of _sortedStringKeys(fields)) {
        _writeScalar(b, 6, f, String(fields[f]));
      }
    }
  }

  if (lists && typeof lists === 'object' && Object.keys(lists).length > 0) {
    b.writeln('  lists:');
    for (const k of _sortedStringKeys(lists)) {
      const spec = lists[k];
      if (!spec || typeof spec !== 'object') {
        continue;
      }
      b.writeln(`    ${_yamlKey(k)}:`);
      b.writeln(`      seq: ${spec.seq || 0}`);
      const items = spec.items;
      if (Array.isArray(items) && items.length > 0) {
        b.writeln('      items:');
        for (const it of items) {
          b.writeln(`        - ${_yamlKey(String(it))}`);
        }
      } else {
        b.writeln('      items: []');
      }
    }
  }
}

/**
 * Serializes `document` (a {@link SpecDocument}) to a header + `version:` (+
 * `modelVersion:`) + `document:` pass.
 */
export function encode(
  document: SpecDocument,
  modelVersion: string | null = null,
): string {
  const b = new _Buffer();
  _writeHeader(b, modelVersion);
  _writeDocumentPass(b, document.toJson());
  return b.toString();
}

/**
 * Parses a `*.docspecs.yaml` document into its passes. A missing pass decodes as
 * empty rather than failing, so a partial/hand-written file still loads what it
 * has.
 */
export function decode(yamlText: string): SpecYamlContents {
  const root = yamlText.trim() === '' ? null : yaml.parse(yamlText);
  const isMap =
    root !== null && typeof root === 'object' && !Array.isArray(root);
  const doc = isMap ? root['document'] : null;
  const rev = isMap ? root['review'] : null;
  const stamp = isMap ? root['modelVersion'] : null;
  const docIsMap = doc !== null && typeof doc === 'object' && !Array.isArray(doc);
  const revIsMap = rev !== null && typeof rev === 'object' && !Array.isArray(rev);
  return new SpecYamlContents(
    docIsMap ? doc : {},
    revIsMap ? rev : {},
    stamp != null && String(stamp) !== '' ? String(stamp) : null,
  );
}
