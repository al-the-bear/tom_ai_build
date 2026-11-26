//! `spec_backfill` — [`backfill`]: the accepted end state of the Phase 3
//! documents, carried into the Blueprint (DP-part-operations-2). A port of
//! `tom_som_dart_runtime/lib/src/spec_backfill.dart` (a `part of`
//! `spec_document_set.dart` there; and the TypeScript, JavaScript, Python, Go
//! and Java `spec_backfill` modules); it reads the comparison internals of
//! [`SpecSetCheck`].

use std::collections::{HashMap, HashSet};

use crate::json::Json;
use crate::spec_derive_fields::{
    derive_fields, spec_add_item, spec_get_value, spec_set_value, SpecDeriveOptions,
};
use crate::spec_document::{DocumentJson, ListJson, SpecDocument};
use crate::spec_document_set::{
    pair_scope, set_effective_item_id, set_jobj, set_jstr, SpecDocumentSet, SpecSetCheck,
    SpecSetFound, SpecSyncCode, SpecSyncFinding, SpecSyncHolder, SpecSyncPlace, SpecSyncResolution,
};
use crate::spec_model::SPEC_FIELD_KIND_LIST;
use crate::spec_place::spec_section_positions;
use crate::spec_review_annotations::spec_review_annotation_list;

/// Why [`backfill`] refuses a set.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecBackfillErrorCode {
    /// A document holds an inline mark or an annotation block.
    SetHasMarks,
    /// The set has no Blueprint.
    NoBlueprint,
}

impl SpecBackfillErrorCode {
    /// The code's name as the corpus writes it (`setHasMarks`,
    /// `noBlueprint`).
    pub fn name(self) -> &'static str {
        match self {
            SpecBackfillErrorCode::SetHasMarks => "setHasMarks",
            SpecBackfillErrorCode::NoBlueprint => "noBlueprint",
        }
    }
}

/// The kind of a [`SpecBackfillChange`].
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecBackfillChangeKind {
    /// A value written or cleared.
    Value,
    /// An element added.
    ElementAdded,
    /// An element removed.
    ElementRemoved,
    /// The history entry.
    Revision,
    /// A derived place rewritten.
    Derived,
}

impl SpecBackfillChangeKind {
    /// The kind's name as the corpus writes it.
    pub fn name(self) -> &'static str {
        match self {
            SpecBackfillChangeKind::Value => "value",
            SpecBackfillChangeKind::ElementAdded => "elementAdded",
            SpecBackfillChangeKind::ElementRemoved => "elementRemoved",
            SpecBackfillChangeKind::Revision => "revision",
            SpecBackfillChangeKind::Derived => "derived",
        }
    }
}

/// Why [`backfill`] left a finding.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecBackfillLeftReason {
    /// The Blueprint holds the value: the agent corrects the Phase 3
    /// document.
    HeldHere,
    /// Under `subset`, not carried in.
    MayBeAdded,
    /// The finding's own resolution (`agent`, `info`).
    Resolution(SpecSyncResolution),
}

impl SpecBackfillLeftReason {
    /// The reason's name as the corpus writes it (`heldHere`, `mayBeAdded`,
    /// or the resolution's name).
    pub fn name(self) -> &'static str {
        match self {
            SpecBackfillLeftReason::HeldHere => "heldHere",
            SpecBackfillLeftReason::MayBeAdded => "mayBeAdded",
            SpecBackfillLeftReason::Resolution(r) => r.name(),
        }
    }
}

/// Why [`backfill`] refuses a set.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecBackfillError {
    /// Why.
    pub code: SpecBackfillErrorCode,
    /// The places holding marks, in document order.
    pub places: Vec<SpecSyncPlace>,
    /// The prose for the reader.
    pub message: String,
}

impl SpecBackfillError {
    /// The canonical JSON form (no message).
    pub fn to_json(&self) -> Json {
        set_jobj(vec![
            ("code", set_jstr(self.code.name())),
            (
                "places",
                Json::Array(self.places.iter().map(SpecSyncPlace::to_json).collect()),
            ),
        ])
    }
}

impl std::fmt::Display for SpecBackfillError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "SpecBackfillError({}): {}",
            self.code.name(),
            self.message
        )
    }
}

