//! Tests for the DocSpecs-conform Markdown codec (`spec_document_markdown.rs`,
//! DR6 / DR1 §1 — DR26) — a port of
//! `tom_som_go_runtime/tests/spec_document_markdown_test.go` (itself a port of
//! the TypeScript/Python/Dart reference suite).
//!
//! The generated `*.md` is a genuine DocSpecs document: line 1 is the
//! `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
//! section is a heading of the form `## <!--[SECTION-ID]--> Title`, content
//! sections are normal markdown text (no fences), `@Form` sections use the
//! plain-text `FieldName: value` format, and list items sit as sub-headings
//! directly under the owner (no container heading).
//!
//! The model fixture (`demo_model`) and populated document
//! (`populated_demo_doc`) mirror the Go suite's `item12_test.go` fixtures
//! (whose own tests already exist in Rust as inline unit tests in
//! `spec_model.rs` / `spec_document.rs`).

use std::collections::BTreeMap;

use tom_som_rust_runtime::{
    DocumentJson, SpecDocument, SpecDocumentMarkdown, SpecMarkdownResult, SpecModel,
    SPEC_MARKDOWN_REJECT_KIND_MISMATCH, SPEC_MARKDOWN_REJECT_MALFORMED_HEADING,
    SPEC_MARKDOWN_REJECT_MISSING_VALUE, SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT,
    SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION,
};

struct Checker {
    passed: usize,
    failed: Vec<String>,
}

impl Checker {
    fn new() -> Checker {
        Checker {
            passed: 0,
            failed: Vec::new(),
        }
    }

    fn check(&mut self, name: &str, cond: bool, detail: &str) {
        if cond {
            self.passed += 1;
        } else if detail.is_empty() {
            self.failed.push(name.to_string());
        } else {
            self.failed.push(format!("{}: {}", name, detail));
        }
    }

    fn finish(&self) {
        let total = self.passed + self.failed.len();
        if !self.failed.is_empty() {
            for f in &self.failed {
                eprintln!("  - {}", f);
            }
            panic!("FAIL: {}/{} checks failed", self.failed.len(), total);
        }
        println!("OK: {} checks passed", total);
    }
}

// --- fixtures (shared with the Go suite's item12_test.go) --------------------

/// The single-root DemoDoc fixture covering content, enum, @Form, a complex
/// sub-section, and a list of complex items.
const DEMO_MODEL_JSON: &str = r#"{
  "roots": [
    {"type": "DemoDoc", "title": "Demo Document", "sectionId": "D00", "description": "A demo document."}
  ],
  "classes": {
    "DemoDoc": {
      "name": "DemoDoc",
      "sectionId": "D00",
      "fields": [
        {"name": "overview", "kind": "content", "sectionId": "D00-OVR"},
        {"name": "status", "kind": "enum", "sectionId": "D00-ST", "enumValues": ["draft", "final"]},
        {"name": "header", "kind": "form", "sectionId": "D00-HDR",
         "formFields": [
           {"name": "author", "label": "Author", "type": "String"},
           {"name": "reviewer", "label": "Reviewer", "type": "String"}
         ]},
        {"name": "meta", "kind": "complex", "type": "DemoMeta", "sectionId": "D00-MET"},
        {"name": "items", "kind": "list", "elementType": "DemoItem", "elementIsComplex": true, "sectionId": "D00-ITM"}
      ]
    },
    "DemoMeta": {
      "name": "DemoMeta",
      "sectionId": "D00-MET",
      "fields": [
        {"name": "note", "kind": "content", "sectionId": "D00-MET-NOTE"}
      ]
    },
    "DemoItem": {
      "name": "DemoItem",
      "fields": [
        {"name": "label", "kind": "content", "sectionId": "D01-LBL"},
        {"name": "body", "kind": "content", "sectionId": "D01-BODY"}
      ]
    }
  }
}"#;

/// A d4rt-flutter body that is multi-line and embeds a run of three backticks
/// mid-line — must pass through the plain-text body verbatim.
const MD_D4RT_BODY: &str = "Column(\n  children: [\n    Text(\"hi\"),\n  ],\n) // not a fence: ``` still inside the body";

