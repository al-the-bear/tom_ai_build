//! `spec_query` — lexical/structural query + lazy cursor over a live
//! [`SpecDocument`] (`llm_and_d4rt_tools.md` §6,
//! `som_multiplatform_spec_model.md` §15), a faithful port of the Dart
//! `spec_query.dart`.
//!
//! This is the **grep-like** facility the downstream D4rt scripting layer and
//! the editor's search tools reuse. It is **embedding-free** — exact substring
//! or [`SomTextPattern`] match plus structural filters — so it is always current
//! and needs no model calls.
//!
//! A [`SpecQuery`] composes (AND-combined) over five dimensions:
//!   * **text** — substring or [`SomTextPattern`] over content + form-field
//!     values and over a node's headline, stored or doc-comment (optionally
//!     case-insensitive);
//!   * **kind** — one or more node kinds (the
//!     [`SPEC_NODE_KIND_*`](crate::spec_reflection) constants);
//!   * **class** — the model class a node *is* (by class name);
//!   * **id / path** — exact `@SectionId`, `@SectionId` prefix, path glob, or a
//!     `@MapsTo` / `@DetailedIn` target on the node's class;
//!   * **state** — empty / non-empty (the structural "empty = no value" test).
//!
//! [`SpecQueryEngine::query`] returns a [`SpecQueryCursor`] the caller iterates
//! lazily (`next` / `take` / `count`). The cursor captures the **structural**
//! candidate set when it is created, then **re-validates each path against the
//! live document on every step** — so a result whose list-item ancestor was
//! removed after the cursor was made is silently skipped (stable against
//! concurrent edits, llm_and_d4rt_tools.md §6).
//!
//! ## Rust deviations from the reference
//!
//! Two, both forced by the language and neither of them semantic:
//!
//!   * **The cursor does not hold the engine.** Dart's cursor keeps a reference
//!     to the engine and re-reads the *mutating* document through it; Rust
//!     cannot hold a shared borrow of a document that is about to be mutated.
//!     So the cursor holds only its own captured state and every stepping method
//!     takes `engine: &SpecQueryEngine<'_, '_>`. Re-validation still happens per
//!     step against whatever the document says *now*, which is the behaviour the
//!     corpus pins; the borrow is simply made explicit at the call, exactly as
//!     [`SpecEditor`](crate::spec_editor) makes its exclusive access explicit.
//!   * **Absent dimensions are `Option`, not `""`.** Elsewhere in this crate an
//!     empty string is the model's "absent" sentinel, but here `text: Some("")`
//!     and `section_id_prefix: Some("")` are meaningful queries distinct from
//!     unset — and the corpus contract is explicitly that an absent key means
//!     "dimension unset", never a default that happens to match.
//!
//! One rule is worth naming here even though it is **not** a deviation:
//! form-field values are read in **model-declaration order** (SOM §9,
//! "Form-field order"), never in the store's. It bites hardest in this crate,
//! whose store is a `BTreeMap`: `form_field_names` yields alphabetical order, so
//! a walk that followed it would report a different snippet sequence from every
//! other runtime for the same values. The walk goes through
//! [`SpecSerializationOrder::order_form_fields`].
//!
//! Compiling a pattern can fail, so [`SpecQueryEngine::query`] returns
//! `Result<_, SomPatternError>` where the Dart reference throws.

use std::collections::BTreeSet;

use crate::spec_document::SpecDocument;
use crate::spec_model::{
    SpecClass, SpecModel, SPEC_FIELD_KIND_COMPLEX, SPEC_FIELD_KIND_CONTENT, SPEC_FIELD_KIND_ENUM,
    SPEC_FIELD_KIND_FORM, SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SCALAR, SPEC_FIELD_KIND_SECTION,
};
use crate::spec_paths::{spec_path_join, spec_path_segments, split_list_item_segment};
use crate::spec_reflection::{
    SpecReflection, SpecResolution, SPEC_NODE_KIND_CONTENT, SPEC_NODE_KIND_ENUM_VALUE,
    SPEC_NODE_KIND_FORM, SPEC_NODE_KIND_LIST, SPEC_NODE_KIND_LIST_ITEM_SCALAR,
    SPEC_NODE_KIND_ROOT, SPEC_NODE_KIND_SCALAR,
};
use crate::spec_serialization_order::SpecSerializationOrder;
use crate::spec_text_pattern::{SomPatternError, SomTextPattern, SpecMatchSpan};

