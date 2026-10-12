//! Shared-corpus conformance suite for the Rust generic runtime
//! (`tom_som_rust_runtime`).
//!
//! It loads the language-agnostic conformance corpus produced from the Dart
//! reference (`tom_som_conformance/corpus`) and asserts the Rust port reproduces
//! every golden byte-for-byte and matches every behavioural case:
//!
//!   - model meta-data loads (root + class structure);
//!   - state.json loads and re-serialises identically;
//!   - YAML encode == expected.docspecs.yaml (byte-for-byte, hierarchical v2);
//!   - YAML decode → memory → encode is byte-stable + preserves the stamp and
//!     lands the fixture memory (state.json);
//!   - Markdown export == expected.md, parse round-trips byte-stable, and the
//!     parsed values land the fixture memory (md.export / md.parse.* /
//!     md.land.*), and applying a parsed import overwrites only the roots it
//!     covers (mdApply[…]);
//!   - the YAML `review:` pass: written back sorted and byte-stable, and stale
//!     entries reported (yamlReview[…]);
//!   - the SOM §4.2/§21 editability contract (classification + refusal message);
//!   - reflection resolution cases;
//!   - validation cases;
//!   - the imperative operations script;
//!   - the generic typed editing script (YRD7 `SpecEditor`);
//!   - the SOM §9 search tier: the portable text-pattern subset, the query /
//!     projection surfaces, the lazy cursor over a mutating document, and the
//!     meta-model-validated node-creation gate;
//!   - the Phase-4 CodeSpecs tier: the routing diagnostic, the per-area extracts
//!     with their YAML/Markdown goldens, the "copied, never composed" guard, and
//!     the `ROUTE-TOTAL` error cases;
//!   - reading the CodeSpecs records back: extract files (round-tripping byte
//!     for byte), the gate record (read, written, edited, refused) and the
//!     scoping of a file set by its record (codespecs_record_cases.json);
//!   - the Stage-A CodeSpecs gate, A1–A5, over every case of
//!     codespecs_gate_cases.json;
//!   - the SOM §14 DocSpecs tier (one case per violation rule).
//!
//! `cargo test` is the native runner; exit 0 == all green.

use std::collections::HashSet;
use std::path::PathBuf;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::spec_codespecs_extract::{
    CodeSpecsAreaCatalog, CodeSpecsExtract, CodeSpecsExtractor,
};
use tom_som_rust_runtime::spec_codespecs_gate::{CodeSpecsGate, CodeSpecsGateReport};
use tom_som_rust_runtime::spec_codespecs_records::{
    CodeSpecsExtractSet, CodeSpecsGateEntry, CodeSpecsGateRecord, CodeSpecsGateVerdict,
};
use tom_som_rust_runtime::spec_document::{DocumentJson, SpecDocument};
use tom_som_rust_runtime::spec_document_markdown::{SpecDocumentMarkdown, SpecMarkdownResult};
use tom_som_rust_runtime::spec_document_yaml::{
    decode_yaml, encode_yaml, encode_yaml_with_review, stale_review_paths,
};
use tom_som_rust_runtime::spec_editor::{SomValue, SpecEditor};
use tom_som_rust_runtime::spec_meta::SomMetaTree;
use tom_som_rust_runtime::spec_meta_bridge::build_som_meta_tree;
use tom_som_rust_runtime::spec_model::{
    SpecModel, DEFAULT_MAX_SNAPSHOT_AGE_SECONDS, SECONDS_PER_DAY,
};
use tom_som_rust_runtime::spec_node_creation::{check_add_node, SpecNodeCreator};
use tom_som_rust_runtime::som_facade::{
    check_som_model_version, som_editability_for, SomEditability,
};
use tom_som_rust_runtime::spec_query::{
    SpecQuery, SpecQueryCursor, SpecQueryEngine, SpecQueryMatch, SpecStateFilter,
};
use tom_som_rust_runtime::spec_reflection::SpecReflection;
use tom_som_rust_runtime::spec_section_id::{
    encode_two_letter_date, generate_list_item_section_id, is_collision,
};
use tom_som_rust_runtime::spec_serialization_order::SpecSerializationOrder;
use tom_som_rust_runtime::spec_text_pattern::SomTextPattern;
use tom_som_rust_runtime::spec_validator::validate_document;
use tom_som_rust_runtime::{
    DocSpecsDocument, DocSpecsSchema, DocSpecsValidator, DOCSPECS_ALL_RULES,
};

const MODEL_VERSION: &str = "1.0";

fn corpus_dir() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../tom_som_conformance/corpus")
}

fn read_corpus(name: &str) -> String {
    let path = corpus_dir().join(name);
    std::fs::read_to_string(&path)
        .unwrap_or_else(|e| panic!("read corpus {}: {}", path.display(), e))
}

fn read_json(name: &str) -> Json {
    Json::parse(&read_corpus(name)).unwrap_or_else(|e| panic!("parse corpus {}: {}", name, e))
}

struct Checker {
    passed: usize,
    failed: Vec<String>,
}

impl Checker {
    fn new() -> Checker {
        Checker {
            passed: 0,
            failed: Vec::new(),
        }
    }

    fn check(&mut self, name: &str, cond: bool, detail: &str) {
        if cond {
            self.passed += 1;
        } else if detail.is_empty() {
            self.failed.push(name.to_string());
        } else {
            self.failed.push(format!("{}: {}", name, detail));
        }
    }

    fn finish(&self) {
        let total = self.passed + self.failed.len();
        if !self.failed.is_empty() {
            for f in &self.failed {
                eprintln!("  - {}", f);
            }
            panic!("FAIL: {}/{} checks failed", self.failed.len(), total);
        }
        println!("OK: {} checks passed", total);
    }
}

fn load_model() -> SpecModel {
    SpecModel::from_json(&read_json("model.meta.json"))
}

fn doc_from_state(state: &DocumentJson) -> SpecDocument {
    let mut doc = SpecDocument::new();
    doc.load_json(state);
    doc
}

fn byte_diff(label: &str, actual: &str, expected: &str) -> String {
    if actual == expected {
        return String::new();
    }
    let a_lines: Vec<&str> = actual.split('\n').collect();
    let e_lines: Vec<&str> = expected.split('\n').collect();
    let max = a_lines.len().max(e_lines.len());
    for idx in 0..max {
        let a = a_lines.get(idx).copied().unwrap_or("<EOF>");
        let e = e_lines.get(idx).copied().unwrap_or("<EOF>");
        if a != e {
            return format!(
                "{}: first diff at line {}: got {:?} want {:?}",
                label,
                idx + 1,
                a,
                e
            );
        }
    }
    format!(
        "{}: differ (len got {} want {})",
        label,
        actual.len(),
        expected.len()
    )
}

#[test]
fn conformance() {
    assert!(corpus_dir().is_dir(), "corpus not found at {}", corpus_dir().display());
    let mut c = Checker::new();
    let model = load_model();
    let tree = build_som_meta_tree(&model, "").expect("meta tree");

    test_model_meta(&mut c, &model);
    test_stamp(&mut c, &model);
    test_editability(&mut c);
    test_state_round_trip(&mut c);
    test_yaml_encode(&mut c, &tree);
    test_yaml_decode_round_trip(&mut c, &tree);
    test_markdown_export(&mut c, &model);
    test_markdown_round_trip(&mut c, &model);
    test_markdown_memory_landing(&mut c, &model);
    test_markdown_import_rejections(&mut c, &model);
    test_markdown_apply(&mut c, &model);
    test_assembly(&mut c);
    test_yaml_review(&mut c, &model, &tree);
    test_reflection(&mut c, &model);
    test_validation(&mut c, &model);
    test_operations(&mut c);
    test_editor(&mut c, &model);
    test_section_id(&mut c);
    test_serialization_order(&mut c);
    test_text_pattern(&mut c);
    test_query(&mut c, &model);
    test_projection(&mut c, &model);
    test_codespecs_extract(&mut c, &model);
    test_codespecs_records(&mut c);
    test_codespecs_gate(&mut c);
    test_cursor_script(&mut c, &model);
    test_node_creation_cases(&mut c, &model);
    test_node_creation_script(&mut c, &model);
    test_docspecs(&mut c);
    test_docspecs_replace(&mut c);

    c.finish();
}

fn test_model_meta(c: &mut Checker, model: &SpecModel) {
    let root = &model.roots[0];
    c.check("model.root.sectionId", root.section_id == "DEMO", &root.section_id);
    c.check("model.root.type", root.type_ == "Demo", &root.type_);
    c.check(
        "model.classCount",
        model.classes.len() == 12,
        &model.classes.len().to_string(),
    );
    let demo = model.class_named("Demo");
    c.check("model.Demo.found", demo.is_some(), "");
    if let Some(demo) = demo {
        let names: Vec<&str> = demo.fields.iter().map(|f| f.name.as_str()).collect();
        // `cards` is the card list (CARD-LST) added by the Demo corpus's Card
        // class; `notes` is the fixture's one `section`-kind member.
        let want = [
            "title", "summary", "priority", "count", "ratio", "score", "details", "items", "refs",
            "cards", "meta", "control", "notes", "registry",
        ];
        c.check("model.Demo.fields", names == want, &names.join(","));
    }
}

/// The generation stamp: the five keys the exporter writes, and the staleness
/// verdict every runtime must reach from the same input.
fn test_stamp(c: &mut Checker, model: &SpecModel) {
    // The shared model fixture carries the stamp, minus `containerRoot` (it is a
    // single synthetic document with no container class).
    c.check(
        "stamp.meta.generatedAt",
        model.generated_at == Some(1_784_534_400),
        "",
    );
    c.check(
        "stamp.meta.metaSchemaVersion",
        model.meta_schema_version == Some(1),
        "",
    );
    c.check(
        "stamp.meta.classCount",
        model.class_count == Some(model.classes.len() as i64),
        "",
    );
    c.check(
        "stamp.meta.rootCount",
        model.root_count == Some(model.roots.len() as i64),
        "",
    );
    c.check("stamp.meta.containerRoot", model.container_root.is_empty(), "");

    let table = read_json("stamp_cases.json");
    c.check(
        "stamp.defaultMaxAgeDays",
        table.get("defaultMaxAgeDays").and_then(|v| v.as_i64())
            == Some(DEFAULT_MAX_SNAPSHOT_AGE_SECONDS / SECONDS_PER_DAY),
        "",
    );
    for kase in table
        .get("cases")
        .and_then(|v| v.as_array())
        .unwrap_or(&[])
    {
        let name = kase.str_or("name");
        let loaded = SpecModel::from_json(kase.get("model").expect("case.model"));
        let want = kase.get("expect").expect("case.expect");
        let opt = |v: &Json, k: &str| v.get(k).and_then(|x| x.as_i64());
        c.check(
            &format!("stamp[{}].generatedAt", name),
            loaded.generated_at == opt(want, "generatedAtEpochSeconds"),
            &format!("{:?}", loaded.generated_at),
        );
        c.check(
            &format!("stamp[{}].metaSchemaVersion", name),
            loaded.meta_schema_version == opt(want, "metaSchemaVersion"),
            "",
        );
        c.check(
            &format!("stamp[{}].classCount", name),
            loaded.class_count == opt(want, "classCount"),
            "",
        );
        c.check(
            &format!("stamp[{}].rootCount", name),
            loaded.root_count == opt(want, "rootCount"),
            "",
        );
        c.check(
            &format!("stamp[{}].containerRoot", name),
            loaded.container_root == want.str_or("containerRoot"),
            &loaded.container_root,
        );
        c.check(
            &format!("stamp[{}].actualClassCount", name),
            Some(loaded.classes.len() as i64) == opt(want, "actualClassCount"),
            "",
        );
        c.check(
            &format!("stamp[{}].actualRootCount", name),
            Some(loaded.roots.len() as i64) == opt(want, "actualRootCount"),
            "",
        );

        let wc = kase.get("check").expect("case.check");
        let got = loaded.check_stamp(
            opt(wc, "maxAgeDays").unwrap_or(0) * SECONDS_PER_DAY,
            opt(wc, "nowEpochSeconds").unwrap_or(0),
        );
        c.check(
            &format!("stamp[{}].ageSeconds", name),
            got.age_seconds == opt(wc, "ageSeconds"),
            &format!("{:?}", got.age_seconds),
        );
        for (key, actual) in [
            ("isAged", got.is_aged()),
            ("classCountDisagrees", got.class_count_disagrees()),
            ("rootCountDisagrees", got.root_count_disagrees()),
            ("countsDisagree", got.counts_disagree()),
            ("isStale", got.is_stale()),
        ] {
            c.check(
                &format!("stamp[{}].{}", name, key),
                actual == wc.bool_or(key),
                "",
            );
        }
        let want_warnings: Vec<String> = wc
            .get("warnings")
            .and_then(|v| v.as_array())
            .unwrap_or(&[])
            .iter()
            .map(|v| v.as_str().unwrap_or("").to_string())
            .collect();
        c.check(
            &format!("stamp[{}].warnings", name),
            got.warnings() == want_warnings,
            &got.warnings().join(" | "),
        );
    }
}

