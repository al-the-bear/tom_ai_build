'use strict';

/**
 * The reading notation's scanner: one call per text value, returning the
 * value's fenced divs, bracketed spans and citation shapes with their kind,
 * attributes, source ranges and nesting, and the findings the DocSpecs
 * specification lists for the notation (*Reading Notation*, RN-1 … RN-13).
 *
 * The JavaScript port of `tom_som_typescript_runtime`'s `spec_notation.ts`
 * (itself the port of `tom_som_dart_runtime`'s `spec_notation.dart`): the same
 * grammar, the same elements and findings, the same UTF-16 offsets; all run
 * `tom_som_conformance/corpus/notation_cases.json`.
 *
 * - a **fenced div** is a line of at least three colons, indented up to three
 *   spaces, then attribute braces (`::: {.provenance}`) or a bare kind word
 *   (`::: aside`); it closes at a line of at least three colons and nothing
 *   else, and a closing fence closes the innermost open div;
 * - a **bracketed span** is `[text]` followed immediately by attribute braces,
 *   inside one paragraph;
 * - a **citation shape** is `(-> ids)` (kind `trace`), `(<- source)` or
 *   `(<~ source)` (kind `provenance`);
 * - fenced code and code spans are literal, and so are `\:::` and `]\{.`.
 *
 * An unknown kind passes through as an element like any other.
 */

/** The kinds the notation registers (RN-5); any other kind passes through. */
const registeredNotationKinds = new Set([
  'provenance',
  'trace',
  'editorial',
  'aside',
  'linked',
  'derived',
  'refs',
  'records',
  'rejected',
]);

/** The notation's findings (RN-10); each is the rule's name in the validator. */
const NotationFindingCode = Object.freeze({
  UNCLOSED_DIV: 'unclosedDiv',
  STRAY_CLOSING_FENCE: 'strayClosingFence',
  UNCLOSED_SPAN: 'unclosedSpan',
  DIV_WITHOUT_KIND: 'divWithoutKind',
  UNKNOWN_KIND: 'unknownKind',
  MARK_ACROSS_NOTATION: 'markAcrossNotation',
  ANNOTATION_INSIDE_DIV: 'annotationInsideDiv',
  DIV_INSIDE_ANNOTATION: 'divInsideAnnotation',
  REJECTED_BLOCK: 'rejectedBlock',
});

const _codeOrder = Object.values(NotationFindingCode);
const _typeOrder = ['div', 'span', 'citation'];

/** The severity of `code`: an unknown kind is a `warning`, the rest `error`s. */
function notationSeverity(code) {
  return code === NotationFindingCode.UNKNOWN_KIND ? 'warning' : 'error';
}

/** One element of the notation: a div, a span or a citation. */
class NotationElement {
  constructor(
    type,
    kind,
    classes,
    id,
    attributes,
    shape,
    start,
    end,
    contentStart,
    contentEnd,
    line,
    endLine,
    closed,
  ) {
    /** `div`, `span` or `citation`. */
    this.type = type;
    /** The first class; `trace` / `provenance` for a citation; null without a class. */
    this.kind = kind;
    /** Every class, the kind first. @type {string[]} */
    this.classes = classes;
    /** The `#id` of the attributes (not a section id). */
    this.id = id;
    /** The `key="value"` pairs, in their order. @type {Object<string, string>} */
    this.attributes = attributes;
    /** A citation's arrow: `->`, `<-` or `<~`; null otherwise. */
    this.shape = shape;
    /** The UTF-16 offset of the first character. */
    this.start = start;
    /** The UTF-16 offset after the last character. */
    this.end = end;
    /** The UTF-16 offset of the content. */
    this.contentStart = contentStart;
    /** The UTF-16 offset after the content. */
    this.contentEnd = contentEnd;
    /** The 1-based line of start. */
    this.line = line;
    /** The 1-based line of the last character. */
    this.endLine = endLine;
    /** False for a div without a closing fence. */
    this.closed = closed;
    /** The elements nested in this one, in source order. @type {NotationElement[]} */
    this.children = [];
  }

  /** Whether the kind is registered. */
  get isRegistered() {
    return this.kind != null && registeredNotationKinds.has(this.kind);
  }

  /** The element as the conformance corpus writes it. */
  toJson(text) {
    return {
      type: this.type,
      kind: this.kind,
      classes: this.classes,
      id: this.id,
      attributes: this.attributes,
      shape: this.shape,
      start: this.start,
      end: this.end,
      line: this.line,
      endLine: this.endLine,
      closed: this.closed,
      source: text.substring(this.start, this.end),
      content: text.substring(this.contentStart, this.contentEnd),
      children: this.children.map((c) => c.toJson(text)),
    };
  }
}

