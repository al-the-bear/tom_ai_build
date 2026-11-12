/**
 * Merging the reviewed copies of a team review (SOM §11.9.9) into one
 * document in the team notation of §11.9.8: who proposed, voted for and
 * answered what, and where two members changed the same passage differently.
 *
 * {@link mergeReviews} merges a SOM document ({@link SpecDocument}, by model
 * path, list items matched by section id) or a plain annotated Markdown file
 * (by heading path). Both share one engine that works value by value; only the
 * way values are found, and the SOM-only structure and revision entry, differ.
 *
 * The engine is built on the review-annotation building blocks: the paragraph
 * split and the mark decisions of {@link SpecReviewAnnotations}, `markChangeText`
 * for edits written as plain text, the individual-answer rules of `setAnswer`,
 * and the list-item id generation of `generateListItemSectionId`.
 */

import { SpecDocument } from './spec_document';
import { FormFieldSpec, SpecClass, SpecField, SpecFieldKind, SpecModel } from './spec_model';
import { SpecNodeKind, SpecReflection } from './spec_reflection';
import { specParentPath } from './spec_paths';
import { MarkdownFenceTracker } from './spec_document_markdown';
import { effectiveListItemSectionId, generateListItemSectionId } from './spec_section_id';
import {
  ReviewMark,
  ReviewPiece,
  SpecMarkVote,
  SpecQuestionDraft,
  SpecReviewAnnotationKind,
  applyInlineMarksText,
  decideReviewMarks,
  formatCommentBlock,
  formatConflictBlock,
  formatQuestionBlock,
  markChangeText,
  reviewMarks,
  reviewPieces,
  reviewTeamAnswerTimes,
  reviewTeamAnswers,
  setIndividualAnswerText,
  transplantEdits,
  withAttribution,
} from './spec_review_annotations';

// ---------------------------------------------------------------------------
// Inputs, report and result.
// ---------------------------------------------------------------------------

/** A member of a review team (SOM §11.9.8). */
export interface SpecReviewMember {
  /** The member id: lowercase letters, digits and `_`. */
  memberId: string;
  displayName: string;
  role: string;
}

/** One returned copy: its reviewer and the copy's document. */
export interface SpecReviewedCopy<D> extends SpecReviewMember {
  document: D;
}

/** The options of {@link mergeReviews}. */
export interface SpecReviewMergeOptions {
  /** The members the round started with, in team order; a copy of anybody else is a guest's. */
  team: SpecReviewMember[];
  /** The round's date (ISO 8601): the revision entry's date, and the date of every generated list-item id. */
  date: string;
  /** The revision entry's author. */
  author: string;
  /** The id prefix of the questions the merge writes. Default `RQ`. */
  questionPrefix?: string;
  /** The model of a SOM document; required when merging {@link SpecDocument}s. */
  model?: SpecModel;
}

/** Thrown when a copy's structure does not fit the base; nothing is merged. */
export class SpecReviewMergeError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'SpecReviewMergeError';
    Object.setPrototypeOf(this, SpecReviewMergeError.prototype);
  }
}

/** A reviewer as the report lists it. */
export interface SpecMergeReviewer extends SpecReviewMember {
  guest: boolean;
}

/** A conflict block the merge wrote. */
export interface SpecMergeConflict {
  id: string;
  path: string;
  field: string | null;
  /** The unit's index among the value's text paragraphs; null for a whole value or a structural conflict. */
  paragraph: number | null;
  members: string[];
}

/** A base mark left with votes. */
export interface SpecMergeVotes {
  path: string;
  field: string | null;
  /** The mark as merged, its token carrying the votes. */
  markup: string;
  votes: SpecMarkVote[];
}

/** A base mark every copy decided the same way, applied or dropped. */
export interface SpecMergeUnanimous {
  path: string;
  field: string | null;
  /** The mark as the base wrote it. */
  markup: string;
  decision: 'accept' | 'reject';
  result: string;
}

/** A base question the copies answered. */
export interface SpecMergeAnswers {
  questionId: string;
  members: string[];
}

/** A new comment. */
export interface SpecMergeComment {
  id: string;
  author: string;
  path: string;
  field: string | null;
}

/** An item a copy added. */
export interface SpecMergeAddition {
  path: string;
  members: string[];
}

/** The question proposing a guest for the next round's team. */
export interface SpecMergeGuestQuestion {
  id: string;
  memberId: string;
  /** Where it was written; null when the document has no place for it. */
  path: string | null;
}

/** The draft revision entry the merge appended. */
export interface SpecMergeRevision {
  path: string;
  version: string;
}

/** The merge report (SOM §11.9.9), every list in merged document order. */
export class SpecReviewMergeReport {
  readonly reviewers: SpecMergeReviewer[] = [];
  readonly conflicts: SpecMergeConflict[] = [];
  readonly votes: SpecMergeVotes[] = [];
  readonly unanimous: SpecMergeUnanimous[] = [];
  readonly answers: SpecMergeAnswers[] = [];
  readonly comments: SpecMergeComment[] = [];
  readonly additions: SpecMergeAddition[] = [];
  readonly guestQuestions: SpecMergeGuestQuestion[] = [];
  revision: SpecMergeRevision | null = null;

  /** The canonical JSON form the conformance corpus pins. */
  toJson(): Record<string, unknown> {
    return {
      reviewers: this.reviewers.map((r) => ({
        memberId: r.memberId,
        displayName: r.displayName,
        role: r.role,
        guest: r.guest,
      })),
      conflicts: this.conflicts.map((c) => ({
        id: c.id,
        path: c.path,
        field: c.field,
        paragraph: c.paragraph,
        members: c.members,
      })),
      votes: this.votes.map((v) => ({
        path: v.path,
        field: v.field,
        markup: v.markup,
        votes: v.votes.map((x) => x.toJson()),
      })),
      unanimous: this.unanimous.map((u) => ({
        path: u.path,
        field: u.field,
        markup: u.markup,
        decision: u.decision,
        result: u.result,
      })),
      answers: this.answers.map((a) => ({ questionId: a.questionId, members: a.members })),
      comments: this.comments.map((c) => ({
        id: c.id,
        author: c.author,
        path: c.path,
        field: c.field,
      })),
      additions: this.additions.map((a) => ({ path: a.path, members: a.members })),
      guestQuestions: this.guestQuestions.map((g) => ({
        id: g.id,
        memberId: g.memberId,
        path: g.path,
      })),
      revision: this.revision === null ? null : { ...this.revision },
    };
  }
}

/** The merged document and its report. */
export class SpecReviewMergeResult<D> {
  constructor(
    readonly merged: D,
    readonly report: SpecReviewMergeReport,
  ) {}
}

/**
 * Merges the reviewed `copies` of `base` (SOM §11.9.9). Neither the base nor
 * a copy is written. A SOM document needs `options.model`; a copy whose
 * structure does not fit the base is refused with {@link SpecReviewMergeError}.
 */
export function mergeReviews(
  base: SpecDocument,
  copies: Array<SpecReviewedCopy<SpecDocument>>,
  options: SpecReviewMergeOptions,
): SpecReviewMergeResult<SpecDocument>;
export function mergeReviews(
  base: string,
  copies: Array<SpecReviewedCopy<string>>,
  options: SpecReviewMergeOptions,
): SpecReviewMergeResult<string>;
export function mergeReviews(
  base: SpecDocument | string,
  copies: Array<SpecReviewedCopy<SpecDocument | string>>,
  options: SpecReviewMergeOptions,
): SpecReviewMergeResult<SpecDocument | string> {
  if (typeof base === 'string') {
    return _mergeMarkdown(base, copies as Array<SpecReviewedCopy<string>>, options);
  }
  if (options.model === undefined) {
    throw new SpecReviewMergeError('merging a SOM document needs options.model');
  }
  return _mergeSom(base, copies as Array<SpecReviewedCopy<SpecDocument>>, options, options.model);
}

