//! SOM §11.2 `units`: the generation units a section goes to — a port of the
//! Dart reference `tom_som_dart_runtime/test/spec_units_test.dart`.
//!
//! Kept exactly as `codeSpec` is: a sparse store by section path, the Markdown
//! heading key `units="a,b"` after `codeSpec`, the YAML key `units` after
//! `codeSpec`, the facade's `units` / `set_units`, the snapshot's `units` map —
//! and checked by the instance tier's phase 8. The Dart cases of
//! `captureState` / `restoreState` and the path normalizer have no counterpart
//! here: this port's document is `Clone` (no state snapshot) and has no path
//! normalizer.

use std::cell::RefCell;
use std::rc::Rc;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::spec_codespecs_extract::{CodeSpecsAreaCatalog, CodeSpecsExtractor};
use tom_som_rust_runtime::spec_document::{DocumentJson, SpecDocument};
use tom_som_rust_runtime::spec_document_markdown::SpecDocumentMarkdown;
use tom_som_rust_runtime::spec_document_yaml::{encode_yaml, SpecYamlError};
use tom_som_rust_runtime::spec_meta::SomMetaTree;
use tom_som_rust_runtime::spec_meta_bridge::build_som_meta_tree;
use tom_som_rust_runtime::spec_model::SpecModel;
use tom_som_rust_runtime::spec_review_merge::{
    merge_reviews, SpecReviewMember, SpecReviewMergeOptions, SpecReviewedCopy,
};
use tom_som_rust_runtime::validate_document;
use tom_som_rust_runtime::CodeSpecsExtract;
use tom_som_rust_runtime::SomNode;
use tom_som_rust_runtime::{spec_default_units, spec_generation_units};

fn corpus(name: &str) -> String {
    let path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../tom_som_conformance/corpus")
        .join(name);
    std::fs::read_to_string(&path).unwrap_or_else(|e| panic!("read {}: {}", path.display(), e))
}

/// The shared corpus model: the demo root with the generation-unit register
/// `DEMO/DLV-LST` (`Deliverable`, `DeliverableRoute`).
fn corpus_model() -> SpecModel {
    SpecModel::from_json_str(&corpus("model.meta.json")).expect("the corpus model loads")
}

fn tree(model: &SpecModel) -> SomMetaTree {
    build_som_meta_tree(model, "").expect("tree")
}

fn enc(tree: &SomMetaTree, d: &SpecDocument) -> String {
    encode_yaml(d, tree, "1.0").expect("encodes")
}

/// A register declaring `u_a` and `u_b`, both building something.
fn register() -> SpecDocument {
    let mut d = SpecDocument::new();
    let a = d.add_list_item("DEMO/DLV-LST");
    d.set_form_field(&format!("{}/content", a), "unitId", "u_a");
    d.set_form_field(&format!("{}/content", a), "component", "ARCM-COMP-A");
    let b = d.add_list_item("DEMO/DLV-LST");
    d.set_form_field(&format!("{}/content", b), "unitId", "u_b");
    d.set_form_field(
        &format!("{}/content", b),
        "deploymentTarget",
        "DEPTAR-DEPL-B",
    );
    d
}

// --- the store --------------------------------------------------------------

#[test]
fn store_units_set_units_units_paths_empty_clears() {
    let mut d = SpecDocument::new();
    assert_eq!(d.units("DEMO/TTL"), None);
    d.set_units("DEMO/TTL", "u_a,u_b");
    assert_eq!(d.units("DEMO/TTL").map(|s| s.as_str()), Some("u_a,u_b"));
    assert_eq!(d.units_paths(), vec!["DEMO/TTL".to_string()]);
    assert!(!d.is_empty());
    assert!(d.has_values_under("DEMO"));
    d.set_units("DEMO/TTL", "");
    assert_eq!(d.units("DEMO/TTL"), None);
    assert!(d.units_paths().is_empty());
    assert!(d.is_empty());
}

