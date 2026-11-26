//! `spec_place` — places and filters of the link vocabulary
//! (`tom_specs_model_rules.md` §9.7): the grammar every link annotation names
//! places in, parsed once and resolved under an anchor through
//! [`SpecReflection`] — a port of `tom_som_dart_runtime/lib/src/spec_place.dart`
//! (and the TypeScript, JavaScript, Python, Go and Java `spec_place` modules).
//!
//! - A place names a section, a list, a form field, a heading, a content value
//!   or a registry id: `FRED.description`, `FRE.@headline`, `FRE-REQU-LST`,
//!   `./RQDEP`, `FRE/REQDEP/RQDEP.description`, `<SECTIONID>.@content`,
//!   `<SECTIONID>.@sectionId` ([`SpecPlace`]).
//! - A filter selects entries by one of their form values: `<SECTIONID>`,
//!   `./<SECTIONID>`, `<SECTIONID>.<field>=<value>` with `|` between
//!   alternatives (`FRE.priority=must|should`) ([`SpecPlaceFilter`]).
//!   `countOf` and every `where:` read it.
//!
//! Resolution is value-free, like [`SpecReflection`]: it says where in a
//! document the place is stored, with every list item below the anchor written
//! `<list>-*`, and never reads a value.

use std::collections::{BTreeMap, HashSet};

use crate::json::Json;
use crate::spec_model::{
    FormFieldSpec, SpecClass, SpecField, SPEC_FIELD_KIND_COMPLEX, SPEC_FIELD_KIND_CONTENT,
    SPEC_FIELD_KIND_FORM, SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SECTION,
};
use crate::spec_model_links::strings_json;
use crate::spec_paths::spec_path_segments;
use crate::spec_reflection::{SpecReflection, SPEC_NODE_KIND_LIST_ITEM_COMPLEX};
use crate::spec_section_id::K_SECTION_ID_SLOT;

/// A resolved place: a section (a class's own node or a complex member),
/// whole.
pub const SPEC_PLACE_KIND_SECTION: &str = "section";
/// A resolved place: a `-LST` list container.
pub const SPEC_PLACE_KIND_LIST: &str = "list";
/// A resolved place: a form member, every field of it.
pub const SPEC_PLACE_KIND_FORM: &str = "form";
/// A resolved place: one field of a form.
pub const SPEC_PLACE_KIND_FORM_FIELD: &str = "formField";
/// A resolved place: the stored headline of a section (`.@headline`).
pub const SPEC_PLACE_KIND_HEADLINE: &str = "headline";
/// A resolved place: the content value of a section (`.@content`, or a
/// content member).
pub const SPEC_PLACE_KIND_CONTENT: &str = "content";
/// A resolved place: the stored section id of a list element (`.@sectionId`).
pub const SPEC_PLACE_KIND_SECTION_ID: &str = "sectionId";

/// The text is not a place (or not a filter) of the grammar.
pub const SPEC_PLACE_PROBLEM_MALFORMED: &str = "malformed";
/// The anchor path resolves to no section of the model.
pub const SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED: &str = "anchorUnresolved";
/// The place is `./`-scoped, but no list element lies at or above the anchor.
pub const SPEC_PLACE_PROBLEM_NOT_SCOPED: &str = "notScoped";
/// No section with the place's id (and `/` path) lies in the scope.
pub const SPEC_PLACE_PROBLEM_UNRESOLVED: &str = "unresolved";
/// The place's id is reached at more than one position in the scope.
pub const SPEC_PLACE_PROBLEM_AMBIGUOUS: &str = "ambiguous";
/// The named field is no form field of the section.
pub const SPEC_PLACE_PROBLEM_NO_SUCH_FIELD: &str = "noSuchField";
/// `.@content` names a section that holds no content value.
pub const SPEC_PLACE_PROBLEM_NO_CONTENT: &str = "noContent";
/// `.@sectionId` names a section that is no list element.
pub const SPEC_PLACE_PROBLEM_NOT_LIST_ELEMENT: &str = "notListElement";
/// A slot starting with `@` other than `@headline`, `@content`, `@sectionId`.
pub const SPEC_PLACE_PROBLEM_RESERVED_SLOT: &str = "reservedSlot";

