/**
 * A minimal, dependency-free YAML reader for the constrained `*.docspecs.yaml`
 * subset the {@link SpecDocumentYaml} codec emits — the runtime ships with no
 * external libraries (no js-yaml), so this hand-rolled indentation parser stands
 * in for `package:yaml` / PyYAML. It is a faithful port of the JavaScript
 * `yaml.js` (itself ported from the Java runtime's hand-rolled `Yaml.java`).
 *
 * It supports exactly what the encoder produces (and what the self-verify
 * round-trip probe needs): block mappings, block sequences (`- item`), literal
 * block scalars (`|`, `|-`, `|2`, `|2-` …), JSON-quoted flow scalars, plain
 * integers, and the empty flow collections `{}` / `[]`. Mappings are plain
 * objects (prototype-free), sequences are arrays, and scalars are strings or
 * numbers (or, in the typed reading of the `review:` pass, the
 * {@link YamlReviewScalar} values of SOM §12.5). JSON-quoted scalars are parsed
 * with the native `JSON.parse`.
 *
 * The dynamic value model is intentionally untyped (`any`): a YAML document is a
 * heterogeneous tree of maps, arrays, strings and numbers, mirroring the JS port.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */

type YamlValue = any;

function _newMap(): YamlValue {
  return Object.create(null);
}

function _splitLines(text: string): string[] {
  return text.split('\n');
}

function _leading(line: string): number {
  let n = 0;
  while (n < line.length && line.charAt(n) === ' ') {
    n++;
  }
  return n;
}

function _isInteger(s: string): boolean {
  if (s.length === 0) {
    return false;
  }
  let i = 0;
  if (s.charAt(0) === '-' || s.charAt(0) === '+') {
    i = 1;
    if (s.length === 1) {
      return false;
    }
  }
  for (; i < s.length; i++) {
    const c = s.charCodeAt(i);
    if (c < 48 || c > 57) {
      return false;
    }
  }
  return true;
}

function _findColon(content: string): number {
  if (content.startsWith('"')) {
    let i = 1;
    while (i < content.length) {
      const c = content.charAt(i);
      if (c === '\\') {
        i += 2;
        continue;
      }
      if (c === '"') {
        i++;
        break;
      }
      i++;
    }
    return content.indexOf(':', i);
  }
  return content.indexOf(':');
}

function _parseScalarKey(keyPart: string): string {
  if (keyPart.startsWith('"')) {
    const v = JSON.parse(keyPart);
    return v == null ? '' : String(v);
  }
  return keyPart;
}

const _FLOAT_PATTERN = /^[-+]?(\.[0-9]+|[0-9]+(\.[0-9]*)?)([eE][-+]?[0-9]+)?$/;
const _DEC_INT_PATTERN = /^[-+]?[0-9]+$/;
const _OCT_INT_PATTERN = /^0o[0-7]+$/;
const _HEX_INT_PATTERN = /^0x[0-9a-fA-F]+$/;
const _INF_PATTERN = /^[-+]?\.(inf|Inf|INF)$/;
const _NAN_PATTERN = /^\.(nan|NaN|NAN)$/;
const _INT64_MIN = -(BigInt(1) << BigInt(63));
const _INT64_MAX = (BigInt(1) << BigInt(63)) - BigInt(1);

/**
 * A float whose value is whole (`3.0`, `-0.0`, `1e+300`), decoded from the
 * uninterpreted `review:` pass. A JavaScript `number` cannot tell `3` from
 * `3.0`, so a whole float is wrapped to stay a float through decode and encode
 * (SOM §12.5). Floats with a fraction, `NaN` and the infinities stay plain
 * `number`s — no integer reads as one.
 */
export class YamlFloat {
  constructor(readonly value: number) {}

  valueOf(): number {
    return this.value;
  }

  toString(): string {
    return formatYamlFloat(this.value);
  }
}

/**
 * A decoded review-pass scalar (SOM §12.5): `null`, a boolean, an integer
 * (`number` when `Number.isSafeInteger`, else `bigint` — always within the
 * signed 64-bit range), a float (`number` that is not a safe integer, or a
 * {@link YamlFloat} when whole), or a string.
 */
export type YamlReviewScalar = null | boolean | number | bigint | YamlFloat | string;

/** An integer as the narrowest exact JavaScript value. */
function _intValue(n: bigint): number | bigint {
  const asNumber = Number(n);
  return Number.isSafeInteger(asNumber) ? asNumber : n;
}

/** A float, wrapped when whole so it stays distinguishable from an int. */
function _floatValue(x: number): number | YamlFloat {
  return Number.isInteger(x) ? new YamlFloat(x) : x;
}

