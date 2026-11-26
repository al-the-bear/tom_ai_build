//! The places and filters of the link vocabulary (`spec_place.rs`,
//! `tom_specs_model_rules.md` §9.7) and the typed link readers of the model
//! they are read from (`spec_model_links.rs`): the grammar, resolution under
//! an anchor over the corpus's `links.meta.json`, the filter's `|`
//! alternatives, the `@SameAs` holders and the readers' defaults for a key a
//! meta does not carry.
//!
//! The shared corpus (`link_reader_cases.json`) pins the canonical JSON of
//! these; this test holds the Rust surface around it — the errors, the
//! defaults, `Display` and the section positions. Mirrors the Go runtime's
//! `spec_place_test.go`.

use std::path::PathBuf;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::{
    spec_same_as_bindings, spec_section_positions, SpecAnnotation, SpecDerivation,
    SpecExtractsLinks, SpecInverseOf, SpecModel, SpecPlace, SpecPlaceFilter, SpecReflection,
    SpecSameAs, SpecSummaryOf, SpecSync, SPEC_PLACE_KIND_FORM_FIELD,
    SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED, SPEC_PLACE_PROBLEM_MALFORMED,
    SPEC_PLACE_PROBLEM_NOT_SCOPED, SPEC_PLACE_PROBLEM_NO_SUCH_FIELD,
    SPEC_PLACE_PROBLEM_RESERVED_SLOT, SPEC_PLACE_PROBLEM_UNRESOLVED,
};

fn links_model() -> SpecModel {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../tom_som_conformance/corpus/links.meta.json");
    SpecModel::from_json_str(&std::fs::read_to_string(path).expect("links.meta.json"))
        .expect("parse")
}

/// The JSON of a parsed argument object.
fn args(text: &str) -> Vec<(String, Json)> {
    match Json::parse(text).expect("json") {
        Json::Object(pairs) => pairs,
        _ => panic!("not an object"),
    }
}

/// `v` as compact JSON with sorted keys, for comparing canonical forms.
fn canon(v: &Json) -> String {
    match v {
        Json::Object(pairs) => {
            let mut sorted: Vec<&(String, Json)> = pairs.iter().collect();
            sorted.sort_by(|a, b| a.0.cmp(&b.0));
            let inner: Vec<String> = sorted
                .iter()
                .map(|(k, v)| format!("{:?}:{}", k, canon(v)))
                .collect();
            format!("{{{}}}", inner.join(","))
        }
        Json::Array(items) => format!(
            "[{}]",
            items.iter().map(canon).collect::<Vec<_>>().join(",")
        ),
        Json::Str(s) => format!("{:?}", s),
        Json::Bool(b) => b.to_string(),
        Json::Int(n) => n.to_string(),
        Json::Float(f) => f.to_string(),
        Json::Null => "null".to_string(),
    }
}

#[test]
fn spec_place_grammar() {
    let p = SpecPlace::parse("./FRE/REQDEP/RQDEP.description").expect("place");
    assert!(p.scoped);
    assert_eq!(p.prefix, ["FRE", "REQDEP"]);
    assert_eq!(p.section_id, "RQDEP");
    assert_eq!(p.slot, "description");
    assert_eq!(p.to_string(), "./FRE/REQDEP/RQDEP.description");
    assert_eq!(SpecPlace::parse("FRE.@headline").unwrap().slot, "@headline");
    let bare = SpecPlace::parse("FRE-REQU-LST").unwrap();
    assert_eq!(
        canon(&bare.to_json()),
        r#"{"prefix":[],"scoped":false,"sectionId":"FRE-REQU-LST"}"#
    );
    for bad in ["", "./", "-X", "FRE.", "FRE.a-b", "FRE/.x", "FRE..x"] {
        assert!(
            SpecPlace::try_parse(bad).is_none(),
            "{:?} parsed as a place",
            bad
        );
    }
    assert_eq!(
        SpecPlace::parse("a b").unwrap_err().problem,
        SPEC_PLACE_PROBLEM_MALFORMED
    );
}

#[test]
fn spec_place_filter_grammar() {
    let f = SpecPlaceFilter::parse("./FRE.priority=must|should").expect("filter");
    assert!(f.scoped);
    assert_eq!(f.field, "priority");
    assert_eq!(f.values, ["must", "should"]);
    assert!(
        f.matches(&["could", " should "]),
        "the second alternative, trimmed, matches"
    );
    assert!(!f.matches(&["could"]));
    assert!(!f.matches::<&str>(&[]));
    let every = SpecPlaceFilter::parse("FRE").unwrap();
    assert!(
        every.matches::<&str>(&[]),
        "a filter without a field matches every entry"
    );
    assert_eq!(every.place().text, "FRE");
    assert_eq!(f.place().text, "./FRE");
    for bad in [
        "FRE.priority",
        "FRE.priority=",
        "FRE.priority=a||b",
        "FRE.9x=a",
        ".x=a",
    ] {
        assert!(
            SpecPlaceFilter::try_parse(bad).is_none(),
            "{:?} parsed as a filter",
            bad
        );
    }
}

