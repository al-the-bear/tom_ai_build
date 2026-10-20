package somruntime

// spec_answers.go — the answers of a review round, extracted for a step
// folder (SOM §11.9.7). A faithful port of
// `tom_som_dart_runtime/lib/src/spec_answers.dart`.
//
// A step of the TomSpecs process starts by collecting what the reviewer wrote
// into the document — answers to the agent's questions, comments, and
// optionally the questions still open and the inline marks — into the step
// folder's `answers.md`. The annotations stay in the document; this reads
// them through SpecReviewAnnotations.List and never writes.

import (
	"regexp"
	"sort"
	"strconv"
	"strings"
	"unicode"
	"unicode/utf8"
)

// SpecAnswerKind is what an extracted entry is.
type SpecAnswerKind string

const (
	// SpecAnswerKindAnswered is a question with an answer.
	SpecAnswerKindAnswered SpecAnswerKind = "answered"
	// SpecAnswerKindOpen is a question without an answer.
	SpecAnswerKindOpen SpecAnswerKind = "open"
	// SpecAnswerKindComment is a comment block.
	SpecAnswerKindComment SpecAnswerKind = "comment"
	// SpecAnswerKindMark is an inline mark.
	SpecAnswerKindMark SpecAnswerKind = "mark"
)

// SpecAnswerKinds lists every SpecAnswerKind, in declaration order.
var SpecAnswerKinds = []SpecAnswerKind{
	SpecAnswerKindAnswered,
	SpecAnswerKindOpen,
	SpecAnswerKindComment,
	SpecAnswerKindMark,
}

// SpecAnswerEntry is one extracted entry.
type SpecAnswerEntry struct {
	// Kind is what it is.
	Kind SpecAnswerKind
	// ID is the question or comment id (`BQ-81`, `C-12`), or `M-<n>` for a
	// mark; nil for a comment without an id.
	ID *string
	// Section is the section-id chain of the rendition heading the entry sits
	// under (`SBP > INSC > SYSUM`).
	Section string
	// Line is the 1-based line in the document's Markdown rendition.
	Line int
	// Path is the document path of the value holding the entry.
	Path string
	// Field is the form field holding it, or nil for content.
	Field *string
	// Topic is a question's topic.
	Topic *string
	// Combined reports whether a question is part of a combined form block
	// (its topic is then the field it asks about).
	Combined bool
	// Text is a question's text, a comment's text, or a mark's markup.
	Text string
	// Answer is a question's answer ("" when open).
	Answer string
	// Author is a comment's author.
	Author *string
	// MarkKind is a mark's kind ("" for other entries).
	MarkKind SpecMarkKind
	// OldText is a mark's text when rejected.
	OldText *string
	// NewText is a mark's text when accepted.
	NewText *string
	// Comment is a mark's comment.
	Comment *string
}

// ToJSON is the canonical JSON form.
func (e SpecAnswerEntry) ToJSON() map[string]any {
	var markKind any
	if e.MarkKind != "" {
		markKind = string(e.MarkKind)
	}
	return map[string]any{
		"kind":     string(e.Kind),
		"id":       nullableString(e.ID),
		"section":  e.Section,
		"line":     e.Line,
		"path":     e.Path,
		"field":    nullableString(e.Field),
		"topic":    nullableString(e.Topic),
		"combined": e.Combined,
		"text":     e.Text,
		"answer":   e.Answer,
		"author":   nullableString(e.Author),
		"markKind": markKind,
		"oldText":  nullableString(e.OldText),
		"newText":  nullableString(e.NewText),
		"comment":  nullableString(e.Comment),
	}
}

// SpecAnswerCounts are the counts a step's closing item reports.
type SpecAnswerCounts struct {
	// Answered counts questions with an answer.
	Answered int
	// Open counts questions without one.
	Open int
	// Comments counts comment blocks.
	Comments int
	// Marks counts inline marks.
	Marks int
}

// Plus is the sum of two counts.
func (c SpecAnswerCounts) Plus(o SpecAnswerCounts) SpecAnswerCounts {
	return SpecAnswerCounts{
		Answered: c.Answered + o.Answered,
		Open:     c.Open + o.Open,
		Comments: c.Comments + o.Comments,
		Marks:    c.Marks + o.Marks,
	}
}

// ToJSON is the canonical JSON form.
func (c SpecAnswerCounts) ToJSON() map[string]int {
	return map[string]int{
		"answered": c.Answered,
		"open":     c.Open,
		"comments": c.Comments,
		"marks":    c.Marks,
	}
}

