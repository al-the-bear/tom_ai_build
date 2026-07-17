package somruntime

// spec_meta_diff.go — structural comparison of two SomMetaNode subtrees; a
// faithful port of `tom_som_dart_runtime/lib/src/spec_meta_diff.dart` (and the
// TypeScript `spec_meta_diff.ts` / Python / JavaScript ports).
//
// SomMetaNodeDiff is the agreement oracle for DR8: the generated facades embed
// populated metadata trees as static code (DR1 §3.2), while BuildSomMetaTree
// derives the same tree from the exported meta-JSON at runtime — the two must
// be field-for-field identical for every node. Tests compare them with this
// function, which returns a human-readable description of the **first**
// difference found (with the node's position), or the empty string when the
// subtrees agree completely.
//
// Go conventions (documented divergences from the TS port): the "no
// difference" result is the idiomatic empty string instead of null; optional
// ints (*int) print as `null` when nil so the message strings stay aligned
// with the sibling ports; and numeric annotation-argument values compare by
// numeric value across int/float64 (the JSON decoder yields float64 where the
// generated literals are untyped Go constants).

import (
	"encoding/json"
	"fmt"
	"strconv"
)

// SomMetaNodeDiff compares the a and b subtrees field by field (annotations,
// names, kinds, form/document metadata, children and list element subtrees).
//
// Returns "" when the subtrees are structurally identical, else a description
// of the first difference, prefixed with the node's position (a `/`-joined
// member-name chain rooted at the `<root>` marker).
func SomMetaNodeDiff(a, b *SomMetaNode) string {
	return somMetaNodeDiffAt(a, b, "<root>")
}

func somMetaNodeDiffAt(a, b *SomMetaNode, at string) string {
	diff := func(field string, va, vb interface{}) string {
		if metaValueEq(va, vb) {
			return ""
		}
		return at + ": " + field + " differs — " +
			metaValueRepr(va) + " != " + metaValueRepr(vb)
	}

	checks := []func() string{
		func() string { return diff("className", a.ClassName, b.ClassName) },
		func() string { return diff("memberName", a.MemberName, b.MemberName) },
		func() string { return diff("sectionId", a.SectionID, b.SectionID) },
		func() string {
			return diff("sectionIdPattern", a.SectionIDPattern, b.SectionIDPattern)
		},
		func() string { return diff("kind", a.Kind, b.Kind) },
		func() string { return diff("typeName", a.TypeName, b.TypeName) },
		func() string {
			return diff("serializationOrder",
				optIntRepr(a.SerializationOrder), optIntRepr(b.SerializationOrder))
		},
		func() string { return diff("min", optIntRepr(a.Min), optIntRepr(b.Min)) },
		func() string { return diff("unused", a.Unused, b.Unused) },
		func() string {
			return diff("contentType.type",
				contentTypeField(a.ContentType, true),
				contentTypeField(b.ContentType, true))
		},
		func() string {
			return diff("contentType.description",
				contentTypeField(a.ContentType, false),
				contentTypeField(b.ContentType, false))
		},
		func() string { return diff("contentHelp", a.ContentHelp, b.ContentHelp) },
		func() string { return diff("headline", a.Headline, b.Headline) },
		func() string { return diff("comment", a.Comment, b.Comment) },
		func() string { return diff("docComment", a.DocComment, b.DocComment) },
		func() string {
			return diff("classDocComment", a.ClassDocComment, b.ClassDocComment)
		},
		func() string { return diff("mapsTo", a.MapsTo, b.MapsTo) },
		func() string { return diff("detailedIn", a.DetailedIn, b.DetailedIn) },
		func() string { return diff("recursive", a.Recursive, b.Recursive) },
		func() string { return metaFormDiff(at, a.Form, b.Form) },
		func() string { return metaDocumentDiff(at, a.Document, b.Document) },
		func() string {
			return metaSecondLevelDiff(at, a.SecondLevelIds, b.SecondLevelIds)
		},
		func() string { return metaExtraDiff(at, a.Extra, b.Extra) },
	}
	for _, check := range checks {
		if d := check(); d != "" {
			return d
		}
	}

	if len(a.Children) != len(b.Children) {
		return fmt.Sprintf("%s: children count differs — %d != %d (%s vs %s)",
			at, len(a.Children), len(b.Children),
			jsonRepr(memberNames(a.Children)), jsonRepr(memberNames(b.Children)))
	}
	for i, ca := range a.Children {
		name := ca.MemberName
		if name == "" {
			name = ca.ClassName
		}
		if d := somMetaNodeDiffAt(ca, b.Children[i], at+"/"+name); d != "" {
			return d
		}
	}

	aElem := a.ElementNode != nil
	bElem := b.ElementNode != nil
	if aElem != bElem {
		return fmt.Sprintf("%s: elementNode presence differs — %t != %t",
			at, aElem, bElem)
	}
	if aElem {
		return somMetaNodeDiffAt(a.ElementNode, b.ElementNode, at+"/§element")
	}
	return ""
}

func memberNames(nodes []*SomMetaNode) []string {
	names := make([]string, len(nodes))
	for i, n := range nodes {
		names[i] = n.MemberName
	}
	return names
}

func contentTypeField(ct *SomContentTypeMeta, wantType bool) interface{} {
	if ct == nil {
		return nil
	}
	if wantType {
		return ct.Type
	}
	return ct.Description
}

