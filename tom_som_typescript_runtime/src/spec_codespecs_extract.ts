/**
 * The Phase-4 **specification extract generator** — the machine half of
 * CodeSpecs production (`codespecs_mapping.md` §1.1.1) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_codespecs_extract.dart`.
 *
 * Phase 4 runs in two passes. This surface is the first: for each CodeSpecs
 * area it collects everything in a filled specification document that
 * `@CodeSpecKind` routes to that area, **verbatim and with provenance**, so the
 * second pass — an authoring agent, one prompt per authoring step — writes
 * against a bounded extract rather than against a 652-section document.
 *
 * The boundary between the two passes is a rule, not a preference. This
 * generator may **copy and index**; it may not summarise, rephrase, compose a
 * sentence out of field values, or choose a name — the prohibitions of
 * `codespecs_derivation_contract.md` §2.8 **C1**, which bind the extract
 * generator word for word. The consequence is checkable rather than trusted:
 * every {@link CodeSpecsExtractEntry.value} is a string the document stores,
 * byte for byte, and the conformance corpus asserts it.
 *
 * Three things follow from that and shape the API:
 *
 *   * **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a
 *     class carries `@CodeSpecKind` (feeds code), sits under a `@FollowUpKind`
 *     root (feeds a non-generation process), or carries `@NoArtifact` (feeds
 *     nothing). The trio is exhaustive by construction, so a class carrying
 *     none of them is not "skipped": it is a {@link CodeSpecsExtractError}, the
 *     `ROUTE-TOTAL` invariant (`tom_specs_model_rules.md` §10.2) failing loudly
 *     at the one place that depends on it.
 *   * **`@CodeSpecKind` is list-valued** (§9.1), and extracts are **not**
 *     deduplicated across areas: a section feeding three areas appears, whole,
 *     in three extracts. Each area's prompt must be self-sufficient.
 *   * **Every entry carries its provenance** — section id, class, field, the
 *     routing marker that put it here and where that marker was declared — so
 *     the `@DocSpec`/`DocRef` back-links (§9.3) can be written from the extract
 *     alone.
 *
 * The area catalogue ({@link CodeSpecsAreaCatalog}) is an **input**, not a table
 * baked into the runtime: it is the machine-readable form of
 * `codespecs_mapping.md` §4.1 (the parts catalogue), §4.4.3 (the emission
 * slices) and §4.4.6 (the authoring steps), authored once and read by all nine
 * runtimes. Carrying it beside the content is what stops an agent having to
 * open the mapping document to find out what `CE-FM` means.
 */

import * as fs from 'fs';

import { SpecDocument } from './spec_document';
import {
  SpecClass,
  SpecField,
  SpecFieldKind,
  SpecModel,
  SpecRoot,
} from './spec_model';
import { specPathJoin } from './spec_paths';
import { SpecReflection } from './spec_reflection';
import * as yaml from './yaml';

/**
 * The version of the emitted extract artifact's on-disk shape. Bumped when the
 * YAML or Markdown layout changes in a way a reader could notice.
 *
 * 2: entries carry `headline` — the enclosing section instance's headline,
 * copy-only (stored headline, else the `@Headline` type default, else null).
 *
 * 3: entries carry `instanceId` — the nearest enclosing list-item instance's
 * **stored** section id (the `<!--[…]-->` id the document serializes),
 * copy-only; null when no enclosing instance stores one. The render-time
 * positional default (`CARD-2`) is derived, never stored, so it is never
 * carried — that would be the composition C1 forbids.
 */
export const K_CODE_SPECS_EXTRACT_FORMAT = 3;

/**
 * The annotation names of the three routing verdicts (`codespecs_mapping.md`
 * §8.3). All three ride the generic annotation bag in every SOM runtime (§8.4),
 * so they are read by name rather than through a meta slot.
 */
export const K_CODE_SPEC_KIND_ANNOTATION = 'CodeSpecKind';

/** See {@link K_CODE_SPEC_KIND_ANNOTATION}. */
export const K_FOLLOW_UP_KIND_ANNOTATION = 'FollowUpKind';

/** See {@link K_CODE_SPEC_KIND_ANNOTATION}. */
export const K_NO_ARTIFACT_ANNOTATION = 'NoArtifact';

/** Which of the three `codespecs_mapping.md` §8.3 verdicts a class carries. */
export const CodeSpecsRoutingVerdict = {
  /**
   * `@CodeSpecKind(List<CodeSpecPart>)` — the section's content is shown to
   * every named area's extract.
   */
  FEEDS_CODE: 'feedsCode',

  /**
   * `@FollowUpKind(List<FollowUpProcess>)` — the section is delivered by a
   * non-generation process. The whole subtree is excluded from every extract.
   */
  FEEDS_PROCESS: 'feedsProcess',

  /**
   * `@NoArtifact(NoArtifactReason)` — the section deliberately produces no
   * downstream artifact. Its own leaves contribute nothing; its children are
   * still routed individually (that is what `container` means).
   */
  FEEDS_NOTHING: 'feedsNothing',

  /**
   * A `@Document` root carrying no verdict. Structurally exempt from
   * `ROUTE-TOTAL`: a root is the document, not a section of it.
   */
  DOCUMENT_ROOT: 'documentRoot',

  /**
   * No verdict, and not a `@Document` root — a `ROUTE-TOTAL` violation, and the
   * reason {@link CodeSpecsExtractor.extractAll} throws.
   */
  UNROUTED: 'unrouted',
} as const;

export type CodeSpecsRoutingVerdictValue =
  (typeof CodeSpecsRoutingVerdict)[keyof typeof CodeSpecsRoutingVerdict];

/**
 * The verdict recorded for one class node of the walked document, with the
 * provenance of the marker that decided it.
 */
export class CodeSpecsRouting {
  /** The document path of the node the verdict was computed for. */
  path: string;

  /** The model class at {@link path}. */
  className: string;

  /** Which verdict the class carries. */
  verdict: CodeSpecsRoutingVerdictValue;

  /**
   * The verdict's payload, verbatim from the annotation: the `CodeSpecPart.*`
   * values for `feedsCode`, the `FollowUpProcess.*` values for `feedsProcess`,
   * the single `NoArtifactReason.*` for `feedsNothing`, and empty for the two
   * verdicts that have no marker.
   */
  values: string[];

  /** The marker's optional `note`, verbatim; `null` when it carries none. */
  note: string | null;

  /**
   * Where the marker was declared — the class name, or `Class.field` when a
   * field-level `@CodeSpecKind` overrode its class. Empty when there is no
   * marker.
   */
  declaredAt: string;

  constructor(props: {
    path: string;
    className: string;
    verdict: CodeSpecsRoutingVerdictValue;
    values?: string[];
    note?: string | null;
    declaredAt?: string;
  }) {
    this.path = props.path;
    this.className = props.className;
    this.verdict = props.verdict;
    this.values = props.values || [];
    this.note = props.note != null ? props.note : null;
    this.declaredAt = props.declaredAt != null ? props.declaredAt : '';
  }

  toString(): string {
    return `CodeSpecsRouting(${this.path}, ${this.className}, ${this.verdict})`;
  }
}

/**
 * One extract entry: a single value the specification document stores, with
 * everything needed to trace it back (`codespecs_mapping.md` §1.1.1, "Entry").
 */
export class CodeSpecsExtractEntry {
  /** The `CE-*` code of the area this entry was collected for. */
  areaCode: string;

  /**
   * The section id of the leaf the value sits on (`@SectionId`, else the model
   * field name).
   */
  sectionId: string;

  /**
   * The enclosing section instance's headline, copy-only like {@link value}:
   * the document's **stored** headline for the class node the leaf sits under
   * (YRD3), else the class's `@Headline` type default (YRD4), else `null`.
   * Gives naming rule N1 a real source — never a derivation.
   */
  headline: string | null;

  /**
   * The nearest enclosing list-item instance's **stored** section id — the
   * `<!--[…]-->` id the document serializes — or `null` when no enclosing
   * instance stores one. Copy-only auxiliary trace data: a `DocRef` back-link
   * still names the extract token, not this id (`codespecs_mapping.md` §9.3).
   */
  instanceId: string | null;

  /** The document path of the leaf — the source location. */
  path: string;

  /** The model class declaring the leaf. */
  className: string;

  /** The model field name of the leaf. */
  fieldName: string;

  /**
   * The form-field name when the value is one field of a `@Form` section;
   * `null` for a content, enum, scalar or scalar-list leaf.
   */
  formField: string | null;

  /** The `CodeSpecPart.*` value that routed this entry here, verbatim. */
  routedBy: string;

  /**
   * Where that `@CodeSpecKind` was declared — the class name, or `Class.field`
   * for a field-level override.
   */
  routedAt: string;

  /** The `@CodeSpecKind` `note`, verbatim; `null` when it carries none. */
  routingNote: string | null;

  /** The stored value, **verbatim**. Never assembled, reformatted or trimmed. */
  value: string;

  constructor(props: {
    areaCode: string;
    sectionId: string;
    path: string;
    className: string;
    fieldName: string;
    routedBy: string;
    routedAt: string;
    value: string;
    headline?: string | null;
    instanceId?: string | null;
    formField?: string | null;
    routingNote?: string | null;
  }) {
    this.areaCode = props.areaCode;
    this.sectionId = props.sectionId;
    this.headline = props.headline != null ? props.headline : null;
    this.instanceId = props.instanceId != null ? props.instanceId : null;
    this.path = props.path;
    this.className = props.className;
    this.fieldName = props.fieldName;
    this.routedBy = props.routedBy;
    this.routedAt = props.routedAt;
    this.value = props.value;
    this.formField = props.formField != null ? props.formField : null;
    this.routingNote = props.routingNote != null ? props.routingNote : null;
  }

  toString(): string {
    return `CodeSpecsExtractEntry(${this.areaCode}, ${this.path})`;
  }
}

/** One emission slice of `codespecs_mapping.md` §4.4.3. */
export class CodeSpecsSlice {
  /** The slice's number, 1–7. */
  number: number;

  /** The slice's name as §4.4.3 gives it. */
  title: string;

  /** The §4.2 project the slice emits into. */
  project: string;

  /**
   * The slices this one may cite — §4.4.3's across-slice edges. Transitively
   * closed by {@link CodeSpecsAreaCatalog.citableAreaCodes}.
   */
  cites: number[];

  constructor(props: {
    number: number;
    title: string;
    project: string;
    cites?: number[];
  }) {
    this.number = props.number;
    this.title = props.title;
    this.project = props.project;
    this.cites = props.cites || [];
  }

