/**
 * Shared typed-value conversion at the store boundary (YRD7) — a faithful port
 * of `tom_som_dart_runtime/lib/src/spec_typed_values.dart` (and the Python
 * `spec_typed_values.py`).
 *
 * A {@link SpecDocument}'s stores hold **plain strings** — that is what the
 * md/yaml serialization writes (`FieldName: value`) and what keeps every
 * language runtime's persistence identical. Typed access therefore converts *at
 * the boundary*: parse on read, format on write. These helpers are that single
 * boundary — the generated typed facades and the generic {@link SpecEditor} call
 * the **same** functions, so a facade is provably a thin layer over the generic
 * API (they cannot disagree on a conversion).
 *
 * Conventions (the typed contract, mirrored by all nine runtimes):
 *
 *   * absent / empty string ⇒ `null` on read; `null` on write ⇒ clear (D4);
 *   * `int` — decimal integer, {@link somParseInt} returns `null` for
 *     non-numeric text;
 *   * `double` — accepts any floating literal (also a plain integer);
 *     formatting always carries a decimal point, so an integral value
 *     round-trips as `2.0` rather than `2` (Dart's `double.toString`).
 *     TypeScript has a single `number` type, so the decimal point cannot be
 *     inferred from the runtime value — the caller picks the formatter from the
 *     *declared* field type;
 *   * `num` — parses to an integer when the text is integral, else a float, and
 *     formats accordingly (Dart's `num.tryParse`), so a `num` field keeps the
 *     narrower rendering when the text carries no fraction;
 *   * `bool` — stored as `true` / `false` (lower case, language-neutral);
 *     parsing accepts exactly those, anything else reads as `null`;
 *   * enums — stored as the constant **name** (e.g. `high`); the generic layer
 *     validates against the field's `enumValues` domain, the generated facade
 *     converts name ⇄ native constant.
 */

/** A decimal integer literal, with the optional sign Dart's `int.parse` takes. */
const _INT_TEXT = /^[+-]?[0-9]+$/;

/** A floating literal, with the optional exponent Dart's `double.parse` takes. */
const _FLOAT_TEXT =
  /^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$/;

/**
 * Whether a rendered number already reads as a floating literal — a decimal
 * point, an exponent, or one of the non-finite spellings (`Infinity`, `NaN`).
 */
const _READS_AS_FLOAT = /[.eEnN]/;

/** Parses a stored string as `int`, or `null` when absent/unparsable. */
export function somParseInt(raw: string | null | undefined): number | null {
  if (raw === null || raw === undefined || raw === '') {
    return null;
  }
  const text = raw.trim();
  return _INT_TEXT.test(text) ? parseInt(text, 10) : null;
}

/** Formats an `int` for the store; `null` becomes `''` (clear, D4). */
export function somFormatInt(value: number | null | undefined): string {
  return value === null || value === undefined ? '' : String(value);
}

/** Parses a stored string as `double`, or `null` when absent/unparsable. */
export function somParseDouble(raw: string | null | undefined): number | null {
  if (raw === null || raw === undefined || raw === '') {
    return null;
  }
  const text = raw.trim();
  return _FLOAT_TEXT.test(text) ? parseFloat(text) : null;
}

/**
 * Formats a `double` for the store; `null` becomes `''` (clear, D4).
 *
 * A `double` always renders with a decimal point (`2.0`), matching Dart's
 * `double.toString` — the store is language-neutral, so the same value must
 * serialize identically everywhere. TypeScript's `String(2)` gives `"2"`, so
 * the point is appended when the rendering carries none.
 */
export function somFormatDouble(value: number | null | undefined): string {
  if (value === null || value === undefined) {
    return '';
  }
  const text = String(value);
  return _READS_AS_FLOAT.test(text) ? text : `${text}.0`;
}

/**
 * Parses a stored string as an integer when the text is integral, else as a
 * float — `null` when absent/unparsable.
 *
 * Mirrors Dart's `num.tryParse`: an integral literal yields an `int`, so a
 * `num` field keeps the narrower value when the text carries no fraction.
 */
export function somParseNum(raw: string | null | undefined): number | null {
  if (raw === null || raw === undefined || raw === '') {
    return null;
  }
  const text = raw.trim();
  if (_INT_TEXT.test(text)) {
    return parseInt(text, 10);
  }
  return _FLOAT_TEXT.test(text) ? parseFloat(text) : null;
}

/**
 * Formats a `num` for the store; `null` becomes `''` (clear, D4).
 *
 * `int` and `double` are the one `number` type here, so the rendering follows
 * the value: an integral value stores as `2`, a fractional one as `2.5`.
 */
export function somFormatNum(value: number | null | undefined): string {
  if (value === null || value === undefined) {
    return '';
  }
  return Number.isInteger(value) ? somFormatInt(value) : somFormatDouble(value);
}

/** Parses a stored string as `bool` — exactly `true`/`false`, else `null`. */
export function somParseBool(raw: string | null | undefined): boolean | null {
  if (raw === 'true') {
    return true;
  }
  if (raw === 'false') {
    return false;
  }
  return null;
}

/** Formats a `bool` for the store; `null` becomes `''` (clear, D4). */
export function somFormatBool(value: boolean | null | undefined): string {
  if (value === null || value === undefined) {
    return '';
  }
  return value ? 'true' : 'false';
}

/**
 * Parses a stored string as an enum constant name against `values` (the field's
 * `enumValues` domain). Returns `null` when absent or not in the domain — a
 * stale/foreign name reads as unset rather than throwing, the same forgiveness
 * the other parsers extend to malformed numbers.
 */
export function somParseEnumName(
  raw: string | null | undefined,
  values: readonly string[],
): string | null {
  return raw !== null && raw !== undefined && values.indexOf(raw) >= 0
    ? raw
    : null;
}

/**
 * Validates an enum constant `name` against `values` before storing.
 *
 * `null`/empty clears (returns `''`); a name outside the domain throws — writes
 * are strict where reads are forgiving, so a typo cannot enter the store.
 */
export function somFormatEnumName(
  name: string | null | undefined,
  values: readonly string[],
): string {
  if (name === null || name === undefined || name === '') {
    return '';
  }
  if (values.indexOf(name) < 0) {
    throw new Error(
      `'${name}' is not one of the enum values ${values.join(', ')}`,
    );
  }
  return name;
}
