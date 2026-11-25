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
 * A single annotation captured losslessly from the model source (som_multiplatform_spec_model.md §5.3): its
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

/**
 * `CodeSpecPart.validation` → `validation`. A name already given bare is
 * returned unchanged, so readers do not depend on how the exporter chose to
 * spell the enum constant. Splitting on the last dot rather than a fixed prefix
 * keeps this working for any code enum the model adds.
 *
 * @param {string} raw
 * @returns {string}
 */
function _stripEnumPrefix(raw) {
  const dot = raw.lastIndexOf('.');
  return dot < 0 ? raw : raw.slice(dot + 1);
}

// ---------------------------------------------------------------------------
// The link vocabulary (`tom_specs_model_rules.md` §9.7)
// ---------------------------------------------------------------------------
//
// Typed readers of the link annotations, read from the lossless `annotations`
// block (member and class annotations) or from the curated `formFields[]` keys
// (the `Field` qualifiers). They follow {@link KindLink}: an enum constant is
// read with its type prefix stripped (`LinkRelation.subset` → `subset`), a key
// the reader does not know is ignored, and an absent key takes the
// annotation's default — so a meta written before a key existed loads
// unchanged.

/** Whether `raw` is a JSON object (not an array, not null). */
function _isObject(raw) {
  return raw != null && typeof raw === 'object' && !Array.isArray(raw);
}

/** A JSON list read as strings; anything else as empty. */
function _stringList(raw) {
  return Array.isArray(raw) ? raw.filter((e) => e != null).map((e) => String(e)) : [];
}

/** A JSON object read with string keys; anything else as empty. */
function _objectMap(raw) {
  return _isObject(raw) ? { ...raw } : {};
}

/** A JSON object read as string → string; anything else as empty. */
function _stringMap(raw) {
  const out = {};
  if (_isObject(raw)) {
    for (const [k, v] of Object.entries(raw)) {
      out[k] = String(v);
    }
  }
  return out;
}

/** An optional string argument: the string, or `null` for anything else. */
function _optString(raw) {
  return typeof raw === 'string' ? raw : null;
}

/** A string argument with a default when absent. */
function _str(raw, fallback) {
  return raw != null ? String(raw) : fallback;
}

/**
 * The relation of the elements of a list on two sides of a link, as the
 * annotated side reads it (`ListRelation`, `tom_specs_model_rules.md` §9.7).
 */
class SpecListRelation {
  constructor({ place, relation, where = null }) {
    /** The list or multi-valued reference field the relation is about.
     * @type {string} */
    this.place = place;
    /** `equal`, `subset` or `superset` (the `LinkRelation` constant name).
     * @type {string} */
    this.relation = relation;
    /** The filter selecting the elements the relation applies to, or `null`
     * for all of them (the {@link SpecPlaceFilter} grammar).
     * @type {?string} */
    this.where = where != null ? where : null;
  }

  /** Reads one `relations[]` entry of a `@SyncedWith`. */
  static fromArguments(a) {
    return new SpecListRelation({
      place: _str(a.place, ''),
      relation: _stripEnumPrefix(_str(a.relation, 'equal')),
      where: _optString(a.where),
    });
  }

  /** The canonical JSON form, keys in declaration order, null left out. */
  toJson() {
    return {
      place: this.place,
      relation: this.relation,
      ...(this.where != null ? { where: this.where } : {}),
    };
  }
}

/**
 * `@SyncedWith(document, {detailOnly, heldHere, relations, note})`: the
 * annotated section is kept in sync with the section of the same id in
 * `document` (`tom_specs_model_rules.md` §9.7).
 */
class SpecSync {
  constructor({ document, detailOnly = [], heldHere = [], relations = [], note = null }) {
    /** The other document's root class name. @type {string} */
    this.document = document;
    /** The places only `document` carries. @type {string[]} */
    this.detailOnly = detailOnly || [];
    /** The places whose value this document holds. @type {string[]} */
    this.heldHere = heldHere || [];
    /** The lists whose relation is not `equal`. @type {SpecListRelation[]} */
    this.relations = relations || [];
    /** The annotation's free-text note. @type {?string} */
    this.note = note != null ? note : null;
  }

  /** Reads the sync out of `annotation`. */
  static fromAnnotation(annotation) {
    const a = annotation.arguments;
    const relations = Array.isArray(a.relations) ? a.relations : [];
    return new SpecSync({
      document: _str(a.document, ''),
      detailOnly: _stringList(a.detailOnly),
      heldHere: _stringList(a.heldHere),
      relations: relations
        .filter((r) => _isObject(r))
        .map((r) => SpecListRelation.fromArguments(_objectMap(r))),
      note: _optString(a.note),
    });
  }

