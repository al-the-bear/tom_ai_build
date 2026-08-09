package somruntime

// spec_query.go — lexical/structural query + lazy cursor over a live
// SpecDocument (`llm_and_d4rt_tools.md` §6, `som_multiplatform_spec_model.md`
// §15), a faithful port of `tom_som_dart_runtime/lib/src/spec_query.dart`.
//
// This is the **grep-like** facility the downstream D4rt scripting layer and the
// editor's search tools reuse. It is **embedding-free** — exact substring or
// SomTextPattern match plus structural filters — so it is always current and
// needs no model calls.
//
// A SpecQuery composes (AND-combined) over five dimensions:
//
//   - **text** — substring or SomTextPattern over content + form-field values
//     and over a node's headline, stored or doc-comment (optionally
//     case-insensitive);
//   - **kind** — one or more node kinds;
//   - **class** — the model class a node *is* (by class name);
//   - **id / path** — exact @SectionId, @SectionId prefix, path glob, or a
//     @MapsTo / @DetailedIn target on the node's class;
//   - **state** — empty / non-empty (the structural "empty = no value" test).
//
// SpecQueryEngine.Query returns a SpecQueryCursor the caller iterates lazily
// (Next / Take / Count). The cursor captures the **structural** candidate set
// when it is created, then **re-validates each path against the live document on
// every step** — so a result whose list-item ancestor was removed after the
// cursor was made is silently skipped (stable against concurrent edits,
// llm_and_d4rt_tools.md §6).
//
// # Go's stand-ins for the reference's optional parameters
//
// The reference's SpecQuery is a constructor with eleven optional named
// arguments, every one of which distinguishes "not supplied" from "supplied".
// Go has neither optional parameters nor nullable value types, so SpecQuery is a
// struct whose optional dimensions are **pointers**: a nil pointer is the
// dimension being *unset* (it admits everything), a non-nil pointer is the
// dimension being *applied* — even when it points at the zero value. That
// distinction is load-bearing rather than stylistic: `SectionIDPrefix` unset
// admits every node, while `SectionIDPrefix` set to "" admits only nodes that
// *have* a section id. Kinds follows the same rule with the slice's own
// nil/empty split (nil = unset, an empty non-nil slice = "no kind is admitted"),
// which is exactly what encoding/json produces for an absent key versus `[]`.
// Regex and CaseInsensitive are plain bools because the reference declares them
// non-nullable with a `false` default.
//
// # "" as the absent string
//
// Node descriptors (class id, section id, @MapsTo, @DetailedIn, headline,
// snippet) are plain strings whose "" means "the node has none" — the same
// null-stand-in convention the rest of this port uses (see SpecResolution and
// the DocSpecs validator). The model has no way to declare an *empty* section
// id, class name or annotation target, so "" is unambiguous there.

import "strings"

// Node value-presence states, used by the SpecQuery `State` dimension.
const (
	// SpecStateFilterEmpty selects nodes that (with everything beneath them)
	// hold no value.
	SpecStateFilterEmpty = "empty"
	// SpecStateFilterNonEmpty selects nodes holding at least one value at or
	// beneath their path.
	SpecStateFilterNonEmpty = "nonEmpty"
)

// SpecStateFilter is the `state` dimension's domain — one of
// SpecStateFilterEmpty / SpecStateFilterNonEmpty. A string alias (rather than a
// defined type) so it matches the string-constant enum convention the rest of
// this package uses for SpecNodeKind and the DocSpecs rules.
type SpecStateFilter = string

// SpecStateAllFilters is the complete state vocabulary, in declaration order.
var SpecStateAllFilters = []string{SpecStateFilterEmpty, SpecStateFilterNonEmpty}

