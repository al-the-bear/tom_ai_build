//! `spec_model` — in-memory representation of the exported TomSpecs class graph
//! (the spec-model meta-data file), a faithful port of the Go `spec_model.go`.
//!
//! The model is a class graph, not an expanded tree: each class appears once and
//! field `element_type` / `type` references are followed on demand by a
//! traversal. This is the "reflection" surface — it describes any document's
//! structure, independent of the values a concrete document holds.

use std::collections::HashMap;

use crate::json::Json;

/// Field render kind: an expandable list of element instances.
pub const SPEC_FIELD_KIND_LIST: &str = "list";
/// Field render kind: a `@Form` content section with named sub-fields.
pub const SPEC_FIELD_KIND_FORM: &str = "form";
/// Field render kind: a sub-section that collapses into its target class.
pub const SPEC_FIELD_KIND_SECTION: &str = "section";
/// Field render kind: a free-text content leaf.
pub const SPEC_FIELD_KIND_CONTENT: &str = "content";
/// Field render kind: an enum value leaf.
pub const SPEC_FIELD_KIND_ENUM: &str = "enum";
/// Field render kind: a complex nested class that collapses into its target.
pub const SPEC_FIELD_KIND_COMPLEX: &str = "complex";
/// Field render kind: a scalar value leaf.
pub const SPEC_FIELD_KIND_SCALAR: &str = "scalar";

/// Parses a raw kind string, falling back to `scalar`.
pub fn parse_field_kind(raw: &str) -> String {
    match raw {
        SPEC_FIELD_KIND_LIST
        | SPEC_FIELD_KIND_FORM
        | SPEC_FIELD_KIND_SECTION
        | SPEC_FIELD_KIND_CONTENT
        | SPEC_FIELD_KIND_ENUM
        | SPEC_FIELD_KIND_COMPLEX
        | SPEC_FIELD_KIND_SCALAR => raw.to_string(),
        _ => SPEC_FIELD_KIND_SCALAR.to_string(),
    }
}

/// A single annotation captured losslessly from the model source: its name and
/// the resolved argument map.
#[derive(Debug, Clone)]
pub struct SpecAnnotation {
    pub name: String,
    pub arguments: Vec<(String, Json)>,
}

impl SpecAnnotation {
    /// Returns the resolved value of a named annotation argument.
    pub fn argument(&self, key: &str) -> Option<&Json> {
        self.arguments.iter().find(|(k, _)| k == key).map(|(_, v)| v)
    }
}

/// A single form field within a `@Form` content section.
#[derive(Debug, Clone)]
pub struct FormFieldSpec {
    pub name: String,
    pub label: String,
    pub type_: String,
    pub hint: String,
    pub required: bool,
    /// Structural role of the field (YRD6): `"title"` (view onto the owning
    /// section's headline), `"id"` (view onto the stored section id), or `""`
    /// for an ordinary form-value field.
    pub role: String,
    /// Predefined initial content (YRD6, meta-only editor prefill), `""` when
    /// absent.
    pub initial: String,
}

/// A single field of a [`SpecClass`].
#[derive(Debug, Clone)]
pub struct SpecField {
    pub name: String,
    pub kind: String,
    pub doc: String,
    pub help: String,
    /// The `@Headline(text)` default headline (YRD4), `""` when unannotated.
    /// Render precedence: stored headline > this default > name derivation.
    pub headline: String,
    pub section_id: String,
    pub section_id_pattern: String,
    pub element_type: String,
    pub element_is_complex: bool,
    pub min: Option<i64>,
    pub content_type: String,
    pub section_type: String,
    pub enum_type: String,
    pub enum_values: Vec<String>,
    pub type_: String,
    pub form_fields: Vec<FormFieldSpec>,
    pub annotations: Vec<SpecAnnotation>,
    /// The field's `@SerializationOrder` (its declaration order in the SOM
    /// source), or `None` when unannotated. Drives model-aware YAML member
    /// ordering (AA1 criterion 7).
    pub serialization_order: Option<i64>,
}

impl SpecField {
    /// Reports whether expanding this field reveals further tree nodes.
    pub fn is_expandable(&self) -> bool {
        self.kind == SPEC_FIELD_KIND_LIST || self.kind == SPEC_FIELD_KIND_COMPLEX
    }

    /// Returns the named annotation on this field, or `None`.
    pub fn annotation(&self, name: &str) -> Option<&SpecAnnotation> {
        self.annotations.iter().find(|a| a.name == name)
    }
}

