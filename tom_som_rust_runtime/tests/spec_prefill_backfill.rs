//! `prefill` and `backfill` (`spec_prefill.rs`, `spec_backfill.rs`): the
//! Blueprint into a new Phase 3 document (BP-8), and the accepted Phase 3 end
//! state back into the Blueprint (DP-part-operations-2).
//!
//! The shared corpus (`prefill_cases.json`, `backfill_cases.json`) pins the
//! canonical JSON of each run; this test holds the Rust surface it does not:
//! the created document joining the set under its default name, the typed
//! results (`filled_pairs`, `skipped_pairs`, `derived`, `findings`;
//! `changes`, `left`), the refusals as errors with their codes and places, the
//! revision entry's version bump and default author, and the dry run leaving
//! the set's Blueprint alone. Mirrors the Go runtime's
//! `spec_prefill_backfill_test.go`.

mod set_support;

use set_support::{case_named, case_set, json_eq, table, table_model};
use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::{
    backfill, prefill, spec_backfill_bump, sync_report, SpecBackfillChange, SpecBackfillChangeKind,
    SpecBackfillErrorCode, SpecBackfillLeftReason, SpecBackfillOptions, SpecDocumentSet,
    SpecPrefillErrorCode, SpecPrefillOptions, SpecSyncCode,
};

#[test]
fn prefill_creates_fills_and_refuses() {
    let t = table("prefill_cases.json");
    let model = table_model(&t);
    let mut s = case_set(&model, case_named(&t, "cases", "a new Screens document"));
    assert_eq!(s.missing_roots(), ["Screens"]);
    let r = prefill(&mut s, "SCR", &SpecPrefillOptions::default()).expect("prefill");
    assert_eq!(r.name, "Screens");
    assert!(r.created);
    assert_eq!(
        s.get("Screens").map(|d| d.to_json()),
        Some(r.document.to_json())
    );
    assert_eq!(r.filled_pairs, ["ACC"]);
    assert!(r.skipped_pairs.is_empty());
    assert!(s.missing_roots().is_empty());
    let again = prefill(&mut s, "Screens", &SpecPrefillOptions::default()).expect("again");
    assert!(!again.created);
    assert!(again.filled_pairs.is_empty());
    assert_eq!(again.skipped_pairs, ["ACC"]);
    assert!(again.derived.changes.is_empty());

    let mut named = case_set(&model, case_named(&t, "cases", "a new Detail document"));
    let r = prefill(
        &mut named,
        "Detail",
        &SpecPrefillOptions {
            name: "detail.tomspecs.yaml".to_string(),
            pairs: None,
        },
    )
    .expect("named");
    assert_eq!(
        named.names(),
        ["blueprint", "detail.tomspecs.yaml", "screens"]
    );
    assert!(!r.derived.changes.is_empty());
    for (code, _) in sync_report(&named, None).counts_by_code() {
        assert!(
            !code.name().starts_with("shared"),
            "agrees: {}",
            code.name()
        );
    }

    let mut no_bp = case_set(
        &model,
        case_named(&t, "cases", "a set without the Blueprint"),
    );
    let e = prefill(&mut no_bp, "DET", &SpecPrefillOptions::default()).expect_err("noBlueprint");
    assert_eq!(e.code, SpecPrefillErrorCode::NoBlueprint);
    let mut own = case_set(&model, case_named(&t, "cases", "the Blueprint's own root"));
    let e = prefill(&mut own, "BLU", &SpecPrefillOptions::default()).expect_err("unknownRoot");
    assert_eq!(e.code, SpecPrefillErrorCode::UnknownRoot);
    assert!(e.to_string().starts_with("SpecPrefillError(unknownRoot): "));
    let e = prefill(&mut own, "Nope", &SpecPrefillOptions::default()).expect_err("unknown");
    assert_eq!(e.code, SpecPrefillErrorCode::UnknownRoot);
}

