//! DR5 hierarchical `*.docspecs.yaml` v2 codec tests — a port of
//! `tom_som_go_runtime/tests/spec_document_yaml_test.go` (itself a port of
//! `tom_som_typescript_runtime/tests/spec_document_yaml_test.ts` /
//! `tom_som_javascript_runtime/tests/spec_document_yaml_test.js` /
//! `tom_som_python_runtime/tests/spec_document_yaml_test.py` /
//! `tom_som_dart_runtime/test/spec_document_yaml_test.dart`).
//!
//! The codec walks the document root's SomMetaTree: sections nest, keys are
//! `<section-id> <member-name>`, list items key by stored section id (or an
//! anonymous positional `<member>-<n>`), body text uses the literal `content`
//! key, and form fields use their bare names. Round-trip is lossless modulo
//! the DR1 §2.4.3 empty-line dedup; version-1 files and unmatched keys are
//! structured load errors.

use tom_som_rust_runtime::spec_document::SpecDocument;
use tom_som_rust_runtime::spec_document_yaml::{
    decode_yaml, encode_yaml, SpecYamlContents, SpecYamlError,
};
use tom_som_rust_runtime::spec_meta::SomMetaTree;
use tom_som_rust_runtime::spec_meta_bridge::build_som_meta_tree;
use tom_som_rust_runtime::spec_model::SpecModel;

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

/// Reports whether `err` is a `SpecYamlError::Format` whose message contains
/// `needle` — the Rust stand-in for the other ports' `_throwsFormat` helper.
fn yaml_throws_format<T>(result: &Result<T, SpecYamlError>, needle: &str) -> bool {
    match result {
        Err(SpecYamlError::Format(fe)) => fe.message.contains(needle),
        _ => false,
    }
}

/// Exercises every field kind: root body content, a content section with a
/// nested complex section, a complex list with `@SectionIdPattern`, a scalar
/// list, a `@Form` with a numeric field, enum and int leaves.
const YAML_TEST_MODEL_JSON: &str = r#"{
  "modelVersion": 1,
  "roots": [{"type": "Demo", "title": "Demo Document", "sectionId": "D00"}],
  "classes": {
    "Demo": {
      "name": "Demo",
      "sectionId": "D00",
      "fields": [
        {"name": "overview", "kind": "content", "sectionId": "D00-OVR",
         "serializationOrder": 0},
        {"name": "scope", "kind": "complex", "sectionId": "D00-SCO",
         "type": "Scope", "serializationOrder": 1},
        {"name": "header", "kind": "form", "sectionId": "D00-HDR",
         "serializationOrder": 2,
         "formFields": [
           {"name": "author", "label": "Author", "type": "String"},
           {"name": "reviewer", "label": "Reviewer", "type": "String"},
           {"name": "revision", "label": "Revision", "type": "int"}
         ]},
        {"name": "requirements", "kind": "list", "sectionId": "D00-REQ",
         "sectionIdPattern": "REQ-xxx", "elementType": "Requirement",
         "elementIsComplex": true, "serializationOrder": 3},
        {"name": "tags", "kind": "list", "sectionId": "D00-TAG",
         "elementType": "String", "elementIsComplex": false,
         "serializationOrder": 4},
        {"name": "priority", "kind": "enum", "sectionId": "D00-PRI",
         "enumType": "Priority", "enumValues": ["low", "high"],
         "serializationOrder": 5},
        {"name": "count", "kind": "scalar", "type": "int",
         "serializationOrder": 6}
      ]
    },
    "Scope": {
      "name": "Scope",
      "fields": [
        {"name": "inScope", "kind": "content", "sectionId": "D00-INS"},
        {"name": "outOfScope", "kind": "content"}
      ]
    },
    "Requirement": {
      "name": "Requirement",
      "fields": [
        {"name": "text", "kind": "content"},
        {"name": "notes", "kind": "list", "elementType": "String",
         "elementIsComplex": false}
      ]
    }
  }
}"#;

fn yaml_test_tree() -> SomMetaTree {
    let model = SpecModel::from_json_str(YAML_TEST_MODEL_JSON).expect("model");
    build_som_meta_tree(&model, "").expect("tree")
}

fn yaml_enc(tree: &SomMetaTree, d: &SpecDocument, stamp: &str) -> String {
    encode_yaml(d, tree, stamp).expect("encode")
}

