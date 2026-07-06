//! `spec_paths` — the section-path grammar shared by the in-memory document and
//! the meta-model traversal, a faithful port of the Go `spec_paths.go` (and the
//! Dart/TypeScript reference).
//!
//! A path is the globally-unique address of a node in a concrete document:
//!
//!   - the root is the document root's section segment (its `@SectionId` when
//!     present, otherwise the root class name);
//!   - a child field appends `/<segment>`;
//!   - a complex / section field collapses into its target class (no extra
//!     segment — the class's children hang directly off the field's path);
//!   - a list item appends `-<seq>` to the list field's path (no `/`).
//!
//! Form-field values are not path segments: a `@Form` section is one path whose
//! individual fields are sub-keys inside the document's form store.

/// The path separator between section segments.
pub const SPEC_PATH_SEPARATOR: &str = "/";

/// Joins `parent` with a child `segment` using the path separator.
pub fn spec_path_join(parent: &str, segment: &str) -> String {
    format!("{}{}{}", parent, SPEC_PATH_SEPARATOR, segment)
}

/// Splits `path` into its `/`-separated segments. A list-item sequence suffix
/// (`<segment>-3`) stays attached to its segment.
pub fn spec_path_segments(path: &str) -> Vec<String> {
    path.split(SPEC_PATH_SEPARATOR).map(|s| s.to_string()).collect()
}

/// Returns the path of the `seq`-th item appended to the list at `list_path`.
pub fn list_item_path(list_path: &str, seq: i64) -> String {
    format!("{}-{}", list_path, seq)
}

/// A list-item segment split into its base segment and sequence number.
#[derive(Debug, Clone, PartialEq)]
pub struct ListItemSegment {
    pub base: String,
    pub seq: i64,
}

/// Splits a list-item segment into its base segment and sequence number when it
/// ends in `-<digits>`, returning `None` otherwise.
///
/// Only an all-digit tail counts, so a hyphenated `@SectionId` such as `CUOPME-OPER-LST`
/// is never mis-read as a list item.
pub fn split_list_item_segment(segment: &str) -> Option<ListItemSegment> {
    let dash = segment.rfind('-')?;
    if dash == 0 || dash == segment.len() - 1 {
        return None;
    }
    let tail = &segment[dash + 1..];
    if !is_all_digits(tail) {
        return None;
    }
    Some(ListItemSegment {
        base: segment[..dash].to_string(),
        seq: tail.parse::<i64>().ok()?,
    })
}

/// Reports whether `s` is non-empty and composed solely of ASCII digits.
pub fn is_all_digits(s: &str) -> bool {
    !s.is_empty() && s.bytes().all(|b| b.is_ascii_digit())
}
