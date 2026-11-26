package tests

// The document set (spec_document_set.go, `tom_specs_model_rules.md` §9.7):
// SpecDocumentSet, SyncReport and RenameID.
//
// The shared corpus (`document_set_cases.json`) pins the canonical JSON of the
// construction, the report and the rename; this test holds the Go surface it
// does not: the accessors of the set (by type name and by section id, Get, Put
// replacing a document), the typed report (CountsByCode, CountsByResolution,
// IsInfo), the refusals as errors with their fields, a refused rename changing
// nothing, and the comparison helpers (typed sameness, ids, value keys). A
// port of the Python `spec_document_set_test.py`.

import (
	"errors"
	"reflect"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func setTableModel(t *testing.T, table map[string]any) *som.SpecModel {
	name, _ := table["model"].(string)
	return modelFromCorpus(t, name)
}

func setCaseNamed(t *testing.T, table map[string]any, group, prefix string) setCase {
	for _, c := range setCases(table, group) {
		if strings.HasPrefix(c.name(), prefix) {
			return c
		}
	}
	t.Fatalf("no %s case %q", group, prefix)
	return nil
}

func eq(t *testing.T, name string, got, want any) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		t.Errorf("%s: got %#v, want %#v", name, got, want)
	}
}

func TestDocumentSetAccessors(t *testing.T) {
	table := readSetTable(t, "document_set_cases.json")
	model := setTableModel(t, table)
	docs := setDocuments(t, setCaseNamed(t, table, "construction", "the base set")["documents"])
	s, err := som.NewSpecDocumentSet(model, docs)
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "BlueprintRoot", s.BlueprintRoot, "Blueprint")
	eq(t, "Blueprint", s.Blueprint() == docs[0].Document, true)
	eq(t, "Document.byType", s.Document("Detail") == docs[1].Document, true)
	eq(t, "Document.bySectionId", s.Document("DET") == docs[1].Document, true)
	name, ok := s.NameOf("SCR")
	eq(t, "NameOf", name, "screens")
	eq(t, "NameOf.ok", ok, true)
	_, ok = s.NameOf("Nope")
	eq(t, "NameOf.unknown", ok, false)
	eq(t, "Get", s.Get("detail") == docs[1].Document, true)
	eq(t, "Get.unknown", s.Get("nope") == nil, true)
	eq(t, "RootOf", s.RootOf("screens"), "Screens")
	var ids []string
	for _, p := range s.Pairs() {
		ids = append(ids, p.SectionID)
	}
	eq(t, "Pairs", ids, []string{"REQS", "ACC", "CRIT"})
	eq(t, "Pair.anchors", [2]string{s.Pairs()[0].BlueprintAnchor, s.Pairs()[0].DetailAnchor},
		[2]string{"BLU/requirements", "DET/requirements"})
	eq(t, "Pair.sync", s.Pairs()[0].Sync != nil, true)
	// Put replaces the document of the same name.
	other := som.NewSpecDocument()
	other.LoadJSON(docs[1].Document.ToJSON())
	if err := s.Put("detail", other); err != nil {
		t.Fatal(err)
	}
	eq(t, "Put.replaces", s.Get("detail") == other, true)
	eq(t, "Put.names", s.Names(), []string{"blueprint", "detail", "screens"})
	// An empty set knows its pairs and every Phase 3 root as missing.
	empty, err := som.NewSpecDocumentSet(model, nil)
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "empty.names", empty.Names(), []string{})
	eq(t, "empty.missing", empty.MissingRoots(), []string{"Detail", "Screens"})
	eq(t, "empty.pairs", len(empty.Pairs()), 3)
}

func TestDocumentSetRefusals(t *testing.T) {
	table := readSetTable(t, "document_set_cases.json")
	model := setTableModel(t, table)
	same := setCaseNamed(t, table, "construction", "two documents of one root")
	_, err := som.NewSpecDocumentSet(model, setDocuments(t, same["documents"]))
	var se *som.SpecDocumentSetError
	if !errors.As(err, &se) {
		t.Fatalf("sameRoot: got %v", err)
	}
	eq(t, "sameRoot.refusal", se.Refusal, som.SpecDocumentSetRefusalSameRoot)
	eq(t, "sameRoot.json", generic(t, se.ToJSON()), same["expect"].(map[string]any)["refused"])
	eq(t, "sameRoot.error", strings.HasPrefix(se.Error(), "SpecDocumentSetError(sameRoot): "), true)

	unp := setCaseNamed(t, table, "construction", "a synced class whose positions")
	_, err = som.NewSpecDocumentSet(modelFromGeneric(t, unp["meta"]), setDocuments(t, unp["documents"]))
	if !errors.As(err, &se) {
		t.Fatalf("unpairable: got %v", err)
	}
	eq(t, "unpairable.refusal", se.Refusal, som.SpecDocumentSetRefusalUnpairable)
	eq(t, "unpairable.className", se.ClassName != "", true)

	// Put refuses an empty document.
	s, _ := som.NewSpecDocumentSet(model, nil)
	err = s.Put("x", som.NewSpecDocument())
	eq(t, "Put.noRoot", errors.As(err, &se) && se.Refusal == som.SpecDocumentSetRefusalNoRoot, true)
}