// SpecNodeProjection is a flat, value-bearing projection of one document node —
// everything the tier-1 structural/lexical index (`llm_and_d4rt_tools.md` §9.2)
// needs to index a section **without re-walking the model itself**: its path,
// kind, class, the structural facets (section id, @MapsTo / @DetailedIn), the
// headline, the searchable strings (stored values + headline), and whether it
// currently holds a value.
//
// Produced by SpecQueryEngine.ProjectNodes / SpecQueryEngine.ProjectNode, which
// reuse the same structural-closure walk and value extraction the live query
// uses — so the index and the live llm_and_d4rt_tools.md §6 search agree on what
// a node is and what text it carries — with no model (LLM) calls.
type SpecNodeProjection struct {
	// Path is the globally-unique section-id path the node lives at.
	Path string
	// Kind is what kind of node the path lands on (a SpecNodeKind* constant).
	Kind string
	// ClassID is the model class the node *is* ("" for value leaves and list
	// containers).
	ClassID string
	// SectionID is the node's @SectionId (field, class, or root), "" when none.
	SectionID string
	// MapsTo is the @MapsTo target on the node's class, "" when none.
	MapsTo string
	// DetailedIn is the @DetailedIn target on the node's class, "" when none.
	DetailedIn string
	// Headline is the node's headline — the stored one when the author set it,
	// else the model's doc comment. "" when neither exists.
	Headline string
	// SearchableStrings are the strings a text search indexes for this node:
	// stored values (content, scalar item, every form-field value) followed by
	// the headline. Empty for a container node that carries no direct value and
	// has no headline.
	SearchableStrings []string
	// HasValue reports whether the node (or anything beneath it) currently holds
	// a value — the `state` facet (empty vs non-empty).
	HasValue bool
}

// SpecQueryMatch is one node matched by a SpecQuery (the llm_and_d4rt_tools.md
// §6 cursor record).
type SpecQueryMatch struct {
	// Path is the globally-unique section-ID path the node lives at.
	Path string
	// Kind is what kind of node the path lands on (a SpecNodeKind* constant).
	Kind string
	// ClassID is the model class the node *is* ("" for value leaves and list
	// containers).
	ClassID string
	// Headline is the node's headline — stored if the author set one, else the
	// model's doc comment ("" when neither exists).
	Headline string
	// Snippet is the matched text when the query carried a `text` dimension (""
	// otherwise) — the value/headline that the pattern hit.
	Snippet string
	// MatchSpans are the spans within Snippet the `text` pattern matched (empty
	// for non-text queries).
	MatchSpans []SpecMatchSpan
}

// SpecQuery is an AND-combined lexical/structural query
// (llm_and_d4rt_tools.md §6). Every supplied dimension must hold for a node to
// match; a wholly unset query matches every node in the document's structural
// closure.
//
// See the file comment for the nil-pointer-is-unset rule the optional dimensions
// follow.
type SpecQuery struct {
	// Text is the substring (or, with Regex, the SomTextPattern) to find in
	// content + form values and the headline. nil leaves the dimension unset.
	Text *string
	// Regex treats Text as a SomTextPattern — the portable pattern subset (`.`,
	// `*`, `+`, `?`, `[…]`, `^`, `$`) — instead of a literal substring. Named
	// `regex` because that is what a caller reaches for it expecting; the
	// grammar is deliberately narrower than a full regex, and SomPatternError
	// says so rather than silently reinterpreting.
	Regex bool
	// CaseInsensitive matches Text case-insensitively (ASCII folding only).
	CaseInsensitive bool
	// Kinds are the node kinds to include (any-of). nil admits every kind; an
	// empty non-nil slice admits none.
	Kinds []string
	// ClassName is the model class name a node must *be*
	// (SpecResolution.TargetClass).
	ClassName *string
	// SectionIDExact requires the node's @SectionId to equal this exactly.
	SectionIDExact *string
	// SectionIDPrefix requires the node's @SectionId to start with this prefix.
	SectionIDPrefix *string
	// PathGlob is a glob over the node's path (`*` matches within one segment,
	// `**` across segments).
	PathGlob *string
	// MapsTo requires the node's class to carry @MapsTo(<this>).
	MapsTo *string
	// DetailedIn requires the node's class to carry @DetailedIn(<this>).
	DetailedIn *string
	// State requires the node's value-presence state to match this (a
	// SpecStateFilter* constant).
	State *SpecStateFilter
}

// SpecQueryEngine runs SpecQuerys over a (SpecModel, SpecDocument) pair,
// producing SpecQueryCursors.
type SpecQueryEngine struct {
	// Model is the meta-model describing the document's structure.
	Model *SpecModel
	// Document is the live document whose values are searched.
	Document *SpecDocument

	reflection *SpecReflection
	order      *SpecSerializationOrder
}

// NewSpecQueryEngine binds a query engine to a model and the live document it
// searches.
func NewSpecQueryEngine(model *SpecModel, document *SpecDocument) *SpecQueryEngine {
	return &SpecQueryEngine{
		Model:      model,
		Document:   document,
		reflection: NewSpecReflection(model),
		order:      NewSpecSerializationOrder(model),
	}
}

