//! The document set (`spec_document_set.rs`, `tom_specs_model_rules.md`
//! §9.7): `SpecDocumentSet`, `sync_report` and `rename_id`.
//!
//! The shared corpus (`document_set_cases.json`) pins the canonical JSON of
//! the construction, the report and the rename; this test holds the Rust
//! surface it does not: the accessors of the set (by type name and by section
//! id, `get`, `put` replacing a document), the typed report (`counts_by_code`,
//! `counts_by_resolution`, `is_info`), the refusals as errors with their
//! fields, a refused rename changing nothing, and the comparison helpers
//! (typed sameness, ids, value keys). Mirrors the Go runtime's
//! `spec_document_set_test.go`.

mod set_support;

use set_support::{case_named, case_set, documents, json_eq, table, table_model};
use tom_som_rust_runtime::{
    rename_id, spec_link_ids, spec_set_is_pending, spec_set_reviewed, spec_set_same_typed,
    spec_set_strip_kind, sync_report, FormFieldSpec, SpecDocument, SpecDocumentSet,
    SpecDocumentSetRefusal, SpecSyncCode, SpecSyncHolder, SpecSyncResolution,
};

#[test]
fn document_set_accessors() {
    let t = table("document_set_cases.json");
    let model = table_model(&t);
    let docs = documents(case_named(&t, "construction", "the base set"));
    let given: Vec<SpecDocument> = docs.iter().map(|(_, d)| d.clone()).collect();
    let mut s = SpecDocumentSet::new(&model, docs).expect("set");
    assert_eq!(s.blueprint_root, "Blueprint");
    let same =
        |a: Option<&SpecDocument>, b: &SpecDocument| a.is_some_and(|a| a.to_json() == b.to_json());
    assert!(same(s.blueprint(), &given[0]));
    assert!(same(s.document("Detail"), &given[1]));
    assert!(same(s.document("DET"), &given[1]));
    assert_eq!(s.name_of("SCR").as_deref(), Some("screens"));
    assert_eq!(s.name_of("Nope"), None);
    assert!(same(s.get("detail"), &given[1]));
    assert!(s.get("nope").is_none());
    assert_eq!(s.root_of("screens"), "Screens");
    let ids: Vec<&str> = s.pairs().iter().map(|p| p.section_id.as_str()).collect();
    assert_eq!(ids, ["REQS", "ACC", "CRIT"]);
    assert_eq!(
        (
            s.pairs()[0].blueprint_anchor.as_str(),
            s.pairs()[0].detail_anchor.as_str()
        ),
        ("BLU/requirements", "DET/requirements")
    );
    assert!(s.pairs()[0].sync.is_some());
    // `put` replaces the document of the same name.
    let mut other = given[1].clone();
    other.set_content("DET/requirements/REQ-ITEM-LST-1/REQAB", "Changed.");
    s.put("detail", other.clone()).expect("put");
    assert!(same(s.get("detail"), &other));
    assert_eq!(s.names(), ["blueprint", "detail", "screens"]);
    // An empty set knows its pairs and every Phase 3 root as missing.
    let empty = SpecDocumentSet::new(&model, Vec::new()).expect("empty");
    assert!(empty.names().is_empty());
    assert_eq!(empty.missing_roots(), ["Detail", "Screens"]);
    assert_eq!(empty.pairs().len(), 3);
}

#[test]
fn document_set_refusals() {
    let t = table("document_set_cases.json");
    let model = table_model(&t);
    let same = case_named(&t, "construction", "two documents of one root");
    let e = SpecDocumentSet::new(&model, documents(same)).expect_err("sameRoot");
    assert_eq!(e.refusal, SpecDocumentSetRefusal::SameRoot);
    let want = same
        .get("expect")
        .and_then(|x| x.get("refused"))
        .expect("refused");
    assert!(json_eq(&e.to_json(), want));
    assert!(e
        .to_string()
        .starts_with("SpecDocumentSetError(sameRoot): "));

    let unp = case_named(&t, "construction", "a synced class whose positions");
    let meta = tom_som_rust_runtime::SpecModel::from_json(unp.get("meta").expect("meta"));
    let e = SpecDocumentSet::new(&meta, documents(unp)).expect_err("unpairable");
    assert_eq!(e.refusal, SpecDocumentSetRefusal::Unpairable);
    assert!(!e.class_name.is_empty());

    // `put` refuses an empty document.
    let mut s = SpecDocumentSet::new(&model, Vec::new()).expect("empty");
    let e = s.put("x", SpecDocument::new()).expect_err("noRoot");
    assert_eq!(e.refusal, SpecDocumentSetRefusal::NoRoot);
}

#[test]
fn sync_report_typed() {
    let t = table("document_set_cases.json");
    let model = table_model(&t);
    let c = case_named(&t, "reports", "an enum value differs");
    let r = sync_report(&case_set(&model, c), None);
    assert!(!r.clean());
    assert_eq!(r.counts_by_code(), [(SpecSyncCode::SharedValueDiffers, 1)]);
    assert_eq!(
        r.counts_by_resolution(),
        [(SpecSyncResolution::Backfill, 1)]
    );
    let f = &r.findings[0];
    assert_eq!(f.pair, "REQS");
    assert_eq!(f.holder, SpecSyncHolder::Detail);
    assert!(!f.is_info());
    assert_eq!(
        (f.blueprint.value.as_deref(), f.detail.value.as_deref()),
        (Some("approved"), Some("done"))
    );
    assert_eq!(f.blueprint.field, "status");
    let names: Vec<&str> = r
        .document_findings
        .iter()
        .map(|d| d.name.as_str())
        .collect();
    assert_eq!(names, ["blueprint", "detail", "screens"]);
    assert!(json_eq(&r.to_json(), c.get("expect").expect("expect")));
    // Scoped to another pair, the finding is left out.
    let scoped = sync_report(&case_set(&model, c), Some(&["ACC".to_string()]));
    assert!(scoped.findings.is_empty());
    let pending = sync_report(
        &case_set(
            &model,
            case_named(&t, "reports", "a value holding a pending change"),
        ),
        None,
    );
    assert!(pending.clean());
    assert!(!pending.findings.is_empty() && pending.findings.iter().all(|f| f.is_info()));
}

