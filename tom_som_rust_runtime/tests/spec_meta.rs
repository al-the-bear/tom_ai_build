//! Metadata-core tests — a port of
//! `tom_som_go_runtime/tests/spec_meta_test.go` (itself a port of
//! `tom_som_typescript_runtime/tests/spec_meta_test.ts` /
//! `tom_som_javascript_runtime/tests/spec_meta_test.js` /
//! `tom_som_python_runtime/tests/spec_meta_test.py` /
//! `tom_som_dart_runtime/test/spec_meta_test.dart`).
//!
//! Hand-built SOM §7.1 fixture tree mirroring the design doc's demo document
//! (acceptance: "the runtime compiles with a hand-built fixture tree").
//!
//! Structure:
//!
//! ```text
//! DEMO D99DemoDocument                      (@Document)
//!   INSC introductionAndScope               (section, class-level id)
//!     summary                               (content, no id)
//!     GOAL goals                            (section)
//!       GOAL-ITEM-LST entries               (list of GoalEntry, pattern)
//!         [element GoalEntry]
//!           text                            (content)
//!           subTasks                        (nested list of TaskEntry)
//!             [element TaskEntry]  note     (content)
//!   DOCO documentControl                    (form)
//!   RISK primaryRisk / RISK fallbackRisk    (shared class, two positions)
//!   PHASE-2 phaseTwo                        (hyphen+digit section id)
//!   related                                 (recursive re-entry)
//!   OLD legacy                              (@Unused content)
//!   tags                                    (scalar list, no element node)
//! ```

use std::rc::Rc;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::spec_meta::{
    SomContentTypeMeta, SomDocMeta, SomFormFieldMeta, SomFormMeta, SomMetaExtra, SomMetaNode,
    SomMetaTree, SOM_META_KIND_COMPLEX, SOM_META_KIND_CONTENT,
    SOM_META_KIND_ENUM_VALUE, SOM_META_KIND_FORM, SOM_META_KIND_LIST, SOM_META_KIND_SCALAR,
    SOM_META_KIND_SECTION,
};

struct Checker {
    passed: usize,
    failed: Vec<String>,
}

impl Checker {
    fn new() -> Checker {
        Checker {
            passed: 0,
            failed: Vec::new(),
        }
    }

    fn check(&mut self, name: &str, cond: bool, detail: &str) {
        if cond {
            self.passed += 1;
        } else if detail.is_empty() {
            self.failed.push(name.to_string());
        } else {
            self.failed.push(format!("{}: {}", name, detail));
        }
    }

    fn finish(&self) {
        let total = self.passed + self.failed.len();
        if !self.failed.is_empty() {
            for f in &self.failed {
                eprintln!("  - {}", f);
            }
            panic!("FAIL: {}/{} checks failed", self.failed.len(), total);
        }
        println!("OK: {} checks passed", total);
    }
}

