//! `spec_node_creation` — meta-model-validated node creation for a live
//! [`SpecDocument`] (llm_and_d4rt_tools.md §5 "constrained node creation"), a
//! faithful port of the Dart `spec_node_creation.dart`.
//!
//! Every node a script or tool adds passes through this single gate, so the
//! document can only grow in ways the [`SpecModel`] permits for the parent. The
//! rules are the `tom_specs_model_rules.md` §10.2 *structural* rules — but read
//! from the model meta-data the runtime already carries ([`SpecField::kind`],
//! [`SpecField::section_id_pattern`], [`SpecField::min`]), **not** from the
//! analyzer-backed authoring validator in `tom_specs_clitool`. The clitool
//! validates the *authored model graph*; this validates a *document mutation
//! against that model*. They are different layers and the runtime keeps its
//! dependency-free footprint.
//!
//! [`check_add_node`] is the single, value-aware rule-check entry point
//! (exported for reuse by editors and the engine); [`SpecNodeCreator::add`]
//! applies it and performs the mutation only when it returns `None`, so an
//! illegal add never touches the tree.
//!
//! Rust has no exceptions, so where the Dart reference *throws*
//! [`SpecCreationError`] this port returns `Result<String, SpecCreationError>`
//! — the same split the rest of the crate uses (see
//! [`SpecEditor`](crate::spec_editor::SpecEditor)). Rust also has no optional
//! parameters, so Dart's `add(parent, child, {itemId, date})` becomes three
//! methods exactly as [`SomList::add`](crate::som_facade::SomList::add) does
//! (decision AG-D2): [`SpecNodeCreator::add`] (generate an id, today's date),
//! [`SpecNodeCreator::add_on`] (generate, explicit date) and
//! [`SpecNodeCreator::add_with_id`] (explicit id override — the date is unused
//! when the caller supplies the id).

use std::fmt;

use crate::spec_document::SpecDocument;
use crate::spec_model::{SpecClass, SpecField, SpecModel, SPEC_FIELD_KIND_LIST};
use crate::spec_paths::spec_path_join;
use crate::spec_reflection::SpecReflection;
use crate::spec_section_id::{
    generate_list_item_section_id, section_id_pattern_prefix, today_month_day,
};

/// Why an attempted node creation is illegal against the model.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SpecCreationCode {
    /// The parent path does not resolve to a node that can own named children
    /// (it is dangling, a leaf, or a list — lists grow through their own field,
    /// not by adding children to the list node).
    NotAContainer,

    /// The requested child segment names no field on the parent's class.
    UnknownChild,

    /// A caller-proposed list-item id does not keep the prefix mandated by the
    /// list's `@SectionIdPattern` (AA1 criterion 3/5: an override replaces the
    /// suffix, the pattern prefix stays).
    PatternMismatch,

    /// A caller-proposed list-item id collides with another item's section id in
    /// the same list (AA1 criterion 5: section ids within a list must be
    /// unique).
    DuplicateSectionId,

    /// A single-valued (non-list) child already holds a value — only one is
    /// allowed.
    CardinalityExceeded,
}

impl SpecCreationCode {
    /// The portable name of this code, identical to the Dart enum's `.name` (the
    /// conformance corpus pins these strings).
    pub fn name(&self) -> &'static str {
        match self {
            SpecCreationCode::NotAContainer => "notAContainer",
            SpecCreationCode::UnknownChild => "unknownChild",
            SpecCreationCode::PatternMismatch => "patternMismatch",
            SpecCreationCode::DuplicateSectionId => "duplicateSectionId",
            SpecCreationCode::CardinalityExceeded => "cardinalityExceeded",
        }
    }
}

impl fmt::Display for SpecCreationCode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}

/// A rejected node-creation attempt. Returned as the `Err` of
/// [`SpecNodeCreator::add`] and as the `Some` of [`check_add_node`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecCreationError {
    /// The parent path the add was attempted under.
    pub parent_path: String,

    /// The child section segment that was requested.
    pub child_segment: String,

    /// Why the add is illegal.
    pub code: SpecCreationCode,

    /// A human-readable explanation.
    pub message: String,
}

impl SpecCreationError {
    /// Builds a rejection for `parent_path` → `child_segment`.
    pub fn new(
        parent_path: &str,
        child_segment: &str,
        code: SpecCreationCode,
        message: &str,
    ) -> SpecCreationError {
        SpecCreationError {
            parent_path: parent_path.to_string(),
            child_segment: child_segment.to_string(),
            code,
            message: message.to_string(),
        }
    }
}

impl fmt::Display for SpecCreationError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "SpecCreationError({}) under \"{}\" → \"{}\": {}",
            self.code.name(),
            self.parent_path,
            self.child_segment,
            self.message
        )
    }
}

