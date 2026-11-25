/* spec_document_strip — the strip of one text value (SOM §11.10; the reading
 * view's part *Stripped renditions and the merge back*): a copy of a value
 * with the secondary prose of named kinds dropped, unmarked or moved to an
 * appendix.
 *
 * The kinds are the four the reading notation registers as secondary
 * (`provenance`, `trace`, `editorial`, `aside`, DocSpecs RN-5), `linked`, the
 * navigation marker (SOM §11.11), and `derived`, the generated parts (SOM
 * §11.12) — both removed by `drop` and `unmark` alike —, and `comments`, the
 * review annotations (SOM §11.9). A citation shape counts as a span of its
 * kind. `refs`, `records` and `rejected` are never secondary.
 *
 * The strip of a whole document (`spec_document_strip`) strips every value
 * of a document into a copy and, given a model, applies the emptying rule,
 * removes list items left empty, numbers the appendix through the rendition,
 * renders the readable rendition (`.readable.md`, its readable header first,
 * SOM §11.1) and checks it.
 *
 * The C port of `spec_document_strip.dart` / `.ts`; `strip_cases.json` holds
 * them to the same results. The text is UTF-8; a piece's `anchor` and
 * `origin` count UTF-16 code units, as the corpus and the other runtimes do.
 */
#ifndef SPEC_DOCUMENT_STRIP_H
#define SPEC_DOCUMENT_STRIP_H

#include <stddef.h>

#include "docspecs_validator.h"
#include "som_util.h"
#include "spec_document.h"
#include "spec_model.h"

/* The kind names a strip takes, in report and header order. */
#define SPEC_STRIP_KIND_COUNT 7
extern const char *const SPEC_STRIP_KIND_NAMES[SPEC_STRIP_KIND_COUNT];

/* The notation kinds a strip can drop, unmark or move to the appendix (the
 * first four of SPEC_STRIP_KIND_NAMES). */
#define SPEC_STRIP_NOTATION_KIND_COUNT 4
extern const char *const SPEC_STRIP_NOTATION_KINDS[SPEC_STRIP_NOTATION_KIND_COUNT];

/* The index of `name` in SPEC_STRIP_KIND_NAMES, or -1. */
int spec_strip_kind_index(const char *name);

/* What a strip does with each kind: bit `1 << i` for SPEC_STRIP_KIND_NAMES[i]. */
typedef struct {
  unsigned drop;     /* the kinds removed with their content */
  unsigned unmark;   /* the kinds whose markers go and whose content stays */
  unsigned appendix; /* the kinds moved, with their content, to the appendix */
  int appendix_references; /* each moved element leaves a link `[n]` */
  int heading_divs;  /* sections deeper than level 6 as styled-div headings */
} SpecStripOptions;

/* The options from the names a user gives, each item possibly comma-joined
 * (NULL lists are empty). `all` stands for every kind the list can hold that
 * no other list names explicitly. A usage error — an unknown name, a name in
 * two lists, `comments` to unmark or move, `linked` / `derived` to move,
 * appendix references without an appendix — returns 0 and writes the
 * message to `*error` (owned, when non-NULL); else returns 1. */
int spec_strip_options_from_names(const SomStrList *drop,
                                  const SomStrList *unmark,
                                  const SomStrList *appendix,
                                  int appendix_references, int heading_divs,
                                  SpecStripOptions *out, char **error);

/* The options as the corpus writes them (`drop`, `unmark`, `appendix` in
 * canonical order, `appendixReferences`, `headingDivs`). Owned JSON. */
char *spec_strip_options_to_json(const SpecStripOptions *o);

/* The options of the emptying rule: what would go is unmarked instead
 * (`comments` stays dropped; no appendix). */
SpecStripOptions spec_strip_options_keeping(const SpecStripOptions *o);

/* The source a readable rendition was made from, for its header. `revision`
 * and `commit` are NULL when not known. Owned strings when it comes from
 * spec_readable_header_parse; a caller's own may be borrowed. */
