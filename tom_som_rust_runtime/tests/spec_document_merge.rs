//! The merge back (SOM §11.10, `spec_document_merge.rs`) beyond the shared
//! corpus: properties over the strip corpus, the report lines of a conflict,
//! text beyond ASCII and the base read from git — what
//! `strip_merge_cases.json` (run by `tests/conformance.rs`) does not reach.
//! The port of the Python runtime's `spec_document_merge_test.py` (itself the
//! port of Java's and TypeScript's), with the non-ASCII cases of the C++
//! runtime's test, whose expectations were computed with the TypeScript
//! runtime: offsets and excerpts in UTF-16 code units.
//!
//! The git checks build their own scratch repository in the system temp
//! directory, delete it afterwards and are skipped when no `git` can be run.

use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::{
    annotation_issues_text, merge_stripped_value, spec_strip_merge_label, strip_notation_text,
    SpecStripMerge, SpecStripOptions, SpecStripValueRef,
};

fn names(list: &[&str]) -> Vec<String> {
    list.iter().map(|s| s.to_string()).collect()
}

fn drop(list: &[&str]) -> SpecStripOptions {
    SpecStripOptions::from_names(&names(list), &[], &[], false, false).expect("options")
}

fn unmark(list: &[&str]) -> SpecStripOptions {
    SpecStripOptions::from_names(&[], &names(list), &[], false, false).expect("options")
}

fn value(path: &str, field: Option<&str>, headline: bool) -> SpecStripValueRef {
    SpecStripValueRef {
        path: path.to_string(),
        field: field.map(str::to_string),
        headline,
    }
}

fn str_list(v: Option<&Json>) -> Vec<String> {
    match v {
        Some(Json::Array(a)) => a
            .iter()
            .filter_map(|x| x.as_str().map(str::to_string))
            .collect(),
        _ => Vec::new(),
    }
}

/// Every value case of the strip corpus merges back unchanged, and with a
/// paragraph added.
#[test]
fn over_strip_cases() {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../tom_som_conformance/corpus/strip_cases.json");
    let table =
        Json::parse(&std::fs::read_to_string(path).expect("strip_cases.json")).expect("json");
    let Some(Json::Array(cases)) = table.get("cases") else {
        panic!("no cases");
    };
    assert!(!cases.is_empty());
    for case in cases {
        let name = case.get("name").and_then(|v| v.as_str()).unwrap_or("");
        let o = case.get("text").and_then(|v| v.as_str()).unwrap_or("");
        let opts = SpecStripOptions::from_names(
            &str_list(case.get("drop")),
            &str_list(case.get("unmark")),
            &str_list(case.get("appendix")),
            case.get("appendixReferences").and_then(|v| v.as_bool()) == Some(true),
            case.get("headingDivs").and_then(|v| v.as_bool()) == Some(true),
        )
        .expect("options");
        let s = strip_notation_text(o, &opts);
        if s.refused() {
            continue;
        }
        let same = merge_stripped_value(o, &s.text, &s.text, &s.pieces);
        assert!(
            same.text.as_deref() == Some(o)
                && same.restored == s.pieces.len()
                && same.placed.is_empty(),
            "unchanged[{}]",
            name
        );
        let e = if s.text.is_empty() {
            "An added paragraph.".to_string()
        } else {
            format!("{}\n\nAn added paragraph.", s.text)
        };
        let r = merge_stripped_value(o, &s.text, &e, &s.pieces);
        assert!(
            r.ok() && strip_notation_text(r.text.as_deref().unwrap_or(""), &opts).text == e,
            "addedParagraph[{}]: {:?}",
            name,
            r.to_json()
        );
    }
}

#[test]
fn values() {
    let o = "Keep this. Gone here (-> C1). Tail.";
    let s = strip_notation_text(o, &drop(&["trace"]));
    let r = merge_stripped_value(o, &s.text, "Keep this. Tail.", &s.pieces);
    assert!(!r.ok() && r.text.is_none());
    assert_eq!(r.conflicts.len(), 1);
    assert_eq!(r.conflicts[0].code, "sentenceRemoved");
    assert_eq!(
        r.conflicts[0]
            .about(&value("DEMO/SUM", None, false))
            .report_lines(),
        vec![
            "CONFLICT DEMO/SUM \u{2014} the edit removed the whole sentence holding the piece",
            "  O: \u{ab}Keep this. Gone here (-> C1). Tail.\u{bb}",
            "  B: \u{ab}Keep this. Gone here. Tail.\u{bb}",
            "  E: \u{ab}Keep this. Tail.\u{bb}",
            "  piece: \u{ab} (-> C1)\u{bb}",
        ]
    );

    let o2 = "Alpha (-> A1). Beta [aside]{.aside} gamma (-> B2).";
    let opts = drop(&["trace", "aside"]);
    let s2 = strip_notation_text(o2, &opts);
    let e2 = s2.text.replace("Alpha", "First");
    let r2 = merge_stripped_value(o2, &s2.text, &e2, &s2.pieces);
    assert_eq!(
        r2.text.as_deref(),
        Some("First (-> A1). Beta [aside]{.aside} gamma (-> B2).")
    );
    assert_eq!(r2.restored, 3);
    assert_eq!(
        strip_notation_text(r2.text.as_deref().unwrap(), &opts).text,
        e2
    );
}

