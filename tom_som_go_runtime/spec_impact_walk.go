package somruntime

// spec_impact_walk.go — the impact walk: the starting table of a change's
// impact evaluation (the change mode of the `tom_specs` process, Phase 0 step
// `impact`). A faithful port of
// `tom_som_typescript_runtime/src/spec_impact_walk.ts`.
//
// For a specification it lists every section of every document root of the
// model, filled or not, and roots the project never created as well: each row
// with its section-id chain, its model class, whether it holds values, and its
// CodeSpecs routing. Beside it, SpecImpactLevel records how far the project
// has come (documents, extracts, IR, tests, code).
//
// Rows: one per class node (the root, each `complex` / `section` field, each
// list item) and one per list (with its item count). An empty list of a class
// element gets one template row `<list>/*` with the element's subtree below
// it. Value leaves (content, form fields) are counted in their row, not rows of
// their own. A class already on the branch is not entered again. Below a
// `@FollowUpKind` section every row carries that routing.
//
// Pure: it reads a model and documents and writes nothing. Pinned by
// `tom_som_conformance/corpus/impact_walk_cases.json`.

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// The kinds of an impact-walk row (SpecImpactRow.Kind).
const (
	// SpecImpactRowKindRoot is the document root.
	SpecImpactRowKindRoot = "root"
	// SpecImpactRowKindComplex is a `complex` field's class node.
	SpecImpactRowKindComplex = "complex"
	// SpecImpactRowKindSection is a `section` field's class node.
	SpecImpactRowKindSection = "section"
	// SpecImpactRowKindList is a list field (its items are rows of their own).
	SpecImpactRowKindList = "list"
	// SpecImpactRowKindItem is one item of a list of class elements.
	SpecImpactRowKindItem = "item"
	// SpecImpactRowKindTemplate is the element class of an empty list, at
	// `<list>/*`: what a new item holds.
	SpecImpactRowKindTemplate = "template"
)

// SpecImpactRow is one row of the impact walk.
type SpecImpactRow struct {
	// Path is the document path; a template's subtree has `*` for the item
	// segment.
	Path string
	// Chain is the section-id chain, outer first, joined by ` > ` (a list item
	// by its stored id).
	Chain string
	// Kind is one of the SpecImpactRowKind* constants.
	Kind string
	// ClassName is the model class; for a list, its element class ("" for a
	// list of scalars).
	ClassName string
	// Depth is the nesting below the root (the root is 0).
	Depth int
	// Filled reports whether the document holds anything at or below Path.
	Filled bool
	// Values counts the stored values at or below Path: content leaves plus
	// form-field values.
	Values int
	// Items is a list's item count; nil for every other row.
	Items *int
	// Routing is the CodeSpecs routing verdict (a CodeSpecsVerdict* constant).
	Routing string
	// RoutingValues are the routing's values verbatim.
	RoutingValues []string
	// RoutingDeclaredAt is where the routing marker is declared (`Class` or
	// `Class.field`); "" when none.
	RoutingDeclaredAt string
}

// ToJSON returns the row in the reference's JSON shape (camelCase keys).
func (r SpecImpactRow) ToJSON() map[string]any {
	var items any
	if r.Items != nil {
		items = *r.Items
	}
	return map[string]any{
		"path":              r.Path,
		"chain":             r.Chain,
		"kind":              r.Kind,
		"className":         r.ClassName,
		"depth":             r.Depth,
		"filled":            r.Filled,
		"values":            r.Values,
		"items":             items,
		"routing":           r.Routing,
		"routingValues":     nonNilStrings(r.RoutingValues),
		"routingDeclaredAt": r.RoutingDeclaredAt,
	}
}

// SpecImpactRootWalk is the walk of one document root.
type SpecImpactRootWalk struct {
	// Type is the root's model type, e.g. `D00SolutionBlueprint`.
	Type string
	// SectionID is the root's section id (its first path segment).
	SectionID string
	// Present reports whether the specification has this document; an absent
	// root is walked over an empty document.
	Present bool
	Rows    []SpecImpactRow
}

// ToJSON returns the root walk in the reference's JSON shape.
func (w SpecImpactRootWalk) ToJSON() map[string]any {
	rows := make([]any, 0, len(w.Rows))
	for _, r := range w.Rows {
		rows = append(rows, r.ToJSON())
	}
	return map[string]any{
		"type":      w.Type,
		"sectionId": w.SectionID,
		"present":   w.Present,
		"rows":      rows,
	}
}

