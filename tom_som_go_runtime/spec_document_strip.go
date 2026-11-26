package somruntime

// spec_document_strip.go — stripped renditions (SOM §11.10; the reading
// view's part *Stripped renditions and the merge back*): a copy of a document
// with the secondary prose of named kinds dropped, unmarked or moved to an
// appendix.
//
// The kinds are the four the reading notation registers as secondary
// (`provenance`, `trace`, `editorial`, `aside`, DocSpecs RN-5), `linked`, the
// navigation marker (SOM §11.11), and `derived`, the generated parts (SOM
// §11.12) — both removed by `drop` and `unmark` alike, the rendition then
// writing none —, and `comments`, the review annotations (SOM §11.9). A
// citation shape counts as a span of its kind. `refs`, `records` and
// `rejected` are never secondary: no name drops or unmarks them (RN-11).
//
// The port of `spec_document_strip.dart` / `.ts`; `strip_cases.json` holds
// them to the same results. Offsets are UTF-16 code units, as the notation
// scanner's: the strip of one value works on the value's code units.
//
// The plan of one value (stripPlan), the edit scripts (stripDiff,
// stripMyers, stripCompose), the review marks (stripFindMarks), the value
// references (stripValueRefs) and the tier findings (stripTierFindings) are
// package-internal so the merge back of an edited rendition can reuse them.

import (
	"regexp"
	"sort"
	"strings"
	"unicode/utf16"
)

// mdReadableHeaderPartsRE is a readable header line; group 1 its parts.
var mdReadableHeaderPartsRE = regexp.MustCompile(`^<!--\s*readable:(.*)-->$`)

// SpecStripKindNames are the kind names a strip takes, in report and header
// order.
var SpecStripKindNames = []string{
	"provenance", "trace", "editorial", "aside", "linked", "derived", "comments",
}

// SpecStripNotationKinds are the notation kinds a strip can drop, unmark or
// move to the appendix.
var SpecStripNotationKinds = []string{"provenance", "trace", "editorial", "aside"}

// SpecStripUsageError says a strip was asked for something it cannot do; the
// message says which.
type SpecStripUsageError struct {
	Message string
}

func (e *SpecStripUsageError) Error() string { return e.Message }

// SpecStripOptions is what a strip does with each kind. The sets are keyed by
// kind name; SpecStripOptionsFromNames is the checked form.
type SpecStripOptions struct {
	// Drop holds the kinds removed with their content.
	Drop map[string]bool
	// Unmark holds the kinds whose markers go and whose content stays.
	Unmark map[string]bool
	// Appendix holds the kinds moved, with their content, into the appendix
	// *Notes*.
	Appendix map[string]bool
	// AppendixReferences says each moved element leaves a link `[n]` to its
	// entry.
	AppendixReferences bool
	// HeadingDivs says sections deeper than level 6 are styled-div headings.
	HeadingDivs bool
}

// WritesNoLinkedMarkers reports whether the rendition leaves the `linked`
// markers out (SOM §11.11): `linked` dropped or unmarked.
func (o SpecStripOptions) WritesNoLinkedMarkers() bool {
	return o.Drop["linked"] || o.Unmark["linked"]
}

// WritesNoGeneratedParts reports whether the rendition leaves the generated
// parts out (SOM §11.12): `derived` dropped or unmarked.
func (o SpecStripOptions) WritesNoGeneratedParts() bool {
	return o.Drop["derived"] || o.Unmark["derived"]
}

// SpecStripOptionsFromNames is the options from the names a user gives, each
// item possibly comma-joined. `all` stands for every kind the list can hold
// that no other list names explicitly. A *SpecStripUsageError is returned for
// an unknown name, a name in two lists, `comments` to unmark or move, `linked`
// or `derived` to move, and appendix references without an appendix.
func SpecStripOptionsFromNames(drop, unmark, appendix []string, appendixReferences, headingDivs bool) (SpecStripOptions, error) {
	names := func(list []string) []string {
		out := []string{}
		for _, item := range list {
			for _, n := range strings.Split(item, ",") {
				if t := stripJSTrim(n); t != "" {
					out = append(out, t)
				}
			}
		}
		return out
	}
	keys := []string{"drop", "unmark", "appendix"}
	lists := map[string][]string{
		"drop":     names(drop),
		"unmark":   names(unmark),
		"appendix": names(appendix),
	}
	known := append(append([]string{}, SpecStripKindNames...), "all")
	for _, key := range keys {
		for _, n := range lists[key] {
			if !stripContains(known, n) {
				return SpecStripOptions{}, &SpecStripUsageError{Message: "unknown kind name \"" + n + "\" in " +
					key + "; known names: " + strings.Join(known, ", ")}
			}
		}
	}
	for i := 0; i < len(keys); i++ {
		for j := i + 1; j < len(keys); j++ {
			for _, n := range lists[keys[i]] {
				if stripContains(lists[keys[j]], n) {
					return SpecStripOptions{}, &SpecStripUsageError{Message: "kind name \"" + n +
						"\" is in both " + keys[i] + " and " + keys[j]}
				}
			}
		}
	}
	if stripContains(lists["unmark"], "comments") {
		return SpecStripOptions{}, &SpecStripUsageError{Message: "comments cannot be unmarked: a review " +
			"annotation has no reading without its markers; drop it or leave it"}
	}
	if stripContains(lists["appendix"], "comments") {
		return SpecStripOptions{}, &SpecStripUsageError{
			Message: "comments cannot be moved to the appendix; drop them or leave them"}
	}
	for _, k := range []string{"linked", "derived"} {
		if stripContains(lists["appendix"], k) {
			return SpecStripOptions{}, &SpecStripUsageError{Message: k + " cannot be moved to the appendix: " +
				"the renderer writes it from the document; drop it or leave it"}
		}
	}
	explicit := map[string]bool{}
	for _, key := range keys {
		for _, n := range lists[key] {
			if n != "all" {
				explicit[n] = true
			}
		}
	}
	expand := func(list string, all []string) map[string]bool {
		out := map[string]bool{}
		for _, n := range lists[list] {
			if n == "all" {
				for _, k := range all {
					if !explicit[k] {
						out[k] = true
					}
				}
			} else {
				out[n] = true
			}
		}
		return out
	}
	app := expand("appendix", SpecStripNotationKinds)
	if appendixReferences && len(app) == 0 {
		return SpecStripOptions{}, &SpecStripUsageError{
			Message: "appendix references need an appendix: name its kinds"}
	}
	return SpecStripOptions{
		Drop:               expand("drop", SpecStripKindNames),
		Unmark:             expand("unmark", append(append([]string{}, SpecStripNotationKinds...), "linked", "derived")),
		Appendix:           app,
		AppendixReferences: appendixReferences,
		HeadingDivs:        headingDivs,
	}, nil
}

// Keeping is the options of the emptying rule: what would go is unmarked
// instead.
func (o SpecStripOptions) Keeping() SpecStripOptions {
	unmark := map[string]bool{}
	for k := range o.Unmark {
		unmark[k] = true
	}
	for k := range o.Appendix {
		unmark[k] = true
	}
	for k := range o.Drop {
		if k != "comments" {
			unmark[k] = true
		}
	}
	drop := map[string]bool{}
	if o.Drop["comments"] {
		drop["comments"] = true
	}
	return SpecStripOptions{Drop: drop, Unmark: unmark, Appendix: map[string]bool{}, HeadingDivs: o.HeadingDivs}
}

// InEntry is the options an appendix entry's own content is stripped with.
func (o SpecStripOptions) InEntry() SpecStripOptions {
	drop := map[string]bool{}
	for k := range o.Drop {
		if k != "comments" {
			drop[k] = true
		}
	}
	unmark := map[string]bool{}
	for k := range o.Unmark {
		unmark[k] = true
	}
	for k := range o.Appendix {
		unmark[k] = true
	}
	return SpecStripOptions{Drop: drop, Unmark: unmark, Appendix: map[string]bool{}}
}