/// A place or filter that does not parse or resolve, with the reason.
///
/// `problem` is one of the `SPEC_PLACE_PROBLEM_*` constants — the corpus
/// compares it, never the message. It is `""` for the one failure that is no
/// place problem: an ancestor of the anchor that resolves to no class (the
/// reference fails on it with a null check).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecPlaceError {
    /// What went wrong (a `SPEC_PLACE_PROBLEM_*` constant), `""` when no
    /// place problem.
    pub problem: String,
    /// The place or filter as written.
    pub text: String,
    /// The prose for the reader.
    pub message: String,
}

impl SpecPlaceError {
    fn new(problem: &str, text: &str, message: String) -> SpecPlaceError {
        SpecPlaceError {
            problem: problem.to_string(),
            text: text.to_string(),
            message,
        }
    }

    /// Whether this is a place problem (`problem` set) rather than a model
    /// that cannot hold the anchor's scope.
    pub fn is_place_problem(&self) -> bool {
        !self.problem.is_empty()
    }
}

impl std::fmt::Display for SpecPlaceError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.problem.is_empty() {
            return write!(f, "{}", self.message);
        }
        write!(
            f,
            "SpecPlaceException({}): \"{}\" {}",
            self.problem, self.text, self.message
        )
    }
}

impl std::error::Error for SpecPlaceError {}

/// `^[A-Za-z0-9][A-Za-z0-9-]*$` — a section id segment.
fn is_place_segment(s: &str) -> bool {
    let b = s.as_bytes();
    !b.is_empty()
        && b[0].is_ascii_alphanumeric()
        && b.iter().all(|c| c.is_ascii_alphanumeric() || *c == b'-')
}

/// `^[A-Za-z_][A-Za-z0-9_]*$` — a form field name.
fn is_place_field(s: &str) -> bool {
    let b = s.as_bytes();
    !b.is_empty()
        && (b[0].is_ascii_alphabetic() || b[0] == b'_')
        && b.iter().all(|c| c.is_ascii_alphanumeric() || *c == b'_')
}

/// `^@?[A-Za-z_][A-Za-z0-9_]*$` — a slot.
fn is_place_slot(s: &str) -> bool {
    is_place_field(s.strip_prefix('@').unwrap_or(s))
}

/// A place as written: `./` scope, `/` segments, section id and slot.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecPlace {
    /// The text it was parsed from.
    pub text: String,
    /// Whether it is written `./…`: resolved beneath the nearest list element
    /// at or above the anchor.
    pub scoped: bool,
    /// The section ids written before the last `/`, which the path to the
    /// place holds in this order.
    pub prefix: Vec<String>,
    /// The section id the place names.
    pub section_id: String,
    /// The part after the dot: a form field name, `@headline`, `@content`,
    /// `@sectionId`; `""` for the section, list or form itself.
    pub slot: String,
}

impl SpecPlace {
    /// Parses `text`; fails with a [`SpecPlaceError`] (`malformed`) when it is
    /// not a place.
    pub fn parse(text: &str) -> Result<SpecPlace, SpecPlaceError> {
        Self::try_parse(text).ok_or_else(|| {
            SpecPlaceError::new(
                SPEC_PLACE_PROBLEM_MALFORMED,
                text,
                "is not a place (`<SECTIONID>[.<field>|.@headline|.@content|.@sectionId]`, \
                 optionally `./`-scoped or a `/` path)"
                    .to_string(),
            )
        })
    }

    /// Parses `text`, or returns `None` when it is not a place.
    pub fn try_parse(text: &str) -> Option<SpecPlace> {
        let scoped = text.starts_with("./");
        let body = if scoped { &text[2..] } else { text };
        if body.is_empty() {
            return None;
        }
        let mut segments: Vec<&str> = body.split('/').collect();
        let last = segments.pop().unwrap_or("");
        let (id, slot, has_slot) = match last.find('.') {
            Some(dot) => (&last[..dot], &last[dot + 1..], true),
            None => (last, "", false),
        };
        if !is_place_segment(id) || !segments.iter().all(|s| is_place_segment(s)) {
            return None;
        }
        if has_slot && !is_place_slot(slot) {
            return None;
        }
        Some(SpecPlace {
            text: text.to_string(),
            scoped,
            prefix: segments.iter().map(|s| s.to_string()).collect(),
            section_id: id.to_string(),
            slot: slot.to_string(),
        })
    }

