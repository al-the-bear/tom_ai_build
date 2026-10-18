//! `SpecDocument::has_values_under` answers from a prefix index rather than a
//! scan of every stored key. The markdown emitter, the validator and the query
//! engine ask it once per model node, so a scan made rendering a large
//! specification quadratic.
//!
//! VI-1 holds the index to the scan it replaces, across every mutator, so a
//! mutation that forgets to drop the index fails here. VI-2 guards the
//! complexity itself. Mirror of the Dart reference test.

use std::collections::BTreeMap;
use std::time::{Duration, Instant};

use tom_som_rust_runtime::spec_document::{DocumentJson, ListJson, SpecDocument};
use tom_som_rust_runtime::spec_document_markdown::SpecMarkdownResult;
use tom_som_rust_runtime::spec_model::SpecModel;

/// The predicate the index must reproduce: a stored key equal to `query`, or
/// continuing it after a `/` or a `-`.
fn scan(d: &SpecDocument, query: &str) -> bool {
    let j = d.to_json();
    let keys = j
        .content
        .keys()
        .chain(j.forms.keys())
        .chain(j.lists.keys())
        .chain(j.headlines.keys())
        .chain(j.code_specs.keys());
    for k in keys {
        if k == query
            || k.starts_with(&format!("{query}/"))
            || k.starts_with(&format!("{query}-"))
        {
            return true;
        }
    }
    false
}

const PROBES: &[&str] = &[
    "DEMO",
    "DEMO/TTL",
    "DEMO/TT",
    "DEMO/SUM",
    "DEMO/DET",
    "DEMO/items",
    "DEMO/items-1",
    "DEMO/items-1/label",
    "DEMO/items-2",
    "DEMO/items-3",
    "DEMO/REF-LST",
    "DEMO/REF",
    "DEMO/CARD-LST-1",
    "OTHER",
    "D00",
    "D00/D00-ITM",
    "D00/D00-ITM-1",
    "D00/D00-ITM-2",
    "D00/D00-ITM-1/D01-LBL",
    "D00/D00-OVR",
    "",
];

fn expect_agrees(d: &SpecDocument, when: &str) {
    for p in PROBES {
        assert_eq!(d.has_values_under(p), scan(d, p), "{when}: \"{p}\"");
    }
}

fn model() -> SpecModel {
    SpecModel::from_json_str(
        r#"{
            "roots": [
                {"type": "DemoDoc", "title": "Demo Document", "sectionId": "D00"}
            ],
            "classes": {
                "DemoDoc": {
                    "name": "DemoDoc", "sectionId": "D00",
                    "fields": [
                        {"name": "overview", "kind": "content", "sectionId": "D00-OVR"},
                        {"name": "items", "kind": "list", "elementType": "DemoItem",
                         "elementIsComplex": true, "sectionId": "D00-ITM"}
                    ]
                },
                "DemoItem": {
                    "name": "DemoItem",
                    "fields": [
                        {"name": "label", "kind": "content", "sectionId": "D01-LBL"}
                    ]
                }
            }
        }"#,
    )
    .unwrap()
}

