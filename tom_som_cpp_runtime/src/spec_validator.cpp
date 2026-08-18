/* Idiomatic-C++ port of the C `spec_validator` module. */
#include "spec_validator.hpp"

#include <algorithm>
#include <map>
#include <set>

#include "som_util.hpp"
#include "spec_reflection.hpp"
#include "spec_section_id.hpp"

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

const SpecAnnotation* annotationNamed(
    const std::vector<SpecAnnotation>& annotations, const std::string& name) {
  for (const SpecAnnotation& a : annotations) {
    if (a.name == name) {
      return &a;
    }
  }
  return nullptr;
}

/* The constant part of a qualified `EnumType.constant` `@Case` token (or the
 * whole string when it is not qualified). */
std::string caseConstant(const std::string& token) {
  std::size_t dot = token.find('.');
  return dot == std::string::npos ? token : token.substr(dot + 1);
}

/* Every section-instance path present in `doc`: each stored value path plus all
   of its ancestor prefixes. A container's own discriminator form lives at
   `<container>/<form>`, so the container path is always a prefix of a populated
   path. */
std::set<std::string> documentSectionPaths(const SpecDocument& doc) {
  std::set<std::string> paths;
  auto addPrefixes = [&](const std::string& full) {
    std::size_t from = 0;
    while (true) {
      std::size_t slash = full.find('/', from);
      if (slash == std::string::npos) {
        paths.insert(full);
        return;
      }
      paths.insert(full.substr(0, slash));
      from = slash + 1;
    }
  };
  for (const std::string& p : doc.contentPaths()) addPrefixes(p);
  for (const std::string& p : doc.formPaths()) addPrefixes(p);
  for (const std::string& p : doc.listPaths()) addPrefixes(p);
  for (const std::string& p : doc.headlinePaths()) addPrefixes(p);
  return paths;
}

/* Instance-tier `@OneOf`/`@Case` check (csmb6): for every `@OneOf` container
   instance present in `doc`, verify the populated case subsections match the
   chosen discriminator value. */
std::vector<SpecValidationError> validateOneOfInstances(
    const SpecReflection& refl, const SpecDocument& doc) {
  std::vector<SpecValidationError> errors;

  for (const std::string& path : documentSectionPaths(doc)) {
    auto res = refl.resolve(path);
    if (!res.has_value() || res->targetClass == nullptr) {
      continue;
    }
    const SpecClass& cls = *res->targetClass;
    const SpecAnnotation* oneOf = annotationNamed(cls.annotations, "OneOf");
    if (oneOf == nullptr) {
      continue;
    }
    const std::string* discriminatorPtr =
        jsonAsStr(oneOf->argument("discriminator"));
    if (discriminatorPtr == nullptr || discriminatorPtr->empty()) {
      continue;
    }
    const std::string& discriminator = *discriminatorPtr;

    // Read the chosen discriminator value from the container's own @Form.
    const SpecField* formHolder = nullptr;
    for (const SpecField& f : cls.fields) {
      if (f.kind != kSpecFieldKindForm) {
        continue;
      }
      for (const FormFieldSpec& ff : f.formFields) {
        if (ff.name == discriminator) {
          formHolder = &f;
          break;
        }
      }
      if (formHolder != nullptr) {
        break;
      }
    }
    if (formHolder == nullptr) {
      continue;  // static tier flagged the mismatch
    }
    std::string chosen = doc.formField(
        path + "/" + SpecReflection::fieldSegment(*formHolder), discriminator);
    if (chosen.empty()) {
      continue;  // no case chosen yet
    }

    // Inspect each case-bound subsection: present + not-selected → mismatch.
    std::vector<std::string> presentForChosen;
    for (const SpecField& f : cls.fields) {
      std::set<std::string> caseConstants;
      for (const SpecAnnotation& a : f.annotations) {
        if (a.name != "Case") {
          continue;
        }
        const std::string* value = jsonAsStr(a.argument("value"));
        if (value != nullptr) {
          caseConstants.insert(caseConstant(*value));
        }
      }
      if (caseConstants.empty()) {
        continue;  // common subsection — always allowed
      }
      std::string childPath = path + "/" + SpecReflection::fieldSegment(f);
      if (!doc.hasValuesUnder(childPath)) {
        continue;
      }
      if (caseConstants.count(chosen) != 0) {
        presentForChosen.push_back(f.name);
      } else {
        std::string cases;
        for (const std::string& c : caseConstants) {
          if (!cases.empty()) cases += ", ";
          cases += c;
        }
        errors.push_back({childPath, kSpecValidationCodeOneOfCaseMismatch,
                          "subsection \"" + f.name +
                              "\" is present but the chosen " + discriminator +
                              "=\"" + chosen + "\" does not select it (cases: " +
                              cases + ")"});
      }
    }
    if (presentForChosen.size() > 1) {
      std::sort(presentForChosen.begin(), presentForChosen.end());
      std::string joined;
      for (const std::string& n : presentForChosen) {
        if (!joined.empty()) joined += ", ";
        joined += n;
      }
      errors.push_back({path, kSpecValidationCodeOneOfCaseMismatch,
                        "chosen " + discriminator + "=\"" + chosen +
                            "\" selects more than one populated subsection (" +
                            joined +
                            ") — at most one case subsection may be present"});
    }
  }
  return errors;
}

