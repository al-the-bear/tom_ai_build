//! Tests for the consolidated DocSpecs parsing + validation module (SOM §14,
//! SOM §14) — a port of
//! `tom_som_go_runtime/tests/docspecs_validator_test.go` (itself a port of the
//! TypeScript/Python/Dart reference suite): the generic schema-free parse,
//! schema loading (with warnings for unsupported features), the structured
//! violation list, and the acceptance criterion — the markdown-codec-emitted Solution
//! Blueprint sample validates cleanly against the generated
//! `solution-blueprint` schema.

use std::path::PathBuf;

use tom_som_rust_runtime::json::Json;
use tom_som_rust_runtime::spec_document::SpecDocument;
use tom_som_rust_runtime::spec_document_markdown::SpecDocumentMarkdown;
use tom_som_rust_runtime::spec_document_yaml::decode_yaml;
use tom_som_rust_runtime::spec_meta_bridge::build_som_meta_tree;
use tom_som_rust_runtime::spec_model::SpecModel;
use tom_som_rust_runtime::{
    bind_docspecs_markdown, parse_docspecs_document, DocSpecsSchema, DocSpecsSection,
    DocSpecsValidator, DocSpecsViolation, DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
    DOCSPECS_RULE_FORMAT_MISMATCH, DOCSPECS_RULE_ID_PATTERN_MISMATCH,
    DOCSPECS_RULE_MALFORMED_HEADING, DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
    DOCSPECS_RULE_MISSING_REQUIRED_SECTION, DOCSPECS_RULE_TEXT_REQUIRED,
    DOCSPECS_RULE_TOO_MANY_ITEMS, DOCSPECS_RULE_UNKNOWN_SECTION,
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

/// The ai_build folder holding the sibling runtime packages.
fn dv_siblings() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("..")
}

// ---------------------------------------------------------------------------
// Fixture schema (hand-written in the exact schema-generator output shape , SOM §13).
// ---------------------------------------------------------------------------

const DV_SCHEMA_YAML: &str = r##"title-format: "# <!--[D00]--> Demo Document"
section-types:
  goal-item:
    prefix: GOAL_ITEM_
    pattern-check-id:
      pattern: "^GOAL-ITEM-[0-9]+$"
      error-message: IDs of this section must match GOAL-ITEM-xxx
  d00-ovr:
    prefix: D00_OVR
    text-required: true
  d00-hdr:
    prefix: D00_HDR
    format: header-form
  gsum:
    prefix: GSUM
  diag:
    prefix: DIAG
    format: mermaid
  goals:
    prefix: GOALS
    subsection-types:
      goal-item:
        min-count: 1
        max-count: infinite
      gsum:
        max-count: 1
form-types:
  header-form:
    fields:
      - fieldname: author
        required: true
      - fieldname: reviewer
        pattern-check:
          pattern: "^[A-Z]"
          error-message: Reviewer must start with an uppercase letter
document:
  sections:
    d00-ovr:
      section-type: d00-ovr
    d00-hdr:
      section-type: d00-hdr
      optional: true
    goals:
      section-type: goals
      optional: true
    diag:
      section-type: diag
      optional: true
"##;

const DV_VALID_DOC: &str = r#"<!-- docspec: demo-document/1.0 -->
# <!--[D00]--> Demo Document

Intro text.

## <!--[D00-OVR]--> Overview

Some overview text.

## <!--[D00-HDR]--> Header

Author: Alice
Reviewer: Bob

## <!--[GOALS]--> Goals

### <!--[GOAL-ITEM-1]--> Goal 1

First goal.

### <!--[GOAL-ITEM-2]--> Goal 2

Second goal.
"#;

fn dv_schema() -> DocSpecsSchema {
    DocSpecsSchema::from_yaml_text(DV_SCHEMA_YAML).expect("from_yaml_text")
}

