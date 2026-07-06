//! `spec_document` — a sparse, live instance of a TomSpecs document, a faithful
//! port of the Go `spec_document.go`.
//!
//! The structure is defined by the [`SpecModel`](crate::spec_model::SpecModel)
//! class graph; this holds only the values the user/agent has actually set,
//! keyed by the globally-unique section-ID path. Nothing is materialised until
//! written, so an untouched document is empty (the "empty = no value" rule).
//!
//! Three sparse stores cover the writable field kinds:
//!
//!   - content — content/scalar leaves: path → string value;
//!   - form — `@Form` sections: path → (form-field name → value);
//!   - list_items — lists: list path → ordered item paths.
//!
//! List item paths are `<listPath>-<seq>` where seq is a per-list monotonic
//! counter that never reuses a number. Stores use `BTreeMap` so iteration is
//! already sorted by path (the byte-stable codecs rely on this).

use std::collections::BTreeMap;

use crate::json::{encode_str, Json};
use crate::spec_section_id::{SpecSectionIdCollision, SpecSectionIdError};

/// The plain-data shape of a single list store entry. `ids` maps an item path to
/// its assigned section id; it is present only for lists that carry section ids
/// (AA1 criteria 3–6) and is omitted (empty) otherwise, so byte-stable output
/// stays identical for id-less lists.
#[derive(Debug, Clone, PartialEq)]
pub struct ListJson {
    pub seq: i64,
    pub items: Vec<String>,
    pub ids: BTreeMap<String, String>,
}

/// A `SpecDocument::to_json`-shaped plain-data view of a document. Only non-empty
/// stores are populated.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct DocumentJson {
    pub content: BTreeMap<String, String>,
    pub forms: BTreeMap<String, BTreeMap<String, String>>,
    pub lists: BTreeMap<String, ListJson>,
}

impl DocumentJson {
    /// Builds a `DocumentJson` from a parsed `{content,forms,lists}` JSON value.
    pub fn from_json(v: &Json) -> DocumentJson {
        let mut out = DocumentJson::default();
        if let Some(content) = v.get("content").and_then(|j| j.as_object()) {
            for (k, val) in content {
                if let Some(s) = val.as_str() {
                    out.content.insert(k.clone(), s.to_string());
                }
            }
        }
        if let Some(forms) = v.get("forms").and_then(|j| j.as_object()) {
            for (k, val) in forms {
                if let Some(fields) = val.as_object() {
                    let mut entry = BTreeMap::new();
                    for (f, fv) in fields {
                        if let Some(s) = fv.as_str() {
                            entry.insert(f.clone(), s.to_string());
                        }
                    }
                    out.forms.insert(k.clone(), entry);
                }
            }
        }
        if let Some(lists) = v.get("lists").and_then(|j| j.as_object()) {
            for (k, val) in lists {
                let seq = val.get("seq").and_then(|s| s.as_i64()).unwrap_or(0);
                let mut items = Vec::new();
                if let Some(arr) = val.get("items").and_then(|s| s.as_array()) {
                    for it in arr {
                        if let Some(s) = it.as_str() {
                            items.push(s.to_string());
                        }
                    }
                }
                let mut ids = BTreeMap::new();
                if let Some(obj) = val.get("ids").and_then(|s| s.as_object()) {
                    for (ik, iv) in obj {
                        if let Some(s) = iv.as_str() {
                            ids.insert(ik.clone(), s.to_string());
                        }
                    }
                }
                out.lists.insert(k.clone(), ListJson { seq, items, ids });
            }
        }
        out
    }