// SpecAnswerExtract is the extraction of one document.
type SpecAnswerExtract struct {
	// Label is the document's label in `answers.md` (its file name, e.g.
	// `tom_uam.sbp`).
	Label string
	// Qualifier is the document root's section id, written in front of a
	// comment id (`SBP C-12`).
	Qualifier string
	// Entries holds every entry, in document order.
	Entries []SpecAnswerEntry
}

// Counts returns the counts over Entries.
func (x SpecAnswerExtract) Counts() SpecAnswerCounts {
	var c SpecAnswerCounts
	for _, e := range x.Entries {
		switch e.Kind {
		case SpecAnswerKindAnswered:
			c.Answered++
		case SpecAnswerKindOpen:
			c.Open++
		case SpecAnswerKindComment:
			c.Comments++
		case SpecAnswerKindMark:
			c.Marks++
		}
	}
	return c
}

// ToJSON is the canonical JSON form.
func (x SpecAnswerExtract) ToJSON() map[string]any {
	entries := make([]any, 0, len(x.Entries))
	for _, e := range x.Entries {
		entries = append(entries, e.ToJSON())
	}
	return map[string]any{
		"label":     x.Label,
		"qualifier": x.Qualifier,
		"entries":   entries,
		"counts":    x.Counts().ToJSON(),
	}
}

var answersHeading = regexp.MustCompile(`^(#+) <!--\[([^\]]+)\]-->`)

func answersRootSegment(r *SpecRoot) string {
	if r.SectionID != "" {
		return r.SectionID
	}
	return r.Type
}

func answersUpperFirst(s string) string {
	r, n := utf8.DecodeRuneInString(s)
	if r == utf8.RuneError && n == 0 {
		return s
	}
	return string(unicode.ToUpper(r)) + s[n:]
}