/// Whether a node currently holds a value, used by the `state` dimension.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SpecStateFilter {
    /// The node (and everything beneath it) holds no value.
    Empty,

    /// The node holds at least one value at or beneath its path.
    NonEmpty,
}

impl SpecStateFilter {
    /// The wire name of this filter (`empty` / `nonEmpty`) — the Dart enum
    /// constant name the shared corpus is keyed by.
    pub fn name(&self) -> &'static str {
        match self {
            SpecStateFilter::Empty => "empty",
            SpecStateFilter::NonEmpty => "nonEmpty",
        }
    }

    /// The filter with the given wire name, or `None` for an unknown name.
    pub fn from_name(name: &str) -> Option<SpecStateFilter> {
        match name {
            "empty" => Some(SpecStateFilter::Empty),
            "nonEmpty" => Some(SpecStateFilter::NonEmpty),
            _ => None,
        }
    }
}

impl std::fmt::Display for SpecStateFilter {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.name())
    }
}

/// A flat, value-bearing projection of one document node — everything the
/// tier-1 structural/lexical index (`llm_and_d4rt_tools.md` §9.2) needs to
/// index a section **without re-walking the model itself**: its path, kind,
/// class, the structural facets (section id, `@MapsTo` / `@DetailedIn`), the
/// headline, the searchable strings (stored values + headline), and whether it
/// currently holds a value.
///
/// Produced by [`SpecQueryEngine::project_nodes`] /
/// [`SpecQueryEngine::project_node`], which reuse the same structural-closure
/// walk and value-extraction the live query uses — so the index and the live
/// llm_and_d4rt_tools.md §6 search agree on what a node is and what text it
/// carries — with no model (LLM) calls.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecNodeProjection {
    /// The globally-unique section-id path the node lives at.
    pub path: String,

    /// What kind of node the path lands on (a `SPEC_NODE_KIND_*` constant).
    pub kind: String,

    /// The model class the node *is* (`None` for value leaves and list
    /// containers).
    pub class_id: Option<String>,

    /// The node's `@SectionId` (field, class, or root), `None` when none.
    pub section_id: Option<String>,

    /// The `@MapsTo` target on the node's class, `None` when none.
    pub maps_to: Option<String>,

    /// The `@DetailedIn` target on the node's class, `None` when none.
    pub detailed_in: Option<String>,

    /// The node's headline — the stored one when the author set it, else the
    /// model's doc comment. `None` when neither exists.
    pub headline: Option<String>,

    /// The strings a text search indexes for this node: stored values (content,
    /// scalar item, every form-field value) followed by the headline. Empty for
    /// a container node that carries no direct value and has no headline.
    pub searchable_strings: Vec<String>,

    /// Whether the node (or anything beneath it) currently holds a value — the
    /// `state` facet (empty vs non-empty).
    pub has_value: bool,
}

impl std::fmt::Display for SpecNodeProjection {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SpecNodeProjection({}, {})", self.path, self.kind)
    }
}

/// One node matched by a [`SpecQuery`] (the llm_and_d4rt_tools.md §6 cursor
/// record).
#[derive(Debug, Clone, PartialEq)]
pub struct SpecQueryMatch {
    /// The globally-unique section-ID path the node lives at.
    pub path: String,

    /// What kind of node the path lands on (a `SPEC_NODE_KIND_*` constant).
    pub kind: String,

    /// The model class the node *is* (`None` for value leaves and list
    /// containers).
    pub class_id: Option<String>,

    /// The node's headline — stored if the author set one, else the model's doc
    /// comment (`None` when neither exists).
    pub headline: Option<String>,

    /// The matched text, when the query carried a `text` dimension (`None`
    /// otherwise) — the value/headline that the pattern hit.
    pub snippet: Option<String>,

    /// The spans within [`SpecQueryMatch::snippet`] the `text` pattern matched
    /// (empty for non-text queries).
    pub match_spans: Vec<SpecMatchSpan>,
}

impl std::fmt::Display for SpecQueryMatch {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "SpecQueryMatch({}, {})", self.path, self.kind)
    }
}

