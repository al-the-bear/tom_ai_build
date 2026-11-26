package tests

// The stripped renditions of the conformance run (SOM §11.10):
// strip_cases.json, read like Dart's strip_case_runner.dart. TestConformance
// calls testStripCases.

import (
	"encoding/json"
	"errors"
	"reflect"
	"testing"
	"unicode/utf16"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// stripTable mirrors corpus/strip_cases.json: the strip of one value
// (`cases`), the option names (`usageCases`), the readable header
// (`headerCases`) and the strip of a document (`documentCases`).
type stripTable struct {
	Cases []struct {
		Name               string          `json:"name"`
		Text               string          `json:"text"`
		Drop               []string        `json:"drop"`
		Unmark             []string        `json:"unmark"`
		Appendix           []string        `json:"appendix"`
		AppendixReferences bool            `json:"appendixReferences"`
		Expect             json.RawMessage `json:"expect"`
	} `json:"cases"`
	UsageCases []struct {
		Name               string          `json:"name"`
		Drop               []string        `json:"drop"`
		Unmark             []string        `json:"unmark"`
		Appendix           []string        `json:"appendix"`
		AppendixReferences bool            `json:"appendixReferences"`
		HeadingDivs        bool            `json:"headingDivs"`
		Expect             json.RawMessage `json:"expect"`
	} `json:"usageCases"`
	HeaderCases []struct {
		Name   string          `json:"name"`
		Line   string          `json:"line"`
		Expect json.RawMessage `json:"expect"`
	} `json:"headerCases"`
	DocumentCases []struct {
		Name               string           `json:"name"`
		State              som.DocumentJson `json:"state"`
		Model              *bool            `json:"model"`
		RootType           string           `json:"rootType"`
		Drop               []string         `json:"drop"`
		Unmark             []string         `json:"unmark"`
		Appendix           []string         `json:"appendix"`
		AppendixReferences bool             `json:"appendixReferences"`
		HeadingDivs        bool             `json:"headingDivs"`
		Source             *struct {
			File     string `json:"file"`
			Revision string `json:"revision"`
			Commit   string `json:"commit"`
			Dirty    bool   `json:"dirty"`
		} `json:"source"`
		Expect json.RawMessage `json:"expect"`
	} `json:"documentCases"`
}

// jsonValue is v through JSON: maps, slices and float64s, as the corpus
// decodes.
func jsonValue(t *testing.T, v interface{}) interface{} {
	var out interface{}
	if err := json.Unmarshal([]byte(canonJSON(t, v)), &out); err != nil {
		t.Fatalf("re-decode: %v", err)
	}
	return out
}

func rawValue(t *testing.T, raw json.RawMessage) interface{} {
	var out interface{}
	if err := json.Unmarshal(raw, &out); err != nil {
		t.Fatalf("decode expect: %v", err)
	}
	return out
}

func stripOptionsJSON(o som.SpecStripOptions) map[string]interface{} {
	return map[string]interface{}{
		"drop":               som.SpecStripOptionsOrdered(o.Drop),
		"unmark":             som.SpecStripOptionsOrdered(o.Unmark),
		"appendix":           som.SpecStripOptionsOrdered(o.Appendix),
		"appendixReferences": o.AppendixReferences,
		"headingDivs":        o.HeadingDivs,
	}
}

// unstrip is stripped with every piece put back at its anchor (UTF-16
// offsets): the original.
func unstrip(stripped string, pieces []som.SpecStripPiece) string {
	s := utf16.Encode([]rune(stripped))
	var out []uint16
	at := 0
	for _, p := range pieces {
		out = append(out, s[at:p.Anchor]...)
		out = append(out, utf16.Encode([]rune(p.Removed))...)
		at = p.Anchor + len(utf16.Encode([]rune(p.Inserted)))
	}
	out = append(out, s[at:]...)
	return string(utf16.Decode(out))
}

func testStripCases(c *checker, t *testing.T, model *som.SpecModel) {
	var table stripTable
	readJSON(t, "strip_cases.json", &table)
	c.check("strip.tables", len(table.Cases) > 0 && len(table.UsageCases) > 0 &&
		len(table.HeaderCases) > 0 && len(table.DocumentCases) > 0, "a table of strip_cases.json is empty")
	schema, err := som.DocSpecsSchemaFromYamlText(readCorpus(t, "docspecs_schema.yaml"))
	if err != nil {
		t.Fatalf("docspecs schema: %v", err)
	}
	for _, cc := range table.Cases {
		name := "strip[" + cc.Name + "]"
		o, err := som.SpecStripOptionsFromNames(cc.Drop, cc.Unmark, cc.Appendix, cc.AppendixReferences, false)
		if err != nil {
			c.check(name, false, "options: "+err.Error())
			continue
		}
		r := som.StripNotationText(cc.Text, o)
		got, want := jsonValue(t, r.ToJSON()), rawValue(t, cc.Expect)
		c.check(name, reflect.DeepEqual(got, want), "got "+canonJSON(t, got)+" want "+canonJSON(t, want))
		c.check(name+".pieces", unstrip(r.Text, r.Pieces) == cc.Text, "pieces do not restore")
		if len(cc.Drop) == 1 && cc.Drop[0] == "comments" {
			c.check(name+".stripAnnotationsText", r.Text == som.StripAnnotationsText(cc.Text), r.Text)
		}
	}
	for _, cc := range table.UsageCases {
		var got interface{}
		o, err := som.SpecStripOptionsFromNames(cc.Drop, cc.Unmark, cc.Appendix, cc.AppendixReferences, cc.HeadingDivs)
		var usage *som.SpecStripUsageError
		switch {
		case err == nil:
			got = jsonValue(t, stripOptionsJSON(o))
		case errors.As(err, &usage):
			got = map[string]interface{}{"error": usage.Message}
		default:
			got = "error " + err.Error()
		}
		want := rawValue(t, cc.Expect)
		c.check("strip.usage["+cc.Name+"]", reflect.DeepEqual(got, want),
			"got "+canonJSON(t, got)+" want "+canonJSON(t, want))
	}
	for _, cc := range table.HeaderCases {
		h := som.ParseSpecReadableHeader(cc.Line)
		var got interface{}
		if h != nil {
			o := stripOptionsJSON(h.Options)
			if h.Source != nil {
				opt := func(s string) interface{} {
					if s == "" {
						return nil
					}
					return s
				}
				o["source"] = map[string]interface{}{
					"file":     h.Source.File,
					"revision": opt(h.Source.Revision),
					"commit":   opt(h.Source.Commit),
					"dirty":    h.Source.Dirty,
				}
			}
			o["format"] = h.Format()
			got = jsonValue(t, o)
			again := som.ParseSpecReadableHeader(h.Format())
			c.check("strip.header["+cc.Name+"].inverse", again != nil && again.Format() == h.Format(), h.Format())
		}
		want := rawValue(t, cc.Expect)
		c.check("strip.header["+cc.Name+"]", reflect.DeepEqual(got, want),
			"got "+canonJSON(t, got)+" want "+canonJSON(t, want))
	}
	for _, cc := range table.DocumentCases {
		name := "strip.document[" + cc.Name + "]"
		o, err := som.SpecStripOptionsFromNames(cc.Drop, cc.Unmark, cc.Appendix, cc.AppendixReferences, cc.HeadingDivs)
		if err != nil {
			c.check(name, false, "options: "+err.Error())
			continue
		}
		doc := som.NewSpecDocument()
		state := cc.State
		doc.LoadJSON(&state)
		extra := som.SpecDocumentStripOptions{RootType: cc.RootType}
		if cc.Model == nil || *cc.Model {
			extra.Model = model
			extra.Schema = schema
		}
		if cc.Source != nil {
			extra.Source = &som.SpecReadableSource{File: cc.Source.File, Revision: cc.Source.Revision,
				Commit: cc.Source.Commit, Dirty: cc.Source.Dirty}
		}
		r := som.SpecDocumentStrip{}.Strip(doc, o, extra)
		kept := []interface{}{}
		for _, k := range r.Kept {
			kept = append(kept, k.Ref.ToJSON())
		}
		appendix := []interface{}{}
		for _, e := range r.Appendix {
			appendix = append(appendix, e.ToJSON())
		}
		findings := []interface{}{}
		for _, f := range r.Findings {
			findings = append(findings, f.Kind)
		}
		var readable interface{}
		if r.Readable != "" {
			readable = r.Readable
		}
		got := jsonValue(t, map[string]interface{}{
			"document":       r.Document.ToJSON(),
			"kept":           kept,
			"removedItems":   r.RemovedItems,
			"appendix":       appendix,
			"dropped":        r.Dropped,
			"unmarked":       r.Unmarked,
			"appended":       r.Appended,
			"marksDropped":   r.MarksDropped,
			"readableHeader": r.ReadableHeader,
			"readable":       readable,
			"findings":       findings,
		})
		want := rawValue(t, cc.Expect)
		// The expected document goes through DocumentJson as the actual one.
		if m, ok := want.(map[string]interface{}); ok {
			var d som.DocumentJson
			if err := json.Unmarshal([]byte(canonJSON(t, m["document"])), &d); err == nil {
				m["document"] = jsonValue(t, &d)
			}
		}
		c.check(name, reflect.DeepEqual(got, want), "got "+canonJSON(t, got)+" want "+canonJSON(t, want))
	}
}
