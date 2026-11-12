// SOM §11.2 `units`: the generation units a section goes to. Kept exactly as
// `codeSpec` is — a sparse store by section path, the Markdown heading key
// `units="a,b"` after `codeSpec`, the YAML key `units` after `codeSpec`, the
// facade's Units / SetUnits, the snapshot's `units` map — and checked by the
// instance tier's phase 8. Mirrors the Dart reference's spec_units_test.dart
// (the captureState and path-normalizer cases have no counterpart here: this
// port has neither).
package tests

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// unitsCorpusModel is the shared corpus model: the demo root with the
// generation-unit register `DEMO/DLV-LST` (`Deliverable`, `DeliverableRoute`).
func unitsCorpusModel(t *testing.T) *som.SpecModel {
	t.Helper()
	raw, err := os.ReadFile(filepath.Join(corpusRel, "model.meta.json"))
	if err != nil {
		t.Fatalf("read model.meta.json: %v", err)
	}
	m, err := som.SpecModelFromJSON(raw)
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	return m
}

// unitsRegister is a register declaring `u_a` and `u_b`, both building
// something.
func unitsRegister() *som.SpecDocument {
	d := som.NewSpecDocument()
	a := d.AddListItem("DEMO/DLV-LST")
	d.SetFormField(a+"/content", "unitId", "u_a")
	d.SetFormField(a+"/content", "component", "ARCM-COMP-A")
	b := d.AddListItem("DEMO/DLV-LST")
	d.SetFormField(b+"/content", "unitId", "u_b")
	d.SetFormField(b+"/content", "deploymentTarget", "DEPTAR-DEPL-B")
	return d
}

func unitsSorted(in []string) []string {
	out := append([]string(nil), in...)
	sort.Strings(out)
	return out
}

func unitsJSON(t *testing.T, d *som.SpecDocument) string {
	t.Helper()
	b, err := json.Marshal(d.ToJSON())
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	return string(b)
}

func TestUnitsStore(t *testing.T) {
	d := som.NewSpecDocument()
	if _, ok := d.Units("DEMO/TTL"); ok {
		t.Fatal("fresh document carries units")
	}
	d.SetUnits("DEMO/TTL", "u_a,u_b")
	if got := d.UnitsOr("DEMO/TTL"); got != "u_a,u_b" {
		t.Fatalf("Units = %q", got)
	}
	if got := d.UnitsPaths(); !reflect.DeepEqual(got, []string{"DEMO/TTL"}) {
		t.Fatalf("UnitsPaths = %v", got)
	}
	if d.IsEmpty() || !d.HasValuesUnder("DEMO") {
		t.Fatal("units must count as a value")
	}
	d.SetUnits("DEMO/TTL", "")
	if _, ok := d.Units("DEMO/TTL"); ok {
		t.Fatal("empty value must clear")
	}
	if len(d.UnitsPaths()) != 0 || !d.IsEmpty() {
		t.Fatal("document must be empty again")
	}
}

func TestUnitsSnapshot(t *testing.T) {
	d := som.NewSpecDocument()
	d.SetCodeSpec("DEMO/TTL", "A")
	d.SetUnits("DEMO/TTL", "u_b")
	d.SetUnits("DEMO/SUM", "u_a")
	got := unitsJSON(t, d)
	want := `{"codeSpecs":{"DEMO/TTL":"A"},"units":{"DEMO/SUM":"u_a","DEMO/TTL":"u_b"}}`
	if got != want {
		t.Fatalf("snapshot = %s\nwant %s", got, want)
	}
	var back som.DocumentJson
	if err := json.Unmarshal([]byte(got), &back); err != nil {
		t.Fatal(err)
	}
	reloaded := som.NewSpecDocument()
	reloaded.LoadJSON(&back)
	if again := unitsJSON(t, reloaded); again != want {
		t.Fatalf("reloaded = %s", again)
	}
	if empty := unitsJSON(t, som.NewSpecDocument()); strings.Contains(empty, "units") {
		t.Fatalf("no units, no key: %s", empty)
	}
}