    /// Renders a deterministic canonical JSON string (sorted keys, fixed field
    /// order content/forms/lists, omitting empty stores). Used only for
    /// internal consistency checks — both compared sides use this same encoder.
    pub fn to_canonical_json(&self) -> String {
        let mut out = String::from("{");
        let mut first = true;
        if !self.content.is_empty() {
            first = false;
            out.push_str("\"content\":{");
            let mut inner_first = true;
            for (k, v) in &self.content {
                if !inner_first {
                    out.push(',');
                }
                inner_first = false;
                out.push_str(&encode_str(k));
                out.push(':');
                out.push_str(&encode_str(v));
            }
            out.push('}');
        }
        if !self.forms.is_empty() {
            if !first {
                out.push(',');
            }
            first = false;
            out.push_str("\"forms\":{");
            let mut form_first = true;
            for (k, fields) in &self.forms {
                if !form_first {
                    out.push(',');
                }
                form_first = false;
                out.push_str(&encode_str(k));
                out.push_str(":{");
                let mut field_first = true;
                for (f, v) in fields {
                    if !field_first {
                        out.push(',');
                    }
                    field_first = false;
                    out.push_str(&encode_str(f));
                    out.push(':');
                    out.push_str(&encode_str(v));
                }
                out.push('}');
            }
            out.push('}');
        }
        if !self.lists.is_empty() {
            if !first {
                out.push(',');
            }
            out.push_str("\"lists\":{");
            let mut list_first = true;
            for (k, spec) in &self.lists {
                if !list_first {
                    out.push(',');
                }
                list_first = false;
                out.push_str(&encode_str(k));
                out.push_str(":{\"seq\":");
                out.push_str(&spec.seq.to_string());
                out.push_str(",\"items\":[");
                for (i, it) in spec.items.iter().enumerate() {
                    if i > 0 {
                        out.push(',');
                    }
                    out.push_str(&encode_str(it));
                }
                out.push(']');
                if !spec.ids.is_empty() {
                    out.push_str(",\"ids\":{");
                    let mut id_first = true;
                    for (ik, iv) in &spec.ids {
                        if !id_first {
                            out.push(',');
                        }
                        id_first = false;
                        out.push_str(&encode_str(ik));
                        out.push(':');
                        out.push_str(&encode_str(iv));
                    }
                    out.push('}');
                }
                out.push('}');
            }
            out.push('}');
        }
        out.push('}');
        out
    }
}

/// The sparse in-memory document.
///
/// Each list item also carries a **section id** (AA1 criteria 3–6): the
/// document-semantic identity generated from the list field's
/// `@SectionIdPattern`. This is distinct from the internal `-<seq>` path key:
/// the seq path keeps nested values attached across edits (never renumbered),
/// while the section id is what the document exposes and may be overridden
/// ([`SpecDocument::set_item_section_id`], criterion 5) or reused same-day after
/// the last item is deleted (criterion 6). Section ids live in
/// `item_section_id`, keyed by the internal item path.
#[derive(Debug, Clone, Default)]
pub struct SpecDocument {
    content: BTreeMap<String, String>,
    form: BTreeMap<String, BTreeMap<String, String>>,
    list_items: BTreeMap<String, Vec<String>>,
    list_seq: BTreeMap<String, i64>,
    item_section_id: BTreeMap<String, String>,
    /// The authoring object-model version (`major.minor`) this document was
    /// loaded from, or `""` for a brand-new / unstamped document. Retained here
    /// by [`SpecDocument::from_yaml`] so a consumer need not thread
    /// `decoded.model_version` to the typed facade by hand (the "forgot the
    /// stamp" class of bug); the generated `load_yaml` / `load_file` associated
    /// functions apply it automatically. Empty means "none", matching how
    /// [`decode_yaml`](crate::decode_yaml) reports the stamp.
    pub model_version: String,
}

impl SpecDocument {
    /// Returns an empty document.
    pub fn new() -> SpecDocument {
        SpecDocument::default()
    }

    /// Loads a `*.docspecs.yaml` document in one call: decode the YAML, populate
    /// the sparse stores ([`SpecDocument::load_json`]), and retain the parsed
    /// `model_version` on the document. Collapses the former three-step
    /// `decode_yaml` → `load_json` → thread-`document_version` incantation
    /// (§ item 4).
    pub fn from_yaml(yaml: &str) -> SpecDocument {
        let decoded = crate::spec_document_yaml::decode_yaml(yaml);
        let mut doc = SpecDocument::new();
        doc.load_json(&decoded.document);
        doc.model_version = decoded.model_version;
        doc
    }

