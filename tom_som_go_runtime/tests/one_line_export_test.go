// Tests for SOM §21 — the two one-call conveniences ported from
// the Dart reference runtime:
//
//   - SpecModel.RootByType(type) — the root whose Type matches, else an error
//     naming the missing type and the available ones (mirrors
//     `SpecModel.rootByType` in spec_model.dart).
//   - SpecDocument.ToMarkdown(model, rootType) — render to Markdown in one call,
//     defaulting to the single populated root when rootType is "" (mirrors
//     `SpecDocument.toMarkdown` + `_singlePopulatedRoot` in spec_document.dart).
package tests

import (
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// twoRootModelJSON is the two-root, class-less fixture from the Dart
// `SpecModel.rootByType (one-line export, SOM §21)` group.
const twoRootModelJSON = `{
  "roots": [
    {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
    {"type": "Beta",  "title": "Beta Doc",  "sectionId": "B00"}
  ],
  "classes": {}
}`

func twoRootModel(t *testing.T) *som.SpecModel {
	t.Helper()
	m, err := som.SpecModelFromJSON([]byte(twoRootModelJSON))
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	return m
}

// TestRootByTypeReturnsMatch: RootByType returns the root whose Type matches.
func TestRootByTypeReturnsMatch(t *testing.T) {
	m := twoRootModel(t)

	alpha, err := m.RootByType("Alpha")
	if err != nil {
		t.Fatalf("RootByType(Alpha): unexpected error %v", err)
	}
	if alpha.Title != "Alpha Doc" {
		t.Errorf("RootByType(Alpha).Title = %q, want %q", alpha.Title, "Alpha Doc")
	}

	beta, err := m.RootByType("Beta")
	if err != nil {
		t.Fatalf("RootByType(Beta): unexpected error %v", err)
	}
	if beta.SectionID != "B00" {
		t.Errorf("RootByType(Beta).SectionID = %q, want %q", beta.SectionID, "B00")
	}
}

// TestRootByTypeErrorNamesMissingAndAvailable: an unknown type yields an error
// naming both the available root types.
func TestRootByTypeErrorNamesMissingAndAvailable(t *testing.T) {
	m := twoRootModel(t)

	root, err := m.RootByType("Gamma")
	if err == nil {
		t.Fatalf("RootByType(Gamma) = %v, want error", root)
	}
	msg := err.Error()
	if !strings.Contains(msg, "Gamma") {
		t.Errorf("error %q does not name the missing type Gamma", msg)
	}
	if !strings.Contains(msg, "Alpha") {
		t.Errorf("error %q does not name available type Alpha", msg)
	}
	if !strings.Contains(msg, "Beta") {
		t.Errorf("error %q does not name available type Beta", msg)
	}
}

// --- SpecDocument.ToMarkdown (one-line export, SOM §21) ---------------------

// demoModelJSON is the single-root DemoDoc fixture from the markdown test's
// _sampleJson(), covering content, enum, @Form, a complex sub-section, and a
// list of complex items.
const demoModelJSON = `{
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
}`

func demoModel(t *testing.T) *som.SpecModel {
	t.Helper()
	m, err := som.SpecModelFromJSON([]byte(demoModelJSON))
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	return m
}

// populatedDemoDoc mirrors the Dart _populated() helper.
func populatedDemoDoc() *som.SpecDocument {
	doc := som.NewSpecDocument()
	doc.SetContent("D00/D00-OVR", "An overview paragraph.\nWith two lines.")
	doc.SetContent("D00/D00-ST", "final")
	doc.SetFormField("D00/D00-HDR", "author", "Ada Lovelace")
	doc.SetContent("D00/D00-MET/D00-MET-NOTE", "A note.")
	item := doc.AddListItem("D00/D00-ITM")
	doc.SetContent(item+"/D01-LBL", "First item")
	doc.SetContent(item+"/D01-BODY", "Column(\n  children: [\n    Text(\"hi\"),\n  ],\n) // not a fence: ``` still inside the body")
	item2 := doc.AddListItem("D00/D00-ITM")
	doc.SetContent(item2+"/D01-LBL", "Second item")
	return doc
}

// TestToMarkdownMatchesExplicitCodecForExplicitRootType: ToMarkdown with an
// explicit rootType equals the long-hand NewSpecDocumentMarkdown(...).ExportRoot.
func TestToMarkdownMatchesExplicitCodecForExplicitRootType(t *testing.T) {
	model := demoModel(t)
	doc := populatedDemoDoc()

	oneLiner, err := doc.ToMarkdown(model, "DemoDoc")
	if err != nil {
		t.Fatalf("ToMarkdown(DemoDoc): unexpected error %v", err)
	}
	root, err := model.RootByType("DemoDoc")
	if err != nil {
		t.Fatalf("RootByType(DemoDoc): %v", err)
	}
	explicit, err := som.NewSpecDocumentMarkdown(model, doc).ExportRoot(root)
	if err != nil {
		t.Fatalf("ExportRoot(DemoDoc): unexpected error %v", err)
	}
	if oneLiner != explicit {
		t.Errorf("ToMarkdown output differs from explicit codec output\n--- one-liner ---\n%s\n--- explicit ---\n%s", oneLiner, explicit)
	}
}

// TestToMarkdownDefaultsToSinglePopulatedRoot: with rootType "" the single
// populated root is chosen, matching the explicit-rootType output.
func TestToMarkdownDefaultsToSinglePopulatedRoot(t *testing.T) {
	model := demoModel(t)
	doc := populatedDemoDoc()

	def, err := doc.ToMarkdown(model, "")
	if err != nil {
		t.Fatalf("ToMarkdown(\"\"): unexpected error %v", err)
	}
	explicit, err := doc.ToMarkdown(model, "DemoDoc")
	if err != nil {
		t.Fatalf("ToMarkdown(DemoDoc): unexpected error %v", err)
	}
	if def != explicit {
		t.Errorf("default ToMarkdown differs from explicit-rootType output")
	}
}

// TestToMarkdownErrorsWhenNoRootPopulated: an empty document has no populated
// root, so the default errors.
func TestToMarkdownErrorsWhenNoRootPopulated(t *testing.T) {
	model := demoModel(t)

	out, err := som.NewSpecDocument().ToMarkdown(model, "")
	if err == nil {
		t.Fatalf("ToMarkdown on empty doc = %q, want error", out)
	}
	if !strings.Contains(err.Error(), "no populated root") {
		t.Errorf("error %q does not mention 'no populated root'", err.Error())
	}
}

// TestToMarkdownErrorsNamingCandidatesWhenMultiplePopulated: two populated
// roots make the default ambiguous, and the error names both candidates.
func TestToMarkdownErrorsNamingCandidatesWhenMultiplePopulated(t *testing.T) {
	const twoPopulatedModelJSON = `{
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
    }`
	model, err := som.SpecModelFromJSON([]byte(twoPopulatedModelJSON))
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	doc := som.NewSpecDocument()
	doc.SetContent("A00/A00-OVR", "a")
	doc.SetContent("B00/B00-OVR", "b")

	out, err := doc.ToMarkdown(model, "")
	if err == nil {
		t.Fatalf("ToMarkdown with two populated roots = %q, want error", out)
	}
	msg := err.Error()
	if !strings.Contains(msg, "Alpha") {
		t.Errorf("error %q does not name candidate Alpha", msg)
	}
	if !strings.Contains(msg, "Beta") {
		t.Errorf("error %q does not name candidate Beta", msg)
	}
}
