package tests

// The rendition's navigation and generated parts in the conformance suite
// (`link_rendition_cases.json`, SOM §11.2, §11.11, §11.12): each case's
// document rendered with file stem `links`, the rendition (its markers
// deleted or edited where the case says) handed to the parser, and the
// rendition of what it staged; then the schema tier over the real model
// (`uam_requirements_cut.json`). A port of the Python runner's
// `test_link_rendition` / `test_rendition_schema_tier`.

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"sort"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// renditionOf is doc rendered as its root's rendition: the first root of
// model it holds a value under.
func renditionOf(model *som.SpecModel, doc *som.SpecDocument, fileStem string, markers, generated bool) (string, error) {
	var root *som.SpecRoot
	for _, r := range model.Roots {
		seg := r.SectionID
		if seg == "" {
			seg = r.Type
		}
		if doc.HasValuesUnder(seg) {
			root = r
			break
		}
	}
	if root == nil {
		return "", errors.New("no root holds a value")
	}
	codec := som.NewSpecDocumentMarkdown(model, doc)
	codec.FileStem = fileStem
	codec.LinkedMarkers = markers
	codec.GeneratedParts = generated
	return codec.ExportRoot(root)
}

var renditionMarkerLineRE = regexp.MustCompile(`^\[.*\]\{\.linked\}$`)

// withoutMarkers is markdown with its `linked` marker paragraphs removed.
func withoutMarkers(markdown string) string {
	lines := strings.Split(markdown, "\n")
	var out []string
	for i := 0; i < len(lines); i++ {
		if renditionMarkerLineRE.MatchString(lines[i]) {
			if i+1 < len(lines) && lines[i+1] == "" {
				i++
			}
			continue
		}
		out = append(out, lines[i])
	}
	return strings.Join(out, "\n")
}

// renditionCase is one rendition case, as the Dart test's `renditionCase`
// computes it.
func renditionCase(t *testing.T, models *setModels, fixture *som.SpecModel, cc setCase) (map[string]any, error) {
	model := models.modelOf(fixture, cc)
	doc := stateDocument(t, cc["state"])
	markers := true
	if b, ok := cc["linkedMarkers"].(bool); ok && !b {
		markers = false
	}
	generated := true
	if b, ok := cc["generatedParts"].(bool); ok && !b {
		generated = false
	}
	markdown, err := renditionOf(model, doc, "links", markers, generated)
	if err != nil {
		return nil, err
	}
	given := markdown
	if cc.flag("dropMarkers") {
		given = withoutMarkers(given)
	}
	if edits, ok := cc["edits"].([]any); ok {
		for _, e := range edits {
			pair := e.([]any)
			from, to := fmt.Sprint(pair[0]), fmt.Sprint(pair[1])
			if !strings.Contains(given, from) {
				return nil, fmt.Errorf("%s: the rendition has no %q", cc.name(), from)
			}
			given = strings.Replace(given, from, to, 1)
		}
	}
	parsed, err := som.SpecDocumentFromMarkdown(given, model)
	if err != nil {
		return nil, err
	}
	out := map[string]any{"markdown": markdown}
	if given != markdown {
		out["given"] = given
	}
	rejections := []any{}
	for _, r := range parsed.Rejections() {
		rejections = append(rejections, r.Reason)
	}
	out["rejections"] = rejections
	out["parseMatches"] = canonJSON(t, parsed.Document.ToJSON()) == canonJSON(t, doc.ToJSON())
	reemit, err := renditionOf(model, parsed.Document, "links", markers, generated)
	if err != nil {
		return nil, err
	}
	out["reemitMatches"] = reemit == markdown
	return out, nil
}

func mustMatch(pattern, text string) bool {
	return regexp.MustCompile(pattern).MatchString(text)
}

