// Cross-language golden-log generator for Rust (roadmap item 7b).
//
// Mirror of tom_som_dart_v0/tool/golden_log.dart — see that file for the
// canonical format. Loads the shared sample and emits a byte-identical reading
// of essentially every section through both the generic string-path API and the
// typed facade, asserting typed == generic before writing.
//
// Run from the crate root:  cargo run --example golden_log [samplePath] [output]

use std::fs;
use std::path::Path;
use std::process::exit;

use tom_som_rust_runtime as som;
use tom_som_rust_v0::D00SolutionBlueprint;

fn esc(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('\n', "\\n")
        .replace('\r', "\\r")
        .replace('\t', "\\t")
}

fn die(msg: &str) -> ! {
    eprintln!("{}", msg);
    exit(2);
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let sample = if args.len() > 1 {
        args[1].clone()
    } else {
        "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml".to_string()
    };
    let output = if args.len() > 2 {
        args[2].clone()
    } else {
        "../tom_som_conformance/golden/rust.log".to_string()
    };

    let doc = som::SpecDocument::from_file(&sample);
    let sbp = match D00SolutionBlueprint::load_file(&sample) {
        Ok(s) => s,
        Err(e) => die(&format!("load typed root failed: {}", e)),
    };

    let mut out: Vec<String> = Vec::new();
    out.push("# TomSpecs SOM golden log — canonical cross-language reading.".to_string());
    out.push("# All nine per-language generators must emit byte-identical output.".to_string());
    out.push("FORMAT\t1".to_string());
    out.push(format!("MODELVERSION\t{}", esc(&doc.model_version)));

    // Generic: content leaves, sorted by path.
    out.push("SECTION\tgeneric-content".to_string());
    let mut content_paths = doc.content_paths();
    content_paths.sort();
    for p in &content_paths {
        out.push(format!("C\t{}\t{}", p, esc(&doc.content_or(p))));
    }

    // Generic: form sections + fields, sorted by path then field.
    out.push("SECTION\tgeneric-forms".to_string());
    let mut form_paths = doc.form_paths();
    form_paths.sort();
    for p in &form_paths {
        let mut fields = doc.form_field_names(p);
        fields.sort();
        for f in &fields {
            out.push(format!("F\t{}\t{}\t{}", p, f, esc(&doc.form_field_or(p, f))));
        }
    }

    // Generic: list containers + item paths (document order).
    out.push("SECTION\tgeneric-lists".to_string());
    let mut list_paths = doc.list_paths();
    list_paths.sort();
    for p in &list_paths {
        let items = doc.list_items(p);
        out.push(format!("L\t{}\t{}", p, items.len()));
        for item in &items {
            out.push(format!("I\t{}", item));
        }
    }

    // Typed: curated traversal that must agree with the generic reads.
    out.push("SECTION\ttyped".to_string());

    let mut typed_content = |node_path: &str, value: &str| {
        let leaf = format!("{}/content", node_path);
        let generic = doc.content_or(&leaf);
        if value != generic {
            die(&format!("TYPED MISMATCH at {}", leaf));
        }
        out.push(format!("T\t{}\t{}", leaf, esc(value)));
    };

    typed_content(sbp.node.path(), &sbp.content());
    let n = sbp.document_control();
    typed_content(n.node.path(), &n.content());
    let n = sbp.introduction_and_scope();
    typed_content(n.node.path(), &n.content());
    let n = sbp.glossary_and_abbreviations();
    typed_content(n.node.path(), &n.content());
    let n = sbp.stakeholders_and_governance();
    typed_content(n.node.path(), &n.content());
    let n = sbp.current_landscape();
    typed_content(n.node.path(), &n.content());
    let n = sbp.assumptions_constraints_dependencies();
    typed_content(n.node.path(), &n.content());
    let n = sbp.target_operating_model_concept();
    typed_content(n.node.path(), &n.content());
    let n = sbp.information_and_data_model();
    typed_content(n.node.path(), &n.content());
    let n = sbp.requirements();
    typed_content(n.node.path(), &n.content());
    let n = sbp.solution_architecture_and_technology();
    typed_content(n.node.path(), &n.content());
    let n = sbp.security_and_access_model();
    typed_content(n.node.path(), &n.content());
    let n = sbp.experience_and_interface_design();
    typed_content(n.node.path(), &n.content());
    let n = sbp.quality_and_acceptance_model();
    typed_content(n.node.path(), &n.content());
    let n = sbp.delivery_transition_and_rollout();
    typed_content(n.node.path(), &n.content());

    let intro = sbp.introduction_and_scope();
    let goals = intro.goals();
    typed_content(goals.node.path(), &goals.content());

    let cl = sbp.current_landscape();
    let metrics = cl.operational_metrics();
    let metric_item_paths = doc.list_items(metrics.list_path());
    if metrics.length() != metric_item_paths.len() {
        die(&format!("TYPED LIST LENGTH MISMATCH at {}", metrics.list_path()));
    }
    out.push(format!("TL\t{}\t{}", metrics.list_path(), metrics.length()));
    for i in 0..metrics.length() {
        let elem = metrics.at(i);
        let leaf = format!("{}/content", elem.node.path());
        let generic = doc.content_or(&leaf);
        if elem.content() != generic {
            die(&format!("TYPED LIST ITEM MISMATCH at {}", leaf));
        }
        out.push(format!("TI\t{}\t{}", leaf, esc(&elem.content())));
    }

    if let Some(parent) = Path::new(&output).parent() {
        fs::create_dir_all(parent).unwrap_or_else(|e| die(&format!("mkdir failed: {}", e)));
    }
    let body = format!("{}\n", out.join("\n"));
    fs::write(&output, body).unwrap_or_else(|e| die(&format!("write failed: {}", e)));
    println!("wrote {} lines to {}", out.len(), output);
}
