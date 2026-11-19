//! `spec_impact_walk` — the impact walk, the starting table of a change's
//! impact evaluation (the change mode of the `tom_specs` process, Phase 0 step
//! `impact`). A port of the TypeScript `spec_impact_walk.ts` (and the Dart
//! `spec_impact_walk.dart`).
//!
//! For a specification it lists **every** section of **every** document root
//! of the model, filled or not, and roots the project never created as well:
//! each row with its section-id chain, its model class, whether it holds
//! values, and its CodeSpecs routing. The change analyst gives each row a
//! verdict (*affected*, *needed*, *unaffected*); a table built from the model
//! rather than from the document is what makes "nothing the SOM covers is
//! missed" checkable. Beside it, [`spec_impact_level`] records how far the
//! project has come (documents, extracts, IR, tests, code).
//!
//! Rows: one per class node (the root, each `complex` / `section` field, each
//! list item) and one per list (with its item count). An empty list of a class
//! element gets one **template** row `<list>/*` with the element's subtree
//! below it, so a section a new item would need shows its routing too. Value
//! leaves (content, form fields) are counted in their row, not rows of their
//! own. A class already on the branch is not entered again (the model is a
//! graph), exactly as the CodeSpecs routing walk cuts recursion. Below a
//! `@FollowUpKind` section every row carries that routing: the whole subtree is
//! delivered by the process, as the CodeSpecs extractor treats it.
//!
//! Pure: it reads a model and documents and writes nothing. Finding the files
//! and probing folders is the caller's. Pinned by
//! `tom_som_conformance/corpus/impact_walk_cases.json`.

use std::collections::{HashMap, HashSet};

use crate::json::Json;
use crate::spec_codespecs_extract::{
    code_specs_class_routing, code_specs_field_routing, CodeSpecsRouting, CodeSpecsRoutingVerdict,
};
use crate::spec_document::SpecDocument;
use crate::spec_model::{
    SpecClass, SpecField, SpecModel, SpecRoot, SPEC_FIELD_KIND_COMPLEX, SPEC_FIELD_KIND_LIST,
    SPEC_FIELD_KIND_SECTION,
};
use crate::spec_paths::spec_path_join;
use crate::spec_reflection::SpecReflection;

/// What a row of the walk stands for.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SpecImpactRowKind {
    /// The document root.
    Root,
    /// A `complex` field's class node.
    Complex,
    /// A `section` field's class node.
    Section,
    /// A list field (its items are rows of their own).
    List,
    /// One item of a list of class elements.
    Item,
    /// The element class of an empty list, at `<list>/*`: what a new item holds.
    Template,
}

impl SpecImpactRowKind {
    /// The portable name of the kind, as every runtime writes it.
    pub fn name(&self) -> &'static str {
        match self {
            SpecImpactRowKind::Root => "root",
            SpecImpactRowKind::Complex => "complex",
            SpecImpactRowKind::Section => "section",
            SpecImpactRowKind::List => "list",
            SpecImpactRowKind::Item => "item",
            SpecImpactRowKind::Template => "template",
        }
    }
}

/// One row of the impact walk.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecImpactRow {
    /// The document path; a template's subtree has `*` for the item segment.
    pub path: String,
    /// The section-id chain, outer first, joined by ` > ` (a list item by its
    /// stored id).
    pub chain: String,
    pub kind: SpecImpactRowKind,
    /// The model class; for a list, its element class (`""` for a list of
    /// scalars).
    pub class_name: String,
    /// Nesting below the root (the root is 0).
    pub depth: usize,
    /// Whether the document holds anything at or below the path
    /// ([`SpecDocument::has_values_under`]).
    pub filled: bool,
    /// Stored values at or below the path: content leaves plus form-field
    /// values.
    pub values: usize,
    /// A list's item count; `None` for every other row.
    pub items: Option<usize>,
    /// The CodeSpecs routing: of the class (a class row), of the element class
    /// (a list of classes), or of the field, else its enclosing class (a list
    /// of scalars). Below a `feedsProcess` section, that section's routing.
    pub routing: CodeSpecsRoutingVerdict,
    /// The routing's values verbatim (`CodeSpecPart` / `FollowUpProcess` /
    /// `NoArtifactReason` names).
    pub routing_values: Vec<String>,
    /// Where the routing marker is declared (`Class` or `Class.field`); `""`
    /// when none.
    pub routing_declared_at: String,
}

