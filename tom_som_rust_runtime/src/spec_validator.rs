//! `spec_validator` — validates a concrete [`SpecDocument`]'s values against a
//! [`SpecModel`] via the [`SpecReflection`] resolver, a faithful port of the Go
//! `spec_validator.go`.
//!
//! The check is over the values a document holds: every set path must resolve to
//! a node of a compatible kind, every form sub-key must name a real form field,
//! and every populated list must meet its `@Min` item count. Schema completeness
//! (mandatory-but-absent nodes) is a separate concern and is not reported here.

use crate::spec_document::SpecDocument;
use crate::spec_model::{SpecClass, SpecField, SpecModel, SPEC_FIELD_KIND_FORM};
use crate::spec_reflection::{SpecReflection, SPEC_NODE_KIND_FORM, SPEC_NODE_KIND_LIST};
use crate::spec_section_id::{effective_list_item_section_id, K_SECTION_ID_SLOT};
use std::collections::{BTreeMap, BTreeSet};

/// Why a single value in a document is invalid against the model.
pub const SPEC_VALIDATION_CODE_DANGLING_PATH: &str = "danglingPath";
pub const SPEC_VALIDATION_CODE_KIND_MISMATCH: &str = "kindMismatch";
pub const SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD: &str = "unknownFormField";
pub const SPEC_VALIDATION_CODE_MIN_ITEMS: &str = "minItems";
pub const SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH: &str = "oneOfCaseMismatch";
pub const SPEC_VALIDATION_CODE_DANGLING_REFERENCE: &str = "danglingReference";

/// One problem found while validating a document.
#[derive(Debug, Clone, PartialEq)]
pub struct SpecValidationError {
    pub path: String,
    pub code: String,
    pub message: String,
}

impl SpecValidationError {
    /// Renders the error as `[code] path: message`.
    pub fn to_display(&self) -> String {
        format!("[{}] {}: {}", self.code, self.path, self.message)
    }
}

impl std::fmt::Display for SpecValidationError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.to_display())
    }
}

fn dangling(path: &str) -> SpecValidationError {
    SpecValidationError {
        path: path.to_string(),
        code: SPEC_VALIDATION_CODE_DANGLING_PATH.to_string(),
        message: "path does not resolve to any model node".to_string(),
    }
}

/// Validates `doc` against `model`. Returns an empty vector when the document is
/// valid; otherwise one error per problem, in a stable order (content paths,
/// then forms, then lists; each group sorted by path).
pub fn validate_document(model: &SpecModel, doc: &SpecDocument) -> Vec<SpecValidationError> {
    let refl = SpecReflection::new(model);
    let mut errors = Vec::new();

    // 1. Content/scalar/enum leaves. (content_paths is already sorted.)
    for path in doc.content_paths() {
        match refl.resolve(&path) {
            None => errors.push(dangling(&path)),
            Some(res) => {
                if !res.is_value_leaf() {
                    errors.push(SpecValidationError {
                        path: path.clone(),
                        code: SPEC_VALIDATION_CODE_KIND_MISMATCH.to_string(),
                        message: format!("expected a value leaf but path resolves to {}", res.kind),
                    });
                }
            }
        }
    }

    // 2. Form sections.
    for path in doc.form_paths() {
        let res = match refl.resolve(&path) {
            None => {
                errors.push(dangling(&path));
                continue;
            }
            Some(r) => r,
        };
        let field = match &res.field {
            Some(f) if res.kind == SPEC_NODE_KIND_FORM => f.clone(),
            _ => {
                errors.push(SpecValidationError {
                    path: path.clone(),
                    code: SPEC_VALIDATION_CODE_KIND_MISMATCH.to_string(),
                    message: format!("expected a form section but path resolves to {}", res.kind),
                });
                continue;
            }
        };
        let declared: std::collections::HashSet<&str> =
            field.form_fields.iter().map(|ff| ff.name.as_str()).collect();
        for name in doc.form_field_names(&path) {
            if !declared.contains(name.as_str()) {
                errors.push(SpecValidationError {
                    path: path.clone(),
                    code: SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD.to_string(),
                    message: format!(
                        "form field \"{}\" is not declared on {}",
                        name, field.name
                    ),
                });
            }
        }
    }

    // 3. Lists (container kind + @Min count on populated lists).
    for path in doc.list_paths() {
        let res = match refl.resolve(&path) {
            None => {
                errors.push(dangling(&path));
                continue;
            }
            Some(r) => r,
        };
        let field = match &res.field {
            Some(f) if res.kind == SPEC_NODE_KIND_LIST => f.clone(),
            _ => {
                errors.push(SpecValidationError {
                    path: path.clone(),
                    code: SPEC_VALIDATION_CODE_KIND_MISMATCH.to_string(),
                    message: format!("expected a list but path resolves to {}", res.kind),
                });
                continue;
            }
        };
        if let Some(min) = field.min {
            let count = doc.list_item_count(&path) as i64;
            if count < min {
                errors.push(SpecValidationError {
                    path: path.clone(),
                    code: SPEC_VALIDATION_CODE_MIN_ITEMS.to_string(),
                    message: format!(
                        "list holds {} item(s) but requires at least {}",
                        count, min
                    ),
                });
            }
        }
    }

    // 4. @OneOf/@Case closed choice (csmb6).
    //
    // The static tier checks the group is well formed; only here can we see which
    // case a document actually chose and whether the subsections it populated are
    // the ones that choice selects.
    errors.extend(validate_one_of_instances(&refl, doc));

    // 5. Cross-registry references (csrb3).
    //
    // A reference form field holds an id that must already be declared by some
    // entry of a target registry. The static tier has checked the `refersTo`
    // targets are resolvable; only here can we see whether the id a document
    // actually wrote is one the document also declares.
    errors.extend(validate_reference_instances(&refl, doc));

    errors
}