#[test]
fn spec_place_resolution() {
    let model = links_model();
    let refl = SpecReflection::new(&model);
    let item = "BLU/requirements/REQ-ITEM-LST-1";
    let resolve =
        |place: &str, anchor: &str| SpecPlace::parse(place).unwrap().resolve(&refl, anchor);
    let r = resolve("REQD.description", item).expect("resolves");
    assert_eq!(r.kind, SPEC_PLACE_KIND_FORM_FIELD);
    assert_eq!(r.field(), "description");
    assert!(r.form_field.is_some());
    for (place, anchor, problem) in [
        ("REQD", "BLU/nowhere", SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED),
        ("./REQD", "BLU", SPEC_PLACE_PROBLEM_NOT_SCOPED),
        ("NOPE", "BLU", SPEC_PLACE_PROBLEM_UNRESOLVED),
        ("REQD.@nope", item, SPEC_PLACE_PROBLEM_RESERVED_SLOT),
        ("REQD.nope", item, SPEC_PLACE_PROBLEM_NO_SUCH_FIELD),
    ] {
        let err = resolve(place, anchor).expect_err(place);
        assert_eq!(err.problem, problem, "{} under {}", place, anchor);
        assert!(err.is_place_problem());
    }
    // The filter reports with its own text.
    let err = SpecPlaceFilter::parse("NOPE.x=1")
        .unwrap()
        .resolve(&refl, "BLU")
        .expect_err("unresolved");
    assert_eq!(err.text, "NOPE.x=1");
    assert!(err.to_string().contains("NOPE.x=1"));
}

#[test]
fn spec_section_positions_and_same_as() {
    let model = links_model();
    let refl = SpecReflection::new(&model);
    let positions = spec_section_positions(&refl, "Blueprint");
    assert!(!positions.is_empty());
    assert_eq!(positions[0].path, "BLU");
    assert!(
        !positions[0].is_member && positions[0].member.is_none(),
        "the root position is no member"
    );
    assert!(
        positions.iter().any(|p| p.path.contains("-*")),
        "a list-item position"
    );
    assert!(spec_section_positions(&refl, "Nope").is_empty());
    let bindings = spec_same_as_bindings(&refl, "Blueprint");
    assert_eq!(bindings.len(), 1);
    assert!(!bindings[0].holder_path.is_empty());
    assert!(spec_same_as_bindings(&refl, "Nope").is_empty());
}

#[test]
fn spec_link_reader_defaults() {
    // An absent key takes the annotation's default; an enum constant loses
    // its type prefix.
    let d = SpecDerivation::from_arguments(&args(r#"{"source":"X","kind":"DerivationKind.rows"}"#));
    assert_eq!(d.kind, "rows");
    assert_eq!(
        canon(&d.to_json()),
        r#"{"kind":"rows","map":{},"source":"X","take":[]}"#
    );
    assert_eq!(SpecDerivation::from_arguments(&[]).kind, "copy");
    let s = SpecSummaryOf::from_arguments(&args(r#"{"detail":"D-LST"}"#));
    assert_eq!(
        canon(&s.to_json()),
        r#"{"detail":"D-LST","relation":"subset","repeats":{}}"#
    );
    let inv = |fields: &[&str]| SpecInverseOf {
        fields: fields.iter().map(|f| f.to_string()).collect(),
        r#where: String::new(),
    };
    assert!(inv(&["@self"]).symmetric());
    assert!(!inv(&["@self", "X.y"]).symmetric());
    let e = SpecExtractsLinks::from_annotation(&SpecAnnotation {
        name: "ExtractsLinks".to_string(),
        arguments: args(r#"{"ref":"L.ref","from":["A.b",null]}"#),
    });
    assert_eq!(
        canon(&e.to_json()),
        r#"{"from":["A.b"],"mode":"generate","ref":"L.ref","set":{}}"#
    );
    let sync = SpecSync::from_annotation(&SpecAnnotation {
        name: "SyncedWith".to_string(),
        arguments: args(r#"{"document":"D","relations":[{"place":"P"},"junk"]}"#),
    });
    assert_eq!(sync.relations.len(), 1);
    assert_eq!(
        canon(&sync.relations[0].to_json()),
        r#"{"place":"P","relation":"equal"}"#
    );
    let empty = SpecSameAs {
        holder: String::new(),
        note: String::new(),
    };
    assert_eq!(canon(&empty.to_json()), "{}");
}

/// A string → string argument keeps the order the meta writes it in.
#[test]
fn spec_link_reader_keeps_meta_order() {
    let model = SpecModel::from_json_str(
        r#"{"roots":[],"classes":{"C":{"name":"C","fields":[],"annotations":[
            {"name":"SummaryOf","arguments":{"detail":"D-LST","repeats":{"Z.a":"1","A.b":"2","M.c":"3"}}}]}}}"#,
    )
    .expect("model");
    let repeats = model
        .class_named("C")
        .unwrap()
        .summary_of()
        .unwrap()
        .repeats;
    let keys: Vec<&str> = repeats.iter().map(|(k, _)| k.as_str()).collect();
    assert_eq!(keys, ["Z.a", "A.b", "M.c"]);
}

#[test]
fn spec_link_model_accessors() {
    let model = links_model();
    let req = model.class_named("Requirement").unwrap();
    assert_eq!(
        req.field_named("links")
            .unwrap()
            .annotations_named("ExtractsLinks")
            .len(),
        2
    );
    let blueprint = model.class_named("Blueprint").unwrap();
    assert!(blueprint.synced_with().is_none());
    assert!(!blueprint.is_code_specs_projection());
}
