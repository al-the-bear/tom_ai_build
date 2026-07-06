//! `spec_serialization_order` — model-aware member ordering for YAML
//! serialization (AA1 criterion 7), a faithful port of the Go
//! `spec_serialization_order.go`.
//!
//! A [`SpecDocument`](crate::spec_document::SpecDocument) is a flat, path-keyed
//! store; the native YAML codec normally emits keys alphabetically for clean
//! diffs. Criterion 7 instead requires each class's members to be emitted in the
//! order declared by their `@SerializationOrder` annotation (the SOM source
//! declaration order).
//!
//! This helper turns a path into an ordinal tuple — the `@SerializationOrder` of
//! each field crossed on the way down (plus the numeric sequence for a list
//! item), mirroring the walk [`SpecReflection::resolve`] performs. Comparing
//! those tuples lexicographically reproduces a depth-first, member-order
//! traversal: siblings of one class sort by their declared order, and the
//! recursion carries that ordering down the tree. Form fields (which are
//! sub-keys, not path segments) are ordered by their position in the owning
//! `@Form`'s field list.
//!
//! Unannotated members sort after annotated ones (fallback ordinal), then by
//! path/name, so ordering is always total and deterministic.

use std::cmp::Ordering;

use crate::spec_model::{SpecClass, SpecField, SpecModel, SPEC_FIELD_KIND_COMPLEX,
    SPEC_FIELD_KIND_LIST, SPEC_FIELD_KIND_SECTION};
use crate::spec_paths::{spec_path_segments, split_list_item_segment};
use crate::spec_reflection::SpecReflection;

/// The ordinal used for members without a `@SerializationOrder`, so they sort
/// after every annotated member while staying stable relative to each other.
pub const SERIALIZATION_UNORDERED_FALLBACK: i64 = 1 << 30;

/// Computes member ordering keys from a [`SpecModel`].
pub struct SpecSerializationOrder<'a> {
    refl: SpecReflection<'a>,
}

impl<'a> SpecSerializationOrder<'a> {
    /// Builds an ordering helper for the given model.
    pub fn new(model: &'a SpecModel) -> SpecSerializationOrder<'a> {
        SpecSerializationOrder {
            refl: SpecReflection::new(model),
        }
    }

    /// Returns the ordinal tuple for `path`: one entry per field crossed (its
    /// `@SerializationOrder`, or [`SERIALIZATION_UNORDERED_FALLBACK`]), with a
    /// trailing entry for a list item's numeric sequence. A path that does not
    /// resolve yields an empty tuple (it then sorts by its string form only).
    pub fn order_key(&self, path: &str) -> Vec<i64> {
        let segs = spec_path_segments(path);
        if segs.is_empty() || segs[0].is_empty() {
            return Vec::new();
        }
        let root = match self.refl.root_for_segment(&segs[0]) {
            Some(r) => r,
            None => return Vec::new(),
        };

        let mut key: Vec<i64> = Vec::new();
        let mut cur_class = self.refl.class_named(&root.type_);
        let mut i = 1;
        while i < segs.len() {
            let cls = match cur_class {
                Some(c) => c,
                None => break,
            };
            let seg = &segs[i];

            if let Some(field) = self.match_field(cls, seg) {
                key.push(order_of(field));
                if field.kind == SPEC_FIELD_KIND_COMPLEX || field.kind == SPEC_FIELD_KIND_SECTION {
                    cur_class = self.refl.class_named(&field.type_);
                    i += 1;
                    continue;
                }
                break; // list container / leaf / form terminates the descent
            }

            // A list item segment: `<base>-<seq>`.
            let split = match split_list_item_segment(seg) {
                Some(s) => s,
                None => break,
            };
            let list_field = match self.match_field(cls, &split.base) {
                Some(f) if f.kind == SPEC_FIELD_KIND_LIST => f,
                _ => break,
            };
            key.push(order_of(list_field));
            key.push(split.seq);
            if list_field.element_is_complex {
                cur_class = self.refl.class_named(&list_field.element_type);
                i += 1;
                continue;
            }
            break; // scalar list item is a leaf
        }
        key
    }

    /// Orders `paths` by their [`SpecSerializationOrder::order_key`]
    /// (lexicographically), breaking ties by the path string so the result is a
    /// total, stable order.
    pub fn order_paths(&self, paths: &[String]) -> Vec<String> {
        let mut items: Vec<String> = paths.to_vec();
        let keys: Vec<(String, Vec<i64>)> =
            items.iter().map(|p| (p.clone(), self.order_key(p))).collect();
        items.sort_by(|a, b| {
            let ka = keys.iter().find(|(p, _)| p == a).map(|(_, k)| k).unwrap();
            let kb = keys.iter().find(|(p, _)| p == b).map(|(_, k)| k).unwrap();
            compare_order_keys(ka, a, kb, b)
        });
        items
    }

    /// Orders the form-field names of the `@Form` at `form_path` by their
    /// declared position in the form's field list; names not found in the model
    /// sort after, alphabetically.
    pub fn order_form_fields(&self, form_path: &str, field_names: &[String]) -> Vec<String> {
        let resolution = self.refl.resolve(form_path);
        let mut names: Vec<String> = field_names.to_vec();
        let positions: Vec<(String, usize)> = match resolution.and_then(|r| r.field) {
            Some(field) => field
                .form_fields
                .iter()
                .enumerate()
                .map(|(idx, ff)| (ff.name.clone(), idx))
                .collect(),
            None => Vec::new(),
        };
        let pos_of = |name: &str| -> usize {
            positions
                .iter()
                .find(|(n, _)| n == name)
                .map(|(_, i)| *i)
                .unwrap_or(SERIALIZATION_UNORDERED_FALLBACK as usize)
        };
        names.sort_by(|a, b| {
            let pa = pos_of(a);
            let pb = pos_of(b);
            if pa != pb {
                pa.cmp(&pb)
            } else {
                a.cmp(b)
            }
        });
        names
    }

    fn match_field<'c>(&self, cls: &'c SpecClass, segment: &str) -> Option<&'c SpecField> {
        cls.fields
            .iter()
            .find(|f| self.refl.field_segment(f) == segment)
    }
}

fn order_of(field: &SpecField) -> i64 {
    field.serialization_order.unwrap_or(SERIALIZATION_UNORDERED_FALLBACK)
}

/// Reproduces the Go `compareOrderKeys` total order: shorter/equal-prefix tuples
/// order by length, then ties break on the path string.
fn compare_order_keys(a: &[i64], a_path: &str, b: &[i64], b_path: &str) -> Ordering {
    let n = a.len().min(b.len());
    for i in 0..n {
        if a[i] != b[i] {
            return a[i].cmp(&b[i]);
        }
    }
    if a.len() != b.len() {
        return a.len().cmp(&b.len());
    }
    a_path.cmp(b_path)
}
