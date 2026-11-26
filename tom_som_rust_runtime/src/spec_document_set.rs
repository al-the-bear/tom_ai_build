//! `spec_document_set` — a project's specification documents read side by
//! side, one per root, and the validation of the set
//! (`tom_specs_model_rules.md` §9.7): the places a Phase 3 document shares
//! with the Solution Blueprint agree, element by element and value by value,
//! and the links that cross two documents hold.
//!
//! The documents are never assembled into one: each keeps its own registry,
//! and every finding names the document a place is in. [`sync_report`] writes
//! nothing; [`rename_id`] renames an id in every document at once.
//!
//! A port of `tom_som_dart_runtime/lib/src/spec_document_set.dart` (and the
//! TypeScript, JavaScript, Python, Go and Java `spec_document_set` modules).
//! The comparison internals ([`SpecSetCheck`], [`SpecSetSide`]) are what
//! [`backfill`](crate::backfill) and [`prefill`](crate::prefill) read.

use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};
use std::rc::Rc;

use crate::json::Json;
use crate::spec_derive_fields::{derive_fields_dry_run, SpecDeriveOptions};
use crate::spec_document::SpecDocument;
use crate::spec_document_assembly::assemble_spec_documents;
use crate::spec_links_validator::{
    spec_expand_pattern, spec_link_ids, spec_resolve_place_at, validate_links,
};
use crate::spec_meta::SomMetaTree;
use crate::spec_meta_bridge::build_som_meta_tree;
use crate::spec_model::{
    FormFieldSpec, SpecClass, SpecModel, SPEC_FIELD_KIND_COMPLEX, SPEC_FIELD_KIND_LIST,
    SPEC_FIELD_KIND_SECTION,
};
use crate::spec_model_links::{link_json_text, SpecSummaryOf, SpecSync};
use crate::spec_place::{
    spec_same_as_bindings, spec_section_positions, SpecPlace, SpecPlaceFilter, SpecPlaceResolution,
    SpecSameAsBinding, SpecSectionPosition, SPEC_PLACE_KIND_CONTENT, SPEC_PLACE_KIND_FORM_FIELD,
    SPEC_PLACE_KIND_HEADLINE, SPEC_PLACE_KIND_LIST, SPEC_PLACE_KIND_SECTION_ID,
};
use crate::spec_reflection::{
    SpecReflection, SPEC_NODE_KIND_LIST_ITEM_COMPLEX, SPEC_NODE_KIND_LIST_ITEM_SCALAR,
};
use crate::spec_review_annotations::{apply_inline_marks_text, K_SPEC_HEADLINE_FIELD};
use crate::spec_section_id::{effective_list_item_section_id, K_SECTION_ID_SLOT};
use crate::spec_validator::{
    validate_document, SpecValidationError, SPEC_VALIDATION_CODE_UNMARKABLE,
};

// --- JSON helpers ----------------------------------------------------------------

pub(crate) fn set_jstr(s: &str) -> Json {
    Json::Str(s.to_string())
}

pub(crate) fn set_jobj(pairs: Vec<(&str, Json)>) -> Json {
    Json::Object(pairs.into_iter().map(|(k, v)| (k.to_string(), v)).collect())
}

pub(crate) fn set_jstrs(items: &[String]) -> Json {
    Json::Array(items.iter().map(|s| set_jstr(s)).collect())
}

/// `errors` as `[{path, code, message}]`.
pub(crate) fn spec_validation_errors_json(errors: &[SpecValidationError]) -> Json {
    Json::Array(
        errors
            .iter()
            .map(|e| {
                set_jobj(vec![
                    ("path", set_jstr(&e.path)),
                    ("code", set_jstr(&e.code)),
                    ("message", set_jstr(&e.message)),
                ])
            })
            .collect(),
    )
}

// --- the vocabulary of the set ------------------------------------------------

/// What a finding of the set reports, in the order the report sorts by (the
/// corpus compares the names).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum SpecSyncCode {
    /// Both documents hold the shared place, and the values differ.
    SharedValueDiffers,
    /// The Phase 3 document fills a shared place the Blueprint leaves empty.
    SharedValueMissing,
    /// The Blueprint fills a shared place the Phase 3 document leaves empty;
    /// the Phase 3 document emptied it, so `backfill` clears it.
    SharedValueOnlyInBlueprint,
    /// An element of an `equal` list (or an id of an `equal` reference field)
    /// is only in the Phase 3 document.
    SharedElementMissing,
    /// An element (or id) is only in the Blueprint, under `equal` or
    /// `subset`; `backfill` removes it.
    SharedElementOnlyInBlueprint,
    /// Under `subset`, an element (or id) only in the Phase 3 document: it may
    /// be added to the Blueprint, and is not carried in.
    SharedElementMayBeAdded,
    /// A `@SummaryOf(document:)` whose summary and detail sit in two documents
    /// does not hold.
    CrossSummaryMismatch,
    /// An `inverseOf` whose two ends sit in two documents is one-sided.
    CrossInverseMissing,
    /// A value holding pending change marks, listed for the user.
    PendingReview,
    /// A change `deriveFields` would write in a document under review that
    /// cannot be marked exactly.
    Unmarkable,
}

impl SpecSyncCode {
    /// Every code, in declaration order.
    pub const ALL: [SpecSyncCode; 10] = [
        SpecSyncCode::SharedValueDiffers,
        SpecSyncCode::SharedValueMissing,
        SpecSyncCode::SharedValueOnlyInBlueprint,
        SpecSyncCode::SharedElementMissing,
        SpecSyncCode::SharedElementOnlyInBlueprint,
        SpecSyncCode::SharedElementMayBeAdded,
        SpecSyncCode::CrossSummaryMismatch,
        SpecSyncCode::CrossInverseMissing,
        SpecSyncCode::PendingReview,
        SpecSyncCode::Unmarkable,
    ];

    /// The code's name as the corpus writes it (`sharedValueDiffers`, …).
    pub fn name(self) -> &'static str {
        match self {
            SpecSyncCode::SharedValueDiffers => "sharedValueDiffers",
            SpecSyncCode::SharedValueMissing => "sharedValueMissing",
            SpecSyncCode::SharedValueOnlyInBlueprint => "sharedValueOnlyInBlueprint",
            SpecSyncCode::SharedElementMissing => "sharedElementMissing",
            SpecSyncCode::SharedElementOnlyInBlueprint => "sharedElementOnlyInBlueprint",
            SpecSyncCode::SharedElementMayBeAdded => "sharedElementMayBeAdded",
            SpecSyncCode::CrossSummaryMismatch => "crossSummaryMismatch",
            SpecSyncCode::CrossInverseMissing => "crossInverseMissing",
            SpecSyncCode::PendingReview => "pendingReview",
            SpecSyncCode::Unmarkable => "unmarkable",
        }
    }

    /// The code named `name`, `None` for an unknown name.
    pub fn from_name(name: &str) -> Option<SpecSyncCode> {
        Self::ALL.into_iter().find(|c| c.name() == name)
    }

    /// The position in the declaration order.
    pub fn index(self) -> usize {
        self as usize
    }
}

/// How a finding of the set is resolved.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub enum SpecSyncResolution {
    /// `backfill` resolves it, writing the Blueprint.
    Backfill,
    /// `deriveFields` resolves it.
    DeriveFields,
    /// The agent decides (or asks the user).
    Agent,
    /// Reported, not a finding: it does not hold up a gate.
    Info,
}

impl SpecSyncResolution {
    /// Every resolution, in declaration order.
    pub const ALL: [SpecSyncResolution; 4] = [
        SpecSyncResolution::Backfill,
        SpecSyncResolution::DeriveFields,
        SpecSyncResolution::Agent,
        SpecSyncResolution::Info,
    ];

    /// The resolution's name as the corpus writes it.
    pub fn name(self) -> &'static str {
        match self {
            SpecSyncResolution::Backfill => "backfill",
            SpecSyncResolution::DeriveFields => "deriveFields",
            SpecSyncResolution::Agent => "agent",
            SpecSyncResolution::Info => "info",
        }
    }
}

/// Which document holds a shared place's value.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecSyncHolder {
    /// The Phase 3 document (the default).
    Detail,
    /// The Blueprint (`@SyncedWith(heldHere:)`).
    Blueprint,
}

impl SpecSyncHolder {
    /// The holder's name as the corpus writes it.
    pub fn name(self) -> &'static str {
        match self {
            SpecSyncHolder::Detail => "detail",
            SpecSyncHolder::Blueprint => "blueprint",
        }
    }
}

/// Why a document set cannot be built.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecDocumentSetRefusal {
    /// Two documents populate one root.
    SameRoot,
    /// A document populates no root.
    NoRoot,
    /// A document populates two roots.
    TwoRoots,
    /// A document is the CodeSpecs projection, which is no specification.
    Projection,
    /// Fragments of one root overlap.
    Overlap,
    /// A synced class's positions in the Blueprint and its document cannot be
    /// paired (invariant `SHARED-ANCHOR`).
    Unpairable,
}

impl SpecDocumentSetRefusal {
    /// The refusal's name as the corpus writes it.
    pub fn name(self) -> &'static str {
        match self {
            SpecDocumentSetRefusal::SameRoot => "sameRoot",
            SpecDocumentSetRefusal::NoRoot => "noRoot",
            SpecDocumentSetRefusal::TwoRoots => "twoRoots",
            SpecDocumentSetRefusal::Projection => "projection",
            SpecDocumentSetRefusal::Overlap => "overlap",
            SpecDocumentSetRefusal::Unpairable => "unpairable",
        }
    }
}

/// A document set that cannot be built, with the documents it names.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecDocumentSetError {
    /// Why.
    pub refusal: SpecDocumentSetRefusal,
    /// The documents (or fragments) concerned, in the order given.
    pub documents: Vec<String>,
    /// The prose for the reader.
    pub message: String,
    /// For [`SpecDocumentSetRefusal::Unpairable`], the class; `""` else.
    pub class_name: String,
}

impl SpecDocumentSetError {
    fn new(refusal: SpecDocumentSetRefusal, documents: Vec<String>, message: String) -> Self {
        SpecDocumentSetError {
            refusal,
            documents,
            message,
            class_name: String::new(),
        }
    }

    /// The canonical JSON form the corpus compares (no message).
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("refusal", set_jstr(self.refusal.name())),
            ("documents", set_jstrs(&self.documents)),
        ];
        if !self.class_name.is_empty() {
            out.push(("className", set_jstr(&self.class_name)));
        }
        set_jobj(out)
    }
}

impl std::fmt::Display for SpecDocumentSetError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "SpecDocumentSetError({}): {}",
            self.refusal.name(),
            self.message
        )
    }
}

impl std::error::Error for SpecDocumentSetError {}

/// Why [`SpecDocumentSet::load`] cannot load its files.
#[derive(Debug, Clone, PartialEq)]
pub enum SpecDocumentSetLoadError {
    /// A file cannot be read.
    Read { file: String, message: String },
    /// A YAML file does not decode.
    Decode { file: String, message: String },
    /// The documents do not make a set.
    Set(SpecDocumentSetError),
}

impl std::fmt::Display for SpecDocumentSetLoadError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SpecDocumentSetLoadError::Read { file, message } => {
                write!(f, "cannot read {}: {}", file, message)
            }
            SpecDocumentSetLoadError::Decode { file, message } => {
                write!(f, "cannot decode {}: {}", file, message)
            }
            SpecDocumentSetLoadError::Set(e) => e.fmt(f),
        }
    }
}

impl std::error::Error for SpecDocumentSetLoadError {}

/// A class kept in sync between the Blueprint and a Phase 3 document: its
/// position in each root.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecSyncPair {
    /// The class carrying `@SyncedWith` / `@DetailedIn`.
    pub class_name: String,
    /// Its section id: the name of the pair in findings and filters.
    pub section_id: String,
    /// The anchor in the Blueprint root (list items written `<list>-*`).
    pub blueprint_anchor: String,
    /// The anchor in the Phase 3 root.
    pub detail_anchor: String,
    /// The Phase 3 root's class name.
    pub detail_root: String,
    /// The class's `@SyncedWith`, `None` when only `@DetailedIn` is declared.
    pub sync: Option<SpecSync>,
}

impl SpecSyncPair {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        set_jobj(vec![
            ("pair", set_jstr(&self.section_id)),
            ("className", set_jstr(&self.class_name)),
            ("blueprint", set_jstr(&self.blueprint_anchor)),
            ("detail", set_jstr(&self.detail_anchor)),
            ("detailRoot", set_jstr(&self.detail_root)),
        ])
    }
}

