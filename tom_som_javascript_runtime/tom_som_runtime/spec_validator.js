'use strict';

/**
 * Validates a concrete {@link SpecDocument}'s values against a {@link SpecModel}
 * via the {@link SpecReflection} resolver — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_validator.dart` (and `spec_validator.py`).
 *
 * The check is over the values a document *holds*: every set path must resolve to
 * a node of a compatible kind, every form sub-key must name a real form field,
 * and every populated list must meet its `@Min` item count. Schema completeness
 * (mandatory-but-absent nodes) is a separate concern and is not reported here.
 */

const { SpecFieldKind } = require('./spec_model');
const { SpecNodeKind, SpecReflection } = require('./spec_reflection');
const { K_SECTION_ID_SLOT, effectiveListItemSectionId } = require('./spec_section_id');
const { somScalarBase, somTypedTextReadable } = require('./spec_typed_values');

/** Why a single value in a document is invalid against the model. */
const SpecValidationCode = Object.freeze({
  DANGLING_PATH: 'danglingPath',
  KIND_MISMATCH: 'kindMismatch',
  UNKNOWN_FORM_FIELD: 'unknownFormField',
  MIN_ITEMS: 'minItems',
  /**
   * A `@OneOf` container carries a case-bound subsection that the chosen
   * discriminator value does not select, or more than one subsection for the
   * chosen case (`codespecs_mapping.md` §8.2).
   */
  ONE_OF_CASE_MISMATCH: 'oneOfCaseMismatch',
  /**
   * A reference form field (`FormFieldSpec.refersTo`) holds an id that no entry
   * of any of its target registries declares.
   */
  DANGLING_REFERENCE: 'danglingReference',
  /**
   * A form field whose model type is an enum holds a token the enum does not
   * declare. The typed read is forgiving (an unknown token answers null), and a
   * document is loaded far more often than it is written through a setter, so
   * without this the value is simply dropped. An **empty** value is absence,
   * not a bad value, and is not reported.
   */
  ENUM_VALUE_UNKNOWN: 'enumValueUnknown',
  /**
   * A form field that states a count (`Field.countOf`) holds a number that is
   * not the number of entries the document holds, or no whole number at all
   * (vsctsa43). A total kept by hand drifts from the list it describes the
   * first time the list changes and the total does not.
   */
  COUNT_MISMATCH: 'countMismatch',
  /**
   * A typed field (`int`, `double`, `num` or `bool`) — a form field or a scalar
   * leaf — holds text its type cannot read (`lots` in an `int`). The typed read
   * refuses such text and the setters refuse to store it, but a document edited
   * by hand or by another tool can still carry it; this is where it is
   * reported. Empty text is absence, not a bad value, and is not reported.
   */
  VALUE_TYPE_MISMATCH: 'valueTypeMismatch',
  /**
   * A form field whose value is derived from other fields — a product
   * (`Field.productOf`) or a rank by a sibling field (`Field.rankOf`) — holds
   * a value the fields it is derived from do not give, or no number at all
   * (uamtc10). A risk score kept by hand drifts the first time probability or
   * impact changes and the score does not.
   */
  DERIVED_VALUE_MISMATCH: 'derivedValueMismatch',
  /**
   * A form the document holds leaves a `required` field empty (uamtc16).
   *
   * Checked for every form instance that holds at least one field value — a
   * class-level form, a form declared on a section member, in a list item or
   * not — so an absent form is absence, not an incomplete one. The schema
   * tier checks class-level forms of the rendition only; this is the check
   * that reaches every form.
   */
  MISSING_REQUIRED_FIELD: 'missingRequiredField',
  /**
   * A reference field that holds one id (no `Field.multiple`) holds a
   * comma-separated list (uamtc17). A field meant for one reference must not
   * silently hold several; each id of the list is still resolved, so a
   * dangling one is a `danglingReference` as well.
   */
  MULTIPLE_REFERENCES: 'multipleReferences',
});

/** One problem found while validating a document. */
class SpecValidationError {
  constructor(path, code, message) {
    this.path = path;
    this.code = code;
    this.message = message;
  }

  toString() {
    return `[${this.code}] ${this.path}: ${this.message}`;
  }
}

function _dangling(path) {
  return new SpecValidationError(
    path,
    SpecValidationCode.DANGLING_PATH,
    'path does not resolve to any model node',
  );
}

