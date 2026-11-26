package tests

// DeriveFields (spec_derive_fields.go, `tom_specs_model_rules.md` §9.7): the
// derived places of one document, written plain or as marks.
//
// The shared corpus (`derive_cases.json`) pins the canonical JSON of each run;
// this test holds the Go surface it does not: the typed changes
// (SpecDeriveChange with its step, kind, field and values), the dry run
// answering a copy and leaving the given document alone, the unresolved
// entries as SpecValidationError with their code, and the canonical JSON of a
// change without a field. A port of the Python `spec_derive_fields_test.py`.

import (
	"sort"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func deriveDoc(t *testing.T, table map[string]any, prefix string) *som.SpecDocument {
	return stateDocument(t, setCaseNamed(t, table, "cases", prefix)["state"])
}

func TestDeriveFieldsPlainSteps(t *testing.T) {
	table := readSetTable(t, "derive_cases.json")
	model := setTableModel(t, table)
	doc := deriveDoc(t, table, "step 1: a missing symmetric row")
	r := som.DeriveFields(model, doc, som.SpecDeriveOptions{})
	eq(t, "plain.same", r.Document == doc, true)
	first := r.Changes[0]
	eq(t, "plain.rowAdded", []any{first.Step, first.Kind, first.Field}, []any{1, "rowAdded", ""})
	stepSet := map[int]bool{}
	for _, c := range r.Changes {
		stepSet[c.Step] = true
	}
	var steps []int
	for s := range stepSet {
		steps = append(steps, s)
	}
	sort.Ints(steps)
	eq(t, "plain.steps", steps, []int{1, 2})
	last := r.Changes[len(r.Changes)-1]
	eq(t, "plain.value", []string{last.Kind, last.Field, last.OldValue, last.NewValue},
		[]string{"value", "conflictsWith", "", "REQ-EXPORT"})
	eq(t, "plain.unresolved", len(r.Unresolved), 0)
	eq(t, "plain.clean", len(som.ValidateLinks(model, doc)), 0)
	eq(t, "plain.again", len(som.DeriveFields(model, doc, som.SpecDeriveOptions{}).Changes), 0)
}

func TestDeriveFieldsDryRun(t *testing.T) {
	table := readSetTable(t, "derive_cases.json")
	model := setTableModel(t, table)
	doc := deriveDoc(t, table, "a dry run writes nothing")
	before := generic(t, doc.ToJSON())
	r := som.DeriveFields(model, doc, som.SpecDeriveOptions{DryRun: true})
	eq(t, "dry.copy", r.Document != doc, true)
	eq(t, "dry.unchanged", generic(t, doc.ToJSON()), before)
	eq(t, "dry.changes", len(r.Changes) > 0, true)
	written := generic(t, r.Document.ToJSON())
	eq(t, "dry.written", canonJSON(t, written) != canonJSON(t, before), true)
}

func TestDeriveFieldsMarked(t *testing.T) {
	table := readSetTable(t, "derive_cases.json")
	model := setTableModel(t, table)
	doc := deriveDoc(t, table, "under review: every derived value")
	at := "2026-11-24T10:00+01:00"
	options := som.SpecDeriveOptions{Marked: true, Author: "agent_spec_author", At: at}
	r := som.DeriveFields(model, doc, options)
	values := 0
	for _, c := range r.Changes {
		if c.Kind != som.SpecDeriveChangeValue {
			continue
		}
		values++
		if !strings.Contains(c.NewValue, "{") || !strings.Contains(c.NewValue, "@agent_spec_author "+at) {
			t.Errorf("marked.marks: %q", c.NewValue)
		}
	}
	eq(t, "marked.values", values > 0, true)
	eq(t, "marked.again", len(som.DeriveFields(model, doc, options).Changes), 0)
}

func TestDeriveFieldsUnresolved(t *testing.T) {
	table := readSetTable(t, "derive_cases.json")
	model := setTableModel(t, table)
	miss := som.DeriveFields(model, deriveDoc(t, table, "a lookup without its row"), som.SpecDeriveOptions{})
	found := false
	for _, e := range miss.Unresolved {
		found = found || e.Code == som.SpecValidationCodeDerivedLookupMiss
	}
	eq(t, "lookupMiss", found, true)
	fenced := som.DeriveFields(model, deriveDoc(t, table, "under review: a change inside fenced code"),
		som.SpecDeriveOptions{Marked: true, At: "2026-11-24T10:00+01:00"})
	var codes []string
	for _, e := range fenced.Unresolved {
		codes = append(codes, e.Code)
	}
	eq(t, "unmarkable", codes, []string{som.SpecValidationCodeUnmarkable})
	unresolved := generic(t, fenced.ToJSON()).(map[string]any)["unresolved"].([]any)
	eq(t, "unmarkable.json", unresolved[0].(map[string]any)["code"], "unmarkable")
}

func TestDeriveChangeJSON(t *testing.T) {
	eq(t, "json.noField", generic(t, som.SpecDeriveChange{Step: 1, Kind: "rowRemoved", Path: "A/b-1"}.ToJSON()),
		map[string]any{"step": float64(1), "kind": "rowRemoved", "path": "A/b-1", "old": "", "new": ""})
	eq(t, "json.field", generic(t, som.SpecDeriveChange{
		Step: 3, Kind: "value", Path: "A/c", Field: "n", OldValue: "1", NewValue: "2",
	}.ToJSON()),
		map[string]any{"step": float64(3), "kind": "value", "path": "A/c", "field": "n", "old": "1", "new": "2"})
}
