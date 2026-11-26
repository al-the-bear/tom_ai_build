package tests

// The section-link part of the conformance suite (`tom_specs_model_rules.md`
// §9.7): the typed readers of the link annotations and the place / filter
// grammar (`link_reader_cases.json` over `links.meta.json`), the link checks
// of one document (`link_validation_cases.json`), and the typed values and
// headlines under review (the `typedCases` of `inline_mark_cases.json` /
// `change_mark_cases.json`). A port of the Python runner's `test_link_readers`
// / `test_link_validation` / `_run_typed_mark_cases`.

import (
	"encoding/json"
	"errors"
	"reflect"
	"sort"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// --- typed values and headlines under review ------------------------------------

// runTypedMarkCases replays the typedCases of inline_mark_cases.json /
// change_mark_cases.json like the scripted annotation cases.
func runTypedMarkCases(c *checker, t *testing.T, label string, model *som.SpecModel, tree *som.SomMetaTree, cases []annotationCase) {
	c.check(label+".cases", len(cases) > 0, "no typedCases")
	for _, cc := range cases {
		got := runAnnotationCase(t, model, tree, cc, false)
		want := toGenericJSON(t, cc.Expect)
		c.check(label+"["+cc.Name+"]", reflect.DeepEqual(got, want),
			"got "+canonJSON(t, got)+" want "+canonJSON(t, want))
	}
}

// validationPairs is the findings as `{path, code}`, never null.
func validationPairs(errs []som.SpecValidationError) []any {
	out := []any{}
	for _, e := range errs {
		out = append(out, map[string]any{"path": e.Path, "code": e.Code})
	}
	return out
}

// typedRead is the typed reading of the value at `path` / `field`: an enum by
// its name, `int`, `double`, `num` and `bool` as numbers and booleans, nil when
// the text reads as nothing — with any inline mark rejected (its old value).
func typedRead(model *som.SpecModel, doc *som.SpecDocument, op map[string]any) any {
	path := opString(op, "path")
	field, hasField := op["field"].(string)
	res := som.NewSpecReflection(model).Resolve(path)
	var spec *som.FormFieldSpec
	if hasField && res != nil && res.Field != nil {
		for _, ff := range res.Field.FormFields {
			if ff.Name == field {
				spec = ff
				break
			}
		}
	}
	var raw string
	var present bool
	if hasField {
		raw, present = doc.FormField(path, field)
	} else {
		raw, present = doc.Content(path)
	}
	typeName := ""
	var values []string
	switch {
	case spec != nil:
		typeName, values = spec.Type, spec.EnumValues
	case res != nil && res.Field != nil:
		typeName, values = res.Field.Type, res.Field.EnumValues
	}
	if len(values) > 0 {
		if v, ok := som.SomParseEnumName(raw, values); ok {
			return v
		}
		return nil
	}
	switch som.SomScalarBase(typeName) {
	case "int":
		if v, ok := som.SomParseInt(raw); ok {
			return v
		}
		return nil
	case "double":
		if v, ok := som.SomParseDouble(raw); ok {
			return v
		}
		return nil
	case "num":
		if v, ok := som.SomParseNum(raw); ok {
			return v
		}
		return nil
	case "bool":
		if v, ok := som.SomParseBool(raw); ok {
			return v
		}
		return nil
	}
	if !present {
		return nil
	}
	return som.SomTypedReading(raw)
}

// --- the section-link readers ------------------------------------------------------

// linkReadBack is what the readers return for model, in canonical JSON: every
// class sync, every member link, every form-field qualifier, and the
// `@SameAs` bindings per root. Classes by name, fields and form fields in
// declaration order (the Dart test's `linkReadBack`).
func linkReadBack(model *som.SpecModel) map[string]any {
	names := make([]string, 0, len(model.Classes))
	for n := range model.Classes {
		names = append(names, n)
	}
	sort.Strings(names)
	refl := som.NewSpecReflection(model)
	classes, fields, formFields := []any{}, []any{}, []any{}
	for _, n := range names {
		if sync := model.Classes[n].SyncedWith(); sync != nil {
			classes = append(classes, map[string]any{"class": n, "syncedWith": sync.ToJSON()})
		}
	}
	for _, n := range names {
		for _, f := range model.Classes[n].Fields {
			sync, summary, derived := f.SyncedWith(), f.SummaryOf(), f.DerivedFrom()
			extracts, sameAs := f.ExtractsLinks(), f.SameAs()
			if sync == nil && summary == nil && derived == nil && len(extracts) == 0 && sameAs == nil {
				continue
			}
			row := map[string]any{"class": n, "field": f.Name}
			if sync != nil {
				row["syncedWith"] = sync.ToJSON()
			}
			if summary != nil {
				row["summaryOf"] = summary.ToJSON()
			}
			if derived != nil {
				row["derivedFrom"] = derived.ToJSON()
			}
			if len(extracts) > 0 {
				list := []any{}
				for _, e := range extracts {
					list = append(list, e.ToJSON())
				}
				row["extractsLinks"] = list
			}
			if sameAs != nil {
				row["sameAs"] = sameAs.ToJSON()
			}
			fields = append(fields, row)
		}
	}
	for _, n := range names {
		for _, f := range model.Classes[n].Fields {
			for _, ff := range f.FormFields {
				if ff.DerivedFrom == nil && ff.InverseOf == nil && ff.SummaryOf == nil {
					continue
				}
				row := map[string]any{"class": n, "field": f.Name, "formField": ff.Name}
				if ff.DerivedFrom != nil {
					row["derivedFrom"] = ff.DerivedFrom.ToJSON()
				}
				if ff.InverseOf != nil {
					row["inverseOf"] = ff.InverseOf.ToJSON()
				}
				if ff.SummaryOf != nil {
					row["summaryOf"] = ff.SummaryOf.ToJSON()
				}
				formFields = append(formFields, row)
			}
		}
	}
	bindings := []any{}
	for _, r := range model.Roots {
		for _, b := range som.SpecSameAsBindings(refl, r.Type) {
			bindings = append(bindings, b.ToJSON())
		}
	}
	return map[string]any{
		"classes":        classes,
		"fields":         fields,
		"formFields":     formFields,
		"sameAsBindings": bindings,
		"classCount":     len(model.Classes),
	}
}

// placeProblem is the problem of a place error; ok=false for any other error.
func placeProblem(err error) (string, bool) {
	var pe *som.SpecPlaceError
	if errors.As(err, &pe) {
		return pe.Problem, true
	}
	return "", false
}

type linkTextCase struct {
	Name   string          `json:"name"`
	Intent []string        `json:"intent"`
	Text   string          `json:"text"`
	Anchor *string         `json:"anchor"`
	Stored []any           `json:"stored"`
	Expect json.RawMessage `json:"expect"`
}

// placeCase is one place case: the text parsed, then resolved under `anchor`
// when given.
func placeCase(refl *som.SpecReflection, c linkTextCase) (any, error) {
	place := som.TryParseSpecPlace(c.Text)
	if place == nil {
		return map[string]any{"problem": som.SpecPlaceProblemMalformed}, nil
	}
	if c.Anchor == nil {
		return map[string]any{"parsed": place.ToJSON()}, nil
	}
	r, err := place.Resolve(refl, *c.Anchor)
	if err != nil {
		problem, ok := placeProblem(err)
		if !ok {
			return nil, err
		}
		return map[string]any{"parsed": place.ToJSON(), "problem": problem}, nil
	}
	return map[string]any{"parsed": place.ToJSON(), "resolved": r.ToJSON()}, nil
}

// filterCase is one filter case: the text parsed, resolved under `anchor` when
// given, and matched against `stored` when given.
func filterCase(refl *som.SpecReflection, c linkTextCase) (any, error) {
	f := som.TryParseSpecPlaceFilter(c.Text)
	if f == nil {
		return map[string]any{"problem": som.SpecPlaceProblemMalformed}, nil
	}
	out := map[string]any{"parsed": f.ToJSON()}
	if c.Stored != nil {
		stored := []string{}
		for _, v := range c.Stored {
			if s, ok := v.(string); ok {
				stored = append(stored, s)
			} else {
				b, _ := json.Marshal(v)
				stored = append(stored, string(b))
			}
		}
		out["matches"] = f.Matches(stored)
	}
	if c.Anchor != nil {
		r, err := f.Resolve(refl, *c.Anchor)
		if err != nil {
			problem, ok := placeProblem(err)
			if !ok {
				return nil, err
			}
			out["problem"] = problem
		} else {
			out["resolved"] = r.ToJSON()
		}
	}
	return out, nil
}

// readerIntentHolds reports whether the reader-case intent token holds in the
// expectation e (the Dart test's `_readerIntentHolds`); known=false for an
// unknown token.
func readerIntentHolds(token string, e map[string]any) (holds, known bool) {
	list := func(key string) []any {
		l, _ := e[key].([]any)
		return l
	}
	anyRow := func(key string, pred func(map[string]any) bool) bool {
		for _, r := range list(key) {
			if m, ok := r.(map[string]any); ok && pred(m) {
				return true
			}
		}
		return false
	}
	has := func(key, member string) bool {
		return anyRow(key, func(m map[string]any) bool { _, ok := m[member]; return ok })
	}
	switch token {
	case "syncedWith":
		return len(list("classes")) > 0, true
	case "syncRelationWhere":
		return anyRow("classes", func(m map[string]any) bool {
			sync, _ := m["syncedWith"].(map[string]any)
			rels, _ := sync["relations"].([]any)
			for _, x := range rels {
				if xm, ok := x.(map[string]any); ok {
					if _, ok := xm["where"]; ok {
						return true
					}
				}
			}
			return false
		}), true
	case "summaryOf":
		return has("fields", "summaryOf"), true
	case "summaryOfDocument":
		return anyRow("fields", func(m map[string]any) bool {
			s, ok := m["summaryOf"].(map[string]any)
			if !ok {
				return false
			}
			_, ok = s["document"]
			return ok
		}), true
	case "derivedFrom":
		return has("fields", "derivedFrom"), true
	case "extractsLinksRepeated":
		return anyRow("fields", func(m map[string]any) bool {
			l, _ := m["extractsLinks"].([]any)
			return len(l) > 1
		}), true
	case "sameAs":
		return has("fields", "sameAs"), true
	case "formDerivedFrom":
		return has("formFields", "derivedFrom"), true
	case "formInverseOf":
		return has("formFields", "inverseOf"), true
	case "formSymmetric":
		return anyRow("formFields", func(m map[string]any) bool {
			inv, ok := m["inverseOf"].(map[string]any)
			if !ok {
				return false
			}
			fs, _ := inv["fields"].([]any)
			for _, f := range fs {
				if f == "@self" {
					return true
				}
			}
			return false
		}), true
	case "formSummaryOf":
		return has("formFields", "summaryOf"), true
	case "sameAsHolder":
		return has("sameAsBindings", "holder"), true
	case "loadsUnchanged":
		count, _ := e["classCount"].(float64)
		return count > 0 && len(list("classes")) == 0 && len(list("fields")) == 0 &&
			len(list("formFields")) == 0 && len(list("sameAsBindings")) == 0, true
	}
	return false, false
}

// linkTokens returns every string a text case's expectation shows: kinds,
// problems, and `matches` / `noMatch` (the Dart test's `_tokens`).
func linkTokens(e any) map[string]bool {
	out := map[string]bool{}
	var walk func(v any, key string)
	walk = func(v any, key string) {
		switch t := v.(type) {
		case []any:
			for _, x := range t {
				walk(x, "")
			}
		case map[string]any:
			for k, x := range t {
				walk(x, k)
			}
		case bool:
			if key == "matches" {
				if t {
					out["matches"] = true
				} else {
					out["noMatch"] = true
				}
			}
		case string:
			if key == "kind" || key == "problem" {
				out[t] = true
			}
		}
	}
	walk(e, "")
	return out
}

func testLinkReaders(c *checker, t *testing.T) {
	metaRaw := readCorpus(t, "links.meta.json")
	var table struct {
		Cases []struct {
			Name   string          `json:"name"`
			Model  *string         `json:"model"`
			Meta   json.RawMessage `json:"meta"`
			Intent []string        `json:"intent"`
			Expect json.RawMessage `json:"expect"`
		} `json:"cases"`
		TextCases struct {
			Places  []linkTextCase `json:"places"`
			Filters []linkTextCase `json:"filters"`
		} `json:"textCases"`
	}
	readJSON(t, "link_reader_cases.json", &table)
	c.check("links.reader.cases", len(table.Cases) > 0, "no cases in link_reader_cases.json")
	for _, cc := range table.Cases {
		name := "links.reader[" + cc.Name + "]"
		data := []byte(metaRaw)
		if cc.Model == nil || *cc.Model != "links.meta.json" {
			data = cc.Meta
		}
		want := jsonAny(t, cc.Expect)
		m, err := som.SpecModelFromJSON(data)
		if err != nil {
			c.check(name, false, "threw "+err.Error())
		} else {
			got := toGenericJSON(t, linkReadBack(m))
			c.check(name, reflect.DeepEqual(got, want), "got "+canonJSON(t, got)+" want "+canonJSON(t, want))
		}
		e, _ := want.(map[string]any)
		for _, token := range cc.Intent {
			holds, known := readerIntentHolds(token, e)
			detail := "does not hold"
			if !known {
				detail = "unknown intent token"
			}
			c.check("links.reader.intent["+cc.Name+": "+token+"]", known && holds, detail)
		}
	}
	model, err := som.SpecModelFromJSON([]byte(metaRaw))
	if err != nil {
		t.Fatalf("load links.meta.json: %v", err)
	}
	refl := som.NewSpecReflection(model)

	runText := func(kind string, cases []linkTextCase, run func(linkTextCase) (any, error)) {
		c.check("links."+kind+".cases", len(cases) > 0, "no "+kind+" cases")
		for _, cc := range cases {
			name := "links." + kind + "[" + cc.Name + "]"
			want := jsonAny(t, cc.Expect)
			got, err := run(cc)
			if err != nil {
				c.check(name, false, "threw "+err.Error())
			} else {
				g := toGenericJSON(t, got)
				c.check(name, reflect.DeepEqual(g, want), "got "+canonJSON(t, g)+" want "+canonJSON(t, want))
			}
			shown := linkTokens(want)
			for _, token := range cc.Intent {
				c.check("links."+kind+".intent["+cc.Name+": "+token+"]", shown[token], "")
			}
		}
	}
	runText("place", table.TextCases.Places, func(cc linkTextCase) (any, error) { return placeCase(refl, cc) })
	runText("filter", table.TextCases.Filters, func(cc linkTextCase) (any, error) { return filterCase(refl, cc) })

	// LR1: the class sync is read with its relations.
	reqs := model.Classes["Requirements"].SyncedWith()
	c.check("links.LR1.sync", reqs != nil && reqs.Document == "Detail" &&
		reflect.DeepEqual(reqs.DetailOnly, []string{"REQX"}) &&
		reflect.DeepEqual(reqs.HeldHere, []string{"REQ.owner"}) &&
		len(reqs.Relations) == 1 && reqs.Relations[0].Relation == "subset", "")
	crit := model.Classes["Criteria"].SyncedWith()
	c.check("links.LR1.where", crit != nil && len(crit.Relations) == 1 &&
		crit.Relations[0].Where == "CRITE.kind=functional|quality", "")
	c.check("links.LR1.none", model.Classes["Blueprint"].SyncedWith() == nil, "")

	// LR2: member links and the repeated @ExtractsLinks.
	req := model.Classes["Requirement"]
	links := req.FieldNamed("links").ExtractsLinks()
	var modes []string
	for _, x := range links {
		modes = append(modes, x.Mode)
	}
	c.check("links.LR2.modes", reflect.DeepEqual(modes, []string{"generate", "warn"}), strings.Join(modes, ","))
	c.check("links.LR2.set", len(links) > 0 && reflect.DeepEqual(som.SpecStringPairsMap(links[0].Set),
		map[string]string{"LNK.linkType": "namedInText"}), "")
	abstract := req.FieldNamed("abstract").DerivedFrom()
	c.check("links.LR2.copy", abstract != nil && abstract.Kind == "copy", "")
	pre := req.FieldNamed("prerequisites").DerivedFrom()
	c.check("links.LR2.map", pre != nil && reflect.DeepEqual(som.SpecStringPairsMap(pre.Map),
		map[string]string{"PRE.ref": "LNK-REF.ref"}), "")
	c.check("links.LR2.noSummary", req.FieldNamed("links").SummaryOf() == nil, "")

	// LR3: the form-field qualifiers.
	ff := func(cls, field, name string) *som.FormFieldSpec {
		for _, f := range model.Classes[cls].FieldNamed(field).FormFields {
			if f.Name == name {
				return f
			}
		}
		t.Fatalf("no form field %s.%s.%s", cls, field, name)
		return nil
	}
	conflicts := ff("Requirement", "constraints", "conflictsWith").DerivedFrom
	c.check("links.LR3.where", conflicts != nil && conflicts.Where == "LNK.linkType=conflict", "")
	sym := ff("Link", "ref", "ref").InverseOf
	c.check("links.LR3.symmetric", sym != nil && sym.Symmetric(), "")
	nsym := ff("Requirement", "trace", "relatedScreens").InverseOf
	c.check("links.LR3.notSymmetric", nsym != nil && !nsym.Symmetric(), "")
	focus := ff("Blueprint", "focus", "focusScreens").SummaryOf
	c.check("links.LR3.summaryDocument", focus != nil && focus.Document == "Screens", "")

	// LR4: the real model — S1 has one holder in each document.
	realRefl := som.NewSpecReflection(loadSomModel(t))
	for _, root := range []string{"D00SolutionBlueprint", "D10QualityAcceptancePlan"} {
		bindings := som.SpecSameAsBindings(realRefl, root)
		c.check("links.LR4["+root+"]", len(bindings) == 1 &&
			bindings[0].ClassName == "AcceptanceCriteriaList" &&
			bindings[0].Problem == "" &&
			strings.HasSuffix(bindings[0].CopyPath, "/detailedCriteria"),
			canonJSON(t, bindings))
	}

	// CO1–CO2: countOf reads the filter, `|` included.
	base := "BLU/requirements"
	doc := func(settled, total string) *som.SpecDocument {
		d := som.NewSpecDocument()
		for _, status := range []string{"approved", "done", "draft"} {
			item := d.AddListItem(base + "/REQ-ITEM-LST")
			d.SetFormField(item+"/content", "status", status)
		}
		d.SetFormField(base+"/REQS-SUM", "total", total)
		d.SetFormField(base+"/REQS-SUM", "settled", settled)
		return d
	}
	counts := func(d *som.SpecDocument) []string {
		out := []string{}
		for _, e := range som.ValidateDocument(model, d) {
			if e.Code == som.SpecValidationCodeCountMismatch {
				out = append(out, e.Path)
			}
		}
		return out
	}
	co := func(name string, got, want []string) {
		c.check(name, reflect.DeepEqual(got, want), "got "+canonJSON(t, got)+" want "+canonJSON(t, want))
	}
	co("links.CO1", counts(doc("2", "3")), []string{})
	co("links.CO2.settled", counts(doc("3", "3")), []string{base + "/REQS-SUM"})
	co("links.CO2.total", counts(doc("2", "2")), []string{base + "/REQS-SUM"})
}

// --- the link checks of one document --------------------------------------------------

type linkFinding struct {
	Path string `json:"path"`
	Code string `json:"code"`
}

type linkValidationCase struct {
	Name           string           `json:"name"`
	Intent         []string         `json:"intent"`
	State          som.DocumentJson `json:"state"`
	Errors         []linkFinding    `json:"errors"`
	InstanceErrors []linkFinding    `json:"instanceErrors"`
}

func findingPairs(errs []som.SpecValidationError) []linkFinding {
	out := []linkFinding{}
	for _, e := range errs {
		out = append(out, linkFinding{e.Path, e.Code})
	}
	return out
}

func testLinkValidation(c *checker, t *testing.T) {
	var table struct {
		Model string               `json:"model"`
		Cases []linkValidationCase `json:"cases"`
	}
	readJSON(t, "link_validation_cases.json", &table)
	metaName := table.Model
	if metaName == "" {
		metaName = "links.meta.json"
	}
	model, err := som.SpecModelFromJSON([]byte(readCorpus(t, metaName)))
	if err != nil {
		t.Fatalf("load %s: %v", metaName, err)
	}
	c.check("links.validate.cases", len(table.Cases) > 0, "no cases in link_validation_cases.json")
	provoked := map[string]bool{}
	for _, cc := range table.Cases {
		name := "links.validate[" + cc.Name + "]"
		for _, e := range cc.Errors {
			provoked[e.Code] = true
		}
		want := cc.Errors
		if want == nil {
			want = []linkFinding{}
		}
		wantInstance := cc.InstanceErrors
		if wantInstance == nil {
			wantInstance = []linkFinding{}
		}
		state := cc.State
		d := docFromState(&state)
		got := findingPairs(som.ValidateLinks(model, d))
		c.check(name+".errors", reflect.DeepEqual(got, want), "got "+canonJSON(t, got)+" want "+canonJSON(t, want))
		instance := findingPairs(som.ValidateDocument(model, d))
		c.check(name+".instanceErrors", reflect.DeepEqual(instance, wantInstance),
			"got "+canonJSON(t, instance)+" want "+canonJSON(t, wantInstance))
		codes := map[string]bool{}
		for _, e := range append(append([]linkFinding{}, cc.Errors...), cc.InstanceErrors...) {
			codes[e.Code] = true
		}
		for _, token := range cc.Intent {
			holds := codes[token]
			if token == "clean" {
				holds = len(codes) == 0
			}
			c.check("links.validate.intent["+cc.Name+": "+token+"]", holds, "")
		}
	}
	for _, code := range []string{
		som.SpecValidationCodeDerivedValueMismatch,
		som.SpecValidationCodeDerivedLookupMiss,
		som.SpecValidationCodeDuplicateLinkRow,
		som.SpecValidationCodeInverseMissing,
		som.SpecValidationCodeExtractedLinkMissing,
		som.SpecValidationCodeExtractedLinkStale,
		som.SpecValidationCodeSummaryNotInDetail,
		som.SpecValidationCodeDetailNotInSummary,
		som.SpecValidationCodeSummaryDuplicate,
		som.SpecValidationCodeSameAsMismatch,
		som.SpecValidationCodeLinkValuePending,
	} {
		c.check("links.validate.provoked["+code+"]", provoked[code], "")
	}
}
