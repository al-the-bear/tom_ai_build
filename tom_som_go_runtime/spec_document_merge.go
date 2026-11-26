package somruntime

// spec_document_merge.go — the merge back (SOM §11.10; the reading view's
// part *Stripped renditions and the merge back*): an edited readable
// rendition merged onto the document of record, every piece the strip removed
// put back.
//
// The port of `spec_document_merge.dart` / `.ts`, following the JavaScript and
// Rust ports: MergeStrippedValue merges one value (SpecStripValueMerge,
// SpecStripMergePlaced, SpecStripMergeConflict); SpecStripMerge.Merge merges a
// whole rendition onto its document (SpecStripMergeResult,
// SpecStripMergedValue, SpecStripMergeRefusal), and SpecStripMerge.GitShowFile
// reads the base of a stale original from git. `strip_merge_cases.json` holds
// them to the same results.
//
// Offsets are UTF-16 code units, as in every other runtime: the merge works on
// the values as UTF-16 code units — the form the strip's plan, its edit
// scripts and its mark finder use — and hands out ordinary strings again; a
// placed piece's At counts UTF-16 units of the merged value, and an excerpt is
// thirty units either side.

import (
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"sort"
	"strings"
)

// --- the result types ------------------------------------------------------------

// SpecStripMergePlaced is a piece put back after an edited run rather than
// between unchanged neighbours: an author confirms or moves it (`PLACED
// <value> — check`).
type SpecStripMergePlaced struct {
	Piece SpecStripPiece
	// At is the UTF-16 offset in the merged value the piece's text starts at.
	At int
}

// ToJSON is `{at, removed}`, as the conformance corpus writes it.
func (p SpecStripMergePlaced) ToJSON() map[string]interface{} {
	return map[string]interface{}{"at": p.At, "removed": p.Piece.Removed}
}

// SpecStripMergeConflict is why a value, or the whole merge, cannot be merged.
// The codes: `crossesBoundary`, `sentenceRemoved`, `stripTextEdited`,
// `unplaceable`, `notation`, `annotations`, `changedBothSides`,
// `notStrippedBack` and `newFinding`.
type SpecStripMergeConflict struct {
	Code    string
	Message string
	// Value is the value it is about; nil when about no one value.
	Value *SpecStripValueRef
	// Piece is the piece it is about; nil when about no one piece.
	Piece *SpecStripPiece
	// ExcerptO is the original around it.
	ExcerptO string
	// ExcerptB is the stripped text around it.
	ExcerptB string
	// ExcerptE is the edited text around it.
	ExcerptE string
}

// About is the conflict about value.
func (c SpecStripMergeConflict) About(value SpecStripValueRef) SpecStripMergeConflict {
	out := c
	out.Value = &value
	return out
}

// ReportLines is `CONFLICT <value> — <reason>`, then the three excerpts and
// the piece.
func (c SpecStripMergeConflict) ReportLines() []string {
	label := "(document)"
	if c.Value != nil {
		label = SpecStripMergeLabel(*c.Value)
	}
	out := []string{"CONFLICT " + label + " — " + c.Message}
	if c.Piece != nil || c.ExcerptB != "" {
		out = append(out, "  O: "+c.ExcerptO, "  B: "+c.ExcerptB, "  E: "+c.ExcerptE)
	}
	if c.Piece != nil {
		out = append(out, "  piece: "+smergeVisible(stripUnits(c.Piece.Removed)))
	}
	return out
}

// ToJSON is `{code, value?, removed?}`, as the conformance corpus writes it.
func (c SpecStripMergeConflict) ToJSON() map[string]interface{} {
	out := map[string]interface{}{"code": c.Code}
	if c.Value != nil {
		out["value"] = c.Value.ToJSON()
	}
	if c.Piece != nil {
		out["removed"] = c.Piece.Removed
	}
	return out
}

// SpecStripValueMerge is the result of MergeStrippedValue.
type SpecStripValueMerge struct {
	// Text is the merged value; "" (and null in ToJSON) on conflicts.
	Text string
	// Restored is how many pieces were put back.
	Restored  int
	Placed    []SpecStripMergePlaced
	Conflicts []SpecStripMergeConflict
}

// OK reports whether the value merged: no conflict.
func (m *SpecStripValueMerge) OK() bool { return len(m.Conflicts) == 0 }

// ToJSON is `{text, restored, placed, conflicts}`, as the conformance corpus
// writes it.
func (m *SpecStripValueMerge) ToJSON() map[string]interface{} {
	var text interface{}
	if m.OK() {
		text = m.Text
	}
	placed := make([]interface{}, 0, len(m.Placed))
	for _, p := range m.Placed {
		placed = append(placed, p.ToJSON())
	}
	conflicts := make([]interface{}, 0, len(m.Conflicts))
	for _, c := range m.Conflicts {
		conflicts = append(conflicts, c.ToJSON())
	}
	return map[string]interface{}{"text": text, "restored": m.Restored, "placed": placed,
		"conflicts": conflicts}
}

// SpecStripMergeLabel is the name of a value in a merge report: `<path>
// (headline)`, `<path> / <field>` or `<path>`.
func SpecStripMergeLabel(value SpecStripValueRef) string {
	switch {
	case value.Headline:
		return value.Path + " (headline)"
	case value.Field != "":
		return value.Path + " / " + value.Field
	}
	return value.Path
}

// SpecStripMergedValue is one value a document merge changed.
type SpecStripMergedValue struct {
	Value SpecStripValueRef
	// Text is the merged value written into the document of record.
	Text     string
	Restored int
	Placed   []SpecStripMergePlaced
}

// SpecStripMergeRefusal is an edit a merge refuses. The codes: `sectionAdded`,
// `sectionRemoved`, `sectionMoved`, `listItems`, `codeSpec`, `units`,
// `rejected`, `stale` and `strip`.
type SpecStripMergeRefusal struct {
	Code string
	// Path is "" for the whole document.
	Path    string
	Message string
}

