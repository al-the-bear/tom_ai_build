/* spec_model — in-memory representation of the exported TomSpecs class graph, an
 * idiomatic-C++ port of the C `spec_model` module.
 *
 * The model is a class graph, not an expanded tree: each class appears once and
 * field elementType/type references are followed on demand by a traversal.
 * Classes are kept sorted by name (binary-searchable).
 */
#ifndef SPEC_MODEL_HPP
#define SPEC_MODEL_HPP

#include <cstddef>
#include <map>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include "som_json.hpp"

namespace som {

inline constexpr const char* kSpecFieldKindList = "list";
inline constexpr const char* kSpecFieldKindForm = "form";
inline constexpr const char* kSpecFieldKindSection = "section";
inline constexpr const char* kSpecFieldKindContent = "content";
inline constexpr const char* kSpecFieldKindEnum = "enum";
inline constexpr const char* kSpecFieldKindComplex = "complex";
inline constexpr const char* kSpecFieldKindScalar = "scalar";

/* Returns the canonical kind for `raw`, falling back to "scalar". */
std::string specParseFieldKind(const std::string& raw);

/* Derives the `major.minor` DocSpecs version string from a model's integer
 * version and its optional free-form label (port of the C
 * `som_model_version_string` / Go `SomModelVersionString`).
 *
 * When the label's `+`-stripped core has at least two dot-separated integer
 * components, those become `major.minor`; otherwise the result is
 * `<major>.0`. */
std::string somModelVersionString(long long major, const std::string& label);

struct SpecAnnotation {
  std::string name;
  JsonRef arguments;  // borrowed object node into the model source (or null)

  /* Returns the argument value for `key`, or null. */
  JsonRef argument(const std::string& key) const;
};

struct FormFieldSpec {
  std::string name;
  std::string label;
  std::string type;  // defaults to "String"
  std::string hint;
  bool required = false;
};

struct SpecField {
  std::string name;
  std::string kind;
  std::string doc;
  std::string help;
  std::string headline;  // @Headline(text) default headline (YRD4), "" none
  std::string sectionId;
  std::string sectionIdPattern;
  std::string elementType;
  bool elementIsComplex = false;
  bool hasMin = false;
  long long min = 0;
  std::string contentType;
  std::string sectionType;
  std::string enumType;
  std::vector<std::string> enumValues;
  std::string type;
  bool hasSerializationOrder = false;
  long long serializationOrder = 0;
  std::vector<FormFieldSpec> formFields;
  std::vector<SpecAnnotation> annotations;

  /* Reports whether expanding this field reveals further tree nodes. */
  bool isExpandable() const;
};

struct SpecClass {
  std::string name;
  std::string sectionId;
  std::string doc;
  std::string help;
  std::string headline;  // class-level @Headline(text) default (YRD4), "" none
  std::string mapsTo;
  std::string detailedIn;
  std::vector<SpecField> fields;
  std::vector<SpecAnnotation> annotations;

  /* Returns the field named `name`, or null. */
  const SpecField* fieldNamed(const std::string& name) const;
};

struct SpecRoot {
  std::string type;
  std::string title;
  std::string sectionId;
  std::string description;
  std::string doc;
};

class SpecModel {
 public:
  std::vector<SpecRoot> roots;
  long long modelVersion = 0;
  std::string modelVersionLabel;

  /* Returns the class named `name`, or null. */
  const SpecClass* classNamed(const std::string& name) const;

  /* Returns the document root whose `type` equals `type` (§ item 12).
   * Replaces the recurring firstWhere((r) => r.type == …) boilerplate. Throws
   * std::invalid_argument when no root carries that type, with a message that
   * names the missing type and the ones that do exist. */
  const SpecRoot& rootByType(const std::string& type) const;

  std::size_t classCount() const { return classesByName_.size(); }

  /* Decodes a meta-data JSON document. On failure returns null and, when `err`
   * is non-null, writes an error message. */
  static std::unique_ptr<SpecModel> fromJsonStr(const std::string& data,
                                                std::string* err);

  /* Builds a model from an already-parsed meta-data JSON node. The node is
   * retained (annotation arguments borrow from it) via shared ownership, so it
   * stays alive for the model's lifetime. Mirrors the C `spec_model_from_json`. */
  static std::unique_ptr<SpecModel> fromJson(const JsonRef& root);

 private:
  // Shared builder for both fromJsonStr and fromJson: fills the model from an
  // already-parsed root node and retains it (annotations borrow from it).
  static std::unique_ptr<SpecModel> buildFromRoot(const JsonRef& root);

  // sorted-by-name map (std::map gives byte-ordered, binary-searchable access).
  std::map<std::string, SpecClass> classesByName_;
  JsonRef source_;  // owned parsed tree; annotations borrow from it
};

}  // namespace som

#endif  // SPEC_MODEL_HPP
