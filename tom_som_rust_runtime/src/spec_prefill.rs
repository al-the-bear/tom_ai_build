//! `spec_prefill` — [`prefill`]: a Phase 3 document started from the
//! Blueprint (BP-8). A port of `tom_som_dart_runtime/lib/src/spec_prefill.dart`
//! (a `part of` `spec_document_set.dart` there; and the TypeScript,
//! JavaScript, Python, Go and Java `spec_prefill` modules); it reads the
//! comparison internals of [`SpecSetCheck`] and [`SpecSetSide`].

use std::collections::HashSet;

use crate::json::Json;
use crate::spec_derive_fields::{
    derive_fields, spec_add_item, spec_set_value, SpecDeriveOptions, SpecDeriveResult,
};
use crate::spec_document::SpecDocument;
use crate::spec_document_set::{
    pair_scope, set_jobj, set_jstr, set_jstrs, spec_validation_errors_json, SpecDocumentSet,
    SpecSetCheck, SpecSetSide,
};
use crate::spec_links_validator::validate_links;
use crate::spec_validator::{validate_document, SpecValidationError};

/// Why [`prefill`] refuses.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum SpecPrefillErrorCode {
    /// The set holds no Blueprint.
    NoBlueprint,
    /// The root names no root of the model, or the Blueprint's own.
    UnknownRoot,
}

impl SpecPrefillErrorCode {
    /// The code's name as the corpus writes it (`noBlueprint`,
    /// `unknownRoot`).
    pub fn name(self) -> &'static str {
        match self {
            SpecPrefillErrorCode::NoBlueprint => "noBlueprint",
            SpecPrefillErrorCode::UnknownRoot => "unknownRoot",
        }
    }
}

/// Why [`prefill`] refuses.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecPrefillError {
    /// Why.
    pub code: SpecPrefillErrorCode,
    /// The prose for the reader.
    pub message: String,
}

impl std::fmt::Display for SpecPrefillError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "SpecPrefillError({}): {}",
            self.code.name(),
            self.message
        )
    }
}

impl std::error::Error for SpecPrefillError {}

/// What [`prefill`] did.
#[derive(Debug, Clone)]
pub struct SpecPrefillResult {
    /// The document filled, as the set now holds it (unless nothing was
    /// created: then it is the empty document the set did not take).
    pub document: SpecDocument,
    /// Its name in the set.
    pub name: String,
    /// Whether it was created by this call.
    pub created: bool,
    /// The pairs it filled, by section id, in the Blueprint's order.
    pub filled_pairs: Vec<String>,
    /// The pairs it left because their anchor already holds a value.
    pub skipped_pairs: Vec<String>,
    /// The `derive_fields` run (plain) on the document after the copy.
    pub derived: SpecDeriveResult,
    /// The document's findings after it (`validate_document`, then
    /// `validate_links`): the agent's work list.
    pub findings: Vec<SpecValidationError>,
}

impl SpecPrefillResult {
    /// The canonical JSON form.
    pub fn to_json(&self) -> Json {
        set_jobj(vec![
            ("name", set_jstr(&self.name)),
            ("created", Json::Bool(self.created)),
            ("filledPairs", set_jstrs(&self.filled_pairs)),
            ("skippedPairs", set_jstrs(&self.skipped_pairs)),
            (
                "derived",
                set_jobj(vec![
                    (
                        "changes",
                        Json::Array(self.derived.changes.iter().map(|c| c.to_json()).collect()),
                    ),
                    (
                        "unresolved",
                        spec_validation_errors_json(&self.derived.unresolved),
                    ),
                ]),
            ),
            ("findings", spec_validation_errors_json(&self.findings)),
            ("document", self.document.to_json().to_json()),
        ])
    }
}

/// The options of [`prefill`].
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SpecPrefillOptions {
    /// The name a document created is given, `""` for the root's type name.
    pub name: String,
    /// `Some`: keeps those pairs (by section id) only.
    pub pairs: Option<Vec<String>>,
}