#[test]
fn snapshot_carries_units_beside_code_specs_sorted() {
    let mut d = SpecDocument::new();
    d.set_code_spec("DEMO/TTL", "A");
    d.set_units("DEMO/TTL", "u_b");
    d.set_units("DEMO/SUM", "u_a");
    let canonical = d.to_json().to_canonical_json();
    assert_eq!(
        canonical,
        r#"{"codeSpecs":{"DEMO/TTL":"A"},"units":{"DEMO/SUM":"u_a","DEMO/TTL":"u_b"}}"#
    );
    let back_json = DocumentJson::from_json(&Json::parse(&canonical).expect("json"));
    let mut back = SpecDocument::new();
    back.load_json(&back_json);
    assert_eq!(back.to_json(), d.to_json());
    // No units, no key.
    assert!(!SpecDocument::new()
        .to_json()
        .to_canonical_json()
        .contains("units"));
}

#[test]
fn remove_values_under_clears_units_under_the_prefix() {
    let mut d = SpecDocument::new();
    d.set_units("DEMO/notes", "u_a");
    d.set_units("DEMO/notes/NOTE-BDY", "u_b");
    d.set_units("DEMO/TTL", "u_a");
    d.remove_values_under("DEMO/notes");
    assert_eq!(d.units_paths(), vec!["DEMO/TTL".to_string()]);
}

#[test]
fn units_move_with_their_list_item() {
    let model = corpus_model();
    let mut d = SpecDocument::new();
    let first = d.add_list_item("DEMO/items");
    let second = d.add_list_item("DEMO/items");
    d.set_content(&format!("{}/label", first), "one");
    d.set_content(&format!("{}/label", second), "two");
    d.set_units(&second, "u_a");
    d.move_list_item(&model, &second, 0, None).expect("moves");
    assert_eq!(d.units("DEMO/items-1").map(|s| s.as_str()), Some("u_a"));
    assert_eq!(d.units("DEMO/items-2"), None);
}

#[test]
fn the_value_index_sees_units() {
    let mut d = SpecDocument::new();
    d.set_units("DEMO/REF-LST", "u_a");
    assert!(d.has_values_under("DEMO"));
    assert!(d.has_values_under("DEMO/REF"));
    assert!(d.has_values_under("DEMO/REF-LST"));
    assert!(!d.has_values_under("DEMO/REF-LST-1"));
}

#[test]
fn the_facade_reads_and_writes_units_empty_clears() {
    let doc = Rc::new(RefCell::new(SpecDocument::new()));
    let node = SomNode::new(Rc::clone(&doc), "DEMO/TTL".to_string());
    assert_eq!(node.units(), "");
    node.set_units("u_a");
    assert_eq!(
        doc.borrow().units("DEMO/TTL").map(|s| s.as_str()),
        Some("u_a")
    );
    assert_eq!(node.units(), "u_a");
    node.set_units("");
    assert_eq!(node.units(), "");
    assert!(doc.borrow().units_paths().is_empty());
}

// --- Markdown ---------------------------------------------------------------

#[test]
fn markdown_emits_units_after_code_spec_in_the_heading_comment() {
    let model = corpus_model();
    let mut d = SpecDocument::new();
    d.set_content("DEMO/TTL", "Hello");
    d.set_code_spec("DEMO/TTL", "DemoTitle");
    d.set_units("DEMO/TTL", "u_a,u_b");
    d.set_content("DEMO/SUM", "Sum");
    d.set_units("DEMO/SUM", "u_a");
    let md = d.to_markdown(&model, None).expect("renders");
    assert!(
        md.contains("## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Document Title\n"),
        "{}",
        md
    );
    assert!(
        md.contains("## <!--[SUM] units=\"u_a\"--> Summary\n"),
        "{}",
        md
    );
}

