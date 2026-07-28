/* Tests for the consolidated DocSpecs parsing + validation module (SOM §14,
 * SOM §14) — an idiomatic-C++ port of
 * `tom_som_c_runtime/tests/docspecs_validator_test.c` (itself a 1:1 port of the
 * Go / TypeScript / Python / Dart reference suites): the generic schema-free
 * parse, schema loading (with warnings for unsupported features), the
 * structured violation list, and the acceptance criterion — the markdown-codec-emitted
 * Solution Blueprint sample validates cleanly against the generated
 * `solution-blueprint` schema.
 *
 * Check names byte-match the reference suites. Exit status is the number of
 * failed checks (0 = green).
 */
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "docspecs_validator.hpp"
#include "spec_document.hpp"
#include "spec_document_markdown.hpp"
#include "spec_meta.hpp"
#include "spec_meta_bridge.hpp"
#include "spec_model.hpp"
#include "yaml.hpp"

namespace {

/* dvSiblings is the ai_build folder holding the sibling runtime packages. The
 * unit binaries run from the C++ package root, so the Go suite's "../.." maps
 * to "..". */
const char* DV_SIBLINGS = "..";

int g_checks = 0;
int g_failures = 0;

/* mdCheck — the reference harness helper. `detail` may be empty. */
void mdCheck(const char* name, bool cond, const std::string& detail = "") {
  ++g_checks;
  if (cond) {
    return;
  }
  ++g_failures;
  if (!detail.empty()) {
    std::fprintf(stderr, "FAIL %s: %s\n", name, detail.c_str());
  } else {
    std::fprintf(stderr, "FAIL %s\n", name);
  }
}

[[noreturn]] void fatal(const char* what, const std::string& err) {
  std::fprintf(stderr, "fatal: %s: %s\n", what,
               err.empty() ? "(no message)" : err.c_str());
  std::exit(2);
}

/* ---- small string helpers ------------------------------------------------ */

/* Replaces the first occurrence of `old` in `src` with `rep`. */
std::string strReplaceFirst(const std::string& src, const std::string& old,
                            const std::string& rep) {
  std::size_t at = src.find(old);
  if (at == std::string::npos) {
    return src;
  }
  return src.substr(0, at) + rep + src.substr(at + old.size());
}

bool contains(const std::string& hay, const std::string& needle) {
  return hay.find(needle) != std::string::npos;
}

/* Reads a whole file into a string, or exits. */
std::string readFile(const std::string& path) {
  std::ifstream f(path, std::ios::binary);
  if (!f) {
    std::fprintf(stderr, "read %s: cannot open\n", path.c_str());
    std::exit(2);
  }
  std::ostringstream ss;
  ss << f.rdbuf();
  return ss.str();
}

/* ---- fixtures ------------------------------------------------------------ */

/* Fixture schema (hand-written in the exact schema-generator output shape , SOM §13). */
const char* dvSchemaYaml =
    "title-format: \"# <!--[D00]--> Demo Document\"\n"
    "section-types:\n"
    "  goal-item:\n"
    "    prefix: GOAL_ITEM_\n"
    "    pattern-check-id:\n"
    "      pattern: \"^GOAL-ITEM-[0-9]+$\"\n"
    "      error-message: IDs of this section must match GOAL-ITEM-xxx\n"
    "  d00-ovr:\n"
    "    prefix: D00_OVR\n"
    "    text-required: true\n"
    "  d00-hdr:\n"
    "    prefix: D00_HDR\n"
    "    format: header-form\n"
    "  gsum:\n"
    "    prefix: GSUM\n"
    "  diag:\n"
    "    prefix: DIAG\n"
    "    format: mermaid\n"
    "  goals:\n"
    "    prefix: GOALS\n"
    "    subsection-types:\n"
    "      goal-item:\n"
    "        min-count: 1\n"
    "        max-count: infinite\n"
    "      gsum:\n"
    "        max-count: 1\n"
    "form-types:\n"
    "  header-form:\n"
    "    fields:\n"
    "      - fieldname: author\n"
    "        required: true\n"
    "      - fieldname: reviewer\n"
    "        pattern-check:\n"
    "          pattern: \"^[A-Z]\"\n"
    "          error-message: Reviewer must start with an uppercase letter\n"
    "document:\n"
    "  sections:\n"
    "    d00-ovr:\n"
    "      section-type: d00-ovr\n"
    "    d00-hdr:\n"
    "      section-type: d00-hdr\n"
    "      optional: true\n"
    "    goals:\n"
    "      section-type: goals\n"
    "      optional: true\n"
    "    diag:\n"
    "      section-type: diag\n"
    "      optional: true\n";

const char* dvValidDoc =
    "<!-- docspec: demo-document/1.0 -->\n"
    "# <!--[D00]--> Demo Document\n"
    "\n"
    "Intro text.\n"
    "\n"
    "## <!--[D00-OVR]--> Overview\n"
    "\n"
    "Some overview text.\n"
    "\n"
    "## <!--[D00-HDR]--> Header\n"
    "\n"
    "Author: Alice\n"
    "Reviewer: Bob\n"
    "\n"
    "## <!--[GOALS]--> Goals\n"
    "\n"
    "### <!--[GOAL-ITEM-1]--> Goal 1\n"
    "\n"
    "First goal.\n"
    "\n"
    "### <!--[GOAL-ITEM-2]--> Goal 2\n"
    "\n"
    "Second goal.\n";

/* ---- shared derived helpers ---------------------------------------------- */

/* dvSchema — loads the fixture schema or fatally aborts. */
som::DocSpecsSchema dvSchema() {
  std::string err;
  auto schema = som::docspecsSchemaFromYamlText(dvSchemaYaml, &err);
  if (!schema.has_value()) {
    fatal("DocSpecsSchemaFromYamlText", err);
  }
  return *schema;
}

/* dvValidate — schema-load + validate `md`, writing findings to `out`. */
void dvValidate(const std::string& md, std::vector<som::DocSpecsViolation>& out) {
  som::DocSpecsSchema schema = dvSchema();
  som::DocSpecsValidator val(schema);
  val.validateMarkdown(md, out);
}

/* dvDetail — the `; `-joined violation strings. */
std::string dvDetail(const std::vector<som::DocSpecsViolation>& v) {
  std::string out;
  for (std::size_t i = 0; i < v.size(); ++i) {
    if (i > 0) {
      out += "; ";
    }
    out += v[i].display();
  }
  return out;
}

/* dvChildIDs — the `,`-joined child ids of `s`. */
std::string dvChildIDs(const som::DocSpecsSection& s) {
  std::string out;
  for (std::size_t i = 0; i < s.children.size(); ++i) {
    if (i > 0) {
      out += ',';
    }
    out += s.children[i]->id;
  }
  return out;
}

std::string joinWarnings(const std::vector<std::string>& w,
                         const std::string& sep) {
  std::string out;
  for (std::size_t i = 0; i < w.size(); ++i) {
    if (i > 0) {
      out += sep;
    }
    out += w[i];
  }
  return out;
}

/* --- DocSpecsDocument parse (generic, schema-free) ------------------------ */

void TestDocspecsParseTree() {
  som::DocSpecsDocument doc = som::docspecsParseDocument(dvValidDoc);
  mdCheck("parse.declaredSchema", doc.declaredSchema == "demo-document/1.0",
          doc.declaredSchema);
  mdCheck("parse.noViolations", doc.violations.empty(), dvDetail(doc.violations));
  mdCheck("parse.oneRoot", doc.sections.size() == 1,
          std::to_string(doc.sections.size()));
  const som::DocSpecsSection& root = *doc.sections[0];
  mdCheck("parse.root.id", root.id == "D00", root.id);
  mdCheck("parse.root.title", root.title == "Demo Document", root.title);
  mdCheck("parse.root.level", root.level == 1, std::to_string(root.level));
  mdCheck("parse.root.text", root.text() == "Intro text.", root.text());
  mdCheck("parse.root.children", dvChildIDs(root) == "D00-OVR,D00-HDR,GOALS",
          dvChildIDs(root));
  const som::DocSpecsSection& goals = *root.children[root.children.size() - 1];
  mdCheck("parse.goals.children", dvChildIDs(goals) == "GOAL-ITEM-1,GOAL-ITEM-2",
          dvChildIDs(goals));
  mdCheck("parse.goal1.text", goals.children[0]->text() == "First goal.",
          goals.children[0]->text());
}

void TestDocspecsParseFenceShield() {
  som::DocSpecsDocument doc = som::docspecsParseDocument(
      "# <!--[D00]--> Demo Document\n"
      "\n"
      "```md\n"
      "## <!--[NOT-A-SECTION]--> shielded\n"
      "```\n");
  mdCheck("parse.fence.noChildren", doc.sections[0]->children.empty());
  mdCheck("parse.fence.bodyKept",
          contains(doc.sections[0]->text(), "NOT-A-SECTION"));
}

void TestDocspecsParseMalformedHeading() {
  som::DocSpecsDocument doc = som::docspecsParseDocument(
      "# <!--[D00]--> Demo Document\n"
      "\n"
      "## Plain Heading\n");
  mdCheck("parse.malformed.count", doc.violations.size() == 1,
          dvDetail(doc.violations));
  if (!doc.violations.empty()) {
    const som::DocSpecsViolation& v = doc.violations[0];
    mdCheck("parse.malformed.rule", v.rule == som::kDocSpecsRuleMalformedHeading,
            v.display());
    mdCheck("parse.malformed.line", v.line == 3, std::to_string(v.line));
  }
}

/* --- DocSpecsSchemaFromYamlText ------------------------------------------- */

void TestDocspecsSchemaLoading() {
  som::DocSpecsSchema schema = dvSchema();
  mdCheck("schema.noWarnings", schema.warnings.empty(),
          joinWarnings(schema.warnings, "; "));
  mdCheck("schema.rootSectionId", schema.rootSectionId() == "D00",
          schema.rootSectionId());
  const som::DocSpecsSectionType* goalItem =
      schema.sectionTypeByName("goal-item");
  mdCheck("schema.goalItem.present", goalItem != nullptr);
  if (goalItem != nullptr) {
    mdCheck("schema.goalItem.prefix", goalItem->prefix == "GOAL_ITEM_",
            goalItem->prefix);
    mdCheck("schema.goalItem.pattern",
            goalItem->patternCheck.has_value() &&
                goalItem->patternCheck->pattern == "^GOAL-ITEM-[0-9]+$",
            goalItem->patternCheck.has_value() ? goalItem->patternCheck->pattern
                                               : std::string("<nil>"));
  }
  const som::DocSpecsSectionType* goals = schema.sectionTypeByName("goals");
  const som::DocSpecsSubsectionRule* goalSub =
      goals != nullptr ? goals->subsection("goal-item") : nullptr;
  mdCheck("schema.goals.min", goalSub != nullptr && goalSub->minCount == 1);
  mdCheck("schema.goals.maxInfinite", goalSub != nullptr && !goalSub->hasMax);
  const som::DocSpecsSubsectionRule* gsumSub =
      goals != nullptr ? goals->subsection("gsum") : nullptr;
  mdCheck("schema.gsum.max1",
          gsumSub != nullptr && gsumSub->hasMax && gsumSub->maxCount == 1);
  const som::DocSpecsFormType* form = schema.formType("header-form");
  std::string fieldNames;
  for (std::size_t i = 0; form != nullptr && i < form->fields.size(); ++i) {
    if (i > 0) {
      fieldNames += ',';
    }
    fieldNames += form->fields[i].name;
  }
  mdCheck("schema.form.fields", fieldNames == "author,reviewer", fieldNames);
  mdCheck("schema.form.authorRequired",
          form != nullptr && !form->fields.empty() && form->fields[0].required);
  const som::DocSpecsDocumentSection* ovr = schema.documentSection("d00-ovr");
  mdCheck("schema.doc.ovrRequired", ovr != nullptr && !ovr->optional);
  const som::DocSpecsDocumentSection* hdr = schema.documentSection("d00-hdr");
  mdCheck("schema.doc.hdrOptional", hdr != nullptr && hdr->optional);
}

/* The resolved section-type name for `id`, or "<nil>". */
std::string resolveName(const som::DocSpecsSchema& schema,
                        const std::string& id) {
  const som::DocSpecsSectionType* st = schema.resolveSectionType(id);
  return st == nullptr ? "<nil>" : st->name;
}

void TestDocspecsSchemaResolution() {
  som::DocSpecsSchema schema = dvSchema();
  mdCheck("resolve.goalItem", resolveName(schema, "GOAL-ITEM-7") == "goal-item",
          resolveName(schema, "GOAL-ITEM-7"));
  mdCheck("resolve.goals", resolveName(schema, "GOALS") == "goals",
          resolveName(schema, "GOALS"));
  mdCheck("resolve.ovr", resolveName(schema, "D00-OVR") == "d00-ovr",
          resolveName(schema, "D00-OVR"));
  mdCheck("resolve.none", resolveName(schema, "NOPE-1") == "<nil>",
          resolveName(schema, "NOPE-1"));
}

void TestDocspecsSchemaWarnings() {
  std::string err;
  auto schemaOpt = som::docspecsSchemaFromYamlText(
      "title-format: \"# <!--[D00]--> Demo\"\n"
      "generators:\n"
      "  something: true\n"
      "section-types:\n"
      "  d00-ovr:\n"
      "    prefix: D00_OVR\n"
      "    database-schema:\n"
      "      table: t\n"
      "document:\n"
      "  sections:\n"
      "    d00-ovr:\n"
      "      section-type: d00-ovr\n"
      "  custom-tag: x\n",
      &err);
  if (!schemaOpt.has_value()) {
    fatal("DocSpecsSchemaFromYamlText", err);
  }
  som::DocSpecsSchema& schema = *schemaOpt;
  std::string warnj = joinWarnings(schema.warnings, "; ");
  mdCheck("warnings.count", schema.warnings.size() == 3, warnj);
  std::string joined = joinWarnings(schema.warnings, "\n");
  mdCheck("warnings.generators", contains(joined, "generators"), joined);
  mdCheck("warnings.databaseSchema", contains(joined, "database-schema"),
          joined);
  mdCheck("warnings.customTag", contains(joined, "custom-tag"), joined);
  mdCheck("warnings.stillLoads",
          schema.sectionTypeByName("d00-ovr") != nullptr);
}

/* --- DocSpecsValidator.Validate ------------------------------------------- */

void TestDocspecsValidateValid() {
  std::vector<som::DocSpecsViolation> v;
  dvValidate(dvValidDoc, v);
  mdCheck("validate.valid.empty", v.empty(), dvDetail(v));
}

void TestDocspecsValidateMissingRequiredSection() {
  std::string md = strReplaceFirst(
      dvValidDoc, "## <!--[D00-OVR]--> Overview\n\nSome overview text.\n\n", "");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.missingSection.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.missingSection.rule",
            v[0].rule == som::kDocSpecsRuleMissingRequiredSection,
            v[0].display());
    mdCheck("validate.missingSection.id", v[0].sectionId == "d00-ovr",
            v[0].sectionId);
    mdCheck("validate.missingSection.msg", contains(v[0].message, "d00-ovr"),
            v[0].message);
  }
}