// renditionIntentHolds reports whether the rendition-case intent token holds
// in case cc (the Dart test's `_renditionIntentHolds`); known is false for an
// unknown token.
func renditionIntentHolds(t *testing.T, token string, cc setCase) (holds, known bool) {
	e, _ := cc["expect"].(map[string]any)
	md, _ := e["markdown"].(string)
	parsed, _ := e["parseMatches"].(bool)
	reemit, _ := e["reemitMatches"].(bool)
	given, edited := e["given"].(string)
	switch token {
	case "alsoInHeldThere":
		return mustMatch(`\[Also in \[[^\]]+\]\([^)]+\), held there`, md), true
	case "alsoInHeldHere":
		return mustMatch(`\[Also in \[[^\]]+\]\([^)]+\), held here`, md), true
	case "heldException":
		return strings.Contains(md, " except REQ.owner"), true
	case "summaryOf":
		return strings.Contains(md,
			"held there except REQ.owner; Summary of [REQ-EXPORT](#REQ-EXPORT)]{.linked}"), true
	case "summarisedIn":
		return strings.Contains(md, "Summarised in [KEY-1](#KEY-1)"), true
	case "derivedTwoFields":
		return mustMatch(`Derived from (\[[^\]]+\]\([^)]+\)(,)?)+: \w+, \w+`, md), true
	case "extractedFrom":
		return strings.Contains(md, "[Extracted from [REQD](#REQ-EXPORT/REQD)]{.linked}"), true
	case "copyOf":
		return strings.Contains(md, "[Copy of [CRIT](#CRIT), edit it there]{.linked}"), true
	case "copiedTo":
		return strings.Contains(md, "Copied to [CRIT](#CSUM/CRIT)"), true
	case "copyAnchors":
		return strings.Contains(md, `<a id="CSUM/CRIT/CRIT-SPEED"></a>`), true
	case "qualifiedThree":
		return mustMatch(`(?m)^#+ <!--\[LNK-REF\]--> <a id="REQ-EXPORT/LNK-1/LNK-REF"></a> `, md), true
	case "markerRestored":
		return edited && !strings.Contains(given, "{.linked}") && parsed && reemit, true
	case "handEditDiscarded":
		return edited && strings.Contains(given, "Copy of [X]") && parsed && reemit, true
	case "emptyMarker":
		return strings.Contains(md, "[]{.linked}\n\n[To be chosen") && parsed, true
	case "spanKept":
		return strings.Contains(canonJSON(t, cc["state"]), "{.linked}") && parsed, true
	case "dangling":
		return strings.Contains(md,
			"[Also in [BLU REQ-PRESETS](links.blu.tomspecs.md#REQ-PRESETS), held here"), true
	case "generatedTrace":
		return strings.Contains(md,
			"::: {.derived label=\"Generated from each requirement's traceability; "+
				"edit it there\"}\n| Requirement | Use cases | Screens | Data entities | Tests |"), true
	case "generatedCoverage":
		return mustMatch(`\| Requirement \| Covered \| By \|\n\| --- \| --- \| --- \|\n`+
			`\| \[FRE-REQU-TENANT-LIFECYCLE\]\(#FRE-REQU-TENANT-LIFECYCLE\) \| (yes|no) \|`, md), true
	case "generatedRelationships":
		return strings.Contains(md, "| Requirement | Dependency | Related requirement |"), true
	case "generatedFirst":
		return mustMatch(`(?m)^## <!--\[REQCOV\]--> <a id="REQCOV"></a> [^\n]*\n\n`+
			`(\[[^\n]*\]\{\.linked\}\n\n)?::: \{\.derived `, md), true
	case "generatedOverview":
		return strings.Contains(md, "<!--[RO-TRAC]-->") &&
			strings.Contains(md, "| Requirement | Use cases | Screens |"), true
	case "generatedUseCases":
		return strings.Contains(md,
			"| [INEN-INTE-UC-02](#INEN-INTE-UC-02) |  | [FRE-REQU-TENANT-FEATURES]("), true
	case "generatedEditDiscarded":
		return edited && strings.Contains(given, "| Requirement | Covered |\n") && parsed && reemit, true
	case "noGenerated":
		return !strings.Contains(md, "{.derived"), true
	case "emptyGenerated":
		return strings.Contains(md, "::: {.derived}\n:::\n\n::: {.derived}\nTraced by hand.\n:::"), true
	case "summaryRowLink":
		return strings.Contains(md, `| <a id="TOP-BETA"></a>[TOP-BETA](#TOP-BETA) |`) &&
			strings.Contains(md, `| <a id="TOP-BETA"></a>TOP-BETA |`), true
	case "noMarkers":
		return !strings.Contains(md, "{.linked}") && strings.Contains(md, `<a id="REQ-EXPORT/REQD"></a>`), true
	case "roundTrip":
		return !edited && parsed && reemit, true
	case "clean":
		r, _ := e["rejections"].([]any)
		return len(r) == 0, true
	}
	return false, false
}