    /// The parsed parts, for the corpus.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("scoped".to_string(), Json::Bool(self.scoped)),
            ("prefix".to_string(), strings_json(&self.prefix)),
            ("sectionId".to_string(), Json::Str(self.section_id.clone())),
        ];
        if !self.slot.is_empty() {
            out.push(("slot".to_string(), Json::Str(self.slot.clone())));
        }
        Json::Object(out)
    }

    /// Resolves the place under `anchor`, a document path of a section (a
    /// root, a complex or section member, or a list item). Fails with a
    /// [`SpecPlaceError`] when the place does not resolve.
    ///
    /// The place is looked for in the subtree of the anchor's class — beneath
    /// the nearest list element at or above the anchor when it is `./`-scoped
    /// — among the positions whose section id is `section_id` and whose path
    /// holds the `prefix` ids in order (only `-LST` containers and the scope's
    /// own id may lie between them). More than one such position is
    /// `ambiguous`.
    pub fn resolve(
        &self,
        refl: &SpecReflection<'_>,
        anchor: &str,
    ) -> Result<SpecPlaceResolution, SpecPlaceError> {
        let scope = place_scope_of(refl, anchor, self.scoped, &self.text)?;
        let mut by_path: BTreeMap<String, PlacePosition<'_>> = BTreeMap::new();
        for pos in place_positions(refl, &scope) {
            if pos.node.id == self.section_id
                && place_path_matches(&pos.ids[..pos.ids.len() - 1], &self.prefix)
            {
                by_path.insert(pos.node.path.clone(), pos);
            }
        }
        if by_path.is_empty() {
            return Err(SpecPlaceError::new(
                SPEC_PLACE_PROBLEM_UNRESOLVED,
                &self.text,
                format!("resolves to no section beneath {}", scope.path),
            ));
        }
        if by_path.len() > 1 {
            let paths: Vec<&str> = by_path.keys().map(String::as_str).collect();
            return Err(SpecPlaceError::new(
                SPEC_PLACE_PROBLEM_AMBIGUOUS,
                &self.text,
                format!(
                    "is ambiguous: {} is reached at {} — write it as a `/` path",
                    self.section_id,
                    paths.join(", ")
                ),
            ));
        }
        let pos = by_path.into_values().next().expect("one position");
        self.with_slot(pos)
    }

    fn with_slot(&self, pos: PlacePosition<'_>) -> Result<SpecPlaceResolution, SpecPlaceError> {
        let n = &pos.node;
        let result =
            |kind: &str, path: &str, form_field: Option<&FormFieldSpec>| SpecPlaceResolution {
                place: self.clone(),
                kind: kind.to_string(),
                path: path.to_string(),
                class_name: n.class_name.clone(),
                section_ids: pos.ids.clone(),
                form_field: form_field.cloned(),
            };
        let slot = self.slot.as_str();
        if slot.is_empty() {
            let kind = match n.shape {
                "list" => SPEC_PLACE_KIND_LIST,
                "form" => SPEC_PLACE_KIND_FORM,
                "content" => SPEC_PLACE_KIND_CONTENT,
                _ => SPEC_PLACE_KIND_SECTION,
            };
            return Ok(result(kind, &n.path, None));
        }
        if slot == "@headline" {
            return Ok(result(SPEC_PLACE_KIND_HEADLINE, &n.path, None));
        }
        if slot == "@content" {
            if n.content_path.is_empty() {
                return Err(SpecPlaceError::new(
                    SPEC_PLACE_PROBLEM_NO_CONTENT,
                    &self.text,
                    format!(
                        "names @content of {}, which holds no content value",
                        self.section_id
                    ),
                ));
            }
            return Ok(result(SPEC_PLACE_KIND_CONTENT, &n.content_path, None));
        }
        if slot == K_SECTION_ID_SLOT {
            if !n.is_list_element {
                return Err(SpecPlaceError::new(
                    SPEC_PLACE_PROBLEM_NOT_LIST_ELEMENT,
                    &self.text,
                    format!(
                        "names @sectionId of {}, which is no list element",
                        self.section_id
                    ),
                ));
            }
            return Ok(result(SPEC_PLACE_KIND_SECTION_ID, &n.path, None));
        }
        if slot.starts_with('@') {
            return Err(SpecPlaceError::new(
                SPEC_PLACE_PROBLEM_RESERVED_SLOT,
                &self.text,
                format!(
                    "names the slot {} — \"@\" is reserved for @headline, @content and @sectionId",
                    slot
                ),
            ));
        }
        match n.form_fields.iter().find(|f| f.name == slot) {
            Some(ff) if !n.form_path.is_empty() => {
                Ok(result(SPEC_PLACE_KIND_FORM_FIELD, &n.form_path, Some(ff)))
            }
            _ => Err(SpecPlaceError::new(
                SPEC_PLACE_PROBLEM_NO_SUCH_FIELD,
                &self.text,
                format!("names {}.{}, which is no form field", self.section_id, slot),
            )),
        }
    }
}