void TestDocspecsValidateIdPatternMismatch() {
  std::string md = strReplaceFirst(dvValidDoc, "GOAL-ITEM-2", "GOAL-ITEM-B");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.idPattern.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.idPattern.rule",
            v[0].rule == som::kDocSpecsRuleIdPatternMismatch, v[0].display());
    mdCheck("validate.idPattern.id", v[0].sectionId == "GOAL-ITEM-B",
            v[0].sectionId);
    mdCheck("validate.idPattern.msg",
            v[0].message == "IDs of this section must match GOAL-ITEM-xxx",
            v[0].message);
    mdCheck("validate.idPattern.line", v[0].line == 21,
            std::to_string(v[0].line));
  }
}

void TestDocspecsValidateUnknownSection() {
  std::string md = strReplaceFirst(dvValidDoc,
                                   "### <!--[GOAL-ITEM-2]--> Goal 2",
                                   "### <!--[XYZ-2]--> Goal 2");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.unknown.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.unknown.rule",
            v[0].rule == som::kDocSpecsRuleUnknownSection, v[0].display());
    mdCheck("validate.unknown.id", v[0].sectionId == "XYZ-2", v[0].sectionId);
  }
}

void TestDocspecsValidateDisallowedPosition() {
  std::string md = strReplaceFirst(dvValidDoc,
                                   "### <!--[GOAL-ITEM-2]--> Goal 2",
                                   "### <!--[DIAG]--> Diagram");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.disallowed.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.disallowed.rule",
            v[0].rule == som::kDocSpecsRuleUnknownSection, v[0].display());
    mdCheck("validate.disallowed.msg",
            contains(v[0].message, "not an allowed subsection"), v[0].message);
  }
}