/// A model class with its fields.
#[derive(Debug, Clone)]
pub struct SpecClass {
    pub name: String,
    pub section_id: String,
    pub doc: String,
    pub help: String,
    /// The class-level `@Headline(text)` default headline (YRD4), `""` when
    /// unannotated. A field-level `@Headline` on the instantiating field wins
    /// over this.
    pub headline: String,
    pub maps_to: String,
    pub detailed_in: String,
    pub fields: Vec<SpecField>,
    pub annotations: Vec<SpecAnnotation>,
}

impl SpecClass {
    /// Returns the field with the given name, or `None`.
    pub fn field_named(&self, name: &str) -> Option<&SpecField> {
        self.fields.iter().find(|f| f.name == name)
    }

    /// Returns the named annotation on this class, or `None`.
    pub fn annotation(&self, name: &str) -> Option<&SpecAnnotation> {
        self.annotations.iter().find(|a| a.name == name)
    }
}

/// A document root (a class carrying `@Document`).
#[derive(Debug, Clone)]
pub struct SpecRoot {
    pub type_: String,
    pub title: String,
    pub section_id: String,
    pub description: String,
    pub doc: String,
}

/// The complete exported model.
#[derive(Debug, Clone)]
pub struct SpecModel {
    pub roots: Vec<SpecRoot>,
    pub classes: HashMap<String, SpecClass>,
    pub model_version: i64,
    pub model_version_label: String,
}

impl SpecModel {
    /// Returns the class with the given name, or `None`.
    pub fn class_named(&self, name: &str) -> Option<&SpecClass> {
        if name.is_empty() {
            return None;
        }
        self.classes.get(name)
    }

    /// Returns the document root whose [`SpecRoot::type_`] equals `ty` (§ item 12).
    ///
    /// Replaces the recurring `roots.iter().find(|r| r.type_ == …)` boilerplate.
    /// Returns `Err` when no root carries that type — the message names the
    /// missing type and lists the ones that do exist.
    pub fn root_by_type(&self, ty: &str) -> Result<&SpecRoot, String> {
        if let Some(root) = self.roots.iter().find(|r| r.type_ == ty) {
            return Ok(root);
        }
        let available: Vec<&str> = self.roots.iter().map(|r| r.type_.as_str()).collect();
        Err(format!(
            "no document root with type '{}' (have: {})",
            ty,
            available.join(", ")
        ))
    }

    /// Returns the `major.minor` DocSpecs version string for this model — see
    /// [`som_model_version_string`].
    pub fn model_version_string(&self) -> String {
        som_model_version_string(self.model_version, &self.model_version_label)
    }

    /// Decodes a meta-data JSON document into a `SpecModel`, normalising every
    /// field kind through [`parse_field_kind`].
    pub fn from_json_str(data: &str) -> Result<SpecModel, String> {
        let root = Json::parse(data)?;
        Ok(Self::from_json(&root))
    }

    /// Builds a `SpecModel` from a parsed [`Json`] value.
    pub fn from_json(root: &Json) -> SpecModel {
        let mut roots = Vec::new();
        if let Some(arr) = root.get("roots").and_then(|v| v.as_array()) {
            for r in arr {
                roots.push(SpecRoot {
                    type_: r.str_or("type"),
                    title: r.str_or("title"),
                    section_id: r.str_or("sectionId"),
                    description: r.str_or("description"),
                    doc: r.str_or("doc"),
                });
            }
        }

        let mut classes = HashMap::new();
        if let Some(obj) = root.get("classes").and_then(|v| v.as_object()) {
            for (name, cls) in obj {
                classes.insert(name.clone(), class_from_json(name, cls));
            }
        }

        let model_version = root.get("modelVersion").and_then(|v| v.as_i64()).unwrap_or(0);
        let model_version_label = root.str_or("modelVersionLabel");

        SpecModel {
            roots,
            classes,
            model_version,
            model_version_label,
        }
    }
}

/// Derives the `major.minor` DocSpecs version string from a model's integer
/// version and its optional free-form label (port of Go's
/// `SomModelVersionString` / Python's `som_model_version_string`).
///
/// When the label's `+`-stripped core has at least two dot-separated integer
/// components, those become `major.minor`; otherwise the result is `<major>.0`.
pub fn som_model_version_string(major: i64, label: &str) -> String {
    if !label.is_empty() {
        let core = label.split('+').next().unwrap_or("").trim();
        let parts: Vec<&str> = core.split('.').collect();
        if parts.len() >= 2 {
            let maj = parts[0].trim();
            let minor = parts[1].trim();
            if is_signed_digits(maj) && is_signed_digits(minor) {
                let maj_n: i64 = maj.parse().unwrap_or(0);
                let minor_n: i64 = minor.parse().unwrap_or(0);
                return format!("{}.{}", maj_n, minor_n);
            }
        }
    }
    format!("{}.0", major)
}

