/* DR4 metadata-core tests — a port of the Go
 * `tom_som_go_runtime/tests/spec_meta_test.go` (itself a port of the
 * TypeScript / JavaScript / Python / Dart suites).
 *
 * Hand-built DR1 §3.1 fixture tree mirroring the design doc's demo document
 * (DR4 acceptance: "the runtime compiles with a hand-built fixture tree").
 *
 * Structure:
 *
 *   DEMO D99DemoDocument                      (@Document)
 *     INSC introductionAndScope               (section, class-level id)
 *       summary                               (content, no id)
 *       GOAL goals                            (section)
 *         GOAL-ITEM-LST entries               (list of GoalEntry, pattern)
 *           [element GoalEntry]
 *             text                            (content)
 *             subTasks                        (nested list of TaskEntry)
 *               [element TaskEntry]  note     (content)
 *     DOCO documentControl                    (form)
 *     RISK primaryRisk / RISK fallbackRisk    (shared class, two positions)
 *     PHASE-2 phaseTwo                        (hyphen+digit section id)
 *     related                                 (recursive re-entry)
 *     OLD legacy                              (@Unused content)
 *     tags                                    (scalar list, no element node)
 *
 * 87 checks; check names byte-match the Go suite. Exit status is the number
 * of failed checks (0 = green).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "spec_meta.h"
#include "som_json.h"
#include "som_util.h"

/* ---- checker ------------------------------------------------------------- */

static int g_checks = 0;
static int g_failures = 0;

static void check(const char *name, int cond, const char *detail) {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  if (detail != NULL && detail[0] != '\0')
    fprintf(stderr, "FAIL %s: %s\n", name, detail);
  else
    fprintf(stderr, "FAIL %s\n", name);
}

static void fatal(const char *what, char *err) {
  fprintf(stderr, "fatal: %s: %s\n", what, err != NULL ? err : "(no message)");
  free(err);
  exit(2);
}

static int str_eq(const char *a, const char *b) {
  return a != NULL && b != NULL && strcmp(a, b) == 0;
}

/* ---- fixture ------------------------------------------------------------- */

/* The @Max annotation's borrowed argument object, alive for the whole run. */
static SomJson *g_max_args = NULL;

static void set_str(char **slot, const char *v) {
  free(*slot);
  *slot = som_strdup(v);
}

/* Allocates a node with the five common fields set. Empty strings mean
 * "absent" (the fixture's stand-in for the Go zero values). */
static SomMetaNode *mk(const char *cls, const char *member, const char *sid,
                       const char *kind, const char *type) {
  SomMetaNode *n = som_meta_node_new();
  set_str(&n->class_name, cls);
  set_str(&n->member_name, member);
  set_str(&n->section_id, sid);
  n->kind = kind;
  set_str(&n->type_name, type);
  return n;
}

static void set_order(SomMetaNode *n, long long order) {
  n->has_serialization_order = 1;
  n->serialization_order = order;
}

static void set_min(SomMetaNode *n, long long min) {
  n->has_min = 1;
  n->min = min;
}

static SomMetaNode *fixture_risk(const char *member) {
  SomMetaNode *n = mk("Risk", member, "RISK", SOM_META_KIND_COMPLEX, "Risk");
  set_str(&n->class_doc_comment, "A programme risk.");
  som_meta_node_add_child(
      n, mk("Risk", "probability", "", SOM_META_KIND_ENUM_VALUE, "Probability"));
  return n;
}