void TestDocspecsValidateMissingRequiredField() {
  std::string md = strReplaceFirst(dvValidDoc, "Author: Alice\n", "");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.missingField.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.missingField.rule",
            v[0].rule == som::kDocSpecsRuleMissingRequiredField, v[0].display());
    mdCheck("validate.missingField.id", v[0].sectionId == "D00-HDR",
            v[0].sectionId);
    mdCheck("validate.missingField.msg", contains(v[0].message, "author"),
            v[0].message);
  }
}

void TestDocspecsValidateFieldPatternMismatch() {
  std::string md = strReplaceFirst(dvValidDoc, "Reviewer: Bob", "Reviewer: bob");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.fieldPattern.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.fieldPattern.rule",
            v[0].rule == som::kDocSpecsRuleFieldPatternMismatch, v[0].display());
    mdCheck("validate.fieldPattern.msg",
            v[0].message == "Reviewer must start with an uppercase letter",
            v[0].message);
    mdCheck("validate.fieldPattern.line", v[0].line == 13,
            std::to_string(v[0].line));
  }
}

void TestDocspecsValidateTextRequired() {
  std::string md = strReplaceFirst(dvValidDoc, "Some overview text.\n\n", "");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.textRequired.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.textRequired.rule",
            v[0].rule == som::kDocSpecsRuleTextRequired, v[0].display());
    mdCheck("validate.textRequired.id", v[0].sectionId == "D00-OVR",
            v[0].sectionId);
  }
}

