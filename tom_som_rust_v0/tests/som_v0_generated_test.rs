// Behavioural test for the **actually-committed** generated Rust typed model.
//
// Unlike the emitter's golden test (which compiles the small emitter fixture),
// this suite exercises the real, full `tom_som_rust_v0` crate (3000+ types)
// against the generic `tom_som_rust_runtime` and proves the typed facade is a
// faithful editing surface over the shared document (SOM §6):
//
//   - the `D00SolutionBlueprint` root is anchored at the `PD` segment;
//   - a content leaf round-trips typed → generic and generic → typed;
//   - a nested complex section derives its path under the root;
//   - the typed `SomList` collection maps onto the generic list store;
//   - the generated model-version accessor / constant return `1.0`;
//   - the instantiation-time version check (SOM §4.2) accepts an editable stamp and
//     rejects a newer-minor / cross-major stamp with a `SomVersionError`.
//
// Run with `cargo test`. The runtime resolves through the `path` dev-dependency
// in this crate's Cargo.toml, so the test is portable across checkouts.

use tom_som_rust_runtime as som;
use tom_som_rust_v0::{
    meta, CurrentOperationalMetric, D00SolutionBlueprint, D00_SOLUTION_BLUEPRINT_MODEL_VERSION,
};

/// A fresh `DocRef` over an empty document.
fn new_doc() -> som::DocRef {
    som::doc_ref(som::SpecDocument::new())
}

#[test]
fn root_and_parity() {
    let doc = new_doc();
    let pd = D00SolutionBlueprint::new(doc.clone(), "").expect("new D00SolutionBlueprint");

    assert_eq!(pd.node.path(), "SBP", "root segment");

    // Typed write → generic read.
    pd.set_content("A clear vision");
    assert_eq!(doc.borrow().content_or("SBP/content"), "A clear vision");

    // Generic write → typed read.
    doc.borrow_mut().set_content("SBP/content", "Revised vision");
    assert_eq!(pd.content(), "Revised vision");

    // Unset leaf reads as empty string.
    let fresh = D00SolutionBlueprint::new(new_doc(), "").unwrap();
    assert_eq!(fresh.content(), "");

    // Nested complex section path derivation (camelCase accessor preserved as
    // the stored segment).
    let csa = pd.current_landscape();
    assert_eq!(csa.node.path(), "SBP/currentLandscape");

    // A generic value under the nested typed node is addressable via the
    // expected literal path (typed path == generic path).
    let probe = format!("{}/probe", csa.node.path());
    doc.borrow_mut().set_content(&probe, "x");
    assert_eq!(doc.borrow().content_or("SBP/currentLandscape/probe"), "x");
}

#[test]
fn typed_list() {
    let doc = new_doc();
    let pd = D00SolutionBlueprint::new(doc.clone(), "").unwrap();
    let metrics = pd.current_landscape().operational_metrics();

    metrics
        .add()
        .set_content("Average order turnaround: 4.2 days.");
    metrics
        .add()
        .set_content("Manual reconciliation: ~12 hours / week.");

    assert_eq!(metrics.length(), 2, "list length");
    assert_eq!(
        metrics.at(0).content(),
        "Average order turnaround: 4.2 days."
    );

    // Typed list writes land in the generic list store under the same path.
    let list_path = "SBP/currentLandscape/CUOPME-OPER-LST";
    assert_eq!(doc.borrow().list_item_count(list_path), 2);
}

/// A fresh `operationalMetrics` list — a `@SectionIdPattern` list
/// (`CUOPME-OPER-xxx`) over an empty document — for the section-id scenarios.
fn fresh_metrics() -> som::SomList<CurrentOperationalMetric> {
    let pd = D00SolutionBlueprint::new(new_doc(), "").unwrap();
    pd.current_landscape().operational_metrics()
}