// SpecImpactWalk walks every document root of model, in model order: a root
// present in documents (keyed by root type) over its document, any other over
// an empty one. A document keyed by a type the model has no root for is
// refused with an error.
func SpecImpactWalk(model *SpecModel, documents map[string]*SpecDocument) ([]SpecImpactRootWalk, error) {
	for _, typ := range sortedKeys(documents) {
		known := false
		for _, r := range model.Roots {
			if r.Type == typ {
				known = true
				break
			}
		}
		if !known {
			return nil, fmt.Errorf("spec_impact_walk: the model has no document root %s", typ)
		}
	}
	refl := NewSpecReflection(model)
	out := make([]SpecImpactRootWalk, 0, len(model.Roots))
	for _, root := range model.Roots {
		doc, present := documents[root.Type]
		if doc == nil {
			present = false
			doc = NewSpecDocument()
		}
		w := newImpactWalker(model, refl, doc)
		out = append(out, SpecImpactRootWalk{
			Type:      root.Type,
			SectionID: refl.RootSegment(root),
			Present:   present,
			Rows:      w.walkRoot(root),
		})
	}
	return out, nil
}

func sortedKeys(m map[string]*SpecDocument) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}

func nonNilStrings(s []string) []string {
	if s == nil {
		return []string{}
	}
	return s
}

type impactWalker struct {
	model  *SpecModel
	refl   *SpecReflection
	doc    *SpecDocument
	rows   []SpecImpactRow
	counts map[string]int
}

func newImpactWalker(model *SpecModel, refl *SpecReflection, doc *SpecDocument) *impactWalker {
	w := &impactWalker{model: model, refl: refl, doc: doc, rows: []SpecImpactRow{}, counts: map[string]int{}}
	for _, p := range doc.ContentPaths() {
		if _, ok := doc.Content(p); ok {
			w.count(p)
		}
	}
	for _, p := range doc.FormPaths() {
		for _, f := range doc.FormFieldNames(p) {
			if _, ok := doc.FormField(p, f); ok {
				w.count(p)
			}
		}
	}
	return w
}

// count adds one value at path to the path and each of its prefixes ending
// before `/` or `-`.
func (w *impactWalker) count(path string) {
	w.counts[path]++
	for i := len(path) - 1; i > 0; i-- {
		if path[i] == '/' || path[i] == '-' {
			w.counts[path[:i]]++
		}
	}
}

func (w *impactWalker) walkRoot(root *SpecRoot) []SpecImpactRow {
	cls := w.model.ClassNamed(root.Type)
	if cls == nil {
		return w.rows
	}
	segment := w.refl.RootSegment(root)
	w.classNode(SpecImpactRowKindRoot, segment, segment, cls, 0, map[string]bool{cls.Name: true}, nil)
	return w.rows
}

func withAncestor(ancestors map[string]bool, name string) map[string]bool {
	next := make(map[string]bool, len(ancestors)+1)
	for k := range ancestors {
		next[k] = true
	}
	next[name] = true
	return next
}

func (w *impactWalker) classNode(kind, path, chain string, cls *SpecClass, depth int,
	ancestors map[string]bool, process *CodeSpecsRouting) {
	template := strings.Contains(path, "*")
	routing := CodeSpecsClassRouting(cls, path)
	if process != nil {
		routing = *process
	}
	var below *CodeSpecsRouting
	if routing.Verdict == CodeSpecsVerdictFeedsProcess {
		r := routing
		below = &r
	}
	values := 0
	if !template {
		values = w.counts[path]
	}
	w.rows = append(w.rows, SpecImpactRow{
		Path:              path,
		Chain:             chain,
		Kind:              kind,
		ClassName:         cls.Name,
		Depth:             depth,
		Filled:            !template && w.doc.HasValuesUnder(path),
		Values:            values,
		Routing:           routing.Verdict,
		RoutingValues:     routing.Values,
		RoutingDeclaredAt: routing.DeclaredAt,
	})
	for _, field := range cls.Fields {
		segment := w.refl.FieldSegment(field)
		fieldPath := SpecPathJoin(path, segment)
		fieldChain := chain + " > " + segment
		switch field.Kind {
		case SpecFieldKindComplex, SpecFieldKindSection:
			if child := w.enter(field.Type, ancestors); child != nil {
				childKind := SpecImpactRowKindSection
				if field.Kind == SpecFieldKindComplex {
					childKind = SpecImpactRowKindComplex
				}
				w.classNode(childKind, fieldPath, fieldChain, child, depth+1,
					withAncestor(ancestors, child.Name), below)
			}
		case SpecFieldKindList:
			w.list(cls, field, fieldPath, fieldChain, depth+1, ancestors, below)
		}
	}
}

