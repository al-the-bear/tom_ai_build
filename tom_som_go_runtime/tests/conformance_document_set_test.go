package tests

// The document-set part of the conformance suite (`tom_specs_model_rules.md`
// §9.7): the set, its report and the global rename
// (`document_set_cases.json`), DeriveFields (`derive_cases.json`), Prefill and
// Backfill (`prefill_cases.json`, `backfill_cases.json`). A port of the Python
// runner's `test_document_set` / `test_derive_fields` /
// `test_prefill_backfill`.

import (
	"encoding/json"
	"errors"
	"fmt"
	"reflect"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// setCase is one case of the four tables, read generically.
type setCase map[string]any

func (c setCase) str(key string) string {
	s, _ := c[key].(string)
	return s
}

func (c setCase) name() string { return c.str("name") }

func (c setCase) intent() []string {
	var out []string
	if list, ok := c["intent"].([]any); ok {
		for _, x := range list {
			out = append(out, fmt.Sprint(x))
		}
	}
	return out
}

// pairs is the case's `pairs` list, nil when it has none.
func (c setCase) pairs() []string {
	list, ok := c["pairs"].([]any)
	if !ok {
		return nil
	}
	out := []string{}
	for _, x := range list {
		out = append(out, fmt.Sprint(x))
	}
	return out
}

func (c setCase) flag(key string) bool {
	b, _ := c[key].(bool)
	return b
}

// readSetTable reads a case table as JSON objects.
func readSetTable(t *testing.T, name string) map[string]any {
	var table map[string]any
	readJSON(t, name, &table)
	return table
}

func setCases(table map[string]any, group string) []setCase {
	var out []setCase
	if list, ok := table[group].([]any); ok {
		for _, x := range list {
			if m, ok := x.(map[string]any); ok {
				out = append(out, setCase(m))
			}
		}
	}
	return out
}

// stateDocument is the document a generic state decodes to.
func stateDocument(t *testing.T, state any) *som.SpecDocument {
	b, err := json.Marshal(state)
	if err != nil {
		t.Fatalf("marshal state: %v", err)
	}
	var j som.DocumentJson
	if err := json.Unmarshal(b, &j); err != nil {
		t.Fatalf("decode state: %v", err)
	}
	return docFromState(&j)
}

// setDocuments is the documents of a case, `[[name, state], …]`.
func setDocuments(t *testing.T, entries any) []som.SpecNamedDocument {
	var out []som.SpecNamedDocument
	list, _ := entries.([]any)
	for _, e := range list {
		pair := e.([]any)
		out = append(out, som.SpecNamedDocument{Name: fmt.Sprint(pair[0]), Document: stateDocument(t, pair[1])})
	}
	return out
}

func modelFromGeneric(t *testing.T, v any) *som.SpecModel {
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatalf("marshal model: %v", err)
	}
	m, err := som.SpecModelFromJSON(b)
	if err != nil {
		t.Fatalf("load inline model: %v", err)
	}
	return m
}

func modelFromCorpus(t *testing.T, name string) *som.SpecModel {
	if name == "" {
		name = "links.meta.json"
	}
	m, err := som.SpecModelFromJSON([]byte(readCorpus(t, name)))
	if err != nil {
		t.Fatalf("load %s: %v", name, err)
	}
	return m
}

// setModels caches the real model (11 MB) across the tables.
type setModels struct {
	t   *testing.T
	som *som.SpecModel
}

func (m *setModels) real() *som.SpecModel {
	if m.som == nil {
		m.som = loadSomModel(m.t)
	}
	return m.som
}

// modelOf is the model a case runs against: an inline one, the real one, or
// the fixture.
func (m *setModels) modelOf(fixture *som.SpecModel, c setCase) *som.SpecModel {
	if inline, ok := c["inline"].(map[string]any); ok {
		return modelFromGeneric(m.t, inline)
	}
	if c.str("model") == "som" {
		return m.real()
	}
	return fixture
}

func nullableString(s string) any {
	if s == "" {
		return nil
	}
	return s
}

func pairsJSON(pairs []*som.SpecSyncPair) []any {
	out := []any{}
	for _, p := range pairs {
		out = append(out, p.ToJSON())
	}
	return out
}

func stringList(ss []string) []any {
	out := []any{}
	for _, s := range ss {
		out = append(out, s)
	}
	return out
}

// runGuarded runs f, a panic answered as an error (the reference runtimes
// raise).
func runGuarded(f func() any) (out any, err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("panic: %v", r)
		}
	}()
	return f(), nil
}

