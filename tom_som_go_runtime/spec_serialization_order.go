package somruntime

// spec_serialization_order.go — model-aware member ordering for YAML
// serialization (AA1 criterion 7), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_serialization_order.dart` (and
// `spec_serialization_order.js` / `.ts` / `.py`).
//
// A SpecDocument is a flat, path-keyed store; the native YAML codec normally
// emits keys alphabetically for clean diffs. Criterion 7 instead requires each
// class's members to be emitted in the order declared by their
// @SerializationOrder annotation (the SOM source declaration order).
//
// This helper turns a path into an ordinal tuple — the @SerializationOrder of
// each field crossed on the way down (plus the numeric sequence for a list
// item), mirroring the walk SpecReflection.Resolve performs. Comparing those
// tuples lexicographically reproduces a depth-first, member-order traversal:
// siblings of one class sort by their declared order, and the recursion carries
// that ordering down the tree. Form fields (which are sub-keys, not path
// segments) are ordered by their position in the owning @Form's field list.
//
// Unannotated members sort after annotated ones (fallback ordinal), then by
// path/name, so ordering is always total and deterministic.

import "sort"

// serializationUnorderedFallback is the ordinal used for members without a
// @SerializationOrder, so they sort after every annotated member while staying
// stable relative to each other.
const serializationUnorderedFallback = 1 << 30

// SpecSerializationOrder computes member ordering keys from a SpecModel.
type SpecSerializationOrder struct {
	refl *SpecReflection
}

// NewSpecSerializationOrder builds an ordering helper for the given model.
func NewSpecSerializationOrder(model *SpecModel) *SpecSerializationOrder {
	return &SpecSerializationOrder{refl: NewSpecReflection(model)}
}

// OrderKey returns the ordinal tuple for path: one entry per field crossed (its
// @SerializationOrder, or serializationUnorderedFallback), with a trailing
// entry for a list item's numeric sequence. A path that does not resolve yields
// an empty tuple (it then sorts by its string form only).
func (s *SpecSerializationOrder) OrderKey(path string) []int {
	segs := SpecPathSegments(path)
	if len(segs) == 0 || segs[0] == "" {
		return nil
	}
	root := s.refl.RootForSegment(segs[0])
	if root == nil {
		return nil
	}

	key := []int{}
	curClass := s.refl.ClassNamed(root.Type)
	for i := 1; i < len(segs); i++ {
		cls := curClass
		if cls == nil {
			break
		}
		seg := segs[i]

		field := s.matchField(cls, seg)
		if field != nil {
			key = append(key, orderOf(field))
			if field.Kind == SpecFieldKindComplex || field.Kind == SpecFieldKindSection {
				curClass = s.refl.ClassNamed(field.Type)
				continue
			}
			break // list container / leaf / form terminates the descent
		}

		// A list item segment: `<base>-<seq>`.
		split, ok := SplitListItemSegment(seg)
		if !ok {
			break
		}
		listField := s.matchField(cls, split.Base)
		if listField == nil || listField.Kind != SpecFieldKindList {
			break
		}
		key = append(key, orderOf(listField))
		key = append(key, split.Seq)
		if listField.ElementIsComplex {
			curClass = s.refl.ClassNamed(listField.ElementType)
			continue
		}
		break // scalar list item is a leaf
	}
	return key
}

// OrderPaths orders paths by their OrderKey (lexicographically), breaking ties
// by the path string so the result is a total, stable order.
func (s *SpecSerializationOrder) OrderPaths(paths []string) []string {
	items := make([]string, len(paths))
	copy(items, paths)
	keys := make(map[string][]int, len(items))
	for _, p := range items {
		keys[p] = s.OrderKey(p)
	}
	sort.SliceStable(items, func(i, j int) bool {
		return compareOrderKeys(keys[items[i]], items[i], keys[items[j]], items[j]) < 0
	})
	return items
}

// OrderFormFields orders the form-field names of the @Form at formPath by their
// declared position in the form's field list; names not found in the model sort
// after, alphabetically.
func (s *SpecSerializationOrder) OrderFormFields(formPath string, fieldNames []string) []string {
	resolution := s.refl.Resolve(formPath)
	var field *SpecField
	if resolution != nil {
		field = resolution.Field
	}
	positions := map[string]int{}
	if field != nil {
		for i, ff := range field.FormFields {
			positions[ff.Name] = i
		}
	}
	names := make([]string, len(fieldNames))
	copy(names, fieldNames)
	sort.SliceStable(names, func(i, j int) bool {
		a, b := names[i], names[j]
		pa, okA := positions[a]
		if !okA {
			pa = serializationUnorderedFallback
		}
		pb, okB := positions[b]
		if !okB {
			pb = serializationUnorderedFallback
		}
		if pa != pb {
			return pa < pb
		}
		return a < b
	})
	return names
}

func (s *SpecSerializationOrder) matchField(cls *SpecClass, segment string) *SpecField {
	for _, f := range cls.Fields {
		if s.refl.FieldSegment(f) == segment {
			return f
		}
	}
	return nil
}

func orderOf(field *SpecField) int {
	if field.SerializationOrder != nil {
		return *field.SerializationOrder
	}
	return serializationUnorderedFallback
}

// compareOrderKeys reproduces the Dart _compareKeys / JS _compareKeys total
// order: shorter/equal-prefix tuples order by length, then ties break on the
// path string.
func compareOrderKeys(a []int, aPath string, b []int, bPath string) int {
	n := len(a)
	if len(b) < n {
		n = len(b)
	}
	for i := 0; i < n; i++ {
		if a[i] != b[i] {
			if a[i] < b[i] {
				return -1
			}
			return 1
		}
	}
	if len(a) != len(b) {
		if len(a) < len(b) {
			return -1
		}
		return 1
	}
	if aPath < bPath {
		return -1
	}
	if aPath > bPath {
		return 1
	}
	return 0
}