  /**
   * Reads one slice. `number` is required and must be a JSON number; a row
   * without one throws an error naming the row by its `title` or `project`.
   */
  static fromJson(j: any): CodeSpecsSlice {
    const label = gateRowLabel(j, ['title', 'project']);
    return new CodeSpecsSlice({
      number: gateRequiredInt(j, 'number', label),
      title: j.title != null ? j.title : '',
      project: j.project != null ? j.project : '',
      cites: intList(j.cites),
    });
  }
}

/**
 * One row of the `codespecs_mapping.md` §4.4.6 authoring-step table — the unit
 * Phase 4 is authored in, one `csgen` todo each.
 *
 * The catalogue carries the table so a consumer planning Phase 4 step by step
 * reads it as data rather than parsing the mapping document's Markdown.
 */
export class CodeSpecsStep {
  /**
   * The step's number, 1–31. The table is written in authoring order, so the
   * number is also the step's position in that order.
   */
  number: number;

  /** The "Authoring step (emission unit)" cell, verbatim — Markdown included. */
  title: string;

  /** The §4.4.3 slice the step's code is emitted in. */
  slice: number;

  /**
   * The "Placed by" cell, verbatim: the catalogue position or edge that puts
   * the step where it is.
   */
  placedBy: string;

  /**
   * The `CE-*` codes of the areas the step authors, in catalogue order — the
   * inverse of {@link CodeSpecsArea.authoringSteps}.
   */
  areaCodes: string[];

  /**
   * `number` and `slice` are required: a step with no number cannot be placed,
   * and one with no slice does not say which project it lands in.
   */
  constructor(props: {
    number: number;
    slice: number;
    title?: string;
    placedBy?: string;
    areaCodes?: string[];
  }) {
    this.number = props.number;
    this.slice = props.slice;
    this.title = props.title != null ? props.title : '';
    this.placedBy = props.placedBy != null ? props.placedBy : '';
    this.areaCodes = props.areaCodes || [];
  }

  /**
   * Reads one step. `number` and `slice` are required JSON numbers — a row
   * missing either throws an error naming it by its `title` or `placedBy`.
   * The text cells and `areaCodes` fall back to empty.
   */
  static fromJson(j: any): CodeSpecsStep {
    const label = gateRowLabel(j, ['title', 'placedBy']);
    return new CodeSpecsStep({
      number: gateRequiredInt(j, 'number', label),
      slice: gateRequiredInt(j, 'slice', label),
      title: j.title != null ? j.title : '',
      placedBy: j.placedBy != null ? j.placedBy : '',
      areaCodes: stringList(j.areaCodes),
    });
  }
}

/**
 * A SOM field a gate table names: a class, one of its members, and the form
 * field when the value is one field of a `@Form` section.
 */
export class CodeSpecsFieldRef {
  /** The model class. */
  className: string;

  /** The member of {@link className}. */
  member: string;

  /** The form field of {@link member}, or `null` for a whole-member value. */
  formField: string | null;

  constructor(props: {
    className: string;
    member: string;
    formField?: string | null;
  }) {
    this.className = props.className;
    this.member = props.member;
    this.formField = props.formField != null ? props.formField : null;
  }

  /** Reads one reference; `className` and `member` are required. */
  static fromJson(j: any): CodeSpecsFieldRef {
    const label = gateRowLabel(j, ['className', 'member']);
    return new CodeSpecsFieldRef({
      className: gateRequiredString(j, 'className', label),
      member: gateRequiredString(j, 'member', label),
      formField: j.formField != null ? String(j.formField) : null,
    });
  }

  /** `Class.member` or `Class.member.formField` — how findings name it. */
  get source(): string {
    return this.formField === null
      ? `${this.className}.${this.member}`
      : `${this.className}.${this.member}.${this.formField}`;
  }
}

/**
 * One A4 obligation (`codespecs_prompt.md` §4.4): a required `Cs*` marker
 * argument and the stored SOM field it derives from.
 */
export class CodeSpecsRequiredArgument {
  /** The area whose extract makes the obligation apply. */
  area: string;

  /** The marker, `@CsTable`. */
  marker: string;

  /** The required argument, `table`. */
  argument: string;

  /** The SOM field the argument derives from. */
  field: CodeSpecsFieldRef;

  /**
   * When set, the value must also equal a value the run carries here — the
   * `domainEnum` → `DMENE` case of §4.4.
   */
  resolvesTo: CodeSpecsFieldRef | null;

  /**
   * When set, an instance is held to the row only if it carries this field
   * with the value {@link whenEquals} — the obligation sits on a `@Case`.
   */
  when: CodeSpecsFieldRef | null;

  /** The value {@link when} must hold. */
  whenEquals: string | null;

  constructor(props: {
    area: string;
    marker: string;
    argument: string;
    field: CodeSpecsFieldRef;
    resolvesTo?: CodeSpecsFieldRef | null;
    when?: CodeSpecsFieldRef | null;
    whenEquals?: string | null;
  }) {
    this.area = props.area;
    this.marker = props.marker;
    this.argument = props.argument;
    this.field = props.field;
    this.resolvesTo = props.resolvesTo != null ? props.resolvesTo : null;
    this.when = props.when != null ? props.when : null;
    this.whenEquals = props.whenEquals != null ? props.whenEquals : null;
  }

  /** Reads one row of the catalogue's `gate.requiredArguments`. */
  static fromJson(j: any): CodeSpecsRequiredArgument {
    const label = gateRowLabel(j, ['marker', 'argument', 'area']);
    const resolves = j.resolvesTo;
    const when = j.when;
    return new CodeSpecsRequiredArgument({
      area: gateRequiredString(j, 'area', label),
      marker: gateRequiredString(j, 'marker', label),
      argument: gateRequiredString(j, 'argument', label),
      field: CodeSpecsFieldRef.fromJson(j),
      resolvesTo: resolves == null ? null : CodeSpecsFieldRef.fromJson(resolves),
      when: when == null ? null : CodeSpecsFieldRef.fromJson(when),
      whenEquals: when == null ? null : gateRequiredString(when, 'equals', label),
    });
  }

  /** The source field's class. */
  get className(): string {
    return this.field.className;
  }

  /** The source field's member. */
  get member(): string {
    return this.field.member;
  }

  /** The source field's form field. */
  get formField(): string | null {
    return this.field.formField;
  }

  /** The source field, as findings name it. */
  get source(): string {
    return this.field.source;
  }
}

/**
 * One A5 carrier (`codespecs_prompt.md` §4.5): a structured field the model
 * must keep offering.
 */
export class CodeSpecsCarrier {
  /** The field. */
  field: CodeSpecsFieldRef;

  /** The document section that introduced it, for the finding. */
  introducedBy: string;

  constructor(props: { field: CodeSpecsFieldRef; introducedBy?: string }) {
    this.field = props.field;
    this.introducedBy = props.introducedBy != null ? props.introducedBy : '';
  }

  /** Reads one row of the catalogue's `gate.carriers`. */
  static fromJson(j: any): CodeSpecsCarrier {
    return new CodeSpecsCarrier({
      field: CodeSpecsFieldRef.fromJson(j),
      introducedBy: j.introducedBy != null ? String(j.introducedBy) : '',
    });
  }

  /** The carrier's class. */
  get className(): string {
    return this.field.className;
  }

  /** The carrier's member. */
  get member(): string {
    return this.field.member;
  }

  /** The carrier's form field. */
  get formField(): string | null {
    return this.field.formField;
  }

  /** The carrier, as findings name it. */
  get source(): string {
    return this.field.source;
  }
}

/**
 * One row of the `codespecs_mapping.md` §4.1 parts catalogue, plus the §4.4.3
 * slice and §4.4.6 authoring steps that place it. This is the **per-area
 * context** an extract carries beside its content.
 */
export class CodeSpecsArea {
  /**
   * The permanent registry key — `CE-FM`, `CE-API`. Never reused, never
   * renamed, and the extract file's name.
   */
  code: string;

  /** The §4.1 canonical id — the PascalCase noun (`Form`, `ServerApi`). */
  canonicalId: string;

  /**
   * The `CodeSpecPart` value, camelCase and **without** the enum prefix
   * (`form`, `serverApi`).
   */
  part: string;

  /** The `Cs*` annotation names of the §4.1 row. */
  annotations: string[];

  /** The §4.1 "Built on" cell, verbatim. */
  builtOn: string;

  /**
   * Where the area's spec-authorable attribute surface is stated — a §5.x
   * citation.
   */
  attributeSurface: string;

  /**
   * The §4.4.3 slice(s) the area's emission units sit in. More than one when
   * the area is split by locus.
   */
  slices: number[];

  /** The §4.4.6 authoring step(s) that write the area. */
  authoringSteps: number[];

  /**
   * Whether the part is active. A deferred part (§4.3) holds a reserved
   * `CodeSpecPart` value but has no generated surface, so it gets no extract.
   */
  active: boolean;

  constructor(props: {
    code: string;
    canonicalId: string;
    part: string;
    annotations?: string[];
    builtOn?: string;
    attributeSurface?: string;
    slices?: number[];
    authoringSteps?: number[];
    active?: boolean;
  }) {
    this.code = props.code;
    this.canonicalId = props.canonicalId;
    this.part = props.part;
    this.annotations = props.annotations || [];
    this.builtOn = props.builtOn != null ? props.builtOn : '';
    this.attributeSurface =
      props.attributeSurface != null ? props.attributeSurface : '';
    this.slices = props.slices || [];
    this.authoringSteps = props.authoringSteps || [];
    this.active = props.active != null ? props.active : true;
  }

  /**
   * Reads one area. `code` and `part` are required non-empty strings; a row
   * missing either throws an error naming it by `code`, `part` or
   * `canonicalId`.
   */
  static fromJson(j: any): CodeSpecsArea {
    const label = gateRowLabel(j, ['code', 'part', 'canonicalId']);
    return new CodeSpecsArea({
      code: gateRequiredString(j, 'code', label),
      canonicalId: j.canonicalId != null ? j.canonicalId : '',
      part: gateRequiredString(j, 'part', label),
      annotations: stringList(j.annotations),
      builtOn: j.builtOn != null ? j.builtOn : '',
      attributeSurface: j.attributeSurface != null ? j.attributeSurface : '',
      slices: intList(j.slices),
      authoringSteps: intList(j.authoringSteps),
      active: j.active != null ? Boolean(j.active) : true,
    });
  }

