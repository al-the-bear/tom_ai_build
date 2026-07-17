// YRD6 — title/id role form fields, a port of the Dart reference tests in
// `tom_som_dart_runtime/test/spec_document_markdown_test.dart` /
// `spec_document_yaml_test.dart` ("YRD6 — title/id role form fields" groups).
//
// Role fields are pure views onto the YRD3 headline / stored-item-id stores.
// Their values emit exactly once — as the item heading text / id comment (md)
// and the item key / `headline` key (yaml) — never as form lines/entries; a
// duplicate is rejected (md) or a format error (yaml), both ways.
package tests

import (
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

const cardsModelJSON = `{
  "roots": [{"type": "CardDoc", "title": "Card Doc", "sectionId": "C00"}],
  "classes": {
    "CardDoc": {
      "name": "CardDoc",
      "sectionId": "C00",
      "annotations": [
        {"name": "Document", "arguments": {"title": "Card Doc"}},
        {"name": "SectionId", "arguments": {"id": "C00"}}
      ],
      "fields": [
        {"name": "cards", "kind": "list", "sectionId": "CARD-LST",
         "sectionIdPattern": "CARD-xxx", "elementType": "Card",
         "elementIsComplex": true}
      ]
    },
    "Card": {
      "name": "Card",
      "fields": [
        {"name": "content", "kind": "form",
         "formFields": [
           {"name": "cardId", "label": "Card ID", "type": "String",
            "role": "id"},
           {"name": "name", "label": "Name", "type": "String",
            "role": "title", "initial": "New Card"},
           {"name": "note", "label": "Note", "type": "String"}
         ]}
      ]
    }
  }
}`

func cardsModel(t *testing.T) *som.SpecModel {
	t.Helper()
	model, err := som.SpecModelFromJSON([]byte(cardsModelJSON))
	if err != nil {
		t.Fatalf("model: %v", err)
	}
	return model
}

func cardsTree(t *testing.T) *som.SomMetaTree {
	t.Helper()
	tree, err := som.BuildSomMetaTree(cardsModel(t), "")
	if err != nil {
		t.Fatalf("tree: %v", err)
	}
	return tree
}

func cardsPopulated(t *testing.T) *som.SpecDocument {
	t.Helper()
	d := som.NewSpecDocument()
	c1 := d.AddListItem("C00/CARD-LST")
	if err := d.SetItemSectionID(c1, "CARD-ALPHA"); err != nil {
		t.Fatalf("SetItemSectionID: %v", err)
	}
	d.SetHeadline(c1, "Alpha Card")
	d.SetFormField(c1+"/content", "note", "first card")
	return d
}

func cardsExport(t *testing.T, d *som.SpecDocument) string {
	t.Helper()
	model := cardsModel(t)
	md, err := som.NewSpecDocumentMarkdown(model, d).ExportRoot(model.Roots[0])
	if err != nil {
		t.Fatalf("ExportRoot: %v", err)
	}
	return md
}

func TestYrd6MarkdownRoleValuesEmitOnce(t *testing.T) {
	md := cardsExport(t, cardsPopulated(t))
	if !strings.Contains(md, "<!--[CARD-ALPHA]--> Alpha Card") {
		t.Errorf("missing heading with id + title:\n%s", md)
	}
	if !strings.Contains(md, "Note: first card") {
		t.Errorf("missing ordinary form line:\n%s", md)
	}
	for _, forbidden := range []string{"Card ID:", "cardId:", "Name:"} {
		if strings.Contains(md, forbidden) {
			t.Errorf("role value duplicated as form line %q:\n%s", forbidden, md)
		}
	}
}

func TestYrd6MarkdownRoleFormLineRejectedSiblingsKept(t *testing.T) {
	md := "# <!--[C00]--> Card Doc\n\n" +
		"## <!--[CARD-LST]--> Cards\n\n" +
		"### <!--[CARD-ALPHA]--> Alpha Card\n\n" +
		"cardId: CARD-DUP\n" +
		"  spilled continuation\n" +
		"Note: kept note\n"
	report := som.NewSpecDocumentMarkdown(cardsModel(t), som.NewSpecDocument()).Parse(md)
	found := false
	for _, r := range report.Rejections {
		if r.Reason == som.SpecMarkdownRejectRoleFieldFormLine {
			found = true
		}
	}
	if !found {
		t.Fatalf("expected roleFieldFormLine rejection, got: %s", mdRejStr(report))
	}
	// The rejected role line and its continuation never reach the stores.
	forms := report.Forms["C00/CARD-LST-1/content"]
	if !mdShallowEqual(forms, map[string]string{"note": "kept note"}) {
		t.Errorf("form store: got %v, want only the kept note", forms)
	}
	// The heading still restores the YRD3 views.
	ids := report.Lists["C00/CARD-LST"].Ids
	if ids["C00/CARD-LST-1"] != "CARD-ALPHA" {
		t.Errorf("stored ids: got %v, want CARD-ALPHA at item 1", ids)
	}
}

func TestYrd6MarkdownRoundTripRestoresRoleViews(t *testing.T) {
	md := cardsExport(t, cardsPopulated(t))
	target := som.NewSpecDocument()
	report := som.NewSpecDocumentMarkdown(cardsModel(t), target).Parse(md)
	if !report.IsClean() {
		t.Fatalf("unexpected rejections: %s", mdRejStr(report))
	}
	target.LoadJSON(&som.DocumentJson{
		Content:   report.Content,
		Forms:     report.Forms,
		Lists:     report.Lists,
		Headlines: report.Headlines,
	})
	if id := target.ItemSectionIDOr("C00/CARD-LST-1"); id != "CARD-ALPHA" {
		t.Errorf("item section id: got %q", id)
	}
	if h := target.HeadlineOr("C00/CARD-LST-1"); h != "Alpha Card" {
		t.Errorf("headline: got %q", h)
	}
	if v, _ := target.FormField("C00/CARD-LST-1/content", "note"); v != "first card" {
		t.Errorf("note: got %q", v)
	}
	if again := cardsExport(t, target); again != md {
		t.Errorf("round-trip not byte-stable:\n%s", byteDiff("md", again, md))
	}
}

func TestYrd6YamlRoleValuesEmitOnce(t *testing.T) {
	yaml := yamlEnc(t, cardsTree(t), cardsPopulated(t), "")
	for _, wanted := range []string{"CARD-ALPHA:", "headline:", "Alpha Card", "first card"} {
		if !strings.Contains(yaml, wanted) {
			t.Errorf("missing %q:\n%s", wanted, yaml)
		}
	}
	for _, forbidden := range []string{"cardId", "name:"} {
		if strings.Contains(yaml, forbidden) {
			t.Errorf("role value duplicated as form entry %q:\n%s", forbidden, yaml)
		}
	}
}

func TestYrd6YamlRoundTripRestoresRoleViews(t *testing.T) {
	tree := cardsTree(t)
	yaml := yamlEnc(t, tree, cardsPopulated(t), "")
	decoded := yamlDec(t, tree, yaml).Document
	if id := decoded.ItemSectionIDOr("C00/CARD-LST-1"); id != "CARD-ALPHA" {
		t.Errorf("item section id: got %q", id)
	}
	if h := decoded.HeadlineOr("C00/CARD-LST-1"); h != "Alpha Card" {
		t.Errorf("headline: got %q", h)
	}
	if v, _ := decoded.FormField("C00/CARD-LST-1/content", "note"); v != "first card" {
		t.Errorf("note: got %q", v)
	}
	if again := yamlEnc(t, tree, decoded, ""); again != yaml {
		t.Errorf("round-trip not byte-stable:\n%s", byteDiff("yaml", again, yaml))
	}
}

func TestYrd6YamlDecodeRejectsRoleFormEntry(t *testing.T) {
	yaml := "version: 2\n" +
		"document:\n" +
		"  C00 CardDoc:\n" +
		"    CARD-LST cards:\n" +
		"      CARD-ALPHA:\n" +
		"        headline: Alpha Card\n" +
		"        content:\n" +
		"          cardId: CARD-DUP\n" +
		"          note: kept\n"
	_, err := som.DecodeYaml(yaml, cardsTree(t))
	if !yamlThrowsFormat(err, "id-role field") {
		t.Fatalf("expected id-role format error, got: %v", err)
	}
}

func TestYrd6YamlEncodeRejectsRoleValueInStore(t *testing.T) {
	d := cardsPopulated(t)
	// Corrupt the store below the public API: LoadJSON bypasses the facade.
	state := d.ToJSON()
	state.Forms["C00/CARD-LST-1/content"]["cardId"] = "CARD-DUP"
	corrupt := som.NewSpecDocument()
	corrupt.LoadJSON(state)
	_, err := som.EncodeYaml(corrupt, cardsTree(t), "")
	if !yamlThrowsFormat(err, "id-role field") {
		t.Fatalf("expected id-role format error, got: %v", err)
	}
}