impl std::error::Error for SpecBackfillError {}

/// One place [`backfill`] wrote in the Blueprint.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecBackfillChange {
    /// The pair the change belongs to; empty for the revision entry and the
    /// derived places written after it.
    pub pair: String,
    /// What was written.
    pub kind: SpecBackfillChangeKind,
    /// The value's path, or the element's.
    pub path: String,
    /// The form field (`K_SPEC_HEADLINE_FIELD` for a headline), `""` for
    /// content and elements.
    pub field: String,
    /// The value before (for an element, its id before).
    pub old_value: String,
    /// The value after (for an element, its id after).
    pub new_value: String,
}

impl SpecBackfillChange {
    fn new(pair: &str, kind: SpecBackfillChangeKind, path: &str) -> SpecBackfillChange {
        SpecBackfillChange {
            pair: pair.to_string(),
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
            ("pair", set_jstr(&self.pair)),
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

/// A finding [`backfill`] left, with the reason.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecBackfillLeft {
    /// The finding.
    pub finding: SpecSyncFinding,
    /// Why it was left.
    pub reason: SpecBackfillLeftReason,
}

impl SpecBackfillLeft {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        set_jobj(vec![
            ("finding", self.finding.to_json()),
            ("reason", set_jstr(self.reason.name())),
        ])
    }
}

/// What [`backfill`] did.
#[derive(Debug, Clone)]
pub struct SpecBackfillResult {
    /// The Blueprint written: the set's own (as the set now holds it), or the
    /// copy a dry run wrote.
    pub blueprint: SpecDocument,
    /// Every place written, in the order written.
    pub changes: Vec<SpecBackfillChange>,
    /// Every finding in scope it did not resolve, with the reason.
    pub left: Vec<SpecBackfillLeft>,
}

impl SpecBackfillResult {
    /// The canonical JSON form (the Blueprint as its stores).
    pub fn to_json(&self) -> Json {
        set_jobj(vec![
            (
                "changes",
                Json::Array(
                    self.changes
                        .iter()
                        .map(SpecBackfillChange::to_json)
                        .collect(),
                ),
            ),
            (
                "left",
                Json::Array(self.left.iter().map(SpecBackfillLeft::to_json).collect()),
            ),
            ("blueprint", self.blueprint.to_json().to_json()),
        ])
    }
}

/// The options of [`backfill`].
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecBackfillOptions {
    /// `Some`: keeps those pairs (by section id) only.
    pub pairs: Option<Vec<String>>,
    /// Non-empty: keeps the findings at or below this Blueprint path.
    pub path: String,
    /// Writes a copy of the Blueprint; the set's own is left alone.
    pub dry_run: bool,
    /// The revision entry's author, `""` for `backfill`.
    pub author: String,
    /// The revision entry's date, `""` for today (UTC).
    pub date: String,
}

/// Carries the end state of the Phase 3 documents into the Blueprint, as
/// plain values (DP-part-operations-2): for every shared place whose holder is
/// the Phase 3 document, the holder's value — a differing or missing value
/// written, a value the Phase 3 document emptied cleared, an element only in
/// the Phase 3 document added (with its stored section id, after its nearest
/// preceding neighbour the Blueprint holds, or first), an element only in the
/// Blueprint removed (DP-part-operations-3).
///
/// It leaves `detailOnly` places, a `heldHere` place the documents disagree
/// on, an element that under `subset` may be added, and every finding across
/// two documents: each is listed in [`SpecBackfillResult::left`] with the
/// reason.
///
/// It refuses a set holding any inline mark or annotation block
/// ([`SpecBackfillError`], `setHasMarks`, the places named). It writes only
/// the Blueprint; when it changed anything it adds one entry to the
/// Blueprint's revision history (the `RVENT` list) naming the pairs, and
/// rewrites the Blueprint's derived places (`derive_fields`, plain). A second
/// run right after the first writes nothing.
pub fn backfill(
    set: &mut SpecDocumentSet<'_>,
    options: &SpecBackfillOptions,
) -> Result<SpecBackfillResult, SpecBackfillError> {
    let scope = pair_scope(options.pairs.as_deref());
    let bp_name = set.name_of(&set.blueprint_root).ok_or(SpecBackfillError {
        code: SpecBackfillErrorCode::NoBlueprint,
        places: Vec::new(),
        message: "the set holds no Blueprint".to_string(),
    })?;
    let refl = set.refl();

    // No review in progress.
    let mut marked: Vec<SpecSyncPlace> = Vec::new();
    for name in set.names() {
        let doc = match set.get(&name) {
            Some(d) => d,
            None => continue,
        };
        let root_type = set.root_of(&name);
        let root = refl
            .model
            .roots
            .iter()
            .find(|r| r.type_ == root_type)
            .map(|r| refl.root_segment(r))
            .unwrap_or_default();
        let mut seen: HashSet<String> = HashSet::new();
        for a in spec_review_annotation_list(doc) {
            let field = a.field.clone().unwrap_or_default();
            if !seen.insert(format!("{}#{}", a.path, field)) {
                continue;
            }
            marked.push(SpecSyncPlace {
                document: Some(name.clone()),
                root: root.clone(),
                path: a.path.clone(),
                field,
                value: None,
                pending_marks: false,
            });
        }
    }
    if !marked.is_empty() {
        return Err(SpecBackfillError {
            code: SpecBackfillErrorCode::SetHasMarks,
            message: format!(
                "the set holds {} value(s) with inline marks or annotation blocks; backfill carries the end state of an accepted review, so decide them first",
                marked.len()
            ),
            places: marked,
        });
    }

    let mut target = SpecDocument::new();
    target.load_json(
        &set.get(&bp_name)
            .map(SpecDocument::to_json)
            .unwrap_or_default(),
    );
    let changes;
    let mut left = Vec::new();
    {
        let mut c = SpecSetCheck::new(set);
        let mut index = 0;
        for p in set.pairs() {
            if scope.as_ref().is_none_or(|s| s.contains(&p.section_id)) {
                c.compare_pair(p, index);
            }
            index += 1;
        }
        // The links across two documents are the agent's; they are listed as
        // left.
        c.cross_checks(scope.as_ref(), index);
        c.out.sort_by(|a, b| {
            a.order
                .cmp(&b.order)
                .then_with(|| a.key.cmp(&b.key))
                .then_with(|| a.finding.code.index().cmp(&b.finding.code.index()))
        });

        let in_scope = |f: &SpecSyncFinding| {
            options.path.is_empty()
                || f.blueprint.path == options.path
                || f.blueprint.path.starts_with(&format!("{}/", options.path))
        };

        let mut w = Backfiller {
            set,
            doc: &mut target,
            name: bp_name.clone(),
            changes: Vec::new(),
            pairs: HashSet::new(),
        };
        let mut apply: Vec<&SpecSetFound> = Vec::new();
        for o in &c.out {
            let f = &o.finding;
            if !in_scope(f) {
                continue;
            }
            if f.resolution == SpecSyncResolution::Backfill {
                apply.push(o);
                continue;
            }
            let reason = if f.holder == SpecSyncHolder::Blueprint {
                SpecBackfillLeftReason::HeldHere
            } else if f.code == SpecSyncCode::SharedElementMayBeAdded {
                SpecBackfillLeftReason::MayBeAdded
            } else {
                SpecBackfillLeftReason::Resolution(f.resolution)
            };
            left.push(SpecBackfillLeft {
                finding: f.clone(),
                reason,
            });
        }
        w.apply(&apply);
        if !w.changes.is_empty() {
            let author = if options.author.is_empty() {
                "backfill".to_string()
            } else {
                options.author.clone()
            };
            let date = if options.date.is_empty() {
                spec_today()
            } else {
                options.date.clone()
            };
            w.revision_entry(&author, &date);
            let derived = derive_fields(set.model, w.doc, &SpecDeriveOptions::default());
            for d in derived.changes {
                w.changes.push(SpecBackfillChange {
                    pair: String::new(),
                    kind: SpecBackfillChangeKind::Derived,
                    path: d.path,
                    field: d.field,
                    old_value: d.old_value,
                    new_value: d.new_value,
                });
            }
        }
        changes = w.changes;
    }
    if !options.dry_run {
        set.replace(&bp_name, target.clone());
    }
    Ok(SpecBackfillResult {
        blueprint: target,
        changes,
        left,
    })
}

/// Today's date (UTC) as `YYYY-MM-DD`.
fn spec_today() -> String {
    let secs = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
    let (y, m, d) = crate::spec_section_id::civil_from_days(secs.div_euclid(86_400));
    format!("{:04}-{:02}-{:02}", y, m, d)
}

struct Backfiller<'w, 'm> {
    set: &'w SpecDocumentSet<'m>,
    doc: &'w mut SpecDocument,
    name: String,
    changes: Vec<SpecBackfillChange>,
    pairs: HashSet<String>,
}

/// The ids to add to and drop from one reference field.
struct BackfillIds {
    pair: String,
    add: Vec<String>,
    drop: Vec<String>,
}

fn backfill_rel(key: &str) -> &str {
    let body = &key[2..];
    match body.find('#') {
        Some(h) => &body[..h],
        None => body,
    }
}

fn list_of_item(item: &str) -> &str {
    &item[..item.rfind('-').unwrap_or(item.len())]
}

impl Backfiller<'_, '_> {
    fn write(&mut self, pair: &str, path: &str, field: &str, value: &str) {
        let old = spec_get_value(self.doc, path, field);
        if old.trim() == value.trim() {
            return;
        }
        spec_set_value(self.doc, path, field, value);
        self.pairs.insert(pair.to_string());
        self.changes.push(SpecBackfillChange {
            pair: pair.to_string(),
            kind: SpecBackfillChangeKind::Value,
            path: path.to_string(),
            field: field.to_string(),
            old_value: old,
            new_value: value.to_string(),
        });
    }

