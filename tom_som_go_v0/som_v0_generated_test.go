// Behavioural test for the **actually-committed** generated Go typed model.
//
// Unlike the emitter's golden test (which compiles the small emitter fixture),
// this suite exercises the real, full `tom_som_go_v0` module (3000+ types)
// against the generic `tom_som_go_runtime` and proves the typed facade is a
// faithful editing surface over the shared document (spec §3):
//
//   - the `D00SolutionBlueprint` root is anchored at the `PD` segment;
//   - a content leaf round-trips typed → generic and generic → typed;
//   - a nested complex section derives its path under the root;
//   - the typed `SomList` collection maps onto the generic list store;
//   - the generated model-version accessor / constant return `0.0`;
//   - the instantiation-time version check (§2.2) accepts an editable stamp and
//     rejects a newer-minor / cross-major stamp with a *som.SomVersionError.
//
// Run with `go test ./...`. The runtime resolves through the `replace`
// directive in this module's go.mod, so the test is portable across checkouts.
package somv0

import (
	"errors"
	"testing"

	som "tom_som_go_runtime"
)

func TestRootAndParity(t *testing.T) {
	doc := som.NewSpecDocument()
	pd, err := NewD00SolutionBlueprint(doc, "")
	if err != nil {
		t.Fatalf("NewD00SolutionBlueprint: %v", err)
	}

	if pd.Path() != "SBP" {
		t.Errorf("root segment = %q, want PD", pd.Path())
	}

	// Typed write → generic read.
	pd.SetContent("A clear vision")
	if got := doc.ContentOr("SBP/content"); got != "A clear vision" {
		t.Errorf("content typed->generic = %q, want %q", got, "A clear vision")
	}

	// Generic write → typed read.
	doc.SetContent("SBP/content", "Revised vision")
	if got := pd.Content(); got != "Revised vision" {
		t.Errorf("content generic->typed = %q, want %q", got, "Revised vision")
	}

	// Unset leaf reads as empty string.
	fresh, _ := NewD00SolutionBlueprint(som.NewSpecDocument(), "")
	if got := fresh.Content(); got != "" {
		t.Errorf("unset content = %q, want empty", got)
	}

	// Nested complex section path derivation (camelCase accessor preserved as
	// the stored segment).
	csa := pd.CurrentLandscape()
	if csa.Path() != "SBP/currentLandscape" {
		t.Errorf("nested path = %q, want SBP/currentLandscape", csa.Path())
	}

	// A generic value under the nested typed node is addressable via the
	// expected literal path (typed path == generic path).
	doc.SetContent(csa.Path()+"/probe", "x")
	if doc.ContentOr("SBP/currentLandscape/probe") != "x" {
		t.Errorf("nested typed-path != generic path")
	}
}

func TestTypedList(t *testing.T) {
	doc := som.NewSpecDocument()
	pd, _ := NewD00SolutionBlueprint(doc, "")
	metrics := pd.CurrentLandscape().OperationalMetrics()

	metrics.Add().SetContent("Average order turnaround: 4.2 days.")
	metrics.Add().SetContent("Manual reconciliation: ~12 hours / week.")

	if metrics.Length() != 2 {
		t.Fatalf("list length = %d, want 2", metrics.Length())
	}
	if got := metrics.At(0).Content(); got != "Average order turnaround: 4.2 days." {
		t.Errorf("metric[0] = %q", got)
	}
	// Typed list writes land in the generic list store under the same path.
	listPath := "SBP/currentLandscape/CUOPME-OPER-LST"
	if doc.ListItemCount(listPath) != 2 {
		t.Errorf("generic list count = %d, want 2", doc.ListItemCount(listPath))
	}
}

// freshMetrics returns a new operationalMetrics list — a @SectionIdPattern list
// (CUOPME-OPER-xxx) — over an empty document, for the section-id scenarios.
func freshMetrics(t *testing.T) *som.SomList[*CurrentOperationalMetric] {
	t.Helper()
	pd, _ := NewD00SolutionBlueprint(som.NewSpecDocument(), "")
	return pd.CurrentLandscape().OperationalMetrics()
}