    /// Loads a `*.docspecs.yaml` document from the file at `path` — the file
    /// companion to [`SpecDocument::from_yaml`] the generated `load_file`
    /// associated function delegates to.
    pub fn from_file(path: &str) -> SpecDocument {
        let yaml = std::fs::read_to_string(path)
            .unwrap_or_else(|e| panic!("failed to read {}: {}", path, e));
        SpecDocument::from_yaml(&yaml)
    }

    // --- content -----------------------------------------------------------

    /// Returns the content string at `path`, or `None` when unset.
    pub fn content(&self, path: &str) -> Option<&String> {
        self.content.get(path)
    }

    /// Returns the content string at `path`, or `""` when unset.
    pub fn content_or(&self, path: &str) -> String {
        self.content.get(path).cloned().unwrap_or_default()
    }

    /// Sets the content string at `path`. An empty value clears it.
    pub fn set_content(&mut self, path: &str, value: &str) {
        if value.is_empty() {
            self.content.remove(path);
        } else {
            self.content.insert(path.to_string(), value.to_string());
        }
    }

    // --- forms -------------------------------------------------------------

    /// Returns form `field_name` at `path`, or `None` when unset.
    pub fn form_field(&self, path: &str, field_name: &str) -> Option<&String> {
        self.form.get(path).and_then(|fields| fields.get(field_name))
    }

    /// Returns form `field_name` at `path`, or `""` when unset.
    pub fn form_field_or(&self, path: &str, field_name: &str) -> String {
        self.form
            .get(path)
            .and_then(|fields| fields.get(field_name))
            .cloned()
            .unwrap_or_default()
    }

    /// Sets form `field_name` at `path`. An empty value clears that field (and
    /// the whole form entry once its last field is gone).
    pub fn set_form_field(&mut self, path: &str, field_name: &str, value: &str) {
        if value.is_empty() {
            if let Some(fields) = self.form.get_mut(path) {
                fields.remove(field_name);
                if fields.is_empty() {
                    self.form.remove(path);
                }
            }
            return;
        }
        self.form
            .entry(path.to_string())
            .or_default()
            .insert(field_name.to_string(), value.to_string());
    }

    // --- lists -------------------------------------------------------------

    /// Returns a copy of the item paths of the list at `list_path`.
    pub fn list_items(&self, list_path: &str) -> Vec<String> {
        self.list_items.get(list_path).cloned().unwrap_or_default()
    }

    /// Appends a new item to the list at `list_path` and returns its stable path.
    pub fn add_list_item(&mut self, list_path: &str) -> String {
        let seq = self.list_seq.get(list_path).copied().unwrap_or(0) + 1;
        self.list_seq.insert(list_path.to_string(), seq);
        let item_path = format!("{}-{}", list_path, seq);
        self.list_items
            .entry(list_path.to_string())
            .or_default()
            .push(item_path.clone());
        item_path
    }

    /// Appends a new item to the list at `list_path`, assigns it `section_id`,
    /// and returns its stable path. The id is checked for uniqueness against the
    /// list's other items (AA1 criterion 5); a collision returns
    /// [`SpecSectionIdError::Collision`] and leaves the document untouched.
    /// Section id *generation* from a `@SectionIdPattern` lives in the caller (it
    /// needs the pattern); this layer only stores and guards uniqueness.
    pub fn add_list_item_with_section_id(
        &mut self,
        list_path: &str,
        section_id: &str,
    ) -> Result<String, SpecSectionIdError> {
        self.assert_section_id_free(list_path, section_id, "")?;
        let item_path = self.add_list_item(list_path);
        self.item_section_id
            .insert(item_path.clone(), section_id.to_string());
        Ok(item_path)
    }

    /// Returns the section id assigned to the list item at `item_path`, or `None`
    /// when none has been set (AA1 criterion 1 read path).
    pub fn item_section_id(&self, item_path: &str) -> Option<&String> {
        self.item_section_id.get(item_path)
    }

