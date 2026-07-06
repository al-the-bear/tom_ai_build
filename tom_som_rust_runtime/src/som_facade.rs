//! `som_facade` — the hand-written runtime support for the generated typed
//! object model (`tom_som_rust_v0`), a faithful port of the Go `som_facade.go`.
//!
//! The generated structs are a thin editing facade over the generic
//! [`SpecDocument`]: every typed accessor reads or writes the path-keyed memory
//! representation directly, so a mutation made through the typed surface is
//! immediately visible through the generic path and vice-versa. These base types
//! ([`SomNode`], [`SomList`], [`SomScalar`]) hold no state of their own beyond
//! the document handle and a path; the generated structs hold a [`SomNode`] and
//! only add typed accessors.
//!
//! Rust shares the one document through an `Rc<RefCell<SpecDocument>>`
//! ([`DocRef`]): a child facade clones the `Rc` (cheap reference-count bump) and
//! every read/write borrows the cell. Because generated accessors reference the
//! bound document explicitly through the embedded [`SomNode`], no `doc`/`path`
//! name guard is needed (unlike the Go/TypeScript ports).

use std::cell::RefCell;
use std::rc::Rc;

use crate::spec_document::SpecDocument;
use crate::spec_section_id::{generate_list_item_section_id, today_month_day, SpecSectionIdError};

/// A shared, mutable handle to the one document every facade in a tree edits.
pub type DocRef = Rc<RefCell<SpecDocument>>;

/// Wraps a [`SpecDocument`] in a shareable [`DocRef`].
pub fn doc_ref(doc: SpecDocument) -> DocRef {
    Rc::new(RefCell::new(doc))
}

/// The base every generated typed facade struct holds. It binds a facade
/// instance to the [`SpecDocument`] it edits and the path it lives at (the
/// globally-unique section path, per `spec_paths`).
#[derive(Clone)]
pub struct SomNode {
    doc: DocRef,
    path: String,
}

impl SomNode {
    /// Binds a facade node to a document and a path.
    pub fn new(doc: DocRef, path: String) -> SomNode {
        SomNode { doc, path }
    }

    /// Returns a shared handle to the document this node edits.
    pub fn doc(&self) -> DocRef {
        Rc::clone(&self.doc)
    }

    /// Returns the globally-unique section path of this node.
    pub fn path(&self) -> &str {
        &self.path
    }

    /// Returns this node's section id when it is a list item (AA1 criterion 1
    /// read), or `""` for non-list nodes (roots, complex/section children — their
    /// id is the fixed `@SectionId` already embedded in [`SomNode::path`]).
    pub fn section_id(&self) -> String {
        self.doc.borrow().item_section_id_or(&self.path)
    }

    /// Overrides this list item's section id (AA1 criterion 5): an arbitrary
    /// suffix, validated unique within the owning list. Returns
    /// [`SpecSectionIdError::Collision`] on a duplicate, or
    /// [`SpecSectionIdError::NotLiveItem`] if this node is not a live list item.
    /// An empty id is a no-op.
    pub fn set_section_id(&self, id: &str) -> Result<(), SpecSectionIdError> {
        if id.is_empty() {
            return Ok(());
        }
        self.doc.borrow_mut().set_item_section_id(&self.path, id)
    }

    /// Returns `true` iff this section holds no value at its path or nested
    /// beneath it — delegates to [`SpecDocument::has_values_under`] (SOM
    /// roadmap § item 5).
    pub fn is_empty(&self) -> bool {
        !self.doc.borrow().has_values_under(&self.path)
    }
}

/// A scalar list item — a bare string value held in the document's content store
/// at its own item path. Used as the element facade for non-complex
/// (string/scalar) lists.
#[derive(Clone)]
pub struct SomScalar {
    pub node: SomNode,
}

impl SomScalar {
    /// Binds a scalar facade to a document and an item path.
    pub fn new(doc: DocRef, path: String) -> SomScalar {
        SomScalar {
            node: SomNode::new(doc, path),
        }
    }

