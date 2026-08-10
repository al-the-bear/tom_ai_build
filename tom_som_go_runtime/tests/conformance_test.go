// Package tests runs the shared-corpus conformance suite against the Go generic
// runtime (tom_som_go_runtime).
//
// It loads the language-agnostic conformance corpus produced from the Dart
// reference (`tom_som_conformance/corpus`) and asserts the Go port reproduces
// every golden byte-for-byte and matches every behavioural case:
//
//   - model meta-data loads (root + class structure);
//   - state.json loads and re-serialises identically;
//   - hierarchical YAML encode (v2, tree-based) == expected.docspecs.yaml
//     (byte-for-byte);
//   - YAML decode → memory equals state.json, and → encode is byte-stable +
//     preserves the stamp;
//   - the SOM §4.2/§21 editability contract (classification + refusal message);
//   - reflection resolution cases;
//   - validation cases;
//   - the imperative operations script;
//   - the generic editor script (YRD7);
//   - the SOM §14 DocSpecs tier (one case per violation rule);
//   - the portable text-pattern subset (match spans + compile rejections);
//   - the query surface (match lists, cursor laziness, the projection walk);
//   - the constrained node-creation gate (per-code rejections + the script).
//
// `go test ./tests/` is the native runner; exit 0 == all green.
package tests

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
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

	tree, err := som.BuildSomMetaTree(model, "")
	if err != nil {
		t.Fatalf("BuildSomMetaTree: %v", err)
	}

	testModelMeta(c, model)
	testStamp(c, t, model)
	testEditability(c, t)
	testStateRoundTrip(c, t)
	testYamlEncode(c, t, tree)
	testYamlDecodeRoundTrip(c, t, tree)
	testMarkdownExport(c, t, model)
	testMarkdownRoundTrip(c, t, model)
	testMarkdownMemoryLanding(c, t, model)
	testReflection(c, t, model)
	testValidation(c, t, model)
	testOperations(c, t)
	testEditor(c, t, model)
	testSectionId(c, t)
	testSerializationOrder(c, t)
	testDocSpecs(c, t)
	testPattern(c, t)
	testQuery(c, t, model)
	testProjection(c, t, model)
	testCursor(c, t, model)
	testNodeCreation(c, t, model)
	testNodeCreationScript(c, t, model)

	c.finish()
}

func testModelMeta(c *checker, model *som.SpecModel) {
	root := model.Roots[0]
	c.check("model.root.sectionId", root.SectionID == "DEMO", root.SectionID)
	c.check("model.root.type", root.Type == "Demo", root.Type)
	c.check("model.classCount", len(model.Classes) == 12, itoa(len(model.Classes)))
	demo := model.ClassNamed("Demo")
	c.check("model.Demo.found", demo != nil, "")
	if demo != nil {
		var names []string
		for _, f := range demo.Fields {
			names = append(names, f.Name)
		}
		want := []string{"title", "summary", "priority", "count", "details", "items", "refs", "cards", "meta", "control", "notes", "registry"}
		c.check("model.Demo.fields", sliceEq(names, want), join(names))
	}
}

// stampCaseTable mirrors corpus/stamp_cases.json — the cross-language stamp
// contract. Ages are whole seconds and thresholds whole days so the table
// carries no language's duration type.
type stampCaseTable struct {
	DefaultMaxAgeDays int `json:"defaultMaxAgeDays"`
	Cases             []struct {
		Name   string          `json:"name"`
		Model  json.RawMessage `json:"model"`
		Expect struct {
			GeneratedAtEpochSeconds *int64  `json:"generatedAtEpochSeconds"`
			MetaSchemaVersion       *int    `json:"metaSchemaVersion"`
			ClassCount              *int    `json:"classCount"`
			RootCount               *int    `json:"rootCount"`
			ContainerRoot           *string `json:"containerRoot"`
			ActualClassCount        int     `json:"actualClassCount"`
			ActualRootCount         int     `json:"actualRootCount"`
		} `json:"expect"`
		Check struct {
			NowEpochSeconds     int64    `json:"nowEpochSeconds"`
			MaxAgeDays          int      `json:"maxAgeDays"`
			AgeSeconds          *int64   `json:"ageSeconds"`
			IsAged              bool     `json:"isAged"`
			ClassCountDisagrees bool     `json:"classCountDisagrees"`
			RootCountDisagrees  bool     `json:"rootCountDisagrees"`
			CountsDisagree      bool     `json:"countsDisagree"`
			IsStale             bool     `json:"isStale"`
			Warnings            []string `json:"warnings"`
		} `json:"check"`
	} `json:"cases"`
}