// --- the set ------------------------------------------------------------------

/// A project's specification documents, one per root, read side by side.
/// The set owns its documents, each under the name the tools use (its file
/// name).
#[derive(Debug, Clone)]
pub struct SpecDocumentSet<'m> {
    /// The model the set is read with.
    pub model: &'m SpecModel,
    /// The Blueprint's root class name: the root the others are `basedOn`;
    /// `""` when the model names none.
    pub blueprint_root: String,
    documents: HashMap<String, SpecDocument>,
    root_of: HashMap<String, String>,
    order: Vec<String>,
    pairs: Vec<SpecSyncPair>,
}

impl<'m> SpecDocumentSet<'m> {
    /// A set of `documents`, each named by the file name the tools use. Each
    /// document populates exactly one root; two documents of one root, a
    /// document with no populated root or with two, and the CodeSpecs
    /// projection are refused with a [`SpecDocumentSetError`] naming the
    /// documents, as is a model whose synced positions cannot be paired.
    pub fn new(
        model: &'m SpecModel,
        documents: Vec<(String, SpecDocument)>,
    ) -> Result<SpecDocumentSet<'m>, SpecDocumentSetError> {
        let refl = SpecReflection::new(model);
        let blueprint_root = compute_blueprint_root(&refl);
        let pairs = compute_pairs(&refl, &blueprint_root)?;
        let mut set = SpecDocumentSet {
            model,
            blueprint_root,
            documents: HashMap::new(),
            root_of: HashMap::new(),
            order: Vec::new(),
            pairs,
        };
        for (name, doc) in documents {
            set.put(&name, doc)?;
        }
        Ok(set)
    }

    /// A set from documents and fragments: those of one root are fragments of
    /// one document, assembled in the order given (overlaps refused), the
    /// document named by its first fragment's name.
    pub fn from_fragments(
        model: &'m SpecModel,
        fragments: Vec<(String, SpecDocument)>,
    ) -> Result<SpecDocumentSet<'m>, SpecDocumentSetError> {
        let refl = SpecReflection::new(model);
        let mut by_root: HashMap<String, Vec<(String, SpecDocument)>> = HashMap::new();
        let mut root_order: Vec<String> = Vec::new();
        for (name, doc) in fragments {
            let roots = set_populated_roots(&refl, &doc);
            if roots.len() != 1 {
                let (refusal, what) = if roots.is_empty() {
                    (SpecDocumentSetRefusal::NoRoot, "no root".to_string())
                } else {
                    (SpecDocumentSetRefusal::TwoRoots, roots.join(" and "))
                };
                return Err(SpecDocumentSetError::new(
                    refusal,
                    vec![name.clone()],
                    format!("{} populates {}", name, what),
                ));
            }
            let root = roots[0].clone();
            if !by_root.contains_key(&root) {
                root_order.push(root.clone());
            }
            by_root.entry(root).or_default().push((name, doc));
        }
        let mut documents = Vec::new();
        for root in root_order {
            let mut group = by_root.remove(&root).unwrap_or_default();
            if group.len() == 1 {
                documents.push(group.remove(0));
                continue;
            }
            let names: Vec<String> = group.iter().map(|(n, _)| n.clone()).collect();
            let parts: Vec<(&str, &SpecDocument)> =
                group.iter().map(|(n, d)| (n.as_str(), d)).collect();
            let assembly = assemble_spec_documents(&parts);
            match assembly.document {
                Some(doc) if assembly.overlaps.is_empty() => {
                    documents.push((names[0].clone(), doc));
                }
                _ => {
                    return Err(SpecDocumentSetError::new(
                        SpecDocumentSetRefusal::Overlap,
                        names.clone(),
                        format!("the fragments {} overlap", names.join(", ")),
                    ))
                }
            }
        }
        SpecDocumentSet::new(model, documents)
    }

    /// Loads YAML or SOM Markdown files; files of one root are fragments and
    /// are assembled first (refusing overlaps). Each document is named by its
    /// first file's name.
    pub fn load<P: AsRef<str>>(
        model: &'m SpecModel,
        files: &[P],
    ) -> Result<SpecDocumentSet<'m>, SpecDocumentSetLoadError> {
        let mut trees: HashMap<String, SomMetaTree> = HashMap::new();
        let mut fragments = Vec::new();
        for file in files {
            let file = file.as_ref();
            let text =
                std::fs::read_to_string(file).map_err(|e| SpecDocumentSetLoadError::Read {
                    file: file.to_string(),
                    message: e.to_string(),
                })?;
            let normalized = file.replace('\\', "/");
            let name = normalized
                .rsplit('/')
                .next()
                .unwrap_or(normalized.as_str())
                .to_string();
            let doc = if file.ends_with(".md") {
                SpecDocument::from_markdown(&text, model).document
            } else {
                // The root key `<SECTIONID> <Type>:` names the tree to decode
                // with.
                let root = model.roots.iter().find(|r| {
                    let key = format!("{} {}:", r.section_id, r.type_);
                    text.lines().any(|l| l.trim_start().starts_with(&key))
                });
                let root = match root {
                    Some(r) => r,
                    None => {
                        return Err(SpecDocumentSetLoadError::Set(SpecDocumentSetError::new(
                            SpecDocumentSetRefusal::NoRoot,
                            vec![name.clone()],
                            format!("{} names no root of the model", name),
                        )))
                    }
                };
                if !trees.contains_key(&root.type_) {
                    let tree = build_som_meta_tree(model, &root.type_).map_err(|e| {
                        SpecDocumentSetLoadError::Decode {
                            file: file.to_string(),
                            message: e,
                        }
                    })?;
                    trees.insert(root.type_.clone(), tree);
                }
                SpecDocument::from_yaml(&text, &trees[&root.type_]).map_err(|e| {
                    SpecDocumentSetLoadError::Decode {
                        file: file.to_string(),
                        message: format!("{:?}", e),
                    }
                })?
            };
            fragments.push((name, doc));
        }
        SpecDocumentSet::from_fragments(model, fragments).map_err(SpecDocumentSetLoadError::Set)
    }

    /// The model's reflection.
    pub fn refl(&self) -> SpecReflection<'m> {
        SpecReflection::new(self.model)
    }

    /// The Blueprint document (the D00SolutionBlueprint), or `None`.
    pub fn blueprint(&self) -> Option<&SpecDocument> {
        if self.blueprint_root.is_empty() {
            return None;
        }
        self.document(&self.blueprint_root)
    }

    /// The document of `root_type` (a type name or a section id), or `None`.
    pub fn document(&self, root_type: &str) -> Option<&SpecDocument> {
        self.name_of(root_type).and_then(|n| self.documents.get(&n))
    }

    /// The name of the document of `root_type` (a type name or a section id),
    /// `None` when the set has none.
    pub fn name_of(&self, root_type: &str) -> Option<String> {
        let t = self.type_of(root_type)?;
        self.order
            .iter()
            .find(|n| self.root_of.get(*n) == Some(&t))
            .cloned()
    }

    fn type_of(&self, root_type: &str) -> Option<String> {
        if root_type.is_empty() {
            return None;
        }
        self.model
            .roots
            .iter()
            .find(|r| r.type_ == root_type || r.section_id == root_type)
            .map(|r| r.type_.clone())
    }

    fn has_root(&self, t: &str) -> bool {
        self.root_of.values().any(|r| r == t)
    }

    /// The populated roots, in model order.
    pub fn roots(&self) -> Vec<String> {
        self.model
            .roots
            .iter()
            .filter(|r| self.has_root(&r.type_))
            .map(|r| r.type_.clone())
            .collect()
    }

    /// The document names, in model order of their roots.
    pub fn names(&self) -> Vec<String> {
        self.roots()
            .iter()
            .filter_map(|r| self.name_of(r))
            .collect()
    }

    /// Every Phase 3 root a pair names with no document yet: its pairs are
    /// "not started", reported as such and never as findings.
    pub fn missing_roots(&self) -> Vec<String> {
        self.model
            .roots
            .iter()
            .filter(|r| {
                self.pairs.iter().any(|p| p.detail_root == r.type_) && !self.has_root(&r.type_)
            })
            .map(|r| r.type_.clone())
            .collect()
    }

    /// The anchor pairs, in the Blueprint's walk order.
    pub fn pairs(&self) -> &[SpecSyncPair] {
        &self.pairs
    }

    /// Adds or replaces a document (what `prefill` creates); refused like the
    /// documents [`new`](Self::new) takes.
    pub fn put(&mut self, name: &str, document: SpecDocument) -> Result<(), SpecDocumentSetError> {
        let refl = self.refl();
        let roots = set_populated_roots(&refl, &document);
        if roots.is_empty() {
            return Err(SpecDocumentSetError::new(
                SpecDocumentSetRefusal::NoRoot,
                vec![name.to_string()],
                format!("{} populates no root", name),
            ));
        }
        if roots.len() > 1 {
            return Err(SpecDocumentSetError::new(
                SpecDocumentSetRefusal::TwoRoots,
                vec![name.to_string()],
                format!("{} populates {}", name, roots.join(" and ")),
            ));
        }
        let root = roots[0].clone();
        if refl
            .class_named(&root)
            .is_some_and(|c| c.is_code_specs_projection())
        {
            return Err(SpecDocumentSetError::new(
                SpecDocumentSetRefusal::Projection,
                vec![name.to_string()],
                format!(
                    "{} is the CodeSpecs projection, which is no specification",
                    name
                ),
            ));
        }
        for other in &self.order {
            if self.root_of.get(other) == Some(&root) && other != name {
                return Err(SpecDocumentSetError::new(
                    SpecDocumentSetRefusal::SameRoot,
                    vec![other.clone(), name.to_string()],
                    format!("{} and {} both populate {}", other, name, root),
                ));
            }
        }
        if !self.documents.contains_key(name) {
            self.order.push(name.to_string());
        }
        self.documents.insert(name.to_string(), document);
        self.root_of.insert(name.to_string(), root);
        Ok(())
    }

    /// Replaces the document named `name` without the checks of
    /// [`put`](Self::put) (the writes of `backfill` and `prefill`, which keep
    /// its root).
    pub(crate) fn replace(&mut self, name: &str, document: SpecDocument) {
        if let Some(d) = self.documents.get_mut(name) {
            *d = document;
        }
    }

    /// The document named `name`, or `None`.
    pub fn get(&self, name: &str) -> Option<&SpecDocument> {
        self.documents.get(name)
    }

    /// The document named `name` to write, or `None`.
    pub fn get_mut(&mut self, name: &str) -> Option<&mut SpecDocument> {
        self.documents.get_mut(name)
    }

    /// The root class name of the document named `name`, `""` when the set
    /// has none of that name.
    pub fn root_of(&self, name: &str) -> String {
        self.root_of.get(name).cloned().unwrap_or_default()
    }
}

/// The roots `doc` holds a value under, in model order.
fn set_populated_roots(refl: &SpecReflection<'_>, doc: &SpecDocument) -> Vec<String> {
    let mut segs: HashSet<String> = HashSet::new();
    for paths in [
        doc.content_paths(),
        doc.form_paths(),
        doc.list_paths(),
        doc.headline_paths(),
    ] {
        for p in paths {
            let seg = p.split('/').next().unwrap_or("").to_string();
            segs.insert(seg);
        }
    }
    refl.model
        .roots
        .iter()
        .filter(|r| segs.contains(&refl.root_segment(r)))
        .map(|r| r.type_.clone())
        .collect()
}

fn compute_blueprint_root(refl: &SpecReflection<'_>) -> String {
    let mut targets: Vec<String> = Vec::new();
    for r in &refl.model.roots {
        let cls = match refl.class_named(&r.type_) {
            Some(c) => c,
            None => continue,
        };
        let based = cls
            .annotation("Document")
            .and_then(|d| d.argument("basedOn"))
            .and_then(|b| b.as_array());
        if let Some(based) = based {
            for e in based {
                let t = link_json_text(e);
                if !targets.contains(&t) {
                    targets.push(t);
                }
            }
        }
    }
    if targets.len() == 1 {
        targets.remove(0)
    } else {
        String::new()
    }
}

// --- the anchor pairs ---------------------------------------------------------