  /** The fully-qualified `@CodeSpecKind` value — `CodeSpecPart.form`. */
  get kindValue(): string {
    return `CodeSpecPart.${this.part}`;
  }

  toString(): string {
    return `CodeSpecsArea(${this.code})`;
  }
}

/**
 * The machine-readable form of `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6.
 *
 * Authored once, read by all nine runtimes. It is an input rather than a baked
 * table because the catalogue is the mapping document's content: a copy per
 * runtime would be nine things to keep current, and the one thing this quest
 * has learned three times is that a vocabulary duplicated nine ways can be
 * wrong in agreement.
 */
export class CodeSpecsAreaCatalog {
  /** Where the catalogue was transcribed from, for the extract header. */
  source: string;

  /** The §4.4.3 slices, in emission order. */
  slices: CodeSpecsSlice[];

  /**
   * The §4.1 areas, in catalogue order. Catalogue order is the tie-break §4.4.6
   * rule 2 uses, so it is load-bearing rather than cosmetic.
   */
  areas: CodeSpecsArea[];

  /**
   * The §4.4.6 authoring steps, in authoring order. Empty for a catalogue
   * written before the step table was transcribed.
   */
  steps: CodeSpecsStep[];

  /** The A4 obligations (`codespecs_prompt.md` §4.4). */
  requiredArguments: CodeSpecsRequiredArgument[];

  /** The A5 carriers (`codespecs_prompt.md` §4.5). */
  carriers: CodeSpecsCarrier[];

  /**
   * Whether the catalogue carries the gate tables at all. Without them A4 and
   * A5 are not run, rather than passing over nothing.
   */
  hasGateTables: boolean;

  constructor(props: {
    source?: string;
    slices?: CodeSpecsSlice[];
    areas?: CodeSpecsArea[];
    steps?: CodeSpecsStep[];
    requiredArguments?: CodeSpecsRequiredArgument[];
    carriers?: CodeSpecsCarrier[];
    hasGateTables?: boolean;
  }) {
    this.source = props.source != null ? props.source : '';
    this.slices = props.slices || [];
    this.areas = props.areas || [];
    this.steps = props.steps || [];
    this.requiredArguments = props.requiredArguments || [];
    this.carriers = props.carriers || [];
    this.hasGateTables = props.hasGateTables === true;
  }

  /**
   * Loads the authored catalogue. The optional `gate` key carries the A4/A5
   * tables (`requiredArguments`, `carriers`); its presence — not null — is
   * {@link hasGateTables}.
   */
  static fromJson(j: any): CodeSpecsAreaCatalog {
    const gate = j.gate != null ? j.gate : null;
    return new CodeSpecsAreaCatalog({
      source: j.source != null ? j.source : '',
      slices: (j.slices || []).map((e: any) => CodeSpecsSlice.fromJson(e)),
      areas: (j.areas || []).map((e: any) => CodeSpecsArea.fromJson(e)),
      steps: (j.steps || []).map((e: any) => CodeSpecsStep.fromJson(e)),
      requiredArguments: ((gate && gate.requiredArguments) || []).map((e: any) =>
        CodeSpecsRequiredArgument.fromJson(e),
      ),
      carriers: ((gate && gate.carriers) || []).map((e: any) =>
        CodeSpecsCarrier.fromJson(e),
      ),
      hasGateTables: gate !== null,
    });
  }

  /** The authoring step numbered `number`, or `null`. */
  stepNumbered(number: number): CodeSpecsStep | null {
    for (const s of this.steps) {
      if (s.number === number) {
        return s;
      }
    }
    return null;
  }

  /**
   * The steps that author `area`, in authoring order. Steps the catalogue does
   * not carry are skipped, so an older catalogue answers empty.
   */
  stepsFor(area: CodeSpecsArea): CodeSpecsStep[] {
    const out: CodeSpecsStep[] = [];
    for (const n of area.authoringSteps) {
      const step = this.stepNumbered(n);
      if (step !== null) {
        out.push(step);
      }
    }
    return out;
  }

  /** The active areas, in catalogue order — one extract each. */
  get activeAreas(): CodeSpecsArea[] {
    return this.areas.filter((a) => a.active);
  }

  /** The area with this `CE-*` code, or `null`. */
  byCode(code: string): CodeSpecsArea | null {
    for (const a of this.areas) {
      if (a.code === code) {
        return a;
      }
    }
    return null;
  }

  /**
   * The area a `@CodeSpecKind` value names, or `null`. Accepts both the bare
   * value (`form`) and the qualified one (`CodeSpecPart.form`), because the
   * meta carries the qualified spelling and callers reach for the bare one.
   */
  byPart(value: string): CodeSpecsArea | null {
    const bare = value.startsWith('CodeSpecPart.')
      ? value.slice('CodeSpecPart.'.length)
      : value;
    for (const a of this.areas) {
      if (a.part === bare) {
        return a;
      }
    }
    return null;
  }

  /** The slice numbered `number`, or `null`. */
  sliceNumbered(number: number): CodeSpecsSlice | null {
    for (const s of this.slices) {
      if (s.number === number) {
        return s;
      }
    }
    return null;
  }

  /**
   * The §4.2 projects `area`'s code lands in, in slice order.
   *
   * Derived from the area's slices rather than authored on the area: §4.4.3
   * already fixes one project per slice, so a per-area project column would be
   * a second place for the same fact to be stated — and the areas that would
   * need it are exactly the locus-split ones, where getting it wrong is
   * easiest.
   */
  projectsFor(area: CodeSpecsArea): string[] {
    const out: string[] = [];
    for (const n of area.slices) {
      const slice = this.sliceNumbered(n);
      const project = slice === null ? null : slice.project;
      if (project === null || project === '' || out.includes(project)) {
        continue;
      }
      out.push(project);
    }
    return out;
  }

  /**
   * The area codes `area` may cite — every other active area whose emission
   * units sit in a slice `area`'s slices reach, following §4.4.3's edges
   * transitively. Within-slice citation is legal, so an area's own slices are
   * part of the reachable set; the area itself is excluded.
   *
   * Derived rather than authored: a hand-kept per-area citation list is a
   * second source of truth for something the slice graph already decides.
   */
  citableAreaCodes(area: CodeSpecsArea): string[] {
    const reachable = new Set<number>();
    const stack: number[] = [...area.slices];
    while (stack.length > 0) {
      const n = stack.pop() as number;
      if (reachable.has(n)) {
        continue;
      }
      reachable.add(n);
      const slice = this.sliceNumbered(n);
      if (slice === null) {
        continue;
      }
      stack.push(...slice.cites);
    }
    const out: string[] = [];
    for (const a of this.areas) {
      if (!a.active || a.code === area.code) {
        continue;
      }
      for (const s of a.slices) {
        if (reachable.has(s)) {
          out.push(a.code);
          break;
        }
      }
    }
    return out;
  }
}

/**
 * One area's extract: the area's context plus every routed entry, in SOM
 * document order.
 */
export class CodeSpecsExtract {
  /** The area this extract is for. */
  area: CodeSpecsArea;

  /** The `codespecs_mapping.md` §4.1/§4.4.3 source the catalogue names. */
  catalogSource: string;

  /** The section segment of the document root the entries were collected from. */
  documentRoot: string;

  /** The area codes this area may cite (§4.4.3), for the agent's prompt. */
  citableParts: string[];

  /** The §4.2 projects the area's code lands in (§4.4.3, via the slices). */
  projects: string[];

  /** The routed entries, in SOM document order. */
  entries: CodeSpecsExtractEntry[];

  constructor(props: {
    area: CodeSpecsArea;
    documentRoot: string;
    catalogSource?: string;
    citableParts?: string[];
    projects?: string[];
    entries?: CodeSpecsExtractEntry[];
  }) {
    this.area = props.area;
    this.documentRoot = props.documentRoot;
    this.catalogSource = props.catalogSource != null ? props.catalogSource : '';
    this.citableParts = props.citableParts || [];
    this.projects = props.projects || [];
    this.entries = props.entries || [];
  }

  /**
   * Reads an extract back from its artifact of record — the inverse of
   * {@link toYaml}. `source` names the file in errors. Throws
   * {@link CodeSpecsRecordError} on an unknown `formatVersion` or a malformed
   * file.
   */
  static fromYaml(text: string, source = ''): CodeSpecsExtract {
    return parseCodeSpecsExtractYaml(text, source);
  }

  /** The extract's file name stem — `CE-FM.extract`. */
  get fileStem(): string {
    return `${this.area.code}.extract`;
  }

  /**
   * The artifact of record (`codespecs_mapping.md` §1.1.1). Scalars are emitted
   * as JSON strings, which are valid YAML 1.2 double-quoted scalars — so one
   * escaping rule, identical in all nine runtimes, covers every value a
   * specification can hold.
   */
  toYaml(): string {
    const b = new _Buffer();
    b.writeln(
      `# ${this.area.code}.extract.yaml — generated by ` +
        'spec_codespecs_extract. Do not edit.',
    );
    b.writeln('extract:');
    b.writeln(`  formatVersion: ${K_CODE_SPECS_EXTRACT_FORMAT}`);
    b.writeln(`  catalogSource: ${yamlString(this.catalogSource)}`);
    b.writeln('  area:');
    b.writeln(`    code: ${yamlString(this.area.code)}`);
    b.writeln(`    canonicalId: ${yamlString(this.area.canonicalId)}`);
    b.writeln(`    part: ${yamlString(this.area.kindValue)}`);
    b.writeln(`    annotations: ${yamlStringList(this.area.annotations)}`);
    b.writeln(`    builtOn: ${yamlString(this.area.builtOn)}`);
    b.writeln(
      `    attributeSurface: ${yamlString(this.area.attributeSurface)}`,
    );
    b.writeln(`    slices: ${yamlIntList(this.area.slices)}`);
    b.writeln(`    authoringSteps: ${yamlIntList(this.area.authoringSteps)}`);
    b.writeln(`    projects: ${yamlStringList(this.projects)}`);
    b.writeln(`    citableParts: ${yamlStringList(this.citableParts)}`);
    b.writeln('  document:');
    b.writeln(`    root: ${yamlString(this.documentRoot)}`);
    b.writeln(`    entryCount: ${this.entries.length}`);
    if (this.entries.length === 0) {
      b.writeln('  entries: []');
      return b.toString();
    }
    b.writeln('  entries:');
    for (const e of this.entries) {
      b.writeln(`    - sectionId: ${yamlString(e.sectionId)}`);
      b.writeln(`      headline: ${yamlNullableString(e.headline)}`);
      b.writeln(`      instanceId: ${yamlNullableString(e.instanceId)}`);
      b.writeln(`      path: ${yamlString(e.path)}`);
      b.writeln(`      className: ${yamlString(e.className)}`);
      b.writeln(`      fieldName: ${yamlString(e.fieldName)}`);
      b.writeln(`      formField: ${yamlNullableString(e.formField)}`);
      b.writeln(`      routedBy: ${yamlString(e.routedBy)}`);
      b.writeln(`      routedAt: ${yamlString(e.routedAt)}`);
      b.writeln(`      routingNote: ${yamlNullableString(e.routingNote)}`);
      b.writeln(`      value: ${yamlString(e.value)}`);
    }
    return b.toString();
  }

