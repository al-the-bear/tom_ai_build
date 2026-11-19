/**
 * The reading notation's scanner: one call per text value, returning the
 * value's fenced divs, bracketed spans and citation shapes with their kind,
 * attributes, source ranges and nesting, and the findings the DocSpecs
 * specification lists for the notation (*Reading Notation*, RN-1 … RN-13).
 *
 * The TypeScript port of `tom_som_dart_runtime`'s `spec_notation.dart`: the
 * same grammar, the same elements and findings, the same UTF-16 offsets; both
 * run `tom_som_conformance/corpus/notation_cases.json`.
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
export const registeredNotationKinds: ReadonlySet<string> = new Set([
  'provenance',
  'trace',
  'editorial',
  'aside',
  'refs',
  'records',
  'rejected',
]);

/** What an element of the notation is. */
export type NotationElementType = 'div' | 'span' | 'citation';

/** How serious a finding is. */
export type NotationSeverity = 'error' | 'warning';

/** The notation's findings (RN-10); each is the rule's name in the validator. */
export const NotationFindingCode = Object.freeze({
  UNCLOSED_DIV: 'unclosedDiv',
  STRAY_CLOSING_FENCE: 'strayClosingFence',
  UNCLOSED_SPAN: 'unclosedSpan',
  DIV_WITHOUT_KIND: 'divWithoutKind',
  UNKNOWN_KIND: 'unknownKind',
  MARK_ACROSS_NOTATION: 'markAcrossNotation',
  ANNOTATION_INSIDE_DIV: 'annotationInsideDiv',
  DIV_INSIDE_ANNOTATION: 'divInsideAnnotation',
  REJECTED_BLOCK: 'rejectedBlock',
} as const);

/** One of the {@link NotationFindingCode} values. */
export type NotationFindingCodeValue =
  (typeof NotationFindingCode)[keyof typeof NotationFindingCode];

const _codeOrder: readonly string[] = Object.values(NotationFindingCode);
const _typeOrder: readonly NotationElementType[] = ['div', 'span', 'citation'];

/** The severity of [code]: an unknown kind is a warning, the rest errors. */
export function notationSeverity(
  code: NotationFindingCodeValue,
): NotationSeverity {
  return code === NotationFindingCode.UNKNOWN_KIND ? 'warning' : 'error';
}

/** One element of the notation: a div, a span or a citation. */
export class NotationElement {
  /** The elements nested in this one, in source order. */
  readonly children: NotationElement[] = [];

  constructor(
    /** Div, span or citation. */
    readonly type: NotationElementType,
    /** The first class; `trace` / `provenance` for a citation; null without a class. */
    readonly kind: string | null,
    /** Every class, the kind first. */
    readonly classes: string[],
    /** The `#id` of the attributes (not a section id). */
    readonly id: string | null,
    /** The `key="value"` pairs, in their order. */
    readonly attributes: Record<string, string>,
    /** A citation's arrow: `->`, `<-` or `<~`; null otherwise. */
    readonly shape: string | null,
    /** The offset of the first character. */
    readonly start: number,
    /** The offset after the last character. */
    readonly end: number,
    /** The offset of the content. */
    readonly contentStart: number,
    /** The offset after the content. */
    readonly contentEnd: number,
    /** The 1-based line of start. */
    readonly line: number,
    /** The 1-based line of the last character. */
    readonly endLine: number,
    /** False for a div without a closing fence. */
    readonly closed: boolean,
  ) {}

  /** Whether the kind is registered. */
  get isRegistered(): boolean {
    return this.kind != null && registeredNotationKinds.has(this.kind);
  }

