// Agreement suite for the generated Rust metadata module
// (`src/meta.rs`, SOM §7.2/§8) — the Rust port of the Go facade's
// `som_v0_meta_test.go` (itself a port of the Dart facade's
// `test/generated_meta_test.dart`). Two guarantees over the *real* committed
// model:
//
//  1. EXHAUSTIVE TREE AGREEMENT — for every one of the document roots the
//     generated per-call SomMetaTree is field-for-field identical (via
//     som::som_meta_node_diff) to the tree som::build_som_meta_tree derives
//     from the committed `meta/spec_model.meta.json` at runtime. Since the
//     emitter writes the dot-notation / ID-tree accessor paths from the same
//     node walk, this also anchors every path the accessors can produce.
//  2. SURFACE AGREEMENT — the dot-notation entry points, the ID-tree entry
//     points, and the dynamic by_path lookups all resolve to the *same* node
//     instances for representative positions (root, nested section, content
//     leaf, list, list element, hoisted id).
//
// The root set comes from the generated `meta::som_meta_roots()` registry, not
// a hand-list: adding a document root cannot leave this suite behind. That does
// not make the coverage check circular — `meta/spec_model.meta.json` is written
// by the model JSON exporter, a different code path from the meta emitter, so
// an emitter that drops a root still shows up as a count mismatch.
//
// Run with `cargo test`. The runtime resolves through the `path` dependency in
// this crate's Cargo.toml, so the test is portable across checkouts.

use std::rc::Rc;

use tom_som_rust_runtime as som;
use tom_som_rust_v0::meta;

/// Parses the committed language-agnostic meta-data next to the generated
/// crate (the same file the bridge builds trees from at runtime).
fn load_model() -> som::SpecModel {
    let raw = std::fs::read_to_string("meta/spec_model.meta.json")
        .expect("read meta/spec_model.meta.json");
    som::SpecModel::from_json_str(&raw).expect("SpecModel::from_json_str")
}

fn same(a: &Rc<som::SomMetaNode>, b: &Rc<som::SomMetaNode>) -> bool {
    Rc::ptr_eq(a, b)
}

/// Proves exhaustive tree agreement: the generated trees cover exactly the
/// model's roots, and each is field-for-field identical to the bridge-built
/// tree.
#[test]
fn generated_trees_agree_with_bridge() {
    let model = load_model();
    let roots = meta::som_meta_roots();

    assert_eq!(
        model.roots.len(),
        roots.len(),
        "model has {} roots, generated registry has {}",
        model.roots.len(),
        roots.len()
    );
    for root in &model.roots {
        assert!(
            roots.iter().any(|e| e.type_name == root.type_),
            "model root {:?} has no generated tree",
            root.type_
        );
    }

    for entry in &roots {
        let tree = (entry.tree)();
        let bridge = som::build_som_meta_tree(&model, entry.type_name)
            .expect("build_som_meta_tree");
        let diff = som::som_meta_node_diff(&tree.root, &bridge.root);
        assert!(
            diff.is_empty(),
            "generated tree for {} disagrees with bridge:\n{}",
            entry.type_name,
            diff
        );
    }
}

/// Proves each registry entry describes itself consistently: both access roots
/// sit at the declared segment and both resolve to the entry's own tree root.
#[test]
fn registry_entries_are_self_consistent() {
    for entry in meta::som_meta_roots() {
        let tree = (entry.tree)();
        let nav = (entry.nav_ref)(&tree);
        let id = (entry.id_ref)(&tree);
        assert_eq!(
            nav.path, entry.segment,
            "{}: nav path != segment",
            entry.type_name
        );
        assert_eq!(
            id.path, entry.segment,
            "{}: id path != segment",
            entry.type_name
        );
        assert!(
            same(&nav.meta().expect("nav meta()"), &tree.root),
            "{}: nav meta() != tree root",
            entry.type_name
        );
        assert!(
            same(&id.meta().expect("id meta()"), &tree.root),
            "{}: id meta() != tree root",
            entry.type_name
        );
    }
}

