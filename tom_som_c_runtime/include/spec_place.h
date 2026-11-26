/* spec_place — places and filters of the link vocabulary
 * (`tom_specs_model_rules.md` §9.7): the grammar every link annotation names
 * places in, parsed once and resolved under an anchor through the reflection
 * surface — a port of `tom_som_dart_runtime/lib/src/spec_place.dart` (and the
 * Go `spec_place.go` / Rust `spec_place.rs`).
 *
 *   - A place names a section, a list, a form field, a heading, a content
 *     value or a registry id: `FRED.description`, `FRE.@headline`,
 *     `FRE-REQU-LST`, `./RQDEP`, `FRE/REQDEP/RQDEP.description`,
 *     `<SECTIONID>.@content`, `<SECTIONID>.@sectionId` (SpecPlace).
 *   - A filter selects entries by one of their form values: `<SECTIONID>`,
 *     `./<SECTIONID>`, `<SECTIONID>.<field>=<value>` with `|` between
 *     alternatives (`FRE.priority=must|should`) (SpecPlaceFilter). `countOf`
 *     and every `where:` read it.
 *
 * Resolution is value-free, like the reflection: it says where in a document
 * the place is stored, with every list item below the anchor written
 * `<list>-*`, and never reads a value.
 *
 * Ownership: every struct owns its strings unless a member says it borrows
 * from the model; release with its `*_free` (safe on a zeroed struct). The
 * `*_to_json` functions return owned JSON text. */
#ifndef SPEC_PLACE_H
#define SPEC_PLACE_H

#include "som_util.h"
#include "spec_model.h"
#include "spec_reflection.h"

/* ---- what a resolved place is (the corpus compares the strings) ---------- */

/* A section (a class's own node or a complex member), whole. */
#define SPEC_PLACE_KIND_SECTION "section"
/* A `-LST` list container. */
#define SPEC_PLACE_KIND_LIST "list"
/* A form member, every field of it. */
#define SPEC_PLACE_KIND_FORM "form"
/* One field of a form. */
#define SPEC_PLACE_KIND_FORM_FIELD "formField"
/* The stored headline of a section (`.@headline`). */
#define SPEC_PLACE_KIND_HEADLINE "headline"
/* The content value of a section (`.@content`, or a content member). */
#define SPEC_PLACE_KIND_CONTENT "content"
/* The stored section id of a list element (`.@sectionId`). */
#define SPEC_PLACE_KIND_SECTION_ID "sectionId"

/* ---- why a place or a filter does not parse or resolve ------------------- */

/* The text is not a place (or not a filter) of the grammar. */
#define SPEC_PLACE_PROBLEM_MALFORMED "malformed"
/* The anchor path resolves to no section of the model. */
#define SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED "anchorUnresolved"
/* The place is `./`-scoped, but no list element lies at or above the anchor. */
#define SPEC_PLACE_PROBLEM_NOT_SCOPED "notScoped"
/* No section with the place's id (and `/` path) lies in the scope. */
#define SPEC_PLACE_PROBLEM_UNRESOLVED "unresolved"
/* The place's id is reached at more than one position in the scope. */
#define SPEC_PLACE_PROBLEM_AMBIGUOUS "ambiguous"
/* The named field is no form field of the section. */
#define SPEC_PLACE_PROBLEM_NO_SUCH_FIELD "noSuchField"
/* `.@content` names a section that holds no content value. */
#define SPEC_PLACE_PROBLEM_NO_CONTENT "noContent"
/* `.@sectionId` names a section that is no list element. */
#define SPEC_PLACE_PROBLEM_NOT_LIST_ELEMENT "notListElement"
/* A slot starting with `@` other than `@headline`, `@content`, `@sectionId`. */
#define SPEC_PLACE_PROBLEM_RESERVED_SLOT "reservedSlot"