func TestUnitsRemoveValuesUnder(t *testing.T) {
	d := som.NewSpecDocument()
	d.SetUnits("DEMO/notes", "u_a")
	d.SetUnits("DEMO/notes/NOTE-BDY", "u_b")
	d.SetUnits("DEMO/TTL", "u_a")
	d.RemoveValuesUnder("DEMO/notes")
	if got := d.UnitsPaths(); !reflect.DeepEqual(got, []string{"DEMO/TTL"}) {
		t.Fatalf("UnitsPaths = %v", got)
	}
}

func TestUnitsMoveWithListItem(t *testing.T) {
	model := unitsCorpusModel(t)
	d := som.NewSpecDocument()
	first := d.AddListItem("DEMO/items")
	second := d.AddListItem("DEMO/items")
	d.SetContent(first+"/label", "one")
	d.SetContent(second+"/label", "two")
	d.SetUnits(second, "u_a")
	if _, err := d.MoveListItem(model, second, 0, ""); err != nil {
		t.Fatal(err)
	}
	if got := d.UnitsOr("DEMO/items-1"); got != "u_a" {
		t.Fatalf("items-1 units = %q", got)
	}
	if _, ok := d.Units("DEMO/items-2"); ok {
		t.Fatal("items-2 must carry no units")
	}
}

func TestUnitsFacade(t *testing.T) {
	d := som.NewSpecDocument()
	node := som.NewSomNode(d, "DEMO/TTL")
	if node.Units() != "" {
		t.Fatal("fresh node carries units")
	}
	node.SetUnits("u_a")
	if d.UnitsOr("DEMO/TTL") != "u_a" || node.Units() != "u_a" {
		t.Fatal("SetUnits did not store")
	}
	node.SetUnits("")
	if node.Units() != "" || len(d.UnitsPaths()) != 0 {
		t.Fatal("empty must clear")
	}
}

func TestUnitsMarkdownEmit(t *testing.T) {
	model := unitsCorpusModel(t)
	d := som.NewSpecDocument()
	d.SetContent("DEMO/TTL", "Hello")
	d.SetCodeSpec("DEMO/TTL", "DemoTitle")
	d.SetUnits("DEMO/TTL", "u_a,u_b")
	d.SetContent("DEMO/SUM", "Sum")
	d.SetUnits("DEMO/SUM", "u_a")
	md, err := d.ToMarkdown(model, "")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Document Title\n",
		"## <!--[SUM] units=\"u_a\"--> Summary\n",
	} {
		if !strings.Contains(md, want) {
			t.Fatalf("markdown lacks %q:\n%s", want, md)
		}
	}
}

func TestUnitsMarkdownParse(t *testing.T) {
	model := unitsCorpusModel(t)
	md := "# <!--[DEMO] units=u_root--> Demo Document\n\n" +
		"## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Title\n\n" +
		"Hello\n\n" +
		"## <!--[SUM] units='u_c'--> Summary\n\n" +
		"Sum\n\n" +
		"## <!--[CNT] codeSpec=\"units=no\"--> Count\n\n" +
		"3\n"
	result := som.NewSpecDocumentMarkdown(model, som.NewSpecDocument()).Parse(md)
	if len(result.Rejections) != 0 {
		t.Fatalf("rejections: %v", result.Rejections)
	}
	want := map[string]string{
		"DEMO":     "u_root",
		"DEMO/TTL": "u_a,u_b",
		"DEMO/SUM": "u_c",
	}
	if !reflect.DeepEqual(result.Units, want) {
		t.Fatalf("Units = %v", result.Units)
	}
	if result.CodeSpecs["DEMO/TTL"] != "DemoTitle" {
		t.Fatalf("TTL codeSpec = %q", result.CodeSpecs["DEMO/TTL"])
	}
	// A `units=` inside a quoted codeSpec value is not the key.
	if result.CodeSpecs["DEMO/CNT"] != "units=no" {
		t.Fatalf("CNT codeSpec = %q", result.CodeSpecs["DEMO/CNT"])
	}
}

