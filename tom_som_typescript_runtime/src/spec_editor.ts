/**
 * The generic, meta-model-driven modification API (YRD7) — a faithful port of
 * `tom_som_dart_runtime/lib/src/spec_editor.dart` (and the Python
 * `spec_editor.py`).
 *
 * {@link SpecEditor} lets a consumer walk any document's meta tree and
 * create/modify/delete sections, list items, headlines, ids, content and
 * **typed** form fields *without a generated facade*: every operation resolves
 * its path against the {@link SpecModel} first ({@link SpecReflection.resolve})
 * and converts values at the store boundary through the same
 * `spec_typed_values.ts` helpers the generated accessors call — so a typed
 * facade is provably a thin layer over exactly this API.
 *
 * Typed contract (mirrored by all nine runtimes):
 *
 *   * `int` / `double` / `num` / `bool` values are native on both sides — one
 *     `number` here, so the store rendering follows the **declared** field type
 *     (a `double` field always stores `2.0`, never `2`);
 *   * enum values travel as validated **constant-name strings** at this generic
 *     layer (`'high'`), because the generic API has no generated enum types —
 *     only the facade layer converts to native constants;
 *   * `null` (or `''`) clears a value (D4);
 *   * reads are forgiving (unparsable stored text reads as `null`), writes are
 *     strict (an {@link Error} for a wrong type or an out-of-domain enum name).
 */

import { SpecDocument } from './spec_document';
import { FormFieldSpec, SpecField, SpecModel } from './spec_model';
import { SpecNodeKind, SpecReflection, SpecResolution } from './spec_reflection';
import type { SpecNodeKindValue } from './spec_reflection';
import { generateListItemSectionId } from './spec_section_id';
import {
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
} from './spec_typed_values';

/**
 * A value as it crosses the generic editing boundary: the native scalar types
 * the store round-trips, plus `null` for "unset".
 *
 * TypeScript has no dynamic `Object?`, so the untyped in/out position Dart and
 * Python spell as `Object?` / `Any` is named here. Enum leaves travel as their
 * constant-name `string`.
 */
export type SomValue = string | number | boolean | null;

/** Strips a trailing `?` from a declared type name. */
function _scalarBase(typeName: string | null | undefined): string | null {
  if (typeName === null || typeName === undefined) {
    return null;
  }
  return typeName.endsWith('?') ? typeName.slice(0, -1) : typeName;
}