fn yaml_dec(tree: &SomMetaTree, yaml: &str) -> SpecYamlContents {
    decode_yaml(yaml, tree).expect("decode")
}

fn yaml_round_trip(tree: &SomMetaTree, d: &SpecDocument) -> SpecDocument {
    yaml_dec(tree, &yaml_enc(tree, d, "")).document
}

/// Builds a document touching every store and the §2.4 edge cases.
fn yaml_populated() -> SpecDocument {
    let mut doc = SpecDocument::new();
    doc.set_content("D00", "Preamble body text.");
    doc.set_content("D00/D00-OVR", "line one\nline two\nline three");
    doc.set_content("D00/D00-SCO/D00-INS", "  indented first line\n    deeper");
    doc.set_content("D00/D00-SCO/outOfScope", "ends with newline\n");
    doc.set_content("D00/D00-PRI", "high");
    doc.set_content("D00/count", "3");
    doc.set_form_field("D00/D00-HDR", "author", "Ada Lovelace");
    doc.set_form_field("D00/D00-HDR", "reviewer", "Grace Hopper");
    doc.set_form_field("D00/D00-HDR", "revision", "7");
    let a = doc
        .add_list_item_with_section_id("D00/D00-REQ", "REQ-AB1")
        .expect("addListItem");
    doc.set_content(&format!("{}/text", a), "value: with: colons # and hash");
    let n1 = doc.add_list_item(&format!("{}/notes", a));
    doc.set_content(&n1, "a nested scalar note");
    let b = doc.add_list_item("D00/D00-REQ"); // anonymous item
    doc.set_content(&format!("{}/text", b), "second requirement");
    let t1 = doc.add_list_item("D00/D00-TAG");
    doc.set_content(&t1, "alpha");
    doc
}

fn yaml_test_encode(c: &mut Checker, tree: &SomMetaTree) {
    // writes the v2 header, version and hierarchical structure
    let yaml = yaml_enc(tree, &yaml_populated(), "1.0");
    c.check(
        "encode.header",
        yaml.starts_with("# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n"),
        yaml.lines().next().unwrap_or(""),
    );
    c.check("encode.version", yaml.contains("version: 2\n"), "");
    c.check("encode.stamp", yaml.contains("modelVersion: \"1.0\"\n"), "");
    c.check(
        "encode.rootKey",
        yaml.contains("\ndocument:\n  D00 Demo:\n"),
        "",
    );
    c.check(
        "encode.nesting",
        yaml.contains("\n    D00-SCO scope:\n      D00-INS inScope:"),
        "",
    );
    c.check(
        "encode.rootContent",
        yaml.contains("\n    content: |2-\n      Preamble body text.\n"),
        "",
    );
    c.check(
        "encode.storedItemId",
        yaml.contains("\n    D00-REQ requirements:\n      REQ-AB1:\n"),
        "",
    );
    c.check("encode.anonItem", yaml.contains("\n      requirements-2:\n"), "");
    c.check("encode.noFlatPaths", !yaml.contains("\"D00/"), "");

    // sibling order follows @SerializationOrder, sparse emission
    let mut doc = SpecDocument::new();
    doc.set_content("D00/D00-PRI", "low"); // order 5
    doc.set_content("D00/D00-OVR", "first"); // order 0
    let sparse = yaml_enc(tree, &doc, "");
    c.check(
        "encode.order",
        sparse.find("D00-OVR overview:") < sparse.find("D00-PRI priority:"),
        "",
    );
    c.check("encode.sparse", !sparse.contains("D00-SCO"), "");

    // non-text values are plain scalars (§2.5)
    let yaml2 = yaml_enc(tree, &yaml_populated(), "");
    c.check(
        "encode.plainEnum",
        yaml2.contains("\n    D00-PRI priority: high\n"),
        "",
    );
    c.check("encode.plainInt", yaml2.contains("\n    count: 3\n"), "");
    c.check(
        "encode.plainFormInt",
        yaml2.contains("\n      revision: 7\n"),
        "",
    );

    // an empty document emits `document: {}`
    c.check(
        "encode.emptyDoc",
        yaml_enc(tree, &SpecDocument::new(), "").contains("document: {}"),
        "",
    );

    // the model-version stamp is omitted when absent
    c.check(
        "encode.noStamp",
        !yaml_enc(tree, &SpecDocument::new(), "").contains("modelVersion:"),
        "",
    );

    // values the tree cannot place are a structured error
    let mut ghost = SpecDocument::new();
    ghost.set_content("D00/ghost", "x");
    let err_ghost = encode_yaml(&ghost, tree, "");
    c.check("encode.leftoverError", yaml_throws_format(&err_ghost, ""), "");

    // an unknown form field is a structured error
    let mut bogus = SpecDocument::new();
    bogus.set_form_field("D00/D00-HDR", "bogus", "v");
    let err_bogus = encode_yaml(&bogus, tree, "");
    c.check(
        "encode.unknownFormField",
        yaml_throws_format(&err_bogus, ""),
        "",
    );
}

