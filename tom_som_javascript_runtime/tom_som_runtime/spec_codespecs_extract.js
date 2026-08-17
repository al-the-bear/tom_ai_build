'use strict';

/**
 * The Phase-4 **specification extract generator** — the machine half of
 * CodeSpecs production (`codespecs_mapping.md` §1.1.1). A faithful port of
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
 * every {@link CodeSpecsExtractEntry#value} is a string the document stores,
 * byte for byte, and the conformance corpus asserts it.
 *
 * Three things follow from that and shape the API:
 *
 *   * **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a
 *     class carries `@CodeSpecKind` (feeds code), sits under a `@FollowUpKind`
 *     root (feeds a non-generation process), or carries `@NoArtifact` (feeds
 *     nothing). The trio is exhaustive by construction, so a class carrying none
 *     of them is not "skipped": it is a {@link CodeSpecsExtractError}, the
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
 * runtimes. Carrying it beside the content is what stops an agent having to open
 * the mapping document to find out what `CE-FM` means.
 */

const { SpecFieldKind } = require('./spec_model');
const { specPathJoin } = require('./spec_paths');
const { SpecReflection } = require('./spec_reflection');

/**
 * The version of the emitted extract artifact's on-disk shape. Bumped when the
 * YAML or Markdown layout changes in a way a reader could notice.
 */
const K_CODESPECS_EXTRACT_FORMAT = 1;

/**
 * The annotation names of the three routing verdicts (`codespecs_mapping.md`
 * §8.3). All three ride the generic annotation bag in every SOM runtime (§8.4),
 * so they are read by name rather than through a meta slot.
 */
const K_CODESPEC_KIND_ANNOTATION = 'CodeSpecKind';

/** See {@link K_CODESPEC_KIND_ANNOTATION}. */
const K_FOLLOW_UP_KIND_ANNOTATION = 'FollowUpKind';

/** See {@link K_CODESPEC_KIND_ANNOTATION}. */
const K_NO_ARTIFACT_ANNOTATION = 'NoArtifact';

/** Which of the three `codespecs_mapping.md` §8.3 verdicts a class carries. */
const CodeSpecsRoutingVerdict = Object.freeze({
  /** `@CodeSpecKind(List<CodeSpecPart>)` — the section's content is shown to
   * every named area's extract. */
  FEEDS_CODE: 'feedsCode',

  /** `@FollowUpKind(List<FollowUpProcess>)` — the section is delivered by a
   * non-generation process. The whole subtree is excluded from every extract. */
  FEEDS_PROCESS: 'feedsProcess',

  /** `@NoArtifact(NoArtifactReason)` — the section deliberately produces no
   * downstream artifact. Its own leaves contribute nothing; its children are
   * still routed individually (that is what `container` means). */
  FEEDS_NOTHING: 'feedsNothing',

  /** A `@Document` root carrying no verdict. Structurally exempt from
   * `ROUTE-TOTAL`: a root is the document, not a section of it. */
  DOCUMENT_ROOT: 'documentRoot',

  /** No verdict, and not a `@Document` root — a `ROUTE-TOTAL` violation, and
   * the reason {@link CodeSpecsExtractor#extractAll} throws. */
  UNROUTED: 'unrouted',
});

/**
 * The verdict recorded for one class node of the walked document, with the
 * provenance of the marker that decided it.
 */
class CodeSpecsRouting {
  constructor({ path, className, verdict, values = [], note = null, declaredAt = '' }) {
    /** The document path of the node the verdict was computed for. */
    this.path = path;
    /** The model class at {@link CodeSpecsRouting#path}. */
    this.className = className;
    /** Which verdict the class carries (a {@link CodeSpecsRoutingVerdict}
     * constant). */
    this.verdict = verdict;
    /**
     * The verdict's payload, verbatim from the annotation: the `CodeSpecPart.*`
     * values for `feedsCode`, the `FollowUpProcess.*` values for `feedsProcess`,
     * the single `NoArtifactReason.*` for `feedsNothing`, and empty for the two
     * verdicts that have no marker.
     * @type {string[]}
     */
    this.values = values;
    /** The marker's optional `note`, verbatim; `null` when it carries none.
     * @type {?string} */
    this.note = note;
    /** Where the marker was declared — the class name, or `Class.field` when a
     * field-level `@CodeSpecKind` overrode its class. Empty when there is no
     * marker. */
    this.declaredAt = declaredAt;
  }