/// The class positions of `root` that can be paired: member positions and
/// `@SameAs` copies (kept equal to their holder, never paired) left out.
fn pairable_positions<'m>(refl: &SpecReflection<'m>, root: &str) -> Vec<SpecSectionPosition<'m>> {
    let every = spec_section_positions(refl, root);
    let copies: Vec<String> = every
        .iter()
        .filter(|p| !p.is_member && p.member.is_some_and(|m| m.same_as().is_some()))
        .map(|p| p.path.clone())
        .collect();
    every
        .into_iter()
        .filter(|p| {
            !p.is_member
                && !copies
                    .iter()
                    .any(|c| p.path == *c || p.path.starts_with(&format!("{}/", c)))
        })
        .collect()
}

fn compute_pairs(
    refl: &SpecReflection<'_>,
    bp: &str,
) -> Result<Vec<SpecSyncPair>, SpecDocumentSetError> {
    let mut out = Vec::new();
    if bp.is_empty() {
        return Ok(out);
    }
    let mut positions: HashMap<String, Vec<SpecSectionPosition<'_>>> = HashMap::new();
    positions.insert(bp.to_string(), pairable_positions(refl, bp));

    let mut candidates: HashMap<String, String> = HashMap::new(); // class -> target root
    let mut candidate_order: Vec<String> = Vec::new();
    for p in &positions[bp] {
        let cls = match refl.class_named(&p.class_name) {
            Some(c) => c,
            None => continue,
        };
        let target = match cls.synced_with() {
            Some(sync) => sync.document,
            None => cls.detailed_in.clone(),
        };
        if target.is_empty() || target == bp || refl.class_named(&target).is_none() {
            continue;
        }
        if !candidates.contains_key(&p.class_name) {
            candidates.insert(p.class_name.clone(), target);
            candidate_order.push(p.class_name.clone());
        }
    }
    for target in candidates.values() {
        if !positions.contains_key(target) {
            positions.insert(target.clone(), pairable_positions(refl, target));
        }
    }

    let unpairable = |class_name: &str| {
        SpecDocumentSetError {
        refusal: SpecDocumentSetRefusal::Unpairable,
        documents: Vec::new(),
        message: format!(
            "the positions of {} in the Blueprint and its document cannot be paired (SHARED-ANCHOR)",
            class_name
        ),
        class_name: class_name.to_string(),
    }
    };

    // Paired by the path below the nearest enclosing anchor.
    let key = |p: &SpecSectionPosition<'_>, root: &str| -> String {
        let mut outer: Option<&SpecSectionPosition<'_>> = None;
        for q in &positions[root] {
            if q.path == p.path || !p.path.starts_with(&format!("{}/", q.path)) {
                continue;
            }
            if !candidates.contains_key(&q.class_name) {
                continue;
            }
            if outer.is_none_or(|o| q.path.len() > o.path.len()) {
                outer = Some(q);
            }
        }
        let (ids, outer_name) = match outer {
            Some(o) => (&p.section_ids[o.section_ids.len()..], o.class_name.as_str()),
            None => (&p.section_ids[..], ""),
        };
        format!("{}/{}", outer_name, ids.join("/"))
    };

    for class_name in &candidate_order {
        let target = &candidates[class_name];
        let mine: Vec<&SpecSectionPosition<'_>> = positions[bp]
            .iter()
            .filter(|p| &p.class_name == class_name)
            .collect();
        let theirs: Vec<&SpecSectionPosition<'_>> = positions[target]
            .iter()
            .filter(|p| &p.class_name == class_name)
            .collect();
        if theirs.is_empty() {
            continue;
        }
        let mut matched: Vec<(&SpecSectionPosition<'_>, &SpecSectionPosition<'_>)> = Vec::new();
        if mine.len() == 1 && theirs.len() == 1 {
            matched.push((mine[0], theirs[0]));
        } else {
            let mut by_key: HashMap<String, &SpecSectionPosition<'_>> = HashMap::new();
            for p in &theirs {
                let k = key(p, target);
                if by_key.contains_key(&k) {
                    return Err(unpairable(class_name));
                }
                by_key.insert(k, p);
            }
            for p in &mine {
                let k = key(p, bp);
                match by_key.remove(&k) {
                    Some(q) => matched.push((p, q)),
                    None => return Err(unpairable(class_name)),
                }
            }
            if !by_key.is_empty() {
                return Err(unpairable(class_name));
            }
        }
        let cls = refl.class_named(class_name);
        let section_id = cls
            .map(|c| c.section_id.clone())
            .filter(|s| !s.is_empty())
            .unwrap_or_else(|| class_name.clone());
        let sync = cls.and_then(|c| c.synced_with());
        for (b, d) in matched {
            out.push(SpecSyncPair {
                class_name: class_name.clone(),
                section_id: section_id.clone(),
                blueprint_anchor: b.path.clone(),
                detail_anchor: d.path.clone(),
                detail_root: target.clone(),
                sync: sync.clone(),
            });
        }
    }
    Ok(out)
}

// --- findings and the report --------------------------------------------------

/// One side of a finding: where the place is and what it holds.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct SpecSyncPlace {
    /// The document's name, `None` when the set has none for this side.
    pub document: Option<String>,
    /// The root's section id.
    pub root: String,
    /// The document path (for a place the document does not hold, the
    /// nearest path it does: the list an element would be added to).
    pub path: String,
    /// The form field, `""` for none.
    pub field: String,
    /// The value (read with pending marks rejected), `None` when absent.
    pub value: Option<String>,
    /// Whether the value holds pending change marks.
    pub pending_marks: bool,
}

impl SpecSyncPlace {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("root", set_jstr(&self.root)),
            ("path", set_jstr(&self.path)),
            (
                "document",
                self.document.as_deref().map_or(Json::Null, set_jstr),
            ),
        ];
        if !self.field.is_empty() {
            out.push(("field", set_jstr(&self.field)));
        }
        if let Some(v) = &self.value {
            out.push(("value", set_jstr(v)));
        }
        out.push(("pendingMarks", Json::Bool(self.pending_marks)));
        set_jobj(out)
    }

    /// The value, `""` when absent.
    pub fn value_or(&self) -> &str {
        self.value.as_deref().unwrap_or("")
    }
}

/// One finding of the set.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecSyncFinding {
    /// What it reports.
    pub code: SpecSyncCode,
    /// The pair's section id (the summary's or link's class for a cross
    /// check, empty for a pending value outside every pair).
    pub pair: String,
    /// The Blueprint side (for a cross check, the side holding the link).
    pub blueprint: SpecSyncPlace,
    /// The Phase 3 side (for a cross check, the other end).
    pub detail: SpecSyncPlace,
    /// Which side holds the value.
    pub holder: SpecSyncHolder,
    /// How it is resolved.
    pub resolution: SpecSyncResolution,
    /// Prose for the agent, in the canonical form: every runtime writes the
    /// same sentence (the conformance corpus compares it).
    pub message: String,
}

impl SpecSyncFinding {
    /// Whether it is reported only, not a finding.
    pub fn is_info(&self) -> bool {
        self.resolution == SpecSyncResolution::Info
    }

    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        set_jobj(vec![
            ("code", set_jstr(self.code.name())),
            ("pair", set_jstr(&self.pair)),
            ("blueprint", self.blueprint.to_json()),
            ("detail", self.detail.to_json()),
            ("holder", set_jstr(self.holder.name())),
            ("resolution", set_jstr(self.resolution.name())),
            ("message", set_jstr(&self.message)),
            ("info", Json::Bool(self.is_info())),
        ])
    }
}

/// One document's own findings in a [`SpecSyncReport`].
#[derive(Debug, Clone, PartialEq)]
pub struct SpecDocumentFindings {
    /// The document's name.
    pub name: String,
    /// Its findings (`validate_document`, then `validate_links`).
    pub errors: Vec<SpecValidationError>,
}

/// The validation of a document set.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecSyncReport {
    /// The findings in pair and path order, `info` entries included.
    pub findings: Vec<SpecSyncFinding>,
    /// Each document's own findings (`validate_document`, then
    /// `validate_links`), in the set's order.
    pub document_findings: Vec<SpecDocumentFindings>,
    /// The Phase 3 roots with no document yet.
    pub not_started: Vec<String>,
    /// The pairs (by section id) whose Phase 3 document exists but holds
    /// nothing beneath the pair's anchor: not started, like a missing
    /// document.
    pub not_started_pairs: Vec<String>,
}

impl SpecSyncReport {
    /// The findings per code, `info` entries included, in code order (codes
    /// without findings left out).
    pub fn counts_by_code(&self) -> Vec<(SpecSyncCode, usize)> {
        SpecSyncCode::ALL
            .into_iter()
            .map(|c| (c, self.findings.iter().filter(|f| f.code == c).count()))
            .filter(|(_, n)| *n > 0)
            .collect()
    }

    /// The findings per resolution, in resolution order.
    pub fn counts_by_resolution(&self) -> Vec<(SpecSyncResolution, usize)> {
        SpecSyncResolution::ALL
            .into_iter()
            .map(|r| {
                (
                    r,
                    self.findings.iter().filter(|f| f.resolution == r).count(),
                )
            })
            .filter(|(_, n)| *n > 0)
            .collect()
    }

    /// Whether there is no finding other than `info`.
    pub fn clean(&self) -> bool {
        self.findings.iter().all(SpecSyncFinding::is_info)
    }

    /// [`counts_by_code`](Self::counts_by_code) as the canonical
    /// `[[code, count], …]` form.
    pub fn counts_by_code_json(&self) -> Json {
        spec_sync_counts_json(
            self.counts_by_code()
                .into_iter()
                .map(|(c, n)| (c.name(), n)),
        )
    }

    /// [`counts_by_resolution`](Self::counts_by_resolution) as the canonical
    /// `[[resolution, count], …]` form.
    pub fn counts_by_resolution_json(&self) -> Json {
        spec_sync_counts_json(
            self.counts_by_resolution()
                .into_iter()
                .map(|(r, n)| (r.name(), n)),
        )
    }

    /// The canonical JSON form; every ordered value is a list.
    pub fn to_json(&self) -> Json {
        set_jobj(vec![
            (
                "findings",
                Json::Array(self.findings.iter().map(SpecSyncFinding::to_json).collect()),
            ),
            (
                "documentFindings",
                Json::Array(
                    self.document_findings
                        .iter()
                        .map(|d| {
                            Json::Array(vec![
                                set_jstr(&d.name),
                                spec_validation_errors_json(&d.errors),
                            ])
                        })
                        .collect(),
                ),
            ),
            ("notStarted", set_jstrs(&self.not_started)),
            ("notStartedPairs", set_jstrs(&self.not_started_pairs)),
            ("countsByCode", self.counts_by_code_json()),
            ("countsByResolution", self.counts_by_resolution_json()),
            ("clean", Json::Bool(self.clean())),
        ])
    }
}

/// Counts as the canonical `[[key, count], …]` form.
pub fn spec_sync_counts_json<'k>(counts: impl IntoIterator<Item = (&'k str, usize)>) -> Json {
    Json::Array(
        counts
            .into_iter()
            .map(|(k, n)| Json::Array(vec![set_jstr(k), Json::Int(n as i64)]))
            .collect(),
    )
}

/// A set of pair section ids, `None` for every pair.
pub(crate) fn pair_scope(pairs: Option<&[String]>) -> Option<HashSet<String>> {
    pairs.map(|p| p.iter().cloned().collect())
}

/// The validation of `set`, with counts; `pairs` (`Some`) keeps the findings
/// of those pairs (by section id) only. Writes nothing.
pub fn sync_report(set: &SpecDocumentSet<'_>, pairs: Option<&[String]>) -> SpecSyncReport {
    let scope = pair_scope(pairs);
    let mut c = SpecSetCheck::new(set);
    let mut index = 0;
    for p in set.pairs() {
        if scope.as_ref().is_none_or(|s| s.contains(&p.section_id)) {
            c.compare_pair(p, index);
        }
        index += 1;
    }
    c.cross_checks(scope.as_ref(), index);
    if scope.is_none() {
        c.pending_scan(index + 1);
        c.unmarkable_scan(index + 2);
    }
    c.sort_out();
    let mut document_findings = Vec::new();
    for name in set.names() {
        let doc = &set.documents[&name];
        let mut errors = validate_document(set.model, doc);
        errors.extend(validate_links(set.model, doc));
        document_findings.push(SpecDocumentFindings { name, errors });
    }
    SpecSyncReport {
        findings: c.out.into_iter().map(|o| o.finding).collect(),
        document_findings,
        not_started: set.missing_roots(),
        not_started_pairs: c.not_started_pairs,
    }
}