func TestUnitsMarkdownRoundTrip(t *testing.T) {
	model := unitsCorpusModel(t)
	d := unitsRegister()
	d.SetContent("DEMO/TTL", "Hello")
	d.SetCodeSpec("DEMO/TTL", "DemoTitle")
	d.SetUnits("DEMO/TTL", "u_a")
	d.SetContent("DEMO/notes/NOTE-BDY", "Body")
	d.SetUnits("DEMO/notes", "u_a,u_b")
	md, err := d.ToMarkdown(model, "")
	if err != nil {
		t.Fatal(err)
	}
	imp, err := som.SpecDocumentFromMarkdown(md, model)
	if err != nil {
		t.Fatal(err)
	}
	back := imp.Document
	if back.UnitsOr("DEMO/TTL") != "u_a" || back.UnitsOr("DEMO/notes") != "u_a,u_b" {
		t.Fatalf("units lost: %v", back.ToJSON().Units)
	}
	again, err := back.ToMarkdown(model, "")
	if err != nil {
		t.Fatal(err)
	}
	if again != md {
		t.Fatalf("not byte-stable:\n%s\n---\n%s", again, md)
	}
}

func unitsTree(t *testing.T, model *som.SpecModel) *som.SomMetaTree {
	t.Helper()
	tree, err := som.BuildSomMetaTree(model, "")
	if err != nil {
		t.Fatal(err)
	}
	return tree
}

func TestUnitsYamlScalarPromotion(t *testing.T) {
	model := unitsCorpusModel(t)
	tree := unitsTree(t, model)
	d := som.NewSpecDocument()
	d.SetContent("DEMO/TTL", "Hello")
	d.SetHeadline("DEMO/TTL", "Title")
	d.SetCodeSpec("DEMO/TTL", "DemoTitle")
	d.SetUnits("DEMO/TTL", "u_a")
	d.SetContent("DEMO/CNT", "3")
	d.SetUnits("DEMO/CNT", "u_b")
	d.SetContent("DEMO/notes/NOTE-BDY", "Body")
	d.SetUnits("DEMO/notes", "u_a,u_b")
	yaml, err := som.EncodeYaml(d, tree, "1.0")
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"    TTL title:\n" +
			"      headline: |2-\n        Title\n" +
			"      codeSpec: |2-\n        DemoTitle\n" +
			"      units: |2-\n        u_a\n" +
			"      content: |2-\n        Hello\n",
		// A non-text scalar keeps its plain content inside the mapping.
		"    CNT count:\n      units: |2-\n        u_b\n      content: 3\n",
		"    NOTE notes:\n      units: |2-\n        u_a,u_b\n",
	} {
		if !strings.Contains(yaml, want) {
			t.Fatalf("yaml lacks %q:\n%s", want, yaml)
		}
	}
	back, err := som.FromYaml(yaml, tree)
	if err != nil {
		t.Fatal(err)
	}
	if unitsJSON(t, back) != unitsJSON(t, d) {
		t.Fatalf("round trip differs:\n%s\n%s", unitsJSON(t, back), unitsJSON(t, d))
	}
	again, err := som.EncodeYaml(back, tree, "1.0")
	if err != nil {
		t.Fatal(err)
	}
	if again != yaml {
		t.Fatal("re-encode not byte-stable")
	}
}

func TestUnitsYamlFormListItemRoundTrip(t *testing.T) {
	model := unitsCorpusModel(t)
	tree := unitsTree(t, model)
	d := unitsRegister()
	d.SetFormField("DEMO/DET", "owner", "Bob")
	d.SetUnits("DEMO/DET", "u_a")
	d.SetUnits("DEMO/DLV-LST", "u_b")
	d.SetUnits("DEMO/DLV-LST-1", "u_a")
	tag := d.AddListItem("DEMO/META/tags")
	d.SetContent(tag, "on")
	d.SetUnits(tag, "u_b")
	yaml, err := som.EncodeYaml(d, tree, "1.0")
	if err != nil {
		t.Fatal(err)
	}
	back, err := som.FromYaml(yaml, tree)
	if err != nil {
		t.Fatal(err)
	}
	if unitsJSON(t, back) != unitsJSON(t, d) {
		t.Fatalf("round trip differs:\n%s\n%s", unitsJSON(t, back), unitsJSON(t, d))
	}
	again, err := som.EncodeYaml(back, tree, "1.0")
	if err != nil {
		t.Fatal(err)
	}
	if again != yaml {
		t.Fatal("re-encode not byte-stable")
	}
}