/// Maps a corpus token — spelled as the Dart constant name — to the Rust port's
/// own spelling.
fn editability_token(token: &str) -> SomEditability {
    match token {
        "editable" => SomEditability::Editable,
        "readOnlyCrossMajor" => SomEditability::ReadOnlyCrossMajor,
        "rejectedNewerMinor" => SomEditability::RejectedNewerMinor,
        "invalidVersion" => SomEditability::InvalidVersion,
        other => panic!("unknown editability token: {}", other),
    }
}

/// The SOM §4.2/§21 version check. The classifier and the check are one rule
/// seen twice — `rejects` is just "the classification is not editable" — so
/// asserting both is what makes a port that classifies right and refuses wrong
/// fail. The message is pinned because `invalidVersion` is one outcome with two
/// causes, and the message is where they separate. The corpus spells "no stamp"
/// and "no refusal" as JSON null; `str_or` maps both to "" — for the stamp that
/// is exactly the CS4-D2 sentinel this port's non-nullable signature uses.
fn test_editability(c: &mut Checker) {
    let table = read_json("editability_cases.json");
    for kase in table.get("cases").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let name = kase.str_or("name");
        let generated = kase.str_or("generated");
        let document_version = kase.str_or("documentVersion");
        let want = editability_token(&kase.str_or("editability"));
        let got = som_editability_for(&generated, &document_version);
        c.check(
            &format!("editability[{}].classification", name),
            got == want,
            &format!("{:?} != {:?}", got, want),
        );

        let raised = match check_som_model_version(&generated, &document_version) {
            Ok(()) => String::new(),
            Err(e) => e.message,
        };
        c.check(
            &format!("editability[{}].rejects", name),
            !raised.is_empty() == kase.bool_or("rejects"),
            &raised,
        );
        c.check(
            &format!("editability[{}].message", name),
            raised == kase.str_or("message"),
            &raised,
        );
    }
}

fn test_state_round_trip(c: &mut Checker) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let doc = doc_from_state(&state);
    let got = doc.to_json().to_canonical_json();
    let want = state.to_canonical_json();
    c.check(
        "state.toJson",
        got == want,
        &format!("got {} want {}", got, want),
    );
}

fn test_yaml_encode(c: &mut Checker, tree: &SomMetaTree) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let doc = doc_from_state(&state);
    let expected = read_corpus("expected.docspecs.yaml");
    match encode_yaml(&doc, tree, MODEL_VERSION) {
        Ok(actual) => c.check(
            "yaml.encode",
            actual == expected,
            &byte_diff("yaml.encode", &actual, &expected),
        ),
        Err(e) => c.check("yaml.encode", false, &e.to_string()),
    }
}

fn test_yaml_decode_round_trip(c: &mut Checker, tree: &SomMetaTree) {
    let expected = read_corpus("expected.docspecs.yaml");
    let contents = match decode_yaml(&expected, tree) {
        Ok(contents) => contents,
        Err(e) => {
            c.check("yaml.decode", false, &e.to_string());
            return;
        }
    };
    c.check(
        "yaml.decode.stamp",
        contents.model_version == MODEL_VERSION,
        &contents.model_version,
    );
    // The decoded document must land the same memory as the state.json fixture.
    let canonical = DocumentJson::from_json(&read_json("state.json"));
    let got = contents.document.to_json().to_canonical_json();
    let want = canonical.to_canonical_json();
    c.check(
        "yaml.decode.memory",
        got == want,
        &format!("got {} want {}", got, want),
    );
    let stamp = if contents.model_version.is_empty() {
        MODEL_VERSION.to_string()
    } else {
        contents.model_version.clone()
    };
    match encode_yaml(&contents.document, tree, &stamp) {
        Ok(actual) => c.check(
            "yaml.decode.reencode",
            actual == expected,
            &byte_diff("yaml.decode.reencode", &actual, &expected),
        ),
        Err(e) => c.check("yaml.decode.reencode", false, &e.to_string()),
    }
}

// --- markdown conformance (SOM §11) -----------------------------------------

fn test_markdown_export(c: &mut Checker, model: &SpecModel) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let doc = doc_from_state(&state);
    let expected = read_corpus("expected.md");
    match SpecDocumentMarkdown::new(model, &doc).export_root(&model.roots[0]) {
        Ok(actual) => c.check(
            "md.export",
            actual == expected,
            &byte_diff("md.export", &actual, &expected),
        ),
        Err(e) => c.check("md.export", false, &e),
    }
}

fn test_markdown_round_trip(c: &mut Checker, model: &SpecModel) {
    let golden = read_corpus("expected.md");
    let state = DocumentJson::from_json(&read_json("state.json"));
    let doc = doc_from_state(&state);
    let parsed = SpecDocumentMarkdown::new(model, &doc).parse(&golden);
    c.check("md.parse.clean", parsed.rejections.is_empty(), &rej_detail(&parsed));
    let mut re_doc = SpecDocument::new();
    re_doc.load_json(&parsed.to_document_json());
    // YRD3: the stored item id and stored headline round-trip through md.
    c.check(
        "md.parse.storedId",
        re_doc.item_section_id_or("DEMO/REF-LST-1") == "REF-SPEC",
        &re_doc.item_section_id_or("DEMO/REF-LST-1"),
    );
    c.check(
        "md.parse.headline",
        re_doc.headline_or("DEMO/REF-LST-1") == "Reference to the Spec",
        &re_doc.headline_or("DEMO/REF-LST-1"),
    );
    match SpecDocumentMarkdown::new(model, &re_doc).export_root(&model.roots[0]) {
        Ok(actual) => c.check(
            "md.parse.reexport",
            actual == golden,
            &byte_diff("md.parse.reexport", &actual, &golden),
        ),
        Err(e) => c.check("md.parse.reexport", false, &e),
    }
}

// Markdown/YAML convergence: parsing `expected.md` and applying it must
// reproduce `state.json` (the YAML-route memory) exactly, proving both formats
// converge on one in-memory document (SOM §8).
fn test_markdown_memory_landing(c: &mut Checker, model: &SpecModel) {
    let golden = read_corpus("expected.md");
    let canonical = DocumentJson::from_json(&read_json("state.json"));
    let imported = SpecDocument::from_markdown(&golden, model);
    c.check(
        "md.land.clean",
        imported.rejections().is_empty(),
        &rej_detail(&imported.result),
    );
    let got = imported.document.to_json().to_canonical_json();
    let want = canonical.to_canonical_json();
    c.check(
        "md.land.memory",
        got == want,
        &format!("got {} want {}", got, want),
    );
}

/// SOM §11.7: applying a parsed import is a runtime operation. `fromMarkdown`
/// loads a fresh document; `apply` overwrites the covered root of an existing
/// one, keeps every other root, and refuses a result with rejections unless the
/// caller allows them. Each case runs exactly like the Dart reference's
/// `_runMarkdownApplyCase` and is compared field by field with its `expect`.
/// `assembly_cases.json`: [`SpecDocument::assemble`] over ordered fragments,
/// each loaded with `load_json` into a fresh document — the Dart reference's
/// `_runAssemblyCase`. The document split in two must assemble back into
/// `whole`; the other cases pin the refusing rule per store.
fn test_assembly(c: &mut Checker) {
    let table = read_json("assembly_cases.json");
    let canonical = |v: Option<&Json>| match v {
        None | Some(Json::Null) => "null".to_string(),
        Some(v) => DocumentJson::from_json(v).to_canonical_json(),
    };
    for (index, kase) in cases(&table, "cases").iter().enumerate() {
        let tag = format!("assembly[{}]", kase.str_or("name"));
        let mut names = Vec::new();
        let mut docs = Vec::new();
        for pair in kase.get("fragments").and_then(|v| v.as_array()).unwrap_or(&[]) {
            let pair = pair.as_array().unwrap_or(&[]);
            names.push(pair.first().and_then(|v| v.as_str()).unwrap_or("").to_string());
            docs.push(doc_from_state(&DocumentJson::from_json(
                pair.get(1).unwrap_or(&Json::Null),
            )));
        }
        let fragments: Vec<(&str, &SpecDocument)> =
            names.iter().map(|n| n.as_str()).zip(docs.iter()).collect();
        let result = SpecDocument::assemble(&fragments);
        let expect = kase.get("expect").unwrap_or(&Json::Null);

        let want_ok = expect.get("ok").and_then(|v| v.as_bool());
        c.check(
            &format!("{}.ok", tag),
            want_ok == Some(result.ok()),
            &format!("got {} want {:?}", result.ok(), want_ok),
        );
        let got = match &result.document {
            None => "null".to_string(),
            Some(d) => d.to_json().to_canonical_json(),
        };
        let want = canonical(expect.get("document"));
        c.check(
            &format!("{}.document", tag),
            got == want,
            &format!("got {} want {}", got, want),
        );
        let got_overlaps = Json::Array(
            result
                .overlaps
                .iter()
                .map(|o| {
                    obj(vec![
                        ("store", jstr(&o.store)),
                        ("path", jstr(&o.path)),
                        ("field", jopt(&o.field)),
                        ("fragments", jstrs(&o.fragments)),
                        ("message", jstr(&o.message())),
                    ])
                })
                .collect(),
        );
        let want_overlaps = expect.get("overlaps").unwrap_or(&Json::Null);
        c.check(
            &format!("{}.overlaps", tag),
            json_eq(&got_overlaps, want_overlaps),
            &format!("got {:?} want {:?}", got_overlaps, want_overlaps),
        );
        if index == 0 {
            let whole = canonical(table.get("whole"));
            c.check("assembly.whole", got == whole, &format!("got {} want {}", got, whole));
        }
    }
}

fn test_markdown_apply(c: &mut Checker, model: &SpecModel) {
    let table = read_json("markdown_apply_cases.json");
    for kase in table.get("cases").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let name = kase.str_or("name");
        let markdown = kase.str_or("markdown");
        let (refused, rejection_count, document) = if kase.str_or("op") == "fromMarkdown" {
            let imported = SpecDocument::from_markdown(&markdown, model);
            (false, imported.rejections().len(), imported.document.to_json())
        } else {
            let base = DocumentJson::from_json(kase.get("base").unwrap_or(&Json::Null));
            let mut document = doc_from_state(&base);
            let parsed = SpecDocumentMarkdown::new(model, &document).parse(&markdown);
            let allow = kase.get("allowRejections").and_then(|v| v.as_bool()).unwrap_or(false);
            let refused = document.apply_markdown_result(&parsed, allow).is_err();
            (refused, parsed.rejections.len(), document.to_json())
        };
        let expect = kase.get("expect").unwrap_or(&Json::Null);
        let tag = format!("mdApply[{}]", name);
        let want_refused = expect.get("refused").and_then(|v| v.as_bool());
        c.check(
            &format!("{}.refused", tag),
            want_refused == Some(refused),
            &format!("got {} want {:?}", refused, want_refused),
        );
        let want_count = expect.get("rejectionCount").and_then(|v| v.as_i64());
        c.check(
            &format!("{}.rejectionCount", tag),
            want_count == Some(rejection_count as i64),
            &format!("got {} want {:?}", rejection_count, want_count),
        );
        let got = document.to_canonical_json();
        let want = DocumentJson::from_json(expect.get("document").unwrap_or(&Json::Null))
            .to_canonical_json();
        c.check(
            &format!("{}.document", tag),
            got == want,
            &format!("got {} want {}", got, want),
        );
    }
}

