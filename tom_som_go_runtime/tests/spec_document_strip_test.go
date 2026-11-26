// The strip of one value (SOM §11.10, spec_document_strip.go) beyond the
// shared corpus: UTF-16 offsets around supplementary characters (the corpus
// has none), a refused value, the option sets' derived forms and
// CountAnnotationsText; and the strip of a whole document over a model nine
// sections deep: styled-div headings, the readable header, the appendix and
// the strip's checks.
//
// Each expected result of a strip was produced by the JavaScript runtime (the
// port of the TypeScript reference) for the same input; the Rust runtime's
// tests/spec_document_strip.rs holds the same values.
package tests

import (
	"fmt"
	"reflect"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func stripValue(t *testing.T, text string, drop, appendix []string, references bool) *som.SpecStripTextResult {
	t.Helper()
	o, err := som.SpecStripOptionsFromNames(drop, nil, appendix, references, false)
	if err != nil {
		t.Fatalf("options: %v", err)
	}
	return som.StripNotationText(text, o)
}

func piece(anchor, origin int, removed, inserted, label string) som.SpecStripPiece {
	return som.SpecStripPiece{Anchor: anchor, Origin: origin, Removed: removed, Inserted: inserted,
		Labels: []string{label}}
}

func assertPieces(t *testing.T, got, want []som.SpecStripPiece) {
	t.Helper()
	if !reflect.DeepEqual(got, want) {
		t.Errorf("pieces:\n got %#v\nwant %#v", got, want)
	}
}

func TestStripAstralBeforeADroppedSpan(t *testing.T) {
	r := stripValue(t, "😀 [x]{.aside} end", []string{"aside"}, nil, false)
	if r.Text != "😀 end" {
		t.Errorf("text %q", r.Text)
	}
	if !reflect.DeepEqual(r.Dropped, map[string]int{"aside": 1}) {
		t.Errorf("dropped %v", r.Dropped)
	}
	assertPieces(t, r.Pieces, []som.SpecStripPiece{piece(2, 2, " [x]{.aside}", "", "aside:drop")})
}

func TestStripAstralWithCommentsDroppedAndAppendixReferences(t *testing.T) {
	note1 := `<a id="note-1-ref"></a>[\[1\]](#note-1)`
	note2 := `<a id="note-2-ref"></a>[\[2\]](#note-2)`
	r := stripValue(t,
		"😀 a\n\n::: {.provenance}\n𝔸 p\n:::\n\n> ⬆️ **C-1** (al): 𝔹 note\n\nb {++𝔸++} c [t]{.trace}",
		[]string{"comments"}, []string{"provenance", "trace"}, true)
	if want := "😀 a\n\n" + note1 + "\n\nb 𝔸 c" + note2; r.Text != want {
		t.Errorf("text %q, want %q", r.Text, want)
	}
	if !reflect.DeepEqual(r.Dropped, map[string]int{"comments": 2}) || len(r.Unmarked) != 0 ||
		!reflect.DeepEqual(r.Appended, map[string]int{"provenance": 1, "trace": 1}) || r.MarksDropped != 0 {
		t.Errorf("counts %v %v %v %d", r.Dropped, r.Unmarked, r.Appended, r.MarksDropped)
	}
	want := []som.SpecAppendixEntry{
		{Number: 1, Kind: "provenance", Text: "𝔸 p"},
		{Number: 2, Kind: "trace", Text: "t"},
	}
	if !reflect.DeepEqual(r.Appendix, want) {
		t.Errorf("appendix %#v", r.Appendix)
	}
	assertPieces(t, r.Pieces, []som.SpecStripPiece{
		piece(6, 6, "::: {.provenance}\n𝔸 p\n:::", note1, "provenance:appendix"),
		piece(47, 34, "> ⬆️ **C-1** (al): 𝔹 note\n\n", "", "comments"),
		piece(49, 64, "{++", "", "comments"),
		piece(51, 69, "++}", "", "comments"),
		piece(53, 74, " [t]{.trace}", note2, "trace:appendix"),
	})
}

func TestStripAstralInsideReviewMarks(t *testing.T) {
	r := stripValue(t, "x {--😀 [y]{.aside}--} z {~~𝔸 [q]{.aside}~>new~~}", []string{"aside"}, nil, false)
	if r.Text != "x {--😀--} z {~~𝔸~>new~~}" {
		t.Errorf("text %q", r.Text)
	}
	if !reflect.DeepEqual(r.Dropped, map[string]int{"aside": 2}) {
		t.Errorf("dropped %v", r.Dropped)
	}
	assertPieces(t, r.Pieces, []som.SpecStripPiece{
		piece(7, 7, " [y]{.aside}", "", "aside:drop"),
		piece(18, 30, " [q]{.aside}", "", "aside:drop"),
	})
}

func TestStripRefusedValue(t *testing.T) {
	r := stripValue(t, "a\n::: {.aside}\nunclosed", []string{"aside"}, nil, false)
	if !r.Refused() || r.Text != "a\n::: {.aside}\nunclosed" || len(r.Pieces) != 0 {
		t.Errorf("refused %v text %q pieces %v", r.Refused(), r.Text, r.Pieces)
	}
	if got := r.ToJSON()["refused"]; !reflect.DeepEqual(got, []interface{}{"unclosedDiv"}) {
		t.Errorf("refused %v", got)
	}
}

func TestStripOptions(t *testing.T) {
	if som.SpecStripKindNames[len(som.SpecStripKindNames)-1] != "comments" || len(som.SpecStripNotationKinds) != 4 {
		t.Error("kind names")
	}
	o, err := som.SpecStripOptionsFromNames([]string{"all"}, []string{"aside"}, []string{"trace"}, false, false)
	if err != nil {
		t.Fatal(err)
	}
	if got := som.SpecStripOptionsOrdered(o.Drop); !reflect.DeepEqual(got,
		[]string{"provenance", "editorial", "linked", "derived", "comments"}) {
		t.Errorf("drop %v", got)
	}
	if !o.WritesNoLinkedMarkers() || !o.WritesNoGeneratedParts() {
		t.Error("linked / derived written")
	}
	k := o.Keeping()
	if !reflect.DeepEqual(k.Drop, map[string]bool{"comments": true}) || len(k.Appendix) != 0 ||
		!reflect.DeepEqual(som.SpecStripOptionsOrdered(k.Unmark),
			[]string{"provenance", "trace", "editorial", "aside", "linked", "derived"}) {
		t.Errorf("keeping %#v", k)
	}
	e := o.InEntry()
	if e.Drop["comments"] || !reflect.DeepEqual(som.SpecStripOptionsOrdered(e.Unmark), []string{"trace", "aside"}) {
		t.Errorf("in entry %#v", e)
	}
	if (som.SpecStripOptions{}).WritesNoLinkedMarkers() {
		t.Error("zero options write no linked markers")
	}
	if _, err := som.SpecStripOptionsFromNames(nil, nil, []string{"linked"}, false, false); err == nil ||
		!strings.HasPrefix(err.Error(), "linked cannot") {
		t.Errorf("linked to the appendix: %v", err)
	}
	if _, err := som.SpecStripOptionsFromNames(nil, nil, nil, true, false); err == nil ||
		err.Error() != "appendix references need an appendix: name its kinds" {
		t.Errorf("references without an appendix: %v", err)
	}
}

func TestCountAnnotationsText(t *testing.T) {
	if n := som.CountAnnotationsText("> ⬆️ **C-1** (al): n\n\nx {++a++} {>>c<<}"); n != 3 {
		t.Errorf("count %d", n)
	}
	if n := som.CountAnnotationsText("plain"); n != 0 {
		t.Errorf("count %d", n)
	}
}

// --- the strip of a whole document ---------------------------------------------

// stripDeepModel is a model nine sections deep: `L<n>` holds content `T<n>`
// and section `L<n+1>`, so `T<n>` stands at depth n + 1.
func stripDeepModel(t *testing.T) *som.SpecModel {
	t.Helper()
	var classes []string
	for n := 1; n <= 9; n++ {
		fields := fmt.Sprintf(`{"name":"text","kind":"content","sectionId":"T%d","contentType":"text"}`, n)
		if n < 9 {
			fields += fmt.Sprintf(`,{"name":"next","kind":"complex","sectionId":"L%d","type":"L%d"}`, n+1, n+1)
		}
		annotations := ""
		if n == 1 {
			annotations = `"annotations":[{"name":"Document","arguments":{"title":"Deep"}},` +
				`{"name":"SectionId","arguments":{"id":"L1"}}],`
		}
		classes = append(classes, fmt.Sprintf(`"L%d":{"name":"L%d","sectionId":"L%d",%s"fields":[%s]}`,
			n, n, n, annotations, fields))
	}
	text := `{"modelVersion":1,"modelVersionLabel":"0.1.0+1",` +
		`"roots":[{"type":"L1","title":"Deep","sectionId":"L1"}],` +
		`"classes":{` + strings.Join(classes, ",") + `}}`
	m, err := som.SpecModelFromJSON([]byte(text))
	if err != nil {
		t.Fatalf("deep model: %v", err)
	}
	return m
}

// stripPathTo is `L1/…/L<n>[/T<n>]`.
func stripPathTo(n int, text bool) string {
	var p []string
	for k := 1; k <= n; k++ {
		p = append(p, fmt.Sprintf("L%d", k))
	}
	if text {
		p = append(p, fmt.Sprintf("T%d", n))
	}
	return strings.Join(p, "/")
}

func stripDeepDocument() *som.SpecDocument {
	d := som.NewSpecDocument()
	for n := 1; n <= 9; n++ {
		d.SetContent(stripPathTo(n, true), fmt.Sprintf("Text %d [an aside]{.aside}.", n))
	}
	d.SetHeadline(stripPathTo(7, false), "Seven & <more>\nsecond line")
	d.SetContent(stripPathTo(8, true), "Before.\n\n<div class=\"heading9\" style=\"x\">Not a heading</div>"+
		"\n\n\\<div class=\"heading7\" style=\"x\">Escaped once</div>")
	return d
}

func stripHasLine(md, line string) bool {
	for _, l := range strings.Split(md, "\n") {
		if l == line {
			return true
		}
	}
	return false
}

// assertReadsBack checks md reads back as want without a rejection.
func assertReadsBack(t *testing.T, name, md string, model *som.SpecModel, want *som.SpecDocument) {
	t.Helper()
	back, err := som.SpecDocumentFromMarkdown(md, model)
	if err != nil {
		t.Fatalf("%s: %v", name, err)
	}
	if len(back.Rejections()) != 0 {
		t.Errorf("%s: rejections %v", name, back.Rejections())
	}
	if g, w := canonJSON(t, back.Document.ToJSON()), canonJSON(t, want.ToJSON()); g != w {
		t.Errorf("%s: reads back\n got %s\nwant %s", name, g, w)
	}
}

func TestStripHeadingDivs(t *testing.T) {
	model := stripDeepModel(t)
	root, err := model.RootByType("L1")
	if err != nil {
		t.Fatal(err)
	}
	doc := stripDeepDocument()
	codec := som.NewSpecDocumentMarkdown(model, doc)
	codec.HeadingDivs = true
	r, err := codec.ExportRootWithMap(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, l := range strings.Split(r.Markdown, "\n") {
		if strings.HasPrefix(l, "#######") {
			t.Errorf("a # heading deeper than 6: %s", l)
		}
	}
	if !stripHasLine(r.Markdown, `<div class="heading7" style="margin:1em 0 0.5em;padding-left:0.75em;font-weight:bold">`+
		`<!--[L7]--> <a id="L7"></a> Seven &amp; &lt;more&gt;<br>second line</div>`) {
		t.Errorf("level 7 with the title escaped:\n%s", r.Markdown)
	}
	if !strings.Contains(r.Markdown, `<div class="heading10" style="margin:1em 0 0.5em;padding-left:3em;`) {
		t.Error("level 10")
	}
	if !stripHasLine(r.Markdown, `\<div class="heading9" style="x">Not a heading</div>`) ||
		!stripHasLine(r.Markdown, `\\<div class="heading7" style="x">Escaped once</div>`) {
		t.Errorf("div-shaped value lines escaped:\n%s", r.Markdown)
	}
	// Every heading is in the map, the div ones included.
	headings, mapped := 0, 0
	for i, l := range strings.Split(r.Markdown, "\n") {
		if (strings.HasPrefix(l, "#") || strings.HasPrefix(l, `<div class="heading`)) && strings.Contains(l, "<!--[") {
			headings++
			if _, ok := r.HeadingPaths[i+1]; ok {
				mapped++
			}
		}
	}
	if headings <= 9 || mapped != headings || mapped != len(r.HeadingPaths) {
		t.Errorf("headings %d mapped %d map %d", headings, mapped, len(r.HeadingPaths))
	}
	assertReadsBack(t, "divs", r.Markdown, model, doc)

	plain, err := som.NewSpecDocumentMarkdown(model, doc).ExportRoot(root)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(plain, "####### <!--[L7]-->") || strings.Contains(plain, "\n<div class=\"heading7\"") {
		t.Error("without divs: # headings")
	}
	if !stripHasLine(plain, `\<div class="heading9" style="x">Not a heading</div>`) {
		t.Error("without divs: the div-shaped line escaped")
	}
	assertReadsBack(t, "no divs", plain, model, doc)

	for d, w := range map[int]string{7: "0.75", 8: "1.5", 9: "2.25", 10: "3", 11: "3.75", 12: "4.5"} {
		if got := som.SpecMarkdownHeadingDivIndent(d); got != w {
			t.Errorf("indent %d: %s", d, got)
		}
	}
	if _, _, ok := som.SpecMarkdownHeadingDiv(`<div class="heading6">x</div>`); ok {
		t.Error("heading6 is content")
	}
	if level, inner, ok := som.SpecMarkdownHeadingDiv(`<div class="heading7">a &amp;lt;</div>`); !ok ||
		level != 7 || inner != "a &lt;" {
		t.Errorf("heading div %d %q %v", level, inner, ok)
	}
}

func TestStripReadableHeaderAppendixAndChecks(t *testing.T) {
	model := stripDeepModel(t)
	source := &som.SpecReadableSource{File: "deep.tomspecs.yaml", Revision: "r3", Commit: "8e1d2a7", Dirty: true}
	extra := som.SpecDocumentStripOptions{Model: model, Source: source}
	o, err := som.SpecStripOptionsFromNames([]string{"aside"}, nil, nil, false, true)
	if err != nil {
		t.Fatal(err)
	}
	doc := stripDeepDocument()
	r := som.SpecDocumentStrip{}.Strip(doc, o, extra)
	if !r.OK() {
		t.Fatalf("findings %v", r.Findings)
	}
	if r.ReadableHeader != "<!-- readable: drop=aside; headings=divs; of=deep.tomspecs.yaml@r3; commit=8e1d2a7+dirty -->" {
		t.Errorf("header %s", r.ReadableHeader)
	}
	lines := strings.Split(r.Readable, "\n")
	if !strings.HasPrefix(lines[0], "<!-- docspec: ") || lines[1] != r.ReadableHeader {
		t.Errorf("the header follows the docspec line: %q %q", lines[0], lines[1])
	}
	if !strings.Contains(r.Readable, `<div class="heading8"`) || strings.Contains(r.Readable, "{.aside}") {
		t.Errorf("readable:\n%s", r.Readable)
	}
	parsed := som.NewSpecDocumentMarkdown(model, som.NewSpecDocument()).Parse(r.Readable)
	if parsed.ReadableHeader != r.ReadableHeader {
		t.Errorf("parsed header %q", parsed.ReadableHeader)
	}
	h := som.ParseSpecReadableHeader(r.ReadableHeader)
	if h == nil || h.Format() != r.ReadableHeader || len(h.Options.Drop) != 1 || !h.Options.Drop["aside"] ||
		!h.Options.HeadingDivs || h.Source == nil || !h.Source.Dirty {
		t.Errorf("header parse %#v", h)
	}
	assertReadsBack(t, "readable", r.Readable, model, r.Document)

	// The appendix lists the moved prose under its section titles.
	a, err := som.SpecStripOptionsFromNames(nil, nil, []string{"aside"}, true, true)
	if err != nil {
		t.Fatal(err)
	}
	extra.Source = nil
	r = som.SpecDocumentStrip{}.Strip(doc, a, extra)
	if !r.OK() || len(r.Appendix) != 8 {
		t.Fatalf("ok %v appendix %d findings %v", r.OK(), len(r.Appendix), r.Findings)
	}
	for i, e := range r.Appendix {
		n := i + 1
		if i >= 7 {
			n++ // T8 holds no aside
		}
		if e.Number != i+1 || e.Value == nil || e.Value.Path != stripPathTo(n, true) {
			t.Errorf("entry %d: %#v", i, e)
		}
	}
	marker := som.SpecMarkdownAppendixMarker + "\n"
	at := strings.Index(r.Readable, marker)
	if at < 0 {
		t.Fatal("the appendix after its marker")
	}
	notes := r.Readable[at+len(marker):]
	if !strings.HasPrefix(notes, "\n## Notes\n") || strings.Count(notes, "### Text\n") != 8 ||
		!strings.Contains(notes, "<a id=\"note-1\"></a>**[1]** an aside [↩](#note-1-ref)") {
		t.Errorf("notes:\n%s", notes)
	}
	if got := r.Document.ContentOr(stripPathTo(1, true)); got != `Text 1<a id="note-1-ref"></a>[\[1\]](#note-1).` {
		t.Errorf("T1 %q", got)
	}
	// The DocSpecs parse stops at the marker: no Notes section.
	for _, s := range som.ParseDocSpecsDocument(r.Readable).AllSections() {
		if s.Title == "Notes" {
			t.Error("the DocSpecs parse read the appendix")
		}
	}
	// Nor does the markdown parse read it.
	assertReadsBack(t, "appendix", r.Readable, model, r.Document)

	// A value with a notation error is refused and reported.
	doc.SetContent(stripPathTo(2, true), "::: {.aside}\nopen")
	r = som.SpecDocumentStrip{}.Strip(doc, o, extra)
	if r.OK() || len(r.Findings) != 1 || r.Findings[0].Kind != "notation" || r.Findings[0].Ref == nil {
		t.Errorf("findings %v", r.Findings)
	}
	if got := r.Document.ContentOr(stripPathTo(2, true)); got != "::: {.aside}\nopen" {
		t.Errorf("T2 %q", got)
	}

	// Without a model nothing is rendered or checked.
	every, err := som.SpecStripOptionsFromNames([]string{"all"}, nil, nil, false, false)
	if err != nil {
		t.Fatal(err)
	}
	r = som.SpecDocumentStrip{}.Strip(stripDeepDocument(), every, som.SpecDocumentStripOptions{})
	if r.Readable != "" || r.Document.ContentOr(stripPathTo(1, true)) != "Text 1." {
		t.Errorf("without a model: %q %q", r.Readable, r.Document.ContentOr(stripPathTo(1, true)))
	}
	if got := r.Report(); !reflect.DeepEqual(got, []string{"aside: 8 dropped, 0 unmarked, 0 moved"}) {
		t.Errorf("report %v", got)
	}
}

func TestStrippedGoesThroughTheStrip(t *testing.T) {
	doc := som.NewSpecDocument()
	doc.SetContent("L1/T1", "Keep {++this++}.\n\n> ⬆️ **C-1** (Al): ok")
	doc.SetHeadline("L1/L2", "Two {--old--}")
	s := som.NewSpecReviewAnnotations(doc, "").Stripped()
	if got := s.ContentOr("L1/T1"); got != "Keep this." {
		t.Errorf("content %q", got)
	}
	if got := s.HeadlineOr("L1/L2"); got != "Two" {
		t.Errorf("headlines too: %q", got)
	}
}

func TestStripValueRefsAndFindingsPrint(t *testing.T) {
	headline := som.SpecStripValueRef{Path: "A/B", Headline: true}
	field := som.SpecStripValueRef{Path: "A/F", Field: "owner"}
	if headline.Label() != "A/B (headline)" || field.Label() != "A/F/owner" {
		t.Errorf("labels %s %s", headline.Label(), field.Label())
	}
	if !reflect.DeepEqual(field.ToJSON(), map[string]interface{}{"path": "A/F", "field": "owner"}) {
		t.Errorf("json %v", field.ToJSON())
	}
	f := som.SpecStripFinding{Kind: "parse", Message: "m", Ref: &field}
	if f.String() != "parse: A/F/owner: m" {
		t.Errorf("finding %s", f.String())
	}
}