// testStamp asserts the generation stamp: the five keys the exporter writes,
// and the staleness verdict every runtime must reach from the same input.
func testStamp(c *checker, t *testing.T, model *som.SpecModel) {
	// The shared model fixture carries the stamp, minus containerRoot (it is a
	// single synthetic document with no container class).
	c.check("stamp.meta.generatedAt",
		model.GeneratedAt != nil && model.GeneratedAt.Unix() == 1784534400, "")
	c.check("stamp.meta.metaSchemaVersion",
		model.MetaSchemaVersion != nil && *model.MetaSchemaVersion == 1, "")
	c.check("stamp.meta.classCount",
		model.ClassCount != nil && *model.ClassCount == len(model.Classes), "")
	c.check("stamp.meta.rootCount",
		model.RootCount != nil && *model.RootCount == len(model.Roots), "")
	c.check("stamp.meta.containerRoot", model.ContainerRoot == "", model.ContainerRoot)

	var table stampCaseTable
	readJSON(t, "stamp_cases.json", &table)
	c.check("stamp.defaultMaxAgeDays",
		int64(table.DefaultMaxAgeDays) == int64(som.DefaultMaxSnapshotAge/(24*time.Hour)), "")
	for _, kase := range table.Cases {
		name := kase.Name
		loaded, err := som.SpecModelFromJSON(kase.Model)
		if err != nil {
			t.Fatalf("stamp case %s: %v", name, err)
		}
		want := kase.Expect
		var gotEpoch *int64
		if loaded.GeneratedAt != nil {
			e := loaded.GeneratedAt.Unix()
			gotEpoch = &e
		}
		c.check("stamp["+name+"].generatedAt", eqInt64Ptr(gotEpoch, want.GeneratedAtEpochSeconds), "")
		c.check("stamp["+name+"].metaSchemaVersion",
			eqIntPtr(loaded.MetaSchemaVersion, want.MetaSchemaVersion), "")
		c.check("stamp["+name+"].classCount", eqIntPtr(loaded.ClassCount, want.ClassCount), "")
		c.check("stamp["+name+"].rootCount", eqIntPtr(loaded.RootCount, want.RootCount), "")
		wantContainer := ""
		if want.ContainerRoot != nil {
			wantContainer = *want.ContainerRoot
		}
		c.check("stamp["+name+"].containerRoot", loaded.ContainerRoot == wantContainer,
			loaded.ContainerRoot)
		c.check("stamp["+name+"].actualClassCount", len(loaded.Classes) == want.ActualClassCount, "")
		c.check("stamp["+name+"].actualRootCount", len(loaded.Roots) == want.ActualRootCount, "")

		wc := kase.Check
		got := loaded.CheckStamp(
			time.Duration(wc.MaxAgeDays)*24*time.Hour,
			time.Unix(wc.NowEpochSeconds, 0).UTC())
		var ageSeconds *int64
		if got.Age != nil {
			s := int64(*got.Age / time.Second)
			ageSeconds = &s
		}
		c.check("stamp["+name+"].ageSeconds", eqInt64Ptr(ageSeconds, wc.AgeSeconds), "")
		c.check("stamp["+name+"].isAged", got.IsAged() == wc.IsAged, "")
		c.check("stamp["+name+"].classCountDisagrees",
			got.ClassCountDisagrees() == wc.ClassCountDisagrees, "")
		c.check("stamp["+name+"].rootCountDisagrees",
			got.RootCountDisagrees() == wc.RootCountDisagrees, "")
		c.check("stamp["+name+"].countsDisagree", got.CountsDisagree() == wc.CountsDisagree, "")
		c.check("stamp["+name+"].isStale", got.IsStale() == wc.IsStale, "")
		c.check("stamp["+name+"].warnings", sliceEq(got.Warnings(), wc.Warnings),
			join(got.Warnings()))
	}
}

// editabilityCaseTable mirrors corpus/editability_cases.json — the SOM §4.2/§21
// version contract. `documentVersion` and `message` are pointers because the
// corpus spells "no stamp" and "no refusal" as JSON null; Go's facade takes a
// non-nullable string, so a nil stamp maps to "" (the CS4-D2 sentinel).
type editabilityCaseTable struct {
	Cases []struct {
		Name            string  `json:"name"`
		Generated       string  `json:"generated"`
		DocumentVersion *string `json:"documentVersion"`
		Editability     string  `json:"editability"`
		Rejects         bool    `json:"rejects"`
		Message         *string `json:"message"`
	} `json:"cases"`
}

// editabilityToken maps a corpus token — spelled as the Dart constant name — to
// the Go port's own spelling.
func editabilityToken(t *testing.T, token string) som.SomEditability {
	switch token {
	case "editable":
		return som.SomEditabilityEditable
	case "readOnlyCrossMajor":
		return som.SomEditabilityReadOnlyCrossMajor
	case "rejectedNewerMinor":
		return som.SomEditabilityRejectedNewerMinor
	case "invalidVersion":
		return som.SomEditabilityInvalidVersion
	}
	t.Fatalf("unknown editability token: %s", token)
	return som.SomEditabilityEditable
}

// testEditability asserts the §4.2/§21 version check. The classifier and the
// check are one rule seen twice — `rejects` is just "the classification is not
// editable" — so asserting both is what makes a port that classifies right and
// refuses wrong fail. The message is pinned because `invalidVersion` is one
// outcome with two causes, and the message is where they separate.
func testEditability(c *checker, t *testing.T) {
	var table editabilityCaseTable
	readJSON(t, "editability_cases.json", &table)
	for _, kase := range table.Cases {
		name := kase.Name
		documentVersion := ""
		if kase.DocumentVersion != nil {
			documentVersion = *kase.DocumentVersion
		}
		want := editabilityToken(t, kase.Editability)
		got := som.SomEditabilityFor(kase.Generated, documentVersion)
		c.check("editability["+name+"].classification", got == want, itoa(int(got)))

		raised := ""
		if err := som.CheckSomModelVersion(kase.Generated, documentVersion); err != nil {
			var ve *som.SomVersionError
			if !errors.As(err, &ve) {
				t.Fatalf("editability case %s: unexpected error type %T", name, err)
			}
			raised = ve.Message
		}
		c.check("editability["+name+"].rejects", (raised != "") == kase.Rejects, optName(raised))
		wantMessage := ""
		if kase.Message != nil {
			wantMessage = *kase.Message
		}
		c.check("editability["+name+"].message", raised == wantMessage, optName(raised))
	}
}

func eqIntPtr(a, b *int) bool {
	if a == nil || b == nil {
		return a == nil && b == nil
	}
	return *a == *b
}

func eqInt64Ptr(a, b *int64) bool {
	if a == nil || b == nil {
		return a == nil && b == nil
	}
	return *a == *b
}

func testStateRoundTrip(c *checker, t *testing.T) {
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	doc := docFromState(&state)
	got := canonJSON(t, doc.ToJSON())
	want := canonJSON(t, &state)
	c.check("state.toJson", got == want, "got "+got+" want "+want)
}

func testYamlEncode(c *checker, t *testing.T, tree *som.SomMetaTree) {
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	doc := docFromState(&state)
	expected := readCorpus(t, "expected.docspecs.yaml")
	actual, err := som.EncodeYaml(doc, tree, modelVersion)
	if err != nil {
		c.check("yaml.encode", false, err.Error())
		return
	}
	c.check("yaml.encode", actual == expected, byteDiff("yaml.encode", actual, expected))
}