impl std::fmt::Display for SpecPlace {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.text)
    }
}

/// Where a place is stored in a document.
#[derive(Debug, Clone)]
pub struct SpecPlaceResolution {
    /// The place resolved.
    pub place: SpecPlace,
    /// What the place is (a `SPEC_PLACE_KIND_*` constant).
    pub kind: String,
    /// The document path the value lives at, with every list item beneath the
    /// anchor written `<list>-*`: the section (or list item) for a section, a
    /// headline or a section id; the list for a list; the form for a form or a
    /// form field; the content leaf for a content value.
    pub path: String,
    /// The class of the section the place sits on (for a member, its owner).
    pub class_name: String,
    /// The section ids on the way from the scope to the place, the place's own
    /// last.
    pub section_ids: Vec<String>,
    /// For [`SPEC_PLACE_KIND_FORM_FIELD`], the field; `None` otherwise.
    pub form_field: Option<FormFieldSpec>,
}

impl SpecPlaceResolution {
    /// The form field name for [`SPEC_PLACE_KIND_FORM_FIELD`], else `""`.
    pub fn field(&self) -> &str {
        self.form_field.as_ref().map_or("", |f| f.name.as_str())
    }

    /// The canonical JSON form the corpus compares.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("kind".to_string(), Json::Str(self.kind.clone())),
            ("path".to_string(), Json::Str(self.path.clone())),
        ];
        if let Some(ff) = &self.form_field {
            out.push(("field".to_string(), Json::Str(ff.name.clone())));
        }
        Json::Object(out)
    }
}

/// An entry filter: `<SECTIONID>`, `./<SECTIONID>` or
/// `<SECTIONID>.<field>=<value>[|<value>…]`, optionally `./`-scoped.
///
/// It selects the entries (list elements of the class with that section id)
/// one of whose own forms holds one of `values` in `field`; without a field
/// every entry. `countOf` counts the entries it selects, a `where:` keeps the
/// elements or rows it selects.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecPlaceFilter {
    /// The text it was parsed from.
    pub text: String,
    /// Whether it is written `./…`: only the entries beneath the nearest list
    /// element (for `countOf`: beneath the section holding the form).
    pub scoped: bool,
    /// The section id of the entries.
    pub section_id: String,
    /// The form field compared, or `""` for every entry.
    pub field: String,
    /// The values accepted, in written order; empty exactly when `field` is
    /// `""`.
    pub values: Vec<String>,
}

impl SpecPlaceFilter {
    /// Parses `text`; fails with a [`SpecPlaceError`] (`malformed`) when it is
    /// not a filter.
    pub fn parse(text: &str) -> Result<SpecPlaceFilter, SpecPlaceError> {
        Self::try_parse(text).ok_or_else(|| {
            SpecPlaceError::new(
                SPEC_PLACE_PROBLEM_MALFORMED,
                text,
                "is not a filter (`<SECTIONID>[.<field>=<value>[|<value>…]]`, optionally `./`-scoped)"
                    .to_string(),
            )
        })
    }

