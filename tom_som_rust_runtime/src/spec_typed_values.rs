//! `spec_typed_values` — shared typed-value conversion at the store boundary
//! (YRD7), a faithful port of the Dart `spec_typed_values.dart` (and the Python
//! `spec_typed_values.py`).
//!
//! A [`SpecDocument`](crate::spec_document::SpecDocument)'s stores hold **plain
//! strings** — that is what the md/yaml serialization writes (`FieldName: value`)
//! and what keeps every language runtime's persistence identical. Typed access
//! therefore converts *at the boundary*: parse on read, format on write. These
//! helpers are that single boundary — the generated typed facades and the generic
//! [`SpecEditor`](crate::spec_editor::SpecEditor) call the **same** functions, so
//! a facade is provably a thin layer over the generic API (they cannot disagree
//! on a conversion).
//!
//! Conventions (the typed contract, mirrored by all nine runtimes):
//!   * absent / empty string ⇒ `None` on read; `None` on write ⇒ clear (D4);
//!   * `int`, `double` and `num` read their text with surrounding whitespace
//!     trimmed (the canonical reading of `tom_som_typescript_runtime`'s
//!     `spec_typed_values.ts`, shared corpus `typed_value_cases.json`);
//!   * `int` — an optional sign and decimal digits (`^[+-]?[0-9]+$`),
//!     [`som_parse_int`] yields `None` for anything else;
//!   * `double` — a decimal or exponent literal
//!     (`^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`, also
//!     plain integers); NaN, Infinity, hexadecimal and digit separators — some
//!     of which `str::parse::<f64>` would take — are refused, because a spec
//!     value is finite; formatting always carries a fraction or an exponent, so
//!     an integral value round-trips as `2.0` rather than `2`;
//!   * `num` — an integral literal parses back as an `int` (Dart's
//!     `num.tryParse`), so a `num` field keeps the narrower type when the text
//!     carries no fraction; hence [`SomNum`];
//!   * `bool` — stored as `true` / `false` (lower case, language-neutral);
//!     parsing accepts exactly those, anything else reads as `None`;
//!   * enums — stored as the constant **name** (e.g. `high`); the generic layer
//!     validates against the field's `enum_values` domain, the generated facade
//!     converts name ⇄ native constant;
//!   * a typed value holding inline marks (SOM §11.9.3, a change under
//!     review: `{~~ 30 ~> 15 ~~}`) reads as its **old** value, every mark
//!     rejected, until the marks are decided ([`som_typed_reading`]).
//!
//! Writes are strict and reads are forgiving, so the one fallible helper
//! ([`som_format_enum_name`]) returns `Result<_, String>` — the crate's error
//! idiom for a caller-supplied value that does not fit the model (see
//! [`spec_meta`](crate::spec_meta)).

/// A `num` value: an `int` when the text carried no fraction, else a `double`.
///
/// Rust has no `num` supertype (Dart's `num`, Python's `int | float`), so the
/// two shapes a `num` field can hold travel as this tagged pair. It keeps the
/// int/double distinction the store depends on: `2` must serialize as `2`, while
/// `2.0` must serialize as `2.0`.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum SomNum {
    Int(i64),
    Double(f64),
}

/// The reading of a typed value under review: `raw` with every inline mark
/// rejected (its old value), trimmed; `raw` itself when it holds no mark.
///
/// A typed value marked as a change (SOM §11.9.3) is the old value until the
/// change is accepted: the parsers below, the validator and every typed read
/// see that value, never the markup.
pub fn som_typed_reading(raw: &str) -> String {
    if !raw.contains('{') {
        return raw.to_string();
    }
    let old = crate::spec_review_annotations::apply_inline_marks_text(raw, false);
    if old == raw {
        return raw.to_string();
    }
    old.trim().to_string()
}

/// [`som_typed_reading`] over an optional stored value.
fn typed_reading_opt(raw: Option<&str>) -> Option<String> {
    raw.map(som_typed_reading)
}

/// Whether a form field holds a typed value: an enum (`enum_values` not
/// empty), or `int`, `double`, `num` or `bool` — the values that read as their
/// old value while marked.
pub fn som_is_typed_field(type_name: &str, enum_values: &[String]) -> bool {
    !enum_values.is_empty()
        || matches!(som_scalar_base(Some(type_name)), Some("int" | "double" | "num" | "bool"))
}

/// Whether `text` is an optional sign followed by one or more decimal digits.
pub(crate) fn is_int_text(text: &str) -> bool {
    let digits = text.strip_prefix(['+', '-']).unwrap_or(text);
    !digits.is_empty() && digits.bytes().all(|b| b.is_ascii_digit())
}