// ReportLine is `REFUSED <path> — <message>`.
func (r SpecStripMergeRefusal) ReportLine() string {
	path := r.Path
	if path == "" {
		path = "(document)"
	}
	return "REFUSED " + path + " — " + r.Message
}

// ToJSON is `{code, path}`.
func (r SpecStripMergeRefusal) ToJSON() map[string]interface{} {
	return map[string]interface{}{"code": r.Code, "path": r.Path}
}

// SpecStripMergeResult is the result of SpecStripMerge.Merge.
type SpecStripMergeResult struct {
	// Document is the merged document; nil when nothing may be written.
	Document *SpecDocument
	// Options are the switches the rendition was stripped with.
	Options SpecStripOptions
	// Stale reports whether the merge was three-way, from the original at the
	// export.
	Stale     bool
	Merged    []SpecStripMergedValue
	Conflicts []SpecStripMergeConflict
	Refusals  []SpecStripMergeRefusal
}

// OK reports whether the merge went through: no conflict and no refusal.
func (r *SpecStripMergeResult) OK() bool {
	return len(r.Conflicts) == 0 && len(r.Refusals) == 0
}

// ExitCode is 0 merged or nothing to merge, 1 conflicts or refusals.
func (r *SpecStripMergeResult) ExitCode() int {
	if r.OK() {
		return 0
	}
	return 1
}

// Report is the `MERGED` / `PLACED` lines, then the conflicts' and the
// refusals'.
func (r *SpecStripMergeResult) Report() []string {
	out := []string{}
	for _, m := range r.Merged {
		label := SpecStripMergeLabel(m.Value)
		out = append(out, "MERGED "+label+" — "+itoa(m.Restored)+" pieces put back")
		for range m.Placed {
			out = append(out, "PLACED "+label+" — check")
		}
	}
	for _, c := range r.Conflicts {
		out = append(out, c.ReportLines()...)
	}
	for _, f := range r.Refusals {
		out = append(out, f.ReportLine())
	}
	return out
}

// ReportLines is the report as one text, a line each.
func (r *SpecStripMergeResult) ReportLines() string {
	return strings.Join(r.Report(), "\n")
}

// SpecStripMergeOptions is what SpecStripMerge.Merge takes beyond the original
// and the edited text.
type SpecStripMergeOptions struct {
	// Model is required.
	Model *SpecModel
	// Schema is the schema tier of the checks (nil: not checked).
	Schema *DocSpecsSchema
	// RootType is the root; "" for the single populated one.
	RootType string
	// Options are switches given beside the readable header; they must agree
	// with it. nil for none.
	Options *SpecStripOptions
	// CurrentRevision is the revision the original has now; a header naming
	// another is stale. "" when unknown.
	CurrentRevision string
	// Base is the original as it was at the export, given by hand.
	Base *SpecDocument
	// LoadBase loads the base of a stale original from the header's source
	// (its commit); nil when it cannot be read.
	LoadBase func(source SpecReadableSource) *SpecDocument
	// FileStem and DocumentFiles are the codec's (SpecDocumentMarkdown).
	FileStem      string
	DocumentFiles map[string]string
}

// --- text helpers (UTF-16 code units) --------------------------------------------

const smergeNL uint16 = '\n'

func smergeBlank(s []uint16) bool {
	for _, c := range s {
		if !stripJSSpace(c) {
			return false
		}
	}
	return true
}

// smergeVisible is s in guillemets, its line breaks shown.
func smergeVisible(s []uint16) string {
	return "«" + strings.ReplaceAll(stripString(s), "\n", "⏎") + "»"
}

// smergeExcerpt is thirty UTF-16 units of s either side of at, made visible.
func smergeExcerpt(s []uint16, at int) string {
	a := at
	if a > len(s) {
		a = len(s)
	}
	a -= 30
	if a < 0 {
		a = 0
	}
	z := at + 30
	if z > len(s) {
		z = len(s)
	}
	if z < a {
		z = a
	}
	return smergeVisible(s[a:z])
}

func smergeFirstDifference(a, b []uint16) int {
	n := len(a)
	if len(b) < n {
		n = len(b)
	}
	for i := 0; i < n; i++ {
		if a[i] != b[i] {
			return i
		}
	}
	return n
}

func smergeTrailingBreaks(s []uint16) int {
	n := 0
	for i := len(s) - 1; i >= 0 && s[i] == smergeNL; i-- {
		n++
	}
	return n
}

func smergeLeadingBreaks(s []uint16) int {
	n := 0
	for n < len(s) && s[n] == smergeNL {
		n++
	}
	return n
}

func smergeContains(s []uint16, c uint16) bool {
	for _, x := range s {
		if x == c {
			return true
		}
	}
	return false
}

func smergeBreaks(n int) []uint16 {
	if n <= 0 {
		return nil
	}
	out := make([]uint16, n)
	for i := range out {
		out[i] = smergeNL
	}
	return out
}

// --- edit maps -------------------------------------------------------------------

const (
	smergeWhole = iota
	smergeOpener
	smergeCloser
	smergeBoth
)

// smergeGap is where a gap of the baseline lies in the edited text.
type smergeGap struct {
	leftEdited, rightEdited bool
	start, end              int
}

func (g smergeGap) unchanged() bool {
	return !g.leftEdited && !g.rightEdited && g.start == g.end
}

// smergeGapAt is the gap before baseline unit (or line) p of a script given by
// its op types and the edited-text offsets before each op.
func smergeGapAt(p int, first bool, types []int8, eBefore []int) smergeGap {
	leftEdited := !first && types[p-1] == stripDel
	r := p
	for r < len(types) && types[r] == stripIns {
		r++
	}
	rightEdited := r < len(types) && types[r] == stripDel
	if !leftEdited && r == p && !rightEdited {
		return smergeGap{start: eBefore[p], end: eBefore[p]}
	}
	s := p
	for s > 0 && types[s-1] != stripKeep {
		s--
	}
	t := p
	for t < len(types) && types[t] != stripKeep {
		t++
	}
	return smergeGap{leftEdited: leftEdited, rightEdited: rightEdited, start: eBefore[s], end: eBefore[t]}
}