    /// Parses `text`, or returns `None` when it is not a filter.
    pub fn try_parse(text: &str) -> Option<SpecPlaceFilter> {
        let scoped = text.starts_with("./");
        let body = if scoped { &text[2..] } else { text };
        let dot = body.find('.');
        let id = match dot {
            Some(d) => &body[..d],
            None => body,
        };
        if !is_place_segment(id) {
            return None;
        }
        let dot = match dot {
            None => {
                return Some(SpecPlaceFilter {
                    text: text.to_string(),
                    scoped,
                    section_id: id.to_string(),
                    field: String::new(),
                    values: Vec::new(),
                })
            }
            Some(d) => d,
        };
        let eq = dot + body[dot..].find('=')?;
        let name = &body[dot + 1..eq];
        if !is_place_field(name) {
            return None;
        }
        let values: Vec<String> = body[eq + 1..].split('|').map(str::to_string).collect();
        if values.iter().any(String::is_empty) {
            return None;
        }
        Some(SpecPlaceFilter {
            text: text.to_string(),
            scoped,
            section_id: id.to_string(),
            field: name.to_string(),
            values,
        })
    }

    /// Whether an entry whose `field` holds `stored` (values trimmed, as many
    /// as its forms hold) is selected.
    pub fn matches<S: AsRef<str>>(&self, stored: &[S]) -> bool {
        if self.field.is_empty() {
            return true;
        }
        stored
            .iter()
            .any(|v| self.values.iter().any(|want| v.as_ref().trim() == want))
    }

    /// The place of the entries: `section_id`, scoped as the filter is.
    pub fn place(&self) -> SpecPlace {
        SpecPlace {
            text: if self.scoped {
                format!("./{}", self.section_id)
            } else {
                self.section_id.clone()
            },
            scoped: self.scoped,
            prefix: Vec::new(),
            section_id: self.section_id.clone(),
            slot: String::new(),
        }
    }

    /// Resolves the entries under `anchor` as [`SpecPlace::resolve`] does, and
    /// checks that `field` is a field of one of the entry's own forms (a form
    /// member of the entry, or its content form). Fails with a
    /// [`SpecPlaceError`] when it does not resolve.
    pub fn resolve(
        &self,
        refl: &SpecReflection<'_>,
        anchor: &str,
    ) -> Result<SpecPlaceResolution, SpecPlaceError> {
        let r = self.place().resolve(refl, anchor).map_err(|e| {
            if e.is_place_problem() {
                SpecPlaceError::new(&e.problem, &self.text, e.message)
            } else {
                e
            }
        })?;
        if !self.field.is_empty() {
            let found = r.kind == SPEC_PLACE_KIND_SECTION
                && refl.model.class_named(&r.class_name).is_some_and(|cls| {
                    cls.fields
                        .iter()
                        .filter(|f| f.kind == SPEC_FIELD_KIND_FORM)
                        .any(|f| f.form_fields.iter().any(|ff| ff.name == self.field))
                });
            if !found {
                return Err(SpecPlaceError::new(
                    SPEC_PLACE_PROBLEM_NO_SUCH_FIELD,
                    &self.text,
                    format!(
                        "names {}.{}, which no form of {} holds",
                        self.section_id, self.field, self.section_id
                    ),
                ));
            }
        }
        Ok(r)
    }

    /// The parsed parts, for the corpus.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("scoped".to_string(), Json::Bool(self.scoped)),
            ("sectionId".to_string(), Json::Str(self.section_id.clone())),
        ];
        if !self.field.is_empty() {
            out.push(("field".to_string(), Json::Str(self.field.clone())));
            out.push(("values".to_string(), strings_json(&self.values)));
        }
        Json::Object(out)
    }
}

impl std::fmt::Display for SpecPlaceFilter {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.text)
    }
}

/// A `@SameAs` copy at one position of a document root, with its holder.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecSameAsBinding {
    /// The root the positions are in.
    pub root: String,
    /// The class both positions hold.
    pub class_name: String,
    /// The copy's document path (list items written `<list>-*`).
    pub copy_path: String,
    /// The copy's section-id path from the root.
    pub copy_section_ids: Vec<String>,
    /// The holder's document path, `""` when `problem` is set.
    pub holder_path: String,
    /// The holder's section-id path from the root, empty when `problem` is
    /// set.
    pub holder_section_ids: Vec<String>,
    /// Why no single holder was found: `unresolved` (no position fits) or
    /// `ambiguous` (several do); `""` when `holder_path` is set.
    pub problem: String,
}