/// Proves the generated typed facade drives section-id generation (AA1
/// criteria 3–6) end-to-end: deterministic ids via `add_on`, override with
/// uniqueness validation, and the delete/renumber rules. March 5 → the
/// two-letter day code "CE" (C = month 3, E = day 5).
#[test]
fn section_ids() {
    const MAR: i64 = 3;
    const DAY: i64 = 5;

    // Generation: consecutive same-day items number CE1, CE2 (criteria 3–4).
    let metrics = fresh_metrics();
    assert_eq!(metrics.add_on(MAR, DAY).node.section_id(), "CUOPME-OPER-CE1");
    assert_eq!(metrics.add_on(MAR, DAY).node.section_id(), "CUOPME-OPER-CE2");

    // Override to an arbitrary suffix, then a duplicate override raises a
    // collision (criterion 5).
    let metrics = fresh_metrics();
    metrics.add_on(MAR, DAY); // CE1
    let second = metrics.add_on(MAR, DAY);
    second
        .node
        .set_section_id("CUOPME-OPER-ZZ9")
        .expect("override should succeed");
    assert!(
        metrics.section_ids().contains(&"CUOPME-OPER-ZZ9".to_string()),
        "override not applied: {:?}",
        metrics.section_ids()
    );
    assert!(
        matches!(
            metrics.at(0).node.set_section_id("CUOPME-OPER-ZZ9"),
            Err(ref e) if som::is_collision(e)
        ),
        "override collision expected"
    );
    // An explicit add with a duplicate id raises the same collision.
    assert!(
        matches!(
            metrics.add_with_id("CUOPME-OPER-ZZ9"),
            Err(ref e) if som::is_collision(e)
        ),
        "add collision expected"
    );

    // Delete a middle item: the remaining ids never renumber, and a new
    // same-day item takes the next free number (criterion 6).
    let metrics = fresh_metrics();
    metrics.add_on(MAR, DAY); // CE1
    metrics.add_on(MAR, DAY); // CE2
    metrics.add_on(MAR, DAY); // CE3
    metrics.remove_at(1); // drop CE2
    assert_eq!(
        metrics.section_ids(),
        vec!["CUOPME-OPER-CE1".to_string(), "CUOPME-OPER-CE3".to_string()]
    );
    assert_eq!(metrics.add_on(MAR, DAY).node.section_id(), "CUOPME-OPER-CE4");

    // Delete the last item: a new same-day item reuses the just-freed number
    // (criterion 6).
    let metrics = fresh_metrics();
    metrics.add_on(MAR, DAY); // CE1
    metrics.add_on(MAR, DAY); // CE2
    metrics.add_on(MAR, DAY); // CE3
    metrics.remove_at(2); // drop CE3 (the max)
    assert_eq!(metrics.add_on(MAR, DAY).node.section_id(), "CUOPME-OPER-CE3");
}

#[test]
fn model_version() {
    assert_eq!(D00_SOLUTION_BLUEPRINT_MODEL_VERSION, "1.0");
    let pd = D00SolutionBlueprint::new(new_doc(), "").unwrap();
    assert_eq!(pd.object_model_version(), "1.0");
}

#[test]
fn version_check() {
    // New / equal-stamp document → accepted.
    assert!(D00SolutionBlueprint::new(new_doc(), "").is_ok(), "empty stamp");
    assert!(D00SolutionBlueprint::new(new_doc(), "1.0").is_ok(), "equal stamp");

    // Newer minor → rejected with a SomVersionError.
    assert!(
        D00SolutionBlueprint::new(new_doc(), "1.1").is_err(),
        "newer-minor stamp must be rejected"
    );

    // Different major → rejected with a SomVersionError.
    assert!(
        D00SolutionBlueprint::new(new_doc(), "2.0").is_err(),
        "cross-major stamp must be rejected"
    );
}

// --- aligned absence semantics (SOM §21) ----------------------------------

