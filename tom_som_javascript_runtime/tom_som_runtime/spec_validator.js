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
    if (!res.isValueLeaf) {
      errors.push(
        new SpecValidationError(
          path,
          SpecValidationCode.KIND_MISMATCH,
          `expected a value leaf but path resolves to ${res.kind}`,
        ),
      );
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
    const declared = new Set(res.field.formFields.map((ff) => ff.name));
    for (const name of _sorted(doc.formFieldNames(path))) {
      if (!declared.has(name)) {
        errors.push(
          new SpecValidationError(
            path,
            SpecValidationCode.UNKNOWN_FORM_FIELD,
            `form field "${name}" is not declared on ${res.field.name}`,
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
  //
  // A form resolution names the form *field*, not a class — the section id a
  // registry key is written against belongs to the class the form sits on, so
  // the owner is resolved from the parent path.
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

module.exports = {
  SpecValidationCode,
  SpecValidationError,
  validateDocument,
};