// ---------------------------------------------------------------------------
// The engine: one value at a time.
// ---------------------------------------------------------------------------

/** Ids the merge writes before it can number them: renumbered in merged document order at the end. */
const _PLACEHOLDER = /\u0001([CX])([0-9]+)\u0001/g;

/** One value to merge, located in the merged document. */
interface _MergeValue {
  path: string;
  field: string | null;
  base: string;
  /** Per copy, in round order; null when the copy holds no such value (it removed the item). */
  copies: Array<string | null>;
  /** A typed leaf (number, bool, enum, code): never marked, any change is a conflict. */
  typed: boolean;
  /** Where a conflict about a form field or a typed leaf goes; null for a content value. */
  conflictHome: string | null;
}

/** What one copy did to one unit (SOM §11.9.9, steps 1–4). */
interface _UnitReading {
  changed: boolean;
  /** The reviewer's text. */
  t: string;
  /** The change as it is written into the merged document. */
  written: string;
  /** The copy's votes, by the index of the base unit's mark. */
  votes: Map<number, boolean>;
}

/** The state one merge carries from value to value. */
class _MergeContext {
  readonly report = new SpecReviewMergeReport();
  /** Blocks to append to the end of a content value, by its key. */
  readonly appends = new Map<string, string[]>();
  readonly members: string[];
  private _nextPlaceholder = 0;
  /** Placeholder → report entry, filled in when the ids are numbered. */
  readonly pendingConflicts = new Map<string, SpecMergeConflict>();
  readonly pendingComments = new Map<string, SpecMergeComment>();

  constructor(
    readonly copies: SpecReviewMember[],
    readonly baseCommentIds: Set<string>,
    readonly baseQuestionIds: Set<string>,
  ) {
    this.members = copies.map((c) => c.memberId);
  }

  placeholder(kind: 'C' | 'X'): string {
    return `\u0001${kind}${++this._nextPlaceholder}\u0001`;
  }

  append(key: string, block: string): void {
    const list = this.appends.get(key) ?? [];
    list.push(block);
    this.appends.set(key, list);
  }

  /** Writes a conflict block with a placeholder id and records it for the report. */
  conflict(init: {
    topic: string;
    text: string;
    base: string;
    groups: Array<{ text: string; members: string[] }>;
    path: string;
    field: string | null;
    paragraph: number | null;
  }): string {
    const id = this.placeholder('X');
    this.pendingConflicts.set(id, {
      id,
      path: init.path,
      field: init.field,
      paragraph: init.paragraph,
      members: init.groups.flatMap((g) => g.members),
    });
    return formatConflictBlock({
      id,
      topic: init.topic,
      text: init.text,
      base: init.base,
      alternatives: init.groups.map((g, k) => ({
        letter: String.fromCharCode(0x61 + k),
        members: g.members,
        text: g.text,
      })),
    }).join('\n');
  }
}

/** Groups the changed readings by their text `t`, in order of first appearance. */
function _changeGroups(
  readings: Array<_UnitReading | null>,
  members: string[],
): Array<{ text: string; members: string[]; first: _UnitReading }> {
  const groups: Array<{ text: string; members: string[]; first: _UnitReading }> = [];
  readings.forEach((r, k) => {
    if (r === null || !r.changed) return;
    const g = groups.find((x) => x.text === r.t);
    if (g === undefined) groups.push({ text: r.t, members: [members[k]], first: r });
    else g.members.push(members[k]);
  });
  return groups;
}

