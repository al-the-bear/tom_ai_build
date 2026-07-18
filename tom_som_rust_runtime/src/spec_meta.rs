//! `spec_meta` — the canonical SOM **metadata tree**: the runtime's DR1 §3.1
//! node types, a faithful port of the Go `spec_meta.go` (itself a port of
//! `tom_som_dart_runtime/lib/src/spec_meta.dart`).
//!
//! One [`SomMetaTree`] exists per document root. Its nodes carry *every*
//! `tom_specs_core` annotation the model source declares, plus the exact class
//! and member names, so the tree is the single language-neutral description of
//! a document's structure:
//!
//!   - [`SomMetaNode`] — one node per navigable model position (§3.1), with
//!     section id / pattern, kind, serialization order, `@Min`, content type,
//!     help/comment/doc texts, form metadata, traceability links
//!     (`@MapsTo` / `@DetailedIn`) and the lossless
//!     `extra` annotation list;
//!   - [`SomMetaTree`] — wires parent links and absolute paths (the §4 path
//!     grammar shared with `spec_paths`) and provides the two dynamic lookups
//!     every runtime keeps: `by_id` and `by_path`.
//!
//! The runtime only *defines* these types; the generated facades (DR8) emit
//! the populated tree as statically initialized values, and tests build small
//! fixture trees by hand.
//!
//! Rust conventions (shared with the rest of the crate): the empty string is
//! the idiomatic nullable string (`""` = absent), optional ints are
//! `Option<i64>`, and the other ports' throwing accessors return
//! `Result<_, String>`. Nodes are shared via `Rc` (mirroring the reference
//! semantics of the Go/Dart/TS ports); the tree wires the parent links through
//! interior mutability exactly once.

use std::cell::{Cell, RefCell};
use std::collections::HashMap;
use std::rc::{Rc, Weak};

use crate::json::Json;
use crate::spec_paths::{list_item_path, spec_path_join, spec_path_segments, split_list_item_segment};

/// [`SomMetaNode::kind`] value: a `List<T>` field; items are addressed by
/// `-<seq>` path suffixes and described by [`SomMetaNode::element_node`].
pub const SOM_META_KIND_LIST: &str = "list";
/// [`SomMetaNode::kind`] value: a `@Form` content section (its fields live in
/// [`SomMetaNode::form`]).
pub const SOM_META_KIND_FORM: &str = "form";
/// [`SomMetaNode::kind`] value: a field rendered as a section of its own.
pub const SOM_META_KIND_SECTION: &str = "section";
/// [`SomMetaNode::kind`] value: a free-text (markdown) content leaf.
pub const SOM_META_KIND_CONTENT: &str = "content";
/// [`SomMetaNode::kind`] value: an enum-valued leaf.
pub const SOM_META_KIND_ENUM_VALUE: &str = "enum";
/// [`SomMetaNode::kind`] value: a field typed by another model class (collapses
/// into that class: the node's children are the target class's fields).
pub const SOM_META_KIND_COMPLEX: &str = "complex";
/// [`SomMetaNode::kind`] value: a plain scalar leaf (String/int/double/bool).
pub const SOM_META_KIND_SCALAR: &str = "scalar";

/// The `@ContentType(type, description)` annotation captured on a node.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SomContentTypeMeta {
    /// The declared content type (e.g. `"code"`, `"diagram"`).
    pub type_: String,
    /// The human/AI-facing description of the expected content.
    pub description: String,
}

/// One field of a `@Form` section (DR1 §3.1 FormMeta.fields).
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SomFormFieldMeta {
    /// The exact model field name (`"approvedBy"`).
    pub name: String,
    /// The Dart type name of the field (`"String"`, `"int"`, …).
    pub type_name: String,
    /// The display label / description, `""` when the form declares none.
    pub description: String,
    /// Whether the form marks the field as required.
    pub required: bool,
    /// The authoring hint (e.g. `"e.g. 1.0"`), `""` when absent.
    pub hint: String,
    /// The declaration order within the form.
    pub order: i64,
    /// Enum constant names when `type_name` is a model enum (YRD7); empty for
    /// non-enum field types. The complete value domain of an enum-typed form
    /// field, so editors and the generic modification API can validate and
    /// convert without generated code.
    pub enum_values: Vec<String>,
}

/// The form metadata of a `@Form` node (DR1 §3.1 FormMeta).
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SomFormMeta {
    /// The form's fields in declaration order.
    pub fields: Vec<SomFormFieldMeta>,
}

impl SomFormMeta {
    /// Returns the field named `name`, or `None` when absent.
    pub fn field_named(&self, name: &str) -> Option<&SomFormFieldMeta> {
        self.fields.iter().find(|f| f.name == name)
    }
}

