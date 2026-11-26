/* spec_document_merge — the merge back (SOM §11.10; the reading view's part
 * *Stripped renditions and the merge back*): an edited readable rendition
 * merged onto the document of record, every piece the strip removed put
 * back.
 *
 * `spec_merge_stripped_value` merges one value: the edited text against the
 * stripped one, each piece of the strip put back where the edit left its
 * neighbours, after an edited run (PLACED, for an author to check), or
 * refused as a conflict. `spec_strip_merge` merges a whole edited rendition:
 * the readable header names the switches, a stale original merges three ways
 * from the original at the export (given, or loaded from the header's
 * commit, `spec_strip_merge_git_show_file`), structural edits are refused,
 * and the merged document is checked to strip back to the edited text.
 *
 * The C port of `spec_document_merge.dart` / `.ts`; `strip_merge_cases.json`
 * holds them to the same results. Texts are UTF-8; the offsets in results
 * (`at`) count UTF-16 code units, as the corpus and the other runtimes do.
 */
#ifndef SPEC_DOCUMENT_MERGE_H
#define SPEC_DOCUMENT_MERGE_H

#include <stddef.h>

#include "docspecs_validator.h"
#include "som_util.h"
#include "spec_document.h"
#include "spec_document_strip.h"
#include "spec_model.h"

/* A piece put back after an edited run rather than between unchanged
 * neighbours: an author confirms or moves it (`PLACED <value> — check`). */
typedef struct {
  size_t at;     /* UTF-16 offset in the merged value its text starts at */
  char *removed; /* owned; the piece's text */
} SpecStripMergePlaced;

/* Why a value, or the whole merge, cannot be merged. `code` is one of
 * `crossesBoundary`, `sentenceRemoved`, `stripTextEdited`, `unplaceable`,
 * `notation`, `annotations`, `changedBothSides`, `notStrippedBack` and
 * `newFinding`. */
typedef struct {
  char *code;    /* owned */
  char *message; /* owned */
  SpecStripValueRef *ref; /* owned; the value, NULL for the document */
  char *removed; /* owned; the piece's text, NULL when about no piece */
  char *excerpt_o; /* owned; the original, the stripped and the edited text */
  char *excerpt_b; /* around the place, `«…»` with `⏎` for line breaks; ""   */
  char *excerpt_e; /* when not given                                         */
} SpecStripMergeConflict;

/* `CONFLICT <value> — <reason>`, then the three excerpts and the piece, into
 * `out` (initialised by the callee). */
void spec_strip_merge_conflict_report_lines(const SpecStripMergeConflict *c,
                                            SomStrList *out);

/* The result of spec_merge_stripped_value. */
typedef struct {
  char *text; /* owned; the merged value, NULL when there are conflicts */
  long long restored; /* how many pieces were put back */
  SpecStripMergePlaced *placed;
  size_t placed_len;
  SpecStripMergeConflict *conflicts;
  size_t conflicts_len;
} SpecStripValueMerge;

/* Merges the edited text `e` of one value back onto its original `o` (SOM
 * §11.10): `b` is `o` stripped and `pieces` what the strip removed, anchored
 * in `b` (the strip's pieces as spec_strip_notation_text returns them).
 * Writes `*out` (free with spec_strip_value_merge_free). */
void spec_merge_stripped_value(const char *o, const char *b, const char *e,
                               const SpecStripPiece *pieces, size_t pieces_len,
                               SpecStripValueMerge *out);

void spec_strip_value_merge_free(SpecStripValueMerge *m);
int spec_strip_value_merge_ok(const SpecStripValueMerge *m);

/* `{text, restored, placed: [{at, removed}], conflicts: [{code, value?,
 * removed?}]}`, as the corpus writes it. Owned JSON. */
char *spec_strip_value_merge_to_json(const SpecStripValueMerge *m);

/* The name of a value in a merge report: `<path> (headline)`,
 * `<path> / <field>` or `<path>`. Owned. */
char *spec_strip_merge_label(const SpecStripValueRef *ref);

/* One value a document merge changed. */
typedef struct {
  SpecStripValueRef ref;
  char *text; /* owned; the merged value written into the document */
  long long restored;
  SpecStripMergePlaced *placed;
  size_t placed_len;
} SpecStripMergedValue;

/* An edit a merge refuses. `code` is one of `sectionAdded`,
 * `sectionRemoved`, `sectionMoved`, `listItems`, `codeSpec`, `units`,
 * `rejected`, `stale` and `strip`; `path` is "" for the document. */
typedef struct {
  char *code;
  char *path;
  char *message;
} SpecStripMergeRefusal;

/* The result of spec_strip_merge. */
typedef struct {
  SpecDocument *document; /* owned heap document; NULL when nothing may be
                           * written */
  SpecStripOptions options; /* the switches the rendition was stripped with */
  int stale; /* whether the merge was three-way from the original at the
              * export */
  SpecStripMergedValue *merged;
  size_t merged_len;
  SpecStripMergeConflict *conflicts;
  size_t conflicts_len;
  SpecStripMergeRefusal *refusals;
  size_t refusals_len;
} SpecStripMergeResult;

void spec_strip_merge_result_free(SpecStripMergeResult *r);
int spec_strip_merge_result_ok(const SpecStripMergeResult *r);
/* `0` merged or nothing to merge, `1` conflicts or refusals. */
int spec_strip_merge_result_exit_code(const SpecStripMergeResult *r);
/* MERGED / PLACED lines per merged value, then the conflicts' lines, then
 * `REFUSED <path> — <reason>` per refusal, into `out` (initialised by the
 * callee). */
void spec_strip_merge_result_report(const SpecStripMergeResult *r,
                                    SomStrList *out);

/* Loads the original as it was at the export from the readable header's
 * source (its commit); returns an owned heap document (released by the
 * merge with spec_document_free + free) or NULL. */
typedef SpecDocument *(*SpecStripLoadBase)(const SpecReadableSource *source,
                                           void *context);

/* What spec_strip_merge takes beyond the document and the rendition. */
typedef struct {
  const SpecModel *model;          /* required */
  const DocSpecsSchema *schema;    /* NULL: no schema tier */
  const char *root_type;           /* NULL: the single populated root */
  const SpecStripOptions *options; /* switches given beside the readable
                                    * header; they must agree with it; NULL
                                    * when none */
  const char *current_revision;    /* the original's revision now, NULL when
                                    * not known */
  const SpecDocument *base;        /* the original at the export, given by
                                    * hand; NULL when none */
  SpecStripLoadBase load_base;     /* NULL: no loader */
  void *load_base_context;
  const char *file_stem;           /* the codec's file stem
                                    * (SpecMarkdownExportOptions.file_stem) */
  const SomMap *document_files;    /* the codec's document files */
} SpecStripMergeOptions;

/* Merges `edited`, a `.readable.md` made from `original` and changed by a
 * reader, back onto `original` (SOM §11.10). A usage error — a readable
 * header that cannot be read, switches that disagree with it, a rendition
 * without a header and without switches — returns 0 with `*error` (owned,
 * when non-NULL) and `*out` empty; else returns 1 writing `*out` (free with
 * spec_strip_merge_result_free). */
int spec_strip_merge(const SpecDocument *original, const char *edited,
                     const SpecStripMergeOptions *extra,
                     SpecStripMergeResult *out, char **error);

/* The file at `file_path` as it was at `commit` (`git show
 * <commit>:./<name>`, run in the file's folder), or NULL when git cannot
 * give it. Owned. */
char *spec_strip_merge_git_show_file(const char *commit, const char *file_path);

#endif /* SPEC_DOCUMENT_MERGE_H */
