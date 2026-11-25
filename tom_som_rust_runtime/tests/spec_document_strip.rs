//! The strip of one value (SOM §11.10, `spec_document_strip.rs`) beyond the
//! shared corpus: UTF-16 offsets around supplementary characters (the corpus
//! has none), a refused value, the option sets' derived forms and
//! `count_annotations_text`; and the strip of a whole document over a model
//! nine sections deep: styled-div headings, the readable header, the appendix
//! and the strip's checks.
//!
//! Each expected result of a strip was produced by the JavaScript runtime (the
//! port of the TypeScript reference) for the same input; the Python runtime's
//! `spec_document_strip_test.py` holds the same values.

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::spec_review_annotations::SpecReviewAnnotations;
use tom_som_rust_runtime::{
    count_annotations_text, markdown_heading_div, markdown_heading_div_indent,
    parse_docspecs_document, spec_strip_kind_names, spec_strip_notation_kinds,
    strip_notation_text, SpecDocument, SpecDocumentMarkdown, SpecDocumentStrip,
    SpecDocumentStripOptions, SpecMarkdownExportOptions, SpecModel, SpecReadableHeader,
    SpecReadableSource, SpecStripFinding, SpecStripOptions, SpecStripTextResult,
    SpecStripValueRef, SPEC_MARKDOWN_APPENDIX_MARKER,
};

fn names(list: &[&str]) -> Vec<String> {
    list.iter().map(|s| s.to_string()).collect()
}

fn strip(text: &str, drop: &[&str], appendix: &[&str], references: bool) -> SpecStripTextResult {
    let options =
        SpecStripOptions::from_names(&names(drop), &[], &names(appendix), references, false)
            .expect("options");
    strip_notation_text(text, &options)
}

fn counts(pairs: &[(&str, i64)]) -> Vec<(String, i64)> {
    pairs.iter().map(|(k, n)| (k.to_string(), *n)).collect()
}

/// A piece as `(anchor, origin, removed, inserted, labels)`.
fn pieces(r: &SpecStripTextResult) -> Vec<(usize, usize, String, String, Vec<String>)> {
    r.pieces
        .iter()
        .map(|p| (p.anchor, p.origin, p.removed.clone(), p.inserted.clone(), p.labels.clone()))
        .collect()
}

fn piece(
    anchor: usize,
    origin: usize,
    removed: &str,
    inserted: &str,
    label: &str,
) -> (usize, usize, String, String, Vec<String>) {
    (anchor, origin, removed.to_string(), inserted.to_string(), vec![label.to_string()])
}

#[test]
fn astral_before_a_dropped_span() {
    let r = strip("😀 [x]{.aside} end", &["aside"], &[], false);
    assert_eq!(r.text, "😀 end");
    assert_eq!(r.dropped, counts(&[("aside", 1)]));
    assert_eq!(pieces(&r), vec![piece(2, 2, " [x]{.aside}", "", "aside:drop")]);
}

#[test]
fn astral_with_comments_dropped_and_appendix_references() {
    let note1 = "<a id=\"note-1-ref\"></a>[\\[1\\]](#note-1)";
    let note2 = "<a id=\"note-2-ref\"></a>[\\[2\\]](#note-2)";
    let r = strip(
        "😀 a\n\n::: {.provenance}\n𝔸 p\n:::\n\n> ⬆️ **C-1** (al): 𝔹 note\n\nb {++𝔸++} c [t]{.trace}",
        &["comments"],
        &["provenance", "trace"],
        true,
    );
    assert_eq!(r.text, format!("😀 a\n\n{}\n\nb 𝔸 c{}", note1, note2));
    assert_eq!(r.dropped, counts(&[("comments", 2)]));
    assert!(r.unmarked.is_empty());
    assert_eq!(r.appended, counts(&[("provenance", 1), ("trace", 1)]));
    assert_eq!(r.marks_dropped, 0);
    let appendix: Vec<(i64, String, String)> = r
        .appendix
        .iter()
        .map(|e| (e.number, e.kind.clone(), e.text.clone()))
        .collect();
    assert_eq!(
        appendix,
        vec![
            (1, "provenance".to_string(), "𝔸 p".to_string()),
            (2, "trace".to_string(), "t".to_string()),
        ]
    );
    assert_eq!(
        pieces(&r),
        vec![
            piece(6, 6, "::: {.provenance}\n𝔸 p\n:::", note1, "provenance:appendix"),
            piece(47, 34, "> ⬆️ **C-1** (al): 𝔹 note\n\n", "", "comments"),
            piece(49, 64, "{++", "", "comments"),
            piece(51, 69, "++}", "", "comments"),
            piece(53, 74, " [t]{.trace}", note2, "trace:appendix"),
        ]
    );
}