/// The `review:` pass: written back sorted and byte-stable, and stale entries
/// (unresolvable paths, removed list items) reported. Each case runs exactly
/// like the Dart reference's `_runYamlReviewCase`: `roundTrip` re-encodes the
/// decoded document with its decoded stamp and review pass; `stale` removes the
/// named list items, then asks which review entries no longer resolve.
fn test_yaml_review(c: &mut Checker, model: &SpecModel, tree: &SomMetaTree) {
    let table = read_json("yaml_review_cases.json");
    for kase in table.get("cases").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let tag = format!("yamlReview[{}]", kase.str_or("name"));
        let mut contents = match decode_yaml(&kase.str_or("yaml"), tree) {
            Ok(contents) => contents,
            Err(e) => {
                c.check(&tag, false, &e.to_string());
                continue;
            }
        };
        if kase.str_or("op") == "roundTrip" {
            let want = kase.str_or("expect");
            match encode_yaml_with_review(
                &contents.document,
                tree,
                &contents.model_version,
                Some(&contents.review),
            ) {
                Ok(got) => c.check(&tag, got == want, &byte_diff(&tag, &got, &want)),
                Err(e) => c.check(&tag, false, &e.to_string()),
            }
            continue;
        }
        for item in kase.get("removeItems").and_then(|v| v.as_array()).unwrap_or(&[]) {
            contents.document.remove_list_item(item.as_str().unwrap_or(""));
        }
        let got = stale_review_paths(model, &contents.document, &contents.review);
        let want: Vec<String> = kase
            .get("expect")
            .and_then(|v| v.as_array())
            .unwrap_or(&[])
            .iter()
            .map(|v| v.as_str().unwrap_or("").to_string())
            .collect();
        c.check(&tag, got == want, &format!("got {:?} want {:?}", got, want));
    }
}

/// The SOM §11.7 rejection protocol: nothing is silently dropped. Each case
/// asserts both halves together — the full `(line, reason, anchor, message)`
/// report *and* the document that still landed. A port that drops an
/// unplaceable block fails the first; one that reports it and abandons the rest
/// of the parse fails the second. The corpus spells "no anchor" as JSON null;
/// `str_or` maps that to "", which is exactly this port's no-anchor sentinel.
fn test_markdown_import_rejections(c: &mut Checker, model: &SpecModel) {
    let table = read_json("markdown_import_cases.json");
    for kase in table.get("cases").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let name = kase.str_or("name");
        let doc = SpecDocument::new();
        let parsed = SpecDocumentMarkdown::new(model, &doc).parse(&kase.str_or("markdown"));
        let want_rejections = kase
            .get("rejections")
            .and_then(|v| v.as_array())
            .unwrap_or(&[]);
        c.check(
            &format!("md.reject[{}].count", name),
            parsed.rejections.len() == want_rejections.len(),
            &rej_detail(&parsed),
        );
        for (i, want) in want_rejections.iter().enumerate() {
            if i >= parsed.rejections.len() {
                break;
            }
            let got = &parsed.rejections[i];
            let tag = format!("md.reject[{}][{}]", name, i);
            c.check(
                &format!("{}.line", tag),
                got.line as i64 == want.get("line").and_then(|v| v.as_i64()).unwrap_or(-1),
                &got.line.to_string(),
            );
            c.check(
                &format!("{}.reason", tag),
                got.reason == want.str_or("reason"),
                &got.reason,
            );
            c.check(
                &format!("{}.anchor", tag),
                got.anchor == want.str_or("anchor"),
                &got.anchor,
            );
            c.check(
                &format!("{}.message", tag),
                got.message == want.str_or("message"),
                &got.message,
            );
        }
        let mut landed = SpecDocument::new();
        landed.load_json(&parsed.to_document_json());
        let got = landed.to_json().to_canonical_json();
        let want = DocumentJson::from_json(kase.get("document").unwrap_or(&Json::Null))
            .to_canonical_json();
        c.check(
            &format!("md.reject[{}].landed", name),
            got == want,
            &format!("got {} want {}", got, want),
        );
    }
}

fn rej_detail(r: &SpecMarkdownResult) -> String {
    r.rejections
        .iter()
        .map(|rej| rej.to_display())
        .collect::<Vec<String>>()
        .join("; ")
}

fn test_reflection(c: &mut Checker, model: &SpecModel) {
    let refl = SpecReflection::new(model);
    let cases = read_json("reflection_cases.json");
    for cc in cases.as_array().unwrap() {
        let path = cc.str_or("path");
        let resolves = cc.bool_or("resolves");
        let res = refl.resolve(&path);
        if !resolves {
            c.check(
                &format!("reflect[{}].none", path),
                res.is_none(),
                "expected no resolution",
            );
            continue;
        }
        let res = match res {
            Some(r) => r,
            None => {
                c.check(
                    &format!("reflect[{}].some", path),
                    false,
                    "expected resolution, got nil",
                );
                continue;
            }
        };
        let want_kind = cc.str_or("kind");
        c.check(
            &format!("reflect[{}].kind", path),
            res.kind == want_kind,
            &format!("{} != {}", res.kind, want_kind),
        );
        let field_name = res.field.as_ref().map(|f| f.name.clone()).unwrap_or_default();
        let want_field = opt_str(cc.get("field"));
        c.check(
            &format!("reflect[{}].field", path),
            opt_eq(&field_name, &want_field),
            &format!("{} != {:?}", field_name, want_field),
        );
        let target = res
            .target_class
            .as_ref()
            .map(|t| t.name.clone())
            .unwrap_or_default();
        let want_target = opt_str(cc.get("targetClass"));
        c.check(
            &format!("reflect[{}].target", path),
            opt_eq(&target, &want_target),
            &format!("{} != {:?}", target, want_target),
        );
        c.check(
            &format!("reflect[{}].leaf", path),
            res.is_value_leaf() == cc.bool_or("isValueLeaf"),
            "",
        );
    }
}

fn test_validation(c: &mut Checker, model: &SpecModel) {
    let cases = read_json("validation_cases.json");
    for cc in cases.as_array().unwrap() {
        let name = cc.str_or("name");
        let state = DocumentJson::from_json(cc.get("state").unwrap());
        let doc = doc_from_state(&state);
        let errs = validate_document(model, &doc);
        let got: Vec<(String, String)> =
            errs.iter().map(|e| (e.path.clone(), e.code.clone())).collect();
        let mut want: Vec<(String, String)> = Vec::new();
        if let Some(arr) = cc.get("errors").and_then(|v| v.as_array()) {
            for e in arr {
                want.push((e.str_or("path"), e.str_or("code")));
            }
        }
        c.check(
            &format!("validate[{}]", name),
            got == want,
            &format!("{:?} != {:?}", got, want),
        );
    }
}

/// The SOM §14 DocSpecs tier: one shared schema, one case per violation rule.
///
/// The corpus carries the rule/sectionId/line triples the Dart reference
/// produces; matching them is what proves this port implements each rule at
/// all, rather than merely declaring its name. `str_or` yields `""` for the
/// corpus's JSON null, which is exactly this port's absent-section-id value.
fn test_docspecs(c: &mut Checker) {
    let schema = DocSpecsSchema::from_yaml_text(&read_corpus("docspecs_schema.yaml"))
        .expect("docspecs schema");
    c.check(
        "docspecs.schemaWarnings",
        schema.warnings.is_empty(),
        &format!("{:?}", schema.warnings),
    );
    c.check(
        "docspecs.rootSectionId",
        schema.root_section_id() == "D00",
        &schema.root_section_id(),
    );

    let validator = DocSpecsValidator::new(schema);
    let cases = read_json("docspecs_cases.json");
    let mut covered: Vec<String> = Vec::new();
    for cc in cases.as_array().unwrap() {
        let name = cc.str_or("name");
        let got: Vec<(String, String, i64)> = validator
            .validate_markdown(&cc.str_or("markdown"))
            .iter()
            .map(|v| (v.rule.clone(), v.section_id.clone(), v.line as i64))
            .collect();
        let mut want: Vec<(String, String, i64)> = Vec::new();
        if let Some(arr) = cc.get("violations").and_then(|v| v.as_array()) {
            for v in arr {
                let rule = v.str_or("rule");
                covered.push(rule.clone());
                want.push((
                    rule,
                    v.str_or("sectionId"),
                    v.get("line").and_then(|l| l.as_i64()).unwrap_or(-1),
                ));
            }
        }
        c.check(
            &format!("docspecs[{}]", name),
            got == want,
            &format!("{:?} != {:?}", got, want),
        );
    }

    let uncovered: Vec<&str> = DOCSPECS_ALL_RULES
        .iter()
        .copied()
        .filter(|r| !covered.iter().any(|got| got == r))
        .collect();
    c.check(
        "docspecs.ruleCoverage",
        uncovered.is_empty(),
        &format!("uncovered: {:?}", uncovered),
    );
}

/// `DocSpecsDocument::replace_section_body` over `docspecs_replace_cases.json`:
/// the error flag must match, and a successful replacement must reproduce the
/// expected text byte for byte.
fn test_docspecs_replace(c: &mut Checker) {
    let table = read_json("docspecs_replace_cases.json");
    for cc in table.get("cases").and_then(|v| v.as_array()).unwrap() {
        let name = cc.str_or("name");
        let expect = cc.get("expect").unwrap();
        let got = DocSpecsDocument::replace_section_body(
            &cc.str_or("markdown"),
            &cc.str_or("sectionId"),
            &cc.str_or("body"),
        );
        let ok = match (&got, expect.bool_or("error")) {
            (Err(_), true) => true,
            (Ok(text), false) => *text == expect.str_or("text"),
            _ => false,
        };
        c.check(&format!("docspecsReplace[{}]", name), ok, &format!("{:?}", got));
    }
}

fn test_operations(c: &mut Checker) {
    let mut doc = SpecDocument::new();
    let cases = read_json("operations_cases.json");
    for (n, op) in cases.as_array().unwrap().iter().enumerate() {
        let op_name = op.str_or("op");
        let tag = format!("op[{}].{}", n, op_name);
        match op_name.as_str() {
            "isEmpty" => {
                let exp = op.get("expect").and_then(|v| v.as_bool()).unwrap_or(false);
                c.check(&tag, doc.is_empty() == exp, "");
            }
            "setContent" => {
                doc.set_content(&op.str_or("path"), &op.str_or("value"));
            }
            "content" => {
                let path = op.str_or("path");
                let val = doc.content(&path).cloned();
                match op.get("expect") {
                    Some(Json::Null) | None => c.check(&tag, val.is_none(), "expected unset"),
                    Some(e) => {
                        let exp = e.as_str().unwrap_or("").to_string();
                        c.check(&tag, val.as_deref() == Some(exp.as_str()), &val.unwrap_or_default());
                    }
                }
            }
            "setFormField" => {
                doc.set_form_field(&op.str_or("path"), &op.str_or("field"), &op.str_or("value"));
            }
            "formField" => {
                let path = op.str_or("path");
                let field = op.str_or("field");
                let val = doc.form_field(&path, &field).cloned();
                match op.get("expect") {
                    Some(Json::Null) | None => c.check(&tag, val.is_none(), "expected unset"),
                    Some(e) => {
                        let exp = e.as_str().unwrap_or("").to_string();
                        c.check(&tag, val.as_deref() == Some(exp.as_str()), &val.unwrap_or_default());
                    }
                }
            }
            "addListItem" => {
                let exp = op.str_or("expect");
                let got = doc.add_list_item(&op.str_or("listPath"));
                c.check(&tag, got == exp, &format!("{} != {}", got, exp));
            }
            "listItems" => {
                let exp: Vec<String> = op
                    .get("expect")
                    .and_then(|v| v.as_array())
                    .map(|a| a.iter().filter_map(|x| x.as_str().map(|s| s.to_string())).collect())
                    .unwrap_or_default();
                let got = doc.list_items(&op.str_or("listPath"));
                c.check(&tag, got == exp, &got.join(","));
            }
            "listItemCount" => {
                let exp = op.get("expect").and_then(|v| v.as_i64()).unwrap_or(0) as usize;
                let got = doc.list_item_count(&op.str_or("listPath"));
                c.check(&tag, got == exp, &got.to_string());
            }
            "hasValuesUnder" => {
                let exp = op.get("expect").and_then(|v| v.as_bool()).unwrap_or(false);
                c.check(&tag, doc.has_values_under(&op.str_or("prefix")) == exp, "");
            }
            "removeListItem" => {
                let exp = op.get("expect").and_then(|v| v.as_bool()).unwrap_or(false);
                c.check(&tag, doc.remove_list_item(&op.str_or("itemPath")) == exp, "");
            }
            "setHeadline" => {
                doc.set_headline(&op.str_or("path"), &op.str_or("value"));
            }
            "headline" => {
                let path = op.str_or("path");
                let val = doc.headline(&path).cloned();
                match op.get("expect") {
                    Some(Json::Null) | None => c.check(&tag, val.is_none(), "expected unset"),
                    Some(e) => {
                        let exp = e.as_str().unwrap_or("").to_string();
                        c.check(&tag, val.as_deref() == Some(exp.as_str()), &val.unwrap_or_default());
                    }
                }
            }
            other => c.check(&format!("{}.unknown", tag), false, other),
        }
    }
}

