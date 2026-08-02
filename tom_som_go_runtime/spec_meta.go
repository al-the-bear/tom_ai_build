package somruntime

// spec_meta.go — the canonical SOM **metadata tree**: the runtime's SOM §7.1
// node types, a faithful port of `tom_som_dart_runtime/lib/src/spec_meta.dart`
// (and the TypeScript `spec_meta.ts`).
//
// One SomMetaTree exists per document root. Its nodes carry *every*
// `tom_specs_core` annotation the model source declares, plus the exact class
// and member names, so the tree is the single language-neutral description of a
// document's structure:
//
//   - SomMetaNode — one node per navigable model position (SOM §7.1), with section
//     id / pattern, kind, serialization order, @Min, content type,
//     help/comment/doc texts, form metadata, traceability links
//     (@MapsTo / @DetailedIn) and the lossless Extra
//     annotation list;
//   - SomMetaTree — wires parent links and absolute paths (the SOM §8 path grammar
//     shared with spec_paths.go) and provides the two dynamic lookups every
//     runtime keeps: ByID and ByPath.
//
// The runtime only *defines* these types; the generated facades (SOM §8) emit the
// populated tree as statically initialized values, and tests build small
// fixture trees by hand.
//
// Go conventions (shared with the rest of the package): the empty string is the
// idiomatic nullable string ("" = absent), optional ints are *int, and the
// other ports' throwing accessors return errors instead (Tree/Parent/Path/
// ItemPath and SomMetaRef.Meta).

import (
	"errors"
	"regexp"
	"strings"
)

// The structural kind of a metadata node, mirroring SOM §7.1
// (`list | form | section | content | enum | complex | scalar`). The values are
// identical to the SpecFieldKind* constants, so the bridge maps them 1:1.
const (
	// SomMetaKindList is a List<T> field; items are addressed by `-<seq>` path
	// suffixes and described by SomMetaNode.ElementNode.
	SomMetaKindList = "list"
	// SomMetaKindForm is a @Form content section (its fields live in
	// SomMetaNode.Form).
	SomMetaKindForm = "form"
	// SomMetaKindSection is a field rendered as a section of its own.
	SomMetaKindSection = "section"
	// SomMetaKindContent is a free-text (markdown) content leaf.
	SomMetaKindContent = "content"
	// SomMetaKindEnumValue is an enum-valued leaf.
	SomMetaKindEnumValue = "enum"
	// SomMetaKindComplex is a field typed by another model class (collapses
	// into that class: the node's children are the target class's fields).
	SomMetaKindComplex = "complex"
	// SomMetaKindScalar is a plain scalar leaf (String/int/double/bool).
	SomMetaKindScalar = "scalar"
)

// SomContentTypeMeta is the @ContentType(type, description) annotation captured
// on a node.
type SomContentTypeMeta struct {
	// Type is the declared content type (e.g. "code", "diagram").
	Type string
	// Description is the human/AI-facing description of the expected content.
	Description string
}

// SomFormFieldMeta is one field of a @Form section (SOM §7.1 FormMeta.fields).
type SomFormFieldMeta struct {
	// Name is the exact model field name ("approvedBy").
	Name string
	// TypeName is the Dart type name of the field ("String", "int", …).
	TypeName string
	// Description is the display label / description, "" when the form
	// declares none.
	Description string
	// Required is whether the form marks the field as required.
	Required bool
	// Hint is the authoring hint (e.g. "e.g. 1.0"), "" when absent.
	Hint string
	// Order is the declaration order within the form.
	Order int
	// EnumValues holds the enum constant names when TypeName is a model enum
	// (YRD7); empty for non-enum field types. The complete value domain of an
	// enum-typed form field, so editors and the generic modification API can
	// validate and convert without generated code.
	EnumValues []string
	// RefersTo holds the registry key(s) this field's value is an *id drawn
	// from*, each written "<SECTIONID>.<formFieldName>" (csrb3); empty for a
	// field that is not a reference. A value is valid when it resolves in ANY
	// listed registry; a reference naming several ids writes them
	// comma-separated.
	RefersTo []string
}