/// Proves the dot-notation entry points (SOM §8) resolve representative
/// positions to the expected paths and to the same SomMetaNode instances the
/// dynamic by_path lookups find.
#[test]
fn dot_notation_surface() {
    let tree = meta::d00_solution_blueprint_meta_tree();
    let dot = meta::d00_solution_blueprint_meta(&tree);

    assert_eq!(dot.path(), "SBP", "dot root path");
    assert_eq!(
        dot.introduction_and_scope().path(),
        "SBP/introductionAndScope",
        "dot section path"
    );
    assert_eq!(
        dot.requirements().content().path,
        "SBP/requirements/content",
        "dot leaf path"
    );
    assert_eq!(
        dot.introduction_and_scope().goals().content().path,
        "SBP/introductionAndScope/goals/content",
        "dot nested-leaf path"
    );

    // meta() resolves to the same node by_path finds.
    let via_dot = dot
        .introduction_and_scope()
        .meta()
        .expect("IntroductionAndScope.meta()");
    let via_path = tree
        .by_path("SBP/introductionAndScope")
        .expect("by_path(SBP/introductionAndScope)");
    assert!(same(&via_dot, &via_path), "dot meta() != by_path node");
    assert_eq!(via_dot.member_name, "introductionAndScope", "member name");

    // List positions expose item() with element accessors.
    let revs = dot.document_control().revision_history();
    assert_eq!(
        revs.meta_ref.path, "SBP/documentControl/RVHST-REVS-LST",
        "dot list path"
    );
    assert_eq!(
        revs.item(3).path(),
        "SBP/documentControl/RVHST-REVS-LST-3",
        "dot list-item path"
    );
    // The list node's metadata carries the section-id pattern.
    let revs_node = revs.meta_ref.meta().expect("Revisions.meta()");
    assert!(
        !revs_node.section_id_pattern.is_empty(),
        "list node section_id_pattern is empty"
    );

    // A second root has its own entry point and segment.
    let tree01 = meta::d01_current_landscape_assessment_meta_tree();
    let dot01 = meta::d01_current_landscape_assessment_meta(&tree01);
    assert_ne!(dot01.path(), "SBP", "second root shares the SBP segment");
    assert!(
        same(
            &dot01.meta().expect("d01 dot meta()"),
            &tree01.root
        ),
        "second-root meta() != its tree root"
    );
}

/// Proves the ID-tree entry points (SOM §8) agree with the dot-notation
/// positions and that every root's ID entry point sits at its own section-id
/// segment over the same tree root node.
#[test]
fn id_tree_surface() {
    let tree = meta::d00_solution_blueprint_meta_tree();
    let dot = meta::d00_solution_blueprint_meta(&tree);
    let sbp = meta::SBP(&tree);

    // The ID root shares the dot root position.
    assert_eq!(sbp.path(), dot.path(), "SBP.path != dot root path");
    assert!(
        same(
            &sbp.meta().expect("SBP.meta()"),
            &dot.meta().expect("dot root meta()")
        ),
        "SBP.meta() != dot root meta()"
    );

    // A hoisted list id agrees with the dot-notation position: RVHST_REVS_LST
    // is hoisted onto the root ID type through the id-less documentControl /
    // revisionHistory members.
    let revs = dot.document_control().revision_history();
    let hoisted = sbp.RVHST_REVS_LST();
    assert_eq!(
        hoisted.meta_ref.path, revs.meta_ref.path,
        "hoisted path != dot path"
    );
    assert!(
        same(
            &hoisted.meta_ref.meta().expect("hoisted meta()"),
            &revs.meta_ref.meta().expect("revisions meta()")
        ),
        "hoisted meta() != dot meta()"
    );
    assert_eq!(
        hoisted.item(0).path(),
        revs.item(0).path(),
        "hoisted item(0) path != dot item(0) path"
    );

    // Every root has a distinct ID entry point at its own segment, resolving
    // to its generated tree's root node. The per-root Id types differ, so the
    // registry's `id_ref` adapter is what makes this a loop rather than an
    // unrolled block that a fifteenth root could be left out of.
    for entry in meta::som_meta_roots() {
        let t = (entry.tree)();
        let id = (entry.id_ref)(&t);
        assert_eq!(
            id.path, t.root.section_id,
            "{} id path = {:?}, want {:?}",
            entry.type_name, id.path, t.root.section_id
        );
        assert!(
            same(&id.meta().expect("id meta()"), &t.root),
            "{} id meta() != tree root",
            entry.type_name
        );
    }
}
