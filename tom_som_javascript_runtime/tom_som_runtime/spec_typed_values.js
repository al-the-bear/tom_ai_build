'use strict';

/**
 * Shared typed-value conversion at the store boundary (YRD7) — a faithful port
 * of `tom_som_dart_runtime/lib/src/spec_typed_values.dart` (and
 * `spec_typed_values.py`).
 *
 * A {@link SpecDocument}'s stores hold **plain strings** — that is what the
 * md/yaml serialization writes (`FieldName: value`) and what keeps every
 * language runtime's persistence identical. Typed access therefore converts *at
 * the boundary*: parse on read, format on write. These helpers are that single
 * boundary — the generated typed facades and the generic {@link SpecEditor}
 * call the **same** functions, so a facade is provably a thin layer over the
 * generic API (they cannot disagree on a conversion).
 *
 * Conventions (the typed contract, mirrored by all nine runtimes):
 *
 *   * absent / empty string ⇒ `null` on read; `null` on write ⇒ clear (D4);
 *   * `int`, `double` and `num` text is read with surrounding whitespace
 *     trimmed (the TypeScript reading is canonical for every runtime);
 *   * `int` — an optional sign and decimal digits; {@link somParseInt} returns
 *     `null` for anything else (a fraction — `12.5` is not an `int` —,
 *     hexadecimal, digit separators);
 *   * `double` — a decimal or exponent literal (also a plain integer); `NaN`,
 *     `Infinity` and every other spelling read as `null`, because a spec value
 *     is finite; formatting always shows a fraction or an exponent, so an
 *     integral value round-trips as `2.0` rather than `2`;
 *   * `num` — an integral literal parses to an integer, everything else to a
 *     float; JavaScript has one numeric type, so formatting decides by
 *     inspecting the value (`Number.isInteger`) rather than by its class;
 *   * `bool` — stored as `true` / `false` (lower case, language-neutral);
 *     parsing accepts exactly those, anything else reads as `null`;
 *   * enums — stored as the constant **name** (e.g. `high`); the generic layer
 *     validates against the field's `enumValues` domain, the generated facade
 *     converts name ⇄ native constant;
 *   * a typed value holding inline marks (SOM §11.9.3, a change under review:
 *     `{~~ 30 ~> 15 ~~}`) reads as its **old** value, every mark rejected,
 *     until the marks are decided ({@link somTypedReading}).
 *
 * The parsers match on an explicit grammar rather than deferring to `Number()`
 * / `parseInt()`, whose coercions (`''` → `0`, `'0x10'` → `16`, a trailing
 * `'12abc'` → `12`) would silently admit text the reference runtimes reject.
 */

const { applyInlineMarksText } = require('./spec_review_annotations');

/**
 * The reading of a typed value under review: `raw` with every inline mark
 * rejected (its old value), trimmed; `raw` itself when it holds no mark.
 *
 * A typed value marked as a change (SOM §11.9.3) is the old value until the
 * change is accepted: the parsers below, the validator and every typed read
 * see that value, never the markup.
 *
 * @param {?string} raw
 * @returns {?string}
 */
function somTypedReading(raw) {
  if (raw === null || raw === undefined || !raw.includes('{')) {
    return raw;
  }
  const old = applyInlineMarksText(raw, { accept: false });
  return old === raw ? raw : old.trim();
}

/** The `int` grammar: an optionally-signed run of decimal digits. */
const _INT_PATTERN = /^[+-]?[0-9]+$/;

/** The `double` grammar: a decimal literal with optional fraction/exponent. */
const _DOUBLE_PATTERN =
  /^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$/;

/**
 * Whether a rendered number already reads as a floating literal — a decimal
 * point, an exponent, or one of the non-finite spellings (`Infinity`, `NaN`).
 */
const _READS_AS_FLOAT = /[.eEnN]/;

/**
 * Parses a stored string as an integer, or `null` when absent/unparsable.
 * The text is trimmed; only an optional sign and decimal digits are read.
 *
 * @param {?string} raw
 * @returns {?number}
 */
function somParseInt(raw) {
  raw = somTypedReading(raw);
  if (raw === null || raw === undefined || raw === '') {
    return null;
  }
  const text = raw.trim();
  return _INT_PATTERN.test(text) ? parseInt(text, 10) : null;
}

/**
 * Formats an integer for the store; `null` becomes `''` (clear, D4).
 *
 * @param {?number} value
 * @returns {string}
 */
function somFormatInt(value) {
  return value === null || value === undefined ? '' : String(value);
}

/**
 * Parses a stored string as a floating-point number, or `null` when
 * absent/unparsable. The text is trimmed; only a decimal or exponent literal is
 * read — `NaN`, `Infinity` and hexadecimal text are refused.
 *
 * @param {?string} raw
 * @returns {?number}
 */
function somParseDouble(raw) {
  raw = somTypedReading(raw);
  if (raw === null || raw === undefined || raw === '') {
    return null;
  }
  const text = raw.trim();
  if (!_DOUBLE_PATTERN.test(text)) return null;
  const value = parseFloat(text);
  // A literal that overflows (`1e400`) is no value: a spec value is finite.
  return Number.isFinite(value) ? value : null;
}

/**
 * Formats a `double` for the store; `null` becomes `''` (clear, D4).
 *
 * A `double` always renders with a fraction or an exponent (`2.0`), matching
 * Dart's `double.toString` — the store is language-neutral, so the same value
 * must serialize identically everywhere. JavaScript has a single numeric type
 * and would render `2`, so the point is forced here; the caller decides that
 * the value *is* a `double` from the field's declared type.
 *
 * @param {?number} value
 * @returns {string}
 */