func TestSyncReport(t *testing.T) {
	table := readSetTable(t, "document_set_cases.json")
	model := setTableModel(t, table)
	c := setCaseNamed(t, table, "reports", "an enum value differs")
	r := som.SyncReport(mustSet(model, setDocuments(t, c["documents"])), nil)
	eq(t, "Clean", r.Clean(), false)
	eq(t, "CountsByCode", r.CountsByCode(), []som.SpecSyncCount{{Key: som.SpecSyncCodeSharedValueDiffers, Count: 1}})
	eq(t, "CountsByResolution", r.CountsByResolution(), []som.SpecSyncCount{{Key: som.SpecSyncResolutionBackfill, Count: 1}})
	f := r.Findings[0]
	eq(t, "finding.pair", f.Pair, "REQS")
	eq(t, "finding.holder", f.Holder, som.SpecSyncHolderDetail)
	eq(t, "finding.IsInfo", f.IsInfo(), false)
	eq(t, "finding.values", [2]string{*f.Blueprint.Value, *f.Detail.Value}, [2]string{"approved", "done"})
	eq(t, "finding.field", f.Blueprint.Field, "status")
	var names []string
	for _, d := range r.DocumentFindings {
		names = append(names, d.Name)
	}
	eq(t, "report.documents", names, []string{"blueprint", "detail", "screens"})
	eq(t, "report.json", generic(t, r.ToJSON()), c["expect"])
	// Scoped to another pair, the finding is left out.
	scoped := som.SyncReport(mustSet(model, setDocuments(t, c["documents"])), []string{"ACC"})
	eq(t, "report.scoped", len(scoped.Findings), 0)
	pending := som.SyncReport(mustSet(model,
		setDocuments(t, setCaseNamed(t, table, "reports", "a value holding a pending change")["documents"])), nil)
	eq(t, "pending.clean", pending.Clean(), true)
	allInfo := len(pending.Findings) > 0
	for _, f := range pending.Findings {
		allInfo = allInfo && f.IsInfo()
	}
	eq(t, "pending.info", allInfo, true)
}

func TestRenameID(t *testing.T) {
	table := readSetTable(t, "document_set_cases.json")
	model := setTableModel(t, table)
	ok := setCaseNamed(t, table, "renames", "an id renamed")
	s := mustSet(model, setDocuments(t, ok["documents"]))
	changes, err := som.RenameID(s, ok.str("from"), ok.str("to"))
	if err != nil {
		t.Fatal(err)
	}
	eq(t, "rename.first", [3]string{changes[0].Kind, changes[0].OldValue, changes[0].NewValue},
		[3]string{"sectionId", ok.str("from"), ok.str("to")})
	again, err := som.RenameID(s, ok.str("from"), "REQ-OTHER")
	eq(t, "rename.again", len(again) == 0 && err == nil, true)

	refused := setCaseNamed(t, table, "renames", "a rename onto an id")
	s = mustSet(model, setDocuments(t, refused["documents"]))
	var before []any
	for _, n := range s.Names() {
		before = append(before, generic(t, s.Get(n).ToJSON()))
	}
	_, err = som.RenameID(s, refused.str("from"), refused.str("to"))
	var re *som.SpecRenameError
	if !errors.As(err, &re) {
		t.Fatalf("rename.refused: got %v", err)
	}
	eq(t, "rename.documents", generic(t, re.Documents), refused["expect"].(map[string]any)["refused"])
	eq(t, "rename.error", strings.HasPrefix(re.Error(), "SpecRenameError: "), true)
	var after []any
	for _, n := range s.Names() {
		after = append(after, generic(t, s.Get(n).ToJSON()))
	}
	eq(t, "rename.unchanged", after, before)
}

func TestDocumentSetHelpers(t *testing.T) {
	dbl := &som.FormFieldSpec{Name: "n", Label: "n", Type: "double"}
	eq(t, "sameTyped.double", som.SpecSetSameTyped("2", "2.0", dbl), true)
	eq(t, "sameTyped.hex", som.SpecSetSameTyped("0x10", "16", dbl), true)
	eq(t, "sameTyped.nan", som.SpecSetSameTyped("NaN", "NaN", dbl), false)
	eq(t, "sameTyped.text", som.SpecSetSameTyped("2", "2.0", nil), false)
	eq(t, "sameTyped.bool", som.SpecSetSameTyped("True", "true", &som.FormFieldSpec{Name: "b", Type: "bool"}), true)
	eq(t, "ids", som.SpecLinkIDs(" A, ,B ,C"), []string{"A", "B", "C"})
	eq(t, "stripKind.form", som.SpecSetStripKind("f:LIST[X]/content#status"), "LIST[X]/content")
	eq(t, "stripKind.item", som.SpecSetStripKind("i:LIST[X]"), "LIST[X]")
	eq(t, "reviewed", som.SpecSetReviewed(" a {++b ++}"), "a")
	eq(t, "isPending", som.SpecSetIsPending("a {++b++}"), true)
	eq(t, "isPending.plain", som.SpecSetIsPending("a b"), false)
	eq(t, "codeIndex.first", som.SpecSyncCodeIndex(som.SpecSyncCodeSharedValueDiffers), 0)
	eq(t, "codeIndex.last", som.SpecSyncCodeIndex(som.SpecSyncCodeUnmarkable), 9)
	eq(t, "codeIndex.unknown", som.SpecSyncCodeIndex("nope"), -1)
}
