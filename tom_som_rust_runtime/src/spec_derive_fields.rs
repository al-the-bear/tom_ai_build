//! `spec_derive_fields` — [`derive_fields`]: the derived places of one
//! document, written (`tom_specs_model_rules.md` §9.7). A port of
//! `tom_som_dart_runtime/lib/src/spec_derive_fields.dart` (and the
//! TypeScript, JavaScript, Python, Go and Java `spec_derive_fields` modules);
//! it applies the [`SpecLinkFix`] entries [`SpecLinkValidator`] collects, in
//! their recorded write order.
//!
//! The reference runtimes share one document between the checker and the
//! writes; here the checker reads a copy of the document taken before each
//! write that reads it back ([`SpecLinkValidator::rebind`]), carrying the
//! caches the run collected, so it reads what they read.

use std::collections::{BTreeMap, HashSet};

use crate::json::Json;
use crate::spec_document::SpecDocument;
use crate::spec_document_set::{set_jobj, set_jstr, spec_validation_errors_json};
use crate::spec_links_validator::{
    put_ordered, spec_link_ids, tail_from, SpecLinkFix, SpecLinkValidator, SPEC_LINK_FIX_ADD_ROW,
    SPEC_LINK_FIX_APPEND, SPEC_LINK_FIX_COPY, SPEC_LINK_FIX_LIST, SPEC_LINK_FIX_REMOVE_ROW,
    SPEC_LINK_FIX_SET,
};
use crate::spec_model::SpecModel;
use crate::spec_review_annotations::{
    apply_inline_marks_text, mark_change_text, SpecReviewAnnotations, K_SPEC_HEADLINE_FIELD,
};
use crate::spec_validator::{
    spec_derived_numbers, SpecValidationError, SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS,
    SPEC_VALIDATION_CODE_UNMARKABLE,
};

/// The kind of a [`SpecDeriveChange`].
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecDeriveChangeKind {
    /// A value written.
    Value,
    /// A row added.
    RowAdded,
    /// A row removed (under review: every value of it proposed for deletion).
    RowRemoved,
}

impl SpecDeriveChangeKind {
    /// The kind's name as the corpus writes it (`value`, `rowAdded`,
    /// `rowRemoved`).
    pub fn name(self) -> &'static str {
        match self {
            SpecDeriveChangeKind::Value => "value",
            SpecDeriveChangeKind::RowAdded => "rowAdded",
            SpecDeriveChangeKind::RowRemoved => "rowRemoved",
        }
    }
}

/// One place [`derive_fields`] wrote.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecDeriveChange {
    /// The step that wrote it: 1 (link ends and rows), 2 (derived values,
    /// repeats, `@SameAs` copies), 3 (counts, products, ranks).
    pub step: i64,
    /// What was written.
    pub kind: SpecDeriveChangeKind,
    /// The value's path, or the row's.
    pub path: String,
    /// The form field ([`K_SPEC_HEADLINE_FIELD`] for a headline), `""` for
    /// content and rows.
    pub field: String,
    /// The value before (for a row, empty).
    pub old_value: String,
    /// The value after (for a row, empty).
    pub new_value: String,
}

impl SpecDeriveChange {
    fn row(step: i64, kind: SpecDeriveChangeKind, path: &str) -> SpecDeriveChange {
        SpecDeriveChange {
            step,
            kind,
            path: path.to_string(),
            field: String::new(),
            old_value: String::new(),
            new_value: String::new(),
        }
    }

    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        let mut out = vec![
            ("step", Json::Int(self.step)),
            ("kind", set_jstr(self.kind.name())),
            ("path", set_jstr(&self.path)),
            ("old", set_jstr(&self.old_value)),
            ("new", set_jstr(&self.new_value)),
        ];
        if !self.field.is_empty() {
            out.push(("field", set_jstr(&self.field)));
        }
        set_jobj(out)
    }
}

