//! `can_have_content` suite for the SOM §21 structural predicate.
//!
//! `can_have_content` answers "does this **type** declare the standard
//! `content` text leaf?" — can this node hold body text? — as a compile-time
//! constant of the type, **without probing the document**. It is deliberately
//! distinct from the two state predicates: [`SpecDocument::has_content`] ("is a
//! value present at this leaf *now*?") and [`SomNode::is_empty`] ("is this
//! subtree empty *now*?").
//!
//! Rust facades hold a [`SomNode`] but do not inherit from it, so — mirroring
//! the per-type `editability_for` emission (SOM §21) — the emitter bakes
//! `can_have_content` onto **every** generated section type as a literal
//! boolean (`true` for a type carrying a `content` leaf, `false` for one that
//! declares none). Since `tom_specs_model_rules.md` §10.2 requires
//! `content: String?` on every section class, every generated section type
//! emits `true`; the `false` literal below stands for the emitter's other
//! branch, which no generated section reaches.
//! The generated crate is regenerated centrally, so here we exercise two
//! stand-in facades that reproduce the exact per-type emission the emitter
//! produces, plus the invariant that the predicate never consults the document.

use tom_som_rust_runtime::som_facade::{doc_ref, DocRef, SomNode};
use tom_som_rust_runtime::spec_document::SpecDocument;

/// Stand-in for a **content-bearing** generated facade (e.g. `Goals`): it carries
/// a typed `content` leaf, so the emitter emits `can_have_content` == `true`.
struct ContentBearingFacade {
    node: SomNode,
}

impl ContentBearingFacade {
    fn new(doc: DocRef, path: String) -> ContentBearingFacade {
        ContentBearingFacade {
            node: SomNode::new(doc, path),
        }
    }

    /// The literal the emitter bakes onto a content-bearing type (SOM §21).
    fn can_have_content(&self) -> bool {
        true
    }

    fn content(&self) -> String {
        self.node
            .doc()
            .borrow()
            .content_or(&format!("{}/content", self.node.path()))
    }
}

/// Stand-in for a generated facade that declares **no `content` leaf**, so the
/// emitter emits `can_have_content` == `false`.
struct LeaflessFacade {
    // Bound like every generated facade, though a leafless type's
    // `can_have_content` never reads it (the predicate is purely structural).
    #[allow(dead_code)]
    node: SomNode,
}

impl LeaflessFacade {
    fn new(doc: DocRef, path: String) -> LeaflessFacade {
        LeaflessFacade {
            node: SomNode::new(doc, path),
        }
    }

    /// The literal the emitter bakes onto a type with no `content` leaf (SOM §21).
    fn can_have_content(&self) -> bool {
        false
    }
}

#[test]
fn content_bearing_type_can_have_content() {
    let doc = doc_ref(SpecDocument::new());
    let facade = ContentBearingFacade::new(doc, "SBP/goals".to_string());
    assert!(facade.can_have_content());
}

#[test]
fn leafless_type_cannot_have_content() {
    let doc = doc_ref(SpecDocument::new());
    let facade = LeaflessFacade::new(doc, "SBP/tags-1".to_string());
    assert!(!facade.can_have_content());
}

/// `can_have_content` is **structural**: it depends only on the type, never on
/// the document's state. Setting or clearing the `content` leaf must not change
/// it (contrast `has_content` / `is_empty`, which do move with the data).
#[test]
fn can_have_content_ignores_document_state() {
    let doc = doc_ref(SpecDocument::new());
    let facade = ContentBearingFacade::new(doc.clone(), "SBP/goals".to_string());

    // Empty document: no content value present yet.
    assert_eq!(facade.content(), "");
    assert!(facade.can_have_content());

    // Populate the content leaf — the state predicate would flip, the
    // structural predicate does not.
    doc.borrow_mut().set_content("SBP/goals/content", "a body");
    assert_eq!(facade.content(), "a body");
    assert!(facade.can_have_content());

    // Clear it again — still unchanged.
    doc.borrow_mut().set_content("SBP/goals/content", "");
    assert_eq!(facade.content(), "");
    assert!(facade.can_have_content());
}