/// A value beyond ASCII, one edit, and what the merge gives.
struct NonAscii {
    original: &'static str,
    drop: bool,
    name: &'static str,
    find: &'static str,
    replace: &'static str,
    text: Option<&'static str>,
    restored: usize,
    placed: Option<(usize, &'static str)>,
    conflict: Option<&'static str>,
    lines: &'static [&'static str],
}

const NON_ASCII: &[NonAscii] = &[
    NonAscii {
        original: "Die Größe ist hoch (-> C2.1).",
        drop: true,
        name: "trace",
        find: "hoch",
        replace: "stark gestiegen \u{1F600}",
        text: Some("Die Größe ist stark gestiegen \u{1F600} (-> C2.1)."),
        restored: 1,
        placed: Some((32, " (-> C2.1)")),
        conflict: None,
        lines: &[],
    },
    NonAscii {
        original: "Ein \u{1F600} [schnelles braunes]{.aside} Tier läuft.",
        drop: false,
        name: "aside",
        find: "braunes Tier",
        replace: "Wesen",
        text: None,
        restored: 0,
        placed: None,
        conflict: Some("crossesBoundary"),
        lines: &[
            "CONFLICT (document) \u{2014} an edit crosses the boundary of an unmarked element",
            "  O: \u{ab}Ein \u{1F600} [schnelles braunes]{.aside} Tier läuft.\u{bb}",
            "  B: \u{ab}Ein \u{1F600} schnelles braunes Tier läuft.\u{bb}",
            "  E: \u{ab}Ein \u{1F600} schnelles Wesen läuft.\u{bb}",
            "  piece: \u{ab}]{.aside}\u{bb}",
        ],
    },
    NonAscii {
        original: "Ä Wort{>>Bemerkung über Öl<<} hier.",
        drop: true,
        name: "comments",
        find: "Wort",
        replace: "Begriff",
        text: Some("Ä Begriff{>>Bemerkung über Öl<<} hier."),
        restored: 2,
        placed: None,
        conflict: None,
        lines: &[],
    },
    NonAscii {
        original: "Größe [weil \u{1F600} so]{.aside} gilt.\n\nZweiter Absatz.",
        drop: true,
        name: "aside",
        find: "gilt",
        replace: "bleibt",
        text: Some("Größe [weil \u{1F600} so]{.aside} bleibt.\n\nZweiter Absatz."),
        restored: 1,
        placed: None,
        conflict: None,
        lines: &[],
    },
    NonAscii {
        original: "Ein äöüäöüäöüäöüäöüäöü langer Satz mit [schnelles braunes]{.aside} Tier und \
                   noch viel mehr Text danach äöü.",
        drop: false,
        name: "aside",
        find: "braunes Tier",
        replace: "Wesen",
        text: None,
        restored: 0,
        placed: None,
        conflict: Some("crossesBoundary"),
        lines: &[
            "CONFLICT (document) \u{2014} an edit crosses the boundary of an unmarked element",
            "  O: \u{ab}er Satz mit [schnelles braunes]{.aside} Tier und noch viel m\u{bb}",
            "  B: \u{ab}ger Satz mit schnelles braunes Tier und noch viel mehr Text \u{bb}",
            "  E: \u{ab}äöü langer Satz mit schnelles Wesen und noch viel mehr Text \u{bb}",
            "  piece: \u{ab}]{.aside}\u{bb}",
        ],
    },
];