// --- generic typed editing conformance (YRD7) ------------------------------

/// Converts a corpus JSON value into the editor's boundary value.
///
/// The corpus deliberately distinguishes the integer `2` from the float `2.5`
/// and from the string `"12"`, and `true` from `"not-a-bool"`; the hand-rolled
/// [`Json`] parser keeps `Int` and `Float` apart, so that distinction survives
/// into [`SomValue`] instead of collapsing into one numeric type.
fn som_value_of(v: Option<&Json>) -> Option<SomValue> {
    match v {
        None | Some(Json::Null) => None,
        Some(Json::Int(n)) => Some(SomValue::Int(*n)),
        Some(Json::Float(f)) => Some(SomValue::Double(*f)),
        Some(Json::Bool(b)) => Some(SomValue::Bool(*b)),
        Some(Json::Str(s)) => Some(SomValue::Str(s.clone())),
        Some(other) => panic!("editor corpus value is not a scalar: {:?}", other),
    }
}

/// Compares a read-back typed value against the corpus expectation, variant and
/// all — an `Int` never satisfies a `Float` expectation and vice versa.
fn value_matches(got: &Option<SomValue>, expect: Option<&Json>) -> bool {
    *got == som_value_of(expect)
}

/// Compares a raw store string (`rawContent` / `rawFormField` / `headline` /
/// `itemSectionId`) against the corpus expectation, where JSON `null` means the
/// key is absent — the D4 "empty = no value" state.
fn raw_matches(got: Option<&String>, expect: Option<&Json>) -> bool {
    match expect {
        None | Some(Json::Null) => got.is_none(),
        Some(Json::Str(s)) => got.map(|g| g == s).unwrap_or(false),
        Some(other) => panic!("editor corpus raw expectation is not a string: {:?}", other),
    }
}

/// YRD7: the generic, meta-validated modification API ([`SpecEditor`]) — typed
/// value/form-field round-trips through the shared boundary helpers, enum domain
/// validation, and structural create/clear ops.
///
/// The script is **stateful and ordered**: every step mutates one shared
/// document and later steps depend on earlier ones, so it is replayed in corpus
/// order against a single document — exactly as the Dart and Python runners do.
fn test_editor(c: &mut Checker, model: &SpecModel) {
    let cases = read_json("editor_cases.json");
    let mut doc = SpecDocument::new();
    let mut ed = SpecEditor::for_model(&mut doc, model);
    for (n, s) in cases.as_array().unwrap().iter().enumerate() {
        let op = s.str_or("op");
        let path = s.str_or("path");
        let field = s.str_or("field");
        let expect = s.get("expect");
        let tag = format!("editor[{}].{}", n, op);
        match op.as_str() {
            "setValue" => {
                if let Err(e) = ed.set_value(&path, som_value_of(s.get("value"))) {
                    c.check(&format!("{} {}", tag, path), false, &e);
                }
            }
            "value" => {
                let got = ed.value(&path);
                match got {
                    Ok(got) => c.check(
                        &format!("{} {}", tag, path),
                        value_matches(&got, expect),
                        &format!("{:?}", got),
                    ),
                    Err(e) => c.check(&format!("{} {}", tag, path), false, &e),
                }
            }
            "setValueThrows" => c.check(
                &format!("{} {}", tag, path),
                ed.set_value(&path, som_value_of(s.get("value"))).is_err(),
                "did not error",
            ),
            "valueThrows" => c.check(
                &format!("{} {}", tag, path),
                ed.value(&path).is_err(),
                "did not error",
            ),
            // Raw store write, bypassing the typed boundary.
            "setContent" => ed.document.set_content(&path, &s.str_or("value")),
            "rawContent" => {
                let got = ed.document.content(&path);
                c.check(
                    &format!("{} {}", tag, path),
                    raw_matches(got, expect),
                    &format!("{:?}", got),
                );
            }
            "setFormValue" => {
                if let Err(e) = ed.set_form_value(&path, &field, som_value_of(s.get("value"))) {
                    c.check(&format!("{} {}#{}", tag, path, field), false, &e);
                }
            }
            "formValue" => {
                let got = ed.form_value(&path, &field);
                match got {
                    Ok(got) => c.check(
                        &format!("{} {}#{}", tag, path, field),
                        value_matches(&got, expect),
                        &format!("{:?}", got),
                    ),
                    Err(e) => c.check(&format!("{} {}#{}", tag, path, field), false, &e),
                }
            }
            "setFormValueThrows" => c.check(
                &format!("{} {}#{}", tag, path, field),
                ed.set_form_value(&path, &field, som_value_of(s.get("value")))
                    .is_err(),
                "did not error",
            ),
            "formValueThrows" => c.check(
                &format!("{} {}#{}", tag, path, field),
                ed.form_value(&path, &field).is_err(),
                "did not error",
            ),
            "rawFormField" => {
                let got = ed.document.form_field(&path, &field);
                c.check(
                    &format!("{} {}#{}", tag, path, field),
                    raw_matches(got, expect),
                    &format!("{:?}", got),
                );
            }
            "formFieldNames" => match ed.form_fields(&path) {
                Ok(specs) => {
                    let got: Vec<String> = specs.iter().map(|f| f.name.clone()).collect();
                    let want = str_list(expect);
                    c.check(
                        &format!("{} {}", tag, path),
                        got == want,
                        &format!("{} != {}", got.join(","), want.join(",")),
                    );
                }
                Err(e) => c.check(&format!("{} {}", tag, path), false, &e),
            },
            "formFieldNamesThrows" => c.check(
                &format!("{} {}", tag, path),
                ed.form_fields(&path).is_err(),
                "did not error",
            ),
            "setHeadline" => {
                if let Err(e) = ed.set_headline(&path, s.get("value").and_then(|v| v.as_str())) {
                    c.check(&format!("{} {}", tag, path), false, &e);
                }
            }
            "headline" => match ed.headline(&path) {
                Ok(got) => c.check(
                    &format!("{} {}", tag, path),
                    raw_matches(got.as_ref(), expect),
                    &format!("{:?}", got),
                ),
                Err(e) => c.check(&format!("{} {}", tag, path), false, &e),
            },
            "headlineThrows" => c.check(
                &format!("{} {}", tag, path),
                ed.headline(&path).is_err(),
                "did not error",
            ),
            "itemSectionId" => {
                let item_path = s.str_or("itemPath");
                let got = ed.document.item_section_id(&item_path);
                c.check(
                    &format!("{} {}", tag, item_path),
                    raw_matches(got, expect),
                    &format!("{:?}", got),
                );
            }
            "addListItem" => {
                let list_path = s.str_or("listPath");
                let month = s.get("month").and_then(|v| v.as_i64()).unwrap_or(0);
                let day = s.get("day").and_then(|v| v.as_i64()).unwrap_or(0);
                match ed.add_list_item_on(&list_path, month, day) {
                    Ok(p) => {
                        let want_path = s.str_or("expectPath");
                        c.check(
                            &format!("{} {}", tag, list_path),
                            p == want_path,
                            &format!("{} != {}", p, want_path),
                        );
                        if s.get("expectId").is_some() {
                            let got = ed.document.item_section_id(&p);
                            c.check(
                                &format!("{} id {}", tag, list_path),
                                raw_matches(got, s.get("expectId")),
                                &format!("{:?}", got),
                            );
                        }
                    }
                    Err(e) => c.check(&format!("{} {}", tag, list_path), false, &e),
                }
            }
            "addListItemThrows" => {
                let list_path = s.str_or("listPath");
                let month = s.get("month").and_then(|v| v.as_i64()).unwrap_or(0);
                let day = s.get("day").and_then(|v| v.as_i64()).unwrap_or(0);
                c.check(
                    &format!("{} {}", tag, list_path),
                    ed.add_list_item_on(&list_path, month, day).is_err(),
                    "did not error",
                );
            }
            "removeListItem" => {
                let item_path = s.str_or("itemPath");
                let want = expect.and_then(|v| v.as_bool()).unwrap_or(false);
                c.check(
                    &format!("{} {}", tag, item_path),
                    ed.remove_list_item(&item_path) == want,
                    "",
                );
            }
            "clearSection" => {
                if let Err(e) = ed.clear_section(&path) {
                    c.check(&format!("{} {}", tag, path), false, &e);
                }
            }
            "clearSectionThrows" => c.check(
                &format!("{} {}", tag, path),
                ed.clear_section(&path).is_err(),
                "did not error",
            ),
            "hasValuesUnder" => {
                let prefix = s.str_or("prefix");
                let want = expect.and_then(|v| v.as_bool()).unwrap_or(false);
                c.check(
                    &format!("{} {}", tag, prefix),
                    ed.document.has_values_under(&prefix) == want,
                    "",
                );
            }
            other => c.check(&format!("{}.unknown", tag), false, other),
        }
    }
}

// --- section-id conformance (AA1 criteria 3–6) -----------------------------

fn str_list(v: Option<&Json>) -> Vec<String> {
    v.and_then(|j| j.as_array())
        .map(|a| a.iter().filter_map(|x| x.as_str().map(|s| s.to_string())).collect())
        .unwrap_or_default()
}

fn test_section_id(c: &mut Checker) {
    let cases = read_json("section_id_cases.json");

    // Criterion 4: the two-letter day code.
    for tc in cases.get("twoLetterDate").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let month = tc.get("month").and_then(|v| v.as_i64()).unwrap_or(0);
        let day = tc.get("day").and_then(|v| v.as_i64()).unwrap_or(0);
        let expect = tc.str_or("expect");
        let got = encode_two_letter_date(month, day);
        c.check(
            &format!("sectionId.twoLetterDate[{}/{}]", month, day),
            got == expect,
            &format!("{} != {}", got, expect),
        );
    }

    // Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
    for tc in cases.get("generate").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let pattern = tc.str_or("pattern");
        let month = tc.get("month").and_then(|v| v.as_i64()).unwrap_or(0);
        let day = tc.get("day").and_then(|v| v.as_i64()).unwrap_or(0);
        let existing = str_list(tc.get("existing"));
        let expect = tc.str_or("expect");
        let got = generate_list_item_section_id(&pattern, month, day, &existing);
        c.check(
            &format!("sectionId.generate[{}]", pattern),
            got == expect,
            &format!("{} != {}", got, expect),
        );
    }

    // Criteria 5 & 6 at the document level.
    let mut doc = SpecDocument::new();
    for (i, s) in cases.get("documentOps").and_then(|v| v.as_array()).unwrap_or(&[]).iter().enumerate() {
        let op = s.str_or("op");
        let tag = format!("sectionId.op[{}].{}", i, op);
        match op.as_str() {
            "addGen" => {
                let list_path = s.str_or("listPath");
                let pattern = s.str_or("pattern");
                let month = s.get("month").and_then(|v| v.as_i64()).unwrap_or(0);
                let day = s.get("day").and_then(|v| v.as_i64()).unwrap_or(0);
                let expect_id = s.str_or("expectId");
                let expect_path = s.str_or("expectPath");
                let gen_id = generate_list_item_section_id(
                    &pattern,
                    month,
                    day,
                    &doc.list_item_section_ids(&list_path),
                );
                c.check(
                    &format!("{}.id", tag),
                    gen_id == expect_id,
                    &format!("{} != {}", gen_id, expect_id),
                );
                match doc.add_list_item_with_section_id(&list_path, &gen_id) {
                    Ok(p) => {
                        c.check(
                            &format!("{}.path", tag),
                            p == expect_path,
                            &format!("{} != {}", p, expect_path),
                        );
                    }
                    Err(e) => c.check(&format!("{}.add", tag), false, &e.to_string()),
                }
            }
            "sectionIds" => {
                let exp = str_list(s.get("expect"));
                let got = doc.list_item_section_ids(&s.str_or("listPath"));
                c.check(&tag, got == exp, &format!("{} != {}", got.join(","), exp.join(",")));
            }
            "removeListItem" => {
                let exp = s.get("expect").and_then(|v| v.as_bool()).unwrap_or(false);
                c.check(&tag, doc.remove_list_item(&s.str_or("itemPath")) == exp, "");
            }
            "override" => match doc.set_item_section_id(&s.str_or("itemPath"), &s.str_or("id")) {
                Ok(()) => {}
                Err(e) => c.check(&tag, false, &format!("unexpected error: {}", e)),
            },
            "overrideThrows" => {
                let collided = matches!(
                    doc.set_item_section_id(&s.str_or("itemPath"), &s.str_or("id")),
                    Err(ref e) if is_collision(e)
                );
                c.check(&tag, collided, "expected collision");
            }
            "addExplicitThrows" => {
                let collided = matches!(
                    doc.add_list_item_with_section_id(&s.str_or("listPath"), &s.str_or("id")),
                    Err(ref e) if is_collision(e)
                );
                c.check(&tag, collided, "expected collision");
            }
            other => c.check(&format!("{}.unknown", tag), false, other),
        }
    }
}