// smergeEditMap is an edit script from a baseline to an edited text, indexed by
// baseline offset.
type smergeEditMap struct {
	types   []int8
	after   []int
	eBefore []int
	deleted []bool
}

func newSmergeEditMap(ops []stripOp, bLength int) *smergeEditMap {
	m := &smergeEditMap{
		types:   make([]int8, len(ops)),
		after:   make([]int, bLength+1),
		eBefore: make([]int, len(ops)+1),
		deleted: make([]bool, bLength),
	}
	g := 0
	for i, op := range ops {
		m.types[i] = op.typ
		m.eBefore[i+1] = m.eBefore[i]
		if op.typ != stripDel {
			m.eBefore[i+1]++
		}
		if op.typ != stripIns {
			if op.typ == stripDel {
				m.deleted[g] = true
			}
			g++
			m.after[g] = i + 1
		}
	}
	return m
}

func (m *smergeEditMap) gap(g int) smergeGap {
	return smergeGapAt(m.after[g], g == 0, m.types, m.eBefore)
}

// keptRange is the edited-text offset of baseline range [a, z) kept whole;
// false when it was not.
func (m *smergeEditMap) keptRange(a, z int) (int, bool) {
	first := m.after[a+1] - 1
	for k := a; k < z; k++ {
		i := m.after[k+1] - 1
		if m.types[i] != stripKeep || i != first+(k-a) {
			return 0, false
		}
	}
	return m.eBefore[first], true
}

// smergeLineEditMap is a line edit script from a baseline to an edited text.
type smergeLineEditMap struct {
	ops     []stripStep
	types   []int8
	after   []int
	eBefore []int
}

func newSmergeLineEditMap(b, e []uint16) *smergeLineEditMap {
	bl := stripLines(b)
	ops := stripMyers(bl, stripLines(e))
	m := &smergeLineEditMap{
		ops:     ops,
		types:   make([]int8, len(ops)),
		after:   make([]int, len(bl)+1),
		eBefore: make([]int, len(ops)+1),
	}
	k := 0
	for i, op := range ops {
		m.types[i] = op.typ
		m.eBefore[i+1] = m.eBefore[i]
		if op.typ != stripDel {
			m.eBefore[i+1] += len(op.token)
		}
		if op.typ != stripIns {
			k++
			m.after[k] = i + 1
		}
	}
	return m
}

func (m *smergeLineEditMap) gap(k int) smergeGap {
	return smergeGapAt(m.after[k], k == 0, m.types, m.eBefore)
}

// paragraphPlace is where a block goes back in a gap edited on both sides:
// before the paragraph the edited text holds where the baseline had as many
// paragraphs before the block as it removed.
func (m *smergeLineEditMap) paragraphPlace(gap smergeGap, k int) int {
	p := m.after[k]
	s := p
	for s > 0 && m.types[s-1] != stripKeep {
		s--
	}
	before := 0
	blank := true
	for _, op := range m.ops[s:p] {
		if op.typ != stripDel {
			continue
		}
		isBlank := smergeBlank(op.token)
		if !isBlank && blank {
			before++
		}
		blank = isBlank
	}
	if before == 0 {
		return gap.start
	}
	count := 0
	blank = true
	for i := s; i < len(m.ops); i++ {
		op := m.ops[i]
		if op.typ == stripKeep {
			break
		}
		if op.typ != stripIns {
			continue
		}
		isBlank := smergeBlank(op.token)
		if !isBlank && blank {
			if count == before {
				return m.eBefore[i]
			}
			count++
		}
		blank = isBlank
	}
	return gap.end
}

// smergeSlide is the script with each run of whitespace edits slid to lead
// (leading) or trail its unchanged neighbours, where the same whitespace
// stands there.
func smergeSlide(ops []stripOp, leading bool) []stripOp {
	out := append([]stripOp(nil), ops...)
	keep := func(ch uint16) stripOp { return stripOp{typ: stripKeep, ch: ch} }
	edit := func(typ int8, ch uint16) stripOp { return stripOp{typ: typ, ch: ch, label: "edit"} }
	s := 0
	for s < len(out) {
		if out[s].typ == stripKeep {
			s++
			continue
		}
		t := s
		for t < len(out) && out[t].typ == out[s].typ {
			t++
		}
		if t < len(out) && out[t].typ != stripKeep {
			for t < len(out) && out[t].typ != stripKeep {
				t++
			}
			s = t
			continue
		}
		typ := out[s].typ
		if leading {
			for s > 0 && out[s-1].typ == stripKeep && stripJSSpace(out[t-1].ch) && out[s-1].ch == out[t-1].ch {
				out[t-1] = keep(out[t-1].ch)
				out[s-1] = edit(typ, out[s-1].ch)
				s--
				t--
			}
		} else {
			for t < len(out) && out[t].typ == stripKeep && stripJSSpace(out[s].ch) && out[s].ch == out[t].ch {
				out[s] = keep(out[s].ch)
				out[t] = edit(typ, out[t].ch)
				s++
				t++
			}
		}
		s = t
	}
	return out
}

func smergeLineIndex(b []uint16, g int) int {
	k := 0
	for _, c := range b[:g] {
		if c == smergeNL {
			k++
		}
	}
	if g == len(b) && len(b) > 0 && b[len(b)-1] != smergeNL {
		k++
	}
	return k
}