#[test]
fn markdown_parses_units_in_every_quoting_beside_or_without_code_spec() {
    let model = corpus_model();
    let md = "# <!--[DEMO] units=u_root--> Demo Document\n\n\
              ## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Title\n\n\
              Hello\n\n\
              ## <!--[SUM] units='u_c'--> Summary\n\n\
              Sum\n\n\
              ## <!--[CNT] codeSpec=\"units=no\"--> Count\n\n\
              3\n";
    let empty = SpecDocument::new();
    let result = SpecDocumentMarkdown::new(&model, &empty).parse(md);
    assert!(result.rejections.is_empty(), "{:?}", result.rejections);
    let units: Vec<(&str, &str)> = result
        .units
        .iter()
        .map(|(k, v)| (k.as_str(), v.as_str()))
        .collect();
    assert_eq!(
        units,
        vec![
            ("DEMO", "u_root"),
            ("DEMO/SUM", "u_c"),
            ("DEMO/TTL", "u_a,u_b")
        ]
    );
    assert_eq!(
        result.code_specs.get("DEMO/TTL").map(|s| s.as_str()),
        Some("DemoTitle")
    );
    // A `units=` inside a quoted codeSpec value is not the key.
    assert_eq!(
        result.code_specs.get("DEMO/CNT").map(|s| s.as_str()),
        Some("units=no")
    );
}

#[test]
fn markdown_round_trips_byte_stably_through_from_markdown() {
    let model = corpus_model();
    let mut d = register();
    d.set_content("DEMO/TTL", "Hello");
    d.set_code_spec("DEMO/TTL", "DemoTitle");
    d.set_units("DEMO/TTL", "u_a");
    d.set_content("DEMO/notes/NOTE-BDY", "Body");
    d.set_units("DEMO/notes", "u_a,u_b");
    let md = d.to_markdown(&model, None).expect("renders");
    let back = SpecDocument::from_markdown(&md, &model).document;
    assert_eq!(back.units("DEMO/TTL").map(|s| s.as_str()), Some("u_a"));
    assert_eq!(
        back.units("DEMO/notes").map(|s| s.as_str()),
        Some("u_a,u_b")
    );
    assert_eq!(back.to_markdown(&model, None).expect("renders"), md);
}

#[test]
fn apply_markdown_result_overwrites_clears_and_keeps_units() {
    let model = corpus_model();
    let mut d = SpecDocument::new();
    d.set_units("DEMO/TTL", "stale");
    d.set_units("DEMO/SUM", "stale");
    d.set_units("OTHER/kept", "kept");
    let md = "# <!--[DEMO]--> Demo Document\n\n\
              ## <!--[TTL] units=\"u_a\"--> Document Title\n\nHello\n";
    let empty = SpecDocument::new();
    let parsed = SpecDocumentMarkdown::new(&model, &empty).parse(md);
    d.apply_markdown_result(&parsed, false).expect("applies");
    let units: Vec<(String, String)> = d.to_json().units.into_iter().collect();
    assert_eq!(
        units,
        vec![
            ("DEMO/TTL".to_string(), "u_a".to_string()),
            ("OTHER/kept".to_string(), "kept".to_string()),
        ]
    );
}

// --- YAML -------------------------------------------------------------------

#[test]
fn yaml_writes_units_right_after_code_spec_promoting_a_scalar() {
    let model = corpus_model();
    let tree = tree(&model);
    let mut d = SpecDocument::new();
    d.set_content("DEMO/TTL", "Hello");
    d.set_headline("DEMO/TTL", "Title");
    d.set_code_spec("DEMO/TTL", "DemoTitle");
    d.set_units("DEMO/TTL", "u_a");
    d.set_content("DEMO/CNT", "3");
    d.set_units("DEMO/CNT", "u_b");
    d.set_content("DEMO/notes/NOTE-BDY", "Body");
    d.set_units("DEMO/notes", "u_a,u_b");
    let yaml = enc(&tree, &d);
    assert!(
        yaml.contains(
            "    TTL title:\n\
             \x20     headline: |2-\n        Title\n\
             \x20     codeSpec: |2-\n        DemoTitle\n\
             \x20     units: |2-\n        u_a\n\
             \x20     content: |2-\n        Hello\n"
        ),
        "{}",
        yaml
    );
    // A non-text scalar keeps its plain content inside the mapping.
    assert!(
        yaml.contains("    CNT count:\n      units: |2-\n        u_b\n      content: 3\n"),
        "{}",
        yaml
    );
    assert!(
        yaml.contains("    NOTE notes:\n      units: |2-\n        u_a,u_b\n"),
        "{}",
        yaml
    );
    let back = SpecDocument::from_yaml(&yaml, &tree).expect("decodes");
    assert_eq!(back.to_json(), d.to_json());
    assert_eq!(enc(&tree, &back), yaml);
}

