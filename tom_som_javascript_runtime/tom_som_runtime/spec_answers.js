'use strict';

/**
 * The answers of a review round, extracted for a step folder (SOM §11.9.7) —
 * a port of `tom_som_dart_runtime/lib/src/spec_answers.dart`.
 *
 * A step of the TomSpecs process starts by collecting what the reviewer
 * wrote into the document — answers to the agent's questions, comments, and
 * optionally the questions still open and the inline marks — into the step
 * folder's `answers.md`. The annotations stay in the document; this reads
 * them through `SpecReviewAnnotations.list` and never writes.
 */

const { SpecDocumentMarkdown } = require('./spec_document_markdown');
const {
  SpecReviewAnnotationKind,
  SpecReviewAnnotations,
} = require('./spec_review_annotations');

/** What an extracted entry is. */
const SpecAnswerKind = Object.freeze({
  /** A question with an answer. */
  ANSWERED: 'answered',
  /** A question without an answer. */
  OPEN: 'open',
  /** A comment block. */
  COMMENT: 'comment',
  /** An inline mark. */
  MARK: 'mark',
});

/** One extracted entry. */
class SpecAnswerEntry {
  /**
   * @param {object} init `kind` (a {@link SpecAnswerKind}); `id` (`BQ-81`,
   *   `C-12`, `M-<n>`, null for a comment without an id); `section` (the
   *   section-id chain, `SBP > INSC > SYSUM`); `line` (1-based, in the
   *   Markdown rendition); `path`; `field` (null for content); `topic`;
   *   `combined`; `text` (question / comment text, or a mark's markup);
   *   `answer` (empty when open); `author`; `markKind`; `oldText` / `newText`
   *   (a mark's text when rejected / accepted); `comment` (a mark's comment).
   */
  constructor(init) {
    this.kind = init.kind;
    this.id = init.id ?? null;
    this.section = init.section;
    this.line = init.line;
    this.path = init.path;
    this.field = init.field ?? null;
    this.topic = init.topic ?? null;
    this.combined = init.combined ?? false;
    this.text = init.text ?? '';
    this.answer = init.answer ?? '';
    this.author = init.author ?? null;
    this.markKind = init.markKind ?? null;
    this.oldText = init.oldText ?? null;
    this.newText = init.newText ?? null;
    this.comment = init.comment ?? null;
  }

  /** The canonical JSON form. */
  toJson() {
    return {
      kind: this.kind,
      id: this.id,
      section: this.section,
      line: this.line,
      path: this.path,
      field: this.field,
      topic: this.topic,
      combined: this.combined,
      text: this.text,
      answer: this.answer,
      author: this.author,
      markKind: this.markKind,
      oldText: this.oldText,
      newText: this.newText,
      comment: this.comment,
    };
  }
}

/** The counts a step's closing item reports. */
class SpecAnswerCounts {
  /** @param {object} [init] `answered`, `open`, `comments`, `marks` (default 0). */
  constructor(init = {}) {
    this.answered = init.answered ?? 0;
    this.open = init.open ?? 0;
    this.comments = init.comments ?? 0;
    this.marks = init.marks ?? 0;
  }

  /** The sum of two counts. */
  plus(o) {
    return new SpecAnswerCounts({
      answered: this.answered + o.answered,
      open: this.open + o.open,
      comments: this.comments + o.comments,
      marks: this.marks + o.marks,
    });
  }

  /** The canonical JSON form. */
  toJson() {
    return {
      answered: this.answered,
      open: this.open,
      comments: this.comments,
      marks: this.marks,
    };
  }
}

/** The extraction of one document. */
class SpecAnswerExtract {
  /**
   * @param {object} init `label` (the document's label in `answers.md`, e.g.
   *   `tom_uam.sbp`), `qualifier` (the root's section id, written in front of
   *   a comment id: `SBP C-12`), `entries` (in document order).
   */
  constructor(init) {
    this.label = init.label;
    this.qualifier = init.qualifier;
    this.entries = init.entries;
  }

  /** The counts over `entries`. */
  get counts() {
    let a = 0;
    let o = 0;
    let c = 0;
    let m = 0;
    for (const e of this.entries) {
      switch (e.kind) {
        case SpecAnswerKind.ANSWERED:
          a++;
          break;
        case SpecAnswerKind.OPEN:
          o++;
          break;
        case SpecAnswerKind.COMMENT:
          c++;
          break;
        case SpecAnswerKind.MARK:
          m++;
          break;
      }
    }
    return new SpecAnswerCounts({ answered: a, open: o, comments: c, marks: m });
  }

  /** The canonical JSON form. */
  toJson() {
    return {
      label: this.label,
      qualifier: this.qualifier,
      entries: this.entries.map((e) => e.toJson()),
      counts: this.counts.toJson(),
    };
  }
}

