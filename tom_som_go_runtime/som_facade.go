package somruntime

// som_facade.go — the hand-written runtime support for the generated typed
// object model (`tom_som_go_v0`), a faithful port of
// `tom_som_dart_runtime/lib/src/som_facade.dart` (and the TypeScript
// `som_facade.ts`).
//
// The generated structs are a thin editing facade over the generic
// SpecDocument: every typed accessor reads or writes the path-keyed memory
// representation directly, so a mutation made through the typed surface is
// immediately visible through the generic path and vice-versa (SOM §6 — the two
// access paths share one document). These base types (SomNode, SomList,
// SomScalar) hold no state of their own beyond the document and a path; the
// generated structs embed SomNode and only add typed accessors.
//
// Go has no classes or inheritance: the generated structs embed SomNode (value)
// and reach the bound document/path through the exported Doc() / Path() methods.
// Because a method declared on the embedding struct shadows a promoted method of
// the same name, an accessor named Doc or Path would mask these and break path
// derivation; the Go emitter therefore sanitises those two names (the analogue
// of the TypeScript doc/path guard).

import (
	"strings"
	"time"
)

// SomNode is the base every generated typed facade struct embeds. It binds a
// facade instance to the SpecDocument it edits and the path it lives at (the
// globally-unique section path, per spec_paths). The bound fields are
// unexported; the generated code in another package reads them through Doc() and
// Path() and constructs children via NewSomNode.
type SomNode struct {
	doc  *SpecDocument
	path string
}

// NewSomNode binds a facade node to a document and a path.
func NewSomNode(doc *SpecDocument, path string) SomNode {
	return SomNode{doc: doc, path: path}
}

// Doc returns the document this node edits.
func (n SomNode) Doc() *SpecDocument { return n.doc }

// Path returns the globally-unique section path of this node.
func (n SomNode) Path() string { return n.path }

// SectionID returns this node's section id when it is a list item (AA1
// criterion 1 read), or "" for non-list nodes (roots, complex/section children
// — their id is the fixed @SectionId already embedded in Path()).
//
// Named SectionID / SetSectionID — names the Go emitter reserves in its
// accessor allocator (the analogue of the Dart/TypeScript $sectionId
// collision-proofing, AA-6 decision AF-D1) — so this structural accessor can
// never collide with a typed field a generated struct emits.
func (n SomNode) SectionID() string { return n.doc.ItemSectionIDOr(n.path) }

// SetSectionID overrides this list item's section id (AA1 criterion 5): an
// arbitrary suffix, validated unique within the owning list. Returns a
// *SpecSectionIDCollision on a duplicate, or an error if this node is not a
// live list item. An empty id is a no-op.
func (n SomNode) SetSectionID(id string) error {
	if id == "" {
		return nil
	}
	return n.doc.SetItemSectionID(n.path, id)
}

// Headline returns this section's stored headline (YRD3), or "" when none is
// stored — the effective heading then falls back to the derived default.
//
// Named Headline / SetHeadline — names the Go emitter reserves in its accessor
// allocator (the same collision-proofing as SectionID, AF-D1) — so this
// structural accessor can never collide with a typed field a generated struct
// emits.
func (n SomNode) Headline() string { return n.doc.HeadlineOr(n.path) }

// SetHeadline stores a headline for this section (YRD3). An empty value clears
// the stored headline, reverting to the derived default heading.
func (n SomNode) SetHeadline(value string) { n.doc.SetHeadline(n.path, value) }

// CodeSpec returns this section's CodeSpecs forward link
// (codespecs_mapping.md §9.2) as the comma-joined list of code locations, or ""
// when the section carries no mapping. Sparse exactly like Headline, and named
// CodeSpec / SetCodeSpec for the same collision-proofing as SectionID (AF-D1).
func (n SomNode) CodeSpec() string { return n.doc.CodeSpecOr(n.path) }

// SetCodeSpec stores this section's CodeSpecs forward link
// (codespecs_mapping.md §9.2). An empty value clears it, returning the section
// to "no code mapping".
func (n SomNode) SetCodeSpec(value string) { n.doc.SetCodeSpec(n.path, value) }

// IsEmpty reports whether this section holds no value at its path or nested
// beneath it (delegates to HasValuesUnder). Promoted to every generated section
// facade via the embedded SomNode. (SOM §21.)
func (n SomNode) IsEmpty() bool { return !n.doc.HasValuesUnder(n.path) }