/// Exercises embedded markdown formatting: emphasis, a bullet list, a fenced
/// code block containing heading-like lines, and a leading `#` line at column
/// 0 (which the emitter escapes as `\#`).
const MD_RICH_MARKDOWN: &str = "Intro with **bold** and *italic*.\n\n- first bullet\n- second bullet\n\n```dart\n# not a heading — shielded by the fence\n## also shielded\nvoid main() {}\n```\n\n# looks like a heading at column 0\ntrailing paragraph";

fn demo_model() -> SpecModel {
    SpecModel::from_json_str(DEMO_MODEL_JSON).expect("demo model parses")
}

/// Mirrors the Dart `_populated()` helper (and Go's populatedDemoDoc).
fn populated_demo_doc() -> SpecDocument {
    let mut doc = SpecDocument::new();
    doc.set_content("D00/D00-OVR", "An overview paragraph.\nWith two lines.");
    doc.set_content("D00/D00-ST", "final");
    doc.set_form_field("D00/D00-HDR", "author", "Ada Lovelace");
    doc.set_content("D00/D00-MET/D00-MET-NOTE", "A note.");
    let item = doc.add_list_item("D00/D00-ITM");
    doc.set_content(&format!("{}/D01-LBL", item), "First item");
    doc.set_content(&format!("{}/D01-BODY", item), MD_D4RT_BODY);
    let item2 = doc.add_list_item("D00/D00-ITM");
    doc.set_content(&format!("{}/D01-LBL", item2), "Second item");
    doc
}

fn md_export(doc: &SpecDocument) -> String {
    let model = demo_model();
    SpecDocumentMarkdown::new(&model, doc)
        .export_root(&model.roots[0])
        .expect("export_root")
}

/// Parses md into a fresh document via the staged-values report.
fn md_reload(md: &str) -> (SpecDocument, SpecMarkdownResult) {
    let model = demo_model();
    let mut target = SpecDocument::new();
    let report = SpecDocumentMarkdown::new(&model, &target).parse(md);
    target.load_json(&DocumentJson {
        content: report.content.clone(),
        forms: report.forms.clone(),
        lists: report.lists.clone(),
    });
    (target, report)
}

fn md_parse(md: &str) -> SpecMarkdownResult {
    let model = demo_model();
    let doc = SpecDocument::new();
    SpecDocumentMarkdown::new(&model, &doc).parse(md)
}

fn md_rej_str(report: &SpecMarkdownResult) -> String {
    report
        .rejections
        .iter()
        .map(|r| r.to_display())
        .collect::<Vec<String>>()
        .join("; ")
}

fn md_shallow_equal(a: Option<&BTreeMap<String, String>>, b: &[(&str, &str)]) -> bool {
    match a {
        None => false,
        Some(m) => {
            m.len() == b.len() && b.iter().all(|(k, v)| m.get(*k).map(String::as_str) == Some(*v))
        }
    }
}

// --- export — DocSpecs format (DR1 §1) ---------------------------------------

fn test_markdown_export_format(c: &mut Checker) {
    let md = md_export(&populated_demo_doc());
    let first = md.split('\n').next().unwrap_or("");
    c.check(
        "export.docspec.prefix",
        first.starts_with("<!-- docspec: demo-document/"),
        first,
    );
    c.check("export.docspec.suffix", first.ends_with("-->"), first);

    c.check(
        "export.heading.root",
        md.contains("# <!--[D00]--> Demo Document"),
        "",
    );
    c.check(
        "export.heading.overview",
        md.contains("## <!--[D00-OVR]--> Overview"),
        "",
    );
    c.check(
        "export.heading.status",
        md.contains("## <!--[D00-ST]--> Status"),
        "",
    );
    c.check(
        "export.heading.header",
        md.contains("## <!--[D00-HDR]--> Header"),
        "",
    );
    c.check(
        "export.heading.meta",
        md.contains("## <!--[D00-MET]--> Meta"),
        "",
    );
    c.check(
        "export.heading.note",
        md.contains("### <!--[D00-MET-NOTE]--> Note"),
        "",
    );

    c.check(
        "export.content.plain",
        md.contains("An overview paragraph.\nWith two lines."),
        "",
    );
    let mut no_fence = true;
    for l in md.split('\n') {
        if l.starts_with("```") {
            no_fence = false;
        }
    }
    c.check("export.content.noFence", no_fence, "");
    c.check("export.content.noFieldAnchor", !md.contains("<!-- field:"), "");
    c.check("export.content.noPathHeading", !md.contains("D00/D00-OVR"), "");

    c.check(
        "export.form.sparse.author",
        md.contains("Author: Ada Lovelace"),
        "",
    );
    c.check("export.form.sparse.noReviewer", !md.contains("Reviewer"), "");

    c.check(
        "export.item.1",
        md.contains("## <!--[items-1]--> Demo Item 1"),
        "",
    );
    c.check(
        "export.item.2",
        md.contains("## <!--[items-2]--> Demo Item 2"),
        "",
    );
    c.check(
        "export.item.label",
        md.contains("### <!--[D01-LBL]--> Label"),
        "",
    );
    c.check("export.item.noContainer", !md.contains("<!--[D00-ITM]-->"), "");

    c.check(
        "export.noSchemaDescription",
        !md.contains("A demo document."),
        "",
    );
}

