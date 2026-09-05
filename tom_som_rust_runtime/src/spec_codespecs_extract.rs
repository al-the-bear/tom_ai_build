//! `spec_codespecs_extract` — the Phase-4 **specification extract generator**,
//! the machine half of CodeSpecs production (`codespecs_mapping.md` §1.1.1), a
//! faithful port of the Dart `spec_codespecs_extract.dart`.
//!
//! Phase 4 runs in two passes. This surface is the first: for each CodeSpecs
//! area it collects everything in a filled specification document that
//! `@CodeSpecKind` routes to that area, **verbatim and with provenance**, so the
//! second pass — an authoring agent, one prompt per authoring step — writes
//! against a bounded extract rather than against a 652-section document.
//!
//! The boundary between the two passes is a rule, not a preference. This
//! generator may **copy and index**; it may not summarise, rephrase, compose a
//! sentence out of field values, or choose a name — the prohibitions of
//! `codespecs_derivation_contract.md` §2.8 **C1**, which bind the extract
//! generator word for word. The consequence is checkable rather than trusted:
//! every [`CodeSpecsExtractEntry::value`] is a string the document stores, byte
//! for byte, and the conformance corpus asserts it.
//!
//! Three things follow from that and shape the API:
//!
//!   * **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a
//!     class carries `@CodeSpecKind` (feeds code), sits under a `@FollowUpKind`
//!     root (feeds a non-generation process), or carries `@NoArtifact` (feeds
//!     nothing). The trio is exhaustive by construction, so a class carrying
//!     none of them is not "skipped": it is a [`CodeSpecsExtractError`], the
//!     `ROUTE-TOTAL` invariant (`tom_specs_model_rules.md` §10.2) failing loudly
//!     at the one place that depends on it.
//!   * **`@CodeSpecKind` is list-valued** (§9.1), and extracts are **not**
//!     deduplicated across areas: a section feeding three areas appears, whole,
//!     in three extracts. Each area's prompt must be self-sufficient.
//!   * **Every entry carries its provenance** — section id, class, field, the
//!     routing marker that put it here and where that marker was declared — so
//!     the `@DocSpec`/`DocRef` back-links (§9.3) can be written from the extract
//!     alone.
//!
//! The area catalogue ([`CodeSpecsAreaCatalog`]) is an **input**, not a table
//! baked into the runtime: it is the machine-readable form of
//! `codespecs_mapping.md` §4.1 (the parts catalogue), §4.4.3 (the emission
//! slices) and §4.4.6 (the authoring steps), authored once and read by all nine
//! runtimes. Carrying it beside the content is what stops an agent having to
//! open the mapping document to find out what `CE-FM` means.
//!
//! Rust has no exceptions, so where the Dart reference *throws*
//! [`CodeSpecsExtractError`] this port returns a `Result` — the same split the
//! rest of the crate uses (see
//! [`SpecNodeCreator`](crate::spec_node_creation::SpecNodeCreator)).

use std::collections::HashSet;
use std::fmt;

use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_model::{
    SpecClass, SpecField, SpecModel, SpecRoot, SPEC_FIELD_KIND_COMPLEX, SPEC_FIELD_KIND_CONTENT,
    SPEC_FIELD_KIND_ENUM, SPEC_FIELD_KIND_FORM, SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SCALAR,
    SPEC_FIELD_KIND_SECTION,
};
use crate::spec_paths::spec_path_join;
use crate::spec_reflection::SpecReflection;

/// The version of the emitted extract artifact's on-disk shape. Bumped when the
/// YAML or Markdown layout changes in a way a reader could notice.
///
/// 2: entries carry `headline` — the enclosing section instance's headline,
/// copy-only (stored headline, else the `@Headline` type default, else null).
///
/// 3: entries carry `instanceId` — the nearest enclosing list-item instance's
/// **stored** section id (the `<!--[…]-->` id the document serializes),
/// copy-only; null when no enclosing instance stores one.
pub const CODE_SPECS_EXTRACT_FORMAT: i64 = 3;

/// The annotation names of the three routing verdicts (`codespecs_mapping.md`
/// §8.3). All three ride the generic annotation bag in every SOM runtime (§8.4),
/// so they are read by name rather than through a meta slot.
pub const CODE_SPEC_KIND_ANNOTATION: &str = "CodeSpecKind";

/// See [`CODE_SPEC_KIND_ANNOTATION`].
pub const FOLLOW_UP_KIND_ANNOTATION: &str = "FollowUpKind";

/// See [`CODE_SPEC_KIND_ANNOTATION`].
pub const NO_ARTIFACT_ANNOTATION: &str = "NoArtifact";

/// Which of the three `codespecs_mapping.md` §8.3 verdicts a class carries.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CodeSpecsRoutingVerdict {
    /// `@CodeSpecKind(List<CodeSpecPart>)` — the section's content is shown to
    /// every named area's extract.
    FeedsCode,

    /// `@FollowUpKind(List<FollowUpProcess>)` — the section is delivered by a
    /// non-generation process. The whole subtree is excluded from every extract.
    FeedsProcess,

    /// `@NoArtifact(NoArtifactReason)` — the section deliberately produces no
    /// downstream artifact. Its own leaves contribute nothing; its children are
    /// still routed individually (that is what `container` means).
    FeedsNothing,

    /// A `@Document` root carrying no verdict. Structurally exempt from
    /// `ROUTE-TOTAL`: a root is the document, not a section of it.
    DocumentRoot,

    /// No verdict, and not a `@Document` root — a `ROUTE-TOTAL` violation, and
    /// the reason [`CodeSpecsExtractor::extract_all`] fails.
    Unrouted,
}

impl CodeSpecsRoutingVerdict {
    /// The portable name of this verdict, identical to the Dart enum's `.name`
    /// (the conformance corpus pins these strings).
    pub fn name(&self) -> &'static str {
        match self {
            CodeSpecsRoutingVerdict::FeedsCode => "feedsCode",
            CodeSpecsRoutingVerdict::FeedsProcess => "feedsProcess",
            CodeSpecsRoutingVerdict::FeedsNothing => "feedsNothing",
            CodeSpecsRoutingVerdict::DocumentRoot => "documentRoot",
            CodeSpecsRoutingVerdict::Unrouted => "unrouted",
        }
    }
}