const unitsClashModelJSON = `{
  "roots": [{"type": "R", "title": "R", "sectionId": "R"}],
  "classes": {
    "R": {
      "name": "R",
      "sectionId": "R",
      "fields": [
        {"name": "units", "kind": "content"},
        {"name": "shape", "kind": "form", "sectionId": "SHP",
         "formFields": [{"name": "units", "label": "Units", "type": "String"}]}
      ]
    }
  }
}`

func TestUnitsYamlCollisionGuards(t *testing.T) {
	clash, err := som.SpecModelFromJSON([]byte(unitsClashModelJSON))
	if err != nil {
		t.Fatal(err)
	}
	tree := unitsTree(t, clash)
	expectFormatErr := func(d *som.SpecDocument, fragment string) {
		t.Helper()
		_, err := som.EncodeYaml(d, tree, "1.0")
		var fe *som.SpecYamlFormatException
		if !errors.As(err, &fe) || !strings.Contains(fe.Message, fragment) {
			t.Fatalf("want a format error containing %q, got %v", fragment, err)
		}
	}
	child := som.NewSpecDocument()
	child.SetUnits("R", "u_a")
	expectFormatErr(child, "also serializes as key `units`")
	form := som.NewSpecDocument()
	form.SetFormField("R/SHP", "units", "3")
	form.SetUnits("R/SHP", "u_a")
	expectFormatErr(form, "field literally named `units`")
}

func TestUnitsYamlListItemKeyedUnits(t *testing.T) {
	tree := unitsTree(t, unitsCorpusModel(t))
	d := som.NewSpecDocument()
	if _, err := d.AddListItemWithSectionID("DEMO/DLV-LST", "units"); err != nil {
		t.Skipf("the store refuses the id itself: %v", err)
	}
	_, err := som.EncodeYaml(d, tree, "1.0")
	var fe *som.SpecYamlFormatException
	if !errors.As(err, &fe) {
		t.Fatalf("want a SpecYamlFormatException, got %v", err)
	}
}

func TestUnitsApplyMarkdownResult(t *testing.T) {
	model := unitsCorpusModel(t)
	d := som.NewSpecDocument()
	d.SetUnits("DEMO/TTL", "stale")
	d.SetUnits("DEMO/SUM", "stale")
	d.SetUnits("OTHER/kept", "kept")
	md := "# <!--[DEMO]--> Demo Document\n\n" +
		"## <!--[TTL] units=\"u_a\"--> Document Title\n\nHello\n"
	result := som.NewSpecDocumentMarkdown(model, som.NewSpecDocument()).Parse(md)
	if err := d.ApplyMarkdownResult(result, false); err != nil {
		t.Fatal(err)
	}
	want := map[string]string{"DEMO/TTL": "u_a", "OTHER/kept": "kept"}
	if got := d.ToJSON().Units; !reflect.DeepEqual(got, want) {
		t.Fatalf("units = %v", got)
	}
}

func TestUnitsAssembly(t *testing.T) {
	a := som.NewSpecDocument()
	a.SetUnits("DEMO/TTL", "u_a")
	b := som.NewSpecDocument()
	b.SetUnits("DEMO/SUM", "u_b")
	ok := som.AssembleSpecDocuments([]som.SpecAssemblyFragment{{Name: "a", Document: a}, {Name: "b", Document: b}})
	if !ok.Ok() || ok.Document.UnitsOr("DEMO/SUM") != "u_b" {
		t.Fatalf("assembly: %v", ok.Overlaps)
	}
	c := som.NewSpecDocument()
	c.SetUnits("DEMO/TTL", "u_b")
	clash := som.AssembleSpecDocuments([]som.SpecAssemblyFragment{{Name: "a", Document: a}, {Name: "c", Document: c}})
	if clash.Ok() || len(clash.Overlaps) != 1 ||
		clash.Overlaps[0].Store != "units" || clash.Overlaps[0].Path != "DEMO/TTL" {
		t.Fatalf("overlaps = %v", clash.Overlaps)
	}
}