// CanHaveContent reports whether this *type* declares the standard `content`
// text leaf — i.e. whether its typed facade carries a Content() accessor
// (SOM §21).
//
// This is a structural / schema predicate: a per-type constant answering "*can*
// this node hold body text?" without probing Content(). A type that declares no
// `content` leaf — a scalar list item, whose value *is* its item path —
// inherits this false default via the embedded SomNode; every generated
// *section* type shadows it with a CanHaveContent() returning true, since
// tom_specs_model_rules.md §10.2 requires `content: String?` on all of them,
// pure containers included.
//
// It is deliberately distinct from the two state predicates: the generic
// SpecDocument.HasContent answers "is a value present at this leaf *now*?" and
// IsEmpty answers "is this subtree empty *now*?". CanHaveContent never looks at
// the document — it describes the model, not the data.
func (n SomNode) CanHaveContent() bool { return false }

// SomScalar is a scalar list item — a bare string value held in the document's
// content store at its own item path. Used as the element facade for non-complex
// (string/scalar) lists.
type SomScalar struct {
	SomNode
}

// NewSomScalar binds a scalar facade to a document and an item path.
func NewSomScalar(doc *SpecDocument, path string) *SomScalar {
	return &SomScalar{SomNode: NewSomNode(doc, path)}
}

// Value returns the string value at this item's path ("" when unset).
func (s *SomScalar) Value() string { return s.doc.ContentOr(s.path) }

// SetValue sets the string value (an empty string clears it, per SpecDocument).
func (s *SomScalar) SetValue(v string) { s.doc.SetContent(s.path, v) }

// SomList is a typed view over a list field, layered over the document's list
// store. Items are addressed by their stable item paths (SpecDocument.ListItems);
// each is wrapped in an element facade by factory. The wrapper holds no items
// itself — every operation reads through the live document, so it always
// reflects the current state.
type SomList[T any] struct {
	doc      *SpecDocument
	listPath string
	factory  func(*SpecDocument, string) T
	// pattern is the list field's @SectionIdPattern (e.g. `DACEN-ITEM-xxx`), or
	// "" for a pattern-less (scalar) list. It drives section-id generation on
	// Add / AddOn (AA1 criteria 3–5).
	pattern string
}

// NewSomList binds a typed list view to a document, a list path, an element
// factory and the field's @SectionIdPattern ("" when the field has none).
func NewSomList[T any](doc *SpecDocument, listPath string, factory func(*SpecDocument, string) T, pattern string) *SomList[T] {
	return &SomList[T]{doc: doc, listPath: listPath, factory: factory, pattern: pattern}
}

// ListPath returns the list container's section path (items hang off it as
// "<listPath>-<seq>"). The Go counterpart of Dart's SomList.listPath /
// Python's list_path, so a traversal can name the container it is iterating.
func (l *SomList[T]) ListPath() string { return l.listPath }

// Length returns the number of items currently in the list.
func (l *SomList[T]) Length() int { return l.doc.ListItemCount(l.listPath) }

// Items returns the element facades for every item, in order.
func (l *SomList[T]) Items() []T {
	paths := l.doc.ListItems(l.listPath)
	out := make([]T, len(paths))
	for i, p := range paths {
		out[i] = l.factory(l.doc, p)
	}
	return out
}

// At returns the element facade for the item at index.
func (l *SomList[T]) At(index int) T {
	return l.factory(l.doc, l.doc.ListItems(l.listPath)[index])
}

// SectionIDs returns the section ids currently assigned within this list, in
// item order (AA1 criterion 1 read).
func (l *SomList[T]) SectionIDs() []string {
	return l.doc.ListItemSectionIDs(l.listPath)
}

// Add appends a new item and returns its element facade.
//
// When the list has a pattern, the new item is assigned a section id generated
// from that pattern using today's date for the two-letter-date component (AA1
// criteria 3–4). A pattern-less list appends without a section id.
//
// Go has no exceptions, optional parameters or overloading, so the JS/TS
// `add(sectionId?, date?)` splits into three methods: Add (generate, today),
// AddOn (generate, explicit date) and AddWithID (explicit override). See
// decision AF-D2.
func (l *SomList[T]) Add() T {
	now := time.Now()
	return l.factory(l.doc, l.addItemPath(int(now.Month()), now.Day()))
}

// AddOn appends a new item whose generated section id uses the given (month,
// day) for the two-letter-date component (AA1 criteria 3–4). For a pattern-less
// list it behaves like Add (the date is ignored).
func (l *SomList[T]) AddOn(month, day int) T {
	return l.factory(l.doc, l.addItemPath(month, day))
}