/** Parses stored text per the declared scalar base type. */
function _parseScalar(raw: string, base: string | null): SomValue {
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
export class SpecEditor {
  /** The document being edited (the sparse value stores). */
  document: SpecDocument;

  /** The value-free meta-model queries the editor validates against. */
  reflection: SpecReflection;

  constructor(document: SpecDocument, reflection: SpecReflection) {
    this.document = document;
    this.reflection = reflection;
  }

  /** Convenience: builds the editor for `document` over `model`. */
  static forModel(document: SpecDocument, model: SpecModel): SpecEditor {
    return new SpecEditor(document, new SpecReflection(model));
  }

  // --- resolution -----------------------------------------------------------

  /**
   * Resolves `path` against the meta-model, throwing for a dangling path — the
   * strict companion to {@link SpecReflection.resolve}.
   */
  resolve(path: string): SpecResolution {
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
   * The returned value follows the model: `int`/`double`/`num`/`bool` scalars
   * return the parsed native value, enum leaves the validated constant name,
   * everything else the raw string. Throws when `path` is not a value leaf.
   */
  value(path: string): SomValue {
    const r = this._valueLeaf(path);
    const raw = this.document.content(path);
    if (raw === null || raw === '') {
      return null;
    }
    if (r.kind === SpecNodeKind.ENUM_VALUE) {
      return somParseEnumName(raw, r.field !== null ? r.field.enumValues : []);
    }
    return _parseScalar(
      raw,
      _scalarBase(r.field !== null ? r.field.type : null),
    );
  }

  /**
   * Sets the value leaf at `path` to `v`, converting at the store boundary.
   *
   * `null` clears. For typed scalars `v` must be the native type (or a string,
   * taken verbatim); for enum leaves `v` must be one of the field's constant
   * names. Throws for a non-leaf path, a wrong value type, or an out-of-domain
   * enum name.
   */
  setValue(path: string, v: SomValue): void {
    const r = this._valueLeaf(path);
    this.document.setContent(path, this._format(v, r.kind, r.field, path));
  }

  private _valueLeaf(path: string): SpecResolution {
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
   */
  headline(path: string): string | null {
    this.resolve(path);
    return this.document.headline(path);
  }

  /**
   * Sets the stored headline at `path`; empty/`null` returns the section to its
   * default title.
   */
  setHeadline(path: string, value: string | null): void {
    this.resolve(path);
    this.document.setHeadline(path, value !== null ? value : '');
  }

  // --- typed form fields ----------------------------------------------------

  /**
   * The typed value of form `field` at the `@Form` section `path`, or `null`
   * when unset.
   *
   * Reads the form store and parses per the declared field type (enum fields
   * return the validated constant name). Throws for a non-form path or an
   * unknown field name.
   */
  formValue(path: string, field: string): SomValue {
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
   * Throws for a wrong value type or an out-of-domain enum name.
   */
  setFormValue(path: string, field: string, v: SomValue): void {
    const ff = this._formField(path, field);
    const stored =
      ff.enumValues.length > 0
        ? somFormatEnumName(this._stringOrNull(v, path, field), ff.enumValues)
        : this._format(v, SpecNodeKind.SCALAR, null, path, ff.type, field);
    this.document.setFormField(path, field, stored);
  }

  /**
   * The form-field specs of the `@Form` section at `path`, in declaration order
   * — the meta a generic editor UI renders from.
   */
  formFields(path: string): FormFieldSpec[] {
    const r = this.resolve(path);
    if (r.kind !== SpecNodeKind.FORM) {
      throw new Error(`path '${path}' is a ${r.kind} node, not a @Form section`);
    }
    return r.field !== null ? r.field.formFields : [];
  }

  private _formField(path: string, field: string): FormFieldSpec {
    const r = this.resolve(path);
    if (r.kind !== SpecNodeKind.FORM) {
      throw new Error(`path '${path}' is a ${r.kind} node, not a @Form section`);
    }
    for (const ff of r.field !== null ? r.field.formFields : []) {
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
   * other items. Throws when `listPath` is not a list.
   */
  addListItem(
    listPath: string,
    sectionId: string | null = null,
    month: number | null = null,
    day: number | null = null,
  ): string {
    const r = this.resolve(listPath);
    if (r.kind !== SpecNodeKind.LIST) {
      throw new Error(`path '${listPath}' is a ${r.kind} node, not a list`);
    }
    let id = sectionId;
    const pattern = r.field !== null ? r.field.sectionIdPattern : null;
    if (id === null && pattern !== null) {
      const today = new Date();
      id = generateListItemSectionId(
        pattern,
        month !== null ? month : today.getMonth() + 1,
        day !== null ? day : today.getDate(),
        this.document.listItemSectionIds(listPath),
      );
    }
    return this.document.addListItem(listPath, id);
  }

  /**
   * Removes the list item at `itemPath` with every value beneath it. Returns
   * `true` when an item was found and removed.
   */
  removeListItem(itemPath: string): boolean {
    return this.document.removeListItem(itemPath);
  }

  /**
   * Clears every value at `path` and beneath it — content, form entries, nested
   * list items, stored headlines and ids — returning the subtree to the
   * untouched "empty = no value" state (D4). The node itself remains
   * addressable (structure lives in the model, not the document).
   */
  clearSection(path: string): void {
    this.resolve(path);
    this.document.removeValuesUnder(path);
  }

  // --- conversion -----------------------------------------------------------

  /**
   * Formats `v` for the store per the leaf's declared type; strings pass through
   * verbatim (the plain-text serialization is authoritative).
   */
  private _format(
    v: SomValue,
    kind: SpecNodeKindValue,
    field: SpecField | null,
    path: string,
    typeName: string | null = null,
    where: string | null = null,
  ): string {
    if (v === null) {
      return '';
    }
    if (kind === SpecNodeKind.ENUM_VALUE) {
      return somFormatEnumName(
        this._stringOrNull(v, path, where !== null ? where : path),
        field !== null ? field.enumValues : [],
      );
    }
    const base = _scalarBase(
      typeName !== null ? typeName : field !== null ? field.type : null,
    );
    switch (base) {
      case 'int':
        if (typeof v === 'number' && Number.isInteger(v)) {
          return somFormatInt(v);
        }
        break;
      case 'double':
        // One `number` type: an integral value is still a `double` field, so it
        // must store with the decimal point (`2` → `2.0`).
        if (typeof v === 'number') {
          return somFormatDouble(v);
        }
        break;
      case 'num':
        if (typeof v === 'number') {
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

  private _stringOrNull(
    v: SomValue,
    path: string,
    field: string,
  ): string | null {
    if (v === null) {
      return null;
    }
    if (typeof v === 'string') {
      return v;
    }
    throw new Error(`${field}: expected a string for this field of ${path}`);
  }
}