  toString() {
    return `CodeSpecsRouting(${this.path}, ${this.className}, ${this.verdict})`;
  }
}

/**
 * One extract entry: a single value the specification document stores, with
 * everything needed to trace it back (`codespecs_mapping.md` §1.1.1, "Entry").
 */
class CodeSpecsExtractEntry {
  constructor({
    areaCode,
    sectionId,
    path,
    className,
    fieldName,
    routedBy,
    routedAt,
    value,
    formField = null,
    routingNote = null,
  }) {
    /** The `CE-*` code of the area this entry was collected for. */
    this.areaCode = areaCode;
    /** The section id of the leaf the value sits on (`@SectionId`, else the
     * model field name). */
    this.sectionId = sectionId;
    /** The document path of the leaf — the source location. */
    this.path = path;
    /** The model class declaring the leaf. */
    this.className = className;
    /** The model field name of the leaf. */
    this.fieldName = fieldName;
    /** The form-field name when the value is one field of a `@Form` section;
     * `null` for a content, enum, scalar or scalar-list leaf. @type {?string} */
    this.formField = formField;
    /** The `CodeSpecPart.*` value that routed this entry here, verbatim. */
    this.routedBy = routedBy;
    /** Where that `@CodeSpecKind` was declared — the class name, or
     * `Class.field` for a field-level override. */
    this.routedAt = routedAt;
    /** The `@CodeSpecKind` `note`, verbatim; `null` when it carries none.
     * @type {?string} */
    this.routingNote = routingNote;
    /** The stored value, **verbatim**. Never assembled, reformatted or
     * trimmed. */
    this.value = value;
  }

  toString() {
    return `CodeSpecsExtractEntry(${this.areaCode}, ${this.path})`;
  }
}

/** One emission slice of `codespecs_mapping.md` §4.4.3. */
class CodeSpecsSlice {
  constructor({ number, title = '', project = '', cites = [] }) {
    /** The slice's number, 1–7. */
    this.number = number;
    /** The slice's name as §4.4.3 gives it. */
    this.title = title;
    /** The §4.2 project the slice emits into. */
    this.project = project;
    /** The slices this one may cite — §4.4.3's across-slice edges. Transitively
     * closed by {@link CodeSpecsAreaCatalog#citableAreaCodes}. @type {number[]} */
    this.cites = cites;
  }

  static fromJson(j) {
    return new CodeSpecsSlice({
      number: Math.trunc(j.number),
      title: j.title != null ? j.title : '',
      project: j.project != null ? j.project : '',
      cites: _intList(j.cites),
    });
  }
}

/**
 * One row of the `codespecs_mapping.md` §4.1 parts catalogue, plus the §4.4.3
 * slice and §4.4.6 authoring steps that place it. This is the **per-area
 * context** an extract carries beside its content.
 */