    fn id_of(&self, item: &str) -> String {
        set_effective_item_id(&self.set.refl(), self.doc, item)
    }

    fn apply(&mut self, found: &[&SpecSetFound]) {
        // 1. Elements only in the Blueprint go, first.
        for o in found {
            if o.finding.code != SpecSyncCode::SharedElementOnlyInBlueprint
                || !o.key.starts_with("i:")
            {
                continue;
            }
            let item = match o.b.as_ref().and_then(|b| b.items.get(&o.key[2..])) {
                Some(i) => i.clone(),
                None => continue,
            };
            if !self.doc.remove_list_item(&item) {
                continue;
            }
            self.pairs.insert(o.finding.pair.clone());
            let mut ch = SpecBackfillChange::new(
                &o.finding.pair,
                SpecBackfillChangeKind::ElementRemoved,
                &item,
            );
            ch.old_value = o.finding.blueprint.value_or().to_string();
            self.changes.push(ch);
        }

        // 2. Values, and the ids of reference fields.
        let mut ids: HashMap<String, BackfillIds> = HashMap::new();
        let mut id_keys: Vec<String> = Vec::new();
        for o in found {
            let f = &o.finding;
            if o.key.starts_with("i:") {
                continue;
            }
            let field = f.blueprint.field.clone();
            match f.code {
                SpecSyncCode::SharedValueDiffers | SpecSyncCode::SharedValueMissing => {
                    let value =
                        o.d.as_ref()
                            .and_then(|d| d.values.get(&o.key))
                            .map(|v| v.value.clone())
                            .unwrap_or_default();
                    self.write(&f.pair, &f.blueprint.path, &field, &value);
                }
                SpecSyncCode::SharedValueOnlyInBlueprint => {
                    self.write(&f.pair, &f.blueprint.path, &field, "");
                }
                SpecSyncCode::SharedElementMissing | SpecSyncCode::SharedElementOnlyInBlueprint => {
                    let key = format!("{}#{}", f.blueprint.path, field);
                    if !ids.contains_key(&key) {
                        id_keys.push(key.clone());
                    }
                    let e = ids.entry(key).or_insert_with(|| BackfillIds {
                        pair: f.pair.clone(),
                        add: Vec::new(),
                        drop: Vec::new(),
                    });
                    let (list, x) = if f.code == SpecSyncCode::SharedElementMissing {
                        (&mut e.add, f.detail.value_or())
                    } else {
                        (&mut e.drop, f.blueprint.value_or())
                    };
                    if !list.iter().any(|y| y == x) {
                        list.push(x.to_string());
                    }
                }
                _ => {}
            }
        }
        for key in &id_keys {
            let e = &ids[key];
            let hash = key.rfind('#').unwrap_or(key.len());
            let (p, field) = (&key[..hash], &key[hash + 1..]);
            let mut now: Vec<String> = Vec::new();
            for s in spec_get_value(self.doc, p, field).split(',') {
                let t = s.trim();
                if !t.is_empty() && !e.drop.iter().any(|d| d == t) {
                    now.push(t.to_string());
                }
            }
            for x in &e.add {
                if !now.contains(x) {
                    now.push(x.clone());
                }
            }
            let pair = e.pair.clone();
            self.write(&pair, p, field, &now.join(", "));
        }

        // 3. Elements only in the Phase 3 document come in, each with every
        // value the pair shares beneath it, then take their place.
        let mut additions: Vec<(String, String, Vec<String>)> = Vec::new(); // list, id, order
        for o in found {
            if o.finding.code != SpecSyncCode::SharedElementMissing || !o.key.starts_with("i:") {
                continue;
            }
            let d = match &o.d {
                Some(d) => d,
                None => continue,
            };
            let rel = &o.key[2..];
            let id = &rel[rel.rfind('[').map_or(0, |b| b + 1)..rel.len() - 1];
            let lst = o.finding.blueprint.path.clone();
            let detail_item = d.items.get(rel).cloned().unwrap_or_default();
            let item = spec_add_item(self.doc, &lst, Some(id));
            self.pairs.insert(o.finding.pair.clone());
            let mut ch = SpecBackfillChange::new(
                &o.finding.pair,
                SpecBackfillChangeKind::ElementAdded,
                &item,
            );
            ch.new_value = id.to_string();
            self.changes.push(ch);
            // Nested elements first (shortest key first), then the values.
            let mut mapped: Vec<(String, String)> = vec![(detail_item.clone(), item.clone())];
            let rel_prefix = format!("{}/", rel);
            let mut nested: Vec<&String> = d
                .item_keys
                .iter()
                .filter(|k| k.starts_with(&rel_prefix))
                .collect();
            nested.sort_by_key(|k| k.len());
            let best = |mapped: &[(String, String)], d_path: &str, inclusive: bool| {
                mapped
                    .iter()
                    .filter(|(from, _)| {
                        (inclusive && d_path == from)
                            || (d_path.starts_with(from.as_str())
                                && d_path[from.len()..].starts_with('/'))
                    })
                    .max_by_key(|(from, _)| from.len())
                    .cloned()
            };
            for k in nested {
                let d_path = d.items[k].clone();
                let (parent_from, parent_to) = match best(&mapped, &d_path, false) {
                    Some(x) => x,
                    None => continue,
                };
                let seg = &d_path[parent_from.len() + 1..];
                let nested_id = &k[k.rfind('[').map_or(0, |b| b + 1)..k.len() - 1];
                let new_item = spec_add_item(
                    self.doc,
                    &format!("{}/{}", parent_to, list_of_item(seg)),
                    Some(nested_id),
                );
                mapped.push((d_path, new_item));
            }
            for (k, v) in &d.values {
                let r = backfill_rel(k);
                if r != rel && !r.starts_with(&rel_prefix) {
                    continue;
                }
                let target = match best(&mapped, &v.path, true) {
                    Some((from, to)) => format!("{}{}", to, &v.path[from.len()..]),
                    None => continue,
                };
                if v.value.is_empty() {
                    continue;
                }
                spec_set_value(self.doc, &target, &v.field, &v.value);
            }
            // The detail list's order, by id.
            let refl = self.set.refl();
            let order: Vec<String> = match o
                .finding
                .detail
                .document
                .as_deref()
                .and_then(|n| self.set.get(n))
            {
                Some(detail_doc) => detail_doc
                    .list_items(list_of_item(&detail_item))
                    .iter()
                    .map(|it| set_effective_item_id(&refl, detail_doc, it))
                    .collect(),
                None => Vec::new(),
            };
            additions.push((lst, id.to_string(), order));
        }
        // Each list takes its new elements in one reorder: an element goes
        // after its nearest preceding neighbour (in the Phase 3 order) the
        // Blueprint holds, or first.
        let mut by_list: HashMap<String, Vec<(String, Vec<String>)>> = HashMap::new();
        let mut list_order: Vec<String> = Vec::new();
        for (lst, id, order) in additions {
            if !by_list.contains_key(&lst) {
                list_order.push(lst.clone());
            }
            by_list.entry(lst).or_default().push((id, order));
        }
        let mut orders: HashMap<String, Vec<String>> = HashMap::new();
        for lst in &list_order {
            let entries = &by_list[lst];
            let new_ids: HashSet<&str> = entries.iter().map(|(id, _)| id.as_str()).collect();
            let items = self.doc.list_items(lst);
            let mut order_now: Vec<String> = items
                .iter()
                .filter(|i| !new_ids.contains(self.id_of(i).as_str()))
                .cloned()
                .collect();
            for (id, order) in entries {
                let item = items
                    .iter()
                    .find(|i| self.id_of(i) == *id)
                    .cloned()
                    .unwrap_or_default();
                let before: &[String] = match order.iter().position(|x| x == id) {
                    Some(at) => &order[..at],
                    None if !order.is_empty() => &order[..order.len() - 1],
                    None => &[],
                };
                let mut at = 0;
                for b in before.iter().rev() {
                    if let Some(k) = order_now.iter().position(|x| self.id_of(x) == *b) {
                        at = k + 1;
                        break;
                    }
                }
                order_now.insert(at, item);
            }
            orders.insert(lst.clone(), order_now);
        }
        self.reorder(&list_order, &orders);
        // Each added element is reported at the place it took.
        for i in 0..self.changes.len() {
            if self.changes[i].kind != SpecBackfillChangeKind::ElementAdded {
                continue;
            }
            let path = self.changes[i].path.clone();
            let new_value = self.changes[i].new_value.clone();
            let now_path = self
                .doc
                .list_items(list_of_item(&path))
                .into_iter()
                .find(|x| self.id_of(x) == new_value);
            match now_path {
                Some(p) if p != path => self.changes[i].path = p,
                _ => {}
            }
        }
    }

