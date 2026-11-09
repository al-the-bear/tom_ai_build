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
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode"
	"unicode/utf8"
)

// SpecReviewAnnotationKind is one kind of annotation (SOM §11.9): the three of
// §11.9.1–11.9.3 and the conflict block a team review adds (§11.9.8).
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
	// SpecReviewAnnotationKindConflict is a conflict block,
	// `> ⚖️ **X-3 — Conflicting changes:** …` (SOM §11.9.8).
	SpecReviewAnnotationKindConflict SpecReviewAnnotationKind = "conflict"
)

// SpecReviewAnnotationKinds lists every SpecReviewAnnotationKind, in
// declaration order.
var SpecReviewAnnotationKinds = []SpecReviewAnnotationKind{
	SpecReviewAnnotationKindComment,
	SpecReviewAnnotationKindQuestion,
	SpecReviewAnnotationKindMark,
	SpecReviewAnnotationKindConflict,
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
	// Options are a question's options, in order (empty when it states none).
	Options []SpecQuestionOption
	// Recommended is a question's recommended letter: the bold option, else
	// the option that says "recommended", else the letter of a
	// `*Recommendation:*` line; nil when none.
	Recommended *string
	// MarkKind is a mark's kind; empty for a comment or question.
	MarkKind SpecMarkKind
	// NewText is a substitution's new text.
	NewText *string
	// Comment is the comment of a comment mark, or of a highlight followed by
	// one.
	Comment *string
	// Authors are a mark's authors from its attribution token (SOM §11.9.8);
	// empty without one.
	Authors []string
	// Votes are a mark's votes from its attribution token; empty without one.
	Votes []SpecMarkVote
	// Answers are a question's individual answers, in the order written.
	Answers []SpecIndividualAnswer
	// Base is a conflict's `(base)` text. For a conflict, Text is the text of
	// its header (what it concerns) and Answer its decision.
	Base string
	// Alternatives are a conflict's lettered alternatives.
	Alternatives []SpecConflictAlternative
	// ChangedAt is when a comment, mark or question was last changed (SOM
	// §11.9.10); nil without a time. A question's is the time in its header.
	ChangedAt *string
	// AnswerChangedAt is when a question's team answer was last changed (SOM
	// §11.9.10): the time in `**Answer (<time>):**`, or nil.
	AnswerChangedAt *string
}

// Open reports whether a question is still open (no team answer written), or
// a conflict (no decision written).
func (a SpecReviewAnnotation) Open() bool {
	return (a.Kind == SpecReviewAnnotationKindQuestion || a.Kind == SpecReviewAnnotationKindConflict) &&
		a.Answer == ""
}

// Unresolved reports whether a question's team answer or a conflict's
// decision begins with `open:` — answered for a gate, but handed back (SOM
// §11.9.8).
func (a SpecReviewAnnotation) Unresolved() bool {
	return annIsUnresolved(a.Answer)
}

// AnswerLetter is the letter a question's team answer starts with (`(b)` or
// `**(b)**`), or nil — nil too for an unresolved answer, and always for a
// comment, mark or conflict.
func (a SpecReviewAnnotation) AnswerLetter() *string {
	if a.Kind != SpecReviewAnnotationKindQuestion || a.Unresolved() {
		return nil
	}
	return annLeadingLetter(a.Answer)
}

// DecisionLetter is a conflict's decision letter: `a`…, `base`, or nil for
// rewritten text, no decision, or anything but a conflict.
func (a SpecReviewAnnotation) DecisionLetter() *string {
	if a.Kind != SpecReviewAnnotationKindConflict {
		return nil
	}
	return annDecisionLetter(a.Answer)
}

// SpecReviewJSONOptions are the options of the listing types' JSON forms.
// Team gives the extended form `team_annotation_cases.json` pins (SOM
// §11.9.8): marks with `authors` and `votes`, questions with `unresolved` and
// `answers`, the counts with the team counts, a removal report with its
// `conflicts`. Without it the form is the one of §11.9.1–11.9.7, which the
// older case files pin.
type SpecReviewJSONOptions struct {
	Team bool
}

// SpecMarkVote is one reviewer's vote on a mark someone else proposed (SOM
// §11.9.8).
type SpecMarkVote struct {
	// Member is the voter's member id.
	Member string
	// Vote is SpecMarkDecisionAccept (`+id`) or SpecMarkDecisionReject
	// (`-id`).
	Vote SpecMarkDecision
}

// ToJSON is the canonical JSON form.
func (v SpecMarkVote) ToJSON() map[string]any {
	return map[string]any{"member": v.Member, "vote": string(v.Vote)}
}

// SpecIndividualAnswer is one line of individual answers,
// `**Answer (alice, bob):** (a)` (SOM §11.9.8).
type SpecIndividualAnswer struct {
	// Members are the members who gave this answer, in the order written.
	Members []string
	// Answer is the answer, trimmed.
	Answer string
	// ChangedAt is when the answer was last written (SOM §11.9.10); nil
	// without a time.
	ChangedAt *string
}

// AnswerLetter is the letter the answer starts with (`(a)` or `**(a)**`), or
// nil.
func (a SpecIndividualAnswer) AnswerLetter() *string { return annLeadingLetter(a.Answer) }

// ToJSON is the canonical JSON form.
func (a SpecIndividualAnswer) ToJSON() map[string]any {
	out := map[string]any{
		"members":      annStringsJSON(a.Members),
		"answer":       a.Answer,
		"answerLetter": nullableString(a.AnswerLetter()),
	}
	if a.ChangedAt != nil {
		out["changedAt"] = *a.ChangedAt
	}
	return out
}

// SpecConflictAlternative is one lettered alternative of a conflict block,
// `- (a) **alice:** text` (SOM §11.9.8).
type SpecConflictAlternative struct {
	// Letter is the lowercase letter.
	Letter string
	// Members are the members who made this change.
	Members []string
	// Text is the alternative's text; its continuation lines kept as lines.
	Text string
}

// ToJSON is the canonical JSON form.
func (a SpecConflictAlternative) ToJSON() map[string]any {
	return map[string]any{"letter": a.Letter, "members": annStringsJSON(a.Members), "text": a.Text}
}

// annStringsJSON is ss as a JSON array: never null, even when empty.
func annStringsJSON(ss []string) []any {
	out := make([]any, 0, len(ss))
	for _, s := range ss {
		out = append(out, s)
	}
	return out
}

// annVotesJSON is the JSON form of a vote list: never null.
func annVotesJSON(votes []SpecMarkVote) []any {
	out := make([]any, 0, len(votes))
	for _, v := range votes {
		out = append(out, v.ToJSON())
	}
	return out
}

// SpecParagraph is one paragraph of a value (SOM §11.9.1, "Paragraphs"): a
// run of non-blank lines, where a blank line inside fenced code does not end
// the run. Its Index is what afterParagraph of the inserts takes.
type SpecParagraph struct {
	// Index is the 0-based position among the value's paragraphs.
	Index int
	// StartLine is the 0-based first line within the value.
	StartLine int
	// EndLine is the 0-based last line within the value (inclusive).
	EndLine int
	// Text is the paragraph's lines, verbatim, joined with `\n`.
	Text string
	// Annotation is `comment`, `question` or `conflict` when the paragraph
	// opens with an annotation block of that kind, else nil.
	Annotation *string
}

// ToJSON is the canonical JSON form.
func (p SpecParagraph) ToJSON() map[string]any {
	return map[string]any{
		"index":      p.Index,
		"startLine":  p.StartLine,
		"endLine":    p.EndLine,
		"text":       p.Text,
		"annotation": nullableString(p.Annotation),
	}
}

// SpecQuestionOption is one option of a question (SOM §11.9.2): `- (a) text`,
// or `- **(b)** text` for the recommended one.
type SpecQuestionOption struct {
	// Letter is the lowercase letter.
	Letter string
	// Text is the option's text, its continuation lines joined with one space.
	Text string
	// Bold reports whether the option is written bold — the recommended one.
	Bold bool
}

// ToJSON is the canonical JSON form.
func (o SpecQuestionOption) ToJSON() map[string]any {
	return map[string]any{"letter": o.Letter, "text": o.Text, "bold": o.Bold}
}

func nullableString(s *string) any {
	if s == nil {
		return nil
	}
	return *s
}

// ToJSON is the canonical JSON form the conformance corpus pins.
func (a SpecReviewAnnotation) ToJSON() map[string]any {
	return a.ToJSONWith(SpecReviewJSONOptions{})
}

