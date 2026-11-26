//! The section-link part of the conformance suite (`tom_specs_model_rules.md`
//! §9.7): the typed readers of the link annotations and the place / filter
//! grammar (`link_reader_cases.json` over `links.meta.json`), the link checks
//! of one document (`link_validation_cases.json`), and the typed values and
//! headlines under review (the `typed_read` / `validation_pairs` ops the
//! `typedCases` of `inline_mark_cases.json` / `change_mark_cases.json` use). A
//! port of the Go runner's `conformance_links_test.go` (the Python runner's
//! `test_link_readers` / `test_link_validation` / `_run_typed_mark_cases`).

use super::*;

use tom_som_rust_runtime::spec_typed_values::{
    som_parse_bool, som_parse_double, som_parse_enum_name, som_parse_int, som_parse_num,
    som_scalar_base, som_typed_reading, SomNum,
};
use tom_som_rust_runtime::{
    spec_same_as_bindings, validate_links, SpecPlace, SpecPlaceError, SpecPlaceFilter,
    SpecValidationError, SPEC_PLACE_PROBLEM_MALFORMED, SPEC_VALIDATION_CODE_COUNT_MISMATCH,
    SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS, SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
    SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY, SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW,
    SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING, SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE,
    SPEC_VALIDATION_CODE_INVERSE_MISSING, SPEC_VALIDATION_CODE_LINK_VALUE_PENDING,
    SPEC_VALIDATION_CODE_SAME_AS_MISMATCH, SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE,
    SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL,
};

// --- typed values and headlines under review ---------------------------------

/// The findings as `{path, code}`.
pub fn validation_pairs(errs: &[SpecValidationError]) -> Json {
    Json::Array(
        errs.iter()
            .map(|e| obj(vec![("path", jstr(&e.path)), ("code", jstr(&e.code))]))
            .collect(),
    )
}

/// The typed reading of the value at `path` / `field`: an enum by its name,
/// `int`, `double`, `num` and `bool` as numbers and booleans, null when the
/// text reads as nothing — with any inline mark rejected (its old value).
pub fn typed_read(model: &SpecModel, doc: &SpecDocument, op: &Json) -> Json {
    let path = op.str_or("path");
    let field = op.get("field").and_then(|f| f.as_str());
    let res = SpecReflection::new(model).resolve(&path);
    let res_field = res.as_ref().and_then(|r| r.field.as_ref());
    let spec = match (field, res_field) {
        (Some(name), Some(f)) => f.form_fields.iter().find(|ff| ff.name == name),
        _ => None,
    };
    let raw = match field {
        Some(f) => doc.form_field(&path, f),
        None => doc.content(&path),
    };
    let raw = raw.map(String::as_str);
    let (type_name, values): (&str, &[String]) = match (spec, res_field) {
        (Some(s), _) => (&s.type_, &s.enum_values),
        (None, Some(f)) => (&f.type_, &f.enum_values),
        _ => ("", &[]),
    };
    if !values.is_empty() {
        return som_parse_enum_name(raw, values).map_or(Json::Null, |v| jstr(&v));
    }
    match som_scalar_base(Some(type_name)) {
        Some("int") => som_parse_int(raw).map_or(Json::Null, Json::Int),
        Some("double") => som_parse_double(raw).map_or(Json::Null, Json::Float),
        Some("num") => match som_parse_num(raw) {
            Some(SomNum::Int(n)) => Json::Int(n),
            Some(SomNum::Double(d)) => Json::Float(d),
            None => Json::Null,
        },
        Some("bool") => som_parse_bool(raw).map_or(Json::Null, Json::Bool),
        _ => raw.map_or(Json::Null, |r| jstr(&som_typed_reading(r))),
    }
}