/// What [`derive_fields`] did.
#[derive(Debug, Clone)]
pub struct SpecDeriveResult {
    /// The copy written on a dry run; `None` when the given document was
    /// written in place.
    pub document: Option<SpecDocument>,
    /// Every place written, in the order written.
    pub changes: Vec<SpecDeriveChange>,
    /// What it could not write, with the code: `unmarkable` (a change it
    /// cannot mark exactly in a document under review, left as it was),
    /// `derivedLookupMiss` (a lookup without exactly one row).
    pub unresolved: Vec<SpecValidationError>,
}

impl SpecDeriveResult {
    /// The document written: the copy of a dry run, else `given` (the
    /// document [`derive_fields`] wrote in place).
    pub fn written<'r>(&'r self, given: &'r SpecDocument) -> &'r SpecDocument {
        self.document.as_ref().unwrap_or(given)
    }

    /// The canonical JSON form, the document written as its stores
    /// (`given`: the document [`derive_fields`] was called with).
    pub fn to_json(&self, given: &SpecDocument) -> Json {
        set_jobj(vec![
            (
                "changes",
                Json::Array(self.changes.iter().map(SpecDeriveChange::to_json).collect()),
            ),
            ("unresolved", spec_validation_errors_json(&self.unresolved)),
            ("document", self.written(given).to_json().to_json()),
        ])
    }
}

/// The options of [`derive_fields`].
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecDeriveOptions {
    /// Writes every change as inline marks (SOM §11.9.3), for a document under
    /// review, and reads values as proposed (pending marks accepted); false
    /// writes plain values. The reference runtimes default it to true.
    pub marked: bool,
    /// The review member the marks are attributed to, `""` for none.
    pub author: String,
    /// The change time the marks record, `""` for now.
    pub at: String,
    /// Works on a copy of the document.
    pub dry_run: bool,
}

/// Recomputes the derived places of `doc` (`tom_specs_model_rules.md` §9.7)
/// in three steps, each reading the result of the one before:
///
/// 1. the missing `inverseOf` ends inside the document, the missing
///    `@ExtractsLinks` rows in `generate` mode, and the stale generated rows
///    removed (a link row left with no value at all goes too);
/// 2. `@DerivedFrom` values and lists, `@SummaryOf` `repeats`, and every
///    `@SameAs` copy from its holder;
/// 3. `countOf`, `productOf` and `rankOf`.
///
/// With `options.marked` (a document under review) every change is written as
/// inline marks attributed to `options.author` at `options.at`, and values are
/// read as proposed (pending marks accepted); without it values are written
/// plain. A change it cannot mark exactly is left as it was and listed as
/// `unmarkable`. It never writes another document. A second run right after
/// the first writes nothing. `options.dry_run` works on a copy (the result's
/// `document`) and leaves `doc` alone.
pub fn derive_fields(
    model: &SpecModel,
    doc: &mut SpecDocument,
    options: &SpecDeriveOptions,
) -> SpecDeriveResult {
    if options.dry_run {
        return derive_fields_dry_run(model, doc, options);
    }
    let mut d = Deriver::new(model, options);
    d.run(doc);
    SpecDeriveResult {
        document: None,
        changes: d.changes,
        unresolved: d.unresolved,
    }
}

/// [`derive_fields`] on a copy of `doc`, whatever `options.dry_run` says: the
/// copy is the result's `document`.
pub fn derive_fields_dry_run(
    model: &SpecModel,
    doc: &SpecDocument,
    options: &SpecDeriveOptions,
) -> SpecDeriveResult {
    let mut target = SpecDocument::new();
    target.load_json(&doc.to_json());
    let mut d = Deriver::new(model, options);
    d.run(&mut target);
    SpecDeriveResult {
        document: Some(target),
        changes: d.changes,
        unresolved: d.unresolved,
    }
}

struct Deriver<'m> {
    model: &'m SpecModel,
    marked: bool,
    author: String,
    at: String,
    changes: Vec<SpecDeriveChange>,
    unresolved: Vec<SpecValidationError>,
    unresolved_keys: HashSet<String>,
}