// SpecStripOptionsOrdered is names in the canonical order of
// SpecStripKindNames.
func SpecStripOptionsOrdered(names map[string]bool) []string {
	out := []string{}
	for _, k := range SpecStripKindNames {
		if names[k] {
			out = append(out, k)
		}
	}
	return out
}

// SpecReadableSource is the source a readable rendition was made from, for
// its header. Revision and Commit are "" when unknown.
type SpecReadableSource struct {
	File     string
	Revision string
	Commit   string
	Dirty    bool
}

// SpecReadableHeader is the readable header line of a stripped rendition (SOM
// §11.1): `<!-- readable: drop=…; unmark=…; appendix=…; appendix-references;
// headings=divs; of=<file>@<revision>; commit=<sha>[+dirty] -->`. Parts that do
// not apply are left out; Format and ParseSpecReadableHeader are inverse.
type SpecReadableHeader struct {
	Options SpecStripOptions
	// Source is nil when the header names none.
	Source *SpecReadableSource
}

// Format is the header line.
func (h SpecReadableHeader) Format() string {
	o := h.Options
	s := h.Source
	var parts []string
	if len(o.Drop) > 0 {
		parts = append(parts, "drop="+strings.Join(SpecStripOptionsOrdered(o.Drop), ","))
	}
	if len(o.Unmark) > 0 {
		parts = append(parts, "unmark="+strings.Join(SpecStripOptionsOrdered(o.Unmark), ","))
	}
	if len(o.Appendix) > 0 {
		parts = append(parts, "appendix="+strings.Join(SpecStripOptionsOrdered(o.Appendix), ","))
	}
	if o.AppendixReferences {
		parts = append(parts, "appendix-references")
	}
	if o.HeadingDivs {
		parts = append(parts, "headings=divs")
	}
	if s != nil {
		of := "of=" + s.File
		if s.Revision != "" {
			of += "@" + s.Revision
		}
		parts = append(parts, of)
		if s.Commit != "" {
			c := "commit=" + s.Commit
			if s.Dirty {
				c += "+dirty"
			}
			parts = append(parts, c)
		}
	}
	if len(parts) == 0 {
		return "<!-- readable: -->"
	}
	return "<!-- readable: " + strings.Join(parts, "; ") + " -->"
}

// ParseSpecReadableHeader reads line as a readable header; nil when it is
// none (another comment, an unknown part or kind name).
func ParseSpecReadableHeader(line string) *SpecReadableHeader {
	m := mdReadableHeaderPartsRE.FindStringSubmatch(stripJSTrim(line))
	if m == nil {
		return nil
	}
	var drop, unmark, appendix []string
	refs, divs := false, false
	file, revision, commit := "", "", ""
	hasFile, hasCommit, dirty := false, false, false
	for _, raw := range strings.Split(m[1], ";") {
		part := stripJSTrim(raw)
		if part == "" {
			continue
		}
		eq := strings.Index(part, "=")
		key, value := part, ""
		if eq >= 0 {
			key, value = part[:eq], part[eq+1:]
		}
		switch {
		case key == "drop":
			drop = append(drop, value)
		case key == "unmark":
			unmark = append(unmark, value)
		case key == "appendix":
			appendix = append(appendix, value)
		case key == "appendix-references" && eq < 0:
			refs = true
		case key == "headings" && value == "divs":
			divs = true
		case key == "of":
			hasFile = true
			if at := strings.LastIndex(value, "@"); at >= 0 {
				file, revision = value[:at], value[at+1:]
			} else {
				file, revision = value, ""
			}
		case key == "commit":
			hasCommit = true
			dirty = strings.HasSuffix(value, "+dirty")
			commit = strings.TrimSuffix(value, "+dirty")
		default:
			return nil
		}
	}
	if !hasFile && hasCommit {
		return nil
	}
	options, err := SpecStripOptionsFromNames(drop, unmark, appendix, refs, divs)
	if err != nil {
		return nil
	}
	h := &SpecReadableHeader{Options: options}
	if hasFile {
		h.Source = &SpecReadableSource{File: file, Revision: revision, Commit: commit, Dirty: dirty}
	}
	return h
}

// SpecStripPiece is one piece a strip removed from a value, anchored in the
// stripped text. Offsets are UTF-16 code units.
type SpecStripPiece struct {
	// Anchor is the offset in the stripped text the piece stands at.
	Anchor int
	// Origin is the offset in the original text the piece starts at.
	Origin int
	// Removed is the original text the piece removed.
	Removed string
	// Inserted is the text the stripped value holds in its place.
	Inserted string
	// Labels says what removed it, sorted.
	Labels []string
}

// ToJSON is the piece as the conformance corpus writes it.
func (p SpecStripPiece) ToJSON() map[string]interface{} {
	labels := make([]interface{}, 0, len(p.Labels))
	for _, l := range p.Labels {
		labels = append(labels, l)
	}
	return map[string]interface{}{
		"anchor":   p.Anchor,
		"origin":   p.Origin,
		"removed":  p.Removed,
		"inserted": p.Inserted,
		"labels":   labels,
	}
}

// SpecAppendixEntry is one entry of a stripped rendition's appendix *Notes*.
type SpecAppendixEntry struct {
	Number int
	Kind   string
	Text   string
	// Value is the value the entry was moved out of (nil for the strip of one
	// value).
	Value *SpecStripValueRef
}

// ToJSON is the entry as the conformance corpus writes it.
func (e SpecAppendixEntry) ToJSON() map[string]interface{} {
	out := map[string]interface{}{"number": e.Number, "kind": e.Kind, "text": e.Text}
	if e.Value != nil {
		out["value"] = e.Value.ToJSON()
	}
	return out
}

// SpecStripTextResult is the result of stripping one value
// (StripNotationText).
type SpecStripTextResult struct {
	Text   string
	Pieces []SpecStripPiece
	// Dropped, Unmarked and Appended count the elements per kind.
	Dropped  map[string]int
	Unmarked map[string]int
	Appended map[string]int
	// MarksDropped counts the review marks that went inside a dropped element.
	MarksDropped int
	Appendix     []SpecAppendixEntry
	// Findings are the error findings a refused value has.
	Findings []*NotationFinding
}

// Refused reports whether the value was refused for its findings.
func (r *SpecStripTextResult) Refused() bool { return len(r.Findings) > 0 }

// ToJSON is the result as the conformance corpus writes it.
func (r *SpecStripTextResult) ToJSON() map[string]interface{} {
	appendix := make([]interface{}, 0, len(r.Appendix))
	for _, e := range r.Appendix {
		appendix = append(appendix, e.ToJSON())
	}
	pieces := make([]interface{}, 0, len(r.Pieces))
	for _, p := range r.Pieces {
		pieces = append(pieces, p.ToJSON())
	}
	refused := make([]interface{}, 0, len(r.Findings))
	for _, f := range r.Findings {
		refused = append(refused, f.Code.String())
	}
	return map[string]interface{}{
		"text":         r.Text,
		"dropped":      stripCountsJSON(r.Dropped),
		"unmarked":     stripCountsJSON(r.Unmarked),
		"appended":     stripCountsJSON(r.Appended),
		"marksDropped": r.MarksDropped,
		"appendix":     appendix,
		"pieces":       pieces,
		"refused":      refused,
	}
}

func stripCountsJSON(m map[string]int) map[string]interface{} {
	out := map[string]interface{}{}
	for k, v := range m {
		out[k] = v
	}
	return out
}

// StripNotationText strips one value with options (SOM §11.10): comments
// first, then the notation from the outside in, then the whitespace the
// removals leave. Appendix entries are numbered from 1. A value whose notation
// has an error finding (other than `rejectedBlock`) is refused and returned
// unchanged.
func StripNotationText(value string, options SpecStripOptions) *SpecStripTextResult {
	return newStripPlan(value, options).finish(func(i int) int { return i + 1 })
}

// --- the strip of a whole document -------------------------------------------

