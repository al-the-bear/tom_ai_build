//! The document-set part of the conformance suite
//! (`tom_specs_model_rules.md` §9.7): the set, its report and the global
//! rename (`document_set_cases.json`), `derive_fields` (`derive_cases.json`),
//! `prefill` and `backfill` (`prefill_cases.json`, `backfill_cases.json`). A
//! port of the Go runner's `conformance_document_set_test.go` (the Python
//! runner's `test_document_set` / `test_derive_fields` /
//! `test_prefill_backfill`).

use super::*;

use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::OnceLock;

use tom_som_rust_runtime::{
    backfill, derive_fields, prefill, rename_id, sync_report, validate_links, SpecBackfillOptions,
    SpecDeriveOptions, SpecDocumentSet, SpecPrefillOptions, SpecSyncPair,
};

// --- reading the tables ------------------------------------------------------------

/// The real model (11 MB), loaded once across the tables.
pub fn real_model() -> &'static SpecModel {
    static MODEL: OnceLock<SpecModel> = OnceLock::new();
    MODEL.get_or_init(load_som_model)
}

/// The fixture model a table names (`links.meta.json` by default).
pub fn table_model(table: &Json) -> SpecModel {
    let name = table
        .get("model")
        .and_then(|m| m.as_str())
        .unwrap_or("links.meta.json");
    SpecModel::from_json(&read_json(name))
}

/// The model a case runs against: an inline one, the real one, or the
/// fixture.
pub fn model_of<'a>(fixture: &'a SpecModel, inline: &'a Option<SpecModel>, c: &Json) -> &'a SpecModel {
    if let Some(m) = inline {
        return m;
    }
    if c.str_or("model") == "som" {
        return real_model();
    }
    fixture
}

pub fn inline_model(c: &Json) -> Option<SpecModel> {
    c.get("inline")
        .filter(|v| v.as_object().is_some())
        .map(SpecModel::from_json)
}

/// The document a generic state decodes to.
pub fn state_document(state: &Json) -> SpecDocument {
    doc_from_state(&DocumentJson::from_json(state))
}

/// The documents of a case, `[[name, state], …]`.
pub fn set_documents(entries: Option<&Json>) -> Vec<(String, SpecDocument)> {
    entries
        .and_then(|e| e.as_array())
        .unwrap_or(&[])
        .iter()
        .filter_map(|e| {
            let pair = e.as_array()?;
            Some((pair[0].as_str()?.to_string(), state_document(&pair[1])))
        })
        .collect()
}

/// The case's `pairs` list, `None` when it has none.
pub fn case_pairs(c: &Json) -> Option<Vec<String>> {
    c.get("pairs").and_then(|p| p.as_array()).map(|list| {
        list.iter()
            .map(|x| {
                x.as_str()
                    .map_or_else(|| format!("{:?}", x), str::to_string)
            })
            .collect()
    })
}

pub fn intent(c: &Json) -> Vec<String> {
    c.get("intent")
        .and_then(|v| v.as_array())
        .unwrap_or(&[])
        .iter()
        .filter_map(|x| x.as_str().map(str::to_string))
        .collect()
}

pub fn table_cases<'a>(table: &'a Json, group: &str) -> &'a [Json] {
    table.get(group).and_then(|v| v.as_array()).unwrap_or(&[])
}

fn list_len(v: Option<&Json>) -> usize {
    v.and_then(|x| x.as_array()).map_or(0, <[Json]>::len)
}

/// Compact JSON text, for a failure's detail.
pub fn jtext(v: &Json) -> String {
    match v {
        Json::Null => "null".to_string(),
        Json::Bool(b) => b.to_string(),
        Json::Int(n) => n.to_string(),
        Json::Float(f) => f.to_string(),
        Json::Str(s) => tom_som_rust_runtime::json::encode_str(s),
        Json::Array(items) => format!(
            "[{}]",
            items.iter().map(jtext).collect::<Vec<_>>().join(",")
        ),
        Json::Object(pairs) => format!(
            "{{{}}}",
            pairs
                .iter()
                .map(|(k, v)| format!("{}:{}", tom_som_rust_runtime::json::encode_str(k), jtext(v)))
                .collect::<Vec<_>>()
                .join(",")
        ),
    }
}

