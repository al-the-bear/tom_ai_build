// Hierarchical `*.docspecs.yaml` v2 codec tests — a port of
// `tom_som_typescript_runtime/tests/spec_document_yaml_test.ts` (itself a port
// of `tom_som_javascript_runtime/tests/spec_document_yaml_test.js` /
// `tom_som_python_runtime/tests/spec_document_yaml_test.py` /
// `tom_som_dart_runtime/test/spec_document_yaml_test.dart`).
//
// The codec walks the document root's SomMetaTree: sections nest, keys are
// `<section-id> <member-name>`, list items key by stored section id (or an
// anonymous positional `<member>-<n>`), body text uses the literal `content`
// key, and form fields use their bare names. Round-trip is lossless modulo
// the SOM §12.4 empty-line dedup; version-1 files and unmatched keys are
// structured load errors.
package tests

import (
	"errors"
	"strings"
	"testing"

	som "github.com/al-the-bear/tom_ai_build/tom_som_go_runtime"
)

// yamlThrowsFormat reports whether err is a *SpecYamlFormatException whose
// message contains needle — the Go stand-in for the other ports'
// `_throwsFormat` helper.
func yamlThrowsFormat(err error, needle string) bool {
	var fe *som.SpecYamlFormatException
	if !errors.As(err, &fe) {
		return false
	}
	return strings.Contains(fe.Message, needle)
}

// yamlTestModelJSON exercises every field kind: root body content, a content
// section with a nested complex section, a complex list with
// `@SectionIdPattern`, a scalar list, a `@Form` with a numeric field, enum and
// int leaves.
const yamlTestModelJSON = `{
  "modelVersion": 1,
  "roots": [{"type": "Demo", "title": "Demo Document", "sectionId": "D00"}],
  "classes": {
    "Demo": {
      "name": "Demo",
      "sectionId": "D00",
      "fields": [
        {"name": "overview", "kind": "content", "sectionId": "D00-OVR",
         "serializationOrder": 0},
        {"name": "scope", "kind": "complex", "sectionId": "D00-SCO",
         "type": "Scope", "serializationOrder": 1},
        {"name": "header", "kind": "form", "sectionId": "D00-HDR",
         "serializationOrder": 2,
         "formFields": [
           {"name": "author", "label": "Author", "type": "String"},
           {"name": "reviewer", "label": "Reviewer", "type": "String"},
           {"name": "revision", "label": "Revision", "type": "int"}
         ]},
        {"name": "requirements", "kind": "list", "sectionId": "D00-REQ",
         "sectionIdPattern": "REQ-xxx", "elementType": "Requirement",
         "elementIsComplex": true, "serializationOrder": 3},
        {"name": "tags", "kind": "list", "sectionId": "D00-TAG",
         "elementType": "String", "elementIsComplex": false,
         "serializationOrder": 4},
        {"name": "priority", "kind": "enum", "sectionId": "D00-PRI",
         "enumType": "Priority", "enumValues": ["low", "high"],
         "serializationOrder": 5},
        {"name": "count", "kind": "scalar", "type": "int",
         "serializationOrder": 6},
        {"name": "control", "kind": "complex", "type": "Control",
         "serializationOrder": 7}
      ]
    },
    "Control": {
      "name": "Control",
      "sectionId": "CTRL",
      "fields": [
        {"name": "summary", "kind": "content", "sectionId": "CTRL-SUM"},
        {"name": "owner", "kind": "content"}
      ]
    },
    "Scope": {
      "name": "Scope",
      "fields": [
        {"name": "inScope", "kind": "content", "sectionId": "D00-INS"},
        {"name": "outOfScope", "kind": "content"}
      ]
    },
    "Requirement": {
      "name": "Requirement",
      "fields": [
        {"name": "text", "kind": "content"},
        {"name": "notes", "kind": "list", "elementType": "String",
         "elementIsComplex": false}
      ]
    }
  }
}`

func yamlTestTree(t *testing.T) *som.SomMetaTree {
	model, err := som.SpecModelFromJSON([]byte(yamlTestModelJSON))
	if err != nil {
		t.Fatalf("model: %v", err)
	}
	tree, err := som.BuildSomMetaTree(model, "")
	if err != nil {
		t.Fatalf("tree: %v", err)
	}
	return tree
}