/// Structural JSON equality that compares numbers by value (`2` == `2.0`):
/// a typed reading of a `double` is a number, however the corpus writes it.
pub fn json_num_eq(a: &Json, b: &Json) -> bool {
    let num = |v: &Json| match v {
        Json::Int(n) => Some(*n as f64),
        Json::Float(f) => Some(*f),
        _ => None,
    };
    match (num(a), num(b)) {
        (Some(x), Some(y)) => x == y,
        _ => json_eq(a, b),
    }
}

// --- the section-link readers ------------------------------------------------

/// What the readers return for `model`, in canonical JSON: every class sync,
/// every member link, every form-field qualifier, and the `@SameAs` bindings
/// per root. Classes by name, fields and form fields in declaration order (the
/// Dart test's `linkReadBack`).
fn link_read_back(model: &SpecModel) -> Json {
    let mut names: Vec<&String> = model.classes.keys().collect();
    names.sort();
    let refl = SpecReflection::new(model);
    let mut classes = Vec::new();
    let mut fields = Vec::new();
    let mut form_fields = Vec::new();
    for n in &names {
        if let Some(sync) = model.classes[*n].synced_with() {
            classes.push(obj(vec![
                ("class", jstr(n)),
                ("syncedWith", sync.to_json()),
            ]));
        }
    }
    for n in &names {
        for f in &model.classes[*n].fields {
            let (sync, summary, derived) = (f.synced_with(), f.summary_of(), f.derived_from());
            let (extracts, same_as) = (f.extracts_links(), f.same_as());
            if sync.is_none()
                && summary.is_none()
                && derived.is_none()
                && extracts.is_empty()
                && same_as.is_none()
            {
                continue;
            }
            let mut row = vec![("class", jstr(n)), ("field", jstr(&f.name))];
            if let Some(s) = sync {
                row.push(("syncedWith", s.to_json()));
            }
            if let Some(s) = summary {
                row.push(("summaryOf", s.to_json()));
            }
            if let Some(d) = derived {
                row.push(("derivedFrom", d.to_json()));
            }
            if !extracts.is_empty() {
                row.push((
                    "extractsLinks",
                    Json::Array(extracts.iter().map(|e| e.to_json()).collect()),
                ));
            }
            if let Some(s) = same_as {
                row.push(("sameAs", s.to_json()));
            }
            fields.push(obj(row));
        }
    }
    for n in &names {
        for f in &model.classes[*n].fields {
            for ff in &f.form_fields {
                if ff.derived_from.is_none() && ff.inverse_of.is_none() && ff.summary_of.is_none() {
                    continue;
                }
                let mut row = vec![
                    ("class", jstr(n)),
                    ("field", jstr(&f.name)),
                    ("formField", jstr(&ff.name)),
                ];
                if let Some(d) = &ff.derived_from {
                    row.push(("derivedFrom", d.to_json()));
                }
                if let Some(i) = &ff.inverse_of {
                    row.push(("inverseOf", i.to_json()));
                }
                if let Some(s) = &ff.summary_of {
                    row.push(("summaryOf", s.to_json()));
                }
                form_fields.push(obj(row));
            }
        }
    }
    let bindings: Vec<Json> = model
        .roots
        .iter()
        .flat_map(|r| spec_same_as_bindings(&refl, &r.type_))
        .map(|b| b.to_json())
        .collect();
    obj(vec![
        ("classes", Json::Array(classes)),
        ("fields", Json::Array(fields)),
        ("formFields", Json::Array(form_fields)),
        ("sameAsBindings", Json::Array(bindings)),
        ("classCount", Json::Int(model.classes.len() as i64)),
    ])
}

/// The problem of a place error, or the error when it is no place problem.
fn place_problem(err: SpecPlaceError) -> Result<String, String> {
    if err.is_place_problem() {
        Ok(err.problem)
    } else {
        Err(err.to_string())
    }
}