func (w *impactWalker) list(owner *SpecClass, field *SpecField, path, chain string, depth int,
	ancestors map[string]bool, process *CodeSpecsRouting) {
	template := strings.Contains(path, "*")
	var items []string
	if !template {
		items = w.doc.ListItems(path)
	}
	var element *SpecClass
	if field.ElementIsComplex {
		element = w.model.ClassNamed(field.ElementType)
	}
	var routing CodeSpecsRouting
	switch {
	case process != nil:
		routing = *process
	case element != nil:
		routing = CodeSpecsClassRouting(element, path)
	default:
		if fr := CodeSpecsFieldRouting(owner, field); fr != nil {
			routing = *fr
		} else {
			routing = CodeSpecsClassRouting(owner, path)
		}
	}
	className := ""
	if element != nil {
		className = element.Name
	}
	values := 0
	if !template {
		values = w.counts[path]
	}
	n := len(items)
	w.rows = append(w.rows, SpecImpactRow{
		Path:              path,
		Chain:             chain,
		Kind:              SpecImpactRowKindList,
		ClassName:         className,
		Depth:             depth,
		Filled:            !template && w.doc.HasValuesUnder(path),
		Values:            values,
		Items:             &n,
		Routing:           routing.Verdict,
		RoutingValues:     routing.Values,
		RoutingDeclaredAt: routing.DeclaredAt,
	})
	if element == nil || ancestors[element.Name] {
		return
	}
	next := withAncestor(ancestors, element.Name)
	if n == 0 {
		w.classNode(SpecImpactRowKindTemplate, path+"/*", chain+" > *", element, depth+1, next, process)
		return
	}
	for _, itemPath := range items {
		id, ok := w.doc.ItemSectionID(itemPath)
		if !ok {
			id = itemPath[strings.LastIndex(itemPath, "/")+1:]
		}
		w.classNode(SpecImpactRowKindItem, itemPath, chain+" > "+id, element, depth+1, next, process)
	}
}

func (w *impactWalker) enter(typ string, ancestors map[string]bool) *SpecClass {
	if typ == "" || ancestors[typ] {
		return nil
	}
	return w.model.ClassNamed(typ)
}

// --- the project's level -----------------------------------------------------

// SpecImpactFolder is a folder the caller passed for tests or code, and
// whether it exists.
type SpecImpactFolder struct {
	Path    string `json:"path"`
	Present bool   `json:"present"`
}

// SpecImpactDocumentLevel is one document root of SpecImpactLevel.Documents.
type SpecImpactDocumentLevel struct {
	Type      string `json:"type"`
	SectionID string `json:"sectionId"`
	Present   bool   `json:"present"`
}

// SpecImpactLevel is how far the project has come (impact_evaluation.md §
// Level).
type SpecImpactLevel struct {
	// Documents lists every document root: whether the specification has it.
	Documents []SpecImpactDocumentLevel
	// ProjectIdea reports whether `phase1_project_idea/` holds a Markdown file.
	ProjectIdea bool
	// Extracts counts `CE-*.extract.yaml` files in
	// `generated-doc/codespecs_extracts/`.
	Extracts int
	// GateRecord reports whether
	// `generated-doc/codespecs_extracts/gate.verdicts.yaml` exists.
	GateRecord bool
	// IR counts `*.ir.yaml` files in `irspecs/`.
	IR int
	// Gates are the gate checklists and reports under `gates/` and
	// `quality/evidence/gates/`.
	Gates []string
	// Tests are the test folders the caller passed; nil: none given.
	Tests []SpecImpactFolder
	// Code are the code folders the caller passed; nil: none given.
	Code []SpecImpactFolder
	// PhasesReached are the phases (1–6) the project has reached.
	PhasesReached []int
	// PhasesLeftOut are the phases (1–6) it has not, which a change leaves out.
	PhasesLeftOut []int
}

// ToJSON returns the level in the reference's JSON shape (camelCase keys;
// tests / code null when not given).
func (l SpecImpactLevel) ToJSON() map[string]any {
	docs := make([]any, 0, len(l.Documents))
	for _, d := range l.Documents {
		docs = append(docs, map[string]any{"type": d.Type, "sectionId": d.SectionID, "present": d.Present})
	}
	folders := func(f []SpecImpactFolder) any {
		if f == nil {
			return nil
		}
		out := make([]any, 0, len(f))
		for _, x := range f {
			out = append(out, map[string]any{"path": x.Path, "present": x.Present})
		}
		return out
	}
	ints := func(s []int) []int {
		if s == nil {
			return []int{}
		}
		return s
	}
	return map[string]any{
		"documents":     docs,
		"projectIdea":   l.ProjectIdea,
		"extracts":      l.Extracts,
		"gateRecord":    l.GateRecord,
		"ir":            l.IR,
		"gates":         nonNilStrings(l.Gates),
		"tests":         folders(l.Tests),
		"code":          folders(l.Code),
		"phasesReached": ints(l.PhasesReached),
		"phasesLeftOut": ints(l.PhasesLeftOut),
	}
}