#[test]
fn astral_inside_review_marks() {
    let r = strip("x {--😀 [y]{.aside}--} z {~~𝔸 [q]{.aside}~>new~~}", &["aside"], &[], false);
    assert_eq!(r.text, "x {--😀--} z {~~𝔸~>new~~}");
    assert_eq!(r.dropped, counts(&[("aside", 2)]));
    assert_eq!(
        pieces(&r),
        vec![
            piece(7, 7, " [y]{.aside}", "", "aside:drop"),
            piece(18, 30, " [q]{.aside}", "", "aside:drop"),
        ]
    );
}

#[test]
fn refused_value() {
    let r = strip("a\n::: {.aside}\nunclosed", &["aside"], &[], false);
    assert!(r.refused());
    assert_eq!(r.text, "a\n::: {.aside}\nunclosed");
    assert!(r.pieces.is_empty());
    assert_eq!(
        r.to_json().get("refused"),
        Some(&Json::Array(vec![Json::Str("unclosedDiv".to_string())]))
    );
}

#[test]
fn options() {
    assert_eq!(spec_strip_kind_names().last(), Some(&"comments"));
    assert_eq!(spec_strip_notation_kinds().len(), 4);
    let o = SpecStripOptions::from_names(&["all"], &["aside"], &["trace"], false, false)
        .expect("options");
    assert_eq!(
        SpecStripOptions::ordered(&o.drop),
        names(&["provenance", "editorial", "linked", "derived", "comments"])
    );
    assert!(o.writes_no_linked_markers());
    assert!(o.writes_no_generated_parts());
    let k = o.keeping();
    assert_eq!(k.drop.iter().cloned().collect::<Vec<_>>(), names(&["comments"]));
    assert_eq!(
        k.unmark.iter().cloned().collect::<Vec<_>>(),
        names(&["aside", "derived", "editorial", "linked", "provenance", "trace"])
    );
    assert!(k.appendix.is_empty());
    let e = o.in_entry();
    assert!(!e.drop.contains("comments"));
    assert_eq!(e.unmark.iter().cloned().collect::<Vec<_>>(), names(&["aside", "trace"]));
    assert!(!SpecStripOptions::default().writes_no_linked_markers());
    let err = SpecStripOptions::from_names(&[] as &[&str], &[], &["linked"], false, false)
        .expect_err("linked to the appendix");
    assert!(err.to_string().starts_with("linked cannot"));
    let err = SpecStripOptions::from_names(&[] as &[&str], &[], &[], true, false)
        .expect_err("references without an appendix");
    assert_eq!(err.message, "appendix references need an appendix: name its kinds");
}

#[test]
fn count_annotations() {
    assert_eq!(count_annotations_text("> ⬆️ **C-1** (al): n\n\nx {++a++} {>>c<<}"), 3);
    assert_eq!(count_annotations_text("plain"), 0);
}

// ---------------------------------------------------------------------------
// The strip of a whole document: styled-div headings, the readable header and
// the document strip's checks, over a model nine sections deep — the port of
// the C++ `spec_document_strip_test.cpp` and the Python
// `spec_document_strip_test.py`. The corpus documents are the `documentCases`
// of `strip_cases.json`, run by tests/conformance.rs.