// --- serialization-order conformance (AA1 criterion 7) ---------------------

fn test_serialization_order(c: &mut Checker) {
    let cases = read_json("serialization_order_cases.json");
    let model = SpecModel::from_json(cases.get("model").expect("serialization order model"));
    let order = SpecSerializationOrder::new(&model);

    let content_paths = str_list(cases.get("contentPaths"));
    let expected_order = str_list(cases.get("expectedOrder"));
    let got_paths = order.order_paths(&content_paths);
    c.check(
        "serialOrder.orderPaths",
        got_paths == expected_order,
        &format!("{} != {}", got_paths.join(","), expected_order.join(",")),
    );

    let form_fields = str_list(cases.get("formFields"));
    let expected_form_order = str_list(cases.get("expectedFormOrder"));
    let got_fields = order.order_form_fields(&cases.str_or("formPath"), &form_fields);
    c.check(
        "serialOrder.orderFormFields",
        got_fields == expected_form_order,
        &format!("{} != {}", got_fields.join(","), expected_form_order.join(",")),
    );
}

// --- search tier: text pattern / query / projection / creation (SOM §9) ----

/// The portable pattern subset: every committed match list, and every committed
/// compile rejection.
///
/// Spans are **UTF-16 code-unit offsets** (the corpus deliberately carries
/// non-ASCII text), so this port measures in `str::encode_utf16` units rather
/// than Rust byte or `char` indices.
fn test_text_pattern(c: &mut Checker) {
    let cases_json = read_json("pattern_cases.json");
    let cases = cases_json.as_array().expect("pattern_cases.json is a list");

    let mut rejections = 0usize;
    let mut matches = 0usize;
    for (n, tc) in cases.iter().enumerate() {
        let source = tc.str_or("pattern");
        let regex = tc.get("regex").and_then(|v| v.as_bool()).unwrap_or(false);
        let ci = tc
            .get("caseInsensitive")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        let tag = format!("pattern[{}] {:?}", n, source);

        if tc.get("error").and_then(|v| v.as_bool()) == Some(true) {
            rejections += 1;
            // The Dart reference compiles rejections with the default (case
            // sensitive) flag; the flag cannot affect a parse decision.
            match SomTextPattern::compile(&source, false) {
                Ok(_) => c.check(&tag, false, "must be rejected but compiled"),
                Err(_) => c.check(&tag, true, ""),
            }
            continue;
        }
        matches += 1;

        let pattern = if regex {
            match SomTextPattern::compile(&source, ci) {
                Ok(p) => p,
                Err(e) => {
                    c.check(&tag, false, &format!("unexpected rejection: {}", e));
                    continue;
                }
            }
        } else {
            SomTextPattern::literal(&source, ci)
        };

        let text = tc.str_or("text");
        let got: Vec<(usize, usize)> = pattern
            .all_matches(&text)
            .iter()
            .map(|s| (s.start, s.end))
            .collect();
        let want = spans_of(tc.get("spans"));
        c.check(
            &tag,
            got == want,
            &format!("over {:?}: {:?} != {:?}", text, got, want),
        );
    }

    // A table of matches alone would let a port accept everything; a table of
    // rejections alone would let one reject everything.
    c.check("pattern.table.hasRejections", rejections > 0, "");
    c.check("pattern.table.hasMatches", matches > 0, "");
}

/// The query surface: every committed query reproduces its match list **in
/// order**, and `count` independently agrees with that list's length.
///
/// The second assertion is deliberately separate: a port that implements
/// `to_list` by draining but `count` by returning the candidate count passes the
/// first and fails this one.
fn test_query(c: &mut Checker, model: &SpecModel) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let doc = doc_from_state(&state);
    let engine = SpecQueryEngine::for_model(&doc, model);
    let cases_json = read_json("query_cases.json");
    let cases = cases_json.as_array().expect("query_cases.json is a list");

    for tc in cases {
        let name = tc.str_or("name");
        let query = query_from_json(tc.get("query").expect("case has a query"));
        let want = tc
            .get("matches")
            .and_then(|v| v.as_array())
            .expect("case has a match list");

        let mut cursor = match engine.query(query.clone()) {
            Ok(cur) => cur,
            Err(e) => {
                c.check(&format!("query[{}]", name), false, &e.to_string());
                continue;
            }
        };
        let got = cursor.to_list(&engine);
        c.check(
            &format!("query[{}].len", name),
            got.len() == want.len(),
            &format!("{} != {}", got.len(), want.len()),
        );
        for (i, expected) in want.iter().enumerate() {
            let Some(m) = got.get(i) else { break };
            check_query_match(c, &format!("query[{}][{}]", name, i), m, expected);
        }

        // `count` re-validates the *remaining* candidates without consuming, so
        // it is taken from a fresh cursor over the same query.
        let counted = match engine.query(query) {
            Ok(cur) => cur.count(&engine),
            Err(e) => {
                c.check(&format!("query[{}].count", name), false, &e.to_string());
                continue;
            }
        };
        c.check(
            &format!("query[{}].count", name),
            counted == want.len(),
            &format!("{} != {}", counted, want.len()),
        );
    }
}

/// Compares one materialised match against its corpus entry, field by field.
fn check_query_match(c: &mut Checker, tag: &str, got: &SpecQueryMatch, want: &Json) {
    c.check(
        &format!("{}.path", tag),
        got.path == want.str_or("path"),
        &format!("{} != {}", got.path, want.str_or("path")),
    );
    c.check(
        &format!("{}.kind", tag),
        got.kind == want.str_or("kind"),
        &format!("{} != {}", got.kind, want.str_or("kind")),
    );
    c.check(
        &format!("{}.classId", tag),
        got.class_id == opt_str(want.get("classId")),
        &format!("{:?}", got.class_id),
    );
    c.check(
        &format!("{}.headline", tag),
        got.headline == opt_str(want.get("headline")),
        &format!("{:?}", got.headline),
    );
    c.check(
        &format!("{}.snippet", tag),
        got.snippet == opt_str(want.get("snippet")),
        &format!("{:?}", got.snippet),
    );
    let spans: Vec<(usize, usize)> = got.match_spans.iter().map(|s| (s.start, s.end)).collect();
    let want_spans = spans_of(want.get("spans"));
    c.check(
        &format!("{}.spans", tag),
        spans == want_spans,
        &format!("{:?} != {:?}", spans, want_spans),
    );
}

/// The full structural walk in document order — the projection every UI/agent
/// surface reads before it queries anything.
fn test_projection(c: &mut Checker, model: &SpecModel) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let doc = doc_from_state(&state);
    let engine = SpecQueryEngine::for_model(&doc, model);
    let cases_json = read_json("projection_cases.json");
    let want = cases_json
        .as_array()
        .expect("projection_cases.json is a list");
    let got = engine.project_nodes();

    c.check(
        "projection.len",
        got.len() == want.len(),
        &format!("{} != {}", got.len(), want.len()),
    );
    for (i, expected) in want.iter().enumerate() {
        let Some(p) = got.get(i) else { break };
        let tag = format!("projection[{}] {}", i, expected.str_or("path"));
        c.check(
            &format!("{}.path", tag),
            p.path == expected.str_or("path"),
            &p.path,
        );
        c.check(
            &format!("{}.kind", tag),
            p.kind == expected.str_or("kind"),
            &p.kind,
        );
        c.check(
            &format!("{}.classId", tag),
            p.class_id == opt_str(expected.get("classId")),
            &format!("{:?}", p.class_id),
        );
        c.check(
            &format!("{}.sectionId", tag),
            p.section_id == opt_str(expected.get("sectionId")),
            &format!("{:?}", p.section_id),
        );
        c.check(
            &format!("{}.mapsTo", tag),
            p.maps_to == opt_str(expected.get("mapsTo")),
            &format!("{:?}", p.maps_to),
        );
        c.check(
            &format!("{}.detailedIn", tag),
            p.detailed_in == opt_str(expected.get("detailedIn")),
            &format!("{:?}", p.detailed_in),
        );
        c.check(
            &format!("{}.headline", tag),
            p.headline == opt_str(expected.get("headline")),
            &format!("{:?}", p.headline),
        );
        let want_strings = str_list(expected.get("searchableStrings"));
        c.check(
            &format!("{}.searchableStrings", tag),
            p.searchable_strings == want_strings,
            &format!("{:?} != {:?}", p.searchable_strings, want_strings),
        );
        c.check(
            &format!("{}.hasValue", tag),
            Some(p.has_value) == expected.get("hasValue").and_then(|v| v.as_bool()),
            &p.has_value.to_string(),
        );
    }
}

/// The catalogue's authoring-step table as a runtime reads it back: every
/// step's fields, `steps_for` per area, and a catalogue written before the table
/// was transcribed, which must still load with no steps.
fn codespecs_step_cases(catalog_json: &Json) -> Json {
    fn str_array(items: &[String]) -> Json {
        Json::Array(items.iter().map(|s| Json::Str(s.clone())).collect())
    }
    fn steps_by_area(catalog: &CodeSpecsAreaCatalog) -> Json {
        Json::Object(
            catalog
                .areas
                .iter()
                .map(|a| {
                    let numbers =
                        catalog.steps_for(a).iter().map(|s| Json::Int(s.number)).collect();
                    (a.code.clone(), Json::Array(numbers))
                })
                .collect(),
        )
    }
    let catalog = CodeSpecsAreaCatalog::from_json(catalog_json).expect("the catalogue loads");
    let legacy_json = Json::Object(
        catalog_json
            .as_object()
            .expect("the catalogue is an object")
            .iter()
            .filter(|(k, _)| k != "steps")
            .cloned()
            .collect(),
    );
    let legacy = CodeSpecsAreaCatalog::from_json(&legacy_json).expect("the catalogue loads");
    let steps = catalog
        .steps
        .iter()
        .map(|s| {
            Json::Object(vec![
                ("number".to_string(), Json::Int(s.number)),
                ("title".to_string(), Json::Str(s.title.clone())),
                ("slice".to_string(), Json::Int(s.slice)),
                ("placedBy".to_string(), Json::Str(s.placed_by.clone())),
                ("areaCodes".to_string(), str_array(&s.area_codes)),
            ])
        })
        .collect();
    Json::Object(vec![
        ("steps".to_string(), Json::Array(steps)),
        ("stepsByArea".to_string(), steps_by_area(&catalog)),
        (
            "legacy".to_string(),
            Json::Object(vec![
                ("steps".to_string(), Json::Int(legacy.steps.len() as i64)),
                ("areas".to_string(), Json::Int(legacy.areas.len() as i64)),
                ("stepsByArea".to_string(), steps_by_area(&legacy)),
            ]),
        ),
    ])
}

