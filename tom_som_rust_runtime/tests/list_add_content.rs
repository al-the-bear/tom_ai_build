//! Behavioural tests for the `add_content` / `contents` convenience members on
//! [`SomList`] (SOM convenience roadmap item 9), the Rust port of the Dart
//! `SomList.addContent` / `SomList.contents` reference.
//!
//! They exercise a content-only element facade (`ContentItem`) whose single
//! typed accessor is the nested `<item>/content` leaf — the shape `add_content`
//! is designed for — and assert visibility through both the typed handle and
//! the generic document path.

use tom_som_rust_runtime::som_facade::{doc_ref, DocRef, SomList, SomNode};
use tom_som_rust_runtime::spec_document::SpecDocument;

/// A minimal content-only element facade: one nested `content` leaf, mirroring
/// a generated complex list item whose sole field is `content`.
struct ContentItem {
    node: SomNode,
}

impl ContentItem {
    fn new(doc: DocRef, path: String) -> ContentItem {
        ContentItem {
            node: SomNode::new(doc, path),
        }
    }

    fn content_path(&self) -> String {
        format!("{}/content", self.node.path())
    }

    fn content(&self) -> String {
        self.node.doc().borrow().content_or(&self.content_path())
    }
}

fn content_list(doc: DocRef, list_path: &str, pattern: &str) -> SomList<ContentItem> {
    SomList::new(
        doc,
        list_path.to_string(),
        Box::new(ContentItem::new),
        pattern.to_string(),
    )
}

/// (a) add_content appends an item and sets its nested content leaf, visible
/// via both the element handle and the generic document path.
#[test]
fn add_content_appends_and_sets_leaf() {
    let doc = doc_ref(SpecDocument::new());
    let list = content_list(doc.clone(), "DEMO/items", "");

    assert_eq!(list.length(), 0);
    let item = list.add_content("hello");

    assert_eq!(list.length(), 1);
    // Visible via the typed handle.
    assert_eq!(item.content(), "hello");
    // Visible via the generic document path (the nested <item>/content leaf).
    let item_path = item.node.path().to_string();
    assert_eq!(
        doc.borrow().content(&format!("{}/content", item_path)),
        Some(&"hello".to_string()),
    );
}

/// (b) add_content honours the list's section-id pattern (generated id).
#[test]
fn add_content_honours_section_id_pattern() {
    let doc = doc_ref(SpecDocument::new());
    let list = content_list(doc.clone(), "DEMO/items", "DACEN-ITEM-xxx");

    // Explicit date so the generated id is deterministic.
    let item = list.add_content_on("patterned", 1, 1);

    assert_eq!(item.content(), "patterned");
    let ids = list.section_ids();
    assert_eq!(ids.len(), 1);
    // A pattern-driven id was generated (non-empty, prefixed).
    assert!(
        ids[0].starts_with("DACEN-ITEM-"),
        "unexpected generated id: {}",
        ids[0],
    );
}

/// (c) add_content_with_id accepts an explicit section-id override.
#[test]
fn add_content_accepts_id_override() {
    let doc = doc_ref(SpecDocument::new());
    let list = content_list(doc.clone(), "DEMO/items", "DACEN-ITEM-xxx");

    let item = list
        .add_content_with_id("overridden", "CUSTOM-1")
        .expect("unique override");

    assert_eq!(item.content(), "overridden");
    assert_eq!(list.section_ids(), vec!["CUSTOM-1".to_string()]);
}

/// (d) contents yields every item's content leaf in item order.
#[test]
fn contents_yields_ordered_content() {
    let doc = doc_ref(SpecDocument::new());
    let list = content_list(doc.clone(), "DEMO/items", "");

    list.add_content("first");
    list.add_content("second");
    list.add_content("third");

    assert_eq!(
        list.contents(),
        vec![
            "first".to_string(),
            "second".to_string(),
            "third".to_string(),
        ],
    );
}

/// (e) contents reads "" for an item whose content leaf is missing.
#[test]
fn contents_reads_empty_for_missing_leaf() {
    let doc = doc_ref(SpecDocument::new());
    let list = content_list(doc.clone(), "DEMO/items", "");

    // First item has content; second is a bare add() with no content leaf.
    list.add_content("present");
    list.add();

    assert_eq!(
        list.contents(),
        vec!["present".to_string(), String::new()],
    );
}