    /// Puts the items of each list in `orders` in the order given, in one pass
    /// over the document's stores: the lists renumbered `<list>-1 …
    /// <list>-n`, every value beneath an item travelling with it, an
    /// anonymous item whose positional id would change keeping its old id (as
    /// `move_list_item` does). Inner lists go first, so an outer rename
    /// carries their new paths.
    fn reorder(&mut self, list_order: &[String], orders: &HashMap<String, Vec<String>>) {
        if list_order.is_empty() {
            return;
        }
        let mut lists: Vec<String> = list_order.to_vec();
        lists.sort_by_key(|l| std::cmp::Reverse(l.split('/').count()));
        let mut ids: HashMap<String, String> = HashMap::new();
        for lst in &lists {
            for i in self.doc.list_items(lst) {
                let id = self.id_of(&i);
                ids.insert(i, id);
            }
        }
        let mut j: DocumentJson = self.doc.to_json();

        fn rename(key: &str, m: &[(String, String)]) -> String {
            for (from, to) in m {
                if key == from {
                    return to.clone();
                }
                if key.starts_with(from.as_str()) && key[from.len()..].starts_with('/') {
                    return format!("{}{}", to, &key[from.len()..]);
                }
            }
            key.to_string()
        }
        fn rename_store(
            store: &std::collections::BTreeMap<String, String>,
            m: &[(String, String)],
        ) -> std::collections::BTreeMap<String, String> {
            store
                .iter()
                .map(|(k, v)| (rename(k, m), v.clone()))
                .collect()
        }

        let original_doc = self.doc.clone();
        for lst in &lists {
            let order = &orders[lst];
            let m: Vec<(String, String)> = order
                .iter()
                .enumerate()
                .filter_map(|(i, it)| {
                    let to = format!("{}-{}", lst, i + 1);
                    if *it != to {
                        Some((it.clone(), to))
                    } else {
                        None
                    }
                })
                .collect();
            if m.is_empty() {
                continue;
            }
            let mut stored_ids = j.lists.get(lst).map(|l| l.ids.clone()).unwrap_or_default();
            let original = original_doc.list_items(lst);
            for (i, it) in order.iter().enumerate() {
                let pos = original.iter().position(|x| x == it);
                if pos != Some(i) && !stored_ids.contains_key(it) {
                    if let Some(id) = ids.get(it) {
                        stored_ids.insert(it.clone(), id.clone());
                    }
                }
            }
            j.content = rename_store(&j.content, &m);
            j.headlines = rename_store(&j.headlines, &m);
            j.code_specs = rename_store(&j.code_specs, &m);
            j.units = rename_store(&j.units, &m);
            j.forms = j
                .forms
                .iter()
                .map(|(k, v)| (rename(k, &m), v.clone()))
                .collect();
            let mut new_lists = std::collections::BTreeMap::new();
            for (key, value) in &j.lists {
                let spec = if key == lst {
                    ListJson {
                        seq: value.seq,
                        items: order.iter().map(|i| rename(i, &m)).collect(),
                        ids: order
                            .iter()
                            .filter_map(|i| stored_ids.get(i).map(|id| (rename(i, &m), id.clone())))
                            .collect(),
                    }
                } else {
                    ListJson {
                        seq: value.seq,
                        items: value.items.iter().map(|i| rename(i, &m)).collect(),
                        ids: value
                            .ids
                            .iter()
                            .map(|(k, v)| (rename(k, &m), v.clone()))
                            .collect(),
                    }
                };
                new_lists.insert(rename(key, &m), spec);
            }
            j.lists = new_lists;
        }
        self.doc.load_json(&j);
    }

