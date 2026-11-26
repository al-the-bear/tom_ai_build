// The rendition's navigation (spec_document_markdown_linked.go) through the
// codec's surface: qualified anchors (SOM §11.2), the `linked` marker and its
// entries in their order (SOM §11.11), the placeholder resolution, the option
// that turns the marker off, the strip kinds that do, and the parser removing
// the marker.
//
// The shared corpus (`link_rendition_cases.json`) pins whole renditions; these
// tests hold the module's behaviour over the corpus's `links.meta.json`.
package tests

import (
	"encoding/json"
	"regexp"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// renditionFixture is the corpus case whose intent names token, with its
// document and the model it runs against (the links fixture, or the real
// model for a case marked `som`).
func renditionFixture(t *testing.T, token string) (*som.SpecModel, *som.SpecDocument, setCase) {
	t.Helper()
	table := readSetTable(t, "link_rendition_cases.json")
	for _, cc := range setCases(table, "cases") {
		for _, i := range cc.intent() {
			if i != token {
				continue
			}
			models := &setModels{t: t}
			model := models.modelOf(modelFromCorpus(t, "links.meta.json"), cc)
			return model, stateDocument(t, cc["state"]), cc
		}
	}
	t.Fatalf("no rendition case with intent %s", token)
	return nil, nil, nil
}

func renderRoot(t *testing.T, model *som.SpecModel, doc *som.SpecDocument, rootID string, configure func(*som.SpecDocumentMarkdown)) string {
	t.Helper()
	var root *som.SpecRoot
	for _, r := range model.Roots {
		if r.SectionID == rootID {
			root = r
		}
	}
	if root == nil {
		t.Fatalf("no root %s", rootID)
	}
	codec := som.NewSpecDocumentMarkdown(model, doc)
	codec.FileStem = "links"
	if configure != nil {
		configure(codec)
	}
	md, err := codec.ExportRoot(root)
	if err != nil {
		t.Fatalf("export: %v", err)
	}
	return md
}

// markerAfter is the marker paragraph written right after the heading
// carrying anchor, "" when none follows it.
func markerAfter(md, anchor string) string {
	lines := strings.Split(md, "\n")
	for i, l := range lines {
		if strings.Contains(l, `<a id="`+anchor+`"></a>`) && strings.HasPrefix(l, "#") {
			if i+2 < len(lines) && strings.HasSuffix(lines[i+2], "{.linked}") {
				return lines[i+2]
			}
			return ""
		}
	}
	return ""
}

func assertRoundTrip(t *testing.T, label, md string, model *som.SpecModel, doc *som.SpecDocument) {
	t.Helper()
	parsed, err := som.SpecDocumentFromMarkdown(md, model)
	if err != nil {
		t.Fatalf("%s: parse: %v", label, err)
	}
	if r := parsed.Rejections(); len(r) != 0 {
		t.Errorf("%s: rejections %v", label, r)
	}
	got, _ := json.Marshal(parsed.Document.ToJSON())
	want, _ := json.Marshal(doc.ToJSON())
	if string(got) != string(want) {
		t.Errorf("%s: the document differs\n got %s\nwant %s", label, got, want)
	}
}

func TestLinkedMarkerEntriesOnTheBlueprint(t *testing.T) {
	model, doc, cc := renditionFixture(t, "copyOf")
	md := renderRoot(t, model, doc, "BLU", nil)
	expect, _ := cc["expect"].(map[string]any)
	if md != expect["markdown"] {
		t.Fatalf("the rendition differs from the golden one")
	}
	if got := markerAfter(md, "CSUM/CRIT"); got != "[Copy of [CRIT](#CRIT), edit it there]{.linked}" {
		t.Errorf("copy marker %q", got)
	}
	if got := markerAfter(md, "REQ-EXPORT/LNK-ITEM-LST"); got != "[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}" {
		t.Errorf("extracted marker %q", got)
	}
	// An item's entries in the order of SOM §11.11: Also in, Summarised in,
	// Derived from.
	item := markerAfter(md, "REQ-EXPORT")
	also := strings.Index(item, "Also in [DET REQ-EXPORT](links.det.tomspecs.md#REQ-EXPORT), held there except REQ.owner")
	summarised := strings.Index(item, "; Summarised in [KEY-1](#KEY-1)")
	derived := strings.Index(item, "; Derived from ")
	if also != 1 || summarised < also || derived < summarised {
		t.Errorf("item marker %q", item)
	}
	if strings.HasPrefix(md, "[") || markerAfter(md, "BLU") != "" {
		t.Error("the root carries no marker")
	}
	// Qualified anchors below an item and in a copy.
	for _, a := range []string{`<a id="REQ-EXPORT/REQD"></a>`, `<a id="CSUM/CRIT"></a>`} {
		if !strings.Contains(md, a) {
			t.Errorf("anchor %s missing", a)
		}
	}
	assertRoundTrip(t, "with markers", md, model, doc)
}

func TestLinkedMarkersOff(t *testing.T) {
	model, doc, _ := renditionFixture(t, "copyOf")
	plain := renderRoot(t, model, doc, "BLU", func(c *som.SpecDocumentMarkdown) { c.LinkedMarkers = false })
	if strings.Contains(plain, "{.linked}") {
		t.Error("LinkedMarkers false still writes a marker")
	}
	if !strings.Contains(plain, `<a id="CSUM/CRIT"></a>`) {
		t.Error("the anchors go with the markers")
	}
	assertRoundTrip(t, "without markers", plain, model, doc)
	// A marker deleted by hand is restored on the next export.
	md := renderRoot(t, model, doc, "BLU", nil)
	parsed, err := som.SpecDocumentFromMarkdown(plain, model)
	if err != nil {
		t.Fatal(err)
	}
	if again := renderRoot(t, model, parsed.Document, "BLU", nil); again != md {
		t.Error("the markers are not restored after a rendition without them")
	}
}

func TestLinkedMarkerHandEditDiscarded(t *testing.T) {
	model, doc, _ := renditionFixture(t, "copyOf")
	md := renderRoot(t, model, doc, "BLU", nil)
	edited := strings.Replace(md, "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
		"[Copy of [X](#X), edit it there]{.linked}", 1)
	assertRoundTrip(t, "edited marker", edited, model, doc)
}

func TestLinkedMarkerTextAfterIsAValue(t *testing.T) {
	// A paragraph that is more than one `linked` span is the value's, not
	// the marker: it stays content (and the copy's form has no content, so it
	// is rejected rather than silently dropped).
	model, doc, _ := renditionFixture(t, "copyOf")
	md := renderRoot(t, model, doc, "BLU", nil)
	edited := strings.Replace(md, "[Copy of [CRIT](#CRIT), edit it there]{.linked}",
		"[Copy of [CRIT](#CRIT), edit it there]{.linked} and more", 1)
	parsed, err := som.SpecDocumentFromMarkdown(edited, model)
	if err != nil {
		t.Fatal(err)
	}
	got, _ := json.Marshal(parsed.Document.ToJSON())
	want, _ := json.Marshal(doc.ToJSON())
	if string(got) == string(want) && len(parsed.Rejections()) == 0 {
		t.Error("text beside the marker was dropped")
	}
}

func TestLinkedEmptyMarkerBeforeALinkedValue(t *testing.T) {
	model, doc, _ := renditionFixture(t, "emptyMarker")
	var rootID string
	for _, r := range model.Roots {
		if doc.HasValuesUnder(r.SectionID) && r.SectionID != "" {
			rootID = r.SectionID
			break
		}
	}
	md := renderRoot(t, model, doc, rootID, nil)
	if !strings.Contains(md, "[]{.linked}\n\n[To be chosen") {
		t.Errorf("no empty marker before the linked value:\n%s", md)
	}
	if strings.Contains(md, "\x00") {
		t.Error("a placeholder is left in the rendition")
	}
	assertRoundTrip(t, "empty marker", md, model, doc)
}

func TestLinkedSummaryRowIDCell(t *testing.T) {
	model, doc, cc := renditionFixture(t, "summaryRowLink")
	md, _ := cc["expect"].(map[string]any)["markdown"].(string)
	var rootID string
	for _, r := range model.Roots {
		if r.SectionID != "" && doc.HasValuesUnder(r.SectionID) {
			rootID = r.SectionID
			break
		}
	}
	got := renderRoot(t, model, doc, rootID, nil)
	if got != md {
		t.Fatal("the rendition differs from the golden one")
	}
	if !regexp.MustCompile(`\| <a id="TOP-BETA"></a>\[TOP-BETA\]\(#TOP-BETA\) \|`).MatchString(got) {
		t.Error("the summary row's Id cell is no link")
	}
	assertRoundTrip(t, "summary rows", got, model, doc)
}

func TestLinkedStripKindsTurnTheMarkerOff(t *testing.T) {
	model, doc, _ := renditionFixture(t, "copyOf")
	for _, names := range [][2][]string{
		{{"linked"}, nil},
		{nil, {"linked"}},
	} {
		o, err := som.SpecStripOptionsFromNames(names[0], names[1], nil, false, false)
		if err != nil {
			t.Fatal(err)
		}
		r := som.SpecDocumentStrip{}.Strip(doc, o, som.SpecDocumentStripOptions{Model: model, RootType: "Blueprint", FileStem: "links"})
		if r.Readable == "" {
			t.Fatalf("no readable rendition: %v", r.Findings)
		}
		if strings.Contains(r.Readable, "{.linked}") {
			t.Errorf("%v: the readable rendition has a marker", names)
		}
	}
	o, _ := som.SpecStripOptionsFromNames([]string{"provenance"}, nil, nil, false, false)
	r := som.SpecDocumentStrip{}.Strip(doc, o, som.SpecDocumentStripOptions{Model: model, RootType: "Blueprint", FileStem: "links"})
	if !strings.Contains(r.Readable, "{.linked}") {
		t.Error("dropping another kind turns the marker off")
	}
}