// SomFormMeta is the form metadata of a @Form node (SOM §7.1 FormMeta).
type SomFormMeta struct {
	// Fields holds the form's fields in declaration order.
	Fields []*SomFormFieldMeta
}

// FieldNamed returns the field named name, or nil when absent.
func (f *SomFormMeta) FieldNamed(name string) *SomFormFieldMeta {
	for _, field := range f.Fields {
		if field.Name == name {
			return field
		}
	}
	return nil
}

// SomDocMeta is the @Document metadata carried by a document root (SOM §7.1
// DocMeta).
type SomDocMeta struct {
	// Name is the document's display name ("Solution Blueprint").
	Name string
	// Description is the document's description.
	Description string
	// BasedOn holds class names of the documents this one is based on
	// (@Document.basedOn).
	BasedOn []string
}

// SomMetaExtra is one annotation captured losslessly into the generic Extra
// list — annotations the tree defines no dedicated slot for (SOM §7.1 note),
// e.g. @Max, @MinLength, @PatternCheck, @TextRequired.
type SomMetaExtra struct {
	// Annotation is the annotation's class name ("Max", "PatternCheck", …).
	Annotation string
	// Args holds the resolved constructor arguments ({count: 4}).
	Args map[string]interface{}
}

// SomMetaNode is one node of the SOM metadata tree (SOM §7.1 MetaNode).
//
// A node describes one navigable position of a document root's structure: the
// document root itself, a field, or a list's element subtree. Class-level
// annotations attach to the node where the class is *instantiated*;
// field-level annotations attach to the node directly (field-level @SectionId
// wins over the target class's).
//
// Nodes are immutable value carriers; SomMetaTree wires the parent links and
// absolute paths when the tree is constructed. A node instance belongs to at
// most one tree.
type SomMetaNode struct {
	// ClassName is the exact model class name this node is (for
	// root/complex/section nodes: the instantiated class; for leaves: the
	// declaring class of the field).
	ClassName string
	// MemberName is the exact field name in the parent class, "" on the
	// document root and on list element subtrees.
	MemberName string
	// SectionID is the effective @SectionId (field-level wins over
	// class-level), "" when none.
	SectionID string
	// ClassSectionID is the target class's own @SectionId (SOM §12.2
	// fallback): the id its generated schema type is keyed by, used only to build
	// the mapping key of a section/complex node whose field carries no id.
	// Never enters Segment — the path stays field-level. "" when none.
	ClassSectionID string
	// SectionIDPattern is the @SectionIdPattern on a list field (item ids),
	// "" when none.
	SectionIDPattern string
	// Kind is the structural kind of the node (a SomMetaKind* constant).
	Kind string
	// TypeName is the Dart type name of the field/class ("String",
	// "GoalEntry", …).
	TypeName string
	// SerializationOrder is @SerializationOrder(order), nil when unannotated.
	SerializationOrder *int
	// Min is @Min(count), nil when unannotated.
	Min *int
	// Unused is whether @Unused is present on the node.
	Unused bool
	// ContentType is @ContentType, nil when unannotated.
	ContentType *SomContentTypeMeta
	// ContentHelp is @ContentHelp(guidance), "" when unannotated.
	ContentHelp string
	// Headline is the @Headline(text) predefined DEFAULT headline (YRD4;
	// field-level wins over the target class's), "" when unannotated.
	//
	// Render precedence: stored headline > this default > name derivation.
	// Editors prefill a new section's headline from this; a stored headline
	// always wins and stays editable.
	Headline string
	// Comment is @Comment(text), "" when unannotated.
	Comment string
	// DocComment is the cleaned /// doc comment (member wins over class), ""
	// when none.
	DocComment string
	// ClassDocComment is the instantiated class's own doc comment, when it
	// differs from DocComment.
	ClassDocComment string
	// Form is the form metadata, for SomMetaKindForm nodes.
	Form *SomFormMeta
	// Document is @Document metadata; non-nil only on the document root.
	Document *SomDocMeta
	// MapsTo is the @MapsTo target class name, "" when unannotated.
	MapsTo string
	// DetailedIn is the @DetailedIn target class name, "" when unannotated.
	DetailedIn string
	// Extra holds annotations without a dedicated slot, captured losslessly.
	Extra []*SomMetaExtra
	// Recursive is whether this node is a recursive re-entry reference (a
	// class already on the descent stack): Kind == SomMetaKindComplex, no
	// children.
	Recursive bool
	// Children holds the child nodes, in @SerializationOrder order. For
	// complex/section nodes these are the target class's fields (the class
	// collapses onto the node); empty for leaves and recursive references.
	Children []*SomMetaNode
	// ElementNode is, for SomMetaKindList nodes, the element class subtree.
	// Its children describe each item's structure; item positions have no
	// static path (see Path).
	ElementNode *SomMetaNode

	// --- tree wiring (set once by SomMetaTree) -----------------------------
	tree    *SomMetaTree
	parent  *SomMetaNode
	path    string
	hasPath bool
}