/// An AND-combined lexical/structural query (llm_and_d4rt_tools.md §6). Every
/// supplied dimension must hold for a node to match; an all-`None` query
/// ([`SpecQuery::default`]) matches every node in the document's structural
/// closure.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct SpecQuery {
    /// Substring (or [`SpecQuery::regex`] pattern) to find in content + form
    /// values and the headline.
    pub text: Option<String>,

    /// Treat [`SpecQuery::text`] as a [`SomTextPattern`] — the portable pattern
    /// subset (`.`, `*`, `+`, `?`, `[…]`, `^`, `$`) — instead of a literal
    /// substring. Named `regex` because that is what a caller reaches for it
    /// expecting; the grammar is deliberately narrower than a full regex, and
    /// [`SomPatternError`] says so rather than silently reinterpreting.
    pub regex: bool,

    /// Match [`SpecQuery::text`] case-insensitively.
    pub case_insensitive: bool,

    /// The node kinds to include (any-of); `None` admits every kind.
    pub kinds: Option<Vec<String>>,

    /// The model class name a node must *be* ([`SpecResolution::target_class`]).
    pub class_name: Option<String>,

    /// The node's `@SectionId` must equal this exactly.
    pub section_id_exact: Option<String>,

    /// The node's `@SectionId` must start with this prefix.
    pub section_id_prefix: Option<String>,

    /// A glob over the node's path (`*` matches within one segment, `**` across
    /// segments).
    pub path_glob: Option<String>,

    /// The node's class must carry `@MapsTo(<this>)`.
    pub maps_to: Option<String>,

    /// The node's class must carry `@DetailedIn(<this>)`.
    pub detailed_in: Option<String>,

    /// The node's value-presence state must match this.
    pub state: Option<SpecStateFilter>,
}

/// Runs [`SpecQuery`]s over a ([`SpecModel`], [`SpecDocument`]) pair, producing
/// [`SpecQueryCursor`]s.
///
/// The engine borrows the document immutably for its lifetime. A caller that
/// wants to mutate between cursor steps (as the conformance cursor script does)
/// drops the engine — or lets it fall out of scope — around the mutation and
/// rebuilds it; the cursor itself survives, because it holds no borrow.
pub struct SpecQueryEngine<'d, 'm> {
    /// The live document whose values are searched.
    pub document: &'d SpecDocument,

    /// The value-free meta-model queries the engine resolves against.
    pub reflection: SpecReflection<'m>,

    /// Model-declaration ordering, used to read a `@Form`'s field values in the
    /// order the model declares rather than the store's key order.
    order: SpecSerializationOrder<'m>,
}

impl<'d, 'm> SpecQueryEngine<'d, 'm> {
    /// Binds an engine to a document and a reflection surface.
    pub fn new(
        document: &'d SpecDocument,
        reflection: SpecReflection<'m>,
    ) -> SpecQueryEngine<'d, 'm> {
        let order = SpecSerializationOrder::new(reflection.model);
        SpecQueryEngine {
            document,
            reflection,
            order,
        }
    }

    /// Convenience: builds the engine for `document` over `model`.
    pub fn for_model(document: &'d SpecDocument, model: &'m SpecModel) -> SpecQueryEngine<'d, 'm> {
        SpecQueryEngine::new(document, SpecReflection::new(model))
    }