var (
	impactProjectIdeaRe = regexp.MustCompile(`^phase1_[^/]*/[^/]+\.md$`)
	impactExtractRe     = regexp.MustCompile(`^generated-doc/codespecs_extracts/CE-[^/]+\.extract\.yaml$`)
	impactIRRe          = regexp.MustCompile(`^irspecs/[^/]+\.ir\.yaml$`)
	impactGateRe        = regexp.MustCompile(`^gates/G[^/]*\.checklist\.yaml$`)
	impactGateReportRe  = regexp.MustCompile(`^quality/evidence/gates/[^/]+\.md$`)
	impactDocumentRe    = regexp.MustCompile(`^phase[^/]*/[^/]+\.docspecs\.yaml$`)
)

// impactNormalize turns a listing entry `/`-separated and drops one leading
// `./`.
func impactNormalize(listing []string) []string {
	out := make([]string, 0, len(listing))
	for _, p := range listing {
		out = append(out, strings.TrimPrefix(strings.ReplaceAll(p, "\\", "/"), "./"))
	}
	return out
}

// SpecImpactLevel returns the project's level from the walk and a listing of
// the spec root (paths relative to it, `/`-separated). Phase 2 is reached when
// the root with section id `SBP` is present, Phase 3 when any other root is
// that is not a generation input, Phase 4 when extracts or IR exist, Phases 5
// and 6 when a test or code folder the caller passed exists. Phases 7–8 are
// not visible on disk and are not reported.
func SpecImpactLevelOf(model *SpecModel, walk []SpecImpactRootWalk, listing []string,
	tests, code []SpecImpactFolder) SpecImpactLevel {
	files := impactNormalize(listing)
	docs := make([]SpecImpactDocumentLevel, 0, len(walk))
	for _, w := range walk {
		docs = append(docs, SpecImpactDocumentLevel{Type: w.Type, SectionID: w.SectionID, Present: w.Present})
	}
	projectIdea := false
	extracts, ir := 0, 0
	gateRecord := false
	gates := []string{}
	for _, f := range files {
		if impactProjectIdeaRe.MatchString(f) {
			projectIdea = true
		}
		if impactExtractRe.MatchString(f) {
			extracts++
		}
		if f == "generated-doc/codespecs_extracts/gate.verdicts.yaml" {
			gateRecord = true
		}
		if impactIRRe.MatchString(f) {
			ir++
		}
		if impactGateRe.MatchString(f) || impactGateReportRe.MatchString(f) {
			gates = append(gates, f)
		}
	}
	sort.Strings(gates)
	present := func(test func(root *SpecRoot) bool) bool {
		for _, w := range walk {
			if !w.Present {
				continue
			}
			for _, r := range model.Roots {
				if r.Type == w.Type {
					if test(r) {
						return true
					}
					break
				}
			}
		}
		return false
	}
	anyPresent := func(f []SpecImpactFolder) bool {
		for _, x := range f {
			if x.Present {
				return true
			}
		}
		return false
	}
	reached := []int{}
	if projectIdea {
		reached = append(reached, 1)
	}
	if present(func(r *SpecRoot) bool { return r.SectionID == "SBP" }) {
		reached = append(reached, 2)
	}
	if present(func(r *SpecRoot) bool { return r.SectionID != "SBP" && !model.IsGenerationInput(r) }) {
		reached = append(reached, 3)
	}
	if extracts > 0 || ir > 0 {
		reached = append(reached, 4)
	}
	if tests != nil && anyPresent(tests) {
		reached = append(reached, 5)
	}
	if code != nil && anyPresent(code) {
		reached = append(reached, 6)
	}
	leftOut := []int{}
	for p := 1; p <= 6; p++ {
		hit := false
		for _, r := range reached {
			if r == p {
				hit = true
			}
		}
		if !hit {
			leftOut = append(leftOut, p)
		}
	}
	return SpecImpactLevel{
		Documents:     docs,
		ProjectIdea:   projectIdea,
		Extracts:      extracts,
		GateRecord:    gateRecord,
		IR:            ir,
		Gates:         gates,
		Tests:         tests,
		Code:          code,
		PhasesReached: reached,
		PhasesLeftOut: leftOut,
	}
}

