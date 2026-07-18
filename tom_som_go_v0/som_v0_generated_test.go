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
//   - the generated model-version accessor / constant return `1.0`;
//   - the instantiation-time version check (§2.2) accepts an editable stamp and
//     rejects a newer-minor / cross-major stamp with a *som.SomVersionError;
//   - the live-document conformance case (YRD8 / dsa11): the shared Meridian
//     sample round-trips (content + lists), its markdown twin validates clean
//     under the SBP schema, and ByPath / nav / id node operations resolve to the
//     same meta identity — the guarantees the Go golden generator emits, pinned
//     as a committed guard because `golden/` is git-ignored.
//
// Run with `go test ./...`. The runtime resolves through the `replace`
// directive in this module's go.mod, so the test is portable across checkouts.
package somv0

import (
	"errors"
	"os"
	"sort"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// samplePath is the shared cross-language conformance sample. Tests read it via
// this relative path, so `go test` must run from the project directory (the
// `../tom_som_conformance/...` prefix resolves against the module root).
const samplePath = "../tom_som_conformance/samples/meridian_order_management.docspecs.yaml"

func TestRootAndParity(t *testing.T) {
	doc := som.NewSpecDocument()
	pd, err := NewD00SolutionBlueprint(doc, "")
	if err != nil {
		t.Fatalf("NewD00SolutionBlueprint: %v", err)
	}

	if pd.Path() != "SBP" {
		t.Errorf("root segment = %q, want SBP", pd.Path())
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

// TestAlignedAbsenceSemantics ports the Dart "aligned absence semantics
// (§ item 5)" group: a section's structural emptiness stays in lock-step with
// the generic HasValuesUnder / HasContent predicates as values are written and
// cleared. The Go emptiness convention is the empty string (never nil).
func TestAlignedAbsenceSemantics(t *testing.T) {
	// A section IsEmpty until any value is written under it, and empties again
	// when that value is cleared.
	t.Run("section emptiness follows subtree values", func(t *testing.T) {
		pd, _ := NewD00SolutionBlueprint(som.NewSpecDocument(), "")
		req := pd.Requirements()
		if !req.IsEmpty() {
			t.Errorf("fresh section IsEmpty() = false, want true")
		}
		// A nested content value fills the section (subtree emptiness).
		req.SetContent("Some requirements")
		if req.IsEmpty() {
			t.Errorf("after write IsEmpty() = true, want false")
		}
		// Clearing it empties the section again.
		req.SetContent("")
		if !req.IsEmpty() {
			t.Errorf("after clear IsEmpty() = false, want true")
		}
	})

	// Typed IsEmpty and generic HasValuesUnder agree before and after a write.
	t.Run("typed IsEmpty and generic HasValuesUnder agree", func(t *testing.T) {
		doc := som.NewSpecDocument()
		pd, _ := NewD00SolutionBlueprint(doc, "")
		req := pd.Requirements()
		path := req.Path()
		if got, want := req.IsEmpty(), !doc.HasValuesUnder(path); got != want {
			t.Errorf("before write: IsEmpty()=%v, !HasValuesUnder=%v", got, want)
		}
		doc.SetContent(path+"/content", "x")
		if got, want := req.IsEmpty(), !doc.HasValuesUnder(path); got != want {
			t.Errorf("after write: IsEmpty()=%v, !HasValuesUnder=%v", got, want)
		}
		if req.IsEmpty() {
			t.Errorf("after write: IsEmpty() = true, want false")
		}
	})

	// HasContent gives the generic leaf path the typed .Content answer.
	t.Run("HasContent agrees with typed content on the leaf", func(t *testing.T) {
		doc := som.NewSpecDocument()
		pd, _ := NewD00SolutionBlueprint(doc, "")
		req := pd.Requirements()
		leaf := req.Path() + "/content"
		// Typed "" and generic HasContent(false) agree the leaf is empty.
		if got := req.Content(); got != "" {
			t.Errorf("initial typed content = %q, want empty", got)
		}
		if doc.HasContent(leaf) {
			t.Errorf("initial HasContent(%q) = true, want false", leaf)
		}
		req.SetContent("Filled")
		if got, want := req.Content() != "", doc.HasContent(leaf); got != want {
			t.Errorf("after write: (content!=\"\")=%v, HasContent=%v", got, want)
		}
		if !doc.HasContent(leaf) {
			t.Errorf("after write: HasContent(%q) = false, want true", leaf)
		}
	})
}

// TestCanHaveContent ports the Dart "canHaveContent (structural content-slot
// predicate, § item 10)" behaviour against the real generated facade: the
// per-type predicate answers "does this section TYPE declare the standard
// `content` text leaf?" without probing Content() and without looking at the
// document.
//
// It is emitted per content-bearing type (shadowing the promoted
// som.SomNode.CanHaveContent false default), so:
//   - the D00SolutionBlueprint root (which has a Content() leaf) → true;
//   - IntroductionAndScope().Goals() (content-bearing) → true;
//   - IntroductionAndScope().SystemsToReplace() (container-only, no `content`
//     leaf — only child sections) → false;
//
// and it is structural (schema) not state: filling / clearing the leaf never
// changes the answer, unlike the generic HasContent / typed IsEmpty state
// predicates.
func TestCanHaveContent(t *testing.T) {
	pd, err := NewD00SolutionBlueprint(som.NewSpecDocument(), "")
	if err != nil {
		t.Fatalf("NewD00SolutionBlueprint: %v", err)
	}

	// The root declares a `content` leaf → content-bearing.
	if !pd.CanHaveContent() {
		t.Errorf("root D00SolutionBlueprint.CanHaveContent() = false, want true")
	}

	scope := pd.IntroductionAndScope()

	// Goals is content-bearing (carries the standard `content` leaf).
	goals := scope.Goals()
	if !goals.CanHaveContent() {
		t.Errorf("Goals.CanHaveContent() = false, want true (content-bearing)")
	}

	// SystemsToReplace is container-only (only child sections, no `content` leaf)
	// → inherits the promoted som.SomNode false default.
	systems := scope.SystemsToReplace()
	if systems.CanHaveContent() {
		t.Errorf("SystemsToReplace.CanHaveContent() = true, want false (container-only)")
	}

	// Structural, not state: filling the content leaf leaves the schema-level
	// answer unchanged, and the container can never hold content regardless of
	// its current (empty) state.
	goals.SetContent("filled")
	if !goals.CanHaveContent() {
		t.Errorf("filled Goals.CanHaveContent() = false, want true (structural, not state)")
	}
	if systems.CanHaveContent() {
		t.Errorf("SystemsToReplace.CanHaveContent() must stay false regardless of state")
	}
}

// TestOneCallLoading ports the Dart "one-call loading (§ item 4)" group: the
// LoadYaml / LoadFile / FromYaml convenience loaders collapse the former
// decode → LoadJSON → thread-version incantation into a single call while
// retaining the document's parsed model version (empty-string sentinel when
// unstamped). Reads the shared sample via samplePath, so `go test` must run
// from the project directory.
func TestOneCallLoading(t *testing.T) {
	// LoadYaml collapses parse-into-document → thread-version into one call.
	t.Run("LoadYaml collapses the multi-step load", func(t *testing.T) {
		data, err := os.ReadFile(samplePath)
		if err != nil {
			t.Fatalf("read sample: %v", err)
		}
		yaml := string(data)

		// The former multi-step incantation, built by hand: parse into a
		// document (hierarchical v2 decoding needs the root's metadata tree),
		// then construct the typed root with the retained model version.
		manualDoc, err := som.FromYaml(yaml, D00SolutionBlueprintMetaTree)
		if err != nil {
			t.Fatalf("som.FromYaml: %v", err)
		}
		manual, err := NewD00SolutionBlueprint(manualDoc, manualDoc.ModelVersion)
		if err != nil {
			t.Fatalf("manual NewD00SolutionBlueprint: %v", err)
		}

		// The one-call convenience.
		oneCall, err := LoadYamlD00SolutionBlueprint(yaml)
		if err != nil {
			t.Fatalf("LoadYamlD00SolutionBlueprint: %v", err)
		}

		// The document stamp is applied automatically — no manual threading.
		if got, want := oneCall.Doc().ModelVersion, manualDoc.ModelVersion; got != want {
			t.Errorf("one-call ModelVersion = %q, want %q", got, want)
		}
		// Both paths read identical content from the shared sample.
		if got, want := oneCall.Content(), manual.Content(); got != want {
			t.Errorf("content mismatch: one-call=%q manual=%q", got, want)
		}
		if got, want := oneCall.IntroductionAndScope().Goals().Content(),
			manual.IntroductionAndScope().Goals().Content(); got != want {
			t.Errorf("goals content mismatch: one-call=%q manual=%q", got, want)
		}
		if got, want := oneCall.CurrentLandscape().OperationalMetrics().Length(),
			manual.CurrentLandscape().OperationalMetrics().Length(); got != want {
			t.Errorf("metrics length mismatch: one-call=%d manual=%d", got, want)
		}
	})

	// LoadFile reads the file then delegates to LoadYaml.
	t.Run("LoadFile delegates to LoadYaml", func(t *testing.T) {
		fromFile, err := LoadFileD00SolutionBlueprint(samplePath)
		if err != nil {
			t.Fatalf("LoadFileD00SolutionBlueprint: %v", err)
		}
		data, err := os.ReadFile(samplePath)
		if err != nil {
			t.Fatalf("read sample: %v", err)
		}
		fromYaml, err := LoadYamlD00SolutionBlueprint(string(data))
		if err != nil {
			t.Fatalf("LoadYamlD00SolutionBlueprint: %v", err)
		}
		if got, want := fromFile.Doc().ModelVersion, fromYaml.Doc().ModelVersion; got != want {
			t.Errorf("ModelVersion mismatch: file=%q yaml=%q", got, want)
		}
		if got, want := fromFile.Content(), fromYaml.Content(); got != want {
			t.Errorf("content mismatch: file=%q yaml=%q", got, want)
		}
	})

	// The wire format is hierarchical v2, so the fixture yaml is built via
	// som.EncodeYaml against the root's metadata tree (mirrors the Dart
	// suite's buildV2Yaml helper). modelVersion "" ⇒ unstamped.
	buildV2Yaml := func(modelVersion string) string {
		d := som.NewSpecDocument()
		d.SetContent("SBP/content", "Hello")
		yaml, err := som.EncodeYaml(d, D00SolutionBlueprintMetaTree, modelVersion)
		if err != nil {
			t.Fatalf("som.EncodeYaml: %v", err)
		}
		return yaml
	}

	// FromYaml (the generic one-call loader) retains the parsed model version.
	t.Run("FromYaml retains the parsed model version", func(t *testing.T) {
		doc, err := som.FromYaml(buildV2Yaml("1.0"), D00SolutionBlueprintMetaTree)
		if err != nil {
			t.Fatalf("som.FromYaml: %v", err)
		}
		if got := doc.ModelVersion; got != "1.0" {
			t.Errorf("ModelVersion = %q, want 1.0", got)
		}
		if got := doc.ContentOr("SBP/content"); got != "Hello" {
			t.Errorf("SBP/content = %q, want Hello", got)
		}
	})

	// An unstamped document loads with the empty-string sentinel (Go's null-free
	// convention) and the facade accepts it without error.
	t.Run("unstamped document yields the empty-string sentinel", func(t *testing.T) {
		yaml := buildV2Yaml("")
		doc, err := som.FromYaml(yaml, D00SolutionBlueprintMetaTree)
		if err != nil {
			t.Fatalf("som.FromYaml: %v", err)
		}
		if got := doc.ModelVersion; got != "" {
			t.Errorf("unstamped ModelVersion = %q, want \"\" sentinel", got)
		}
		// An empty stamp is accepted by the facade (a new document is editable).
		if _, err := LoadYamlD00SolutionBlueprint(yaml); err != nil {
			t.Errorf("LoadYamlD00SolutionBlueprint on unstamped: %v", err)
		}
	})
}

// TestLiveDocumentCase is the live-document conformance case durability guard
// (YRD8 / dsa11). The golden/ tree is git-ignored, so this committed test pins
// the three live-document guarantees the Go golden generator emits over the
// shared Meridian sample — a regression fails `go test`, not only a full
// nine-toolchain golden run. Mirrors the Dart (dsa7), Python (dsa8),
// JavaScript (dsa9) and TypeScript (dsa10) durability guards.
func TestLiveDocumentCase(t *testing.T) {
	const sampleMd = "../tom_som_conformance/samples/meridian_order_management.md"
	const schemaPath = "schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml"
	tree := D00SolutionBlueprintMetaTree

	// 1) Round-trip: decode → encode → decode is stable over content + lists.
	original, err := som.FromFile(samplePath, tree)
	if err != nil {
		t.Fatalf("som.FromFile: %v", err)
	}
	reEncoded, err := som.EncodeYaml(original, tree, original.ModelVersion)
	if err != nil {
		t.Fatalf("som.EncodeYaml: %v", err)
	}
	roundTripped, err := som.FromYaml(reEncoded, tree)
	if err != nil {
		t.Fatalf("som.FromYaml: %v", err)
	}
	if roundTripped.ModelVersion != original.ModelVersion {
		t.Errorf("roundtrip ModelVersion = %q, want %q", roundTripped.ModelVersion, original.ModelVersion)
	}
	origContent := original.ContentPaths()
	rtContent := roundTripped.ContentPaths()
	sort.Strings(origContent)
	sort.Strings(rtContent)
	if !sliceEqual(rtContent, origContent) {
		t.Errorf("roundtrip content paths diverged (%d vs %d)", len(rtContent), len(origContent))
	}
	for _, p := range origContent {
		if roundTripped.ContentOr(p) != original.ContentOr(p) {
			t.Errorf("roundtrip content value diverged at %q", p)
		}
	}
	origLists := original.ListPaths()
	rtLists := roundTripped.ListPaths()
	sort.Strings(origLists)
	sort.Strings(rtLists)
	if !sliceEqual(rtLists, origLists) {
		t.Errorf("roundtrip list paths diverged (%d vs %d)", len(rtLists), len(origLists))
	}
	for _, p := range origLists {
		if !sliceEqual(roundTripped.ListItems(p), original.ListItems(p)) {
			t.Errorf("roundtrip list items diverged at %q", p)
		}
	}

	// 2) Validation: the markdown twin is clean under the SBP schema.
	schemaText, err := os.ReadFile(schemaPath)
	if err != nil {
		t.Fatalf("read schema: %v", err)
	}
	schema, err := som.DocSpecsSchemaFromYamlText(string(schemaText))
	if err != nil {
		t.Fatalf("parse schema: %v", err)
	}
	mdText, err := os.ReadFile(sampleMd)
	if err != nil {
		t.Fatalf("read sample md: %v", err)
	}
	violations := som.NewDocSpecsValidator(schema).ValidateMarkdown(string(mdText))
	if schema.RootSectionID() != "SBP" {
		t.Errorf("schema root = %q, want SBP", schema.RootSectionID())
	}
	if len(schema.Warnings) != 0 {
		t.Errorf("schema warnings = %d, want 0", len(schema.Warnings))
	}
	if len(violations) != 0 {
		t.Errorf("validation violations = %d, want 0", len(violations))
	}

	// 3) Node operations: ByPath / nav / id resolve to the same meta identity.
	listByPath := tree.ByPath("SBP/currentLandscape/CUOPME-OPER-LST")
	if listByPath == nil {
		t.Fatal("ByPath(operationalMetrics list) = nil")
	}
	if listByPath.Kind != som.SomMetaKindList {
		t.Errorf("operationalMetrics kind = %v, want list", listByPath.Kind)
	}
	nav := D00SolutionBlueprintMeta
	navRef := nav.CurrentLandscape().OperationalMetrics()
	if navRef.Path != "SBP/currentLandscape/CUOPME-OPER-LST" {
		t.Errorf("nav path = %q, want SBP/currentLandscape/CUOPME-OPER-LST", navRef.Path)
	}
	navNode, err := navRef.Meta()
	if err != nil {
		t.Fatalf("navRef.Meta: %v", err)
	}
	if navNode != listByPath {
		t.Error("nav node identity != ByPath node")
	}
	revs := nav.DocumentControl().RevisionHistory()
	idItem := SBP.RVHST_REVS_LST().Item(0)
	navItem := revs.Item(0)
	if idItem.Path != navItem.Path {
		t.Errorf("id path = %q, want %q", idItem.Path, navItem.Path)
	}
	idNode, errI := idItem.Meta()
	navItemNode, errN := navItem.Meta()
	if errI != nil || errN != nil {
		t.Fatalf("item Meta: id=%v nav=%v", errI, errN)
	}
	if idNode != navItemNode {
		t.Error("id item node identity != nav item node")
	}
}