impl std::error::Error for SpecCreationError {}

/// Validates adding child `child_segment` under `parent_path` against `model`,
/// consulting `document` for cardinality. Returns `None` when the add is legal,
/// otherwise the [`SpecCreationError`] describing the first rule it breaks.
///
/// `item_id` is the caller-proposed list-item section id (`None` when the id is
/// to be generated); it is only consulted for list fields.
///
/// This performs **no mutation**; it is the shared rule-check that
/// [`SpecNodeCreator::add`] (and any editor) calls before touching the tree.
pub fn check_add_node(
    model: &SpecModel,
    document: &SpecDocument,
    parent_path: &str,
    child_segment: &str,
    item_id: Option<&str>,
) -> Option<SpecCreationError> {
    let refl = SpecReflection::new(model);

    // 1. The parent must resolve to a class-bearing node (root / complex /
    //    section / complex list item). Leaves, lists and dangling paths cannot
    //    own named children.
    let parent = refl.resolve(parent_path);
    let parent_class = match &parent {
        Some(res) => match &res.target_class {
            Some(cls) => cls,
            None => {
                return Some(SpecCreationError::new(
                    parent_path,
                    child_segment,
                    SpecCreationCode::NotAContainer,
                    &format!(
                        "parent path is a {} and cannot own child nodes",
                        res.kind
                    ),
                ))
            }
        },
        None => {
            return Some(SpecCreationError::new(
                parent_path,
                child_segment,
                SpecCreationCode::NotAContainer,
                "parent path does not resolve and cannot own child nodes",
            ))
        }
    };

    // 2. The child segment must name a declared field of the parent's class.
    let field = match field_for_segment(parent_class, child_segment) {
        Some(f) => f,
        None => {
            return Some(SpecCreationError::new(
                parent_path,
                child_segment,
                SpecCreationCode::UnknownChild,
                &format!(
                    "\"{}\" is not a child of {}",
                    child_segment, parent_class.name
                ),
            ))
        }
    };

    let child_path = spec_path_join(parent_path, child_segment);

    if field.kind == SPEC_FIELD_KIND_LIST {
        // 3. List item: validate a caller-proposed id. Lists have no upper
        //    bound, so there is no cardinality check. A missing id is generated
        //    later (criterion 3); an explicit override must keep the pattern
        //    prefix (criterion 3) and stay unique within the list (criterion 5).
        let pattern = &field.section_id_pattern;
        if let Some(id) = item_id {
            if !pattern.is_empty() {
                let prefix = section_id_pattern_prefix(pattern);
                if !id.starts_with(&prefix) {
                    return Some(SpecCreationError::new(
                        parent_path,
                        child_segment,
                        SpecCreationCode::PatternMismatch,
                        &format!(
                            "item id \"{}\" does not keep the pattern prefix \"{}\"",
                            id, prefix
                        ),
                    ));
                }
                if document
                    .list_item_section_ids(&child_path)
                    .iter()
                    .any(|existing| existing == id)
                {
                    return Some(SpecCreationError::new(
                        parent_path,
                        child_segment,
                        SpecCreationCode::DuplicateSectionId,
                        &format!(
                            "item id \"{}\" is already used in list \"{}\"",
                            id, child_path
                        ),
                    ));
                }
            }
        }
        return None;
    }

    // 4. Single-valued child (complex / section / form / content / enum /
    //    scalar): cardinality is exactly one, so reject if a value already
    //    exists at or beneath the child path.
    if document.has_values_under(&child_path) {
        return Some(SpecCreationError::new(
            parent_path,
            child_segment,
            SpecCreationCode::CardinalityExceeded,
            &format!(
                "a {} child already exists at \"{}\"",
                field.kind, child_path
            ),
        ));
    }
    None
}

/// Applies [`check_add_node`] and performs the constrained mutation.
///
/// Holds the model/document pair so callers add children by parent path and
/// child segment without re-supplying the context each time. The document is
/// borrowed **mutably** for the creator's lifetime (Dart shares one object by
/// reference; Rust makes the exclusive access explicit), exactly as
/// [`SpecEditor`](crate::spec_editor::SpecEditor) does.
pub struct SpecNodeCreator<'d, 'm> {
    pub document: &'d mut SpecDocument,
    pub reflection: SpecReflection<'m>,
}

impl<'d, 'm> SpecNodeCreator<'d, 'm> {
    /// Binds a creator to a document and a reflection surface.
    pub fn new(
        document: &'d mut SpecDocument,
        reflection: SpecReflection<'m>,
    ) -> SpecNodeCreator<'d, 'm> {
        SpecNodeCreator {
            document,
            reflection,
        }
    }