// ExtractAnswers extracts the annotations of doc (or of the subtree at path;
// "" for the whole document) with their place in the document's Markdown
// rendition under model, in rendition order (by line). The error is the
// rendition's (SpecDocumentMarkdown.ExportRootWithMap).
func ExtractAnswers(model *SpecModel, doc *SpecDocument, label, path string) (SpecAnswerExtract, error) {
	var root *SpecRoot
	for _, r := range model.Roots {
		if doc.HasValuesUnder(answersRootSegment(r)) {
			root = r
			break
		}
	}
	if root == nil && len(model.Roots) > 0 {
		root = model.Roots[0]
	}
	if root == nil {
		return SpecAnswerExtract{}, &SpecReviewAnnotationError{Message: "the model has no roots"}
	}
	qualifier := answersRootSegment(root)
	rendition, err := NewSpecDocumentMarkdown(model, doc).ExportRootWithMap(root)
	if err != nil {
		return SpecAnswerExtract{}, err
	}
	lines := strings.Split(rendition.Markdown, "\n")

	// The section-id chain of every heading line (1-based).
	chains := map[int]string{}
	type level struct {
		level int
		id    string
	}
	var stack []level
	for i, line := range lines {
		m := answersHeading.FindStringSubmatch(line)
		if m == nil {
			continue
		}
		lv := len(m[1])
		for len(stack) > 0 && stack[len(stack)-1].level >= lv {
			stack = stack[:len(stack)-1]
		}
		stack = append(stack, level{lv, m[2]})
		ids := make([]string, len(stack))
		for k, s := range stack {
			ids[k] = s.id
		}
		chains[i+1] = strings.Join(ids, " > ")
	}

	headingKeys := make([]int, 0, len(rendition.HeadingPaths))
	for l := range rendition.HeadingPaths {
		headingKeys = append(headingKeys, l)
	}
	sort.Ints(headingKeys)

	// The heading line of a value: the heading whose path is the longest
	// prefix of the value's path (on equal length, the first).
	headingLine := func(valuePath string) int {
		best, bestLen := 0, -1
		for _, l := range headingKeys {
			hp := rendition.HeadingPaths[l]
			if (valuePath == hp || strings.HasPrefix(valuePath, hp+"/")) && len(hp) > bestLen {
				best = l
				bestLen = len(hp)
			}
		}
		return best
	}

	chainAt := func(line int) string {
		for l := line; l >= 1; l-- {
			if c, ok := chains[l]; ok {
				return c
			}
		}
		return qualifier
	}

	claimed := map[int]bool{}
	// The rendition line of an annotation: the first unclaimed line after the
	// value's heading whose trimmed text is the annotation's first line. A
	// form field's first line renders behind its label (`Owner: …`, the field
	// name with its first letter upper-cased).
	locate := func(valuePath string, field *string, valueLine int, firstLine string) int {
		h := headingLine(valuePath)
		want := strings.TrimSpace(firstLine)
		labelled, hasLabelled := "", false
		if field != nil && valueLine == 0 {
			labelled = strings.TrimSpace(answersUpperFirst(*field) + ": " + want)
			hasLabelled = true
		}
		for i := h; i < len(lines); i++ {
			l := i + 1
			if l <= h || claimed[l] {
				continue
			}
			t := strings.TrimSpace(lines[i])
			if t == want || (hasLabelled && t == labelled) {
				claimed[l] = true
				return l
			}
		}
		if h == 0 {
			return 1
		}
		return h
	}

	inScope := func(p string) bool {
		return path == "" || p == path || strings.HasPrefix(p, path+"/")
	}

	api := NewSpecReviewAnnotations(doc, "")
	// List and ListMarks give the marks in the same order.
	marks := api.ListMarks("")
	markIndex := 0
	entries := []SpecAnswerEntry{}
	for _, a := range api.List() {
		// Every mark consumes its listing entry before the scope check, so
		// the marks in a subtree keep their document-wide `M-<n>`.
		var m SpecMarkEntry
		if a.Kind == SpecReviewAnnotationKindMark {
			m = marks[markIndex]
			markIndex++
		}
		if !inScope(a.Path) {
			continue
		}
		var value string
		if a.Field == nil {
			value = doc.ContentOr(a.Path)
		} else {
			value = doc.FormFieldOr(a.Path, *a.Field)
		}
		first := ""
		if vl := strings.Split(value, "\n"); a.Line >= 0 && a.Line < len(vl) {
			first = vl[a.Line]
		}
		switch a.Kind {
		case SpecReviewAnnotationKindQuestion:
			line := locate(a.Path, a.Field, a.Line, first)
			kind := SpecAnswerKindAnswered
			if a.Open() {
				kind = SpecAnswerKindOpen
			}
			entries = append(entries, SpecAnswerEntry{
				Kind:     kind,
				ID:       a.ID,
				Section:  chainAt(line),
				Line:     line,
				Path:     a.Path,
				Field:    a.Field,
				Topic:    a.Topic,
				Combined: a.Combined,
				Text:     a.Text,
				Answer:   a.Answer,
			})
		case SpecReviewAnnotationKindComment:
			line := locate(a.Path, a.Field, a.Line, first)
			entries = append(entries, SpecAnswerEntry{
				Kind:    SpecAnswerKindComment,
				ID:      a.ID,
				Section: chainAt(line),
				Line:    line,
				Path:    a.Path,
				Field:   a.Field,
				Text:    a.Text,
				Author:  a.Author,
			})
		case SpecReviewAnnotationKindMark:
			line := locate(a.Path, a.Field, a.Line, first)
			// A line holding several marks is found once; later marks on it
			// share the line.
			delete(claimed, line)
			id, oldText, newText := m.ID, m.OldText, m.NewText
			entries = append(entries, SpecAnswerEntry{
				Kind:     SpecAnswerKindMark,
				ID:       &id,
				Section:  chainAt(line),
				Line:     line,
				Path:     a.Path,
				Field:    a.Field,
				Text:     m.Markup,
				MarkKind: a.MarkKind,
				OldText:  &oldText,
				NewText:  &newText,
				Comment:  a.Comment,
			})
		}
	}
	// Rendition order: by line; entries on one line keep their order.
	sort.SliceStable(entries, func(i, j int) bool { return entries[i].Line < entries[j].Line })
	return SpecAnswerExtract{Label: label, Qualifier: qualifier, Entries: entries}, nil
}

// SpecAnswerRenderOptions says what `answers.md` includes besides the
// answered questions and comments.
type SpecAnswerRenderOptions struct {
	// IncludeOpen lists the questions still open.
	IncludeOpen bool
	// IncludeMarks lists the inline marks.
	IncludeMarks bool
	// Title is the file's title.
	Title string
}