/// Whether `text` is a decimal literal with an optional exponent:
/// `[+-]?(digits(.digits?)?|.digits)([eE][+-]?digits)?`.
pub(crate) fn is_float_text(text: &str) -> bool {
    let b = text.as_bytes();
    let mut i = 0;
    if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
        i += 1;
    }
    let int_start = i;
    while i < b.len() && b[i].is_ascii_digit() {
        i += 1;
    }
    let int_digits = i - int_start;
    let mut frac_digits = 0;
    if i < b.len() && b[i] == b'.' {
        i += 1;
        let frac_start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        frac_digits = i - frac_start;
    }
    if int_digits == 0 && frac_digits == 0 {
        return false;
    }
    if i < b.len() && (b[i] == b'e' || b[i] == b'E') {
        i += 1;
        if i < b.len() && (b[i] == b'+' || b[i] == b'-') {
            i += 1;
        }
        let exp_start = i;
        while i < b.len() && b[i].is_ascii_digit() {
            i += 1;
        }
        if i == exp_start {
            return false;
        }
    }
    i == b.len()
}

/// Parses a stored string as `int`, or `None` when absent or when the text,
/// with surrounding whitespace trimmed, is not an optional sign and digits.
pub fn som_parse_int(raw: Option<&str>) -> Option<i64> {
    let raw = typed_reading_opt(raw);
    match raw.as_deref() {
        None => None,
        Some("") => None,
        Some(s) => {
            let text = s.trim();
            if is_int_text(text) {
                text.parse::<i64>().ok()
            } else {
                None
            }
        }
    }
}

/// Formats an `int` for the store; `None` becomes `""` (clear, D4).
pub fn som_format_int(value: Option<i64>) -> String {
    match value {
        None => String::new(),
        Some(v) => v.to_string(),
    }
}

/// Parses a stored string as `double`, or `None` when absent or when the text,
/// with surrounding whitespace trimmed, is not a decimal or exponent literal
/// (NaN, Infinity, hexadecimal and digit separators are refused).
pub fn som_parse_double(raw: Option<&str>) -> Option<f64> {
    let raw = typed_reading_opt(raw);
    match raw.as_deref() {
        None => None,
        Some("") => None,
        Some(s) => {
            let text = s.trim();
            if is_float_text(text) {
                text.parse::<f64>().ok().filter(|v| v.is_finite())
            } else {
                None
            }
        }
    }
}

/// Formats a `double` for the store; `None` becomes `""` (clear, D4).
///
/// A `double` always renders with a fraction or an exponent (`2.0`, `1e+21`),
/// matching Dart's `double.toString` — the store is language-neutral, so the
/// same value must serialize identically everywhere. Rust's `Display` for `f64`
/// drops the fraction of an integral value (`2`) and never uses an exponent, so
/// a finite value goes through `format_yaml_float`.
pub fn som_format_double(value: Option<f64>) -> String {
    let v = match value {
        None => return String::new(),
        Some(v) => v,
    };
    if v.is_finite() {
        // One layout in every runtime (decision tspubnondart29 (a)): the
        // shortest digits in JavaScript's Number toString layout, `.0` on a
        // whole value (`10000000.0`, `1e-7`, `1e+21`) — the review pass's
        // float form. `{}` never uses an exponent (1e21 in full).
        return crate::spec_document_yaml::format_yaml_float(v);
    }
    v.to_string()
}

/// Parses a stored string as `int` when integral, else `double` — both with
/// the text trimmed and read as [`som_parse_int`] / [`som_parse_double`] do.
///
/// Mirrors Dart's `num.tryParse`: an integral literal yields an `int`, so `num`
/// fields keep the narrower type when the text carries no fraction.
pub fn som_parse_num(raw: Option<&str>) -> Option<SomNum> {
    let raw = typed_reading_opt(raw);
    let s = match raw.as_deref() {
        None => return None,
        Some("") => return None,
        Some(s) => s,
    };
    if let Some(n) = som_parse_int(Some(s)) {
        return Some(SomNum::Int(n));
    }
    som_parse_double(Some(s)).map(SomNum::Double)
}

/// Formats a `num` for the store; `None` becomes `""` (clear, D4).
pub fn som_format_num(value: Option<SomNum>) -> String {
    match value {
        None => String::new(),
        Some(SomNum::Int(n)) => som_format_int(Some(n)),
        Some(SomNum::Double(d)) => som_format_double(Some(d)),
    }
}

/// Parses a stored string as `bool` — exactly `true`/`false`, else `None`.
pub fn som_parse_bool(raw: Option<&str>) -> Option<bool> {
    let raw = typed_reading_opt(raw);
    match raw.as_deref() {
        Some("true") => Some(true),
        Some("false") => Some(false),
        _ => None,
    }
}

/// Formats a `bool` for the store; `None` becomes `""` (clear, D4).
pub fn som_format_bool(value: Option<bool>) -> String {
    match value {
        None => String::new(),
        Some(true) => "true".to_string(),
        Some(false) => "false".to_string(),
    }
}

/// Parses a stored string as an enum constant name against `values` (the field's
/// `enum_values` domain).
///
/// Returns `None` when absent or not in the domain — a stale/foreign name reads
/// as unset rather than erroring, the same forgiveness the other parsers extend
/// to malformed numbers.
pub fn som_parse_enum_name(raw: Option<&str>, values: &[String]) -> Option<String> {
    let raw = typed_reading_opt(raw);
    match raw.as_deref() {
        Some(s) if !s.is_empty() && values.iter().any(|v| v == s) => Some(s.to_string()),
        _ => None,
    }
}

