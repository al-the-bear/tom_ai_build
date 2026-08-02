/**
 * In-memory representation of the exported TomSpecs class graph (the spec-model
 * meta-data file) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_model.dart` (and the JavaScript
 * `spec_model.js`).
 *
 * The model is a *class graph*, not an expanded tree: each class appears once and
 * field `elementType` / `type` references are followed on demand by a traversal.
 * This is the "reflection" surface — it describes any document's structure,
 * independent of the values a concrete document holds.
 */

/** The render kind of a field, mirroring the exporter's classification. */
export const SpecFieldKind = {
  LIST: 'list',
  FORM: 'form',
  SECTION: 'section',
  CONTENT: 'content',
  ENUM: 'enum',
  COMPLEX: 'complex',
  SCALAR: 'scalar',
} as const;

export type SpecFieldKindValue =
  (typeof SpecFieldKind)[keyof typeof SpecFieldKind];

const _FIELD_KIND_VALUES = new Set<string>(Object.values(SpecFieldKind));

/** Parses a raw kind string, falling back to `scalar`. */
export function parseFieldKind(raw: string): SpecFieldKindValue {
  return _FIELD_KIND_VALUES.has(raw)
    ? (raw as SpecFieldKindValue)
    : SpecFieldKind.SCALAR;
}

/**
 * A single annotation captured losslessly from the model source (som_multiplatform_spec_model.md §5.3): its
 * name and the resolved argument map.
 */
export class SpecAnnotation {
  name: string;
  arguments: Record<string, unknown>;

  constructor(name: string, args?: Record<string, unknown>) {
    this.name = name;
    this.arguments = args || {};
  }

  argument(key: string): unknown {
    return this.arguments[key];
  }

  static fromJson(j: any): SpecAnnotation {
    return new SpecAnnotation(j.name, { ...(j.arguments || {}) });
  }

  static listFromJson(raw: any): SpecAnnotation[] {
    if (!Array.isArray(raw)) {
      return [];
    }
    return raw.map((e) => SpecAnnotation.fromJson(e));
  }
}

/** A single form field within a `@Form` content section. */
export class FormFieldSpec {
  name: string;
  label: string;
  type: string;
  hint: string | null;
  required: boolean;
  /**
   * Enum constant names when {@link type} is a model enum; empty for non-enum
   * field types. Lets consumers validate and convert values without the
   * analyzer.
   */
  enumValues: string[];
  /**
   * The registry key(s) this field's value is an id drawn from, each written
   * `<SECTIONID>.<formFieldName>`; empty for a non-reference field. A reference
   * field holds a free-text id that must already be declared by some entry of
   * the named registry, so a runtime can resolve it and report a dangling id
   * instead of generating broken code.
   */
  refersTo: string[];

  constructor(props: {
    name: string;
    label: string;
    type?: string;
    hint?: string | null;
    required?: boolean;
    enumValues?: string[];
    refersTo?: string[];
  }) {
    this.name = props.name;
    this.label = props.label;
    this.type = props.type != null ? props.type : 'String';
    this.hint = props.hint != null ? props.hint : null;
    this.required = Boolean(props.required || false);
    this.enumValues = props.enumValues || [];
    this.refersTo = props.refersTo || [];
  }

  static fromJson(j: any): FormFieldSpec {
    return new FormFieldSpec({
      name: j.name,
      label: j.label || j.name,
      type: j.type || 'String',
      hint: j.hint != null ? j.hint : null,
      required: Boolean(j.required || false),
      enumValues: (j.enumValues || []).map((e: unknown) => String(e)),
      refersTo: (j.refersTo || []).map((e: unknown) => String(e)),
    });
  }
}

