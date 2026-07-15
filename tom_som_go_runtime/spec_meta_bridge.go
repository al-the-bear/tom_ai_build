package somruntime

// spec_meta_bridge.go — bridge from the meta-JSON class graph (SpecModel) to
// the canonical metadata tree (SomMetaTree, DR1 §3.1), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_meta_bridge.dart` (and the TypeScript
// `spec_meta_bridge.ts`).
//
// The generated facades (DR8) emit populated SomMetaTrees directly; every
// consumer that only has the exported spec-model meta-data (the conformance
// harness, tooling) builds its tree here. The expansion follows the same walk
// SpecReflection.Resolve performs — crucially, a node's SomMetaNode.SectionID
// is the **field-level** id exactly as exported (field.sectionId), so the
// tree's path grammar stays byte-compatible with the paths a SpecDocument is
// keyed by. (DR1 §2.2's "field id, else target-class id" resolution is applied
// at *export* time by the model exporter / DR8 generator, not re-derived
// here.)
//
// Recursive class references become terminal re-entry nodes
// (SomMetaNode.Recursive), mirroring how the generated chains terminate.

import "sort"

// slottedAnnotations holds annotation names that have a dedicated SomMetaNode
// slot; everything else is captured losslessly into SomMetaNode.Extra.
var slottedAnnotations = map[string]bool{
	"SectionId":            true,
	"SectionIdPattern":     true,
	"SerializationOrder":   true,
	"Min":                  true,
	"Unused":               true,
	"ContentType":          true,
	"ContentHelp":          true,
	"Comment":              true,
	"Form":                 true,
	"Document":             true,
	"MapsTo":               true,
	"DetailedIn":           true,
	"SecondLevelSectionId": true,
}

// BuildSomMetaTree builds the wired SomMetaTree for one document root of
// model.
//
// When rootType is "" the model's first root is used; otherwise the root is
// looked up via SpecModel.RootByType (returning its error for an unknown
// type). Children are ordered by @SerializationOrder (annotated members first,
// then declaration order), which is the sibling emission order of the
// hierarchical YAML format (DR1 §2.3).
func BuildSomMetaTree(model *SpecModel, rootType string) (*SomMetaTree, error) {
	var root *SpecRoot
	if rootType == "" {
		if len(model.Roots) > 0 {
			root = model.Roots[0]
		} else {
			r, err := model.RootByType("")
			if err != nil {
				return nil, err
			}
			root = r
		}
	} else {
		r, err := model.RootByType(rootType)
		if err != nil {
			return nil, err
		}
		root = r
	}
	cls := model.ClassNamed(root.Type)

	sectionID := root.SectionID
	docComment := root.Doc
	classDoc, mapsTo, detailedIn := "", "", ""
	classSectionID := ""
	var annotations []*SpecAnnotation
	var children []*SomMetaNode
	if cls != nil {
		if sectionID == "" {
			sectionID = cls.SectionID
		}
		if docComment == "" {
			docComment = cls.Doc
		}
		classDoc = cls.Doc
		classSectionID = cls.SectionID
		mapsTo = cls.MapsTo
		detailedIn = cls.DetailedIn
		annotations = cls.Annotations
		children = bridgeChildNodes(model, cls, map[string]bool{root.Type: true})
	}
	rootNode := &SomMetaNode{
		ClassName:       root.Type,
		SectionID:       sectionID,
		ClassSectionID:  classSectionID,
		Kind:            SomMetaKindSection,
		TypeName:        root.Type,
		DocComment:      docComment,
		ClassDocComment: classDoc,
		MapsTo:          mapsTo,
		DetailedIn:      detailedIn,
		Document: &SomDocMeta{
			Name:        root.Title,
			Description: root.Description,
			BasedOn:     bridgeBasedOn(cls),
		},
		SecondLevelIds: bridgeSecondLevelIds(annotations),
		Extra:          bridgeExtras(annotations),
		Children:       children,
	}
	return NewSomMetaTree(rootNode)
}

func bridgeBasedOn(cls *SpecClass) []string {
	if cls == nil {
		return []string{}
	}
	ann := cls.Annotation("Document")
	if ann == nil {
		return []string{}
	}
	raw, ok := ann.Argument("basedOn").([]interface{})
	if !ok {
		return []string{}
	}
	out := make([]string, 0, len(raw))
	for _, e := range raw {
		out = append(out, bridgeStr(e))
	}
	return out
}

// bridgeStr coerces an annotation argument value to its string form ("" for
// nil, matching the other ports' String(x || ”)).
func bridgeStr(v interface{}) string {
	switch t := v.(type) {
	case string:
		return t
	case int:
		return itoa(t)
	case float64:
		if t == float64(int(t)) {
			return itoa(int(t))
		}
		return ""
	case bool:
		if t {
			return "true"
		}
		return "false"
	default:
		return ""
	}
}

func bridgeChildNodes(model *SpecModel, cls *SpecClass, stack map[string]bool) []*SomMetaNode {
	const fallback = 1 << 30
	type indexed struct {
		index int
		field *SpecField
	}
	fields := make([]indexed, len(cls.Fields))
	for i, f := range cls.Fields {
		fields[i] = indexed{index: i, field: f}
	}
	sort.SliceStable(fields, func(a, b int) bool {
		oa, ob := fallback, fallback
		if fields[a].field.SerializationOrder != nil {
			oa = *fields[a].field.SerializationOrder
		}
		if fields[b].field.SerializationOrder != nil {
			ob = *fields[b].field.SerializationOrder
		}
		if oa != ob {
			return oa < ob
		}
		return fields[a].index < fields[b].index
	})
	out := make([]*SomMetaNode, 0, len(fields))
	for _, f := range fields {
		out = append(out, bridgeFieldNode(model, cls, f.field, stack))
	}
	return out
}

