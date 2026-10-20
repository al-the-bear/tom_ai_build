/**
 * Review annotations in content values (SOM §11.9): comment blocks, question
 * blocks and CriticMarkup inline marks — a port of
 * `tom_som_dart_runtime/lib/src/spec_review_annotations.dart`.
 *
 * An annotation is text inside a content value or a form-field value. This
 * module reads it out of that text and edits it in place, and every edit is
 * byte-stable outside the annotation it touches. The notation itself is
 * `som_multiplatform_spec_model.md` §11.9.
 *
 * Positions are **0-based line numbers within the value**, never character
 * offsets: the nine runtimes count characters in different units, and a line
 * number is the same in all of them.
 */

import { SpecDocument } from './spec_document';
import { SpecValidationCode, SpecValidationError } from './spec_validator';

/** The three kinds of annotation (SOM §11.9). */
export const SpecReviewAnnotationKind = {
  /** A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`. */
  COMMENT: 'comment',
  /** One question of a question block, `> **❓ BQ-81 — topic:** …`. */
  QUESTION: 'question',
  /** A CriticMarkup inline mark. */
  MARK: 'mark',
} as const;

export type SpecReviewAnnotationKindValue =
  (typeof SpecReviewAnnotationKind)[keyof typeof SpecReviewAnnotationKind];

/** The five CriticMarkup inline marks (SOM §11.9.3). */
export const SpecMarkKind = {
  /** `{>> comment <<}`. */
  COMMENT: 'comment',
  /** `{== text ==}`, optionally followed by `{>> comment <<}`. */
  HIGHLIGHT: 'highlight',
  /** `{++ added ++}`. */
  INSERTION: 'insertion',
  /** `{-- removed --}`. */
  DELETION: 'deletion',
  /** `{~~ old ~> new ~~}`. */
  SUBSTITUTION: 'substitution',
} as const;

export type SpecMarkKindValue = (typeof SpecMarkKind)[keyof typeof SpecMarkKind];

/** The constructor options of a {@link SpecReviewAnnotation}. */
export interface SpecReviewAnnotationInit {
  kind: SpecReviewAnnotationKindValue;
  path: string;
  field?: string | null;
  line: number;
  id?: string | null;
  qualifiedId?: string | null;
  author?: string | null;
  text?: string;
  context?: string;
  topic?: string | null;
  starred?: boolean;
  combined?: boolean;
  answer?: string;
  markKind?: SpecMarkKindValue | null;
  newText?: string | null;
  comment?: string | null;
}

/** One annotation, located by the value that holds it. */
export class SpecReviewAnnotation {
  /** The kind. */
  readonly kind: SpecReviewAnnotationKindValue;
  /** The document path of the value: a content path, or a form path when `field` is set. */
  readonly path: string;
  /** The form field whose value holds the annotation; null for content. */
  readonly field: string | null;
  /** The 0-based line within the value where the annotation starts (a question: its header line). */
  readonly line: number;
  /** The comment id (`C-12`) or question id (`BQ-81`); null for a comment without an id and for a mark. */
  readonly id: string | null;
  /** A comment's id with the document qualifier in front (`SBP C-12`). */
  readonly qualifiedId: string | null;
  /** A comment's author; null when none is written. */
  readonly author: string | null;
  /** A comment's, question's (options included) or mark's text. */
  readonly text: string;
  /** A comment's context: the paragraph before the block, verbatim. */
  readonly context: string;
  /** A question's topic (in a combined block: the field it asks about). */
  readonly topic: string | null;
  /** Whether a question carries `★` before its topic. */
  readonly starred: boolean;
  /** Whether a question is part of a combined block. */
  readonly combined: boolean;
  /** A question's answer, trimmed; empty when open. */
  readonly answer: string;
  /** A mark's kind. */
  readonly markKind: SpecMarkKindValue | null;
  /** A substitution's new text. */
  readonly newText: string | null;
  /** The comment of a comment mark, or of a highlight followed by one. */
  readonly comment: string | null;

  constructor(init: SpecReviewAnnotationInit) {
    this.kind = init.kind;
    this.path = init.path;
    this.field = init.field ?? null;
    this.line = init.line;
    this.id = init.id ?? null;
    this.qualifiedId = init.qualifiedId ?? null;
    this.author = init.author ?? null;
    this.text = init.text ?? '';
    this.context = init.context ?? '';
    this.topic = init.topic ?? null;
    this.starred = init.starred ?? false;
    this.combined = init.combined ?? false;
    this.answer = init.answer ?? '';
    this.markKind = init.markKind ?? null;
    this.newText = init.newText ?? null;
    this.comment = init.comment ?? null;
  }

  /** Whether a question is still open (no answer written). */
  get open(): boolean {
    return this.kind === SpecReviewAnnotationKind.QUESTION && this.answer.length === 0;
  }

  /** The canonical JSON form the conformance corpus pins. */
  toJson(): Record<string, unknown> {
    switch (this.kind) {
      case SpecReviewAnnotationKind.COMMENT:
        return {
          kind: 'comment',
          path: this.path,
          field: this.field,
          line: this.line,
          id: this.id,
          qualifiedId: this.qualifiedId,
          author: this.author,
          text: this.text,
          context: this.context,
        };
      case SpecReviewAnnotationKind.QUESTION:
        return {
          kind: 'question',
          path: this.path,
          field: this.field,
          line: this.line,
          id: this.id,
          topic: this.topic,
          starred: this.starred,
          combined: this.combined,
          text: this.text,
          answer: this.answer,
          open: this.open,
        };
      default:
        return {
          kind: 'mark',
          path: this.path,
          field: this.field,
          line: this.line,
          markKind: this.markKind,
          text: this.text,
          newText: this.newText,
          comment: this.comment,
        };
    }
  }
}

/** The counts a report needs (SOM §11.9). */
export class SpecReviewAnnotationCounts {
  /** Every question. */
  readonly questions: number;
  /** Questions without an answer. */
  readonly openQuestions: number;
  /** Questions with an answer. */
  readonly answeredQuestions: number;
  /** Comment blocks. */
  readonly comments: number;
  /** Inline marks. */
  readonly marks: number;

  constructor(
    init: {
      questions?: number;
      openQuestions?: number;
      answeredQuestions?: number;
      comments?: number;
      marks?: number;
    } = {},
  ) {
    this.questions = init.questions ?? 0;
    this.openQuestions = init.openQuestions ?? 0;
    this.answeredQuestions = init.answeredQuestions ?? 0;
    this.comments = init.comments ?? 0;
    this.marks = init.marks ?? 0;
  }

  /** The canonical JSON form. */
  toJson(): Record<string, number> {
    return {
      questions: this.questions,
      openQuestions: this.openQuestions,
      answeredQuestions: this.answeredQuestions,
      comments: this.comments,
      marks: this.marks,
    };
  }
}

