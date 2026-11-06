package somruntime

// spec_review_merge.go — merging the reviewed copies of a team review (SOM
// §11.9.9) into one document in the team notation of §11.9.8: who proposed,
// voted for and answered what, and where two members changed the same passage
// differently. A port of `tom_som_typescript_runtime/src/spec_review_merge.ts`.
//
// MergeReviews merges a SOM document (by model path, list items matched by
// section id), MergeMarkdownReviews a plain annotated Markdown file (by
// heading path). Both share one engine that works value by value; only the way
// values are found, and the SOM-only structure and revision entry, differ.
//
// The engine is built on the review-annotation building blocks of
// spec_review_annotations.go: the paragraph split and the mark decisions,
// MarkChangeText for edits written as plain text, the individual-answer rules
// of SetAnswer, and the list-item id generation of GenerateListItemSectionID.

import (
	"encoding/json"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// ---------------------------------------------------------------------------
// Inputs, report and result.
// ---------------------------------------------------------------------------

// SpecReviewMember is a member of a review team (SOM §11.9.8).
type SpecReviewMember struct {
	// MemberID is the member id: lowercase letters, digits and `_`.
	MemberID    string
	DisplayName string
	Role        string
}

// SpecReviewedCopy is one returned copy: its reviewer and the copy's
// document — a *SpecDocument for MergeReviews, the Markdown text for
// MergeMarkdownReviews.
type SpecReviewedCopy[D any] struct {
	SpecReviewMember
	Document D
}

// SpecReviewMergeOptions are the options of a merge.
type SpecReviewMergeOptions struct {
	// Team are the members the round started with, in team order; a copy of
	// anybody else is a guest's.
	Team []SpecReviewMember
	// Date is the round's date (ISO 8601): the revision entry's date, and the
	// date of every generated list-item id.
	Date string
	// Author is the revision entry's author.
	Author string
	// QuestionPrefix is the id prefix of the questions the merge writes; ""
	// for the default `RQ`.
	QuestionPrefix string
}

// SpecReviewMergeError is returned when a copy's structure does not fit the
// base; nothing is merged.
type SpecReviewMergeError struct {
	Message string
}

func (e *SpecReviewMergeError) Error() string {
	return "SpecReviewMergeError: " + e.Message
}

// SpecMergeReviewer is a reviewer as the report lists it.
type SpecMergeReviewer struct {
	SpecReviewMember
	Guest bool
}

// SpecMergeConflict is a conflict block the merge wrote.
type SpecMergeConflict struct {
	ID    string
	Path  string
	Field *string
	// Paragraph is the unit's index among the value's text paragraphs; nil
	// for a whole value or a structural conflict.
	Paragraph *int
	Members   []string
}

// SpecMergeVotes is a base mark left with votes.
type SpecMergeVotes struct {
	Path  string
	Field *string
	// Markup is the mark as merged, its token carrying the votes.
	Markup string
	Votes  []SpecMarkVote
}

// SpecMergeUnanimous is a base mark every copy decided the same way, applied
// or dropped.
type SpecMergeUnanimous struct {
	Path  string
	Field *string
	// Markup is the mark as the base wrote it.
	Markup   string
	Decision SpecMarkDecision
	Result   string
}

// SpecMergeAnswers is a base question the copies answered.
type SpecMergeAnswers struct {
	QuestionID string
	Members    []string
}

// SpecMergeComment is a new comment.
type SpecMergeComment struct {
	ID     string
	Author string
	Path   string
	Field  *string
}

// SpecMergeAddition is an item a copy added.
type SpecMergeAddition struct {
	Path    string
	Members []string
}

// SpecMergeGuestQuestion is the question proposing a guest for the next
// round's team.
type SpecMergeGuestQuestion struct {
	ID       string
	MemberID string
	// Path is where it was written; nil when the document has no place for
	// it.
	Path *string
}

// SpecMergeRevision is the draft revision entry the merge appended.
type SpecMergeRevision struct {
	Path    string
	Version string
}

// SpecReviewMergeReport is the merge report (SOM §11.9.9), every list in
// merged document order.
type SpecReviewMergeReport struct {
	Reviewers      []SpecMergeReviewer
	Conflicts      []SpecMergeConflict
	Votes          []SpecMergeVotes
	Unanimous      []SpecMergeUnanimous
	Answers        []SpecMergeAnswers
	Comments       []SpecMergeComment
	Additions      []SpecMergeAddition
	GuestQuestions []SpecMergeGuestQuestion
	// Revision is the draft revision entry, or nil.
	Revision *SpecMergeRevision
}

func nullableInt(n *int) any {
	if n == nil {
		return nil
	}
	return *n
}

// ToJSON is the canonical JSON form the conformance corpus pins.
func (r *SpecReviewMergeReport) ToJSON() map[string]any {
	reviewers := []any{}
	for _, x := range r.Reviewers {
		reviewers = append(reviewers, map[string]any{
			"memberId": x.MemberID, "displayName": x.DisplayName, "role": x.Role, "guest": x.Guest,
		})
	}
	conflicts := []any{}
	for _, x := range r.Conflicts {
		conflicts = append(conflicts, map[string]any{
			"id": x.ID, "path": x.Path, "field": nullableString(x.Field),
			"paragraph": nullableInt(x.Paragraph), "members": annStringsJSON(x.Members),
		})
	}
	votes := []any{}
	for _, x := range r.Votes {
		votes = append(votes, map[string]any{
			"path": x.Path, "field": nullableString(x.Field), "markup": x.Markup, "votes": annVotesJSON(x.Votes),
		})
	}
	unanimous := []any{}
	for _, x := range r.Unanimous {
		unanimous = append(unanimous, map[string]any{
			"path": x.Path, "field": nullableString(x.Field), "markup": x.Markup,
			"decision": string(x.Decision), "result": x.Result,
		})
	}
	answers := []any{}
	for _, x := range r.Answers {
		answers = append(answers, map[string]any{"questionId": x.QuestionID, "members": annStringsJSON(x.Members)})
	}
	comments := []any{}
	for _, x := range r.Comments {
		comments = append(comments, map[string]any{
			"id": x.ID, "author": x.Author, "path": x.Path, "field": nullableString(x.Field),
		})
	}
	additions := []any{}
	for _, x := range r.Additions {
		additions = append(additions, map[string]any{"path": x.Path, "members": annStringsJSON(x.Members)})
	}
	guests := []any{}
	for _, x := range r.GuestQuestions {
		guests = append(guests, map[string]any{"id": x.ID, "memberId": x.MemberID, "path": nullableString(x.Path)})
	}
	var revision any
	if r.Revision != nil {
		revision = map[string]any{"path": r.Revision.Path, "version": r.Revision.Version}
	}
	return map[string]any{
		"reviewers":      reviewers,
		"conflicts":      conflicts,
		"votes":          votes,
		"unanimous":      unanimous,
		"answers":        answers,
		"comments":       comments,
		"additions":      additions,
		"guestQuestions": guests,
		"revision":       revision,
	}
}

// SpecReviewMergeResult is the merged document and its report.
type SpecReviewMergeResult[D any] struct {
	Merged D
	Report *SpecReviewMergeReport
}

// MergeReviews merges the reviewed copies of the SOM document base (SOM
// §11.9.9), by model path, list items matched by section id. Neither the base
// nor a copy is written. A copy whose structure does not fit the base — a path
// the model does not resolve — is refused with a *SpecReviewMergeError.
func MergeReviews(model *SpecModel, base *SpecDocument, copies []SpecReviewedCopy[*SpecDocument],
	options SpecReviewMergeOptions) (*SpecReviewMergeResult[*SpecDocument], error) {
	return mergeSom(model, base, copies, options)
}

// MergeMarkdownReviews merges the reviewed copies of the plain annotated
// Markdown text base (SOM §11.9.9), by heading path. A copy whose heading
// sequence differs from the base's is refused with a *SpecReviewMergeError.
func MergeMarkdownReviews(base string, copies []SpecReviewedCopy[string],
	options SpecReviewMergeOptions) (*SpecReviewMergeResult[string], error) {
	return mergeMarkdown(base, copies, options)
}

// ---------------------------------------------------------------------------
// The engine: one value at a time.
// ---------------------------------------------------------------------------

// mergePlaceholderRE matches the ids the merge writes before it can number
// them: renumbered in merged document order at the end.
var mergePlaceholderRE = regexp.MustCompile("\x01([CX])([0-9]+)\x01")

// mergeValue is one value to merge, located in the merged document.
type mergeValue struct {
	// key is the value's key in the merged texts.
	key   string
	path  string
	field string // "" for content
	base  string
	// copies are per copy, in round order; nil when the copy holds no such
	// value (it removed the item).
	copies []*string
	// typed is a typed leaf (number, bool, enum, code): never marked, any
	// change is a conflict.
	typed bool
	// conflictHome is where a conflict about a form field or a typed leaf
	// goes (a key of the merged texts); "" for a content value.
	conflictHome string
}

// mergeUnitReading is what one copy did to one unit (SOM §11.9.9, steps 1–4).
type mergeUnitReading struct {
	changed bool
	// t is the reviewer's text.
	t string
	// written is the change as it is written into the merged document.
	written string
	// votes are the copy's votes, by the index of the base unit's mark (true
	// accepts).
	votes map[int]bool
}

// mergeGroup is the copies that made one change, in order of first
// appearance.
type mergeGroup struct {
	text    string
	members []string
	first   *mergeUnitReading
}

// mergeContext is the state one merge carries from value to value.
type mergeContext struct {
	report *SpecReviewMergeReport
	// appends are the blocks to append to the end of a value, by its key, in
	// the order the keys were first appended to.
	appends     map[string][]string
	appendOrder []string
	members     []string
	next        int
	// pendingConflicts and pendingComments map a placeholder to its report
	// entry, filled in when the ids are numbered.
	pendingConflicts map[string]SpecMergeConflict
	pendingComments  map[string]SpecMergeComment
	baseCommentIDs   map[string]bool
	baseQuestionIDs  map[string]bool
}

func newMergeContext(copies []SpecReviewMember, comments, questions map[string]bool) *mergeContext {
	ctx := &mergeContext{
		report:           &SpecReviewMergeReport{},
		appends:          map[string][]string{},
		pendingConflicts: map[string]SpecMergeConflict{},
		pendingComments:  map[string]SpecMergeComment{},
		baseCommentIDs:   comments,
		baseQuestionIDs:  questions,
	}
	for _, c := range copies {
		ctx.members = append(ctx.members, c.MemberID)
	}
	return ctx
}

func (ctx *mergeContext) placeholder(kind string) string {
	ctx.next++
	return "\x01" + kind + strconv.Itoa(ctx.next) + "\x01"
}

func (ctx *mergeContext) appendBlock(key, block string) {
	if _, ok := ctx.appends[key]; !ok {
		ctx.appendOrder = append(ctx.appendOrder, key)
	}
	ctx.appends[key] = append(ctx.appends[key], block)
}

// conflict writes a conflict block with a placeholder id and records it for
// the report.
func (ctx *mergeContext) conflict(topic, text, base string, groups []mergeGroup, path, field string,
	paragraph *int) string {
	id := ctx.placeholder("X")
	var members []string
	alternatives := make([]SpecConflictAlternative, 0, len(groups))
	for k, g := range groups {
		members = append(members, g.members...)
		alternatives = append(alternatives, SpecConflictAlternative{
			Letter: string(rune('a' + k)), Members: g.members, Text: g.text,
		})
	}
	ctx.pendingConflicts[id] = SpecMergeConflict{
		ID: id, Path: path, Field: annFieldPtr(field), Paragraph: paragraph, Members: members,
	}
	return strings.Join(FormatConflictBlock(id, topic, text, base, alternatives), "\n")
}

// mergeChangeGroups groups the changed readings by their text t, in order of
// first appearance.
func mergeChangeGroups(readings []*mergeUnitReading, members []string) []mergeGroup {
	var groups []mergeGroup
	for k, r := range readings {
		if r == nil || !r.changed {
			continue
		}
		found := false
		for g := range groups {
			if groups[g].text == r.t {
				groups[g].members = append(groups[g].members, members[k])
				found = true
				break
			}
		}
		if !found {
			groups = append(groups, mergeGroup{text: r.t, members: []string{members[k]}, first: r})
		}
	}
	return groups
}

// mergeLCS is the longest-common-subsequence alignment of two sequences
// under eq: index in a → index in b.
func mergeLCS(n, m int, eq func(i, j int) bool) map[int]int {
	l := make([][]int, n+1)
	for i := range l {
		l[i] = make([]int, m+1)
	}
	for i := n - 1; i >= 0; i-- {
		for j := m - 1; j >= 0; j-- {
			if eq(i, j) {
				l[i][j] = l[i+1][j+1] + 1
			} else if l[i+1][j] >= l[i][j+1] {
				l[i][j] = l[i+1][j]
			} else {
				l[i][j] = l[i][j+1]
			}
		}
	}
	out := map[int]int{}
	i, j := 0, 0
	for i < n && j < m {
		switch {
		case eq(i, j):
			out[i] = j
			i++
			j++
		case l[i+1][j] >= l[i][j+1]:
			i++
		default:
			j++
		}
	}
	return out
}

// mergeAlignMarks aligns two mark lists by their markup: index in a → index
// in b.
func mergeAlignMarks(a, b []reviewMark) map[int]int {
	return mergeLCS(len(a), len(b), func(i, j int) bool { return a[i].markup == b[j].markup })
}

// mergeMaxDecidedMarks is the most base marks a unit may have that a copy no
// longer holds as written: the combinations of step 2 grow as 2^n. Beyond it
// the copy's unit is read as an edit (step 4), so every runtime gives up at the
// same point.
const mergeMaxDecidedMarks = 16

// mergeFindVotes is the first combination of decisions on b's marks (step 2)
// whose result is target, or nil. Each mark takes leave, accept, reject in
// that order, the first mark varying slowest. A mark the copy still holds as
// written can only have been left, and a mark it no longer holds cannot have
// been, so only the others vary — the same first combination, found without
// trying the rest.
func mergeFindVotes(b string, marks []reviewMark, left map[int]bool, target string) map[int]bool {
	var free []int
	for i := range marks {
		if !left[i] {
			free = append(free, i)
		}
	}
	if len(free) > mergeMaxDecidedMarks {
		return nil
	}
	for combo := 0; combo < 1<<len(free); combo++ {
		decisions := map[int]bool{}
		for k, mark := range free {
			// Bit set: reject; the first mark is the most significant bit.
			decisions[mark] = (combo>>(len(free)-1-k))&1 == 0
		}
		if decideReviewMarks(b, decisions) == target {
			return decisions
		}
	}
	return nil
}

// mergeReadAsEdit is step 4: the copy edited text that holds base marks; it
// casts no votes.
func mergeReadAsEdit(b, c string) *mergeUnitReading {
	t := ApplyInlineMarksText(c, true)
	return &mergeUnitReading{
		changed: t != b,
		t:       t,
		written: MarkChangeText(ApplyInlineMarksText(b, false), t).Text,
		votes:   map[int]bool{},
	}
}

// mergeReadUnit is what copy unit c did to base unit b (SOM §11.9.9, steps
// 1–4).
func mergeReadUnit(b, c string) *mergeUnitReading {
	if c == b {
		return &mergeUnitReading{t: b, written: b, votes: map[int]bool{}}
	}
	baseMarks := reviewMarks(b)
	copyMarks := reviewMarks(c)
	kept := mergeAlignMarks(copyMarks, baseMarks)
	// 1. Own marks: the copy's marks that are not the base's.
	reject := map[int]bool{}
	accept := map[int]bool{}
	for i := range copyMarks {
		if _, ok := kept[i]; !ok {
			reject[i] = false
			accept[i] = true
		}
	}
	// 2. Votes: the decisions on the base marks that give c with its own
	// marks rejected.
	cPrime := decideReviewMarks(c, reject)
	left := map[int]bool{}
	for _, j := range kept {
		left[j] = true
	}
	votes := mergeFindVotes(b, baseMarks, left, cPrime)
	if votes == nil {
		return mergeReadAsEdit(b, c)
	}
	if len(reject) == 0 {
		return &mergeUnitReading{t: b, written: b, votes: votes}
	}
	// 3. Change: the own marks, carried over to the base text where marks
	// were voted on.
	ownAccepted := decideReviewMarks(c, accept)
	written, t := c, ownAccepted
	if len(votes) > 0 {
		var okW, okT bool
		written, okW = transplantEdits(cPrime, c, b)
		t, okT = transplantEdits(cPrime, ownAccepted, b)
		if !okW || !okT {
			return mergeReadAsEdit(b, c)
		}
	}
	return &mergeUnitReading{changed: t != b, t: t, written: written, votes: votes}
}

// mergeAttribute is written with every mark that is not one of the base's
// attributed to members.
func mergeAttribute(written string, baseMarks []reviewMark, members []string) string {
	marks := reviewMarks(written)
	base := mergeAlignMarks(marks, baseMarks)
	out := written
	for k := len(marks) - 1; k >= 0; k-- {
		if _, ok := base[k]; !ok {
			out = withAttribution(out, marks[k], members, marks[k].votes)
		}
	}
	return out
}

// mergeApplyVotes is text with the copies' votes on the base marks it holds:
// a base mark every copy decided the same way is applied (accept) or dropped
// (reject); any other voted change mark gets the votes in its token, `agent`
// as author when it had no token. A highlight or comment mark takes no votes
// and stays.
func mergeApplyVotes(text string, baseMarks []reviewMark, readings []*mergeUnitReading, v *mergeValue,
	ctx *mergeContext) string {
	marks := reviewMarks(text)
	base := mergeAlignMarks(marks, baseMarks)
	taking := 0
	for _, r := range readings {
		if r != nil {
			taking++
		}
	}
	var votes []SpecMergeVotes
	var unanimous []SpecMergeUnanimous
	out := text
	for k := len(marks) - 1; k >= 0; k-- {
		b, ok := base[k]
		if !ok {
			continue
		}
		var cast []SpecMarkVote
		for i, r := range readings {
			if r == nil {
				continue
			}
			if d, has := r.votes[b]; has {
				vote := SpecMarkDecisionReject
				if d {
					vote = SpecMarkDecisionAccept
				}
				cast = append(cast, SpecMarkVote{Member: ctx.members[i], Vote: vote})
			}
		}
		if len(cast) == 0 {
			continue
		}
		m := marks[k]
		if len(cast) == taking && mergeAllSame(cast) {
			accept := cast[0].Vote == SpecMarkDecisionAccept
			out = decideReviewMarks(out, map[int]bool{k: accept})
			result := baseMarks[b].rejected
			if accept {
				result = baseMarks[b].accepted
			}
			unanimous = append([]SpecMergeUnanimous{{
				Path: v.path, Field: annFieldPtr(v.field), Markup: baseMarks[b].markup,
				Decision: cast[0].Vote, Result: result,
			}}, unanimous...)
			continue
		}
		if !annIsChangeMark(m.kind) {
			continue
		}
		authors := []string{"agent"}
		if m.end > m.bodyEnd {
			authors = m.authors
		}
		var merged []SpecMarkVote
		for _, x := range m.votes {
			if !mergeVotedBy(cast, x.Member) {
				merged = append(merged, x)
			}
		}
		merged = append(merged, cast...)
		out = withAttribution(out, m, authors, merged)
		votes = append([]SpecMergeVotes{{
			Path: v.path, Field: annFieldPtr(v.field), Markup: reviewMarks(out)[k].markup, Votes: merged,
		}}, votes...)
	}
	ctx.report.Votes = append(ctx.report.Votes, votes...)
	ctx.report.Unanimous = append(ctx.report.Unanimous, unanimous...)
	return out
}

func mergeAllSame(cast []SpecMarkVote) bool {
	for _, x := range cast {
		if x.Vote != cast[0].Vote {
			return false
		}
	}
	return true
}

func mergeVotedBy(cast []SpecMarkVote, member string) bool {
	for _, y := range cast {
		if y.Member == member {
			return true
		}
	}
	return false
}

// mergeFieldSuffix is ` <field>` for a form field, "" for content: how a
// conflict's text names a value.
func mergeFieldSuffix(field string) string {
	if field == "" {
		return ""
	}
	return " " + field
}

// mergeUnit merges one unit: the base text with votes when no copy changed
// it, the one change attributed to every member who made it, or the base text
// and a conflict block ("" when none) when the copies changed it differently.
func mergeUnit(b string, units []*string, paragraph *int, v *mergeValue, ctx *mergeContext) (string, string) {
	readings := make([]*mergeUnitReading, len(units))
	for i, c := range units {
		if c != nil {
			readings[i] = mergeReadUnit(b, *c)
		}
	}
	groups := mergeChangeGroups(readings, ctx.members)
	baseMarks := reviewMarks(b)
	text := b
	if len(groups) == 1 {
		text = mergeAttribute(groups[0].first.written, baseMarks, groups[0].members)
	}
	text = mergeApplyVotes(text, baseMarks, readings, v, ctx)
	if len(groups) < 2 {
		return text, ""
	}
	where := v.path + mergeFieldSuffix(v.field)
	if paragraph != nil {
		where += ", paragraph " + strconv.Itoa(*paragraph)
	}
	return text, ctx.conflict("Conflicting changes", where, b, groups, v.path, v.field, paragraph)
}

// mergeTyped merges a typed leaf: it cannot hold a mark, so a change by any
// copy is a `Value changed` conflict at the leaf's home, the base value kept.
func mergeTyped(v *mergeValue, ctx *mergeContext) string {
	readings := make([]*mergeUnitReading, len(v.copies))
	for i, c := range v.copies {
		if c != nil {
			readings[i] = &mergeUnitReading{changed: *c != v.base, t: *c, written: *c, votes: map[int]bool{}}
		}
	}
	groups := mergeChangeGroups(readings, ctx.members)
	if len(groups) > 0 && v.conflictHome != "" {
		ctx.appendBlock(v.conflictHome, ctx.conflict("Value changed", v.path+mergeFieldSuffix(v.field), v.base,
			groups, v.path, v.field, nil))
	}
	return v.base
}

// mergeField merges a form-field value: always one unit; its conflict goes to
// the end of the form's preamble.
func mergeField(v *mergeValue, ctx *mergeContext) string {
	text, conflict := mergeUnit(v.base, v.copies, nil, v, ctx)
	if conflict != "" && v.conflictHome != "" {
		ctx.appendBlock(v.conflictHome, conflict)
	}
	return text
}

// mergeIsNewBlock reports whether a copy's block is new: a comment whose id
// the base lacks, a question block with no base question.
func mergeIsNewBlock(piece reviewPiece, ctx *mergeContext) bool {
	switch piece.kind {
	case string(SpecReviewAnnotationKindComment):
		return piece.id == nil || !ctx.baseCommentIDs[*piece.id]
	case string(SpecReviewAnnotationKindQuestion):
		if len(piece.questionIDs) == 0 {
			return false
		}
		for _, id := range piece.questionIDs {
			if ctx.baseQuestionIDs[id] {
				return false
			}
		}
		return true
	}
	return false
}

// mergeAnchors is the anchor of each block of a value: the index of the text
// paragraph it follows (-1: before every one). In whole-value mode every block
// that follows text follows the one unit.
func mergeAnchors(pieces []reviewPiece, whole bool) []int {
	texts := -1
	out := make([]int, len(pieces))
	for k, p := range pieces {
		if p.kind == reviewPieceText {
			texts++
			out[k] = texts
			continue
		}
		if whole && texts > 0 {
			out[k] = 0
		} else {
			out[k] = texts
		}
	}
	return out
}

func mergeTextsOf(pieces []reviewPiece) []string {
	var out []string
	for _, p := range pieces {
		if p.kind == reviewPieceText {
			out = append(out, p.text)
		}
	}
	return out
}

// mergeContent merges a content value: split into text paragraphs and
// annotation blocks, merged unit by unit, the copies' new comments and
// questions placed after the unit they followed. A copy whose text-paragraph
// count differs from the base's makes the whole text one unit, for every copy.
func mergeContent(v *mergeValue, ctx *mergeContext) string {
	basePieces := reviewPieces(v.base)
	copyPieces := make([][]reviewPiece, len(v.copies))
	baseTexts := mergeTextsOf(basePieces)
	whole := false
	for i, c := range v.copies {
		if c == nil {
			continue
		}
		copyPieces[i] = reviewPieces(*c)
		if len(mergeTextsOf(copyPieces[i])) != len(baseTexts) {
			whole = true
		}
	}
	unitsOf := func(ps []reviewPiece) []string {
		if whole {
			return []string{strings.Join(mergeTextsOf(ps), "\n\n")}
		}
		return mergeTextsOf(ps)
	}
	baseUnits := unitsOf(basePieces)

	// Blocks by anchor: the base's first, then each copy's new ones in round
	// order.
	after := map[int][]string{}
	baseAnchors := mergeAnchors(basePieces, whole)
	for k, p := range basePieces {
		if p.kind != reviewPieceText {
			after[baseAnchors[k]] = append(after[baseAnchors[k]], p.text)
		}
	}
	for i, ps := range copyPieces {
		if v.copies[i] == nil {
			continue
		}
		anchors := mergeAnchors(ps, false)
		for k, p := range ps {
			if p.kind == reviewPieceText || !mergeIsNewBlock(p, ctx) {
				continue
			}
			anchor := anchors[k]
			if whole {
				anchor = len(baseUnits) - 1
			}
			after[anchor] = append(after[anchor], mergeNewBlock(p, ctx.members[i], v, ctx))
		}
	}

	out := append([]string{}, after[-1]...)
	for u, b := range baseUnits {
		units := make([]*string, len(v.copies))
		for i := range v.copies {
			if v.copies[i] == nil {
				continue
			}
			cu := unitsOf(copyPieces[i])
			units[i] = &cu[u]
		}
		var paragraph *int
		if !whole {
			n := u
			paragraph = &n
		}
		text, conflict := mergeUnit(b, units, paragraph, v, ctx)
		if text != "" {
			out = append(out, text)
		}
		if conflict != "" {
			out = append(out, conflict)
		}
		out = append(out, after[u]...)
	}
	return strings.Join(out, "\n\n")
}

// mergeNewBlock is a copy's new block as merged: a comment renumbered and
// attributed, a question as written.
func mergeNewBlock(p reviewPiece, member string, v *mergeValue, ctx *mergeContext) string {
	if p.kind != string(SpecReviewAnnotationKindComment) {
		return p.text
	}
	id := ctx.placeholder("C")
	author := member
	if p.author != nil {
		author = *p.author
	}
	ctx.pendingComments[id] = SpecMergeComment{ID: id, Author: author, Path: v.path, Field: annFieldPtr(v.field)}
	return strings.Join(FormatCommentBlock(id, p.commentText, author), "\n")
}

// mergeOneValue merges one value; the base text when no copy differs from it.
func mergeOneValue(v *mergeValue, ctx *mergeContext) string {
	differs := false
	for _, c := range v.copies {
		if c != nil && *c != v.base {
			differs = true
		}
	}
	switch {
	case !differs:
		return v.base
	case v.typed:
		return mergeTyped(v, ctx)
	case v.field != "":
		return mergeField(v, ctx)
	default:
		return mergeContent(v, ctx)
	}
}

// ---------------------------------------------------------------------------
// Shared phases over the merged texts.
// ---------------------------------------------------------------------------

// mergeTexts are the merged document's values, by key, in merged document
// order.
type mergeTexts interface {
	keys() []string
	get(key string) string
	set(key, value string)
}

// mergeJoinBlocks is value with blocks appended, one blank line between.
func mergeJoinBlocks(value string, blocks ...string) string {
	var parts []string
	if value != "" {
		parts = append(parts, value)
	}
	return strings.Join(append(parts, blocks...), "\n\n")
}

// mergeApplyAppends appends the collected blocks (field and structural
// conflicts) to the end of their values.
func mergeApplyAppends(texts mergeTexts, ctx *mergeContext) {
	for _, key := range ctx.appendOrder {
		texts.set(key, mergeJoinBlocks(texts.get(key), ctx.appends[key]...))
	}
}

// mergeLeadingNumber is the number at the start of s, like JavaScript's
// parseInt; ok=false when s starts with no digit.
func mergeLeadingNumber(s string) (int, bool) {
	k := 0
	for k < len(s) && s[k] >= '0' && s[k] <= '9' {
		k++
	}
	if k == 0 {
		return 0, false
	}
	n, err := strconv.Atoi(s[:k])
	return n, err == nil
}

// mergeHighestID is the highest `<prefix>-<n>` among the annotations of texts
// of the given kinds.
func mergeHighestID(texts []string, prefix string, kinds ...SpecReviewAnnotationKind) int {
	high := 0
	for _, t := range texts {
		for _, p := range reviewPieces(t) {
			match := false
			for _, k := range kinds {
				if p.kind == string(k) {
					match = true
				}
			}
			if !match {
				continue
			}
			ids := p.questionIDs
			if p.kind != string(SpecReviewAnnotationKindQuestion) {
				ids = nil
				if p.id != nil {
					ids = []string{*p.id}
				}
			}
			for _, id := range ids {
				if !strings.HasPrefix(id, prefix+"-") {
					continue
				}
				if n, ok := mergeLeadingNumber(id[len(prefix)+1:]); ok && n > high {
					high = n
				}
			}
		}
	}
	return high
}

// mergeNumberIDs numbers the new comments and conflicts in merged document
// order, above the base's highest `C-<n>` and `X-<n>`, and fills their report
// entries in.
func mergeNumberIDs(texts mergeTexts, baseTexts []string, ctx *mergeContext) {
	next := map[string]int{
		"C": mergeHighestID(baseTexts, "C", SpecReviewAnnotationKindComment),
		"X": mergeHighestID(baseTexts, "X", SpecReviewAnnotationKindConflict),
	}
	for _, key := range texts.keys() {
		value := texts.get(key)
		if !strings.Contains(value, "\x01") {
			continue
		}
		texts.set(key, mergePlaceholderRE.ReplaceAllStringFunc(value, func(placeholder string) string {
			kind := placeholder[1:2]
			next[kind]++
			id := kind + "-" + strconv.Itoa(next[kind])
			if kind == "C" {
				c := ctx.pendingComments[placeholder]
				c.ID = id
				ctx.report.Comments = append(ctx.report.Comments, c)
			} else {
				c := ctx.pendingConflicts[placeholder]
				c.ID = id
				ctx.report.Conflicts = append(ctx.report.Conflicts, c)
			}
			return id
		}))
	}
}

// mergeTeamAnswers are the team answers of every question of texts, by id
// (the first wins), with the ids in order.
func mergeTeamAnswers(texts []string) (map[string]string, []string) {
	out := map[string]string{}
	var order []string
	for _, t := range texts {
		answers, ids := reviewTeamAnswers(t)
		for _, id := range ids {
			if _, ok := out[id]; !ok {
				out[id] = answers[id]
				order = append(order, id)
			}
		}
	}
	return out, order
}

// mergeAnswers writes each copy's team answer to a base question, where it
// differs from the base's, as that member's individual answer (copies in
// round order).
func mergeAnswers(texts mergeTexts, baseTexts []string, copyTexts [][]string, ctx *mergeContext) {
	baseAnswers, order := mergeTeamAnswers(baseTexts)
	copyAnswers := make([]map[string]string, len(copyTexts))
	for i, ts := range copyTexts {
		copyAnswers[i], _ = mergeTeamAnswers(ts)
	}
	for _, id := range order {
		var members []string
		for i, answers := range copyAnswers {
			a, ok := answers[id]
			if !ok || a == baseAnswers[id] || a == "" {
				continue
			}
			for _, key := range texts.keys() {
				written, found := setIndividualAnswerText(texts.get(key), id, ctx.members[i], a)
				if !found {
					continue
				}
				texts.set(key, written)
				members = append(members, ctx.members[i])
				break
			}
		}
		if len(members) > 0 {
			ctx.report.Answers = append(ctx.report.Answers, SpecMergeAnswers{QuestionID: id, Members: members})
		}
	}
}

// mergeGuestQuestion is the question proposing guest g for the next round's
// team.
func mergeGuestQuestion(id string, g SpecReviewMember) string {
	who := g.DisplayName
	if g.Role != "" {
		who += ", " + g.Role
	}
	return strings.Join(FormatQuestionBlock(SpecQuestionDraft{
		ID:          id,
		Topic:       "Guest " + g.MemberID,
		Text:        "add " + g.MemberID + " (" + who + ") to the review team?",
		Options:     []string{"(a) yes, from the next round on", "(b) no, this round only"},
		Recommended: "a",
	}), "\n")
}

// mergeHome is where the guest questions go: a key of the merged texts and
// the path the report names.
type mergeHome struct {
	key, path string
}

// mergeAddGuests lists the reviewers and writes one question per guest to the
// end of the value at home (nil: the report only), numbered above the base's
// highest question id with the prefix.
func mergeAddGuests(texts mergeTexts, baseTexts []string, copies []SpecReviewMember,
	options SpecReviewMergeOptions, home *mergeHome, ctx *mergeContext) {
	team := mergeTeamIDs(options)
	prefix := options.QuestionPrefix
	if prefix == "" {
		prefix = "RQ"
	}
	n := mergeHighestID(baseTexts, prefix, SpecReviewAnnotationKindQuestion)
	for _, c := range copies {
		guest := !team[c.MemberID]
		ctx.report.Reviewers = append(ctx.report.Reviewers, SpecMergeReviewer{SpecReviewMember: c, Guest: guest})
		if !guest {
			continue
		}
		n++
		id := prefix + "-" + strconv.Itoa(n)
		q := SpecMergeGuestQuestion{ID: id, MemberID: c.MemberID}
		if home != nil {
			path := home.path
			q.Path = &path
		}
		ctx.report.GuestQuestions = append(ctx.report.GuestQuestions, q)
		if home == nil {
			continue
		}
		texts.set(home.key, mergeJoinBlocks(texts.get(home.key), mergeGuestQuestion(id, c)))
	}
}

func mergeTeamIDs(options SpecReviewMergeOptions) map[string]bool {
	team := map[string]bool{}
	for _, m := range options.Team {
		team[m.MemberID] = true
	}
	return team
}

// mergeBlockIDs are the ids of the comments and questions of texts.
func mergeBlockIDs(texts []string) (comments, questions map[string]bool) {
	comments = map[string]bool{}
	questions = map[string]bool{}
	for _, t := range texts {
		for _, p := range reviewPieces(t) {
			if p.kind == string(SpecReviewAnnotationKindComment) && p.id != nil {
				comments[*p.id] = true
			}
			for _, q := range p.questionIDs {
				questions[q] = true
			}
		}
	}
	return comments, questions
}

// mergeTextPhases runs the phases after the structure, shared by both
// formats.
func mergeTextPhases(values []*mergeValue, texts mergeTexts, baseTexts []string, copyTexts [][]string,
	copies []SpecReviewMember, options SpecReviewMergeOptions, home *mergeHome, ctx *mergeContext) {
	for _, v := range values {
		if merged := mergeOneValue(v, ctx); merged != v.base {
			texts.set(v.key, merged)
		}
	}
	mergeApplyAppends(texts, ctx)
	mergeNumberIDs(texts, baseTexts, ctx)
	mergeAnswers(texts, baseTexts, copyTexts, ctx)
	mergeAddGuests(texts, baseTexts, copies, options, home, ctx)
}

func mergeMembersOf[D any](copies []SpecReviewedCopy[D]) []SpecReviewMember {
	out := make([]SpecReviewMember, len(copies))
	for i, c := range copies {
		out[i] = c.SpecReviewMember
	}
	return out
}

// ---------------------------------------------------------------------------
// Plain Markdown: values by heading path.
// ---------------------------------------------------------------------------

// mergeMarkdownSplit is a Markdown file cut at its headings: body i follows
// heading i-1 (body 0 precedes them all).
type mergeMarkdownSplit struct {
	headings []string
	// paths are the heading path of each body, its heading texts joined by
	// ` > ` (body 0: "").
	paths  []string
	bodies [][]string
}

var mergeHeadingRE = regexp.MustCompile(`^(#{1,6})(?:[ \t]+(.*?))?[ \t]*$`)

func mergeSplitMarkdown(text string) mergeMarkdownSplit {
	out := mergeMarkdownSplit{paths: []string{""}, bodies: [][]string{{}}}
	fence := &MarkdownFenceTracker{}
	type level struct {
		depth int
		text  string
	}
	var stack []level
	for _, line := range strings.Split(text, "\n") {
		wasFenced := fence.InFence()
		fence.Feed(line)
		var h []string
		if !wasFenced && !fence.InFence() {
			h = mergeHeadingRE.FindStringSubmatch(line)
		}
		if h == nil {
			last := len(out.bodies) - 1
			out.bodies[last] = append(out.bodies[last], line)
			continue
		}
		depth := len(h[1])
		for len(stack) > 0 && stack[len(stack)-1].depth >= depth {
			stack = stack[:len(stack)-1]
		}
		stack = append(stack, level{depth, h[2]})
		texts := make([]string, len(stack))
		for k, s := range stack {
			texts[k] = s.text
		}
		out.headings = append(out.headings, line)
		out.paths = append(out.paths, strings.Join(texts, " > "))
		out.bodies = append(out.bodies, []string{})
	}
	return out
}

// mergeBodyParts are a body's blank lines before and after its value, and the
// value.
func mergeBodyParts(lines []string) (lead, trail int, value string) {
	for lead < len(lines) && strings.TrimSpace(lines[lead]) == "" {
		lead++
	}
	if lead == len(lines) {
		return lead, 0, ""
	}
	for strings.TrimSpace(lines[len(lines)-1-trail]) == "" {
		trail++
	}
	return lead, trail, strings.Join(lines[lead:len(lines)-trail], "\n")
}

// mergeBodyLines are the body lines for a new value, keeping the body's blank
// lines around it.
func mergeBodyLines(lines []string, value string, afterHeading bool) []string {
	lead, trail, old := mergeBodyParts(lines)
	switch {
	case value == old:
		return lines
	case value == "":
		return lines[:lead]
	case old == "":
		var out []string
		if afterHeading {
			out = append(out, "")
		}
		out = append(out, strings.Split(value, "\n")...)
		if len(lines) > 0 {
			out = append(out, "")
		}
		return out
	}
	out := append([]string{}, lines[:lead]...)
	out = append(out, strings.Split(value, "\n")...)
	return append(out, lines[len(lines)-trail:]...)
}

// mergeSliceTexts are the merged Markdown values, keyed by body index.
type mergeSliceTexts struct {
	values []string
}

func (t *mergeSliceTexts) keys() []string {
	out := make([]string, len(t.values))
	for k := range t.values {
		out[k] = strconv.Itoa(k)
	}
	return out
}

func (t *mergeSliceTexts) get(key string) string {
	k, _ := strconv.Atoi(key)
	return t.values[k]
}

func (t *mergeSliceTexts) set(key, value string) {
	k, _ := strconv.Atoi(key)
	t.values[k] = value
}

func mergeMarkdown(base string, copies []SpecReviewedCopy[string],
	options SpecReviewMergeOptions) (*SpecReviewMergeResult[string], error) {
	b := mergeSplitMarkdown(base)
	cs := make([]mergeMarkdownSplit, len(copies))
	for i, c := range copies {
		cs[i] = mergeSplitMarkdown(c.Document)
		same := len(cs[i].headings) == len(b.headings)
		for k := 0; same && k < len(b.headings); k++ {
			same = strings.TrimSpace(cs[i].headings[k]) == strings.TrimSpace(b.headings[k])
		}
		if !same {
			return nil, &SpecReviewMergeError{Message: "the copy of " + c.MemberID +
				" has other headings than the base"}
		}
	}
	valueOf := func(s mergeMarkdownSplit) []string {
		out := make([]string, len(s.bodies))
		for k, lines := range s.bodies {
			_, _, out[k] = mergeBodyParts(lines)
		}
		return out
	}
	baseTexts := valueOf(b)
	copyTexts := make([][]string, len(cs))
	for i, c := range cs {
		copyTexts[i] = valueOf(c)
	}
	texts := &mergeSliceTexts{values: append([]string{}, baseTexts...)}
	comments, questions := mergeBlockIDs(baseTexts)
	members := mergeMembersOf(copies)
	ctx := newMergeContext(members, comments, questions)
	values := make([]*mergeValue, len(baseTexts))
	for k, t := range baseTexts {
		v := &mergeValue{key: strconv.Itoa(k), path: b.paths[k], base: t}
		for i := range copyTexts {
			c := copyTexts[i][k]
			v.copies = append(v.copies, &c)
		}
		values[k] = v
	}
	first := 0
	if len(b.headings) > 0 {
		first = 1
	}
	home := &mergeHome{key: strconv.Itoa(first), path: b.paths[first]}
	mergeTextPhases(values, texts, baseTexts, copyTexts, members, options, home, ctx)
	var lines []string
	for k, body := range b.bodies {
		if k > 0 {
			lines = append(lines, b.headings[k-1])
		}
		lines = append(lines, mergeBodyLines(body, texts.values[k], k > 0)...)
	}
	return &SpecReviewMergeResult[string]{Merged: strings.Join(lines, "\n"), Report: ctx.report}, nil
}

// ---------------------------------------------------------------------------
// SOM documents: values by model path, list items by section id.
// ---------------------------------------------------------------------------

// mergeCanonicalPaths are a document's paths with every list item named by
// its section id instead of its position (`DEMO/CARD-LST#CARD-BETA/content`),
// so the same item has the same name in the base, in every copy and in the
// merged document.
type mergeCanonicalPaths struct {
	doc         *SpecDocument
	listOf      map[string]string
	ids         map[string]string
	byCanonical map[string]string
	memo        map[string]string
}

func newMergeCanonicalPaths(doc *SpecDocument, refl *SpecReflection) *mergeCanonicalPaths {
	c := &mergeCanonicalPaths{
		doc: doc, listOf: map[string]string{}, ids: map[string]string{},
		byCanonical: map[string]string{}, memo: map[string]string{},
	}
	for _, list := range doc.ListPaths() {
		pattern, stem := "", list
		if res := refl.Resolve(list); res != nil && res.Field != nil {
			pattern, stem = res.Field.SectionIDPattern, res.Field.Name
		}
		for k, item := range doc.ListItems(list) {
			stored, has := doc.ItemSectionID(item)
			c.listOf[item] = list
			c.ids[item] = EffectiveListItemSectionID(stored, has, pattern, k+1, stem)
		}
	}
	for item := range c.listOf {
		c.byCanonical[c.of(item)] = item
	}
	return c
}

// items are the item paths of the list at list, in order.
func (c *mergeCanonicalPaths) items(list string) []string { return c.doc.ListItems(list) }

// idOf is the section id an item is matched by.
func (c *mergeCanonicalPaths) idOf(item string) string { return c.ids[item] }

// of is the canonical form of path.
func (c *mergeCanonicalPaths) of(path string) string {
	if memo, ok := c.memo[path]; ok {
		return memo
	}
	segs := strings.Split(path, "/")
	out := path
	for k := len(segs); k > 0; k-- {
		prefix := strings.Join(segs[:k], "/")
		list, ok := c.listOf[prefix]
		if !ok {
			continue
		}
		out = c.of(list) + "#" + c.idOf(prefix)
		if rest := strings.Join(segs[k:], "/"); rest != "" {
			out += "/" + rest
		}
		break
	}
	c.memo[path] = out
	return out
}

// pathOf is the document's path for a canonical path; ok=false when the
// document lacks one of its items.
func (c *mergeCanonicalPaths) pathOf(canonical string) (string, bool) {
	segs := strings.Split(canonical, "/")
	for k := len(segs); k > 0; k-- {
		item, ok := c.byCanonical[strings.Join(segs[:k], "/")]
		if !ok {
			continue
		}
		if rest := strings.Join(segs[k:], "/"); rest != "" {
			return item + "/" + rest, true
		}
		return item, true
	}
	if strings.Contains(canonical, "#") {
		return "", false
	}
	return canonical, true
}

// mustPathOf is pathOf for a canonical path the document is known to hold.
func (c *mergeCanonicalPaths) mustPathOf(canonical string) string {
	p, _ := c.pathOf(canonical)
	return p
}

// mergeUnder reports whether path is item or lies under it.
func mergeUnder(path, item string) bool {
	return path == item || strings.HasPrefix(path, item+"/")
}

func mergeUnderAny(path string, items map[string]bool) bool {
	for a := range items {
		if mergeUnder(path, a) {
			return true
		}
	}
	return false
}

// mergeCheckStructure refuses a document whose paths the model does not
// resolve: it does not fit the base.
func mergeCheckStructure(doc *SpecDocument, what string, refl *SpecReflection) error {
	j := doc.ToJSON()
	var paths []string
	for p := range j.Content {
		paths = append(paths, p)
	}
	for p := range j.Forms {
		paths = append(paths, p)
	}
	for p := range j.Headlines {
		paths = append(paths, p)
	}
	for p := range j.CodeSpecs {
		paths = append(paths, p)
	}
	for list, l := range j.Lists {
		paths = append(paths, list)
		paths = append(paths, l.Items...)
	}
	sort.Strings(paths)
	for _, p := range paths {
		if refl.Resolve(p) == nil {
			return &SpecReviewMergeError{Message: what + " holds " + p + ", a path the base model does not resolve"}
		}
	}
	return nil
}

func mergeCopyDocument(doc *SpecDocument) *SpecDocument {
	out := NewSpecDocument()
	out.LoadJSON(doc.ToJSON())
	return out
}

// mergeFormField is the form field named field of the form at path, or nil.
func mergeFormField(refl *SpecReflection, path, field string) *FormFieldSpec {
	res := refl.Resolve(path)
	if res == nil || res.Field == nil {
		return nil
	}
	for _, f := range res.Field.FormFields {
		if f.Name == field {
			return f
		}
	}
	return nil
}

// mergeIsText reports whether the value at path / field is text, which can
// hold marks: a content value (a form's preamble included) or a String form
// field that is not code. Scalar and enum leaves, and typed or code fields,
// are not.
func mergeIsText(refl *SpecReflection, path, field string) bool {
	if field != "" {
		spec := mergeFormField(refl, path, field)
		return spec == nil || (spec.Type == "String" && !spec.Code)
	}
	res := refl.Resolve(path)
	if res == nil {
		return true
	}
	if res.Kind == SpecNodeKindScalar || res.Kind == SpecNodeKindEnumValue {
		return false
	}
	return res.Kind != SpecNodeKindListItemScalar || (res.Field != nil && res.Field.ElementType == "String")
}

// mergeFirstContentSlot is the first node at or below path that holds content
// (a content leaf or a form's preamble), in model order; "" when none.
func mergeFirstContentSlot(refl *SpecReflection, path string, deep bool) string {
	res := refl.Resolve(path)
	if res == nil {
		return ""
	}
	if res.Kind == SpecNodeKindContent || res.Kind == SpecNodeKindForm {
		return path
	}
	if res.TargetClass == nil {
		return ""
	}
	for _, f := range res.TargetClass.Fields {
		child := path + "/" + refl.FieldSegment(f)
		if f.Kind == SpecFieldKindContent || f.Kind == SpecFieldKindForm {
			return child
		}
		if deep && (f.Kind == SpecFieldKindComplex || f.Kind == SpecFieldKindSection) {
			if found := mergeFirstContentSlot(refl, child, true); found != "" {
				return found
			}
		}
	}
	return ""
}

// mergeBlockHome is where a block about the node at path goes (SOM §11.9.9,
// "Structure"): the first content value at or below it in document order;
// else the first node at or below it that can hold content; else its nearest
// ancestor's own. "" when there is none.
func mergeBlockHome(doc *SpecDocument, refl *SpecReflection, path string, ownFirst bool) string {
	if ownFirst {
		var existing []string
		for _, p := range doc.ContentPaths() {
			if mergeUnder(p, path) {
				existing = append(existing, p)
			}
		}
		if len(existing) > 0 {
			sort.Strings(existing)
			return existing[0]
		}
		if slot := mergeFirstContentSlot(refl, path, true); slot != "" {
			return slot
		}
	}
	for a := SpecParentPath(path); a != ""; {
		if _, ok := doc.Content(a); ok {
			return a
		}
		if slot := mergeFirstContentSlot(refl, a, false); slot != "" {
			return slot
		}
		parent := SpecParentPath(a)
		if parent == a {
			break
		}
		a = parent
	}
	return ""
}

// mergeStructural is one structural change the copies disagree with the base
// on.
type mergeStructural struct {
	// node is the canonical path of the item (or section) concerned.
	node   string
	topic  string // `Item removed`, `Item moved` or `Headline changed`
	base   string
	groups []mergeGroup
}

func mergeAddStructural(all *[]*mergeStructural, node, topic, base, text, member string) {
	var s *mergeStructural
	for _, x := range *all {
		if x.node == node && x.topic == topic {
			s = x
			break
		}
	}
	if s == nil {
		s = &mergeStructural{node: node, topic: topic, base: base}
		*all = append(*all, s)
	}
	for g := range s.groups {
		if s.groups[g].text == text {
			s.groups[g].members = append(s.groups[g].members, member)
			return
		}
	}
	s.groups = append(s.groups, mergeGroup{text: text, members: []string{member}})
}

// mergeMoved are the ids of ids that are not in their longest common
// subsequence with order, in ids' order.
func mergeMoved(order, ids []string) []string {
	stay := map[string]bool{}
	for i := range mergeLCS(len(order), len(ids), func(i, j int) bool { return order[i] == ids[j] }) {
		stay[order[i]] = true
	}
	var out []string
	for _, id := range ids {
		if !stay[id] {
			out = append(out, id)
		}
	}
	return out
}

var mergeFenceStartRE = regexp.MustCompile("^\\s*(```|~~~)")

// mergeAsInsertion is value written as attributed insertions, one per text
// paragraph (an added item's text); fenced code and annotation blocks are
// copied as they are.
func mergeAsInsertion(value string, members []string) string {
	token := "{@" + strings.Join(members, ",") + "}"
	var out []string
	for _, p := range reviewPieces(value) {
		if p.kind != reviewPieceText || mergeFenceStartRE.MatchString(p.text) {
			out = append(out, p.text)
		} else {
			out = append(out, "{++ "+strings.TrimSpace(p.text)+" ++}"+token)
		}
	}
	return strings.Join(out, "\n\n")
}

// mergeCopyItem copies item from of src, with everything under it, to item to
// of dst; its text values as insertions attributed to members.
func mergeCopyItem(src *SpecDocument, from string, dst *SpecDocument, to string, members []string,
	refl *SpecReflection) error {
	moved := map[string]string{from: to}
	remap := func(p string) string {
		segs := strings.Split(p, "/")
		for k := len(segs); k > 0; k-- {
			if target, ok := moved[strings.Join(segs[:k], "/")]; ok {
				return strings.Join(append([]string{target}, segs[k:]...), "/")
			}
		}
		return p
	}
	var lists []string
	for _, l := range src.ListPaths() {
		if mergeUnder(l, from) {
			lists = append(lists, l)
		}
	}
	sort.SliceStable(lists, func(i, j int) bool {
		di, dj := strings.Count(lists[i], "/"), strings.Count(lists[j], "/")
		if di != dj {
			return di < dj
		}
		return lists[i] < lists[j]
	})
	canonical := newMergeCanonicalPaths(src, refl)
	for _, list := range lists {
		for _, item := range src.ListItems(list) {
			added, err := dst.AddListItemWithSectionID(remap(list), canonical.idOf(item))
			if err != nil {
				return err
			}
			moved[item] = added
		}
	}
	for _, p := range src.ContentPaths() {
		if !mergeUnder(p, from) {
			continue
		}
		value := src.ContentOr(p)
		if mergeIsText(refl, p, "") {
			value = mergeAsInsertion(value, members)
		}
		dst.SetContent(remap(p), value)
	}
	for _, p := range src.FormPaths() {
		if !mergeUnder(p, from) {
			continue
		}
		for _, f := range src.FormFieldNames(p) {
			value := src.FormFieldOr(p, f)
			if mergeIsText(refl, p, f) {
				value = mergeAsInsertion(value, members)
			}
			dst.SetFormField(remap(p), f, value)
		}
	}
	for _, p := range src.HeadlinePaths() {
		if mergeUnder(p, from) {
			dst.SetHeadline(remap(p), src.HeadlineOr(p))
		}
	}
	for _, p := range src.CodeSpecPaths() {
		if mergeUnder(p, from) {
			dst.SetCodeSpec(remap(p), src.CodeSpecOr(p))
		}
	}
	return nil
}

// mergeItemSignature is everything under an item, as one comparable value:
// copies adding the same item alike add it once. Paths are written relative
// to the item, whose own path is a position.
func mergeItemSignature(doc *SpecDocument, item string) string {
	j := doc.ToJSON()
	rel := func(p string) string { return strings.TrimPrefix(p, item) }
	content := map[string]string{}
	for k, v := range j.Content {
		if mergeUnder(k, item) {
			content[rel(k)] = v
		}
	}
	forms := map[string]map[string]string{}
	for k, v := range j.Forms {
		if mergeUnder(k, item) {
			forms[rel(k)] = v
		}
	}
	headlines := map[string]string{}
	for k, v := range j.Headlines {
		if mergeUnder(k, item) {
			headlines[rel(k)] = v
		}
	}
	lists := map[string]ListJson{}
	for k, l := range j.Lists {
		if !mergeUnder(k, item) {
			continue
		}
		entry := ListJson{Seq: l.Seq, Ids: map[string]string{}}
		for _, it := range l.Items {
			entry.Items = append(entry.Items, rel(it))
		}
		for it, id := range l.Ids {
			entry.Ids[rel(it)] = id
		}
		lists[rel(k)] = entry
	}
	// encoding/json writes map keys sorted, so the signature is canonical.
	b, _ := json.Marshal([]any{content, forms, headlines, lists})
	return string(b)
}

// mergeAddedGroup is the copies that added one item alike.
type mergeAddedGroup struct {
	id        string
	copy      int
	anchor    string // the base item it follows; "" for the start
	members   []string
	signature string
}

func mergeContains(ss []string, s string) bool {
	for _, x := range ss {
		if x == s {
			return true
		}
	}
	return false
}

func mergeIndexOf(ss []string, s string) int {
	for k, x := range ss {
		if x == s {
			return k
		}
	}
	return -1
}

// mergeStructure is the structure phase: items the copies added are added
// (attributed to every copy that added them alike); items removed or moved,
// and changed headlines, become structural conflicts. It returns the
// canonical paths of the added items.
func mergeStructure(merged, base *SpecDocument, copies []SpecReviewedCopy[*SpecDocument], refl *SpecReflection,
	model *SpecModel, ctx *mergeContext) (map[string]bool, error) {
	baseCanon := newMergeCanonicalPaths(base, refl)
	copyCanon := make([]*mergeCanonicalPaths, len(copies))
	for i, c := range copies {
		copyCanon[i] = newMergeCanonicalPaths(c.Document, refl)
	}
	added := map[string]bool{}
	var structural []*mergeStructural
	type addition struct {
		node    string
		members []string
	}
	var additions []addition
	listSet := map[string]bool{}
	for _, l := range base.ListPaths() {
		listSet[baseCanon.of(l)] = true
	}
	for i, c := range copies {
		for _, l := range c.Document.ListPaths() {
			listSet[copyCanon[i].of(l)] = true
		}
	}
	ordered := make([]string, 0, len(listSet))
	for l := range listSet {
		ordered = append(ordered, l)
	}
	sort.Slice(ordered, func(i, j int) bool {
		di, dj := strings.Count(ordered[i], "#"), strings.Count(ordered[j], "#")
		if di != dj {
			return di < dj
		}
		return ordered[i] < ordered[j]
	})
	for _, list := range ordered {
		if mergeUnderAny(list, added) {
			continue
		}
		basePath, ok := baseCanon.pathOf(list)
		if !ok {
			continue
		}
		var baseIDs []string
		for _, p := range baseCanon.items(basePath) {
			baseIDs = append(baseIDs, baseCanon.idOf(p))
		}
		var groups []*mergeAddedGroup
		for i, c := range copies {
			copyPath, ok := copyCanon[i].pathOf(list)
			if !ok {
				continue
			}
			items := copyCanon[i].items(copyPath)
			ids := make([]string, len(items))
			for k, p := range items {
				ids[k] = copyCanon[i].idOf(p)
			}
			member := c.MemberID
			for k, id := range ids {
				if mergeContains(baseIDs, id) {
					continue
				}
				signature := mergeItemSignature(c.Document, items[k])
				var g *mergeAddedGroup
				for _, x := range groups {
					if x.id == id {
						g = x
					}
				}
				if g == nil {
					anchor := ""
					for a := k - 1; a >= 0; a-- {
						if mergeContains(baseIDs, ids[a]) {
							anchor = ids[a]
							break
						}
					}
					groups = append(groups, &mergeAddedGroup{id: id, copy: i, anchor: anchor,
						members: []string{member}, signature: signature})
				} else if g.signature == signature {
					g.members = append(g.members, member)
				}
			}
			var keptOrder, keptIDs []string
			for _, id := range baseIDs {
				if !mergeContains(ids, id) {
					mergeAddStructural(&structural, list+"#"+id, "Item removed", "kept", "removed", member)
				} else {
					keptOrder = append(keptOrder, id)
				}
			}
			for _, id := range ids {
				if mergeContains(baseIDs, id) {
					keptIDs = append(keptIDs, id)
				}
			}
			for _, id := range mergeMoved(keptOrder, keptIDs) {
				mergeAddStructural(&structural, list+"#"+id, "Item moved",
					"position "+strconv.Itoa(mergeIndexOf(baseIDs, id)+1),
					"moved to position "+strconv.Itoa(mergeIndexOf(ids, id)+1), member)
			}
		}
		for _, g := range groups {
			mergedCanon := newMergeCanonicalPaths(merged, refl)
			listPath := mergedCanon.mustPathOf(list)
			var mergedIDs []string
			for _, p := range mergedCanon.items(listPath) {
				mergedIDs = append(mergedIDs, mergedCanon.idOf(p))
			}
			at := 0
			if g.anchor != "" {
				at = mergeIndexOf(mergedIDs, g.anchor) + 1
			}
			for at < len(mergedIDs) && !mergeContains(baseIDs, mergedIDs[at]) {
				at++
			}
			item, err := merged.AddListItemWithSectionID(listPath, g.id)
			if err != nil {
				return nil, err
			}
			if at < len(mergedIDs) {
				move, err := merged.MoveListItem(model, item, at, "")
				if err != nil {
					return nil, err
				}
				item = move.Path
			}
			node := list + "#" + g.id
			src := copies[g.copy].Document
			if err := mergeCopyItem(src, copyCanon[g.copy].mustPathOf(node), merged, item, g.members, refl); err != nil {
				return nil, err
			}
			added[node] = true
			additions = append(additions, addition{node: node, members: g.members})
		}
	}
	mergeHeadlineChanges(base, baseCanon, copies, copyCanon, added, &structural)
	mergedCanon := newMergeCanonicalPaths(merged, refl)
	for _, a := range additions {
		ctx.report.Additions = append(ctx.report.Additions,
			SpecMergeAddition{Path: mergedCanon.mustPathOf(a.node), Members: a.members})
	}
	for _, s := range structural {
		node := mergedCanon.mustPathOf(s.node)
		home := mergeBlockHome(merged, refl, node, true)
		block := ctx.conflict(s.topic, node, s.base, s.groups, node, "", nil)
		if home != "" {
			ctx.appendBlock(mergeContentKey(home), block)
		}
	}
	return added, nil
}

// mergeHeadlineChanges makes every headline a copy changed (items it added
// aside) a structural conflict.
func mergeHeadlineChanges(base *SpecDocument, baseCanon *mergeCanonicalPaths,
	copies []SpecReviewedCopy[*SpecDocument], copyCanon []*mergeCanonicalPaths, added map[string]bool,
	structural *[]*mergeStructural) {
	nodeSet := map[string]bool{}
	for _, p := range base.HeadlinePaths() {
		nodeSet[baseCanon.of(p)] = true
	}
	for i, c := range copies {
		for _, p := range c.Document.HeadlinePaths() {
			nodeSet[copyCanon[i].of(p)] = true
		}
	}
	nodes := make([]string, 0, len(nodeSet))
	for n := range nodeSet {
		nodes = append(nodes, n)
	}
	sort.Strings(nodes)
	for _, node := range nodes {
		if mergeUnderAny(node, added) {
			continue
		}
		basePath, ok := baseCanon.pathOf(node)
		if !ok {
			continue
		}
		was := base.HeadlineOr(basePath)
		for i, c := range copies {
			path, ok := copyCanon[i].pathOf(node)
			if !ok {
				continue
			}
			if now := c.Document.HeadlineOr(path); now != was {
				mergeAddStructural(structural, node, "Headline changed", was, now, c.MemberID)
			}
		}
	}
}

// mergeContentKey and mergeFieldKey are the keys of the SOM texts:
// `c\0<path>` for content, `f\0<path>\0<field>` for a form field.
func mergeContentKey(path string) string { return "c\x00" + path }

func mergeFieldKey(path, field string) string { return "f\x00" + path + "\x00" + field }

// mergeSomTexts are a SOM document's values as mergeTexts, in document order
// (content sorted, then forms and their fields sorted).
type mergeSomTexts struct {
	doc *SpecDocument
}

func (t mergeSomTexts) keys() []string {
	var out []string
	for _, p := range sortedCopy(t.doc.ContentPaths()) {
		out = append(out, mergeContentKey(p))
	}
	for _, p := range sortedCopy(t.doc.FormPaths()) {
		for _, f := range sortedCopy(t.doc.FormFieldNames(p)) {
			out = append(out, mergeFieldKey(p, f))
		}
	}
	return out
}

func (t mergeSomTexts) get(key string) string {
	parts := strings.Split(key, "\x00")
	if parts[0] == "c" {
		return t.doc.ContentOr(parts[1])
	}
	return t.doc.FormFieldOr(parts[1], parts[2])
}

func (t mergeSomTexts) set(key, value string) {
	parts := strings.Split(key, "\x00")
	if parts[0] == "c" {
		t.doc.SetContent(parts[1], value)
	} else {
		t.doc.SetFormField(parts[1], parts[2], value)
	}
}

func (t mergeSomTexts) values() []string {
	var out []string
	for _, k := range t.keys() {
		out = append(out, t.get(k))
	}
	return out
}

// mergeSomValues are the values to merge: every value of the base and of the
// copies, items the copies added aside, located in the merged document; in
// its document order.
func mergeSomValues(merged, base *SpecDocument, copies []SpecReviewedCopy[*SpecDocument], added map[string]bool,
	refl *SpecReflection) []*mergeValue {
	baseCanon := newMergeCanonicalPaths(base, refl)
	copyCanon := make([]*mergeCanonicalPaths, len(copies))
	for i, c := range copies {
		copyCanon[i] = newMergeCanonicalPaths(c.Document, refl)
	}
	mergedCanon := newMergeCanonicalPaths(merged, refl)
	type node struct{ path, field string }
	keys := map[string]node{}
	collect := func(doc *SpecDocument, canon *mergeCanonicalPaths) {
		for _, p := range doc.ContentPaths() {
			keys[mergeContentKey(canon.of(p))] = node{canon.of(p), ""}
		}
		for _, p := range doc.FormPaths() {
			for _, f := range doc.FormFieldNames(p) {
				keys[mergeFieldKey(canon.of(p), f)] = node{canon.of(p), f}
			}
		}
	}
	collect(base, baseCanon)
	for i, c := range copies {
		collect(c.Document, copyCanon[i])
	}
	read := func(doc *SpecDocument, path, field string) string {
		if field == "" {
			return doc.ContentOr(path)
		}
		return doc.FormFieldOr(path, field)
	}
	var values []*mergeValue
	for _, n := range keys {
		if mergeUnderAny(n.path, added) {
			continue
		}
		basePath, ok := baseCanon.pathOf(n.path)
		if !ok {
			continue
		}
		path := mergedCanon.mustPathOf(n.path)
		text := mergeIsText(refl, path, n.field)
		v := &mergeValue{path: path, field: n.field, base: read(base, basePath, n.field), typed: !text}
		if n.field == "" {
			v.key = mergeContentKey(path)
		} else {
			v.key = mergeFieldKey(path, n.field)
		}
		for i, c := range copies {
			if p, ok := copyCanon[i].pathOf(n.path); ok {
				value := read(c.Document, p, n.field)
				v.copies = append(v.copies, &value)
			} else {
				v.copies = append(v.copies, nil)
			}
		}
		switch {
		case n.field != "":
			v.conflictHome = mergeContentKey(path)
		case !text:
			if home := mergeBlockHome(merged, refl, path, false); home != "" {
				v.conflictHome = mergeContentKey(home)
			}
		}
		values = append(values, v)
	}
	order := func(v *mergeValue) string {
		kind := "0"
		if v.field != "" {
			kind = "1"
		}
		return kind + "\x00" + v.path + "\x00" + v.field
	}
	sort.Slice(values, func(i, j int) bool { return order(values[i]) < order(values[j]) })
	return values
}

// mergeClassField is the field of cls named name with kind kind, or nil.
func mergeClassField(cls *SpecClass, name, kind string) *SpecField {
	if cls == nil {
		return nil
	}
	if f := cls.FieldNamed(name); f != nil && f.Kind == kind {
		return f
	}
	return nil
}

// The model classes the revision entry is written with (`tom_specs_model`'s
// document front matter).
const (
	mergeRevisionEntry = "RevisionEntry"
	mergeDocumentHdr   = "DocumentHeader"
)

var mergeVersionRE = regexp.MustCompile(`^([0-9]+)\.([0-9]+)(\.[0-9]+)?$`)

// mergeNextMinor is the next minor of a `major.minor[.patch]` version;
// `0.1.0` for anything else.
func mergeNextMinor(version string) string {
	m := mergeVersionRE.FindStringSubmatch(strings.TrimSpace(version))
	if m == nil {
		return "0.1.0"
	}
	minor, _ := strconv.Atoi(m[2])
	out := m[1] + "." + strconv.Itoa(minor+1)
	if m[3] != "" {
		out += ".0"
	}
	return out
}

var mergeDateRE = regexp.MustCompile(`^[0-9]{4}-([0-9]{2})-([0-9]{2})`)

// mergeMonthDay is the month and day of an ISO 8601 date.
func mergeMonthDay(date string) (int, int, error) {
	m := mergeDateRE.FindStringSubmatch(date)
	if m == nil {
		return 0, 0, &SpecReviewMergeError{Message: "options.date \"" + date + "\" is not an ISO 8601 date"}
	}
	month, _ := strconv.Atoi(m[1])
	day, _ := strconv.Atoi(m[2])
	return month, day, nil
}

// mergeAddGeneratedItem adds an item with a generated id to the list field at
// list, and returns its path.
func mergeAddGeneratedItem(doc *SpecDocument, list string, field *SpecField, month, day int) (string, error) {
	pattern := field.SectionIDPattern
	if pattern == "" {
		pattern = field.Name + "-xxx"
	}
	id := GenerateListItemSectionID(pattern, month, day, doc.ListItemSectionIDs(list))
	return doc.AddListItemWithSectionID(list, id)
}

// mergeAddReviewerRecord writes one reviewer record into the list field at
// list.
func mergeAddReviewerRecord(doc *SpecDocument, refl *SpecReflection, list string, field *SpecField,
	member SpecReviewMember, guest bool, month, day int) error {
	item, err := mergeAddGeneratedItem(doc, list, field, month, day)
	if err != nil {
		return err
	}
	form := mergeClassField(refl.ClassNamed(field.ElementType), "content", SpecFieldKindForm)
	if form == nil {
		return nil
	}
	path := item + "/" + refl.FieldSegment(form)
	doc.SetFormField(path, "memberId", member.MemberID)
	doc.SetFormField(path, "displayName", member.DisplayName)
	doc.SetFormField(path, "role", member.Role)
	if guest {
		doc.SetFormField(path, "guest", "true")
	}
	return nil
}

// mergeAddRevisionEntry appends the draft revision entry when the root has a
// revision history: the next minor version, the date and author, the team the
// round started with and every reviewer who returned a copy, guests marked.
func mergeAddRevisionEntry(merged *SpecDocument, root string, copies []SpecReviewMember,
	options SpecReviewMergeOptions, refl *SpecReflection, ctx *mergeContext) error {
	var rootClass *SpecClass
	if r := refl.RootForSegment(root); r != nil {
		rootClass = refl.ClassNamed(r.Type)
	}
	if rootClass == nil {
		return nil
	}
	var history, header *SpecField
	for _, f := range rootClass.Fields {
		if history == nil && f.Kind == SpecFieldKindList && f.ElementType == mergeRevisionEntry {
			history = f
		}
		if header == nil && f.Type == mergeDocumentHdr {
			header = f
		}
	}
	if history == nil {
		return nil
	}
	month, day, err := mergeMonthDay(options.Date)
	if err != nil {
		return err
	}
	current := ""
	if header != nil {
		if headerForm := mergeClassField(refl.ClassNamed(mergeDocumentHdr), "content", SpecFieldKindForm); headerForm != nil {
			current = merged.FormFieldOr(root+"/"+refl.FieldSegment(header)+"/"+refl.FieldSegment(headerForm), "version")
		}
	}
	version := mergeNextMinor(current)
	item, err := mergeAddGeneratedItem(merged, root+"/"+refl.FieldSegment(history), history, month, day)
	if err != nil {
		return err
	}
	entry := refl.ClassNamed(mergeRevisionEntry)
	if form := mergeClassField(entry, "content", SpecFieldKindForm); form != nil {
		path := item + "/" + refl.FieldSegment(form)
		merged.SetFormField(path, "version", version)
		merged.SetFormField(path, "date", options.Date)
		merged.SetFormField(path, "author", options.Author)
	}
	team := mergeTeamIDs(options)
	records := []struct {
		name    string
		members []SpecReviewMember
		guests  bool
	}{
		{"reviewTeam", options.Team, false},
		{"reviewers", copies, true},
	}
	for _, rec := range records {
		list := mergeClassField(entry, rec.name, SpecFieldKindList)
		if list == nil {
			continue
		}
		for _, m := range rec.members {
			guest := rec.guests && !team[m.MemberID]
			if err := mergeAddReviewerRecord(merged, refl, item+"/"+refl.FieldSegment(list), list, m, guest,
				month, day); err != nil {
				return err
			}
		}
	}
	ctx.report.Revision = &SpecMergeRevision{Path: item, Version: version}
	return nil
}

// mergeRootOf is the root segment of a document: the first segment of its
// paths, else the model's first root's.
func mergeRootOf(doc *SpecDocument, refl *SpecReflection) string {
	var paths []string
	paths = append(paths, doc.ContentPaths()...)
	paths = append(paths, doc.FormPaths()...)
	paths = append(paths, doc.ListPaths()...)
	paths = append(paths, doc.HeadlinePaths()...)
	if len(paths) > 0 {
		sort.Strings(paths)
		return strings.Split(paths[0], "/")[0]
	}
	if roots := refl.Roots(); len(roots) > 0 {
		return refl.RootSegment(roots[0])
	}
	return ""
}

func mergeSom(model *SpecModel, base *SpecDocument, copies []SpecReviewedCopy[*SpecDocument],
	options SpecReviewMergeOptions) (*SpecReviewMergeResult[*SpecDocument], error) {
	if model == nil {
		return nil, &SpecReviewMergeError{Message: "merging a SOM document needs its model"}
	}
	refl := NewSpecReflection(model)
	if err := mergeCheckStructure(base, "the base", refl); err != nil {
		return nil, err
	}
	for _, c := range copies {
		if err := mergeCheckStructure(c.Document, "the copy of "+c.MemberID, refl); err != nil {
			return nil, err
		}
	}
	baseValues := mergeSomTexts{base}.values()
	copyValues := make([][]string, len(copies))
	for i, c := range copies {
		copyValues[i] = mergeSomTexts{c.Document}.values()
	}
	comments, questions := mergeBlockIDs(baseValues)
	members := mergeMembersOf(copies)
	ctx := newMergeContext(members, comments, questions)
	merged := mergeCopyDocument(base)
	added, err := mergeStructure(merged, base, copies, refl, model, ctx)
	if err != nil {
		return nil, err
	}
	values := mergeSomValues(merged, base, copies, added, refl)
	root := mergeRootOf(base, refl)
	var home *mergeHome
	if root != "" {
		var rootClass *SpecClass
		if r := refl.RootForSegment(root); r != nil {
			rootClass = refl.ClassNamed(r.Type)
		}
		if rootContent := mergeClassField(rootClass, "content", SpecFieldKindContent); rootContent != nil {
			path := root + "/" + refl.FieldSegment(rootContent)
			home = &mergeHome{key: mergeContentKey(path), path: path}
		}
	}
	mergeTextPhases(values, mergeSomTexts{merged}, baseValues, copyValues, members, options, home, ctx)
	if root != "" {
		if err := mergeAddRevisionEntry(merged, root, members, options, refl, ctx); err != nil {
			return nil, err
		}
	}
	return &SpecReviewMergeResult[*SpecDocument]{Merged: merged, Report: ctx.report}, nil
}