/// Reports whether `s` matches `/^[+-]?[0-9]+$/`.
fn is_signed_digits(s: &str) -> bool {
    let body = match s.strip_prefix(['+', '-']) {
        Some(rest) => rest,
        None => s,
    };
    !body.is_empty() && body.bytes().all(|b| b.is_ascii_digit())
}

fn class_from_json(name: &str, cls: &Json) -> SpecClass {
    let mut fields = Vec::new();
    if let Some(arr) = cls.get("fields").and_then(|v| v.as_array()) {
        for f in arr {
            fields.push(field_from_json(f));
        }
    }
    SpecClass {
        name: if cls.str_or("name").is_empty() {
            name.to_string()
        } else {
            cls.str_or("name")
        },
        section_id: cls.str_or("sectionId"),
        doc: cls.str_or("doc"),
        help: cls.str_or("help"),
        headline: cls.str_or("headline"),
        maps_to: cls.str_or("mapsTo"),
        detailed_in: cls.str_or("detailedIn"),
        fields,
        annotations: annotations_from_json(cls.get("annotations")),
    }
}

fn field_from_json(f: &Json) -> SpecField {
    let mut enum_values = Vec::new();
    if let Some(arr) = f.get("enumValues").and_then(|v| v.as_array()) {
        for v in arr {
            if let Some(s) = v.as_str() {
                enum_values.push(s.to_string());
            }
        }
    }
    let mut form_fields = Vec::new();
    if let Some(arr) = f.get("formFields").and_then(|v| v.as_array()) {
        for ff in arr {
            let mut type_ = ff.str_or("type");
            if type_.is_empty() {
                type_ = "String".to_string();
            }
            let mut label = ff.str_or("label");
            let fname = ff.str_or("name");
            if label.is_empty() {
                label = fname.clone();
            }
            form_fields.push(FormFieldSpec {
                name: fname,
                label,
                type_,
                hint: ff.str_or("hint"),
                required: ff.bool_or("required"),
                role: ff.str_or("role"),
                initial: ff.str_or("initial"),
            });
        }
    }
    SpecField {
        name: f.str_or("name"),
        kind: parse_field_kind(&f.str_or("kind")),
        doc: f.str_or("doc"),
        help: f.str_or("help"),
        headline: f.str_or("headline"),
        section_id: f.str_or("sectionId"),
        section_id_pattern: f.str_or("sectionIdPattern"),
        element_type: f.str_or("elementType"),
        element_is_complex: f.bool_or("elementIsComplex"),
        min: f.get("min").and_then(|v| v.as_i64()),
        content_type: f.str_or("contentType"),
        section_type: f.str_or("sectionType"),
        enum_type: f.str_or("enumType"),
        enum_values,
        type_: f.str_or("type"),
        form_fields,
        annotations: annotations_from_json(f.get("annotations")),
        serialization_order: f.get("serializationOrder").and_then(|v| v.as_i64()),
    }
}

fn annotations_from_json(v: Option<&Json>) -> Vec<SpecAnnotation> {
    let mut out = Vec::new();
    if let Some(arr) = v.and_then(|j| j.as_array()) {
        for a in arr {
            let arguments = match a.get("arguments") {
                Some(Json::Object(pairs)) => pairs.clone(),
                _ => Vec::new(),
            };
            out.push(SpecAnnotation {
                name: a.str_or("name"),
                arguments,
            });
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    /// A two-root model, mirroring the Dart `twoRootModel` fixture.
    fn two_root_model() -> SpecModel {
        SpecModel::from_json_str(
            r#"{
                "roots": [
                    {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
                    {"type": "Beta", "title": "Beta Doc", "sectionId": "B00"}
                ],
                "classes": {}
            }"#,
        )
        .unwrap()
    }

    #[test]
    fn root_by_type_returns_the_root_whose_type_matches() {
        let model = two_root_model();
        assert_eq!(model.root_by_type("Alpha").unwrap().title, "Alpha Doc");
        assert_eq!(model.root_by_type("Beta").unwrap().section_id, "B00");
    }

    #[test]
    fn root_by_type_errors_naming_the_missing_and_available_types() {
        let model = two_root_model();
        let err = model.root_by_type("Gamma").unwrap_err();
        assert!(err.contains("Gamma"), "message names the missing type: {err}");
        assert!(err.contains("Alpha"), "message lists Alpha: {err}");
        assert!(err.contains("Beta"), "message lists Beta: {err}");
    }
}
