//! `spec_section_id` — section-ID derivation for list/pattern sections (AA1
//! acceptance criteria 3–6), a faithful port of the Go `spec_section_id.go` (and
//! the Dart/TypeScript/Python/Java references).
//!
//! A single-valued section carries a *fixed* id — its `@SectionId`, which is
//! already the path segment, so nothing is derived. A **list item**, by
//! contrast, gets a generated id built from the list field's `@SectionIdPattern`
//! (e.g. `DACEN-ITEM-xxx`):
//!
//!   `<prefix><two-letter-date><number-within-the-day>`
//!
//! where `<prefix>` is the pattern with its trailing placeholder (`xxx`)
//! stripped (`DACEN-ITEM-`), `<two-letter-date>` encodes the creation date (see
//! [`encode_two_letter_date`]), and `<number-within-the-day>` is the 1-based
//! ordinal of the item among the list's items created the same day.
//!
//! The within-day number is derived from the list's *current* ids as
//! `max(existing for that day) + 1`. This gives both required behaviours with
//! one rule (criterion 6): deleting a middle item never renumbers the rest (the
//! max is unchanged, so a new same-day item takes the next free number and the
//! numbering may stay non-consecutive), while deleting the last item lowers the
//! max so a new same-day item *reuses* the just-freed id.

use std::time::{SystemTime, UNIX_EPOCH};

use crate::spec_paths::is_all_digits;

/// Encodes a `(month, day)` pair as the two-letter day code used in generated
/// section ids (criterion 4).
///
///   - First letter — month: Jan → A, Feb → B, … Dec → L.
///   - Second letter — day-of-month: days 1–26 → A–Z; days 27–31 → 0,1,2,3,4.
pub fn encode_two_letter_date(month: i64, day: i64) -> String {
    let month_letter = char::from_u32((0x41 + (month - 1)) as u32).unwrap_or('?');
    let day_code = if day <= 26 {
        char::from_u32((0x41 + (day - 1)) as u32).unwrap_or('?')
    } else {
        // 27 → '0', 28 → '1', … 31 → '4'.
        char::from_u32((0x30 + (day - 27)) as u32).unwrap_or('?')
    };
    let mut out = String::with_capacity(2);
    out.push(month_letter);
    out.push(day_code);
    out
}

/// Returns the static prefix of a `@SectionIdPattern`: the pattern with its
/// trailing placeholder (the run of trailing `x` characters) removed.
/// `DACEN-ITEM-xxx` → `DACEN-ITEM-`.
pub fn section_id_pattern_prefix(pattern: &str) -> String {
    let bytes = pattern.as_bytes();
    let mut i = bytes.len();
    while i > 0 && bytes[i - 1] == b'x' {
        i -= 1;
    }
    pattern[..i].to_string()
}

/// Returned when a section id would collide with another id in the same list
/// (criterion 5: overriding an id must keep every id in the list unique).
#[derive(Debug, Clone, PartialEq)]
pub struct SpecSectionIdCollision {
    pub id: String,
    pub list_path: String,
}

impl std::fmt::Display for SpecSectionIdCollision {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "SpecSectionIdCollision: section id \"{}\" is already used in list \"{}\"; section ids within a list must be unique.",
            self.id, self.list_path
        )
    }
}

/// The error kind returned by the section-id write paths: a uniqueness collision
/// (criterion 5) or an attempt to set an id on a path that is not a live list
/// item.
#[derive(Debug, Clone, PartialEq)]
pub enum SpecSectionIdError {
    /// The requested id is already used by another item of the same list.
    Collision(SpecSectionIdCollision),
    /// The path is not (or no longer) a live list item.
    NotLiveItem { item_path: String },
}

impl std::fmt::Display for SpecSectionIdError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            SpecSectionIdError::Collision(c) => write!(f, "{}", c),
            SpecSectionIdError::NotLiveItem { item_path } => {
                write!(f, "'{}' is not a live list item", item_path)
            }
        }
    }
}

impl std::error::Error for SpecSectionIdError {}

/// Reports whether `err` is a uniqueness collision (as opposed to a not-a-live-
/// item error) — the Rust analogue of the Go conformance runner's
/// `errors.As(&SpecSectionIDCollision)`.
pub fn is_collision(err: &SpecSectionIdError) -> bool {
    matches!(err, SpecSectionIdError::Collision(_))
}

/// Builds the generated section id for a new list item (criteria 3–4, 6).
///
/// `pattern` is the list field's `@SectionIdPattern`; `month`/`day` are the
/// creation date; `existing_ids` are the ids already assigned to the list's
/// items. The within-day number is `max(existing ids that share this day's
/// prefix) + 1`.
pub fn generate_list_item_section_id(
    pattern: &str,
    month: i64,
    day: i64,
    existing_ids: &[String],
) -> String {
    let day_prefix = section_id_pattern_prefix(pattern) + &encode_two_letter_date(month, day);
    let mut max_for_day: i64 = 0;
    for id in existing_ids {
        if id.is_empty() || !id.starts_with(&day_prefix) {
            continue;
        }
        let tail = &id[day_prefix.len()..];
        if tail.is_empty() || !is_all_digits(tail) {
            continue;
        }
        if let Ok(n) = tail.parse::<i64>() {
            if n > max_for_day {
                max_for_day = n;
            }
        }
    }
    format!("{}{}", day_prefix, max_for_day + 1)
}

/// Returns today's `(month, day)` in local-agnostic UTC terms, using only the
/// standard library (the runtime carries zero external dependencies).
///
/// Used by [`crate::som_facade::SomList::add`] to date a generated id when no
/// explicit date is supplied; the exact value is never asserted in tests (only
/// list length/content are), so a UTC civil date is sufficient.
pub fn today_month_day() -> (i64, i64) {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0);
    let days = secs.div_euclid(86_400);
    let (_, month, day) = civil_from_days(days);
    (month, day)
}

/// Converts a count of days since 1970-01-01 into a `(year, month, day)` civil
/// date using Howard Hinnant's dependency-free algorithm.
fn civil_from_days(z_in: i64) -> (i64, i64, i64) {
    let z = z_in + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = z - era * 146_097; // [0, 146096]
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365; // [0, 399]
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100); // [0, 365]
    let mp = (5 * doy + 2) / 153; // [0, 11]
    let d = doy - (153 * mp + 2) / 5 + 1; // [1, 31]
    let m = if mp < 10 { mp + 3 } else { mp - 9 }; // [1, 12]
    (if m <= 2 { y + 1 } else { y }, m, d)
}