    /// Returns the string value at this item's path (`""` when unset).
    pub fn value(&self) -> String {
        self.node.doc.borrow().content_or(self.node.path())
    }

    /// Sets the string value (an empty string clears it, per [`SpecDocument`]).
    pub fn set_value(&self, v: &str) {
        let path = self.node.path().to_string();
        self.node.doc.borrow_mut().set_content(&path, v);
    }
}

/// A typed view over a list field, layered over the document's list store. Items
/// are addressed by their stable item paths; each is wrapped in an element
/// facade by `factory`. The view holds no items itself — every operation reads
/// through the live document, so it always reflects the current state.
pub struct SomList<T> {
    doc: DocRef,
    list_path: String,
    factory: Box<dyn Fn(DocRef, String) -> T>,
    /// The list field's `@SectionIdPattern` (e.g. `DACEN-ITEM-xxx`), or `""` for
    /// a pattern-less (scalar) list. It drives section-id generation on
    /// [`SomList::add`] / [`SomList::add_on`] (AA1 criteria 3–5).
    pattern: String,
}

impl<T> SomList<T> {
    /// Binds a typed list view to a document, a list path, an element factory and
    /// the field's `@SectionIdPattern` (`""` when the field has none).
    pub fn new(
        doc: DocRef,
        list_path: String,
        factory: Box<dyn Fn(DocRef, String) -> T>,
        pattern: String,
    ) -> SomList<T> {
        SomList {
            doc,
            list_path,
            factory,
            pattern,
        }
    }

    /// Returns the list container's section path (items hang off it as
    /// `"<list_path>-<seq>"`). The Rust counterpart of Dart's `SomList.listPath`
    /// / Python's `list_path`, so a traversal can name the container it iterates.
    pub fn list_path(&self) -> &str {
        &self.list_path
    }

    /// Returns the number of items currently in the list.
    pub fn length(&self) -> usize {
        self.doc.borrow().list_item_count(&self.list_path)
    }

    /// Returns the element facades for every item, in order.
    pub fn items(&self) -> Vec<T> {
        let paths = self.doc.borrow().list_items(&self.list_path);
        paths
            .into_iter()
            .map(|p| (self.factory)(Rc::clone(&self.doc), p))
            .collect()
    }

    /// Returns the element facade for the item at `index`.
    pub fn at(&self, index: usize) -> T {
        let path = self.doc.borrow().list_items(&self.list_path)[index].clone();
        (self.factory)(Rc::clone(&self.doc), path)
    }

    /// Returns the section ids currently assigned within this list, in item
    /// order (AA1 criterion 1 read).
    pub fn section_ids(&self) -> Vec<String> {
        self.doc.borrow().list_item_section_ids(&self.list_path)
    }

    /// Appends a new item and returns its element facade.
    ///
    /// When the list has a pattern, the new item is assigned a section id
    /// generated from that pattern using today's date for the two-letter-date
    /// component (AA1 criteria 3–4). A pattern-less list appends without a
    /// section id.
    ///
    /// Rust has no exceptions, optional parameters or overloading, so the JS/TS
    /// `add(sectionId?, date?)` splits into three methods: [`SomList::add`]
    /// (generate, today), [`SomList::add_on`] (generate, explicit date) and
    /// [`SomList::add_with_id`] (explicit override). See decision AG-D2.
    pub fn add(&self) -> T {
        if self.pattern.is_empty() {
            let path = self.doc.borrow_mut().add_list_item(&self.list_path);
            return (self.factory)(Rc::clone(&self.doc), path);
        }
        let (month, day) = today_month_day();
        self.add_generated(month, day)
    }

    /// Appends a new item whose generated section id uses the given `(month,
    /// day)` for the two-letter-date component (AA1 criteria 3–4). For a
    /// pattern-less list it behaves like [`SomList::add`] (the date is ignored).
    pub fn add_on(&self, month: i64, day: i64) -> T {
        if self.pattern.is_empty() {
            let path = self.doc.borrow_mut().add_list_item(&self.list_path);
            return (self.factory)(Rc::clone(&self.doc), path);
        }
        self.add_generated(month, day)
    }