func TestUnitsReviewMergeCarriesAddedItem(t *testing.T) {
	model := unitsCorpusModel(t)
	base := som.NewSpecDocument()
	first := base.AddListItem("DEMO/items")
	base.SetContent(first+"/label", "one")
	cp := som.NewSpecDocument()
	cp.LoadJSON(base.ToJSON())
	added := cp.AddListItem("DEMO/items")
	cp.SetContent(added+"/label", "two")
	cp.SetUnits(added, "u_a")
	member := som.SpecReviewMember{MemberID: "alice", DisplayName: "Alice"}
	result, err := som.MergeReviews(model, base,
		[]som.SpecReviewedCopy[*som.SpecDocument]{{SpecReviewMember: member, Document: cp}},
		som.SpecReviewMergeOptions{Team: []som.SpecReviewMember{member}, Date: "2026-11-12", Author: "alice"})
	if err != nil {
		t.Fatal(err)
	}
	items := result.Merged.ListItems("DEMO/items")
	if len(items) != 2 {
		t.Fatalf("items = %v", items)
	}
	if got := result.Merged.UnitsOr(items[1]); got != "u_a" {
		t.Fatalf("added item units = %q", got)
	}
}

type unitsFinding struct{ path, code, message string }

func unitsCheck(model *som.SpecModel, d *som.SpecDocument) []unitsFinding {
	out := []unitsFinding{}
	for _, e := range som.ValidateDocument(model, d) {
		out = append(out, unitsFinding{e.Path, e.Code, e.Message})
	}
	return out
}

func unitsExpect(t *testing.T, got, want []unitsFinding) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("findings:\n got %v\nwant %v", got, want)
	}
}

func TestUnitsValidationClean(t *testing.T) {
	model := unitsCorpusModel(t)
	d := unitsRegister()
	d.SetUnits("DEMO/TTL", "u_a")
	d.SetUnits("DEMO/REG", "u_a,u_b")
	unitsExpect(t, unitsCheck(model, d), []unitsFinding{})
}

func TestUnitsValidationUnknownUnit(t *testing.T) {
	model := unitsCorpusModel(t)
	d := unitsRegister()
	d.SetUnits("DEMO/TTL", "u_x, u_a ,u_y")
	unitsExpect(t, unitsCheck(model, d), []unitsFinding{
		{"DEMO/TTL", "unknownUnit", `units names "u_x", which no generation unit declares`},
		{"DEMO/TTL", "unknownUnit", `units names "u_y", which no generation unit declares`},
	})
}

func TestUnitsValidationUnrouted(t *testing.T) {
	model := unitsCorpusModel(t)
	d := unitsRegister()
	d.SetUnits("DEMO/META", "u_a")
	d.SetUnits("DEMO/META/tags", "u_a")
	d.SetUnits("DEMO/control", "u_a")
	d.SetUnits("DEMO/DLV-LST-1", "u_a")
	// Routed: a field of a routed class, a list of a routed element.
	d.SetUnits("DEMO/PRI", "u_a")
	d.SetUnits("DEMO/CARD-LST", "u_a")
	const message = "units is set on a section that routes nothing to CodeSpecs"
	unitsExpect(t, unitsCheck(model, d), []unitsFinding{
		{"DEMO/DLV-LST-1", "unitsUnrouted", message},
		{"DEMO/META", "unitsUnrouted", message},
		{"DEMO/META/tags", "unitsUnrouted", message},
		{"DEMO/control", "unitsUnrouted", message},
	})
}