fn first_difference(got: &Json, want: &Json, at: &str) -> String {
    match (got, want) {
        (Json::Object(a), Json::Object(b)) => {
            for (k, v) in b {
                match a.iter().find(|(k2, _)| k2 == k) {
                    Some((_, g)) if !json_eq(g, v) => {
                        return first_difference(g, v, &format!("{}.{}", at, k))
                    }
                    None => return format!("{}.{} missing", at, k),
                    _ => {}
                }
            }
            for (k, _) in a {
                if !b.iter().any(|(k2, _)| k2 == k) {
                    return format!("{}.{} unexpected", at, k);
                }
            }
            format!("{} differs", at)
        }
        (Json::Array(a), Json::Array(b)) if a.len() == b.len() => {
            for (i, (g, w)) in a.iter().zip(b).enumerate() {
                if !json_eq(g, w) {
                    return first_difference(g, w, &format!("{}[{}]", at, i));
                }
            }
            format!("{} differs", at)
        }
        _ => {
            let cut = |s: String| s.chars().take(600).collect::<String>();
            format!("{}: got {} want {}", at, cut(jtext(got)), cut(jtext(want)))
        }
    }
}

/// Compares one case's output with its expectation; a panic is a failure
/// (the reference runtimes raise).
fn check_case(c: &mut Checker, name: &str, run: impl FnOnce() -> Json, expect: Option<&Json>) {
    let got = match catch_unwind(AssertUnwindSafe(run)) {
        Ok(g) => g,
        Err(e) => {
            let why = e
                .downcast_ref::<String>()
                .cloned()
                .or_else(|| e.downcast_ref::<&str>().map(|s| s.to_string()))
                .unwrap_or_default();
            c.check(name, false, &format!("threw {}", why));
            return;
        }
    };
    let want = expect.cloned().unwrap_or(Json::Null);
    if json_eq(&got, &want) {
        c.check(name, true, "");
    } else {
        c.check(name, false, &first_difference(&got, &want, "$"));
    }
}

fn nullable(s: &str) -> Json {
    if s.is_empty() {
        Json::Null
    } else {
        jstr(s)
    }
}

fn pairs_json(pairs: &[SpecSyncPair]) -> Json {
    Json::Array(pairs.iter().map(SpecSyncPair::to_json).collect())
}

fn must_set(model: &SpecModel, docs: Vec<(String, SpecDocument)>) -> SpecDocumentSet<'_> {
    SpecDocumentSet::new(model, docs).unwrap_or_else(|e| panic!("{}", e))
}

// --- the set ----------------------------------------------------------------------

fn set_construction_case(model: &SpecModel, c: &Json) -> Json {
    let docs = set_documents(c.get("documents"));
    let built = if c.bool_or("fragments") {
        SpecDocumentSet::from_fragments(model, docs)
    } else {
        SpecDocumentSet::new(model, docs)
    };
    match built {
        Err(e) => obj(vec![("refused", e.to_json())]),
        Ok(s) => obj(vec![
            ("blueprintRoot", nullable(&s.blueprint_root)),
            ("names", jstrs(&s.names())),
            ("roots", jstrs(&s.roots())),
            ("missingRoots", jstrs(&s.missing_roots())),
            ("pairs", pairs_json(s.pairs())),
        ]),
    }
}

fn set_report_case(model: &SpecModel, c: &Json) -> Json {
    let s = must_set(model, set_documents(c.get("documents")));
    sync_report(&s, case_pairs(c).as_deref()).to_json()
}

fn set_rename_case(model: &SpecModel, c: &Json) -> Json {
    let mut s = must_set(model, set_documents(c.get("documents")));
    match rename_id(&mut s, &c.str_or("from"), &c.str_or("to")) {
        Err(e) => obj(vec![("refused", jstrs(&e.documents))]),
        Ok(changes) => {
            let after = sync_report(&s, None);
            let n = after.findings.iter().filter(|f| !f.is_info()).count();
            obj(vec![
                (
                    "changes",
                    Json::Array(changes.iter().map(|x| x.to_json()).collect()),
                ),
                ("cleanAfter", Json::Bool(after.clean())),
                ("findingsAfter", Json::Int(n as i64)),
            ])
        }
    }
}