// ToJSONWith is the canonical JSON form, in the team form when options ask
// for it (see SpecReviewJSONOptions).
func (a SpecReviewAnnotation) ToJSONWith(opts SpecReviewJSONOptions) map[string]any {
	switch a.Kind {
	case SpecReviewAnnotationKindComment:
		out := map[string]any{
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
		if a.ChangedAt != nil {
			out["changedAt"] = *a.ChangedAt
		}
		return out
	case SpecReviewAnnotationKindQuestion:
		options := make([]any, 0, len(a.Options))
		for _, o := range a.Options {
			options = append(options, o.ToJSON())
		}
		out := map[string]any{
			"kind":         "question",
			"path":         a.Path,
			"field":        nullableString(a.Field),
			"line":         a.Line,
			"id":           nullableString(a.ID),
			"topic":        nullableString(a.Topic),
			"starred":      a.Starred,
			"combined":     a.Combined,
			"text":         a.Text,
			"answer":       a.Answer,
			"open":         a.Open(),
			"options":      options,
			"recommended":  nullableString(a.Recommended),
			"answerLetter": nullableString(a.AnswerLetter()),
		}
		if opts.Team {
			answers := make([]any, 0, len(a.Answers))
			for _, x := range a.Answers {
				answers = append(answers, x.ToJSON())
			}
			out["unresolved"] = a.Unresolved()
			out["answers"] = answers
		}
		if a.ChangedAt != nil {
			out["changedAt"] = *a.ChangedAt
		}
		if a.AnswerChangedAt != nil {
			out["answerChangedAt"] = *a.AnswerChangedAt
		}
		return out
	case SpecReviewAnnotationKindConflict:
		alternatives := make([]any, 0, len(a.Alternatives))
		for _, x := range a.Alternatives {
			alternatives = append(alternatives, x.ToJSON())
		}
		return map[string]any{
			"kind":           "conflict",
			"path":           a.Path,
			"field":          nullableString(a.Field),
			"line":           a.Line,
			"id":             nullableString(a.ID),
			"qualifiedId":    nullableString(a.QualifiedID),
			"topic":          nullableString(a.Topic),
			"text":           a.Text,
			"base":           a.Base,
			"alternatives":   alternatives,
			"decision":       a.Answer,
			"decisionLetter": nullableString(a.DecisionLetter()),
			"open":           a.Open(),
			"unresolved":     a.Unresolved(),
		}
	default:
		out := map[string]any{
			"kind":     "mark",
			"path":     a.Path,
			"field":    nullableString(a.Field),
			"line":     a.Line,
			"markKind": string(a.MarkKind),
			"text":     a.Text,
			"newText":  nullableString(a.NewText),
			"comment":  nullableString(a.Comment),
		}
		if a.ChangedAt != nil {
			out["changedAt"] = *a.ChangedAt
		}
		if opts.Team {
			out["authors"] = annStringsJSON(a.Authors)
			out["votes"] = annVotesJSON(a.Votes)
		}
		return out
	}
}

// SpecReviewAnnotationCounts holds the counts a report needs (SOM §11.9).
type SpecReviewAnnotationCounts struct {
	Questions         int
	OpenQuestions     int
	AnsweredQuestions int
	Comments          int
	Marks             int
	// UnresolvedQuestions are the questions whose team answer begins `open:`
	// (also counted as answered; SOM §11.9.8).
	UnresolvedQuestions int
	// Conflicts are the conflict blocks.
	Conflicts int
	// OpenConflicts are the conflict blocks without a decision.
	OpenConflicts int
}

// ToJSON is the canonical JSON form.
func (c SpecReviewAnnotationCounts) ToJSON() map[string]int {
	return c.ToJSONWith(SpecReviewJSONOptions{})
}

// ToJSONWith is the canonical JSON form, with the three team counts when
// options ask for the team form.
func (c SpecReviewAnnotationCounts) ToJSONWith(options SpecReviewJSONOptions) map[string]int {
	out := map[string]int{
		"questions":         c.Questions,
		"openQuestions":     c.OpenQuestions,
		"answeredQuestions": c.AnsweredQuestions,
		"comments":          c.Comments,
		"marks":             c.Marks,
	}
	if options.Team {
		out["unresolvedQuestions"] = c.UnresolvedQuestions
		out["conflicts"] = c.Conflicts
		out["openConflicts"] = c.OpenConflicts
	}
	return out
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
	// Recommended is the recommended option's letter, or empty; that option
	// is written bold.
	Recommended string
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
	annScales         = "⚖"
	annDecisionLabel  = "**Decision:**"
	annUnresolvedPfx  = "open:"
)

var (
	annCommentNumber = regexp.MustCompile(`^[1-9][0-9]*$`)
	// annIndividualAnswerRE is the start of an individual answer line,
	// `**Answer (alice, bob):**`.
	annIndividualAnswerRE = regexp.MustCompile(`^\*\*Answer \(([^)]*)\):\*\*`)
	// annMemberIDRE is a member id (SOM §11.9.8): lowercase letters, digits
	// and `_`.
	annMemberIDRE = regexp.MustCompile(`^[a-z0-9_]+$`)
	// annConflictBaseRE is `- (base) …`, the base line of a conflict block.
	annConflictBaseRE = regexp.MustCompile(`^- \(base\)(?: (.*))?$`)
	// annConflictAltRE is `- (a) **alice, bob:** …`, a lettered alternative.
	annConflictAltRE = regexp.MustCompile(`^- \(([a-z])\)(?: \*\*([^*]*):\*\*)?(?: (.*))?$`)
	// annConflictHeaderRE is the header after the marker,
	// `**X-<n> — <topic>:** <text>`.
	annConflictHeaderRE = regexp.MustCompile(`^\*\*(X-[1-9][0-9]*) — (.+?):\*\*(?: (.*))?$`)
)

// IsReviewMemberID reports whether s is a member id (SOM §11.9.8): lowercase
// letters, digits and `_`.
func IsReviewMemberID(s string) bool { return annMemberIDRE.MatchString(s) }

var (
	// annReviewTimeRE is a change time as annotations write it (SOM
	// §11.9.10): minutes with the writer's UTC offset,
	// `2026-11-07T14:05+01:00` or `2026-11-07T13:05Z`.
	annReviewTimeRE = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?:Z|[+-]\d{2}:\d{2})$`)
	// annReviewTimeInRE is an ISO 8601 time a caller may pass as `at`:
	// minutes, optional seconds and fraction, and an offset or `Z`.
	annReviewTimeInRE = regexp.MustCompile(`^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2})(?::\d{2}(?:\.\d+)?)?(Z|[+-]\d{2}:\d{2})$`)
)

// IsReviewTime reports whether s is a change time of the form SOM §11.9.10
// fixes.
func IsReviewTime(s string) bool { return annReviewTimeRE.MatchString(s) }

// NormalizeReviewTime is at as a change time (SOM §11.9.10): seconds and
// fractions cut, the offset kept as given. Any other shape is a
// *SpecReviewAnnotationError.
func NormalizeReviewTime(at string) (string, error) {
	m := annReviewTimeInRE.FindStringSubmatch(strings.TrimSpace(at))
	if m == nil {
		return "", &SpecReviewAnnotationError{Message: "\"" + at +
			"\" is not an ISO 8601 time with an offset or Z (e.g. 2026-11-07T14:05+01:00)"}
	}
	return m[1] + m[2], nil
}

// SystemReviewTime is now as a change time in its local offset (SOM
// §11.9.10).
func SystemReviewTime(now time.Time) string {
	_, off := now.Zone()
	sign := "+"
	if off < 0 {
		sign = "-"
		off = -off
	}
	mins := off / 60
	return fmt.Sprintf("%04d-%02d-%02dT%02d:%02d%s%02d:%02d", now.Year(), int(now.Month()), now.Day(),
		now.Hour(), now.Minute(), sign, mins/60, mins%60)
}

// annSplitTime splits parts (a header's or an answer's comma-separated parts)
// into the parts before a trailing change time and the time (SOM §11.9.10).
func annSplitTime(parts []string) ([]string, *string) {
	if len(parts) > 0 {
		if t := strings.TrimSpace(parts[len(parts)-1]); IsReviewTime(t) {
			return parts[:len(parts)-1], &t
		}
	}
	return parts, nil
}

func annIsUnresolved(answer string) bool { return strings.HasPrefix(answer, annUnresolvedPfx) }

// annDecisionLetter is a conflict decision's letter: `a`…, `base`, or nil
// (rewritten text or none).
func annDecisionLetter(decision string) *string {
	t := strings.TrimLeft(decision, " \t\n\r\f\v")
	if strings.HasPrefix(t, "(base)") || strings.HasPrefix(t, "**(base)**") {
		b := "base"
		return &b
	}
	if annIsUnresolved(t) {
		return nil
	}
	return annLeadingLetter(t)
}

// annIndividualAnswer is one `**Answer (<ids>):**` entry of a question (SOM
// §11.9.8).
type annIndividualAnswer struct {
	line    int // value line of the `**Answer (…):**` line
	end     int // last value line of the entry with text (inclusive)
	members []string
	answer  string
	// changedAt is the entry's change time (SOM §11.9.10), or nil.
	changedAt *string
}

// annConflict is one parsed conflict block (SOM §11.9.8).
type annConflict struct {
	block *annBlock
	// id is nil when the header is malformed: the block is then not listed.
	id    *string
	topic string
	text  string
	// base is nil when the block has no `(base)` line.
	base         *string
	alternatives []SpecConflictAlternative
	decision     string
}

// annBlock is one parsed block of a value (lines [start, end] inclusive).
type annBlock struct {
	start, end int
	kind       SpecReviewAnnotationKind
	comment    *annComment    // comment blocks
	questions  []*annQuestion // question blocks
	combined   bool
	conflict   *annConflict // conflict blocks
}

// annQuestion is one question region inside a question block.
type annQuestion struct {
	header      int // value line of the header
	regionEnd   int // last value line of the region (inclusive)
	answerLine  int // value line of `**Answer:**`, or -1
	id          string
	topic       string
	starred     bool
	text        string
	answer      string
	options     []SpecQuestionOption
	recommended *string
	answers     []annIndividualAnswer
	// changedAt is the time in the header (SOM §11.9.10), or nil.
	changedAt *string
	// answerChangedAt is the time of the team answer, or nil.
	answerChangedAt *string
}

func annIsLetter(c byte) bool { return c >= 'a' && c <= 'z' }

// annParseOptions returns the options of a question and its recommended
// letter (SOM §11.9.2): one option per line, `- (a) …`, the recommended one
// bold, `- **(b)** …`. The recommended letter is the first bold option's; else
// the first option's whose text says "recommended"; else the letter a
// `*Recommendation:*` line names; else none.
func annParseOptions(lines []string) ([]SpecQuestionOption, *string) {
	options := []SpecQuestionOption{}
	open := false
	var letter, text string
	bold := false
	closeOpt := func() {
		if open {
			options = append(options, SpecQuestionOption{Letter: letter, Text: strings.TrimSpace(text), Bold: bold})
		}
		open = false
	}
	for _, l := range lines {
		if strings.HasPrefix(l, "- ") {
			r := l[2:]
			if len(r) >= 7 && strings.HasPrefix(r, "**(") && annIsLetter(r[3]) && r[4:7] == ")**" {
				closeOpt()
				open, letter, text, bold = true, r[3:4], r[7:], true
				continue
			}
			if len(r) >= 3 && r[0] == '(' && annIsLetter(r[1]) && r[2] == ')' {
				closeOpt()
				open, letter, text, bold = true, r[1:2], r[3:], false
				continue
			}
		}
		if open && strings.HasPrefix(l, " ") && strings.TrimSpace(l) != "" {
			text = strings.TrimSpace(text) + " " + strings.TrimSpace(l)
			continue
		}
		closeOpt()
	}
	closeOpt()
	for _, o := range options {
		if o.Bold {
			x := o.Letter
			return options, &x
		}
	}
	for _, o := range options {
		if strings.Contains(strings.ToLower(o.Text), "recommended") {
			x := o.Letter
			return options, &x
		}
	}
	const label = "*Recommendation:*"
	for _, l := range lines {
		i := strings.Index(l, label)
		if i < 0 {
			continue
		}
		if x := annLeadingLetter(l[i+len(label):]); x != nil {
			return options, x
		}
	}
	return options, nil
}

// annLeadingLetter is the letter of a leading `(x)` or `**(x)**` in s (spaces
// skipped), or nil.
func annLeadingLetter(s string) *string {
	t := strings.TrimLeft(s, " \t\n\r\f\v")
	t = strings.TrimPrefix(t, "**")
	if len(t) >= 3 && t[0] == '(' && annIsLetter(t[1]) && t[2] == ')' {
		x := t[1:2]
		return &x
	}
	return nil
}

// annComment is one parsed comment block.
type annComment struct {
	block     *annBlock
	id        *string
	author    *string
	text      string
	context   string
	markerEnd int // where an id is inserted into the first line
	// beforeAuthor is the first line up to where the author's parentheses
	// (or the text) start.
	beforeAuthor string
	// changedAt is when the comment was last changed (SOM §11.9.10), or nil.
	changedAt *string
}

// annMark is one parsed mark; start/end are byte offsets into the value.
// end lies after the attribution token when the mark has one, bodyEnd always
// right after the mark itself, so the token can be rewritten in place.
type annMark struct {
	start, end int
	bodyEnd    int
	line       int
	kind       SpecMarkKind
	text       string
	newText    *string
	comment    *string
	authors    []string
	votes      []SpecMarkVote
	// quote is a comment mark's quote of a change (SOM §11.9.3), or nil.
	quote *annQuote
	// changedAt is the time in the mark's attribution token (SOM §11.9.10),
	// or nil.
	changedAt *string
	// changeIndex is the index (among the value's marks) of the change this
	// change comment is attached to, or -1.
	changeIndex int
	// commentIndex is the index of this change's attached comment, or -1.
	commentIndex int
	// textLead, textTrail, newLead and newTrail say whether whitespace was
	// written inside the delimiters at the leading / trailing edge of text
	// and of newText (SOM §11.9.3, edge spaces).
	textLead, textTrail, newLead, newTrail bool
}

// annQuote is the quote a change comment opens with (SOM §11.9.3); offsets
// are byte offsets into the value.
type annQuote struct {
	kind    SpecMarkKind
	oldText string
	newText string
	// outcome is `accepted`, `rejected`, or "" while the change is open.
	outcome string
	// delimEnd lies right after the quote's closing delimiter.
	delimEnd int
	// end lies right after the quote's `]`.
	end int
	// comment is the text after the quote, trimmed.
	comment string
}

func (q *annQuote) toJSON() map[string]any {
	var outcome any
	if q.outcome != "" {
		outcome = q.outcome
	}
	return map[string]any{
		"kind":    string(q.kind),
		"oldText": q.oldText,
		"newText": q.newText,
		"outcome": outcome,
	}
}

var annQuoteKinds = map[string]SpecMarkKind{
	"++": SpecMarkKindInsertion,
	"--": SpecMarkKindDeletion,
	"~~": SpecMarkKindSubstitution,
}

func annIsBlankChar(c byte) bool { return c == ' ' || c == '\t' }

// annReadQuote reads the quote at the start of a comment mark's inner text s,
// whose first byte is at value offset at: the quote, or nil with issue ""
// when s opens no quote, or nil with the issue (`unclosed`, `noArrow`) of a
// quote that is malformed.
func annReadQuote(s string, at int) (*annQuote, string) {
	a := 0
	for a < len(s) && strings.IndexByte(" \t\r\n", s[a]) >= 0 {
		a++
	}
	if a+3 > len(s) || s[a] != '[' {
		return nil, ""
	}
	d := s[a+1 : a+3]
	kind, ok := annQuoteKinds[d]
	if !ok {
		return nil, ""
	}
	j := annIndexFrom(s, d, a+3)
	for j >= 0 {
		t := j + 2
		for t < len(s) && annIsBlankChar(s[t]) {
			t++
		}
		outcome := ""
		closeAt := -1
		if t < len(s) && s[t] == ']' {
			closeAt = t
		} else if t < len(s) && s[t] == '|' {
			t++
			for t < len(s) && annIsBlankChar(s[t]) {
				t++
			}
			for _, w := range []string{"accepted", "rejected"} {
				if !strings.HasPrefix(s[t:], w) {
					continue
				}
				u := t + len(w)
				for u < len(s) && annIsBlankChar(s[u]) {
					u++
				}
				if u < len(s) && s[u] == ']' {
					outcome = w
					closeAt = u
				}
				break
			}
		}
		if closeAt >= 0 {
			body := s[a+3 : j]
			oldText, newText := "", ""
			switch kind {
			case SpecMarkKindInsertion:
				newText = strings.TrimSpace(body)
			case SpecMarkKindDeletion:
				oldText = strings.TrimSpace(body)
			default:
				arrow := strings.Index(body, "~>")
				if arrow < 0 {
					return nil, "noArrow"
				}
				oldText = strings.TrimSpace(body[:arrow])
				newText = strings.TrimSpace(body[arrow+2:])
			}
			return &annQuote{kind: kind, oldText: oldText, newText: newText, outcome: outcome,
				delimEnd: at + j + 2, end: at + closeAt + 1,
				comment: strings.TrimSpace(s[closeAt+1:])}, ""
		}
		j = annIndexFrom(s, d, j+1)
	}
	return nil, "unclosed"
}

// annAttachChangeComments links each change comment to the change written
// directly before it whose kind and texts it quotes (SOM §11.9.3).
func annAttachChangeComments(marks []*annMark) {
	for k := 1; k < len(marks); k++ {
		q := marks[k].quote
		c := marks[k-1]
		if q == nil || q.outcome != "" || !annIsChangeMark(c.kind) {
			continue
		}
		if c.end != marks[k].start || c.kind != q.kind {
			continue
		}
		if annMarkReplacement(c, false) != q.oldText || annMarkReplacement(c, true) != q.newText {
			continue
		}
		marks[k].changeIndex = k - 1
		c.commentIndex = k
	}
}

// annParsed is everything one value holds.
type annParsed struct {
	lines     []string
	code      []bool
	blocks    []*annBlock
	comments  []*annComment
	marks     []*annMark
	malformed []string
	// markIssues are the malformed inline marks as (value line, issue code):
	// `unclosed`, `nested`, `noArrow`.
	markIssues []annMarkIssue
}

// annMarkIssue is one malformed inline mark.
type annMarkIssue struct {
	line  int
	issue string
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
		} else if strings.HasPrefix(first, annScales) {
			b := &annBlock{start: s, end: e, kind: SpecReviewAnnotationKindConflict}
			p.blocks = append(p.blocks, b)
			b.conflict = annParseConflict(p, b)
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
	var author, changedAt *string
	beforeAuthor := raw0[:len(raw0)-len(rest)]
	if strings.HasPrefix(rest, "(") {
		if closeAt := strings.Index(rest, ")"); closeAt > 0 {
			parts, when := annSplitTime(strings.Split(rest[1:closeAt], ","))
			changedAt = when
			if when == nil {
				a := rest[1:closeAt]
				author = &a
			} else if a := strings.TrimSpace(strings.Join(parts, ",")); a != "" {
				author = &a
			}
			rest = rest[closeAt+1:]
			rest = strings.TrimPrefix(rest, ":")
			rest = annLstrip(rest)
		}
	} else if strings.HasPrefix(rest, ":") {
		rest = annLstrip(rest[1:])
	}
	textLines := []string{rest}
	for k := b.start + 1; k <= b.end; k++ {
		inner := annInner(p.lines[k])
		t := annLstrip(inner)
		if strings.HasPrefix(t, annQuestionOpen) || strings.HasPrefix(t, annAnswerLabel) ||
			annIndividualAnswerRE.MatchString(t) {
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
		markerEnd:    markerEnd,
		beforeAuthor: beforeAuthor,
		changedAt:    changedAt,
	}
}

type annHeader struct {
	id, topic, rest string
	starred         bool
	changedAt       *string
}

// annHeaderID is a question header's id with its optional change time (SOM
// §11.9.2, §11.9.10): `BQ-81` or `BQ-81 (2026-11-07T14:05+01:00)`.
var annHeaderID = regexp.MustCompile(`^([A-Z][A-Z0-9]*-[0-9]+)(?: \(([^)]*)\))?$`)

// annParseHeader parses a question header's remainder after `**❓ `; ok=false
// when malformed.
func annParseHeader(inner string) (annHeader, bool) {
	h := inner[len(annQuestionOpen)+1:]
	sep := strings.Index(h, annEmDashSep)
	if sep <= 0 {
		return annHeader{}, false
	}
	idMatch := annHeaderID.FindStringSubmatchIndex(h[:sep])
	if idMatch == nil {
		return annHeader{}, false
	}
	id := h[idMatch[2]:idMatch[3]]
	var changedAt *string
	if idMatch[4] >= 0 {
		t := h[idMatch[4]:idMatch[5]]
		if !IsReviewTime(t) {
			return annHeader{}, false
		}
		changedAt = &t
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
	return annHeader{id: id, topic: topic, rest: rest, starred: starred, changedAt: changedAt}, true
}

// annTeamAnswerTime is the time of a team answer line `**Answer (<time>):**`
// (SOM §11.9.10), or nil when line is no such line.
func annTeamAnswerTime(line string) *string {
	m := annIndividualAnswerRE.FindStringSubmatch(line)
	if m == nil {
		return nil
	}
	t := strings.TrimSpace(m[1])
	if !IsReviewTime(t) {
		return nil
	}
	return &t
}

// annTeamAnswerLabelLength is the length of a team answer's label on line
// (`**Answer:**` or `**Answer (<time>):**`), or -1 when line does not start
// with one.
func annTeamAnswerLabelLength(line string) int {
	if strings.HasPrefix(line, annAnswerLabel) {
		return len(annAnswerLabel)
	}
	if annTeamAnswerTime(line) == nil {
		return -1
	}
	return len(annIndividualAnswerRE.FindString(line))
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
					"\"**❓ <ID> — <topic>:**\" or \"**❓ <ID> (<time>) — <topic>:**\" (SOM §11.9.2)")
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
		// Every `**Answer` line of the region: the individual ones and the
		// team's.
		var answerLines []int
		for m := k + 1; m <= regionEnd; m++ {
			if strings.HasPrefix(inner[m], annAnswerLabel) || annIndividualAnswerRE.MatchString(inner[m]) {
				answerLines = append(answerLines, m)
			}
		}
		// An answer runs to the next `**Answer` line or the end of the region.
		answerEnd := func(m int) int {
			for _, x := range answerLines {
				if x > m {
					return x - 1
				}
			}
			return regionEnd
		}
		answerText := func(m, label int) string {
			parts := append([]string{inner[m][label:]}, inner[m+1:answerEnd(m)+1]...)
			return strings.TrimSpace(strings.Join(parts, "\n"))
		}
		// The question's text ends before its first answer line of either
		// kind.
		textEnd := regionEnd
		if len(answerLines) > 0 {
			textEnd = answerLines[0] - 1
		}
		options, recommended := annParseOptions(inner[k+1 : textEnd+1])
		textParts := append([]string{h.rest}, inner[k+1:textEnd+1]...)
		text := strings.TrimSpace(strings.Join(textParts, "\n"))
		answer := -1
		var individual []annIndividualAnswer
		answered := map[string]bool{}
		for _, m := range answerLines {
			if annTeamAnswerLabelLength(inner[m]) >= 0 {
				if answer < 0 {
					answer = m
				}
				continue
			}
			match := annIndividualAnswerRE.FindStringSubmatch(inner[m])
			memberParts, answerTime := annSplitTime(strings.Split(match[1], ","))
			var members []string
			for _, x := range memberParts {
				members = append(members, strings.TrimSpace(x))
			}
			for _, member := range members {
				if answered[member] {
					p.malformed = append(p.malformed,
						"line "+strconv.Itoa(b.start+m)+": "+member+" already answered "+h.id+
							"; a member answers a question at most once (SOM §11.9.8)")
				}
				answered[member] = true
			}
			end := answerEnd(m)
			for end > m && strings.TrimSpace(inner[end]) == "" {
				end--
			}
			individual = append(individual, annIndividualAnswer{
				line:      b.start + m,
				end:       b.start + end,
				members:   members,
				answer:    answerText(m, len(match[0])),
				changedAt: answerTime,
			})
		}
		teamAnswer := ""
		answerLine := -1
		var answerChangedAt *string
		if answer >= 0 {
			teamAnswer = answerText(answer, annTeamAnswerLabelLength(inner[answer]))
			answerLine = b.start + answer
			answerChangedAt = annTeamAnswerTime(inner[answer])
		}
		b.questions = append(b.questions, &annQuestion{
			header:          b.start + k,
			regionEnd:       b.start + regionEnd,
			answerLine:      answerLine,
			id:              h.id,
			topic:           h.topic,
			starred:         h.starred,
			text:            text,
			answer:          teamAnswer,
			options:         options,
			recommended:     recommended,
			answers:         individual,
			changedAt:       h.changedAt,
			answerChangedAt: answerChangedAt,
		})
	}
}

// annParseConflict parses a conflict block (SOM §11.9.8): the header, the
// `(base)` line and the lettered alternatives — each continuing on lines
// indented under it, its line breaks kept — then `**Decision:**`. A malformed
// header leaves the block unlisted; a missing base line or alternative is a
// finding.
func annParseConflict(p *annParsed, b *annBlock) *annConflict {
	var inner []string
	for k := b.start; k <= b.end; k++ {
		inner = append(inner, annInner(p.lines[k]))
	}
	rest := strings.TrimPrefix(inner[0][len(annScales):], annVS16)
	header := annConflictHeaderRE.FindStringSubmatch(annLstripAll(rest))
	c := &annConflict{block: b}
	if header == nil {
		p.malformed = append(p.malformed, "line "+strconv.Itoa(b.start)+
			": conflict header is not \"⚖️ **X-<n> — <topic>:**\" (SOM §11.9.8)")
	} else {
		id := header[1]
		c.id = &id
		c.topic = header[2]
		c.text = strings.TrimSpace(header[3])
	}
	decisionLine := len(inner)
	for k := 1; k < len(inner); k++ {
		if strings.HasPrefix(inner[k], annDecisionLabel) {
			decisionLine = k
			break
		}
	}
	// The open entry: the base (letter "") or an alternative.
	type entry struct {
		letter  string
		members []string
		lines   []string
	}
	var open *entry
	closeEntry := func() {
		if open == nil {
			return
		}
		text := strings.TrimSpace(strings.Join(open.lines, "\n"))
		if open.letter == "" {
			c.base = &text
		} else {
			c.alternatives = append(c.alternatives, SpecConflictAlternative{
				Letter: open.letter, Members: open.members, Text: text,
			})
		}
		open = nil
	}
	for k := 1; k < decisionLine; k++ {
		l := inner[k]
		if base := annConflictBaseRE.FindStringSubmatch(l); base != nil {
			closeEntry()
			open = &entry{lines: []string{base[1]}}
		} else if alt := annConflictAltRE.FindStringSubmatch(l); alt != nil {
			closeEntry()
			members := []string{}
			for _, x := range strings.Split(alt[2], ",") {
				if x = strings.TrimSpace(x); x != "" {
					members = append(members, x)
				}
			}
			open = &entry{letter: alt[1], members: members, lines: []string{alt[3]}}
		} else if open != nil && strings.HasPrefix(l, " ") {
			if strings.HasPrefix(l, "  ") {
				open.lines = append(open.lines, l[2:])
			} else {
				open.lines = append(open.lines, annLstrip(l))
			}
		} else {
			closeEntry()
		}
	}
	closeEntry()
	if decisionLine < len(inner) {
		parts := append([]string{inner[decisionLine][len(annDecisionLabel):]}, inner[decisionLine+1:]...)
		c.decision = strings.TrimSpace(strings.Join(parts, "\n"))
	}
	if c.id != nil && c.base == nil {
		p.malformed = append(p.malformed, "line "+strconv.Itoa(b.start)+": conflict "+*c.id+
			" has no \"(base)\" line (SOM §11.9.8)")
	}
	if c.id != nil && len(c.alternatives) == 0 {
		p.malformed = append(p.malformed, "line "+strconv.Itoa(b.start)+": conflict "+*c.id+
			" has no lettered alternative (SOM §11.9.8)")
	}
	return c
}

// annLstripAll is s without its leading whitespace (JavaScript's trimStart).
func annLstripAll(s string) string { return strings.TrimLeftFunc(s, unicode.IsSpace) }

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
	annAttachChangeComments(p.marks)
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
		if c == '{' && strings.HasPrefix(seg[i:], "{@") {
			// A token that no mark precedes directly (a mark's own token is
			// read with the mark, below).
			p.malformed = append(p.malformed, "line "+strconv.Itoa(lineOf(base+i))+
				": an attribution token \"{@\" does not follow a mark directly (SOM §11.9.8)")
			if closeAt := annIndexFrom(seg, "}", i+2); closeAt < 0 {
				i += 2
			} else {
				i = closeAt + 1
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
			p.markIssues = append(p.markIssues, annMarkIssue{line, "unclosed"})
			i += 3
			continue
		}
		inner := seg[i+3 : closeAt]
		if annContainsOpener(inner) {
			p.malformed = append(p.malformed,
				"line "+strconv.Itoa(line)+": inline marks do not nest (SOM §11.9.3)")
			p.markIssues = append(p.markIssues, annMarkIssue{line, "nested"})
			i = closeAt + 3
			continue
		}
		end := closeAt + 3
		mark := func(kind SpecMarkKind, text string, newText, comment *string) *annMark {
			return &annMark{start: base + i, end: base + end, bodyEnd: base + end, line: line,
				kind: kind, text: text, newText: newText, comment: comment,
				changeIndex: -1, commentIndex: -1}
		}
		before := len(p.marks)
		switch opener {
		case "{>>":
			cm := strings.TrimSpace(inner)
			m := mark(SpecMarkKindComment, "", nil, &cm)
			q, issue := annReadQuote(inner, base+i+3)
			switch {
			case q != nil:
				m.quote = q
			case issue == "unclosed":
				p.malformed = append(p.malformed, "line "+strconv.Itoa(line)+
					": the quote of a change comment is not closed; it is read as a plain comment (SOM §11.9.3)")
			case issue == "noArrow":
				p.malformed = append(p.malformed, "line "+strconv.Itoa(line)+
					": the quote of a change comment has no \"~>\"; it is read as a plain comment (SOM §11.9.3)")
			}
			p.marks = append(p.marks, m)
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
			p.marks = append(p.marks, mark(SpecMarkKindHighlight, strings.TrimSpace(inner), nil, comment))
		case "{++":
			m := mark(SpecMarkKindInsertion, strings.TrimSpace(inner), nil, nil)
			m.textLead, m.textTrail = annWsEdge(inner, true), annWsEdge(inner, false)
			p.marks = append(p.marks, m)
		case "{--":
			m := mark(SpecMarkKindDeletion, strings.TrimSpace(inner), nil, nil)
			m.textLead, m.textTrail = annWsEdge(inner, true), annWsEdge(inner, false)
			p.marks = append(p.marks, m)
		case "{~~":
			arrow := strings.Index(inner, "~>")
			if arrow < 0 {
				p.malformed = append(p.malformed,
					"line "+strconv.Itoa(line)+": a substitution has no \"~>\" (SOM §11.9.3)")
				p.markIssues = append(p.markIssues, annMarkIssue{line, "noArrow"})
				i = end
				continue
			}
			oldRaw, newRaw := inner[:arrow], inner[arrow+2:]
			nt := strings.TrimSpace(newRaw)
			m := mark(SpecMarkKindSubstitution, strings.TrimSpace(oldRaw), &nt, nil)
			m.textLead, m.textTrail = annWsEdge(oldRaw, true), annWsEdge(oldRaw, false)
			m.newLead, m.newTrail = annWsEdge(newRaw, true), annWsEdge(newRaw, false)
			p.marks = append(p.marks, m)
		}
		if len(p.marks) > before && strings.HasPrefix(seg[end:], "{@") {
			end = annAttachToken(p, seg, end, base, p.marks[len(p.marks)-1])
		}
		i = end
	}
}

// annAttachToken reads the attribution token `{@…}` at at (SOM §11.9.8) into
// m, which it directly follows, and returns the segment offset after it. The
// token is part of the mark — its markup, its decision — so m.end moves past
// it. A token that breaks the grammar is still part of the mark (it goes with
// the mark on a decision) and is a finding; its members are then not listed.
func annAttachToken(p *annParsed, seg string, at, base int, m *annMark) int {
	lineEnd := annIndexFrom(seg, "\n", at)
	closeAt := annIndexFrom(seg, "}", at+2)
	if closeAt < 0 || (lineEnd >= 0 && closeAt > lineEnd) {
		p.malformed = append(p.malformed, "line "+strconv.Itoa(m.line)+
			": attribution token \"{@\" is not closed (SOM §11.9.8)")
		return at
	}
	authors, votes, changedAt, problem := annReadToken(seg[at+2:closeAt], m.kind)
	m.changedAt = changedAt
	if problem != "" {
		p.malformed = append(p.malformed, "line "+strconv.Itoa(m.line)+": attribution token "+
			problem+" (SOM §11.9.8)")
	} else {
		m.authors = authors
		m.votes = votes
	}
	m.end = base + closeAt + 1
	return closeAt + 1
}

// annIsChangeMark reports whether a mark kind is a change, which alone takes
// votes (SOM §11.9.8).
func annIsChangeMark(kind SpecMarkKind) bool {
	return kind == SpecMarkKindInsertion || kind == SpecMarkKindDeletion || kind == SpecMarkKindSubstitution
}

var annCommaSpaceRE = regexp.MustCompile(`,\s+`)

// annReadToken reads a token's inside, `[<authors>][ <votes>][ <time>]`, into
// its authors, votes and change time (SOM §11.9.10), or answers the reason it
// breaks the grammar of SOM §11.9.8 as problem (the time is read either way).
func annReadToken(inside string, kind SpecMarkKind) (authors []string, votes []SpecMarkVote, changedAt *string, problem string) {
	words := strings.Fields(annCommaSpaceRE.ReplaceAllString(inside, ","))
	if len(words) == 0 {
		return nil, nil, nil, "is empty"
	}
	if last := words[len(words)-1]; IsReviewTime(last) {
		changedAt = &last
		words = words[:len(words)-1]
	}
	authors, votes, problem = annReadMembers(words, kind)
	return authors, votes, changedAt, problem
}

// annReadMembers reads the authors and votes of a token's words (its time
// taken off), or answers the reason they break the grammar of SOM §11.9.8 as
// problem.
func annReadMembers(words []string, kind SpecMarkKind) (authors []string, votes []SpecMarkVote, problem string) {
	authors = []string{}
	votes = []SpecMarkVote{}
	if len(words) == 0 {
		return authors, votes, ""
	}
	votes = []SpecMarkVote{}
	k := 0
	if !strings.HasPrefix(words[0], "+") && !strings.HasPrefix(words[0], "-") {
		authors = append(authors, strings.Split(words[0], ",")...)
		k = 1
	}
	for ; k < len(words); k++ {
		w := words[k]
		switch {
		case strings.HasPrefix(w, "+"):
			votes = append(votes, SpecMarkVote{Member: w[1:], Vote: SpecMarkDecisionAccept})
		case strings.HasPrefix(w, "-"):
			votes = append(votes, SpecMarkVote{Member: w[1:], Vote: SpecMarkDecisionReject})
		default:
			return nil, nil, "has \"" + w + "\" where a vote belongs"
		}
	}
	seen := map[string]bool{}
	ids := append([]string{}, authors...)
	for _, v := range votes {
		ids = append(ids, v.Member)
	}
	for _, id := range ids {
		if !annMemberIDRE.MatchString(id) {
			return nil, nil, "names \"" + id + "\", which is not a member id"
		}
		if seen[id] {
			return nil, nil, "names " + id + " twice, or as author and voter"
		}
		seen[id] = true
	}
	if len(votes) > 0 && !annIsChangeMark(kind) {
		return nil, nil, "carries votes on a " + string(kind) + " mark, which takes authors only"
	}
	return authors, votes, ""
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
				ChangedAt:   c.changedAt,
			}})
			seq++
			continue
		}
		if b.kind == SpecReviewAnnotationKindConflict {
			c := b.conflict
			if c.id == nil {
				continue
			}
			var qualified *string
			if qualifier != "" {
				q := qualifier + " " + *c.id
				qualified = &q
			}
			base := ""
			if c.base != nil {
				base = *c.base
			}
			topic := c.topic
			out = append(out, entry{b.start, 0, seq, SpecReviewAnnotation{
				Kind:         SpecReviewAnnotationKindConflict,
				Path:         path,
				Field:        fp,
				Line:         b.start,
				ID:           c.id,
				QualifiedID:  qualified,
				Topic:        &topic,
				Text:         c.text,
				Base:         base,
				Alternatives: c.alternatives,
				Answer:       c.decision,
			}})
			seq++
			continue
		}
		for _, q := range b.questions {
			id, topic := q.id, q.topic
			answers := make([]SpecIndividualAnswer, 0, len(q.answers))
			for _, a := range q.answers {
				answers = append(answers, SpecIndividualAnswer{Members: a.members, Answer: a.answer,
					ChangedAt: a.changedAt})
			}
			out = append(out, entry{q.header, 0, seq, SpecReviewAnnotation{
				Kind:            SpecReviewAnnotationKindQuestion,
				Path:            path,
				Field:           fp,
				Line:            q.header,
				ID:              &id,
				Topic:           &topic,
				Starred:         q.starred,
				Combined:        b.combined,
				Text:            q.text,
				Answer:          q.answer,
				Options:         q.options,
				Recommended:     q.recommended,
				Answers:         answers,
				ChangedAt:       q.changedAt,
				AnswerChangedAt: q.answerChangedAt,
			}})
			seq++
		}
	}
	for _, m := range p.marks {
		out = append(out, entry{m.line, 1, seq, SpecReviewAnnotation{
			Kind:      SpecReviewAnnotationKindMark,
			Path:      path,
			Field:     fp,
			Line:      m.line,
			MarkKind:  m.kind,
			Text:      m.text,
			NewText:   m.newText,
			Comment:   m.comment,
			Authors:   m.authors,
			Votes:     m.votes,
			ChangedAt: m.changedAt,
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
// none, changedAt "" no change time (SOM §11.9.10).
func FormatCommentBlock(id, text, author, changedAt string) []string {
	t := strings.Split(text, "\n")
	head := "> " + annArrow + annVS16 + " **" + id + "**"
	if who := annAuthorAndTime(author, changedAt); who != "" {
		head += " (" + who + "):"
	}
	if t[0] != "" {
		head += " " + t[0]
	}
	return append([]string{head}, annQuoted(t[1:])...)
}

// annAuthorAndTime is a comment header's parentheses: the author and the
// change time, either alone, or "" when there is neither (SOM §11.9.10).
func annAuthorAndTime(author, changedAt string) string {
	switch {
	case author == "":
		return changedAt
	case changedAt == "":
		return author
	}
	return author + ", " + changedAt
}

// FormatQuestionBlock returns the lines of a question block; changedAt ("" for
// none) is written after the id (SOM §11.9.10).
func FormatQuestionBlock(q SpecQuestionDraft, changedAt string) []string {
	t := strings.Split(q.Text, "\n")
	star := ""
	if q.Starred {
		star = annStar + " "
	}
	id := q.ID
	if changedAt != "" {
		id += " (" + changedAt + ")"
	}
	lines := []string{"> " + annQuestionOpen + " " + id + annEmDashSep + star + q.Topic + ":** " + t[0]}
	lines = append(lines, annQuoted(t[1:])...)
	for _, o := range q.Options {
		if q.Recommended != "" && strings.HasPrefix(o, "("+q.Recommended+")") {
			lines = append(lines, "> - **("+q.Recommended+")**"+o[3:])
		} else {
			lines = append(lines, "> - "+o)
		}
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

// annReplaceMark applies a mark's replacement with the whitespace rules of
// SOM §11.9.3: never join two words, keep an edge space written inside a
// change mark after punctuation and before a word, never leave a double space
// or a space before punctuation, and a mark that was a whole line leaves no
// blank line. accept names the decision the replacement comes from; nil when
// the mark is removed rather than decided.
func annReplaceMark(value string, m *annMark, replacement string, accept *bool) string {
	before := value[:m.start]
	after := value[m.end:]
	isSpace := func(c byte) bool { return c == ' ' || c == '\t' }
	trimEnd := func(s string) string { return strings.TrimRight(s, " \t") }
	trimStart := func(s string) string { return strings.TrimLeft(s, " \t") }
	if replacement == "" {
		tb := trimEnd(before)
		ta := trimStart(after)
		lineStart := tb == "" || strings.HasSuffix(tb, "\n")
		lineEnd := ta == "" || strings.HasPrefix(ta, "\n")
		if lineStart && lineEnd {
			// The mark was the whole line: the line goes, and with it one of
			// the newlines around it; a blank line left doubled is merged.
			before = tb
			after = ta
			if strings.HasPrefix(after, "\n") {
				after = after[1:]
			} else if strings.HasSuffix(before, "\n") {
				before = before[:len(before)-1]
			}
			if (before == "" || strings.HasSuffix(before, "\n\n")) && strings.HasPrefix(after, "\n") {
				after = after[1:]
			}
			if after == "" {
				before = strings.TrimRight(before, "\n")
			}
			return before + after
		}
		if before != "" && isSpace(before[len(before)-1]) {
			if after != "" && isSpace(after[0]) {
				after = trimStart(after)
			} else if after == "" || after[0] == '\n' || strings.IndexByte(annClosingPunctuation, after[0]) >= 0 {
				before = trimEnd(before)
			}
		} else if (before == "" || strings.HasSuffix(before, "\n")) && after != "" && isSpace(after[0]) {
			after = trimStart(after)
		}
		return before + after
	}
	// Never join two words: a mark written flush against a word keeps a space
	// on that side. An edge space written inside a change mark, beside the
	// text the decision keeps, is kept after punctuation and before a word or
	// an opening bracket.
	lead, trail := false, false
	if accept != nil {
		lead, trail = annKeptEdges(m, *accept)
	}
	if (annLastIsWord(before) && annFirstIsWord(replacement)) ||
		(lead && before != "" && strings.IndexByte(annClosingPunctuation, before[len(before)-1]) >= 0) {
		replacement = " " + replacement
	}
	if after != "" && ((annLastIsWord(replacement) && annFirstIsWord(after)) ||
		(trail && (annFirstIsWord(after) || after[0] == '(' || after[0] == '['))) {
		replacement = replacement + " "
	}
	return before + replacement + after
}

// annClosingPunctuation is the punctuation no space is left before, and
// after which an edge space is kept (SOM §11.9.3).
const annClosingPunctuation = ".,;:!?)]}"

// annWsEdge reports whether raw, a mark's text as written between its
// delimiters, begins (leading) or ends with whitespace.
func annWsEdge(raw string, leading bool) bool {
	if raw == "" {
		return false
	}
	c := raw[len(raw)-1]
	if leading {
		c = raw[0]
	}
	return c == ' ' || c == '\t' || c == '\n'
}

// annKeptEdges returns the edge spaces written beside the text accept keeps
// of m: the leading and the trailing one.
func annKeptEdges(m *annMark, accept bool) (bool, bool) {
	switch {
	case m.kind == SpecMarkKindInsertion && accept,
		m.kind == SpecMarkKindDeletion && !accept,
		m.kind == SpecMarkKindSubstitution && !accept:
		return m.textLead, m.textTrail
	case m.kind == SpecMarkKindSubstitution:
		return m.newLead, m.newTrail
	}
	return false, false
}

// annBoolPtr returns a pointer to b.
func annBoolPtr(b bool) *bool { return &b }

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

// ApplyInlineMarksText returns value with every inline mark accepted (accept)
// or rejected, and every highlight and comment mark removed, by the rules of
// SOM §11.9.3. Marks in code and malformed marks stay as written.
func ApplyInlineMarksText(value string, accept bool) string {
	v := value
	marks := annParse(v).marks
	for k := len(marks) - 1; k >= 0; k-- {
		v = annReplaceMark(v, marks[k], annMarkReplacement(marks[k], accept), &accept)
	}
	return v
}

// DecideAllMarksText returns value with every inline mark accepted (accept)
// or rejected, as accept all / reject all write it (SOM §11.9.3): change
// comments stay, an attached one records the outcome; every other highlight
// and comment mark is removed. Marks in code and malformed marks stay as
// written.
func DecideAllMarksText(value string, accept bool) string {
	marks := annParse(value).marks
	v := value
	for k := len(marks) - 1; k >= 0; k-- {
		if marks[k].quote != nil {
			continue
		}
		v = annDecideMark(v, marks, k, accept)
	}
	return v
}

// annDecideMark returns value with the mark k of marks decided; a change's
// attached comment records the outcome (SOM §11.9.3).
func annDecideMark(value string, marks []*annMark, k int, accept bool) string {
	m := marks[k]
	v := value
	if m.commentIndex >= 0 {
		v = annRecordOutcome(v, marks[m.commentIndex].quote, accept)
	}
	return annReplaceMark(v, m, annMarkReplacement(m, accept), &accept)
}

// annRecordOutcome returns value with the outcome written into the quote q:
// everything from its closing delimiter to its `]` becomes ` | accepted]` or
// ` | rejected]`.
func annRecordOutcome(value string, q *annQuote, accept bool) string {
	outcome := "rejected"
	if accept {
		outcome = "accepted"
	}
	return value[:q.delimEnd] + " | " + outcome + "]" + value[q.end:]
}

var annBlankLineInRE = regexp.MustCompile(`\n[ \t\r]*\n`)

// annCheckInlineComment returns the trimmed text of an inline comment,
// refused when it is empty or holds a mark delimiter or a blank line.
func annCheckInlineComment(text string) (string, error) {
	t := strings.TrimSpace(text)
	if t == "" {
		return "", &SpecReviewAnnotationError{Message: "a comment needs text"}
	}
	if annContainsOpener(t) || strings.Contains(t, "<<}") || annBlankLineInRE.MatchString(t) {
		return "", &SpecReviewAnnotationError{Message: "a comment cannot hold a mark delimiter or a blank line"}
	}
	return t, nil
}

// annIsAnchorSpace is the whitespace of the change-comment anchors (SOM
// §11.9.3).
func annIsAnchorSpace(c byte) bool { return c == ' ' || c == '\t' || c == '\r' || c == '\n' }

func annNonSpaceCount(s string) int {
	n := 0
	for i := 0; i < len(s); i++ {
		if !annIsAnchorSpace(s[i]) {
			n++
		}
	}
	return n
}

// annMarkKeepingChangeComments is SetMarked with the value's change comments
// kept (SOM §11.9.3): taken out of the original, then written back where
// their anchor falls.
func annMarkKeepingChangeComments(current, text string) SpecMarkedChange {
	// 1. The original: every mark rejected except the change comments.
	original := current
	marks := annParse(current).marks
	for k := len(marks) - 1; k >= 0; k-- {
		if marks[k].quote != nil {
			continue
		}
		original = annReplaceMark(original, marks[k], annMarkReplacement(marks[k], false), annBoolPtr(false))
	}
	// 2. Each change comment's markup, anchor and leading space.
	var kept []*annMark
	for _, m := range annParse(original).marks {
		if m.quote != nil {
			kept = append(kept, m)
		}
	}
	type anchor struct {
		markup string
		count  int
		space  bool
	}
	anchors := make([]anchor, 0, len(kept))
	counted, from := 0, 0
	for _, m := range kept {
		counted += annNonSpaceCount(original[from:m.start])
		from = m.end
		anchors = append(anchors, anchor{
			markup: original[m.start:m.end],
			count:  counted,
			space:  m.start > 0 && annIsBlankChar(original[m.start-1]),
		})
	}
	// 3. Removed, compared.
	base := original
	for k := len(kept) - 1; k >= 0; k-- {
		base = annReplaceMark(base, kept[k], "", nil)
	}
	result := MarkChangeText(base, text)
	if len(anchors) == 0 {
		return result
	}
	// 4. Written back where k non-whitespace bytes have passed.
	r := result.Text
	rm := annParse(r).marks
	place := func(k int) int {
		if k == 0 {
			return 0
		}
		n, i, mi := 0, 0, 0
		for i < len(r) {
			if mi < len(rm) && rm[mi].start == i {
				m := rm[mi]
				mi++
				if m.kind != SpecMarkKindInsertion {
					n += annNonSpaceCount(m.text)
				}
				i = m.end
				if n >= k {
					return i
				}
				continue
			}
			if !annIsAnchorSpace(r[i]) {
				n++
			}
			i++
			if n >= k {
				return i
			}
		}
		return len(r)
	}
	at := make([]int, len(anchors))
	for j, a := range anchors {
		at[j] = place(a.count)
	}
	out := r
	for j := len(anchors) - 1; j >= 0; j-- {
		lead := ""
		if anchors[j].space {
			lead = " "
		}
		out = out[:at[j]] + lead + anchors[j].markup + out[at[j]:]
	}
	return SpecMarkedChange{Text: out, Exact: result.Exact}
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
		v = annReplaceMark(v, m, annMarkReplacement(m, true), annBoolPtr(true))
	}
	return v
}

// ---------------------------------------------------------------------------
// Team reviews (SOM §11.9.8): individual answers and applying conflicts.
// ---------------------------------------------------------------------------

// annSubstr is JavaScript's s.substring(from, to): indices clamped to s.
func annSubstr(s string, from, to int) string {
	if to > len(s) {
		to = len(s)
	}
	if from > to {
		return ""
	}
	return s[from:to]
}

// annIsCommentedAnswer reports whether an answer carries anything beyond an
// option letter (SOM §11.9.8): no leading letter, or text other than exactly
// that option's after it.
func annIsCommentedAnswer(answer string, options []SpecQuestionOption) bool {
	letter := annLeadingLetter(answer)
	if letter == nil {
		return true
	}
	t := annLstripAll(answer)
	bold := strings.HasPrefix(t, "**(") && annSubstr(t, 4, 7) == ")**"
	skip := 3
	if bold {
		skip = 7
	} else if strings.HasPrefix(t, "**") {
		skip = 5
	}
	rest := strings.TrimSpace(annSubstr(t, skip, len(t)))
	if rest == "" {
		return false
	}
	for _, o := range options {
		if o.Letter == *letter {
			return rest != o.Text
		}
	}
	return true
}

// annIndividualAnswerLines are the lines of one individual-answer entry.
// changedAt "" writes no change time (SOM §11.9.10).
func annIndividualAnswerLines(members []string, answer, changedAt string) []string {
	a := strings.Split(answer, "\n")
	who := append([]string{}, members...)
	if changedAt != "" {
		who = append(who, changedAt)
	}
	head := strings.TrimRightFunc("> **Answer ("+strings.Join(who, ", ")+"):** "+a[0], unicode.IsSpace)
	return append([]string{head}, annQuoted(a[1:])...)
}

// annSetIndividualAnswer is value with member's individual answer to question
// q set to answer (SOM §11.9.8): the member leaves the line it was on (a line
// left empty goes); a non-empty answer that is not commented joins the line
// whose answer is identical and not commented, at its end, and otherwise gets
// a new line after the last individual answer. The first individual answer
// opens the run before the team's `**Answer:**`, with a `>` line between run
// and team answer, and a run left empty takes that line with it. Entries left
// alone keep their bytes. changedAt ("" for none) is the new entry's change
// time (SOM §11.9.10); entries join only when answer and time are equal.
func annSetIndividualAnswer(value string, q *annQuestion, member, answer, changedAt string) string {
	lines := strings.Split(value, "\n")
	type entry struct {
		members   []string
		answer    string
		changedAt string
		lines     []string // nil: rewritten
	}
	var kept []*entry
	for _, a := range q.answers {
		e := &entry{answer: a.answer, lines: append([]string{}, lines[a.line:a.end+1]...)}
		if a.changedAt != nil {
			e.changedAt = *a.changedAt
		}
		for _, m := range a.members {
			if m == member {
				e.lines = nil
				continue
			}
			e.members = append(e.members, m)
		}
		if len(e.members) > 0 {
			kept = append(kept, e)
		}
	}
	text := strings.TrimSpace(answer)
	if text != "" {
		var join *entry
		if !annIsCommentedAnswer(text, q.options) {
			for _, e := range kept {
				if e.answer == text && e.changedAt == changedAt && !annIsCommentedAnswer(e.answer, q.options) {
					join = e
					break
				}
			}
		}
		if join != nil {
			join.members = append(join.members, member)
			join.lines = nil
		} else {
			kept = append(kept, &entry{members: []string{member}, answer: text, changedAt: changedAt})
		}
	}
	var run []string
	for _, e := range kept {
		if e.lines != nil {
			run = append(run, e.lines...)
		} else {
			run = append(run, annIndividualAnswerLines(e.members, e.answer, e.changedAt)...)
		}
	}
	splice := func(from, count int, insert []string) {
		out := append(append(append([]string{}, lines[:from]...), insert...), lines[from+count:]...)
		lines = out
	}
	switch {
	case len(q.answers) > 0:
		from := q.answers[0].line
		to := q.answers[len(q.answers)-1].end
		// A run left empty takes its separating `>` line with it.
		if len(run) == 0 && to+1 < len(lines) && strings.TrimSpace(annInner(lines[to+1])) == "" {
			to++
		}
		splice(from, to-from+1, run)
	case len(run) > 0:
		if q.answerLine >= 0 {
			splice(q.answerLine, 0, append(run, ">"))
		} else {
			last := q.regionEnd
			for last > q.header && strings.TrimSpace(annInner(lines[last])) == "" {
				last--
			}
			splice(last+1, 0, append([]string{">"}, run...))
		}
	}
	return strings.Join(lines, "\n")
}

// annStructuralTopics are the topics of the structural conflicts a merge
// writes (SOM §11.9.9); their decisions are not text.
var annStructuralTopics = map[string]bool{"Item removed": true, "Item moved": true, "Headline changed": true}

// annDecidedConflict is a decided conflict, as RemoveAllAnnotations found it
// before any change.
type annDecidedConflict struct {
	path, field string
	// index is the block's position among the value's conflict blocks.
	index    int
	id       string
	line     int
	decision string
}

// annChosenText is the text a conflict's decision chooses: the base, an
// alternative, or the rewritten text.
func annChosenText(c *annConflict) string {
	letter := annDecisionLetter(c.decision)
	if letter == nil {
		return c.decision
	}
	if *letter == "base" {
		if c.base == nil {
			return ""
		}
		return *c.base
	}
	for _, a := range c.alternatives {
		if a.Letter == *letter {
			return a.Text
		}
	}
	return ""
}

// annTextParagraphs are the text paragraphs (no annotation block) of a parsed
// value, as [first, last] lines.
func annTextParagraphs(p *annParsed) [][2]int {
	var out [][2]int
	for _, para := range annParagraphs(p.lines, p.code) {
		if !annOpensBlock(p, para[0]) {
			out = append(out, para)
		}
	}
	return out
}

// annOpensBlock reports whether an annotation block of p starts at line.
func annOpensBlock(p *annParsed, line int) bool {
	for _, b := range p.blocks {
		if b.start == line {
			return true
		}
	}
	return false
}

// annReplaceLines is value with the lines [s, e] replaced by text.
func annReplaceLines(value string, s, e int, text string) string {
	lines := strings.Split(value, "\n")
	out := append(append(append([]string{}, lines[:s]...), strings.Split(text, "\n")...), lines[e+1:]...)
	return strings.Join(out, "\n")
}

// annReplaceParagraphBefore is value with the text paragraph directly before
// block b (annotation blocks between them skipped) replaced by text; with
// none, text goes before the block.
func annReplaceParagraphBefore(value string, b *annBlock, text string) string {
	var before [][2]int
	for _, para := range annTextParagraphs(annParse(value)) {
		if para[1] < b.start {
			before = append(before, para)
		}
	}
	if len(before) == 0 {
		return annInsertAfterLine(value, b.start-1, strings.Split(text, "\n"))
	}
	last := before[len(before)-1]
	return annReplaceLines(value, last[0], last[1], text)
}

// annReplaceTextRun is value with the run of text paragraphs directly before
// block b — a whole-value unit (SOM §11.9.9) — replaced by text.
func annReplaceTextRun(value string, b *annBlock, text string) string {
	p := annParse(value)
	var paras [][2]int
	for _, para := range annParagraphs(p.lines, p.code) {
		if para[1] < b.start {
			paras = append(paras, para)
		}
	}
	k := len(paras)
	for k > 0 && !annOpensBlock(p, paras[k-1][0]) {
		k--
	}
	run := paras[k:]
	if len(run) == 0 {
		return annInsertAfterLine(value, b.start-1, strings.Split(text, "\n"))
	}
	return annReplaceLines(value, run[0][0], run[len(run)-1][1], text)
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
	// Clock is the clock the write operations take a change time from when
	// no `at` is passed (SOM §11.9.10); nil: the system clock in the writer's
	// offset.
	Clock func() string
}

// NewSpecReviewAnnotations wraps doc; qualifier "" lists bare ids.
func NewSpecReviewAnnotations(doc *SpecDocument, qualifier string) *SpecReviewAnnotations {
	return &SpecReviewAnnotations{Doc: doc, Qualifier: qualifier}
}

// NewSpecReviewAnnotationsWithClock wraps doc like NewSpecReviewAnnotations;
// clock fixes the change time the writes record (SOM §11.9.10; the
// conformance drivers pass a fixed one).
func NewSpecReviewAnnotationsWithClock(doc *SpecDocument, qualifier string, clock func() string) *SpecReviewAnnotations {
	return &SpecReviewAnnotations{Doc: doc, Qualifier: qualifier, Clock: clock}
}

// changeTime is the change time a write records: at normalized, else the
// clock's (at "" for none).
func (r *SpecReviewAnnotations) changeTime(at string) (string, error) {
	if at != "" {
		return NormalizeReviewTime(at)
	}
	if r.Clock != nil {
		return r.Clock(), nil
	}
	return SystemReviewTime(time.Now()), nil
}

// checkAuthor refuses an author that is not a member id ("" for none).
func annCheckAuthor(author string) error {
	if author != "" && !annMemberIDRE.MatchString(author) {
		return &SpecReviewAnnotationError{Message: "\"" + author +
			"\" is not a member id (lowercase letters, digits and _)"}
	}
	return nil
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
			if a.Unresolved() {
				c.UnresolvedQuestions++
			}
		case SpecReviewAnnotationKindComment:
			c.Comments++
		case SpecReviewAnnotationKindConflict:
			c.Conflicts++
			if a.Open() {
				c.OpenConflicts++
			}
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
// author "" writes none. The header records at (an ISO 8601 time; "" for
// the clock's) as the change time (SOM §11.9.10).
func (r *SpecReviewAnnotations) InsertComment(path, field string, afterParagraph int, text, author, id, at string) (string, error) {
	when, err := r.changeTime(at)
	if err != nil {
		return "", err
	}
	cid := id
	if cid == "" {
		cid = r.NextCommentID(0)
	}
	value := r.get(path, field)
	end, err := r.paragraphLastLine(value, afterParagraph)
	if err != nil {
		return "", err
	}
	r.set(path, field, annInsertAfterLine(value, end, FormatCommentBlock(cid, text, author, when)))
	return cid, nil
}

// Paragraphs returns the paragraphs of the value at path / field, in order —
// the units afterParagraph of InsertComment and InsertQuestion counts. It
// fails with a SpecReviewAnnotationError when the document holds no such
// value.
func (r *SpecReviewAnnotations) Paragraphs(path, field string) ([]SpecParagraph, error) {
	var value string
	var ok bool
	if field == "" {
		value, ok = r.Doc.Content(path)
	} else {
		value, ok = r.Doc.FormField(path, field)
	}
	if !ok {
		where := path
		if field != "" {
			where += " / " + field
		}
		return nil, &SpecReviewAnnotationError{Message: "no value at " + where}
	}
	p := annParse(value)
	paras := annParagraphs(p.lines, p.code)
	out := make([]SpecParagraph, 0, len(paras))
	for i, para := range paras {
		var kind *string
		for _, b := range p.blocks {
			if b.start == para[0] {
				k := string(b.kind)
				kind = &k
				break
			}
		}
		out = append(out, SpecParagraph{
			Index:      i,
			StartLine:  para[0],
			EndLine:    para[1],
			Text:       strings.Join(p.lines[para[0]:para[1]+1], "\n"),
			Annotation: kind,
		})
	}
	return out, nil
}

// InsertQuestion inserts a question block after paragraph afterParagraph
// (0-based; -1: at the start) of the value at path / field; its header
// records at (an ISO 8601 time; "" for the clock's) as the change time (SOM
// §11.9.10).
func (r *SpecReviewAnnotations) InsertQuestion(path, field string, afterParagraph int, question SpecQuestionDraft, at string) error {
	when, err := r.changeTime(at)
	if err != nil {
		return err
	}
	value := r.get(path, field)
	end, err := r.paragraphLastLine(value, afterParagraph)
	if err != nil {
		return err
	}
	r.set(path, field, annInsertAfterLine(value, end, FormatQuestionBlock(question, when)))
	return nil
}

// InsertQuestionAfterComment inserts a question block directly after the
// comment commentID; its header records at (an ISO 8601 time; "" for the
// clock's) as the change time (SOM §11.9.10).
func (r *SpecReviewAnnotations) InsertQuestionAfterComment(commentID string, question SpecQuestionDraft, at string) error {
	when, err := r.changeTime(at)
	if err != nil {
		return err
	}
	v, c, err := r.findComment(commentID)
	if err != nil {
		return err
	}
	r.set(v.path, v.field, annInsertAfterLine(v.text, c.block.end, FormatQuestionBlock(question, when)))
	return nil
}

// SetAnswer writes answer as the question's team answer, `**Answer
// (<time>):**` with at (an ISO 8601 time; "" for the clock's) as its change
// time (SOM §11.9.10); empty reopens it as `**Answer:**`. With author (a member id; "" for the team), it writes that member's
// individual answer instead, grouped and placed by the rules of SOM §11.9.8
// (empty: only takes the member out); an author that is not a member id is
// refused. A member's non-empty answer records at (an ISO 8601 time; "" for
// the clock's) as its change time (SOM §11.9.10).
func (r *SpecReviewAnnotations) SetAnswer(questionID, answer, author, at string) error {
	if author != "" && !annMemberIDRE.MatchString(author) {
		return &SpecReviewAnnotationError{Message: "\"" + author +
			"\" is not a member id (lowercase letters, digits and _)"}
	}
	v, _, q, err := r.findQuestion(questionID)
	if err != nil {
		return err
	}
	if author != "" {
		when := ""
		if strings.TrimSpace(answer) != "" {
			if when, err = r.changeTime(at); err != nil {
				return err
			}
		}
		r.set(v.path, v.field, annSetIndividualAnswer(v.text, q, author, answer, when))
		return nil
	}
	lines := strings.Split(v.text, "\n")
	a := strings.Split(answer, "\n")
	var written []string
	if answer == "" {
		written = []string{"> " + annAnswerLabel}
	} else {
		when, err := r.changeTime(at)
		if err != nil {
			return err
		}
		written = append([]string{"> **Answer (" + when + "):** " + a[0]}, annQuoted(a[1:])...)
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
// written, and the header records at (an ISO 8601 time; "" for the clock's)
// as the change time (SOM §11.9.10).
func (r *SpecReviewAnnotations) EditComment(commentID, text, at string) error {
	when, err := r.changeTime(at)
	if err != nil {
		return err
	}
	v, c, err := r.findComment(commentID)
	if err != nil {
		return err
	}
	lines := strings.Split(v.text, "\n")
	t := strings.Split(text, "\n")
	author := ""
	if c.author != nil {
		author = *c.author
	}
	head := strings.TrimRightFunc(c.beforeAuthor, unicode.IsSpace) + " (" + annAuthorAndTime(author, when) + "): " + t[0]
	block := append([]string{strings.TrimRightFunc(head, unicode.IsSpace)}, annQuoted(t[1:])...)
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
	r.set(path, field, annDecideMark(value, marks, index, accept))
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
			if b.conflict != nil && b.conflict.id != nil {
				ids = append(ids, *b.conflict.id)
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

// ---------------------------------------------------------------------------
// Reviewing inline marks (SOM §11.9.3).
// ---------------------------------------------------------------------------

// SpecMarkDecision is what to do with one inline mark.
type SpecMarkDecision string

const (
	// SpecMarkDecisionAccept takes the change: an insertion's text, nothing
	// for a deletion, a substitution's new text.
	SpecMarkDecisionAccept SpecMarkDecision = "accept"
	// SpecMarkDecisionReject undoes the change: nothing for an insertion, a
	// deletion's text, a substitution's old text.
	SpecMarkDecisionReject SpecMarkDecision = "reject"
	// SpecMarkDecisionLeave keeps the mark as written.
	SpecMarkDecisionLeave SpecMarkDecision = "leave"
)

// SpecMarkDecisions lists every SpecMarkDecision, in declaration order.
var SpecMarkDecisions = []SpecMarkDecision{
	SpecMarkDecisionAccept,
	SpecMarkDecisionReject,
	SpecMarkDecisionLeave,
}

// SpecMarkEntry is one inline mark as ListMarks reports it.
type SpecMarkEntry struct {
	// ID is `M-<n>`: the mark's 1-based position among all marks of the
	// document, in document order. Stable for one Revision.
	ID string
	// Path is the value's path.
	Path string
	// Field is the form field, or nil for content.
	Field *string
	// Line is the 0-based line within the value where the mark opens.
	Line int
	// MarkKind is the mark's kind.
	MarkKind SpecMarkKind
	// OldText is the text after rejecting the mark.
	OldText string
	// NewText is the text after accepting the mark.
	NewText string
	// Comment is a comment mark's or a commented highlight's comment.
	Comment *string
	// Markup is the mark as written.
	Markup string
	// Context is the paragraph holding the mark, verbatim — for display.
	Context string
	// Authors are the authors its attribution token names (SOM §11.9.8);
	// empty without one.
	Authors []string
	// Votes are the votes its attribution token records; empty without one.
	Votes []SpecMarkVote
	// QuotedChange is a change comment's quote (SOM §11.9.3): `kind`,
	// `oldText`, `newText` and `outcome`; nil for any other mark. Its Comment
	// is the text after the quote.
	QuotedChange map[string]any
	// CommentID is a change's attached comment, by id; nil without one.
	CommentID *string
	// ChangeID is the change an attached change comment is about, by id; nil
	// otherwise.
	ChangeID *string
	// ChangedAt is when the mark was last changed (SOM §11.9.10); nil
	// without a time.
	ChangedAt *string
}

// ToJSON is the canonical JSON form the conformance corpus pins.
func (e SpecMarkEntry) ToJSON() map[string]any {
	return e.ToJSONWith(SpecReviewJSONOptions{})
}

// ToJSONWith is the canonical JSON form, with `authors` and `votes` in the
// team form. `quotedChange`, `commentId` and `changeId` appear only on the
// marks they describe.
func (e SpecMarkEntry) ToJSONWith(options SpecReviewJSONOptions) map[string]any {
	out := map[string]any{
		"id":       e.ID,
		"path":     e.Path,
		"field":    nullableString(e.Field),
		"line":     e.Line,
		"markKind": string(e.MarkKind),
		"oldText":  e.OldText,
		"newText":  e.NewText,
		"comment":  nullableString(e.Comment),
		"markup":   e.Markup,
		"context":  e.Context,
	}
	if e.QuotedChange != nil {
		out["quotedChange"] = e.QuotedChange
	}
	if e.CommentID != nil {
		out["commentId"] = *e.CommentID
	}
	if e.ChangeID != nil {
		out["changeId"] = *e.ChangeID
	}
	if e.ChangedAt != nil {
		out["changedAt"] = *e.ChangedAt
	}
	if options.Team {
		out["authors"] = annStringsJSON(e.Authors)
		out["votes"] = annVotesJSON(e.Votes)
	}
	return out
}

// SpecMarkOutcome is what was done to one mark.
type SpecMarkOutcome struct {
	// ID is the mark's id at the revision the operation ran on.
	ID string
	// Path is the value's path.
	Path string
	// Field is the form field, or nil for content.
	Field *string
	// Line is the 0-based line within the value where the mark opened.
	Line int
	// MarkKind is the mark's kind.
	MarkKind SpecMarkKind
	// Decision is accept or reject.
	Decision SpecMarkDecision
	// Markup is the mark as written.
	Markup string
	// Result is the text that replaced it.
	Result string
}

// ToJSON is the canonical JSON form.
func (o SpecMarkOutcome) ToJSON() map[string]any {
	return map[string]any{
		"id":       o.ID,
		"path":     o.Path,
		"field":    nullableString(o.Field),
		"line":     o.Line,
		"markKind": string(o.MarkKind),
		"decision": string(o.Decision),
		"markup":   o.Markup,
		"result":   o.Result,
	}
}

// SpecMarkIssue is a mark the scanner could not read; it is left as written.
type SpecMarkIssue struct {
	// Path is the value's path.
	Path string
	// Field is the form field, or nil for content.
	Field *string
	// Line is the 0-based line within the value.
	Line int
	// Issue is `unclosed`, `nested` or `noArrow`.
	Issue string
}

// ToJSON is the canonical JSON form.
func (i SpecMarkIssue) ToJSON() map[string]any {
	return map[string]any{
		"path":  i.Path,
		"field": nullableString(i.Field),
		"line":  i.Line,
		"issue": i.Issue,
	}
}

// SpecConflictOutcome is what RemoveAllAnnotations did with one conflict
// block (SOM §11.9.8).
type SpecConflictOutcome struct {
	// ID is the conflict id, `X-<n>`.
	ID string
	// Path is the value's path.
	Path string
	// Field is the form field, or nil for content.
	Field *string
	// Line is the 0-based line within the value where the block opened.
	Line int
	// Decision is the decision as written.
	Decision string
	// Result is the text the decision chose.
	Result string
}

// ToJSON is the canonical JSON form.
func (o SpecConflictOutcome) ToJSON() map[string]any {
	return map[string]any{
		"id":       o.ID,
		"path":     o.Path,
		"field":    nullableString(o.Field),
		"line":     o.Line,
		"decision": o.Decision,
		"result":   o.Result,
	}
}

// SpecMarkReport is the report of a mark operation, for the decision log.
type SpecMarkReport struct {
	// Applied is what was done, in document order.
	Applied []SpecMarkOutcome
	// Malformed are the malformed marks in scope, left as written.
	Malformed []SpecMarkIssue
	// Conflicts are the conflicts RemoveAllAnnotations applied, in document
	// order; nil for the mark operations, which do not touch conflicts (an
	// empty, non-nil slice: a removal that found none).
	Conflicts []SpecConflictOutcome
}

// ToJSON is the canonical JSON form.
func (r SpecMarkReport) ToJSON() map[string]any {
	return r.ToJSONWith(SpecReviewJSONOptions{})
}

// ToJSONWith is the canonical JSON form, with the `conflicts` of a removal in
// the team form.
func (r SpecMarkReport) ToJSONWith(options SpecReviewJSONOptions) map[string]any {
	applied := make([]any, 0, len(r.Applied))
	for _, a := range r.Applied {
		applied = append(applied, a.ToJSON())
	}
	malformed := make([]any, 0, len(r.Malformed))
	for _, m := range r.Malformed {
		malformed = append(malformed, m.ToJSON())
	}
	out := map[string]any{"applied": applied, "malformed": malformed}
	if options.Team && r.Conflicts != nil {
		conflicts := make([]any, 0, len(r.Conflicts))
		for _, c := range r.Conflicts {
			conflicts = append(conflicts, c.ToJSON())
		}
		out["conflicts"] = conflicts
	}
	return out
}

// Revision is the revision the mark ids are stable for: FNV-1a 64-bit over
// the UTF-8 of every value in document order (path, NUL, field or empty,
// NUL, text, NUL), as 16 lower-case hex digits. Any change to a value changes
// it.
func (r *SpecReviewAnnotations) Revision() string {
	h := uint64(0xcbf29ce484222325)
	const prime = uint64(0x100000001b3)
	add := func(s string) {
		for k := 0; k < len(s); k++ {
			h ^= uint64(s[k])
			h *= prime
		}
		h *= prime // the NUL byte: h ^ 0 == h
	}
	for _, v := range r.values() {
		add(v.path)
		add(v.field)
		add(v.text)
	}
	return fmt.Sprintf("%016x", h)
}

func annUnder(path, under string) bool {
	return under == "" || path == under || strings.HasPrefix(path, under+"/")
}

// ListMarks returns every inline mark of the document, or of the subtree at
// path ("" for the whole document), in document order.
func (r *SpecReviewAnnotations) ListMarks(path string) []SpecMarkEntry {
	out := []SpecMarkEntry{}
	n := 0
	for _, v := range r.values() {
		p := annParse(v.text)
		paras := annParagraphs(p.lines, p.code)
		first := n + 1
		markID := func(k int) *string {
			if k < 0 {
				return nil
			}
			id := "M-" + strconv.Itoa(first+k)
			return &id
		}
		for _, m := range p.marks {
			n++
			id := "M-" + strconv.Itoa(n)
			if !annUnder(v.path, path) {
				continue
			}
			para := [2]int{m.line, m.line}
			for _, pr := range paras {
				if pr[0] <= m.line && m.line <= pr[1] {
					para = pr
					break
				}
			}
			entry := SpecMarkEntry{
				ID:        id,
				Path:      v.path,
				Field:     annFieldPtr(v.field),
				Line:      m.line,
				MarkKind:  m.kind,
				OldText:   annMarkReplacement(m, false),
				NewText:   annMarkReplacement(m, true),
				Comment:   m.comment,
				Markup:    v.text[m.start:m.end],
				Context:   strings.Join(p.lines[para[0]:para[1]+1], "\n"),
				Authors:   m.authors,
				Votes:     m.votes,
				CommentID: markID(m.commentIndex),
				ChangeID:  markID(m.changeIndex),
				ChangedAt: m.changedAt,
			}
			if m.quote != nil {
				c := m.quote.comment
				entry.Comment = &c
				entry.QuotedChange = m.quote.toJSON()
			}
			out = append(out, entry)
		}
	}
	return out
}

// applyMarks applies decide to every mark in the subtree under ("" for the
// whole document), one write per value. decide answers "" for no decision.
func (r *SpecReviewAnnotations) applyMarks(decide func(id string, m *annMark) SpecMarkDecision, under string) SpecMarkReport {
	applied := []SpecMarkOutcome{}
	issues := []SpecMarkIssue{}
	n := 0
	for _, v := range r.values() {
		p := annParse(v.text)
		ids := make([]string, len(p.marks))
		for k := range p.marks {
			n++
			ids[k] = "M-" + strconv.Itoa(n)
		}
		if !annUnder(v.path, under) {
			continue
		}
		for _, is := range p.markIssues {
			issues = append(issues, SpecMarkIssue{Path: v.path, Field: annFieldPtr(v.field), Line: is.line, Issue: is.issue})
		}
		value := v.text
		var outcomes []SpecMarkOutcome
		decided := make([]SpecMarkDecision, len(p.marks))
		for k, m := range p.marks {
			decided[k] = decide(ids[k], m)
		}
		isDecided := func(k int) bool {
			return decided[k] != "" && decided[k] != SpecMarkDecisionLeave
		}
		for k := len(p.marks) - 1; k >= 0; k-- {
			if !isDecided(k) {
				continue
			}
			d := decided[k]
			m := p.marks[k]
			repl := annMarkReplacement(m, d == SpecMarkDecisionAccept)
			if ci := m.commentIndex; ci >= 0 && !isDecided(ci) {
				value = annRecordOutcome(value, p.marks[ci].quote, d == SpecMarkDecisionAccept)
			}
			outcomes = append([]SpecMarkOutcome{{
				ID:       ids[k],
				Path:     v.path,
				Field:    annFieldPtr(v.field),
				Line:     m.line,
				MarkKind: m.kind,
				Decision: d,
				Markup:   v.text[m.start:m.end],
				Result:   repl,
			}}, outcomes...)
			value = annReplaceMark(value, m, repl, annBoolPtr(d == SpecMarkDecisionAccept))
		}
		if value != v.text {
			r.set(v.path, v.field, value)
		}
		applied = append(applied, outcomes...)
	}
	return SpecMarkReport{Applied: applied, Malformed: issues}
}

// DecideMarks applies one decision per named mark in one write. Refused —
// nothing changes — when the document is no longer at revision, or when a
// decision names a mark that does not exist. Marks not named, and marks
// decided leave, stay.
func (r *SpecReviewAnnotations) DecideMarks(decisions map[string]SpecMarkDecision, revision string) (SpecMarkReport, error) {
	current := r.Revision()
	if revision != current {
		return SpecMarkReport{}, &SpecReviewAnnotationError{Message: "the document changed since revision " +
			revision + " (now " + current + "); list the marks again"}
	}
	known := map[string]bool{}
	for _, m := range r.ListMarks("") {
		known[m.ID] = true
	}
	ids := make([]string, 0, len(decisions))
	for id := range decisions {
		ids = append(ids, id)
	}
	sort.Strings(ids)
	for _, id := range ids {
		if !known[id] {
			return SpecMarkReport{}, &SpecReviewAnnotationError{Message: "no inline mark " + id + " in the document"}
		}
	}
	return r.applyMarks(func(id string, _ *annMark) SpecMarkDecision { return decisions[id] }, ""), nil
}

// AcceptAllMarks accepts every inline mark under path ("" for the whole
// document), except change comments, which stay (SOM §11.9.3).
func (r *SpecReviewAnnotations) AcceptAllMarks(path string) SpecMarkReport {
	return r.applyMarks(func(_ string, m *annMark) SpecMarkDecision {
		if m.quote != nil {
			return ""
		}
		return SpecMarkDecisionAccept
	}, path)
}

// RejectAllMarks rejects every inline mark under path ("" for the whole
// document), except change comments, which stay (SOM §11.9.3).
func (r *SpecReviewAnnotations) RejectAllMarks(path string) SpecMarkReport {
	return r.applyMarks(func(_ string, m *annMark) SpecMarkDecision {
		if m.quote != nil {
			return ""
		}
		return SpecMarkDecisionReject
	}, path)
}

// findMark finds the mark `M-<n>` markID with its value, refused when the
// document is no longer at revision (when not "") or holds no such mark.
func (r *SpecReviewAnnotations) findMark(markID, revision string) (annValue, *annParsed, int, error) {
	if revision != "" {
		if current := r.Revision(); revision != current {
			return annValue{}, nil, 0, &SpecReviewAnnotationError{Message: "the document changed since revision " +
				revision + " (now " + current + "); list the marks again"}
		}
	}
	n := 0
	for _, v := range r.values() {
		p := annParse(v.text)
		for k := range p.marks {
			n++
			if "M-"+strconv.Itoa(n) == markID {
				return v, p, k, nil
			}
		}
	}
	return annValue{}, nil, 0, &SpecReviewAnnotationError{Message: "no inline mark " + markID + " in the document"}
}

// CommentChange writes a change comment (SOM §11.9.3) directly after the
// change mark markID, its quote written from the mark and text after it,
// with an attribution token `{@author T}` (T: at, an ISO 8601 time, or the
// clock's when at is ""; SOM §11.9.10), and returns the new comment's id. Refused with a SpecReviewAnnotationError — nothing
// changes — for an unknown id, a stale revision (when not ""), a mark that
// is not a change or already has an attached comment, a change its quote
// cannot hold, a text that is empty or holds a mark delimiter or a blank
// line, and an author that is not a member id.
func (r *SpecReviewAnnotations) CommentChange(markID, text, author, revision, at string) (string, error) {
	when, err := r.changeTime(at)
	if err != nil {
		return "", err
	}
	v, p, k, err := r.findMark(markID, revision)
	if err != nil {
		return "", err
	}
	m := p.marks[k]
	if !annIsChangeMark(m.kind) {
		return "", &SpecReviewAnnotationError{Message: markID + " is a " + string(m.kind) + " mark, not a change"}
	}
	if m.commentIndex >= 0 {
		return "", &SpecReviewAnnotationError{Message: markID + " already has a comment; edit it instead"}
	}
	comment, err := annCheckInlineComment(text)
	if err != nil {
		return "", err
	}
	if author != "" && !annMemberIDRE.MatchString(author) {
		return "", &SpecReviewAnnotationError{Message: "\"" + author + "\" is not a member id"}
	}
	d := "~~"
	switch m.kind {
	case SpecMarkKindInsertion:
		d = "++"
	case SpecMarkKindDeletion:
		d = "--"
	}
	body := m.text
	if m.kind == SpecMarkKindSubstitution {
		body = m.text + " ~> " + *m.newText
	}
	if strings.Contains(body, d+"]") || strings.Contains(body, "<<}") {
		return "", &SpecReviewAnnotationError{Message: markID + " holds \"" + d + "]\" or \"<<}\", which its quote cannot hold"}
	}
	var authors []string
	if author != "" {
		authors = []string{author}
	}
	markup := "{>> [" + d + " " + body + " " + d + "] " + comment + " <<}" +
		formatAttributionToken(authors, nil, when)
	r.set(v.path, v.field, v.text[:m.end]+markup+v.text[m.end:])
	n, _ := strconv.Atoi(markID[2:])
	return "M-" + strconv.Itoa(n+1), nil
}

// EditMarkComment replaces the comment of the comment mark, change comment
// or commented highlight markID with text (SOM §11.9.3). A change comment
// keeps its quote as written, and the attribution token keeps its authors and
// votes and records at (an ISO 8601 time; "" for the clock's) as the change
// time (SOM §11.9.10). Refused with
// a SpecReviewAnnotationError — nothing changes — for an unknown id, a stale
// revision (when not ""), a mark that holds no comment, and a text that is
// empty or holds a mark delimiter or a blank line.
func (r *SpecReviewAnnotations) EditMarkComment(markID, text, revision, at string) error {
	when, err := r.changeTime(at)
	if err != nil {
		return err
	}
	v, p, k, err := r.findMark(markID, revision)
	if err != nil {
		return err
	}
	m := p.marks[k]
	comment, err := annCheckInlineComment(text)
	if err != nil {
		return err
	}
	var markup string
	switch {
	case m.kind == SpecMarkKindComment:
		if q := m.quote; q == nil {
			markup = "{>> " + comment + " <<}"
		} else {
			markup = "{>> " + strings.TrimLeftFunc(v.text[m.start+3:q.end], unicode.IsSpace) + " " + comment + " <<}"
		}
	case m.kind == SpecMarkKindHighlight && m.comment != nil:
		markup = "{== " + m.text + " ==}{>> " + comment + " <<}"
	default:
		return &SpecReviewAnnotationError{Message: markID + " holds no comment"}
	}
	token := formatAttributionToken(m.authors, m.votes, when)
	r.set(v.path, v.field, v.text[:m.start]+markup+token+v.text[m.end:])
	return nil
}

// RemoveAllAnnotations removes every annotation and writes the result back:
// every inline mark accepted, every conflict's decision applied (SOM
// §11.9.8), every comment, question and conflict block removed. Malformed
// marks stay and are reported. Refused with a SpecReviewAnnotationError —
// nothing changes — while a conflict is open, unresolved (`open:`),
// malformed, or decided for a letter it has no alternative for.
func (r *SpecReviewAnnotations) RemoveAllAnnotations() (SpecMarkReport, error) {
	decided, err := r.decidedConflicts()
	if err != nil {
		return SpecMarkReport{}, err
	}
	report := r.applyMarks(func(string, *annMark) SpecMarkDecision { return SpecMarkDecisionAccept }, "")
	report.Conflicts = []SpecConflictOutcome{}
	for _, v := range r.values() {
		value := v.text
		var here []annDecidedConflict
		for _, d := range decided {
			if d.path == v.path && d.field == v.field {
				here = append(here, d)
			}
		}
		if len(here) > 0 {
			value = r.applyConflicts(v.path, v.field, value, here, &report.Conflicts)
		}
		for {
			p := annParse(value)
			if len(p.blocks) == 0 {
				break
			}
			b := p.blocks[len(p.blocks)-1]
			value = annRemoveLines(value, b.start, b.end)
		}
		if value != v.text {
			r.set(v.path, v.field, value)
		}
	}
	return report, nil
}

// decidedConflicts lists every conflict block of the document with the line
// it opens on, in document order — or the refusal of RemoveAllAnnotations
// when one of them cannot be applied.
func (r *SpecReviewAnnotations) decidedConflicts() ([]annDecidedConflict, error) {
	var out []annDecidedConflict
	for _, v := range r.values() {
		p := annParse(v.text)
		index := 0
		for _, b := range p.blocks {
			if b.kind != SpecReviewAnnotationKindConflict {
				continue
			}
			c := b.conflict
			where := v.path
			if v.field != "" {
				where += " / " + v.field
			}
			where += ", line " + strconv.Itoa(b.start)
			if c.id == nil || c.base == nil || len(c.alternatives) == 0 {
				return nil, &SpecReviewAnnotationError{Message: where + ": a malformed conflict block cannot be applied"}
			}
			if c.decision == "" || annIsUnresolved(c.decision) {
				state := "unresolved"
				if c.decision == "" {
					state = "open"
				}
				return nil, &SpecReviewAnnotationError{Message: where + ": conflict " + *c.id + " is " + state +
					"; decide it before removing the annotations"}
			}
			if letter := annDecisionLetter(c.decision); letter != nil && *letter != "base" {
				found := false
				for _, a := range c.alternatives {
					if a.Letter == *letter {
						found = true
					}
				}
				if !found {
					return nil, &SpecReviewAnnotationError{Message: where + ": conflict " + *c.id +
						" has no alternative (" + *letter + ")"}
				}
			}
			out = append(out, annDecidedConflict{path: v.path, field: v.field, index: index, id: *c.id,
				line: b.start, decision: c.decision})
			index++
		}
	}
	return out, nil
}

// applyConflicts applies the decided conflicts of one value (marks already
// accepted), from the last block up so earlier line numbers stay valid, and
// records each in outcomes.
func (r *SpecReviewAnnotations) applyConflicts(path, field, value string, decided []annDecidedConflict,
	outcomes *[]SpecConflictOutcome) string {
	v := value
	var conflicts []*annBlock
	for _, b := range annParse(v).blocks {
		if b.kind == SpecReviewAnnotationKindConflict {
			conflicts = append(conflicts, b)
		}
	}
	recorded := make([]SpecConflictOutcome, len(conflicts))
	for k := len(conflicts) - 1; k >= 0; k-- {
		var d annDecidedConflict
		for _, x := range decided {
			if x.index == k {
				d = x
			}
		}
		c := conflicts[k].conflict
		result := annChosenText(c)
		recorded[k] = SpecConflictOutcome{ID: d.id, Path: path, Field: annFieldPtr(field), Line: d.line,
			Decision: d.decision, Result: result}
		v = r.applyConflict(path, field, v, c, result)
	}
	*outcomes = append(*outcomes, recorded...)
	return v
}

var (
	// annFieldTargetRE is a conflict text naming a form field: `<path> <field>`.
	annFieldTargetRE = regexp.MustCompile(`^(\S+) (\S+)$`)
	// annValueTargetRE is a conflict text naming a value path.
	annValueTargetRE = regexp.MustCompile(`^[^\s,]+/[^\s,]+$`)
)

// applyConflict puts the text a conflict's decision chose in place. Where it
// goes follows the conflict's text (SOM §11.9.8, "Applying"): a form field,
// another value, this value's text paragraphs (a whole-value unit), or — the
// default — the text paragraph directly before the block. A structural
// conflict only goes; its change is the caller's.
func (r *SpecReviewAnnotations) applyConflict(path, field, value string, c *annConflict, result string) string {
	if annStructuralTopics[c.topic] {
		return value
	}
	if t := annFieldTargetRE.FindStringSubmatch(c.text); t != nil {
		if _, ok := r.Doc.FormField(t[1], t[2]); ok {
			r.Doc.SetFormField(t[1], t[2], result)
			return value
		}
	}
	if field == "" && c.text == path {
		return annReplaceTextRun(value, c.block, result)
	}
	if annValueTargetRE.MatchString(c.text) && c.text != path {
		r.Doc.SetContent(c.text, result)
		return value
	}
	return annReplaceParagraphBefore(value, c.block, result)
}

// SetMarked writes text at path / field ("" for content) as a marked change
// against the value there now (SOM §11.9.3). A value that already holds
// change marks is compared from its original — every mark rejected — so a
// second edit of the same passage updates its mark instead of nesting one.
// Change comments stay: each is taken out of the original and written back
// after the same number of non-whitespace characters (SOM §11.9.3). Every
// change mark gets an attribution token (SOM §11.9.10): the one it had when
// the change was there before, else `{@author T}` (author "" for none; T: at,
// an ISO 8601 time, or the clock's when at is ""). An author that is not a
// member id and an invalid at are refused with a SpecReviewAnnotationError;
// nothing changes.
func (r *SpecReviewAnnotations) SetMarked(path, field, text, author, at string) (SpecMarkedChange, error) {
	if err := annCheckAuthor(author); err != nil {
		return SpecMarkedChange{}, err
	}
	when, err := r.changeTime(at)
	if err != nil {
		return SpecMarkedChange{}, err
	}
	current := r.get(path, field)
	result := annMarkKeepingChangeComments(current, text)
	stamped := SpecMarkedChange{Text: annStampMarks(current, result.Text, author, when), Exact: result.Exact}
	r.set(path, field, stamped.Text)
	return stamped, nil
}

// MarkAgainst marks the value at path / field ("" for content) as a change
// against earlier, an earlier version of it; author and at as for SetMarked.
func (r *SpecReviewAnnotations) MarkAgainst(path, field, earlier, author, at string) (SpecMarkedChange, error) {
	if err := annCheckAuthor(author); err != nil {
		return SpecMarkedChange{}, err
	}
	when, err := r.changeTime(at)
	if err != nil {
		return SpecMarkedChange{}, err
	}
	current := r.get(path, field)
	result := MarkChangeText(earlier, current)
	stamped := SpecMarkedChange{Text: annStampMarks(current, result.Text, author, when), Exact: result.Exact}
	r.set(path, field, stamped.Text)
	return stamped, nil
}

// annStampMarks is after (a value just written as marks) with an attribution
// token on every change mark it lacks one on (SOM §11.9.10): the token of the
// same change in before (same kind, old and new text; each used once, in
// order) when before held it, else a new one with author and when.
func annStampMarks(before, after, author, when string) string {
	key := func(m *annMark) string {
		return string(m.kind) + "\x00" + annMarkReplacement(m, false) + "\x00" + annMarkReplacement(m, true)
	}
	type oldMark struct{ key, token string }
	var old []oldMark
	for _, m := range annParse(before).marks {
		if annIsChangeMark(m.kind) {
			old = append(old, oldMark{key(m), before[m.bodyEnd:m.end]})
		}
	}
	used := make([]bool, len(old))
	var authors []string
	if author != "" {
		authors = []string{author}
	}
	fresh := formatAttributionToken(authors, nil, when)
	type insert struct {
		at    int
		token string
	}
	var inserts []insert
	for _, m := range annParse(after).marks {
		if !annIsChangeMark(m.kind) || m.end > m.bodyEnd {
			continue
		}
		k := key(m)
		token := fresh
		for i := range old {
			if !used[i] && old[i].key == k {
				used[i] = true
				token = old[i].token
				break
			}
		}
		if token != "" {
			inserts = append(inserts, insert{m.bodyEnd, token})
		}
	}
	v := after
	for i := len(inserts) - 1; i >= 0; i-- {
		v = v[:inserts[i].at] + inserts[i].token + v[inserts[i].at:]
	}
	return v
}

// ---------------------------------------------------------------------------
// Writing changes as inline marks (SOM §11.9.3, annot5).
// ---------------------------------------------------------------------------

// SpecMarkedChange is a value written as a marked change.
type SpecMarkedChange struct {
	// Text is the value with every difference marked.
	Text string
	// Exact is whether accepting the marks gives exactly the new value and
	// rejecting them exactly the old one. False when a difference cannot be
	// marked — a change inside fenced code, or text that holds mark
	// delimiters — and the new value was written unmarked instead.
	Exact bool
}

// ToJSON is the canonical JSON form.
func (c SpecMarkedChange) ToJSON() map[string]any {
	return map[string]any{"text": c.Text, "exact": c.Exact}
}

// annTok is one token of a value: a run of whitespace, a word (a run of
// non-whitespace with inline code spans kept whole) or a fenced code block
// (its lines).
type annTok struct {
	text  string
	space bool
}

func annIsWs(c byte) bool { return c == ' ' || c == '\t' || c == '\n' }

func annTokens(value string) []annTok {
	var out []annTok
	add := func(t string, space bool) {
		if t == "" {
			return
		}
		if space && len(out) > 0 && out[len(out)-1].space {
			out[len(out)-1] = annTok{out[len(out)-1].text + t, true}
		} else {
			out = append(out, annTok{t, space})
		}
	}
	words := func(s string) {
		i := 0
		for i < len(s) {
			if annIsWs(s[i]) {
				st := i
				for i < len(s) && annIsWs(s[i]) {
					i++
				}
				add(s[st:i], true)
				continue
			}
			st := i
			for i < len(s) && !annIsWs(s[i]) {
				if s[i] == '`' {
					n := 0
					for i+n < len(s) && s[i+n] == '`' {
						n++
					}
					// The matching run of exactly n backticks ends the span.
					j := i + n
					closeAt := -1
					for j < len(s) {
						if s[j] == '`' {
							m := 0
							for j+m < len(s) && s[j+m] == '`' {
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
				i++
			}
			add(s[st:i], false)
		}
	}
	lines := strings.Split(value, "\n")
	code := annCodeLines(lines)
	k := 0
	for k < len(lines) {
		if k > 0 {
			add("\n", true)
		}
		st := k
		isCode := code[k]
		for k+1 < len(lines) && code[k+1] == isCode {
			k++
		}
		run := strings.Join(lines[st:k+1], "\n")
		if isCode {
			add(run, false)
		} else {
			words(run)
		}
		k++
	}
	return out
}

// annOp is one diff op: kind 0 keep, 1 delete (old), 2 insert (new).
type annOp struct {
	kind int
	tok  annTok
}

// annDiff is the diff of two token lists. LCS over token text; ties prefer
// the deletion.
func annDiff(a, b []annTok) []annOp {
	n, m := len(a), len(b)
	l := make([][]int, n+1)
	for i := range l {
		l[i] = make([]int, m+1)
	}
	for i := n - 1; i >= 0; i-- {
		for j := m - 1; j >= 0; j-- {
			if a[i].text == b[j].text {
				l[i][j] = l[i+1][j+1] + 1
			} else if l[i+1][j] >= l[i][j+1] {
				l[i][j] = l[i+1][j]
			} else {
				l[i][j] = l[i][j+1]
			}
		}
	}
	var ops []annOp
	i, j := 0, 0
	for i < n || j < m {
		if i < n && j < m && a[i].text == b[j].text {
			ops = append(ops, annOp{0, a[i]})
			i++
			j++
		} else if j >= m || (i < n && l[i+1][j] >= l[i][j+1]) {
			ops = append(ops, annOp{1, a[i]})
			i++
		} else {
			ops = append(ops, annOp{2, b[j]})
			j++
		}
	}
	return ops
}

// annTrimWs is s with its leading and trailing whitespace removed (spaces,
// tabs, newlines).
func annTrimWs(s string) string {
	a, b := 0, len(s)
	for a < b && annIsWs(s[a]) {
		a++
	}
	for b > a && annIsWs(s[b-1]) {
		b--
	}
	return s[a:b]
}

// annMarkup is the markup for one region whose old text is o and new text
// is n (both trimmed, not both empty).
func annMarkup(o, n string) string {
	if o == "" {
		return "{++ " + n + " ++}"
	}
	if n == "" {
		return "{-- " + o + " --}"
	}
	return "{~~ " + o + " ~> " + n + " ~~}"
}

func annLeadWs(x string) string { return x[:len(x)-len(strings.TrimLeftFunc(x, unicode.IsSpace))] }

func annTrailWs(x string) string { return x[len(strings.TrimRightFunc(x, unicode.IsSpace)):] }

// annEmitRegion is the marked emission for the region [r0, r1) of ops, with
// the old and the new text around it; ok false when no mark round-trips
// there.
func annEmitRegion(ops []annOp, r0, r1 int, oldBefore, newBefore, oldAfter, newAfter string) (string, bool) {
	var o, n strings.Builder
	for k := r0; k < r1; k++ {
		if ops[k].kind != 2 {
			o.WriteString(ops[k].tok.text)
		}
		if ops[k].kind != 1 {
			n.WriteString(ops[k].tok.text)
		}
	}
	os, ns := o.String(), n.String()
	// Whitespace the two sides share at the edges stays outside the mark.
	lead := 0
	for lead < len(os) && lead < len(ns) && os[lead] == ns[lead] && annIsWs(os[lead]) {
		lead++
	}
	trail := 0
	for trail < len(os)-lead && trail < len(ns)-lead &&
		os[len(os)-1-trail] == ns[len(ns)-1-trail] && annIsWs(os[len(os)-1-trail]) {
		trail++
	}
	oi := os[lead : len(os)-trail]
	ni := ns[lead : len(ns)-trail]
	// The mark's content is trimmed when read, so it must already be
	// trimmed; the whitespace still differing is placed outside, on the side
	// whose text keeps it, and the tidy rules then have to restore the other
	// side.
	ot, nt := annTrimWs(oi), annTrimWs(ni)
	if ot == "" && nt == "" {
		return "", false
	}
	pre := os[:lead]
	post := os[len(os)-trail:]
	candidates := [][2]string{
		{annLeadWs(ni), annTrailWs(ni)},
		{annLeadWs(oi), annTrailWs(oi)},
		{"", ""},
		{annLeadWs(ni), ""},
		{"", annTrailWs(ni)},
	}
	markup := annMarkup(ot, nt)
	for _, c := range candidates {
		emission := pre + c[0] + markup + c[1] + post
		acc := ApplyInlineMarksText(newBefore+emission+newAfter, true)
		rej := ApplyInlineMarksText(oldBefore+emission+oldAfter, false)
		if acc == newBefore+ns+newAfter && rej == oldBefore+os+oldAfter {
			return emission, true
		}
	}
	return "", false
}

// annMarkTokens marks the token-level differences of o → n, where the text
// before them is ob (old) / nb (new) and after them oa / na; ok false when
// the marks do not round-trip.
func annMarkTokens(o, n, ob, nb, oa, na string) (string, bool) {
	ops := annDiff(annTokens(o), annTokens(n))
	var runs [][2]int
	k := 0
	for k < len(ops) {
		if ops[k].kind == 0 {
			k++
			continue
		}
		s := k
		for k < len(ops) && ops[k].kind != 0 {
			k++
		}
		runs = append(runs, [2]int{s, k})
	}
	// Changes separated by at most two unchanged words are one mark.
	var merged [][2]int
	for _, r := range runs {
		if len(merged) > 0 {
			words := 0
			for q := merged[len(merged)-1][1]; q < r[0]; q++ {
				if !ops[q].tok.space {
					words++
				}
			}
			if words <= 2 {
				merged[len(merged)-1][1] = r[1]
				continue
			}
		}
		merged = append(merged, r)
	}
	runs = merged

	side := func(from, to, skip int) string {
		var b strings.Builder
		for q := from; q < to; q++ {
			if ops[q].kind != skip {
				b.WriteString(ops[q].tok.text)
			}
		}
		return b.String()
	}

	// Left to right; a region that does not round-trip grows by one token
	// on each side and is tried again.
	var out strings.Builder
	pos := 0
	for ri := 0; ri < len(runs); ri++ {
		r0, r1 := runs[ri][0], runs[ri][1]
		if r0 < pos {
			r0 = pos
		}
		var emission string
		var ok bool
		for {
			emission, ok = annEmitRegion(ops, r0, r1,
				ob+side(0, r0, 2),
				nb+side(0, r0, 1),
				side(r1, len(ops), 2)+oa,
				side(r1, len(ops), 1)+na)
			if ok || (r0 <= pos && r1 >= len(ops)) {
				break
			}
			if r0 > pos {
				r0--
			}
			if r1 < len(ops) {
				r1++
			}
		}
		if !ok {
			return "", false
		}
		out.WriteString(side(pos, r0, 1))
		out.WriteString(emission)
		pos = r1
		for ri+1 < len(runs) && runs[ri+1][1] <= pos {
			ri++
		}
	}
	out.WriteString(side(pos, len(ops), 1))
	text := out.String()
	if ApplyInlineMarksText(nb+text+na, true) != nb+n+na ||
		ApplyInlineMarksText(ob+text+oa, false) != ob+o+oa {
		return "", false
	}
	return text, true
}

// annLineMark is a whole line marked as inserted (`++`) or deleted (`--`):
// its indentation stays outside the mark; a blank line stays blank.
func annLineMark(line, d string) string {
	body := strings.TrimLeftFunc(line, unicode.IsSpace)
	if strings.TrimSpace(body) == "" {
		return line
	}
	indent := line[:len(line)-len(body)]
	return indent + "{" + d + " " + strings.TrimRightFunc(body, unicode.IsSpace) + " " + d + "}"
}

// MarkChangeText returns newValue with its differences from oldValue marked,
// so that accepting every mark gives exactly newValue and rejecting every
// mark exactly oldValue (SOM §11.9.3). The diff runs by line, then by word
// inside a changed run of lines; words are never split, changes separated by
// at most two unchanged words are one mark, and nothing inside code is
// marked.
func MarkChangeText(oldValue, newValue string) SpecMarkedChange {
	if oldValue == newValue {
		return SpecMarkedChange{Text: newValue, Exact: true}
	}
	ol, nl := strings.Split(oldValue, "\n"), strings.Split(newValue, "\n")
	oc, nc := annCodeLines(ol), annCodeLines(nl)
	toks := func(ls []string) []annTok {
		out := make([]annTok, len(ls))
		for i, l := range ls {
			out[i] = annTok{l, false}
		}
		return out
	}
	lops := annDiff(toks(ol), toks(nl))
	join := func(parts ...[]string) string {
		var all []string
		for _, p := range parts {
			all = append(all, p...)
		}
		return strings.Join(all, "\n")
	}
	blank := func(l string) bool { return strings.TrimSpace(l) == "" }
	nonBlank := func(ls []string) []string {
		var out []string
		for _, l := range ls {
			if !blank(l) {
				out = append(out, l)
			}
		}
		return out
	}
	var out []string
	exact := true
	oi, ni, k := 0, 0, 0
	for k < len(lops) {
		if lops[k].kind == 0 {
			out = append(out, nl[ni])
			oi++
			ni++
			k++
			continue
		}
		d0, n0 := oi, ni
		for k < len(lops) && lops[k].kind != 0 {
			if lops[k].kind == 1 {
				oi++
			} else {
				ni++
			}
			k++
		}
		del, ins := ol[d0:oi], nl[n0:ni]
		ob, oa := ol[:d0], ol[oi:]
		nb, na := nl[:n0], nl[ni:]
		roundTrips := func(e []string) bool {
			return ApplyInlineMarksText(join(nb, e, na), true) == newValue &&
				ApplyInlineMarksText(join(ob, e, oa), false) == oldValue
		}
		var emitted []string
		found := false
		inCode := false
		for q := d0; q < oi; q++ {
			inCode = inCode || oc[q]
		}
		for q := n0; q < ni; q++ {
			inCode = inCode || nc[q]
		}
		if !inCode {
			var candidates [][]string
			if len(del) > 0 && len(ins) > 0 {
				before := func(ls []string) string {
					if len(ls) == 0 {
						return ""
					}
					return join(ls) + "\n"
				}
				after := func(ls []string) string {
					if len(ls) == 0 {
						return ""
					}
					return "\n" + join(ls)
				}
				if t, ok := annMarkTokens(join(del), join(ins), before(ob), before(nb), after(oa), after(na)); ok {
					candidates = append(candidates, strings.Split(t, "\n"))
				}
			}
			dm := make([]string, len(del))
			for i, l := range del {
				dm[i] = annLineMark(l, "--")
			}
			im := make([]string, len(ins))
			for i, l := range ins {
				im[i] = annLineMark(l, "++")
			}
			cat := func(a, b []string) []string {
				out := append([]string{}, a...)
				return append(out, b...)
			}
			candidates = append(candidates,
				cat(dm, im),
				cat(nonBlank(dm), im),
				cat(dm, nonBlank(im)),
				cat(nonBlank(dm), nonBlank(im)))
			for _, e := range candidates {
				if roundTrips(e) {
					emitted = e
					found = true
					break
				}
			}
		}
		if !found {
			exact = false
			out = append(out, ins...)
		} else {
			out = append(out, emitted...)
		}
	}
	text := strings.Join(out, "\n")
	if exact && (ApplyInlineMarksText(text, true) != newValue ||
		ApplyInlineMarksText(text, false) != oldValue) {
		return SpecMarkedChange{Text: newValue, Exact: false}
	}
	return SpecMarkedChange{Text: text, Exact: exact}
}

// ---------------------------------------------------------------------------
// Text-level building blocks of the merge (SOM §11.9.9), for
// spec_review_merge.go.
// ---------------------------------------------------------------------------

// reviewPiece is one paragraph of a value as the merge sees it: text, or an
// annotation block.
type reviewPiece struct {
	// kind is "text", or the annotation kind of the block the paragraph opens
	// with.
	kind string
	// text is the paragraph's lines, verbatim.
	text string
	// id is a comment's id (nil without one), a conflict's id (nil when
	// malformed).
	id *string
	// author is a comment's author, nil without one.
	author *string
	// commentText is a comment's text.
	commentText string
	// changedAt is a comment's change time (SOM §11.9.10), "" without one.
	changedAt string
	// questionIDs are the ids of a question block's questions.
	questionIDs []string
}

const reviewPieceText = "text"

// reviewPieces are the paragraphs of value (SOM §11.9.1), each classified.
func reviewPieces(value string) []reviewPiece {
	if value == "" {
		return nil
	}
	p := annParse(value)
	var out []reviewPiece
	for _, para := range annParagraphs(p.lines, p.code) {
		piece := reviewPiece{kind: reviewPieceText, text: strings.Join(p.lines[para[0]:para[1]+1], "\n")}
		for _, b := range p.blocks {
			if b.start != para[0] {
				continue
			}
			piece.kind = string(b.kind)
			if b.comment != nil {
				piece.id = b.comment.id
				piece.author = b.comment.author
				piece.commentText = b.comment.text
				if b.comment.changedAt != nil {
					piece.changedAt = *b.comment.changedAt
				}
			}
			if b.conflict != nil {
				piece.id = b.conflict.id
			}
			for _, q := range b.questions {
				piece.questionIDs = append(piece.questionIDs, q.id)
			}
			break
		}
		out = append(out, piece)
	}
	return out
}

// reviewMark is one inline mark of a value, with what its decisions leave.
type reviewMark struct {
	start, end, bodyEnd int
	kind                SpecMarkKind
	// markup is the mark as written, its attribution token included.
	markup  string
	authors []string
	votes   []SpecMarkVote
	// changedAt is its token's change time (SOM §11.9.10), "" without one.
	changedAt string
	// accepted is the text accepting it leaves; rejected rejecting it.
	accepted, rejected string
}

// reviewMarks are the inline marks of value, in order (marks in code are not
// marks).
func reviewMarks(value string) []reviewMark {
	marks := annParse(value).marks
	out := make([]reviewMark, 0, len(marks))
	for _, m := range marks {
		rm := reviewMark{
			start: m.start, end: m.end, bodyEnd: m.bodyEnd, kind: m.kind,
			markup:   value[m.start:m.end],
			authors:  m.authors,
			votes:    m.votes,
			accepted: annMarkReplacement(m, true),
			rejected: annMarkReplacement(m, false),
		}
		if m.changedAt != nil {
			rm.changedAt = *m.changedAt
		}
		out = append(out, rm)
	}
	return out
}

// decideReviewMarks is value with the marks decisions names (by index into
// reviewMarks; true accepts) accepted or rejected, by the whitespace rules of
// SOM §11.9.3.
func decideReviewMarks(value string, decisions map[int]bool) string {
	marks := annParse(value).marks
	v := value
	for k := len(marks) - 1; k >= 0; k-- {
		accept, ok := decisions[k]
		if !ok {
			continue
		}
		v = annReplaceMark(v, marks[k], annMarkReplacement(marks[k], accept), &accept)
	}
	return v
}

// formatAttributionToken is the attribution token for authors, votes and
// changedAt ("" for none), `{@agent +alice -bob 2026-11-07T14:05+01:00}`
// (SOM §11.9.8, §11.9.10); "" when there is nothing to write.
func formatAttributionToken(authors []string, votes []SpecMarkVote, changedAt string) string {
	parts := make([]string, 0, len(votes)+2)
	if len(authors) > 0 {
		parts = append(parts, strings.Join(authors, ","))
	}
	for _, x := range votes {
		sign := "-"
		if x.Vote == SpecMarkDecisionAccept {
			sign = "+"
		}
		parts = append(parts, sign+x.Member)
	}
	if changedAt != "" {
		parts = append(parts, changedAt)
	}
	if len(parts) == 0 {
		return ""
	}
	return "{@" + strings.Join(parts, " ") + "}"
}

// withAttribution is value with mark m's token replaced by one for authors
// and votes; its change time stays.
func withAttribution(value string, m reviewMark, authors []string, votes []SpecMarkVote) string {
	return value[:m.bodyEnd] + formatAttributionToken(authors, votes, m.changedAt) + value[m.end:]
}

// reviewTeamAnswers are the team answer of every question of value, by id
// (the first question with an id wins), with the ids in order.
func reviewTeamAnswers(value string) (map[string]string, []string) {
	out := map[string]string{}
	var order []string
	for _, b := range annParse(value).blocks {
		for _, q := range b.questions {
			if _, ok := out[q.id]; !ok {
				out[q.id] = q.answer
				order = append(order, q.id)
			}
		}
	}
	return out, order
}

// reviewTeamAnswerTimes are the times of the team answer of every question of
// value, by id (SOM §11.9.10): the first question with that id; nil for an
// answer written without one.
func reviewTeamAnswerTimes(value string) map[string]*string {
	out := map[string]*string{}
	for _, b := range annParse(value).blocks {
		for _, q := range b.questions {
			if _, ok := out[q.id]; !ok {
				out[q.id] = q.answerChangedAt
			}
		}
	}
	return out
}

// setIndividualAnswerText is value with member's individual answer to
// question questionID set, as SetAnswer with an author does, with changedAt
// ("" for none) as its change time; ok=false when the value holds no such
// question.
func setIndividualAnswerText(value, questionID, member, answer, changedAt string) (string, bool) {
	for _, b := range annParse(value).blocks {
		for _, q := range b.questions {
			if q.id == questionID {
				return annSetIndividualAnswer(value, q, member, answer, changedAt), true
			}
		}
	}
	return "", false
}

// annAlternativeLines are the lines of a conflict's text: the first after its
// prefix, the rest indented under it.
func annAlternativeLines(prefix, text string) []string {
	t := strings.Split(text, "\n")
	out := []string{strings.TrimRightFunc("> - "+prefix+" "+t[0], unicode.IsSpace)}
	for _, l := range t[1:] {
		out = append(out, ">   "+l)
	}
	return out
}

// FormatConflictBlock returns the lines of a conflict block (SOM §11.9.8):
// the header, the `(base)` line, one lettered alternative per entry naming its
// members, and an empty `**Decision:**`. A text's further lines are indented
// under it, so a reader gets them back with their line breaks.
func FormatConflictBlock(id, topic, text, base string, alternatives []SpecConflictAlternative) []string {
	lines := []string{strings.TrimRightFunc("> "+annScales+annVS16+" **"+id+annEmDashSep+topic+":** "+text,
		unicode.IsSpace)}
	lines = append(lines, annAlternativeLines("(base)", base)...)
	for _, a := range alternatives {
		lines = append(lines, annAlternativeLines("("+a.Letter+") **"+strings.Join(a.Members, ", ")+":**", a.Text)...)
	}
	return append(lines, ">", "> "+annDecisionLabel)
}

// transplantEdits carries the edits x → y over to b, a text equal to x except
// where marks of b were decided in x (SOM §11.9.9, step 3): every edit lands
// in b at the place x and b agree on. ok=false when an edit touches a place
// where they differ — the edit overlaps a decided mark. Both diffs are the
// token diffs of MarkChangeText.
func transplantEdits(x, y, b string) (string, bool) {
	xt := annTokens(x)
	bt := annTokens(b)
	// Where each token of x is in b (-1: x and b differ there).
	toB := make([]int, len(xt))
	for k := range toB {
		toB[k] = -1
	}
	i, j := 0, 0
	for _, op := range annDiff(xt, bt) {
		switch op.kind {
		case 0:
			toB[i] = j
			i++
			j++
		case 1:
			i++
		default:
			j++
		}
	}
	// The edits x → y as [first x token, end x token, inserted text].
	type hunk struct {
		x0, x1 int
		ins    string
	}
	var hunks []hunk
	var open *hunk
	i = 0
	for _, op := range annDiff(xt, annTokens(y)) {
		if op.kind == 0 {
			if open != nil {
				hunks = append(hunks, *open)
			}
			open = nil
			i++
			continue
		}
		if open == nil {
			open = &hunk{x0: i, x1: i}
		}
		if op.kind == 1 {
			i++
			open.x1 = i
		} else {
			open.ins += op.tok.text
		}
	}
	if open != nil {
		hunks = append(hunks, *open)
	}
	out := make([]string, len(bt))
	for k, t := range bt {
		out[k] = t.text
	}
	for h := len(hunks) - 1; h >= 0; h-- {
		from, to, ok := annLanding(toB, hunks[h].x0, hunks[h].x1, len(bt))
		if !ok {
			return "", false
		}
		out = append(append(append([]string{}, out[:from]...), hunks[h].ins), out[to:]...)
	}
	return strings.Join(out, ""), true
}

// annLanding is the b-token range [from, to) an x-token range [x0, x1) lands
// on, or ok=false when it is not one.
//
// A replaced range lands where its tokens are in b, which must be contiguous
// there; its neighbours are not consulted, because the token diff may align a
// neighbouring space with another space of b (beside a decided mark) without
// the range touching that mark. A pure insertion (x0 == x1) has no tokens of
// its own, so both neighbours must sit next to each other in b.
func annLanding(toB []int, x0, x1, bLength int) (from, to int, ok bool) {
	for k := x0; k < x1; k++ {
		if toB[k] < 0 || (k > x0 && toB[k] != toB[k-1]+1) {
			return 0, 0, false
		}
	}
	if x1 > x0 {
		return toB[x0], toB[x1-1] + 1, true
	}
	left := -1
	if x0 > 0 {
		left = toB[x0-1]
	}
	right := bLength
	if x1 < len(toB) {
		right = toB[x1]
	}
	if (x0 > 0 && left < 0) || (x1 < len(toB) && right < 0) {
		return 0, 0, false
	}
	if left+1 != right {
		return 0, 0, false
	}
	return left + 1, left + 1, true
}