/// A section is empty (subtree-empty) until any value is written under it, and
/// becomes empty again once cleared. Emptiness tracks the whole subtree, not a
/// single leaf.
#[test]
fn section_is_empty_until_written() {
    let doc = new_doc();
    let sbp = D00SolutionBlueprint::new(doc, "").unwrap();

    assert!(sbp.requirements().node.is_empty(), "fresh section is empty");
    // A nested content value fills the section (subtree emptiness).
    sbp.requirements().set_content("Some requirements");
    assert!(
        !sbp.requirements().node.is_empty(),
        "written section is not empty"
    );
    // Clearing it empties the section again.
    sbp.requirements().set_content("");
    assert!(
        sbp.requirements().node.is_empty(),
        "cleared section is empty again"
    );
}

/// The typed `is_empty` mirrors the generic `has_values_under` for the section
/// path, both before and after a generic write beneath it.
#[test]
fn typed_is_empty_matches_generic_has_values_under() {
    let doc = new_doc();
    let sbp = D00SolutionBlueprint::new(doc.clone(), "").unwrap();
    let path = sbp.requirements().node.path().to_string();

    assert_eq!(
        sbp.requirements().node.is_empty(),
        !doc.borrow().has_values_under(&path),
        "before write: is_empty == !has_values_under"
    );
    doc.borrow_mut()
        .set_content(&format!("{}/content", path), "x");
    assert_eq!(
        sbp.requirements().node.is_empty(),
        !doc.borrow().has_values_under(&path),
        "after write: is_empty == !has_values_under"
    );
    assert!(
        !sbp.requirements().node.is_empty(),
        "section is not empty after write"
    );
}

/// The generic `has_content` on the content leaf gives the same yes/no answer
/// as the typed `.content()` string (empty → false, non-empty → true).
#[test]
fn has_content_matches_typed_content() {
    let doc = new_doc();
    let sbp = D00SolutionBlueprint::new(doc.clone(), "").unwrap();
    let leaf = format!("{}/content", sbp.requirements().node.path());

    // Typed '' and generic has_content(false) agree the leaf is empty.
    assert_eq!(sbp.requirements().content(), "");
    assert!(!doc.borrow().has_content(&leaf), "empty leaf has no content");

    sbp.requirements().set_content("Filled");
    assert_eq!(
        !sbp.requirements().content().is_empty(),
        doc.borrow().has_content(&leaf)
    );
    assert!(doc.borrow().has_content(&leaf), "filled leaf has content");
}

// --- structural content predicate (SOM §21) ------------------------------

/// `can_have_content` is a **structural / schema** predicate baked onto every
/// generated section type as a literal boolean: `true` for a type carrying the
/// standard `content` text leaf. It never probes the document — it describes
/// the model, not the data.
///
/// Since `tom_specs_model_rules.md` §10.2 requires `content: String?` on every
/// section class, every generated Rust section type emits `true`. Rust has no
/// base node default and `SomScalar` carries no `can_have_content` accessor, so
/// — unlike the seven base-default languages — the v0 facade has no node on
/// which the predicate reads `false`. The `false` branch survives only in the
/// emitter (see `som_rust_emitter.dart`) and is exercised by the runtime's own
/// hand-written fixtures; here the assertions pin the `true` side, which is
/// what §10.2 makes universal.
#[test]
fn can_have_content_is_type_structural() {
    let sbp = D00SolutionBlueprint::new(new_doc(), "").unwrap();

    // The root carries a `content` leaf → content-bearing.
    assert!(sbp.can_have_content(), "root is content-bearing");

    // `Goals` carries a `content` leaf → content-bearing.
    assert!(
        sbp.introduction_and_scope().goals().can_have_content(),
        "Goals is content-bearing"
    );

    // Every section type reports `true`, including a pure container:
    // `SystemsToReplace` holds two child sections and no fields of its own, yet
    // it still declares `content` (its `@ContentHelp` asks the author to
    // introduce the replacement portfolio). Pins §10.2's universal-content rule
    // at the generated facade — red the day a section class without `content`
    // is reintroduced.
    assert!(
        sbp.introduction_and_scope()
            .systems_to_replace()
            .can_have_content(),
        "a pure container is still a section, so it declares `content` too"
    );

    // A `@Unused()` on the `content` member does not lower the answer.
    // `DocumentControl` carries it — one of the ten in the model. That is an
    // *authoring* statement ("no prose is expected here",
    // `tom_specs_model_rules.md` §5.6), not a claim that the slot is absent, so
    // the *capability* answer stays `true` and the slot stays writable. Pins
    // SOM §21: `can_have_content` never consults the annotation, and no second
    // predicate exists for the authoring question — a consumer reads the
    // content node's `unused` flag in the metadata.
    let control = sbp.document_control();
    assert!(
        control.can_have_content(),
        "`@Unused` says no prose is expected, not that the slot is absent"
    );
    control.set_content("Prose is possible even where it is not expected.");
    assert_eq!(
        control.content(),
        "Prose is possible even where it is not expected.",
        "the `@Unused` content slot stays writable"
    );
    assert!(
        control.can_have_content(),
        "still true after a write to a `@Unused` content slot"
    );
}