/// The `@Document` metadata carried by a document root (DR1 §3.1 DocMeta).
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SomDocMeta {
    /// The document's display name (`"Solution Blueprint"`).
    pub name: String,
    /// The document's description.
    pub description: String,
    /// Class names of the documents this one is based on (`@Document.basedOn`).
    pub based_on: Vec<String>,
}

/// One annotation captured losslessly into the generic `extra` list —
/// annotations the tree defines no dedicated slot for (DR1 §3.1 note), e.g.
/// `@Max`, `@MinLength`, `@PatternCheck`, `@TextRequired`.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SomMetaExtra {
    /// The annotation's class name (`"Max"`, `"PatternCheck"`, …).
    pub annotation: String,
    /// The resolved constructor arguments (`{count: 4}`), in source order.
    pub args: Vec<(String, Json)>,
}

impl SomMetaExtra {
    /// Returns the resolved value of a named argument.
    pub fn arg(&self, key: &str) -> Option<&Json> {
        self.args.iter().find(|(k, _)| k == key).map(|(_, v)| v)
    }
}

/// One node of the SOM metadata tree (DR1 §3.1 MetaNode).
///
/// A node describes one navigable position of a document root's structure: the
/// document root itself, a field, or a list's element subtree. Class-level
/// annotations attach to the node where the class is *instantiated*;
/// field-level annotations attach to the node directly (field-level
/// `@SectionId` wins over the target class's).
///
/// Nodes are immutable value carriers; [`SomMetaTree`] wires the parent links
/// and absolute paths when the tree is constructed. A node instance belongs to
/// at most one tree.
#[derive(Debug, Default)]
pub struct SomMetaNode {
    /// The exact model class name this node is (for root/complex/section
    /// nodes: the instantiated class; for leaves: the declaring class of the
    /// field).
    pub class_name: String,
    /// The exact field name in the parent class, `""` on the document root and
    /// on list element subtrees.
    pub member_name: String,
    /// The effective `@SectionId` (field-level wins over class-level), `""`
    /// when none.
    pub section_id: String,
    /// The target class's own `@SectionId` (DR1 §2.2 fallback): the id its DR3
    /// schema type is keyed by, used only to build the mapping key of a
    /// section/complex node whose field carries no id. Never enters
    /// [`SomMetaNode::segment`] — the path stays field-level. `""` when none.
    pub class_section_id: String,
    /// The `@SectionIdPattern` on a list field (item ids), `""` when none.
    pub section_id_pattern: String,
    /// The structural kind of the node (a `SOM_META_KIND_*` constant).
    pub kind: String,
    /// The Dart type name of the field/class (`"String"`, `"GoalEntry"`, …).
    pub type_name: String,
    /// `@SerializationOrder(order)`, `None` when unannotated.
    pub serialization_order: Option<i64>,
    /// `@Min(count)`, `None` when unannotated.
    pub min: Option<i64>,
    /// Whether `@Unused` is present on the node.
    pub unused: bool,
    /// `@ContentType`, `None` when unannotated.
    pub content_type: Option<SomContentTypeMeta>,
    /// `@ContentHelp(guidance)`, `""` when unannotated.
    pub content_help: String,
    /// The `@Headline(text)` predefined DEFAULT headline (YRD4; field-level
    /// wins over the target class's), `""` when unannotated.
    ///
    /// Render precedence: `stored headline > this default > name derivation`.
    /// Editors prefill a new section's headline from this; a stored headline
    /// always wins and stays editable.
    pub headline: String,
    /// `@Comment(text)`, `""` when unannotated.
    pub comment: String,
    /// The cleaned `///` doc comment (member wins over class), `""` when none.
    pub doc_comment: String,
    /// The instantiated class's own doc comment, when it differs from
    /// `doc_comment`.
    pub class_doc_comment: String,
    /// The form metadata, for [`SOM_META_KIND_FORM`] nodes.
    pub form: Option<SomFormMeta>,
    /// `@Document` metadata; `Some` only on the document root.
    pub document: Option<SomDocMeta>,
    /// The `@MapsTo` target class name, `""` when unannotated.
    pub maps_to: String,
    /// The `@DetailedIn` target class name, `""` when unannotated.
    pub detailed_in: String,
    /// Annotations without a dedicated slot, captured losslessly.
    pub extra: Vec<SomMetaExtra>,
    /// Whether this node is a recursive re-entry reference (a class already on
    /// the descent stack): kind == [`SOM_META_KIND_COMPLEX`], no children.
    pub recursive: bool,
    /// The child nodes, in `@SerializationOrder` order. For complex/section
    /// nodes these are the target class's fields (the class collapses onto the
    /// node); empty for leaves and recursive references.
    pub children: Vec<Rc<SomMetaNode>>,
    /// For [`SOM_META_KIND_LIST`] nodes, the element class subtree. Its
    /// children describe each item's structure; item positions have no static
    /// path (see [`SomMetaNode::path`]).
    pub element_node: Option<Rc<SomMetaNode>>,

