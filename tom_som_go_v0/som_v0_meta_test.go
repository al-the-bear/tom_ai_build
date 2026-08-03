// Agreement suite for the generated Go metadata module
// (`tom_som_go_v0_meta.go`, SOM §7.2/§8) — the Go port of the Dart facade's
// `test/generated_meta_test.dart` (and the TypeScript `som_v0_meta_test.ts`).
// Two guarantees over the *real* committed model:
//
//  1. EXHAUSTIVE TREE AGREEMENT — for every one of the document roots the
//     generated static SomMetaTree is field-for-field identical (via
//     som.SomMetaNodeDiff) to the tree som.BuildSomMetaTree derives from the
//     committed `meta/spec_model.meta.json` at runtime. Since the emitter
//     writes the dot-notation / ID-tree accessor paths from the same node
//     walk, this also anchors every Path the accessors can produce.
//  2. SURFACE AGREEMENT — the dot-notation entry points, the ID-tree entry
//     points, and the dynamic ByPath lookups all resolve to the *same* node
//     instances for representative positions (root, nested section, content
//     leaf, list, list element, hoisted id).
//
// The root set comes from the generated SomMetaRoots registry, not a hand-list:
// adding a document root cannot leave this suite behind. That does not make the
// coverage check circular — `meta/spec_model.meta.json` is written by the model
// JSON exporter, a different code path from the meta emitter, so an emitter
// that drops a root still shows up as a count mismatch.
//
// Run with `go test ./...`. The runtime resolves through the `replace`
// directive in this module's go.mod, so the test is portable across checkouts.
package somv0