fn meta_fixture_tree() -> SomMetaTree {
    let element = Rc::new(SomMetaNode {
        class_name: "GoalEntry".to_string(),
        kind: SOM_META_KIND_SECTION.to_string(),
        type_name: "GoalEntry".to_string(),
        doc_comment: "One programme goal.".to_string(),
        children: vec![
            Rc::new(SomMetaNode {
                class_name: "GoalEntry".to_string(),
                member_name: "text".to_string(),
                kind: SOM_META_KIND_CONTENT.to_string(),
                type_name: "String".to_string(),
                serialization_order: Some(1),
                ..SomMetaNode::new()
            }),
            Rc::new(SomMetaNode {
                class_name: "GoalEntry".to_string(),
                member_name: "subTasks".to_string(),
                section_id_pattern: "GOAL-TASK-xxx".to_string(),
                kind: SOM_META_KIND_LIST.to_string(),
                type_name: "List<TaskEntry>".to_string(),
                serialization_order: Some(2),
                element_node: Some(Rc::new(SomMetaNode {
                    class_name: "TaskEntry".to_string(),
                    kind: SOM_META_KIND_SECTION.to_string(),
                    type_name: "TaskEntry".to_string(),
                    children: vec![Rc::new(SomMetaNode {
                        class_name: "TaskEntry".to_string(),
                        member_name: "note".to_string(),
                        kind: SOM_META_KIND_CONTENT.to_string(),
                        type_name: "String".to_string(),
                        ..SomMetaNode::new()
                    })],
                    ..SomMetaNode::new()
                })),
                ..SomMetaNode::new()
            }),
        ],
        ..SomMetaNode::new()
    });

    let risk = |member: &str| -> Rc<SomMetaNode> {
        Rc::new(SomMetaNode {
            class_name: "Risk".to_string(),
            member_name: member.to_string(),
            section_id: "RISK".to_string(),
            kind: SOM_META_KIND_COMPLEX.to_string(),
            type_name: "Risk".to_string(),
            class_doc_comment: "A programme risk.".to_string(),
            children: vec![Rc::new(SomMetaNode {
                class_name: "Risk".to_string(),
                member_name: "probability".to_string(),
                kind: SOM_META_KIND_ENUM_VALUE.to_string(),
                type_name: "Probability".to_string(),
                ..SomMetaNode::new()
            })],
            ..SomMetaNode::new()
        })
    };

    let root = Rc::new(SomMetaNode {
        class_name: "D99DemoDocument".to_string(),
        section_id: "DEMO".to_string(),
        kind: SOM_META_KIND_SECTION.to_string(),
        type_name: "D99DemoDocument".to_string(),
        document: Some(SomDocMeta {
            name: "Demo Document".to_string(),
            description: "The demo specification document.".to_string(),
            based_on: vec!["D00SolutionBlueprint".to_string()],
        }),
        doc_comment: "Root of the demo document.".to_string(),
        children: vec![
            Rc::new(SomMetaNode {
                class_name: "IntroductionAndScope".to_string(),
                member_name: "introductionAndScope".to_string(),
                section_id: "INSC".to_string(),
                kind: SOM_META_KIND_SECTION.to_string(),
                type_name: "IntroductionAndScope".to_string(),
                serialization_order: Some(1),
                content_help: "Describe why the system exists.".to_string(),
                comment: "Keep this short.".to_string(),
                maps_to: "CurrentLandscape".to_string(),
                detailed_in: "D01RequirementsSpecification".to_string(),
                children: vec![
                    Rc::new(SomMetaNode {
                        class_name: "IntroductionAndScope".to_string(),
                        member_name: "summary".to_string(),
                        kind: SOM_META_KIND_CONTENT.to_string(),
                        type_name: "String".to_string(),
                        min: Some(1),
                        serialization_order: Some(1),
                        content_type: Some(SomContentTypeMeta {
                            type_: "diagram".to_string(),
                            description: "A mermaid context diagram.".to_string(),
                        }),
                        doc_comment: "What the system covers.".to_string(),
                        ..SomMetaNode::new()
                    }),
                    Rc::new(SomMetaNode {
                        class_name: "Goals".to_string(),
                        member_name: "goals".to_string(),
                        section_id: "GOAL".to_string(),
                        kind: SOM_META_KIND_SECTION.to_string(),
                        type_name: "Goals".to_string(),
                        serialization_order: Some(2),
                        children: vec![Rc::new(SomMetaNode {
                            class_name: "Goals".to_string(),
                            member_name: "entries".to_string(),
                            section_id: "GOAL-ITEM-LST".to_string(),
                            section_id_pattern: "GOAL-ITEM-xxx".to_string(),
                            kind: SOM_META_KIND_LIST.to_string(),
                            type_name: "List<GoalEntry>".to_string(),
                            min: Some(1),
                            extra: vec![SomMetaExtra {
                                annotation: "Max".to_string(),
                                args: vec![("count".to_string(), Json::Int(4))],
                            }],
                            element_node: Some(element),
                            ..SomMetaNode::new()
                        })],
                        ..SomMetaNode::new()
                    }),
                ],
                ..SomMetaNode::new()
            }),
            Rc::new(SomMetaNode {
                class_name: "DocumentControl".to_string(),
                member_name: "documentControl".to_string(),
                section_id: "DOCO".to_string(),
                kind: SOM_META_KIND_FORM.to_string(),
                type_name: "DocumentControl".to_string(),
                serialization_order: Some(2),
                form: Some(SomFormMeta {
                    fields: vec![
                        SomFormFieldMeta {
                            name: "version".to_string(),
                            type_name: "String".to_string(),
                            description: "Version".to_string(),
                            required: true,
                            hint: "e.g. 1.0".to_string(),
                            order: 1,
                            ..SomFormFieldMeta::default()
                        },
                        SomFormFieldMeta {
                            name: "approvedBy".to_string(),
                            type_name: "String".to_string(),
                            order: 2,
                            ..SomFormFieldMeta::default()
                        },
                        SomFormFieldMeta {
                            name: "reviewCount".to_string(),
                            type_name: "int".to_string(),
                            order: 3,
                            ..SomFormFieldMeta::default()
                        },
                    ],
                }),
                ..SomMetaNode::new()
            }),
            risk("primaryRisk"),
            risk("fallbackRisk"),
            Rc::new(SomMetaNode {
                class_name: "PhaseTwo".to_string(),
                member_name: "phaseTwo".to_string(),
                section_id: "PHASE-2".to_string(),
                kind: SOM_META_KIND_SECTION.to_string(),
                type_name: "PhaseTwo".to_string(),
                children: vec![Rc::new(SomMetaNode {
                    class_name: "PhaseTwo".to_string(),
                    member_name: "outline".to_string(),
                    kind: SOM_META_KIND_CONTENT.to_string(),
                    type_name: "String".to_string(),
                    ..SomMetaNode::new()
                })],
                ..SomMetaNode::new()
            }),
            Rc::new(SomMetaNode {
                class_name: "D99DemoDocument".to_string(),
                member_name: "related".to_string(),
                kind: SOM_META_KIND_COMPLEX.to_string(),
                type_name: "D99DemoDocument".to_string(),
                recursive: true,
                ..SomMetaNode::new()
            }),
            Rc::new(SomMetaNode {
                class_name: "D99DemoDocument".to_string(),
                member_name: "legacy".to_string(),
                section_id: "OLD".to_string(),
                kind: SOM_META_KIND_CONTENT.to_string(),
                type_name: "String".to_string(),
                unused: true,
                ..SomMetaNode::new()
            }),
            Rc::new(SomMetaNode {
                class_name: "D99DemoDocument".to_string(),
                member_name: "tags".to_string(),
                kind: SOM_META_KIND_LIST.to_string(),
                type_name: "List<String>".to_string(),
                ..SomMetaNode::new()
            }),
        ],
        ..SomMetaNode::new()
    });

    SomMetaTree::new(root).expect("fixture tree")
}

