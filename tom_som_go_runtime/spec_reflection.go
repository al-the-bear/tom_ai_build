package somruntime

// spec_reflection.go — generic, value-free traversal of a SpecModel class graph
// (the "reflection" surface), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_reflection.dart` (and the TypeScript
// `spec_reflection.ts`).
//
// It answers two kinds of question about a model: enumeration (what roots,
// classes, fields and annotations exist) and resolution (which model node a
// concrete document path addresses). It holds no document values.

// What a resolved path lands on in the model.
const (
	SpecNodeKindRoot            = "root"
	SpecNodeKindComplex         = "complex"
	SpecNodeKindSection         = "section"
	SpecNodeKindList            = "list"
	SpecNodeKindListItemComplex = "listItemComplex"
	SpecNodeKindListItemScalar  = "listItemScalar"
	SpecNodeKindForm            = "form"
	SpecNodeKindContent         = "content"
	SpecNodeKindEnumValue       = "enumValue"
	SpecNodeKindScalar          = "scalar"
)

var valueLeafKinds = map[string]bool{
	SpecNodeKindContent:        true,
	SpecNodeKindEnumValue:      true,
	SpecNodeKindScalar:         true,
	SpecNodeKindListItemScalar: true,
}

// SpecResolution is the outcome of resolving a document path against a SpecModel.
type SpecResolution struct {
	Path        string
	Kind        string
	Root        *SpecRoot
	Field       *SpecField
	TargetClass *SpecClass
}

// IsValueLeaf reports whether a single string value is stored directly at this
// path (a content, enum, scalar leaf, or a scalar list item).
func (r *SpecResolution) IsValueLeaf() bool {
	return valueLeafKinds[r.Kind]
}

var leafKinds = map[string]string{
	SpecFieldKindForm:    SpecNodeKindForm,
	SpecFieldKindContent: SpecNodeKindContent,
	SpecFieldKindEnum:    SpecNodeKindEnumValue,
	SpecFieldKindScalar:  SpecNodeKindScalar,
}

// SpecReflection provides read-only queries over a SpecModel.
type SpecReflection struct {
	Model *SpecModel
}

// NewSpecReflection binds a reflection surface to a model.
func NewSpecReflection(model *SpecModel) *SpecReflection {
	return &SpecReflection{Model: model}
}

// --- enumeration -----------------------------------------------------------

// Roots returns the document roots.
func (r *SpecReflection) Roots() []*SpecRoot { return r.Model.Roots }

// Classes returns every class (unordered).
func (r *SpecReflection) Classes() []*SpecClass {
	out := make([]*SpecClass, 0, len(r.Model.Classes))
	for _, c := range r.Model.Classes {
		out = append(out, c)
	}
	return out
}

// ClassNamed returns the named class, or nil.
func (r *SpecReflection) ClassNamed(name string) *SpecClass {
	return r.Model.ClassNamed(name)
}

// FieldsOf returns the fields of the named class.
func (r *SpecReflection) FieldsOf(className string) []*SpecField {
	if cls := r.ClassNamed(className); cls != nil {
		return cls.Fields
	}
	return nil
}

// AnnotationsOf returns the annotations of the named class.
func (r *SpecReflection) AnnotationsOf(className string) []*SpecAnnotation {
	if cls := r.ClassNamed(className); cls != nil {
		return cls.Annotations
	}
	return nil
}

// FieldAnnotations returns the annotations of a named field of a named class.
func (r *SpecReflection) FieldAnnotations(className, fieldName string) []*SpecAnnotation {
	cls := r.ClassNamed(className)
	if cls == nil {
		return nil
	}
	if f := cls.FieldNamed(fieldName); f != nil {
		return f.Annotations
	}
	return nil
}