/** A question to insert (SOM §11.9.2). */
export class SpecQuestionDraft {
  /** The question id (`BQ-90`). */
  readonly id: string;
  /** The topic. */
  readonly topic: string;
  /** The question text; may span lines. */
  readonly text: string;
  /** Option lines, written as `- <option>` (e.g. `(a) lower only`). */
  readonly options: string[];
  /** The recommendation, or empty. */
  readonly recommendation: string;
  /** The working assumption, or empty. */
  readonly assumption: string;
  /** Whether the question carries `★`. */
  readonly starred: boolean;

  constructor(init: {
    id: string;
    topic: string;
    text: string;
    options?: string[];
    recommendation?: string;
    assumption?: string;
    starred?: boolean;
  }) {
    this.id = init.id;
    this.topic = init.topic;
    this.text = init.text;
    this.options = init.options ?? [];
    this.recommendation = init.recommendation ?? '';
    this.assumption = init.assumption ?? '';
    this.starred = init.starred ?? false;
  }

  /** Reads a draft from its corpus JSON form. */
  static fromJson(j: any): SpecQuestionDraft {
    return new SpecQuestionDraft({
      id: j.id as string,
      topic: j.topic as string,
      text: j.text as string,
      options: ((j.options as unknown[] | undefined) ?? []).map((o) => `${o}`),
      recommendation: (j.recommendation as string | undefined) ?? '',
      assumption: (j.assumption as string | undefined) ?? '',
      starred: (j.starred as boolean | undefined) ?? false,
    });
  }
}

/** What to do with one inline mark (SOM §11.9.3). */
export const SpecMarkDecision = {
  /** Take the change: an insertion's text, nothing for a deletion, a substitution's new text. */
  ACCEPT: 'accept',
  /** Undo the change: nothing for an insertion, a deletion's text, a substitution's old text. */
  REJECT: 'reject',
  /** Keep the mark as written. */
  LEAVE: 'leave',
} as const;

export type SpecMarkDecisionValue = (typeof SpecMarkDecision)[keyof typeof SpecMarkDecision];

/** One inline mark as `listMarks` reports it. */
export class SpecMarkEntry {
  /** `M-<n>`: the mark's 1-based position among all marks of the document. */
  readonly id: string;
  /** The value's path. */
  readonly path: string;
  /** The form field, or null for content. */
  readonly field: string | null;
  /** The 0-based line within the value where the mark opens. */
  readonly line: number;
  /** The mark's kind. */
  readonly markKind: SpecMarkKindValue;
  /** The text after rejecting the mark. */
  readonly oldText: string;
  /** The text after accepting the mark. */
  readonly newText: string;
  /** A comment mark's or a commented highlight's comment. */
  readonly comment: string | null;
  /** The mark as written. */
  readonly markup: string;
  /** The paragraph holding the mark, verbatim — for display. */
  readonly context: string;

  constructor(init: {
    id: string;
    path: string;
    field?: string | null;
    line: number;
    markKind: SpecMarkKindValue;
    oldText: string;
    newText: string;
    comment?: string | null;
    markup: string;
    context: string;
  }) {
    this.id = init.id;
    this.path = init.path;
    this.field = init.field ?? null;
    this.line = init.line;
    this.markKind = init.markKind;
    this.oldText = init.oldText;
    this.newText = init.newText;
    this.comment = init.comment ?? null;
    this.markup = init.markup;
    this.context = init.context;
  }

  /** The canonical JSON form the conformance corpus pins. */
  toJson(): Record<string, unknown> {
    return {
      id: this.id,
      path: this.path,
      field: this.field,
      line: this.line,
      markKind: this.markKind,
      oldText: this.oldText,
      newText: this.newText,
      comment: this.comment,
      markup: this.markup,
      context: this.context,
    };
  }
}

/** What was done to one mark. */
export class SpecMarkOutcome {
  /** The mark's id at the revision the operation ran on. */
  readonly id: string;
  /** The value's path. */
  readonly path: string;
  /** The form field, or null for content. */
  readonly field: string | null;
  /** The 0-based line within the value where the mark opened. */
  readonly line: number;
  /** The mark's kind. */
  readonly markKind: SpecMarkKindValue;
  /** Accepted or rejected. */
  readonly decision: SpecMarkDecisionValue;
  /** The mark as written. */
  readonly markup: string;
  /** The text that replaced it. */
  readonly result: string;

  constructor(init: {
    id: string;
    path: string;
    field?: string | null;
    line: number;
    markKind: SpecMarkKindValue;
    decision: SpecMarkDecisionValue;
    markup: string;
    result: string;
  }) {
    this.id = init.id;
    this.path = init.path;
    this.field = init.field ?? null;
    this.line = init.line;
    this.markKind = init.markKind;
    this.decision = init.decision;
    this.markup = init.markup;
    this.result = init.result;
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return {
      id: this.id,
      path: this.path,
      field: this.field,
      line: this.line,
      markKind: this.markKind,
      decision: this.decision,
      markup: this.markup,
      result: this.result,
    };
  }
}

/** A mark the scanner could not read; it is left as written. */
export class SpecMarkIssue {
  /** The value's path. */
  readonly path: string;
  /** The form field, or null for content. */
  readonly field: string | null;
  /** The 0-based line within the value. */
  readonly line: number;
  /** `unclosed`, `nested` or `noArrow`. */
  readonly issue: string;

  constructor(init: { path: string; field?: string | null; line: number; issue: string }) {
    this.path = init.path;
    this.field = init.field ?? null;
    this.line = init.line;
    this.issue = init.issue;
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return { path: this.path, field: this.field, line: this.line, issue: this.issue };
  }
}

/** The report of a mark operation, for the decision log. */
export class SpecMarkReport {
  /** What was done, in document order. */
  readonly applied: SpecMarkOutcome[];
  /** Malformed marks in scope, left as written. */
  readonly malformed: SpecMarkIssue[];

  constructor(init: { applied?: SpecMarkOutcome[]; malformed?: SpecMarkIssue[] } = {}) {
    this.applied = init.applied ?? [];
    this.malformed = init.malformed ?? [];
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return {
      applied: this.applied.map((a) => a.toJson()),
      malformed: this.malformed.map((m) => m.toJson()),
    };
  }
}

/**
 * Thrown when an operation names an annotation, value or paragraph that does
 * not exist. Nothing is changed before it is thrown.
 */
export class SpecReviewAnnotationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SpecReviewAnnotationError';
    Object.setPrototypeOf(this, SpecReviewAnnotationError.prototype);
  }

  toString(): string {
    return `SpecReviewAnnotationError: ${this.message}`;
  }
}

// ---------------------------------------------------------------------------
// Text level: one value.
// ---------------------------------------------------------------------------

const _ARROW = '⬆';
const _VS16 = '️';
const _QUESTION_OPEN = '**❓';
const _COMBINED_OPENER = '**❓ Open questions on these fields**';
const _ANSWER_LABEL = '**Answer:**';
const _EM_DASH_SEP = ' — ';
const _STAR = '★';

/** One question region inside a question block. */
interface _Question {
  header: number; // value line of the header
  regionEnd: number; // last value line of the region (inclusive)
  answerLine: number | null; // value line of `**Answer:**`, or null
  id: string;
  topic: string;
  starred: boolean;
  text: string;
  answer: string;
}