  /**
   * The rendered view. Regenerated from the YAML's own data — nothing reads the
   * Markdown as input — and exists because the agent reads it far better than
   * it reads YAML.
   */
  toMarkdown(): string {
    const b = new _Buffer();
    b.writeln(`# ${this.area.code} — ${this.area.canonicalId}`);
    b.writeln();
    b.writeln(
      'Generated by `spec_codespecs_extract` from the specification ' +
        `document rooted at \`${this.documentRoot}\`.`,
    );
    b.writeln(
      `\`${this.area.code}.extract.yaml\` beside this file is the artifact of ` +
        'record; this is a view of it.',
    );
    b.writeln();
    b.writeln('## Area');
    b.writeln();
    b.writeln('| | |');
    b.writeln('|---|---|');
    b.writeln(`| CE code | \`${this.area.code}\` |`);
    b.writeln(`| Canonical id | \`${this.area.canonicalId}\` |`);
    b.writeln(`| \`@CodeSpecKind\` value | \`${this.area.kindValue}\` |`);
    b.writeln(`| \`Cs*\` annotations | ${mdCodeList(this.area.annotations)} |`);
    b.writeln(`| Built on | ${mdCell(this.area.builtOn)} |`);
    b.writeln(`| Attribute surface | ${mdCell(this.area.attributeSurface)} |`);
    b.writeln(`| Slice(s) | ${mdIntList(this.area.slices)} |`);
    b.writeln(`| Authoring step(s) | ${mdIntList(this.area.authoringSteps)} |`);
    b.writeln(`| Project(s) | ${mdCodeList(this.projects)} |`);
    b.writeln(`| May cite | ${mdCodeList(this.citableParts)} |`);
    b.writeln(`| Catalogue source | ${mdCell(this.catalogSource)} |`);
    b.writeln();
    b.writeln(`## Entries (${this.entries.length})`);
    b.writeln();
    if (this.entries.length === 0) {
      b.writeln(
        '_No section of this document is routed to ' +
          `\`${this.area.kindValue}\`._`,
      );
      return b.toString();
    }
    let n = 0;
    for (const e of this.entries) {
      n++;
      const member =
        e.formField === null ? e.fieldName : `${e.fieldName}.${e.formField}`;
      b.writeln(`### ${n}. \`${e.sectionId}\` — \`${e.className}.${member}\``);
      b.writeln();
      if (e.headline !== null) {
        b.writeln(`- headline: ${mdCell(e.headline)}`);
      }
      if (e.instanceId !== null) {
        b.writeln(`- instanceId: \`${e.instanceId}\``);
      }
      b.writeln(`- path: \`${e.path}\``);
      b.writeln(`- routed by: \`${e.routedBy}\` declared on \`${e.routedAt}\``);
      if (e.routingNote !== null) {
        b.writeln(`- routing note: ${mdCell(e.routingNote)}`);
      }
      b.writeln();
      const fence = fenceFor(e.value);
      b.writeln(`${fence} text`);
      b.writeln(e.value);
      b.writeln(fence);
      b.writeln();
    }
    return b.toString();
  }
}

/**
 * Thrown when the document cannot be extracted from at all.
 *
 * Two causes: a section routed nowhere — `ROUTE-TOTAL`
 * (`tom_specs_model_rules.md` §10.2) failing — and a walk root that cannot be
 * resolved to exactly one (`codespecs_prompt.md` §5). Both are errors rather
 * than skips: a section routed nowhere is a section the agent writing that area
 * never sees, and a walk over the wrong root is every area empty. A silent
 * omission at this boundary is indistinguishable from a specification that
 * genuinely said nothing.
 *
 * Dart's counterpart `implements Exception` (a plain value); here it extends
 * `Error` so `throw` carries a stack and `instanceof` works — the same choice
 * `SpecCreationError` makes, including the `setPrototypeOf` call that repairs
 * the prototype chain when the package is compiled down to ES5.
 */
export class CodeSpecsExtractError extends Error {
  /** The document path of the offending node. */
  readonly path: string;

  /** The model class at {@link path}. */
  readonly className: string;

  constructor(message: string, path: string, className: string) {
    super(message);
    this.name = 'CodeSpecsExtractError';
    this.path = path;
    this.className = className;
    Object.setPrototypeOf(this, CodeSpecsExtractError.prototype);
  }

  toString(): string {
    return (
      `CodeSpecsExtractError: ${this.message} ` +
      `(${this.path}, ${this.className})`
    );
  }
}

/** The root segment of `root` — its `@SectionId` when it has one. */
function codeSpecsRootSegment(root: SpecRoot): string {
  return root.sectionId ?? root.type;
}

/** The one root a {@link CodeSpecsExtractor} walks — `codespecs_prompt.md` §5. */
function resolveCodeSpecsRoot(
  model: SpecModel,
  document: SpecDocument,
  rootType: string | null,
): SpecRoot {
  const populated = model.roots.filter((r) =>
    document.hasValuesUnder(codeSpecsRootSegment(r)),
  );
  const names = model.roots.map((r) => r.type).join(', ');
  if (rootType !== null && rootType !== '') {
    for (const r of model.roots) {
      if (r.type !== rootType && codeSpecsRootSegment(r) !== rootType) {
        continue;
      }
      if (populated.length > 0 && !populated.includes(r)) {
        throw new CodeSpecsExtractError(
          `root "${rootType}" holds no value in this document, but ` +
            `${populated.map((p) => p.type).join(', ')} does — every ` +
            'extract would come out empty (codespecs_prompt.md §5)',
          codeSpecsRootSegment(r),
          r.type,
        );
      }
      return r;
    }
    throw new CodeSpecsExtractError(
      `no document root with type or section id "${rootType}" ` +
        `(have: ${names})`,
      '',
      rootType,
    );
  }
  if (populated.length === 1) {
    return populated[0];
  }
  if (populated.length === 0) {
    if (model.roots.length === 1) {
      return model.roots[0];
    }
    throw new CodeSpecsExtractError(
      'document has no populated root to extract from; pass rootType to ' +
        `choose one (have: ${names})`,
      '',
      '',
    );
  }
  throw new CodeSpecsExtractError(
    `document has ${populated.length} populated roots ` +
      `(${populated.map((r) => r.type).join(', ')}); pass rootType to ` +
      'choose one',
    '',
    '',
  );
}

/**
 * Produces one {@link CodeSpecsExtract} per active area from a filled
 * specification document.
 *
 * A Phase-4 run extracts from **one** specification document, so the walk has
 * exactly one root ({@link CodeSpecsExtractor.root}, `codespecs_prompt.md` §5).
 * The two ways to get that wrong are both closed here rather than left to the
 * caller: the walk cannot union every `@Document` root, because there is no way
 * to ask for that; and naming a root the document never populates — the
 * `D13CodeSpecsProjection` mistake, whose `CGP/…` path space misses a
 * blueprint's `SBP/…` values and yields every area silently empty — throws
 * rather than returning an empty result.
 */
export class CodeSpecsExtractor {
  /**
   * The model describing the document's structure and carrying the routing
   * verdicts.
   */
  model: SpecModel;

  /** The filled specification document. */
  document: SpecDocument;

  /** The area catalogue — `codespecs_mapping.md` §4.1/§4.4.3/§4.4.6. */
  catalog: CodeSpecsAreaCatalog;

  /**
   * The one `@Document` root this extractor walks. Resolved once, in the
   * constructor, so {@link routings} and {@link extractAll} cannot disagree
   * about what was walked.
   */
  readonly root: SpecRoot;

  private _reflection: SpecReflection;

  /**
   * Binds an extractor to a model / document / catalogue triple.
   *
   * `rootType` names the specification document's own root, by type name or by
   * section id. Omitted (`null`), it defaults to the document's single
   * **populated** root — the root under which the document holds any value —
   * falling back to the model's only root when the document is empty, so an
   * unfilled single-root model still reaches the routing walk.
   *
   * Throws {@link CodeSpecsExtractError} when the root cannot be resolved to
   * exactly one: an unknown `rootType`, a `rootType` holding no value while
   * another root does, more than one populated root, or an empty document over
   * a multi-root model.
   */
  constructor(
    model: SpecModel,
    document: SpecDocument,
    catalog: CodeSpecsAreaCatalog,
    rootType: string | null = null,
  ) {
    this.model = model;
    this.document = document;
    this.catalog = catalog;
    this.root = resolveCodeSpecsRoot(model, document, rootType);
    this._reflection = new SpecReflection(model);
  }

  /**
   * The verdict of every class node the walk reaches, in document order.
   *
   * Computed by the same walk {@link extractAll} uses, so "what was routed
   * where" and "what landed in which extract" cannot disagree. Unlike
   * {@link extractAll} this does **not** throw on an unrouted class — it
   * reports it, which is what a diagnostic is for.
   */
  routings(): CodeSpecsRouting[] {
    const out: CodeSpecsRouting[] = [];
    this._walkAll(out, null, false);
    return out;
  }

  /**
   * One extract per active area, in catalogue order.
   *
   * Throws {@link CodeSpecsExtractError} on the first class the walk reaches
   * that carries none of the three verdicts.
   */
  extractAll(): CodeSpecsExtract[] {
    const entries: CodeSpecsExtractEntry[] = [];
    this._walkAll(null, entries, true);
    const root = this._reflection.rootSegment(this.root);
    const out: CodeSpecsExtract[] = [];
    for (const area of this.catalog.activeAreas) {
      out.push(
        new CodeSpecsExtract({
          area,
          catalogSource: this.catalog.source,
          documentRoot: root,
          citableParts: this.catalog.citableAreaCodes(area),
          projects: this.catalog.projectsFor(area),
          entries: entries.filter((e) => e.areaCode === area.code),
        }),
      );
    }
    return out;
  }