/// Returns a node's static path, `""` for element-subtree nodes — the
/// test-side stand-in for the other ports' nullable `path` getter.
fn meta_path_of(n: &SomMetaNode) -> String {
    n.path().expect("path")
}

fn meta_parent_of(n: &SomMetaNode) -> Option<Rc<SomMetaNode>> {
    n.parent().expect("parent")
}

fn same(a: &Rc<SomMetaNode>, b: &Rc<SomMetaNode>) -> bool {
    Rc::ptr_eq(a, b)
}

fn meta_test_wiring(c: &mut Checker) {
    let tree = meta_fixture_tree();

    // root path is the root segment and parent is null
    let root_path = meta_path_of(&tree.root);
    c.check("wiring.root.path", root_path == "DEMO", &root_path);
    c.check("wiring.root.segment", tree.root.segment() == "DEMO", "");
    c.check("wiring.root.parent", meta_parent_of(&tree.root).is_none(), "");
    let doc = tree.root.document.as_ref().expect("root document");
    c.check("wiring.root.doc.name", doc.name == "Demo Document", "");
    c.check(
        "wiring.root.doc.basedOn",
        doc.based_on == vec!["D00SolutionBlueprint".to_string()],
        "",
    );

    // child paths follow the SOM §8 grammar (sectionId ?? memberName)
    let insc = tree
        .root
        .child_by_member("introductionAndScope")
        .expect("insc");
    let insc_path = meta_path_of(insc);
    c.check("wiring.insc.path", insc_path == "DEMO/INSC", &insc_path);
    c.check(
        "wiring.summary.path",
        meta_path_of(insc.child_by_member("summary").expect("summary")) == "DEMO/INSC/summary",
        "",
    );
    let entries = insc
        .child_by_member("goals")
        .expect("goals")
        .child_by_member("entries")
        .expect("entries");
    let entries_path = meta_path_of(entries);
    c.check(
        "wiring.entries.path",
        entries_path == "DEMO/INSC/GOAL/GOAL-ITEM-LST",
        &entries_path,
    );

    // parent links are wired for children and element subtrees
    c.check(
        "wiring.entries.parent",
        meta_parent_of(entries).expect("entries parent").segment() == "GOAL",
        "",
    );
    let entries_element = entries.element_node.as_ref().expect("element");
    c.check(
        "wiring.element.parent",
        same(&meta_parent_of(entries_element).expect("element parent"), entries),
        "",
    );
    c.check(
        "wiring.element.child.parent",
        same(
            &meta_parent_of(&entries_element.children[0]).expect("element child parent"),
            entries_element,
        ),
        "",
    );

    // element subtree nodes carry no static path
    let entries2 = tree
        .by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST")
        .expect("entries2");
    let element = entries2.element_node.as_ref().expect("element node");
    c.check("wiring.element.path", meta_path_of(element).is_empty(), "");
    c.check(
        "wiring.element.text.path",
        meta_path_of(element.child_by_member("text").expect("text")).is_empty(),
        "",
    );
    c.check(
        "wiring.element.subTasks.path",
        meta_path_of(element.child_by_member("subTasks").expect("subTasks")).is_empty(),
        "",
    );

    // allNodes covers children and element subtrees in document order
    let names: Vec<String> = tree.all_nodes().iter().map(|n| n.debug_name()).collect();
    let index_of = |name: &str| -> i64 {
        names
            .iter()
            .position(|n| n == name)
            .map(|i| i as i64)
            .unwrap_or(-1)
    };
    c.check("wiring.allNodes.first", names[0] == "D99DemoDocument", &names[0]);
    c.check("wiring.allNodes.goalEntry", index_of("GoalEntry") >= 0, "");
    c.check("wiring.allNodes.taskNote", index_of("TaskEntry.note") >= 0, "");
    c.check(
        "wiring.allNodes.fallbackRisk",
        index_of("Risk.fallbackRisk") >= 0,
        "",
    );
    c.check(
        "wiring.allNodes.elementAfterList",
        index_of("GoalEntry") > index_of("Goals.entries"),
        "",
    );

    // a root without @Document metadata is rejected
    let err_no_doc = SomMetaTree::new(Rc::new(SomMetaNode {
        class_name: "X".to_string(),
        kind: SOM_META_KIND_SECTION.to_string(),
        type_name: "X".to_string(),
        ..SomMetaNode::new()
    }));
    c.check("wiring.noDocumentRejected", err_no_doc.is_err(), "");

    // a node belongs to exactly one tree
    let err_one_tree = SomMetaTree::new(Rc::clone(&tree.root));
    c.check("wiring.oneTreeRule", err_one_tree.is_err(), "");

    // an unattached node refuses path/parent access
    let loose = SomMetaNode {
        class_name: "X".to_string(),
        kind: SOM_META_KIND_SCALAR.to_string(),
        type_name: "int".to_string(),
        ..SomMetaNode::new()
    };
    c.check("wiring.loose.path", loose.path().is_err(), "");
    c.check("wiring.loose.parent", loose.parent().is_err(), "");
}