const _heading = /^(#+) <!--\[([^\]]+)\]-->/;

/**
 * Extracts the annotations of `doc` (or of the subtree at `path`) with their
 * place in the document's Markdown rendition under `model`, in rendition
 * order (by line).
 */
function extractAnswers(model, doc, options) {
  const path = options.path ?? null;
  const root =
    model.roots.find((r) => doc.hasValuesUnder(r.sectionId ?? r.type)) ?? model.roots[0];
  const qualifier = root.sectionId ?? root.type;
  const rendition = new SpecDocumentMarkdown(model, doc).exportRootWithMap(root);
  const lines = rendition.markdown.split('\n');

  // The section-id chain of every heading line (1-based).
  const chains = new Map();
  const stack = [];
  for (let i = 0; i < lines.length; i++) {
    const m = _heading.exec(lines[i]);
    if (m === null) continue;
    const level = m[1].length;
    while (stack.length > 0 && stack[stack.length - 1][0] >= level) {
      stack.pop();
    }
    stack.push([level, m[2]]);
    chains.set(i + 1, stack.map((e) => e[1]).join(' > '));
  }

  const headingKeys = [...rendition.headingPaths.keys()].sort((a, b) => a - b);
  // The heading line of a value: the heading whose path is the longest
  // prefix of the value's path (on equal length, the first).
  const headingLine = (valuePath) => {
    let best = 0;
    let bestLen = -1;
    for (const l of headingKeys) {
      const hp = rendition.headingPaths.get(l);
      if ((valuePath === hp || valuePath.startsWith(`${hp}/`)) && hp.length > bestLen) {
        best = l;
        bestLen = hp.length;
      }
    }
    return best;
  };

  const chainAt = (line) => {
    for (let l = line; l >= 1; l--) {
      const c = chains.get(l);
      if (c !== undefined) return c;
    }
    return qualifier;
  };

  const claimed = new Set();
  // The rendition line of an annotation: the first unclaimed line after the
  // value's heading whose trimmed text is the annotation's first line. A
  // form field's first line renders behind its label (`Owner: …`).
  const locate = (valuePath, field, valueLine, firstLine) => {
    const h = headingLine(valuePath);
    const want = firstLine.trim();
    const labelled =
      field === null || valueLine !== 0
        ? null
        : `${field[0].toUpperCase()}${field.substring(1)}: ${want}`.trim();
    for (let i = h; i < lines.length; i++) {
      const l = i + 1;
      if (l <= h || claimed.has(l)) continue;
      const t = lines[i].trim();
      if (t === want || (labelled !== null && t === labelled)) {
        claimed.add(l);
        return l;
      }
    }
    return h === 0 ? 1 : h;
  };

  const inScope = (p) =>
    path === null || p === path || p.startsWith(`${path}/`);

  const api = new SpecReviewAnnotations(doc);
  // `list()` and `listMarks()` give the marks in the same order.
  const marks = api.listMarks();
  let markIndex = 0;
  const entries = [];
  for (const a of api.list()) {
    // Every mark consumes its listing entry, in scope or not, so marks in a
    // subtree keep their document-wide `M-<n>` ids.
    const m = a.kind === SpecReviewAnnotationKind.MARK ? marks[markIndex++] : null;
    if (!inScope(a.path)) continue;
    const value =
      (a.field === null ? doc.content(a.path) : doc.formField(a.path, a.field)) ?? '';
    const first = value.split('\n')[a.line];
    switch (a.kind) {
      case SpecReviewAnnotationKind.QUESTION: {
        const line = locate(a.path, a.field, a.line, first);
        entries.push(
          new SpecAnswerEntry({
            kind: a.open ? SpecAnswerKind.OPEN : SpecAnswerKind.ANSWERED,
            id: a.id,
            section: chainAt(line),
            line,
            path: a.path,
            field: a.field,
            topic: a.topic,
            combined: a.combined,
            text: a.text,
            answer: a.answer,
          }),
        );
        break;
      }
      case SpecReviewAnnotationKind.COMMENT: {
        const line = locate(a.path, a.field, a.line, first);
        entries.push(
          new SpecAnswerEntry({
            kind: SpecAnswerKind.COMMENT,
            id: a.id,
            section: chainAt(line),
            line,
            path: a.path,
            field: a.field,
            text: a.text,
            author: a.author,
          }),
        );
        break;
      }
      case SpecReviewAnnotationKind.MARK: {
        const line = locate(a.path, a.field, a.line, first);
        // A line holding several marks is found once; later marks on it
        // share the line.
        claimed.delete(line);
        entries.push(
          new SpecAnswerEntry({
            kind: SpecAnswerKind.MARK,
            id: m.id,
            section: chainAt(line),
            line,
            path: a.path,
            field: a.field,
            text: m.markup,
            markKind: a.markKind,
            oldText: m.oldText,
            newText: m.newText,
            comment: a.comment,
          }),
        );
        break;
      }
    }
  }
  // Rendition order: by line; entries on one line keep their order.
  const ordered = entries
    .map((e, i) => [i, e])
    .sort((x, y) => (x[1].line !== y[1].line ? x[1].line - y[1].line : x[0] - y[0]))
    .map((x) => x[1]);
  return new SpecAnswerExtract({ label: options.label, qualifier, entries: ordered });
}

/** What `answers.md` includes besides the answered questions and comments. */
class SpecAnswerRenderOptions {
  /**
   * @param {object} [init] `includeOpen` (list the questions still open),
   *   `includeMarks` (list the inline marks), `title` (default `Answers`).
   */
  constructor(init = {}) {
    this.includeOpen = init.includeOpen ?? false;
    this.includeMarks = init.includeMarks ?? false;
    this.title = init.title ?? 'Answers';
  }
}

/** A labelled value: `- **Label:** first line`, further lines indented two spaces. */
function _item(label, value) {
  const ls = value.split('\n');
  let b = `- **${label}:**`;
  if (ls[0].length > 0) b += ` ${ls[0]}`;
  for (const l of ls.slice(1)) {
    b += l.length === 0 ? '\n' : `\n  ${l}`;
  }
  return b;
}

function _countLine(c, o) {
  const parts = [
    `${c.answered} answered question${c.answered === 1 ? '' : 's'}`,
    `${c.open} open question${c.open === 1 ? '' : 's'}`,
    `${c.comments} comment${c.comments === 1 ? '' : 's'}`,
  ];
  if (o.includeMarks) parts.push(`${c.marks} inline mark${c.marks === 1 ? '' : 's'}`);
  return `${parts.join(', ')}.`;
}

function _entryHeading(x, e) {
  switch (e.kind) {
    case SpecAnswerKind.ANSWERED:
    case SpecAnswerKind.OPEN:
      return `${e.id} — ${e.topic}`;
    case SpecAnswerKind.COMMENT:
      return e.id === null ? `Comment without id (line ${e.line})` : `${x.qualifier} ${e.id}`;
    case SpecAnswerKind.MARK:
      return `${e.id} — ${e.markKind}`;
  }
}

/**
 * Renders `extracts` as a step folder's `answers.md`: deterministic, grouped
 * per document in the order given, entries in document order.
 */
function renderAnswers(extracts, options = new SpecAnswerRenderOptions()) {
  let total = new SpecAnswerCounts();
  for (const x of extracts) {
    total = total.plus(x.counts);
  }
  const out = [`# ${options.title}`, '', _countLine(total, options)];
  for (const x of extracts) {
    out.push('', `## ${x.label}`, '', _countLine(x.counts, options));
    const section = (heading, kind) => {
      const es = x.entries.filter((e) => e.kind === kind);
      out.push('', `### ${heading}`);
      if (es.length === 0) {
        out.push('', 'None.');
        return;
      }
      for (const e of es) {
        out.push(
          '',
          `#### ${_entryHeading(x, e)}`,
          '',
          _item('Section', `\`${e.section}\``),
          _item('Line', `${e.line}`),
        );
        if (e.field !== null) out.push(_item('Field', `\`${e.field}\``));
        switch (kind) {
          case SpecAnswerKind.ANSWERED:
          case SpecAnswerKind.OPEN:
            out.push(_item('Question', e.text));
            if (kind === SpecAnswerKind.ANSWERED) out.push(_item('Answer', e.answer));
            break;
          case SpecAnswerKind.COMMENT:
            if (e.author !== null) out.push(_item('Author', e.author));
            out.push(_item('Comment', e.text));
            break;
          case SpecAnswerKind.MARK:
            out.push(
              _item('Markup', `\`${e.text}\``),
              _item('Old', e.oldText ?? ''),
              _item('New', e.newText ?? ''),
            );
            if (e.comment !== null) out.push(_item('Note', e.comment));
            break;
        }
      }
    };
    section('Answered questions', SpecAnswerKind.ANSWERED);
    section('Comments', SpecAnswerKind.COMMENT);
    if (options.includeOpen) section('Open questions', SpecAnswerKind.OPEN);
    if (options.includeMarks) section('Inline marks', SpecAnswerKind.MARK);
  }
  return `${out.join('\n')}\n`;
}

module.exports = {
  SpecAnswerKind,
  SpecAnswerEntry,
  SpecAnswerCounts,
  SpecAnswerExtract,
  SpecAnswerRenderOptions,
  extractAnswers,
  renderAnswers,
};