// SpecStripValueRef is a value of a document: its content, a form field or its
// headline.
type SpecStripValueRef struct {
	Path string
	// Field is the form field, "" for content or a headline.
	Field    string
	Headline bool
}

// Read is the value in doc ("" when unset).
func (r SpecStripValueRef) Read(doc *SpecDocument) string {
	switch {
	case r.Headline:
		return doc.HeadlineOr(r.Path)
	case r.Field != "":
		return doc.FormFieldOr(r.Path, r.Field)
	}
	return doc.ContentOr(r.Path)
}

// Write sets the value in doc ("" clears it).
func (r SpecStripValueRef) Write(doc *SpecDocument, value string) {
	switch {
	case r.Headline:
		doc.SetHeadline(r.Path, value)
	case r.Field != "":
		doc.SetFormField(r.Path, r.Field, value)
	default:
		doc.SetContent(r.Path, value)
	}
}

// Label is the reference as a report names it.
func (r SpecStripValueRef) Label() string {
	switch {
	case r.Headline:
		return r.Path + " (headline)"
	case r.Field != "":
		return r.Path + "/" + r.Field
	}
	return r.Path
}

func (r SpecStripValueRef) String() string { return r.Label() }

// ToJSON is the reference as the conformance corpus writes it.
func (r SpecStripValueRef) ToJSON() map[string]interface{} {
	out := map[string]interface{}{"path": r.Path}
	if r.Field != "" {
		out["field"] = r.Field
	}
	if r.Headline {
		out["headline"] = true
	}
	return out
}

// SpecStrippedValue is one value a strip changed, with what went.
type SpecStrippedValue struct {
	Ref      SpecStripValueRef
	Original string
	Stripped string
	Pieces   []SpecStripPiece
}

// SpecStripKept is a value the emptying rule kept.
type SpecStripKept struct {
	Ref     SpecStripValueRef
	Finding string
}

func (k SpecStripKept) String() string {
	return "KEPT (would empty a required value): " + k.Ref.Label() + " — " + k.Finding
}

// SpecStripFinding is a reason a stripped document is not valid.
type SpecStripFinding struct {
	// Kind is `notation`, `instance`, `schema` or `parse`.
	Kind    string
	Message string
	// Ref is the value it concerns, nil for none.
	Ref *SpecStripValueRef
}

func (f SpecStripFinding) String() string {
	if f.Ref != nil {
		return f.Kind + ": " + f.Ref.Label() + ": " + f.Message
	}
	return f.Kind + ": " + f.Message
}

// SpecStripResult is the result of SpecDocumentStrip.Strip.
type SpecStripResult struct {
	Document *SpecDocument
	Values   []SpecStrippedValue
	Kept     []SpecStripKept
	// RemovedItems are the list items the strip left empty and removed.
	RemovedItems []string
	Appendix     []SpecAppendixEntry
	Dropped      map[string]int
	Unmarked     map[string]int
	Appended     map[string]int
	MarksDropped int
	// ReadableHeader is the header line the rendition carries.
	ReadableHeader string
	// Readable is the `.readable.md`; "" without a model.
	Readable string
	Findings []SpecStripFinding
}

// OK reports whether the stripped document is valid and may be written.
func (r *SpecStripResult) OK() bool { return len(r.Findings) == 0 }

// Report is what was dropped, unmarked, moved and kept per kind.
func (r *SpecStripResult) Report() []string {
	out := []string{}
	for _, k := range SpecStripKindNames {
		d, u, a := r.Dropped[k], r.Unmarked[k], r.Appended[k]
		if d+u+a > 0 {
			out = append(out, k+": "+itoa(d)+" dropped, "+itoa(u)+" unmarked, "+itoa(a)+" moved")
		}
	}
	if r.MarksDropped > 0 {
		out = append(out, "review marks inside dropped elements: "+itoa(r.MarksDropped))
	}
	for _, k := range r.Kept {
		out = append(out, k.String())
	}
	return out
}

// SpecDocumentStripOptions are the options of SpecDocumentStrip.Strip beyond
// the switches. Without a Model nothing is rendered or checked.
type SpecDocumentStripOptions struct {
	Model *SpecModel
	// Schema is the DocSpecs schema the rendition is checked against (nil:
	// the schema tier is not checked).
	Schema *DocSpecsSchema
	// RootType is the root rendered; "" the single populated root.
	RootType string
	// FileStem and DocumentFiles are the codec's (SpecDocumentMarkdown).
	FileStem      string
	DocumentFiles map[string]string
	// Source is the source named in the readable header (nil: none).
	Source *SpecReadableSource
}

// SpecDocumentStrip is the strip of a whole document (SOM §11.10).
type SpecDocumentStrip struct{}

type stripEntryKey struct{ index, entry int }

