// Behavioural test for the **actually-committed** generated Rust typed model.
//
// Unlike the emitter's golden test (which compiles the small emitter fixture),
// this suite exercises the real, full `tom_som_rust_v0` crate (3000+ types)
// against the generic `tom_som_rust_runtime` and proves the typed facade is a
// faithful editing surface over the shared document (spec §3):
//
//   - the `D00SolutionBlueprint` root is anchored at the `PD` segment;
//   - a content leaf round-trips typed → generic and generic → typed;
//   - a nested complex section derives its path under the root;
//   - the typed `SomList` collection maps onto the generic list store;
//   - the generated model-version accessor / constant return `0.0`;
//   - the instantiation-time version check (§2.2) accepts an editable stamp and
//     rejects a newer-minor / cross-major stamp with a `SomVersionError`.
//
// Run with `cargo test`. The runtime resolves through the `path` dev-dependency
// in this crate's Cargo.toml, so the test is portable across checkouts.

use tom_som_rust_runtime as som;
use tom_som_rust_v0::{
    CurrentOperationalMetric, D00SolutionBlueprint, D00_SOLUTION_BLUEPRINT_MODEL_VERSION,
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

// --- aligned absence semantics (§ item 5) ----------------------------------

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

// --- one-call loading (§ item 4) -------------------------------------------

/// The shared conformance sample, resolved relative to the crate root (which is
/// `cargo test`'s cwd).
const SAMPLE_PATH: &str = "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml";

/// `load_yaml` collapses the former decode → load_json → thread-version
/// incantation into one call, applying the document stamp automatically and
/// reading identical content to the manually-built three-step equivalent.
#[test]
fn load_yaml_collapses_three_step() {
    let yaml = std::fs::read_to_string(SAMPLE_PATH).expect("read sample");

    // The former three-step incantation.
    let decoded = som::decode_yaml(&yaml);
    let mut manual_doc = som::SpecDocument::new();
    manual_doc.load_json(&decoded.document);
    manual_doc.model_version = decoded.model_version.clone();
    let manual =
        D00SolutionBlueprint::new(som::doc_ref(manual_doc), &decoded.model_version).unwrap();

    // The one-call convenience.
    let one_call = D00SolutionBlueprint::load_yaml(&yaml).expect("load_yaml");

    // The document stamp is applied automatically — no manual threading.
    assert_eq!(
        one_call.node.doc().borrow().model_version,
        decoded.model_version,
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

/// The generic one-call loader `SpecDocument::from_yaml` retains the parsed
/// model-version stamp and reads its content leaves.
#[test]
fn from_yaml_retains_model_version() {
    let yaml = "version: 1\nmodelVersion: \"1.0\"\ndocument:\n  content:\n    \"SBP/content\": |2-\n      Hello\n";
    let doc = som::SpecDocument::from_yaml(yaml);
    assert_eq!(doc.model_version, "1.0");
    assert_eq!(doc.content_or("SBP/content"), "Hello");
}

/// An unstamped document loads with the empty-string sentinel model version
/// (Rust uses `""`, not `Option::None`), and `load_yaml` accepts it without
/// panicking — a new, editable document.
#[test]
fn unstamped_document_has_empty_model_version() {
    let yaml = "version: 1\ndocument: {}\n";
    let doc = som::SpecDocument::from_yaml(yaml);
    assert_eq!(doc.model_version, "", "unstamped → empty-string sentinel");
    // An empty stamp is accepted by the facade (a new document is editable).
    assert!(
        D00SolutionBlueprint::load_yaml(yaml).is_ok(),
        "load_yaml accepts an unstamped document"
    );
}
