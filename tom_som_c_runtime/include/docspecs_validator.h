/* docspecs_validator — DocSpecs markdown validation, a faithful C port of the
 * Go `tom_som_go_runtime/docspecs_validator.go` (itself a port of the
 * TypeScript / JavaScript / Python / Dart chain, DR7/DR14/DR17 parity, DR29).
 *
 * Three cooperating pieces:
 *
 *  1. DocSpecsDocument — a schema-free structural parse of a DocSpecs markdown
 *     document into a heading tree (fence-aware, never fails).
 *  2. DocSpecsSchema — loader for `*.docspecs-schema.yaml` files with §7-style
 *     warnings for unsupported keys (never fails on extra keys).
 *  3. DocSpecsValidator — never-fail-fast validation of a parsed document
 *     against a schema, emitting DocSpecsViolations whose messages are
 *     golden-identical to the Dart implementation.
 *
 * Plus docspecs_bind_markdown, which lands a DocSpecs markdown text in a typed
 * SpecDocument via the SOM markdown codec.
 *
 * C conventions (shared with the rest of the runtime): "" stands in for the
 * other ports' null strings; optional ints use a paired `has_*` flag; owned
 * `char *` results are freed with `free`; the one throwing entry point
 * (docspecs_schema_from_yaml_text's "must be a YAML map") reports via a `char
 * **err` out-param and a 0 return.
 */
#ifndef DOCSPECS_VALIDATOR_H
#define DOCSPECS_VALIDATOR_H

#include <stddef.h>

#include "som_util.h"
#include "spec_document.h"
#include "spec_document_markdown.h"
#include "spec_model.h"
#include "yaml.h"

/* ---- violation rules (Dart-parity names) --------------------------------- */

#define DOCSPECS_RULE_UNKNOWN_SECTION "unknownSection"
#define DOCSPECS_RULE_MISSING_REQUIRED_SECTION "missingRequiredSection"
#define DOCSPECS_RULE_ID_PATTERN_MISMATCH "idPatternMismatch"
#define DOCSPECS_RULE_TOO_FEW_ITEMS "tooFewItems"
#define DOCSPECS_RULE_TOO_MANY_ITEMS "tooManyItems"
#define DOCSPECS_RULE_MISSING_REQUIRED_FIELD "missingRequiredField"
#define DOCSPECS_RULE_FIELD_PATTERN_MISMATCH "fieldPatternMismatch"
#define DOCSPECS_RULE_TEXT_REQUIRED "textRequired"
#define DOCSPECS_RULE_TEXT_LENGTH_OUT "textLengthOut"
#define DOCSPECS_RULE_FORMAT_MISMATCH "formatMismatch"
#define DOCSPECS_RULE_MALFORMED_HEADING "malformedHeading"

/* ---- violation ----------------------------------------------------------- */

/* DocSpecsViolation is one validation finding. `section_id` / `path` are ""
 * when absent. */
typedef struct {
  char *rule;       /* owned; one of the rule literals */
  int line;
  char *message;    /* owned */
  char *section_id; /* owned, "" when none */
  char *path;       /* owned, "" when none */
} DocSpecsViolation;

/* Renders the violation as `line N: rule [section] (path) — message` (the
 * bracket / paren parts are omitted when empty). Owned result. */
char *docspecs_violation_string(const DocSpecsViolation *v);

/* An owning, growable list of violations. */
typedef struct {
  DocSpecsViolation *items;
  size_t len;
  size_t cap;
} DocSpecsViolationList;

void docspecs_violation_list_init(DocSpecsViolationList *l);
void docspecs_violation_list_free(DocSpecsViolationList *l);

/* ---- document parse (schema-free) ---------------------------------------- */

/* DocSpecsSection is one heading-delimited section of a schema-free parse. */
typedef struct DocSpecsSection DocSpecsSection;
struct DocSpecsSection {
  char *id;    /* owned; the headline-comment id, "" for a malformed heading */
  char *title; /* owned */
  int level;
  int line;
  SomStrList body_lines;         /* raw body lines between this heading and next */
  DocSpecsSection **children;    /* owned */
  size_t children_len;
  size_t children_cap;
};

/* The 1-based line number of the first body line. */
int docspecs_section_body_start_line(const DocSpecsSection *s);

/* The body text with leading/trailing blank lines trimmed. Owned result. */
char *docspecs_section_text(const DocSpecsSection *s);

/* DocSpecsDocument is a schema-free structural parse of a DocSpecs markdown
 * document. */
typedef struct {
  char *declared_schema;       /* owned; the `<!-- docspec: … -->` id, "" absent */
  DocSpecsSection **sections;  /* owned; top-level (root) sections */
  size_t sections_len;
  size_t sections_cap;
  DocSpecsViolationList violations; /* structural findings from the parse */
} DocSpecsDocument;

/* Parses `text` into a heading tree. Never fails — structural problems are
 * recorded as violations. Free with docspecs_document_free. */
DocSpecsDocument *docspecs_parse_document(const char *text);

void docspecs_document_free(DocSpecsDocument *doc);

/* The DocSpecs id transform: every run of non-alphanumeric/underscore
 * characters becomes a single `_`. Owned result. */
char *docspecs_id_transform(const char *id);

