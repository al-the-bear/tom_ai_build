// Metadata-core tests — a port of
// `tom_som_typescript_runtime/tests/spec_meta_test.ts` (itself a port of
// `tom_som_javascript_runtime/tests/spec_meta_test.js` /
// `tom_som_python_runtime/tests/spec_meta_test.py` /
// `tom_som_dart_runtime/test/spec_meta_test.dart`).
//
// Hand-built SOM §7.1 fixture tree mirroring the design doc's demo document
// (acceptance: "the runtime compiles with a hand-built fixture tree").
//
// Structure:
//
//	DEMO D99DemoDocument                      (@Document)
//	  INSC introductionAndScope               (section, class-level id)
//	    summary                               (content, no id)
//	    GOAL goals                            (section)
//	      GOAL-ITEM-LST entries               (list of GoalEntry, pattern)
//	        [element GoalEntry]
//	          text                            (content)
//	          subTasks                        (nested list of TaskEntry)
//	            [element TaskEntry]  note     (content)
//	  DOCO documentControl                    (form)
//	  RISK primaryRisk / RISK fallbackRisk    (shared class, two positions)
//	  PHASE-2 phaseTwo                        (hyphen+digit section id)
//	  related                                 (recursive re-entry)
//	  OLD legacy                              (@Unused content)
//	  tags                                    (scalar list, no element node)
package tests