func setConstructionCase(t *testing.T, model *som.SpecModel, c setCase) any {
	docs := setDocuments(t, c["documents"])
	var s *som.SpecDocumentSet
	var err error
	if c.flag("fragments") {
		s, err = som.SpecDocumentSetFromFragments(model, docs)
	} else {
		s, err = som.NewSpecDocumentSet(model, docs)
	}
	if err != nil {
		var se *som.SpecDocumentSetError
		if errors.As(err, &se) {
			return map[string]any{"refused": se.ToJSON()}
		}
		panic(err)
	}
	return map[string]any{
		"blueprintRoot": nullableString(s.BlueprintRoot),
		"names":         stringList(s.Names()),
		"roots":         stringList(s.Roots()),
		"missingRoots":  stringList(s.MissingRoots()),
		"pairs":         pairsJSON(s.Pairs()),
	}
}

func mustSet(model *som.SpecModel, docs []som.SpecNamedDocument) *som.SpecDocumentSet {
	s, err := som.NewSpecDocumentSet(model, docs)
	if err != nil {
		panic(err)
	}
	return s
}

func setReportCase(t *testing.T, models *setModels, fixture *som.SpecModel, c setCase) any {
	s := mustSet(models.modelOf(fixture, c), setDocuments(t, c["documents"]))
	return som.SyncReport(s, c.pairs()).ToJSON()
}

func setRenameCase(t *testing.T, model *som.SpecModel, c setCase) any {
	s := mustSet(model, setDocuments(t, c["documents"]))
	changes, err := som.RenameID(s, c.str("from"), c.str("to"))
	if err != nil {
		var re *som.SpecRenameError
		if errors.As(err, &re) {
			return map[string]any{"refused": stringList(re.Documents)}
		}
		panic(err)
	}
	after := som.SyncReport(s, nil)
	list := []any{}
	for _, x := range changes {
		list = append(list, x.ToJSON())
	}
	n := 0
	for _, f := range after.Findings {
		if !f.IsInfo() {
			n++
		}
	}
	return map[string]any{"changes": list, "cleanAfter": after.Clean(), "findingsAfter": n}
}

func listLen(v any) int {
	l, _ := v.([]any)
	return len(l)
}

// setTokens is every token a document-set expectation shows (the Dart
// test's `_setTokens`).
func setTokens(expect any) map[string]bool {
	out := map[string]bool{}
	e, _ := expect.(map[string]any)
	refused := e["refused"]
	if m, ok := refused.(map[string]any); ok {
		out[fmt.Sprint(m["refusal"])] = true
	}
	if _, ok := refused.([]any); ok {
		out["refused"] = true
	}
	if e["pairs"] != nil && refused == nil {
		out["built"] = true
		if listLen(e["missingRoots"]) > 0 {
			out["missingRoots"] = true
		}
	}
	if e["findings"] != nil {
		if e["clean"] == true {
			out["clean"] = true
		}
		if listLen(e["notStarted"]) > 0 {
			out["notStarted"] = true
		}
		if listLen(e["notStartedPairs"]) > 0 {
			out["notStartedPairs"] = true
		}
		for _, f := range e["findings"].([]any) {
			fm := f.(map[string]any)
			out[fmt.Sprint(fm["code"])] = true
			out[fmt.Sprint(fm["resolution"])] = true
		}
		for _, d := range e["documentFindings"].([]any) {
			for _, x := range d.([]any)[1].([]any) {
				out[fmt.Sprint(x.(map[string]any)["code"])] = true
			}
		}
	}
	if listLen(e["changes"]) > 0 {
		out["renamed"] = true
	}
	return out
}

// checkCase compares one case's output with its expectation.
func checkCase(c *checker, t *testing.T, name string, run func() any, expect any) {
	got, err := runGuarded(run)
	if err != nil {
		c.check(name, false, "threw "+err.Error())
		return
	}
	g := generic(t, got)
	if reflect.DeepEqual(g, expect) {
		c.check(name, true, "")
		return
	}
	c.check(name, false, "got "+canonJSON(t, g)+" want "+canonJSON(t, expect))
}

func testDocumentSet(c *checker, t *testing.T, models *setModels) {
	table := readSetTable(t, "document_set_cases.json")
	model, _ := table["model"].(string)
	fixture := modelFromCorpus(t, model)
	run := func(group string, f func(setCase) any) {
		for _, cc := range setCases(table, group) {
			name := "set." + group + "[" + cc.name() + "]"
			checkCase(c, t, name, func() any { return f(cc) }, cc["expect"])
			shown := setTokens(cc["expect"])
			for _, token := range cc.intent() {
				c.check("set."+group+".intent["+cc.name()+": "+token+"]", shown[token], "")
			}
		}
	}
	run("construction", func(cc setCase) any {
		m := fixture
		if meta, ok := cc["meta"]; ok && meta != nil {
			m = modelFromGeneric(t, meta)
		}
		return setConstructionCase(t, m, cc)
	})
	run("reports", func(cc setCase) any { return setReportCase(t, models, fixture, cc) })
	run("renames", func(cc setCase) any { return setRenameCase(t, fixture, cc) })

	// DSC4: the real model pairs every synced class.
	real, err := som.NewSpecDocumentSet(models.real(), nil)
	if err != nil {
		c.check("set.DSC4.blueprintRoot", false, err.Error())
		c.check("set.DSC4.pairs", false, err.Error())
		return
	}
	c.check("set.DSC4.blueprintRoot", real.BlueprintRoot == "D00SolutionBlueprint", real.BlueprintRoot)
	c.check("set.DSC4.pairs", len(real.Pairs()) == 132, itoa(len(real.Pairs())))
}

