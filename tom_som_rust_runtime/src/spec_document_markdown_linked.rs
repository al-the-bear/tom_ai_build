//! `spec_document_markdown_linked` — navigation between linked places of a
//! rendition (SOM §11.2 qualified anchors, SOM §11.11 the `linked` marker), a
//! port of the Go runtime's `spec_document_markdown_linked.go` (itself a port
//! of the Python, JavaScript, TypeScript and Dart runtimes'
//! `spec_document_markdown_linked`).
//!
//! Both are written from the model and the document's own values, and nothing
//! of either is stored: the parser removes the anchors and the marker.
//!
//! Internal to [`SpecDocumentMarkdown`]: a child module, so it reads the
//! codec's private helpers.

use std::cell::{OnceCell, RefCell};
use std::collections::HashMap;
use std::rc::Rc;

use super::{md_is_transparent_value, md_qualify_anchor, MdAnchorKind, SpecDocumentMarkdown};
use crate::spec_document::SpecDocument;
use crate::spec_links_validator::{
    spec_expand_pattern, spec_resolve_link_place, spec_resolve_place_at,
};
use crate::spec_meta::{
    SomMetaNode, SomMetaTree, SOM_META_KIND_COMPLEX, SOM_META_KIND_FORM, SOM_META_KIND_LIST,
    SOM_META_KIND_SECTION,
};
use crate::spec_model::{SpecModel, SpecRoot};
use crate::spec_model_links::{SpecSummaryOf, SpecSync};
use crate::spec_notation::scan_notation;
use crate::spec_paths::split_list_item_segment;
use crate::spec_place::{spec_same_as_bindings, SpecPlaceFilter, SpecSameAsBinding};
use crate::spec_reflection::SpecReflection;
use crate::spec_section_id::effective_list_item_section_id;

/// Written by the emitter where a markable place has no entry: replaced by
/// `[]{.linked}` when the value written after it begins with a `linked` span,
/// else removed with its blank line (SOM §11.11).
pub(super) const MD_LINKED_PLACEHOLDER: &str = "\u{0}linked\u{0}";

/// A path walked through a tree: the anchor and id of the heading it ends at,
/// that heading's path, the path as a pattern (items `<list>-*`), the items'
/// ids on the way and the node reached (`None`: not reached).
pub(super) struct MdWalk {
    pub(super) anchor: String,
    pub(super) heading_id: String,
    pub(super) heading_path: String,
    pub(super) pattern: String,
    pub(super) item_ids: Vec<String>,
    pub(super) node: Option<Rc<SomMetaNode>>,
}

/// One side of a `@SyncedWith` pair: its anchor here, the other root, the
/// anchor there, whether this side holds the values, the sync.
struct MdSide {
    mine: String,
    other: SpecRoot,
    theirs: String,
    holder: bool,
    sync: SpecSync,
}

/// One derived value at a heading: a link to a source (`""`: none) and the
/// derived field's name (`""`: a derived section).
struct MdDerivedSource {
    link: String,
    field: String,
}

/// A detail element a summary element names: its id, its anchor and the
/// other root it is in (`None`: this document).
struct MdSummaryTarget {
    id: String,
    anchor: String,
    other: Option<SpecRoot>,
}

/// `path` cut before its first `<list>-*` segment: that list's path.
fn md_cut_pattern(path: &str) -> &str {
    match path.find("-*") {
        Some(i) => &path[..i],
        None => path,
    }
}

/// An item pattern's list pattern (`a/L-*` → `a/L`).
fn md_list_pattern_of(item_pattern: &str) -> &str {
    item_pattern.strip_suffix("-*").unwrap_or(item_pattern)
}

fn md_add_unique(out: &mut Vec<String>, v: String) {
    if !out.contains(&v) {
        out.push(v);
    }
}

/// The `@SectionIdPattern` of a list's items: the list's, else its element's.
fn md_item_pattern_of(list_node: &SomMetaNode) -> String {
    if !list_node.section_id_pattern.is_empty() {
        return list_node.section_id_pattern.clone();
    }
    list_node
        .element_node
        .as_ref()
        .map(|e| e.section_id_pattern.clone())
        .unwrap_or_default()
}

/// The stem of a pattern-less list's item ids: its member name, else its
/// segment.
fn md_member_stem_of(list_node: &SomMetaNode) -> String {
    if !list_node.member_name.is_empty() {
        return list_node.member_name.clone();
    }
    list_node.segment().to_string()
}

/// The part of `path` before its last `/` (the whole path without one).
fn md_owner_of(path: &str) -> &str {
    match path.rfind('/') {
        Some(i) => &path[..i],
        None => path,
    }
}

/// The section id of a root, else its type: its path segment and its name.
fn md_root_name(root: &SpecRoot) -> &str {
    if root.section_id.is_empty() {
        &root.type_
    } else {
        &root.section_id
    }
}