/// Structural, not stateful: writing or clearing the `content` leaf never moves
/// `can_have_content` (contrast the state predicates `has_content` / `is_empty`,
/// which do track the data).
#[test]
fn can_have_content_ignores_document_state() {
    let doc = new_doc();
    let sbp = D00SolutionBlueprint::new(doc.clone(), "").unwrap();

    assert!(sbp.introduction_and_scope().goals().can_have_content());
    sbp.introduction_and_scope()
        .goals()
        .set_content("some goals prose");
    assert!(
        sbp.introduction_and_scope().goals().can_have_content(),
        "still true after a write"
    );
    sbp.introduction_and_scope().goals().set_content("");
    assert!(
        sbp.introduction_and_scope().goals().can_have_content(),
        "still true after a clear"
    );
}

// --- one-call loading (SOM §21) -------------------------------------------

/// The shared conformance sample, resolved relative to the crate root (which is
/// `cargo test`'s cwd).
const SAMPLE_PATH: &str = "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";

/// `load_yaml` collapses the former parse-into-document → thread-version
/// incantation into one call, applying the document stamp automatically and
/// reading identical content to the manually-built multi-step equivalent.
#[test]
fn load_yaml_collapses_three_step() {
    let yaml = std::fs::read_to_string(SAMPLE_PATH).expect("read sample");

    // The former multi-step incantation, built by hand: parse into a document
    // (hierarchical v2 decoding needs the root's metadata tree), then
    // construct the typed root with the retained model version.
    let tree = meta::d00_solution_blueprint_meta_tree();
    let manual_doc = som::SpecDocument::from_yaml(&yaml, &tree).expect("SpecDocument::from_yaml");
    let manual_version = manual_doc.model_version.clone();
    let manual =
        D00SolutionBlueprint::new(som::doc_ref(manual_doc), &manual_version).unwrap();

    // The one-call convenience.
    let one_call = D00SolutionBlueprint::load_yaml(&yaml).expect("load_yaml");

    // The document stamp is applied automatically — no manual threading.
    assert_eq!(
        one_call.node.doc().borrow().model_version,
        manual_version,
        "model version applied automatically"
    );
    // Both paths read identical content from the shared sample.
    assert_eq!(one_call.content(), manual.content());
    assert_eq!(
        one_call.introduction_and_scope().goals().content(),
        manual.introduction_and_scope().goals().content()
    );
    assert_eq!(
        one_call.current_landscape().operational_metrics().length(),
        manual.current_landscape().operational_metrics().length()
    );
}

