// The merge back (SOM §11.10, spec_document_merge.go) beyond the shared
// corpus: properties over the strip corpus, the report lines of a conflict,
// text beyond ASCII and the base read from git — what strip_merge_cases.json
// (run by TestConformance) does not reach. The port of the Rust runtime's
// tests/spec_document_merge.rs (itself the port of Python's, Java's and
// TypeScript's), whose non-ASCII expectations were computed with the
// TypeScript runtime: offsets and excerpts in UTF-16 code units.
//
// The git checks build their own scratch repository in the system temp
// directory, delete it afterwards and are skipped when no `git` can be run.
package tests

import (
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

func mergeOpts(t *testing.T, drop, unmark []string) som.SpecStripOptions {
	t.Helper()
	o, err := som.SpecStripOptionsFromNames(drop, unmark, nil, false, false)
	if err != nil {
		t.Fatalf("options: %v", err)
	}
	return o
}

// Every value case of the strip corpus merges back unchanged, and with a
// paragraph added.
func TestMergeOverStripCases(t *testing.T) {
	var table stripTable
	readJSON(t, "strip_cases.json", &table)
	if len(table.Cases) == 0 {
		t.Fatal("no cases")
	}
	for _, cc := range table.Cases {
		opts, err := som.SpecStripOptionsFromNames(cc.Drop, cc.Unmark, cc.Appendix, cc.AppendixReferences, false)
		if err != nil {
			t.Fatalf("options[%s]: %v", cc.Name, err)
		}
		s := som.StripNotationText(cc.Text, opts)
		if s.Refused() {
			continue
		}
		same := som.MergeStrippedValue(cc.Text, s.Text, s.Text, s.Pieces)
		if !same.OK() || same.Text != cc.Text || same.Restored != len(s.Pieces) || len(same.Placed) != 0 {
			t.Errorf("unchanged[%s]: %v", cc.Name, same.ToJSON())
		}
		e := "An added paragraph."
		if s.Text != "" {
			e = s.Text + "\n\nAn added paragraph."
		}
		r := som.MergeStrippedValue(cc.Text, s.Text, e, s.Pieces)
		if !r.OK() || som.StripNotationText(r.Text, opts).Text != e {
			t.Errorf("addedParagraph[%s]: %v", cc.Name, r.ToJSON())
		}
	}
}

func TestMergeValues(t *testing.T) {
	o := "Keep this. Gone here (-> C1). Tail."
	s := som.StripNotationText(o, mergeOpts(t, []string{"trace"}, nil))
	r := som.MergeStrippedValue(o, s.Text, "Keep this. Tail.", s.Pieces)
	if r.OK() || len(r.Conflicts) != 1 || r.Conflicts[0].Code != "sentenceRemoved" {
		t.Fatalf("conflicts %v", r.ToJSON())
	}
	if r.ToJSON()["text"] != nil {
		t.Errorf("a conflict has no text")
	}
	got := r.Conflicts[0].About(som.SpecStripValueRef{Path: "DEMO/SUM"}).ReportLines()
	want := []string{
		"CONFLICT DEMO/SUM — the edit removed the whole sentence holding the piece",
		"  O: «Keep this. Gone here (-> C1). Tail.»",
		"  B: «Keep this. Gone here. Tail.»",
		"  E: «Keep this. Tail.»",
		"  piece: « (-> C1)»",
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("report lines\n got %q\nwant %q", got, want)
	}

	o2 := "Alpha (-> A1). Beta [aside]{.aside} gamma (-> B2)."
	opts := mergeOpts(t, []string{"trace", "aside"}, nil)
	s2 := som.StripNotationText(o2, opts)
	e2 := strings.ReplaceAll(s2.Text, "Alpha", "First")
	r2 := som.MergeStrippedValue(o2, s2.Text, e2, s2.Pieces)
	if r2.Text != "First (-> A1). Beta [aside]{.aside} gamma (-> B2)." || r2.Restored != 3 {
		t.Errorf("merged %v", r2.ToJSON())
	}
	if back := som.StripNotationText(r2.Text, opts).Text; back != e2 {
		t.Errorf("strips back to %q", back)
	}
}

func TestMergeNonASCII(t *testing.T) {
	type placedAt struct {
		at      int
		removed string
	}
	cases := []struct {
		original string
		drop     bool
		name     string
		find     string
		replace  string
		text     string // "" with a conflict
		restored int
		placed   *placedAt
		conflict string
		lines    []string
	}{
		{original: "Die Größe ist hoch (-> C2.1).", drop: true, name: "trace", find: "hoch",
			replace: "stark gestiegen \U0001F600", text: "Die Größe ist stark gestiegen \U0001F600 (-> C2.1).",
			restored: 1, placed: &placedAt{32, " (-> C2.1)"}},
		{original: "Ein \U0001F600 [schnelles braunes]{.aside} Tier läuft.", name: "aside",
			find: "braunes Tier", replace: "Wesen", conflict: "crossesBoundary", lines: []string{
				"CONFLICT (document) — an edit crosses the boundary of an unmarked element",
				"  O: «Ein \U0001F600 [schnelles braunes]{.aside} Tier läuft.»",
				"  B: «Ein \U0001F600 schnelles braunes Tier läuft.»",
				"  E: «Ein \U0001F600 schnelles Wesen läuft.»",
				"  piece: «]{.aside}»",
			}},
		{original: "Ä Wort{>>Bemerkung über Öl<<} hier.", drop: true, name: "comments", find: "Wort",
			replace: "Begriff", text: "Ä Begriff{>>Bemerkung über Öl<<} hier.", restored: 2},
		{original: "Größe [weil \U0001F600 so]{.aside} gilt.\n\nZweiter Absatz.", drop: true, name: "aside",
			find: "gilt", replace: "bleibt", text: "Größe [weil \U0001F600 so]{.aside} bleibt.\n\nZweiter Absatz.",
			restored: 1},
		{original: "Ein äöüäöüäöüäöüäöüäöü langer Satz mit [schnelles braunes]{.aside} Tier und " +
			"noch viel mehr Text danach äöü.", name: "aside", find: "braunes Tier", replace: "Wesen",
			conflict: "crossesBoundary", lines: []string{
				"CONFLICT (document) — an edit crosses the boundary of an unmarked element",
				"  O: «er Satz mit [schnelles braunes]{.aside} Tier und noch viel m»",
				"  B: «ger Satz mit schnelles braunes Tier und noch viel mehr Text »",
				"  E: «äöü langer Satz mit schnelles Wesen und noch viel mehr Text »",
				"  piece: «]{.aside}»",
			}},
	}
	for i, c := range cases {
		var o som.SpecStripOptions
		if c.drop {
			o = mergeOpts(t, []string{c.name}, nil)
		} else {
			o = mergeOpts(t, nil, []string{c.name})
		}
		st := som.StripNotationText(c.original, o)
		if !strings.Contains(st.Text, c.find) {
			t.Fatalf("nonASCII %d: the edit applies", i)
		}
		edited := strings.Replace(st.Text, c.find, c.replace, 1)
		m := som.MergeStrippedValue(c.original, st.Text, edited, st.Pieces)
		if m.Text != c.text || m.Restored != c.restored {
			t.Errorf("nonASCII %d: %v", i, m.ToJSON())
		}
		switch {
		case c.placed == nil && len(m.Placed) != 0:
			t.Errorf("nonASCII %d: placed %v", i, m.Placed)
		case c.placed != nil && (len(m.Placed) != 1 || m.Placed[0].At != c.placed.at ||
			m.Placed[0].Piece.Removed != c.placed.removed):
			t.Errorf("nonASCII %d: placed %v", i, m.Placed)
		}
		if c.conflict == "" {
			if len(m.Conflicts) != 0 {
				t.Errorf("nonASCII %d: conflicts %v", i, m.ToJSON())
			}
			continue
		}
		if len(m.Conflicts) != 1 || m.Conflicts[0].Code != c.conflict {
			t.Errorf("nonASCII %d: conflicts %v", i, m.ToJSON())
			continue
		}
		if got := m.Conflicts[0].ReportLines(); !reflect.DeepEqual(got, c.lines) {
			t.Errorf("nonASCII %d: report lines\n got %q\nwant %q", i, got, c.lines)
		}
	}
}

func TestMergeLabels(t *testing.T) {
	for _, c := range []struct {
		ref  som.SpecStripValueRef
		want string
	}{
		{som.SpecStripValueRef{Path: "A/B"}, "A/B"},
		{som.SpecStripValueRef{Path: "A/B", Field: "f"}, "A/B / f"},
		{som.SpecStripValueRef{Path: "A/B", Headline: true}, "A/B (headline)"},
	} {
		if got := som.SpecStripMergeLabel(c.ref); got != c.want {
			t.Errorf("label %q, want %q", got, c.want)
		}
	}
}

func TestMergeAnnotationIssues(t *testing.T) {
	if got := som.AnnotationIssuesText("A {++b++} c."); len(got) != 0 {
		t.Errorf("issues %q", got)
	}
	want := []string{"line 0: inline mark \"{++\" is not closed in its paragraph (SOM §11.9.3)"}
	if got := som.AnnotationIssuesText("x {++ open"); !reflect.DeepEqual(got, want) {
		t.Errorf("issues %q", got)
	}
}

// mergeGit runs git in folder; false when it fails or cannot be run.
func mergeGit(folder string, args ...string) bool {
	cmd := exec.Command("git", args...)
	cmd.Dir = folder
	return cmd.Run() == nil
}

// The base read from git, in a scratch repository of the test's own.
func TestMergeGitShowFile(t *testing.T) {
	repo, err := os.MkdirTemp("", "tom_som_go_merge_test_")
	if err != nil {
		t.Fatalf("scratch folder: %v", err)
	}
	defer os.RemoveAll(repo)
	if err := os.MkdirAll(filepath.Join(repo, "sub"), 0o755); err != nil {
		t.Fatalf("scratch folder: %v", err)
	}
	doc := filepath.Join(repo, "doc.md")
	inner := filepath.Join(repo, "sub", "inner.md")
	if err := os.WriteFile(doc, []byte("first ä\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(inner, []byte("inner\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	made := mergeGit(repo, "init", "-q") &&
		mergeGit(repo, "add", "doc.md", "sub/inner.md") &&
		mergeGit(repo, "-c", "user.name=test", "-c", "user.email=test@example.invalid",
			"-c", "commit.gpgsign=false", "-c", "core.hooksPath=/dev/null", "commit", "-q", "-m", "first")
	if !made {
		t.Skip("no git, or the scratch repository could not be made")
	}
	if err := os.WriteFile(doc, []byte("second\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	m := som.SpecStripMerge{}
	if got, ok := m.GitShowFile("HEAD", doc); !ok || got != "first ä\n" {
		t.Errorf("the committed text, not the working tree's: %q %v", got, ok)
	}
	if got, ok := m.GitShowFile("HEAD", inner); !ok || got != "inner\n" {
		t.Errorf("a file in a folder is read from its folder: %q %v", got, ok)
	}
	for _, c := range []struct {
		commit, path, why string
	}{
		{strings.Repeat("0", 40), doc, "an unknown commit gives none"},
		{"HEAD", doc + "x", "an unknown file gives none"},
		{"HEAD", filepath.Join(repo, "none", "doc.md"), "a missing folder gives none"},
		{"--stat", doc, "a commit that reads as an option gives none"},
		{"", doc, "an empty commit gives none"},
	} {
		if got, ok := m.GitShowFile(c.commit, c.path); ok || got != "" {
			t.Errorf("%s: %q", c.why, got)
		}
	}
}