/// The constant part of a qualified `EnumType.constant` `@Case` token (or the
/// whole string when it is not qualified).
fn case_constant(token: &str) -> String {
    match token.find('.') {
        Some(dot) => token[dot + 1..].to_string(),
        None => token.to_string(),
    }
}

/// Every section-instance path present in `doc`: each stored value path plus all
/// of its ancestor prefixes (a container's own discriminator form lives at
/// `<container>/content`, so the container path is always a prefix of a
/// populated path), sorted.
fn document_section_paths(doc: &SpecDocument) -> BTreeSet<String> {
    let mut paths: BTreeSet<String> = BTreeSet::new();
    for group in [
        doc.content_paths(),
        doc.form_paths(),
        doc.list_paths(),
        doc.headline_paths(),
    ] {
        for full in group {
            let mut buf = String::new();
            for (i, seg) in full.split('/').enumerate() {
                if i > 0 {
                    buf.push('/');
                }
                buf.push_str(seg);
                paths.insert(buf.clone());
            }
        }
    }
    paths
}

/// Instance-tier `@OneOf`/`@Case` check (csmb6): for every `@OneOf` container
/// instance present in `doc`, verifies the populated case subsections match the
/// chosen discriminator value.
fn validate_one_of_instances(refl: &SpecReflection, doc: &SpecDocument) -> Vec<SpecValidationError> {
    let mut errors = Vec::new();

    for path in document_section_paths(doc) {
        let cls: SpecClass = match refl.resolve(&path).and_then(|r| r.target_class) {
            Some(c) => c,
            None => continue,
        };
        let discriminator = match cls.annotation("OneOf").and_then(|a| a.argument("discriminator")) {
            Some(v) => match v.as_str() {
                Some(s) if !s.is_empty() => s.to_string(),
                _ => continue,
            },
            None => continue,
        };

        // Read the chosen discriminator value from the container's own @Form.
        let form_holder: &SpecField = match cls.fields.iter().find(|f| {
            f.kind == SPEC_FIELD_KIND_FORM && f.form_fields.iter().any(|ff| ff.name == discriminator)
        }) {
            Some(f) => f,
            None => continue, // static tier flagged the mismatch
        };
        let chosen = doc.form_field_or(
            &format!("{}/{}", path, refl.field_segment(form_holder)),
            &discriminator,
        );
        if chosen.is_empty() {
            continue; // no case chosen yet
        }

        // Inspect each case-bound subsection: present + not-selected → mismatch.
        let mut present_for_chosen: Vec<String> = Vec::new();
        for f in &cls.fields {
            let cases: BTreeSet<String> = f
                .annotations
                .iter()
                .filter(|a| a.name == "Case")
                .filter_map(|a| a.argument("value").and_then(|v| v.as_str()))
                .map(case_constant)
                .collect();
            if cases.is_empty() {
                continue; // common subsection — always allowed
            }
            let child_path = format!("{}/{}", path, refl.field_segment(f));
            if !doc.has_values_under(&child_path) {
                continue;
            }
            if cases.contains(&chosen) {
                present_for_chosen.push(f.name.clone());
                continue;
            }
            errors.push(SpecValidationError {
                path: child_path,
                code: SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH.to_string(),
                message: format!(
                    "subsection \"{}\" is present but the chosen {}=\"{}\" does not select it \
                     (cases: {})",
                    f.name,
                    discriminator,
                    chosen,
                    cases.iter().cloned().collect::<Vec<_>>().join(", ")
                ),
            });
        }
        if present_for_chosen.len() > 1 {
            present_for_chosen.sort();
            errors.push(SpecValidationError {
                path: path.clone(),
                code: SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH.to_string(),
                message: format!(
                    "chosen {}=\"{}\" selects more than one populated subsection ({}) — at most \
                     one case subsection may be present",
                    discriminator,
                    chosen,
                    present_for_chosen.join(", ")
                ),
            });
        }
    }

    errors
}

