/* spec_generation_units — the generation-unit register of a document (SOM
 * §11.2): the units Phase 4 writes code into, each with the mapper of every
 * area it holds. An idiomatic-C++ port of the Dart `spec_generation_units`
 * library.
 *
 * The register is recognised by its annotations, never by class name, exactly
 * as validation phase 8 recognises it: a **unit** is a list item whose class
 * carries `@NoArtifact(generation)` and declares the form field `unitId`; a
 * **mapping** is such a list item declaring the form field `area`, and belongs
 * to the nearest unit whose path is a prefix of its own; an **emitter** is
 * such a list item declaring the form field `emitter`, and belongs to its unit
 * the same way.
 */
#ifndef SPEC_GENERATION_UNITS_HPP
#define SPEC_GENERATION_UNITS_HPP

#include <array>
#include <optional>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

/* One mapping of a generation unit: the area it holds and the mapper that
 * writes that area's code for it. */
struct SpecGenerationUnitMapping {
  /* The area code, `CE-…`, as stored (trimmed). */
  std::string area;
  /* The mapper id, e.g. `dart-tom`, as stored (trimmed); empty when unset. */
  std::string mapping;
};

/* The standard emitters a unit's `emitters` may name (`irspecs_ir.md` §10),
 * in the order `irspecs emit` lists them. Validation phase 8 reports any other
 * id as `unitEmitterUnknown`. */
inline constexpr std::array<const char*, 4> kSpecStandardEmitters = {
    "openapi", "jsonschema", "icu", "asyncapi"};

/* Whether `id` is one of kSpecStandardEmitters (case-sensitive). */
bool specIsStandardEmitter(const std::string& id);

/* One generation unit the document declares. */
struct SpecGenerationUnit {
  /* The unit's id — what a section's `units` names, usually the package name. */
  std::string unitId;
  /* `client`, `server`, `shared` or `other`, as stored; empty when unset. */
  std::string kind;
  /* The unit's list-item path in the document. */
  std::string path;
  /* The unit's mappings, in stored order. */
  std::vector<SpecGenerationUnitMapping> mappings;
  /* The standard emitters the unit ships (`irspecs_ir.md` §10), as stored
   * (trimmed), in stored order; an emitter with no id is left out. */
  std::vector<std::string> emitters;

  /* Whether one of the unit's mappings holds `areaCode`. */
  bool maps(const std::string& areaCode) const;

  /* The mapper of `areaCode` — the first mapping that holds it — or
   * std::nullopt. */
  std::optional<std::string> mappingFor(const std::string& areaCode) const;
};

/* The generation units `doc` declares, in register order: sorted list-path
 * order, each list's items in their stored order — the order validation phase
 * 8 visits them in. A unit without a `unitId` is left out; a second unit with
 * an id already seen is left out too (phase 8 reports it as
 * `duplicateUnitId`). A document without a register declares none. */
std::vector<SpecGenerationUnit> specGenerationUnits(const SpecModel& model,
                                                    const SpecDocument& doc);

/* The units of `units` whose mappings hold `areaCode`, in register order —
 * the default destination of a section routed to that area (SOM §11.2). */
std::vector<std::string> specDefaultUnits(
    const std::vector<SpecGenerationUnit>& units, const std::string& areaCode);

/* The form field of `cls` that declares a form field named `name`, or null —
 * how the register and validation phase 8 find a unit's, a mapping's or an
 * emitter's form. */
const SpecField* specFormDeclaring(const SpecClass& cls,
                                   const std::string& name);

}  // namespace som

#endif  // SPEC_GENERATION_UNITS_HPP
