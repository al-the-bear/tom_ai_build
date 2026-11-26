// The places and filters of the link vocabulary (spec_place.go,
// `tom_specs_model_rules.md` §9.7) and the typed link readers of the model
// they are read from (spec_model_links.go): the grammar, resolution under an
// anchor over the corpus's `links.meta.json`, the filter's `|` alternatives,
// the `@SameAs` holders and the readers' defaults for a key a meta does not
// carry.
//
// The shared corpus (`link_reader_cases.json`) pins the canonical JSON of
// these; this test holds the Go surface around it — the errors, the
// defaults, String() and the section positions. Mirrors the Python runtime's
// spec_place_test.py.
package tests

import (
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func linksModel(t *testing.T) *som.SpecModel {
	t.Helper()
	m, err := som.SpecModelFromJSON([]byte(readCorpus(t, "links.meta.json")))
	if err != nil {
		t.Fatalf("load links.meta.json: %v", err)
	}
	return m
}

// problemOf is the place problem of err, "" for nil or another error.
func problemOf(err error) string {
	var pe *som.SpecPlaceError
	if errors.As(err, &pe) {
		return pe.Problem
	}
	return ""
}

func TestSpecPlaceGrammar(t *testing.T) {
	p, err := som.ParseSpecPlace("./FRE/REQDEP/RQDEP.description")
	if err != nil {
		t.Fatal(err)
	}
	if !p.Scoped || !reflect.DeepEqual(p.Prefix, []string{"FRE", "REQDEP"}) ||
		p.SectionID != "RQDEP" || p.Slot != "description" {
		t.Fatalf("parsed %+v", p)
	}
	if p.String() != "./FRE/REQDEP/RQDEP.description" {
		t.Fatalf("String() = %q", p.String())
	}
	if h, _ := som.ParseSpecPlace("FRE.@headline"); h.Slot != "@headline" {
		t.Fatalf("headline slot = %q", h.Slot)
	}
	bare, _ := som.ParseSpecPlace("FRE-REQU-LST")
	if got := canonJSON(t, bare.ToJSON()); got != `{"prefix":[],"scoped":false,"sectionId":"FRE-REQU-LST"}` {
		t.Fatalf("bare ToJSON = %s", got)
	}
	for _, bad := range []string{"", "./", "-X", "FRE.", "FRE.a-b", "FRE/.x", "FRE..x"} {
		if som.TryParseSpecPlace(bad) != nil {
			t.Errorf("%q parsed as a place", bad)
		}
	}
	if _, err := som.ParseSpecPlace("a b"); problemOf(err) != som.SpecPlaceProblemMalformed {
		t.Fatalf("ParseSpecPlace(a b) = %v", err)
	}
}

func TestSpecPlaceFilterGrammar(t *testing.T) {
	f, err := som.ParseSpecPlaceFilter("./FRE.priority=must|should")
	if err != nil {
		t.Fatal(err)
	}
	if !f.Scoped || f.Field != "priority" || !reflect.DeepEqual(f.Values, []string{"must", "should"}) {
		t.Fatalf("parsed %+v", f)
	}
	if !f.Matches([]string{"could", " should "}) {
		t.Error("the second alternative, trimmed, does not match")
	}
	if f.Matches([]string{"could"}) || f.Matches(nil) {
		t.Error("a value outside the alternatives matches")
	}
	every, _ := som.ParseSpecPlaceFilter("FRE")
	if !every.Matches(nil) {
		t.Error("a filter without a field does not match every entry")
	}
	if every.Place().Text != "FRE" || f.Place().Text != "./FRE" {
		t.Fatalf("places %q, %q", every.Place().Text, f.Place().Text)
	}
	for _, bad := range []string{"FRE.priority", "FRE.priority=", "FRE.priority=a||b", "FRE.9x=a", ".x=a"} {
		if som.TryParseSpecPlaceFilter(bad) != nil {
			t.Errorf("%q parsed as a filter", bad)
		}
	}
}

func TestSpecPlaceResolution(t *testing.T) {
	refl := som.NewSpecReflection(linksModel(t))
	item := "BLU/requirements/REQ-ITEM-LST-1"
	resolve := func(place, anchor string) (*som.SpecPlaceResolution, error) {
		p, err := som.ParseSpecPlace(place)
		if err != nil {
			t.Fatal(err)
		}
		return p.Resolve(refl, anchor)
	}
	r, err := resolve("REQD.description", item)
	if err != nil {
		t.Fatal(err)
	}
	if r.Kind != som.SpecPlaceKindFormField || r.Field() != "description" || r.FormField == nil {
		t.Fatalf("resolved %+v", r)
	}
	for _, c := range []struct{ place, anchor, problem string }{
		{"REQD", "BLU/nowhere", som.SpecPlaceProblemAnchorUnresolved},
		{"./REQD", "BLU", som.SpecPlaceProblemNotScoped},
		{"NOPE", "BLU", som.SpecPlaceProblemUnresolved},
		{"REQD.@nope", item, som.SpecPlaceProblemReservedSlot},
		{"REQD.nope", item, som.SpecPlaceProblemNoSuchField},
	} {
		if _, err := resolve(c.place, c.anchor); problemOf(err) != c.problem {
			t.Errorf("%s under %s: %v, want %s", c.place, c.anchor, err, c.problem)
		}
	}
	// The filter reports with its own text.
	f, _ := som.ParseSpecPlaceFilter("NOPE.x=1")
	_, err = f.Resolve(refl, "BLU")
	var pe *som.SpecPlaceError
	if !errors.As(err, &pe) || pe.Text != "NOPE.x=1" || !strings.Contains(err.Error(), "NOPE.x=1") {
		t.Fatalf("filter error %v", err)
	}
}

func TestSpecSectionPositionsAndSameAs(t *testing.T) {
	refl := som.NewSpecReflection(linksModel(t))
	positions := som.SpecSectionPositions(refl, "Blueprint")
	if len(positions) == 0 || positions[0].Path != "BLU" {
		t.Fatalf("positions %+v", positions)
	}
	if positions[0].IsMember || positions[0].Member != nil {
		t.Error("the root position is a member")
	}
	items := false
	for _, p := range positions {
		if strings.Contains(p.Path, "-*") {
			items = true
		}
	}
	if !items {
		t.Error("no list-item position")
	}
	if got := som.SpecSectionPositions(refl, "Nope"); len(got) != 0 {
		t.Errorf("unknown root: %+v", got)
	}
	bindings := som.SpecSameAsBindings(refl, "Blueprint")
	if len(bindings) != 1 || bindings[0].HolderPath == "" {
		t.Fatalf("bindings %+v", bindings)
	}
	if got := som.SpecSameAsBindings(refl, "Nope"); len(got) != 0 {
		t.Errorf("unknown root: %+v", got)
	}
}

func TestSpecLinkReaderDefaults(t *testing.T) {
	// An absent key takes the annotation's default; an enum constant loses
	// its type prefix.
	d := som.SpecDerivationFromArguments(map[string]any{"source": "X", "kind": "DerivationKind.rows"})
	if d.Kind != "rows" {
		t.Fatalf("kind %q", d.Kind)
	}
	if got := canonJSON(t, d.ToJSON()); got != `{"kind":"rows","map":{},"source":"X","take":[]}` {
		t.Fatalf("derivation ToJSON = %s", got)
	}
	if som.SpecDerivationFromArguments(map[string]any{}).Kind != "copy" {
		t.Error("the default kind is not copy")
	}
	s := som.SpecSummaryOfFromArguments(map[string]any{"detail": "D-LST"})
	if got := canonJSON(t, s.ToJSON()); got != `{"detail":"D-LST","relation":"subset","repeats":{}}` {
		t.Fatalf("summary ToJSON = %s", got)
	}
	if !(&som.SpecInverseOf{Fields: []string{"@self"}}).Symmetric() {
		t.Error("@self is not symmetric")
	}
	if (&som.SpecInverseOf{Fields: []string{"@self", "X.y"}}).Symmetric() {
		t.Error("@self with another end is symmetric")
	}
	e := som.SpecExtractsLinksFromAnnotation(&som.SpecAnnotation{
		Name: "ExtractsLinks", Arguments: map[string]any{"ref": "L.ref", "from": []any{"A.b", nil}},
	})
	if got := canonJSON(t, e.ToJSON()); got != `{"from":["A.b"],"mode":"generate","ref":"L.ref","set":{}}` {
		t.Fatalf("extracts ToJSON = %s", got)
	}
	sync := som.SpecSyncFromAnnotation(&som.SpecAnnotation{
		Name:      "SyncedWith",
		Arguments: map[string]any{"document": "D", "relations": []any{map[string]any{"place": "P"}, "junk"}},
	})
	if len(sync.Relations) != 1 || canonJSON(t, sync.Relations[0].ToJSON()) != `{"place":"P","relation":"equal"}` {
		t.Fatalf("sync relations %+v", sync.Relations)
	}
	if got := canonJSON(t, (&som.SpecSameAs{}).ToJSON()); got != `{}` {
		t.Fatalf("empty same-as ToJSON = %s", got)
	}
}

// TestSpecLinkReaderKeepsMetaOrder: a string → string argument keeps the order
// the meta writes it in, not Go's map order.
func TestSpecLinkReaderKeepsMetaOrder(t *testing.T) {
	var ann som.SpecAnnotation
	raw := `{"name":"SummaryOf","arguments":{"detail":"D-LST","repeats":{"Z.a":"1","A.b":"2","M.c":"3"}}}`
	if err := json.Unmarshal([]byte(raw), &ann); err != nil {
		t.Fatal(err)
	}
	cls := &som.SpecClass{Name: "C", Annotations: []*som.SpecAnnotation{&ann}}
	var keys []string
	for _, p := range cls.SummaryOf().Repeats {
		keys = append(keys, p.Key)
	}
	if strings.Join(keys, ",") != "Z.a,A.b,M.c" {
		t.Fatalf("repeats order %v", keys)
	}
}

func TestSpecLinkModelAccessors(t *testing.T) {
	model := linksModel(t)
	req := model.Classes["Requirement"]
	if n := len(req.FieldNamed("links").AnnotationsNamed("ExtractsLinks")); n != 2 {
		t.Fatalf("ExtractsLinks annotations: %d", n)
	}
	if model.Classes["Blueprint"].SyncedWith() != nil {
		t.Error("Blueprint carries a sync")
	}
	if model.Classes["Blueprint"].IsCodeSpecsProjection() {
		t.Error("Blueprint is a CodeSpecs projection")
	}
}
