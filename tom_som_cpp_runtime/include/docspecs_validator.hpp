/* docspecs_validator — DocSpecs markdown validation, an idiomatic-C++ port of
 * the C `docspecs_validator` module (itself a faithful port of the Go
 * `docspecs_validator.go`, DR7/DR14/DR17 parity, DR29).
 *
 * Three cooperating pieces:
 *
 *  1. DocSpecsDocument — a schema-free structural parse of a DocSpecs markdown
 *     document into a heading tree (fence-aware, never fails).
 *  2. DocSpecsSchema — loader for `*.docspecs-schema.yaml` files with §7-style
 *     warnings for unsupported keys (never fails on extra keys).
 *  3. DocSpecsValidator — never-fail-fast validation of a parsed document
 *     against a schema, emitting DocSpecsViolations whose messages are
 *     golden-identical to the reference implementations.
 *
 * Plus docspecsBindMarkdown, which lands a DocSpecs markdown text in staged
 * values via the SOM markdown codec.
 *
 * C++ conventions (shared with the rest of the runtime): "" stands in for the
 * other ports' null strings; optional ints use std::optional; owned trees use
 * value semantics / std::unique_ptr; the one throwing entry point
 * (docspecsSchemaFromYamlText's "must be a YAML map") reports via a `std::string*
 * err` out-param and a false return.
 */
#ifndef DOCSPECS_VALIDATOR_HPP
#define DOCSPECS_VALIDATOR_HPP

#include <cstddef>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "spec_document_markdown.hpp"
#include "spec_model.hpp"
#include "yaml.hpp"

namespace som {

/* ---- violation rules (Dart-parity names) --------------------------------- */

inline constexpr const char* kDocSpecsRuleUnknownSection = "unknownSection";
inline constexpr const char* kDocSpecsRuleMissingRequiredSection =
    "missingRequiredSection";
inline constexpr const char* kDocSpecsRuleIdPatternMismatch = "idPatternMismatch";
inline constexpr const char* kDocSpecsRuleTooFewItems = "tooFewItems";
inline constexpr const char* kDocSpecsRuleTooManyItems = "tooManyItems";
inline constexpr const char* kDocSpecsRuleMissingRequiredField =
    "missingRequiredField";
inline constexpr const char* kDocSpecsRuleFieldPatternMismatch =
    "fieldPatternMismatch";
inline constexpr const char* kDocSpecsRuleTextRequired = "textRequired";
inline constexpr const char* kDocSpecsRuleTextLengthOut = "textLengthOut";
inline constexpr const char* kDocSpecsRuleFormatMismatch = "formatMismatch";
inline constexpr const char* kDocSpecsRuleMalformedHeading = "malformedHeading";

/* ---- violation ----------------------------------------------------------- */

/* One validation finding. `sectionId` / `path` are "" when absent. */
struct DocSpecsViolation {
  std::string rule;       // one of the rule literals
  int line = 0;
  std::string message;
  std::string sectionId;  // "" when none
  std::string path;       // "" when none

  /* Renders as `line N: rule [section] (path) — message` (the bracket / paren
   * parts are omitted when empty; the dash is U+2014). */
  std::string display() const;
};

/* ---- document parse (schema-free) ---------------------------------------- */

/* One heading-delimited section of a schema-free parse. */
struct DocSpecsSection {
  std::string id;     // the headline-comment id, "" for a malformed heading
  std::string title;
  int level = 0;
  int line = 0;
  std::vector<std::string> bodyLines;  // raw body lines between headings
  std::vector<std::unique_ptr<DocSpecsSection>> children;

  /* The 1-based line number of the first body line. */
  int bodyStartLine() const { return line + 1; }

  /* The body text with leading/trailing blank lines trimmed. */
  std::string text() const;
};

/* A schema-free structural parse of a DocSpecs markdown document. */
struct DocSpecsDocument {
  std::string declaredSchema;  // the `<!-- docspec: … -->` id, "" absent
  std::vector<std::unique_ptr<DocSpecsSection>> sections;  // top-level (root)
  std::vector<DocSpecsViolation> violations;  // structural findings from parse
};

/* Parses `text` into a heading tree. Never fails — structural problems are
 * recorded as violations. */
DocSpecsDocument docspecsParseDocument(const std::string& text);

/* The DocSpecs id transform: every run of non-alphanumeric/underscore
 * characters becomes a single `_`. */
std::string docspecsIdTransform(const std::string& id);

/* ---- schema -------------------------------------------------------------- */

/* A regex pattern check with an optional custom error message ("" when none). */
struct DocSpecsPatternCheck {
  std::string pattern;
  std::string errorMessage;  // "" when none