/// Every token a document-set expectation shows (the Dart test's
/// `_setTokens`).
fn set_tokens(expect: Option<&Json>) -> HashSet<String> {
    let mut out = HashSet::new();
    let e = match expect {
        Some(e) => e,
        None => return out,
    };
    let refused = e.get("refused");
    if let Some(r) = refused.filter(|r| r.as_object().is_some()) {
        out.insert(r.str_or("refusal"));
    }
    if refused.is_some_and(|r| r.as_array().is_some()) {
        out.insert("refused".to_string());
    }
    if e.get("pairs").is_some_and(|p| *p != Json::Null) && refused.is_none() {
        out.insert("built".to_string());
        if list_len(e.get("missingRoots")) > 0 {
            out.insert("missingRoots".to_string());
        }
    }
    if let Some(findings) = e.get("findings").and_then(|f| f.as_array()) {
        if e.get("clean") == Some(&Json::Bool(true)) {
            out.insert("clean".to_string());
        }
        if list_len(e.get("notStarted")) > 0 {
            out.insert("notStarted".to_string());
        }
        if list_len(e.get("notStartedPairs")) > 0 {
            out.insert("notStartedPairs".to_string());
        }
        for f in findings {
            out.insert(f.str_or("code"));
            out.insert(f.str_or("resolution"));
        }
        for d in e
            .get("documentFindings")
            .and_then(|d| d.as_array())
            .unwrap_or(&[])
        {
            let errors = d
                .as_array()
                .and_then(|x| x.get(1))
                .and_then(|x| x.as_array());
            for x in errors.unwrap_or(&[]) {
                out.insert(x.str_or("code"));
            }
        }
    }
    if list_len(e.get("changes")) > 0 {
        out.insert("renamed".to_string());
    }
    out
}

pub fn test_document_set(c: &mut Checker) {
    let table = read_json("document_set_cases.json");
    let fixture = table_model(&table);
    type CaseFn = fn(&SpecModel, &Json) -> Json;
    let groups: [(&str, CaseFn); 3] = [
        ("construction", set_construction_case),
        ("reports", set_report_case),
        ("renames", set_rename_case),
    ];
    for (group, run) in groups {
        for cc in table_cases(&table, group) {
            let name = format!("set.{}[{}]", group, cc.str_or("name"));
            let inline = if group == "construction" {
                cc.get("meta")
                    .filter(|m| **m != Json::Null)
                    .map(SpecModel::from_json)
            } else if group == "reports" {
                inline_model(cc)
            } else {
                None
            };
            let model = match group {
                "renames" => &fixture,
                "construction" => inline.as_ref().unwrap_or(&fixture),
                _ => model_of(&fixture, &inline, cc),
            };
            check_case(c, &name, || run(model, cc), cc.get("expect"));
            let shown = set_tokens(cc.get("expect"));
            for token in intent(cc) {
                c.check(
                    &format!("set.{}.intent[{}: {}]", group, cc.str_or("name"), token),
                    shown.contains(&token),
                    "",
                );
            }
        }
    }

    // DSC4: the real model pairs every synced class.
    match SpecDocumentSet::new(real_model(), Vec::new()) {
        Err(e) => {
            c.check("set.DSC4.blueprintRoot", false, &e.to_string());
            c.check("set.DSC4.pairs", false, &e.to_string());
        }
        Ok(real) => {
            c.check(
                "set.DSC4.blueprintRoot",
                real.blueprint_root == "D00SolutionBlueprint",
                &real.blueprint_root,
            );
            c.check(
                "set.DSC4.pairs",
                real.pairs().len() == 132,
                &real.pairs().len().to_string(),
            );
        }
    }
}

// --- derive_fields -------------------------------------------------------------------

fn derive_case(model: &SpecModel, cc: &Json) -> Json {
    let mut doc = state_document(cc.get("state").unwrap_or(&Json::Null));
    let options = SpecDeriveOptions {
        marked: cc.get("marked").and_then(|m| m.as_bool()).unwrap_or(true),
        author: cc.str_or("author"),
        at: cc.str_or("at"),
        dry_run: cc.bool_or("dryRun"),
    };
    let first = derive_fields(model, &mut doc, &options);
    let second = derive_fields(model, &mut doc, &options);
    // The first run's result is read after the second, as the reference
    // runners read it (the same document unless it is a dry run).
    let first_json = first.to_json(&doc);
    let written = second.written(&doc);
    let mut after = validate_links(model, written);
    after.extend(validate_document(model, written));
    obj(vec![
        ("first", first_json),
        ("second", second.to_json(&doc)),
        ("findingsAfter", conformance_links::validation_pairs(&after)),
        ("given", doc.to_json().to_json()),
    ])
}