func bridgeFieldNode(
	model *SpecModel, owner *SpecClass, field *SpecField, stack map[string]bool,
) *SomMetaNode {
	kind := field.Kind // SpecFieldKind* values equal the SomMetaKind* values.
	var target *SpecClass
	recursive := false
	var children []*SomMetaNode
	var elementNode *SomMetaNode

	if field.Kind == SpecFieldKindComplex || field.Kind == SpecFieldKindSection {
		target = model.ClassNamed(field.Type)
		if target != nil {
			if stack[target.Name] {
				recursive = true
			} else {
				stack[target.Name] = true
				children = bridgeChildNodes(model, target, stack)
				delete(stack, target.Name)
			}
		}
	} else if field.Kind == SpecFieldKindList && field.ElementIsComplex {
		element := model.ClassNamed(field.ElementType)
		if element != nil {
			var elementChildren []*SomMetaNode
			elementRecursive := false
			if stack[element.Name] {
				elementRecursive = true
			} else {
				stack[element.Name] = true
				elementChildren = bridgeChildNodes(model, element, stack)
				delete(stack, element.Name)
			}
			elementNode = &SomMetaNode{
				ClassName:       element.Name,
				ClassSectionID:  element.SectionID,
				Kind:            SomMetaKindComplex,
				TypeName:        element.Name,
				DocComment:      element.Doc,
				ClassDocComment: element.Doc,
				MapsTo:          element.MapsTo,
				DetailedIn:      element.DetailedIn,
				Recursive:       elementRecursive,
				Children:        elementChildren,
			}
		}
	}

	var contentType *SomContentTypeMeta
	if field.ContentType != "" {
		description := ""
		if ctAnn := field.Annotation("ContentType"); ctAnn != nil {
			description = bridgeStr(ctAnn.Argument("description"))
		}
		contentType = &SomContentTypeMeta{Type: field.ContentType, Description: description}
	}

	commentText := ""
	if commentAnn := field.Annotation("Comment"); commentAnn != nil {
		commentText = bridgeStr(commentAnn.Argument("text"))
	}

	var form *SomFormMeta
	if field.Kind == SpecFieldKindForm {
		fields := make([]*SomFormFieldMeta, 0, len(field.FormFields))
		for i, ff := range field.FormFields {
			fields = append(fields, &SomFormFieldMeta{
				Name:        ff.Name,
				TypeName:    ff.Type,
				Description: ff.Label,
				Required:    ff.Required,
				Hint:        ff.Hint,
				Order:       i,
			})
		}
		form = &SomFormMeta{Fields: fields}
	}

	className := owner.Name
	docComment := field.Doc
	classDoc, mapsTo, detailedIn := "", "", ""
	classSectionID := ""
	if target != nil {
		className = target.Name
		if docComment == "" {
			docComment = target.Doc
		}
		classDoc = target.Doc
		classSectionID = target.SectionID
		mapsTo = target.MapsTo
		detailedIn = target.DetailedIn
	}
	typeName := field.Type
	if typeName == "" {
		typeName = field.ElementType
	}
	if typeName == "" {
		typeName = field.EnumType
	}
	if typeName == "" {
		typeName = "String"
	}

	return &SomMetaNode{
		ClassName:          className,
		MemberName:         field.Name,
		SectionID:          field.SectionID,
		ClassSectionID:     classSectionID,
		SectionIDPattern:   field.SectionIDPattern,
		Kind:               kind,
		TypeName:           typeName,
		SerializationOrder: field.SerializationOrder,
		Min:                field.Min,
		Unused:             field.Annotation("Unused") != nil,
		ContentType:        contentType,
		ContentHelp:        field.Help,
		Comment:            commentText,
		DocComment:         docComment,
		ClassDocComment:    classDoc,
		Form:               form,
		MapsTo:             mapsTo,
		DetailedIn:         detailedIn,
		SecondLevelIds:     bridgeSecondLevelIds(field.Annotations),
		Extra:              bridgeExtras(field.Annotations),
		Recursive:          recursive,
		Children:           children,
		ElementNode:        elementNode,
	}
}

func bridgeSecondLevelIds(annotations []*SpecAnnotation) []*SomSecondLevelId {
	var out []*SomSecondLevelId
	for _, a := range annotations {
		if a.Name != "SecondLevelSectionId" {
			continue
		}
		out = append(out, &SomSecondLevelId{
			DocumentClass: bridgeStr(a.Argument("documentClass")),
			ID:            bridgeStr(a.Argument("id")),
		})
	}
	return out
}

func bridgeExtras(annotations []*SpecAnnotation) []*SomMetaExtra {
	var out []*SomMetaExtra
	for _, a := range annotations {
		if slottedAnnotations[a.Name] {
			continue
		}
		args := a.Arguments
		if args == nil {
			args = map[string]interface{}{}
		}
		out = append(out, &SomMetaExtra{Annotation: a.Name, Args: args})
	}
	return out
}