impl fmt::Display for CodeSpecsRoutingVerdict {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}

/// The verdict recorded for one class node of the walked document, with the
/// provenance of the marker that decided it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsRouting {
    /// The document path of the node the verdict was computed for.
    pub path: String,

    /// The model class at [`Self::path`].
    pub class_name: String,

    /// Which verdict the class carries.
    pub verdict: CodeSpecsRoutingVerdict,

    /// The verdict's payload, verbatim from the annotation: the `CodeSpecPart.*`
    /// values for [`CodeSpecsRoutingVerdict::FeedsCode`], the
    /// `FollowUpProcess.*` values for [`CodeSpecsRoutingVerdict::FeedsProcess`],
    /// the single `NoArtifactReason.*` for
    /// [`CodeSpecsRoutingVerdict::FeedsNothing`], and empty for the two verdicts
    /// that have no marker.
    pub values: Vec<String>,

    /// The marker's optional `note`, verbatim; `None` when it carries none.
    pub note: Option<String>,

    /// Where the marker was declared — the class name, or `Class.field` when a
    /// field-level `@CodeSpecKind` overrode its class. Empty when there is no
    /// marker.
    pub declared_at: String,
}

impl fmt::Display for CodeSpecsRouting {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "CodeSpecsRouting({}, {}, {})",
            self.path,
            self.class_name,
            self.verdict.name()
        )
    }
}

/// One extract entry: a single value the specification document stores, with
/// everything needed to trace it back (`codespecs_mapping.md` §1.1.1, "Entry").
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsExtractEntry {
    /// The `CE-*` code of the area this entry was collected for.
    pub area_code: String,

    /// The section id of the leaf the value sits on (`@SectionId`, else the
    /// model field name).
    pub section_id: String,

    /// The enclosing section instance's headline, copy-only like `value`: the
    /// document's **stored** headline for the class node the leaf sits under
    /// (YRD3), else the class's `@Headline` type default (YRD4), else `None`.
    /// Gives naming rule N1 a real source — never a derivation.
    pub headline: Option<String>,
    /// The nearest enclosing list-item instance's **stored** section id (the
    /// `<!--[…]-->` id the document serializes), copy-only auxiliary trace
    /// data; `None` when no enclosing instance stores one. The render-time
    /// positional default is a derivation and is never carried. A `DocRef`
    /// back-link still names the extract token, not this id
    /// (`codespecs_mapping.md` §9.3).
    pub instance_id: Option<String>,

    /// The document path of the leaf — the source location.
    pub path: String,

    /// The model class declaring the leaf.
    pub class_name: String,

    /// The model field name of the leaf.
    pub field_name: String,

    /// The form-field name when the value is one field of a `@Form` section;
    /// `None` for a content, enum, scalar or scalar-list leaf.
    pub form_field: Option<String>,

    /// The `CodeSpecPart.*` value that routed this entry here, verbatim.
    pub routed_by: String,

    /// Where that `@CodeSpecKind` was declared — the class name, or
    /// `Class.field` for a field-level override.
    pub routed_at: String,

    /// The `@CodeSpecKind` `note`, verbatim; `None` when it carries none.
    pub routing_note: Option<String>,

    /// The stored value, **verbatim**. Never assembled, reformatted or trimmed.
    pub value: String,
}

impl fmt::Display for CodeSpecsExtractEntry {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "CodeSpecsExtractEntry({}, {})", self.area_code, self.path)
    }
}

/// One emission slice of `codespecs_mapping.md` §4.4.3.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsSlice {
    /// The slice's number, 1–7.
    pub number: i64,

    /// The slice's name as §4.4.3 gives it.
    pub title: String,

    /// The §4.2 project the slice emits into.
    pub project: String,

    /// The slices this one may cite — §4.4.3's across-slice edges. Transitively
    /// closed by [`CodeSpecsAreaCatalog::citable_area_codes`].
    pub cites: Vec<i64>,
}

impl CodeSpecsSlice {
    /// Reads one slice out of its catalogue JSON object.
    pub fn from_json(j: &Json) -> CodeSpecsSlice {
        CodeSpecsSlice {
            number: j.get("number").and_then(|v| v.as_i64()).unwrap_or(0),
            title: j.str_or("title"),
            project: j.str_or("project"),
            cites: int_list(j.get("cites")),
        }
    }
}

/// One row of the `codespecs_mapping.md` §4.1 parts catalogue, plus the §4.4.3
/// slice and §4.4.6 authoring steps that place it. This is the **per-area
/// context** an extract carries beside its content.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsArea {
    /// The permanent registry key — `CE-FM`, `CE-API`. Never reused, never
    /// renamed, and the extract file's name.
    pub code: String,

    /// The §4.1 canonical id — the PascalCase noun (`Form`, `ServerApi`).
    pub canonical_id: String,

    /// The `CodeSpecPart` value, camelCase and **without** the enum prefix
    /// (`form`, `serverApi`).
    pub part: String,

    /// The `Cs*` annotation names of the §4.1 row.
    pub annotations: Vec<String>,

    /// The §4.1 "Built on" cell, verbatim.
    pub built_on: String,

    /// Where the area's spec-authorable attribute surface is stated — a §5.x
    /// citation.
    pub attribute_surface: String,

    /// The §4.4.3 slice(s) the area's emission units sit in. More than one when
    /// the area is split by locus.
    pub slices: Vec<i64>,

    /// The §4.4.6 authoring step(s) that write the area.
    pub authoring_steps: Vec<i64>,

    /// Whether the part is active. A deferred part (§4.3) holds a reserved
    /// `CodeSpecPart` value but has no generated surface, so it gets no extract.
    pub active: bool,
}

