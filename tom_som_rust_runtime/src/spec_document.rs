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

/// The plain-data shape of a single list store entry.
#[derive(Debug, Clone, PartialEq)]
pub struct ListJson {
    pub seq: i64,
    pub items: Vec<String>,
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
                out.lists.insert(k.clone(), ListJson { seq, items });
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
                out.push_str("]}");
            }
            out.push('}');
        }
        out.push('}');
        out
    }
}

/// The sparse in-memory document.
#[derive(Debug, Clone, Default)]
pub struct SpecDocument {
    content: BTreeMap<String, String>,
    form: BTreeMap<String, BTreeMap<String, String>>,
    list_items: BTreeMap<String, Vec<String>>,
    list_seq: BTreeMap<String, i64>,
}

impl SpecDocument {
    /// Returns an empty document.
    pub fn new() -> SpecDocument {
        SpecDocument::default()
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
            out.lists.insert(
                k.clone(),
                ListJson {
                    seq,
                    items: items.clone(),
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
            }
        }
    }
}

fn is_under(key: &str, prefix: &str) -> bool {
    key == prefix
        || key.starts_with(&format!("{}/", prefix))
        || key.starts_with(&format!("{}-", prefix))
}
