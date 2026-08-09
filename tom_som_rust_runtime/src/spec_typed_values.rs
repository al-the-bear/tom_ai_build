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
//!   * `int` — decimal integer, [`som_parse_int`] yields `None` for non-numeric
//!     text;
//!   * `double` — accepts any parsable floating literal (also plain integers);
//!     formatting always carries a decimal point, so an integral value
//!     round-trips as `2.0` rather than `2` (Dart's `double.toString`);
//!   * `num` — an integral literal parses back as an `int` (Dart's
//!     `num.tryParse`), so a `num` field keeps the narrower type when the text
//!     carries no fraction; hence [`SomNum`];
//!   * `bool` — stored as `true` / `false` (lower case, language-neutral);
//!     parsing accepts exactly those, anything else reads as `None`;
//!   * enums — stored as the constant **name** (e.g. `high`); the generic layer
//!     validates against the field's `enum_values` domain, the generated facade
//!     converts name ⇄ native constant.
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

/// Parses a stored string as `int`, or `None` when absent/unparsable.
pub fn som_parse_int(raw: Option<&str>) -> Option<i64> {
    match raw {
        None => None,
        Some(s) if s.is_empty() => None,
        Some(s) => s.parse::<i64>().ok(),
    }
}

/// Formats an `int` for the store; `None` becomes `""` (clear, D4).
pub fn som_format_int(value: Option<i64>) -> String {
    match value {
        None => String::new(),
        Some(v) => v.to_string(),
    }
}

/// Parses a stored string as `double`, or `None` when absent/unparsable.
pub fn som_parse_double(raw: Option<&str>) -> Option<f64> {
    match raw {
        None => None,
        Some(s) if s.is_empty() => None,
        Some(s) => s.parse::<f64>().ok(),
    }
}

/// Formats a `double` for the store; `None` becomes `""` (clear, D4).
///
/// A `double` always renders with a decimal point (`2.0`), matching Dart's
/// `double.toString` — the store is language-neutral, so the same value must
/// serialize identically everywhere. Rust's `Display` for `f64` is the shortest
/// round-tripping form but drops the fraction of an integral value (`2`), so the
/// `.0` is re-attached here.
pub fn som_format_double(value: Option<f64>) -> String {
    let v = match value {
        None => return String::new(),
        Some(v) => v,
    };
    let text = v.to_string();
    if text.contains('.') || text.contains('e') || text.contains('E') || !v.is_finite() {
        text
    } else {
        format!("{}.0", text)
    }
}

/// Parses a stored string as `int` when integral, else `double`.
///
/// Mirrors Dart's `num.tryParse`: an integral literal yields an `int`, so `num`
/// fields keep the narrower type when the text carries no fraction.
pub fn som_parse_num(raw: Option<&str>) -> Option<SomNum> {
    let s = match raw {
        None => return None,
        Some(s) if s.is_empty() => return None,
        Some(s) => s,
    };
    if let Ok(n) = s.parse::<i64>() {
        return Some(SomNum::Int(n));
    }
    s.parse::<f64>().ok().map(SomNum::Double)
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
    match raw {
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
    match raw {
        Some(s) if values.iter().any(|v| v == s) => Some(s.to_string()),
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