fn byte_diff(actual: &str, expected: &str) -> String {
    if actual == expected {
        return String::new();
    }
    let a: Vec<&str> = actual.lines().collect();
    let e: Vec<&str> = expected.lines().collect();
    for i in 0..a.len().max(e.len()) {
        let al = a.get(i).copied().unwrap_or("<missing>");
        let el = e.get(i).copied().unwrap_or("<missing>");
        if al != el {
            return format!("line {}: got {:?} want {:?}", i + 1, al, el);
        }
    }
    "differs in trailing newlines".to_string()
}

fn yaml_test_round_trip(c: &mut Checker, tree: &SomMetaTree) {
    // every value survives verbatim
    let out = yaml_round_trip(tree, &yaml_populated());
    c.check("rt.root", out.content_or("D00") == "Preamble body text.", "");
    c.check(
        "rt.overview",
        out.content_or("D00/D00-OVR") == "line one\nline two\nline three",
        "",
    );
    c.check(
        "rt.inScope",
        out.content_or("D00/D00-SCO/D00-INS") == "  indented first line\n    deeper",
        "",
    );
    c.check(
        "rt.outOfScope",
        out.content_or("D00/D00-SCO/outOfScope") == "ends with newline\n",
        "",
    );
    c.check("rt.priority", out.content_or("D00/D00-PRI") == "high", "");
    c.check("rt.count", out.content_or("D00/count") == "3", "");
    c.check(
        "rt.author",
        out.form_field_or("D00/D00-HDR", "author") == "Ada Lovelace",
        "",
    );
    c.check(
        "rt.reviewer",
        out.form_field_or("D00/D00-HDR", "reviewer") == "Grace Hopper",
        "",
    );
    c.check(
        "rt.revision",
        out.form_field_or("D00/D00-HDR", "revision") == "7",
        "",
    );
    c.check("rt.reqCount", out.list_item_count("D00/D00-REQ") == 2, "");
    let items = out.list_items("D00/D00-REQ");
    c.check(
        "rt.item0.id",
        out.item_section_id_or(&items[0]) == "REQ-AB1",
        "",
    );
    c.check("rt.item1.id", out.item_section_id(&items[1]).is_none(), "");
    c.check(
        "rt.item0.text",
        out.content_or(&format!("{}/text", items[0])) == "value: with: colons # and hash",
        "",
    );
    c.check(
        "rt.item1.text",
        out.content_or(&format!("{}/text", items[1])) == "second requirement",
        "",
    );
    let notes = out.list_items(&format!("{}/notes", items[0]));
    c.check(
        "rt.notes",
        notes.len() == 1 && out.content_or(&notes[0]) == "a nested scalar note",
        "",
    );
    let tags = out.list_items("D00/D00-TAG");
    c.check(
        "rt.tags",
        tags.len() == 1 && out.content_or(&tags[0]) == "alpha",
        "",
    );

    // encode is byte-stable across decode → re-encode
    let yaml1 = yaml_enc(tree, &yaml_populated(), "1.2");
    let yaml2 = yaml_enc(tree, &yaml_dec(tree, &yaml1).document, "1.2");
    c.check("rt.byteStable", yaml2 == yaml1, &byte_diff(&yaml2, &yaml1));

    // the model-version stamp lands on the decoded document
    let decoded = yaml_dec(tree, &yaml_enc(tree, &yaml_populated(), "2.5"));
    c.check("rt.stamp.contents", decoded.model_version == "2.5", "");
    c.check("rt.stamp.document", decoded.document.model_version == "2.5", "");

    // markdown edge cases survive
    let cases = [
        "\nleading blank line",
        "trailing blank line kept as one\n\nend",
        "two trailing newlines\n\n", // block cannot represent → JSON fallback
        "trailing space on a line \nnext",
        "\ttab\tpreserved",
        "- looks: like\n  yaml: [a, b]\n# comment-ish",
        "\"double\" and 'single' quotes",
        "ends with newline\n",
        "   only-indentation-sensitive\n      nested deeper\n   back",
    ];
    for (i, edge) in cases.iter().enumerate() {
        let mut doc = SpecDocument::new();
        doc.set_content("D00/D00-OVR", edge);
        let got = yaml_round_trip(tree, &doc).content_or("D00/D00-OVR");
        c.check(
            &format!("rt.edge[{}]", i),
            got == *edge,
            &format!("got {:?} want {:?}", got, edge),
        );
    }

    // runs of 2+ empty lines collapse to one on write (§2.4.3)
    let mut doc = SpecDocument::new();
    doc.set_content("D00/D00-OVR", "a\n\n\n\nb\n\n\nc");
    c.check(
        "rt.emptyLineDedup",
        yaml_round_trip(tree, &doc).content_or("D00/D00-OVR") == "a\n\nb\n\nc",
        "",
    );

    // an empty complex list item round-trips as `{}`
    let mut empty_item = SpecDocument::new();
    empty_item.add_list_item("D00/D00-REQ");
    let yaml3 = yaml_enc(tree, &empty_item, "");
    c.check(
        "rt.emptyItem.enc",
        yaml3.contains("requirements-1: {}"),
        &yaml3,
    );
    c.check(
        "rt.emptyItem.count",
        yaml_round_trip(tree, &empty_item).list_item_count("D00/D00-REQ") == 1,
        "",
    );
}