#[test]
fn vi1_the_index_agrees_with_a_full_scan_after_every_mutator() {
    let mut d = SpecDocument::new();
    expect_agrees(&d, "empty");
    d.set_content("DEMO/TTL", "Hello");
    expect_agrees(&d, "set_content");
    d.set_headline("DEMO/SUM", "Summary");
    expect_agrees(&d, "set_headline");
    d.set_code_spec("DEMO/DET", "a.b");
    expect_agrees(&d, "set_code_spec");
    d.set_form_field("DEMO/CARD-LST-1/content", "note", "x");
    expect_agrees(&d, "set_form_field");
    let item = d.add_list_item("DEMO/items");
    d.set_content(&format!("{item}/label"), "First");
    d.add_list_item("DEMO/items");
    expect_agrees(&d, "add_list_item");
    d.add_list_item_with_section_id("DEMO/items", "ITEM-C").unwrap();
    expect_agrees(&d, "add_list_item_with_section_id");
    d.set_item_section_id(&item, "ITEM-A").unwrap();
    expect_agrees(&d, "set_item_section_id");
    d.set_content("DEMO/TTL", "");
    expect_agrees(&d, "set_content to empty");
    d.set_form_field("DEMO/CARD-LST-1/content", "note", "");
    expect_agrees(&d, "set_form_field to empty");
    d.set_headline("DEMO/SUM", "");
    expect_agrees(&d, "set_headline to empty");
    d.set_code_spec("DEMO/DET", "");
    expect_agrees(&d, "set_code_spec to empty");
    assert!(d.remove_list_item(&item));
    expect_agrees(&d, "remove_list_item");
    d.set_headline("DEMO/SUM", "Summary");
    expect_agrees(&d, "set_headline again");
    d.remove_values_under("DEMO/SUM");
    expect_agrees(&d, "remove_values_under");

    // A clone keeps an index consistent with its own stores, and diverging
    // copies never see each other's index.
    let mut copy = d.clone();
    copy.set_content("OTHER/X", "y");
    expect_agrees(&copy, "mutated clone");
    expect_agrees(&d, "original after clone mutated");

    let mut lists = BTreeMap::new();
    lists.insert(
        "DEMO/REF-LST".to_string(),
        ListJson {
            seq: 1,
            items: vec!["DEMO/REF-LST-1".to_string()],
            ids: BTreeMap::new(),
        },
    );
    let mut content = BTreeMap::new();
    content.insert("DEMO/REF-LST-1".to_string(), "spec".to_string());
    d.load_json(&DocumentJson {
        content,
        lists,
        ..DocumentJson::default()
    });
    expect_agrees(&d, "load_json");

    // move_list_item (within and across lists) needs a model.
    let m = model();
    let a = d.add_list_item("D00/D00-ITM");
    d.set_content(&format!("{a}/D01-LBL"), "A");
    let b = d.add_list_item("D00/D00-ITM");
    d.set_content(&format!("{b}/D01-LBL"), "B");
    d.set_content("D00/D00-OVR", "overview");
    expect_agrees(&d, "before move_list_item");
    d.move_list_item(&m, &b, 0, None).unwrap();
    expect_agrees(&d, "move_list_item");

    // apply_markdown_result: a full overwrite of the covered root.
    let mut result = SpecMarkdownResult::default();
    result.root_prefixes.insert("D00".to_string());
    result
        .content
        .insert("D00/D00-OVR".to_string(), "replaced".to_string());
    d.apply_markdown_result(&result, true).unwrap();
    expect_agrees(&d, "apply_markdown_result");
    assert!(!d.has_values_under("D00/D00-ITM"));
    assert!(d.has_values_under("D00"));
}

#[test]
fn vi2_has_values_under_is_not_a_scan_of_every_stored_key() {
    // 20,000 stored values and 20,000 queries. A per-query scan costs
    // 4 * 10^8 key comparisons; the index answers in milliseconds. The bound is
    // generous (debug builds are slower), so only the complexity class can
    // fail it.
    let n = 20000;
    let mut d = SpecDocument::new();
    for i in 0..n {
        d.set_content(&format!("ROOT/S{}/F{}", i / 100, i), &format!("v{i}"));
    }
    let start = Instant::now();
    let mut hits: i64 = 0;
    for i in 0..n {
        if d.has_values_under(&format!("ROOT/S{}/F{}", i / 100, i)) {
            hits += 1;
        }
        if d.has_values_under(&format!("ROOT/S{}/G{}", i / 100, i)) {
            hits -= 1;
        }
    }
    let elapsed = start.elapsed();
    assert_eq!(hits, n as i64);
    assert!(
        elapsed < Duration::from_secs(5),
        "40,000 queries over 20,000 values took {elapsed:?}"
    );
}