/** One parsed comment block. */
interface _Comment {
  block: _Block;
  id: string | null;
  author: string | null;
  text: string;
  context: string;
  /** The first line up to where the text starts (kept by an edit). */
  headerPrefix: string;
  /** Where an id is inserted into the first line, and how. */
  markerEnd: number;
}

/** One parsed block of a value (lines [start, end] inclusive). */
interface _Block {
  start: number;
  end: number;
  kind: SpecReviewAnnotationKindValue;
  comment?: _Comment;
  questions?: _Question[];
  combined?: boolean;
}

/** One parsed mark; start/end are UTF-16 offsets into the value (never exported). */
interface _Mark {
  start: number;
  end: number;
  line: number;
  kind: SpecMarkKindValue;
  text: string;
  newText: string | null;
  comment: string | null;
}

/** Everything one value holds. */
interface _Parsed {
  lines: string[];
  code: boolean[]; // per line: inside a fenced block (fence lines too)
  blocks: _Block[];
  comments: _Comment[];
  marks: _Mark[];
  malformed: string[];
  /** Malformed inline marks as [value line, issue code]: `unclosed`, `nested`, `noArrow`. */
  markIssues: Array<[number, string]>;
}

function _lstrip(s: string): string {
  let i = 0;
  while (i < s.length && (s[i] === ' ' || s[i] === '\t')) {
    i++;
  }
  return s.substring(i);
}

function _isBlank(s: string): boolean {
  return s.trim().length === 0;
}

/** The fenced-code flag of every line. */
function _codeLines(lines: string[]): boolean[] {
  const code: boolean[] = new Array<boolean>(lines.length).fill(false);
  let fenceChar: string | null = null;
  let fenceLen = 0;
  for (let i = 0; i < lines.length; i++) {
    const t = _lstrip(lines[i]);
    if (fenceChar === null) {
      const c = t.length > 0 ? t[0] : '';
      if (c === '`' || c === '~') {
        let n = 0;
        while (n < t.length && t[n] === c) {
          n++;
        }
        if (n >= 3) {
          fenceChar = c;
          fenceLen = n;
          code[i] = true;
        }
      }
    } else {
      code[i] = true;
      let n = 0;
      while (n < t.length && t[n] === fenceChar) {
        n++;
      }
      if (n >= fenceLen && t.substring(n).trim().length === 0) {
        fenceChar = null;
      }
    }
  }
  return code;
}

function _isQuoteLine(line: string): boolean {
  return _lstrip(line).startsWith('>');
}

/** The line inside the quote: after `>` and one following space. */
function _inner(line: string): string {
  const t = _lstrip(line);
  let s = t.substring(1);
  if (s.startsWith(' ')) s = s.substring(1);
  return s;
}

function _parse(value: string): _Parsed {
  const lines = value.split('\n');
  const code = _codeLines(lines);
  const p: _Parsed = {
    lines,
    code,
    blocks: [],
    comments: [],
    marks: [],
    malformed: [],
    markIssues: [],
  };

  let i = 0;
  while (i < lines.length) {
    if (code[i] || !_isQuoteLine(lines[i])) {
      i++;
      continue;
    }
    const s = i;
    while (i + 1 < lines.length && !code[i + 1] && _isQuoteLine(lines[i + 1])) {
      i++;
    }
    const e = i;
    const first = _inner(lines[s]);
    if (first.startsWith(_ARROW)) {
      const b: _Block = { start: s, end: e, kind: SpecReviewAnnotationKind.COMMENT };
      p.blocks.push(b);
      const c = _parseComment(p, b);
      b.comment = c;
      p.comments.push(c);
    } else if (first.startsWith(_QUESTION_OPEN)) {
      const b: _Block = { start: s, end: e, kind: SpecReviewAnnotationKind.QUESTION };
      p.blocks.push(b);
      _parseQuestions(p, b);
    }
    i = e + 1;
  }

  _parseMarks(p);
  return p;
}

function _context(p: _Parsed, blockStart: number): string {
  let k = blockStart - 1;
  while (k >= 0 && (_isBlank(p.lines[k]) || _isQuoteLine(p.lines[k]))) {
    k--;
  }
  if (k < 0) return '';
  const end = k;
  while (k - 1 >= 0 && !_isBlank(p.lines[k - 1]) && !_isQuoteLine(p.lines[k - 1])) {
    k--;
  }
  return p.lines.slice(k, end + 1).join('\n');
}

function _parseComment(p: _Parsed, b: _Block): _Comment {
  const raw0 = p.lines[b.start];
  let rest = _inner(raw0).substring(_ARROW.length);
  if (rest.startsWith(_VS16)) rest = rest.substring(_VS16.length);
  const markerEnd = raw0.length - rest.length;
  rest = _lstrip(rest);
  let id: string | null = null;
  if (rest.startsWith('**C-')) {
    const close = rest.indexOf('**', 4);
    if (close >= 0) {
      const n = rest.substring(4, close);
      if (/^[1-9][0-9]*$/.test(n)) {
        id = `C-${n}`;
      } else {
        p.malformed.push(
          `line ${b.start}: comment id "C-${n}" is not C-<number> (SOM §11.9.1)`,
        );
      }
      rest = _lstrip(rest.substring(close + 2));
    }
  }
  let author: string | null = null;
  if (rest.startsWith('(')) {
    const close = rest.indexOf(')');
    if (close > 0) {
      author = rest.substring(1, close);
      rest = rest.substring(close + 1);
      if (rest.startsWith(':')) rest = rest.substring(1);
      rest = _lstrip(rest);
    }
  } else if (rest.startsWith(':')) {
    rest = _lstrip(rest.substring(1));
  }
  const headerPrefix = raw0.substring(0, raw0.length - rest.length);
  const textLines = [rest];
  for (let k = b.start + 1; k <= b.end; k++) {
    const inner = _inner(p.lines[k]);
    const t = _lstrip(inner);
    if (t.startsWith(_QUESTION_OPEN) || t.startsWith(_ANSWER_LABEL)) {
      p.malformed.push(
        `line ${k}: a comment block holds a question or an answer; the ` +
          'question goes into its own block after the comment (SOM §11.9.1)',
      );
    }
    textLines.push(inner);
  }
  return {
    block: b,
    id,
    author,
    text: textLines.join('\n').trim(),
    context: _context(p, b.start),
    headerPrefix,
    markerEnd,
  };
}

interface _Header {
  id: string;
  topic: string;
  starred: boolean;
  rest: string;
}

/** Parses a question header's remainder after `**❓ `; null when malformed. */
function _parseHeader(inner: string): _Header | null {
  const h = inner.substring(_QUESTION_OPEN.length + 1);
  const sep = h.indexOf(_EM_DASH_SEP);
  if (sep <= 0) return null;
  const id = h.substring(0, sep);
  if (!/^[A-Z][A-Z0-9]*-[0-9]+$/.test(id)) return null;
  let t = h.substring(sep + _EM_DASH_SEP.length);
  let starred = false;
  if (t.startsWith(`${_STAR} `)) {
    starred = true;
    t = t.substring(_STAR.length + 1);
  }
  const close = t.indexOf(':**');
  if (close < 0) return null;
  const topic = t.substring(0, close);
  let rest = t.substring(close + 3);
  if (rest.startsWith(' ')) rest = rest.substring(1);
  return { id, topic, starred, rest };
}

