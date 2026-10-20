package somruntime

// spec_review_annotations.go — review annotations in content values (SOM
// §11.9): comment blocks, question blocks and CriticMarkup inline marks. A
// faithful port of `tom_som_dart_runtime/lib/src/spec_review_annotations.dart`.
//
// An annotation is text inside a content value or a form-field value. This
// file reads it out of that text and edits it in place, and every edit is
// byte-stable outside the annotation it touches.
//
// Positions are **0-based line numbers within the value**, never character
// offsets: the nine runtimes count characters in different units, and a line
// number is the same in all of them. Byte offsets are used internally only.

import (
	"regexp"
	"sort"
	"strconv"
	"strings"
	"unicode"
	"unicode/utf8"
)

// SpecReviewAnnotationKind is one of the three kinds of annotation (SOM §11.9).
type SpecReviewAnnotationKind string

const (
	// SpecReviewAnnotationKindComment is a reviewer's comment block,
	// `> ⬆️ **C-12** (Alexis): …`.
	SpecReviewAnnotationKindComment SpecReviewAnnotationKind = "comment"
	// SpecReviewAnnotationKindQuestion is one question of a question block,
	// `> **❓ BQ-81 — topic:** …`.
	SpecReviewAnnotationKindQuestion SpecReviewAnnotationKind = "question"
	// SpecReviewAnnotationKindMark is a CriticMarkup inline mark.
	SpecReviewAnnotationKindMark SpecReviewAnnotationKind = "mark"
)

// SpecReviewAnnotationKinds lists every SpecReviewAnnotationKind, in
// declaration order.
var SpecReviewAnnotationKinds = []SpecReviewAnnotationKind{
	SpecReviewAnnotationKindComment,
	SpecReviewAnnotationKindQuestion,
	SpecReviewAnnotationKindMark,
}

// SpecMarkKind is one of the five CriticMarkup inline marks (SOM §11.9.3).
type SpecMarkKind string

const (
	// SpecMarkKindComment is `{>> comment <<}`.
	SpecMarkKindComment SpecMarkKind = "comment"
	// SpecMarkKindHighlight is `{== text ==}`, optionally followed by
	// `{>> comment <<}`.
	SpecMarkKindHighlight SpecMarkKind = "highlight"
	// SpecMarkKindInsertion is `{++ added ++}`.
	SpecMarkKindInsertion SpecMarkKind = "insertion"
	// SpecMarkKindDeletion is `{-- removed --}`.
	SpecMarkKindDeletion SpecMarkKind = "deletion"
	// SpecMarkKindSubstitution is `{~~ old ~> new ~~}`.
	SpecMarkKindSubstitution SpecMarkKind = "substitution"
)

// SpecMarkKinds lists every SpecMarkKind, in declaration order.
var SpecMarkKinds = []SpecMarkKind{
	SpecMarkKindComment,
	SpecMarkKindHighlight,
	SpecMarkKindInsertion,
	SpecMarkKindDeletion,
	SpecMarkKindSubstitution,
}

// SpecReviewAnnotation is one annotation, located by the value that holds it.
// A nil pointer field is the corpus's `null`.
type SpecReviewAnnotation struct {
	// Kind is the annotation kind.
	Kind SpecReviewAnnotationKind
	// Path is the document path of the value: a content path, or a form path
	// when Field is set.
	Path string
	// Field is the form field whose value holds the annotation; nil for
	// content.
	Field *string
	// Line is the 0-based line within the value where the annotation starts (a
	// question: its header line).
	Line int
	// ID is the comment id (`C-12`) or question id (`BQ-81`); nil for a comment
	// without an id and for a mark.
	ID *string
	// QualifiedID is a comment's id with the document qualifier in front
	// (`SBP C-12`), when the listing was given a qualifier and the comment has
	// an id.
	QualifiedID *string
	// Author is a comment's author; nil when none is written.
	Author *string
	// Text is a comment's text, a question's text (options included), or a
	// mark's text (the added, removed or highlighted text; a substitution's
	// old text; empty for a comment mark).
	Text string
	// Context is a comment's context: the paragraph before the block,
	// verbatim (empty at the start of the value).
	Context string
	// Topic is a question's topic (in a combined block: the field it asks
	// about).
	Topic *string
	// Starred reports whether a question carries `★` before its topic.
	Starred bool
	// Combined reports whether a question is part of a combined block
	// (`**❓ Open questions on these fields**`).
	Combined bool
	// Answer is a question's answer, trimmed; empty when open.
	Answer string
	// MarkKind is a mark's kind; empty for a comment or question.
	MarkKind SpecMarkKind
	// NewText is a substitution's new text.
	NewText *string
	// Comment is the comment of a comment mark, or of a highlight followed by
	// one.
	Comment *string
}

// Open reports whether a question is still open (no answer written).
func (a SpecReviewAnnotation) Open() bool {
	return a.Kind == SpecReviewAnnotationKindQuestion && a.Answer == ""
}

func nullableString(s *string) any {
	if s == nil {
		return nil
	}
	return *s
}