#[test]
fn backfill_writes_leaves_and_refuses() {
    let model = table_model(&table("prefill_cases.json"));
    let t = table("backfill_cases.json");

    let mut s = case_set(&model, case_named(&t, "cases", "a differing enum value"));
    let r = backfill(
        &mut s,
        &SpecBackfillOptions {
            author: "agent_spec_author".to_string(),
            date: "2026-11-24".to_string(),
            ..SpecBackfillOptions::default()
        },
    )
    .expect("backfill");
    assert_eq!(
        s.blueprint().map(|d| d.to_json()),
        Some(r.blueprint.to_json())
    );
    let kinds: Vec<SpecBackfillChangeKind> = r.changes.iter().map(|c| c.kind).collect();
    assert_eq!(
        kinds,
        [
            SpecBackfillChangeKind::Value,
            SpecBackfillChangeKind::Revision
        ]
    );
    assert_eq!(
        (
            r.changes[0].pair.as_str(),
            r.changes[0].old_value.as_str(),
            r.changes[0].new_value.as_str()
        ),
        ("REQS", "approved", "done")
    );
    let rev = format!("{}/content", r.changes[1].path);
    assert_eq!(r.changes[1].new_value, "1.1");
    let bp = s.blueprint().expect("blueprint");
    assert_eq!(bp.form_field_or(&rev, "author"), "agent_spec_author");
    assert_eq!(
        bp.form_field_or(&rev, "summary"),
        "Backfilled from detail, screens: REQS"
    );
    assert!(sync_report(&s, None).clean());
    let again = backfill(&mut s, &SpecBackfillOptions::default()).expect("again");
    assert!(again.changes.is_empty());

    // The default author; the default date is today's.
    let mut d = case_set(
        &model,
        case_named(&t, "cases", "a value the Blueprint leaves empty"),
    );
    let r = backfill(&mut d, &SpecBackfillOptions::default()).expect("defaults");
    let rev = r
        .changes
        .iter()
        .find(|c| c.kind == SpecBackfillChangeKind::Revision)
        .map(|c| format!("{}/content", c.path))
        .expect("revision");
    let bp = d.blueprint().expect("blueprint");
    assert_eq!(bp.form_field_or(&rev, "author"), "backfill");
    let date = bp.form_field_or(&rev, "date");
    assert!(date.len() == 10 && date.as_bytes()[4] == b'-' && date.as_bytes()[7] == b'-');

    let mut dry = case_set(&model, case_named(&t, "cases", "a dry run writes a copy"));
    let before = dry.blueprint().map(|d| d.to_json());
    let r = backfill(
        &mut dry,
        &SpecBackfillOptions {
            dry_run: true,
            ..SpecBackfillOptions::default()
        },
    )
    .expect("dry");
    assert_eq!(dry.blueprint().map(|d| d.to_json()), before);
    assert_ne!(Some(r.blueprint.to_json()), before);
    assert!(!r.changes.is_empty());

    let mut held_set = case_set(&model, case_named(&t, "cases", "a heldHere value"));
    let held = backfill(&mut held_set, &SpecBackfillOptions::default()).expect("held");
    assert!(held.changes.is_empty());
    let reasons: Vec<SpecBackfillLeftReason> = held.left.iter().map(|l| l.reason).collect();
    assert_eq!(reasons, [SpecBackfillLeftReason::HeldHere]);
    assert_eq!(held.left[0].finding.code, SpecSyncCode::SharedValueDiffers);

    let mut marked = case_set(
        &model,
        case_named(&t, "cases", "a set holding an inline mark"),
    );
    let e = backfill(&mut marked, &SpecBackfillOptions::default()).expect_err("marks");
    assert_eq!(e.code, SpecBackfillErrorCode::SetHasMarks);
    assert!(!e.places.is_empty() && e.places[0].document.is_some());
    assert!(e
        .to_string()
        .starts_with("SpecBackfillError(setHasMarks): "));
    let mut empty = SpecDocumentSet::new(&model, Vec::new()).expect("empty");
    let e = backfill(&mut empty, &SpecBackfillOptions::default()).expect_err("noBlueprint");
    assert_eq!(e.code, SpecBackfillErrorCode::NoBlueprint);
}

#[test]
fn backfill_bump_and_json() {
    assert_eq!(spec_backfill_bump(""), "1");
    assert_eq!(spec_backfill_bump("1.2"), "1.3");
    assert_eq!(spec_backfill_bump("v1.9-rc"), "v1.10-rc");
    assert_eq!(spec_backfill_bump("draft"), "draft.1");
    let change = SpecBackfillChange {
        pair: String::new(),
        kind: SpecBackfillChangeKind::Revision,
        path: "B/R-1".to_string(),
        field: String::new(),
        old_value: String::new(),
        new_value: "2".to_string(),
    };
    let want = Json::parse(r#"{"pair":"","kind":"revision","path":"B/R-1","old":"","new":"2"}"#)
        .expect("json");
    assert!(json_eq(&change.to_json(), &want));
}