    /// The tree wiring (parent link, absolute path), set exactly once by
    /// [`SomMetaTree::new`]. Public only so nodes can be built with
    /// functional-update syntax (`..SomMetaNode::new()`); its internals are
    /// private to this module.
    pub wiring: SomMetaNodeWiring,
}

/// The internal tree wiring of a [`SomMetaNode`] (parent link, absolute path,
/// attachment flag). Constructed only via `Default`; written only by
/// [`SomMetaTree::new`].
#[derive(Debug, Default)]
pub struct SomMetaNodeWiring {
    attached: Cell<bool>,
    parent: RefCell<Weak<SomMetaNode>>,
    path: RefCell<String>,
    has_path: Cell<bool>,
}

impl SomMetaNode {
    /// Returns a fully-default node — the fixture/builder starting point (all
    /// public metadata fields are also settable directly before the node is
    /// wrapped in an `Rc` and attached to a tree).
    pub fn new() -> SomMetaNode {
        SomMetaNode::default()
    }

    fn assert_attached(&self) -> Result<(), String> {
        if !self.wiring.attached.get() {
            return Err(format!(
                "SomMetaNode({}) is not attached to a SomMetaTree",
                self.debug_name()
            ));
        }
        Ok(())
    }

    /// Returns the parent node, `None` on the document root. The parent of a
    /// list's element node is the list node itself. Returns an error when the
    /// node is unattached.
    pub fn parent(&self) -> Result<Option<Rc<SomMetaNode>>, String> {
        self.assert_attached()?;
        Ok(self.wiring.parent.borrow().upgrade())
    }

    /// Returns the node's absolute document path per the §4 path grammar
    /// (`<rootSegment>/<segment>/…`), or `""` for nodes inside a list element
    /// subtree — their concrete paths depend on the item sequence (see
    /// [`SomMetaNode::item_path`] on the list node and
    /// [`SomMetaTree::by_path`]). Returns an error when the node is unattached.
    pub fn path(&self) -> Result<String, String> {
        self.assert_attached()?;
        Ok(self.wiring.path.borrow().clone())
    }

    /// Returns the path segment this node contributes: the effective
    /// `section_id` when present, else the `member_name`, else the
    /// `class_name` (document root).
    pub fn segment(&self) -> &str {
        if !self.section_id.is_empty() {
            return &self.section_id;
        }
        if !self.member_name.is_empty() {
            return &self.member_name;
        }
        &self.class_name
    }

    /// Returns the path of the `seq`-th item of this list node
    /// (`<path>-<seq>`). Returns an error when the node is not a list or has
    /// no static path.
    pub fn item_path(&self, seq: i64) -> Result<String, String> {
        if self.kind != SOM_META_KIND_LIST {
            return Err(format!(
                "itemPath() requires a list node, {} is {}",
                self.debug_name(),
                self.kind
            ));
        }
        let p = self.path()?;
        if !self.wiring.has_path.get() {
            return Err(format!(
                "list {} sits inside a list element subtree and has no static path",
                self.debug_name()
            ));
        }
        Ok(list_item_path(&p, seq))
    }

    /// Returns the direct child whose `member_name` equals `name`, or `None`.
    pub fn child_by_member(&self, name: &str) -> Option<&Rc<SomMetaNode>> {
        self.children.iter().find(|c| c.member_name == name)
    }

    /// Returns the direct child whose [`segment`](Self::segment) equals `seg`,
    /// or `None`.
    pub fn child_by_segment(&self, seg: &str) -> Option<&Rc<SomMetaNode>> {
        self.children.iter().find(|c| c.segment() == seg)
    }

    /// Returns a short identification for error messages.
    pub fn debug_name(&self) -> String {
        if self.member_name.is_empty() {
            return self.class_name.clone();
        }
        format!("{}.{}", self.class_name, self.member_name)
    }
}

/// Reports whether `id` matches `pattern` with every `"xxx"` placeholder
/// standing for one-or-more digits (the dependency-free stand-in for the other
/// ports' regex match).
pub(crate) fn matches_section_id_pattern(pattern: &str, id: &str) -> bool {
    let parts: Vec<&str> = pattern.split("xxx").collect();
    match_pattern_parts(&parts, id)
}