fn dv_validate(md: &str) -> Vec<DocSpecsViolation> {
    DocSpecsValidator::new(dv_schema()).validate_markdown(md)
}

fn dv_detail(violations: &[DocSpecsViolation]) -> String {
    violations
        .iter()
        .map(|v| v.to_display())
        .collect::<Vec<String>>()
        .join("; ")
}

fn dv_child_ids(s: &DocSpecsSection) -> Vec<&str> {
    s.children.iter().map(|c| c.id.as_str()).collect()
}

// --- DocSpecsDocument parse (generic, schema-free) ---------------------------

fn test_docspecs_parse_tree(c: &mut Checker) {
    let doc = parse_docspecs_document(DV_VALID_DOC);
    c.check(
        "parse.declaredSchema",
        doc.declared_schema == "demo-document/1.0",
        &doc.declared_schema,
    );
    c.check(
        "parse.noViolations",
        doc.violations.is_empty(),
        &dv_detail(&doc.violations),
    );
    c.check(
        "parse.oneRoot",
        doc.sections.len() == 1,
        &doc.sections.len().to_string(),
    );
    let root = &doc.sections[0];
    c.check("parse.root.id", root.id == "D00", &root.id);
    c.check("parse.root.title", root.title == "Demo Document", &root.title);
    c.check("parse.root.level", root.level == 1, &root.level.to_string());
    c.check(
        "parse.root.text",
        root.text() == "Intro text.",
        &format!("{:?}", root.text()),
    );
    c.check(
        "parse.root.children",
        dv_child_ids(root) == ["D00-OVR", "D00-HDR", "GOALS"],
        &dv_child_ids(root).join(","),
    );
    let goals = root.children.last().unwrap();
    c.check(
        "parse.goals.children",
        dv_child_ids(goals) == ["GOAL-ITEM-1", "GOAL-ITEM-2"],
        &dv_child_ids(goals).join(","),
    );
    c.check(
        "parse.goal1.text",
        goals.children[0].text() == "First goal.",
        &format!("{:?}", goals.children[0].text()),
    );
}

fn test_docspecs_parse_fence_shield(c: &mut Checker) {
    let doc = parse_docspecs_document(
        "# <!--[D00]--> Demo Document\n\n```md\n## <!--[NOT-A-SECTION]--> shielded\n```\n",
    );
    c.check(
        "parse.fence.noChildren",
        doc.sections[0].children.is_empty(),
        "",
    );
    c.check(
        "parse.fence.bodyKept",
        doc.sections[0].text().contains("NOT-A-SECTION"),
        "",
    );
}

fn test_docspecs_parse_malformed_heading(c: &mut Checker) {
    let doc = parse_docspecs_document("# <!--[D00]--> Demo Document\n\n## Plain Heading\n");
    c.check(
        "parse.malformed.count",
        doc.violations.len() == 1,
        &dv_detail(&doc.violations),
    );
    if !doc.violations.is_empty() {
        let v = &doc.violations[0];
        c.check(
            "parse.malformed.rule",
            v.rule == DOCSPECS_RULE_MALFORMED_HEADING,
            &v.to_display(),
        );
        c.check("parse.malformed.line", v.line == 3, &v.line.to_string());
    }
}

// --- DocSpecsSchema::from_yaml_text ------------------------------------------

