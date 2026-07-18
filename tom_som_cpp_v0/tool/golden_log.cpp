// Cross-language golden-log generator for C++ (roadmap item 7b).
//
// Mirror of tom_som_dart_v0/tool/golden_log.dart — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Build & run (from the project root): see run_tests.sh / examples/README.md.
//   g++ -std=c++17 -Iinclude -I../tom_som_cpp_runtime/include tool/golden_log.cpp
//     build/libtom_som_cpp_v0.a ../tom_som_cpp_runtime/build/libtom_som_cpp_runtime.a
//     -o build/golden_log
//   ./build/golden_log [samplePath] [outputPath]
#include "tom_som_cpp_v0.hpp"
#include "tom_som_cpp_v0_meta.hpp"

#include "docspecs_validator.hpp"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <optional>
#include <sstream>
#include <string>
#include <vector>

// Escapes a value so it occupies exactly one log line: backslash first (so the
// other escapes are unambiguous), then the three whitespace controls.
static std::string esc(const std::string& s) {
  std::string out;
  out.reserve(s.size());
  for (const char c : s) {
    switch (c) {
      case '\\': out += "\\\\"; break;
      case '\n': out += "\\n"; break;
      case '\r': out += "\\r"; break;
      case '\t': out += "\\t"; break;
      default: out += c; break;
    }
  }
  return out;
}

[[noreturn]] static void die(const std::string& msg) {
  std::cerr << msg << "\n";
  std::exit(2);
}

// Reads the whole file at `path` into a string, or aborts.
static std::string readFile(const std::string& path) {
  std::ifstream f(path, std::ios::binary);
  if (!f) die("read failed: " + path);
  std::ostringstream ss;
  ss << f.rdbuf();
  return ss.str();
}

// Maps a runtime meta-kind constant to the DART enum spelling used by the
// cross-language golden log. The runtime spells the enum-value kind "enum";
// the golden format requires "enumValue". The other six are identical.
static std::string dartKind(const char* kind) {
  const std::string k = kind == nullptr ? "" : kind;
  if (k == som::kSomMetaKindList) return "list";
  if (k == som::kSomMetaKindForm) return "form";
  if (k == som::kSomMetaKindSection) return "section";
  if (k == som::kSomMetaKindContent) return "content";
  if (k == som::kSomMetaKindEnumValue) return "enumValue";
  if (k == som::kSomMetaKindComplex) return "complex";
  if (k == som::kSomMetaKindScalar) return "scalar";
  die("unknown meta kind: " + k);
}