#[test]
fn yaml_units_on_a_form_a_list_container_and_a_list_item_round_trip() {
    let model = corpus_model();
    let tree = tree(&model);
    let mut d = register();
    d.set_form_field("DEMO/DET", "owner", "Bob");
    d.set_units("DEMO/DET", "u_a");
    d.set_units("DEMO/DLV-LST", "u_b");
    d.set_units("DEMO/DLV-LST-1", "u_a");
    let tag_item = d.add_list_item("DEMO/META/tags");
    d.set_content(&tag_item, "on");
    d.set_units(&tag_item, "u_b");
    let yaml = enc(&tree, &d);
    let back = SpecDocument::from_yaml(&yaml, &tree).expect("decodes");
    assert_eq!(back.to_json(), d.to_json());
    assert_eq!(enc(&tree, &back), yaml);
}

const UNITS_CLASH_MODEL_JSON: &str = r#"{
  "modelVersion": 1,
  "roots": [{"type": "R", "title": "R", "sectionId": "R"}],
  "classes": {
    "R": {
      "name": "R",
      "sectionId": "R",
      "fields": [
        {"name": "units", "kind": "content"},
        {"name": "shape", "kind": "form", "sectionId": "SHP",
         "formFields": [{"name": "units", "label": "Units", "type": "String"}]}
      ]
    }
  }
}"#;

fn format_message<T>(r: &Result<T, SpecYamlError>) -> String {
    match r {
        Err(SpecYamlError::Format(e)) => e.to_string(),
        Err(e) => format!("other error: {}", e),
        Ok(_) => "no error".to_string(),
    }
}

#[test]
fn yaml_refuses_units_where_a_child_or_form_field_is_named_units() {
    let clash = SpecModel::from_json_str(UNITS_CLASH_MODEL_JSON).expect("clash model");
    let clash_tree = build_som_meta_tree(&clash, "").expect("clash tree");

    let mut root = SpecDocument::new();
    root.set_units("R", "u_a");
    let msg = format_message(&encode_yaml(&root, &clash_tree, "1.0"));
    assert!(msg.contains("also serializes as key `units`"), "{}", msg);

    let mut form = SpecDocument::new();
    form.set_form_field("R/SHP", "units", "3");
    form.set_units("R/SHP", "u_a");
    let msg = format_message(&encode_yaml(&form, &clash_tree, "1.0"));
    assert!(msg.contains("field literally named `units`"), "{}", msg);
}

#[test]
fn yaml_a_list_item_may_not_be_keyed_units() {
    let model = corpus_model();
    let tree = tree(&model);
    let mut d = SpecDocument::new();
    d.add_list_item_with_section_id("DEMO/DLV-LST", "units")
        .expect("adds");
    assert!(matches!(
        encode_yaml(&d, &tree, "1.0"),
        Err(SpecYamlError::Format(_))
    ));
}

// --- assembly and review merge ----------------------------------------------

#[test]
fn assembly_merges_units_and_refuses_two_fragments_writing_one() {
    let mut a = SpecDocument::new();
    a.set_units("DEMO/TTL", "u_a");
    let mut b = SpecDocument::new();
    b.set_units("DEMO/SUM", "u_b");
    let ok = SpecDocument::assemble(&[("a", &a), ("b", &b)]);
    assert!(ok.ok());
    assert_eq!(
        ok.document
            .as_ref()
            .and_then(|d| d.units("DEMO/SUM"))
            .map(|s| s.as_str()),
        Some("u_b")
    );
    let mut c = SpecDocument::new();
    c.set_units("DEMO/TTL", "u_b");
    let clash = SpecDocument::assemble(&[("a", &a), ("c", &c)]);
    assert!(!clash.ok());
    assert_eq!(clash.overlaps.len(), 1);
    assert_eq!(clash.overlaps[0].store, "units");
    assert_eq!(clash.overlaps[0].path, "DEMO/TTL");
}