function _sorted(iterable) {
  return Array.from(iterable).sort();
}

/**
 * Validates `doc` against `model`. Returns an empty array when the document is
 * valid; otherwise one {@link SpecValidationError} per problem, in a stable order
 * (content paths, then forms, then lists; each group sorted by path).
 *
 * @returns {SpecValidationError[]}
 */
function validateDocument(model, doc) {
  const refl = new SpecReflection(model);
  const errors = [];

  // 1. Content/scalar/enum leaves.
  for (const path of _sorted(doc.contentPaths)) {
    const res = refl.resolve(path);
    if (res === null) {
      errors.push(_dangling(path));
      continue;
    }
    // A form node is the one non-leaf that legitimately carries content: it is
    // the form's preamble, the free text before the first field line (SOM §11.4
    // rule 7), in the same slot a plain section's body uses.
    // A wrapper section (TextSection, …) is the other: its class is not
    // exported, so it resolves to no class and its text is stored at its own
    // path, the way the YAML codec writes it.
    const isWrapperSection =
      res.kind === SpecNodeKind.SECTION && res.targetClass == null;
    if (!res.isValueLeaf && res.kind !== SpecNodeKind.FORM && !isWrapperSection) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.KIND_MISMATCH,
          `expected a value leaf but path resolves to ${res.kind}`,
        ),
      );
      continue;
    }
    if (res.kind === SpecNodeKind.SCALAR) {
      const type = res.field !== null && res.field !== undefined ? res.field.type : null;
      const value = doc.content(path);
      if (!somTypedTextReadable(type, value)) {
        errors.push(
          new SpecValidationError(
            path,
            SpecValidationCode.VALUE_TYPE_MISMATCH,
            `holds "${value}", which is not readable as ${somScalarBase(type)}`,
          ),
        );
      }
    }
  }

  // 2. Form sections.
  for (const path of _sorted(doc.formPaths)) {
    const res = refl.resolve(path);
    if (res === null) {
      errors.push(_dangling(path));
      continue;
    }
    if (res.kind !== SpecNodeKind.FORM || res.field === null) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.KIND_MISMATCH,
          `expected a form section but path resolves to ${res.kind}`,
        ),
      );
      continue;
    }
    const declared = new Map(res.field.formFields.map((ff) => [ff.name, ff]));
    for (const name of _sorted(doc.formFieldNames(path))) {
      const spec = declared.get(name);
      if (spec === undefined) {
        errors.push(
          new SpecValidationError(
            path,
            SpecValidationCode.UNKNOWN_FORM_FIELD,
            `form field "${name}" is not declared on ${res.field.name}`,
          ),
        );
        continue;
      }
      if (spec.enumValues.length === 0) {
        const text = doc.formField(path, name);
        // A stated count (`countOf`) is checked by `countMismatch`, a derived
        // value (`productOf`, `rankOf`) by `derivedValueMismatch`; both
        // already report text that is no number; one finding is enough.
        const countOf = spec.countOf || [];
        const productOf = spec.productOf || [];
        const rankOf = spec.rankOf == null ? null : spec.rankOf;
        if (
          countOf.length === 0 &&
          productOf.length === 0 &&
          rankOf === null &&
          !somTypedTextReadable(spec.type, text)
        ) {
          errors.push(
            new SpecValidationError(
              path,
              SpecValidationCode.VALUE_TYPE_MISMATCH,
              `form field "${name}" holds "${text}", which is not readable ` +
                `as ${somScalarBase(spec.type)}`,
            ),
          );
        }
        continue;
      }
      const value = doc.formField(path, name);
      // Absence is not a bad value.
      if (value === null || value === undefined || value === '') continue;
      if (!spec.enumValues.includes(value)) {
        errors.push(
          new SpecValidationError(
            path,
            SpecValidationCode.ENUM_VALUE_UNKNOWN,
            `form field "${name}" holds "${value}", which ${spec.type} does ` +
              `not declare (${spec.enumValues.join(', ')})`,
          ),
        );
      }
    }
    // A form the document holds must fill its required fields; the declared
    // order makes the findings for one form stable.
    const slash = path.lastIndexOf('/');
    const ownerRes = slash > 0 ? refl.resolve(path.substring(0, slash)) : null;
    const owner =
      ownerRes !== null && ownerRes !== undefined && ownerRes.targetClass
        ? ownerRes.targetClass.name
        : null;
    const formName =
      owner === null ? res.field.name : `${owner}.${res.field.name}`;
    for (const ff of res.field.formFields) {
      if (!ff.required) continue;
      const raw = doc.formField(path, ff.name);
      const value = raw === null || raw === undefined ? '' : String(raw).trim();
      if (value === '') {
        errors.push(
          new SpecValidationError(
            path,
            SpecValidationCode.MISSING_REQUIRED_FIELD,
            `form field "${ff.name}" is required on ${formName} but empty`,
          ),
        );
      }
    }
  }

  // 3. Lists (container kind + `@Min` count on populated lists).
  for (const path of _sorted(doc.listPaths)) {
    const res = refl.resolve(path);
    if (res === null) {
      errors.push(_dangling(path));
      continue;
    }
    if (res.kind !== SpecNodeKind.LIST || res.field === null) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.KIND_MISMATCH,
          `expected a list but path resolves to ${res.kind}`,
        ),
      );
      continue;
    }
    const minimum = res.field.min;
    const count = doc.listItemCount(path);
    if (minimum !== null && minimum !== undefined && count < minimum) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.MIN_ITEMS,
          `list holds ${count} item(s) but requires at least ${minimum}`,
        ),
      );
    }
  }

  // 4. @OneOf discriminated subsection groups (instance tier).
  //
  // A concrete `@OneOf` container must carry ONLY the subsections whose `@Case`
  // matches the chosen discriminator value (plus the common, un-`@Case`d ones),
  // and at most one case subsection for the chosen case
  // (`codespecs_mapping.md` §8.2). The static tier has already checked the
  // annotations are well-formed; here we check a document's *values* against
  // them.
  errors.push(..._validateOneOfInstances(refl, doc));

  // 5. Cross-registry id references (instance tier).
  //
  // A reference form field holds an id that must already be declared by some
  // entry of a target registry. The static tier has checked the `refersTo`
  // targets are resolvable; only here can we see whether the id a document
  // actually wrote is one the document also declares.
  errors.push(..._validateReferenceInstances(refl, doc));

  // 6. Stated counts (instance tier, vsctsa43).
  //
  // A form field declaring `countOf` states how many entries the document
  // holds; only the instance tier can count them.
  errors.push(..._validateCountInstances(refl, doc));

  // 7. Derived values (instance tier, uamtc10).
  //
  // A `productOf` field must hold the product of its operands, a `rankOf`
  // field must rank its form's instances by their score.
  errors.push(..._validateDerivedValues(refl, doc));

  return errors;
}