/* ---- schema -------------------------------------------------------------- */

/* A regex pattern check with an optional custom error message ("" when none). */
typedef struct {
  char *pattern;       /* owned */
  char *error_message; /* owned, "" when none */
} DocSpecsPatternCheck;

/* Reports whether `value` matches the check's (hand-rolled) pattern. */
int docspecs_pattern_check_matches(const DocSpecsPatternCheck *c,
                                   const char *value);

/* Occurrence bounds for one subsection type. `has_max` == 0 means infinite. */
typedef struct {
  char *name; /* owned; the subsection-type key */
  int min_count;
  int has_max;
  int max_count;
} DocSpecsSubsectionRule;

/* One `section-types` entry of a schema. */
typedef struct {
  char *name;   /* owned */
  char *prefix; /* owned */
  DocSpecsPatternCheck *pattern_check; /* owned, NULL when none */
  DocSpecsSubsectionRule *subsection_types; /* owned, file order */
  size_t subsection_types_len;
  char *format;            /* owned, "" when none */
  int text_required;
  int has_min_text_length;
  int min_text_length;
  int has_max_text_length;
  int max_text_length;
  char *description;       /* owned, "" when none */
  char *validation_prompt; /* owned, "" when none */
} DocSpecsSectionType;

/* Returns the subsection rule named `name`, or NULL. */
const DocSpecsSubsectionRule *docspecs_section_type_subsection(
    const DocSpecsSectionType *t, const char *name);

/* One field of a `form-types` entry. */
typedef struct {
  char *name;        /* owned */
  int required;
  char *description; /* owned, "" when none */
  DocSpecsPatternCheck *pattern_check; /* owned, NULL when none */
} DocSpecsFormField;

/* One `form-types` entry of a schema. */
typedef struct {
  char *name; /* owned */
  DocSpecsFormField *fields; /* owned */
  size_t fields_len;
} DocSpecsFormType;

/* One `document.sections` slot of a schema. */
typedef struct {
  char *key;          /* owned; the slot key */
  char *section_type; /* owned */
  int optional;
} DocSpecsDocumentSection;

/* A loaded `*.docspecs-schema.yaml` schema. */
typedef struct {
  char *title_format; /* owned, "" when absent */
  DocSpecsSectionType *section_types; /* owned, file order */
  size_t section_types_len;
  DocSpecsFormType *form_types; /* owned */
  size_t form_types_len;
  DocSpecsDocumentSection *document_sections; /* owned, file order */
  size_t document_sections_len;
  SomStrList warnings; /* §7 warnings for unsupported keys */
} DocSpecsSchema;

/* Returns the section type named `name`, or NULL. */
const DocSpecsSectionType *docspecs_schema_section_type_by_name(
    const DocSpecsSchema *s, const char *name);

/* Returns the form type named `name`, or NULL. */
const DocSpecsFormType *docspecs_schema_form_type(const DocSpecsSchema *s,
                                                  const char *name);

/* Returns the document slot keyed `key`, or NULL. */
const DocSpecsDocumentSection *docspecs_schema_document_section(
    const DocSpecsSchema *s, const char *key);

/* The section id embedded in title-format, "" when none. Owned result. */
char *docspecs_schema_root_section_id(const DocSpecsSchema *s);

/* Resolves a section id to its section-type by first-startsWith prefix match
 * over id-transformed ids. Borrowed pointer, or NULL. */
const DocSpecsSectionType *docspecs_schema_resolve_section_type(
    const DocSpecsSchema *s, const char *id);

/* Loads a schema from YAML text. Unknown keys warn; a non-map root returns 0
 * (writing an owned message to `*err` when non-NULL). On success writes an
 * owned schema to `*out` (free with docspecs_schema_free) and returns 1. */
int docspecs_schema_from_yaml_text(const char *text, DocSpecsSchema **out,
                                   char **err);

void docspecs_schema_free(DocSpecsSchema *s);

/* ---- validator ----------------------------------------------------------- */

/* A never-fail-fast validator of a parsed document against a schema. */
typedef struct {
  const DocSpecsSchema *schema; /* borrowed */
} DocSpecsValidator;

/* Binds a schema to the validator (borrowed; must outlive the validator). */
DocSpecsValidator docspecs_validator_new(const DocSpecsSchema *schema);

/* Parses + validates in one step, writing ALL findings to `*out`
 * (init/free with docspecs_violation_list_*). */
void docspecs_validator_validate_markdown(const DocSpecsValidator *val,
                                          const char *markdown,
                                          DocSpecsViolationList *out);

/* Validates a parsed document, appending ALL findings to `*out` (never
 * fail-fast). */
void docspecs_validator_validate(const DocSpecsValidator *val,
                                 const DocSpecsDocument *doc,
                                 DocSpecsViolationList *out);

/* ---- bind ---------------------------------------------------------------- */

/* Lands a DocSpecs markdown text in staged values + a rejection report via the
 * SOM markdown codec — the DR7 "bind" entry point. Writes `*out` (init by the
 * callee; free with spec_markdown_result_free). */
void docspecs_bind_markdown(const SpecModel *model, const char *text,
                            SpecMarkdownResult *out);

#endif /* DOCSPECS_VALIDATOR_H */
