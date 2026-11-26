package somruntime

// spec_typed_values.go — shared typed-value conversion at the store boundary
// (YRD7), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_typed_values.dart` (and the Python
// `spec_typed_values.py`).
//
// A SpecDocument's stores hold **plain strings** — that is what the md/yaml
// serialization writes (`FieldName: value`) and what keeps every language
// runtime's persistence identical. Typed access therefore converts *at the
// boundary*: parse on read, format on write. These helpers are that single
// boundary — the generated typed facades and the generic SpecEditor call the
// **same** functions, so a facade is provably a thin layer over the generic API
// (they cannot disagree on a conversion).
//
// Conventions (the typed contract, mirrored by all nine runtimes):
//
//   - absent / empty string ⇒ unset on read; the empty string on write ⇒ clear
//     (D4), which the stores treat as a delete;
//   - int, double and num read their text with surrounding whitespace trimmed
//     (the canonical reading of `tom_som_typescript_runtime`'s
//     `spec_typed_values.ts`, shared corpus `typed_value_cases.json`);
//   - int — an optional sign and decimal digits (`^[+-]?[0-9]+$`), SomParseInt
//     reports unset for anything else;
//   - double — a decimal or exponent literal
//     (`^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`, also a
//     plain integer); NaN, Infinity, hexadecimal and digit separators — which
//     strconv.ParseFloat would take — are refused, because a spec value is
//     finite; formatting always carries a fraction or an exponent, so an
//     integral value round-trips as `2.0` rather than `2`;
//   - num — parses to an int when the text is integral, else a float64, and
//     formats the same way round;
//   - bool — stored as `true` / `false` (lower case, language-neutral); parsing
//     accepts exactly those, anything else reads as unset;
//   - enums — stored as the constant **name** (e.g. `high`); the generic layer
//     validates against the field's EnumValues domain, the generated facade
//     converts name ⇄ native constant;
//   - a typed value holding inline marks (SOM §11.9.3, a change under review:
//     `{~~ 30 ~> 15 ~~}`) reads as its **old** value, every mark rejected,
//     until the marks are decided (SomTypedReading).
//
// # Go's stand-in for the other ports' null
//
// Dart's `int?` / Python's `Optional[int]` have no Go equivalent, so the parse
// helpers return `(value, ok)` — the same shape SpecDocument.Content and
// SpecDocument.FormField already use for "no value stored". The format helpers
// take the value itself: "clear" is not a formattable value here but the empty
// string the caller stores, which is exactly what SpecEditor writes for a nil.

import (
	"math"
	"regexp"
	"strconv"
	"strings"
)

// SomTypedReading is the reading of a typed value under review: raw with every
// inline mark rejected (its old value), trimmed; raw itself when it holds no
// mark.
//
// A typed value marked as a change (SOM §11.9.3) is the old value until the
// change is accepted: the parsers below, the validator and every typed read
// see that value, never the markup.
func SomTypedReading(raw string) string {
	if !strings.Contains(raw, "{") {
		return raw
	}
	old := ApplyInlineMarksText(raw, false)
	if old == raw {
		return raw
	}
	return strings.TrimSpace(old)
}

// SomIsTypedField reports whether a form field holds a typed value: an enum,
// or `int`, `double`, `num` or `bool` — the values that read as their old
// value while marked.
func SomIsTypedField(typeName string, enumValues []string) bool {
	if len(enumValues) > 0 {
		return true
	}
	switch scalarBase(typeName) {
	case "int", "double", "num", "bool":
		return true
	}
	return false
}

// intText is a decimal integer literal with an optional sign.
var intText = regexp.MustCompile(`^[+-]?[0-9]+$`)

// floatText is a decimal literal with an optional exponent. strconv.ParseFloat
// alone also takes NaN, Inf, hexadecimal floats and underscores, which a SOM
// value never is.
var floatText = regexp.MustCompile(`^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`)

// SomParseInt parses a stored string as an int, with ok=false when the text is
// absent (empty) or, with surrounding whitespace trimmed, not an optional sign
// and decimal digits.
func SomParseInt(raw string) (int, bool) {
	raw = SomTypedReading(raw)
	if raw == "" {
		return 0, false
	}
	text := strings.TrimSpace(raw)
	if !intText.MatchString(text) {
		return 0, false
	}
	n, err := strconv.ParseInt(text, 10, 64)
	if err != nil {
		return 0, false
	}
	return int(n), true
}

// SomFormatInt formats an int for the store.
func SomFormatInt(value int) string { return itoa(value) }

// SomParseDouble parses a stored string as a float64, with ok=false when the
// text is absent (empty) or, with surrounding whitespace trimmed, not a decimal
// or exponent literal. A plain integer parses fine — `2` reads as 2.0; NaN,
// Infinity, hexadecimal and digit separators are refused.
func SomParseDouble(raw string) (float64, bool) {
	raw = SomTypedReading(raw)
	if raw == "" {
		return 0, false
	}
	text := strings.TrimSpace(raw)
	if !floatText.MatchString(text) {
		return 0, false
	}
	f, err := strconv.ParseFloat(text, 64)
	if err != nil {
		return 0, false
	}
	return f, true
}