fn test_markdown_export_stored_item_id(c: &mut Checker) {
    let mut doc = SpecDocument::new();
    let item = doc
        .add_list_item_with_section_id("D00/D00-ITM", "D01-CUSTOM")
        .expect("add_list_item_with_section_id");
    doc.set_content(&format!("{}/D01-LBL", item), "Custom-id item");
    let md = md_export(&doc);
    c.check(
        "export.storedId.custom",
        md.contains("## <!--[D01-CUSTOM]--> Demo Item 1"),
        &md,
    );
    c.check(
        "export.storedId.noAnonymous",
        !md.contains("<!--[items-1]-->"),
        "",
    );
}

fn test_markdown_export_unterm_fence_errors(c: &mut Checker) {
    let mut doc = SpecDocument::new();
    doc.set_content("D00/D00-OVR", "before\n```dart\nnever closed");
    let model = demo_model();
    let result = SpecDocumentMarkdown::new(&model, &doc).export_root(&model.roots[0]);
    c.check(
        "export.untermFence.raises",
        matches!(&result, Err(e) if e.contains("unterminated")),
        &format!("{:?}", result),
    );
}

// --- SpecDocument::to_markdown (item 12) --------------------------------------

fn test_markdown_to_markdown(c: &mut Checker) {
    let model = demo_model();
    let doc = populated_demo_doc();
    let one_liner = doc
        .to_markdown(&model, Some("DemoDoc"))
        .expect("to_markdown(DemoDoc)");
    let root = model.root_by_type("DemoDoc").expect("root_by_type(DemoDoc)");
    let explicit = SpecDocumentMarkdown::new(&model, &doc)
        .export_root(root)
        .expect("export_root(DemoDoc)");
    c.check("toMarkdown.explicitRoot", one_liner == explicit, "");
    let def = doc.to_markdown(&model, None).expect("to_markdown(default)");
    c.check("toMarkdown.defaultRoot", def == one_liner, "");
    let empty_err = SpecDocument::new().to_markdown(&model, None);
    c.check(
        "toMarkdown.emptyThrows",
        matches!(&empty_err, Err(e) if e.contains("no populated root")),
        &format!("{:?}", empty_err),
    );

    let two_model = SpecModel::from_json_str(
        r#"{
  "roots": [
    {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
    {"type": "Beta",  "title": "Beta Doc",  "sectionId": "B00"}
  ],
  "classes": {
    "Alpha": {"name": "Alpha", "sectionId": "A00",
      "fields": [{"name": "overview", "kind": "content", "sectionId": "A00-OVR"}]},
    "Beta": {"name": "Beta", "sectionId": "B00",
      "fields": [{"name": "overview", "kind": "content", "sectionId": "B00-OVR"}]}
  }
}"#,
    )
    .expect("two-root model parses");
    let mut doc2 = SpecDocument::new();
    doc2.set_content("A00/A00-OVR", "a");
    doc2.set_content("B00/B00-OVR", "b");
    let two_err = doc2.to_markdown(&two_model, None);
    c.check(
        "toMarkdown.twoRootsThrows.alpha",
        matches!(&two_err, Err(e) if e.contains("Alpha")),
        &format!("{:?}", two_err),
    );
    c.check(
        "toMarkdown.twoRootsThrows.beta",
        matches!(&two_err, Err(e) if e.contains("Beta")),
        &format!("{:?}", two_err),
    );
}