  /** The canonical JSON form, keys in declaration order, null left out. */
  toJson() {
    return {
      document: this.document,
      detailOnly: this.detailOnly,
      heldHere: this.heldHere,
      relations: this.relations.map((r) => r.toJson()),
      ...(this.note != null ? { note: this.note } : {}),
    };
  }
}

/**
 * `@SummaryOf` on a member, or the `summaryOf:` qualifier of a form field: the
 * annotated list or reference field summarises a detailed list
 * (`tom_specs_model_rules.md` §9.7).
 */
class SpecSummaryOf {
  constructor({ detail, document = null, match = null, relation = 'subset', repeats = {}, note = null }) {
    /** The detailed list, `<LIST-ID>` (a `/` path where needed). @type {string} */
    this.detail = detail;
    /** The root class name of the document holding `detail`; `null`: this one.
     * @type {?string} */
    this.document = document != null ? document : null;
    /** The summary element's field naming its detail element; `null`: the
     * summary element carries the detail element's own section id.
     * @type {?string} */
    this.match = match != null ? match : null;
    /** `equal`, `subset` (the default) or `superset`. @type {string} */
    this.relation = relation != null ? relation : 'subset';
    /** Summary place → detail place for every value the summary repeats.
     * @type {Object<string, string>} */
    this.repeats = repeats || {};
    /** The annotation's free-text note. @type {?string} */
    this.note = note != null ? note : null;
  }

  /** Reads the arguments of a `SummaryOf` (annotation or qualifier). */
  static fromArguments(a) {
    return new SpecSummaryOf({
      detail: _str(a.detail, ''),
      document: _optString(a.document),
      match: _optString(a.match),
      relation: _stripEnumPrefix(_str(a.relation, 'subset')),
      repeats: _stringMap(a.repeats),
      note: _optString(a.note),
    });
  }

  /** The canonical JSON form, keys in declaration order, null left out. */
  toJson() {
    return {
      detail: this.detail,
      ...(this.document != null ? { document: this.document } : {}),
      ...(this.match != null ? { match: this.match } : {}),
      relation: this.relation,
      repeats: this.repeats,
      ...(this.note != null ? { note: this.note } : {}),
    };
  }
}

/**
 * `@DerivedFrom` on a member, or the `derivedFrom:` qualifier of a form field:
 * the value is derived from other places (`tom_specs_model_rules.md` §9.7).
 */
class SpecDerivation {
  constructor({ kind, source, where = null, take = [], key = null, by = null, map = {}, note = null }) {
    /** `copy`, `rows` or `lookup` (the `DerivationKind` constant name). @type {string} */
    this.kind = kind;
    /** copy: the place copied; rows / lookup: the rows read. @type {string} */
    this.source = source;
    /** rows: which rows count (the {@link SpecPlaceFilter} grammar). @type {?string} */
    this.where = where != null ? where : null;
    /** rows / lookup: the row places collected. @type {string[]} */
    this.take = take || [];
    /** rows / lookup: the row field compared with this element's `by`. @type {?string} */
    this.key = key != null ? key : null;
    /** rows / lookup: this element's field holding the key. @type {?string} */
    this.by = by != null ? by : null;
    /** For a list member: target element place ← row place. @type {Object<string, string>} */
    this.map = map || {};
    /** The annotation's free-text note. @type {?string} */
    this.note = note != null ? note : null;
  }

  /** Reads the arguments of a `DerivedFrom` (annotation or qualifier). */
  static fromArguments(a) {
    return new SpecDerivation({
      kind: _stripEnumPrefix(_str(a.kind, 'copy')),
      source: _str(a.source, ''),
      where: _optString(a.where),
      take: _stringList(a.take),
      key: _optString(a.key),
      by: _optString(a.by),
      map: _stringMap(a.map),
      note: _optString(a.note),
    });
  }

  /** The canonical JSON form, keys in declaration order, null left out. */
  toJson() {
    return {
      kind: this.kind,
      source: this.source,
      ...(this.where != null ? { where: this.where } : {}),
      take: this.take,
      ...(this.key != null ? { key: this.key } : {}),
      ...(this.by != null ? { by: this.by } : {}),
      map: this.map,
      ...(this.note != null ? { note: this.note } : {}),
    };
  }
}