fn yaml_test_strict_decode(c: &mut Checker, tree: &SomMetaTree) {
    // version 1 files are rejected with a clear error
    let err_v1 = decode_yaml("version: 1\ndocument: {}\n", tree);
    c.check("decode.v1Rejected", yaml_throws_format(&err_v1, "version 1"), "");

    // a missing version is rejected
    let err_no_version = decode_yaml("document: {}\n", tree);
    c.check(
        "decode.missingVersion",
        yaml_throws_format(&err_no_version, ""),
        "",
    );
    let err_empty = decode_yaml("", tree);
    c.check("decode.emptyText", yaml_throws_format(&err_empty, ""), "");

    // an unmatched key is a structured load error, not a silent skip
    let bad = "version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n      x\n";
    let err_bad = decode_yaml(bad, tree);
    c.check(
        "decode.unmatchedKey",
        yaml_throws_format(&err_bad, "nonsense"),
        "",
    );

    // a wrong root key is a structured load error
    let err_root = decode_yaml("version: 2\ndocument:\n  WRONG Other: {}\n", tree);
    c.check("decode.wrongRoot", yaml_throws_format(&err_root, ""), "");

    // an unknown form field on read is a structured load error
    let bad_form =
        "version: 2\ndocument:\n  D00 Demo:\n    D00-HDR header:\n      bogus: |-\n        v\n";
    let err_form = decode_yaml(bad_form, tree);
    c.check(
        "decode.unknownFormField",
        yaml_throws_format(&err_form, ""),
        "",
    );

    // a missing/empty document pass decodes as an empty document
    c.check(
        "decode.noDocKey",
        yaml_dec(tree, "version: 2\n").document.is_empty(),
        "",
    );
    c.check(
        "decode.emptyDoc",
        yaml_dec(tree, "version: 2\ndocument: {}\n").document.is_empty(),
        "",
    );

    // the raw review pass is passed through untouched
    let fixture = "version: 2\ndocument: {}\nreview:\n  \"D00/a\":\n    scope: global\n";
    let contents = yaml_dec(tree, fixture);
    c.check("decode.review", contents.review.has("D00/a"), "");
}

/// Runs the shared DR5 hierarchical-codec suite (58 checks).
#[test]
fn spec_document_yaml() {
    let mut c = Checker::new();
    let tree = yaml_test_tree();
    yaml_test_encode(&mut c, &tree);
    yaml_test_round_trip(&mut c, &tree);
    yaml_test_strict_decode(&mut c, &tree);
    c.finish();
}