static SomMetaTree *meta_fixture_tree(void) {
  /* [element GoalEntry] text / subTasks([element TaskEntry] note) */
  SomMetaNode *element =
      mk("GoalEntry", "", "", SOM_META_KIND_SECTION, "GoalEntry");
  set_str(&element->doc_comment, "One programme goal.");
  {
    SomMetaNode *text =
        mk("GoalEntry", "text", "", SOM_META_KIND_CONTENT, "String");
    set_order(text, 1);
    som_meta_node_add_child(element, text);

    SomMetaNode *sub_tasks =
        mk("GoalEntry", "subTasks", "", SOM_META_KIND_LIST, "List<TaskEntry>");
    set_str(&sub_tasks->section_id_pattern, "GOAL-TASK-xxx");
    set_order(sub_tasks, 2);
    SomMetaNode *task =
        mk("TaskEntry", "", "", SOM_META_KIND_SECTION, "TaskEntry");
    som_meta_node_add_child(
        task, mk("TaskEntry", "note", "", SOM_META_KIND_CONTENT, "String"));
    sub_tasks->element_node = task;
    som_meta_node_add_child(element, sub_tasks);
  }

  SomMetaNode *root =
      mk("D99DemoDocument", "", "DEMO", SOM_META_KIND_SECTION, "D99DemoDocument");
  root->document = (SomDocMeta *)calloc(1, sizeof(SomDocMeta));
  root->document->name = som_strdup("Demo Document");
  root->document->description = som_strdup("The demo specification document.");
  som_strlist_init(&root->document->based_on);
  som_strlist_push_copy(&root->document->based_on, "D00SolutionBlueprint");
  set_str(&root->doc_comment, "Root of the demo document.");

  /* INSC introductionAndScope */
  SomMetaNode *insc = mk("IntroductionAndScope", "introductionAndScope", "INSC",
                         SOM_META_KIND_SECTION, "IntroductionAndScope");
  set_order(insc, 1);
  set_str(&insc->content_help, "Describe why the system exists.");
  set_str(&insc->comment, "Keep this short.");
  set_str(&insc->maps_to, "CurrentLandscape");
  set_str(&insc->detailed_in, "D01RequirementsSpecification");
  insc->second_level_ids =
      (SomSecondLevelId *)calloc(1, sizeof(SomSecondLevelId));
  insc->second_level_ids_len = 1;
  insc->second_level_ids[0].document_class =
      som_strdup("D01RequirementsSpecification");
  insc->second_level_ids[0].id = som_strdup("RS-INSC");
  {
    SomMetaNode *summary = mk("IntroductionAndScope", "summary", "",
                              SOM_META_KIND_CONTENT, "String");
    set_min(summary, 1);
    set_order(summary, 1);
    summary->content_type =
        (SomContentTypeMeta *)calloc(1, sizeof(SomContentTypeMeta));
    summary->content_type->type = som_strdup("diagram");
    summary->content_type->description =
        som_strdup("A mermaid context diagram.");
    set_str(&summary->doc_comment, "What the system covers.");
    som_meta_node_add_child(insc, summary);

    SomMetaNode *goals =
        mk("Goals", "goals", "GOAL", SOM_META_KIND_SECTION, "Goals");
    set_order(goals, 2);
    SomMetaNode *entries = mk("Goals", "entries", "GOAL-ITEM-LST",
                              SOM_META_KIND_LIST, "List<GoalEntry>");
    set_str(&entries->section_id_pattern, "GOAL-ITEM-xxx");
    set_min(entries, 1);
    entries->extra = (SomMetaExtra *)calloc(1, sizeof(SomMetaExtra));
    entries->extra_len = 1;
    entries->extra[0].annotation = som_strdup("Max");
    entries->extra[0].args = g_max_args;
    entries->element_node = element;
    som_meta_node_add_child(goals, entries);
    som_meta_node_add_child(insc, goals);
  }
  som_meta_node_add_child(root, insc);

  /* DOCO documentControl (form) */
  {
    SomMetaNode *doco = mk("DocumentControl", "documentControl", "DOCO",
                           SOM_META_KIND_FORM, "DocumentControl");
    set_order(doco, 2);
    doco->form = (SomFormMeta *)calloc(1, sizeof(SomFormMeta));
    doco->form->fields =
        (SomFormFieldMeta *)calloc(3, sizeof(SomFormFieldMeta));
    doco->form->fields_len = 3;
    doco->form->fields[0].name = som_strdup("version");
    doco->form->fields[0].type_name = som_strdup("String");
    doco->form->fields[0].description = som_strdup("Version");
    doco->form->fields[0].required = 1;
    doco->form->fields[0].hint = som_strdup("e.g. 1.0");
    doco->form->fields[0].order = 1;
    doco->form->fields[1].name = som_strdup("approvedBy");
    doco->form->fields[1].type_name = som_strdup("String");
    doco->form->fields[1].description = som_strdup("");
    doco->form->fields[1].hint = som_strdup("");
    doco->form->fields[1].order = 2;
    doco->form->fields[2].name = som_strdup("reviewCount");
    doco->form->fields[2].type_name = som_strdup("int");
    doco->form->fields[2].description = som_strdup("");
    doco->form->fields[2].hint = som_strdup("");
    doco->form->fields[2].order = 3;
    som_meta_node_add_child(root, doco);
  }

  som_meta_node_add_child(root, fixture_risk("primaryRisk"));
  som_meta_node_add_child(root, fixture_risk("fallbackRisk"));

  /* PHASE-2 phaseTwo */
  {
    SomMetaNode *phase = mk("PhaseTwo", "phaseTwo", "PHASE-2",
                            SOM_META_KIND_SECTION, "PhaseTwo");
    som_meta_node_add_child(
        phase, mk("PhaseTwo", "outline", "", SOM_META_KIND_CONTENT, "String"));
    som_meta_node_add_child(root, phase);
  }

  /* related (recursive re-entry) */
  {
    SomMetaNode *related = mk("D99DemoDocument", "related", "",
                              SOM_META_KIND_COMPLEX, "D99DemoDocument");
    related->recursive = 1;
    som_meta_node_add_child(root, related);
  }

  /* OLD legacy (@Unused content) */
  {
    SomMetaNode *legacy = mk("D99DemoDocument", "legacy", "OLD",
                             SOM_META_KIND_CONTENT, "String");
    legacy->unused = 1;
    som_meta_node_add_child(root, legacy);
  }

  /* tags (scalar list, no element node) */
  som_meta_node_add_child(
      root, mk("D99DemoDocument", "tags", "", SOM_META_KIND_LIST, "List<String>"));

  char *err = NULL;
  SomMetaTree *tree = som_meta_tree_new(root, &err);
  if (tree == NULL) fatal("fixture tree", err);
  return tree;
}