func optIntRepr(v *int) interface{} {
	if v == nil {
		return nil
	}
	return *v
}

func metaFormDiff(at string, a, b *SomFormMeta) string {
	aSet := a != nil
	bSet := b != nil
	if aSet != bSet {
		return fmt.Sprintf("%s: form presence differs — %t != %t", at, aSet, bSet)
	}
	if !aSet {
		return ""
	}
	if len(a.Fields) != len(b.Fields) {
		return fmt.Sprintf("%s: form field count differs — %d != %d",
			at, len(a.Fields), len(b.Fields))
	}
	for i, fa := range a.Fields {
		fb := b.Fields[i]
		if fa.Name != fb.Name ||
			fa.TypeName != fb.TypeName ||
			fa.Description != fb.Description ||
			fa.Required != fb.Required ||
			fa.Hint != fb.Hint ||
			fa.Role != fb.Role ||
			fa.Initial != fb.Initial ||
			fa.Order != fb.Order {
			return at + ": form field " + fa.Name + " differs"
		}
	}
	return ""
}

func metaDocumentDiff(at string, a, b *SomDocMeta) string {
	aSet := a != nil
	bSet := b != nil
	if aSet != bSet {
		return fmt.Sprintf("%s: document presence differs — %t != %t",
			at, aSet, bSet)
	}
	if !aSet {
		return ""
	}
	if a.Name != b.Name {
		return at + ": document.name differs — " + a.Name + " != " + b.Name
	}
	if a.Description != b.Description {
		return at + ": document.description differs"
	}
	if !stringListEq(a.BasedOn, b.BasedOn) {
		return at + ": document.basedOn differs — " +
			jsonRepr(a.BasedOn) + " != " + jsonRepr(b.BasedOn)
	}
	return ""
}

func metaSecondLevelDiff(at string, a, b []*SomSecondLevelId) string {
	if len(a) != len(b) {
		return fmt.Sprintf("%s: secondLevelIds count differs — %d != %d",
			at, len(a), len(b))
	}
	for i := range a {
		if a[i].DocumentClass != b[i].DocumentClass || a[i].ID != b[i].ID {
			return fmt.Sprintf("%s: secondLevelIds[%d] differs", at, i)
		}
	}
	return ""
}

func metaExtraDiff(at string, a, b []*SomMetaExtra) string {
	if len(a) != len(b) {
		return fmt.Sprintf("%s: extra annotation count differs — %d != %d "+
			"(%s vs %s)", at, len(a), len(b),
			jsonRepr(annotationNames(a)), jsonRepr(annotationNames(b)))
	}
	for i := range a {
		if a[i].Annotation != b[i].Annotation ||
			!metaValueEq(argsAsValue(a[i].Args), argsAsValue(b[i].Args)) {
			return at + ": extra annotation " + a[i].Annotation + " differs — " +
				jsonRepr(a[i].Args) + " != " + jsonRepr(b[i].Args)
		}
	}
	return ""
}

func annotationNames(extras []*SomMetaExtra) []string {
	names := make([]string, len(extras))
	for i, e := range extras {
		names[i] = e.Annotation
	}
	return names
}

// argsAsValue widens a (possibly nil) args map into an interface{} so the
// generic metaValueEq map branch applies (a nil map equals an empty map).
func argsAsValue(args map[string]interface{}) interface{} {
	if args == nil {
		return map[string]interface{}{}
	}
	return args
}

// metaValueEq is deep structural equality over JSON-shaped values (the
// annotation-argument shapes: scalars, arrays, string-keyed maps). Numbers
// compare by numeric value across int/float64 (see the file header).
func metaValueEq(a, b interface{}) bool {
	if an, aok := asFloat(a); aok {
		bn, bok := asFloat(b)
		return bok && an == bn
	}
	if al, aok := a.([]interface{}); aok {
		bl, bok := b.([]interface{})
		if !bok || len(al) != len(bl) {
			return false
		}
		for i := range al {
			if !metaValueEq(al[i], bl[i]) {
				return false
			}
		}
		return true
	}
	if am, aok := a.(map[string]interface{}); aok {
		bm, bok := b.(map[string]interface{})
		if !bok || len(am) != len(bm) {
			return false
		}
		for k, av := range am {
			bv, has := bm[k]
			if !has || !metaValueEq(av, bv) {
				return false
			}
		}
		return true
	}
	return a == b
}

func asFloat(v interface{}) (float64, bool) {
	switch n := v.(type) {
	case int:
		return float64(n), true
	case int64:
		return float64(n), true
	case float64:
		return n, true
	}
	return 0, false
}

func stringListEq(a, b []string) bool {
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

// metaValueRepr renders a scalar the way the sibling ports interpolate it
// into a diff message (`null` for absent values).
func metaValueRepr(v interface{}) string {
	switch t := v.(type) {
	case nil:
		return "null"
	case string:
		return t
	case bool:
		return strconv.FormatBool(t)
	case int:
		return strconv.Itoa(t)
	}
	return fmt.Sprintf("%v", v)
}

// jsonRepr renders a value as compact JSON for diff messages (mirroring the
// TS port's JSON.stringify interpolations).
func jsonRepr(v interface{}) string {
	data, err := json.Marshal(v)
	if err != nil {
		return fmt.Sprintf("%v", v)
	}
	return string(data)
}