    /// Appends a new item with an explicit section id override (AA1 criterion 5),
    /// validated unique within the list. Returns
    /// [`SpecSectionIdError::Collision`] on a duplicate. For a pattern-less list
    /// the id is still recorded (an explicit override is always honoured).
    pub fn add_with_id(&self, section_id: &str) -> Result<T, SpecSectionIdError> {
        let item_path = self
            .doc
            .borrow_mut()
            .add_list_item_with_section_id(&self.list_path, section_id)?;
        Ok((self.factory)(Rc::clone(&self.doc), item_path))
    }

    fn add_generated(&self, month: i64, day: i64) -> T {
        let existing = self.doc.borrow().list_item_section_ids(&self.list_path);
        let id = generate_list_item_section_id(&self.pattern, month, day, &existing);
        let item_path = self
            .doc
            .borrow_mut()
            .add_list_item_with_section_id(&self.list_path, &id)
            .expect("generated section id is unique by construction");
        (self.factory)(Rc::clone(&self.doc), item_path)
    }

    /// Removes the item at `index` and every value nested beneath it.
    pub fn remove_at(&self, index: usize) {
        let path = self.doc.borrow().list_items(&self.list_path)[index].clone();
        self.doc.borrow_mut().remove_list_item(&path);
    }
}

/// Raised when a generated object model is instantiated against a document whose
/// authoring model version it must not edit.
#[derive(Debug, Clone)]
pub struct SomVersionError {
    pub message: String,
}

impl std::fmt::Display for SomVersionError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SomVersionError: {}", self.message)
    }
}

impl std::error::Error for SomVersionError {}

struct SomVersion {
    major: i64,
    minor: i64,
}

fn try_parse_som_version(raw: &str) -> Option<SomVersion> {
    let parts: Vec<&str> = raw.split('.').collect();
    if parts.len() != 2 {
        return None;
    }
    let major = try_int(parts[0])?;
    let minor = try_int(parts[1])?;
    Some(SomVersion { major, minor })
}

fn try_int(raw: &str) -> Option<i64> {
    if raw.is_empty() {
        return None;
    }
    let bytes = raw.as_bytes();
    let mut i = 0;
    if bytes[0] == b'-' || bytes[0] == b'+' {
        if bytes.len() == 1 {
            return None;
        }
        i = 1;
    }
    if !bytes[i..].iter().all(|b| b.is_ascii_digit()) {
        return None;
    }
    raw.parse::<i64>().ok()
}

/// The instantiation-time version check every generated root facade performs.
/// `generated` is the object model's own major.minor version; `document_version`
/// is the document's recorded authoring stamp (`""` for a brand-new,
/// never-stamped document).
///
/// Rules:
///   - an empty document stamp is always accepted — a new document is stamped on
///     first edit;
///   - within the same major version, a document whose minor is `<=` the
///     generated minor is editable; a document whose minor is greater is
///     rejected;
///   - a different major version is always rejected (cross-major is
///     read/convert only, never in-place edit).
pub fn check_som_model_version(generated: &str, document_version: &str) -> Result<(), SomVersionError> {
    if document_version.is_empty() {
        return Ok(());
    }
    let gen = try_parse_som_version(generated).ok_or_else(|| SomVersionError {
        message: format!("\"{}\" is not a valid major.minor version", generated),
    })?;
    let docv = try_parse_som_version(document_version).ok_or_else(|| SomVersionError {
        message: format!(
            "document model version \"{}\" is not a valid major.minor",
            document_version
        ),
    })?;
    if docv.major != gen.major {
        return Err(SomVersionError {
            message: format!(
                "document major version {} differs from the object model major version {}; cross-major documents are read-only",
                docv.major, gen.major
            ),
        });
    }
    if docv.minor > gen.minor {
        return Err(SomVersionError {
            message: format!(
                "document model version {} is newer than the object model version {}; an older object model cannot edit a newer document",
                document_version, generated
            ),
        });
    }
    Ok(())
}
