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
/// Conventions (the typed contract):
///   * absent / empty string ⇒ `null` on read; `null` on write ⇒ clear (D4);
///   * `int`, `double` and `num` text is read with surrounding whitespace
///     trimmed (the TypeScript reading is canonical for every runtime);
///   * `int` — an optional sign and decimal digits; `somParseInt` returns
///     `null` for anything else (hexadecimal `0x10`, a fraction, digit
///     separators), although Dart's `int.tryParse` would accept a hex literal;
///   * `double` — a decimal or exponent literal (`5`, `1.`, `.5`, `-2.5e2`);
///     `NaN`, `Infinity` and every other spelling Dart's `double.tryParse`
///     accepts beyond that grammar read as `null`, because a spec value is
///     finite. Formatting uses the value's shortest `toString()`, which
///     **always shows a fraction or an exponent** (`1.0`, never `1`). That is
///     the whole reason this is a shared boundary rather than each language's
///     default number-to-string: a runtime with one numeric type writes `1`
///     and silently diverges in every serialized document;
///   * `num` — an `int` when the text reads as one, else a `double` by the
///     same grammar;
///   * `bool` — stored as `true` / `false`; parsing accepts exactly those
///     (case-sensitive), anything else reads as `null`;
///   * enums — stored as the constant **name** (e.g. `high`); the generic
///     layer validates against the field's `enumValues` domain, the generated
///     facade converts name ⇄ native constant.
///
///   * a typed value holding inline marks (SOM §11.9.3, a change under review:
///     `{~~ 30 ~> 15 ~~}`) reads as its **old** value, every mark rejected,
///     until the marks are decided ([somTypedReading]).
///
/// All nine runtimes carry these helpers, and the conventions above are
/// replayed against each of them by
/// `tom_som_conformance/corpus/editor_cases.json`.
library;

import 'spec_review_annotations.dart' show applyInlineMarksText;

/// The reading of a typed value under review: [raw] with every inline mark
/// rejected (its old value), trimmed; [raw] itself when it holds no mark.
///
/// A typed value marked as a change (SOM §11.9.3) is the old value until the
/// change is accepted: the parsers below, the validator and every typed read
/// see that value, never the markup.
String? somTypedReading(String? raw) {
  if (raw == null || !raw.contains('{')) return raw;
  final old = applyInlineMarksText(raw, accept: false);
  return old == raw ? raw : old.trim();
}

/// A decimal integer literal: an optional sign and digits.
final RegExp _intText = RegExp(r'^[+-]?[0-9]+$');

/// A floating literal: digits with an optional fraction, or a bare fraction,
/// and an optional exponent.
final RegExp _floatText = RegExp(
  r'^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$',
);

/// Parses a stored string as `int`, or `null` when absent/unparsable.
///
/// The text is trimmed; only an optional sign and decimal digits are read.
int? somParseInt(String? raw) {
  raw = somTypedReading(raw);
  if (raw == null || raw.isEmpty) return null;
  final text = raw.trim();
  return _intText.hasMatch(text) ? int.tryParse(text) : null;
}

/// Formats an `int` for the store; `null` becomes `''` (clear, D4).
String somFormatInt(int? value) => value?.toString() ?? '';

/// Parses a stored string as `double`, or `null` when absent/unparsable.
///
/// The text is trimmed; only a decimal or exponent literal is read — `NaN`,
/// `Infinity` and hexadecimal text are refused.
double? somParseDouble(String? raw) {
  raw = somTypedReading(raw);
  if (raw == null || raw.isEmpty) return null;
  final text = raw.trim();
  return _floatText.hasMatch(text) ? _finite(double.tryParse(text)) : null;
}

/// Formats a `double` for the store; `null` becomes `''` (clear, D4).
///
/// Dart's `double.toString` always shows a fraction or an exponent (`1.0`).
String somFormatDouble(double? value) => value?.toString() ?? '';

/// Parses a stored string as `num`, or `null` when absent/unparsable.
///
/// The text is trimmed; it reads as an `int` when it is an integer literal,
/// else as a `double` by [somParseDouble]'s grammar.
num? somParseNum(String? raw) {
  raw = somTypedReading(raw);
  if (raw == null || raw.isEmpty) return null;
  final text = raw.trim();
  if (_intText.hasMatch(text)) {
    return int.tryParse(text) ?? _finite(double.parse(text));
  }
  return _floatText.hasMatch(text) ? _finite(double.tryParse(text)) : null;
}

/// Formats a `num` for the store; `null` becomes `''` (clear, D4).
String somFormatNum(num? value) => value?.toString() ?? '';

/// Parses a stored string as `bool` — exactly `true`/`false`, else `null`.
bool? somParseBool(String? raw) {
  raw = somTypedReading(raw);
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
String? somParseEnumName(String? raw, List<String> values) {
  final name = somTypedReading(raw);
  return (name != null && values.contains(name)) ? name : null;
}

/// Validates an enum constant [name] against [values] before storing.
///
/// `null`/empty clears (returns `''`); a name outside the domain throws
/// [ArgumentError] — writes are strict where reads are forgiving, so a typo
/// cannot enter the store.
String somFormatEnumName(String? name, List<String> values) {
  if (name == null || name.isEmpty) return '';
  if (!values.contains(name)) {
    throw ArgumentError.value(
      name,
      'name',
      'not one of the enum values ${values.join(', ')}',
    );
  }
  return name;
}

/// The scalar base of a declared field type: `int?` → `int`, `null` stays
/// `null`.
String? somScalarBase(String? typeName) {
  if (typeName == null) return null;
  return typeName.endsWith('?')
      ? typeName.substring(0, typeName.length - 1)
      : typeName;
}

/// Whether [raw], stored in a field declared as [typeName], is text that
/// type's parser can read.
///
/// Only `int`, `double`, `num` and `bool` constrain their text; every other
/// type (strings, and enums, whose domain `enumValueUnknown` checks) accepts
/// any text. Empty or absent text is readable: it is how a field is unset.
/// The validator reports a stored value this rejects as `valueTypeMismatch`,
/// the setters refuse to store one, and the typed reads throw on one — so
/// text a typed field cannot read is never silently read as unset.
bool somTypedTextReadable(String? typeName, String? raw) {
  raw = somTypedReading(raw);
  if (raw == null || raw.isEmpty) return true;
  switch (somScalarBase(typeName)) {
    case 'int':
      return somParseInt(raw) != null;
    case 'double':
      return somParseDouble(raw) != null;
    case 'num':
      return somParseNum(raw) != null;
    case 'bool':
      return somParseBool(raw) != null;
    default:
      return true;
  }
}

/// Whether a form field holds a typed value: an enum, or `int`, `double`,
/// `num` or `bool` — the values that read as their old value while marked.
bool somIsTypedField(String? typeName, List<String> enumValues) =>
    enumValues.isNotEmpty ||
    const {'int', 'double', 'num', 'bool'}.contains(somScalarBase(typeName));

/// [value] when it is finite, else `null`: a literal that overflows (`1e400`)
/// is no value, as `NaN` and `Infinity` are not (a specification value is
/// finite).
double? _finite(double? value) =>
    value != null && value.isFinite ? value : null;