  /**
   * The single extract for `areaCode`, or `null` when the catalogue holds no
   * such active area.
   */
  extractFor(areaCode: string): CodeSpecsExtract | null {
    for (const e of this.extractAll()) {
      if (e.area.code === areaCode) {
        return e;
      }
    }
    return null;
  }

  // --- the walk ------------------------------------------------------------

  private _walkAll(
    routings: CodeSpecsRouting[] | null,
    entries: CodeSpecsExtractEntry[] | null,
    strict: boolean,
  ): void {
    this._walk(
      this._reflection.rootSegment(this.root),
      this.model.classNamed(this.root.type),
      new Set<string>([this.root.type]),
      routings,
      entries,
      strict,
      null,
    );
  }

  private _walk(
    path: string,
    cls: SpecClass | null,
    ancestorTypes: Set<string>,
    routings: CodeSpecsRouting[] | null,
    entries: CodeSpecsExtractEntry[] | null,
    strict: boolean,
    enclosingInstanceId: string | null,
  ): void {
    if (cls === null) {
      return;
    }
    const routing = this._verdictOf(cls, path);
    if (routings !== null) {
      routings.push(routing);
    }

    if (routing.verdict === CodeSpecsRoutingVerdict.FEEDS_PROCESS) {
      return; // the whole subtree is delivered by a non-generation process
    }
    if (routing.verdict === CodeSpecsRoutingVerdict.UNROUTED && strict) {
      throw new CodeSpecsExtractError(
        'section carries none of the three routing verdicts ' +
          '(@CodeSpecKind / @FollowUpKind / @NoArtifact) — ' +
          'tom_specs_model_rules.md §10.2 ROUTE-TOTAL',
        path,
        cls.name,
      );
    }

    const classRouting =
      routing.verdict === CodeSpecsRoutingVerdict.FEEDS_CODE ? routing : null;

    // The enclosing section instance's headline, resolved once per class node
    // (YRD3 stored > YRD4 type default > null) and copied onto every entry
    // emitted below it. Copy-only — never a name derivation.
    const stored = this.document.headline(path);
    const headline = stored !== null ? stored : cls.headline;

    // The nearest enclosing list-item instance's **stored** section id, copied
    // onto every entry emitted below it. Only a stored id is ever carried — the
    // render-time positional default is a derivation, and a derivation is what
    // C1 forbids — so an id-less instance yields `null`, never `CARD-2`.
    const storedId = this.document.itemSectionId(path);
    const instanceId = storedId !== null ? storedId : enclosingInstanceId;

    for (const field of cls.fields) {
      const fieldPath = specPathJoin(
        path,
        this._reflection.fieldSegment(field),
      );
      const fieldRouting = this._fieldRouting(cls, field) || classRouting;

      switch (field.kind) {
        case SpecFieldKind.CONTENT:
        case SpecFieldKind.ENUM:
        case SpecFieldKind.SCALAR:
          this._emitValue(
            entries,
            fieldRouting,
            cls,
            field,
            fieldPath,
            null,
            headline,
            instanceId,
            this.document.content(fieldPath),
          );
          break;
        case SpecFieldKind.FORM:
          for (const ff of field.formFields) {
            this._emitValue(
              entries,
              fieldRouting,
              cls,
              field,
              fieldPath,
              ff.name,
              headline,
              instanceId,
              this.document.formField(fieldPath, ff.name),
            );
          }
          break;
        case SpecFieldKind.LIST:
          for (const itemPath of this.document.listItems(fieldPath)) {
            if (
              field.elementIsComplex &&
              field.elementType !== null &&
              !ancestorTypes.has(field.elementType)
            ) {
              this._walk(
                itemPath,
                this.model.classNamed(field.elementType),
                new Set<string>([...ancestorTypes, field.elementType]),
                routings,
                entries,
                strict,
                instanceId,
              );
            } else {
              // A scalar item is itself an instance of the list: its own
              // stored id is the most precise enclosing-instance id its
              // entry can carry.
              const itemStored = this.document.itemSectionId(itemPath);
              this._emitValue(
                entries,
                fieldRouting,
                cls,
                field,
                itemPath,
                null,
                headline,
                itemStored !== null ? itemStored : instanceId,
                this.document.content(itemPath),
              );
            }
          }
          break;
        case SpecFieldKind.COMPLEX:
        case SpecFieldKind.SECTION:
          if (field.type !== null && !ancestorTypes.has(field.type)) {
            this._walk(
              fieldPath,
              this.model.classNamed(field.type),
              new Set<string>([...ancestorTypes, field.type]),
              routings,
              entries,
              strict,
              instanceId,
            );
          }
          break;
      }
    }
  }

  /**
   * Appends one entry **per area the routing names** — never deduplicated,
   * because each area's prompt must be self-sufficient (§1.1.1).
   */
  private _emitValue(
    entries: CodeSpecsExtractEntry[] | null,
    routing: CodeSpecsRouting | null,
    cls: SpecClass,
    field: SpecField,
    path: string,
    formField: string | null,
    headline: string | null,
    instanceId: string | null,
    value: string | null,
  ): void {
    if (entries === null || routing === null) {
      return;
    }
    if (value === null || value === '') {
      return;
    }
    for (const kind of routing.values) {
      const area = this.catalog.byPart(kind);
      if (area === null || !area.active) {
        continue;
      }
      entries.push(
        new CodeSpecsExtractEntry({
          areaCode: area.code,
          sectionId: this._reflection.fieldSegment(field),
          headline,
          instanceId,
          path,
          className: cls.name,
          fieldName: field.name,
          formField,
          routedBy: area.kindValue,
          routedAt: routing.declaredAt,
          routingNote: routing.note,
          value,
        }),
      );
    }
  }

  // --- verdict resolution --------------------------------------------------

  /**
   * The verdict `cls` carries. The three markers are mutually exclusive
   * (`KIND-EXCLUSIVE`), so the order they are tested in is a readability choice
   * rather than a precedence rule.
   *
   * Read through the model's own annotation accessors
   * ({@link SpecClass.codeSpecKind} and friends) rather than off the raw
   * annotation bag: they already know that `@CodeSpecKind`'s list argument is
   * `kinds` while `@FollowUpKind`'s is `processes`, and they strip the enum
   * prefix, so the codes here are bare whatever spelling the meta chose. Two
   * readers of the same annotations would be two chances to disagree.
   */
  private _verdictOf(cls: SpecClass, path: string): CodeSpecsRouting {
    const code = cls.codeSpecKind;
    if (code !== null) {
      return new CodeSpecsRouting({
        path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.FEEDS_CODE,
        values: code.kinds,
        note: code.note,
        declaredAt: cls.name,
      });
    }
    const followUp = cls.followUpKind;
    if (followUp !== null) {
      return new CodeSpecsRouting({
        path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.FEEDS_PROCESS,
        values: followUp.kinds,
        note: followUp.note,
        declaredAt: cls.name,
      });
    }
    const none = cls.noArtifact;
    if (none !== null) {
      return new CodeSpecsRouting({
        path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.FEEDS_NOTHING,
        values: [none.reason],
        note: none.note,
        declaredAt: cls.name,
      });
    }
    if (cls.hasAnnotation('Document')) {
      return new CodeSpecsRouting({
        path,
        className: cls.name,
        verdict: CodeSpecsRoutingVerdict.DOCUMENT_ROOT,
      });
    }
    return new CodeSpecsRouting({
      path,
      className: cls.name,
      verdict: CodeSpecsRoutingVerdict.UNROUTED,
    });
  }

  /**
   * A field-level `@CodeSpecKind`, which overrides its class's routing for that
   * field alone; `null` when the field carries none.
   */
  private _fieldRouting(
    cls: SpecClass,
    field: SpecField,
  ): CodeSpecsRouting | null {
    const code = field.codeSpecKind;
    if (code === null) {
      return null;
    }
    return new CodeSpecsRouting({
      path: '',
      className: cls.name,
      verdict: CodeSpecsRoutingVerdict.FEEDS_CODE,
      values: code.kinds,
      note: code.note,
      declaredAt: `${cls.name}.${field.name}`,
    });
  }
}

// --- reading back: extract files and the gate record ------------------------
//
// The extractor writes `<CE-CODE>.extract.yaml`; this is the other half, so a
// consumer that did not run the extractor — a validator, an editor tool, an
// agent asking which areas are in scope — reads the files with the same rules
// everywhere instead of re-deriving the shape (`codespecs_mapping.md` §1.1.1,
// `codespecs_prompt.md` §6.3). Port of
// `tom_som_dart_runtime/lib/src/spec_codespecs_records.dart`.
//
// Both readers **refuse** an unknown `formatVersion`: a later format that moved
// a key would otherwise read as an extract with no entries, or a scope with no
// verdicts, and a check with no input passes.

/**
 * The file name of the gate record, written beside the extracts. Fixed so a
 * partial pass cannot hide its record under a name no reader looks for.
 */
export const K_CODE_SPECS_GATE_RECORD_FILE = 'gate.verdicts.yaml';

/** The gate record `formatVersion` this runtime reads and writes. */
export const K_CODE_SPECS_GATE_RECORD_FORMAT = 1;

/** The suffix every extract artifact of record carries. */
export const K_CODE_SPECS_EXTRACT_FILE_SUFFIX = '.extract.yaml';

/**
 * The one resolution a gate record may carry: an insufficient area the user
 * decided to leave out.
 */
export const K_CODE_SPECS_GATE_DESCOPED = 'descoped';

const _AREA_CODE_PATTERN = /^CE-[A-Z]+$/;

/**
 * A malformed or unreadable extract file or gate record. {@link message} names
 * the file it was read from.
 */
export class CodeSpecsRecordError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CodeSpecsRecordError';
    Object.setPrototypeOf(this, CodeSpecsRecordError.prototype);
  }

  toString(): string {
    return `CodeSpecsRecordError: ${this.message}`;
  }
}

/**
 * Parses one `<CE-CODE>.extract.yaml`; `source` names the file in errors.
 *
 * Only `extract.formatVersion` and `extract.area.code` are required; any other
 * absent key reads as empty (a string as `''`, a list as `[]`, an optional
 * entry field as `null`), so a hand-written fixture stays readable. A key that
 * is present with the wrong type is an error, and so is a
 * `document.entryCount` that disagrees with the entries — a truncated file
 * would otherwise read as a complete one.
 *
 * The inverse of {@link CodeSpecsExtract.toYaml}: for any extract the extractor
 * wrote, `parseCodeSpecsExtractYaml(x.toYaml()).toYaml() === x.toYaml()`.
 */