void TestDocspecsValidateTooManyItems() {
  std::string md = std::string(dvValidDoc) +
                   "\n"
                   "### <!--[GSUM]--> Summary\n\nOne.\n\n"
                   "### <!--[GSUM]--> Summary\n\nTwo.\n";
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.tooMany.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.tooMany.rule",
            v[0].rule == som::kDocSpecsRuleTooManyItems, v[0].display());
    mdCheck("validate.tooMany.msg", contains(v[0].message, "gsum"),
            v[0].message);
  }
}

void TestDocspecsValidateFormatMismatch() {
  std::string md = std::string(dvValidDoc) +
                   "\n## <!--[DIAG]--> Diagram\n\nno fence here\n";
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  mdCheck("validate.format.count", v.size() == 1, dvDetail(v));
  if (!v.empty()) {
    mdCheck("validate.format.rule",
            v[0].rule == som::kDocSpecsRuleFormatMismatch, v[0].display());
  }

  std::string ok = std::string(dvValidDoc) +
                   "\n## <!--[DIAG]--> Diagram\n\n```mermaid\ngraph TD;\n```\n";
  std::vector<som::DocSpecsViolation> vOk;
  dvValidate(ok, vOk);
  mdCheck("validate.format.fencedOk", vOk.empty(), dvDetail(vOk));
}

