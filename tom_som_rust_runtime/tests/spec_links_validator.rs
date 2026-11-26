//! The link checks of one document (`spec_links_validator.rs`,
//! `tom_specs_model_rules.md` §9.7), the derived numbers of the instance tier
//! (`spec_derived_numbers`) and the typed reading of a value under review
//! (`som_typed_reading`, the headline field of the review operations).
//!
//! The shared corpus (`link_validation_cases.json`) pins the findings as
//! `{path, code}`; this test holds what it does not: the fixes `deriveFields`
//! reads beside each finding, the finding order and messages, reading the
//! proposal (`read_proposed`), the derived numbers, and a headline refusing a
//! comment block. Mirrors the Go runtime's `spec_links_validator_test.go`.

use std::collections::{BTreeMap, HashMap};
use std::path::PathBuf;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::spec_typed_values::{
    som_parse_bool, som_parse_enum_name, som_parse_int, som_typed_text_readable,
};
use tom_som_rust_runtime::{
    som_is_typed_field, som_typed_reading, spec_derived_numbers, spec_expand_pattern,
    spec_link_ids, spec_validation_code_index, validate_links, DocumentJson, SpecDocument,
    SpecLinkFix, SpecLinkValidator, SpecModel, SpecReviewAnnotations, K_SPEC_HEADLINE_FIELD,
    SPEC_LINK_FIX_COPY, SPEC_VALIDATION_ALL_CODES, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
    SPEC_VALIDATION_CODE_LINK_VALUE_PENDING, SPEC_VALIDATION_CODE_UNMARKABLE,
};

fn corpus(name: &str) -> String {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../tom_som_conformance/corpus")
        .join(name);
    std::fs::read_to_string(path).unwrap_or_else(|e| panic!("read {}: {}", name, e))
}

fn links_model() -> SpecModel {
    SpecModel::from_json_str(&corpus("links.meta.json")).expect("links.meta.json")
}

/// The state of the link-validation case whose name starts with `prefix`.
fn link_case_doc(prefix: &str) -> SpecDocument {
    let table = Json::parse(&corpus("link_validation_cases.json")).expect("parse");
    for c in table.get("cases").and_then(|c| c.as_array()).unwrap_or(&[]) {
        if c.str_or("name").starts_with(prefix) {
            let mut doc = SpecDocument::new();
            doc.load_json(&DocumentJson::from_json(
                c.get("state").unwrap_or(&Json::Null),
            ));
            return doc;
        }
    }
    panic!("no link-validation case {:?}", prefix);
}

fn link_fixes(model: &SpecModel, doc: &SpecDocument, read_proposed: bool) -> Vec<SpecLinkFix> {
    let mut v = SpecLinkValidator::new(model, doc, read_proposed);
    v.run();
    v.fixes
}