// --- the comparison -----------------------------------------------------------

/// A finding with its sort keys (and, for a pair's finding, its two sides).
#[derive(Debug, Clone)]
pub struct SpecSetFound {
    pub order: usize,
    pub key: String,
    pub finding: SpecSyncFinding,
    pub b: Option<Rc<SpecSetSide>>,
    pub d: Option<Rc<SpecSetSide>>,
}

/// One value of a subtree, keyed for comparison.
#[derive(Debug, Clone)]
pub struct SpecSetValue {
    pub path: String,
    /// The form field ([`K_SPEC_HEADLINE_FIELD`] for a headline), `""` for
    /// content.
    pub field: String,
    pub value: String,
    pub pending: bool,
    pub spec: Option<FormFieldSpec>,
}

/// A document side of a pair: its subtree's values and items, keyed by the
/// path below the anchor with list items written by their section id.
#[derive(Debug, Clone, Default)]
pub struct SpecSetSide {
    pub name: String,
    pub root: String,
    pub anchor: String,
    /// The values by key (`c:` content, `f:` form field, `h:` headline).
    pub values: BTreeMap<String, SpecSetValue>,
    /// Item key → item path, and the anchor's own key `""`.
    pub items: HashMap<String, String>,
    /// The keys of `items` in the order they were collected.
    pub item_keys: Vec<String>,
}

impl SpecSetSide {
    fn new(name: &str, root: &str, anchor: &str) -> SpecSetSide {
        SpecSetSide {
            name: name.to_string(),
            root: root.to_string(),
            anchor: anchor.to_string(),
            ..SpecSetSide::default()
        }
    }

    fn put_item(&mut self, key: String, path: &str) {
        if !self.items.contains_key(&key) {
            self.item_keys.push(key.clone());
        }
        self.items.insert(key, path.to_string());
    }
}

/// The places a set of place texts stands for under an anchor.
#[derive(Debug, Default)]
struct SetPlaces {
    prefixes: Vec<String>,
    fields: HashSet<String>,
    headlines: HashSet<String>,
}

/// `^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$`, any case.
fn set_is_float_text(t: &str) -> bool {
    let b = t.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
        i += 1;
    }
    let int_start = i;
    while i < b.len() && b[i].is_ascii_digit() {
        i += 1;
    }
    let int_digits = i - int_start;
    if int_digits > 0 {
        if i < b.len() && b[i] == b'.' {
            i += 1;
            while i < b.len() && b[i].is_ascii_digit() {
                i += 1;
            }
        }
    } else {
        if i >= b.len() || b[i] != b'.' {
            return false;
        }
        i += 1;
        let frac_start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        if i == frac_start {
            return false;
        }
    }
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        i += 1;
        if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
            i += 1;
        }
        let exp_start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        if i == exp_start {
            return false;
        }
    }
    i == b.len()
}

/// Dart's `num.tryParse`: decimal, hex, `Infinity` and `NaN`.
fn set_num_try_parse(text: &str) -> Option<f64> {
    let t = text.trim();
    if set_is_float_text(t) {
        let normalized = if t.ends_with('.') {
            format!("{}0", t)
        } else {
            t.to_string()
        };
        return normalized.parse::<f64>().ok();
    }
    let (neg, body) = match t.as_bytes().first() {
        Some(b'-') => (true, &t[1..]),
        Some(b'+') => (false, &t[1..]),
        _ => (false, t),
    };
    if body.len() > 2
        && (body.starts_with("0x") || body.starts_with("0X"))
        && body[2..].bytes().all(|c| c.is_ascii_hexdigit())
    {
        let n = u64::from_str_radix(&body[2..], 16).ok()? as f64;
        return Some(if neg { -n } else { n });
    }
    match body {
        "NaN" => Some(f64::NAN),
        "Infinity" => Some(if neg {
            f64::NEG_INFINITY
        } else {
            f64::INFINITY
        }),
        _ => None,
    }
}

/// Whether `path` is one of `prefixes` or beneath one.
fn set_under_any(path: &str, prefixes: &[String]) -> bool {
    prefixes
        .iter()
        .any(|p| path == p || (path.starts_with(p.as_str()) && path[p.len()..].starts_with('/')))
}

/// `raw` with every pending mark rejected, trimmed.
pub fn spec_set_reviewed(raw: &str) -> String {
    apply_inline_marks_text(raw, false).trim().to_string()
}

/// Whether `raw` holds pending change marks.
pub fn spec_set_is_pending(raw: &str) -> bool {
    apply_inline_marks_text(raw, true) != apply_inline_marks_text(raw, false)
}

/// Whether `a` and `b` are the same value of the field's type.
pub fn spec_set_same_typed(a: &str, b: &str, spec: Option<&FormFieldSpec>) -> bool {
    match spec.map_or("", |s| s.type_.as_str()) {
        "int" | "double" | "num" => {
            if let (Some(x), Some(y)) = (set_num_try_parse(a), set_num_try_parse(b)) {
                return x == y;
            }
        }
        "bool" => return a.to_lowercase() == b.to_lowercase(),
        _ => {}
    }
    a == b
}

/// A value key (`c:` / `f:` / `h:` / `i:`) without its kind and field.
pub fn spec_set_strip_kind(key: &str) -> &str {
    let k = if key.len() > 2 && key.as_bytes()[1] == b':' {
        &key[2..]
    } else {
        key
    };
    match k.find('#') {
        Some(h) => &k[..h],
        None => k,
    }
}

/// The key with every item id dropped (`LIST[X]` → `LIST[]`).
fn set_shape(key: &str) -> String {
    let mut out = String::with_capacity(key.len());
    let mut rest = key;
    while let Some(open) = rest.find('[') {
        match rest[open..].find(']') {
            Some(close) => {
                out.push_str(&rest[..open]);
                out.push_str("[]");
                rest = &rest[open + close + 1..];
            }
            None => break,
        }
    }
    out.push_str(rest);
    out
}

/// The distinct entries of `a` not in `b`, sorted.
fn set_sorted_minus(a: &[String], b: &[String]) -> Vec<String> {
    a.iter()
        .filter(|x| !b.contains(x))
        .cloned()
        .collect::<BTreeSet<String>>()
        .into_iter()
        .collect()
}

/// The stored section id of the item at `item_path`, else the one its
/// position and the list's pattern give it.
pub(crate) fn set_effective_item_id(
    refl: &SpecReflection<'_>,
    doc: &SpecDocument,
    item_path: &str,
) -> String {
    if let Some(stored) = doc.item_section_id(item_path) {
        return stored.clone();
    }
    let lst = &item_path[..item_path.rfind('-').unwrap_or(item_path.len())];
    let mut pattern = String::new();
    let mut stem = lst[lst.rfind('/').map_or(0, |s| s + 1)..].to_string();
    if let Some(field) = refl.resolve(lst).and_then(|r| r.field) {
        pattern = field.section_id_pattern;
        stem = field.name;
    }
    let position = doc
        .list_items(lst)
        .iter()
        .position(|it| it == item_path)
        .map_or(0, |i| i + 1);
    effective_list_item_section_id(None, &pattern, position, &stem)
}

/// The cache key of a document: its address (the documents a check reads do
/// not move while it runs).
fn doc_key(doc: &SpecDocument) -> usize {
    doc as *const SpecDocument as usize
}

/// One class instance of a document: its path and class.
struct SetInstance<'m> {
    path: String,
    cls: &'m SpecClass,
}

/// One detail element of a cross summary: its item and id.
struct SetElement {
    item: String,
    id: String,
}

/// A value read at a place: its path, value and field.
struct SetValueAt {
    path: String,
    value: String,
    field: String,
}

/// The comparison behind [`sync_report`] (and `backfill`, `prefill` and
/// [`rename_id`]): one per run, with its caches.
pub struct SpecSetCheck<'s, 'm> {
    pub set: &'s SpecDocumentSet<'m>,
    pub refl: SpecReflection<'m>,
    /// The findings collected so far.
    pub out: Vec<SpecSetFound>,
    /// The pairs whose Phase 3 document exists but holds nothing beneath the
    /// pair's anchor.
    pub not_started_pairs: Vec<String>,

    item_ids: HashMap<(usize, String), String>,
    items: HashMap<String, bool>,
    forms: HashMap<usize, HashMap<String, Vec<String>>>,
    registry_docs: HashMap<String, String>,
    reach: HashMap<String, HashSet<String>>,
    entries: HashMap<usize, HashMap<String, HashMap<String, String>>>,
    same_as: HashMap<String, Vec<SpecSameAsBinding>>,
}

impl<'s, 'm> SpecSetCheck<'s, 'm> {
    /// The comparison of `set`.
    pub fn new(set: &'s SpecDocumentSet<'m>) -> SpecSetCheck<'s, 'm> {
        SpecSetCheck {
            set,
            refl: set.refl(),
            out: Vec::new(),
            not_started_pairs: Vec::new(),
            item_ids: HashMap::new(),
            items: HashMap::new(),
            forms: HashMap::new(),
            registry_docs: HashMap::new(),
            reach: HashMap::new(),
            entries: HashMap::new(),
            same_as: HashMap::new(),
        }
    }

    fn add(
        &mut self,
        order: usize,
        key: String,
        finding: SpecSyncFinding,
        b: Option<Rc<SpecSetSide>>,
        d: Option<Rc<SpecSetSide>>,
    ) {
        self.out.push(SpecSetFound {
            order,
            key,
            finding,
            b,
            d,
        });
    }

    /// Sorts `out` as the report lists it.
    pub fn sort_out(&mut self) {
        let value = |f: &SpecSyncFinding| -> String {
            f.blueprint
                .value
                .clone()
                .unwrap_or_else(|| f.detail.value_or().to_string())
        };
        self.out.sort_by(|a, b| {
            a.order
                .cmp(&b.order)
                .then_with(|| a.key.cmp(&b.key))
                .then_with(|| a.finding.code.index().cmp(&b.finding.code.index()))
                .then_with(|| value(&a.finding).cmp(&value(&b.finding)))
        });
    }

    fn root_seg(&self, type_name: &str) -> String {
        match self.refl.model.roots.iter().find(|r| r.type_ == type_name) {
            Some(r) => self.refl.root_segment(r),
            None => panic!("no root {}", type_name),
        }
    }

    /// The effective section id of the list item at `item_path` in `doc`.
    pub fn item_id(&mut self, doc: &SpecDocument, item_path: &str) -> String {
        let key = (doc_key(doc), item_path.to_string());
        if let Some(hit) = self.item_ids.get(&key) {
            return hit.clone();
        }
        let hit = set_effective_item_id(&self.refl, doc, item_path);
        self.item_ids.insert(key, hit.clone());
        hit
    }

    /// Whether `path` is a list item (complex or scalar).
    pub fn is_item(&mut self, path: &str) -> bool {
        if let Some(hit) = self.items.get(path) {
            return *hit;
        }
        // A scalar list's items are elements too, keyed by their effective id
        // like a complex list's (`LIST[ID]`).
        let hit = self.refl.resolve(path).is_some_and(|r| {
            r.kind == SPEC_NODE_KIND_LIST_ITEM_COMPLEX || r.kind == SPEC_NODE_KIND_LIST_ITEM_SCALAR
        });
        self.items.insert(path.to_string(), hit);
        hit
    }

    /// The concrete paths a pattern (list items `<list>-*`) stands for in
    /// `doc`.
    pub fn expand(&self, doc: &SpecDocument, pattern: &str) -> Vec<String> {
        spec_expand_pattern(doc, pattern)
    }

    /// The key of `path` below `anchor`: item segments as `LIST[id]`.
    pub fn key(&mut self, doc: &SpecDocument, anchor: &str, path: &str) -> String {
        if path == anchor {
            return String::new();
        }
        let mut out = Vec::new();
        let mut at = anchor.to_string();
        for seg in path[anchor.len() + 1..].split('/') {
            at = format!("{}/{}", at, seg);
            if self.is_item(&at) {
                let base = &seg[..seg.rfind('-').unwrap_or(seg.len())];
                out.push(format!("{}[{}]", base, self.item_id(doc, &at)));
            } else {
                out.push(seg.to_string());
            }
        }
        out.join("/")
    }