// DefaultSpecAnswerRenderOptions are the defaults: no open questions, no
// marks, title `Answers`.
func DefaultSpecAnswerRenderOptions() SpecAnswerRenderOptions {
	return SpecAnswerRenderOptions{Title: "Answers"}
}

// answersItem is a labelled value: `- **Label:** first line`, further lines
// indented two spaces.
func answersItem(label, value string) string {
	ls := strings.Split(value, "\n")
	var b strings.Builder
	b.WriteString("- **" + label + ":**")
	if ls[0] != "" {
		b.WriteString(" " + ls[0])
	}
	for _, l := range ls[1:] {
		if l == "" {
			b.WriteString("\n")
		} else {
			b.WriteString("\n  " + l)
		}
	}
	return b.String()
}

func answersPlural(n int, noun string) string {
	if n == 1 {
		return strconv.Itoa(n) + " " + noun
	}
	return strconv.Itoa(n) + " " + noun + "s"
}

func answersCountLine(c SpecAnswerCounts, o SpecAnswerRenderOptions) string {
	parts := []string{
		answersPlural(c.Answered, "answered question"),
		answersPlural(c.Open, "open question"),
		answersPlural(c.Comments, "comment"),
	}
	if o.IncludeMarks {
		parts = append(parts, answersPlural(c.Marks, "inline mark"))
	}
	return strings.Join(parts, ", ") + "."
}

func answersOr(s *string) string {
	if s == nil {
		return "null"
	}
	return *s
}

func answersEntryHeading(x SpecAnswerExtract, e SpecAnswerEntry) string {
	switch e.Kind {
	case SpecAnswerKindComment:
		if e.ID == nil {
			return "Comment without id (line " + strconv.Itoa(e.Line) + ")"
		}
		return x.Qualifier + " " + *e.ID
	case SpecAnswerKindMark:
		return answersOr(e.ID) + " — " + string(e.MarkKind)
	default:
		return answersOr(e.ID) + " — " + answersOr(e.Topic)
	}
}

// RenderAnswers renders extracts as a step folder's `answers.md`:
// deterministic, grouped per document in the order given, entries in
// document order.
func RenderAnswers(extracts []SpecAnswerExtract, options SpecAnswerRenderOptions) string {
	var total SpecAnswerCounts
	for _, x := range extracts {
		total = total.Plus(x.Counts())
	}
	out := []string{"# " + options.Title, "", answersCountLine(total, options)}
	for _, x := range extracts {
		out = append(out, "", "## "+x.Label, "", answersCountLine(x.Counts(), options))
		section := func(heading string, kind SpecAnswerKind) {
			var es []SpecAnswerEntry
			for _, e := range x.Entries {
				if e.Kind == kind {
					es = append(es, e)
				}
			}
			out = append(out, "", "### "+heading)
			if len(es) == 0 {
				out = append(out, "", "None.")
				return
			}
			for _, e := range es {
				out = append(out,
					"",
					"#### "+answersEntryHeading(x, e),
					"",
					answersItem("Section", "`"+e.Section+"`"),
					answersItem("Line", strconv.Itoa(e.Line)),
				)
				if e.Field != nil {
					out = append(out, answersItem("Field", "`"+*e.Field+"`"))
				}
				switch kind {
				case SpecAnswerKindAnswered, SpecAnswerKindOpen:
					out = append(out, answersItem("Question", e.Text))
					if kind == SpecAnswerKindAnswered {
						out = append(out, answersItem("Answer", e.Answer))
					}
				case SpecAnswerKindComment:
					if e.Author != nil {
						out = append(out, answersItem("Author", *e.Author))
					}
					out = append(out, answersItem("Comment", e.Text))
				case SpecAnswerKindMark:
					oldText, newText := "", ""
					if e.OldText != nil {
						oldText = *e.OldText
					}
					if e.NewText != nil {
						newText = *e.NewText
					}
					out = append(out,
						answersItem("Markup", "`"+e.Text+"`"),
						answersItem("Old", oldText),
						answersItem("New", newText),
					)
					if e.Comment != nil {
						out = append(out, answersItem("Note", *e.Comment))
					}
				}
			}
		}
		section("Answered questions", SpecAnswerKindAnswered)
		section("Comments", SpecAnswerKindComment)
		if options.IncludeOpen {
			section("Open questions", SpecAnswerKindOpen)
		}
		if options.IncludeMarks {
			section("Inline marks", SpecAnswerKindMark)
		}
	}
	return strings.Join(out, "\n") + "\n"
}
