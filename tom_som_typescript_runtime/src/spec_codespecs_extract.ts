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

  static fromJson(j: any): CodeSpecsSlice {
    return new CodeSpecsSlice({
      number: Math.trunc(Number(j.number)),
      title: j.title != null ? j.title : '',
      project: j.project != null ? j.project : '',
      cites: intList(j.cites),
    });
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

  static fromJson(j: any): CodeSpecsArea {
    return new CodeSpecsArea({
      code: j.code,
      canonicalId: j.canonicalId != null ? j.canonicalId : '',
      part: j.part,
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

  constructor(props: {
    source?: string;
    slices?: CodeSpecsSlice[];
    areas?: CodeSpecsArea[];
  }) {
    this.source = props.source != null ? props.source : '';
    this.slices = props.slices || [];
    this.areas = props.areas || [];
  }

  static fromJson(j: any): CodeSpecsAreaCatalog {
    return new CodeSpecsAreaCatalog({
      source: j.source != null ? j.source : '',
      slices: (j.slices || []).map((e: any) => CodeSpecsSlice.fromJson(e)),
      areas: (j.areas || []).map((e: any) => CodeSpecsArea.fromJson(e)),
    });
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
