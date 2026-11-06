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

/**
 * The kinds of annotation (SOM §11.9): the three of §11.9.1–11.9.3 and the
 * conflict block a team review adds (§11.9.8).
 */
const SpecReviewAnnotationKind = Object.freeze({
  /** A reviewer's comment block, `> ⬆️ **C-12** (Alexis): …`. */
  COMMENT: 'comment',
  /** One question of a question block, `> **❓ BQ-81 — topic:** …`. */
  QUESTION: 'question',
  /** A CriticMarkup inline mark. */
  MARK: 'mark',
  /** A conflict block, `> ⚖️ **X-3 — Conflicting changes:** …` (SOM §11.9.8). */
  CONFLICT: 'conflict',
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

/**
 * One paragraph of a value (SOM §11.9.1, "Paragraphs"): a run of non-blank
 * lines, where a blank line inside fenced code does not end the run. Its
 * `index` is what `afterParagraph` of the inserts takes.
 */
class SpecParagraph {
  /**
   * @param {{index: number, startLine: number, endLine: number, text: string,
   *   annotation?: string|null}} options
   */
  constructor({ index, startLine, endLine, text, annotation = null }) {
    /** The 0-based position among the value's paragraphs. */
    this.index = index;
    /** The 0-based first line within the value. */
    this.startLine = startLine;
    /** The 0-based last line within the value (inclusive). */
    this.endLine = endLine;
    /** The paragraph's lines, verbatim, joined with `\n`. */
    this.text = text;
    /**
     * `comment`, `question` or `conflict` when the paragraph opens with an
     * annotation block of that kind, else null.
     */
    this.annotation = annotation;
  }

  /** The canonical JSON form. */
  toJson() {
    return {
      index: this.index,
      startLine: this.startLine,
      endLine: this.endLine,
      text: this.text,
      annotation: this.annotation,
    };
  }
}

/**
 * One option of a question (SOM §11.9.2): `- (a) text`, or `- **(b)** text`
 * for the recommended one.
 */
class SpecQuestionOption {
  /**
   * @param {string} letter
   * @param {string} text
   * @param {{bold?: boolean}} [options]
   */
  constructor(letter, text, { bold = false } = {}) {
    /** The lowercase letter. */
    this.letter = letter;
    /** The option's text, its continuation lines joined with one space. */
    this.text = text;
    /** Whether the option is written bold — the recommended one. */
    this.bold = bold;
  }

  /** The canonical JSON form. */
  toJson() {
    return { letter: this.letter, text: this.text, bold: this.bold };
  }
}

/*
 * The JSON options of the listing classes: `{team: true}` gives the extended
 * form `team_annotation_cases.json` pins (SOM §11.9.8): marks with `authors`
 * and `votes`, questions with `unresolved` and `answers`, the counts with the
 * team counts, a removal report with its `conflicts`. Without it the form is
 * the one of §11.9.1–11.9.7, which the older case files pin.
 */

/** One reviewer's vote on a mark someone else proposed (SOM §11.9.8). */
class SpecMarkVote {
  /**
   * @param {string} member
   * @param {'accept'|'reject'} vote
   */
  constructor(member, vote) {
    /** The voter's member id. */
    this.member = member;
    /** `accept` (`+id`) or `reject` (`-id`). */
    this.vote = vote;
  }

  /** The canonical JSON form. */
  toJson() {
    return { member: this.member, vote: this.vote };
  }
}

/** One line of individual answers, `**Answer (alice, bob):** (a)` (SOM §11.9.8). */
class SpecIndividualAnswer {
  /**
   * @param {string[]} members
   * @param {string} answer
   */
  constructor(members, answer) {
    /** The members who gave this answer, in the order written. */
    this.members = members;
    /** The answer, trimmed. */
    this.answer = answer;
    /** The letter the answer starts with (`(a)` or `**(a)**`), or null. */
    this.answerLetter = _leadingLetter(answer);
  }

  /** The canonical JSON form. */
  toJson() {
    return { members: this.members, answer: this.answer, answerLetter: this.answerLetter };
  }
}

/** One lettered alternative of a conflict block, `- (a) **alice:** text`. */
class SpecConflictAlternative {
  /**
   * @param {string} letter
   * @param {string[]} members
   * @param {string} text
   */
  constructor(letter, members, text) {
    /** The lowercase letter. */
    this.letter = letter;
    /** The members who made this change. */
    this.members = members;
    /** The alternative's text; its continuation lines kept as lines. */
    this.text = text;
  }

  /** The canonical JSON form. */
  toJson() {
    return { letter: this.letter, members: this.members, text: this.text };
  }
}

/** One annotation, located by the value that holds it. */
class SpecReviewAnnotation {
  /**
   * @param {{kind: string, path: string, field?: string|null, line: number,
   *   id?: string|null, qualifiedId?: string|null, author?: string|null,
   *   text?: string, context?: string, topic?: string|null, starred?: boolean,
   *   combined?: boolean, answer?: string, options?: SpecQuestionOption[],
   *   recommended?: string|null, markKind?: string|null,
   *   newText?: string|null, comment?: string|null, authors?: string[],
   *   votes?: SpecMarkVote[], answers?: SpecIndividualAnswer[], base?: string,
   *   alternatives?: SpecConflictAlternative[]}} options
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
    options = [],
    recommended = null,
    markKind = null,
    newText = null,
    comment = null,
    authors = [],
    votes = [],
    answers = [],
    base = '',
    alternatives = [],
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
    /** A question's options, in order (empty when it states none). */
    this.options = options;
    /**
     * A question's recommended letter: the bold option, else the option that
     * says "recommended", else the letter of a `*Recommendation:*` line.
     */
    this.recommended = recommended;
    /** A mark's kind (a {@link SpecMarkKind} value). */
    this.markKind = markKind;
    /** A substitution's new text. */
    this.newText = newText;
    /** The comment of a comment mark, or of a highlight followed by one. */
    this.comment = comment;
    /** A mark's authors from its attribution token; empty without one. */
    this.authors = authors;
    /** A mark's votes from its attribution token; empty without one. */
    this.votes = votes;
    /** A question's individual answers, in the order written. */
    this.answers = answers;
    /** A conflict's `(base)` text. */
    this.base = base;
    /** A conflict's lettered alternatives. */
    this.alternatives = alternatives;
  }

  /**
   * Whether a question is still open (no team answer written), or a conflict
   * (no decision written). For a conflict, `answer` holds the decision.
   */
  get open() {
    return (
      (this.kind === SpecReviewAnnotationKind.QUESTION ||
        this.kind === SpecReviewAnnotationKind.CONFLICT) &&
      this.answer.length === 0
    );
  }

  /**
   * Whether a question's team answer or a conflict's decision begins with
   * `open:` — answered for a gate, but handed back (SOM §11.9.8).
   */
  get unresolved() {
    return _isUnresolved(this.answer);
  }

  /**
   * The letter a question's team answer starts with (`(b)` or `**(b)**`), or
   * null; null too for an unresolved answer.
   */
  get answerLetter() {
    return this.kind === SpecReviewAnnotationKind.QUESTION && !this.unresolved
      ? _leadingLetter(this.answer)
      : null;
  }

  /** A conflict's decision letter: `a`…, `base`, or null for rewritten text or none. */
  get decisionLetter() {
    return this.kind === SpecReviewAnnotationKind.CONFLICT ? _decisionLetter(this.answer) : null;
  }

  /**
   * The canonical JSON form the conformance corpus pins; `{team: true}` adds
   * the members of SOM §11.9.8.
   */
  toJson({ team = false } = {}) {
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
          ...(team ? { unresolved: this.unresolved } : {}),
          options: this.options.map((o) => o.toJson()),
          recommended: this.recommended,
          answerLetter: this.answerLetter,
          ...(team ? { answers: this.answers.map((a) => a.toJson()) } : {}),
        };
      case SpecReviewAnnotationKind.CONFLICT:
        return {
          kind: 'conflict',
          path: this.path,
          field: this.field,
          line: this.line,
          id: this.id,
          qualifiedId: this.qualifiedId,
          topic: this.topic,
          text: this.text,
          base: this.base,
          alternatives: this.alternatives.map((a) => a.toJson()),
          decision: this.answer,
          decisionLetter: this.decisionLetter,
          open: this.open,
          unresolved: this.unresolved,
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
          ...(team ? { authors: this.authors, votes: this.votes.map((v) => v.toJson()) } : {}),
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
    unresolvedQuestions = 0,
    conflicts = 0,
    openConflicts = 0,
  } = {}) {
    this.questions = questions;
    this.openQuestions = openQuestions;
    this.answeredQuestions = answeredQuestions;
    this.comments = comments;
    this.marks = marks;
    /** Questions whose team answer begins `open:` (also counted as answered). */
    this.unresolvedQuestions = unresolvedQuestions;
    /** Conflict blocks. */
    this.conflicts = conflicts;
    /** Conflict blocks without a decision. */
    this.openConflicts = openConflicts;
  }

  /** The canonical JSON form; `{team: true}` adds the team counts (SOM §11.9.8). */
  toJson({ team = false } = {}) {
    const out = {
      questions: this.questions,
      openQuestions: this.openQuestions,
      answeredQuestions: this.answeredQuestions,
      comments: this.comments,
      marks: this.marks,
    };
    if (team) {
      out.unresolvedQuestions = this.unresolvedQuestions;
      out.conflicts = this.conflicts;
      out.openConflicts = this.openConflicts;
    }
    return out;
  }
}

