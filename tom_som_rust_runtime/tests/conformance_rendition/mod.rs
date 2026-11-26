//! The rendition's navigation and generated parts in the conformance suite
//! (`link_rendition_cases.json`, SOM §11.2, §11.11, §11.12): each case's
//! document rendered with file stem `links`, the rendition (its markers
//! deleted or edited where the case says) handed to the parser, and the
//! rendition of what it staged; then the schema tier over the real model
//! (`uam_requirements_cut.json`). A port of the Go runner's
//! `conformance_rendition_test.go` (the Python runner's `test_link_rendition`
//! / `test_rendition_schema_tier`).

use super::conformance_document_set::{
    inline_model, intent, intent_detail, jtext, model_of, real_model, state_document, table_model,
};
use super::*;

use std::panic::{catch_unwind, AssertUnwindSafe};

use tom_som_rust_runtime::{DocSpecsSchema, DocSpecsValidator};

/// `doc` rendered as its root's rendition: the first root of `model` it holds
/// a value under.
fn rendition_of(
    model: &SpecModel,
    doc: &SpecDocument,
    file_stem: &str,
    markers: bool,
    generated: bool,
) -> Result<String, String> {
    let root = model
        .roots
        .iter()
        .find(|r| {
            let seg = if r.section_id.is_empty() {
                &r.type_
            } else {
                &r.section_id
            };
            doc.has_values_under(seg)
        })
        .ok_or_else(|| "no root holds a value".to_string())?;
    SpecDocumentMarkdown::new(model, doc)
        .with_file_stem(file_stem)
        .with_navigation(markers, generated)
        .export_root(root)
}

/// `^\[.*\]\{\.linked\}$`: a marker line.
fn is_marker_line(line: &str) -> bool {
    line.starts_with('[') && line.ends_with("]{.linked}")
}

/// `markdown` with its `linked` marker paragraphs removed.
fn without_markers(markdown: &str) -> String {
    let lines: Vec<&str> = markdown.split('\n').collect();
    let mut out: Vec<&str> = Vec::new();
    let mut i = 0;
    while i < lines.len() {
        if is_marker_line(lines[i]) {
            if i + 1 < lines.len() && lines[i + 1].is_empty() {
                i += 1;
            }
            i += 1;
            continue;
        }
        out.push(lines[i]);
        i += 1;
    }
    out.join("\n")
}

/// One rendition case, as the Dart test's `renditionCase` computes it.
fn rendition_case(model: &SpecModel, cc: &Json) -> Result<Json, String> {
    let doc = state_document(cc.get("state").unwrap_or(&Json::Null));
    let markers = cc.get("linkedMarkers").and_then(|v| v.as_bool()) != Some(false);
    let generated = cc.get("generatedParts").and_then(|v| v.as_bool()) != Some(false);
    let markdown = rendition_of(model, &doc, "links", markers, generated)?;
    let mut given = markdown.clone();
    if cc.bool_or("dropMarkers") {
        given = without_markers(&given);
    }
    for e in cc.get("edits").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let pair = e.as_array().ok_or("an edit is [from, to]")?;
        let from = pair[0].as_str().unwrap_or("");
        let to = pair[1].as_str().unwrap_or("");
        if !given.contains(from) {
            return Err(format!(
                "{}: the rendition has no {:?}",
                cc.str_or("name"),
                from
            ));
        }
        given = given.replacen(from, to, 1);
    }
    let parsed = SpecDocument::from_markdown(&given, model);
    let mut out: Vec<(String, Json)> = vec![("markdown".to_string(), Json::Str(markdown.clone()))];
    if given != markdown {
        out.push(("given".to_string(), Json::Str(given.clone())));
    }
    out.push((
        "rejections".to_string(),
        Json::Array(
            parsed
                .rejections()
                .iter()
                .map(|r| Json::Str(r.reason.clone()))
                .collect(),
        ),
    ));
    let matches =
        parsed.document.to_json().to_canonical_json() == doc.to_json().to_canonical_json();
    out.push(("parseMatches".to_string(), Json::Bool(matches)));
    let reemit = rendition_of(model, &parsed.document, "links", markers, generated)?;
    out.push(("reemitMatches".to_string(), Json::Bool(reemit == markdown)));
    Ok(Json::Object(out))
}

