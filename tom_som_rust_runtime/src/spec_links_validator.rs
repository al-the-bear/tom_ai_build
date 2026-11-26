//! `spec_links_validator` — the link checks of one document
//! (`tom_specs_model_rules.md` §9.7): [`validate_links`] holds a document's
//! values to the link annotations of the model — derived values to their
//! sources, summaries to their detail lists, each end of a link to the other,
//! the ids named in a text to the link rows, and a `@SameAs` copy to its
//! holder. A port of `tom_som_dart_runtime/lib/src/spec_links_validator.dart`
//! (and the TypeScript, JavaScript, Python, Go and Java
//! `spec_links_validator` modules).
//!
//! Values are read in their reviewed state: a value holding pending change
//! marks is read with every mark rejected, and listed as `linkValuePending`.
//! A `@SummaryOf` naming another document is skipped here; the document set
//! checks it.

use std::collections::{BTreeMap, BTreeSet, HashMap, HashSet};

use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_model::{
    FormFieldSpec, SpecClass, SpecField, SpecModel, SPEC_FIELD_KIND_COMPLEX,
    SPEC_FIELD_KIND_CONTENT, SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SECTION,
};
use crate::spec_model_links::{SpecDerivation, SpecInverseOf, SpecStringPair, SpecSummaryOf};
use crate::spec_place::{
    place_class_of, spec_same_as_bindings, SpecPlace, SpecPlaceFilter, SpecPlaceResolution,
    SPEC_PLACE_KIND_CONTENT, SPEC_PLACE_KIND_FORM_FIELD, SPEC_PLACE_KIND_HEADLINE,
    SPEC_PLACE_KIND_LIST, SPEC_PLACE_KIND_SECTION_ID,
};
use crate::spec_reflection::{SpecReflection, SPEC_NODE_KIND_LIST_ITEM_COMPLEX};
use crate::spec_review_annotations::{apply_inline_marks_text, K_SPEC_HEADLINE_FIELD};
use crate::spec_section_id::{effective_list_item_section_id, K_SECTION_ID_SLOT};
use crate::spec_typed_values::{is_float_text, is_int_text};
use crate::spec_validator::{
    spec_validation_code_index, SpecValidationError, SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS,
    SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH, SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY,
    SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW, SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING,
    SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE, SPEC_VALIDATION_CODE_INVERSE_MISSING,
    SPEC_VALIDATION_CODE_LINK_VALUE_PENDING, SPEC_VALIDATION_CODE_SAME_AS_MISMATCH,
    SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE, SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL,
};

/// Runs the link checks of `doc` against `model`; the findings sorted by path,
/// then by code (declaration order), then by message.
pub fn validate_links(model: &SpecModel, doc: &SpecDocument) -> Vec<SpecValidationError> {
    let mut v = SpecLinkValidator::new(model, doc, false);
    v.run();
    let mut errors = v.errors;
    errors.sort_by(|a, b| {
        a.path
            .cmp(&b.path)
            .then_with(|| {
                spec_validation_code_index(&a.code).cmp(&spec_validation_code_index(&b.code))
            })
            .then_with(|| a.message.cmp(&b.message))
    });
    errors
}

/// Every concrete path of `pattern` in `doc`: each `<list>-*` segment expanded
/// over the document's items.
pub fn spec_expand_pattern(doc: &SpecDocument, pattern: &str) -> Vec<String> {
    let mut paths = vec![String::new()];
    for seg in pattern.split('/') {
        let mut next = Vec::new();
        for p in &paths {
            let base = if p.is_empty() {
                seg.to_string()
            } else {
                format!("{}/{}", p, seg)
            };
            if seg.ends_with("-*") {
                next.extend(doc.list_items(&base[..base.len() - 2]));
            } else {
                next.push(base);
            }
        }
        paths = next;
    }
    paths
}

/// `place` resolved under `anchor`, or `None` when it does not resolve.
pub fn spec_resolve_place_at(
    refl: &SpecReflection<'_>,
    place: &str,
    anchor: &str,
) -> Option<SpecPlaceResolution> {
    SpecPlace::parse(place).ok()?.resolve(refl, anchor).ok()
}

/// `place` resolved for a link annotated at `anchor`, as the link checks and
/// the rendition's `linked` marker (SOM §11.11) read it: a `./` place beneath
/// the nearest list element of `anchor`; any other place inside `anchor`'s
/// subtree when it is there, else anywhere beneath the document root `root` —
/// a bare id wherever it is reached once, a `/` path from the section its
/// first segment names, through the first item `doc` holds of a list there
/// (`doc` `None`: such a path does not resolve). `None` when it does not
/// resolve.
pub fn spec_resolve_link_place(
    refl: &SpecReflection<'_>,
    doc: Option<&SpecDocument>,
    place: &str,
    root: &str,
    anchor: &str,
) -> Option<SpecPlaceResolution> {
    if place.starts_with("./") {
        return spec_resolve_place_at(refl, place, anchor);
    }
    // The grammar's own scope first: the subtree of the annotated section.
    if anchor != root {
        if let Some(local) = spec_resolve_place_at(refl, place, anchor) {
            return Some(local);
        }
    }
    let slash = match place.find('/') {
        Some(s) => s,
        None => return spec_resolve_place_at(refl, place, root),
    };
    let head = spec_resolve_place_at(refl, &place[..slash], root)?;
    let scope = if head.kind == SPEC_PLACE_KIND_LIST {
        format!("{}-*", head.path)
    } else {
        head.path.clone()
    };
    // A pattern anchor resolves through its first concrete instance; the rest
    // of the place is relative, so the pattern is rebuilt below.
    let concrete: Vec<String> = match doc {
        Some(doc) => spec_expand_pattern(doc, &scope),
        None if !scope.contains("-*") => vec![scope.clone()],
        None => Vec::new(),
    };
    let first = concrete.first()?;
    let rest = spec_resolve_place_at(refl, &place[slash + 1..], first)?;
    Some(SpecPlaceResolution {
        path: format!("{}{}", scope, tail_from(&rest.path, first.len())),
        ..rest
    })
}

/// A fix kind: set the value at `path` / `field`.
pub const SPEC_LINK_FIX_SET: &str = "set";
/// A fix kind: add `value` to the ids of the reference field.
pub const SPEC_LINK_FIX_APPEND: &str = "append";
/// A fix kind: add a row to the list at `path`.
pub const SPEC_LINK_FIX_ADD_ROW: &str = "addRow";
/// A fix kind: remove the row at `path`.
pub const SPEC_LINK_FIX_REMOVE_ROW: &str = "removeRow";
/// A fix kind: make the list at `path` hold one element per tuple.
pub const SPEC_LINK_FIX_LIST: &str = "list";
/// A fix kind: write the copy at `path` from `holder`.
pub const SPEC_LINK_FIX_COPY: &str = "copy";

/// What `deriveFields` would write for one link finding (collected by
/// [`SpecLinkValidator`] beside the finding).
///
/// Kinds: `set` (the value at `path` / `field`, `field` `""`: content),
/// `append` (add `value` to the ids of the reference field), `addRow` (add a
/// row to the list at `path`: `<member>#<field>` → value in `values`),
/// `removeRow` (the row at `path`; `empty`: it holds no value already), `list`
/// (make the list at `path` hold one element per tuple of `tuples`), `copy`
/// (write the copy at `path` from `holder`).
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecLinkFix {
    pub step: i64,
    pub kind: String,
    pub path: String,
    pub field: String,
    pub value: String,
    pub values: BTreeMap<String, String>,
    pub tuples: Vec<BTreeMap<String, String>>,
    pub holder: String,
    pub empty: bool,
    /// The keys of `values` in the order they were written (an `addRow`
    /// writes its values in this order); empty: sorted.
    pub value_keys: Vec<String>,
    /// The target places of each tuple of `tuples`, in the derivation's order;
    /// empty: sorted.
    pub tuple_keys: Vec<String>,
}

impl SpecLinkFix {
    /// Sets the value at `path` / `field` (`""` content) to `value`.
    pub fn set(step: i64, path: &str, field: &str, value: &str) -> SpecLinkFix {
        SpecLinkFix {
            step,
            kind: SPEC_LINK_FIX_SET.to_string(),
            path: path.to_string(),
            field: field.to_string(),
            value: value.to_string(),
            ..Default::default()
        }
    }