// Query builds a cursor over the nodes matching query. The structural candidate
// set is computed now (document order); value-dependent filters and path
// liveness are re-checked as the cursor advances.
//
// It returns a *SomPatternError when query.Regex is set and query.Text is not in
// the portable subset. The pattern is compiled **here**, not on first use, for
// two reasons: a malformed pattern is the caller's mistake and should surface at
// the call that made it, and a cursor that happens to visit no candidate would
// otherwise swallow the error entirely.
func (e *SpecQueryEngine) Query(query SpecQuery) (*SpecQueryCursor, error) {
	var pattern *SomTextPattern
	if query.Text != nil {
		compiled, err := e.patternFor(query)
		if err != nil {
			return nil, err
		}
		pattern = compiled
	}
	var candidates []string
	for _, path := range e.enumeratePaths() {
		resolution := e.reflection.Resolve(path)
		if resolution == nil {
			continue
		}
		if e.matchesStructural(query, resolution) {
			candidates = append(candidates, path)
		}
	}
	return &SpecQueryCursor{
		engine:         e,
		query:          query,
		pattern:        pattern,
		candidatePaths: candidates,
	}, nil
}

// --- flat node projection (tier-1 index source) -----------------------------

// ProjectNodes projects every indexable node of the live document (the
// llm_and_d4rt_tools.md §6 structural closure) as a flat SpecNodeProjection, in
// document order. Reuses the same walk and value extraction the query uses, so
// the index built from these projections and the live llm_and_d4rt_tools.md §6
// search agree on what a node is and what text it carries. Pure object-model
// traversal — no model (LLM) calls.
func (e *SpecQueryEngine) ProjectNodes() []SpecNodeProjection {
	out := []SpecNodeProjection{}
	for _, path := range e.enumeratePaths() {
		if projection := e.ProjectNode(path); projection != nil {
			out = append(out, *projection)
		}
	}
	return out
}

// ProjectNode projects the single node at path, or nil when the path no longer
// resolves against the model. Used for the index's incremental refresh: a caller
// re-projects only the changed section paths.
func (e *SpecQueryEngine) ProjectNode(path string) *SpecNodeProjection {
	resolution := e.reflection.Resolve(path)
	if resolution == nil {
		return nil
	}
	return &SpecNodeProjection{
		Path:              path,
		Kind:              resolution.Kind,
		ClassID:           classNameOf(resolution),
		SectionID:         e.sectionIDOf(resolution),
		MapsTo:            classMapsTo(resolution),
		DetailedIn:        classDetailedIn(resolution),
		Headline:          e.headlineOf(resolution),
		SearchableStrings: e.searchableStrings(resolution),
		HasValue:          e.Document.HasValuesUnder(path),
	}
}

// --- structural-closure enumeration -----------------------------------------

// enumeratePaths returns every addressable node of the document in document
// order: the root, each singular complex/section node on the spine (bounded by
// cycle detection), each list container, each *existing* list item, and every
// declared leaf.
func (e *SpecQueryEngine) enumeratePaths() []string {
	out := []string{}
	for _, root := range e.Model.Roots {
		segment := e.reflection.RootSegment(root)
		e.walk(segment, e.Model.ClassNamed(root.Type), map[string]bool{root.Type: true}, &out)
	}
	return out
}

func (e *SpecQueryEngine) walk(
	path string, cls *SpecClass, ancestorTypes map[string]bool, out *[]string,
) {
	*out = append(*out, path) // the node itself (root / complex / section container)
	if cls == nil {
		return
	}
	for _, field := range cls.Fields {
		fieldPath := SpecPathJoin(path, e.reflection.FieldSegment(field))
		switch field.Kind {
		case SpecFieldKindContent, SpecFieldKindEnum, SpecFieldKindScalar, SpecFieldKindForm:
			*out = append(*out, fieldPath) // a value leaf
		case SpecFieldKindList:
			*out = append(*out, fieldPath) // the list container node
			for _, itemPath := range e.Document.ListItems(fieldPath) {
				if field.ElementIsComplex && field.ElementType != "" &&
					!ancestorTypes[field.ElementType] {
					e.walk(itemPath, e.Model.ClassNamed(field.ElementType),
						withAncestorType(ancestorTypes, field.ElementType), out)
				} else {
					*out = append(*out, itemPath) // scalar item, or a recursive/unknown element
				}
			}
		case SpecFieldKindComplex, SpecFieldKindSection:
			if field.Type != "" && !ancestorTypes[field.Type] {
				e.walk(fieldPath, e.Model.ClassNamed(field.Type),
					withAncestorType(ancestorTypes, field.Type), out)
			} else {
				*out = append(*out, fieldPath) // recursive/unknown target: a terminal node
			}
		}
	}
}