export function parseCodeSpecsExtractYaml(
  text: string,
  source = '',
): CodeSpecsExtract {
  const name = source === '' ? 'the extract' : source;
  const root = _rootMapping(text, name, 'extract');
  const version = root.formatVersion;
  if (version !== K_CODE_SPECS_EXTRACT_FORMAT) {
    throw new CodeSpecsRecordError(
      `${name} declares extract format ${_show(version)}; this reader ` +
        `understands ${K_CODE_SPECS_EXTRACT_FORMAT} only — reading it would ` +
        'silently drop entries',
    );
  }
  const area = _absent(root.area) ? null : root.area;
  if (!_isMap(area)) {
    throw new CodeSpecsRecordError(`${name} has no \`area:\` mapping`);
  }
  const code = _str(area.code, name, 'area.code');
  if (code === '') {
    throw new CodeSpecsRecordError(`${name} names no area code`);
  }
  let part = _str(area.part, name, 'area.part');
  if (part.startsWith('CodeSpecPart.')) {
    part = part.slice('CodeSpecPart.'.length);
  }
  const documentNode = _absent(root.document) ? null : root.document;
  if (documentNode !== null && !_isMap(documentNode)) {
    throw new CodeSpecsRecordError(`${name}: \`document\` must be a mapping`);
  }
  const entriesNode = _absent(root.entries) ? null : root.entries;
  if (entriesNode !== null && !Array.isArray(entriesNode)) {
    throw new CodeSpecsRecordError(`${name}: \`entries\` must be a list`);
  }
  const entries: CodeSpecsExtractEntry[] = [];
  for (const raw of (entriesNode as unknown[] | null) || []) {
    if (!_isMap(raw)) {
      throw new CodeSpecsRecordError(
        `${name} has an entry that is not a mapping`,
      );
    }
    const req = (key: string) => _str(raw[key], name, `entries[].${key}`);
    const opt = (key: string) => _optStr(raw[key], name, `entries[].${key}`);
    entries.push(
      new CodeSpecsExtractEntry({
        areaCode: code,
        sectionId: req('sectionId'),
        headline: opt('headline'),
        instanceId: opt('instanceId'),
        path: req('path'),
        className: req('className'),
        fieldName: req('fieldName'),
        formField: opt('formField'),
        routedBy: req('routedBy'),
        routedAt: req('routedAt'),
        routingNote: opt('routingNote'),
        value: req('value'),
      }),
    );
  }
  const declared = documentNode === null ? null : documentNode.entryCount;
  if (declared != null && declared !== entries.length) {
    throw new CodeSpecsRecordError(
      `${name} declares entryCount ${_show(declared)} but carries ` +
        `${entries.length} entries — a truncated extract must not read as a ` +
        'complete one',
    );
  }
  return new CodeSpecsExtract({
    area: new CodeSpecsArea({
      code,
      canonicalId: _str(area.canonicalId, name, 'area.canonicalId'),
      part,
      annotations: _strList(area.annotations, name, 'area.annotations'),
      builtOn: _str(area.builtOn, name, 'area.builtOn'),
      attributeSurface: _str(
        area.attributeSurface,
        name,
        'area.attributeSurface',
      ),
      slices: _intList(area.slices, name, 'area.slices'),
      authoringSteps: _intList(
        area.authoringSteps,
        name,
        'area.authoringSteps',
      ),
    }),
    documentRoot: _str(
      documentNode === null ? null : documentNode.root,
      name,
      'document.root',
    ),
    catalogSource: _str(root.catalogSource, name, 'catalogSource'),
    projects: _strList(area.projects, name, 'area.projects'),
    citableParts: _strList(area.citableParts, name, 'area.citableParts'),
    entries,
  });
}

/**
 * One of `codespecs_prompt.md` §6.2's three per-area verdicts — an enum of
 * fixed instances, compared by identity, carrying the Dart enum `name` and
 * the §6.2 {@link word}.
 */
export class CodeSpecsGateVerdict {
  /** The extract carries every input the derivation contract requires. */
  static readonly sufficient = new CodeSpecsGateVerdict(
    'sufficient',
    'sufficient',
  );

  /**
   * The area does not apply — nothing was routed, with positive evidence of
   * absence (`codespecs_prompt.md` §6.4).
   */
  static readonly notApplicable = new CodeSpecsGateVerdict(
    'notApplicable',
    'not applicable',
  );

  /**
   * The extract is missing required inputs; only a recorded descope lets a run
   * continue without the area.
   */
  static readonly insufficient = new CodeSpecsGateVerdict(
    'insufficient',
    'insufficient',
  );

  /** Every verdict, in declaration order. */
  static readonly values: readonly CodeSpecsGateVerdict[] = [
    CodeSpecsGateVerdict.sufficient,
    CodeSpecsGateVerdict.notApplicable,
    CodeSpecsGateVerdict.insufficient,
  ];

  /** The enum constant's name (`notApplicable`). */
  readonly name: string;

  /** The verdict word exactly as `codespecs_prompt.md` §6.2 states it. */
  readonly word: string;

  private constructor(name: string, word: string) {
    this.name = name;
    this.word = word;
  }

  /** The verdict for `word`, or `null` for a word §6.2 does not know. */
  static parse(word: string): CodeSpecsGateVerdict | null {
    for (const v of CodeSpecsGateVerdict.values) {
      if (v.word === word) {
        return v;
      }
    }
    return null;
  }

  toString(): string {
    return `CodeSpecsGateVerdict.${this.name}`;
  }
}

/** One area's recorded verdict. */
export class CodeSpecsGateEntry {
  /** The area's `CE-*` code. */
  readonly area: string;

  /** The verdict. */
  readonly verdict: CodeSpecsGateVerdict;

  /** `descoped`, on an insufficient area only; otherwise `null`. */
  readonly resolution: string | null;

  /** A free-text note — why the verdict was taken. Never read as data. */
  readonly note: string | null;

  /**
   * Creates an entry. Shape is checked by {@link CodeSpecsGateRecord}, which is
   * the only thing that reads or writes entries.
   */
  constructor(props: {
    area: string;
    verdict: CodeSpecsGateVerdict;
    resolution?: string | null;
    note?: string | null;
  }) {
    this.area = props.area;
    this.verdict = props.verdict;
    this.resolution = props.resolution != null ? props.resolution : null;
    this.note = props.note != null ? props.note : null;
  }

  /** Whether this is an insufficient area resolved by descoping. */
  get descoped(): boolean {
    return this.resolution === K_CODE_SPECS_GATE_DESCOPED;
  }

  toString(): string {
    return `CodeSpecsGateEntry(${this.area}, ${this.verdict.word})`;
  }
}

/**
 * The Stage-B gate record, `gate.verdicts.yaml` (`codespecs_prompt.md` §6.3).
 *
 * Constructing one checks it: every area is a `CE-*` code named once, and a
 * `resolution:` appears only as `descoped` on an insufficient area. So a record
 * that exists is a record of the checked shape, whether it was read or built to
 * be written.
 */
export class CodeSpecsGateRecord {
  /** The verdicts, in the order they were recorded. */
  readonly verdicts: readonly CodeSpecsGateEntry[];

  /**
   * Creates and checks a record; throws {@link CodeSpecsRecordError} on a shape
   * `codespecs_prompt.md` §6.3 does not allow. `source` names it in errors.
   */
  constructor(
    verdicts: readonly CodeSpecsGateEntry[],
    source: string = K_CODE_SPECS_GATE_RECORD_FILE,
  ) {
    this.verdicts = Object.freeze([...verdicts]);
    this._check(source);
  }

  /** Parses `gate.verdicts.yaml`; `source` names the file in errors. */
  static fromYaml(
    text: string,
    source: string = K_CODE_SPECS_GATE_RECORD_FILE,
  ): CodeSpecsGateRecord {
    const root = _rootMapping(text, source, 'gate');
    for (const key of Object.keys(root)) {
      if (key !== 'formatVersion' && key !== 'verdicts') {
        throw new CodeSpecsRecordError(
          `${source} has an unknown key \`gate.${key}\` — the record knows ` +
            '`formatVersion` and `verdicts` only',
        );
      }
    }
    const version = root.formatVersion;
    if (version !== K_CODE_SPECS_GATE_RECORD_FORMAT) {
      throw new CodeSpecsRecordError(
        `${source} declares gate record format ${_show(version)}; this ` +
          `reader understands ${K_CODE_SPECS_GATE_RECORD_FORMAT} only — ` +
          'reading it would silently change the scope',
      );
    }
    const list = root.verdicts;
    if (!Array.isArray(list)) {
      throw new CodeSpecsRecordError(`${source} has no \`verdicts:\` list`);
    }
    const entries: CodeSpecsGateEntry[] = [];
    for (const raw of list) {
      if (!_isMap(raw)) {
        throw new CodeSpecsRecordError(
          `${source} has a verdict that is not a mapping`,
        );
      }
      for (const key of Object.keys(raw)) {
        if (!['area', 'verdict', 'resolution', 'note'].includes(key)) {
          throw new CodeSpecsRecordError(
            `${source} has an unknown key \`${key}\` in a verdict — an entry ` +
              'knows `area`, `verdict`, `resolution` and `note` only',
          );
        }
      }
      const area = _str(raw.area, source, 'verdicts[].area');
      const word = _str(raw.verdict, source, 'verdicts[].verdict');
      const verdict = CodeSpecsGateVerdict.parse(word);
      if (verdict === null) {
        throw new CodeSpecsRecordError(
          `${source} gives ${area} the verdict \`${word}\` — ` +
            'codespecs_prompt.md §6.2 knows `sufficient`, `not applicable` ' +
            'and `insufficient` only',
        );
      }
      entries.push(
        new CodeSpecsGateEntry({
          area,
          verdict,
          resolution: _optStr(raw.resolution, source, 'verdicts[].resolution'),
          note: _optStr(raw.note, source, 'verdicts[].note'),
        }),
      );
    }
    return new CodeSpecsGateRecord(entries, source);
  }

