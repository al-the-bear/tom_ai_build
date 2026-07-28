// Agreement suite for the generated C++ metadata module
// (`tom_som_cpp_v0_meta.hpp/.cpp`, SOM §7.2/§8) — the C++ port of the C facade's
// `meta_agreement_test.c` (itself the port of the Go `som_v0_meta_test.go` /
// Dart `generated_meta_test.dart`). Two guarantees over the *real* committed
// model:
//
//   1. EXHAUSTIVE TREE AGREEMENT — for every one of the 13 document roots the
//      generated static som::SomMetaTree is field-for-field identical (via
//      som::somMetaNodeDiff) to the tree som::somBuildMetaTree derives from the
//      committed `meta/spec_model.meta.json` at runtime. Because the emitter
//      writes the dot-notation / ID-tree accessor paths from the same node walk,
//      this anchors every path the accessors can produce.
//   2. SURFACE AGREEMENT — the dot-notation entry points (SOM §8), the ID-tree
//      entry points (SOM §8), and the dynamic by-path lookups all resolve to the
//      *same* som::SomMetaNode instances for representative positions (root,
//      nested section, content leaf, list, list element, hoisted id).
//
// Build & run via `./run_tests.sh`. Exit 0 == all green; prints "OK: N checks".
//
// C++ RAII means there is nothing to free: the static trees are owned by the
// module's function-local statics, the bridge trees by std::unique_ptr, and
// every accessor returns by value. som::SomMetaRef::meta() throws when a path
// resolves to no node (never expected for these positions), so any throw is a
// genuine failure surfaced by main's catch.

#include "tom_som_cpp_v0.hpp"
#include "tom_som_cpp_v0_meta.hpp"

#include <cstdio>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

