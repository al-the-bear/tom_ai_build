// Package tests runs the shared-corpus conformance suite against the Go generic
// runtime (tom_som_go_runtime).
//
// It loads the language-agnostic conformance corpus produced from the Dart
// reference (`tom_som_conformance/corpus`) and asserts the Go port reproduces
// every golden byte-for-byte and matches every behavioural case:
//
//   - model meta-data loads (root + class structure);
//   - state.json loads and re-serialises identically;
//   - YAML encode == expected.docspecs.yaml (byte-for-byte);
//   - YAML decode → memory → encode is byte-stable + preserves the stamp;
//   - Markdown export == expected.md (byte-for-byte);
//   - Markdown parse → memory → export is clean + byte-stable;
//   - the Markdown route lands the fixture in the same memory as the YAML route;
//   - reflection resolution cases;
//   - validation cases;
//   - the imperative operations script.
//
// `go test ./tests/` is the native runner; exit 0 == all green.
package tests

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	som "tom_som_go_runtime"
)

const corpusRel = "../../tom_som_conformance/corpus"
const modelVersion = "1.0"

type checker struct {
	t      *testing.T
	passed int
	failed []string
}

func (c *checker) check(name string, cond bool, detail string) {
	if cond {
		c.passed++
		return
	}
	if detail != "" {
		c.failed = append(c.failed, name+": "+detail)
	} else {
		c.failed = append(c.failed, name)
	}
}

func (c *checker) finish() {
	total := c.passed + len(c.failed)
	if len(c.failed) > 0 {
		for _, f := range c.failed {
			c.t.Errorf("  - %s", f)
		}
		c.t.Fatalf("FAIL: %d/%d checks failed", len(c.failed), total)
	}
	c.t.Logf("OK: %d checks passed", total)
}

func readCorpus(t *testing.T, name string) string {
	b, err := os.ReadFile(filepath.Join(corpusRel, name))
	if err != nil {
		t.Fatalf("read corpus %s: %v", name, err)
	}
	return string(b)
}

func readJSON(t *testing.T, name string, v interface{}) {
	if err := json.Unmarshal([]byte(readCorpus(t, name)), v); err != nil {
		t.Fatalf("parse corpus %s: %v", name, err)
	}
}

func canonJSON(t *testing.T, v interface{}) string {
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("marshal: %v", err)
	}
	return string(b)
}

func loadModel(t *testing.T) *som.SpecModel {
	m, err := som.SpecModelFromJSON([]byte(readCorpus(t, "model.meta.json")))
	if err != nil {
		t.Fatalf("load model: %v", err)
	}
	return m
}

func docFromState(state *som.DocumentJson) *som.SpecDocument {
	doc := som.NewSpecDocument()
	doc.LoadJSON(state)
	return doc
}

func byteDiff(label, actual, expected string) string {
	if actual == expected {
		return ""
	}
	aLines := splitLines(actual)
	eLines := splitLines(expected)
	max := len(aLines)
	if len(eLines) > max {
		max = len(eLines)
	}
	for idx := 0; idx < max; idx++ {
		a, e := "<EOF>", "<EOF>"
		if idx < len(aLines) {
			a = aLines[idx]
		}
		if idx < len(eLines) {
			e = eLines[idx]
		}
		if a != e {
			return label + ": first diff at line " + itoa(idx+1) + ": got " + quote(a) + " want " + quote(e)
		}
	}
	return label + ": differ (len got " + itoa(len(actual)) + " want " + itoa(len(expected)) + ")"
}

func splitLines(s string) []string {
	var out []string
	cur := ""
	for _, r := range s {
		if r == '\n' {
			out = append(out, cur)
			cur = ""
		} else {
			cur += string(r)
		}
	}
	out = append(out, cur)
	return out
}