/**
 * The constant part of a qualified `EnumType.constant` `@Case` token (or the
 * whole string when it is not qualified).
 */
function _caseConstant(token) {
  const dot = token.indexOf('.');
  return dot >= 0 ? token.substring(dot + 1) : token;
}

/**
 * Instance-tier `@OneOf`/`@Case` check: for every `@OneOf` container instance
 * present in `doc`, verify the populated case subsections match the chosen
 * discriminator value.
 *
 * @returns {SpecValidationError[]}
 */
function _validateOneOfInstances(refl, doc) {
  const errors = [];

  // Every section-instance path present in the document: each stored value path
  // plus all of its ancestor prefixes (a container's own discriminator form
  // lives at `<container>/<form>`, so the container path is always a prefix of a
  // populated path).
  const sectionPaths = new Set();
  const addPrefixes = (full) => {
    const segs = full.split('/');
    let buf = '';
    for (let i = 0; i < segs.length; i++) {
      buf = i === 0 ? segs[i] : `${buf}/${segs[i]}`;
      sectionPaths.add(buf);
    }
  };
  for (const p of doc.contentPaths) addPrefixes(p);
  for (const p of doc.formPaths) addPrefixes(p);
  for (const p of doc.listPaths) addPrefixes(p);
  for (const p of doc.headlinePaths) addPrefixes(p);

  for (const path of _sorted(sectionPaths)) {
    const res = refl.resolve(path);
    const cls = res ? res.targetClass : null;
    if (cls === null || cls === undefined) {
      continue;
    }
    const oneOf = cls.annotation('OneOf');
    if (oneOf === null || oneOf === undefined) {
      continue;
    }
    const discriminator = oneOf.argument('discriminator');
    if (typeof discriminator !== 'string' || discriminator === '') {
      continue;
    }

    // Read the chosen discriminator value from the container's own @Form.
    let formHolder = null;
    for (const f of cls.fields) {
      if (
        f.kind === SpecFieldKind.FORM &&
        f.formFields.some((ff) => ff.name === discriminator)
      ) {
        formHolder = f;
        break;
      }
    }
    if (formHolder === null) {
      continue; // static tier flagged the mismatch
    }
    const chosen = doc.formField(
      `${path}/${refl.fieldSegment(formHolder)}`,
      discriminator,
    );
    if (chosen === null || chosen === undefined || chosen === '') {
      continue; // no case chosen yet
    }

    // Inspect each case-bound subsection: present + not-selected → mismatch.
    const presentForChosen = [];
    for (const f of cls.fields) {
      const caseConstants = new Set();
      for (const a of f.annotations) {
        if (a.name === 'Case' && typeof a.argument('value') === 'string') {
          caseConstants.add(_caseConstant(a.argument('value')));
        }
      }
      if (caseConstants.size === 0) {
        continue; // common subsection — always allowed
      }
      const childPath = `${path}/${refl.fieldSegment(f)}`;
      if (!doc.hasValuesUnder(childPath)) {
        continue;
      }
      if (caseConstants.has(chosen)) {
        presentForChosen.push(f.name);
      } else {
        errors.push(
          new SpecValidationError(
            childPath,
            SpecValidationCode.ONE_OF_CASE_MISMATCH,
            `subsection "${f.name}" is present but the chosen ` +
              `${discriminator}="${chosen}" does not select it ` +
              `(cases: ${_sorted(caseConstants).join(', ')})`,
          ),
        );
      }
    }
    if (presentForChosen.length > 1) {
      presentForChosen.sort();
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.ONE_OF_CASE_MISMATCH,
          `chosen ${discriminator}="${chosen}" selects more than one ` +
            `populated subsection (${presentForChosen.join(', ')}) — at most ` +
            'one case subsection may be present',
        ),
      );
    }
  }

  return errors;
}