// ToJSON is the canonical JSON form the conformance corpus pins.
func (a SpecReviewAnnotation) ToJSON() map[string]any {
	switch a.Kind {
	case SpecReviewAnnotationKindComment:
		return map[string]any{
			"kind":        "comment",
			"path":        a.Path,
			"field":       nullableString(a.Field),
			"line":        a.Line,
			"id":          nullableString(a.ID),
			"qualifiedId": nullableString(a.QualifiedID),
			"author":      nullableString(a.Author),
			"text":        a.Text,
			"context":     a.Context,
		}
	case SpecReviewAnnotationKindQuestion:
		return map[string]any{
			"kind":     "question",
			"path":     a.Path,
			"field":    nullableString(a.Field),
			"line":     a.Line,
			"id":       nullableString(a.ID),
			"topic":    nullableString(a.Topic),
			"starred":  a.Starred,
			"combined": a.Combined,
			"text":     a.Text,
			"answer":   a.Answer,
			"open":     a.Open(),
		}
	default:
		return map[string]any{
			"kind":     "mark",
			"path":     a.Path,
			"field":    nullableString(a.Field),
			"line":     a.Line,
			"markKind": string(a.MarkKind),
			"text":     a.Text,
			"newText":  nullableString(a.NewText),
			"comment":  nullableString(a.Comment),
		}
	}
}

// SpecReviewAnnotationCounts holds the counts a report needs (SOM §11.9).
type SpecReviewAnnotationCounts struct {
	Questions         int
	OpenQuestions     int
	AnsweredQuestions int
	Comments          int
	Marks             int
}

// ToJSON is the canonical JSON form.
func (c SpecReviewAnnotationCounts) ToJSON() map[string]int {
	return map[string]int{
		"questions":         c.Questions,
		"openQuestions":     c.OpenQuestions,
		"answeredQuestions": c.AnsweredQuestions,
		"comments":          c.Comments,
		"marks":             c.Marks,
	}
}

// SpecQuestionDraft is a question to insert (SOM §11.9.2).
type SpecQuestionDraft struct {
	// ID is the question id (`BQ-90`).
	ID string
	// Topic is the topic.
	Topic string
	// Text is the question text; may span lines.
	Text string
	// Options are option lines, written as `- <option>`.
	Options []string
	// Recommendation is the recommendation, or empty.
	Recommendation string
	// Assumption is the working assumption, or empty.
	Assumption string
	// Starred reports whether the question carries `★`.
	Starred bool
}

// SpecReviewAnnotationError is returned when an operation names an
// annotation, value or paragraph that does not exist. Nothing is changed.
type SpecReviewAnnotationError struct {
	Message string
}

func (e *SpecReviewAnnotationError) Error() string {
	return "SpecReviewAnnotationError: " + e.Message
}

// ---------------------------------------------------------------------------
// Text level: one value.
// ---------------------------------------------------------------------------

const (
	annArrow          = "⬆"
	annVS16           = "️"
	annQuestionOpen   = "**❓"
	annCombinedOpener = "**❓ Open questions on these fields**"
	annAnswerLabel    = "**Answer:**"
	annEmDashSep      = " — "
	annStar           = "★"
)

var (
	annCommentNumber = regexp.MustCompile(`^[1-9][0-9]*$`)
	annQuestionID    = regexp.MustCompile(`^[A-Z][A-Z0-9]*-[0-9]+$`)
)

// annBlock is one parsed block of a value (lines [start, end] inclusive).
type annBlock struct {
	start, end int
	kind       SpecReviewAnnotationKind
	comment    *annComment    // comment blocks
	questions  []*annQuestion // question blocks
	combined   bool
}

// annQuestion is one question region inside a question block.
type annQuestion struct {
	header     int // value line of the header
	regionEnd  int // last value line of the region (inclusive)
	answerLine int // value line of `**Answer:**`, or -1
	id         string
	topic      string
	starred    bool
	text       string
	answer     string
}

// annComment is one parsed comment block.
type annComment struct {
	block        *annBlock
	id           *string
	author       *string
	text         string
	context      string
	headerPrefix string // the first line up to where the text starts
	markerEnd    int    // where an id is inserted into the first line
}

// annMark is one parsed mark; start/end are byte offsets into the value.
type annMark struct {
	start, end int
	line       int
	kind       SpecMarkKind
	text       string
	newText    *string
	comment    *string
}

// annParsed is everything one value holds.
type annParsed struct {
	lines     []string
	code      []bool
	blocks    []*annBlock
	comments  []*annComment
	marks     []*annMark
	malformed []string
}

func annLstrip(s string) string {
	return strings.TrimLeft(s, " \t")
}

func annIsBlank(s string) bool { return strings.TrimSpace(s) == "" }

// annCodeLines is the fenced-code flag of every line.
func annCodeLines(lines []string) []bool {
	code := make([]bool, len(lines))
	var fenceChar byte
	fenceLen := 0
	for i, l := range lines {
		t := annLstrip(l)
		if fenceChar == 0 {
			if t != "" && (t[0] == '`' || t[0] == '~') {
				c := t[0]
				n := 0
				for n < len(t) && t[n] == c {
					n++
				}
				if n >= 3 {
					fenceChar = c
					fenceLen = n
					code[i] = true
				}
			}
		} else {
			code[i] = true
			n := 0
			for n < len(t) && t[n] == fenceChar {
				n++
			}
			if n >= fenceLen && strings.TrimSpace(t[n:]) == "" {
				fenceChar = 0
			}
		}
	}
	return code
}

func annIsQuoteLine(line string) bool { return strings.HasPrefix(annLstrip(line), ">") }

// annInner is the line inside the quote: after `>` and one following space.
func annInner(line string) string {
	t := annLstrip(line)
	if t == "" {
		return ""
	}
	s := t[1:]
	return strings.TrimPrefix(s, " ")
}

