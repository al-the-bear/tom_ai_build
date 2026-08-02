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
    /// Enum constant names when the field's value type is an enum (FORMAT 6,
    /// YRD7), empty for non-enum fields.
    pub enum_values: Vec<String>,
    /// The registry key(s) this field's value is an id drawn from, each
    /// written `<SECTIONID>.<formFieldName>` (csrb3); empty for a field that
    /// is not a reference. A value is valid when it resolves in ANY listed
    /// registry; a reference naming several ids writes them comma-separated.
    pub refers_to: Vec<String>,
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

/// Seconds in a day — the unit ages and thresholds are reported in.
pub const SECONDS_PER_DAY: i64 = 86_400;

/// How old a snapshot may get before [`SpecModel::check_stamp`] calls it aged.
///
/// A fortnight: long enough that a healthy working copy is never nagged, short
/// enough that structural feedback keyed to a snapshot's paths is not recorded
/// against a model that has moved past them.
pub const DEFAULT_MAX_SNAPSHOT_AGE_SECONDS: i64 = 14 * SECONDS_PER_DAY;

/// The length of `month` in `year`, Gregorian. Used to reject a day that does
/// not exist rather than letting it roll into the next month: some SOM runtimes'
/// date types would turn 31 February into 3 March while others reject it
/// outright — so the grammar rejects it everywhere.
fn days_in_month(year: i64, month: i64) -> i64 {
    if month != 2 {
        return [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][(month - 1) as usize];
    }
    if year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) {
        29
    } else {
        28
    }
}

/// Days since 1970-01-01 for a proleptic-Gregorian civil date (Howard
/// Hinnant's `days_from_civil`). The Go, Java, C and C++ ports carry the same
/// arithmetic; Rust's std has no calendar type at all.
fn epoch_day(year: i64, month: i64, day: i64) -> i64 {
    let y = year - if month <= 2 { 1 } else { 0 };
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = y - era * 400;
    let doy = (153 * (month + if month > 2 { -3 } else { 9 }) + 2) / 5 + day - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + doe - 719_468
}

/// Reads `count` decimal digits at `at`, or `None` when any is not a digit.
fn digits_at(b: &[u8], at: usize, count: usize) -> Option<i64> {
    if at + count > b.len() {
        return None;
    }
    let mut value: i64 = 0;
    for &c in &b[at..at + count] {
        if !c.is_ascii_digit() {
            return None;
        }
        value = value * 10 + i64::from(c - b'0');
    }
    Some(value)
}

/// Parses a generation-stamp timestamp to epoch seconds (UTC), or `None`.
///
/// The grammar is `YYYY-MM-DDTHH:MM:SS`, an optional fractional part, and an
/// optional `Z` / `±HH:MM` / `±HHMM` offset — spelled out here rather than
/// delegated to a date library, which Rust's std does not provide and which
/// would in any case make the accepted set differ by language. A stamp that
/// reads on one platform and not another is exactly the divergence the shared
/// conformance corpus exists to catch.
///
/// A timestamp carrying **no** zone is read as UTC: a staleness verdict that
/// changed with the reader's timezone would be a defect in its own right.
///
/// The sub-second part is accepted and discarded — every consumer compares the
/// resulting instant in whole days.
///
/// Anything outside the grammar — or carrying an out-of-range field — degrades
/// to `None` rather than erroring: an unreadable stamp is not worth failing a
/// whole model over.
pub fn parse_stamp_timestamp(raw: &str) -> Option<i64> {
    let b = raw.trim().as_bytes();
    if b.len() < 19 || b[4] != b'-' || b[7] != b'-' || b[13] != b':' || b[16] != b':' {
        return None;
    }
    if b[10] != b'T' && b[10] != b't' && b[10] != b' ' {
        return None;
    }
    let year = digits_at(b, 0, 4)?;
    let month = digits_at(b, 5, 2)?;
    let day = digits_at(b, 8, 2)?;
    let hour = digits_at(b, 11, 2)?;
    let minute = digits_at(b, 14, 2)?;
    let second = digits_at(b, 17, 2)?;
    if month < 1 || month > 12 || day < 1 || day > days_in_month(year, month) {
        return None;
    }
    if hour > 23 || minute > 59 || second > 59 {
        return None;
    }

    let mut idx = 19;
    if idx < b.len() && b[idx] == b'.' {
        idx += 1;
        let start = idx;
        while idx < b.len() && b[idx].is_ascii_digit() {
            idx += 1;
        }
        if idx == start {
            return None; // a `.` with no digits is not the grammar
        }
    }

    let mut epoch = epoch_day(year, month, day) * SECONDS_PER_DAY
        + hour * 3600
        + minute * 60
        + second;
    if idx < b.len() {
        let sign = b[idx];
        if sign == b'Z' || sign == b'z' {
            if idx + 1 != b.len() {
                return None;
            }
        } else if sign == b'+' || sign == b'-' {
            let rest = &b[idx + 1..];
            let (oh, om) = match rest.len() {
                4 => (digits_at(rest, 0, 2)?, digits_at(rest, 2, 2)?),
                5 if rest[2] == b':' => (digits_at(rest, 0, 2)?, digits_at(rest, 3, 2)?),
                _ => return None,
            };
            let offset = (oh * 60 + om) * 60;
            epoch += if sign == b'-' { offset } else { -offset };
        } else {
            return None;
        }
    }
    Some(epoch)
}

