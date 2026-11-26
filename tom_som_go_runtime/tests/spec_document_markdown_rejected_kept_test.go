// Rejected blocks kept for review (SOM §11.7, DocSpecs RN-11): an import
// accepting rejections keeps each rejected block as a `rejected` div in the
// text of the section it stood in (else its parent), at its place. The kept
// document re-exports and re-imports without a rejection and to the same
// document, and the validator reports each div as `rejectedBlock`. A port of
// `tom_som_rust_runtime/tests/spec_document_markdown_rejected_kept.rs`
// (itself a port of the Python and TypeScript suites); the single cases are
// pinned in the conformance corpus (`markdown_apply_cases.json`).
package tests

import (
	"fmt"
	"regexp"
	"sort"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

type keptFixture struct {
	t      *testing.T
	model  *som.SpecModel
	golden string
}

func loadKeptFixture(t *testing.T) *keptFixture {
	return &keptFixture{t: t, model: loadModel(t), golden: readCorpus(t, "expected.tables.md")}
}

// sub returns the golden with source (which it must hold) replaced by target.
func (f *keptFixture) sub(source, target string) string {
	if !strings.Contains(f.golden, source) {
		f.t.Fatalf("the golden has no %q", source)
	}
	return strings.Replace(f.golden, source, target, 1)
}

func (f *keptFixture) parse(markdown string) *som.SpecMarkdownResult {
	return som.NewSpecDocumentMarkdown(f.model, som.NewSpecDocument()).Parse(markdown)
}

func (f *keptFixture) kept(markdown string) *som.SpecDocument {
	doc := som.NewSpecDocument()
	if err := doc.ApplyMarkdownResult(f.parse(markdown), true); err != nil {
		f.t.Fatalf("rejections are allowed: %v", err)
	}
	return doc
}

type keptVariant struct {
	name     string
	markdown string
}

func (f *keptFixture) variants() []keptVariant {
	return []keptVariant{
		{"unknown section", f.golden + "\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n"},
		{"near-miss row", f.sub("| Owner | Bob |", "| Owner | Bob |\n| Ownr | Carol |")},
		{"row given twice", f.sub("| Estimate | 8 |", "| Estimate | 8 |\n| Owner | Carol |")},
		{"paragraph given twice", f.sub(
			"- backup: alice@example.com\n",
			"- backup: alice@example.com\nContact: carol@example.com\n- line\n")},
		{"table without delimiter", f.sub(
			"| TomSpecField | Value |\n| --- | --- |\n| Owner | Bob |",
			"| TomSpecField | Value |\n| Owner | Bob |")},
		{"records column", f.sub("| Id | Title | Note |", "| Id | Title | Nte |")},
		{"records row", f.sub(
			"| <a id=\"CARD-2\"></a>CARD-2 |  | second card |",
			"| <a id=\"CARD-2\"></a>CARD-2 | second card |")},
		{"unclosed records fence", f.sub("| second card |\n:::\n", "| second card |\n")},
		{"section-table row", f.sub(
			"| <a id=\"DLV-1/DLR-1\"></a>DLR-LST / DLR-1 | Area | CE-NV |\n"+
				"|  | Mapping | dart-tom |\n\n### <!--[DLV-2]",
			"| <a id=\"DLV-1/DLR-1\"></a>DLR-LS / DLR-1 | Area | CE-NV |\n"+
				"|  | Mapping | dart-tom |\n\n### <!--[DLV-2]")},
		{"orphan text", "Stray text.\n\n" + f.golden},
		{"child under a value leaf", f.sub(
			"high\n\n## <!--[CNT]-->",
			"high\n\n### <!--[X]--> Child\n\nchild text\n\n## <!--[CNT]-->")},
		{"nested unknown sections",
			f.golden + "\n## <!--[NOPE]--> A\n\nA text\n\n### <!--[NOPE2]--> B\n\nB\n"},
	}
}

func (f *keptFixture) variant(name string) string {
	for _, v := range f.variants() {
		if v.name == name {
			return v.markdown
		}
	}
	f.t.Fatalf("no variant %q", name)
	return ""
}

var keptDivRE = regexp.MustCompile(`^:{3,} \{\.rejected reason="([^"]*)" line="([0-9]+)"`)

// rejectedDivs returns `reason@line` of every `rejected` div opening a line
// of text.
func rejectedDivs(text string) []string {
	var out []string
	for _, line := range strings.Split(text, "\n") {
		if m := keptDivRE.FindStringSubmatch(line); m != nil {
			out = append(out, m[1]+"@"+m[2])
		}
	}
	return out
}

func keptCanonical(t *testing.T, doc *som.SpecDocument) string {
	return canonJSON(t, doc.ToJSON())
}

func keptContent(doc *som.SpecDocument, path string) string {
	v, _ := doc.Content(path)
	return v
}

func TestRejectedBlocksKeptEveryVariant(t *testing.T) {
	f := loadKeptFixture(t)
	mdCheck(t, "a clean parse keeps nothing", len(f.parse(f.golden).KeptContent) == 0)
	schema, err := som.DocSpecsSchemaFromYamlText("title-format: \"# <!--[DEMO]--> Demo\"\n")
	if err != nil {
		t.Fatalf("the schema: %v", err)
	}
	for _, v := range f.variants() {
		result := f.parse(v.markdown)
		mdCheck(t, v.name+": rejected", len(result.Rejections) > 0)
		doc := f.kept(v.markdown)
		// Every content value, in path order: the divs of one value are in
		// source order, and the variants keep their blocks in one value.
		content := doc.ToJSON().Content
		paths := make([]string, 0, len(content))
		for p := range content {
			paths = append(paths, p)
		}
		sort.Strings(paths)
		var values []string
		for _, p := range paths {
			values = append(values, content[p])
		}
		divs := rejectedDivs(strings.Join(values, "\n"))
		var want []string
		for _, r := range result.Rejections {
			want = append(want, r.Reason+"@"+fmt.Sprint(r.Line))
		}
		mdCheck(t, v.name+": every rejection kept",
			strings.Join(divs, ",") == strings.Join(want, ","),
			fmt.Sprint(divs, " != ", want))

		rendition, err := doc.ToMarkdown(f.model, "Demo")
		if err != nil {
			t.Fatalf("%s: the kept document exports: %v", v.name, err)
		}
		again := f.parse(rendition)
		var messages []string
		for _, r := range again.Rejections {
			messages = append(messages, r.Message)
		}
		mdCheck(t, v.name+": re-imports clean", len(again.Rejections) == 0, strings.Join(messages, "; "))
		reloaded := som.NewSpecDocument()
		if err := reloaded.ApplyMarkdownResult(again, true); err != nil {
			t.Fatalf("%s: rejections are allowed: %v", v.name, err)
		}
		mdCheck(t, v.name+": re-imports the same document",
			keptCanonical(t, reloaded) == keptCanonical(t, doc))

		found, err := som.ValidateSpecDocument(f.model, doc, schema, "Demo")
		if err != nil {
			t.Fatalf("%s: the kept document validates: %v", v.name, err)
		}
		reported := 0
		for _, x := range found {
			if x.Rule == som.DocSpecsRuleRejectedBlock {
				reported++
			}
		}
		mdCheck(t, v.name+": reported", reported == len(result.Rejections),
			fmt.Sprint(reported, " != ", len(result.Rejections)))
	}
}

func TestRejectedBlocksRefused(t *testing.T) {
	f := loadKeptFixture(t)
	doc := som.NewSpecDocument()
	doc.SetContent("DEMO/TTL", "base")
	before := keptCanonical(t, doc)
	unknown := f.golden + "\n## <!--[NOPE]--> Not A Section\n\nText with no home.\n"
	mdCheck(t, "a refused import refuses", doc.ApplyMarkdownResult(f.parse(unknown), false) != nil)
	mdCheck(t, "a refused import never reads the kept blocks",
		keptCanonical(t, doc) == before, keptCanonical(t, doc))
}

func TestRejectedBlocksAttributes(t *testing.T) {
	f := loadKeptFixture(t)
	row := keptContent(f.kept(f.variant("near-miss row")), "DEMO/DET")
	mdCheck(t, "near-miss row names the field",
		strings.Contains(row, `reason="unknownField" line="31" field="owner" `), row)
	twice := keptContent(f.kept(f.variant("row given twice")), "DEMO/DET")
	mdCheck(t, "a field given twice names the kept form",
		strings.Contains(twice, `field="owner" kept="DEMO/DET" `), twice)
	cell := keptContent(f.kept(f.variant("section-table row")), "DEMO/DLV-LST-1/content")
	mdCheck(t, "a near-miss cell names the section",
		strings.Contains(cell, `section="DLR-LST / DLR-1" `), cell)
	mdCheck(t, "the skipped continuation row is in the block",
		strings.Contains(cell, "|  | Mapping | dart-tom |"), cell)
}

func TestRejectedBlocksParents(t *testing.T) {
	f := loadKeptFixture(t)
	doc := f.kept(f.variant("unclosed records fence"))
	listText, has := doc.Content("DEMO/CARD-LST")
	mdCheck(t, "the list container keeps no text", !has, listText)
	root := keptContent(doc, "DEMO")
	mdCheck(t, "the unclosed fence is escaped", strings.Contains(root, "\n\\::: {.records}\n"), root)
	mdCheck(t, "the div closes", strings.HasSuffix(strings.TrimRight(root, " \n"), "\n:::"), root)
	records := keptContent(f.kept(f.variant("records column")), "DEMO")
	mdCheck(t, "a records div is kept in the parent",
		strings.HasPrefix(records, `:::: {.rejected reason="unknownField"`), records)
	mdCheck(t, "its own div stays inside", strings.Contains(records, "\n::: {.records}\n"), records)
}

func TestRejectedBlocksPlace(t *testing.T) {
	f := loadKeptFixture(t)
	doc := f.kept(f.variant("paragraph given twice"))
	contact, _ := doc.FormField("DEMO/DET", "contact")
	mdCheck(t, "the first value is kept", strings.HasPrefix(contact, "bob@example.com"), contact)
	want := "Captured during the November review.\n" +
		"Owner: this line is prose, not the field.\n\n" +
		`::: {.rejected reason="malformedBlock" line="35" field="contact" ` +
		`kept="DEMO/DET" label="field 'contact' given twice"}` + "\n" +
		"Contact: carol@example.com\n- line\n:::"
	got := keptContent(doc, "DEMO/DET")
	mdCheck(t, "a paragraph given twice is kept at its place", got == want,
		"\n--- got\n"+got+"\n--- want\n"+want)
	orphan := keptContent(f.kept(f.variant("orphan text")), "DEMO")
	mdCheck(t, "orphan text starts the root",
		strings.HasPrefix(orphan, `::: {.rejected reason="orphanContent" line="1"`), orphan)
}