impl SpecImpactRow {
    /// The row as JSON, keys as every runtime writes them.
    pub fn to_json(&self) -> Json {
        obj(vec![
            ("path", jstr(&self.path)),
            ("chain", jstr(&self.chain)),
            ("kind", jstr(self.kind.name())),
            ("className", jstr(&self.class_name)),
            ("depth", Json::Int(self.depth as i64)),
            ("filled", Json::Bool(self.filled)),
            ("values", Json::Int(self.values as i64)),
            (
                "items",
                self.items
                    .map(|n| Json::Int(n as i64))
                    .unwrap_or(Json::Null),
            ),
            ("routing", jstr(self.routing.name())),
            ("routingValues", jstrs(&self.routing_values)),
            ("routingDeclaredAt", jstr(&self.routing_declared_at)),
        ])
    }
}

/// The walk of one document root.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecImpactRootWalk {
    /// The root's model type, e.g. `D00SolutionBlueprint`.
    pub type_: String,
    /// The root's section id (its first path segment).
    pub section_id: String,
    /// Whether the specification has this document; an absent root is walked
    /// over an empty document.
    pub present: bool,
    pub rows: Vec<SpecImpactRow>,
}

impl SpecImpactRootWalk {
    /// The root walk as JSON.
    pub fn to_json(&self) -> Json {
        obj(vec![
            ("type", jstr(&self.type_)),
            ("sectionId", jstr(&self.section_id)),
            ("present", Json::Bool(self.present)),
            (
                "rows",
                Json::Array(self.rows.iter().map(|r| r.to_json()).collect()),
            ),
        ])
    }
}

/// Walks every document root of `model`, in model order: a root present in
/// `documents` (keyed by root type) over its document, any other over an
/// empty one. A document keyed by a type the model has no root for is refused.
pub fn spec_impact_walk(
    model: &SpecModel,
    documents: &HashMap<String, SpecDocument>,
) -> Result<Vec<SpecImpactRootWalk>, String> {
    let mut types: Vec<&String> = documents.keys().collect();
    types.sort();
    for ty in types {
        if model.roots.iter().all(|r| &r.type_ != ty) {
            return Err(format!(
                "spec_impact_walk: the model has no document root {}",
                ty
            ));
        }
    }
    let reflection = SpecReflection::new(model);
    let empty = SpecDocument::new();
    Ok(model
        .roots
        .iter()
        .map(|root| {
            let doc = documents.get(&root.type_);
            let mut walker = ImpactWalker::new(model, &reflection, doc.unwrap_or(&empty));
            walker.walk_root(root);
            SpecImpactRootWalk {
                type_: root.type_.clone(),
                section_id: reflection.root_segment(root),
                present: doc.is_some(),
                rows: walker.rows,
            }
        })
        .collect())
}

struct ImpactWalker<'a> {
    model: &'a SpecModel,
    reflection: &'a SpecReflection<'a>,
    doc: &'a SpecDocument,
    rows: Vec<SpecImpactRow>,
    /// Stored values per path prefix (a value counts at its own path and every
    /// ancestor).
    counts: HashMap<String, usize>,
}

