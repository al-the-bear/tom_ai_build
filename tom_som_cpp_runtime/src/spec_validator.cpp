/* Idiomatic-C++ port of the C `spec_validator` module. */
#include "spec_validator.hpp"

#include "som_util.hpp"
#include "spec_reflection.hpp"

namespace som {

std::vector<SpecValidationError> validateDocument(const SpecModel& model,
                                                  const SpecDocument& doc) {
  std::vector<SpecValidationError> out;
  SpecReflection refl(model);

  auto push = [&](const std::string& path, const std::string& code,
                  const std::string& message) {
    out.push_back({path, code, message});
  };

  // 1. Content/scalar/enum leaves (contentPaths already byte-sorted).
  for (const std::string& path : doc.contentPaths()) {
    auto res = refl.resolve(path);
    if (!res.has_value()) {
      push(path, kSpecValidationCodeDanglingPath,
           "path does not resolve to any model node");
      continue;
    }
    if (!res->isValueLeaf()) {
      push(path, kSpecValidationCodeKindMismatch,
           "expected a value leaf but path resolves to " + res->kind);
    }
  }

  // 2. Form sections.
  for (const std::string& path : doc.formPaths()) {
    auto res = refl.resolve(path);
    if (!res.has_value()) {
      push(path, kSpecValidationCodeDanglingPath,
           "path does not resolve to any model node");
      continue;
    }
    if (res->field == nullptr || res->kind != kSpecNodeKindForm) {
      push(path, kSpecValidationCodeKindMismatch,
           "expected a form section but path resolves to " + res->kind);
      continue;
    }
    const SpecField* field = res->field;
    for (const std::string& name : doc.formFieldNames(path)) {
      bool declared = false;
      for (const FormFieldSpec& ff : field->formFields) {
        if (ff.name == name) {
          declared = true;
          break;
        }
      }
      if (!declared) {
        push(path, kSpecValidationCodeUnknownFormField,
             "form field \"" + name + "\" is not declared on " + field->name);
      }
    }
  }

  // 3. Lists (container kind + @Min count on populated lists).
  for (const std::string& path : doc.listPaths()) {
    auto res = refl.resolve(path);
    if (!res.has_value()) {
      push(path, kSpecValidationCodeDanglingPath,
           "path does not resolve to any model node");
      continue;
    }
    if (res->field == nullptr || res->kind != kSpecNodeKindList) {
      push(path, kSpecValidationCodeKindMismatch,
           "expected a list but path resolves to " + res->kind);
      continue;
    }
    const SpecField* field = res->field;
    if (field->hasMin) {
      long long count = static_cast<long long>(doc.listItemCount(path));
      if (count < field->min) {
        push(path, kSpecValidationCodeMinItems,
             "list holds " + formatI64(count) +
                 " item(s) but requires at least " + formatI64(field->min));
      }
    }
  }

  return out;
}

}  // namespace som