    /// The meta-model describing the document's structure.
    pub fn model(&self) -> &'m SpecModel {
        self.reflection.model
    }

    /// Builds a cursor over the nodes matching `query`. The structural candidate
    /// set is computed now (document order); value-dependent filters and path
    /// liveness are re-checked as the cursor advances.
    ///
    /// Returns [`SomPatternError`] when `query.regex` is set and `query.text` is
    /// not in the portable subset. The pattern is compiled **here**, not on
    /// first use, for two reasons: a malformed pattern is the caller's mistake
    /// and should surface at the call that made it, and a cursor that happens to
    /// visit no candidate would otherwise swallow the error entirely.
    pub fn query(&self, query: SpecQuery) -> Result<SpecQueryCursor, SomPatternError> {
        let pattern = match &query.text {
            None => None,
            Some(_) => Some(pattern_for(&query)?),
        };
        let mut candidates: Vec<String> = Vec::new();
        for path in self.enumerate_paths() {
            let resolution = match self.reflection.resolve(&path) {
                Some(r) => r,
                None => continue,
            };
            if self.matches_structural(&query, &resolution) {
                candidates.push(path);
            }
        }
        Ok(SpecQueryCursor {
            query,
            pattern,
            candidate_paths: candidates,
            position: 0,
        })
    }

    // --- flat node projection (tier-1 index source) -------------------------

    /// Projects every indexable node of the live document (the
    /// llm_and_d4rt_tools.md §6 structural closure) as a flat
    /// [`SpecNodeProjection`], in document order. Reuses the same walk and value
    /// extraction the query uses, so the index built from these projections and
    /// the live llm_and_d4rt_tools.md §6 search agree on what a node is and what
    /// text it carries. Pure object-model traversal — no model (LLM) calls.
    pub fn project_nodes(&self) -> Vec<SpecNodeProjection> {
        self.enumerate_paths()
            .iter()
            .filter_map(|p| self.project_node(p))
            .collect()
    }

    /// Projects the single node at `path`, or `None` when the path no longer
    /// resolves against the model. Used for the index's incremental refresh: a
    /// caller re-projects only the changed section paths.
    pub fn project_node(&self, path: &str) -> Option<SpecNodeProjection> {
        let resolution = self.reflection.resolve(path)?;
        Some(SpecNodeProjection {
            path: path.to_string(),
            kind: resolution.kind.clone(),
            class_id: resolution.target_class.as_ref().map(|c| c.name.clone()),
            section_id: section_id_of(&resolution),
            maps_to: resolution
                .target_class
                .as_ref()
                .and_then(|c| non_empty(&c.maps_to)),
            detailed_in: resolution
                .target_class
                .as_ref()
                .and_then(|c| non_empty(&c.detailed_in)),
            headline: self.headline_of(&resolution),
            searchable_strings: self.searchable_strings(&resolution),
            has_value: self.document.has_values_under(path),
        })
    }

    // --- structural-closure enumeration -------------------------------------

    /// Every addressable node of the document in document order: the root, each
    /// singular complex/section node on the spine (bounded by cycle detection),
    /// each list container, each *existing* list item, and every declared leaf.
    fn enumerate_paths(&self) -> Vec<String> {
        let mut out: Vec<String> = Vec::new();
        for root in self.reflection.roots() {
            let segment = self.reflection.root_segment(root);
            let mut seen = BTreeSet::new();
            seen.insert(root.type_.clone());
            self.walk(
                &segment,
                self.reflection.class_named(&root.type_),
                &seen,
                &mut out,
            );
        }
        out
    }

    fn walk(
        &self,
        path: &str,
        cls: Option<&SpecClass>,
        ancestor_types: &BTreeSet<String>,
        out: &mut Vec<String>,
    ) {
        out.push(path.to_string()); // the node itself (root / complex / section)
        let cls = match cls {
            Some(c) => c,
            None => return,
        };
        for field in &cls.fields {
            let field_path = spec_path_join(path, &self.reflection.field_segment(field));
            match field.kind.as_str() {
                SPEC_FIELD_KIND_CONTENT
                | SPEC_FIELD_KIND_ENUM
                | SPEC_FIELD_KIND_SCALAR
                | SPEC_FIELD_KIND_FORM => out.push(field_path), // a value leaf
                SPEC_FIELD_KIND_LIST => {
                    out.push(field_path.clone()); // the list container node
                    for item_path in self.document.list_items(&field_path) {
                        if field.element_is_complex
                            && !field.element_type.is_empty()
                            && !ancestor_types.contains(&field.element_type)
                        {
                            let mut deeper = ancestor_types.clone();
                            deeper.insert(field.element_type.clone());
                            self.walk(
                                &item_path,
                                self.reflection.class_named(&field.element_type),
                                &deeper,
                                out,
                            );
                        } else {
                            // scalar item, or a recursive/unknown element
                            out.push(item_path);
                        }
                    }
                }
                SPEC_FIELD_KIND_COMPLEX | SPEC_FIELD_KIND_SECTION => {
                    if !field.type_.is_empty() && !ancestor_types.contains(&field.type_) {
                        let mut deeper = ancestor_types.clone();
                        deeper.insert(field.type_.clone());
                        self.walk(
                            &field_path,
                            self.reflection.class_named(&field.type_),
                            &deeper,
                            out,
                        );
                    } else {
                        out.push(field_path); // recursive/unknown target: terminal
                    }
                }
                _ => out.push(field_path),
            }
        }
    }

    // --- predicates ----------------------------------------------------------

    /// The model-fixed dimensions (kind / class / id / path / mapsTo /
    /// detailedIn).
    fn matches_structural(&self, query: &SpecQuery, resolution: &SpecResolution) -> bool {
        if let Some(kinds) = &query.kinds {
            if !kinds.contains(&resolution.kind) {
                return false;
            }
        }
        if let Some(class_name) = &query.class_name {
            if resolution.target_class.as_ref().map(|c| c.name.as_str()) != Some(class_name.as_str())
            {
                return false;
            }
        }

        let section_id = section_id_of(resolution);
        if let Some(exact) = &query.section_id_exact {
            if section_id.as_deref() != Some(exact.as_str()) {
                return false;
            }
        }
        if let Some(prefix) = &query.section_id_prefix {
            if !section_id
                .as_deref()
                .map(|s| s.starts_with(prefix.as_str()))
                .unwrap_or(false)
            {
                return false;
            }
        }
        if let Some(glob) = &query.path_glob {
            if !glob_matches(glob, &resolution.path) {
                return false;
            }
        }
        if let Some(maps_to) = &query.maps_to {
            let got = resolution
                .target_class
                .as_ref()
                .and_then(|c| non_empty(&c.maps_to));
            if got.as_deref() != Some(maps_to.as_str()) {
                return false;
            }
        }
        if let Some(detailed_in) = &query.detailed_in {
            let got = resolution
                .target_class
                .as_ref()
                .and_then(|c| non_empty(&c.detailed_in));
            if got.as_deref() != Some(detailed_in.as_str()) {
                return false;
            }
        }
        true
    }

    /// The value-reading dimensions (text / state), re-evaluated against the
    /// live document. Returns the built match (with snippet/spans) or `None`
    /// when the node no longer satisfies the query. Assumes the path is
    /// structurally valid.
    fn evaluate_live(
        &self,
        query: &SpecQuery,
        pattern: Option<&SomTextPattern>,
        path: &str,
    ) -> Option<SpecQueryMatch> {
        if !self.is_live_path(path) {
            return None;
        }
        let resolution = self.reflection.resolve(path)?;

        if let Some(state) = query.state {
            let has_value = self.document.has_values_under(path);
            let want_value = state == SpecStateFilter::NonEmpty;
            if has_value != want_value {
                return None;
            }
        }

        let mut snippet: Option<String> = None;
        let mut spans: Vec<SpecMatchSpan> = Vec::new();
        if let Some(pattern) = pattern {
            let (hit_text, hit_spans) = self.match_text(pattern, &resolution)?;
            snippet = Some(hit_text);
            spans = hit_spans;
        }

        Some(SpecQueryMatch {
            path: path.to_string(),
            kind: resolution.kind.clone(),
            class_id: resolution.target_class.as_ref().map(|c| c.name.clone()),
            headline: self.headline_of(&resolution),
            snippet,
            match_spans: spans,
        })
    }

    /// Searches each candidate string in turn; the first that hits wins, so the
    /// snippet is the actual text the pattern matched.
    fn match_text(
        &self,
        pattern: &SomTextPattern,
        resolution: &SpecResolution,
    ) -> Option<(String, Vec<SpecMatchSpan>)> {
        for text in self.searchable_strings(resolution) {
            let spans = pattern.all_matches(&text);
            if !spans.is_empty() {
                return Some((text, spans));
            }
        }
        None
    }

    /// The strings a `text` query searches at `resolution`: stored values first
    /// (content leaf, scalar list item, every form field), then the node's
    /// headline.
    fn searchable_strings(&self, resolution: &SpecResolution) -> Vec<String> {
        let path = resolution.path.as_str();
        let mut out: Vec<String> = Vec::new();
        match resolution.kind.as_str() {
            SPEC_NODE_KIND_CONTENT
            | SPEC_NODE_KIND_ENUM_VALUE
            | SPEC_NODE_KIND_SCALAR
            | SPEC_NODE_KIND_LIST_ITEM_SCALAR => {
                if let Some(value) = self.document.content(path) {
                    out.push(value.clone());
                }
            }
            SPEC_NODE_KIND_FORM => {
                // Model-declaration order, not store order — see the module
                // comment's form-field note.
                let stored = self.document.form_field_names(path);
                for name in self.order.order_form_fields(path, &stored) {
                    if let Some(value) = self.document.form_field(path, &name) {
                        out.push(value.clone());
                    }
                }
            }
            // Container nodes (root / complex / section / list / complex item)
            // carry no direct value.
            _ => {}
        }
        if let Some(headline) = self.headline_of(resolution) {
            out.push(headline);
        }
        out
    }

    // --- path liveness (cursor stability) -----------------------------------

    /// Whether `path` still exists in the live document: every `-<seq>`
    /// list-item segment must still be present in its parent list. Model-fixed
    /// segments (root, complex/section, declared leaves) are always structurally
    /// live, so only list items can go stale (via
    /// [`SpecDocument::remove_list_item`]).
    fn is_live_path(&self, path: &str) -> bool {
        let segments = spec_path_segments(path);
        let mut prefix = String::new();
        for (i, segment) in segments.iter().enumerate() {
            let previous = prefix.clone();
            prefix = if i == 0 {
                segment.clone()
            } else {
                spec_path_join(&prefix, segment)
            };
            let split = match split_list_item_segment(segment) {
                Some(s) => s,
                None => continue,
            };
            let list_path = if i == 0 {
                split.base.clone()
            } else {
                spec_path_join(&previous, &split.base)
            };
            let is_list = self
                .reflection
                .resolve(&list_path)
                .map(|r| r.kind == SPEC_NODE_KIND_LIST)
                .unwrap_or(false);
            if is_list && !self.document.list_items(&list_path).contains(&prefix) {
                return false;
            }
        }
        true
    }

    // --- node descriptors ----------------------------------------------------

    /// The headline a node actually shows: the document's **stored** headline
    /// when the author set one, otherwise the model's doc comment.
    ///
    /// The stored value comes first because it is the one a reader sees and the
    /// one an author would search for. Consulting only the doc comment made
    /// renamed sections unfindable — `set_headline("DEMO/SUM", "Executive
    /// Summary")` stored text that no query could reach and that never entered
    /// the search index built from [`SpecQueryEngine::project_nodes`].
    fn headline_of(&self, resolution: &SpecResolution) -> Option<String> {
        if let Some(stored) = self.document.headline(&resolution.path) {
            return Some(stored.clone());
        }
        if let Some(doc) = resolution.field.as_ref().and_then(|f| non_empty(&f.doc)) {
            return Some(doc);
        }
        if let Some(doc) = resolution
            .target_class
            .as_ref()
            .and_then(|c| non_empty(&c.doc))
        {
            return Some(doc);
        }
        if resolution.kind == SPEC_NODE_KIND_ROOT {
            return resolution
                .root
                .as_ref()
                .and_then(|r| non_empty(&r.description));
        }
        None
    }
}

