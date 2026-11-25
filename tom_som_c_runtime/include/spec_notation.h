/* spec_notation — the reading notation's scanner: one call per text value,
 * returning the value's fenced divs, bracketed spans and citation shapes with
 * their kind, attributes, source ranges and nesting, and the findings the
 * DocSpecs specification lists for the notation (*Reading Notation*, RN-1 …
 * RN-13).
 *
 * The C port of `tom_som_dart_runtime`'s `spec_notation.dart` (and the
 * TypeScript `spec_notation.ts`): the same grammar, the same elements and
 * findings; all run `tom_som_conformance/corpus/notation_cases.json`.
 *
 * - a **fenced div** is a line of at least three colons, indented up to three
 *   spaces, then attribute braces (`::: {.provenance}`) or a bare kind word
 *   (`::: aside`); it closes at a line of at least three colons and nothing
 *   else, and a closing fence closes the innermost open div;
 * - a **bracketed span** is `[text]` followed immediately by attribute braces,
 *   inside one paragraph;
 * - a **citation shape** is `(-> ids)` (kind `trace`), `(<- source)` or
 *   `(<~ source)` (kind `provenance`);
 * - fenced code and code spans are literal, and so are `\:::` and `]\{.`.
 *
 * An unknown kind passes through as an element like any other.
 *
 * Offsets: the text is UTF-8. Every element and finding carries its byte
 * offsets (`start`, `end`, …, into the text as given) and the same positions
 * in UTF-16 code units (`*_utf16`), the unit the other runtimes and the
 * corpus count in.
 */
#ifndef SPEC_NOTATION_H
#define SPEC_NOTATION_H

#include <stddef.h>

#include "som_util.h"

/* The kinds the notation registers (RN-5); any other kind passes through. */
#define SPEC_REGISTERED_NOTATION_KINDS_COUNT 9
extern const char *const
    SPEC_REGISTERED_NOTATION_KINDS[SPEC_REGISTERED_NOTATION_KINDS_COUNT];

/* Whether `kind` is one of SPEC_REGISTERED_NOTATION_KINDS. */
int spec_notation_kind_registered(const char *kind);

/* What an element of the notation is. */
typedef enum {
  SPEC_NOTATION_DIV = 0,
  SPEC_NOTATION_SPAN = 1,
  SPEC_NOTATION_CITATION = 2,
} SpecNotationElementType;

/* "div", "span" or "citation". */
const char *spec_notation_element_type_name(SpecNotationElementType t);

/* The notation's findings (RN-10), in declaration order; each name is the
 * rule's name in the DocSpecs validator. */
typedef enum {
  SPEC_NOTATION_UNCLOSED_DIV = 0,
  SPEC_NOTATION_STRAY_CLOSING_FENCE,
  SPEC_NOTATION_UNCLOSED_SPAN,
  SPEC_NOTATION_DIV_WITHOUT_KIND,
  SPEC_NOTATION_UNKNOWN_KIND,
  SPEC_NOTATION_MARK_ACROSS_NOTATION,
  SPEC_NOTATION_ANNOTATION_INSIDE_DIV,
  SPEC_NOTATION_DIV_INSIDE_ANNOTATION,
  SPEC_NOTATION_REJECTED_BLOCK,
} SpecNotationFindingCode;

#define SPEC_NOTATION_FINDING_CODE_COUNT 9

/* The code's name: `unclosedDiv`, `strayClosingFence`, … (static string). */
const char *spec_notation_finding_code_name(SpecNotationFindingCode code);

/* The severity of `code`: "warning" for an unknown kind, "error" for the
 * rest (static string). */
const char *spec_notation_severity(SpecNotationFindingCode code);

/* One element of the notation: a div, a span or a citation. */
typedef struct SpecNotationElement SpecNotationElement;
struct SpecNotationElement {
  SpecNotationElementType type;
  char *kind;            /* owned; the first class (`trace` / `provenance` for
                          * a citation); NULL without a class */
  SomStrList classes;    /* every class, the kind first */
  char *id;              /* owned; the `#id` of the attributes (not a section
                          * id); NULL when none */
  SomStrList attr_keys;  /* the `key="value"` pairs, in their order */
  SomStrList attr_values;
  char *shape;           /* owned; a citation's arrow `->`, `<-` or `<~`;
                          * NULL otherwise */
  size_t start;          /* byte offset of the first character */
  size_t end;            /* byte offset after the last character */
  size_t content_start;  /* byte offset of the content */
  size_t content_end;    /* byte offset after the content */
  size_t start_utf16;    /* the four offsets above in UTF-16 code units */
  size_t end_utf16;
  size_t content_start_utf16;
  size_t content_end_utf16;
  int line;              /* 1-based line of start */
  int end_line;          /* 1-based line of the last character */
  int closed;            /* 0 for a div without a closing fence */
  SpecNotationElement **children; /* owned; nested elements, source order */
  size_t children_len;
  size_t children_cap;
};

/* Whether the element's kind is registered. */
int spec_notation_element_registered(const SpecNotationElement *e);

/* One finding of the scan. */
typedef struct {
  SpecNotationFindingCode code;
  size_t offset;       /* byte offset */
  size_t offset_utf16; /* the same in UTF-16 code units */
  int line;            /* 1-based */
  char *message;       /* owned */
} SpecNotationFinding;

/* The result of spec_scan_notation. */
typedef struct {
  char *text;                      /* owned copy of the scanned text */
  SpecNotationElement **elements;  /* owned; elements not nested in another,
                                    * in source order */
  size_t elements_len;
  SpecNotationFinding *findings;   /* owned; by offset, then code order */
  size_t findings_len;
} SpecNotationScan;

/* Scans one text value for the reading notation. `tom_specs` says the value
 * belongs to a TomSpecs rendition: only then are a div without a class and an
 * unregistered kind reported (RN-10). Writes `*out` (free with
 * spec_notation_scan_free). */
void spec_scan_notation(const char *text, int tom_specs,
                        SpecNotationScan *out);

void spec_notation_scan_free(SpecNotationScan *scan);

/* Whether a finding of severity error is present. */
int spec_notation_scan_has_errors(const SpecNotationScan *scan);

/* Every element, depth-first in source order: a newly allocated array of
 * `*out_len` borrowed pointers (free the array with free()); NULL when none. */
const SpecNotationElement **spec_notation_scan_all(const SpecNotationScan *scan,
                                                   size_t *out_len);

/* The element as the conformance corpus writes it (`type`, `kind`,
 * `classes`, `id`, `attributes`, `shape`, UTF-16 `start` / `end`, `line`,
 * `endLine`, `closed`, `source`, `content`, `children`). Owned JSON text. */
char *spec_notation_element_to_json(const SpecNotationElement *e,
                                    const char *text);

/* The finding as the corpus writes it (`code`, `severity`, `line`). Owned
 * JSON text. */
char *spec_notation_finding_to_json(const SpecNotationFinding *f);

/* The scan's top-level elements / findings as JSON arrays of the forms
 * above. Owned JSON text. */
char *spec_notation_scan_elements_json(const SpecNotationScan *scan);
char *spec_notation_scan_findings_json(const SpecNotationScan *scan);

#endif /* SPEC_NOTATION_H */
