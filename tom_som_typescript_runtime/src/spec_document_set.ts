/**
 * A project's specification documents read side by side, one per root, and
 * the validation of the set (`tom_specs_model_rules.md` §9.7): the places a
 * Phase 3 document shares with the Solution Blueprint agree, element by
 * element and value by value, and the links that cross two documents hold.
 *
 * The documents are never assembled into one: each keeps its own registry,
 * and every finding names the document a place is in. {@link syncReport}
 * writes nothing; {@link renameId} renames an id in every document at once.
 *
 * A port of `tom_som_dart_runtime/lib/src/spec_document_set.dart`. The
 * comparison internals (`SpecSetCheck`, `SpecSetSide`, `SpecSetOrdered`) are
 * exported for `backfill` and `prefill`, which read them.
 */

import { readFileSync } from 'fs';

import { deriveFields } from './spec_derive_fields';
import { SpecDocument } from './spec_document';
import { validateLinks } from './spec_links_validator';
import { buildSomMetaTree } from './spec_meta_bridge';
import { SomMetaTree } from './spec_meta';
import {
  FormFieldSpec,
  SpecClass,
  SpecFieldKind,
  SpecListRelation,
  SpecModel,
  SpecSummaryOf,
  SpecSync,
} from './spec_model';
import {
  SpecPlace,
  SpecPlaceException,
  SpecPlaceFilter,
  SpecPlaceKind,
  SpecPlaceResolution,
  SpecSameAsBinding,
  SpecSectionPosition,
  specSameAsBindings,
  specSectionPositions,
} from './spec_place';
import { SpecNodeKind, SpecReflection } from './spec_reflection';
import { K_SPEC_HEADLINE_FIELD, applyInlineMarksText } from './spec_review_annotations';
import { K_SECTION_ID_SLOT, effectiveListItemSectionId } from './spec_section_id';
import {
  SpecValidationCode,
  SpecValidationError,
  validateDocument,
} from './spec_validator';

// ---------------------------------------------------------------------------
// The vocabulary of the set
// ---------------------------------------------------------------------------

/** What a finding of the set reports (in the order the report sorts by). */
export const SpecSyncCode = {
  /** Both documents hold the shared place, and the values differ. */
  SHARED_VALUE_DIFFERS: 'sharedValueDiffers',
  /** The Phase 3 document fills a shared place the Blueprint leaves empty. */
  SHARED_VALUE_MISSING: 'sharedValueMissing',
  /**
   * The Blueprint fills a shared place the Phase 3 document leaves empty;
   * the Phase 3 document emptied it, so `backfill` clears it.
   */
  SHARED_VALUE_ONLY_IN_BLUEPRINT: 'sharedValueOnlyInBlueprint',
  /**
   * An element of an `equal` list (or an id of an `equal` reference field)
   * is only in the Phase 3 document.
   */
  SHARED_ELEMENT_MISSING: 'sharedElementMissing',
  /**
   * An element (or id) is only in the Blueprint, under `equal` or `subset`;
   * `backfill` removes it.
   */
  SHARED_ELEMENT_ONLY_IN_BLUEPRINT: 'sharedElementOnlyInBlueprint',
  /**
   * Under `subset`, an element (or id) only in the Phase 3 document: it may
   * be added to the Blueprint, and is not carried in.
   */
  SHARED_ELEMENT_MAY_BE_ADDED: 'sharedElementMayBeAdded',
  /**
   * A `@SummaryOf(document:)` whose summary and detail sit in two documents
   * does not hold.
   */
  CROSS_SUMMARY_MISMATCH: 'crossSummaryMismatch',
  /** An `inverseOf` whose two ends sit in two documents is one-sided. */
  CROSS_INVERSE_MISSING: 'crossInverseMissing',
  /** A value holding pending change marks, listed for the user. */
  PENDING_REVIEW: 'pendingReview',
  /**
   * A change `deriveFields` would write in a document under review that
   * cannot be marked exactly.
   */
  UNMARKABLE: 'unmarkable',
} as const;

export type SpecSyncCodeValue = (typeof SpecSyncCode)[keyof typeof SpecSyncCode];

const _CODES: SpecSyncCodeValue[] = Object.values(SpecSyncCode);

/** The position of `code` in the declaration order. */
export function specSyncCodeIndex(code: SpecSyncCodeValue): number {
  return _CODES.indexOf(code);
}

/** How a finding of the set is resolved. */
export const SpecSyncResolution = {
  /** `backfill` resolves it, writing the Blueprint. */
  BACKFILL: 'backfill',
  /** `deriveFields` resolves it. */
  DERIVE_FIELDS: 'deriveFields',
  /** The agent decides (or asks the user). */
  AGENT: 'agent',
  /** Reported, not a finding: it does not hold up a gate. */
  INFO: 'info',
} as const;

export type SpecSyncResolutionValue =
  (typeof SpecSyncResolution)[keyof typeof SpecSyncResolution];

const _RESOLUTIONS: SpecSyncResolutionValue[] = Object.values(SpecSyncResolution);

/** Which document holds a shared place's value. */
export const SpecSyncHolder = {
  /** The Phase 3 document (the default). */
  DETAIL: 'detail',
  /** The Blueprint (`@SyncedWith(heldHere:)`). */
  BLUEPRINT: 'blueprint',
} as const;

export type SpecSyncHolderValue = (typeof SpecSyncHolder)[keyof typeof SpecSyncHolder];

/** Why a document set cannot be built. */
export const SpecDocumentSetRefusal = {
  /** Two documents populate one root. */
  SAME_ROOT: 'sameRoot',
  /** A document populates no root. */
  NO_ROOT: 'noRoot',
  /** A document populates two roots. */
  TWO_ROOTS: 'twoRoots',
  /** A document is the CodeSpecs projection, which is no specification. */
  PROJECTION: 'projection',
  /** Fragments of one root overlap. */
  OVERLAP: 'overlap',
  /**
   * A synced class's positions in the Blueprint and its document cannot be
   * paired (invariant `SHARED-ANCHOR`).
   */
  UNPAIRABLE: 'unpairable',
} as const;

export type SpecDocumentSetRefusalValue =
  (typeof SpecDocumentSetRefusal)[keyof typeof SpecDocumentSetRefusal];

/** A document set that cannot be built, with the documents it names. */
export class SpecDocumentSetError extends Error {
  /** Why. */
  readonly refusal: SpecDocumentSetRefusalValue;
  /** The documents (or fragments) concerned, in the order given. */
  readonly documents: string[];
  /** For {@link SpecDocumentSetRefusal.UNPAIRABLE}, the class. */
  readonly className: string | null;

  constructor(
    refusal: SpecDocumentSetRefusalValue,
    documents: string[],
    message: string,
    className: string | null = null,
  ) {
    super(message);
    this.name = 'SpecDocumentSetError';
    this.refusal = refusal;
    this.documents = documents;
    this.className = className;
  }

  /** The canonical JSON form the corpus compares (no message). */
  toJson(): Record<string, unknown> {
    return {
      refusal: this.refusal,
      documents: this.documents,
      ...(this.className !== null ? { className: this.className } : {}),
    };
  }

  toString(): string {
    return `SpecDocumentSetError(${this.refusal}): ${this.message}`;
  }
}

/**
 * A class kept in sync between the Blueprint and a Phase 3 document: its
 * position in each root.
 */
export class SpecSyncPair {
  /** The class carrying `@SyncedWith` / `@DetailedIn`. */
  readonly className: string;
  /** Its section id: the name of the pair in findings and filters. */
  readonly sectionId: string;
  /** The anchor in the Blueprint root (list items written `<list>-*`). */
  readonly blueprintAnchor: string;
  /** The anchor in the Phase 3 root. */
  readonly detailAnchor: string;
  /** The Phase 3 root's class name. */
  readonly detailRoot: string;
  /** The class's `@SyncedWith`, or null when only `@DetailedIn` is declared. */
  readonly sync: SpecSync | null;

  constructor(props: {
    className: string;
    sectionId: string;
    blueprintAnchor: string;
    detailAnchor: string;
    detailRoot: string;
    sync?: SpecSync | null;
  }) {
    this.className = props.className;
    this.sectionId = props.sectionId;
    this.blueprintAnchor = props.blueprintAnchor;
    this.detailAnchor = props.detailAnchor;
    this.detailRoot = props.detailRoot;
    this.sync = props.sync != null ? props.sync : null;
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return {
      pair: this.sectionId,
      className: this.className,
      blueprint: this.blueprintAnchor,
      detail: this.detailAnchor,
      detailRoot: this.detailRoot,
    };
  }
}