/// The node's `@SectionId`: the field's, else its class's, else the root's.
fn section_id_of(resolution: &SpecResolution) -> Option<String> {
    if let Some(id) = resolution
        .field
        .as_ref()
        .and_then(|f| non_empty(&f.section_id))
    {
        return Some(id);
    }
    if let Some(id) = resolution
        .target_class
        .as_ref()
        .and_then(|c| non_empty(&c.section_id))
    {
        return Some(id);
    }
    resolution
        .root
        .as_ref()
        .and_then(|r| non_empty(&r.section_id))
}

/// `""` is this crate's model-level "absent" sentinel; the query surface reports
/// genuine `Option`s, so the two are converted at exactly this one point.
fn non_empty(value: &str) -> Option<String> {
    if value.is_empty() {
        None
    } else {
        Some(value.to_string())
    }
}

/// Compiles the query's `text` dimension: the portable pattern subset when
/// `regex` is set, a plain substring otherwise.
fn pattern_for(query: &SpecQuery) -> Result<SomTextPattern, SomPatternError> {
    let text = query.text.as_deref().unwrap_or("");
    if query.regex {
        SomTextPattern::compile(text, query.case_insensitive)
    } else {
        Ok(SomTextPattern::literal(text, query.case_insensitive))
    }
}

const K_ASTERISK: u16 = 0x2A; // *
const K_SLASH: u16 = 0x2F; // /

