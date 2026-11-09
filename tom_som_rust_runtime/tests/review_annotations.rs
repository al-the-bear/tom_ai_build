//! The quick start and the merge example of `doc/review_annotations.md`,
//! run: the output the guide prints is asserted here, so the guide cannot
//! drift from the code. The behaviour itself is pinned by
//! `annotation_cases.json`, `team_annotation_cases.json` and
//! `review_merge_cases.json` in the conformance suite.

use tom_som_rust_runtime::{
    merge_reviews, strip_annotations_text, Json, SpecDocument, SpecModel, SpecQuestionDraft,
    SpecReviewAnnotationKind, SpecReviewAnnotations, SpecReviewMember, SpecReviewMergeOptions,
    SpecReviewedCopy,
};

#[test]
fn quick_start_output_is_true() {
    let mut doc = SpecDocument::new();
    doc.set_content(
        "DEMO/SUM",
        "Sessions expire after 30 minutes.\n\n> \u{2B06}\u{FE0F} (Alexis): Too long for kiosks.",
    );
    let mut review = SpecReviewAnnotations::with_qualifier(&mut doc, Some("DEMO"));
    let mut out = Vec::new();
    out.push(format!("{:?}", review.assign_comment_ids(0)));
    out.push(review.list()[0].qualified_id.clone().unwrap_or_default());
    review
        .insert_question_after_comment(
            "C-1",
            &SpecQuestionDraft::new("BQ-1", "C-1 kiosks", "Kiosks only?"),
            None,
        )
        .unwrap();
    review.set_answer("BQ-1", "yes").unwrap();
    out.push(format!("{:?}", review.counts()));
    assert_eq!(
        out,
        vec![
            "[\"C-1\"]".to_string(),
            "DEMO C-1".to_string(),
            "SpecReviewAnnotationCounts { questions: 1, open_questions: 0, \
             answered_questions: 1, comments: 1, marks: 0, unresolved_questions: 0, \
             conflicts: 0, open_conflicts: 0 }"
                .to_string(),
        ]
    );
}

#[test]
fn unknown_ids_are_errors_and_change_nothing() {
    let mut doc = SpecDocument::new();
    doc.set_content("DEMO/SUM", "Text {++ added ++}.");
    let before = doc.content_or("DEMO/SUM");
    let mut review = SpecReviewAnnotations::new(&mut doc);
    assert!(review.resolve("C-9").is_err());
    assert!(review.set_answer("BQ-9", "x").is_err());
    assert!(review.apply_mark("DEMO/SUM", None, 1, true).is_err());
    assert!(review
        .insert_comment("DEMO/SUM", None, 3, "x", None, None, None)
        .is_err());
    assert_eq!(review.list()[0].kind, SpecReviewAnnotationKind::Mark);
    assert_eq!(review.doc().content_or("DEMO/SUM"), before);
    assert_eq!(strip_annotations_text(&before), "Text added.");
}

/// The corpus DEMO model the guide's merge example runs against.
fn demo_model() -> SpecModel {
    let path = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../tom_som_conformance/corpus/model.meta.json");
    let text = std::fs::read_to_string(&path).expect("read the corpus model");
    SpecModel::from_json(&Json::parse(&text).expect("parse the corpus model"))
}

#[test]
fn merge_example_output_is_true() {
    let model = demo_model();
    let doc = |text: &str| {
        let mut d = SpecDocument::new();
        d.set_content("DEMO/SUM", text);
        d
    };
    let member = |id: &str, name: &str, role: &str| SpecReviewMember {
        member_id: id.to_string(),
        display_name: name.to_string(),
        role: role.to_string(),
    };
    let team = vec![
        member("alice", "Alice Owner", "Product owner"),
        member("bob", "Bob Dev", "Developer"),
    ];
    let copies: Vec<SpecReviewedCopy<SpecDocument>> = team
        .iter()
        .map(|m| SpecReviewedCopy {
            member: m.clone(),
            document: doc("Sessions expire after 15 minutes."),
        })
        .collect();
    let options = SpecReviewMergeOptions {
        team: team.clone(),
        date: "2026-11-05".to_string(),
        author: "Alice Owner".to_string(),
        question_prefix: None,
    };
    let r = merge_reviews(
        &model,
        &doc("Sessions expire after 30 minutes."),
        &copies,
        &options,
    )
    .expect("the copies fit the base");
    assert_eq!(
        r.merged.content_or("DEMO/SUM"),
        "Sessions expire after {~~ 30 ~> 15 ~~}{@alice,bob} minutes."
    );
    assert_eq!(r.report.conflicts.len(), 0);
}
