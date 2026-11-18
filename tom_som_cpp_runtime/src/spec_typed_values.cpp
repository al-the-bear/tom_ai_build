#include "spec_typed_values.hpp"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <stdexcept>

#include "som_util.hpp"

namespace som {

/* ---- SomValue ----------------------------------------------------------- */

SomValue SomValue::ofInt(long long v) {
  SomValue s;
  s.kind_ = Kind::Int;
  s.integer_ = v;
  return s;
}

SomValue SomValue::ofDouble(double v) {
  SomValue s;
  s.kind_ = Kind::Double;
  s.real_ = v;
  return s;
}

SomValue SomValue::ofBool(bool v) {
  SomValue s;
  s.kind_ = Kind::Bool;
  s.boolean_ = v;
  return s;
}

SomValue SomValue::ofString(std::string v) {
  SomValue s;
  s.kind_ = Kind::Str;
  s.str_ = std::move(v);
  return s;
}

bool SomValue::operator==(const SomValue& other) const {
  /* Int and Double compare numerically (Dart's `num` equality: 2 == 2.0); every
   * other kind only ever equals its own. */
  if (isNum() && other.isNum()) {
    if (isInt() && other.isInt()) {
      return integer_ == other.integer_;
    }
    return numValue() == other.numValue();
  }
  if (kind_ != other.kind_) {
    return false;
  }
  switch (kind_) {
    case Kind::Null:
      return true;
    case Kind::Bool:
      return boolean_ == other.boolean_;
    case Kind::Str:
      return str_ == other.str_;
    default:
      return false;  // Int / Double handled above
  }
}

std::string SomValue::debug() const {
  switch (kind_) {
    case Kind::Null:
      return "null";
    case Kind::Int:
      return formatI64(integer_);
    case Kind::Double:
      return somFormatDouble(real_);
    case Kind::Bool:
      return boolean_ ? "true" : "false";
    case Kind::Str:
      return "\"" + str_ + "\"";
  }
  return "null";
}

/* ---- the canonical number grammar -------------------------------------- */

/* The typed-value reading every runtime shares (decision tspubnondart20 (a),
 * the TypeScript `spec_typed_values.ts` canonical): the stored text is read
 * with its surrounding whitespace trimmed; an int is `^[+-]?[0-9]+$`, a double
 * `^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`. Everything
 * else — NaN, Infinity, hexadecimal, digit separators, the platform extensions
 * std::strtod would let through — is refused, because a spec value is finite. */

namespace {

bool isSpace(char ch) {
  return ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == '\v' ||
         ch == '\f';
}

bool isDigit(char ch) { return ch >= '0' && ch <= '9'; }

std::string trimmed(const std::string& raw) {
  std::size_t b = 0;
  std::size_t e = raw.size();
  while (b < e && isSpace(raw[b])) {
    b++;
  }
  while (e > b && isSpace(raw[e - 1])) {
    e--;
  }
  return raw.substr(b, e - b);
}

/* Whether `s` (already trimmed) is a decimal or exponent literal. */
bool isFloatText(const std::string& s) {
  std::size_t i = 0;
  const std::size_t n = s.size();
  if (i < n && (s[i] == '+' || s[i] == '-')) {
    i++;
  }
  std::size_t digits = 0;
  while (i < n && isDigit(s[i])) {
    i++;
    digits++;
  }
  if (i < n && s[i] == '.') {
    i++;
    while (i < n && isDigit(s[i])) {
      i++;
      digits++;
    }
  }
  if (digits == 0) {
    return false;
  }
  if (i < n && (s[i] == 'e' || s[i] == 'E')) {
    i++;
    if (i < n && (s[i] == '+' || s[i] == '-')) {
      i++;
    }
    if (i == n || !isDigit(s[i])) {
      return false;
    }
    while (i < n && isDigit(s[i])) {
      i++;
    }
  }
  return i == n;
}

}  // namespace

/* ---- int ---------------------------------------------------------------- */

std::optional<long long> somParseInt(const std::string& raw) {
  if (raw.empty()) {
    return std::nullopt;
  }
  /* parseI64 is the runtime's strict base-10 reader (optional sign, then
   * digits only), applied to the trimmed text. */
  return parseI64(trimmed(raw));
}

std::string somFormatInt(const std::optional<long long>& value) {
  return value.has_value() ? formatI64(*value) : std::string();
}

/* ---- double ------------------------------------------------------------- */

std::optional<double> somParseDouble(const std::string& raw) {
  if (raw.empty()) {
    return std::nullopt;
  }
  std::string text = trimmed(raw);
  if (!isFloatText(text)) {
    return std::nullopt;
  }
  /* A literal that overflows to infinity is no value either: a spec value is
   * finite. */
  double v = std::strtod(text.c_str(), nullptr);
  if (!std::isfinite(v)) {
    return std::nullopt;
  }
  return v;
}

std::string somFormatDouble(const std::optional<double>& value) {
  if (!value.has_value()) {
    return std::string();
  }
  double v = *value;
  if (std::isnan(v)) {
    return "NaN";
  }
  if (std::isinf(v)) {
    return v < 0 ? "-Infinity" : "Infinity";
  }
  /* The shortest digit string that parses back to the same double (`%.{p}e`
   * for growing p until strtod agrees), laid out like Dart's double.toString
   * and JavaScript's Number.prototype.toString — fixed notation when v == 0 or
   * 1e-6 <= |v| < 1e21, with `.0` appended when there is no fractional part
   * (`3.0`, `-0.0`, `1000.0`), exponent notation otherwise with an explicit
   * sign and no padding (`1e+21`, `1.5e-300`, `1e-7`). */
  std::string sign = std::signbit(v) ? "-" : "";
  double a = std::fabs(v);
  if (a == 0.0) {
    return sign + "0.0";
  }
  char buf[64];
  for (int prec = 0; prec <= 17; prec++) {
    std::snprintf(buf, sizeof buf, "%.*e", prec, a);
    if (std::strtod(buf, nullptr) == a) {
      break;
    }
  }
  std::string rep = buf;
  std::size_t e = rep.find('e');
  std::string digits;
  for (std::size_t i = 0; i < e; i++) {
    if (rep[i] != '.') {
      digits.push_back(rep[i]);
    }
  }
  while (digits.size() > 1 && digits.back() == '0') {
    digits.pop_back();
  }
  long n = std::strtol(rep.c_str() + e + 1, nullptr, 10) + 1;
  long k = static_cast<long>(digits.size());
  std::string out;
  if (k <= n && n <= 21) {
    out = digits + std::string(static_cast<std::size_t>(n - k), '0') + ".0";
  } else if (0 < n && n <= 21) {
    out = digits.substr(0, static_cast<std::size_t>(n)) + "." +
          digits.substr(static_cast<std::size_t>(n));
  } else if (-6 < n && n <= 0) {
    out = "0." + std::string(static_cast<std::size_t>(-n), '0') + digits;
  } else {
    long x = n - 1;
    std::string exp = (x < 0 ? "-" : "+") + formatI64(x < 0 ? -x : x);
    out = k == 1 ? digits + "e" + exp
                 : digits.substr(0, 1) + "." + digits.substr(1) + "e" + exp;
  }
  return sign + out;
}

/* ---- num ---------------------------------------------------------------- */

SomValue somParseNum(const std::string& raw) {
  if (raw.empty()) {
    return SomValue::null();
  }
  std::optional<long long> asInt = somParseInt(raw);
  if (asInt.has_value()) {
    return SomValue::ofInt(*asInt);
  }
  std::optional<double> asDouble = somParseDouble(raw);
  if (asDouble.has_value()) {
    return SomValue::ofDouble(*asDouble);
  }
  return SomValue::null();
}

std::string somFormatNum(const SomValue& value) {
  if (value.isInt()) {
    return somFormatInt(value.intValue());
  }
  if (value.isDouble()) {
    return somFormatDouble(value.doubleValue());
  }
  return std::string();
}

/* ---- bool --------------------------------------------------------------- */

std::optional<bool> somParseBool(const std::string& raw) {
  if (raw == "true") {
    return true;
  }
  if (raw == "false") {
    return false;
  }
  return std::nullopt;
}

std::string somFormatBool(const std::optional<bool>& value) {
  if (!value.has_value()) {
    return std::string();
  }
  return *value ? "true" : "false";
}

/* ---- enum names --------------------------------------------------------- */

std::optional<std::string> somParseEnumName(
    const std::string& raw, const std::vector<std::string>& values) {
  if (raw.empty()) {
    return std::nullopt;
  }
  if (std::find(values.begin(), values.end(), raw) == values.end()) {
    return std::nullopt;
  }
  return raw;
}

std::string somFormatEnumName(const std::optional<std::string>& name,
                              const std::vector<std::string>& values) {
  if (!name.has_value() || name->empty()) {
    return std::string();
  }
  if (std::find(values.begin(), values.end(), *name) == values.end()) {
    std::string domain;
    for (std::size_t i = 0; i < values.size(); i++) {
      if (i > 0) {
        domain += ", ";
      }
      domain += values[i];
    }
    throw std::invalid_argument("\"" + *name +
                                "\" is not one of the enum values " + domain);
  }
  return *name;
}

/* ---- typed-text readability (valueTypeMismatch) ------------------------ */

std::string somScalarBase(const std::string& typeName) {
  if (!typeName.empty() && typeName.back() == '?') {
    return typeName.substr(0, typeName.size() - 1);
  }
  return typeName;
}

bool somTypedTextReadable(const std::string& typeName, const std::string& raw) {
  if (raw.empty()) {
    return true;
  }
  const std::string base = somScalarBase(typeName);
  if (base == "int") {
    return somParseInt(raw).has_value();
  }
  if (base == "double") {
    return somParseDouble(raw).has_value();
  }
  if (base == "num") {
    return !somParseNum(raw).isNull();
  }
  if (base == "bool") {
    return somParseBool(raw).has_value();
  }
  return true;
}

}  // namespace som
