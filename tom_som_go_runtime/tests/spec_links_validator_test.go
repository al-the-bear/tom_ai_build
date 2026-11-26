// The link checks of one document (spec_links_validator.go,
// `tom_specs_model_rules.md` §9.7), the derived numbers of the instance tier
// (SpecDerivedNumbers) and the typed reading of a value under review
// (SomTypedReading, the headline field of the review operations).
//
// The shared corpus (`link_validation_cases.json`) pins the findings as
// `{path, code}`; this test holds what it does not: the fixes `deriveFields`
// reads beside each finding, the finding order and messages, reading the
// proposal (ReadProposed), the derived numbers, and a headline refusing a
// comment block. Mirrors the Python runtime's spec_links_validator_test.py.
package tests

import (
	"errors"
	"reflect"
	"sort"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// linkCaseDoc loads the state of the link-validation case whose name starts
// with prefix.
func linkCaseDoc(t *testing.T, prefix string) *som.SpecDocument {
	t.Helper()
	var table struct {
		Cases []linkValidationCase `json:"cases"`
	}
	readJSON(t, "link_validation_cases.json", &table)
	for _, cc := range table.Cases {
		if strings.HasPrefix(cc.Name, prefix) {
			state := cc.State
			return docFromState(&state)
		}
	}
	t.Fatalf("no link-validation case %q", prefix)
	return nil
}

func linkFixes(t *testing.T, doc *som.SpecDocument, readProposed bool) []som.SpecLinkFix {
	t.Helper()
	return som.NewSpecLinkValidator(linksModel(t), doc, readProposed).Run().Fixes
}

func TestSpecLinkFixes(t *testing.T) {
	req1 := "BLU/requirements/REQ-ITEM-LST-1"
	model := linksModel(t)

	// A derived value not written yet: no finding, but deriveFields writes it.
	d := linkCaseDoc(t, "a derived value not written yet")
	if errs := som.ValidateLinks(model, d); len(errs) != 0 {
		t.Fatalf("notYet errors %v", errs)
	}
	want := []som.SpecLinkFix{som.SpecLinkFixOfSet(2, req1+"/REQAB", "",
		"Exports use the formats of REQ-IMPORT and never run with REQ-PURGE.")}
	if got := linkFixes(t, d, false); !reflect.DeepEqual(got, want) {
		t.Fatalf("notYet fixes %+v", got)
	}

	// A one-way link not named back: the other end gets the id appended.
	want = []som.SpecLinkFix{som.SpecLinkFixOfAppend(
		"BLU/acceptance/criteria/CRIT-ITEM-LST-1/content", "relatedRequirements", "REQ-EXPORT")}
	if got := linkFixes(t, linkCaseDoc(t, "a one-way link not named back"), false); !reflect.DeepEqual(got, want) {
		t.Fatalf("inverse fixes %+v", got)
	}

	// A symmetric row without its counterpart: a row is added there.
	// The row's values keep the order they are written in (ValueKeys).
	addRow := som.SpecLinkFixOfAddRow(1, "BLU/requirements/REQ-ITEM-LST-3/LNK-ITEM-LST",
		map[string]string{"LNK-REF#ref": "REQ-EXPORT", "content#linkType": "conflict"})
	addRow.ValueKeys = []string{"LNK-REF#ref", "content#linkType"}
	want = []som.SpecLinkFix{addRow}
	if got := linkFixes(t, linkCaseDoc(t, "a symmetric row without its counterpart"), false); !reflect.DeepEqual(got, want) {
		t.Fatalf("symmetric fixes %+v", got)
	}

	// A generated row the text no longer names: removed.
	want = []som.SpecLinkFix{som.SpecLinkFixOfRemoveRow(req1+"/LNK-ITEM-LST-1", false)}
	if got := linkFixes(t, linkCaseDoc(t, "a generated row the text no longer names"), false); !reflect.DeepEqual(got, want) {
		t.Fatalf("stale fixes %+v", got)
	}

	// A copy edited apart from its holder: copied back whole.
	got := linkFixes(t, linkCaseDoc(t, "a copy edited apart from its holder"), false)
	if len(got) != 1 || got[0].Kind != som.SpecLinkFixCopy || got[0].Path != "BLU/criteriaSummary/criteria" {
		t.Fatalf("sameAs fixes %+v", got)
	}
}

func TestSpecLinkFindings(t *testing.T) {
	model := linksModel(t)
	errs := som.ValidateLinks(model, linkCaseDoc(t, "a copy differing from its source"))
	if len(errs) != 1 || errs[0].Code != som.SpecValidationCodeDerivedValueMismatch {
		t.Fatalf("copy findings %v", errs)
	}
	if !strings.Contains(errs[0].Message, "is derived (copy of") {
		t.Fatalf("copy message %q", errs[0].Message)
	}
	// Sorted by path, then by code in declaration order.
	errs = som.ValidateLinks(model, linkCaseDoc(t, "an id named in a generate-mode text"))
	if !sort.SliceIsSorted(errs, func(i, j int) bool { return errs[i].Path < errs[j].Path }) {
		t.Fatalf("not sorted by path: %v", errs)
	}
	// A value holding a pending change is read with the mark rejected and
	// listed once; reading the proposal lists nothing.
	d := linkCaseDoc(t, "a source holding a pending change")
	pending := 0
	for _, e := range som.ValidateLinks(model, d) {
		if e.Code == som.SpecValidationCodeLinkValuePending {
			pending++
		}
	}
	if pending != 1 {
		t.Fatalf("pending findings: %d", pending)
	}
	for _, e := range som.NewSpecLinkValidator(model, d, true).Run().Errors {
		if e.Code == som.SpecValidationCodeLinkValuePending {
			t.Fatalf("the proposal lists a pending value: %v", e)
		}
	}
}

func TestSpecLinkExpandAndIDs(t *testing.T) {
	d := linkCaseDoc(t, "a clean Blueprint")
	got := som.SpecExpandPattern(d, "BLU/requirements/REQ-ITEM-LST-*/REQD")
	want := []string{
		"BLU/requirements/REQ-ITEM-LST-1/REQD",
		"BLU/requirements/REQ-ITEM-LST-2/REQD",
		"BLU/requirements/REQ-ITEM-LST-3/REQD",
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("expand %v", got)
	}
	if got := som.SpecExpandPattern(d, "BLU/requirements"); !reflect.DeepEqual(got, []string{"BLU/requirements"}) {
		t.Fatalf("expand plain %v", got)
	}
	if got := som.SpecLinkIDs(" A, ,B ,"); !reflect.DeepEqual(got, []string{"A", "B"}) {
		t.Fatalf("ids %v", got)
	}
	if som.SpecValidationCodeIndex(som.SpecValidationCodeUnmarkable) != len(som.SpecValidationAllCodes)-1 ||
		som.SpecValidationCodeIndex("nope") != -1 {
		t.Fatal("SpecValidationCodeIndex")
	}
}

func TestSpecDerivedNumbers(t *testing.T) {
	model := linksModel(t)
	base := "BLU/requirements"
	d := som.NewSpecDocument()
	for _, status := range []string{"approved", "done", "draft"} {
		item := d.AddListItem(base + "/REQ-ITEM-LST")
		d.SetFormField(item+"/content", "status", status)
	}
	d.SetFormField(base+"/REQS-SUM", "total", "1")
	numbers := func(readProposed bool) map[string]string {
		out := map[string]string{}
		for _, n := range som.SpecDerivedNumbers(model, d, readProposed) {
			out[n.Path+"#"+n.Field] = n.Value
		}
		return out
	}
	got := numbers(false)
	if got[base+"/REQS-SUM#total"] != "3" || got[base+"/REQS-SUM#settled"] != "2" {
		t.Fatalf("counts %v", got)
	}
	// A count reading a pending mark: rejected by default, accepted with
	// readProposed.
	d.SetFormField(base+"/REQ-ITEM-LST-3/content", "status", "{~~draft~>done~~}")
	if got := numbers(false)[base+"/REQS-SUM#settled"]; got != "2" {
		t.Fatalf("rejected count %q", got)
	}
	if got := numbers(true)[base+"/REQS-SUM#settled"]; got != "3" {
		t.Fatalf("proposed count %q", got)
	}
}

func TestSomTypedReading(t *testing.T) {
	cases := []struct{ name, got, want string }{
		{"plain", som.SomTypedReading("30"), "30"},
		{"none", som.SomTypedReading(""), ""},
		{"change", som.SomTypedReading("{~~ 30 ~> 15 ~~}"), "30"},
		{"insertion", som.SomTypedReading("{++15++}"), ""},
	}
	for _, c := range cases {
		if c.got != c.want {
			t.Errorf("%s: %q, want %q", c.name, c.got, c.want)
		}
	}
	if n, ok := som.SomParseInt("{~~30~>15~~}"); !ok || n != 30 {
		t.Errorf("int marked: %d %v", n, ok)
	}
	if b, ok := som.SomParseBool("{~~true~>false~~}"); !ok || !b {
		t.Errorf("bool marked: %v %v", b, ok)
	}
	if e, ok := som.SomParseEnumName("{~~high~>low~~}", []string{"low", "high"}); !ok || e != "high" {
		t.Errorf("enum marked: %q %v", e, ok)
	}
	if !som.SomTypedTextReadable("int", "{~~30~>lots~~}") {
		t.Error("a marked int is read by its new value")
	}
	if !som.SomIsTypedField("String", []string{"a"}) || !som.SomIsTypedField("int?", nil) ||
		som.SomIsTypedField("String", nil) {
		t.Error("SomIsTypedField")
	}
}

func TestReviewHeadlineField(t *testing.T) {
	d := som.NewSpecDocument()
	d.SetHeadline("BLU/requirements", "Requirements {++and links++}")
	api := som.NewSpecReviewAnnotationsWithClock(d, "", func() string { return "2026-11-07T14:05+01:00" })
	marks := api.ListMarks("")
	if len(marks) != 1 || marks[0].Path != "BLU/requirements" || marks[0].Field == nil ||
		*marks[0].Field != som.KSpecHeadlineField {
		t.Fatalf("headline marks %+v", marks)
	}
	_, err := api.InsertComment("BLU/requirements", som.KSpecHeadlineField, 0, "x", "", "", "")
	var ae *som.SpecReviewAnnotationError
	if !errors.As(err, &ae) {
		t.Fatalf("a headline takes a comment block: %v", err)
	}
	api.AcceptAllMarks("")
	if got := d.HeadlineOr("BLU/requirements"); got != "Requirements and links" {
		t.Fatalf("accepted headline %q", got)
	}
}
