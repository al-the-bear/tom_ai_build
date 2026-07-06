/* spec_document_markdown — generic, meta-data-driven Markdown codec for a
 * TomSpecs document, a faithful port of the Rust `spec_document_markdown.rs`.
 *
 * A `<!-- docspec: -->` header, then one heading per populated section (sparse,
 * in schema order), with each section's machine-readable section path as the
 * first token of its heading. Leaf values live in fenced code blocks whose fence
 * is widened past any backtick run in the value. Form fields are introduced by a
 * `<!-- field: name -->` anchor; list items appear as nested `…-N` sections.
 *
 * `spec_markdown_parse` does not mutate the document — it returns staged values
 * keyed exactly like DocumentJson plus a rejection report; the caller applies
 * them.
 */
#ifndef SPEC_DOCUMENT_MARKDOWN_H
#define SPEC_DOCUMENT_MARKDOWN_H

#include "spec_document.h"
#include "spec_model.h"

#define SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION "unknownSection"
#define SPEC_MARKDOWN_REJECT_KIND_MISMATCH "kindMismatch"
#define SPEC_MARKDOWN_REJECT_ORPHAN_BLOCK "orphanBlock"
#define SPEC_MARKDOWN_REJECT_MISSING_VALUE "missingValue"
#define SPEC_MARKDOWN_REJECT_MALFORMED_HEADING "malformedHeading"

typedef struct {
  size_t line;
  char *reason;  /* one of the reject literals (copied) */
  char *message; /* owned */
  char *anchor;  /* owned */
} SpecMarkdownRejection;

typedef struct {
  DocumentJson staged; /* content/forms staged values; lists reconstructed */
  SpecMarkdownRejection *rejections;
  size_t rejections_len;
  size_t rejections_cap;
  SomStrList root_prefixes; /* byte-sorted set of root segments seen */
} SpecMarkdownResult;

void spec_markdown_result_free(SpecMarkdownResult *r);

/* Reports whether no block was rejected. */
int spec_markdown_result_is_clean(const SpecMarkdownResult *r);

/* The staged values as a DocumentJson (borrowed; load via spec_document_load_json). */
const DocumentJson *spec_markdown_result_document(const SpecMarkdownResult *r);

/* Renders the rejection as `line N: reason (anchor) — message`. Owned result. */
char *spec_markdown_rejection_display(const SpecMarkdownRejection *rej);

/* Renders the populated subtree of `root` as Markdown with a docspec header. */
char *spec_markdown_export_root(const SpecModel *model,
                                const SpecDocument *document,
                                const SpecRoot *root);

/* Renders `document` to Markdown in one call (§ item 12), returning the owned
 * output of `spec_markdown_export_root` (caller frees with `free`).
 *
 * When `root_type` is non-NULL, that root is exported (via
 * `spec_model_root_by_type`). When `root_type` is NULL, the document's single
 * *populated* root is used — a root is populated when `document` holds any value
 * beneath its segment (`spec_document_has_values_under` on `section_id` if
 * present, else `type`). Exactly one populated root → that root; zero or more
 * than one is ambiguous.
 *
 * On failure returns NULL and, when `err` is non-NULL, writes an owned message:
 * an unknown `root_type`, no populated root ("document has no populated root to
 * export; pass root_type to choose one"), or several populated roots (message
 * naming the candidate types). `err` may be NULL. */
char *spec_document_to_markdown(const SpecDocument *document,
                                const SpecModel *model, const char *root_type,
                                char **err);

/* Parses `text` into staged values + a rejection report, writing `*out`
 * (initialised by the callee; free with spec_markdown_result_free). */
void spec_markdown_parse(const SpecModel *model, const char *text,
                         SpecMarkdownResult *out);

#endif /* SPEC_DOCUMENT_MARKDOWN_H */