/**
 * The section id part of a registry key written `<SECTIONID>.<slot>`. A key with
 * no dot is malformed — the static tier reports it — and is treated whole here
 * so it simply fails to match any section id.
 */
function _registrySectionId(target) {
  const dot = target.indexOf('.');
  return dot <= 0 ? target : target.substring(0, dot);
}

/**
 * The registry section ids that are **in scope** for `doc`: the `@SectionId` of
 * every class reachable from a document root the document actually uses.
 *
 * A `refersTo` target names its registry by section id, and a document can only
 * ever declare entries of registries its own root reaches. Anything outside this
 * set is absent from the document by construction — which is precisely the case
 * the dangling-reference check must not call an error.
 *
 * The roots are read off the document rather than passed in: every path begins
 * with its root's segment, so the document already says which root(s) it belongs
 * to and no caller has to know. A document spanning several roots (the
 * whole-project container) contributes the union.
 *
 * @returns {Set<string>}
 */
function _registryScope(refl, doc) {
  const rootTypes = new Set();
  const addRootOf = (path) => {
    const slash = path.indexOf('/');
    const segment = slash < 0 ? path : path.substring(0, slash);
    const root = refl.rootForSegment(segment);
    if (root !== null && root !== undefined) {
      rootTypes.add(root.type);
    }
  };
  for (const p of doc.contentPaths) addRootOf(p);
  for (const p of doc.formPaths) addRootOf(p);
  for (const p of doc.listPaths) addRootOf(p);
  for (const p of doc.headlinePaths) addRootOf(p);

  const ids = new Set();
  for (const type of rootTypes) {
    for (const name of refl.reachableClassNames(type)) {
      const cls = refl.classNamed(name);
      if (cls && cls.sectionId) {
        ids.add(cls.sectionId);
      }
    }
  }
  return ids;
}

