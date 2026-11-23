/**
 * The merge back (SOM §11.10; the reading view's part *Stripped renditions and
 * the merge back*): an edited readable rendition merged onto the document of
 * record, every piece the strip removed put back.
 *
 * The port of `spec_document_merge.dart`; `strip_merge_cases.json` holds both
 * to the same results.
 */

import { execFileSync } from 'child_process';
import * as path from 'path';

import { DocSpecsDocument, DocSpecsSchema, DocSpecsSection } from './docspecs_validator';
import { SpecDocument } from './spec_document';
import { SpecDocumentMarkdown } from './spec_document_markdown';
import {
  SpecDocumentStrip,
  SpecReadableHeader,
  SpecReadableSource,
  SpecStripOptions,
  SpecStripPiece,
  SpecStripUsageError,
  SpecStripValueRef,
  _stripInternals,
  type _StripOp,
} from './spec_document_strip';
import type { SpecModel } from './spec_model';
import { NotationElement, NotationFindingCode, scanNotation } from './spec_notation';
import { annotationIssuesText } from './spec_review_annotations';

const { KEEP, DEL, INS } = _stripInternals;

/**
 * A piece put back after an edited run rather than between unchanged
 * neighbours: an author confirms or moves it (`PLACED <value> — check`).
 */
export class SpecStripMergePlaced {
  constructor(
    readonly piece: SpecStripPiece,
    /** The offset in the merged value the piece's text starts at. */
    readonly at: number,
  ) {}

  toJson(): Record<string, unknown> {
    return { at: this.at, removed: this.piece.removed };
  }
}

/**
 * Why a value, or the whole merge, cannot be merged. The codes are those of
 * the Dart `SpecStripMergeConflict`: `crossesBoundary`, `sentenceRemoved`,
 * `stripTextEdited`, `unplaceable`, `notation`, `annotations`,
 * `changedBothSides`, `notStrippedBack` and `newFinding`.
 */
export class SpecStripMergeConflict {
  constructor(
    readonly code: string,
    readonly message: string,
    readonly ref: SpecStripValueRef | null = null,
    readonly piece: SpecStripPiece | null = null,
    readonly excerptO = '',
    readonly excerptB = '',
    readonly excerptE = '',
  ) {}

  /** The conflict about value `value`. */
  about(value: SpecStripValueRef): SpecStripMergeConflict {
    return new SpecStripMergeConflict(
      this.code,
      this.message,
      value,
      this.piece,
      this.excerptO,
      this.excerptB,
      this.excerptE,
    );
  }

  /** `CONFLICT <value> — <reason>`, then the three excerpts and the piece. */
  get reportLines(): string[] {
    const out = [
      `CONFLICT ${this.ref === null ? '(document)' : specStripMergeLabel(this.ref)} — ${this.message}`,
    ];
    if (this.piece !== null || this.excerptB !== '') {
      out.push(`  O: ${this.excerptO}`, `  B: ${this.excerptB}`, `  E: ${this.excerptE}`);
    }
    if (this.piece !== null) out.push(`  piece: ${_visible(this.piece.removed)}`);
    return out;
  }

  toJson(): Record<string, unknown> {
    const out: Record<string, unknown> = { code: this.code };
    if (this.ref !== null) out.value = this.ref.toJson();
    if (this.piece !== null) out.removed = this.piece.removed;
    return out;
  }
}

/** The result of {@link mergeStrippedValue}. */
export class SpecStripValueMerge {
  constructor(
    /** The merged value; null when there are conflicts. */
    readonly text: string | null,
    /** How many pieces were put back. */
    readonly restored: number,
    readonly placed: SpecStripMergePlaced[],
    readonly conflicts: SpecStripMergeConflict[],
  ) {}

  get ok(): boolean {
    return this.conflicts.length === 0;
  }

  toJson(): Record<string, unknown> {
    return {
      text: this.text,
      restored: this.restored,
      placed: this.placed.map((p) => p.toJson()),
      conflicts: this.conflicts.map((c) => c.toJson()),
    };
  }
}

/** The name of a value in a merge report. */
export function specStripMergeLabel(ref: SpecStripValueRef): string {
  return ref.headline
    ? `${ref.path} (headline)`
    : ref.field !== null
      ? `${ref.path} / ${ref.field}`
      : ref.path;
}

const _ROLE_WHOLE = 0;
const _ROLE_OPENER = 1;
const _ROLE_CLOSER = 2;
const _ROLE_BOTH = 3;

interface _Put {
  at: number;
  order: number;
  text: string;
  replace: number;
  normalize: boolean;
  before: number;
  after: number;
}

function _put(at: number, order: number, text: string, extra: Partial<_Put> = {}): _Put {
  return { at, order, text, replace: 0, normalize: false, before: 2, after: 2, ...extra };
}

