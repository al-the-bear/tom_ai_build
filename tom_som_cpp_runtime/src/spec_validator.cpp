/* Idiomatic-C++ port of the C `spec_validator` module. */
#include "spec_validator.hpp"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <optional>
#include <set>

#include "som_util.hpp"
#include "spec_reflection.hpp"
#include "spec_section_id.hpp"
#include "spec_typed_values.hpp"

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

/* Every form instance in `doc` with its field and the class it sits on, in path
   order — the shape both the reference and the count check sweep. A form
   resolution names the form *field*, not a class — the section id a registry
   key is written against belongs to the class the form sits on, so the owner is
   resolved from the parent path. */
std::vector<FormInstance> resolvedForms(const SpecReflection& refl,
                                        const SpecDocument& doc) {
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
  return forms;
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

  // Resolve every form path once; both sweeps read the same resolutions.
  const std::vector<FormInstance> forms = resolvedForms(refl, doc);

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

/* The section id of a `countOf` target — the part before any `.field=value`,
   without the `./` scope prefix. */
std::string countTargetId(std::string target) {
  if (target.rfind("./", 0) == 0) target = target.substr(2);
  std::size_t dot = target.find('.');
  return dot == std::string::npos ? target : target.substr(0, dot);
}

/* Whether `s` is a non-empty run of ASCII digits (`^[0-9]+$`). */
bool allDigits(const std::string& s) {
  return !s.empty() && std::all_of(s.begin(), s.end(), [](char c) {
    return c >= '0' && c <= '9';
  });
}

/* Whether the digit string `digits` names the number `n`. Compared as decimal
   text (leading zeros stripped), so a stated value too large for any integer
   type is simply unequal rather than overflowing. */
bool digitsEqual(const std::string& digits, long long n) {
  std::size_t first = digits.find_first_not_of('0');
  std::string stripped =
      first == std::string::npos ? "0" : digits.substr(first);
  return stripped == std::to_string(n);
}

/* Instance-tier stated-count check (vsctsa43): every non-empty value of a
   `countOf` form field must be a whole number equal to the number of entries
   the document holds.

   An **entry** is a list item whose element class carries `@SectionId(X)`. A
   target `X` counts every such entry; `X.f=v` counts only the entries one of
   whose own forms — a form member of the entry, at `<item>/<member>` — holds
   `v` in form field `f`. The count is the sum over the targets. As with the
   reference check, a target whose section id the document's root cannot reach
   makes the field undecidable here, so it is skipped rather than reported, and
   an empty value is completeness, not a count. */
std::vector<SpecValidationError> validateCountInstances(
    const SpecReflection& refl, const SpecDocument& doc) {
  const std::vector<FormInstance> forms = resolvedForms(refl, doc);
  bool any = std::any_of(forms.begin(), forms.end(), [](const FormInstance& f) {
    return std::any_of(
        f.field->formFields.begin(), f.field->formFields.end(),
        [](const FormFieldSpec& ff) { return !ff.countOf.empty(); });
  });
  if (!any) {
    return {};
  }
  const std::set<std::string> scope = registryScope(refl, doc);

  // Every entry, by its class's section id, with the form values its own form
  // members hold.
  std::map<std::string, std::vector<std::string>> entriesById;
  std::vector<std::string> listPaths = doc.listPaths();
  std::sort(listPaths.begin(), listPaths.end());
  for (const std::string& listPath : listPaths) {
    for (const std::string& item : doc.listItems(listPath)) {
      auto res = refl.resolve(item);
      if (!res.has_value() || res->targetClass == nullptr ||
          res->targetClass->sectionId.empty()) {
        continue;
      }
      entriesById[res->targetClass->sectionId].push_back(item);
    }
  }
  std::map<std::string, std::map<std::string, std::set<std::string>>>
      valuesByItem;
  for (const std::string& path : doc.formPaths()) {
    std::size_t slash = path.rfind('/');
    if (slash == std::string::npos || slash == 0) {
      continue;
    }
    auto res = refl.resolve(path);
    if (!res.has_value() || res->field == nullptr) {
      continue;
    }
    const std::string owner = path.substr(0, slash);
    for (const FormFieldSpec& ff : res->field->formFields) {
      std::string v = trimmed(doc.formField(path, ff.name));
      if (v.empty()) {
        continue;
      }
      valuesByItem[owner][ff.name].insert(v);
    }
  }

  // A target written `./...` counts only the entries beneath `owner`, the
  // section holding the form; any other target counts the whole document.
  auto countTarget = [&](std::string target,
                         const std::string& owner) -> long long {
    const bool scoped = target.rfind("./", 0) == 0;
    if (scoped) target = target.substr(2);
    const std::string prefix = owner + "/";
    auto inScope = [&](const std::string& item) {
      return !scoped || item.rfind(prefix, 0) == 0;
    };
    std::size_t dot = target.find('.');
    if (dot == std::string::npos) {
      auto it = entriesById.find(target);
      if (it == entriesById.end()) return 0;
      return static_cast<long long>(
          std::count_if(it->second.begin(), it->second.end(), inScope));
    }
    const std::string id = target.substr(0, dot);
    std::size_t eq = target.find('=', dot);
    const std::string field = target.substr(
        dot + 1, eq == std::string::npos ? std::string::npos : eq - dot - 1);
    const std::string value =
        eq == std::string::npos ? std::string() : target.substr(eq + 1);
    auto it = entriesById.find(id);
    if (it == entriesById.end()) {
      return 0;
    }
    long long n = 0;
    for (const std::string& item : it->second) {
      if (!inScope(item)) continue;
      auto byItem = valuesByItem.find(item);
      if (byItem == valuesByItem.end()) continue;
      auto byField = byItem->second.find(field);
      if (byField != byItem->second.end() && byField->second.count(value) != 0) {
        n++;
      }
    }
    return n;
  };

  std::vector<SpecValidationError> errors;
  for (const FormInstance& form : forms) {
    for (const FormFieldSpec& ff : form.field->formFields) {
      if (ff.countOf.empty()) {
        continue;
      }
      const std::string stated = trimmed(doc.formField(form.path, ff.name));
      if (stated.empty()) {
        continue;
      }
      bool allInScope = std::all_of(
          ff.countOf.begin(), ff.countOf.end(), [&](const std::string& t) {
            return scope.count(registrySectionId(countTargetId(t))) != 0;
          });
      if (!allInScope) {
        continue;
      }
      const std::size_t lastSlash = form.path.rfind('/');
      const std::string owner = lastSlash == std::string::npos
                                    ? std::string()
                                    : form.path.substr(0, lastSlash);
      long long counted = 0;
      std::string targets;
      for (const std::string& t : ff.countOf) {
        counted += countTarget(t, owner);
        if (!targets.empty()) targets += " + ";
        targets += t;
      }
      if (!allDigits(stated)) {
        errors.push_back(
            {form.path, kSpecValidationCodeCountMismatch,
             "form field \"" + ff.name + "\" states \"" + stated +
                 "\", which is not a whole number — it counts " + targets +
                 ", of which the document holds " + std::to_string(counted)});
      } else if (!digitsEqual(stated, counted)) {
        errors.push_back({form.path, kSpecValidationCodeCountMismatch,
                          "form field \"" + ff.name + "\" states " + stated +
                              ", but the document holds " +
                              std::to_string(counted) + " (counting " +
                              targets + ")"});
      }
    }
  }
  return errors;
}

/* Whether `s` reads as `^-?[0-9]+(\.[0-9]+)?$`. */
bool isNumberText(const std::string& s) {
  std::size_t i = 0;
  if (i < s.size() && s[i] == '-') i++;
  std::size_t start = i;
  while (i < s.size() && s[i] >= '0' && s[i] <= '9') i++;
  if (i == start) return false;
  if (i < s.size() && s[i] == '.') {
    i++;
    std::size_t frac = i;
    while (i < s.size() && s[i] >= '0' && s[i] <= '9') i++;
    if (i == frac) return false;
  }
  return i == s.size();
}

double pow10Int(int exponent) {
  double v = 1.0;
  for (int i = 0; i < (exponent < 0 ? -exponent : exponent); i++) v *= 10.0;
  return exponent < 0 ? 1.0 / v : v;
}

/* `v` as a whole number when it is one, else the shortest text that reads
   back as the same double. */
std::string formatNumber(double v) {
  if (v > -9e18 && v < 9e18 && static_cast<double>(static_cast<long long>(v)) == v) {
    return std::to_string(static_cast<long long>(v));
  }
  char buf[64];
  for (int prec = 1; prec <= 17; prec++) {
    std::snprintf(buf, sizeof(buf), "%.*g", prec, v);
    if (std::strtod(buf, nullptr) == v) return buf;
  }
  std::snprintf(buf, sizeof(buf), "%.17g", v);
  return buf;
}

/* Instance-tier derived-value check (uamtc10): a `productOf` field must hold
   the product of its operands, and a `rankOf` field must rank the instances of
   its form by their score, highest first.

   **Operands.** A plain operand is a field of the same form; `F.x` is field
   `x` of the form `F` beside it, at `<owner>/F` where `<owner>` is the section
   holding this form. A numeric operand contributes its number, an enum operand
   its 1-based position among the enum's values. When the value or any operand
   is empty — or an operand is unreadable, which other checks report — the
   product is undecidable and is skipped; a stated value that is no number is
   reported regardless.

   **Precision.** The stated number is held to the precision it is written in:
   `2.8` matches 0.7 × 4.0, and `15` matches 3 × 5, but `2.9` does not.

   **Ranks.** Over every instance of the same form whose rank and score are
   both filled, the ranks must be the whole numbers 1 to n, each once, and an
   instance may not rank below one that scores lower. Equal scores take their
   ranks in any order. Each offending instance is reported once.

   The phase's findings, products and ranks together, are stable-sorted by
   form path. */
std::vector<SpecValidationError> validateDerivedValues(
    const SpecReflection& refl, const SpecDocument& doc) {
  const std::vector<FormInstance> forms = resolvedForms(refl, doc);
  bool any = std::any_of(forms.begin(), forms.end(), [](const FormInstance& f) {
    return std::any_of(f.field->formFields.begin(), f.field->formFields.end(),
                       [](const FormFieldSpec& ff) {
                         return !ff.productOf.empty() || ff.rankOf.has_value();
                       });
  });
  if (!any) {
    return {};
  }

  // The number a filled form field contributes, or unset when it is empty or
  // unreadable.
  auto numberOf = [&](const std::string& formPath,
                      const FormFieldSpec& spec) -> std::optional<double> {
    const std::string v = trimmed(doc.formField(formPath, spec.name));
    if (v.empty()) return std::nullopt;
    if (!spec.enumValues.empty()) {
      auto it = std::find(spec.enumValues.begin(), spec.enumValues.end(), v);
      if (it == spec.enumValues.end()) return std::nullopt;
      return static_cast<double>(it - spec.enumValues.begin() + 1);
    }
    if (!isNumberText(v)) return std::nullopt;
    return std::strtod(v.c_str(), nullptr);
  };

  // The spec of field `name` of the form at `path`, or null.
  auto specAt = [&](const std::string& path,
                    const std::string& name) -> const FormFieldSpec* {
    auto res = refl.resolve(path);
    if (!res.has_value() || res->kind != kSpecNodeKindForm ||
        res->field == nullptr) {
      return nullptr;
    }
    for (const FormFieldSpec& ff : res->field->formFields) {
      if (ff.name == name) return &ff;
    }
    return nullptr;
  };

  struct Ranked {
    std::string path;
    std::string name;
    std::string stated;
    double score;
  };
  std::vector<std::string> groupKeys;
  std::map<std::string, std::vector<Ranked>> ranked;

  std::vector<SpecValidationError> errors;
  for (const FormInstance& form : forms) {
    const std::size_t slash = form.path.rfind('/');
    const std::string owner =
        slash == std::string::npos ? std::string() : form.path.substr(0, slash);
    for (const FormFieldSpec& ff : form.field->formFields) {
      if (!ff.productOf.empty()) {
        const std::string stated = trimmed(doc.formField(form.path, ff.name));
        if (!stated.empty()) {
          std::optional<double> product = 1.0;
          for (const std::string& operand : ff.productOf) {
            const std::size_t dot = operand.find('.');
            const std::string path = dot == std::string::npos
                                         ? form.path
                                         : owner + "/" + operand.substr(0, dot);
            const std::string name =
                dot == std::string::npos ? operand : operand.substr(dot + 1);
            const FormFieldSpec* spec = specAt(path, name);
            std::optional<double> n =
                spec == nullptr ? std::nullopt : numberOf(path, *spec);
            if (!n.has_value()) {
              product.reset();
              break;
            }
            *product *= *n;
          }
          std::string operands;
          for (const std::string& operand : ff.productOf) {
            if (!operands.empty()) operands += " \xC3\x97 ";
            operands += operand;
          }
          if (!isNumberText(stated)) {
            errors.push_back({form.path, kSpecValidationCodeDerivedValueMismatch,
                              "form field \"" + ff.name + "\" states \"" +
                                  stated +
                                  "\", which is not a number \xE2\x80\x94 it is "
                                  "the product " +
                                  operands});
          } else if (product.has_value()) {
            const std::size_t sdot = stated.find('.');
            const int decimals =
                sdot == std::string::npos
                    ? 0
                    : static_cast<int>(stated.size() - sdot - 1);
            const double tolerance = 0.5 * pow10Int(-decimals) + 1e-9;
            double diff = std::strtod(stated.c_str(), nullptr) - *product;
            if (diff < 0) diff = -diff;
            if (diff > tolerance) {
              errors.push_back(
                  {form.path, kSpecValidationCodeDerivedValueMismatch,
                   "form field \"" + ff.name + "\" states " + stated + ", but " +
                       operands + " gives " + formatNumber(*product)});
            }
          }
        }
      }
      if (ff.rankOf.has_value()) {
        const std::string stated = trimmed(doc.formField(form.path, ff.name));
        const FormFieldSpec* scoreSpec = specAt(form.path, *ff.rankOf);
        std::optional<double> score =
            scoreSpec == nullptr ? std::nullopt : numberOf(form.path, *scoreSpec);
        if (!stated.empty() && score.has_value()) {
          const std::string key = (form.cls != nullptr ? form.cls->name : "") +
                                  "#" + form.field->name + "#" + ff.name;
          if (ranked.find(key) == ranked.end()) groupKeys.push_back(key);
          ranked[key].push_back({form.path, ff.name, stated, *score});
        }
      }
    }
  }

  for (const std::string& key : groupKeys) {
    const std::vector<Ranked>& group = ranked[key];
    const long long n = static_cast<long long>(group.size());
    std::vector<std::optional<long long>> rankAt(group.size());
    std::map<long long, int> seen;
    for (std::size_t i = 0; i < group.size(); i++) {
      if (!allDigits(group[i].stated)) continue;
      // A rank too long for any integer type is out of 1..n anyway.
      long long r = group[i].stated.size() > 18
                        ? n + 1
                        : std::strtoll(group[i].stated.c_str(), nullptr, 10);
      rankAt[i] = r;
      seen[r]++;
    }
    for (std::size_t i = 0; i < group.size(); i++) {
      const Ranked& e = group[i];
      std::string problem;
      if (!rankAt[i].has_value()) {
        problem = "states \"" + e.stated + "\", which is not a whole number";
      } else {
        const long long r = *rankAt[i];
        if (r < 1 || r > n || seen[r] > 1) {
          problem = "states rank " + std::to_string(r) + ", but the " +
                    std::to_string(n) + " ranked entries take the ranks 1 to " +
                    std::to_string(n) + ", each once";
        } else {
          for (std::size_t o = 0; o < group.size(); o++) {
            if (rankAt[o].has_value() && group[o].score < e.score &&
                *rankAt[o] < r) {
              problem = "ranks " + std::to_string(r) + " with score " +
                        formatNumber(e.score) + ", below an entry ranked " +
                        std::to_string(*rankAt[o]) + " with the lower score " +
                        formatNumber(group[o].score);
              break;
            }
          }
        }
      }
      if (!problem.empty()) {
        errors.push_back({e.path, kSpecValidationCodeDerivedValueMismatch,
                          "form field \"" + e.name + "\" " + problem});
      }
    }
  }

  // Like every phase's group, the findings are ordered by path; the sort is
  // stable, so a path's own findings keep the order they were found in.
  std::stable_sort(errors.begin(), errors.end(),
                   [](const SpecValidationError& a, const SpecValidationError& b) {
                     return a.path < b.path;
                   });
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
    // A wrapper section (TextSection, ...) is the other: its class is not
    // exported, so it resolves to no class and its text is stored at its own
    // path, the way the YAML codec writes it.
    const bool isWrapperSection =
        res->kind == kSpecNodeKindSection && res->targetClass == nullptr;
    if (!res->isValueLeaf() && res->kind != kSpecNodeKindForm &&
        !isWrapperSection) {
      push(path, kSpecValidationCodeKindMismatch,
           "expected a value leaf but path resolves to " + res->kind);
      continue;
    }
    if (res->kind == kSpecNodeKindScalar) {
      const std::string type =
          res->field != nullptr ? res->field->type : std::string();
      const std::string value = doc.content(path);
      if (!somTypedTextReadable(type, value)) {
        push(path, kSpecValidationCodeValueTypeMismatch,
             "holds \"" + value + "\", which is not readable as " +
                 somScalarBase(type));
      }
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
      const FormFieldSpec* spec = nullptr;
      for (const FormFieldSpec& ff : field->formFields) {
        if (ff.name == name) {
          spec = &ff;
          break;
        }
      }
      if (spec == nullptr) {
        push(path, kSpecValidationCodeUnknownFormField,
             "form field \"" + name + "\" is not declared on " + field->name);
        continue;
      }
      if (spec->enumValues.empty()) {
        const std::string text = doc.formField(path, name);
        // A stated count (`countOf`) is checked by countMismatch, a derived
        // value (`productOf` / `rankOf`) by derivedValueMismatch, which already
        // report text that is no number; one finding is enough.
        if (spec->countOf.empty() && spec->productOf.empty() &&
            !spec->rankOf.has_value() &&
            !somTypedTextReadable(spec->type, text)) {
          push(path, kSpecValidationCodeValueTypeMismatch,
               "form field \"" + name + "\" holds \"" + text +
                   "\", which is not readable as " + somScalarBase(spec->type));
        }
        continue;
      }
      const std::string value = doc.formField(path, name);
      // Absence is not a bad value.
      if (value.empty()) {
        continue;
      }
      bool known = false;
      for (const std::string& v : spec->enumValues) {
        if (v == value) {
          known = true;
          break;
        }
      }
      if (!known) {
        std::string allowed;
        for (std::size_t k = 0; k < spec->enumValues.size(); ++k) {
          if (k > 0) {
            allowed += ", ";
          }
          allowed += spec->enumValues[k];
        }
        push(path, kSpecValidationCodeEnumValueUnknown,
             "form field \"" + name + "\" holds \"" + value + "\", which " +
                 spec->type + " does not declare (" + allowed + ")");
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

  // 6. Stated counts: a `countOf` form field states how many entries the
  // document holds; only the instance tier can count them.
  for (SpecValidationError& e : validateCountInstances(refl, doc)) {
    out.push_back(std::move(e));
  }

  // 7. Derived values: a `productOf` field holds the product of its operands,
  // a `rankOf` field ranks the instances of its form by their score.
  for (SpecValidationError& e : validateDerivedValues(refl, doc)) {
    out.push_back(std::move(e));
  }

  return out;
}

}  // namespace som