typedef struct {
  char *file;
  char *revision;
  char *commit;
  int dirty;
} SpecReadableSource;

/* The readable header line of a stripped rendition (SOM §11.1): `<!--
 * readable: drop=…; unmark=…; appendix=…; appendix-references;
 * headings=divs; of=<file>@<revision>; commit=<sha>[+dirty] -->`. Parts that
 * do not apply are left out; format and parse are inverse. */
typedef struct {
  SpecStripOptions options;
  SpecReadableSource *source; /* owned, NULL when the header names none */
} SpecReadableHeader;

/* The header line for `options` and `source` (NULL: none). Owned. */
char *spec_readable_header_format(const SpecStripOptions *options,
                                  const SpecReadableSource *source);

/* `line` read as a readable header: 1 writing `*out` (free with
 * spec_readable_header_free), 0 for a line that is none — an unknown part,
 * an unknown kind, a usage error, a commit without a file. */
int spec_readable_header_parse(const char *line, SpecReadableHeader *out);

void spec_readable_header_free(SpecReadableHeader *h);

/* A value of a document: a stored headline, a content value, or a form
 * field's value. Owned strings. */
typedef struct {
  char *path;
  char *field; /* NULL unless a form field */
  int headline;
} SpecStripValueRef;

/* The value `ref` names in `doc` ("" when unset). Borrowed. */
const char *spec_strip_value_ref_read(const SpecStripValueRef *ref,
                                      const SpecDocument *doc);
/* Writes `value` to the value `ref` names ("" clears it). */
void spec_strip_value_ref_write(const SpecStripValueRef *ref, SpecDocument *doc,
                                const char *value);
/* `<path> (headline)`, `<path>/<field>` or `<path>`. Owned. */
char *spec_strip_value_ref_label(const SpecStripValueRef *ref);
/* `{path, field?, headline?}`. Owned JSON. */
char *spec_strip_value_ref_to_json(const SpecStripValueRef *ref);
void spec_strip_value_ref_free(SpecStripValueRef *ref);

/* One piece a strip removed from a value, anchored in the stripped text. */
typedef struct {
  size_t anchor;     /* UTF-16 offset in the stripped text it stands at */
  size_t origin;     /* UTF-16 offset in the original text it starts at */
  char *removed;     /* owned; the original text the piece removed */
  char *inserted;    /* owned; the text the stripped value holds instead */
  SomStrList labels; /* what removed it, sorted */
} SpecStripPiece;

/* One entry of a stripped rendition's appendix *Notes*. */
typedef struct {
  long long number;
  char *kind; /* owned */
  char *text; /* owned */
  SpecStripValueRef *value; /* owned; the value it came from, NULL for the
                             * strip of one value */
} SpecAppendixEntry;

/* The result of stripping one value. */
typedef struct {
  char *text;                            /* owned */
  SpecStripPiece *pieces;
  size_t pieces_len;
  long long dropped[SPEC_STRIP_KIND_COUNT];  /* per kind, 0 when none */
  long long unmarked[SPEC_STRIP_KIND_COUNT];
  long long appended[SPEC_STRIP_KIND_COUNT];
  long long marks_dropped;               /* inline marks gone with a removal */
  SpecAppendixEntry *appendix;
  size_t appendix_len;
  SomStrList refused; /* the finding codes the value was refused for */
} SpecStripTextResult;

/* Strips one value with `options` (SOM §11.10): comments first, then the
 * notation from the outside in, then the whitespace the removals leave.
 * Appendix entries are numbered from 1. A value whose notation has an error
 * finding (other than `rejectedBlock`) is refused and returned unchanged.
 * Writes `*out` (free with spec_strip_text_result_free). */
void spec_strip_notation_text(const char *value, const SpecStripOptions *options,
                              SpecStripTextResult *out);