// --- round-trip ----------------------------------------------------------------

fn test_markdown_round_trip_values(c: &mut Checker) {
    let md = md_export(&populated_demo_doc());
    let (target, report) = md_reload(&md);
    c.check("roundTrip.clean", report.is_clean(), &md_rej_str(&report));
    c.check(
        "roundTrip.overview",
        target.content_or("D00/D00-OVR") == "An overview paragraph.\nWith two lines.",
        "",
    );
    c.check("roundTrip.status", target.content_or("D00/D00-ST") == "final", "");
    c.check(
        "roundTrip.author",
        target.form_field_or("D00/D00-HDR", "author") == "Ada Lovelace",
        "",
    );
    c.check(
        "roundTrip.note",
        target.content_or("D00/D00-MET/D00-MET-NOTE") == "A note.",
        "",
    );
    let items = target.list_items("D00/D00-ITM");
    c.check(
        "roundTrip.itemCount",
        items.len() == 2,
        &format!("{:?}", items),
    );
    if items.len() == 2 {
        c.check(
            "roundTrip.item1.label",
            target.content_or(&format!("{}/D01-LBL", items[0])) == "First item",
            "",
        );
        // The embedded d4rt body survives verbatim, backticks and all.
        c.check(
            "roundTrip.item1.body",
            target.content_or(&format!("{}/D01-BODY", items[0])) == MD_D4RT_BODY,
            &format!("{:?}", target.content_or(&format!("{}/D01-BODY", items[0]))),
        );
        c.check(
            "roundTrip.item2.label",
            target.content_or(&format!("{}/D01-LBL", items[1])) == "Second item",
            "",
        );
    }
}

fn test_markdown_round_trip_byte_stable(c: &mut Checker) {
    let md1 = md_export(&populated_demo_doc());
    let (reloaded, _) = md_reload(&md1);
    let md2 = md_export(&reloaded);
    c.check("roundTrip.byteStable", md2 == md1, "");
}

fn test_markdown_round_trip_rich_markdown(c: &mut Checker) {
    let mut doc = SpecDocument::new();
    doc.set_content("D00/D00-OVR", MD_RICH_MARKDOWN);
    let md1 = md_export(&doc);
    // Fence-shielded heading-like lines are NOT escaped; the column-0 `#` line
    // outside the fence IS.
    c.check(
        "richMd.fenceShielded",
        md1.contains("\n# not a heading — shielded by the fence\n"),
        "",
    );
    c.check(
        "richMd.escapedHeading",
        md1.contains("\n\\# looks like a heading at column 0\n"),
        "",
    );

    let (reloaded, report) = md_reload(&md1);
    c.check("richMd.clean", report.is_clean(), &md_rej_str(&report));
    c.check(
        "richMd.value",
        reloaded.content_or("D00/D00-OVR") == MD_RICH_MARKDOWN,
        &format!("{:?}", reloaded.content_or("D00/D00-OVR")),
    );
    c.check("richMd.byteStable", md_export(&reloaded) == md1, "");
}

fn test_markdown_round_trip_stored_item_id(c: &mut Checker) {
    let mut doc = SpecDocument::new();
    let item = doc
        .add_list_item_with_section_id("D00/D00-ITM", "D01-CUSTOM")
        .expect("add_list_item_with_section_id");
    doc.set_content(&format!("{}/D01-LBL", item), "Custom-id item");
    let md1 = md_export(&doc);
    let (reloaded, report) = md_reload(&md1);
    c.check("storedId.clean", report.is_clean(), &md_rej_str(&report));
    let items = reloaded.list_items("D00/D00-ITM");
    c.check("storedId.itemCount", items.len() == 1, &format!("{:?}", items));
    if items.len() == 1 {
        c.check(
            "storedId.sectionId",
            reloaded.item_section_id_or(&items[0]) == "D01-CUSTOM",
            &reloaded.item_section_id_or(&items[0]),
        );
        c.check(
            "storedId.label",
            reloaded.content_or(&format!("{}/D01-LBL", items[0])) == "Custom-id item",
            "",
        );
    }
    c.check("storedId.byteStable", md_export(&reloaded) == md1, "");
}

