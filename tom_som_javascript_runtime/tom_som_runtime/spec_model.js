'use strict';

/**
 * In-memory representation of the exported TomSpecs class graph (the spec-model
 * meta-data file) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_model.dart` (and `spec_model.py`).
 *
 * The model is a *class graph*, not an expanded tree: each class appears once and
 * field `elementType` / `type` references are followed on demand by a traversal.
 * This is the "reflection" surface — it describes any document's structure,
 * independent of the values a concrete document holds.
 */

/** The render kind of a field, mirroring the exporter's classification. */
const SpecFieldKind = Object.freeze({
  LIST: 'list',
  FORM: 'form',
  SECTION: 'section',
  CONTENT: 'content',
  ENUM: 'enum',
  COMPLEX: 'complex',
  SCALAR: 'scalar',
});

const _FIELD_KIND_VALUES = new Set(Object.values(SpecFieldKind));

/** Parses a raw kind string, falling back to `scalar`. */
function parseFieldKind(raw) {
  return _FIELD_KIND_VALUES.has(raw) ? raw : SpecFieldKind.SCALAR;
}

/**
 * A single annotation captured losslessly from the model source (spec §3.1): its
 * name and the resolved argument map.
 */
class SpecAnnotation {
  constructor(name, args) {
    this.name = name;
    this.arguments = args || {};
  }

  argument(key) {
    return this.arguments[key];
  }

  static fromJson(j) {
    return new SpecAnnotation(j.name, { ...(j.arguments || {}) });
  }

  static listFromJson(raw) {
    if (!Array.isArray(raw)) {
      return [];
    }
    return raw.map((e) => SpecAnnotation.fromJson(e));
  }
}

/** A single form field within a `@Form` content section. */
class FormFieldSpec {
  constructor({ name, label, type = 'String', hint = null, required = false }) {
    this.name = name;
    this.label = label;
    this.type = type;
    this.hint = hint;
    this.required = required;
  }

  static fromJson(j) {
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
class SpecField {
  constructor(props) {
    this.name = props.name;
    this.kind = props.kind;
    this.doc = props.doc != null ? props.doc : null;
    this.help = props.help != null ? props.help : null;
    this.sectionId = props.sectionId != null ? props.sectionId : null;
    this.sectionIdPattern = props.sectionIdPattern != null ? props.sectionIdPattern : null;
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

  static fromJson(j) {
    return new SpecField({
      name: j.name,
      kind: parseFieldKind(j.kind),
      doc: j.doc,
      help: j.help,
      sectionId: j.sectionId,
      sectionIdPattern: j.sectionIdPattern,
      elementType: j.elementType,
      elementIsComplex: Boolean(j.elementIsComplex || false),
      min: j.min,
      contentType: j.contentType,
      sectionType: j.sectionType,
      enumType: j.enumType,
      enumValues: (j.enumValues || []).map((e) => String(e)),
      type: j.type,
      formFields: (j.formFields || []).map((e) => FormFieldSpec.fromJson(e)),
      annotations: SpecAnnotation.listFromJson(j.annotations),
    });
  }

  /** Whether expanding this field reveals further tree nodes. */
  get isExpandable() {
    return this.kind === SpecFieldKind.LIST || this.kind === SpecFieldKind.COMPLEX;
  }

  annotation(name) {
    return this.annotations.find((a) => a.name === name) || null;
  }
}

/** A model class with its fields. */
class SpecClass {
  constructor(props) {
    this.name = props.name;
    this.sectionId = props.sectionId != null ? props.sectionId : null;
    this.doc = props.doc != null ? props.doc : null;
    this.help = props.help != null ? props.help : null;
    this.mapsTo = props.mapsTo != null ? props.mapsTo : null;
    this.detailedIn = props.detailedIn != null ? props.detailedIn : null;
    this.fields = props.fields || [];
    this.annotations = props.annotations || [];
  }

  static fromJson(j) {
    return new SpecClass({
      name: j.name,
      sectionId: j.sectionId,
      doc: j.doc,
      help: j.help,
      mapsTo: j.mapsTo,
      detailedIn: j.detailedIn,
      fields: j.fields.map((e) => SpecField.fromJson(e)),
      annotations: SpecAnnotation.listFromJson(j.annotations),
    });
  }

  fieldNamed(name) {
    return this.fields.find((f) => f.name === name) || null;
  }

  annotation(name) {
    return this.annotations.find((a) => a.name === name) || null;
  }
}

/** A document root (a class carrying `@Document`). */
class SpecRoot {
  constructor({ type, title, sectionId = null, description = null, doc = null }) {
    this.type = type;
    this.title = title;
    this.sectionId = sectionId;
    this.description = description;
    this.doc = doc;
  }

  static fromJson(j) {
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
class SpecModel {
  constructor({ roots, classes, modelVersion = 0, modelVersionLabel = null }) {
    this.roots = roots;
    /** @type {Map<string, SpecClass>} */
    this.classes = classes;
    this.modelVersion = modelVersion;
    this.modelVersionLabel = modelVersionLabel;
  }

  classNamed(name) {
    if (name == null) {
      return null;
    }
    return this.classes.get(name) || null;
  }

  static fromJson(j) {
    const classes = new Map();
    for (const [name, value] of Object.entries(j.classes)) {
      classes.set(name, SpecClass.fromJson(value));
    }
    const roots = j.roots.map((e) => SpecRoot.fromJson(e));
    const label = j.modelVersionLabel;
    return new SpecModel({
      roots,
      classes,
      modelVersion: parseInt(j.modelVersion || 0, 10) || 0,
      modelVersionLabel: label ? label : null,
    });
  }
}

module.exports = {
  SpecFieldKind,
  parseFieldKind,
  SpecAnnotation,
  FormFieldSpec,
  SpecField,
  SpecClass,
  SpecRoot,
  SpecModel,
};