impl SpecSameAsBinding {
    /// The canonical JSON form the corpus compares.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("root".to_string(), Json::Str(self.root.clone())),
            ("className".to_string(), Json::Str(self.class_name.clone())),
            ("copy".to_string(), Json::Str(self.copy_path.clone())),
        ];
        if !self.holder_path.is_empty() {
            out.push(("holder".to_string(), Json::Str(self.holder_path.clone())));
        }
        if !self.problem.is_empty() {
            out.push(("problem".to_string(), Json::Str(self.problem.clone())));
        }
        Json::Object(out)
    }
}

/// The scope of the whole document root `root_type`, `None` when the model has
/// no such root or class.
fn root_scope<'a>(refl: &SpecReflection<'a>, root_type: &str) -> Option<PlaceScope<'a>> {
    let model = refl.model;
    let root = model.roots.iter().find(|r| r.type_ == root_type)?;
    let cls = model.class_named(root_type)?;
    Some(PlaceScope {
        path: refl.root_segment(root),
        cls,
        is_list_element: false,
    })
}

/// Every `@SameAs` copy the document root `root_type` reaches, each with its
/// holder (`tom_specs_model_rules.md` §9.7, invariant `SAME-AS`): among the
/// positions of the copy's class in the root that are no copy themselves, the
/// one whose section-id path ends with `holder`, or — without `holder` — the
/// one there is. In position order.
pub fn spec_same_as_bindings(refl: &SpecReflection<'_>, root_type: &str) -> Vec<SpecSameAsBinding> {
    let mut out = Vec::new();
    let scope = match root_scope(refl, root_type) {
        Some(s) => s,
        None => return out,
    };
    let sections: Vec<PlacePosition<'_>> = place_positions(refl, &scope)
        .into_iter()
        .filter(|p| p.node.shape == "section" && p.node.own_node)
        .collect();
    for copy in &sections {
        let same_as = match copy.member.and_then(SpecField::same_as) {
            Some(s) => s,
            None => continue,
        };
        let typ = &copy.node.class_name;
        let holder_tail: Option<Vec<String>> = if same_as.holder.is_empty() {
            None
        } else {
            Some(same_as.holder.split('/').map(str::to_string).collect())
        };
        let holders: Vec<&PlacePosition<'_>> = sections
            .iter()
            .filter(|p| &p.node.class_name == typ)
            .filter(|p| p.member.is_none_or(|m| m.same_as().is_none()))
            .filter(|p| {
                holder_tail
                    .as_ref()
                    .is_none_or(|tail| place_ends_with(&p.ids, tail))
            })
            .collect();
        let mut b = SpecSameAsBinding {
            root: root_type.to_string(),
            class_name: typ.clone(),
            copy_path: copy.node.path.clone(),
            copy_section_ids: copy.ids.clone(),
            holder_path: String::new(),
            holder_section_ids: Vec::new(),
            problem: String::new(),
        };
        match holders.len() {
            0 => b.problem = SPEC_PLACE_PROBLEM_UNRESOLVED.to_string(),
            1 => {
                b.holder_path = holders[0].node.path.clone();
                b.holder_section_ids = holders[0].ids.clone();
            }
            _ => b.problem = SPEC_PLACE_PROBLEM_AMBIGUOUS.to_string(),
        }
        out.push(b);
    }
    out
}

/// One position of a section in a document root: a class reached there (its
/// own node), or a member of a class that carries a section id of its own.
#[derive(Debug, Clone)]
pub struct SpecSectionPosition<'a> {
    /// The document path, list items written `<list>-*`.
    pub path: String,
    /// The class reached (`member` `None`), or the class the member belongs
    /// to.
    pub class_name: String,
    /// The section ids from the root to here, this position's own last.
    pub section_ids: Vec<String>,
    /// Whether this is a member position (a form, list, content or section
    /// member with its own section id) rather than a class reached.
    pub is_member: bool,
    /// For a class position, the member it is reached through (`None` at the
    /// root); for a member position, the member itself.
    pub member: Option<&'a SpecField>,
}