  private _check(source: string): void {
    const seen = new Set<string>();
    for (const e of this.verdicts) {
      if (e.area === '') {
        throw new CodeSpecsRecordError(
          `${source} has a verdict that names no area`,
        );
      }
      if (!_AREA_CODE_PATTERN.test(e.area)) {
        throw new CodeSpecsRecordError(
          `${source} names the area \`${e.area}\`, which is not a CE-* code`,
        );
      }
      if (seen.has(e.area)) {
        throw new CodeSpecsRecordError(
          `${source} carries two verdicts for ${e.area} — a scope with two ` +
            'answers for one area is no scope',
        );
      }
      seen.add(e.area);
      const resolution = e.resolution;
      if (resolution === null) {
        continue;
      }
      if (e.verdict !== CodeSpecsGateVerdict.insufficient) {
        throw new CodeSpecsRecordError(
          `${source} gives ${e.area} a \`resolution:\` on verdict ` +
            `\`${e.verdict.word}\` — only an insufficient area has an L0 ` +
            'decision to resolve',
        );
      }
      if (resolution !== K_CODE_SPECS_GATE_DESCOPED) {
        throw new CodeSpecsRecordError(
          `${source} gives ${e.area} the resolution \`${resolution}\` — ` +
            '`descoped` is the one resolution that admits a partial pass; ' +
            'any other resolution means the area was completed and its ' +
            'verdict re-taken',
        );
      }
    }
  }

  /** The entry for `area`, or `null` when the record says nothing about it. */
  verdictFor(area: string): CodeSpecsGateEntry | null {
    for (const e of this.verdicts) {
      if (e.area === area) {
        return e;
      }
    }
    return null;
  }

  /**
   * Throws {@link CodeSpecsRecordError} when an area is not an active area of
   * `catalog` — a verdict for an area that does not exist scopes nothing.
   */
  checkAgainst(
    catalog: CodeSpecsAreaCatalog,
    source: string = K_CODE_SPECS_GATE_RECORD_FILE,
  ): void {
    for (const e of this.verdicts) {
      const area = catalog.byCode(e.area);
      if (area === null || !area.active) {
        throw new CodeSpecsRecordError(
          `${source} gives a verdict for ${e.area}, which is not an active ` +
            'area of the catalogue',
        );
      }
    }
  }

  /**
   * A copy with `entry` recorded — replacing the area's earlier verdict in
   * place, or appended when the area had none.
   */
  withVerdict(entry: CodeSpecsGateEntry): CodeSpecsGateRecord {
    const out: CodeSpecsGateEntry[] = [];
    let replaced = false;
    for (const e of this.verdicts) {
      if (e.area === entry.area) {
        out.push(entry);
        replaced = true;
      } else {
        out.push(e);
      }
    }
    if (!replaced) {
      out.push(entry);
    }
    return new CodeSpecsGateRecord(out);
  }

  /**
   * The record as `gate.verdicts.yaml`. Byte-stable: the same record always
   * writes the same text, and `fromYaml(r.toYaml()).toYaml() === r.toYaml()`.
   *
   * `area` and `verdict` are written plain, as `codespecs_prompt.md` §6.3 shows
   * them — both are from a closed vocabulary the constructor checked — and a
   * note as a double-quoted scalar, the extract's one escaping rule.
   */
  toYaml(): string {
    const b = new _Buffer();
    b.writeln('gate:');
    b.writeln(`  formatVersion: ${K_CODE_SPECS_GATE_RECORD_FORMAT}`);
    if (this.verdicts.length === 0) {
      b.writeln('  verdicts: []');
      return b.toString();
    }
    b.writeln('  verdicts:');
    for (const e of this.verdicts) {
      b.writeln(`    - area: ${e.area}`);
      b.writeln(`      verdict: ${e.verdict.word}`);
      if (e.resolution !== null) {
        b.writeln(`      resolution: ${e.resolution}`);
      }
      if (e.note !== null) {
        b.writeln(`      note: ${yamlString(e.note)}`);
      }
    }
    return b.toString();
  }
}

/**
 * One area the gate record left out of scope. Kept visible rather than
 * dropped, so a consumer can say so: a scoped-out area must never read as a
 * covered one.
 */
export class CodeSpecsExcludedArea {
  /** The `CE-*` code. */
  readonly area: string;

  /** `notApplicable`, or `insufficient` with a recorded descope. */
  readonly verdict: CodeSpecsGateVerdict;

  /** Whether an insufficient verdict was resolved by descoping. */
  readonly descoped: boolean;

  /** How many routed entries the excluded extract carried (0 with no file). */
  readonly entryCount: number;

  /** The file the excluded extract was read from, or '' when there was none. */
  readonly source: string;

  constructor(props: {
    area: string;
    verdict: CodeSpecsGateVerdict;
    descoped?: boolean;
    entryCount?: number;
    source?: string;
  }) {
    this.area = props.area;
    this.verdict = props.verdict;
    this.descoped = props.descoped != null ? props.descoped : false;
    this.entryCount = props.entryCount != null ? props.entryCount : 0;
    this.source = props.source != null ? props.source : '';
  }

  toString(): string {
    return `CodeSpecsExcludedArea(${this.area}, ${this.verdict.word})`;
  }
}

/**
 * The files {@link CodeSpecsExtractSet.fromFiles} reads — file name → text, in
 * source order: a `Map`, an array (or other iterable) of `[name, text]` pairs,
 * or a plain object. Order matters: it is the in-scope order without a gate
 * record, and it decides which file an error names.
 */
export type CodeSpecsFiles =
  | ReadonlyMap<string, string>
  | Iterable<readonly [string, string]>
  | Readonly<Record<string, string>>;

/** Every extract one run produced, read back and scoped by its gate record. */
export class CodeSpecsExtractSet {
  /**
   * The in-scope extracts, in source order. With a gate record: the areas it
   * marks `sufficient`, in the record's order. Without: every extract.
   */
  readonly extracts: readonly CodeSpecsExtract[];

  /** The file each in-scope extract was read from, parallel to {@link extracts}. */
  readonly sources: readonly string[];

  /** The areas the gate record excluded — empty without a record. */
  readonly excluded: readonly CodeSpecsExcludedArea[];

  /** The gate record, when one was among the sources. */
  readonly gate: CodeSpecsGateRecord | null;

  private constructor(
    extracts: CodeSpecsExtract[],
    sources: string[],
    excluded: CodeSpecsExcludedArea[],
    gate: CodeSpecsGateRecord | null,
  ) {
    this.extracts = Object.freeze(extracts);
    this.sources = Object.freeze(sources);
    this.excluded = Object.freeze(excluded);
    this.gate = gate;
  }

  /**
   * Reads `files` — file name → text, ordered — into a scoped set.
   *
   * The file whose basename is {@link K_CODE_SPECS_GATE_RECORD_FILE} is the gate
   * record; every other file is an extract. The area code comes from the file's
   * content, never its name. With a record, an area is in scope **iff** its
   * verdict is `sufficient`, and:
   *
   *   * the record must carry a verdict for every extract supplied — a scope
   *     silent about an area would let a skipped area read as a passed one;
   *   * a `not applicable` area whose extract has entries is an error — a
   *     routed value is evidence the area applies (`codespecs_prompt.md` §6.4);
   *   * an `insufficient` area without `resolution: descoped` is an error — the
   *     run may not have continued past it (`codespecs_prompt.md` §6.2).
   *
   * Two extracts for one area, or two gate records, are errors. A name given
   * twice keeps its first position and its last text, as a map would.
   */
  static fromFiles(files: CodeSpecsFiles): CodeSpecsExtractSet {
    const map = _filesMap(files);
    let gateName: string | null = null;
    const extracts: CodeSpecsExtract[] = [];
    const sources: string[] = [];
    for (const [fileName, text] of map) {
      const segments = fileName.split('/');
      const basename = segments[segments.length - 1];
      if (basename === K_CODE_SPECS_GATE_RECORD_FILE) {
        if (gateName !== null) {
          throw new CodeSpecsRecordError(
            `both ${gateName} and ${fileName} are gate records — the scope ` +
              'must have one author',
          );
        }
        gateName = fileName;
        continue;
      }
      const x = parseCodeSpecsExtractYaml(text, fileName);
      const earlier = extracts.findIndex((e) => e.area.code === x.area.code);
      if (earlier >= 0) {
        throw new CodeSpecsRecordError(
          `${sources[earlier]} and ${fileName} are both extracts for ` +
            `${x.area.code}`,
        );
      }
      extracts.push(x);
      sources.push(fileName);
    }
    if (gateName === null) {
      return new CodeSpecsExtractSet(extracts, sources, [], null);
    }
    const gate = CodeSpecsGateRecord.fromYaml(
      map.get(gateName) as string,
      gateName,
    );
    for (let i = 0; i < extracts.length; i++) {
      if (gate.verdictFor(extracts[i].area.code) === null) {
        throw new CodeSpecsRecordError(
          `${gateName} carries no verdict for ${extracts[i].area.code} ` +
            `(${sources[i]}) — the gate record must be total over the ` +
            'supplied extracts',
        );
      }
    }
    const inScope: CodeSpecsExtract[] = [];
    const inScopeSources: string[] = [];
    const excluded: CodeSpecsExcludedArea[] = [];
    for (const v of gate.verdicts) {
      const i = extracts.findIndex((e) => e.area.code === v.area);
      const x = i < 0 ? null : extracts[i];
      const src = i < 0 ? '' : sources[i];
      if (v.verdict === CodeSpecsGateVerdict.sufficient) {
        if (x !== null) {
          inScope.push(x);
          inScopeSources.push(src);
        }
      } else if (v.verdict === CodeSpecsGateVerdict.notApplicable) {
        if (x !== null && x.entries.length > 0) {
          const n = x.entries.length;
          throw new CodeSpecsRecordError(
            `${gateName} marks ${v.area} \`not applicable\`, but ${src} ` +
              `carries ${n} routed entr${n === 1 ? 'y' : 'ies'} — a routed ` +
              'value is evidence the area applies (codespecs_prompt.md §6.4)',
          );
        }
        excluded.push(
          new CodeSpecsExcludedArea({
            area: v.area,
            verdict: v.verdict,
            entryCount: x === null ? 0 : x.entries.length,
            source: src,
          }),
        );
      } else {
        if (!v.descoped) {
          throw new CodeSpecsRecordError(
            `${gateName} marks ${v.area} \`insufficient\` without ` +
              '`resolution: descoped` — codespecs_prompt.md §6.2 says the ' +
              'run does not continue past an unresolved insufficient area; ' +
              'recording the descope is what legitimizes a partial pass',
          );
        }
        excluded.push(
          new CodeSpecsExcludedArea({
            area: v.area,
            verdict: v.verdict,
            descoped: true,
            entryCount: x === null ? 0 : x.entries.length,
            source: src,
          }),
        );
      }
    }
    return new CodeSpecsExtractSet(inScope, inScopeSources, excluded, gate);
  }