function _parseQuestions(p: _Parsed, b: _Block): void {
  const inner: string[] = [];
  for (let k = b.start; k <= b.end; k++) inner.push(_inner(p.lines[k]));
  b.combined = inner[0].startsWith(_COMBINED_OPENER);
  const headers: Array<[number, _Header]> = []; // ascending line
  for (let k = 0; k < inner.length; k++) {
    if (!inner[k].startsWith(`${_QUESTION_OPEN} `)) continue;
    if (inner[k].startsWith(_COMBINED_OPENER)) continue;
    const h = _parseHeader(inner[k]);
    if (h === null) {
      p.malformed.push(
        `line ${b.start + k}: question header is not ` +
          '"**❓ <ID> — <topic>:**" (SOM §11.9.2)',
      );
      continue;
    }
    headers.push([k, h]);
  }
  const list: _Question[] = [];
  for (let q = 0; q < headers.length; q++) {
    const [k, h] = headers[q];
    const regionEnd = q + 1 < headers.length ? headers[q + 1][0] - 1 : inner.length - 1;
    let answer: number | null = null;
    for (let m = k + 1; m <= regionEnd; m++) {
      if (inner[m].startsWith(_ANSWER_LABEL)) {
        answer = m;
        break;
      }
    }
    const textEnd = answer === null ? regionEnd : answer - 1;
    const text = [h.rest, ...inner.slice(k + 1, textEnd + 1)].join('\n').trim();
    let answerText = '';
    if (answer !== null) {
      answerText = [
        inner[answer].substring(_ANSWER_LABEL.length),
        ...inner.slice(answer + 1, regionEnd + 1),
      ]
        .join('\n')
        .trim();
    }
    list.push({
      header: b.start + k,
      regionEnd: b.start + regionEnd,
      answerLine: answer === null ? null : b.start + answer,
      id: h.id,
      topic: h.topic,
      starred: h.starred,
      text,
      answer: answerText,
    });
  }
  b.questions = list;
}

const _OPENERS = ['{>>', '{==', '{++', '{--', '{~~'];
const _CLOSERS: Record<string, string> = {
  '{>>': '<<}',
  '{==': '==}',
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
};

function _hasOpener(s: string): boolean {
  return _OPENERS.some((o) => s.includes(o));
}

/** The offset of the first blank line's start after `from` (the paragraph end), or the text length. */
function _paragraphEnd(text: string, from: number): number {
  let i = text.indexOf('\n', from);
  while (i >= 0) {
    const next = text.indexOf('\n', i + 1);
    const line = text.substring(i + 1, next < 0 ? text.length : next);
    if (line.trim().length === 0) return i;
    i = next;
  }
  return text.length;
}

function _parseMarks(p: _Parsed): void {
  // Offsets of each line's start in the value.
  const lineStart: number[] = [];
  let off = 0;
  for (const l of p.lines) {
    lineStart.push(off);
    off += l.length + 1;
  }
  const value = p.lines.join('\n');
  const lineOf = (offset: number): number => {
    let lo = 0;
    for (let k = 0; k < lineStart.length; k++) {
      if (lineStart[k] <= offset) lo = k;
    }
    return lo;
  };

  let k = 0;
  while (k < p.lines.length) {
    if (p.code[k]) {
      k++;
      continue;
    }
    // A run of non-code lines is scanned as one segment.
    const segStartLine = k;
    while (k < p.lines.length && !p.code[k]) {
      k++;
    }
    const segStart = lineStart[segStartLine];
    const segEnd = lineStart[k - 1] + p.lines[k - 1].length;
    _scanSegment(p, value.substring(segStart, segEnd), segStart, lineOf);
  }
}

function _scanSegment(
  p: _Parsed,
  seg: string,
  base: number,
  lineOf: (offset: number) => number,
): void {
  let i = 0;
  while (i < seg.length) {
    const c = seg[i];
    if (c === '`') {
      let n = 0;
      while (i + n < seg.length && seg[i + n] === '`') {
        n++;
      }
      // Find the next run of exactly n backticks.
      let j = i + n;
      let closeAt = -1;
      while (j < seg.length) {
        if (seg[j] === '`') {
          let m = 0;
          while (j + m < seg.length && seg[j + m] === '`') {
            m++;
          }
          if (m === n) {
            closeAt = j;
            break;
          }
          j += m;
        } else {
          j++;
        }
      }
      i = closeAt < 0 ? i + n : closeAt + n;
      continue;
    }
    if (c !== '{' || i + 3 > seg.length) {
      i++;
      continue;
    }
    const opener = seg.substring(i, i + 3);
    if (!_OPENERS.includes(opener)) {
      i++;
      continue;
    }
    const closer = _CLOSERS[opener];
    const close = seg.indexOf(closer, i + 3);
    const pend = _paragraphEnd(seg, i);
    const line = lineOf(base + i);
    if (close < 0 || close > pend) {
      p.malformed.push(
        `line ${line}: inline mark "${opener}" is not closed in its paragraph (SOM §11.9.3)`,
      );
      p.markIssues.push([line, 'unclosed']);
      i += 3;
      continue;
    }
    const inner = seg.substring(i + 3, close);
    if (_hasOpener(inner)) {
      p.malformed.push(`line ${line}: inline marks do not nest (SOM §11.9.3)`);
      p.markIssues.push([line, 'nested']);
      i = close + 3;
      continue;
    }
    let end = close + 3;
    const start = base + i;
    const mark = (
      kind: SpecMarkKindValue,
      text: string,
      newText: string | null,
      comment: string | null,
    ): _Mark => ({ start, end: base + end, line, kind, text, newText, comment });
    switch (opener) {
      case '{>>':
        p.marks.push(mark(SpecMarkKind.COMMENT, '', null, inner.trim()));
        break;
      case '{==': {
        let comment: string | null = null;
        if (seg.startsWith('{>>', end)) {
          const c2 = seg.indexOf('<<}', end + 3);
          if (c2 >= 0 && c2 <= _paragraphEnd(seg, end)) {
            const ci = seg.substring(end + 3, c2);
            if (!_hasOpener(ci)) {
              comment = ci.trim();
              end = c2 + 3;
            }
          }
        }
        p.marks.push(mark(SpecMarkKind.HIGHLIGHT, inner.trim(), null, comment));
        break;
      }
      case '{++':
        p.marks.push(mark(SpecMarkKind.INSERTION, inner.trim(), null, null));
        break;
      case '{--':
        p.marks.push(mark(SpecMarkKind.DELETION, inner.trim(), null, null));
        break;
      case '{~~': {
        const arrow = inner.indexOf('~>');
        if (arrow < 0) {
          p.malformed.push(`line ${line}: a substitution has no "~>" (SOM §11.9.3)`);
          p.markIssues.push([line, 'noArrow']);
          i = end;
          continue;
        }
        p.marks.push(
          mark(
            SpecMarkKind.SUBSTITUTION,
            inner.substring(0, arrow).trim(),
            inner.substring(arrow + 2).trim(),
            null,
          ),
        );
        break;
      }
      default:
        break;
    }
    i = end;
  }
}