impl<'a> ImpactWalker<'a> {
    fn new(
        model: &'a SpecModel,
        reflection: &'a SpecReflection<'a>,
        doc: &'a SpecDocument,
    ) -> ImpactWalker<'a> {
        let mut walker = ImpactWalker {
            model,
            reflection,
            doc,
            rows: Vec::new(),
            counts: HashMap::new(),
        };
        for path in doc.content_paths() {
            if doc.content(&path).is_some() {
                walker.count(&path);
            }
        }
        for path in doc.form_paths() {
            for field in doc.form_field_names(&path) {
                if doc.form_field(&path, &field).is_some() {
                    walker.count(&path);
                }
            }
        }
        walker
    }

    /// Adds one value at `path` to the path and each of its prefixes ending
    /// before `/` or `-`.
    fn count(&mut self, path: &str) {
        *self.counts.entry(path.to_string()).or_insert(0) += 1;
        let bytes = path.as_bytes();
        for i in (1..bytes.len()).rev() {
            // Both separators are ASCII, so `i` is a char boundary.
            if bytes[i] == b'/' || bytes[i] == b'-' {
                *self.counts.entry(path[..i].to_string()).or_insert(0) += 1;
            }
        }
    }

    fn values_at(&self, path: &str) -> usize {
        self.counts.get(path).copied().unwrap_or(0)
    }

    fn walk_root(&mut self, root: &SpecRoot) {
        let cls = match self.model.class_named(&root.type_) {
            Some(cls) => cls,
            None => return,
        };
        let segment = self.reflection.root_segment(root);
        let mut ancestors = HashSet::new();
        ancestors.insert(cls.name.clone());
        self.class_node(
            SpecImpactRowKind::Root,
            &segment,
            &segment,
            cls,
            0,
            &ancestors,
            None,
        );
    }

    #[allow(clippy::too_many_arguments)]
    fn push_row(
        &mut self,
        kind: SpecImpactRowKind,
        path: &str,
        chain: &str,
        class_name: &str,
        depth: usize,
        items: Option<usize>,
        routing: &CodeSpecsRouting,
    ) {
        let template = path.contains('*');
        self.rows.push(SpecImpactRow {
            path: path.to_string(),
            chain: chain.to_string(),
            kind,
            class_name: class_name.to_string(),
            depth,
            filled: !template && self.doc.has_values_under(path),
            values: if template { 0 } else { self.values_at(path) },
            items,
            routing: routing.verdict,
            routing_values: routing.values.clone(),
            routing_declared_at: routing.declared_at.clone(),
        });
    }

    #[allow(clippy::too_many_arguments)]
    fn class_node(
        &mut self,
        kind: SpecImpactRowKind,
        path: &str,
        chain: &str,
        cls: &'a SpecClass,
        depth: usize,
        ancestors: &HashSet<String>,
        process: Option<&CodeSpecsRouting>,
    ) {
        let routing = match process {
            Some(p) => p.clone(),
            None => code_specs_class_routing(cls, path),
        };
        let below = if routing.verdict == CodeSpecsRoutingVerdict::FeedsProcess {
            Some(routing.clone())
        } else {
            None
        };
        self.push_row(kind, path, chain, &cls.name, depth, None, &routing);
        for field in &cls.fields {
            let segment = self.reflection.field_segment(field);
            let field_path = spec_path_join(path, &segment);
            let field_chain = format!("{} > {}", chain, segment);
            if field.kind == SPEC_FIELD_KIND_COMPLEX || field.kind == SPEC_FIELD_KIND_SECTION {
                if let Some(child) = self.enter(&field.type_, ancestors) {
                    let child_kind = if field.kind == SPEC_FIELD_KIND_COMPLEX {
                        SpecImpactRowKind::Complex
                    } else {
                        SpecImpactRowKind::Section
                    };
                    let mut next = ancestors.clone();
                    next.insert(child.name.clone());
                    self.class_node(
                        child_kind,
                        &field_path,
                        &field_chain,
                        child,
                        depth + 1,
                        &next,
                        below.as_ref(),
                    );
                }
            } else if field.kind == SPEC_FIELD_KIND_LIST {
                self.list(
                    cls,
                    field,
                    &field_path,
                    &field_chain,
                    depth + 1,
                    ancestors,
                    below.as_ref(),
                );
            }
            // Any other kind is a value leaf: counted in this row.
        }
    }

    #[allow(clippy::too_many_arguments)]
    fn list(
        &mut self,
        owner: &'a SpecClass,
        field: &'a SpecField,
        path: &str,
        chain: &str,
        depth: usize,
        ancestors: &HashSet<String>,
        process: Option<&CodeSpecsRouting>,
    ) {
        let template = path.contains('*');
        let items = if template {
            Vec::new()
        } else {
            self.doc.list_items(path)
        };
        let element = if field.element_is_complex {
            self.model.class_named(&field.element_type)
        } else {
            None
        };
        let routing = match (process, element) {
            (Some(p), _) => p.clone(),
            (None, Some(el)) => code_specs_class_routing(el, path),
            (None, None) => code_specs_field_routing(owner, field)
                .unwrap_or_else(|| code_specs_class_routing(owner, path)),
        };
        let class_name = element.map(|e| e.name.as_str()).unwrap_or("");
        self.push_row(
            SpecImpactRowKind::List,
            path,
            chain,
            class_name,
            depth,
            Some(items.len()),
            &routing,
        );
        let element = match element {
            Some(el) if !ancestors.contains(&el.name) => el,
            _ => return,
        };
        let mut next = ancestors.clone();
        next.insert(element.name.clone());
        if items.is_empty() {
            self.class_node(
                SpecImpactRowKind::Template,
                &format!("{}/*", path),
                &format!("{} > *", chain),
                element,
                depth + 1,
                &next,
                process,
            );
            return;
        }
        for item_path in &items {
            let id = match self.doc.item_section_id(item_path) {
                Some(stored) => stored.clone(),
                None => match item_path.rfind('/') {
                    Some(i) => item_path[i + 1..].to_string(),
                    None => item_path.clone(),
                },
            };
            self.class_node(
                SpecImpactRowKind::Item,
                item_path,
                &format!("{} > {}", chain, id),
                element,
                depth + 1,
                &next,
                process,
            );
        }
    }

    fn enter(&self, ty: &str, ancestors: &HashSet<String>) -> Option<&'a SpecClass> {
        if ty.is_empty() || ancestors.contains(ty) {
            return None;
        }
        self.model.class_named(ty)
    }
}