/// Glob match over a whole path: `**` spans `/`, a single `*` stays within one
/// segment, every other character is literal.
///
/// Matched directly rather than compiled to a regex, because two of the nine
/// runtimes have no regex engine and because a wildcard walk is a smaller, more
/// obviously identical thing to transcribe than an escaping rule plus somebody
/// else's matcher (see [`SomTextPattern`]).
pub fn glob_matches(glob: &str, path: &str) -> bool {
    let glob: Vec<u16> = glob.encode_utf16().collect();
    let path: Vec<u16> = path.encode_utf16().collect();
    glob_at(&glob, 0, &path, 0)
}

/// Greedy wildcard walk with backtracking: at a `*`/`**` try the longest
/// remaining span first and give characters back until the tail fits.
fn glob_at(glob: &[u16], g_in: usize, path: &[u16], p_in: usize) -> bool {
    let mut g = g_in;
    let mut p = p_in;
    while g < glob.len() {
        if glob[g] != K_ASTERISK {
            if p >= path.len() || path[p] != glob[g] {
                return false;
            }
            g += 1;
            p += 1;
            continue;
        }
        let crosses_segments = g + 1 < glob.len() && glob[g + 1] == K_ASTERISK;
        let after_wildcard = g + if crosses_segments { 2 } else { 1 };
        // Longest first, so `*` behaves greedily exactly as the regex did.
        let mut limit = path.len();
        if !crosses_segments {
            for (i, unit) in path.iter().enumerate().skip(p) {
                if *unit == K_SLASH {
                    limit = i;
                    break;
                }
            }
        }
        let mut take = limit;
        loop {
            if glob_at(glob, after_wildcard, path, take) {
                return true;
            }
            if take == p {
                break;
            }
            take -= 1;
        }
        return false;
    }
    p == path.len()
}