func TestUnitsValidationRegister(t *testing.T) {
	model := unitsCorpusModel(t)
	d := unitsRegister()
	dup := d.AddListItem("DEMO/DLV-LST")
	d.SetFormField(dup+"/content", "unitId", "u_a")
	d.SetFormField(dup+"/content", "kind", "server")
	// An item with no value at all is absence, not a finding.
	d.AddListItem("DEMO/DLV-LST")
	for _, area := range []string{"CE-DB", "ce-db", "CE-", "CE-D1"} {
		route := d.AddListItem("DEMO/DLV-LST-1/DLR-LST")
		d.SetFormField(route+"/content", "area", area)
		d.SetFormField(route+"/content", "mapping", "dart-tom")
	}
	unitsExpect(t, unitsCheck(model, d), []unitsFinding{
		{"DEMO/DLV-LST-1/DLR-LST-2", "unitAreaMalformed", `mapping area "ce-db" is not an area code (CE-…)`},
		{"DEMO/DLV-LST-1/DLR-LST-3", "unitAreaMalformed", `mapping area "CE-" is not an area code (CE-…)`},
		{"DEMO/DLV-LST-1/DLR-LST-4", "unitAreaMalformed", `mapping area "CE-D1" is not an area code (CE-…)`},
		{"DEMO/DLV-LST-3", "duplicateUnitId", `generation unit "u_a" is declared twice`},
		{"DEMO/DLV-LST-3", "unitBuildsNothing", `generation unit "u_a" builds neither a deploymentTarget nor a component`},
	})
}

func TestUnitsValidationPhaseOrder(t *testing.T) {
	model := unitsCorpusModel(t)
	d := unitsRegister()
	d.SetUnits("DEMO/TTL", "u_x")
	d.SetContent("DEMO/SUM", "> ⬆️ **C-1** a\n\n> ⬆️ **C-1** b")
	var codes []string
	for _, e := range som.ValidateDocument(model, d) {
		codes = append(codes, e.Code)
	}
	if !reflect.DeepEqual(codes, []string{"unknownUnit", "duplicateAnnotationId"}) {
		t.Fatalf("codes = %v", codes)
	}
}

func TestUnitsExtractRecordsRoundTrip(t *testing.T) {
	// The extract writer emits `units` only when non-empty and the reader reads
	// it back (absent → empty).
	x := &som.CodeSpecsExtract{
		Area:         &som.CodeSpecsArea{Code: "CE-FM", CanonicalID: "Form", Part: "form"},
		DocumentRoot: "DEMO",
		Entries: []som.CodeSpecsExtractEntry{
			{AreaCode: "CE-FM", SectionID: "TTL", Path: "DEMO/TTL", ClassName: "Demo",
				FieldName: "title", RoutedBy: "CodeSpecPart.form", RoutedAt: "Demo",
				Units: []string{"u_a", "u_b"}, Value: "Hello"},
			{AreaCode: "CE-FM", SectionID: "SUM", Path: "DEMO/SUM", ClassName: "Demo",
				FieldName: "summary", RoutedBy: "CodeSpecPart.form", RoutedAt: "Demo",
				Units: []string{}, Value: "Sum"},
		},
	}
	yaml := x.ToYaml()
	if !strings.Contains(yaml, "      routingNote: null\n      units: [\"u_a\", \"u_b\"]\n      value: \"Hello\"\n") {
		t.Fatalf("yaml lacks the units line:\n%s", yaml)
	}
	if strings.Count(yaml, "units:") != 1 {
		t.Fatalf("empty units must not be written:\n%s", yaml)
	}
	if md := x.ToMarkdown(); !strings.Contains(md, "- routed by: `CodeSpecPart.form` declared on `Demo`\n- units: `u_a`, `u_b`\n") {
		t.Fatalf("markdown lacks the units line:\n%s", md)
	}
	back, err := som.ParseCodeSpecsExtractYaml(yaml, "")
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(back.Entries[0].Units, []string{"u_a", "u_b"}) ||
		len(back.Entries[1].Units) != 0 {
		t.Fatalf("units read back = %v / %v", back.Entries[0].Units, back.Entries[1].Units)
	}
}