/// `load_file` reads the file then delegates to `load_yaml`: its model version
/// and content match `load_yaml(<file contents>)`.
#[test]
fn load_file_delegates_to_load_yaml() {
    let from_file = D00SolutionBlueprint::load_file(SAMPLE_PATH).expect("load_file");
    let yaml = std::fs::read_to_string(SAMPLE_PATH).expect("read sample");
    let from_yaml = D00SolutionBlueprint::load_yaml(&yaml).expect("load_yaml");

    assert_eq!(
        from_file.node.doc().borrow().model_version,
        from_yaml.node.doc().borrow().model_version
    );
    assert_eq!(from_file.content(), from_yaml.content());
}

/// Builds a minimal hierarchical-v2 fixture yaml via `som::encode_yaml`
/// against the root's generated metadata tree (mirrors the Dart suite's
/// `buildV2Yaml` helper and the Go port). `model_version` "" ⇒ unstamped.
fn build_v2_yaml(model_version: &str) -> String {
    let tree = meta::d00_solution_blueprint_meta_tree();
    let mut d = som::SpecDocument::new();
    d.set_content("SBP/content", "Hello");
    som::encode_yaml(&d, &tree, model_version).expect("som::encode_yaml")
}

/// The generic one-call loader `SpecDocument::from_yaml` retains the parsed
/// model-version stamp and reads its content leaves.
#[test]
fn from_yaml_retains_model_version() {
    let tree = meta::d00_solution_blueprint_meta_tree();
    let doc =
        som::SpecDocument::from_yaml(&build_v2_yaml("1.0"), &tree).expect("from_yaml");
    assert_eq!(doc.model_version, "1.0");
    assert_eq!(doc.content_or("SBP/content"), "Hello");
}

/// An unstamped document loads with the empty-string sentinel model version
/// (Rust uses `""`, not `Option::None`), and `load_yaml` accepts it without
/// panicking — a new, editable document.
#[test]
fn unstamped_document_has_empty_model_version() {
    let yaml = build_v2_yaml("");
    let tree = meta::d00_solution_blueprint_meta_tree();
    let doc = som::SpecDocument::from_yaml(&yaml, &tree).expect("from_yaml");
    assert_eq!(doc.model_version, "", "unstamped → empty-string sentinel");
    // An empty stamp is accepted by the facade (a new document is editable).
    assert!(
        D00SolutionBlueprint::load_yaml(&yaml).is_ok(),
        "load_yaml accepts an unstamped document"
    );
}

// --- live-document conformance case durability guard (YRD8 / dsa13) ---------

