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
 * The C port of `spec_document_strip.dart` / `.ts` for one value
 * (`stripNotationText`); `strip_cases.json` holds them to the same results.
 * The text is UTF-8; a piece's `anchor` and `origin` count UTF-16 code units,
 * as the corpus and the other runtimes do. The strip of a whole document
 * (`SpecDocumentStrip`, the readable header, heading divs) is not in this
 * port yet.
 */
#ifndef SPEC_DOCUMENT_STRIP_H
#define SPEC_DOCUMENT_STRIP_H

#include <stddef.h>

#include "som_util.h"

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

#endif /* SPEC_DOCUMENT_STRIP_H */
