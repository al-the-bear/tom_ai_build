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
//   - int — decimal integer, SomParseInt reports unset for non-numeric text;
//   - double — accepts any float literal (also a plain integer); formatting
//     always carries a decimal point, so an integral value round-trips as `2.0`
//     rather than `2` (Dart's `double.toString`);
//   - num — parses to an int when the text is integral, else a float64, and
//     formats the same way round;
//   - bool — stored as `true` / `false` (lower case, language-neutral); parsing
//     accepts exactly those, anything else reads as unset;
//   - enums — stored as the constant **name** (e.g. `high`); the generic layer
//     validates against the field's EnumValues domain, the generated facade
//     converts name ⇄ native constant.
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
	"strconv"
	"strings"
)

// SomParseInt parses a stored string as an int, with ok=false when the text is
// absent (empty) or not a decimal integer.
func SomParseInt(raw string) (int, bool) {
	if raw == "" {
		return 0, false
	}
	n, err := strconv.ParseInt(raw, 10, 64)
	if err != nil {
		return 0, false
	}
	return int(n), true
}

// SomFormatInt formats an int for the store.
func SomFormatInt(value int) string { return itoa(value) }

// SomParseDouble parses a stored string as a float64, with ok=false when the
// text is absent (empty) or not a float literal. A plain integer parses fine —
// `2` reads as 2.0.
func SomParseDouble(raw string) (float64, bool) {
	if raw == "" {
		return 0, false
	}
	f, err := strconv.ParseFloat(raw, 64)
	if err != nil {
		return 0, false
	}
	return f, true
}

// SomFormatDouble formats a float64 for the store.
//
// The result always carries a decimal point (`2` formats as `2.0`), matching
// Dart's `double.toString`: the store is language-neutral, so the same value
// must serialize identically everywhere — and Go's shortest-round-trip
// formatting would otherwise drop the point and make an integral double
// indistinguishable from an int in the persisted text.
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
	text := strconv.FormatFloat(value, 'g', -1, 64)
	if strings.ContainsAny(text, ".eE") {
		return text
	}
	return text + ".0"
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
	if isIntegral(value) {
		return SomFormatInt(int(value))
	}
	return SomFormatDouble(value)
}

// SomParseBool parses a stored string as a bool — exactly `true` / `false`,
// with ok=false for anything else.
func SomParseBool(raw string) (bool, bool) {
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
