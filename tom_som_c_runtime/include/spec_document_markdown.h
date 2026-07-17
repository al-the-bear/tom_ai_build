/* spec_document_markdown — DocSpecs-conform Markdown codec for a TomSpecs
 * document (DR1 §1), a faithful port of the Go `spec_document_markdown.go`
 * (which itself ports the Dart reference `spec_document_markdown.dart`).
 *
 * The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
 * the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is one markdown heading whose machine-readable identity is the
 * DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
 * human-readable Title-Case member name. Content values are **normal markdown
 * text** under their heading (no fences, no anchors); `@Form` sections use the
 * DocSpecs plain-text `FieldName: value` format; a `List<T>` field heads a
 * `<!--[FOO-LST]-->` container section (DR1 §1.2/§1.5) at the owner's child
 * level, its numbered item sub-headings one level deeper and their item-element
 * children one level deeper again — the container itself carries no body.
 * Id-less members are **transparent**
 * (mirroring the DR3 schema generator): a transparent value member's text or
 * form block is the owner's body region, emitted without a heading and bound
 * at its own path; a transparent section/complex member never heads — its
 * id-bearing descendants hoist to the owner's child level (paths keep the
 * transparent segments).
 *
 * Escaping (DR1 §1.3): a content line starting with `#` at column 0 is
 * emitted as `\#` (and a leading `\#`… run gains one more backslash), except
 * inside fenced code blocks, which shield their lines verbatim. Consecutive
 * blank lines are collapsed to one on emit; parse trims each value of
 * leading/trailing blank lines and does not re-collapse.
 *
 * `spec_markdown_parse` does not mutate any document — it returns staged
 * values keyed exactly like `spec_document_to_json` plus a rejection report
 * (DR1 §1.7); the caller applies them as a full overwrite.
 *
 * C conventions (shared with the rest of the runtime): "" = absent strings;
 * owned `char *` results are freed with `free`; `char **err` out-parameters
 * receive an owned message on failure (`err` may be NULL).
 */
#ifndef SPEC_DOCUMENT_MARKDOWN_H
#define SPEC_DOCUMENT_MARKDOWN_H

#include "spec_document.h"
#include "spec_model.h"

/* Why an imported Markdown block was rejected (DR1 §1.7 rejection protocol). */
/* The heading's section id does not resolve against the schema tree at its
 * nesting position. */
#define SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION "unknownSection"
/* A structurally impossible combination, e.g. a child heading nested under a
 * value-leaf (content/scalar/enum) section. */
#define SPEC_MARKDOWN_REJECT_KIND_MISMATCH "kindMismatch"
/* Body text with no owning value slot, e.g. prose inside a `@Form` section
 * before the first `FieldName:` line. */
#define SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT "orphanContent"
/* A value-leaf section heading with an empty body. */
#define SPEC_MARKDOWN_REJECT_MISSING_VALUE "missingValue"
/* A heading line without a parseable `<!--[id]-->` headline comment. */
#define SPEC_MARKDOWN_REJECT_MALFORMED_HEADING "malformedHeading"
/* A `FieldName:` form line for a title/id **role field** (YRD6): the field's
 * value is the section heading / id comment and must never be duplicated as a
 * form line. */
#define SPEC_MARKDOWN_REJECT_ROLE_FIELD_FORM_LINE "roleFieldFormLine"

/* One rejected block in a Markdown import (DR1 §1.7). Reported, never
 * silently dropped: each carries the source line, the offending anchor
 * (section path or id, "" when none), the reason, and a human-readable
 * message. */
typedef struct {
  size_t line;
  char *reason;  /* one of the reject literals (owned copy) */
  char *message; /* owned */
  char *anchor;  /* owned, "" when none */
} SpecMarkdownRejection;

/* The outcome of parsing a Markdown document (DR1 §1.7): the staged values
 * plus every rejected block. The values are keyed exactly like
 * `spec_document_to_json` so a caller can merge them into a live document as
 * a full overwrite of the covered scope. */
typedef struct {
  DocumentJson staged; /* content / forms / lists staged values */
  SpecMarkdownRejection *rejections; /* every rejected block, source order */
  size_t rejections_len;
  size_t rejections_cap;
  SomStrList root_prefixes; /* byte-sorted set of root segments the import
                             * covers — the scope a full-overwrite apply
                             * purges first */
} SpecMarkdownResult;

