// Sample (a) — TYPED object-model access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the crate root `src/lib.rs`, `meta/`, `schemas/` and `Cargo.toml`).
//
// Demonstrates editing a TomSpecs document through the generated *typed* facade
// `tom_som_rust_v0`: named accessors, nested-section navigation, and the typed
// `SomList` collection. The typed facade is a thin editing surface over a
// generic `SpecDocument` — every typed write lands in the same path-keyed store
// the generic API (sample b) reads, which the closing lines prove.
//
// Run from the crate root:  cargo run --example a_typed_access
//
// The generic runtime is reached through the fixed crate name
// `tom_som_rust_runtime` (wired by the relative `path` dependency in this
// crate's Cargo.toml), so the sample is portable across checkouts.

use tom_som_rust_runtime as som;
use tom_som_rust_v0::D00SolutionBlueprint;

fn main() {
    // A typed root over a fresh, empty document. The constructor also runs the
    // §2.2 instantiation-time version check (an empty stamp is editable).
    let doc = som::doc_ref(som::SpecDocument::new());
    let pd = D00SolutionBlueprint::new(doc.clone(), "").expect("new D00SolutionBlueprint");

    println!(
        "Model version of this typed facade: {}",
        pd.object_model_version()
    );
    println!("Root path: {}\n", pd.node.path());

    // 1) A content leaf directly on the root.
    pd.set_content("A platform that unifies our fragmented order systems.");

    // 2) Navigate into a nested complex section and edit its own content leaf.
    let csa = pd.current_landscape();
    csa.set_content("Three legacy systems with no shared customer record.");

    // 3) The typed collection API: append two list items and edit each.
    let metrics = csa.operational_metrics();
    metrics
        .add()
        .set_content("Average order turnaround: 4.2 days.");
    metrics
        .add()
        .set_content("Manual reconciliation: ~12 hours / week.");

    // Read everything back through the typed accessors.
    println!("SBP.content              = {}", pd.content());
    println!("SBP.currentLandscape = {}", csa.content());
    println!("operationalMetrics.length = {}", metrics.length());
    for i in 0..metrics.length() {
        println!("  metric[{}] = {}", i, metrics.at(i).content());
    }

    // The typed path is the generic path: the same data is addressable through
    // the generic document API (this is exactly what sample (b) uses).
    println!(
        "\nSame value via the generic path (doc.content_or({:?}/content)):",
        csa.node.path()
    );
    println!(
        "  {}",
        doc.borrow().content_or(&format!("{}/content", csa.node.path()))
    );
}