/// The outcome of checking a loaded snapshot's generation stamp against its own
/// payload and against the clock — see [`SpecModel::check_stamp`].
///
/// The two findings are independent and can both hold at once: [`Self::is_aged`]
/// says the snapshot is probably behind the live model, while
/// [`Self::counts_disagree`] says the file no longer describes itself correctly.
/// Only the second is a defect in the file.
#[derive(Debug, Clone)]
pub struct SpecModelStampCheck {
    /// How long ago the snapshot was generated, in seconds, or `None` when it
    /// carries no `generatedAt` (an older export, or a hand-built model).
    pub age_seconds: Option<i64>,
    /// The threshold [`Self::age_seconds`] was judged against.
    pub max_age_seconds: i64,
    /// The class count the stamp declares, or `None` when it declares none.
    pub declared_class_count: Option<i64>,
    /// The number of classes the payload actually carries.
    pub actual_class_count: i64,
    /// The document-root count the stamp declares, or `None`.
    pub declared_root_count: Option<i64>,
    /// The number of document roots the payload actually carries.
    pub actual_root_count: i64,
}

impl SpecModelStampCheck {
    /// Whether the snapshot is older than [`Self::max_age_seconds`]. Always
    /// false when it carries no `generatedAt` — an unknown age is not evidence
    /// of a stale one.
    pub fn is_aged(&self) -> bool {
        matches!(self.age_seconds, Some(age) if age > self.max_age_seconds)
    }

    /// Whether the declared and actual class counts differ.
    ///
    /// An absent declaration is not a disagreement: older snapshots predate the
    /// stamp keys, and reading absent as `0` would make every one of them look
    /// corrupt.
    pub fn class_count_disagrees(&self) -> bool {
        matches!(self.declared_class_count, Some(n) if n != self.actual_class_count)
    }

    /// Whether the declared and actual root counts differ. Absent declarations
    /// are ignored, as for [`Self::class_count_disagrees`].
    pub fn root_count_disagrees(&self) -> bool {
        matches!(self.declared_root_count, Some(n) if n != self.actual_root_count)
    }

    /// Whether either declared size disagrees with the payload.
    ///
    /// The exporter derives both counts *from* the payload it writes, so a
    /// disagreement cannot arise from a normal export — it means the file was
    /// edited or truncated afterwards.
    pub fn counts_disagree(&self) -> bool {
        self.class_count_disagrees() || self.root_count_disagrees()
    }

    /// Whether anything at all was found.
    pub fn is_stale(&self) -> bool {
        self.is_aged() || self.counts_disagree()
    }

    /// The findings as ready-to-display sentences, empty when there are none.
    /// The wording is identical in all nine runtimes.
    pub fn warnings(&self) -> Vec<String> {
        let mut out = Vec::new();
        if self.is_aged() {
            let days = self.age_seconds.unwrap_or(0) / SECONDS_PER_DAY;
            let threshold = self.max_age_seconds / SECONDS_PER_DAY;
            out.push(format!(
                "Snapshot is {} days old (threshold {} days) — the model may \
                 have moved on since it was exported.",
                days, threshold
            ));
        }
        if self.class_count_disagrees() {
            out.push(format!(
                "Stamp declares {} classes but the snapshot carries {} — it \
                 was edited after export.",
                self.declared_class_count.unwrap_or(0),
                self.actual_class_count
            ));
        }
        if self.root_count_disagrees() {
            out.push(format!(
                "Stamp declares {} document roots but the snapshot carries {} \
                 — it was edited after export.",
                self.declared_root_count.unwrap_or(0),
                self.actual_root_count
            ));
        }
        out
    }
}