    /// The key of an anchor itself among its siblings: the ids of the list
    /// items on its path.
    pub fn anchor_key(&mut self, doc: &SpecDocument, path: &str) -> String {
        let mut out = Vec::new();
        let mut at = String::new();
        for seg in path.split('/') {
            if at.is_empty() {
                at = seg.to_string();
            } else {
                at = format!("{}/{}", at, seg);
            }
            if self.is_item(&at) {
                out.push(self.item_id(doc, &at));
            }
        }
        out.join("/")
    }

    /// The paths `places` resolved under `anchor` stand for in `doc`: whole
    /// sections (prefixes), single form fields and headlines.
    fn places(&self, doc: &SpecDocument, places: &[String], anchor: &str) -> SetPlaces {
        let mut out = SetPlaces::default();
        for text in places {
            let r = match spec_resolve_place_at(&self.refl, text, anchor) {
                Some(r) => r,
                None => continue,
            };
            for p in self.expand(doc, &r.path) {
                match r.kind.as_str() {
                    SPEC_PLACE_KIND_FORM_FIELD => {
                        out.fields.insert(format!("{}#{}", p, r.field()));
                    }
                    SPEC_PLACE_KIND_HEADLINE => {
                        out.headlines.insert(p);
                    }
                    SPEC_PLACE_KIND_SECTION_ID => {}
                    _ => out.prefixes.push(p),
                }
            }
        }
        out
    }

    /// The values beneath `anchor` in `doc`, with what the pair does not
    /// compare left out: `detailOnly` places, nested pairs, `@SameAs` copies
    /// and derived places.
    pub fn collect(
        &mut self,
        name: &str,
        doc: &SpecDocument,
        root: &str,
        anchor: &str,
        pair: &SpecSyncPair,
        nested: &[String],
    ) -> SpecSetSide {
        let refl = SpecReflection::new(self.set.model);
        let mut side = SpecSetSide::new(name, root, anchor);
        let detail_only: Vec<String> = pair
            .sync
            .as_ref()
            .map(|s| s.detail_only.clone())
            .unwrap_or_default();
        let mut skip = self.places(doc, &detail_only, anchor);
        if !self.same_as.contains_key(root) {
            let bindings = spec_same_as_bindings(&refl, root);
            self.same_as.insert(root.to_string(), bindings);
        }
        let mut excluded: Vec<String> = skip.prefixes.clone();
        excluded.extend(nested.iter().cloned());
        let copies: Vec<String> = self.same_as[root]
            .iter()
            .map(|b| b.copy_path.clone())
            .collect();
        for c in copies {
            excluded.extend(self.expand(doc, &c));
        }
        let anchor_prefix = format!("{}/", anchor);
        let under = |p: &str| p == anchor || p.starts_with(&anchor_prefix);
        let outside = |p: &str, excluded: &[String]| p != anchor && set_under_any(p, excluded);

        let lists = doc.list_paths();
        // The values a summary row repeats are derived from its detail element
        // (`@SummaryOf` repeats): never shared, like every derived place.
        for lst in &lists {
            if !under(lst) {
                continue;
            }
            let field = match refl.resolve(lst).and_then(|r| r.field) {
                Some(f) => f,
                None => continue,
            };
            let s = match field.summary_of() {
                Some(s) if !s.repeats.is_empty() => s,
                _ => continue,
            };
            let repeats: Vec<String> = s.repeats.iter().map(|r| r.0.clone()).collect();
            for item in doc.list_items(lst) {
                let r = self.places(doc, &repeats, &item);
                excluded.extend(r.prefixes);
                skip.fields.extend(r.fields);
                skip.headlines.extend(r.headlines);
            }
        }

        side.put_item(String::new(), anchor);
        for lst in &lists {
            if !under(lst) || outside(lst, &excluded) {
                continue;
            }
            if refl
                .resolve(lst)
                .and_then(|r| r.field)
                .is_some_and(|f| f.derived_from().is_some())
            {
                excluded.push(lst.clone());
                continue;
            }
            for item in doc.list_items(lst) {
                let k = self.key(doc, anchor, &item);
                side.put_item(k, &item);
            }
        }
        for p in doc.content_paths() {
            if !under(&p) || outside(&p, &excluded) {
                continue;
            }
            if refl
                .resolve(&p)
                .and_then(|r| r.field)
                .is_some_and(|f| f.derived_from().is_some())
            {
                continue;
            }
            let raw = doc.content_or(&p);
            let k = format!("c:{}", self.key(doc, anchor, &p));
            side.values.insert(
                k,
                SpecSetValue {
                    path: p.clone(),
                    field: String::new(),
                    value: spec_set_reviewed(&raw),
                    pending: spec_set_is_pending(&raw),
                    spec: None,
                },
            );
        }
        for p in doc.form_paths() {
            if !under(&p) || outside(&p, &excluded) {
                continue;
            }
            let specs: Vec<FormFieldSpec> = refl
                .resolve(&p)
                .and_then(|r| r.field)
                .map(|f| f.form_fields)
                .unwrap_or_default();
            for fname in doc.form_field_names(&p) {
                if skip.fields.contains(&format!("{}#{}", p, fname)) {
                    continue;
                }
                let spec = specs.iter().find(|f| f.name == fname).cloned();
                if spec.as_ref().is_some_and(|s| {
                    s.derived_from.is_some()
                        || !s.count_of.is_empty()
                        || !s.product_of.is_empty()
                        || s.rank_of.as_deref().is_some_and(|r| !r.is_empty())
                }) {
                    continue;
                }
                let raw = doc.form_field_or(&p, &fname);
                let k = format!("f:{}#{}", self.key(doc, anchor, &p), fname);
                side.values.insert(
                    k,
                    SpecSetValue {
                        path: p.clone(),
                        field: fname.clone(),
                        value: spec_set_reviewed(&raw),
                        pending: spec_set_is_pending(&raw),
                        spec,
                    },
                );
            }
        }
        for p in doc.headline_paths() {
            if !under(&p) || outside(&p, &excluded) || skip.headlines.contains(&p) {
                continue;
            }
            let raw = doc.headline_or(&p);
            let k = format!("h:{}", self.key(doc, anchor, &p));
            side.values.insert(
                k,
                SpecSetValue {
                    path: p.clone(),
                    field: K_SPEC_HEADLINE_FIELD.to_string(),
                    value: spec_set_reviewed(&raw),
                    pending: spec_set_is_pending(&raw),
                    spec: None,
                },
            );
        }
        side
    }

    /// The path `key` stands for on `side`: the item paths it names as far as
    /// the side holds them; where it stops, the list an element would go in.
    fn path_on(side: &SpecSetSide, key: &str) -> String {
        if key.is_empty() {
            return side.anchor.clone();
        }
        let mut path = side.anchor.clone();
        let mut prefix = String::new();
        for s in key.split('/') {
            if prefix.is_empty() {
                prefix = s.to_string();
            } else {
                prefix = format!("{}/{}", prefix, s);
            }
            match s.find('[').filter(|b| *b > 0) {
                Some(bracket) => match side.items.get(&prefix) {
                    Some(item) => path = item.clone(),
                    None => return format!("{}/{}", path, &s[..bracket]),
                },
                None => path = format!("{}/{}", path, s),
            }
        }
        path
    }

    // --- one pair -------------------------------------------------------------

    /// Compares one pair, adding its findings at `order`.
    pub fn compare_pair(&mut self, pair: &SpecSyncPair, order: usize) {
        let set = self.set;
        let (bp_name, dt_name) = match (
            set.name_of(&set.blueprint_root),
            set.name_of(&pair.detail_root),
        ) {
            (Some(b), Some(d)) => (b, d),
            _ => return, // not started
        };
        let bp = &set.documents[&bp_name];
        let dt = &set.documents[&dt_name];
        let bp_root = set.blueprint_root.clone();

        let mut bp_anchors: HashMap<String, String> = HashMap::new();
        let mut key_order: Vec<String> = Vec::new();
        for a in self.expand(bp, &pair.blueprint_anchor) {
            let k = self.anchor_key(bp, &a);
            if !bp_anchors.contains_key(&k) {
                key_order.push(k.clone());
            }
            bp_anchors.insert(k, a);
        }
        let mut dt_anchors: HashMap<String, String> = HashMap::new();
        for a in self.expand(dt, &pair.detail_anchor) {
            let k = self.anchor_key(dt, &a);
            dt_anchors.insert(k, a);
        }
        // A pair the Phase 3 document has not written yet is not started,
        // never findings: it is what `prefill` fills, and `backfill` must not
        // take its emptiness for removals.
        if !dt_anchors.values().any(|a| dt.has_values_under(a)) {
            self.not_started_pairs.push(pair.section_id.clone());
            return;
        }
        // Nested pairs are compared on their own.
        let nested = |c: &Self, doc: &SpecDocument, blueprint_side: bool| -> Vec<String> {
            let mut out = Vec::new();
            for other in set.pairs() {
                if other != pair && (blueprint_side || other.detail_root == pair.detail_root) {
                    let anchor = if blueprint_side {
                        &other.blueprint_anchor
                    } else {
                        &other.detail_anchor
                    };
                    out.extend(c.expand(doc, anchor));
                }
            }
            out
        };
        let beneath = |all: &[String], anchor: &str| -> Vec<String> {
            let prefix = format!("{}/", anchor);
            all.iter()
                .filter(|p| p.starts_with(&prefix))
                .cloned()
                .collect()
        };
        let mut nested_done: Option<(Vec<String>, Vec<String>)> = None;
        for k in key_order {
            let ba = bp_anchors[&k].clone();
            let da = match dt_anchors.get(&k) {
                Some(a) => a.clone(),
                None => continue, // the outer list reports it
            };
            if nested_done.is_none() {
                nested_done = Some((nested(self, bp, true), nested(self, dt, false)));
            }
            let (bp_nested, dt_nested) = nested_done
                .as_ref()
                .map_or((Vec::new(), Vec::new()), |(b, d)| {
                    (beneath(b, &ba), beneath(d, &da))
                });
            let b = self.collect(&bp_name, bp, &bp_root, &ba, pair, &bp_nested);
            let d = self.collect(&dt_name, dt, &pair.detail_root, &da, pair, &dt_nested);
            self.compare(pair, order, Rc::new(b), Rc::new(d), bp, dt);
        }
    }

    fn side_place(
        &self,
        s: &SpecSetSide,
        key: &str,
        fld: &str,
        value: Option<String>,
    ) -> SpecSyncPlace {
        let mut out = SpecSyncPlace {
            document: Some(s.name.clone()),
            root: self.root_seg(&s.root),
            path: String::new(),
            field: fld.to_string(),
            value: value.clone(),
            pending_marks: false,
        };
        if let Some(v) = s.values.get(key) {
            out.path = v.path.clone();
            if fld.is_empty() {
                out.field = v.field.clone();
            }
            if value.is_none() {
                out.value = Some(v.value.clone());
            }
            out.pending_marks = v.pending;
        } else if let Some(rest) = key.strip_prefix("i:") {
            out.path = Self::path_on(s, rest);
        } else {
            out.path = Self::path_on(s, spec_set_strip_kind(key));
        }
        out
    }

    #[allow(clippy::too_many_arguments)]
    fn emit(
        &mut self,
        pair: &SpecSyncPair,
        order: usize,
        b: &Rc<SpecSetSide>,
        d: &Rc<SpecSetSide>,
        code: SpecSyncCode,
        key: &str,
        message: String,
        held_here: bool,
        fld: &str,
        b_value: Option<String>,
        d_value: Option<String>,
        resolution: Option<SpecSyncResolution>,
    ) {
        let holder = if held_here {
            SpecSyncHolder::Blueprint
        } else {
            SpecSyncHolder::Detail
        };
        let resolution = resolution.unwrap_or(if held_here {
            SpecSyncResolution::Agent
        } else {
            SpecSyncResolution::Backfill
        });
        let finding = SpecSyncFinding {
            code,
            pair: pair.section_id.clone(),
            blueprint: self.side_place(b, key, fld, b_value),
            detail: self.side_place(d, key, fld, d_value),
            holder,
            resolution,
            message,
        };
        self.add(
            order,
            key.to_string(),
            finding,
            Some(b.clone()),
            Some(d.clone()),
        );
    }