func yamlEnc(t *testing.T, tree *som.SomMetaTree, d *som.SpecDocument, stamp string) string {
	out, err := som.EncodeYaml(d, tree, stamp)
	if err != nil {
		t.Fatalf("encode: %v", err)
	}
	return out
}

func yamlDec(t *testing.T, tree *som.SomMetaTree, yaml string) *som.SpecYamlContents {
	contents, err := som.DecodeYaml(yaml, tree)
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	return contents
}

func yamlRoundTrip(t *testing.T, tree *som.SomMetaTree, d *som.SpecDocument) *som.SpecDocument {
	return yamlDec(t, tree, yamlEnc(t, tree, d, "")).Document
}

// yamlPopulated builds a document touching every store and the SOM §12.4 edge
// cases.
func yamlPopulated(t *testing.T) *som.SpecDocument {
	doc := som.NewSpecDocument()
	doc.SetContent("D00", "Preamble body text.")
	doc.SetContent("D00/D00-OVR", "line one\nline two\nline three")
	doc.SetContent("D00/D00-SCO/D00-INS", "  indented first line\n    deeper")
	doc.SetContent("D00/D00-SCO/outOfScope", "ends with newline\n")
	doc.SetContent("D00/D00-PRI", "high")
	doc.SetContent("D00/count", "3")
	doc.SetFormField("D00/D00-HDR", "author", "Ada Lovelace")
	doc.SetFormField("D00/D00-HDR", "reviewer", "Grace Hopper")
	doc.SetFormField("D00/D00-HDR", "revision", "7")
	a, err := doc.AddListItemWithSectionID("D00/D00-REQ", "REQ-AB1")
	if err != nil {
		t.Fatalf("addListItem: %v", err)
	}
	doc.SetContent(a+"/text", "value: with: colons # and hash")
	n1 := doc.AddListItem(a + "/notes")
	doc.SetContent(n1, "a nested scalar note")
	b := doc.AddListItem("D00/D00-REQ") // anonymous item
	doc.SetContent(b+"/text", "second requirement")
	t1 := doc.AddListItem("D00/D00-TAG")
	doc.SetContent(t1, "alpha")
	return doc
}