// TestSectionIds proves the generated typed facade drives section-id generation
// (AA1 criteria 3–6) end-to-end: deterministic ids via AddOn, override with
// uniqueness validation, and the delete/renumber rules. March 5 → the two-letter
// day code "CE" (C = month 3, E = day 5).
func TestSectionIds(t *testing.T) {
	const mar, day = 3, 5

	// Generation: consecutive same-day items number CE1, CE2 (criteria 3–4).
	metrics := freshMetrics(t)
	if id := metrics.AddOn(mar, day).SectionID(); id != "CUOPME-OPER-CE1" {
		t.Errorf("gen first = %q, want CUOPME-OPER-CE1", id)
	}
	if id := metrics.AddOn(mar, day).SectionID(); id != "CUOPME-OPER-CE2" {
		t.Errorf("gen second = %q, want CUOPME-OPER-CE2", id)
	}

	// Override to an arbitrary suffix, then a duplicate override raises a
	// *SpecSectionIDCollision (criterion 5).
	metrics = freshMetrics(t)
	metrics.AddOn(mar, day) // CE1
	second := metrics.AddOn(mar, day)
	if err := second.SetSectionID("CUOPME-OPER-ZZ9"); err != nil {
		t.Fatalf("override: unexpected error %v", err)
	}
	if !contains(metrics.SectionIDs(), "CUOPME-OPER-ZZ9") {
		t.Errorf("override not applied: %v", metrics.SectionIDs())
	}
	var coll *som.SpecSectionIDCollision
	if err := metrics.At(0).SetSectionID("CUOPME-OPER-ZZ9"); !errors.As(err, &coll) {
		t.Errorf("override collision: got %v, want *SpecSectionIDCollision", err)
	}
	// An explicit add with a duplicate id raises the same collision.
	if _, err := metrics.AddWithID("CUOPME-OPER-ZZ9"); !errors.As(err, &coll) {
		t.Errorf("add collision: got %v, want *SpecSectionIDCollision", err)
	}

	// Delete a middle item: the remaining ids never renumber, and a new same-day
	// item takes the next free number (criterion 6).
	metrics = freshMetrics(t)
	metrics.AddOn(mar, day) // CE1
	metrics.AddOn(mar, day) // CE2
	metrics.AddOn(mar, day) // CE3
	metrics.RemoveAt(1)     // drop CE2
	if got := metrics.SectionIDs(); !sliceEqual(got, []string{"CUOPME-OPER-CE1", "CUOPME-OPER-CE3"}) {
		t.Errorf("delete-middle ids = %v", got)
	}
	if id := metrics.AddOn(mar, day).SectionID(); id != "CUOPME-OPER-CE4" {
		t.Errorf("delete-middle next = %q, want CUOPME-OPER-CE4", id)
	}

	// Delete the last item: a new same-day item reuses the just-freed number
	// (criterion 6).
	metrics = freshMetrics(t)
	metrics.AddOn(mar, day) // CE1
	metrics.AddOn(mar, day) // CE2
	metrics.AddOn(mar, day) // CE3
	metrics.RemoveAt(2)     // drop CE3 (the max)
	if id := metrics.AddOn(mar, day).SectionID(); id != "CUOPME-OPER-CE3" {
		t.Errorf("delete-last reuse = %q, want CUOPME-OPER-CE3", id)
	}
}

func contains(xs []string, want string) bool {
	for _, x := range xs {
		if x == want {
			return true
		}
	}
	return false
}

func sliceEqual(a, b []string) bool {
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

func TestModelVersion(t *testing.T) {
	if D00SolutionBlueprintModelVersion != "1.0" {
		t.Errorf("D00SolutionBlueprintModelVersion = %q, want 1.0",
			D00SolutionBlueprintModelVersion)
	}
	pd, _ := NewD00SolutionBlueprint(som.NewSpecDocument(), "")
	if pd.ObjectModelVersion() != "1.0" {
		t.Errorf("ObjectModelVersion() = %q, want 1.0", pd.ObjectModelVersion())
	}
}

func TestVersionCheck(t *testing.T) {
	// New / equal-stamp document → accepted.
	if _, err := NewD00SolutionBlueprint(som.NewSpecDocument(), ""); err != nil {
		t.Errorf("empty stamp rejected: %v", err)
	}
	if _, err := NewD00SolutionBlueprint(som.NewSpecDocument(), "1.0"); err != nil {
		t.Errorf("equal stamp rejected: %v", err)
	}

	// Newer minor → rejected with a SomVersionError.
	_, err := NewD00SolutionBlueprint(som.NewSpecDocument(), "1.1")
	var verr *som.SomVersionError
	if err == nil || !errors.As(err, &verr) {
		t.Errorf("newer-minor stamp: got %v, want *SomVersionError", err)
	}

	// Different major → rejected with a SomVersionError.
	_, err = NewD00SolutionBlueprint(som.NewSpecDocument(), "2.0")
	if err == nil || !errors.As(err, &verr) {
		t.Errorf("cross-major stamp: got %v, want *SomVersionError", err)
	}
}