/** A single field of a {@link SpecClass}. */
export class SpecField {
  name: string;
  kind: SpecFieldKindValue;
  doc: string | null;
  help: string | null;
  /**
   * The `@Headline(text)` default headline (YRD4), or `null`. Render
   * precedence: stored headline > this default > name derivation.
   */
  headline: string | null;
  sectionId: string | null;
  sectionIdPattern: string | null;
  serializationOrder: number | null;
  elementType: string | null;
  elementIsComplex: boolean;
  min: number | null;
  contentType: string | null;
  sectionType: string | null;
  enumType: string | null;
  enumValues: string[];
  type: string | null;
  formFields: FormFieldSpec[];
  annotations: SpecAnnotation[];

  constructor(props: {
    name: string;
    kind: SpecFieldKindValue;
    doc?: string | null;
    help?: string | null;
    headline?: string | null;
    sectionId?: string | null;
    sectionIdPattern?: string | null;
    serializationOrder?: number | null;
    elementType?: string | null;
    elementIsComplex?: boolean;
    min?: number | null;
    contentType?: string | null;
    sectionType?: string | null;
    enumType?: string | null;
    enumValues?: string[];
    type?: string | null;
    formFields?: FormFieldSpec[];
    annotations?: SpecAnnotation[];
  }) {
    this.name = props.name;
    this.kind = props.kind;
    this.doc = props.doc != null ? props.doc : null;
    this.help = props.help != null ? props.help : null;
    this.headline = props.headline != null ? props.headline : null;
    this.sectionId = props.sectionId != null ? props.sectionId : null;
    this.sectionIdPattern =
      props.sectionIdPattern != null ? props.sectionIdPattern : null;
    this.serializationOrder =
      props.serializationOrder != null ? props.serializationOrder : null;
    this.elementType = props.elementType != null ? props.elementType : null;
    this.elementIsComplex = Boolean(props.elementIsComplex || false);
    this.min = props.min != null ? props.min : null;
    this.contentType = props.contentType != null ? props.contentType : null;
    this.sectionType = props.sectionType != null ? props.sectionType : null;
    this.enumType = props.enumType != null ? props.enumType : null;
    this.enumValues = props.enumValues || [];
    this.type = props.type != null ? props.type : null;
    this.formFields = props.formFields || [];
    this.annotations = props.annotations || [];
  }

  static fromJson(j: any): SpecField {
    return new SpecField({
      name: j.name,
      kind: parseFieldKind(j.kind),
      doc: j.doc,
      help: j.help,
      headline: j.headline,
      sectionId: j.sectionId,
      sectionIdPattern: j.sectionIdPattern,
      serializationOrder:
        j.serializationOrder != null
          ? parseInt(j.serializationOrder, 10)
          : null,
      elementType: j.elementType,
      elementIsComplex: Boolean(j.elementIsComplex || false),
      min: j.min,
      contentType: j.contentType,
      sectionType: j.sectionType,
      enumType: j.enumType,
      enumValues: (j.enumValues || []).map((e: unknown) => String(e)),
      type: j.type,
      formFields: (j.formFields || []).map((e: any) => FormFieldSpec.fromJson(e)),
      annotations: SpecAnnotation.listFromJson(j.annotations),
    });
  }

  /** Whether expanding this field reveals further tree nodes. */
  get isExpandable(): boolean {
    return (
      this.kind === SpecFieldKind.LIST || this.kind === SpecFieldKind.COMPLEX
    );
  }

  annotation(name: string): SpecAnnotation | null {
    return this.annotations.find((a) => a.name === name) || null;
  }
}

/** A model class with its fields. */
export class SpecClass {
  name: string;
  sectionId: string | null;
  doc: string | null;
  help: string | null;
  /**
   * The class-level `@Headline(text)` default headline (YRD4), or `null`.
   * A field-level `@Headline` on the instantiating field wins over this.
   */
  headline: string | null;
  mapsTo: string | null;
  detailedIn: string | null;
  fields: SpecField[];
  annotations: SpecAnnotation[];