/// Whether the intent `token` holds for the case's expectation; `None` for an
/// unknown token.
fn derive_intent_holds(token: &str, cc: &Json) -> Option<bool> {
    let e = cc.get("expect")?;
    let first = e.get("first")?;
    let changes = first
        .get("changes")
        .and_then(|c| c.as_array())
        .unwrap_or(&[]);
    let unresolved = |code: &str| {
        first
            .get("unresolved")
            .and_then(|u| u.as_array())
            .unwrap_or(&[])
            .iter()
            .any(|u| u.str_or("code") == code)
    };
    let any_change = |key: &str, want: &Json| {
        changes.iter().any(|x| {
            x.get(key)
                .is_some_and(|v| conformance_links::json_num_eq(v, want))
        })
    };
    Some(match token {
        "nothing" => changes.is_empty(),
        "step1" | "step2" | "step3" => {
            any_change("step", &Json::Int(i64::from(token.as_bytes()[4] - b'0')))
        }
        "rowAdded" | "rowRemoved" => any_change("kind", &jstr(token)),
        "marked" => changes.iter().any(|x| x.str_or("new").contains('{')),
        "clean" => list_len(e.get("findingsAfter")) == 0,
        "idempotent" => {
            let second = e.get("second")?;
            list_len(second.get("changes")) == 0
                && json_eq(
                    second.get("document").unwrap_or(&Json::Null),
                    first.get("document").unwrap_or(&Json::Null),
                )
        }
        "unchanged" => json_eq(
            e.get("given").unwrap_or(&Json::Null),
            cc.get("state").unwrap_or(&Json::Null),
        ),
        "unmarkable" | "derivedLookupMiss" => unresolved(token),
        _ => return None,
    })
}

pub fn intent_detail(known: bool) -> &'static str {
    if known {
        "does not hold"
    } else {
        "unknown intent token"
    }
}

pub fn test_derive_fields(c: &mut Checker) {
    let table = read_json("derive_cases.json");
    let model = table_model(&table);
    for cc in table_cases(&table, "cases") {
        let name = cc.str_or("name");
        check_case(
            c,
            &format!("derive[{}]", name),
            || derive_case(&model, cc),
            cc.get("expect"),
        );
        for token in intent(cc) {
            let holds = derive_intent_holds(&token, cc);
            c.check(
                &format!("derive.intent[{}: {}]", name, token),
                holds == Some(true),
                intent_detail(holds.is_some()),
            );
        }
    }
}

// --- prefill and backfill -------------------------------------------------------------

fn prefill_case(model: &SpecModel, cc: &Json) -> Json {
    let mut s = must_set(model, set_documents(cc.get("documents")));
    let options = SpecPrefillOptions {
        name: cc.str_or("name_"),
        pairs: case_pairs(cc),
    };
    let run = |s: &mut SpecDocumentSet<'_>| match prefill(s, &cc.str_or("root"), &options) {
        Ok(r) => r.to_json(),
        Err(e) => obj(vec![("refused", jstr(e.code.name()))]),
    };
    let first = run(&mut s);
    let second = run(&mut s);
    let after = sync_report(&s, None);
    obj(vec![
        ("first", first),
        ("second", second),
        (
            "reportAfter",
            obj(vec![
                ("countsByCode", after.counts_by_code_json()),
                ("notStartedPairs", jstrs(&after.not_started_pairs)),
            ]),
        ),
    ])
}

fn prefill_intent_holds(token: &str, cc: &Json) -> Option<bool> {
    let e = cc.get("expect")?;
    let first = e.get("first")?;
    let second = e.get("second")?;
    Some(match token {
        "created" => first.get("created") == Some(&Json::Bool(true)),
        "filled" => list_len(first.get("filledPairs")) > 0,
        "skipped" => list_len(first.get("skippedPairs")) > 0,
        "derived" => list_len(first.get("derived").and_then(|d| d.get("changes"))) > 0,
        "idempotent" => {
            list_len(second.get("filledPairs")) == 0
                && list_len(second.get("derived").and_then(|d| d.get("changes"))) == 0
                && json_eq(
                    second.get("document").unwrap_or(&Json::Null),
                    first.get("document").unwrap_or(&Json::Null),
                )
        }
        "agrees" => !e
            .get("reportAfter")
            .and_then(|r| r.get("countsByCode"))
            .and_then(|x| x.as_array())
            .unwrap_or(&[])
            .iter()
            .any(|x| {
                x.as_array()
                    .and_then(|p| p.first())
                    .and_then(|k| k.as_str())
                    .is_some_and(|k| k.starts_with("shared"))
            }),
        "noBlueprint" | "unknownRoot" => first.get("refused") == Some(&jstr(token)),
        _ => return None,
    })
}

