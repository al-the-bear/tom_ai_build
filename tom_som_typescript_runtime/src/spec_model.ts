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

  constructor(props: {
    name: string;
    label: string;
    type?: string;
    hint?: string | null;
    required?: boolean;
  }) {
    this.name = props.name;
    this.label = props.label;
    this.type = props.type != null ? props.type : 'String';
    this.hint = props.hint != null ? props.hint : null;
    this.required = Boolean(props.required || false);
  }

  static fromJson(j: any): FormFieldSpec {
    return new FormFieldSpec({
      name: j.name,
      label: j.label || j.name,
      type: j.type || 'String',
      hint: j.hint != null ? j.hint : null,
      required: Boolean(j.required || false),
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

/** The complete exported model. */
export class SpecModel {
  roots: SpecRoot[];
  classes: Map<string, SpecClass>;
  modelVersion: number;
  modelVersionLabel: string | null;

  constructor(props: {
    roots: SpecRoot[];
    classes: Map<string, SpecClass>;
    modelVersion?: number;
    modelVersionLabel?: string | null;
  }) {
    this.roots = props.roots;
    this.classes = props.classes;
    this.modelVersion = props.modelVersion != null ? props.modelVersion : 0;
    this.modelVersionLabel =
      props.modelVersionLabel != null ? props.modelVersionLabel : null;
  }

  classNamed(name: string | null | undefined): SpecClass | null {
    if (name == null) {
      return null;
    }
    return this.classes.get(name) || null;
  }

  /**
   * The `major.minor` version string used in the DocSpecs markdown declaration
   * (DR6/DR11 parity — mirrors Python's `SpecModel.model_version_string`).
   */
  get modelVersionString(): string {
    return somModelVersionString(this.modelVersion, this.modelVersionLabel);
  }

  /**
   * The document root whose {@link SpecRoot.type} equals `type` (§ item 12).
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
    return new SpecModel({
      roots,
      classes,
      modelVersion: parseInt(j.modelVersion || 0, 10) || 0,
      modelVersionLabel: label ? label : null,
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