  constructor(props: {
    name: string;
    sectionId?: string | null;
    doc?: string | null;
    help?: string | null;
    headline?: string | null;
    mapsTo?: string | null;
    detailedIn?: string | null;
    fields?: SpecField[];
    annotations?: SpecAnnotation[];
  }) {
    this.name = props.name;
    this.sectionId = props.sectionId != null ? props.sectionId : null;
    this.doc = props.doc != null ? props.doc : null;
    this.help = props.help != null ? props.help : null;
    this.headline = props.headline != null ? props.headline : null;
    this.mapsTo = props.mapsTo != null ? props.mapsTo : null;
    this.detailedIn = props.detailedIn != null ? props.detailedIn : null;
    this.fields = props.fields || [];
    this.annotations = props.annotations || [];
  }

  static fromJson(j: any): SpecClass {
    return new SpecClass({
      name: j.name,
      sectionId: j.sectionId,
      doc: j.doc,
      help: j.help,
      headline: j.headline,
      mapsTo: j.mapsTo,
      detailedIn: j.detailedIn,
      fields: j.fields.map((e: any) => SpecField.fromJson(e)),
      annotations: SpecAnnotation.listFromJson(j.annotations),
    });
  }

  fieldNamed(name: string): SpecField | null {
    return this.fields.find((f) => f.name === name) || null;
  }

  annotation(name: string): SpecAnnotation | null {
    return this.annotations.find((a) => a.name === name) || null;
  }
}

/** A document root (a class carrying `@Document`). */
export class SpecRoot {
  type: string;
  title: string;
  sectionId: string | null;
  description: string | null;
  doc: string | null;

  constructor(props: {
    type: string;
    title: string;
    sectionId?: string | null;
    description?: string | null;
    doc?: string | null;
  }) {
    this.type = props.type;
    this.title = props.title;
    this.sectionId = props.sectionId != null ? props.sectionId : null;
    this.description = props.description != null ? props.description : null;
    this.doc = props.doc != null ? props.doc : null;
  }

  static fromJson(j: any): SpecRoot {
    return new SpecRoot({
      type: j.type,
      title: j.title,
      sectionId: j.sectionId != null ? j.sectionId : null,
      description: j.description != null ? j.description : null,
      doc: j.doc != null ? j.doc : null,
    });
  }
}

/** One day in milliseconds — the unit thresholds and ages are reported in. */
export const MILLIS_PER_DAY = 86400000;

/**
 * How old a snapshot may get before {@link SpecModel.checkStamp} calls it aged.
 *
 * A fortnight: long enough that a healthy working copy is never nagged, short
 * enough that structural feedback keyed to a snapshot's paths is not recorded
 * against a model that has moved past them.
 */
export const DEFAULT_MAX_SNAPSHOT_AGE_MS = 14 * MILLIS_PER_DAY;

/**
 * The generation-stamp timestamp grammar, spelled out rather than delegated to
 * `Date.parse`: `YYYY-MM-DDTHH:MM:SS`, an optional fractional part, and an
 * optional `Z` / `±HH:MM` / `±HHMM` offset.
 *
 * Every SOM runtime carries this same grammar. Delegating to each platform's
 * own parser would make the accepted set differ by language — several of the
 * nine have no date library at all — and a stamp that reads on one platform and
 * not another is exactly the divergence the shared corpus exists to catch.
 */
const STAMP_PATTERN =
  /^(\d{4})-(\d{2})-(\d{2})[Tt ](\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|z|[+-]\d{2}:?\d{2})?$/;

/**
 * The length of `month` in `year`, Gregorian. Used to reject a day that does
 * not exist rather than letting it roll into the next month: `Date.UTC` would
 * turn 31 February into 3 March, while several other SOM runtimes' date types
 * reject it outright — so the grammar rejects it everywhere.
 */
function daysInMonth(year: number, month: number): number {
  if (month !== 2) {
    return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][month - 1];
  }
  const isLeap = year % 4 === 0 && (year % 100 !== 0 || year % 400 === 0);
  return isLeap ? 29 : 28;
}