impl CodeSpecsArea {
    /// Reads one area row out of its catalogue JSON object.
    pub fn from_json(j: &Json) -> CodeSpecsArea {
        CodeSpecsArea {
            code: j.str_or("code"),
            canonical_id: j.str_or("canonicalId"),
            part: j.str_or("part"),
            annotations: string_list(j.get("annotations")),
            built_on: j.str_or("builtOn"),
            attribute_surface: j.str_or("attributeSurface"),
            slices: int_list(j.get("slices")),
            authoring_steps: int_list(j.get("authoringSteps")),
            active: j.get("active").and_then(|v| v.as_bool()).unwrap_or(true),
        }
    }

    /// The fully-qualified `@CodeSpecKind` value — `CodeSpecPart.form`.
    pub fn kind_value(&self) -> String {
        format!("CodeSpecPart.{}", self.part)
    }
}

impl fmt::Display for CodeSpecsArea {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "CodeSpecsArea({})", self.code)
    }
}

/// The machine-readable form of `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6.
///
/// Authored once, read by all nine runtimes. It is an input rather than a baked
/// table because the catalogue is the mapping document's content: a copy per
/// runtime would be nine things to keep current, and the one thing this quest
/// has learned three times is that a vocabulary duplicated nine ways can be
/// wrong in agreement.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct CodeSpecsAreaCatalog {
    /// Where the catalogue was transcribed from, for the extract header.
    pub source: String,

    /// The §4.4.3 slices, in emission order.
    pub slices: Vec<CodeSpecsSlice>,

    /// The §4.1 areas, in catalogue order. Catalogue order is the tie-break
    /// §4.4.6 rule 2 uses, so it is load-bearing rather than cosmetic.
    pub areas: Vec<CodeSpecsArea>,
}

impl CodeSpecsAreaCatalog {
    /// Reads the catalogue out of its JSON object.
    pub fn from_json(j: &Json) -> CodeSpecsAreaCatalog {
        let slices = j
            .get("slices")
            .and_then(|v| v.as_array())
            .map(|arr| arr.iter().map(CodeSpecsSlice::from_json).collect())
            .unwrap_or_default();
        let areas = j
            .get("areas")
            .and_then(|v| v.as_array())
            .map(|arr| arr.iter().map(CodeSpecsArea::from_json).collect())
            .unwrap_or_default();
        CodeSpecsAreaCatalog {
            source: j.str_or("source"),
            slices,
            areas,
        }
    }

    /// The active areas, in catalogue order — one extract each.
    pub fn active_areas(&self) -> Vec<&CodeSpecsArea> {
        self.areas.iter().filter(|a| a.active).collect()
    }

    /// The area with this `CE-*` code, or `None`.
    pub fn by_code(&self, code: &str) -> Option<&CodeSpecsArea> {
        self.areas.iter().find(|a| a.code == code)
    }

    /// The area a `@CodeSpecKind` value names, or `None`. Accepts both the bare
    /// value (`form`) and the qualified one (`CodeSpecPart.form`), because the
    /// meta carries the qualified spelling and callers reach for the bare one.
    pub fn by_part(&self, value: &str) -> Option<&CodeSpecsArea> {
        let bare = value.strip_prefix("CodeSpecPart.").unwrap_or(value);
        self.areas.iter().find(|a| a.part == bare)
    }

    /// The slice numbered `number`, or `None`.
    pub fn slice_numbered(&self, number: i64) -> Option<&CodeSpecsSlice> {
        self.slices.iter().find(|s| s.number == number)
    }

    /// The §4.2 projects `area`'s code lands in, in slice order.
    ///
    /// Derived from the area's slices rather than authored on the area: §4.4.3
    /// already fixes one project per slice, so a per-area project column would
    /// be a second place for the same fact to be stated — and the areas that
    /// would need it are exactly the locus-split ones, where getting it wrong is
    /// easiest.
    pub fn projects_for(&self, area: &CodeSpecsArea) -> Vec<String> {
        let mut out: Vec<String> = Vec::new();
        for n in &area.slices {
            let project = match self.slice_numbered(*n) {
                Some(s) => &s.project,
                None => continue,
            };
            if project.is_empty() || out.iter().any(|p| p == project) {
                continue;
            }
            out.push(project.clone());
        }
        out
    }

    /// The area codes `area` may cite — every other active area whose emission
    /// units sit in a slice `area`'s slices reach, following §4.4.3's edges
    /// transitively. Within-slice citation is legal, so an area's own slices are
    /// part of the reachable set; the area itself is excluded.
    ///
    /// Derived rather than authored: a hand-kept per-area citation list is a
    /// second source of truth for something the slice graph already decides.
    pub fn citable_area_codes(&self, area: &CodeSpecsArea) -> Vec<String> {
        let mut reachable: HashSet<i64> = HashSet::new();
        let mut stack: Vec<i64> = area.slices.clone();
        while let Some(n) = stack.pop() {
            if !reachable.insert(n) {
                continue;
            }
            if let Some(slice) = self.slice_numbered(n) {
                stack.extend(slice.cites.iter().copied());
            }
        }
        let mut out: Vec<String> = Vec::new();
        for a in &self.areas {
            if !a.active || a.code == area.code {
                continue;
            }
            if a.slices.iter().any(|s| reachable.contains(s)) {
                out.push(a.code.clone());
            }
        }
        out
    }
}

/// One area's extract: the area's context plus every routed entry, in SOM
/// document order.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsExtract {
    /// The area this extract is for.
    pub area: CodeSpecsArea,

    /// The `codespecs_mapping.md` §4.1/§4.4.3 source the catalogue names.
    pub catalog_source: String,

    /// The section segment of the document root the entries were collected from.
    pub document_root: String,

    /// The area codes this area may cite (§4.4.3), for the agent's prompt.
    pub citable_parts: Vec<String>,

    /// The §4.2 projects the area's code lands in (§4.4.3, via the slices).
    pub projects: Vec<String>,

    /// The routed entries, in SOM document order.
    pub entries: Vec<CodeSpecsExtractEntry>,
}

impl CodeSpecsExtract {
    /// The extract's file name stem — `CE-FM.extract`.
    pub fn file_stem(&self) -> String {
        format!("{}.extract", self.area.code)
    }