/// The Phase-4 CodeSpecs extract generator: the routing diagnostic, the emitted
/// extracts (including their YAML and Markdown goldens), the "copied, never
/// composed" guard, and the `ROUTE-TOTAL` error cases.
fn test_codespecs_extract(c: &mut Checker, model: &SpecModel) {
    let table = read_json("codespecs_extract_cases.json");
    let catalog = CodeSpecsAreaCatalog::from_json(
        table.get("catalog").expect("codespecs_extract_cases has a catalog"),
    )
    .expect("the catalogue loads");
    let state = DocumentJson::from_json(&read_json("state.json"));
    let doc = doc_from_state(&state);
    let extractor = CodeSpecsExtractor::for_model(&doc, model, catalog.clone(), None)
        .expect("the corpus model resolves to one root");

    // 0. the catalogue's §4.4.6 authoring steps read back as committed — and a
    // catalogue written before the step table was transcribed still loads.
    let got_steps = codespecs_step_cases(
        table.get("catalog").expect("codespecs_extract_cases has a catalog"),
    );
    let want_steps = table.get("stepCases").expect("codespecs_extract_cases has stepCases");
    c.check(
        "codespecs.stepCases",
        &got_steps == want_steps,
        &format!("{:?} != {:?}", got_steps, want_steps),
    );

    // 1. the routing verdicts reproduce the committed diagnostic.
    let got = extractor.routings();
    let want = table
        .get("routings")
        .and_then(|v| v.as_array())
        .expect("codespecs_extract_cases.routings is a list");
    c.check(
        "codespecs.routings.len",
        got.len() == want.len(),
        &format!("{} != {}", got.len(), want.len()),
    );
    for (i, expected) in want.iter().enumerate() {
        let Some(r) = got.get(i) else { break };
        let tag = format!("codespecs.routing[{}] {}", i, expected.str_or("path"));
        c.check(&format!("{}.path", tag), r.path == expected.str_or("path"), &r.path);
        c.check(
            &format!("{}.className", tag),
            r.class_name == expected.str_or("className"),
            &r.class_name,
        );
        c.check(
            &format!("{}.verdict", tag),
            r.verdict.name() == expected.str_or("verdict"),
            r.verdict.name(),
        );
        let want_values = str_list(expected.get("values"));
        c.check(
            &format!("{}.values", tag),
            r.values == want_values,
            &format!("{:?} != {:?}", r.values, want_values),
        );
        let want_note = opt_str(expected.get("note"));
        c.check(
            &format!("{}.note", tag),
            r.note == want_note,
            &format!("{:?} != {:?}", r.note, want_note),
        );
        c.check(
            &format!("{}.declaredAt", tag),
            r.declared_at == expected.str_or("declaredAt"),
            &r.declared_at,
        );
    }

    // 2. the extracts reproduce the committed goldens byte for byte.
    let extracts = match extractor.extract_all() {
        Ok(x) => x,
        Err(e) => {
            c.check("codespecs.extractAll", false, &e.to_string());
            return;
        }
    };
    let want_extracts = table
        .get("extracts")
        .and_then(|v| v.as_array())
        .expect("codespecs_extract_cases.extracts is a list");
    c.check(
        "codespecs.extracts.len",
        extracts.len() == want_extracts.len(),
        &format!("{} != {}", extracts.len(), want_extracts.len()),
    );
    for (i, expected) in want_extracts.iter().enumerate() {
        let Some(x) = extracts.get(i) else { break };
        let tag = format!("codespecs.extract[{}]", expected.str_or("area"));
        c.check(&format!("{}.area", tag), x.area.code == expected.str_or("area"), &x.area.code);
        c.check(
            &format!("{}.canonicalId", tag),
            x.area.canonical_id == expected.str_or("canonicalId"),
            &x.area.canonical_id,
        );
        c.check(
            &format!("{}.part", tag),
            x.area.kind_value() == expected.str_or("part"),
            &x.area.kind_value(),
        );
        c.check(
            &format!("{}.documentRoot", tag),
            x.document_root == expected.str_or("documentRoot"),
            &x.document_root,
        );
        c.check(
            &format!("{}.fileStem", tag),
            x.file_stem() == expected.str_or("fileStem"),
            &x.file_stem(),
        );
        let want_projects = str_list(expected.get("projects"));
        c.check(
            &format!("{}.projects", tag),
            x.projects == want_projects,
            &format!("{:?} != {:?}", x.projects, want_projects),
        );
        let want_citable = str_list(expected.get("citableParts"));
        c.check(
            &format!("{}.citableParts", tag),
            x.citable_parts == want_citable,
            &format!("{:?} != {:?}", x.citable_parts, want_citable),
        );

        let want_entries = expected
            .get("entries")
            .and_then(|v| v.as_array())
            .unwrap_or(&[]);
        c.check(
            &format!("{}.entries.len", tag),
            x.entries.len() == want_entries.len(),
            &format!("{} != {}", x.entries.len(), want_entries.len()),
        );
        for (n, we) in want_entries.iter().enumerate() {
            let Some(e) = x.entries.get(n) else { break };
            let etag = format!("{}.entry[{}]", tag, n);
            c.check(
                &format!("{}.sectionId", etag),
                e.section_id == we.str_or("sectionId"),
                &e.section_id,
            );
            let want_headline = opt_str(we.get("headline"));
            c.check(
                &format!("{}.headline", etag),
                e.headline == want_headline,
                &format!("{:?} != {:?}", e.headline, want_headline),
            );
            let want_instance_id = opt_str(we.get("instanceId"));
            c.check(
                &format!("{}.instanceId", etag),
                e.instance_id == want_instance_id,
                &format!("{:?} != {:?}", e.instance_id, want_instance_id),
            );
            c.check(&format!("{}.path", etag), e.path == we.str_or("path"), &e.path);
            c.check(
                &format!("{}.className", etag),
                e.class_name == we.str_or("className"),
                &e.class_name,
            );
            c.check(
                &format!("{}.fieldName", etag),
                e.field_name == we.str_or("fieldName"),
                &e.field_name,
            );
            let want_form_field = opt_str(we.get("formField"));
            c.check(
                &format!("{}.formField", etag),
                e.form_field == want_form_field,
                &format!("{:?} != {:?}", e.form_field, want_form_field),
            );
            c.check(
                &format!("{}.routedBy", etag),
                e.routed_by == we.str_or("routedBy"),
                &e.routed_by,
            );
            c.check(
                &format!("{}.routedAt", etag),
                e.routed_at == we.str_or("routedAt"),
                &e.routed_at,
            );
            let want_note = opt_str(we.get("routingNote"));
            c.check(
                &format!("{}.routingNote", etag),
                e.routing_note == want_note,
                &format!("{:?} != {:?}", e.routing_note, want_note),
            );
            c.check(
                &format!("{}.value", etag),
                e.value == we.str_or("value"),
                &format!("{:?} != {:?}", e.value, we.str_or("value")),
            );
        }

        let want_yaml = expected.str_or("yaml");
        c.check(
            &format!("{}.yaml", tag),
            x.to_yaml() == want_yaml,
            &byte_diff("yaml", &x.to_yaml(), &want_yaml),
        );
        let want_markdown = expected.str_or("markdown");
        c.check(
            &format!("{}.markdown", tag),
            x.to_markdown() == want_markdown,
            &byte_diff("markdown", &x.to_markdown(), &want_markdown),
        );
    }

    // 3. every emitted value occurs verbatim in the source document.
    //
    // The guard `codespecs_derivation_contract.md` §2.8 C1 rests on, carried in
    // the corpus rather than left to each port's own conscience: the generator
    // may copy and index, it may not compose. Membership, not substring — that
    // is what makes "verbatim" mean verbatim rather than "derived from".
    let mut stored: HashSet<&str> = HashSet::new();
    for v in state.content.values() {
        stored.insert(v.as_str());
    }
    for section in state.forms.values() {
        for v in section.values() {
            stored.insert(v.as_str());
        }
    }
    c.check("codespecs.stored.nonEmpty", !stored.is_empty(), "");
    for x in &extracts {
        for e in &x.entries {
            c.check(
                &format!("codespecs.copied[{}] {}", x.area.code, e.path),
                stored.contains(e.value.as_str()),
                "was not copied from the document",
            );
        }
    }

    // 4. a @FollowUpKind subtree contributes to no extract.
    //
    // `Control` is populated, and populated distinctively, so its absence cannot
    // be an accident of an empty section. `alice` covers the second half: a
    // @NoArtifact section's own leaf contributes nothing either.
    let emitted: Vec<&str> = extracts
        .iter()
        .flat_map(|x| x.entries.iter().map(|e| e.value.as_str()))
        .collect();
    for absent in ["Controlled summary", "ctrl-owner", "alice"] {
        c.check(
            &format!("codespecs.excluded[{}]", absent),
            !emitted.contains(&absent),
            "reached an extract",
        );
    }

    // 5. the ROUTE-TOTAL error cases: `extract_all` fails, `routings` reports.
    let error_cases = table
        .get("errorCases")
        .and_then(|v| v.as_array())
        .expect("codespecs_extract_cases.errorCases is a list");
    for ec in error_cases {
        let name = ec.str_or("name");
        // The error case carries its own model and state rather than mutating the
        // shared fixture: `model.meta.json` is a VALID model by construction
        // (§10.2 `ROUTE-TOTAL` holds over it), and a port in a language without
        // cheap structural editing should not have to break it to run this case.
        let err_model = SpecModel::from_json(ec.get("model").expect("error case has a model"));
        let err_state = match ec.get("state") {
            Some(s) => DocumentJson::from_json(s),
            None => DocumentJson::default(),
        };
        let err_doc = doc_from_state(&err_state);
        let err_extractor =
            CodeSpecsExtractor::for_model(&err_doc, &err_model, catalog.clone(), None)
                .expect("an error case's model resolves to one root");
        let want = ec.get("expect").expect("error case has an expectation");

        match err_extractor.extract_all() {
            Ok(_) => c.check(
                &format!("codespecs.error[{}].raised", name),
                false,
                "extract_all succeeded",
            ),
            Err(e) => {
                c.check(
                    &format!("codespecs.error[{}].path", name),
                    e.path == want.str_or("path"),
                    &e.path,
                );
                c.check(
                    &format!("codespecs.error[{}].className", name),
                    e.class_name == want.str_or("className"),
                    &e.class_name,
                );
                c.check(
                    &format!("codespecs.error[{}].message", name),
                    e.message.contains(&want.str_or("messageContains")),
                    &e.message,
                );
            }
        }

        let verdicts: Vec<&str> = err_extractor
            .routings()
            .iter()
            .filter(|r| r.path == want.str_or("path"))
            .map(|r| r.verdict.name())
            .collect();
        let want_verdicts = vec![want.str_or("routingVerdict")];
        c.check(
            &format!("codespecs.error[{}].routingVerdict", name),
            verdicts == want_verdicts,
            &format!("{:?} != {:?}", verdicts, want_verdicts),
        );
    }

    // 6. root scoping (`codespecs_prompt.md` §5): the walk starts at ONE root.
    // The models here carry two, because over a single-root model "walks the
    // named root" and "walks every root" give the same answer.
    let root_cases = table
        .get("rootCases")
        .and_then(|v| v.as_array())
        .expect("codespecs_extract_cases.rootCases is a list");
    for rc in root_cases {
        let name = rc.str_or("name");
        let root_model = SpecModel::from_json(rc.get("model").expect("root case has a model"));
        let root_state = match rc.get("state") {
            Some(s) => DocumentJson::from_json(s),
            None => DocumentJson::default(),
        };
        let root_doc = doc_from_state(&root_state);
        let want = rc.get("expect").expect("root case has an expectation");
        let built = CodeSpecsExtractor::for_model(
            &root_doc,
            &root_model,
            catalog.clone(),
            rc.get("rootType").and_then(|v| v.as_str()),
        );
        if want.bool_or("fails") {
            match built {
                Ok(_) => c.check(
                    &format!("codespecs.root[{}].thrown", name),
                    false,
                    "the extractor bound instead of failing",
                ),
                Err(e) => {
                    c.check(
                        &format!("codespecs.root[{}].path", name),
                        e.path == want.str_or("path"),
                        &e.path,
                    );
                    c.check(
                        &format!("codespecs.root[{}].className", name),
                        e.class_name == want.str_or("className"),
                        &e.class_name,
                    );
                    c.check(
                        &format!("codespecs.root[{}].message", name),
                        e.message.contains(&want.str_or("messageContains")),
                        &e.message,
                    );
                }
            }
            continue;
        }
        let x = built.expect("a passing root case binds");
        c.check(
            &format!("codespecs.root[{}].root", name),
            x.root.type_ == want.str_or("root"),
            &x.root.type_,
        );
        // `routings` and `extract_all` walk the same resolved root, so the
        // verdict sequence is scoped too — that is what makes the bare
        // `@Document` root of case 2 the corpus's `documentRoot` producer.
        let root_verdicts: Vec<String> = x
            .routings()
            .iter()
            .map(|r| r.verdict.name().to_string())
            .collect();
        let want_verdicts: Vec<String> = want
            .get("routingVerdicts")
            .and_then(|v| v.as_array())
            .map(|a| a.iter().filter_map(|v| v.as_str().map(String::from)).collect())
            .unwrap_or_default();
        c.check(
            &format!("codespecs.root[{}].routingVerdicts", name),
            root_verdicts == want_verdicts,
            &format!("{:?} != {:?}", root_verdicts, want_verdicts),
        );
        let extracts = x.extract_all().expect("a passing root case extracts");
        c.check(
            &format!("codespecs.root[{}].documentRoot", name),
            extracts[0].document_root == want.str_or("documentRoot"),
            &extracts[0].document_root,
        );
        let paths: Vec<String> = extracts
            .iter()
            .flat_map(|g| g.entries.iter().map(|e| e.path.clone()))
            .collect();
        let want_paths: Vec<String> = want
            .get("paths")
            .and_then(|v| v.as_array())
            .map(|a| a.iter().filter_map(|v| v.as_str().map(String::from)).collect())
            .unwrap_or_default();
        c.check(
            &format!("codespecs.root[{}].paths", name),
            paths == want_paths,
            &format!("{:?} != {:?}", paths, want_paths),
        );
    }
}