/**
 * Parses a generation-stamp timestamp to a UTC `Date`, or returns `null`.
 *
 * A timestamp carrying **no** zone is read as UTC. `new Date(string)` would
 * read it as the reader's local time, which would make a staleness verdict
 * depend on where the reader sits — a defect in its own right, and one the
 * other eight SOM runtimes could not mirror anyway (several have no timezone
 * database). Fixing the fallback here is what lets all nine agree.
 *
 * Anything outside the grammar — or carrying an out-of-range field — degrades
 * to `null` rather than throwing: an unreadable stamp is not worth failing a
 * whole model over.
 */
export function parseStampTimestamp(raw: string | null | undefined): Date | null {
  if (raw == null) {
    return null;
  }
  const m = STAMP_PATTERN.exec(String(raw).trim());
  if (m === null) {
    return null;
  }
  const year = parseInt(m[1], 10);
  const month = parseInt(m[2], 10);
  const day = parseInt(m[3], 10);
  const hour = parseInt(m[4], 10);
  const minute = parseInt(m[5], 10);
  const second = parseInt(m[6], 10);
  if (month < 1 || month > 12 || day < 1 || day > daysInMonth(year, month)) {
    return null;
  }
  if (hour > 23 || minute > 59 || second > 59) {
    return null;
  }
  // Right-pad the fraction to milliseconds; a longer fraction is truncated.
  const millis = parseInt((m[7] || '').padEnd(3, '0').slice(0, 3), 10);
  let epochMs = Date.UTC(year, month - 1, day, hour, minute, second, millis);
  const zone = m[8];
  if (zone != null && zone !== 'Z' && zone !== 'z') {
    const digits = zone.slice(1).replace(':', '');
    const offsetMs =
      (parseInt(digits.slice(0, 2), 10) * 60 + parseInt(digits.slice(2), 10)) *
      60000;
    epochMs += zone[0] === '-' ? offsetMs : -offsetMs;
  }
  return new Date(epochMs);
}

/**
 * A stamp count as a number, or `null` when the key is absent.
 *
 * Absent must stay `null` rather than becoming `0`: a snapshot predating the
 * stamp keys would otherwise declare zero classes and read as corrupt.
 */
function optionalInt(raw: unknown): number | null {
  if (typeof raw !== 'number' || !Number.isFinite(raw)) {
    return null;
  }
  return Math.trunc(raw);
}

/**
 * The outcome of checking a loaded snapshot's generation stamp against its own
 * payload and against the clock — see {@link SpecModel.checkStamp}.
 *
 * The two findings are independent and can both hold at once: `isAged` says the
 * snapshot is probably behind the live model, while `countsDisagree` says the
 * file no longer describes itself correctly. Only the second is a defect in the
 * file.
 */
export class SpecModelStampCheck {
  /** How long ago the snapshot was generated, or null when it carries no
   * `generatedAt` (an older export, or a hand-built model). */
  ageMs: number | null;
  /** The threshold {@link ageMs} was judged against. */
  maxAgeMs: number;
  declaredClassCount: number | null;
  actualClassCount: number;
  declaredRootCount: number | null;
  actualRootCount: number;

  constructor(props: {
    ageMs: number | null;
    maxAgeMs: number;
    declaredClassCount: number | null;
    actualClassCount: number;
    declaredRootCount: number | null;
    actualRootCount: number;
  }) {
    this.ageMs = props.ageMs;
    this.maxAgeMs = props.maxAgeMs;
    this.declaredClassCount = props.declaredClassCount;
    this.actualClassCount = props.actualClassCount;
    this.declaredRootCount = props.declaredRootCount;
    this.actualRootCount = props.actualRootCount;
  }

  /** Whether the snapshot is older than {@link maxAgeMs}. Always false when it
   * carries no `generatedAt` — an unknown age is not evidence of a stale one. */
  get isAged(): boolean {
    return this.ageMs != null && this.ageMs > this.maxAgeMs;
  }

