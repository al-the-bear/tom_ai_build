// Tests for the consolidated DocSpecs parsing + validation module (SOM §14,
// SOM §14) — a port of
// `tom_som_typescript_runtime/tests/docspecs_validator_test.ts` (itself a port
// of the Python/Dart reference suite): the generic schema-free parse, schema
// loading (with warnings for unsupported features), the structured violation
// list, and the acceptance criterion — the markdown-codec-emitted Solution Blueprint
// sample validates cleanly against the generated `solution-blueprint`
// schema.
package tests

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// dvSiblings is the ai_build folder holding the sibling runtime packages.
const dvSiblings = "../.."

// ---------------------------------------------------------------------------
// Fixture schema (hand-written in the exact schema-generator output shape , SOM §13).
// ---------------------------------------------------------------------------

const dvSchemaYaml = `title-format: "# <!--[D00]--> Demo Document"
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
`

const dvValidDoc = `<!-- docspec: demo-document/1.0 -->
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
`

func dvSchema(t *testing.T) *som.DocSpecsSchema {
	t.Helper()
	schema, err := som.DocSpecsSchemaFromYamlText(dvSchemaYaml)
	if err != nil {
		t.Fatalf("DocSpecsSchemaFromYamlText: %v", err)
	}
	return schema
}

func dvValidate(t *testing.T, md string) []*som.DocSpecsViolation {
	t.Helper()
	return som.NewDocSpecsValidator(dvSchema(t)).ValidateMarkdown(md)
}

func dvDetail(violations []*som.DocSpecsViolation) string {
	parts := make([]string, 0, len(violations))
	for _, v := range violations {
		parts = append(parts, v.String())
	}
	return strings.Join(parts, "; ")
}