#[test]
fn non_ascii() {
    for (i, c) in NON_ASCII.iter().enumerate() {
        let o = if c.drop {
            drop(&[c.name])
        } else {
            unmark(&[c.name])
        };
        let st = strip_notation_text(c.original, &o);
        assert!(st.text.contains(c.find), "nonAscii {}: the edit applies", i);
        let edited = st.text.replacen(c.find, c.replace, 1);
        let m = merge_stripped_value(c.original, &st.text, &edited, &st.pieces);
        assert_eq!(m.text.as_deref(), c.text, "nonAscii {}: text", i);
        assert_eq!(m.restored, c.restored, "nonAscii {}: restored", i);
        match c.placed {
            None => assert!(m.placed.is_empty(), "nonAscii {}: placed", i),
            Some((at, removed)) => {
                assert_eq!(m.placed.len(), 1, "nonAscii {}: placed", i);
                assert_eq!(m.placed[0].at, at, "nonAscii {}: placed at", i);
                assert_eq!(
                    m.placed[0].piece.removed, removed,
                    "nonAscii {}: placed piece",
                    i
                );
            }
        }
        match c.conflict {
            None => assert!(m.conflicts.is_empty(), "nonAscii {}: conflicts", i),
            Some(code) => {
                assert_eq!(m.conflicts.len(), 1, "nonAscii {}: conflicts", i);
                assert_eq!(m.conflicts[0].code, code, "nonAscii {}: conflict code", i);
                assert_eq!(
                    m.conflicts[0].report_lines(),
                    c.lines,
                    "nonAscii {}: report lines",
                    i
                );
            }
        }
    }
}

#[test]
fn labels() {
    assert_eq!(spec_strip_merge_label(&value("A/B", None, false)), "A/B");
    assert_eq!(
        spec_strip_merge_label(&value("A/B", Some("f"), false)),
        "A/B / f"
    );
    assert_eq!(
        spec_strip_merge_label(&value("A/B", None, true)),
        "A/B (headline)"
    );
}

#[test]
fn annotation_issues() {
    assert!(annotation_issues_text("A {++b++} c.").is_empty());
    assert_eq!(
        annotation_issues_text("x {++ open"),
        vec!["line 0: inline mark \"{++\" is not closed in its paragraph (SOM §11.9.3)"]
    );
}

/// Runs git in `folder`; false when it fails or cannot be run.
fn git(folder: &Path, args: &[&str]) -> bool {
    Command::new("git")
        .args(args)
        .current_dir(folder)
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

/// Deletes the scratch repository however the test ends.
struct Scratch(PathBuf);

impl Drop for Scratch {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

/// The base read from git, in a scratch repository of the test's own.
#[test]
fn git_show_file() {
    let stamp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_or(0, |d| d.as_nanos());
    let repo = std::env::temp_dir().join(format!(
        "tom_som_rust_merge_test_{}_{}",
        std::process::id(),
        stamp
    ));
    std::fs::create_dir_all(repo.join("sub")).expect("scratch folder");
    let scratch = Scratch(repo);
    let repo = &scratch.0;
    let doc = repo.join("doc.md");
    let inner = repo.join("sub").join("inner.md");
    std::fs::write(&doc, "first ä\n").expect("doc.md");
    std::fs::write(&inner, "inner\n").expect("inner.md");
    let made = git(repo, &["init", "-q"])
        && git(repo, &["add", "doc.md", "sub/inner.md"])
        && git(
            repo,
            &[
                "-c",
                "user.name=test",
                "-c",
                "user.email=test@example.invalid",
                "-c",
                "commit.gpgsign=false",
                "-c",
                "core.hooksPath=/dev/null",
                "commit",
                "-q",
                "-m",
                "first",
            ],
        );
    if !made {
        eprintln!("SKIP: git_show_file (no git, or the scratch repository could not be made)");
        return;
    }
    std::fs::write(&doc, "second\n").expect("doc.md");
    let doc_s = doc.to_str().expect("path");
    assert_eq!(
        SpecStripMerge::git_show_file(Some("HEAD"), doc_s).as_deref(),
        Some("first ä\n"),
        "the committed text, not the working tree's"
    );
    assert_eq!(
        SpecStripMerge::git_show_file(Some("HEAD"), inner.to_str().expect("path")).as_deref(),
        Some("inner\n"),
        "a file in a folder is read from its folder"
    );
    assert_eq!(
        SpecStripMerge::git_show_file(Some(&"0".repeat(40)), doc_s),
        None,
        "an unknown commit gives none"
    );
    assert_eq!(
        SpecStripMerge::git_show_file(Some("HEAD"), &format!("{}x", doc_s)),
        None,
        "an unknown file gives none"
    );
    let missing = repo.join("none").join("doc.md");
    assert_eq!(
        SpecStripMerge::git_show_file(Some("HEAD"), missing.to_str().expect("path")),
        None,
        "a missing folder gives none"
    );
    assert_eq!(
        SpecStripMerge::git_show_file(Some("--stat"), doc_s),
        None,
        "a commit that reads as an option gives none"
    );
    assert_eq!(
        SpecStripMerge::git_show_file(Some(""), doc_s),
        None,
        "an empty commit gives none"
    );
    assert_eq!(
        SpecStripMerge::git_show_file(None, doc_s),
        None,
        "no commit gives none"
    );
}