/// Detail-list pattern → the summary lists naming its elements, and the
/// patterns in insertion order.
type MdDetailLists = (HashMap<String, Vec<String>>, Vec<String>);

/// One root's navigation: anchors, markable places and marker entries.
pub(super) struct MdNavigation<'a> {
    model: &'a SpecModel,
    root: SpecRoot,
    pub(super) tree: Rc<SomMetaTree>,
    walks: RefCell<HashMap<String, Rc<MdWalk>>>,
    sides: OnceCell<Vec<MdSide>>,
    same_as: OnceCell<Vec<SpecSameAsBinding>>,
    detail_lists: OnceCell<MdDetailLists>,
    markables: RefCell<HashMap<String, bool>>,
    summary_map: OnceCell<HashMap<String, Vec<String>>>,
}

impl<'a> MdNavigation<'a> {
    pub(super) fn new(
        model: &'a SpecModel,
        root: &SpecRoot,
        tree: Rc<SomMetaTree>,
    ) -> MdNavigation<'a> {
        MdNavigation {
            model,
            root: root.clone(),
            tree,
            walks: RefCell::new(HashMap::new()),
            sides: OnceCell::new(),
            same_as: OnceCell::new(),
            detail_lists: OnceCell::new(),
            markables: RefCell::new(HashMap::new()),
            summary_map: OnceCell::new(),
        }
    }

    pub(super) fn refl(&self) -> SpecReflection<'a> {
        SpecReflection::new(self.model)
    }

    pub(super) fn root_seg(&self) -> String {
        self.refl().root_segment(&self.root)
    }

    // --- anchors ---------------------------------------------------------------

    /// The heading id of the item at `item_path` of `list_node` in `d`
    /// (`None`: no document), as the emitter writes it.
    fn item_id(
        &self,
        d: Option<&SpecDocument>,
        list_node: &SomMetaNode,
        item_path: &str,
    ) -> String {
        let slash = item_path.rfind('/').map(|i| i + 1).unwrap_or(0);
        let (base, seq) = match split_list_item_segment(&item_path[slash..]) {
            Some(split) => (split.base, split.seq),
            None => (item_path[slash..].to_string(), 0),
        };
        let list_path = format!("{}{}", &item_path[..slash], base);
        let mut pos = 0;
        let mut stored = None;
        if let Some(d) = d {
            pos = d
                .list_items(&list_path)
                .iter()
                .position(|p| p == item_path)
                .map(|i| i + 1)
                .unwrap_or(0);
            stored = d.item_section_id(item_path).map(|s| s.as_str());
        }
        if pos == 0 {
            pos = seq.max(0) as usize;
        }
        effective_list_item_section_id(
            stored,
            &md_item_pattern_of(list_node),
            pos,
            &md_member_stem_of(list_node),
        )
    }

    /// `path` (concrete, or a pattern whose `<list>-*` segments take `ids` in
    /// order) walked through `other` (`None`: this root's tree, the items' ids
    /// read from the codec's document; else no document).
    pub(super) fn walk(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        path: &str,
        other: Option<&SomMetaTree>,
        ids: &[String],
    ) -> Rc<MdWalk> {
        let cacheable = other.is_none() && ids.is_empty();
        if cacheable {
            if let Some(hit) = self.walks.borrow().get(path) {
                return hit.clone();
            }
        }
        let d = if other.is_none() {
            Some(c.document)
        } else {
            None
        };
        let t: &SomMetaTree = other.unwrap_or(&self.tree);
        let mut queue = ids.iter();
        let segs: Vec<&str> = path.split('/').collect();
        let mut node: Rc<SomMetaNode> = t.root.clone();
        let mut cur = segs[0].to_string();
        let mut pattern = segs[0].to_string();
        let mut anchor = node.segment().to_string();
        let mut heading_id = node.segment().to_string();
        let mut heading_path = cur.clone();
        let mut scope: Option<Vec<String>> = None;
        let mut section: Option<String> = Some(node.segment().to_string());
        let mut item_ids: Vec<String> = Vec::new();
        let mut reached: Option<Rc<SomMetaNode>> = Some(node.clone());
        for i in 1..segs.len() {
            let seg = segs[i];
            if let Some(child) = node.child_by_segment(seg).cloned() {
                cur = format!("{}/{}", cur, seg);
                pattern = format!("{}/{}", pattern, seg);
                node = child.clone();
                reached = Some(child.clone());
                if c.is_transparent_section(&child) || md_is_transparent_value(&child) {
                    continue;
                }
                let id = c.heading_id_of(&child);
                let container = child.kind == SOM_META_KIND_LIST;
                let kind = if container {
                    MdAnchorKind::Container
                } else if c.is_copy_node(&child) {
                    MdAnchorKind::Copy
                } else {
                    MdAnchorKind::Plain
                };
                let (a, sc) = md_qualify_anchor(&scope, &section, &id, kind);
                anchor = a;
                scope = sc;
                heading_id = id.clone();
                heading_path = cur.clone();
                if !container {
                    section = Some(id);
                }
                continue;
            }
            let star = seg.ends_with("-*");
            let base = if star {
                Some(seg[..seg.len() - 2].to_string())
            } else {
                split_list_item_segment(seg).map(|s| s.base)
            };
            let list_node = base
                .as_deref()
                .and_then(|b| node.child_by_segment(b).cloned())
                .filter(|l| l.kind == SOM_META_KIND_LIST);
            let Some(list_node) = list_node else {
                reached = None;
                break;
            };
            let base = base.unwrap_or_default();
            let item_path = format!("{}/{}", cur, seg);
            let id = if star {
                queue.next().cloned().unwrap_or_default()
            } else {
                self.item_id(d, &list_node, &item_path)
            };
            item_ids.push(id.clone());
            let (a, sc) = md_qualify_anchor(&scope, &section, &id, MdAnchorKind::Item);
            anchor = a;
            scope = sc;
            heading_id = id.clone();
            section = Some(id);
            cur = item_path.clone();
            heading_path = item_path;
            pattern = format!("{}/{}-*", pattern, base);
            let element = list_node.element_node.clone();
            let has_element = element.is_some();
            node = element.unwrap_or(list_node);
            reached = Some(node.clone());
            if !has_element && i < segs.len() - 1 {
                reached = None;
                break;
            }
        }
        let w = Rc::new(MdWalk {
            anchor,
            heading_id,
            heading_path,
            pattern,
            item_ids,
            node: reached,
        });
        if cacheable {
            self.walks.borrow_mut().insert(path.to_string(), w.clone());
        }
        w
    }

    /// The anchor of the heading `path` names in this document.
    pub(super) fn anchor_of(&self, c: &SpecDocumentMarkdown<'_>, path: &str) -> String {
        self.walk(c, path, None, &[]).anchor.clone()
    }

    // --- the model's links, per root ---------------------------------------------

    /// The model's root of type `t`.
    fn root_of_type(&self, t: &str) -> Option<SpecRoot> {
        self.model.roots.iter().find(|r| r.type_ == t).cloned()
    }

    /// Every `@SyncedWith` pair this root is a side of.
    fn all_sides(&self, c: &SpecDocumentMarkdown<'_>) -> &[MdSide] {
        self.sides.get_or_init(|| {
            let mut out = Vec::new();
            let (bp, pairs) = c.sync_pairs();
            if bp.is_empty() {
                return out;
            }
            for p in pairs {
                let Some(sync) = &p.sync else {
                    continue;
                };
                if self.root.type_ == *bp {
                    let Some(other) = self.root_of_type(&p.detail_root) else {
                        continue;
                    };
                    out.push(MdSide {
                        mine: p.blueprint_anchor.clone(),
                        other,
                        theirs: p.detail_anchor.clone(),
                        holder: false,
                        sync: sync.clone(),
                    });
                } else if self.root.type_ == p.detail_root {
                    let Some(other) = self.root_of_type(bp) else {
                        continue;
                    };
                    out.push(MdSide {
                        mine: p.detail_anchor.clone(),
                        other,
                        theirs: p.blueprint_anchor.clone(),
                        holder: true,
                        sync: sync.clone(),
                    });
                }
            }
            out
        })
    }

    /// The `@SameAs` copies of this root with their holders.
    fn same_as_bindings(&self) -> &[SpecSameAsBinding] {
        self.same_as
            .get_or_init(|| spec_same_as_bindings(&self.refl(), &self.root.type_))
    }

    fn under_copy(&self, pattern: &str) -> bool {
        self.same_as_bindings().iter().any(|b| {
            pattern == b.copy_path
                || pattern
                    .strip_prefix(b.copy_path.as_str())
                    .is_some_and(|r| r.starts_with('/'))
        })
    }

    /// The side whose shared list `list_pattern` is: the innermost pair anchor
    /// holding it, when the list lies directly beneath it (not below an item
    /// of it), outside a copy and outside the pair's `detailOnly` places.
    fn shared_list_side(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        list_pattern: &str,
        concrete_list: &str,
    ) -> Option<&MdSide> {
        if self.under_copy(list_pattern) {
            return None;
        }
        let mut best: Option<&MdSide> = None;
        for s in self.all_sides(c) {
            if !list_pattern.starts_with(&format!("{}/", s.mine)) {
                continue;
            }
            if best.is_none_or(|b| s.mine.len() > b.mine.len()) {
                best = Some(s);
            }
        }
        let best = best?;
        let rel = &list_pattern[best.mine.len() + 1..];
        if rel.contains("-*") {
            return None;
        }
        // The anchor's concrete path: the list's as long as the anchor is.
        let depth = best.mine.split('/').count();
        let parts: Vec<&str> = concrete_list.split('/').collect();
        let anchor = parts[..depth.min(parts.len())].join("/");
        let refl = self.refl();
        for place in &best.sync.detail_only {
            let Some(r) = spec_resolve_place_at(&refl, place, &anchor) else {
                continue;
            };
            let p = self.walk(c, &r.path, None, &[]).pattern.clone();
            if list_pattern == p || list_pattern.starts_with(&format!("{}/", p)) {
                return None;
            }
        }
        Some(best)
    }

    /// The `@SummaryOf` of the list member at `list_path`.
    fn summary_of_list(&self, list_path: &str) -> Option<SpecSummaryOf> {
        self.refl().resolve(list_path)?.field?.summary_of()
    }

    /// Whether a summary names its detail elements in this document.
    fn same_document(&self, s: &SpecSummaryOf) -> bool {
        s.document.is_empty() || s.document == self.root.type_
    }

    /// Detail-list pattern → the summary lists (patterns) of this document
    /// naming its elements, and the patterns in insertion order.
    fn detail_lists_map(&self, c: &SpecDocumentMarkdown<'_>) -> &MdDetailLists {
        self.detail_lists.get_or_init(|| {
            let mut out: HashMap<String, Vec<String>> = HashMap::new();
            let mut keys: Vec<String> = Vec::new();
            let refl = self.refl();
            let root_seg = self.root_seg();
            for node in self.tree.all_nodes() {
                let np = node.path().unwrap_or_default();
                if node.kind != SOM_META_KIND_LIST || np.is_empty() {
                    continue;
                }
                let Some(s) = self.summary_of_list(&np) else {
                    continue;
                };
                if !self.same_document(&s) {
                    continue;
                }
                let owner = md_owner_of(&np);
                let Some(r) = spec_resolve_link_place(&refl, None, &s.detail, &root_seg, owner)
                else {
                    continue;
                };
                let key = self
                    .walk(c, md_cut_pattern(&r.path), None, &[])
                    .pattern
                    .clone();
                if !out.contains_key(&key) {
                    keys.push(key.clone());
                }
                out.entry(key).or_default().push(np);
            }
            (out, keys)
        })
    }

    // --- markable places (structural: the parser and the emitter agree) ------

    /// Whether the heading at `path` carries one of the links of SOM §11.11:
    /// a `@SyncedWith` anchor or an element of one of its shared lists, an
    /// element of a summary list or of a detail list a summary of this
    /// document names, a heading holding a derived value, a list of link rows
    /// extracted from text, a `@SameAs` copy or its holder.
    pub(super) fn markable(&self, c: &SpecDocumentMarkdown<'_>, path: &str) -> bool {
        if let Some(&v) = self.markables.borrow().get(path) {
            return v;
        }
        let v = self.compute_markable(c, path);
        self.markables.borrow_mut().insert(path.to_string(), v);
        v
    }

    fn compute_markable(&self, c: &SpecDocumentMarkdown<'_>, path: &str) -> bool {
        let w = self.walk(c, path, None, &[]);
        let Some(node) = w.node.clone() else {
            return false;
        };
        if w.heading_path != path {
            return false;
        }
        let pattern = w.pattern.as_str();
        if self.all_sides(c).iter().any(|s| s.mine == pattern) {
            return true;
        }
        if let Some(list_path) = self.item_list_path(path) {
            let list_pattern = md_list_pattern_of(pattern);
            if self.shared_list_side(c, list_pattern, &list_path).is_some() {
                return true;
            }
            if self.summary_of_list(&list_path).is_some() {
                return true;
            }
            if self.detail_lists_map(c).0.contains_key(list_pattern) {
                return true;
            }
        }
        if !self.derived_sources(c, path, &node, true, false).is_empty() {
            return true;
        }
        if node.kind == SOM_META_KIND_LIST && !self.extract_from(c, path).is_empty() {
            return true;
        }
        self.same_as_bindings()
            .iter()
            .any(|b| b.copy_path == pattern || b.holder_path == pattern)
    }

    /// For an item path, its list's path; `None` otherwise.
    pub(super) fn item_list_path(&self, path: &str) -> Option<String> {
        let slash = path.rfind('/')?;
        let seg = &path[slash + 1..];
        let split = split_list_item_segment(seg)?;
        let parent = &path[..slash];
        if let Some(node) = self.tree.by_path(parent) {
            if node.child_by_segment(seg).is_some() {
                return None;
            }
        }
        let list_path = format!("{}/{}", parent, split.base);
        let list_node = self.tree.by_path(&list_path)?;
        if list_node.kind != SOM_META_KIND_LIST {
            return None;
        }
        Some(list_path)
    }

    // --- the marker ------------------------------------------------------------

    /// A link to `anchor` in `other` (`None`: this document), its text `id`
    /// prefixed by the other root's id.
    fn link(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        id: &str,
        anchor: &str,
        other: Option<&SpecRoot>,
    ) -> String {
        match other {
            None => format!("[{}](#{})", id, anchor),
            Some(o) => format!(
                "[{} {}]({}#{})",
                md_root_name(o),
                id,
                c.file_of_root(o),
                anchor
            ),
        }
    }

    /// The marker's entries at the heading `path`, in the order of SOM
    /// §11.11; empty when `path` is not markable or carries no link this
    /// time. `section_table`: the heading's children are written as a section
    /// table.
    pub(super) fn entries(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        path: &str,
        section_table: bool,
    ) -> Vec<String> {
        if !self.markable(c, path) {
            return Vec::new();
        }
        let w = self.walk(c, path, None, &[]);
        let Some(node) = w.node.clone() else {
            return Vec::new();
        };
        let pattern = w.pattern.as_str();
        let mut out: Vec<String> = Vec::new();

        // Also in (@SyncedWith).
        let note = |s: &MdSide| -> String {
            let held = if s.holder { "held here" } else { "held there" };
            if s.sync.held_here.is_empty() {
                held.to_string()
            } else {
                format!("{} except {}", held, s.sync.held_here.join(", "))
            }
        };
        for s in self.all_sides(c) {
            if s.mine != pattern {
                continue;
            }
            let Ok(other_tree) = c.tree_for(&s.other.type_) else {
                continue;
            };
            let there = self.walk(c, &s.theirs, Some(&other_tree), &w.item_ids);
            out.push(format!(
                "Also in {}, {}",
                self.link(c, &w.heading_id, &there.anchor, Some(&s.other)),
                note(s)
            ));
        }
        if let Some(list_path) = self.item_list_path(path) {
            let list_pattern = md_list_pattern_of(pattern);
            if let Some(side) = self.shared_list_side(c, list_pattern, &list_path) {
                if let Ok(other_tree) = c.tree_for(&side.other.type_) {
                    let rel = &list_pattern[side.mine.len()..];
                    let there = self.walk(
                        c,
                        &format!("{}{}-*", side.theirs, rel),
                        Some(&other_tree),
                        &w.item_ids,
                    );
                    out.push(format!(
                        "Also in {}, {}",
                        self.link(c, &w.heading_id, &there.anchor, Some(&side.other)),
                        note(side)
                    ));
                }
            }

            // Summary of (@SummaryOf on the list).
            if let Some(summary) = self.summary_of_list(&list_path) {
                let links: Vec<String> = self
                    .summary_targets(c, path, &list_path, &w.heading_id, &summary)
                    .iter()
                    .map(|t| self.link(c, &t.id, &t.anchor, t.other.as_ref()))
                    .collect();
                if !links.is_empty() {
                    out.push(format!("Summary of {}", links.join(", ")));
                }
            }

            // Summarised in: the summary elements of this document naming it.
            if let Some(named) = self
                .summary_links(c)
                .get(&format!("{}#{}", list_path, w.heading_id))
            {
                out.push(format!("Summarised in {}", named.join(", ")));
            }
        }

        // Derived from.
        let derived = self.derived_sources(c, path, &node, false, section_table);
        if !derived.is_empty() {
            let mut dlinks: Vec<String> = Vec::new();
            let mut fields: Vec<String> = Vec::new();
            for d in derived {
                if !d.link.is_empty() {
                    md_add_unique(&mut dlinks, d.link);
                }
                if !d.field.is_empty() {
                    md_add_unique(&mut fields, d.field);
                }
            }
            if !dlinks.is_empty() {
                let mut entry = format!("Derived from {}", dlinks.join(", "));
                if !fields.is_empty() {
                    entry.push_str(&format!(": {}", fields.join(", ")));
                }
                out.push(entry);
            }
        }

        // Extracted from (@ExtractsLinks, generate).
        if node.kind == SOM_META_KIND_LIST {
            let from = self.extract_from(c, path);
            if !from.is_empty() {
                out.push(format!("Extracted from {}", from.join(", ")));
            }
        }

        // Copy of / Copied to (@SameAs).
        for b in self.same_as_bindings() {
            if b.copy_path != pattern || b.holder_path.is_empty() {
                continue;
            }
            let h = self.walk(c, &b.holder_path, None, &w.item_ids);
            out.push(format!(
                "Copy of {}, edit it there",
                self.link(c, &h.heading_id, &h.anchor, None)
            ));
        }
        let copies: Vec<String> = self
            .same_as_bindings()
            .iter()
            .filter(|b| b.holder_path == pattern)
            .map(|b| {
                let cw = self.walk(c, &b.copy_path, None, &w.item_ids);
                self.link(c, &cw.heading_id, &cw.anchor, None)
            })
            .collect();
        if !copies.is_empty() {
            out.push(format!("Copied to {}", copies.join(", ")));
        }
        out
    }

    /// `<detail list path>#<element id>` → the links to the summary elements
    /// of this document naming that element, in document order.
    fn summary_links(&self, c: &SpecDocumentMarkdown<'_>) -> &HashMap<String, Vec<String>> {
        self.summary_map.get_or_init(|| {
            let mut out: HashMap<String, Vec<String>> = HashMap::new();
            let (lists, keys) = self.detail_lists_map(c);
            let mut summaries: Vec<String> = Vec::new();
            for k in keys {
                for l in &lists[k] {
                    md_add_unique(&mut summaries, l.clone());
                }
            }
            let doc = c.document;
            let refl = self.refl();
            let root_seg = self.root_seg();
            for summary_list in &summaries {
                for concrete in spec_expand_pattern(doc, summary_list) {
                    let Some(s) = self.summary_of_list(&concrete) else {
                        continue;
                    };
                    let owner = md_owner_of(&concrete);
                    let Some(r) =
                        spec_resolve_link_place(&refl, Some(doc), &s.detail, &root_seg, owner)
                    else {
                        continue;
                    };
                    let detail = md_cut_pattern(&r.path);
                    for e in doc.list_items(&concrete) {
                        let ew = self.walk(c, &e, None, &[]);
                        for id in self.summary_ids(c, &e, &s, &ew.heading_id) {
                            let link = self.link(c, &ew.heading_id, &ew.anchor, None);
                            md_add_unique(
                                out.entry(format!("{}#{}", detail, id)).or_default(),
                                link,
                            );
                        }
                    }
                }
            }
            out
        })
    }

    /// The ids summary element `element` names: its `match` field's ids, else
    /// its own `own_id`.
    fn summary_ids(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        element: &str,
        s: &SpecSummaryOf,
        own_id: &str,
    ) -> Vec<String> {
        if s.r#match.is_empty() {
            return vec![own_id.to_string()];
        }
        let Some(r) = spec_resolve_place_at(&self.refl(), &s.r#match, element) else {
            return Vec::new();
        };
        if r.field().is_empty() {
            return Vec::new();
        }
        let Some(raw) = c.document.form_field(&r.path, r.field()) else {
            return Vec::new();
        };
        raw.split(',')
            .map(str::trim)
            .filter(|id| !id.is_empty())
            .map(str::to_string)
            .collect()
    }

    /// The detail elements summary element `element` of `list_path` names.
    fn summary_targets(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        element: &str,
        list_path: &str,
        own_id: &str,
        s: &SpecSummaryOf,
    ) -> Vec<MdSummaryTarget> {
        let ids = self.summary_ids(c, element, s, own_id);
        if ids.is_empty() {
            return Vec::new();
        }
        let owner = md_owner_of(list_path);
        let refl = self.refl();
        if self.same_document(s) {
            let Some(r) = spec_resolve_link_place(
                &refl,
                Some(c.document),
                &s.detail,
                &self.root_seg(),
                owner,
            ) else {
                return Vec::new();
            };
            let list = format!("{}-*", md_cut_pattern(&r.path));
            return ids
                .into_iter()
                .map(|id| {
                    let anchor = self
                        .walk(c, &list, None, std::slice::from_ref(&id))
                        .anchor
                        .clone();
                    MdSummaryTarget {
                        id,
                        anchor,
                        other: None,
                    }
                })
                .collect();
        }
        let Some(other) = self.root_of_type(&s.document) else {
            return Vec::new();
        };
        let other_seg = refl.root_segment(&other);
        let r = spec_resolve_link_place(&refl, None, &s.detail, &other_seg, &other_seg);
        let other_tree = c.tree_for(&other.type_).ok();
        ids.into_iter()
            .map(|id| {
                let mut anchor = id.clone();
                if let (Some(r), Some(t)) = (&r, &other_tree) {
                    if !r.path.contains("-*") {
                        anchor = self
                            .walk(
                                c,
                                &format!("{}-*", r.path),
                                Some(t),
                                std::slice::from_ref(&id),
                            )
                            .anchor
                            .clone();
                    }
                }
                MdSummaryTarget {
                    id,
                    anchor,
                    other: Some(other.clone()),
                }
            })
            .collect()
    }

    /// The `Id` cell of a records row standing for summary element `item` of
    /// `list_path` whose `@SummaryOf` has no `match` (SOM §11.5, §11.11): its
    /// anchor, then its id as a link to the detail element it names. `None`
    /// when the list is no such summary.
    pub(super) fn summary_id_cell(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        item: &str,
        list_path: &str,
        id: &str,
    ) -> Option<String> {
        let s = self.summary_of_list(list_path)?;
        if !s.r#match.is_empty() {
            return None;
        }
        // Without `match` a summary element names exactly one detail element.
        let t = self
            .summary_targets(c, item, list_path, id, &s)
            .into_iter()
            .next()?;
        let href = match &t.other {
            None => format!("#{}", t.anchor),
            Some(o) => format!("{}#{}", c.file_of_root(o), t.anchor),
        };
        Some(format!(
            "<a id=\"{}\"></a>[{}]({})",
            self.anchor_of(c, item),
            id,
            href
        ))
    }

    /// A link to the heading `target` (a pattern cut at its first list item).
    fn link_to(&self, c: &SpecDocumentMarkdown<'_>, target: &str) -> String {
        let t = self.walk(c, md_cut_pattern(target), None, &[]);
        self.link(c, &t.heading_id, &t.anchor, None)
    }

    /// The link to the source `place` of a link annotated at `owner`; `""`
    /// when probing or when it does not resolve.
    fn source_link(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        place: &str,
        owner: &str,
        probe: bool,
    ) -> String {
        if probe {
            return String::new();
        }
        match spec_resolve_link_place(
            &self.refl(),
            Some(c.document),
            place,
            &self.root_seg(),
            owner,
        ) {
            Some(r) => self.link_to(c, &r.path),
            None => String::new(),
        }
    }

    /// The derived form fields of the form at `form_path`, named with
    /// `prefix`.
    fn derived_form(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        form_path: &str,
        prefix: &str,
        probe: bool,
        out: &mut Vec<MdDerivedSource>,
    ) {
        let owner = md_owner_of(form_path);
        let Some(field) = self.refl().resolve(form_path).and_then(|r| r.field) else {
            return;
        };
        for ff in &field.form_fields {
            let name = if prefix.is_empty() {
                ff.name.clone()
            } else {
                format!("{}.{}", prefix, ff.name)
            };
            if let Some(d) = &ff.derived_from {
                out.push(MdDerivedSource {
                    link: self.source_link(c, &d.source, owner, probe),
                    field: name.clone(),
                });
            }
            for t in &ff.count_of {
                let Some(f) = SpecPlaceFilter::try_parse(t) else {
                    continue;
                };
                let place = if f.scoped {
                    format!("./{}", f.section_id)
                } else {
                    f.section_id.clone()
                };
                out.push(MdDerivedSource {
                    link: self.source_link(c, &place, owner, probe),
                    field: name.clone(),
                });
            }
            for operand in &ff.product_of {
                let link = if probe {
                    String::new()
                } else {
                    match operand.find('.') {
                        None => self.link_to(c, form_path),
                        Some(dot) => self.link_to(c, &format!("{}/{}", owner, &operand[..dot])),
                    }
                };
                out.push(MdDerivedSource {
                    link,
                    field: name.clone(),
                });
            }
            if ff.rank_of.as_deref().is_some_and(|r| !r.is_empty()) {
                let link = if probe {
                    String::new()
                } else {
                    match self.item_list_path(owner) {
                        Some(list_path) => self.link_to(c, &list_path),
                        None => self.link_to(c, form_path),
                    }
                };
                out.push(MdDerivedSource {
                    link,
                    field: name.clone(),
                });
            }
        }
    }

    /// A member carrying `@DerivedFrom`: `name` for one written in its owner's
    /// body (no heading of its own), `""` for the heading itself.
    fn derived_member(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        member_path: &str,
        name: &str,
        probe: bool,
        out: &mut Vec<MdDerivedSource>,
    ) {
        let Some(d) = self
            .refl()
            .resolve(member_path)
            .and_then(|r| r.field)
            .and_then(|f| f.derived_from())
        else {
            return;
        };
        let owner = md_owner_of(member_path);
        out.push(MdDerivedSource {
            link: self.source_link(c, &d.source, owner, probe),
            field: name.to_string(),
        });
    }

    /// The derived values at the heading `path`: a link to a source (`""`
    /// none) and the derived field's name (`""` a derived section) per
    /// source. `probe`: answer whether there is any, structurally (no links
    /// built).
    fn derived_sources(
        &self,
        c: &SpecDocumentMarkdown<'_>,
        path: &str,
        node: &SomMetaNode,
        probe: bool,
        section_table: bool,
    ) -> Vec<MdDerivedSource> {
        let mut out = Vec::new();
        let is_item = self.item_list_path(path).is_some();
        if node.kind == SOM_META_KIND_FORM {
            self.derived_form(c, path, "", probe, &mut out);
        }
        if !is_item && path.contains('/') {
            self.derived_member(c, path, "", probe, &mut out);
        }
        if node.kind == SOM_META_KIND_SECTION || node.kind == SOM_META_KIND_COMPLEX || is_item {
            for slot in c.body_slots(node) {
                let slot_path = format!("{}/{}", path, slot.rel);
                if slot.node.kind == SOM_META_KIND_FORM {
                    self.derived_form(c, &slot_path, "", probe, &mut out);
                } else {
                    let name = if slot.node.member_name.is_empty() {
                        slot.node.segment().to_string()
                    } else {
                        slot.node.member_name.clone()
                    };
                    self.derived_member(c, &slot_path, &name, probe, &mut out);
                }
            }
            if section_table || probe {
                for child in c.effective_children(node) {
                    if child.node.kind != SOM_META_KIND_FORM {
                        continue;
                    }
                    let child_path = format!("{}/{}", path, child.rel);
                    if probe || c.document.has_values_under(&child_path) {
                        self.derived_form(
                            c,
                            &child_path,
                            &c.heading_id_of(&child.node),
                            probe,
                            &mut out,
                        );
                    }
                }
            }
        }
        out
    }

    /// The `Extracted from` links of the link-row list at `path`: the text
    /// places of its `@ExtractsLinks` in `generate` mode.
    fn extract_from(&self, c: &SpecDocumentMarkdown<'_>, path: &str) -> Vec<String> {
        let refl = self.refl();
        let Some(field) = refl.resolve(path).and_then(|r| r.field) else {
            return Vec::new();
        };
        let owner = md_owner_of(path);
        let root_seg = self.root_seg();
        let mut out = Vec::new();
        for e in field.extracts_links() {
            if e.mode != "generate" {
                continue;
            }
            for place in &e.from {
                let Some(r) =
                    spec_resolve_link_place(&refl, Some(c.document), place, &root_seg, owner)
                else {
                    continue;
                };
                md_add_unique(&mut out, self.link_to(c, &r.path));
            }
        }
        out
    }
}

