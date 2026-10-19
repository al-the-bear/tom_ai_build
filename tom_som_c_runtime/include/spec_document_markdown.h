/* spec_document_markdown — DocSpecs-conform Markdown codec for a TomSpecs
 * document (SOM §11), a faithful port of the Go `spec_document_markdown.go`
 * (which itself ports the Dart reference `spec_document_markdown.dart`).
 *
 * The generated/authored `*.md` **is a genuine DocSpecs document**: line 1 is
 * the `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
 * section is one markdown heading whose machine-readable identity is the
 * DocSpecs headline comment `<!--[SECTION-ID]-->` and whose text is the
 * human-readable Title-Case member name. Content values are **normal markdown
 * text** under their heading (no fences, no anchors); `@Form` sections use the
 * DocSpecs plain-text `FieldName: value` format; a `List<T>` field heads a
 * `<!--[FOO-LST]-->` container section (SOM §11.2/§11.5) at the owner's child
 * level, its numbered item sub-headings one level deeper and their item-element
 * children one level deeper again — the container itself carries no body.
 * Id-less members are **transparent**
 * (mirroring the schema generator , SOM §13): a transparent value member's text or
 * form block is the owner's body region, emitted without a heading and bound
 * at its own path; a transparent section/complex member never heads — its
 * id-bearing descendants hoist to the owner's child level (paths keep the
 * transparent segments).
 *
 * Escaping (SOM §11.3): a content line starting with `#` at column 0 is
 * emitted as `\#` (and a leading `\#`… run gains one more backslash), except
 * inside fenced code blocks, which shield their lines verbatim. Blank lines
 * inside a value are kept as written; parse trims each value of
 * leading/trailing blank lines only.
 *
 * `spec_markdown_parse` does not mutate any document — it returns staged
 * values keyed exactly like `spec_document_to_json` plus a rejection report
 * (SOM §11.7); `spec_document_apply_markdown_result` applies them as a full overwrite.
 *
 * C conventions (shared with the rest of the runtime): "" = absent strings;
 * owned `char *` results are freed with `free`; `char **err` out-parameters
 * receive an owned message on failure (`err` may be NULL).
 */
#ifndef SPEC_DOCUMENT_MARKDOWN_H
#define SPEC_DOCUMENT_MARKDOWN_H

#include "spec_document.h"
#include "spec_model.h"

/* Why an imported Markdown block was rejected (SOM §11.7 rejection protocol). */
/* The heading's section id does not resolve against the schema tree at its
 * nesting position. */
#define SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION "unknownSection"
/* A structurally impossible combination, e.g. a child heading nested under a
 * value-leaf (content/scalar/enum) section. */
#define SPEC_MARKDOWN_REJECT_KIND_MISMATCH "kindMismatch"
/* Body text with no owning value slot: text before the document root
 * heading. */
#define SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT "orphanContent"
/* A value-leaf section heading with an empty body. */
#define SPEC_MARKDOWN_REJECT_MISSING_VALUE "missingValue"
/* A heading line without a parseable `<!--[id]-->` headline comment. */
#define SPEC_MARKDOWN_REJECT_MALFORMED_HEADING "malformedHeading"

/* One rejected block in a Markdown import (SOM §11.7). Reported, never
 * silently dropped: each carries the source line, the offending anchor
 * (section path or id, "" when none), the reason, and a human-readable
 * message. */
typedef struct {
  size_t line;
  char *reason;  /* one of the reject literals (owned copy) */
  char *message; /* owned */
  char *anchor;  /* owned, "" when none */
} SpecMarkdownRejection;

/* The outcome of parsing a Markdown document (SOM §11.7): the staged values
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

/* ---- naming helpers (SOM §11.2 / §11.5) ---------------------------------- */

/* Expands a camel/Pascal-case identifier into Title Case:
 * `introductionAndScope` / `DemoItem` → `Introduction And Scope` /
 * `Demo Item`. Owned result. */
char *spec_markdown_title_case(const char *name);

/* Derives the DocSpecs schema id of a `@Document` name (SOM §11.1):
 * `Demo Document` → `demo-document`. Owned result. */
char *spec_markdown_kebab_case(const char *title);

/* The item heading title stem: Title-Case element class name with a trailing
 * `Entry` dropped (SOM §11.5, normative). Owned result. */
char *spec_markdown_item_title_stem(const char *element_class_name);

/* The `FieldName` label written for a form field: the model field name with
 * the first letter upper-cased (SOM §11.4). Owned result. */
char *spec_markdown_form_label(const char *field_name);

/* ---- export / import ----------------------------------------------------- */

/* Renders the populated subtree of `root` as a DocSpecs-conform Markdown
 * document. Owned result. Returns NULL (writing `*err` when non-NULL) — the C
 * analogue of the other ports' throw — on the two conditions this format cannot
 * represent without losing the round-trip: a content value containing an
 * unterminated fenced code block (which would shield the remainder of the
 * document from heading detection), and a form holding a field the model does
 * not declare (SOM §9, "Form-field order"). */