/// Every section position of the document root `root_type`, in walk order: a
/// class reached again on its own path is not descended into, and a
/// `@Reference` member's target is not walked.
pub fn spec_section_positions<'a>(
    refl: &SpecReflection<'a>,
    root_type: &str,
) -> Vec<SpecSectionPosition<'a>> {
    let scope = match root_scope(refl, root_type) {
        Some(s) => s,
        None => return Vec::new(),
    };
    place_positions(refl, &scope)
        .into_iter()
        .map(|p| SpecSectionPosition {
            path: p.node.path,
            class_name: p.node.class_name,
            section_ids: p.ids,
            is_member: !p.node.own_node,
            member: p.member,
        })
        .collect()
}

// --- the positions of a subtree ----------------------------------------------

pub(crate) struct PlaceScope<'a> {
    path: String,
    cls: &'a SpecClass,
    is_list_element: bool,
}

struct PlaceNode<'a> {
    id: String,
    path: String,
    class_name: String,
    shape: &'static str,
    own_node: bool,
    form_fields: &'a [FormFieldSpec],
    form_path: String,
    content_path: String,
    is_list_element: bool,
}

struct PlacePosition<'a> {
    node: PlaceNode<'a>,
    ids: Vec<String>,
    member: Option<&'a SpecField>,
}

/// The scope a place is looked for in under `anchor`.
fn place_scope_of<'a>(
    refl: &SpecReflection<'a>,
    anchor: &str,
    scoped: bool,
    text: &str,
) -> Result<PlaceScope<'a>, SpecPlaceError> {
    let segs = spec_path_segments(anchor);
    for n in (1..=segs.len()).rev() {
        let path = segs[..n].join("/");
        let r = refl.resolve(&path);
        let cls = r
            .as_ref()
            .and_then(|r| r.target_class.as_ref())
            .and_then(|c| refl.model.class_named(&c.name));
        if n == segs.len() && cls.is_none() {
            return Err(SpecPlaceError::new(
                SPEC_PLACE_PROBLEM_ANCHOR_UNRESOLVED,
                text,
                format!("has the anchor {}, which resolves to no section", anchor),
            ));
        }
        let is_item = r
            .as_ref()
            .is_some_and(|r| r.kind == SPEC_NODE_KIND_LIST_ITEM_COMPLEX);
        if !scoped || is_item {
            // As in Dart (`r!.targetClass!`): an ancestor that resolves to no
            // class cannot be a scope.
            return match cls {
                Some(cls) => Ok(PlaceScope {
                    path,
                    cls,
                    is_list_element: is_item,
                }),
                None => Err(SpecPlaceError::new(
                    "",
                    text,
                    format!("no class at {}", path),
                )),
            };
        }
    }
    Err(SpecPlaceError::new(
        SPEC_PLACE_PROBLEM_NOT_SCOPED,
        text,
        format!(
            "is `./`-scoped, but no list element lies at or above {}",
            anchor
        ),
    ))
}

/// The class a complex or section member reaches.
pub(crate) fn place_class_of<'a>(
    refl: &SpecReflection<'a>,
    f: &SpecField,
) -> Option<&'a SpecClass> {
    refl.model.class_named(&f.type_.replace('?', ""))
}