func dvListEqual(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func dvChildIDs(s *som.DocSpecsSection) []string {
	ids := make([]string, 0, len(s.Children))
	for _, c := range s.Children {
		ids = append(ids, c.ID)
	}
	return ids
}

// --- DocSpecsDocument parse (generic, schema-free) ---------------------------

func TestDocspecsParseTree(t *testing.T) {
	doc := som.ParseDocSpecsDocument(dvValidDoc)
	mdCheck(t, "parse.declaredSchema", doc.DeclaredSchema == "demo-document/1.0", doc.DeclaredSchema)
	mdCheck(t, "parse.noViolations", len(doc.Violations) == 0, dvDetail(doc.Violations))
	mdCheck(t, "parse.oneRoot", len(doc.Sections) == 1, fmt.Sprintf("%d", len(doc.Sections)))
	root := doc.Sections[0]
	mdCheck(t, "parse.root.id", root.ID == "D00", root.ID)
	mdCheck(t, "parse.root.title", root.Title == "Demo Document", root.Title)
	mdCheck(t, "parse.root.level", root.Level == 1, fmt.Sprintf("%d", root.Level))
	mdCheck(t, "parse.root.text", root.Text() == "Intro text.", fmt.Sprintf("%q", root.Text()))
	mdCheck(t, "parse.root.children",
		dvListEqual(dvChildIDs(root), []string{"D00-OVR", "D00-HDR", "GOALS"}),
		strings.Join(dvChildIDs(root), ","))
	goals := root.Children[len(root.Children)-1]
	mdCheck(t, "parse.goals.children",
		dvListEqual(dvChildIDs(goals), []string{"GOAL-ITEM-1", "GOAL-ITEM-2"}),
		strings.Join(dvChildIDs(goals), ","))
	mdCheck(t, "parse.goal1.text", goals.Children[0].Text() == "First goal.",
		fmt.Sprintf("%q", goals.Children[0].Text()))
}

func TestDocspecsParseFenceShield(t *testing.T) {
	doc := som.ParseDocSpecsDocument(
		"# <!--[D00]--> Demo Document\n" +
			"\n" +
			"```md\n" +
			"## <!--[NOT-A-SECTION]--> shielded\n" +
			"```\n")
	mdCheck(t, "parse.fence.noChildren", len(doc.Sections[0].Children) == 0)
	mdCheck(t, "parse.fence.bodyKept", strings.Contains(doc.Sections[0].Text(), "NOT-A-SECTION"))
}

func TestDocspecsParseMalformedHeading(t *testing.T) {
	doc := som.ParseDocSpecsDocument(
		"# <!--[D00]--> Demo Document\n" + "\n" + "## Plain Heading\n")
	mdCheck(t, "parse.malformed.count", len(doc.Violations) == 1, dvDetail(doc.Violations))
	if len(doc.Violations) > 0 {
		v := doc.Violations[0]
		mdCheck(t, "parse.malformed.rule", v.Rule == som.DocSpecsRuleMalformedHeading, v.String())
		mdCheck(t, "parse.malformed.line", v.Line == 3, fmt.Sprintf("%d", v.Line))
	}
}

// --- DocSpecsSchemaFromYamlText ----------------------------------------------

func TestDocspecsSchemaLoading(t *testing.T) {
	schema := dvSchema(t)
	mdCheck(t, "schema.noWarnings", len(schema.Warnings) == 0, strings.Join(schema.Warnings, "; "))
	mdCheck(t, "schema.rootSectionId", schema.RootSectionID() == "D00", schema.RootSectionID())
	goalItem, present := schema.SectionTypesByName["goal-item"]
	mdCheck(t, "schema.goalItem.present", present)
	if present {
		mdCheck(t, "schema.goalItem.prefix", goalItem.Prefix == "GOAL_ITEM_", goalItem.Prefix)
		mdCheck(t, "schema.goalItem.pattern",
			goalItem.PatternCheck != nil && goalItem.PatternCheck.Pattern == "^GOAL-ITEM-[0-9]+$",
			fmt.Sprintf("%v", goalItem.PatternCheck))
	}
	goals := schema.SectionTypesByName["goals"]
	mdCheck(t, "schema.goals.min", goals.SubsectionTypes["goal-item"].MinCount == 1)
	mdCheck(t, "schema.goals.maxInfinite", goals.SubsectionTypes["goal-item"].MaxCount == nil)
	mdCheck(t, "schema.gsum.max1",
		goals.SubsectionTypes["gsum"].MaxCount != nil && *goals.SubsectionTypes["gsum"].MaxCount == 1)
	form := schema.FormTypes["header-form"]
	fieldNames := make([]string, 0, len(form.Fields))
	for _, f := range form.Fields {
		fieldNames = append(fieldNames, f.Name)
	}
	mdCheck(t, "schema.form.fields",
		dvListEqual(fieldNames, []string{"author", "reviewer"}), strings.Join(fieldNames, ","))
	mdCheck(t, "schema.form.authorRequired", form.Fields[0].Required)
	mdCheck(t, "schema.doc.ovrRequired", !schema.DocumentSections["d00-ovr"].Optional)
	mdCheck(t, "schema.doc.hdrOptional", schema.DocumentSections["d00-hdr"].Optional)
}

func TestDocspecsSchemaResolution(t *testing.T) {
	schema := dvSchema(t)
	nameOf := func(id string) string {
		st := schema.ResolveSectionType(id)
		if st == nil {
			return "<nil>"
		}
		return st.Name
	}
	mdCheck(t, "resolve.goalItem", nameOf("GOAL-ITEM-7") == "goal-item", nameOf("GOAL-ITEM-7"))
	mdCheck(t, "resolve.goals", nameOf("GOALS") == "goals", nameOf("GOALS"))
	mdCheck(t, "resolve.ovr", nameOf("D00-OVR") == "d00-ovr", nameOf("D00-OVR"))
	mdCheck(t, "resolve.none", nameOf("NOPE-1") == "<nil>", nameOf("NOPE-1"))
}

func TestDocspecsSchemaWarnings(t *testing.T) {
	schema, err := som.DocSpecsSchemaFromYamlText(
		"title-format: \"# <!--[D00]--> Demo\"\n" +
			"generators:\n" +
			"  something: true\n" +
			"section-types:\n" +
			"  d00-ovr:\n" +
			"    prefix: D00_OVR\n" +
			"    database-schema:\n" +
			"      table: t\n" +
			"document:\n" +
			"  sections:\n" +
			"    d00-ovr:\n" +
			"      section-type: d00-ovr\n" +
			"  custom-tag: x\n")
	if err != nil {
		t.Fatalf("DocSpecsSchemaFromYamlText: %v", err)
	}
	mdCheck(t, "warnings.count", len(schema.Warnings) == 3, strings.Join(schema.Warnings, "; "))
	joined := strings.Join(schema.Warnings, "\n")
	mdCheck(t, "warnings.generators", strings.Contains(joined, "generators"), joined)
	mdCheck(t, "warnings.databaseSchema", strings.Contains(joined, "database-schema"), joined)
	mdCheck(t, "warnings.customTag", strings.Contains(joined, "custom-tag"), joined)
	// The supported parts still load.
	mdCheck(t, "warnings.stillLoads", schema.SectionTypesByName["d00-ovr"] != nil)
}

// --- DocSpecsValidator.Validate ------------------------------------------------

func TestDocspecsValidateValid(t *testing.T) {
	v := dvValidate(t, dvValidDoc)
	mdCheck(t, "validate.valid.empty", len(v) == 0, dvDetail(v))
}

func TestDocspecsValidateMissingRequiredSection(t *testing.T) {
	md := strings.Replace(dvValidDoc,
		"## <!--[D00-OVR]--> Overview\n\nSome overview text.\n\n", "", 1)
	v := dvValidate(t, md)
	mdCheck(t, "validate.missingSection.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.missingSection.rule",
			v[0].Rule == som.DocSpecsRuleMissingRequiredSection, v[0].String())
		mdCheck(t, "validate.missingSection.id", v[0].SectionID == "d00-ovr", v[0].SectionID)
		mdCheck(t, "validate.missingSection.msg", strings.Contains(v[0].Message, "d00-ovr"), v[0].Message)
	}
}

