//! `spec_generation_units` — the generation-unit register of a document (SOM
//! §11.2): the units Phase 4 writes code into, each with the mapper of every
//! area it holds. A port of the Dart `spec_generation_units.dart`.
//!
//! The register is recognised by its annotations, never by class name, exactly
//! as validation phase 8 recognises it: a **unit** is a list item whose class
//! carries `@NoArtifact(generation)` and declares the form field `unitId`; a
//! **mapping** is such a list item declaring the form field `area`, and belongs
//! to the nearest unit whose path is a prefix of its own.

use std::collections::HashSet;

use crate::spec_document::SpecDocument;
use crate::spec_model::SpecModel;
use crate::spec_paths::spec_path_join;
use crate::spec_reflection::SpecReflection;
use crate::spec_validator::form_declaring;

/// One mapping of a generation unit: the area it holds and the mapper that
/// writes that area's code for it.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecGenerationUnitMapping {
    /// The area code, `CE-…`, as stored (trimmed).
    pub area: String,

    /// The mapper id, e.g. `dart-tom`, as stored (trimmed); empty when unset.
    pub mapping: String,
}

/// One generation unit the document declares.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SpecGenerationUnit {
    /// The unit's id — what a section's `units` names, usually the package name.
    pub unit_id: String,

    /// `client`, `server`, `shared` or `other`, as stored; empty when unset.
    pub kind: String,

    /// The unit's list-item path in the document.
    pub path: String,

    /// The unit's mappings, in stored order.
    pub mappings: Vec<SpecGenerationUnitMapping>,
}

impl SpecGenerationUnit {
    /// Whether one of the unit's mappings holds `area_code`.
    pub fn maps(&self, area_code: &str) -> bool {
        self.mappings.iter().any(|m| m.area == area_code)
    }

    /// The mapper of `area_code` — the first mapping that holds it — or `None`.
    pub fn mapping_for(&self, area_code: &str) -> Option<&str> {
        self.mappings
            .iter()
            .find(|m| m.area == area_code)
            .map(|m| m.mapping.as_str())
    }
}

/// A unit as read, before duplicates are dropped.
struct RawUnit {
    id: String,
    kind: String,
    path: String,
}

/// A mapping as read, before it is given to its unit.
struct RawMapping {
    path: String,
    area: String,
    mapping: String,
}

/// The generation units `doc` declares, in register order: sorted list-path
/// order, each list's items in their stored order — the order validation phase
/// 8 visits them in. A unit without a `unitId` is left out; a second unit with
/// an id already seen is left out too (phase 8 reports it as
/// `duplicateUnitId`). A document without a register declares none.
pub fn spec_generation_units(model: &SpecModel, doc: &SpecDocument) -> Vec<SpecGenerationUnit> {
    let refl = SpecReflection::new(model);
    let mut units: Vec<RawUnit> = Vec::new();
    let mut mappings: Vec<RawMapping> = Vec::new();
    let mut list_paths = doc.list_paths();
    list_paths.sort();
    for list_path in &list_paths {
        for item in doc.list_items(list_path) {
            let cls = match refl.resolve(&item).and_then(|r| r.target_class) {
                Some(c) => c,
                None => continue,
            };
            if cls.no_artifact().map(|n| n.reason) != Some("generation".to_string()) {
                continue;
            }
            let trimmed = |form_path: &str, f: &str| {
                doc.form_field(form_path, f)
                    .map(|v| v.trim().to_string())
                    .unwrap_or_default()
            };
            if let Some(unit_form) = form_declaring(&cls, "unitId") {
                let form_path = spec_path_join(&item, &refl.field_segment(unit_form));
                let id = trimmed(&form_path, "unitId");
                if !id.is_empty() {
                    units.push(RawUnit {
                        id,
                        kind: trimmed(&form_path, "kind"),
                        path: item.clone(),
                    });
                }
            }
            if let Some(area_form) = form_declaring(&cls, "area") {
                let form_path = spec_path_join(&item, &refl.field_segment(area_form));
                let area = trimmed(&form_path, "area");
                if !area.is_empty() {
                    mappings.push(RawMapping {
                        path: item.clone(),
                        area,
                        mapping: trimmed(&form_path, "mapping"),
                    });
                }
            }
        }
    }

    let mut seen: HashSet<String> = HashSet::new();
    let mut out: Vec<SpecGenerationUnit> = Vec::new();
    for u in &units {
        if !seen.insert(u.id.clone()) {
            continue;
        }
        out.push(SpecGenerationUnit {
            unit_id: u.id.clone(),
            kind: u.kind.clone(),
            path: u.path.clone(),
            mappings: mappings
                .iter()
                .filter(|m| owner(&m.path, &units) == Some(u.path.as_str()))
                .map(|m| SpecGenerationUnitMapping {
                    area: m.area.clone(),
                    mapping: m.mapping.clone(),
                })
                .collect(),
        });
    }
    out
}

/// The units of `units` whose mappings hold `area_code`, in register order —
/// the default destination of a section routed to that area (SOM §11.2).
pub fn spec_default_units(units: &[SpecGenerationUnit], area_code: &str) -> Vec<String> {
    units
        .iter()
        .filter(|u| u.maps(area_code))
        .map(|u| u.unit_id.clone())
        .collect()
}

/// The path of the unit a mapping at `mapping_path` belongs to: the longest
/// unit path that is a proper prefix of it, or `None`.
fn owner<'u>(mapping_path: &str, units: &'u [RawUnit]) -> Option<&'u str> {
    let mut best: Option<&str> = None;
    for u in units {
        if mapping_path.starts_with(&format!("{}/", u.path))
            && best.is_none_or(|b| u.path.len() > b.len())
        {
            best = Some(&u.path);
        }
    }
    best
}