/// One resolved form section: its path, the class it sits on, and its field.
struct FormInstance {
    path: String,
    cls: SpecClass,
    field: SpecField,
}

/// Instance-tier cross-registry reference check (csrb3): every id written into a
/// `refersTo` form field must be declared by some entry of one of its target
/// registries *in this document*.
///
/// The pass is two sweeps over the document's form sections, so it costs one
/// extra walk rather than a resolve per reference:
///
///  1. **Declare.** Every form instance whose class carries `@SectionId(X)` and
///     declares form field `f` contributes its value of `f` to the registry key
///     `X.f`. Every item of a list whose element class carries `@SectionId(X)`
///     additionally contributes its *effective* section id — stored, else
///     positional, see [`effective_list_item_section_id`] — to the reserved key
///     `X.@sectionId`. That second half is what makes a registry keeping its id
///     nowhere but the section id (a functional requirement) referenceable at
///     all.
///  2. **Resolve.** Every form instance holding a `refersTo` field checks its
///     value against those sets. A value naming several ids writes them
///     comma-separated, so each segment resolves independently.
///
/// A value is valid when it resolves in **any** listed registry: some fields
/// legitimately accept an id from more than one. An empty value is not a dangling
/// reference — it means "not filled in yet".
///
/// **Cross-document references (csre2).** A reference whose target registry the
/// document's own root cannot reach is skipped rather than reported. Such a
/// reference is a *cross-document* one and the registry it names is absent from
/// the document by construction, not undeclared; see [`registry_scope`].
fn validate_reference_instances(
    refl: &SpecReflection,
    doc: &SpecDocument,
) -> Vec<SpecValidationError> {
    let mut errors = Vec::new();
    let scope = registry_scope(refl, doc);

    // Resolve every form path once; both sweeps read the same resolutions.
    //
    // A form resolution names the form *field*, not a class — the section id a
    // registry key is written against belongs to the class the form sits on, so
    // the owner is resolved from the parent path.
    let mut form_paths = doc.form_paths();
    form_paths.sort();
    let mut forms: Vec<FormInstance> = Vec::new();
    for path in form_paths {
        let res = match refl.resolve(&path) {
            Some(r) => r,
            None => continue,
        };
        if res.kind != SPEC_NODE_KIND_FORM {
            continue;
        }
        let field = match res.field {
            Some(f) => f,
            None => continue,
        };
        let slash = match path.rfind('/') {
            Some(s) if s > 0 => s,
            _ => continue,
        };
        let cls = match refl.resolve(&path[..slash]).and_then(|r| r.target_class) {
            Some(c) => c,
            None => continue,
        };
        forms.push(FormInstance { path, cls, field });
    }

    // 1. Declare.
    let mut declared: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for form in &forms {
        if form.cls.section_id.is_empty() {
            continue;
        }
        for ff in &form.field.form_fields {
            let value = doc.form_field_or(&form.path, &ff.name).trim().to_string();
            if value.is_empty() {
                continue;
            }
            declared
                .entry(format!("{}.{}", form.cls.section_id, ff.name))
                .or_default()
                .insert(value);
        }
    }

    // 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
    // The key is the *element class's* section id, not the `-LST` container's: a
    // target names the entry, so `FRE.@sectionId` reads as "an id of some
    // functional-requirement entry".
    let mut list_paths = doc.list_paths();
    list_paths.sort();
    for list_path in list_paths {
        let list_field = refl.resolve(&list_path).and_then(|r| r.field);
        let pattern = list_field
            .as_ref()
            .map(|f| f.section_id_pattern.clone())
            .unwrap_or_default();
        let mut stem = list_field.as_ref().map(|f| f.name.clone()).unwrap_or_default();
        if stem.is_empty() {
            stem = list_path.rsplit('/').next().unwrap_or(&list_path).to_string();
        }
        for (i, item_path) in doc.list_items(&list_path).iter().enumerate() {
            let section_id = match refl.resolve(item_path).and_then(|r| r.target_class) {
                Some(c) if !c.section_id.is_empty() => c.section_id,
                _ => continue,
            };
            let stored = doc.item_section_id(item_path).cloned();
            declared
                .entry(format!("{}.{}", section_id, K_SECTION_ID_SLOT))
                .or_default()
                .insert(effective_list_item_section_id(
                    stored.as_deref(),
                    &pattern,
                    i + 1,
                    &stem,
                ));
        }
    }

    // 2. Resolve.
    for form in &forms {
        for ff in &form.field.form_fields {
            if ff.refers_to.is_empty() {
                continue;
            }
            let value = doc.form_field_or(&form.path, &ff.name).trim().to_string();
            if value.is_empty() {
                continue;
            }

            // Every target must be in scope, not merely one of them: a
            // disjunction says the id may come from any of the listed registries,
            // so one absent registry is enough to make "no registry declares it"
            // unsound.
            if !ff
                .refers_to
                .iter()
                .all(|t| scope.contains(registry_section_id(t)))
            {
                continue;
            }

            for segment in value.split(',') {
                let id = segment.trim();
                if id.is_empty() {
                    continue;
                }
                let resolves = ff
                    .refers_to
                    .iter()
                    .any(|t| declared.get(t).is_some_and(|ids| ids.contains(id)));
                if resolves {
                    continue;
                }
                errors.push(SpecValidationError {
                    path: form.path.clone(),
                    code: SPEC_VALIDATION_CODE_DANGLING_REFERENCE.to_string(),
                    message: format!(
                        "form field \"{}\" references \"{}\", which no entry of {} {} declares",
                        ff.name,
                        id,
                        if ff.refers_to.len() == 1 {
                            "registry"
                        } else {
                            "registries"
                        },
                        ff.refers_to.join(", ")
                    ),
                });
            }
        }
    }

    errors
}