/**
 * Instance-tier cross-registry reference check: every id written into a
 * `refersTo` form field must be declared by some entry of one of its target
 * registries *in this document*.
 *
 * The pass is two sweeps over the document's form sections, so it costs one
 * extra walk rather than a resolve per reference:
 *
 *  1. **Declare.** Every form instance whose class carries `@SectionId(X)` and
 *     declares form field `f` contributes its value of `f` to the registry key
 *     `X.f`. Every item of a list whose element class carries `@SectionId(X)`
 *     additionally contributes its *effective* section id — stored, else
 *     positional — to the reserved key `X.@sectionId`. That second half is what
 *     makes a registry keeping its id nowhere but the section id referenceable
 *     at all.
 *  2. **Resolve.** Every form instance holding a `refersTo` field checks its
 *     value against those sets, comma-segment by comma-segment.
 *
 * A value is valid when it resolves in **any** listed registry. An empty value
 * is not a dangling reference — it means "not filled in yet".
 *
 * **Cross-document references.** A reference whose target registry the
 * document's own root cannot reach is skipped rather than reported; see
 * {@link _registryScope}.
 *
 * @returns {SpecValidationError[]}
 */
function _validateReferenceInstances(refl, doc) {
  const errors = [];
  const scope = _registryScope(refl, doc);

  // Resolve every form path once; both sweeps read the same resolutions.
  const forms = _resolvedForms(refl, doc);

  // 1. Declare.
  const declared = new Map();
  const declare = (key, value) => {
    if (!declared.has(key)) {
      declared.set(key, new Set());
    }
    declared.get(key).add(value);
  };
  for (const form of forms) {
    const sectionId = form.cls.sectionId;
    if (!sectionId) {
      continue;
    }
    for (const ff of form.field.formFields) {
      const value = doc.formField(form.path, ff.name);
      if (value === null || value === undefined || value.trim() === '') {
        continue;
      }
      declare(`${sectionId}.${ff.name}`, value.trim());
    }
  }

  // 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
  // The key is the *element class's* section id, not the `-LST` container's: a
  // target names the entry, so `FRE.@sectionId` reads as "an id of some
  // functional-requirement entry".
  for (const listPath of _sorted(doc.listPaths)) {
    const listRes = refl.resolve(listPath);
    const listField = listRes ? listRes.field : null;
    const pattern = listField ? listField.sectionIdPattern : null;
    const stem = listField ? listField.name : listPath.split('/').pop();
    const items = doc.listItems(listPath);
    for (let i = 0; i < items.length; i++) {
      const itemRes = refl.resolve(items[i]);
      const elementClass = itemRes ? itemRes.targetClass : null;
      const sectionId = elementClass ? elementClass.sectionId : null;
      if (!sectionId) {
        continue;
      }
      declare(
        `${sectionId}.${K_SECTION_ID_SLOT}`,
        effectiveListItemSectionId(
          doc.itemSectionId(items[i]),
          pattern,
          i + 1,
          stem,
        ),
      );
    }
  }

  // 2. Resolve.
  for (const form of forms) {
    for (const ff of form.field.formFields) {
      if (ff.refersTo.length === 0) {
        continue;
      }
      const value = doc.formField(form.path, ff.name);
      if (value === null || value === undefined || value.trim() === '') {
        continue;
      }

      // One id, unless the field says it holds several. Decidable without the
      // registries, so it is checked before the scope test below.
      if (!ff.multiple) {
        const ids = value
          .split(',')
          .map((part) => part.trim())
          .filter((part) => part !== '');
        if (ids.length > 1) {
          errors.push(
            new SpecValidationError(
              form.path,
              SpecValidationCode.MULTIPLE_REFERENCES,
              `form field "${ff.name}" holds ${ids.length} references ` +
                `(${ids.join(', ')}) but takes one`,
            ),
          );
        }
      }

      // Every target must be in scope, not merely one of them: a disjunction
      // says the id may come from any of the listed registries, so one absent
      // registry is enough to make "no registry declares it" unsound.
      if (!ff.refersTo.every((t) => scope.has(_registrySectionId(t)))) {
        continue;
      }

      for (const segment of value.split(',')) {
        const id = segment.trim();
        if (id === '') {
          continue;
        }
        const resolves = ff.refersTo.some((target) => {
          const set = declared.get(target);
          return set !== undefined && set.has(id);
        });
        if (resolves) {
          continue;
        }
        errors.push(
          new SpecValidationError(
            form.path,
            SpecValidationCode.DANGLING_REFERENCE,
            `form field "${ff.name}" references "${id}", which no entry of ` +
              `${ff.refersTo.length === 1 ? 'registry' : 'registries'} ` +
              `${ff.refersTo.join(', ')} declares`,
          ),
        );
      }
    }
  }

  return errors;
}