// Tree returns the tree this node belongs to, or an error when the node has
// not been attached to a SomMetaTree yet.
func (n *SomMetaNode) Tree() (*SomMetaTree, error) {
	if n.tree == nil {
		return nil, errors.New(
			"SomMetaNode(" + n.DebugName() + ") is not attached to a SomMetaTree")
	}
	return n.tree, nil
}

// Parent returns the parent node, nil on the document root. The parent of a
// list's ElementNode is the list node itself. Returns an error when the node
// is unattached.
func (n *SomMetaNode) Parent() (*SomMetaNode, error) {
	if _, err := n.Tree(); err != nil {
		return nil, err
	}
	return n.parent, nil
}

// Path returns the node's absolute document path per the SOM §8 path grammar
// (`<rootSegment>/<segment>/…`), or "" for nodes inside a list element subtree
// — their concrete paths depend on the item sequence (see ItemPath on the list
// node and SomMetaTree.ByPath). Returns an error when the node is unattached.
func (n *SomMetaNode) Path() (string, error) {
	if _, err := n.Tree(); err != nil {
		return "", err
	}
	return n.path, nil
}

// Segment returns the path segment this node contributes: the effective
// SectionID when present, else the MemberName, else the ClassName (document
// root).
func (n *SomMetaNode) Segment() string {
	if n.SectionID != "" {
		return n.SectionID
	}
	if n.MemberName != "" {
		return n.MemberName
	}
	return n.ClassName
}

// ItemPath returns the path of the seq-th item of this list node
// (`<path>-<seq>`). Returns an error when the node is not a list or has no
// static path.
func (n *SomMetaNode) ItemPath(seq int) (string, error) {
	if n.Kind != SomMetaKindList {
		return "", errors.New(
			"itemPath() requires a list node, " + n.DebugName() + " is " + n.Kind)
	}
	p, err := n.Path()
	if err != nil {
		return "", err
	}
	if !n.hasPath {
		return "", errors.New(
			"list " + n.DebugName() + " sits inside a list element subtree and " +
				"has no static path")
	}
	return ListItemPath(p, seq), nil
}

// ChildByMember returns the direct child whose MemberName equals name, or nil.
func (n *SomMetaNode) ChildByMember(name string) *SomMetaNode {
	for _, c := range n.Children {
		if c.MemberName == name {
			return c
		}
	}
	return nil
}

// ChildBySegment returns the direct child whose Segment equals seg, or nil.
func (n *SomMetaNode) ChildBySegment(seg string) *SomMetaNode {
	for _, c := range n.Children {
		if c.Segment() == seg {
			return c
		}
	}
	return nil
}

// DebugName returns a short identification for error messages.
func (n *SomMetaNode) DebugName() string {
	if n.MemberName == "" {
		return n.ClassName
	}
	return n.ClassName + "." + n.MemberName
}