// SomFormatDouble formats a float64 for the store.
//
// The result always carries a fraction or an exponent (`2` formats as `2.0`,
// 1e21 as `1e+21`), matching Dart's `double.toString`: the store is
// language-neutral, so the same value must serialize identically everywhere —
// and Go's shortest-round-trip formatting would otherwise drop the point and
// make an integral double indistinguishable from an int in the persisted text.
// Non-finite values are `NaN`, `Infinity` and `-Infinity`.
func SomFormatDouble(value float64) string {
	if math.IsNaN(value) {
		return "NaN"
	}
	if math.IsInf(value, 1) {
		return "Infinity"
	}
	if math.IsInf(value, -1) {
		return "-Infinity"
	}
	// One layout in every runtime (decision tspubnondart29 (a)): the shortest
	// digits in JavaScript's Number toString layout, `.0` on a whole value
	// (10000000.0, 1e-7, 1e+21) — the review pass's float form.
	return FormatYamlFloat(value)
}

// SomParseNum parses a stored string as an int when the text is integral, else
// as a float64, with ok=false when it is absent or unparsable. The value is
// returned as an `any` holding an `int` or a `float64` — Go has no `num` type,
// so the narrowing Dart's `num.tryParse` performs shows up in the dynamic type.
func SomParseNum(raw string) (any, bool) {
	if n, ok := SomParseInt(raw); ok {
		return n, true
	}
	if f, ok := SomParseDouble(raw); ok {
		return f, true
	}
	return nil, false
}

// SomFormatNum formats a num for the store: an integral value renders as an int
// (`2`), a fractional one as a double (`2.5`) — the mirror of SomParseNum's
// narrowing. float64 is the widest numeric carrier Go offers, so it is what the
// boundary takes on write.
func SomFormatNum(value float64) string {
	// A whole value outside the int64 range is written as a double: int()
	// would saturate it (1e21 became 9223372036854775807).
	if isIntegral(value) && value >= -9223372036854775808 && value < 9223372036854775808 {
		return SomFormatInt(int(value))
	}
	return SomFormatDouble(value)
}

// SomParseBool parses a stored string as a bool — exactly `true` / `false`,
// with ok=false for anything else.
func SomParseBool(raw string) (bool, bool) {
	raw = SomTypedReading(raw)
	if raw == "true" {
		return true, true
	}
	if raw == "false" {
		return false, true
	}
	return false, false
}

// SomFormatBool formats a bool for the store as lower-case `true` / `false`.
func SomFormatBool(value bool) string {
	if value {
		return "true"
	}
	return "false"
}

// SomParseEnumName parses a stored string as an enum constant name against
// values (the field's EnumValues domain), with ok=false when it is absent or
// not in the domain — a stale/foreign name reads as unset rather than erroring,
// the same forgiveness the other parsers extend to malformed numbers.
func SomParseEnumName(raw string, values []string) (string, bool) {
	raw = SomTypedReading(raw)
	if raw == "" {
		return "", false
	}
	for _, v := range values {
		if v == raw {
			return raw, true
		}
	}
	return "", false
}

// SomFormatEnumName validates an enum constant name against values before
// storing.
//
// An empty name clears (returns ""); a name outside the domain returns an
// *EnumNameOutOfDomain — writes are strict where reads are forgiving, so a typo
// cannot enter the store.
func SomFormatEnumName(name string, values []string) (string, error) {
	if name == "" {
		return "", nil
	}
	if _, ok := SomParseEnumName(name, values); !ok {
		return "", &EnumNameOutOfDomain{Name: name, Values: values}
	}
	return name, nil
}

// EnumNameOutOfDomain is returned when a write presents an enum constant name
// the field's EnumValues domain does not contain.
type EnumNameOutOfDomain struct {
	Name   string
	Values []string
}

// Error implements the error interface.
func (e *EnumNameOutOfDomain) Error() string {
	return "'" + e.Name + "' is not one of the enum values " +
		strings.Join(e.Values, ", ")
}

// isIntegral reports whether value carries no fractional part and is finite —
// the test that decides whether a num renders as an int and whether a Go
// dynamic float64 may stand in for an int field.
func isIntegral(value float64) bool {
	return !math.IsNaN(value) && !math.IsInf(value, 0) && value == math.Trunc(value)
}

// SomScalarBase returns the scalar base of a declared field type: `int?` →
// `int`; "" (no declared type) stays "".
func SomScalarBase(typeName string) string { return scalarBase(typeName) }

// SomTypedTextReadable reports whether raw, stored in a field declared as
// typeName, is text that type's parser can read.
//
// Only `int`, `double`, `num` and `bool` constrain their text; every other
// type (strings, and enums, whose domain `enumValueUnknown` checks) accepts
// any text. Empty text is readable: it is how a field is unset. The validator
// reports a stored value this rejects as `valueTypeMismatch`, the setters
// refuse to store one, and the typed reads return an error for one — so text
// a typed field cannot read is never silently read as unset.
func SomTypedTextReadable(typeName, raw string) bool {
	raw = SomTypedReading(raw)
	if raw == "" {
		return true
	}
	var ok bool
	switch scalarBase(typeName) {
	case "int":
		_, ok = SomParseInt(raw)
	case "double":
		_, ok = SomParseDouble(raw)
	case "num":
		_, ok = SomParseNum(raw)
	case "bool":
		_, ok = SomParseBool(raw)
	default:
		return true
	}
	return ok
}
