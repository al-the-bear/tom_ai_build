//! `spec_editor` — the generic, meta-model-driven modification API (YRD7), a
//! faithful port of the Dart `spec_editor.dart` (and the Python
//! `spec_editor.py`).
//!
//! [`SpecEditor`] lets a consumer walk any document's meta tree and
//! create/modify/delete sections, list items, headlines, ids, content and
//! **typed** form fields *without a generated facade*: every operation resolves
//! its path against the [`SpecModel`] first ([`SpecReflection::resolve`]) and
//! converts values at the store boundary through the same
//! [`spec_typed_values`](crate::spec_typed_values) helpers the generated
//! accessors call — so a typed facade is provably a thin layer over exactly this
//! API.
//!
//! Typed contract (mirrored by all nine runtimes):
//!   * `int` / `double` / `num` / `bool` values are native on both sides —
//!     carried by the [`SomValue`] tagged enum, because a generic API needs one
//!     value type that still tells `2` from `2.0` from `"2"`;
//!   * enum values travel as validated **constant-name strings** at this generic
//!     layer (`"high"`), because the generic API has no generated enum types —
//!     only the facade layer converts to native constants;
//!   * `None` (or `""`) clears a value (D4);
//!   * reads are forgiving (unparsable stored text reads as `None`), writes are
//!     strict (`Err` for a wrong value type or an out-of-domain enum name).
//!
//! Rust has no exceptions, so every operation the Dart reference throws
//! `ArgumentError` from returns `Result<_, String>` instead — the crate's error
//! idiom for a caller-supplied value that does not fit the model. Rust also has
//! no optional parameters, so `add_list_item` splits into three methods exactly
//! as [`SomList::add`](crate::som_facade::SomList::add) does (decision AG-D2).

use crate::spec_document::SpecDocument;
use crate::spec_model::{FormFieldSpec, SpecField, SpecModel};
use crate::spec_reflection::{
    SpecReflection, SpecResolution, SPEC_NODE_KIND_ENUM_VALUE, SPEC_NODE_KIND_FORM,
    SPEC_NODE_KIND_LIST, SPEC_NODE_KIND_SCALAR,
};
use crate::spec_section_id::{generate_list_item_section_id, today_month_day};
use crate::spec_typed_values::{
    som_format_bool, som_format_double, som_format_enum_name, som_format_int, som_format_num,
    som_parse_bool, som_parse_double, som_parse_enum_name, som_parse_int, som_parse_num, SomNum,
};

/// A typed value at the generic editing boundary.
///
/// The generic API has no static type per path — the model supplies it — so a
/// value crossing the boundary carries its own tag. The distinction matters:
/// writing [`SomValue::Int`] `2` into a `double` field stores `"2.0"`, while
/// writing [`SomValue::Str`] `"2"` into the same field stores `"2"` verbatim
/// (the plain-text serialization is authoritative). Collapsing the two would
/// silently change what lands in the store.
#[derive(Debug, Clone, PartialEq)]
pub enum SomValue {
    Int(i64),
    Double(f64),
    Bool(bool),
    Str(String),
}

impl SomValue {
    /// Returns the string when this is a [`SomValue::Str`], else `None`.
    pub fn as_str(&self) -> Option<&str> {
        match self {
            SomValue::Str(s) => Some(s),
            _ => None,
        }
    }
}

/// Strips a trailing `?` from a declared type name; an empty name means "no
/// declared type" (the Rust model's absent-value sentinel, where Dart has null).
fn scalar_base(type_name: &str) -> Option<&str> {
    if type_name.is_empty() {
        return None;
    }
    Some(type_name.strip_suffix('?').unwrap_or(type_name))
}

/// Generic, typed, meta-validated editing over a [`SpecDocument`].
///
/// The editor borrows the document mutably for its lifetime (Dart/Python share
/// one object by reference; Rust makes the exclusive access explicit). Read the
/// raw stores through the public [`SpecEditor::document`] field while an editor
/// is alive.
pub struct SpecEditor<'d, 'm> {
    /// The document being edited (the sparse value stores).
    pub document: &'d mut SpecDocument,
    /// The value-free meta-model queries the editor validates against.
    pub reflection: SpecReflection<'m>,
}

