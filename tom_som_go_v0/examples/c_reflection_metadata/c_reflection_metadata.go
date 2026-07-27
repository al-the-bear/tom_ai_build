// Sample (c) — REFLECTION / meta-information access (som_multiplatform_spec_model.md §6).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the module, meta/, schemas/ and go.mod).
//
// Demonstrates the value-free "reflection" surface: load the exported meta-data
// (`meta/spec_model.meta.json`, the lossless class graph) into a `SpecModel`
// and query its shape with `SpecReflection` — enumerate roots and fields, and
// resolve a concrete document *path* to the model node it lands on. No document
// values are involved; this answers "what CAN the model hold?", not "what does
// a given document hold?".
//
// Run from the module root:  go run ./examples/c_reflection_metadata
//
// The generic runtime is reached through the fixed import path
// `tom_som_go_runtime` (wired by the relative `replace` in this module's
// go.mod), so the sample is portable across checkouts.
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// projectRoot returns the module root (which holds `meta/`). The source file
// lives at `<root>/examples/c_reflection_metadata/c_reflection_metadata.go`, so
// the root is two directories up — making the sample runnable from any cwd.
func projectRoot() string {
	_, file, _, ok := runtime.Caller(0)
	if !ok {
		return "."
	}
	return filepath.Dir(filepath.Dir(filepath.Dir(file)))
}

func main() {
	metaPath := filepath.Join(projectRoot(), "meta", "spec_model.meta.json")
	data, err := os.ReadFile(metaPath)
	if err != nil {
		panic(err)
	}
	model, err := som.SpecModelFromJSON(data)
	if err != nil {
		panic(err)
	}
	reflection := som.NewSpecReflection(model)

	label := model.ModelVersionLabel
	if label == "" {
		label = "unstamped"
	}
	fmt.Printf("Model version: %d (%s)\n", model.ModelVersion, label)
	roots := reflection.Roots()
	fmt.Printf("Roots: %d, classes: %d\n\n", len(roots), len(reflection.Classes()))

	// Enumerate the document roots by their addressable segment.
	fmt.Println("Document roots:")
	for _, root := range roots {
		fmt.Printf("  %-4s %s\n", reflection.RootSegment(root), root.Title)
	}

	// Inspect the fields of the D00SolutionBlueprint root class.
	pdRoot := reflection.RootForSegment("SBP")
	if pdRoot == nil {
		fmt.Println("SBP root not found")
		os.Exit(1)
	}
	pdFields := reflection.FieldsOf(pdRoot.Type)
	fmt.Printf("\nFirst fields of %s (%d total):\n", pdRoot.Type, len(pdFields))
	for i, field := range pdFields {
		if i >= 6 {
			break
		}
		extra := ""
		if field.Type != "" {
			extra += "  type=" + field.Type
		}
		if field.ElementType != "" {
			extra += "  elem=" + field.ElementType
		}
		fmt.Printf("  %-24s kind=%s%s\n", field.Name, field.Kind, extra)
	}

	// Resolve concrete document paths to model nodes (value-free).
	fmt.Println("\nPath resolution:")
	for _, p := range []string{
		"SBP",
		"SBP/content",
		"SBP/currentLandscape",
		"SBP/currentLandscape/CUOPME-OPER-LST",
	} {
		res := reflection.Resolve(p)
		if res == nil {
			fmt.Printf("  %s  ->  (unresolved)\n", p)
			continue
		}
		cls := ""
		if res.TargetClass != nil {
			cls = "  class=" + res.TargetClass.Name
		}
		fmt.Printf("  %-40s -> kind=%s%s  value_leaf=%t\n",
			p, res.Kind, cls, res.IsValueLeaf())
	}
}