/**
 * Merges the edited text `e` of one value back onto its original `o` (SOM
 * §11.10): `b` is `o` stripped and `pieces` what the strip removed, anchored
 * in `b`. The rules are those of the Dart `mergeStrippedValue`.
 */
export function mergeStrippedValue(
  o: string,
  b: string,
  e: string,
  pieces: SpecStripPiece[],
): SpecStripValueMerge {
  if (e === b) return new SpecStripValueMerge(o, pieces.length, [], []);
  const roles = _pieceRoles(o, pieces);
  const ops = _stripInternals.diff(b, e, 'edit');
  const map = new _EditMap(ops, b.length);
  // An opening marker is judged on the script whose whitespace edits trail
  // their run, a closing one on the script whose whitespace edits lead it.
  const trailing = new _EditMap(_slide(ops, false), b.length);
  const leading = new _EditMap(_slide(ops, true), b.length);
  let lines: _LineEditMap | null = null;
  const puts: _Put[] = [];
  const placedAt = new Set<number>();
  const conflicts: SpecStripMergeConflict[] = [];
  let restored = 0;
  for (let i = 0; i < pieces.length; i++) {
    const p = pieces[i];
    const conflict = (code: string, message: string, eAt: number): SpecStripMergeConflict =>
      new SpecStripMergeConflict(
        code,
        message,
        null,
        p,
        _excerpt(o, p.origin),
        _excerpt(b, p.anchor),
        _excerpt(e, eAt),
      );

    if (p.inserted !== '') {
      const at = map.keptRange(p.anchor, p.anchor + p.inserted.length);
      if (at < 0) {
        conflicts.push(
          conflict(
            'stripTextEdited',
            'the text the strip wrote in place of a piece was edited',
            map.gap(p.anchor).start,
          ),
        );
        continue;
      }
      puts.push(_put(at, i, p.removed, { replace: p.inserted.length }));
      restored++;
      continue;
    }

    const role = roles[i];
    let g = p.anchor;
    let text = p.removed;
    if (role === _ROLE_WHOLE && text.includes('\n')) {
      while (g > 0 && b[g - 1] !== '\n' && g < b.length && text[0] === b[g]) {
        text = text.substring(1) + text[0];
        g++;
      }
      if (g === 0 || b[g - 1] === '\n' || g === b.length) {
        if (lines === null) lines = new _LineEditMap(b, e);
        const k = _lineIndex(b, g);
        const gap = lines.gap(k);
        if (gap.unchanged) {
          puts.push(_put(gap.at, i, text));
          restored++;
          continue;
        }
        const at = !gap.leftEdited
          ? gap.start
          : !gap.rightEdited
            ? gap.end
            : lines.paragraphPlace(gap, k);
        if (at > 0 && at < e.length && e[at - 1] !== '\n') {
          conflicts.push(
            conflict('unplaceable', 'the block has no line boundary to go back to', at),
          );
          continue;
        }
        // The block keeps the distance it had from the text around it in the
        // original: a blank line, or none when it stood right against a line.
        const core = p.origin + _leadingBreaks(p.removed);
        const coreEnd = p.origin + p.removed.length - _trailingBreaks(p.removed);
        const distance = (breaks: number, edge: boolean): number =>
          edge ? 2 : Math.min(2, Math.max(1, breaks));
        puts.push(
          _put(at, i, text, {
            normalize: true,
            before: distance(_trailingBreaks(o.substring(0, core)), core === 0),
            after: distance(_leadingBreaks(o.substring(coreEnd)), coreEnd >= o.length),
          }),
        );
        restored++;
        continue;
      }
      g = p.anchor;
      text = p.removed;
    }

    const gap = (role === _ROLE_OPENER ? trailing : role === _ROLE_CLOSER ? leading : map).gap(g);
    if (gap.unchanged) {
      puts.push(_put(gap.at, i, text));
      restored++;
      continue;
    }
    if (text.trim() === '') continue; // normalised whitespace at an edit
    if (role === _ROLE_OPENER || role === _ROLE_CLOSER) {
      if (gap.leftEdited && gap.rightEdited) {
        conflicts.push(
          conflict(
            'crossesBoundary',
            'an edit crosses the boundary of an unmarked element',
            gap.start,
          ),
        );
        continue;
      }
      // The edit on the inner side of the marker goes inside the element.
      const at =
        role === _ROLE_OPENER
          ? !gap.leftEdited
            ? gap.start
            : gap.end
          : !gap.rightEdited
            ? gap.end
            : gap.start;
      puts.push(_put(at, i, text));
      restored++;
    } else if (role === _ROLE_BOTH) {
      conflicts.push(
        conflict(
          'crossesBoundary',
          'an edit touches the boundary between two unmarked elements',
          gap.start,
        ),
      );
    } else {
      if (_sentenceRemoved(b, g, map)) {
        conflicts.push(
          conflict(
            'sentenceRemoved',
            'the edit removed the whole sentence holding the piece',
            gap.start,
          ),
        );
        continue;
      }
      puts.push(_put(gap.end, i, text));
      placedAt.add(i);
      restored++;
    }
  }
  if (conflicts.length > 0) return new SpecStripValueMerge(null, 0, [], conflicts);

  puts.sort((x, y) => (x.at !== y.at ? x.at - y.at : x.order - y.order));
  let out = '';
  const placed: SpecStripMergePlaced[] = [];
  let pos = 0;
  for (const put of puts) {
    if (put.at < pos) {
      conflicts.push(
        new SpecStripMergeConflict(
          'stripTextEdited',
          'two pieces claim the same text',
          null,
          pieces[put.order],
        ),
      );
      continue;
    }
    out += e.substring(pos, put.at);
    pos = put.at;
    if (put.normalize) {
      const core = put.text.replace(/^\n+|\n+$/g, '');
      if (out !== '') out += '\n'.repeat(Math.max(0, put.before - _trailingBreaks(out)));
      if (placedAt.has(put.order)) placed.push(new SpecStripMergePlaced(pieces[put.order], out.length));
      out += core;
      const right = e.substring(pos);
      if (right !== '') out += '\n'.repeat(Math.max(0, put.after - _leadingBreaks(right)));
    } else {
      if (placedAt.has(put.order)) placed.push(new SpecStripMergePlaced(pieces[put.order], out.length));
      out += put.text;
    }
    pos += put.replace;
  }
  out += e.substring(pos);
  const merged = out;

  const notationErrors = (s: string): number =>
    scanNotation(s, { tomSpecs: true }).findings.filter(
      (f) => f.severity === 'error' && f.code !== NotationFindingCode.REJECTED_BLOCK,
    ).length;
  if (notationErrors(merged) > notationErrors(e) + notationErrors(o)) {
    conflicts.push(
      new SpecStripMergeConflict(
        'notation',
        'the merged value has a notation error neither the original nor the edited text has',
      ),
    );
  }
  if (
    annotationIssuesText(merged).length >
    annotationIssuesText(e).length + annotationIssuesText(o).length
  ) {
    conflicts.push(
      new SpecStripMergeConflict(
        'annotations',
        'the merged value has a malformed review annotation neither the original nor the edited text has',
      ),
    );
  }
  if (conflicts.length > 0) return new SpecStripValueMerge(null, 0, [], conflicts);
  return new SpecStripValueMerge(merged, restored, placed, []);
}