fn test_docspecs_schema_loading(c: &mut Checker) {
    let schema = dv_schema();
    c.check(
        "schema.noWarnings",
        schema.warnings.is_empty(),
        &schema.warnings.join("; "),
    );
    c.check(
        "schema.rootSectionId",
        schema.root_section_id() == "D00",
        &schema.root_section_id(),
    );
    let goal_item = schema.section_type_named("goal-item");
    c.check("schema.goalItem.present", goal_item.is_some(), "");
    if let Some(goal_item) = goal_item {
        c.check(
            "schema.goalItem.prefix",
            goal_item.prefix == "GOAL_ITEM_",
            &goal_item.prefix,
        );
        c.check(
            "schema.goalItem.pattern",
            goal_item
                .pattern_check
                .as_ref()
                .is_some_and(|pc| pc.pattern == "^GOAL-ITEM-[0-9]+$"),
            &format!("{:?}", goal_item.pattern_check),
        );
    }
    let goals = schema.section_type_named("goals").unwrap();
    c.check(
        "schema.goals.min",
        goals.subsection_rule("goal-item").unwrap().min_count == 1,
        "",
    );
    c.check(
        "schema.goals.maxInfinite",
        goals.subsection_rule("goal-item").unwrap().max_count.is_none(),
        "",
    );
    c.check(
        "schema.gsum.max1",
        goals.subsection_rule("gsum").unwrap().max_count == Some(1),
        "",
    );
    let form = schema.form_types.get("header-form").unwrap();
    let field_names: Vec<&str> = form.fields.iter().map(|f| f.name.as_str()).collect();
    c.check(
        "schema.form.fields",
        field_names == ["author", "reviewer"],
        &field_names.join(","),
    );
    c.check("schema.form.authorRequired", form.fields[0].required, "");
    c.check(
        "schema.doc.ovrRequired",
        !schema.document_section("d00-ovr").unwrap().optional,
        "",
    );
    c.check(
        "schema.doc.hdrOptional",
        schema.document_section("d00-hdr").unwrap().optional,
        "",
    );
}

fn test_docspecs_schema_resolution(c: &mut Checker) {
    let schema = dv_schema();
    let name_of = |id: &str| -> String {
        match schema.resolve_section_type(id) {
            Some(st) => st.name.clone(),
            None => "<nil>".to_string(),
        }
    };
    c.check(
        "resolve.goalItem",
        name_of("GOAL-ITEM-7") == "goal-item",
        &name_of("GOAL-ITEM-7"),
    );
    c.check("resolve.goals", name_of("GOALS") == "goals", &name_of("GOALS"));
    c.check("resolve.ovr", name_of("D00-OVR") == "d00-ovr", &name_of("D00-OVR"));
    c.check("resolve.none", name_of("NOPE-1") == "<nil>", &name_of("NOPE-1"));
}

fn test_docspecs_schema_warnings(c: &mut Checker) {
    let schema = DocSpecsSchema::from_yaml_text(
        "title-format: \"# <!--[D00]--> Demo\"\n\
         generators:\n\
         \x20 something: true\n\
         section-types:\n\
         \x20 d00-ovr:\n\
         \x20   prefix: D00_OVR\n\
         \x20   database-schema:\n\
         \x20     table: t\n\
         document:\n\
         \x20 sections:\n\
         \x20   d00-ovr:\n\
         \x20     section-type: d00-ovr\n\
         \x20 custom-tag: x\n",
    )
    .expect("from_yaml_text");
    c.check(
        "warnings.count",
        schema.warnings.len() == 3,
        &schema.warnings.join("; "),
    );
    let joined = schema.warnings.join("\n");
    c.check("warnings.generators", joined.contains("generators"), &joined);
    c.check(
        "warnings.databaseSchema",
        joined.contains("database-schema"),
        &joined,
    );
    c.check("warnings.customTag", joined.contains("custom-tag"), &joined);
    // The supported parts still load.
    c.check(
        "warnings.stillLoads",
        schema.section_type_named("d00-ovr").is_some(),
        "",
    );
}

// --- DocSpecsValidator::validate ----------------------------------------------

fn test_docspecs_validate_valid(c: &mut Checker) {
    let v = dv_validate(DV_VALID_DOC);
    c.check("validate.valid.empty", v.is_empty(), &dv_detail(&v));
}