/* A place or filter that does not parse or resolve, with the reason. */
typedef struct {
  /* What went wrong (a SPEC_PLACE_PROBLEM_* literal, static); the corpus
   * compares this, never the message. NULL for a failure that is no place
   * problem (an ancestor of the anchor that resolves to no class). */
  const char *problem;
  char *text;    /* the place or filter as written, owned */
  char *message; /* the prose for the reader, owned */
} SpecPlaceError;

void spec_place_error_init(SpecPlaceError *e);
void spec_place_error_free(SpecPlaceError *e);

/* ---- SpecPlace -------------------------------------------------------------- */

/* A place as written: `./` scope, `/` segments, section id and slot. */
typedef struct {
  char *text;        /* the text it was parsed from */
  int scoped;        /* written `./...`: beneath the nearest list element */
  SomStrList prefix; /* the section ids written before the last `/` */
  char *section_id;  /* the section id the place names */
  /* The part after the dot: a form field name, `@headline`, `@content`,
   * `@sectionId`; NULL for the section, list or form itself. */
  char *slot;
} SpecPlace;

/* Parses `text`; returns 1 and fills `*out`, or 0 (out untouched) when it is
 * not a place. */
int spec_place_try_parse(const char *text, SpecPlace *out);
/* Parses `text`; on failure fills `*err` (`malformed`) and returns 0. */
int spec_place_parse(const char *text, SpecPlace *out, SpecPlaceError *err);
void spec_place_free(SpecPlace *p);
/* The parsed parts, for the corpus. */
char *spec_place_to_json(const SpecPlace *p);

/* Where a place is stored in a document. */
typedef struct {
  /* What the place is (a SPEC_PLACE_KIND_* literal, static). */
  const char *kind;
  /* The document path the value lives at, every list item beneath the
   * anchor written `<list>-*`: the section (or list item) for a section, a
   * headline or a section id; the list for a list; the form for a form or a
   * form field; the content leaf for a content value. Owned. */
  char *path;
  /* The class of the section the place sits on (for a member, its owner).
   * Borrowed from the model. */
  const char *class_name;
  /* The section ids on the way from the scope to the place, its own last. */
  SomStrList section_ids;
  /* For SPEC_PLACE_KIND_FORM_FIELD, the field (borrowed); NULL otherwise. */
  const FormFieldSpec *form_field;
} SpecPlaceResolution;

void spec_place_resolution_init(SpecPlaceResolution *r);
void spec_place_resolution_free(SpecPlaceResolution *r);
/* The form field name for SPEC_PLACE_KIND_FORM_FIELD, else NULL. */
const char *spec_place_resolution_field(const SpecPlaceResolution *r);
/* The canonical JSON form the corpus compares. */
char *spec_place_resolution_to_json(const SpecPlaceResolution *r);

/* Resolves `place` under `anchor`, a document path of a section (a root, a
 * complex or section member, or a list item). Returns 1 and fills `*out`, or
 * 0 and fills `*err` when the place does not resolve.
 *
 * The place is looked for in the subtree of the anchor's class — beneath the
 * nearest list element at or above the anchor when it is `./`-scoped — among
 * the positions whose section id is `section_id` and whose path holds the
 * `prefix` ids in order (only `-LST` containers and the scope's own id may lie
 * between them). More than one such position is `ambiguous`. */
int spec_place_resolve(const SpecPlace *place, const SpecReflection *refl,
                       const char *anchor, SpecPlaceResolution *out,
                       SpecPlaceError *err);

/* ---- SpecPlaceFilter -------------------------------------------------------- */

/* An entry filter: `<SECTIONID>`, `./<SECTIONID>` or
 * `<SECTIONID>.<field>=<value>[|<value>...]`, optionally `./`-scoped. It
 * selects the entries (list elements of the class with that section id) one
 * of whose own forms holds one of `values` in `field`; without a field every
 * entry. */