// smergeSentenceRemoved reports whether the edit removed the whole sentence of
// b holding offset g.
func smergeSentenceRemoved(b []uint16, g int, m *smergeEditMap) bool {
	ends := func(i int) bool {
		c := b[i]
		return (c == '.' || c == '!' || c == '?') && (i+1 >= len(b) || stripJSSpace(b[i+1]))
	}
	s := g
	for s > 0 && b[s-1] != smergeNL && !(s < g && ends(s-1)) {
		s--
	}
	e := g
	for e < len(b) && b[e] != smergeNL {
		if ends(e) {
			e++
			break
		}
		e++
	}
	any := false
	for k := s; k < e; k++ {
		if stripJSSpace(b[k]) {
			continue
		}
		any = true
		if !m.deleted[k] {
			return false
		}
	}
	return any
}

// smergePieceRoles is what each piece is, read from the original o: a whole
// element, the opening or the closing marker of an unmarked element, or both
// (the closer of one and the opener of the next).
func smergePieceRoles(o []uint16, original string, pieces []SpecStripPiece, removed [][]uint16) []int {
	at := make([]int, len(o))
	for k := range at {
		at[k] = -1
	}
	for i, p := range pieces {
		for k := p.Origin; k < p.Origin+len(removed[i]) && k < len(o); k++ {
			at[k] = i
		}
	}
	opener := make([]bool, len(pieces))
	closer := make([]bool, len(pieces))
	first := func(s, e int) int {
		if e > len(o) {
			e = len(o)
		}
		for k := s; k < e; k++ {
			if !stripJSSpace(o[k]) {
				return at[k]
			}
		}
		return -1
	}
	whole := func(start, end int) bool {
		if !(start < end && start < len(o) && at[start] >= 0) {
			return false
		}
		for k := start; k < end; k++ {
			if k >= len(o) || at[k] != at[start] {
				return false
			}
		}
		return true
	}
	pair := func(start, openEnd, closeStart, end int) {
		if whole(start, end) {
			return
		}
		po := first(start, openEnd)
		pc := first(closeStart, end)
		if po >= 0 && po != pc {
			opener[po] = true
		}
		if pc >= 0 && pc != po {
			closer[pc] = true
		}
	}
	var walk func(list []*NotationElement)
	walk = func(list []*NotationElement) {
		for _, e := range list {
			if e.Type == "citation" {
				if whole(e.Start, e.End) {
					continue
				}
				if po := first(e.Start+1, e.ContentStart); po >= 0 {
					opener[po] = true
				}
			} else {
				pair(e.Start, e.ContentStart, e.ContentEnd, e.End)
			}
			walk(e.Children)
		}
	}
	walk(ScanNotation(original, true).Elements)
	for _, m := range stripFindMarks(o) {
		openEnd := m.bodyStart
		if m.sep >= 0 {
			openEnd = m.sep + 2
		}
		pair(m.start, openEnd, m.bodyEnd, m.end)
	}
	roles := make([]int, len(pieces))
	for i := range pieces {
		switch {
		case opener[i] && closer[i]:
			roles[i] = smergeBoth
		case opener[i]:
			roles[i] = smergeOpener
		case closer[i]:
			roles[i] = smergeCloser
		default:
			roles[i] = smergeWhole
		}
	}
	return roles
}

// smergePut is text to write into the edited value at at.
type smergePut struct {
	at, order     int
	text          []uint16
	replace       int
	normalize     bool
	before, after int
}

func newSmergePut(at, order int, text []uint16) smergePut {
	return smergePut{at: at, order: order, text: text, before: 2, after: 2}
}

func smergeNotationErrors(s string) int {
	n := 0
	for _, f := range ScanNotation(s, true).Findings {
		if f.Severity() == "error" && f.Code != NotationRejectedBlock {
			n++
		}
	}
	return n
}

// smergeDistance is the blank lines a block keeps from the text beside it: a
// blank line, or none when it stood right against a line; at an edge a blank
// line.
func smergeDistance(breaks int, edge bool) int {
	if edge {
		return 2
	}
	if breaks < 1 {
		return 1
	}
	if breaks > 2 {
		return 2
	}
	return breaks
}

// --- one value -------------------------------------------------------------------