/** The annotations of one value, in order: by line, blocks before marks, marks in scan order. */
function _annotationsOf(
  p: _Parsed,
  path: string,
  field: string | null,
  qualifier: string | null,
): SpecReviewAnnotation[] {
  const out: Array<[number, number, number, SpecReviewAnnotation]> = [];
  let seq = 0;
  for (const b of p.blocks) {
    if (b.kind === SpecReviewAnnotationKind.COMMENT) {
      const c = b.comment as _Comment;
      out.push([
        b.start,
        0,
        seq++,
        new SpecReviewAnnotation({
          kind: SpecReviewAnnotationKind.COMMENT,
          path,
          field,
          line: b.start,
          id: c.id,
          qualifiedId: qualifier !== null && c.id !== null ? `${qualifier} ${c.id}` : null,
          author: c.author,
          text: c.text,
          context: c.context,
        }),
      ]);
    } else {
      for (const q of b.questions ?? []) {
        out.push([
          q.header,
          0,
          seq++,
          new SpecReviewAnnotation({
            kind: SpecReviewAnnotationKind.QUESTION,
            path,
            field,
            line: q.header,
            id: q.id,
            topic: q.topic,
            starred: q.starred,
            combined: b.combined ?? false,
            text: q.text,
            answer: q.answer,
          }),
        ]);
      }
    }
  }
  for (const m of p.marks) {
    out.push([
      m.line,
      1,
      seq++,
      new SpecReviewAnnotation({
        kind: SpecReviewAnnotationKind.MARK,
        path,
        field,
        line: m.line,
        markKind: m.kind,
        text: m.text,
        newText: m.newText,
        comment: m.comment,
      }),
    ]);
  }
  out.sort((a, b) => a[0] - b[0] || a[1] - b[1] || a[2] - b[2]);
  return out.map((e) => e[3]);
}

/**
 * The paragraphs of a value as `[first line, last line]`, blank-separated and
 * fence-aware (a blank line inside a fenced block does not split).
 */
function _paragraphs(lines: string[], code: boolean[]): Array<[number, number]> {
  const out: Array<[number, number]> = [];
  let k = 0;
  while (k < lines.length) {
    if (_isBlank(lines[k]) && !code[k]) {
      k++;
      continue;
    }
    const s = k;
    while (k + 1 < lines.length && !(_isBlank(lines[k + 1]) && !code[k + 1])) {
      k++;
    }
    out.push([s, k]);
    k++;
  }
  return out;
}

/** Inserts `block` after value line `end` (-1: at the start), one blank line on each side. */
function _insertAfterLine(value: string, end: number, block: string[]): string {
  if (value.length === 0) return block.join('\n');
  const lines = value.split('\n');
  const before = lines.slice(0, end + 1);
  const rest = lines.slice(end + 1);
  const out = [...before];
  if (before.length > 0) out.push('');
  out.push(...block);
  if (rest.length > 0) {
    if (!_isBlank(rest[0])) out.push('');
    out.push(...rest);
  }
  return out.join('\n');
}

/** Removes value lines `[s, e]` and one adjacent blank line. */
function _removeLines(value: string, s: number, e: number): string {
  const lines = value.split('\n');
  let from = s;
  let to = e;
  if (to + 1 < lines.length && _isBlank(lines[to + 1])) {
    to++;
  } else if (from - 1 >= 0 && _isBlank(lines[from - 1])) {
    from--;
  }
  lines.splice(from, to - from + 1);
  const out = lines.join('\n');
  return out.trim().length === 0 ? '' : out;
}

function _quoted(lines: string[]): string[] {
  return lines.map((l) => (l.length === 0 ? '>' : `> ${l}`));
}

/** The lines of a comment block. */
export function formatCommentBlock(options: {
  id: string;
  text: string;
  author?: string | null;
}): string[] {
  const { id, text, author } = options;
  const t = text.split('\n');
  let head = `> ${_ARROW}${_VS16} **${id}**`;
  if (author != null && author.length > 0) head += ` (${author}):`;
  if (t[0].length > 0) head += ` ${t[0]}`;
  return [head, ..._quoted(t.slice(1))];
}

/** The lines of a question block. */
export function formatQuestionBlock(q: SpecQuestionDraft): string[] {
  const t = q.text.split('\n');
  const lines = [
    `> ${_QUESTION_OPEN} ${q.id}${_EM_DASH_SEP}${q.starred ? `${_STAR} ` : ''}` +
      `${q.topic}:** ${t[0]}`,
    ..._quoted(t.slice(1)),
    ...q.options.map((o) => `> - ${o}`),
  ];
  if (q.recommendation.length > 0 || q.assumption.length > 0) {
    lines.push('>');
    if (q.recommendation.length > 0) {
      lines.push(`> *Recommendation:* ${q.recommendation}`);
    }
    if (q.assumption.length > 0) {
      lines.push(`> *Working assumption until answered:* ${q.assumption}`);
    }
  }
  lines.push('>');
  lines.push(`> ${_ANSWER_LABEL}`);
  return lines;
}

/** Letters and digits (any script); punctuation and spaces are not. */
function _wordCharAt(s: string, i: number): boolean {
  if (i < 0 || i >= s.length) return false;
  const c = s[i];
  const u = c.charCodeAt(0);
  return c.toLowerCase() !== c.toUpperCase() || (u >= 0x30 && u <= 0x39);
}

function _wordChar(s: string): boolean {
  return s.length > 0 && _wordCharAt(s, s.length - 1);
}

function _isSpace(c: string): boolean {
  return c === ' ' || c === '\t';
}

function _trimEndSpaces(s: string): string {
  let k = s.length;
  while (k > 0 && _isSpace(s[k - 1])) k--;
  return s.substring(0, k);
}

function _trimStartSpaces(s: string): string {
  let k = 0;
  while (k < s.length && _isSpace(s[k])) k++;
  return s.substring(k);
}

/**
 * Applies a mark's replacement with the whitespace rules of SOM §11.9.3: never
 * join two words, never leave a double space or a space before punctuation, and
 * a mark that was a whole line leaves no blank line.
 */