/// Whether `paragraph` is exactly one span of kind `linked`.
pub(super) fn md_is_linked_paragraph(paragraph: &str) -> bool {
    let text = paragraph.trim();
    if !text.starts_with('[') || !text.ends_with("{.linked}") {
        return false;
    }
    let scan = scan_notation(text, false);
    if scan.elements.len() != 1 {
        return false;
    }
    let e = &scan.elements[0];
    e.type_ == "span"
        && e.kind.as_deref() == Some("linked")
        && e.start == 0
        && e.end == text.encode_utf16().count()
}

/// `markdown` with every placeholder resolved: `[]{.linked}` where the
/// paragraph after it is a `linked` span, else removed with its blank line.
pub(super) fn md_resolve_linked_placeholders(markdown: String) -> String {
    if !markdown.contains(MD_LINKED_PLACEHOLDER) {
        return markdown;
    }
    let lines: Vec<&str> = markdown.split('\n').collect();
    let mut out: Vec<&str> = Vec::with_capacity(lines.len());
    let mut i = 0;
    while i < lines.len() {
        if lines[i] != MD_LINKED_PLACEHOLDER {
            out.push(lines[i]);
            i += 1;
            continue;
        }
        // The placeholder, its blank line, then the paragraph that follows.
        let mut k = i + 1;
        while k < lines.len() && lines[k].trim().is_empty() {
            k += 1;
        }
        let mut j = k;
        while j < lines.len() && !lines[j].trim().is_empty() {
            j += 1;
        }
        if j > k && md_is_linked_paragraph(&lines[k..j].join("\n")) {
            out.push("[]{.linked}");
            i += 1;
        } else {
            i += 2; // the blank line after the placeholder goes with it
        }
    }
    out.join("\n")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn cut_and_list_patterns() {
        assert_eq!(md_cut_pattern("A/L-*/B"), "A/L");
        assert_eq!(md_cut_pattern("A/B"), "A/B");
        assert_eq!(md_list_pattern_of("A/L-*"), "A/L");
        assert_eq!(md_owner_of("A/B/C"), "A/B");
    }

    #[test]
    fn a_linked_paragraph_is_one_linked_span() {
        assert!(md_is_linked_paragraph(
            "[Also in [X](#X), held here]{.linked}"
        ));
        assert!(md_is_linked_paragraph("[]{.linked}"));
        assert!(!md_is_linked_paragraph("[a]{.aside}"));
        assert!(!md_is_linked_paragraph("text [a]{.linked}"));
        assert!(!md_is_linked_paragraph("[a]{.linked} [b]{.linked}"));
    }

    #[test]
    fn placeholders_resolve_to_the_empty_marker_or_go() {
        let kept = format!("# H\n\n{}\n\n[x]{{.linked}}\n", MD_LINKED_PLACEHOLDER);
        assert_eq!(
            md_resolve_linked_placeholders(kept),
            "# H\n\n[]{.linked}\n\n[x]{.linked}\n"
        );
        let gone = format!("# H\n\n{}\n\nText.\n", MD_LINKED_PLACEHOLDER);
        assert_eq!(md_resolve_linked_placeholders(gone), "# H\n\nText.\n");
    }
}