/* A resolved form section: its path, the class it sits on (which carries the
   `@SectionId` a registry key is written against) and the form field itself. */
struct FormInstance {
  std::string path;
  const SpecClass* cls;
  const SpecField* field;
};

/* The section id part of a registry key written `<SECTIONID>.<slot>`. A key with
   no dot is malformed — the static tier reports it — and is treated whole here
   so it simply fails to match any section id. */
std::string registrySectionId(const std::string& target) {
  std::size_t dot = target.find('.');
  return dot == std::string::npos || dot == 0 ? target : target.substr(0, dot);
}

/* The registry section ids that are **in scope** for `doc` (csre2): the
   `@SectionId` of every class reachable from a document root the document
   actually uses. Anything outside this set is absent from the document by
   construction — precisely the case the dangling-reference check must not call
   an error. A document spanning several roots contributes the union. */
std::set<std::string> registryScope(const SpecReflection& refl,
                                    const SpecDocument& doc) {
  std::set<std::string> rootTypes;
  auto addRootOf = [&](const std::string& path) {
    std::size_t slash = path.find('/');
    std::string segment =
        slash == std::string::npos ? path : path.substr(0, slash);
    const SpecRoot* root = refl.rootForSegment(segment);
    if (root != nullptr) {
      rootTypes.insert(root->type);
    }
  };
  for (const std::string& p : doc.contentPaths()) addRootOf(p);
  for (const std::string& p : doc.formPaths()) addRootOf(p);
  for (const std::string& p : doc.listPaths()) addRootOf(p);
  for (const std::string& p : doc.headlinePaths()) addRootOf(p);

  std::set<std::string> ids;
  for (const std::string& type : rootTypes) {
    for (const std::string& name : refl.reachableClassNames(type)) {
      const SpecClass* cls = refl.model().classNamed(name);
      if (cls != nullptr && !cls->sectionId.empty()) {
        ids.insert(cls->sectionId);
      }
    }
  }
  return ids;
}

/* Instance-tier cross-registry reference check (csrb3): every id written into a
   `refersTo` form field must be declared by some entry of one of its target
   registries *in this document*. Two sweeps over the document's form sections
   (declare, then resolve), so it costs one extra walk rather than a resolve per
   reference. An empty value is not a dangling reference — it means "not filled
   in yet", the schema-completeness concern this validator leaves to its
   caller. */