fn meta_test_metadata_slots(c: &mut Checker) {
    let tree = meta_fixture_tree();

    // section node carries help, comment and traceability links
    let insc = tree.by_id("INSC").expect("INSC");
    c.check(
        "slots.insc.help",
        insc.content_help == "Describe why the system exists.",
        "",
    );
    c.check("slots.insc.comment", insc.comment == "Keep this short.", "");
    c.check("slots.insc.mapsTo", insc.maps_to == "CurrentLandscape", "");
    c.check(
        "slots.insc.detailedIn",
        insc.detailed_in == "D01RequirementsSpecification",
        "",
    );
    c.check("slots.insc.order", insc.serialization_order == Some(1), "");

    // content node carries @Min, @ContentType and doc comment
    let summary = tree.by_path("DEMO/INSC/summary").expect("summary");
    c.check("slots.summary.kind", summary.kind == SOM_META_KIND_CONTENT, "");
    c.check("slots.summary.min", summary.min == Some(1), "");
    let ct = summary.content_type.as_ref().expect("content type");
    c.check("slots.summary.ct.type", ct.type_ == "diagram", "");
    c.check(
        "slots.summary.ct.desc",
        ct.description == "A mermaid context diagram.",
        "",
    );
    c.check(
        "slots.summary.doc",
        summary.doc_comment == "What the system covers.",
        "",
    );

    // form node exposes fields with description/required/hint/order
    let doco = tree.by_id("DOCO").expect("DOCO");
    let form = doco.form.as_ref().expect("form");
    let field_names: Vec<&str> = form.fields.iter().map(|f| f.name.as_str()).collect();
    c.check(
        "slots.form.fields",
        field_names == ["version", "approvedBy", "reviewCount"],
        "",
    );
    let version = form.field_named("version").expect("version field");
    c.check("slots.form.version.required", version.required, "");
    c.check("slots.form.version.hint", version.hint == "e.g. 1.0", "");
    c.check("slots.form.version.desc", version.description == "Version", "");
    c.check("slots.form.version.order", version.order == 1, "");
    c.check(
        "slots.form.approvedBy.required",
        !form.field_named("approvedBy").expect("approvedBy").required,
        "",
    );
    c.check("slots.form.missing", form.field_named("missing").is_none(), "");

    // list node carries @Min plus the lossless extra list (@Max)
    let entries = tree.by_id("GOAL-ITEM-LST").expect("entries");
    c.check("slots.entries.kind", entries.kind == SOM_META_KIND_LIST, "");
    c.check("slots.entries.min", entries.min == Some(1), "");
    c.check(
        "slots.entries.pattern",
        entries.section_id_pattern == "GOAL-ITEM-xxx",
        "",
    );
    c.check(
        "slots.entries.extra",
        entries.extra.len() == 1
            && entries.extra[0].annotation == "Max"
            && entries.extra[0].arg("count") == Some(&Json::Int(4)),
        "",
    );

    // @Unused and recursive flags are carried
    c.check("slots.old.unused", tree.by_id("OLD").expect("OLD").unused, "");
    let related = tree.root.child_by_member("related").expect("related");
    c.check("slots.related.recursive", related.recursive, "");
    c.check("slots.related.children", related.children.is_empty(), "");

    // class doc comment is carried where it differs from the member one
    c.check(
        "slots.risk.classDoc",
        tree.by_id("RISK").expect("RISK").class_doc_comment == "A programme risk.",
        "",
    );
}