    fn compare(
        &mut self,
        pair: &SpecSyncPair,
        order: usize,
        b: Rc<SpecSetSide>,
        d: Rc<SpecSetSide>,
        bp: &SpecDocument,
        dt: &SpecDocument,
    ) {
        let refl = SpecReflection::new(self.set.model);
        // Relations: list key -> (relation, where); field key -> relation.
        let mut list_rel: HashMap<String, (String, String)> = HashMap::new();
        let mut field_rel: BTreeMap<String, String> = BTreeMap::new();
        let (relations, held_here_places) = match &pair.sync {
            Some(s) => (s.relations.clone(), s.held_here.clone()),
            None => (Vec::new(), Vec::new()),
        };
        for r in &relations {
            let res = match spec_resolve_place_at(&refl, &r.place, &b.anchor) {
                Some(res) => res,
                None => continue,
            };
            for p in self.expand(bp, &res.path) {
                let key = self.key(bp, &b.anchor, &p);
                match res.kind.as_str() {
                    SPEC_PLACE_KIND_LIST => {
                        list_rel.insert(key, (r.relation.clone(), r.r#where.clone()));
                    }
                    SPEC_PLACE_KIND_FORM_FIELD => {
                        field_rel.insert(format!("{}#{}", key, res.field()), r.relation.clone());
                    }
                    _ => {}
                }
            }
        }

        // A relation stated for a form field is the same for every element:
        // match it by its key with item ids dropped.
        let field_rel_by_shape: HashMap<String, String> = field_rel
            .iter()
            .map(|(k, v)| (set_shape(k), v.clone()))
            .collect();
        let held = self.places(bp, &held_here_places, &b.anchor);
        let is_held = |bp_path: &str, fld: &str| {
            set_under_any(bp_path, &held.prefixes)
                || (!fld.is_empty() && held.fields.contains(&format!("{}#{}", bp_path, fld)))
        };

        // Elements.
        let mut one_sided: Vec<String> = Vec::new();
        let item_keys: BTreeSet<String> = b.items.keys().chain(d.items.keys()).cloned().collect();
        for k in &item_keys {
            if k.is_empty() {
                continue;
            }
            let in_b = b.items.contains_key(k);
            let in_d = d.items.contains_key(k);
            if in_b == in_d {
                continue;
            }
            if one_sided.iter().any(|o| k.starts_with(&format!("{}/", o))) {
                continue;
            }
            one_sided.push(k.clone());
            // `LIST[ID]` (every item key, `key`); a key without the brackets
            // names its element by its last segment.
            let bracket = k.rfind('[');
            let parent_list = match bracket {
                Some(br) => k[..br].to_string(),
                None => k.rfind('/').map_or(String::new(), |s| k[..s].to_string()),
            };
            let rel = list_rel.get(&parent_list);
            let mut relation = rel.map_or("equal".to_string(), |r| r.0.clone());
            let (item_path, doc) = if in_b {
                (b.items[k].clone(), bp)
            } else {
                (d.items[k].clone(), dt)
            };
            if let Some((_, w)) = rel {
                if !w.is_empty() {
                    if let Some(flt) = SpecPlaceFilter::try_parse(w) {
                        if !flt.field.is_empty() {
                            let values = self.own_values(doc, &item_path, &flt.field);
                            if !flt.matches(&values) {
                                relation = "equal".to_string();
                            }
                        }
                    }
                }
            }
            let id = match bracket {
                Some(br) => k[br + 1..k.len() - 1].to_string(),
                None => k[k.rfind('/').map_or(0, |s| s + 1)..].to_string(),
            };
            let held_path = if in_b {
                item_path.clone()
            } else {
                Self::path_on(&b, k)
            };
            let held_here = is_held(&held_path, "");
            let key = format!("i:{}", k);
            if in_d && relation == "subset" {
                self.emit(
                    pair,
                    order,
                    &b,
                    &d,
                    SpecSyncCode::SharedElementMayBeAdded,
                    &key,
                    format!(
                        "{} is only in {}; under subset it may be added to {}",
                        id, d.name, b.name
                    ),
                    held_here,
                    "",
                    None,
                    Some(id.clone()),
                    Some(SpecSyncResolution::Info),
                );
            } else if in_d {
                self.emit(
                    pair,
                    order,
                    &b,
                    &d,
                    SpecSyncCode::SharedElementMissing,
                    &key,
                    format!("{} is in {} and missing in {}", id, d.name, b.name),
                    held_here,
                    "",
                    None,
                    Some(id.clone()),
                    None,
                );
            } else if relation != "superset" {
                self.emit(
                    pair,
                    order,
                    &b,
                    &d,
                    SpecSyncCode::SharedElementOnlyInBlueprint,
                    &key,
                    format!("{} is only in {}; {} removed it", id, b.name, d.name),
                    held_here,
                    "",
                    Some(id.clone()),
                    None,
                    None,
                );
            }
        }

        let beneath_one_sided = |key: &str| {
            let rel = spec_set_strip_kind(key);
            one_sided
                .iter()
                .any(|o| rel == o || rel.starts_with(&format!("{}/", o)))
        };
        let non_empty = |s: &str| {
            if s.is_empty() {
                None
            } else {
                Some(s.to_string())
            }
        };

        // Values.
        let value_keys: BTreeSet<String> =
            b.values.keys().chain(d.values.keys()).cloned().collect();
        for k in &value_keys {
            if beneath_one_sided(k) {
                continue;
            }
            let vb = b.values.get(k);
            let vd = d.values.get(k);
            let mut spec: Option<FormFieldSpec> = None;
            let mut fld = String::new();
            let mut b_value = String::new();
            let mut d_value = String::new();
            if let Some(vb) = vb {
                spec = vb.spec.clone();
                fld = vb.field.clone();
                b_value = vb.value.clone();
            }
            if let Some(vd) = vd {
                if spec.is_none() {
                    spec = vd.spec.clone();
                }
                if fld.is_empty() {
                    fld = vd.field.clone();
                }
                d_value = vd.value.clone();
            }
            let held_path = match vb {
                Some(vb) => vb.path.clone(),
                None => Self::path_on(&b, spec_set_strip_kind(k)),
            };
            let held_here = is_held(&held_path, &fld);
            if spec
                .as_ref()
                .is_some_and(|s| s.multiple && !s.refers_to.is_empty())
            {
                let relation = field_rel_by_shape
                    .get(&set_shape(&k[2..]))
                    .cloned()
                    .unwrap_or_else(|| "equal".to_string());
                let ib = spec_link_ids(&b_value);
                let idd = spec_link_ids(&d_value);
                for x in set_sorted_minus(&idd, &ib) {
                    let (code, resolution) = if relation == "subset" {
                        (
                            SpecSyncCode::SharedElementMayBeAdded,
                            Some(SpecSyncResolution::Info),
                        )
                    } else {
                        (SpecSyncCode::SharedElementMissing, None)
                    };
                    self.emit(
                        pair,
                        order,
                        &b,
                        &d,
                        code,
                        k,
                        format!("{} is named in {} and not in {}", x, d.name, b.name),
                        held_here,
                        &fld,
                        non_empty(&b_value),
                        Some(x.clone()),
                        resolution,
                    );
                }
                if relation != "superset" {
                    for x in set_sorted_minus(&ib, &idd) {
                        self.emit(
                            pair,
                            order,
                            &b,
                            &d,
                            SpecSyncCode::SharedElementOnlyInBlueprint,
                            k,
                            format!("{} is named only in {}", x, b.name),
                            held_here,
                            &fld,
                            Some(x.clone()),
                            non_empty(&d_value),
                            None,
                        );
                    }
                }
                continue;
            }
            if b_value.is_empty() && d_value.is_empty() {
                continue;
            }
            if spec_set_same_typed(&b_value, &d_value, spec.as_ref()) {
                continue;
            }
            let what = if fld.is_empty() {
                "the value".to_string()
            } else {
                format!("form field \"{}\"", fld)
            };
            let (code, message) = if b_value.is_empty() {
                (
                    SpecSyncCode::SharedValueMissing,
                    format!("{} is filled in {} and empty in {}", what, d.name, b.name),
                )
            } else if d_value.is_empty() {
                (
                    SpecSyncCode::SharedValueOnlyInBlueprint,
                    format!(
                        "{} is filled only in {}; {} emptied it",
                        what, b.name, d.name
                    ),
                )
            } else {
                let mut message = format!(
                    "{} differs: \"{}\" in {}, \"{}\" in {}",
                    what, b_value, b.name, d_value, d.name
                );
                if held_here {
                    message.push_str(&format!(" (held in {})", b.name));
                }
                (SpecSyncCode::SharedValueDiffers, message)
            };
            self.emit(
                pair, order, &b, &d, code, k, message, held_here, &fld, None, None, None,
            );
        }
    }

    /// The values a row's own forms (`<row>/<member>`) hold in `fld`.
    fn own_values(&mut self, doc: &SpecDocument, row: &str, fld: &str) -> Vec<String> {
        let index = self.forms.entry(doc_key(doc)).or_insert_with(|| {
            let mut index: HashMap<String, Vec<String>> = HashMap::new();
            for p in doc.form_paths() {
                if let Some(slash) = p.rfind('/').filter(|s| *s > 0) {
                    index
                        .entry(p[..slash].to_string())
                        .or_default()
                        .push(p.clone());
                }
            }
            index
        });
        index
            .get(row)
            .map(|forms| {
                forms
                    .iter()
                    .filter_map(|p| doc.form_field(p, fld).map(|v| spec_set_reviewed(v)))
                    .collect()
            })
            .unwrap_or_default()
    }

    // --- unmarkable derived changes ------------------------------------------

    /// Lists every change `deriveFields` would write in a document under
    /// review that cannot be marked exactly: left for the agent.
    fn unmarkable_scan(&mut self, order: usize) {
        let set = self.set;
        for name in set.names() {
            let doc = &set.documents[&name];
            let root = self.root_seg(&set.root_of(&name));
            let derived = derive_fields_dry_run(
                set.model,
                doc,
                &SpecDeriveOptions {
                    marked: true,
                    ..SpecDeriveOptions::default()
                },
            );
            for u in derived.unresolved {
                if u.code != SPEC_VALIDATION_CODE_UNMARKABLE {
                    continue;
                }
                let p = SpecSyncPlace {
                    document: Some(name.clone()),
                    root: root.clone(),
                    path: u.path.clone(),
                    ..SpecSyncPlace::default()
                };
                self.add(
                    order,
                    format!("{} {}", name, u.path),
                    SpecSyncFinding {
                        code: SpecSyncCode::Unmarkable,
                        pair: String::new(),
                        blueprint: p.clone(),
                        detail: p,
                        holder: SpecSyncHolder::Detail,
                        resolution: SpecSyncResolution::Agent,
                        message: format!("{} (in {})", u.message, name),
                    },
                    None,
                    None,
                );
            }
        }
    }

    // --- pending marks --------------------------------------------------------

    /// Lists every value of every document that holds pending change marks.
    fn pending_scan(&mut self, order: usize) {
        let set = self.set;
        for name in set.names() {
            let doc = &set.documents[&name];
            let root = self.root_seg(&set.root_of(&name));
            let mut values: Vec<(String, String, String)> = Vec::new();
            for p in doc.content_paths() {
                values.push((p.clone(), String::new(), doc.content_or(&p)));
            }
            for p in doc.form_paths() {
                for f in doc.form_field_names(&p) {
                    let raw = doc.form_field_or(&p, &f);
                    values.push((p.clone(), f, raw));
                }
            }
            for p in doc.headline_paths() {
                values.push((p.clone(), String::new(), doc.headline_or(&p)));
            }
            for (path, fld, raw) in values {
                if !spec_set_is_pending(&raw) {
                    continue;
                }
                let p = SpecSyncPlace {
                    document: Some(name.clone()),
                    root: root.clone(),
                    path: path.clone(),
                    field: fld.clone(),
                    value: Some(spec_set_reviewed(&raw)),
                    pending_marks: true,
                };
                let what = if fld.is_empty() {
                    "the value".to_string()
                } else {
                    format!("form field \"{}\"", fld)
                };
                self.add(
                    order,
                    format!("{} {} {}", name, path, fld),
                    SpecSyncFinding {
                        code: SpecSyncCode::PendingReview,
                        pair: String::new(),
                        blueprint: p.clone(),
                        detail: p,
                        holder: SpecSyncHolder::Detail,
                        resolution: SpecSyncResolution::Info,
                        message: format!(
                            "{} at {} in {} holds pending change marks",
                            what, path, name
                        ),
                    },
                    None,
                    None,
                );
            }
        }
    }

    // --- links across two documents ----------------------------------------------

    /// Every class instance of a document of root `type_name`: path and class.
    fn instances(&self, doc: &SpecDocument, type_name: &str) -> Vec<SetInstance<'m>> {
        let refl = SpecReflection::new(self.set.model);
        let mut out = Vec::new();
        if let Some(cls) = self.set.model.class_named(type_name) {
            let root = self.root_seg(type_name);
            set_walk_instances(&refl, doc, cls, &root, &HashSet::new(), &mut out);
        }
        out
    }

    /// The document a registry class is read in: the one whose root details
    /// it (a populated root other than the Blueprint's that reaches it), else
    /// the Blueprint (`""` for none).
    fn registry_document(&mut self, section_id: &str) -> String {
        if let Some(hit) = self.registry_docs.get(section_id) {
            return hit.clone();
        }
        let hit = self.compute_registry_document(section_id);
        self.registry_docs
            .insert(section_id.to_string(), hit.clone());
        hit
    }

    fn compute_registry_document(&mut self, section_id: &str) -> String {
        let classes: HashSet<&str> = self
            .set
            .model
            .classes
            .values()
            .filter(|c| c.section_id == section_id)
            .map(|c| c.name.as_str())
            .collect();
        let mut blueprint = String::new();
        for name in self.set.names() {
            let root = self.set.root_of(&name);
            if !self.reach.contains_key(&root) {
                let reach = self.refl.reachable_class_names(&root);
                self.reach.insert(root.clone(), reach);
            }
            if !self.reach[&root]
                .iter()
                .any(|r| classes.contains(r.as_str()))
            {
                continue;
            }
            if root == self.set.blueprint_root {
                blueprint = name;
            } else {
                return name;
            }
        }
        blueprint
    }

    fn identity(&mut self, doc: &SpecDocument, item: &str, target: &str) -> Option<String> {
        let fld = &target[target.find('.').map_or(0, |d| d + 1)..];
        if fld == K_SECTION_ID_SLOT {
            return Some(self.item_id(doc, item));
        }
        self.own_values(doc, item, fld).into_iter().next()
    }

    /// The entry of `doc` that `refers_to` names `id` by, `None` when none.
    fn entry(&mut self, doc: &SpecDocument, refers_to: &[String], id: &str) -> Option<String> {
        let dk = doc_key(doc);
        for t in refers_to {
            let cached = self.entries.get(&dk).and_then(|m| m.get(t)).is_some();
            if !cached {
                let mut index: HashMap<String, String> = HashMap::new();
                let sid = t.split('.').next().unwrap_or("");
                for lst in doc.list_paths() {
                    for item in doc.list_items(&lst) {
                        let ok = self
                            .refl
                            .resolve(&item)
                            .and_then(|r| r.target_class)
                            .is_some_and(|c| c.section_id == sid);
                        if !ok {
                            continue;
                        }
                        if let Some(name) = self.identity(doc, &item, t) {
                            index.entry(name).or_insert(item.clone());
                        }
                    }
                }
                self.entries.entry(dk).or_default().insert(t.clone(), index);
            }
            if let Some(hit) = self.entries[&dk][t].get(id) {
                return Some(hit.clone());
            }
        }
        None
    }

    fn nearest_item(&mut self, path: &str) -> Option<String> {
        let mut p = path.to_string();
        loop {
            if self.is_item(&p) {
                return Some(p);
            }
            let slash = p.rfind('/')?;
            p.truncate(slash);
        }
    }

    /// Adds the findings of the links across two documents, summaries and
    /// inverses, at `order`; `pairs` (`Some`) keeps those of the classes with
    /// those section ids.
    pub fn cross_checks(&mut self, pairs: Option<&HashSet<String>>, order: usize) {
        let set = self.set;
        for name in set.names() {
            let doc = &set.documents[&name];
            let root = set.root_of(&name);
            for inst in self.instances(doc, &root) {
                let pair_id = if inst.cls.section_id.is_empty() {
                    inst.cls.name.clone()
                } else {
                    inst.cls.section_id.clone()
                };
                if pairs.is_some_and(|p| !p.contains(&pair_id)) {
                    continue;
                }
                for f in &inst.cls.fields {
                    let member = format!("{}/{}", inst.path, self.refl.field_segment(f));
                    if let Some(s) = f.summary_of() {
                        if !s.document.is_empty() && f.kind == SPEC_FIELD_KIND_LIST {
                            self.cross_summary_rows(order, &pair_id, &name, doc, &member, &s);
                        }
                    }
                    for ff in &f.form_fields {
                        if ff
                            .summary_of
                            .as_ref()
                            .is_some_and(|s| !s.document.is_empty())
                        {
                            self.cross_summary_field(order, &pair_id, &name, doc, &member, ff);
                        }
                        if ff.inverse_of.as_ref().is_some_and(|i| !i.symmetric()) {
                            self.cross_inverse(order, &pair_id, &name, doc, &member, ff);
                        }
                    }
                }
            }
        }
    }

    /// The detail elements of a cross summary: document name, document,
    /// elements; `None` when the detail is not started or does not resolve.
    fn cross_detail(
        &mut self,
        s: &SpecSummaryOf,
    ) -> Option<(String, &'s SpecDocument, Vec<SetElement>)> {
        let set = self.set;
        let name = set.name_of(&s.document)?; // not started
        let doc = &set.documents[&name];
        let seg = self.root_seg(&set.root_of(&name));
        let r: Option<SpecPlaceResolution> = match s.detail.find('/') {
            None => spec_resolve_place_at(&self.refl, &s.detail, &seg),
            Some(slash) => {
                let head = spec_resolve_place_at(&self.refl, &s.detail[..slash], &seg)?;
                let scope = if head.kind == SPEC_PLACE_KIND_LIST {
                    format!("{}-*", head.path)
                } else {
                    head.path.clone()
                };
                let concrete = self.expand(doc, &scope);
                if concrete.is_empty() {
                    None
                } else {
                    let p = SpecPlace::parse(&s.detail[slash + 1..]).ok()?;
                    Some(p.resolve(&self.refl, &concrete[0]).ok()?)
                }
            }
        };
        let r = r.filter(|r| r.kind == SPEC_PLACE_KIND_LIST)?;
        let mut elements: Vec<SetElement> = Vec::new();
        let mut seen: HashMap<String, usize> = HashMap::new();
        for lst in self.expand(doc, &r.path) {
            for item in doc.list_items(&lst) {
                let id = self.item_id(doc, &item);
                if let Some(at) = seen.get(&item) {
                    elements[*at] = SetElement { item, id };
                    continue;
                }
                seen.insert(item.clone(), elements.len());
                elements.push(SetElement { item, id });
            }
        }
        Some((name, doc, elements))
    }

    fn place_of(&self, name: &str, path: &str, fld: &str, value: Option<String>) -> SpecSyncPlace {
        let root = if name.is_empty() {
            String::new()
        } else {
            self.root_seg(&self.set.root_of(name))
        };
        SpecSyncPlace {
            document: if name.is_empty() {
                None
            } else {
                Some(name.to_string())
            },
            root,
            path: path.to_string(),
            field: fld.to_string(),
            value,
            pending_marks: false,
        }
    }

    fn cross(
        &mut self,
        order: usize,
        code: SpecSyncCode,
        pair: &str,
        here: SpecSyncPlace,
        there: SpecSyncPlace,
        message: String,
    ) {
        let document = here.document.clone().unwrap_or_else(|| "None".to_string());
        let key = format!(
            "{} {} {} {}",
            document,
            here.path,
            here.field,
            there.value_or()
        );
        self.add(
            order,
            key,
            SpecSyncFinding {
                code,
                pair: pair.to_string(),
                blueprint: here,
                detail: there,
                holder: SpecSyncHolder::Detail,
                resolution: SpecSyncResolution::Agent,
                message,
            },
            None,
            None,
        );
    }

    #[allow(clippy::too_many_arguments)]
    fn cross_summary_rows(
        &mut self,
        order: usize,
        pair: &str,
        name: &str,
        doc: &SpecDocument,
        lst: &str,
        s: &SpecSummaryOf,
    ) {
        let (d_name, d_doc, elements) = match self.cross_detail(s) {
            Some(x) => x,
            None => return,
        };
        let by_id: HashMap<&str, &str> = elements
            .iter()
            .map(|e| (e.id.as_str(), e.item.as_str()))
            .collect();
        let list_of = set_list_of(&elements);
        let mut named: HashMap<String, String> = HashMap::new();
        for row in doc.list_items(lst) {
            let ids = if s.r#match.is_empty() {
                vec![self.item_id(doc, &row)]
            } else {
                self.match_ids(doc, &s.r#match, &row)
            };
            for id in ids {
                let target = match by_id.get(id.as_str()) {
                    Some(t) => t.to_string(),
                    None => {
                        let here = self.place_of(name, &row, "", Some(id.clone()));
                        let there = self.place_of(&d_name, &list_of, "", Some(id.clone()));
                        self.cross(
                            order,
                            SpecSyncCode::CrossSummaryMismatch,
                            pair,
                            here,
                            there,
                            format!(
                                "the summary row names {}, which is no element of {} in {}",
                                id, s.detail, d_name
                            ),
                        );
                        continue;
                    }
                };
                if let Some(prev) = named.get(&id).cloned() {
                    let here = self.place_of(name, &row, "", Some(id.clone()));
                    let there = self.place_of(&d_name, &target, "", Some(id.clone()));
                    self.cross(
                        order,
                        SpecSyncCode::CrossSummaryMismatch,
                        pair,
                        here,
                        there,
                        format!("the summary row names {}, which {} names already", id, prev),
                    );
                    continue;
                }
                named.insert(id.clone(), row.clone());
                for rp in &s.repeats {
                    let mine = self.value_at(doc, &rp.0, &row);
                    let theirs = self.value_at(d_doc, &rp.1, &target);
                    let (mine, theirs) = match (mine, theirs) {
                        (Some(m), Some(t)) if !m.value.is_empty() => (m, t),
                        _ => continue,
                    };
                    if mine.value != theirs.value {
                        let here =
                            self.place_of(name, &mine.path, &mine.field, Some(mine.value.clone()));
                        let there = self.place_of(
                            &d_name,
                            &theirs.path,
                            &theirs.field,
                            Some(theirs.value.clone()),
                        );
                        self.cross(
                            order,
                            SpecSyncCode::CrossSummaryMismatch,
                            pair,
                            here,
                            there,
                            format!(
                                "{} repeats {} of {} as \"{}\", but {} holds \"{}\"",
                                rp.0, rp.1, id, mine.value, d_name, theirs.value
                            ),
                        );
                    }
                }
            }
        }
        if s.relation == "equal" {
            for e in &elements {
                if named.contains_key(&e.id) {
                    continue;
                }
                let here = self.place_of(name, lst, "", None);
                let there = self.place_of(&d_name, &e.item, "", Some(e.id.clone()));
                self.cross(
                    order,
                    SpecSyncCode::CrossSummaryMismatch,
                    pair,
                    here,
                    there,
                    format!(
                        "the detail element {} of {} is named by no row of {} (relation: equal)",
                        e.id, d_name, lst
                    ),
                );
            }
        }
    }

    fn match_ids(&mut self, doc: &SpecDocument, place: &str, row: &str) -> Vec<String> {
        match self.value_at(doc, place, row) {
            Some(v) => spec_link_ids(&v.value),
            None => Vec::new(),
        }
    }

    /// The value of `place` under the concrete `anchor`.
    fn value_at(&mut self, doc: &SpecDocument, place: &str, anchor: &str) -> Option<SetValueAt> {
        let r = spec_resolve_place_at(&self.refl, place, anchor)?;
        let paths = self.expand(doc, &r.path);
        if paths.len() != 1 {
            return None;
        }
        let p = paths[0].clone();
        let raw = match r.kind.as_str() {
            SPEC_PLACE_KIND_FORM_FIELD => doc.form_field_or(&p, r.field()),
            SPEC_PLACE_KIND_CONTENT => doc.content_or(&p),
            SPEC_PLACE_KIND_HEADLINE => doc.headline_or(&p),
            SPEC_PLACE_KIND_SECTION_ID if self.is_item(&p) => self.item_id(doc, &p),
            _ => String::new(),
        };
        Some(SetValueAt {
            path: p,
            value: spec_set_reviewed(&raw),
            field: r.field().to_string(),
        })
    }

    #[allow(clippy::too_many_arguments)]
    fn cross_summary_field(
        &mut self,
        order: usize,
        pair: &str,
        name: &str,
        doc: &SpecDocument,
        form: &str,
        ff: &FormFieldSpec,
    ) {
        let raw = match doc.form_field(form, &ff.name) {
            Some(r) => r.clone(),
            None => return,
        };
        let s = match &ff.summary_of {
            Some(s) => s,
            None => return,
        };
        let (d_name, _, elements) = match self.cross_detail(s) {
            Some(x) => x,
            None => return,
        };
        let known: HashSet<&str> = elements.iter().map(|e| e.id.as_str()).collect();
        let list_of = set_list_of(&elements);
        let mut seen: HashSet<String> = HashSet::new();
        for id in spec_link_ids(&spec_set_reviewed(&raw)) {
            let fresh = seen.insert(id.clone());
            let is_known = known.contains(id.as_str());
            if !is_known || !fresh {
                let message = if is_known {
                    format!("form field \"{}\" names {} twice", ff.name, id)
                } else {
                    format!(
                        "form field \"{}\" names {}, which is no element of {} in {}",
                        ff.name, id, s.detail, d_name
                    )
                };
                let here = self.place_of(name, form, &ff.name, Some(id.clone()));
                let there = self.place_of(&d_name, &list_of, "", Some(id.clone()));
                self.cross(
                    order,
                    SpecSyncCode::CrossSummaryMismatch,
                    pair,
                    here,
                    there,
                    message,
                );
            }
        }
        if s.relation == "equal" {
            for e in &elements {
                if seen.contains(&e.id) {
                    continue;
                }
                let here = self.place_of(name, form, &ff.name, None);
                let there = self.place_of(&d_name, &e.item, "", Some(e.id.clone()));
                self.cross(
                    order,
                    SpecSyncCode::CrossSummaryMismatch,
                    pair,
                    here,
                    there,
                    format!(
                        "the detail element {} of {} is not named in \"{}\" (relation: equal)",
                        e.id, d_name, ff.name
                    ),
                );
            }
        }
    }

    fn sid_of(&self, p: &str) -> String {
        self.refl
            .resolve(p)
            .and_then(|r| r.target_class)
            .map(|c| c.section_id)
            .unwrap_or_default()
    }

    #[allow(clippy::too_many_arguments)]
    fn cross_inverse(
        &mut self,
        order: usize,
        pair: &str,
        name: &str,
        doc: &SpecDocument,
        form: &str,
        ff: &FormFieldSpec,
    ) {
        let raw = match doc.form_field(form, &ff.name) {
            Some(r) => r.clone(),
            None => return,
        };
        let value = spec_set_reviewed(&raw);
        if value.is_empty() {
            return;
        }
        let inv = match &ff.inverse_of {
            Some(i) => i,
            None => return,
        };
        let set = self.set;
        for b in spec_link_ids(&value) {
            // The document the named entry is read in.
            let mut registries: Vec<String> = Vec::new();
            for t in &ff.refers_to {
                let r = t.split('.').next().unwrap_or("").to_string();
                if !registries.contains(&r) {
                    registries.push(r);
                }
            }
            for registry in &registries {
                let other = self.registry_document(registry);
                if other.is_empty() || other == name {
                    continue;
                }
                let o_doc = &set.documents[&other];
                let targets: Vec<String> = ff
                    .refers_to
                    .iter()
                    .filter(|t| t.split('.').next() == Some(registry.as_str()))
                    .cloned()
                    .collect();
                let b_path = match self.entry(o_doc, &targets, &b) {
                    Some(p) => p,
                    None => continue,
                };
                for end in &inv.fields {
                    let r = match spec_resolve_place_at(&self.refl, end, &b_path) {
                        Some(r) => r,
                        None => continue,
                    };
                    let end_ff = match &r.form_field {
                        Some(f) => f.clone(),
                        None => continue,
                    };
                    // This field's entry, named as the other end names it, and
                    // read in its own registry document only.
                    let a_classes: HashSet<String> = end_ff
                        .refers_to
                        .iter()
                        .map(|t| t.split('.').next().unwrap_or("").to_string())
                        .collect();
                    let mut a = self.nearest_item(form);
                    while let Some(cur) = a.clone() {
                        if a_classes.contains(&self.sid_of(&cur)) {
                            break;
                        }
                        a = match cur.rfind('/') {
                            Some(slash) => self.nearest_item(&cur[..slash]),
                            None => None,
                        };
                    }
                    let a = match a {
                        Some(a) => a,
                        None => continue,
                    };
                    let a_sid = self.sid_of(&a);
                    if self.registry_document(&a_sid) != name {
                        continue;
                    }
                    let mut a_id: Option<String> = None;
                    for t in &end_ff.refers_to {
                        if let Some(v) = self.identity(doc, &a, t) {
                            a_id = Some(v);
                            break;
                        }
                    }
                    let a_id = match a_id {
                        Some(v) => v,
                        None => continue,
                    };
                    let ends = self.expand(o_doc, &r.path);
                    let fld = r.field().to_string();
                    let names_back = ends.iter().any(|p| {
                        spec_link_ids(&spec_set_reviewed(&o_doc.form_field_or(p, &fld)))
                            .contains(&a_id)
                    });
                    if !names_back {
                        let end_path = ends.first().cloned().unwrap_or_else(|| b_path.clone());
                        let here = self.place_of(name, form, &ff.name, Some(b.clone()));
                        let there = self.place_of(&other, &end_path, &fld, Some(a_id.clone()));
                        self.cross(
                            order,
                            SpecSyncCode::CrossInverseMissing,
                            pair,
                            here,
                            there,
                            format!(
                                "form field \"{}\" in {} names {}, but {} in {} does not name {} back ({})",
                                ff.name,
                                name,
                                b,
                                b,
                                other,
                                a_id,
                                inv.fields.join(", ")
                            ),
                        );
                    }
                }
            }
        }
    }
}

/// Walks the class instances of `doc` beneath `path` (of class `cls`).
fn set_walk_instances<'m>(
    refl: &SpecReflection<'m>,
    doc: &SpecDocument,
    cls: &'m SpecClass,
    path: &str,
    on_path: &HashSet<String>,
    out: &mut Vec<SetInstance<'m>>,
) {
    out.push(SetInstance {
        path: path.to_string(),
        cls,
    });
    for f in &cls.fields {
        if f.has_annotation("Reference") {
            continue;
        }
        let member = format!("{}/{}", path, refl.field_segment(f));
        if f.kind == SPEC_FIELD_KIND_LIST && f.element_is_complex {
            let el = match refl.model.class_named(&f.element_type) {
                Some(el) => el,
                None => continue,
            };
            for item in doc.list_items(&member) {
                set_walk_instances(refl, doc, el, &item, &HashSet::new(), out);
            }
        } else if f.kind == SPEC_FIELD_KIND_COMPLEX || f.kind == SPEC_FIELD_KIND_SECTION {
            let child = match refl.model.class_named(&f.type_.replace('?', "")) {
                Some(c) if !on_path.contains(&c.name) => c,
                _ => continue,
            };
            let mut next = on_path.clone();
            next.insert(cls.name.clone());
            set_walk_instances(refl, doc, child, &member, &next, out);
        }
    }
}

