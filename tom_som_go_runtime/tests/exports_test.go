package tests

// The surface the TypeScript runtime exports and this port had kept
// unexported: the YAML writer helpers, the review-pass scalar forms, the
// Markdown heading-comment readers, the CodeSpecs YAML string, the JSON
// constructors and SomMetaNodeDiff's position prefix. The expected values are
// the TypeScript runtime's output for the same inputs.

import (
	"math"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func TestWriteScalarAndHeader(t *testing.T) {
	var b strings.Builder
	som.WriteScalar(&b, 2, "key", "one")
	som.WriteScalar(&b, 2, "a b", "line1\nline2")
	som.WriteScalar(&b, 0, "k", "")
	som.WriteHeader(&b, "1.2.3")
	som.WriteHeader(&b, "")
	want := "  \"key\": |2-\n    one\n  \"a b\": |2-\n    line1\n    line2\n\"k\": |2-\n\n" +
		"# TomSpecs document (*.tomspecs.yaml). Hierarchical format v2.\nversion: 2\nmodelVersion: \"1.2.3\"\n" +
		"# TomSpecs document (*.tomspecs.yaml). Hierarchical format v2.\nversion: 2\n"
	if got := b.String(); got != want {
		t.Fatalf("WriteScalar/WriteHeader:\n got %q\nwant %q", got, want)
	}
}

func TestScalarHelpers(t *testing.T) {
	cases := []struct{ name, got, want string }{
		{"YamlKey", som.YamlKey("a b"), `"a b"`},
		{"ReviewScalar(true)", som.ReviewScalar(true), "true"},
		{"ReviewScalar(3)", som.ReviewScalar(3), "3"},
		{"ReviewScalar(2.5)", som.ReviewScalar(2.5), "2.5"},
		{"ReviewScalar(3.0)", som.ReviewScalar(3.0), "3.0"},
		{"CodeSpecsYamlString", som.CodeSpecsYamlString("a\"b\n"), `"a\"b\n"`},
		{"FormatYamlFloat(3)", som.FormatYamlFloat(3), "3.0"},
		{"FormatYamlFloat(-0)", som.FormatYamlFloat(math.Copysign(0, -1)), "-0.0"},
		{"FormatYamlFloat(0.1)", som.FormatYamlFloat(0.1), "0.1"},
		{"FormatYamlFloat(1e21)", som.FormatYamlFloat(1e21), "1e+21"},
		{"FormatYamlFloat(1e-7)", som.FormatYamlFloat(1e-7), "1e-7"},
		{"FormatYamlFloat(1e20)", som.FormatYamlFloat(1e20), "100000000000000000000.0"},
		{"FormatYamlFloat(NaN)", som.FormatYamlFloat(math.NaN()), ".nan"},
		{"FormatYamlFloat(+Inf)", som.FormatYamlFloat(math.Inf(1)), ".inf"},
		{"FormatYamlFloat(-Inf)", som.FormatYamlFloat(math.Inf(-1)), "-.inf"},
		{"CodeSpecOf", som.SpecDocumentMarkdownCodeSpecOf(`sectionId="X" codeSpec=" a,b "`), "a,b"},
		{"CodeSpecOf absent", som.SpecDocumentMarkdownCodeSpecOf(`sectionId="X"`), ""},
		{"UnitsOf", som.SpecDocumentMarkdownUnitsOf(`units='server,web'`), "server,web"},
	}
	for _, c := range cases {
		if c.got != c.want {
			t.Errorf("%s = %q, want %q", c.name, c.got, c.want)
		}
	}
}

func TestSpecQuestionDraftFromJSON(t *testing.T) {
	d, err := som.SpecQuestionDraftFromJSON([]byte(`{"id": "BQ-90", "topic": "Limit",
		"text": "Which limit?", "options": ["100 EUR", 150], "recommendation": "(a)",
		"assumption": "100", "starred": true, "recommended": "a"}`))
	if err != nil {
		t.Fatal(err)
	}
	if d.ID != "BQ-90" || d.Topic != "Limit" || d.Text != "Which limit?" ||
		d.Recommendation != "(a)" || d.Assumption != "100" || !d.Starred || d.Recommended != "a" {
		t.Errorf("draft fields: %+v", d)
	}
	if len(d.Options) != 2 || d.Options[0] != "100 EUR" || d.Options[1] != "150" {
		t.Errorf("options: %q", d.Options)
	}
	empty, err := som.SpecQuestionDraftFromJSON([]byte(`{"id": "Q-1", "recommended": null}`))
	if err != nil {
		t.Fatal(err)
	}
	if empty.Options == nil || len(empty.Options) != 0 || empty.Starred || empty.Recommended != "" {
		t.Errorf("defaults: %+v", empty)
	}
	if _, err := som.SpecQuestionDraftFromJSON([]byte(`["not", "an", "object"]`)); err == nil {
		t.Error("an array read as a draft")
	}
	if _, err := som.SpecQuestionDraftFromJSON([]byte(`{"id": 3}`)); err == nil {
		t.Error("a numeric id read as a draft")
	}
}

// The error messages are the TypeScript runtime's for the same rows.
func TestCodeSpecsFromJSON(t *testing.T) {
	s, err := som.CodeSpecsSliceFromJSON([]byte(`{"number": 2, "title": "T", "project": "shared", "cites": [1]}`))
	if err != nil || s.Number != 2 || s.Title != "T" || s.Project != "shared" || len(s.Cites) != 1 || s.Cites[0] != 1 {
		t.Errorf("slice: %+v, %v", s, err)
	}
	st, err := som.CodeSpecsStepFromJSON([]byte(`{"number": 3, "slice": 1, "title": "T", "placedBy": "p", "areaCodes": ["CE-FM"]}`))
	if err != nil || st.Number != 3 || st.Slice != 1 || st.PlacedBy != "p" || len(st.AreaCodes) != 1 {
		t.Errorf("step: %+v, %v", st, err)
	}
	a, err := som.CodeSpecsAreaFromJSON([]byte(`{"code": "CE-FM", "part": "form", "canonicalId": "Form"}`))
	if err != nil || a.Code != "CE-FM" || a.Part != "form" || !a.Active || a.Annotations == nil {
		t.Errorf("area: %+v, %v", a, err)
	}
	inactive, err := som.CodeSpecsAreaFromJSON([]byte(`{"code": "CE-X", "part": "x", "active": false}`))
	if err != nil || inactive.Active {
		t.Errorf("inactive area: %+v, %v", inactive, err)
	}
	ref, err := som.CodeSpecsFieldRefFromJSON([]byte(`{"className": "C", "member": "m", "formField": "f"}`))
	if err != nil || ref.Source() != "C.m.f" {
		t.Errorf("field ref: %+v, %v", ref, err)
	}
	arg, err := som.CodeSpecsRequiredArgumentFromJSON([]byte(`{"area": "CE-FM", "marker": "CsForm",
		"argument": "id", "className": "C", "member": "m",
		"resolvesTo": {"className": "R", "member": "r"},
		"when": {"className": "W", "member": "w", "equals": "yes"}}`))
	if err != nil || arg.Area != "CE-FM" || arg.Marker != "CsForm" || arg.Argument != "id" ||
		arg.Source() != "C.m" || arg.ResolvesTo == nil || arg.ResolvesTo.Source() != "R.r" ||
		arg.When == nil || arg.When.Source() != "W.w" || arg.WhenEquals != "yes" {
		t.Errorf("required argument: %+v, %v", arg, err)
	}
	carrier, err := som.CodeSpecsCarrierFromJSON([]byte(`{"className": "C", "member": "m", "introducedBy": "SBP"}`))
	if err != nil || carrier.Source() != "C.m" || carrier.IntroducedBy != "SBP" {
		t.Errorf("carrier: %+v, %v", carrier, err)
	}

	refusals := []struct {
		name string
		read func() error
		want string
	}{
		{"slice", func() error { _, e := som.CodeSpecsSliceFromJSON([]byte(`{"title": "Shared types"}`)); return e },
			`CodeSpecs area catalogue: title "Shared types" is missing a numeric "number" (got absent)`},
		{"step", func() error { _, e := som.CodeSpecsStepFromJSON([]byte(`{"title": "T", "number": 1}`)); return e },
			`CodeSpecs area catalogue: title "T" is missing a numeric "slice" (got absent)`},
		{"area", func() error { _, e := som.CodeSpecsAreaFromJSON([]byte(`{"canonicalId": "Form"}`)); return e },
			`CodeSpecs area catalogue: canonicalId "Form" is missing a non-empty "code" (got absent)`},
		{"field ref", func() error { _, e := som.CodeSpecsFieldRefFromJSON([]byte(`{"className": "X"}`)); return e },
			`CodeSpecs area catalogue: className "X" is missing a non-empty "member" (got absent)`},
		{"required argument", func() error {
			_, e := som.CodeSpecsRequiredArgumentFromJSON([]byte(`{"area": "CE-FM", "marker": "CsForm",
				"argument": "id", "className": "C", "member": "m", "when": {"className": "W", "member": "w"}}`))
			return e
		}, `CodeSpecs area catalogue: marker "CsForm" is missing a non-empty "equals" (got absent)`},
	}
	for _, r := range refusals {
		err := r.read()
		if err == nil || err.Error() != r.want {
			t.Errorf("%s: got %v, want %q", r.name, err, r.want)
		}
	}
	if _, err := som.CodeSpecsSliceFromJSON([]byte(`[1]`)); err == nil {
		t.Error("an array read as a slice")
	}
	if _, err := som.CodeSpecsCarrierFromJSON([]byte(`"x"`)); err == nil {
		t.Error("a string read as a carrier")
	}
}

func TestSomMetaNodeDiffAt(t *testing.T) {
	a := &som.SomMetaNode{ClassName: "A"}
	b := &som.SomMetaNode{ClassName: "B"}
	if d := som.SomMetaNodeDiff(a, a); d != "" {
		t.Errorf("identical nodes differ: %s", d)
	}
	if d := som.SomMetaNodeDiff(a, b); !strings.HasPrefix(d, "<root>: className differs") {
		t.Errorf("default prefix: %s", d)
	}
	if d := som.SomMetaNodeDiff(a, b, "<root>/orders"); !strings.HasPrefix(d, "<root>/orders: className differs") {
		t.Errorf("given prefix: %s", d)
	}
	pa := &som.SomMetaNode{ClassName: "P", Children: []*som.SomMetaNode{{ClassName: "A", MemberName: "lines"}}}
	pb := &som.SomMetaNode{ClassName: "P", Children: []*som.SomMetaNode{{ClassName: "B", MemberName: "lines"}}}
	if d := som.SomMetaNodeDiff(pa, pb, "doc"); !strings.HasPrefix(d, "doc/lines: className differs") {
		t.Errorf("child under the given prefix: %s", d)
	}
}