fn test_markdown_round_trip_label_shaped_continuation(c: &mut Checker) {
    let mut doc = SpecDocument::new();
    doc.set_form_field(
        "D00/D00-HDR",
        "author",
        "Ada Lovelace\nNote: also a mathematician\nplain line",
    );
    let md1 = md_export(&doc);
    // The label-shaped continuation is space-escaped on emit.
    c.check(
        "formCont.escaped",
        md1.contains("\n Note: also a mathematician\n"),
        &md1,
    );

    let (reloaded, report) = md_reload(&md1);
    c.check("formCont.clean", report.is_clean(), &md_rej_str(&report));
    c.check(
        "formCont.value",
        reloaded.form_field_or("D00/D00-HDR", "author")
            == "Ada Lovelace\nNote: also a mathematician\nplain line",
        &format!("{:?}", reloaded.form_field_or("D00/D00-HDR", "author")),
    );
    c.check("formCont.byteStable", md_export(&reloaded) == md1, "");
}

// --- parse-rejection protocol (DR1 §1.7) ----------------------------------------

fn test_markdown_reject_unknown_section(c: &mut Checker) {
    // The bogus heading is nested under `meta` (which has no list children);
    // directly under the root any unresolved id would be absorbed by the
    // single-list-child fallback as a stored-id item.
    let md = "<!-- docspec: demo-document/1.0 -->\n\
# <!--[D00]--> Demo Document\n\n\
## <!--[D00-OVR]--> Overview\n\n\
kept\n\n\
## <!--[D00-MET]--> Meta\n\n\
### <!--[D00-NOPE]--> Bogus\n\n\
dropped\n";
    let report = md_parse(md);
    c.check("reject.unknown.dirty", !report.is_clean(), "");
    let found = report
        .rejections
        .iter()
        .any(|r| r.anchor == "D00-NOPE" && r.reason == SPEC_MARKDOWN_REJECT_UNKNOWN_SECTION);
    c.check("reject.unknown.reason", found, &md_rej_str(&report));
    c.check(
        "reject.unknown.siblingsKept",
        report.content.get("D00/D00-OVR").map(String::as_str) == Some("kept"),
        "",
    );
}

fn test_markdown_reject_malformed_heading(c: &mut Checker) {
    let md = "<!-- docspec: demo-document/1.0 -->\n\
# <!--[D00]--> Demo Document\n\n\
## Overview without an id comment\n\n\
lost\n";
    let report = md_parse(md);
    let found = report
        .rejections
        .iter()
        .any(|r| r.reason == SPEC_MARKDOWN_REJECT_MALFORMED_HEADING);
    c.check("reject.malformed.reason", found, &md_rej_str(&report));
    c.check(
        "reject.malformed.noContent",
        report.content.is_empty(),
        &format!("{:?}", report.content),
    );
}

fn test_markdown_reject_orphan_preamble(c: &mut Checker) {
    let md = "stray preamble text\n\
# <!--[D00]--> Demo Document\n\n\
## <!--[D00-OVR]--> Overview\n\n\
kept\n";
    let report = md_parse(md);
    let found = report
        .rejections
        .iter()
        .any(|r| r.reason == SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT);
    c.check("reject.orphanPreamble.reason", found, &md_rej_str(&report));
    c.check(
        "reject.orphanPreamble.kept",
        report.content.get("D00/D00-OVR").map(String::as_str) == Some("kept"),
        "",
    );
}

fn test_markdown_reject_orphan_form_prose(c: &mut Checker) {
    let md = "# <!--[D00]--> Demo Document\n\n\
## <!--[D00-HDR]--> Header\n\n\
prose before any field label\n\
Author: Ada Lovelace\n";
    let report = md_parse(md);
    let found = report
        .rejections
        .iter()
        .any(|r| r.reason == SPEC_MARKDOWN_REJECT_ORPHAN_CONTENT);
    c.check("reject.orphanForm.reason", found, &md_rej_str(&report));
    // The labelled field still parses.
    c.check(
        "reject.orphanForm.fieldParsed",
        md_shallow_equal(report.forms.get("D00/D00-HDR"), &[("author", "Ada Lovelace")]),
        &format!("{:?}", report.forms),
    );
}