import (
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// intp returns a pointer to n — the fixture's optional-int literal helper.
func intp(n int) *int {
	return &n
}

func metaFixtureTree(t *testing.T) *som.SomMetaTree {
	element := &som.SomMetaNode{
		ClassName:  "GoalEntry",
		Kind:       som.SomMetaKindSection,
		TypeName:   "GoalEntry",
		DocComment: "One programme goal.",
		Children: []*som.SomMetaNode{
			{
				ClassName:          "GoalEntry",
				MemberName:         "text",
				Kind:               som.SomMetaKindContent,
				TypeName:           "String",
				SerializationOrder: intp(1),
			},
			{
				ClassName:          "GoalEntry",
				MemberName:         "subTasks",
				SectionIDPattern:   "GOAL-TASK-xxx",
				Kind:               som.SomMetaKindList,
				TypeName:           "List<TaskEntry>",
				SerializationOrder: intp(2),
				ElementNode: &som.SomMetaNode{
					ClassName: "TaskEntry",
					Kind:      som.SomMetaKindSection,
					TypeName:  "TaskEntry",
					Children: []*som.SomMetaNode{
						{
							ClassName:  "TaskEntry",
							MemberName: "note",
							Kind:       som.SomMetaKindContent,
							TypeName:   "String",
						},
					},
				},
			},
		},
	}

	risk := func(member string) *som.SomMetaNode {
		return &som.SomMetaNode{
			ClassName:       "Risk",
			MemberName:      member,
			SectionID:       "RISK",
			Kind:            som.SomMetaKindComplex,
			TypeName:        "Risk",
			ClassDocComment: "A programme risk.",
			Children: []*som.SomMetaNode{
				{
					ClassName:  "Risk",
					MemberName: "probability",
					Kind:       som.SomMetaKindEnumValue,
					TypeName:   "Probability",
				},
			},
		}
	}

	root := &som.SomMetaNode{
		ClassName: "D99DemoDocument",
		SectionID: "DEMO",
		Kind:      som.SomMetaKindSection,
		TypeName:  "D99DemoDocument",
		Document: &som.SomDocMeta{
			Name:        "Demo Document",
			Description: "The demo specification document.",
			BasedOn:     []string{"D00SolutionBlueprint"},
		},
		DocComment: "Root of the demo document.",
		Children: []*som.SomMetaNode{
			{
				ClassName:          "IntroductionAndScope",
				MemberName:         "introductionAndScope",
				SectionID:          "INSC",
				Kind:               som.SomMetaKindSection,
				TypeName:           "IntroductionAndScope",
				SerializationOrder: intp(1),
				ContentHelp:        "Describe why the system exists.",
				Comment:            "Keep this short.",
				MapsTo:             "CurrentLandscape",
				DetailedIn:         "D01RequirementsSpecification",
				Children: []*som.SomMetaNode{
					{
						ClassName:          "IntroductionAndScope",
						MemberName:         "summary",
						Kind:               som.SomMetaKindContent,
						TypeName:           "String",
						Min:                intp(1),
						SerializationOrder: intp(1),
						ContentType: &som.SomContentTypeMeta{
							Type:        "diagram",
							Description: "A mermaid context diagram.",
						},
						DocComment: "What the system covers.",
					},
					{
						ClassName:          "Goals",
						MemberName:         "goals",
						SectionID:          "GOAL",
						Kind:               som.SomMetaKindSection,
						TypeName:           "Goals",
						SerializationOrder: intp(2),
						Children: []*som.SomMetaNode{
							{
								ClassName:        "Goals",
								MemberName:       "entries",
								SectionID:        "GOAL-ITEM-LST",
								SectionIDPattern: "GOAL-ITEM-xxx",
								Kind:             som.SomMetaKindList,
								TypeName:         "List<GoalEntry>",
								Min:              intp(1),
								Extra: []*som.SomMetaExtra{
									{
										Annotation: "Max",
										Args:       map[string]interface{}{"count": 4},
									},
								},
								ElementNode: element,
							},
						},
					},
				},
			},
			{
				ClassName:          "DocumentControl",
				MemberName:         "documentControl",
				SectionID:          "DOCO",
				Kind:               som.SomMetaKindForm,
				TypeName:           "DocumentControl",
				SerializationOrder: intp(2),
				Form: &som.SomFormMeta{Fields: []*som.SomFormFieldMeta{
					{
						Name:        "version",
						TypeName:    "String",
						Description: "Version",
						Required:    true,
						Hint:        "e.g. 1.0",
						Order:       1,
					},
					{Name: "approvedBy", TypeName: "String", Order: 2},
					{Name: "reviewCount", TypeName: "int", Order: 3},
				}},
			},
			risk("primaryRisk"),
			risk("fallbackRisk"),
			{
				ClassName:  "PhaseTwo",
				MemberName: "phaseTwo",
				SectionID:  "PHASE-2",
				Kind:       som.SomMetaKindSection,
				TypeName:   "PhaseTwo",
				Children: []*som.SomMetaNode{
					{
						ClassName:  "PhaseTwo",
						MemberName: "outline",
						Kind:       som.SomMetaKindContent,
						TypeName:   "String",
					},
				},
			},
			{
				ClassName:  "D99DemoDocument",
				MemberName: "related",
				Kind:       som.SomMetaKindComplex,
				TypeName:   "D99DemoDocument",
				Recursive:  true,
			},
			{
				ClassName:  "D99DemoDocument",
				MemberName: "legacy",
				SectionID:  "OLD",
				Kind:       som.SomMetaKindContent,
				TypeName:   "String",
				Unused:     true,
			},
			{
				ClassName:  "D99DemoDocument",
				MemberName: "tags",
				Kind:       som.SomMetaKindList,
				TypeName:   "List<String>",
			},
		},
	}
	tree, err := som.NewSomMetaTree(root)
	if err != nil {
		t.Fatalf("fixture tree: %v", err)
	}
	return tree
}

// metaPathOf returns a node's static path, "" for element-subtree nodes —
// the test-side stand-in for the other ports' nullable `path` getter.
func metaPathOf(t *testing.T, n *som.SomMetaNode) string {
	p, err := n.Path()
	if err != nil {
		t.Fatalf("path: %v", err)
	}
	return p
}

func metaParentOf(t *testing.T, n *som.SomMetaNode) *som.SomMetaNode {
	p, err := n.Parent()
	if err != nil {
		t.Fatalf("parent: %v", err)
	}
	return p
}

func metaTestWiring(c *checker, t *testing.T) {
	tree := metaFixtureTree(t)

	// root path is the root segment and parent is null
	c.check("wiring.root.path", metaPathOf(t, tree.Root) == "DEMO",
		metaPathOf(t, tree.Root))
	c.check("wiring.root.segment", tree.Root.Segment() == "DEMO", "")
	c.check("wiring.root.parent", metaParentOf(t, tree.Root) == nil, "")
	c.check("wiring.root.doc.name", tree.Root.Document.Name == "Demo Document", "")
	c.check("wiring.root.doc.basedOn",
		sliceEq(tree.Root.Document.BasedOn, []string{"D00SolutionBlueprint"}), "")

	// child paths follow the SOM §8 grammar (sectionId ?? memberName)
	insc := tree.Root.ChildByMember("introductionAndScope")
	c.check("wiring.insc.path", metaPathOf(t, insc) == "DEMO/INSC",
		metaPathOf(t, insc))
	c.check("wiring.summary.path",
		metaPathOf(t, insc.ChildByMember("summary")) == "DEMO/INSC/summary", "")
	entries := insc.ChildByMember("goals").ChildByMember("entries")
	c.check("wiring.entries.path",
		metaPathOf(t, entries) == "DEMO/INSC/GOAL/GOAL-ITEM-LST",
		metaPathOf(t, entries))

	// parent links are wired for children and element subtrees
	c.check("wiring.entries.parent",
		metaParentOf(t, entries).Segment() == "GOAL", "")
	c.check("wiring.element.parent",
		metaParentOf(t, entries.ElementNode) == entries, "")
	c.check("wiring.element.child.parent",
		metaParentOf(t, entries.ElementNode.Children[0]) == entries.ElementNode, "")

	// element subtree nodes carry no static path
	entries2 := tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST")
	element := entries2.ElementNode
	c.check("wiring.element.path", metaPathOf(t, element) == "", "")
	c.check("wiring.element.text.path",
		metaPathOf(t, element.ChildByMember("text")) == "", "")
	c.check("wiring.element.subTasks.path",
		metaPathOf(t, element.ChildByMember("subTasks")) == "", "")

	// allNodes covers children and element subtrees in document order
	all := tree.AllNodes()
	names := make([]string, len(all))
	for i, n := range all {
		names[i] = n.DebugName()
	}
	indexOf := func(name string) int {
		for i, n := range names {
			if n == name {
				return i
			}
		}
		return -1
	}
	c.check("wiring.allNodes.first", names[0] == "D99DemoDocument", names[0])
	c.check("wiring.allNodes.goalEntry", indexOf("GoalEntry") >= 0, "")
	c.check("wiring.allNodes.taskNote", indexOf("TaskEntry.note") >= 0, "")
	c.check("wiring.allNodes.fallbackRisk", indexOf("Risk.fallbackRisk") >= 0, "")
	c.check("wiring.allNodes.elementAfterList",
		indexOf("GoalEntry") > indexOf("Goals.entries"), "")

	// a root without @Document metadata is rejected
	_, errNoDoc := som.NewSomMetaTree(&som.SomMetaNode{
		ClassName: "X",
		Kind:      som.SomMetaKindSection,
		TypeName:  "X",
	})
	c.check("wiring.noDocumentRejected", errNoDoc != nil, "")

	// a node belongs to exactly one tree
	_, errOneTree := som.NewSomMetaTree(tree.Root)
	c.check("wiring.oneTreeRule", errOneTree != nil, "")

	// an unattached node refuses path/parent access
	loose := &som.SomMetaNode{
		ClassName: "X",
		Kind:      som.SomMetaKindScalar,
		TypeName:  "int",
	}
	_, errPath := loose.Path()
	c.check("wiring.loose.path", errPath != nil, "")
	_, errParent := loose.Parent()
	c.check("wiring.loose.parent", errParent != nil, "")
}

func metaTestMetadataSlots(c *checker, t *testing.T) {
	tree := metaFixtureTree(t)

	// section node carries help, comment and traceability links
	insc := tree.ByID("INSC")
	c.check("slots.insc.help",
		insc.ContentHelp == "Describe why the system exists.", "")
	c.check("slots.insc.comment", insc.Comment == "Keep this short.", "")
	c.check("slots.insc.mapsTo", insc.MapsTo == "CurrentLandscape", "")
	c.check("slots.insc.detailedIn",
		insc.DetailedIn == "D01RequirementsSpecification", "")
	c.check("slots.insc.order",
		insc.SerializationOrder != nil && *insc.SerializationOrder == 1, "")

	// content node carries @Min, @ContentType and doc comment
	summary := tree.ByPath("DEMO/INSC/summary")
	c.check("slots.summary.kind", summary.Kind == som.SomMetaKindContent, "")
	c.check("slots.summary.min", summary.Min != nil && *summary.Min == 1, "")
	c.check("slots.summary.ct.type", summary.ContentType.Type == "diagram", "")
	c.check("slots.summary.ct.desc",
		summary.ContentType.Description == "A mermaid context diagram.", "")
	c.check("slots.summary.doc",
		summary.DocComment == "What the system covers.", "")

	// form node exposes fields with description/required/hint/order
	form := tree.ByID("DOCO").Form
	fieldNames := make([]string, len(form.Fields))
	for i, f := range form.Fields {
		fieldNames[i] = f.Name
	}
	c.check("slots.form.fields",
		sliceEq(fieldNames, []string{"version", "approvedBy", "reviewCount"}), "")
	version := form.FieldNamed("version")
	c.check("slots.form.version.required", version.Required == true, "")
	c.check("slots.form.version.hint", version.Hint == "e.g. 1.0", "")
	c.check("slots.form.version.desc", version.Description == "Version", "")
	c.check("slots.form.version.order", version.Order == 1, "")
	c.check("slots.form.approvedBy.required",
		form.FieldNamed("approvedBy").Required == false, "")
	c.check("slots.form.missing", form.FieldNamed("missing") == nil, "")

	// list node carries @Min plus the lossless extra list (@Max)
	entries := tree.ByID("GOAL-ITEM-LST")
	c.check("slots.entries.kind", entries.Kind == som.SomMetaKindList, "")
	c.check("slots.entries.min", entries.Min != nil && *entries.Min == 1, "")
	c.check("slots.entries.pattern",
		entries.SectionIDPattern == "GOAL-ITEM-xxx", "")
	c.check("slots.entries.extra",
		len(entries.Extra) == 1 &&
			entries.Extra[0].Annotation == "Max" &&
			entries.Extra[0].Args != nil &&
			entries.Extra[0].Args["count"] == 4, "")

	// @Unused and recursive flags are carried
	c.check("slots.old.unused", tree.ByID("OLD").Unused == true, "")
	related := tree.Root.ChildByMember("related")
	c.check("slots.related.recursive", related.Recursive == true, "")
	c.check("slots.related.children", len(related.Children) == 0, "")

	// class doc comment is carried where it differs from the member one
	c.check("slots.risk.classDoc",
		tree.ByID("RISK").ClassDocComment == "A programme risk.", "")
}

func metaTestById(c *checker, t *testing.T) {
	tree := metaFixtureTree(t)

	// resolves an exact section id
	c.check("byId.demo", tree.ByID("DEMO") == tree.Root, "")
	c.check("byId.goal", tree.ByID("GOAL").MemberName == "goals", "")

	// a shared class at two positions: first wins, allById has both
	c.check("byId.risk.first", tree.ByID("RISK").MemberName == "primaryRisk", "")
	risks := tree.AllByID("RISK")
	riskMembers := make([]string, len(risks))
	for i, n := range risks {
		riskMembers[i] = n.MemberName
	}
	c.check("byId.risk.all",
		sliceEq(riskMembers, []string{"primaryRisk", "fallbackRisk"}), "")

	// a resolved @SectionIdPattern id resolves to the element subtree
	element := tree.ByID("GOAL-ITEM-3")
	c.check("byId.pattern.class", element.ClassName == "GoalEntry", "")
	c.check("byId.pattern.element",
		element == tree.ByID("GOAL-ITEM-LST").ElementNode, "")
	c.check("byId.nestedPattern",
		tree.ByID("GOAL-TASK-12").ClassName == "TaskEntry", "")

	// unknown and non-matching ids return nil / empty
	c.check("byId.nope", tree.ByID("NOPE") == nil, "")
	c.check("byId.dangling", tree.ByID("GOAL-ITEM-") == nil, "")
	c.check("byId.nonNumeric", tree.ByID("GOAL-ITEM-x") == nil, "")
	c.check("byId.allNope", len(tree.AllByID("NOPE")) == 0, "")
}

func metaTestByPath(c *checker, t *testing.T) {
	tree := metaFixtureTree(t)

	// resolves the bare root and nested sections
	c.check("byPath.root", tree.ByPath("DEMO") == tree.Root, "")
	c.check("byPath.insc", tree.ByPath("DEMO/INSC").SectionID == "INSC", "")
	c.check("byPath.goal", tree.ByPath("DEMO/INSC/GOAL").MemberName == "goals", "")
	c.check("byPath.doco", tree.ByPath("DEMO/DOCO").Kind == som.SomMetaKindForm, "")

	// a list container resolves only as the final segment
	c.check("byPath.list.final",
		tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST").Kind == som.SomMetaKindList, "")
	c.check("byPath.list.notFinal",
		tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST/text") == nil, "")

	// a `-<seq>` item suffix descends into the element subtree
	item := tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2")
	c.check("byPath.item.class", item.ClassName == "GoalEntry", "")
	text := tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/text")
	c.check("byPath.item.text", text.Kind == som.SomMetaKindContent, "")

	// nested lists inside an element subtree resolve dynamically
	task := tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-1/subTasks-3/note")
	c.check("byPath.nested",
		task != nil &&
			task.ClassName == "TaskEntry" &&
			task.Kind == som.SomMetaKindContent, "")

	// a hyphen+digit section id is not mis-read as a list item
	phase := tree.ByPath("DEMO/PHASE-2")
	c.check("byPath.phase",
		phase.Kind == som.SomMetaKindSection && phase.MemberName == "phaseTwo", "")
	c.check("byPath.phase.outline",
		tree.ByPath("DEMO/PHASE-2/outline").Kind == som.SomMetaKindContent, "")

	// a scalar list item is a value leaf (resolves to the list node)
	c.check("byPath.scalarItem",
		tree.ByPath("DEMO/tags-4") == tree.ByPath("DEMO/tags"), "")
	c.check("byPath.scalarItem.deeper", tree.ByPath("DEMO/tags-4/deeper") == nil, "")

	// descending past a recursive re-entry terminates
	c.check("byPath.recursive", tree.ByPath("DEMO/related").Recursive == true, "")
	c.check("byPath.recursive.past", tree.ByPath("DEMO/related/INSC") == nil, "")

	// dangling paths and foreign roots return nil
	c.check("byPath.empty", tree.ByPath("") == nil, "")
	c.check("byPath.other", tree.ByPath("OTHER") == nil, "")
	c.check("byPath.missing", tree.ByPath("DEMO/missing") == nil, "")
	c.check("byPath.pastLeaf", tree.ByPath("DEMO/INSC/summary/deeper") == nil, "")
	c.check("byPath.itemMissing",
		tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-2/missing") == nil, "")

	// byId and byPath agree on the node they address (SOM §8)
	c.check("agree.insc", tree.ByID("INSC") == tree.ByPath("DEMO/INSC"), "")
	c.check("agree.list",
		tree.ByID("GOAL-ITEM-LST") == tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST"),
		"")
	c.check("agree.item",
		tree.ByID("GOAL-ITEM-1") == tree.ByPath("DEMO/INSC/GOAL/GOAL-ITEM-LST-1"),
		"")
}

func metaTestItemPath(c *checker, t *testing.T) {
	tree := metaFixtureTree(t)

	// builds `<listPath>-<seq>` for a statically placed list
	entries := tree.ByID("GOAL-ITEM-LST")
	itemPath2, errItemPath := entries.ItemPath(2)
	c.check("itemPath.build",
		errItemPath == nil && itemPath2 == "DEMO/INSC/GOAL/GOAL-ITEM-LST-2",
		itemPath2)
	c.check("itemPath.resolves",
		tree.ByPath(itemPath2).ClassName == "GoalEntry", "")

	// rejects non-list nodes and lists inside element subtrees
	_, errNonList := tree.ByID("INSC").ItemPath(1)
	c.check("itemPath.nonList", errNonList != nil, "")
	nested := tree.ByID("GOAL-ITEM-LST").ElementNode.ChildByMember("subTasks")
	_, errNested := nested.ItemPath(1)
	c.check("itemPath.nestedList", errNested != nil, "")
}

// TestSpecMeta runs the shared metadata-core suite (SOM §7) (87 checks).
func TestSpecMeta(t *testing.T) {
	c := &checker{t: t}
	metaTestWiring(c, t)
	metaTestMetadataSlots(c, t)
	metaTestById(c, t)
	metaTestByPath(c, t)
	metaTestItemPath(c, t)
	c.finish()
}