// withAncestorType returns a copy of seen with typeName added — the reference
// spreads a new set per descent (`{...ancestorTypes, type}`), so siblings never
// see each other's additions.
func withAncestorType(seen map[string]bool, typeName string) map[string]bool {
	out := make(map[string]bool, len(seen)+1)
	for k := range seen {
		out[k] = true
	}
	out[typeName] = true
	return out
}

// --- predicates --------------------------------------------------------------

// matchesStructural applies the model-fixed dimensions (kind / class / id / path
// / mapsTo / detailedIn).
func (e *SpecQueryEngine) matchesStructural(query SpecQuery, resolution *SpecResolution) bool {
	if query.Kinds != nil && !containsString(query.Kinds, resolution.Kind) {
		return false
	}
	if query.ClassName != nil && classNameOf(resolution) != *query.ClassName {
		return false
	}

	sectionID := e.sectionIDOf(resolution)
	if query.SectionIDExact != nil && sectionID != *query.SectionIDExact {
		return false
	}
	// A node with no section id never satisfies a prefix filter — the reference
	// spells this `sectionId?.startsWith(p) ?? false`, so an unset id is a miss
	// even for an empty prefix.
	if query.SectionIDPrefix != nil &&
		!(sectionID != "" && strings.HasPrefix(sectionID, *query.SectionIDPrefix)) {
		return false
	}
	if query.PathGlob != nil && !globMatches(*query.PathGlob, resolution.Path) {
		return false
	}
	if query.MapsTo != nil && classMapsTo(resolution) != *query.MapsTo {
		return false
	}
	if query.DetailedIn != nil && classDetailedIn(resolution) != *query.DetailedIn {
		return false
	}
	return true
}

// evaluateLive applies the value-reading dimensions (text / state), re-evaluated
// against the live document. Returns the built match (with snippet/spans) or nil
// when the node no longer satisfies the query. Assumes the path is structurally
// valid.
func (e *SpecQueryEngine) evaluateLive(
	query SpecQuery, pattern *SomTextPattern, path string,
) *SpecQueryMatch {
	if !e.isLivePath(path) {
		return nil
	}
	resolution := e.reflection.Resolve(path)
	if resolution == nil {
		return nil
	}

	if query.State != nil {
		hasValue := e.Document.HasValuesUnder(path)
		wantValue := *query.State == SpecStateFilterNonEmpty
		if hasValue != wantValue {
			return nil
		}
	}

	snippet := ""
	spans := []SpecMatchSpan{}
	if pattern != nil {
		hitSnippet, hitSpans, ok := e.matchText(pattern, resolution)
		if !ok {
			return nil
		}
		snippet = hitSnippet
		spans = hitSpans
	}

	return &SpecQueryMatch{
		Path:       path,
		Kind:       resolution.Kind,
		ClassID:    classNameOf(resolution),
		Headline:   e.headlineOf(resolution),
		Snippet:    snippet,
		MatchSpans: spans,
	}
}

// matchText searches each candidate string in turn; the first that hits wins, so
// the snippet is the actual text the pattern matched.
func (e *SpecQueryEngine) matchText(
	pattern *SomTextPattern, resolution *SpecResolution,
) (string, []SpecMatchSpan, bool) {
	for _, text := range e.searchableStrings(resolution) {
		spans := pattern.AllMatches(text)
		if len(spans) > 0 {
			return text, spans, true
		}
	}
	return "", nil, false
}