/* metaPathOf / metaParentOf — the test-side stand-ins for the other ports'
 * nullable `path` getter; a wiring error on a fixture node is fatal. */
static const char *meta_path_of(const SomMetaNode *n) {
  const char *p = NULL;
  char *err = NULL;
  if (!som_meta_node_path(n, &p, &err)) fatal("path", err);
  return p;
}

static SomMetaNode *meta_parent_of(const SomMetaNode *n) {
  SomMetaNode *p = NULL;
  char *err = NULL;
  if (!som_meta_node_parent(n, &p, &err)) fatal("parent", err);
  return p;
}

/* ---- suites --------------------------------------------------------------- */

static void meta_test_wiring(void) {
  SomMetaTree *tree = meta_fixture_tree();

  /* root path is the root segment and parent is null */
  check("wiring.root.path", str_eq(meta_path_of(tree->root), "DEMO"),
        meta_path_of(tree->root));
  check("wiring.root.segment",
        str_eq(som_meta_node_segment(tree->root), "DEMO"), "");
  check("wiring.root.parent", meta_parent_of(tree->root) == NULL, "");
  check("wiring.root.doc.name",
        str_eq(tree->root->document->name, "Demo Document"), "");
  check("wiring.root.doc.basedOn",
        tree->root->document->based_on.len == 1 &&
            str_eq(tree->root->document->based_on.items[0],
                   "D00SolutionBlueprint"),
        "");

  /* child paths follow the §4 grammar (sectionId ?? memberName) */
  SomMetaNode *insc =
      som_meta_node_child_by_member(tree->root, "introductionAndScope");
  check("wiring.insc.path", str_eq(meta_path_of(insc), "DEMO/INSC"),
        meta_path_of(insc));
  check("wiring.summary.path",
        str_eq(meta_path_of(som_meta_node_child_by_member(insc, "summary")),
               "DEMO/INSC/summary"),
        "");
  SomMetaNode *entries = som_meta_node_child_by_member(
      som_meta_node_child_by_member(insc, "goals"), "entries");
  check("wiring.entries.path",
        str_eq(meta_path_of(entries), "DEMO/INSC/GOAL/GOAL-ITEM-LST"),
        meta_path_of(entries));

  /* parent links are wired for children and element subtrees */
  check("wiring.entries.parent",
        str_eq(som_meta_node_segment(meta_parent_of(entries)), "GOAL"), "");
  check("wiring.element.parent",
        meta_parent_of(entries->element_node) == entries, "");
  check("wiring.element.child.parent",
        meta_parent_of(entries->element_node->children[0]) ==
            entries->element_node,
        "");

  /* element subtree nodes carry no static path */
  SomMetaNode *entries2 =
      som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST");
  SomMetaNode *element = entries2->element_node;
  check("wiring.element.path", str_eq(meta_path_of(element), ""), "");
  check("wiring.element.text.path",
        str_eq(meta_path_of(som_meta_node_child_by_member(element, "text")), ""),
        "");
  check("wiring.element.subTasks.path",
        str_eq(meta_path_of(som_meta_node_child_by_member(element, "subTasks")),
               ""),
        "");

  /* allNodes covers children and element subtrees in document order */
  {
    size_t n = tree->all_nodes_len;
    char **names = (char **)calloc(n, sizeof(char *));
    for (size_t i = 0; i < n; ++i)
      names[i] = som_meta_node_debug_name(tree->all_nodes[i]);
    long goal_entry = -1, task_note = -1, fallback = -1, goals_entries = -1;
    for (size_t i = 0; i < n; ++i) {
      if (str_eq(names[i], "GoalEntry") && goal_entry < 0) goal_entry = (long)i;
      if (str_eq(names[i], "TaskEntry.note") && task_note < 0)
        task_note = (long)i;
      if (str_eq(names[i], "Risk.fallbackRisk") && fallback < 0)
        fallback = (long)i;
      if (str_eq(names[i], "Goals.entries") && goals_entries < 0)
        goals_entries = (long)i;
    }
    check("wiring.allNodes.first",
          n > 0 && str_eq(names[0], "D99DemoDocument"),
          n > 0 ? names[0] : "");
    check("wiring.allNodes.goalEntry", goal_entry >= 0, "");
    check("wiring.allNodes.taskNote", task_note >= 0, "");
    check("wiring.allNodes.fallbackRisk", fallback >= 0, "");
    check("wiring.allNodes.elementAfterList", goal_entry > goals_entries, "");
    for (size_t i = 0; i < n; ++i) free(names[i]);
    free(names);
  }

  /* a root without @Document metadata is rejected */
  {
    SomMetaNode *no_doc = mk("X", "", "", SOM_META_KIND_SECTION, "X");
    char *err_no_doc = NULL;
    SomMetaTree *t2 = som_meta_tree_new(no_doc, &err_no_doc);
    check("wiring.noDocumentRejected", t2 == NULL && err_no_doc != NULL, "");
    free(err_no_doc);
    if (t2 != NULL) som_meta_tree_free(t2);
    else som_meta_node_free(no_doc);
  }

  /* a node belongs to exactly one tree */
  {
    char *err_one_tree = NULL;
    SomMetaTree *t3 = som_meta_tree_new(tree->root, &err_one_tree);
    check("wiring.oneTreeRule", t3 == NULL && err_one_tree != NULL, "");
    free(err_one_tree);
    if (t3 != NULL) som_meta_tree_free(t3);
  }

  /* an unattached node refuses path/parent access */
  {
    SomMetaNode *loose = mk("X", "", "", SOM_META_KIND_SCALAR, "int");
    const char *p = NULL;
    char *err_path = NULL;
    int ok_path = som_meta_node_path(loose, &p, &err_path);
    check("wiring.loose.path", !ok_path && err_path != NULL, "");
    free(err_path);
    SomMetaNode *parent = NULL;
    char *err_parent = NULL;
    int ok_parent = som_meta_node_parent(loose, &parent, &err_parent);
    check("wiring.loose.parent", !ok_parent && err_parent != NULL, "");
    free(err_parent);
    som_meta_node_free(loose);
  }

  som_meta_tree_free(tree);
}