// Strip strips every value of document — content, form-field values and
// stored headlines — into a copy. Given a model it also applies the emptying
// rule, removes list items left empty, numbers the appendix through the
// rendition, renders the `.readable.md` and checks it.
func (SpecDocumentStrip) Strip(document *SpecDocument, options SpecStripOptions, extra SpecDocumentStripOptions) *SpecStripResult {
	model := extra.Model
	schema := extra.Schema
	rootType := extra.RootType
	codec := func(doc *SpecDocument) *SpecDocumentMarkdown {
		c := NewSpecDocumentMarkdown(model, doc)
		c.FileStem = extra.FileStem
		c.DocumentFiles = extra.DocumentFiles
		return c
	}
	refs := stripValueRefs(document)
	var findings []SpecStripFinding
	plans := map[int]*stripPlan{}
	for index, ref := range refs {
		text := ref.Read(document)
		if text == "" {
			continue
		}
		plan := newStripPlan(text, options)
		if len(plan.findings) > 0 {
			for _, f := range plan.findings {
				r := ref
				findings = append(findings, SpecStripFinding{Kind: "notation",
					Message: f.Code.String() + " (line " + itoa(f.Line) + "): " + f.Message, Ref: &r})
			}
			continue
		}
		if plan.changes() {
			plans[index] = plan
		}
	}
	planOrder := func() []int {
		out := make([]int, 0, len(plans))
		for i := range plans {
			out = append(out, i)
		}
		sort.Ints(out)
		return out
	}

	cp := NewSpecDocument()
	cp.LoadJSON(document.ToJSON())
	provisional := map[stripEntryKey]int{}
	next := 1
	for _, index := range planOrder() {
		for i := range plans[index].entries {
			provisional[stripEntryKey{index, i}] = next
			next++
		}
	}
	apply := func(numbers map[stripEntryKey]int) {
		for _, index := range planOrder() {
			idx := index
			refs[index].Write(cp, plans[index].finish(func(i int) int { return numbers[stripEntryKey{idx, i}] }).Text)
		}
	}
	apply(provisional)
	var kept []SpecStripKept
	var base *stripTierSet
	removedItems := []string{}
	if model != nil {
		base = stripTierFindings(model, schema, rootType, document)
		removedItems = stripEmptyingRule(model, schema, rootType, base, document, cp, refs, plans, &kept, options)
	} else {
		base = &stripTierSet{paths: map[string]string{}}
	}

	// The appendix, numbered through the rendition.
	var entries []stripEntryKey
	for _, index := range planOrder() {
		for i := range plans[index].entries {
			entries = append(entries, stripEntryKey{index, i})
		}
	}
	var root *SpecRoot
	if model != nil {
		r, err := cp.RootToExport(model, rootType)
		if err != nil {
			findings = append(findings, SpecStripFinding{Kind: "parse", Message: err.Error()})
		} else {
			root = r
		}
	}
	titles := map[string]string{}
	if len(entries) > 0 && root != nil {
		rendition, err := codec(cp).ExportRootWithMap(root)
		if err != nil {
			findings = append(findings, SpecStripFinding{Kind: "parse", Message: err.Error()})
		} else {
			lines := strings.Split(rendition.Markdown, "\n")
			order := map[string]int{}
			for _, line := range stripSortedLines(rendition.HeadingPaths) {
				path := rendition.HeadingPaths[line]
				order[path] = line
				titles[path] = SpecMarkdownHeadingTitle(lines[line-1])
			}
			sectionLine := func(ref SpecStripValueRef) int {
				best, bestLength := 0, -1
				for p, line := range order {
					if (ref.Path == p || strings.HasPrefix(ref.Path, p+"/")) && len(p) > bestLength {
						best, bestLength = line, len(p)
					}
				}
				return best
			}
			sort.SliceStable(entries, func(a, b int) bool {
				ea, eb := entries[a], entries[b]
				la, lb := sectionLine(refs[ea.index]), sectionLine(refs[eb.index])
				if la != lb {
					return la < lb
				}
				if ea.index != eb.index {
					return ea.index < eb.index
				}
				return ea.entry < eb.entry
			})
		}
	}
	numbers := map[stripEntryKey]int{}
	for k, e := range entries {
		numbers[e] = k + 1
	}
	apply(numbers)

	result := &SpecStripResult{
		Document:     cp,
		Kept:         kept,
		RemovedItems: removedItems,
		Dropped:      map[string]int{},
		Unmarked:     map[string]int{},
		Appended:     map[string]int{},
	}
	add := func(into, from map[string]int) {
		for k, v := range from {
			into[k] += v
		}
	}
	for _, index := range planOrder() {
		idx := index
		plan := plans[index]
		r := plan.finish(func(i int) int { return numbers[stripEntryKey{idx, i}] })
		result.Values = append(result.Values, SpecStrippedValue{Ref: refs[index], Original: plan.o,
			Stripped: r.Text, Pieces: r.Pieces})
		add(result.Dropped, r.Dropped)
		add(result.Unmarked, r.Unmarked)
		add(result.Appended, r.Appended)
		result.MarksDropped += r.MarksDropped
		for _, e := range r.Appendix {
			ref := refs[index]
			result.Appendix = append(result.Appendix, SpecAppendixEntry{Number: e.Number, Kind: e.Kind,
				Text: e.Text, Value: &ref})
		}
	}
	sort.SliceStable(result.Appendix, func(a, b int) bool {
		return result.Appendix[a].Number < result.Appendix[b].Number
	})

	result.ReadableHeader = SpecReadableHeader{Options: options, Source: extra.Source}.Format()
	if model != nil && root != nil {
		c := codec(cp)
		c.HeadingDivs = options.HeadingDivs
		c.ReadableHeader = result.ReadableHeader
		c.LinkedMarkers = !options.WritesNoLinkedMarkers()
		c.GeneratedParts = !options.WritesNoGeneratedParts()
		rendition, err := c.ExportRootWithMap(root)
		if err != nil {
			findings = append(findings, SpecStripFinding{Kind: "parse", Message: err.Error()})
		} else {
			if len(titles) == 0 && len(result.Appendix) > 0 {
				lines := strings.Split(rendition.Markdown, "\n")
				for line, path := range rendition.HeadingPaths {
					titles[path] = SpecMarkdownHeadingTitle(lines[line-1])
				}
			}
			readable := rendition.Markdown
			if len(result.Appendix) > 0 {
				readable = stripWithAppendix(rendition.Markdown, result.Appendix, titles, options.AppendixReferences)
			}
			result.Readable = readable
			findings = stripCheckOutput(model, schema, root, rootType, base, document, cp, readable, codec, findings)
		}
	}
	result.Findings = findings
	return result
}

func stripSortedLines(m map[int]string) []int {
	out := make([]int, 0, len(m))
	for l := range m {
		out = append(out, l)
	}
	sort.Ints(out)
	return out
}

// stripValueRefs is every value of doc: headlines, content, form fields, each
// group sorted by path.
func stripValueRefs(doc *SpecDocument) []SpecStripValueRef {
	var out []SpecStripValueRef
	for _, p := range sortedCopy(doc.HeadlinePaths()) {
		out = append(out, SpecStripValueRef{Path: p, Headline: true})
	}
	for _, p := range sortedCopy(doc.ContentPaths()) {
		out = append(out, SpecStripValueRef{Path: p})
	}
	for _, p := range sortedCopy(doc.FormPaths()) {
		for _, f := range sortedCopy(doc.FormFieldNames(p)) {
			out = append(out, SpecStripValueRef{Path: p, Field: f})
		}
	}
	return out
}

// stripTierSet is the findings of the instance and schema tiers: each key (a
// finding's text) with the path it concerns, in the order found.
type stripTierSet struct {
	keys  []string
	paths map[string]string
}

func (s *stripTierSet) add(key, path string) {
	if _, ok := s.paths[key]; !ok {
		s.keys = append(s.keys, key)
	}
	s.paths[key] = path
}

func (s *stripTierSet) has(key string) bool {
	_, ok := s.paths[key]
	return ok
}

// stripTierFindings is the instance-tier findings of doc and, given a schema,
// the schema-tier findings of its rendition.
func stripTierFindings(model *SpecModel, schema *DocSpecsSchema, rootType string, doc *SpecDocument) *stripTierSet {
	out := &stripTierSet{paths: map[string]string{}}
	for _, e := range ValidateDocument(model, doc) {
		out.add("instance "+e.Code+" "+e.Path+": "+e.Message, e.Path)
	}
	if schema != nil {
		// No single root to render: the schema tier cannot judge it.
		if found, err := ValidateSpecDocument(model, doc, schema, rootType); err == nil {
			for _, v := range found {
				out.add("schema "+v.Rule+" "+v.SectionID+": "+v.Message, v.Path)
			}
		}
	}
	return out
}

func stripConcerns(findingPath, path string) bool {
	return findingPath == "" || path == findingPath ||
		strings.HasPrefix(path, findingPath+"/") ||
		strings.HasPrefix(path, findingPath+"-") ||
		strings.HasPrefix(findingPath, path+"/")
}

// stripItemsAbove is the list items of doc at or above the refs' paths, sorted.
func stripItemsAbove(doc *SpecDocument, refs []SpecStripValueRef) []string {
	items := map[string]bool{}
	for _, list := range doc.ListPaths() {
		for _, i := range doc.ListItems(list) {
			items[i] = true
		}
	}
	found := map[string]bool{}
	for _, ref := range refs {
		p := ref.Path
		if items[p] {
			found[p] = true
		}
		for i := 0; i < len(p); i++ {
			if p[i] == '/' && items[p[:i]] {
				found[p[:i]] = true
			}
		}
	}
	out := make([]string, 0, len(found))
	for p := range found {
		out = append(out, p)
	}
	sort.Strings(out)
	return out
}

// stripEmptyingRule keeps, unmarked, each value whose strip would empty a value
// the model requires, and answers the list items the strip left empty, which
// it removes from cp.
func stripEmptyingRule(model *SpecModel, schema *DocSpecsSchema, rootType string, base *stripTierSet,
	document, cp *SpecDocument, refs []SpecStripValueRef, plans map[int]*stripPlan,
	kept *[]SpecStripKept, options SpecStripOptions) []string {
	keptRefs := map[int]bool{}
	keepItems := map[string]bool{}
	var planned []SpecStripValueRef
	for index := range refs {
		if _, ok := plans[index]; ok {
			planned = append(planned, refs[index])
		}
	}
	candidates := stripItemsAbove(cp, planned)
	emptiedItems := func() []string {
		out := []string{}
		for _, item := range candidates {
			if !keepItems[item] && document.HasValuesUnder(item) && !cp.HasValuesUnder(item) {
				out = append(out, item)
			}
		}
		return out
	}
	for round := 0; round < 8; round++ {
		items := emptiedItems()
		scratch := cp
		if len(items) > 0 {
			scratch = NewSpecDocument()
			scratch.LoadJSON(cp.ToJSON())
		}
		for _, item := range items {
			scratch.RemoveListItem(item)
		}
		now := stripTierFindings(model, schema, rootType, scratch)
		var added []string
		for _, k := range now.keys {
			if !base.has(k) {
				added = append(added, k)
			}
		}
		if len(added) == 0 {
			break
		}
		var emptied []int
		for index := range refs {
			if _, ok := plans[index]; ok && !keptRefs[index] && stripJSTrim(refs[index].Read(cp)) == "" {
				emptied = append(emptied, index)
			}
		}
		changed := false
		for _, key := range added {
			findingPath := now.paths[key]
			for _, item := range items {
				if stripConcerns(findingPath, item) && !keepItems[item] {
					keepItems[item] = true
					changed = true
				}
			}
			for _, index := range emptied {
				ref := refs[index]
				if keptRefs[index] || !stripConcerns(findingPath, ref.Path) {
					continue
				}
				keptRefs[index] = true
				*kept = append(*kept, SpecStripKept{Ref: ref, Finding: key})
				keeping := newStripPlan(plans[index].o, options.Keeping())
				text := keeping.finish(func(int) int { return 0 }).Text
				if stripJSTrim(text) == "" {
					delete(plans, index)
					ref.Write(cp, ref.Read(document))
				} else {
					plans[index] = keeping
					ref.Write(cp, text)
				}
				changed = true
			}
		}
		if !changed {
			break
		}
	}
	items := emptiedItems()
	for _, item := range items {
		cp.RemoveListItem(item)
	}
	return items
}