func annParse(value string) *annParsed {
	lines := strings.Split(value, "\n")
	code := annCodeLines(lines)
	p := &annParsed{lines: lines, code: code}

	i := 0
	for i < len(lines) {
		if code[i] || !annIsQuoteLine(lines[i]) {
			i++
			continue
		}
		s := i
		for i+1 < len(lines) && !code[i+1] && annIsQuoteLine(lines[i+1]) {
			i++
		}
		e := i
		first := annInner(lines[s])
		if strings.HasPrefix(first, annArrow) {
			b := &annBlock{start: s, end: e, kind: SpecReviewAnnotationKindComment}
			p.blocks = append(p.blocks, b)
			c := annParseComment(p, b)
			b.comment = c
			p.comments = append(p.comments, c)
		} else if strings.HasPrefix(first, annQuestionOpen) {
			b := &annBlock{start: s, end: e, kind: SpecReviewAnnotationKindQuestion}
			p.blocks = append(p.blocks, b)
			annParseQuestions(p, b)
		}
		i = e + 1
	}

	annParseMarks(p)
	return p
}

func annContext(p *annParsed, blockStart int) string {
	k := blockStart - 1
	for k >= 0 && (annIsBlank(p.lines[k]) || annIsQuoteLine(p.lines[k])) {
		k--
	}
	if k < 0 {
		return ""
	}
	end := k
	for k-1 >= 0 && !annIsBlank(p.lines[k-1]) && !annIsQuoteLine(p.lines[k-1]) {
		k--
	}
	return strings.Join(p.lines[k:end+1], "\n")
}

func annParseComment(p *annParsed, b *annBlock) *annComment {
	raw0 := p.lines[b.start]
	rest := strings.TrimPrefix(annInner(raw0), annArrow)
	rest = strings.TrimPrefix(rest, annVS16)
	markerEnd := len(raw0) - len(rest)
	rest = annLstrip(rest)
	var id *string
	if strings.HasPrefix(rest, "**C-") {
		if rel := strings.Index(rest[4:], "**"); rel >= 0 {
			closeAt := 4 + rel
			n := rest[4:closeAt]
			if annCommentNumber.MatchString(n) {
				v := "C-" + n
				id = &v
			} else {
				p.malformed = append(p.malformed,
					"line "+strconv.Itoa(b.start)+": comment id \"C-"+n+
						"\" is not C-<number> (SOM §11.9.1)")
			}
			rest = annLstrip(rest[closeAt+2:])
		}
	}
	var author *string
	if strings.HasPrefix(rest, "(") {
		if closeAt := strings.Index(rest, ")"); closeAt > 0 {
			a := rest[1:closeAt]
			author = &a
			rest = rest[closeAt+1:]
			rest = strings.TrimPrefix(rest, ":")
			rest = annLstrip(rest)
		}
	} else if strings.HasPrefix(rest, ":") {
		rest = annLstrip(rest[1:])
	}
	headerPrefix := raw0[:len(raw0)-len(rest)]
	textLines := []string{rest}
	for k := b.start + 1; k <= b.end; k++ {
		inner := annInner(p.lines[k])
		t := annLstrip(inner)
		if strings.HasPrefix(t, annQuestionOpen) || strings.HasPrefix(t, annAnswerLabel) {
			p.malformed = append(p.malformed,
				"line "+strconv.Itoa(k)+": a comment block holds a question or an "+
					"answer; the question goes into its own block after the comment "+
					"(SOM §11.9.1)")
		}
		textLines = append(textLines, inner)
	}
	return &annComment{
		block:        b,
		id:           id,
		author:       author,
		text:         strings.TrimSpace(strings.Join(textLines, "\n")),
		context:      annContext(p, b.start),
		headerPrefix: headerPrefix,
		markerEnd:    markerEnd,
	}
}

type annHeader struct {
	id, topic, rest string
	starred         bool
}

// annParseHeader parses a question header's remainder after `**❓ `; ok=false
// when malformed.
func annParseHeader(inner string) (annHeader, bool) {
	h := inner[len(annQuestionOpen)+1:]
	sep := strings.Index(h, annEmDashSep)
	if sep <= 0 {
		return annHeader{}, false
	}
	id := h[:sep]
	if !annQuestionID.MatchString(id) {
		return annHeader{}, false
	}
	t := h[sep+len(annEmDashSep):]
	starred := false
	if strings.HasPrefix(t, annStar+" ") {
		starred = true
		t = t[len(annStar)+1:]
	}
	closeAt := strings.Index(t, ":**")
	if closeAt < 0 {
		return annHeader{}, false
	}
	topic := t[:closeAt]
	rest := strings.TrimPrefix(t[closeAt+3:], " ")
	return annHeader{id: id, topic: topic, rest: rest, starred: starred}, true
}

func annParseQuestions(p *annParsed, b *annBlock) {
	var inner []string
	for k := b.start; k <= b.end; k++ {
		inner = append(inner, annInner(p.lines[k]))
	}
	b.combined = strings.HasPrefix(inner[0], annCombinedOpener)
	var keys []int
	headers := map[int]annHeader{}
	for k := range inner {
		if !strings.HasPrefix(inner[k], annQuestionOpen+" ") {
			continue
		}
		if strings.HasPrefix(inner[k], annCombinedOpener) {
			continue
		}
		h, ok := annParseHeader(inner[k])
		if !ok {
			p.malformed = append(p.malformed,
				"line "+strconv.Itoa(b.start+k)+": question header is not "+
					"\"**❓ <ID> — <topic>:**\" (SOM §11.9.2)")
			continue
		}
		headers[k] = h
		keys = append(keys, k)
	}
	for q, k := range keys {
		h := headers[k]
		regionEnd := len(inner) - 1
		if q+1 < len(keys) {
			regionEnd = keys[q+1] - 1
		}
		answer := -1
		for m := k + 1; m <= regionEnd; m++ {
			if strings.HasPrefix(inner[m], annAnswerLabel) {
				answer = m
				break
			}
		}
		textEnd := regionEnd
		if answer >= 0 {
			textEnd = answer - 1
		}
		textParts := append([]string{h.rest}, inner[k+1:textEnd+1]...)
		text := strings.TrimSpace(strings.Join(textParts, "\n"))
		answerText := ""
		answerLine := -1
		if answer >= 0 {
			parts := append([]string{inner[answer][len(annAnswerLabel):]}, inner[answer+1:regionEnd+1]...)
			answerText = strings.TrimSpace(strings.Join(parts, "\n"))
			answerLine = b.start + answer
		}
		b.questions = append(b.questions, &annQuestion{
			header:     b.start + k,
			regionEnd:  b.start + regionEnd,
			answerLine: answerLine,
			id:         h.id,
			topic:      h.topic,
			starred:    h.starred,
			text:       text,
			answer:     answerText,
		})
	}
}