// MergeStrippedValue merges the edited text edited of one value back onto its
// original (SOM §11.10): stripped is the original stripped and pieces what the
// strip removed, anchored in it. A piece goes back between its unchanged
// neighbours; next to an edit it is placed after the edited run (reported as
// placed) or, where that would be a guess — an edit across the boundary of an
// unmarked element (`crossesBoundary`), the whole sentence holding the piece
// removed (`sentenceRemoved`), the text the strip wrote edited
// (`stripTextEdited`), a block without a line to go back to (`unplaceable`) —
// it is a conflict, and so is a merged value with a notation error or a
// malformed annotation neither side had.
func MergeStrippedValue(original, stripped, edited string, pieces []SpecStripPiece) *SpecStripValueMerge {
	if edited == stripped {
		return &SpecStripValueMerge{Text: original, Restored: len(pieces)}
	}
	o, b, e := stripUnits(original), stripUnits(stripped), stripUnits(edited)
	removedOf := make([][]uint16, len(pieces))
	insertedOf := make([][]uint16, len(pieces))
	for i, p := range pieces {
		removedOf[i] = stripUnits(p.Removed)
		insertedOf[i] = stripUnits(p.Inserted)
	}
	roles := smergePieceRoles(o, original, pieces, removedOf)
	ops := stripDiff(b, e, "edit")
	emap := newSmergeEditMap(ops, len(b))
	// An opening marker is judged on the script whose whitespace edits trail
	// their run, a closing one on the script whose whitespace edits lead it.
	trailing := newSmergeEditMap(smergeSlide(ops, false), len(b))
	leading := newSmergeEditMap(smergeSlide(ops, true), len(b))
	var lineMap *smergeLineEditMap
	var puts []smergePut
	placedAt := map[int]bool{}
	var conflicts []SpecStripMergeConflict
	restored := 0
	for i := range pieces {
		p := pieces[i]
		anchor := p.Anchor
		conflict := func(code, message string, eAt int) SpecStripMergeConflict {
			piece := p
			return SpecStripMergeConflict{Code: code, Message: message, Piece: &piece,
				ExcerptO: smergeExcerpt(o, p.Origin), ExcerptB: smergeExcerpt(b, anchor),
				ExcerptE: smergeExcerpt(e, eAt)}
		}

		if len(insertedOf[i]) > 0 {
			if at, ok := emap.keptRange(anchor, anchor+len(insertedOf[i])); ok {
				put := newSmergePut(at, i, removedOf[i])
				put.replace = len(insertedOf[i])
				puts = append(puts, put)
				restored++
			} else {
				conflicts = append(conflicts, conflict("stripTextEdited",
					"the text the strip wrote in place of a piece was edited", emap.gap(anchor).start))
			}
			continue
		}

		role := roles[i]
		g := anchor
		text := append([]uint16(nil), removedOf[i]...)
		if role == smergeWhole && smergeContains(text, smergeNL) {
			for g > 0 && b[g-1] != smergeNL && g < len(b) && text[0] == b[g] {
				text = append(text[1:], text[0])
				g++
			}
			if g == 0 || b[g-1] == smergeNL || g == len(b) {
				if lineMap == nil {
					lineMap = newSmergeLineEditMap(b, e)
				}
				k := smergeLineIndex(b, g)
				gap := lineMap.gap(k)
				if gap.unchanged() {
					puts = append(puts, newSmergePut(gap.start, i, text))
					restored++
					continue
				}
				var at int
				switch {
				case !gap.leftEdited:
					at = gap.start
				case !gap.rightEdited:
					at = gap.end
				default:
					at = lineMap.paragraphPlace(gap, k)
				}
				if at > 0 && at < len(e) && e[at-1] != smergeNL {
					conflicts = append(conflicts, conflict("unplaceable",
						"the block has no line boundary to go back to", at))
					continue
				}
				// The block keeps the distance it had from the text around it
				// in the original: a blank line, or none when it stood right
				// against a line.
				rem := removedOf[i]
				core := p.Origin + smergeLeadingBreaks(rem)
				coreEnd := p.Origin + len(rem) - smergeTrailingBreaks(rem)
				put := newSmergePut(at, i, text)
				put.normalize = true
				coreAt := core
				if coreAt > len(o) {
					coreAt = len(o)
				}
				put.before = smergeDistance(smergeTrailingBreaks(o[:coreAt]), core == 0)
				var right []uint16
				if coreEnd < len(o) {
					right = o[coreEnd:]
				}
				put.after = smergeDistance(smergeLeadingBreaks(right), coreEnd >= len(o))
				puts = append(puts, put)
				restored++
				continue
			}
			g = anchor
			text = append([]uint16(nil), removedOf[i]...)
		}

		m := emap
		switch role {
		case smergeOpener:
			m = trailing
		case smergeCloser:
			m = leading
		}
		gap := m.gap(g)
		if gap.unchanged() {
			puts = append(puts, newSmergePut(gap.start, i, text))
			restored++
			continue
		}
		if smergeBlank(text) {
			continue // normalised whitespace at an edit
		}
		switch role {
		case smergeOpener, smergeCloser:
			if gap.leftEdited && gap.rightEdited {
				conflicts = append(conflicts, conflict("crossesBoundary",
					"an edit crosses the boundary of an unmarked element", gap.start))
				continue
			}
			// The edit on the inner side of the marker goes inside the element.
			var at int
			if role == smergeOpener {
				at = gap.start
				if gap.leftEdited {
					at = gap.end
				}
			} else {
				at = gap.end
				if gap.rightEdited {
					at = gap.start
				}
			}
			puts = append(puts, newSmergePut(at, i, text))
			restored++
		case smergeBoth:
			conflicts = append(conflicts, conflict("crossesBoundary",
				"an edit touches the boundary between two unmarked elements", gap.start))
		default:
			if smergeSentenceRemoved(b, g, emap) {
				conflicts = append(conflicts, conflict("sentenceRemoved",
					"the edit removed the whole sentence holding the piece", gap.start))
				continue
			}
			puts = append(puts, newSmergePut(gap.end, i, text))
			placedAt[i] = true
			restored++
		}
	}
	if len(conflicts) > 0 {
		return &SpecStripValueMerge{Conflicts: conflicts}
	}

	sort.SliceStable(puts, func(x, y int) bool {
		if puts[x].at != puts[y].at {
			return puts[x].at < puts[y].at
		}
		return puts[x].order < puts[y].order
	})
	var out []uint16
	placed := []SpecStripMergePlaced{}
	pos := 0
	for _, put := range puts {
		if put.at < pos {
			piece := pieces[put.order]
			conflicts = append(conflicts, SpecStripMergeConflict{Code: "stripTextEdited",
				Message: "two pieces claim the same text", Piece: &piece})
			continue
		}
		out = append(out, e[pos:put.at]...)
		pos = put.at
		place := func() {
			if placedAt[put.order] {
				placed = append(placed, SpecStripMergePlaced{Piece: pieces[put.order], At: len(out)})
			}
		}
		if put.normalize {
			a := smergeLeadingBreaks(put.text)
			z := len(put.text) - smergeTrailingBreaks(put.text)
			if z < a {
				z = a
			}
			if len(out) > 0 {
				out = append(out, smergeBreaks(put.before-smergeTrailingBreaks(out))...)
			}
			place()
			out = append(out, put.text[a:z]...)
			if pos < len(e) {
				out = append(out, smergeBreaks(put.after-smergeLeadingBreaks(e[pos:]))...)
			}
		} else {
			place()
			out = append(out, put.text...)
		}
		pos += put.replace
	}
	if pos < len(e) {
		out = append(out, e[pos:]...)
	}
	merged := stripString(out)

	if smergeNotationErrors(merged) > smergeNotationErrors(edited)+smergeNotationErrors(original) {
		conflicts = append(conflicts, SpecStripMergeConflict{Code: "notation",
			Message: "the merged value has a notation error neither the original nor the edited text has"})
	}
	if len(AnnotationIssuesText(merged)) > len(AnnotationIssuesText(edited))+len(AnnotationIssuesText(original)) {
		conflicts = append(conflicts, SpecStripMergeConflict{Code: "annotations",
			Message: "the merged value has a malformed review annotation neither the original nor the " +
				"edited text has"})
	}
	if len(conflicts) > 0 {
		return &SpecStripValueMerge{Conflicts: conflicts}
	}
	return &SpecStripValueMerge{Text: merged, Restored: restored, Placed: placed}
}