    /// Adds `value` to the ids of the reference field at `path` / `field`.
    pub fn append(path: &str, field: &str, value: &str) -> SpecLinkFix {
        SpecLinkFix {
            step: 1,
            kind: SPEC_LINK_FIX_APPEND.to_string(),
            path: path.to_string(),
            field: field.to_string(),
            value: value.to_string(),
            ..Default::default()
        }
    }

    /// Adds a row to the list at `path`: `<member>#<field>` (or `<member>`, a
    /// content value) → value.
    pub fn add_row(step: i64, path: &str, values: BTreeMap<String, String>) -> SpecLinkFix {
        SpecLinkFix {
            step,
            kind: SPEC_LINK_FIX_ADD_ROW.to_string(),
            path: path.to_string(),
            values,
            ..Default::default()
        }
    }

    /// Removes the row at `path`; `empty`: it holds no value already.
    pub fn remove_row(path: &str, empty: bool) -> SpecLinkFix {
        SpecLinkFix {
            step: 1,
            kind: SPEC_LINK_FIX_REMOVE_ROW.to_string(),
            path: path.to_string(),
            empty,
            ..Default::default()
        }
    }

    /// Makes the list at `path` hold one element per tuple (target place →
    /// value).
    pub fn list(path: &str, tuples: Vec<BTreeMap<String, String>>) -> SpecLinkFix {
        SpecLinkFix {
            step: 2,
            kind: SPEC_LINK_FIX_LIST.to_string(),
            path: path.to_string(),
            tuples,
            ..Default::default()
        }
    }

    /// Writes the copy at `path` from the holder.
    pub fn copy(path: &str, holder: &str) -> SpecLinkFix {
        SpecLinkFix {
            step: 2,
            kind: SPEC_LINK_FIX_COPY.to_string(),
            path: path.to_string(),
            holder: holder.to_string(),
            ..Default::default()
        }
    }

    /// The keys of `values` in their written order (sorted when the order was
    /// not recorded).
    pub fn ordered_value_keys(&self) -> Vec<String> {
        if !self.value_keys.is_empty() {
            return self.value_keys.clone();
        }
        self.values.keys().cloned().collect()
    }

    /// The target places of the tuples in the derivation's order (sorted when
    /// the order was not recorded).
    pub fn ordered_tuple_keys(&self) -> Vec<String> {
        if !self.tuple_keys.is_empty() || self.tuples.is_empty() {
            return self.tuple_keys.clone();
        }
        self.tuples[0].keys().cloned().collect()
    }

    /// The fix as JSON, unset parts left out (for comparing runtimes).
    pub fn to_json(&self) -> Json {
        let s = |v: &str| Json::Str(v.to_string());
        let map = |m: &BTreeMap<String, String>| {
            Json::Object(m.iter().map(|(k, v)| (k.clone(), s(v))).collect())
        };
        let mut out = vec![
            ("step".to_string(), Json::Int(self.step)),
            ("kind".to_string(), s(&self.kind)),
            ("path".to_string(), s(&self.path)),
        ];
        match self.kind.as_str() {
            SPEC_LINK_FIX_SET | SPEC_LINK_FIX_APPEND => {
                let field = if self.field.is_empty() {
                    Json::Null
                } else {
                    s(&self.field)
                };
                out.push(("field".to_string(), field));
                out.push(("value".to_string(), s(&self.value)));
            }
            SPEC_LINK_FIX_ADD_ROW => out.push(("values".to_string(), map(&self.values))),
            SPEC_LINK_FIX_REMOVE_ROW => out.push(("empty".to_string(), Json::Bool(self.empty))),
            SPEC_LINK_FIX_LIST => out.push((
                "tuples".to_string(),
                Json::Array(self.tuples.iter().map(map).collect()),
            )),
            SPEC_LINK_FIX_COPY => out.push(("holder".to_string(), s(&self.holder))),
            _ => {}
        }
        Json::Object(out)
    }
}

/// `values[key] = value`, recording a new key in `keys`.
pub(crate) fn put_ordered(
    values: &mut BTreeMap<String, String>,
    keys: &mut Vec<String>,
    key: String,
    value: String,
) {
    if !values.contains_key(&key) {
        keys.push(key.clone());
    }
    values.insert(key, value);
}

/// `^0[xX][0-9a-fA-F]+$`.
fn is_hex_text(t: &str) -> bool {
    let b = t.as_bytes();
    b.len() > 2
        && b[0] == b'0'
        && (b[1] == b'x' || b[1] == b'X')
        && b[2..].iter().all(u8::is_ascii_hexdigit)
}

/// Dart's `num.tryParse` (decimal forms; surrounding whitespace allowed).
fn link_num_try_parse(text: &str) -> Option<f64> {
    let t = text.trim();
    if is_int_text(t) || is_float_text(t) {
        return t.parse::<f64>().ok();
    }
    if is_hex_text(t) {
        return i64::from_str_radix(&t[2..], 16).ok().map(|n| n as f64);
    }
    match t {
        "NaN" => Some(f64::NAN),
        "Infinity" => Some(f64::INFINITY),
        "-Infinity" => Some(f64::NEG_INFINITY),
        _ => None,
    }
}

/// The ids as text names them (`[A-Za-z0-9][A-Za-z0-9-]*[A-Za-z0-9]|[A-Za-z0-9]`,
/// leftmost first): letters, digits and inner hyphens.
fn link_id_tokens(text: &str) -> Vec<&str> {
    let b = text.as_bytes();
    let mut out = Vec::new();
    let mut i = 0;
    while i < b.len() {
        if !b[i].is_ascii_alphanumeric() {
            i += 1;
            continue;
        }
        let mut j = i;
        let mut last = i;
        while j < b.len() && (b[j].is_ascii_alphanumeric() || b[j] == b'-') {
            if b[j].is_ascii_alphanumeric() {
                last = j;
            }
            j += 1;
        }
        out.push(&text[i..=last]);
        i = last + 1;
    }
    out
}

/// One section instance of the document.
struct LinkInstance<'a> {
    path: String,
    cls: &'a SpecClass,
    root: String,
}

/// One scalar derivation: a content member or a form field.
struct LinkScalar<'a> {
    path: String,
    field: String, // "" for content
    d: SpecDerivation,
    anchor: String,
    root: String,
    spec: Option<&'a FormFieldSpec>,
}

/// One value of a subtree: its path and its value.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecSubtreeValue {
    pub path: String,
    pub value: String,
}

/// The link checker of one document: [`validate_links`] runs it,
/// `deriveFields` reads its `fixes` and value readers.
pub struct SpecLinkValidator<'a> {
    /// What `deriveFields` would write for each finding, collected beside it.
    pub fixes: Vec<SpecLinkFix>,
    /// The findings, in the order they were found.
    pub errors: Vec<SpecValidationError>,
    /// The effective section id per list item path (writable by
    /// `deriveFields`).
    pub item_ids: HashMap<String, String>,
    /// Reads values with their pending marks accepted (the proposal), as
    /// `deriveFields` does in a document under review, instead of the
    /// reviewed state; no value is then listed as pending.
    pub read_proposed: bool,
    pub model: &'a SpecModel,
    pub doc: &'a SpecDocument,

    reported: HashSet<String>,
    pending: HashSet<String>,
    /// The derived values computed so far (`path#field` → value), read before
    /// the stored value so a derivation from a derived place sees its derived
    /// value.
    derived: HashMap<String, String>,
    items: HashMap<String, bool>,
    forms_by_owner: Option<HashMap<String, Vec<String>>>,
    entries_cache: HashMap<String, BTreeMap<String, String>>,
    valued: Option<HashSet<String>>,
}

