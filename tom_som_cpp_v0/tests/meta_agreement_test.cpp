// Agreement suite for the generated C++ metadata module
// (`tom_som_cpp_v0_meta.hpp/.cpp`, SOM §7.2/§8) — the C++ port of the C facade's
// `meta_agreement_test.c` (itself the port of the Go `som_v0_meta_test.go` /
// Dart `generated_meta_test.dart`). Two guarantees over the *real* committed
// model:
//
//   1. EXHAUSTIVE TREE AGREEMENT — for every one of the document roots the
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
// The root set comes from the generated `somMetaRoots()` registry, not a
// hand-list: adding a document root cannot leave this suite behind. That does
// not make the coverage check circular — `meta/spec_model.meta.json` is written
// by the model JSON exporter, a different code path from the meta emitter, so
// an emitter that drops a root still shows up as a count mismatch.
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

// GUARANTEE 1: every generated static tree is field-for-field identical to the
// bridge-built tree, and the generated trees cover exactly the model roots.
void testTreesAgreeWithBridge() {
  namespace m = tom_som_v0_meta;
  bool readOk = false;
  std::string data = readFile("meta/spec_model.meta.json", &readOk);
  ok(readOk, "read meta/spec_model.meta.json");
  if (!readOk) return;

  std::string err;
  std::unique_ptr<som::SpecModel> model =
      som::SpecModel::fromJsonStr(data, &err);
  ok(model != nullptr, "parse spec model");
  if (model == nullptr) return;

  std::vector<m::SomMetaRootEntry> rows = m::somMetaRoots();
  ok(model->roots.size() == rows.size(),
     "model root count matches generated tree count");

  for (const m::SomMetaRootEntry& row : rows) {
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

  // Every model root has a generated tree (same set, by type).
  for (const som::SpecRoot& r : model->roots) {
    bool found = false;
    for (const m::SomMetaRootEntry& row : rows) {
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
  eqStr(revs.ref.path, "SBP/documentControl/RVENT-REVS-LST",
        "dot list path");

  void* item3 = revs.item(3);
  som::SomMetaRef* item3Ref =
      reinterpret_cast<som::SomMetaRef*>(item3);  // first member of any accessor
  eqStr(item3Ref->path,
        "SBP/documentControl/RVENT-REVS-LST-3",
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
  som::SomListMetaRef idRevs = m::idD00SolutionBlueprint_RVENT_REVS_LST(sbp);
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

  // Every root has a distinct ID entry point at its own section-id segment,
  // resolving to its own tree root. The per-root Id types differ, so the
  // generated registry's common-typed `id` is what makes this a loop rather
  // than an unrolled block a fifteenth root could be left out of.
  for (const m::SomMetaRootEntry& row : m::somMetaRoots()) {
    eqStr(row.id.path, row.tree->root()->sectionId,
          "ID root path == its tree root section id");
    ok(row.id.meta() == row.tree->root(), "ID root meta() == its tree root");
  }
}

// Each registry entry describes itself consistently: both access roots sit at
// the declared segment and both resolve to the entry's own tree root.
void testRegistryEntriesAreSelfConsistent() {
  namespace m = tom_som_v0_meta;
  for (const m::SomMetaRootEntry& row : m::somMetaRoots()) {
    eqStr(row.nav.path, row.segment, "registry nav path == segment");
    eqStr(row.id.path, row.segment, "registry id path == segment");
    ok(row.nav.meta() == row.tree->root(), "registry nav meta() == tree root");
    ok(row.id.meta() == row.tree->root(), "registry id meta() == tree root");
  }
}

}  // namespace

int main() {
  try {
    testTreesAgreeWithBridge();
    testRegistryEntriesAreSelfConsistent();
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
