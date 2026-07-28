import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import tom_som_runtime.SomContentTypeMeta;
import tom_som_runtime.SomDocMeta;
import tom_som_runtime.SomFormFieldMeta;
import tom_som_runtime.SomFormMeta;
import tom_som_runtime.SomMetaExtra;
import tom_som_runtime.SomMetaKind;
import tom_som_runtime.SomMetaNode;
import tom_som_runtime.SomMetaTree;

/**
 * Metadata-core tests — a port of
 * {@code tom_som_go_runtime/tests/spec_meta_test.go} (itself a port of
 * {@code spec_meta_test.ts} / {@code spec_meta_test.js} /
 * {@code spec_meta_test.py} / {@code spec_meta_test.dart}).
 *
 * <p>Hand-built SOM §7.1 fixture tree mirroring the design doc's demo document
 * (acceptance: "the runtime compiles with a hand-built fixture tree").
 *
 * <pre>
 * DEMO D99DemoDocument                      (@Document)
 *   INSC introductionAndScope               (section, class-level id)
 *     summary                               (content, no id)
 *     GOAL goals                            (section)
 *       GOAL-ITEM-LST entries               (list of GoalEntry, pattern)
 *         [element GoalEntry]
 *           text                            (content)
 *           subTasks                        (nested list of TaskEntry)
 *             [element TaskEntry]  note     (content)
 *   DOCO documentControl                    (form)
 *   RISK primaryRisk / RISK fallbackRisk    (shared class, two positions)
 *   PHASE-2 phaseTwo                        (hyphen+digit section id)
 *   related                                 (recursive re-entry)
 *   OLD legacy                              (@Unused content)
 *   tags                                    (scalar list, no element node)
 * </pre>
 *
 * <p>JUnit is unavailable on the build host, so this is a plain {@code main()}
 * that exits 0 on success and 1 on failure (same shape as SomFacadeTest).
 */
