// The reading notation's scanner (spec_notation.go) beyond the shared corpus:
// offsets are UTF-16 code units although Go strings are UTF-8, so a character
// outside the Basic Multilingual Plane counts twice — the offsets below are the
// ones the JavaScript and TypeScript scanners report for the same text (as the
// Python port's `spec_notation_test.py` and the Rust port's
// `tests/spec_notation.rs`). `notation_cases.json` (run by the conformance
// runner) holds the grammar itself.
package tests

import (
	"reflect"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// notationEmoji is two UTF-16 code units, four UTF-8 bytes, one rune.
const notationEmoji = "\U0001F600"

func notationText() string {
	e := notationEmoji
	return e + " [x" + e + "]{.aside} (-> " + e + "A)\n\n::: {.rejected}\n" + e +
		" {++a [b]{.trace}++} c\n:::\n::: {.mine}\n"
}

// notationShape is an element's type and UTF-16 range, with its children's.
type notationShape struct {
	Type       string
	Start, End int
	Children   []notationShape
}

func TestNotationUTF16Offsets(t *testing.T) {
	text := notationText()
	scan := som.ScanNotation(text, true)
	var got []notationShape
	for _, e := range scan.Elements {
		s := notationShape{Type: e.Type, Start: e.Start, End: e.End}
		for _, c := range e.Children {
			s.Children = append(s.Children, notationShape{Type: c.Type, Start: c.Start, End: c.End})
		}
		got = append(got, s)
	}
	want := []notationShape{
		{"span", 3, 16, nil},
		{"citation", 17, 25, nil},
		{"div", 27, 71, []notationShape{{"span", 51, 62, nil}}},
		{"div", 72, 84, nil},
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("elements %+v != %+v", got, want)
	}

	span := scan.Elements[0].ToJSON(text)
	if span["source"] != "[x"+notationEmoji+"]{.aside}" {
		t.Errorf("span source %q", span["source"])
	}
	if span["content"] != "x"+notationEmoji {
		t.Errorf("span content %q", span["content"])
	}

	type finding struct {
		Code         som.NotationFindingCode
		Offset, Line int
	}
	var findings []finding
	for _, f := range scan.Findings {
		findings = append(findings, finding{f.Code, f.Offset, f.Line})
	}
	wantFindings := []finding{
		{som.NotationRejectedBlock, 27, 3},
		{som.NotationUnclosedDiv, 72, 6},
		{som.NotationUnknownKind, 72, 6},
	}
	if !reflect.DeepEqual(findings, wantFindings) {
		t.Errorf("findings %+v != %+v", findings, wantFindings)
	}
	if !scan.HasErrors() {
		t.Errorf("HasErrors() is false")
	}
	var all []string
	for _, e := range scan.All() {
		all = append(all, e.Type)
	}
	if !reflect.DeepEqual(all, []string{"span", "citation", "div", "span", "div"}) {
		t.Errorf("All() = %v", all)
	}
}

func TestNotationVocabulary(t *testing.T) {
	if som.NotationSeverity(som.NotationUnknownKind) != "warning" {
		t.Errorf("unknownKind is no warning")
	}
	for _, code := range som.NotationFindingCodes {
		if code != som.NotationUnknownKind && som.NotationSeverity(code) != "error" {
			t.Errorf("%s is no error", code)
		}
		if back, ok := som.NotationFindingCodeFromName(code.String()); !ok || back != code {
			t.Errorf("%s does not round-trip by name", code)
		}
	}
	if len(som.NotationFindingCodes) != 9 {
		t.Errorf("%d codes, want 9", len(som.NotationFindingCodes))
	}
	kinds := map[string]bool{}
	for _, k := range som.RegisteredNotationKinds {
		kinds[k] = true
	}
	if !kinds["linked"] || !kinds["derived"] || len(som.RegisteredNotationKinds) != 9 {
		t.Errorf("registered kinds %v", som.RegisteredNotationKinds)
	}
	if plain := som.ScanNotation("::: {.mine}\n:::\n", false); len(plain.Findings) != 0 {
		t.Errorf("a plain DocSpecs value reports %v", plain.Findings)
	}
}

func TestNotationRulesAreDocSpecsRules(t *testing.T) {
	rules := map[string]bool{}
	for _, r := range som.DocSpecsAllRules {
		rules[r] = true
	}
	for _, code := range som.NotationFindingCodes {
		if !rules[code.String()] {
			t.Errorf("%s is no DocSpecs rule", code)
		}
	}
}
