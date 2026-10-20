'use strict';

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

/** The three kinds of annotation (SOM §11.9). */
const SpecReviewAnnotationKind = Object.freeze({
  /** A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`. */
  COMMENT: 'comment',
  /** One question of a question block, `> **❓ BQ-81 — topic:** …`. */
  QUESTION: 'question',
  /** A CriticMarkup inline mark. */
  MARK: 'mark',
});

/** The five CriticMarkup inline marks (SOM §11.9.3). */
const SpecMarkKind = Object.freeze({
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
});

/** One annotation, located by the value that holds it. */
class SpecReviewAnnotation {
  /**
   * @param {{kind: string, path: string, field?: string|null, line: number,
   *   id?: string|null, qualifiedId?: string|null, author?: string|null,
   *   text?: string, context?: string, topic?: string|null, starred?: boolean,
   *   combined?: boolean, answer?: string, markKind?: string|null,
   *   newText?: string|null, comment?: string|null}} options
   */
  constructor({
    kind,
    path,
    field = null,
    line,
    id = null,
    qualifiedId = null,
    author = null,
    text = '',
    context = '',
    topic = null,
    starred = false,
    combined = false,
    answer = '',
    markKind = null,
    newText = null,
    comment = null,
  }) {
    /** The kind (a {@link SpecReviewAnnotationKind} value). */
    this.kind = kind;
    /** The document path of the value: a content path, or a form path when `field` is set. */
    this.path = path;
    /** The form field whose value holds the annotation; null for content. */
    this.field = field;
    /** The 0-based line within the value where the annotation starts (a question: its header line). */
    this.line = line;
    /** The comment id (`C-12`) or question id (`BQ-81`); null for a comment without an id and for a mark. */
    this.id = id;
    /** A comment's id with the document qualifier in front (`SBP C-12`). */
    this.qualifiedId = qualifiedId;
    /** A comment's author; null when none is written. */
    this.author = author;
    /** A comment's, question's or mark's text. */
    this.text = text;
    /** A comment's context: the paragraph before the block, verbatim. */
    this.context = context;
    /** A question's topic (in a combined block: the field it asks about). */
    this.topic = topic;
    /** Whether a question carries `★` before its topic. */
    this.starred = starred;
    /** Whether a question is part of a combined block. */
    this.combined = combined;
    /** A question's answer, trimmed; empty when open. */
    this.answer = answer;
    /** A mark's kind (a {@link SpecMarkKind} value). */
    this.markKind = markKind;
    /** A substitution's new text. */
    this.newText = newText;
    /** The comment of a comment mark, or of a highlight followed by one. */
    this.comment = comment;
  }

  /** Whether a question is still open (no answer written). */
  get open() {
    return this.kind === SpecReviewAnnotationKind.QUESTION && this.answer.length === 0;
  }