    /// Adds one entry to the Blueprint's revision history naming the pairs.
    fn revision_entry(&mut self, author: &str, date: &str) {
        let refl = self.set.refl();
        let mut lst = String::new();
        for p in spec_section_positions(&refl, &self.set.blueprint_root) {
            let member = match p.member {
                Some(m) if p.is_member && m.kind == SPEC_FIELD_KIND_LIST => m,
                _ => continue,
            };
            if p.path.contains("-*") {
                continue;
            }
            if refl
                .class_named(&member.element_type)
                .is_none_or(|el| el.section_id != "RVENT")
            {
                continue;
            }
            lst = p.path.clone();
            break;
        }
        if lst.is_empty() {
            return;
        }
        let items = self.doc.list_items(&lst);
        let last = items
            .last()
            .map(|i| self.doc.form_field_or(&format!("{}/content", i), "version"))
            .unwrap_or_default();
        let version = spec_backfill_bump(&last);
        let item = self.doc.add_list_item(&lst);
        let mut names: Vec<String> = Vec::new();
        for p in self.set.pairs() {
            if self.pairs.contains(&p.section_id) && !names.contains(&p.section_id) {
                names.push(p.section_id.clone());
            }
        }
        let others: Vec<String> = self
            .set
            .names()
            .into_iter()
            .filter(|n| *n != self.name)
            .collect();
        let summary = format!(
            "Backfilled from {}: {}",
            others.join(", "),
            names.join(", ")
        );
        let form = format!("{}/content", item);
        for (field, value) in [
            ("version", version.as_str()),
            ("date", date),
            ("author", author),
            ("summary", summary.as_str()),
        ] {
            self.doc.set_form_field(&form, field, value);
        }
        let mut ch = SpecBackfillChange::new("", SpecBackfillChangeKind::Revision, &item);
        ch.new_value = version;
        self.changes.push(ch);
    }
}

/// The version after `v`: its last number raised by one (`1.2` → `1.3`), `1`
/// when it is empty, `<v>.1` when it holds no number.
pub fn spec_backfill_bump(v: &str) -> String {
    let b = v.as_bytes();
    let end = match b.iter().rposition(u8::is_ascii_digit) {
        Some(i) => i + 1,
        None => {
            return if v.is_empty() {
                "1".to_string()
            } else {
                format!("{}.1", v)
            }
        }
    };
    let mut start = end;
    while start > 0 && b[start - 1].is_ascii_digit() {
        start -= 1;
    }
    match v[start..end].parse::<u64>() {
        Ok(n) => format!("{}{}{}", &v[..start], n + 1, &v[end..]),
        Err(_) => format!("{}.1", v),
    }
}
