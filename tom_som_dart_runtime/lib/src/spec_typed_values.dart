/// Shared typed-value conversion at the store boundary (YRD7).
///
/// A [SpecDocument]'s stores hold **plain strings** — that is what the md/yaml
/// serialization writes (`FieldName: value`) and what keeps every language
/// runtime's persistence identical. Typed access therefore converts *at the
/// boundary*: parse on read, format on write. These helpers are that single
/// boundary — the generated typed facades and the generic [SpecEditor] call
/// the **same** functions, so a facade is provably a thin layer over the
/// generic API (they cannot disagree on a conversion).
///
/// Conventions (the typed contract, mirrored by all nine runtimes):
///   * absent / empty string ⇒ `null` on read; `null` on write ⇒ clear (D4);
///   * `int` — decimal integer, `somParseInt` returns `null` for non-numeric;
///   * `double` — accepts any Dart-parsable floating literal (also plain
///     integers); formatting uses the value's shortest `toString()`;
///   * `bool` — stored as `true` / `false`; parsing accepts exactly those
///     (case-sensitive), anything else reads as `null`;
///   * enums — stored as the constant **name** (e.g. `high`); the generic
///     layer validates against the field's `enumValues` domain, the generated
///     facade converts name ⇄ native constant.
library;

/// Parses a stored string as `int`, or `null` when absent/unparsable.
int? somParseInt(String? raw) =>
    (raw == null || raw.isEmpty) ? null : int.tryParse(raw);

/// Formats an `int` for the store; `null` becomes `''` (clear, D4).
String somFormatInt(int? value) => value?.toString() ?? '';

/// Parses a stored string as `double`, or `null` when absent/unparsable.
double? somParseDouble(String? raw) =>
    (raw == null || raw.isEmpty) ? null : double.tryParse(raw);

/// Formats a `double` for the store; `null` becomes `''` (clear, D4).
String somFormatDouble(double? value) => value?.toString() ?? '';

/// Parses a stored string as `num`, or `null` when absent/unparsable.
num? somParseNum(String? raw) =>
    (raw == null || raw.isEmpty) ? null : num.tryParse(raw);

/// Formats a `num` for the store; `null` becomes `''` (clear, D4).
String somFormatNum(num? value) => value?.toString() ?? '';

/// Parses a stored string as `bool` — exactly `true`/`false`, else `null`.
bool? somParseBool(String? raw) {
  if (raw == 'true') return true;
  if (raw == 'false') return false;
  return null;
}

/// Formats a `bool` for the store; `null` becomes `''` (clear, D4).
String somFormatBool(bool? value) => value?.toString() ?? '';

/// Parses a stored string as an enum constant name against [values] (the
/// field's `enumValues` domain). Returns `null` when absent or not in the
/// domain — a stale/foreign name reads as unset rather than throwing, the
/// same forgiveness the other parsers extend to malformed numbers.
String? somParseEnumName(String? raw, List<String> values) =>
    (raw != null && values.contains(raw)) ? raw : null;

/// Validates an enum constant [name] against [values] before storing.
///
/// `null`/empty clears (returns `''`); a name outside the domain throws
/// [ArgumentError] — writes are strict where reads are forgiving, so a typo
/// cannot enter the store.
String somFormatEnumName(String? name, List<String> values) {
  if (name == null || name.isEmpty) return '';
  if (!values.contains(name)) {
    throw ArgumentError.value(
        name, 'name', 'not one of the enum values ${values.join(', ')}');
  }
  return name;
}