char *spec_markdown_export_root(const SpecModel *model,
                                const SpecDocument *document,
                                const SpecRoot *root, char **err);

/* One heading of a rendition: its 1-based line and the document path it
 * renders (owned). */
typedef struct {
  int line;
  char *path;
} SpecMarkdownHeadingPath;

/* A Markdown rendition of a document plus the document path behind each of
 * its headings — the renderer is the one place that knows which node a
 * heading came from, and a section id alone does not (ids repeat across a
 * document). Owns everything; release with `spec_markdown_rendition_free`. */
typedef struct {
  char *markdown;                    /* identical to spec_markdown_export_root */
  SpecMarkdownHeadingPath *headings; /* ascending by line */
  size_t headings_len;
} SpecMarkdownRendition;

/* `spec_markdown_export_root`, plus the heading map: every heading line
 * (1-based) and the document path it renders. Returns 1 writing `*out`; on the
 * export's failure conditions returns 0 with `*out` empty (safe to free) and
 * `*err` written when non-NULL. */
int spec_markdown_export_root_with_map(const SpecModel *model,
                                       const SpecDocument *document,
                                       const SpecRoot *root,
                                       SpecMarkdownRendition *out,
                                       char **err);

/* The document path of the section `line` (1-based) belongs to: the path of
 * the heading on that line, else of the nearest heading above it. NULL for a
 * line before the first heading. Borrowed from `r`. */
const char *spec_markdown_rendition_path_at_line(
    const SpecMarkdownRendition *r, int line);

/* Releases a rendition's markdown and heading map (leaves it empty). */
void spec_markdown_rendition_free(SpecMarkdownRendition *r);

/* Renders `document` to Markdown in one call (SOM §21), returning the
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

/* `spec_document_to_markdown`, plus the heading map
 * (`spec_markdown_export_root_with_map`). Same root selection and failures;
 * returns 1 writing `*out`, else 0 with `*out` empty. */
int spec_document_to_markdown_with_map(const SpecDocument *document,
                                       const SpecModel *model,
                                       const char *root_type,
                                       SpecMarkdownRendition *out,
                                       char **err);

/* Parses `text` into staged values + a rejection report, writing `*out`
 * (initialised by the callee; free with spec_markdown_result_free). The
 * parse never mutates a document — `spec_document_apply_markdown_result` applies the result as a full
 * overwrite (SOM §11.7). */
void spec_markdown_parse(const SpecModel *model, const char *text,
                         SpecMarkdownResult *out);

/* ---- apply / one-call import (SOM §11.7) --------------------------------- */

/* Applies a parsed Markdown import to `doc` as a **full overwrite** of the
 * roots it covers (SOM §11.7): every value under each of
 * `result->root_prefixes` is removed, then the parsed content, forms, lists
 * (seq, items and stored item ids exactly as staged), headlines and codeSpecs
 * are written. Other roots are left as they are. Keys are written as-is (this
 * port has no path normalizer).
 *
 * A result with rejections is refused unless `allow_rejections` is non-zero:
 * the blocks it rejected would otherwise vanish from a document the caller
 * believes it imported whole. On refusal the document is left unchanged, a
 * non-zero value is returned and, when `error_out` is non-NULL, an owned
 * message naming the rejection count and the first rejection's line and
 * message is written. Returns 0 on success (including a result covering no
 * root, which changes nothing). */
int spec_document_apply_markdown_result(SpecDocument *doc,
                                        const SpecMarkdownResult *result,
                                        int allow_rejections,
                                        char **error_out);

/* The outcome of `spec_document_from_markdown`: a document holding every
 * value the parse accepted, plus the parse report (rejections included — the
 * rejected blocks are not in `document`). Owns both; free with
 * `spec_markdown_import_free`. */
typedef struct {
  SpecDocument *document; /* owned heap document */
  SpecMarkdownResult result;
} SpecMarkdownImport;

/* Frees the document and the parse result held by `imp` (not `imp` itself). */
void spec_markdown_import_free(SpecMarkdownImport *imp);

/* Builds a document from a DocSpecs Markdown `text` in one call: creates a
 * fresh document, parses `text` against `model`, then applies the result with
 * rejections allowed (`spec_document_apply_markdown_result`). Rejected blocks
 * are not loaded and are reported in `out->result`, so a caller can show them
 * or refuse to save: re-exporting a document whose source had rejections drops
 * those blocks for good. `out` is initialised by the callee. */
void spec_document_from_markdown(const char *text, const SpecModel *model,
                                 SpecMarkdownImport *out);

#endif /* SPEC_DOCUMENT_MARKDOWN_H */
