package tests

// Prefill and Backfill (spec_prefill.go, spec_backfill.go): the Blueprint into
// a new Phase 3 document (BP-8), and the accepted Phase 3 end state back into
// the Blueprint (DP-part-operations-2).
//
// The shared corpus (`prefill_cases.json`, `backfill_cases.json`) pins the
// canonical JSON of each run; this test holds the Go surface it does not: the
// created document joining the set under its default name, the typed results
// (FilledPairs, SkippedPairs, Derived, Findings; Changes, Left), the refusals
// as errors with their codes and places, the revision entry's version bump and
// default author, and the dry run leaving the set's Blueprint alone. A port of
// the Python `spec_prefill_backfill_test.py`.

import (
	"errors"
	"strings"
	"testing"
	"time"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func caseSet(t *testing.T, model *som.SpecModel, table map[string]any, prefix string) *som.SpecDocumentSet {
	return mustSet(model, setDocuments(t, setCaseNamed(t, table, "cases", prefix)["documents"]))
}

func TestPrefill(t *testing.T) {
	table := readSetTable(t, "prefill_cases.json")
	model := setTableModel(t, table)
	s := caseSet(t, model, table, "a new Screens document")
	eq(t, "prefill.missing", s.MissingRoots(), []string{"Screens"})
	r, err := som.Prefill(s, "SCR", som.SpecPrefillOptions{})
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "prefill.name", r.Name, "Screens")
	eq(t, "prefill.created", r.Created, true)
	eq(t, "prefill.joined", s.Get("Screens") == r.Document, true)
	eq(t, "prefill.filled", r.FilledPairs, []string{"ACC"})
	eq(t, "prefill.skipped", r.SkippedPairs, []string{})
	eq(t, "prefill.missingAfter", s.MissingRoots(), []string{})
	again, err := som.Prefill(s, "Screens", som.SpecPrefillOptions{})
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "prefill.again.notCreated", again.Created, false)
	eq(t, "prefill.again.filled", again.FilledPairs, []string{})
	eq(t, "prefill.again.skipped", again.SkippedPairs, []string{"ACC"})
	eq(t, "prefill.again.derived", len(again.Derived.Changes), 0)

	named := caseSet(t, model, table, "a new Detail document")
	r, err = som.Prefill(named, "Detail", som.SpecPrefillOptions{Name: "detail.tomspecs.yaml"})
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "prefill.named", named.Names(), []string{"blueprint", "detail.tomspecs.yaml", "screens"})
	eq(t, "prefill.derived", len(r.Derived.Changes) > 0, true)
	for _, c := range som.SyncReport(named, nil).CountsByCode() {
		if strings.HasPrefix(c.Key, "shared") {
			t.Errorf("prefill.agrees: %s", c.Key)
		}
	}

	var pe *som.SpecPrefillError
	_, err = som.Prefill(caseSet(t, model, table, "a set without the Blueprint"), "DET", som.SpecPrefillOptions{})
	eq(t, "prefill.noBlueprint", errors.As(err, &pe) && pe.Code == "noBlueprint", true)
	_, err = som.Prefill(caseSet(t, model, table, "the Blueprint's own root"), "BLU", som.SpecPrefillOptions{})
	eq(t, "prefill.unknownRoot", errors.As(err, &pe) && pe.Code == "unknownRoot", true)
	eq(t, "prefill.error", strings.HasPrefix(err.Error(), "SpecPrefillError(unknownRoot): "), true)
	_, err = som.Prefill(caseSet(t, model, table, "the Blueprint's own root"), "Nope", som.SpecPrefillOptions{})
	eq(t, "prefill.unknownRoot.name", errors.As(err, &pe) && pe.Code == "unknownRoot", true)
}

