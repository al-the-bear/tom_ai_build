'use strict';

/**
 * The generic, meta-model-driven modification API (YRD7) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_editor.dart` (and `spec_editor.py`).
 *
 * {@link SpecEditor} lets a consumer walk any document's meta tree and
 * create/modify/delete sections, list items, headlines, ids, content and
 * **typed** form fields *without a generated facade*: every operation resolves
 * its path against the {@link SpecModel} first ({@link SpecReflection#resolve})
 * and converts values at the store boundary through the same
 * `spec_typed_values.js` helpers the generated accessors call — so a typed
 * facade is provably a thin layer over exactly this API.
 *
 * Typed contract (mirrored by all nine runtimes):
 *
 *   * `int` / `double` / `num` / `bool` values are native on both sides;
 *   * enum values travel as validated **constant-name strings** at this generic
 *     layer (`'high'`), because the generic API has no generated enum types —
 *     only the facade layer converts to native constants;
 *   * `null` (or `''`) clears a value (D4);
 *   * reads are forgiving (unparsable stored text reads as `null`), writes are
 *     strict (an {@link Error} for a wrong type or an out-of-domain enum name).
 *
 * JavaScript has a single `number` type, so the `int`/`double`/`num` split the
 * reference runtimes get from the language is made here from the **declared
 * field type**: a `double` field stores `2` as `2.0`, and a fractional value
 * written to an `int` field is rejected.
 */

const { SpecNodeKind, SpecReflection } = require('./spec_reflection');
const { generateListItemSectionId } = require('./spec_section_id');
const {
  somFormatBool,
  somFormatDouble,
  somFormatEnumName,
  somFormatInt,
  somFormatNum,
  somParseBool,
  somParseDouble,
  somParseEnumName,
  somParseInt,
  somParseNum,
} = require('./spec_typed_values');

/**
 * Strips a trailing `?` from a declared type name.
 *
 * @param {?string} typeName
 * @returns {?string}
 */
function _scalarBase(typeName) {
  if (typeName === null || typeName === undefined) {
    return null;
  }
  return typeName.endsWith('?') ? typeName.slice(0, -1) : typeName;
}

/**
 * Parses stored text per the declared scalar base type.
 *
 * @param {string} raw
 * @param {?string} base
 * @returns {string|number|boolean|null}
 */
function _parseScalar(raw, base) {
  switch (base) {
    case 'int':
      return somParseInt(raw);
    case 'double':
      return somParseDouble(raw);
    case 'num':
      return somParseNum(raw);
    case 'bool':
      return somParseBool(raw);
    default:
      return raw;
  }
}

/** Generic, typed, meta-validated editing over a {@link SpecDocument}. */
class SpecEditor {
  /**
   * @param {import('./spec_document').SpecDocument} document
   * @param {SpecReflection} reflection
   */
  constructor(document, reflection) {
    /** The document being edited (the sparse value stores). */
    this.document = document;
    /** The value-free meta-model queries the editor validates against. */
    this.reflection = reflection;
  }

  /**
   * Convenience: builds the editor for `document` over `model`.
   *
   * @param {import('./spec_document').SpecDocument} document
   * @param {import('./spec_model').SpecModel} model
   * @returns {SpecEditor}
   */
  static forModel(document, model) {
    return new SpecEditor(document, new SpecReflection(model));
  }

  // --- resolution -----------------------------------------------------------

  /**
   * Resolves `path` against the meta-model, throwing an {@link Error} for a
   * dangling path — the strict companion to {@link SpecReflection#resolve}.
   *
   * @param {string} path
   * @returns {import('./spec_reflection').SpecResolution}
   */
  resolve(path) {
    const r = this.reflection.resolve(path);
    if (r === null) {
      throw new Error(`path '${path}' does not resolve against the model`);
    }
    return r;
  }

  // --- value leaves (content / scalar / enum / scalar list item) ------------

