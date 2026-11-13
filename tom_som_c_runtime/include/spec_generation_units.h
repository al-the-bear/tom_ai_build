/* spec_generation_units — the generation-unit register of a document (SOM
 * §11.2): the units Phase 4 writes code into, each with the mapper of every area
 * it holds. A faithful port of the Dart `spec_generation_units.dart`.
 *
 * The register is recognised by its annotations, never by class name, exactly
 * as validation phase 8 recognises it (the validator uses the two recognition
 * helpers below): a **unit** is a list item whose class carries
 * `@NoArtifact(generation)` and declares the form field `unitId`; a **mapping**
 * is such a list item declaring the form field `area`, and belongs to the
 * nearest unit whose path is a prefix of its own.
 *
 * Ownership: a `SpecGenerationUnitList` owns every unit, mapping and string it
 * holds — release it with `spec_generation_unit_list_free`. The lists
 * `spec_default_units` writes are owned by the caller (`som_strlist_free`).
 */
#ifndef SPEC_GENERATION_UNITS_H
#define SPEC_GENERATION_UNITS_H

#include <stddef.h>

#include "som_util.h"
#include "spec_document.h"
#include "spec_model.h"

/* One mapping of a generation unit: the area it holds and the mapper that
 * writes that area's code for it. Owns its strings. */
typedef struct {
  /* The area code, `CE-…`, as stored (trimmed). */
  char *area;
  /* The mapper id, e.g. `dart-tom`, as stored (trimmed); empty when unset. */
  char *mapping;
} SpecGenerationUnitMapping;

/* One generation unit the document declares. Owns its strings and mappings. */
typedef struct {
  /* The unit's id — what a section's `units` names, usually the package
   * name. */
  char *unit_id;
  /* `client`, `server`, `shared` or `other`, as stored; empty when unset. */
  char *kind;
  /* The unit's list-item path in the document. */
  char *path;
  /* The unit's mappings, in stored order. */
  SpecGenerationUnitMapping *mappings;
  size_t mappings_len;
  size_t mappings_cap;
} SpecGenerationUnit;

/* Whether one of the unit's mappings holds `area_code`. */
int spec_generation_unit_maps(const SpecGenerationUnit *u,
                              const char *area_code);

/* The mapper of `area_code` — the first mapping that holds it — or NULL.
 * Borrowed from `u`. */
const char *spec_generation_unit_mapping_for(const SpecGenerationUnit *u,
                                             const char *area_code);

/* An owning list of generation units. A zeroed list is empty. */
typedef struct {
  SpecGenerationUnit *items;
  size_t len;
  size_t cap;
} SpecGenerationUnitList;

void spec_generation_unit_list_init(SpecGenerationUnitList *l);
void spec_generation_unit_list_free(SpecGenerationUnitList *l);

/* The generation units `doc` declares, in register order, written into `out`
 * (initialised by the callee): sorted list-path order, each list's items in
 * their stored order — the order validation phase 8 visits them in. A unit
 * without a `unitId` is left out; a second unit with an id already seen is left
 * out too (phase 8 reports it as `duplicateUnitId`). A document without a
 * register declares none. */
void spec_generation_units(const SpecModel *model, const SpecDocument *doc,
                           SpecGenerationUnitList *out);

/* The ids of the units of `units` whose mappings hold `area_code`, in register
 * order, written into `out` (initialised by the callee) — the default
 * destination of a section routed to that area (SOM §11.2). */
void spec_default_units(const SpecGenerationUnitList *units,
                        const char *area_code, SomStrList *out);

/* ---- recognition helpers shared with validation phase 8 ------------------ */

/* The form field of `cls` that declares a form field named `name`, or NULL.
 * Borrowed from `cls`. */
const SpecField *spec_generation_form_declaring(const SpecClass *cls,
                                                const char *name);

/* Whether `cls` carries `@NoArtifact(generation)`. */
int spec_generation_is_register(const SpecClass *cls);

#endif /* SPEC_GENERATION_UNITS_H */