void TestDocspecsValidateRootMismatch() {
  std::string md =
      strReplaceFirst(dvValidDoc, "# <!--[D00]-->", "# <!--[D99]-->");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  bool found = false;
  for (const auto& viol : v) {
    if (viol.rule == som::kDocSpecsRuleFormatMismatch) {
      found = true;
    }
  }
  mdCheck("validate.rootMismatch.rule", found, dvDetail(v));
}

void TestDocspecsValidateNeverFailFast() {
  std::string m1 = strReplaceFirst(dvValidDoc, "Author: Alice\n", "");
  std::string m2 = strReplaceFirst(m1, "Reviewer: Bob", "Reviewer: bob");
  std::string md = strReplaceFirst(m2, "GOAL-ITEM-2", "GOAL-ITEM-B");
  std::vector<som::DocSpecsViolation> v;
  dvValidate(md, v);
  // de-dup rules seen, in first-seen order.
  std::vector<std::string> got;
  for (const auto& viol : v) {
    if (std::find(got.begin(), got.end(), viol.rule) == got.end()) {
      got.push_back(viol.rule);
    }
  }
  std::sort(got.begin(), got.end());
  std::vector<std::string> want = {som::kDocSpecsRuleMissingRequiredField,
                                   som::kDocSpecsRuleFieldPatternMismatch,
                                   som::kDocSpecsRuleIdPatternMismatch};
  std::sort(want.begin(), want.end());
  bool equal = got == want;
  std::string detail;
  for (std::size_t i = 0; i < got.size(); ++i) {
    if (i > 0) detail += ',';
    detail += got[i];
  }
  detail += " != ";
  for (std::size_t i = 0; i < want.size(); ++i) {
    if (i > 0) detail += ',';
    detail += want[i];
  }
  mdCheck("validate.neverFailFast", equal, detail);
}