/** One value a document merge changed. */
export class SpecStripMergedValue {
  constructor(
    readonly ref: SpecStripValueRef,
    /** The merged value written into the document of record. */
    readonly text: string,
    readonly restored: number,
    readonly placed: SpecStripMergePlaced[],
  ) {}
}

/**
 * An edit a merge refuses. The codes are those of the Dart
 * `SpecStripMergeRefusal`: `sectionAdded`, `sectionRemoved`, `sectionMoved`,
 * `listItems`, `codeSpec`, `units`, `rejected`, `stale` and `strip`.
 */
export class SpecStripMergeRefusal {
  constructor(
    readonly code: string,
    readonly path: string,
    readonly message: string,
  ) {}

  get reportLine(): string {
    return `REFUSED ${this.path === '' ? '(document)' : this.path} — ${this.message}`;
  }

  toJson(): Record<string, unknown> {
    return { code: this.code, path: this.path };
  }
}

/** The result of {@link SpecStripMerge.merge}. */
export class SpecStripMergeResult {
  constructor(
    /** The merged document; null when nothing may be written. */
    readonly document: SpecDocument | null,
    readonly options: SpecStripOptions,
    /** Whether the merge was three-way from the original at the export. */
    readonly stale: boolean,
    readonly merged: SpecStripMergedValue[],
    readonly conflicts: SpecStripMergeConflict[],
    readonly refusals: SpecStripMergeRefusal[],
  ) {}

  get ok(): boolean {
    return this.conflicts.length === 0 && this.refusals.length === 0;
  }

  /** `0` merged or nothing to merge, `1` conflicts or refusals. */
  get exitCode(): number {
    return this.ok ? 0 : 1;
  }

  get report(): string[] {
    const out: string[] = [];
    for (const m of this.merged) {
      out.push(`MERGED ${specStripMergeLabel(m.ref)} — ${m.restored} pieces put back`);
      for (let k = 0; k < m.placed.length; k++) {
        out.push(`PLACED ${specStripMergeLabel(m.ref)} — check`);
      }
    }
    for (const c of this.conflicts) out.push(...c.reportLines);
    for (const r of this.refusals) out.push(r.reportLine);
    return out;
  }
}