/// A lazy, forward-only cursor over the nodes matching a [`SpecQuery`]
/// (llm_and_d4rt_tools.md §6).
///
/// The cursor holds the structural candidate paths captured when it was created;
/// each step re-validates the path against the **live** document and re-applies
/// the value-dependent filters, so concurrent edits never surface stale or
/// newly-mismatching results. It is forward-only: [`SpecQueryCursor::next`] /
/// [`SpecQueryCursor::take`] consume matches; [`SpecQueryCursor::count`] peeks
/// the remaining matches without consuming.
///
/// Unlike the Dart reference the cursor keeps **no reference to its engine** —
/// see the module comment. Every step takes the engine, which is what lets the
/// document be mutated between steps.
#[derive(Debug, Clone)]
pub struct SpecQueryCursor {
    query: SpecQuery,

    /// The query's `text` dimension, compiled once when the cursor was built.
    /// `None` when the query has no text dimension at all.
    pattern: Option<SomTextPattern>,
    candidate_paths: Vec<String>,
    position: usize,
}

impl SpecQueryCursor {
    /// The query this cursor was opened with.
    pub fn query_spec(&self) -> &SpecQuery {
        &self.query
    }

    /// The structural candidate paths captured when the cursor was created —
    /// the *upper bound* on what it can still yield, before liveness and the
    /// value-dependent filters are re-applied.
    pub fn candidate_paths(&self) -> &[String] {
        &self.candidate_paths
    }

    /// The next matching node, or `None` when the cursor is exhausted. Skips
    /// candidates whose path went stale or no longer satisfies the live filters.
    pub fn next(&mut self, engine: &SpecQueryEngine<'_, '_>) -> Option<SpecQueryMatch> {
        while self.position < self.candidate_paths.len() {
            let path = self.candidate_paths[self.position].clone();
            self.position += 1;
            if let Some(m) = engine.evaluate_live(&self.query, self.pattern.as_ref(), &path) {
                return Some(m);
            }
        }
        None
    }

    /// Up to `n` further matches (fewer when the cursor is exhausted first).
    pub fn take(&mut self, engine: &SpecQueryEngine<'_, '_>, n: usize) -> Vec<SpecQueryMatch> {
        let mut out: Vec<SpecQueryMatch> = Vec::new();
        for _ in 0..n {
            match self.next(engine) {
                Some(m) => out.push(m),
                None => break,
            }
        }
        out
    }

    /// Every remaining match, draining the cursor.
    pub fn to_list(&mut self, engine: &SpecQueryEngine<'_, '_>) -> Vec<SpecQueryMatch> {
        let mut out: Vec<SpecQueryMatch> = Vec::new();
        while let Some(m) = self.next(engine) {
            out.push(m);
        }
        out
    }

    /// How many matches remain from the current position, without consuming any.
    /// Re-validates each remaining candidate against the live document, so the
    /// count reflects the document as it is *now*.
    pub fn count(&self, engine: &SpecQueryEngine<'_, '_>) -> usize {
        self.candidate_paths[self.position..]
            .iter()
            .filter(|p| {
                engine
                    .evaluate_live(&self.query, self.pattern.as_ref(), p)
                    .is_some()
            })
            .count()
    }
}