fn match_pattern_parts(parts: &[&str], id: &str) -> bool {
    let first = parts[0];
    if !id.starts_with(first) {
        return false;
    }
    let rest = &id[first.len()..];
    if parts.len() == 1 {
        return rest.is_empty();
    }
    let digits = rest.bytes().take_while(|b| b.is_ascii_digit()).count();
    for take in 1..=digits {
        if match_pattern_parts(&parts[1..], &rest[take..]) {
            return true;
        }
    }
    false
}

/// The metadata tree of one document root: parent/path wiring plus the two
/// dynamic lookups (`by_id`, `by_path`) DR1 §4.3 requires every runtime to
/// keep.
#[derive(Debug)]
pub struct SomMetaTree {
    /// The document root node (carries [`SomMetaNode::document`]).
    pub root: Rc<SomMetaNode>,
    by_id: HashMap<String, Vec<Rc<SomMetaNode>>>,
    all_nodes: Vec<Rc<SomMetaNode>>,
}

impl SomMetaTree {
    /// Wires `root`'s subtree: sets parent links, computes static paths, and
    /// indexes section ids.
    ///
    /// Returns an error when `root` carries no `@Document` metadata, and when
    /// any node is already attached to another tree (nodes belong to exactly
    /// one tree).
    pub fn new(root: Rc<SomMetaNode>) -> Result<SomMetaTree, String> {
        if root.document.is_none() {
            return Err(format!(
                "the tree root must carry @Document metadata (SomMetaNode.document): {}",
                root.debug_name()
            ));
        }
        let mut t = SomMetaTree {
            root: root.clone(),
            by_id: HashMap::new(),
            all_nodes: Vec::new(),
        };
        let root_segment = root.segment().to_string();
        t.wire(&root, None, root_segment, true)?;
        Ok(t)
    }

    fn wire(
        &mut self,
        node: &Rc<SomMetaNode>,
        parent: Option<&Rc<SomMetaNode>>,
        path: String,
        has_path: bool,
    ) -> Result<(), String> {
        if node.wiring.attached.get() {
            return Err(format!(
                "SomMetaNode({}) is already attached to a SomMetaTree; nodes belong to exactly one tree",
                node.debug_name()
            ));
        }
        node.wiring.attached.set(true);
        *node.wiring.parent.borrow_mut() = match parent {
            Some(p) => Rc::downgrade(p),
            None => Weak::new(),
        };
        *node.wiring.path.borrow_mut() = path.clone();
        node.wiring.has_path.set(has_path);
        self.all_nodes.push(node.clone());
        if !node.section_id.is_empty() {
            self.by_id
                .entry(node.section_id.clone())
                .or_default()
                .push(node.clone());
        }
        for child in &node.children {
            let child_path = if has_path {
                spec_path_join(&path, child.segment())
            } else {
                String::new()
            };
            self.wire(child, Some(node), child_path, has_path)?;
        }
        if let Some(element) = &node.element_node {
            // Item positions are dynamic (`<listPath>-<seq>`), so the element
            // subtree carries no static paths.
            self.wire(element, Some(node), String::new(), false)?;
        }
        Ok(())
    }

    /// Returns every node of the tree (document order; element subtrees follow
    /// their list node).
    pub fn all_nodes(&self) -> &[Rc<SomMetaNode>] {
        &self.all_nodes
    }

    // --- lookup by section id ------------------------------------------------

    /// Returns all nodes whose effective section id equals `section_id`, in
    /// document order. A shared class instantiated at several positions yields
    /// several nodes (ids resolve within their parent chain, DR1 §1.2).
    pub fn all_by_id(&self, section_id: &str) -> &[Rc<SomMetaNode>] {
        self.by_id.get(section_id).map(|v| v.as_slice()).unwrap_or(&[])
    }

    /// Returns the first node whose effective section id equals `section_id`.
    ///
    /// A *resolved list-item id* (a list's `@SectionIdPattern` with the `"xxx"`
    /// placeholder replaced by digits, e.g. `"GOAL-ITEM-3"`) resolves to that
    /// list's element subtree. Returns `None` when nothing matches.
    pub fn by_id(&self, section_id: &str) -> Option<Rc<SomMetaNode>> {
        if let Some(exact) = self.by_id.get(section_id) {
            if let Some(first) = exact.first() {
                return Some(first.clone());
            }
        }
        for node in &self.all_nodes {
            if !node.section_id_pattern.is_empty()
                && matches_section_id_pattern(&node.section_id_pattern, section_id)
            {
                if let Some(element) = &node.element_node {
                    return Some(element.clone());
                }
                return Some(node.clone());
            }
        }
        None
    }