static void meta_test_metadata_slots(void) {
  SomMetaTree *tree = meta_fixture_tree();

  /* section node carries help, comment and traceability links */
  SomMetaNode *insc = som_meta_tree_by_id(tree, "INSC");
  check("slots.insc.help",
        str_eq(insc->content_help, "Describe why the system exists."), "");
  check("slots.insc.comment", str_eq(insc->comment, "Keep this short."), "");
  check("slots.insc.mapsTo", str_eq(insc->maps_to, "CurrentLandscape"), "");
  check("slots.insc.detailedIn",
        str_eq(insc->detailed_in, "D01RequirementsSpecification"), "");
  check("slots.insc.secondLevel",
        insc->second_level_ids_len == 1 &&
            str_eq(insc->second_level_ids[0].document_class,
                   "D01RequirementsSpecification") &&
            str_eq(insc->second_level_ids[0].id, "RS-INSC"),
        "");
  check("slots.insc.order",
        insc->has_serialization_order && insc->serialization_order == 1, "");

  /* content node carries @Min, @ContentType and doc comment */
  SomMetaNode *summary = som_meta_tree_by_path(tree, "DEMO/INSC/summary");
  check("slots.summary.kind", str_eq(summary->kind, SOM_META_KIND_CONTENT),
        "");
  check("slots.summary.min", summary->has_min && summary->min == 1, "");
  check("slots.summary.ct.type",
        summary->content_type != NULL &&
            str_eq(summary->content_type->type, "diagram"),
        "");
  check("slots.summary.ct.desc",
        summary->content_type != NULL &&
            str_eq(summary->content_type->description,
                   "A mermaid context diagram."),
        "");
  check("slots.summary.doc",
        str_eq(summary->doc_comment, "What the system covers."), "");

  /* form node exposes fields with description/required/hint/order */
  SomFormMeta *form = som_meta_tree_by_id(tree, "DOCO")->form;
  check("slots.form.fields",
        form != NULL && form->fields_len == 3 &&
            str_eq(form->fields[0].name, "version") &&
            str_eq(form->fields[1].name, "approvedBy") &&
            str_eq(form->fields[2].name, "reviewCount"),
        "");
  const SomFormFieldMeta *version = som_form_meta_field_named(form, "version");
  check("slots.form.version.required", version != NULL && version->required,
        "");
  check("slots.form.version.hint",
        version != NULL && str_eq(version->hint, "e.g. 1.0"), "");
  check("slots.form.version.desc",
        version != NULL && str_eq(version->description, "Version"), "");
  check("slots.form.version.order", version != NULL && version->order == 1, "");
  const SomFormFieldMeta *approved_by =
      som_form_meta_field_named(form, "approvedBy");
  check("slots.form.approvedBy.required",
        approved_by != NULL && approved_by->required == 0, "");
  check("slots.form.missing", som_form_meta_field_named(form, "missing") == NULL,
        "");

  /* list node carries @Min plus the lossless extra list (@Max) */
  SomMetaNode *entries = som_meta_tree_by_id(tree, "GOAL-ITEM-LST");
  check("slots.entries.kind", str_eq(entries->kind, SOM_META_KIND_LIST), "");
  check("slots.entries.min", entries->has_min && entries->min == 1, "");
  check("slots.entries.pattern",
        str_eq(entries->section_id_pattern, "GOAL-ITEM-xxx"), "");
  {
    long long count = 0;
    check("slots.entries.extra",
          entries->extra_len == 1 &&
              str_eq(entries->extra[0].annotation, "Max") &&
              entries->extra[0].args != NULL &&
              som_json_as_i64(som_json_get(entries->extra[0].args, "count"),
                              &count) &&
              count == 4,
          "");
  }

  /* @Unused and recursive flags are carried */
  check("slots.old.unused", som_meta_tree_by_id(tree, "OLD")->unused == 1, "");
  SomMetaNode *related = som_meta_node_child_by_member(tree->root, "related");
  check("slots.related.recursive", related->recursive == 1, "");
  check("slots.related.children", related->children_len == 0, "");

  /* class doc comment is carried where it differs from the member one */
  check("slots.risk.classDoc",
        str_eq(som_meta_tree_by_id(tree, "RISK")->class_doc_comment,
               "A programme risk."),
        "");

  som_meta_tree_free(tree);
}