// matchesSectionIDPattern reports whether id matches pattern with every "xxx"
// placeholder standing for one-or-more digits.
func matchesSectionIDPattern(pattern, id string) bool {
	parts := strings.Split(pattern, "xxx")
	quoted := make([]string, len(parts))
	for i, p := range parts {
		quoted[i] = regexp.QuoteMeta(p)
	}
	re, err := regexp.Compile("^" + strings.Join(quoted, "[0-9]+") + "$")
	if err != nil {
		return false
	}
	return re.MatchString(id)
}

// SomMetaTree is the metadata tree of one document root: parent/path wiring
// plus the two dynamic lookups (ByID, ByPath) SOM §10 requires every runtime
// to keep.
type SomMetaTree struct {
	// Root is the document root node (carries SomMetaNode.Document).
	Root *SomMetaNode

	byID     map[string][]*SomMetaNode
	allNodes []*SomMetaNode
}

// NewSomMetaTree wires root's subtree: sets parent links, computes static
// paths, and indexes section ids.
//
// Returns an error when root carries no @Document metadata, and when any node
// is already attached to another tree (nodes belong to exactly one tree).
func NewSomMetaTree(root *SomMetaNode) (*SomMetaTree, error) {
	if root.Document == nil {
		return nil, errors.New(
			"the tree root must carry @Document metadata " +
				"(SomMetaNode.document): " + root.DebugName())
	}
	t := &SomMetaTree{Root: root, byID: map[string][]*SomMetaNode{}}
	if err := t.wire(root, nil, root.Segment(), true); err != nil {
		return nil, err
	}
	return t, nil
}

func (t *SomMetaTree) wire(node, parent *SomMetaNode, path string, hasPath bool) error {
	if node.tree != nil {
		return errors.New(
			"SomMetaNode(" + node.DebugName() + ") is already attached to a " +
				"SomMetaTree; nodes belong to exactly one tree")
	}
	node.tree = t
	node.parent = parent
	node.path = path
	node.hasPath = hasPath
	t.allNodes = append(t.allNodes, node)
	if node.SectionID != "" {
		t.byID[node.SectionID] = append(t.byID[node.SectionID], node)
	}
	for _, child := range node.Children {
		childPath := ""
		if hasPath {
			childPath = SpecPathJoin(path, child.Segment())
		}
		if err := t.wire(child, node, childPath, hasPath); err != nil {
			return err
		}
	}
	if node.ElementNode != nil {
		// Item positions are dynamic (`<listPath>-<seq>`), so the element
		// subtree carries no static paths.
		if err := t.wire(node.ElementNode, node, "", false); err != nil {
			return err
		}
	}
	return nil
}

// AllNodes returns every node of the tree (document order; element subtrees
// follow their list node).
func (t *SomMetaTree) AllNodes() []*SomMetaNode {
	return t.allNodes
}

// --- lookup by section id ---------------------------------------------------

// AllByID returns all nodes whose effective section id equals sectionID, in
// document order. A shared class instantiated at several positions yields
// several nodes (ids resolve within their parent chain, SOM §11.2).
func (t *SomMetaTree) AllByID(sectionID string) []*SomMetaNode {
	return t.byID[sectionID]
}

// ByID returns the first node whose effective section id equals sectionID.
//
// A *resolved list-item id* (a list's @SectionIdPattern with the "xxx"
// placeholder replaced by digits, e.g. "GOAL-ITEM-3") resolves to that list's
// element subtree. Returns nil when nothing matches.
func (t *SomMetaTree) ByID(sectionID string) *SomMetaNode {
	if exact := t.byID[sectionID]; len(exact) > 0 {
		return exact[0]
	}
	for _, node := range t.allNodes {
		if node.SectionIDPattern != "" &&
			matchesSectionIDPattern(node.SectionIDPattern, sectionID) {
			if node.ElementNode != nil {
				return node.ElementNode
			}
			return node
		}
	}
	return nil
}