namespace {

int g_passed = 0;
int g_failed = 0;

void ok(bool cond, const char* name) {
  if (cond) {
    ++g_passed;
  } else {
    ++g_failed;
    std::fprintf(stderr, "FAIL: %s\n", name);
  }
}

void eqStr(const std::string& got, const std::string& want, const char* name) {
  if (got == want) {
    ++g_passed;
  } else {
    ++g_failed;
    std::fprintf(stderr, "FAIL: %s — got \"%s\" want \"%s\"\n", name,
                 got.c_str(), want.c_str());
  }
}

// Reads the whole file at `path` into a string, or "" (and sets ok=false).
std::string readFile(const std::string& path, bool* okFlag) {
  std::ifstream f(path, std::ios::binary);
  if (!f) {
    *okFlag = false;
    return "";
  }
  std::ostringstream ss;
  ss << f.rdbuf();
  *okFlag = true;
  return ss.str();
}

// One row of the 13-root registry: the model root type, the generated static
// tree, and the ID-tree entry point resolved to its root ref.
struct RootRow {
  std::string type;
  const som::SomMetaTree* tree;
  som::SomMetaRef idRef;  // the section-id root accessor's ref
};

// Builds the registry of all 13 roots. The ID entry points return distinct
// struct types, so each is called explicitly and its `.ref` captured.
std::vector<RootRow> buildRows() {
  namespace m = tom_som_v0_meta;
  std::vector<RootRow> rows;
  rows.push_back({"D00SolutionBlueprint", &m::d00SolutionBlueprintMetaTree(),
                  m::d00SolutionBlueprintMetaId(m::d00SolutionBlueprintMetaTree())
                      .ref});
  rows.push_back(
      {"D01CurrentLandscapeAssessment",
       &m::d01CurrentLandscapeAssessmentMetaTree(),
       m::d01CurrentLandscapeAssessmentMetaId(
           m::d01CurrentLandscapeAssessmentMetaTree())
           .ref});
  rows.push_back(
      {"D02TargetOperatingModel", &m::d02TargetOperatingModelMetaTree(),
       m::d02TargetOperatingModelMetaId(m::d02TargetOperatingModelMetaTree())
           .ref});
  rows.push_back(
      {"D03InformationModel", &m::d03InformationModelMetaTree(),
       m::d03InformationModelMetaId(m::d03InformationModelMetaTree()).ref});
  rows.push_back(
      {"D04RequirementsSpecification",
       &m::d04RequirementsSpecificationMetaTree(),
       m::d04RequirementsSpecificationMetaId(
           m::d04RequirementsSpecificationMetaTree())
           .ref});
  rows.push_back(
      {"D05InteractionScenarios", &m::d05InteractionScenariosMetaTree(),
       m::d05InteractionScenariosMetaId(m::d05InteractionScenariosMetaTree())
           .ref});
  rows.push_back(
      {"D06ArchitectureTechnologySpecification",
       &m::d06ArchitectureTechnologySpecificationMetaTree(),
       m::d06ArchitectureTechnologySpecificationMetaId(
           m::d06ArchitectureTechnologySpecificationMetaTree())
           .ref});
  rows.push_back(
      {"D07IntegrationInterfaceSpecification",
       &m::d07IntegrationInterfaceSpecificationMetaTree(),
       m::d07IntegrationInterfaceSpecificationMetaId(
           m::d07IntegrationInterfaceSpecificationMetaTree())
           .ref});
  rows.push_back(
      {"D08SecurityAccessSpecification",
       &m::d08SecurityAccessSpecificationMetaTree(),
       m::d08SecurityAccessSpecificationMetaId(
           m::d08SecurityAccessSpecificationMetaTree())
           .ref});
  rows.push_back(
      {"D09ExperienceDesignSpecification",
       &m::d09ExperienceDesignSpecificationMetaTree(),
       m::d09ExperienceDesignSpecificationMetaId(
           m::d09ExperienceDesignSpecificationMetaTree())
           .ref});
  rows.push_back(
      {"D10QualityAcceptancePlan", &m::d10QualityAcceptancePlanMetaTree(),
       m::d10QualityAcceptancePlanMetaId(m::d10QualityAcceptancePlanMetaTree())
           .ref});
  rows.push_back(
      {"D11DeliveryRoadmap", &m::d11DeliveryRoadmapMetaTree(),
       m::d11DeliveryRoadmapMetaId(m::d11DeliveryRoadmapMetaTree()).ref});
  rows.push_back(
      {"D12TransitionRolloutPlan", &m::d12TransitionRolloutPlanMetaTree(),
       m::d12TransitionRolloutPlanMetaId(m::d12TransitionRolloutPlanMetaTree())
           .ref});
  return rows;
}

// GUARANTEE 1: every generated static tree is field-for-field identical to the
// bridge-built tree, and the 13 generated trees cover exactly the model roots.
void testTreesAgreeWithBridge() {
  bool readOk = false;
  std::string data = readFile("meta/spec_model.meta.json", &readOk);
  ok(readOk, "read meta/spec_model.meta.json");
  if (!readOk) return;

  std::string err;
  std::unique_ptr<som::SpecModel> model =
      som::SpecModel::fromJsonStr(data, &err);
  ok(model != nullptr, "parse spec model");
  if (model == nullptr) return;

  std::vector<RootRow> rows = buildRows();
  ok(model->roots.size() == rows.size(),
     "model root count matches generated tree count");

  for (const RootRow& row : rows) {
    std::string berr;
    std::unique_ptr<som::SomMetaTree> bridge =
        som::somBuildMetaTree(*model, row.type, &berr);
    if (bridge == nullptr) {
      ++g_failed;
      std::fprintf(stderr, "FAIL: somBuildMetaTree(%s): %s\n", row.type.c_str(),
                   berr.empty() ? "?" : berr.c_str());
      continue;
    }
    std::string diff =
        som::somMetaNodeDiff(*row.tree->root(), *bridge->root());
    if (!diff.empty()) {
      ++g_failed;
      std::fprintf(stderr,
                   "FAIL: generated tree for %s disagrees with bridge:\n%s\n",
                   row.type.c_str(), diff.c_str());
    } else {
      ++g_passed;
    }
  }

  // Every model root has a generated tree (same 13, by type).
  for (const som::SpecRoot& r : model->roots) {
    bool found = false;
    for (const RootRow& row : rows) {
      if (row.type == r.type) {
        found = true;
        break;
      }
    }
    ok(found, "model root has a generated tree");
  }
}

// GUARANTEE 2a: the dot-notation entry points resolve representative positions
// to the expected paths and to the same nodes the by-path lookups find.
void testDotNotationSurface() {
  namespace m = tom_som_v0_meta;
  const som::SomMetaTree& tree = m::d00SolutionBlueprintMetaTree();
  m::NavD00SolutionBlueprint root = m::d00SolutionBlueprintMetaNav(tree);
  eqStr(root.ref.path, "SBP", "dot root path");

  m::NavIntroductionAndScope intro =
      m::navD00SolutionBlueprint_introductionAndScope(root);
  eqStr(intro.ref.path, "SBP/introductionAndScope", "dot section path");

  m::NavRequirements req = m::navD00SolutionBlueprint_requirements(root);
  som::SomMetaRef reqContent = m::navRequirements_content(req);
  eqStr(reqContent.path, "SBP/requirements/content", "dot leaf path");

  m::NavGoals goals = m::navIntroductionAndScope_goals(intro);
  som::SomMetaRef goalsContent = m::navGoals_content(goals);
  eqStr(goalsContent.path, "SBP/introductionAndScope/goals/content",
        "dot nested-leaf path");

  // meta() resolves to the same node by-path finds.
  const som::SomMetaNode* viaDot = intro.ref.meta();
  const som::SomMetaNode* viaPath = tree.byPath("SBP/introductionAndScope");
  ok(viaDot == viaPath, "dot meta() == by-path node");
  ok(viaDot != nullptr && viaDot->memberName == "introductionAndScope",
     "dot node member name");

  // List positions expose item accessors and the section-id pattern.
  m::NavDocumentControl dc = m::navD00SolutionBlueprint_documentControl(root);
  som::SomListMetaRef revs = m::navDocumentControl_revisionHistory(dc);
  eqStr(revs.ref.path, "SBP/documentControl/RVHST-REVS-LST",
        "dot list path");

  void* item3 = revs.item(3);
  som::SomMetaRef* item3Ref =
      reinterpret_cast<som::SomMetaRef*>(item3);  // first member of any accessor
  eqStr(item3Ref->path,
        "SBP/documentControl/RVHST-REVS-LST-3",
        "dot list-item path");
  delete reinterpret_cast<m::NavRevisionEntry*>(item3);

  const som::SomMetaNode* revsNode = revs.ref.meta();
  ok(revsNode != nullptr && !revsNode->sectionIdPattern.empty(),
     "list node carries a section-id pattern");

  // A second root has its own entry point and segment, resolving to its own
  // tree root.
  const som::SomMetaTree& tree1 = m::d01CurrentLandscapeAssessmentMetaTree();
  m::NavD01CurrentLandscapeAssessment root1 =
      m::d01CurrentLandscapeAssessmentMetaNav(tree1);
  ok(root1.ref.path != "SBP", "second root does not share SBP");
  ok(root1.ref.meta() == tree1.root(), "second-root meta() == its tree root");
}

// GUARANTEE 2b: the ID-tree entry points agree with the dot-notation positions
// and each root's ID entry sits over its own tree root node.
void testIdTreeSurface() {
  namespace m = tom_som_v0_meta;
  const som::SomMetaTree& tree = m::d00SolutionBlueprintMetaTree();

  m::IdD00SolutionBlueprint sbp = m::d00SolutionBlueprintMetaId(tree);
  m::NavD00SolutionBlueprint dot = m::d00SolutionBlueprintMetaNav(tree);
  eqStr(sbp.ref.path, dot.ref.path, "ID root path == dot root path");
  ok(sbp.ref.meta() == dot.ref.meta(), "ID root meta() == dot root meta()");

  // The hoisted list id agrees with the dot-notation position.
  m::NavDocumentControl dc = m::navD00SolutionBlueprint_documentControl(dot);
  som::SomListMetaRef dotRevs = m::navDocumentControl_revisionHistory(dc);
  som::SomListMetaRef idRevs = m::idD00SolutionBlueprint_RVHST_REVS_LST(sbp);
  eqStr(idRevs.ref.path, dotRevs.ref.path, "hoisted id path == dot list path");
  ok(idRevs.ref.meta() == dotRevs.ref.meta(),
     "hoisted id meta() == dot list meta()");

  void* idItem0 = idRevs.item(0);
  void* dotItem0 = dotRevs.item(0);
  eqStr(reinterpret_cast<som::SomMetaRef*>(idItem0)->path,
        reinterpret_cast<som::SomMetaRef*>(dotItem0)->path,
        "hoisted item0 path == dot item0 path");
  delete reinterpret_cast<m::NavRevisionEntry*>(idItem0);
  delete reinterpret_cast<m::NavRevisionEntry*>(dotItem0);

  // Every root has a distinct ID entry point resolving to its own tree root.
  std::vector<RootRow> rows = buildRows();
  for (const RootRow& row : rows) {
    ok(row.idRef.meta() == row.tree->root(), "ID root meta() == its tree root");
  }
}

}  // namespace

int main() {
  try {
    testTreesAgreeWithBridge();
    testDotNotationSurface();
    testIdTreeSurface();
  } catch (const std::exception& e) {
    std::fprintf(stderr, "\nEXCEPTION: %s\n", e.what());
    return 1;
  }

  if (g_failed != 0) {
    std::fprintf(stderr, "\n%d checks FAILED (%d passed)\n", g_failed, g_passed);
    return 1;
  }
  std::printf("OK: %d checks passed\n", g_passed);
  return 0;
}