/** The options of {@link SpecStripMerge.merge}. */
export interface SpecStripMergeOptions {
  model: SpecModel;
  schema?: DocSpecsSchema | null;
  rootType?: string | null;
  /** Switches given beside the readable header; they must agree with it. */
  options?: SpecStripOptions | null;
  currentRevision?: string | null;
  /** The original as it was at the export, given by hand. */
  base?: SpecDocument | null;
  /** The base of a stale original from the header's source (its commit). */
  loadBase?: ((source: SpecReadableSource) => SpecDocument | null) | null;
  fileStem?: string | null;
  documentFiles?: Record<string, string>;
}

/** Merging an edited readable rendition back onto its document (SOM §11.10). */
export class SpecStripMerge {
  /**
   * Merges `edited`, a `.readable.md` made from `original` and changed by a
   * reader, back onto `original`; the behaviour is that of the Dart
   * `SpecStripMerge.merge`.
   */
  static merge(
    original: SpecDocument,
    edited: string,
    extra: SpecStripMergeOptions,
  ): SpecStripMergeResult {
    const model = extra.model;
    const schema = extra.schema ?? null;
    const rootType = extra.rootType ?? null;
    const fileStem = extra.fileStem ?? null;
    const documentFiles = extra.documentFiles ?? {};
    const parsed = new SpecDocumentMarkdown(model, new SpecDocument(), {
      fileStem,
      documentFiles,
    }).parse(edited);
    const headerLine = parsed.readableHeader;
    const header = headerLine === null ? null : SpecReadableHeader.parse(headerLine);
    if (headerLine !== null && header === null) {
      throw new SpecStripUsageError(`the readable header cannot be read: ${headerLine}`);
    }
    const given = extra.options ?? null;
    let opts: SpecStripOptions;
    if (given !== null) {
      if (header !== null && _optionsText(header.options) !== _optionsText(given)) {
        throw new SpecStripUsageError(
          `the switches given (${_optionsText(given)}) disagree with the readable header (${_optionsText(header.options)})`,
        );
      }
      opts = given;
    } else if (header !== null) {
      opts = header.options;
    } else {
      throw new SpecStripUsageError(
        'the rendition has no readable header: name the switches it was stripped with',
      );
    }

    const refused = (r: SpecStripMergeRefusal[], stale: boolean): SpecStripMergeResult =>
      new SpecStripMergeResult(null, opts, stale, [], [], r);

    if (parsed.rejections.length > 0) {
      return refused(
        parsed.rejections.map(
          (r) => new SpecStripMergeRefusal('rejected', '', `line ${r.line}: ${r.message}`),
        ),
        false,
      );
    }

    const source = header?.source ?? null;
    const currentRevision = extra.currentRevision ?? null;
    const base = extra.base ?? null;
    const stale =
      base !== null ||
      (source !== null &&
        source.revision !== null &&
        currentRevision !== null &&
        source.revision !== currentRevision);
    let origin = original;
    if (stale) {
      const loaded =
        base ??
        (source !== null && source.commit !== null && !source.dirty && extra.loadBase
          ? extra.loadBase(source)
          : null);
      if (loaded === null) {
        const why =
          source === null || source.commit === null
            ? 'names no commit'
            : source.dirty
              ? 'names a dirty commit'
              : 'names a commit that could not be read';
        return refused(
          [
            new SpecStripMergeRefusal(
              'stale',
              '',
              `the original moved since the export (revision ${source?.revision ?? 'null'} then, ${currentRevision} now) and there is no base: the header ${why}; give the original as it was at the export`,
            ),
          ],
          true,
        );
      }
      origin = loaded;
    }

    const strip = SpecDocumentStrip.strip(origin, opts, {
      model,
      schema,
      rootType,
      fileStem,
      documentFiles,
    });
    if (!strip.ok || strip.readable === null) {
      const r = strip.findings.map(
        (f) => new SpecStripMergeRefusal('strip', f.ref?.label ?? '', `${f}`),
      );
      if (r.length === 0) r.push(new SpecStripMergeRefusal('strip', '', 'the base renders no rendition'));
      return refused(r, stale);
    }
    const bDoc = strip.document;
    const eDoc = new SpecDocument();
    eDoc.applyMarkdownResult(parsed);
    const roots = Array.from(parsed.rootPrefixes);
    const inRoot = (p: string): boolean =>
      roots.some((r) => p === r || p.startsWith(`${r}/`) || p.startsWith(`${r}-`));

    // Structural edits.
    const refusals: SpecStripMergeRefusal[] = [];
    const bHeadings = _headingPaths(strip.readable);
    const eHeadings = _headingPaths(edited);
    if (!_listEq(bHeadings, eHeadings)) {
      const bSet = new Set(bHeadings);
      const eSet = new Set(eHeadings);
      for (const p of eHeadings) {
        if (!bSet.has(p)) refusals.push(new SpecStripMergeRefusal('sectionAdded', p, 'a section added'));
      }
      for (const p of bHeadings) {
        if (!eSet.has(p)) {
          refusals.push(new SpecStripMergeRefusal('sectionRemoved', p, 'a section removed'));
        }
      }
      if (refusals.length === 0) {
        const common = eHeadings.filter((p) => bSet.has(p));
        const want = bHeadings.filter((p) => eSet.has(p));
        for (let i = 0; i < common.length; i++) {
          if (common[i] !== want[i]) {
            refusals.push(new SpecStripMergeRefusal('sectionMoved', common[i], 'a section moved'));
            break;
          }
        }
      }
    }
    const bLists = _listsUnder(bDoc, inRoot);
    const eLists = _listsUnder(eDoc, inRoot);
    for (const l of Array.from(new Set([...bLists.keys(), ...eLists.keys()])).sort(_cmp)) {
      if (bLists.get(l) !== eLists.get(l)) {
        refusals.push(
          new SpecStripMergeRefusal('listItems', l, 'list items added, removed, moved or renamed'),
        );
      }
    }
    const keyed: Array<[string, (d: SpecDocument, p: string) => string | null, (d: SpecDocument) => Iterable<string>]> = [
      ['codeSpec', (d, p) => d.codeSpec(p), (d) => d.codeSpecPaths],
      ['units', (d, p) => d.units(p), (d) => d.unitsPaths],
    ];
    for (const [code, read, paths] of keyed) {
      const all = Array.from(new Set([...paths(bDoc), ...paths(eDoc)]))
        .filter(inRoot)
        .sort(_cmp);
      for (const p of all) {
        if (read(bDoc, p) !== read(eDoc, p)) {
          refusals.push(new SpecStripMergeRefusal(code, p, `a changed ${code}`));
        }
      }
    }
    const byKey = new Map<string, SpecStripValueRef>();
    for (const r of [..._stripInternals.valueRefs(bDoc), ..._stripInternals.valueRefs(eDoc)]) {
      if (inRoot(r.path)) byKey.set(_refKey(r), r);
    }
    const refs = Array.from(byKey.values()).sort((x, y) => {
      const c = _cmp(x.path, y.path);
      if (c !== 0) return c;
      if (x.headline !== y.headline) return x.headline ? -1 : 1;
      return _cmp(x.field ?? '', y.field ?? '');
    });
    for (const ref of refs) {
      if (
        ref.read(bDoc) === '' &&
        ref.read(eDoc) !== '' &&
        !bDoc.hasValuesUnder(ref.path) &&
        !refusals.some((r) => r.path === ref.path)
      ) {
        refusals.push(
          new SpecStripMergeRefusal(
            'sectionAdded',
            ref.path,
            'a value in a section the rendition does not show',
          ),
        );
      }
    }

    // The values.
    const pieces = new Map<string, SpecStripPiece[]>();
    for (const v of strip.values) pieces.set(_refKey(v.ref), v.pieces);
    const merged: SpecStripMergedValue[] = [];
    const conflicts: SpecStripMergeConflict[] = [];
    for (const ref of refs) {
      const bText = ref.read(bDoc);
      const eText = ref.read(eDoc);
      if (bText === eText) continue;
      if (refusals.some((r) => r.path === ref.path)) continue;
      // A value whose section came or went with a refused edit is that edit.
      if (refusals.length > 0 && (!bDoc.hasValuesUnder(ref.path) || !eDoc.hasValuesUnder(ref.path))) {
        continue;
      }
      const o = ref.read(origin);
      const r = mergeStrippedValue(o, bText, eText, pieces.get(_refKey(ref)) ?? []);
      const now = ref.read(original);
      if (stale && now !== o) {
        // The edit is already in the moved original (the same rendition
        // merged before): nothing to do for this value.
        if (r.ok && r.text === now) continue;
        const at = _firstDifference(bText, eText);
        conflicts.push(
          new SpecStripMergeConflict(
            'changedBothSides',
            'the value changed in the original since the export, and in the rendition',
            ref,
            null,
            _excerpt(now, _firstDifference(o, now)),
            _excerpt(bText, at),
            _excerpt(eText, at),
          ),
        );
        continue;
      }
      if (!r.ok) {
        for (const c of r.conflicts) conflicts.push(c.about(ref));
        continue;
      }
      merged.push(new SpecStripMergedValue(ref, r.text as string, r.restored, r.placed));
    }
    if (conflicts.length > 0 || refusals.length > 0) {
      return new SpecStripMergeResult(null, opts, stale, merged, conflicts, refusals);
    }

    // Write and verify.
    const out = new SpecDocument();
    out.loadJson(original.toJson());
    for (const m of merged) m.ref.write(out, m.text);
    const expected = new Set(
      merged.filter((m) => m.text !== m.ref.read(original)).map((m) => _refKey(m.ref)),
    );
    const changed = new Set<string>();
    for (const r of [..._stripInternals.valueRefs(original), ..._stripInternals.valueRefs(out)]) {
      if (r.read(original) !== r.read(out)) changed.add(_refKey(r));
    }
    if (changed.size !== expected.size || Array.from(expected).some((k) => !changed.has(k))) {
      conflicts.push(
        new SpecStripMergeConflict(
          'newFinding',
          'the merged document changes other values than the merged ones',
        ),
      );
    }
    const again = SpecDocumentStrip.strip(out, opts, {
      model,
      schema,
      rootType,
      fileStem,
      documentFiles,
    });
    for (const m of merged) {
      if (m.ref.read(again.document) !== m.ref.read(eDoc)) {
        conflicts.push(
          new SpecStripMergeConflict(
            'notStrippedBack',
            'the merged value does not strip back to the edited text',
            m.ref,
            null,
            _excerpt(m.text, 0),
            _excerpt(m.ref.read(again.document), 0),
            _excerpt(m.ref.read(eDoc), 0),
          ),
        );
      }
    }
    const before = _stripInternals.tierFindings(model, schema, rootType, original);
    for (const k of _stripInternals.tierFindings(model, schema, rootType, out).keys()) {
      if (!before.has(k)) {
        conflicts.push(
          new SpecStripMergeConflict('newFinding', `the merged document has a new finding: ${k}`),
        );
      }
    }
    return new SpecStripMergeResult(
      conflicts.length === 0 ? out : null,
      opts,
      stale,
      merged,
      conflicts,
      [],
    );
  }