std::vector<SpecValidationError> validateReferenceInstances(
    const SpecReflection& refl, const SpecDocument& doc) {
  std::vector<SpecValidationError> errors;
  const std::set<std::string> scope = registryScope(refl, doc);

  // Resolve every form path once; both sweeps read the same resolutions. A form
  // resolution names the form *field*, not a class — the section id a registry
  // key is written against belongs to the class the form sits on, so the owner
  // is resolved from the parent path.
  std::vector<FormInstance> forms;
  std::vector<std::string> formPaths = doc.formPaths();
  std::sort(formPaths.begin(), formPaths.end());
  for (const std::string& path : formPaths) {
    auto res = refl.resolve(path);
    if (!res.has_value() || res->field == nullptr ||
        res->kind != kSpecNodeKindForm) {
      continue;
    }
    std::size_t slash = path.rfind('/');
    if (slash == std::string::npos || slash == 0) {
      continue;
    }
    auto owner = refl.resolve(path.substr(0, slash));
    if (!owner.has_value() || owner->targetClass == nullptr) {
      continue;
    }
    forms.push_back({path, owner->targetClass, res->field});
  }

  // 1. Declare: every form instance contributes `<SECTIONID>.<formField>`.
  std::map<std::string, std::set<std::string>> declared;
  for (const FormInstance& form : forms) {
    if (form.cls->sectionId.empty()) {
      continue;
    }
    for (const FormFieldSpec& ff : form.field->formFields) {
      std::string value = trimmed(doc.formField(form.path, ff.name));
      if (value.empty()) {
        continue;
      }
      declared[form.cls->sectionId + "." + ff.name].insert(value);
    }
  }

  // 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
  // The key is the *element class's* section id, not the `-LST` container's: a
  // target names the entry, so `FRE.@sectionId` reads as "an id of some
  // functional-requirement entry". That half is what makes a registry keeping
  // its id nowhere but the section id referenceable at all.
  std::vector<std::string> listPaths = doc.listPaths();
  std::sort(listPaths.begin(), listPaths.end());
  for (const std::string& listPath : listPaths) {
    auto listRes = refl.resolve(listPath);
    std::string pattern;
    std::string stem;
    if (listRes.has_value() && listRes->field != nullptr) {
      pattern = listRes->field->sectionIdPattern;
      stem = listRes->field->name;
    } else {
      std::size_t slash = listPath.rfind('/');
      stem = slash == std::string::npos ? listPath : listPath.substr(slash + 1);
    }
    std::vector<std::string> items = doc.listItems(listPath);
    for (std::size_t i = 0; i < items.size(); i++) {
      auto itemRes = refl.resolve(items[i]);
      if (!itemRes.has_value() || itemRes->targetClass == nullptr ||
          itemRes->targetClass->sectionId.empty()) {
        continue;
      }
      declared[itemRes->targetClass->sectionId + "." + kSectionIdSlot].insert(
          effectiveListItemSectionId(doc.itemSectionIdOpt(items[i]), pattern,
                                     static_cast<long long>(i) + 1, stem));
    }
  }

  // 2. Resolve.
  for (const FormInstance& form : forms) {
    for (const FormFieldSpec& ff : form.field->formFields) {
      if (ff.refersTo.empty()) {
        continue;
      }
      std::string value = trimmed(doc.formField(form.path, ff.name));
      if (value.empty()) {
        continue;
      }

      // Every target must be in scope, not merely one of them: a disjunction
      // says the id may come from any of the listed registries, so one absent
      // registry is enough to make "no registry declares it" unsound — the id
      // could legitimately be declared by the one this document cannot see.
      bool allInScope = true;
      for (const std::string& t : ff.refersTo) {
        if (scope.count(registrySectionId(t)) == 0) {
          allInScope = false;
          break;
        }
      }
      if (!allInScope) {
        continue;
      }

      // A value naming several ids writes them comma-separated, so each segment
      // resolves independently; a value is valid when it resolves in **any**
      // listed registry.
      std::size_t from = 0;
      while (true) {
        std::size_t comma = value.find(',', from);
        std::string id = trimmed(comma == std::string::npos
                                     ? value.substr(from)
                                     : value.substr(from, comma - from));
        if (!id.empty()) {
          bool resolves = false;
          for (const std::string& target : ff.refersTo) {
            auto it = declared.find(target);
            if (it != declared.end() && it->second.count(id) != 0) {
              resolves = true;
              break;
            }
          }
          if (!resolves) {
            std::string targets;
            for (const std::string& t : ff.refersTo) {
              if (!targets.empty()) targets += ", ";
              targets += t;
            }
            errors.push_back(
                {form.path, kSpecValidationCodeDanglingReference,
                 "form field \"" + ff.name + "\" references \"" + id +
                     "\", which no entry of " +
                     (ff.refersTo.size() == 1 ? "registry " : "registries ") +
                     targets + " declares"});
          }
        }
        if (comma == std::string::npos) {
          break;
        }
        from = comma + 1;
      }
    }
  }
  return errors;
}

}  // namespace

