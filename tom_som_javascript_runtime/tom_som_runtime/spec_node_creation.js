'use strict';

/**
 * Meta-model-validated node creation for a live {@link SpecDocument}
 * (llm_and_d4rt_tools.md §5 "constrained node creation") — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_node_creation.dart`.
 *
 * Every node a script or tool adds passes through this single gate, so the
 * document can only grow in ways the {@link SpecModel} permits for the parent.
 * The rules are the `tom_specs_model_rules.md` §10.2 *structural* rules — but
 * read from the model meta-data the runtime already carries
 * (`SpecField.kind`, `SpecField.sectionIdPattern`, `SpecField.min`), **not**
 * from the analyzer-backed authoring validator in `tom_specs_clitool`. The
 * clitool validates the *authored model graph*; this validates a *document
 * mutation against that model*. They are different layers and the runtime keeps
 * its lean, dependency-free footprint.
 *
 * {@link checkAddNode} is the single, value-aware rule-check entry point
 * (exported for reuse by editors and the engine); {@link SpecNodeCreator#add}
 * applies it and performs the mutation only when it returns `null`, so an
 * illegal add never touches the tree.
 */

const { SpecFieldKind } = require('./spec_model');
const { specPathJoin } = require('./spec_paths');
const { SpecReflection } = require('./spec_reflection');
const { generateListItemSectionId, sectionIdPatternPrefix } = require('./spec_section_id');

/** Why an attempted node creation is illegal against the model. */
const SpecCreationCode = Object.freeze({
  /**
   * The parent path does not resolve to a node that can own named children (it
   * is dangling, a leaf, or a list — lists grow through their own field, not by
   * adding children to the list node).
   */
  NOT_A_CONTAINER: 'notAContainer',

  /** The requested child segment names no field on the parent's class. */
  UNKNOWN_CHILD: 'unknownChild',

  /**
   * A caller-proposed list-item id does not keep the prefix mandated by the
   * list's `@SectionIdPattern` (AA1 criterion 3/5: an override replaces the
   * suffix, the pattern prefix stays).
   */
  PATTERN_MISMATCH: 'patternMismatch',

  /**
   * A caller-proposed list-item id collides with another item's section id in
   * the same list (AA1 criterion 5: section ids within a list must be unique).
   */
  DUPLICATE_SECTION_ID: 'duplicateSectionId',

  /**
   * A single-valued (non-list) child already holds a value — only one is
   * allowed.
   */
  CARDINALITY_EXCEEDED: 'cardinalityExceeded',
});

/**
 * A rejected node-creation attempt. Thrown by {@link SpecNodeCreator#add} and
 * returned (rather than thrown) by {@link checkAddNode}.
 */
class SpecCreationError extends Error {
  /**
   * @param {{parentPath: string, childSegment: string, code: string,
   *          message: string}} options
   */
  constructor({ parentPath, childSegment, code, message }) {
    super(message);
    this.name = 'SpecCreationError';
    /** The parent path the add was attempted under. */
    this.parentPath = parentPath;
    /** The child section segment that was requested. */
    this.childSegment = childSegment;
    /** Why the add is illegal (a {@link SpecCreationCode} constant). */
    this.code = code;
  }

  toString() {
    return (
      `SpecCreationError(${this.code}) ` +
      `under "${this.parentPath}" → "${this.childSegment}": ${this.message}`
    );
  }
}

/**
 * Validates adding child `childSegment` under `parentPath` against `model`,
 * consulting `document` for cardinality. Returns `null` when the add is legal,
 * otherwise the {@link SpecCreationError} describing the first rule it breaks.
 *
 * This performs **no mutation**; it is the shared rule-check that
 * {@link SpecNodeCreator#add} (and any editor) calls before touching the tree.
 *
 * @param {import('./spec_model').SpecModel} model
 * @param {import('./spec_document').SpecDocument} document
 * @param {string} parentPath
 * @param {string} childSegment
 * @param {{itemId?: ?string}} [options]
 * @returns {?SpecCreationError}
 */