/** One finding of the scan. */
class NotationFinding {
  constructor(code, offset, line, message) {
    /** One of the {@link NotationFindingCode} values. */
    this.code = code;
    /** The UTF-16 offset it stands at. */
    this.offset = offset;
    /** Its 1-based line. */
    this.line = line;
    this.message = message;
  }

  /** The severity of the code. */
  get severity() {
    return notationSeverity(this.code);
  }

  /** The finding as the conformance corpus writes it. */
  toJson() {
    return { code: this.code, severity: this.severity, line: this.line };
  }

  toString() {
    return `line ${this.line}: ${this.code} — ${this.message}`;
  }
}

/** The result of {@link scanNotation}. */
class NotationScan {
  constructor(text, elements, findings) {
    this.text = text;
    /** The elements not nested in another, in source order. */
    this.elements = elements;
    /** The findings, by offset. */
    this.findings = findings;
  }

  /** Every element, depth-first in source order. */
  get all() {
    const out = [];
    const walk = (list) => {
      for (const e of list) {
        out.push(e);
        walk(e.children);
      }
    };
    walk(this.elements);
    return out;
  }

  /** Whether a finding of severity error is present. */
  get hasErrors() {
    return this.findings.some((f) => f.severity === 'error');
  }
}

const _divOpen =
  /^ {0,3}:{3,}[ \t]*(?:\{(.*)\}|([A-Za-z][A-Za-z0-9_-]*))[ \t]*$/;