// ReachableClassNames returns every class name reachable from typeName by
// following class-bearing fields — complex/section fields through their Type,
// complex list fields through their ElementType — including typeName itself.
//
// This is the model's notion of **document scope**. A document rooted at a given
// @Document class can only ever hold sections of the classes that root reaches,
// so a class outside the set is not merely *unpopulated* in such a document — it
// is absent from it by construction. Any consumer that has to tell "the author
// did not write this" from "this document could not hold it in the first place"
// needs exactly this set.
//
// A name that resolves to no class contributes nothing and is not itself
// included: an unresolved reference is not evidence of a reachable class.
func (r *SpecReflection) ReachableClassNames(typeName string) map[string]bool {
	seen := map[string]bool{}
	stack := []string{typeName}
	for len(stack) > 0 {
		current := stack[len(stack)-1]
		stack = stack[:len(stack)-1]
		if seen[current] {
			continue
		}
		cls := r.ClassNamed(current)
		if cls == nil {
			continue
		}
		seen[current] = true
		for _, f := range cls.Fields {
			child := ""
			switch f.Kind {
			case SpecFieldKindComplex, SpecFieldKindSection:
				child = f.Type
			case SpecFieldKindList:
				if f.ElementIsComplex {
					child = f.ElementType
				}
			}
			if child != "" {
				stack = append(stack, child)
			}
		}
	}
	return seen
}

// --- resolution ------------------------------------------------------------

// RootSegment returns the section segment of a root.
func (r *SpecReflection) RootSegment(root *SpecRoot) string {
	if root.SectionID != "" {
		return root.SectionID
	}
	return root.Type
}

// FieldSegment returns the section segment of a field.
func (r *SpecReflection) FieldSegment(field *SpecField) string {
	if field.SectionID != "" {
		return field.SectionID
	}
	return field.Name
}

// RootForSegment returns the root whose segment matches, or nil.
func (r *SpecReflection) RootForSegment(segment string) *SpecRoot {
	for _, root := range r.Model.Roots {
		if r.RootSegment(root) == segment {
			return root
		}
	}
	return nil
}

func (r *SpecReflection) matchField(cls *SpecClass, segment string) *SpecField {
	for _, f := range cls.Fields {
		if r.FieldSegment(f) == segment {
			return f
		}
	}
	return nil
}

// Resolve resolves a document path to the model node it addresses, or nil when
// the path does not describe a reachable node.
func (r *SpecReflection) Resolve(path string) *SpecResolution {
	segs := SpecPathSegments(path)
	if len(segs) == 0 || segs[0] == "" {
		return nil
	}

	root := r.RootForSegment(segs[0])
	if root == nil {
		return nil
	}

	curClass := r.ClassNamed(root.Type)
	if len(segs) == 1 {
		return &SpecResolution{
			Path:        path,
			Kind:        SpecNodeKindRoot,
			Root:        root,
			TargetClass: curClass,
		}
	}

	for i := 1; i < len(segs); i++ {
		cls := curClass
		if cls == nil {
			return nil // cannot descend into a non-class
		}
		seg := segs[i]
		last := i == len(segs)-1

		// Prefer an exact field-segment match; only then try a list-item suffix,
		// so a hyphenated @SectionId is never mis-read as an item.
		field := r.matchField(cls, seg)
		if field != nil {
			if field.Kind == SpecFieldKindComplex || field.Kind == SpecFieldKindSection {
				curClass = r.ClassNamed(field.Type)
				if last {
					kind := SpecNodeKindComplex
					if field.Kind == SpecFieldKindSection {
						kind = SpecNodeKindSection
					}
					return &SpecResolution{
						Path:        path,
						Kind:        kind,
						Root:        root,
						Field:       field,
						TargetClass: curClass,
					}
				}
				continue // descend into the collapsed class
			}
			if field.Kind == SpecFieldKindList {
				if last {
					return &SpecResolution{Path: path, Kind: SpecNodeKindList, Root: root, Field: field}
				}
				return nil // a list path needs a -<seq> item suffix
			}
			// form / content / enum / scalar leaves
			if last {
				return &SpecResolution{Path: path, Kind: leafKinds[field.Kind], Root: root, Field: field}
			}
			return nil // a leaf cannot have further segments
		}

		split, ok := SplitListItemSegment(seg)
		if !ok {
			return nil
		}
		listField := r.matchField(cls, split.Base)
		if listField == nil || listField.Kind != SpecFieldKindList {
			return nil
		}
		if listField.ElementIsComplex {
			curClass = r.ClassNamed(listField.ElementType)
			if last {
				return &SpecResolution{
					Path:        path,
					Kind:        SpecNodeKindListItemComplex,
					Root:        root,
					Field:       listField,
					TargetClass: curClass,
				}
			}
			continue
		}
		// Scalar list item: a value leaf, so it must be the final segment.
		if last {
			return &SpecResolution{Path: path, Kind: SpecNodeKindListItemScalar, Root: root, Field: listField}
		}
		return nil
	}
	return nil
}
