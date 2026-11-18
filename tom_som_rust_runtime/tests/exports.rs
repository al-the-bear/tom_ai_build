//! The surface the TypeScript runtime's `index.ts` exports, reached from the
//! crate root: the YAML writer helpers, the review-pass scalar forms, the
//! Markdown heading-comment readers, the CodeSpecs YAML string, the path,
//! node-kind, field-kind and section-id constants, every validation code, and
//! `som_meta_node_diff` with its `at` prefix. The expected values are the
//! TypeScript runtime's output for the same inputs.

use std::rc::Rc;

use tom_som_rust_runtime as som;
use tom_som_rust_runtime::yaml::YamlValue;

#[test]
fn write_scalar_and_header() {
    let mut out = String::from("x\n");
    som::write_scalar(&mut out, 2, "key", "one");
    som::write_scalar(&mut out, 2, "a b", "line1\nline2");
    som::write_scalar(&mut out, 0, "k", "");
    som::write_header(&mut out, "1.2.3");
    som::write_header(&mut out, "");
    let want = concat!(
        "x\n",
        "  \"key\": |2-\n    one\n  \"a b\": |2-\n    line1\n    line2\n\"k\": |2-\n\n",
        "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\nversion: 2\nmodelVersion: \"1.2.3\"\n",
        "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\nversion: 2\n",
    );
    assert_eq!(out, want);
}

#[test]
fn scalar_helpers() {
    assert_eq!(som::yaml_key("a b"), "\"a b\"");
    assert_eq!(som::review_scalar(&YamlValue::Bool(true)), "true");
    assert_eq!(som::review_scalar(&YamlValue::Int(3)), "3");
    assert_eq!(som::review_scalar(&YamlValue::Float(2.5)), "2.5");
    assert_eq!(som::review_scalar(&YamlValue::Float(3.0)), "3.0");
    assert_eq!(som::review_scalar(&YamlValue::Null), "null");
    assert_eq!(som::code_specs_yaml_string("a\"b\n"), "\"a\\\"b\\n\"");
    let floats: [(f64, &str); 9] = [
        (3.0, "3.0"),
        (-0.0, "-0.0"),
        (0.1, "0.1"),
        (1e21, "1e+21"),
        (1e-7, "1e-7"),
        (1e20, "100000000000000000000.0"),
        (f64::NAN, ".nan"),
        (f64::INFINITY, ".inf"),
        (f64::NEG_INFINITY, "-.inf"),
    ];
    for (x, want) in floats {
        assert_eq!(som::format_yaml_float(x), want, "format_yaml_float({})", x);
    }
    assert_eq!(
        som::SpecDocumentMarkdown::code_spec_of("sectionId=\"X\" codeSpec=\" a,b \""),
        "a,b"
    );
    assert_eq!(
        som::SpecDocumentMarkdown::code_spec_of("sectionId=\"X\""),
        ""
    );
    assert_eq!(
        som::SpecDocumentMarkdown::units_of("units='server,web'"),
        "server,web"
    );
}

