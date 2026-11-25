/* docspecs_validator — DocSpecs markdown validation, an idiomatic-C++ port of
 * the C `docspecs_validator` module (itself a faithful port of the Go
 * `docspecs_validator.go`, Dart / JavaScript / TypeScript parity).
 *
 * Three cooperating pieces:
 *
 *  1. DocSpecsDocument — a schema-free structural parse of a DocSpecs markdown
 *     document into a heading tree (fence-aware, never fails).
 *  2. DocSpecsSchema — loader for `*.docspecs-schema.yaml` files with SOM §14-style
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
inline constexpr const char* kDocSpecsRuleSectionOutOfOrder =
    "sectionOutOfOrder";
inline constexpr const char* kDocSpecsRuleDuplicateIdPath = "duplicateIdPath";
/* The reading notation's findings (DocSpecs specification, RN-10), reported by
 * scanNotation per value: a section's own body, and in a TomSpecs rendition
 * each form field's value apart. The names are NotationFindingCode's. */
inline constexpr const char* kDocSpecsRuleUnclosedDiv = "unclosedDiv";
inline constexpr const char* kDocSpecsRuleStrayClosingFence =
    "strayClosingFence";
inline constexpr const char* kDocSpecsRuleUnclosedSpan = "unclosedSpan";
inline constexpr const char* kDocSpecsRuleDivWithoutKind = "divWithoutKind";
inline constexpr const char* kDocSpecsRuleUnknownKind = "unknownKind";
inline constexpr const char* kDocSpecsRuleMarkAcrossNotation =
    "markAcrossNotation";
inline constexpr const char* kDocSpecsRuleAnnotationInsideDiv =
    "annotationInsideDiv";
inline constexpr const char* kDocSpecsRuleDivInsideAnnotation =
    "divInsideAnnotation";
inline constexpr const char* kDocSpecsRuleRejectedBlock = "rejectedBlock";
/* The reading view's list bodies and tables (DocSpecs specification,
 * Findings in list bodies and tables): a form, section or record table without
 * a matching delimiter row, a row of another cell count, a field given twice
 * (the first kept), a refs / records div beside other text or item headings, a
 * records div holding no table or one whose first column is not Id, an
 * unclosed refs / records fence. */
inline constexpr const char* kDocSpecsRuleMalformedBlock = "malformedBlock";
/* A form-table row or a record-table column naming no field of its form. */
inline constexpr const char* kDocSpecsRuleUnknownField = "unknownField";

/* The complete §14 vocabulary, in declaration order — the enumerable form of
 * what Dart gets for free from its enum. The conformance runner diffs it
 * against the rules the shared corpus exercises, so a rule added here without a
 * corpus case fails the suite instead of going unnoticed. */
inline constexpr const char* kDocSpecsAllRules[] = {
    kDocSpecsRuleUnknownSection,
    kDocSpecsRuleMissingRequiredSection,
    kDocSpecsRuleIdPatternMismatch,
    kDocSpecsRuleTooFewItems,
    kDocSpecsRuleTooManyItems,
    kDocSpecsRuleMissingRequiredField,
    kDocSpecsRuleFieldPatternMismatch,
    kDocSpecsRuleTextRequired,
    kDocSpecsRuleTextLengthOut,
    kDocSpecsRuleFormatMismatch,
    kDocSpecsRuleMalformedHeading,
    kDocSpecsRuleSectionOutOfOrder,
    kDocSpecsRuleDuplicateIdPath,
    kDocSpecsRuleUnclosedDiv,
    kDocSpecsRuleStrayClosingFence,
    kDocSpecsRuleUnclosedSpan,
    kDocSpecsRuleDivWithoutKind,
    kDocSpecsRuleUnknownKind,
    kDocSpecsRuleMarkAcrossNotation,
    kDocSpecsRuleAnnotationInsideDiv,
    kDocSpecsRuleDivInsideAnnotation,
    kDocSpecsRuleRejectedBlock,
    kDocSpecsRuleMalformedBlock,
    kDocSpecsRuleUnknownField,
};

/* ---- violation ----------------------------------------------------------- */

/* One validation finding. `sectionId` / `path` are "" when absent. */
struct DocSpecsViolation {
  std::string rule;       // one of the rule literals
  int line = 0;
  std::string message;
  std::string sectionId;  // "" when none
  std::string path;       // "" when none; validateSpecDocument fills it

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