  /**
   * Reads a directory of extracts — `<CE-CODE>.extract.yaml` plus an optional
   * `gate.verdicts.yaml`; other files (the `.extract.md` views) are ignored.
   * Files are read in name order, so the set is the same on every file system.
   */
  static fromDirectory(path: string): CodeSpecsExtractSet {
    if (!fs.existsSync(path) || !fs.statSync(path).isDirectory()) {
      throw new CodeSpecsRecordError(`extract directory not found: ${path}`);
    }
    const names = fs
      .readdirSync(path, { withFileTypes: true })
      .filter((d) => d.isFile())
      .map((d) => d.name)
      .filter(
        (n) =>
          n.endsWith(K_CODE_SPECS_EXTRACT_FILE_SUFFIX) ||
          n === K_CODE_SPECS_GATE_RECORD_FILE,
      )
      .sort();
    return CodeSpecsExtractSet.fromFiles(
      names.map((n): [string, string] => [
        n,
        fs.readFileSync(`${path}/${n}`, 'utf8'),
      ]),
    );
  }

  /** The in-scope extract for `area`, or `null`. */
  byArea(area: string): CodeSpecsExtract | null {
    for (const x of this.extracts) {
      if (x.area.code === area) {
        return x;
      }
    }
    return null;
  }

  /**
   * Every in-scope entry routed from `sectionId` — the back-link token a
   * `DocRef` names — across every area, in extract order.
   */
  entriesForSection(sectionId: string): CodeSpecsExtractEntry[] {
    const out: CodeSpecsExtractEntry[] = [];
    for (const x of this.extracts) {
      for (const e of x.entries) {
        if (e.sectionId === sectionId) {
          out.push(e);
        }
      }
    }
    return out;
  }

  /** Every in-scope entry read from document `path`, in extract order. */
  entriesAtPath(path: string): CodeSpecsExtractEntry[] {
    const out: CodeSpecsExtractEntry[] = [];
    for (const x of this.extracts) {
      for (const e of x.entries) {
        if (e.path === path) {
          out.push(e);
        }
      }
    }
    return out;
  }
}

/**
 * A JSON string literal that is also a YAML 1.2 double-quoted scalar — the one
 * escaping rule every CodeSpecs artifact uses for free text.
 */
export function codeSpecsYamlString(value: string): string {
  return yamlString(value);
}

// --- record reading helpers -----------------------------------------------

function _filesMap(files: CodeSpecsFiles): Map<string, string> {
  if (files instanceof Map) {
    return new Map(files as ReadonlyMap<string, string>);
  }
  if (
    files != null &&
    typeof (files as Iterable<unknown>)[Symbol.iterator] === 'function'
  ) {
    return new Map(files as Iterable<readonly [string, string]>);
  }
  return new Map(Object.entries(files as Record<string, string>));
}

function _isMap(v: unknown): v is Record<string, any> {
  return v !== null && typeof v === 'object' && !Array.isArray(v);
}

/**
 * Whether `v` reads as an absent value. The runtime's YAML reader gives a key
 * with no value (`headline:`) an empty mapping where `package:yaml` gives null;
 * reading that as absent keeps the two readers agreeing on it.
 */
function _absent(v: unknown): boolean {
  return v == null || (_isMap(v) && Object.keys(v).length === 0);
}

/** A value as Dart's string interpolation shows it (`null`, not `undefined`). */
function _show(v: unknown): string {
  return v == null ? 'null' : String(v);
}

function _rootMapping(text: string, name: string, key: string): any {
  let document: unknown;
  try {
    document = yaml.parse(text, true);
  } catch (e) {
    const detail = e instanceof Error ? e.message : String(e);
    throw new CodeSpecsRecordError(`${name} is not valid YAML: ${detail}`);
  }
  if (!_isMap(document)) {
    throw new CodeSpecsRecordError(`${name} does not hold a YAML mapping`);
  }
  const root = document[key];
  if (!_isMap(root) || Object.keys(root).length === 0) {
    throw new CodeSpecsRecordError(
      `${name} has no top-level \`${key}:\` mapping`,
    );
  }
  return root;
}

function _str(v: unknown, name: string, key: string): string {
  if (_absent(v)) {
    return '';
  }
  if (typeof v === 'string') {
    return v;
  }
  throw new CodeSpecsRecordError(`${name}: \`${key}\` must be a string`);
}

function _optStr(v: unknown, name: string, key: string): string | null {
  if (_absent(v)) {
    return null;
  }
  if (typeof v === 'string') {
    return v;
  }
  throw new CodeSpecsRecordError(
    `${name}: \`${key}\` must be a string or null`,
  );
}

function _strList(v: unknown, name: string, key: string): string[] {
  if (_absent(v)) {
    return [];
  }
  if (!Array.isArray(v)) {
    throw new CodeSpecsRecordError(`${name}: \`${key}\` must be a list`);
  }
  return v.map((e) => _str(e, name, key));
}

function _intList(v: unknown, name: string, key: string): number[] {
  if (_absent(v)) {
    return [];
  }
  if (!Array.isArray(v)) {
    throw new CodeSpecsRecordError(`${name}: \`${key}\` must be a list`);
  }
  return v.map((e) => {
    if (typeof e === 'number' && Number.isInteger(e)) {
      return e;
    }
    throw new CodeSpecsRecordError(`${name}: \`${key}\` must hold integers`);
  });
}

// --- shared emission helpers ----------------------------------------------

/** A minimal stand-in for Dart's `StringBuffer` (writeln semantics). */
class _Buffer {
  private _parts: string[] = [];

  writeln(text = ''): void {
    this._parts.push(text);
    this._parts.push('\n');
  }

  toString(): string {
    return this._parts.join('');
  }
}

/**
 * Names a catalogue row for an error: `<key> "<value>"` for the first preferred
 * key the row carries as a non-empty string, else `the row with keys [...]`
 * (in the row's own key order), else `an empty row`.
 *
 * Deliberately tolerant — it runs before the required-key checks, so it must
 * produce something for a row missing the very key that would identify it.
 */
function gateRowLabel(j: any, preferred: string[]): string {
  for (const key of preferred) {
    const v = j != null ? j[key] : undefined;
    if (typeof v === 'string' && v !== '') {
      return `${key} "${v}"`;
    }
  }
  const keys = j != null && typeof j === 'object' ? Object.keys(j).join(', ') : '';
  return keys === '' ? 'an empty row' : `the row with keys [${keys}]`;
}

/** A required non-empty string of a gate-table row. */
function gateRequiredString(j: any, key: string, owner: string): string {
  const v = j != null ? j[key] : undefined;
  if (typeof v === 'string' && v !== '') {
    return v;
  }
  throw new Error(
    `CodeSpecs area catalogue: ${owner} is missing a non-empty "${key}" ` +
      `(got ${describeValue(v)})`,
  );
}

/**
 * A required numeric cell of a catalogue row, truncated to an integer. Only a
 * JSON number passes — the string `"2"` is rejected rather than coerced, and a
 * missing cell fails instead of reading `NaN`. The error names the row via
 * `owner` (a {@link gateRowLabel}).
 */
function gateRequiredInt(j: any, key: string, owner: string): number {
  const v = j != null ? j[key] : undefined;
  if (typeof v === 'number' && Number.isFinite(v)) {
    return Math.trunc(v);
  }
  throw new Error(
    `CodeSpecs area catalogue: ${owner} is missing a numeric "${key}" ` +
      `(got ${describeValue(v)})`,
  );
}

/**
 * Renders a rejected value for an error message: `absent` for a missing key,
 * else the value's type and its quoted text, so `"3"` and `3` differ.
 */
function describeValue(v: unknown): string {
  return v == null ? 'absent' : `${typeof v} ${yamlString(String(v))}`;
}

function stringList(raw: unknown): string[] {
  return Array.isArray(raw) ? raw.map((e) => String(e)) : [];
}

function intList(raw: unknown): number[] {
  return Array.isArray(raw) ? raw.map((e) => Math.trunc(Number(e))) : [];
}

/**
 * A JSON string literal, which is also a valid YAML 1.2 double-quoted scalar.
 * Hand-written rather than delegated to `JSON.stringify` so the eight ports have
 * one rule to transcribe rather than nine encoders to hope agree.
 */
function yamlString(value: string): string {
  const b: string[] = ['"'];
  for (const ch of value) {
    const rune = ch.codePointAt(0) as number;
    switch (rune) {
      case 0x22:
        b.push('\\"');
        break;
      case 0x5c:
        b.push('\\\\');
        break;
      case 0x08:
        b.push('\\b');
        break;
      case 0x0c:
        b.push('\\f');
        break;
      case 0x0a:
        b.push('\\n');
        break;
      case 0x0d:
        b.push('\\r');
        break;
      case 0x09:
        b.push('\\t');
        break;
      default:
        if (rune < 0x20) {
          b.push(`\\u${rune.toString(16).padStart(4, '0')}`);
        } else {
          b.push(ch);
        }
    }
  }
  b.push('"');
  return b.join('');
}

function yamlNullableString(value: string | null): string {
  return value === null ? 'null' : yamlString(value);
}

function yamlStringList(values: string[]): string {
  return `[${values.map(yamlString).join(', ')}]`;
}

function yamlIntList(values: number[]): string {
  return `[${values.join(', ')}]`;
}

/**
 * A markdown table cell: newlines folded to a space (a cell cannot hold one) and
 * `|` escaped. Applied only to catalogue prose, never to a stored value — values
 * go into fenced blocks, where they stay verbatim.
 */
function mdCell(value: string): string {
  return value.split('\n').join(' ').split('|').join('\\|');
}

function mdCodeList(values: string[]): string {
  return values.length === 0 ? '—' : values.map((v) => `\`${v}\``).join(', ');
}

function mdIntList(values: number[]): string {
  return values.length === 0 ? '—' : values.join(', ');
}

/** The shortest backtick fence that cannot be closed by `value`'s own content. */
function fenceFor(value: string): string {
  let longest = 0;
  let run = 0;
  for (let i = 0; i < value.length; i++) {
    if (value.charCodeAt(i) === 0x60) {
      run++;
      if (run > longest) {
        longest = run;
      }
    } else {
      run = 0;
    }
  }
  const width = longest >= 3 ? longest + 1 : 3;
  return '`'.repeat(width);
}