/// The complete exported model.
#[derive(Debug, Clone)]
pub struct SpecModel {
    pub roots: Vec<SpecRoot>,
    pub classes: HashMap<String, SpecClass>,
    pub model_version: i64,
    pub model_version_label: String,
    /// When the snapshot was exported, as epoch seconds (UTC), or `None` when
    /// it carries no `generatedAt` — an export predating the key, or a
    /// hand-built model. Epoch seconds rather than a date type because Rust's
    /// std has none.
    pub generated_at: Option<i64>,
    /// The *file format's* own version, distinct from
    /// [`Self::model_version`] (which model the snapshot describes). `None`
    /// when undeclared.
    pub meta_schema_version: Option<i64>,
    /// The class count the snapshot declares, or `None` when undeclared. Kept
    /// separate from `classes.len()`: the declared value is what the exporter
    /// recorded, the actual value is what survived to the reader, and comparing
    /// them is the point ([`Self::check_stamp`]).
    pub class_count: Option<i64>,
    /// The document-root count the snapshot declares, or `None`.
    pub root_count: Option<i64>,
    /// The canonical container class — the single true tree root, which is not
    /// itself a document and so does not appear in [`Self::roots`]. Empty when
    /// the model has no container (e.g. a synthetic export).
    pub container_root: String,
}

impl SpecModel {
    /// Returns the class with the given name, or `None`.
    pub fn class_named(&self, name: &str) -> Option<&SpecClass> {
        if name.is_empty() {
            return None;
        }
        self.classes.get(name)
    }

    /// Returns the document root whose [`SpecRoot::type_`] equals `ty` (SOM
    /// §21).
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

    /// Checks the generation stamp against the payload and the clock.
    ///
    /// `now_epoch_seconds` is injectable so callers (and tests) can evaluate age
    /// against a fixed instant instead of the wall clock.
    pub fn check_stamp(
        &self,
        max_age_seconds: i64,
        now_epoch_seconds: i64,
    ) -> SpecModelStampCheck {
        SpecModelStampCheck {
            age_seconds: self.generated_at.map(|at| now_epoch_seconds - at),
            max_age_seconds,
            declared_class_count: self.class_count,
            actual_class_count: self.classes.len() as i64,
            declared_root_count: self.root_count,
            actual_root_count: self.roots.len() as i64,
        }
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

        // The counts stay `None` when the key is absent rather than becoming
        // `0`: a snapshot predating the stamp keys would otherwise declare zero
        // classes and read as corrupt.
        SpecModel {
            roots,
            classes,
            model_version,
            model_version_label,
            generated_at: parse_stamp_timestamp(&root.str_or("generatedAt")),
            meta_schema_version: root.get("metaSchemaVersion").and_then(|v| v.as_i64()),
            class_count: root.get("classCount").and_then(|v| v.as_i64()),
            root_count: root.get("rootCount").and_then(|v| v.as_i64()),
            container_root: root.str_or("containerRoot"),
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
            let mut ff_enum_values = Vec::new();
            if let Some(arr) = ff.get("enumValues").and_then(|v| v.as_array()) {
                for v in arr {
                    if let Some(s) = v.as_str() {
                        ff_enum_values.push(s.to_string());
                    }
                }
            }
            let mut ff_refers_to = Vec::new();
            if let Some(arr) = ff.get("refersTo").and_then(|v| v.as_array()) {
                for v in arr {
                    if let Some(s) = v.as_str() {
                        ff_refers_to.push(s.to_string());
                    }
                }
            }
            form_fields.push(FormFieldSpec {
                name: fname,
                label,
                type_,
                hint: ff.str_or("hint"),
                required: ff.bool_or("required"),
                enum_values: ff_enum_values,
                refers_to: ff_refers_to,
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