func sortedMapKeys(m map[string]any) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

// testLinkRendition replays link_rendition_cases.json: each case's
// rendition, what the parser makes of it and the rendition of that, against
// the expectation, and its intent.
func testLinkRendition(c *checker, t *testing.T, models *setModels) {
	table := readSetTable(t, "link_rendition_cases.json")
	modelName, _ := table["model"].(string)
	fixture := modelFromCorpus(t, modelName)
	for _, cc := range setCases(table, "cases") {
		name := "links.rendition[" + cc.name() + "]"
		var got map[string]any
		_, err := runGuarded(func() any {
			var e error
			got, e = renditionCase(t, models, fixture, cc)
			if e != nil {
				panic(e)
			}
			return nil
		})
		if err != nil {
			c.check(name, false, "threw "+err.Error())
		} else {
			g, _ := generic(t, got).(map[string]any)
			expect, _ := cc["expect"].(map[string]any)
			for _, k := range []string{"markdown", "given", "rejections", "parseMatches", "reemitMatches"} {
				ok := reflect.DeepEqual(g[k], expect[k])
				detail := ""
				if !ok {
					detail = "got " + canonJSON(t, g[k]) + " want " + canonJSON(t, expect[k])
				}
				c.check(name+"."+k, ok, detail)
			}
			gk, ek := sortedMapKeys(g), sortedMapKeys(expect)
			c.check(name+".keys", reflect.DeepEqual(gk, ek),
				strings.Join(gk, ",")+" vs "+strings.Join(ek, ","))
		}
		for _, token := range cc.intent() {
			holds, known := renditionIntentHolds(t, token, cc)
			c.check("links.rendition.intent["+cc.name()+": "+token+"]", holds && known, intentDetail(known))
		}
	}
}

// testRenditionSchemaTier checks that the schema tier finds nothing in the
// markers and generated parts (the Dart test's RNC5, real model): each
// document's findings with navigation equal its findings without.
func testRenditionSchemaTier(c *checker, t *testing.T, models *setModels) {
	table := readSetTable(t, "uam_requirements_cut.json")
	rsp := stateDocument(t, table["rsp"])
	sbp := stateDocument(t, table["blueprint"])
	isc := som.NewSpecDocument()
	item, err := isc.AddListItemWithSectionID("ISC/interactionCatalog/INEN-INTE-LST", "INEN-INTE-UC-01")
	if err != nil {
		t.Fatalf("add the interaction: %v", err)
	}
	isc.SetFormField(item+"/INTR", "relatedRequirements", "FRE-REQU-TENANT-LIFECYCLE")
	model := models.real()
	for _, dc := range []struct {
		doc    *som.SpecDocument
		schema string
	}{
		{rsp, "requirements-specification"},
		{sbp, "solution-blueprint"},
		{isc, "interaction-scenarios"},
	} {
		name := "links.rendition.schemaTier[" + dc.schema + "]"
		file := filepath.Join(corpusRel, "..", "..", "tom_som_dart_v0", "schemas", dc.schema,
			dc.schema+".1.0.docspecs-schema.yaml")
		text, err := os.ReadFile(file)
		if err != nil {
			c.check(name, false, "threw "+err.Error())
			continue
		}
		schema, err := som.DocSpecsSchemaFromYamlText(string(text))
		if err != nil {
			c.check(name, false, "threw "+err.Error())
			continue
		}
		findings := func(navigation bool) (string, []string, error) {
			md, err := renditionOf(model, dc.doc, "", navigation, navigation)
			if err != nil {
				return "", nil, err
			}
			out := []string{}
			for _, v := range som.NewDocSpecsValidatorWithTomSpecs(schema, true).ValidateMarkdown(md) {
				out = append(out, v.Rule+" "+v.SectionID)
			}
			sort.Strings(out)
			return md, out, nil
		}
		md, with, err := findings(true)
		if err != nil {
			c.check(name, false, "threw "+err.Error())
			continue
		}
		_, without, err := findings(false)
		if err != nil {
			c.check(name, false, "threw "+err.Error())
			continue
		}
		c.check(name+".derived", strings.Contains(md, "{.derived"), "")
		ok := reflect.DeepEqual(with, without)
		detail := ""
		if !ok {
			detail = "got " + canonJSON(t, with) + " want " + canonJSON(t, without)
		}
		c.check(name, ok, detail)
	}
}