function somFormatDouble(value) {
  if (value === null || value === undefined) {
    return '';
  }
  // String(-0) is "0": the sign of a negative zero is kept, as every runtime
  // writes it (decision tspubnondart29 (a)).
  if (Object.is(value, -0)) {
    return '-0.0';
  }
  const text = String(value);
  return _READS_AS_FLOAT.test(text) ? text : `${text}.0`;
}

/**
 * Parses a stored string as an integer when the text is integral, else as a
 * floating-point number; `null` when absent/unparsable. The text is trimmed.
 *
 * Mirrors Dart's `num.tryParse`: an integral literal yields an `int`, so `num`
 * fields keep the narrower type when the text carries no fraction. JavaScript
 * has one numeric type, so the distinction survives only in the value itself.
 *
 * @param {?string} raw
 * @returns {?number}
 */
function somParseNum(raw) {
  raw = somTypedReading(raw);
  const asInt = somParseInt(raw);
  return asInt !== null ? asInt : somParseDouble(raw);
}

/**
 * Formats a `num` for the store; `null` becomes `''` (clear, D4).
 *
 * An integral value renders without a decimal point, a fractional one with —
 * the split Dart makes by the value's `int`/`double` class, made here by
 * inspecting the value, because JavaScript has only `number`.
 *
 * @param {?number} value
 * @returns {string}
 */
function somFormatNum(value) {
  if (value === null || value === undefined) {
    return '';
  }
  return Number.isInteger(value) ? somFormatInt(value) : somFormatDouble(value);
}

/**
 * Parses a stored string as a boolean — exactly `true`/`false`, else `null`.
 *
 * @param {?string} raw
 * @returns {?boolean}
 */
function somParseBool(raw) {
  raw = somTypedReading(raw);
  if (raw === 'true') {
    return true;
  }
  if (raw === 'false') {
    return false;
  }
  return null;
}

/**
 * Formats a boolean for the store; `null` becomes `''` (clear, D4).
 *
 * @param {?boolean} value
 * @returns {string}
 */
function somFormatBool(value) {
  if (value === null || value === undefined) {
    return '';
  }
  return value ? 'true' : 'false';
}

/**
 * Parses a stored string as an enum constant name against `values` (the
 * field's `enumValues` domain).
 *
 * Returns `null` when absent or not in the domain — a stale/foreign name reads
 * as unset rather than throwing, the same forgiveness the other parsers extend
 * to malformed numbers.
 *
 * @param {?string} raw
 * @param {string[]} values
 * @returns {?string}
 */
function somParseEnumName(raw, values) {
  const name = somTypedReading(raw);
  return name !== null && name !== undefined && values.includes(name) ? name : null;
}

/**
 * Validates an enum constant `name` against `values` before storing.
 *
 * `null`/empty clears (returns `''`); a name outside the domain throws an
 * {@link Error} — writes are strict where reads are forgiving, so a typo cannot
 * enter the store.
 *
 * @param {?string} name
 * @param {string[]} values
 * @returns {string}
 */
function somFormatEnumName(name, values) {
  if (name === null || name === undefined || name === '') {
    return '';
  }
  if (!values.includes(name)) {
    throw new Error(
      `'${name}' is not one of the enum values ${values.join(', ')}`,
    );
  }
  return name;
}

/**
 * The scalar base of a declared field type: `int?` → `int`; `null` stays
 * `null`.
 *
 * @param {?string} typeName
 * @returns {?string}
 */
function somScalarBase(typeName) {
  if (typeName === null || typeName === undefined) {
    return null;
  }
  return typeName.endsWith('?') ? typeName.slice(0, -1) : typeName;
}

/**
 * Whether `raw`, stored in a field declared as `typeName`, is text that type's
 * parser can read.
 *
 * Only `int`, `double`, `num` and `bool` constrain their text; every other type
 * (strings, and enums, whose domain `enumValueUnknown` checks) accepts any
 * text. Empty or absent text is readable: it is how a field is unset. The
 * validator reports a stored value this rejects as `valueTypeMismatch`, the
 * setters refuse to store one, and the typed reads throw on one — so text a
 * typed field cannot read is never silently read as unset.
 *
 * @param {?string} typeName
 * @param {?string} raw
 * @returns {boolean}
 */
function somTypedTextReadable(typeName, raw) {
  raw = somTypedReading(raw);
  if (raw === null || raw === undefined || raw === '') {
    return true;
  }
  switch (somScalarBase(typeName)) {
    case 'int':
      return somParseInt(raw) !== null;
    case 'double':
      return somParseDouble(raw) !== null;
    case 'num':
      return somParseNum(raw) !== null;
    case 'bool':
      return somParseBool(raw) !== null;
    default:
      return true;
  }
}

/**
 * Whether a form field holds a typed value: an enum, or `int`, `double`,
 * `num` or `bool` — the values that read as their old value while marked.
 *
 * @param {?string} typeName
 * @param {string[]} enumValues
 * @returns {boolean}
 */
function somIsTypedField(typeName, enumValues) {
  if (enumValues.length > 0) {
    return true;
  }
  const base = somScalarBase(typeName);
  return base === 'int' || base === 'double' || base === 'num' || base === 'bool';
}

module.exports = {
  somScalarBase,
  somTypedTextReadable,
  somTypedReading,
  somIsTypedField,
  somParseInt,
  somFormatInt,
  somParseDouble,
  somFormatDouble,
  somParseNum,
  somFormatNum,
  somParseBool,
  somFormatBool,
  somParseEnumName,
  somFormatEnumName,
};