/**
 * The `inverseOf:` qualifier of a reference form field: the other ends of the
 * link (`tom_specs_model_rules.md` §9.7).
 */
class SpecInverseOf {
  constructor({ fields = [], where = null } = {}) {
    /** The other ends, `<FORMSECTIONID>.<field>`; `['@self']` for the
     * symmetric form. @type {string[]} */
    this.fields = fields || [];
    /** Only values (or rows) matching this filter have an inverse. @type {?string} */
    this.where = where != null ? where : null;
  }

  /** Reads the `inverseOf` key of a `formFields[]` entry. */
  static fromArguments(a) {
    return new SpecInverseOf({
      fields: _stringList(a.fields),
      where: _optString(a.where),
    });
  }

  /** Whether the link is stored on both entries in the same field
   * (`InverseOf.symmetric`). */
  get symmetric() {
    return this.fields.length === 1 && this.fields[0] === '@self';
  }

  /** The canonical JSON form, null left out. */
  toJson() {
    return {
      fields: this.fields,
      ...(this.where != null ? { where: this.where } : {}),
    };
  }
}

/**
 * `@ExtractsLinks` on a list of link rows: ids named in text get rows
 * (`tom_specs_model_rules.md` §9.7). A member may carry it more than once.
 */
class SpecExtractsLinks {
  constructor({ from = [], ref, set = {}, mode = 'generate', note = null }) {
    /** The text places searched for ids. @type {string[]} */
    this.from = from || [];
    /** The row's `refersTo` field receiving a found id. @type {string} */
    this.ref = ref;
    /** The values every generated row gets. @type {Object<string, string>} */
    this.set = set || {};
    /** `generate` (the default) or `warn` (the `ExtractMode` constant name). @type {string} */
    this.mode = mode != null ? mode : 'generate';
    /** The annotation's free-text note. @type {?string} */
    this.note = note != null ? note : null;
  }

  /** Reads one `ExtractsLinks` annotation. */
  static fromAnnotation(annotation) {
    const a = annotation.arguments;
    return new SpecExtractsLinks({
      from: _stringList(a.from),
      ref: _str(a.ref, ''),
      set: _stringMap(a.set),
      mode: _stripEnumPrefix(_str(a.mode, 'generate')),
      note: _optString(a.note),
    });
  }

  /** The canonical JSON form, keys in declaration order, null left out. */
  toJson() {
    return {
      from: this.from,
      ref: this.ref,
      set: this.set,
      mode: this.mode,
      ...(this.note != null ? { note: this.note } : {}),
    };
  }
}

/**
 * `@SameAs({holder, note})` on a section member: the member holds a copy of
 * the section the same document holds at another position, the holder
 * (`tom_specs_model_rules.md` §9.7). `specSameAsBindings` finds the holder per
 * document.
 */
class SpecSameAs {
  constructor({ holder = null, note = null } = {}) {
    /** The holder's section-id path, its last ids as far as needed
     * (`ACPLN/ACRITL`); `null`: the one other position of the class.
     * @type {?string} */
    this.holder = holder != null ? holder : null;
    /** The annotation's free-text note. @type {?string} */
    this.note = note != null ? note : null;
  }

  /** Reads the copy out of `annotation`. */
  static fromAnnotation(annotation) {
    return new SpecSameAs({
      holder: _optString(annotation.argument('holder')),
      note: _optString(annotation.argument('note')),
    });
  }

  /** The canonical JSON form, null left out. */
  toJson() {
    return {
      ...(this.holder != null ? { holder: this.holder } : {}),
      ...(this.note != null ? { note: this.note } : {}),
    };
  }
}

/** The `@SyncedWith` sync carried by `annotations`, or `null`. */
function _syncOf(annotations) {
  const a = annotations.find((x) => x.name === 'SyncedWith');
  return a === undefined ? null : SpecSync.fromAnnotation(a);
}

/** The `@SummaryOf` link carried by `annotations`, or `null`. */
function _summaryOfOf(annotations) {
  const a = annotations.find((x) => x.name === 'SummaryOf');
  return a === undefined ? null : SpecSummaryOf.fromArguments(a.arguments);
}

/** The `@DerivedFrom` derivation carried by `annotations`, or `null`. */
function _derivedFromOf(annotations) {
  const a = annotations.find((x) => x.name === 'DerivedFrom');
  return a === undefined ? null : SpecDerivation.fromArguments(a.arguments);
}

/** Every `@ExtractsLinks` carried by `annotations`, in source order. */
function _extractsLinksOf(annotations) {
  return annotations
    .filter((x) => x.name === 'ExtractsLinks')
    .map((a) => SpecExtractsLinks.fromAnnotation(a));
}