std::vector<SpecValidationError> validateDocument(const SpecModel& model,
                                                  const SpecDocument& doc) {
  std::vector<SpecValidationError> out;
  SpecReflection refl(model);

  auto push = [&](const std::string& path, const std::string& code,
                  const std::string& message) {
    out.push_back({path, code, message});
  };

  // 1. Content/scalar/enum leaves (contentPaths already byte-sorted).
  for (const std::string& path : doc.contentPaths()) {
    auto res = refl.resolve(path);
    if (!res.has_value()) {
      push(path, kSpecValidationCodeDanglingPath,
           "path does not resolve to any model node");
      continue;
    }
    // A form node is the one non-leaf that legitimately carries content: it is
    // the form's preamble, the free text before the first field line (SOM §11.4
    // rule 7), in the same slot a plain section's body uses.
    if (!res->isValueLeaf() && res->kind != kSpecNodeKindForm) {
      push(path, kSpecValidationCodeKindMismatch,
           "expected a value leaf but path resolves to " + res->kind);
    }
  }

  // 2. Form sections.
  for (const std::string& path : doc.formPaths()) {
    auto res = refl.resolve(path);
    if (!res.has_value()) {
      push(path, kSpecValidationCodeDanglingPath,
           "path does not resolve to any model node");
      continue;
    }
    if (res->field == nullptr || res->kind != kSpecNodeKindForm) {
      push(path, kSpecValidationCodeKindMismatch,
           "expected a form section but path resolves to " + res->kind);
      continue;
    }
    const SpecField* field = res->field;
    for (const std::string& name : doc.formFieldNames(path)) {
      bool declared = false;
      for (const FormFieldSpec& ff : field->formFields) {
        if (ff.name == name) {
          declared = true;
          break;
        }
      }
      if (!declared) {
        push(path, kSpecValidationCodeUnknownFormField,
             "form field \"" + name + "\" is not declared on " + field->name);
      }
    }
  }

  // 3. Lists (container kind + @Min count on populated lists).
  for (const std::string& path : doc.listPaths()) {
    auto res = refl.resolve(path);
    if (!res.has_value()) {
      push(path, kSpecValidationCodeDanglingPath,
           "path does not resolve to any model node");
      continue;
    }
    if (res->field == nullptr || res->kind != kSpecNodeKindList) {
      push(path, kSpecValidationCodeKindMismatch,
           "expected a list but path resolves to " + res->kind);
      continue;
    }
    const SpecField* field = res->field;
    if (field->hasMin) {
      long long count = static_cast<long long>(doc.listItemCount(path));
      if (count < field->min) {
        push(path, kSpecValidationCodeMinItems,
             "list holds " + formatI64(count) +
                 " item(s) but requires at least " + formatI64(field->min));
      }
    }
  }

  // 4. @OneOf/@Case instances: a populated subsection the chosen discriminator
  // does not select. Only here can we see which case a document actually
  // wrote — the static tier can only check the annotations are well formed.
  for (SpecValidationError& e : validateOneOfInstances(refl, doc)) {
    out.push_back(std::move(e));
  }

  // 5. `refersTo` references: an id no entry of its target registries declares
  // in this document. The static tier has checked the targets are resolvable;
  // only here can we see whether the id a document wrote is one it declares.
  for (SpecValidationError& e : validateReferenceInstances(refl, doc)) {
    out.push_back(std::move(e));
  }

  return out;
}

}  // namespace som