impl<'d, 'm> SpecEditor<'d, 'm> {
    /// Binds an editor to a document and a reflection surface.
    pub fn new(document: &'d mut SpecDocument, reflection: SpecReflection<'m>) -> SpecEditor<'d, 'm> {
        SpecEditor {
            document,
            reflection,
        }
    }

    /// Convenience: builds the editor for `document` over `model`.
    pub fn for_model(document: &'d mut SpecDocument, model: &'m SpecModel) -> SpecEditor<'d, 'm> {
        SpecEditor::new(document, SpecReflection::new(model))
    }

    // --- resolution ----------------------------------------------------------

    /// Resolves `path` against the meta-model, erroring for a dangling path —
    /// the strict companion to [`SpecReflection::resolve`].
    pub fn resolve(&self, path: &str) -> Result<SpecResolution, String> {
        self.reflection
            .resolve(path)
            .ok_or_else(|| format!("path '{}' does not resolve against the model", path))
    }

    // --- value leaves (content / scalar / enum / scalar list item) -----------

    /// The typed value at the value leaf `path`, or `None` when unset.
    ///
    /// The returned variant follows the model: `int`/`double`/`num`/`bool`
    /// scalars return the parsed native value, enum leaves the validated
    /// constant name, everything else the raw string. Errors when `path` is not
    /// a value leaf.
    pub fn value(&self, path: &str) -> Result<Option<SomValue>, String> {
        let r = self.value_leaf(path)?;
        let raw = match self.document.content(path) {
            Some(raw) if !raw.is_empty() => raw.clone(),
            _ => return Ok(None),
        };
        let field_type = r.field.as_ref().map(|f| f.type_.as_str()).unwrap_or("");
        if r.kind == SPEC_NODE_KIND_ENUM_VALUE {
            let empty: Vec<String> = Vec::new();
            let values = r.field.as_ref().map(|f| &f.enum_values).unwrap_or(&empty);
            return Ok(som_parse_enum_name(Some(&raw), values).map(SomValue::Str));
        }
        Ok(parse_typed(&raw, scalar_base(field_type)))
    }

    /// Sets the value leaf at `path` to `v`, converting at the store boundary.
    ///
    /// `None` clears. For typed scalars `v` must be the native variant (or a
    /// [`SomValue::Str`], taken verbatim); for enum leaves `v` must be one of the
    /// field's constant names. Errors for a non-leaf path, a wrong value type, or
    /// an out-of-domain enum name.
    pub fn set_value(&mut self, path: &str, v: Option<SomValue>) -> Result<(), String> {
        let r = self.value_leaf(path)?;
        let stored = format_for_store(v.as_ref(), &r.kind, r.field.as_ref(), path, None, None)?;
        self.document.set_content(path, &stored);
        Ok(())
    }

    fn value_leaf(&self, path: &str) -> Result<SpecResolution, String> {
        let r = self.resolve(path)?;
        if !r.is_value_leaf() {
            return Err(format!(
                "path '{}' is a {} node, not a value leaf",
                path, r.kind
            ));
        }
        Ok(r)
    }

    // --- headlines (YRD3) ----------------------------------------------------

    /// The stored headline at `path`, or `None` when the section renders its
    /// effective default title.
    pub fn headline(&self, path: &str) -> Result<Option<String>, String> {
        self.resolve(path)?;
        Ok(self.document.headline(path).cloned())
    }

    /// Sets the stored headline at `path`; empty/`None` returns the section to
    /// its default title.
    pub fn set_headline(&mut self, path: &str, value: Option<&str>) -> Result<(), String> {
        self.resolve(path)?;
        self.document.set_headline(path, value.unwrap_or(""));
        Ok(())
    }

    // --- typed form fields ---------------------------------------------------