#[test]
fn a_review_merge_carries_the_units_of_an_item_a_copy_added() {
    let model = corpus_model();
    let mut base = SpecDocument::new();
    let first = base.add_list_item("DEMO/items");
    base.set_content(&format!("{}/label", first), "one");
    let mut copy = SpecDocument::new();
    copy.load_json(&base.to_json());
    let added = copy.add_list_item("DEMO/items");
    copy.set_content(&format!("{}/label", added), "two");
    copy.set_units(&added, "u_a");
    let member = SpecReviewMember {
        member_id: "alice".to_string(),
        display_name: "Alice".to_string(),
        role: String::new(),
    };
    let result = merge_reviews(
        &model,
        &base,
        &[SpecReviewedCopy {
            member: member.clone(),
            document: copy,
        }],
        &SpecReviewMergeOptions {
            team: vec![member],
            date: "2026-11-12".to_string(),
            author: "alice".to_string(),
            question_prefix: None,
        },
    )
    .expect("merges");
    let merged = &result.merged;
    let items = merged.list_items("DEMO/items");
    assert_eq!(items.len(), 2);
    assert_eq!(merged.units(&items[1]).map(|s| s.as_str()), Some("u_a"));
}

// --- validation phase 8 -----------------------------------------------------

fn check(model: &SpecModel, d: &SpecDocument) -> Vec<(String, String, String)> {
    validate_document(model, d)
        .into_iter()
        .map(|e| (e.path, e.code, e.message))
        .collect()
}

fn finding(path: &str, code: &str, message: &str) -> (String, String, String) {
    (path.to_string(), code.to_string(), message.to_string())
}

#[test]
fn phase8_a_declared_unit_on_a_routed_section_is_clean() {
    let model = corpus_model();
    let mut d = register();
    d.set_units("DEMO/TTL", "u_a");
    d.set_units("DEMO/REG", "u_a,u_b");
    assert_eq!(check(&model, &d), vec![]);
}

#[test]
fn phase8_unknown_unit_names_each_undeclared_id_in_the_order_written() {
    let model = corpus_model();
    let mut d = register();
    d.set_units("DEMO/TTL", "u_x, u_a ,u_y");
    assert_eq!(
        check(&model, &d),
        vec![
            finding(
                "DEMO/TTL",
                "unknownUnit",
                "units names \"u_x\", which no generation unit declares"
            ),
            finding(
                "DEMO/TTL",
                "unknownUnit",
                "units names \"u_y\", which no generation unit declares"
            ),
        ]
    );
}

#[test]
fn phase8_units_unrouted_a_class_reaching_no_code_spec_kind() {
    let model = corpus_model();
    let mut d = register();
    d.set_units("DEMO/META", "u_a");
    d.set_units("DEMO/META/tags", "u_a");
    d.set_units("DEMO/control", "u_a");
    d.set_units("DEMO/DLV-LST-1", "u_a");
    // Routed: a field of a routed class, a list of a routed element.
    d.set_units("DEMO/PRI", "u_a");
    d.set_units("DEMO/CARD-LST", "u_a");
    let message = "units is set on a section that routes nothing to CodeSpecs";
    assert_eq!(
        check(&model, &d),
        vec![
            finding("DEMO/DLV-LST-1", "unitsUnrouted", message),
            finding("DEMO/META", "unitsUnrouted", message),
            finding("DEMO/META/tags", "unitsUnrouted", message),
            finding("DEMO/control", "unitsUnrouted", message),
        ]
    );
}