  /**
   * The typed value at the value leaf `path`, or `null` when unset.
   *
   * The returned type follows the model: `int`/`double`/`num`/`bool` scalars
   * return the parsed native value, enum leaves the validated constant name,
   * everything else the raw string. Throws an {@link Error} when `path` is not
   * a value leaf.
   *
   * @param {string} path
   * @returns {string|number|boolean|null}
   */
  value(path) {
    const r = this._valueLeaf(path);
    const raw = this.document.content(path);
    if (raw === null || raw === '') {
      return null;
    }
    if (r.kind === SpecNodeKind.ENUM_VALUE) {
      return somParseEnumName(raw, r.field !== null ? r.field.enumValues : []);
    }
    return _parseScalar(raw, _scalarBase(r.field !== null ? r.field.type : null));
  }

  /**
   * Sets the value leaf at `path` to `v`, converting at the store boundary.
   *
   * `null` clears. For typed scalars `v` must be the native type (or a string,
   * taken verbatim); for enum leaves `v` must be one of the field's constant
   * names. Throws an {@link Error} for a non-leaf path, a wrong value type, or
   * an out-of-domain enum name.
   *
   * @param {string} path
   * @param {string|number|boolean|null} v
   */
  setValue(path, v) {
    const r = this._valueLeaf(path);
    this.document.setContent(path, this._format(v, r.kind, r.field, path));
  }

  /**
   * @param {string} path
   * @returns {import('./spec_reflection').SpecResolution}
   */
  _valueLeaf(path) {
    const r = this.resolve(path);
    if (!r.isValueLeaf) {
      throw new Error(`path '${path}' is a ${r.kind} node, not a value leaf`);
    }
    return r;
  }

  // --- headlines (YRD3) -----------------------------------------------------

  /**
   * The stored headline at `path`, or `null` when the section renders its
   * effective default title.
   *
   * @param {string} path
   * @returns {?string}
   */
  headline(path) {
    this.resolve(path);
    return this.document.headline(path);
  }

  /**
   * Sets the stored headline at `path`; empty/`null` returns the section to its
   * default title.
   *
   * @param {string} path
   * @param {?string} value
   */
  setHeadline(path, value) {
    this.resolve(path);
    this.document.setHeadline(path, value === null || value === undefined ? '' : value);
  }

  // --- typed form fields ----------------------------------------------------

  /**
   * The typed value of form `field` at the `@Form` section `path`, or `null`
   * when unset.
   *
   * Reads the form store and parses per the declared field type (enum fields
   * return the validated constant name). Throws an {@link Error} for a non-form
   * path or an unknown field name.
   *
   * @param {string} path
   * @param {string} field
   * @returns {string|number|boolean|null}
   */
  formValue(path, field) {
    const ff = this._formField(path, field);
    const raw = this.document.formField(path, field);
    if (raw === null || raw === '') {
      return null;
    }
    if (ff.enumValues.length > 0) {
      return somParseEnumName(raw, ff.enumValues);
    }
    return _parseScalar(raw, _scalarBase(ff.type));
  }

  /**
   * Sets form `field` at the `@Form` section `path` to the typed value `v`
   * (`null` clears), converting through the shared boundary helpers.
   *
   * Throws an {@link Error} for a wrong value type or an out-of-domain enum
   * name.
   *
   * @param {string} path
   * @param {string} field
   * @param {string|number|boolean|null} v
   */
  setFormValue(path, field, v) {
    const ff = this._formField(path, field);
    const stored =
      ff.enumValues.length > 0
        ? somFormatEnumName(this._stringOrNull(v, path, field), ff.enumValues)
        : this._format(v, SpecNodeKind.SCALAR, null, path, ff.type, field);
    this.document.setFormField(path, field, stored);
  }

  /**
   * The form-field specs of the `@Form` section at `path`, in declaration
   * order — the meta a generic editor UI renders from.
   *
   * @param {string} path
   * @returns {import('./spec_model').FormFieldSpec[]}
   */
  formFields(path) {
    const r = this.resolve(path);
    if (r.kind !== SpecNodeKind.FORM) {
      throw new Error(`path '${path}' is a ${r.kind} node, not a @Form section`);
    }
    return r.field !== null ? r.field.formFields : [];
  }

  /**
   * @param {string} path
   * @param {string} field
   * @returns {import('./spec_model').FormFieldSpec}
   */
  _formField(path, field) {
    for (const ff of this.formFields(path)) {
      if (ff.name === field) {
        return ff;
      }
    }
    throw new Error(`'${field}' is not a form field of ${path}`);
  }

