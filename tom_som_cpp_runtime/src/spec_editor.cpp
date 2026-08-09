#include "spec_editor.hpp"

#include <stdexcept>

#include "spec_section_id.hpp"

namespace som {

namespace {

/* Strips a trailing `?` from a declared type name (`int?` -> `int`). */
std::string scalarBase(const std::string& typeName) {
  if (!typeName.empty() && typeName.back() == '?') {
    return typeName.substr(0, typeName.size() - 1);
  }
  return typeName;
}

/* Parses stored text per the declared scalar base type; an unrecognised base is
 * the string passthrough. */
SomValue parseScalar(const std::string& raw, const std::string& base) {
  if (base == "int") {
    std::optional<long long> v = somParseInt(raw);
    return v.has_value() ? SomValue::ofInt(*v) : SomValue::null();
  }
  if (base == "double") {
    std::optional<double> v = somParseDouble(raw);
    return v.has_value() ? SomValue::ofDouble(*v) : SomValue::null();
  }
  if (base == "num") {
    return somParseNum(raw);
  }
  if (base == "bool") {
    std::optional<bool> v = somParseBool(raw);
    return v.has_value() ? SomValue::ofBool(*v) : SomValue::null();
  }
  return SomValue::ofString(raw);
}

/* The value as an enum constant name: null passes through as "no name", a
 * string is the name, anything else is a type error at `where` of `path`. */
std::optional<std::string> stringOrNull(const SomValue& v,
                                        const std::string& path,
                                        const std::string& where) {
  if (v.isNull()) {
    return std::nullopt;
  }
  if (v.isString()) {
    return v.stringValue();
  }
  throw std::invalid_argument(where + ": expected a string for this field of " +
                              path + ", got " + v.debug());
}

}  // namespace

/* ---- resolution --------------------------------------------------------- */

SpecResolution SpecEditor::resolve(const std::string& path) const {
  std::optional<SpecResolution> r = reflection_.resolve(path);
  if (!r.has_value()) {
    throw std::invalid_argument("path \"" + path +
                                "\" does not resolve against the model");
  }
  return *r;
}

SpecResolution SpecEditor::valueLeaf(const std::string& path) const {
  SpecResolution r = resolve(path);
  if (!r.isValueLeaf()) {
    throw std::invalid_argument("path \"" + path + "\" is a " + r.kind +
                                " node, not a value leaf");
  }
  return r;
}

/* ---- value leaves ------------------------------------------------------- */

SomValue SpecEditor::value(const std::string& path) const {
  SpecResolution r = valueLeaf(path);
  const std::string* raw = document_.contentOpt(path);
  if (raw == nullptr || raw->empty()) {
    return SomValue::null();
  }
  if (r.kind == kSpecNodeKindEnumValue) {
    static const std::vector<std::string> kNoValues;
    std::optional<std::string> name = somParseEnumName(
        *raw, r.field != nullptr ? r.field->enumValues : kNoValues);
    return name.has_value() ? SomValue::ofString(*name) : SomValue::null();
  }
  return parseScalar(
      *raw, scalarBase(r.field != nullptr ? r.field->type : std::string()));
}

void SpecEditor::setValue(const std::string& path, const SomValue& v) {
  SpecResolution r = valueLeaf(path);
  document_.setContent(path, format(v, r.kind, r.field, path));
}

/* ---- headlines (YRD3) --------------------------------------------------- */

std::optional<std::string> SpecEditor::headline(const std::string& path) const {
  resolve(path);
  const std::string* stored = document_.headlineOpt(path);
  if (stored == nullptr) {
    return std::nullopt;
  }
  return *stored;
}

void SpecEditor::setHeadline(const std::string& path,
                             const std::string& value) {
  resolve(path);
  document_.setHeadline(path, value);
}

/* ---- typed form fields -------------------------------------------------- */

FormFieldSpec SpecEditor::formFieldSpec(const std::string& path,
                                        const std::string& field) const {
  SpecResolution r = resolve(path);
  if (r.kind != kSpecNodeKindForm) {
    throw std::invalid_argument("path \"" + path + "\" is a " + r.kind +
                                " node, not a @Form section");
  }
  if (r.field != nullptr) {
    for (const FormFieldSpec& ff : r.field->formFields) {
      if (ff.name == field) {
        return ff;
      }
    }
  }
  throw std::invalid_argument("\"" + field + "\" is not a form field of " +
                              path);
}

std::vector<FormFieldSpec> SpecEditor::formFields(
    const std::string& path) const {
  SpecResolution r = resolve(path);
  if (r.kind != kSpecNodeKindForm) {
    throw std::invalid_argument("path \"" + path + "\" is a " + r.kind +
                                " node, not a @Form section");
  }
  if (r.field == nullptr) {
    return {};
  }
  return r.field->formFields;
}

SomValue SpecEditor::formValue(const std::string& path,
                               const std::string& field) const {
  FormFieldSpec ff = formFieldSpec(path, field);
  const std::string* raw = document_.formFieldOpt(path, field);
  if (raw == nullptr || raw->empty()) {
    return SomValue::null();
  }
  if (!ff.enumValues.empty()) {
    std::optional<std::string> name = somParseEnumName(*raw, ff.enumValues);
    return name.has_value() ? SomValue::ofString(*name) : SomValue::null();
  }
  return parseScalar(*raw, scalarBase(ff.type));
}

void SpecEditor::setFormValue(const std::string& path, const std::string& field,
                              const SomValue& v) {
  FormFieldSpec ff = formFieldSpec(path, field);
  std::string stored;
  if (!ff.enumValues.empty()) {
    stored = somFormatEnumName(stringOrNull(v, path, field), ff.enumValues);
  } else {
    stored = format(v, kSpecNodeKindScalar, nullptr, path, ff.type, field);
  }
  document_.setFormField(path, field, stored);
}

/* ---- structural operations ---------------------------------------------- */

std::string SpecEditor::addListItem(const std::string& listPath,
                                    const std::string& sectionId,
                                    std::optional<long long> month,
                                    std::optional<long long> day) {
  SpecResolution r = resolve(listPath);
  if (r.kind != kSpecNodeKindList) {
    throw std::invalid_argument("path \"" + listPath + "\" is a " + r.kind +
                                " node, not a list");
  }
  std::string id = sectionId;
  const std::string pattern =
      r.field != nullptr ? r.field->sectionIdPattern : std::string();
  if (id.empty() && !pattern.empty()) {
    std::pair<long long, long long> today = specTodayMonthDay();
    id = specGenerateListItemSectionId(pattern, month.value_or(today.first),
                                       day.value_or(today.second),
                                       document_.listItemSectionIds(listPath));
  }
  if (id.empty()) {
    return document_.addListItem(listPath);
  }
  return document_.addListItemWithSectionId(listPath, id);
}

bool SpecEditor::removeListItem(const std::string& itemPath) {
  return document_.removeListItem(itemPath);
}

void SpecEditor::clearSection(const std::string& path) {
  resolve(path);
  document_.removeValuesUnder(path);
}

/* ---- conversion --------------------------------------------------------- */

std::string SpecEditor::format(const SomValue& v, const std::string& kind,
                               const SpecField* field, const std::string& path,
                               const std::string& typeName,
                               const std::string& where) const {
  if (v.isNull()) {
    return std::string();
  }
  if (kind == kSpecNodeKindEnumValue) {
    static const std::vector<std::string> kNoValues;
    return somFormatEnumName(
        stringOrNull(v, path, where.empty() ? path : where),
        field != nullptr ? field->enumValues : kNoValues);
  }
  const std::string base = scalarBase(
      !typeName.empty() ? typeName
                        : (field != nullptr ? field->type : std::string()));
  if (base == "int") {
    if (v.isInt()) {
      return somFormatInt(v.intValue());
    }
  } else if (base == "double") {
    if (v.isDouble()) {
      return somFormatDouble(v.doubleValue());
    }
    if (v.isInt()) {
      return somFormatDouble(static_cast<double>(v.intValue()));
    }
  } else if (base == "num") {
    if (v.isNum()) {
      return somFormatNum(v);
    }
  } else if (base == "bool") {
    if (v.isBool()) {
      return somFormatBool(v.boolValue());
    }
  }
  /* A string is authoritative for every declared type: the store holds plain
   * text, so writing "12" into an int leaf stores exactly that. */
  if (v.isString()) {
    return v.stringValue();
  }
  throw std::invalid_argument(
      (where.empty() ? path : where) + ": " + v.debug() +
      " is the wrong value type for a " + (base.empty() ? "String" : base) +
      " field");
}

}  // namespace som