int main(int argc, char** argv) {
  const std::string sample =
      argc > 1 ? argv[1]
               : "../tom_som_conformance/samples/"
                 "meridian_order_management.docspecs.yaml";
  const std::string output =
      argc > 2 ? argv[2] : "../tom_som_conformance/golden/cpp.log";

  // Generic view — decode against the D00 root's metadata tree (DR33).
  std::string genErr;
  std::optional<som::SpecDocument> genDoc = som::SpecDocument::fromFile(
      sample, tom_som_v0_meta::d00SolutionBlueprintMetaTree(), &genErr);
  if (!genDoc) die("fromFile failed: " + genErr);
  som::SpecDocument doc = std::move(*genDoc);
  // Typed view — the facade borrows a separate caller-owned document loaded from
  // the same file, so its reads must agree with the generic `doc` byte-for-byte.
  som::SpecDocument typedDoc;
  tom_som_v0::D00SolutionBlueprint sbp =
      tom_som_v0::D00SolutionBlueprint::loadFile(typedDoc, sample);

  std::vector<std::string> out;
  out.push_back("# TomSpecs SOM golden log — canonical cross-language reading.");
  out.push_back(
      "# All nine per-language generators must emit byte-identical output.");
  out.push_back("FORMAT\t7");
  out.push_back("MODELVERSION\t" + esc(doc.modelVersion));

  // --- Generic: every content leaf, sorted by path. ---
  out.push_back("SECTION\tgeneric-content");
  {
    std::vector<std::string> paths = doc.contentPaths();  // byte-sorted by runtime
    for (const std::string& p : paths) {
      out.push_back("C\t" + p + "\t" + esc(doc.content(p)));
    }
  }

  // --- Generic: every form section + field, sorted by path then field. ---
  out.push_back("SECTION\tgeneric-forms");
  {
    std::vector<std::string> paths = doc.formPaths();
    for (const std::string& p : paths) {
      std::vector<std::string> fields = doc.formFieldNames(p);
      for (const std::string& f : fields) {
        out.push_back("F\t" + p + "\t" + f + "\t" + esc(doc.formField(p, f)));
      }
    }
  }

  // --- Generic: every list container + its item paths (document order). ---
  out.push_back("SECTION\tgeneric-lists");
  {
    std::vector<std::string> paths = doc.listPaths();
    for (const std::string& p : paths) {
      std::vector<std::string> items = doc.listItems(p);
      out.push_back("L\t" + p + "\t" + std::to_string(items.size()));
      for (const std::string& item : items) {
        out.push_back("I\t" + item);
        const std::string* sid = doc.itemSectionIdOpt(item);
        if (sid != nullptr) {
          out.push_back("ID\t" + item + "\t" + esc(*sid));
        }
      }
    }
  }

  // --- Generic: every stored headline, sorted by path (FORMAT 3 / YRD3). ---
  out.push_back("SECTION\tgeneric-headlines");
  {
    std::vector<std::string> paths = doc.headlinePaths();  // byte-sorted
    for (const std::string& p : paths) {
      out.push_back("H\t" + p + "\t" + esc(doc.headline(p)));
    }
  }

  // --- Typed: a curated traversal of the facade that must agree with the
  // generic reads. ---
  out.push_back("SECTION\ttyped");

  auto typedContent = [&](const std::string& path, const std::string& value) {
    const std::string leaf = path + "/content";
    const std::string generic = doc.content(leaf);
    if (value != generic) {
      die("TYPED MISMATCH at " + leaf + ": typed=\"" + value + "\" generic=\"" +
          generic + "\"");
    }
    out.push_back("T\t" + leaf + "\t" + esc(value));
  };

  typedContent(sbp.path(), sbp.content());
  { auto s = sbp.documentControl(); typedContent(s.path(), s.content()); }
  { auto s = sbp.introductionAndScope(); typedContent(s.path(), s.content()); }
  { auto s = sbp.glossaryAndAbbreviations(); typedContent(s.path(), s.content()); }
  { auto s = sbp.stakeholdersAndGovernance(); typedContent(s.path(), s.content()); }
  { auto s = sbp.currentLandscape(); typedContent(s.path(), s.content()); }
  { auto s = sbp.assumptionsConstraintsDependencies(); typedContent(s.path(), s.content()); }
  { auto s = sbp.targetOperatingModelConcept(); typedContent(s.path(), s.content()); }
  { auto s = sbp.informationAndDataModel(); typedContent(s.path(), s.content()); }
  { auto s = sbp.requirements(); typedContent(s.path(), s.content()); }
  { auto s = sbp.solutionArchitectureAndTechnology(); typedContent(s.path(), s.content()); }
  { auto s = sbp.securityAndAccessModel(); typedContent(s.path(), s.content()); }
  { auto s = sbp.experienceAndInterfaceDesign(); typedContent(s.path(), s.content()); }
  { auto s = sbp.qualityAndAcceptanceModel(); typedContent(s.path(), s.content()); }
  { auto s = sbp.deliveryTransitionAndRollout(); typedContent(s.path(), s.content()); }

  // Nested section reached through two typed hops.
  {
    auto intro = sbp.introductionAndScope();
    auto goals = intro.goals();
    typedContent(goals.path(), goals.content());
  }

  // A typed list traversal: length + each element's content, each asserted
  // against the generic list-item read.
  {
    auto cl = sbp.currentLandscape();
    som::SomList metrics = cl.operationalMetrics();
    const std::vector<std::string> metricItems = doc.listItems(metrics.path());
    if (metrics.length() != metricItems.size()) {
      die("TYPED LIST LENGTH MISMATCH at " + metrics.path());
    }
    out.push_back("TL\t" + metrics.path() + "\t" +
                  std::to_string(metrics.length()));
    for (std::size_t i = 0; i < metrics.length(); i++) {
      tom_som_v0::CurrentOperationalMetric elem(typedDoc, metrics.itemPathAt(i));
      const std::string leaf = elem.path() + "/content";
      const std::string generic = doc.content(leaf);
      if (elem.content() != generic) {
        die("TYPED LIST ITEM MISMATCH at " + leaf);
      }
      out.push_back("TI\t" + leaf + "\t" + esc(elem.content()));
    }
  }

  // --- Typed non-String form fields (FORMAT 7, YRD7): native int/bool/enum
  // members read through the typed facade and asserted against the generic form
  // store, canonicalised through the SAME boundary rules the facade setters used
  // to write them (int -> decimal, bool -> "true"/"false", enum -> constant
  // name). The emitted value is the raw stored string, so the lines are byte-
  // identical across languages regardless of native member types. ---
  out.push_back("SECTION\ttyped-form");
  {
    auto somFormatInt = [](std::optional<long> v) -> std::string {
      return v.has_value() ? std::to_string(*v) : "";
    };
    auto somFormatBool = [](std::optional<bool> v) -> std::string {
      return v.has_value() ? (*v ? "true" : "false") : "";
    };
    auto typedForm = [&](const std::string& formPath, const std::string& field,
                         const std::string& canonical) {
      const std::string generic = doc.formField(formPath, field);
      if (canonical != generic) {
        die("TYPED FORM MISMATCH at " + formPath + "." + field + ": typed=\"" +
            canonical + "\" generic=\"" + generic + "\"");
      }
      out.push_back("TF\t" + formPath + "\t" + field + "\t" + esc(generic));
    };

    auto actorOverview = sbp.targetOperatingModelConcept()
                             .targetBusinessProcess()
                             .processStepsAndActorInteractions()
                             .actorOverview()
                             .overview();
    const std::string aoPath = actorOverview.path();
    typedForm(aoPath, "totalActorCount",
              somFormatInt(actorOverview.totalActorCount()));
    typedForm(aoPath, "humanActorCount",
              somFormatInt(actorOverview.humanActorCount()));
    typedForm(aoPath, "systemActorCount",
              somFormatInt(actorOverview.systemActorCount()));
    typedForm(aoPath, "externalActorCount",
              somFormatInt(actorOverview.externalActorCount()));

    auto accForm = sbp.experienceAndInterfaceDesign()
                       .accessibility()
                       .accessibilityOverviewContent();
    typedForm(accForm.path(), "accessibilityStatement",
              somFormatBool(accForm.accessibilityStatement()));

    som::SomList coverage =
        sbp.qualityAndAcceptanceModel().iso25010Coverage().characteristics();
    out.push_back("TL\t" + coverage.path() + "\t" +
                  std::to_string(coverage.length()));
    for (std::size_t i = 0; i < coverage.length(); i++) {
      tom_som_v0::Iso25010CoverageEntry entry(typedDoc, coverage.itemPathAt(i));
      auto cform = entry.content();
      typedForm(cform.path(), "characteristic", cform.characteristic());
    }
  }

  // --- Meta (FORMAT 2): the generated metadata tree read three ways. Every
  // path and every emitted field is model-derived, so the lines are byte-
  // identical across all nine languages even though the accessor *names* and
  // node *types* differ. ---
  namespace m = tom_som_v0_meta;
  const som::SomMetaTree& metaTree = m::d00SolutionBlueprintMetaTree();

  // Metadata reads: for a curated set of nodes resolved by path, emit the
  // node's kind plus its help / comment / doc-comment.
  out.push_back("SECTION\tmeta");
  auto metaNode = [&](const std::string& path) {
    const som::SomMetaNode* n = metaTree.byPath(path);
    if (n == nullptr) die("META MISSING at " + path);
    out.push_back("M\t" + path + "\t" + dartKind(n->kind) + "\t" +
                  esc(n->sectionId) + "\t" + esc(n->contentHelp) + "\t" +
                  esc(n->comment) + "\t" + esc(n->docComment) + "\t" +
                  esc(n->headline));
  };

  metaNode("SBP");
  metaNode("SBP/documentControl");
  metaNode("SBP/documentControl/RVHST-REVS-LST");
  metaNode("SBP/introductionAndScope");
  metaNode("SBP/introductionAndScope/goals");
  metaNode("SBP/introductionAndScope/goals/content");
  metaNode("SBP/currentLandscape");
  metaNode("SBP/currentLandscape/CUOPME-OPER-LST");
  metaNode("SBP/requirements");
  metaNode("SBP/requirements/content");

  // --- Meta form fields (FORMAT 7, YRD7): the FRE list-element content form
  // read through the metadata tree — one MF line per field (declaration
  // order) with type/required plus the enumValues column. All values are
  // model-derived. ---
  out.push_back("SECTION\tmeta-form");
  // Generalized over any list path whose element content is a form: emit one MF
  // line per field (declaration order) with type/required and the enumValues
  // column (comma-joined constant names, empty for non-enum fields).
  auto metaForm = [&](const std::string& listPath) {
    const som::SomMetaNode* listNode = metaTree.byPath(listPath);
    const som::SomMetaNode* element =
        listNode != nullptr ? listNode->elementNode.get() : nullptr;
    const som::SomMetaNode* contentNode = nullptr;
    if (element != nullptr) {
      for (const auto& child : element->children) {
        if (child->memberName == "content") contentNode = child.get();
      }
    }
    const som::SomFormMeta* form =
        (contentNode != nullptr && contentNode->form.has_value())
            ? &*contentNode->form
            : nullptr;
    if (form == nullptr) {
      std::cerr << "META FORM MISSING at " << listPath << " element content\n";
      std::exit(3);
    }
    // Element subtrees have no static document path; use an ASCII marker
    // segment so the log path stays ASCII (mirrored verbatim per language).
    const std::string formPath = listPath + "/#element/content";
    for (const som::SomFormFieldMeta& f : form->fields) {
      std::string joined;
      for (std::size_t j = 0; j < f.enumValues.size(); j++) {
        if (j > 0) joined += ",";
        joined += f.enumValues[j];
      }
      out.push_back("MF\t" + formPath + "\t" + esc(f.name) + "\t" +
                    esc(f.typeName) + "\t" + (f.required ? "1" : "0") + "\t" +
                    esc(joined));
    }
  };
  metaForm("SBP/introductionAndScope/requirements/functionalRequirements/FRE-REQU-LST");
  metaForm("SBP/qualityAndAcceptanceModel/iso25010Coverage/I25CV-CHAR-LST");

  // Dot-notation navigation: the typed nav accessors must resolve to exactly
  // the path byPath finds, and to the *same* node instance.
  out.push_back("SECTION\tmeta-nav");
  auto metaNav = [&](const som::SomMetaRef& ref, const std::string& expected) {
    if (ref.path != expected) {
      die("META NAV PATH at " + ref.path + " expected " + expected);
    }
    const som::SomMetaNode* byPath = metaTree.byPath(expected);
    if (byPath == nullptr || ref.meta() != byPath) {
      die("META NAV NODE mismatch at " + expected);
    }
    out.push_back("N\t" + expected);
  };

  m::NavD00SolutionBlueprint navRoot = m::d00SolutionBlueprintMetaNav(metaTree);
  m::NavIntroductionAndScope navIntro =
      m::navD00SolutionBlueprint_introductionAndScope(navRoot);
  m::NavGoals navGoals = m::navIntroductionAndScope_goals(navIntro);
  m::NavCurrentLandscape navCl =
      m::navD00SolutionBlueprint_currentLandscape(navRoot);
  m::NavRequirements navReq = m::navD00SolutionBlueprint_requirements(navRoot);
  m::NavDocumentControl navDc =
      m::navD00SolutionBlueprint_documentControl(navRoot);

  metaNav(navRoot.ref, "SBP");
  metaNav(navDc.ref, "SBP/documentControl");
  metaNav(navIntro.ref, "SBP/introductionAndScope");
  metaNav(navGoals.ref, "SBP/introductionAndScope/goals");
  metaNav(m::navGoals_content(navGoals), "SBP/introductionAndScope/goals/content");
  metaNav(navCl.ref, "SBP/currentLandscape");
  metaNav(navReq.ref, "SBP/requirements");
  metaNav(m::navRequirements_content(navReq), "SBP/requirements/content");

  // ID-tree navigation: the hoisted-id accessors must agree — same path, same
  // node instance — with the dot-notation position, including list elements.
  out.push_back("SECTION\tmeta-id");
  auto metaId = [&](const som::SomMetaRef& idRef, const som::SomMetaRef& navRef) {
    if (idRef.path != navRef.path || idRef.meta() != navRef.meta()) {
      die("META ID mismatch at " + idRef.path + " vs " + navRef.path);
    }
    out.push_back("D\t" + idRef.path);
  };

  m::IdD00SolutionBlueprint idRoot = m::d00SolutionBlueprintMetaId(metaTree);
  som::SomListMetaRef idRevs = m::idD00SolutionBlueprint_RVHST_REVS_LST(idRoot);
  som::SomListMetaRef navRevs = m::navDocumentControl_revisionHistory(navDc);

  metaId(idRoot.ref, navRoot.ref);
  metaId(idRevs.ref, navRevs.ref);
  {
    void* idItem0 = idRevs.item(0);
    void* navItem0 = navRevs.item(0);
    metaId(*reinterpret_cast<som::SomMetaRef*>(idItem0),
           *reinterpret_cast<som::SomMetaRef*>(navItem0));
    delete reinterpret_cast<m::NavRevisionEntry*>(idItem0);
    delete reinterpret_cast<m::NavRevisionEntry*>(navItem0);
  }

  // DocSpecs validation: the shared markdown rendering of the sample validates
  // cleanly against the facade's generated Solution-Blueprint schema.
  out.push_back("SECTION\tdocspecs");
  {
    const std::string schemaPath =
        "schemas/solution-blueprint/"
        "solution-blueprint.1.0.docspecs-schema.yaml";
    const std::string sampleMdPath =
        "../tom_som_conformance/samples/meridian_order_management.md";
    std::string schemaErr;
    std::optional<som::DocSpecsSchema> schema =
        som::docspecsSchemaFromYamlText(readFile(schemaPath), &schemaErr);
    if (!schema) die("DocSpecsSchemaFromYamlText failed: " + schemaErr);
    const std::string sampleMd = readFile(sampleMdPath);
    som::DocSpecsValidator validator(*schema);
    std::vector<som::DocSpecsViolation> violations;
    validator.validateMarkdown(sampleMd, violations);
    out.push_back("DS\troot\t" + esc(schema->rootSectionId()));
    out.push_back("DS\twarnings\t" + std::to_string(schema->warnings.size()));
    out.push_back("DS\tviolations\t" + std::to_string(violations.size()));
    for (const som::DocSpecsViolation& v : violations) {
      out.push_back("DV\t" + v.rule + "\t" + esc(v.sectionId) + "\t" +
                    std::to_string(v.line));
    }
  }

  // Join with LF and terminate with a single trailing LF — fixed regardless of
  // host platform so the bytes match on every machine.
  std::string body;
  for (std::size_t i = 0; i < out.size(); i++) {
    if (i != 0) body += '\n';
    body += out[i];
  }
  body += '\n';

  std::ofstream fp(output, std::ios::binary);
  if (!fp) die("write failed");
  fp.write(body.data(), static_cast<std::streamsize>(body.size()));
  fp.close();
  std::cout << "wrote " << out.size() << " lines to " << output << "\n";
  return 0;
}
