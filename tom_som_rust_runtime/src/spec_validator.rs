//! `spec_validator` — validates a concrete [`SpecDocument`]'s values against a
//! [`SpecModel`] via the [`SpecReflection`] resolver, a faithful port of the Go
//! `spec_validator.go`.
//!
//! The check is over the values a document holds: every set path must resolve to
//! a node of a compatible kind, every form sub-key must name a real form field,
//! and every populated list must meet its `@Min` item count. Schema completeness
//! (mandatory-but-absent nodes) is a separate concern and is not reported here.

use crate::spec_document::SpecDocument;
use crate::spec_model::{FormFieldSpec, SpecClass, SpecField, SpecModel, SPEC_FIELD_KIND_FORM};
use crate::spec_reflection::{
    SpecReflection, SPEC_NODE_KIND_FORM, SPEC_NODE_KIND_LIST, SPEC_NODE_KIND_SCALAR,
    SPEC_NODE_KIND_SECTION,
};
use crate::spec_section_id::{effective_list_item_section_id, K_SECTION_ID_SLOT};
use crate::spec_typed_values::{som_scalar_base, som_typed_text_readable};
use std::collections::{BTreeMap, BTreeSet};

/// Why a single value in a document is invalid against the model.
pub const SPEC_VALIDATION_CODE_DANGLING_PATH: &str = "danglingPath";
pub const SPEC_VALIDATION_CODE_KIND_MISMATCH: &str = "kindMismatch";
pub const SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD: &str = "unknownFormField";
pub const SPEC_VALIDATION_CODE_MIN_ITEMS: &str = "minItems";
pub const SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH: &str = "oneOfCaseMismatch";
pub const SPEC_VALIDATION_CODE_DANGLING_REFERENCE: &str = "danglingReference";
/// A form field whose model type is an enum holds a token the enum does not
/// declare. The typed read is forgiving (an unknown token answers `None`), and a
/// document is loaded far more often than it is written through a setter, so
/// without this the value is simply dropped. An EMPTY value is absence, not a
/// bad value, and is not reported.
pub const SPEC_VALIDATION_CODE_ENUM_VALUE_UNKNOWN: &str = "enumValueUnknown";
/// A form field that states a count (`Field.countOf`) holds a number that is
/// not the number of entries the document holds, or no whole number at all
/// (vsctsa43). A total kept by hand drifts from the list it describes the first
/// time the list changes and the total does not.
pub const SPEC_VALIDATION_CODE_COUNT_MISMATCH: &str = "countMismatch";
/// A typed field (`int`, `double`, `num` or `bool`) — a form field or a scalar
/// leaf — holds text its type cannot read (`lots` in an `int`). The typed read
/// refuses such text rather than answering `None`, and the setters refuse to
/// store it, but a document edited by hand or by another tool can still carry
/// it; this is where it is reported. Empty text is absence, not a bad value,
/// and is not reported.
pub const SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH: &str = "valueTypeMismatch";
/// A form field whose value is derived from other fields — a product
/// (`Field.productOf`) or a rank by a sibling field (`Field.rankOf`) — holds a
/// value the fields it is derived from do not give, or no number at all
/// (uamtc10). A risk score kept by hand drifts the first time probability or
/// impact changes and the score does not.
pub const SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH: &str = "derivedValueMismatch";

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
                // A form node is the one non-leaf that legitimately carries
                // content: it is the form's preamble, the free text before the
                // first field line (SOM §11.4 rule 7), in the same slot a plain
                // section's body uses.
                // A wrapper section (TextSection, ...) is the other: its class
                // is not exported, so it resolves to no class and its text is
                // stored at its own path, the way the YAML codec writes it.
                let is_wrapper_section =
                    res.kind == SPEC_NODE_KIND_SECTION && res.target_class.is_none();
                if !res.is_value_leaf() && res.kind != SPEC_NODE_KIND_FORM && !is_wrapper_section {
                    errors.push(SpecValidationError {
                        path: path.clone(),
                        code: SPEC_VALIDATION_CODE_KIND_MISMATCH.to_string(),
                        message: format!("expected a value leaf but path resolves to {}", res.kind),
                    });
                } else if res.kind == SPEC_NODE_KIND_SCALAR {
                    let ty = res.field.as_ref().map(|f| f.type_.as_str());
                    let value = doc.content(&path).cloned();
                    if !som_typed_text_readable(ty, value.as_deref()) {
                        errors.push(SpecValidationError {
                            path: path.clone(),
                            code: SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH.to_string(),
                            message: format!(
                                "holds \"{}\", which is not readable as {}",
                                value.as_deref().unwrap_or(""),
                                som_scalar_base(ty).unwrap_or("")
                            ),
                        });
                    }
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
        let declared: std::collections::HashMap<&str, _> = field
            .form_fields
            .iter()
            .map(|ff| (ff.name.as_str(), ff))
            .collect();
        for name in doc.form_field_names(&path) {
            let spec = match declared.get(name.as_str()) {
                Some(spec) => *spec,
                None => {
                    errors.push(SpecValidationError {
                        path: path.clone(),
                        code: SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD.to_string(),
                        message: format!(
                            "form field \"{}\" is not declared on {}",
                            name, field.name
                        ),
                    });
                    continue;
                }
            };
            if spec.enum_values.is_empty() {
                let text = doc.form_field_or(&path, &name);
                // A stated count (`count_of`) is checked by countMismatch, a
                // derived value (`product_of`, `rank_of`) by
                // derivedValueMismatch; both already report text that is no
                // number, and one finding is enough.
                if spec.count_of.is_empty()
                    && spec.product_of.is_empty()
                    && spec.rank_of.is_none()
                    && !som_typed_text_readable(Some(&spec.type_), Some(&text))
                {
                    errors.push(SpecValidationError {
                        path: path.clone(),
                        code: SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH.to_string(),
                        message: format!(
                            "form field \"{}\" holds \"{}\", which is not readable as {}",
                            name,
                            text,
                            som_scalar_base(Some(&spec.type_)).unwrap_or("")
                        ),
                    });
                }
                continue;
            }
            let value = doc.form_field_or(&path, &name);
            // Absence is not a bad value.
            if value.is_empty() {
                continue;
            }
            if !spec.enum_values.iter().any(|v| v == &value) {
                errors.push(SpecValidationError {
                    path: path.clone(),
                    code: SPEC_VALIDATION_CODE_ENUM_VALUE_UNKNOWN.to_string(),
                    message: format!(
                        "form field \"{}\" holds \"{}\", which {} does not declare ({})",
                        name,
                        value,
                        spec.type_,
                        spec.enum_values.join(", ")
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

    // 6. Stated counts (instance tier, vsctsa43).
    //
    // A form field declaring `countOf` states how many entries the document
    // holds; only the instance tier can count them.
    errors.extend(validate_count_instances(&refl, doc));
    errors.extend(validate_derived_values(&refl, doc));

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
    let forms = resolved_forms(refl, doc);

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

/// Instance-tier stated-count check (vsctsa43): every non-empty value of a
/// `countOf` form field must be a whole number equal to the number of entries
/// the document holds.
///
/// An **entry** is a list item whose element class carries `@SectionId(X)`. A
/// target `X` counts every such entry; `X.f=v` counts only the entries one of
/// whose own forms — a form member of the entry, at `<item>/<member>` — holds
/// `v` in form field `f`. The count is the sum over the targets. As with the
/// reference check, a target whose section id the document's root cannot reach
/// makes the field undecidable here, so it is skipped rather than reported, and
/// an empty value is completeness, not a count.
fn validate_count_instances(refl: &SpecReflection, doc: &SpecDocument) -> Vec<SpecValidationError> {
    let forms = resolved_forms(refl, doc);
    if !forms
        .iter()
        .any(|f| f.field.form_fields.iter().any(|ff| !ff.count_of.is_empty()))
    {
        return Vec::new();
    }
    let scope = registry_scope(refl, doc);

    // Every entry, by its class's section id, with the form values its own form
    // members hold.
    let mut entries_by_id: BTreeMap<String, Vec<String>> = BTreeMap::new();
    let mut list_paths = doc.list_paths();
    list_paths.sort();
    for list_path in list_paths {
        for item in doc.list_items(&list_path) {
            let id = match refl.resolve(&item).and_then(|r| r.target_class) {
                Some(c) if !c.section_id.is_empty() => c.section_id,
                _ => continue,
            };
            entries_by_id.entry(id).or_default().push(item);
        }
    }
    let mut values_by_item: BTreeMap<String, BTreeMap<String, BTreeSet<String>>> =
        BTreeMap::new();
    for path in doc.form_paths() {
        let slash = match path.rfind('/') {
            Some(s) if s > 0 => s,
            _ => continue,
        };
        let owner = &path[..slash];
        let field = match refl.resolve(&path).and_then(|r| r.field) {
            Some(f) => f,
            None => continue,
        };
        for ff in &field.form_fields {
            let v = doc.form_field_or(&path, &ff.name).trim().to_string();
            if v.is_empty() {
                continue;
            }
            values_by_item
                .entry(owner.to_string())
                .or_default()
                .entry(ff.name.clone())
                .or_default()
                .insert(v);
        }
    }

    // A target written `./…` counts only the entries beneath `owner`, the
    // section holding the form; any other target counts the whole document.
    let count_target = |target: &str, owner: &str| -> usize {
        let scoped = target.starts_with("./");
        let target = if scoped { &target[2..] } else { target };
        let prefix = format!("{}/", owner);
        let in_scope = |item: &String| !scoped || item.starts_with(&prefix);
        let dot = match target.find('.') {
            Some(d) => d,
            None => {
                return entries_by_id
                    .get(target)
                    .map_or(0, |e| e.iter().filter(|i| in_scope(i)).count())
            }
        };
        let id = &target[..dot];
        let eq = target[dot..].find('=').map(|e| dot + e);
        let field = &target[dot + 1..eq.unwrap_or(target.len())];
        let value = eq.map_or("", |e| &target[e + 1..]);
        entries_by_id.get(id).map_or(0, |items| {
            items
                .iter()
                .filter(|item| in_scope(item))
                .filter(|item| {
                    values_by_item
                        .get(item.as_str())
                        .and_then(|m| m.get(field))
                        .is_some_and(|vs| vs.contains(value))
                })
                .count()
        })
    };

    let mut errors = Vec::new();
    for form in &forms {
        for ff in &form.field.form_fields {
            if ff.count_of.is_empty() {
                continue;
            }
            let stated = doc.form_field_or(&form.path, &ff.name).trim().to_string();
            if stated.is_empty() {
                continue;
            }
            if !ff
                .count_of
                .iter()
                .all(|t| scope.contains(registry_section_id(count_target_id(t))))
            {
                continue;
            }
            let owner = &form.path[..form.path.rfind('/').unwrap_or(0)];
            let counted: usize = ff.count_of.iter().map(|t| count_target(t, owner)).sum();
            let targets = ff.count_of.join(" + ");
            if !stated.bytes().all(|b| b.is_ascii_digit()) {
                errors.push(SpecValidationError {
                    path: form.path.clone(),
                    code: SPEC_VALIDATION_CODE_COUNT_MISMATCH.to_string(),
                    message: format!(
                        "form field \"{}\" states \"{}\", which is not a whole number — it counts {}, of which the document holds {}",
                        ff.name, stated, targets, counted
                    ),
                });
            } else if stated.trim_start_matches('0') != counted.to_string().trim_start_matches('0') {
                errors.push(SpecValidationError {
                    path: form.path.clone(),
                    code: SPEC_VALIDATION_CODE_COUNT_MISMATCH.to_string(),
                    message: format!(
                        "form field \"{}\" states {}, but the document holds {} (counting {})",
                        ff.name, stated, counted, targets
                    ),
                });
            }
        }
    }
    errors
}

/// The section id of a `countOf` target — the part before any `.field=value`,
/// without the `./` scope prefix.
fn count_target_id(target: &str) -> &str {
    let target = target.strip_prefix("./").unwrap_or(target);
    match target.find('.') {
        Some(dot) => &target[..dot],
        None => target,
    }
}

/// Instance-tier derived-value check (uamtc10): a `productOf` field must hold
/// the product of its operands, and a `rankOf` field must rank the instances of
/// its form by their score, highest first.
///
/// **Operands.** A plain operand is a field of the same form; `F.x` is field `x`
/// of the form `F` beside it, at `<owner>/F` where `<owner>` is the section
/// holding this form. A numeric operand contributes its number, an enum operand
/// its 1-based position among the enum's values. When the value or any operand
/// is empty — or an operand is unreadable, which other checks report — the
/// product is undecidable and is skipped; a stated value that is no number at
/// all is still reported.
///
/// **Precision.** The stated number is held to the precision it is written in:
/// `2.8` matches 0.7 × 4.0, and `15` matches 3 × 5, but `2.9` does not.
///
/// **Ranks.** Over every instance of the same form whose rank and score are
/// both filled, the ranks must be the whole numbers 1 to n, each once, and an
/// instance may not rank below one that scores lower. Equal scores take their
/// ranks in any order. Each offending instance is reported once.
fn validate_derived_values(refl: &SpecReflection, doc: &SpecDocument) -> Vec<SpecValidationError> {
    let forms = resolved_forms(refl, doc);
    if !forms.iter().any(|f| {
        f.field
            .form_fields
            .iter()
            .any(|ff| !ff.product_of.is_empty() || ff.rank_of.is_some())
    }) {
        return Vec::new();
    }

    // The number a filled form field contributes, or `None` when it is empty or
    // unreadable.
    let number_of = |form_path: &str, spec: &FormFieldSpec| -> Option<f64> {
        let v = doc.form_field_or(form_path, &spec.name).trim().to_string();
        if v.is_empty() {
            return None;
        }
        if !spec.enum_values.is_empty() {
            return spec
                .enum_values
                .iter()
                .position(|e| *e == v)
                .map(|i| (i + 1) as f64);
        }
        if !is_decimal_number(&v) {
            return None;
        }
        v.parse::<f64>().ok()
    };

    // The spec of field `name` on the form at `path`, or `None`.
    let spec_at = |path: &str, name: &str| -> Option<FormFieldSpec> {
        let res = refl.resolve(path)?;
        if res.kind != SPEC_NODE_KIND_FORM {
            return None;
        }
        res.field?.form_fields.into_iter().find(|ff| ff.name == name)
    };

    struct Ranked {
        path: String,
        name: String,
        stated: String,
        score: f64,
    }
    let mut ranked: Vec<(String, Vec<Ranked>)> = Vec::new();

    let mut errors = Vec::new();
    for form in &forms {
        let owner = &form.path[..form.path.rfind('/').unwrap_or(0)];
        for ff in &form.field.form_fields {
            if !ff.product_of.is_empty() {
                let stated = doc.form_field_or(&form.path, &ff.name).trim().to_string();
                if !stated.is_empty() {
                    let mut product: Option<f64> = Some(1.0);
                    for operand in &ff.product_of {
                        let (path, name) = match operand.find('.') {
                            Some(dot) => (format!("{}/{}", owner, &operand[..dot]), &operand[dot + 1..]),
                            None => (form.path.clone(), operand.as_str()),
                        };
                        let n = spec_at(&path, name).and_then(|spec| number_of(&path, &spec));
                        match n {
                            Some(n) => product = product.map(|p| p * n),
                            None => {
                                product = None;
                                break;
                            }
                        }
                    }
                    let operands = ff.product_of.join(" × ");
                    if !is_decimal_number(&stated) {
                        errors.push(SpecValidationError {
                            path: form.path.clone(),
                            code: SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH.to_string(),
                            message: format!(
                                "form field \"{}\" states \"{}\", which is not a number — it is the product {}",
                                ff.name, stated, operands
                            ),
                        });
                    } else if let Some(product) = product {
                        let decimals = stated.find('.').map_or(0, |dot| stated.len() - dot - 1);
                        let tolerance = 0.5 * pow10(-(decimals as i32)) + 1e-9;
                        let value: f64 = stated.parse().unwrap_or(f64::NAN);
                        if !((value - product).abs() <= tolerance) {
                            errors.push(SpecValidationError {
                                path: form.path.clone(),
                                code: SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH.to_string(),
                                message: format!(
                                    "form field \"{}\" states {}, but {} gives {}",
                                    ff.name,
                                    stated,
                                    operands,
                                    format_number(product)
                                ),
                            });
                        }
                    }
                }
            }
            if let Some(by) = &ff.rank_of {
                let stated = doc.form_field_or(&form.path, &ff.name).trim().to_string();
                let score = spec_at(&form.path, by).and_then(|spec| number_of(&form.path, &spec));
                if let (false, Some(score)) = (stated.is_empty(), score) {
                    let key = format!("{}#{}#{}", form.cls.name, form.field.name, ff.name);
                    let entry = Ranked {
                        path: form.path.clone(),
                        name: ff.name.clone(),
                        stated,
                        score,
                    };
                    match ranked.iter_mut().find(|(k, _)| *k == key) {
                        Some((_, group)) => group.push(entry),
                        None => ranked.push((key, vec![entry])),
                    }
                }
            }
        }
    }

    for (_, group) in &ranked {
        let n = group.len();
        let mut rank_of: BTreeMap<&str, usize> = BTreeMap::new();
        let mut seen: BTreeMap<usize, usize> = BTreeMap::new();
        for e in group {
            if e.stated.is_empty() || !e.stated.bytes().all(|b| b.is_ascii_digit()) {
                continue;
            }
            // Too large for a usize: out of range either way.
            let r = e.stated.parse::<usize>().unwrap_or(n + 1);
            rank_of.insert(e.path.as_str(), r);
            *seen.entry(r).or_insert(0) += 1;
        }
        for e in group {
            let problem = match rank_of.get(e.path.as_str()) {
                None => Some(format!("states \"{}\", which is not a whole number", e.stated)),
                Some(&r) if r < 1 || r > n || seen[&r] > 1 => Some(format!(
                    "states rank {}, but the {} ranked entries take the ranks 1 to {}, each once",
                    r, n, n
                )),
                Some(&r) => group.iter().find_map(|o| match rank_of.get(o.path.as_str()) {
                    Some(&ro) if o.score < e.score && ro < r => Some(format!(
                        "ranks {} with score {}, below an entry ranked {} with the lower score {}",
                        r,
                        format_number(e.score),
                        ro,
                        format_number(o.score)
                    )),
                    _ => None,
                }),
            };
            if let Some(problem) = problem {
                errors.push(SpecValidationError {
                    path: e.path.clone(),
                    code: SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH.to_string(),
                    message: format!("form field \"{}\" {}", e.name, problem),
                });
            }
        }
    }
    // Like every phase's group, the findings are ordered by path; the sort is
    // stable, so a path's own findings keep the order they were found in.
    errors.sort_by(|a, b| a.path.cmp(&b.path));
    errors
}

/// Whether `s` matches the reference's `^-?[0-9]+(\.[0-9]+)?$`.
fn is_decimal_number(s: &str) -> bool {
    let s = s.strip_prefix('-').unwrap_or(s);
    let digits = |p: &str| !p.is_empty() && p.bytes().all(|b| b.is_ascii_digit());
    match s.split_once('.') {
        Some((int_part, frac)) => digits(int_part) && digits(frac),
        None => digits(s),
    }
}

/// 10^`exponent` by repeated multiplication, as the reference computes it.
fn pow10(exponent: i32) -> f64 {
    let mut v = 1.0;
    for _ in 0..exponent.unsigned_abs() {
        v *= 10.0;
    }
    if exponent < 0 {
        1.0 / v
    } else {
        v
    }
}

/// A whole number without a fraction, any other number in its shortest form.
fn format_number(v: f64) -> String {
    if v == v.round() && v.abs() < 1e15 {
        format!("{}", v as i64)
    } else {
        format!("{}", v)
    }
}

/// Every form instance in `doc` with its field and the class it sits on, in
/// path order — the shape both the reference and the count check sweep.
fn resolved_forms(refl: &SpecReflection, doc: &SpecDocument) -> Vec<FormInstance> {
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
    forms
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
