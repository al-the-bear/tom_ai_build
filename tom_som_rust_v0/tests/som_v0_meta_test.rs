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
// Run with `cargo test`. The runtime resolves through the `path` dependency in
// this crate's Cargo.toml, so the test is portable across checkouts.

use std::rc::Rc;

use tom_som_rust_runtime as som;
use tom_som_rust_v0::meta;

/// A generated per-root tree builder entry: the root type plus the per-call
/// `<root>_meta_tree()` constructor.
type TreeBuilder = (&'static str, fn() -> som::SomMetaTree);

/// Every generated per-root tree builder, keyed by root type — `SomMetaTree`
/// is `Rc`-based (no statics), so the suite constructs each tree per use.
fn generated_tree_builders() -> Vec<TreeBuilder> {
    vec![
        ("D00SolutionBlueprint", meta::d00_solution_blueprint_meta_tree),
        (
            "D01CurrentLandscapeAssessment",
            meta::d01_current_landscape_assessment_meta_tree,
        ),
        (
            "D02TargetOperatingModel",
            meta::d02_target_operating_model_meta_tree,
        ),
        ("D03InformationModel", meta::d03_information_model_meta_tree),
        (
            "D04RequirementsSpecification",
            meta::d04_requirements_specification_meta_tree,
        ),
        (
            "D05InteractionScenarios",
            meta::d05_interaction_scenarios_meta_tree,
        ),
        (
            "D06ArchitectureTechnologySpecification",
            meta::d06_architecture_technology_specification_meta_tree,
        ),
        (
            "D07IntegrationInterfaceSpecification",
            meta::d07_integration_interface_specification_meta_tree,
        ),
        (
            "D08SecurityAccessSpecification",
            meta::d08_security_access_specification_meta_tree,
        ),
        (
            "D09ExperienceDesignSpecification",
            meta::d09_experience_design_specification_meta_tree,
        ),
        (
            "D10QualityAcceptancePlan",
            meta::d10_quality_acceptance_plan_meta_tree,
        ),
        ("D11DeliveryRoadmap", meta::d11_delivery_roadmap_meta_tree),
        (
            "D12TransitionRolloutPlan",
            meta::d12_transition_rollout_plan_meta_tree,
        ),
        (
            "D13CodeSpecsProjection",
            meta::d13_code_specs_projection_meta_tree,
        ),
    ]
}

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
    let builders = generated_tree_builders();

    assert_eq!(
        model.roots.len(),
        builders.len(),
        "model has {} roots, generated list has {}",
        model.roots.len(),
        builders.len()
    );
    for root in &model.roots {
        assert!(
            builders.iter().any(|(t, _)| *t == root.type_),
            "model root {:?} has no generated tree",
            root.type_
        );
    }

    for (root_type, build) in builders {
        let tree = build();
        let bridge =
            som::build_som_meta_tree(&model, root_type).expect("build_som_meta_tree");
        let diff = som::som_meta_node_diff(&tree.root, &bridge.root);
        assert!(
            diff.is_empty(),
            "generated tree for {} disagrees with bridge:\n{}",
            root_type,
            diff
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

/// Asserts one root's ID entry point sits at its own section-id segment over
/// the same generated tree root node — the per-root body of the root loop.
fn assert_id_root(
    root_type: &str,
    tree: &som::SomMetaTree,
    id_path: &str,
    id_meta: Rc<som::SomMetaNode>,
) {
    assert_eq!(
        id_path, tree.root.section_id,
        "{} id path = {:?}, want {:?}",
        root_type, id_path, tree.root.section_id
    );
    assert!(
        same(&id_meta, &tree.root),
        "{} id meta() != tree root",
        root_type
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
    // to its generated tree's root node. (Each entry point returns its own
    // generated Id type, so the loop body is unrolled per root.)
    let t = meta::d00_solution_blueprint_meta_tree();
    let id = meta::SBP(&t);
    assert_id_root("D00SolutionBlueprint", &t, id.path(), id.meta().unwrap());

    let t = meta::d01_current_landscape_assessment_meta_tree();
    let id = meta::CLA(&t);
    assert_id_root(
        "D01CurrentLandscapeAssessment",
        &t,
        id.path(),
        id.meta().unwrap(),
    );

    let t = meta::d02_target_operating_model_meta_tree();
    let id = meta::TOM(&t);
    assert_id_root("D02TargetOperatingModel", &t, id.path(), id.meta().unwrap());

    let t = meta::d03_information_model_meta_tree();
    let id = meta::IFM(&t);
    assert_id_root("D03InformationModel", &t, id.path(), id.meta().unwrap());

    let t = meta::d04_requirements_specification_meta_tree();
    let id = meta::RSP(&t);
    assert_id_root(
        "D04RequirementsSpecification",
        &t,
        id.path(),
        id.meta().unwrap(),
    );

    let t = meta::d05_interaction_scenarios_meta_tree();
    let id = meta::ISC(&t);
    assert_id_root("D05InteractionScenarios", &t, id.path(), id.meta().unwrap());

    let t = meta::d06_architecture_technology_specification_meta_tree();
    let id = meta::ATS(&t);
    assert_id_root(
        "D06ArchitectureTechnologySpecification",
        &t,
        id.path(),
        id.meta().unwrap(),
    );

    let t = meta::d07_integration_interface_specification_meta_tree();
    let id = meta::IIS(&t);
    assert_id_root(
        "D07IntegrationInterfaceSpecification",
        &t,
        id.path(),
        id.meta().unwrap(),
    );

    let t = meta::d08_security_access_specification_meta_tree();
    let id = meta::SAS(&t);
    assert_id_root(
        "D08SecurityAccessSpecification",
        &t,
        id.path(),
        id.meta().unwrap(),
    );

    let t = meta::d09_experience_design_specification_meta_tree();
    let id = meta::XDS(&t);
    assert_id_root(
        "D09ExperienceDesignSpecification",
        &t,
        id.path(),
        id.meta().unwrap(),
    );

    let t = meta::d10_quality_acceptance_plan_meta_tree();
    let id = meta::QAP(&t);
    assert_id_root("D10QualityAcceptancePlan", &t, id.path(), id.meta().unwrap());

    let t = meta::d11_delivery_roadmap_meta_tree();
    let id = meta::DRM(&t);
    assert_id_root("D11DeliveryRoadmap", &t, id.path(), id.meta().unwrap());

    let t = meta::d12_transition_rollout_plan_meta_tree();
    let id = meta::TRP(&t);
    assert_id_root("D12TransitionRolloutPlan", &t, id.path(), id.meta().unwrap());

    let t = meta::d13_code_specs_projection_meta_tree();
    let id = meta::CGP(&t);
    assert_id_root("D13CodeSpecsProjection", &t, id.path(), id.meta().unwrap());
}