/**
 * The YAML 1.2 core-schema reading of a plain scalar `t` (SOM §12.5, the
 * schema `package:yaml` applies): `~`/`null`/`Null`/`NULL` are null;
 * `true|True|TRUE|false|False|FALSE` are booleans; `[-+]?[0-9]+`, `0o[0-7]+`
 * and `0x[0-9a-fA-F]+` are integers — a decimal outside the signed 64-bit
 * range becomes a float; `[-+]?(.[0-9]+|[0-9]+(.[0-9]*)?)([eE][-+]?[0-9]+)?`,
 * `[-+]?.inf` and `.nan` are floats. A JSON flow collection is parsed as
 * JSON. Anything else stays the string it is. Quoted and block scalars never
 * reach here: they are always strings.
 */
function _typedPlain(t: string): YamlValue {
  if (t === '' || t === '~' || t === 'null' || t === 'Null' || t === 'NULL') return null;
  if (t === 'true' || t === 'True' || t === 'TRUE') return true;
  if (t === 'false' || t === 'False' || t === 'FALSE') return false;
  if (_DEC_INT_PATTERN.test(t)) {
    const n = BigInt(t);
    if (n < _INT64_MIN || n > _INT64_MAX) return _floatValue(Number(t));
    return _intValue(n);
  }
  if (_OCT_INT_PATTERN.test(t)) return _intValue(BigInt('0o' + t.slice(2)));
  if (_HEX_INT_PATTERN.test(t)) return _intValue(BigInt(t));
  if (_FLOAT_PATTERN.test(t)) return _floatValue(Number(t));
  if (_INF_PATTERN.test(t)) return t.startsWith('-') ? -Infinity : Infinity;
  if (_NAN_PATTERN.test(t)) return NaN;
  if (t.startsWith('[') || t.startsWith('{')) {
    try {
      return JSON.parse(t);
    } catch (_) {
      return t;
    }
  }
  return t;
}

/**
 * A float in the canonical review-pass spelling (SOM §12.5): `.nan`, `.inf`,
 * `-.inf`; otherwise the shortest round-tripping digits in JavaScript's
 * `Number.prototype.toString` layout (fixed notation for 0 and
 * 1e-6 <= |x| < 1e21, else exponent notation such as `1e+300`), with `.0`
 * appended in fixed notation when there is no fraction (`3.0`, `-0.0`).
 */
export function formatYamlFloat(x: number): string {
  if (Number.isNaN(x)) return '.nan';
  if (x === Infinity) return '.inf';
  if (x === -Infinity) return '-.inf';
  if (Object.is(x, -0)) return '-0.0';
  const s = String(x);
  return s.includes('e') || s.includes('.') ? s : s + '.0';
}

class _Yaml {
  lines: string[];
  idx: number;
  typed: boolean;

  constructor(lines: string[], typed = false) {
    this.lines = lines;
    this.idx = 0;
    this.typed = typed;
  }

  _nextSignificant(from: number): number {
    for (let i = from; i < this.lines.length; i++) {
      const t = this.lines[i].trim();
      if (t === '' || t.startsWith('#')) {
        continue;
      }
      return i;
    }
    return -1;
  }

  parseNode(minIndent: number): YamlValue {
    const i = this._nextSignificant(this.idx);
    if (i === -1) {
      return _newMap();
    }
    const line = this.lines[i];
    const indent = _leading(line);
    if (indent < minIndent) {
      return _newMap();
    }
    const content = line.slice(indent);
    if (content === '-' || content.startsWith('- ')) {
      return this.parseSequence(indent);
    }
    return this.parseMapping(indent);
  }

  parseMapping(indent: number): YamlValue {
    const map = _newMap();
    while (true) {
      const i = this._nextSignificant(this.idx);
      if (i === -1) {
        break;
      }
      const line = this.lines[i];
      const curIndent = _leading(line);
      if (curIndent !== indent) {
        break; // dedent → belongs to the parent; over-indent shouldn't occur.
      }
      this.idx = i + 1;
      const content = line.slice(indent);
      const colon = _findColon(content);
      if (colon < 0) {
        continue; // not a mapping entry — tolerate and skip.
      }
      const key = _parseScalarKey(content.slice(0, colon).trim());
      const rest = content.slice(colon + 1).trim();
      let value: YamlValue;
      if (rest === '') {
        value = this.parseNestedAfterKey(indent);
      } else if (rest.startsWith('|') || rest.startsWith('>')) {
        value = this.parseBlockScalar(rest, indent);
      } else {
        value = this.parseFlowScalar(rest);
      }
      map[key] = value;
    }
    return map;
  }

  parseSequence(indent: number): YamlValue {
    const list: YamlValue[] = [];
    while (true) {
      const i = this._nextSignificant(this.idx);
      if (i === -1) {
        break;
      }
      const line = this.lines[i];
      const curIndent = _leading(line);
      if (curIndent !== indent) {
        break;
      }
      const content = line.slice(indent);
      if (content !== '-' && !content.startsWith('- ')) {
        break;
      }
      this.idx = i + 1;
      const itemText = content === '-' ? '' : content.slice(2).trim();
      if (itemText === '') {
        list.push(this.parseNestedAfterKey(indent));
      } else if (itemText.startsWith('|') || itemText.startsWith('>')) {
        list.push(this.parseBlockScalar(itemText, indent));
      } else {
        // A `- key: …` item is a mapping whose first entry sits on the dash
        // line; rewrite the dash as indentation and re-parse as a mapping.
        const colon = _findColon(itemText);
        const isMapEntry =
          colon >= 0 &&
          (colon === itemText.length - 1 || itemText.charAt(colon + 1) === ' ');
        if (isMapEntry) {
          this.idx = i;
          this.lines[i] = ' '.repeat(indent + 2) + line.slice(indent + 2);
          list.push(this.parseMapping(indent + 2));
        } else {
          list.push(this.parseFlowScalar(itemText));
        }
      }
    }
    return list;
  }