/// Fills the pairs of `root_type` (a root's type name or section id) that
/// hold nothing yet from the Blueprint, once, at the start of a Phase 3
/// document (BP-8): every value, element (with its stored section id) and
/// headline beneath each pair's Blueprint anchor, outside `detailOnly`,
/// copied as plain values. Derived places are not copied; they are derived in
/// the document (`derive_fields`, plain) after the copy.
///
/// A pair whose anchor already holds any value is skipped, not merged, so a
/// second run writes nothing. The document's front matter is left empty for
/// the agent. When the set has no document of the root, it is created as
/// `options.name` (default: the root's type name) and added to the set once it
/// holds a value.
pub fn prefill(
    set: &mut SpecDocumentSet<'_>,
    root_type: &str,
    options: &SpecPrefillOptions,
) -> Result<SpecPrefillResult, SpecPrefillError> {
    let scope = pair_scope(options.pairs.as_deref());
    let bp_root = set.blueprint_root.clone();
    let bp_name = match set.name_of(&bp_root) {
        Some(n) if !bp_root.is_empty() => n,
        _ => {
            return Err(SpecPrefillError {
                code: SpecPrefillErrorCode::NoBlueprint,
                message: "the set holds no Blueprint".to_string(),
            })
        }
    };
    let root = match set
        .model
        .roots
        .iter()
        .find(|r| r.type_ == root_type || r.section_id == root_type)
    {
        Some(r) if r.type_ != bp_root => r.clone(),
        _ => {
            return Err(SpecPrefillError {
                code: SpecPrefillErrorCode::UnknownRoot,
                message: format!("{} names no Phase 3 root of the model", root_type),
            })
        }
    };
    let existing = set.name_of(&root.type_);
    let doc_name = match &existing {
        Some(n) => n.clone(),
        None if options.name.is_empty() => root.type_.clone(),
        None => options.name.clone(),
    };
    let mut doc = existing
        .as_ref()
        .and_then(|n| set.get(n))
        .cloned()
        .unwrap_or_default();

    let mut filled = Vec::new();
    let mut skipped = Vec::new();
    {
        let bp = match set.get(&bp_name) {
            Some(d) => d,
            None => unreachable!("the Blueprint is named in the set"),
        };
        let mut c = SpecSetCheck::new(set);
        for pair in set.pairs() {
            if pair.detail_root != root.type_ {
                continue;
            }
            if scope
                .as_ref()
                .is_some_and(|s| !s.contains(&pair.section_id))
            {
                continue;
            }
            // Nested pairs are filled on their own (when they are this root's).
            let mut nested = Vec::new();
            for other in set.pairs() {
                if other != pair {
                    nested.extend(c.expand(bp, &other.blueprint_anchor));
                }
            }
            let mut wrote = false;
            let mut held = false;
            for ba in c.expand(bp, &pair.blueprint_anchor) {
                let ids = c.anchor_key(bp, &ba);
                let mut created_items = Vec::new();
                let da = prefill_anchor_in(
                    &mut c,
                    &mut doc,
                    &pair.detail_anchor,
                    &ids,
                    &mut created_items,
                );
                if doc.has_values_under(&da) && created_items.is_empty() {
                    held = true;
                    continue;
                }
                let prefix = format!("{}/", ba);
                let beneath: Vec<String> = nested
                    .iter()
                    .filter(|p| p.starts_with(&prefix))
                    .cloned()
                    .collect();
                let side = c.collect(&bp_name, bp, &bp_root, &ba, pair, &beneath);
                if prefill_copy(&mut c, bp, &side, &mut doc, &da) {
                    wrote = true;
                } else {
                    // Nothing to copy: the anchor items made for it go again.
                    for item in created_items.iter().rev() {
                        doc.remove_list_item(item);
                    }
                }
            }
            if wrote {
                filled.push(pair.section_id.clone());
            }
            if held && !wrote {
                skipped.push(pair.section_id.clone());
            }
        }
    }

    let created = existing.is_none() && doc.has_values_under(&set.refl().root_segment(&root));
    if created {
        set.put(&doc_name, doc.clone())
            .unwrap_or_else(|e| panic!("{}", e));
    }
    let derived = derive_fields(set.model, &mut doc, &SpecDeriveOptions::default());
    if existing.is_some() || created {
        set.replace(&doc_name, doc.clone());
    }
    let mut findings = validate_document(set.model, &doc);
    findings.extend(validate_links(set.model, &doc));
    Ok(SpecPrefillResult {
        document: doc,
        name: doc_name,
        created,
        filled_pairs: filled,
        skipped_pairs: skipped,
        derived,
        findings,
    })
}