/** The `@SameAs` copy carried by `annotations`, or `null`. */
function _sameAsOf(annotations) {
  const a = annotations.find((x) => x.name === 'SameAs');
  return a === undefined ? null : SpecSameAs.fromAnnotation(a);
}

/**
 * A list-valued taxonomy annotation: a set of enum codes plus an optional
 * explanatory note.
 *
 * The model states where a subtree is headed with two such annotations, which
 * share this shape exactly — `@CodeSpecKind(List<CodeSpecPart>, {note})` names
 * the CodeSpecs part(s) a section type must be realised as
 * (`codespecs_mapping.md` §9.1/§9.5), and
 * `@FollowUpKind(List<FollowUpProcess>, {note})` names the downstream
 * *process(es)* a non-code subtree feeds (`codespecs_mapping.md` §8.3). One
 * reader serves both; which annotation a link came from is expressed by which
 * accessor produced it.
 *
 * Obtaining a link at all means the annotation is present. That matters: a node
 * with no link has not been classified yet, whereas a link with empty
 * {@link KindLink#kinds} is a recorded decision that the section belongs to no
 * member of that taxonomy. The two are different statements, so they are
 * different values rather than one nullable list.
 */
class KindLink {
  constructor({ kinds = [], note = null } = {}) {
    /**
     * The enum code names with their type prefix stripped — `validation`, not
     * `CodeSpecPart.validation`; `doc`, not `FollowUpProcess.doc`.
     *
     * Both annotations are list-valued because one section can be realised as
     * several parts, or feed several processes; consumers must handle all of
     * them, not just the first.
     * @type {string[]}
     */
    this.kinds = kinds;
    /** The annotation's free-text `note`, explaining the classification.
     * @type {?string} */
    this.note = note;
  }

  /**
   * Reads a link out of `annotation`, taking the code list from the argument
   * named `listArgument` — `kinds` for `@CodeSpecKind`, `processes` for
   * `@FollowUpKind`.
   *
   * @param {SpecAnnotation} annotation
   * @param {{listArgument: string}} options
   * @returns {KindLink}
   */
  static fromAnnotation(annotation, { listArgument }) {
    const raw = annotation.argument(listArgument);
    return new KindLink({
      kinds: Array.isArray(raw)
        ? raw.filter((k) => k != null).map((k) => _stripEnumPrefix(String(k)))
        : [],
      note: annotation.argument('note') != null ? annotation.argument('note') : null,
    });
  }
}

/**
 * The third routing verdict: `@NoArtifact(NoArtifactReason, {note})` — the
 * section feeds neither a CodeSpecs part nor a follow-up process
 * (`codespecs_mapping.md` §8.3).
 *
 * Single-valued where {@link KindLink} is a list, and the asymmetry is the
 * point: a section can feed several parts or several processes at once, but it
 * is unrouted for exactly one reason. That reason is what makes the absence of
 * the other two markers readable as a decision rather than an omission, which is
 * what `tom_specs_model_rules.md` §10.2 invariant `ROUTE-TOTAL` checks.
 */
class NoArtifactLink {
  constructor({ reason, note = null }) {
    /**
     * The `NoArtifactReason` code name with its type prefix stripped —
     * `container`, not `NoArtifactReason.container`. One of `container`,
     * `overview`, `view`.
     * @type {string}
     */
    this.reason = reason;
    /** The annotation's free-text `note`. On an `overview` this customarily
     * names the routed section that states the material normatively.
     * @type {?string} */
    this.note = note;
  }

  /**
   * Reads the verdict out of `annotation`.
   *
   * @param {SpecAnnotation} annotation
   * @returns {NoArtifactLink}
   */
  static fromAnnotation(annotation) {
    const reason = annotation.argument('reason');
    return new NoArtifactLink({
      reason: _stripEnumPrefix(reason != null ? String(reason) : 'container'),
      note: annotation.argument('note') != null ? annotation.argument('note') : null,
    });
  }
}

/**
 * Shared behaviour of the two model nodes that carry annotations — classes and
 * fields. Dart states it as a mixin; JavaScript has no mixin keyword, so the
 * members are declared once here and installed on both prototypes with
 * {@link Object.defineProperties}. Either way the annotation lookups are
 * defined once instead of per node type.
 *
 * Descriptors rather than an object literal so the getters survive the copy and
 * stay non-enumerable — an instance must serialise as its own data, not as its
 * derived views.
 */