/**
 * Every form instance in `doc` with its field and the class it sits on, in path
 * order — the shape both the reference and the count check sweep.
 *
 * A form resolution names the form *field*, not a class — the section id a
 * registry key is written against belongs to the class the form sits on, so the
 * owner is resolved from the parent path.
 *
 * @returns {{path: string, cls: object, field: object}[]}
 */
function _resolvedForms(refl, doc) {
  const forms = [];
  for (const path of _sorted(doc.formPaths)) {
    const res = refl.resolve(path);
    if (res === null || res.kind !== SpecNodeKind.FORM || res.field === null) {
      continue;
    }
    const slash = path.lastIndexOf('/');
    if (slash <= 0) {
      continue;
    }
    const owner = refl.resolve(path.substring(0, slash));
    const cls = owner ? owner.targetClass : null;
    if (cls === null || cls === undefined) {
      continue;
    }
    forms.push({ path, cls, field: res.field });
  }
  return forms;
}

/**
 * The section id of a `countOf` target — the part before any `.field=value`,
 * without the `./` scope prefix.
 */
function _countTargetId(target) {
  if (target.startsWith('./')) {
    target = target.substring(2);
  }
  const dot = target.indexOf('.');
  return dot < 0 ? target : target.substring(0, dot);
}

/**
 * Instance-tier stated-count check (vsctsa43): every non-empty value of a
 * `countOf` form field must be a whole number equal to the number of entries
 * the document holds.
 *
 * An **entry** is a list item whose element class carries `@SectionId(X)`. A
 * target `X` counts every such entry; `X.f=v` counts only the entries one of
 * whose own forms — a form member of the entry, at `<item>/<member>` — holds
 * `v` in form field `f`. The count is the sum over the targets. As with the
 * reference check, a target whose section id the document's root cannot reach
 * makes the field undecidable here, so it is skipped rather than reported, and
 * an empty value is completeness, not a count.
 *
 * @returns {SpecValidationError[]}
 */
function _validateCountInstances(refl, doc) {
  const forms = _resolvedForms(refl, doc);
  if (
    !forms.some((f) => f.field.formFields.some((ff) => ff.countOf.length > 0))
  ) {
    return [];
  }
  const scope = _registryScope(refl, doc);

  // Every entry, by its class's section id, with the form values its own form
  // members hold.
  const entriesById = new Map();
  for (const listPath of _sorted(doc.listPaths)) {
    for (const item of doc.listItems(listPath)) {
      const itemRes = refl.resolve(item);
      const cls = itemRes ? itemRes.targetClass : null;
      const id = cls ? cls.sectionId : null;
      if (!id) {
        continue;
      }
      if (!entriesById.has(id)) {
        entriesById.set(id, []);
      }
      entriesById.get(id).push(item);
    }
  }
  const valuesByItem = new Map();
  for (const path of doc.formPaths) {
    const slash = path.lastIndexOf('/');
    if (slash <= 0) {
      continue;
    }
    const owner = path.substring(0, slash);
    const res = refl.resolve(path);
    if (res === null || res === undefined || !res.field) {
      continue;
    }
    for (const ff of res.field.formFields) {
      const raw = doc.formField(path, ff.name);
      const v = raw === null || raw === undefined ? '' : raw.trim();
      if (v === '') {
        continue;
      }
      if (!valuesByItem.has(owner)) {
        valuesByItem.set(owner, new Map());
      }
      const byField = valuesByItem.get(owner);
      if (!byField.has(ff.name)) {
        byField.set(ff.name, new Set());
      }
      byField.get(ff.name).add(v);
    }
  }

  // A target written `./…` counts only the entries beneath `owner`, the
  // section holding the form; any other target counts the whole document.
  const countTarget = (target, owner) => {
    const scoped = target.startsWith('./');
    if (scoped) {
      target = target.substring(2);
    }
    const inScope = (item) => !scoped || item.startsWith(`${owner}/`);
    const dot = target.indexOf('.');
    if (dot < 0) {
      return (entriesById.get(target) || []).filter(inScope).length;
    }
    const id = target.substring(0, dot);
    const eq = target.indexOf('=', dot);
    const field = target.substring(dot + 1, eq < 0 ? target.length : eq);
    const value = eq < 0 ? '' : target.substring(eq + 1);
    return (entriesById.get(id) || []).filter(inScope).filter((item) => {
      const byField = valuesByItem.get(item);
      const values = byField ? byField.get(field) : undefined;
      return values !== undefined && values.has(value);
    }).length;
  };

  const errors = [];
  for (const form of forms) {
    for (const ff of form.field.formFields) {
      if (ff.countOf.length === 0) {
        continue;
      }
      const raw = doc.formField(form.path, ff.name);
      const stated = raw === null || raw === undefined ? '' : raw.trim();
      if (stated === '') {
        continue;
      }
      if (
        !ff.countOf.every((t) =>
          scope.has(_registrySectionId(_countTargetId(t))),
        )
      ) {
        continue;
      }
      const owner = form.path.substring(0, form.path.lastIndexOf('/'));
      const counted = ff.countOf
        .map((t) => countTarget(t, owner))
        .reduce((a, b) => a + b, 0);
      const targets = ff.countOf.join(' + ');
      if (!/^[0-9]+$/.test(stated)) {
        errors.push(
          new SpecValidationError(
            form.path,
            SpecValidationCode.COUNT_MISMATCH,
            `form field "${ff.name}" states "${stated}", which is not a whole ` +
              `number — it counts ${targets}, of which the document holds ` +
              `${counted}`,
          ),
        );
      } else if (Number(stated) !== counted) {
        errors.push(
          new SpecValidationError(
            form.path,
            SpecValidationCode.COUNT_MISMATCH,
            `form field "${ff.name}" states ${stated}, but the document ` +
              `holds ${counted} (counting ${targets})`,
          ),
        );
      }
    }
  }
  return errors;
}