// searchableStrings returns the strings a `text` query searches at resolution:
// stored values first (content leaf, scalar list item, every form field), then
// the node's headline.
//
// Form fields are emitted in the order the model **declares** them. The
// reference reads them in the document's own insertion order, which Go cannot
// reproduce — its maps have no insertion order and iterate in a randomised one —
// so the order comes from the meta-model instead, via the package's existing
// answer to "in what order do this form's fields go"
// (SpecSerializationOrder.OrderFormFields). That is also the order the reference
// actually produces, because a document's fields are written in declaration
// order; making it explicit is what keeps this port's snippet selection (first
// hit wins) and its projected searchableStrings deterministic run to run.
func (e *SpecQueryEngine) searchableStrings(resolution *SpecResolution) []string {
	out := []string{}
	path := resolution.Path
	switch resolution.Kind {
	case SpecNodeKindContent, SpecNodeKindEnumValue, SpecNodeKindScalar,
		SpecNodeKindListItemScalar:
		if value, ok := e.Document.Content(path); ok {
			out = append(out, value)
		}
	case SpecNodeKindForm:
		names := e.order.OrderFormFields(path, e.Document.FormFieldNames(path))
		for _, name := range names {
			if value, ok := e.Document.FormField(path, name); ok {
				out = append(out, value)
			}
		}
	}
	// Container nodes (root / complex / section / list / complex list item) carry
	// no direct value and fall through to the headline alone.
	if headline := e.headlineOf(resolution); headline != "" {
		out = append(out, headline)
	}
	return out
}

func (e *SpecQueryEngine) patternFor(query SpecQuery) (*SomTextPattern, error) {
	if query.Regex {
		return CompileSomTextPattern(*query.Text, query.CaseInsensitive)
	}
	return NewSomTextPatternLiteral(*query.Text, query.CaseInsensitive), nil
}

// --- path liveness (cursor stability) ---------------------------------------

// isLivePath reports whether path still exists in the live document: every
// `-<seq>` list-item segment must still be present in its parent list.
// Model-fixed segments (root, complex/section, declared leaves) are always
// structurally live, so only list items can go stale (via
// SpecDocument.RemoveListItem).
func (e *SpecQueryEngine) isLivePath(path string) bool {
	segments := SpecPathSegments(path)
	prefix := ""
	for i := 0; i < len(segments); i++ {
		previous := prefix
		if i == 0 {
			prefix = segments[i]
		} else {
			prefix = SpecPathJoin(prefix, segments[i])
		}
		split, ok := SplitListItemSegment(segments[i])
		if !ok {
			continue
		}
		listPath := split.Base
		if i != 0 {
			listPath = SpecPathJoin(previous, split.Base)
		}
		resolution := e.reflection.Resolve(listPath)
		if resolution != nil && resolution.Kind == SpecNodeKindList &&
			!containsString(e.Document.ListItems(listPath), prefix) {
			return false
		}
	}
	return true
}

// --- node descriptors --------------------------------------------------------

func (e *SpecQueryEngine) sectionIDOf(resolution *SpecResolution) string {
	if resolution.Field != nil && resolution.Field.SectionID != "" {
		return resolution.Field.SectionID
	}
	if resolution.TargetClass != nil && resolution.TargetClass.SectionID != "" {
		return resolution.TargetClass.SectionID
	}
	if resolution.Root != nil {
		return resolution.Root.SectionID
	}
	return ""
}

// headlineOf returns the headline a node actually shows: the document's
// **stored** headline when the author set one, otherwise the model's doc
// comment.
//
// The stored value comes first because it is the one a reader sees and the one
// an author would search for. Consulting only the doc comment made renamed
// sections unfindable — SetHeadline("DEMO/SUM", "Executive Summary") stored text
// that no query could reach and that never entered the search index built from
// ProjectNodes.
func (e *SpecQueryEngine) headlineOf(resolution *SpecResolution) string {
	if stored, ok := e.Document.Headline(resolution.Path); ok {
		return stored
	}
	if resolution.Field != nil && resolution.Field.Doc != "" {
		return resolution.Field.Doc
	}
	if resolution.TargetClass != nil && resolution.TargetClass.Doc != "" {
		return resolution.TargetClass.Doc
	}
	if resolution.Kind == SpecNodeKindRoot && resolution.Root != nil {
		return resolution.Root.Description
	}
	return ""
}

func classNameOf(resolution *SpecResolution) string {
	if resolution.TargetClass == nil {
		return ""
	}
	return resolution.TargetClass.Name
}

func classMapsTo(resolution *SpecResolution) string {
	if resolution.TargetClass == nil {
		return ""
	}
	return resolution.TargetClass.MapsTo
}