var annOpeners = []string{"{>>", "{==", "{++", "{--", "{~~"}

var annClosers = map[string]string{
	"{>>": "<<}",
	"{==": "==}",
	"{++": "++}",
	"{--": "--}",
	"{~~": "~~}",
}

func annIndexFrom(s, sub string, from int) int {
	if from > len(s) {
		return -1
	}
	i := strings.Index(s[from:], sub)
	if i < 0 {
		return -1
	}
	return from + i
}

func annContainsOpener(s string) bool {
	for _, o := range annOpeners {
		if strings.Contains(s, o) {
			return true
		}
	}
	return false
}

// annParagraphEnd is the offset of the first `\n` after from whose following
// line is blank (the paragraph end), or the text length.
func annParagraphEnd(text string, from int) int {
	i := annIndexFrom(text, "\n", from)
	for i >= 0 {
		next := annIndexFrom(text, "\n", i+1)
		end := next
		if next < 0 {
			end = len(text)
		}
		if strings.TrimSpace(text[i+1:end]) == "" {
			return i
		}
		i = next
	}
	return len(text)
}

func annParseMarks(p *annParsed) {
	lineStart := make([]int, 0, len(p.lines))
	off := 0
	for _, l := range p.lines {
		lineStart = append(lineStart, off)
		off += len(l) + 1
	}
	value := strings.Join(p.lines, "\n")
	lineOf := func(offset int) int {
		lo := 0
		for k, s := range lineStart {
			if s <= offset {
				lo = k
			}
		}
		return lo
	}
	k := 0
	for k < len(p.lines) {
		if p.code[k] {
			k++
			continue
		}
		segStartLine := k
		for k < len(p.lines) && !p.code[k] {
			k++
		}
		segStart := lineStart[segStartLine]
		segEnd := lineStart[k-1] + len(p.lines[k-1])
		annScanSegment(p, value[segStart:segEnd], segStart, lineOf)
	}
}

func annScanSegment(p *annParsed, seg string, base int, lineOf func(int) int) {
	i := 0
	for i < len(seg) {
		c := seg[i]
		if c == '`' {
			n := 0
			for i+n < len(seg) && seg[i+n] == '`' {
				n++
			}
			j := i + n
			closeAt := -1
			for j < len(seg) {
				if seg[j] == '`' {
					m := 0
					for j+m < len(seg) && seg[j+m] == '`' {
						m++
					}
					if m == n {
						closeAt = j
						break
					}
					j += m
				} else {
					j++
				}
			}
			if closeAt < 0 {
				i += n
			} else {
				i = closeAt + n
			}
			continue
		}
		if c != '{' || i+3 > len(seg) {
			i++
			continue
		}
		opener := seg[i : i+3]
		closer, known := annClosers[opener]
		if !known {
			i++
			continue
		}
		closeAt := annIndexFrom(seg, closer, i+3)
		pend := annParagraphEnd(seg, i)
		line := lineOf(base + i)
		if closeAt < 0 || closeAt > pend {
			p.malformed = append(p.malformed,
				"line "+strconv.Itoa(line)+": inline mark \""+opener+
					"\" is not closed in its paragraph (SOM §11.9.3)")
			i += 3
			continue
		}
		inner := seg[i+3 : closeAt]
		if annContainsOpener(inner) {
			p.malformed = append(p.malformed,
				"line "+strconv.Itoa(line)+": inline marks do not nest (SOM §11.9.3)")
			i = closeAt + 3
			continue
		}
		end := closeAt + 3
		switch opener {
		case "{>>":
			cm := strings.TrimSpace(inner)
			p.marks = append(p.marks, &annMark{base + i, base + end, line, SpecMarkKindComment, "", nil, &cm})
		case "{==":
			var comment *string
			if strings.HasPrefix(seg[end:], "{>>") {
				c2 := annIndexFrom(seg, "<<}", end+3)
				if c2 >= 0 && c2 <= annParagraphEnd(seg, end) {
					ci := seg[end+3 : c2]
					if !annContainsOpener(ci) {
						cm := strings.TrimSpace(ci)
						comment = &cm
						end = c2 + 3
					}
				}
			}
			p.marks = append(p.marks, &annMark{base + i, base + end, line, SpecMarkKindHighlight, strings.TrimSpace(inner), nil, comment})
		case "{++":
			p.marks = append(p.marks, &annMark{base + i, base + end, line, SpecMarkKindInsertion, strings.TrimSpace(inner), nil, nil})
		case "{--":
			p.marks = append(p.marks, &annMark{base + i, base + end, line, SpecMarkKindDeletion, strings.TrimSpace(inner), nil, nil})
		case "{~~":
			arrow := strings.Index(inner, "~>")
			if arrow < 0 {
				p.malformed = append(p.malformed,
					"line "+strconv.Itoa(line)+": a substitution has no \"~>\" (SOM §11.9.3)")
				i = end
				continue
			}
			nt := strings.TrimSpace(inner[arrow+2:])
			p.marks = append(p.marks, &annMark{base + i, base + end, line, SpecMarkKindSubstitution, strings.TrimSpace(inner[:arrow]), &nt, nil})
		}
		i = end
	}
}