    /// The typed value of form `field` at the `@Form` section `path`, or `None`
    /// when unset.
    ///
    /// Reads the form store and parses per the declared field type (enum fields
    /// return the validated constant name). Errors for a non-form path or an
    /// unknown field name.
    pub fn form_value(&self, path: &str, field: &str) -> Result<Option<SomValue>, String> {
        let ff = self.form_field(path, field)?;
        let raw = match self.document.form_field(path, field) {
            Some(raw) if !raw.is_empty() => raw.clone(),
            _ => return Ok(None),
        };
        if !ff.enum_values.is_empty() {
            return Ok(som_parse_enum_name(Some(&raw), &ff.enum_values).map(SomValue::Str));
        }
        Ok(parse_typed(&raw, scalar_base(&ff.type_)))
    }

    /// Sets form `field` at the `@Form` section `path` to the typed value `v`
    /// (`None` clears), converting through the shared boundary helpers.
    ///
    /// Errors for a wrong value type or an out-of-domain enum name.
    pub fn set_form_value(
        &mut self,
        path: &str,
        field: &str,
        v: Option<SomValue>,
    ) -> Result<(), String> {
        let ff = self.form_field(path, field)?;
        let stored = if !ff.enum_values.is_empty() {
            som_format_enum_name(string_or_none(v.as_ref(), path, field)?, &ff.enum_values)?
        } else {
            format_for_store(
                v.as_ref(),
                SPEC_NODE_KIND_SCALAR,
                None,
                path,
                Some(&ff.type_),
                Some(field),
            )?
        };
        self.document.set_form_field(path, field, &stored);
        Ok(())
    }

    /// The form-field specs of the `@Form` section at `path`, in declaration
    /// order — the meta a generic editor UI renders from.
    pub fn form_fields(&self, path: &str) -> Result<Vec<FormFieldSpec>, String> {
        let r = self.resolve(path)?;
        if r.kind != SPEC_NODE_KIND_FORM {
            return Err(format!(
                "path '{}' is a {} node, not a @Form section",
                path, r.kind
            ));
        }
        Ok(r.field.map(|f| f.form_fields).unwrap_or_default())
    }

    fn form_field(&self, path: &str, field: &str) -> Result<FormFieldSpec, String> {
        for ff in self.form_fields(path)? {
            if ff.name == field {
                return Ok(ff);
            }
        }
        Err(format!("'{}' is not a form field of {}", field, path))
    }

    // --- structural operations -----------------------------------------------

    /// Appends a new item to the list at `list_path`, dated today, and returns
    /// its stable item path.
    ///
    /// When the list field carries a `@SectionIdPattern`, a fresh id is generated
    /// from the pattern ([`generate_list_item_section_id`]). Errors when
    /// `list_path` is not a list.
    pub fn add_list_item(&mut self, list_path: &str) -> Result<String, String> {
        let (month, day) = today_month_day();
        self.add_list_item_on(list_path, month, day)
    }

    /// Like [`SpecEditor::add_list_item`] but the generated section id uses the
    /// given `(month, day)` for its two-letter-date component (AA1 criteria 3–4).
    ///
    /// The date travels as month/day integers rather than a date type because the
    /// shared [`generate_list_item_section_id`] helper is language-neutral and
    /// takes exactly those.
    pub fn add_list_item_on(
        &mut self,
        list_path: &str,
        month: i64,
        day: i64,
    ) -> Result<String, String> {
        let r = self.list_node(list_path)?;
        let pattern = r
            .field
            .as_ref()
            .map(|f| f.section_id_pattern.clone())
            .unwrap_or_default();
        if pattern.is_empty() {
            return Ok(self.document.add_list_item(list_path));
        }
        let existing = self.document.list_item_section_ids(list_path);
        let id = generate_list_item_section_id(&pattern, month, day, &existing);
        self.document
            .add_list_item_with_section_id(list_path, &id)
            .map_err(|e| e.to_string())
    }

    /// Like [`SpecEditor::add_list_item`] but with an explicit `section_id`
    /// override, uniqueness-checked against the list's other items (AA1 criterion
    /// 5).
    pub fn add_list_item_with_id(
        &mut self,
        list_path: &str,
        section_id: &str,
    ) -> Result<String, String> {
        self.list_node(list_path)?;
        self.document
            .add_list_item_with_section_id(list_path, section_id)
            .map_err(|e| e.to_string())
    }