/**
 * Instance-tier derived-value check (uamtc10): a `productOf` field must hold
 * the product of its operands, and a `rankOf` field must rank the instances of
 * its form by their score, highest first.
 *
 * **Operands.** A plain operand is a field of the same form; `F.x` is field
 * `x` of the form `F` beside it, at `<owner>/F` where `<owner>` is the section
 * holding this form. A numeric operand contributes its number, an enum operand
 * its 1-based position among the enum's values. When the value or any operand
 * is empty — or an operand is unreadable, which other checks report — the
 * product is undecidable and is skipped.
 *
 * **Precision.** The stated number is held to the precision it is written in:
 * `2.8` matches 0.7 × 4.0, and `15` matches 3 × 5, but `2.9` does not.
 *
 * **Ranks.** Over every instance of the same form whose rank and score are
 * both filled, the ranks must be the whole numbers 1 to n, each once, and an
 * instance may not rank below one that scores lower. Equal scores take their
 * ranks in any order. Each offending instance is reported once.
 *
 * @returns {SpecValidationError[]}
 */
function _validateDerivedValues(refl, doc) {
  const forms = _resolvedForms(refl, doc);
  if (
    !forms.some((f) =>
      f.field.formFields.some(
        (ff) => (ff.productOf || []).length > 0 || ff.rankOf != null,
      ),
    )
  ) {
    return [];
  }
  const errors = [];
  const numberPattern = /^-?[0-9]+(\.[0-9]+)?$/;
  const trimmed = (formPath, name) => {
    const raw = doc.formField(formPath, name);
    return raw === null || raw === undefined ? '' : raw.trim();
  };

  // The number a filled form field contributes, or null when it is empty or
  // unreadable.
  const numberOf = (formPath, spec) => {
    const v = trimmed(formPath, spec.name);
    if (v === '') {
      return null;
    }
    if (spec.enumValues.length > 0) {
      const i = spec.enumValues.indexOf(v);
      return i < 0 ? null : i + 1;
    }
    return numberPattern.test(v) ? Number(v) : null;
  };

  // The spec of field `name` of the form at `path`, or null.
  const specAt = (path, name) => {
    const res = refl.resolve(path);
    if (res === null || res === undefined || res.kind !== SpecNodeKind.FORM) {
      return null;
    }
    for (const ff of (res.field && res.field.formFields) || []) {
      if (ff.name === name) {
        return ff;
      }
    }
    return null;
  };

  const ranked = new Map();

  for (const form of forms) {
    const owner = form.path.substring(0, form.path.lastIndexOf('/'));
    for (const ff of form.field.formFields) {
      const productOf = ff.productOf || [];
      if (productOf.length > 0) {
        const stated = trimmed(form.path, ff.name);
        if (stated !== '') {
          let product = 1;
          for (const operand of productOf) {
            const dot = operand.indexOf('.');
            const path =
              dot < 0 ? form.path : `${owner}/${operand.substring(0, dot)}`;
            const name = dot < 0 ? operand : operand.substring(dot + 1);
            const spec = specAt(path, name);
            const n = spec === null ? null : numberOf(path, spec);
            if (n === null) {
              product = null;
              break;
            }
            product *= n;
          }
          const operands = productOf.join(' × ');
          if (!numberPattern.test(stated)) {
            errors.push(
              new SpecValidationError(
                form.path,
                SpecValidationCode.DERIVED_VALUE_MISMATCH,
                `form field "${ff.name}" states "${stated}", which is not a ` +
                  `number — it is the product ${operands}`,
              ),
            );
          } else if (product !== null) {
            const dot = stated.indexOf('.');
            const decimals = dot < 0 ? 0 : stated.length - dot - 1;
            const tolerance = 0.5 * _pow10(-decimals) + 1e-9;
            if (Math.abs(Number(stated) - product) > tolerance) {
              errors.push(
                new SpecValidationError(
                  form.path,
                  SpecValidationCode.DERIVED_VALUE_MISMATCH,
                  `form field "${ff.name}" states ${stated}, but ${operands} ` +
                    `gives ${_formatNumber(product)}`,
                ),
              );
            }
          }
        }
      }
      const by = ff.rankOf;
      if (by !== null && by !== undefined) {
        const stated = trimmed(form.path, ff.name);
        const scoreSpec = specAt(form.path, by);
        const score =
          scoreSpec === null ? null : numberOf(form.path, scoreSpec);
        if (stated !== '' && score !== null) {
          const key = `${form.cls.name}#${form.field.name}#${ff.name}`;
          if (!ranked.has(key)) {
            ranked.set(key, []);
          }
          ranked.get(key).push({ path: form.path, name: ff.name, stated, score });
        }
      }
    }
  }

  for (const group of ranked.values()) {
    const n = group.length;
    const rankOf = new Map();
    const seen = new Map();
    for (const e of group) {
      if (!/^[0-9]+$/.test(e.stated)) {
        continue;
      }
      const r = parseInt(e.stated, 10);
      rankOf.set(e.path, r);
      seen.set(r, (seen.get(r) || 0) + 1);
    }
    for (const e of group) {
      const r = rankOf.has(e.path) ? rankOf.get(e.path) : null;
      let problem = null;
      if (r === null) {
        problem = `states "${e.stated}", which is not a whole number`;
      } else if (r < 1 || r > n || seen.get(r) > 1) {
        problem =
          `states rank ${r}, but the ${n} ranked entries take the ranks ` +
          `1 to ${n}, each once`;
      } else {
        for (const o of group) {
          const ro = rankOf.has(o.path) ? rankOf.get(o.path) : null;
          if (ro !== null && o.score < e.score && ro < r) {
            problem =
              `ranks ${r} with score ${_formatNumber(e.score)}, below an ` +
              `entry ranked ${ro} with the lower score ` +
              `${_formatNumber(o.score)}`;
            break;
          }
        }
      }
      if (problem !== null) {
        errors.push(
          new SpecValidationError(
            e.path,
            SpecValidationCode.DERIVED_VALUE_MISMATCH,
            `form field "${e.name}" ${problem}`,
          ),
        );
      }
    }
  }
  // Like every phase's group, the findings are ordered by path (code-unit
  // order); Array.prototype.sort is stable, so a path's own findings keep the
  // order they were found in.
  return errors.sort((a, b) =>
    a.path < b.path ? -1 : a.path > b.path ? 1 : 0,
  );
}

function _pow10(exponent) {
  let v = 1;
  for (let i = 0; i < Math.abs(exponent); i++) {
    v *= 10;
  }
  return exponent < 0 ? 1 / v : v;
}

/** `15` for a whole number, `2.8` otherwise (JS already prints it so). */
function _formatNumber(v) {
  return String(v);
}

module.exports = {
  SpecValidationCode,
  SpecValidationError,
  validateDocument,
};