/// Every addressable position beneath (and including) `scope`, in model
/// order. A class reached again on its own path is not descended into, and a
/// `@Reference` member is a place whose target is not walked.
fn place_positions<'a>(
    refl: &SpecReflection<'a>,
    scope: &PlaceScope<'a>,
) -> Vec<PlacePosition<'a>> {
    struct Walker<'r, 'a> {
        refl: &'r SpecReflection<'a>,
        out: Vec<PlacePosition<'a>>,
        on_path: HashSet<String>,
    }
    impl<'a> Walker<'_, 'a> {
        fn walk(
            &mut self,
            cls: &'a SpecClass,
            path: &str,
            ids: &[String],
            is_item: bool,
            via: Option<&'a SpecField>,
        ) {
            if self.on_path.contains(&cls.name) {
                return;
            }
            self.on_path.insert(cls.name.clone());
            let content = cls.field_named("content");
            let mut here: Vec<String> = ids.to_vec();
            if !cls.section_id.is_empty() {
                here.push(cls.section_id.clone());
                let mut node = PlaceNode {
                    id: cls.section_id.clone(),
                    path: path.to_string(),
                    class_name: cls.name.clone(),
                    shape: "section",
                    own_node: true,
                    form_fields: &[],
                    form_path: String::new(),
                    content_path: String::new(),
                    is_list_element: is_item,
                };
                if let Some(content) = content {
                    let seg = format!("{}/{}", path, self.refl.field_segment(content));
                    if content.kind == SPEC_FIELD_KIND_FORM {
                        node.form_fields = &content.form_fields;
                        node.form_path = seg;
                    } else if content.kind == SPEC_FIELD_KIND_CONTENT {
                        node.content_path = seg;
                    }
                }
                self.out.push(PlacePosition {
                    node,
                    ids: here.clone(),
                    member: via,
                });
            }
            for f in &cls.fields {
                let member_path = format!("{}/{}", path, self.refl.field_segment(f));
                let mut below = here.clone();
                if f.name != "content" && !f.section_id.is_empty() {
                    below.push(f.section_id.clone());
                    let shape = match f.kind.as_str() {
                        SPEC_FIELD_KIND_LIST => "list",
                        SPEC_FIELD_KIND_FORM => "form",
                        SPEC_FIELD_KIND_COMPLEX | SPEC_FIELD_KIND_SECTION => "section",
                        _ => "content",
                    };
                    let mut node = PlaceNode {
                        id: f.section_id.clone(),
                        path: member_path.clone(),
                        class_name: cls.name.clone(),
                        shape,
                        own_node: false,
                        form_fields: &[],
                        form_path: String::new(),
                        content_path: String::new(),
                        is_list_element: false,
                    };
                    if f.kind == SPEC_FIELD_KIND_FORM {
                        node.form_fields = &f.form_fields;
                        node.form_path = member_path.clone();
                    }
                    if shape == "content" {
                        node.content_path = member_path.clone();
                    }
                    self.out.push(PlacePosition {
                        node,
                        ids: below.clone(),
                        member: Some(f),
                    });
                }
                if f.has_annotation("Reference") {
                    continue;
                }
                if f.kind == SPEC_FIELD_KIND_LIST && f.element_is_complex {
                    if let Some(el) = self.refl.model.class_named(&f.element_type) {
                        self.walk(el, &format!("{}-*", member_path), &below, true, Some(f));
                    }
                } else if f.kind == SPEC_FIELD_KIND_COMPLEX || f.kind == SPEC_FIELD_KIND_SECTION {
                    if let Some(child) = place_class_of(self.refl, f) {
                        self.walk(child, &member_path, &below, false, Some(f));
                    }
                }
            }
            self.on_path.remove(&cls.name);
        }
    }
    let mut w = Walker {
        refl,
        out: Vec::new(),
        on_path: HashSet::new(),
    };
    w.walk(scope.cls, &scope.path, &[], scope.is_list_element, None);
    w.out
}

/// Whether the `/` segments lead to a position whose ancestors are `path`:
/// they name every section on the way, leaving out only `-LST` containers and
/// the scope's own id. No segments: any position.
fn place_path_matches(path: &[String], segments: &[String]) -> bool {
    if segments.is_empty() {
        return true;
    }
    let from = |start: usize| {
        let mut j = 0;
        for p in &path[start.min(path.len())..] {
            if j < segments.len() && *p == segments[j] {
                j += 1;
            } else if !p.ends_with("-LST") {
                return false;
            }
        }
        j == segments.len()
    };
    from(0) || (!path.is_empty() && from(1))
}

/// Whether `path` ends with exactly the ids of `tail`, as the static
/// validator's `SAME-AS` reads a holder.
fn place_ends_with(path: &[String], tail: &[String]) -> bool {
    path.len() >= tail.len() && path[path.len() - tail.len()..] == *tail
}
