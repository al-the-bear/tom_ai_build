// Sample (b) — GENERIC in-memory document access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the module, meta/, schemas/ and go.mod).
//
// Demonstrates editing the *same* document shape as sample (a) using ONLY the
// generic `tom_som_go_runtime` — string paths, no generated typed classes.
// This is the language-independent core: a sparse, path-keyed store plus the
// list and serialization helpers. Anything the typed facade can express is
// expressible here; the typed facade just makes it type-safe and discoverable.
//
// Run from the module root:  go run ./examples/b_generic_document
//
// The generic runtime is reached through the fixed import path
// `tom_som_go_runtime` (wired by the relative `replace` in this module's
// go.mod), so the sample is portable across checkouts.
package main

import (
	"encoding/json"
	"fmt"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

func main() {
	doc := som.NewSpecDocument()

	// Content leaves are addressed by their full path from the root segment.
	doc.SetContent("SBP/content",
		"A platform that unifies our fragmented order systems.")
	doc.SetContent("SBP/currentLandscape/content",
		"Three legacy systems with no shared customer record.")

	// A list: append items (each call returns the new item's path), then set a
	// content leaf under each. The list path mirrors the typed facade's
	// `operationalMetrics` accessor.
	listPath := "SBP/currentLandscape/CUOPME-OPER-LST"
	item0 := doc.AddListItem(listPath)
	doc.SetContent(item0+"/content", "Average order turnaround: 4.2 days.")
	item1 := doc.AddListItem(listPath)
	doc.SetContent(item1+"/content", "Manual reconciliation: ~12 hours / week.")

	// Read back generically.
	fmt.Printf("SBP/content = %s\n", doc.ContentOr("SBP/content"))
	fmt.Printf("list item count = %d\n", doc.ListItemCount(listPath))
	for _, itemPath := range doc.ListItems(listPath) {
		fmt.Printf("  %s/content = %s\n", itemPath, doc.ContentOr(itemPath+"/content"))
	}

	// The whole document serializes losslessly to JSON. Go's encoding/json
	// emits map keys in sorted order, so the dump is deterministic regardless
	// of insertion order (matching the Dart/Python/TS counterparts).
	fmt.Println("\nDocument JSON:")
	out, err := json.MarshalIndent(doc.ToJSON(), "", "  ")
	if err != nil {
		panic(err)
	}
	fmt.Println(string(out))

	// … and to the canonical YAML wire format (stamped with the model version).
	// Hierarchical v2 encoding walks the root's generated metadata tree.
	fmt.Println("\nDocument YAML:")
	yaml, err := som.EncodeYaml(doc, somv0.D00SolutionBlueprintMetaTree, "1.0")
	if err != nil {
		panic(err)
	}
	fmt.Print(yaml)
}