  /* Every section of the tree, depth-first (each section before its
   * children), at every level. Borrowed pointers into `sections`. */
  std::vector<const DocSpecsSection*> allSections() const;

  /* Returns `text` with the body of the section whose id is `sectionId`
   * replaced by `body`; every other byte is kept.
   *
   * The body is the section's own region: the lines after its heading up to
   * its first child heading, or the next heading of any level. The heading
   * line and the subsections are untouched. The region is found by the same
   * fence-aware docspecsParseDocument, so a `#` line inside a fenced block is
   * never taken for a heading.
   *
   * The new region is a blank line, `body` with its leading and trailing blank
   * lines removed, and a blank line; an empty `body` leaves a single blank
   * line. Throws std::invalid_argument when `sectionId` names no section or
   * more than one, and when `body` would change the document's structure: a
   * heading outside a fenced block, or a fence it opens and never closes. */
  static std::string replaceSectionBody(const std::string& text,
                                        const std::string& sectionId,
                                        const std::string& body);
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

/* One `document.sections` slot of a schema: the backing section-type, whether
 * the slot is optional, and its `position` — `relative` (the default: in the
 * order of `document: sections:`) or `any` (anywhere among the root's
 * children; the order check leaves it out). */
struct DocSpecsDocumentSection {
  std::string key;          // the slot key
  std::string sectionType;
  bool optional = false;
  std::string position = "relative";  // one of kDocSpecsPositions

  /* Whether the section may stand anywhere among the root's children. */
  bool anyPosition() const { return position == "any"; }
};

/* The `position` values a document section may take. */
inline constexpr const char* kDocSpecsPositions[] = {"relative", "any"};

/* A loaded `*.docspecs-schema.yaml` schema. */
struct DocSpecsSchema {
  std::string titleFormat;  // "" when absent
  std::vector<DocSpecsSectionType> sectionTypes;      // file order
  std::vector<DocSpecsFormType> formTypes;
  std::vector<DocSpecsDocumentSection> documentSections;  // file order
  std::vector<std::string> warnings;  // SOM §14 warnings for unsupported keys

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

/* Loads a schema from YAML text. Unknown keys warn; a non-map root, or a
 * document section whose `position` is neither `relative` nor `any`, returns
 * std::nullopt (writing a message to `*err` when non-null). */
std::optional<DocSpecsSchema> docspecsSchemaFromYamlText(const std::string& text,
                                                         std::string* err);

/* `title` without the section's own anchor (*Section Anchors*): a leading
 * `<a id="ID"></a>` whose id is `id` or a qualified `<A>/…/<id>`, with the
 * whitespace after it. */
std::string docspecsStripOwnAnchor(const std::string& title,
                                   const std::string& id);

/* ---- validator ----------------------------------------------------------- */

/* A never-fail-fast validator of a parsed document against a schema. */
class DocSpecsValidator {
 public:
  /* Binds a schema to the validator (borrowed; must outlive the validator).
   * `tomSpecs` says the documents are TomSpecs renditions: the reading
   * notation is then scanned value by value (a form field's value apart from
   * the next), and a div without a class and an unregistered kind are
   * reported too. */
  explicit DocSpecsValidator(const DocSpecsSchema& schema,
                             bool tomSpecs = false)
      : schema_(&schema), tomSpecs_(tomSpecs) {}

  /* Whether the documents are TomSpecs renditions (see the constructor). */
  bool tomSpecs() const { return tomSpecs_; }

  /* Parses + validates in one step, appending ALL findings to `out`. */
  void validateMarkdown(const std::string& markdown,
                        std::vector<DocSpecsViolation>& out) const;

  /* Validates a parsed document, appending ALL findings to `out` (never
   * fail-fast). */
  void validate(const DocSpecsDocument& doc,
                std::vector<DocSpecsViolation>& out) const;

 private:
  const DocSpecsSchema* schema_;
  bool tomSpecs_ = false;
};

/* ---- bind ---------------------------------------------------------------- */

/* Lands a DocSpecs markdown text in staged values + a rejection report via the
 * SOM markdown codec — the "bind" entry point (SOM §14). */
SpecMarkdownResult docspecsBindMarkdown(const SpecModel& model,
                                        const std::string& text);

}  // namespace som

#endif  // DOCSPECS_VALIDATOR_HPP