func TestBackfill(t *testing.T) {
	prefillTable := readSetTable(t, "prefill_cases.json")
	model := setTableModel(t, prefillTable)
	table := readSetTable(t, "backfill_cases.json")

	s := caseSet(t, model, table, "a differing enum value")
	r, err := som.Backfill(s, som.SpecBackfillOptions{Author: "agent_spec_author", Date: "2026-11-24"})
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "backfill.same", r.Blueprint == s.Blueprint(), true)
	var kinds []string
	for _, c := range r.Changes {
		kinds = append(kinds, c.Kind)
	}
	eq(t, "backfill.kinds", kinds, []string{"value", "revision"})
	eq(t, "backfill.value", []string{r.Changes[0].Pair, r.Changes[0].OldValue, r.Changes[0].NewValue},
		[]string{"REQS", "approved", "done"})
	rev := r.Changes[1].Path
	eq(t, "backfill.revision.version", r.Changes[1].NewValue, "1.1")
	bp := s.Blueprint()
	eq(t, "backfill.revision.author", bp.FormFieldOr(rev+"/content", "author"), "agent_spec_author")
	eq(t, "backfill.revision.summary", bp.FormFieldOr(rev+"/content", "summary"),
		"Backfilled from detail, screens: REQS")
	eq(t, "backfill.clean", som.SyncReport(s, nil).Clean(), true)
	again, err := som.Backfill(s, som.SpecBackfillOptions{})
	eq(t, "backfill.again", err == nil && len(again.Changes) == 0, true)

	// Default author and date.
	d := caseSet(t, model, table, "a value the Blueprint leaves empty")
	r, err = som.Backfill(d, som.SpecBackfillOptions{})
	if err != nil {
		t.Fatal(err)
	}
	rev = ""
	for _, c := range r.Changes {
		if c.Kind == som.SpecBackfillChangeRevision {
			rev = c.Path
		}
	}
	eq(t, "backfill.default.author", d.Blueprint().FormFieldOr(rev+"/content", "author"), "backfill")
	eq(t, "backfill.default.date", d.Blueprint().FormFieldOr(rev+"/content", "date"),
		time.Now().Format("2006-01-02"))

	dry := caseSet(t, model, table, "a dry run writes a copy")
	before := canonJSON(t, generic(t, dry.Blueprint().ToJSON()))
	r, err = som.Backfill(dry, som.SpecBackfillOptions{DryRun: true})
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "backfill.dry.copy", r.Blueprint != dry.Blueprint(), true)
	eq(t, "backfill.dry.unchanged", canonJSON(t, generic(t, dry.Blueprint().ToJSON())), before)
	eq(t, "backfill.dry.changes", len(r.Changes) > 0, true)

	held, err := som.Backfill(caseSet(t, model, table, "a heldHere value"), som.SpecBackfillOptions{})
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "backfill.held.changes", len(held.Changes), 0)
	var reasons []string
	for _, l := range held.Left {
		reasons = append(reasons, l.Reason)
	}
	eq(t, "backfill.held.reason", reasons, []string{"heldHere"})
	eq(t, "backfill.held.code", held.Left[0].Finding.Code, "sharedValueDiffers")

	var be *som.SpecBackfillError
	_, err = som.Backfill(caseSet(t, model, table, "a set holding an inline mark"), som.SpecBackfillOptions{})
	if !errors.As(err, &be) {
		t.Fatalf("backfill.marks: got %v", err)
	}
	eq(t, "backfill.marks", be.Code, "setHasMarks")
	eq(t, "backfill.marks.places", len(be.Places) > 0 && be.Places[0].Document != "", true)
	eq(t, "backfill.marks.error", strings.HasPrefix(be.Error(), "SpecBackfillError(setHasMarks): "), true)
	emptySet, _ := som.NewSpecDocumentSet(model, nil)
	_, err = som.Backfill(emptySet, som.SpecBackfillOptions{})
	eq(t, "backfill.noBlueprint", errors.As(err, &be) && be.Code == "noBlueprint", true)
}

func TestBackfillBumpAndJSON(t *testing.T) {
	eq(t, "bump.empty", som.SpecBackfillBump(""), "1")
	eq(t, "bump.minor", som.SpecBackfillBump("1.2"), "1.3")
	eq(t, "bump.carry", som.SpecBackfillBump("v1.9-rc"), "v1.10-rc")
	eq(t, "bump.none", som.SpecBackfillBump("draft"), "draft.1")
	eq(t, "change.json", generic(t, som.SpecBackfillChange{Kind: "revision", Path: "B/R-1", NewValue: "2"}.ToJSON()),
		map[string]any{"pair": "", "kind": "revision", "path": "B/R-1", "old": "", "new": "2"})
}