func annFieldPtr(field string) *string {
	if field == "" {
		return nil
	}
	f := field
	return &f
}

// annAnnotationsOf lists the annotations of one value, in order: by line,
// blocks before marks, marks in scan order.
func annAnnotationsOf(p *annParsed, path, field, qualifier string) []SpecReviewAnnotation {
	type entry struct {
		line, rank, seq int
		a               SpecReviewAnnotation
	}
	var out []entry
	seq := 0
	fp := annFieldPtr(field)
	for _, b := range p.blocks {
		if b.kind == SpecReviewAnnotationKindComment {
			c := b.comment
			var qualified *string
			if qualifier != "" && c.id != nil {
				q := qualifier + " " + *c.id
				qualified = &q
			}
			out = append(out, entry{b.start, 0, seq, SpecReviewAnnotation{
				Kind:        SpecReviewAnnotationKindComment,
				Path:        path,
				Field:       fp,
				Line:        b.start,
				ID:          c.id,
				QualifiedID: qualified,
				Author:      c.author,
				Text:        c.text,
				Context:     c.context,
			}})
			seq++
			continue
		}
		for _, q := range b.questions {
			id, topic := q.id, q.topic
			out = append(out, entry{q.header, 0, seq, SpecReviewAnnotation{
				Kind:     SpecReviewAnnotationKindQuestion,
				Path:     path,
				Field:    fp,
				Line:     q.header,
				ID:       &id,
				Topic:    &topic,
				Starred:  q.starred,
				Combined: b.combined,
				Text:     q.text,
				Answer:   q.answer,
			}})
			seq++
		}
	}
	for _, m := range p.marks {
		out = append(out, entry{m.line, 1, seq, SpecReviewAnnotation{
			Kind:     SpecReviewAnnotationKindMark,
			Path:     path,
			Field:    fp,
			Line:     m.line,
			MarkKind: m.kind,
			Text:     m.text,
			NewText:  m.newText,
			Comment:  m.comment,
		}})
		seq++
	}
	sort.SliceStable(out, func(x, y int) bool {
		a, b := out[x], out[y]
		if a.line != b.line {
			return a.line < b.line
		}
		if a.rank != b.rank {
			return a.rank < b.rank
		}
		return a.seq < b.seq
	})
	res := make([]SpecReviewAnnotation, len(out))
	for k, e := range out {
		res[k] = e.a
	}
	return res
}

// annParagraphs lists the paragraphs of a value as [first line, last line],
// blank-separated and fence-aware.
func annParagraphs(lines []string, code []bool) [][2]int {
	var out [][2]int
	k := 0
	for k < len(lines) {
		if annIsBlank(lines[k]) && !code[k] {
			k++
			continue
		}
		s := k
		for k+1 < len(lines) && !(annIsBlank(lines[k+1]) && !code[k+1]) {
			k++
		}
		out = append(out, [2]int{s, k})
		k++
	}
	return out
}

// annInsertAfterLine inserts block after value line end (-1: at the start),
// one blank line on each side.
func annInsertAfterLine(value string, end int, block []string) string {
	if value == "" {
		return strings.Join(block, "\n")
	}
	lines := strings.Split(value, "\n")
	before := lines[:end+1]
	rest := lines[end+1:]
	out := append([]string{}, before...)
	if len(before) > 0 {
		out = append(out, "")
	}
	out = append(out, block...)
	if len(rest) > 0 {
		if !annIsBlank(rest[0]) {
			out = append(out, "")
		}
		out = append(out, rest...)
	}
	return strings.Join(out, "\n")
}

// annRemoveLines removes value lines [s, e] and one adjacent blank line.
func annRemoveLines(value string, s, e int) string {
	lines := strings.Split(value, "\n")
	from, to := s, e
	if to+1 < len(lines) && annIsBlank(lines[to+1]) {
		to++
	} else if from-1 >= 0 && annIsBlank(lines[from-1]) {
		from--
	}
	kept := append(append([]string{}, lines[:from]...), lines[to+1:]...)
	out := strings.Join(kept, "\n")
	if strings.TrimSpace(out) == "" {
		return ""
	}
	return out
}

func annQuoted(lines []string) []string {
	out := make([]string, 0, len(lines))
	for _, l := range lines {
		if l == "" {
			out = append(out, ">")
		} else {
			out = append(out, "> "+l)
		}
	}
	return out
}

// FormatCommentBlock returns the lines of a comment block; author "" writes
// none.
func FormatCommentBlock(id, text, author string) []string {
	t := strings.Split(text, "\n")
	head := "> " + annArrow + annVS16 + " **" + id + "**"
	if author != "" {
		head += " (" + author + "):"
	}
	if t[0] != "" {
		head += " " + t[0]
	}
	return append([]string{head}, annQuoted(t[1:])...)
}

// FormatQuestionBlock returns the lines of a question block.
func FormatQuestionBlock(q SpecQuestionDraft) []string {
	t := strings.Split(q.Text, "\n")
	star := ""
	if q.Starred {
		star = annStar + " "
	}
	lines := []string{"> " + annQuestionOpen + " " + q.ID + annEmDashSep + star + q.Topic + ":** " + t[0]}
	lines = append(lines, annQuoted(t[1:])...)
	for _, o := range q.Options {
		lines = append(lines, "> - "+o)
	}
	if q.Recommendation != "" || q.Assumption != "" {
		lines = append(lines, ">")
		if q.Recommendation != "" {
			lines = append(lines, "> *Recommendation:* "+q.Recommendation)
		}
		if q.Assumption != "" {
			lines = append(lines, "> *Working assumption until answered:* "+q.Assumption)
		}
	}
	return append(lines, ">", "> "+annAnswerLabel)
}

