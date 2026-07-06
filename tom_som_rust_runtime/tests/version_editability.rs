//! Version-editability suite for the §2.2 checks (SOM roadmap § item 8).
//!
//! Mirrors the Dart reference `som_facade_test.dart` cases for both the
//! non-erroring classifier [`som_editability_for`] and the erroring
//! [`check_som_model_version`], plus a facade-behavioural case standing in for
//! the generated root's `editability_for` associated function (which delegates
//! to `som_editability_for(<CONST>, document_version)` — the generated crate is
//! regenerated centrally, so we exercise the same delegation the emitter emits).
//!
//! CS4-D2: Rust uses the empty-string `""` sentinel (not `Option::None`) for an
//! absent document stamp, so `""` classifies as editable.

use tom_som_rust_runtime::{check_som_model_version, som_editability_for, SomEditability};

// --- som_editability_for (non-erroring §2.2 classification) ----------------

#[test]
fn empty_stamp_is_editable() {
    // The empty-string sentinel means "no stamp" — a brand-new document.
    assert_eq!(som_editability_for("0.0", ""), SomEditability::Editable);
    assert_eq!(som_editability_for("1.3", ""), SomEditability::Editable);
}

#[test]
fn same_major_older_or_equal_minor_is_editable() {
    assert_eq!(som_editability_for("1.3", "1.0"), SomEditability::Editable);
    assert_eq!(som_editability_for("1.3", "1.3"), SomEditability::Editable);
}

#[test]
fn same_major_newer_minor_is_rejected() {
    assert_eq!(
        som_editability_for("1.2", "1.5"),
        SomEditability::RejectedNewerMinor
    );
}

#[test]
fn different_major_is_read_only_cross_major() {
    assert_eq!(
        som_editability_for("1.0", "2.0"),
        SomEditability::ReadOnlyCrossMajor
    );
    assert_eq!(
        som_editability_for("1.0", "0.9"),
        SomEditability::ReadOnlyCrossMajor
    );
}

#[test]
fn unparseable_stamp_is_invalid_version() {
    assert_eq!(
        som_editability_for("1.0", "not-a-version"),
        SomEditability::InvalidVersion
    );
}

// --- check_som_model_version parity ----------------------------------------

#[test]
fn check_is_ok_exactly_where_editable() {
    for stamp in ["", "1.0", "1.3"] {
        assert_eq!(som_editability_for("1.3", stamp), SomEditability::Editable);
        assert!(check_som_model_version("1.3", stamp).is_ok());
    }
}

#[test]
fn check_is_err_exactly_where_non_editable() {
    // For every non-editable classification, the erroring check returns Err —
    // the two never diverge (check delegates to the classifier).
    for stamp in ["1.5", "2.0", "0.9", "not-a-version"] {
        assert_ne!(som_editability_for("1.0", stamp), SomEditability::Editable);
        assert!(check_som_model_version("1.0", stamp).is_err());
    }
}

#[test]
fn check_error_messages_match_the_classification() {
    // Cross-major message.
    let cross = check_som_model_version("1.0", "2.0").unwrap_err();
    assert!(cross
        .message
        .contains("cross-major documents are read-only"));
    assert!(cross.message.contains("document major version 2"));

    // Newer-minor message.
    let newer = check_som_model_version("1.2", "1.5").unwrap_err();
    assert!(newer
        .message
        .contains("an older object model cannot edit a newer document"));
    assert!(newer.message.contains("document model version 1.5"));

    // Invalid-version message.
    let invalid = check_som_model_version("1.0", "not-a-version").unwrap_err();
    assert!(invalid
        .message
        .contains("is not a valid major.minor"));
    assert!(invalid.message.contains("not-a-version"));
}

// --- facade behavioural (generated root `editability_for` stand-in) ---------

/// The generated root facade emits
/// `pub fn editability_for(document_version: &str) -> som::SomEditability`
/// delegating to `som::som_editability_for(<ROOT>_MODEL_VERSION, ...)`. With a
/// `"1.0"` model version, the facade classifies each stamp exactly as the Dart
/// reference `Root.editabilityFor` does.
#[test]
fn generated_root_editability_for_delegates() {
    const ROOT_MODEL_VERSION: &str = "1.0";
    let editability_for =
        |doc_ver: &str| som_editability_for(ROOT_MODEL_VERSION, doc_ver);

    assert_eq!(editability_for(""), SomEditability::Editable);
    assert_eq!(editability_for("1.0"), SomEditability::Editable);
    assert_eq!(editability_for("1.5"), SomEditability::RejectedNewerMinor);
    assert_eq!(editability_for("2.0"), SomEditability::ReadOnlyCrossMajor);
    assert_eq!(editability_for("0.9"), SomEditability::ReadOnlyCrossMajor);
    assert_eq!(editability_for("bogus"), SomEditability::InvalidVersion);
}