func testYamlDecodeRoundTrip(c *checker, t *testing.T, tree *som.SomMetaTree) {
	expected := readCorpus(t, "expected.docspecs.yaml")
	contents, err := som.DecodeYaml(expected, tree)
	if err != nil {
		c.check("yaml.decode.stamp", false, err.Error())
		return
	}
	c.check("yaml.decode.stamp", contents.ModelVersion == modelVersion, contents.ModelVersion)

	// The decoded memory equals the canonical state (the hierarchical decode
	// lands the same sparse stores state.json describes).
	var canonical som.DocumentJson
	readJSON(t, "state.json", &canonical)
	got := canonJSON(t, contents.Document.ToJSON())
	want := canonJSON(t, &canonical)
	c.check("yaml.decode.memory", got == want, "got "+got+" want "+want)

	stamp := contents.ModelVersion
	if stamp == "" {
		stamp = modelVersion
	}
	actual, err := som.EncodeYaml(contents.Document, tree, stamp)
	if err != nil {
		c.check("yaml.decode.reencode", false, err.Error())
		return
	}
	c.check("yaml.decode.reencode", actual == expected, byteDiff("yaml.decode.reencode", actual, expected))
}

// --- markdown conformance (SOM §11) -----------------------------------------

func testMarkdownExport(c *checker, t *testing.T, model *som.SpecModel) {
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	doc := docFromState(&state)
	expected := readCorpus(t, "expected.md")
	actual, err := som.NewSpecDocumentMarkdown(model, doc).ExportRoot(model.Roots[0])
	if err != nil {
		c.check("md.export", false, err.Error())
		return
	}
	c.check("md.export", actual == expected, byteDiff("md.export", actual, expected))
}

func testMarkdownRoundTrip(c *checker, t *testing.T, model *som.SpecModel) {
	golden := readCorpus(t, "expected.md")
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	doc := docFromState(&state)
	parsed := som.NewSpecDocumentMarkdown(model, doc).Parse(golden)
	c.check("md.parse.clean", len(parsed.Rejections) == 0, rejDetail(parsed))
	reDoc := som.NewSpecDocument()
	reDoc.LoadJSON(&som.DocumentJson{
		Content:   parsed.Content,
		Forms:     parsed.Forms,
		Lists:     parsed.Lists,
		Headlines: parsed.Headlines,
	})
	// YRD3: the stored item id and stored headline round-trip through md.
	c.check("md.parse.storedId",
		reDoc.ItemSectionIDOr("DEMO/REF-LST-1") == "REF-SPEC",
		reDoc.ItemSectionIDOr("DEMO/REF-LST-1"))
	c.check("md.parse.headline",
		reDoc.HeadlineOr("DEMO/REF-LST-1") == "Reference to the Spec",
		reDoc.HeadlineOr("DEMO/REF-LST-1"))
	actual, err := som.NewSpecDocumentMarkdown(model, reDoc).ExportRoot(model.Roots[0])
	if err != nil {
		c.check("md.parse.reexport", false, err.Error())
		return
	}
	c.check("md.parse.reexport", actual == golden, byteDiff("md.parse.reexport", actual, golden))
}

// Markdown/YAML convergence: parsing `expected.md` and applying it must
// reproduce `state.json` (the YAML-route memory) exactly, proving both formats
// converge on one in-memory document (SOM §8).
func testMarkdownMemoryLanding(c *checker, t *testing.T, model *som.SpecModel) {
	golden := readCorpus(t, "expected.md")
	var canonical som.DocumentJson
	readJSON(t, "state.json", &canonical)
	doc := docFromState(&canonical)
	parsed := som.NewSpecDocumentMarkdown(model, doc).Parse(golden)
	c.check("md.land.clean", len(parsed.Rejections) == 0, rejDetail(parsed))
	landed := som.NewSpecDocument()
	landed.LoadJSON(&som.DocumentJson{
		Content:   parsed.Content,
		Forms:     parsed.Forms,
		Lists:     parsed.Lists,
		Headlines: parsed.Headlines,
	})
	got := canonJSON(t, landed.ToJSON())
	want := canonJSON(t, &canonical)
	c.check("md.land.memory", got == want, "got "+got+" want "+want)
}