function _cmp(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

function _sorted(values: Iterable<string>): string[] {
  return Array.from(values).sort(_cmp);
}

function _fileName(path: string): string {
  const parts = path.split('/');
  return parts[parts.length - 1];
}

function _escapeRegExp(text: string): string {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// ---------------------------------------------------------------------------
// The set
// ---------------------------------------------------------------------------

/** A project's specification documents, one per root, read side by side. */
export class SpecDocumentSet {
  /** The model the set is read with. */
  readonly model: SpecModel;
  /** The model's reflection. */
  readonly refl: SpecReflection;
  /** The Blueprint's root class name: the root the others are `basedOn`. */
  readonly blueprintRoot: string | null;

  private readonly _documents = new Map<string, SpecDocument>();
  private readonly _rootOf = new Map<string, string>();
  private readonly _pairs: SpecSyncPair[];

  /**
   * `documents`: name (the file name the tools use) → document, as a `Map`
   * or `[name, document]` pairs. Each document populates exactly one root;
   * two documents of one root, a document with no populated root or with
   * two, and the CodeSpecs projection are refused with a
   * {@link SpecDocumentSetError} naming the documents, as is a model whose
   * synced positions cannot be paired.
   */
  constructor(model: SpecModel, documents: Iterable<readonly [string, SpecDocument]> = []) {
    this.model = model;
    this.refl = new SpecReflection(model);
    this.blueprintRoot = this._computeBlueprintRoot();
    this._pairs = this._computePairs();
    for (const [name, doc] of documents) {
      this.put(name, doc);
    }
  }

  /**
   * Loads YAML or SOM Markdown files; files of one root are fragments and
   * are assembled first (refusing overlaps). Each document is named by its
   * first file's name.
   */
  static load(model: SpecModel, files: Iterable<string>): SpecDocumentSet {
    const trees = new Map<string, SomMetaTree>();
    const fragments = new Map<string, SpecDocument>();
    for (const file of files) {
      const text = readFileSync(file, 'utf8');
      let doc: SpecDocument;
      if (file.endsWith('.md')) {
        doc = SpecDocument.fromMarkdown(text, model).document;
      } else {
        // The root key `<SECTIONID> <Type>:` names the tree to decode with.
        const root = model.roots.find((r) =>
          new RegExp(
            `^\\s*${_escapeRegExp(r.sectionId ?? '')} ${_escapeRegExp(r.type)}:`,
            'm',
          ).test(text),
        );
        if (root === undefined) {
          throw new SpecDocumentSetError(
            SpecDocumentSetRefusal.NO_ROOT,
            [_fileName(file)],
            `${_fileName(file)} names no root of the model`,
          );
        }
        let tree = trees.get(root.type);
        if (tree === undefined) {
          tree = buildSomMetaTree(model, root.type);
          trees.set(root.type, tree);
        }
        doc = SpecDocument.fromYaml(text, tree);
      }
      fragments.set(_fileName(file), doc);
    }
    return SpecDocumentSet.fromFragments(model, fragments);
  }

  /**
   * Builds a set from documents and fragments: `fragments` maps a name to a
   * document; those of one root are fragments of one document, assembled in
   * the order given (overlaps refused), the document named by its first
   * fragment's name.
   */
  static fromFragments(
    model: SpecModel,
    fragments: Iterable<readonly [string, SpecDocument]>,
  ): SpecDocumentSet {
    const refl = new SpecReflection(model);
    const byRoot = new Map<string, Map<string, SpecDocument>>();
    for (const [name, doc] of fragments) {
      const roots = SpecDocumentSet._populatedRoots(refl, doc);
      if (roots.length !== 1) {
        throw new SpecDocumentSetError(
          roots.length === 0 ? SpecDocumentSetRefusal.NO_ROOT : SpecDocumentSetRefusal.TWO_ROOTS,
          [name],
          `${name} populates ${roots.length === 0 ? 'no root' : roots.join(' and ')}`,
        );
      }
      let group = byRoot.get(roots[0]);
      if (group === undefined) {
        group = new Map<string, SpecDocument>();
        byRoot.set(roots[0], group);
      }
      group.set(name, doc);
    }
    const documents = new Map<string, SpecDocument>();
    for (const group of byRoot.values()) {
      if (group.size === 1) {
        for (const [k, v] of group) {
          documents.set(k, v);
        }
        continue;
      }
      const assembly = SpecDocument.assemble(group);
      if (!assembly.ok) {
        const names = Array.from(group.keys());
        throw new SpecDocumentSetError(
          SpecDocumentSetRefusal.OVERLAP,
          names,
          `the fragments ${names.join(', ')} overlap`,
        );
      }
      documents.set(group.keys().next().value as string, assembly.document!);
    }
    return new SpecDocumentSet(model, documents);
  }

  private _computeBlueprintRoot(): string | null {
    const targets = new Set<string>();
    for (const r of this.model.roots) {
      const cls = this.refl.classNamed(r.type);
      const doc = cls !== null ? cls.annotation('Document') : null;
      const based = doc !== null ? doc.argument('basedOn') : null;
      if (Array.isArray(based)) {
        for (const e of based) {
          targets.add(`${e}`);
        }
      }
    }
    return targets.size === 1 ? Array.from(targets)[0] : null;
  }

  /** The D00SolutionBlueprint document (the Blueprint), or null. */
  get blueprint(): SpecDocument | null {
    return this.blueprintRoot === null ? null : this.document(this.blueprintRoot);
  }

  /** The document of `rootType` (a type name or a section id), or null. */
  document(rootType: string): SpecDocument | null {
    const name = this.nameOf(rootType);
    return name === null ? null : (this._documents.get(name) ?? null);
  }

  /** The name of the document of `rootType`, or null. */
  nameOf(rootType: string): string | null {
    const type = this._typeOf(rootType);
    for (const [name, root] of this._rootOf) {
      if (root === type) {
        return name;
      }
    }
    return null;
  }

  private _typeOf(rootType: string): string | null {
    for (const r of this.model.roots) {
      if (r.type === rootType || r.sectionId === rootType) {
        return r.type;
      }
    }
    return null;
  }

  private _hasRoot(type: string): boolean {
    for (const v of this._rootOf.values()) {
      if (v === type) {
        return true;
      }
    }
    return false;
  }

  /** The populated roots, in model order. */
  get roots(): string[] {
    return this.model.roots.filter((r) => this._hasRoot(r.type)).map((r) => r.type);
  }

  /** The document names, in model order of their roots. */
  get names(): string[] {
    return this.roots.map((r) => this.nameOf(r)!);
  }

  /**
   * Every Phase 3 root a pair names with no document yet: its pairs are
   * "not started", reported as such and never as findings.
   */
  get missingRoots(): string[] {
    return this.model.roots
      .filter((r) => this._pairs.some((p) => p.detailRoot === r.type) && !this._hasRoot(r.type))
      .map((r) => r.type);
  }

  /** The anchor pairs, in the Blueprint's walk order. */
  get pairs(): readonly SpecSyncPair[] {
    return this._pairs;
  }

  /** Adds or replaces a document (what `prefill` creates). */
  put(name: string, document: SpecDocument): void {
    const roots = SpecDocumentSet._populatedRoots(this.refl, document);
    if (roots.length === 0) {
      throw new SpecDocumentSetError(
        SpecDocumentSetRefusal.NO_ROOT,
        [name],
        `${name} populates no root`,
      );
    }
    if (roots.length > 1) {
      throw new SpecDocumentSetError(
        SpecDocumentSetRefusal.TWO_ROOTS,
        [name],
        `${name} populates ${roots.join(' and ')}`,
      );
    }
    const root = roots[0];
    const cls = this.refl.classNamed(root);
    if (cls !== null && cls.isCodeSpecsProjection) {
      throw new SpecDocumentSetError(
        SpecDocumentSetRefusal.PROJECTION,
        [name],
        `${name} is the CodeSpecs projection, which is no specification`,
      );
    }
    for (const [other, r] of this._rootOf) {
      if (r === root && other !== name) {
        throw new SpecDocumentSetError(
          SpecDocumentSetRefusal.SAME_ROOT,
          [other, name],
          `${other} and ${name} both populate ${root}`,
        );
      }
    }
    this._documents.set(name, document);
    this._rootOf.set(name, root);
  }

  /** The document named `name` (Dart's `operator []`). */
  get(name: string): SpecDocument | null {
    return this._documents.get(name) ?? null;
  }

  /** The root class name of the document named `name`. */
  rootOf(name: string): string | null {
    return this._rootOf.get(name) ?? null;
  }

  private static _populatedRoots(refl: SpecReflection, doc: SpecDocument): string[] {
    const segs = new Set<string>();
    for (const paths of [doc.contentPaths, doc.formPaths, doc.listPaths, doc.headlinePaths]) {
      for (const p of paths) {
        const slash = p.indexOf('/');
        segs.add(slash < 0 ? p : p.substring(0, slash));
      }
    }
    return refl.model.roots.filter((r) => segs.has(refl.rootSegment(r))).map((r) => r.type);
  }

  // -------------------------------------------------------------------------
  // The anchor pairs
  // -------------------------------------------------------------------------

  private _computePairs(): SpecSyncPair[] {
    const bp = this.blueprintRoot;
    if (bp === null) {
      return [];
    }
    const refl = this.refl;
    const positions = new Map<string, SpecSectionPosition[]>();
    const at = (root: string): SpecSectionPosition[] => {
      let hit = positions.get(root);
      if (hit === undefined) {
        const all = specSectionPositions(refl, root);
        // A `@SameAs` copy is kept equal to its holder, never paired.
        const copies = all
          .filter((p) => !p.isMember && p.member !== null && p.member.sameAs !== null)
          .map((p) => p.path);
        hit = all.filter(
          (p) => !p.isMember && !copies.some((c) => p.path === c || p.path.startsWith(`${c}/`)),
        );
        positions.set(root, hit);
      }
      return hit;
    };

    const candidates = new Map<string, string>(); // class → target root
    for (const p of at(bp)) {
      const cls = refl.classNamed(p.className);
      const sync = cls !== null ? cls.syncedWith : null;
      const target = sync !== null ? sync.document : cls !== null ? cls.detailedIn : null;
      if (target === null || target === bp) {
        continue;
      }
      if (refl.classNamed(target) === null) {
        continue;
      }
      if (!candidates.has(p.className)) {
        candidates.set(p.className, target);
      }
    }

    const out: SpecSyncPair[] = [];
    for (const [className, target] of candidates) {
      const mine = at(bp).filter((p) => p.className === className);
      const theirs = at(target).filter((p) => p.className === className);
      if (theirs.length === 0) {
        continue;
      }
      const matched: [SpecSectionPosition, SpecSectionPosition][] = [];
      if (mine.length === 1 && theirs.length === 1) {
        matched.push([mine[0], theirs[0]]);
      } else {
        // Paired by the path below the nearest enclosing anchor.
        const key = (p: SpecSectionPosition, root: string): string => {
          let outer: SpecSectionPosition | null = null;
          for (const q of at(root)) {
            if (q.path === p.path || !p.path.startsWith(`${q.path}/`)) {
              continue;
            }
            if (!candidates.has(q.className)) {
              continue;
            }
            if (outer === null || q.path.length > outer.path.length) {
              outer = q;
            }
          }
          const ids = outer === null ? p.sectionIds : p.sectionIds.slice(outer.sectionIds.length);
          return `${outer !== null ? outer.className : ''}/${ids.join('/')}`;
        };
        const byKey = new Map<string, SpecSectionPosition>();
        for (const p of theirs) {
          const k = key(p, target);
          if (byKey.has(k)) {
            this._unpairable(className);
          }
          byKey.set(k, p);
        }
        for (const p of mine) {
          const k = key(p, bp);
          const q = byKey.get(k);
          if (q === undefined) {
            this._unpairable(className);
          }
          byKey.delete(k);
          matched.push([p, q!]);
        }
        if (byKey.size > 0) {
          this._unpairable(className);
        }
      }
      const cls = refl.classNamed(className)!;
      for (const [b, d] of matched) {
        out.push(
          new SpecSyncPair({
            className,
            sectionId: cls.sectionId ?? className,
            blueprintAnchor: b.path,
            detailAnchor: d.path,
            detailRoot: target,
            sync: cls.syncedWith,
          }),
        );
      }
    }
    return out;
  }

  private _unpairable(className: string): never {
    throw new SpecDocumentSetError(
      SpecDocumentSetRefusal.UNPAIRABLE,
      [],
      `the positions of ${className} in the Blueprint and its document cannot ` +
        'be paired (SHARED-ANCHOR)',
      className,
    );
  }
}

// ---------------------------------------------------------------------------
// Findings and the report
// ---------------------------------------------------------------------------

/** One side of a finding: where the place is and what it holds. */
export class SpecSyncPlace {
  /** The document's name, or null when the set has none for this side. */
  readonly document: string | null;
  /** The root's section id. */
  readonly root: string;
  /**
   * The document path (for a place the document does not hold, the
   * nearest path it does: the list an element would be added to).
   */
  readonly path: string;
  /** The form field, or null. */
  readonly field: string | null;
  /** The value (read with pending marks rejected), or null when absent. */
  readonly value: string | null;
  /** Whether the value holds pending change marks. */
  readonly pendingMarks: boolean;

  constructor(props: {
    document: string | null;
    root: string;
    path: string;
    field?: string | null;
    value?: string | null;
    pendingMarks?: boolean;
  }) {
    this.document = props.document;
    this.root = props.root;
    this.path = props.path;
    this.field = props.field != null ? props.field : null;
    this.value = props.value != null ? props.value : null;
    this.pendingMarks = props.pendingMarks === true;
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return {
      document: this.document,
      root: this.root,
      path: this.path,
      ...(this.field !== null ? { field: this.field } : {}),
      ...(this.value !== null ? { value: this.value } : {}),
      pendingMarks: this.pendingMarks,
    };
  }
}

/** One finding of the set. */
export class SpecSyncFinding {
  /** What it reports. */
  readonly code: SpecSyncCodeValue;
  /**
   * The pair's section id (the summary's or link's class for a cross check,
   * empty for a pending value outside every pair).
   */
  readonly pair: string;
  /** The Blueprint side (for a cross check, the side holding the link). */
  readonly blueprint: SpecSyncPlace;
  /** The Phase 3 side (for a cross check, the other end). */
  readonly detail: SpecSyncPlace;
  /** Which side holds the value. */
  readonly holder: SpecSyncHolderValue;
  /** How it is resolved. */
  readonly resolution: SpecSyncResolutionValue;
  /**
   * Prose for the agent, in the canonical form: every runtime writes the
   * same sentence (the conformance corpus compares it).
   */
  readonly message: string;

  constructor(props: {
    code: SpecSyncCodeValue;
    pair: string;
    blueprint: SpecSyncPlace;
    detail: SpecSyncPlace;
    holder: SpecSyncHolderValue;
    resolution: SpecSyncResolutionValue;
    message: string;
  }) {
    this.code = props.code;
    this.pair = props.pair;
    this.blueprint = props.blueprint;
    this.detail = props.detail;
    this.holder = props.holder;
    this.resolution = props.resolution;
    this.message = props.message;
  }

  /** Whether it is reported only, not a finding. */
  get isInfo(): boolean {
    return this.resolution === SpecSyncResolution.INFO;
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return {
      code: this.code,
      pair: this.pair,
      blueprint: this.blueprint.toJson(),
      detail: this.detail.toJson(),
      holder: this.holder,
      resolution: this.resolution,
      message: this.message,
      info: this.isInfo,
    };
  }
}

/** The validation of a document set. */
export class SpecSyncReport {
  /** The findings in pair and path order, `info` entries included. */
  readonly findings: SpecSyncFinding[];
  /**
   * Each document's own findings (`validateDocument`, then `validateLinks`),
   * by name, in the set's order.
   */
  readonly documentFindings: Map<string, SpecValidationError[]>;
  /** The Phase 3 roots with no document yet. */
  readonly notStarted: string[];
  /**
   * The pairs (by section id) whose Phase 3 document exists but holds
   * nothing beneath the pair's anchor: not started, like a missing document.
   */
  readonly notStartedPairs: string[];

  constructor(props: {
    findings: SpecSyncFinding[];
    documentFindings: Map<string, SpecValidationError[]>;
    notStarted: string[];
    notStartedPairs?: string[];
  }) {
    this.findings = props.findings;
    this.documentFindings = props.documentFindings;
    this.notStarted = props.notStarted;
    this.notStartedPairs = props.notStartedPairs ?? [];
  }

  /** Findings per code, `info` entries included, in code order. */
  countsByCode(): Map<string, number> {
    const out = new Map<string, number>();
    for (const c of _CODES) {
      const n = this.findings.filter((f) => f.code === c).length;
      if (n > 0) {
        out.set(c, n);
      }
    }
    return out;
  }

  /** Findings per resolution, in resolution order. */
  countsByResolution(): Map<string, number> {
    const out = new Map<string, number>();
    for (const r of _RESOLUTIONS) {
      const n = this.findings.filter((f) => f.resolution === r).length;
      if (n > 0) {
        out.set(r, n);
      }
    }
    return out;
  }

  /** No finding other than `info`. */
  get clean(): boolean {
    return this.findings.every((f) => f.isInfo);
  }

  /** The canonical JSON form; every ordered value is a list. */
  toJson(): Record<string, unknown> {
    return {
      findings: this.findings.map((f) => f.toJson()),
      documentFindings: Array.from(this.documentFindings).map(([name, errors]) => [
        name,
        errors.map((x) => ({ path: x.path, code: x.code, message: x.message })),
      ]),
      notStarted: this.notStarted,
      notStartedPairs: this.notStartedPairs,
      countsByCode: Array.from(this.countsByCode()),
      countsByResolution: Array.from(this.countsByResolution()),
      clean: this.clean,
    };
  }
}

/**
 * The validation of `set`, with counts; `pairs` keeps the findings of those
 * pairs (by section id) only. Writes nothing.
 */
export function syncReport(set: SpecDocumentSet, options: { pairs?: Iterable<string> | null } = {}): SpecSyncReport {
  const pairs = options.pairs != null ? new Set(options.pairs) : null;
  const c = new SpecSetCheck(set);
  let index = 0;
  for (const p of set.pairs) {
    if (pairs === null || pairs.has(p.sectionId)) {
      c.comparePair(p, index);
    }
    index++;
  }
  c.crossChecks(pairs, index);
  if (pairs === null) {
    c.pendingScan(index + 1);
    c.unmarkableScan(index + 2);
  }
  c.sortOut();
  const documentFindings = new Map<string, SpecValidationError[]>();
  for (const name of set.names) {
    const doc = set.get(name)!;
    documentFindings.set(name, [...validateDocument(set.model, doc), ...validateLinks(set.model, doc)]);
  }
  return new SpecSyncReport({
    findings: c.out.map((o) => o.finding),
    documentFindings,
    notStarted: set.missingRoots,
    notStartedPairs: c.notStartedPairs,
  });
}

// ---------------------------------------------------------------------------
// The comparison
// ---------------------------------------------------------------------------

/** A finding with its sort keys (and, for a pair's finding, its two sides). */
export interface SpecSetOrdered {
  order: number;
  key: string;
  finding: SpecSyncFinding;
  /** For a finding of a pair, the two sides compared (what backfill reads). */
  b: SpecSetSide | null;
  d: SpecSetSide | null;
}

/** One value of a subtree, keyed for comparison. */
export interface SpecSetValue {
  path: string;
  field: string | null;
  value: string;
  pending: boolean;
  spec: FormFieldSpec | null;
}

/**
 * A document side of a pair: its subtree's values and items, keyed by the
 * path below the anchor with list items written by their section id.
 */
export class SpecSetSide {
  readonly values = new Map<string, SpecSetValue>();
  /** item key → item path, and the anchor's own key ''. */
  readonly items = new Map<string, string>();

  constructor(
    readonly name: string | null,
    readonly root: string,
    readonly anchor: string,
  ) {}
}

/** The places a set of place texts stands for under an anchor. */
export interface SpecSetPlaces {
  prefixes: string[];
  fields: Set<string>;
  headlines: Set<string>;
}

function _numTryParse(text: string): number | null {
  const t = text.trim();
  if (/^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$/i.test(t)) {
    return Number(t);
  }
  if (/^[+-]?0x[0-9a-f]+$/i.test(t)) {
    const neg = t.startsWith('-');
    const v = parseInt(t.replace(/^[+-]/, ''), 16);
    return neg ? -v : v;
  }
  if (/^[+-]?(Infinity|NaN)$/.test(t)) {
    return Number(t);
  }
  return null;
}

/**
 * The comparison behind {@link syncReport} (and `backfill`, `prefill` and
 * {@link renameId}): one per run, with its caches.
 */
export class SpecSetCheck {
  readonly refl: SpecReflection;
  readonly out: SpecSetOrdered[] = [];
  /**
   * The pairs whose Phase 3 document exists but holds nothing beneath the
   * pair's anchor.
   */
  readonly notStartedPairs: string[] = [];

  private readonly _itemIds = new Map<SpecDocument, Map<string, string>>();
  private readonly _items = new Map<string, boolean>();
  private readonly _forms = new Map<SpecDocument, Map<string, string[]>>();
  private readonly _registryDocs = new Map<string, string | null>();
  private readonly _reach = new Map<string, Set<string>>();
  private readonly _entries = new Map<SpecDocument, Map<string, Map<string, string>>>();
  private readonly _sameAs = new Map<string, SpecSameAsBinding[]>();

  constructor(readonly set: SpecDocumentSet) {
    this.refl = set.refl;
  }

  add(
    order: number,
    key: string,
    finding: SpecSyncFinding,
    sides: { b?: SpecSetSide | null; d?: SpecSetSide | null } = {},
  ): void {
    this.out.push({ order, key, finding, b: sides.b ?? null, d: sides.d ?? null });
  }

  /** Sorts {@link out} as the report lists it. */
  sortOut(): void {
    this.out.sort((a, b) => {
      if (a.order !== b.order) {
        return a.order - b.order;
      }
      const k = _cmp(a.key, b.key);
      if (k !== 0) {
        return k;
      }
      const x = specSyncCodeIndex(a.finding.code) - specSyncCodeIndex(b.finding.code);
      if (x !== 0) {
        return x;
      }
      return _cmp(
        a.finding.blueprint.value ?? a.finding.detail.value ?? '',
        b.finding.blueprint.value ?? b.finding.detail.value ?? '',
      );
    });
  }

  rootSeg(type: string): string {
    return this.refl.rootSegment(this.refl.model.roots.find((r) => r.type === type)!);
  }

  // --- values ---------------------------------------------------------------

  static reviewed(raw: string): string {
    return applyInlineMarksText(raw, { accept: false }).trim();
  }

  static isPending(raw: string): boolean {
    return (
      applyInlineMarksText(raw, { accept: true }) !== applyInlineMarksText(raw, { accept: false })
    );
  }

  /** The effective section id of the list item at `itemPath` in `doc`. */
  itemId(doc: SpecDocument, itemPath: string): string {
    let byDoc = this._itemIds.get(doc);
    if (byDoc === undefined) {
      byDoc = new Map<string, string>();
      this._itemIds.set(doc, byDoc);
    }
    let id = byDoc.get(itemPath);
    if (id === undefined) {
      id = this._computeItemId(doc, itemPath);
      byDoc.set(itemPath, id);
    }
    return id;
  }

  private _computeItemId(doc: SpecDocument, itemPath: string): string {
    const stored = doc.itemSectionId(itemPath);
    if (stored !== null) {
      return stored;
    }
    const list = itemPath.substring(0, itemPath.lastIndexOf('-'));
    const res = this.refl.resolve(list);
    const field = res !== null ? res.field : null;
    const segs = list.split('/');
    return effectiveListItemSectionId(
      null,
      field !== null ? field.sectionIdPattern : null,
      doc.listItems(list).indexOf(itemPath) + 1,
      field !== null ? field.name : segs[segs.length - 1],
    );
  }

  /** Whether `path` is a list item (complex or scalar). */
  isItem(path: string): boolean {
    let hit = this._items.get(path);
    if (hit === undefined) {
      // A scalar list's items are elements too, keyed by their effective id
      // like a complex list's (`LIST[ID]`).
      const r = this.refl.resolve(path);
      hit =
        r !== null &&
        (r.kind === SpecNodeKind.LIST_ITEM_COMPLEX || r.kind === SpecNodeKind.LIST_ITEM_SCALAR);
      this._items.set(path, hit);
    }
    return hit;
  }

  /** The concrete paths a pattern (list items `<list>-*`) stands for in `doc`. */
  expand(doc: SpecDocument, pattern: string): string[] {
    let paths: string[] = [''];
    for (const seg of pattern.split('/')) {
      const next: string[] = [];
      for (const p of paths) {
        const base = p === '' ? seg : `${p}/${seg}`;
        if (seg.endsWith('-*')) {
          next.push(...doc.listItems(base.substring(0, base.length - 2)));
        } else {
          next.push(base);
        }
      }
      paths = next;
    }
    return paths;
  }

  /** The key of `path` below `anchor`: item segments as `LIST[id]`. */
  key(doc: SpecDocument, anchor: string, path: string): string {
    if (path === anchor) {
      return '';
    }
    const out: string[] = [];
    let at = anchor;
    for (const seg of path.substring(anchor.length + 1).split('/')) {
      at = `${at}/${seg}`;
      out.push(
        this.isItem(at) ? `${seg.substring(0, seg.lastIndexOf('-'))}[${this.itemId(doc, at)}]` : seg,
      );
    }
    return out.join('/');
  }

  /**
   * The key of an anchor itself among its siblings: the ids of the list
   * items on its path.
   */
  anchorKey(doc: SpecDocument, path: string): string {
    const out: string[] = [];
    let at = '';
    for (const seg of path.split('/')) {
      at = at === '' ? seg : `${at}/${seg}`;
      if (this.isItem(at)) {
        out.push(this.itemId(doc, at));
      }
    }
    return out.join('/');
  }

  /**
   * The paths a place resolved under `anchor` stands for in `doc`: whole
   * sections (prefixes) and single form fields.
   */
  places(doc: SpecDocument, places: Iterable<string>, anchor: string): SpecSetPlaces {
    const prefixes: string[] = [];
    const fields = new Set<string>();
    const headlines = new Set<string>();
    for (const text of places) {
      let r: SpecPlaceResolution;
      try {
        r = SpecPlace.parse(text).resolve(this.refl, anchor);
      } catch (e) {
        if (e instanceof SpecPlaceException) {
          continue;
        }
        throw e;
      }
      for (const p of this.expand(doc, r.path)) {
        switch (r.kind) {
          case SpecPlaceKind.FORM_FIELD:
            fields.add(`${p}#${r.field}`);
            break;
          case SpecPlaceKind.HEADLINE:
            headlines.add(p);
            break;
          case SpecPlaceKind.SECTION_ID:
            break;
          default:
            prefixes.push(p);
        }
      }
    }
    return { prefixes, fields, headlines };
  }

  static underAny(path: string, prefixes: Iterable<string>): boolean {
    for (const p of prefixes) {
      if (path === p || path.startsWith(`${p}/`)) {
        return true;
      }
    }
    return false;
  }

  /**
   * The values beneath `anchor` in `doc`, with what the pair does not
   * compare left out: `detailOnly` places, nested pairs, `@SameAs` copies
   * and derived places.
   */
  collect(
    name: string | null,
    doc: SpecDocument,
    root: string,
    anchor: string,
    pair: SpecSyncPair,
    nested: string[],
  ): SpecSetSide {
    const refl = this.refl;
    const side = new SpecSetSide(name, root, anchor);
    const skip = this.places(doc, pair.sync !== null ? pair.sync.detailOnly : [], anchor);
    let bindings = this._sameAs.get(root);
    if (bindings === undefined) {
      bindings = specSameAsBindings(refl, root);
      this._sameAs.set(root, bindings);
    }
    const excluded: string[] = [...skip.prefixes, ...nested];
    for (const b of bindings) {
      excluded.push(...this.expand(doc, b.copyPath));
    }
    const under = (p: string): boolean => p === anchor || p.startsWith(`${anchor}/`);
    const outside = (p: string): boolean => p !== anchor && SpecSetCheck.underAny(p, excluded);

    // The values a summary row repeats are derived from its detail element
    // (`@SummaryOf` repeats): never shared, like every derived place.
    for (const list of doc.listPaths) {
      if (!under(list)) {
        continue;
      }
      const res = refl.resolve(list);
      const s = res !== null && res.field !== null ? res.field.summaryOf : null;
      const repeats = s !== null ? Object.keys(s.repeats) : [];
      if (repeats.length === 0) {
        continue;
      }
      for (const item of doc.listItems(list)) {
        const r = this.places(doc, repeats, item);
        excluded.push(...r.prefixes);
        for (const f of r.fields) {
          skip.fields.add(f);
        }
        for (const h of r.headlines) {
          skip.headlines.add(h);
        }
      }
    }

    side.items.set('', anchor);
    for (const list of doc.listPaths) {
      if (!under(list) || outside(list)) {
        continue;
      }
      const res = refl.resolve(list);
      if (res !== null && res.field !== null && res.field.derivedFrom !== null) {
        excluded.push(list);
        continue;
      }
      for (const item of doc.listItems(list)) {
        side.items.set(this.key(doc, anchor, item), item);
      }
    }
    for (const p of doc.contentPaths) {
      if (!under(p) || outside(p)) {
        continue;
      }
      const res = refl.resolve(p);
      if (res !== null && res.field !== null && res.field.derivedFrom !== null) {
        continue;
      }
      const raw = doc.content(p) ?? '';
      side.values.set(`c:${this.key(doc, anchor, p)}`, {
        path: p,
        field: null,
        value: SpecSetCheck.reviewed(raw),
        pending: SpecSetCheck.isPending(raw),
        spec: null,
      });
    }
    for (const p of doc.formPaths) {
      if (!under(p) || outside(p)) {
        continue;
      }
      const res = refl.resolve(p);
      const specs = res !== null && res.field !== null ? res.field.formFields : [];
      for (const field of doc.formFieldNames(p)) {
        if (skip.fields.has(`${p}#${field}`)) {
          continue;
        }
        const spec = specs.find((f) => f.name === field) ?? null;
        if (
          spec !== null &&
          (spec.derivedFrom !== null ||
            spec.countOf.length > 0 ||
            spec.productOf.length > 0 ||
            spec.rankOf !== null)
        ) {
          continue;
        }
        const raw = doc.formField(p, field) ?? '';
        side.values.set(`f:${this.key(doc, anchor, p)}#${field}`, {
          path: p,
          field,
          value: SpecSetCheck.reviewed(raw),
          pending: SpecSetCheck.isPending(raw),
          spec,
        });
      }
    }
    for (const p of doc.headlinePaths) {
      if (!under(p) || outside(p) || skip.headlines.has(p)) {
        continue;
      }
      const raw = doc.headline(p) ?? '';
      side.values.set(`h:${this.key(doc, anchor, p)}`, {
        path: p,
        field: K_SPEC_HEADLINE_FIELD,
        value: SpecSetCheck.reviewed(raw),
        pending: SpecSetCheck.isPending(raw),
        spec: null,
      });
    }
    return side;
  }

  /**
   * The path `key` stands for on `side`: the item paths it names as far as
   * the side holds them; where it stops, the list an element would go in.
   */
  pathOn(side: SpecSetSide, key: string): string {
    if (key === '') {
      return side.anchor;
    }
    let path = side.anchor;
    let prefix = '';
    for (const s of key.split('/')) {
      prefix = prefix === '' ? s : `${prefix}/${s}`;
      const bracket = s.indexOf('[');
      if (bracket > 0) {
        const item = side.items.get(prefix);
        if (item === undefined) {
          return `${path}/${s.substring(0, bracket)}`;
        }
        path = item;
      } else {
        path = `${path}/${s}`;
      }
    }
    return path;
  }

  static sameTyped(a: string, b: string, spec: FormFieldSpec | null): boolean {
    const t = spec !== null ? spec.type : null;
    if (t === 'int' || t === 'double' || t === 'num') {
      const x = _numTryParse(a);
      const y = _numTryParse(b);
      if (x !== null && y !== null) {
        return x === y;
      }
    }
    if (t === 'bool') {
      return a.toLowerCase() === b.toLowerCase();
    }
    return a === b;
  }

  static ids(value: string): string[] {
    const out: string[] = [];
    for (const s of value.split(',')) {
      if (s.trim() !== '') {
        out.push(s.trim());
      }
    }
    return out;
  }

  // --- one pair -------------------------------------------------------------

  comparePair(pair: SpecSyncPair, order: number): void {
    const set = this.set;
    const bpName = set.nameOf(set.blueprintRoot!);
    const dtName = set.nameOf(pair.detailRoot);
    if (bpName === null || dtName === null) {
      return; // not started
    }
    const bp = set.get(bpName)!;
    const dt = set.get(dtName)!;
    const bpRoot = set.blueprintRoot!;

    // Nested pairs are compared on their own.
    const nested = (doc: SpecDocument, blueprintSide: boolean): string[] => {
      const out: string[] = [];
      for (const other of set.pairs) {
        if (other !== pair && (blueprintSide || other.detailRoot === pair.detailRoot)) {
          out.push(
            ...this.expand(doc, blueprintSide ? other.blueprintAnchor : other.detailAnchor),
          );
        }
      }
      return out;
    };

    const bpAnchors = new Map<string, string>();
    for (const a of this.expand(bp, pair.blueprintAnchor)) {
      bpAnchors.set(this.anchorKey(bp, a), a);
    }
    const dtAnchors = new Map<string, string>();
    for (const a of this.expand(dt, pair.detailAnchor)) {
      dtAnchors.set(this.anchorKey(dt, a), a);
    }
    // A pair the Phase 3 document has not written yet is not started, never
    // findings: it is what prefill fills, and backfill must not take its
    // emptiness for removals.
    if (!Array.from(dtAnchors.values()).some((a) => dt.hasValuesUnder(a))) {
      this.notStartedPairs.push(pair.sectionId);
      return;
    }
    let bpNested: string[] | null = null;
    let dtNested: string[] | null = null;
    for (const k of new Set([...bpAnchors.keys(), ...dtAnchors.keys()])) {
      const ba = bpAnchors.get(k);
      const da = dtAnchors.get(k);
      if (ba === undefined || da === undefined) {
        continue; // the outer list reports it
      }
      if (bpNested === null) {
        bpNested = nested(bp, true);
        dtNested = nested(dt, false);
      }
      const b = this.collect(
        bpName,
        bp,
        bpRoot,
        ba,
        pair,
        bpNested.filter((p) => p.startsWith(`${ba}/`)),
      );
      const d = this.collect(
        dtName,
        dt,
        pair.detailRoot,
        da,
        pair,
        dtNested!.filter((p) => p.startsWith(`${da}/`)),
      );
      this._compare(pair, order, b, d, bp, dt);
    }
  }

  private _compare(
    pair: SpecSyncPair,
    order: number,
    b: SpecSetSide,
    d: SpecSetSide,
    bp: SpecDocument,
    dt: SpecDocument,
  ): void {
    const refl = this.refl;
    const sync = pair.sync;
    // Relations: list key → (relation, where); field key → relation.
    const listRel = new Map<string, { relation: string; where: string | null }>();
    const fieldRel = new Map<string, string>();
    const relations: SpecListRelation[] = sync !== null ? sync.relations : [];
    for (const r of relations) {
      let res: SpecPlaceResolution;
      try {
        res = SpecPlace.parse(r.place).resolve(refl, b.anchor);
      } catch (e) {
        if (e instanceof SpecPlaceException) {
          continue;
        }
        throw e;
      }
      for (const p of this.expand(bp, res.path)) {
        const key = this.key(bp, b.anchor, p);
        if (res.kind === SpecPlaceKind.LIST) {
          listRel.set(key, { relation: r.relation, where: r.where });
        } else if (res.kind === SpecPlaceKind.FORM_FIELD) {
          fieldRel.set(`${key}#${res.field}`, r.relation);
        }
      }
    }
    // A relation stated for a form field is the same for every element:
    // match it by its key with item ids dropped.
    const shape = (key: string): string => key.replace(/\[[^\]]*\]/g, '[]');
    const fieldRelByShape = new Map<string, string>();
    for (const [k, v] of fieldRel) {
      fieldRelByShape.set(shape(k), v);
    }
    const held = this.places(bp, sync !== null ? sync.heldHere : [], b.anchor);
    const isHeld = (bpPath: string, field: string | null = null): boolean =>
      SpecSetCheck.underAny(bpPath, held.prefixes) ||
      (field !== null && held.fields.has(`${bpPath}#${field}`));

    const place = (
      s: SpecSetSide,
      key: string,
      field: string | null,
      value: string | null,
    ): SpecSyncPlace => {
      const v = s.values.get(key);
      return new SpecSyncPlace({
        document: s.name,
        root: this.rootSeg(s.root),
        path:
          v !== undefined
            ? v.path
            : this.pathOn(s, key.startsWith('i:') ? key.substring(2) : SpecSetCheck.stripKind(key)),
        field: field ?? (v !== undefined ? v.field : null),
        value: value ?? (v !== undefined ? v.value : null),
        pendingMarks: v !== undefined ? v.pending : false,
      });
    };

    const emit = (
      code: SpecSyncCodeValue,
      key: string,
      message: string,
      o: {
        heldHere: boolean;
        field?: string | null;
        bValue?: string | null;
        dValue?: string | null;
        resolution?: SpecSyncResolutionValue | null;
      },
    ): void => {
      this.add(
        order,
        key,
        new SpecSyncFinding({
          code,
          pair: pair.sectionId,
          blueprint: place(b, key, o.field ?? null, o.bValue ?? null),
          detail: place(d, key, o.field ?? null, o.dValue ?? null),
          holder: o.heldHere ? SpecSyncHolder.BLUEPRINT : SpecSyncHolder.DETAIL,
          resolution:
            o.resolution ??
            (o.heldHere ? SpecSyncResolution.AGENT : SpecSyncResolution.BACKFILL),
          message,
        }),
        { b, d },
      );
    };

    // Elements.
    const oneSided: string[] = [];
    const itemKeys = _sorted(new Set([...b.items.keys(), ...d.items.keys()]));
    for (const k of itemKeys) {
      if (k === '') {
        continue;
      }
      const inB = b.items.has(k);
      const inD = d.items.has(k);
      if (inB === inD) {
        continue;
      }
      if (oneSided.some((o) => k.startsWith(`${o}/`))) {
        continue;
      }
      oneSided.push(k);
      // `LIST[ID]` (every item key, `key`); a key without the brackets
      // names its element by its last segment.
      const bracket = k.lastIndexOf('[');
      const parentList =
        bracket < 0 ? (k.includes('/') ? k.substring(0, k.lastIndexOf('/')) : '') : k.substring(0, bracket);
      const rel = listRel.get(parentList);
      let relation = rel !== undefined ? rel.relation : 'equal';
      const itemPath = inB ? b.items.get(k)! : d.items.get(k)!;
      const doc = inB ? bp : dt;
      if (rel !== undefined && rel.where !== null) {
        const filter = SpecPlaceFilter.tryParse(rel.where);
        if (
          filter !== null &&
          filter.field !== null &&
          !filter.matches(this.ownValues(doc, itemPath, filter.field))
        ) {
          relation = 'equal';
        }
      }
      const segs = k.split('/');
      const id = bracket < 0 ? segs[segs.length - 1] : k.substring(bracket + 1, k.length - 1);
      const heldHere = isHeld(inB ? itemPath : this.pathOn(b, k));
      const key = `i:${k}`;
      if (inD) {
        if (relation === 'subset') {
          emit(
            SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED,
            key,
            `${id} is only in ${d.name}; under subset it may be added to ${b.name}`,
            { heldHere, dValue: id, resolution: SpecSyncResolution.INFO },
          );
        } else {
          emit(SpecSyncCode.SHARED_ELEMENT_MISSING, key, `${id} is in ${d.name} and missing in ${b.name}`, {
            heldHere,
            dValue: id,
          });
        }
      } else if (relation !== 'superset') {
        emit(
          SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT,
          key,
          `${id} is only in ${b.name}; ${d.name} removed it`,
          { heldHere, bValue: id },
        );
      }
    }
    const beneathOneSided = (key: string): boolean => {
      const rel = SpecSetCheck.stripKind(key);
      return oneSided.some((o) => rel === o || rel.startsWith(`${o}/`));
    };

    // Values.
    const keys = _sorted(new Set([...b.values.keys(), ...d.values.keys()]));
    for (const k of keys) {
      if (beneathOneSided(k)) {
        continue;
      }
      const vb = b.values.get(k);
      const vd = d.values.get(k);
      const spec = (vb !== undefined ? vb.spec : null) ?? (vd !== undefined ? vd.spec : null);
      const field = (vb !== undefined ? vb.field : null) ?? (vd !== undefined ? vd.field : null);
      const bValue = vb !== undefined ? vb.value : '';
      const dValue = vd !== undefined ? vd.value : '';
      const heldHere = isHeld(
        vb !== undefined ? vb.path : this.pathOn(b, SpecSetCheck.stripKind(k)),
        field,
      );
      if (spec !== null && spec.multiple && spec.refersTo.length > 0) {
        const relation = fieldRelByShape.get(shape(k.substring(2))) ?? 'equal';
        const ib = new Set(SpecSetCheck.ids(bValue));
        const idd = new Set(SpecSetCheck.ids(dValue));
        for (const x of _sorted(Array.from(idd).filter((x) => !ib.has(x)))) {
          const may = relation === 'subset';
          emit(
            may ? SpecSyncCode.SHARED_ELEMENT_MAY_BE_ADDED : SpecSyncCode.SHARED_ELEMENT_MISSING,
            k,
            `${x} is named in ${d.name} and not in ${b.name}`,
            {
              field,
              heldHere,
              dValue: x,
              bValue: bValue === '' ? null : bValue,
              resolution: may ? SpecSyncResolution.INFO : null,
            },
          );
        }
        if (relation !== 'superset') {
          for (const x of _sorted(Array.from(ib).filter((x) => !idd.has(x)))) {
            emit(SpecSyncCode.SHARED_ELEMENT_ONLY_IN_BLUEPRINT, k, `${x} is named only in ${b.name}`, {
              field,
              heldHere,
              bValue: x,
              dValue: dValue === '' ? null : dValue,
            });
          }
        }
        continue;
      }
      if (bValue === '' && dValue === '') {
        continue;
      }
      if (SpecSetCheck.sameTyped(bValue, dValue, spec)) {
        continue;
      }
      const what = field === null ? 'the value' : `form field "${field}"`;
      if (bValue === '') {
        emit(
          SpecSyncCode.SHARED_VALUE_MISSING,
          k,
          `${what} is filled in ${d.name} and empty in ${b.name}`,
          { field, heldHere },
        );
      } else if (dValue === '') {
        emit(
          SpecSyncCode.SHARED_VALUE_ONLY_IN_BLUEPRINT,
          k,
          `${what} is filled only in ${b.name}; ${d.name} emptied it`,
          { field, heldHere },
        );
      } else {
        emit(
          SpecSyncCode.SHARED_VALUE_DIFFERS,
          k,
          `${what} differs: "${bValue}" in ${b.name}, "${dValue}" in ${d.name}` +
            `${heldHere ? ` (held in ${b.name})` : ''}`,
          { field, heldHere },
        );
      }
    }
  }

  /** A value key (`c:` / `f:` / `h:` / `i:`) without its kind and field. */
  static stripKind(key: string): string {
    const k = key.length > 2 && key[1] === ':' ? key.substring(2) : key;
    const hash = k.indexOf('#');
    return hash < 0 ? k : k.substring(0, hash);
  }

  /** The values a row's own forms (`<row>/<member>`) hold in `field`. */
  ownValues(doc: SpecDocument, row: string, field: string): string[] {
    let index = this._forms.get(doc);
    if (index === undefined) {
      index = new Map<string, string[]>();
      for (const p of doc.formPaths) {
        const slash = p.lastIndexOf('/');
        if (slash > 0) {
          const owner = p.substring(0, slash);
          let list = index.get(owner);
          if (list === undefined) {
            list = [];
            index.set(owner, list);
          }
          list.push(p);
        }
      }
      this._forms.set(doc, index);
    }
    const out: string[] = [];
    for (const p of index.get(row) || []) {
      const v = doc.formField(p, field);
      if (v !== null) {
        out.push(SpecSetCheck.reviewed(v));
      }
    }
    return out;
  }

  // --- unmarkable derived changes -------------------------------------------

  /**
   * Every change `deriveFields` would write in a document under review that
   * cannot be marked exactly: left for the agent.
   */
  unmarkableScan(order: number): void {
    const set = this.set;
    for (const name of set.names) {
      const doc = set.get(name)!;
      const root = this.rootSeg(set.rootOf(name)!);
      const derived = deriveFields(set.model, doc, { dryRun: true });
      for (const u of derived.unresolved) {
        if (u.code !== SpecValidationCode.UNMARKABLE) {
          continue;
        }
        const p = new SpecSyncPlace({ document: name, root, path: u.path });
        this.add(
          order,
          `${name} ${u.path}`,
          new SpecSyncFinding({
            code: SpecSyncCode.UNMARKABLE,
            pair: '',
            blueprint: p,
            detail: p,
            holder: SpecSyncHolder.DETAIL,
            resolution: SpecSyncResolution.AGENT,
            message: `${u.message} (in ${name})`,
          }),
        );
      }
    }
  }

  // --- pending marks --------------------------------------------------------

  /** Every value of every document that holds pending change marks. */
  pendingScan(order: number): void {
    const set = this.set;
    for (const name of set.names) {
      const doc = set.get(name)!;
      const root = this.rootSeg(set.rootOf(name)!);
      const flag = (path: string, field: string | null, raw: string): void => {
        if (!SpecSetCheck.isPending(raw)) {
          return;
        }
        const p = new SpecSyncPlace({
          document: name,
          root,
          path,
          field,
          value: SpecSetCheck.reviewed(raw),
          pendingMarks: true,
        });
        this.add(
          order,
          `${name} ${path} ${field ?? ''}`,
          new SpecSyncFinding({
            code: SpecSyncCode.PENDING_REVIEW,
            pair: '',
            blueprint: p,
            detail: p,
            holder: SpecSyncHolder.DETAIL,
            resolution: SpecSyncResolution.INFO,
            message:
              `${field === null ? 'the value' : `form field "${field}"`} at ` +
              `${path} in ${name} holds pending change marks`,
          }),
        );
      };
      for (const p of doc.contentPaths) {
        flag(p, null, doc.content(p) ?? '');
      }
      for (const p of doc.formPaths) {
        for (const f of doc.formFieldNames(p)) {
          flag(p, f, doc.formField(p, f) ?? '');
        }
      }
      for (const p of doc.headlinePaths) {
        flag(p, null, doc.headline(p) ?? '');
      }
    }
  }

  // --- links across two documents --------------------------------------------

  /** Every class instance of a document of root `type`: path and class. */
  private _instances(doc: SpecDocument, type: string): { path: string; cls: SpecClass }[] {
    const refl = this.refl;
    const out: { path: string; cls: SpecClass }[] = [];
    const walk = (cls: SpecClass, path: string, onPath: Set<string>): void => {
      out.push({ path, cls });
      for (const f of cls.fields) {
        if (f.hasAnnotation('Reference')) {
          continue;
        }
        const member = `${path}/${refl.fieldSegment(f)}`;
        if (f.kind === SpecFieldKind.LIST && f.elementIsComplex) {
          const el = refl.classNamed(f.elementType);
          if (el === null) {
            continue;
          }
          for (const item of doc.listItems(member)) {
            walk(el, item, new Set<string>());
          }
        } else if (f.kind === SpecFieldKind.COMPLEX || f.kind === SpecFieldKind.SECTION) {
          const child = refl.classNamed(f.type !== null ? f.type.split('?').join('') : null);
          if (child === null || onPath.has(child.name)) {
            continue;
          }
          const next = new Set(onPath);
          next.add(cls.name);
          walk(child, member, next);
        }
      }
    };
    const cls = refl.classNamed(type);
    if (cls !== null) {
      walk(cls, this.rootSeg(type), new Set<string>());
    }
    return out;
  }

  /**
   * The document a registry class is read in: the one whose root details it
   * (a populated root other than the Blueprint's that reaches it), else the
   * Blueprint.
   */
  registryDocument(sectionId: string): string | null {
    if (!this._registryDocs.has(sectionId)) {
      this._registryDocs.set(sectionId, this._computeRegistryDocument(sectionId));
    }
    return this._registryDocs.get(sectionId)!;
  }

  private _computeRegistryDocument(sectionId: string): string | null {
    const classes = new Set<string>();
    for (const c of this.refl.model.classes.values()) {
      if (c.sectionId === sectionId) {
        classes.add(c.name);
      }
    }
    let blueprint: string | null = null;
    for (const name of this.set.names) {
      const root = this.set.rootOf(name)!;
      let reach = this._reach.get(root);
      if (reach === undefined) {
        reach = this.refl.reachableClassNames(root);
        this._reach.set(root, reach);
      }
      let hit = false;
      for (const r of reach) {
        if (classes.has(r)) {
          hit = true;
          break;
        }
      }
      if (!hit) {
        continue;
      }
      if (root === this.set.blueprintRoot) {
        blueprint = name;
      } else {
        return name;
      }
    }
    return blueprint;
  }

  private _identity(doc: SpecDocument, item: string, target: string): string | null {
    const field = target.substring(target.indexOf('.') + 1);
    if (field === K_SECTION_ID_SLOT) {
      return this.itemId(doc, item);
    }
    const values = this.ownValues(doc, item, field);
    return values.length === 0 ? null : values[0];
  }

  /** The entry of `doc` that `refersTo` names `id` by, or null. */
  private _entry(doc: SpecDocument, refersTo: string[], id: string): string | null {
    let byTarget = this._entries.get(doc);
    if (byTarget === undefined) {
      byTarget = new Map<string, Map<string, string>>();
      this._entries.set(doc, byTarget);
    }
    for (const t of refersTo) {
      let index = byTarget.get(t);
      if (index === undefined) {
        index = new Map<string, string>();
        const sid = t.split('.')[0];
        for (const list of _sorted(doc.listPaths)) {
          for (const item of doc.listItems(list)) {
            const r = this.refl.resolve(item);
            if (r === null || r.targetClass === null || r.targetClass.sectionId !== sid) {
              continue;
            }
            const name = this._identity(doc, item, t);
            if (name !== null && !index.has(name)) {
              index.set(name, item);
            }
          }
        }
        byTarget.set(t, index);
      }
      const hit = index.get(id);
      if (hit !== undefined) {
        return hit;
      }
    }
    return null;
  }

  private _nearestItem(path: string): string | null {
    let p = path;
    for (;;) {
      if (this.isItem(p)) {
        return p;
      }
      const slash = p.lastIndexOf('/');
      if (slash < 0) {
        return null;
      }
      p = p.substring(0, slash);
    }
  }

  crossChecks(pairs: Set<string> | null, order: number): void {
    for (const name of this.set.names) {
      const doc = this.set.get(name)!;
      const root = this.set.rootOf(name)!;
      for (const i of this._instances(doc, root)) {
        const pairId = i.cls.sectionId ?? i.cls.name;
        if (pairs !== null && !pairs.has(pairId)) {
          continue;
        }
        for (const f of i.cls.fields) {
          const member = `${i.path}/${this.refl.fieldSegment(f)}`;
          const s = f.summaryOf;
          if (s !== null && s.document !== null && f.kind === SpecFieldKind.LIST) {
            this._crossSummaryRows(order, pairId, name, doc, member, s);
          }
          for (const ff of f.formFields) {
            if (ff.summaryOf !== null && ff.summaryOf.document !== null) {
              this._crossSummaryField(order, pairId, name, doc, member, ff);
            }
            if (ff.inverseOf !== null && !ff.inverseOf.symmetric) {
              this._crossInverse(order, pairId, name, doc, member, ff);
            }
          }
        }
      }
    }
  }

  /** The detail elements of a cross summary: (document name, document, item → id). */
  private _crossDetail(
    s: SpecSummaryOf,
  ): { name: string; doc: SpecDocument; elements: Map<string, string> } | null {
    const name = this.set.nameOf(s.document!);
    if (name === null) {
      return null; // not started
    }
    const doc = this.set.get(name)!;
    const seg = this.rootSeg(this.set.rootOf(name)!);
    let r: SpecPlaceResolution | null = null;
    try {
      const slash = s.detail.indexOf('/');
      if (slash < 0) {
        r = SpecPlace.parse(s.detail).resolve(this.refl, seg);
      } else {
        const head = SpecPlace.parse(s.detail.substring(0, slash)).resolve(this.refl, seg);
        const scope = head.kind === SpecPlaceKind.LIST ? `${head.path}-*` : head.path;
        const concrete = this.expand(doc, scope);
        if (concrete.length > 0) {
          r = SpecPlace.parse(s.detail.substring(slash + 1)).resolve(this.refl, concrete[0]);
        }
      }
    } catch (e) {
      if (e instanceof SpecPlaceException) {
        return null;
      }
      throw e;
    }
    if (r === null || r.kind !== SpecPlaceKind.LIST) {
      return null;
    }
    const elements = new Map<string, string>();
    for (const list of this.expand(doc, r.path)) {
      for (const item of doc.listItems(list)) {
        elements.set(item, this.itemId(doc, item));
      }
    }
    return { name, doc, elements };
  }

  private _place(
    name: string | null,
    path: string,
    o: { field?: string | null; value?: string | null } = {},
  ): SpecSyncPlace {
    return new SpecSyncPlace({
      document: name,
      root: name === null ? '' : this.rootSeg(this.set.rootOf(name)!),
      path,
      field: o.field ?? null,
      value: o.value ?? null,
    });
  }

  private _cross(
    order: number,
    code: SpecSyncCodeValue,
    pair: string,
    here: SpecSyncPlace,
    there: SpecSyncPlace,
    message: string,
  ): void {
    this.add(
      order,
      `${here.document} ${here.path} ${here.field ?? ''} ${there.value ?? ''}`,
      new SpecSyncFinding({
        code,
        pair,
        blueprint: here,
        detail: there,
        holder: SpecSyncHolder.DETAIL,
        resolution: SpecSyncResolution.AGENT,
        message,
      }),
    );
  }

  private _crossSummaryRows(
    order: number,
    pair: string,
    name: string,
    doc: SpecDocument,
    list: string,
    s: SpecSummaryOf,
  ): void {
    const detail = this._crossDetail(s);
    if (detail === null) {
      return;
    }
    const { name: dName, doc: dDoc, elements } = detail;
    const byId = new Map<string, string>();
    for (const [item, id] of elements) {
      byId.set(id, item);
    }
    const named = new Map<string, string>();
    for (const row of doc.listItems(list)) {
      const ids = s.match === null ? [this.itemId(doc, row)] : this._matchIds(doc, s.match, row);
      for (const id of ids) {
        const target = byId.get(id);
        if (target === undefined) {
          this._cross(
            order,
            SpecSyncCode.CROSS_SUMMARY_MISMATCH,
            pair,
            this._place(name, row, { value: id }),
            this._place(dName, list === '' ? '' : this._listOf(elements), { value: id }),
            `the summary row names ${id}, which is no element of ${s.detail} in ${dName}`,
          );
          continue;
        }
        if (named.has(id)) {
          this._cross(
            order,
            SpecSyncCode.CROSS_SUMMARY_MISMATCH,
            pair,
            this._place(name, row, { value: id }),
            this._place(dName, target, { value: id }),
            `the summary row names ${id}, which ${named.get(id)} names already`,
          );
          continue;
        }
        named.set(id, row);
        for (const [mineKey, theirsKey] of Object.entries(s.repeats)) {
          const mine = this._valueAt(doc, mineKey, row);
          const theirs = this._valueAt(dDoc, theirsKey, target);
          if (mine === null || theirs === null || mine.value === '') {
            continue;
          }
          if (mine.value !== theirs.value) {
            this._cross(
              order,
              SpecSyncCode.CROSS_SUMMARY_MISMATCH,
              pair,
              this._place(name, mine.path, { field: mine.field, value: mine.value }),
              this._place(dName, theirs.path, { field: theirs.field, value: theirs.value }),
              `${mineKey} repeats ${theirsKey} of ${id} as "${mine.value}", but ${dName} ` +
                `holds "${theirs.value}"`,
            );
          }
        }
      }
    }
    if (s.relation === 'equal') {
      for (const [item, id] of elements) {
        if (named.has(id)) {
          continue;
        }
        this._cross(
          order,
          SpecSyncCode.CROSS_SUMMARY_MISMATCH,
          pair,
          this._place(name, list),
          this._place(dName, item, { value: id }),
          `the detail element ${id} of ${dName} is named by no row of ${list} (relation: equal)`,
        );
      }
    }
  }

  private _listOf(elements: Map<string, string>): string {
    if (elements.size === 0) {
      return '';
    }
    const first = elements.keys().next().value as string;
    return first.substring(0, first.lastIndexOf('-'));
  }

  private _matchIds(doc: SpecDocument, place: string, row: string): string[] {
    const v = this._valueAt(doc, place, row);
    return v === null ? [] : SpecSetCheck.ids(v.value);
  }

  /** The value of `place` under the concrete `anchor`: path, value, field. */
  private _valueAt(
    doc: SpecDocument,
    place: string,
    anchor: string,
  ): { path: string; value: string; field: string | null } | null {
    let r: SpecPlaceResolution;
    try {
      r = SpecPlace.parse(place).resolve(this.refl, anchor);
    } catch (e) {
      if (e instanceof SpecPlaceException) {
        return null;
      }
      throw e;
    }
    const paths = this.expand(doc, r.path);
    if (paths.length !== 1) {
      return null;
    }
    const p = paths[0];
    let raw: string | null;
    switch (r.kind) {
      case SpecPlaceKind.FORM_FIELD:
        raw = doc.formField(p, r.field!);
        break;
      case SpecPlaceKind.CONTENT:
        raw = doc.content(p);
        break;
      case SpecPlaceKind.HEADLINE:
        raw = doc.headline(p);
        break;
      case SpecPlaceKind.SECTION_ID:
        raw = this.isItem(p) ? this.itemId(doc, p) : null;
        break;
      default:
        raw = null;
    }
    return { path: p, value: SpecSetCheck.reviewed(raw ?? ''), field: r.field };
  }

  private _crossSummaryField(
    order: number,
    pair: string,
    name: string,
    doc: SpecDocument,
    form: string,
    ff: FormFieldSpec,
  ): void {
    const raw = doc.formField(form, ff.name);
    if (raw === null) {
      return;
    }
    const s = ff.summaryOf!;
    const detail = this._crossDetail(s);
    if (detail === null) {
      return;
    }
    const { name: dName, elements } = detail;
    const known = new Set(elements.values());
    const seen = new Set<string>();
    for (const id of SpecSetCheck.ids(SpecSetCheck.reviewed(raw))) {
      const fresh = !seen.has(id);
      seen.add(id);
      if (!known.has(id) || !fresh) {
        this._cross(
          order,
          SpecSyncCode.CROSS_SUMMARY_MISMATCH,
          pair,
          this._place(name, form, { field: ff.name, value: id }),
          this._place(dName, this._listOf(elements), { value: id }),
          known.has(id)
            ? `form field "${ff.name}" names ${id} twice`
            : `form field "${ff.name}" names ${id}, which is no element of ` +
                `${s.detail} in ${dName}`,
        );
      }
    }
    if (s.relation === 'equal') {
      for (const [item, id] of elements) {
        if (seen.has(id)) {
          continue;
        }
        this._cross(
          order,
          SpecSyncCode.CROSS_SUMMARY_MISMATCH,
          pair,
          this._place(name, form, { field: ff.name }),
          this._place(dName, item, { value: id }),
          `the detail element ${id} of ${dName} is not named in "${ff.name}" (relation: equal)`,
        );
      }
    }
  }

  private _crossInverse(
    order: number,
    pair: string,
    name: string,
    doc: SpecDocument,
    form: string,
    ff: FormFieldSpec,
  ): void {
    const raw = doc.formField(form, ff.name);
    if (raw === null) {
      return;
    }
    const value = SpecSetCheck.reviewed(raw);
    if (value === '') {
      return;
    }
    const inv = ff.inverseOf!;
    for (const b of SpecSetCheck.ids(value)) {
      // The document the named entry is read in.
      const registries = new Set(ff.refersTo.map((t) => t.split('.')[0]));
      for (const registry of registries) {
        const other = this.registryDocument(registry);
        if (other === null || other === name) {
          continue;
        }
        const oDoc = this.set.get(other)!;
        const targets = ff.refersTo.filter((t) => t.split('.')[0] === registry);
        const bPath = this._entry(oDoc, targets, b);
        if (bPath === null) {
          continue;
        }
        for (const end of inv.fields) {
          let r: SpecPlaceResolution;
          try {
            r = SpecPlace.parse(end).resolve(this.refl, bPath);
          } catch (e) {
            if (e instanceof SpecPlaceException) {
              continue;
            }
            throw e;
          }
          if (r.formField === null) {
            continue;
          }
          // This field's entry, named as the other end names it, and read in
          // its own registry document only.
          const aClasses = new Set(r.formField.refersTo.map((t) => t.split('.')[0]));
          const sidOf = (p: string): string | null => {
            const res = this.refl.resolve(p);
            return res !== null && res.targetClass !== null ? res.targetClass.sectionId : null;
          };
          let a = this._nearestItem(form);
          while (a !== null && !aClasses.has(sidOf(a) as string)) {
            const slash = a.lastIndexOf('/');
            a = slash < 0 ? null : this._nearestItem(a.substring(0, slash));
          }
          if (a === null) {
            continue;
          }
          const aSid = sidOf(a)!;
          if (this.registryDocument(aSid) !== name) {
            continue;
          }
          const item = a;
          let aId: string | null = null;
          for (const t of r.formField.refersTo) {
            const v = this._identity(doc, item, t);
            if (v !== null) {
              aId = v;
              break;
            }
          }
          if (aId === null) {
            continue;
          }
          const ends = this.expand(oDoc, r.path);
          const field = r.field!;
          const back = aId;
          const namesBack = ends.some((p) =>
            SpecSetCheck.ids(SpecSetCheck.reviewed(oDoc.formField(p, field) ?? '')).includes(back),
          );
          if (!namesBack) {
            this._cross(
              order,
              SpecSyncCode.CROSS_INVERSE_MISSING,
              pair,
              this._place(name, form, { field: ff.name, value: b }),
              this._place(other, ends.length === 0 ? bPath : ends[0], { field: r.field, value: aId }),
              `form field "${ff.name}" in ${name} names ${b}, but ${b} in ${other} ` +
                `does not name ${aId} back (${inv.fields.join(', ')})`,
            );
          }
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// The global rename
// ---------------------------------------------------------------------------

/** Why {@link renameId} refuses. */
export class SpecRenameError extends Error {
  /** The documents already holding the new id. */
  readonly documents: string[];

  constructor(documents: string[], message: string) {
    super(message);
    this.name = 'SpecRenameError';
    this.documents = documents;
  }

  toString(): string {
    return `SpecRenameError: ${this.message}`;
  }
}

/** One value {@link renameId} changed. */
export class SpecRenameChange {
  /** The document's name. */
  readonly document: string;
  /** The path: a list item (its section id) or the value's path. */
  readonly path: string;
  /** The form field, or null. */
  readonly field: string | null;
  /** `sectionId`, `value` (a form field or content). */
  readonly kind: string;
  /** The value before. */
  readonly oldValue: string;
  /** The value after. */
  readonly newValue: string;

  constructor(props: {
    document: string;
    path: string;
    kind: string;
    oldValue: string;
    newValue: string;
    field?: string | null;
  }) {
    this.document = props.document;
    this.path = props.path;
    this.kind = props.kind;
    this.oldValue = props.oldValue;
    this.newValue = props.newValue;
    this.field = props.field != null ? props.field : null;
  }

  /** The canonical JSON form. */
  toJson(): Record<string, unknown> {
    return {
      document: this.document,
      path: this.path,
      ...(this.field !== null ? { field: this.field } : {}),
      kind: this.kind,
      old: this.oldValue,
      new: this.newValue,
    };
  }
}

function _allItems(doc: SpecDocument): string[] {
  const out: string[] = [];
  for (const list of _sorted(doc.listPaths)) {
    out.push(...doc.listItems(list));
  }
  return out;
}

/**
 * Renames the section id `from` to `to` in every document of `set` at once
 * (DP-part-cleanup-2): the list element carrying it, and every value naming
 * it as a whole token (references, comma-separated lists, the texts link
 * rows are extracted from). Refused, nothing changed, when an element of
 * any document already carries `to`. Returns the changes, in document and
 * path order.
 */
export function renameId(set: SpecDocumentSet, from: string, to: string): SpecRenameChange[] {
  const c = new SpecSetCheck(set);
  const holders = set.names.filter((name) => {
    const doc = set.get(name)!;
    return _allItems(doc).some((i) => c.itemId(doc, i) === to);
  });
  if (holders.length > 0) {
    throw new SpecRenameError(holders, `${to} is already an id in ${holders.join(', ')}`);
  }
  const token = new RegExp(`(?<![A-Za-z0-9-])${_escapeRegExp(from)}(?![A-Za-z0-9-])`, 'g');
  const test = new RegExp(token.source);
  const changes: SpecRenameChange[] = [];
  for (const name of set.names) {
    const doc = set.get(name)!;
    for (const item of _allItems(doc)) {
      if (c.itemId(doc, item) !== from) {
        continue;
      }
      doc.setItemSectionId(item, to);
      changes.push(
        new SpecRenameChange({ document: name, path: item, kind: 'sectionId', oldValue: from, newValue: to }),
      );
    }
    for (const p of _sorted(doc.contentPaths)) {
      const v = doc.content(p) ?? '';
      if (!test.test(v)) {
        continue;
      }
      const n = v.replace(token, () => to);
      doc.setContent(p, n);
      changes.push(new SpecRenameChange({ document: name, path: p, kind: 'value', oldValue: v, newValue: n }));
    }
    for (const p of _sorted(doc.formPaths)) {
      for (const f of _sorted(doc.formFieldNames(p))) {
        const v = doc.formField(p, f) ?? '';
        if (!test.test(v)) {
          continue;
        }
        const n = v.replace(token, () => to);
        doc.setFormField(p, f, n);
        changes.push(
          new SpecRenameChange({ document: name, path: p, field: f, kind: 'value', oldValue: v, newValue: n }),
        );
      }
    }
  }
  return changes;
}