  /** The element as the conformance corpus writes it. */
  toJson(text: string): Record<string, unknown> {
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
export class NotationFinding {
  constructor(
    readonly code: NotationFindingCodeValue,
    readonly offset: number,
    readonly line: number,
    readonly message: string,
  ) {}

  /** The severity of the code. */
  get severity(): NotationSeverity {
    return notationSeverity(this.code);
  }

  /** The finding as the conformance corpus writes it. */
  toJson(): Record<string, unknown> {
    return { code: this.code, severity: this.severity, line: this.line };
  }

  toString(): string {
    return `line ${this.line}: ${this.code} — ${this.message}`;
  }
}

/** The result of {@link scanNotation}. */
export class NotationScan {
  constructor(
    readonly text: string,
    /** The elements not nested in another, in source order. */
    readonly elements: NotationElement[],
    /** The findings, by offset. */
    readonly findings: NotationFinding[],
  ) {}

  /** Every element, depth-first in source order. */
  get all(): NotationElement[] {
    const out: NotationElement[] = [];
    const walk = (list: NotationElement[]): void => {
      for (const e of list) {
        out.push(e);
        walk(e.children);
      }
    };
    walk(this.elements);
    return out;
  }

  /** Whether a finding of severity error is present. */
  get hasErrors(): boolean {
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
const _markClosers: Record<string, string> = {
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
  '{==': '==}',
  '{>>': '<<}',
};
const _citationKinds: Record<string, string> = {
  '->': 'trace',
  '<-': 'provenance',
  '<~': 'provenance',
};

/**
 * Scans one text value for the reading notation. [tomSpecs] says the value
 * belongs to a TomSpecs rendition: only then are a div without a class and an
 * unregistered kind reported (RN-10).
 */
export function scanNotation(
  text: string,
  options: { tomSpecs?: boolean } = {},
): NotationScan {
  return new _Scanner(text, options.tomSpecs === true).scan();
}

interface _Attributes {
  classes: string[];
  id: string | null;
  pairs: Record<string, string>;
}

interface _OpenDiv {
  start: number;
  contentStart: number;
  line: number;
  attributes: _Attributes;
}

function _parseAttributes(inner: string): _Attributes {
  const classes: string[] = [];
  let id: string | null = null;
  const pairs: Record<string, string> = {};
  _attributeToken.lastIndex = 0;
  let m: RegExpExecArray | null;
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
  private readonly lineStarts: number[] = [];
  private readonly lines: string[] = [];
  private readonly elements: NotationElement[] = [];
  private readonly findings: NotationFinding[] = [];

  constructor(
    private readonly text: string,
    private readonly tomSpecs: boolean,
  ) {
    let offset = 0;
    for (const line of text.split('\n')) {
      this.lineStarts.push(offset);
      this.lines.push(line);
      offset += line.length + 1;
    }
  }

  private lineOf(offset: number): number {
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

  private find(code: NotationFindingCodeValue, offset: number, message: string): void {
    this.findings.push(
      new NotationFinding(code, offset, this.lineOf(offset), message),
    );
  }

  scan(): NotationScan {
    this.blocks();
    this.kindFindings();
    const sorted = this.elements.slice().sort((a, b) => {
      if (a.start !== b.start) return a.start - b.start;
      if (a.end !== b.end) return b.end - a.end;
      return _typeOrder.indexOf(a.type) - _typeOrder.indexOf(b.type);
    });
    const roots: NotationElement[] = [];
    const stack: NotationElement[] = [];
    for (const e of sorted) {
      while (
        stack.length > 0 &&
        !(e.start >= stack[stack.length - 1].start &&
          e.end <= stack[stack.length - 1].end)
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

  private blocks(): void {
    const text = this.text;
    const open: _OpenDiv[] = [];
    let codeFence: string | null = null;
    let inAnnotation = false;
    let regionStart: number | null = null;
    let regionEnd = 0;

    const endRegion = (): void => {
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
      const d = open.pop()!;
      this.find(
        NotationFindingCode.UNCLOSED_DIV,
        d.start,
        'an opening fence has no closing fence',
      );
      this.addDiv(d, text.length, text.length, false);
    }
  }

  private addDiv(d: _OpenDiv, end: number, contentEnd: number, closed: boolean): void {
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

  private inline(start: number, end: number): void {
    const text = this.text;
    const literal = new Map<number, number>();
    const escaped = new Set<number>();
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

    const spans: NotationElement[] = [];
    const marks: Array<[number, number]> = [];
    const brackets: number[] = [];
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
        const openAt = brackets.pop()!;
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

  private closingBackticks(from: number, end: number, n: number): number {
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

  private closingBrace(from: number, end: number): number {
    const text = this.text;
    let quote: string | null = null;
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

  private closingParenthesis(from: number, end: number, literal: Map<number, number>): number {
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

  private kindFindings(): void {
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
          this.find(
            NotationFindingCode.DIV_WITHOUT_KIND,
            e.start,
            "a div's attributes hold no class",
          );
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