/// A model nine sections deep: `L<n>` holds content `T<n>` and section
/// `L<n+1>`, so `T<n>` stands at depth n + 1.
fn deep_model() -> SpecModel {
    let mut classes = Vec::new();
    for n in 1..=9 {
        let mut fields = format!(
            "{{\"name\":\"text\",\"kind\":\"content\",\"sectionId\":\"T{n}\",\"contentType\":\"text\"}}"
        );
        if n < 9 {
            let m = n + 1;
            fields.push_str(&format!(
                ",{{\"name\":\"next\",\"kind\":\"complex\",\"sectionId\":\"L{m}\",\"type\":\"L{m}\"}}"
            ));
        }
        let annotations = if n == 1 {
            "\"annotations\":[{\"name\":\"Document\",\"arguments\":{\"title\":\"Deep\"}},\
             {\"name\":\"SectionId\",\"arguments\":{\"id\":\"L1\"}}],"
        } else {
            ""
        };
        classes.push(format!(
            "\"L{n}\":{{\"name\":\"L{n}\",\"sectionId\":\"L{n}\",{annotations}\"fields\":[{fields}]}}"
        ));
    }
    let text = format!(
        "{{\"modelVersion\":1,\"modelVersionLabel\":\"0.1.0+1\",\
         \"roots\":[{{\"type\":\"L1\",\"title\":\"Deep\",\"sectionId\":\"L1\"}}],\
         \"classes\":{{{}}}}}",
        classes.join(",")
    );
    SpecModel::from_json_str(&text).expect("deep model")
}

/// `L1/…/L<n>[/T<n>]`.
fn path_to(n: usize, text: bool) -> String {
    let mut p: Vec<String> = (1..=n).map(|k| format!("L{k}")).collect();
    if text {
        p.push(format!("T{n}"));
    }
    p.join("/")
}

fn deep_document() -> SpecDocument {
    let mut d = SpecDocument::new();
    for n in 1..=9 {
        d.set_content(&path_to(n, true), &format!("Text {n} [an aside]{{.aside}}."));
    }
    d.set_headline(&path_to(7, false), "Seven & <more>\nsecond line");
    d.set_content(
        &path_to(8, true),
        "Before.\n\n<div class=\"heading9\" style=\"x\">Not a heading</div>\
         \n\n\\<div class=\"heading7\" style=\"x\">Escaped once</div>",
    );
    d
}

fn doc_json(d: &SpecDocument) -> String {
    d.to_json().to_canonical_json()
}

fn has_line(md: &str, line: &str) -> bool {
    md.split('\n').any(|l| l == line)
}

/// `md` reads back as `want` without a rejection.
fn assert_reads_back(name: &str, md: &str, model: &SpecModel, want: &SpecDocument) {
    let back = SpecDocument::from_markdown(md, model);
    assert!(back.rejections().is_empty(), "{name}: rejections {:?}", back.rejections());
    assert_eq!(doc_json(&back.document), doc_json(want), "{name}: reads back");
}