class CodeSpecsArea {
  constructor({
    code,
    canonicalId = '',
    part,
    annotations = [],
    builtOn = '',
    attributeSurface = '',
    slices = [],
    authoringSteps = [],
    active = true,
  }) {
    /** The permanent registry key — `CE-FM`, `CE-API`. Never reused, never
     * renamed, and the extract file's name. */
    this.code = code;
    /** The §4.1 canonical id — the PascalCase noun (`Form`, `ServerApi`). */
    this.canonicalId = canonicalId;
    /** The `CodeSpecPart` value, camelCase and **without** the enum prefix
     * (`form`, `serverApi`). */
    this.part = part;
    /** The `Cs*` annotation names of the §4.1 row. @type {string[]} */
    this.annotations = annotations;
    /** The §4.1 "Built on" cell, verbatim. */
    this.builtOn = builtOn;
    /** Where the area's spec-authorable attribute surface is stated — a §5.x
     * citation. */
    this.attributeSurface = attributeSurface;
    /** The §4.4.3 slice(s) the area's emission units sit in. More than one when
     * the area is split by locus. @type {number[]} */
    this.slices = slices;
    /** The §4.4.6 authoring step(s) that write the area. @type {number[]} */
    this.authoringSteps = authoringSteps;
    /** Whether the part is active. A deferred part (§4.3) holds a reserved
     * `CodeSpecPart` value but has no generated surface, so it gets no
     * extract. */
    this.active = active;
  }

  static fromJson(j) {
    return new CodeSpecsArea({
      code: j.code,
      canonicalId: j.canonicalId != null ? j.canonicalId : '',
      part: j.part,
      annotations: _stringList(j.annotations),
      builtOn: j.builtOn != null ? j.builtOn : '',
      attributeSurface: j.attributeSurface != null ? j.attributeSurface : '',
      slices: _intList(j.slices),
      authoringSteps: _intList(j.authoringSteps),
      active: j.active != null ? Boolean(j.active) : true,
    });
  }

  /** The fully-qualified `@CodeSpecKind` value — `CodeSpecPart.form`. */
  get kindValue() {
    return `CodeSpecPart.${this.part}`;
  }

  toString() {
    return `CodeSpecsArea(${this.code})`;
  }
}

/**
 * The machine-readable form of `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6.
 *
 * Authored once, read by all nine runtimes. It is an input rather than a baked
 * table because the catalogue is the mapping document's content: a copy per
 * runtime would be nine things to keep current, and the one thing this quest has
 * learned three times is that a vocabulary duplicated nine ways can be wrong in
 * agreement.
 */
class CodeSpecsAreaCatalog {
  constructor({ source = '', slices = [], areas = [] } = {}) {
    /** Where the catalogue was transcribed from, for the extract header. */
    this.source = source;
    /** The §4.4.3 slices, in emission order. @type {CodeSpecsSlice[]} */
    this.slices = slices;
    /** The §4.1 areas, in catalogue order. Catalogue order is the tie-break
     * §4.4.6 rule 2 uses, so it is load-bearing rather than cosmetic.
     * @type {CodeSpecsArea[]} */
    this.areas = areas;
  }

  static fromJson(j) {
    return new CodeSpecsAreaCatalog({
      source: j.source != null ? j.source : '',
      slices: (j.slices || []).map((e) => CodeSpecsSlice.fromJson(e)),
      areas: (j.areas || []).map((e) => CodeSpecsArea.fromJson(e)),
    });
  }

  /** The active areas, in catalogue order — one extract each.
   * @returns {CodeSpecsArea[]} */
  get activeAreas() {
    return this.areas.filter((a) => a.active);
  }

  /** The area with this `CE-*` code, or `null`. */
  byCode(code) {
    for (const a of this.areas) {
      if (a.code === code) {
        return a;
      }
    }
    return null;
  }