const _ANNOTATED_SPEC_NODE = {
  /**
   * Whether the annotation named `name` is present. For markers that carry no
   * arguments, presence *is* the whole statement.
   */
  hasAnnotation: {
    value: function hasAnnotation(name) {
      return this.annotation(name) !== null;
    },
  },

  /** The `@CodeSpecKind` link, or `null` when this node carries no such
   * annotation. See {@link KindLink} for why absent and empty differ. */
  codeSpecKind: {
    get: function codeSpecKind() {
      return _kindLink(this, 'CodeSpecKind', 'kinds');
    },
  },

  /** The `@FollowUpKind` link, or `null` when this node carries no such
   * annotation — which downstream process(es) this subtree feeds instead of
   * becoming CodeSpecs code (`codespecs_mapping.md` §8.3). */
  followUpKind: {
    get: function followUpKind() {
      return _kindLink(this, 'FollowUpKind', 'processes');
    },
  },

  /** The `@NoArtifact` verdict, or `null` when this node carries no such
   * annotation — the recorded decision that the section produces nothing
   * downstream (`codespecs_mapping.md` §8.3). */
  noArtifact: {
    get: function noArtifact() {
      const a = this.annotation('NoArtifact');
      return a === null ? null : NoArtifactLink.fromAnnotation(a);
    },
  },

  /** Every annotation named `name`, in source order. Distinct from
   * `annotation` because some annotations are repeatable. */
  annotationsNamed: {
    value: function annotationsNamed(name) {
      return this.annotations.filter((a) => a.name === name);
    },
  },

  /** The `@SyncedWith` sync, or `null` when this node carries none — a
   * `@DetailedIn` without one is "not declared yet", not "nothing shared". */
  syncedWith: {
    get: function syncedWith() {
      return _syncOf(this.annotations);
    },
  },

  /** The `@SummaryOf` link of this member, or `null` when it carries none. */
  summaryOf: {
    get: function summaryOf() {
      return _summaryOfOf(this.annotations);
    },
  },

  /** The `@DerivedFrom` derivation of this member, or `null` when it carries
   * none. */
  derivedFrom: {
    get: function derivedFrom() {
      return _derivedFromOf(this.annotations);
    },
  },

  /** Every `@ExtractsLinks` of this member, in source order; empty when it
   * carries none. */
  extractsLinks: {
    get: function extractsLinks() {
      return _extractsLinksOf(this.annotations);
    },
  },

  /** The `@SameAs` copy of this member, or `null` when it carries none. */
  sameAs: {
    get: function sameAs() {
      return _sameAsOf(this.annotations);
    },
  },
};

/**
 * The `@CodeSpecKind` / `@FollowUpKind` reader both accessors share. Both
 * annotations ride the generic annotation bag (SOM §5.3) rather than a
 * dedicated meta slot, so they are looked up by name; only the name of their
 * list argument differs.
 *
 * @param {SpecField|SpecClass} node
 * @param {string} name
 * @param {string} listArgument
 * @returns {?KindLink}
 */
function _kindLink(node, name, listArgument) {
  const a = node.annotation(name);
  return a === null ? null : KindLink.fromAnnotation(a, { listArgument });
}