#[test]
fn heading_divs() {
    let model = deep_model();
    let root = model.root_by_type("L1").expect("root");
    let doc = deep_document();
    let options = SpecMarkdownExportOptions {
        heading_divs: true,
        readable_header: None,
    };
    let r = SpecDocumentMarkdown::new(&model, &doc)
        .export_root_with_options(root, &options)
        .expect("export");
    assert!(!r.markdown.split('\n').any(|l| l.starts_with("#######")), "no # heading deeper than 6");
    assert!(
        has_line(
            &r.markdown,
            "<div class=\"heading7\" style=\"margin:1em 0 0.5em;padding-left:0.75em;font-weight:bold\">\
             <!--[L7]--> <a id=\"L7\"></a> Seven &amp; &lt;more&gt;<br>second line</div>"
        ),
        "level 7 with the title escaped:\n{}",
        r.markdown
    );
    assert!(r
        .markdown
        .contains("<div class=\"heading10\" style=\"margin:1em 0 0.5em;padding-left:3em;"));
    assert!(has_line(&r.markdown, "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"));
    assert!(has_line(&r.markdown, "\\\\<div class=\"heading7\" style=\"x\">Escaped once</div>"));
    // Every heading is in the map, the div ones included.
    let mut headings = 0;
    let mut mapped = 0;
    for (i, l) in r.markdown.split('\n').enumerate() {
        if (l.starts_with('#') || l.starts_with("<div class=\"heading")) && l.contains("<!--[") {
            headings += 1;
            if r.heading_paths.contains_key(&(i + 1)) {
                mapped += 1;
            }
        }
    }
    assert!(headings > 9 && mapped == headings && mapped == r.heading_paths.len());
    assert_reads_back("divs", &r.markdown, &model, &doc);

    let plain = SpecDocumentMarkdown::new(&model, &doc).export_root(root).expect("export");
    assert!(plain.contains("####### <!--[L7]-->") && !plain.contains("\n<div class=\"heading7\""));
    assert!(has_line(&plain, "\\<div class=\"heading9\" style=\"x\">Not a heading</div>"));
    assert_reads_back("no divs", &plain, &model, &doc);

    let want = ["0.75", "1.5", "2.25", "3", "3.75", "4.5"];
    for (d, w) in (7..=12).zip(want) {
        assert_eq!(markdown_heading_div_indent(d), w);
    }
    assert_eq!(markdown_heading_div("<div class=\"heading6\">x</div>"), None);
    assert_eq!(
        markdown_heading_div("<div class=\"heading7\">a &amp;lt;</div>"),
        Some((7, "a &lt;".to_string()))
    );
}