func classDetailedIn(resolution *SpecResolution) string {
	if resolution.TargetClass == nil {
		return ""
	}
	return resolution.TargetClass.DetailedIn
}

func containsString(haystack []string, needle string) bool {
	for _, v := range haystack {
		if v == needle {
			return true
		}
	}
	return false
}

// --- path globbing -----------------------------------------------------------

// globMatches matches a glob over a whole path: `**` spans `/`, a single `*`
// stays within one segment, every other character is literal.
//
// Matched directly rather than compiled to a regex, because two of the nine
// runtimes have no regex engine and because a wildcard walk is a smaller, more
// obviously identical thing to transcribe than an escaping rule plus somebody
// else's matcher (see spec_text_pattern.go — and here too Go's own RE2 would be
// the wrong matcher to delegate to). Code units, like the pattern matcher, so
// the two agree on what "one character" is.
func globMatches(glob, path string) bool {
	return globAt(utf16Units(glob), 0, utf16Units(path), 0)
}

// globAt is a greedy wildcard walk with backtracking: at a `*`/`**` try the
// longest remaining span first and give characters back until the tail fits.
func globAt(glob []uint16, g int, path []uint16, p int) bool {
	for g < len(glob) {
		if glob[g] != globAsterisk {
			if p >= len(path) || path[p] != glob[g] {
				return false
			}
			g++
			p++
			continue
		}
		crossesSegments := g+1 < len(glob) && glob[g+1] == globAsterisk
		afterWildcard := g + 1
		if crossesSegments {
			afterWildcard = g + 2
		}
		// Longest first, so `*` behaves greedily exactly as the regex did.
		limit := len(path)
		if !crossesSegments {
			for i := p; i < len(path); i++ {
				if path[i] == globSlash {
					limit = i
					break
				}
			}
		}
		for take := limit; take >= p; take-- {
			if globAt(glob, afterWildcard, path, take) {
				return true
			}
		}
		return false
	}
	return p == len(path)
}

const (
	globAsterisk uint16 = 0x2A // *
	globSlash    uint16 = 0x2F // /
)

// SpecQueryCursor is a lazy, forward-only cursor over the nodes matching a
// SpecQuery (llm_and_d4rt_tools.md §6).
//
// The cursor holds the structural candidate paths captured when it was created;
// each step re-validates the path against the **live** document and re-applies
// the value-dependent filters, so concurrent edits never surface stale or
// newly-mismatching results. It is forward-only: Next / Take consume matches;
// Count peeks the remaining matches without consuming.
type SpecQueryCursor struct {
	engine *SpecQueryEngine
	query  SpecQuery

	// pattern is the query's `text` dimension, compiled once when the cursor was
	// built. nil when the query has no text dimension at all.
	pattern        *SomTextPattern
	candidatePaths []string
	position       int
}

// Next returns the next matching node, or nil when the cursor is exhausted.
// Skips candidates whose path went stale or no longer satisfies the live
// filters.
func (c *SpecQueryCursor) Next() *SpecQueryMatch {
	for c.position < len(c.candidatePaths) {
		path := c.candidatePaths[c.position]
		c.position++
		if match := c.engine.evaluateLive(c.query, c.pattern, path); match != nil {
			return match
		}
	}
	return nil
}

// Take returns up to n further matches (fewer when the cursor is exhausted
// first).
func (c *SpecQueryCursor) Take(n int) []SpecQueryMatch {
	out := []SpecQueryMatch{}
	for i := 0; i < n; i++ {
		match := c.Next()
		if match == nil {
			break
		}
		out = append(out, *match)
	}
	return out
}

// ToList returns every remaining match, draining the cursor.
func (c *SpecQueryCursor) ToList() []SpecQueryMatch {
	out := []SpecQueryMatch{}
	for {
		match := c.Next()
		if match == nil {
			return out
		}
		out = append(out, *match)
	}
}

// Count reports how many matches remain from the current position, without
// consuming any. Re-validates each remaining candidate against the live
// document, so the count reflects the document as it is *now* — it is not the
// candidate count, and after a Take it is smaller than it was.
func (c *SpecQueryCursor) Count() int {
	remaining := 0
	for i := c.position; i < len(c.candidatePaths); i++ {
		if c.engine.evaluateLive(c.query, c.pattern, c.candidatePaths[i]) != nil {
			remaining++
		}
	}
	return remaining
}