public final class SpecMetaTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  // --- fixture --------------------------------------------------------------

  private static SomMetaNode node(
      String className, String memberName, String kind, String typeName) {
    SomMetaNode n = new SomMetaNode(className, kind, typeName);
    n.memberName = memberName;
    return n;
  }

  private static SomMetaNode risk(String member) {
    SomMetaNode n = node("Risk", member, SomMetaKind.COMPLEX, "Risk");
    n.sectionId = "RISK";
    n.classDocComment = "A programme risk.";
    SomMetaNode probability =
        node("Risk", "probability", SomMetaKind.ENUM_VALUE, "Probability");
    n.children = List.of(probability);
    return n;
  }

  private static SomMetaTree metaFixtureTree() {
    SomMetaNode elementText = node("GoalEntry", "text", SomMetaKind.CONTENT, "String");
    elementText.serializationOrder = 1;

    SomMetaNode taskNote = node("TaskEntry", "note", SomMetaKind.CONTENT, "String");
    SomMetaNode taskEntry = node("TaskEntry", null, SomMetaKind.SECTION, "TaskEntry");
    taskEntry.children = List.of(taskNote);

    SomMetaNode subTasks =
        node("GoalEntry", "subTasks", SomMetaKind.LIST, "List<TaskEntry>");
    subTasks.sectionIdPattern = "GOAL-TASK-xxx";
    subTasks.serializationOrder = 2;
    subTasks.elementNode = taskEntry;

    SomMetaNode element = node("GoalEntry", null, SomMetaKind.SECTION, "GoalEntry");
    element.docComment = "One programme goal.";
    element.children = List.of(elementText, subTasks);

    SomMetaNode summary =
        node("IntroductionAndScope", "summary", SomMetaKind.CONTENT, "String");
    summary.min = 1;
    summary.serializationOrder = 1;
    summary.contentType = new SomContentTypeMeta("diagram", "A mermaid context diagram.");
    summary.docComment = "What the system covers.";

    SomMetaNode entries =
        node("Goals", "entries", SomMetaKind.LIST, "List<GoalEntry>");
    entries.sectionId = "GOAL-ITEM-LST";
    entries.sectionIdPattern = "GOAL-ITEM-xxx";
    entries.min = 1;
    entries.extra = List.of(new SomMetaExtra("Max", Map.of("count", 4)));
    entries.elementNode = element;

    SomMetaNode goals = node("Goals", "goals", SomMetaKind.SECTION, "Goals");
    goals.sectionId = "GOAL";
    goals.serializationOrder = 2;
    goals.children = List.of(entries);

    SomMetaNode insc =
        node(
            "IntroductionAndScope",
            "introductionAndScope",
            SomMetaKind.SECTION,
            "IntroductionAndScope");
    insc.sectionId = "INSC";
    insc.serializationOrder = 1;
    insc.contentHelp = "Describe why the system exists.";
    insc.comment = "Keep this short.";
    insc.mapsTo = "CurrentLandscape";
    insc.detailedIn = "D01RequirementsSpecification";
    insc.children = List.of(summary, goals);

    SomMetaNode doco =
        node("DocumentControl", "documentControl", SomMetaKind.FORM, "DocumentControl");
    doco.sectionId = "DOCO";
    doco.serializationOrder = 2;
    doco.form =
        new SomFormMeta(
            List.of(
                new SomFormFieldMeta("version", "String", "Version", true, "e.g. 1.0", 1),
                new SomFormFieldMeta("approvedBy", "String", null, false, null, 2),
                new SomFormFieldMeta("reviewCount", "int", null, false, null, 3)));

    SomMetaNode outline = node("PhaseTwo", "outline", SomMetaKind.CONTENT, "String");
    SomMetaNode phaseTwo = node("PhaseTwo", "phaseTwo", SomMetaKind.SECTION, "PhaseTwo");
    phaseTwo.sectionId = "PHASE-2";
    phaseTwo.children = List.of(outline);

    SomMetaNode related =
        node("D99DemoDocument", "related", SomMetaKind.COMPLEX, "D99DemoDocument");
    related.recursive = true;

    SomMetaNode legacy =
        node("D99DemoDocument", "legacy", SomMetaKind.CONTENT, "String");
    legacy.sectionId = "OLD";
    legacy.unused = true;

    SomMetaNode tags = node("D99DemoDocument", "tags", SomMetaKind.LIST, "List<String>");

    SomMetaNode root = node("D99DemoDocument", null, SomMetaKind.SECTION, "D99DemoDocument");
    root.sectionId = "DEMO";
    root.document =
        new SomDocMeta(
            "Demo Document",
            "The demo specification document.",
            List.of("D00SolutionBlueprint"));
    root.docComment = "Root of the demo document.";
    root.children =
        List.of(insc, doco, risk("primaryRisk"), risk("fallbackRisk"), phaseTwo, related,
            legacy, tags);
    return new SomMetaTree(root);
  }

  // --- helpers --------------------------------------------------------------

  private static String str(String s) {
    return s == null ? "null" : s;
  }

  private static boolean listEq(List<String> got, List<String> want) {
    return got.equals(want);
  }

  private static boolean pathThrows(SomMetaNode n) {
    try {
      n.path();
      return false;
    } catch (IllegalStateException e) {
      return true;
    }
  }

  private static boolean parentThrows(SomMetaNode n) {
    try {
      n.parent();
      return false;
    } catch (IllegalStateException e) {
      return true;
    }
  }

  private static boolean itemPathThrows(SomMetaNode n, int seq) {
    try {
      n.itemPath(seq);
      return false;
    } catch (IllegalStateException e) {
      return true;
    }
  }

  // --- sections ---------------------------------------------------------------

  private static void metaTestWiring() {
    SomMetaTree tree = metaFixtureTree();

    // root path is the root segment and parent is null
    check("wiring.root.path", "DEMO".equals(tree.root.path()), str(tree.root.path()));
    check("wiring.root.segment", "DEMO".equals(tree.root.segment()), "");
    check("wiring.root.parent", tree.root.parent() == null, "");
    check("wiring.root.doc.name", "Demo Document".equals(tree.root.document.name), "");
    check(
        "wiring.root.doc.basedOn",
        listEq(tree.root.document.basedOn, List.of("D00SolutionBlueprint")),
        "");

    // child paths follow the SOM §8 grammar (sectionId ?? memberName)
    SomMetaNode insc = tree.root.childByMember("introductionAndScope");
    check("wiring.insc.path", "DEMO/INSC".equals(insc.path()), str(insc.path()));
    check(
        "wiring.summary.path",
        "DEMO/INSC/summary".equals(insc.childByMember("summary").path()),
        "");
    SomMetaNode entries = insc.childByMember("goals").childByMember("entries");
    check(
        "wiring.entries.path",
        "DEMO/INSC/GOAL/GOAL-ITEM-LST".equals(entries.path()),
        str(entries.path()));

    // parent links are wired for children and element subtrees
    check("wiring.entries.parent", "GOAL".equals(entries.parent().segment()), "");
    check("wiring.element.parent", entries.elementNode.parent() == entries, "");
    check(
        "wiring.element.child.parent",
        entries.elementNode.children.get(0).parent() == entries.elementNode,
        "");

    // element subtree nodes carry no static path
    SomMetaNode entries2 = tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST");
    SomMetaNode element = entries2.elementNode;
    check("wiring.element.path", element.path() == null, "");
    check("wiring.element.text.path", element.childByMember("text").path() == null, "");
    check(
        "wiring.element.subTasks.path",
        element.childByMember("subTasks").path() == null,
        "");

    // allNodes covers children and element subtrees in document order
    List<SomMetaNode> all = tree.allNodes();
    List<String> names = new ArrayList<>(all.size());
    for (SomMetaNode n : all) {
      names.add(n.debugName());
    }
    check("wiring.allNodes.first", "D99DemoDocument".equals(names.get(0)), names.get(0));
    check("wiring.allNodes.goalEntry", names.indexOf("GoalEntry") >= 0, "");
    check("wiring.allNodes.taskNote", names.indexOf("TaskEntry.note") >= 0, "");
    check("wiring.allNodes.fallbackRisk", names.indexOf("Risk.fallbackRisk") >= 0, "");
    check(
        "wiring.allNodes.elementAfterList",
        names.indexOf("GoalEntry") > names.indexOf("Goals.entries"),
        "");

    // a root without @Document metadata is rejected
    boolean noDocRejected;
    try {
      new SomMetaTree(new SomMetaNode("X", SomMetaKind.SECTION, "X"));
      noDocRejected = false;
    } catch (IllegalStateException e) {
      noDocRejected = true;
    }
    check("wiring.noDocumentRejected", noDocRejected, "");

    // a node belongs to exactly one tree
    boolean oneTreeRule;
    try {
      new SomMetaTree(tree.root);
      oneTreeRule = false;
    } catch (IllegalStateException e) {
      oneTreeRule = true;
    }
    check("wiring.oneTreeRule", oneTreeRule, "");

    // an unattached node refuses path/parent access
    SomMetaNode loose = new SomMetaNode("X", SomMetaKind.SCALAR, "int");
    check("wiring.loose.path", pathThrows(loose), "");
    check("wiring.loose.parent", parentThrows(loose), "");
  }

  private static void metaTestMetadataSlots() {
    SomMetaTree tree = metaFixtureTree();

    // section node carries help, comment and traceability links
    SomMetaNode insc = tree.byId("INSC");
    check("slots.insc.help", "Describe why the system exists.".equals(insc.contentHelp), "");
    check("slots.insc.comment", "Keep this short.".equals(insc.comment), "");
    check("slots.insc.mapsTo", "CurrentLandscape".equals(insc.mapsTo), "");
    check(
        "slots.insc.detailedIn",
        "D01RequirementsSpecification".equals(insc.detailedIn),
        "");
    check(
        "slots.insc.order",
        insc.serializationOrder != null && insc.serializationOrder == 1,
        "");

    // content node carries @Min, @ContentType and doc comment
    SomMetaNode summary = tree.byPath("DEMO/INSC/summary");
    check("slots.summary.kind", SomMetaKind.CONTENT.equals(summary.kind), "");
    check("slots.summary.min", summary.min != null && summary.min == 1, "");
    check("slots.summary.ct.type", "diagram".equals(summary.contentType.type), "");
    check(
        "slots.summary.ct.desc",
        "A mermaid context diagram.".equals(summary.contentType.description),
        "");
    check("slots.summary.doc", "What the system covers.".equals(summary.docComment), "");

    // form node exposes fields with description/required/hint/order
    SomFormMeta form = tree.byId("DOCO").form;
    List<String> fieldNames = new ArrayList<>();
    for (SomFormFieldMeta f : form.fields) {
      fieldNames.add(f.name);
    }
    check(
        "slots.form.fields",
        listEq(fieldNames, List.of("version", "approvedBy", "reviewCount")),
        "");
    SomFormFieldMeta version = form.fieldNamed("version");
    check("slots.form.version.required", version.required, "");
    check("slots.form.version.hint", "e.g. 1.0".equals(version.hint), "");
    check("slots.form.version.desc", "Version".equals(version.description), "");
    check("slots.form.version.order", version.order == 1, "");
    check("slots.form.approvedBy.required", !form.fieldNamed("approvedBy").required, "");
    check("slots.form.missing", form.fieldNamed("missing") == null, "");

    // list node carries @Min plus the lossless extra list (@Max)
    SomMetaNode entries = tree.byId("GOAL-ITEM-LST");
    check("slots.entries.kind", SomMetaKind.LIST.equals(entries.kind), "");
    check("slots.entries.min", entries.min != null && entries.min == 1, "");
    check("slots.entries.pattern", "GOAL-ITEM-xxx".equals(entries.sectionIdPattern), "");
    check(
        "slots.entries.extra",
        entries.extra.size() == 1
            && "Max".equals(entries.extra.get(0).annotation)
            && entries.extra.get(0).args != null
            && Integer.valueOf(4).equals(entries.extra.get(0).args.get("count")),
        "");

    // @Unused and recursive flags are carried
    check("slots.old.unused", tree.byId("OLD").unused, "");
    SomMetaNode related = tree.root.childByMember("related");
    check("slots.related.recursive", related.recursive, "");
    check("slots.related.children", related.children.isEmpty(), "");

    // class doc comment is carried where it differs from the member one
    check(
        "slots.risk.classDoc",
        "A programme risk.".equals(tree.byId("RISK").classDocComment),
        "");
  }

  private static void metaTestById() {
    SomMetaTree tree = metaFixtureTree();

    // resolves an exact section id
    check("byId.demo", tree.byId("DEMO") == tree.root, "");
    check("byId.goal", "goals".equals(tree.byId("GOAL").memberName), "");

    // a shared class at two positions: first wins, allById has both
    check("byId.risk.first", "primaryRisk".equals(tree.byId("RISK").memberName), "");
    List<SomMetaNode> risks = tree.allById("RISK");
    List<String> riskMembers = new ArrayList<>();
    for (SomMetaNode n : risks) {
      riskMembers.add(n.memberName);
    }
    check("byId.risk.all", listEq(riskMembers, List.of("primaryRisk", "fallbackRisk")), "");

    // a resolved @SectionIdPattern id resolves to the element subtree
    SomMetaNode element = tree.byId("GOAL-ITEM-3");
    check("byId.pattern.class", "GoalEntry".equals(element.className), "");
    check(
        "byId.pattern.element",
        element == tree.byId("GOAL-ITEM-LST").elementNode,
        "");
    check("byId.nestedPattern", "TaskEntry".equals(tree.byId("GOAL-TASK-12").className), "");

    // unknown and non-matching ids return null / empty
    check("byId.nope", tree.byId("NOPE") == null, "");
    check("byId.dangling", tree.byId("GOAL-ITEM-") == null, "");
    check("byId.nonNumeric", tree.byId("GOAL-ITEM-x") == null, "");
    check("byId.allNope", tree.allById("NOPE").isEmpty(), "");
  }

  private static void metaTestByPath() {
    SomMetaTree tree = metaFixtureTree();

    // resolves the bare root and nested sections
    check("byPath.root", tree.byPath("DEMO") == tree.root, "");
    check("byPath.insc", "INSC".equals(tree.byPath("DEMO/INSC").sectionId), "");
    check("byPath.goal", "goals".equals(tree.byPath("DEMO/INSC/GOAL").memberName), "");
    check("byPath.doco", SomMetaKind.FORM.equals(tree.byPath("DEMO/DOCO").kind), "");

    // a list container resolves only as the final segment
    check(
        "byPath.list.final",
        SomMetaKind.LIST.equals(tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST").kind),
        "");
    check(
        "byPath.list.notFinal",
        tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST/text") == null,
        "");

    // a `-<seq>` item suffix descends into the element subtree
    SomMetaNode item = tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2");
    check("byPath.item.class", "GoalEntry".equals(item.className), "");
    SomMetaNode text = tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text");
    check("byPath.item.text", SomMetaKind.CONTENT.equals(text.kind), "");

    // nested lists inside an element subtree resolve dynamically
    SomMetaNode task = tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note");
    check(
        "byPath.nested",
        task != null
            && "TaskEntry".equals(task.className)
            && SomMetaKind.CONTENT.equals(task.kind),
        "");

    // a hyphen+digit section id is not mis-read as a list item
    SomMetaNode phase = tree.byPath("DEMO/PHASE-2");
    check(
        "byPath.phase",
        SomMetaKind.SECTION.equals(phase.kind) && "phaseTwo".equals(phase.memberName),
        "");
    check(
        "byPath.phase.outline",
        SomMetaKind.CONTENT.equals(tree.byPath("DEMO/PHASE-2/outline").kind),
        "");

    // a scalar list item is a value leaf (resolves to the list node)
    check("byPath.scalarItem", tree.byPath("DEMO/tags-4") == tree.byPath("DEMO/tags"), "");
    check("byPath.scalarItem.deeper", tree.byPath("DEMO/tags-4/deeper") == null, "");

    // descending past a recursive re-entry terminates
    check("byPath.recursive", tree.byPath("DEMO/related").recursive, "");
    check("byPath.recursive.past", tree.byPath("DEMO/related/INSC") == null, "");

    // dangling paths and foreign roots return null
    check("byPath.empty", tree.byPath("") == null, "");
    check("byPath.other", tree.byPath("OTHER") == null, "");
    check("byPath.missing", tree.byPath("DEMO/missing") == null, "");
    check("byPath.pastLeaf", tree.byPath("DEMO/INSC/summary/deeper") == null, "");
    check(
        "byPath.itemMissing",
        tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing") == null,
        "");

    // byId and byPath agree on the node they address (SOM §8)
    check("agree.insc", tree.byId("INSC") == tree.byPath("DEMO/INSC"), "");
    check(
        "agree.list",
        tree.byId("GOAL-ITEM-LST") == tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST"),
        "");
    check(
        "agree.item",
        tree.byId("GOAL-ITEM-1") == tree.byPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-1"),
        "");
  }

  private static void metaTestItemPath() {
    SomMetaTree tree = metaFixtureTree();

    // builds `<listPath>-<seq>` for a statically placed list
    SomMetaNode entries = tree.byId("GOAL-ITEM-LST");
    String itemPath2 = entries.itemPath(2);
    check(
        "itemPath.build",
        "DEMO/INSC/GOAL/GOAL-ITEM-LST-2".equals(itemPath2),
        str(itemPath2));
    check("itemPath.resolves", "GoalEntry".equals(tree.byPath(itemPath2).className), "");

    // rejects non-list nodes and lists inside element subtrees
    check("itemPath.nonList", itemPathThrows(tree.byId("INSC"), 1), "");
    SomMetaNode nested = tree.byId("GOAL-ITEM-LST").elementNode.childByMember("subTasks");
    check("itemPath.nestedList", itemPathThrows(nested, 1), "");
  }

  public static void main(String[] args) {
    metaTestWiring();
    metaTestMetadataSlots();
    metaTestById();
    metaTestByPath();
    metaTestItemPath();

    if (!failed.isEmpty()) {
      System.out.println("FAILED (" + failed.size() + " of " + (passed + failed.size()) + "):");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
    }
    System.out.println("OK: " + passed + " checks passed");
  }
}