    fn list_node(&self, list_path: &str) -> Result<SpecResolution, String> {
        let r = self.resolve(list_path)?;
        if r.kind != SPEC_NODE_KIND_LIST {
            return Err(format!(
                "path '{}' is a {} node, not a list",
                list_path, r.kind
            ));
        }
        Ok(r)
    }

    /// Removes the list item at `item_path` with every value beneath it. Returns
    /// `true` when an item was found and removed.
    pub fn remove_list_item(&mut self, item_path: &str) -> bool {
        self.document.remove_list_item(item_path)
    }

    /// Clears every value at `path` and beneath it — content, form entries,
    /// nested list items, stored headlines and ids — returning the subtree to the
    /// untouched "empty = no value" state (D4). The node itself remains
    /// addressable (structure lives in the model, not the document).
    pub fn clear_section(&mut self, path: &str) -> Result<(), String> {
        self.resolve(path)?;
        self.document.remove_values_under(path);
        Ok(())
    }
}

/// Parses stored text per the declared scalar base type; an untyped (or
/// unrecognised) base keeps the raw string.
fn parse_typed(raw: &str, base: Option<&str>) -> Option<SomValue> {
    match base {
        Some("int") => som_parse_int(Some(raw)).map(SomValue::Int),
        Some("double") => som_parse_double(Some(raw)).map(SomValue::Double),
        Some("num") => som_parse_num(Some(raw)).map(|n| match n {
            SomNum::Int(i) => SomValue::Int(i),
            SomNum::Double(d) => SomValue::Double(d),
        }),
        Some("bool") => som_parse_bool(Some(raw)).map(SomValue::Bool),
        _ => Some(SomValue::Str(raw.to_string())),
    }
}

/// Formats `v` for the store per the leaf's declared type; strings pass through
/// verbatim (the plain-text serialization is authoritative).
///
/// `type_name` overrides the field's declared type (the form-field path, whose
/// type lives on the [`FormFieldSpec`] rather than the [`SpecField`]) and
/// `where_` names the position in an error message.
fn format_for_store(
    v: Option<&SomValue>,
    kind: &str,
    field: Option<&SpecField>,
    path: &str,
    type_name: Option<&str>,
    where_: Option<&str>,
) -> Result<String, String> {
    let v = match v {
        None => return Ok(String::new()),
        Some(v) => v,
    };
    if kind == SPEC_NODE_KIND_ENUM_VALUE {
        let empty: Vec<String> = Vec::new();
        let values = field.map(|f| &f.enum_values).unwrap_or(&empty);
        return som_format_enum_name(string_or_none(Some(v), path, where_.unwrap_or(path))?, values);
    }
    let declared = type_name.unwrap_or_else(|| field.map(|f| f.type_.as_str()).unwrap_or(""));
    let base = scalar_base(declared);
    match (base, v) {
        (Some("int"), SomValue::Int(n)) => return Ok(som_format_int(Some(*n))),
        (Some("double"), SomValue::Double(d)) => return Ok(som_format_double(Some(*d))),
        (Some("double"), SomValue::Int(n)) => return Ok(som_format_double(Some(*n as f64))),
        (Some("num"), SomValue::Int(n)) => return Ok(som_format_num(Some(SomNum::Int(*n)))),
        (Some("num"), SomValue::Double(d)) => return Ok(som_format_num(Some(SomNum::Double(*d)))),
        (Some("bool"), SomValue::Bool(b)) => return Ok(som_format_bool(Some(*b))),
        _ => {}
    }
    if let SomValue::Str(s) = v {
        return Ok(s.clone());
    }
    Err(format!(
        "{:?} at {}: wrong value type for a {} field",
        v,
        where_.unwrap_or(path),
        base.unwrap_or("String")
    ))
}

/// Unwraps a [`SomValue::Str`] for a string-only position (an enum constant
/// name); `None` stays `None`, anything else is an error.
fn string_or_none<'v>(
    v: Option<&'v SomValue>,
    path: &str,
    field: &str,
) -> Result<Option<&'v str>, String> {
    match v {
        None => Ok(None),
        Some(SomValue::Str(s)) => Ok(Some(s.as_str())),
        Some(other) => Err(format!(
            "{}: expected a string for this field of {} (got {:?})",
            field, path, other
        )),
    }
}