function _replaceMark(value: string, m: _Mark, replacement0: string): string {
  let replacement = replacement0;
  let before = value.substring(0, m.start);
  let after = value.substring(m.end);
  if (replacement.length === 0) {
    const b0 = _trimEndSpaces(before);
    const a0 = _trimStartSpaces(after);
    const lineStart = b0.length === 0 || b0.endsWith('\n');
    const lineEnd = a0.length === 0 || a0.startsWith('\n');
    if (lineStart && lineEnd) {
      // The mark was the whole line: the line goes, and with it one of the
      // newlines around it; a blank line left doubled is merged.
      before = b0;
      after = a0;
      if (after.startsWith('\n')) {
        after = after.substring(1);
      } else if (before.endsWith('\n')) {
        before = before.substring(0, before.length - 1);
      }
      if ((before.length === 0 || before.endsWith('\n\n')) && after.startsWith('\n')) {
        after = after.substring(1);
      }
      if (after.length === 0) {
        while (before.endsWith('\n')) before = before.substring(0, before.length - 1);
      }
      return `${before}${after}`;
    }
    if (before.length > 0 && _isSpace(before[before.length - 1])) {
      if (after.length > 0 && _isSpace(after[0])) {
        after = _trimStartSpaces(after);
      } else if (after.length === 0 || after.startsWith('\n') || '.,;:!?)]}'.includes(after[0])) {
        before = _trimEndSpaces(before);
      }
    } else if (
      (before.length === 0 || before.endsWith('\n')) &&
      after.length > 0 &&
      _isSpace(after[0])
    ) {
      after = _trimStartSpaces(after);
    }
    return `${before}${after}`;
  }
  // Never join two words: a mark written flush against a word keeps a space
  // on that side.
  if (_wordChar(before) && _wordCharAt(replacement, 0)) {
    replacement = ` ${replacement}`;
  }
  if (
    _wordCharAt(replacement, replacement.length - 1) &&
    after.length > 0 &&
    _wordCharAt(after, 0)
  ) {
    replacement = `${replacement} `;
  }
  return `${before}${replacement}${after}`;
}

function _markReplacement(m: _Mark, accept: boolean): string {
  switch (m.kind) {
    case SpecMarkKind.INSERTION:
      return accept ? m.text : '';
    case SpecMarkKind.DELETION:
      return accept ? '' : m.text;
    case SpecMarkKind.SUBSTITUTION:
      return accept ? (m.newText as string) : m.text;
    case SpecMarkKind.HIGHLIGHT:
      return m.text;
    default:
      return '';
  }
}

/**
 * `value` with every inline mark accepted (`accept`) or rejected, and every
 * highlight and comment mark removed, by the rules of SOM §11.9.3. Marks in
 * code and malformed marks stay as written.
 */
export function applyInlineMarksText(value: string, options: { accept: boolean }): string {
  let v = value;
  const marks = _parse(v).marks;
  for (let k = marks.length - 1; k >= 0; k--) {
    v = _replaceMark(v, marks[k], _markReplacement(marks[k], options.accept));
  }
  return v;
}

/**
 * `value` without any comment block, question block or inline mark (every mark
 * accepted). Plain quotes and code stay.
 */
export function stripAnnotationsText(value: string): string {
  let v = value;
  // Blocks, from the last up, so earlier line numbers stay valid.
  for (;;) {
    const p = _parse(v);
    if (p.blocks.length === 0) break;
    const b = p.blocks[p.blocks.length - 1];
    v = _removeLines(v, b.start, b.end);
  }
  for (;;) {
    const p = _parse(v);
    if (p.marks.length === 0) break;
    const m = p.marks[p.marks.length - 1];
    v = _replaceMark(v, m, _markReplacement(m, true));
  }
  return v;
}

// ---------------------------------------------------------------------------
// Document level.
// ---------------------------------------------------------------------------

type _Value = [string, string | null, string];

/**
 * The annotations of a document, and the operations that edit them (SOM
 * §11.9). Values are visited in a fixed order — content paths sorted, then form
 * paths sorted with their field names sorted — so "document order" is the same
 * in every runtime.
 */
export class SpecReviewAnnotations {
  /** The document. */
  readonly doc: SpecDocument;

  /**
   * The document's id or name, written in front of a comment id cited outside
   * the document (`SBP` → `SBP C-12`); null for bare ids.
   */
  readonly qualifier: string | null;

  constructor(doc: SpecDocument, options: { qualifier?: string | null } = {}) {
    this.doc = doc;
    this.qualifier = options.qualifier ?? null;
  }

  /** Every value as `[path, field or null, text]`, in document order. */
  private _values(): _Value[] {
    const out: _Value[] = [];
    for (const path of Array.from(this.doc.contentPaths).sort()) {
      out.push([path, null, this.doc.content(path) ?? '']);
    }
    for (const path of Array.from(this.doc.formPaths).sort()) {
      for (const f of Array.from(this.doc.formFieldNames(path)).sort()) {
        out.push([path, f, this.doc.formField(path, f) ?? '']);
      }
    }
    return out;
  }

  private _get(path: string, field: string | null): string {
    return (field === null ? this.doc.content(path) : this.doc.formField(path, field)) ?? '';
  }

  private _set(path: string, field: string | null, value: string): void {
    if (field === null) {
      this.doc.setContent(path, value);
    } else {
      this.doc.setFormField(path, field, value);
    }
  }

  /** Every annotation, in document order. */
  list(): SpecReviewAnnotation[] {
    const out: SpecReviewAnnotation[] = [];
    for (const [path, field, text] of this._values()) {
      out.push(..._annotationsOf(_parse(text), path, field, this.qualifier));
    }
    return out;
  }

  /** The counts a report needs. */
  counts(): SpecReviewAnnotationCounts {
    let q = 0;
    let open = 0;
    let c = 0;
    let m = 0;
    for (const a of this.list()) {
      if (a.kind === SpecReviewAnnotationKind.QUESTION) {
        q++;
        if (a.open) open++;
      } else if (a.kind === SpecReviewAnnotationKind.COMMENT) {
        c++;
      } else {
        m++;
      }
    }
    return new SpecReviewAnnotationCounts({
      questions: q,
      openQuestions: open,
      answeredQuestions: q - open,
      comments: c,
      marks: m,
    });
  }

  private _highestCommentNumber(): number {
    let high = 0;
    for (const a of this.list()) {
      if (a.kind === SpecReviewAnnotationKind.COMMENT && a.id !== null) {
        const n = parseInt(a.id.substring(2), 10);
        if (n > high) high = n;
      }
    }
    return high;
  }

  /**
   * The id the next comment gets: `C-<n>`, n = the highest number in the
   * document (or `floor`, when higher) plus one. Writes nothing.
   */
  nextCommentId(options: { floor?: number } = {}): string {
    const floor = options.floor ?? 0;
    const high = this._highestCommentNumber();
    return `C-${(high > floor ? high : floor) + 1}`;
  }