// stripCheckOutput checks the rendition: it reads back as the stripped
// document without a rejection, adds no instance or schema finding, and its
// DocSpecs validation adds none to the original's.
func stripCheckOutput(model *SpecModel, schema *DocSpecsSchema, root *SpecRoot, rootType string,
	before *stripTierSet, document, cp *SpecDocument, readable string,
	codec func(*SpecDocument) *SpecDocumentMarkdown, findings []SpecStripFinding) []SpecStripFinding {
	parsed := codec(NewSpecDocument()).Parse(readable)
	for _, r := range parsed.Rejections {
		findings = append(findings, SpecStripFinding{Kind: "parse", Message: "the rendition rejects: " + r.String()})
	}
	prefix := root.SectionID
	if prefix == "" {
		prefix = root.Type
	}
	inRoot := func(p string) bool { return p == prefix || strings.HasPrefix(p, prefix+"/") }
	compare := func(what string, want, got map[string]string) {
		keySet := map[string]bool{}
		for k := range want {
			keySet[k] = true
		}
		for k := range got {
			keySet[k] = true
		}
		keys := make([]string, 0, len(keySet))
		for k := range keySet {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		for _, k := range keys {
			w, hasW := want[k]
			g, hasG := got[k]
			if !inRoot(k) || (hasW == hasG && w == g) {
				continue
			}
			// A wrapped paragraph written in a table cell reads back on one
			// line (SOM §11.4).
			if hasW && hasG {
				if joined, ok := SpecMarkdownWrappedParagraphJoined(w); ok && joined == g {
					continue
				}
			}
			gs, ws := "nothing", "nothing"
			if hasG {
				gs = "\"" + g + "\""
			}
			if hasW {
				ws = "\"" + w + "\""
			}
			findings = append(findings, SpecStripFinding{Kind: "parse",
				Message: what + " at " + k + " reads back as " + gs + " instead of " + ws})
		}
	}
	wantContent := map[string]string{}
	for _, p := range cp.ContentPaths() {
		wantContent[p] = cp.ContentOr(p)
	}
	compare("content", wantContent, parsed.Content)
	wantForms := map[string]string{}
	for _, p := range cp.FormPaths() {
		for _, f := range cp.FormFieldNames(p) {
			wantForms[p+"/"+f] = cp.FormFieldOr(p, f)
		}
	}
	gotForms := map[string]string{}
	for p, fields := range parsed.Forms {
		for f, v := range fields {
			gotForms[p+"/"+f] = v
		}
	}
	compare("the form field", wantForms, gotForms)
	for _, key := range stripTierFindings(model, schema, rootType, cp).keys {
		if !before.has(key) {
			kind := "instance"
			if strings.HasPrefix(key, "schema") {
				kind = "schema"
			}
			findings = append(findings, SpecStripFinding{Kind: kind, Message: key})
		}
	}
	if schema != nil {
		key := func(v *DocSpecsViolation) string { return v.Rule + " " + v.SectionID + ": " + v.Message }
		validator := NewDocSpecsValidatorWithTomSpecs(schema, true)
		had := map[string]bool{}
		if original, err := codec(document).ExportRoot(root); err == nil {
			for _, v := range validator.ValidateMarkdown(original) {
				had[key(v)] = true
			}
		}
		for _, v := range validator.ValidateMarkdown(readable) {
			if !had[key(v)] {
				findings = append(findings, SpecStripFinding{Kind: "schema",
					Message: "the rendition: line " + itoa(v.Line) + ": " + key(v)})
			}
		}
	}
	return findings
}

// stripWithAppendix is markdown with the appendix *Notes* after its marker,
// the entries under the titles of their sections.
func stripWithAppendix(markdown string, entries []SpecAppendixEntry, titles map[string]string, references bool) string {
	sectionOf := func(ref *SpecStripValueRef) (string, string) {
		best, title := "", ref.Path
		for p, t := range titles {
			if (ref.Path == p || strings.HasPrefix(ref.Path, p+"/")) && len(p) > len(best) {
				best, title = p, t
			}
		}
		if best == "" {
			return ref.Path, title
		}
		return best, title
	}
	var b strings.Builder
	b.WriteString(strings.TrimRight(markdown, "\n"))
	b.WriteString("\n\n" + SpecMarkdownAppendixMarker + "\n\n## Notes\n")
	section, hasSection := "", false
	for _, e := range entries {
		path, title := "", ""
		if e.Value != nil {
			path, title = sectionOf(e.Value)
		}
		if !hasSection || path != section {
			b.WriteString("\n### " + title + "\n")
			section, hasSection = path, true
		}
		lines := strings.Split(e.Text, "\n")
		for i, l := range lines {
			if strings.HasPrefix(l, "#") {
				lines[i] = "\\" + l
			}
		}
		text := strings.Join(lines, "\n")
		n := itoa(e.Number)
		if references {
			b.WriteString("\n<a id=\"note-" + n + "\"></a>**[" + n + "]** " + text +
				" [↩](#note-" + n + "-ref)\n")
		} else {
			b.WriteString("\n**[" + n + "]** " + text + "\n")
		}
	}
	return b.String()
}

// --- one value's strip ----------------------------------------------------------

const (
	stripKeep int8 = iota
	stripDel
	stripIns
)

// stripOp is one step of an edit script over UTF-16 code units; label "" is
// none (a kept unit).
type stripOp struct {
	typ   int8
	ch    uint16
	label string
}

// stripInsert is a text the stripped value holds where nothing stood: a review
// mark's new delimiter (hasText) or an appendix reference (entry).
type stripInsert struct {
	label   string
	text    []uint16
	hasText bool
	entry   int
}

// stripEntry is an appendix entry before it is numbered.
type stripEntry struct {
	kind string
	text string
}

// stripPlan is the strip of one value, planned once and finished for any
// numbering. o is the value as given; t the value the notation strip works on
// (o without its comments when they are dropped) as UTF-16 code units — the
// indexing of del / ins and the scanner's offsets.
type stripPlan struct {
	o            string
	options      SpecStripOptions
	t            []uint16
	script1      []stripOp
	hasScript1   bool
	del          []string
	blockDel     []bool
	ins          map[int][]stripInsert
	dropped      map[string]int
	unmarked     map[string]int
	appended     map[string]int
	marksDropped int
	entries      []stripEntry
	findings     []*NotationFinding
}

func newStripPlan(o string, options SpecStripOptions) *stripPlan {
	p := &stripPlan{
		o:        o,
		options:  options,
		ins:      map[int][]stripInsert{},
		dropped:  map[string]int{},
		unmarked: map[string]int{},
		appended: map[string]int{},
	}
	for _, f := range ScanNotation(o, true).Findings {
		if f.Severity() == NotationSeverityError && f.Code != NotationRejectedBlock {
			p.findings = append(p.findings, f)
		}
	}
	o16 := stripUnits(o)
	if len(p.findings) > 0 {
		p.t = o16
		p.del = make([]string, len(p.t))
		p.blockDel = make([]bool, len(p.t))
		return p
	}
	stripped := o
	if options.Drop["comments"] {
		stripped = StripAnnotationsText(o)
		p.t = stripUnits(stripped)
		if stripped != o {
			p.dropped["comments"] = CountAnnotationsText(o)
			p.script1 = stripDiff(o16, p.t, "comments")
			p.hasScript1 = true
		}
	} else {
		p.t = o16
	}
	p.del = make([]string, len(p.t))
	p.blockDel = make([]bool, len(p.t))
	p.process(ScanNotation(stripped, true).Elements)
	if !options.Drop["comments"] {
		p.marks()
	}
	if p.anyDeleted() {
		p.normalise()
	}
	return p
}

func (p *stripPlan) anyDeleted() bool {
	for _, d := range p.del {
		if d != "" {
			return true
		}
	}
	return false
}

// changes reports whether the strip changes the value.
func (p *stripPlan) changes() bool {
	return len(p.findings) == 0 && (p.hasScript1 || p.anyDeleted() || len(p.ins) > 0)
}

func (p *stripPlan) mark(s, e int, label string, block bool) {
	if e > len(p.t) {
		e = len(p.t)
	}
	for i := s; i < e; i++ {
		if p.del[i] == "" {
			p.del[i] = label
		}
		if block {
			p.blockDel[i] = true
		}
	}
}

func (p *stripPlan) insert(at int, x stripInsert) {
	p.ins[at] = append(p.ins[at], x)
}

func (p *stripPlan) process(list []*NotationElement) {
	t := p.t
	for _, e := range list {
		k := e.Kind
		// A `linked` span (SOM §11.11) or a `derived` block (SOM §11.12) is
		// removed by `-drop:` and `-unmark:` alike: its text without its
		// markers would read back as content.
		if e.IsRegistered() && (k == "linked" || k == "derived") &&
			(p.options.Drop[k] || p.options.Unmark[k]) {
			p.remove(e, k+":drop", -1)
			p.dropped[k]++
			continue
		}
		secondary := e.IsRegistered() && k != "" && stripContains(SpecStripNotationKinds, k)
		if !secondary {
			p.process(e.Children)
			continue
		}
		if p.options.Drop[k] {
			p.remove(e, k+":drop", -1)
			p.dropped[k]++
			continue
		}
		if p.options.Appendix[k] {
			var content []uint16
			if e.Type == NotationTypeCitation {
				content = t[e.Start:e.End]
			} else {
				content = t[e.ContentStart:e.ContentEnd]
				for len(content) > 0 && content[len(content)-1] == '\n' {
					content = content[:len(content)-1]
				}
			}
			p.entries = append(p.entries, stripEntry{kind: k,
				text: StripNotationText(stripString(content), p.options.InEntry()).Text})
			p.remove(e, k+":appendix", len(p.entries)-1)
			p.appended[k]++
			continue
		}
		if p.options.Unmark[k] {
			p.unmark(e, k+":unmark")
			p.unmarked[k]++
		}
		p.process(e.Children)
	}
}

func (p *stripPlan) remove(e *NotationElement, label string, entry int) {
	t := p.t
	reference := entry >= 0 && p.options.AppendixReferences
	if e.Type == NotationTypeDiv {
		p.mark(e.Start, e.End, label, true)
		if reference {
			p.insert(e.Start, stripInsert{label: label, entry: entry})
		}
		return
	}
	s := e.Start
	if s > 0 && stripSpace(t[s-1]) && p.del[s-1] == "" {
		p.del[s-1] = label
	} else if !reference && (s == 0 || t[s-1] == '\n') && e.End < len(t) && stripSpace(t[e.End]) {
		p.del[e.End] = label
	}
	p.mark(e.Start, e.End, label, false)
	if reference {
		p.insert(e.Start, stripInsert{label: label, entry: entry})
	}
}

func (p *stripPlan) unmark(e *NotationElement, label string) {
	switch e.Type {
	case NotationTypeDiv:
		if e.ContentStart >= e.ContentEnd {
			p.mark(e.Start, e.End, label, true)
		} else {
			p.mark(e.Start, e.ContentStart, label, true)
			p.mark(e.ContentEnd-1, e.End, label, true)
		}
	case NotationTypeSpan:
		p.mark(e.Start, e.Start+1, label, false)
		p.mark(e.ContentEnd, e.End, label, false)
	default:
		p.mark(e.Start+1, e.ContentStart, label, false)
	}
}

func (p *stripPlan) marks() {
	for _, m := range stripFindMarks(p.t) {
		if p.allDeleted(m.start, m.end) {
			p.marksDropped++
			continue
		}
		if m.sep < 0 {
			if stripHasText(p.t, m.bodyStart, m.bodyEnd) && !p.survives(m.bodyStart, m.bodyEnd) {
				p.removeMark(m)
			}
			continue
		}
		oldHad := stripHasText(p.t, m.bodyStart, m.sep)
		newHad := stripHasText(p.t, m.sep+2, m.bodyEnd)
		oldLeft := p.survives(m.bodyStart, m.sep)
		newLeft := p.survives(m.sep+2, m.bodyEnd)
		switch {
		case !oldLeft && !newLeft && (oldHad || newHad):
			p.removeMark(m)
		case oldHad && !oldLeft:
			p.convert(m, "++", m.bodyStart, m.sep+2)
		case newHad && !newLeft:
			p.convert(m, "--", m.sep, m.bodyEnd)
		}
	}
}

func (p *stripPlan) removeMark(m stripMark) {
	t := p.t
	s := m.start
	if s > 0 && stripSpace(t[s-1]) && p.del[s-1] == "" {
		p.del[s-1] = "mark"
	} else if (s == 0 || t[s-1] == '\n') && m.end < len(t) && stripSpace(t[m.end]) {
		p.del[m.end] = "mark"
	}
	p.mark(m.start, m.end, "mark", false)
}

func (p *stripPlan) convert(m stripMark, delimiter string, s, e int) {
	d := stripUnits(delimiter)
	p.mark(m.start+1, m.start+3, "mark", false)
	p.insert(m.start+3, stripInsert{label: "mark", text: d, hasText: true})
	p.mark(s, e, "mark", false)
	p.mark(m.end-3, m.end-1, "mark", false)
	p.insert(m.end-1, stripInsert{label: "mark", text: d, hasText: true})
}

func (p *stripPlan) allDeleted(s, e int) bool {
	for i := s; i < e; i++ {
		if p.del[i] == "" {
			return false
		}
	}
	return true
}

func (p *stripPlan) survives(s, e int) bool {
	for i := s; i < e; i++ {
		if p.del[i] == "" && !stripJSSpace(p.t[i]) {
			return true
		}
	}
	return false
}

func (p *stripPlan) wipe(i int) {
	if i >= 0 && p.del[i] == "" {
		p.del[i] = "whitespace"
	}
}

func (p *stripPlan) normalise() {
	t := p.t
	del := p.del
	starts := []int{0}
	for i, c := range t {
		if c == '\n' {
			starts = append(starts, i+1)
		}
	}
	for l, s := range starts {
		e := len(t)
		if l+1 < len(starts) {
			e = starts[l+1] - 1
		}
		if !stripHasText(t, s, e) {
			continue
		}
		touched, survives, allBlock := false, false, true
		for i := s; i < e; i++ {
			if del[i] != "" {
				touched = true
			} else if !stripJSSpace(t[i]) {
				survives = true
			}
			if !p.blockDel[i] {
				allBlock = false
			}
		}
		for i := s; i <= e; i++ {
			if _, ok := p.ins[i]; ok {
				survives = true
			}
		}
		if !touched || survives || allBlock {
			continue
		}
		p.mark(s, e, "whitespace", false)
		if e < len(t) {
			p.wipe(e)
		} else if s > 0 {
			p.wipe(s - 1)
		}
	}
	// Blank-line runs, read on the text as it now stands.
	var kept []int
	var b []uint16
	for i := 0; i <= len(t); i++ {
		for _, x := range p.ins[i] {
			s := []uint16{'x'} // a reference is never blank
			if x.hasText {
				s = x.text
			}
			for range s {
				kept = append(kept, -1)
			}
			b = append(b, s...)
		}
		if i < len(t) && del[i] == "" {
			kept = append(kept, i)
			b = append(b, t[i])
		}
	}
	solid := func(c uint16) bool { return !stripJSSpace(c) }
	firstSolid := 0
	for firstSolid < len(b) && !solid(b[firstSolid]) {
		firstSolid++
	}
	if firstSolid == len(b) {
		for _, i := range kept {
			p.wipe(i)
		}
		return
	}
	lastSolid := len(b) - 1
	for !solid(b[lastSolid]) {
		lastSolid--
	}
	lead := -1
	for k := firstSolid; k >= 0; k-- {
		if b[k] == '\n' {
			lead = k
			break
		}
	}
	for k := 0; k <= lead; k++ {
		p.wipe(kept[k])
	}
	trail := -1
	for k := lastSolid; k < len(b); k++ {
		if b[k] == '\n' {
			trail = k
			break
		}
	}
	if trail >= 0 {
		for k := trail; k < len(b); k++ {
			p.wipe(kept[k])
		}
	}
	k := firstSolid
	for k < lastSolid {
		if solid(b[k]) {
			k++
			continue
		}
		runStart := k
		for !solid(b[k]) {
			k++
		}
		runEnd := k
		var breaks []int
		for j := runStart; j < runEnd; j++ {
			if b[j] == '\n' {
				breaks = append(breaks, j)
			}
		}
		if len(breaks) <= 2 {
			continue
		}
		from := kept[runStart-1]
		to := kept[runEnd]
		atRemoval := false
		if from >= 0 && to >= 0 {
			for i := from + 1; i < to; i++ {
				if del[i] != "" && del[i] != "whitespace" {
					atRemoval = true
				}
			}
		} else {
			atRemoval = true
		}
		if !atRemoval {
			continue
		}
		for j := breaks[0] + 1; j <= breaks[len(breaks)-1]-1; j++ {
			p.wipe(kept[j])
		}
	}
}

// finish is the strip with the appendix entries numbered by number.
func (p *stripPlan) finish(number func(int) int) *SpecStripTextResult {
	if len(p.findings) > 0 {
		return &SpecStripTextResult{
			Text:     p.o,
			Pieces:   []SpecStripPiece{},
			Dropped:  map[string]int{},
			Unmarked: map[string]int{},
			Appended: map[string]int{},
			Appendix: []SpecAppendixEntry{},
			Findings: p.findings,
		}
	}
	t := p.t
	insertText := func(x stripInsert) []uint16 {
		if x.hasText {
			return x.text
		}
		n := itoa(number(x.entry))
		return stripUnits("<a id=\"note-" + n + "-ref\"></a>[\\[" + n + "\\]](#note-" + n + ")")
	}
	var script2 []stripOp
	for i := 0; i <= len(t); i++ {
		for _, x := range p.ins[i] {
			for _, c := range insertText(x) {
				script2 = append(script2, stripOp{stripIns, c, x.label})
			}
		}
		if i < len(t) {
			if p.del[i] == "" {
				script2 = append(script2, stripOp{stripKeep, t[i], ""})
			} else {
				script2 = append(script2, stripOp{stripDel, t[i], p.del[i]})
			}
		}
	}
	ops := script2
	if p.hasScript1 {
		ops = stripCompose(p.script1, script2)
	}
	var out []uint16
	pieces := []SpecStripPiece{}
	oPos, bPos, i := 0, 0, 0
	for i < len(ops) {
		if ops[i].typ == stripKeep {
			out = append(out, ops[i].ch)
			oPos++
			bPos++
			i++
			continue
		}
		anchor, origin := bPos, oPos
		var removed, inserted []uint16
		labels := map[string]bool{}
		for i < len(ops) && ops[i].typ != stripKeep {
			op := ops[i]
			if op.label != "" {
				labels[op.label] = true
			}
			if op.typ == stripDel {
				removed = append(removed, op.ch)
				oPos++
			} else {
				inserted = append(inserted, op.ch)
				out = append(out, op.ch)
				bPos++
			}
			i++
		}
		sorted := make([]string, 0, len(labels))
		for l := range labels {
			sorted = append(sorted, l)
		}
		sort.Strings(sorted)
		pieces = append(pieces, SpecStripPiece{Anchor: anchor, Origin: origin,
			Removed: stripString(removed), Inserted: stripString(inserted), Labels: sorted})
	}
	appendix := make([]SpecAppendixEntry, 0, len(p.entries))
	for k, e := range p.entries {
		appendix = append(appendix, SpecAppendixEntry{Number: number(k), Kind: e.kind, Text: e.text})
	}
	return &SpecStripTextResult{
		Text:         stripString(out),
		Pieces:       pieces,
		Dropped:      stripCopyCounts(p.dropped),
		Unmarked:     stripCopyCounts(p.unmarked),
		Appended:     stripCopyCounts(p.appended),
		MarksDropped: p.marksDropped,
		Appendix:     appendix,
	}
}

func stripCopyCounts(m map[string]int) map[string]int {
	out := make(map[string]int, len(m))
	for k, v := range m {
		out[k] = v
	}
	return out
}

// stripCompose composes the scripts original → middle (s1) and middle →
// result (s2).
func stripCompose(s1, s2 []stripOp) []stripOp {
	var out []stripOp
	j := 0
	flushInserts := func() {
		for j < len(s2) && s2[j].typ == stripIns {
			out = append(out, s2[j])
			j++
		}
	}
	for _, a := range s1 {
		if a.typ == stripDel {
			out = append(out, a)
			continue
		}
		flushInserts()
		b := s2[j]
		j++
		if a.typ == stripKeep {
			if b.typ == stripKeep {
				out = append(out, a)
			} else {
				out = append(out, stripOp{stripDel, a.ch, b.label})
			}
		} else if b.typ == stripKeep {
			out = append(out, a)
		}
	}
	flushInserts()
	return out
}

// stripDiff is an edit script from a to b: Myers by line, then by word token.
func stripDiff(a, b []uint16, label string) []stripOp {
	var out []stripOp
	chars := func(typ int8, s []uint16) {
		l := label
		if typ == stripKeep {
			l = ""
		}
		for _, c := range s {
			out = append(out, stripOp{typ, c, l})
		}
	}
	var deleted, inserted []uint16
	flush := func() {
		if len(deleted) == 0 && len(inserted) == 0 {
			return
		}
		for _, step := range stripMyers(stripTokens(deleted), stripTokens(inserted)) {
			chars(step.typ, step.token)
		}
		deleted, inserted = nil, nil
	}
	for _, step := range stripMyers(stripLines(a), stripLines(b)) {
		switch step.typ {
		case stripKeep:
			flush()
			chars(stripKeep, step.token)
		case stripDel:
			deleted = append(deleted, step.token...)
		default:
			inserted = append(inserted, step.token...)
		}
	}
	flush()
	return out
}

// stripLines is s split after each line break.
func stripLines(s []uint16) [][]uint16 {
	var out [][]uint16
	i := 0
	for i < len(s) {
		e := len(s)
		for j := i; j < len(s); j++ {
			if s[j] == '\n' {
				e = j + 1
				break
			}
		}
		out = append(out, s[i:e])
		i = e
	}
	return out
}

func stripTokenKind(c uint16) int {
	if c == 0x20 || c == 0x09 || c == 0x0a || c == 0x0d {
		return 2
	}
	if (c >= 0x30 && c <= 0x39) || (c >= 0x41 && c <= 0x5a) || (c >= 0x61 && c <= 0x7a) ||
		c == 0x5f || c >= 0x80 {
		return 1
	}
	return 0
}

// stripTokens is s split into word, whitespace and single-punctuation tokens.
func stripTokens(s []uint16) [][]uint16 {
	var out [][]uint16
	i := 0
	for i < len(s) {
		k := stripTokenKind(s[i])
		j := i + 1
		if k != 0 {
			for j < len(s) && stripTokenKind(s[j]) == k {
				j++
			}
		}
		out = append(out, s[i:j])
		i = j
	}
	return out
}

// stripStep is one step of a Myers script: a token kept, deleted or inserted.
type stripStep struct {
	typ   int8
	token []uint16
}

func stripEqual(a, b []uint16) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

// stripMyers is the Myers edit script from a to b (at most 2000 edits, else
// everything deleted and inserted).
func stripMyers(a, b [][]uint16) []stripStep {
	n, m := len(a), len(b)
	max := n + m
	if max == 0 {
		return nil
	}
	const limit = 2000
	off := max + 1
	v := make([]int, 2*max+3)
	var trace [][]int
	found := -1
	for d := 0; d <= max && d <= limit; d++ {
		if d > 0 {
			snap := make([]int, 2*d-1)
			for k := -(d - 1); k <= d-1; k++ {
				snap[k+d-1] = v[k+off]
			}
			trace = append(trace, snap)
		}
		for k := -d; k <= d; k += 2 {
			var x int
			if k == -d || (k != d && v[k-1+off] < v[k+1+off]) {
				x = v[k+1+off]
			} else {
				x = v[k-1+off] + 1
			}
			y := x - k
			for x < n && y < m && stripEqual(a[x], b[y]) {
				x++
				y++
			}
			v[k+off] = x
			if x >= n && y >= m {
				found = d
				break
			}
		}
		if found >= 0 {
			break
		}
	}
	if found < 0 {
		out := make([]stripStep, 0, n+m)
		for _, t := range a {
			out = append(out, stripStep{stripDel, t})
		}
		for _, t := range b {
			out = append(out, stripStep{stripIns, t})
		}
		return out
	}
	var rev []stripStep
	x, y := n, m
	for d := found; d > 0; d-- {
		snap := trace[d-1]
		at := func(k int) int { return snap[k+d-1] }
		k := x - y
		var prevK int
		if k == -d || (k != d && at(k-1) < at(k+1)) {
			prevK = k + 1
		} else {
			prevK = k - 1
		}
		prevX := at(prevK)
		prevY := prevX - prevK
		for x > prevX && y > prevY {
			rev = append(rev, stripStep{stripKeep, a[x-1]})
			x--
			y--
		}
		if x == prevX {
			rev = append(rev, stripStep{stripIns, b[y-1]})
		} else {
			rev = append(rev, stripStep{stripDel, a[x-1]})
		}
		x, y = prevX, prevY
	}
	for x > 0 && y > 0 {
		rev = append(rev, stripStep{stripKeep, a[x-1]})
		x--
		y--
	}
	for i, j := 0, len(rev)-1; i < j; i, j = i+1, j-1 {
		rev[i], rev[j] = rev[j], rev[i]
	}
	return rev
}

// stripMark is an inline review mark of the text the notation strip works on
// (UTF-16 offsets); sep is the `~>` of a substitution, -1 for none.
type stripMark struct {
	start, end, bodyStart, bodyEnd, sep int
}

var stripMarkPairs = [][2]string{
	{"{++", "++}"}, {"{--", "--}"}, {"{~~", "~~}"}, {"{==", "==}"}, {"{>>", "<<}"},
}

// stripFindMarks is the inline review marks of t, outside code, each inside
// one paragraph.
func stripFindMarks(t []uint16) []stripMark {
	code := make([]bool, len(t))
	fence := &MarkdownFenceTracker{}
	s := 0
	for _, line := range stripSplitLines(t) {
		inFence := fence.InFence()
		fence.Feed(stripString(line))
		if inFence || fence.InFence() {
			for i := s; i < s+len(line); i++ {
				code[i] = true
			}
		} else {
			i := 0
			for i < len(line) {
				if line[i] != '`' {
					i++
					continue
				}
				j := i
				for j < len(line) && line[j] == '`' {
					j++
				}
				ticks := line[i:j]
				close := stripFind(line, ticks, j)
				if close < 0 {
					i = j
					continue
				}
				for k := s + i; k < s+close+len(ticks); k++ {
					code[k] = true
				}
				i = close + len(ticks)
			}
		}
		s += len(line) + 1
	}
	arrow := stripUnits("~>")
	var out []stripMark
	i := 0
	for i+3 <= len(t) {
		opener := t[i : i+3]
		var closer []uint16
		tilde := false
		for _, pair := range stripMarkPairs {
			if stripEqual(opener, stripUnits(pair[0])) {
				closer = stripUnits(pair[1])
				tilde = pair[0] == "{~~"
				break
			}
		}
		if closer == nil || code[i] {
			i++
			continue
		}
		// `/\n[ \t]*\n/` from i: the paragraph's end.
		limit := len(t)
		for at := i; at < len(t); at++ {
			if t[at] != '\n' {
				continue
			}
			q := at + 1
			for q < len(t) && stripSpace(t[q]) {
				q++
			}
			if q < len(t) && t[q] == '\n' {
				limit = at
				break
			}
		}
		close := stripFind(t, closer, i+3)
		if close < 0 || close+3 > limit {
			i++
			continue
		}
		sep := -1
		if tilde {
			sep = stripFind(t, arrow, i+3)
			if sep < 0 || sep >= close {
				i++
				continue
			}
		}
		out = append(out, stripMark{start: i, end: close + 3, bodyStart: i + 3, bodyEnd: close, sep: sep})
		i = close + 3
	}
	return out
}

// --- helpers ---------------------------------------------------------------------

func stripUnits(s string) []uint16 { return utf16.Encode([]rune(s)) }

// stripString is the string of UTF-16 code units (a lone surrogate as U+FFFD).
func stripString(u []uint16) string { return string(utf16.Decode(u)) }

// stripSplitLines is s split at each line break (the breaks dropped).
func stripSplitLines(s []uint16) [][]uint16 {
	var out [][]uint16
	start := 0
	for i, c := range s {
		if c == '\n' {
			out = append(out, s[start:i])
			start = i + 1
		}
	}
	return append(out, s[start:])
}

// stripFind is the first index of needle in hay at or after from, -1 for none.
func stripFind(hay, needle []uint16, from int) int {
	if len(needle) == 0 {
		return -1
	}
	for i := from; i+len(needle) <= len(hay); i++ {
		if stripEqual(hay[i:i+len(needle)], needle) {
			return i
		}
	}
	return -1
}

func stripSpace(c uint16) bool { return c == ' ' || c == '\t' }

// stripJSSpace reports whether c is what JavaScript's `trim()` removes.
func stripJSSpace(c uint16) bool {
	switch {
	case c >= 0x09 && c <= 0x0D, c == 0x20, c == 0xA0, c == 0x1680,
		c >= 0x2000 && c <= 0x200A, c == 0x2028, c == 0x2029, c == 0x202F,
		c == 0x205F, c == 0x3000, c == 0xFEFF:
		return true
	}
	return false
}

// stripHasText reports whether t[s:e] holds more than whitespace.
func stripHasText(t []uint16, s, e int) bool {
	if e > len(t) {
		e = len(t)
	}
	for i := s; i < e; i++ {
		if !stripJSSpace(t[i]) {
			return true
		}
	}
	return false
}

// stripJSTrim is s without the leading and trailing whitespace JavaScript's
// `trim()` removes.
func stripJSTrim(s string) string {
	return strings.TrimFunc(s, func(r rune) bool { return r < 0x10000 && stripJSSpace(uint16(r)) })
}

func stripContains(list []string, s string) bool {
	for _, x := range list {
		if x == s {
			return true
		}
	}
	return false
}
