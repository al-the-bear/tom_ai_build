//! `spec_validator` — validates a concrete [`SpecDocument`]'s values against a
//! [`SpecModel`] via the [`SpecReflection`] resolver, a faithful port of the Go
//! `spec_validator.go`.
//!
//! The check is over the values a document holds: every set path must resolve to
//! a node of a compatible kind, every form sub-key must name a real form field,
//! and every populated list must meet its `@Min` item count. Schema completeness
//! (mandatory-but-absent nodes) is a separate concern and is not reported here.

use crate::spec_document::SpecDocument;
use crate::spec_model::SpecModel;
use crate::spec_reflection::{SpecReflection, SPEC_NODE_KIND_FORM, SPEC_NODE_KIND_LIST};

/// Why a single value in a document is invalid against the model.
pub const SPEC_VALIDATION_CODE_DANGLING_PATH: &str = "danglingPath";
pub const SPEC_VALIDATION_CODE_KIND_MISMATCH: &str = "kindMismatch";
pub const SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD: &str = "unknownFormField";
pub const SPEC_VALIDATION_CODE_MIN_ITEMS: &str = "minItems";

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

    errors
}