void spec_strip_text_result_free(SpecStripTextResult *r);

/* Whether the value was refused for its findings. */
int spec_strip_text_result_refused(const SpecStripTextResult *r);

/* The result as the corpus writes it (`text`, `dropped`, `unmarked`,
 * `appended`, `marksDropped`, `appendix`, `pieces`, `refused`). Owned JSON. */
char *spec_strip_text_result_to_json(const SpecStripTextResult *r);

/* ---- the strip of a document ---------------------------------------------- */

/* One value a strip changed, with what went. */
typedef struct {
  SpecStripValueRef ref;
  char *original; /* owned */
  char *stripped; /* owned */
  SpecStripPiece *pieces;
  size_t pieces_len;
} SpecStrippedValue;

/* A value the emptying rule kept: stripping it would have added `finding`. */
typedef struct {
  SpecStripValueRef ref;
  char *finding; /* owned */
} SpecStripKept;

/* A reason a stripped document is not valid. */
typedef struct {
  char *kind;    /* owned: `notation`, `instance`, `schema` or `parse` */
  char *message; /* owned */
  SpecStripValueRef *ref; /* owned, NULL when it is about no one value */
} SpecStripFinding;

/* The result of spec_document_strip. */
typedef struct {
  SpecDocument *document; /* owned heap copy, stripped */
  SpecStrippedValue *values;
  size_t values_len;
  SpecStripKept *kept;
  size_t kept_len;
  SomStrList removed_items; /* the list items left empty and removed */
  SpecAppendixEntry *appendix; /* numbered through the rendition */
  size_t appendix_len;
  long long dropped[SPEC_STRIP_KIND_COUNT];
  long long unmarked[SPEC_STRIP_KIND_COUNT];
  long long appended[SPEC_STRIP_KIND_COUNT];
  long long marks_dropped;
  char *readable_header; /* owned */
  char *readable;        /* owned rendition, NULL without a model */
  SpecStripFinding *findings;
  size_t findings_len;
} SpecStripResult;

/* What spec_document_strip takes beyond the switches; every member may be
 * NULL. */
typedef struct {
  const SpecModel *model;          /* the emptying rule, the rendition */
  const DocSpecsSchema *schema;    /* the schema tier of both checks */
  const char *root_type;           /* the root rendered; default the single
                                    * populated one */
  const SpecReadableSource *source; /* named in the readable header */
} SpecDocumentStripOptions;

/* Strips every value of `document` — content, form-field values and stored
 * headlines — into a copy (SOM §11.10). Given a model it also applies the
 * emptying rule (a value whose strip would add an instance or schema finding
 * is stripped with the keeping options instead, or left as it was), removes
 * list items left with nothing, numbers the appendix through the rendition,
 * renders the readable rendition and checks that it reads back and validates.
 * `extra` may be NULL. Writes `*out` (free with spec_strip_result_free). */
void spec_document_strip(const SpecDocument *document,
                         const SpecStripOptions *options,
                         const SpecDocumentStripOptions *extra,
                         SpecStripResult *out);

void spec_strip_result_free(SpecStripResult *r);

/* Whether the stripped document is valid and may be written. */
int spec_strip_result_ok(const SpecStripResult *r);

/* The report: what was dropped, unmarked, moved and kept per kind, one line
 * each, into `out` (initialised by the callee). */
void spec_strip_result_report(const SpecStripResult *r, SomStrList *out);

/* `<kind>: [<ref>: ]<message>`. Owned. */
char *spec_strip_finding_string(const SpecStripFinding *f);

/* The result as the corpus writes it (`document` as canonical document JSON,
 * `kept`, `removedItems`, `appendix`, `dropped`, `unmarked`, `appended`,
 * `marksDropped`, `readableHeader`, `readable`, `findings` by kind). Owned
 * JSON. */
char *spec_strip_result_to_json(const SpecStripResult *r);

#endif /* SPEC_DOCUMENT_STRIP_H */
