// Tests for the DocSpecs-conform Markdown codec (`spec_document_markdown.go`,
// SOM §11) — a port of
// `tom_som_typescript_runtime/tests/spec_document_markdown_test.ts` (itself a
// port of the Python/Dart reference suite).
//
// The generated `*.md` is a genuine DocSpecs document: line 1 is the
// `<!-- docspec: <schema-id>/<version> -->` declaration, every populated
// section is a heading of the form `## <!--[SECTION-ID]--> Title`, content
// sections are normal markdown text (no fences), `@Form` sections use the
// plain-text `FieldName: value` format, and a list emits its `-LST` container
// heading at the owner's child level, wrapping the numbered item headings one
// level deeper (SOM §11.2).
//
// The model fixture (demoModelJSON) and populated document
// (populatedDemoDoc) are shared with item12_test.go.
package tests

import (
	"fmt"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// mdCheck mirrors the reference suites' _check(name, condition, detail).
func mdCheck(t *testing.T, name string, condition bool, detail ...string) {
	t.Helper()
	if !condition {
		d := ""
		if len(detail) > 0 {
			d = ": " + detail[0]
		}
		t.Errorf("%s%s", name, d)
	}
}

// mdD4rtBody is a d4rt-flutter body that is multi-line and embeds a run of
// three backticks mid-line — must pass through the plain-text body verbatim.
const mdD4rtBody = "Column(\n" +
	"  children: [\n" +
	"    Text(\"hi\"),\n" +
	"  ],\n" +
	") // not a fence: ``` still inside the body"

// mdRichMarkdown exercises embedded markdown formatting: emphasis, a bullet
// list, a fenced code block containing heading-like lines, and a leading `#`
// line at column 0 (which the emitter escapes as `\#`).
const mdRichMarkdown = "Intro with **bold** and *italic*.\n" +
	"\n" +
	"- first bullet\n" +
	"- second bullet\n" +
	"\n" +
	"```dart\n" +
	"# not a heading — shielded by the fence\n" +
	"## also shielded\n" +
	"void main() {}\n" +
	"```\n" +
	"\n" +
	"# looks like a heading at column 0\n" +
	"trailing paragraph"

func mdExport(t *testing.T, doc *som.SpecDocument) string {
	t.Helper()
	model := demoModel(t)
	md, err := som.NewSpecDocumentMarkdown(model, doc).ExportRoot(model.Roots[0])
	if err != nil {
		t.Fatalf("ExportRoot: unexpected error %v", err)
	}
	return md
}

// mdReload parses md into a fresh document via the staged-values report.
func mdReload(t *testing.T, md string) (*som.SpecDocument, *som.SpecMarkdownResult) {
	t.Helper()
	target := som.NewSpecDocument()
	report := som.NewSpecDocumentMarkdown(demoModel(t), target).Parse(md)
	target.LoadJSON(&som.DocumentJson{
		Content:   report.Content,
		Forms:     report.Forms,
		Lists:     report.Lists,
		Headlines: report.Headlines,
		CodeSpecs: report.CodeSpecs,
	})
	return target, report
}

func mdParse(t *testing.T, md string) *som.SpecMarkdownResult {
	t.Helper()
	return som.NewSpecDocumentMarkdown(demoModel(t), som.NewSpecDocument()).Parse(md)
}

func mdRejStr(report *som.SpecMarkdownResult) string {
	parts := make([]string, 0, len(report.Rejections))
	for _, r := range report.Rejections {
		parts = append(parts, r.String())
	}
	return strings.Join(parts, "; ")
}

func mdShallowEqual(a, b map[string]string) bool {
	if len(a) != len(b) {
		return false
	}
	for k, v := range a {
		if b[k] != v {
			return false
		}
	}
	return true
}

// --- export — DocSpecs format (SOM §11) -------------------------------------

func TestMarkdownExportFormat(t *testing.T) {
	md := mdExport(t, populatedDemoDoc())
	first := strings.Split(md, "\n")[0]
	mdCheck(t, "export.docspec.prefix", strings.HasPrefix(first, "<!-- docspec: demo-document/"), first)
	mdCheck(t, "export.docspec.suffix", strings.HasSuffix(first, "-->"), first)

	mdCheck(t, "export.heading.root", strings.Contains(md, "# <!--[D00]--> Demo Document"))
	mdCheck(t, "export.heading.overview", strings.Contains(md, "## <!--[D00-OVR]--> Overview"))
	mdCheck(t, "export.heading.status", strings.Contains(md, "## <!--[D00-ST]--> Status"))
	mdCheck(t, "export.heading.header", strings.Contains(md, "## <!--[D00-HDR]--> Header"))
	mdCheck(t, "export.heading.meta", strings.Contains(md, "## <!--[D00-MET]--> Meta"))
	mdCheck(t, "export.heading.note", strings.Contains(md, "### <!--[D00-MET-NOTE]--> Note"))

	mdCheck(t, "export.content.plain", strings.Contains(md, "An overview paragraph.\nWith two lines."))
	noFence := true
	for _, l := range strings.Split(md, "\n") {
		if strings.HasPrefix(l, "```") {
			noFence = false
		}
	}
	mdCheck(t, "export.content.noFence", noFence)
	mdCheck(t, "export.content.noFieldAnchor", !strings.Contains(md, "<!-- field:"))
	mdCheck(t, "export.content.noPathHeading", !strings.Contains(md, "D00/D00-OVR"))

	mdCheck(t, "export.form.sparse.author", strings.Contains(md, "Author: Ada Lovelace"))
	mdCheck(t, "export.form.sparse.noReviewer", !strings.Contains(md, "Reviewer"))

	// The list container heads (SOM §11.2): `D00-ITM` at the owner's child
	// level, its numbered items one level below it, item fields one deeper.
	mdCheck(t, "export.item.container", strings.Contains(md, "## <!--[D00-ITM]--> Items"))
	mdCheck(t, "export.item.1", strings.Contains(md, "### <!--[items-1]--> Demo Item 1"))
	mdCheck(t, "export.item.2", strings.Contains(md, "### <!--[items-2]--> Demo Item 2"))
	mdCheck(t, "export.item.label", strings.Contains(md, "#### <!--[D01-LBL]--> Label"))

	mdCheck(t, "export.noSchemaDescription", !strings.Contains(md, "A demo document."))
}

func TestMarkdownExportStoredItemId(t *testing.T) {
	doc := som.NewSpecDocument()
	item, err := doc.AddListItemWithSectionID("D00/D00-ITM", "D01-CUSTOM")
	if err != nil {
		t.Fatalf("AddListItemWithSectionID: %v", err)
	}
	doc.SetContent(item+"/D01-LBL", "Custom-id item")
	md := mdExport(t, doc)
	// YRD3: the stored id IS the md heading id; only
	// anonymous items fall back to the positional derivation.
	mdCheck(t, "export.storedId.container", strings.Contains(md, "## <!--[D00-ITM]--> Items"), md)
	mdCheck(t, "export.storedId.heading", strings.Contains(md, "### <!--[D01-CUSTOM]--> Demo Item 1"), md)
	mdCheck(t, "export.storedId.noPositional", !strings.Contains(md, "items-1"), md)
}

func TestMarkdownExportUntermFenceErrors(t *testing.T) {
	doc := som.NewSpecDocument()
	doc.SetContent("D00/D00-OVR", "before\n```dart\nnever closed")
	model := demoModel(t)
	out, err := som.NewSpecDocumentMarkdown(model, doc).ExportRoot(model.Roots[0])
	mdCheck(t, "export.untermFence.raises",
		err != nil && strings.Contains(err.Error(), "unterminated"),
		fmt.Sprintf("out=%q err=%v", out, err))
}

// --- SpecDocument.ToMarkdown (item 12) --------------------------------------

func TestMarkdownToMarkdown(t *testing.T) {
	model := demoModel(t)
	doc := populatedDemoDoc()
	oneLiner, err := doc.ToMarkdown(model, "DemoDoc")
	if err != nil {
		t.Fatalf("ToMarkdown(DemoDoc): %v", err)
	}
	root, err := model.RootByType("DemoDoc")
	if err != nil {
		t.Fatalf("RootByType(DemoDoc): %v", err)
	}
	explicit, err := som.NewSpecDocumentMarkdown(model, doc).ExportRoot(root)
	if err != nil {
		t.Fatalf("ExportRoot(DemoDoc): %v", err)
	}
	mdCheck(t, "toMarkdown.explicitRoot", oneLiner == explicit)
	def, err := doc.ToMarkdown(model, "")
	if err != nil {
		t.Fatalf("ToMarkdown(\"\"): %v", err)
	}
	mdCheck(t, "toMarkdown.defaultRoot", def == oneLiner)
	_, err = som.NewSpecDocument().ToMarkdown(model, "")
	mdCheck(t, "toMarkdown.emptyThrows",
		err != nil && strings.Contains(err.Error(), "no populated root"),
		fmt.Sprintf("%v", err))

	twoModel, err := som.SpecModelFromJSON([]byte(`{
	  "roots": [
	    {"type": "Alpha", "title": "Alpha Doc", "sectionId": "A00"},
	    {"type": "Beta",  "title": "Beta Doc",  "sectionId": "B00"}
	  ],
	  "classes": {
	    "Alpha": {"name": "Alpha", "sectionId": "A00",
	      "fields": [{"name": "overview", "kind": "content", "sectionId": "A00-OVR"}]},
	    "Beta": {"name": "Beta", "sectionId": "B00",
	      "fields": [{"name": "overview", "kind": "content", "sectionId": "B00-OVR"}]}
	  }
	}`))
	if err != nil {
		t.Fatalf("SpecModelFromJSON: %v", err)
	}
	doc2 := som.NewSpecDocument()
	doc2.SetContent("A00/A00-OVR", "a")
	doc2.SetContent("B00/B00-OVR", "b")
	_, err = doc2.ToMarkdown(twoModel, "")
	mdCheck(t, "toMarkdown.twoRootsThrows.alpha",
		err != nil && strings.Contains(err.Error(), "Alpha"), fmt.Sprintf("%v", err))
	mdCheck(t, "toMarkdown.twoRootsThrows.beta",
		err != nil && strings.Contains(err.Error(), "Beta"), fmt.Sprintf("%v", err))
}

// --- round-trip --------------------------------------------------------------

func TestMarkdownRoundTripValues(t *testing.T) {
	md := mdExport(t, populatedDemoDoc())
	target, report := mdReload(t, md)
	mdCheck(t, "roundTrip.clean", report.IsClean(), mdRejStr(report))
	mdCheck(t, "roundTrip.overview",
		target.ContentOr("D00/D00-OVR") == "An overview paragraph.\nWith two lines.")
	mdCheck(t, "roundTrip.status", target.ContentOr("D00/D00-ST") == "final")
	mdCheck(t, "roundTrip.author", target.FormFieldOr("D00/D00-HDR", "author") == "Ada Lovelace")
	mdCheck(t, "roundTrip.note", target.ContentOr("D00/D00-MET/D00-MET-NOTE") == "A note.")
	items := target.ListItems("D00/D00-ITM")
	mdCheck(t, "roundTrip.itemCount", len(items) == 2, fmt.Sprintf("%v", items))
	if len(items) == 2 {
		mdCheck(t, "roundTrip.item1.label", target.ContentOr(items[0]+"/D01-LBL") == "First item")
		// The embedded d4rt body survives verbatim, backticks and all.
		mdCheck(t, "roundTrip.item1.body",
			target.ContentOr(items[0]+"/D01-BODY") == mdD4rtBody,
			fmt.Sprintf("%q", target.ContentOr(items[0]+"/D01-BODY")))
		mdCheck(t, "roundTrip.item2.label", target.ContentOr(items[1]+"/D01-LBL") == "Second item")
	}
}

func TestMarkdownRoundTripByteStable(t *testing.T) {
	md1 := mdExport(t, populatedDemoDoc())
	reloaded, _ := mdReload(t, md1)
	md2 := mdExport(t, reloaded)
	mdCheck(t, "roundTrip.byteStable", md2 == md1)
}

func TestMarkdownRoundTripRichMarkdown(t *testing.T) {
	doc := som.NewSpecDocument()
	doc.SetContent("D00/D00-OVR", mdRichMarkdown)
	md1 := mdExport(t, doc)
	// Fence-shielded heading-like lines are NOT escaped; the column-0 `#` line
	// outside the fence IS.
	mdCheck(t, "richMd.fenceShielded",
		strings.Contains(md1, "\n# not a heading — shielded by the fence\n"))
	mdCheck(t, "richMd.escapedHeading",
		strings.Contains(md1, "\n\\# looks like a heading at column 0\n"))

	reloaded, report := mdReload(t, md1)
	mdCheck(t, "richMd.clean", report.IsClean(), mdRejStr(report))
	mdCheck(t, "richMd.value",
		reloaded.ContentOr("D00/D00-OVR") == mdRichMarkdown,
		fmt.Sprintf("%q", reloaded.ContentOr("D00/D00-OVR")))
	mdCheck(t, "richMd.byteStable", mdExport(t, reloaded) == md1)
}

func TestMarkdownRoundTripStoredItemId(t *testing.T) {
	doc := som.NewSpecDocument()
	item, err := doc.AddListItemWithSectionID("D00/D00-ITM", "D01-CUSTOM")
	if err != nil {
		t.Fatalf("AddListItemWithSectionID: %v", err)
	}
	doc.SetContent(item+"/D01-LBL", "Custom-id item")
	md1 := mdExport(t, doc)
	// YRD3: the stored id IS the md heading id and is
	// recovered on parse.
	mdCheck(t, "storedId.inMd", strings.Contains(md1, "<!--[D01-CUSTOM]-->"), md1)
	reloaded, report := mdReload(t, md1)
	mdCheck(t, "storedId.clean", report.IsClean(), mdRejStr(report))
	items := reloaded.ListItems("D00/D00-ITM")
	mdCheck(t, "storedId.itemCount", len(items) == 1, fmt.Sprintf("%v", items))
	if len(items) == 1 {
		mdCheck(t, "storedId.sectionId",
			reloaded.ItemSectionIDOr(items[0]) == "D01-CUSTOM",
			reloaded.ItemSectionIDOr(items[0]))
		mdCheck(t, "storedId.label", reloaded.ContentOr(items[0]+"/D01-LBL") == "Custom-id item")
	}
	mdCheck(t, "storedId.byteStable", mdExport(t, reloaded) == md1)
}

func TestMarkdownRoundTripLabelShapedContinuation(t *testing.T) {
	doc := som.NewSpecDocument()
	doc.SetFormField("D00/D00-HDR", "author",
		"Ada Lovelace\nNote: also a mathematician\nplain line")
	md1 := mdExport(t, doc)
	// The label-shaped continuation is space-escaped on emit.
	mdCheck(t, "formCont.escaped", strings.Contains(md1, "\n Note: also a mathematician\n"), md1)

	reloaded, report := mdReload(t, md1)
	mdCheck(t, "formCont.clean", report.IsClean(), mdRejStr(report))
	mdCheck(t, "formCont.value",
		reloaded.FormFieldOr("D00/D00-HDR", "author") ==
			"Ada Lovelace\nNote: also a mathematician\nplain line",
		fmt.Sprintf("%q", reloaded.FormFieldOr("D00/D00-HDR", "author")))
	mdCheck(t, "formCont.byteStable", mdExport(t, reloaded) == md1)
}

// --- parse-rejection protocol (SOM §11.7) -------------------------------------

func TestMarkdownRejectUnknownSection(t *testing.T) {
	// The bogus heading is nested under `meta` (which has no list children);
	// directly under the root any unresolved id would be absorbed by the
	// single-list-child fallback as a stored-id item.
	md := "<!-- docspec: demo-document/1.0 -->\n" +
		"# <!--[D00]--> Demo Document\n\n" +
		"## <!--[D00-OVR]--> Overview\n\n" +
		"kept\n\n" +
		"## <!--[D00-MET]--> Meta\n\n" +
		"### <!--[D00-NOPE]--> Bogus\n\n" +
		"dropped\n"
	report := mdParse(t, md)
	mdCheck(t, "reject.unknown.dirty", !report.IsClean())
	found := false
	for _, r := range report.Rejections {
		if r.Anchor == "D00-NOPE" && r.Reason == som.SpecMarkdownRejectUnknownSection {
			found = true
		}
	}
	mdCheck(t, "reject.unknown.reason", found, mdRejStr(report))
	mdCheck(t, "reject.unknown.siblingsKept", report.Content["D00/D00-OVR"] == "kept")
}

func TestMarkdownRejectMalformedHeading(t *testing.T) {
	md := "<!-- docspec: demo-document/1.0 -->\n" +
		"# <!--[D00]--> Demo Document\n\n" +
		"## Overview without an id comment\n\n" +
		"lost\n"
	report := mdParse(t, md)
	found := false
	for _, r := range report.Rejections {
		if r.Reason == som.SpecMarkdownRejectMalformedHeading {
			found = true
		}
	}
	mdCheck(t, "reject.malformed.reason", found, mdRejStr(report))
	mdCheck(t, "reject.malformed.noContent", len(report.Content) == 0,
		fmt.Sprintf("%v", report.Content))
}

func TestMarkdownRejectOrphanPreamble(t *testing.T) {
	md := "stray preamble text\n" +
		"# <!--[D00]--> Demo Document\n\n" +
		"## <!--[D00-OVR]--> Overview\n\n" +
		"kept\n"
	report := mdParse(t, md)
	found := false
	for _, r := range report.Rejections {
		if r.Reason == som.SpecMarkdownRejectOrphanContent {
			found = true
		}
	}
	mdCheck(t, "reject.orphanPreamble.reason", found, mdRejStr(report))
	mdCheck(t, "reject.orphanPreamble.kept", report.Content["D00/D00-OVR"] == "kept")
}

func TestMarkdownRejectOrphanFormProse(t *testing.T) {
	md := "# <!--[D00]--> Demo Document\n\n" +
		"## <!--[D00-HDR]--> Header\n\n" +
		"prose before any field label\n" +
		"Author: Ada Lovelace\n"
	report := mdParse(t, md)
	found := false
	for _, r := range report.Rejections {
		if r.Reason == som.SpecMarkdownRejectOrphanContent {
			found = true
		}
	}
	mdCheck(t, "reject.orphanForm.reason", found, mdRejStr(report))
	// The labelled field still parses.
	mdCheck(t, "reject.orphanForm.fieldParsed",
		mdShallowEqual(report.Forms["D00/D00-HDR"], map[string]string{"author": "Ada Lovelace"}),
		fmt.Sprintf("%v", report.Forms))
}

func TestMarkdownRejectKindMismatch(t *testing.T) {
	md := "# <!--[D00]--> Demo Document\n\n" +
		"## <!--[D00-OVR]--> Overview\n\n" +
		"kept\n\n" +
		"### <!--[D00-MET-NOTE]--> Note\n\n" +
		"misplaced\n"
	report := mdParse(t, md)
	found := false
	for _, r := range report.Rejections {
		if r.Reason == som.SpecMarkdownRejectKindMismatch {
			found = true
		}
	}
	mdCheck(t, "reject.kindMismatch.reason", found, mdRejStr(report))
	mdCheck(t, "reject.kindMismatch.kept", report.Content["D00/D00-OVR"] == "kept")
}

func TestMarkdownRejectMissingValue(t *testing.T) {
	md := "# <!--[D00]--> Demo Document\n\n" +
		"## <!--[D00-OVR]--> Overview\n\n" +
		"## <!--[D00-ST]--> Status\n\n" +
		"final\n"
	report := mdParse(t, md)
	found := false
	for _, r := range report.Rejections {
		if r.Reason == som.SpecMarkdownRejectMissingValue && r.Anchor == "D00/D00-OVR" {
			found = true
		}
	}
	mdCheck(t, "reject.missingValue.reason", found, mdRejStr(report))
	mdCheck(t, "reject.missingValue.statusKept", report.Content["D00/D00-ST"] == "final")
}

func TestMarkdownCaseInsensitiveLabels(t *testing.T) {
	md := "# <!--[D00]--> Demo Document\n\n" +
		"## <!--[D00-HDR]--> Header\n\n" +
		"author: lower-case label\n"
	report := mdParse(t, md)
	mdCheck(t, "labels.caseInsensitive.clean", report.IsClean(), mdRejStr(report))
	mdCheck(t, "labels.caseInsensitive.value",
		mdShallowEqual(report.Forms["D00/D00-HDR"], map[string]string{"author": "lower-case label"}),
		fmt.Sprintf("%v", report.Forms))
}

func TestMarkdownFenceShieldedHeadingsStayBody(t *testing.T) {
	md := "# <!--[D00]--> Demo Document\n\n" +
		"## <!--[D00-OVR]--> Overview\n\n" +
		"```\n" +
		"## <!--[D00-ST]--> not a real heading\n" +
		"```\n"
	report := mdParse(t, md)
	mdCheck(t, "fenceShield.clean", report.IsClean(), mdRejStr(report))
	mdCheck(t, "fenceShield.body",
		report.Content["D00/D00-OVR"] == "```\n## <!--[D00-ST]--> not a real heading\n```",
		fmt.Sprintf("%q", report.Content["D00/D00-OVR"]))
	_, hasStatus := report.Content["D00/D00-ST"]
	mdCheck(t, "fenceShield.noStatus", !hasStatus)
}

// --- csmc8: stored codeSpec rides in the headline comment
// (codespecs_mapping.md §9.2) --------------

func TestMarkdownCodeSpecRidesInHeadlineComment(t *testing.T) {
	doc := populatedDemoDoc()
	doc.SetCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository")
	md := mdExport(t, doc)
	mdCheck(t, "codeSpec.md.attribute",
		strings.Contains(md,
			`## <!--[D00-OVR] codeSpec="CsOrder,CsOrder.total,CsOrderRepository"--> Overview`),
		md)
	// Untouched sections stay byte-stable (no empty codeSpec attribute).
	mdCheck(t, "codeSpec.md.untouched", strings.Contains(md, "## <!--[D00-ST]--> Status"))
}

func TestMarkdownCodeSpecParsedBackOut(t *testing.T) {
	doc := populatedDemoDoc()
	doc.SetCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total")
	md := mdExport(t, doc)
	report := mdParse(t, md)
	mdCheck(t, "codeSpec.md.parsed",
		report.CodeSpecs["D00/D00-OVR"] == "CsOrder,CsOrder.total",
		fmt.Sprintf("%v", report.CodeSpecs))
}

func TestMarkdownCodeSpecAndHeadlineRoundTripByteStable(t *testing.T) {
	doc := populatedDemoDoc()
	doc.SetHeadline("D00/D00-OVR", "Custom Overview")
	doc.SetCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository")
	md := mdExport(t, doc)
	target, _ := mdReload(t, md)
	mdCheck(t, "codeSpec.md.byteStable", mdExport(t, target) == md)
	mdCheck(t, "codeSpec.md.stored",
		target.CodeSpecOr("D00/D00-OVR") == "CsOrder,CsOrder.total,CsOrderRepository",
		target.CodeSpecOr("D00/D00-OVR"))
}
