//! What the document-set tests share: the corpus tables, their models and
//! their documents.
#![allow(dead_code)]

use std::path::PathBuf;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::{DocumentJson, SpecDocument, SpecDocumentSet, SpecModel};

pub fn corpus(name: &str) -> String {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../tom_som_conformance/corpus")
        .join(name);
    std::fs::read_to_string(path).unwrap_or_else(|e| panic!("read {}: {}", name, e))
}

/// A corpus table.
pub fn table(name: &str) -> Json {
    Json::parse(&corpus(name)).unwrap_or_else(|e| panic!("parse {}: {}", name, e))
}

/// The fixture model a table names.
pub fn table_model(table: &Json) -> SpecModel {
    let name = table
        .get("model")
        .and_then(|m| m.as_str())
        .unwrap_or("links.meta.json");
    SpecModel::from_json_str(&corpus(name)).expect("model")
}

/// The case of `group` whose name starts with `prefix`.
pub fn case_named<'a>(table: &'a Json, group: &str, prefix: &str) -> &'a Json {
    table
        .get(group)
        .and_then(|g| g.as_array())
        .unwrap_or(&[])
        .iter()
        .find(|c| c.str_or("name").starts_with(prefix))
        .unwrap_or_else(|| panic!("no {} case {:?}", group, prefix))
}

/// The document a generic state decodes to.
pub fn state_document(state: &Json) -> SpecDocument {
    let mut doc = SpecDocument::new();
    doc.load_json(&DocumentJson::from_json(state));
    doc
}

/// The documents of a case, `[[name, state], …]`.
pub fn documents(case: &Json) -> Vec<(String, SpecDocument)> {
    case.get("documents")
        .and_then(|d| d.as_array())
        .unwrap_or(&[])
        .iter()
        .map(|e| {
            let pair = e.as_array().expect("[name, state]");
            (
                pair[0].as_str().expect("name").to_string(),
                state_document(&pair[1]),
            )
        })
        .collect()
}

/// The set of a case's documents.
pub fn case_set<'m>(model: &'m SpecModel, case: &Json) -> SpecDocumentSet<'m> {
    SpecDocumentSet::new(model, documents(case)).unwrap_or_else(|e| panic!("{}", e))
}

/// Structural JSON equality with object keys compared as a set.
pub fn json_eq(a: &Json, b: &Json) -> bool {
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