    /// The artifact of record (`codespecs_mapping.md` §1.1.1). Scalars are
    /// emitted as JSON strings, which are valid YAML 1.2 double-quoted scalars —
    /// so one escaping rule, identical in all nine runtimes, covers every value a
    /// specification can hold.
    pub fn to_yaml(&self) -> String {
        let mut b = String::new();
        writeln_to(
            &mut b,
            &format!(
                "# {}.extract.yaml — generated by spec_codespecs_extract. Do not edit.",
                self.area.code
            ),
        );
        writeln_to(&mut b, "extract:");
        writeln_to(
            &mut b,
            &format!("  formatVersion: {}", CODE_SPECS_EXTRACT_FORMAT),
        );
        writeln_to(
            &mut b,
            &format!("  catalogSource: {}", yaml_string(&self.catalog_source)),
        );
        writeln_to(&mut b, "  area:");
        writeln_to(&mut b, &format!("    code: {}", yaml_string(&self.area.code)));
        writeln_to(
            &mut b,
            &format!("    canonicalId: {}", yaml_string(&self.area.canonical_id)),
        );
        writeln_to(
            &mut b,
            &format!("    part: {}", yaml_string(&self.area.kind_value())),
        );
        writeln_to(
            &mut b,
            &format!(
                "    annotations: {}",
                yaml_string_list(&self.area.annotations)
            ),
        );
        writeln_to(
            &mut b,
            &format!("    builtOn: {}", yaml_string(&self.area.built_on)),
        );
        writeln_to(
            &mut b,
            &format!(
                "    attributeSurface: {}",
                yaml_string(&self.area.attribute_surface)
            ),
        );
        writeln_to(
            &mut b,
            &format!("    slices: {}", yaml_int_list(&self.area.slices)),
        );
        writeln_to(
            &mut b,
            &format!(
                "    authoringSteps: {}",
                yaml_int_list(&self.area.authoring_steps)
            ),
        );
        writeln_to(
            &mut b,
            &format!("    projects: {}", yaml_string_list(&self.projects)),
        );
        writeln_to(
            &mut b,
            &format!(
                "    citableParts: {}",
                yaml_string_list(&self.citable_parts)
            ),
        );
        writeln_to(&mut b, "  document:");
        writeln_to(
            &mut b,
            &format!("    root: {}", yaml_string(&self.document_root)),
        );
        writeln_to(
            &mut b,
            &format!("    entryCount: {}", self.entries.len()),
        );
        if self.entries.is_empty() {
            writeln_to(&mut b, "  entries: []");
            return b;
        }
        writeln_to(&mut b, "  entries:");
        for e in &self.entries {
            writeln_to(
                &mut b,
                &format!("    - sectionId: {}", yaml_string(&e.section_id)),
            );
            writeln_to(
                &mut b,
                &format!(
                    "      headline: {}",
                    yaml_nullable_string(e.headline.as_deref())
                ),
            );
            writeln_to(
                &mut b,
                &format!(
                    "      instanceId: {}",
                    yaml_nullable_string(e.instance_id.as_deref())
                ),
            );
            writeln_to(&mut b, &format!("      path: {}", yaml_string(&e.path)));
            writeln_to(
                &mut b,
                &format!("      className: {}", yaml_string(&e.class_name)),
            );
            writeln_to(
                &mut b,
                &format!("      fieldName: {}", yaml_string(&e.field_name)),
            );
            writeln_to(
                &mut b,
                &format!(
                    "      formField: {}",
                    yaml_nullable_string(e.form_field.as_deref())
                ),
            );
            writeln_to(
                &mut b,
                &format!("      routedBy: {}", yaml_string(&e.routed_by)),
            );
            writeln_to(
                &mut b,
                &format!("      routedAt: {}", yaml_string(&e.routed_at)),
            );
            writeln_to(
                &mut b,
                &format!(
                    "      routingNote: {}",
                    yaml_nullable_string(e.routing_note.as_deref())
                ),
            );
            writeln_to(&mut b, &format!("      value: {}", yaml_string(&e.value)));
        }
        b
    }

    /// The rendered view. Regenerated from the YAML's own data — nothing reads
    /// the Markdown as input — and exists because the agent reads it far better
    /// than it reads YAML.
    pub fn to_markdown(&self) -> String {
        let mut b = String::new();
        writeln_to(
            &mut b,
            &format!("# {} — {}", self.area.code, self.area.canonical_id),
        );
        writeln_to(&mut b, "");
        writeln_to(
            &mut b,
            &format!(
                "Generated by `spec_codespecs_extract` from the specification \
                 document rooted at `{}`.",
                self.document_root
            ),
        );
        writeln_to(
            &mut b,
            &format!(
                "`{}.extract.yaml` beside this file is the artifact of record; \
                 this is a view of it.",
                self.area.code
            ),
        );
        writeln_to(&mut b, "");
        writeln_to(&mut b, "## Area");
        writeln_to(&mut b, "");
        writeln_to(&mut b, "| | |");
        writeln_to(&mut b, "|---|---|");
        writeln_to(&mut b, &format!("| CE code | `{}` |", self.area.code));
        writeln_to(
            &mut b,
            &format!("| Canonical id | `{}` |", self.area.canonical_id),
        );
        writeln_to(
            &mut b,
            &format!(
                "| `@CodeSpecKind` value | `{}` |",
                self.area.kind_value()
            ),
        );
        writeln_to(
            &mut b,
            &format!(
                "| `Cs*` annotations | {} |",
                md_code_list(&self.area.annotations)
            ),
        );
        writeln_to(
            &mut b,
            &format!("| Built on | {} |", md_cell(&self.area.built_on)),
        );
        writeln_to(
            &mut b,
            &format!(
                "| Attribute surface | {} |",
                md_cell(&self.area.attribute_surface)
            ),
        );
        writeln_to(
            &mut b,
            &format!("| Slice(s) | {} |", md_int_list(&self.area.slices)),
        );
        writeln_to(
            &mut b,
            &format!(
                "| Authoring step(s) | {} |",
                md_int_list(&self.area.authoring_steps)
            ),
        );
        writeln_to(
            &mut b,
            &format!("| Project(s) | {} |", md_code_list(&self.projects)),
        );
        writeln_to(
            &mut b,
            &format!("| May cite | {} |", md_code_list(&self.citable_parts)),
        );
        writeln_to(
            &mut b,
            &format!("| Catalogue source | {} |", md_cell(&self.catalog_source)),
        );
        writeln_to(&mut b, "");
        writeln_to(&mut b, &format!("## Entries ({})", self.entries.len()));
        writeln_to(&mut b, "");
        if self.entries.is_empty() {
            writeln_to(
                &mut b,
                &format!(
                    "_No section of this document is routed to `{}`._",
                    self.area.kind_value()
                ),
            );
            return b;
        }
        let mut n = 0;
        for e in &self.entries {
            n += 1;
            let member = match &e.form_field {
                None => e.field_name.clone(),
                Some(ff) => format!("{}.{}", e.field_name, ff),
            };
            writeln_to(
                &mut b,
                &format!("### {}. `{}` — `{}.{}`", n, e.section_id, e.class_name, member),
            );
            writeln_to(&mut b, "");
            if let Some(headline) = &e.headline {
                writeln_to(&mut b, &format!("- headline: {}", md_cell(headline)));
            }
            if let Some(instance_id) = &e.instance_id {
                writeln_to(&mut b, &format!("- instanceId: `{}`", instance_id));
            }
            writeln_to(&mut b, &format!("- path: `{}`", e.path));
            writeln_to(
                &mut b,
                &format!(
                    "- routed by: `{}` declared on `{}`",
                    e.routed_by, e.routed_at
                ),
            );
            if let Some(note) = &e.routing_note {
                writeln_to(&mut b, &format!("- routing note: {}", md_cell(note)));
            }
            writeln_to(&mut b, "");
            let fence = fence_for(&e.value);
            writeln_to(&mut b, &format!("{} text", fence));
            writeln_to(&mut b, &e.value);
            writeln_to(&mut b, &fence);
            writeln_to(&mut b, "");
        }
        b
    }
}