/** A question to insert (SOM §11.9.2). */
class SpecQuestionDraft {
  /**
   * @param {{id: string, topic: string, text: string, options?: string[],
   *   recommendation?: string, assumption?: string, starred?: boolean,
   *   recommended?: string|null}} options
   */
  constructor({
    id,
    topic,
    text,
    options = [],
    recommendation = '',
    assumption = '',
    starred = false,
    recommended = null,
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
    /** The recommended option's letter; that option is written bold. */
    this.recommended = recommended;
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
      recommended: j.recommended ?? null,
    });
  }
}

/** What to do with one inline mark (SOM §11.9.3). */
const SpecMarkDecision = Object.freeze({
  /** Take the change: an insertion's text, nothing for a deletion, a substitution's new text. */
  ACCEPT: 'accept',
  /** Undo the change: nothing for an insertion, a deletion's text, a substitution's old text. */
  REJECT: 'reject',
  /** Keep the mark as written. */
  LEAVE: 'leave',
});

/** One inline mark as `listMarks` reports it. */
class SpecMarkEntry {
  /**
   * @param {{id: string, path: string, field?: string|null, line: number,
   *   markKind: string, oldText: string, newText: string,
   *   comment?: string|null, markup: string, context: string,
   *   authors?: string[], votes?: SpecMarkVote[]}} options
   */
  constructor({
    id,
    path,
    field = null,
    line,
    markKind,
    oldText,
    newText,
    comment = null,
    markup,
    context,
    authors = [],
    votes = [],
  }) {
    /** `M-<n>`: the mark's 1-based position among all marks of the document. */
    this.id = id;
    /** The value's path. */
    this.path = path;
    /** The form field, or null for content. */
    this.field = field;
    /** The 0-based line within the value where the mark opens. */
    this.line = line;
    /** The mark's kind (a {@link SpecMarkKind} value). */
    this.markKind = markKind;
    /** The text after rejecting the mark. */
    this.oldText = oldText;
    /** The text after accepting the mark. */
    this.newText = newText;
    /** A comment mark's or a commented highlight's comment. */
    this.comment = comment;
    /** The mark as written. */
    this.markup = markup;
    /** The paragraph holding the mark, verbatim — for display. */
    this.context = context;
    /** The authors its attribution token names (SOM §11.9.8); empty without one. */
    this.authors = authors;
    /** The votes its attribution token records; empty without one. */
    this.votes = votes;
  }

  /** The canonical JSON form the conformance corpus pins; `{team: true}` adds authors and votes. */
  toJson({ team = false } = {}) {
    const out = {
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
    if (team) {
      out.authors = this.authors;
      out.votes = this.votes.map((v) => v.toJson());
    }
    return out;
  }
}

/** What was done to one mark. */
class SpecMarkOutcome {
  /**
   * @param {{id: string, path: string, field?: string|null, line: number,
   *   markKind: string, decision: string, markup: string, result: string}} options
   */
  constructor({ id, path, field = null, line, markKind, decision, markup, result }) {
    /** The mark's id at the revision the operation ran on. */
    this.id = id;
    /** The value's path. */
    this.path = path;
    /** The form field, or null for content. */
    this.field = field;
    /** The 0-based line within the value where the mark opened. */
    this.line = line;
    /** The mark's kind. */
    this.markKind = markKind;
    /** Accepted or rejected (a {@link SpecMarkDecision} value). */
    this.decision = decision;
    /** The mark as written. */
    this.markup = markup;
    /** The text that replaced it. */
    this.result = result;
  }

