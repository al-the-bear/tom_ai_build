package somruntime

// som_facade.go — the hand-written runtime support for the generated typed
// object model (`tom_som_go_v0`), a faithful port of
// `tom_som_dart_runtime/lib/src/som_facade.dart` (and the TypeScript
// `som_facade.ts`).
//
// The generated structs are a thin editing facade over the generic SpecDocument:
// every typed accessor reads or writes the path-keyed memory representation
// directly, so a mutation made through the typed surface is immediately visible
// through the generic path and vice-versa (§3 — the two access paths share one
// document). These base types (SomNode, SomList, SomScalar) hold no state of
// their own beyond the document and a path; the generated structs embed SomNode
// and only add typed accessors.
//
// Go has no classes or inheritance: the generated structs embed SomNode (value)
// and reach the bound document/path through the exported Doc() / Path() methods.
// Because a method declared on the embedding struct shadows a promoted method of
// the same name, an accessor named Doc or Path would mask these and break path
// derivation; the Go emitter therefore sanitises those two names (the analogue
// of the TypeScript doc/path guard).

import "strings"

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
}

// NewSomList binds a typed list view to a document, a list path and an element
// factory.
func NewSomList[T any](doc *SpecDocument, listPath string, factory func(*SpecDocument, string) T) *SomList[T] {
	return &SomList[T]{doc: doc, listPath: listPath, factory: factory}
}

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

// Add appends a new item and returns its element facade.
func (l *SomList[T]) Add() T {
	return l.factory(l.doc, l.doc.AddListItem(l.listPath))
}

// RemoveAt removes the item at index and every value nested beneath it.
func (l *SomList[T]) RemoveAt(index int) {
	l.doc.RemoveListItem(l.doc.ListItems(l.listPath)[index])
}

// SomVersionError is raised when a generated object model is instantiated
// against a document whose authoring model version it must not edit (§2.2).
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

// CheckSomModelVersion is the instantiation-time version check every generated
// root facade performs (§2.2). generated is the object model's own major.minor
// version; documentVersion is the document's recorded authoring stamp ("" for a
// brand-new, never-stamped document).
//
// Rules:
//   - an empty document stamp is always accepted — a new document is stamped on
//     first edit;
//   - within the same major version, a document whose minor is <= the generated
//     minor is editable; a document whose minor is greater is rejected;
//   - a different major version is always rejected (cross-major is read/convert
//     only, never in-place edit).
//
// Returns a *SomVersionError on any rejection or an unparseable stamp.
func CheckSomModelVersion(generated, documentVersion string) error {
	if documentVersion == "" {
		return nil
	}
	gen, ok := tryParseSomVersion(generated)
	if !ok {
		return &SomVersionError{Message: "\"" + generated + "\" is not a valid major.minor version"}
	}
	docv, ok := tryParseSomVersion(documentVersion)
	if !ok {
		return &SomVersionError{Message: "document model version \"" + documentVersion + "\" is not a valid major.minor"}
	}
	if docv.major != gen.major {
		return &SomVersionError{Message: "document major version " + itoa(docv.major) +
			" differs from the object model major version " + itoa(gen.major) +
			"; cross-major documents are read-only"}
	}
	if docv.minor > gen.minor {
		return &SomVersionError{Message: "document model version " + documentVersion +
			" is newer than the object model version " + generated +
			"; an older object model cannot edit a newer document"}
	}
	return nil
}