func yamlTestEncode(c *checker, t *testing.T, tree *som.SomMetaTree) {
	// writes the v2 header, version and hierarchical structure
	yaml := yamlEnc(t, tree, yamlPopulated(t), "1.0")
	c.check("encode.header",
		strings.HasPrefix(yaml,
			"# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n"),
		strings.SplitN(yaml, "\n", 2)[0])
	c.check("encode.version", strings.Contains(yaml, "version: 2\n"), "")
	c.check("encode.stamp", strings.Contains(yaml, "modelVersion: \"1.0\"\n"), "")
	c.check("encode.rootKey",
		strings.Contains(yaml, "\ndocument:\n  D00 Demo:\n"), "")
	c.check("encode.nesting",
		strings.Contains(yaml, "\n    D00-SCO scope:\n      D00-INS inScope:"), "")
	c.check("encode.rootContent",
		strings.Contains(yaml, "\n    content: |2-\n      Preamble body text.\n"),
		"")
	c.check("encode.storedItemId",
		strings.Contains(yaml, "\n    D00-REQ requirements:\n      REQ-AB1:\n"),
		"")
	c.check("encode.anonItem",
		strings.Contains(yaml, "\n      requirements-2:\n"), "")
	c.check("encode.noFlatPaths", !strings.Contains(yaml, "\"D00/"), "")

	// sibling order follows @SerializationOrder, sparse emission
	doc := som.NewSpecDocument()
	doc.SetContent("D00/D00-PRI", "low")   // order 5
	doc.SetContent("D00/D00-OVR", "first") // order 0
	sparse := yamlEnc(t, tree, doc, "")
	c.check("encode.order",
		strings.Index(sparse, "D00-OVR overview:") <
			strings.Index(sparse, "D00-PRI priority:"), "")
	c.check("encode.sparse", !strings.Contains(sparse, "D00-SCO"), "")

	// non-text values are plain scalars (SOM §12.5)
	yaml2 := yamlEnc(t, tree, yamlPopulated(t), "")
	c.check("encode.plainEnum",
		strings.Contains(yaml2, "\n    D00-PRI priority: high\n"), "")
	c.check("encode.plainInt", strings.Contains(yaml2, "\n    count: 3\n"), "")
	c.check("encode.plainFormInt",
		strings.Contains(yaml2, "\n      revision: 7\n"), "")

	// YAML 1.1-special values are quoted, not plain (SOM §12.5). `on`/`no` are
	// 1.1-only booleans and `1:30` is a 1.1 sexagesimal int: plain strings under
	// YAML 1.2 but bool/number under YAML 1.1. They must emit as block scalars so
	// every runtime reads back the exact string; an ordinary token stays plain.
	special := som.NewSpecDocument()
	for _, v := range []string{"on", "no", "1:30", "plain"} {
		special.SetContent(special.AddListItem("D00/D00-TAG"), v)
	}
	yaml3 := yamlEnc(t, tree, special, "")
	c.check("encode.yaml11.on",
		strings.Contains(yaml3, "\n      tags-1: |2-\n        on\n"), "")
	c.check("encode.yaml11.no",
		strings.Contains(yaml3, "\n      tags-2: |2-\n        no\n"), "")
	c.check("encode.yaml11.sexagesimal",
		strings.Contains(yaml3, "\n      tags-3: |2-\n        1:30\n"), "")
	c.check("encode.yaml11.plain",
		strings.Contains(yaml3, "\n      tags-4: plain\n"), "")
	outSpecial := yamlRoundTrip(t, tree, special)
	specialTags := outSpecial.ListItems("D00/D00-TAG")
	specialOk := len(specialTags) == 4 &&
		outSpecial.ContentOr(specialTags[0]) == "on" &&
		outSpecial.ContentOr(specialTags[1]) == "no" &&
		outSpecial.ContentOr(specialTags[2]) == "1:30" &&
		outSpecial.ContentOr(specialTags[3]) == "plain"
	c.check("encode.yaml11.roundTrip", specialOk, "")

	// an empty document emits `document: {}`
	c.check("encode.emptyDoc",
		strings.Contains(yamlEnc(t, tree, som.NewSpecDocument(), ""),
			"document: {}"), "")

	// the model-version stamp is omitted when absent
	c.check("encode.noStamp",
		!strings.Contains(yamlEnc(t, tree, som.NewSpecDocument(), ""),
			"modelVersion:"), "")

	// values the tree cannot place are a structured error
	ghost := som.NewSpecDocument()
	ghost.SetContent("D00/ghost", "x")
	_, errGhost := som.EncodeYaml(ghost, tree, "")
	c.check("encode.leftoverError", yamlThrowsFormat(errGhost, ""), "")

	// an unknown form field is a structured error
	bogus := som.NewSpecDocument()
	bogus.SetFormField("D00/D00-HDR", "bogus", "v")
	_, errBogus := som.EncodeYaml(bogus, tree, "")
	c.check("encode.unknownFormField", yamlThrowsFormat(errBogus, ""), "")
}