  /**
   * The area a `@CodeSpecKind` value names, or `null`. Accepts both the bare
   * value (`form`) and the qualified one (`CodeSpecPart.form`), because the meta
   * carries the qualified spelling and callers reach for the bare one.
   */
  byPart(value) {
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
  sliceNumbered(number) {
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
   * already fixes one project per slice, so a per-area project column would be a
   * second place for the same fact to be stated — and the areas that would need
   * it are exactly the locus-split ones, where getting it wrong is easiest.
   *
   * @param {CodeSpecsArea} area
   * @returns {string[]}
   */
  projectsFor(area) {
    const out = [];
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
   * Derived rather than authored: a hand-kept per-area citation list is a second
   * source of truth for something the slice graph already decides.
   *
   * @param {CodeSpecsArea} area
   * @returns {string[]}
   */
  citableAreaCodes(area) {
    const reachable = new Set();
    const stack = [...area.slices];
    while (stack.length > 0) {
      const n = stack.pop();
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
    const out = [];
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
class CodeSpecsExtract {
  constructor({
    area,
    documentRoot,
    catalogSource = '',
    citableParts = [],
    projects = [],
    entries = [],
  }) {
    /** The area this extract is for. @type {CodeSpecsArea} */
    this.area = area;
    /** The `codespecs_mapping.md` §4.1/§4.4.3 source the catalogue names. */
    this.catalogSource = catalogSource;
    /** The section segment of the document root the entries were collected
     * from. */
    this.documentRoot = documentRoot;
    /** The area codes this area may cite (§4.4.3), for the agent's prompt.
     * @type {string[]} */
    this.citableParts = citableParts;
    /** The §4.2 projects the area's code lands in (§4.4.3, via the slices).
     * @type {string[]} */
    this.projects = projects;
    /** The routed entries, in SOM document order.
     * @type {CodeSpecsExtractEntry[]} */
    this.entries = entries;
  }

  /** The extract's file name stem — `CE-FM.extract`. */
  get fileStem() {
    return `${this.area.code}.extract`;
  }

  /**
   * The artifact of record (`codespecs_mapping.md` §1.1.1). Scalars are emitted
   * as JSON strings, which are valid YAML 1.2 double-quoted scalars — so one
   * escaping rule, identical in all nine runtimes, covers every value a
   * specification can hold.
   *
   * @returns {string}
   */
  toYaml() {
    const b = new _Buffer();
    b.writeln(
      `# ${this.area.code}.extract.yaml — generated by ` +
        'spec_codespecs_extract. Do not edit.',
    );
    b.writeln('extract:');
    b.writeln(`  formatVersion: ${K_CODESPECS_EXTRACT_FORMAT}`);
    b.writeln(`  catalogSource: ${_yamlString(this.catalogSource)}`);
    b.writeln('  area:');
    b.writeln(`    code: ${_yamlString(this.area.code)}`);
    b.writeln(`    canonicalId: ${_yamlString(this.area.canonicalId)}`);
    b.writeln(`    part: ${_yamlString(this.area.kindValue)}`);
    b.writeln(`    annotations: ${_yamlStringList(this.area.annotations)}`);
    b.writeln(`    builtOn: ${_yamlString(this.area.builtOn)}`);
    b.writeln(`    attributeSurface: ${_yamlString(this.area.attributeSurface)}`);
    b.writeln(`    slices: ${_yamlIntList(this.area.slices)}`);
    b.writeln(`    authoringSteps: ${_yamlIntList(this.area.authoringSteps)}`);
    b.writeln(`    projects: ${_yamlStringList(this.projects)}`);
    b.writeln(`    citableParts: ${_yamlStringList(this.citableParts)}`);
    b.writeln('  document:');
    b.writeln(`    root: ${_yamlString(this.documentRoot)}`);
    b.writeln(`    entryCount: ${this.entries.length}`);
    if (this.entries.length === 0) {
      b.writeln('  entries: []');
      return b.toString();
    }
    b.writeln('  entries:');
    for (const e of this.entries) {
      b.writeln(`    - sectionId: ${_yamlString(e.sectionId)}`);
      b.writeln(`      path: ${_yamlString(e.path)}`);
      b.writeln(`      className: ${_yamlString(e.className)}`);
      b.writeln(`      fieldName: ${_yamlString(e.fieldName)}`);
      b.writeln(`      formField: ${_yamlNullableString(e.formField)}`);
      b.writeln(`      routedBy: ${_yamlString(e.routedBy)}`);
      b.writeln(`      routedAt: ${_yamlString(e.routedAt)}`);
      b.writeln(`      routingNote: ${_yamlNullableString(e.routingNote)}`);
      b.writeln(`      value: ${_yamlString(e.value)}`);
    }
    return b.toString();
  }

  /**
   * The rendered view. Regenerated from the YAML's own data — nothing reads the
   * Markdown as input — and exists because the agent reads it far better than it
   * reads YAML.
   *
   * @returns {string}
   */
  toMarkdown() {
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
    b.writeln(`| \`Cs*\` annotations | ${_mdCodeList(this.area.annotations)} |`);
    b.writeln(`| Built on | ${_mdCell(this.area.builtOn)} |`);
    b.writeln(`| Attribute surface | ${_mdCell(this.area.attributeSurface)} |`);
    b.writeln(`| Slice(s) | ${_mdIntList(this.area.slices)} |`);
    b.writeln(`| Authoring step(s) | ${_mdIntList(this.area.authoringSteps)} |`);
    b.writeln(`| Project(s) | ${_mdCodeList(this.projects)} |`);
    b.writeln(`| May cite | ${_mdCodeList(this.citableParts)} |`);
    b.writeln(`| Catalogue source | ${_mdCell(this.catalogSource)} |`);
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
      b.writeln(`- path: \`${e.path}\``);
      b.writeln(`- routed by: \`${e.routedBy}\` declared on \`${e.routedAt}\``);
      if (e.routingNote !== null) {
        b.writeln(`- routing note: ${_mdCell(e.routingNote)}`);
      }
      b.writeln();
      const fence = _fenceFor(e.value);
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
 * The only cause today is a section routed nowhere — `ROUTE-TOTAL`
 * (`tom_specs_model_rules.md` §10.2) failing. It is an error rather than a skip
 * because a section routed nowhere is a section the agent writing that area
 * never sees, and a silent omission at this boundary is indistinguishable from a
 * specification that genuinely said nothing.
 */
class CodeSpecsExtractError extends Error {
  /** @param {{message: string, path: string, className: string}} options */
  constructor({ message, path, className }) {
    super(message);
    this.name = 'CodeSpecsExtractError';
    /** The document path of the offending node. */
    this.path = path;
    /** The model class at {@link CodeSpecsExtractError#path}. */
    this.className = className;
  }

  toString() {
    return `CodeSpecsExtractError: ${this.message} (${this.path}, ${this.className})`;
  }
}

/**
 * Produces one {@link CodeSpecsExtract} per active area from a filled
 * specification document.
 */
class CodeSpecsExtractor {
  /**
   * @param {{model: import('./spec_model').SpecModel,
   *          document: import('./spec_document').SpecDocument,
   *          catalog: CodeSpecsAreaCatalog}} options
   */
  constructor({ model, document, catalog }) {
    /** The model describing the document's structure and carrying the routing
     * verdicts. */
    this.model = model;
    /** The filled specification document. */
    this.document = document;
    /** The area catalogue — `codespecs_mapping.md` §4.1/§4.4.3/§4.4.6. */
    this.catalog = catalog;
    this._reflection = new SpecReflection(model);
  }

  /**
   * The verdict of every class node the walk reaches, in document order.
   *
   * Computed by the same walk {@link CodeSpecsExtractor#extractAll} uses, so
   * "what was routed where" and "what landed in which extract" cannot disagree.
   * Unlike `extractAll` this does **not** throw on an unrouted class — it
   * reports it, which is what a diagnostic is for.
   *
   * @returns {CodeSpecsRouting[]}
   */
  routings() {
    const out = [];
    this._walkAll({ routings: out, entries: null, strict: false });
    return out;
  }

  /**
   * One extract per active area, in catalogue order.
   *
   * Throws {@link CodeSpecsExtractError} on the first class the walk reaches
   * that carries none of the three verdicts.
   *
   * @returns {CodeSpecsExtract[]}
   */
  extractAll() {
    const entries = [];
    this._walkAll({ routings: null, entries, strict: true });
    const root =
      this.model.roots.length === 0
        ? ''
        : this._reflection.rootSegment(this.model.roots[0]);
    const out = [];
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
   *
   * @param {string} areaCode
   * @returns {?CodeSpecsExtract}
   */
  extractFor(areaCode) {
    for (const e of this.extractAll()) {
      if (e.area.code === areaCode) {
        return e;
      }
    }
    return null;
  }

  // --- the walk -------------------------------------------------------------

  _walkAll({ routings, entries, strict }) {
    for (const root of this.model.roots) {
      this._walk({
        path: this._reflection.rootSegment(root),
        cls: this.model.classNamed(root.type),
        ancestorTypes: new Set([root.type]),
        routings,
        entries,
        strict,
      });
    }
  }

  _walk({ path, cls, ancestorTypes, routings, entries, strict }) {
    if (cls === null || cls === undefined) {
      return;
    }
    const routing = this._verdictOf(cls, path);
    if (routings !== null) {
      routings.push(routing);
    }

    switch (routing.verdict) {
      case CodeSpecsRoutingVerdict.FEEDS_PROCESS:
        return; // the whole subtree is delivered by a non-generation process
      case CodeSpecsRoutingVerdict.UNROUTED:
        if (strict) {
          throw new CodeSpecsExtractError({
            message:
              'section carries none of the three routing verdicts ' +
              '(@CodeSpecKind / @FollowUpKind / @NoArtifact) — ' +
              'tom_specs_model_rules.md §10.2 ROUTE-TOTAL',
            path,
            className: cls.name,
          });
        }
        break;
      default:
        break;
    }

    const classRouting =
      routing.verdict === CodeSpecsRoutingVerdict.FEEDS_CODE ? routing : null;

    for (const field of cls.fields) {
      const fieldPath = specPathJoin(path, this._reflection.fieldSegment(field));
      const own = this._fieldRouting(cls, field);
      const fieldRouting = own === null ? classRouting : own;

      switch (field.kind) {
        case SpecFieldKind.CONTENT:
        case SpecFieldKind.ENUM:
        case SpecFieldKind.SCALAR:
          this._emitValue({
            entries,
            routing: fieldRouting,
            cls,
            field,
            path: fieldPath,
            formField: null,
            value: this.document.content(fieldPath),
          });
          break;
        case SpecFieldKind.FORM:
          for (const ff of field.formFields) {
            this._emitValue({
              entries,
              routing: fieldRouting,
              cls,
              field,
              path: fieldPath,
              formField: ff.name,
              value: this.document.formField(fieldPath, ff.name),
            });
          }
          break;
        case SpecFieldKind.LIST:
          for (const itemPath of this.document.listItems(fieldPath)) {
            if (
              field.elementIsComplex &&
              field.elementType !== null &&
              !ancestorTypes.has(field.elementType)
            ) {
              this._walk({
                path: itemPath,
                cls: this.model.classNamed(field.elementType),
                ancestorTypes: new Set([...ancestorTypes, field.elementType]),
                routings,
                entries,
                strict,
              });
            } else {
              this._emitValue({
                entries,
                routing: fieldRouting,
                cls,
                field,
                path: itemPath,
                formField: null,
                value: this.document.content(itemPath),
              });
            }
          }
          break;
        case SpecFieldKind.COMPLEX:
        case SpecFieldKind.SECTION:
          if (field.type !== null && !ancestorTypes.has(field.type)) {
            this._walk({
              path: fieldPath,
              cls: this.model.classNamed(field.type),
              ancestorTypes: new Set([...ancestorTypes, field.type]),
              routings,
              entries,
              strict,
            });
          }
          break;
        default:
          break;
      }
    }
  }

  /**
   * Appends one entry **per area the routing names** — never deduplicated,
   * because each area's prompt must be self-sufficient (§1.1.1).
   */
  _emitValue({ entries, routing, cls, field, path, formField, value }) {
    if (entries === null || routing === null) {
      return;
    }
    if (value === null || value === undefined || value === '') {
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

  // --- verdict resolution ---------------------------------------------------

  /**
   * The verdict `cls` carries. The three markers are mutually exclusive
   * (`KIND-EXCLUSIVE`), so the order they are tested in is a readability choice
   * rather than a precedence rule.
   *
   * Read through the model's own annotated-node accessors rather than off the
   * raw annotation bag: they already know that `@CodeSpecKind`'s list argument
   * is `kinds` while `@FollowUpKind`'s is `processes`, and they strip the enum
   * prefix, so the codes here are bare whatever spelling the meta chose. Two
   * readers of the same annotations would be two chances to disagree.
   *
   * @param {import('./spec_model').SpecClass} cls
   * @param {string} path
   * @returns {CodeSpecsRouting}
   */
  _verdictOf(cls, path) {
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
   *
   * @param {import('./spec_model').SpecClass} cls
   * @param {import('./spec_model').SpecField} field
   * @returns {?CodeSpecsRouting}
   */
  _fieldRouting(cls, field) {
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

// --- shared emission helpers -------------------------------------------------

/** A tiny StringBuffer with Dart-style `writeln` semantics. */
class _Buffer {
  constructor() {
    this._parts = [];
  }

  writeln(text = '') {
    this._parts.push(text);
    this._parts.push('\n');
  }

  toString() {
    return this._parts.join('');
  }
}

function _stringList(raw) {
  return Array.isArray(raw) ? raw.map((e) => String(e)) : [];
}

function _intList(raw) {
  return Array.isArray(raw) ? raw.map((e) => Math.trunc(e)) : [];
}

/**
 * A JSON string literal, which is also a valid YAML 1.2 double-quoted scalar.
 * Hand-written rather than delegated to `JSON.stringify` so the eight ports have
 * one rule to transcribe rather than nine encoders to hope agree.
 *
 * @param {string} value
 * @returns {string}
 */
function _yamlString(value) {
  const b = ['"'];
  // `for…of` over a string yields whole code points, matching Dart's `runes` —
  // a surrogate pair is one iteration and is re-emitted unchanged.
  for (const ch of value) {
    const rune = ch.codePointAt(0);
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
        break;
    }
  }
  b.push('"');
  return b.join('');
}

function _yamlNullableString(value) {
  return value === null || value === undefined ? 'null' : _yamlString(value);
}

function _yamlStringList(values) {
  return `[${values.map((v) => _yamlString(v)).join(', ')}]`;
}

function _yamlIntList(values) {
  return `[${values.join(', ')}]`;
}

/**
 * A markdown table cell: newlines folded to a space (a cell cannot hold one) and
 * `|` escaped. Applied only to catalogue prose, never to a stored value — values
 * go into fenced blocks, where they stay verbatim.
 *
 * @param {string} value
 * @returns {string}
 */
function _mdCell(value) {
  return value.replace(/\n/g, ' ').replace(/\|/g, '\\|');
}

function _mdCodeList(values) {
  return values.length === 0 ? '—' : values.map((v) => `\`${v}\``).join(', ');
}

function _mdIntList(values) {
  return values.length === 0 ? '—' : values.join(', ');
}

/**
 * The shortest backtick fence that cannot be closed by `value`'s own content.
 *
 * @param {string} value
 * @returns {string}
 */
function _fenceFor(value) {
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

module.exports = {
  K_CODESPECS_EXTRACT_FORMAT,
  K_CODESPEC_KIND_ANNOTATION,
  K_FOLLOW_UP_KIND_ANNOTATION,
  K_NO_ARTIFACT_ANNOTATION,
  CodeSpecsRoutingVerdict,
  CodeSpecsRouting,
  CodeSpecsExtractEntry,
  CodeSpecsSlice,
  CodeSpecsArea,
  CodeSpecsAreaCatalog,
  CodeSpecsExtract,
  CodeSpecsExtractError,
  CodeSpecsExtractor,
};