/// The section id part of a registry key written `<SECTIONID>.<slot>`. A key with
/// no dot is malformed — the static tier reports it — and is treated whole here
/// so it simply fails to match any section id.
fn registry_section_id(target: &str) -> &str {
    match target.find('.') {
        Some(dot) if dot > 0 => &target[..dot],
        _ => target,
    }
}

/// The registry section ids that are **in scope** for `doc`: the `@SectionId` of
/// every class reachable from a document root the document actually uses (csre2).
///
/// A `refersTo` target names its registry by section id, and a document can only
/// ever declare entries of registries its own root reaches. Anything outside this
/// set is absent from the document by construction — which is precisely the case
/// the dangling-reference check must not call an error.
///
/// The roots are read off the document rather than passed in: every path begins
/// with its root's segment, so the document already says which root(s) it belongs
/// to. A document spanning several roots contributes the union.
fn registry_scope(refl: &SpecReflection, doc: &SpecDocument) -> BTreeSet<String> {
    let mut root_types: BTreeSet<String> = BTreeSet::new();
    for group in [
        doc.content_paths(),
        doc.form_paths(),
        doc.list_paths(),
        doc.headline_paths(),
    ] {
        for path in group {
            let segment = match path.find('/') {
                Some(slash) => &path[..slash],
                None => path.as_str(),
            };
            if let Some(root) = refl.root_for_segment(segment) {
                root_types.insert(root.type_.clone());
            }
        }
    }

    let mut ids: BTreeSet<String> = BTreeSet::new();
    for root_type in root_types {
        for name in refl.reachable_class_names(&root_type) {
            if let Some(cls) = refl.class_named(&name) {
                if !cls.section_id.is_empty() {
                    ids.insert(cls.section_id.clone());
                }
            }
        }
    }
    ids
}