// annReplaceMark applies a mark's replacement and tidies the one space a
// removal leaves.
func annReplaceMark(value string, m *annMark, replacement string) string {
	before := value[:m.start]
	after := value[m.end:]
	if replacement == "" {
		if strings.HasSuffix(before, " ") &&
			(after == "" || after[0] == ' ' || after[0] == '\n' ||
				strings.IndexByte(".,;:!?)", after[0]) >= 0) {
			before = before[:len(before)-1]
		} else if (before == "" || strings.HasSuffix(before, "\n")) &&
			strings.HasPrefix(after, " ") {
			after = after[1:]
		}
	} else {
		// Never join two words: a mark written flush against a word keeps a
		// space on that side.
		if annLastIsWord(before) && annFirstIsWord(replacement) {
			replacement = " " + replacement
		}
		if annLastIsWord(replacement) && annFirstIsWord(after) {
			replacement = replacement + " "
		}
	}
	return before + replacement + after
}

// annIsWordRune: letters (lowercase ≠ uppercase, any script) and ASCII digits.
func annIsWordRune(r rune) bool {
	return unicode.ToLower(r) != unicode.ToUpper(r) || (r >= '0' && r <= '9')
}

func annFirstIsWord(s string) bool {
	if s == "" {
		return false
	}
	r, _ := utf8.DecodeRuneInString(s)
	return annIsWordRune(r)
}

func annLastIsWord(s string) bool {
	if s == "" {
		return false
	}
	r, _ := utf8.DecodeLastRuneInString(s)
	return annIsWordRune(r)
}

func annMarkReplacement(m *annMark, accept bool) string {
	switch m.kind {
	case SpecMarkKindInsertion:
		if accept {
			return m.text
		}
		return ""
	case SpecMarkKindDeletion:
		if accept {
			return ""
		}
		return m.text
	case SpecMarkKindSubstitution:
		if accept {
			return *m.newText
		}
		return m.text
	case SpecMarkKindHighlight:
		return m.text
	default:
		return ""
	}
}

// StripAnnotationsText returns value without any comment block, question
// block or inline mark (every mark accepted). Plain quotes and code stay.
func StripAnnotationsText(value string) string {
	v := value
	// Blocks, from the last up, so earlier line numbers stay valid.
	for {
		p := annParse(v)
		if len(p.blocks) == 0 {
			break
		}
		b := p.blocks[len(p.blocks)-1]
		v = annRemoveLines(v, b.start, b.end)
	}
	for {
		p := annParse(v)
		if len(p.marks) == 0 {
			break
		}
		m := p.marks[len(p.marks)-1]
		v = annReplaceMark(v, m, annMarkReplacement(m, true))
	}
	return v
}

// ---------------------------------------------------------------------------
// Document level.
// ---------------------------------------------------------------------------

// SpecReviewAnnotations holds the annotations of a document and the
// operations that edit them (SOM §11.9). Values are visited in a fixed order —
// content paths sorted, then form paths sorted with their field names sorted —
// so "document order" is the same in every runtime.
type SpecReviewAnnotations struct {
	// Doc is the document.
	Doc *SpecDocument
	// Qualifier is the document's id or name, written in front of a comment
	// id cited outside the document (`SBP` → `SBP C-12`); "" for bare ids.
	Qualifier string
}

// NewSpecReviewAnnotations wraps doc; qualifier "" lists bare ids.
func NewSpecReviewAnnotations(doc *SpecDocument, qualifier string) *SpecReviewAnnotations {
	return &SpecReviewAnnotations{Doc: doc, Qualifier: qualifier}
}

type annValue struct {
	path, field, text string // field "" for content
}

func (r *SpecReviewAnnotations) values() []annValue {
	var out []annValue
	for _, path := range sortedCopy(r.Doc.ContentPaths()) {
		out = append(out, annValue{path, "", r.Doc.ContentOr(path)})
	}
	for _, path := range sortedCopy(r.Doc.FormPaths()) {
		for _, f := range sortedCopy(r.Doc.FormFieldNames(path)) {
			out = append(out, annValue{path, f, r.Doc.FormFieldOr(path, f)})
		}
	}
	return out
}

func (r *SpecReviewAnnotations) get(path, field string) string {
	if field == "" {
		return r.Doc.ContentOr(path)
	}
	return r.Doc.FormFieldOr(path, field)
}

func (r *SpecReviewAnnotations) set(path, field, value string) {
	if field == "" {
		r.Doc.SetContent(path, value)
	} else {
		r.Doc.SetFormField(path, field, value)
	}
}

// List returns every annotation, in document order.
func (r *SpecReviewAnnotations) List() []SpecReviewAnnotation {
	out := []SpecReviewAnnotation{}
	for _, v := range r.values() {
		out = append(out, annAnnotationsOf(annParse(v.text), v.path, v.field, r.Qualifier)...)
	}
	return out
}

// Counts returns the counts a report needs.
func (r *SpecReviewAnnotations) Counts() SpecReviewAnnotationCounts {
	var c SpecReviewAnnotationCounts
	for _, a := range r.List() {
		switch a.Kind {
		case SpecReviewAnnotationKindQuestion:
			c.Questions++
			if a.Open() {
				c.OpenQuestions++
			}
		case SpecReviewAnnotationKindComment:
			c.Comments++
		case SpecReviewAnnotationKindMark:
			c.Marks++
		}
	}
	c.AnsweredQuestions = c.Questions - c.OpenQuestions
	return c
}