fn set_list_of(elements: &[SetElement]) -> String {
    match elements.first() {
        Some(e) => e.item[..e.item.rfind('-').unwrap_or(e.item.len())].to_string(),
        None => String::new(),
    }
}

// --- the global rename ----------------------------------------------------------

/// Why [`rename_id`] refuses.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecRenameError {
    /// The documents already holding the new id.
    pub documents: Vec<String>,
    /// The prose for the reader.
    pub message: String,
}

impl std::fmt::Display for SpecRenameError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SpecRenameError: {}", self.message)
    }
}

impl std::error::Error for SpecRenameError {}

/// One value [`rename_id`] changed.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecRenameChange {
    /// The document's name.
    pub document: String,
    /// A list item (its section id) or the value's path.
    pub path: String,
    /// `sectionId` or `value` (a form field or content).
    pub kind: String,
    /// The value before.
    pub old_value: String,
    /// The value after.
    pub new_value: String,
    /// The form field, `""` for none.
    pub field: String,
}

impl SpecRenameChange {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("document", set_jstr(&self.document)),
            ("path", set_jstr(&self.path)),
            ("kind", set_jstr(&self.kind)),
            ("old", set_jstr(&self.old_value)),
            ("new", set_jstr(&self.new_value)),
        ];
        if !self.field.is_empty() {
            out.push(("field", set_jstr(&self.field)));
        }
        set_jobj(out)
    }
}