// AddContent appends a content-only item and sets its nested content leaf in
// one call, then returns the new item's element facade — the Go port of the
// Dart SomList.addContent (SOM §21).
//
// The item's section id follows the same rules as Add: when the list has a
// @SectionIdPattern the id is generated from that pattern using today's date for
// the two-letter-date component (AA1 criteria 3–4); a pattern-less list appends
// without a section id. content is written to the item's nested "<itemPath>/content"
// leaf, so it is immediately visible both through the returned handle and via the
// generic document path. (Scalar/string lists — whose value lives at the item
// path itself rather than a nested content leaf — are out of scope.)
func (l *SomList[T]) AddContent(content string) T {
	now := time.Now()
	itemPath := l.addItemPath(int(now.Month()), now.Day())
	l.doc.SetContent(itemPath+"/content", content) // nested <item>/content leaf
	return l.factory(l.doc, itemPath)
}

// AddContentOn is the explicit-date companion to AddContent: it appends a
// content-only item whose generated section id uses the given (month, day) for
// the two-letter-date component, writes content to the item's nested
// "<itemPath>/content" leaf, and returns the new item's element facade. For a
// pattern-less list the date is ignored (it appends without a section id).
func (l *SomList[T]) AddContentOn(content string, month, day int) T {
	itemPath := l.addItemPath(month, day)
	l.doc.SetContent(itemPath+"/content", content) // nested <item>/content leaf
	return l.factory(l.doc, itemPath)
}

// Contents returns an ordered, read-only view of every item's nested content
// leaf ("<itemPath>/content"), in item order — the Go port of the Dart
// SomList.contents (SOM §21). A missing leaf reads as "" (the Go
// empty-string sentinel for absent content, so this is natural). Scalar/string
// lists are out of scope (their value lives at the item path itself).
func (l *SomList[T]) Contents() []string {
	paths := l.doc.ListItems(l.listPath)
	out := make([]string, len(paths))
	for i, p := range paths {
		out[i] = l.doc.ContentOr(p + "/content")
	}
	return out
}

// addItemPath is the shared append-and-derive-section-id helper behind Add /
// AddOn / AddContent (mirrors the Dart _addItemPath). A pattern-less list
// appends without a section id; a patterned list generates one from the pattern
// using the given (month, day) for the two-letter-date component (AA1
// criteria 3–4) and appends under it.
func (l *SomList[T]) addItemPath(month, day int) string {
	if l.pattern == "" {
		return l.doc.AddListItem(l.listPath)
	}
	id := GenerateListItemSectionID(l.pattern, month, day, l.doc.ListItemSectionIDs(l.listPath))
	itemPath, _ := l.doc.AddListItemWithSectionID(l.listPath, id)
	return itemPath
}

// AddWithID appends a new item with an explicit section id override (AA1
// criterion 5), validated unique within the list. Returns a
// *SpecSectionIDCollision on a duplicate. For a pattern-less list the id is
// still recorded (an explicit override is always honoured).
func (l *SomList[T]) AddWithID(sectionID string) (T, error) {
	itemPath, err := l.doc.AddListItemWithSectionID(l.listPath, sectionID)
	if err != nil {
		var zero T
		return zero, err
	}
	return l.factory(l.doc, itemPath), nil
}

// RemoveAt removes the item at index and every value nested beneath it.
func (l *SomList[T]) RemoveAt(index int) {
	l.doc.RemoveListItem(l.doc.ListItems(l.listPath)[index])
}

// SomVersionError is raised when a generated object model is instantiated
// against a document whose authoring model version it must not edit (SOM §4.2).
type SomVersionError struct {
	Message string
}

// Error implements the error interface.
func (e *SomVersionError) Error() string { return "SomVersionError: " + e.Message }

type somVersion struct {
	major int
	minor int
}

func tryParseSomVersion(raw string) (somVersion, bool) {
	parts := strings.Split(raw, ".")
	if len(parts) != 2 {
		return somVersion{}, false
	}
	major, ok1 := tryInt(parts[0])
	minor, ok2 := tryInt(parts[1])
	if !ok1 || !ok2 {
		return somVersion{}, false
	}
	return somVersion{major: major, minor: minor}, true
}