func (r *SpecReviewAnnotations) highestCommentNumber() int {
	high := 0
	for _, a := range r.List() {
		if a.Kind == SpecReviewAnnotationKindComment && a.ID != nil {
			if n, err := strconv.Atoi((*a.ID)[2:]); err == nil && n > high {
				high = n
			}
		}
	}
	return high
}

// NextCommentID returns the id the next comment gets: `C-<n>`, n = the
// highest number in the document (or floor, when higher) plus one. Writes
// nothing.
func (r *SpecReviewAnnotations) NextCommentID(floor int) string {
	high := r.highestCommentNumber()
	if floor > high {
		high = floor
	}
	return "C-" + strconv.Itoa(high+1)
}

// AssignCommentIDs gives every comment without an id the next one, in
// document order, and returns the ids assigned. Nothing else changes.
func (r *SpecReviewAnnotations) AssignCommentIDs(floor int) []string {
	high := r.highestCommentNumber()
	if floor > high {
		high = floor
	}
	next := high + 1
	assigned := []string{}
	for _, v := range r.values() {
		p := annParse(v.text)
		var bare []*annComment
		for _, c := range p.comments {
			if c.id == nil {
				bare = append(bare, c)
			}
		}
		if len(bare) == 0 {
			continue
		}
		lines := strings.Split(v.text, "\n")
		for _, c := range bare {
			id := "C-" + strconv.Itoa(next)
			next++
			assigned = append(assigned, id)
			raw := lines[c.block.start]
			at := c.markerEnd
			switch {
			case at < len(raw) && raw[at] == ' ':
				lines[c.block.start] = raw[:at+1] + "**" + id + "** " + raw[at+1:]
			case at >= len(raw):
				lines[c.block.start] = raw + " **" + id + "**"
			default:
				lines[c.block.start] = raw[:at] + " **" + id + "** " + raw[at:]
			}
		}
		r.set(v.path, v.field, strings.Join(lines, "\n"))
	}
	return assigned
}

// InsertComment inserts a comment block after paragraph afterParagraph
// (0-based; -1: at the start) of the value at path / field (field "" for
// content), and returns its id — id when non-empty, else the next free one.
// author "" writes none.
func (r *SpecReviewAnnotations) InsertComment(path, field string, afterParagraph int, text, author, id string) (string, error) {
	cid := id
	if cid == "" {
		cid = r.NextCommentID(0)
	}
	value := r.get(path, field)
	end, err := r.paragraphLastLine(value, afterParagraph)
	if err != nil {
		return "", err
	}
	r.set(path, field, annInsertAfterLine(value, end, FormatCommentBlock(cid, text, author)))
	return cid, nil
}

// InsertQuestion inserts a question block after paragraph afterParagraph
// (0-based; -1: at the start) of the value at path / field.
func (r *SpecReviewAnnotations) InsertQuestion(path, field string, afterParagraph int, question SpecQuestionDraft) error {
	value := r.get(path, field)
	end, err := r.paragraphLastLine(value, afterParagraph)
	if err != nil {
		return err
	}
	r.set(path, field, annInsertAfterLine(value, end, FormatQuestionBlock(question)))
	return nil
}

// InsertQuestionAfterComment inserts a question block directly after the
// comment commentID.
func (r *SpecReviewAnnotations) InsertQuestionAfterComment(commentID string, question SpecQuestionDraft) error {
	v, c, err := r.findComment(commentID)
	if err != nil {
		return err
	}
	r.set(v.path, v.field, annInsertAfterLine(v.text, c.block.end, FormatQuestionBlock(question)))
	return nil
}

// SetAnswer writes answer after the question's `**Answer:**` (empty: reopens
// it).
func (r *SpecReviewAnnotations) SetAnswer(questionID, answer string) error {
	v, _, q, err := r.findQuestion(questionID)
	if err != nil {
		return err
	}
	lines := strings.Split(v.text, "\n")
	a := strings.Split(answer, "\n")
	var written []string
	if answer == "" {
		written = []string{"> " + annAnswerLabel}
	} else {
		written = append([]string{"> " + annAnswerLabel + " " + a[0]}, annQuoted(a[1:])...)
	}
	// The answer runs to the region's last non-empty line.
	last := q.regionEnd
	for last > q.header && strings.TrimSpace(annInner(lines[last])) == "" {
		last--
	}
	var out []string
	if q.answerLine >= 0 {
		from := q.answerLine
		to := last
		if to < from {
			to = from
		}
		out = append(append(append([]string{}, lines[:from]...), written...), lines[to+1:]...)
	} else {
		out = append(append(append(append([]string{}, lines[:last+1]...), ">"), written...), lines[last+1:]...)
	}
	r.set(v.path, v.field, strings.Join(out, "\n"))
	return nil
}

// EditComment replaces a comment's text; its marker, id and author stay as
// written.
func (r *SpecReviewAnnotations) EditComment(commentID, text string) error {
	v, c, err := r.findComment(commentID)
	if err != nil {
		return err
	}
	lines := strings.Split(v.text, "\n")
	t := strings.Split(text, "\n")
	block := append([]string{strings.TrimRightFunc(c.headerPrefix+t[0], unicode.IsSpace)}, annQuoted(t[1:])...)
	out := append(append(append([]string{}, lines[:c.block.start]...), block...), lines[c.block.end+1:]...)
	r.set(v.path, v.field, strings.Join(out, "\n"))
	return nil
}