const _divClose = /^ {0,3}:{3,}[ \t]*$/;
const _codeFenceOpen = /^ {0,3}(`{3,}|~{3,})(.*)$/;
const _quoteLine = /^ {0,3}>/;
const _annotationStart = /^ {0,3}> ?(?:⬆|\*\*❓|⚖)/;
const _quotedDivOpen =
  /^ {0,3}>[ \t]?( {0,3}:{3,}[ \t]*(?:\{.*\}|[A-Za-z][A-Za-z0-9_-]*)[ \t]*)$/;
const _attributeToken =
  /\.([^\s.#}="']+)|#([^\s.#}="']+)|([A-Za-z_][A-Za-z0-9_:.-]*)=("[^"]*"|'[^']*'|[^\s}]+)/g;
const _asciiPunctuation = '!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~';
const _markOpeners = ['{++', '{--', '{~~', '{==', '{>>'];
const _markClosers = {
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
  '{==': '==}',
  '{>>': '<<}',
};
const _citationKinds = {
  '->': 'trace',
  '<-': 'provenance',
  '<~': 'provenance',
};

/**
 * Scans one text value for the reading notation. `options.tomSpecs` says the
 * value belongs to a TomSpecs rendition: only then are a div without a class
 * and an unregistered kind reported (RN-10).
 *
 * @param {string} text
 * @param {{tomSpecs?: boolean}} [options]
 * @returns {NotationScan}
 */
function scanNotation(text, options = {}) {
  return new _Scanner(text, options.tomSpecs === true).scan();
}

function _parseAttributes(inner) {
  const classes = [];
  let id = null;
  const pairs = {};
  _attributeToken.lastIndex = 0;
  let m;
  while ((m = _attributeToken.exec(inner)) !== null) {
    if (m[1] !== undefined) {
      classes.push(m[1]);
    } else if (m[2] !== undefined) {
      if (id == null) id = m[2];
    } else {
      let value = m[4];
      if (
        value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'")))
      ) {
        value = value.substring(1, value.length - 1);
      }
      pairs[m[3]] = value;
    }
  }
  return { classes, id, pairs };
}

class _Scanner {
  constructor(text, tomSpecs) {
    this.text = text;
    this.tomSpecs = tomSpecs;
    this.lineStarts = [];
    this.lines = [];
    this.elements = [];
    this.findings = [];
    let offset = 0;
    for (const line of text.split('\n')) {
      this.lineStarts.push(offset);
      this.lines.push(line);
      offset += line.length + 1;
    }
  }

  lineOf(offset) {
    let lo = 0;
    let hi = this.lineStarts.length - 1;
    while (lo < hi) {
      const mid = (lo + hi + 1) >> 1;
      if (this.lineStarts[mid] <= offset) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  find(code, offset, message) {
    this.findings.push(new NotationFinding(code, offset, this.lineOf(offset), message));
  }

  scan() {
    this.blocks();
    this.kindFindings();
    const sorted = this.elements.slice().sort((a, b) => {
      if (a.start !== b.start) return a.start - b.start;
      if (a.end !== b.end) return b.end - a.end;
      return _typeOrder.indexOf(a.type) - _typeOrder.indexOf(b.type);
    });
    const roots = [];
    const stack = [];
    for (const e of sorted) {
      while (
        stack.length > 0 &&
        !(e.start >= stack[stack.length - 1].start && e.end <= stack[stack.length - 1].end)
      ) {
        stack.pop();
      }
      (stack.length === 0 ? roots : stack[stack.length - 1].children).push(e);
      stack.push(e);
    }
    const findings = this.findings.slice().sort((a, b) =>
      a.offset !== b.offset
        ? a.offset - b.offset
        : _codeOrder.indexOf(a.code) - _codeOrder.indexOf(b.code),
    );
    return new NotationScan(this.text, roots, findings);
  }

  // --- Blocks -------------------------------------------------------------

  blocks() {
    const text = this.text;
    const open = [];
    let codeFence = null;
    let inAnnotation = false;
    let regionStart = null;
    let regionEnd = 0;

    const endRegion = () => {
      if (regionStart != null) this.inline(regionStart, regionEnd);
      regionStart = null;
    };

    for (let i = 0; i < this.lines.length; i++) {
      const line = this.lines[i];
      const start = this.lineStarts[i];
      const lineEnd = start + line.length;
      const next = i + 1 < this.lines.length ? this.lineStarts[i + 1] : text.length;

      if (codeFence != null) {
        const t = line.replace(/^\s+/, '');
        if (
          line.length - t.length <= 3 &&
          t.startsWith(codeFence) &&
          t.substring(codeFence.length).split(codeFence[0]).join('').trim() === ''
        ) {
          codeFence = null;
        }
        continue;
      }

      if (_annotationStart.test(line)) {
        if (!inAnnotation && open.length > 0) {
          this.find(
            NotationFindingCode.ANNOTATION_INSIDE_DIV,
            start,
            'a comment or question block stands inside a div',
          );
        }
        inAnnotation = true;
      } else if (!_quoteLine.test(line)) {
        inAnnotation = false;
      }
      if (inAnnotation) {
        if (_quotedDivOpen.test(line)) {
          this.find(
            NotationFindingCode.DIV_INSIDE_ANNOTATION,
            start,
            'a div stands inside a comment or question block',
          );
        }
        if (regionStart == null) regionStart = start;
        regionEnd = lineEnd;
        continue;
      }

      const code = _codeFenceOpen.exec(line);
      if (code != null && !(code[1].startsWith('`') && code[2].includes('`'))) {
        endRegion();
        codeFence = code[1];
        continue;
      }

      const divOpen = _divOpen.exec(line);
      if (divOpen != null) {
        endRegion();
        const attributes =
          divOpen[1] !== undefined
            ? _parseAttributes(divOpen[1])
            : { classes: [divOpen[2]], id: null, pairs: {} };
        open.push({ start, contentStart: next, line: i + 1, attributes });
        continue;
      }

      if (_divClose.test(line)) {
        endRegion();
        const d = open.pop();
        if (d === undefined) {
          this.find(
            NotationFindingCode.STRAY_CLOSING_FENCE,
            start,
            'a closing fence has no open div',
          );
        } else {
          this.addDiv(d, lineEnd, start, true);
        }
        continue;
      }

      if (line.trim() === '') {
        endRegion();
        continue;
      }
      if (regionStart == null) regionStart = start;
      regionEnd = lineEnd;
    }
    endRegion();
    while (open.length > 0) {
      const d = open.pop();
      this.find(NotationFindingCode.UNCLOSED_DIV, d.start, 'an opening fence has no closing fence');
      this.addDiv(d, text.length, text.length, false);
    }
  }

  addDiv(d, end, contentEnd, closed) {
    const a = d.attributes;
    const contentStart = d.contentStart > contentEnd ? contentEnd : d.contentStart;
    this.elements.push(
      new NotationElement(
        'div',
        a.classes.length === 0 ? null : a.classes[0],
        a.classes,
        a.id,
        a.pairs,
        null,
        d.start,
        end,
        contentStart,
        contentEnd,
        d.line,
        this.lineOf(end > d.start ? end - 1 : d.start),
        closed,
      ),
    );
  }

  // --- Inline -------------------------------------------------------------

  inline(start, end) {
    const text = this.text;
    const literal = new Map();
    const escaped = new Set();
    for (let i = start; i < end; i++) {
      const c = text[i];
      if (c === '\\' && i + 1 < end && _asciiPunctuation.includes(text[i + 1])) {
        escaped.add(i + 1);
        i++;
        continue;
      }
      if (c === '`') {
        let n = 0;
        while (i + n < end && text[i + n] === '`') n++;
        const close = this.closingBackticks(i + n, end, n);
        if (close >= 0) {
          literal.set(i, close + n);
          i = close + n - 1;
        } else {
          i += n - 1;
        }
      }
    }

    const spans = [];
    const marks = [];
    const brackets = [];
    let i = start;
    while (i < end) {
      const skip = literal.get(i);
      if (skip !== undefined) {
        i = skip;
        continue;
      }
      const c = text[i];
      if (escaped.has(i) || (c === '\\' && escaped.has(i + 1))) {
        i++;
        continue;
      }
      if (c === '{') {
        const opener = _markOpeners.find((o) => text.startsWith(o, i));
        if (opener !== undefined) {
          const closer = _markClosers[opener];
          const close = text.indexOf(closer, i + 3);
          if (close >= 0 && close + closer.length <= end) {
            marks.push([i, close + closer.length]);
          }
          i += 3;
          continue;
        }
      }
      if (c === '[') {
        brackets.push(i);
      } else if (c === ']' && brackets.length > 0) {
        const openAt = brackets.pop();
        if (
          i + 1 < end &&
          text[i + 1] === '{' &&
          !escaped.has(i + 1) &&
          !_markOpeners.some((o) => text.startsWith(o, i + 1))
        ) {
          const close = this.closingBrace(i + 2, end);
          if (close < 0) {
            this.find(
              NotationFindingCode.UNCLOSED_SPAN,
              i + 1,
              "a span's attribute braces do not close on the paragraph",
            );
          } else {
            const a = _parseAttributes(text.substring(i + 2, close));
            const span = new NotationElement(
              'span',
              a.classes.length === 0 ? null : a.classes[0],
              a.classes,
              a.id,
              a.pairs,
              null,
              openAt,
              close + 1,
              openAt + 1,
              i,
              this.lineOf(openAt),
              this.lineOf(close),
              true,
            );
            spans.push(span);
            this.elements.push(span);
            i = close + 1;
            continue;
          }
        }
      } else if (c === '(' && i + 3 < end && text[i + 3] === ' ') {
        const arrow = text.substring(i + 1, i + 3);
        const kind = _citationKinds[arrow];
        if (kind !== undefined) {
          const close = this.closingParenthesis(i + 4, end, literal);
          if (close > i + 4 && text.substring(i + 4, close).trim() !== '') {
            const citation = new NotationElement(
              'citation',
              kind,
              [kind],
              null,
              {},
              arrow,
              i,
              close + 1,
              i + 4,
              close,
              this.lineOf(i),
              this.lineOf(close),
              true,
            );
            spans.push(citation);
            this.elements.push(citation);
            i += 4;
            continue;
          }
        }
      }
      i++;
    }

    for (const [ms, me] of marks) {
      for (const e of spans) {
        const crosses =
          (ms < e.start && e.start < me && me < e.end) ||
          (e.start < ms && ms < e.end && e.end < me);
        if (crosses) {
          this.find(
            NotationFindingCode.MARK_ACROSS_NOTATION,
            ms,
            `an inline review mark crosses the boundary of a ${e.type}`,
          );
          break;
        }
      }
    }
  }

  closingBackticks(from, end, n) {
    const text = this.text;
    let i = from;
    while (i < end) {
      if (text[i] === '`') {
        let m = 0;
        while (i + m < end && text[i + m] === '`') m++;
        if (m === n) return i;
        i += m;
      } else {
        i++;
      }
    }
    return -1;
  }

  closingBrace(from, end) {
    const text = this.text;
    let quote = null;
    for (let i = from; i < end; i++) {
      const c = text[i];
      if (quote != null) {
        if (c === quote) quote = null;
      } else if (c === '"' || c === "'") {
        quote = c;
      } else if (c === '}') {
        return i;
      } else if (c === '{') {
        return -1;
      }
    }
    return -1;
  }

  closingParenthesis(from, end, literal) {
    const text = this.text;
    let depth = 0;
    let i = from;
    while (i < end) {
      const skip = literal.get(i);
      if (skip !== undefined) {
        i = skip;
        continue;
      }
      const c = text[i];
      if (c === '(') {
        depth++;
      } else if (c === ')') {
        if (depth === 0) return i;
        depth--;
      }
      i++;
    }
    return -1;
  }

  // --- Kinds --------------------------------------------------------------

  kindFindings() {
    for (const e of this.elements) {
      if (e.type === 'citation') continue;
      if (e.type === 'div' && e.kind === 'rejected') {
        this.find(
          NotationFindingCode.REJECTED_BLOCK,
          e.start,
          'a rejected block waits for its resolution',
        );
      }
      if (!this.tomSpecs) continue;
      if (e.kind == null) {
        if (e.type === 'div') {
          this.find(NotationFindingCode.DIV_WITHOUT_KIND, e.start, "a div's attributes hold no class");
        }
      } else if (!e.isRegistered) {
        this.find(
          NotationFindingCode.UNKNOWN_KIND,
          e.start,
          `the kind "${e.kind}" is not registered`,
        );
      }
    }
  }
}

module.exports = {
  NotationElement,
  NotationFinding,
  NotationFindingCode,
  NotationScan,
  notationSeverity,
  registeredNotationKinds,
  scanNotation,
};