  parseNestedAfterKey(parentIndent: number): YamlValue {
    const i = this._nextSignificant(this.idx);
    if (i === -1) {
      return _newMap();
    }
    const childIndent = _leading(this.lines[i]);
    if (childIndent <= parentIndent) {
      // An empty value: null in the YAML 1.2 core schema (the typed reading).
      return this.typed ? null : _newMap();
    }
    return this.parseNode(childIndent);
  }

  parseFlowScalar(s: string): YamlValue {
    const t = s.trim();
    if (t === '{}') {
      return _newMap();
    }
    if (t === '[]') {
      return [];
    }
    if (t.startsWith('"')) {
      return JSON.parse(t); // a JSON string literal is a valid YAML flow scalar.
    }
    if (this.typed) {
      return _typedPlain(t);
    }
    if (_isInteger(t)) {
      return parseInt(t, 10);
    }
    return t;
  }

  /**
   * Parses a literal block scalar starting at `header` (e.g. `|2-`) whose body
   * lines follow. `keyIndent` is the indentation of the owning key/sequence line.
   */
  parseBlockScalar(header: string, keyIndent: number): string {
    let p = 1; // skip the leading '|' (or '>').
    let explicitIndent = -1;
    const digitsStart = p;
    while (
      p < header.length &&
      header.charCodeAt(p) >= 48 &&
      header.charCodeAt(p) <= 57
    ) {
      p++;
    }
    if (p > digitsStart) {
      explicitIndent = parseInt(header.slice(digitsStart, p), 10);
    }
    let chomp = ' ';
    while (p < header.length) {
      const c = header.charAt(p);
      if (c === '-' || c === '+') {
        chomp = c;
      }
      p++;
    }

    // Collect the raw body: blank lines plus any line indented past the key.
    const rawBody: string[] = [];
    while (this.idx < this.lines.length) {
      const l = this.lines[this.idx];
      if (l.trim() === '') {
        rawBody.push('');
        this.idx++;
        continue;
      }
      if (_leading(l) <= keyIndent) {
        break;
      }
      rawBody.push(l);
      this.idx++;
    }
    // Drop trailing blank lines that actually belong to the following node.
    while (rawBody.length > 0 && rawBody[rawBody.length - 1] === '') {
      rawBody.pop();
    }

    let contentIndent: number;
    if (explicitIndent >= 0) {
      contentIndent = keyIndent + explicitIndent;
    } else {
      contentIndent = Number.MAX_SAFE_INTEGER;
      for (const l of rawBody) {
        if (l !== '') {
          contentIndent = Math.min(contentIndent, _leading(l));
        }
      }
      if (contentIndent === Number.MAX_SAFE_INTEGER) {
        contentIndent = keyIndent + 1;
      }
    }

    const body: string[] = [];
    for (const l of rawBody) {
      if (l === '') {
        body.push('');
      } else {
        const strip = Math.min(contentIndent, l.length);
        body.push(l.slice(strip));
      }
    }

    const joined = body.join('\n');
    if (chomp === '-') {
      let end = joined.length;
      while (end > 0 && joined.charAt(end - 1) === '\n') {
        end--;
      }
      return joined.slice(0, end);
    }
    if (chomp === '+') {
      return joined;
    }
    // Clip (default): exactly one trailing newline when non-empty.
    let end = joined.length;
    while (end > 0 && joined.charAt(end - 1) === '\n') {
      end--;
    }
    const clipped = joined.slice(0, end);
    return clipped === '' ? '' : clipped + '\n';
  }
}

/**
 * Parses `text` into the value model (a mapping object or array). With
 * `typed`, plain scalars are read by the YAML 1.2 core schema (SOM §12.5:
 * null, booleans, 64-bit integers, floats, JSON flow collections — see
 * {@link YamlReviewScalar}) and an empty value is null, instead of the
 * document codec's strings and plain integers — the reading the uninterpreted
 * `review:` pass needs to round-trip its values' types.
 */
export function parse(text: string, typed = false): YamlValue {
  const lines = _splitLines(text);
  const y = new _Yaml(lines, typed);
  const first = y._nextSignificant(0);
  if (first === -1) {
    return _newMap();
  }
  return y.parseNode(0);
}

/** Parses `text`, returning a mapping object (empty when not a mapping). */
export function parseMap(text: string): YamlValue {
  const v = parse(text);
  if (v !== null && typeof v === 'object' && !Array.isArray(v)) {
    return v;
  }
  return _newMap();
}