// --- DeriveFields -----------------------------------------------------------------

func deriveCase(t *testing.T, model *som.SpecModel, cc setCase) any {
	doc := stateDocument(t, cc["state"])
	marked := true
	if m, ok := cc["marked"].(bool); ok {
		marked = m
	}
	options := som.SpecDeriveOptions{
		Marked: marked, Author: cc.str("author"), At: cc.str("at"), DryRun: cc.flag("dryRun"),
	}
	first := som.DeriveFields(model, doc, options)
	second := som.DeriveFields(model, doc, options)
	// The first run's result is read after the second, as the reference
	// runners read it (the same document unless it is a dry run).
	firstJSON := first.ToJSON()
	after := append(som.ValidateLinks(model, second.Document), som.ValidateDocument(model, second.Document)...)
	return map[string]any{
		"first":         firstJSON,
		"second":        second.ToJSON(),
		"findingsAfter": validationPairs(after),
		"given":         doc.ToJSON(),
	}
}

func deriveIntentHolds(token string, cc setCase) (holds, known bool) {
	e := cc["expect"].(map[string]any)
	first := e["first"].(map[string]any)
	changes, _ := first["changes"].([]any)
	unresolved := func(code string) bool {
		for _, u := range first["unresolved"].([]any) {
			if u.(map[string]any)["code"] == code {
				return true
			}
		}
		return false
	}
	anyChange := func(key string, want any) bool {
		for _, x := range changes {
			if reflect.DeepEqual(x.(map[string]any)[key], want) {
				return true
			}
		}
		return false
	}
	switch token {
	case "nothing":
		return len(changes) == 0, true
	case "step1", "step2", "step3":
		return anyChange("step", float64(token[4]-'0')), true
	case "rowAdded", "rowRemoved":
		return anyChange("kind", token), true
	case "marked":
		for _, x := range changes {
			if strings.Contains(fmt.Sprint(x.(map[string]any)["new"]), "{") {
				return true, true
			}
		}
		return false, true
	case "clean":
		return listLen(e["findingsAfter"]) == 0, true
	case "idempotent":
		second := e["second"].(map[string]any)
		return listLen(second["changes"]) == 0 && reflect.DeepEqual(second["document"], first["document"]), true
	case "unchanged":
		return reflect.DeepEqual(e["given"], cc["state"]), true
	case "unmarkable", "derivedLookupMiss":
		return unresolved(token), true
	}
	return false, false
}

func intentDetail(known bool) string {
	if !known {
		return "unknown intent token"
	}
	return "does not hold"
}

func testDeriveFields(c *checker, t *testing.T) {
	table := readSetTable(t, "derive_cases.json")
	name, _ := table["model"].(string)
	model := modelFromCorpus(t, name)
	for _, cc := range setCases(table, "cases") {
		checkCase(c, t, "derive["+cc.name()+"]", func() any { return deriveCase(t, model, cc) }, cc["expect"])
		for _, token := range cc.intent() {
			holds, known := deriveIntentHolds(token, cc)
			c.check("derive.intent["+cc.name()+": "+token+"]", holds && known, intentDetail(known))
		}
	}
}

// --- Prefill and Backfill -----------------------------------------------------------

func prefillCase(t *testing.T, model *som.SpecModel, cc setCase) any {
	s := mustSet(model, setDocuments(t, cc["documents"]))
	run := func() any {
		r, err := som.Prefill(s, cc.str("root"), som.SpecPrefillOptions{Name: cc.str("name_"), Pairs: cc.pairs()})
		if err != nil {
			var pe *som.SpecPrefillError
			if errors.As(err, &pe) {
				return map[string]any{"refused": pe.Code}
			}
			panic(err)
		}
		return r.ToJSON()
	}
	first := run()
	second := run()
	after := som.SyncReport(s, nil)
	return map[string]any{
		"first":  first,
		"second": second,
		"reportAfter": map[string]any{
			"countsByCode":    som.SpecSyncCountsJSON(after.CountsByCode()),
			"notStartedPairs": stringList(after.NotStartedPairs),
		},
	}
}

