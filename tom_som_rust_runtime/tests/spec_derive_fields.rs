//! `derive_fields` (`spec_derive_fields.rs`, `tom_specs_model_rules.md`
//! §9.7): the derived places of one document, written plain or as marks.
//!
//! The shared corpus (`derive_cases.json`) pins the canonical JSON of each
//! run; this test holds the Rust surface it does not: the typed changes
//! (`SpecDeriveChange` with its step, kind, field and values), the dry run
//! answering a copy and leaving the given document alone, the unresolved
//! entries as `SpecValidationError` with their code, and the canonical JSON of
//! a change without a field. Mirrors the Go runtime's
//! `spec_derive_fields_test.go`.

mod set_support;

use std::collections::BTreeSet;

use set_support::{case_named, json_eq, state_document, table, table_model};
use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::{
    derive_fields, validate_links, SpecDeriveChange, SpecDeriveChangeKind, SpecDeriveOptions,
    SpecDocument, SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS, SPEC_VALIDATION_CODE_UNMARKABLE,
};

fn derive_doc(t: &Json, prefix: &str) -> SpecDocument {
    state_document(
        case_named(t, "cases", prefix)
            .get("state")
            .unwrap_or(&Json::Null),
    )
}

#[test]
fn derive_fields_plain_steps() {
    let t = table("derive_cases.json");
    let model = table_model(&t);
    let mut doc = derive_doc(&t, "step 1: a missing symmetric row");
    let r = derive_fields(&model, &mut doc, &SpecDeriveOptions::default());
    assert!(r.document.is_none(), "written in place");
    let first = &r.changes[0];
    assert_eq!(
        (first.step, first.kind, first.field.as_str()),
        (1, SpecDeriveChangeKind::RowAdded, "")
    );
    let steps: BTreeSet<i64> = r.changes.iter().map(|c| c.step).collect();
    assert_eq!(steps.into_iter().collect::<Vec<_>>(), [1, 2]);
    let last = r.changes.last().expect("a change");
    assert_eq!(
        (
            last.kind,
            last.field.as_str(),
            last.old_value.as_str(),
            last.new_value.as_str()
        ),
        (
            SpecDeriveChangeKind::Value,
            "conflictsWith",
            "",
            "REQ-EXPORT"
        )
    );
    assert!(r.unresolved.is_empty());
    assert!(validate_links(&model, &doc).is_empty());
    assert!(
        derive_fields(&model, &mut doc, &SpecDeriveOptions::default())
            .changes
            .is_empty()
    );
}

#[test]
fn derive_fields_dry_run() {
    let t = table("derive_cases.json");
    let model = table_model(&t);
    let mut doc = derive_doc(&t, "a dry run writes nothing");
    let before = doc.to_json();
    let options = SpecDeriveOptions {
        dry_run: true,
        ..SpecDeriveOptions::default()
    };
    let r = derive_fields(&model, &mut doc, &options);
    let copy = r.document.as_ref().expect("a copy");
    assert_eq!(doc.to_json(), before);
    assert!(!r.changes.is_empty());
    assert_ne!(copy.to_json(), before);
    assert_eq!(r.written(&doc).to_json(), copy.to_json());
}

#[test]
fn derive_fields_marked() {
    let t = table("derive_cases.json");
    let model = table_model(&t);
    let mut doc = derive_doc(&t, "under review: every derived value");
    let at = "2026-11-24T10:00+01:00";
    let options = SpecDeriveOptions {
        marked: true,
        author: "agent_spec_author".to_string(),
        at: at.to_string(),
        dry_run: false,
    };
    let r = derive_fields(&model, &mut doc, &options);
    let values: Vec<&SpecDeriveChange> = r
        .changes
        .iter()
        .filter(|c| c.kind == SpecDeriveChangeKind::Value)
        .collect();
    assert!(!values.is_empty());
    for c in values {
        assert!(
            c.new_value.contains('{')
                && c.new_value.contains(&format!("@agent_spec_author {}", at)),
            "marked: {:?}",
            c.new_value
        );
    }
    assert!(derive_fields(&model, &mut doc, &options).changes.is_empty());
}

#[test]
fn derive_fields_unresolved() {
    let t = table("derive_cases.json");
    let model = table_model(&t);
    let mut miss_doc = derive_doc(&t, "a lookup without its row");
    let miss = derive_fields(&model, &mut miss_doc, &SpecDeriveOptions::default());
    assert!(miss
        .unresolved
        .iter()
        .any(|e| e.code == SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS));
    let mut fenced_doc = derive_doc(&t, "under review: a change inside fenced code");
    let fenced = derive_fields(
        &model,
        &mut fenced_doc,
        &SpecDeriveOptions {
            marked: true,
            at: "2026-11-24T10:00+01:00".to_string(),
            ..SpecDeriveOptions::default()
        },
    );
    let codes: Vec<&str> = fenced.unresolved.iter().map(|e| e.code.as_str()).collect();
    assert_eq!(codes, [SPEC_VALIDATION_CODE_UNMARKABLE]);
    let json = fenced.to_json(&fenced_doc);
    let first = json
        .get("unresolved")
        .and_then(|u| u.as_array())
        .and_then(|u| u.first())
        .expect("unresolved");
    assert_eq!(first.str_or("code"), "unmarkable");
}

#[test]
fn derive_change_json() {
    let row = SpecDeriveChange {
        step: 1,
        kind: SpecDeriveChangeKind::RowRemoved,
        path: "A/b-1".to_string(),
        field: String::new(),
        old_value: String::new(),
        new_value: String::new(),
    };
    let want = Json::parse(r#"{"step":1,"kind":"rowRemoved","path":"A/b-1","old":"","new":""}"#)
        .expect("json");
    assert!(json_eq(&row.to_json(), &want));
    let value = SpecDeriveChange {
        step: 3,
        kind: SpecDeriveChangeKind::Value,
        path: "A/c".to_string(),
        field: "n".to_string(),
        old_value: "1".to_string(),
        new_value: "2".to_string(),
    };
    let want =
        Json::parse(r#"{"step":3,"kind":"value","path":"A/c","field":"n","old":"1","new":"2"}"#)
            .expect("json");
    assert!(json_eq(&value.to_json(), &want));
}
