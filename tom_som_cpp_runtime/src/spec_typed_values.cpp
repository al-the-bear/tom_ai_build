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

/* ---- int ---------------------------------------------------------------- */

std::optional<long long> somParseInt(const std::string& raw) {
  if (raw.empty()) {
    return std::nullopt;
  }
  /* parseI64 is the runtime's own strict base-10 reader: optional sign then
   * digits only, so hex / trailing text / whitespace all read as "no value"
   * exactly as the Dart and Python ports' `int.tryParse` / `int(raw, 10)` do. */
  return parseI64(raw);
}

std::string somFormatInt(const std::optional<long long>& value) {
  return value.has_value() ? formatI64(*value) : std::string();
}

/* ---- double ------------------------------------------------------------- */

/* Reads `raw` as a floating literal, rejecting anything std::strtod would
 * accept but the reference runtimes would not (hex literals, trailing text,
 * surrounding whitespace). */
static std::optional<double> parseFloatingLiteral(const std::string& raw) {
  if (raw.empty()) {
    return std::nullopt;
  }
  /* strtod skips leading whitespace and accepts 0x… hex floats; neither is a
   * literal any other runtime accepts. */
  if (std::isspace(static_cast<unsigned char>(raw.front())) != 0 ||
      raw.find('x') != std::string::npos || raw.find('X') != std::string::npos) {
    return std::nullopt;
  }
  const char* begin = raw.c_str();
  char* end = nullptr;
  double v = std::strtod(begin, &end);
  if (end == begin || *end != '\0') {
    return std::nullopt;
  }
  return v;
}

std::optional<double> somParseDouble(const std::string& raw) {
  return parseFloatingLiteral(raw);
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
    return v > 0 ? "Infinity" : "-Infinity";
  }
  /* The shortest %g rendering that reads back as the same double — the C++
   * equivalent of Dart's shortest `double.toString()`. Neither std::to_string
   * (which pads to "2.000000") nor operator<< (which drops to "2") produces it. */
  char buf[64];
  for (int precision = 1; precision <= 17; precision++) {
    std::snprintf(buf, sizeof(buf), "%.*g", precision, v);
    if (std::strtod(buf, nullptr) == v) {
      break;
    }
  }
  std::string text(buf);
  /* An integral value must still read as a double, so give it a fraction: `2`
   * becomes `2.0`. An exponent form already reads as one. */
  if (text.find('.') == std::string::npos &&
      text.find('e') == std::string::npos &&
      text.find('E') == std::string::npos) {
    text += ".0";
  }
  return text;
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

}  // namespace som
