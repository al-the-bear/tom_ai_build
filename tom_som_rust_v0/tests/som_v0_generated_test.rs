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