#[test]
fn phase8_the_register_duplicate_builds_nothing_malformed_area() {
    let model = corpus_model();
    let mut d = register();
    let dup = d.add_list_item("DEMO/DLV-LST");
    d.set_form_field(&format!("{}/content", dup), "unitId", "u_a");
    d.set_form_field(&format!("{}/content", dup), "kind", "server");
    // An item with no value at all is absence, not a finding.
    d.add_list_item("DEMO/DLV-LST");
    for area in ["CE-DB", "ce-db", "CE-", "CE-D1"] {
        let route = d.add_list_item("DEMO/DLV-LST-1/DLR-LST");
        d.set_form_field(&format!("{}/content", route), "area", area);
        d.set_form_field(&format!("{}/content", route), "mapping", "dart-tom");
    }
    assert_eq!(
        check(&model, &d),
        vec![
            finding(
                "DEMO/DLV-LST-1/DLR-LST-2",
                "unitAreaMalformed",
                "mapping area \"ce-db\" is not an area code (CE-…)"
            ),
            finding(
                "DEMO/DLV-LST-1/DLR-LST-3",
                "unitAreaMalformed",
                "mapping area \"CE-\" is not an area code (CE-…)"
            ),
            finding(
                "DEMO/DLV-LST-1/DLR-LST-4",
                "unitAreaMalformed",
                "mapping area \"CE-D1\" is not an area code (CE-…)"
            ),
            finding(
                "DEMO/DLV-LST-3",
                "duplicateUnitId",
                "generation unit \"u_a\" is declared twice"
            ),
            finding(
                "DEMO/DLV-LST-3",
                "unitBuildsNothing",
                "generation unit \"u_a\" builds neither a deploymentTarget nor a component"
            ),
        ]
    );
}

#[test]
fn phase8_follows_the_derived_values_and_precedes_annotations() {
    let model = corpus_model();
    let mut d = register();
    d.set_units("DEMO/TTL", "u_x");
    d.set_content("DEMO/SUM", "> ⬆️ **C-1** a\n\n> ⬆️ **C-1** b");
    let codes: Vec<String> = validate_document(&model, &d)
        .into_iter()
        .map(|e| e.code)
        .collect();
    assert_eq!(
        codes,
        vec![
            "unknownUnit".to_string(),
            "duplicateAnnotationId".to_string()
        ]
    );
}

// --- the CodeSpecs extract --------------------------------------------------

fn extract_catalog() -> CodeSpecsAreaCatalog {
    let table = Json::parse(&corpus("codespecs_extract_cases.json")).expect("json");
    CodeSpecsAreaCatalog::from_json(table.get("catalog").expect("catalog")).expect("catalog loads")
}

#[test]
fn extract_carries_the_nearest_stored_units_own_or_inherited() {
    let model = corpus_model();
    let mut d = SpecDocument::new();
    d.set_content("DEMO/TTL", "Hello");
    d.set_content("DEMO/SUM", "Sum");
    let item = d.add_list_item("DEMO/items");
    d.set_content(&format!("{}/label", item), "First");
    d.set_units("DEMO", "app_client");
    d.set_units("DEMO/SUM", "app_shared");
    d.set_units(&item, "app_server, app_shared");
    let extractor =
        CodeSpecsExtractor::for_model(&d, &model, extract_catalog(), None).expect("extractor");
    let extracts = extractor.extract_all().expect("extracts");
    let entries: Vec<_> = extracts.iter().flat_map(|x| x.entries.iter()).collect();
    let by_path = |p: &str| {
        entries
            .iter()
            .find(|e| e.path == p)
            .unwrap_or_else(|| panic!("no entry at {}", p))
    };
    // Inherited from the root.
    assert_eq!(by_path("DEMO/TTL").units, vec!["app_client"]);
    // The entry's own path wins over every ancestor.
    assert_eq!(by_path("DEMO/SUM").units, vec!["app_shared"]);
    // Through the list item, split at its commas and trimmed.
    assert_eq!(
        by_path(&format!("{}/label", item)).units,
        vec!["app_server", "app_shared"]
    );
}