/// One place case: the text parsed, then resolved under `anchor` when given.
fn place_case(refl: &SpecReflection, c: &Json) -> Result<Json, String> {
    let place = match SpecPlace::try_parse(&c.str_or("text")) {
        Some(p) => p,
        None => return Ok(obj(vec![("problem", jstr(SPEC_PLACE_PROBLEM_MALFORMED))])),
    };
    let anchor = match c.get("anchor").and_then(|a| a.as_str()) {
        Some(a) => a,
        None => return Ok(obj(vec![("parsed", place.to_json())])),
    };
    Ok(match place.resolve(refl, anchor) {
        Ok(r) => obj(vec![("parsed", place.to_json()), ("resolved", r.to_json())]),
        Err(e) => obj(vec![
            ("parsed", place.to_json()),
            ("problem", jstr(&place_problem(e)?)),
        ]),
    })
}

/// A stored value of a filter case as text (a non-string as its JSON).
fn stored_text(v: &Json) -> String {
    match v {
        Json::Str(s) => s.clone(),
        Json::Int(n) => n.to_string(),
        Json::Float(f) => f.to_string(),
        Json::Bool(b) => b.to_string(),
        Json::Null => "null".to_string(),
        other => format!("{:?}", other),
    }
}

/// One filter case: the text parsed, resolved under `anchor` when given, and
/// matched against `stored` when given.
fn filter_case(refl: &SpecReflection, c: &Json) -> Result<Json, String> {
    let f = match SpecPlaceFilter::try_parse(&c.str_or("text")) {
        Some(f) => f,
        None => return Ok(obj(vec![("problem", jstr(SPEC_PLACE_PROBLEM_MALFORMED))])),
    };
    let mut out = vec![("parsed", f.to_json())];
    if let Some(stored) = c.get("stored").and_then(|s| s.as_array()) {
        let stored: Vec<String> = stored.iter().map(stored_text).collect();
        out.push(("matches", Json::Bool(f.matches(&stored))));
    }
    if let Some(anchor) = c.get("anchor").and_then(|a| a.as_str()) {
        match f.resolve(refl, anchor) {
            Ok(r) => out.push(("resolved", r.to_json())),
            Err(e) => out.push(("problem", jstr(&place_problem(e)?))),
        }
    }
    Ok(obj(out))
}

/// Whether the reader-case intent `token` holds in the expectation `e` (the
/// Dart test's `_readerIntentHolds`); `None` for an unknown token.
fn reader_intent_holds(token: &str, e: &Json) -> Option<bool> {
    let list = |key: &str| {
        e.get(key)
            .and_then(|l| l.as_array())
            .unwrap_or(&[])
            .to_vec()
    };
    let any_row = |key: &str, pred: &dyn Fn(&Json) -> bool| list(key).iter().any(pred);
    let has = |key: &str, member: &str| any_row(key, &|m: &Json| m.get(member).is_some());
    Some(match token {
        "syncedWith" => !list("classes").is_empty(),
        "syncRelationWhere" => any_row("classes", &|m: &Json| {
            m.get("syncedWith")
                .and_then(|s| s.get("relations"))
                .and_then(|r| r.as_array())
                .is_some_and(|rels| rels.iter().any(|x| x.get("where").is_some()))
        }),
        "summaryOf" => has("fields", "summaryOf"),
        "summaryOfDocument" => any_row("fields", &|m: &Json| {
            m.get("summaryOf")
                .is_some_and(|s| s.get("document").is_some())
        }),
        "derivedFrom" => has("fields", "derivedFrom"),
        "extractsLinksRepeated" => any_row("fields", &|m: &Json| {
            m.get("extractsLinks")
                .and_then(|l| l.as_array())
                .is_some_and(|l| l.len() > 1)
        }),
        "sameAs" => has("fields", "sameAs"),
        "formDerivedFrom" => has("formFields", "derivedFrom"),
        "formInverseOf" => has("formFields", "inverseOf"),
        "formSymmetric" => any_row("formFields", &|m: &Json| {
            m.get("inverseOf")
                .and_then(|i| i.get("fields"))
                .and_then(|f| f.as_array())
                .is_some_and(|fs| fs.iter().any(|f| f.as_str() == Some("@self")))
        }),
        "formSummaryOf" => has("formFields", "summaryOf"),
        "sameAsHolder" => has("sameAsBindings", "holder"),
        "loadsUnchanged" => {
            e.get("classCount").and_then(|c| c.as_i64()).unwrap_or(0) > 0
                && list("classes").is_empty()
                && list("fields").is_empty()
                && list("formFields").is_empty()
                && list("sameAsBindings").is_empty()
        }
        _ => return None,
    })
}