// --- the project's level -----------------------------------------------------

/// A folder the caller passed for tests or code, and whether it exists.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecImpactFolder {
    pub path: String,
    pub present: bool,
}

impl SpecImpactFolder {
    /// The folder as JSON.
    pub fn to_json(&self) -> Json {
        obj(vec![
            ("path", jstr(&self.path)),
            ("present", Json::Bool(self.present)),
        ])
    }
}

/// One document root of the level: whether the specification has it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecImpactLevelDocument {
    pub type_: String,
    pub section_id: String,
    pub present: bool,
}

/// How far the project has come (impact_evaluation.md § Level).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecImpactLevel {
    /// Every document root: whether the specification has it.
    pub documents: Vec<SpecImpactLevelDocument>,
    /// `phase1_project_idea/` holds a Markdown file.
    pub project_idea: bool,
    /// `CE-*.extract.yaml` files in `generated-doc/codespecs_extracts/`.
    pub extracts: usize,
    /// `generated-doc/codespecs_extracts/gate.verdicts.yaml` exists.
    pub gate_record: bool,
    /// `*.ir.yaml` files in `irspecs/`.
    pub ir: usize,
    /// Gate checklists and reports under `gates/` and `quality/evidence/gates/`.
    pub gates: Vec<String>,
    /// The test folders the caller passed; `None`: none given.
    pub tests: Option<Vec<SpecImpactFolder>>,
    /// The code folders the caller passed; `None`: none given.
    pub code: Option<Vec<SpecImpactFolder>>,
    /// The phases (1–6) the project has reached.
    pub phases_reached: Vec<u32>,
    /// The phases (1–6) it has not, which a change leaves out (they run later
    /// in initial mode).
    pub phases_left_out: Vec<u32>,
}

impl SpecImpactLevel {
    /// The level as JSON.
    pub fn to_json(&self) -> Json {
        let folders = |f: &Option<Vec<SpecImpactFolder>>| match f {
            Some(list) => Json::Array(list.iter().map(|x| x.to_json()).collect()),
            None => Json::Null,
        };
        let numbers = |n: &[u32]| Json::Array(n.iter().map(|p| Json::Int(*p as i64)).collect());
        obj(vec![
            (
                "documents",
                Json::Array(
                    self.documents
                        .iter()
                        .map(|d| {
                            obj(vec![
                                ("type", jstr(&d.type_)),
                                ("sectionId", jstr(&d.section_id)),
                                ("present", Json::Bool(d.present)),
                            ])
                        })
                        .collect(),
                ),
            ),
            ("projectIdea", Json::Bool(self.project_idea)),
            ("extracts", Json::Int(self.extracts as i64)),
            ("gateRecord", Json::Bool(self.gate_record)),
            ("ir", Json::Int(self.ir as i64)),
            ("gates", jstrs(&self.gates)),
            ("tests", folders(&self.tests)),
            ("code", folders(&self.code)),
            ("phasesReached", numbers(&self.phases_reached)),
            ("phasesLeftOut", numbers(&self.phases_left_out)),
        ])
    }
}

/// A listing entry `/`-separated and without a leading `./`.
fn normalize_listing_path(p: &str) -> String {
    let f = p.replace('\\', "/");
    match f.strip_prefix("./") {
        Some(rest) => rest.to_string(),
        None => f,
    }
}

/// Whether `f` is `<prefix><middle><suffix>` with a middle of at least
/// `min_middle` characters and no `/` after the prefix (the regex
/// `^<prefix>[^/]{min,}<suffix>$` for a suffix without `/`).
fn single_segment(f: &str, prefix: &str, min_middle: usize, suffix: &str) -> bool {
    match f.strip_prefix(prefix) {
        Some(rest) => {
            !rest.contains('/')
                && rest.ends_with(suffix)
                && rest.chars().count() >= min_middle + suffix.chars().count()
        }
        None => false,
    }
}

