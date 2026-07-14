/* DR4 metadata-core tests — an idiomatic-C++ port of the C
 * `tom_som_c_runtime/tests/spec_meta_test.c` (itself a port of the Go / TS / JS
 * / Python / Dart suites).
 *
 * Hand-built DR1 §3.1 fixture tree mirroring the design doc's demo document
 * (DR4 acceptance: "the runtime compiles with a hand-built fixture tree").
 *
 * The C port's err-out accessors are throwing accessors here, so the three
 * negative wiring checks assert exceptions instead of NULL-out:
 *   - wiring.noDocumentRejected → SomMetaTree::create throws std::invalid_argument
 *   - wiring.loose.path/parent  → nodePath()/nodeParent() throw std::logic_error
 * The C `wiring.oneTreeRule` check cannot be expressed under unique_ptr
 * ownership (a tree owns its root; you cannot hand an already-owned root to a
 * second create) and is therefore dropped. Every other check name byte-matches
 * the C/Go suite.
 */
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

#include "som_json.hpp"
#include "spec_meta.hpp"

namespace {

int g_checks = 0;
int g_failures = 0;

void check(const char* name, bool cond, const std::string& detail = "") {
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

/* The @Max annotation's borrowed argument object, alive for the whole run. */
som::JsonRef g_maxArgs;

std::unique_ptr<som::SomMetaNode> mk(const char* cls, const char* member,
                                    const char* sid, const char* kind,
                                    const char* type) {
  auto n = std::make_unique<som::SomMetaNode>();
  n->className = cls;
  n->memberName = member;
  n->sectionId = sid;
  n->kind = kind;
  n->typeName = type;
  return n;
}

std::unique_ptr<som::SomMetaNode> fixtureRisk(const char* member) {
  using namespace som;
  auto n = mk("Risk", member, "RISK", kSomMetaKindComplex, "Risk");
  n->classDocComment = "A programme risk.";
  n->addChild(mk("Risk", "probability", "", kSomMetaKindEnumValue, "Probability"));
  return n;
}

std::unique_ptr<som::SomMetaTree> metaFixtureTree() {
  using namespace som;

  /* [element GoalEntry] text / subTasks([element TaskEntry] note) */
  auto element = mk("GoalEntry", "", "", kSomMetaKindSection, "GoalEntry");
  element->docComment = "One programme goal.";
  {
    auto text = mk("GoalEntry", "text", "", kSomMetaKindContent, "String");
    text->hasSerializationOrder = true;
    text->serializationOrder = 1;
    element->addChild(std::move(text));

    auto subTasks =
        mk("GoalEntry", "subTasks", "", kSomMetaKindList, "List<TaskEntry>");
    subTasks->sectionIdPattern = "GOAL-TASK-xxx";
    subTasks->hasSerializationOrder = true;
    subTasks->serializationOrder = 2;
    auto task = mk("TaskEntry", "", "", kSomMetaKindSection, "TaskEntry");
    task->addChild(mk("TaskEntry", "note", "", kSomMetaKindContent, "String"));
    subTasks->elementNode = std::move(task);
    element->addChild(std::move(subTasks));
  }

  auto root =
      mk("D99DemoDocument", "", "DEMO", kSomMetaKindSection, "D99DemoDocument");
  SomDocMeta doc;
  doc.name = "Demo Document";
  doc.description = "The demo specification document.";
  doc.basedOn.push_back("D00SolutionBlueprint");
  root->document = std::move(doc);
  root->docComment = "Root of the demo document.";

  /* INSC introductionAndScope */
  auto insc = mk("IntroductionAndScope", "introductionAndScope", "INSC",
                 kSomMetaKindSection, "IntroductionAndScope");
  insc->hasSerializationOrder = true;
  insc->serializationOrder = 1;
  insc->contentHelp = "Describe why the system exists.";
  insc->comment = "Keep this short.";
  insc->mapsTo = "CurrentLandscape";
  insc->detailedIn = "D01RequirementsSpecification";
  insc->secondLevelIds.push_back({"D01RequirementsSpecification", "RS-INSC"});
  {
    auto summary = mk("IntroductionAndScope", "summary", "", kSomMetaKindContent,
                      "String");
    summary->hasMin = true;
    summary->min = 1;
    summary->hasSerializationOrder = true;
    summary->serializationOrder = 1;
    SomContentTypeMeta ct;
    ct.type = "diagram";
    ct.description = "A mermaid context diagram.";
    summary->contentType = std::move(ct);
    summary->docComment = "What the system covers.";
    insc->addChild(std::move(summary));

    auto goals = mk("Goals", "goals", "GOAL", kSomMetaKindSection, "Goals");
    goals->hasSerializationOrder = true;
    goals->serializationOrder = 2;
    auto entries = mk("Goals", "entries", "GOAL-ITEM-LST", kSomMetaKindList,
                      "List<GoalEntry>");
    entries->sectionIdPattern = "GOAL-ITEM-xxx";
    entries->hasMin = true;
    entries->min = 1;
    SomMetaExtra ex;
    ex.annotation = "Max";
    ex.args = g_maxArgs;
    entries->extra.push_back(std::move(ex));
    entries->elementNode = std::move(element);
    goals->addChild(std::move(entries));
    insc->addChild(std::move(goals));
  }
  root->addChild(std::move(insc));

  /* DOCO documentControl (form) */
  {
    auto doco = mk("DocumentControl", "documentControl", "DOCO",
                   kSomMetaKindForm, "DocumentControl");
    doco->hasSerializationOrder = true;
    doco->serializationOrder = 2;
    SomFormMeta form;
    form.fields.push_back({"version", "String", "Version", true, "e.g. 1.0", 1});
    form.fields.push_back({"approvedBy", "String", "", false, "", 2});
    form.fields.push_back({"reviewCount", "int", "", false, "", 3});
    doco->form = std::move(form);
    root->addChild(std::move(doco));
  }

  root->addChild(fixtureRisk("primaryRisk"));
  root->addChild(fixtureRisk("fallbackRisk"));

  /* PHASE-2 phaseTwo */
  {
    auto phase =
        mk("PhaseTwo", "phaseTwo", "PHASE-2", kSomMetaKindSection, "PhaseTwo");
    phase->addChild(mk("PhaseTwo", "outline", "", kSomMetaKindContent, "String"));
    root->addChild(std::move(phase));
  }

  /* related (recursive re-entry) */
  {
    auto related = mk("D99DemoDocument", "related", "", kSomMetaKindComplex,
                      "D99DemoDocument");
    related->recursive = true;
    root->addChild(std::move(related));
  }

  /* OLD legacy (@Unused content) */
  {
    auto legacy =
        mk("D99DemoDocument", "legacy", "OLD", kSomMetaKindContent, "String");
    legacy->unused = true;
    root->addChild(std::move(legacy));
  }

  /* tags (scalar list, no element node) */
  root->addChild(
      mk("D99DemoDocument", "tags", "", kSomMetaKindList, "List<String>"));

  return som::SomMetaTree::create(std::move(root));
}

/* ---- suites -------------------------------------------------------------- */

void metaTestWiring() {
  using namespace som;
  auto tree = metaFixtureTree();

  check("wiring.root.path", tree->root()->nodePath() == "DEMO",
        tree->root()->nodePath());
  check("wiring.root.segment", tree->root()->segment() == "DEMO");
  check("wiring.root.parent", tree->root()->nodeParent() == nullptr);
  check("wiring.root.doc.name", tree->root()->document->name == "Demo Document");
  check("wiring.root.doc.basedOn",
        tree->root()->document->basedOn.size() == 1 &&
            tree->root()->document->basedOn[0] == "D00SolutionBlueprint");

  SomMetaNode* insc = tree->root()->childByMember("introductionAndScope");
  check("wiring.insc.path", insc->nodePath() == "DEMO/INSC", insc->nodePath());
  check("wiring.summary.path",
        insc->childByMember("summary")->nodePath() == "DEMO/INSC/summary");
  SomMetaNode* entries =
      insc->childByMember("goals")->childByMember("entries");
  check("wiring.entries.path",
        entries->nodePath() == "DEMO/INSC/GOAL/GOAL-ITEM-LST",
        entries->nodePath());

  check("wiring.entries.parent", entries->nodeParent()->segment() == "GOAL");
  check("wiring.element.parent",
        entries->elementNode->nodeParent() == entries);
  check("wiring.element.child.parent",
        entries->elementNode->children[0]->nodeParent() ==
            entries->elementNode.get());

  SomMetaNode* entries2 = tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST");
  SomMetaNode* element = entries2->elementNode.get();
  check("wiring.element.path", element->nodePath() == "");
  check("wiring.element.text.path",
        element->childByMember("text")->nodePath() == "");
  check("wiring.element.subTasks.path",
        element->childByMember("subTasks")->nodePath() == "");

  {
    const auto& nodes = tree->allNodes();
    long goalEntry = -1, taskNote = -1, fallback = -1, goalsEntries = -1;
    for (std::size_t i = 0; i < nodes.size(); ++i) {
      std::string name = nodes[i]->debugName();
      if (name == "GoalEntry" && goalEntry < 0) goalEntry = static_cast<long>(i);
      if (name == "TaskEntry.note" && taskNote < 0)
        taskNote = static_cast<long>(i);
      if (name == "Risk.fallbackRisk" && fallback < 0)
        fallback = static_cast<long>(i);
      if (name == "Goals.entries" && goalsEntries < 0)
        goalsEntries = static_cast<long>(i);
    }
    check("wiring.allNodes.first",
          !nodes.empty() && nodes[0]->debugName() == "D99DemoDocument",
          nodes.empty() ? "" : nodes[0]->debugName());
    check("wiring.allNodes.goalEntry", goalEntry >= 0);
    check("wiring.allNodes.taskNote", taskNote >= 0);
    check("wiring.allNodes.fallbackRisk", fallback >= 0);
    check("wiring.allNodes.elementAfterList", goalEntry > goalsEntries);
  }

  /* a root without @Document metadata is rejected */
  {
    auto noDoc = mk("X", "", "", kSomMetaKindSection, "X");
    bool threw = false;
    try {
      SomMetaTree::create(std::move(noDoc));
    } catch (const std::invalid_argument&) {
      threw = true;
    }
    check("wiring.noDocumentRejected", threw);
  }

  /* an unattached node refuses path/parent access */
  {
    auto loose = mk("X", "", "", kSomMetaKindScalar, "int");
    bool threwPath = false;
    try {
      loose->nodePath();
    } catch (const std::logic_error&) {
      threwPath = true;
    }
    check("wiring.loose.path", threwPath);
    bool threwParent = false;
    try {
      loose->nodeParent();
    } catch (const std::logic_error&) {
      threwParent = true;
    }
    check("wiring.loose.parent", threwParent);
  }
}

void metaTestMetadataSlots() {
  using namespace som;
  auto tree = metaFixtureTree();

  SomMetaNode* insc = tree->byId("INSC");
  check("slots.insc.help", insc->contentHelp == "Describe why the system exists.");
  check("slots.insc.comment", insc->comment == "Keep this short.");
  check("slots.insc.mapsTo", insc->mapsTo == "CurrentLandscape");
  check("slots.insc.detailedIn", insc->detailedIn == "D01RequirementsSpecification");
  check("slots.insc.secondLevel",
        insc->secondLevelIds.size() == 1 &&
            insc->secondLevelIds[0].documentClass ==
                "D01RequirementsSpecification" &&
            insc->secondLevelIds[0].id == "RS-INSC");
  check("slots.insc.order",
        insc->hasSerializationOrder && insc->serializationOrder == 1);

  SomMetaNode* summary = tree->byPath("DEMO/INSC/summary");
  check("slots.summary.kind", std::string(summary->kind) == kSomMetaKindContent);
  check("slots.summary.min", summary->hasMin && summary->min == 1);
  check("slots.summary.ct.type",
        summary->contentType.has_value() &&
            summary->contentType->type == "diagram");
  check("slots.summary.ct.desc",
        summary->contentType.has_value() &&
            summary->contentType->description == "A mermaid context diagram.");
  check("slots.summary.doc", summary->docComment == "What the system covers.");

  const SomFormMeta& form = *tree->byId("DOCO")->form;
  check("slots.form.fields",
        form.fields.size() == 3 && form.fields[0].name == "version" &&
            form.fields[1].name == "approvedBy" &&
            form.fields[2].name == "reviewCount");
  const SomFormFieldMeta* version = form.fieldNamed("version");
  check("slots.form.version.required", version != nullptr && version->required);
  check("slots.form.version.hint",
        version != nullptr && version->hint == "e.g. 1.0");
  check("slots.form.version.desc",
        version != nullptr && version->description == "Version");
  check("slots.form.version.order", version != nullptr && version->order == 1);
  const SomFormFieldMeta* approvedBy = form.fieldNamed("approvedBy");
  check("slots.form.approvedBy.required",
        approvedBy != nullptr && !approvedBy->required);
  check("slots.form.missing", form.fieldNamed("missing") == nullptr);

  SomMetaNode* entries = tree->byId("GOAL-ITEM-LST");
  check("slots.entries.kind", std::string(entries->kind) == kSomMetaKindList);
  check("slots.entries.min", entries->hasMin && entries->min == 1);
  check("slots.entries.pattern", entries->sectionIdPattern == "GOAL-ITEM-xxx");
  {
    auto count = entries->extra.size() == 1
                     ? jsonAsI64(jsonGet(entries->extra[0].args, "count"))
                     : std::nullopt;
    check("slots.entries.extra",
          entries->extra.size() == 1 && entries->extra[0].annotation == "Max" &&
              entries->extra[0].args != nullptr && count.has_value() &&
              *count == 4);
  }

  check("slots.old.unused", tree->byId("OLD")->unused);
  SomMetaNode* related = tree->root()->childByMember("related");
  check("slots.related.recursive", related->recursive);
  check("slots.related.children", related->children.empty());

  check("slots.risk.classDoc",
        tree->byId("RISK")->classDocComment == "A programme risk.");
}

void metaTestById() {
  using namespace som;
  auto tree = metaFixtureTree();

  check("byId.demo", tree->byId("DEMO") == tree->root());
  check("byId.goal", tree->byId("GOAL")->memberName == "goals");

  check("byId.risk.first", tree->byId("RISK")->memberName == "primaryRisk");
  {
    std::vector<SomMetaNode*> risks = tree->allById("RISK");
    check("byId.risk.all",
          risks.size() == 2 && risks[0]->memberName == "primaryRisk" &&
              risks[1]->memberName == "fallbackRisk");
  }

  SomMetaNode* element = tree->byId("GOAL-ITEM-3");
  check("byId.pattern.class",
        element != nullptr && element->className == "GoalEntry");
  check("byId.pattern.element",
        element == tree->byId("GOAL-ITEM-LST")->elementNode.get());
  {
    SomMetaNode* task = tree->byId("GOAL-TASK-12");
    check("byId.nestedPattern", task != nullptr && task->className == "TaskEntry");
  }

  check("byId.nope", tree->byId("NOPE") == nullptr);
  check("byId.dangling", tree->byId("GOAL-ITEM-") == nullptr);
  check("byId.nonNumeric", tree->byId("GOAL-ITEM-x") == nullptr);
  check("byId.allNope", tree->allById("NOPE").empty());
}

void metaTestByPath() {
  using namespace som;
  auto tree = metaFixtureTree();

  check("byPath.root", tree->byPath("DEMO") == tree->root());
  check("byPath.insc", tree->byPath("DEMO/INSC")->sectionId == "INSC");
  check("byPath.goal", tree->byPath("DEMO/INSC/GOAL")->memberName == "goals");
  check("byPath.doco",
        std::string(tree->byPath("DEMO/DOCO")->kind) == kSomMetaKindForm);

  check("byPath.list.final",
        std::string(tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST")->kind) ==
            kSomMetaKindList);
  check("byPath.list.notFinal",
        tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST/text") == nullptr);

  SomMetaNode* item = tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2");
  check("byPath.item.class", item != nullptr && item->className == "GoalEntry");
  SomMetaNode* text = tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text");
  check("byPath.item.text",
        text != nullptr && std::string(text->kind) == kSomMetaKindContent);

  {
    SomMetaNode* task =
        tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note");
    check("byPath.nested",
          task != nullptr && task->className == "TaskEntry" &&
              std::string(task->kind) == kSomMetaKindContent);
  }

  SomMetaNode* phase = tree->byPath("DEMO/PHASE-2");
  check("byPath.phase",
        phase != nullptr && std::string(phase->kind) == kSomMetaKindSection &&
            phase->memberName == "phaseTwo");
  check("byPath.phase.outline",
        std::string(tree->byPath("DEMO/PHASE-2/outline")->kind) ==
            kSomMetaKindContent);

  check("byPath.scalarItem",
        tree->byPath("DEMO/tags-4") == tree->byPath("DEMO/tags") &&
            tree->byPath("DEMO/tags") != nullptr);
  check("byPath.scalarItem.deeper", tree->byPath("DEMO/tags-4/deeper") == nullptr);

  check("byPath.recursive", tree->byPath("DEMO/related")->recursive);
  check("byPath.recursive.past", tree->byPath("DEMO/related/INSC") == nullptr);

  check("byPath.empty", tree->byPath("") == nullptr);
  check("byPath.other", tree->byPath("OTHER") == nullptr);
  check("byPath.missing", tree->byPath("DEMO/missing") == nullptr);
  check("byPath.pastLeaf", tree->byPath("DEMO/INSC/summary/deeper") == nullptr);
  check("byPath.itemMissing",
        tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing") == nullptr);

  check("agree.insc", tree->byId("INSC") == tree->byPath("DEMO/INSC"));
  check("agree.list",
        tree->byId("GOAL-ITEM-LST") ==
            tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST"));
  check("agree.item",
        tree->byId("GOAL-ITEM-1") ==
            tree->byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-1"));
}

void metaTestItemPath() {
  using namespace som;
  auto tree = metaFixtureTree();

  SomMetaNode* entries = tree->byId("GOAL-ITEM-LST");
  std::string itemPath2;
  bool built = true;
  try {
    itemPath2 = entries->itemPath(2);
  } catch (const std::logic_error&) {
    built = false;
  }
  check("itemPath.build",
        built && itemPath2 == "DEMO/INSC/GOAL/GOAL-ITEM-LST-2", itemPath2);
  {
    SomMetaNode* resolved = built ? tree->byPath(itemPath2) : nullptr;
    check("itemPath.resolves",
          resolved != nullptr && resolved->className == "GoalEntry");
  }

  {
    bool threw = false;
    try {
      tree->byId("INSC")->itemPath(1);
    } catch (const std::logic_error&) {
      threw = true;
    }
    check("itemPath.nonList", threw);
  }
  {
    SomMetaNode* nested =
        tree->byId("GOAL-ITEM-LST")->elementNode->childByMember("subTasks");
    bool threw = false;
    try {
      nested->itemPath(1);
    } catch (const std::logic_error&) {
      threw = true;
    }
    check("itemPath.nestedList", threw);
  }
}

}  // namespace

int main() {
  std::string err;
  som::JsonPtr maxArgs = som::jsonParse("{\"count\": 4}", &err);
  if (maxArgs == nullptr) {
    std::fprintf(stderr, "fatal: max args: %s\n", err.c_str());
    return 2;
  }
  g_maxArgs = maxArgs;

  metaTestWiring();
  metaTestMetadataSlots();
  metaTestById();
  metaTestByPath();
  metaTestItemPath();

  if (g_failures == 0) {
    std::printf("spec_meta_test: %d checks passed\n", g_checks);
    return 0;
  }
  std::fprintf(stderr, "spec_meta_test: %d/%d checks FAILED\n", g_failures,
               g_checks);
  return 1;
}
