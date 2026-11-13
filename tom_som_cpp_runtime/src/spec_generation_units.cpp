/* spec_generation_units — see spec_generation_units.hpp. */
#include "spec_generation_units.hpp"

#include <set>

#include "spec_paths.hpp"
#include "spec_reflection.hpp"

namespace som {
namespace {

/* Returns `s` with leading/trailing whitespace removed. */
std::string trimmed(const std::string& s) {
  std::size_t b = s.find_first_not_of(" \t\r\n");
  if (b == std::string::npos) {
    return "";
  }
  std::size_t e = s.find_last_not_of(" \t\r\n");
  return s.substr(b, e - b + 1);
}

struct RawUnit {
  std::string id;
  std::string kind;
  std::string path;
};

struct RawMapping {
  std::string path;
  std::string area;
  std::string mapping;
};

/* The path of the unit a mapping at `mappingPath` belongs to: the longest unit
 * path that is a proper prefix of it, or "" when none is. */
std::string ownerOf(const std::string& mappingPath,
                    const std::vector<RawUnit>& units) {
  std::string best;
  bool found = false;
  for (const RawUnit& u : units) {
    const std::string prefix = u.path + "/";
    if (mappingPath.compare(0, prefix.size(), prefix) == 0 &&
        (!found || u.path.size() > best.size())) {
      best = u.path;
      found = true;
    }
  }
  return best;
}

}  // namespace

bool SpecGenerationUnit::maps(const std::string& areaCode) const {
  for (const SpecGenerationUnitMapping& m : mappings) {
    if (m.area == areaCode) return true;
  }
  return false;
}

std::optional<std::string> SpecGenerationUnit::mappingFor(
    const std::string& areaCode) const {
  for (const SpecGenerationUnitMapping& m : mappings) {
    if (m.area == areaCode) return m.mapping;
  }
  return std::nullopt;
}

const SpecField* specFormDeclaring(const SpecClass& cls,
                                   const std::string& name) {
  for (const SpecField& f : cls.fields) {
    if (f.kind != kSpecFieldKindForm) continue;
    for (const FormFieldSpec& ff : f.formFields) {
      if (ff.name == name) return &f;
    }
  }
  return nullptr;
}

std::vector<SpecGenerationUnit> specGenerationUnits(const SpecModel& model,
                                                    const SpecDocument& doc) {
  SpecReflection refl(model);
  std::vector<RawUnit> units;
  std::vector<RawMapping> mappings;
  // listPaths() is already in sorted (byte) order.
  for (const std::string& listPath : doc.listPaths()) {
    for (const std::string& item : doc.listItems(listPath)) {
      std::optional<SpecResolution> res = refl.resolve(item);
      const SpecClass* cls = res.has_value() ? res->targetClass : nullptr;
      if (cls == nullptr) continue;
      std::optional<NoArtifactLink> noArtifact =
          specNoArtifact(cls->annotations);
      if (!noArtifact.has_value() || noArtifact->reason != "generation") {
        continue;
      }
      if (const SpecField* unitForm = specFormDeclaring(*cls, "unitId")) {
        const std::string formPath =
            specPathJoin(item, SpecReflection::fieldSegment(*unitForm));
        const std::string id = trimmed(doc.formField(formPath, "unitId"));
        if (!id.empty()) {
          units.push_back({id, trimmed(doc.formField(formPath, "kind")), item});
        }
      }
      if (const SpecField* areaForm = specFormDeclaring(*cls, "area")) {
        const std::string formPath =
            specPathJoin(item, SpecReflection::fieldSegment(*areaForm));
        const std::string area = trimmed(doc.formField(formPath, "area"));
        if (!area.empty()) {
          mappings.push_back(
              {item, area, trimmed(doc.formField(formPath, "mapping"))});
        }
      }
    }
  }

  std::vector<SpecGenerationUnit> out;
  std::set<std::string> seen;
  for (const RawUnit& u : units) {
    if (!seen.insert(u.id).second) continue;
    SpecGenerationUnit unit;
    unit.unitId = u.id;
    unit.kind = u.kind;
    unit.path = u.path;
    for (const RawMapping& m : mappings) {
      if (ownerOf(m.path, units) == u.path) {
        unit.mappings.push_back({m.area, m.mapping});
      }
    }
    out.push_back(std::move(unit));
  }
  return out;
}

std::vector<std::string> specDefaultUnits(
    const std::vector<SpecGenerationUnit>& units, const std::string& areaCode) {
  std::vector<std::string> out;
  for (const SpecGenerationUnit& u : units) {
    if (u.maps(areaCode)) out.push_back(u.unitId);
  }
  return out;
}

}  // namespace som