/** Aligns two mark lists by their markup (longest common subsequence): index in `a` → index in `b`. */
function _alignMarks(a: ReviewMark[], b: ReviewMark[]): Map<number, number> {
  const n = a.length;
  const m = b.length;
  const l: number[][] = [];
  for (let i = 0; i <= n; i++) l.push(new Array<number>(m + 1).fill(0));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      l[i][j] =
        a[i].markup === b[j].markup ? l[i + 1][j + 1] + 1 : Math.max(l[i + 1][j], l[i][j + 1]);
    }
  }
  const out = new Map<number, number>();
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (a[i].markup === b[j].markup) {
      out.set(i++, j++);
    } else if (l[i + 1][j] >= l[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return out;
}

/**
 * The most base marks a unit may have that a copy no longer holds as written:
 * the combinations of step 2 grow as 2^n. Beyond it the copy's unit is read
 * as an edit (step 4).
 */
const _MAX_DECIDED_MARKS = 16;

/**
 * The first combination of decisions on `b`'s marks (step 2) whose result is
 * `target`, or null. Each mark takes leave, accept, reject in that order, the
 * first mark varying slowest. A mark the copy still holds as written can only
 * have been left, and a mark it no longer holds cannot have been, so only the
 * others vary — the same first combination, found without trying the rest.
 */
function _findVotes(b: string, marks: ReviewMark[], left: Set<number>, target: string): Map<number, boolean> | null {
  const free = marks.map((_, i) => i).filter((i) => !left.has(i));
  if (free.length > _MAX_DECIDED_MARKS) return null;
  for (let combo = 0; combo < 1 << free.length; combo++) {
    const decisions = new Map<number, boolean>();
    free.forEach((mark, k) => {
      // Bit set: reject; the first mark is the most significant bit.
      decisions.set(mark, ((combo >> (free.length - 1 - k)) & 1) === 0);
    });
    if (decideReviewMarks(b, decisions) === target) return decisions;
  }
  return null;
}

/** Step 4: the copy edited text that holds base marks; it casts no votes. */
function _readAsEdit(b: string, c: string): _UnitReading {
  const t = applyInlineMarksText(c, { accept: true });
  return {
    changed: t !== b,
    t,
    written: markChangeText(applyInlineMarksText(b, { accept: false }), t).text,
    votes: new Map(),
  };
}

/** What copy unit `c` did to base unit `b` (SOM §11.9.9, steps 1–4). */
function _readUnit(b: string, c: string): _UnitReading {
  if (c === b) return { changed: false, t: b, written: b, votes: new Map() };
  const baseMarks = reviewMarks(b);
  const copyMarks = reviewMarks(c);
  const kept = _alignMarks(copyMarks, baseMarks);
  // 1. Own marks: the copy's marks that are not the base's.
  const own = copyMarks.map((_, i) => i).filter((i) => !kept.has(i));
  const reject = new Map(own.map((i) => [i, false] as [number, boolean]));
  const accept = new Map(own.map((i) => [i, true] as [number, boolean]));
  // 2. Votes: the decisions on the base marks that give c with its own marks rejected.
  const cPrime = decideReviewMarks(c, reject);
  const votes = _findVotes(b, baseMarks, new Set(kept.values()), cPrime);
  if (votes === null) return _readAsEdit(b, c);
  if (own.length === 0) return { changed: false, t: b, written: b, votes };
  // 3. Change: the own marks, carried over to the base text where marks were voted on.
  const ownAccepted = decideReviewMarks(c, accept);
  const written = votes.size === 0 ? c : transplantEdits(cPrime, c, b);
  const t = votes.size === 0 ? ownAccepted : transplantEdits(cPrime, ownAccepted, b);
  if (written === null || t === null) return _readAsEdit(b, c);
  return { changed: t !== b, t, written, votes };
}

/** `written` with every mark that is not one of the base's attributed to `members`. */
function _attribute(written: string, baseMarks: ReviewMark[], members: string[]): string {
  const marks = reviewMarks(written);
  const base = _alignMarks(marks, baseMarks);
  let out = written;
  for (let k = marks.length - 1; k >= 0; k--) {
    if (!base.has(k)) out = withAttribution(out, marks[k], members, marks[k].votes);
  }
  return out;
}

/** Whether a mark is a change, which alone takes votes. */
function _isChange(m: ReviewMark): boolean {
  return m.kind === 'insertion' || m.kind === 'deletion' || m.kind === 'substitution';
}

/**
 * `text` with the copies' votes on the base marks it holds: a base mark every
 * copy decided the same way is applied (accept) or dropped (reject); any other
 * voted change mark gets the votes in its token, `agent` as author when it had
 * no token. A highlight or comment mark takes no votes and stays.
 */
function _applyVotes(
  text: string,
  baseMarks: ReviewMark[],
  readings: Array<_UnitReading | null>,
  v: _MergeValue,
  ctx: _MergeContext,
): string {
  const marks = reviewMarks(text);
  const base = _alignMarks(marks, baseMarks);
  const taking = readings.filter((r) => r !== null).length;
  const votes: SpecMergeVotes[] = [];
  const unanimous: SpecMergeUnanimous[] = [];
  let out = text;
  for (let k = marks.length - 1; k >= 0; k--) {
    const b = base.get(k);
    if (b === undefined) continue;
    const cast: SpecMarkVote[] = [];
    readings.forEach((r, i) => {
      const d = r?.votes.get(b);
      if (d !== undefined) cast.push(new SpecMarkVote(ctx.members[i], d ? 'accept' : 'reject'));
    });
    if (cast.length === 0) continue;
    const m = marks[k];
    if (cast.length === taking && cast.every((x) => x.vote === cast[0].vote)) {
      const accept = cast[0].vote === 'accept';
      out = decideReviewMarks(out, new Map([[k, accept]]));
      unanimous.unshift({
        path: v.path,
        field: v.field,
        markup: baseMarks[b].markup,
        decision: cast[0].vote,
        result: accept ? baseMarks[b].accepted : baseMarks[b].rejected,
      });
      continue;
    }
    if (!_isChange(m)) continue;
    const authors = m.end > m.bodyEnd ? m.authors : ['agent'];
    const merged = [...m.votes.filter((x) => !cast.some((y) => y.member === x.member)), ...cast];
    out = withAttribution(out, m, authors, merged);
    votes.unshift({
      path: v.path,
      field: v.field,
      markup: reviewMarks(out)[k].markup,
      votes: merged,
    });
  }
  ctx.report.votes.push(...votes);
  ctx.report.unanimous.push(...unanimous);
  return out;
}

/**
 * One unit merged: the base text with votes when no copy changed it, the one
 * change attributed to every member who made it, or the base text and a
 * conflict block when the copies changed it differently.
 */
function _mergeUnit(
  b: string,
  units: Array<string | null>,
  paragraph: number | null,
  v: _MergeValue,
  ctx: _MergeContext,
): { text: string; conflict: string | null } {
  const readings = units.map((c) => (c === null ? null : _readUnit(b, c)));
  const groups = _changeGroups(readings, ctx.members);
  const baseMarks = reviewMarks(b);
  let text = b;
  if (groups.length === 1) text = _attribute(groups[0].first.written, baseMarks, groups[0].members);
  text = _applyVotes(text, baseMarks, readings, v, ctx);
  if (groups.length < 2) return { text, conflict: null };
  const where = `${v.path}${v.field === null ? '' : ` ${v.field}`}`;
  const conflict = ctx.conflict({
    topic: 'Conflicting changes',
    text: paragraph === null ? where : `${where}, paragraph ${paragraph}`,
    base: b,
    groups,
    path: v.path,
    field: v.field,
    paragraph,
  });
  return { text, conflict };
}

/**
 * A typed leaf: it cannot hold a mark, so a change by any copy is a `Value
 * changed` conflict at the leaf's home, the base value kept.
 */
function _mergeTyped(v: _MergeValue, ctx: _MergeContext): string {
  const readings = v.copies.map((c) =>
    c === null ? null : { changed: c !== v.base, t: c, written: c, votes: new Map<number, boolean>() },
  );
  const groups = _changeGroups(readings, ctx.members);
  if (groups.length > 0 && v.conflictHome !== null) {
    ctx.append(
      v.conflictHome,
      ctx.conflict({
        topic: 'Value changed',
        text: `${v.path}${v.field === null ? '' : ` ${v.field}`}`,
        base: v.base,
        groups,
        path: v.path,
        field: v.field,
        paragraph: null,
      }),
    );
  }
  return v.base;
}

/** A form-field value: always one unit; its conflict goes to the end of the form's preamble. */
function _mergeField(v: _MergeValue, ctx: _MergeContext): string {
  const { text, conflict } = _mergeUnit(v.base, v.copies, null, v, ctx);
  if (conflict !== null && v.conflictHome !== null) ctx.append(v.conflictHome, conflict);
  return text;
}

/** Whether a copy's block is new: a comment whose id the base lacks, a question block with no base question. */
function _isNewBlock(piece: ReviewPiece, ctx: _MergeContext): boolean {
  if (piece.kind === SpecReviewAnnotationKind.COMMENT) {
    return piece.id === null || !ctx.baseCommentIds.has(piece.id);
  }
  if (piece.kind === SpecReviewAnnotationKind.QUESTION) {
    return piece.questionIds.length > 0 && piece.questionIds.every((id) => !ctx.baseQuestionIds.has(id));
  }
  return false;
}

/**
 * The anchor of each block of a value: the index of the text paragraph it
 * follows (-1: before every one). In whole-value mode every block that
 * follows text follows the one unit.
 */
function _anchors(pieces: ReviewPiece[], whole: boolean): number[] {
  let texts = -1;
  return pieces.map((p) => {
    if (p.kind === 'text') {
      texts++;
      return texts;
    }
    return whole ? Math.min(texts, 0) : texts;
  });
}

/**
 * A content value: split into text paragraphs and annotation blocks, merged
 * unit by unit, the copies' new comments and questions placed after the unit
 * they followed. A copy whose text-paragraph count differs from the base's
 * makes the whole text one unit, for every copy.
 */
function _mergeContent(v: _MergeValue, ctx: _MergeContext): string {
  const basePieces = reviewPieces(v.base);
  const copyPieces = v.copies.map((c) => (c === null ? null : reviewPieces(c)));
  const textsOf = (ps: ReviewPiece[]): string[] => ps.filter((p) => p.kind === 'text').map((p) => p.text);
  const baseTexts = textsOf(basePieces);
  const whole = copyPieces.some((ps) => ps !== null && textsOf(ps).length !== baseTexts.length);
  const unitsOf = (ps: ReviewPiece[]): string[] => (whole ? [textsOf(ps).join('\n\n')] : textsOf(ps));
  const baseUnits = unitsOf(basePieces);
  const copyUnits = copyPieces.map((ps) => (ps === null ? null : unitsOf(ps)));

  // Blocks by anchor: the base's first, then each copy's new ones in round order.
  const after = new Map<number, string[]>();
  const place = (anchor: number, block: string): void => {
    after.set(anchor, [...(after.get(anchor) ?? []), block]);
  };
  const baseAnchors = _anchors(basePieces, whole);
  basePieces.forEach((p, k) => {
    if (p.kind !== 'text') place(baseAnchors[k], p.text);
  });
  copyPieces.forEach((ps, i) => {
    if (ps === null) return;
    const anchors = _anchors(ps, false);
    ps.forEach((p, k) => {
      if (p.kind === 'text' || !_isNewBlock(p, ctx)) return;
      place(whole ? baseUnits.length - 1 : anchors[k], _newBlock(p, ctx.members[i], v, ctx));
    });
  });

  const out: string[] = [...(after.get(-1) ?? [])];
  baseUnits.forEach((b, u) => {
    const units = copyUnits.map((cs) => (cs === null ? null : cs[u]));
    const { text, conflict } = _mergeUnit(b, units, whole ? null : u, v, ctx);
    if (text.length > 0) out.push(text);
    if (conflict !== null) out.push(conflict);
    out.push(...(after.get(u) ?? []));
  });
  return out.join('\n\n');
}

/** A copy's new block as merged: a comment renumbered and attributed, a question as written. */
function _newBlock(p: ReviewPiece, member: string, v: _MergeValue, ctx: _MergeContext): string {
  if (p.kind !== SpecReviewAnnotationKind.COMMENT) return p.text;
  const id = ctx.placeholder('C');
  const author = p.author ?? member;
  ctx.pendingComments.set(id, { id, author, path: v.path, field: v.field });
  return formatCommentBlock({ id, text: p.commentText, author, changedAt: p.changedAt }).join('\n');
}

/** One value merged; the base text when no copy differs from it. */
function _mergeValue(v: _MergeValue, ctx: _MergeContext): string {
  if (v.copies.every((c) => c === null || c === v.base)) return v.base;
  if (v.typed) return _mergeTyped(v, ctx);
  if (v.field !== null) return _mergeField(v, ctx);
  return _mergeContent(v, ctx);
}

// ---------------------------------------------------------------------------
// Shared phases over the merged texts.
// ---------------------------------------------------------------------------

/** The merged document's values, by key, in merged document order. */
interface _Texts {
  keys(): string[];
  get(key: string): string;
  set(key: string, value: string): void;
}

/** Appends the collected blocks (field and structural conflicts) to the end of their values. */
function _applyAppends(texts: _Texts, ctx: _MergeContext): void {
  for (const [key, blocks] of ctx.appends) {
    const value = texts.get(key);
    texts.set(key, [...(value.length > 0 ? [value] : []), ...blocks].join('\n\n'));
  }
}

/** The highest `<prefix>-<n>` of the texts' annotations of one kind. */
function _highestId(texts: string[], prefix: string, kinds: string[]): number {
  let high = 0;
  for (const t of texts) {
    for (const p of reviewPieces(t)) {
      if (!kinds.includes(p.kind)) continue;
      const ids = p.kind === SpecReviewAnnotationKind.QUESTION ? p.questionIds : [p.id];
      for (const id of ids) {
        if (id !== null && id.startsWith(`${prefix}-`)) {
          const n = parseInt(id.substring(prefix.length + 1), 10);
          if (n > high) high = n;
        }
      }
    }
  }
  return high;
}

/**
 * Numbers the new comments and conflicts in merged document order, above the
 * base's highest `C-<n>` and `X-<n>`, and fills their report entries in.
 */
function _numberIds(texts: _Texts, baseTexts: string[], ctx: _MergeContext): void {
  const next = {
    C: _highestId(baseTexts, 'C', [SpecReviewAnnotationKind.COMMENT]),
    X: _highestId(baseTexts, 'X', [SpecReviewAnnotationKind.CONFLICT]),
  };
  for (const key of texts.keys()) {
    const value = texts.get(key);
    if (!value.includes('\u0001')) continue;
    texts.set(
      key,
      value.replace(_PLACEHOLDER, (placeholder, kind: 'C' | 'X') => {
        const id = `${kind}-${++next[kind]}`;
        if (kind === 'C') {
          ctx.report.comments.push({ ...(ctx.pendingComments.get(placeholder) as SpecMergeComment), id });
        } else {
          ctx.report.conflicts.push({ ...(ctx.pendingConflicts.get(placeholder) as SpecMergeConflict), id });
        }
        return id;
      }),
    );
  }
}

/**
 * Writes each copy's team answer to a base question, where it differs from
 * the base's, as that member's individual answer (copies in round order),
 * with the copy's answer time (SOM §11.9.10).
 */
function _mergeAnswers(
  texts: _Texts,
  baseTexts: string[],
  copyTexts: string[][],
  ctx: _MergeContext,
): void {
  const baseAnswers = new Map<string, string>();
  for (const t of baseTexts) {
    for (const [id, a] of reviewTeamAnswers(t)) if (!baseAnswers.has(id)) baseAnswers.set(id, a);
  }
  const copyAnswers = copyTexts.map((ts) => {
    const m = new Map<string, string>();
    for (const t of ts) for (const [id, a] of reviewTeamAnswers(t)) if (!m.has(id)) m.set(id, a);
    return m;
  });
  const copyTimes = copyTexts.map((ts) => {
    const m = new Map<string, string | null>();
    for (const t of ts) {
      for (const [id, at] of reviewTeamAnswerTimes(t)) if (!m.has(id)) m.set(id, at);
    }
    return m;
  });
  for (const [id, baseAnswer] of baseAnswers) {
    const members: string[] = [];
    copyAnswers.forEach((answers, i) => {
      const a = answers.get(id);
      if (a === undefined || a === baseAnswer || a.length === 0) return;
      for (const key of texts.keys()) {
        const written = setIndividualAnswerText(
          texts.get(key),
          id,
          ctx.members[i],
          a,
          copyTimes[i].get(id) ?? null,
        );
        if (written === null) continue;
        texts.set(key, written);
        members.push(ctx.members[i]);
        break;
      }
    });
    if (members.length > 0) ctx.report.answers.push({ questionId: id, members });
  }
}

/** The question proposing guest `g` for the next round's team. */
function _guestQuestion(id: string, g: SpecReviewMember): string {
  const who = g.role.length > 0 ? `${g.displayName}, ${g.role}` : g.displayName;
  return formatQuestionBlock(
    new SpecQuestionDraft({
      id,
      topic: `Guest ${g.memberId}`,
      text: `add ${g.memberId} (${who}) to the review team?`,
      options: ['(a) yes, from the next round on', '(b) no, this round only'],
      recommended: 'a',
    }),
  ).join('\n');
}

/**
 * Lists the reviewers and writes one question per guest to the end of the
 * value at `home` (null: the report only), numbered above the base's highest
 * question id with the prefix.
 */
function _addGuests(
  texts: _Texts,
  baseTexts: string[],
  copies: SpecReviewMember[],
  options: SpecReviewMergeOptions,
  home: { key: string; path: string } | null,
  ctx: _MergeContext,
): void {
  const team = new Set(options.team.map((m) => m.memberId));
  const prefix = options.questionPrefix ?? 'RQ';
  let n = _highestId(baseTexts, prefix, [SpecReviewAnnotationKind.QUESTION]);
  for (const c of copies) {
    const guest = !team.has(c.memberId);
    ctx.report.reviewers.push({
      memberId: c.memberId,
      displayName: c.displayName,
      role: c.role,
      guest,
    });
    if (!guest) continue;
    const id = `${prefix}-${++n}`;
    ctx.report.guestQuestions.push({ id, memberId: c.memberId, path: home?.path ?? null });
    if (home === null) continue;
    const value = texts.get(home.key);
    texts.set(home.key, [...(value.length > 0 ? [value] : []), _guestQuestion(id, c)].join('\n\n'));
  }
}

/** The ids of the comments and questions of `texts`. */
function _blockIds(texts: string[]): { comments: Set<string>; questions: Set<string> } {
  const comments = new Set<string>();
  const questions = new Set<string>();
  for (const t of texts) {
    for (const p of reviewPieces(t)) {
      if (p.kind === SpecReviewAnnotationKind.COMMENT && p.id !== null) comments.add(p.id);
      for (const q of p.questionIds) questions.add(q);
    }
  }
  return { comments, questions };
}

/** The phases after the structure, shared by both formats. */
function _mergeTexts(
  values: _MergeValue[],
  keyOf: (v: _MergeValue) => string,
  texts: _Texts,
  baseTexts: string[],
  copyTexts: string[][],
  copies: SpecReviewMember[],
  options: SpecReviewMergeOptions,
  home: { key: string; path: string } | null,
  ctx: _MergeContext,
): void {
  for (const v of values) {
    const merged = _mergeValue(v, ctx);
    if (merged !== v.base) texts.set(keyOf(v), merged);
  }
  _applyAppends(texts, ctx);
  _numberIds(texts, baseTexts, ctx);
  _mergeAnswers(texts, baseTexts, copyTexts, ctx);
  _addGuests(texts, baseTexts, copies, options, home, ctx);
}

// ---------------------------------------------------------------------------
// Plain Markdown: values by heading path.
// ---------------------------------------------------------------------------

/** A Markdown file cut at its headings: body `i` follows heading `i - 1` (body 0 precedes them all). */
interface _MarkdownSplit {
  headings: string[];
  /** The heading path of each body, its heading texts joined by ` > ` (body 0: ``). */
  paths: string[];
  bodies: string[][];
}

const _HEADING = /^(#{1,6})(?:[ \t]+(.*?))?[ \t]*$/;

function _splitMarkdown(text: string): _MarkdownSplit {
  const out: _MarkdownSplit = { headings: [], paths: [''], bodies: [[]] };
  const fence = new MarkdownFenceTracker();
  const stack: Array<[number, string]> = [];
  for (const line of text.split('\n')) {
    const wasFenced = fence.inFence;
    fence.feed(line);
    const h = wasFenced || fence.inFence ? null : _HEADING.exec(line);
    if (h === null) {
      out.bodies[out.bodies.length - 1].push(line);
      continue;
    }
    const level = h[1].length;
    while (stack.length > 0 && stack[stack.length - 1][0] >= level) stack.pop();
    stack.push([level, h[2] ?? '']);
    out.headings.push(line);
    out.paths.push(stack.map((s) => s[1]).join(' > '));
    out.bodies.push([]);
  }
  return out;
}

/** A body's blank lines before and after its value, and the value. */
function _bodyParts(lines: string[]): { lead: number; trail: number; value: string } {
  let lead = 0;
  while (lead < lines.length && lines[lead].trim().length === 0) lead++;
  if (lead === lines.length) return { lead, trail: 0, value: '' };
  let trail = 0;
  while (lines[lines.length - 1 - trail].trim().length === 0) trail++;
  return { lead, trail, value: lines.slice(lead, lines.length - trail).join('\n') };
}

/** The body lines for a new value, keeping the body's blank lines around it. */
function _bodyLines(lines: string[], value: string, afterHeading: boolean): string[] {
  const parts = _bodyParts(lines);
  if (value === parts.value) return lines;
  if (value.length === 0) return lines.slice(0, parts.lead);
  if (parts.value.length === 0) {
    return [...(afterHeading ? [''] : []), ...value.split('\n'), ...(lines.length > 0 ? [''] : [])];
  }
  return [
    ...lines.slice(0, parts.lead),
    ...value.split('\n'),
    ...lines.slice(lines.length - parts.trail),
  ];
}

function _mergeMarkdown(
  base: string,
  copies: Array<SpecReviewedCopy<string>>,
  options: SpecReviewMergeOptions,
): SpecReviewMergeResult<string> {
  const b = _splitMarkdown(base);
  const cs = copies.map((c) => _splitMarkdown(c.document));
  cs.forEach((c, i) => {
    if (c.headings.length !== b.headings.length || c.headings.some((h, k) => h.trim() !== b.headings[k].trim())) {
      throw new SpecReviewMergeError(
        `the copy of ${copies[i].memberId} has other headings than the base`,
      );
    }
  });
  const baseTexts = b.bodies.map((lines) => _bodyParts(lines).value);
  const copyTexts = cs.map((c) => c.bodies.map((lines) => _bodyParts(lines).value));
  const merged = baseTexts.slice();
  const texts: _Texts = {
    keys: () => merged.map((_, k) => String(k)),
    get: (key) => merged[Number(key)],
    set: (key, value) => {
      merged[Number(key)] = value;
    },
  };
  const ids = _blockIds(baseTexts);
  const ctx = new _MergeContext(copies, ids.comments, ids.questions);
  const values: _MergeValue[] = baseTexts.map((t, k) => ({
    path: b.paths[k],
    field: null,
    base: t,
    copies: copyTexts.map((ct) => ct[k]),
    typed: false,
    conflictHome: null,
  }));
  const first = b.headings.length > 0 ? 1 : 0;
  _mergeTexts(
    values,
    (v) => String(values.indexOf(v)),
    texts,
    baseTexts,
    copyTexts,
    copies,
    options,
    { key: String(first), path: b.paths[first] },
    ctx,
  );
  const lines: string[] = [];
  b.bodies.forEach((body, k) => {
    if (k > 0) lines.push(b.headings[k - 1]);
    lines.push(..._bodyLines(body, merged[k], k > 0));
  });
  return new SpecReviewMergeResult(lines.join('\n'), ctx.report);
}

// ---------------------------------------------------------------------------
// SOM documents: values by model path, list items by section id.
// ---------------------------------------------------------------------------

/**
 * A document's paths with every list item named by its section id instead of
 * its position (`DEMO/CARD-LST#CARD-BETA/content`), so the same item has the
 * same name in the base, in every copy and in the merged document.
 */
class _CanonicalPaths {
  private readonly _listOf = new Map<string, string>();
  private readonly _ids = new Map<string, string>();
  private readonly _byCanonical = new Map<string, string>();
  private readonly _memo = new Map<string, string>();

  constructor(
    readonly doc: SpecDocument,
    refl: SpecReflection,
  ) {
    for (const list of doc.listPaths) {
      const field = refl.resolve(list)?.field ?? null;
      doc.listItems(list).forEach((item, k) => {
        this._listOf.set(item, list);
        this._ids.set(
          item,
          effectiveListItemSectionId(
            doc.itemSectionId(item),
            field?.sectionIdPattern ?? null,
            k + 1,
            field?.name ?? list,
          ),
        );
      });
    }
    for (const item of this._listOf.keys()) this._byCanonical.set(this.of(item), item);
  }

  /** The item paths of the list at `list`, in order. */
  items(list: string): string[] {
    return this.doc.listItems(list);
  }

  /** The section id an item is matched by. */
  idOf(item: string): string {
    return this._ids.get(item) as string;
  }

  /** The canonical form of `path`. */
  of(path: string): string {
    const memo = this._memo.get(path);
    if (memo !== undefined) return memo;
    const segs = path.split('/');
    let out = path;
    for (let k = segs.length; k > 0; k--) {
      const prefix = segs.slice(0, k).join('/');
      const list = this._listOf.get(prefix);
      if (list === undefined) continue;
      const rest = segs.slice(k).join('/');
      out = `${this.of(list)}#${this.idOf(prefix)}${rest.length > 0 ? `/${rest}` : ''}`;
      break;
    }
    this._memo.set(path, out);
    return out;
  }

  /** The document's path for a canonical path, or null when the document lacks one of its items. */
  pathOf(canonical: string): string | null {
    const segs = canonical.split('/');
    for (let k = segs.length; k > 0; k--) {
      const item = this._byCanonical.get(segs.slice(0, k).join('/'));
      if (item === undefined) continue;
      const rest = segs.slice(k).join('/');
      return `${item}${rest.length > 0 ? `/${rest}` : ''}`;
    }
    return canonical.includes('#') ? null : canonical;
  }
}

/** Whether canonical `path` is `item` or lies under it. */
function _under(path: string, item: string): boolean {
  return path === item || path.startsWith(`${item}/`);
}

/** A copy whose paths the model does not resolve does not fit the base. */
function _checkStructure(doc: SpecDocument, what: string, refl: SpecReflection): void {
  const json = doc.toJson();
  const paths = [
    ...Object.keys(json.content ?? {}),
    ...Object.keys(json.forms ?? {}),
    ...Object.keys(json.headlines ?? {}),
    ...Object.keys(json.codeSpecs ?? {}),
    ...Object.keys(json.units ?? {}),
    ...Object.entries(json.lists ?? {}).flatMap(([list, l]) => [list, ...l.items]),
  ];
  for (const p of paths) {
    if (refl.resolve(p) === null) {
      throw new SpecReviewMergeError(`${what} holds ${p}, a path the base model does not resolve`);
    }
  }
}

function _copyDocument(doc: SpecDocument): SpecDocument {
  const out = new SpecDocument();
  out.loadJson(JSON.parse(JSON.stringify(doc.toJson())));
  return out;
}

/** The form field `field` of the form at `path`, or null. */
function _formField(refl: SpecReflection, path: string, field: string): FormFieldSpec | null {
  const f = refl.resolve(path)?.field ?? null;
  return f === null ? null : (f.formFields.find((x) => x.name === field) ?? null);
}

/**
 * Whether the value at `path` / `field` is text, which can hold marks: a
 * content value (a form's preamble included) or a String form field that is
 * not code. Scalar and enum leaves, and typed or code fields, are not.
 */
function _isText(refl: SpecReflection, path: string, field: string | null): boolean {
  if (field !== null) {
    const spec = _formField(refl, path, field);
    return spec === null || (spec.type === 'String' && !spec.code);
  }
  const res = refl.resolve(path);
  if (res === null) return true;
  if (res.kind === SpecNodeKind.SCALAR || res.kind === SpecNodeKind.ENUM_VALUE) return false;
  return res.kind !== SpecNodeKind.LIST_ITEM_SCALAR || res.field?.elementType === 'String';
}

/** The first node at or below `path` that holds content (a content leaf or a form's preamble), in model order. */
function _firstContentSlot(refl: SpecReflection, path: string, deep: boolean): string | null {
  const res = refl.resolve(path);
  if (res === null) return null;
  if (res.kind === SpecNodeKind.CONTENT || res.kind === SpecNodeKind.FORM) return path;
  const cls: SpecClass | null = res.targetClass;
  if (cls === null) return null;
  for (const f of cls.fields) {
    const child = `${path}/${refl.fieldSegment(f)}`;
    if (f.kind === SpecFieldKind.CONTENT || f.kind === SpecFieldKind.FORM) return child;
    if (deep && (f.kind === SpecFieldKind.COMPLEX || f.kind === SpecFieldKind.SECTION)) {
      const found = _firstContentSlot(refl, child, true);
      if (found !== null) return found;
    }
  }
  return null;
}

/**
 * Where a block about the node at `path` goes (SOM §11.9.9, "Structure"): the
 * first content value at or below it in document order; else the first node
 * at or below it that can hold content; else its nearest ancestor's own.
 */
function _blockHome(doc: SpecDocument, refl: SpecReflection, path: string, ownFirst: boolean): string | null {
  if (ownFirst) {
    const existing = Array.from(doc.contentPaths).filter((p) => _under(p, path)).sort();
    if (existing.length > 0) return existing[0];
    const slot = _firstContentSlot(refl, path, true);
    if (slot !== null) return slot;
  }
  for (let a = specParentPath(path); a.length > 0; ) {
    if (doc.content(a) !== null) return a;
    const slot = _firstContentSlot(refl, a, false);
    if (slot !== null) return slot;
    const parent = specParentPath(a);
    if (parent === a) break;
    a = parent;
  }
  return null;
}

/** One structural change the copies disagree with the base on. */
interface _Structural {
  /** The canonical path of the item (or section) concerned. */
  node: string;
  topic: 'Item removed' | 'Item moved' | 'Headline changed';
  base: string;
  groups: Array<{ text: string; members: string[] }>;
}

function _addStructural(
  all: _Structural[],
  node: string,
  topic: _Structural['topic'],
  base: string,
  text: string,
  member: string,
): void {
  let s = all.find((x) => x.node === node && x.topic === topic);
  if (s === undefined) {
    s = { node, topic, base, groups: [] };
    all.push(s);
  }
  const g = s.groups.find((x) => x.text === text);
  if (g === undefined) s.groups.push({ text, members: [member] });
  else g.members.push(member);
}

/** The positions of `ids` that are not in their longest common subsequence with `order`. */
function _moved(order: string[], ids: string[]): Set<string> {
  const n = order.length;
  const m = ids.length;
  const l: number[][] = [];
  for (let i = 0; i <= n; i++) l.push(new Array<number>(m + 1).fill(0));
  for (let i = n - 1; i >= 0; i--) {
    for (let j = m - 1; j >= 0; j--) {
      l[i][j] = order[i] === ids[j] ? l[i + 1][j + 1] + 1 : Math.max(l[i + 1][j], l[i][j + 1]);
    }
  }
  const stay = new Set<string>();
  let i = 0;
  let j = 0;
  while (i < n && j < m) {
    if (order[i] === ids[j]) {
      stay.add(order[i]);
      i++;
      j++;
    } else if (l[i + 1][j] >= l[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return new Set(ids.filter((id) => !stay.has(id)));
}

/** `value` written as attributed insertions, one per text paragraph (an added item's text). */
function _asInsertion(value: string, members: string[]): string {
  const token = `{@${members.join(',')}}`;
  return reviewPieces(value)
    .map((p) =>
      p.kind !== 'text' || /^\s*(```|~~~)/.test(p.text) ? p.text : `{++ ${p.text.trim()} ++}${token}`,
    )
    .join('\n\n');
}

/** Copies item `from` of `src`, with everything under it, to item `to` of `dst`. */
function _copyItem(
  src: SpecDocument,
  from: string,
  dst: SpecDocument,
  to: string,
  members: string[],
  refl: SpecReflection,
): void {
  const moved = new Map<string, string>([[from, to]]);
  const remap = (p: string): string => {
    const segs = p.split('/');
    for (let k = segs.length; k > 0; k--) {
      const target = moved.get(segs.slice(0, k).join('/'));
      if (target !== undefined) return [target, ...segs.slice(k)].join('/');
    }
    return p;
  };
  const lists = Array.from(src.listPaths)
    .filter((l) => _under(l, from))
    .sort((a, b) => a.split('/').length - b.split('/').length);
  const canonical = new _CanonicalPaths(src, refl);
  for (const list of lists) {
    for (const item of src.listItems(list)) {
      moved.set(item, dst.addListItem(remap(list), canonical.idOf(item)));
    }
  }
  for (const p of Array.from(src.contentPaths).filter((x) => _under(x, from))) {
    const value = src.content(p) as string;
    dst.setContent(remap(p), _isText(refl, p, null) ? _asInsertion(value, members) : value);
  }
  for (const p of Array.from(src.formPaths).filter((x) => _under(x, from))) {
    for (const f of src.formFieldNames(p)) {
      const value = src.formField(p, f) as string;
      dst.setFormField(remap(p), f, _isText(refl, p, f) ? _asInsertion(value, members) : value);
    }
  }
  for (const p of Array.from(src.headlinePaths).filter((x) => _under(x, from))) {
    dst.setHeadline(remap(p), src.headline(p) as string);
  }
  for (const p of Array.from(src.codeSpecPaths).filter((x) => _under(x, from))) {
    dst.setCodeSpec(remap(p), src.codeSpec(p) as string);
  }
  for (const p of Array.from(src.unitsPaths).filter((x) => _under(x, from))) {
    dst.setUnits(remap(p), src.units(p) as string);
  }
}

/** Everything under an item, as one comparable value: copies adding the same item alike add it once. */
function _itemSignature(doc: SpecDocument, item: string): string {
  const json = doc.toJson();
  const pick = <V>(o: Record<string, V> | undefined): Array<[string, V]> =>
    Object.entries(o ?? {})
      .filter(([k]) => _under(k, item))
      .map(([k, v]) => [k.substring(item.length), v]);
  // Nested item paths start with the item's own path, which is a position: cut it.
  const own = JSON.stringify(item).slice(0, -1);
  return JSON.stringify([pick(json.content), pick(json.forms), pick(json.headlines), pick(json.lists)])
    .split(own)
    .join('"');
}

/**
 * The structure phase: items the copies added are added (attributed to every
 * copy that added them alike); items removed or moved, and changed headlines,
 * become structural conflicts. Returns the canonical paths of the added items.
 */
function _mergeStructure(
  merged: SpecDocument,
  base: SpecDocument,
  copies: Array<SpecReviewedCopy<SpecDocument>>,
  refl: SpecReflection,
  model: SpecModel,
  ctx: _MergeContext,
): Set<string> {
  const baseCanon = new _CanonicalPaths(base, refl);
  const copyCanon = copies.map((c) => new _CanonicalPaths(c.document, refl));
  const added = new Set<string>();
  const structural: _Structural[] = [];
  const additions: Array<{ node: string; members: string[] }> = [];
  const lists = new Set<string>(Array.from(base.listPaths).map((l) => baseCanon.of(l)));
  copies.forEach((c, i) => {
    for (const l of c.document.listPaths) lists.add(copyCanon[i].of(l));
  });
  const ordered = Array.from(lists).sort(
    (a, b) => a.split('#').length - b.split('#').length || (a < b ? -1 : a > b ? 1 : 0),
  );
  for (const list of ordered) {
    if (Array.from(added).some((a) => _under(list, a))) continue;
    const basePath = baseCanon.pathOf(list);
    if (basePath === null) continue;
    const baseIds = baseCanon.items(basePath).map((p) => baseCanon.idOf(p));
    const groups = new Map<string, { copy: number; anchor: string | null; members: string[]; signature: string }>();
    copies.forEach((c, i) => {
      const copyPath = copyCanon[i].pathOf(list);
      if (copyPath === null) return;
      const items = copyCanon[i].items(copyPath);
      const ids = items.map((p) => copyCanon[i].idOf(p));
      const member = c.memberId;
      ids.forEach((id, k) => {
        if (baseIds.includes(id)) return;
        const signature = _itemSignature(c.document, items[k]);
        const g = groups.get(id);
        if (g === undefined) {
          const anchor = ids.slice(0, k).reverse().find((x) => baseIds.includes(x)) ?? null;
          groups.set(id, { copy: i, anchor, members: [member], signature });
        } else if (g.signature === signature) {
          g.members.push(member);
        }
      });
      for (const id of baseIds.filter((x) => !ids.includes(x))) {
        _addStructural(structural, `${list}#${id}`, 'Item removed', 'kept', 'removed', member);
      }
      const keptOrder = baseIds.filter((x) => ids.includes(x));
      const keptIds = ids.filter((x) => baseIds.includes(x));
      for (const id of _moved(keptOrder, keptIds)) {
        _addStructural(
          structural,
          `${list}#${id}`,
          'Item moved',
          `position ${baseIds.indexOf(id) + 1}`,
          `moved to position ${ids.indexOf(id) + 1}`,
          member,
        );
      }
    });
    for (const [id, g] of groups) {
      const mergedCanon = new _CanonicalPaths(merged, refl);
      const listPath = mergedCanon.pathOf(list) as string;
      const mergedIds = mergedCanon.items(listPath).map((p) => mergedCanon.idOf(p));
      let at = g.anchor === null ? 0 : mergedIds.indexOf(g.anchor) + 1;
      while (at < mergedIds.length && !baseIds.includes(mergedIds[at])) at++;
      let item = merged.addListItem(listPath, id);
      if (at < mergedIds.length) item = merged.moveListItem(model, item, at).path;
      const src = copies[g.copy].document;
      _copyItem(src, copyCanon[g.copy].pathOf(`${list}#${id}`) as string, merged, item, g.members, refl);
      added.add(`${list}#${id}`);
      additions.push({ node: `${list}#${id}`, members: g.members });
    }
  }
  _headlineChanges(base, baseCanon, copies, copyCanon, added, structural);
  const mergedCanon = new _CanonicalPaths(merged, refl);
  for (const a of additions) {
    ctx.report.additions.push({ path: mergedCanon.pathOf(a.node) as string, members: a.members });
  }
  for (const s of structural) {
    const node = mergedCanon.pathOf(s.node) as string;
    const home = _blockHome(merged, refl, node, true);
    const block = ctx.conflict({
      topic: s.topic,
      text: node,
      base: s.base,
      groups: s.groups,
      path: node,
      field: null,
      paragraph: null,
    });
    if (home !== null) ctx.append(_contentKey(home), block);
  }
  return added;
}

/** Every headline a copy changed (items it added aside) is a structural conflict. */
function _headlineChanges(
  base: SpecDocument,
  baseCanon: _CanonicalPaths,
  copies: Array<SpecReviewedCopy<SpecDocument>>,
  copyCanon: _CanonicalPaths[],
  added: Set<string>,
  structural: _Structural[],
): void {
  const nodes = new Set<string>(Array.from(base.headlinePaths).map((p) => baseCanon.of(p)));
  copies.forEach((c, i) => {
    for (const p of c.document.headlinePaths) nodes.add(copyCanon[i].of(p));
  });
  for (const node of Array.from(nodes).sort()) {
    if (Array.from(added).some((a) => _under(node, a))) continue;
    const basePath = baseCanon.pathOf(node);
    if (basePath === null) continue;
    const was = base.headline(basePath) ?? '';
    copies.forEach((c, i) => {
      const path = copyCanon[i].pathOf(node);
      if (path === null) return;
      const now = c.document.headline(path) ?? '';
      if (now !== was) _addStructural(structural, node, 'Headline changed', was, now, c.memberId);
    });
  }
}

/** The keys of the SOM texts: `c\0<path>` for content, `f\0<path>\0<field>` for a form field. */
function _contentKey(path: string): string {
  return `c\u0000${path}`;
}

function _fieldKey(path: string, field: string): string {
  return `f\u0000${path}\u0000${field}`;
}

/** The SOM document's values as {@link _Texts}, in document order (content sorted, then forms and fields sorted). */
function _somTexts(doc: SpecDocument): _Texts {
  return {
    keys: () => [
      ...Array.from(doc.contentPaths).sort().map(_contentKey),
      ...Array.from(doc.formPaths)
        .sort()
        .flatMap((p) => Array.from(doc.formFieldNames(p)).sort().map((f) => _fieldKey(p, f))),
    ],
    get: (key) => {
      const [kind, path, field] = key.split('\u0000');
      return (kind === 'c' ? doc.content(path) : doc.formField(path, field)) ?? '';
    },
    set: (key, value) => {
      const [kind, path, field] = key.split('\u0000');
      if (kind === 'c') doc.setContent(path, value);
      else doc.setFormField(path, field, value);
    },
  };
}

/**
 * The values to merge: every value of the base and of the copies, items the
 * copies added aside, located in the merged document; in its document order.
 */
function _somValues(
  merged: SpecDocument,
  base: SpecDocument,
  copies: Array<SpecReviewedCopy<SpecDocument>>,
  added: Set<string>,
  refl: SpecReflection,
): _MergeValue[] {
  const baseCanon = new _CanonicalPaths(base, refl);
  const copyCanon = copies.map((c) => new _CanonicalPaths(c.document, refl));
  const mergedCanon = new _CanonicalPaths(merged, refl);
  const keys = new Map<string, [string, string | null]>();
  const collect = (doc: SpecDocument, canon: _CanonicalPaths): void => {
    for (const p of doc.contentPaths) keys.set(_contentKey(canon.of(p)), [canon.of(p), null]);
    for (const p of doc.formPaths) {
      for (const f of doc.formFieldNames(p)) keys.set(_fieldKey(canon.of(p), f), [canon.of(p), f]);
    }
  };
  collect(base, baseCanon);
  copies.forEach((c, i) => collect(c.document, copyCanon[i]));
  const read = (doc: SpecDocument, path: string, field: string | null): string =>
    (field === null ? doc.content(path) : doc.formField(path, field)) ?? '';
  const values: _MergeValue[] = [];
  for (const [node, field] of keys.values()) {
    if (Array.from(added).some((a) => _under(node, a))) continue;
    const basePath = baseCanon.pathOf(node);
    if (basePath === null) continue;
    const path = mergedCanon.pathOf(node) as string;
    const text = _isText(refl, path, field);
    values.push({
      path,
      field,
      base: read(base, basePath, field),
      copies: copies.map((c, i) => {
        const p = copyCanon[i].pathOf(node);
        return p === null ? null : read(c.document, p, field);
      }),
      typed: !text,
      conflictHome:
        field !== null
          ? _contentKey(path)
          : text
            ? null
            : (() => {
                const home = _blockHome(merged, refl, path, false);
                return home === null ? null : _contentKey(home);
              })(),
    });
  }
  const order = (v: _MergeValue): string => `${v.field === null ? 0 : 1}\u0000${v.path}\u0000${v.field ?? ''}`;
  return values.sort((a, b) => (order(a) < order(b) ? -1 : order(a) > order(b) ? 1 : 0));
}

/** The class field of `cls` named `name` with kind `kind`, or null. */
function _classField(cls: SpecClass | null, name: string, kind: string): SpecField | null {
  const f = cls?.fieldNamed(name) ?? null;
  return f !== null && f.kind === kind ? f : null;
}

/** The model classes and fields the revision entry is written with (`tom_specs_model`'s document front matter). */
const _REVISION_ENTRY = 'RevisionEntry';
const _DOCUMENT_HEADER = 'DocumentHeader';

/** The next minor of a `major.minor[.patch]` version; `0.1.0` for anything else. */
function _nextMinor(version: string | null): string {
  const m = /^([0-9]+)\.([0-9]+)(\.[0-9]+)?$/.exec((version ?? '').trim());
  if (m === null) return '0.1.0';
  const minor = `${m[1]}.${parseInt(m[2], 10) + 1}`;
  return m[3] === undefined ? minor : `${minor}.0`;
}

/** The month and day of an ISO 8601 date. */
function _monthDay(date: string): [number, number] {
  const m = /^[0-9]{4}-([0-9]{2})-([0-9]{2})/.exec(date);
  if (m === null) throw new SpecReviewMergeError(`options.date "${date}" is not an ISO 8601 date`);
  return [parseInt(m[1], 10), parseInt(m[2], 10)];
}

/** Adds an item with a generated id to the list `field` at `list`, and returns its path. */
function _addGeneratedItem(doc: SpecDocument, list: string, field: SpecField, date: [number, number]): string {
  const id = generateListItemSectionId(
    field.sectionIdPattern ?? `${field.name}-xxx`,
    date[0],
    date[1],
    doc.listItemSectionIds(list),
  );
  return doc.addListItem(list, id);
}

/** Writes one reviewer record into the list `field` at `list`. */
function _addReviewerRecord(
  doc: SpecDocument,
  refl: SpecReflection,
  list: string,
  field: SpecField,
  member: SpecReviewMember,
  guest: boolean,
  date: [number, number],
): void {
  const item = _addGeneratedItem(doc, list, field, date);
  const form = _classField(refl.classNamed(field.elementType), 'content', SpecFieldKind.FORM);
  if (form === null) return;
  const path = `${item}/${refl.fieldSegment(form)}`;
  doc.setFormField(path, 'memberId', member.memberId);
  doc.setFormField(path, 'displayName', member.displayName);
  doc.setFormField(path, 'role', member.role);
  if (guest) doc.setFormField(path, 'guest', 'true');
}

/**
 * Appends the draft revision entry when the root has a revision history: the
 * next minor version, the date and author, the team the round started with and
 * every reviewer who returned a copy, guests marked.
 */
function _addRevisionEntry(
  merged: SpecDocument,
  root: string,
  copies: SpecReviewMember[],
  options: SpecReviewMergeOptions,
  refl: SpecReflection,
  ctx: _MergeContext,
): void {
  const rootClass = refl.classNamed(refl.rootForSegment(root)?.type);
  const history = rootClass?.fields.find(
    (f) => f.kind === SpecFieldKind.LIST && f.elementType === _REVISION_ENTRY,
  );
  if (history === undefined || rootClass === null) return;
  const date = _monthDay(options.date);
  const header = rootClass.fields.find((f) => f.type === _DOCUMENT_HEADER);
  const headerForm = header
    ? _classField(refl.classNamed(_DOCUMENT_HEADER), 'content', SpecFieldKind.FORM)
    : null;
  const current =
    header && headerForm
      ? merged.formField(`${root}/${refl.fieldSegment(header)}/${refl.fieldSegment(headerForm)}`, 'version')
      : null;
  const version = _nextMinor(current);
  const item = _addGeneratedItem(merged, `${root}/${refl.fieldSegment(history)}`, history, date);
  const entry = refl.classNamed(_REVISION_ENTRY);
  const form = _classField(entry, 'content', SpecFieldKind.FORM);
  if (form !== null) {
    const path = `${item}/${refl.fieldSegment(form)}`;
    merged.setFormField(path, 'version', version);
    merged.setFormField(path, 'date', options.date);
    merged.setFormField(path, 'author', options.author);
  }
  const team = new Set(options.team.map((m) => m.memberId));
  const records: Array<[string, SpecReviewMember[], (m: SpecReviewMember) => boolean]> = [
    ['reviewTeam', options.team, () => false],
    ['reviewers', copies, (m) => !team.has(m.memberId)],
  ];
  for (const [name, members, guest] of records) {
    const list = _classField(entry, name, SpecFieldKind.LIST);
    if (list === null) continue;
    for (const m of members) {
      _addReviewerRecord(merged, refl, `${item}/${refl.fieldSegment(list)}`, list, m, guest(m), date);
    }
  }
  ctx.report.revision = { path: item, version };
}

/** The root segment of a document: the first segment of its paths. */
function _rootOf(doc: SpecDocument, refl: SpecReflection): string | null {
  const json = doc.toJson();
  const any = [
    ...Object.keys(json.content ?? {}),
    ...Object.keys(json.forms ?? {}),
    ...Object.keys(json.lists ?? {}),
    ...Object.keys(json.headlines ?? {}),
  ][0];
  if (any !== undefined) return any.split('/')[0];
  return refl.roots.length > 0 ? refl.rootSegment(refl.roots[0]) : null;
}

function _mergeSom(
  base: SpecDocument,
  copies: Array<SpecReviewedCopy<SpecDocument>>,
  options: SpecReviewMergeOptions,
  model: SpecModel,
): SpecReviewMergeResult<SpecDocument> {
  const refl = new SpecReflection(model);
  _checkStructure(base, 'the base', refl);
  copies.forEach((c) => _checkStructure(c.document, `the copy of ${c.memberId}`, refl));
  const baseTexts = _somTexts(base);
  const baseValues = baseTexts.keys().map((k) => baseTexts.get(k));
  const copyValues = copies.map((c) => {
    const t = _somTexts(c.document);
    return t.keys().map((k) => t.get(k));
  });
  const ids = _blockIds(baseValues);
  const ctx = new _MergeContext(copies, ids.comments, ids.questions);
  const merged = _copyDocument(base);
  const added = _mergeStructure(merged, base, copies, refl, model, ctx);
  const values = _somValues(merged, base, copies, added, refl);
  const root = _rootOf(base, refl);
  const rootClass = root === null ? null : refl.classNamed(refl.rootForSegment(root)?.type);
  const rootContent = _classField(rootClass, 'content', SpecFieldKind.CONTENT);
  const home =
    root !== null && rootContent !== null
      ? (() => {
          const path = `${root}/${refl.fieldSegment(rootContent)}`;
          return { key: _contentKey(path), path };
        })()
      : null;
  _mergeTexts(
    values,
    (v) => (v.field === null ? _contentKey(v.path) : _fieldKey(v.path, v.field)),
    _somTexts(merged),
    baseValues,
    copyValues,
    copies,
    options,
    home,
    ctx,
  );
  if (root !== null) _addRevisionEntry(merged, root, copies, options, refl, ctx);
  return new SpecReviewMergeResult(merged, ctx.report);
}