/// Returned when the document cannot be extracted from at all.
///
/// Two causes: a section routed nowhere — `ROUTE-TOTAL`
/// (`tom_specs_model_rules.md` §10.2) failing — and a walk root that cannot be
/// resolved to exactly one (`codespecs_prompt.md` §5). Both are errors rather
/// than skips: a section routed nowhere is a section the agent writing that area
/// never sees, and a walk over the wrong root is every area empty. A silent
/// omission at this boundary is indistinguishable from a specification that
/// genuinely said nothing.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CodeSpecsExtractError {
    /// What went wrong, in one sentence.
    pub message: String,

    /// The document path of the offending node.
    pub path: String,

    /// The model class at [`Self::path`].
    pub class_name: String,
}

impl fmt::Display for CodeSpecsExtractError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "CodeSpecsExtractError: {} ({}, {})",
            self.message, self.path, self.class_name
        )
    }
}

impl std::error::Error for CodeSpecsExtractError {}

/// The two sinks the single walk fills, plus whether an unrouted class is fatal.
///
/// Dart passes two nullable out-parameters down the recursion; Rust cannot hand
/// two `Option<&mut Vec<…>>` through a recursive call without fighting the
/// borrow checker, so they travel together in one owned accumulator. `None`
/// means "this run does not collect that side" exactly as the Dart `null` does.
struct WalkSink {
    routings: Option<Vec<CodeSpecsRouting>>,
    entries: Option<Vec<CodeSpecsExtractEntry>>,
    strict: bool,
}

/// The document path segment a root's values live under.
fn code_specs_root_segment(root: &SpecRoot) -> &str {
    if root.section_id.is_empty() {
        &root.type_
    } else {
        &root.section_id
    }
}

/// Resolves the one root [`CodeSpecsExtractor`] walks — the rule stated on
/// [`CodeSpecsExtractor::new`].
fn resolve_code_specs_root<'m>(
    model: &'m SpecModel,
    document: &SpecDocument,
    root_type: Option<&str>,
) -> Result<&'m SpecRoot, CodeSpecsExtractError> {
    let populated: Vec<&SpecRoot> = model
        .roots
        .iter()
        .filter(|r| document.has_values_under(code_specs_root_segment(r)))
        .collect();
    let names = || {
        model
            .roots
            .iter()
            .map(|r| r.type_.clone())
            .collect::<Vec<_>>()
            .join(", ")
    };
    let populated_types = || {
        populated
            .iter()
            .map(|r| r.type_.clone())
            .collect::<Vec<_>>()
            .join(", ")
    };
    if let Some(want) = root_type.filter(|s| !s.is_empty()) {
        for r in &model.roots {
            if r.type_ != want && code_specs_root_segment(r) != want {
                continue;
            }
            if !populated.is_empty() && !populated.iter().any(|p| std::ptr::eq(*p, r)) {
                return Err(CodeSpecsExtractError {
                    message: format!(
                        "root \"{want}\" holds no value in this document, but {} does — every \
                         extract would come out empty (codespecs_prompt.md §5)",
                        populated_types()
                    ),
                    path: code_specs_root_segment(r).to_string(),
                    class_name: r.type_.clone(),
                });
            }
            return Ok(r);
        }
        return Err(CodeSpecsExtractError {
            message: format!(
                "no document root with type or section id \"{want}\" (have: {})",
                names()
            ),
            path: String::new(),
            class_name: want.to_string(),
        });
    }
    if populated.len() == 1 {
        return Ok(populated[0]);
    }
    if populated.is_empty() {
        if model.roots.len() == 1 {
            return Ok(&model.roots[0]);
        }
        return Err(CodeSpecsExtractError {
            message: format!(
                "document has no populated root to extract from; pass rootType to choose one \
                 (have: {})",
                names()
            ),
            path: String::new(),
            class_name: String::new(),
        });
    }
    Err(CodeSpecsExtractError {
        message: format!(
            "document has {} populated roots ({}); pass rootType to choose one",
            populated.len(),
            populated_types()
        ),
        path: String::new(),
        class_name: String::new(),
    })
}