func quote(s string) string {
	b, _ := json.Marshal(s)
	return string(b)
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	var buf [20]byte
	i := len(buf)
	for n > 0 {
		i--
		buf[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		buf[i] = '-'
	}
	return string(buf[i:])
}

func optName(s string) string {
	if s == "" {
		return "<nil>"
	}
	return s
}

func TestConformance(t *testing.T) {
	if st, err := os.Stat(corpusRel); err != nil || !st.IsDir() {
		t.Fatalf("corpus not found at %s", corpusRel)
	}
	c := &checker{t: t}
	model := loadModel(t)

	testModelMeta(c, model)
	testStateRoundTrip(c, t)
	testYamlEncode(c, t)
	testYamlDecodeRoundTrip(c, t)
	testMarkdownExport(c, t, model)
	testMarkdownRoundTrip(c, t, model)
	testMarkdownMemoryLanding(c, t, model)
	testReflection(c, t, model)
	testValidation(c, t, model)
	testOperations(c, t)

	c.finish()
}

func testModelMeta(c *checker, model *som.SpecModel) {
	root := model.Roots[0]
	c.check("model.root.sectionId", root.SectionID == "DEMO", root.SectionID)
	c.check("model.root.type", root.Type == "Demo", root.Type)
	c.check("model.classCount", len(model.Classes) == 3, itoa(len(model.Classes)))
	demo := model.ClassNamed("Demo")
	c.check("model.Demo.found", demo != nil, "")
	if demo != nil {
		var names []string
		for _, f := range demo.Fields {
			names = append(names, f.Name)
		}
		want := []string{"title", "summary", "priority", "count", "details", "items", "meta"}
		c.check("model.Demo.fields", sliceEq(names, want), join(names))
	}
}

func testStateRoundTrip(c *checker, t *testing.T) {
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	doc := docFromState(&state)
	got := canonJSON(t, doc.ToJSON())
	want := canonJSON(t, &state)
	c.check("state.toJson", got == want, "got "+got+" want "+want)
}

func testYamlEncode(c *checker, t *testing.T) {
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	doc := docFromState(&state)
	expected := readCorpus(t, "expected.docspecs.yaml")
	actual := som.EncodeYaml(doc, modelVersion)
	c.check("yaml.encode", actual == expected, byteDiff("yaml.encode", actual, expected))
}

func testYamlDecodeRoundTrip(c *checker, t *testing.T) {
	expected := readCorpus(t, "expected.docspecs.yaml")
	contents := som.DecodeYaml(expected)
	c.check("yaml.decode.stamp", contents.ModelVersion == modelVersion, contents.ModelVersion)
	doc := som.NewSpecDocument()
	doc.LoadJSON(contents.Document)
	stamp := contents.ModelVersion
	if stamp == "" {
		stamp = modelVersion
	}
	actual := som.EncodeYaml(doc, stamp)
	c.check("yaml.decode.reencode", actual == expected, byteDiff("yaml.decode.reencode", actual, expected))
}

func testMarkdownExport(c *checker, t *testing.T, model *som.SpecModel) {
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	doc := docFromState(&state)
	expected := readCorpus(t, "expected.md")
	actual := som.NewSpecDocumentMarkdown(model, doc).ExportRoot(model.Roots[0])
	c.check("md.export", actual == expected, byteDiff("md.export", actual, expected))
}

func testMarkdownRoundTrip(c *checker, t *testing.T, model *som.SpecModel) {
	expected := readCorpus(t, "expected.md")
	codec := som.NewSpecDocumentMarkdown(model, som.NewSpecDocument())
	result := codec.Parse(expected)
	c.check("md.parse.clean", result.IsClean(), rejStr(result.Rejections))
	applied := som.NewSpecDocument()
	applied.LoadJSON(&som.DocumentJson{Content: result.Content, Forms: result.Forms, Lists: result.Lists})
	actual := som.NewSpecDocumentMarkdown(model, applied).ExportRoot(model.Roots[0])
	c.check("md.parse.reexport", actual == expected, byteDiff("md.parse.reexport", actual, expected))
}

func testMarkdownMemoryLanding(c *checker, t *testing.T, model *som.SpecModel) {
	expectedMd := readCorpus(t, "expected.md")
	var canonical som.DocumentJson
	readJSON(t, "state.json", &canonical)
	result := som.NewSpecDocumentMarkdown(model, som.NewSpecDocument()).Parse(expectedMd)
	c.check("md.land.clean", result.IsClean(), rejStr(result.Rejections))
	landed := som.NewSpecDocument()
	landed.LoadJSON(&som.DocumentJson{Content: result.Content, Forms: result.Forms, Lists: result.Lists})
	got := canonJSON(t, landed.ToJSON())
	want := canonJSON(t, &canonical)
	c.check("md.land.memory", got == want, "got "+got+" want "+want)
}

type reflCase struct {
	Path        string  `json:"path"`
	Resolves    bool    `json:"resolves"`
	Kind        string  `json:"kind"`
	Field       *string `json:"field"`
	TargetClass *string `json:"targetClass"`
	IsValueLeaf bool    `json:"isValueLeaf"`
}

func testReflection(c *checker, t *testing.T, model *som.SpecModel) {
	refl := som.NewSpecReflection(model)
	var cases []reflCase
	readJSON(t, "reflection_cases.json", &cases)
	for _, cc := range cases {
		res := refl.Resolve(cc.Path)
		if !cc.Resolves {
			c.check("reflect["+cc.Path+"].none", res == nil, "expected no resolution")
			continue
		}
		if res == nil {
			c.check("reflect["+cc.Path+"].some", false, "expected resolution, got nil")
			continue
		}
		c.check("reflect["+cc.Path+"].kind", res.Kind == cc.Kind, res.Kind+" != "+cc.Kind)
		fieldName := ""
		if res.Field != nil {
			fieldName = res.Field.Name
		}
		c.check("reflect["+cc.Path+"].field", optEq(fieldName, cc.Field), optName(fieldName)+" != "+optStr(cc.Field))
		target := ""
		if res.TargetClass != nil {
			target = res.TargetClass.Name
		}
		c.check("reflect["+cc.Path+"].target", optEq(target, cc.TargetClass), optName(target)+" != "+optStr(cc.TargetClass))
		c.check("reflect["+cc.Path+"].leaf", res.IsValueLeaf() == cc.IsValueLeaf, "")
	}
}

type valCase struct {
	Name   string           `json:"name"`
	State  som.DocumentJson `json:"state"`
	Errors []struct {
		Path string `json:"path"`
		Code string `json:"code"`
	} `json:"errors"`
}

func testValidation(c *checker, t *testing.T, model *som.SpecModel) {
	var cases []valCase
	readJSON(t, "validation_cases.json", &cases)
	for _, cc := range cases {
		state := cc.State
		doc := docFromState(&state)
		errs := som.ValidateDocument(model, doc)
		var got [][2]string
		for _, e := range errs {
			got = append(got, [2]string{e.Path, e.Code})
		}
		var want [][2]string
		for _, e := range cc.Errors {
			want = append(want, [2]string{e.Path, e.Code})
		}
		c.check("validate["+cc.Name+"]", pairsEq(got, want), canonJSON(t, got)+" != "+canonJSON(t, want))
	}
}

type opCase struct {
	Op       string          `json:"op"`
	Expect   json.RawMessage `json:"expect"`
	Path     string          `json:"path"`
	Value    string          `json:"value"`
	Field    string          `json:"field"`
	ListPath string          `json:"listPath"`
	Prefix   string          `json:"prefix"`
	ItemPath string          `json:"itemPath"`
}

func testOperations(c *checker, t *testing.T) {
	doc := som.NewSpecDocument()
	var cases []opCase
	readJSON(t, "operations_cases.json", &cases)
	for n, op := range cases {
		tag := "op[" + itoa(n) + "]." + op.Op
		switch op.Op {
		case "isEmpty":
			var exp bool
			json.Unmarshal(op.Expect, &exp)
			c.check(tag, doc.IsEmpty() == exp, "")
		case "setContent":
			doc.SetContent(op.Path, op.Value)
		case "content":
			var exp *string
			json.Unmarshal(op.Expect, &exp)
			val, ok := doc.Content(op.Path)
			if exp == nil {
				c.check(tag, !ok, "expected unset")
			} else {
				c.check(tag, ok && val == *exp, val)
			}
		case "setFormField":
			doc.SetFormField(op.Path, op.Field, op.Value)
		case "formField":
			var exp *string
			json.Unmarshal(op.Expect, &exp)
			val, ok := doc.FormField(op.Path, op.Field)
			if exp == nil {
				c.check(tag, !ok, "expected unset")
			} else {
				c.check(tag, ok && val == *exp, val)
			}
		case "addListItem":
			var exp string
			json.Unmarshal(op.Expect, &exp)
			got := doc.AddListItem(op.ListPath)
			c.check(tag, got == exp, got+" != "+exp)
		case "listItems":
			var exp []string
			json.Unmarshal(op.Expect, &exp)
			c.check(tag, sliceEq(doc.ListItems(op.ListPath), exp), join(doc.ListItems(op.ListPath)))
		case "listItemCount":
			var exp int
			json.Unmarshal(op.Expect, &exp)
			c.check(tag, doc.ListItemCount(op.ListPath) == exp, itoa(doc.ListItemCount(op.ListPath)))
		case "hasValuesUnder":
			var exp bool
			json.Unmarshal(op.Expect, &exp)
			c.check(tag, doc.HasValuesUnder(op.Prefix) == exp, "")
		case "removeListItem":
			var exp bool
			json.Unmarshal(op.Expect, &exp)
			c.check(tag, doc.RemoveListItem(op.ItemPath) == exp, "")
		default:
			c.check(tag+".unknown", false, op.Op)
		}
	}
}

// --- small helpers ---------------------------------------------------------

func sliceEq(a, b []string) bool {
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

func pairsEq(a, b [][2]string) bool {
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

func optEq(got string, want *string) bool {
	if want == nil {
		return got == ""
	}
	return got == *want
}

func optStr(s *string) string {
	if s == nil {
		return "<nil>"
	}
	return *s
}

func join(s []string) string {
	out := ""
	for i, v := range s {
		if i > 0 {
			out += ","
		}
		out += v
	}
	return out
}

func rejStr(rejections []som.SpecMarkdownRejection) string {
	out := ""
	for i, r := range rejections {
		if i > 0 {
			out += "; "
		}
		out += r.String()
	}
	return out
}
