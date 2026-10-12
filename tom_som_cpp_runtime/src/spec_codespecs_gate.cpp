/* Idiomatic-C++ port of the Dart `spec_codespecs_gate` library. */
#include "spec_codespecs_gate.hpp"

#include <stdexcept>
#include <utility>

#include "spec_validator.hpp"

namespace som {
namespace {

/* The Dart reference's not-run reasons, verbatim. */
const char* const kNoSchema = "no DocSpecs schema was supplied";
const char* const kNoTables =
    "the catalogue carries no gate tables (written before "
    "`codespecs_prompt.md` §4.4/§4.5 were transcribed)";
const char* const kNoExtracts =
    "A3 did not complete, so there is no extraction run to read the used "
    "areas from";

CodeSpecsGateCheckResult notRun(CodeSpecsGateCheck check, const char* reason) {
  CodeSpecsGateCheckResult r;
  r.check = check;
  r.ran = false;
  r.notRunReason = reason;
  return r;
}

CodeSpecsGateFinding finding(CodeSpecsGateCheck check, std::string code,
                             std::string location, std::string message) {
  CodeSpecsGateFinding f;
  f.check = check;
  f.code = std::move(code);
  f.location = std::move(location);
  f.message = std::move(message);
  return f;
}

/* Decodes one UTF-8 code point at `s[*i]`, advancing `*i`. Malformed bytes
 * decode to themselves, one byte at a time. */
unsigned long nextCodePoint(const std::string& s, std::size_t* i) {
  auto at = [&](std::size_t k) {
    return k < s.size() ? static_cast<unsigned char>(s[k]) : 0u;
  };
  unsigned long c = at(*i);
  std::size_t n = 1;
  if (c >= 0xF0 && at(*i + 1) && at(*i + 2) && at(*i + 3)) {
    c = ((c & 0x07UL) << 18) | ((at(*i + 1) & 0x3FUL) << 12) |
        ((at(*i + 2) & 0x3FUL) << 6) | (at(*i + 3) & 0x3FUL);
    n = 4;
  } else if (c >= 0xE0 && at(*i + 1) && at(*i + 2)) {
    c = ((c & 0x0FUL) << 12) | ((at(*i + 1) & 0x3FUL) << 6) |
        (at(*i + 2) & 0x3FUL);
    n = 3;
  } else if (c >= 0xC0 && at(*i + 1)) {
    c = ((c & 0x1FUL) << 6) | (at(*i + 1) & 0x3FUL);
    n = 2;
  }
  *i += n;
  return c;
}

/* The whitespace Dart's `String.trim` removes. */
bool dartIsSpace(unsigned long c) {
  return (c >= 0x09 && c <= 0x0D) || c == 0x20 || c == 0x85 || c == 0xA0 ||
         c == 0x1680 || (c >= 0x2000 && c <= 0x200A) || c == 0x2028 ||
         c == 0x2029 || c == 0x202F || c == 0x205F || c == 0x3000 ||
         c == 0xFEFF;
}

/* `value.trim().isEmpty`. */
bool isBlank(const std::string& value) {
  std::size_t i = 0;
  while (i < value.size()) {
    if (!dartIsSpace(nextCodePoint(value, &i))) {
      return false;
    }
  }
  return true;
}

std::string parentPath(const std::string& path) {
  std::size_t i = path.rfind('/');
  return i == std::string::npos ? std::string() : path.substr(0, i);
}

}  // namespace

const char* codeSpecsGateCheckLabel(CodeSpecsGateCheck check) {
  switch (check) {
    case CodeSpecsGateCheck::A1:
      return "A1";
    case CodeSpecsGateCheck::A2:
      return "A2";
    case CodeSpecsGateCheck::A3:
      return "A3";
    case CodeSpecsGateCheck::A4:
      return "A4";
    case CodeSpecsGateCheck::A5:
      return "A5";
  }
  return "";
}

std::string CodeSpecsGateFinding::display() const {
  return std::string(codeSpecsGateCheckLabel(check)) + " " + code + " " +
         location + ": " + message;
}

const CodeSpecsGateCheckResult& CodeSpecsGateReport::operator[](
    CodeSpecsGateCheck check) const {
  for (const CodeSpecsGateCheckResult& r : results) {
    if (r.check == check) {
      return r;
    }
  }
  throw std::out_of_range(std::string("no result for ") +
                          codeSpecsGateCheckLabel(check));
}

bool CodeSpecsGateReport::passed() const {
  for (const CodeSpecsGateCheckResult& r : results) {
    if (!r.passed()) {
      return false;
    }
  }
  return true;
}

std::vector<CodeSpecsGateFinding> CodeSpecsGateReport::findings() const {
  std::vector<CodeSpecsGateFinding> out;
  for (const CodeSpecsGateCheckResult& r : results) {
    out.insert(out.end(), r.findings.begin(), r.findings.end());
  }
  return out;
}

CodeSpecsGate::CodeSpecsGate(const SpecModel& model, const SpecDocument& document,
                             const CodeSpecsAreaCatalog& catalog,
                             const DocSpecsSchema* schema, std::string rootType)
    : model_(&model),
      document_(&document),
      catalog_(&catalog),
      schema_(schema),
      rootType_(std::move(rootType)) {}

CodeSpecsGateReport CodeSpecsGate::run() const {
  CodeSpecsGateReport report;
  CodeSpecsGateCheckResult r1 = a1();
  CodeSpecsGateCheckResult r2 = a2();
  CodeSpecsGateCheckResult r3 = a3(&report.extracts);
  CodeSpecsGateCheckResult r4 =
      !catalog_->hasGateTables ? notRun(CodeSpecsGateCheck::A4, kNoTables)
      : !report.extracts.has_value()
          ? notRun(CodeSpecsGateCheck::A4, kNoExtracts)
          : a4(*report.extracts);
  CodeSpecsGateCheckResult r5 = catalog_->hasGateTables
                                    ? a5()
                                    : notRun(CodeSpecsGateCheck::A5, kNoTables);
  report.results = {std::move(r1), std::move(r2), std::move(r3), std::move(r4),
                    std::move(r5)};
  return report;
}

CodeSpecsGateCheckResult CodeSpecsGate::a1() const {
  if (schema_ == nullptr) {
    return notRun(CodeSpecsGateCheck::A1, kNoSchema);
  }
  std::string markdown = document_->toMarkdown(*model_, rootType_);
  std::vector<DocSpecsViolation> violations;
  DocSpecsValidator(*schema_).validateMarkdown(markdown, violations);
  CodeSpecsGateCheckResult r;
  r.check = CodeSpecsGateCheck::A1;
  for (const DocSpecsViolation& v : violations) {
    // "" is this runtime's spelling of the Dart `null` for both.
    std::string line = std::to_string(v.line);
    std::string location = !v.sectionId.empty() ? v.sectionId
                           : !v.path.empty()    ? v.path
                                                : "line " + line;
    r.findings.push_back(finding(CodeSpecsGateCheck::A1, v.rule, location,
                                 "line " + line + ": " + v.message));
  }
  return r;
}

CodeSpecsGateCheckResult CodeSpecsGate::a2() const {
  CodeSpecsGateCheckResult r;
  r.check = CodeSpecsGateCheck::A2;
  for (const SpecValidationError& e : validateDocument(*model_, *document_)) {
    r.findings.push_back(
        finding(CodeSpecsGateCheck::A2, e.code, e.path, e.message));
  }
  return r;
}

/* A3 collects **every** unrouted class over the non-strict walk, rather than
 * the first one the strict walk throws on; only when there is none does it run
 * the extraction itself. */
CodeSpecsGateCheckResult CodeSpecsGate::a3(
    std::optional<std::vector<CodeSpecsExtract>>* extracts) const {
  CodeSpecsGateCheckResult r;
  r.check = CodeSpecsGateCheck::A3;
  std::optional<CodeSpecsExtractor> extractor;
  try {
    extractor.emplace(*model_, *document_, *catalog_, rootType_);
  } catch (const CodeSpecsExtractError& e) {
    r.findings.push_back(
        finding(CodeSpecsGateCheck::A3, "root", e.path(), e.message()));
    return r;
  }
  for (const CodeSpecsRouting& rt : extractor->routings()) {
    if (rt.verdict != CodeSpecsRoutingVerdict::Unrouted) {
      continue;
    }
    r.findings.push_back(finding(
        CodeSpecsGateCheck::A3, "unrouted", rt.path,
        rt.className +
            " carries no @CodeSpecKind, @FollowUpKind or @NoArtifact — its "
            "content would reach no extract"));
  }
  if (r.findings.empty()) {
    *extracts = extractor->extractAll();
  }
  return r;
}

/* A4 over the extraction run: for each obligation whose area's extract is
 * non-empty, every instance of the obligation's class that the extract carries
 * must carry the source value, populated (non-blank); a `resolvesTo`
 * obligation's value must also equal a value the run carries at the target. */
CodeSpecsGateCheckResult CodeSpecsGate::a4(
    const std::vector<CodeSpecsExtract>& extracts) const {
  CodeSpecsGateCheckResult r;
  r.check = CodeSpecsGateCheck::A4;
  for (const CodeSpecsRequiredArgument& o : catalog_->requiredArguments) {
    const CodeSpecsExtract* extract = nullptr;
    for (const CodeSpecsExtract& x : extracts) {
      if (x.area.code == o.area) {
        extract = &x;
        break;
      }
    }
    if (extract == nullptr || extract->entries.empty()) {
      continue;
    }
    // The instances the extract carries of the obligation's class, in
    // document order, each with the populated source value it holds.
    struct Instance {
      std::string path;
      std::optional<std::string> value;
      bool applies = false;
    };
    std::vector<Instance> instances;
    for (const CodeSpecsExtractEntry& e : extract->entries) {
      if (e.className != o.field.className) {
        continue;
      }
      std::string path = parentPath(e.path);
      Instance* inst = nullptr;
      for (Instance& i : instances) {
        if (i.path == path) {
          inst = &i;
          break;
        }
      }
      if (inst == nullptr) {
        instances.push_back(Instance{path, std::nullopt, false});
        inst = &instances.back();
      }
      if (o.when.has_value() && e.fieldName == o.when->member &&
          e.formField == o.when->formField && e.value == o.whenEquals) {
        inst->applies = true;
      }
      if (e.fieldName == o.field.member && e.formField == o.field.formField &&
          !isBlank(e.value)) {
        inst->value = e.value;
      }
    }
    for (const Instance& inst : instances) {
      if (o.when.has_value() && !inst.applies) {
        continue;
      }
      if (!inst.value.has_value()) {
        r.findings.push_back(finding(
            CodeSpecsGateCheck::A4, "missingSource", inst.path,
            o.marker + "." + o.argument + " (" + o.area +
                ") is required, and its source " + o.source() +
                " is empty here"));
        continue;
      }
      if (!o.resolvesTo.has_value()) {
        continue;
      }
      const CodeSpecsFieldRef& target = *o.resolvesTo;
      bool known = false;
      for (const CodeSpecsExtract& x : extracts) {
        for (const CodeSpecsExtractEntry& e : x.entries) {
          if (e.className == target.className && e.fieldName == target.member &&
              e.formField == target.formField && e.value == *inst.value) {
            known = true;
            break;
          }
        }
        if (known) {
          break;
        }
      }
      if (!known) {
        r.findings.push_back(finding(
            CodeSpecsGateCheck::A4, "unresolvedReference", inst.path,
            o.source() + " names `" + *inst.value + "`, which no " +
                target.source() + " in this document carries — " + o.marker +
                "." + o.argument + " (" + o.area +
                ") has nothing to resolve against"));
      }
    }
  }
  return r;
}

/* A5 against the model, not the document: each carrier's class, member and
 * form field must still exist. */
CodeSpecsGateCheckResult CodeSpecsGate::a5() const {
  CodeSpecsGateCheckResult r;
  r.check = CodeSpecsGateCheck::A5;
  for (const CodeSpecsCarrier& c : catalog_->carriers) {
    const SpecClass* cls = model_->classNamed(c.field.className);
    const SpecField* field =
        cls == nullptr ? nullptr : cls->fieldNamed(c.field.member);
    bool present = field != nullptr;
    if (present && c.field.formField.has_value()) {
      present = false;
      for (const FormFieldSpec& f : field->formFields) {
        if (f.name == *c.field.formField) {
          present = true;
          break;
        }
      }
    }
    if (!present) {
      r.findings.push_back(finding(
          CodeSpecsGateCheck::A5, "missingCarrier", c.source(),
          "the model no longer offers " + c.source() + " (" + c.introducedBy +
              ") — a project with that structured fact would have to write "
              "prose again"));
    }
  }
  return r;
}

}  // namespace som
