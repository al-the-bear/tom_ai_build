// The rendition's generated parts (spec_document_markdown_generated.go, SOM
// §11.12) through the codec's surface, over the real model: the requirement
// views written in `derived` blocks at the start of their sections, the
// headings they force, the option that turns them off, the parser removing a
// block (and only a closed `derived` block at its place), and the missing
// value an empty generated place is without its block.
package tests

import (
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

const generatedTraceOpen = "::: {.derived label=\"Generated from each requirement's traceability; " +
	"edit it there\"}"

func generatedFixture(t *testing.T) (*som.SpecModel, *som.SpecDocument, string) {
	t.Helper()
	model, doc, cc := renditionFixture(t, "generatedTrace")
	md, _ := cc["expect"].(map[string]any)["markdown"].(string)
	return model, doc, md
}

func TestGeneratedTablesOnTheRequirementsSpecification(t *testing.T) {
	model, doc, golden := generatedFixture(t)
	md := renderRoot(t, model, doc, "RSP", nil)
	if md != golden {
		t.Fatal("the rendition differs from the golden one")
	}
	for _, want := range []string{
		generatedTraceOpen + "\n| Requirement | Use cases | Screens | Data entities | Tests |\n| --- | --- | --- | --- | --- |\n",
		"| Requirement | Covered | By |",
		"| Requirement | Dependency | Related requirement |",
	} {
		if !strings.Contains(md, want) {
			t.Errorf("no %q", want)
		}
	}
	if strings.Contains(md, "\x00") {
		t.Error("a placeholder is left in the rendition")
	}
	// The block opens its section, after the heading (and its marker).
	lines := strings.Split(md, "\n")
	for i, l := range lines {
		if l == generatedTraceOpen {
			if !strings.Contains(lines[i-2], "<!--[RSP-TRAC]-->") {
				t.Errorf("the traceability block follows %q", lines[i-2])
			}
		}
	}
	assertRoundTrip(t, "with generated parts", md, model, doc)
}

func TestGeneratedPartsOff(t *testing.T) {
	model, doc, _ := generatedFixture(t)
	plain := renderRoot(t, model, doc, "RSP", func(c *som.SpecDocumentMarkdown) { c.GeneratedParts = false })
	if strings.Contains(plain, "{.derived") {
		t.Error("GeneratedParts false still writes a block")
	}
	if strings.Contains(plain, "<!--[RSP-TRAC]-->") {
		t.Error("an empty generated place is written without its block")
	}
	assertRoundTrip(t, "without generated parts", plain, model, doc)
}

func TestGeneratedBlockEditedIsDiscarded(t *testing.T) {
	model, doc, _ := generatedFixture(t)
	md := renderRoot(t, model, doc, "RSP", nil)
	edited := strings.Replace(md, "| Requirement | Covered | By |", "| Requirement | Covered |", 1)
	assertRoundTrip(t, "edited block", edited, model, doc)
}

func TestGeneratedBlockRemovedIsAMissingValue(t *testing.T) {
	model, doc, _ := generatedFixture(t)
	md := renderRoot(t, model, doc, "RSP", nil)
	lines := strings.Split(md, "\n")
	i := 0
	for lines[i] != generatedTraceOpen {
		i++
	}
	j := i
	for lines[j] != ":::" {
		j++
	}
	given := strings.Join(append(append([]string{}, lines[:i]...), lines[j+2:]...), "\n")
	parsed, err := som.SpecDocumentFromMarkdown(given, model)
	if err != nil {
		t.Fatal(err)
	}
	r := parsed.Rejections()
	if len(r) != 1 || r[0].Reason != som.SpecMarkdownRejectMissingValue || r[0].Anchor != "RSP/RSP-TRAC" {
		t.Errorf("rejections %v", r)
	}
}

func TestGeneratedOnlyAClosedDerivedBlockIsRemoved(t *testing.T) {
	model, doc, _ := generatedFixture(t)
	md := renderRoot(t, model, doc, "RSP", nil)
	// Indented by four spaces the fence opens no block: the lines are the
	// value's, and the traceability matrix holds them.
	indented := strings.Replace(md, generatedTraceOpen, "    "+generatedTraceOpen, 1)
	parsed, err := som.SpecDocumentFromMarkdown(indented, model)
	if err != nil {
		t.Fatal(err)
	}
	if v, ok := parsed.Document.Content("RSP/RSP-TRAC"); !ok || !strings.Contains(v, "Generated from") {
		t.Errorf("the indented lines are not the value: %q", v)
	}
	// A block of another kind is the value's too.
	other := strings.Replace(md, generatedTraceOpen, "::: {.derivedX}", 1)
	parsed, err = som.SpecDocumentFromMarkdown(other, model)
	if err != nil {
		t.Fatal(err)
	}
	if v, ok := parsed.Document.Content("RSP/RSP-TRAC"); !ok || !strings.Contains(v, "{.derivedX}") {
		t.Errorf("a block of another kind is not the value: %q", v)
	}
}

func TestGeneratedStripKindsTurnThePartsOff(t *testing.T) {
	model, doc, _ := generatedFixture(t)
	o, err := som.SpecStripOptionsFromNames([]string{"derived"}, nil, nil, false, false)
	if err != nil {
		t.Fatal(err)
	}
	r := som.SpecDocumentStrip{}.Strip(doc, o, som.SpecDocumentStripOptions{Model: model, RootType: "D04RequirementsSpecification"})
	if r.Readable == "" {
		t.Fatalf("no readable rendition: %v", r.Findings)
	}
	if strings.Contains(r.Readable, "{.derived") {
		t.Error("the readable rendition has a generated block")
	}
}