/// Validates an enum constant `name` against `values` before storing.
///
/// `None`/empty clears (yields `""`); a name outside the domain is an error —
/// writes are strict where reads are forgiving, so a typo cannot enter the store.
pub fn som_format_enum_name(name: Option<&str>, values: &[String]) -> Result<String, String> {
    let n = match name {
        None => return Ok(String::new()),
        Some(s) if s.is_empty() => return Ok(String::new()),
        Some(s) => s,
    };
    if !values.iter().any(|v| v == n) {
        return Err(format!(
            "'{}' is not one of the enum values {}",
            n,
            values.join(", ")
        ));
    }
    Ok(n.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_are_forgiving_and_writes_round_trip() {
        assert_eq!(som_parse_int(Some("12")), Some(12));
        assert_eq!(som_parse_int(Some("abc")), None);
        assert_eq!(som_parse_int(Some("")), None);
        assert_eq!(som_parse_int(None), None);
        assert_eq!(som_format_int(Some(12)), "12");
        assert_eq!(som_format_int(None), "");

        assert_eq!(som_parse_double(Some("2")), Some(2.0));
        assert_eq!(som_parse_double(Some("x")), None);
        assert_eq!(som_format_double(Some(2.5)), "2.5");
        assert_eq!(som_format_double(None), "");

        assert_eq!(som_parse_num(Some("3")), Some(SomNum::Int(3)));
        assert_eq!(som_parse_num(Some("3.5")), Some(SomNum::Double(3.5)));
        assert_eq!(som_format_num(Some(SomNum::Int(3))), "3");
        assert_eq!(som_format_num(Some(SomNum::Double(3.0))), "3.0");

        assert_eq!(som_parse_int(Some(" 5")), Some(5));
        assert_eq!(som_parse_double(Some("NaN")), None);
        assert_eq!(som_parse_double(Some("inf")), None);
        assert_eq!(som_parse_double(Some("1.")), Some(1.0));
        assert_eq!(som_parse_double(Some(".5")), Some(0.5));
        assert_eq!(som_parse_double(Some("1e")), None);

        assert_eq!(som_parse_bool(Some("true")), Some(true));
        assert_eq!(som_parse_bool(Some("TRUE")), None);
        assert_eq!(som_format_bool(Some(false)), "false");
    }

    /// The highest-risk divergence: an integral `double` must keep its decimal
    /// point so the store is byte-identical across the nine runtimes.
    #[test]
    fn an_integral_double_formats_with_a_decimal_point() {
        assert_eq!(som_format_double(Some(2.0)), "2.0");
        assert_eq!(som_format_double(Some(-7.0)), "-7.0");
        assert_eq!(som_format_double(Some(0.0)), "0.0");
    }

    #[test]
    fn enum_names_read_forgivingly_and_write_strictly() {
        let values = vec!["low".to_string(), "high".to_string()];
        assert_eq!(som_parse_enum_name(Some("high"), &values), Some("high".to_string()));
        assert_eq!(som_parse_enum_name(Some("urgent"), &values), None);
        assert_eq!(som_format_enum_name(Some("high"), &values).unwrap(), "high");
        assert_eq!(som_format_enum_name(None, &values).unwrap(), "");
        assert_eq!(som_format_enum_name(Some(""), &values).unwrap(), "");
        assert!(som_format_enum_name(Some("urgent"), &values).is_err());
    }
}

/// The scalar base of a declared field type: `int?` → `int`; `None` (or the
/// empty name, the Rust model's "no declared type") stays `None`.
pub fn som_scalar_base(type_name: Option<&str>) -> Option<&str> {
    match type_name {
        None | Some("") => None,
        Some(t) => Some(t.strip_suffix('?').unwrap_or(t)),
    }
}

/// Whether `raw`, stored in a field declared as `type_name`, is text that
/// type's parser can read.
///
/// Only `int`, `double`, `num` and `bool` constrain their text; every other
/// type (strings, and enums, whose domain `enumValueUnknown` checks) accepts
/// any text. Empty or absent text is readable: it is how a field is unset. The
/// validator reports a stored value this rejects as `valueTypeMismatch`, the
/// setters refuse to store one, and the typed reads return `Err` for one — so
/// text a typed field cannot read is never silently read as unset.
pub fn som_typed_text_readable(type_name: Option<&str>, raw: Option<&str>) -> bool {
    let raw = typed_reading_opt(raw);
    let raw = match raw.as_deref() {
        None | Some("") => return true,
        Some(r) => r,
    };
    match som_scalar_base(type_name) {
        Some("int") => som_parse_int(Some(raw)).is_some(),
        Some("double") => som_parse_double(Some(raw)).is_some(),
        Some("num") => som_parse_num(Some(raw)).is_some(),
        Some("bool") => som_parse_bool(Some(raw)).is_some(),
        _ => true,
    }
}