impl<'a> SpecLinkValidator<'a> {
    /// The link checker of `doc` against `model`.
    pub fn new(
        model: &'a SpecModel,
        doc: &'a SpecDocument,
        read_proposed: bool,
    ) -> SpecLinkValidator<'a> {
        SpecLinkValidator {
            fixes: Vec::new(),
            errors: Vec::new(),
            item_ids: HashMap::new(),
            read_proposed,
            model,
            doc,
            reported: HashSet::new(),
            pending: HashSet::new(),
            derived: HashMap::new(),
            items: HashMap::new(),
            forms_by_owner: None,
            entries_cache: HashMap::new(),
            valued: None,
        }
    }

    /// This checker with every finding, fix and cache it collected, reading
    /// `doc` instead: `deriveFields` reads the document as it writes it, with
    /// the caches the run left (the reference runtimes share one document).
    pub fn rebind<'b>(&self, doc: &'b SpecDocument) -> SpecLinkValidator<'b>
    where
        'a: 'b,
    {
        SpecLinkValidator {
            fixes: self.fixes.clone(),
            errors: self.errors.clone(),
            item_ids: self.item_ids.clone(),
            read_proposed: self.read_proposed,
            model: self.model,
            doc,
            reported: self.reported.clone(),
            pending: self.pending.clone(),
            derived: self.derived.clone(),
            items: self.items.clone(),
            forms_by_owner: self.forms_by_owner.clone(),
            entries_cache: self.entries_cache.clone(),
            valued: self.valued.clone(),
        }
    }

    /// Takes over the findings and caches `other` (a
    /// [`rebind`](Self::rebind) of this checker) collected since.
    pub fn adopt(&mut self, other: &SpecLinkValidator<'_>) {
        self.item_ids = other.item_ids.clone();
        self.reported = other.reported.clone();
        self.pending = other.pending.clone();
        self.errors = other.errors.clone();
        self.derived = other.derived.clone();
        self.items = other.items.clone();
        self.forms_by_owner = other.forms_by_owner.clone();
        self.entries_cache = other.entries_cache.clone();
        self.valued = other.valued.clone();
    }

    /// The reflection over the model.
    pub fn refl(&self) -> SpecReflection<'a> {
        SpecReflection::new(self.model)
    }

    /// Records one finding, once.
    pub fn report(&mut self, code: &str, path: &str, message: String) {
        let key = format!("{} {} {}", code, path, message);
        if !self.reported.insert(key) {
            return;
        }
        self.errors.push(SpecValidationError {
            path: path.to_string(),
            code: code.to_string(),
            message,
        });
    }

    // --- the document's instances ---------------------------------------------

    /// Runs every link check.
    pub fn run(&mut self) -> &mut Self {
        let model = self.model;
        let refl = self.refl();
        let mut instances = Vec::new();
        for root in &model.roots {
            let seg = refl.root_segment(root);
            if !self.populated(&seg) {
                continue;
            }
            if let Some(cls) = model.class_named(&root.type_) {
                self.walk(cls, &seg, &seg, &mut instances, &HashSet::new());
            }
        }
        self.check_derivations(&instances);
        for i in &instances {
            for f in &i.cls.fields {
                self.check_summary(i, f);
                self.check_extracts(i, f);
                for ff in &f.form_fields {
                    let form = self.form_path(i, f);
                    if let Some(inv) = &ff.inverse_of {
                        self.check_inverse(&form, ff, inv);
                    }
                    if let Some(s) = &ff.summary_of {
                        self.check_field_summary(i, &form, ff, s);
                    }
                }
            }
        }
        for root in &model.roots {
            if self.populated(&refl.root_segment(root)) {
                self.check_same_as(&root.type_);
            }
        }
        self
    }

    fn populated(&self, seg: &str) -> bool {
        let prefix = format!("{}/", seg);
        let under = |paths: Vec<String>| paths.iter().any(|p| p == seg || p.starts_with(&prefix));
        let doc = self.doc;
        under(doc.content_paths())
            || under(doc.form_paths())
            || under(doc.list_paths())
            || under(doc.headline_paths())
    }

    fn walk(
        &self,
        cls: &'a SpecClass,
        path: &str,
        root: &str,
        out: &mut Vec<LinkInstance<'a>>,
        on_path: &HashSet<String>,
    ) {
        let refl = self.refl();
        out.push(LinkInstance {
            path: path.to_string(),
            cls,
            root: root.to_string(),
        });
        for f in &cls.fields {
            let member_path = format!("{}/{}", path, refl.field_segment(f));
            if f.has_annotation("Reference") {
                continue;
            }
            if f.kind == SPEC_FIELD_KIND_LIST && f.element_is_complex {
                let el = match self.model.class_named(&f.element_type) {
                    Some(el) => el,
                    None => continue,
                };
                for item in self.doc.list_items(&member_path) {
                    self.walk(el, &item, root, out, &HashSet::new());
                }
            } else if f.kind == SPEC_FIELD_KIND_COMPLEX || f.kind == SPEC_FIELD_KIND_SECTION {
                let child = match place_class_of(&refl, f) {
                    Some(c) if !on_path.contains(&c.name) => c,
                    _ => continue,
                };
                let mut next = on_path.clone();
                next.insert(cls.name.clone());
                self.walk(child, &member_path, root, out, &next);
            }
        }
    }

    fn form_path(&self, i: &LinkInstance<'_>, f: &SpecField) -> String {
        format!("{}/{}", i.path, self.refl().field_segment(f))
    }

    // --- reading values ---------------------------------------------------------

    /// The reviewed reading of a raw value; a value with pending marks is
    /// listed once.
    fn reviewed(&mut self, raw: Option<&str>, path: &str, what: &str) -> String {
        let raw = match raw {
            Some(r) => r,
            None => return String::new(),
        };
        if self.read_proposed {
            return apply_inline_marks_text(raw, true).trim().to_string();
        }
        let rejected = apply_inline_marks_text(raw, false);
        let key = format!("{} {}", path, what);
        if apply_inline_marks_text(raw, true) != rejected && !self.pending.contains(&key) {
            self.pending.insert(key);
            self.report(
                SPEC_VALIDATION_CODE_LINK_VALUE_PENDING,
                path,
                format!(
                    "{} holds pending change marks; it is read with every mark rejected",
                    what
                ),
            );
        }
        rejected.trim().to_string()
    }

    /// The value of form field `field` at `path` (derived first, then
    /// reviewed).
    pub fn form_value(&mut self, path: &str, field: &str) -> String {
        if let Some(d) = self.derived.get(&format!("{}#{}", path, field)) {
            return d.clone();
        }
        let doc = self.doc;
        self.reviewed(
            doc.form_field(path, field).map(String::as_str),
            path,
            &format!("form field \"{}\"", field),
        )
    }

    /// The content value at `path` (derived first, then reviewed).
    pub fn content_value(&mut self, path: &str) -> String {
        if let Some(d) = self.derived.get(&format!("{}#", path)) {
            return d.clone();
        }
        let doc = self.doc;
        self.reviewed(doc.content(path).map(String::as_str), path, "the content")
    }

    /// The headline at `path`, reviewed.
    pub fn headline_value(&mut self, path: &str) -> String {
        let doc = self.doc;
        self.reviewed(doc.headline(path).map(String::as_str), path, "the headline")
    }

    /// The effective section id of the list item at `item_path`.
    pub fn item_id(&mut self, item_path: &str) -> String {
        if let Some(id) = self.item_ids.get(item_path) {
            return id.clone();
        }
        let id = self.compute_item_id(item_path);
        self.item_ids.insert(item_path.to_string(), id.clone());
        id
    }

    fn compute_item_id(&self, item_path: &str) -> String {
        if let Some(stored) = self.doc.item_section_id(item_path) {
            return stored.clone();
        }
        let lst = &item_path[..item_path.rfind('-').unwrap_or(item_path.len())];
        let items = self.doc.list_items(lst);
        let position = items
            .iter()
            .position(|it| it == item_path)
            .map_or(0, |k| k + 1);
        let mut pattern = String::new();
        let mut stem = lst[lst.rfind('/').map_or(0, |s| s + 1)..].to_string();
        if let Some(field) = self.refl().resolve(lst).and_then(|r| r.field) {
            pattern = field.section_id_pattern;
            stem = field.name;
        }
        effective_list_item_section_id(None, &pattern, position, &stem)
    }

    /// Whether `path` is a complex list item.
    pub fn is_item(&mut self, path: &str) -> bool {
        if let Some(hit) = self.items.get(path) {
            return *hit;
        }
        let hit = self
            .refl()
            .resolve(path)
            .is_some_and(|r| r.kind == SPEC_NODE_KIND_LIST_ITEM_COMPLEX);
        self.items.insert(path.to_string(), hit);
        hit
    }

    /// The value a resolved place holds at its concrete path.
    pub fn value(&mut self, r: &SpecPlaceResolution, path: &str) -> String {
        match r.kind.as_str() {
            SPEC_PLACE_KIND_FORM_FIELD => self.form_value(path, r.field()),
            SPEC_PLACE_KIND_CONTENT => self.content_value(path),
            SPEC_PLACE_KIND_HEADLINE => self.headline_value(path),
            SPEC_PLACE_KIND_SECTION_ID if self.is_item(path) => self.item_id(path),
            _ => String::new(),
        }
    }

    /// Every concrete path of a resolved pattern.
    pub fn expand(&self, pattern: &str) -> Vec<String> {
        spec_expand_pattern(self.doc, pattern)
    }

    /// `place` resolved under `anchor`, or `None` when it does not resolve.
    pub fn at(&self, place: &str, anchor: &str) -> Option<SpecPlaceResolution> {
        spec_resolve_place_at(&self.refl(), place, anchor)
    }

    /// `place` resolved for a link annotated at `anchor`
    /// ([`spec_resolve_link_place`]).
    fn global(&self, place: &str, root: &str, anchor: &str) -> Option<SpecPlaceResolution> {
        spec_resolve_link_place(&self.refl(), Some(self.doc), place, root, anchor)
    }

    /// The values a row's own forms (`<row>/<member>`) hold in `field`.
    pub fn own_values(&mut self, row: &str, field: &str) -> Vec<String> {
        if self.forms_by_owner.is_none() {
            let mut by_owner: HashMap<String, Vec<String>> = HashMap::new();
            for p in self.doc.form_paths() {
                if let Some(slash) = p.rfind('/').filter(|s| *s > 0) {
                    by_owner
                        .entry(p[..slash].to_string())
                        .or_default()
                        .push(p.clone());
                }
            }
            self.forms_by_owner = Some(by_owner);
        }
        let forms = self
            .forms_by_owner
            .as_ref()
            .and_then(|m| m.get(row))
            .cloned()
            .unwrap_or_default();
        let doc = self.doc;
        let mut out = Vec::new();
        for p in forms {
            if doc.form_field(&p, field).is_some() {
                out.push(self.form_value(&p, field));
            }
        }
        out
    }

    fn passes(&mut self, r#where: &str, row: &str) -> bool {
        if r#where.is_empty() {
            return true;
        }
        match SpecPlaceFilter::try_parse(r#where) {
            Some(f) if !f.field.is_empty() => {
                let values = self.own_values(row, &f.field);
                f.matches(&values)
            }
            _ => true,
        }
    }

    /// The nearest list item at or above `path` (itself included), `None` when
    /// there is none.
    pub fn nearest_item(&mut self, path: &str) -> Option<String> {
        let mut p = path.to_string();
        loop {
            if self.is_item(&p) {
                return Some(p);
            }
            let slash = p.rfind('/')?;
            p.truncate(slash);
        }
    }

    // --- @DerivedFrom and derivedFrom: -------------------------------------------

    fn check_derivations(&mut self, instances: &[LinkInstance<'a>]) {
        let mut scalar: Vec<LinkScalar<'a>> = Vec::new();
        for i in instances {
            for f in &i.cls.fields {
                let member_path = self.form_path(i, f);
                if let Some(d) = f.derived_from() {
                    if f.kind == SPEC_FIELD_KIND_LIST {
                        self.check_derived_list(i, &member_path, &d);
                    } else if f.kind == SPEC_FIELD_KIND_CONTENT {
                        scalar.push(LinkScalar {
                            path: member_path.clone(),
                            field: String::new(),
                            d,
                            anchor: i.path.clone(),
                            root: i.root.clone(),
                            spec: None,
                        });
                    }
                }
                for ff in &f.form_fields {
                    if let Some(d) = &ff.derived_from {
                        scalar.push(LinkScalar {
                            path: member_path.clone(),
                            field: ff.name.clone(),
                            d: d.clone(),
                            anchor: i.path.clone(),
                            root: i.root.clone(),
                            spec: Some(ff),
                        });
                    }
                }
            }
        }
        // Dependency order: every derivation is recomputed from the values the
        // ones before it gave, until nothing moves. DERIVE-ACYCLIC bounds the
        // rounds by the number of derivations.
        let mut expected: Vec<Option<String>> = vec![None; scalar.len()];
        for _ in 0..=scalar.len() {
            let mut moved = false;
            for (k, t) in scalar.iter().enumerate() {
                let value = self.derive(&t.d, &t.anchor, &t.root, t.spec, &t.path);
                // Dart's `expected[k] != value`: an absent key reads as null.
                if expected[k] != value {
                    if let Some(v) = &value {
                        self.derived
                            .insert(format!("{}#{}", t.path, t.field), v.clone());
                    }
                    expected[k] = value;
                    moved = true;
                }
            }
            if !moved {
                break;
            }
        }
        self.derived.clear();
        for (k, t) in scalar.iter().enumerate() {
            let want = match &expected[k] {
                Some(w) => w.clone(),
                None => continue,
            };
            let have = if t.field.is_empty() {
                self.content_value(&t.path)
            } else {
                self.form_value(&t.path, &t.field)
            };
            let same = link_same_value(&have, &want, t.spec);
            if !same {
                self.fixes
                    .push(SpecLinkFix::set(2, &t.path, &t.field, &want));
            }
            if have.is_empty() {
                continue; // not derived yet: deriveFields writes it
            }
            if !same {
                let what = if t.field.is_empty() {
                    "the content".to_string()
                } else {
                    format!("form field \"{}\"", t.field)
                };
                self.report(
                    SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
                    &t.path,
                    format!(
                        "{} is derived ({} of {}) as \"{}\", but holds \"{}\"",
                        what, t.d.kind, t.d.source, want, have
                    ),
                );
            }
        }
    }

    /// The rows a `rows` / `lookup` derivation reads, in document order;
    /// `None` when the document's root does not reach the source (undecidable
    /// here).
    fn rows(&mut self, d: &SpecDerivation, anchor: &str, root: &str) -> Option<Vec<String>> {
        let src = self.global(&d.source, root, anchor)?;
        let key_by = !d.key.is_empty() && !d.by.is_empty();
        let by_value = if key_by {
            self.place_value(&d.by, anchor)
        } else {
            String::new()
        };
        let mut out = Vec::new();
        for row in self.expand(&src.path) {
            if !self.passes(&d.r#where, &row) {
                continue;
            }
            if key_by && self.place_value(&d.key, &row) != by_value {
                continue;
            }
            out.push(row);
        }
        Some(out)
    }

    /// The value of `place` resolved under the concrete `anchor`.
    pub fn place_value(&mut self, place: &str, anchor: &str) -> String {
        let r = match self.at(place, anchor) {
            Some(r) => r,
            None => return String::new(),
        };
        let paths = self.expand(&r.path);
        if paths.len() != 1 {
            return String::new();
        }
        self.value(&r, &paths[0])
    }

    /// The value a scalar derivation gives, `None` when undecidable.
    fn derive(
        &mut self,
        d: &SpecDerivation,
        anchor: &str,
        root: &str,
        spec: Option<&FormFieldSpec>,
        target_path: &str,
    ) -> Option<String> {
        match d.kind.as_str() {
            "copy" => {
                let src = self.global(&d.source, root, anchor)?;
                let paths = self.expand(&src.path);
                if paths.len() != 1 {
                    return None;
                }
                Some(self.value(&src, &paths[0]))
            }
            "rows" => {
                let rows = self.rows(d, anchor, root)?;
                if spec.is_some_and(|s| s.multiple) {
                    let mut out = Vec::new();
                    for row in &rows {
                        for t in &d.take {
                            out.extend(spec_link_ids(&self.place_value(t, row)));
                        }
                    }
                    return Some(out.join(", "));
                }
                let mut lines = Vec::new();
                for row in &rows {
                    let vals: Vec<String> =
                        d.take.iter().map(|t| self.place_value(t, row)).collect();
                    let line = join_non_empty(&vals, " — ");
                    if !line.is_empty() {
                        lines.push(line);
                    }
                }
                Some(lines.join("\n"))
            }
            "lookup" => {
                let rows = self.rows(d, anchor, root)?;
                let key_by = !d.key.is_empty() && !d.by.is_empty();
                if key_by && rows.len() != 1 {
                    let by = self.place_value(&d.by, anchor);
                    self.report(
                        SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS,
                        target_path,
                        format!(
                            "the lookup in {} by {} = \"{}\" finds {} rows, not one",
                            d.source,
                            d.key,
                            by,
                            rows.len()
                        ),
                    );
                    return None;
                }
                let row = match rows.last() {
                    Some(r) => r.clone(),
                    None => return Some(String::new()),
                };
                let vals: Vec<String> = d.take.iter().map(|t| self.place_value(t, &row)).collect();
                Some(join_non_empty(&vals, " — "))
            }
            _ => None,
        }
    }

    /// Checks a `@DerivedFrom.rows` with `map` on a list: one element per row.
    fn check_derived_list(&mut self, i: &LinkInstance<'_>, list_path: &str, d: &SpecDerivation) {
        if d.kind != "rows" || d.map.is_empty() {
            return;
        }
        let elements = self.doc.list_items(list_path);
        let rows = match self.rows(d, &i.path, &i.root) {
            Some(r) => r,
            None => return, // the source is not in this document
        };
        let tuple = |v: &mut Self, at: &str, by_value: bool| -> BTreeMap<String, String> {
            let mut t = BTreeMap::new();
            for (k, val) in &d.map {
                let place = if by_value { val } else { k };
                let got = v.place_value(place, at);
                t.insert(k.clone(), got);
            }
            t
        };
        let wanted: Vec<BTreeMap<String, String>> =
            rows.iter().map(|row| tuple(self, row, true)).collect();
        let current: Vec<BTreeMap<String, String>> =
            elements.iter().map(|el| tuple(self, el, false)).collect();
        let key = |t: &BTreeMap<String, String>| {
            d.map
                .iter()
                .map(|(k, _)| t.get(k).cloned().unwrap_or_else(|| "null".to_string()))
                .collect::<Vec<_>>()
                .join(" | ")
        };
        let sorted_keys = |ts: &[BTreeMap<String, String>]| {
            let mut out: Vec<String> = ts.iter().map(key).collect();
            out.sort();
            out
        };
        let mut want = sorted_keys(&wanted);
        let mut have = sorted_keys(&current);
        if want != have {
            let mut fix = SpecLinkFix::list(list_path, wanted);
            for (k, _) in &d.map {
                if !fix.tuple_keys.contains(k) {
                    fix.tuple_keys.push(k.clone());
                }
            }
            self.fixes.push(fix);
        }
        if elements.is_empty() {
            return; // not derived yet
        }
        want.sort();
        have.sort();
        if want != have {
            self.report(
                SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
                list_path,
                format!(
                    "the list is derived (rows of {}) as [{}], but holds [{}]",
                    d.source,
                    want.join("; "),
                    have.join("; ")
                ),
            );
        }
    }

    // --- @SummaryOf and summaryOf: ------------------------------------------------

    /// The detail elements of a summary (item path, id), in document order;
    /// `None` when the detail list does not resolve.
    fn detail_elements(&mut self, s: &SpecSummaryOf, root: &str) -> Option<Vec<(String, String)>> {
        let r = self.global(&s.detail, root, root)?;
        if r.kind != SPEC_PLACE_KIND_LIST {
            return None;
        }
        let mut out = Vec::new();
        let mut seen = HashSet::new();
        for lst in self.expand(&r.path) {
            for item in self.doc.list_items(&lst) {
                if !seen.insert(item.clone()) {
                    continue;
                }
                let id = self.item_id(&item);
                out.push((item, id));
            }
        }
        Some(out)
    }

    fn check_summary(&mut self, i: &LinkInstance<'_>, f: &SpecField) {
        let s = match f.summary_of() {
            Some(s) if s.document.is_empty() && f.kind == SPEC_FIELD_KIND_LIST => s,
            _ => return,
        };
        let detail = match self.detail_elements(&s, &i.root) {
            Some(d) => d,
            None => return,
        };
        let by_id: HashMap<&str, &str> = detail
            .iter()
            .map(|(item, id)| (id.as_str(), item.as_str()))
            .collect();
        let mut named: HashMap<String, String> = HashMap::new();
        for el in self.doc.list_items(&self.form_path(i, f)) {
            let ids = if s.r#match.is_empty() {
                vec![self.item_id(&el)]
            } else {
                spec_link_ids(&self.place_value(&s.r#match, &el))
            };
            for id in ids {
                let target = match by_id.get(id.as_str()) {
                    Some(t) => t.to_string(),
                    None => {
                        self.report(
                            SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL,
                            &el,
                            format!(
                                "the summary row names {}, which is no element of {}",
                                id, s.detail
                            ),
                        );
                        continue;
                    }
                };
                if let Some(first) = named.get(&id) {
                    let message = format!(
                        "the summary row names {}, which {} names already",
                        id, first
                    );
                    self.report(SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE, &el, message);
                    continue;
                }
                named.insert(id, el.clone());
                self.check_repeats(&s, &el, &target);
            }
        }
        if s.relation == "equal" {
            for (item, id) in &detail {
                if !named.contains_key(id) {
                    let message = format!(
                        "the detail element {} is named by no row of the summary {} (relation: equal)",
                        id,
                        self.form_path(i, f)
                    );
                    self.report(SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY, item, message);
                }
            }
        }
    }

    /// Checks that the values a summary row repeats agree with its detail
    /// element's.
    fn check_repeats(&mut self, s: &SpecSummaryOf, row: &str, detail: &str) {
        for (mine_at, theirs_at) in &s.repeats {
            let (mine, theirs) = match (self.at(mine_at, row), self.at(theirs_at, detail)) {
                (Some(m), Some(t)) => (m, t),
                _ => continue,
            };
            let mp = self.expand(&mine.path);
            let tp = self.expand(&theirs.path);
            if mp.len() != 1 || tp.len() != 1 {
                continue;
            }
            let have = self.value(&mine, &mp[0]);
            let want = self.value(&theirs, &tp[0]);
            if have != want {
                self.fixes.push(SpecLinkFix::set(
                    2,
                    &mp[0],
                    spec_link_field_of(&mine),
                    &want,
                ));
            }
            if have.is_empty() {
                continue; // not repeated yet: deriveFields writes it
            }
            if have != want {
                self.report(
                    SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
                    &mp[0],
                    format!(
                        "{} repeats {} of {} as \"{}\", but the detail element holds \"{}\"",
                        mine_at, theirs_at, detail, have, want
                    ),
                );
            }
        }
    }

    fn check_field_summary(
        &mut self,
        i: &LinkInstance<'_>,
        form: &str,
        ff: &FormFieldSpec,
        s: &SpecSummaryOf,
    ) {
        if !s.document.is_empty() || self.doc.form_field(form, &ff.name).is_none() {
            return;
        }
        let detail = match self.detail_elements(s, &i.root) {
            Some(d) => d,
            None => return,
        };
        let known: HashSet<&str> = detail.iter().map(|(_, id)| id.as_str()).collect();
        let mut seen: HashSet<String> = HashSet::new();
        for id in spec_link_ids(&self.form_value(form, &ff.name)) {
            if !known.contains(id.as_str()) {
                self.report(
                    SPEC_VALIDATION_CODE_SUMMARY_NOT_IN_DETAIL,
                    form,
                    format!(
                        "form field \"{}\" names {}, which is no element of {}",
                        ff.name, id, s.detail
                    ),
                );
            } else if seen.contains(&id) {
                self.report(
                    SPEC_VALIDATION_CODE_SUMMARY_DUPLICATE,
                    form,
                    format!("form field \"{}\" names {} twice", ff.name, id),
                );
            } else {
                seen.insert(id);
            }
        }
        if s.relation == "equal" {
            for (item, id) in &detail {
                if !seen.contains(id) {
                    self.report(
                        SPEC_VALIDATION_CODE_DETAIL_NOT_IN_SUMMARY,
                        item,
                        format!(
                            "the detail element {} is not named in \"{}\" of {} (relation: equal)",
                            id, ff.name, form
                        ),
                    );
                }
            }
        }
    }

    // --- inverseOf: ------------------------------------------------------------------

    /// The entries a reference field names, by its `refersTo` registries: id →
    /// item path. An entry of `<X>.@sectionId` is named by its section id, one
    /// of `<X>.<field>` by the value its own forms hold in that field.
    pub fn entries(&mut self, refers_to: &[String]) -> BTreeMap<String, String> {
        let key = refers_to.join(",");
        if let Some(hit) = self.entries_cache.get(&key) {
            return hit.clone();
        }
        let refl = self.refl();
        let mut out: BTreeMap<String, String> = BTreeMap::new();
        for lst in self.doc.list_paths() {
            for item in self.doc.list_items(&lst) {
                let id = match refl.resolve(&item).and_then(|r| r.target_class) {
                    Some(c) => c.section_id,
                    None => continue,
                };
                for t in refers_to {
                    if t.split('.').next() != Some(id.as_str()) {
                        continue;
                    }
                    match self.identity(&item, t) {
                        Some(name) if !name.is_empty() => {
                            out.entry(name).or_insert_with(|| item.clone());
                        }
                        _ => {}
                    }
                }
            }
        }
        self.entries_cache.insert(key, out.clone());
        out
    }

    /// How the registry key `target` (`<X>.@sectionId` or `<X>.<field>`)
    /// names the entry at `item`; `None` when it does not.
    pub fn identity(&mut self, item: &str, target: &str) -> Option<String> {
        let name = &target[target.find('.').map_or(0, |d| d + 1)..];
        if name == K_SECTION_ID_SLOT {
            return Some(self.item_id(item));
        }
        self.own_values(item, name).into_iter().next()
    }

    /// The nearest item at or above `path` whose class is one of `classes`.
    fn owner(&mut self, path: &str, classes: &HashSet<String>) -> Option<String> {
        let refl = self.refl();
        let mut p = self.nearest_item(path);
        while let Some(cur) = p {
            if refl
                .resolve(&cur)
                .and_then(|r| r.target_class)
                .is_some_and(|c| classes.contains(&c.section_id))
            {
                return Some(cur);
            }
            let slash = cur.rfind('/')?;
            p = self.nearest_item(&cur[..slash]);
        }
        None
    }

    fn first_identity(&mut self, owner: &str, refers_to: &[String]) -> Option<String> {
        refers_to.iter().find_map(|t| self.identity(owner, t))
    }

    fn check_inverse(&mut self, form: &str, ff: &FormFieldSpec, inv: &SpecInverseOf) {
        if self.doc.form_field(form, &ff.name).is_none() {
            return;
        }
        let value = self.form_value(form, &ff.name);
        if value.is_empty() {
            return;
        }
        let entries = self.entries(&ff.refers_to);
        if inv.symmetric() {
            self.check_symmetric(form, ff, inv, &value, &entries);
            return;
        }
        // The entry this field belongs to, as the other ends name it.
        for b in spec_link_ids(&value) {
            let b_path = match entries.get(&b) {
                Some(p) => p.clone(),
                None => continue, // a registry this document does not hold
            };
            let mut resolved = false;
            let mut names_back = false;
            let mut a_id: Option<String> = None;
            let mut writable: Option<(String, String)> = None;
            for end in &inv.fields {
                let r = match self.at(end, &b_path) {
                    Some(r) if r.form_field.is_some() => r,
                    _ => continue,
                };
                let end_refers = r
                    .form_field
                    .as_ref()
                    .map(|f| f.refers_to.clone())
                    .unwrap_or_default();
                let owner = match self.owner(form, &link_registry_classes(&end_refers)) {
                    Some(o) => o,
                    None => continue,
                };
                if !inv.r#where.is_empty() && !self.passes(&inv.r#where, &owner) {
                    return;
                }
                a_id = self.first_identity(&owner, &end_refers);
                let a = match &a_id {
                    Some(a) => a.clone(),
                    None => continue,
                };
                resolved = true;
                let ends = self.expand(&r.path);
                if writable.is_none() {
                    if let Some(first) = ends.first() {
                        writable = Some((first.clone(), r.field().to_string()));
                    }
                }
                for p in &ends {
                    if spec_link_ids(&self.form_value(p, r.field())).contains(&a) {
                        names_back = true;
                    }
                }
            }
            if resolved && !names_back {
                if let (Some((path, field)), Some(a)) = (&writable, &a_id) {
                    self.fixes.push(SpecLinkFix::append(path, field, a));
                }
                let message = format!(
                    "form field \"{}\" names {}, but {} does not name {} back ({})",
                    ff.name,
                    b,
                    b,
                    a_id.as_deref().unwrap_or(""),
                    inv.fields.join(", ")
                );
                self.report(SPEC_VALIDATION_CODE_INVERSE_MISSING, form, message);
            }
        }
    }

    fn check_symmetric(
        &mut self,
        form: &str,
        ff: &FormFieldSpec,
        inv: &SpecInverseOf,
        value: &str,
        entries: &BTreeMap<String, String>,
    ) {
        let row = match self.nearest_item(form) {
            Some(r) => r,
            None => return,
        };
        if !self.passes(&inv.r#where, &row) {
            return;
        }
        let a = match self.owner(
            &row[..row.rfind('/').unwrap_or(0)],
            &link_registry_classes(&ff.refers_to),
        ) {
            Some(a) => a,
            None => return,
        };
        let a_id = match self.first_identity(&a, &ff.refers_to) {
            Some(id) => id,
            None => return,
        };
        let filter_field = if inv.r#where.is_empty() {
            String::new()
        } else {
            SpecPlaceFilter::try_parse(&inv.r#where)
                .map(|f| f.field)
                .unwrap_or_default()
        };
        let where_values: HashSet<String> = if filter_field.is_empty() {
            HashSet::new()
        } else {
            self.own_values(&row, &filter_field).into_iter().collect()
        };

        // The same place beneath the named entry, every row of it.
        let generalise = |s: &str| -> String {
            match s.rfind('-') {
                Some(dash) if dash > 0 && is_int_text(s[dash + 1..].trim()) => {
                    format!("{}-*", &s[..dash])
                }
                _ => s.to_string(),
            }
        };
        let rel = form[a.len()..]
            .split('/')
            .map(generalise)
            .collect::<Vec<_>>()
            .join("/");
        for b in spec_link_ids(value) {
            let b_path = match entries.get(&b) {
                Some(p) if *p != a => p.clone(),
                _ => continue,
            };
            let mut counterpart = false;
            for p in self.expand(&format!("{}{}", b_path, rel)) {
                if self.is_counterpart(&p, ff, inv, &filter_field, &where_values, &a_id) {
                    counterpart = true;
                    break;
                }
            }
            if counterpart {
                continue;
            }
            if let Some(star) = rel.find("-*").filter(|s| *s > 0) {
                let lst = format!("{}{}", b_path, &rel[..star]);
                let below = if star + 3 <= rel.len() {
                    &rel[star + 3..]
                } else {
                    ""
                };
                let mut values = BTreeMap::new();
                let mut keys = Vec::new();
                put_ordered(
                    &mut values,
                    &mut keys,
                    format!("{}#{}", below, ff.name),
                    a_id.clone(),
                );
                if !filter_field.is_empty() {
                    for p in self.own_forms(&row) {
                        if self.doc.form_field(&p, &filter_field).is_some() {
                            let v = self.form_value(&p, &filter_field);
                            put_ordered(
                                &mut values,
                                &mut keys,
                                format!("{}#{}", &p[row.len() + 1..], filter_field),
                                v,
                            );
                        }
                    }
                }
                let mut fix = SpecLinkFix::add_row(1, &lst, values);
                fix.value_keys = keys;
                self.fixes.push(fix);
            }
            let suffix = if inv.r#where.is_empty() {
                String::new()
            } else {
                format!(" ({})", inv.r#where)
            };
            self.report(
                SPEC_VALIDATION_CODE_INVERSE_MISSING,
                form,
                format!(
                    "the row names {}, but {} holds no row naming {} back{}",
                    b, b, a_id, suffix
                ),
            );
        }
    }

    fn is_counterpart(
        &mut self,
        p: &str,
        ff: &FormFieldSpec,
        inv: &SpecInverseOf,
        filter_field: &str,
        where_values: &HashSet<String>,
        a_id: &str,
    ) -> bool {
        let r = match self.nearest_item(p) {
            Some(r) => r,
            None => return false,
        };
        if !self.passes(&inv.r#where, &r) {
            return false;
        }
        if !filter_field.is_empty() {
            let own: HashSet<String> = self.own_values(&r, filter_field).into_iter().collect();
            if !where_values.iter().all(|x| own.contains(x)) {
                return false;
            }
        }
        spec_link_ids(&self.form_value(p, &ff.name))
            .iter()
            .any(|id| id == a_id)
    }

    // --- @ExtractsLinks and the link rows -------------------------------------------

    fn check_extracts(&mut self, i: &LinkInstance<'a>, f: &'a SpecField) {
        let all = f.extracts_links();
        if all.is_empty() || f.kind != SPEC_FIELD_KIND_LIST {
            return;
        }
        let list_path = self.form_path(i, f);
        let rows = self.doc.list_items(&list_path);
        let own: Option<String> = self
            .nearest_item(&i.path)
            .map(|element| self.item_id(&element));

        // A link row holding no value at all (what accepting the marked removal
        // of a row leaves) is removed.
        for row in &rows {
            if !self.holds_value(row) {
                self.fixes.push(SpecLinkFix::remove_row(row, true));
            }
        }

        // The ids each row names, and its type (the values `set` writes).
        let set_keys: Vec<String> = all
            .iter()
            .flat_map(|e| e.set.iter().map(|(k, _)| k.clone()))
            .collect::<BTreeSet<_>>()
            .into_iter()
            .collect();
        let mut named: HashMap<String, Vec<String>> = HashMap::new();
        let mut seen: HashMap<String, String> = HashMap::new();
        let mut rowed: HashSet<String> = HashSet::new();
        for row in &rows {
            let mut unique: Vec<String> = Vec::new();
            for e in &all {
                let r = match self.at(&e.r#ref, row) {
                    Some(r) => r,
                    None => continue,
                };
                for p in self.expand(&r.path) {
                    for id in spec_link_ids(&self.value(&r, &p)) {
                        if !unique.contains(&id) {
                            unique.push(id);
                        }
                    }
                }
            }
            let types: Vec<String> = set_keys.iter().map(|k| self.place_value(k, row)).collect();
            let typ = types.join(" | ");
            for id in &unique {
                rowed.insert(id.clone());
                let key = format!("{} // {}", id, typ);
                match seen.get(&key) {
                    Some(first) => {
                        let message = format!(
                            "the row names {} with the type \"{}\", as {} does",
                            id, typ, first
                        );
                        self.report(SPEC_VALIDATION_CODE_DUPLICATE_LINK_ROW, row, message);
                    }
                    None => {
                        seen.insert(key, row.clone());
                    }
                }
            }
            named.insert(row.clone(), unique);
        }

        let excluded = |id: &str| own.as_deref() == Some(id);
        for e in &all {
            let ref_refers: Option<Vec<String>> = if rows.is_empty() {
                self.ref_spec_from_model(f, &e.r#ref)
                    .map(|ff| ff.refers_to.clone())
            } else {
                self.at(&e.r#ref, &rows[0])
                    .and_then(|r| r.form_field)
                    .map(|ff| ff.refers_to)
            };
            let ref_refers = match ref_refers {
                Some(r) => r,
                None => continue,
            };
            let registry: HashSet<String> = self.entries(&ref_refers).into_keys().collect();
            let mut found: Vec<String> = Vec::new();
            for place in &e.from {
                let p = if place.starts_with("./") {
                    place.clone()
                } else {
                    format!("./{}", place)
                };
                let r = match self.at(&p, &i.path) {
                    Some(r) => r,
                    None => continue,
                };
                for path in self.expand(&r.path) {
                    for id in link_ids_in(&self.value(&r, &path), &registry) {
                        if !excluded(&id) && !found.contains(&id) {
                            found.push(id);
                        }
                    }
                }
            }
            for id in &found {
                if rowed.contains(id) {
                    continue;
                }
                if e.mode == "generate" {
                    let mut values = BTreeMap::new();
                    let mut keys = Vec::new();
                    let anchor = format!("{}-0", list_path);
                    let mut writes: Vec<SpecStringPair> = vec![(e.r#ref.clone(), id.clone())];
                    writes.extend(e.set.iter().cloned());
                    for (place, value) in &writes {
                        let r = match self.at(place, &anchor) {
                            Some(r) if r.form_field.is_some() => r,
                            _ => continue,
                        };
                        let rel = tail_from(&r.path, anchor.len() + 1);
                        put_ordered(
                            &mut values,
                            &mut keys,
                            format!("{}#{}", rel, r.field()),
                            value.clone(),
                        );
                    }
                    let mut fix = SpecLinkFix::add_row(1, &list_path, values);
                    fix.value_keys = keys;
                    self.fixes.push(fix);
                }
                let warn = if e.mode == "warn" {
                    " (warn: the agent adds it)"
                } else {
                    ""
                };
                self.report(
                    SPEC_VALIDATION_CODE_EXTRACTED_LINK_MISSING,
                    &list_path,
                    format!(
                        "{} is named in {} but has no row{}",
                        id,
                        e.from.join(" / "),
                        warn
                    ),
                );
            }
        }
        // A generated row: every `set` value of a generate-mode use matches.
        for e in &all {
            if e.mode != "generate" {
                continue;
            }
            let mut mine: HashSet<String> = HashSet::new();
            for place in &e.from {
                let p = if place.starts_with("./") {
                    place.clone()
                } else {
                    format!("./{}", place)
                };
                let r = match self.at(&p, &i.path) {
                    Some(r) => r,
                    None => continue,
                };
                let mut registry: HashSet<String> = HashSet::new();
                if let Some(first) = rows.first() {
                    if let Some(ff) = self.at(&e.r#ref, first).and_then(|r| r.form_field) {
                        registry = self.entries(&ff.refers_to).into_keys().collect();
                    }
                }
                for path in self.expand(&r.path) {
                    mine.extend(link_ids_in(&self.value(&r, &path), &registry));
                }
            }
            for row in &rows {
                let generated = e.set.iter().all(|(k, v)| self.place_value(k, row) == *v);
                if !generated {
                    continue;
                }
                for id in named.get(row).cloned().unwrap_or_default() {
                    if !mine.contains(&id) {
                        self.fixes.push(SpecLinkFix::remove_row(row, false));
                        self.report(
                            SPEC_VALIDATION_CODE_EXTRACTED_LINK_STALE,
                            row,
                            format!(
                                "the generated row names {}, which {} no longer names",
                                id,
                                e.from.join(" / ")
                            ),
                        );
                    }
                }
            }
        }
    }

    fn ref_spec_from_model(&self, lst: &SpecField, r#ref: &str) -> Option<&'a FormFieldSpec> {
        let el = self.model.class_named(&lst.element_type)?;
        let dot = r#ref.find('.')?;
        let (id, name) = (&r#ref[..dot], &r#ref[dot + 1..]);
        for f in &el.fields {
            let fid = if f.name == "content" {
                &el.section_id
            } else {
                &f.section_id
            };
            if fid != id {
                continue;
            }
            if let Some(ff) = f.form_fields.iter().find(|ff| ff.name == name) {
                return Some(ff);
            }
        }
        None
    }

    // --- @SameAs -------------------------------------------------------------------

    fn check_same_as(&mut self, root_type: &str) {
        for b in spec_same_as_bindings(&self.refl(), root_type) {
            if b.holder_path.is_empty() {
                continue;
            }
            let copies = self.expand(&b.copy_path);
            let holders = self.expand(&b.holder_path);
            if copies.len() != holders.len() {
                continue;
            }
            for (c, h) in copies.iter().zip(&holders) {
                if self.compare_subtrees(c, h) {
                    self.fixes.push(SpecLinkFix::copy(c, h));
                }
            }
        }
    }

    /// Every value beneath `root` (itself included), keyed by its path
    /// relative to `root` with list items written by their section id, so two
    /// subtrees compare element by element.
    pub fn subtree(&mut self, root: &str) -> BTreeMap<String, SpecSubtreeValue> {
        let prefix = format!("{}/", root);
        let under = |p: &str| p == root || p.starts_with(&prefix);
        let doc = self.doc;
        let mut out: BTreeMap<String, SpecSubtreeValue> = BTreeMap::new();
        let put =
            |out: &mut BTreeMap<String, SpecSubtreeValue>, k: String, path: &str, value: String| {
                if value.is_empty() {
                    out.remove(&k);
                } else {
                    out.insert(
                        k,
                        SpecSubtreeValue {
                            path: path.to_string(),
                            value,
                        },
                    );
                }
            };
        for p in doc.content_paths() {
            if under(&p) {
                let k = format!("c:{}", self.subtree_key(root, &p));
                let v = self.content_value(&p);
                put(&mut out, k, &p, v);
            }
        }
        for p in doc.form_paths() {
            if !under(&p) {
                continue;
            }
            for name in doc.form_field_names(&p) {
                let k = format!("f:{}#{}", self.subtree_key(root, &p), name);
                let v = self.form_value(&p, &name);
                put(&mut out, k, &p, v);
            }
        }
        for p in doc.headline_paths() {
            if under(&p) {
                let k = format!("h:{}", self.subtree_key(root, &p));
                let v = self.headline_value(&p);
                put(&mut out, k, &p, v);
            }
        }
        for lst in doc.list_paths() {
            if !under(&lst) {
                continue;
            }
            for item in doc.list_items(&lst) {
                let k = format!("i:{}", self.subtree_key(root, &item));
                let v = self.item_id(&item);
                put(&mut out, k, &item, v);
            }
        }
        out
    }

    /// The key of `path` beneath `root`: list items written by their section
    /// id.
    fn subtree_key(&mut self, root: &str, path: &str) -> String {
        if path == root {
            return String::new();
        }
        let rel = &path[root.len() + 1..];
        if rel.is_empty() {
            return String::new();
        }
        let mut out = Vec::new();
        let mut at = root.to_string();
        for seg in rel.split('/') {
            at = format!("{}/{}", at, seg);
            if self.is_item(&at) {
                let base = &seg[..seg.rfind('-').unwrap_or(seg.len())];
                out.push(format!("{}[{}]", base, self.item_id(&at)));
            } else {
                out.push(seg.to_string());
            }
        }
        out.join("/")
    }

    /// Reports every difference of `copy` from `holder`; whether there is one.
    fn compare_subtrees(&mut self, copy: &str, holder: &str) -> bool {
        let mine = self.subtree(copy);
        let theirs = self.subtree(holder);
        let keys: BTreeSet<&String> = mine.keys().chain(theirs.keys()).collect();
        // An element on one side only is one finding; its values are not
        // compared.
        let one_sided: Vec<&str> = keys
            .iter()
            .filter(|k| k.starts_with("i:") && mine.contains_key(**k) != theirs.contains_key(**k))
            .map(|k| &k[2..])
            .collect();
        let beneath = |k: &str| {
            if k.starts_with("i:") {
                return false;
            }
            let rel = k[2..].split('#').next().unwrap_or("");
            one_sided
                .iter()
                .any(|o| rel == *o || rel.starts_with(&format!("{}/", o)))
        };
        let mut differs = false;
        let mut findings = Vec::new();
        for k in &keys {
            let a = mine.get(*k);
            let b = theirs.get(*k);
            let same = match (a, b) {
                (Some(a), Some(b)) => a.value == b.value,
                (None, None) => true,
                _ => false,
            };
            if same || beneath(k) {
                continue;
            }
            differs = true;
            let what = if k.starts_with("i:") {
                format!("element {}", a.or(b).map_or("", |x| x.value.as_str()))
            } else if k.starts_with("h:") {
                "the headline".to_string()
            } else if k.starts_with("c:") {
                "the content".to_string()
            } else {
                format!("form field \"{}\"", &k[k.find('#').map_or(0, |h| h + 1)..])
            };
            let at = a.map_or(copy, |a| a.path.as_str()).to_string();
            findings.push((
                at,
                format!(
                    "the copy of {} differs in {}: the copy holds \"{}\", the holder \"{}\"",
                    holder,
                    what,
                    a.map_or("", |x| x.value.as_str()),
                    b.map_or("", |x| x.value.as_str())
                ),
            ));
        }
        for (at, message) in findings {
            self.report(SPEC_VALIDATION_CODE_SAME_AS_MISMATCH, &at, message);
        }
        differs
    }

    // --- helpers of the fixes -----------------------------------------------------

    /// The forms directly beneath `row` (`<row>/<member>`).
    fn own_forms(&self, row: &str) -> Vec<String> {
        let prefix = format!("{}/", row);
        self.doc
            .form_paths()
            .into_iter()
            .filter(|p| p.starts_with(&prefix) && !p[prefix.len()..].contains('/'))
            .collect()
    }

    /// Whether anything beneath `path` holds a value (marks included).
    pub fn holds_value(&mut self, path: &str) -> bool {
        if self.valued.is_none() {
            let mut valued: HashSet<String> = HashSet::new();
            let up = |valued: &mut HashSet<String>, p: &str, own: bool| {
                let mut cur = if own {
                    p.to_string()
                } else {
                    p.rfind('/').map_or(String::new(), |s| p[..s].to_string())
                };
                while !cur.is_empty() && !valued.contains(&cur) {
                    valued.insert(cur.clone());
                    cur = cur
                        .rfind('/')
                        .map_or(String::new(), |s| cur[..s].to_string());
                }
            };
            let doc = self.doc;
            for p in doc.content_paths() {
                if !doc.content_or(&p).trim().is_empty() {
                    up(&mut valued, &p, true);
                }
            }
            for p in doc.form_paths() {
                if doc
                    .form_field_names(&p)
                    .iter()
                    .any(|n| !doc.form_field_or(&p, n).trim().is_empty())
                {
                    up(&mut valued, &p, true);
                }
            }
            for p in doc.headline_paths() {
                if !doc.headline_or(&p).is_empty() {
                    up(&mut valued, &p, false);
                }
            }
            for lst in doc.list_paths() {
                if !doc.list_items(&lst).is_empty() {
                    up(&mut valued, &lst, true);
                }
            }
            self.valued = Some(valued);
        }
        self.valued.as_ref().is_some_and(|v| v.contains(path))
    }
}

/// The comma-separated ids of `value`, trimmed, empty ones dropped.
pub fn spec_link_ids(value: &str) -> Vec<String> {
    value
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
        .collect()
}

/// The field a resolved value place names for a write: the form field, the
/// headline's reserved field ([`K_SPEC_HEADLINE_FIELD`]), or `""` for content.
pub fn spec_link_field_of(r: &SpecPlaceResolution) -> &str {
    match r.kind.as_str() {
        SPEC_PLACE_KIND_FORM_FIELD => r.field(),
        SPEC_PLACE_KIND_HEADLINE => K_SPEC_HEADLINE_FIELD,
        _ => "",
    }
}

/// Whether two values agree: as id sets for a multi-valued reference, as
/// numbers for a numeric field, else as text with trailing whitespace ignored.
fn link_same_value(a: &str, b: &str, spec: Option<&FormFieldSpec>) -> bool {
    if let Some(spec) = spec {
        if spec.multiple && !spec.refers_to.is_empty() {
            let x: HashSet<String> = spec_link_ids(a).into_iter().collect();
            let y: HashSet<String> = spec_link_ids(b).into_iter().collect();
            return x == y;
        }
        if matches!(spec.type_.as_str(), "int" | "double" | "num") {
            if let (Some(x), Some(y)) = (link_num_try_parse(a), link_num_try_parse(b)) {
                return x == y;
            }
        }
    }
    let norm = |s: &str| {
        s.split('\n')
            .map(str::trim_end)
            .collect::<Vec<_>>()
            .join("\n")
            .trim()
            .to_string()
    };
    norm(a) == norm(b)
}

/// The non-empty values joined with `sep`.
fn join_non_empty(values: &[String], sep: &str) -> String {
    values
        .iter()
        .filter(|s| !s.is_empty())
        .cloned()
        .collect::<Vec<_>>()
        .join(sep)
}

/// `s` from byte `n` on, `""` when `s` is shorter (a slice that cannot fail).
pub(crate) fn tail_from(s: &str, n: usize) -> &str {
    s.get(n..).unwrap_or("")
}

fn link_registry_classes(refers_to: &[String]) -> HashSet<String> {
    refers_to
        .iter()
        .map(|t| t.split('.').next().unwrap_or("").to_string())
        .collect()
}

/// The ids of `registry` named in `text`, each matched exactly (not as a part
/// of a longer id), in order of first appearance.
fn link_ids_in(text: &str, registry: &HashSet<String>) -> Vec<String> {
    let mut out: Vec<String> = Vec::new();
    for id in link_id_tokens(text) {
        if registry.contains(id) && !out.iter().any(|o| o == id) {
            out.push(id.to_string());
        }
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn id_tokens_follow_the_reference_pattern() {
        assert_eq!(link_id_tokens("REQ-A, REQ-B."), vec!["REQ-A", "REQ-B"]);
        assert_eq!(link_id_tokens("A- -B x"), vec!["A", "B", "x"]);
        assert_eq!(link_id_tokens("--"), Vec::<&str>::new());
    }

    #[test]
    fn numbers_read_as_dart_num_try_parse() {
        assert_eq!(link_num_try_parse(" 3 "), Some(3.0));
        assert_eq!(link_num_try_parse("0x1F"), Some(31.0));
        assert_eq!(link_num_try_parse("1.5e2"), Some(150.0));
        assert!(link_num_try_parse("NaN").is_some_and(f64::is_nan));
        assert_eq!(link_num_try_parse("abc"), None);
    }
}