/// The lazy cursor replayed against a **mutating** document.
///
/// A cursor is a query plus a position, not a snapshot: it re-validates each
/// candidate against the live document as it steps, so an item removed after the
/// cursor was opened is skipped. Rust cannot hold a shared borrow of the
/// document across a mutation, so [`SpecQueryEngine`] is rebuilt per step (it is
/// a borrow pair, not state) and the cursor carries no engine reference.
/// Structural JSON equality with object keys compared as a set — the corpus is
/// written by the Dart reference, whose key order a summary need not copy.
fn json_eq(a: &Json, b: &Json) -> bool {
    match (a, b) {
        (Json::Object(x), Json::Object(y)) => {
            x.len() == y.len()
                && x.iter().all(|(k, v)| {
                    y.iter()
                        .find(|(k2, _)| k2 == k)
                        .is_some_and(|(_, v2)| json_eq(v, v2))
                })
        }
        (Json::Array(x), Json::Array(y)) => {
            x.len() == y.len() && x.iter().zip(y).all(|(p, q)| json_eq(p, q))
        }
        _ => a == b,
    }
}

fn jstr(s: &str) -> Json {
    Json::Str(s.to_string())
}

fn jopt(s: &Option<String>) -> Json {
    match s {
        Some(s) => jstr(s),
        None => Json::Null,
    }
}

fn jstrs<'a>(items: impl IntoIterator<Item = &'a String>) -> Json {
    Json::Array(items.into_iter().map(|s| jstr(s)).collect())
}

fn obj(pairs: Vec<(&str, Json)>) -> Json {
    Json::Object(pairs.into_iter().map(|(k, v)| (k.to_string(), v)).collect())
}

fn extract_summary(x: &CodeSpecsExtract) -> Json {
    obj(vec![
        ("area", jstr(&x.area.code)),
        ("canonicalId", jstr(&x.area.canonical_id)),
        ("part", jstr(&x.area.part)),
        ("documentRoot", jstr(&x.document_root)),
        ("projects", jstrs(&x.projects)),
        ("citableParts", jstrs(&x.citable_parts)),
        ("entryCount", Json::Int(x.entries.len() as i64)),
        ("sectionIds", jstrs(x.entries.iter().map(|e| &e.section_id))),
        ("values", jstrs(x.entries.iter().map(|e| &e.value))),
        ("classNames", jstrs(x.entries.iter().map(|e| &e.class_name))),
        (
            "headlines",
            Json::Array(x.entries.iter().map(|e| jopt(&e.headline)).collect()),
        ),
    ])
}

fn gate_summary(g: &CodeSpecsGateRecord) -> Json {
    let verdicts = g
        .verdicts()
        .iter()
        .map(|v| {
            obj(vec![
                ("area", jstr(&v.area)),
                ("verdict", jstr(v.verdict.word())),
                ("resolution", jopt(&v.resolution)),
                ("note", jopt(&v.note)),
            ])
        })
        .collect();
    obj(vec![("verdicts", Json::Array(verdicts))])
}

fn scope_summary(set: &CodeSpecsExtractSet) -> Json {
    let excluded = set
        .excluded
        .iter()
        .map(|e| {
            obj(vec![
                ("area", jstr(&e.area)),
                ("verdict", jstr(e.verdict.word())),
                ("descoped", Json::Bool(e.descoped)),
                ("entryCount", Json::Int(e.entry_count as i64)),
                ("source", jstr(&e.source)),
            ])
        })
        .collect();
    obj(vec![
        ("inScope", jstrs(set.extracts.iter().map(|x| &x.area.code))),
        ("sources", jstrs(&set.sources)),
        ("hasGate", Json::Bool(set.gate.is_some())),
        ("excluded", Json::Array(excluded)),
    ])
}

fn gate_entry(v: &Json) -> CodeSpecsGateEntry {
    CodeSpecsGateEntry {
        area: v.str_or("area"),
        verdict: CodeSpecsGateVerdict::parse(&v.str_or("verdict")).expect("a known verdict"),
        resolution: v
            .get("resolution")
            .and_then(|r| r.as_str())
            .map(str::to_string),
        note: v.get("note").and_then(|r| r.as_str()).map(str::to_string),
    }
}

fn cases<'a>(table: &'a Json, key: &str) -> &'a [Json] {
    table
        .get(key)
        .and_then(|v| v.as_array())
        .unwrap_or_else(|| panic!("codespecs_record_cases has {}", key))
}

/// Reading back what a Phase-4 run wrote: extract files (each read checked
/// against its summary and written back byte for byte), the gate record (read,
/// written, edited, refused) and the scoping of a file set by its record. Error
/// cases compare by substring of the Dart reference's message.
fn test_codespecs_records(c: &mut Checker) {
    let table = read_json("codespecs_record_cases.json");
    let extract_table = read_json("codespecs_extract_cases.json");
    let catalog = CodeSpecsAreaCatalog::from_json(
        extract_table
            .get("catalog")
            .expect("codespecs_extract_cases has a catalog"),
    )
    .expect("the catalogue loads");

    for case in cases(&table, "extractReads") {
        let source = case.str_or("source");
        let yaml = case.str_or("yaml");
        let at = format!("codespecsRecords.extractRead[{}]", source);
        match CodeSpecsExtract::from_yaml(&yaml, &source) {
            Ok(x) => {
                let got = extract_summary(&x);
                let want = case.get("expect").expect("an expect");
                c.check(
                    &at,
                    json_eq(&got, want),
                    &format!("{:?} != {:?}", got, want),
                );
                let back = x.to_yaml();
                c.check(
                    &format!("{}.roundTrip", at),
                    back == yaml,
                    &byte_diff(&at, &back, &yaml),
                );
            }
            Err(e) => c.check(&at, false, &e.message),
        }
    }

    let minimal = table
        .get("extractMinimal")
        .expect("codespecs_record_cases has extractMinimal");
    match CodeSpecsExtract::from_yaml(&minimal.str_or("yaml"), &minimal.str_or("source")) {
        Ok(x) => {
            let got = extract_summary(&x);
            let want = minimal.get("expect").expect("an expect");
            c.check(
                "codespecsRecords.extractMinimal",
                json_eq(&got, want),
                &format!("{:?} != {:?}", got, want),
            );
        }
        Err(e) => c.check("codespecsRecords.extractMinimal", false, &e.message),
    }

    for case in cases(&table, "extractErrors") {
        let at = format!("codespecsRecords.extractError[{}]", case.str_or("name"));
        let want = case.str_or("messageContains");
        match CodeSpecsExtract::from_yaml(&case.str_or("yaml"), &case.str_or("source")) {
            Ok(_) => c.check(
                &at,
                false,
                &format!("no error, want one containing {}", want),
            ),
            Err(e) => c.check(
                &at,
                e.message.contains(&want),
                &format!("{} does not contain {}", e.message, want),
            ),
        }
    }

    for case in cases(&table, "gateRecords") {
        let at = format!("codespecsRecords.gateRecord[{}]", case.str_or("name"));
        let yaml = case.str_or("yaml");
        match CodeSpecsGateRecord::from_yaml(&yaml, "") {
            Ok(g) => {
                let got = gate_summary(&g);
                let want = case.get("expect").expect("an expect");
                c.check(
                    &at,
                    json_eq(&got, want),
                    &format!("{:?} != {:?}", got, want),
                );
                let back = g.to_yaml();
                c.check(
                    &format!("{}.toYaml", at),
                    back == yaml,
                    &byte_diff(&at, &back, &yaml),
                );
                let checked = g.check_against(&catalog);
                c.check(
                    &format!("{}.checkAgainst", at),
                    checked.is_ok(),
                    &checked.err().map(|e| e.message).unwrap_or_default(),
                );
            }
            Err(e) => c.check(&at, false, &e.message),
        }
    }

    for case in cases(&table, "gateWrites") {
        let at = format!("codespecsRecords.gateWrite[{}]", case.str_or("name"));
        let verdicts = case
            .get("verdicts")
            .and_then(|v| v.as_array())
            .expect("a verdicts list")
            .iter()
            .map(gate_entry)
            .collect();
        let g = match CodeSpecsGateRecord::new(verdicts) {
            Ok(g) => g,
            Err(e) => {
                c.check(&at, false, &e.message);
                continue;
            }
        };
        let want = case.str_or("yaml");
        c.check(
            &at,
            g.to_yaml() == want,
            &byte_diff(&at, &g.to_yaml(), &want),
        );
        if let Some(then) = case.get("then").filter(|t| **t != Json::Null) {
            match g.with_verdict(gate_entry(then)) {
                Ok(g2) => {
                    let then_want = case.str_or("thenYaml");
                    c.check(
                        &format!("{}.then", at),
                        g2.to_yaml() == then_want,
                        &byte_diff(&at, &g2.to_yaml(), &then_want),
                    );
                }
                Err(e) => c.check(&format!("{}.then", at), false, &e.message),
            }
        }
    }

    for case in cases(&table, "gateErrors") {
        let at = format!("codespecsRecords.gateError[{}]", case.str_or("name"));
        let want = case.str_or("messageContains");
        let against = case
            .get("againstCatalog")
            .and_then(|v| v.as_bool())
            .unwrap_or(false);
        let result = CodeSpecsGateRecord::from_yaml(&case.str_or("yaml"), "").and_then(|g| {
            if against {
                g.check_against(&catalog)
            } else {
                Ok(())
            }
        });
        match result {
            Ok(()) => c.check(
                &at,
                false,
                &format!("no error, want one containing {}", want),
            ),
            Err(e) => c.check(
                &at,
                e.message.contains(&want),
                &format!("{} does not contain {}", e.message, want),
            ),
        }
    }

    for case in cases(&table, "scopeCases") {
        let at = format!("codespecsRecords.scope[{}]", case.str_or("name"));
        let files: Vec<(String, String)> = case
            .get("files")
            .and_then(|v| v.as_array())
            .expect("a files list")
            .iter()
            .map(|pair| {
                let pair = pair.as_array().expect("a [name, text] pair");
                (
                    pair[0].as_str().expect("a name").to_string(),
                    pair[1].as_str().expect("a text").to_string(),
                )
            })
            .collect();
        let want = case.get("expect").expect("an expect");
        let result = CodeSpecsExtractSet::from_files(files);
        match (want.get("error").and_then(|e| e.as_str()), result) {
            (Some(want_error), Err(e)) => c.check(
                &at,
                e.message.contains(want_error),
                &format!("{} does not contain {}", e.message, want_error),
            ),
            (Some(want_error), Ok(set)) => c.check(
                &at,
                false,
                &format!("got {:?}, want error {}", scope_summary(&set), want_error),
            ),
            (None, Ok(set)) => {
                let got = scope_summary(&set);
                c.check(
                    &at,
                    json_eq(&got, want),
                    &format!("{:?} != {:?}", got, want),
                );
            }
            (None, Err(e)) => c.check(&at, false, &e.message),
        }
    }
}