  /** The canonical JSON form the conformance corpus pins. */
  toJson() {
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
class SpecReviewAnnotationCounts {
  constructor({
    questions = 0,
    openQuestions = 0,
    answeredQuestions = 0,
    comments = 0,
    marks = 0,
  } = {}) {
    this.questions = questions;
    this.openQuestions = openQuestions;
    this.answeredQuestions = answeredQuestions;
    this.comments = comments;
    this.marks = marks;
  }

  /** The canonical JSON form. */
  toJson() {
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
class SpecQuestionDraft {
  /**
   * @param {{id: string, topic: string, text: string, options?: string[],
   *   recommendation?: string, assumption?: string, starred?: boolean}} options
   */
  constructor({
    id,
    topic,
    text,
    options = [],
    recommendation = '',
    assumption = '',
    starred = false,
  }) {
    /** The question id (`BQ-90`). */
    this.id = id;
    /** The topic. */
    this.topic = topic;
    /** The question text; may span lines. */
    this.text = text;
    /** Option lines, written as `- <option>`. */
    this.options = options;
    /** The recommendation, or empty. */
    this.recommendation = recommendation;
    /** The working assumption, or empty. */
    this.assumption = assumption;
    /** Whether the question carries `★`. */
    this.starred = starred;
  }

  /** Reads a draft from its corpus JSON form. */
  static fromJson(j) {
    return new SpecQuestionDraft({
      id: j.id,
      topic: j.topic,
      text: j.text,
      options: (j.options || []).map((o) => `${o}`),
      recommendation: j.recommendation ?? '',
      assumption: j.assumption ?? '',
      starred: j.starred ?? false,
    });
  }
}

/**
 * Thrown when an operation names an annotation, value or paragraph that does
 * not exist. Nothing is changed before it is thrown.
 */
class SpecReviewAnnotationError extends Error {
  constructor(message) {
    super(message);
    this.name = 'SpecReviewAnnotationError';
  }

  toString() {
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

function _lstrip(s) {
  let i = 0;
  while (i < s.length && (s[i] === ' ' || s[i] === '\t')) {
    i++;
  }
  return s.substring(i);
}

function _isBlank(s) {
  return s.trim().length === 0;
}

/** The fenced-code flag of every line. */
function _codeLines(lines) {
  const code = new Array(lines.length).fill(false);
  let fenceChar = null;
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

function _isQuoteLine(line) {
  return _lstrip(line).startsWith('>');
}

/** The line inside the quote: after `>` and one following space. */
function _inner(line) {
  const t = _lstrip(line);
  let s = t.substring(1);
  if (s.startsWith(' ')) s = s.substring(1);
  return s;
}

/**
 * Everything one value holds. A block is `{start, end, kind}` (lines inclusive);
 * a comment block also carries `comment`, a question block `questions` and
 * `combined`.
 */
function _parse(value) {
  const lines = value.split('\n');
  const code = _codeLines(lines);
  const p = { lines, code, blocks: [], comments: [], marks: [], malformed: [] };

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
      const b = { start: s, end: e, kind: SpecReviewAnnotationKind.COMMENT };
      p.blocks.push(b);
      const c = _parseComment(p, b);
      b.comment = c;
      p.comments.push(c);
    } else if (first.startsWith(_QUESTION_OPEN)) {
      const b = { start: s, end: e, kind: SpecReviewAnnotationKind.QUESTION };
      p.blocks.push(b);
      _parseQuestions(p, b);
    }
    i = e + 1;
  }

  _parseMarks(p);
  return p;
}

function _context(p, blockStart) {
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

function _parseComment(p, b) {
  const raw0 = p.lines[b.start];
  let rest = _inner(raw0).substring(_ARROW.length);
  if (rest.startsWith(_VS16)) rest = rest.substring(_VS16.length);
  const markerEnd = raw0.length - rest.length;
  rest = _lstrip(rest);
  let id = null;
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
  let author = null;
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

/** Parses a question header's remainder after `**❓ `; null when malformed. */
function _parseHeader(inner) {
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

function _parseQuestions(p, b) {
  const inner = [];
  for (let k = b.start; k <= b.end; k++) inner.push(_inner(p.lines[k]));
  b.combined = inner[0].startsWith(_COMBINED_OPENER);
  const headers = []; // [k, header], ascending k
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
  const list = [];
  for (let q = 0; q < headers.length; q++) {
    const [k, h] = headers[q];
    const regionEnd = q + 1 < headers.length ? headers[q + 1][0] - 1 : inner.length - 1;
    let answer = null;
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
const _CLOSERS = {
  '{>>': '<<}',
  '{==': '==}',
  '{++': '++}',
  '{--': '--}',
  '{~~': '~~}',
};

function _hasOpener(s) {
  return _OPENERS.some((o) => s.includes(o));
}

/** The offset of the first blank line's start after `from` (the paragraph end), or the text length. */
function _paragraphEnd(text, from) {
  let i = text.indexOf('\n', from);
  while (i >= 0) {
    const next = text.indexOf('\n', i + 1);
    const line = text.substring(i + 1, next < 0 ? text.length : next);
    if (line.trim().length === 0) return i;
    i = next;
  }
  return text.length;
}

function _parseMarks(p) {
  const lineStart = [];
  let off = 0;
  for (const l of p.lines) {
    lineStart.push(off);
    off += l.length + 1;
  }
  const value = p.lines.join('\n');
  const lineOf = (offset) => {
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

function _scanSegment(p, seg, base, lineOf) {
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
      i += 3;
      continue;
    }
    const inner = seg.substring(i + 3, close);
    if (_hasOpener(inner)) {
      p.malformed.push(`line ${line}: inline marks do not nest (SOM §11.9.3)`);
      i = close + 3;
      continue;
    }
    let end = close + 3;
    const mark = (kind, text, newText, comment) => ({
      start: base + i,
      end: base + end,
      line,
      kind,
      text,
      newText,
      comment,
    });
    switch (opener) {
      case '{>>':
        p.marks.push(mark(SpecMarkKind.COMMENT, '', null, inner.trim()));
        break;
      case '{==': {
        let comment = null;
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
function _annotationsOf(p, path, field, qualifier) {
  const out = []; // [line, group, seq, annotation]
  let seq = 0;
  for (const b of p.blocks) {
    if (b.kind === SpecReviewAnnotationKind.COMMENT) {
      const c = b.comment;
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
          qualifiedId: qualifier != null && c.id != null ? `${qualifier} ${c.id}` : null,
          author: c.author,
          text: c.text,
          context: c.context,
        }),
      ]);
    } else {
      for (const q of b.questions) {
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
            combined: b.combined,
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
function _paragraphs(lines, code) {
  const out = [];
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
function _insertAfterLine(value, end, block) {
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
function _removeLines(value, s, e) {
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

function _quoted(lines) {
  return lines.map((l) => (l.length === 0 ? '>' : `> ${l}`));
}

/**
 * The lines of a comment block.
 *
 * @param {{id: string, text: string, author?: string|null}} options
 * @returns {string[]}
 */
function formatCommentBlock({ id, text, author = null }) {
  const t = text.split('\n');
  let head = `> ${_ARROW}${_VS16} **${id}**`;
  if (author != null && author.length > 0) head += ` (${author}):`;
  if (t[0].length > 0) head += ` ${t[0]}`;
  return [head, ..._quoted(t.slice(1))];
}

/**
 * The lines of a question block.
 *
 * @param {SpecQuestionDraft} q
 * @returns {string[]}
 */
function formatQuestionBlock(q) {
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
function _wordCharAt(s, i) {
  if (i < 0 || i >= s.length) return false;
  const c = s[i];
  const u = c.charCodeAt(0);
  return c.toLowerCase() !== c.toUpperCase() || (u >= 0x30 && u <= 0x39);
}

function _wordChar(s) {
  return s.length > 0 && _wordCharAt(s, s.length - 1);
}

/** Applies a mark's replacement and tidies the one space a removal leaves. */
function _replaceMark(value, m, replacement0) {
  let replacement = replacement0;
  let before = value.substring(0, m.start);
  let after = value.substring(m.end);
  if (replacement.length === 0) {
    if (
      before.endsWith(' ') &&
      (after.length === 0 ||
        after.startsWith(' ') ||
        after.startsWith('\n') ||
        '.,;:!?)'.includes(after[0]))
    ) {
      before = before.substring(0, before.length - 1);
    } else if ((before.length === 0 || before.endsWith('\n')) && after.startsWith(' ')) {
      after = after.substring(1);
    }
  }
  if (replacement.length > 0) {
    // Never join two words: a mark written flush against a word keeps a
    // space on that side.
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
  }
  return `${before}${replacement}${after}`;
}

function _markReplacement(m, accept) {
  switch (m.kind) {
    case SpecMarkKind.INSERTION:
      return accept ? m.text : '';
    case SpecMarkKind.DELETION:
      return accept ? '' : m.text;
    case SpecMarkKind.SUBSTITUTION:
      return accept ? m.newText : m.text;
    case SpecMarkKind.HIGHLIGHT:
      return m.text;
    default:
      return '';
  }
}

/**
 * `value` without any comment block, question block or inline mark (every mark
 * accepted). Plain quotes and code stay.
 *
 * @param {string} value
 * @returns {string}
 */
function stripAnnotationsText(value) {
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

/**
 * The annotations of a document, and the operations that edit them (SOM
 * §11.9). Values are visited in a fixed order — content paths sorted, then form
 * paths sorted with their field names sorted — so "document order" is the same
 * in every runtime.
 */
class SpecReviewAnnotations {
  /**
   * @param {import('./spec_document').SpecDocument} doc
   * @param {{qualifier?: string|null}} [options] `qualifier`: the document's id
   *   or name, written in front of a comment id cited outside the document
   *   (`SBP` → `SBP C-12`); null for bare ids.
   */
  constructor(doc, { qualifier = null } = {}) {
    /** The document. */
    this.doc = doc;
    /** The qualifier written in front of a cited comment id, or null. */
    this.qualifier = qualifier;
  }

  /** Every value as `[path, field or null, text]`, in document order. */
  _values() {
    const out = [];
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

  _get(path, field) {
    return (field == null ? this.doc.content(path) : this.doc.formField(path, field)) ?? '';
  }

  _set(path, field, value) {
    if (field == null) {
      this.doc.setContent(path, value);
    } else {
      this.doc.setFormField(path, field, value);
    }
  }

  /** Every annotation, in document order. @returns {SpecReviewAnnotation[]} */
  list() {
    const out = [];
    for (const [path, field, text] of this._values()) {
      out.push(..._annotationsOf(_parse(text), path, field, this.qualifier));
    }
    return out;
  }

  /** The counts a report needs. @returns {SpecReviewAnnotationCounts} */
  counts() {
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

  _highestCommentNumber() {
    let high = 0;
    for (const a of this.list()) {
      if (a.kind === SpecReviewAnnotationKind.COMMENT && a.id != null) {
        const n = parseInt(a.id.substring(2), 10);
        if (n > high) high = n;
      }
    }
    return high;
  }

  /**
   * The id the next comment gets: `C-<n>`, n = the highest number in the
   * document (or `floor`, when higher) plus one. Writes nothing.
   *
   * @param {{floor?: number}} [options]
   * @returns {string}
   */
  nextCommentId({ floor = 0 } = {}) {
    const high = this._highestCommentNumber();
    return `C-${(high > floor ? high : floor) + 1}`;
  }

  /**
   * Gives every comment without an id the next one, in document order, and
   * returns the ids assigned. Nothing else changes.
   *
   * @param {{floor?: number}} [options]
   * @returns {string[]}
   */
  assignCommentIds({ floor = 0 } = {}) {
    const high = this._highestCommentNumber();
    let next = (high > floor ? high : floor) + 1;
    const assigned = [];
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      const bare = p.comments.filter((c) => c.id == null);
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
   *
   * @param {{path: string, field?: string|null, afterParagraph: number,
   *   text: string, author?: string|null, id?: string|null}} options
   * @returns {string}
   */
  insertComment({ path, field = null, afterParagraph, text, author = null, id = null }) {
    const cid = id ?? this.nextCommentId();
    const value = this._get(path, field);
    const end = this._paragraphLastLine(value, afterParagraph);
    this._set(
      path,
      field,
      _insertAfterLine(value, end, formatCommentBlock({ id: cid, text, author })),
    );
    return cid;
  }

  /**
   * Inserts a question block after paragraph `afterParagraph` (0-based; -1: at
   * the start) of the value at `path` / `field`.
   *
   * @param {{path: string, field?: string|null, afterParagraph: number,
   *   question: SpecQuestionDraft}} options
   */
  insertQuestion({ path, field = null, afterParagraph, question }) {
    const value = this._get(path, field);
    const end = this._paragraphLastLine(value, afterParagraph);
    this._set(path, field, _insertAfterLine(value, end, formatQuestionBlock(question)));
  }

  /** Inserts a question block directly after the comment `commentId`. */
  insertQuestionAfterComment(commentId, question) {
    const [path, field, text, c] = this._findComment(commentId);
    this._set(path, field, _insertAfterLine(text, c.block.end, formatQuestionBlock(question)));
  }

  /** Writes `answer` after the question's `**Answer:**` (empty: reopens it). */
  setAnswer(questionId, answer) {
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
  editComment(commentId, text) {
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
  resolve(id) {
    const bare = id.includes(' ') ? id.split(' ').pop() : id;
    if (bare.startsWith('C-')) {
      const [path, field, value, c] = this._findComment(bare);
      this._set(path, field, _removeLines(value, c.block.start, c.block.end));
      return;
    }
    const [path, field, value, b, q] = this._findQuestion(bare);
    if (b.questions.length === 1) {
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
   *
   * @param {{path: string, field?: string|null, index: number, accept?: boolean}} options
   */
  applyMark({ path, field = null, index, accept = true }) {
    const value = this._get(path, field);
    const marks = _parse(value).marks;
    if (index < 0 || index >= marks.length) {
      throw new SpecReviewAnnotationError(
        `no inline mark ${index} at ${path}${field == null ? '' : ` / ${field}`}`,
      );
    }
    const m = marks[index];
    this._set(path, field, _replaceMark(value, m, _markReplacement(m, accept)));
  }

  /**
   * A copy of the document without any annotation, for reading. The document
   * itself is unchanged.
   *
   * @returns {import('./spec_document').SpecDocument}
   */
  stripped() {
    const { SpecDocument } = require('./spec_document');
    const copy = new SpecDocument();
    copy.loadJson(JSON.parse(JSON.stringify(this.doc.toJson())));
    for (const [path, field, text] of this._values()) {
      const clean = stripAnnotationsText(text);
      if (clean === text) continue;
      if (field == null) {
        copy.setContent(path, clean);
      } else {
        copy.setFormField(path, field, clean);
      }
    }
    return copy;
  }

  _paragraphLastLine(value, afterParagraph) {
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

  _findComment(id) {
    for (const [path, field, text] of this._values()) {
      for (const c of _parse(text).comments) {
        if (c.id === id) return [path, field, text, c];
      }
    }
    throw new SpecReviewAnnotationError(`no comment ${id} in the document`);
  }

  _findQuestion(id) {
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      for (const b of p.blocks) {
        for (const q of b.questions || []) {
          if (q.id === id) return [path, field, text, b, q];
        }
      }
    }
    throw new SpecReviewAnnotationError(`no question ${id} in the document`);
  }

  /**
   * The instance-tier findings on annotations (SOM §11.9.5), ordered by path.
   *
   * @returns {import('./spec_validator').SpecValidationError[]}
   */
  validate() {
    const { SpecValidationCode, SpecValidationError } = require('./spec_validator');
    const errors = [];
    const seen = new Set();
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      const where = field == null ? path : `${path} / ${field}`;
      for (const m of p.malformed) {
        errors.push(
          new SpecValidationError(path, SpecValidationCode.ANNOTATION_MALFORMED, `${where}, ${m}`),
        );
      }
      if (field != null) {
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
      const ids = [];
      for (const c of p.comments) {
        if (c.id != null) ids.push(c.id);
      }
      for (const b of p.blocks) {
        for (const q of b.questions || []) ids.push(q.id);
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

module.exports = {
  SpecReviewAnnotationKind,
  SpecMarkKind,
  SpecReviewAnnotation,
  SpecReviewAnnotationCounts,
  SpecQuestionDraft,
  SpecReviewAnnotationError,
  SpecReviewAnnotations,
  formatCommentBlock,
  formatQuestionBlock,
  stripAnnotationsText,
};