  // --- structural operations ------------------------------------------------

  /**
   * Appends a new item to the list at `listPath` and returns its stable item
   * path.
   *
   * When the list field carries a `@SectionIdPattern` and no explicit
   * `sectionId` is given, a fresh id is generated from the pattern
   * ({@link generateListItemSectionId}, dated `month`/`day` — defaulting to
   * today). An explicit `sectionId` is uniqueness-checked against the list's
   * other items. Throws an {@link Error} when `listPath` is not a list.
   *
   * @param {string} listPath
   * @param {{sectionId?: ?string, month?: ?number, day?: ?number}} [options]
   * @returns {string}
   */
  addListItem(listPath, { sectionId = null, month = null, day = null } = {}) {
    const r = this.resolve(listPath);
    if (r.kind !== SpecNodeKind.LIST) {
      throw new Error(`path '${listPath}' is a ${r.kind} node, not a list`);
    }
    let id = sectionId;
    const pattern = r.field !== null ? r.field.sectionIdPattern : null;
    if ((id === null || id === undefined) && pattern !== null) {
      const today = new Date();
      id = generateListItemSectionId(
        pattern,
        month === null || month === undefined ? today.getMonth() + 1 : month,
        day === null || day === undefined ? today.getDate() : day,
        this.document.listItemSectionIds(listPath),
      );
    }
    return this.document.addListItem(listPath, id);
  }

  /**
   * Removes the list item at `itemPath` with every value beneath it. Returns
   * `true` when an item was found and removed.
   *
   * @param {string} itemPath
   * @returns {boolean}
   */
  removeListItem(itemPath) {
    return this.document.removeListItem(itemPath);
  }

  /**
   * Clears every value at `path` and beneath it — content, form entries, nested
   * list items, stored headlines and ids — returning the subtree to the
   * untouched "empty = no value" state (D4). The node itself remains
   * addressable (structure lives in the model, not the document).
   *
   * @param {string} path
   */
  clearSection(path) {
    this.resolve(path);
    this.document.removeValuesUnder(path);
  }

  // --- conversion -----------------------------------------------------------

  /**
   * Formats `v` for the store per the leaf's declared type; strings pass
   * through verbatim (the plain-text serialization is authoritative).
   *
   * @param {string|number|boolean|null} v
   * @param {string} kind
   * @param {?import('./spec_model').SpecField} field
   * @param {string} path
   * @param {?string} [typeName]
   * @param {?string} [where]
   * @returns {string}
   */
  _format(v, kind, field, path, typeName = null, where = null) {
    if (v === null || v === undefined) {
      return '';
    }
    if (kind === SpecNodeKind.ENUM_VALUE) {
      return somFormatEnumName(
        this._stringOrNull(v, path, where !== null ? where : path),
        field !== null ? field.enumValues : [],
      );
    }
    const base = _scalarBase(
      typeName !== null && typeName !== undefined
        ? typeName
        : field !== null
          ? field.type
          : null,
    );
    const isNumber = typeof v === 'number';
    switch (base) {
      case 'int':
        if (isNumber && Number.isInteger(v)) {
          return somFormatInt(v);
        }
        break;
      case 'double':
        if (isNumber) {
          return somFormatDouble(v);
        }
        break;
      case 'num':
        if (isNumber) {
          return somFormatNum(v);
        }
        break;
      case 'bool':
        if (typeof v === 'boolean') {
          return somFormatBool(v);
        }
        break;
      default:
        break;
    }
    if (typeof v === 'string') {
      return v;
    }
    throw new Error(
      `${JSON.stringify(v)} at ${where !== null ? where : path}: ` +
        `wrong value type for a ${base !== null ? base : 'String'} field`,
    );
  }

  /**
   * @param {string|number|boolean|null} v
   * @param {string} path
   * @param {string} field
   * @returns {?string}
   */
  _stringOrNull(v, path, field) {
    if (v === null || v === undefined) {
      return null;
    }
    if (typeof v === 'string') {
      return v;
    }
    throw new Error(`${field}: expected a string for this field of ${path}`);
  }
}

module.exports = { SpecEditor };