// Resolve removes one comment or question by id (a qualified comment id,
// `SBP C-12`, is accepted). A question of a combined block takes only its own
// lines; the block goes when its last question does.
func (r *SpecReviewAnnotations) Resolve(id string) error {
	bare := id
	if strings.Contains(id, " ") {
		parts := strings.Split(id, " ")
		bare = parts[len(parts)-1]
	}
	if strings.HasPrefix(bare, "C-") {
		v, c, err := r.findComment(bare)
		if err != nil {
			return err
		}
		r.set(v.path, v.field, annRemoveLines(v.text, c.block.start, c.block.end))
		return nil
	}
	v, b, q, err := r.findQuestion(bare)
	if err != nil {
		return err
	}
	if len(b.questions) == 1 {
		r.set(v.path, v.field, annRemoveLines(v.text, b.start, b.end))
		return nil
	}
	lines := strings.Split(v.text, "\n")
	lines = append(append([]string{}, lines[:q.header]...), lines[q.regionEnd+1:]...)
	// A last question leaves the separator `>` lines of the one before it.
	end := b.end - (q.regionEnd - q.header + 1)
	for end > b.start && strings.TrimSpace(annInner(lines[end])) == "" {
		lines = append(lines[:end], lines[end+1:]...)
		end--
	}
	r.set(v.path, v.field, strings.Join(lines, "\n"))
	return nil
}

// ApplyMark accepts (accept) or rejects the inline mark index (0-based among
// the marks of the value at path / field).
func (r *SpecReviewAnnotations) ApplyMark(path, field string, index int, accept bool) error {
	value := r.get(path, field)
	marks := annParse(value).marks
	if index < 0 || index >= len(marks) {
		where := path
		if field != "" {
			where += " / " + field
		}
		return &SpecReviewAnnotationError{Message: "no inline mark " + strconv.Itoa(index) + " at " + where}
	}
	m := marks[index]
	r.set(path, field, annReplaceMark(value, m, annMarkReplacement(m, accept)))
	return nil
}

// Stripped returns a copy of the document without any annotation, for
// reading. The document itself is unchanged.
func (r *SpecReviewAnnotations) Stripped() *SpecDocument {
	cp := NewSpecDocument()
	cp.LoadJSON(r.Doc.ToJSON())
	for _, v := range r.values() {
		clean := StripAnnotationsText(v.text)
		if clean == v.text {
			continue
		}
		if v.field == "" {
			cp.SetContent(v.path, clean)
		} else {
			cp.SetFormField(v.path, v.field, clean)
		}
	}
	return cp
}

func (r *SpecReviewAnnotations) paragraphLastLine(value string, afterParagraph int) (int, error) {
	if afterParagraph < 0 {
		return -1, nil
	}
	lines := strings.Split(value, "\n")
	paras := annParagraphs(lines, annCodeLines(lines))
	if value == "" || afterParagraph >= len(paras) {
		n := len(paras)
		if value == "" {
			n = 0
		}
		return 0, &SpecReviewAnnotationError{Message: "the value has " + strconv.Itoa(n) +
			" paragraph(s); there is no paragraph " + strconv.Itoa(afterParagraph)}
	}
	return paras[afterParagraph][1], nil
}

func (r *SpecReviewAnnotations) findComment(id string) (annValue, *annComment, error) {
	for _, v := range r.values() {
		for _, c := range annParse(v.text).comments {
			if c.id != nil && *c.id == id {
				return v, c, nil
			}
		}
	}
	return annValue{}, nil, &SpecReviewAnnotationError{Message: "no comment " + id + " in the document"}
}

func (r *SpecReviewAnnotations) findQuestion(id string) (annValue, *annBlock, *annQuestion, error) {
	for _, v := range r.values() {
		p := annParse(v.text)
		for _, b := range p.blocks {
			for _, q := range b.questions {
				if q.id == id {
					return v, b, q, nil
				}
			}
		}
	}
	return annValue{}, nil, nil, &SpecReviewAnnotationError{Message: "no question " + id + " in the document"}
}

// Validate returns the instance-tier findings on annotations (SOM §11.9.5),
// ordered by path.
func (r *SpecReviewAnnotations) Validate() []SpecValidationError {
	var errs []SpecValidationError
	seen := map[string]bool{}
	for _, v := range r.values() {
		p := annParse(v.text)
		where := v.path
		if v.field != "" {
			where += " / " + v.field
		}
		for _, m := range p.malformed {
			errs = append(errs, SpecValidationError{
				Path:    v.path,
				Code:    SpecValidationCodeAnnotationMalformed,
				Message: where + ", " + m,
			})
		}
		if v.field != "" {
			for _, b := range p.blocks {
				errs = append(errs, SpecValidationError{
					Path: v.path,
					Code: SpecValidationCodeAnnotationMisplaced,
					Message: where + ", line " + strconv.Itoa(b.start) + ": a " + string(b.kind) +
						" block sits in a form field value; it belongs in the form's preamble, " +
						"above the first field (SOM §11.9.4)",
				})
			}
		}
		var ids []string
		for _, c := range p.comments {
			if c.id != nil {
				ids = append(ids, *c.id)
			}
		}
		for _, b := range p.blocks {
			for _, q := range b.questions {
				ids = append(ids, q.id)
			}
		}
		for _, id := range ids {
			if seen[id] {
				errs = append(errs, SpecValidationError{
					Path:    v.path,
					Code:    SpecValidationCodeDuplicateAnnotationID,
					Message: where + ": " + id + " is used more than once in the document",
				})
				continue
			}
			seen[id] = true
		}
	}
	sort.SliceStable(errs, func(i, j int) bool { return errs[i].Path < errs[j].Path })
	return errs
}