// SpecImpactDocumentFiles returns the specification's current documents in a
// listing of the spec root: the `*.docspecs.yaml` files directly in a `phase*`
// folder, sorted. The numbered step folders below hold round copies and are
// not the specification.
func SpecImpactDocumentFiles(listing []string) []string {
	out := []string{}
	for _, f := range impactNormalize(listing) {
		if impactDocumentRe.MatchString(f) {
			out = append(out, f)
		}
	}
	sort.Strings(out)
	return out
}

// --- the Markdown table ------------------------------------------------------

func impactCell(text string) string {
	return strings.ReplaceAll(text, "|", "\\|")
}

// SpecImpactWalkMarkdown renders the walk as Markdown, for a round folder's
// `walk/` (one table per root, then § Level): the table the change analyst
// gives verdicts to. level may be nil.
func SpecImpactWalkMarkdown(walk []SpecImpactRootWalk, level *SpecImpactLevel) string {
	out := []string{"# Impact walk", ""}
	out = append(out,
		"Every section of every document root, filled or not: the section-id chain, the model class, whether it holds values, and its CodeSpecs routing. "+
			"A list counts its items; an empty list of sections shows what a new item holds at `<list>/*`.",
		"",
	)
	for _, root := range walk {
		filled := 0
		for _, r := range root.Rows {
			if r.Filled {
				filled++
			}
		}
		absent := ""
		if !root.Present {
			absent = " (absent)"
		}
		out = append(out,
			"## "+root.SectionID+" — "+root.Type+absent,
			"",
			strconv.Itoa(len(root.Rows))+" rows, "+strconv.Itoa(filled)+" holding values.",
			"",
			"| Section-id chain | Path | Kind | Class | Values | Items | Routing |",
			"| --- | --- | --- | --- | --- | --- | --- |",
		)
		for _, r := range root.Rows {
			routing := r.Routing
			if len(r.RoutingValues) > 0 {
				routing = r.Routing + ": " + strings.Join(r.RoutingValues, ", ")
			}
			values := "—"
			if r.Filled {
				values = strconv.Itoa(r.Values)
			}
			items := ""
			if r.Items != nil {
				items = strconv.Itoa(*r.Items)
			}
			out = append(out, "| "+impactCell(r.Chain)+" | `"+impactCell(r.Path)+"` | "+r.Kind+" | "+
				impactCell(r.ClassName)+" | "+values+" | "+items+" | "+impactCell(routing)+" |")
		}
		out = append(out, "")
	}
	if level != nil {
		yes := func(b bool) string {
			if b {
				return "yes"
			}
			return "no"
		}
		folders := func(f []SpecImpactFolder) string {
			if f == nil {
				return "not given"
			}
			if len(f) == 0 {
				return "none"
			}
			parts := make([]string, 0, len(f))
			for _, x := range f {
				state := "absent"
				if x.Present {
					state = "present"
				}
				parts = append(parts, "`"+x.Path+"` ("+state+")")
			}
			return strings.Join(parts, ", ")
		}
		orNone := func(s string) string {
			if s == "" {
				return "none"
			}
			return s
		}
		var presentDocs, absentDocs []string
		for _, d := range level.Documents {
			if d.Present {
				presentDocs = append(presentDocs, d.SectionID)
			} else {
				absentDocs = append(absentDocs, d.SectionID)
			}
		}
		gates := "none"
		if len(level.Gates) > 0 {
			parts := make([]string, 0, len(level.Gates))
			for _, g := range level.Gates {
				parts = append(parts, "`"+g+"`")
			}
			gates = strings.Join(parts, ", ")
		}
		joinInts := func(s []int) string {
			parts := make([]string, 0, len(s))
			for _, n := range s {
				parts = append(parts, strconv.Itoa(n))
			}
			return strings.Join(parts, ", ")
		}
		out = append(out, "## Level", "")
		out = append(out,
			"- Documents present: "+orNone(strings.Join(presentDocs, ", ")),
			"- Documents absent: "+orNone(strings.Join(absentDocs, ", ")),
			"- Project Idea: "+yes(level.ProjectIdea),
			"- CodeSpecs extracts: "+strconv.Itoa(level.Extracts)+"; gate record: "+yes(level.GateRecord),
			"- IR Specs: "+strconv.Itoa(level.IR),
			"- Gates: "+gates,
			"- Tests: "+folders(level.Tests),
			"- Code: "+folders(level.Code),
			"- Phases reached: "+orNone(joinInts(level.PhasesReached))+"; left out by a change: "+
				orNone(joinInts(level.PhasesLeftOut))+" (Phases 7–8 are not visible on disk)",
			"",
		)
	}
	return strings.Join(out, "\n")
}