/// Produces one [`CodeSpecsExtract`] per active area from a filled specification
/// document.
///
/// A Phase-4 run extracts from **one** specification document, so the walk has
/// exactly one root ([`Self::root`], `codespecs_prompt.md` §5). The two ways to
/// get that wrong are both closed here rather than left to the caller: the walk
/// cannot union every `@Document` root, because there is no way to ask for that;
/// and naming a root the document never populates — the `D13CodeSpecsProjection`
/// mistake, whose `CGP/…` path space misses a blueprint's `SBP/…` values and
/// yields every area silently empty — is a [`CodeSpecsExtractError`] rather than
/// an empty result.
pub struct CodeSpecsExtractor<'d, 'm> {
    /// The filled specification document.
    pub document: &'d SpecDocument,

    /// The model describing the document's structure and carrying the routing
    /// verdicts, wrapped in the reflection surface that reads its segments.
    pub reflection: SpecReflection<'m>,

    /// The area catalogue — `codespecs_mapping.md` §4.1/§4.4.3/§4.4.6.
    pub catalog: CodeSpecsAreaCatalog,

    /// The one `@Document` root this extractor walks.
    ///
    /// Resolved once, by the constructor, so [`Self::routings`] and
    /// [`Self::extract_all`] cannot disagree about what was walked.
    pub root: &'m SpecRoot,
}

impl<'d, 'm> CodeSpecsExtractor<'d, 'm> {
    /// Binds an extractor to a document, a reflection surface and a catalogue.
    ///
    /// `root_type` names the specification document's own root, by type name or
    /// by section id. `None` (or `Some("")`) means "omitted": the document's
    /// single **populated** root is used — the root under which the document
    /// holds any value — falling back to the model's only root when the document
    /// is empty, so an unfilled single-root model still reaches the routing walk.
    ///
    /// Fails with [`CodeSpecsExtractError`] when the root cannot be resolved to
    /// exactly one: an unknown `root_type`, a `root_type` holding no value while
    /// another root does, more than one populated root, or an empty document over
    /// a multi-root model.
    pub fn new(
        document: &'d SpecDocument,
        reflection: SpecReflection<'m>,
        catalog: CodeSpecsAreaCatalog,
        root_type: Option<&str>,
    ) -> Result<CodeSpecsExtractor<'d, 'm>, CodeSpecsExtractError> {
        let root = resolve_code_specs_root(reflection.model, document, root_type)?;
        Ok(CodeSpecsExtractor {
            document,
            reflection,
            catalog,
            root,
        })
    }

    /// Binds an extractor to a document and a model (convenience for
    /// [`CodeSpecsExtractor::new`] with a fresh [`SpecReflection`]).
    pub fn for_model(
        document: &'d SpecDocument,
        model: &'m SpecModel,
        catalog: CodeSpecsAreaCatalog,
        root_type: Option<&str>,
    ) -> Result<CodeSpecsExtractor<'d, 'm>, CodeSpecsExtractError> {
        CodeSpecsExtractor::new(document, SpecReflection::new(model), catalog, root_type)
    }

