//! The rendition's generated parts (`spec_document_markdown_generated.rs`,
//! SOM §11.12) through the codec's surface, over the real model: the
//! requirement views written in `derived` blocks at the start of their
//! sections, the headings they force, the option that turns them off, the
//! parser removing a block (and only a closed `derived` block at its place),
//! and the missing value an empty generated place is without its block.
//! Mirrors the Go runtime's `spec_document_markdown_generated_test.go`.

mod set_support;

use set_support::rendition_fixture;
use tom_som_rust_runtime::{
    SpecDocument, SpecDocumentMarkdown, SpecDocumentStrip, SpecDocumentStripOptions, SpecModel,
    SpecStripOptions, SPEC_MARKDOWN_REJECT_MISSING_VALUE,
};

const TRACE_OPEN: &str =
    "::: {.derived label=\"Generated from each requirement's traceability; edit it there\"}";

fn fixture() -> (SpecModel, SpecDocument, String) {
    let (model, doc, case) = rendition_fixture("generatedTrace");
    let md = case
        .get("expect")
        .and_then(|e| e.get("markdown"))
        .and_then(|m| m.as_str())
        .unwrap_or_default()
        .to_string();
    (model, doc, md)
}

fn render_rsp(model: &SpecModel, doc: &SpecDocument, generated: bool) -> String {
    let root = model
        .roots
        .iter()
        .find(|r| r.section_id == "RSP")
        .expect("the RSP root");
    SpecDocumentMarkdown::new(model, doc)
        .with_file_stem("links")
        .with_navigation(true, generated)
        .export_root(root)
        .expect("export")
}

fn assert_round_trip(label: &str, md: &str, model: &SpecModel, doc: &SpecDocument) {
    let parsed = SpecDocument::from_markdown(md, model);
    assert!(
        parsed.rejections().is_empty(),
        "{}: rejections {:?}",
        label,
        parsed.rejections()
    );
    assert_eq!(
        parsed.document.to_json().to_canonical_json(),
        doc.to_json().to_canonical_json(),
        "{}: the document differs",
        label
    );
}

#[test]
fn generated_tables_on_the_requirements_specification() {
    let (model, doc, golden) = fixture();
    let md = render_rsp(&model, &doc, true);
    assert_eq!(md, golden, "the rendition differs from the golden one");
    for want in [
        format!(
            "{}\n| Requirement | Use cases | Screens | Data entities | Tests |\n| --- | --- | --- | --- | --- |\n",
            TRACE_OPEN
        ),
        "| Requirement | Covered | By |".to_string(),
        "| Requirement | Dependency | Related requirement |".to_string(),
    ] {
        assert!(md.contains(&want), "no {:?}", want);
    }
    assert!(
        !md.contains('\u{0}'),
        "a placeholder is left in the rendition"
    );
    // The block opens its section, after the heading (and its marker).
    let lines: Vec<&str> = md.split('\n').collect();
    for (i, l) in lines.iter().enumerate() {
        if *l == TRACE_OPEN {
            assert!(
                lines[i - 2].contains("<!--[RSP-TRAC]-->"),
                "the block follows {:?}",
                lines[i - 2]
            );
        }
    }
    assert_round_trip("with generated parts", &md, &model, &doc);
}

#[test]
fn generated_parts_off() {
    let (model, doc, _) = fixture();
    let plain = render_rsp(&model, &doc, false);
    assert!(
        !plain.contains("{.derived"),
        "generated_parts false still writes a block"
    );
    assert!(
        !plain.contains("<!--[RSP-TRAC]-->"),
        "an empty generated place is written without its block"
    );
    assert_round_trip("without generated parts", &plain, &model, &doc);
}

#[test]
fn an_edited_block_is_discarded() {
    let (model, doc, _) = fixture();
    let md = render_rsp(&model, &doc, true);
    let edited = md.replacen(
        "| Requirement | Covered | By |",
        "| Requirement | Covered |",
        1,
    );
    assert_round_trip("edited block", &edited, &model, &doc);
}

#[test]
fn a_removed_block_is_a_missing_value() {
    let (model, doc, _) = fixture();
    let md = render_rsp(&model, &doc, true);
    let lines: Vec<&str> = md.split('\n').collect();
    let i = lines
        .iter()
        .position(|l| *l == TRACE_OPEN)
        .expect("the block");
    let j = i + lines[i..]
        .iter()
        .position(|l| *l == ":::")
        .expect("its end");
    let given = [&lines[..i], &lines[j + 2..]].concat().join("\n");
    let parsed = SpecDocument::from_markdown(&given, &model);
    let r = parsed.rejections();
    assert!(
        r.len() == 1
            && r[0].reason == SPEC_MARKDOWN_REJECT_MISSING_VALUE
            && r[0].anchor == "RSP/RSP-TRAC",
        "rejections {:?}",
        r
    );
}

#[test]
fn only_a_closed_derived_block_is_removed() {
    let (model, doc, _) = fixture();
    let md = render_rsp(&model, &doc, true);
    // Indented by four spaces the fence opens no block: the lines are the
    // value's, and the traceability matrix holds them.
    let indented = md.replacen(TRACE_OPEN, &format!("    {}", TRACE_OPEN), 1);
    let parsed = SpecDocument::from_markdown(&indented, &model);
    let v = parsed
        .document
        .content("RSP/RSP-TRAC")
        .cloned()
        .unwrap_or_default();
    assert!(
        v.contains("Generated from"),
        "the indented lines are not the value: {:?}",
        v
    );
    // A block of another kind is the value's too.
    let other = md.replacen(TRACE_OPEN, "::: {.derivedX}", 1);
    let parsed = SpecDocument::from_markdown(&other, &model);
    let v = parsed
        .document
        .content("RSP/RSP-TRAC")
        .cloned()
        .unwrap_or_default();
    assert!(
        v.contains("{.derivedX}"),
        "a block of another kind is not the value: {:?}",
        v
    );
}

#[test]
fn the_strip_kinds_turn_the_parts_off() {
    let (model, doc, _) = fixture();
    let none: [&str; 0] = [];
    let o =
        SpecStripOptions::from_names(&["derived"], &none, &none, false, false).expect("options");
    let extra = SpecDocumentStripOptions {
        model: Some(&model),
        root_type: Some("D04RequirementsSpecification"),
        ..Default::default()
    };
    let r = SpecDocumentStrip::strip(&doc, &o, &extra);
    let readable = r
        .readable
        .unwrap_or_else(|| panic!("no readable rendition: {:?}", r.findings));
    assert!(
        !readable.contains("{.derived"),
        "the readable rendition has a generated block"
    );
}