/// `\[Also in \[[^\]]+\]\([^)]+\), held <where>`.
fn has_also_in(md: &str, held: &str) -> bool {
    let start = "[Also in [";
    md.match_indices(start).any(|(i, _)| {
        let rest = &md[i + start.len()..];
        let Some(j) = rest.find(']').filter(|&j| j > 0) else {
            return false;
        };
        let Some(after) = rest[j..].strip_prefix("](") else {
            return false;
        };
        let Some(k) = after.find(')').filter(|&k| k > 0) else {
            return false;
        };
        after[k..].starts_with(&format!("), held {}", held))
    })
}

fn is_word(b: u8) -> bool {
    b.is_ascii_alphanumeric() || b == b'_'
}

/// `\w+, \w+` at the start of `s`.
fn two_words(s: &[u8]) -> bool {
    let a = s.iter().take_while(|&&b| is_word(b)).count();
    a > 0 && s[a..].starts_with(b", ") && s.get(a + 2).is_some_and(|&b| is_word(b))
}

/// `Derived from (\[[^\]]+\]\([^)]+\)(,)?)+: \w+, \w+`.
fn has_derived_two_fields(md: &str) -> bool {
    let start = "Derived from ";
    md.match_indices(start).any(|(i, _)| {
        let b = md.as_bytes();
        let mut p = i + start.len();
        let mut ends: Vec<usize> = Vec::new();
        while b.get(p) == Some(&b'[') {
            let Some(j) = md[p + 1..].find(']').filter(|&j| j > 0) else {
                break;
            };
            let q = p + 1 + j;
            if !md[q..].starts_with("](") {
                break;
            }
            let Some(k) = md[q + 2..].find(')').filter(|&k| k > 0) else {
                break;
            };
            p = q + 2 + k + 1;
            ends.push(p);
            if b.get(p) == Some(&b',') {
                p += 1;
                ends.push(p);
            }
        }
        ends.iter()
            .any(|&e| md[e..].starts_with(": ") && two_words(&b[e + 2..]))
    })
}

/// `(?m)^#+ <!--\[LNK-REF\]--> <a id="REQ-EXPORT/LNK-1/LNK-REF"></a> `.
fn has_qualified_three(md: &str) -> bool {
    md.split('\n').any(|l| {
        let rest = l.trim_start_matches('#');
        rest.len() < l.len()
            && rest.starts_with(" <!--[LNK-REF]--> <a id=\"REQ-EXPORT/LNK-1/LNK-REF\"></a> ")
    })
}

/// `(?m)^## <!--\[REQCOV\]--> <a id="REQCOV"></a> [^\n]*\n\n(\[[^\n]*\]\{\.linked\}\n\n)?::: \{\.derived `.
fn has_generated_first(md: &str) -> bool {
    let lines: Vec<&str> = md.split('\n').collect();
    let derived = |k: usize| {
        lines
            .get(k)
            .is_some_and(|l| l.starts_with("::: {.derived "))
    };
    (0..lines.len()).any(|i| {
        lines[i].starts_with("## <!--[REQCOV]--> <a id=\"REQCOV\"></a> ")
            && lines.get(i + 1) == Some(&"")
            && (derived(i + 2)
                || (lines.get(i + 2).is_some_and(|l| is_marker_line(l))
                    && lines.get(i + 3) == Some(&"")
                    && derived(i + 4)))
    })
}