fn test_docspecs_validate_missing_required_section(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen("## <!--[D00-OVR]--> Overview\n\nSome overview text.\n\n", "", 1);
    let v = dv_validate(&md);
    c.check("validate.missingSection.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.missingSection.rule",
            v[0].rule == DOCSPECS_RULE_MISSING_REQUIRED_SECTION,
            &v[0].to_display(),
        );
        c.check(
            "validate.missingSection.id",
            v[0].section_id == "d00-ovr",
            &v[0].section_id,
        );
        c.check(
            "validate.missingSection.msg",
            v[0].message.contains("d00-ovr"),
            &v[0].message,
        );
    }
}

fn test_docspecs_validate_id_pattern_mismatch(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen("GOAL-ITEM-2", "GOAL-ITEM-B", 1);
    let v = dv_validate(&md);
    c.check("validate.idPattern.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.idPattern.rule",
            v[0].rule == DOCSPECS_RULE_ID_PATTERN_MISMATCH,
            &v[0].to_display(),
        );
        c.check(
            "validate.idPattern.id",
            v[0].section_id == "GOAL-ITEM-B",
            &v[0].section_id,
        );
        c.check(
            "validate.idPattern.msg",
            v[0].message == "IDs of this section must match GOAL-ITEM-xxx",
            &v[0].message,
        );
        c.check("validate.idPattern.line", v[0].line == 21, &v[0].line.to_string());
    }
}

fn test_docspecs_validate_unknown_section(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen(
        "### <!--[GOAL-ITEM-2]--> Goal 2",
        "### <!--[XYZ-2]--> Goal 2",
        1,
    );
    let v = dv_validate(&md);
    c.check("validate.unknown.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.unknown.rule",
            v[0].rule == DOCSPECS_RULE_UNKNOWN_SECTION,
            &v[0].to_display(),
        );
        c.check("validate.unknown.id", v[0].section_id == "XYZ-2", &v[0].section_id);
    }
}

fn test_docspecs_validate_disallowed_position(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen(
        "### <!--[GOAL-ITEM-2]--> Goal 2",
        "### <!--[DIAG]--> Diagram",
        1,
    );
    let v = dv_validate(&md);
    c.check("validate.disallowed.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.disallowed.rule",
            v[0].rule == DOCSPECS_RULE_UNKNOWN_SECTION,
            &v[0].to_display(),
        );
        c.check(
            "validate.disallowed.msg",
            v[0].message.contains("not an allowed subsection"),
            &v[0].message,
        );
    }
}

fn test_docspecs_validate_missing_required_field(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen("Author: Alice\n", "", 1);
    let v = dv_validate(&md);
    c.check("validate.missingField.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.missingField.rule",
            v[0].rule == DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
            &v[0].to_display(),
        );
        c.check(
            "validate.missingField.id",
            v[0].section_id == "D00-HDR",
            &v[0].section_id,
        );
        c.check(
            "validate.missingField.msg",
            v[0].message.contains("author"),
            &v[0].message,
        );
    }
}

fn test_docspecs_validate_field_pattern_mismatch(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen("Reviewer: Bob", "Reviewer: bob", 1);
    let v = dv_validate(&md);
    c.check("validate.fieldPattern.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.fieldPattern.rule",
            v[0].rule == DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
            &v[0].to_display(),
        );
        c.check(
            "validate.fieldPattern.msg",
            v[0].message == "Reviewer must start with an uppercase letter",
            &v[0].message,
        );
        c.check(
            "validate.fieldPattern.line",
            v[0].line == 13,
            &v[0].line.to_string(),
        );
    }
}

fn test_docspecs_validate_text_required(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen("Some overview text.\n\n", "", 1);
    let v = dv_validate(&md);
    c.check("validate.textRequired.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.textRequired.rule",
            v[0].rule == DOCSPECS_RULE_TEXT_REQUIRED,
            &v[0].to_display(),
        );
        c.check(
            "validate.textRequired.id",
            v[0].section_id == "D00-OVR",
            &v[0].section_id,
        );
    }
}