function checkAddNode(model, document, parentPath, childSegment, { itemId = null } = {}) {
  const refl = new SpecReflection(model);

  const err = (code, message) =>
    new SpecCreationError({ parentPath, childSegment, code, message });

  // 1. The parent must resolve to a class-bearing node (root / complex /
  //    section / complex list item). Leaves, lists and dangling paths cannot
  //    own named children.
  const parent = refl.resolve(parentPath);
  if (parent === null || parent.targetClass === null || parent.targetClass === undefined) {
    const what = parent === null ? 'does not resolve' : `is a ${parent.kind}`;
    return err(
      SpecCreationCode.NOT_A_CONTAINER,
      `parent path ${what} and cannot own child nodes`,
    );
  }
  const parentClass = parent.targetClass;

  // 2. The child segment must name a declared field of the parent's class.
  const field = _fieldForSegment(parentClass, childSegment);
  if (field === null) {
    return err(
      SpecCreationCode.UNKNOWN_CHILD,
      `"${childSegment}" is not a child of ${parentClass.name}`,
    );
  }

  const childPath = specPathJoin(parentPath, childSegment);

  if (field.kind === SpecFieldKind.LIST) {
    // 3. List item: validate a caller-proposed id. Lists have no upper bound,
    //    so there is no cardinality check. A missing id is generated later
    //    (criterion 3); an explicit override must keep the pattern prefix
    //    (criterion 3) and stay unique within the list (criterion 5).
    const pattern = field.sectionIdPattern;
    if (itemId !== null && itemId !== undefined && pattern !== null && pattern !== undefined) {
      const prefix = sectionIdPatternPrefix(pattern);
      if (!itemId.startsWith(prefix)) {
        return err(
          SpecCreationCode.PATTERN_MISMATCH,
          `item id "${itemId}" does not keep the pattern prefix "${prefix}"`,
        );
      }
      if (document.listItemSectionIds(childPath).includes(itemId)) {
        return err(
          SpecCreationCode.DUPLICATE_SECTION_ID,
          `item id "${itemId}" is already used in list "${childPath}"`,
        );
      }
    }
    return null;
  }

  // 4. Single-valued child (complex / section / form / content / enum /
  //    scalar): cardinality is exactly one, so reject if a value already
  //    exists at or beneath the child path.
  if (document.hasValuesUnder(childPath)) {
    return err(
      SpecCreationCode.CARDINALITY_EXCEEDED,
      `a ${field.kind} child already exists at "${childPath}"`,
    );
  }
  return null;
}

/**
 * Applies {@link checkAddNode} and performs the constrained mutation.
 *
 * Holds the `model`/`document` pair so callers add children by parent path and
 * child segment without re-supplying the context each time.
 */
class SpecNodeCreator {
  /**
   * @param {import('./spec_model').SpecModel} model
   * @param {import('./spec_document').SpecDocument} document
   */
  constructor(model, document) {
    this.model = model;
    this.document = document;
  }

  /**
   * Adds child `childSegment` under `parentPath` and returns the new node's
   * path. For a list field this appends a fresh item (`…/<segment>-<seq>`),
   * assigning its **section id** (AA1 criteria 3–5): `itemId` if given
   * (override), otherwise one generated from the field's `@SectionIdPattern`
   * using `month`/`day` (defaulting to today) for the two-letter-date
   * component. Lists with no pattern (scalar lists) get no section id. For a
   * single-valued field it returns the child path without mutating the sparse
   * store (the caller then sets its value).
   *
   * Throws {@link SpecCreationError} — leaving the document untouched — when the
   * add violates a structural rule (see {@link SpecCreationCode}).
   *
   * The Dart reference takes a `DateTime`; this port takes the `month`/`day`
   * pair the shared `spec_section_id.js` helper already speaks, matching
   * `SpecEditor#addListItem`.
   *
   * @param {string} parentPath
   * @param {string} childSegment
   * @param {{itemId?: ?string, month?: ?number, day?: ?number}} [options]
   * @returns {string}
   */
  add(parentPath, childSegment, { itemId = null, month = null, day = null } = {}) {
    const error = checkAddNode(this.model, this.document, parentPath, childSegment, { itemId });
    if (error !== null) {
      throw error;
    }

    const childPath = specPathJoin(parentPath, childSegment);
    const parent = new SpecReflection(this.model).resolve(parentPath);
    const field = _fieldForSegment(parent.targetClass, childSegment);
    if (field.kind === SpecFieldKind.LIST) {
      const pattern = field.sectionIdPattern;
      if (pattern === null || pattern === undefined) {
        return this.document.addListItem(childPath);
      }
      const today = new Date();
      const id =
        itemId !== null && itemId !== undefined
          ? itemId
          : generateListItemSectionId(
              pattern,
              month === null || month === undefined ? today.getMonth() + 1 : month,
              day === null || day === undefined ? today.getDate() : day,
              this.document.listItemSectionIds(childPath),
            );
      return this.document.addListItem(childPath, id);
    }
    return childPath;
  }
}

/**
 * The field of `cls` whose section segment (`@SectionId` ?? name) is `segment`,
 * or `null` when the class declares no such child.
 *
 * @param {import('./spec_model').SpecClass} cls
 * @param {string} segment
 * @returns {?import('./spec_model').SpecField}
 */
function _fieldForSegment(cls, segment) {
  for (const f of cls.fields) {
    if ((f.sectionId !== null && f.sectionId !== undefined ? f.sectionId : f.name) === segment) {
      return f;
    }
  }
  return null;
}

module.exports = {
  SpecCreationCode,
  SpecCreationError,
  checkAddNode,
  SpecNodeCreator,
};