    // --- lookup by path -------------------------------------------------------

    /// Resolves a document path (the §4 grammar: segments joined by `"/"`,
    /// list items as `-<seq>` suffixes) to the metadata node it addresses, or
    /// `None` when the path does not describe a reachable position.
    ///
    /// A list-item segment (`<listSegment>-<seq>`) resolves to the list's
    /// element subtree; segments below it match the element class's fields. A
    /// list *container* path is only valid as the final segment (descending
    /// past a list requires an item suffix).
    pub fn by_path(&self, path: &str) -> Option<Rc<SomMetaNode>> {
        let segs = spec_path_segments(path);
        if segs.is_empty() || segs[0] != self.root.segment() {
            return None;
        }

        let mut node = self.root.clone();
        for i in 1..segs.len() {
            let seg = &segs[i];
            let last = i == segs.len() - 1;

            // Prefer an exact segment match; only then try a list-item suffix,
            // so a hyphenated @SectionId is never mis-read as an item.
            if let Some(child) = node.child_by_segment(seg) {
                if child.kind == SOM_META_KIND_LIST && !last {
                    return None; // a list path needs a `-<seq>` item suffix
                }
                if child.recursive && !last {
                    return None; // chains terminate at recursive re-entries
                }
                let child = child.clone();
                node = child;
                continue;
            }

            let split = split_list_item_segment(seg)?;
            let list_node = node.child_by_segment(&split.base)?.clone();
            if list_node.kind != SOM_META_KIND_LIST {
                return None;
            }
            match &list_node.element_node {
                None => {
                    // Scalar list without an element subtree: the item is a
                    // value leaf.
                    if last {
                        return Some(list_node);
                    }
                    return None;
                }
                Some(element) => {
                    let element = element.clone();
                    node = element;
                }
            }
        }
        Some(node)
    }
}

/// One position of the generated **dot-notation / ID-tree access surfaces**
/// (DR1 §4): an absolute document `path` bound to the `tree` it belongs to.
///
/// The generated facades (DR8) emit one accessor type per model class whose
/// getters return further `SomMetaRef`s. Every accessor exposes at least
/// `path` and `meta` (the [`SomMetaNode`] at that position). This base type is
/// the leaf accessor itself (content/scalar/enum/form positions).
#[derive(Clone)]
pub struct SomMetaRef<'a> {
    /// The metadata tree of the document root this position belongs to.
    pub tree: &'a SomMetaTree,
    /// The absolute document path of this position (§4 path grammar).
    pub path: String,
}

impl<'a> SomMetaRef<'a> {
    /// Binds a position to its tree.
    pub fn new(tree: &'a SomMetaTree, path: String) -> SomMetaRef<'a> {
        SomMetaRef { tree, path }
    }

    /// Returns the metadata node at `path`.
    ///
    /// Returns an error when the path resolves to no node — only possible past
    /// a recursive re-entry, where the generated chain has ended and the
    /// metadata tree carries no further nodes (DR1 §4.1 cycle rule).
    pub fn meta(&self) -> Result<Rc<SomMetaNode>, String> {
        self.tree.by_path(&self.path).ok_or_else(|| {
            format!(
                "no metadata node at \"{}\" — the position lies beyond a recursive re-entry; use the dynamic tree lookups instead",
                self.path
            )
        })
    }
}

/// The generated accessor for a **list** position (DR1 §4.1): `meta_ref.path`
/// is the list container path; [`item`](SomListMetaRef::item) returns the
/// accessor for the `seq`-th item position (`<path>-<seq>`), whose children
/// are the element class's accessors.
pub struct SomListMetaRef<'a, T> {
    /// The list container position.
    pub meta_ref: SomMetaRef<'a>,
    element: Box<dyn Fn(&'a SomMetaTree, String) -> T + 'a>,
}

impl<'a, T> SomListMetaRef<'a, T> {
    /// Binds a list container position to its element accessor factory: the
    /// factory builds the element class's generated accessor for an item
    /// position.
    pub fn new(
        tree: &'a SomMetaTree,
        path: String,
        element: impl Fn(&'a SomMetaTree, String) -> T + 'a,
    ) -> SomListMetaRef<'a, T> {
        SomListMetaRef {
            meta_ref: SomMetaRef::new(tree, path),
            element: Box::new(element),
        }
    }

    /// Returns the accessor at the item position `<path>-<seq>`.
    pub fn item(&self, seq: i64) -> T {
        (self.element)(
            self.meta_ref.tree,
            list_item_path(&self.meta_ref.path, seq),
        )
    }
}
