package somruntime

// spec_document_set.go — a project's specification documents read side by
// side, one per root, and the validation of the set (`tom_specs_model_rules.md`
// §9.7): the places a Phase 3 document shares with the Solution Blueprint
// agree, element by element and value by value, and the links that cross two
// documents hold.
//
// The documents are never assembled into one: each keeps its own registry, and
// every finding names the document a place is in. SyncReport writes nothing;
// RenameID renames an id in every document at once.
//
// A port of `tom_som_dart_runtime/lib/src/spec_document_set.dart` (and the
// TypeScript, JavaScript and Python `spec_document_set` modules). The
// comparison internals (SpecSetCheck, SpecSetSide) are what Backfill and
// Prefill read.

import (
	"math"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// --- the vocabulary of the set ------------------------------------------------

// What a finding of the set reports (in the order the report sorts by; the
// corpus compares the string values).
const (
	// SpecSyncCodeSharedValueDiffers: both documents hold the shared place,
	// and the values differ.
	SpecSyncCodeSharedValueDiffers = "sharedValueDiffers"
	// SpecSyncCodeSharedValueMissing: the Phase 3 document fills a shared
	// place the Blueprint leaves empty.
	SpecSyncCodeSharedValueMissing = "sharedValueMissing"
	// SpecSyncCodeSharedValueOnlyInBlueprint: the Blueprint fills a shared
	// place the Phase 3 document leaves empty; the Phase 3 document emptied
	// it, so Backfill clears it.
	SpecSyncCodeSharedValueOnlyInBlueprint = "sharedValueOnlyInBlueprint"
	// SpecSyncCodeSharedElementMissing: an element of an `equal` list (or an
	// id of an `equal` reference field) is only in the Phase 3 document.
	SpecSyncCodeSharedElementMissing = "sharedElementMissing"
	// SpecSyncCodeSharedElementOnlyInBlueprint: an element (or id) is only in
	// the Blueprint, under `equal` or `subset`; Backfill removes it.
	SpecSyncCodeSharedElementOnlyInBlueprint = "sharedElementOnlyInBlueprint"
	// SpecSyncCodeSharedElementMayBeAdded: under `subset`, an element (or id)
	// only in the Phase 3 document: it may be added to the Blueprint, and is
	// not carried in.
	SpecSyncCodeSharedElementMayBeAdded = "sharedElementMayBeAdded"
	// SpecSyncCodeCrossSummaryMismatch: a `@SummaryOf(document:)` whose
	// summary and detail sit in two documents does not hold.
	SpecSyncCodeCrossSummaryMismatch = "crossSummaryMismatch"
	// SpecSyncCodeCrossInverseMissing: an `inverseOf` whose two ends sit in
	// two documents is one-sided.
	SpecSyncCodeCrossInverseMissing = "crossInverseMissing"
	// SpecSyncCodePendingReview: a value holding pending change marks, listed
	// for the user.
	SpecSyncCodePendingReview = "pendingReview"
	// SpecSyncCodeUnmarkable: a change DeriveFields would write in a document
	// under review that cannot be marked exactly.
	SpecSyncCodeUnmarkable = "unmarkable"
)

// SpecSyncCodes is every SpecSyncCode, in declaration order.
var SpecSyncCodes = []string{
	SpecSyncCodeSharedValueDiffers,
	SpecSyncCodeSharedValueMissing,
	SpecSyncCodeSharedValueOnlyInBlueprint,
	SpecSyncCodeSharedElementMissing,
	SpecSyncCodeSharedElementOnlyInBlueprint,
	SpecSyncCodeSharedElementMayBeAdded,
	SpecSyncCodeCrossSummaryMismatch,
	SpecSyncCodeCrossInverseMissing,
	SpecSyncCodePendingReview,
	SpecSyncCodeUnmarkable,
}

// SpecSyncCodeIndex is the position of code in the declaration order (-1 when
// unknown).
func SpecSyncCodeIndex(code string) int {
	for i, c := range SpecSyncCodes {
		if c == code {
			return i
		}
	}
	return -1
}

// How a finding of the set is resolved.
const (
	// SpecSyncResolutionBackfill: Backfill resolves it, writing the Blueprint.
	SpecSyncResolutionBackfill = "backfill"
	// SpecSyncResolutionDeriveFields: DeriveFields resolves it.
	SpecSyncResolutionDeriveFields = "deriveFields"
	// SpecSyncResolutionAgent: the agent decides (or asks the user).
	SpecSyncResolutionAgent = "agent"
	// SpecSyncResolutionInfo: reported, not a finding: it does not hold up a
	// gate.
	SpecSyncResolutionInfo = "info"
)

// SpecSyncResolutions is every SpecSyncResolution, in declaration order.
var SpecSyncResolutions = []string{
	SpecSyncResolutionBackfill,
	SpecSyncResolutionDeriveFields,
	SpecSyncResolutionAgent,
	SpecSyncResolutionInfo,
}

// Which document holds a shared place's value.
const (
	// SpecSyncHolderDetail: the Phase 3 document (the default).
	SpecSyncHolderDetail = "detail"
	// SpecSyncHolderBlueprint: the Blueprint (`@SyncedWith(heldHere:)`).
	SpecSyncHolderBlueprint = "blueprint"
)

// Why a document set cannot be built.
const (
	// SpecDocumentSetRefusalSameRoot: two documents populate one root.
	SpecDocumentSetRefusalSameRoot = "sameRoot"
	// SpecDocumentSetRefusalNoRoot: a document populates no root.
	SpecDocumentSetRefusalNoRoot = "noRoot"
	// SpecDocumentSetRefusalTwoRoots: a document populates two roots.
	SpecDocumentSetRefusalTwoRoots = "twoRoots"
	// SpecDocumentSetRefusalProjection: a document is the CodeSpecs
	// projection, which is no specification.
	SpecDocumentSetRefusalProjection = "projection"
	// SpecDocumentSetRefusalOverlap: fragments of one root overlap.
	SpecDocumentSetRefusalOverlap = "overlap"
	// SpecDocumentSetRefusalUnpairable: a synced class's positions in the
	// Blueprint and its document cannot be paired (invariant
	// `SHARED-ANCHOR`).
	SpecDocumentSetRefusalUnpairable = "unpairable"
)

// SpecDocumentSetError is a document set that cannot be built, with the
// documents it names.
type SpecDocumentSetError struct {
	// Refusal is why (a SpecDocumentSetRefusal constant).
	Refusal string
	// Documents are the documents (or fragments) concerned, in the order
	// given.
	Documents []string
	// Message is the prose for the reader.
	Message string
	// ClassName is, for SpecDocumentSetRefusalUnpairable, the class; "" else.
	ClassName string
}

// Error implements the error interface.
func (e *SpecDocumentSetError) Error() string {
	return "SpecDocumentSetError(" + e.Refusal + "): " + e.Message
}

// ToJSON is the canonical JSON form the corpus compares (no message).
func (e *SpecDocumentSetError) ToJSON() map[string]any {
	out := map[string]any{"refusal": e.Refusal, "documents": stringsJSON(e.Documents)}
	if e.ClassName != "" {
		out["className"] = e.ClassName
	}
	return out
}

// SpecSyncPair is a class kept in sync between the Blueprint and a Phase 3
// document: its position in each root.
type SpecSyncPair struct {
	// ClassName is the class carrying `@SyncedWith` / `@DetailedIn`.
	ClassName string
	// SectionID is its section id: the name of the pair in findings and
	// filters.
	SectionID string
	// BlueprintAnchor is the anchor in the Blueprint root (list items written
	// `<list>-*`).
	BlueprintAnchor string
	// DetailAnchor is the anchor in the Phase 3 root.
	DetailAnchor string
	// DetailRoot is the Phase 3 root's class name.
	DetailRoot string
	// Sync is the class's `@SyncedWith`, or nil when only `@DetailedIn` is
	// declared.
	Sync *SpecSync
}

// ToJSON is the canonical JSON form.
func (p *SpecSyncPair) ToJSON() map[string]any {
	return map[string]any{
		"pair":       p.SectionID,
		"className":  p.ClassName,
		"blueprint":  p.BlueprintAnchor,
		"detail":     p.DetailAnchor,
		"detailRoot": p.DetailRoot,
	}
}

// SpecNamedDocument is a document with the name the tools use for it (its
// file name).
type SpecNamedDocument struct {
	Name     string
	Document *SpecDocument
}

// --- the set ------------------------------------------------------------------

// SpecDocumentSet is a project's specification documents, one per root, read
// side by side.
type SpecDocumentSet struct {
	// Model is the model the set is read with.
	Model *SpecModel
	// Refl is the model's reflection.
	Refl *SpecReflection
	// BlueprintRoot is the Blueprint's root class name: the root the others
	// are `basedOn`; "" when the model names none.
	BlueprintRoot string

	documents map[string]*SpecDocument
	rootOf    map[string]string
	order     []string
	pairs     []*SpecSyncPair
}

// NewSpecDocumentSet builds a set of documents, each named by the file name
// the tools use. Each document populates exactly one root; two documents of
// one root, a document with no populated root or with two, and the CodeSpecs
// projection are refused with a *SpecDocumentSetError naming the documents, as
// is a model whose synced positions cannot be paired.
func NewSpecDocumentSet(model *SpecModel, documents []SpecNamedDocument) (*SpecDocumentSet, error) {
	s := &SpecDocumentSet{
		Model:     model,
		Refl:      NewSpecReflection(model),
		documents: map[string]*SpecDocument{},
		rootOf:    map[string]string{},
	}
	s.BlueprintRoot = s.computeBlueprintRoot()
	pairs, err := s.computePairs()
	if err != nil {
		return nil, err
	}
	s.pairs = pairs
	for _, d := range documents {
		if err := s.Put(d.Name, d.Document); err != nil {
			return nil, err
		}
	}
	return s, nil
}

// LoadSpecDocumentSet loads YAML or SOM Markdown files; files of one root are
// fragments and are assembled first (refusing overlaps). Each document is
// named by its first file's name.
func LoadSpecDocumentSet(model *SpecModel, files []string) (*SpecDocumentSet, error) {
	trees := map[string]*SomMetaTree{}
	var fragments []SpecNamedDocument
	for _, file := range files {
		data, err := os.ReadFile(file)
		if err != nil {
			return nil, err
		}
		text := string(data)
		name := filepath.Base(strings.ReplaceAll(file, "\\", "/"))
		var doc *SpecDocument
		if strings.HasSuffix(file, ".md") {
			imported, err := SpecDocumentFromMarkdown(text, model)
			if err != nil {
				return nil, err
			}
			doc = imported.Document
		} else {
			// The root key `<SECTIONID> <Type>:` names the tree to decode with.
			var root *SpecRoot
			for _, r := range model.Roots {
				pattern := regexp.MustCompile(`(?m)^\s*` + regexp.QuoteMeta(r.SectionID) + " " +
					regexp.QuoteMeta(r.Type) + ":")
				if pattern.MatchString(text) {
					root = r
					break
				}
			}
			if root == nil {
				return nil, &SpecDocumentSetError{
					Refusal:   SpecDocumentSetRefusalNoRoot,
					Documents: []string{name},
					Message:   name + " names no root of the model",
				}
			}
			tree := trees[root.Type]
			if tree == nil {
				tree, err = BuildSomMetaTree(model, root.Type)
				if err != nil {
					return nil, err
				}
				trees[root.Type] = tree
			}
			doc, err = FromYaml(text, tree)
			if err != nil {
				return nil, err
			}
		}
		fragments = append(fragments, SpecNamedDocument{Name: name, Document: doc})
	}
	return SpecDocumentSetFromFragments(model, fragments)
}

// SpecDocumentSetFromFragments builds a set from documents and fragments:
// those of one root are fragments of one document, assembled in the order
// given (overlaps refused), the document named by its first fragment's name.
func SpecDocumentSetFromFragments(model *SpecModel, fragments []SpecNamedDocument) (*SpecDocumentSet, error) {
	refl := NewSpecReflection(model)
	byRoot := map[string][]SpecNamedDocument{}
	var rootOrder []string
	for _, f := range fragments {
		roots := setPopulatedRoots(refl, f.Document)
		if len(roots) != 1 {
			refusal, what := SpecDocumentSetRefusalNoRoot, "no root"
			if len(roots) > 0 {
				refusal, what = SpecDocumentSetRefusalTwoRoots, strings.Join(roots, " and ")
			}
			return nil, &SpecDocumentSetError{
				Refusal: refusal, Documents: []string{f.Name}, Message: f.Name + " populates " + what,
			}
		}
		if _, ok := byRoot[roots[0]]; !ok {
			rootOrder = append(rootOrder, roots[0])
		}
		byRoot[roots[0]] = append(byRoot[roots[0]], f)
	}
	var documents []SpecNamedDocument
	for _, root := range rootOrder {
		group := byRoot[root]
		if len(group) == 1 {
			documents = append(documents, group[0])
			continue
		}
		parts := make([]SpecAssemblyFragment, 0, len(group))
		names := make([]string, 0, len(group))
		for _, g := range group {
			parts = append(parts, SpecAssemblyFragment{Name: g.Name, Document: g.Document})
			names = append(names, g.Name)
		}
		assembly := AssembleSpecDocuments(parts)
		if !assembly.Ok() {
			return nil, &SpecDocumentSetError{
				Refusal:   SpecDocumentSetRefusalOverlap,
				Documents: names,
				Message:   "the fragments " + strings.Join(names, ", ") + " overlap",
			}
		}
		documents = append(documents, SpecNamedDocument{Name: group[0].Name, Document: assembly.Document})
	}
	return NewSpecDocumentSet(model, documents)
}

func (s *SpecDocumentSet) computeBlueprintRoot() string {
	var targets []string
	for _, r := range s.Model.Roots {
		cls := s.Refl.ClassNamed(r.Type)
		if cls == nil {
			continue
		}
		doc := cls.Annotation("Document")
		if doc == nil {
			continue
		}
		if based, ok := doc.Argument("basedOn").([]any); ok {
			for _, e := range based {
				t := linkJSONText(e)
				if !containsString(targets, t) {
					targets = append(targets, t)
				}
			}
		}
	}
	if len(targets) == 1 {
		return targets[0]
	}
	return ""
}

// Blueprint returns the D00SolutionBlueprint document (the Blueprint), or nil.
func (s *SpecDocumentSet) Blueprint() *SpecDocument {
	if s.BlueprintRoot == "" {
		return nil
	}
	return s.Document(s.BlueprintRoot)
}

// Document returns the document of rootType (a type name or a section id), or
// nil.
func (s *SpecDocumentSet) Document(rootType string) *SpecDocument {
	name, ok := s.NameOf(rootType)
	if !ok {
		return nil
	}
	return s.documents[name]
}

// NameOf returns the name of the document of rootType (a type name or a
// section id), ok=false when the set has none.
func (s *SpecDocumentSet) NameOf(rootType string) (string, bool) {
	t, ok := s.typeOf(rootType)
	if !ok {
		return "", false
	}
	for _, name := range s.order {
		if s.rootOf[name] == t {
			return name, true
		}
	}
	return "", false
}

func (s *SpecDocumentSet) typeOf(rootType string) (string, bool) {
	if rootType == "" {
		return "", false
	}
	for _, r := range s.Model.Roots {
		if r.Type == rootType || r.SectionID == rootType {
			return r.Type, true
		}
	}
	return "", false
}

func (s *SpecDocumentSet) hasRoot(t string) bool {
	for _, r := range s.rootOf {
		if r == t {
			return true
		}
	}
	return false
}

// Roots returns the populated roots, in model order.
func (s *SpecDocumentSet) Roots() []string {
	out := []string{}
	for _, r := range s.Model.Roots {
		if s.hasRoot(r.Type) {
			out = append(out, r.Type)
		}
	}
	return out
}

// Names returns the document names, in model order of their roots.
func (s *SpecDocumentSet) Names() []string {
	out := []string{}
	for _, r := range s.Roots() {
		if name, ok := s.NameOf(r); ok {
			out = append(out, name)
		}
	}
	return out
}

// MissingRoots returns every Phase 3 root a pair names with no document yet:
// its pairs are "not started", reported as such and never as findings.
func (s *SpecDocumentSet) MissingRoots() []string {
	out := []string{}
	for _, r := range s.Model.Roots {
		named := false
		for _, p := range s.pairs {
			if p.DetailRoot == r.Type {
				named = true
				break
			}
		}
		if named && !s.hasRoot(r.Type) {
			out = append(out, r.Type)
		}
	}
	return out
}

// Pairs returns the anchor pairs, in the Blueprint's walk order.
func (s *SpecDocumentSet) Pairs() []*SpecSyncPair { return s.pairs }

// Put adds or replaces a document (what Prefill creates); refused like the
// documents NewSpecDocumentSet takes.
func (s *SpecDocumentSet) Put(name string, document *SpecDocument) error {
	roots := setPopulatedRoots(s.Refl, document)
	if len(roots) == 0 {
		return &SpecDocumentSetError{
			Refusal: SpecDocumentSetRefusalNoRoot, Documents: []string{name},
			Message: name + " populates no root",
		}
	}
	if len(roots) > 1 {
		return &SpecDocumentSetError{
			Refusal: SpecDocumentSetRefusalTwoRoots, Documents: []string{name},
			Message: name + " populates " + strings.Join(roots, " and "),
		}
	}
	root := roots[0]
	if cls := s.Refl.ClassNamed(root); cls != nil && cls.IsCodeSpecsProjection() {
		return &SpecDocumentSetError{
			Refusal: SpecDocumentSetRefusalProjection, Documents: []string{name},
			Message: name + " is the CodeSpecs projection, which is no specification",
		}
	}
	for _, other := range s.order {
		if s.rootOf[other] == root && other != name {
			return &SpecDocumentSetError{
				Refusal: SpecDocumentSetRefusalSameRoot, Documents: []string{other, name},
				Message: other + " and " + name + " both populate " + root,
			}
		}
	}
	if _, ok := s.documents[name]; !ok {
		s.order = append(s.order, name)
	}
	s.documents[name] = document
	s.rootOf[name] = root
	return nil
}

// Get returns the document named name, or nil.
func (s *SpecDocumentSet) Get(name string) *SpecDocument { return s.documents[name] }

// RootOf returns the root class name of the document named name, "" when the
// set has none of that name.
func (s *SpecDocumentSet) RootOf(name string) string { return s.rootOf[name] }

// setPopulatedRoots is the roots doc holds a value under, in model order.
func setPopulatedRoots(refl *SpecReflection, doc *SpecDocument) []string {
	segs := map[string]bool{}
	for _, paths := range [][]string{doc.ContentPaths(), doc.FormPaths(), doc.ListPaths(), doc.HeadlinePaths()} {
		for _, p := range paths {
			if slash := strings.Index(p, "/"); slash >= 0 {
				segs[p[:slash]] = true
			} else {
				segs[p] = true
			}
		}
	}
	out := []string{}
	for _, r := range refl.Model.Roots {
		if segs[refl.RootSegment(r)] {
			out = append(out, r.Type)
		}
	}
	return out
}

// --- the anchor pairs ---------------------------------------------------------

func (s *SpecDocumentSet) computePairs() ([]*SpecSyncPair, error) {
	bp := s.BlueprintRoot
	out := []*SpecSyncPair{}
	if bp == "" {
		return out, nil
	}
	refl := s.Refl
	positions := map[string][]SpecSectionPosition{}
	at := func(root string) []SpecSectionPosition {
		if hit, ok := positions[root]; ok {
			return hit
		}
		every := SpecSectionPositions(refl, root)
		// A `@SameAs` copy is kept equal to its holder, never paired.
		var copies []string
		for _, p := range every {
			if !p.IsMember && p.Member != nil && p.Member.SameAs() != nil {
				copies = append(copies, p.Path)
			}
		}
		hit := []SpecSectionPosition{}
		for _, p := range every {
			if p.IsMember {
				continue
			}
			inCopy := false
			for _, c := range copies {
				if p.Path == c || strings.HasPrefix(p.Path, c+"/") {
					inCopy = true
					break
				}
			}
			if !inCopy {
				hit = append(hit, p)
			}
		}
		positions[root] = hit
		return hit
	}

	candidates := map[string]string{} // class -> target root
	var candidateOrder []string
	for _, p := range at(bp) {
		cls := refl.ClassNamed(p.ClassName)
		if cls == nil {
			continue
		}
		target := cls.DetailedIn
		if sync := cls.SyncedWith(); sync != nil {
			target = sync.Document
		}
		if target == "" || target == bp || refl.ClassNamed(target) == nil {
			continue
		}
		if _, ok := candidates[p.ClassName]; !ok {
			candidates[p.ClassName] = target
			candidateOrder = append(candidateOrder, p.ClassName)
		}
	}

	unpairable := func(className string) error {
		return &SpecDocumentSetError{
			Refusal:   SpecDocumentSetRefusalUnpairable,
			Documents: []string{},
			Message: "the positions of " + className + " in the Blueprint and its document " +
				"cannot be paired (SHARED-ANCHOR)",
			ClassName: className,
		}
	}

	for _, className := range candidateOrder {
		target := candidates[className]
		var mine, theirs []SpecSectionPosition
		for _, p := range at(bp) {
			if p.ClassName == className {
				mine = append(mine, p)
			}
		}
		for _, p := range at(target) {
			if p.ClassName == className {
				theirs = append(theirs, p)
			}
		}
		if len(theirs) == 0 {
			continue
		}
		type match struct{ b, d SpecSectionPosition }
		var matched []match
		if len(mine) == 1 && len(theirs) == 1 {
			matched = append(matched, match{mine[0], theirs[0]})
		} else {
			// Paired by the path below the nearest enclosing anchor.
			key := func(p SpecSectionPosition, root string) string {
				var outer *SpecSectionPosition
				for _, q := range at(root) {
					if q.Path == p.Path || !strings.HasPrefix(p.Path, q.Path+"/") {
						continue
					}
					if _, ok := candidates[q.ClassName]; !ok {
						continue
					}
					if outer == nil || len(q.Path) > len(outer.Path) {
						qq := q
						outer = &qq
					}
				}
				ids := p.SectionIDs
				outerName := ""
				if outer != nil {
					ids = p.SectionIDs[len(outer.SectionIDs):]
					outerName = outer.ClassName
				}
				return outerName + "/" + strings.Join(ids, "/")
			}
			byKey := map[string]SpecSectionPosition{}
			for _, p := range theirs {
				k := key(p, target)
				if _, ok := byKey[k]; ok {
					return nil, unpairable(className)
				}
				byKey[k] = p
			}
			for _, p := range mine {
				k := key(p, bp)
				q, ok := byKey[k]
				if !ok {
					return nil, unpairable(className)
				}
				delete(byKey, k)
				matched = append(matched, match{p, q})
			}
			if len(byKey) > 0 {
				return nil, unpairable(className)
			}
		}
		cls := refl.ClassNamed(className)
		sectionID := cls.SectionID
		if sectionID == "" {
			sectionID = className
		}
		for _, m := range matched {
			out = append(out, &SpecSyncPair{
				ClassName:       className,
				SectionID:       sectionID,
				BlueprintAnchor: m.b.Path,
				DetailAnchor:    m.d.Path,
				DetailRoot:      target,
				Sync:            cls.SyncedWith(),
			})
		}
	}
	return out, nil
}

// --- findings and the report --------------------------------------------------

// SpecSyncPlace is one side of a finding: where the place is and what it
// holds.
type SpecSyncPlace struct {
	// Document is the document's name, "" when the set has none for this side.
	Document string
	// Root is the root's section id.
	Root string
	// Path is the document path (for a place the document does not hold, the
	// nearest path it does: the list an element would be added to).
	Path string
	// Field is the form field, "" for none.
	Field string
	// Value is the value (read with pending marks rejected), nil when absent.
	Value *string
	// PendingMarks is whether the value holds pending change marks.
	PendingMarks bool
}

// ToJSON is the canonical JSON form.
func (p SpecSyncPlace) ToJSON() map[string]any {
	out := map[string]any{"root": p.Root, "path": p.Path}
	if p.Document != "" {
		out["document"] = p.Document
	} else {
		out["document"] = nil
	}
	if p.Field != "" {
		out["field"] = p.Field
	}
	if p.Value != nil {
		out["value"] = *p.Value
	}
	out["pendingMarks"] = p.PendingMarks
	return out
}

// valueOr is the place's value, "" when absent.
func (p SpecSyncPlace) valueOr() string {
	if p.Value == nil {
		return ""
	}
	return *p.Value
}

// SpecSyncFinding is one finding of the set.
type SpecSyncFinding struct {
	// Code is what it reports (a SpecSyncCode constant).
	Code string
	// Pair is the pair's section id (the summary's or link's class for a
	// cross check, empty for a pending value outside every pair).
	Pair string
	// Blueprint is the Blueprint side (for a cross check, the side holding
	// the link).
	Blueprint SpecSyncPlace
	// Detail is the Phase 3 side (for a cross check, the other end).
	Detail SpecSyncPlace
	// Holder is which side holds the value (a SpecSyncHolder constant).
	Holder string
	// Resolution is how it is resolved (a SpecSyncResolution constant).
	Resolution string
	// Message is prose for the agent, in the canonical form: every runtime
	// writes the same sentence (the conformance corpus compares it).
	Message string
}

// IsInfo reports whether it is reported only, not a finding.
func (f SpecSyncFinding) IsInfo() bool { return f.Resolution == SpecSyncResolutionInfo }

// ToJSON is the canonical JSON form.
func (f SpecSyncFinding) ToJSON() map[string]any {
	return map[string]any{
		"code":       f.Code,
		"pair":       f.Pair,
		"blueprint":  f.Blueprint.ToJSON(),
		"detail":     f.Detail.ToJSON(),
		"holder":     f.Holder,
		"resolution": f.Resolution,
		"message":    f.Message,
		"info":       f.IsInfo(),
	}
}

// SpecDocumentFindings is one document's own findings in a SpecSyncReport.
type SpecDocumentFindings struct {
	// Name is the document's name.
	Name string
	// Errors are its findings (ValidateDocument, then ValidateLinks).
	Errors []SpecValidationError
}

// SpecSyncCount is one entry of SpecSyncReport.CountsByCode /
// CountsByResolution.
type SpecSyncCount struct {
	Key   string
	Count int
}

// SpecSyncReport is the validation of a document set.
type SpecSyncReport struct {
	// Findings are the findings in pair and path order, `info` entries
	// included.
	Findings []SpecSyncFinding
	// DocumentFindings are each document's own findings (ValidateDocument,
	// then ValidateLinks), in the set's order.
	DocumentFindings []SpecDocumentFindings
	// NotStarted are the Phase 3 roots with no document yet.
	NotStarted []string
	// NotStartedPairs are the pairs (by section id) whose Phase 3 document
	// exists but holds nothing beneath the pair's anchor: not started, like a
	// missing document.
	NotStartedPairs []string
}

// CountsByCode returns the findings per code, `info` entries included, in
// code order (codes without findings left out).
func (r *SpecSyncReport) CountsByCode() []SpecSyncCount {
	out := []SpecSyncCount{}
	for _, c := range SpecSyncCodes {
		n := 0
		for _, f := range r.Findings {
			if f.Code == c {
				n++
			}
		}
		if n > 0 {
			out = append(out, SpecSyncCount{c, n})
		}
	}
	return out
}

// CountsByResolution returns the findings per resolution, in resolution
// order.
func (r *SpecSyncReport) CountsByResolution() []SpecSyncCount {
	out := []SpecSyncCount{}
	for _, res := range SpecSyncResolutions {
		n := 0
		for _, f := range r.Findings {
			if f.Resolution == res {
				n++
			}
		}
		if n > 0 {
			out = append(out, SpecSyncCount{res, n})
		}
	}
	return out
}

// Clean reports whether there is no finding other than `info`.
func (r *SpecSyncReport) Clean() bool {
	for _, f := range r.Findings {
		if !f.IsInfo() {
			return false
		}
	}
	return true
}

// SpecSyncCountsJSON is counts as the canonical `[[key, count], …]` form.
func SpecSyncCountsJSON(counts []SpecSyncCount) []any {
	out := []any{}
	for _, c := range counts {
		out = append(out, []any{c.Key, c.Count})
	}
	return out
}

// specValidationErrorsJSON is errors as `[{path, code, message}]`.
func specValidationErrorsJSON(errors []SpecValidationError) []any {
	out := []any{}
	for _, e := range errors {
		out = append(out, map[string]any{"path": e.Path, "code": e.Code, "message": e.Message})
	}
	return out
}

// ToJSON is the canonical JSON form; every ordered value is a list.
func (r *SpecSyncReport) ToJSON() map[string]any {
	findings := []any{}
	for _, f := range r.Findings {
		findings = append(findings, f.ToJSON())
	}
	documentFindings := []any{}
	for _, d := range r.DocumentFindings {
		documentFindings = append(documentFindings, []any{d.Name, specValidationErrorsJSON(d.Errors)})
	}
	return map[string]any{
		"findings":           findings,
		"documentFindings":   documentFindings,
		"notStarted":         stringsJSON(r.NotStarted),
		"notStartedPairs":    stringsJSON(r.NotStartedPairs),
		"countsByCode":       SpecSyncCountsJSON(r.CountsByCode()),
		"countsByResolution": SpecSyncCountsJSON(r.CountsByResolution()),
		"clean":              r.Clean(),
	}
}

// pairScope is a set of pair section ids, nil for every pair.
func pairScope(pairs []string) map[string]bool {
	if pairs == nil {
		return nil
	}
	scope := map[string]bool{}
	for _, p := range pairs {
		scope[p] = true
	}
	return scope
}

// SyncReport is the validation of set, with counts; pairs (non-nil) keeps the
// findings of those pairs (by section id) only. Writes nothing.
func SyncReport(set *SpecDocumentSet, pairs []string) *SpecSyncReport {
	scope := pairScope(pairs)
	c := NewSpecSetCheck(set)
	index := 0
	for _, p := range set.Pairs() {
		if scope == nil || scope[p.SectionID] {
			c.ComparePair(p, index)
		}
		index++
	}
	c.CrossChecks(scope, index)
	if scope == nil {
		c.pendingScan(index + 1)
		c.unmarkableScan(index + 2)
	}
	c.SortOut()
	documentFindings := []SpecDocumentFindings{}
	for _, name := range set.Names() {
		doc := set.Get(name)
		errors := append(ValidateDocument(set.Model, doc), ValidateLinks(set.Model, doc)...)
		documentFindings = append(documentFindings, SpecDocumentFindings{Name: name, Errors: errors})
	}
	findings := []SpecSyncFinding{}
	for _, o := range c.Out {
		findings = append(findings, o.Finding)
	}
	return &SpecSyncReport{
		Findings:         findings,
		DocumentFindings: documentFindings,
		NotStarted:       set.MissingRoots(),
		NotStartedPairs:  append([]string{}, c.NotStartedPairs...),
	}
}

// --- the comparison -----------------------------------------------------------

// SpecSetFound is a finding with its sort keys (and, for a pair's finding,
// its two sides).
type SpecSetFound struct {
	Order   int
	Key     string
	Finding SpecSyncFinding
	B       *SpecSetSide
	D       *SpecSetSide
}

// SpecSetValue is one value of a subtree, keyed for comparison.
type SpecSetValue struct {
	Path string
	// Field is the form field (KSpecHeadlineField for a headline), "" for
	// content.
	Field   string
	Value   string
	Pending bool
	Spec    *FormFieldSpec
}

// SpecSetSide is a document side of a pair: its subtree's values and items,
// keyed by the path below the anchor with list items written by their section
// id.
type SpecSetSide struct {
	Name   string
	Root   string
	Anchor string
	// Values are the values by key (`c:` content, `f:` form field, `h:`
	// headline).
	Values map[string]*SpecSetValue
	// Items are item key → item path, and the anchor's own key "".
	Items map[string]string
	// ItemKeys are the keys of Items in the order they were collected.
	ItemKeys []string
}

func newSpecSetSide(name, root, anchor string) *SpecSetSide {
	return &SpecSetSide{
		Name: name, Root: root, Anchor: anchor,
		Values: map[string]*SpecSetValue{}, Items: map[string]string{},
	}
}

func (s *SpecSetSide) putItem(key, path string) {
	if _, ok := s.Items[key]; !ok {
		s.ItemKeys = append(s.ItemKeys, key)
	}
	s.Items[key] = path
}

// setPlaces are the places a set of place texts stands for under an anchor.
type setPlaces struct {
	prefixes  []string
	fields    map[string]bool
	headlines map[string]bool
}

var (
	setFloatText    = regexp.MustCompile(`(?i)^[+-]?(\d+\.?\d*|\.\d+)(e[+-]?\d+)?$`)
	setHexText      = regexp.MustCompile(`(?i)^[+-]?0x[0-9a-f]+$`)
	setSpecialText  = regexp.MustCompile(`^[+-]?(Infinity|NaN)$`)
	setItemBrackets = regexp.MustCompile(`\[[^\]]*\]`)
)

// setNumTryParse is Dart's `num.tryParse`: decimal, hex, `Infinity` and
// `NaN`.
func setNumTryParse(text string) (float64, bool) {
	t := strings.TrimSpace(text)
	switch {
	case setFloatText.MatchString(t):
		f, err := strconv.ParseFloat(t, 64)
		if err != nil {
			// An exponent past float range still reads, as Dart's does.
			if ne, ok := err.(*strconv.NumError); ok && ne.Err == strconv.ErrRange {
				return f, true
			}
			return 0, false
		}
		return f, true
	case setHexText.MatchString(t):
		neg := strings.HasPrefix(t, "-")
		digits := strings.TrimLeft(t, "+-")[2:]
		n, err := strconv.ParseUint(digits, 16, 64)
		if err != nil {
			return 0, false
		}
		if neg {
			return -float64(n), true
		}
		return float64(n), true
	case setSpecialText.MatchString(t):
		if strings.HasSuffix(t, "NaN") {
			return math.NaN(), true
		}
		if strings.HasPrefix(t, "-") {
			return math.Inf(-1), true
		}
		return math.Inf(1), true
	}
	return 0, false
}

// setUnderAny reports whether path is one of prefixes or beneath one.
func setUnderAny(path string, prefixes []string) bool {
	for _, p := range prefixes {
		if path == p || strings.HasPrefix(path, p+"/") {
			return true
		}
	}
	return false
}

// SpecSetReviewed is raw with every pending mark rejected, trimmed.
func SpecSetReviewed(raw string) string {
	return strings.TrimSpace(ApplyInlineMarksText(raw, false))
}

// SpecSetIsPending reports whether raw holds pending change marks.
func SpecSetIsPending(raw string) bool {
	return ApplyInlineMarksText(raw, true) != ApplyInlineMarksText(raw, false)
}

// setStrPtr is a pointer to a copy of s.
func setStrPtr(s string) *string { return &s }

// SpecSetCheck is the comparison behind SyncReport (and Backfill, Prefill and
// RenameID): one per run, with its caches.
type SpecSetCheck struct {
	Set  *SpecDocumentSet
	Refl *SpecReflection
	// Out are the findings collected so far.
	Out []SpecSetFound
	// NotStartedPairs are the pairs whose Phase 3 document exists but holds
	// nothing beneath the pair's anchor.
	NotStartedPairs []string

	itemIDs      map[*SpecDocument]map[string]string
	items        map[string]bool
	forms        map[*SpecDocument]map[string][]string
	registryDocs map[string]string
	reach        map[string]map[string]bool
	entries      map[*SpecDocument]map[string]map[string]string
	sameAs       map[string][]SpecSameAsBinding
}

// NewSpecSetCheck returns the comparison of set.
func NewSpecSetCheck(set *SpecDocumentSet) *SpecSetCheck {
	return &SpecSetCheck{
		Set:             set,
		Refl:            set.Refl,
		Out:             []SpecSetFound{},
		NotStartedPairs: []string{},
		itemIDs:         map[*SpecDocument]map[string]string{},
		items:           map[string]bool{},
		forms:           map[*SpecDocument]map[string][]string{},
		registryDocs:    map[string]string{},
		reach:           map[string]map[string]bool{},
		entries:         map[*SpecDocument]map[string]map[string]string{},
		sameAs:          map[string][]SpecSameAsBinding{},
	}
}

func (c *SpecSetCheck) add(order int, key string, finding SpecSyncFinding, b, d *SpecSetSide) {
	c.Out = append(c.Out, SpecSetFound{Order: order, Key: key, Finding: finding, B: b, D: d})
}

// SortOut sorts Out as the report lists it.
func (c *SpecSetCheck) SortOut() {
	value := func(f SpecSyncFinding) string {
		if f.Blueprint.Value != nil {
			return *f.Blueprint.Value
		}
		return f.Detail.valueOr()
	}
	sort.SliceStable(c.Out, func(i, j int) bool {
		a, b := c.Out[i], c.Out[j]
		if a.Order != b.Order {
			return a.Order < b.Order
		}
		if a.Key != b.Key {
			return a.Key < b.Key
		}
		if x, y := SpecSyncCodeIndex(a.Finding.Code), SpecSyncCodeIndex(b.Finding.Code); x != y {
			return x < y
		}
		return value(a.Finding) < value(b.Finding)
	})
}

func (c *SpecSetCheck) rootSeg(typeName string) string {
	for _, r := range c.Refl.Model.Roots {
		if r.Type == typeName {
			return c.Refl.RootSegment(r)
		}
	}
	panic("no root " + typeName)
}

// ItemID returns the effective section id of the list item at itemPath in
// doc.
func (c *SpecSetCheck) ItemID(doc *SpecDocument, itemPath string) string {
	byDoc := c.itemIDs[doc]
	if byDoc == nil {
		byDoc = map[string]string{}
		c.itemIDs[doc] = byDoc
	}
	if hit, ok := byDoc[itemPath]; ok {
		return hit
	}
	hit := setEffectiveItemID(c.Refl, doc, itemPath)
	byDoc[itemPath] = hit
	return hit
}

// setEffectiveItemID is the stored section id of the item at itemPath, else
// the one its position and the list's pattern give it.
func setEffectiveItemID(refl *SpecReflection, doc *SpecDocument, itemPath string) string {
	if stored, ok := doc.ItemSectionID(itemPath); ok {
		return stored
	}
	lst := itemPath
	if dash := strings.LastIndex(itemPath, "-"); dash >= 0 {
		lst = itemPath[:dash]
	}
	pattern, stem := "", lst
	if slash := strings.LastIndex(lst, "/"); slash >= 0 {
		stem = lst[slash+1:]
	}
	if res := refl.Resolve(lst); res != nil && res.Field != nil {
		pattern, stem = res.Field.SectionIDPattern, res.Field.Name
	}
	position := 0
	for i, it := range doc.ListItems(lst) {
		if it == itemPath {
			position = i + 1
			break
		}
	}
	return EffectiveListItemSectionID("", false, pattern, position, stem)
}

// IsItem reports whether path is a list item (complex or scalar).
func (c *SpecSetCheck) IsItem(path string) bool {
	if hit, ok := c.items[path]; ok {
		return hit
	}
	// A scalar list's items are elements too, keyed by their effective id like
	// a complex list's (`LIST[ID]`).
	r := c.Refl.Resolve(path)
	hit := r != nil && (r.Kind == SpecNodeKindListItemComplex || r.Kind == SpecNodeKindListItemScalar)
	c.items[path] = hit
	return hit
}

// Expand returns the concrete paths a pattern (list items `<list>-*`) stands
// for in doc.
func (c *SpecSetCheck) Expand(doc *SpecDocument, pattern string) []string {
	return SpecExpandPattern(doc, pattern)
}

// Key returns the key of path below anchor: item segments as `LIST[id]`.
func (c *SpecSetCheck) Key(doc *SpecDocument, anchor, path string) string {
	if path == anchor {
		return ""
	}
	var out []string
	at := anchor
	for _, seg := range strings.Split(path[len(anchor)+1:], "/") {
		at = at + "/" + seg
		if c.IsItem(at) {
			out = append(out, seg[:strings.LastIndex(seg, "-")]+"["+c.ItemID(doc, at)+"]")
		} else {
			out = append(out, seg)
		}
	}
	return strings.Join(out, "/")
}

// AnchorKey returns the key of an anchor itself among its siblings: the ids of
// the list items on its path.
func (c *SpecSetCheck) AnchorKey(doc *SpecDocument, path string) string {
	var out []string
	at := ""
	for _, seg := range strings.Split(path, "/") {
		if at == "" {
			at = seg
		} else {
			at = at + "/" + seg
		}
		if c.IsItem(at) {
			out = append(out, c.ItemID(doc, at))
		}
	}
	return strings.Join(out, "/")
}

// places is the paths places resolved under anchor stand for in doc: whole
// sections (prefixes), single form fields and headlines.
func (c *SpecSetCheck) places(doc *SpecDocument, places []string, anchor string) setPlaces {
	out := setPlaces{prefixes: []string{}, fields: map[string]bool{}, headlines: map[string]bool{}}
	for _, text := range places {
		r := SpecResolvePlaceAt(c.Refl, text, anchor)
		if r == nil {
			continue
		}
		for _, p := range c.Expand(doc, r.Path) {
			switch r.Kind {
			case SpecPlaceKindFormField:
				out.fields[p+"#"+r.Field()] = true
			case SpecPlaceKindHeadline:
				out.headlines[p] = true
			case SpecPlaceKindSectionID:
			default:
				out.prefixes = append(out.prefixes, p)
			}
		}
	}
	return out
}

// Collect returns the values beneath anchor in doc, with what the pair does
// not compare left out: `detailOnly` places, nested pairs, `@SameAs` copies
// and derived places.
func (c *SpecSetCheck) Collect(name string, doc *SpecDocument, root, anchor string, pair *SpecSyncPair, nested []string) *SpecSetSide {
	refl := c.Refl
	side := newSpecSetSide(name, root, anchor)
	var detailOnly []string
	if pair.Sync != nil {
		detailOnly = pair.Sync.DetailOnly
	}
	skip := c.places(doc, detailOnly, anchor)
	bindings, ok := c.sameAs[root]
	if !ok {
		bindings = SpecSameAsBindings(refl, root)
		c.sameAs[root] = bindings
	}
	excluded := append(append([]string{}, skip.prefixes...), nested...)
	for _, b := range bindings {
		excluded = append(excluded, c.Expand(doc, b.CopyPath)...)
	}
	under := func(p string) bool { return p == anchor || strings.HasPrefix(p, anchor+"/") }
	outside := func(p string) bool { return p != anchor && setUnderAny(p, excluded) }

	lists := sortedCopy(doc.ListPaths())
	// The values a summary row repeats are derived from its detail element
	// (`@SummaryOf` repeats): never shared, like every derived place.
	for _, lst := range lists {
		if !under(lst) {
			continue
		}
		res := refl.Resolve(lst)
		if res == nil || res.Field == nil {
			continue
		}
		s := res.Field.SummaryOf()
		if s == nil || len(s.Repeats) == 0 {
			continue
		}
		repeats := make([]string, 0, len(s.Repeats))
		for _, r := range s.Repeats {
			repeats = append(repeats, r.Key)
		}
		for _, item := range doc.ListItems(lst) {
			r := c.places(doc, repeats, item)
			excluded = append(excluded, r.prefixes...)
			for k := range r.fields {
				skip.fields[k] = true
			}
			for k := range r.headlines {
				skip.headlines[k] = true
			}
		}
	}

	side.putItem("", anchor)
	for _, lst := range lists {
		if !under(lst) || outside(lst) {
			continue
		}
		if res := refl.Resolve(lst); res != nil && res.Field != nil && res.Field.DerivedFrom() != nil {
			excluded = append(excluded, lst)
			continue
		}
		for _, item := range doc.ListItems(lst) {
			side.putItem(c.Key(doc, anchor, item), item)
		}
	}
	for _, p := range sortedCopy(doc.ContentPaths()) {
		if !under(p) || outside(p) {
			continue
		}
		if res := refl.Resolve(p); res != nil && res.Field != nil && res.Field.DerivedFrom() != nil {
			continue
		}
		raw := doc.ContentOr(p)
		side.Values["c:"+c.Key(doc, anchor, p)] = &SpecSetValue{
			Path: p, Value: SpecSetReviewed(raw), Pending: SpecSetIsPending(raw),
		}
	}
	for _, p := range sortedCopy(doc.FormPaths()) {
		if !under(p) || outside(p) {
			continue
		}
		var specs []*FormFieldSpec
		if res := refl.Resolve(p); res != nil && res.Field != nil {
			specs = res.Field.FormFields
		}
		for _, fname := range sortedCopy(doc.FormFieldNames(p)) {
			if skip.fields[p+"#"+fname] {
				continue
			}
			var spec *FormFieldSpec
			for _, f := range specs {
				if f.Name == fname {
					spec = f
					break
				}
			}
			if spec != nil && (spec.DerivedFrom != nil || len(spec.CountOf) > 0 ||
				len(spec.ProductOf) > 0 || spec.RankOf != "") {
				continue
			}
			raw := doc.FormFieldOr(p, fname)
			side.Values["f:"+c.Key(doc, anchor, p)+"#"+fname] = &SpecSetValue{
				Path: p, Field: fname, Value: SpecSetReviewed(raw), Pending: SpecSetIsPending(raw), Spec: spec,
			}
		}
	}
	for _, p := range sortedCopy(doc.HeadlinePaths()) {
		if !under(p) || outside(p) || skip.headlines[p] {
			continue
		}
		raw := doc.HeadlineOr(p)
		side.Values["h:"+c.Key(doc, anchor, p)] = &SpecSetValue{
			Path: p, Field: KSpecHeadlineField, Value: SpecSetReviewed(raw), Pending: SpecSetIsPending(raw),
		}
	}
	return side
}

// pathOn is the path key stands for on side: the item paths it names as far
// as the side holds them; where it stops, the list an element would go in.
func (c *SpecSetCheck) pathOn(side *SpecSetSide, key string) string {
	if key == "" {
		return side.Anchor
	}
	path := side.Anchor
	prefix := ""
	for _, s := range strings.Split(key, "/") {
		if prefix == "" {
			prefix = s
		} else {
			prefix = prefix + "/" + s
		}
		if bracket := strings.Index(s, "["); bracket > 0 {
			item, ok := side.Items[prefix]
			if !ok {
				return path + "/" + s[:bracket]
			}
			path = item
		} else {
			path = path + "/" + s
		}
	}
	return path
}

// SpecSetSameTyped reports whether a and b are the same value of the field's
// type.
func SpecSetSameTyped(a, b string, spec *FormFieldSpec) bool {
	t := ""
	if spec != nil {
		t = spec.Type
	}
	switch t {
	case "int", "double", "num":
		x, okx := setNumTryParse(a)
		y, oky := setNumTryParse(b)
		if okx && oky {
			return x == y
		}
	case "bool":
		return strings.ToLower(a) == strings.ToLower(b)
	}
	return a == b
}

// SpecSetStripKind is a value key (`c:` / `f:` / `h:` / `i:`) without its kind
// and field.
func SpecSetStripKind(key string) string {
	k := key
	if len(key) > 2 && key[1] == ':' {
		k = key[2:]
	}
	if hash := strings.Index(k, "#"); hash >= 0 {
		return k[:hash]
	}
	return k
}

// sortedKeysOf is the keys of the maps, merged and sorted.
func sortedKeysOf[V any](maps ...map[string]V) []string {
	set := map[string]bool{}
	for _, m := range maps {
		for k := range m {
			set[k] = true
		}
	}
	out := make([]string, 0, len(set))
	for k := range set {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// --- one pair -----------------------------------------------------------------

// ComparePair compares one pair, adding its findings at order.
func (c *SpecSetCheck) ComparePair(pair *SpecSyncPair, order int) {
	set := c.Set
	bpName, okB := set.NameOf(set.BlueprintRoot)
	dtName, okD := set.NameOf(pair.DetailRoot)
	if !okB || !okD {
		return // not started
	}
	bp := set.Get(bpName)
	dt := set.Get(dtName)
	bpRoot := set.BlueprintRoot

	// Nested pairs are compared on their own.
	nested := func(doc *SpecDocument, blueprintSide bool) []string {
		var out []string
		for _, other := range set.Pairs() {
			if other != pair && (blueprintSide || other.DetailRoot == pair.DetailRoot) {
				anchor := other.DetailAnchor
				if blueprintSide {
					anchor = other.BlueprintAnchor
				}
				out = append(out, c.Expand(doc, anchor)...)
			}
		}
		return out
	}

	bpAnchors := map[string]string{}
	var keyOrder []string
	for _, a := range c.Expand(bp, pair.BlueprintAnchor) {
		k := c.AnchorKey(bp, a)
		if _, ok := bpAnchors[k]; !ok {
			keyOrder = append(keyOrder, k)
		}
		bpAnchors[k] = a
	}
	dtAnchors := map[string]string{}
	for _, a := range c.Expand(dt, pair.DetailAnchor) {
		k := c.AnchorKey(dt, a)
		dtAnchors[k] = a
	}
	// A pair the Phase 3 document has not written yet is not started, never
	// findings: it is what Prefill fills, and Backfill must not take its
	// emptiness for removals.
	started := false
	for _, a := range dtAnchors {
		if dt.HasValuesUnder(a) {
			started = true
			break
		}
	}
	if !started {
		c.NotStartedPairs = append(c.NotStartedPairs, pair.SectionID)
		return
	}
	var bpNested, dtNested []string
	nestedDone := false
	beneath := func(all []string, anchor string) []string {
		var out []string
		for _, p := range all {
			if strings.HasPrefix(p, anchor+"/") {
				out = append(out, p)
			}
		}
		return out
	}
	for _, k := range keyOrder {
		ba := bpAnchors[k]
		da, ok := dtAnchors[k]
		if !ok {
			continue // the outer list reports it
		}
		if !nestedDone {
			bpNested = nested(bp, true)
			dtNested = nested(dt, false)
			nestedDone = true
		}
		b := c.Collect(bpName, bp, bpRoot, ba, pair, beneath(bpNested, ba))
		d := c.Collect(dtName, dt, pair.DetailRoot, da, pair, beneath(dtNested, da))
		c.compare(pair, order, b, d, bp, dt)
	}
}

type setListRelation struct {
	relation string
	where    string
}

func (c *SpecSetCheck) compare(pair *SpecSyncPair, order int, b, d *SpecSetSide, bp, dt *SpecDocument) {
	refl := c.Refl
	sync := pair.Sync
	// Relations: list key -> (relation, where); field key -> relation.
	listRel := map[string]setListRelation{}
	fieldRel := map[string]string{}
	var relations []SpecListRelation
	var heldHere []string
	if sync != nil {
		relations = sync.Relations
		heldHere = sync.HeldHere
	}
	for _, r := range relations {
		res := SpecResolvePlaceAt(refl, r.Place, b.Anchor)
		if res == nil {
			continue
		}
		for _, p := range c.Expand(bp, res.Path) {
			key := c.Key(bp, b.Anchor, p)
			switch res.Kind {
			case SpecPlaceKindList:
				listRel[key] = setListRelation{r.Relation, r.Where}
			case SpecPlaceKindFormField:
				fieldRel[key+"#"+res.Field()] = r.Relation
			}
		}
	}

	// A relation stated for a form field is the same for every element: match
	// it by its key with item ids dropped.
	shape := func(key string) string { return setItemBrackets.ReplaceAllString(key, "[]") }
	fieldRelByShape := map[string]string{}
	for k, v := range fieldRel {
		fieldRelByShape[shape(k)] = v
	}
	held := c.places(bp, heldHere, b.Anchor)
	isHeld := func(bpPath, fld string) bool {
		return setUnderAny(bpPath, held.prefixes) || (fld != "" && held.fields[bpPath+"#"+fld])
	}

	place := func(s *SpecSetSide, key, fld string, value *string) SpecSyncPlace {
		v := s.Values[key]
		out := SpecSyncPlace{Document: s.Name, Root: c.rootSeg(s.Root), Field: fld, Value: value}
		if v != nil {
			out.Path = v.Path
			if fld == "" {
				out.Field = v.Field
			}
			if value == nil {
				out.Value = setStrPtr(v.Value)
			}
			out.PendingMarks = v.Pending
		} else if strings.HasPrefix(key, "i:") {
			out.Path = c.pathOn(s, key[2:])
		} else {
			out.Path = c.pathOn(s, SpecSetStripKind(key))
		}
		return out
	}

	emit := func(code, key, message string, heldHere bool, fld string, bValue, dValue *string, resolution string) {
		holder := SpecSyncHolderDetail
		if heldHere {
			holder = SpecSyncHolderBlueprint
		}
		if resolution == "" {
			resolution = SpecSyncResolutionBackfill
			if heldHere {
				resolution = SpecSyncResolutionAgent
			}
		}
		c.add(order, key, SpecSyncFinding{
			Code:       code,
			Pair:       pair.SectionID,
			Blueprint:  place(b, key, fld, bValue),
			Detail:     place(d, key, fld, dValue),
			Holder:     holder,
			Resolution: resolution,
			Message:    message,
		}, b, d)
	}

	// Elements.
	var oneSided []string
	for _, k := range sortedKeysOf(b.Items, d.Items) {
		if k == "" {
			continue
		}
		_, inB := b.Items[k]
		_, inD := d.Items[k]
		if inB == inD {
			continue
		}
		beneathOther := false
		for _, o := range oneSided {
			if strings.HasPrefix(k, o+"/") {
				beneathOther = true
				break
			}
		}
		if beneathOther {
			continue
		}
		oneSided = append(oneSided, k)
		// `LIST[ID]` (every item key, Key); a key without the brackets names
		// its element by its last segment.
		bracket := strings.LastIndex(k, "[")
		parentList := ""
		if bracket < 0 {
			if slash := strings.LastIndex(k, "/"); slash >= 0 {
				parentList = k[:slash]
			}
		} else {
			parentList = k[:bracket]
		}
		rel, hasRel := listRel[parentList]
		relation := "equal"
		if hasRel {
			relation = rel.relation
		}
		itemPath, doc := d.Items[k], dt
		if inB {
			itemPath, doc = b.Items[k], bp
		}
		if hasRel && rel.where != "" {
			if flt := TryParseSpecPlaceFilter(rel.where); flt != nil && flt.Field != "" &&
				!flt.Matches(c.ownValues(doc, itemPath, flt.Field)) {
				relation = "equal"
			}
		}
		id := k
		if bracket < 0 {
			id = k[strings.LastIndex(k, "/")+1:]
		} else {
			id = k[bracket+1 : len(k)-1]
		}
		heldPath := itemPath
		if !inB {
			heldPath = c.pathOn(b, k)
		}
		heldHere := isHeld(heldPath, "")
		key := "i:" + k
		switch {
		case inD && relation == "subset":
			emit(SpecSyncCodeSharedElementMayBeAdded, key,
				id+" is only in "+d.Name+"; under subset it may be added to "+b.Name,
				heldHere, "", nil, setStrPtr(id), SpecSyncResolutionInfo)
		case inD:
			emit(SpecSyncCodeSharedElementMissing, key,
				id+" is in "+d.Name+" and missing in "+b.Name,
				heldHere, "", nil, setStrPtr(id), "")
		case relation != "superset":
			emit(SpecSyncCodeSharedElementOnlyInBlueprint, key,
				id+" is only in "+b.Name+"; "+d.Name+" removed it",
				heldHere, "", setStrPtr(id), nil, "")
		}
	}

	beneathOneSided := func(key string) bool {
		rel := SpecSetStripKind(key)
		for _, o := range oneSided {
			if rel == o || strings.HasPrefix(rel, o+"/") {
				return true
			}
		}
		return false
	}
	nonEmpty := func(s string) *string {
		if s == "" {
			return nil
		}
		return setStrPtr(s)
	}

	// Values.
	for _, k := range sortedKeysOf(b.Values, d.Values) {
		if beneathOneSided(k) {
			continue
		}
		vb := b.Values[k]
		vd := d.Values[k]
		var spec *FormFieldSpec
		fld, bValue, dValue := "", "", ""
		if vb != nil {
			spec, fld, bValue = vb.Spec, vb.Field, vb.Value
		}
		if vd != nil {
			if spec == nil {
				spec = vd.Spec
			}
			if fld == "" {
				fld = vd.Field
			}
			dValue = vd.Value
		}
		heldPath := ""
		if vb != nil {
			heldPath = vb.Path
		} else {
			heldPath = c.pathOn(b, SpecSetStripKind(k))
		}
		heldHere := isHeld(heldPath, fld)
		if spec != nil && spec.Multiple && len(spec.RefersTo) > 0 {
			relation, ok := fieldRelByShape[shape(k[2:])]
			if !ok {
				relation = "equal"
			}
			ib := SpecLinkIDs(bValue)
			idd := SpecLinkIDs(dValue)
			for _, x := range setSortedMinus(idd, ib) {
				may := relation == "subset"
				code, resolution := SpecSyncCodeSharedElementMissing, ""
				if may {
					code, resolution = SpecSyncCodeSharedElementMayBeAdded, SpecSyncResolutionInfo
				}
				emit(code, k, x+" is named in "+d.Name+" and not in "+b.Name,
					heldHere, fld, nonEmpty(bValue), setStrPtr(x), resolution)
			}
			if relation != "superset" {
				for _, x := range setSortedMinus(ib, idd) {
					emit(SpecSyncCodeSharedElementOnlyInBlueprint, k, x+" is named only in "+b.Name,
						heldHere, fld, setStrPtr(x), nonEmpty(dValue), "")
				}
			}
			continue
		}
		if bValue == "" && dValue == "" {
			continue
		}
		if SpecSetSameTyped(bValue, dValue, spec) {
			continue
		}
		what := "the value"
		if fld != "" {
			what = "form field \"" + fld + "\""
		}
		switch {
		case bValue == "":
			emit(SpecSyncCodeSharedValueMissing, k,
				what+" is filled in "+d.Name+" and empty in "+b.Name, heldHere, fld, nil, nil, "")
		case dValue == "":
			emit(SpecSyncCodeSharedValueOnlyInBlueprint, k,
				what+" is filled only in "+b.Name+"; "+d.Name+" emptied it", heldHere, fld, nil, nil, "")
		default:
			message := what + " differs: \"" + bValue + "\" in " + b.Name + ", \"" + dValue + "\" in " + d.Name
			if heldHere {
				message += " (held in " + b.Name + ")"
			}
			emit(SpecSyncCodeSharedValueDiffers, k, message, heldHere, fld, nil, nil, "")
		}
	}
}

// setSortedMinus is the distinct entries of a not in b, sorted.
func setSortedMinus(a, b []string) []string {
	set := map[string]bool{}
	for _, x := range a {
		if !containsString(b, x) {
			set[x] = true
		}
	}
	out := make([]string, 0, len(set))
	for x := range set {
		out = append(out, x)
	}
	sort.Strings(out)
	return out
}

// ownValues is the values a row's own forms (`<row>/<member>`) hold in fld.
func (c *SpecSetCheck) ownValues(doc *SpecDocument, row, fld string) []string {
	index := c.forms[doc]
	if index == nil {
		index = map[string][]string{}
		for _, p := range sortedCopy(doc.FormPaths()) {
			if slash := strings.LastIndex(p, "/"); slash > 0 {
				index[p[:slash]] = append(index[p[:slash]], p)
			}
		}
		c.forms[doc] = index
	}
	out := []string{}
	for _, p := range index[row] {
		if v, ok := doc.FormField(p, fld); ok {
			out = append(out, SpecSetReviewed(v))
		}
	}
	return out
}

// --- unmarkable derived changes ----------------------------------------------

// unmarkableScan lists every change DeriveFields would write in a document
// under review that cannot be marked exactly: left for the agent.
func (c *SpecSetCheck) unmarkableScan(order int) {
	set := c.Set
	for _, name := range set.Names() {
		doc := set.Get(name)
		root := c.rootSeg(set.RootOf(name))
		derived := DeriveFields(set.Model, doc, SpecDeriveOptions{Marked: true, DryRun: true})
		for _, u := range derived.Unresolved {
			if u.Code != SpecValidationCodeUnmarkable {
				continue
			}
			p := SpecSyncPlace{Document: name, Root: root, Path: u.Path}
			c.add(order, name+" "+u.Path, SpecSyncFinding{
				Code:       SpecSyncCodeUnmarkable,
				Blueprint:  p,
				Detail:     p,
				Holder:     SpecSyncHolderDetail,
				Resolution: SpecSyncResolutionAgent,
				Message:    u.Message + " (in " + name + ")",
			}, nil, nil)
		}
	}
}

// --- pending marks ------------------------------------------------------------

// pendingScan lists every value of every document that holds pending change
// marks.
func (c *SpecSetCheck) pendingScan(order int) {
	set := c.Set
	for _, name := range set.Names() {
		doc := set.Get(name)
		root := c.rootSeg(set.RootOf(name))
		flag := func(path, fld, raw string) {
			if !SpecSetIsPending(raw) {
				return
			}
			p := SpecSyncPlace{
				Document: name, Root: root, Path: path, Field: fld,
				Value: setStrPtr(SpecSetReviewed(raw)), PendingMarks: true,
			}
			what := "the value"
			if fld != "" {
				what = "form field \"" + fld + "\""
			}
			c.add(order, name+" "+path+" "+fld, SpecSyncFinding{
				Code:       SpecSyncCodePendingReview,
				Blueprint:  p,
				Detail:     p,
				Holder:     SpecSyncHolderDetail,
				Resolution: SpecSyncResolutionInfo,
				Message:    what + " at " + path + " in " + name + " holds pending change marks",
			}, nil, nil)
		}
		for _, p := range sortedCopy(doc.ContentPaths()) {
			flag(p, "", doc.ContentOr(p))
		}
		for _, p := range sortedCopy(doc.FormPaths()) {
			for _, f := range sortedCopy(doc.FormFieldNames(p)) {
				flag(p, f, doc.FormFieldOr(p, f))
			}
		}
		for _, p := range sortedCopy(doc.HeadlinePaths()) {
			flag(p, "", doc.HeadlineOr(p))
		}
	}
}

// --- links across two documents ----------------------------------------------

type setInstance struct {
	path string
	cls  *SpecClass
}

// instances is every class instance of a document of root typeName: path and
// class.
func (c *SpecSetCheck) instances(doc *SpecDocument, typeName string) []setInstance {
	refl := c.Refl
	var out []setInstance
	var walk func(cls *SpecClass, path string, onPath map[string]bool)
	walk = func(cls *SpecClass, path string, onPath map[string]bool) {
		out = append(out, setInstance{path, cls})
		for _, f := range cls.Fields {
			if f.HasAnnotation("Reference") {
				continue
			}
			member := path + "/" + refl.FieldSegment(f)
			switch {
			case f.Kind == SpecFieldKindList && f.ElementIsComplex:
				el := refl.ClassNamed(f.ElementType)
				if el == nil {
					continue
				}
				for _, item := range doc.ListItems(member) {
					walk(el, item, map[string]bool{})
				}
			case f.Kind == SpecFieldKindComplex || f.Kind == SpecFieldKindSection:
				child := refl.ClassNamed(strings.ReplaceAll(f.Type, "?", ""))
				if child == nil || onPath[child.Name] {
					continue
				}
				next := map[string]bool{cls.Name: true}
				for k := range onPath {
					next[k] = true
				}
				walk(child, member, next)
			}
		}
	}
	if cls := refl.ClassNamed(typeName); cls != nil {
		walk(cls, c.rootSeg(typeName), map[string]bool{})
	}
	return out
}

// registryDocument is the document a registry class is read in: the one whose
// root details it (a populated root other than the Blueprint's that reaches
// it), else the Blueprint ("" for none).
func (c *SpecSetCheck) registryDocument(sectionID string) string {
	if hit, ok := c.registryDocs[sectionID]; ok {
		return hit
	}
	hit := c.computeRegistryDocument(sectionID)
	c.registryDocs[sectionID] = hit
	return hit
}

func (c *SpecSetCheck) computeRegistryDocument(sectionID string) string {
	classes := map[string]bool{}
	for _, cls := range c.Refl.Model.Classes {
		if cls.SectionID == sectionID {
			classes[cls.Name] = true
		}
	}
	blueprint := ""
	for _, name := range c.Set.Names() {
		root := c.Set.RootOf(name)
		reach, ok := c.reach[root]
		if !ok {
			reach = c.Refl.ReachableClassNames(root)
			c.reach[root] = reach
		}
		reaches := false
		for r := range reach {
			if classes[r] {
				reaches = true
				break
			}
		}
		if !reaches {
			continue
		}
		if root == c.Set.BlueprintRoot {
			blueprint = name
		} else {
			return name
		}
	}
	return blueprint
}

func (c *SpecSetCheck) identity(doc *SpecDocument, item, target string) (string, bool) {
	fld := target[strings.Index(target, ".")+1:]
	if fld == KSectionIDSlot {
		return c.ItemID(doc, item), true
	}
	values := c.ownValues(doc, item, fld)
	if len(values) == 0 {
		return "", false
	}
	return values[0], true
}

// entry is the entry of doc that refersTo names id by, ok=false when none.
func (c *SpecSetCheck) entry(doc *SpecDocument, refersTo []string, id string) (string, bool) {
	byTarget := c.entries[doc]
	if byTarget == nil {
		byTarget = map[string]map[string]string{}
		c.entries[doc] = byTarget
	}
	for _, t := range refersTo {
		index, ok := byTarget[t]
		if !ok {
			index = map[string]string{}
			sid := strings.Split(t, ".")[0]
			for _, lst := range sortedCopy(doc.ListPaths()) {
				for _, item := range doc.ListItems(lst) {
					r := c.Refl.Resolve(item)
					if r == nil || r.TargetClass == nil || r.TargetClass.SectionID != sid {
						continue
					}
					if name, ok := c.identity(doc, item, t); ok {
						if _, seen := index[name]; !seen {
							index[name] = item
						}
					}
				}
			}
			byTarget[t] = index
		}
		if hit, ok := index[id]; ok {
			return hit, true
		}
	}
	return "", false
}

func (c *SpecSetCheck) nearestItem(path string) (string, bool) {
	p := path
	for {
		if c.IsItem(p) {
			return p, true
		}
		slash := strings.LastIndex(p, "/")
		if slash < 0 {
			return "", false
		}
		p = p[:slash]
	}
}

// CrossChecks adds the findings of the links across two documents, summaries
// and inverses, at order; pairs (non-nil) keeps those of the classes with
// those section ids.
func (c *SpecSetCheck) CrossChecks(pairs map[string]bool, order int) {
	for _, name := range c.Set.Names() {
		doc := c.Set.Get(name)
		root := c.Set.RootOf(name)
		for _, in := range c.instances(doc, root) {
			pairID := in.cls.SectionID
			if pairID == "" {
				pairID = in.cls.Name
			}
			if pairs != nil && !pairs[pairID] {
				continue
			}
			for _, f := range in.cls.Fields {
				member := in.path + "/" + c.Refl.FieldSegment(f)
				if s := f.SummaryOf(); s != nil && s.Document != "" && f.Kind == SpecFieldKindList {
					c.crossSummaryRows(order, pairID, name, doc, member, s)
				}
				for _, ff := range f.FormFields {
					if ff.SummaryOf != nil && ff.SummaryOf.Document != "" {
						c.crossSummaryField(order, pairID, name, doc, member, ff)
					}
					if ff.InverseOf != nil && !ff.InverseOf.Symmetric() {
						c.crossInverse(order, pairID, name, doc, member, ff)
					}
				}
			}
		}
	}
}

// setElement is one detail element of a cross summary: its item and id.
type setElement struct{ item, id string }

// crossDetail is the detail elements of a cross summary: document name,
// document, elements; ok=false when the detail is not started or does not
// resolve.
func (c *SpecSetCheck) crossDetail(s *SpecSummaryOf) (string, *SpecDocument, []setElement, bool) {
	name, ok := c.Set.NameOf(s.Document)
	if !ok {
		return "", nil, nil, false // not started
	}
	doc := c.Set.Get(name)
	seg := c.rootSeg(c.Set.RootOf(name))
	var r *SpecPlaceResolution
	if slash := strings.Index(s.Detail, "/"); slash < 0 {
		r = SpecResolvePlaceAt(c.Refl, s.Detail, seg)
	} else {
		head := SpecResolvePlaceAt(c.Refl, s.Detail[:slash], seg)
		if head == nil {
			return "", nil, nil, false
		}
		scope := head.Path
		if head.Kind == SpecPlaceKindList {
			scope = head.Path + "-*"
		}
		if concrete := c.Expand(doc, scope); len(concrete) > 0 {
			p, err := ParseSpecPlace(s.Detail[slash+1:])
			if err != nil {
				return "", nil, nil, false
			}
			r, err = p.Resolve(c.Refl, concrete[0])
			if err != nil {
				return "", nil, nil, false
			}
		}
	}
	if r == nil || r.Kind != SpecPlaceKindList {
		return "", nil, nil, false
	}
	elements := []setElement{}
	seen := map[string]int{}
	for _, lst := range c.Expand(doc, r.Path) {
		for _, item := range doc.ListItems(lst) {
			e := setElement{item, c.ItemID(doc, item)}
			if at, ok := seen[item]; ok {
				elements[at] = e
				continue
			}
			seen[item] = len(elements)
			elements = append(elements, e)
		}
	}
	return name, doc, elements, true
}

func (c *SpecSetCheck) place(name, path, fld string, value *string) SpecSyncPlace {
	root := ""
	if name != "" {
		root = c.rootSeg(c.Set.RootOf(name))
	}
	return SpecSyncPlace{Document: name, Root: root, Path: path, Field: fld, Value: value}
}

func (c *SpecSetCheck) cross(order int, code, pair string, here, there SpecSyncPlace, message string) {
	document := here.Document
	if document == "" {
		document = "None"
	}
	c.add(order, document+" "+here.Path+" "+here.Field+" "+there.valueOr(), SpecSyncFinding{
		Code:       code,
		Pair:       pair,
		Blueprint:  here,
		Detail:     there,
		Holder:     SpecSyncHolderDetail,
		Resolution: SpecSyncResolutionAgent,
		Message:    message,
	}, nil, nil)
}

func setListOf(elements []setElement) string {
	if len(elements) == 0 {
		return ""
	}
	first := elements[0].item
	return first[:strings.LastIndex(first, "-")]
}

func (c *SpecSetCheck) crossSummaryRows(order int, pair, name string, doc *SpecDocument, lst string, s *SpecSummaryOf) {
	dName, dDoc, elements, ok := c.crossDetail(s)
	if !ok {
		return
	}
	byID := map[string]string{}
	for _, e := range elements {
		byID[e.id] = e.item
	}
	named := map[string]string{}
	for _, row := range doc.ListItems(lst) {
		var ids []string
		if s.Match == "" {
			ids = []string{c.ItemID(doc, row)}
		} else {
			ids = c.matchIDs(doc, s.Match, row)
		}
		for _, id := range ids {
			target, ok := byID[id]
			if !ok {
				c.cross(order, SpecSyncCodeCrossSummaryMismatch, pair,
					c.place(name, row, "", setStrPtr(id)),
					c.place(dName, setListOf(elements), "", setStrPtr(id)),
					"the summary row names "+id+", which is no element of "+s.Detail+" in "+dName)
				continue
			}
			if prev, ok := named[id]; ok {
				c.cross(order, SpecSyncCodeCrossSummaryMismatch, pair,
					c.place(name, row, "", setStrPtr(id)),
					c.place(dName, target, "", setStrPtr(id)),
					"the summary row names "+id+", which "+prev+" names already")
				continue
			}
			named[id] = row
			for _, rp := range s.Repeats {
				mine, okM := c.valueAt(doc, rp.Key, row)
				theirs, okT := c.valueAt(dDoc, rp.Value, target)
				if !okM || !okT || mine.value == "" {
					continue
				}
				if mine.value != theirs.value {
					c.cross(order, SpecSyncCodeCrossSummaryMismatch, pair,
						c.place(name, mine.path, mine.field, setStrPtr(mine.value)),
						c.place(dName, theirs.path, theirs.field, setStrPtr(theirs.value)),
						rp.Key+" repeats "+rp.Value+" of "+id+" as \""+mine.value+"\", but "+
							dName+" holds \""+theirs.value+"\"")
				}
			}
		}
	}
	if s.Relation == "equal" {
		for _, e := range elements {
			if _, ok := named[e.id]; ok {
				continue
			}
			c.cross(order, SpecSyncCodeCrossSummaryMismatch, pair,
				c.place(name, lst, "", nil),
				c.place(dName, e.item, "", setStrPtr(e.id)),
				"the detail element "+e.id+" of "+dName+" is named by no row of "+lst+" (relation: equal)")
		}
	}
}

func (c *SpecSetCheck) matchIDs(doc *SpecDocument, place, row string) []string {
	v, ok := c.valueAt(doc, place, row)
	if !ok {
		return []string{}
	}
	return SpecLinkIDs(v.value)
}

type setValueAt struct{ path, value, field string }

// valueAt is the value of place under the concrete anchor.
func (c *SpecSetCheck) valueAt(doc *SpecDocument, place, anchor string) (setValueAt, bool) {
	r := SpecResolvePlaceAt(c.Refl, place, anchor)
	if r == nil {
		return setValueAt{}, false
	}
	paths := c.Expand(doc, r.Path)
	if len(paths) != 1 {
		return setValueAt{}, false
	}
	p := paths[0]
	raw := ""
	switch r.Kind {
	case SpecPlaceKindFormField:
		raw = doc.FormFieldOr(p, r.Field())
	case SpecPlaceKindContent:
		raw = doc.ContentOr(p)
	case SpecPlaceKindHeadline:
		raw = doc.HeadlineOr(p)
	case SpecPlaceKindSectionID:
		if c.IsItem(p) {
			raw = c.ItemID(doc, p)
		}
	}
	return setValueAt{p, SpecSetReviewed(raw), r.Field()}, true
}

func (c *SpecSetCheck) crossSummaryField(order int, pair, name string, doc *SpecDocument, form string, ff *FormFieldSpec) {
	raw, ok := doc.FormField(form, ff.Name)
	if !ok {
		return
	}
	s := ff.SummaryOf
	dName, _, elements, ok := c.crossDetail(s)
	if !ok {
		return
	}
	known := map[string]bool{}
	for _, e := range elements {
		known[e.id] = true
	}
	seen := map[string]bool{}
	for _, id := range SpecLinkIDs(SpecSetReviewed(raw)) {
		fresh := !seen[id]
		seen[id] = true
		if !known[id] || !fresh {
			message := "form field \"" + ff.Name + "\" names " + id + ", which is no element of " +
				s.Detail + " in " + dName
			if known[id] {
				message = "form field \"" + ff.Name + "\" names " + id + " twice"
			}
			c.cross(order, SpecSyncCodeCrossSummaryMismatch, pair,
				c.place(name, form, ff.Name, setStrPtr(id)),
				c.place(dName, setListOf(elements), "", setStrPtr(id)),
				message)
		}
	}
	if s.Relation == "equal" {
		for _, e := range elements {
			if seen[e.id] {
				continue
			}
			c.cross(order, SpecSyncCodeCrossSummaryMismatch, pair,
				c.place(name, form, ff.Name, nil),
				c.place(dName, e.item, "", setStrPtr(e.id)),
				"the detail element "+e.id+" of "+dName+" is not named in \""+ff.Name+"\" (relation: equal)")
		}
	}
}

func (c *SpecSetCheck) crossInverse(order int, pair, name string, doc *SpecDocument, form string, ff *FormFieldSpec) {
	raw, ok := doc.FormField(form, ff.Name)
	if !ok {
		return
	}
	value := SpecSetReviewed(raw)
	if value == "" {
		return
	}
	inv := ff.InverseOf
	sidOf := func(p string) string {
		if res := c.Refl.Resolve(p); res != nil && res.TargetClass != nil {
			return res.TargetClass.SectionID
		}
		return ""
	}
	for _, b := range SpecLinkIDs(value) {
		// The document the named entry is read in.
		var registries []string
		for _, t := range ff.RefersTo {
			if r := strings.Split(t, ".")[0]; !containsString(registries, r) {
				registries = append(registries, r)
			}
		}
		for _, registry := range registries {
			other := c.registryDocument(registry)
			if other == "" || other == name {
				continue
			}
			oDoc := c.Set.Get(other)
			var targets []string
			for _, t := range ff.RefersTo {
				if strings.Split(t, ".")[0] == registry {
					targets = append(targets, t)
				}
			}
			bPath, ok := c.entry(oDoc, targets, b)
			if !ok {
				continue
			}
			for _, end := range inv.Fields {
				r := SpecResolvePlaceAt(c.Refl, end, bPath)
				if r == nil || r.FormField == nil {
					continue
				}
				// This field's entry, named as the other end names it, and read
				// in its own registry document only.
				aClasses := map[string]bool{}
				for _, t := range r.FormField.RefersTo {
					aClasses[strings.Split(t, ".")[0]] = true
				}
				a, ok := c.nearestItem(form)
				for ok && !aClasses[sidOf(a)] {
					slash := strings.LastIndex(a, "/")
					if slash < 0 {
						ok = false
						break
					}
					a, ok = c.nearestItem(a[:slash])
				}
				if !ok {
					continue
				}
				if c.registryDocument(sidOf(a)) != name {
					continue
				}
				aID, found := "", false
				for _, t := range r.FormField.RefersTo {
					if v, ok := c.identity(doc, a, t); ok {
						aID, found = v, true
						break
					}
				}
				if !found {
					continue
				}
				ends := c.Expand(oDoc, r.Path)
				fld := r.Field()
				namesBack := false
				for _, p := range ends {
					if containsString(SpecLinkIDs(SpecSetReviewed(oDoc.FormFieldOr(p, fld))), aID) {
						namesBack = true
						break
					}
				}
				if !namesBack {
					endPath := bPath
					if len(ends) > 0 {
						endPath = ends[0]
					}
					c.cross(order, SpecSyncCodeCrossInverseMissing, pair,
						c.place(name, form, ff.Name, setStrPtr(b)),
						c.place(other, endPath, r.Field(), setStrPtr(aID)),
						"form field \""+ff.Name+"\" in "+name+" names "+b+", but "+b+" in "+other+
							" does not name "+aID+" back ("+strings.Join(inv.Fields, ", ")+")")
				}
			}
		}
	}
}

// --- the global rename ----------------------------------------------------------

// SpecRenameError is why RenameID refuses.
type SpecRenameError struct {
	// Documents are the documents already holding the new id.
	Documents []string
	// Message is the prose for the reader.
	Message string
}

// Error implements the error interface.
func (e *SpecRenameError) Error() string { return "SpecRenameError: " + e.Message }

// SpecRenameChange is one value RenameID changed.
type SpecRenameChange struct {
	// Document is the document's name.
	Document string
	// Path is a list item (its section id) or the value's path.
	Path string
	// Kind is `sectionId` or `value` (a form field or content).
	Kind string
	// OldValue is the value before.
	OldValue string
	// NewValue is the value after.
	NewValue string
	// Field is the form field, "" for none.
	Field string
}

// ToJSON is the canonical JSON form.
func (c SpecRenameChange) ToJSON() map[string]any {
	out := map[string]any{"document": c.Document, "path": c.Path, "kind": c.Kind, "old": c.OldValue, "new": c.NewValue}
	if c.Field != "" {
		out["field"] = c.Field
	}
	return out
}

func setAllItems(doc *SpecDocument) []string {
	var out []string
	for _, lst := range sortedCopy(doc.ListPaths()) {
		out = append(out, doc.ListItems(lst)...)
	}
	return out
}

// setIDByte reports whether b belongs to an id (letters, digits, hyphens).
func setIDByte(b byte) bool {
	return b == '-' || (b >= '0' && b <= '9') || (b >= 'A' && b <= 'Z') || (b >= 'a' && b <= 'z')
}

// setReplaceToken replaces every whole-token occurrence of from in v with to
// (no letter, digit or hyphen on either side); ok reports whether there was
// one.
func setReplaceToken(v, from, to string) (string, bool) {
	if from == "" {
		return v, false
	}
	var out strings.Builder
	found := false
	i := 0
	for i < len(v) {
		if strings.HasPrefix(v[i:], from) &&
			(i == 0 || !setIDByte(v[i-1])) &&
			(i+len(from) >= len(v) || !setIDByte(v[i+len(from)])) {
			out.WriteString(to)
			i += len(from)
			found = true
			continue
		}
		out.WriteByte(v[i])
		i++
	}
	return out.String(), found
}

// RenameID renames the section id from to to in every document of set at
// once (DP-part-cleanup-2): the list element carrying it, and every value
// naming it as a whole token (references, comma-separated lists, the texts
// link rows are extracted from). Refused with a *SpecRenameError, nothing
// changed, when an element of any document already carries to. Returns the
// changes, in document and path order.
func RenameID(set *SpecDocumentSet, from, to string) ([]SpecRenameChange, error) {
	c := NewSpecSetCheck(set)
	holders := []string{}
	for _, name := range set.Names() {
		doc := set.Get(name)
		for _, i := range setAllItems(doc) {
			if c.ItemID(doc, i) == to {
				holders = append(holders, name)
				break
			}
		}
	}
	if len(holders) > 0 {
		return nil, &SpecRenameError{
			Documents: holders,
			Message:   to + " is already an id in " + strings.Join(holders, ", "),
		}
	}
	changes := []SpecRenameChange{}
	for _, name := range set.Names() {
		doc := set.Get(name)
		for _, item := range setAllItems(doc) {
			if c.ItemID(doc, item) != from {
				continue
			}
			if err := doc.SetItemSectionID(item, to); err != nil {
				return changes, err
			}
			changes = append(changes, SpecRenameChange{
				Document: name, Path: item, Kind: "sectionId", OldValue: from, NewValue: to,
			})
		}
		for _, p := range sortedCopy(doc.ContentPaths()) {
			v := doc.ContentOr(p)
			n, ok := setReplaceToken(v, from, to)
			if !ok {
				continue
			}
			doc.SetContent(p, n)
			changes = append(changes, SpecRenameChange{Document: name, Path: p, Kind: "value", OldValue: v, NewValue: n})
		}
		for _, p := range sortedCopy(doc.FormPaths()) {
			for _, f := range sortedCopy(doc.FormFieldNames(p)) {
				v := doc.FormFieldOr(p, f)
				n, ok := setReplaceToken(v, from, to)
				if !ok {
					continue
				}
				doc.SetFormField(p, f, n)
				changes = append(changes, SpecRenameChange{
					Document: name, Path: p, Field: f, Kind: "value", OldValue: v, NewValue: n,
				})
			}
		}
	}
	return changes, nil
}