/** A single form field within a `@Form` content section. */
class FormFieldSpec {
  constructor({
    name,
    label,
    type = 'String',
    hint = null,
    required = false,
    enumValues = [],
    refersTo = [],
    countOf = [],
    productOf = [],
    rankOf = null,
    code = false,
    multiParagraph = false,
    multiple = false,
    derivedFrom = null,
    inverseOf = null,
    summaryOf = null,
  }) {
    this.name = name;
    this.label = label;
    this.type = type;
    this.hint = hint;
    this.required = required;
    /**
     * Enum constant names when {@link type} is a model enum; empty for non-enum
     * field types. Lets consumers validate and convert values without the
     * analyzer.
     * @type {string[]}
     */
    this.enumValues = enumValues;
    /**
     * The registry key(s) this field's value is an id drawn from, each written
     * `<SECTIONID>.<formFieldName>`; empty for a non-reference field. A
     * reference field holds a free-text id that must already be declared by
     * some entry of the named registry, so a runtime can resolve it and report
     * a dangling id instead of generating broken code.
     * @type {string[]}
     */
    this.refersTo = refersTo;
    /**
     * The entries this field's value counts (`Field.countOf`, vsctsa43), each
     * `<SECTIONID>` or `<SECTIONID>.<formField>=<value>`; empty for a field
     * that states no count. The instance tier holds the stated number to the
     * document (`countMismatch`).
     * @type {string[]}
     */
    this.countOf = countOf;
    /**
     * The operands this field's value is the product of (`Field.productOf`,
     * uamtc10), each a form field of the same form or
     * `<FORMSECTIONID>.<field>` of a sibling form; empty for a field that
     * states no product. The instance tier holds the stated number to it
     * (`derivedValueMismatch`).
     * @type {string[]}
     */
    this.productOf = productOf;
    /**
     * The form field of the same form this field's value ranks by, highest
     * first (`Field.rankOf`, uamtc10); `null` for a field that states no rank.
     * @type {string|null}
     */
    this.rankOf = rankOf;
    /**
     * Whether the value is code rather than prose (`Field.code`): the markdown
     * codec writes it as an inline code span and unwraps it on import (SOM
     * §11.4 rule 8). Omitted from the export when `false`.
     * @type {boolean}
     */
    this.code = code;
    /**
     * Whether the field's values hold paragraphs or blocks
     * (`Field.multiParagraph`): the markdown renderer writes them as a `Field:`
     * paragraph, never as a row of the form table (SOM §11.4).
     */
    this.multiParagraph = multiParagraph;
    /**
     * Whether a reference field holds several ids, comma-separated
     * (`Field.multiple`, uamtc17); a reference field without it holds one, and
     * the instance tier reports a list in it (`multipleReferences`).
     * @type {boolean}
     */
    this.multiple = multiple;
    /**
     * The derivation this field's value follows (`Field.derivedFrom`,
     * `tom_specs_model_rules.md` §9.7), or `null` when it states none.
     * @type {?SpecDerivation}
     */
    this.derivedFrom = derivedFrom != null ? derivedFrom : null;
    /**
     * The other ends of the link this reference field is one end of
     * (`Field.inverseOf`), or `null` when it states none.
     * @type {?SpecInverseOf}
     */
    this.inverseOf = inverseOf != null ? inverseOf : null;
    /**
     * The detailed list this multi-valued reference field summarises
     * (`Field.summaryOf`), or `null` when it states none.
     * @type {?SpecSummaryOf}
     */
    this.summaryOf = summaryOf != null ? summaryOf : null;
  }

  static fromJson(j) {
    return new FormFieldSpec({
      name: j.name,
      label: j.label || j.name,
      type: j.type || 'String',
      hint: j.hint != null ? j.hint : null,
      required: Boolean(j.required || false),
      enumValues: (j.enumValues || []).map(String),
      refersTo: (j.refersTo || []).map(String),
      countOf: (j.countOf || []).map(String),
      productOf: (j.productOf || []).map(String),
      rankOf: typeof j.rankOf === 'string' ? j.rankOf : null,
      code: j.code === true,
      multiParagraph: j.multiParagraph === true,
      multiple: j.multiple === true,
      derivedFrom: _isObject(j.derivedFrom)
        ? SpecDerivation.fromArguments(_objectMap(j.derivedFrom))
        : null,
      inverseOf: _isObject(j.inverseOf)
        ? SpecInverseOf.fromArguments(_objectMap(j.inverseOf))
        : null,
      summaryOf: _isObject(j.summaryOf)
        ? SpecSummaryOf.fromArguments(_objectMap(j.summaryOf))
        : null,
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
    // The `@Headline(text)` default headline (YRD4), or `null`. Render
    // precedence: stored headline > this default > name derivation.
    this.headline = props.headline != null ? props.headline : null;
    this.sectionId = props.sectionId != null ? props.sectionId : null;
    this.sectionIdPattern = props.sectionIdPattern != null ? props.sectionIdPattern : null;
    this.serializationOrder = props.serializationOrder != null ? props.serializationOrder : null;
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
      headline: j.headline,
      sectionId: j.sectionId,
      sectionIdPattern: j.sectionIdPattern,
      serializationOrder: j.serializationOrder != null ? parseInt(j.serializationOrder, 10) : null,
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
    // The class-level `@Headline(text)` default headline (YRD4), or `null`.
    // A field-level `@Headline` on the instantiating field wins over this.
    this.headline = props.headline != null ? props.headline : null;
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
      headline: j.headline,
      mapsTo: j.mapsTo,
      detailedIn: j.detailedIn,
      fields: j.fields.map((e) => SpecField.fromJson(e)),
      annotations: SpecAnnotation.listFromJson(j.annotations),
    });
  }

  fieldNamed(name) {
    return this.fields.find((f) => f.name === name) || null;
  }