fn backfill_case(model: &SpecModel, cc: &Json) -> Json {
    let mut s = must_set(model, set_documents(cc.get("documents")));
    let options = SpecBackfillOptions {
        pairs: case_pairs(cc),
        path: cc.str_or("path"),
        dry_run: cc.bool_or("dryRun"),
        author: cc.str_or("author"),
        date: cc.str_or("date"),
    };
    let run = |s: &mut SpecDocumentSet<'_>| match backfill(s, &options) {
        Ok(r) => r.to_json(),
        Err(e) => obj(vec![("refused", e.to_json())]),
    };
    let first = run(&mut s);
    let second = run(&mut s);
    let after = sync_report(&s, None);
    let given = Json::Array(
        s.names()
            .iter()
            .map(|n| {
                Json::Array(vec![
                    jstr(n),
                    s.get(n).map_or(Json::Null, |d| d.to_json().to_json()),
                ])
            })
            .collect(),
    );
    obj(vec![
        ("first", first),
        ("second", second),
        (
            "reportAfter",
            obj(vec![
                ("countsByCode", after.counts_by_code_json()),
                ("clean", Json::Bool(after.clean())),
            ]),
        ),
        ("given", given),
    ])
}

fn backfill_intent_holds(token: &str, cc: &Json) -> Option<bool> {
    let e = cc.get("expect")?;
    let first = e.get("first")?;
    let second = e.get("second")?;
    let changes = first
        .get("changes")
        .and_then(|c| c.as_array())
        .unwrap_or(&[]);
    let left = first.get("left").and_then(|c| c.as_array()).unwrap_or(&[]);
    Some(match token {
        "nothing" => first.get("refused").is_none() && changes.is_empty(),
        "value" | "elementAdded" | "elementRemoved" | "revision" | "derived" => {
            changes.iter().any(|x| x.str_or("kind") == token)
        }
        "heldHere" | "mayBeAdded" | "agent" => left.iter().any(|x| x.str_or("reason") == token),
        "setHasMarks" => first
            .get("refused")
            .is_some_and(|r| r.str_or("code") == "setHasMarks" && list_len(r.get("places")) > 0),
        "idempotent" => list_len(second.get("changes")) == 0,
        "unchanged" => json_eq(
            e.get("given").unwrap_or(&Json::Null),
            cc.get("documents").unwrap_or(&Json::Null),
        ),
        "cleanAfter" => {
            e.get("reportAfter").and_then(|r| r.get("clean")) == Some(&Json::Bool(true))
        }
        _ => return None,
    })
}

pub fn test_prefill_backfill(c: &mut Checker) {
    type CaseFn = fn(&SpecModel, &Json) -> Json;
    type HoldsFn = fn(&str, &Json) -> Option<bool>;
    let groups: [(&str, &str, CaseFn, HoldsFn); 2] = [
        (
            "prefill",
            "prefill_cases.json",
            prefill_case,
            prefill_intent_holds,
        ),
        (
            "backfill",
            "backfill_cases.json",
            backfill_case,
            backfill_intent_holds,
        ),
    ];
    for (label, file, kase, holds) in groups {
        let table = read_json(file);
        let fixture = table_model(&table);
        for cc in table_cases(&table, "cases") {
            let name = cc.str_or("name");
            let inline = inline_model(cc);
            let model = if label == "backfill" {
                model_of(&fixture, &inline, cc)
            } else {
                &fixture
            };
            check_case(
                c,
                &format!("{}[{}]", label, name),
                || kase(model, cc),
                cc.get("expect"),
            );
            for token in intent(cc) {
                let h = holds(&token, cc);
                c.check(
                    &format!("{}.intent[{}: {}]", label, name, token),
                    h == Some(true),
                    intent_detail(h.is_some()),
                );
            }
        }
    }
}