void spec_markdown_result_free(SpecMarkdownResult *r);

/* Reports whether the parse was clean (no rejections). */
int spec_markdown_result_is_clean(const SpecMarkdownResult *r);

/* Returns the number of leaf values successfully parsed (content + form
 * fields). */
size_t spec_markdown_result_applied_count(const SpecMarkdownResult *r);

/* The staged values as a DocumentJson (borrowed; load via
 * spec_document_load_json). */
const DocumentJson *spec_markdown_result_document(const SpecMarkdownResult *r);

/* Renders the rejection as `line N: reason (anchor) — message` (the anchor
 * part is omitted when the anchor is empty). Owned result. */
char *spec_markdown_rejection_display(const SpecMarkdownRejection *rej);

/* ---- fence tracking ------------------------------------------------------ */

/* A fence state machine (CommonMark-ish): a line whose first non-space run
 * (up to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
 * same-character run at least as long closes it.
 *
 * Public so other markdown-processing modules (the DocSpecs validator's
 * generic parser) share exactly the same fence semantics as this codec. */
typedef struct {
  char ch;     /* the fence character, 0 when outside a fence */
  size_t size; /* the opening run length */
} SpecMarkdownFenceTracker;

void spec_markdown_fence_init(SpecMarkdownFenceTracker *t);
/* Reports whether the tracker is currently inside a fence. */
int spec_markdown_fence_in_fence(const SpecMarkdownFenceTracker *t);
/* Advances the state machine by one line (`line` has no trailing '\n'). */
void spec_markdown_fence_feed(SpecMarkdownFenceTracker *t, const char *line);

/* ---- naming helpers (DR1 §1.2 / §1.5) ------------------------------------ */

/* Expands a camel/Pascal-case identifier into Title Case:
 * `introductionAndScope` / `DemoItem` → `Introduction And Scope` /
 * `Demo Item`. Owned result. */
char *spec_markdown_title_case(const char *name);

/* Derives the DocSpecs schema id of a `@Document` name (DR1 §1.1):
 * `Demo Document` → `demo-document`. Owned result. */
char *spec_markdown_kebab_case(const char *title);

/* The item heading title stem: Title-Case element class name with a trailing
 * `Entry` dropped (DR1 §1.5, normative). Owned result. */
char *spec_markdown_item_title_stem(const char *element_class_name);

/* The `FieldName` label written for a form field: the model field name with
 * the first letter upper-cased (DR1 §1.4.1). Owned result. */
char *spec_markdown_form_label(const char *field_name);

/* ---- export / import ----------------------------------------------------- */

/* Renders the populated subtree of `root` as a DocSpecs-conform Markdown
 * document. Owned result. Returns NULL (writing `*err` when non-NULL) when a
 * content value contains an unterminated fenced code block (which would
 * shield the remainder of the document from heading detection and break the
 * round-trip) — the C analogue of the other ports' throw. */
char *spec_markdown_export_root(const SpecModel *model,
                                const SpecDocument *document,
                                const SpecRoot *root, char **err);

/* Renders `document` to Markdown in one call (SOM § item 12), returning the
 * owned output of `spec_markdown_export_root` (caller frees with `free`).
 *
 * When `root_type` is non-NULL and non-empty, that root is exported (via
 * `spec_model_root_by_type`). Otherwise the document's single *populated*
 * root is used — a root is populated when `document` holds any value beneath
 * its segment (`section_id` if present, else `type`). Exactly one populated
 * root → that root; zero or more than one is ambiguous.
 *
 * On failure returns NULL and, when `err` is non-NULL, writes an owned
 * message: an unknown `root_type`, no populated root, or several populated
 * roots (message naming the candidate types). */
char *spec_document_to_markdown(const SpecDocument *document,
                                const SpecModel *model, const char *root_type,
                                char **err);

/* Parses `text` into staged values + a rejection report, writing `*out`
 * (initialised by the callee; free with spec_markdown_result_free). The
 * parse never mutates a document — the caller applies the result as a full
 * overwrite (DR1 §1.7). */
void spec_markdown_parse(const SpecModel *model, const char *text,
                         SpecMarkdownResult *out);

#endif /* SPEC_DOCUMENT_MARKDOWN_H */
