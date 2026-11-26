//! The rendition's navigation (`spec_document_markdown_linked.rs`) through
//! the codec's surface: qualified anchors (SOM §11.2), the `linked` marker and
//! its entries in their order (SOM §11.11), the placeholder resolution, the
//! option that turns the marker off, the strip kinds that do, the file stem
//! and document files of cross-document links, and the parser removing the
//! marker.
//!
//! The shared corpus (`link_rendition_cases.json`) pins whole renditions;
//! these tests hold the module's behaviour over the corpus's
//! `links.meta.json`. Mirrors the Go runtime's
//! `spec_document_markdown_linked_test.go`.

mod set_support;

use std::collections::HashMap;

use set_support::rendition_fixture;
use tom_som_rust_runtime::{
    SpecDocument, SpecDocumentMarkdown, SpecDocumentStrip, SpecDocumentStripOptions, SpecModel,
    SpecStripOptions,
};

fn render_root(
    model: &SpecModel,
    doc: &SpecDocument,
    root_id: &str,
    configure: impl FnOnce(SpecDocumentMarkdown<'_>) -> SpecDocumentMarkdown<'_>,
) -> String {
    let root = model
        .roots
        .iter()
        .find(|r| r.section_id == root_id)
        .unwrap_or_else(|| panic!("no root {}", root_id));
    configure(SpecDocumentMarkdown::new(model, doc).with_file_stem("links"))
        .export_root(root)
        .expect("export")
}

fn plain(c: SpecDocumentMarkdown<'_>) -> SpecDocumentMarkdown<'_> {
    c
}

/// The first root (with a section id) the document holds a value under.
fn populated_root(model: &SpecModel, doc: &SpecDocument) -> String {
    model
        .roots
        .iter()
        .find(|r| !r.section_id.is_empty() && doc.has_values_under(&r.section_id))
        .map(|r| r.section_id.clone())
        .expect("a populated root")
}

/// The marker paragraph written right after the heading carrying `anchor`,
/// `""` when none follows it.
fn marker_after(md: &str, anchor: &str) -> String {
    let lines: Vec<&str> = md.split('\n').collect();
    let needle = format!("<a id=\"{}\"></a>", anchor);
    for (i, l) in lines.iter().enumerate() {
        if l.contains(&needle) && l.starts_with('#') {
            return match lines.get(i + 2) {
                Some(m) if m.ends_with("{.linked}") => m.to_string(),
                _ => String::new(),
            };
        }
    }
    String::new()
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
fn marker_entries_on_the_blueprint() {
    let (model, doc, case) = rendition_fixture("copyOf");
    let md = render_root(&model, &doc, "BLU", plain);
    assert_eq!(
        Some(md.as_str()),
        case.get("expect")
            .and_then(|e| e.get("markdown"))
            .and_then(|m| m.as_str()),
        "the rendition differs from the golden one"
    );
    assert_eq!(
        marker_after(&md, "CSUM/CRIT"),
        "[Copy of [CRIT](#CRIT), edit it there]{.linked}"
    );
    assert_eq!(
        marker_after(&md, "REQ-EXPORT/LNK-ITEM-LST"),
        "[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}"
    );
    // An item's entries in the order of SOM §11.11: Also in, Summarised in,
    // Derived from.
    let item = marker_after(&md, "REQ-EXPORT");
    let also = item
        .find("Also in [DET REQ-EXPORT](links.det.tomspecs.md#REQ-EXPORT), held there except REQ.owner")
        .expect("also in");
    let summarised = item
        .find("; Summarised in [KEY-1](#KEY-1)")
        .expect("summarised in");
    let derived = item.find("; Derived from ").expect("derived from");
    assert!(
        also == 1 && summarised > also && derived > summarised,
        "item marker {}",
        item
    );
    assert!(
        !md.starts_with('[') && marker_after(&md, "BLU").is_empty(),
        "the root carries no marker"
    );
    // Qualified anchors below an item and in a copy.
    for a in ["<a id=\"REQ-EXPORT/REQD\"></a>", "<a id=\"CSUM/CRIT\"></a>"] {
        assert!(md.contains(a), "anchor {} missing", a);
    }
    assert_round_trip("with markers", &md, &model, &doc);
}

#[test]
fn markers_off() {
    let (model, doc, _) = rendition_fixture("copyOf");
    let without = render_root(&model, &doc, "BLU", |c| c.with_navigation(false, true));
    assert!(
        !without.contains("{.linked}"),
        "linked_markers false still writes a marker"
    );
    assert!(
        without.contains("<a id=\"CSUM/CRIT\"></a>"),
        "the anchors go with the markers"
    );
    assert_round_trip("without markers", &without, &model, &doc);
    // A marker deleted by hand is restored on the next export.
    let md = render_root(&model, &doc, "BLU", plain);
    let parsed = SpecDocument::from_markdown(&without, &model);
    assert_eq!(
        render_root(&model, &parsed.document, "BLU", plain),
        md,
        "the markers are not restored after a rendition without them"
    );
}

#[test]
fn a_hand_edited_marker_is_discarded() {
    let (model, doc, _) = rendition_fixture("copyOf");
    let md = render_root(&model, &doc, "BLU", plain);
    let edited = md.replacen(
        "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
        "[Copy of [X](#X), edit it there]{.linked}",
        1,
    );
    assert_round_trip("edited marker", &edited, &model, &doc);
}

#[test]
fn text_after_the_marker_is_a_value() {
    // A paragraph that is more than one `linked` span is the value's, not the
    // marker: it stays content (and the copy's form has no content, so it is
    // rejected rather than silently dropped).
    let (model, doc, _) = rendition_fixture("copyOf");
    let md = render_root(&model, &doc, "BLU", plain);
    let edited = md.replacen(
        "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
        "[Copy of [CRIT](#CRIT), edit it there]{.linked} and more",
        1,
    );
    let parsed = SpecDocument::from_markdown(&edited, &model);
    let same = parsed.document.to_json().to_canonical_json() == doc.to_json().to_canonical_json();
    assert!(
        !same || !parsed.rejections().is_empty(),
        "text beside the marker was dropped"
    );
}

#[test]
fn the_empty_marker_before_a_linked_value() {
    let (model, doc, _) = rendition_fixture("emptyMarker");
    let md = render_root(&model, &doc, &populated_root(&model, &doc), plain);
    assert!(
        md.contains("[]{.linked}\n\n[To be chosen"),
        "no empty marker before the linked value:\n{}",
        md
    );
    assert!(
        !md.contains('\u{0}'),
        "a placeholder is left in the rendition"
    );
    assert_round_trip("empty marker", &md, &model, &doc);
}

#[test]
fn a_summary_row_links_its_detail_element_from_its_id_cell() {
    let (model, doc, case) = rendition_fixture("summaryRowLink");
    let got = render_root(&model, &doc, &populated_root(&model, &doc), plain);
    assert_eq!(
        Some(got.as_str()),
        case.get("expect")
            .and_then(|e| e.get("markdown"))
            .and_then(|m| m.as_str()),
        "the rendition differs from the golden one"
    );
    assert!(
        got.contains("| <a id=\"TOP-BETA\"></a>[TOP-BETA](#TOP-BETA) |"),
        "the summary row's Id cell is no link"
    );
    assert_round_trip("summary rows", &got, &model, &doc);
}

#[test]
fn the_file_stem_and_document_files_name_the_other_document() {
    let (model, doc, _) = rendition_fixture("dangling");
    let root = populated_root(&model, &doc);
    let stem = render_root(&model, &doc, &root, plain);
    assert!(
        stem.contains("](links.blu.tomspecs.md#REQ-PRESETS)"),
        "{}",
        stem
    );
    let bare = render_root(&model, &doc, &root, |c| c.with_file_stem(""));
    assert!(bare.contains("](blu.tomspecs.md#REQ-PRESETS)"), "{}", bare);
    let files = HashMap::from([("BLU".to_string(), "blueprint.md".to_string())]);
    let mapped = render_root(&model, &doc, &root, |c| c.with_document_files(files));
    assert!(mapped.contains("](blueprint.md#REQ-PRESETS)"), "{}", mapped);
    assert_round_trip("mapped files", &mapped, &model, &doc);
}

#[test]
fn the_strip_kinds_turn_the_marker_off() {
    let (model, doc, _) = rendition_fixture("copyOf");
    let extra = SpecDocumentStripOptions {
        model: Some(&model),
        root_type: Some("Blueprint"),
        file_stem: Some("links"),
        ..Default::default()
    };
    let none: [&str; 0] = [];
    for (drop, unmark) in [(&["linked"][..], &none[..]), (&none[..], &["linked"][..])] {
        let o = SpecStripOptions::from_names(drop, unmark, &none, false, false).expect("options");
        let r = SpecDocumentStrip::strip(&doc, &o, &extra);
        let readable = r
            .readable
            .unwrap_or_else(|| panic!("no readable rendition: {:?}", r.findings));
        assert!(
            !readable.contains("{.linked}"),
            "{:?}/{:?}: the readable rendition has a marker",
            drop,
            unmark
        );
    }
    let o =
        SpecStripOptions::from_names(&["provenance"], &none, &none, false, false).expect("options");
    let r = SpecDocumentStrip::strip(&doc, &o, &extra);
    assert!(
        r.readable.unwrap_or_default().contains("{.linked}"),
        "dropping another kind turns the marker off"
    );
}