  /* Reports whether `value` matches the (hand-rolled) pattern. */
  bool matches(const std::string& value) const;
};

/* Occurrence bounds for one subsection type. `hasMax == false` means infinite. */
struct DocSpecsSubsectionRule {
  std::string name;  // the subsection-type key
  int minCount = 0;
  bool hasMax = false;
  int maxCount = 0;
};

/* One `section-types` entry of a schema. */
struct DocSpecsSectionType {
  std::string name;
  std::string prefix;
  std::optional<DocSpecsPatternCheck> patternCheck;
  std::vector<DocSpecsSubsectionRule> subsectionTypes;  // file order
  std::string format;  // "" when none
  bool textRequired = false;
  bool hasMinTextLength = false;
  int minTextLength = 0;
  bool hasMaxTextLength = false;
  int maxTextLength = 0;
  std::string description;      // "" when none
  std::string validationPrompt; // "" when none

  /* Returns the subsection rule named `name`, or nullptr. */
  const DocSpecsSubsectionRule* subsection(const std::string& name) const;
};

/* One field of a `form-types` entry. */
struct DocSpecsFormField {
  std::string name;
  bool required = false;
  std::string description;  // "" when none
  std::optional<DocSpecsPatternCheck> patternCheck;
};

/* One `form-types` entry of a schema. */
struct DocSpecsFormType {
  std::string name;
  std::vector<DocSpecsFormField> fields;
};

/* One `document.sections` slot of a schema. */
struct DocSpecsDocumentSection {
  std::string key;          // the slot key
  std::string sectionType;
  bool optional = false;
};

/* A loaded `*.docspecs-schema.yaml` schema. */
struct DocSpecsSchema {
  std::string titleFormat;  // "" when absent
  std::vector<DocSpecsSectionType> sectionTypes;      // file order
  std::vector<DocSpecsFormType> formTypes;
  std::vector<DocSpecsDocumentSection> documentSections;  // file order
  std::vector<std::string> warnings;  // §7 warnings for unsupported keys

  /* Returns the section type named `name`, or nullptr. */
  const DocSpecsSectionType* sectionTypeByName(const std::string& name) const;
  /* Returns the form type named `name`, or nullptr. */
  const DocSpecsFormType* formType(const std::string& name) const;
  /* Returns the document slot keyed `key`, or nullptr. */
  const DocSpecsDocumentSection* documentSection(const std::string& key) const;
  /* The section id embedded in title-format, "" when none. */
  std::string rootSectionId() const;
  /* Resolves a section id to its section-type by first-startsWith prefix match
   * over id-transformed ids. Borrowed pointer, or nullptr. */
  const DocSpecsSectionType* resolveSectionType(const std::string& id) const;
};

/* Loads a schema from YAML text. Unknown keys warn; a non-map root returns
 * std::nullopt (writing a message to `*err` when non-null). */
std::optional<DocSpecsSchema> docspecsSchemaFromYamlText(const std::string& text,
                                                         std::string* err);

/* ---- validator ----------------------------------------------------------- */

/* A never-fail-fast validator of a parsed document against a schema. */
class DocSpecsValidator {
 public:
  /* Binds a schema to the validator (borrowed; must outlive the validator). */
  explicit DocSpecsValidator(const DocSpecsSchema& schema) : schema_(&schema) {}

  /* Parses + validates in one step, appending ALL findings to `out`. */
  void validateMarkdown(const std::string& markdown,
                        std::vector<DocSpecsViolation>& out) const;

  /* Validates a parsed document, appending ALL findings to `out` (never
   * fail-fast). */
  void validate(const DocSpecsDocument& doc,
                std::vector<DocSpecsViolation>& out) const;

 private:
  const DocSpecsSchema* schema_;
};

/* ---- bind ---------------------------------------------------------------- */

/* Lands a DocSpecs markdown text in staged values + a rejection report via the
 * SOM markdown codec — the DR7 "bind" entry point. */
SpecMarkdownResult docspecsBindMarkdown(const SpecModel& model,
                                        const std::string& text);

}  // namespace som

#endif  // DOCSPECS_VALIDATOR_HPP
