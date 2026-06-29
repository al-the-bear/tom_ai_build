// Sample (a) — TYPED object-model access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the module, meta/, schemas/ and go.mod).
//
// Demonstrates editing a TomSpecs document through the generated *typed* facade
// `tom_som_go_v0`: named accessors, nested-section navigation, and the typed
// `SomList` collection. The typed facade is a thin editing surface over a
// generic `SpecDocument` — every typed write lands in the same path-keyed store
// the generic API (sample b) reads, which the closing lines prove.
//
// Run from the module root:  go run ./examples/a_typed_access
//
// The generic runtime is reached through the fixed import path
// `tom_som_go_runtime` (wired by the relative `replace` in this module's
// go.mod), so the sample is portable across checkouts.
package main

import (
	"fmt"

	som "tom_som_go_runtime"
	somv0 "tom_som_go_v0"
)

func main() {
	// A typed root over a fresh, empty document. The constructor also runs the
	// §2.2 instantiation-time version check (an empty stamp is editable).
	doc := som.NewSpecDocument()
	pd, err := somv0.NewD00SolutionBlueprint(doc, "")
	if err != nil {
		panic(err)
	}

	fmt.Printf("Model version of this typed facade: %s\n", pd.ObjectModelVersion())
	fmt.Printf("Root path: %s\n\n", pd.Path())

	// 1) A content leaf directly on the root.
	pd.SetContent("A platform that unifies our fragmented order systems.")

	// 2) Navigate into a nested complex section and edit its own content leaf.
	csa := pd.CurrentLandscape()
	csa.SetContent("Three legacy systems with no shared customer record.")

	// 3) The typed collection API: append two list items and edit each.
	metrics := csa.OperationalMetrics()
	metrics.Add().SetContent("Average order turnaround: 4.2 days.")
	metrics.Add().SetContent("Manual reconciliation: ~12 hours / week.")

	// Read everything back through the typed accessors.
	fmt.Printf("SBP.content              = %s\n", pd.Content())
	fmt.Printf("SBP.currentLandscape = %s\n", csa.Content())
	fmt.Printf("operationalMetrics.length = %d\n", metrics.Length())
	for i := 0; i < metrics.Length(); i++ {
		fmt.Printf("  metric[%d] = %s\n", i, metrics.At(i).Content())
	}

	// The typed path is the generic path: the same data is addressable through
	// the generic document API (this is exactly what sample (b) uses).
	fmt.Printf("\nSame value via the generic path (doc.ContentOr(%q/content)):\n",
		csa.Path())
	fmt.Printf("  %s\n", doc.ContentOr(csa.Path()+"/content"))
}