#[test]
fn rename_id_changes_and_refuses() {
    let t = table("document_set_cases.json");
    let model = table_model(&t);
    let ok = case_named(&t, "renames", "an id renamed");
    let mut s = case_set(&model, ok);
    let (from, to) = (ok.str_or("from"), ok.str_or("to"));
    let changes = rename_id(&mut s, &from, &to).expect("rename");
    assert_eq!(
        (
            changes[0].kind.as_str(),
            changes[0].old_value.as_str(),
            changes[0].new_value.as_str()
        ),
        ("sectionId", from.as_str(), to.as_str())
    );
    let again = rename_id(&mut s, &from, "REQ-OTHER").expect("again");
    assert!(again.is_empty());

    let refused = case_named(&t, "renames", "a rename onto an id");
    let mut s = case_set(&model, refused);
    let before: Vec<_> = s
        .names()
        .iter()
        .map(|n| s.get(n).map(|d| d.to_json()))
        .collect();
    let e = rename_id(&mut s, &refused.str_or("from"), &refused.str_or("to")).expect_err("refused");
    let want: Vec<String> = refused
        .get("expect")
        .and_then(|x| x.get("refused"))
        .and_then(|x| x.as_array())
        .unwrap_or(&[])
        .iter()
        .filter_map(|x| x.as_str().map(str::to_string))
        .collect();
    assert_eq!(e.documents, want);
    assert!(e.to_string().starts_with("SpecRenameError: "));
    let after: Vec<_> = s
        .names()
        .iter()
        .map(|n| s.get(n).map(|d| d.to_json()))
        .collect();
    assert_eq!(after, before);
}

#[test]
fn document_set_helpers() {
    let typed = |t: &str| FormFieldSpec {
        name: "n".to_string(),
        type_: t.to_string(),
        ..FormFieldSpec::default()
    };
    let dbl = typed("double");
    assert!(spec_set_same_typed("2", "2.0", Some(&dbl)));
    assert!(spec_set_same_typed("0x10", "16", Some(&dbl)));
    assert!(!spec_set_same_typed("NaN", "NaN", Some(&dbl)));
    assert!(!spec_set_same_typed("2", "2.0", None));
    assert!(spec_set_same_typed("True", "true", Some(&typed("bool"))));
    assert_eq!(spec_link_ids(" A, ,B ,C"), ["A", "B", "C"]);
    assert_eq!(
        spec_set_strip_kind("f:LIST[X]/content#status"),
        "LIST[X]/content"
    );
    assert_eq!(spec_set_strip_kind("i:LIST[X]"), "LIST[X]");
    assert_eq!(spec_set_reviewed(" a {++b ++}"), "a");
    assert!(spec_set_is_pending("a {++b++}"));
    assert!(!spec_set_is_pending("a b"));
    assert_eq!(SpecSyncCode::SharedValueDiffers.index(), 0);
    assert_eq!(SpecSyncCode::Unmarkable.index(), 9);
    assert_eq!(SpecSyncCode::from_name("nope"), None);
    assert_eq!(
        SpecSyncCode::from_name("pendingReview"),
        Some(SpecSyncCode::PendingReview)
    );
}

#[test]
fn document_set_load_reads_yaml_and_markdown() {
    let t = table("document_set_cases.json");
    let model = table_model(&t);
    let docs = documents(case_named(&t, "construction", "the base set"));
    let dir = std::path::PathBuf::from(env!("CARGO_TARGET_TMPDIR")).join("spec_document_set_load");
    std::fs::create_dir_all(&dir).expect("dir");
    let mut files = Vec::new();
    for (i, (name, doc)) in docs.iter().enumerate() {
        let root = SpecDocumentSet::new(&model, vec![(name.clone(), doc.clone())])
            .expect("one")
            .roots()
            .remove(0);
        // The first document as SOM Markdown, the others as YAML.
        let (file, text) = if i == 0 {
            let md = doc.to_markdown(&model, Some(&root)).expect("markdown");
            (dir.join(format!("{}.tomspecs.md", name)), md)
        } else {
            let tree = tom_som_rust_runtime::build_som_meta_tree(&model, &root).expect("tree");
            let yaml = tom_som_rust_runtime::encode_yaml(doc, &tree, "").expect("yaml");
            (dir.join(format!("{}.tomspecs.yaml", name)), yaml)
        };
        std::fs::write(&file, text).expect("write");
        files.push(file.to_string_lossy().to_string());
    }
    let s = SpecDocumentSet::load(&model, &files).expect("load");
    let names = s.names();
    assert_eq!(
        names,
        [
            "blueprint.tomspecs.md",
            "detail.tomspecs.yaml",
            "screens.tomspecs.yaml"
        ]
    );
    for (i, (_, doc)) in docs.iter().enumerate().skip(1) {
        assert_eq!(s.get(&names[i]).map(|d| d.to_json()), Some(doc.to_json()));
    }
    assert!(s.blueprint().is_some_and(|b| !b.is_empty()));
    let missing = dir.join("nope.yaml").to_string_lossy().to_string();
    assert!(matches!(
        SpecDocumentSet::load(&model, &[missing]),
        Err(tom_som_rust_runtime::SpecDocumentSetLoadError::Read { .. })
    ));
}
