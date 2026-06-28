// Behavioural test for the **actually-committed** generated Go typed model.
//
// Unlike the emitter's golden test (which compiles the small emitter fixture),
// this suite exercises the real, full `tom_som_go_v0` module (3000+ types)
// against the generic `tom_som_go_runtime` and proves the typed facade is a
// faithful editing surface over the shared document (spec §3):
//
//   - the `ProjectDefinition` root is anchored at the `PD` segment;
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
	pd, err := NewProjectDefinition(doc, "")
	if err != nil {
		t.Fatalf("NewProjectDefinition: %v", err)
	}

	if pd.Path() != "PD" {
		t.Errorf("root segment = %q, want PD", pd.Path())
	}

	// Typed write → generic read.
	pd.SetContent("A clear vision")
	if got := doc.ContentOr("PD/content"); got != "A clear vision" {
		t.Errorf("content typed->generic = %q, want %q", got, "A clear vision")
	}

	// Generic write → typed read.
	doc.SetContent("PD/content", "Revised vision")
	if got := pd.Content(); got != "Revised vision" {
		t.Errorf("content generic->typed = %q, want %q", got, "Revised vision")
	}

	// Unset leaf reads as empty string.
	fresh, _ := NewProjectDefinition(som.NewSpecDocument(), "")
	if got := fresh.Content(); got != "" {
		t.Errorf("unset content = %q, want empty", got)
	}

	// Nested complex section path derivation (camelCase accessor preserved as
	// the stored segment).
	csa := pd.CurrentStateAnalysis()
	if csa.Path() != "PD/currentStateAnalysis" {
		t.Errorf("nested path = %q, want PD/currentStateAnalysis", csa.Path())
	}

	// A generic value under the nested typed node is addressable via the
	// expected literal path (typed path == generic path).
	doc.SetContent(csa.Path()+"/probe", "x")
	if doc.ContentOr("PD/currentStateAnalysis/probe") != "x" {
		t.Errorf("nested typed-path != generic path")
	}
}

func TestTypedList(t *testing.T) {
	doc := som.NewSpecDocument()
	pd, _ := NewProjectDefinition(doc, "")
	metrics := pd.CurrentStateAnalysis().OperationalMetrics()

	metrics.Add().SetContent("Average order turnaround: 4.2 days.")
	metrics.Add().SetContent("Manual reconciliation: ~12 hours / week.")

	if metrics.Length() != 2 {
		t.Fatalf("list length = %d, want 2", metrics.Length())
	}
	if got := metrics.At(0).Content(); got != "Average order turnaround: 4.2 days." {
		t.Errorf("metric[0] = %q", got)
	}
	// Typed list writes land in the generic list store under the same path.
	listPath := "PD/currentStateAnalysis/CUOPME-OPER-LST"
	if doc.ListItemCount(listPath) != 2 {
		t.Errorf("generic list count = %d, want 2", doc.ListItemCount(listPath))
	}
}

func TestModelVersion(t *testing.T) {
	if ProjectDefinitionModelVersion != "0.0" {
		t.Errorf("ProjectDefinitionModelVersion = %q, want 0.0",
			ProjectDefinitionModelVersion)
	}
	pd, _ := NewProjectDefinition(som.NewSpecDocument(), "")
	if pd.ObjectModelVersion() != "0.0" {
		t.Errorf("ObjectModelVersion() = %q, want 0.0", pd.ObjectModelVersion())
	}
}

func TestVersionCheck(t *testing.T) {
	// New / equal-stamp document → accepted.
	if _, err := NewProjectDefinition(som.NewSpecDocument(), ""); err != nil {
		t.Errorf("empty stamp rejected: %v", err)
	}
	if _, err := NewProjectDefinition(som.NewSpecDocument(), "0.0"); err != nil {
		t.Errorf("equal stamp rejected: %v", err)
	}

	// Newer minor → rejected with a SomVersionError.
	_, err := NewProjectDefinition(som.NewSpecDocument(), "0.1")
	var verr *som.SomVersionError
	if err == nil || !errors.As(err, &verr) {
		t.Errorf("newer-minor stamp: got %v, want *SomVersionError", err)
	}

	// Different major → rejected with a SomVersionError.
	_, err = NewProjectDefinition(som.NewSpecDocument(), "1.0")
	if err == nil || !errors.As(err, &verr) {
		t.Errorf("cross-major stamp: got %v, want *SomVersionError", err)
	}
}
