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
 * numbers. JSON-quoted scalars are parsed with the native `JSON.parse`.
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

class _Yaml {
  lines: string[];
  idx: number;

  constructor(lines: string[]) {
    this.lines = lines;
    this.idx = 0;
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
      return _newMap();
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

/** Parses `text` into the value model (a mapping object or array). */
export function parse(text: string): YamlValue {
  const lines = _splitLines(text);
  const y = new _Yaml(lines);
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