func TestDocspecsValidateIdPatternMismatch(t *testing.T) {
	md := strings.Replace(dvValidDoc, "GOAL-ITEM-2", "GOAL-ITEM-B", 1)
	v := dvValidate(t, md)
	mdCheck(t, "validate.idPattern.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.idPattern.rule",
			v[0].Rule == som.DocSpecsRuleIDPatternMismatch, v[0].String())
		mdCheck(t, "validate.idPattern.id", v[0].SectionID == "GOAL-ITEM-B", v[0].SectionID)
		mdCheck(t, "validate.idPattern.msg",
			v[0].Message == "IDs of this section must match GOAL-ITEM-xxx", v[0].Message)
		mdCheck(t, "validate.idPattern.line", v[0].Line == 21, fmt.Sprintf("%d", v[0].Line))
	}
}

func TestDocspecsValidateUnknownSection(t *testing.T) {
	md := strings.Replace(dvValidDoc,
		"### <!--[GOAL-ITEM-2]--> Goal 2", "### <!--[XYZ-2]--> Goal 2", 1)
	v := dvValidate(t, md)
	mdCheck(t, "validate.unknown.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.unknown.rule", v[0].Rule == som.DocSpecsRuleUnknownSection, v[0].String())
		mdCheck(t, "validate.unknown.id", v[0].SectionID == "XYZ-2", v[0].SectionID)
	}
}

func TestDocspecsValidateDisallowedPosition(t *testing.T) {
	md := strings.Replace(dvValidDoc,
		"### <!--[GOAL-ITEM-2]--> Goal 2", "### <!--[DIAG]--> Diagram", 1)
	v := dvValidate(t, md)
	mdCheck(t, "validate.disallowed.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.disallowed.rule",
			v[0].Rule == som.DocSpecsRuleUnknownSection, v[0].String())
		mdCheck(t, "validate.disallowed.msg",
			strings.Contains(v[0].Message, "not an allowed subsection"), v[0].Message)
	}
}