#[test]
fn readable_header_appendix_and_checks() {
    let model = deep_model();
    let source = SpecReadableSource {
        file: "deep.tomspecs.yaml".to_string(),
        revision: Some("r3".to_string()),
        commit: Some("8e1d2a7".to_string()),
        dirty: true,
    };
    let mut extra = SpecDocumentStripOptions {
        model: Some(&model),
        source: Some(&source),
        ..Default::default()
    };
    let o = SpecStripOptions::from_names(&["aside"], &[], &[], false, true).expect("options");
    let mut doc = deep_document();
    let r = SpecDocumentStrip::strip(&doc, &o, &extra);
    let findings: Vec<String> = r.findings.iter().map(|f| f.to_string()).collect();
    assert!(r.ok(), "{findings:?}");
    assert_eq!(
        r.readable_header,
        "<!-- readable: drop=aside; headings=divs; of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->"
    );
    let readable = r.readable.clone().unwrap_or_default();
    let mut lines = readable.split('\n');
    assert!(lines.next().unwrap_or("").starts_with("<!-- docspec: "));
    assert_eq!(lines.next(), Some(r.readable_header.as_str()), "the header follows the docspec line");
    assert!(readable.contains("<div class=\"heading8\"") && !readable.contains("{.aside}"));
    let empty = SpecDocument::new();
    let parsed = SpecDocumentMarkdown::new(&model, &empty).parse(&readable);
    assert_eq!(parsed.readable_header.as_deref(), Some(r.readable_header.as_str()));
    let h = SpecReadableHeader::parse(&r.readable_header).expect("the header parses");
    assert_eq!(SpecReadableHeader::format(&h.options, h.source.as_ref()), r.readable_header);
    assert!(h.options.drop.contains("aside") && h.options.drop.len() == 1 && h.options.heading_divs);
    assert!(h.source.as_ref().is_some_and(|s| s.dirty));
    assert_reads_back("readable", &readable, &model, &r.document);

    // The appendix lists the moved prose under its section titles.
    let a = SpecStripOptions::from_names(&[], &[], &["aside"], true, true).expect("options");
    extra.source = None;
    let r = SpecDocumentStrip::strip(&doc, &a, &extra);
    assert!(r.ok());
    assert_eq!(r.appendix.len(), 8);
    for (i, e) in r.appendix.iter().enumerate() {
        let n = i + 1 + usize::from(i >= 7); // T8 holds no aside
        assert_eq!(e.number, i as i64 + 1);
        assert_eq!(e.value.as_ref().map(|v| v.path.clone()), Some(path_to(n, true)));
    }
    let text = r.readable.clone().unwrap_or_default();
    let marker = format!("{SPEC_MARKDOWN_APPENDIX_MARKER}\n");
    let at = text.find(&marker).expect("the appendix after its marker");
    let notes = &text[at + marker.len()..];
    assert!(notes.starts_with("\n## Notes\n"), "{notes}");
    assert_eq!(notes.matches("### Text\n").count(), 8);
    assert!(notes.contains("<a id=\"note-1\"></a>**[1]** an aside [\u{21a9}](#note-1-ref)"));
    assert_eq!(
        r.document.content_or(&path_to(1, true)),
        "Text 1<a id=\"note-1-ref\"></a>[\\[1\\]](#note-1)."
    );
    // The DocSpecs parse stops at the marker: no Notes section.
    let dd = parse_docspecs_document(&text);
    assert!(!dd.all_sections().iter().any(|s| s.title == "Notes"));
    // Nor does the markdown parse read it.
    assert_reads_back("appendix", &text, &model, &r.document);

    // A value with a notation error is refused and reported.
    doc.set_content(&path_to(2, true), "::: {.aside}\nopen");
    let r = SpecDocumentStrip::strip(&doc, &o, &extra);
    assert!(!r.ok());
    assert_eq!(r.findings.len(), 1);
    assert_eq!(r.findings[0].kind, "notation");
    assert!(r.findings[0].value.is_some());
    assert_eq!(r.document.content_or(&path_to(2, true)), "::: {.aside}\nopen");

    // Without a model nothing is rendered or checked.
    let every = SpecStripOptions::from_names(&["all"], &[], &[], false, false).expect("options");
    let r = SpecDocumentStrip::strip(&deep_document(), &every, &SpecDocumentStripOptions::default());
    assert!(r.readable.is_none());
    assert_eq!(r.document.content_or(&path_to(1, true)), "Text 1.");
    assert_eq!(r.report(), vec!["aside: 8 dropped, 0 unmarked, 0 moved".to_string()]);
}

#[test]
fn stripped_goes_through_the_strip() {
    let mut doc = SpecDocument::new();
    doc.set_content("L1/T1", "Keep {++this++}.\n\n> \u{2b06}\u{fe0f} **C-1** (Al): ok");
    doc.set_headline("L1/L2", "Two {--old--}");
    let s = SpecReviewAnnotations::new(&mut doc).stripped();
    assert_eq!(s.content_or("L1/T1"), "Keep this.");
    assert_eq!(s.headline_or("L1/L2"), "Two", "headlines too");
}

#[test]
fn value_refs_and_findings_print() {
    let headline = SpecStripValueRef {
        path: "A/B".to_string(),
        field: None,
        headline: true,
    };
    let field = SpecStripValueRef {
        path: "A/F".to_string(),
        field: Some("owner".to_string()),
        headline: false,
    };
    assert_eq!(headline.label(), "A/B (headline)");
    assert_eq!(field.label(), "A/F/owner");
    assert_eq!(
        field.to_json(),
        Json::parse("{\"path\":\"A/F\",\"field\":\"owner\"}").unwrap()
    );
    let f = SpecStripFinding {
        kind: "parse".to_string(),
        message: "m".to_string(),
        value: Some(field),
    };
    assert_eq!(f.to_string(), "parse: A/F/owner: m");
}
