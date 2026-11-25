/* spec_document_strip_internal — what the strip (spec_document_strip.c) shares
 * with the merge back (spec_document_merge.c): its edit scripts, the line
 * diff, the inline-mark finder, a document's value references and the tier
 * findings a strip and a merge compare. Not installed; not part of the API.
 */
#ifndef SPEC_DOCUMENT_STRIP_INTERNAL_H
#define SPEC_DOCUMENT_STRIP_INTERNAL_H

#include <stddef.h>

#include "docspecs_validator.h"
#include "som_util.h"
#include "spec_document.h"
#include "spec_document_strip.h"
#include "spec_model.h"

/* One step of a byte-wise edit script. */
enum { OP_KEEP = 0, OP_DEL = 1, OP_INS = 2 };

typedef struct {
  int type;
  char ch;
  const char *label; /* borrowed (a plan's label pool or a literal) */
} Op;

typedef struct {
  Op *items;
  size_t len, cap;
} OpVec;

/* A token: a range of a string. */
typedef struct {
  const char *p;
  size_t n;
} Tok;

typedef struct {
  Tok *items;
  size_t len, cap;
} TokVec;

/* One step of a token edit script. */
typedef struct {
  int type;
  Tok tok;
} Edit;

typedef struct {
  Edit *items;
  size_t len, cap;
} EditVec;

/* An inline mark of a value (byte offsets). */
typedef struct {
  size_t start, end, body_start, body_end;
  long sep; /* `~>` of a substitution, -1 otherwise */
} MarkAt;

/* An ordered map of finding keys to the paths they concern (`Map<string,
 * string>`): a key set again keeps its place and takes the new path. */
typedef struct {
  SomStrList keys;
  SomStrList paths;
} KeyPaths;

void spec_strip_ops_push(OpVec *v, int type, char ch, const char *label);

/* The edit script from `a` to `b` (`_diff`): Myers by line, then by word
 * token, one op per byte; changed ops carry `label`. */
void spec_strip_diff(const char *a, const char *b, const char *label,
                     OpVec *out);

/* `s` as lines, each with its line break (`_lines`). */
void spec_strip_lines(const char *s, TokVec *out);

/* Myers' shortest edit script between token lists (`_myers`). */
void spec_strip_myers(const TokVec *a, const TokVec *b, EditVec *out);

/* The inline marks of `t` outside code (`_findMarks`). Owned array. */
void spec_strip_find_marks(const char *t, MarkAt **out, size_t *out_len);

/* Every value of `doc`: stored headlines, content, form fields, each group
 * sorted (`_valueRefs`). Owned array of owned refs. */
void spec_strip_value_refs(const SpecDocument *doc, SpecStripValueRef **out,
                           size_t *out_len);

/* The instance tier's and (given a schema) the schema tier's findings of
 * `doc` (`_tierFindings`), into `out` (initialised by the callee). */
void spec_strip_tier_findings(const SpecModel *model,
                              const DocSpecsSchema *schema,
                              const char *root_type, const SpecDocument *doc,
                              KeyPaths *out);

/* The index of `key` in `m`, or -1. */
long spec_strip_key_paths_find(const KeyPaths *m, const char *key);
void spec_strip_key_paths_free(KeyPaths *m);

#endif /* SPEC_DOCUMENT_STRIP_INTERNAL_H */