func TestDocspecsValidateMissingRequiredField(t *testing.T) {
	md := strings.Replace(dvValidDoc, "Author: Alice\n", "", 1)
	v := dvValidate(t, md)
	mdCheck(t, "validate.missingField.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.missingField.rule",
			v[0].Rule == som.DocSpecsRuleMissingRequiredField, v[0].String())
		mdCheck(t, "validate.missingField.id", v[0].SectionID == "D00-HDR", v[0].SectionID)
		mdCheck(t, "validate.missingField.msg", strings.Contains(v[0].Message, "author"), v[0].Message)
	}
}

func TestDocspecsValidateFieldPatternMismatch(t *testing.T) {
	md := strings.Replace(dvValidDoc, "Reviewer: Bob", "Reviewer: bob", 1)
	v := dvValidate(t, md)
	mdCheck(t, "validate.fieldPattern.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.fieldPattern.rule",
			v[0].Rule == som.DocSpecsRuleFieldPatternMismatch, v[0].String())
		mdCheck(t, "validate.fieldPattern.msg",
			v[0].Message == "Reviewer must start with an uppercase letter", v[0].Message)
		mdCheck(t, "validate.fieldPattern.line", v[0].Line == 13, fmt.Sprintf("%d", v[0].Line))
	}
}

func TestDocspecsValidateTextRequired(t *testing.T) {
	md := strings.Replace(dvValidDoc, "Some overview text.\n\n", "", 1)
	v := dvValidate(t, md)
	mdCheck(t, "validate.textRequired.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.textRequired.rule",
			v[0].Rule == som.DocSpecsRuleTextRequired, v[0].String())
		mdCheck(t, "validate.textRequired.id", v[0].SectionID == "D00-OVR", v[0].SectionID)
	}
}

func TestDocspecsValidateTooManyItems(t *testing.T) {
	md := dvValidDoc + "\n" +
		"### <!--[GSUM]--> Summary\n\nOne.\n\n" +
		"### <!--[GSUM]--> Summary\n\nTwo.\n"
	v := dvValidate(t, md)
	mdCheck(t, "validate.tooMany.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.tooMany.rule", v[0].Rule == som.DocSpecsRuleTooManyItems, v[0].String())
		mdCheck(t, "validate.tooMany.msg", strings.Contains(v[0].Message, "gsum"), v[0].Message)
	}
}

func TestDocspecsValidateFormatMismatch(t *testing.T) {
	md := dvValidDoc + "\n## <!--[DIAG]--> Diagram\n\nno fence here\n"
	v := dvValidate(t, md)
	mdCheck(t, "validate.format.count", len(v) == 1, dvDetail(v))
	if len(v) > 0 {
		mdCheck(t, "validate.format.rule", v[0].Rule == som.DocSpecsRuleFormatMismatch, v[0].String())
	}
	ok := dvValidDoc + "\n## <!--[DIAG]--> Diagram\n\n" + "```mermaid\ngraph TD;\n```\n"
	vOk := dvValidate(t, ok)
	mdCheck(t, "validate.format.fencedOk", len(vOk) == 0, dvDetail(vOk))
}

func TestDocspecsValidateRootMismatch(t *testing.T) {
	md := strings.Replace(dvValidDoc, "# <!--[D00]-->", "# <!--[D99]-->", 1)
	v := dvValidate(t, md)
	found := false
	for _, x := range v {
		if x.Rule == som.DocSpecsRuleFormatMismatch {
			found = true
		}
	}
	mdCheck(t, "validate.rootMismatch.rule", found, dvDetail(v))
}