/// `^<dir_prefix>[^/]*/[^/]+<suffix>$`: a file directly in a folder whose name
/// starts with `dir_prefix`.
fn file_in_prefixed_folder(f: &str, dir_prefix: &str, suffix: &str) -> bool {
    let rest = match f.strip_prefix(dir_prefix) {
        Some(rest) => rest,
        None => return false,
    };
    match rest.find('/') {
        Some(i) => single_segment(&rest[i + 1..], "", 1, suffix),
        None => false,
    }
}

/// The project's level from the walk and a listing of the spec root (paths
/// relative to it, `/`-separated). Phase 2 is reached when the root with
/// section id `SBP` is present, Phase 3 when any other root is that is not a
/// generation input, Phase 4 when extracts or IR exist, Phases 5 and 6 when a
/// test or code folder the caller passed exists. Phases 7–8 (acceptance,
/// deployment) are not visible on disk and are not reported.
pub fn spec_impact_level(
    model: &SpecModel,
    walk: &[SpecImpactRootWalk],
    listing: &[String],
    tests: Option<Vec<SpecImpactFolder>>,
    code: Option<Vec<SpecImpactFolder>>,
) -> SpecImpactLevel {
    let files: Vec<String> = listing.iter().map(|p| normalize_listing_path(p)).collect();
    let documents = walk
        .iter()
        .map(|r| SpecImpactLevelDocument {
            type_: r.type_.clone(),
            section_id: r.section_id.clone(),
            present: r.present,
        })
        .collect();
    let project_idea = files
        .iter()
        .any(|f| file_in_prefixed_folder(f, "phase1_", ".md"));
    let extracts = files
        .iter()
        .filter(|f| {
            single_segment(
                f,
                "generated-doc/codespecs_extracts/CE-",
                1,
                ".extract.yaml",
            )
        })
        .count();
    let gate_record = files
        .iter()
        .any(|f| f == "generated-doc/codespecs_extracts/gate.verdicts.yaml");
    let ir = files
        .iter()
        .filter(|f| single_segment(f, "irspecs/", 1, ".ir.yaml"))
        .count();
    let mut gates: Vec<String> = files
        .iter()
        .filter(|f| {
            single_segment(f, "gates/G", 0, ".checklist.yaml")
                || single_segment(f, "quality/evidence/gates/", 1, ".md")
        })
        .cloned()
        .collect();
    gates.sort();
    let present = |test: &dyn Fn(&SpecRoot) -> bool| {
        walk.iter().any(|w| {
            w.present
                && model
                    .roots
                    .iter()
                    .find(|r| r.type_ == w.type_)
                    .is_some_and(test)
        })
    };
    let mut reached: Vec<u32> = Vec::new();
    if project_idea {
        reached.push(1);
    }
    if present(&|r: &SpecRoot| r.section_id == "SBP") {
        reached.push(2);
    }
    if present(&|r: &SpecRoot| r.section_id != "SBP" && !model.is_generation_input(r)) {
        reached.push(3);
    }
    if extracts > 0 || ir > 0 {
        reached.push(4);
    }
    if tests.as_ref().is_some_and(|t| t.iter().any(|f| f.present)) {
        reached.push(5);
    }
    if code.as_ref().is_some_and(|c| c.iter().any(|f| f.present)) {
        reached.push(6);
    }
    let left_out = (1..=6).filter(|p| !reached.contains(p)).collect();
    SpecImpactLevel {
        documents,
        project_idea,
        extracts,
        gate_record,
        ir,
        gates,
        tests,
        code,
        phases_reached: reached,
        phases_left_out: left_out,
    }
}

/// The specification's current documents in a listing of the spec root: the
/// `*.tomspecs.yaml` files directly in a `phase*` folder. The numbered step
/// folders below hold round copies and are not the specification.
pub fn spec_impact_document_files(listing: &[String]) -> Vec<String> {
    let mut files: Vec<String> = listing
        .iter()
        .map(|p| normalize_listing_path(p))
        .filter(|f| file_in_prefixed_folder(f, "phase", ".tomspecs.yaml"))
        .collect();
    files.sort();
    files
}

// --- the Markdown table ------------------------------------------------------

fn cell(text: &str) -> String {
    text.replace('|', "\\|")
}