    /// Binds a creator to a document and a model (convenience for
    /// [`SpecNodeCreator::new`] with a fresh [`SpecReflection`]).
    pub fn for_model(
        document: &'d mut SpecDocument,
        model: &'m SpecModel,
    ) -> SpecNodeCreator<'d, 'm> {
        SpecNodeCreator::new(document, SpecReflection::new(model))
    }

    /// The model this creator validates against.
    pub fn model(&self) -> &'m SpecModel {
        self.reflection.model
    }

    /// Adds child `child_segment` under `parent_path` and returns the new node's
    /// path, dating a generated list-item section id with today's `(month,
    /// day)`. See [`SpecNodeCreator::add_on`] for the full contract.
    pub fn add(
        &mut self,
        parent_path: &str,
        child_segment: &str,
    ) -> Result<String, SpecCreationError> {
        let (month, day) = today_month_day();
        self.add_internal(parent_path, child_segment, None, month, day)
    }

    /// Adds child `child_segment` under `parent_path` and returns the new node's
    /// path. For a list field this appends a fresh item (`…/<segment>-<seq>`),
    /// assigning its **section id** (AA1 criteria 3–5) generated from the
    /// field's `@SectionIdPattern` using `(month, day)` for the two-letter-date
    /// component. Lists with no pattern (scalar lists) get no section id. For a
    /// single-valued field it returns the child path without mutating the sparse
    /// store (the caller then sets its value).
    ///
    /// Returns `Err(`[`SpecCreationError`]`)` — leaving the document untouched —
    /// when the add violates a structural rule (see [`SpecCreationCode`]).
    pub fn add_on(
        &mut self,
        parent_path: &str,
        child_segment: &str,
        month: i64,
        day: i64,
    ) -> Result<String, SpecCreationError> {
        self.add_internal(parent_path, child_segment, None, month, day)
    }

    /// Like [`SpecNodeCreator::add_on`] but with an explicit list-item section id
    /// override (AA1 criterion 5), validated by [`check_add_node`] to keep the
    /// pattern prefix and stay unique in the list. No date is taken: the
    /// two-letter-date component only feeds a *generated* id.
    ///
    /// A pattern-less list ignores the override, exactly as the Dart reference
    /// does (it appends without a section id).
    pub fn add_with_id(
        &mut self,
        parent_path: &str,
        child_segment: &str,
        item_id: &str,
    ) -> Result<String, SpecCreationError> {
        // The date is unreachable for an explicit id, but `add_internal` needs
        // one; today's is as good as any and never observed.
        let (month, day) = today_month_day();
        self.add_internal(parent_path, child_segment, Some(item_id), month, day)
    }

    /// The shared derivation behind the `add*` family: check, then mutate.
    fn add_internal(
        &mut self,
        parent_path: &str,
        child_segment: &str,
        item_id: Option<&str>,
        month: i64,
        day: i64,
    ) -> Result<String, SpecCreationError> {
        if let Some(error) = check_add_node(
            self.reflection.model,
            self.document,
            parent_path,
            child_segment,
            item_id,
        ) {
            return Err(error);
        }

        let child_path = spec_path_join(parent_path, child_segment);
        // `check_add_node` has already proved both of these resolve.
        let parent = self
            .reflection
            .resolve(parent_path)
            .expect("parent resolves — checked by check_add_node");
        let parent_class = parent
            .target_class
            .as_ref()
            .expect("parent is a container — checked by check_add_node");
        let field = field_for_segment(parent_class, child_segment)
            .expect("child names a field — checked by check_add_node")
            .clone();

        if field.kind != SPEC_FIELD_KIND_LIST {
            return Ok(child_path);
        }
        if field.section_id_pattern.is_empty() {
            return Ok(self.document.add_list_item(&child_path));
        }
        let id = match item_id {
            Some(id) => id.to_string(),
            None => generate_list_item_section_id(
                &field.section_id_pattern,
                month,
                day,
                &self.document.list_item_section_ids(&child_path),
            ),
        };
        Ok(self
            .document
            .add_list_item_with_section_id(&child_path, &id)
            .expect("section id uniqueness is guaranteed by check_add_node"))
    }
}

/// The field of `cls` whose section segment (`@SectionId` else name) is
/// `segment`, or `None` when the class declares no such child.
fn field_for_segment<'c>(cls: &'c SpecClass, segment: &str) -> Option<&'c SpecField> {
    cls.fields.iter().find(|f| {
        let seg = if f.section_id.is_empty() {
            &f.name
        } else {
            &f.section_id
        };
        seg == segment
    })
}