  /**
   * The file at `filePath` as it was at `commit` (`git show <commit>:<path>`,
   * run in the file's folder), or null when git cannot give it.
   */
  static gitShowFile(commit: string, filePath: string): string | null {
    const file = path.resolve(filePath);
    try {
      return execFileSync('git', ['show', `${commit}:./${path.basename(file)}`], {
        cwd: path.dirname(file),
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'ignore'],
        maxBuffer: 1 << 30,
      });
    } catch {
      return null;
    }
  }
}

function _optionsText(o: SpecStripOptions): string {
  const s = new SpecReadableHeader(o).format();
  return s.substring('<!-- readable:'.length, s.length - 3).trim();
}

function _refKey(r: SpecStripValueRef): string {
  return `${r.headline ? 'h' : r.field !== null ? 'f' : 'c'}\u0000${r.path}\u0000${r.field ?? ''}`;
}

function _cmp(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

/** The section-id paths of `markdown`'s headings, in order. */
function _headingPaths(markdown: string): string[] {
  const out: string[] = [];
  const walk = (list: DocSpecsSection[], prefix: string): void => {
    for (const s of list) {
      const p = prefix === '' ? (s.id ?? '?') : `${prefix}/${s.id ?? '?'}`;
      out.push(p);
      walk(s.children, p);
    }
  };
  walk(DocSpecsDocument.parse(markdown).sections, '');
  return out;
}

/** The lists of `doc` under the roots, each as its items and their ids. */
function _listsUnder(doc: SpecDocument, inRoot: (p: string) => boolean): Map<string, string> {
  const out = new Map<string, string>();
  const lists = (doc.toJson() as Record<string, unknown>).lists as
    | Record<string, { items?: string[]; ids?: unknown }>
    | undefined;
  for (const [k, v] of Object.entries(lists ?? {})) {
    if (inRoot(k)) out.set(k, `${JSON.stringify(v.items ?? null)} ${JSON.stringify(v.ids ?? null)}`);
  }
  return out;
}

/** What each piece is, read from the original `o`; see the Dart `_pieceRoles`. */
function _pieceRoles(o: string, pieces: SpecStripPiece[]): number[] {
  const at = new Array<number>(o.length).fill(-1);
  pieces.forEach((p, i) => {
    for (let k = p.origin; k < p.origin + p.removed.length && k < o.length; k++) at[k] = i;
  });
  const opener = new Array<boolean>(pieces.length).fill(false);
  const closer = new Array<boolean>(pieces.length).fill(false);
  const first = (s: number, e: number): number => {
    for (let k = s; k < e && k < o.length; k++) {
      if (o[k].trim() !== '') return at[k];
    }
    return -1;
  };
  const whole = (start: number, end: number): boolean => {
    if (!(start < end && at[start] >= 0)) return false;
    for (let k = start; k < end; k++) {
      if (at[k] !== at[start]) return false;
    }
    return true;
  };
  const pair = (start: number, openEnd: number, closeStart: number, end: number): void => {
    if (whole(start, end)) return;
    const po = first(start, openEnd);
    const pc = first(closeStart, end);
    if (po >= 0 && po !== pc) opener[po] = true;
    if (pc >= 0 && pc !== po) closer[pc] = true;
  };
  const walk = (list: NotationElement[]): void => {
    for (const e of list) {
      if (e.type === 'citation') {
        if (whole(e.start, e.end)) continue;
        const po = first(e.start + 1, e.contentStart);
        if (po >= 0) opener[po] = true;
      } else {
        pair(e.start, e.contentStart, e.contentEnd, e.end);
      }
      walk(e.children);
    }
  };
  walk(scanNotation(o, { tomSpecs: true }).elements);
  for (const m of _stripInternals.findMarks(o)) {
    pair(m.start, m.sep >= 0 ? m.sep + 2 : m.bodyStart, m.bodyEnd, m.end);
  }
  return pieces.map((_, i) =>
    opener[i] && closer[i]
      ? _ROLE_BOTH
      : opener[i]
        ? _ROLE_OPENER
        : closer[i]
          ? _ROLE_CLOSER
          : _ROLE_WHOLE,
  );
}

/** Where a gap of the baseline lies in the edited text. */
class _Gap {
  constructor(
    readonly leftEdited: boolean,
    readonly rightEdited: boolean,
    readonly start: number,
    readonly end: number,
  ) {}

  static unchanged(at: number): _Gap {
    return new _Gap(false, false, at, at);
  }

  get at(): number {
    return this.start;
  }

  get unchanged(): boolean {
    return !this.leftEdited && !this.rightEdited && this.start === this.end;
  }
}

/** An edit script from a baseline to an edited text, indexed by baseline offset. */
class _EditMap {
  readonly after: number[];
  readonly eBefore: number[];
  readonly deleted: boolean[];

  constructor(
    readonly ops: _StripOp[],
    bLength: number,
  ) {
    this.after = new Array<number>(bLength + 1).fill(0);
    this.eBefore = new Array<number>(ops.length + 1).fill(0);
    this.deleted = new Array<boolean>(bLength).fill(false);
    let g = 0;
    for (let i = 0; i < ops.length; i++) {
      this.eBefore[i + 1] = this.eBefore[i] + (ops[i].type === DEL ? 0 : 1);
      if (ops[i].type !== INS) {
        if (ops[i].type === DEL) this.deleted[g] = true;
        g++;
        this.after[g] = i + 1;
      }
    }
  }

  gap(g: number): _Gap {
    const ops = this.ops;
    const p = this.after[g];
    const leftEdited = g > 0 && ops[p - 1].type === DEL;
    let r = p;
    while (r < ops.length && ops[r].type === INS) r++;
    const rightEdited = r < ops.length && ops[r].type === DEL;
    if (!leftEdited && r === p && !rightEdited) return _Gap.unchanged(this.eBefore[p]);
    let s = p;
    while (s > 0 && ops[s - 1].type !== KEEP) s--;
    let t = p;
    while (t < ops.length && ops[t].type !== KEEP) t++;
    return new _Gap(leftEdited, rightEdited, this.eBefore[s], this.eBefore[t]);
  }

  /** The edited-text offset of baseline range `[a, z)` kept whole, else -1. */
  keptRange(a: number, z: number): number {
    const first = this.after[a + 1] - 1;
    for (let k = a; k < z; k++) {
      const i = this.after[k + 1] - 1;
      if (this.ops[i].type !== KEEP || i !== first + (k - a)) return -1;
    }
    return this.eBefore[first];
  }
}

/** A line edit script from a baseline to an edited text. */
class _LineEditMap {
  readonly ops: [number, string][];
  readonly after: number[];
  readonly eBefore: number[];

  constructor(b: string, e: string) {
    const bl = _stripInternals.lines(b);
    const el = _stripInternals.lines(e);
    this.ops = _stripInternals.myers(bl, el);
    this.after = new Array<number>(bl.length + 1).fill(0);
    this.eBefore = new Array<number>(this.ops.length + 1).fill(0);
    let k = 0;
    for (let i = 0; i < this.ops.length; i++) {
      const [type, line] = this.ops[i];
      this.eBefore[i + 1] = this.eBefore[i] + (type === DEL ? 0 : line.length);
      if (type !== INS) {
        k++;
        this.after[k] = i + 1;
      }
    }
  }

  gap(k: number): _Gap {
    const ops = this.ops;
    const p = this.after[k];
    const leftEdited = k > 0 && ops[p - 1][0] === DEL;
    let r = p;
    while (r < ops.length && ops[r][0] === INS) r++;
    const rightEdited = r < ops.length && ops[r][0] === DEL;
    if (!leftEdited && r === p && !rightEdited) return _Gap.unchanged(this.eBefore[p]);
    let s = p;
    while (s > 0 && ops[s - 1][0] !== KEEP) s--;
    let t = p;
    while (t < ops.length && ops[t][0] !== KEEP) t++;
    return new _Gap(leftEdited, rightEdited, this.eBefore[s], this.eBefore[t]);
  }

  /** See the Dart `_LineEditMap.paragraphPlace`. */
  paragraphPlace(gap: _Gap, k: number): number {
    const ops = this.ops;
    const p = this.after[k];
    let s = p;
    while (s > 0 && ops[s - 1][0] !== KEEP) s--;
    let before = 0;
    let blank = true;
    for (let i = s; i < p; i++) {
      const [type, line] = ops[i];
      if (type !== DEL) continue;
      const isBlank = line.trim() === '';
      if (!isBlank && blank) before++;
      blank = isBlank;
    }
    if (before === 0) return gap.start;
    let count = 0;
    blank = true;
    for (let i = s; i < ops.length && ops[i][0] !== KEEP; i++) {
      const [type, line] = ops[i];
      if (type !== INS) continue;
      const isBlank = line.trim() === '';
      if (!isBlank && blank) {
        if (count === before) return this.eBefore[i];
        count++;
      }
      blank = isBlank;
    }
    return gap.end;
  }
}

/** See the Dart `_slide`. */
function _slide(ops: _StripOp[], leading: boolean): _StripOp[] {
  const out = ops.slice();
  const ws = (c: string): boolean => c.trim() === '';
  let s = 0;
  while (s < out.length) {
    if (out[s].type === KEEP) {
      s++;
      continue;
    }
    let t = s;
    while (t < out.length && out[t].type === out[s].type) t++;
    if (t < out.length && out[t].type !== KEEP) {
      while (t < out.length && out[t].type !== KEEP) t++;
      s = t;
      continue;
    }
    const type = out[s].type;
    if (leading) {
      while (
        s > 0 &&
        out[s - 1].type === KEEP &&
        ws(out[t - 1].char) &&
        out[s - 1].char === out[t - 1].char
      ) {
        out[t - 1] = { type: KEEP, char: out[t - 1].char, label: null };
        out[s - 1] = { type, char: out[s - 1].char, label: 'edit' };
        s--;
        t--;
      }
    } else {
      while (
        t < out.length &&
        out[t].type === KEEP &&
        ws(out[s].char) &&
        out[s].char === out[t].char
      ) {
        out[s] = { type: KEEP, char: out[s].char, label: null };
        out[t] = { type, char: out[t].char, label: 'edit' };
        s++;
        t++;
      }
    }
    s = t;
  }
  return out;
}

function _lineIndex(b: string, g: number): number {
  let k = 0;
  for (let i = 0; i < g; i++) {
    if (b.charCodeAt(i) === 0x0a) k++;
  }
  if (g === b.length && b.length > 0 && !b.endsWith('\n')) k++;
  return k;
}

/** See the Dart `_sentenceRemoved`. */
function _sentenceRemoved(b: string, g: number, map: _EditMap): boolean {
  const ends = (i: number): boolean =>
    '.!?'.includes(b[i]) && (i + 1 >= b.length || b[i + 1].trim() === '');
  let s = g;
  while (s > 0 && b[s - 1] !== '\n' && !(s - 1 < g - 1 && ends(s - 1))) s--;
  let e = g;
  while (e < b.length && b[e] !== '\n') {
    if (ends(e)) {
      e++;
      break;
    }
    e++;
  }
  let any = false;
  for (let i = s; i < e; i++) {
    if (b[i].trim() === '') continue;
    any = true;
    if (!map.deleted[i]) return false;
  }
  return any;
}

function _trailingBreaks(s: string): number {
  let n = 0;
  for (let i = s.length - 1; i >= 0 && s[i] === '\n'; i--) n++;
  return n;
}

function _leadingBreaks(s: string): number {
  let n = 0;
  for (let i = 0; i < s.length && s[i] === '\n'; i++) n++;
  return n;
}

function _excerpt(s: string, at: number): string {
  const a = Math.max(0, Math.min(at, s.length) - 30);
  const z = Math.min(s.length, at + 30);
  return _visible(s.substring(a, z));
}

/** The first offset at which `a` and `b` differ (the shorter length when one is a prefix of the other). */
function _firstDifference(a: string, b: string): number {
  const n = Math.min(a.length, b.length);
  for (let i = 0; i < n; i++) {
    if (a.charCodeAt(i) !== b.charCodeAt(i)) return i;
  }
  return n;
}

function _visible(s: string): string {
  return `«${s.split('\n').join('⏎')}»`;
}

function _listEq(a: string[], b: string[]): boolean {
  return a.length === b.length && a.every((x, i) => x === b[i]);
}