fn join_or_none<T: ToString>(items: &[T]) -> String {
    if items.is_empty() {
        "none".to_string()
    } else {
        items
            .iter()
            .map(|i| i.to_string())
            .collect::<Vec<_>>()
            .join(", ")
    }
}

/// The walk as Markdown, for a round folder's `walk/` (one table per root, then
/// § Level): the table the change analyst gives verdicts to.
pub fn spec_impact_walk_markdown(
    walk: &[SpecImpactRootWalk],
    level: Option<&SpecImpactLevel>,
) -> String {
    let mut out: Vec<String> = vec!["# Impact walk".to_string(), String::new()];
    out.push(
        "Every section of every document root, filled or not: the section-id chain, the model class, whether it holds values, and its CodeSpecs routing. \
A list counts its items; an empty list of sections shows what a new item holds at `<list>/*`."
            .to_string(),
    );
    out.push(String::new());
    for root in walk {
        let filled = root.rows.iter().filter(|r| r.filled).count();
        out.push(format!(
            "## {} — {}{}",
            root.section_id,
            root.type_,
            if root.present { "" } else { " (absent)" }
        ));
        out.push(String::new());
        out.push(format!(
            "{} rows, {} holding values.",
            root.rows.len(),
            filled
        ));
        out.push(String::new());
        out.push(
            "| Section-id chain | Path | Kind | Class | Values | Items | Routing |".to_string(),
        );
        out.push("| --- | --- | --- | --- | --- | --- | --- |".to_string());
        for r in &root.rows {
            let routing = if r.routing_values.is_empty() {
                r.routing.name().to_string()
            } else {
                format!("{}: {}", r.routing.name(), r.routing_values.join(", "))
            };
            out.push(format!(
                "| {} | `{}` | {} | {} | {} | {} | {} |",
                cell(&r.chain),
                cell(&r.path),
                r.kind.name(),
                cell(&r.class_name),
                if r.filled {
                    r.values.to_string()
                } else {
                    "—".to_string()
                },
                r.items.map(|n| n.to_string()).unwrap_or_default(),
                cell(&routing)
            ));
        }
        out.push(String::new());
    }
    if let Some(level) = level {
        let yes = |b: bool| if b { "yes" } else { "no" };
        let folders = |f: &Option<Vec<SpecImpactFolder>>| match f {
            None => "not given".to_string(),
            Some(list) if list.is_empty() => "none".to_string(),
            Some(list) => list
                .iter()
                .map(|x| {
                    format!(
                        "`{}` ({})",
                        x.path,
                        if x.present { "present" } else { "absent" }
                    )
                })
                .collect::<Vec<_>>()
                .join(", "),
        };
        let present: Vec<&str> = level
            .documents
            .iter()
            .filter(|d| d.present)
            .map(|d| d.section_id.as_str())
            .collect();
        let absent: Vec<&str> = level
            .documents
            .iter()
            .filter(|d| !d.present)
            .map(|d| d.section_id.as_str())
            .collect();
        let gates = if level.gates.is_empty() {
            "none".to_string()
        } else {
            level
                .gates
                .iter()
                .map(|g| format!("`{}`", g))
                .collect::<Vec<_>>()
                .join(", ")
        };
        out.push("## Level".to_string());
        out.push(String::new());
        out.push(format!("- Documents present: {}", join_or_none(&present)));
        out.push(format!("- Documents absent: {}", join_or_none(&absent)));
        out.push(format!("- Project Idea: {}", yes(level.project_idea)));
        out.push(format!(
            "- CodeSpecs extracts: {}; gate record: {}",
            level.extracts,
            yes(level.gate_record)
        ));
        out.push(format!("- IR Specs: {}", level.ir));
        out.push(format!("- Gates: {}", gates));
        out.push(format!("- Tests: {}", folders(&level.tests)));
        out.push(format!("- Code: {}", folders(&level.code)));
        out.push(format!(
            "- Phases reached: {}; left out by a change: {} (Phases 7–8 are not visible on disk)",
            join_or_none(&level.phases_reached),
            join_or_none(&level.phases_left_out)
        ));
        out.push(String::new());
    }
    out.join("\n")
}

// --- JSON helpers --------------------------------------------------------------

fn jstr(s: &str) -> Json {
    Json::Str(s.to_string())
}

fn jstrs(items: &[String]) -> Json {
    Json::Array(items.iter().map(|s| jstr(s)).collect())
}

fn obj(pairs: Vec<(&str, Json)>) -> Json {
    Json::Object(pairs.into_iter().map(|(k, v)| (k.to_string(), v)).collect())
}