#[test]
fn spec_link_fixes() {
    let req1 = "BLU/requirements/REQ-ITEM-LST-1";
    let model = links_model();

    // A derived value not written yet: no finding, but deriveFields writes it.
    let d = link_case_doc("a derived value not written yet");
    assert!(validate_links(&model, &d).is_empty());
    assert_eq!(
        link_fixes(&model, &d, false),
        [SpecLinkFix::set(
            2,
            &format!("{}/REQAB", req1),
            "",
            "Exports use the formats of REQ-IMPORT and never run with REQ-PURGE."
        )]
    );

    // A one-way link not named back: the other end gets the id appended.
    assert_eq!(
        link_fixes(
            &model,
            &link_case_doc("a one-way link not named back"),
            false
        ),
        [SpecLinkFix::append(
            "BLU/acceptance/criteria/CRIT-ITEM-LST-1/content",
            "relatedRequirements",
            "REQ-EXPORT"
        )]
    );

    // A symmetric row without its counterpart: a row is added there; its
    // values keep the order they are written in (value_keys).
    let mut values = BTreeMap::new();
    values.insert("LNK-REF#ref".to_string(), "REQ-EXPORT".to_string());
    values.insert("content#linkType".to_string(), "conflict".to_string());
    let mut add_row =
        SpecLinkFix::add_row(1, "BLU/requirements/REQ-ITEM-LST-3/LNK-ITEM-LST", values);
    add_row.value_keys = vec!["LNK-REF#ref".to_string(), "content#linkType".to_string()];
    assert_eq!(
        link_fixes(
            &model,
            &link_case_doc("a symmetric row without its counterpart"),
            false
        ),
        [add_row]
    );

    // A generated row the text no longer names: removed.
    assert_eq!(
        link_fixes(
            &model,
            &link_case_doc("a generated row the text no longer names"),
            false
        ),
        [SpecLinkFix::remove_row(
            &format!("{}/LNK-ITEM-LST-1", req1),
            false
        )]
    );

    // A copy edited apart from its holder: copied back whole.
    let got = link_fixes(
        &model,
        &link_case_doc("a copy edited apart from its holder"),
        false,
    );
    assert_eq!(got.len(), 1);
    assert_eq!(got[0].kind, SPEC_LINK_FIX_COPY);
    assert_eq!(got[0].path, "BLU/criteriaSummary/criteria");
}

#[test]
fn spec_link_fix_ordered_keys() {
    let mut values = BTreeMap::new();
    values.insert("b".to_string(), "2".to_string());
    values.insert("a".to_string(), "1".to_string());
    let fix = SpecLinkFix::add_row(1, "X", values);
    assert_eq!(
        fix.ordered_value_keys(),
        ["a", "b"],
        "sorted when the order was not recorded"
    );
    let mut t = BTreeMap::new();
    t.insert("Z.y".to_string(), "1".to_string());
    t.insert("A.x".to_string(), "2".to_string());
    let mut list = SpecLinkFix::list("L", vec![t]);
    assert_eq!(list.ordered_tuple_keys(), ["A.x", "Z.y"]);
    list.tuple_keys = vec!["Z.y".to_string(), "A.x".to_string()];
    assert_eq!(list.ordered_tuple_keys(), ["Z.y", "A.x"]);
    assert_eq!(
        SpecLinkFix::set(2, "P", "", "v").to_json().get("field"),
        Some(&Json::Null),
        "content writes field null"
    );
}

#[test]
fn spec_link_findings() {
    let model = links_model();
    let errs = validate_links(&model, &link_case_doc("a copy differing from its source"));
    assert_eq!(errs.len(), 1);
    assert_eq!(errs[0].code, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH);
    assert!(
        errs[0].message.contains("is derived (copy of"),
        "{}",
        errs[0].message
    );
    // Sorted by path, then by code in declaration order.
    let errs = validate_links(
        &model,
        &link_case_doc("an id named in a generate-mode text"),
    );
    assert!(
        errs.windows(2).all(|w| w[0].path <= w[1].path),
        "not sorted by path: {:?}",
        errs
    );
    // A value holding a pending change is read with the mark rejected and
    // listed once; reading the proposal lists nothing.
    let d = link_case_doc("a source holding a pending change");
    let pending = validate_links(&model, &d)
        .iter()
        .filter(|e| e.code == SPEC_VALIDATION_CODE_LINK_VALUE_PENDING)
        .count();
    assert_eq!(pending, 1);
    let mut v = SpecLinkValidator::new(&model, &d, true);
    v.run();
    assert!(v
        .errors
        .iter()
        .all(|e| e.code != SPEC_VALIDATION_CODE_LINK_VALUE_PENDING));
}