func tryInt(raw string) (int, bool) {
	if raw == "" {
		return 0, false
	}
	i := 0
	if raw[0] == '-' || raw[0] == '+' {
		if len(raw) == 1 {
			return 0, false
		}
		i = 1
	}
	for ; i < len(raw); i++ {
		if raw[i] < '0' || raw[i] > '9' {
			return 0, false
		}
	}
	return atoi(raw), true
}

// SomEditability is the outcome of the SOM §4.2 version check, as a value a
// read-only viewer can branch on instead of handling the error returned by
// CheckSomModelVersion (SOM §21).
//
// It is the non-error-returning companion to CheckSomModelVersion:
// CheckSomModelVersion returns an error on any value other than
// SomEditabilityEditable, while SomEditabilityFor returns the same
// classification without an error so a consumer can decide *open for edit* vs
// *open read-only* up front.
type SomEditability int

const (
	// SomEditabilityEditable — the object model may edit the document in place: an
	// empty stamp (a brand-new document) or a same-major, minor-`<=` stamp.
	SomEditabilityEditable SomEditability = iota

	// SomEditabilityReadOnlyCrossMajor — the document was authored under a
	// different major version; it may be read/converted but never edited in place.
	SomEditabilityReadOnlyCrossMajor

	// SomEditabilityRejectedNewerMinor — the document is same-major but a newer
	// minor than the object model; an older model must not edit a newer document.
	SomEditabilityRejectedNewerMinor

	// SomEditabilityInvalidVersion — one of the two versions is not a valid
	// major.minor string: usually the document stamp, but a malformed
	// *generated* version lands here too. One outcome with two causes; the
	// refusal message returned by CheckSomModelVersion is where they separate.
	SomEditabilityInvalidVersion
)

// SomEditabilityFor classifies a document's editability under the SOM §4.2
// rules without returning an error (SOM §21). generated is the object model's
// own major.minor version; documentVersion is the document's recorded authoring
// stamp ("" for a brand-new, never-stamped document — the Go empty-string
// sentinel, CS4-D2).
//
// This is the single definition of the version rules; CheckSomModelVersion
// switches on the value returned here, so the two never diverge.
func SomEditabilityFor(generated, documentVersion string) SomEditability {
	if documentVersion == "" {
		return SomEditabilityEditable
	}
	gen, okGen := tryParseSomVersion(generated)
	docv, okDoc := tryParseSomVersion(documentVersion)
	if !okGen || !okDoc {
		return SomEditabilityInvalidVersion
	}
	if docv.major != gen.major {
		return SomEditabilityReadOnlyCrossMajor
	}
	if docv.minor > gen.minor {
		return SomEditabilityRejectedNewerMinor
	}
	return SomEditabilityEditable
}

// CheckSomModelVersion is the instantiation-time version check every generated
// root facade performs (SOM §4.2). generated is the object model's own
// major.minor version; documentVersion is the document's recorded authoring
// stamp ("" for a brand-new, never-stamped document).
//
// Rules (see SomEditabilityFor, which this delegates to):
//   - an empty document stamp is always accepted — a new document is stamped on
//     first edit;
//   - within the same major version, a document whose minor is <= the generated
//     minor is editable; a document whose minor is greater is rejected;
//   - a different major version is always rejected (cross-major is read/convert
//     only, never in-place edit).
//
// Returns a *SomVersionError on any rejection or an unparseable stamp.
func CheckSomModelVersion(generated, documentVersion string) error {
	switch SomEditabilityFor(generated, documentVersion) {
	case SomEditabilityEditable:
		return nil
	case SomEditabilityInvalidVersion:
		// Distinguish an unparseable generated version from an unparseable
		// document stamp, matching the original messages.
		if _, ok := tryParseSomVersion(generated); !ok {
			return &SomVersionError{Message: "\"" + generated + "\" is not a valid major.minor version"}
		}
		return &SomVersionError{Message: "document model version \"" + documentVersion + "\" is not a valid major.minor"}
	case SomEditabilityReadOnlyCrossMajor:
		gen, _ := tryParseSomVersion(generated)
		docv, _ := tryParseSomVersion(documentVersion)
		return &SomVersionError{Message: "document major version " + itoa(docv.major) +
			" differs from the object model major version " + itoa(gen.major) +
			"; cross-major documents are read-only"}
	case SomEditabilityRejectedNewerMinor:
		return &SomVersionError{Message: "document model version " + documentVersion +
			" is newer than the object model version " + generated +
			"; an older object model cannot edit a newer document"}
	}
	return nil
}