    /// The model describing the document's structure.
    pub fn model(&self) -> &'m SpecModel {
        self.reflection.model
    }

    /// The verdict of every class node the walk reaches, in document order.
    ///
    /// Computed by the same walk [`Self::extract_all`] uses, so "what was routed
    /// where" and "what landed in which extract" cannot disagree. Unlike
    /// [`Self::extract_all`] this does **not** fail on an unrouted class — it
    /// reports it, which is what a diagnostic is for.
    pub fn routings(&self) -> Vec<CodeSpecsRouting> {
        let mut sink = WalkSink {
            routings: Some(Vec::new()),
            entries: None,
            strict: false,
        };
        // Cannot fail: `strict` is false, and the unrouted verdict is the only
        // error the walk raises.
        let _ = self.walk_all(&mut sink);
        sink.routings.unwrap_or_default()
    }

    /// One extract per active area, in catalogue order.
    ///
    /// Fails with [`CodeSpecsExtractError`] on the first class the walk reaches
    /// that carries none of the three verdicts.
    pub fn extract_all(&self) -> Result<Vec<CodeSpecsExtract>, CodeSpecsExtractError> {
        let mut sink = WalkSink {
            routings: None,
            entries: Some(Vec::new()),
            strict: true,
        };
        self.walk_all(&mut sink)?;
        let entries = sink.entries.unwrap_or_default();
        let root = self.reflection.root_segment(self.root);
        let mut out = Vec::new();
        for area in self.catalog.active_areas() {
            out.push(CodeSpecsExtract {
                area: area.clone(),
                catalog_source: self.catalog.source.clone(),
                document_root: root.clone(),
                citable_parts: self.catalog.citable_area_codes(area),
                projects: self.catalog.projects_for(area),
                entries: entries
                    .iter()
                    .filter(|e| e.area_code == area.code)
                    .cloned()
                    .collect(),
            });
        }
        Ok(out)
    }

    /// The single extract for `area_code`, or `None` when the catalogue holds no
    /// such active area.
    pub fn extract_for(
        &self,
        area_code: &str,
    ) -> Result<Option<CodeSpecsExtract>, CodeSpecsExtractError> {
        Ok(self
            .extract_all()?
            .into_iter()
            .find(|e| e.area.code == area_code))
    }

    // --- the walk ------------------------------------------------------------

    fn walk_all(&self, sink: &mut WalkSink) -> Result<(), CodeSpecsExtractError> {
        let mut ancestor_types = HashSet::new();
        ancestor_types.insert(self.root.type_.clone());
        self.walk(
            sink,
            &self.reflection.root_segment(self.root),
            self.model().class_named(&self.root.type_),
            &ancestor_types,
            None,
        )
    }

    fn walk(
        &self,
        sink: &mut WalkSink,
        path: &str,
        cls: Option<&SpecClass>,
        ancestor_types: &HashSet<String>,
        enclosing_instance_id: Option<&str>,
    ) -> Result<(), CodeSpecsExtractError> {
        let cls = match cls {
            Some(c) => c,
            None => return Ok(()),
        };
        let routing = self.verdict_of(cls, path);
        if let Some(routings) = sink.routings.as_mut() {
            routings.push(routing.clone());
        }

        match routing.verdict {
            // the whole subtree is delivered by a non-generation process
            CodeSpecsRoutingVerdict::FeedsProcess => return Ok(()),
            CodeSpecsRoutingVerdict::Unrouted => {
                if sink.strict {
                    return Err(CodeSpecsExtractError {
                        message: "section carries none of the three routing verdicts \
                                  (@CodeSpecKind / @FollowUpKind / @NoArtifact) — \
                                  tom_specs_model_rules.md §10.2 ROUTE-TOTAL"
                            .to_string(),
                        path: path.to_string(),
                        class_name: cls.name.clone(),
                    });
                }
            }
            CodeSpecsRoutingVerdict::FeedsCode
            | CodeSpecsRoutingVerdict::FeedsNothing
            | CodeSpecsRoutingVerdict::DocumentRoot => {}
        }

        let class_routing = if routing.verdict == CodeSpecsRoutingVerdict::FeedsCode {
            Some(routing)
        } else {
            None
        };

        // The enclosing section instance's headline, resolved once per class
        // node (YRD3 stored > YRD4 type default > None) and copied onto every
        // entry emitted below it. Copy-only — never a name derivation.
        let headline: Option<String> = match self.document.headline(path) {
            Some(stored) => Some(stored.clone()),
            None if !cls.headline.is_empty() => Some(cls.headline.clone()),
            None => None,
        };

        // The nearest enclosing list-item instance's **stored** section id,
        // copied onto every entry emitted below it. Only a stored id is ever
        // carried — the render-time positional default is a derivation, and a
        // derivation is what C1 forbids — so an id-less instance yields None,
        // never "CARD-2".
        let instance_id: Option<String> = match self.document.item_section_id(path) {
            Some(stored) => Some(stored.clone()),
            None => enclosing_instance_id.map(|s| s.to_string()),
        };

        for field in &cls.fields {
            let field_path = spec_path_join(path, &self.reflection.field_segment(field));
            let own = self.field_routing(cls, field);
            let field_routing = own.as_ref().or(class_routing.as_ref());

            match field.kind.as_str() {
                SPEC_FIELD_KIND_CONTENT | SPEC_FIELD_KIND_ENUM | SPEC_FIELD_KIND_SCALAR => {
                    self.emit_value(
                        sink,
                        field_routing,
                        cls,
                        field,
                        &field_path,
                        None,
                        headline.as_deref(),
                        instance_id.as_deref(),
                        self.document.content(&field_path),
                    );
                }
                SPEC_FIELD_KIND_FORM => {
                    for ff in &field.form_fields {
                        self.emit_value(
                            sink,
                            field_routing,
                            cls,
                            field,
                            &field_path,
                            Some(&ff.name),
                            headline.as_deref(),
                            instance_id.as_deref(),
                            self.document.form_field(&field_path, &ff.name),
                        );
                    }
                }
                SPEC_FIELD_KIND_LIST => {
                    for item_path in self.document.list_items(&field_path) {
                        if field.element_is_complex
                            && !field.element_type.is_empty()
                            && !ancestor_types.contains(&field.element_type)
                        {
                            let mut next = ancestor_types.clone();
                            next.insert(field.element_type.clone());
                            self.walk(
                                sink,
                                &item_path,
                                self.model().class_named(&field.element_type),
                                &next,
                                instance_id.as_deref(),
                            )?;
                        } else {
                            // A scalar item is itself an instance of the list:
                            // its own stored id is the most precise
                            // enclosing-instance id its entry can carry.
                            let item_instance: Option<&str> = self
                                .document
                                .item_section_id(&item_path)
                                .map(|s| s.as_str())
                                .or(instance_id.as_deref());
                            self.emit_value(
                                sink,
                                field_routing,
                                cls,
                                field,
                                &item_path,
                                None,
                                headline.as_deref(),
                                item_instance,
                                self.document.content(&item_path),
                            );
                        }
                    }
                }
                SPEC_FIELD_KIND_COMPLEX | SPEC_FIELD_KIND_SECTION => {
                    // An unresolvable or already-visited type ends the descent:
                    // the class graph is cyclic and the walk is not.
                    if field.type_.is_empty() || ancestor_types.contains(&field.type_) {
                        continue;
                    }
                    let mut next = ancestor_types.clone();
                    next.insert(field.type_.clone());
                    self.walk(
                        sink,
                        &field_path,
                        self.model().class_named(&field.type_),
                        &next,
                        instance_id.as_deref(),
                    )?;
                }
                _ => {}
            }
        }
        Ok(())
    }

    /// Appends one entry **per area the routing names** — never deduplicated,
    /// because each area's prompt must be self-sufficient (§1.1.1).
    #[allow(clippy::too_many_arguments)]
    fn emit_value(
        &self,
        sink: &mut WalkSink,
        routing: Option<&CodeSpecsRouting>,
        cls: &SpecClass,
        field: &SpecField,
        path: &str,
        form_field: Option<&str>,
        headline: Option<&str>,
        instance_id: Option<&str>,
        value: Option<&String>,
    ) {
        let (entries, routing) = match (sink.entries.as_mut(), routing) {
            (Some(entries), Some(routing)) => (entries, routing),
            _ => return,
        };
        let value = match value {
            Some(v) if !v.is_empty() => v,
            _ => return,
        };
        for kind in &routing.values {
            let area = match self.catalog.by_part(kind) {
                Some(a) if a.active => a,
                _ => continue,
            };
            entries.push(CodeSpecsExtractEntry {
                area_code: area.code.clone(),
                section_id: self.reflection.field_segment(field),
                headline: headline.map(|h| h.to_string()),
                instance_id: instance_id.map(|s| s.to_string()),
                path: path.to_string(),
                class_name: cls.name.clone(),
                field_name: field.name.clone(),
                form_field: form_field.map(|f| f.to_string()),
                routed_by: area.kind_value(),
                routed_at: routing.declared_at.clone(),
                routing_note: routing.note.clone(),
                value: value.clone(),
            });
        }
    }

    // --- verdict resolution --------------------------------------------------

    /// The verdict `cls` carries. The three markers are mutually exclusive
    /// (`KIND-EXCLUSIVE`), so the order they are tested in is a readability
    /// choice rather than a precedence rule.
    ///
    /// Read through the model's own annotation accessors
    /// ([`SpecClass::code_spec_kind`] and friends) rather than off the raw
    /// annotation bag: they already know that `@CodeSpecKind`'s list argument is
    /// `kinds` while `@FollowUpKind`'s is `processes`, and they strip the enum
    /// prefix, so the codes here are bare whatever spelling the meta chose. Two
    /// readers of the same annotations would be two chances to disagree.
    fn verdict_of(&self, cls: &SpecClass, path: &str) -> CodeSpecsRouting {
        if let Some(code) = cls.code_spec_kind() {
            return CodeSpecsRouting {
                path: path.to_string(),
                class_name: cls.name.clone(),
                verdict: CodeSpecsRoutingVerdict::FeedsCode,
                values: code.kinds,
                note: code.note,
                declared_at: cls.name.clone(),
            };
        }
        if let Some(follow_up) = cls.follow_up_kind() {
            return CodeSpecsRouting {
                path: path.to_string(),
                class_name: cls.name.clone(),
                verdict: CodeSpecsRoutingVerdict::FeedsProcess,
                values: follow_up.kinds,
                note: follow_up.note,
                declared_at: cls.name.clone(),
            };
        }
        if let Some(none) = cls.no_artifact() {
            return CodeSpecsRouting {
                path: path.to_string(),
                class_name: cls.name.clone(),
                verdict: CodeSpecsRoutingVerdict::FeedsNothing,
                values: vec![none.reason],
                note: none.note,
                declared_at: cls.name.clone(),
            };
        }
        let verdict = if cls.has_annotation("Document") {
            CodeSpecsRoutingVerdict::DocumentRoot
        } else {
            CodeSpecsRoutingVerdict::Unrouted
        };
        CodeSpecsRouting {
            path: path.to_string(),
            class_name: cls.name.clone(),
            verdict,
            values: Vec::new(),
            note: None,
            declared_at: String::new(),
        }
    }

    /// A field-level `@CodeSpecKind`, which overrides its class's routing for
    /// that field alone; `None` when the field carries none.
    fn field_routing(&self, cls: &SpecClass, field: &SpecField) -> Option<CodeSpecsRouting> {
        let code = field.code_spec_kind()?;
        Some(CodeSpecsRouting {
            path: String::new(),
            class_name: cls.name.clone(),
            verdict: CodeSpecsRoutingVerdict::FeedsCode,
            values: code.kinds,
            note: code.note,
            declared_at: format!("{}.{}", cls.name, field.name),
        })
    }
}