    /// Returns the section id assigned to `item_path`, or `""` when none.
    pub fn item_section_id_or(&self, item_path: &str) -> String {
        self.item_section_id.get(item_path).cloned().unwrap_or_default()
    }

    /// Overrides the section id of the list item at `item_path` (AA1 criterion
    /// 5). It validates that the new id is unique among the *other* items of the
    /// same owning list; a collision returns [`SpecSectionIdError::Collision`].
    /// Assigning an id equal to the item's current id is a no-op. Returns
    /// [`SpecSectionIdError::NotLiveItem`] if `item_path` is not a live list item.
    pub fn set_item_section_id(&mut self, item_path: &str, id: &str) -> Result<(), SpecSectionIdError> {
        let owning_list = match self.owning_list_of(item_path) {
            Some(k) => k,
            None => {
                return Err(SpecSectionIdError::NotLiveItem {
                    item_path: item_path.to_string(),
                })
            }
        };
        if let Some(cur) = self.item_section_id.get(item_path) {
            if cur == id {
                return Ok(());
            }
        }
        self.assert_section_id_free(&owning_list, id, item_path)?;
        self.item_section_id.insert(item_path.to_string(), id.to_string());
        Ok(())
    }

    /// Returns the section ids currently assigned within the list at `list_path`,
    /// in item order (items without an id are skipped). Feeds both id generation
    /// (`existing_ids`) and uniqueness checks.
    pub fn list_item_section_ids(&self, list_path: &str) -> Vec<String> {
        let mut out = Vec::new();
        if let Some(items) = self.list_items.get(list_path) {
            for item_path in items {
                if let Some(id) = self.item_section_id.get(item_path) {
                    out.push(id.clone());
                }
            }
        }
        out
    }

    /// Returns the `list_items` key that owns `item_path`, or `None` when none
    /// does.
    fn owning_list_of(&self, item_path: &str) -> Option<String> {
        self.list_items
            .iter()
            .find(|(_, items)| items.iter().any(|it| it == item_path))
            .map(|(k, _)| k.clone())
    }

    /// Returns [`SpecSectionIdError::Collision`] when `id` is already used by an
    /// item of `list_path` other than `except_item_path` (`""` for none).
    fn assert_section_id_free(
        &self,
        list_path: &str,
        id: &str,
        except_item_path: &str,
    ) -> Result<(), SpecSectionIdError> {
        if let Some(items) = self.list_items.get(list_path) {
            for item_path in items {
                if item_path == except_item_path {
                    continue;
                }
                if let Some(cur) = self.item_section_id.get(item_path) {
                    if cur == id {
                        return Err(SpecSectionIdError::Collision(SpecSectionIdCollision {
                            id: id.to_string(),
                            list_path: list_path.to_string(),
                        }));
                    }
                }
            }
        }
        Ok(())
    }

    /// Removes the list item at `item_path` along with every value nested
    /// beneath it. The counter is left untouched so future items keep getting
    /// fresh sequence numbers (no renumbering). Returns whether an item was
    /// removed.
    pub fn remove_list_item(&mut self, item_path: &str) -> bool {
        let owning_list = self
            .list_items
            .iter()
            .find(|(_, items)| items.iter().any(|it| it == item_path))
            .map(|(k, _)| k.clone());
        let owning_list = match owning_list {
            Some(k) => k,
            None => return false,
        };
        if let Some(items) = self.list_items.get_mut(&owning_list) {
            if let Some(at) = items.iter().position(|it| it == item_path) {
                items.remove(at);
            }
            if items.is_empty() {
                self.list_items.remove(&owning_list);
            }
        }
        self.purge_under(item_path);
        true
    }

    fn purge_under(&mut self, prefix: &str) {
        self.content.retain(|k, _| !is_under(k, prefix));
        self.form.retain(|k, _| !is_under(k, prefix));
        self.list_items.retain(|k, _| !is_under(k, prefix));
        self.list_seq.retain(|k, _| !is_under(k, prefix));
        self.item_section_id.retain(|k, _| !is_under(k, prefix));
    }

