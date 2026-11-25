//! The reading notation's scanner (`spec_notation.rs`) beyond the shared
//! corpus: offsets are UTF-16 code units although Rust strings are UTF-8, so
//! a character outside the Basic Multilingual Plane counts twice — the offsets
//! below are the ones the JavaScript and TypeScript scanners report for the
//! same text (as the Python port's `spec_notation_test.py`).
//! `notation_cases.json` (run by the conformance runner) holds the grammar
//! itself.

use tom_som_rust_runtime as som;
use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::NotationFindingCode;

/// Two UTF-16 code units, four UTF-8 bytes, one `char`.
const EMOJI: &str = "\u{1F600}";

fn text() -> String {
    format!(
        "{e} [x{e}]{{.aside}} (-> {e}A)\n\n::: {{.rejected}}\n{e} {{++a [b]{{.trace}}++}} c\n:::\n::: {{.mine}}\n",
        e = EMOJI
    )
}

/// An element's type and UTF-16 range, with its children's.
type Shape<'a> = (&'a str, usize, usize, Vec<(&'a str, usize, usize)>);

#[test]
fn utf16_offsets() {
    let text = text();
    let scan = som::scan_notation(&text, true);
    let got: Vec<Shape> = scan
        .elements
        .iter()
        .map(|e| {
            (
                e.type_,
                e.start,
                e.end,
                e.children
                    .iter()
                    .map(|c| (c.type_, c.start, c.end))
                    .collect(),
            )
        })
        .collect();
    let want: Vec<Shape> = vec![
        ("span", 3, 16, vec![]),
        ("citation", 17, 25, vec![]),
        ("div", 27, 71, vec![("span", 51, 62)]),
        ("div", 72, 84, vec![]),
    ];
    assert_eq!(got, want);

    let span = scan.elements[0].to_json(&text);
    assert_eq!(
        span.get("source"),
        Some(&Json::Str(format!("[x{}]{{.aside}}", EMOJI)))
    );
    assert_eq!(span.get("content"), Some(&Json::Str(format!("x{}", EMOJI))));

    let findings: Vec<(NotationFindingCode, usize, usize)> = scan
        .findings
        .iter()
        .map(|f| (f.code, f.offset, f.line))
        .collect();
    assert_eq!(
        findings,
        vec![
            (NotationFindingCode::RejectedBlock, 27, 3),
            (NotationFindingCode::UnclosedDiv, 72, 6),
            (NotationFindingCode::UnknownKind, 72, 6),
        ]
    );
    assert!(scan.has_errors());
    let all: Vec<&str> = scan.all().iter().map(|e| e.type_).collect();
    assert_eq!(all, vec!["span", "citation", "div", "span", "div"]);
}

#[test]
fn vocabulary() {
    assert_eq!(
        som::notation_severity(NotationFindingCode::UnknownKind),
        "warning"
    );
    for code in NotationFindingCode::ALL {
        if code != NotationFindingCode::UnknownKind {
            assert_eq!(som::notation_severity(code), "error", "{:?}", code);
        }
        assert_eq!(NotationFindingCode::from_name(code.as_str()), Some(code));
    }
    let kinds = som::registered_notation_kinds();
    assert!(kinds.contains(&"linked"));
    assert!(kinds.contains(&"derived"));
    assert_eq!(kinds.len(), 9);
    let plain = som::scan_notation("::: {.mine}\n:::\n", false);
    assert!(plain.findings.is_empty(), "{:?}", plain.findings);
}

#[test]
fn rules_are_docspecs_rules() {
    for code in NotationFindingCode::ALL {
        assert!(
            som::DOCSPECS_ALL_RULES.contains(&code.as_str()),
            "{} is no DocSpecs rule",
            code.as_str()
        );
    }
}