// --- shared emission helpers ----------------------------------------------

fn string_list(raw: Option<&Json>) -> Vec<String> {
    match raw.and_then(|v| v.as_array()) {
        Some(arr) => arr
            .iter()
            .map(|e| e.as_str().map(|s| s.to_string()).unwrap_or_default())
            .collect(),
        None => Vec::new(),
    }
}

fn int_list(raw: Option<&Json>) -> Vec<i64> {
    match raw.and_then(|v| v.as_array()) {
        Some(arr) => arr.iter().filter_map(|e| e.as_i64()).collect(),
        None => Vec::new(),
    }
}

/// Appends `line` plus a newline — the Dart `StringBuffer.writeln`.
fn writeln_to(b: &mut String, line: &str) {
    b.push_str(line);
    b.push('\n');
}

/// A JSON string literal, which is also a valid YAML 1.2 double-quoted scalar.
/// Hand-written rather than delegated to a JSON encoder so the eight ports have
/// one rule to transcribe rather than nine encoders to hope agree.
fn yaml_string(value: &str) -> String {
    let mut b = String::from("\"");
    for ch in value.chars() {
        match ch {
            '"' => b.push_str("\\\""),
            '\\' => b.push_str("\\\\"),
            '\u{0008}' => b.push_str("\\b"),
            '\u{000C}' => b.push_str("\\f"),
            '\n' => b.push_str("\\n"),
            '\r' => b.push_str("\\r"),
            '\t' => b.push_str("\\t"),
            c if (c as u32) < 0x20 => b.push_str(&format!("\\u{:04x}", c as u32)),
            c => b.push(c),
        }
    }
    b.push('"');
    b
}

fn yaml_nullable_string(value: Option<&str>) -> String {
    match value {
        None => "null".to_string(),
        Some(v) => yaml_string(v),
    }
}

fn yaml_string_list(values: &[String]) -> String {
    let parts: Vec<String> = values.iter().map(|v| yaml_string(v)).collect();
    format!("[{}]", parts.join(", "))
}

fn yaml_int_list(values: &[i64]) -> String {
    let parts: Vec<String> = values.iter().map(|v| v.to_string()).collect();
    format!("[{}]", parts.join(", "))
}

/// A markdown table cell: newlines folded to a space (a cell cannot hold one)
/// and `|` escaped. Applied only to catalogue prose, never to a stored value —
/// values go into fenced blocks, where they stay verbatim.
fn md_cell(value: &str) -> String {
    value.replace('\n', " ").replace('|', "\\|")
}

fn md_code_list(values: &[String]) -> String {
    if values.is_empty() {
        return "—".to_string();
    }
    values
        .iter()
        .map(|v| format!("`{}`", v))
        .collect::<Vec<String>>()
        .join(", ")
}

fn md_int_list(values: &[i64]) -> String {
    if values.is_empty() {
        return "—".to_string();
    }
    values
        .iter()
        .map(|v| v.to_string())
        .collect::<Vec<String>>()
        .join(", ")
}

/// The shortest backtick fence that cannot be closed by `value`'s own content.
fn fence_for(value: &str) -> String {
    let mut longest = 0;
    let mut run = 0;
    for ch in value.chars() {
        if ch == '`' {
            run += 1;
            if run > longest {
                longest = run;
            }
        } else {
            run = 0;
        }
    }
    let width = if longest >= 3 { longest + 1 } else { 3 };
    "`".repeat(width)
}