static void meta_test_by_id(void) {
  SomMetaTree *tree = meta_fixture_tree();

  /* resolves an exact section id */
  check("byId.demo", som_meta_tree_by_id(tree, "DEMO") == tree->root, "");
  check("byId.goal",
        str_eq(som_meta_tree_by_id(tree, "GOAL")->member_name, "goals"), "");

  /* a shared class at two positions: first wins, allById has both */
  check("byId.risk.first",
        str_eq(som_meta_tree_by_id(tree, "RISK")->member_name, "primaryRisk"),
        "");
  {
    size_t len = 0;
    SomMetaNode **risks = som_meta_tree_all_by_id(tree, "RISK", &len);
    check("byId.risk.all",
          len == 2 && str_eq(risks[0]->member_name, "primaryRisk") &&
              str_eq(risks[1]->member_name, "fallbackRisk"),
          "");
    free(risks);
  }

  /* a resolved @SectionIdPattern id resolves to the element subtree */
  SomMetaNode *element = som_meta_tree_by_id(tree, "GOAL-ITEM-3");
  check("byId.pattern.class",
        element != NULL && str_eq(element->class_name, "GoalEntry"), "");
  check("byId.pattern.element",
        element == som_meta_tree_by_id(tree, "GOAL-ITEM-LST")->element_node,
        "");
  {
    SomMetaNode *task = som_meta_tree_by_id(tree, "GOAL-TASK-12");
    check("byId.nestedPattern",
          task != NULL && str_eq(task->class_name, "TaskEntry"), "");
  }

  /* unknown and non-matching ids return nil / empty */
  check("byId.nope", som_meta_tree_by_id(tree, "NOPE") == NULL, "");
  check("byId.dangling", som_meta_tree_by_id(tree, "GOAL-ITEM-") == NULL, "");
  check("byId.nonNumeric", som_meta_tree_by_id(tree, "GOAL-ITEM-x") == NULL,
        "");
  {
    size_t len = 123;
    SomMetaNode **none = som_meta_tree_all_by_id(tree, "NOPE", &len);
    check("byId.allNope", len == 0, "");
    free(none);
  }

  som_meta_tree_free(tree);
}

