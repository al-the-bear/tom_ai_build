/* spec_typed_values — shared typed-value conversion at the store boundary
 * (YRD7), an idiomatic-C++ port of the Dart `spec_typed_values` library.
 *
 * A SpecDocument's stores hold **plain strings** — that is what the md/yaml
 * serialization writes (`FieldName: value`) and what keeps every language
 * runtime's persistence identical. Typed access therefore converts *at the
 * boundary*: parse on read, format on write. These helpers are that single
 * boundary — the generated typed facades and the generic SpecEditor call the
 * **same** functions, so a facade is provably a thin layer over the generic API
 * (they cannot disagree on a conversion).
 *
 * Conventions (the typed contract, mirrored by all nine runtimes):
 *   - absent / empty string => "no value" on read; no value on write => clear
 *     (D4);
 *   - `int` — decimal integer (optional sign, digits only); somParseInt yields
 *     no value for anything else;
 *   - `double` — accepts any parsable floating literal (also a plain integer);
 *     formatting always carries a decimal point, so an integral value
 *     round-trips as `2.0` rather than `2` (Dart's `double.toString`);
 *   - `num` — an integral literal keeps the narrower `int` shape, everything
 *     else becomes a `double` (Dart's `num.tryParse`);
 *   - `bool` — stored as `true` / `false` (lower case, language-neutral);
 *     parsing accepts exactly those, anything else reads as no value;
 *   - enums — stored as the constant **name** (e.g. `high`); the generic layer
 *     validates against the field's `enumValues` domain, the generated facade
 *     converts name <-> native constant.
 *
 * C++ has no dynamic `Object?`, so the typed positions travel in `SomValue`, a
 * small tagged union. Keeping the tag explicit is what preserves the
 * distinctions the contract rests on — the integer `2` is not the double `2.0`,
 * and the bool `true` is not the string `"true"`.
 */
#ifndef SPEC_TYPED_VALUES_HPP
#define SPEC_TYPED_VALUES_HPP

#include <optional>
#include <string>
#include <vector>

namespace som {

/* ---- SomValue — the tagged value the generic typed surface travels in --- */

/* A dynamically-typed value at the store boundary: nothing, an integer, a
 * double, a bool, or a string.
 *
 * The default-constructed value is the "no value" case (an unset leaf, or a
 * write that clears). Numeric comparison across Int/Double follows Dart's
 * `num` equality (`2 == 2.0`); every other kind compares only with its own. */
class SomValue {
 public:
  enum class Kind { Null, Int, Double, Bool, Str };

  SomValue() = default;  // the "no value" case

  static SomValue null() { return SomValue(); }
  static SomValue ofInt(long long v);
  static SomValue ofDouble(double v);
  static SomValue ofBool(bool v);
  static SomValue ofString(std::string v);

  Kind kind() const { return kind_; }
  bool isNull() const { return kind_ == Kind::Null; }
  bool isInt() const { return kind_ == Kind::Int; }
  bool isDouble() const { return kind_ == Kind::Double; }
  /* Whether this holds a number of either width — the `num` position. */
  bool isNum() const { return isInt() || isDouble(); }
  bool isBool() const { return kind_ == Kind::Bool; }
  bool isString() const { return kind_ == Kind::Str; }

  long long intValue() const { return integer_; }
  double doubleValue() const { return real_; }
  /* The value widened to double; valid for Int and Double. */
  double numValue() const { return isInt() ? static_cast<double>(integer_) : real_; }
  bool boolValue() const { return boolean_; }
  const std::string& stringValue() const { return str_; }

  bool operator==(const SomValue& other) const;
  bool operator!=(const SomValue& other) const { return !(*this == other); }

  /* A human-readable rendering for test/diagnostic messages — `null`, a
   * number, `true`/`false`, or the quoted string. */
  std::string debug() const;

 private:
  Kind kind_ = Kind::Null;
  long long integer_ = 0;
  double real_ = 0.0;
  bool boolean_ = false;
  std::string str_;
};

/* ---- the ten boundary helpers ------------------------------------------- */

/* Parses a stored string as `int`, or no value when absent/unparsable. */
std::optional<long long> somParseInt(const std::string& raw);

/* Formats an `int` for the store; no value becomes "" (clear, D4). */
std::string somFormatInt(const std::optional<long long>& value);

/* Parses a stored string as `double`, or no value when absent/unparsable. */
std::optional<double> somParseDouble(const std::string& raw);

/* Formats a `double` for the store; no value becomes "" (clear, D4).
 *
 * The rendering is the shortest text that reads back as the same double, and it
 * always carries a decimal point or an exponent — an integral `2` stores as
 * `2.0`, never `2`, because the store is language-neutral and the same value
 * must serialize identically in every runtime. */
std::string somFormatDouble(const std::optional<double>& value);

/* Parses a stored string as `num`: an integral literal yields an Int, anything
 * else parsable a Double, and unparsable text no value. */
SomValue somParseNum(const std::string& raw);

/* Formats a `num` for the store; no value becomes "" (clear, D4). An Int keeps
 * the integer rendering, a Double the decimal-point one. */
std::string somFormatNum(const SomValue& value);

/* Parses a stored string as `bool` — exactly `true`/`false`, else no value. */
std::optional<bool> somParseBool(const std::string& raw);

/* Formats a `bool` for the store; no value becomes "" (clear, D4). */
std::string somFormatBool(const std::optional<bool>& value);

/* Parses a stored string as an enum constant name against `values` (the field's
 * `enumValues` domain). Returns no value when absent or outside the domain — a
 * stale/foreign name reads as unset rather than throwing, the same forgiveness
 * the other parsers extend to malformed numbers. */
std::optional<std::string> somParseEnumName(const std::string& raw,
                                            const std::vector<std::string>& values);

/* Validates an enum constant `name` against `values` before storing.
 *
 * No value / empty clears (returns ""); a name outside the domain throws
 * std::invalid_argument — writes are strict where reads are forgiving, so a
 * typo cannot enter the store. */
std::string somFormatEnumName(const std::optional<std::string>& name,
                              const std::vector<std::string>& values);

}  // namespace som

#endif  // SPEC_TYPED_VALUES_HPP
