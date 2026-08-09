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
 *   * `int` — decimal integer, {@link somParseInt} returns `null` for
 *     non-numeric text (and for a fractional literal — `12.5` is not an `int`);
 *   * `double` — accepts any parsable floating literal (also plain integers);
 *     formatting always carries a decimal point, so an integral value
 *     round-trips as `2.0` rather than `2` (Dart's `double.toString`);
 *   * `num` — an integral literal parses to an integer, everything else to a
 *     float; JavaScript has one numeric type, so formatting decides by
 *     inspecting the value (`Number.isInteger`) rather than by its class;
 *   * `bool` — stored as `true` / `false` (lower case, language-neutral);
 *     parsing accepts exactly those, anything else reads as `null`;
 *   * enums — stored as the constant **name** (e.g. `high`); the generic layer
 *     validates against the field's `enumValues` domain, the generated facade
 *     converts name ⇄ native constant.
 *
 * The parsers match on an explicit grammar rather than deferring to `Number()`
 * / `parseInt()`, whose coercions (`''` → `0`, `'0x10'` → `16`, a trailing
 * `'12abc'` → `12`) would silently admit text the reference runtimes reject.
 */

/** The `int` grammar: an optionally-signed run of decimal digits. */
const _INT_PATTERN = /^[+-]?[0-9]+$/;

/** The `double` grammar: a decimal literal with optional fraction/exponent. */
const _DOUBLE_PATTERN =
  /^[+-]?(?:[0-9]+\.?[0-9]*|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$/;

/** The non-finite literals `double.tryParse` accepts alongside the grammar. */
const _DOUBLE_LITERALS = new Map([
  ['NaN', NaN],
  ['Infinity', Infinity],
  ['+Infinity', Infinity],
  ['-Infinity', -Infinity],
]);

/**
 * Parses a stored string as an integer, or `null` when absent/unparsable.
 *
 * @param {?string} raw
 * @returns {?number}
 */
function somParseInt(raw) {
  if (raw === null || raw === undefined || raw === '') {
    return null;
  }
  return _INT_PATTERN.test(raw) ? parseInt(raw, 10) : null;
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
 * absent/unparsable.
 *
 * @param {?string} raw
 * @returns {?number}
 */
function somParseDouble(raw) {
  if (raw === null || raw === undefined || raw === '') {
    return null;
  }
  if (_DOUBLE_LITERALS.has(raw)) {
    return _DOUBLE_LITERALS.get(raw);
  }
  return _DOUBLE_PATTERN.test(raw) ? Number(raw) : null;
}

/**
 * Formats a `double` for the store; `null` becomes `''` (clear, D4).
 *
 * A `double` always renders with a decimal point (`2.0`), matching Dart's
 * `double.toString` — the store is language-neutral, so the same value must
 * serialize identically everywhere. JavaScript has a single numeric type and
 * would render `2`, so the point is forced here; the caller decides that the
 * value *is* a `double` from the field's declared type.
 *
 * @param {?number} value
 * @returns {string}
 */
function somFormatDouble(value) {
  if (value === null || value === undefined) {
    return '';
  }
  const text = String(value);
  if (!Number.isFinite(value) || text.includes('.') || text.includes('e')) {
    return text;
  }
  return `${text}.0`;
}

/**
 * Parses a stored string as an integer when the text is integral, else as a
 * floating-point number; `null` when absent/unparsable.
 *
 * Mirrors Dart's `num.tryParse`: an integral literal yields an `int`, so `num`
 * fields keep the narrower type when the text carries no fraction. JavaScript
 * has one numeric type, so the distinction survives only in the value itself.
 *
 * @param {?string} raw
 * @returns {?number}
 */
function somParseNum(raw) {
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
  return raw !== null && raw !== undefined && values.includes(raw) ? raw : null;
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

module.exports = {
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