/// Whether the rendition-case intent `token` holds in case `cc` (the Dart
/// test's `_renditionIntentHolds`); `None` for an unknown token.
fn rendition_intent_holds(token: &str, cc: &Json) -> Option<bool> {
    let e = cc.get("expect").cloned().unwrap_or(Json::Null);
    let md = e.str_or("markdown");
    let md = md.as_str();
    let parsed = e.get("parseMatches") == Some(&Json::Bool(true));
    let reemit = e.get("reemitMatches") == Some(&Json::Bool(true));
    let given = e.get("given").and_then(|g| g.as_str()).map(str::to_string);
    let edited = given.is_some();
    let given = given.unwrap_or_default();
    Some(match token {
        "alsoInHeldThere" => has_also_in(md, "there"),
        "alsoInHeldHere" => has_also_in(md, "here"),
        "heldException" => md.contains(" except REQ.owner"),
        "summaryOf" => md.contains("held there except REQ.owner; Summary of [REQ-EXPORT](#REQ-EXPORT)]{.linked}"),
        "summarisedIn" => md.contains("Summarised in [KEY-1](#KEY-1)"),
        "derivedTwoFields" => has_derived_two_fields(md),
        "extractedFrom" => md.contains("[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}"),
        "copyOf" => md.contains("[Copy of [CRIT](#CRIT), edit it there]{.linked}"),
        "copiedTo" => md.contains("Copied to [CRIT](#CSUM/CRIT)"),
        "copyAnchors" => md.contains("<a id=\"CSUM/CRIT/CRIT-SPEED\"></a>"),
        "qualifiedThree" => has_qualified_three(md),
        "markerRestored" => edited && !given.contains("{.linked}") && parsed && reemit,
        "handEditDiscarded" => edited && given.contains("Copy of [X]") && parsed && reemit,
        "emptyMarker" => md.contains("[]{.linked}\n\n[To be chosen") && parsed,
        "spanKept" => jtext(cc.get("state").unwrap_or(&Json::Null)).contains("{.linked}") && parsed,
        "dangling" => md.contains("[Also in [BLU REQ-PRESETS](links.blu.tomspecs.md#REQ-PRESETS), held here"),
        "generatedTrace" => md.contains(
            "::: {.derived label=\"Generated from each requirement's traceability; edit it there\"}\n\
             | Requirement | Use cases | Screens | Data entities | Tests |",
        ),
        "generatedCoverage" => ["yes", "no"].iter().any(|v| {
            md.contains(&format!(
                "| Requirement | Covered | By |\n| --- | --- | --- |\n\
                 | [FRE-REQU-TENANT-LIFECYCLE](#FRE-REQU-TENANT-LIFECYCLE) | {} |",
                v
            ))
        }),
        "generatedRelationships" => md.contains("| Requirement | Dependency | Related requirement |"),
        "generatedFirst" => has_generated_first(md),
        "generatedOverview" => {
            md.contains("<!--[RO-TRAC]-->") && md.contains("| Requirement | Use cases | Screens |")
        }
        "generatedUseCases" => md.contains("| [INEN-INTE-UC-02](#INEN-INTE-UC-02) |  | [FRE-REQU-TENANT-FEATURES]("),
        "generatedEditDiscarded" => {
            edited && given.contains("| Requirement | Covered |\n") && parsed && reemit
        }
        "noGenerated" => !md.contains("{.derived"),
        "emptyGenerated" => md.contains("::: {.derived}\n:::\n\n::: {.derived}\nTraced by hand.\n:::"),
        "summaryRowLink" => {
            md.contains("| <a id=\"TOP-BETA\"></a>[TOP-BETA](#TOP-BETA) |")
                && md.contains("| <a id=\"TOP-BETA\"></a>TOP-BETA |")
        }
        "noMarkers" => !md.contains("{.linked}") && md.contains("<a id=\"REQ-EXPORT/REQD\"></a>"),
        "roundTrip" => !edited && parsed && reemit,
        "clean" => e.get("rejections").and_then(|r| r.as_array()).is_some_and(|r| r.is_empty()),
        _ => return None,
    })
}

fn sorted_keys(v: &Json) -> Vec<String> {
    let mut keys: Vec<String> = v
        .as_object()
        .map(|o| o.iter().map(|(k, _)| k.clone()).collect())
        .unwrap_or_default();
    keys.sort();
    keys
}

fn panic_text(e: Box<dyn std::any::Any + Send>) -> String {
    e.downcast_ref::<String>()
        .cloned()
        .or_else(|| e.downcast_ref::<&str>().map(|s| s.to_string()))
        .unwrap_or_default()
}

/// Replays `link_rendition_cases.json`: each case's rendition, what the
/// parser makes of it and the rendition of that, against the expectation,
/// and its intent.
pub fn test_link_rendition(c: &mut Checker) {
    let table = read_json("link_rendition_cases.json");
    let fixture = table_model(&table);
    for cc in table.get("cases").and_then(|v| v.as_array()).unwrap_or(&[]) {
        let name = format!("links.rendition[{}]", cc.str_or("name"));
        let inline = inline_model(cc);
        let model = model_of(&fixture, &inline, cc);
        match catch_unwind(AssertUnwindSafe(|| rendition_case(model, cc))) {
            Err(e) => c.check(&name, false, &format!("threw {}", panic_text(e))),
            Ok(Err(e)) => c.check(&name, false, &format!("threw {}", e)),
            Ok(Ok(got)) => {
                let expect = cc.get("expect").cloned().unwrap_or(Json::Null);
                for k in [
                    "markdown",
                    "given",
                    "rejections",
                    "parseMatches",
                    "reemitMatches",
                ] {
                    let (g, w) = (got.get(k), expect.get(k));
                    let ok = match (g, w) {
                        (Some(g), Some(w)) => json_eq(g, w),
                        (None, None) => true,
                        _ => false,
                    };
                    let detail = if ok {
                        String::new()
                    } else {
                        let show =
                            |v: Option<&Json>| v.map(jtext).unwrap_or_else(|| "null".to_string());
                        format!("got {} want {}", show(g), show(w))
                    };
                    c.check(&format!("{}.{}", name, k), ok, &detail);
                }
                let (gk, ek) = (sorted_keys(&got), sorted_keys(&expect));
                c.check(
                    &format!("{}.keys", name),
                    gk == ek,
                    &format!("{} vs {}", gk.join(","), ek.join(",")),
                );
            }
        }
        for token in intent(cc) {
            let holds = rendition_intent_holds(&token, cc);
            c.check(
                &format!("links.rendition.intent[{}: {}]", cc.str_or("name"), token),
                holds == Some(true),
                intent_detail(holds.is_some()),
            );
        }
    }
}