func yamlTestRoundTrip(c *checker, t *testing.T, tree *som.SomMetaTree) {
	// every value survives verbatim
	out := yamlRoundTrip(t, tree, yamlPopulated(t))
	c.check("rt.root", out.ContentOr("D00") == "Preamble body text.", "")
	c.check("rt.overview",
		out.ContentOr("D00/D00-OVR") == "line one\nline two\nline three", "")
	c.check("rt.inScope",
		out.ContentOr("D00/D00-SCO/D00-INS") ==
			"  indented first line\n    deeper", "")
	c.check("rt.outOfScope",
		out.ContentOr("D00/D00-SCO/outOfScope") == "ends with newline\n", "")
	c.check("rt.priority", out.ContentOr("D00/D00-PRI") == "high", "")
	c.check("rt.count", out.ContentOr("D00/count") == "3", "")
	c.check("rt.author",
		out.FormFieldOr("D00/D00-HDR", "author") == "Ada Lovelace", "")
	c.check("rt.reviewer",
		out.FormFieldOr("D00/D00-HDR", "reviewer") == "Grace Hopper", "")
	c.check("rt.revision", out.FormFieldOr("D00/D00-HDR", "revision") == "7", "")
	c.check("rt.reqCount", out.ListItemCount("D00/D00-REQ") == 2, "")
	items := out.ListItems("D00/D00-REQ")
	c.check("rt.item0.id", out.ItemSectionIDOr(items[0]) == "REQ-AB1", "")
	_, item1HasID := out.ItemSectionID(items[1])
	c.check("rt.item1.id", !item1HasID, "")
	c.check("rt.item0.text",
		out.ContentOr(items[0]+"/text") == "value: with: colons # and hash", "")
	c.check("rt.item1.text",
		out.ContentOr(items[1]+"/text") == "second requirement", "")
	notes := out.ListItems(items[0] + "/notes")
	c.check("rt.notes",
		len(notes) == 1 && out.ContentOr(notes[0]) == "a nested scalar note", "")
	tags := out.ListItems("D00/D00-TAG")
	c.check("rt.tags", len(tags) == 1 && out.ContentOr(tags[0]) == "alpha", "")

	// encode is byte-stable across decode → re-encode
	yaml1 := yamlEnc(t, tree, yamlPopulated(t), "1.2")
	yaml2 := yamlEnc(t, tree, yamlDec(t, tree, yaml1).Document, "1.2")
	c.check("rt.byteStable", yaml2 == yaml1, byteDiff("rt.byteStable", yaml2, yaml1))

	// the model-version stamp lands on the decoded document
	decoded := yamlDec(t, tree, yamlEnc(t, tree, yamlPopulated(t), "2.5"))
	c.check("rt.stamp.contents", decoded.ModelVersion == "2.5", "")
	c.check("rt.stamp.document", decoded.Document.ModelVersion == "2.5", "")

	// markdown edge cases survive
	cases := []string{
		"\nleading blank line",
		"trailing blank line kept as one\n\nend",
		"two trailing newlines\n\n", // block cannot represent → JSON fallback
		"trailing space on a line \nnext",
		"\ttab\tpreserved",
		"- looks: like\n  yaml: [a, b]\n# comment-ish",
		"\"double\" and 'single' quotes",
		"ends with newline\n",
		"   only-indentation-sensitive\n      nested deeper\n   back",
	}
	for i, edge := range cases {
		doc := som.NewSpecDocument()
		doc.SetContent("D00/D00-OVR", edge)
		got := yamlRoundTrip(t, tree, doc).ContentOr("D00/D00-OVR")
		c.check("rt.edge["+itoa(i)+"]", got == edge,
			"got "+quote(got)+" want "+quote(edge))
	}

	// runs of 2+ empty lines collapse to one on write (SOM §12.4)
	doc := som.NewSpecDocument()
	doc.SetContent("D00/D00-OVR", "a\n\n\n\nb\n\n\nc")
	c.check("rt.emptyLineDedup",
		yamlRoundTrip(t, tree, doc).ContentOr("D00/D00-OVR") == "a\n\nb\n\nc", "")

	// an empty complex list item round-trips as `{}`
	emptyItem := som.NewSpecDocument()
	emptyItem.AddListItem("D00/D00-REQ")
	yaml3 := yamlEnc(t, tree, emptyItem, "")
	c.check("rt.emptyItem.enc",
		strings.Contains(yaml3, "requirements-1: {}"), yaml3)
	c.check("rt.emptyItem.count",
		yamlRoundTrip(t, tree, emptyItem).ListItemCount("D00/D00-REQ") == 1, "")
}

func yamlTestStrictDecode(c *checker, t *testing.T, tree *som.SomMetaTree) {
	// version 1 files are rejected with a clear error
	_, errV1 := som.DecodeYaml("version: 1\ndocument: {}\n", tree)
	c.check("decode.v1Rejected", yamlThrowsFormat(errV1, "version 1"), "")

	// a missing version is rejected
	_, errNoVersion := som.DecodeYaml("document: {}\n", tree)
	c.check("decode.missingVersion", yamlThrowsFormat(errNoVersion, ""), "")
	_, errEmpty := som.DecodeYaml("", tree)
	c.check("decode.emptyText", yamlThrowsFormat(errEmpty, ""), "")

	// an unmatched key is a structured load error, not a silent skip
	bad := "version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n      x\n"
	_, errBad := som.DecodeYaml(bad, tree)
	c.check("decode.unmatchedKey", yamlThrowsFormat(errBad, "nonsense"), "")

	// a wrong root key is a structured load error
	_, errRoot := som.DecodeYaml("version: 2\ndocument:\n  WRONG Other: {}\n", tree)
	c.check("decode.wrongRoot", yamlThrowsFormat(errRoot, ""), "")

	// an unknown form field on read is a structured load error
	badForm := "version: 2\ndocument:\n  D00 Demo:\n" +
		"    D00-HDR header:\n      bogus: |-\n        v\n"
	_, errForm := som.DecodeYaml(badForm, tree)
	c.check("decode.unknownFormField", yamlThrowsFormat(errForm, ""), "")

	// a missing/empty document pass decodes as an empty document
	c.check("decode.noDocKey",
		yamlDec(t, tree, "version: 2\n").Document.IsEmpty(), "")
	c.check("decode.emptyDoc",
		yamlDec(t, tree, "version: 2\ndocument: {}\n").Document.IsEmpty(), "")

	// the raw review pass is passed through untouched
	fixture := "version: 2\n" +
		"document: {}\n" +
		"review:\n" +
		"  \"D00/a\":\n" +
		"    scope: global\n"
	contents := yamlDec(t, tree, fixture)
	c.check("decode.review", contents.Review.Has("D00/a"), "")
}