fn test_docspecs_validate_too_many_items(c: &mut Checker) {
    let md = format!(
        "{}\n### <!--[GSUM]--> Summary\n\nOne.\n\n### <!--[GSUM]--> Summary\n\nTwo.\n",
        DV_VALID_DOC
    );
    let v = dv_validate(&md);
    c.check("validate.tooMany.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.tooMany.rule",
            v[0].rule == DOCSPECS_RULE_TOO_MANY_ITEMS,
            &v[0].to_display(),
        );
        c.check("validate.tooMany.msg", v[0].message.contains("gsum"), &v[0].message);
    }
}

fn test_docspecs_validate_format_mismatch(c: &mut Checker) {
    let md = format!("{}\n## <!--[DIAG]--> Diagram\n\nno fence here\n", DV_VALID_DOC);
    let v = dv_validate(&md);
    c.check("validate.format.count", v.len() == 1, &dv_detail(&v));
    if !v.is_empty() {
        c.check(
            "validate.format.rule",
            v[0].rule == DOCSPECS_RULE_FORMAT_MISMATCH,
            &v[0].to_display(),
        );
    }
    let ok = format!(
        "{}\n## <!--[DIAG]--> Diagram\n\n```mermaid\ngraph TD;\n```\n",
        DV_VALID_DOC
    );
    let v_ok = dv_validate(&ok);
    c.check("validate.format.fencedOk", v_ok.is_empty(), &dv_detail(&v_ok));
}

fn test_docspecs_validate_root_mismatch(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen("# <!--[D00]-->", "# <!--[D99]-->", 1);
    let v = dv_validate(&md);
    let found = v.iter().any(|x| x.rule == DOCSPECS_RULE_FORMAT_MISMATCH);
    c.check("validate.rootMismatch.rule", found, &dv_detail(&v));
}

fn test_docspecs_validate_never_fail_fast(c: &mut Checker) {
    let md = DV_VALID_DOC.replacen("Author: Alice\n", "", 1);
    let md = md.replacen("Reviewer: Bob", "Reviewer: bob", 1);
    let md = md.replacen("GOAL-ITEM-2", "GOAL-ITEM-B", 1);
    let v = dv_validate(&md);
    let mut got: Vec<&str> = Vec::new();
    for x in &v {
        if !got.contains(&x.rule.as_str()) {
            got.push(&x.rule);
        }
    }
    got.sort_unstable();
    let mut want = [
        DOCSPECS_RULE_MISSING_REQUIRED_FIELD,
        DOCSPECS_RULE_FIELD_PATTERN_MISMATCH,
        DOCSPECS_RULE_ID_PATTERN_MISMATCH,
    ];
    want.sort_unstable();
    c.check(
        "validate.neverFailFast",
        got == want,
        &format!("{} != {}", got.join(","), want.join(",")),
    );
}

// --- bind_docspecs_markdown ----------------------------------------------------

fn test_docspecs_bind_docspecs_markdown(c: &mut Checker) {
    let corpus = dv_siblings().join("tom_som_conformance").join("corpus");
    let model_text =
        std::fs::read_to_string(corpus.join("model.meta.json")).expect("read model.meta.json");
    let model = SpecModel::from_json(&Json::parse(&model_text).expect("parse model.meta.json"));
    let md_text = std::fs::read_to_string(corpus.join("expected.md")).expect("read expected.md");
    let result = bind_docspecs_markdown(&model, &SpecDocument::new(), &md_text);
    let rej = result
        .rejections
        .iter()
        .map(|r| r.to_display())
        .collect::<Vec<String>>()
        .join("; ");
    c.check("bind.clean", result.is_clean(), &rej);
    c.check(
        "bind.appliedCount",
        result.applied_count() > 0,
        &result.applied_count().to_string(),
    );
}

// --- acceptance: emitted sample vs generated schema ----------------------------