fn test_cursor_script(c: &mut Checker, model: &SpecModel) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let mut doc = doc_from_state(&state);
    let steps_json = read_json("cursor_cases.json");
    let steps = steps_json.as_array().expect("cursor_cases.json is a list");
    let mut cursor: Option<SpecQueryCursor> = None;

    for (n, s) in steps.iter().enumerate() {
        let op = s.str_or("op");
        let tag = format!("cursor[{}].{}", n, op);
        match op.as_str() {
            "open" => {
                let engine = SpecQueryEngine::for_model(&doc, model);
                let query = query_from_json(s.get("query").expect("open has a query"));
                match engine.query(query) {
                    Ok(cur) => cursor = Some(cur),
                    Err(e) => c.check(&tag, false, &e.to_string()),
                }
            }
            "count" => {
                let engine = SpecQueryEngine::for_model(&doc, model);
                let want = s.get("expect").and_then(|v| v.as_i64()).unwrap_or(-1) as usize;
                let got = cursor.as_ref().expect("cursor is open").count(&engine);
                c.check(&tag, got == want, &format!("{} != {}", got, want));
            }
            "take" => {
                let engine = SpecQueryEngine::for_model(&doc, model);
                let n_take = s.get("n").and_then(|v| v.as_i64()).unwrap_or(0) as usize;
                let got: Vec<String> = cursor
                    .as_mut()
                    .expect("cursor is open")
                    .take(&engine, n_take)
                    .into_iter()
                    .map(|m| m.path)
                    .collect();
                let want = str_list(s.get("expect"));
                c.check(&tag, got == want, &format!("{:?} != {:?}", got, want));
            }
            "next" => {
                let engine = SpecQueryEngine::for_model(&doc, model);
                let got = cursor
                    .as_mut()
                    .expect("cursor is open")
                    .next(&engine)
                    .map(|m| m.path);
                let want = opt_str(s.get("expect"));
                c.check(&tag, got == want, &format!("{:?} != {:?}", got, want));
            }
            "toList" => {
                let engine = SpecQueryEngine::for_model(&doc, model);
                let got: Vec<String> = cursor
                    .as_mut()
                    .expect("cursor is open")
                    .to_list(&engine)
                    .into_iter()
                    .map(|m| m.path)
                    .collect();
                let want = str_list(s.get("expect"));
                c.check(&tag, got == want, &format!("{:?} != {:?}", got, want));
            }
            "removeListItem" => {
                doc.remove_list_item(&s.str_or("itemPath"));
            }
            other => c.check(&format!("{}.unknown", tag), false, other),
        }
    }
}

/// The creation gate's decision table: every probe is stateless, so each runs
/// against a freshly loaded fixture document.
///
/// Rejections are asserted on the machine-readable triple (code / parentPath /
/// childSegment), never on the message prose.
fn test_node_creation_cases(c: &mut Checker, model: &SpecModel) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let cases_json = read_json("node_creation_cases.json");
    let cases = cases_json
        .as_array()
        .expect("node_creation_cases.json is a list");

    for tc in cases {
        let name = tc.str_or("name");
        let parent_path = tc.str_or("parentPath");
        let child_segment = tc.str_or("childSegment");
        let item_id = opt_str(tc.get("itemId"));
        let accepted = tc.get("accepted").and_then(|v| v.as_bool()).unwrap_or(false);

        let doc = doc_from_state(&state);
        let err = check_add_node(
            model,
            &doc,
            &parent_path,
            &child_segment,
            item_id.as_deref(),
        );
        c.check(
            &format!("create[{}].accepted", name),
            err.is_none() == accepted,
            &format!("{:?}", err.as_ref().map(|e| e.to_string())),
        );
        if let Some(e) = err {
            let want_code = tc.str_or("code");
            c.check(
                &format!("create[{}].code", name),
                e.code.name() == want_code,
                &format!("{} != {}", e.code.name(), want_code),
            );
            c.check(
                &format!("create[{}].parentPath", name),
                e.parent_path == parent_path,
                &e.parent_path,
            );
            c.check(
                &format!("create[{}].childSegment", name),
                e.child_segment == child_segment,
                &e.child_segment,
            );
        }
    }
}

/// The creation script: **stateful and ordered**, replayed against a single
/// document, ending in a full document-state comparison.
///
/// The corpus dates every generated section id in the year 2026; only
/// `(month, day)` reach the two-letter-date encoder, so this port passes those
/// two directly (`today_month_day` has the same shape).
fn test_node_creation_script(c: &mut Checker, model: &SpecModel) {
    let state = DocumentJson::from_json(&read_json("state.json"));
    let mut doc = doc_from_state(&state);
    let steps_json = read_json("node_creation_script.json");
    let steps = steps_json
        .as_array()
        .expect("node_creation_script.json is a list");

    for (n, s) in steps.iter().enumerate() {
        let op = s.str_or("op");
        let tag = format!("createScript[{}].{}", n, op);
        match op.as_str() {
            "add" => {
                let parent_path = s.str_or("parentPath");
                let child_segment = s.str_or("childSegment");
                let item_id = opt_str(s.get("itemId"));
                let month = s.get("month").and_then(|v| v.as_i64()).unwrap_or(1);
                let day = s.get("day").and_then(|v| v.as_i64()).unwrap_or(1);
                let mut creator = SpecNodeCreator::for_model(&mut doc, model);
                let result = match &item_id {
                    Some(id) => creator.add_with_id(&parent_path, &child_segment, id),
                    None => creator.add_on(&parent_path, &child_segment, month, day),
                };
                match result {
                    Ok(path) => {
                        let want_path = s.str_or("expectPath");
                        c.check(
                            &format!("{}.path", tag),
                            path == want_path,
                            &format!("{} != {}", path, want_path),
                        );
                        c.check(
                            &format!("{}.id", tag),
                            raw_matches(doc.item_section_id(&path), s.get("expectId")),
                            &format!("{:?}", doc.item_section_id(&path)),
                        );
                    }
                    Err(e) => c.check(&tag, false, &format!("unexpected rejection: {}", e)),
                }
            }
            "addThrows" => {
                let parent_path = s.str_or("parentPath");
                let child_segment = s.str_or("childSegment");
                let item_id = opt_str(s.get("itemId"));
                let want_code = s.str_or("expectCode");
                let mut creator = SpecNodeCreator::for_model(&mut doc, model);
                // The reference dates every rejection probe 2026-03-04; the date
                // is unreachable because the gate rejects before it is used.
                let result = match &item_id {
                    Some(id) => creator.add_with_id(&parent_path, &child_segment, id),
                    None => creator.add_on(&parent_path, &child_segment, 3, 4),
                };
                match result {
                    Ok(path) => c.check(&tag, false, &format!("unexpectedly added {}", path)),
                    Err(e) => c.check(
                        &tag,
                        e.code.name() == want_code,
                        &format!("{} != {}", e.code.name(), want_code),
                    ),
                }
            }
            "finalState" => {
                let want = DocumentJson::from_json(s.get("expect").expect("finalState.expect"))
                    .to_canonical_json();
                let got = doc.to_json().to_canonical_json();
                c.check(&tag, got == want, &format!("got {} want {}", got, want));
            }
            other => c.check(&format!("{}.unknown", tag), false, other),
        }
    }
}

/// Rebuilds a [`SpecQuery`] from its corpus wire form.
///
/// Every port needs this same decode, so its shape *is* part of the contract: an
/// absent key means "dimension unset", never a default that happens to match.
/// Kept beside the replay tests rather than in `src/` because it belongs to the
/// corpus format, not to the runtime API.
fn query_from_json(j: &Json) -> SpecQuery {
    SpecQuery {
        text: opt_str(j.get("text")),
        regex: j.get("regex").and_then(|v| v.as_bool()).unwrap_or(false),
        case_insensitive: j
            .get("caseInsensitive")
            .and_then(|v| v.as_bool())
            .unwrap_or(false),
        kinds: j
            .get("kinds")
            .and_then(|v| v.as_array())
            .map(|a| a.iter().filter_map(|k| k.as_str().map(String::from)).collect()),
        class_name: opt_str(j.get("className")),
        section_id_exact: opt_str(j.get("sectionIdExact")),
        section_id_prefix: opt_str(j.get("sectionIdPrefix")),
        path_glob: opt_str(j.get("pathGlob")),
        maps_to: opt_str(j.get("mapsTo")),
        detailed_in: opt_str(j.get("detailedIn")),
        state: j.get("state").and_then(|v| v.as_str()).map(|s| {
            SpecStateFilter::from_name(s).unwrap_or_else(|| panic!("unknown state filter {:?}", s))
        }),
    }
}

/// Decodes a corpus `[[start, end], …]` span list.
fn spans_of(v: Option<&Json>) -> Vec<(usize, usize)> {
    v.and_then(|j| j.as_array())
        .map(|a| {
            a.iter()
                .map(|pair| {
                    let p = pair.as_array().expect("a span is a two-element list");
                    (
                        p[0].as_i64().unwrap_or(0) as usize,
                        p[1].as_i64().unwrap_or(0) as usize,
                    )
                })
                .collect()
        })
        .unwrap_or_default()
}

// --- small helpers ---------------------------------------------------------

fn opt_str(v: Option<&Json>) -> Option<String> {
    match v {
        Some(Json::Str(s)) => Some(s.clone()),
        _ => None,
    }
}

fn opt_eq(got: &str, want: &Option<String>) -> bool {
    match want {
        None => got.is_empty(),
        Some(w) => got == w,
    }
}

/// Every case of the Stage-A gate table (codespecs_gate_cases.json, A1–A5). The
/// catalogue is `catalog` plus the case's (or the table's) `gate` block, the
/// schema the case's (or the table's) `schema`. A case key that is **present
/// with null** overrides the default — no schema, or a catalogue without gate
/// tables — so presence is tested on the key, not on the value.
fn test_codespecs_gate(c: &mut Checker) {
    let table = read_json("codespecs_gate_cases.json");
    let meta = read_json("model.meta.json");
    for case in table
        .get("cases")
        .and_then(|v| v.as_array())
        .expect("codespecs_gate_cases has cases")
    {
        let at = format!("codespecsGate[{}]", case.str_or("name"));
        let want = case.get("expect").expect("a gate case has an expect");
        match run_gate_case(&table, case, &meta) {
            Ok(got) => c.check(&at, json_eq(&got, want), &format!("{:?} != {:?}", got, want)),
            Err(e) => c.check(&at, false, &e),
        }
    }
}

/// The value of `key` when `case` carries the key at all (null included),
/// else the table's default.
fn case_or_default<'a>(table: &'a Json, case: &'a Json, key: &str) -> Option<&'a Json> {
    let present = case
        .as_object()
        .is_some_and(|o| o.iter().any(|(k, _)| k == key));
    if present {
        case.get(key)
    } else {
        table.get(key)
    }
}

fn run_gate_case(table: &Json, case: &Json, meta: &Json) -> Result<Json, String> {
    let mut catalog_pairs: Vec<(String, Json)> = table
        .get("catalog")
        .and_then(|v| v.as_object())
        .ok_or("codespecs_gate_cases has a catalog")?
        .to_vec();
    match case_or_default(table, case, "gate") {
        None | Some(Json::Null) => {}
        Some(gate) => {
            catalog_pairs.retain(|(k, _)| k != "gate");
            catalog_pairs.push(("gate".to_string(), gate.clone()));
        }
    }
    let catalog = CodeSpecsAreaCatalog::from_json(&Json::Object(catalog_pairs))?;
    let schema = match case_or_default(table, case, "schema") {
        None | Some(Json::Null) => None,
        Some(yaml) => Some(DocSpecsSchema::from_yaml_text(
            yaml.as_str().ok_or("a gate schema is a YAML string")?,
        )?),
    };
    let model = match case.get("model") {
        None | Some(Json::Null) => SpecModel::from_json(meta),
        Some(m) => SpecModel::from_json(m),
    };
    let state = DocumentJson::from_json(case.get("state").ok_or("a gate case has a state")?);
    let doc = doc_from_state(&state);
    let report = CodeSpecsGate::new(&model, &doc, &catalog, schema.as_ref(), None).run();
    Ok(gate_report_json(&report))
}

fn gate_report_json(report: &CodeSpecsGateReport) -> Json {
    let results = report
        .results
        .iter()
        .map(|r| {
            let findings = r
                .findings
                .iter()
                .map(|f| {
                    Json::Object(vec![
                        ("code".to_string(), jstr(&f.code)),
                        ("location".to_string(), jstr(&f.location)),
                        ("message".to_string(), jstr(&f.message)),
                    ])
                })
                .collect();
            Json::Object(vec![
                ("check".to_string(), jstr(r.check.label())),
                ("ran".to_string(), Json::Bool(r.ran)),
                ("notRunReason".to_string(), jopt(&r.not_run_reason)),
                ("findings".to_string(), Json::Array(findings)),
            ])
        })
        .collect();
    Json::Object(vec![
        ("passed".to_string(), Json::Bool(report.passed())),
        ("results".to_string(), Json::Array(results)),
    ])
}