fn meta_test_by_id(c: &mut Checker) {
    let tree = meta_fixture_tree();

    // resolves an exact section id
    c.check(
        "byId.demo",
        same(&tree.by_id("DEMO").expect("DEMO"), &tree.root),
        "",
    );
    c.check(
        "byId.goal",
        tree.by_id("GOAL").expect("GOAL").member_name == "goals",
        "",
    );

    // a shared class at two positions: first wins, allById has both
    c.check(
        "byId.risk.first",
        tree.by_id("RISK").expect("RISK").member_name == "primaryRisk",
        "",
    );
    let risk_members: Vec<&str> = tree
        .all_by_id("RISK")
        .iter()
        .map(|n| n.member_name.as_str())
        .collect();
    c.check(
        "byId.risk.all",
        risk_members == ["primaryRisk", "fallbackRisk"],
        "",
    );

    // a resolved @SectionIdPattern id resolves to the element subtree
    let element = tree.by_id("GOAL-ITEM-3").expect("GOAL-ITEM-3");
    c.check("byId.pattern.class", element.class_name == "GoalEntry", "");
    let entries_element = tree
        .by_id("GOAL-ITEM-LST")
        .expect("GOAL-ITEM-LST")
        .element_node
        .as_ref()
        .map(Rc::clone)
        .expect("element node");
    c.check("byId.pattern.element", same(&element, &entries_element), "");
    c.check(
        "byId.nestedPattern",
        tree.by_id("GOAL-TASK-12").expect("GOAL-TASK-12").class_name == "TaskEntry",
        "",
    );

    // unknown and non-matching ids return nil / empty
    c.check("byId.nope", tree.by_id("NOPE").is_none(), "");
    c.check("byId.dangling", tree.by_id("GOAL-ITEM-").is_none(), "");
    c.check("byId.nonNumeric", tree.by_id("GOAL-ITEM-x").is_none(), "");
    c.check("byId.allNope", tree.all_by_id("NOPE").is_empty(), "");
}