/// The schema tier finds nothing in the markers and generated parts (the
/// Dart test's RNC5, real model): each document's findings with navigation
/// equal its findings without.
pub fn test_rendition_schema_tier(c: &mut Checker) {
    let table = read_json("uam_requirements_cut.json");
    let rsp = state_document(table.get("rsp").unwrap_or(&Json::Null));
    let sbp = state_document(table.get("blueprint").unwrap_or(&Json::Null));
    let mut isc = SpecDocument::new();
    let item = isc
        .add_list_item_with_section_id("ISC/interactionCatalog/INEN-INTE-LST", "INEN-INTE-UC-01")
        .expect("add the interaction");
    isc.set_form_field(
        &format!("{}/INTR", item),
        "relatedRequirements",
        "FRE-REQU-TENANT-LIFECYCLE",
    );
    let model = real_model();
    for (doc, schema_id) in [
        (&rsp, "requirements-specification"),
        (&sbp, "solution-blueprint"),
        (&isc, "interaction-scenarios"),
    ] {
        let name = format!("links.rendition.schemaTier[{}]", schema_id);
        let file = corpus_dir()
            .join("../../tom_som_dart_v0/schemas")
            .join(schema_id)
            .join(format!("{}.1.0.docspecs-schema.yaml", schema_id));
        let schema = match std::fs::read_to_string(&file)
            .map_err(|e| e.to_string())
            .and_then(|t| DocSpecsSchema::from_yaml_text(&t))
        {
            Ok(s) => s,
            Err(e) => {
                c.check(&name, false, &format!("threw {}", e));
                continue;
            }
        };
        let findings = |navigation: bool| -> Result<(String, Vec<String>), String> {
            let md = rendition_of(model, doc, "", navigation, navigation)?;
            let mut out: Vec<String> = DocSpecsValidator::with_tom_specs(schema.clone(), true)
                .validate_markdown(&md)
                .iter()
                .map(|v| format!("{} {}", v.rule, v.section_id))
                .collect();
            out.sort();
            Ok((md, out))
        };
        let (md, with) = match findings(true) {
            Ok(r) => r,
            Err(e) => {
                c.check(&name, false, &format!("threw {}", e));
                continue;
            }
        };
        let without = match findings(false) {
            Ok((_, w)) => w,
            Err(e) => {
                c.check(&name, false, &format!("threw {}", e));
                continue;
            }
        };
        c.check(&format!("{}.derived", name), md.contains("{.derived"), "");
        c.check(
            &name,
            with == without,
            &format!("got {:?} want {:?}", with, without),
        );
    }
}

#[test]
fn intent_matchers_read_their_patterns() {
    assert!(has_also_in(
        "x [Also in [A B](f#B), held there]{.linked}",
        "there"
    ));
    assert!(!has_also_in(
        "x [Also in [A B](f#B), held here]{.linked}",
        "there"
    ));
    assert!(has_derived_two_fields(
        "[Derived from [A](#A),[B](#B): x, y]"
    ));
    assert!(has_derived_two_fields(
        "[Derived from [A](#A): total, count]"
    ));
    assert!(!has_derived_two_fields("[Derived from [A](#A): total]"));
    assert!(has_qualified_three(
        "### <!--[LNK-REF]--> <a id=\"REQ-EXPORT/LNK-1/LNK-REF\"></a> Ref"
    ));
    assert!(has_generated_first(
        "## <!--[REQCOV]--> <a id=\"REQCOV\"></a> Cov\n\n[x]{.linked}\n\n::: {.derived label=\"y\"}"
    ));
    assert!(has_generated_first(
        "## <!--[REQCOV]--> <a id=\"REQCOV\"></a> Cov\n\n::: {.derived x}"
    ));
    assert_eq!(without_markers("a\n[x]{.linked}\n\nb"), "a\nb");
}