fn set_all_items(doc: &SpecDocument) -> Vec<String> {
    doc.list_paths()
        .iter()
        .flat_map(|lst| doc.list_items(lst))
        .collect()
}

/// Whether `b` belongs to an id (letters, digits, hyphens).
fn set_id_byte(b: u8) -> bool {
    b == b'-' || b.is_ascii_alphanumeric()
}

/// Every whole-token occurrence of `from` in `v` replaced with `to` (no
/// letter, digit or hyphen on either side); `None` when there is none.
fn set_replace_token(v: &str, from: &str, to: &str) -> Option<String> {
    if from.is_empty() {
        return None;
    }
    let bytes = v.as_bytes();
    let fb = from.as_bytes();
    let mut out: Vec<u8> = Vec::with_capacity(v.len());
    let mut found = false;
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i..].starts_with(fb)
            && (i == 0 || !set_id_byte(bytes[i - 1]))
            && (i + fb.len() >= bytes.len() || !set_id_byte(bytes[i + fb.len()]))
        {
            out.extend_from_slice(to.as_bytes());
            i += fb.len();
            found = true;
            continue;
        }
        out.push(bytes[i]);
        i += 1;
    }
    if found {
        Some(String::from_utf8(out).unwrap_or_else(|_| v.to_string()))
    } else {
        None
    }
}

/// Renames the section id `from` to `to` in every document of `set` at once
/// (DP-part-cleanup-2): the list element carrying it, and every value naming
/// it as a whole token (references, comma-separated lists, the texts link
/// rows are extracted from). Refused with a [`SpecRenameError`], nothing
/// changed, when an element of any document already carries `to`. Returns the
/// changes, in document and path order.
pub fn rename_id(
    set: &mut SpecDocumentSet<'_>,
    from: &str,
    to: &str,
) -> Result<Vec<SpecRenameChange>, SpecRenameError> {
    let refl = set.refl();
    let names = set.names();
    // The effective ids, read before anything changes.
    let mut ids: HashMap<(String, String), String> = HashMap::new();
    let mut holders: Vec<String> = Vec::new();
    for name in &names {
        let doc = &set.documents[name];
        let mut holds = false;
        for item in set_all_items(doc) {
            let id = set_effective_item_id(&refl, doc, &item);
            holds = holds || id == to;
            ids.insert((name.clone(), item), id);
        }
        if holds {
            holders.push(name.clone());
        }
    }
    if !holders.is_empty() {
        return Err(SpecRenameError {
            message: format!("{} is already an id in {}", to, holders.join(", ")),
            documents: holders,
        });
    }
    let mut changes = Vec::new();
    for name in &names {
        let doc = match set.documents.get_mut(name) {
            Some(d) => d,
            None => continue,
        };
        for item in set_all_items(doc) {
            if ids.get(&(name.clone(), item.clone())).map(String::as_str) != Some(from) {
                continue;
            }
            if doc.set_item_section_id(&item, to).is_err() {
                return Ok(changes);
            }
            changes.push(SpecRenameChange {
                document: name.clone(),
                path: item,
                kind: "sectionId".to_string(),
                old_value: from.to_string(),
                new_value: to.to_string(),
                field: String::new(),
            });
        }
        for p in doc.content_paths() {
            let v = doc.content_or(&p);
            if let Some(n) = set_replace_token(&v, from, to) {
                doc.set_content(&p, &n);
                changes.push(SpecRenameChange {
                    document: name.clone(),
                    path: p,
                    kind: "value".to_string(),
                    old_value: v,
                    new_value: n,
                    field: String::new(),
                });
            }
        }
        for p in doc.form_paths() {
            for f in doc.form_field_names(&p) {
                let v = doc.form_field_or(&p, &f);
                if let Some(n) = set_replace_token(&v, from, to) {
                    doc.set_form_field(&p, &f, &n);
                    changes.push(SpecRenameChange {
                        document: name.clone(),
                        path: p.clone(),
                        kind: "value".to_string(),
                        old_value: v,
                        new_value: n,
                        field: f,
                    });
                }
            }
        }
    }
    Ok(changes)
}