  /**
   * Whether the declared and actual class counts differ.
   *
   * An absent declaration is not a disagreement: older snapshots predate the
   * stamp keys, and reading absent as `0` would make every one of them look
   * corrupt.
   */
  get classCountDisagrees(): boolean {
    return (
      this.declaredClassCount != null &&
      this.declaredClassCount !== this.actualClassCount
    );
  }

  /** Whether the declared and actual root counts differ. Absent declarations
   * are ignored, as for {@link classCountDisagrees}. */
  get rootCountDisagrees(): boolean {
    return (
      this.declaredRootCount != null &&
      this.declaredRootCount !== this.actualRootCount
    );
  }

  /**
   * Whether either declared size disagrees with the payload.
   *
   * The exporter derives both counts *from* the payload it writes, so a
   * disagreement cannot arise from a normal export — it means the file was
   * edited or truncated afterwards.
   */
  get countsDisagree(): boolean {
    return this.classCountDisagrees || this.rootCountDisagrees;
  }

  /** Whether anything at all was found. */
  get isStale(): boolean {
    return this.isAged || this.countsDisagree;
  }

  /** The findings as ready-to-display sentences, empty when there are none.
   * The wording is identical in all nine runtimes. */
  get warnings(): string[] {
    const out: string[] = [];
    if (this.isAged) {
      const days = Math.trunc((this.ageMs as number) / MILLIS_PER_DAY);
      const threshold = Math.trunc(this.maxAgeMs / MILLIS_PER_DAY);
      out.push(
        `Snapshot is ${days} days old (threshold ${threshold} days) — the ` +
          'model may have moved on since it was exported.',
      );
    }
    if (this.classCountDisagrees) {
      out.push(
        `Stamp declares ${this.declaredClassCount} classes but the snapshot ` +
          `carries ${this.actualClassCount} — it was edited after export.`,
      );
    }
    if (this.rootCountDisagrees) {
      out.push(
        `Stamp declares ${this.declaredRootCount} document roots but the ` +
          `snapshot carries ${this.actualRootCount} — it was edited after ` +
          'export.',
      );
    }
    return out;
  }
}

/** The complete exported model. */
export class SpecModel {
  roots: SpecRoot[];
  classes: Map<string, SpecClass>;
  modelVersion: number;
  modelVersionLabel: string | null;
  /** When the snapshot was exported (UTC), or null when it carries no
   * `generatedAt` — an export predating the key, or a hand-built model. */
  generatedAt: Date | null;
  /** The *file format's* own version, distinct from {@link modelVersion} (which
   * model the snapshot describes). Null when undeclared. */
  metaSchemaVersion: number | null;
  /** The class count the snapshot declares, or null when undeclared. Kept
   * separate from `classes.size`: the declared value is what the exporter
   * recorded, the actual value is what survived to the reader, and comparing
   * them is the point ({@link checkStamp}). */
  classCount: number | null;
  /** The document-root count the snapshot declares, or null when undeclared. */
  rootCount: number | null;
  /** The canonical container class — the single true tree root, which is not
   * itself a document and so does not appear in {@link roots}. Null when the
   * model has no container (e.g. a synthetic export). */
  containerRoot: string | null;

  constructor(props: {
    roots: SpecRoot[];
    classes: Map<string, SpecClass>;
    modelVersion?: number;
    modelVersionLabel?: string | null;
    generatedAt?: Date | null;
    metaSchemaVersion?: number | null;
    classCount?: number | null;
    rootCount?: number | null;
    containerRoot?: string | null;
  }) {
    this.roots = props.roots;
    this.classes = props.classes;
    this.modelVersion = props.modelVersion != null ? props.modelVersion : 0;
    this.modelVersionLabel =
      props.modelVersionLabel != null ? props.modelVersionLabel : null;
    this.generatedAt = props.generatedAt != null ? props.generatedAt : null;
    this.metaSchemaVersion =
      props.metaSchemaVersion != null ? props.metaSchemaVersion : null;
    this.classCount = props.classCount != null ? props.classCount : null;
    this.rootCount = props.rootCount != null ? props.rootCount : null;
    this.containerRoot =
      props.containerRoot != null ? props.containerRoot : null;
  }

