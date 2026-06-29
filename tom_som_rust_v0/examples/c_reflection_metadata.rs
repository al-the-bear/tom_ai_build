// Sample (c) — REFLECTION / meta-information access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the crate root `src/lib.rs`, `meta/`, `schemas/` and `Cargo.toml`).
//
// Demonstrates the value-free "reflection" surface: load the exported meta-data
// (`meta/spec_model.meta.json`, the lossless class graph) into a `SpecModel`
// and query its shape with `SpecReflection` — enumerate roots and fields, and
// resolve a concrete document *path* to the model node it lands on. No document
// values are involved; this answers "what CAN the model hold?", not "what does
// a given document hold?".
//
// Run from the crate root:  cargo run --example c_reflection_metadata
//
// The generic runtime is reached through the fixed crate name
// `tom_som_rust_runtime` (wired by the relative `path` dependency in this
// crate's Cargo.toml), so the sample is portable across checkouts.

use std::fs;
use std::process::exit;

use tom_som_rust_runtime as som;

fn main() {
    // `CARGO_MANIFEST_DIR` is the crate root (which holds `meta/`), so the
    // sample is runnable from any cwd.
    let meta_path = format!(
        "{}/meta/spec_model.meta.json",
        env!("CARGO_MANIFEST_DIR")
    );
    let data = fs::read_to_string(&meta_path).expect("read meta-data");
    let model = som::SpecModel::from_json_str(&data).expect("parse meta-data");
    let reflection = som::SpecReflection::new(&model);

    let label = if model.model_version_label.is_empty() {
        "unstamped".to_string()
    } else {
        model.model_version_label.clone()
    };
    println!("Model version: {} ({})", model.model_version, label);
    let roots = reflection.roots();
    println!(
        "Roots: {}, classes: {}\n",
        roots.len(),
        reflection.classes().len()
    );

    // Enumerate the document roots by their addressable segment.
    println!("Document roots:");
    for root in roots {
        println!("  {:<4} {}", reflection.root_segment(root), root.title);
    }

    // Inspect the fields of the D00SolutionBlueprint root class.
    let pd_root = match reflection.root_for_segment("SBP") {
        Some(r) => r,
        None => {
            println!("SBP root not found");
            exit(1);
        }
    };
    let pd_fields = reflection.fields_of(&pd_root.type_);
    println!(
        "\nFirst fields of {} ({} total):",
        pd_root.type_,
        pd_fields.len()
    );
    for field in pd_fields.iter().take(6) {
        let mut extra = String::new();
        if !field.type_.is_empty() {
            extra.push_str(&format!("  type={}", field.type_));
        }
        if !field.element_type.is_empty() {
            extra.push_str(&format!("  elem={}", field.element_type));
        }
        println!("  {:<24} kind={}{}", field.name, field.kind, extra);
    }

    // Resolve concrete document paths to model nodes (value-free).
    println!("\nPath resolution:");
    for path in [
        "SBP",
        "SBP/content",
        "SBP/currentLandscape",
        "SBP/currentLandscape/CUOPME-OPER-LST",
    ] {
        match reflection.resolve(path) {
            None => println!("  {}  ->  (unresolved)", path),
            Some(res) => {
                let cls = match &res.target_class {
                    Some(c) => format!("  class={}", c.name),
                    None => String::new(),
                };
                println!(
                    "  {:<40} -> kind={}{}  value_leaf={}",
                    path,
                    res.kind,
                    cls,
                    res.is_value_leaf()
                );
            }
        }
    }
}