fn test_markdown_reject_kind_mismatch(c: &mut Checker) {
    let md = "# <!--[D00]--> Demo Document\n\n\
## <!--[D00-OVR]--> Overview\n\n\
kept\n\n\
### <!--[D00-MET-NOTE]--> Note\n\n\
misplaced\n";
    let report = md_parse(md);
    let found = report
        .rejections
        .iter()
        .any(|r| r.reason == SPEC_MARKDOWN_REJECT_KIND_MISMATCH);
    c.check("reject.kindMismatch.reason", found, &md_rej_str(&report));
    c.check(
        "reject.kindMismatch.kept",
        report.content.get("D00/D00-OVR").map(String::as_str) == Some("kept"),
        "",
    );
}

fn test_markdown_reject_missing_value(c: &mut Checker) {
    let md = "# <!--[D00]--> Demo Document\n\n\
## <!--[D00-OVR]--> Overview\n\n\
## <!--[D00-ST]--> Status\n\n\
final\n";
    let report = md_parse(md);
    let found = report.rejections.iter().any(|r| {
        r.reason == SPEC_MARKDOWN_REJECT_MISSING_VALUE && r.anchor == "D00/D00-OVR"
    });
    c.check("reject.missingValue.reason", found, &md_rej_str(&report));
    c.check(
        "reject.missingValue.statusKept",
        report.content.get("D00/D00-ST").map(String::as_str) == Some("final"),
        "",
    );
}

fn test_markdown_case_insensitive_labels(c: &mut Checker) {
    let md = "# <!--[D00]--> Demo Document\n\n\
## <!--[D00-HDR]--> Header\n\n\
author: lower-case label\n";
    let report = md_parse(md);
    c.check(
        "labels.caseInsensitive.clean",
        report.is_clean(),
        &md_rej_str(&report),
    );
    c.check(
        "labels.caseInsensitive.value",
        md_shallow_equal(
            report.forms.get("D00/D00-HDR"),
            &[("author", "lower-case label")],
        ),
        &format!("{:?}", report.forms),
    );
}

fn test_markdown_fence_shielded_headings_stay_body(c: &mut Checker) {
    let md = "# <!--[D00]--> Demo Document\n\n\
## <!--[D00-OVR]--> Overview\n\n\
```\n\
## <!--[D00-ST]--> not a real heading\n\
```\n";
    let report = md_parse(md);
    c.check("fenceShield.clean", report.is_clean(), &md_rej_str(&report));
    c.check(
        "fenceShield.body",
        report.content.get("D00/D00-OVR").map(String::as_str)
            == Some("```\n## <!--[D00-ST]--> not a real heading\n```"),
        &format!("{:?}", report.content.get("D00/D00-OVR")),
    );
    c.check(
        "fenceShield.noStatus",
        !report.content.contains_key("D00/D00-ST"),
        "",
    );
}

#[test]
fn spec_document_markdown() {
    let mut c = Checker::new();
    test_markdown_export_format(&mut c);
    test_markdown_export_stored_item_id(&mut c);
    test_markdown_export_unterm_fence_errors(&mut c);
    test_markdown_to_markdown(&mut c);
    test_markdown_round_trip_values(&mut c);
    test_markdown_round_trip_byte_stable(&mut c);
    test_markdown_round_trip_rich_markdown(&mut c);
    test_markdown_round_trip_stored_item_id(&mut c);
    test_markdown_round_trip_label_shaped_continuation(&mut c);
    test_markdown_reject_unknown_section(&mut c);
    test_markdown_reject_malformed_heading(&mut c);
    test_markdown_reject_orphan_preamble(&mut c);
    test_markdown_reject_orphan_form_prose(&mut c);
    test_markdown_reject_kind_mismatch(&mut c);
    test_markdown_reject_missing_value(&mut c);
    test_markdown_case_insensitive_labels(&mut c);
    test_markdown_fence_shielded_headings_stay_body(&mut c);
    c.finish();
}