    // --- queries -----------------------------------------------------------

    /// Reports whether the document holds no values at all.
    pub fn is_empty(&self) -> bool {
        self.content.is_empty() && self.form.is_empty() && self.list_items.is_empty()
    }

    /// Reports whether any value exists at `prefix` or nested beneath it — the
    /// structural "empty = no value" test (the exact inverse of the purge
    /// predicate, so emptiness and purge stay in lock-step).
    pub fn has_values_under(&self, prefix: &str) -> bool {
        self.content.keys().any(|k| is_under(k, prefix))
            || self.form.keys().any(|k| is_under(k, prefix))
            || self.list_items.keys().any(|k| is_under(k, prefix))
    }

    /// Returns the content paths (sorted).
    pub fn content_paths(&self) -> Vec<String> {
        self.content.keys().cloned().collect()
    }

    /// Returns the form paths (sorted).
    pub fn form_paths(&self) -> Vec<String> {
        self.form.keys().cloned().collect()
    }

    /// Returns the list paths (sorted).
    pub fn list_paths(&self) -> Vec<String> {
        self.list_items.keys().cloned().collect()
    }

    /// Returns the field names set at a form path (sorted).
    pub fn form_field_names(&self, path: &str) -> Vec<String> {
        self.form
            .get(path)
            .map(|f| f.keys().cloned().collect())
            .unwrap_or_default()
    }

    /// Returns the number of items in the list at `list_path`.
    pub fn list_item_count(&self, list_path: &str) -> usize {
        self.list_items.get(list_path).map(|v| v.len()).unwrap_or(0)
    }

    /// Returns content paths in ascending order.
    pub fn sorted_content_paths(&self) -> Vec<String> {
        self.content_paths()
    }

    // --- persistence -------------------------------------------------------

    /// Returns a plain-data view of every value held, for persistence. Only
    /// non-empty stores are included. The inverse of [`SpecDocument::load_json`].
    pub fn to_json(&self) -> DocumentJson {
        let mut out = DocumentJson::default();
        out.content = self.content.clone();
        for (k, fields) in &self.form {
            out.forms.insert(k.clone(), fields.clone());
        }
        for (k, items) in &self.list_items {
            let seq = self
                .list_seq
                .get(k)
                .copied()
                .unwrap_or_else(|| items.len() as i64);
            let mut ids = BTreeMap::new();
            for item_path in items {
                if let Some(id) = self.item_section_id.get(item_path) {
                    ids.insert(item_path.clone(), id.clone());
                }
            }
            out.lists.insert(
                k.clone(),
                ListJson {
                    seq,
                    items: items.clone(),
                    ids,
                },
            );
        }
        out
    }

    /// Replaces every store from a `DocumentJson`-shaped value. Empty entries
    /// are skipped, mirroring the other ports' loadJson.
    pub fn load_json(&mut self, j: &DocumentJson) {
        self.content.clear();
        self.form.clear();
        self.list_items.clear();
        self.list_seq.clear();
        self.item_section_id.clear();
        for (k, v) in &j.content {
            self.content.insert(k.clone(), v.clone());
        }
        for (k, fields) in &j.forms {
            if fields.is_empty() {
                continue;
            }
            self.form.insert(k.clone(), fields.clone());
        }
        for (k, spec) in &j.lists {
            if !spec.items.is_empty() {
                self.list_items.insert(k.clone(), spec.items.clone());
                let seq = if spec.seq != 0 {
                    spec.seq
                } else {
                    spec.items.len() as i64
                };
                self.list_seq.insert(k.clone(), seq);
                for (item_path, id) in &spec.ids {
                    self.item_section_id.insert(item_path.clone(), id.clone());
                }
            }
        }
    }
}

fn is_under(key: &str, prefix: &str) -> bool {
    key == prefix
        || key.starts_with(&format!("{}/", prefix))
        || key.starts_with(&format!("{}-", prefix))
}