  /** The canonical JSON form. */
  toJson() {
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
class SpecMarkIssue {
  /** @param {{path: string, field?: string|null, line: number, issue: string}} options */
  constructor({ path, field = null, line, issue }) {
    /** The value's path. */
    this.path = path;
    /** The form field, or null for content. */
    this.field = field;
    /** The 0-based line within the value. */
    this.line = line;
    /** `unclosed`, `nested` or `noArrow`. */
    this.issue = issue;
  }

  /** The canonical JSON form. */
  toJson() {
    return { path: this.path, field: this.field, line: this.line, issue: this.issue };
  }
}

/** What `removeAllAnnotations` did with one conflict block (SOM §11.9.8). */
class SpecConflictOutcome {
  /**
   * @param {{id: string, path: string, field?: string|null, line: number,
   *   decision: string, result: string}} options
   */
  constructor({ id, path, field = null, line, decision, result }) {
    /** The conflict id, `X-<n>`. */
    this.id = id;
    /** The value's path. */
    this.path = path;
    /** The form field, or null for content. */
    this.field = field;
    /** The 0-based line within the value where the block opened. */
    this.line = line;
    /** The decision as written. */
    this.decision = decision;
    /** The text the decision chose. */
    this.result = result;
  }

  /** The canonical JSON form. */
  toJson() {
    return {
      id: this.id,
      path: this.path,
      field: this.field,
      line: this.line,
      decision: this.decision,
      result: this.result,
    };
  }
}

/** The report of a mark operation, for the decision log. */
class SpecMarkReport {
  /**
   * @param {{applied?: SpecMarkOutcome[], malformed?: SpecMarkIssue[],
   *   conflicts?: SpecConflictOutcome[]|null}} [options]
   */
  constructor({ applied = [], malformed = [], conflicts = null } = {}) {
    /** What was done, in document order. */
    this.applied = applied;
    /** Malformed marks in scope, left as written. */
    this.malformed = malformed;
    /**
     * The conflicts `removeAllAnnotations` applied, in document order; null for
     * the mark operations, which do not touch conflicts.
     */
    this.conflicts = conflicts;
  }

  /** The canonical JSON form; `{team: true}` adds the applied conflicts. */
  toJson({ team = false } = {}) {
    const out = {
      applied: this.applied.map((a) => a.toJson()),
      malformed: this.malformed.map((m) => m.toJson()),
    };
    if (team && this.conflicts !== null) {
      out.conflicts = this.conflicts.map((c) => c.toJson());
    }
    return out;
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
const _SCALES = '⚖';
const _DECISION_LABEL = '**Decision:**';
const _UNRESOLVED_PREFIX = 'open:';
/** The start of an individual answer line, `**Answer (alice, bob):**`. */
const _INDIVIDUAL_ANSWER = /^\*\*Answer \(([^)]*)\):\*\*/;
/** A member id (SOM §11.9.8): lowercase letters, digits and `_`. */
const _MEMBER_ID = /^[a-z0-9_]+$/;

/** Whether `s` is a member id (SOM §11.9.8). */
function isReviewMemberId(s) {
  return _MEMBER_ID.test(s);
}

function _isUnresolved(answer) {
  return answer.startsWith(_UNRESOLVED_PREFIX);
}

/** A conflict decision's letter: `a`…, `base`, or null (rewritten text or none). */
function _decisionLetter(decision) {
  const t = decision.trimStart();
  if (t.startsWith('(base)') || t.startsWith('**(base)**')) return 'base';
  return _isUnresolved(t) ? null : _leadingLetter(t);
}

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
 * `combined`, a conflict block `conflict`. A mark is `{start, end, bodyEnd,
 * line, kind, text, newText, comment, authors, votes}`: `end` lies after the
 * attribution token when the mark has one, `bodyEnd` always right after the
 * mark itself, so the token can be rewritten in place.
 */
function _parse(value) {
  const lines = value.split('\n');
  const code = _codeLines(lines);
  // markIssues: malformed inline marks as [value line, issue code] —
  // `unclosed`, `nested`, `noArrow`.
  const p = { lines, code, blocks: [], comments: [], marks: [], malformed: [], markIssues: [] };

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
    } else if (first.startsWith(_SCALES)) {
      const b = { start: s, end: e, kind: SpecReviewAnnotationKind.CONFLICT };
      p.blocks.push(b);
      b.conflict = _parseConflict(p, b);
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
    if (
      t.startsWith(_QUESTION_OPEN) ||
      t.startsWith(_ANSWER_LABEL) ||
      _INDIVIDUAL_ANSWER.test(t)
    ) {
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

function _isLetter(c) {
  return c.length === 1 && c >= 'a' && c <= 'z';
}

/**
 * The options of a question and its recommended letter (SOM §11.9.2): one
 * option per line, `- (a) …`, the recommended one bold, `- **(b)** …`. The
 * recommended letter is the first bold option's; else the first option's
 * whose text says "recommended"; else the letter a `*Recommendation:*` line
 * names; else none.
 * @param {string[]} lines
 * @returns {{options: SpecQuestionOption[], recommended: string|null}}
 */
function _parseOptions(lines) {
  const options = [];
  let letter = null;
  let text = null;
  let bold = false;
  const close = () => {
    if (letter !== null) options.push(new SpecQuestionOption(letter, text.trim(), { bold }));
    letter = null;
  };
  for (const l of lines) {
    if (l.startsWith('- ')) {
      const r = l.substring(2);
      if (
        r.length >= 7 &&
        r.startsWith('**(') &&
        _isLetter(r[3]) &&
        r.substring(4, 7) === ')**'
      ) {
        close();
        letter = r[3];
        text = r.substring(7);
        bold = true;
        continue;
      }
      if (r.length >= 3 && r[0] === '(' && _isLetter(r[1]) && r[2] === ')') {
        close();
        letter = r[1];
        text = r.substring(3);
        bold = false;
        continue;
      }
    }
    if (letter !== null && l.startsWith(' ') && l.trim().length > 0) {
      text = `${text.trim()} ${l.trim()}`;
      continue;
    }
    close();
  }
  close();
  for (const o of options) {
    if (o.bold) return { options, recommended: o.letter };
  }
  for (const o of options) {
    if (o.text.toLowerCase().includes('recommended')) return { options, recommended: o.letter };
  }
  const label = '*Recommendation:*';
  for (const l of lines) {
    const i = l.indexOf(label);
    if (i < 0) continue;
    const x = _leadingLetter(l.substring(i + label.length));
    if (x !== null) return { options, recommended: x };
  }
  return { options, recommended: null };
}

/** The letter of a leading `(x)` or `**(x)**` in `s` (spaces skipped), or null. */
function _leadingLetter(s) {
  let t = s.trimStart();
  if (t.startsWith('**')) t = t.substring(2);
  if (t.length >= 3 && t[0] === '(' && _isLetter(t[1]) && t[2] === ')') return t[1];
  return null;
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
    // Every `**Answer` line of the region: the individual ones and the team's.
    const answerLines = [];
    for (let m = k + 1; m <= regionEnd; m++) {
      if (inner[m].startsWith(_ANSWER_LABEL) || _INDIVIDUAL_ANSWER.test(inner[m])) {
        answerLines.push(m);
      }
    }
    // An answer runs to the next `**Answer` line or the end of the region.
    const answerEnd = (m) => {
      const next = answerLines.find((x) => x > m);
      return next === undefined ? regionEnd : next - 1;
    };
    const answerText = (m, label) =>
      [inner[m].substring(label), ...inner.slice(m + 1, answerEnd(m) + 1)].join('\n').trim();
    // The question's text ends before its first answer line of either kind.
    const textEnd = answerLines.length === 0 ? regionEnd : answerLines[0] - 1;
    const { options, recommended } = _parseOptions(inner.slice(k + 1, textEnd + 1));
    const text = [h.rest, ...inner.slice(k + 1, textEnd + 1)].join('\n').trim();
    let answer = null;
    // Individual answers as {line, end (last value line with text), members, answer}.
    const individual = [];
    const answered = new Set();
    for (const m of answerLines) {
      if (inner[m].startsWith(_ANSWER_LABEL)) {
        if (answer === null) answer = m;
        continue;
      }
      const match = _INDIVIDUAL_ANSWER.exec(inner[m]);
      const members = match[1].split(',').map((x) => x.trim());
      for (const member of members) {
        if (answered.has(member)) {
          p.malformed.push(
            `line ${b.start + m}: ${member} already answered ${h.id}; a member answers ` +
              'a question at most once (SOM §11.9.8)',
          );
        }
        answered.add(member);
      }
      let end = answerEnd(m);
      while (end > m && inner[end].trim().length === 0) end--;
      individual.push({
        line: b.start + m,
        end: b.start + end,
        members,
        answer: answerText(m, match[0].length),
      });
    }
    list.push({
      header: b.start + k,
      regionEnd: b.start + regionEnd,
      answerLine: answer === null ? null : b.start + answer,
      id: h.id,
      topic: h.topic,
      starred: h.starred,
      text,
      answer: answer === null ? '' : answerText(answer, _ANSWER_LABEL.length),
      options,
      recommended,
      answers: individual,
    });
  }
  b.questions = list;
}

/** `- (base) …`: the base line of a conflict block. */
const _CONFLICT_BASE = /^- \(base\)(?: (.*))?$/;
/** `- (a) **alice, bob:** …`: a lettered alternative. */
const _CONFLICT_ALTERNATIVE = /^- \(([a-z])\)(?: \*\*([^*]*):\*\*)?(?: (.*))?$/;
/** The header after the marker: `**X-<n> — <topic>:** <text>`. */
const _CONFLICT_HEADER = /^\*\*(X-[1-9][0-9]*) — (.+?):\*\*(?: (.*))?$/;

/**
 * A conflict block (SOM §11.9.8): the header, the `(base)` line and the
 * lettered alternatives — each continuing on lines indented under it, its line
 * breaks kept — then `**Decision:**`. A malformed header leaves the block
 * unlisted (`id` null); a missing base line or alternative is a finding.
 * Returns `{block, id, topic, text, base (null without one), alternatives,
 * decision}`.
 */
function _parseConflict(p, b) {
  const inner = [];
  for (let k = b.start; k <= b.end; k++) inner.push(_inner(p.lines[k]));
  let rest = inner[0].substring(_SCALES.length);
  if (rest.startsWith(_VS16)) rest = rest.substring(_VS16.length);
  const header = _CONFLICT_HEADER.exec(rest.trimStart());
  const c = {
    block: b,
    id: header === null ? null : header[1],
    topic: header === null ? '' : header[2],
    text: header === null ? '' : (header[3] ?? '').trim(),
    base: null,
    alternatives: [],
    decision: '',
  };
  if (header === null) {
    p.malformed.push(
      `line ${b.start}: conflict header is not "⚖️ **X-<n> — <topic>:**" (SOM §11.9.8)`,
    );
  }
  let decisionLine = inner.findIndex((l, k) => k > 0 && l.startsWith(_DECISION_LABEL));
  if (decisionLine < 0) decisionLine = inner.length;
  // The open entry: the base (letter null) or an alternative.
  let open = null;
  const close = () => {
    if (open === null) return;
    const text = open.lines.join('\n').trim();
    if (open.letter === null) {
      c.base = text;
    } else {
      c.alternatives.push(new SpecConflictAlternative(open.letter, open.members, text));
    }
    open = null;
  };
  for (let k = 1; k < decisionLine; k++) {
    const l = inner[k];
    const base = _CONFLICT_BASE.exec(l);
    const alt = base === null ? _CONFLICT_ALTERNATIVE.exec(l) : null;
    if (base !== null) {
      close();
      open = { letter: null, members: [], lines: [base[1] ?? ''] };
    } else if (alt !== null) {
      close();
      const members = (alt[2] ?? '')
        .split(',')
        .map((x) => x.trim())
        .filter((x) => x.length > 0);
      open = { letter: alt[1], members, lines: [alt[3] ?? ''] };
    } else if (open !== null && l.startsWith(' ')) {
      open.lines.push(l.startsWith('  ') ? l.substring(2) : _lstrip(l));
    } else {
      close();
    }
  }
  close();
  if (decisionLine < inner.length) {
    c.decision = [
      inner[decisionLine].substring(_DECISION_LABEL.length),
      ...inner.slice(decisionLine + 1),
    ]
      .join('\n')
      .trim();
  }
  if (header !== null && c.base === null) {
    p.malformed.push(`line ${b.start}: conflict ${c.id} has no "(base)" line (SOM §11.9.8)`);
  }
  if (header !== null && c.alternatives.length === 0) {
    p.malformed.push(
      `line ${b.start}: conflict ${c.id} has no lettered alternative (SOM §11.9.8)`,
    );
  }
  return c;
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
    if (c === '{' && seg.startsWith('{@', i)) {
      // A token that no mark precedes directly (a mark's own token is read
      // with the mark, below).
      const tokenLine = lineOf(base + i);
      p.malformed.push(
        `line ${tokenLine}: an attribution token "{@" does not follow a mark directly (SOM §11.9.8)`,
      );
      const tokenClose = seg.indexOf('}', i + 2);
      i = tokenClose < 0 ? i + 2 : tokenClose + 1;
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
    const mark = (kind, text, newText, comment) => ({
      start: base + i,
      end: base + end,
      bodyEnd: base + end,
      line,
      kind,
      text,
      newText,
      comment,
      authors: [],
      votes: [],
    });
    const before = p.marks.length;
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
    if (p.marks.length > before && seg.startsWith('{@', end)) {
      end = _attachToken(p, seg, end, base, p.marks[p.marks.length - 1]);
    }
    i = end;
  }
}

/**
 * Reads the attribution token `{@…}` at `at` (SOM §11.9.8) into `m`, which it
 * directly follows, and returns the segment offset after it. The token is part
 * of the mark — its markup, its decision — so `m.end` moves past it. A token
 * that breaks the grammar is still part of the mark (it goes with the mark on a
 * decision) and is a finding; its members are then not listed.
 */
function _attachToken(p, seg, at, base, m) {
  const lineEnd = seg.indexOf('\n', at);
  const close = seg.indexOf('}', at + 2);
  if (close < 0 || (lineEnd >= 0 && close > lineEnd)) {
    p.malformed.push(`line ${m.line}: attribution token "{@" is not closed (SOM §11.9.8)`);
    return at;
  }
  const read = _readToken(seg.substring(at + 2, close), m.kind);
  if (typeof read === 'string') {
    p.malformed.push(`line ${m.line}: attribution token ${read} (SOM §11.9.8)`);
  } else {
    m.authors = read.authors;
    m.votes = read.votes;
  }
  m.end = base + close + 1;
  return close + 1;
}

/** Whether a mark kind is a change, which alone takes votes (SOM §11.9.8). */
function _isChangeMark(kind) {
  return (
    kind === SpecMarkKind.INSERTION ||
    kind === SpecMarkKind.DELETION ||
    kind === SpecMarkKind.SUBSTITUTION
  );
}

/**
 * The members of a token's inside, `<authors>[ <votes>]` as `{authors,
 * votes}`, or the reason (a string) it breaks the grammar of SOM §11.9.8.
 */
function _readToken(inside, kind) {
  const words = inside
    .replace(/,\s+/g, ',')
    .trim()
    .split(/\s+/)
    .filter((w) => w.length > 0);
  if (words.length === 0) return 'is empty';
  const authors = [];
  const votes = [];
  let k = 0;
  if (!words[0].startsWith('+') && !words[0].startsWith('-')) {
    authors.push(...words[0].split(','));
    k = 1;
  }
  for (; k < words.length; k++) {
    const w = words[k];
    if (!w.startsWith('+') && !w.startsWith('-')) return `has "${w}" where a vote belongs`;
    votes.push(new SpecMarkVote(w.substring(1), w.startsWith('+') ? 'accept' : 'reject'));
  }
  const seen = new Set();
  for (const id of [...authors, ...votes.map((v) => v.member)]) {
    if (!_MEMBER_ID.test(id)) return `names "${id}", which is not a member id`;
    if (seen.has(id)) return `names ${id} twice, or as author and voter`;
    seen.add(id);
  }
  if (votes.length > 0 && !_isChangeMark(kind)) {
    return `carries votes on a ${kind} mark, which takes authors only`;
  }
  return { authors, votes };
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
    } else if (b.kind === SpecReviewAnnotationKind.CONFLICT) {
      const c = b.conflict;
      if (c.id === null) continue;
      out.push([
        b.start,
        0,
        seq++,
        new SpecReviewAnnotation({
          kind: SpecReviewAnnotationKind.CONFLICT,
          path,
          field,
          line: b.start,
          id: c.id,
          qualifiedId: qualifier != null ? `${qualifier} ${c.id}` : null,
          topic: c.topic,
          text: c.text,
          base: c.base ?? '',
          alternatives: c.alternatives,
          answer: c.decision,
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
            options: q.options,
            recommended: q.recommended,
            answers: q.answers.map((a) => new SpecIndividualAnswer(a.members, a.answer)),
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
        authors: m.authors,
        votes: m.votes,
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
    ...q.options.map((o) =>
      q.recommended != null && o.startsWith(`(${q.recommended})`)
        ? `> - **(${q.recommended})**${o.substring(3)}`
        : `> - ${o}`,
    ),
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

function _isSpace(c) {
  return c === ' ' || c === '\t';
}

function _trimEndSpaces(s) {
  let k = s.length;
  while (k > 0 && _isSpace(s[k - 1])) k--;
  return s.substring(0, k);
}

function _trimStartSpaces(s) {
  let k = 0;
  while (k < s.length && _isSpace(s[k])) k++;
  return s.substring(k);
}

/**
 * Applies a mark's replacement with the whitespace rules of SOM §11.9.3: never
 * join two words, never leave a double space or a space before punctuation, and
 * a mark that was a whole line leaves no blank line.
 */
function _replaceMark(value, m, replacement0) {
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
 * `value` with every inline mark accepted (`accept`) or rejected, and every
 * highlight and comment mark removed, by the rules of SOM §11.9.3. Marks in
 * code and malformed marks stay as written.
 *
 * @param {string} value
 * @param {{accept: boolean}} options
 * @returns {string}
 */
function applyInlineMarksText(value, { accept }) {
  let v = value;
  const marks = _parse(v).marks;
  for (let k = marks.length - 1; k >= 0; k--) {
    v = _replaceMark(v, marks[k], _markReplacement(marks[k], accept));
  }
  return v;
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
// Team reviews (SOM §11.9.8): individual answers and applying conflicts.
// ---------------------------------------------------------------------------

/** Whether an answer carries anything beyond an option letter (SOM §11.9.8). */
function _isCommentedAnswer(answer, options) {
  const letter = _leadingLetter(answer);
  if (letter === null) return true;
  const t = answer.trimStart();
  const bold = t.startsWith('**(') && t.substring(4, 7) === ')**';
  const rest = t.substring(bold ? 7 : t.startsWith('**') ? 2 + 3 : 3).trim();
  if (rest.length === 0) return false;
  const option = options.find((o) => o.letter === letter);
  return option === undefined || rest !== option.text;
}

/** The lines of one individual-answer entry. */
function _individualAnswerLines(members, answer) {
  const a = answer.split('\n');
  return [`> **Answer (${members.join(', ')}):** ${a[0]}`.trimEnd(), ..._quoted(a.slice(1))];
}

/**
 * `value` with member `member`'s individual answer to question `q` set to
 * `answer` (SOM §11.9.8): the member leaves the line it was on (a line left
 * empty goes); a non-empty answer that is not commented joins the line whose
 * answer is identical and not commented, at its end, and otherwise gets a new
 * line after the last individual answer. The first individual answer opens the
 * run before the team's `**Answer:**`, with a `>` line between run and team
 * answer, and a run left empty takes that line with it. Entries left alone
 * keep their bytes.
 */
function _setIndividualAnswer(value, q, member, answer) {
  const lines = value.split('\n');
  // An entry's `lines` are its verbatim lines, or null once it must be rewritten.
  const entries = q.answers.map((a) => ({
    members: a.members.slice(),
    answer: a.answer,
    lines: lines.slice(a.line, a.end + 1),
  }));
  for (const e of entries) {
    const at = e.members.indexOf(member);
    if (at >= 0) {
      e.members.splice(at, 1);
      e.lines = null;
    }
  }
  const kept = entries.filter((e) => e.members.length > 0);
  const text = answer.trim();
  if (text.length > 0) {
    const join = _isCommentedAnswer(text, q.options)
      ? undefined
      : kept.find((e) => e.answer === text && !_isCommentedAnswer(e.answer, q.options));
    if (join !== undefined) {
      join.members.push(member);
      join.lines = null;
    } else {
      kept.push({ members: [member], answer: text, lines: null });
    }
  }
  const run = kept.flatMap((e) => e.lines ?? _individualAnswerLines(e.members, e.answer));
  if (q.answers.length > 0) {
    const from = q.answers[0].line;
    let to = q.answers[q.answers.length - 1].end;
    // A run left empty takes its separating `>` line with it.
    if (run.length === 0 && to + 1 < lines.length && _inner(lines[to + 1]).trim().length === 0) {
      to++;
    }
    lines.splice(from, to - from + 1, ...run);
  } else if (run.length > 0) {
    if (q.answerLine !== null) {
      lines.splice(q.answerLine, 0, ...run, '>');
    } else {
      let last = q.regionEnd;
      while (last > q.header && _inner(lines[last]).trim().length === 0) last--;
      lines.splice(last + 1, 0, '>', ...run);
    }
  }
  return lines.join('\n');
}

/** Topics of the structural conflicts a merge writes (SOM §11.9.9); their decisions are not text. */
const _STRUCTURAL_TOPICS = new Set(['Item removed', 'Item moved', 'Headline changed']);

/** The text a conflict's decision chooses: the base, an alternative, or the rewritten text. */
function _chosenText(c) {
  const letter = _decisionLetter(c.decision);
  if (letter === 'base') return c.base ?? '';
  if (letter !== null) return c.alternatives.find((a) => a.letter === letter).text;
  return c.decision;
}

/** The text paragraphs (no annotation block) of a parsed value, as `[first, last]` lines. */
function _textParagraphs(p) {
  return _paragraphs(p.lines, p.code).filter(([s]) => !p.blocks.some((b) => b.start === s));
}

/** `value` with the lines `[s, e]` replaced by `text`. */
function _replaceLines(value, s, e, text) {
  const lines = value.split('\n');
  lines.splice(s, e - s + 1, ...text.split('\n'));
  return lines.join('\n');
}

/**
 * `value` with the text paragraph directly before block `b` (annotation
 * blocks between them skipped) replaced by `text`; with none, `text` goes
 * before the block.
 */
function _replaceParagraphBefore(value, b, text) {
  const before = _textParagraphs(_parse(value)).filter(([, e]) => e < b.start);
  if (before.length === 0) return _insertAfterLine(value, b.start - 1, text.split('\n'));
  const [s, e] = before[before.length - 1];
  return _replaceLines(value, s, e, text);
}

/**
 * `value` with the run of text paragraphs directly before block `b` — a
 * whole-value unit (SOM §11.9.9) — replaced by `text`.
 */
function _replaceTextRun(value, b, text) {
  const p = _parse(value);
  const paras = _paragraphs(p.lines, p.code).filter(([, e]) => e < b.start);
  let k = paras.length;
  while (k > 0 && !p.blocks.some((x) => x.start === paras[k - 1][0])) k--;
  const run = paras.slice(k);
  if (run.length === 0) return _insertAfterLine(value, b.start - 1, text.split('\n'));
  return _replaceLines(value, run[0][0], run[run.length - 1][1], text);
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
    let unresolved = 0;
    let c = 0;
    let m = 0;
    let x = 0;
    let openX = 0;
    for (const a of this.list()) {
      if (a.kind === SpecReviewAnnotationKind.QUESTION) {
        q++;
        if (a.open) open++;
        if (a.unresolved) unresolved++;
      } else if (a.kind === SpecReviewAnnotationKind.COMMENT) {
        c++;
      } else if (a.kind === SpecReviewAnnotationKind.CONFLICT) {
        x++;
        if (a.open) openX++;
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
      unresolvedQuestions: unresolved,
      conflicts: x,
      openConflicts: openX,
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

  /**
   * Writes `answer` after the question's `**Answer:**` (empty: reopens it).
   * With `author`, writes that member's individual answer instead, grouped and
   * placed by the rules of SOM §11.9.8 (empty: only takes the member out); an
   * author that is not a member id is refused.
   *
   * @param {string} questionId
   * @param {string} answer
   * @param {{author?: string|null}} [options]
   */
  setAnswer(questionId, answer, { author = null } = {}) {
    if (author != null && !_MEMBER_ID.test(author)) {
      throw new SpecReviewAnnotationError(
        `"${author}" is not a member id (lowercase letters, digits and _)`,
      );
    }
    const [path, field, text, , q] = this._findQuestion(questionId);
    if (author != null) {
      this._set(path, field, _setIndividualAnswer(text, q, author, answer));
      return;
    }
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
   * The revision the mark ids are stable for: FNV-1a 64-bit over the UTF-8 of
   * every value in document order (path, NUL, field or empty, NUL, text, NUL),
   * as 16 lower-case hex digits. Any change to a value changes it.
   *
   * @returns {string}
   */
  revision() {
    const prime = 0x100000001b3n;
    const mask = 0xffffffffffffffffn;
    let h = 0xcbf29ce484222325n;
    const enc = new TextEncoder();
    const add = (s) => {
      for (const b of enc.encode(s)) {
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

  static _under(path, under) {
    return under == null || path === under || path.startsWith(`${under}/`);
  }

  /**
   * Every inline mark of the document, or of the subtree at `path`, in document
   * order.
   *
   * @param {{path?: string|null}} [options]
   * @returns {SpecMarkEntry[]}
   */
  listMarks({ path = null } = {}) {
    const out = [];
    let n = 0;
    for (const [vpath, field, text] of this._values()) {
      const p = _parse(text);
      const paras = _paragraphs(p.lines, p.code);
      for (const m of p.marks) {
        const id = `M-${++n}`;
        if (!SpecReviewAnnotations._under(vpath, path)) continue;
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
            authors: m.authors,
            votes: m.votes,
          }),
        );
      }
    }
    return out;
  }

  /** Applies `decide(id)` to every mark in the subtree `under` (null: all), one write per value. */
  _applyMarks(decide, under = null) {
    const applied = [];
    const issues = [];
    let n = 0;
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      const ids = p.marks.map(() => `M-${++n}`);
      if (!SpecReviewAnnotations._under(path, under)) continue;
      for (const [line, issue] of p.markIssues) {
        issues.push(new SpecMarkIssue({ path, field, line, issue }));
      }
      let v = text;
      const outcomes = [];
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
   *
   * @param {Object<string, string>|Map<string, string>} decisions mark id →
   *   {@link SpecMarkDecision} value
   * @param {{revision: string}} options
   * @returns {SpecMarkReport}
   */
  decideMarks(decisions, { revision }) {
    const map = decisions instanceof Map ? decisions : new Map(Object.entries(decisions));
    const current = this.revision();
    if (revision !== current) {
      throw new SpecReviewAnnotationError(
        `the document changed since revision ${revision} (now ${current}); list the marks again`,
      );
    }
    const known = new Set(this.listMarks().map((m) => m.id));
    for (const [id, d] of map) {
      if (!known.has(id)) {
        throw new SpecReviewAnnotationError(`no inline mark ${id} in the document`);
      }
      if (!Object.values(SpecMarkDecision).includes(d)) {
        throw new SpecReviewAnnotationError(`unknown mark decision ${d} for ${id}`);
      }
    }
    return this._applyMarks((id) => map.get(id));
  }

  /** Accepts every inline mark under `path` (null: the whole document). @returns {SpecMarkReport} */
  acceptAllMarks({ path = null } = {}) {
    return this._applyMarks(() => SpecMarkDecision.ACCEPT, path);
  }

  /** Rejects every inline mark under `path` (null: the whole document). @returns {SpecMarkReport} */
  rejectAllMarks({ path = null } = {}) {
    return this._applyMarks(() => SpecMarkDecision.REJECT, path);
  }

  /**
   * Removes every annotation and writes the result back: every inline mark
   * accepted, every conflict's decision applied (SOM §11.9.8), every comment,
   * question and conflict block removed. Malformed marks stay and are
   * reported. Refused — nothing changes — while a conflict is open, unresolved
   * (`open:`), malformed, or decided for a letter it has no alternative for.
   *
   * @returns {SpecMarkReport}
   */
  removeAllAnnotations() {
    const decided = this._decidedConflicts();
    const marks = this.acceptAllMarks();
    const outcomes = [];
    for (const [path, field, text] of this._values()) {
      let v = text;
      const here = decided.filter((d) => d.path === path && d.field === field);
      if (here.length > 0) v = this._applyConflicts(path, field, v, here, outcomes);
      for (;;) {
        const p = _parse(v);
        if (p.blocks.length === 0) break;
        const b = p.blocks[p.blocks.length - 1];
        v = _removeLines(v, b.start, b.end);
      }
      if (v !== text) this._set(path, field, v);
    }
    return new SpecMarkReport({
      applied: marks.applied,
      malformed: marks.malformed,
      conflicts: outcomes,
    });
  }

  /**
   * Every conflict block of the document as `{path, field, index (among the
   * value's conflict blocks), id, line, decision}`, in document order — or the
   * refusal of `removeAllAnnotations` when one of them cannot be applied. Read
   * before any change, so the lines are the ones the report names.
   */
  _decidedConflicts() {
    const out = [];
    for (const [path, field, text] of this._values()) {
      const p = _parse(text);
      let index = 0;
      for (const b of p.blocks) {
        if (b.kind !== SpecReviewAnnotationKind.CONFLICT) continue;
        const c = b.conflict;
        const where = `${path}${field == null ? '' : ` / ${field}`}, line ${b.start}`;
        if (c.id === null || c.base === null || c.alternatives.length === 0) {
          throw new SpecReviewAnnotationError(`${where}: a malformed conflict block cannot be applied`);
        }
        if (c.decision.length === 0 || _isUnresolved(c.decision)) {
          throw new SpecReviewAnnotationError(
            `${where}: conflict ${c.id} is ${c.decision.length === 0 ? 'open' : 'unresolved'}; ` +
              'decide it before removing the annotations',
          );
        }
        const letter = _decisionLetter(c.decision);
        if (letter !== null && letter !== 'base' && !c.alternatives.some((a) => a.letter === letter)) {
          throw new SpecReviewAnnotationError(`${where}: conflict ${c.id} has no alternative (${letter})`);
        }
        out.push({ path, field, index: index++, id: c.id, line: b.start, decision: c.decision });
      }
    }
    return out;
  }

  /**
   * Applies the decided conflicts of one value (marks already accepted), from
   * the last block up so earlier line numbers stay valid, and records each.
   * Where the chosen text goes follows the conflict's text (SOM §11.9.8,
   * "Applying"): a form field, another value, this value's text paragraphs, or
   * — the default — the text paragraph directly before the block.
   */
  _applyConflicts(path, field, value, decided, outcomes) {
    let v = value;
    const recorded = [];
    const conflicts = _parse(v).blocks.filter((b) => b.kind === SpecReviewAnnotationKind.CONFLICT);
    for (let k = conflicts.length - 1; k >= 0; k--) {
      const d = decided.find((x) => x.index === k);
      const c = conflicts[k].conflict;
      const result = _chosenText(c);
      recorded.unshift(
        new SpecConflictOutcome({ id: d.id, path, field, line: d.line, decision: d.decision, result }),
      );
      v = this._applyConflict(path, field, v, c, result);
    }
    outcomes.push(...recorded);
    return v;
  }

  /** Puts one conflict's chosen text in place; returns the (possibly unchanged) value. */
  _applyConflict(path, field, value, c, result) {
    if (_STRUCTURAL_TOPICS.has(c.topic)) return value;
    const target = /^(\S+) (\S+)$/.exec(c.text);
    if (target !== null && this.doc.formField(target[1], target[2]) != null) {
      this.doc.setFormField(target[1], target[2], result);
      return value;
    }
    if (field == null && c.text === path) return _replaceTextRun(value, c.block, result);
    if (/^[^\s,]+\/[^\s,]+$/.test(c.text) && c.text !== path) {
      this.doc.setContent(c.text, result);
      return value;
    }
    return _replaceParagraphBefore(value, c.block, result);
  }

  /**
   * Writes `text` at `path` / `field` as a marked change against the value
   * there now (SOM §11.9.3). A value that already holds change marks is
   * compared from its original — every mark rejected — so a second edit of
   * the same passage updates its mark instead of nesting one.
   *
   * @param {{path: string, field?: string|null, text: string}} args
   * @returns {SpecMarkedChange}
   */
  setMarked({ path, field = null, text }) {
    const current = this._get(path, field);
    const base = applyInlineMarksText(current, { accept: false });
    const result = markChangeText(base, text);
    this._set(path, field, result.text);
    return result;
  }

  /**
   * Marks the value at `path` / `field` as a change against `earlier`, an
   * earlier version of it.
   *
   * @param {{path: string, field?: string|null, earlier: string}} args
   * @returns {SpecMarkedChange}
   */
  markAgainst({ path, field = null, earlier }) {
    const result = markChangeText(earlier, this._get(path, field));
    this._set(path, field, result.text);
    return result;
  }

  /**
   * The paragraphs of the value at `path` / `field`, in order — the units
   * `afterParagraph` of `insertComment` and `insertQuestion` counts. Throws
   * {@link SpecReviewAnnotationError} when the document holds no such value.
   *
   * @param {{path: string, field?: string|null}} args
   * @returns {SpecParagraph[]}
   */
  paragraphs({ path, field = null }) {
    const value = field == null ? this.doc.content(path) : this.doc.formField(path, field);
    if (value == null) {
      throw new SpecReviewAnnotationError(
        `no value at ${path}${field == null ? '' : ` / ${field}`}`,
      );
    }
    const p = _parse(value);
    return _paragraphs(p.lines, p.code).map(([s, e], i) => {
      const b = p.blocks.find((x) => x.start === s);
      return new SpecParagraph({
        index: i,
        startLine: s,
        endLine: e,
        text: p.lines.slice(s, e + 1).join('\n'),
        annotation: b ? b.kind : null,
      });
    });
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
        if (b.conflict && b.conflict.id) ids.push(b.conflict.id);
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

// ---------------------------------------------------------------------------
// Writing changes as inline marks (SOM §11.9.3, annot5).
// ---------------------------------------------------------------------------

/** A value written as a marked change. */
class SpecMarkedChange {
  /**
   * @param {string} text The value with every difference marked.
   * @param {{exact: boolean}} options Whether accepting the marks gives
   *   exactly the new value and rejecting them exactly the old one. False when
   *   a difference cannot be marked — a change inside fenced code, or text that
   *   holds mark delimiters — and the new value was written unmarked instead.
   */
  constructor(text, { exact }) {
    this.text = text;
    this.exact = exact;
    Object.freeze(this);
  }

  /** The canonical JSON form. */
  toJson() {
    return { text: this.text, exact: this.exact };
  }
}

// One token of a value: a run of whitespace, a word (a run of non-whitespace
// with inline code spans kept whole) or a fenced code block (its lines).
function _tok(text, space) {
  return { text, space };
}

function _isWs(c) {
  return c === ' ' || c === '\t' || c === '\n';
}

function _tokens(value) {
  const out = [];
  const add = (t, space) => {
    if (t.length === 0) return;
    if (space && out.length > 0 && out[out.length - 1].space) {
      out[out.length - 1] = _tok(out[out.length - 1].text + t, true);
    } else {
      out.push(_tok(t, space));
    }
  };
  const words = (s) => {
    let i = 0;
    while (i < s.length) {
      if (_isWs(s[i])) {
        const st = i;
        while (i < s.length && _isWs(s[i])) i++;
        add(s.substring(st, i), true);
        continue;
      }
      const st = i;
      while (i < s.length && !_isWs(s[i])) {
        if (s[i] === '`') {
          let n = 0;
          while (i + n < s.length && s[i + n] === '`') n++;
          // The matching run of exactly n backticks ends the span.
          let j = i + n;
          let close = -1;
          while (j < s.length) {
            if (s[j] === '`') {
              let m = 0;
              while (j + m < s.length && s[j + m] === '`') m++;
              if (m === n) {
                close = j;
                break;
              }
              j += m;
            } else {
              j++;
            }
          }
          i = close < 0 ? i + n : close + n;
          continue;
        }
        i++;
      }
      add(s.substring(st, i), false);
    }
  };
  const lines = value.split('\n');
  const code = _codeLines(lines);
  let k = 0;
  while (k < lines.length) {
    if (k > 0) add('\n', true);
    const st = k;
    const isCode = code[k];
    while (k + 1 < lines.length && code[k + 1] === isCode) k++;
    const run = lines.slice(st, k + 1).join('\n');
    if (isCode) {
      add(run, false);
    } else {
      words(run);
    }
    k++;
  }
  return out;
}

// The diff of two token lists as ops `[kind, token]`: 0 keep, 1 delete (old),
// 2 insert (new). LCS over token text; ties prefer the deletion.
function _diff(a, b) {
  const n = a.length;
  const m = b.length;
  const l = [];
  for (let i = 0; i <= n; i++) l.push(new Array(m + 1).fill(0));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      l[i][j] =
        a[i].text === b[j].text
          ? l[i + 1][j + 1] + 1
          : l[i + 1][j] >= l[i][j + 1]
            ? l[i + 1][j]
            : l[i][j + 1];
    }
  }
  const ops = [];
  let i = 0;
  let j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && a[i].text === b[j].text) {
      ops.push([0, a[i]]);
      i++;
      j++;
    } else if (j >= m || (i < n && l[i + 1][j] >= l[i][j + 1])) {
      ops.push([1, a[i]]);
      i++;
    } else {
      ops.push([2, b[j]]);
      j++;
    }
  }
  return ops;
}

// `s` with its leading and trailing whitespace removed (spaces, tabs,
// newlines).
function _trimWs(s) {
  let a = 0;
  let b = s.length;
  while (a < b && _isWs(s[a])) a++;
  while (b > a && _isWs(s[b - 1])) b--;
  return s.substring(a, b);
}

// The markup for one region whose old text is `o` and new text is `n` (both
// trimmed, not both empty).
function _markup(o, n) {
  if (o.length === 0) return `{++ ${n} ++}`;
  if (n.length === 0) return `{-- ${o} --}`;
  return `{~~ ${o} ~> ${n} ~~}`;
}

// The marked emission for the region [r0, r1) of `ops`, with the old and the
// new text around it, or null when no mark round-trips there.
function _emitRegion(ops, r0, r1, oldBefore, newBefore, oldAfter, newAfter) {
  let os = '';
  let ns = '';
  for (let k = r0; k < r1; k++) {
    const [kind, t] = ops[k];
    if (kind !== 2) os += t.text;
    if (kind !== 1) ns += t.text;
  }
  // Whitespace the two sides share at the edges stays outside the mark.
  let lead = 0;
  while (lead < os.length && lead < ns.length && os[lead] === ns[lead] && _isWs(os[lead])) {
    lead++;
  }
  let trail = 0;
  while (
    trail < os.length - lead &&
    trail < ns.length - lead &&
    os[os.length - 1 - trail] === ns[ns.length - 1 - trail] &&
    _isWs(os[os.length - 1 - trail])
  ) {
    trail++;
  }
  const oi = os.substring(lead, os.length - trail);
  const ni = ns.substring(lead, ns.length - trail);
  // The mark's content is trimmed when read, so it must already be trimmed;
  // the whitespace still differing is placed outside, on the side whose text
  // keeps it, and the tidy rules then have to restore the other side.
  const ot = _trimWs(oi);
  const nt = _trimWs(ni);
  if (ot.length === 0 && nt.length === 0) return null;
  const pre = os.substring(0, lead);
  const post = os.substring(os.length - trail);
  const leadWs = (x) => x.substring(0, x.length - x.trimStart().length);
  const trailWs = (x) => x.substring(x.trimEnd().length);
  const candidates = [
    [leadWs(ni), trailWs(ni)],
    [leadWs(oi), trailWs(oi)],
    ['', ''],
    [leadWs(ni), ''],
    ['', trailWs(ni)],
  ];
  for (const [wl, wr] of candidates) {
    const emission = `${pre}${wl}${_markup(ot, nt)}${wr}${post}`;
    const acc = applyInlineMarksText(`${newBefore}${emission}${newAfter}`, { accept: true });
    const rej = applyInlineMarksText(`${oldBefore}${emission}${oldAfter}`, { accept: false });
    if (acc === `${newBefore}${ns}${newAfter}` && rej === `${oldBefore}${os}${oldAfter}`) {
      return emission;
    }
  }
  return null;
}

// Marks the token-level differences of `o` → `n`, where the text before them
// is `ob` (old) / `nb` (new) and after them `oa` / `na`. Null when the marks
// do not round-trip.
function _markTokens(o, n, ob, nb, oa, na) {
  const ops = _diff(_tokens(o), _tokens(n));
  const runs = [];
  let k = 0;
  while (k < ops.length) {
    if (ops[k][0] === 0) {
      k++;
      continue;
    }
    const s = k;
    while (k < ops.length && ops[k][0] !== 0) k++;
    runs.push([s, k]);
  }
  // Changes separated by at most two unchanged words are one mark.
  const merged = [];
  for (const r of runs) {
    if (merged.length > 0) {
      const last = merged[merged.length - 1];
      let words = 0;
      for (let q = last[1]; q < r[0]; q++) {
        if (!ops[q][1].space) words++;
      }
      if (words <= 2) {
        merged[merged.length - 1] = [last[0], r[1]];
        continue;
      }
    }
    merged.push(r);
  }

  const side = (from, to, skip) => {
    let b = '';
    for (let q = from; q < to; q++) {
      if (ops[q][0] !== skip) b += ops[q][1].text;
    }
    return b;
  };

  // Left to right; a region that does not round-trip grows by one token on
  // each side and is tried again.
  let out = '';
  let pos = 0;
  for (let ri = 0; ri < merged.length; ri++) {
    let [r0, r1] = merged[ri];
    if (r0 < pos) r0 = pos;
    let emission;
    for (;;) {
      emission = _emitRegion(
        ops,
        r0,
        r1,
        `${ob}${side(0, r0, 2)}`,
        `${nb}${side(0, r0, 1)}`,
        `${side(r1, ops.length, 2)}${oa}`,
        `${side(r1, ops.length, 1)}${na}`,
      );
      if (emission !== null || (r0 <= pos && r1 >= ops.length)) break;
      if (r0 > pos) r0--;
      if (r1 < ops.length) r1++;
    }
    if (emission === null) return null;
    out += side(pos, r0, 1) + emission;
    pos = r1;
    while (ri + 1 < merged.length && merged[ri + 1][1] <= pos) ri++;
  }
  out += side(pos, ops.length, 1);
  if (
    applyInlineMarksText(`${nb}${out}${na}`, { accept: true }) !== `${nb}${n}${na}` ||
    applyInlineMarksText(`${ob}${out}${oa}`, { accept: false }) !== `${ob}${o}${oa}`
  ) {
    return null;
  }
  return out;
}

// A whole line marked as inserted (`++`) or deleted (`--`): its indentation
// stays outside the mark; a blank line stays blank.
function _lineMark(line, d) {
  const body = line.trimStart();
  if (body.trim().length === 0) return line;
  const indent = line.substring(0, line.length - body.length);
  return `${indent}{${d} ${body.trimEnd()} ${d}}`;
}

/**
 * `newValue` with its differences from `oldValue` marked, so that accepting
 * every mark gives exactly `newValue` and rejecting every mark exactly
 * `oldValue` (SOM §11.9.3). The diff runs by line, then by word inside a
 * changed run of lines; words are never split, changes separated by at most
 * two unchanged words are one mark, and nothing inside code is marked.
 *
 * @param {string} oldValue
 * @param {string} newValue
 * @returns {SpecMarkedChange}
 */
function markChangeText(oldValue, newValue) {
  if (oldValue === newValue) return new SpecMarkedChange(newValue, { exact: true });
  const ol = oldValue.split('\n');
  const nl = newValue.split('\n');
  const oc = _codeLines(ol);
  const nc = _codeLines(nl);
  const lops = _diff(
    ol.map((l) => _tok(l, false)),
    nl.map((l) => _tok(l, false)),
  );
  const out = [];
  let exact = true;
  let oi = 0;
  let ni = 0;
  let k = 0;
  const join = (ls) => ls.join('\n');
  const blank = (l) => l.trim().length === 0;
  while (k < lops.length) {
    if (lops[k][0] === 0) {
      out.push(nl[ni]);
      oi++;
      ni++;
      k++;
      continue;
    }
    const d0 = oi;
    const n0 = ni;
    while (k < lops.length && lops[k][0] !== 0) {
      if (lops[k][0] === 1) {
        oi++;
      } else {
        ni++;
      }
      k++;
    }
    const del = ol.slice(d0, oi);
    const ins = nl.slice(n0, ni);
    const ob = ol.slice(0, d0);
    const oa = ol.slice(oi);
    const nb = nl.slice(0, n0);
    const na = nl.slice(ni);
    const roundTrips = (e) =>
      applyInlineMarksText(join([...nb, ...e, ...na]), { accept: true }) === newValue &&
      applyInlineMarksText(join([...ob, ...e, ...oa]), { accept: false }) === oldValue;
    let emitted = null;
    const inCode = oc.slice(d0, oi).some((c) => c) || nc.slice(n0, ni).some((c) => c);
    if (!inCode) {
      const candidates = [];
      if (del.length > 0 && ins.length > 0) {
        const t = _markTokens(
          join(del),
          join(ins),
          ob.length === 0 ? '' : `${join(ob)}\n`,
          nb.length === 0 ? '' : `${join(nb)}\n`,
          oa.length === 0 ? '' : `\n${join(oa)}`,
          na.length === 0 ? '' : `\n${join(na)}`,
        );
        if (t !== null) candidates.push(t.split('\n'));
      }
      const dm = del.map((l) => _lineMark(l, '--'));
      const im = ins.map((l) => _lineMark(l, '++'));
      candidates.push(
        [...dm, ...im],
        [...dm.filter((l) => !blank(l)), ...im],
        [...dm, ...im.filter((l) => !blank(l))],
        [...dm.filter((l) => !blank(l)), ...im.filter((l) => !blank(l))],
      );
      for (const e of candidates) {
        if (roundTrips(e)) {
          emitted = e;
          break;
        }
      }
    }
    if (emitted === null) {
      exact = false;
      out.push(...ins);
    } else {
      out.push(...emitted);
    }
  }
  const text = join(out);
  if (
    exact &&
    (applyInlineMarksText(text, { accept: true }) !== newValue ||
      applyInlineMarksText(text, { accept: false }) !== oldValue)
  ) {
    return new SpecMarkedChange(newValue, { exact: false });
  }
  return new SpecMarkedChange(text, { exact });
}

// ---------------------------------------------------------------------------
// Text-level building blocks of the merge (SOM §11.9.9). Internal: exported for
// `spec_review_merge.js` only, not from the package index.
// ---------------------------------------------------------------------------

/**
 * The paragraphs of `value` (SOM §11.9.1), each classified as the merge sees
 * it: `{kind ('text' or the kind of the block the paragraph opens with), text
 * (verbatim), id (a comment's id, a conflict's id; null without one), author
 * (a comment's, or null), commentText, questionIds}`.
 */
function reviewPieces(value) {
  if (value.length === 0) return [];
  const p = _parse(value);
  return _paragraphs(p.lines, p.code).map(([s, e]) => {
    const b = p.blocks.find((x) => x.start === s);
    return {
      kind: b ? b.kind : 'text',
      text: p.lines.slice(s, e + 1).join('\n'),
      id: b?.comment?.id ?? b?.conflict?.id ?? null,
      author: b?.comment?.author ?? null,
      commentText: b?.comment?.text ?? '',
      questionIds: (b?.questions ?? []).map((q) => q.id),
    };
  });
}

/**
 * One inline mark of a value with what its decisions leave: `{start, end,
 * bodyEnd, kind, markup (as written, its token included), authors, votes,
 * accepted, rejected}`.
 */
function _reviewMark(value, m) {
  return {
    start: m.start,
    end: m.end,
    bodyEnd: m.bodyEnd,
    kind: m.kind,
    markup: value.substring(m.start, m.end),
    authors: m.authors,
    votes: m.votes,
    accepted: _markReplacement(m, true),
    rejected: _markReplacement(m, false),
  };
}

/** The inline marks of `value`, in order (marks in code are not marks). */
function reviewMarks(value) {
  return _parse(value).marks.map((m) => _reviewMark(value, m));
}

/**
 * `value` with the marks `decisions` names (a Map from an index into
 * {@link reviewMarks} to accept = true / reject = false) decided, by the
 * whitespace rules of SOM §11.9.3.
 */
function decideReviewMarks(value, decisions) {
  const marks = _parse(value).marks;
  let v = value;
  for (let k = marks.length - 1; k >= 0; k--) {
    const accept = decisions.get(k);
    if (accept === undefined) continue;
    v = _replaceMark(v, marks[k], _markReplacement(marks[k], accept));
  }
  return v;
}

/** The attribution token for `authors` and `votes`, `{@agent +alice -bob}`. */
function formatAttributionToken(authors, votes) {
  const v = votes.map((x) => `${x.vote === 'accept' ? '+' : '-'}${x.member}`).join(' ');
  return `{@${authors.join(',')}${authors.length > 0 && v.length > 0 ? ' ' : ''}${v}}`;
}

/** `value` with mark `m`'s token (a {@link reviewMarks} entry) replaced by one for `authors` and `votes`. */
function withAttribution(value, m, authors, votes) {
  return (
    value.substring(0, m.bodyEnd) + formatAttributionToken(authors, votes) + value.substring(m.end)
  );
}

/** The team answer of every question of `value`, as a Map by id. */
function reviewTeamAnswers(value) {
  const out = new Map();
  for (const b of _parse(value).blocks) {
    for (const q of b.questions ?? []) {
      if (!out.has(q.id)) out.set(q.id, q.answer);
    }
  }
  return out;
}

/**
 * `value` with `member`'s individual answer to question `questionId` set, as
 * `setAnswer` with an `author` does; null when the value holds no such
 * question.
 */
function setIndividualAnswerText(value, questionId, member, answer) {
  for (const b of _parse(value).blocks) {
    for (const q of b.questions ?? []) {
      if (q.id === questionId) return _setIndividualAnswer(value, q, member, answer);
    }
  }
  return null;
}

/** The lines of a conflict's text: the first after its prefix, the rest indented under it. */
function _alternativeLines(prefix, text) {
  const t = text.split('\n');
  return [`> - ${prefix} ${t[0]}`.trimEnd(), ...t.slice(1).map((l) => `>   ${l}`)];
}

/**
 * The lines of a conflict block (SOM §11.9.8): the header, the `(base)` line,
 * one lettered alternative per entry naming its members, and an empty
 * `**Decision:**`. A text's further lines are indented under it, so a reader
 * gets them back with their line breaks.
 *
 * @param {{id: string, topic: string, text: string, base: string,
 *   alternatives: Array<{letter: string, members: string[], text: string}>}} options
 * @returns {string[]}
 */
function formatConflictBlock({ id, topic, text, base, alternatives }) {
  return [
    `> ${_SCALES}${_VS16} **${id}${_EM_DASH_SEP}${topic}:** ${text}`.trimEnd(),
    ..._alternativeLines('(base)', base),
    ...alternatives.flatMap((a) =>
      _alternativeLines(`(${a.letter}) **${a.members.join(', ')}:**`, a.text),
    ),
    '>',
    `> ${_DECISION_LABEL}`,
  ];
}

/**
 * Carries the edits `x` → `y` over to `b`, a text equal to `x` except where
 * marks of `b` were decided in `x` (SOM §11.9.9, step 3): every edit lands in
 * `b` at the place `x` and `b` agree on. Null when an edit touches or borders
 * a place where they differ — the edit overlaps a decided mark. Both diffs are
 * the token diffs of `markChangeText`.
 */
function transplantEdits(x, y, b) {
  const xt = _tokens(x);
  const bt = _tokens(b);
  // Where each token of x is in b (-1: x and b differ there).
  const toB = new Array(xt.length).fill(-1);
  let i = 0;
  let j = 0;
  for (const [kind] of _diff(xt, bt)) {
    if (kind === 0) toB[i++] = j++;
    else if (kind === 1) i++;
    else j++;
  }
  // The edits x → y as [first x token, end x token, inserted text].
  const hunks = [];
  i = 0;
  let open = null;
  for (const [kind, t] of _diff(xt, _tokens(y))) {
    if (kind === 0) {
      if (open !== null) hunks.push(open);
      open = null;
      i++;
      continue;
    }
    if (open === null) open = [i, i, ''];
    if (kind === 1) open[1] = ++i;
    else open[2] += t.text;
  }
  if (open !== null) hunks.push(open);
  const out = bt.map((t) => t.text);
  for (let h = hunks.length - 1; h >= 0; h--) {
    const [x0, x1, ins] = hunks[h];
    const at = _landing(toB, x0, x1, bt.length);
    if (at === null) return null;
    out.splice(at[0], at[1] - at[0], ins);
  }
  return out.join('');
}

/**
 * The b-token range an x-token range `[x0, x1)` lands on, or null when it is not one.
 *
 * A replaced range lands where its tokens are in b, which must be contiguous
 * there; its neighbours are not consulted, because the token diff may align a
 * neighbouring space with another space of b (beside a decided mark) without
 * the range touching that mark. A pure insertion (`x0 === x1`) has no tokens
 * of its own, so both neighbours must sit next to each other in b.
 */
function _landing(toB, x0, x1, bLength) {
  for (let k = x0; k < x1; k++) {
    if (toB[k] < 0 || (k > x0 && toB[k] !== toB[k - 1] + 1)) return null;
  }
  if (x1 > x0) return [toB[x0], toB[x1 - 1] + 1];
  // The neighbours must sit next to the insertion point in b too.
  const left = x0 === 0 ? -1 : toB[x0 - 1];
  const right = x1 === toB.length ? bLength : toB[x1];
  if ((x0 > 0 && left < 0) || (x1 < toB.length && right < 0)) return null;
  if (left + 1 !== right) return null;
  return [left + 1, left + 1];
}

module.exports = {
  SpecReviewAnnotationKind,
  SpecMarkKind,
  SpecMarkDecision,
  SpecMarkEntry,
  SpecMarkOutcome,
  SpecMarkIssue,
  SpecMarkReport,
  SpecReviewAnnotation,
  SpecReviewAnnotationCounts,
  SpecQuestionDraft,
  SpecQuestionOption,
  SpecParagraph,
  SpecReviewAnnotationError,
  SpecReviewAnnotations,
  formatCommentBlock,
  formatQuestionBlock,
  applyInlineMarksText,
  stripAnnotationsText,
  SpecMarkedChange,
  markChangeText,
  SpecMarkVote,
  SpecIndividualAnswer,
  SpecConflictAlternative,
  SpecConflictOutcome,
  isReviewMemberId,
  // Internal building blocks of spec_review_merge.js (not re-exported by index.js).
  reviewPieces,
  reviewMarks,
  decideReviewMarks,
  formatAttributionToken,
  withAttribution,
  reviewTeamAnswers,
  setIndividualAnswerText,
  formatConflictBlock,
  transplantEdits,
};