#[test]
fn constants_reach_the_crate_root() {
    assert_eq!(som::SPEC_PATH_SEPARATOR, "/");
    assert_eq!(som::K_SECTION_ID_SLOT, "@sectionId");
    let node_kinds = [
        som::SPEC_NODE_KIND_ROOT,
        som::SPEC_NODE_KIND_COMPLEX,
        som::SPEC_NODE_KIND_SECTION,
        som::SPEC_NODE_KIND_LIST,
        som::SPEC_NODE_KIND_LIST_ITEM_COMPLEX,
        som::SPEC_NODE_KIND_LIST_ITEM_SCALAR,
        som::SPEC_NODE_KIND_FORM,
        som::SPEC_NODE_KIND_CONTENT,
        som::SPEC_NODE_KIND_ENUM_VALUE,
        som::SPEC_NODE_KIND_SCALAR,
    ];
    assert_eq!(
        node_kinds,
        [
            "root",
            "complex",
            "section",
            "list",
            "listItemComplex",
            "listItemScalar",
            "form",
            "content",
            "enumValue",
            "scalar"
        ]
    );
    let field_kinds = [
        som::SPEC_FIELD_KIND_LIST,
        som::SPEC_FIELD_KIND_FORM,
        som::SPEC_FIELD_KIND_SECTION,
        som::SPEC_FIELD_KIND_CONTENT,
        som::SPEC_FIELD_KIND_ENUM,
        som::SPEC_FIELD_KIND_COMPLEX,
        som::SPEC_FIELD_KIND_SCALAR,
    ];
    assert_eq!(
        field_kinds,
        ["list", "form", "section", "content", "enum", "complex", "scalar"]
    );
    // TS `SpecValidationCode`, all 21 values.
    let codes = [
        som::SPEC_VALIDATION_CODE_DANGLING_PATH,
        som::SPEC_VALIDATION_CODE_KIND_MISMATCH,
        som::SPEC_VALIDATION_CODE_UNKNOWN_FORM_FIELD,
        som::SPEC_VALIDATION_CODE_MIN_ITEMS,
        som::SPEC_VALIDATION_CODE_ONE_OF_CASE_MISMATCH,
        som::SPEC_VALIDATION_CODE_DANGLING_REFERENCE,
        som::SPEC_VALIDATION_CODE_ENUM_VALUE_UNKNOWN,
        som::SPEC_VALIDATION_CODE_COUNT_MISMATCH,
        som::SPEC_VALIDATION_CODE_VALUE_TYPE_MISMATCH,
        som::SPEC_VALIDATION_CODE_DERIVED_VALUE_MISMATCH,
        som::SPEC_VALIDATION_CODE_MISSING_REQUIRED_FIELD,
        som::SPEC_VALIDATION_CODE_MULTIPLE_REFERENCES,
        som::SPEC_VALIDATION_CODE_ANNOTATION_MISPLACED,
        som::SPEC_VALIDATION_CODE_ANNOTATION_MALFORMED,
        som::SPEC_VALIDATION_CODE_DUPLICATE_ANNOTATION_ID,
        som::SPEC_VALIDATION_CODE_UNKNOWN_UNIT,
        som::SPEC_VALIDATION_CODE_UNITS_UNROUTED,
        som::SPEC_VALIDATION_CODE_DUPLICATE_UNIT_ID,
        som::SPEC_VALIDATION_CODE_UNIT_BUILDS_NOTHING,
        som::SPEC_VALIDATION_CODE_UNIT_AREA_MALFORMED,
        som::SPEC_VALIDATION_CODE_UNIT_EMITTER_UNKNOWN,
    ];
    assert_eq!(
        codes,
        [
            "danglingPath",
            "kindMismatch",
            "unknownFormField",
            "minItems",
            "oneOfCaseMismatch",
            "danglingReference",
            "enumValueUnknown",
            "countMismatch",
            "valueTypeMismatch",
            "derivedValueMismatch",
            "missingRequiredField",
            "multipleReferences",
            "annotationMisplaced",
            "annotationMalformed",
            "duplicateAnnotationId",
            "unknownUnit",
            "unitsUnrouted",
            "duplicateUnitId",
            "unitBuildsNothing",
            "unitAreaMalformed",
            "unitEmitterUnknown",
        ]
    );
}

fn node(
    class_name: &str,
    member_name: &str,
    children: Vec<Rc<som::SomMetaNode>>,
) -> Rc<som::SomMetaNode> {
    let mut n = som::SomMetaNode::new();
    n.class_name = class_name.to_string();
    n.member_name = member_name.to_string();
    n.children = children;
    Rc::new(n)
}

#[test]
fn som_meta_node_diff_with_at() {
    let a = node("A", "", vec![]);
    let b = node("B", "", vec![]);
    assert_eq!(som::som_meta_node_diff(&a, &a), None);
    assert_eq!(som::som_meta_node_diff_at(&a, &a, "x"), None);
    let d = som::som_meta_node_diff(&a, &b).expect("the class names differ");
    assert!(d.starts_with("<root>: className differs"), "{}", d);
    let d = som::som_meta_node_diff_at(&a, &b, "<root>/orders").expect("the class names differ");
    assert!(d.starts_with("<root>/orders: className differs"), "{}", d);
    let pa = node("P", "", vec![node("A", "lines", vec![])]);
    let pb = node("P", "", vec![node("B", "lines", vec![])]);
    let d = som::som_meta_node_diff_at(&pa, &pb, "doc").expect("the children differ");
    assert!(d.starts_with("doc/lines: className differs"), "{}", d);
}