// TestSpecDocumentYaml runs the shared Hierarchical-codec suite
// (58 checks).
func TestSpecDocumentYaml(t *testing.T) {
	c := &checker{t: t}
	tree := yamlTestTree(t)
	yamlTestEncode(c, t, tree)
	yamlTestRoundTrip(c, t, tree)
	yamlTestStrictDecode(c, t, tree)
	yamlTestClassLevelOnlyKey(c, t, tree)
	c.finish()
}

// yamlTestClassLevelOnlyKey verifies a section whose @SectionId lives only on
// the target class keys by that class id (SOM §12.2 field-id-else-class-id). The
// `control` field carries no id; its target class `Control` carries `CTRL`, so
// the key is `CTRL control:`. The leaves keep their own content keys:
// `CTRL-SUM summary:` (field id) and bare `owner:` (no id).
func yamlTestClassLevelOnlyKey(c *checker, t *testing.T, tree *som.SomMetaTree) {
	doc := som.NewSpecDocument()
	doc.SetContent("D00/control/CTRL-SUM", "controlled summary")
	doc.SetContent("D00/control/owner", "the owner")
	yaml := yamlEnc(t, tree, doc, "")
	c.check("clskey.section",
		strings.Contains(yaml, "\n    CTRL control:\n"), yaml)
	c.check("clskey.leafId",
		strings.Contains(yaml, "\n      CTRL-SUM summary:"), yaml)
	c.check("clskey.leafBare",
		strings.Contains(yaml, "\n      owner:"), yaml)
	out := yamlRoundTrip(t, tree, doc)
	c.check("clskey.rt.summary",
		out.ContentOr("D00/control/CTRL-SUM") == "controlled summary", "")
	c.check("clskey.rt.owner",
		out.ContentOr("D00/control/owner") == "the owner", "")
}

// --- csmc8: stored codeSpec (§9.2) --------------------------------------------

// TestSpecDocumentYamlCodeSpecRoundTrip verifies a stored codeSpec survives the
// yaml round-trip and a sibling without one keeps no entry.
func TestSpecDocumentYamlCodeSpecRoundTrip(t *testing.T) {
	tree := yamlTestTree(t)
	doc := yamlPopulated(t)
	doc.SetCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository")
	yaml := yamlEnc(t, tree, doc, "")
	if !strings.Contains(yaml, "codeSpec:") {
		t.Errorf("codeSpec.yaml.emitted: %s", yaml)
	}
	out := yamlRoundTrip(t, tree, doc)
	if got := out.CodeSpecOr("D00/D00-OVR"); got != "CsOrder,CsOrder.total,CsOrderRepository" {
		t.Errorf("codeSpec.yaml.restored: %q", got)
	}
	if _, ok := out.CodeSpec("D00/D00-PRI"); ok {
		t.Errorf("codeSpec.yaml.sibling: sibling unexpectedly has a codeSpec")
	}
}

// TestSpecDocumentYamlCodeSpecByteStable verifies encode is byte-stable with a
// codeSpec across decode → re-encode.
func TestSpecDocumentYamlCodeSpecByteStable(t *testing.T) {
	tree := yamlTestTree(t)
	doc := yamlPopulated(t)
	doc.SetCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total")
	yaml1 := yamlEnc(t, tree, doc, "1.2")
	yaml2 := yamlEnc(t, tree, yamlDec(t, tree, yaml1).Document, "1.2")
	if yaml2 != yaml1 {
		t.Errorf("codeSpec.yaml.byteStable: %s", byteDiff("codeSpec.yaml.byteStable", yaml2, yaml1))
	}
}