import (
	"os"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// generatedTrees is every generated per-root static tree, keyed by root type —
// read from the generated SomMetaRoots registry rather than hand-listed, so a
// new document root reaches this suite by regeneration instead of by
// recollection.
var generatedTrees = func() map[string]*som.SomMetaTree {
	m := make(map[string]*som.SomMetaTree, len(SomMetaRoots))
	for k, e := range SomMetaRoots {
		m[k] = e.Tree
	}
	return m
}()

// loadModel parses the committed language-agnostic meta-data next to the
// generated module (the same file the bridge builds trees from at runtime).
func loadModel(t *testing.T) *som.SpecModel {
	t.Helper()
	raw, err := os.ReadFile("meta/spec_model.meta.json")
	if err != nil {
		t.Fatalf("read meta/spec_model.meta.json: %v", err)
	}
	model, err := som.SpecModelFromJSON(raw)
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	return model
}

// mustMeta resolves a ref's metadata node, failing the test on error.
func mustMeta(t *testing.T, name string, ref interface {
	Meta() (*som.SomMetaNode, error)
}) *som.SomMetaNode {
	t.Helper()
	node, err := ref.Meta()
	if err != nil {
		t.Fatalf("%s.Meta(): %v", name, err)
	}
	return node
}

// TestGeneratedTreesAgreeWithBridge proves exhaustive tree agreement: the
// generated static trees cover exactly the model's roots, and each is
// field-for-field identical to the bridge-built tree.
func TestGeneratedTreesAgreeWithBridge(t *testing.T) {
	model := loadModel(t)

	if len(model.Roots) != len(generatedTrees) {
		t.Errorf("model has %d roots, generated map has %d",
			len(model.Roots), len(generatedTrees))
	}
	for _, root := range model.Roots {
		if _, ok := generatedTrees[root.Type]; !ok {
			t.Errorf("model root %q has no generated tree", root.Type)
		}
	}

	for rootType, tree := range generatedTrees {
		bridge, err := som.BuildSomMetaTree(model, rootType)
		if err != nil {
			t.Fatalf("BuildSomMetaTree(%s): %v", rootType, err)
		}
		if diff := som.SomMetaNodeDiff(tree.Root, bridge.Root); diff != "" {
			t.Errorf("generated tree for %s disagrees with bridge:\n%s",
				rootType, diff)
		}
	}
}

// TestRegistryEntriesAreSelfConsistent proves each registry entry describes
// itself consistently: the map key is the entry's own Type, both access roots
// sit at the declared Segment, and both resolve to the entry's own tree root.
func TestRegistryEntriesAreSelfConsistent(t *testing.T) {
	for key, e := range SomMetaRoots {
		if e.Type != key {
			t.Errorf("registry key %q != entry.Type %q", key, e.Type)
		}
		if e.Nav.Path != e.Segment {
			t.Errorf("%s: Nav.Path = %q, want segment %q", key, e.Nav.Path, e.Segment)
		}
		if e.ID.Path != e.Segment {
			t.Errorf("%s: ID.Path = %q, want segment %q", key, e.ID.Path, e.Segment)
		}
		if mustMeta(t, key+".Nav", e.Nav) != e.Tree.Root {
			t.Errorf("%s: Nav.Meta() != tree root", key)
		}
		if mustMeta(t, key+".ID", e.ID) != e.Tree.Root {
			t.Errorf("%s: ID.Meta() != tree root", key)
		}
	}
}

// TestDotNotationSurface proves the dot-notation entry points (SOM §8)
// resolve representative positions to the expected paths and to the same
// SomMetaNode instances the dynamic ByPath lookups find.
func TestDotNotationSurface(t *testing.T) {
	if D00SolutionBlueprintMeta.Path != "SBP" {
		t.Errorf("dot root path = %q, want SBP", D00SolutionBlueprintMeta.Path)
	}
	if got := D00SolutionBlueprintMeta.IntroductionAndScope().Path; got != "SBP/introductionAndScope" {
		t.Errorf("dot section path = %q", got)
	}
	if got := D00SolutionBlueprintMeta.Requirements().Content().Path; got != "SBP/requirements/content" {
		t.Errorf("dot leaf path = %q", got)
	}
	if got := D00SolutionBlueprintMeta.IntroductionAndScope().Goals().Content().Path; got != "SBP/introductionAndScope/goals/content" {
		t.Errorf("dot nested-leaf path = %q", got)
	}

	// Meta() resolves to the same node ByPath finds.
	viaDot := mustMeta(t, "IntroductionAndScope", D00SolutionBlueprintMeta.IntroductionAndScope())
	viaPath := D00SolutionBlueprintMetaTree.ByPath("SBP/introductionAndScope")
	if viaDot != viaPath {
		t.Errorf("dot Meta() != ByPath node")
	}
	if viaDot.MemberName != "introductionAndScope" {
		t.Errorf("MemberName = %q, want introductionAndScope", viaDot.MemberName)
	}

	// List positions expose Item() with element accessors.
	revs := D00SolutionBlueprintMeta.DocumentControl().RevisionHistory()
	if revs.Path != "SBP/documentControl/RVENT-REVS-LST" {
		t.Errorf("dot list path = %q", revs.Path)
	}
	if got := revs.Item(3).Path; got != "SBP/documentControl/RVENT-REVS-LST-3" {
		t.Errorf("dot list-item path = %q", got)
	}
	// The list node's metadata carries the section-id pattern.
	if node := mustMeta(t, "Revisions", revs); node.SectionIDPattern == "" {
		t.Errorf("list node SectionIDPattern is empty")
	}

	// A second root has its own entry point and segment.
	if D01CurrentLandscapeAssessmentMeta.Path == "SBP" {
		t.Errorf("second root shares the SBP segment")
	}
	if mustMeta(t, "D01CurrentLandscapeAssessmentMeta", &D01CurrentLandscapeAssessmentMeta.SomMetaRef) !=
		D01CurrentLandscapeAssessmentMetaTree.Root {
		t.Errorf("second-root Meta() != its tree root")
	}
}

// TestIdTreeSurface proves the ID-tree entry points (SOM §8) agree with the
// dot-notation positions and that every root's ID entry point sits at its own
// section-id segment over the same tree root node.
func TestIdTreeSurface(t *testing.T) {
	// The ID root shares the dot root position.
	if SBP.Path != D00SolutionBlueprintMeta.Path {
		t.Errorf("SBP.Path = %q != dot root %q", SBP.Path, D00SolutionBlueprintMeta.Path)
	}
	if mustMeta(t, "SBP", &SBP.SomMetaRef) !=
		mustMeta(t, "D00SolutionBlueprintMeta", &D00SolutionBlueprintMeta.SomMetaRef) {
		t.Errorf("SBP.Meta() != dot root Meta()")
	}

	// A hoisted list id agrees with the dot-notation position: RVENT_REVS_LST
	// is hoisted onto the root ID type through the id-less documentControl /
	// revisionHistory members.
	revs := D00SolutionBlueprintMeta.DocumentControl().RevisionHistory()
	hoisted := SBP.RVENT_REVS_LST()
	if hoisted.Path != revs.Path {
		t.Errorf("hoisted path = %q != dot path %q", hoisted.Path, revs.Path)
	}
	if mustMeta(t, "SBP.RVENT_REVS_LST", hoisted) != mustMeta(t, "revisions", revs) {
		t.Errorf("hoisted Meta() != dot Meta()")
	}
	if got, want := hoisted.Item(0).Path, revs.Item(0).Path; got != want {
		t.Errorf("hoisted Item(0) path = %q, want %q", got, want)
	}

	// Every root has a distinct ID entry point at its own segment, resolving
	// to its generated tree's root node.
	idRoots := make(map[string]*som.SomMetaRef, len(SomMetaRoots))
	for rootType, e := range SomMetaRoots {
		idRoots[rootType] = e.ID
	}
	if len(idRoots) != len(generatedTrees) {
		t.Errorf("idRoots has %d entries, generatedTrees %d",
			len(idRoots), len(generatedTrees))
	}
	for rootType, ref := range idRoots {
		tree, ok := generatedTrees[rootType]
		if !ok {
			t.Errorf("no generated tree for id root %s", rootType)
			continue
		}
		if ref.Path != tree.Root.SectionID {
			t.Errorf("%s id path = %q, want %q", rootType, ref.Path, tree.Root.SectionID)
		}
		if mustMeta(t, rootType, ref) != tree.Root {
			t.Errorf("%s id Meta() != tree root", rootType)
		}
	}
}