func TestDocspecsValidateNeverFailFast(t *testing.T) {
	md := strings.Replace(dvValidDoc, "Author: Alice\n", "", 1)
	md = strings.Replace(md, "Reviewer: Bob", "Reviewer: bob", 1)
	md = strings.Replace(md, "GOAL-ITEM-2", "GOAL-ITEM-B", 1)
	v := dvValidate(t, md)
	seen := map[string]bool{}
	var got []string
	for _, x := range v {
		if !seen[x.Rule] {
			seen[x.Rule] = true
			got = append(got, x.Rule)
		}
	}
	sort.Strings(got)
	want := []string{
		som.DocSpecsRuleMissingRequiredField,
		som.DocSpecsRuleFieldPatternMismatch,
		som.DocSpecsRuleIDPatternMismatch,
	}
	sort.Strings(want)
	mdCheck(t, "validate.neverFailFast", dvListEqual(got, want),
		strings.Join(got, ",")+" != "+strings.Join(want, ","))
}

// --- BindDocspecsMarkdown ------------------------------------------------------

func TestDocspecsBindDocspecsMarkdown(t *testing.T) {
	corpus := filepath.Join(dvSiblings, "tom_som_conformance", "corpus")
	modelBytes, err := os.ReadFile(filepath.Join(corpus, "model.meta.json"))
	if err != nil {
		t.Fatalf("read model.meta.json: %v", err)
	}
	model, err := som.SpecModelFromJSON(modelBytes)
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	mdBytes, err := os.ReadFile(filepath.Join(corpus, "expected.md"))
	if err != nil {
		t.Fatalf("read expected.md: %v", err)
	}
	result := som.BindDocspecsMarkdown(model, som.NewSpecDocument(), string(mdBytes))
	mdCheck(t, "bind.clean", result.IsClean(), mdRejStr(result))
	mdCheck(t, "bind.appliedCount", result.AppliedCount() > 0, fmt.Sprintf("%d", result.AppliedCount()))
}

// --- acceptance: emitted sample vs generated schema ----------------------------

// The Solution Blueprint sample emitted by the markdown codec (SOM §11) validates cleanly
// against the generated `solution-blueprint` schema.
func TestDocspecsDr7Acceptance(t *testing.T) {
	metaPath := filepath.Join(dvSiblings, "tom_som_dart_v0", "meta", "spec_model.meta.json")
	metaBytes, err := os.ReadFile(metaPath)
	if err != nil {
		t.Fatalf("read %s: %v", metaPath, err)
	}
	model, err := som.SpecModelFromJSON(metaBytes)
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	// The shared sample is a hierarchical-v2 `*.docspecs.yaml` (SOM §12): decode it
	// against the metadata tree bridged from the exported model.
	samplePath := filepath.Join(
		dvSiblings, "tom_som_conformance", "samples",
		"meridian_order_management.docspecs.yaml")
	tree, err := som.BuildSomMetaTree(model, "D00SolutionBlueprint")
	if err != nil {
		t.Fatalf("BuildSomMetaTree: %v", err)
	}
	document, err := som.FromFile(samplePath, tree)
	if err != nil {
		t.Fatalf("FromFile(%s): %v", samplePath, err)
	}
	md, err := document.ToMarkdown(model, "")
	if err != nil {
		t.Fatalf("ToMarkdown: %v", err)
	}

	schemaPath := filepath.Join(
		dvSiblings, "tom_som_dart_v0", "schemas", "solution-blueprint",
		"solution-blueprint.1.0.docspecs-schema.yaml")
	schemaBytes, err := os.ReadFile(schemaPath)
	if err != nil {
		t.Fatalf("read %s: %v", schemaPath, err)
	}
	schema, err := som.DocSpecsSchemaFromYamlText(string(schemaBytes))
	if err != nil {
		t.Fatalf("DocSpecsSchemaFromYamlText: %v", err)
	}
	mdCheck(t, "dr7.rootSectionId", schema.RootSectionID() == "SBP", schema.RootSectionID())

	violations := som.NewDocSpecsValidator(schema).ValidateMarkdown(md)
	detail := ""
	for i, v := range violations {
		if i >= 20 {
			break
		}
		detail += "\n" + v.String()
	}
	mdCheck(t, "dr7.violationsEmpty", len(violations) == 0, detail)
}
