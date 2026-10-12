/* spec_document_assembly — assembling one spec document from fragments written
 * in parallel, a port of the Dart reference `spec_document_assembly.dart`.
 *
 * A large document is often authored in parts — one group, or one agent, per
 * set of sections — each part a document of its own holding a subset of the
 * sections. References between parts can only be judged on the whole: the
 * instance tier resolves a `refersTo` against the document it is given, so a
 * part validated alone reports every reference into another part as dangling.
 * `spec_document_assemble` is the step that produces the whole.
 *
 * The merge is over the plain-data stores (`spec_document_to_json`), and it is
 * **refusing**: a value two fragments both write — a content path, a form
 * field, a list, a headline, a code-spec location — is an overlap, and an
 * assembly with any overlap yields no document. Choosing a winner would make
 * the result depend on fragment order, and two parts writing one place is an
 * authoring conflict the parts' authors have to settle.
 *
 *   - content / headlines / codeSpecs: one value per path; a path written by
 *     two or more fragments is an overlap.
 *   - forms: merged field by field — two fragments may fill different fields
 *     of one form; a (path, field) written by two or more is an overlap.
 *   - lists: a list path held by two or more fragments is an overlap (the
 *     whole list — seq, items, ids — comes from one fragment).
 *
 * Overlaps are reported in store order content, forms, lists, headlines,
 * codeSpecs, then by path (and field) byte-sorted, each naming its fragments
 * in the order they were given.
 *
 * Ownership: the fragments (names and documents) are borrowed for the call
 * only. The result owns its document and overlaps; release it with
 * `spec_document_assembly_free`.
 */
#ifndef SPEC_DOCUMENT_ASSEMBLY_H
#define SPEC_DOCUMENT_ASSEMBLY_H

#include <stddef.h>

#include "som_util.h"
#include "spec_document.h"

/* One fragment: a name and its document, both borrowed. */
typedef struct {
  const char *name;
  const SpecDocument *document;
} SpecAssemblyFragment;

/* One place two or more fragments both write. */
typedef struct {
  /* The store: "content", "forms", "lists", "headlines" or "codeSpecs" — a
   * static string, not owned. */
  const char *store;
  char *path;           /* the document path, owned */
  char *field;          /* the form field for the `forms` store, else NULL; owned */
  SomStrList fragments; /* the fragments that write it, in the given order */
} SpecAssemblyOverlap;

/* One sentence naming the place and every fragment that writes it — the Dart
 * reference's `SpecAssemblyOverlap.message`, verbatim. Owned result. */
char *spec_assembly_overlap_message(const SpecAssemblyOverlap *o);

/* The result of `spec_document_assemble`. */
typedef struct {
  /* The assembled document (owned heap; released by
   * `spec_document_assembly_free`); NULL when there is any overlap. */
  SpecDocument *document;
  /* Every overlap, in store order and then path order. */
  SpecAssemblyOverlap *overlaps;
  size_t overlaps_len;
} SpecDocumentAssembly;

/* Returns 1 when the fragments assembled (no overlaps), else 0. */
int spec_document_assembly_ok(const SpecDocumentAssembly *a);

/* Releases the document and every overlap, leaving `a` empty. */
void spec_document_assembly_free(SpecDocumentAssembly *a);

/* Merges `fragments` (an ordered array of `fragments_len` name/document pairs)
 * into one document, writing the result into `out` (initialised by callee).
 * See the file comment for the refusing rule. The SpecDocument.assemble of the
 * Dart reference. */
void spec_document_assemble(const SpecAssemblyFragment *fragments,
                            size_t fragments_len, SpecDocumentAssembly *out);

#endif /* SPEC_DOCUMENT_ASSEMBLY_H */