// --- lookup by path -----------------------------------------------------------

// ByPath resolves a document path (the SOM §8 grammar: segments joined by "/",
// list items as "-<seq>" suffixes) to the metadata node it addresses, or nil
// when the path does not describe a reachable position.
//
// A list-item segment ("<listSegment>-<seq>") resolves to the list's element
// subtree; segments below it match the element class's fields. A list
// *container* path is only valid as the final segment (descending past a list
// requires an item suffix).
func (t *SomMetaTree) ByPath(path string) *SomMetaNode {
	segs := SpecPathSegments(path)
	if len(segs) == 0 || segs[0] != t.Root.Segment() {
		return nil
	}

	node := t.Root
	for i := 1; i < len(segs); i++ {
		seg := segs[i]
		last := i == len(segs)-1

		// Prefer an exact segment match; only then try a list-item suffix, so
		// a hyphenated @SectionId is never mis-read as an item.
		if child := node.ChildBySegment(seg); child != nil {
			if child.Kind == SomMetaKindList && !last {
				return nil // a list path needs a `-<seq>` item suffix
			}
			if child.Recursive && !last {
				return nil // chains terminate at recursive re-entries
			}
			node = child
			continue
		}

		split, ok := SplitListItemSegment(seg)
		if !ok {
			return nil
		}
		listNode := node.ChildBySegment(split.Base)
		if listNode == nil || listNode.Kind != SomMetaKindList {
			return nil
		}
		element := listNode.ElementNode
		if element == nil {
			// Scalar list without an element subtree: the item is a value leaf.
			if last {
				return listNode
			}
			return nil
		}
		node = element
	}
	return node
}

// SomMetaRef is one position of the generated **dot-notation / ID-tree access
// surfaces** (SOM §8): an absolute document Path bound to the Tree it belongs
// to.
//
// The generated facades (SOM §8) emit one accessor type per model class whose
// getters return further SomMetaRefs. Every accessor exposes at least Path and
// Meta (the SomMetaNode at that position). This base type is the leaf accessor
// itself (content/scalar/enum/form positions).
type SomMetaRef struct {
	// Tree is the metadata tree of the document root this position belongs to.
	Tree *SomMetaTree
	// Path is the absolute document path of this position (SOM §8 path grammar).
	Path string
}

// Meta returns the metadata node at Path.
//
// Returns an error when the path resolves to no node — only possible past a
// recursive re-entry, where the generated chain has ended and the metadata
// tree carries no further nodes (SOM §8 cycle rule).
func (r *SomMetaRef) Meta() (*SomMetaNode, error) {
	node := r.Tree.ByPath(r.Path)
	if node == nil {
		return nil, errors.New(
			"no metadata node at \"" + r.Path + "\" — the position lies beyond " +
				"a recursive re-entry; use the dynamic tree lookups instead")
	}
	return node, nil
}

// SomMetaRefFactory is the factory a SomListMetaRef uses to build the accessor
// for an item position: func(tree, path) ref, where ref is the element class's
// generated accessor.
type SomMetaRefFactory[T any] func(tree *SomMetaTree, path string) T

// SomListMetaRef is the generated accessor for a **list** position (SOM §8):
// Path is the list container path; Item returns the accessor for the seq-th
// item position (`<path>-<seq>`), whose children are the element class's
// accessors.
type SomListMetaRef[T any] struct {
	SomMetaRef
	element SomMetaRefFactory[T]
}

// NewSomListMetaRef binds a list container position to its element accessor
// factory.
func NewSomListMetaRef[T any](
	tree *SomMetaTree, path string, element SomMetaRefFactory[T],
) *SomListMetaRef[T] {
	return &SomListMetaRef[T]{
		SomMetaRef: SomMetaRef{Tree: tree, Path: path},
		element:    element,
	}
}

// Item returns the accessor at the item position `<path>-<seq>`.
func (r *SomListMetaRef[T]) Item(seq int) T {
	return r.element(r.Tree, ListItemPath(r.Path, seq))
}