func rejDetail(r *som.SpecMarkdownResult) string {
	out := ""
	for i, rej := range r.Rejections {
		if i > 0 {
			out += "; "
		}
		out += rej.String()
	}
	return out
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

// --- DocSpecs-tier conformance (SOM §14) ------------------------------------

type docSpecsViolationCase struct {
	Rule string `json:"rule"`
	// SectionID is null in the corpus when the violation has no section to
	// point at; Go's zero value "" is this port's stand-in for that null, which
	// is what the runtime itself emits.
	SectionID string `json:"sectionId"`
	Line      int    `json:"line"`
}

type docSpecsCase struct {
	Name       string                  `json:"name"`
	Markdown   string                  `json:"markdown"`
	Violations []docSpecsViolationCase `json:"violations"`
}

// testDocSpecs replays the shared DocSpecs corpus: one schema, one case per
// §14 rule. Matching the Dart reference's rule/sectionId/line triples is what
// proves this port *implements* each rule rather than merely declaring its
// name — a rule with no case is invisible, not weakly covered.
func testDocSpecs(c *checker, t *testing.T) {
	schema, err := som.DocSpecsSchemaFromYamlText(readCorpus(t, "docspecs_schema.yaml"))
	if err != nil {
		t.Fatalf("docspecs schema: %v", err)
	}
	c.check("docspecs.schemaWarnings", len(schema.Warnings) == 0, join(schema.Warnings))
	c.check("docspecs.rootSectionId", schema.RootSectionID() == "D00", schema.RootSectionID())

	validator := som.NewDocSpecsValidator(schema)
	var cases []docSpecsCase
	readJSON(t, "docspecs_cases.json", &cases)
	covered := map[string]bool{}
	for _, cc := range cases {
		var got [][3]string
		for _, v := range validator.ValidateMarkdown(cc.Markdown) {
			got = append(got, [3]string{v.Rule, v.SectionID, itoa(v.Line)})
		}
		var want [][3]string
		for _, v := range cc.Violations {
			want = append(want, [3]string{v.Rule, v.SectionID, itoa(v.Line)})
			covered[v.Rule] = true
		}
		c.check("docspecs["+cc.Name+"]", triplesEq(got, want),
			canonJSON(t, got)+" != "+canonJSON(t, want))
	}

	var uncovered []string
	for _, rule := range som.DocSpecsAllRules {
		if !covered[rule] {
			uncovered = append(uncovered, rule)
		}
	}
	c.check("docspecs.ruleCoverage", len(uncovered) == 0, "uncovered: "+join(uncovered))
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
		case "setHeadline":
			doc.SetHeadline(op.Path, op.Value)
		case "headline":
			var exp *string
			json.Unmarshal(op.Expect, &exp)
			val, ok := doc.Headline(op.Path)
			if exp == nil {
				c.check(tag, !ok, "expected unset")
			} else {
				c.check(tag, ok && val == *exp, val)
			}
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

// --- generic editor conformance (YRD7) --------------------------------------

type editorCase struct {
	Op         string          `json:"op"`
	Path       string          `json:"path"`
	Field      string          `json:"field"`
	ListPath   string          `json:"listPath"`
	ItemPath   string          `json:"itemPath"`
	Prefix     string          `json:"prefix"`
	Month      int             `json:"month"`
	Day        int             `json:"day"`
	ExpectPath string          `json:"expectPath"`
	ExpectID   *string         `json:"expectId"`
	Value      json.RawMessage `json:"value"`
	Expect     json.RawMessage `json:"expect"`
}

// jsonAny decodes a corpus value/expectation into the dynamic shape the editor
// speaks. An absent key and a JSON null both land as nil (the "unset" value).
func jsonAny(t *testing.T, raw json.RawMessage) any {
	if len(raw) == 0 {
		return nil
	}
	var v any
	if err := json.Unmarshal(raw, &v); err != nil {
		t.Fatalf("decode editor value %s: %v", string(raw), err)
	}
	return v
}

func jsonString(t *testing.T, raw json.RawMessage) string {
	var s string
	if len(raw) == 0 {
		return ""
	}
	if err := json.Unmarshal(raw, &s); err != nil {
		t.Fatalf("decode editor string %s: %v", string(raw), err)
	}
	return s
}

func jsonStringPtr(t *testing.T, raw json.RawMessage) *string {
	if len(raw) == 0 {
		return nil
	}
	var s *string
	if err := json.Unmarshal(raw, &s); err != nil {
		t.Fatalf("decode editor string %s: %v", string(raw), err)
	}
	return s
}

// valueEq compares an editor value against a corpus expectation.
//
// encoding/json lands every JSON number in a float64 when the target is `any`,
// while the editor returns the model's own type (an int for an `int` leaf), so
// numbers are compared numerically rather than by dynamic type — the corpus
// pins the *value*, and the store text it produced is pinned separately by the
// rawContent / rawFormField expectations.
func valueEq(got, want any) bool {
	if got == nil || want == nil {
		return got == nil && want == nil
	}
	if gf, ok := asFloat64(got); ok {
		wf, ok := asFloat64(want)
		return ok && gf == wf
	}
	return got == want
}

func asFloat64(v any) (float64, bool) {
	switch n := v.(type) {
	case int:
		return float64(n), true
	case int64:
		return float64(n), true
	case float64:
		return n, true
	}
	return 0, false
}

func str(v any) string {
	b, _ := json.Marshal(v)
	return string(b)
}

// testEditor replays the shared editor script: YRD7's generic, meta-validated
// modification API (SpecEditor) — typed value/form-field round-trips through
// the shared boundary helpers, enum domain validation, and the structural
// create/clear ops.
//
// The script is stateful and ordered, so it runs start to finish against one
// document; a `*Throws` step only has to fail, and the steps after it are what
// prove it left the document alone.
func testEditor(c *checker, t *testing.T, model *som.SpecModel) {
	doc := som.NewSpecDocument()
	ed := som.NewSpecEditorForModel(doc, model)
	var cases []editorCase
	readJSON(t, "editor_cases.json", &cases)
	for n, s := range cases {
		tag := "editor[" + itoa(n) + "]." + s.Op
		switch s.Op {
		case "setValue":
			if err := ed.SetValue(s.Path, jsonAny(t, s.Value)); err != nil {
				c.check(tag+" "+s.Path, false, err.Error())
			}
		case "value":
			got, err := ed.Value(s.Path)
			c.check(tag+" "+s.Path, err == nil && valueEq(got, jsonAny(t, s.Expect)),
				str(got))
		case "setValueThrows":
			c.check(tag+" "+s.Path, ed.SetValue(s.Path, jsonAny(t, s.Value)) != nil,
				"expected an error")
		case "setContent": // raw store write (bypasses the typed boundary)
			doc.SetContent(s.Path, jsonString(t, s.Value))
		case "rawContent":
			val, ok := doc.Content(s.Path)
			exp := jsonStringPtr(t, s.Expect)
			if exp == nil {
				c.check(tag+" "+s.Path, !ok, "expected unset")
			} else {
				c.check(tag+" "+s.Path, ok && val == *exp, val)
			}
		case "setFormValue":
			if err := ed.SetFormValue(s.Path, s.Field, jsonAny(t, s.Value)); err != nil {
				c.check(tag+" "+s.Path+"#"+s.Field, false, err.Error())
			}
		case "formValue":
			got, err := ed.FormValue(s.Path, s.Field)
			c.check(tag+" "+s.Path+"#"+s.Field,
				err == nil && valueEq(got, jsonAny(t, s.Expect)), str(got))
		case "setFormValueThrows":
			c.check(tag+" "+s.Path+"#"+s.Field,
				ed.SetFormValue(s.Path, s.Field, jsonAny(t, s.Value)) != nil,
				"expected an error")
		case "rawFormField":
			val, ok := doc.FormField(s.Path, s.Field)
			exp := jsonStringPtr(t, s.Expect)
			if exp == nil {
				c.check(tag+" "+s.Path+"#"+s.Field, !ok, "expected unset")
			} else {
				c.check(tag+" "+s.Path+"#"+s.Field, ok && val == *exp, val)
			}
		case "formFieldNames":
			fields, err := ed.FormFields(s.Path)
			var names []string
			for _, ff := range fields {
				names = append(names, ff.Name)
			}
			var exp []string
			json.Unmarshal(s.Expect, &exp)
			c.check(tag+" "+s.Path, err == nil && sliceEq(names, exp), join(names))
		case "formFieldNamesThrows":
			_, err := ed.FormFields(s.Path)
			c.check(tag+" "+s.Path, err != nil, "expected an error")
		case "setHeadline":
			if err := ed.SetHeadline(s.Path, jsonString(t, s.Value)); err != nil {
				c.check(tag+" "+s.Path, false, err.Error())
			}
		case "headline":
			got, err := ed.Headline(s.Path)
			c.check(tag+" "+s.Path, err == nil && optEq(got, jsonStringPtr(t, s.Expect)),
				optName(got))
		case "headlineThrows":
			_, err := ed.Headline(s.Path)
			c.check(tag+" "+s.Path, err != nil, "expected an error")
		case "itemSectionId":
			got := doc.ItemSectionIDOr(s.ItemPath)
			c.check(tag+" "+s.ItemPath, optEq(got, jsonStringPtr(t, s.Expect)),
				optName(got))
		case "addListItem":
			p, err := ed.AddListItem(s.ListPath, "", s.Month, s.Day)
			if err != nil {
				c.check(tag+" "+s.ListPath, false, err.Error())
				break
			}
			c.check(tag+" "+s.ListPath, p == s.ExpectPath, p+" != "+s.ExpectPath)
			if s.ExpectID != nil {
				got := doc.ItemSectionIDOr(p)
				c.check(tag+" id "+s.ListPath, got == *s.ExpectID, got+" != "+*s.ExpectID)
			}
		case "addListItemThrows":
			_, err := ed.AddListItem(s.ListPath, "", s.Month, s.Day)
			c.check(tag+" "+s.ListPath, err != nil, "expected an error")
		case "removeListItem":
			var exp bool
			json.Unmarshal(s.Expect, &exp)
			c.check(tag+" "+s.ItemPath, ed.RemoveListItem(s.ItemPath) == exp, "")
		case "clearSection":
			if err := ed.ClearSection(s.Path); err != nil {
				c.check(tag+" "+s.Path, false, err.Error())
			}
		case "clearSectionThrows":
			c.check(tag+" "+s.Path, ed.ClearSection(s.Path) != nil, "expected an error")
		case "hasValuesUnder":
			var exp bool
			json.Unmarshal(s.Expect, &exp)
			c.check(tag+" "+s.Prefix, doc.HasValuesUnder(s.Prefix) == exp, "")
		default:
			c.check(tag+".unknown", false, s.Op)
		}
	}
}

// --- section-id conformance (AA1 criteria 3–6) -----------------------------

type sectionIdTwoLetterCase struct {
	Month  int    `json:"month"`
	Day    int    `json:"day"`
	Expect string `json:"expect"`
}

type sectionIdGenerateCase struct {
	Pattern  string   `json:"pattern"`
	Month    int      `json:"month"`
	Day      int      `json:"day"`
	Existing []string `json:"existing"`
	Expect   string   `json:"expect"`
}

type sectionIdOpCase struct {
	Op         string          `json:"op"`
	ListPath   string          `json:"listPath"`
	Pattern    string          `json:"pattern"`
	Month      int             `json:"month"`
	Day        int             `json:"day"`
	ExpectId   string          `json:"expectId"`
	ExpectPath string          `json:"expectPath"`
	Expect     json.RawMessage `json:"expect"`
	ItemPath   string          `json:"itemPath"`
	Id         string          `json:"id"`
}

type sectionIdCases struct {
	TwoLetterDate []sectionIdTwoLetterCase `json:"twoLetterDate"`
	Generate      []sectionIdGenerateCase  `json:"generate"`
	DocumentOps   []sectionIdOpCase        `json:"documentOps"`
}

// isCollision reports whether err is (or wraps) a SpecSectionIDCollision
// (criterion-5 guard).
func isCollision(err error) bool {
	var c *som.SpecSectionIDCollision
	return errors.As(err, &c)
}

func testSectionId(c *checker, t *testing.T) {
	var cases sectionIdCases
	readJSON(t, "section_id_cases.json", &cases)

	// Criterion 4: the two-letter day code.
	for _, tc := range cases.TwoLetterDate {
		got := som.EncodeTwoLetterDate(tc.Month, tc.Day)
		c.check("sectionId.twoLetterDate["+itoa(tc.Month)+"/"+itoa(tc.Day)+"]",
			got == tc.Expect, got+" != "+tc.Expect)
	}

	// Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
	for _, tc := range cases.Generate {
		got := som.GenerateListItemSectionID(tc.Pattern, tc.Month, tc.Day, tc.Existing)
		c.check("sectionId.generate["+tc.Pattern+"]", got == tc.Expect, got+" != "+tc.Expect)
	}

	// Criteria 5 & 6 at the document level.
	doc := som.NewSpecDocument()
	for i, s := range cases.DocumentOps {
		tag := "sectionId.op[" + itoa(i) + "]." + s.Op
		switch s.Op {
		case "addGen":
			genID := som.GenerateListItemSectionID(s.Pattern, s.Month, s.Day, doc.ListItemSectionIDs(s.ListPath))
			c.check(tag+".id", genID == s.ExpectId, genID+" != "+s.ExpectId)
			p, err := doc.AddListItemWithSectionID(s.ListPath, genID)
			c.check(tag+".add", err == nil, "unexpected error")
			c.check(tag+".path", p == s.ExpectPath, p+" != "+s.ExpectPath)
		case "sectionIds":
			var exp []string
			json.Unmarshal(s.Expect, &exp)
			got := doc.ListItemSectionIDs(s.ListPath)
			c.check(tag, sliceEq(got, exp), join(got)+" != "+join(exp))
		case "removeListItem":
			var exp bool
			json.Unmarshal(s.Expect, &exp)
			c.check(tag, doc.RemoveListItem(s.ItemPath) == exp, "")
		case "override":
			if err := doc.SetItemSectionID(s.ItemPath, s.Id); err != nil {
				c.check(tag, false, "unexpected error: "+err.Error())
			}
		case "overrideThrows":
			c.check(tag, isCollision(doc.SetItemSectionID(s.ItemPath, s.Id)), "expected collision")
		case "addExplicitThrows":
			_, err := doc.AddListItemWithSectionID(s.ListPath, s.Id)
			c.check(tag, isCollision(err), "expected collision")
		default:
			c.check(tag+".unknown", false, s.Op)
		}
	}
}

// --- serialization-order conformance (AA1 criterion 7) ---------------------

type serializationOrderCases struct {
	Model             json.RawMessage `json:"model"`
	ContentPaths      []string        `json:"contentPaths"`
	ExpectedOrder     []string        `json:"expectedOrder"`
	FormPath          string          `json:"formPath"`
	FormFields        []string        `json:"formFields"`
	ExpectedFormOrder []string        `json:"expectedFormOrder"`
}

func testSerializationOrder(c *checker, t *testing.T) {
	var cases serializationOrderCases
	readJSON(t, "serialization_order_cases.json", &cases)
	model, err := som.SpecModelFromJSON(cases.Model)
	if err != nil {
		t.Fatalf("serialization order model: %v", err)
	}
	order := som.NewSpecSerializationOrder(model)

	gotPaths := order.OrderPaths(cases.ContentPaths)
	c.check("serialOrder.orderPaths", sliceEq(gotPaths, cases.ExpectedOrder),
		join(gotPaths)+" != "+join(cases.ExpectedOrder))

	gotFields := order.OrderFormFields(cases.FormPath, cases.FormFields)
	c.check("serialOrder.orderFormFields", sliceEq(gotFields, cases.ExpectedFormOrder),
		join(gotFields)+" != "+join(cases.ExpectedFormOrder))
}

// --- portable text pattern / query / node creation (SOM §9) -----------------

// freshDoc rebuilds the shared fixture document from state.json. The stateful
// scripts below each mutate their document, so every one of them starts from
// its own copy — the Go equivalent of the reference's `_buildDocument()`.
func freshDoc(t *testing.T) *som.SpecDocument {
	var state som.DocumentJson
	readJSON(t, "state.json", &state)
	return docFromState(&state)
}

// nullable renders this port's "" (its stand-in for the reference's null) back
// as a JSON null, so the record maps below compare against the corpus verbatim.
func nullable(s string) any {
	if s == "" {
		return nil
	}
	return s
}

// spanPairs renders match spans as the corpus's [start, end] pairs. Always a
// non-nil slice, so a spanless match encodes as `[]` and not `null`.
func spanPairs(spans []som.SpecMatchSpan) [][2]int {
	out := [][2]int{}
	for _, s := range spans {
		out = append(out, [2]int{s.Start, s.End})
	}
	return out
}

type patternCase struct {
	Pattern         string  `json:"pattern"`
	Regex           bool    `json:"regex"`
	CaseInsensitive bool    `json:"caseInsensitive"`
	Error           bool    `json:"error"`
	Text            string  `json:"text"`
	Spans           [][]int `json:"spans"`
}

// testPattern replays the portable pattern subset: the spans every runtime must
// report for a match case, and the compile rejection every runtime must raise
// for an out-of-subset source.
//
// Go's `regexp` cannot stand in here: RE2 is leftmost-longest where the
// reference is leftmost-first with backtracking, and the spans *are* the
// contract — hence the hand-written matcher this table is pointed at.
func testPattern(c *checker, t *testing.T) {
	var cases []patternCase
	readJSON(t, "pattern_cases.json", &cases)
	rejections, accepts := 0, 0
	for _, cc := range cases {
		tag := "pattern[" + quote(cc.Pattern) + "]"
		if cc.Error {
			rejections++
			_, err := som.CompileSomTextPattern(cc.Pattern, cc.CaseInsensitive)
			var pErr *som.SomPatternError
			c.check(tag+".rejected", errors.As(err, &pErr),
				"expected a SomPatternError")
			continue
		}
		accepts++
		var p *som.SomTextPattern
		if cc.Regex {
			compiled, err := som.CompileSomTextPattern(cc.Pattern, cc.CaseInsensitive)
			if err != nil {
				c.check(tag+".compile", false, err.Error())
				continue
			}
			p = compiled
		} else {
			p = som.NewSomTextPatternLiteral(cc.Pattern, cc.CaseInsensitive)
		}
		got := canonJSON(t, spanPairs(p.AllMatches(cc.Text)))
		want := canonJSON(t, cc.Spans)
		c.check(tag+" over "+quote(cc.Text), got == want, got+" != "+want)
		c.check(tag+".hasMatch", p.HasMatch(cc.Text) == (len(cc.Spans) > 0), "")
	}
	// A table of matches alone would let a port accept everything; a table of
	// rejections alone would let one reject everything.
	c.check("pattern.table.rejections", rejections > 0, "no rejection case")
	c.check("pattern.table.matches", accepts > 0, "no match case")
}

// queryWire is a SpecQuery in its corpus form. Every pointer is nil when the key
// is absent, which is what makes "dimension unset" distinguishable from
// "dimension set to the zero value" — `{"caseInsensitive": false}` and `{}` are
// the same query only because the reference defaults that flag to false, while
// `{"kinds": []}` (admit nothing) and `{}` (admit everything) are not.
//
// Kept in the test rather than in the runtime: the decode belongs to the corpus
// format, not to the API (the reference keeps its `_queryFromJson` here too).
type queryWire struct {
	Text            *string   `json:"text"`
	Regex           *bool     `json:"regex"`
	CaseInsensitive *bool     `json:"caseInsensitive"`
	Kinds           *[]string `json:"kinds"`
	ClassName       *string   `json:"className"`
	SectionIDExact  *string   `json:"sectionIdExact"`
	SectionIDPrefix *string   `json:"sectionIdPrefix"`
	PathGlob        *string   `json:"pathGlob"`
	MapsTo          *string   `json:"mapsTo"`
	DetailedIn      *string   `json:"detailedIn"`
	State           *string   `json:"state"`
}

func queryFromJSON(t *testing.T, raw json.RawMessage) som.SpecQuery {
	var w queryWire
	if len(raw) > 0 {
		if err := json.Unmarshal(raw, &w); err != nil {
			t.Fatalf("decode query %s: %v", string(raw), err)
		}
	}
	q := som.SpecQuery{
		Text:            w.Text,
		ClassName:       w.ClassName,
		SectionIDExact:  w.SectionIDExact,
		SectionIDPrefix: w.SectionIDPrefix,
		PathGlob:        w.PathGlob,
		MapsTo:          w.MapsTo,
		DetailedIn:      w.DetailedIn,
		State:           w.State,
	}
	if w.Regex != nil {
		q.Regex = *w.Regex
	}
	if w.CaseInsensitive != nil {
		q.CaseInsensitive = *w.CaseInsensitive
	}
	if w.Kinds != nil {
		// A non-nil (even empty) slice is the "kinds dimension supplied" signal;
		// leaving it nil is what admits every kind.
		kinds := []string{}
		kinds = append(kinds, *w.Kinds...)
		q.Kinds = kinds
	}
	return q
}

func matchRecord(m som.SpecQueryMatch) map[string]any {
	return map[string]any{
		"path":     m.Path,
		"kind":     m.Kind,
		"classId":  nullable(m.ClassID),
		"headline": nullable(m.Headline),
		"snippet":  nullable(m.Snippet),
		"spans":    spanPairs(m.MatchSpans),
	}
}

type queryCase struct {
	Name    string          `json:"name"`
	Query   json.RawMessage `json:"query"`
	Matches json.RawMessage `json:"matches"`
}

// testQuery replays the query surface twice over: once draining each cursor (the
// match list, in order) and once asking only for Count. The second pass is the
// same fact from the other side — a port that implements ToList by draining but
// Count by returning the candidate count passes the first and fails the second.
func testQuery(c *checker, t *testing.T, model *som.SpecModel) {
	var cases []queryCase
	readJSON(t, "query_cases.json", &cases)
	doc := freshDoc(t)
	engine := som.NewSpecQueryEngine(model, doc)
	for _, cc := range cases {
		cursor, err := engine.Query(queryFromJSON(t, cc.Query))
		if err != nil {
			c.check("query["+cc.Name+"]", false, err.Error())
			continue
		}
		got := []map[string]any{}
		for _, m := range cursor.ToList() {
			got = append(got, matchRecord(m))
		}
		var want []map[string]any
		if err := json.Unmarshal(cc.Matches, &want); err != nil {
			t.Fatalf("decode matches for %s: %v", cc.Name, err)
		}
		if want == nil {
			want = []map[string]any{}
		}
		gotJSON, wantJSON := canonJSON(t, got), canonJSON(t, want)
		c.check("query["+cc.Name+"]", gotJSON == wantJSON, gotJSON+" != "+wantJSON)

		counted, err := engine.Query(queryFromJSON(t, cc.Query))
		if err != nil {
			c.check("query["+cc.Name+"].count", false, err.Error())
			continue
		}
		c.check("query["+cc.Name+"].count", counted.Count() == len(want),
			itoa(counted.Count())+" != "+itoa(len(want)))
	}
}

// testProjection replays the full tier-1 index walk: every node of the
// structural closure, in document order, with its facets and searchable strings.
func testProjection(c *checker, t *testing.T, model *som.SpecModel) {
	doc := freshDoc(t)
	engine := som.NewSpecQueryEngine(model, doc)
	got := []map[string]any{}
	for _, p := range engine.ProjectNodes() {
		strings := p.SearchableStrings
		if strings == nil {
			strings = []string{}
		}
		got = append(got, map[string]any{
			"path":              p.Path,
			"kind":              p.Kind,
			"classId":           nullable(p.ClassID),
			"sectionId":         nullable(p.SectionID),
			"mapsTo":            nullable(p.MapsTo),
			"detailedIn":        nullable(p.DetailedIn),
			"headline":          nullable(p.Headline),
			"searchableStrings": strings,
			"hasValue":          p.HasValue,
		})
	}
	var want []map[string]any
	readJSON(t, "projection_cases.json", &want)
	gotJSON, wantJSON := canonJSON(t, got), canonJSON(t, want)
	c.check("projection.walk", gotJSON == wantJSON, gotJSON+" != "+wantJSON)

	// ProjectNode is the incremental-refresh entry point the walk is built from;
	// re-projecting one path must reproduce that path's committed record.
	if len(want) > 0 {
		path, _ := want[0]["path"].(string)
		single := engine.ProjectNode(path)
		c.check("projection.single["+path+"]",
			single != nil && single.Path == path && single.Kind == want[0]["kind"], "")
		c.check("projection.single.dangling",
			engine.ProjectNode("NOPE/nope") == nil, "expected nil for a dangling path")
	}
}

type cursorStep struct {
	Op       string          `json:"op"`
	Query    json.RawMessage `json:"query"`
	N        int             `json:"n"`
	ItemPath string          `json:"itemPath"`
	Expect   json.RawMessage `json:"expect"`
}

// testCursor replays the cursor script: laziness (Count does not consume, Take
// does) and the per-step re-validation against the live document — a list item
// removed after the cursor opened is skipped, not returned as a stale path.
func testCursor(c *checker, t *testing.T, model *som.SpecModel) {
	var steps []cursorStep
	readJSON(t, "cursor_cases.json", &steps)
	doc := freshDoc(t)
	engine := som.NewSpecQueryEngine(model, doc)
	var cursor *som.SpecQueryCursor
	for n, s := range steps {
		tag := "cursor[" + itoa(n) + "]." + s.Op
		switch s.Op {
		case "open":
			opened, err := engine.Query(queryFromJSON(t, s.Query))
			if err != nil {
				c.check(tag, false, err.Error())
				continue
			}
			cursor = opened
		case "count":
			var exp int
			json.Unmarshal(s.Expect, &exp)
			c.check(tag, cursor != nil && cursor.Count() == exp, itoa(cursor.Count()))
		case "take":
			got := []string{}
			for _, m := range cursor.Take(s.N) {
				got = append(got, m.Path)
			}
			var exp []string
			json.Unmarshal(s.Expect, &exp)
			c.check(tag+" "+itoa(s.N), sliceEq(got, exp), join(got)+" != "+join(exp))
		case "next":
			var exp *string
			json.Unmarshal(s.Expect, &exp)
			m := cursor.Next()
			if exp == nil {
				c.check(tag, m == nil, "expected the cursor to be exhausted")
			} else {
				c.check(tag, m != nil && m.Path == *exp, optName(matchPath(m)))
			}
		case "toList":
			got := []string{}
			for _, m := range cursor.ToList() {
				got = append(got, m.Path)
			}
			var exp []string
			json.Unmarshal(s.Expect, &exp)
			c.check(tag, sliceEq(got, exp), join(got)+" != "+join(exp))
		case "removeListItem":
			doc.RemoveListItem(s.ItemPath)
		default:
			c.check(tag+".unknown", false, s.Op)
		}
	}
}

func matchPath(m *som.SpecQueryMatch) string {
	if m == nil {
		return ""
	}
	return m.Path
}

type nodeCreationCase struct {
	Name         string  `json:"name"`
	ParentPath   string  `json:"parentPath"`
	ChildSegment string  `json:"childSegment"`
	ItemID       *string `json:"itemId"`
	Accepted     bool    `json:"accepted"`
	Code         *string `json:"code"`
}

// testNodeCreation replays the stateless creation gate: each probe runs against
// a freshly built document, so the cases are order-independent. A rejection is
// asserted on its code and the parent/child it names — never on message prose,
// which is a port's own wording.
func testNodeCreation(c *checker, t *testing.T, model *som.SpecModel) {
	var cases []nodeCreationCase
	readJSON(t, "node_creation_cases.json", &cases)
	covered := map[string]bool{}
	for _, cc := range cases {
		doc := freshDoc(t)
		itemID := ""
		if cc.ItemID != nil {
			itemID = *cc.ItemID
		}
		err := som.CheckAddNode(model, doc, cc.ParentPath, cc.ChildSegment, itemID)
		c.check("nodeCreate["+cc.Name+"].accepted", (err == nil) == cc.Accepted,
			"expected accepted="+boolStr(cc.Accepted))
		if err == nil {
			continue
		}
		covered[err.Code] = true
		c.check("nodeCreate["+cc.Name+"].code", optEq(err.Code, cc.Code),
			err.Code+" != "+optStr(cc.Code))
		c.check("nodeCreate["+cc.Name+"].parentPath", err.ParentPath == cc.ParentPath,
			err.ParentPath)
		c.check("nodeCreate["+cc.Name+"].childSegment",
			err.ChildSegment == cc.ChildSegment, err.ChildSegment)
	}

	// A code with no case is invisible, not weakly covered.
	var uncovered []string
	for _, code := range som.SpecCreationAllCodes {
		if !covered[code] {
			uncovered = append(uncovered, code)
		}
	}
	c.check("nodeCreate.codeCoverage", len(uncovered) == 0, "uncovered: "+join(uncovered))
}

type nodeCreationStep struct {
	Op           string          `json:"op"`
	ParentPath   string          `json:"parentPath"`
	ChildSegment string          `json:"childSegment"`
	ItemID       *string         `json:"itemId"`
	Month        int             `json:"month"`
	Day          int             `json:"day"`
	ExpectPath   string          `json:"expectPath"`
	ExpectID     *string         `json:"expectId"`
	ExpectCode   string          `json:"expectCode"`
	Expect       json.RawMessage `json:"expect"`
}

// testNodeCreationScript replays the stateful creation script against one
// document: the generated ids and item paths of the accepted adds, the code of
// each rejected one, and the final document state — which is what proves a
// rejected add left the tree untouched.
//
// The reference dates every step `DateTime(2026, month, day)`; the two-letter
// day code only reads the month and day, so this port passes those two through
// (the SpecEditor.AddListItem convention) and the year never enters the id.
func testNodeCreationScript(c *checker, t *testing.T, model *som.SpecModel) {
	var steps []nodeCreationStep
	readJSON(t, "node_creation_script.json", &steps)
	doc := freshDoc(t)
	creator := som.NewSpecNodeCreator(model, doc)
	for n, s := range steps {
		tag := "nodeScript[" + itoa(n) + "]." + s.Op
		itemID := ""
		if s.ItemID != nil {
			itemID = *s.ItemID
		}
		switch s.Op {
		case "add":
			path, err := creator.Add(s.ParentPath, s.ChildSegment, itemID, s.Month, s.Day)
			if err != nil {
				c.check(tag+" "+s.ParentPath+"/"+s.ChildSegment, false, err.Error())
				continue
			}
			c.check(tag+" "+s.ParentPath+"/"+s.ChildSegment, path == s.ExpectPath,
				path+" != "+s.ExpectPath)
			got := doc.ItemSectionIDOr(path)
			c.check(tag+" id "+s.ParentPath+"/"+s.ChildSegment, optEq(got, s.ExpectID),
				optName(got)+" != "+optStr(s.ExpectID))
		case "addThrows":
			// The reference dates this step 2026-03-04; the add is rejected before
			// any id is generated, so the date never reaches the generator.
			_, err := creator.Add(s.ParentPath, s.ChildSegment, itemID, 3, 4)
			var cErr *som.SpecCreationError
			if !errors.As(err, &cErr) {
				c.check(tag+" "+s.ParentPath+"/"+s.ChildSegment, false,
					"expected a SpecCreationError")
				continue
			}
			c.check(tag+" "+s.ParentPath+"/"+s.ChildSegment,
				cErr.Code == s.ExpectCode, cErr.Code+" != "+s.ExpectCode)
		case "finalState":
			var want som.DocumentJson
			if err := json.Unmarshal(s.Expect, &want); err != nil {
				t.Fatalf("decode final state: %v", err)
			}
			got := canonJSON(t, doc.ToJSON())
			expected := canonJSON(t, &want)
			c.check(tag, got == expected, got+" != "+expected)
		default:
			c.check(tag+".unknown", false, s.Op)
		}
	}
}

func boolStr(b bool) string {
	if b {
		return "true"
	}
	return "false"
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

func triplesEq(a, b [][3]string) bool {
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