  /** Whether this class is the CodeSpecs projection root (`@CodeSpecsProjection`). */
  get isCodeSpecsProjection() {
    return this.hasAnnotation('CodeSpecsProjection');
  }

  annotation(name) {
    return this.annotations.find((a) => a.name === name) || null;
  }
}

// The two annotation-carrying node types share one reader — see
// `_ANNOTATED_SPEC_NODE`.
Object.defineProperties(SpecField.prototype, _ANNOTATED_SPEC_NODE);
Object.defineProperties(SpecClass.prototype, _ANNOTATED_SPEC_NODE);

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

/** One day in milliseconds — the unit thresholds and ages are reported in. */
const MILLIS_PER_DAY = 86400000;

/**
 * How old a snapshot may get before {@link SpecModel#checkStamp} calls it aged.
 *
 * A fortnight: long enough that a healthy working copy is never nagged, short
 * enough that structural feedback keyed to a snapshot's paths is not recorded
 * against a model that has moved past them.
 */
const DEFAULT_MAX_SNAPSHOT_AGE_MS = 14 * MILLIS_PER_DAY;

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
 *
 * @param {number} year
 * @param {number} month
 * @returns {number}
 */
function daysInMonth(year, month) {
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
 *
 * @param {?string} raw
 * @returns {?Date}
 */
function parseStampTimestamp(raw) {
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
 *
 * @param {*} raw
 * @returns {?number}
 */
function optionalInt(raw) {
  if (typeof raw !== 'number' || !Number.isFinite(raw)) return null;
  return Math.trunc(raw);
}

/**
 * The outcome of checking a loaded snapshot's generation stamp against its own
 * payload and against the clock — see {@link SpecModel#checkStamp}.
 *
 * The two findings are independent and can both hold at once: `isAged` says the
 * snapshot is probably behind the live model, while `countsDisagree` says the
 * file no longer describes itself correctly. Only the second is a defect in the
 * file.
 */
class SpecModelStampCheck {
  constructor({
    ageMs,
    maxAgeMs,
    declaredClassCount,
    actualClassCount,
    declaredRootCount,
    actualRootCount,
  }) {
    /** How long ago the snapshot was generated, or null when it carries no
     * `generatedAt` (an older export, or a hand-built model). */
    this.ageMs = ageMs;
    /** The threshold `ageMs` was judged against. */
    this.maxAgeMs = maxAgeMs;
    this.declaredClassCount = declaredClassCount;
    this.actualClassCount = actualClassCount;
    this.declaredRootCount = declaredRootCount;
    this.actualRootCount = actualRootCount;
  }

  /** Whether the snapshot is older than `maxAgeMs`. Always false when it
   * carries no `generatedAt` — an unknown age is not evidence of a stale one. */
  get isAged() {
    return this.ageMs != null && this.ageMs > this.maxAgeMs;
  }

  /**
   * Whether the declared and actual class counts differ.
   *
   * An absent declaration is not a disagreement: older snapshots predate the
   * stamp keys, and reading absent as `0` would make every one of them look
   * corrupt.
   */
  get classCountDisagrees() {
    return (
      this.declaredClassCount != null &&
      this.declaredClassCount !== this.actualClassCount
    );
  }

  /** Whether the declared and actual root counts differ. Absent declarations
   * are ignored, as for {@link SpecModelStampCheck#classCountDisagrees}. */
  get rootCountDisagrees() {
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
  get countsDisagree() {
    return this.classCountDisagrees || this.rootCountDisagrees;
  }

  /** Whether anything at all was found. */
  get isStale() {
    return this.isAged || this.countsDisagree;
  }

  /** The findings as ready-to-display sentences, empty when there are none.
   * The wording is identical in all nine runtimes.
   * @returns {string[]} */
  get warnings() {
    const out = [];
    if (this.isAged) {
      const days = Math.trunc(this.ageMs / MILLIS_PER_DAY);
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
class SpecModel {
  constructor({
    roots,
    classes,
    modelVersion = 0,
    modelVersionLabel = null,
    generatedAt = null,
    metaSchemaVersion = null,
    classCount = null,
    rootCount = null,
    containerRoot = null,
  }) {
    this.roots = roots;
    /** @type {Map<string, SpecClass>} */
    this.classes = classes;
    this.modelVersion = modelVersion;
    this.modelVersionLabel = modelVersionLabel;
    /** When the snapshot was exported (UTC), or null when it carries no
     * `generatedAt` — an export predating the key, or a hand-built model.
     * @type {?Date} */
    this.generatedAt = generatedAt;
    /** The *file format's* own version, distinct from `modelVersion` (which
     * model the snapshot describes). Null when undeclared. @type {?number} */
    this.metaSchemaVersion = metaSchemaVersion;
    /** The class count the snapshot declares, or null when undeclared. Kept
     * separate from `classes.size`: the declared value is what the exporter
     * recorded, the actual value is what survived to the reader, and comparing
     * them is the point ({@link SpecModel#checkStamp}). @type {?number} */
    this.classCount = classCount;
    /** The document-root count the snapshot declares, or null. @type {?number} */
    this.rootCount = rootCount;
    /** The canonical container class — the single true tree root, which is not
     * itself a document and so does not appear in `roots`. Null when the model
     * has no container (e.g. a synthetic export). @type {?string} */
    this.containerRoot = containerRoot;
  }

  /**
   * Checks the generation stamp against the payload and the clock.
   *
   * `now` is injectable so callers (and tests) can evaluate age against a fixed
   * instant instead of the wall clock.
   *
   * @param {{maxAgeMs?: number, now?: ?Date}} [options]
   * @returns {SpecModelStampCheck}
   */
  checkStamp({ maxAgeMs = DEFAULT_MAX_SNAPSHOT_AGE_MS, now = null } = {}) {
    const moment = now == null ? new Date() : now;
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

  classNamed(name) {
    if (name == null) {
      return null;
    }
    return this.classes.get(name) || null;
  }

  /**
   * The `major.minor` version string used in the DocSpecs markdown declaration
   * (Dart / Python parity — mirrors Python's `SpecModel.model_version_string`).
   */
  get modelVersionString() {
    return somModelVersionString(this.modelVersion, this.modelVersionLabel);
  }

  /**
   * Whether `root` is a generation input rather than a document an author
   * fills (the Dart `isGenerationInput`).
   *
   * A generation input is an `@Document` root whose audience is a generator,
   * not a spec author: it projects existing Solution Blueprint sections into
   * the shape a downstream phase consumes.
   *
   * Derived from the class's `@CodeSpecsProjection()` marker, so the
   * classification stays single-sourced in the model — a consumer that
   * hard-coded the root's type name would silently misclassify the next
   * projection to be added. A root whose class is absent from
   * {@link SpecModel#classes} is *not* a generation input: an unknown class is
   * not evidence.
   *
   * @param {SpecRoot} root
   * @returns {boolean}
   */
  isGenerationInput(root) {
    const cls = this.classNamed(root.type);
    return cls !== null && cls.hasAnnotation('CodeSpecsProjection');
  }

  /**
   * The document root whose {@link SpecRoot.type} equals `type` (SOM §21).
   *
   * Replaces the recurring `roots.find((r) => r.type === …)` boilerplate.
   * Throws a {@link TypeError} when no root carries that type — with a message
   * that names the missing type and the ones that do exist. A `TypeError` (the
   * argument-error class) marks a caller-supplied bad `type`, distinct from the
   * plain {@link Error} {@link SpecDocument#toMarkdown} throws for an ambiguous
   * document *state* (CS12-D3 split).
   *
   * @param {string} type
   * @returns {SpecRoot}
   */
  rootByType(type) {
    for (const r of this.roots) {
      if (r.type === type) {
        return r;
      }
    }
    const have = this.roots.map((r) => r.type).join(', ');
    throw new TypeError(
      `no document root with type '${type}' (have: ${have})`,
    );
  }

  static fromJson(j) {
    const classes = new Map();
    for (const [name, value] of Object.entries(j.classes)) {
      classes.set(name, SpecClass.fromJson(value));
    }
    const roots = j.roots.map((e) => SpecRoot.fromJson(e));
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
 *
 * @param {number} major
 * @param {?string} label
 * @returns {string}
 */
function somModelVersionString(major, label) {
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

module.exports = {
  MILLIS_PER_DAY,
  SpecFieldKind,
  parseFieldKind,
  SpecAnnotation,
  KindLink,
  NoArtifactLink,
  SpecListRelation,
  SpecSync,
  SpecSummaryOf,
  SpecDerivation,
  SpecInverseOf,
  SpecExtractsLinks,
  SpecSameAs,
  FormFieldSpec,
  SpecField,
  SpecClass,
  SpecRoot,
  SpecModel,
  SpecModelStampCheck,
  DEFAULT_MAX_SNAPSHOT_AGE_MS,
  parseStampTimestamp,
  somModelVersionString,
};