/// The cross-language golden harness
/// (`tom_som_conformance/tool/regenerate_golden.sh` + `compare_golden.dart`)
/// already exercises the shared Meridian sample end to end and asserts the Rust
/// `rust.log` is byte-identical to the Dart reference. But `golden/` is
/// git-ignored, so this committed test pins the three live-document guarantees
/// the Rust golden generator emits over the shared sample, plus a fourth the
/// golden has no section for — instance-tier cleanliness — so a regression
/// fails `cargo test`, not only a full nine-toolchain golden run. Mirrors the Dart
/// (dsa7), Python (dsa8), JavaScript (dsa9), TypeScript (dsa10), Go (dsa11) and
/// Java (dsa12) durability guards.
#[test]
fn live_document_case() {
    const SAMPLE_MD: &str = "../tom_som_conformance/samples/meridian_order_management.md";
    const SCHEMA_PATH: &str =
        "schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml";
    const MODEL_META_PATH: &str = "meta/spec_model.meta.json";
    let tree = meta::d00_solution_blueprint_meta_tree();

    // 1) Round-trip: decode → encode → decode is stable over content + lists.
    let original = som::SpecDocument::from_file(SAMPLE_PATH, &tree).expect("from_file");
    let re_encoded =
        som::encode_yaml(&original, &tree, &original.model_version).expect("encode_yaml");
    let round_tripped = som::SpecDocument::from_yaml(&re_encoded, &tree).expect("from_yaml");

    assert_eq!(
        round_tripped.model_version, original.model_version,
        "round-trip model version diverged"
    );

    let mut orig_content = original.content_paths();
    orig_content.sort();
    let mut rt_content = round_tripped.content_paths();
    rt_content.sort();
    assert_eq!(rt_content, orig_content, "content-path set changed across round-trip");
    for p in &orig_content {
        assert_eq!(
            round_tripped.content_or(p),
            original.content_or(p),
            "content diverged at {}",
            p
        );
    }

    let mut orig_lists = original.list_paths();
    orig_lists.sort();
    let mut rt_lists = round_tripped.list_paths();
    rt_lists.sort();
    assert_eq!(rt_lists, orig_lists, "list-path set changed across round-trip");
    for p in &orig_lists {
        assert_eq!(
            round_tripped.list_items(p),
            original.list_items(p),
            "list items diverged at {}",
            p
        );
    }

    // 2) Validation: the markdown twin is clean under the SBP schema.
    let schema_text = std::fs::read_to_string(SCHEMA_PATH).expect("read schema");
    let schema = som::DocSpecsSchema::from_yaml_text(&schema_text).expect("from_yaml_text");
    let sample_md = std::fs::read_to_string(SAMPLE_MD).expect("read sample md");
    let root_id = schema.root_section_id();
    let warnings = schema.warnings.len();
    let violations = som::DocSpecsValidator::new(schema).validate_markdown(&sample_md);
    assert_eq!(root_id, "SBP", "schema root section id");
    assert_eq!(warnings, 0, "generated schema carries warnings");
    assert_eq!(violations.len(), 0, "sample markdown violates the generated schema");

    // 2b) Validation, instance tier: the sample's *values* are admissible.
    // Disjoint from the schema tier above — that asks whether every required
    // field is filled, this asks whether the values are well-formed: field
    // kinds, form keys, list minima and `refers_to` resolution (SOM §9). A
    // sample naming a message key, a role or a route nothing declares passes
    // the first and fails this one. Pinned here as well as in the sample's
    // builder because the sample is *committed*: a hand-edit or a merge can
    // reach it without anyone re-running the builder.
    let meta_text = std::fs::read_to_string(MODEL_META_PATH).expect("read model meta");
    let model = som::SpecModel::from_json_str(&meta_text).expect("SpecModel::from_json_str");
    let instance_violations = som::validate_document(&model, &original);
    assert!(
        instance_violations.is_empty(),
        "sample document violates the instance tier: {}",
        instance_violations
            .iter()
            .map(|v| v.to_display())
            .collect::<Vec<_>>()
            .join("; ")
    );

    // 3) Node operations: by_path / nav / id resolve to the same node.
    let list_by_path = tree
        .by_path("SBP/currentLandscape/CUOPME-OPER-LST")
        .expect("by_path(operationalMetrics list)");
    assert_eq!(
        list_by_path.kind,
        som::SOM_META_KIND_LIST,
        "operationalMetrics kind"
    );

    let nav = meta::d00_solution_blueprint_meta(&tree);
    let nav_ref = nav.current_landscape().operational_metrics();
    assert_eq!(
        nav_ref.meta_ref.path, "SBP/currentLandscape/CUOPME-OPER-LST",
        "nav path"
    );
    let nav_node = nav_ref.meta_ref.meta().expect("nav meta");
    assert!(
        std::rc::Rc::ptr_eq(&nav_node, &list_by_path),
        "nav node identity != by_path node"
    );

    // Hoisted-id accessor agrees with the dot-notation position.
    let sbp_id = meta::SBP(&tree);
    let id_item = sbp_id.RVENT_REVS_LST().item(0);
    let nav_item = nav.document_control().revision_history().item(0);
    assert_eq!(id_item.path(), nav_item.path(), "id item path vs nav item path");
    let id_node = id_item.meta().expect("id item meta");
    let nav_item_node = nav_item.meta().expect("nav item meta");
    assert!(
        std::rc::Rc::ptr_eq(&id_node, &nav_item_node),
        "id item node identity != nav item node"
    );
}
