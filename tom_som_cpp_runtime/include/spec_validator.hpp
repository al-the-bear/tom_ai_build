/* spec_validator — validates a concrete SpecDocument's values against a SpecModel
 * via the SpecReflection resolver, an idiomatic-C++ port of the C
 * `spec_validator` module.
 *
 * The check is over the values a document holds: every set path must resolve to
 * a node of a compatible kind, every form sub-key must name a real form field,
 * and every populated list must meet its `@Min` item count. Schema completeness
 * (mandatory-but-absent nodes) is a separate concern and is not reported here.
 */
#ifndef SPEC_VALIDATOR_HPP
#define SPEC_VALIDATOR_HPP

#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

inline constexpr const char* kSpecValidationCodeDanglingPath = "danglingPath";
inline constexpr const char* kSpecValidationCodeKindMismatch = "kindMismatch";
inline constexpr const char* kSpecValidationCodeUnknownFormField =
    "unknownFormField";
inline constexpr const char* kSpecValidationCodeMinItems = "minItems";

struct SpecValidationError {
  std::string path;
  std::string code;  // one of kSpecValidationCode*
  std::string message;
};

/* Validates `doc` against `model`, returning problems in stable order: content
 * paths, then forms, then lists; each group sorted by path. An empty list means
 * the document is valid. */
std::vector<SpecValidationError> validateDocument(const SpecModel& model,
                                                  const SpecDocument& doc);

}  // namespace som

#endif  // SPEC_VALIDATOR_HPP