/// The Solution Blueprint sample emitted by the markdown codec (SOM §11) validates cleanly
/// against the generated `solution-blueprint` schema.
fn test_docspecs_dr7_acceptance(c: &mut Checker) {
    let meta_path = dv_siblings()
        .join("tom_som_dart_v0")
        .join("meta")
        .join("spec_model.meta.json");
    let meta_text = std::fs::read_to_string(&meta_path)
        .unwrap_or_else(|e| panic!("read {}: {}", meta_path.display(), e));
    let model = SpecModel::from_json(&Json::parse(&meta_text).expect("parse spec_model.meta.json"));
    // The shared sample is a hierarchical-v2 `*.docspecs.yaml` (SOM §12): decode it
    // against the metadata tree bridged from the exported model.
    let sample_path = dv_siblings()
        .join("tom_som_conformance")
        .join("samples")
        .join("meridian_order_management.docspecs.yaml");
    let tree = build_som_meta_tree(&model, "D00SolutionBlueprint").expect("build_som_meta_tree");
    let sample_text = std::fs::read_to_string(&sample_path)
        .unwrap_or_else(|e| panic!("read {}: {}", sample_path.display(), e));
    let contents = decode_yaml(&sample_text, &tree)
        .unwrap_or_else(|e| panic!("decode_yaml({}): {}", sample_path.display(), e));
    // The Go test's `ToMarkdown(model, "")` — export the single populated root.
    let root = model
        .roots
        .iter()
        .find(|r| {
            let seg = if r.section_id.is_empty() {
                r.type_.as_str()
            } else {
                r.section_id.as_str()
            };
            contents.document.has_values_under(seg)
        })
        .expect("populated root");
    let md = SpecDocumentMarkdown::new(&model, &contents.document)
        .export_root(root)
        .expect("export_root");

    let schema_path = dv_siblings()
        .join("tom_som_dart_v0")
        .join("schemas")
        .join("solution-blueprint")
        .join("solution-blueprint.1.0.docspecs-schema.yaml");
    let schema_text = std::fs::read_to_string(&schema_path)
        .unwrap_or_else(|e| panic!("read {}: {}", schema_path.display(), e));
    let schema = DocSpecsSchema::from_yaml_text(&schema_text).expect("from_yaml_text");
    c.check(
        "dr7.rootSectionId",
        schema.root_section_id() == "SBP",
        &schema.root_section_id(),
    );

    let violations = DocSpecsValidator::new(schema).validate_markdown(&md);
    let mut detail = String::new();
    for v in violations.iter().take(20) {
        detail.push('\n');
        detail.push_str(&v.to_display());
    }
    c.check("dr7.violationsEmpty", violations.is_empty(), &detail);
}

#[test]
fn docspecs_validator() {
    let mut c = Checker::new();
    test_docspecs_parse_tree(&mut c);
    test_docspecs_parse_fence_shield(&mut c);
    test_docspecs_parse_malformed_heading(&mut c);
    test_docspecs_schema_loading(&mut c);
    test_docspecs_schema_resolution(&mut c);
    test_docspecs_schema_warnings(&mut c);
    test_docspecs_validate_valid(&mut c);
    test_docspecs_validate_missing_required_section(&mut c);
    test_docspecs_validate_id_pattern_mismatch(&mut c);
    test_docspecs_validate_unknown_section(&mut c);
    test_docspecs_validate_disallowed_position(&mut c);
    test_docspecs_validate_missing_required_field(&mut c);
    test_docspecs_validate_field_pattern_mismatch(&mut c);
    test_docspecs_validate_text_required(&mut c);
    test_docspecs_validate_too_many_items(&mut c);
    test_docspecs_validate_format_mismatch(&mut c);
    test_docspecs_validate_root_mismatch(&mut c);
    test_docspecs_validate_never_fail_fast(&mut c);
    test_docspecs_bind_docspecs_markdown(&mut c);
    test_docspecs_dr7_acceptance(&mut c);
    c.finish();
}