// --- a document ------------------------------------------------------------------

func smergeOptionsText(o SpecStripOptions) string {
	s := SpecReadableHeader{Options: o}.Format()
	inner := s[len("<!-- readable:") : len(s)-3]
	return strings.Trim(inner, " \t")
}

func smergeRefKey(r SpecStripValueRef) string {
	kind := "c"
	if r.Headline {
		kind = "h"
	} else if r.Field != "" {
		kind = "f"
	}
	return kind + "\x00" + r.Path + "\x00" + r.Field
}

// smergeHeadingPaths is the section-id paths of markdown's headings, in order.
func smergeHeadingPaths(markdown string) []string {
	var out []string
	var walk func(list []*DocSpecsSection, prefix string)
	walk = func(list []*DocSpecsSection, prefix string) {
		for _, s := range list {
			id := s.ID
			if id == "" {
				id = "?"
			}
			p := id
			if prefix != "" {
				p = prefix + "/" + id
			}
			out = append(out, p)
			walk(s.Children, p)
		}
	}
	walk(ParseDocSpecsDocument(markdown).Sections, "")
	return out
}

// smergeListsUnder is the lists of doc under the roots, each as its items and
// their ids.
func smergeListsUnder(doc *SpecDocument, inRoot func(string) bool) map[string]ListJson {
	out := map[string]ListJson{}
	for k, v := range doc.ToJSON().Lists {
		if inRoot(k) {
			out[k] = v
		}
	}
	return out
}

func smergeSameList(a, b ListJson, hasA, hasB bool) bool {
	if hasA != hasB {
		return false
	}
	if !hasA {
		return true
	}
	if len(a.Items) != len(b.Items) || len(a.Ids) != len(b.Ids) {
		return false
	}
	for i := range a.Items {
		if a.Items[i] != b.Items[i] {
			return false
		}
	}
	return len(a.Ids) == 0 || reflect.DeepEqual(a.Ids, b.Ids)
}

func smergeCopyDocument(doc *SpecDocument) *SpecDocument {
	out := NewSpecDocument()
	out.LoadJSON(doc.ToJSON())
	return out
}

// SpecStripMerge merges an edited readable rendition back onto its document
// (SOM §11.10).
type SpecStripMerge struct{}

