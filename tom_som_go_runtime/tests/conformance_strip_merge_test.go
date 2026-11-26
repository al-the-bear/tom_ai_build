package tests

// The merge back of an edited stripped rendition (SOM §11.10):
// strip_merge_cases.json, read like the other runtimes' runners. TestConformance
// calls testStripMergeCases.

import (
	"encoding/json"
	"errors"
	"reflect"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// stripMergeSwitches are a case's strip switches.
type stripMergeSwitches struct {
	Drop               []string `json:"drop"`
	Unmark             []string `json:"unmark"`
	Appendix           []string `json:"appendix"`
	AppendixReferences bool     `json:"appendixReferences"`
}

func (s stripMergeSwitches) options() (som.SpecStripOptions, error) {
	return som.SpecStripOptionsFromNames(s.Drop, s.Unmark, s.Appendix, s.AppendixReferences, false)
}

// stripMergeTable mirrors corpus/strip_merge_cases.json.
type stripMergeTable struct {
	ValueCases []struct {
		stripMergeSwitches
		Name     string          `json:"name"`
		Original string          `json:"original"`
		Edits    [][]string      `json:"edits"`
		Expect   json.RawMessage `json:"expect"`
	} `json:"valueCases"`
	DocumentCases []struct {
		stripMergeSwitches
		Name    string              `json:"name"`
		State   som.DocumentJson    `json:"state"`
		Edits   [][]string          `json:"edits"`
		Options *stripMergeSwitches `json:"options"`
		Source  *struct {
			File     string `json:"file"`
			Revision string `json:"revision"`
			Commit   string `json:"commit"`
			Dirty    bool   `json:"dirty"`
		} `json:"source"`
		CurrentRevision string                      `json:"currentRevision"`
		Current         *som.DocumentJson           `json:"current"`
		Base            *som.DocumentJson           `json:"base"`
		Commits         map[string]som.DocumentJson `json:"commits"`
		Expect          json.RawMessage             `json:"expect"`
	} `json:"documentCases"`
}

// stripMergeApplyEdits is text with each [find, replace] of edits applied;
// each find occurs exactly once (an empty find replaces an empty text).
func stripMergeApplyEdits(text string, edits [][]string) (string, error) {
	out := text
	for _, e := range edits {
		if len(e) != 2 {
			return "", errors.New("bad edit")
		}
		find, replace := e[0], e[1]
		if find == "" {
			if out != "" {
				return "", errors.New("an empty find needs an empty text")
			}
			out = replace
			continue
		}
		if strings.Count(out, find) != 1 {
			return "", errors.New("the edit \"" + find + "\" does not occur exactly once")
		}
		out = strings.Replace(out, find, replace, 1)
	}
	return out, nil
}

func stripMergeDoc(j som.DocumentJson) *som.SpecDocument {
	d := som.NewSpecDocument()
	d.LoadJSON(&j)
	return d
}

func testStripMergeCases(c *checker, t *testing.T, model *som.SpecModel) {
	var table stripMergeTable
	readJSON(t, "strip_merge_cases.json", &table)
	c.check("stripMerge.tables", len(table.ValueCases) > 0 && len(table.DocumentCases) > 0,
		"a table of strip_merge_cases.json is empty")
	schema, err := som.DocSpecsSchemaFromYamlText(readCorpus(t, "docspecs_schema.yaml"))
	if err != nil {
		t.Fatalf("docspecs schema: %v", err)
	}
	for _, cc := range table.ValueCases {
		name := "stripMerge.value[" + cc.Name + "]"
		o, err := cc.options()
		if err != nil {
			c.check(name, false, "options: "+err.Error())
			continue
		}
		s := som.StripNotationText(cc.Original, o)
		edited, err := stripMergeApplyEdits(s.Text, cc.Edits)
		if err != nil {
			c.check(name, false, err.Error())
			continue
		}
		got := jsonValue(t, som.MergeStrippedValue(cc.Original, s.Text, edited, s.Pieces).ToJSON())
		want := rawValue(t, cc.Expect)
		c.check(name, reflect.DeepEqual(got, want), "got "+canonJSON(t, got)+" want "+canonJSON(t, want))
	}
	for _, cc := range table.DocumentCases {
		name := "stripMerge.document[" + cc.Name + "]"
		state := stripMergeDoc(cc.State)
		var source *som.SpecReadableSource
		if cc.Source != nil {
			source = &som.SpecReadableSource{File: cc.Source.File, Revision: cc.Source.Revision,
				Commit: cc.Source.Commit, Dirty: cc.Source.Dirty}
		}
		o, err := cc.options()
		if err != nil {
			c.check(name, false, "options: "+err.Error())
			continue
		}
		stripped := som.SpecDocumentStrip{}.Strip(state, o, som.SpecDocumentStripOptions{Model: model,
			Schema: schema, Source: source})
		edited, err := stripMergeApplyEdits(stripped.Readable, cc.Edits)
		if err != nil {
			c.check(name, false, err.Error())
			continue
		}
		extra := som.SpecStripMergeOptions{Model: model, Schema: schema, CurrentRevision: cc.CurrentRevision,
			LoadBase: func(s som.SpecReadableSource) *som.SpecDocument {
				if j, ok := cc.Commits[s.Commit]; ok && s.Commit != "" {
					return stripMergeDoc(j)
				}
				return nil
			}}
		if cc.Options != nil {
			given, err := cc.Options.options()
			if err != nil {
				c.check(name, false, "options: "+err.Error())
				continue
			}
			extra.Options = &given
		}
		if cc.Base != nil {
			extra.Base = stripMergeDoc(*cc.Base)
		}
		original := state
		if cc.Current != nil {
			original = stripMergeDoc(*cc.Current)
		}
		want, _ := rawValue(t, cc.Expect).(map[string]interface{})
		r, err := som.SpecStripMerge{}.Merge(original, edited, extra)
		if err != nil {
			var usage *som.SpecStripUsageError
			ok := errors.As(err, &usage) && reflect.DeepEqual(interface{}(usage.Message), want["error"])
			c.check(name, ok, "error "+err.Error()+" want "+canonJSON(t, want["error"]))
			continue
		}
		got := jsonValue(t, map[string]interface{}{
			"exitCode": r.ExitCode(),
			"stale":    r.Stale,
			"report":   r.Report(),
			"error":    nil,
		}).(map[string]interface{})
		same, detail := true, ""
		for _, key := range []string{"exitCode", "stale", "report", "error"} {
			if !reflect.DeepEqual(got[key], want[key]) {
				same = false
				detail = key + ": got " + canonJSON(t, got[key]) + " want " + canonJSON(t, want[key])
			}
		}
		var gotDoc, wantDoc interface{}
		if r.Document != nil {
			gotDoc = jsonValue(t, r.Document.ToJSON())
		}
		if wd, ok := want["document"]; ok && wd != nil {
			var d som.DocumentJson
			if err := json.Unmarshal([]byte(canonJSON(t, wd)), &d); err == nil {
				wantDoc = jsonValue(t, &d)
			}
		}
		if !reflect.DeepEqual(gotDoc, wantDoc) {
			same = false
			detail = "document: got " + canonJSON(t, gotDoc) + " want " + canonJSON(t, wantDoc)
		}
		c.check(name, same, detail)
	}
}