fn meta_test_by_path(c: &mut Checker) {
    let tree = meta_fixture_tree();

    // resolves the bare root and nested sections
    c.check(
        "byPath.root",
        same(&tree.by_path("DEMO").expect("DEMO"), &tree.root),
        "",
    );
    c.check(
        "byPath.insc",
        tree.by_path("DEMO/INSC").expect("insc").section_id == "INSC",
        "",
    );
    c.check(
        "byPath.goal",
        tree.by_path("DEMO/INSC/GOAL").expect("goal").member_name == "goals",
        "",
    );
    c.check(
        "byPath.doco",
        tree.by_path("DEMO/DOCO").expect("doco").kind == SOM_META_KIND_FORM,
        "",
    );

    // a list container resolves only as the final segment
    c.check(
        "byPath.list.final",
        tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST").expect("list").kind == SOM_META_KIND_LIST,
        "",
    );
    c.check(
        "byPath.list.notFinal",
        tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST/text").is_none(),
        "",
    );

    // a `-<seq>` item suffix descends into the element subtree
    let item = tree
        .by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-2")
        .expect("item");
    c.check("byPath.item.class", item.class_name == "GoalEntry", "");
    let text = tree
        .by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text")
        .expect("item text");
    c.check("byPath.item.text", text.kind == SOM_META_KIND_CONTENT, "");

    // nested lists inside an element subtree resolve dynamically
    let task = tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note");
    c.check(
        "byPath.nested",
        task.as_ref().is_some_and(|t| {
            t.class_name == "TaskEntry" && t.kind == SOM_META_KIND_CONTENT
        }),
        "",
    );

    // a hyphen+digit section id is not mis-read as a list item
    let phase = tree.by_path("DEMO/PHASE-2").expect("phase");
    c.check(
        "byPath.phase",
        phase.kind == SOM_META_KIND_SECTION && phase.member_name == "phaseTwo",
        "",
    );
    c.check(
        "byPath.phase.outline",
        tree.by_path("DEMO/PHASE-2/outline").expect("outline").kind == SOM_META_KIND_CONTENT,
        "",
    );

    // a scalar list item is a value leaf (resolves to the list node)
    c.check(
        "byPath.scalarItem",
        same(
            &tree.by_path("DEMO/tags-4").expect("tags-4"),
            &tree.by_path("DEMO/tags").expect("tags"),
        ),
        "",
    );
    c.check(
        "byPath.scalarItem.deeper",
        tree.by_path("DEMO/tags-4/deeper").is_none(),
        "",
    );

    // descending past a recursive re-entry terminates
    c.check(
        "byPath.recursive",
        tree.by_path("DEMO/related").expect("related").recursive,
        "",
    );
    c.check(
        "byPath.recursive.past",
        tree.by_path("DEMO/related/INSC").is_none(),
        "",
    );

    // dangling paths and foreign roots return nil
    c.check("byPath.empty", tree.by_path("").is_none(), "");
    c.check("byPath.other", tree.by_path("OTHER").is_none(), "");
    c.check("byPath.missing", tree.by_path("DEMO/missing").is_none(), "");
    c.check(
        "byPath.pastLeaf",
        tree.by_path("DEMO/INSC/summary/deeper").is_none(),
        "",
    );
    c.check(
        "byPath.itemMissing",
        tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing").is_none(),
        "",
    );

    // byId and byPath agree on the node they address (SOM §8)
    c.check(
        "agree.insc",
        same(
            &tree.by_id("INSC").expect("INSC"),
            &tree.by_path("DEMO/INSC").expect("insc path"),
        ),
        "",
    );
    c.check(
        "agree.list",
        same(
            &tree.by_id("GOAL-ITEM-LST").expect("list id"),
            &tree
                .by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST")
                .expect("list path"),
        ),
        "",
    );
    c.check(
        "agree.item",
        same(
            &tree.by_id("GOAL-ITEM-1").expect("item id"),
            &tree
                .by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-1")
                .expect("item path"),
        ),
        "",
    );
}

fn meta_test_item_path(c: &mut Checker) {
    let tree = meta_fixture_tree();

    // builds `<listPath>-<seq>` for a statically placed list
    let entries = tree.by_id("GOAL-ITEM-LST").expect("entries");
    let item_path_2 = entries.item_path(2);
    c.check(
        "itemPath.build",
        item_path_2.as_deref() == Ok("DEMO/INSC/GOAL/GOAL-ITEM-LST-2"),
        item_path_2.as_deref().unwrap_or(""),
    );
    c.check(
        "itemPath.resolves",
        tree.by_path("DEMO/INSC/GOAL/GOAL-ITEM-LST-2")
            .expect("item")
            .class_name
            == "GoalEntry",
        "",
    );

    // rejects non-list nodes and lists inside element subtrees
    c.check(
        "itemPath.nonList",
        tree.by_id("INSC").expect("INSC").item_path(1).is_err(),
        "",
    );
    let nested = tree
        .by_id("GOAL-ITEM-LST")
        .expect("entries")
        .element_node
        .as_ref()
        .map(Rc::clone)
        .expect("element node");
    let nested_sub_tasks = nested.child_by_member("subTasks").expect("subTasks");
    c.check("itemPath.nestedList", nested_sub_tasks.item_path(1).is_err(), "");
}

/// Runs the shared metadata-core suite (SOM §7) (87 checks).
#[test]
fn spec_meta() {
    let mut c = Checker::new();
    meta_test_wiring(&mut c);
    meta_test_metadata_slots(&mut c);
    meta_test_by_id(&mut c);
    meta_test_by_path(&mut c);
    meta_test_item_path(&mut c);
    c.finish();
}