/* --- BindDocspecsMarkdown -------------------------------------------------- */

void TestDocspecsBindDocspecsMarkdown() {
  std::string modelText = readFile(std::string(DV_SIBLINGS) +
                                   "/tom_som_conformance/corpus/model.meta.json");
  std::string err;
  auto model = som::SpecModel::fromJsonStr(modelText, &err);
  if (model == nullptr) {
    fatal("SpecModelFromJSON", err);
  }
  std::string mdText =
      readFile(std::string(DV_SIBLINGS) + "/tom_som_conformance/corpus/expected.md");
  som::SpecMarkdownResult result = som::docspecsBindMarkdown(*model, mdText);
  std::string rej;
  for (std::size_t i = 0; i < result.rejections.size(); ++i) {
    if (i > 0) {
      rej += '\n';
    }
    rej += result.rejections[i].display();
  }
  mdCheck("bind.clean", result.isClean(), rej);
  mdCheck("bind.appliedCount", result.appliedCount() > 0,
          std::to_string(result.appliedCount()));
}

/* --- acceptance: emitted sample vs generated schema ------------------------ */

void TestDocspecsDr7Acceptance() {
  std::string metaText = readFile(std::string(DV_SIBLINGS) +
                                  "/tom_som_dart_v0/meta/spec_model.meta.json");
  std::string err;
  auto model = som::SpecModel::fromJsonStr(metaText, &err);
  if (model == nullptr) {
    fatal("SpecModelFromJSON", err);
  }

  auto tree = som::somBuildMetaTree(*model, "D00SolutionBlueprint", &err);
  if (tree == nullptr) {
    fatal("BuildSomMetaTree", err);
  }

  std::string samplePath =
      std::string(DV_SIBLINGS) +
      "/tom_som_conformance/samples/meridian_order_management.docspecs.yaml";
  auto document = som::SpecDocument::fromFile(samplePath, *tree, &err);
  if (!document.has_value()) {
    fatal("FromFile", err);
  }

  std::string md = som::documentToMarkdown(*document, *model, "");

  std::string schemaText =
      readFile(std::string(DV_SIBLINGS) +
               "/tom_som_dart_v0/schemas/solution-blueprint/"
               "solution-blueprint.1.0.docspecs-schema.yaml");
  auto schemaOpt = som::docspecsSchemaFromYamlText(schemaText, &err);
  if (!schemaOpt.has_value()) {
    fatal("DocSpecsSchemaFromYamlText", err);
  }
  som::DocSpecsSchema& schema = *schemaOpt;

  mdCheck("dr7.rootSectionId", schema.rootSectionId() == "SBP",
          schema.rootSectionId());

  som::DocSpecsValidator val(schema);
  std::vector<som::DocSpecsViolation> v;
  val.validateMarkdown(md, v);
  std::string detail;
  for (std::size_t i = 0; i < v.size() && i < 20; ++i) {
    detail += '\n';
    detail += v[i].display();
  }
  mdCheck("dr7.violationsEmpty", v.empty(), detail);
}

}  // namespace

int main() {
  TestDocspecsParseTree();
  TestDocspecsParseFenceShield();
  TestDocspecsParseMalformedHeading();
  TestDocspecsSchemaLoading();
  TestDocspecsSchemaResolution();
  TestDocspecsSchemaWarnings();
  TestDocspecsValidateValid();
  TestDocspecsValidateMissingRequiredSection();
  TestDocspecsValidateIdPatternMismatch();
  TestDocspecsValidateUnknownSection();
  TestDocspecsValidateDisallowedPosition();
  TestDocspecsValidateMissingRequiredField();
  TestDocspecsValidateFieldPatternMismatch();
  TestDocspecsValidateTextRequired();
  TestDocspecsValidateTooManyItems();
  TestDocspecsValidateFormatMismatch();
  TestDocspecsValidateRootMismatch();
  TestDocspecsValidateNeverFailFast();
  TestDocspecsBindDocspecsMarkdown();
  TestDocspecsDr7Acceptance();

  std::fprintf(stderr, "docspecs_validator_test: %d checks, %d failures\n",
               g_checks, g_failures);
  return g_failures;
}