func prefillIntentHolds(token string, cc setCase) (holds, known bool) {
	e := cc["expect"].(map[string]any)
	first := e["first"].(map[string]any)
	second := e["second"].(map[string]any)
	switch token {
	case "created":
		return first["created"] == true, true
	case "filled":
		return listLen(first["filledPairs"]) > 0, true
	case "skipped":
		return listLen(first["skippedPairs"]) > 0, true
	case "derived":
		d, _ := first["derived"].(map[string]any)
		return listLen(d["changes"]) > 0, true
	case "idempotent":
		d, _ := second["derived"].(map[string]any)
		return listLen(second["filledPairs"]) == 0 && listLen(d["changes"]) == 0 &&
			reflect.DeepEqual(second["document"], first["document"]), true
	case "agrees":
		report := e["reportAfter"].(map[string]any)
		for _, x := range report["countsByCode"].([]any) {
			if strings.HasPrefix(fmt.Sprint(x.([]any)[0]), "shared") {
				return false, true
			}
		}
		return true, true
	case "noBlueprint", "unknownRoot":
		return first["refused"] == token, true
	}
	return false, false
}

func backfillCase(t *testing.T, models *setModels, fixture *som.SpecModel, cc setCase) any {
	s := mustSet(models.modelOf(fixture, cc), setDocuments(t, cc["documents"]))
	run := func() any {
		r, err := som.Backfill(s, som.SpecBackfillOptions{
			Pairs: cc.pairs(), Path: cc.str("path"), DryRun: cc.flag("dryRun"),
			Author: cc.str("author"), Date: cc.str("date"),
		})
		if err != nil {
			var be *som.SpecBackfillError
			if errors.As(err, &be) {
				return map[string]any{"refused": be.ToJSON()}
			}
			panic(err)
		}
		return r.ToJSON()
	}
	first := run()
	second := run()
	after := som.SyncReport(s, nil)
	given := []any{}
	for _, n := range s.Names() {
		given = append(given, []any{n, s.Get(n).ToJSON()})
	}
	return map[string]any{
		"first":  first,
		"second": second,
		"reportAfter": map[string]any{
			"countsByCode": som.SpecSyncCountsJSON(after.CountsByCode()),
			"clean":        after.Clean(),
		},
		"given": given,
	}
}

func backfillIntentHolds(token string, cc setCase) (holds, known bool) {
	e := cc["expect"].(map[string]any)
	first := e["first"].(map[string]any)
	second := e["second"].(map[string]any)
	changes, _ := first["changes"].([]any)
	left, _ := first["left"].([]any)
	switch token {
	case "nothing":
		return first["refused"] == nil && len(changes) == 0, true
	case "value", "elementAdded", "elementRemoved", "revision", "derived":
		for _, x := range changes {
			if x.(map[string]any)["kind"] == token {
				return true, true
			}
		}
		return false, true
	case "heldHere", "mayBeAdded", "agent":
		for _, x := range left {
			if x.(map[string]any)["reason"] == token {
				return true, true
			}
		}
		return false, true
	case "setHasMarks":
		refused, ok := first["refused"].(map[string]any)
		return ok && refused["code"] == "setHasMarks" && listLen(refused["places"]) > 0, true
	case "idempotent":
		return listLen(second["changes"]) == 0, true
	case "unchanged":
		return reflect.DeepEqual(e["given"], cc["documents"]), true
	case "cleanAfter":
		return e["reportAfter"].(map[string]any)["clean"] == true, true
	}
	return false, false
}

func testPrefillBackfill(c *checker, t *testing.T, models *setModels) {
	groups := []struct {
		label, file string
		kase        func(*som.SpecModel, setCase) any
		holds       func(string, setCase) (bool, bool)
	}{
		{"prefill", "prefill_cases.json",
			func(m *som.SpecModel, cc setCase) any { return prefillCase(t, m, cc) }, prefillIntentHolds},
		{"backfill", "backfill_cases.json",
			func(m *som.SpecModel, cc setCase) any { return backfillCase(t, models, m, cc) }, backfillIntentHolds},
	}
	for _, g := range groups {
		table := readSetTable(t, g.file)
		name, _ := table["model"].(string)
		model := modelFromCorpus(t, name)
		for _, cc := range setCases(table, "cases") {
			checkCase(c, t, g.label+"["+cc.name()+"]", func() any { return g.kase(model, cc) }, cc["expect"])
			for _, token := range cc.intent() {
				holds, known := g.holds(token, cc)
				c.check(g.label+".intent["+cc.name()+": "+token+"]", holds && known, intentDetail(known))
			}
		}
	}
}