#[test]
fn spec_link_expand_and_ids() {
    let d = link_case_doc("a clean Blueprint");
    assert_eq!(
        spec_expand_pattern(&d, "BLU/requirements/REQ-ITEM-LST-*/REQD"),
        [
            "BLU/requirements/REQ-ITEM-LST-1/REQD",
            "BLU/requirements/REQ-ITEM-LST-2/REQD",
            "BLU/requirements/REQ-ITEM-LST-3/REQD",
        ]
    );
    assert_eq!(
        spec_expand_pattern(&d, "BLU/requirements"),
        ["BLU/requirements"]
    );
    assert_eq!(spec_link_ids(" A, ,B ,"), ["A", "B"]);
    assert_eq!(
        spec_validation_code_index(SPEC_VALIDATION_CODE_UNMARKABLE),
        SPEC_VALIDATION_ALL_CODES.len() as i64 - 1
    );
    assert_eq!(spec_validation_code_index("nope"), -1);
}

#[test]
fn spec_derived_numbers_count_and_read_marks() {
    let model = links_model();
    let base = "BLU/requirements";
    let mut d = SpecDocument::new();
    for status in ["approved", "done", "draft"] {
        let item = d.add_list_item(&format!("{}/REQ-ITEM-LST", base));
        d.set_form_field(&format!("{}/content", item), "status", status);
    }
    d.set_form_field(&format!("{}/REQS-SUM", base), "total", "1");
    let numbers = |d: &SpecDocument, read_proposed: bool| -> HashMap<String, String> {
        spec_derived_numbers(&model, d, read_proposed)
            .into_iter()
            .map(|n| (format!("{}#{}", n.path, n.field), n.value))
            .collect()
    };
    let got = numbers(&d, false);
    assert_eq!(got[&format!("{}/REQS-SUM#total", base)], "3");
    assert_eq!(got[&format!("{}/REQS-SUM#settled", base)], "2");
    // A count reading a pending mark: rejected by default, accepted with
    // read_proposed.
    d.set_form_field(
        &format!("{}/REQ-ITEM-LST-3/content", base),
        "status",
        "{~~draft~>done~~}",
    );
    assert_eq!(
        numbers(&d, false)[&format!("{}/REQS-SUM#settled", base)],
        "2"
    );
    assert_eq!(
        numbers(&d, true)[&format!("{}/REQS-SUM#settled", base)],
        "3"
    );
}

#[test]
fn som_typed_reading_reads_the_old_value() {
    assert_eq!(som_typed_reading("30"), "30");
    assert_eq!(som_typed_reading(""), "");
    assert_eq!(som_typed_reading("{~~ 30 ~> 15 ~~}"), "30");
    assert_eq!(som_typed_reading("{++15++}"), "");
    assert_eq!(som_parse_int(Some("{~~30~>15~~}")), Some(30));
    assert_eq!(som_parse_bool(Some("{~~true~>false~~}")), Some(true));
    let values = vec!["low".to_string(), "high".to_string()];
    assert_eq!(
        som_parse_enum_name(Some("{~~high~>low~~}"), &values),
        Some("high".to_string())
    );
    assert!(
        som_typed_text_readable(Some("int"), Some("{~~30~>lots~~}")),
        "a marked int is read by its old value"
    );
    assert!(som_is_typed_field("String", &["a".to_string()]));
    assert!(som_is_typed_field("int?", &[]));
    assert!(!som_is_typed_field("String", &[]));
}

#[test]
fn review_headline_field() {
    let mut d = SpecDocument::new();
    d.set_headline("BLU/requirements", "Requirements {++and links++}");
    {
        let mut api = SpecReviewAnnotations::with_clock(&mut d, None, || {
            "2026-11-07T14:05+01:00".to_string()
        });
        let marks = api.list_marks(None);
        assert_eq!(marks.len(), 1);
        assert_eq!(marks[0].path, "BLU/requirements");
        assert_eq!(marks[0].field.as_deref(), Some(K_SPEC_HEADLINE_FIELD));
        assert!(api
            .insert_comment(
                "BLU/requirements",
                Some(K_SPEC_HEADLINE_FIELD),
                0,
                "x",
                None,
                None,
                None
            )
            .is_err());
        api.accept_all_marks(None);
    }
    assert_eq!(d.headline_or("BLU/requirements"), "Requirements and links");
}