static void meta_test_by_path(void) {
  SomMetaTree *tree = meta_fixture_tree();

  /* resolves the bare root and nested sections */
  check("byPath.root", som_meta_tree_by_path(tree, "DEMO") == tree->root, "");
  check("byPath.insc",
        str_eq(som_meta_tree_by_path(tree, "DEMO/INSC")->section_id, "INSC"),
        "");
  check("byPath.goal",
        str_eq(som_meta_tree_by_path(tree, "DEMO/INSC/GOAL")->member_name,
               "goals"),
        "");
  check("byPath.doco",
        str_eq(som_meta_tree_by_path(tree, "DEMO/DOCO")->kind,
               SOM_META_KIND_FORM),
        "");

  /* a list container resolves only as the final segment */
  check("byPath.list.final",
        str_eq(som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST")->kind,
               SOM_META_KIND_LIST),
        "");
  check("byPath.list.notFinal",
        som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST/text") == NULL,
        "");

  /* a `-<seq>` item suffix descends into the element subtree */
  SomMetaNode *item =
      som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST-2");
  check("byPath.item.class",
        item != NULL && str_eq(item->class_name, "GoalEntry"), "");
  SomMetaNode *text =
      som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text");
  check("byPath.item.text",
        text != NULL && str_eq(text->kind, SOM_META_KIND_CONTENT), "");

  /* nested lists inside an element subtree resolve dynamically */
  {
    SomMetaNode *task = som_meta_tree_by_path(
        tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note");
    check("byPath.nested",
          task != NULL && str_eq(task->class_name, "TaskEntry") &&
              str_eq(task->kind, SOM_META_KIND_CONTENT),
          "");
  }

  /* a hyphen+digit section id is not mis-read as a list item */
  SomMetaNode *phase = som_meta_tree_by_path(tree, "DEMO/PHASE-2");
  check("byPath.phase",
        phase != NULL && str_eq(phase->kind, SOM_META_KIND_SECTION) &&
            str_eq(phase->member_name, "phaseTwo"),
        "");
  check("byPath.phase.outline",
        str_eq(som_meta_tree_by_path(tree, "DEMO/PHASE-2/outline")->kind,
               SOM_META_KIND_CONTENT),
        "");

  /* a scalar list item is a value leaf (resolves to the list node) */
  check("byPath.scalarItem",
        som_meta_tree_by_path(tree, "DEMO/tags-4") ==
                som_meta_tree_by_path(tree, "DEMO/tags") &&
            som_meta_tree_by_path(tree, "DEMO/tags") != NULL,
        "");
  check("byPath.scalarItem.deeper",
        som_meta_tree_by_path(tree, "DEMO/tags-4/deeper") == NULL, "");

  /* descending past a recursive re-entry terminates */
  check("byPath.recursive",
        som_meta_tree_by_path(tree, "DEMO/related")->recursive == 1, "");
  check("byPath.recursive.past",
        som_meta_tree_by_path(tree, "DEMO/related/INSC") == NULL, "");

  /* dangling paths and foreign roots return nil */
  check("byPath.empty", som_meta_tree_by_path(tree, "") == NULL, "");
  check("byPath.other", som_meta_tree_by_path(tree, "OTHER") == NULL, "");
  check("byPath.missing", som_meta_tree_by_path(tree, "DEMO/missing") == NULL,
        "");
  check("byPath.pastLeaf",
        som_meta_tree_by_path(tree, "DEMO/INSC/summary/deeper") == NULL, "");
  check("byPath.itemMissing",
        som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing") ==
            NULL,
        "");

  /* byId and byPath agree on the node they address (DR1 §4.2) */
  check("agree.insc",
        som_meta_tree_by_id(tree, "INSC") ==
            som_meta_tree_by_path(tree, "DEMO/INSC"),
        "");
  check("agree.list",
        som_meta_tree_by_id(tree, "GOAL-ITEM-LST") ==
            som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST"),
        "");
  check("agree.item",
        som_meta_tree_by_id(tree, "GOAL-ITEM-1") ==
            som_meta_tree_by_path(tree, "DEMO/INSC/GOAL/GOAL-ITEM-LST-1"),
        "");

  som_meta_tree_free(tree);
}

static void meta_test_item_path(void) {
  SomMetaTree *tree = meta_fixture_tree();

  /* builds `<listPath>-<seq>` for a statically placed list */
  SomMetaNode *entries = som_meta_tree_by_id(tree, "GOAL-ITEM-LST");
  char *err_item_path = NULL;
  char *item_path2 = som_meta_node_item_path(entries, 2, &err_item_path);
  check("itemPath.build",
        err_item_path == NULL && item_path2 != NULL &&
            str_eq(item_path2, "DEMO/INSC/GOAL/GOAL-ITEM-LST-2"),
        item_path2 != NULL ? item_path2 : "");
  free(err_item_path);
  {
    SomMetaNode *resolved =
        item_path2 != NULL ? som_meta_tree_by_path(tree, item_path2) : NULL;
    check("itemPath.resolves",
          resolved != NULL && str_eq(resolved->class_name, "GoalEntry"), "");
  }
  free(item_path2);

  /* rejects non-list nodes and lists inside element subtrees */
  {
    char *err_non_list = NULL;
    char *p = som_meta_node_item_path(som_meta_tree_by_id(tree, "INSC"), 1,
                                      &err_non_list);
    check("itemPath.nonList", p == NULL && err_non_list != NULL, "");
    free(err_non_list);
    free(p);
  }
  {
    SomMetaNode *nested = som_meta_node_child_by_member(
        som_meta_tree_by_id(tree, "GOAL-ITEM-LST")->element_node, "subTasks");
    char *err_nested = NULL;
    char *p = som_meta_node_item_path(nested, 1, &err_nested);
    check("itemPath.nestedList", p == NULL && err_nested != NULL, "");
    free(err_nested);
    free(p);
  }

  som_meta_tree_free(tree);
}

int main(void) {
  char *json_err = NULL;
  g_max_args = som_json_parse("{\"count\": 4}", &json_err);
  if (g_max_args == NULL) fatal("max args", json_err);

  meta_test_wiring();
  meta_test_metadata_slots();
  meta_test_by_id();
  meta_test_by_path();
  meta_test_item_path();

  som_json_free(g_max_args);

  if (g_failures == 0) {
    printf("spec_meta_test: %d checks passed\n", g_checks);
  } else {
    fprintf(stderr, "spec_meta_test: %d/%d checks FAILED\n", g_failures,
            g_checks);
  }
  return g_failures;
}