typedef struct {
  char *text;       /* the text it was parsed from */
  int scoped;       /* written `./...` */
  char *section_id; /* the section id of the entries */
  char *field;      /* the form field compared, NULL for every entry */
  SomStrList values; /* the values accepted, in written order */
} SpecPlaceFilter;

int spec_place_filter_try_parse(const char *text, SpecPlaceFilter *out);
int spec_place_filter_parse(const char *text, SpecPlaceFilter *out,
                            SpecPlaceError *err);
void spec_place_filter_free(SpecPlaceFilter *f);
/* Whether an entry whose `field` holds `stored` (values trimmed, as many as
 * its forms hold) is selected. */
int spec_place_filter_matches(const SpecPlaceFilter *f,
                              const char *const *stored, size_t stored_len);
/* `spec_place_filter_matches` over a string list. */
int spec_place_filter_matches_list(const SpecPlaceFilter *f,
                                   const SomStrList *stored);
/* The place of the entries: `section_id`, scoped as the filter is. `*out` is
 * filled in full. */
void spec_place_filter_place(const SpecPlaceFilter *f, SpecPlace *out);
/* Resolves the entries under `anchor` as `spec_place_resolve` does, and checks
 * that `field` is a field of one of the entry's own forms. */
int spec_place_filter_resolve(const SpecPlaceFilter *f,
                              const SpecReflection *refl, const char *anchor,
                              SpecPlaceResolution *out, SpecPlaceError *err);
/* The parsed parts, for the corpus. */
char *spec_place_filter_to_json(const SpecPlaceFilter *f);

/* ---- @SameAs bindings and section positions ------------------------------ */

/* A `@SameAs` copy at one position of a document root, with its holder. */
typedef struct {
  char *root;            /* the root type the positions are in */
  const char *class_name; /* the class both positions hold (borrowed) */
  char *copy_path;       /* the copy's document path (items `<list>-*`) */
  SomStrList copy_section_ids;
  char *holder_path;     /* NULL when `problem` is set */
  SomStrList holder_section_ids;
  /* Why no single holder was found: `unresolved` or `ambiguous` (static);
   * NULL when `holder_path` is set. */
  const char *problem;
} SpecSameAsBinding;

typedef struct {
  SpecSameAsBinding *items;
  size_t len;
} SpecSameAsBindingList;

void spec_same_as_binding_list_free(SpecSameAsBindingList *l);
char *spec_same_as_binding_to_json(const SpecSameAsBinding *b);

/* Every `@SameAs` copy the document root `root_type` reaches, each with its
 * holder (`tom_specs_model_rules.md` §9.7, invariant `SAME-AS`): among the
 * positions of the copy's class in the root that are no copy themselves, the
 * one whose section-id path ends with `holder`, or — without `holder` — the
 * one there is. In position order. `*out` initialised by the callee. */
void spec_same_as_bindings(const SpecReflection *refl, const char *root_type,
                           SpecSameAsBindingList *out);

/* One position of a section in a document root: a class reached there (its
 * own node), or a member of a class that carries a section id of its own. */
typedef struct {
  char *path;             /* list items written `<list>-*` */
  const char *class_name; /* the class reached, or the member's owner */
  SomStrList section_ids; /* from the root to here, its own last */
  int is_member;          /* a member position rather than a class reached */
  /* For a class position, the member it is reached through (NULL at the
   * root); for a member position, the member itself. Borrowed. */
  const SpecField *member;
} SpecSectionPosition;

typedef struct {
  SpecSectionPosition *items;
  size_t len;
} SpecSectionPositionList;

void spec_section_position_list_free(SpecSectionPositionList *l);

/* Every section position of the document root `root_type`, in walk order: a
 * class reached again on its own path is not descended into, and a
 * `@Reference` member's target is not walked. `*out` initialised by the
 * callee. */
void spec_section_positions(const SpecReflection *refl, const char *root_type,
                            SpecSectionPositionList *out);

#endif /* SPEC_PLACE_H */