/// The concrete detail anchor of `pattern` in `doc` for a Blueprint anchor
/// whose list items carry `ids` (`a/b`, in order): each `<list>-*` taken as
/// the item of that id, created with it when missing.
fn prefill_anchor_in(
    c: &mut SpecSetCheck<'_, '_>,
    doc: &mut SpecDocument,
    pattern: &str,
    ids: &str,
    created: &mut Vec<String>,
) -> String {
    let want: Vec<&str> = if ids.is_empty() {
        Vec::new()
    } else {
        ids.split('/').collect()
    };
    let mut k = 0;
    let mut cur = String::new();
    for seg in pattern.split('/') {
        let base = match seg.strip_suffix("-*") {
            Some(b) => b,
            None => {
                if cur.is_empty() {
                    cur = seg.to_string();
                } else {
                    cur = format!("{}/{}", cur, seg);
                }
                continue;
            }
        };
        let lst = format!("{}/{}", cur, base);
        let id = match want.get(k) {
            Some(id) => {
                k += 1;
                *id
            }
            None => "",
        };
        let hit = doc
            .list_items(&lst)
            .into_iter()
            .find(|i| c.item_id(doc, i) == id);
        match hit {
            Some(h) => cur = h,
            None => {
                cur = spec_add_item(doc, &lst, Some(id));
                created.push(cur.clone());
            }
        }
    }
    cur
}

/// Copies the Blueprint values of `side` beneath `anchor` of `doc`: list items
/// first, in the Blueprint's order and with their section ids, then every
/// value. Whether anything was written.
fn prefill_copy(
    c: &mut SpecSetCheck<'_, '_>,
    bp: &SpecDocument,
    side: &SpecSetSide,
    doc: &mut SpecDocument,
    anchor: &str,
) -> bool {
    let mut wrote = false;
    let mut mapped: Vec<(String, String)> = vec![(side.anchor.clone(), anchor.to_string())];
    let into = |mapped: &[(String, String)], bp_path: &str| -> Option<String> {
        mapped
            .iter()
            .filter(|(k, _)| {
                bp_path == k
                    || (bp_path.starts_with(k.as_str()) && bp_path[k.len()..].starts_with('/'))
            })
            .max_by_key(|(k, _)| k.len())
            .map(|(k, to)| format!("{}{}", to, &bp_path[k.len()..]))
    };

    // Items, outer lists first, each list in the Blueprint's order.
    let mut lists: Vec<String> = Vec::new();
    let mut item_paths: HashSet<&str> = HashSet::new();
    for k in &side.item_keys {
        let item = &side.items[k];
        item_paths.insert(item.as_str());
        if *item != side.anchor {
            let lst = item[..item.rfind('-').unwrap_or(item.len())].to_string();
            if !lists.contains(&lst) {
                lists.push(lst);
            }
        }
    }
    lists.sort_by_key(|l| l.len());
    for lst in &lists {
        let target = match into(&mapped, lst) {
            Some(t) => t,
            None => continue,
        };
        for item in bp.list_items(lst) {
            if !item_paths.contains(item.as_str()) {
                continue;
            }
            let id = c.item_id(bp, &item);
            let new_item = spec_add_item(doc, &target, Some(&id));
            mapped.push((item, new_item));
            wrote = true;
        }
    }
    for v in side.values.values() {
        if v.value.is_empty() {
            continue;
        }
        let p = match into(&mapped, &v.path) {
            Some(p) => p,
            None => continue,
        };
        spec_set_value(doc, &p, &v.field, &v.value);
        wrote = true;
    }
    wrote
}