  /**
   * Gives every comment without an id the next one, in document order, and
   * returns the ids assigned. Nothing else changes.
   */
  assignCommentIds(options: { floor?: number } = {}): string[] {
    const floor = options.floor ?? 0;
    const high = this._highestCommentNumber();
    let next = (high > floor ? high : floor) + 1;
    const assigned: string[] = [];
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      const bare = p.comments.filter((c) => c.id === null);
      if (bare.length === 0) continue;
      const lines = text.split('\n');
      for (const c of bare) {
        const id = `C-${next++}`;
        assigned.push(id);
        const raw = lines[c.block.start];
        const at = c.markerEnd;
        if (at < raw.length && raw[at] === ' ') {
          lines[c.block.start] = `${raw.substring(0, at + 1)}**${id}** ${raw.substring(at + 1)}`;
        } else if (at >= raw.length) {
          lines[c.block.start] = `${raw} **${id}**`;
        } else {
          lines[c.block.start] = `${raw.substring(0, at)} **${id}** ${raw.substring(at)}`;
        }
      }
      this._set(path, field, lines.join('\n'));
    }
    return assigned;
  }

  /**
   * Inserts a comment block after paragraph `afterParagraph` (0-based; -1: at
   * the start) of the value at `path` / `field`, and returns its id — `id`
   * when given, else the next free one.
   */
  insertComment(options: {
    path: string;
    field?: string | null;
    afterParagraph: number;
    text: string;
    author?: string | null;
    id?: string | null;
  }): string {
    const field = options.field ?? null;
    const cid = options.id ?? this.nextCommentId();
    const value = this._get(options.path, field);
    const end = this._paragraphLastLine(value, options.afterParagraph);
    this._set(
      options.path,
      field,
      _insertAfterLine(
        value,
        end,
        formatCommentBlock({ id: cid, text: options.text, author: options.author ?? null }),
      ),
    );
    return cid;
  }

  /**
   * Inserts a question block after paragraph `afterParagraph` (0-based; -1: at
   * the start) of the value at `path` / `field`.
   */
  insertQuestion(options: {
    path: string;
    field?: string | null;
    afterParagraph: number;
    question: SpecQuestionDraft;
  }): void {
    const field = options.field ?? null;
    const value = this._get(options.path, field);
    const end = this._paragraphLastLine(value, options.afterParagraph);
    this._set(options.path, field, _insertAfterLine(value, end, formatQuestionBlock(options.question)));
  }

  /** Inserts a question block directly after the comment `commentId`. */
  insertQuestionAfterComment(commentId: string, question: SpecQuestionDraft): void {
    const [path, field, text, c] = this._findComment(commentId);
    this._set(path, field, _insertAfterLine(text, c.block.end, formatQuestionBlock(question)));
  }

  /** Writes `answer` after the question's `**Answer:**` (empty: reopens it). */
  setAnswer(questionId: string, answer: string): void {
    const [path, field, text, , q] = this._findQuestion(questionId);
    const lines = text.split('\n');
    const a = answer.split('\n');
    const written =
      answer.length === 0
        ? [`> ${_ANSWER_LABEL}`]
        : [`> ${_ANSWER_LABEL} ${a[0]}`, ..._quoted(a.slice(1))];
    // The answer runs to the region's last non-empty line.
    let last = q.regionEnd;
    while (last > q.header && _inner(lines[last]).trim().length === 0) {
      last--;
    }
    if (q.answerLine !== null) {
      const from = q.answerLine;
      const to = last < from ? from : last;
      lines.splice(from, to - from + 1, ...written);
    } else {
      lines.splice(last + 1, 0, '>', ...written);
    }
    this._set(path, field, lines.join('\n'));
  }

  /** Replaces a comment's text; its marker, id and author stay as written. */
  editComment(commentId: string, text: string): void {
    const [path, field, value, c] = this._findComment(commentId);
    const lines = value.split('\n');
    const t = text.split('\n');
    const block = [`${c.headerPrefix}${t[0]}`.trimEnd(), ..._quoted(t.slice(1))];
    lines.splice(c.block.start, c.block.end - c.block.start + 1, ...block);
    this._set(path, field, lines.join('\n'));
  }

  /**
   * Removes one comment or question by id (a qualified comment id, `SBP C-12`,
   * is accepted). A question of a combined block takes only its own lines; the
   * block goes when its last question does.
   */
  resolve(id: string): void {
    const parts = id.split(' ');
    const bare = id.includes(' ') ? parts[parts.length - 1] : id;
    if (bare.startsWith('C-')) {
      const [path, field, value, c] = this._findComment(bare);
      this._set(path, field, _removeLines(value, c.block.start, c.block.end));
      return;
    }
    const [path, field, value, b, q] = this._findQuestion(bare);
    if ((b.questions ?? []).length === 1) {
      this._set(path, field, _removeLines(value, b.start, b.end));
      return;
    }
    const lines = value.split('\n');
    lines.splice(q.header, q.regionEnd - q.header + 1);
    // A last question leaves the separator `>` lines of the one before it.
    let end = b.end - (q.regionEnd - q.header + 1);
    while (end > b.start && _inner(lines[end]).trim().length === 0) {
      lines.splice(end, 1);
      end--;
    }
    this._set(path, field, lines.join('\n'));
  }

  /**
   * Accepts (`accept`) or rejects the inline mark `index` (0-based among the
   * marks of the value at `path` / `field`).
   */
  applyMark(options: {
    path: string;
    field?: string | null;
    index: number;
    accept?: boolean;
  }): void {
    const { path, index } = options;
    const field = options.field ?? null;
    const accept = options.accept ?? true;
    const value = this._get(path, field);
    const marks = _parse(value).marks;
    if (index < 0 || index >= marks.length) {
      throw new SpecReviewAnnotationError(
        `no inline mark ${index} at ${path}${field === null ? '' : ` / ${field}`}`,
      );
    }
    const m = marks[index];
    this._set(path, field, _replaceMark(value, m, _markReplacement(m, accept)));
  }

  /**
   * The revision the mark ids are stable for: FNV-1a 64-bit over the UTF-8 of
   * every value in document order (path, NUL, field or empty, NUL, text, NUL),
   * as 16 lower-case hex digits. Any change to a value changes it.
   */
  revision(): string {
    const prime = BigInt('0x100000001b3');
    const mask = BigInt('0xffffffffffffffff');
    let h = BigInt('0xcbf29ce484222325');
    const add = (s: string): void => {
      for (const b of Buffer.from(s, 'utf8')) {
        h = ((h ^ BigInt(b)) * prime) & mask;
      }
      h = (h * prime) & mask;
    };
    for (const [path, field, text] of this._values()) {
      add(path);
      add(field ?? '');
      add(text);
    }
    return h.toString(16).padStart(16, '0');
  }

  private static _under(path: string, under: string | null): boolean {
    return under === null || path === under || path.startsWith(`${under}/`);
  }

  /** Every inline mark of the document, or of the subtree at `path`, in document order. */
  listMarks(options: { path?: string | null } = {}): SpecMarkEntry[] {
    const filter = options.path ?? null;
    const out: SpecMarkEntry[] = [];
    let n = 0;
    for (const [vpath, field, text] of this._values()) {
      const p = _parse(text);
      const paras = _paragraphs(p.lines, p.code);
      for (const m of p.marks) {
        const id = `M-${++n}`;
        if (!SpecReviewAnnotations._under(vpath, filter)) continue;
        const para = paras.find((r) => r[0] <= m.line && m.line <= r[1]) ?? [m.line, m.line];
        out.push(
          new SpecMarkEntry({
            id,
            path: vpath,
            field,
            line: m.line,
            markKind: m.kind,
            oldText: _markReplacement(m, false),
            newText: _markReplacement(m, true),
            comment: m.comment,
            markup: text.substring(m.start, m.end),
            context: p.lines.slice(para[0], para[1] + 1).join('\n'),
          }),
        );
      }
    }
    return out;
  }

  /** Applies `decide(id)` to every mark in the subtree `under` (null: all), one write per value. */
  private _applyMarks(
    decide: (id: string) => SpecMarkDecisionValue | null | undefined,
    under: string | null = null,
  ): SpecMarkReport {
    const applied: SpecMarkOutcome[] = [];
    const issues: SpecMarkIssue[] = [];
    let n = 0;
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      const ids = p.marks.map(() => `M-${++n}`);
      if (!SpecReviewAnnotations._under(path, under)) continue;
      for (const [line, issue] of p.markIssues) {
        issues.push(new SpecMarkIssue({ path, field, line, issue }));
      }
      let v = text;
      const outcomes: SpecMarkOutcome[] = [];
      for (let k = p.marks.length - 1; k >= 0; k--) {
        const d = decide(ids[k]);
        if (d == null || d === SpecMarkDecision.LEAVE) continue;
        const m = p.marks[k];
        const repl = _markReplacement(m, d === SpecMarkDecision.ACCEPT);
        outcomes.unshift(
          new SpecMarkOutcome({
            id: ids[k],
            path,
            field,
            line: m.line,
            markKind: m.kind,
            decision: d,
            markup: text.substring(m.start, m.end),
            result: repl,
          }),
        );
        v = _replaceMark(v, m, repl);
      }
      if (v !== text) this._set(path, field, v);
      applied.push(...outcomes);
    }
    return new SpecMarkReport({ applied, malformed: issues });
  }

  /**
   * Applies one decision per named mark in one write. Refused — nothing
   * changes — when the document is no longer at `revision`, or when a decision
   * names a mark that does not exist. Marks not named, and marks decided
   * `leave`, stay.
   */
  decideMarks(
    decisions: Record<string, SpecMarkDecisionValue> | Map<string, SpecMarkDecisionValue>,
    options: { revision: string },
  ): SpecMarkReport {
    const map =
      decisions instanceof Map
        ? decisions
        : new Map<string, SpecMarkDecisionValue>(Object.entries(decisions));
    const current = this.revision();
    if (options.revision !== current) {
      throw new SpecReviewAnnotationError(
        `the document changed since revision ${options.revision} (now ${current}); ` +
          'list the marks again',
      );
    }
    const known = new Set(this.listMarks().map((m) => m.id));
    const values: string[] = Object.values(SpecMarkDecision);
    for (const [id, d] of map) {
      if (!known.has(id)) {
        throw new SpecReviewAnnotationError(`no inline mark ${id} in the document`);
      }
      if (!values.includes(d)) {
        throw new SpecReviewAnnotationError(`unknown mark decision ${d} for ${id}`);
      }
    }
    return this._applyMarks((id) => map.get(id));
  }

  /** Accepts every inline mark under `path` (null: the whole document). */
  acceptAllMarks(options: { path?: string | null } = {}): SpecMarkReport {
    return this._applyMarks(() => SpecMarkDecision.ACCEPT, options.path ?? null);
  }

  /** Rejects every inline mark under `path` (null: the whole document). */
  rejectAllMarks(options: { path?: string | null } = {}): SpecMarkReport {
    return this._applyMarks(() => SpecMarkDecision.REJECT, options.path ?? null);
  }

  /**
   * Removes every annotation and writes the result back: every inline mark
   * accepted, every comment and question block removed. Malformed marks stay
   * and are reported.
   */
  removeAllAnnotations(): SpecMarkReport {
    const report = this.acceptAllMarks();
    for (const [path, field, text] of this._values()) {
      let v = text;
      for (;;) {
        const p = _parse(v);
        if (p.blocks.length === 0) break;
        const b = p.blocks[p.blocks.length - 1];
        v = _removeLines(v, b.start, b.end);
      }
      if (v !== text) this._set(path, field, v);
    }
    return report;
  }

  /**
   * A copy of the document without any annotation, for reading. The document
   * itself is unchanged.
   */
  stripped(): SpecDocument {
    const copy = new SpecDocument();
    copy.loadJson(JSON.parse(JSON.stringify(this.doc.toJson())));
    for (const [path, field, text] of this._values()) {
      const clean = stripAnnotationsText(text);
      if (clean === text) continue;
      if (field === null) {
        copy.setContent(path, clean);
      } else {
        copy.setFormField(path, field, clean);
      }
    }
    return copy;
  }

  private _paragraphLastLine(value: string, afterParagraph: number): number {
    if (afterParagraph < 0) return -1;
    const lines = value.split('\n');
    const paras = _paragraphs(lines, _codeLines(lines));
    if (value.length === 0 || afterParagraph >= paras.length) {
      throw new SpecReviewAnnotationError(
        `the value has ${value.length === 0 ? 0 : paras.length} paragraph(s); ` +
          `there is no paragraph ${afterParagraph}`,
      );
    }
    return paras[afterParagraph][1];
  }

  private _findComment(id: string): [string, string | null, string, _Comment] {
    for (const [path, field, text] of this._values()) {
      for (const c of _parse(text).comments) {
        if (c.id === id) return [path, field, text, c];
      }
    }
    throw new SpecReviewAnnotationError(`no comment ${id} in the document`);
  }

  private _findQuestion(id: string): [string, string | null, string, _Block, _Question] {
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      for (const b of p.blocks) {
        for (const q of b.questions ?? []) {
          if (q.id === id) return [path, field, text, b, q];
        }
      }
    }
    throw new SpecReviewAnnotationError(`no question ${id} in the document`);
  }

  /** The instance-tier findings on annotations (SOM §11.9.5), ordered by path. */
  validate(): SpecValidationError[] {
    const errors: SpecValidationError[] = [];
    const seen = new Set<string>();
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      const where = field === null ? path : `${path} / ${field}`;
      for (const m of p.malformed) {
        errors.push(
          new SpecValidationError(path, SpecValidationCode.ANNOTATION_MALFORMED, `${where}, ${m}`),
        );
      }
      if (field !== null) {
        for (const b of p.blocks) {
          errors.push(
            new SpecValidationError(
              path,
              SpecValidationCode.ANNOTATION_MISPLACED,
              `${where}, line ${b.start}: a ${b.kind} block sits in a form field ` +
                "value; it belongs in the form's preamble, above the first field " +
                '(SOM §11.9.4)',
            ),
          );
        }
      }
      const ids: string[] = [];
      for (const c of p.comments) {
        if (c.id !== null) ids.push(c.id);
      }
      for (const b of p.blocks) {
        for (const q of b.questions ?? []) ids.push(q.id);
      }
      for (const id of ids) {
        if (seen.has(id)) {
          errors.push(
            new SpecValidationError(
              path,
              SpecValidationCode.DUPLICATE_ANNOTATION_ID,
              `${where}: ${id} is used more than once in the document`,
            ),
          );
        } else {
          seen.add(id);
        }
      }
    }
    // Array.prototype.sort is stable: a path's findings keep their order.
    return errors.sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0));
  }
}
