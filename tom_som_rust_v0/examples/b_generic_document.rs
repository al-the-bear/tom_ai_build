// Sample (b) — GENERIC in-memory document access (som_multiplatform_spec_model.md §6).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the crate root `src/lib.rs`, `meta/`, `schemas/` and `Cargo.toml`).
//
// Demonstrates editing the *same* document shape as sample (a) using ONLY the
// generic `tom_som_rust_runtime` — string paths, no generated typed classes.
// This is the language-independent core: a sparse, path-keyed store plus the
// list and serialization helpers. Anything the typed facade can express is
// expressible here; the typed facade just makes it type-safe and discoverable.
//
// Run from the crate root:  cargo run --example b_generic_document
//
// The generic runtime is reached through the fixed crate name
// `tom_som_rust_runtime` (wired by the relative `path` dependency in this
// crate's Cargo.toml), so the sample is portable across checkouts.

use tom_som_rust_runtime as som;
use tom_som_rust_v0::meta;

fn main() {
    let mut doc = som::SpecDocument::new();

    // Content leaves are addressed by their full path from the root segment.
    doc.set_content(
        "SBP/content",
        "A platform that unifies our fragmented order systems.",
    );
    doc.set_content(
        "SBP/currentLandscape/content",
        "Three legacy systems with no shared customer record.",
    );

    // A list: append items (each call returns the new item's path), then set a
    // content leaf under each. The list path mirrors the typed facade's
    // `operationalMetrics` accessor.
    let list_path = "SBP/currentLandscape/CUOPME-OPER-LST";
    let item0 = doc.add_list_item(list_path);
    doc.set_content(&format!("{}/content", item0), "Average order turnaround: 4.2 days.");
    let item1 = doc.add_list_item(list_path);
    doc.set_content(
        &format!("{}/content", item1),
        "Manual reconciliation: ~12 hours / week.",
    );

    // Read back generically.
    println!("SBP/content = {}", doc.content_or("SBP/content"));
    println!("list item count = {}", doc.list_item_count(list_path));
    for item_path in doc.list_items(list_path) {
        println!(
            "  {}/content = {}",
            item_path,
            doc.content_or(&format!("{}/content", item_path))
        );
    }

    // The whole document serializes losslessly to canonical JSON. Keys are
    // emitted in sorted order, so the dump is deterministic regardless of
    // insertion order (matching the Dart/Python/Go/TS counterparts).
    println!("\nDocument JSON:");
    println!("{}", doc.to_json().to_canonical_json());

    // … and to the canonical YAML wire format (stamped with the model version).
    // Hierarchical v2 encoding walks the root's generated metadata tree.
    println!("\nDocument YAML:");
    let tree = meta::d00_solution_blueprint_meta_tree();
    print!(
        "{}",
        som::encode_yaml(&doc, &tree, "1.0").expect("encode_yaml")
    );
}