/// Every string a text case's expectation shows: kinds, problems, and
/// `matches` / `noMatch` (the Dart test's `_tokens`).
fn link_tokens(e: &Json) -> HashSet<String> {
    fn walk(v: &Json, key: &str, out: &mut HashSet<String>) {
        match v {
            Json::Array(items) => items.iter().for_each(|x| walk(x, "", out)),
            Json::Object(pairs) => pairs.iter().for_each(|(k, x)| walk(x, k, out)),
            Json::Bool(b) if key == "matches" => {
                out.insert(if *b { "matches" } else { "noMatch" }.to_string());
            }
            Json::Str(s) if key == "kind" || key == "problem" => {
                out.insert(s.clone());
            }
            _ => {}
        }
    }
    let mut out = HashSet::new();
    walk(e, "", &mut out);
    out
}

pub fn test_link_readers(c: &mut Checker) {
    let meta = read_json("links.meta.json");
    let table = read_json("link_reader_cases.json");
    let reader_cases = cases(&table, "cases");
    c.check(
        "links.reader.cases",
        !reader_cases.is_empty(),
        "no cases in link_reader_cases.json",
    );
    for cc in reader_cases {
        let name = format!("links.reader[{}]", cc.str_or("name"));
        let m = if cc.get("model").and_then(|m| m.as_str()) == Some("links.meta.json") {
            SpecModel::from_json(&meta)
        } else {
            SpecModel::from_json(cc.get("meta").unwrap_or(&Json::Null))
        };
        let want = cc.get("expect").cloned().unwrap_or(Json::Null);
        let got = link_read_back(&m);
        c.check(
            &name,
            json_eq(&got, &want),
            &format!("got {:?} want {:?}", got, want),
        );
        for token in str_list(cc.get("intent")) {
            let holds = reader_intent_holds(&token, &want);
            c.check(
                &format!("links.reader.intent[{}: {}]", cc.str_or("name"), token),
                holds == Some(true),
                if holds.is_none() {
                    "unknown intent token"
                } else {
                    "does not hold"
                },
            );
        }
    }
    let model = SpecModel::from_json(&meta);
    let refl = SpecReflection::new(&model);

    let text_cases = table.get("textCases").cloned().unwrap_or(Json::Null);
    let mut run_text = |kind: &str, run: &dyn Fn(&Json) -> Result<Json, String>| {
        let all = cases(
            &text_cases,
            if kind == "place" { "places" } else { "filters" },
        );
        c.check(
            &format!("links.{}.cases", kind),
            !all.is_empty(),
            &format!("no {} cases", kind),
        );
        for cc in all {
            let name = format!("links.{}[{}]", kind, cc.str_or("name"));
            let want = cc.get("expect").cloned().unwrap_or(Json::Null);
            match run(cc) {
                Ok(got) => c.check(
                    &name,
                    json_eq(&got, &want),
                    &format!("got {:?} want {:?}", got, want),
                ),
                Err(e) => c.check(&name, false, &format!("threw {}", e)),
            }
            let shown = link_tokens(&want);
            for token in str_list(cc.get("intent")) {
                c.check(
                    &format!("links.{}.intent[{}: {}]", kind, cc.str_or("name"), token),
                    shown.contains(&token),
                    "",
                );
            }
        }
    };
    run_text("place", &|cc| place_case(&refl, cc));
    run_text("filter", &|cc| filter_case(&refl, cc));

    // LR1: the class sync is read with its relations.
    let reqs = model
        .class_named("Requirements")
        .and_then(|c| c.synced_with());
    c.check(
        "links.LR1.sync",
        reqs.as_ref().is_some_and(|s| {
            s.document == "Detail"
                && s.detail_only == ["REQX"]
                && s.held_here == ["REQ.owner"]
                && s.relations.len() == 1
                && s.relations[0].relation == "subset"
        }),
        "",
    );
    let crit = model.class_named("Criteria").and_then(|c| c.synced_with());
    c.check(
        "links.LR1.where",
        crit.as_ref().is_some_and(|s| {
            s.relations.len() == 1 && s.relations[0].r#where == "CRITE.kind=functional|quality"
        }),
        "",
    );
    c.check(
        "links.LR1.none",
        model
            .class_named("Blueprint")
            .is_some_and(|c| c.synced_with().is_none()),
        "",
    );

    // LR2: member links and the repeated @ExtractsLinks.
    let req = model.class_named("Requirement").expect("Requirement");
    let field = |name: &str| {
        req.field_named(name)
            .unwrap_or_else(|| panic!("no field {}", name))
    };
    let links = field("links").extracts_links();
    let modes: Vec<&str> = links.iter().map(|x| x.mode.as_str()).collect();
    c.check(
        "links.LR2.modes",
        modes == ["generate", "warn"],
        &modes.join(","),
    );
    c.check(
        "links.LR2.set",
        links
            .first()
            .is_some_and(|l| l.set == [("LNK.linkType".to_string(), "namedInText".to_string())]),
        "",
    );
    c.check(
        "links.LR2.copy",
        field("abstract")
            .derived_from()
            .is_some_and(|d| d.kind == "copy"),
        "",
    );
    c.check(
        "links.LR2.map",
        field("prerequisites")
            .derived_from()
            .is_some_and(|d| d.map == [("PRE.ref".to_string(), "LNK-REF.ref".to_string())]),
        "",
    );
    c.check(
        "links.LR2.noSummary",
        field("links").summary_of().is_none(),
        "",
    );

    // LR3: the form-field qualifiers.
    let ff = |cls: &str, field: &str, name: &str| {
        model
            .class_named(cls)
            .and_then(|c| c.field_named(field))
            .and_then(|f| f.form_fields.iter().find(|ff| ff.name == name))
            .unwrap_or_else(|| panic!("no form field {}.{}.{}", cls, field, name))
            .clone()
    };
    let conflicts = ff("Requirement", "constraints", "conflictsWith").derived_from;
    c.check(
        "links.LR3.where",
        conflicts.is_some_and(|d| d.r#where == "LNK.linkType=conflict"),
        "",
    );
    c.check(
        "links.LR3.symmetric",
        ff("Link", "ref", "ref")
            .inverse_of
            .is_some_and(|i| i.symmetric()),
        "",
    );
    c.check(
        "links.LR3.notSymmetric",
        ff("Requirement", "trace", "relatedScreens")
            .inverse_of
            .is_some_and(|i| !i.symmetric()),
        "",
    );
    c.check(
        "links.LR3.summaryDocument",
        ff("Blueprint", "focus", "focusScreens")
            .summary_of
            .is_some_and(|s| s.document == "Screens"),
        "",
    );

    // LR4: the real model — S1 has one holder in each document.
    let real = load_som_model();
    let real_refl = SpecReflection::new(&real);
    for root in ["D00SolutionBlueprint", "D10QualityAcceptancePlan"] {
        let bindings = spec_same_as_bindings(&real_refl, root);
        c.check(
            &format!("links.LR4[{}]", root),
            bindings.len() == 1
                && bindings[0].class_name == "AcceptanceCriteriaList"
                && bindings[0].problem.is_empty()
                && bindings[0].copy_path.ends_with("/detailedCriteria"),
            &format!("{:?}", bindings),
        );
    }

    // CO1–CO2: countOf reads the filter, `|` included.
    let base = "BLU/requirements";
    let doc = |settled: &str, total: &str| {
        let mut d = SpecDocument::new();
        for status in ["approved", "done", "draft"] {
            let item = d.add_list_item(&format!("{}/REQ-ITEM-LST", base));
            d.set_form_field(&format!("{}/content", item), "status", status);
        }
        d.set_form_field(&format!("{}/REQS-SUM", base), "total", total);
        d.set_form_field(&format!("{}/REQS-SUM", base), "settled", settled);
        d
    };
    let counts = |d: &SpecDocument| -> Vec<String> {
        validate_document(&model, d)
            .into_iter()
            .filter(|e| e.code == SPEC_VALIDATION_CODE_COUNT_MISMATCH)
            .map(|e| e.path)
            .collect()
    };
    let sum = format!("{}/REQS-SUM", base);
    for (name, got, want) in [
        ("links.CO1", counts(&doc("2", "3")), vec![]),
        (
            "links.CO2.settled",
            counts(&doc("3", "3")),
            vec![sum.clone()],
        ),
        ("links.CO2.total", counts(&doc("2", "2")), vec![sum.clone()]),
    ] {
        c.check(name, got == want, &format!("got {:?} want {:?}", got, want));
    }
}

// --- the link checks of one document -----------------------------------------

fn finding_pairs(errs: &[SpecValidationError]) -> Vec<(String, String)> {
    errs.iter()
        .map(|e| (e.path.clone(), e.code.clone()))
        .collect()
}

fn want_pairs(v: Option<&Json>) -> Vec<(String, String)> {
    v.and_then(|l| l.as_array())
        .unwrap_or(&[])
        .iter()
        .map(|e| (e.str_or("path"), e.str_or("code")))
        .collect()
}

pub fn test_link_validation(c: &mut Checker) {
    let table = read_json("link_validation_cases.json");
    let meta_name = match table.str_or("model") {
        m if m.is_empty() => "links.meta.json".to_string(),
        m => m,
    };
    let model = SpecModel::from_json(&read_json(&meta_name));
    let all = cases(&table, "cases");
    c.check(
        "links.validate.cases",
        !all.is_empty(),
        "no cases in link_validation_cases.json",
    );
    let mut provoked: HashSet<String> = HashSet::new();
    for cc in all {
        let name = format!("links.validate[{}]", cc.str_or("name"));
        let want = want_pairs(cc.get("errors"));
        let want_instance = want_pairs(cc.get("instanceErrors"));
        provoked.extend(want.iter().map(|(_, code)| code.clone()));
        let d = doc_from_state(&DocumentJson::from_json(
            cc.get("state").unwrap_or(&Json::Null),
        ));
        let got = finding_pairs(&validate_links(&model, &d));
        c.check(
            &format!("{}.errors", name),
            got == want,
            &format!("got {:?} want {:?}", got, want),
        );
        let instance = finding_pairs(&validate_document(&model, &d));
        c.check(
            &format!("{}.instanceErrors", name),
            instance == want_instance,
            &format!("got {:?} want {:?}", instance, want_instance),
        );
        let codes: HashSet<&String> = want
            .iter()
            .chain(&want_instance)
            .map(|(_, code)| code)
            .collect();
        for token in str_list(cc.get("intent")) {
            let holds = if token == "clean" {
                codes.is_empty()
            } else {
                codes.contains(&token)
            };
            c.check(
                &format!("links.validate.intent[{}: {}]", cc.str_or("name"), token),
                holds,
                "",
            );
        }
    }
    for code in [
        SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
        SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS,
        SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW,
        SPEC_VALIDATION_CODE_INVERSE_MISSING,
        SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING,
        SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE,
        SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL,
        SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY,
        SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE,
        SPEC_VALIDATION_CODE_SAME_AS_MISMATCH,
        SPEC_VALIDATION_CODE_LINK_VALUE_PENDING,
    ] {
        c.check(
            &format!("links.validate.provoked[{}]", code),
            provoked.contains(code),
            "",
        );
    }
}