  /**
   * Checks the generation stamp against the payload and the clock.
   *
   * `now` is injectable so callers (and tests) can evaluate age against a fixed
   * instant instead of the wall clock.
   */
  checkStamp(
    options: { maxAgeMs?: number; now?: Date | null } = {},
  ): SpecModelStampCheck {
    const maxAgeMs =
      options.maxAgeMs != null ? options.maxAgeMs : DEFAULT_MAX_SNAPSHOT_AGE_MS;
    const moment = options.now != null ? options.now : new Date();
    return new SpecModelStampCheck({
      ageMs:
        this.generatedAt == null
          ? null
          : moment.getTime() - this.generatedAt.getTime(),
      maxAgeMs,
      declaredClassCount: this.classCount,
      actualClassCount: this.classes.size,
      declaredRootCount: this.rootCount,
      actualRootCount: this.roots.length,
    });
  }

  classNamed(name: string | null | undefined): SpecClass | null {
    if (name == null) {
      return null;
    }
    return this.classes.get(name) || null;
  }

  /**
   * The `major.minor` version string used in the DocSpecs markdown declaration
   * (Dart / Python parity — mirrors Python's `SpecModel.model_version_string`).
   */
  get modelVersionString(): string {
    return somModelVersionString(this.modelVersion, this.modelVersionLabel);
  }

  /**
   * The document root whose {@link SpecRoot.type} equals `type` (SOM §21).
   *
   * Replaces the recurring `roots.find((r) => r.type === …)` boilerplate.
   * Throws a {@link TypeError} when no root carries that type — with a message
   * that names the missing type and the ones that do exist. A `TypeError` (the
   * argument-error class) marks a caller-supplied bad `type`, distinct from the
   * plain {@link Error} {@link SpecDocument.toMarkdown} throws for an ambiguous
   * document *state* (CS12-D3 split).
   */
  rootByType(type: string): SpecRoot {
    for (const r of this.roots) {
      if (r.type === type) {
        return r;
      }
    }
    throw new TypeError(
      `no document root with type '${type}' (have: ` +
        `${this.roots.map((r) => r.type).join(', ')})`,
    );
  }

  static fromJson(j: any): SpecModel {
    const classes = new Map<string, SpecClass>();
    for (const [name, value] of Object.entries(j.classes)) {
      classes.set(name, SpecClass.fromJson(value));
    }
    const roots = j.roots.map((e: any) => SpecRoot.fromJson(e));
    const label = j.modelVersionLabel;
    const container = j.containerRoot;
    return new SpecModel({
      roots,
      classes,
      modelVersion: parseInt(j.modelVersion || 0, 10) || 0,
      modelVersionLabel: label ? label : null,
      generatedAt: parseStampTimestamp(j.generatedAt),
      metaSchemaVersion: optionalInt(j.metaSchemaVersion),
      classCount: optionalInt(j.classCount),
      rootCount: optionalInt(j.rootCount),
      containerRoot: container ? container : null,
    });
  }
}

/**
 * Derives the `major.minor` DocSpecs version string from a model's integer
 * version and its optional free-form label (port of Python's
 * `som_model_version_string`).
 *
 * When the label's `+`-stripped core has at least two dot-separated integer
 * components, those become `major.minor`; otherwise the result is
 * `<major>.0`.
 */
export function somModelVersionString(
  major: number,
  label: string | null,
): string {
  if (label) {
    const core = label.split('+')[0].trim();
    const parts = core.split('.');
    if (parts.length >= 2) {
      const maj = parts[0].trim();
      const minor = parts[1].trim();
      if (/^[+-]?[0-9]+$/.test(maj) && /^[+-]?[0-9]+$/.test(minor)) {
        return `${parseInt(maj, 10)}.${parseInt(minor, 10)}`;
      }
    }
  }
  return `${major}.0`;
}