impl<'m> Deriver<'m> {
    fn new(model: &'m SpecModel, options: &SpecDeriveOptions) -> Deriver<'m> {
        Deriver {
            model,
            marked: options.marked,
            author: options.author.clone(),
            at: options.at.clone(),
            changes: Vec::new(),
            unresolved: Vec::new(),
            unresolved_keys: HashSet::new(),
        }
    }

    fn run(&mut self, doc: &mut SpecDocument) {
        // Step 1: link ends and rows. Removals first, so a row removed and a
        // row added for the same id do not cancel out.
        let snap = doc.clone();
        let mut v = SpecLinkValidator::new(self.model, &snap, self.marked);
        v.run();
        let step1: Vec<SpecLinkFix> = v.fixes.iter().filter(|f| f.step == 1).cloned().collect();
        for f in &step1 {
            if f.kind == SPEC_LINK_FIX_REMOVE_ROW {
                self.remove_row(doc, 1, &f.path, f.empty);
            }
        }
        for f in &step1 {
            if f.kind != SPEC_LINK_FIX_REMOVE_ROW {
                self.apply(doc, f, &mut v);
            }
        }

        // Step 2: derived values and lists, then (reading them) the repeats
        // and the copies; again until nothing moves, which DERIVE-ACYCLIC
        // bounds.
        let mut last_errors: Vec<SpecValidationError> = v.errors.clone();
        for _ in 0..4 {
            let snap = doc.clone();
            let mut v = SpecLinkValidator::new(self.model, &snap, self.marked);
            v.run();
            let before = self.changes.len();
            let fixes = v.fixes.clone();
            for f in &fixes {
                if f.step == 2 && f.kind != SPEC_LINK_FIX_COPY {
                    self.apply(doc, f, &mut v);
                }
            }
            let snap = doc.clone();
            let mut v = SpecLinkValidator::new(self.model, &snap, self.marked);
            v.run();
            last_errors = v.errors.clone();
            let fixes = v.fixes.clone();
            for f in &fixes {
                if f.kind == SPEC_LINK_FIX_COPY {
                    self.apply(doc, f, &mut v);
                }
            }
            if self.changes.len() == before {
                break;
            }
        }
        for e in last_errors {
            if e.code == SPEC_VALIDATION_CODE_DERIVED_LOOKUP_MISS {
                self.add_unresolved(e);
            }
        }

        // Step 3: counts, products, ranks.
        for n in spec_derived_numbers(self.model, doc, self.marked) {
            self.write(doc, 3, &n.path, &n.field, &n.value);
        }
    }

    fn add_unresolved(&mut self, e: SpecValidationError) {
        let key = format!("{} {} {}", e.code, e.path, e.message);
        if self.unresolved_keys.insert(key) {
            self.unresolved.push(e);
        }
    }

    /// Writes `value` at `path` / `field`: plainly, or marked against the
    /// value there (compared from its original, so a change already proposed
    /// is not proposed again).
    fn write(&mut self, doc: &mut SpecDocument, step: i64, path: &str, field: &str, value: &str) {
        let current = spec_get_value(doc, path, field);
        if !self.marked {
            if current.trim() == value.trim() {
                return;
            }
            spec_set_value(doc, path, field, value);
        } else {
            if apply_inline_marks_text(&current, true).trim() == value.trim() {
                return;
            }
            let original = apply_inline_marks_text(&current, false);
            if !mark_change_text(&original, value).exact {
                let what = if field.is_empty() {
                    "the content".to_string()
                } else {
                    format!("form field \"{}\"", field)
                };
                self.add_unresolved(SpecValidationError {
                    path: path.to_string(),
                    code: SPEC_VALIDATION_CODE_UNMARKABLE.to_string(),
                    message: format!(
                        "{} would become \"{}\", a change that cannot be marked exactly; it is left for the agent",
                        what, value
                    ),
                });
                return;
            }
            let field_opt = if field.is_empty() { None } else { Some(field) };
            let author = if self.author.is_empty() {
                None
            } else {
                Some(self.author.as_str())
            };
            let at = if self.at.is_empty() {
                None
            } else {
                Some(self.at.as_str())
            };
            SpecReviewAnnotations::new(doc)
                .set_marked(path, field_opt, value, author, at)
                .unwrap_or_else(|e| panic!("{}", e));
        }
        let now = spec_get_value(doc, path, field);
        if now != current {
            self.changes.push(SpecDeriveChange {
                step,
                kind: SpecDeriveChangeKind::Value,
                path: path.to_string(),
                field: field.to_string(),
                old_value: current,
                new_value: now,
            });
        }
    }

    fn add_row(
        &mut self,
        doc: &mut SpecDocument,
        step: i64,
        lst: &str,
        keys: &[String],
        values: &BTreeMap<String, String>,
    ) {
        let item = doc.add_list_item(lst);
        self.changes.push(SpecDeriveChange::row(
            step,
            SpecDeriveChangeKind::RowAdded,
            &item,
        ));
        for k in keys {
            let (rel, field) = match k.find('#') {
                Some(h) => (&k[..h], &k[h + 1..]),
                None => (k.as_str(), ""),
            };
            let value = values.get(k).cloned().unwrap_or_default();
            self.write(doc, step, &format!("{}/{}", item, rel), field, &value);
        }
    }

    fn remove_row(&mut self, doc: &mut SpecDocument, step: i64, row: &str, empty: bool) {
        if !self.marked || empty {
            if !doc.remove_list_item(row) {
                return;
            }
            self.changes.push(SpecDeriveChange::row(
                step,
                SpecDeriveChangeKind::RowRemoved,
                row,
            ));
            return;
        }
        // Under review: every value of the row is proposed for deletion; once
        // accepted, the empty row goes with the next run.
        let before = self.changes.len();
        let prefix = format!("{}/", row);
        let under = |p: &str| p == row || p.starts_with(&prefix);
        for p in doc.content_paths() {
            if under(&p) {
                self.write(doc, step, &p, "", "");
            }
        }
        for p in doc.form_paths() {
            if !under(&p) {
                continue;
            }
            for f in doc.form_field_names(&p) {
                self.write(doc, step, &p, &f, "");
            }
        }
        if self.changes.len() > before {
            self.changes.insert(
                before,
                SpecDeriveChange::row(step, SpecDeriveChangeKind::RowRemoved, row),
            );
        }
    }

    fn apply(&mut self, doc: &mut SpecDocument, f: &SpecLinkFix, v: &mut SpecLinkValidator<'_>) {
        match f.kind.as_str() {
            SPEC_LINK_FIX_SET => self.write(doc, f.step, &f.path, &f.field, &f.value),
            SPEC_LINK_FIX_APPEND => {
                let live = doc.clone();
                let mut lv = v.rebind(&live);
                let mut ids = spec_link_ids(&lv.form_value(&f.path, &f.field));
                v.adopt(&lv);
                if ids.contains(&f.value) {
                    return;
                }
                ids.push(f.value.clone());
                self.write(doc, f.step, &f.path, &f.field, &ids.join(", "));
            }
            SPEC_LINK_FIX_ADD_ROW => {
                let keys = f.ordered_value_keys();
                self.add_row(doc, f.step, &f.path, &keys, &f.values);
            }
            SPEC_LINK_FIX_REMOVE_ROW => self.remove_row(doc, f.step, &f.path, f.empty),
            SPEC_LINK_FIX_LIST => self.apply_list(doc, f, v),
            SPEC_LINK_FIX_COPY => self.apply_copy(doc, &f.path, &f.holder, v),
            _ => {}
        }
    }

    /// Makes the list hold one element per wanted tuple: elements matching no
    /// tuple removed, tuples matching no element added.
    fn apply_list(
        &mut self,
        doc: &mut SpecDocument,
        f: &SpecLinkFix,
        v: &mut SpecLinkValidator<'_>,
    ) {
        let places = f.ordered_tuple_keys();
        let key = |t: &BTreeMap<String, String>| {
            places
                .iter()
                .map(|p| t.get(p).map_or("", String::as_str))
                .collect::<Vec<&str>>()
                .join(" | ")
        };
        let mut wanted: Vec<String> = f.tuples.iter().map(&key).collect();
        let mut keep: Vec<String> = Vec::new();
        fn remove_first(list: &mut Vec<String>, k: &str) -> bool {
            match list.iter().position(|x| x == k) {
                Some(i) => {
                    list.remove(i);
                    true
                }
                None => false,
            }
        }
        let probe = format!("{}-0", f.path);
        let elements = doc.list_items(&f.path);
        let (element_keys, rels) = {
            let live = doc.clone();
            let mut lv = v.rebind(&live);
            let element_keys: Vec<String> = elements
                .iter()
                .map(|el| {
                    let t: BTreeMap<String, String> = places
                        .iter()
                        .map(|p| (p.clone(), lv.place_value(p, el)))
                        .collect();
                    key(&t)
                })
                .collect();
            let rels: Vec<Option<String>> = places
                .iter()
                .map(|p| {
                    lv.at(p, &probe).map(|r| {
                        let rel = tail_from(&r.path, probe.len() + 1).to_string();
                        if r.field().is_empty() {
                            rel
                        } else {
                            format!("{}#{}", rel, r.field())
                        }
                    })
                })
                .collect();
            v.adopt(&lv);
            (element_keys, rels)
        };
        for (el, k) in elements.iter().zip(element_keys) {
            if remove_first(&mut wanted, &k) {
                keep.push(k);
            } else {
                self.remove_row(doc, 2, el, false);
            }
        }
        for t in &f.tuples {
            let k = key(t);
            if remove_first(&mut keep, &k) {
                continue;
            }
            let mut values: BTreeMap<String, String> = BTreeMap::new();
            let mut keys: Vec<String> = Vec::new();
            for (p, rel) in places.iter().zip(&rels) {
                if let Some(rel) = rel {
                    put_ordered(
                        &mut values,
                        &mut keys,
                        rel.clone(),
                        t.get(p).cloned().unwrap_or_default(),
                    );
                }
            }
            self.add_row(doc, 2, &f.path, &keys, &values);
        }
    }

    /// Writes the copy at `copy_path` from its holder: every value and element
    /// the holder has, in the copy, and nothing else.
    fn apply_copy(
        &mut self,
        doc: &mut SpecDocument,
        copy_path: &str,
        holder: &str,
        v: &mut SpecLinkValidator<'_>,
    ) {
        let live = doc.clone();
        let mut lv = v.rebind(&live);
        let theirs = lv.subtree(holder);
        let mine = lv.subtree(copy_path);
        let mut item_ids = lv.item_ids.clone();
        v.adopt(&lv);
        drop(lv);
        // The effective id of an item; the items the copy adds are recorded.
        let refl = crate::spec_reflection::SpecReflection::new(self.model);
        let item_id = |doc: &SpecDocument,
                       item: &str,
                       ids: &mut std::collections::HashMap<String, String>| {
            if let Some(id) = ids.get(item) {
                return id.clone();
            }
            let id = crate::spec_document_set::set_effective_item_id(&refl, doc, item);
            ids.insert(item.to_string(), id.clone());
            id
        };

        // The path `rel` stands for in the copy; `create` adds the elements it
        // names that are missing.
        let path_in = |this: &mut Self,
                       doc: &mut SpecDocument,
                       rel: &str,
                       create: bool,
                       ids: &mut std::collections::HashMap<String, String>|
         -> Option<String> {
            let mut cur = copy_path.to_string();
            if rel.is_empty() {
                return Some(cur);
            }
            for seg in rel.split('/') {
                let bracket = match seg.find('[') {
                    Some(b) => b,
                    None => {
                        cur = format!("{}/{}", cur, seg);
                        continue;
                    }
                };
                let lst = format!("{}/{}", cur, &seg[..bracket]);
                let id = &seg[bracket + 1..seg.len() - 1];
                let found = doc
                    .list_items(&lst)
                    .into_iter()
                    .find(|i| item_id(doc, i, ids) == id);
                match found {
                    Some(i) => cur = i,
                    None if !create => return None,
                    None => {
                        cur = spec_add_item(doc, &lst, Some(id));
                        ids.insert(cur.clone(), id.to_string());
                        this.changes.push(SpecDeriveChange::row(
                            2,
                            SpecDeriveChangeKind::RowAdded,
                            &cur,
                        ));
                    }
                }
            }
            Some(cur)
        };

        let split = |key: &str| -> Option<(String, String)> {
            let body = &key[2..];
            match key.as_bytes()[0] {
                b'f' => {
                    let hash = body.find('#')?;
                    Some((body[..hash].to_string(), body[hash + 1..].to_string()))
                }
                b'c' => Some((body.to_string(), String::new())),
                b'h' => Some((body.to_string(), K_SPEC_HEADLINE_FIELD.to_string())),
                _ => None,
            }
        };

        // Elements the holder lacks go first, and nothing beneath them is
        // written.
        let mut gone: Vec<String> = Vec::new();
        for (k, m) in &mine {
            if !k.starts_with("i:") || theirs.contains_key(k) {
                continue;
            }
            let rel = &k[2..];
            if gone.iter().any(|g| rel.starts_with(&format!("{}/", g))) {
                continue;
            }
            gone.push(rel.to_string());
            self.remove_row(doc, 2, &m.path, false);
        }
        let beneath_gone = |rel: &str| {
            gone.iter()
                .any(|g| rel == g || rel.starts_with(&format!("{}/", g)))
        };

        for (k, t) in &theirs {
            if let Some(rel) = k.strip_prefix("i:") {
                path_in(self, doc, rel, true, &mut item_ids);
                continue;
            }
            let (rel, field) = match split(k) {
                Some(x) => x,
                None => continue,
            };
            if let Some(path) = path_in(self, doc, &rel, true, &mut item_ids) {
                self.write(doc, 2, &path, &field, &t.value);
            }
        }
        for k in mine.keys() {
            if theirs.contains_key(k) || k.starts_with("i:") {
                continue;
            }
            let (rel, field) = match split(k) {
                Some(x) => x,
                None => continue,
            };
            if beneath_gone(&rel) {
                continue;
            }
            if let Some(path) = path_in(self, doc, &rel, false, &mut item_ids) {
                self.write(doc, 2, &path, &field, "");
            }
        }
        v.item_ids = item_ids;
    }
}

// --- the writes ---------------------------------------------------------------

/// The value at `path` / `field` of `doc` (`""` content,
/// [`K_SPEC_HEADLINE_FIELD`] a headline), `""` when unset.
pub(crate) fn spec_get_value(doc: &SpecDocument, path: &str, field: &str) -> String {
    match field {
        K_SPEC_HEADLINE_FIELD => doc.headline_or(path),
        "" => doc.content_or(path),
        _ => doc.form_field_or(path, field),
    }
}

/// Writes `value` at `path` / `field` of `doc` (`""` clears it).
pub(crate) fn spec_set_value(doc: &mut SpecDocument, path: &str, field: &str, value: &str) {
    match field {
        K_SPEC_HEADLINE_FIELD => doc.set_headline(path, value),
        "" => doc.set_content(path, value),
        _ => doc.set_form_field(path, field, value),
    }
}

/// Appends an item to `lst`, with the section id `id` unless it is `None`; a
/// colliding id panics (the reference runtimes raise).
pub(crate) fn spec_add_item(doc: &mut SpecDocument, lst: &str, id: Option<&str>) -> String {
    match id {
        None => doc.add_list_item(lst),
        Some(id) => doc
            .add_list_item_with_section_id(lst, id)
            .unwrap_or_else(|e| panic!("{:?}", e)),
    }
}
