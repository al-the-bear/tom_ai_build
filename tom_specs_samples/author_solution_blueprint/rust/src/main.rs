//! TomSpecs sample — author a Solution Blueprint end to end (Rust).
//!
//! The Rust port of `../bin/author_solution_blueprint.dart`: the same six
//! steps, the same document, the same output (`../expected_output.txt`).
//!
//! Run (from this folder; see README.md):  `cargo run`
//!
//! Six steps, in the order a real authoring task takes them:
//!
//!  1. open a fresh document and a typed root
//!  2. author a small but coherent Solution Blueprint
//!  3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
//!  4. round-trip the yaml back through the one-call typed loader and prove
//!     the reload is equal to what was written
//!  5. validate on the instance tier
//!  6. break one rule deliberately and read the diagnostic
//!
//! This sample is the NARRATIVE. The individual access styles each have their
//! own focused example in the facade crate (`tom_som_rust_v0/examples/`), and
//! this does not re-explain them.

use std::fs;
use std::path::Path;

use tom_som_rust_runtime as som;
use tom_som_rust_v0::{meta, D00SolutionBlueprint};

fn main() {
    let out_dir = Path::new("build");
    fs::create_dir_all(out_dir).expect("create build/");

    // -------------------------------------------------------------- step 1
    // A typed root over a fresh, empty document. Constructing the root also
    // runs the instantiation-time model-version check (SOM §4.2): an unstamped
    // document is editable, a document from a newer model is refused.
    let doc = som::doc_ref(som::SpecDocument::new());
    let sbp = D00SolutionBlueprint::new(doc.clone(), "").expect("a typed root");

    println!("1. A typed root over an empty document");
    println!("   object model version : {}", sbp.object_model_version());
    println!("   root path            : {}", sbp.node.path());
    println!();

    // -------------------------------------------------------------- step 2
    // Author. Every write below goes through a NAMED accessor — no string
    // paths — and lands in the same path-keyed store the generic API reads.
    println!("2. Authoring, printing each section id as it is written");

    sbp.set_content("Unify three legacy order systems behind one customer record.");
    wrote(sbp.node.path(), "the blueprint itself");

    let intro = sbp.introduction_and_scope();
    intro.set_content("Replace per-region order intake with a single pipeline.");
    wrote(intro.node.path(), "introduction and scope");

    let landscape = sbp.current_landscape();
    landscape.set_content("Three systems, no shared customer record, manual reconciliation.");
    wrote(landscape.node.path(), "the current landscape");

    // A list section. `add()` appends an item and returns it typed.
    let metrics = landscape.operational_metrics();
    metrics
        .add()
        .set_content("Average order turnaround: 4.2 days.");
    metrics
        .add()
        .set_content("Manual reconciliation: about 12 hours a week.");
    wrote(
        metrics.list_path(),
        &format!("{} operational metrics", metrics.length()),
    );

    println!();

    // -------------------------------------------------------------- step 3
    // Both renditions of the same document. They are two encodings of one
    // store, not two documents — which is why step 4 can round-trip either.
    //
    // `to_markdown` and the validator both need a whole SpecModel: the facade
    // crate ships it as `meta/spec_model.meta.json`.
    let model = load_model();
    let tree = meta::d00_solution_blueprint_meta_tree();

    let yaml = som::encode_yaml(&doc.borrow(), &tree, &model.model_version_string()).expect("yaml");
    let markdown = doc
        .borrow()
        .to_markdown(&model, Some("D00SolutionBlueprint"))
        .expect("markdown");

    fs::write(out_dir.join("blueprint.docspecs.yaml"), &yaml).expect("write yaml");
    fs::write(out_dir.join("blueprint.md"), &markdown).expect("write markdown");

    println!("3. Serialised both renditions into build/");
    println!(
        "   blueprint.docspecs.yaml : {} lines  (SOM §12)",
        lines(&yaml)
    );
    println!(
        "   blueprint.md            : {} lines  (SOM §11)",
        lines(&markdown)
    );
    println!();

    // -------------------------------------------------------------- step 4
    // The one-call typed loader: decode, apply the document's own authoring
    // stamp, and hand back a typed root. Re-encoding the reload and comparing
    // the two strings is the actual proof — comparing field by field would only
    // prove the fields somebody thought to compare.
    let reloaded =
        D00SolutionBlueprint::load_file("build/blueprint.docspecs.yaml").expect("reload");
    let re_yaml = som::encode_yaml(
        &reloaded.node.doc().borrow(),
        &tree,
        &model.model_version_string(),
    )
    .expect("yaml");

    println!("4. Round-tripped the yaml through D00SolutionBlueprint.loadFile");
    println!("   reload equals original  : {}", re_yaml == yaml);
    println!(
        "   a value read back typed : \"{}\"",
        reloaded
            .current_landscape()
            .operational_metrics()
            .at(0)
            .content()
    );
    println!();

    // -------------------------------------------------------------- step 5
    let errors = som::validate_document(&model, &doc.borrow());
    println!("5. Instance-tier validation");
    println!("   violations              : {}", errors.len());
    println!();

    // -------------------------------------------------------------- step 6
    // What a violation looks like. Writing to a path the model does not declare
    // is the clearest break to stage: the store accepts it — it is a plain
    // path-keyed map — and the validator is what notices.
    let mut broken = som::SpecDocument::from_yaml(&yaml, &tree).expect("decode");
    broken.set_content("SBP/noSuchSection/content", "not part of the model");

    let broken_errors = som::validate_document(&model, &broken);
    println!("6. The same document with one rule deliberately broken");
    println!("   violations              : {}", broken_errors.len());
    for e in &broken_errors {
        println!("   {}: {}", e.code, e.path);
        println!("     {}", e.message);
    }
    println!();
    println!("Done. The two renditions are in build/.");
}

/// Prints the section id a write landed under. The ids are the document's
/// addressing system — the same tokens appear in the yaml keys and in the
/// markdown `<!--[ID]-->` comments — so the sample shows them rather than
/// describing them.
fn wrote(path: &str, what: &str) {
    println!("   {:<46} {}", path, what);
}

fn lines(s: &str) -> usize {
    s.trim_end().split('\n').count()
}

/// Reads the whole model the facade crate ships, from the checkout:
/// `tom_som_rust_v0/meta/spec_model.meta.json`, three folders above this crate.
fn load_model() -> som::SpecModel {
    let path = format!(
        "{}/../../../tom_som_rust_v0/meta/spec_model.meta.json",
        env!("CARGO_MANIFEST_DIR")
    );
    let text = fs::read_to_string(&path).unwrap_or_else(|e| panic!("{}: {}", path, e));
    som::SpecModel::from_json(&som::Json::parse(&text).expect("model JSON"))
}