// Merge merges edited, a `.readable.md` made from original and changed by a
// reader, back onto original (SOM §11.10).
//
// The switches come from the rendition's readable header, or from
// extra.Options (which must agree with a header); with neither, or without a
// model, the merge is a *SpecStripUsageError. The original is stale when a
// Base is given or the header's revision differs from CurrentRevision: the
// merge is then three-way, from the base given or from the header's commit
// through LoadBase, and refused (`stale`) without one. Structural edits —
// sections or list items added, removed or moved, a changed codeSpec or units
// — and a rendition with rejected blocks are refused; every other changed
// value is merged with MergeStrippedValue. A value whose only change is a
// wrapped paragraph read back on one line (SOM §11.4 rule 13) is no edit. The
// merged document is checked to change only the merged values, to strip back
// to the edited text and to add no finding; the result's Document is nil
// unless all of that holds. original is never changed.
func (SpecStripMerge) Merge(original *SpecDocument, edited string, extra SpecStripMergeOptions) (*SpecStripMergeResult, error) {
	model := extra.Model
	if model == nil {
		return nil, &SpecStripUsageError{Message: "a merge needs the model"}
	}
	schema, rootType := extra.Schema, extra.RootType
	codec := NewSpecDocumentMarkdown(model, NewSpecDocument())
	codec.FileStem = extra.FileStem
	codec.DocumentFiles = extra.DocumentFiles
	parsed := codec.Parse(edited)
	var header *SpecReadableHeader
	if parsed.ReadableHeader != "" {
		header = ParseSpecReadableHeader(parsed.ReadableHeader)
		if header == nil {
			return nil, &SpecStripUsageError{Message: "the readable header cannot be read: " + parsed.ReadableHeader}
		}
	}
	var opts SpecStripOptions
	switch {
	case extra.Options != nil && header != nil && smergeOptionsText(header.Options) != smergeOptionsText(*extra.Options):
		return nil, &SpecStripUsageError{Message: "the switches given (" + smergeOptionsText(*extra.Options) +
			") disagree with the readable header (" + smergeOptionsText(header.Options) + ")"}
	case extra.Options != nil:
		opts = *extra.Options
	case header != nil:
		opts = header.Options
	default:
		return nil, &SpecStripUsageError{
			Message: "the rendition has no readable header: name the switches it was stripped with"}
	}
	refused := func(refusals []SpecStripMergeRefusal, stale bool) *SpecStripMergeResult {
		return &SpecStripMergeResult{Options: opts, Stale: stale, Refusals: refusals}
	}

	if len(parsed.Rejections) > 0 {
		var r []SpecStripMergeRefusal
		for _, x := range parsed.Rejections {
			r = append(r, SpecStripMergeRefusal{Code: "rejected",
				Message: "line " + itoa(x.Line) + ": " + x.Message})
		}
		return refused(r, false), nil
	}

	var source *SpecReadableSource
	if header != nil {
		source = header.Source
	}
	current := extra.CurrentRevision
	stale := extra.Base != nil ||
		(source != nil && source.Revision != "" && current != "" && source.Revision != current)
	origin := original
	if stale {
		if extra.Base != nil {
			origin = extra.Base
		} else {
			var loaded *SpecDocument
			if source != nil && extra.LoadBase != nil && source.Commit != "" && !source.Dirty {
				loaded = extra.LoadBase(*source)
			}
			if loaded == nil {
				why := "names no commit"
				if source != nil && source.Commit != "" {
					why = "names a commit that could not be read"
					if source.Dirty {
						why = "names a dirty commit"
					}
				}
				then, now := "null", "null"
				if source != nil && source.Revision != "" {
					then = source.Revision
				}
				if current != "" {
					now = current
				}
				r := SpecStripMergeRefusal{Code: "stale", Message: "the original moved since the export (revision " +
					then + " then, " + now + " now) and there is no base: the header " + why +
					"; give the original as it was at the export"}
				return refused([]SpecStripMergeRefusal{r}, true), nil
			}
			origin = loaded
		}
	}

	stripExtra := SpecDocumentStripOptions{Model: model, Schema: schema, RootType: rootType,
		FileStem: extra.FileStem, DocumentFiles: extra.DocumentFiles}
	strip := SpecDocumentStrip{}.Strip(origin, opts, stripExtra)
	if !strip.OK() || strip.Readable == "" {
		var r []SpecStripMergeRefusal
		for _, f := range strip.Findings {
			path := ""
			if f.Ref != nil {
				path = f.Ref.Label()
			}
			r = append(r, SpecStripMergeRefusal{Code: "strip", Path: path, Message: f.String()})
		}
		if len(r) == 0 {
			r = append(r, SpecStripMergeRefusal{Code: "strip", Message: "the base renders no rendition"})
		}
		return refused(r, stale), nil
	}
	readable := strip.Readable
	bDoc := strip.Document
	eDoc := NewSpecDocument()
	// The rejections were refused above: nothing is left to refuse here.
	_ = eDoc.ApplyMarkdownResult(parsed, true)
	var roots []string
	for r := range parsed.RootPrefixes {
		roots = append(roots, r)
	}
	inRoot := func(p string) bool {
		for _, r := range roots {
			if p == r || (len(p) > len(r) && strings.HasPrefix(p, r) && (p[len(r)] == '/' || p[len(r)] == '-')) {
				return true
			}
		}
		return false
	}

	// Structural edits.
	var refusals []SpecStripMergeRefusal
	bHeadings := smergeHeadingPaths(readable)
	eHeadings := smergeHeadingPaths(edited)
	if !reflect.DeepEqual(bHeadings, eHeadings) {
		bSet, eSet := map[string]bool{}, map[string]bool{}
		for _, p := range bHeadings {
			bSet[p] = true
		}
		for _, p := range eHeadings {
			eSet[p] = true
		}
		for _, p := range eHeadings {
			if !bSet[p] {
				refusals = append(refusals, SpecStripMergeRefusal{Code: "sectionAdded", Path: p,
					Message: "a section added"})
			}
		}
		for _, p := range bHeadings {
			if !eSet[p] {
				refusals = append(refusals, SpecStripMergeRefusal{Code: "sectionRemoved", Path: p,
					Message: "a section removed"})
			}
		}
		if len(refusals) == 0 {
			var common, want []string
			for _, p := range eHeadings {
				if bSet[p] {
					common = append(common, p)
				}
			}
			for _, p := range bHeadings {
				if eSet[p] {
					want = append(want, p)
				}
			}
			for i := 0; i < len(common) && i < len(want); i++ {
				if common[i] != want[i] {
					refusals = append(refusals, SpecStripMergeRefusal{Code: "sectionMoved", Path: common[i],
						Message: "a section moved"})
					break
				}
			}
		}
	}
	bLists := smergeListsUnder(bDoc, inRoot)
	eLists := smergeListsUnder(eDoc, inRoot)
	listKeys := map[string]bool{}
	for k := range bLists {
		listKeys[k] = true
	}
	for k := range eLists {
		listKeys[k] = true
	}
	for _, l := range smergeSortedKeys(listKeys) {
		bl, hasB := bLists[l]
		el, hasE := eLists[l]
		if !smergeSameList(bl, el, hasB, hasE) {
			refusals = append(refusals, SpecStripMergeRefusal{Code: "listItems", Path: l,
				Message: "list items added, removed, moved or renamed"})
		}
	}
	for _, code := range []string{"codeSpec", "units"} {
		isCode := code == "codeSpec"
		read := func(d *SpecDocument, p string) (string, bool) {
			if isCode {
				return d.CodeSpec(p)
			}
			return d.Units(p)
		}
		all := map[string]bool{}
		for _, d := range []*SpecDocument{bDoc, eDoc} {
			paths := d.UnitsPaths()
			if isCode {
				paths = d.CodeSpecPaths()
			}
			for _, p := range paths {
				if inRoot(p) {
					all[p] = true
				}
			}
		}
		for _, p := range smergeSortedKeys(all) {
			bv, bok := read(bDoc, p)
			ev, eok := read(eDoc, p)
			if bv != ev || bok != eok {
				refusals = append(refusals, SpecStripMergeRefusal{Code: code, Path: p, Message: "a changed " + code})
			}
		}
	}
	byKey := map[string]SpecStripValueRef{}
	for _, d := range []*SpecDocument{bDoc, eDoc} {
		for _, r := range stripValueRefs(d) {
			if inRoot(r.Path) {
				byKey[smergeRefKey(r)] = r
			}
		}
	}
	refs := make([]SpecStripValueRef, 0, len(byKey))
	for _, k := range smergeSortedRefKeys(byKey) {
		refs = append(refs, byKey[k])
	}
	sort.SliceStable(refs, func(x, y int) bool {
		a, b := refs[x], refs[y]
		if a.Path != b.Path {
			return a.Path < b.Path
		}
		if a.Headline != b.Headline {
			return a.Headline
		}
		return a.Field < b.Field
	})
	refusedAt := func(path string) bool {
		for _, r := range refusals {
			if r.Path == path {
				return true
			}
		}
		return false
	}
	for _, r := range refs {
		if r.Read(bDoc) == "" && r.Read(eDoc) != "" && !bDoc.HasValuesUnder(r.Path) && !refusedAt(r.Path) {
			refusals = append(refusals, SpecStripMergeRefusal{Code: "sectionAdded", Path: r.Path,
				Message: "a value in a section the rendition does not show"})
		}
	}

	// The values.
	pieces := map[string][]SpecStripPiece{}
	for _, v := range strip.Values {
		pieces[smergeRefKey(v.Ref)] = v.Pieces
	}
	res := refused(nil, stale)
	for _, r := range refs {
		bText := r.Read(bDoc)
		eText := r.Read(eDoc)
		// A wrapped paragraph written in a table cell reads back on one line
		// (SOM §11.4 rule 13): that alone is no edit.
		if bText == eText {
			continue
		}
		if joined, ok := SpecMarkdownWrappedParagraphJoined(bText); ok && joined == eText {
			continue
		}
		if refusedAt(r.Path) {
			continue
		}
		// A value whose section came or went with a refused edit is that edit.
		if len(refusals) > 0 && (!bDoc.HasValuesUnder(r.Path) || !eDoc.HasValuesUnder(r.Path)) {
			continue
		}
		o := r.Read(origin)
		m := MergeStrippedValue(o, bText, eText, pieces[smergeRefKey(r)])
		now := r.Read(original)
		if stale && now != o {
			// The edit is already in the moved original (the same rendition
			// merged before): nothing to do for this value.
			if m.OK() && m.Text == now {
				continue
			}
			b16, e16, o16, now16 := stripUnits(bText), stripUnits(eText), stripUnits(o), stripUnits(now)
			at := smergeFirstDifference(b16, e16)
			ref := r
			res.Conflicts = append(res.Conflicts, SpecStripMergeConflict{Code: "changedBothSides",
				Message:  "the value changed in the original since the export, and in the rendition",
				Value:    &ref,
				ExcerptO: smergeExcerpt(now16, smergeFirstDifference(o16, now16)),
				ExcerptB: smergeExcerpt(b16, at), ExcerptE: smergeExcerpt(e16, at)})
			continue
		}
		if !m.OK() {
			for _, c := range m.Conflicts {
				res.Conflicts = append(res.Conflicts, c.About(r))
			}
			continue
		}
		res.Merged = append(res.Merged, SpecStripMergedValue{Value: r, Text: m.Text, Restored: m.Restored,
			Placed: m.Placed})
	}
	if len(res.Conflicts) > 0 || len(refusals) > 0 {
		res.Refusals = refusals
		return res, nil
	}

	// Write and verify.
	out := smergeCopyDocument(original)
	expected := map[string]bool{}
	for _, m := range res.Merged {
		if m.Text != m.Value.Read(original) {
			expected[smergeRefKey(m.Value)] = true
		}
		m.Value.Write(out, m.Text)
	}
	changed := map[string]bool{}
	for _, d := range []*SpecDocument{original, out} {
		for _, r := range stripValueRefs(d) {
			if r.Read(original) != r.Read(out) {
				changed[smergeRefKey(r)] = true
			}
		}
	}
	if !reflect.DeepEqual(changed, expected) {
		res.Conflicts = append(res.Conflicts, SpecStripMergeConflict{Code: "newFinding",
			Message: "the merged document changes other values than the merged ones"})
	}
	again := SpecDocumentStrip{}.Strip(out, opts, stripExtra)
	for _, m := range res.Merged {
		back := m.Value.Read(again.Document)
		want := m.Value.Read(eDoc)
		if back != want {
			ref := m.Value
			res.Conflicts = append(res.Conflicts, SpecStripMergeConflict{Code: "notStrippedBack",
				Message: "the merged value does not strip back to the edited text", Value: &ref,
				ExcerptO: smergeExcerpt(stripUnits(m.Text), 0), ExcerptB: smergeExcerpt(stripUnits(back), 0),
				ExcerptE: smergeExcerpt(stripUnits(want), 0)})
		}
	}
	before := stripTierFindings(model, schema, rootType, original)
	for _, k := range stripTierFindings(model, schema, rootType, out).keys {
		if !before.has(k) {
			res.Conflicts = append(res.Conflicts, SpecStripMergeConflict{Code: "newFinding",
				Message: "the merged document has a new finding: " + k})
		}
	}
	if len(res.Conflicts) == 0 {
		res.Document = out
	}
	return res, nil
}

func smergeSortedKeys(m map[string]bool) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func smergeSortedRefKeys(m map[string]SpecStripValueRef) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// GitShowFile is the file at filePath as it was at commit (`git show
// <commit>:./<name>`, run in the file's folder); false when git cannot give
// it. What a LoadBase reads the base of a stale original with. No commit, or
// one starting with `-`, gives false: it is never an option to git.
func (SpecStripMerge) GitShowFile(commit, filePath string) (string, bool) {
	if commit == "" || strings.HasPrefix(commit, "-") {
		return "", false
	}
	abs, err := filepath.Abs(filePath)
	if err != nil {
		return "", false
	}
	folder, name := filepath.Dir(abs), filepath.Base(abs)
	if info, err := os.Stat(folder); err != nil || !info.IsDir() {
		return "", false
	}
	cmd := exec.Command("git", "show", commit+":./"+name)
	cmd.Dir = folder
	out, err := cmd.Output()
	if err != nil {
		return "", false
	}
	return string(out), true
}
