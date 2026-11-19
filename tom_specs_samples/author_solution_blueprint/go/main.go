// TomSpecs sample — author a Solution Blueprint end to end (Go).
//
// The Go port of `../bin/author_solution_blueprint.dart`: the same six steps,
// the same document, the same output (`../expected_output.txt`).
//
// Run (from this folder; see README.md):  go run .
//
// Six steps, in the order a real authoring task takes them:
//
//  1. open a fresh document and a typed root
//  2. author a small but coherent Solution Blueprint
//  3. serialise both renditions — yaml (SOM §12) and markdown (SOM §11)
//  4. round-trip the yaml back through the one-call typed loader and prove
//     the reload is equal to what was written
//  5. validate on the instance tier
//  6. break one rule deliberately and read the diagnostic
//
// This sample is the NARRATIVE. The individual access styles each have their
// own focused example in the facade module (`tom_som_go_v0/examples/`), and
// this does not re-explain them.
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
	somv0 "github.com/al-the-bear/tom_ai_build/tom_som_go_v0"
)

func main() {
	outDir := "build"
	must(os.MkdirAll(outDir, 0o755))

	// -------------------------------------------------------------- step 1
	// A typed root over a fresh, empty document. Constructing the root also
	// runs the instantiation-time model-version check (SOM §4.2): an unstamped
	// document is editable, a document from a newer model is refused.
	doc := som.NewSpecDocument()
	sbp, err := somv0.NewD00SolutionBlueprint(doc, "")
	must(err)

	fmt.Println("1. A typed root over an empty document")
	fmt.Printf("   object model version : %s\n", sbp.ObjectModelVersion())
	fmt.Printf("   root path            : %s\n", sbp.Path())
	fmt.Println()

	// -------------------------------------------------------------- step 2
	// Author. Every write below goes through a NAMED accessor — no string
	// paths — and lands in the same path-keyed store the generic API reads.
	fmt.Println("2. Authoring, printing each section id as it is written")

	sbp.SetContent("Unify three legacy order systems behind one customer record.")
	wrote(sbp.Path(), "the blueprint itself")

	intro := sbp.IntroductionAndScope()
	intro.SetContent("Replace per-region order intake with a single pipeline.")
	wrote(intro.Path(), "introduction and scope")

	landscape := sbp.CurrentLandscape()
	landscape.SetContent("Three systems, no shared customer record, manual reconciliation.")
	wrote(landscape.Path(), "the current landscape")

	// A list section. `Add()` appends an item and returns it typed.
	metrics := landscape.OperationalMetrics()
	metrics.Add().SetContent("Average order turnaround: 4.2 days.")
	metrics.Add().SetContent("Manual reconciliation: about 12 hours a week.")
	wrote(metrics.ListPath(), fmt.Sprintf("%d operational metrics", metrics.Length()))

	fmt.Println()

	// -------------------------------------------------------------- step 3
	// Both renditions of the same document. They are two encodings of one
	// store, not two documents — which is why step 4 can round-trip either.
	//
	// `ToMarkdown` and the validator both need a whole SpecModel: the facade
	// module ships it as `meta/spec_model.meta.json`.
	model := loadModel()

	yaml, err := som.EncodeYaml(doc, somv0.D00SolutionBlueprintMetaTree, model.ModelVersionString())
	must(err)
	markdown, err := doc.ToMarkdown(model, "D00SolutionBlueprint")
	must(err)

	must(os.WriteFile(filepath.Join(outDir, "blueprint.tomspecs.yaml"), []byte(yaml), 0o644))
	must(os.WriteFile(filepath.Join(outDir, "blueprint.tomspecs.md"), []byte(markdown), 0o644))

	fmt.Println("3. Serialised both renditions into build/")
	fmt.Printf("   blueprint.tomspecs.yaml : %d lines  (SOM §12)\n", lines(yaml))
	fmt.Printf("   blueprint.tomspecs.md   : %d lines  (SOM §11)\n", lines(markdown))
	fmt.Println()

	// -------------------------------------------------------------- step 4
	// The one-call typed loader: decode, apply the document's own authoring
	// stamp, and hand back a typed root. Re-encoding the reload and comparing
	// the two strings is the actual proof — comparing field by field would only
	// prove the fields somebody thought to compare.
	reloaded, err := somv0.LoadFileD00SolutionBlueprint(filepath.Join(outDir, "blueprint.tomspecs.yaml"))
	must(err)
	reYaml, err := som.EncodeYaml(reloaded.Doc(), somv0.D00SolutionBlueprintMetaTree, model.ModelVersionString())
	must(err)

	fmt.Println("4. Round-tripped the yaml through D00SolutionBlueprint.loadFile")
	fmt.Printf("   reload equals original  : %t\n", reYaml == yaml)
	fmt.Printf("   a value read back typed : %q\n",
		reloaded.CurrentLandscape().OperationalMetrics().At(0).Content())
	fmt.Println()

	// -------------------------------------------------------------- step 5
	errors := som.ValidateDocument(model, doc)
	fmt.Println("5. Instance-tier validation")
	fmt.Printf("   violations              : %d\n", len(errors))
	fmt.Println()

	// -------------------------------------------------------------- step 6
	// What a violation looks like. Writing to a path the model does not declare
	// is the clearest break to stage: the store accepts it — it is a plain
	// path-keyed map — and the validator is what notices.
	broken, err := som.FromYaml(yaml, somv0.D00SolutionBlueprintMetaTree)
	must(err)
	broken.SetContent("SBP/noSuchSection/content", "not part of the model")

	brokenErrors := som.ValidateDocument(model, broken)
	fmt.Println("6. The same document with one rule deliberately broken")
	fmt.Printf("   violations              : %d\n", len(brokenErrors))
	for _, e := range brokenErrors {
		fmt.Printf("   %s: %s\n", e.Code, e.Path)
		fmt.Printf("     %s\n", e.Message)
	}
	fmt.Println()
	fmt.Println("Done. The two renditions are in build/.")
}

// wrote prints the section id a write landed under. The ids are the document's
// addressing system — the same tokens appear in the yaml keys and in the
// markdown `<!--[ID]-->` comments — so the sample shows them rather than
// describing them.
func wrote(path, what string) {
	fmt.Printf("   %-46s %s\n", path, what)
}

func lines(s string) int {
	return len(strings.Split(strings.TrimRight(s, " \t\r\n"), "\n"))
}

// loadModel reads the whole model the facade module ships, from the checkout:
// `tom_som_go_v0/meta/spec_model.meta.json`, three folders above this one.
func loadModel() *som.SpecModel {
	_, file, _, _ := runtime.Caller(0)
	metaPath := filepath.Join(filepath.Dir(file), "..", "..", "..",
		"tom_som_go_v0", "meta", "spec_model.meta.json")
	data, err := os.ReadFile(metaPath)
	must(err)
	model, err := som.SpecModelFromJSON(data)
	must(err)
	return model
}

func must(err error) {
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