#[test]
fn extract_writes_units_only_where_set_and_reads_them_back() {
    let model = corpus_model();
    let mut d = SpecDocument::new();
    d.set_content("DEMO/TTL", "Hello");
    d.set_content("DEMO/SUM", "Sum");
    d.set_units("DEMO/TTL", "app_client,app_server");
    let extractor =
        CodeSpecsExtractor::for_model(&d, &model, extract_catalog(), None).expect("extractor");
    let extract = extractor
        .extract_all()
        .expect("extracts")
        .into_iter()
        .find(|x| x.area.code == "CE-FM")
        .expect("a CE-FM extract");
    let yaml = extract.to_yaml();
    assert!(
        yaml.contains(
            "      routingNote: \"the demo capture screen and its view state\"\n\
             \x20     units: [\"app_client\", \"app_server\"]\n\
             \x20     value: \"Hello\"\n"
        ),
        "{}",
        yaml
    );
    assert_eq!(yaml.matches("units:").count(), 1);
    assert!(
        extract.to_markdown().contains(
            "- routed by: `CodeSpecPart.form` declared on `Demo`\n\
             - units: `app_client`, `app_server`\n"
        ),
        "{}",
        extract.to_markdown()
    );
    let back = CodeSpecsExtract::from_yaml(&yaml, "CE-FM.extract.yaml").expect("reads back");
    let ttl = back
        .entries
        .iter()
        .find(|e| e.path == "DEMO/TTL")
        .expect("TTL");
    assert_eq!(ttl.units, vec!["app_client", "app_server"]);
    assert!(back
        .entries
        .iter()
        .filter(|e| e.path != "DEMO/TTL")
        .all(|e| e.units.is_empty()));
    assert_eq!(back.to_yaml(), yaml);
}

// --- the register (spec_generation_units) ---------------------------------

#[test]
fn register_units_in_register_order_each_with_its_own_mappings() {
    let model = corpus_model();
    let mut d = register();
    d.set_form_field("DEMO/DLV-LST-1/content", "kind", "client");
    for (unit, area, mapping) in [
        ("DEMO/DLV-LST-1", "CE-NV", "dart-tom"),
        ("DEMO/DLV-LST-1", "CE-TX", " ts-react "),
        ("DEMO/DLV-LST-2", "CE-NV", "dart-tom"),
    ] {
        let r = d.add_list_item(&format!("{}/DLR-LST", unit));
        d.set_form_field(&format!("{}/content", r), "area", area);
        d.set_form_field(&format!("{}/content", r), "mapping", mapping);
    }
    let units = spec_generation_units(&model, &d);
    let ids: Vec<&str> = units.iter().map(|u| u.unit_id.as_str()).collect();
    assert_eq!(ids, vec!["u_a", "u_b"]);
    assert_eq!(units[0].kind, "client");
    assert_eq!(units[0].path, "DEMO/DLV-LST-1");
    let first: Vec<(&str, &str)> = units[0]
        .mappings
        .iter()
        .map(|m| (m.area.as_str(), m.mapping.as_str()))
        .collect();
    assert_eq!(first, vec![("CE-NV", "dart-tom"), ("CE-TX", "ts-react")]);
    assert_eq!(units[0].mapping_for("CE-TX"), Some("ts-react"));
    assert_eq!(units[1].mapping_for("CE-TX"), None);
    assert_eq!(spec_default_units(&units, "CE-NV"), vec!["u_a", "u_b"]);
    assert_eq!(spec_default_units(&units, "CE-TX"), vec!["u_a"]);
    assert!(spec_default_units(&units, "CE-DB").is_empty());
}

#[test]
fn register_a_unit_without_an_id_and_a_second_unit_of_one_id_are_left_out() {
    let model = corpus_model();
    let mut d = register();
    d.add_list_item("DEMO/DLV-LST");
    let dup = d.add_list_item("DEMO/DLV-LST");
    d.set_form_field(&format!("{}/content", dup), "unitId", "u_a");
    let ids: Vec<String> = spec_generation_units(&model, &d)
        .into_iter()
        .map(|u| u.unit_id)
        .collect();
    assert_eq!(ids, vec!["u_a", "u_b"]);
}

#[test]
fn register_a_document_without_a_register_declares_none() {
    let model = corpus_model();
    assert!(spec_generation_units(&model, &SpecDocument::new()).is_empty());
}
