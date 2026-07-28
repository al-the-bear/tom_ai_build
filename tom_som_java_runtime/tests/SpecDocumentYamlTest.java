import java.util.ArrayList;
import java.util.List;

import tom_som_runtime.Json;
import tom_som_runtime.SomMetaBridge;
import tom_som_runtime.SomMetaTree;
import tom_som_runtime.SpecDocument;
import tom_som_runtime.SpecDocumentYaml;
import tom_som_runtime.SpecModel;
import tom_som_runtime.SpecYamlContents;
import tom_som_runtime.SpecYamlFormatException;

/**
 * Hierarchical {@code *.docspecs.yaml} v2 codec tests — a port of
 * {@code tom_som_go_runtime/tests/spec_document_yaml_test.go} (itself a port
 * of {@code spec_document_yaml_test.ts} / {@code spec_document_yaml_test.js} /
 * {@code spec_document_yaml_test.py} / {@code spec_document_yaml_test.dart}).
 *
 * <p>The codec walks the document root's SomMetaTree: sections nest, keys are
 * {@code <section-id> <member-name>}, list items key by stored section id (or
 * an anonymous positional {@code <member>-<n>}), body text uses the literal
 * {@code content} key, and form fields use their bare names. Round-trip is
 * lossless modulo the SOM §12.4 empty-line dedup; version-1 files and
 * unmatched keys are structured load errors.
 *
 * <p>JUnit is unavailable on the build host, so this is a plain {@code main()}
 * that exits 0 on success and 1 on failure (same shape as SomFacadeTest).
 */
public final class SpecDocumentYamlTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  /**
   * Exercises every field kind: root body content, a content section with a
   * nested complex section, a complex list with {@code @SectionIdPattern}, a
   * scalar list, a {@code @Form} with a numeric field, enum and int leaves.
   */
  private static final String YAML_TEST_MODEL_JSON =
      """
      {
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
          "Scope": {
            "name": "Scope",
            "fields": [
              {"name": "inScope", "kind": "content", "sectionId": "D00-INS"},
              {"name": "outOfScope", "kind": "content"}
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
          "Requirement": {
            "name": "Requirement",
            "fields": [
              {"name": "text", "kind": "content"},
              {"name": "notes", "kind": "list", "elementType": "String",
               "elementIsComplex": false}
            ]
          }
        }
      }""";

  private static SomMetaTree yamlTestTree() {
    SpecModel model = SpecModel.fromJson(Json.parseObject(YAML_TEST_MODEL_JSON));
    return SomMetaBridge.buildSomMetaTree(model, null);
  }

  /**
   * Whether the codec call throws a {@link SpecYamlFormatException} whose
   * message contains {@code needle}.
   */
  private static boolean throwsFormat(Runnable action, String needle) {
    try {
      action.run();
      return false;
    } catch (SpecYamlFormatException e) {
      return e.getMessage().contains(needle);
    }
  }

  private static SpecDocument roundTrip(SomMetaTree tree, SpecDocument doc) {
    return SpecDocumentYaml.decode(SpecDocumentYaml.encode(doc, tree, null), tree).document;
  }

  /** Builds a document touching every store and the SOM §12.4 edge cases. */
  private static SpecDocument populated() {
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00", "Preamble body text.");
    doc.setContent("D00/D00-OVR", "line one\nline two\nline three");
    doc.setContent("D00/D00-SCO/D00-INS", "  indented first line\n    deeper");
    doc.setContent("D00/D00-SCO/outOfScope", "ends with newline\n");
    doc.setContent("D00/D00-PRI", "high");
    doc.setContent("D00/count", "3");
    doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
    doc.setFormField("D00/D00-HDR", "reviewer", "Grace Hopper");
    doc.setFormField("D00/D00-HDR", "revision", "7");
    String a = doc.addListItem("D00/D00-REQ", "REQ-AB1");
    doc.setContent(a + "/text", "value: with: colons # and hash");
    String n1 = doc.addListItem(a + "/notes");
    doc.setContent(n1, "a nested scalar note");
    String b = doc.addListItem("D00/D00-REQ"); // anonymous item
    doc.setContent(b + "/text", "second requirement");
    String t1 = doc.addListItem("D00/D00-TAG");
    doc.setContent(t1, "alpha");
    return doc;
  }

  private static String quote(String s) {
    return s == null ? "null" : Json.write(s);
  }

  private static String byteDiff(String got, String want) {
    if (got.equals(want)) {
      return "";
    }
    int n = Math.min(got.length(), want.length());
    int i = 0;
    while (i < n && got.charAt(i) == want.charAt(i)) {
      i++;
    }
    int from = Math.max(0, i - 20);
    return "first diff at "
        + i
        + ": got "
        + quote(got.substring(from, Math.min(got.length(), i + 20)))
        + " want "
        + quote(want.substring(from, Math.min(want.length(), i + 20)));
  }

  // --- sections ---------------------------------------------------------------

  private static void yamlTestEncode(SomMetaTree tree) {
    // writes the v2 header, version and hierarchical structure
    String yaml = SpecDocumentYaml.encode(populated(), tree, "1.0");
    check(
        "encode.header",
        yaml.startsWith("# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n"),
        yaml.split("\n", 2)[0]);
    check("encode.version", yaml.contains("version: 2\n"), "");
    check("encode.stamp", yaml.contains("modelVersion: \"1.0\"\n"), "");
    check("encode.rootKey", yaml.contains("\ndocument:\n  D00 Demo:\n"), "");
    check(
        "encode.nesting",
        yaml.contains("\n    D00-SCO scope:\n      D00-INS inScope:"),
        "");
    check(
        "encode.rootContent",
        yaml.contains("\n    content: |2-\n      Preamble body text.\n"),
        "");
    check(
        "encode.storedItemId",
        yaml.contains("\n    D00-REQ requirements:\n      REQ-AB1:\n"),
        "");
    check("encode.anonItem", yaml.contains("\n      requirements-2:\n"), "");
    check("encode.noFlatPaths", !yaml.contains("\"D00/"), "");

    // sibling order follows @SerializationOrder, sparse emission
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00/D00-PRI", "low"); // order 5
    doc.setContent("D00/D00-OVR", "first"); // order 0
    String sparse = SpecDocumentYaml.encode(doc, tree, null);
    check(
        "encode.order",
        sparse.indexOf("D00-OVR overview:") < sparse.indexOf("D00-PRI priority:"),
        "");
    check("encode.sparse", !sparse.contains("D00-SCO"), "");

    // non-text values are plain scalars (SOM §12.5)
    String yaml2 = SpecDocumentYaml.encode(populated(), tree, null);
    check("encode.plainEnum", yaml2.contains("\n    D00-PRI priority: high\n"), "");
    check("encode.plainInt", yaml2.contains("\n    count: 3\n"), "");
    check("encode.plainFormInt", yaml2.contains("\n      revision: 7\n"), "");

    // YAML 1.1-special values are quoted, not plain (SOM §12.5). `on`/`no` are
    // 1.1-only booleans and `1:30` is a 1.1 sexagesimal int: plain strings under
    // YAML 1.2 but bool/number under YAML 1.1 (SnakeYAML). They must emit as
    // block scalars so every runtime reads back the exact string; an ordinary
    // token stays plain.
    SpecDocument special = new SpecDocument();
    for (String v : new String[] {"on", "no", "1:30", "plain"}) {
      special.setContent(special.addListItem("D00/D00-TAG"), v);
    }
    String yaml3 = SpecDocumentYaml.encode(special, tree, null);
    check("encode.yaml11.on", yaml3.contains("\n      tags-1: |2-\n        on\n"), "");
    check("encode.yaml11.no", yaml3.contains("\n      tags-2: |2-\n        no\n"), "");
    check(
        "encode.yaml11.sexagesimal",
        yaml3.contains("\n      tags-3: |2-\n        1:30\n"),
        "");
    check("encode.yaml11.plain", yaml3.contains("\n      tags-4: plain\n"), "");
    SpecDocument outSpecial = roundTrip(tree, special);
    java.util.List<String> specialTags = outSpecial.listItems("D00/D00-TAG");
    check(
        "encode.yaml11.roundTrip",
        specialTags.size() == 4
            && "on".equals(outSpecial.content(specialTags.get(0)))
            && "no".equals(outSpecial.content(specialTags.get(1)))
            && "1:30".equals(outSpecial.content(specialTags.get(2)))
            && "plain".equals(outSpecial.content(specialTags.get(3))),
        "");

    // an empty document emits `document: {}`
    check(
        "encode.emptyDoc",
        SpecDocumentYaml.encode(new SpecDocument(), tree, null).contains("document: {}"),
        "");

    // the model-version stamp is omitted when absent
    check(
        "encode.noStamp",
        !SpecDocumentYaml.encode(new SpecDocument(), tree, null).contains("modelVersion:"),
        "");

    // values the tree cannot place are a structured error
    SpecDocument ghost = new SpecDocument();
    ghost.setContent("D00/ghost", "x");
    check(
        "encode.leftoverError",
        throwsFormat(() -> SpecDocumentYaml.encode(ghost, tree, null), ""),
        "");

    // an unknown form field is a structured error
    SpecDocument bogus = new SpecDocument();
    bogus.setFormField("D00/D00-HDR", "bogus", "v");
    check(
        "encode.unknownFormField",
        throwsFormat(() -> SpecDocumentYaml.encode(bogus, tree, null), ""),
        "");
  }

  private static void yamlTestRoundTrip(SomMetaTree tree) {
    // every value survives verbatim
    SpecDocument out = roundTrip(tree, populated());
    check("rt.root", "Preamble body text.".equals(out.content("D00")), "");
    check(
        "rt.overview",
        "line one\nline two\nline three".equals(out.content("D00/D00-OVR")),
        "");
    check(
        "rt.inScope",
        "  indented first line\n    deeper".equals(out.content("D00/D00-SCO/D00-INS")),
        "");
    check(
        "rt.outOfScope",
        "ends with newline\n".equals(out.content("D00/D00-SCO/outOfScope")),
        "");
    check("rt.priority", "high".equals(out.content("D00/D00-PRI")), "");
    check("rt.count", "3".equals(out.content("D00/count")), "");
    check("rt.author", "Ada Lovelace".equals(out.formField("D00/D00-HDR", "author")), "");
    check(
        "rt.reviewer", "Grace Hopper".equals(out.formField("D00/D00-HDR", "reviewer")), "");
    check("rt.revision", "7".equals(out.formField("D00/D00-HDR", "revision")), "");
    check("rt.reqCount", out.listItemCount("D00/D00-REQ") == 2, "");
    List<String> items = out.listItems("D00/D00-REQ");
    check("rt.item0.id", "REQ-AB1".equals(out.itemSectionId(items.get(0))), "");
    check("rt.item1.id", out.itemSectionId(items.get(1)) == null, "");
    check(
        "rt.item0.text",
        "value: with: colons # and hash".equals(out.content(items.get(0) + "/text")),
        "");
    check(
        "rt.item1.text",
        "second requirement".equals(out.content(items.get(1) + "/text")),
        "");
    List<String> notes = out.listItems(items.get(0) + "/notes");
    check(
        "rt.notes",
        notes.size() == 1 && "a nested scalar note".equals(out.content(notes.get(0))),
        "");
    List<String> tags = out.listItems("D00/D00-TAG");
    check("rt.tags", tags.size() == 1 && "alpha".equals(out.content(tags.get(0))), "");

    // encode is byte-stable across decode → re-encode
    String yaml1 = SpecDocumentYaml.encode(populated(), tree, "1.2");
    String yaml2 =
        SpecDocumentYaml.encode(SpecDocumentYaml.decode(yaml1, tree).document, tree, "1.2");
    check("rt.byteStable", yaml2.equals(yaml1), byteDiff(yaml2, yaml1));

    // the model-version stamp lands on the decoded document
    SpecYamlContents decoded =
        SpecDocumentYaml.decode(SpecDocumentYaml.encode(populated(), tree, "2.5"), tree);
    check("rt.stamp.contents", "2.5".equals(decoded.modelVersion), "");
    check("rt.stamp.document", "2.5".equals(decoded.document.modelVersion()), "");

    // markdown edge cases survive
    String[] cases = {
      "\nleading blank line",
      "trailing blank line kept as one\n\nend",
      "two trailing newlines\n\n", // block cannot represent → JSON fallback
      "trailing space on a line \nnext",
      "\ttab\tpreserved",
      "- looks: like\n  yaml: [a, b]\n# comment-ish",
      "\"double\" and 'single' quotes",
      "ends with newline\n",
      "   only-indentation-sensitive\n      nested deeper\n   back",
    };
    for (int i = 0; i < cases.length; i++) {
      String edge = cases[i];
      SpecDocument doc = new SpecDocument();
      doc.setContent("D00/D00-OVR", edge);
      String got = roundTrip(tree, doc).content("D00/D00-OVR");
      check(
          "rt.edge[" + i + "]",
          edge.equals(got),
          "got " + quote(got) + " want " + quote(edge));
    }

    // runs of 2+ empty lines collapse to one on write (SOM §12.4)
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00/D00-OVR", "a\n\n\n\nb\n\n\nc");
    check(
        "rt.emptyLineDedup",
        "a\n\nb\n\nc".equals(roundTrip(tree, doc).content("D00/D00-OVR")),
        "");

    // an empty complex list item round-trips as `{}`
    SpecDocument emptyItem = new SpecDocument();
    emptyItem.addListItem("D00/D00-REQ");
    String yaml3 = SpecDocumentYaml.encode(emptyItem, tree, null);
    check("rt.emptyItem.enc", yaml3.contains("requirements-1: {}"), yaml3);
    check(
        "rt.emptyItem.count",
        roundTrip(tree, emptyItem).listItemCount("D00/D00-REQ") == 1,
        "");
  }

  private static void yamlTestStrictDecode(SomMetaTree tree) {
    // version 1 files are rejected with a clear error
    check(
        "decode.v1Rejected",
        throwsFormat(
            () -> SpecDocumentYaml.decode("version: 1\ndocument: {}\n", tree), "version 1"),
        "");

    // a missing version is rejected
    check(
        "decode.missingVersion",
        throwsFormat(() -> SpecDocumentYaml.decode("document: {}\n", tree), ""),
        "");
    check(
        "decode.emptyText",
        throwsFormat(() -> SpecDocumentYaml.decode("", tree), ""),
        "");

    // an unmatched key is a structured load error, not a silent skip
    String bad = "version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n      x\n";
    check(
        "decode.unmatchedKey",
        throwsFormat(() -> SpecDocumentYaml.decode(bad, tree), "nonsense"),
        "");

    // a wrong root key is a structured load error
    check(
        "decode.wrongRoot",
        throwsFormat(
            () -> SpecDocumentYaml.decode("version: 2\ndocument:\n  WRONG Other: {}\n", tree),
            ""),
        "");

    // an unknown form field on read is a structured load error
    String badForm =
        "version: 2\ndocument:\n  D00 Demo:\n    D00-HDR header:\n      bogus: |-\n        v\n";
    check(
        "decode.unknownFormField",
        throwsFormat(() -> SpecDocumentYaml.decode(badForm, tree), ""),
        "");

    // a missing/empty document pass decodes as an empty document
    check(
        "decode.noDocKey",
        SpecDocumentYaml.decode("version: 2\n", tree).document.isEmpty(),
        "");
    check(
        "decode.emptyDoc",
        SpecDocumentYaml.decode("version: 2\ndocument: {}\n", tree).document.isEmpty(),
        "");

    // the raw review pass is passed through untouched
    String fixture =
        "version: 2\n"
            + "document: {}\n"
            + "review:\n"
            + "  \"D00/a\":\n"
            + "    scope: global\n";
    SpecYamlContents contents = SpecDocumentYaml.decode(fixture, tree);
    check("decode.review", contents.review.containsKey("D00/a"), "");
  }

  /**
   * A section/complex node whose field carries no {@code @SectionId} takes its
   * target class's id for the mapping key (SOM §12.2 class fallback), while its
   * path segment stays field-level. {@code control} (id-less field) → {@code
   * Control} (class id {@code CTRL}) emits {@code CTRL control:}; its id-less
   * leaf {@code owner} stays a bare key; the path is field-level throughout.
   */
  private static void yamlTestClassLevelOnlyKey(SomMetaTree tree) {
    SpecDocument doc = new SpecDocument();
    doc.setContent("D00/control/CTRL-SUM", "controlled summary");
    doc.setContent("D00/control/owner", "the owner");
    String yaml = SpecDocumentYaml.encode(doc, tree, null);

    // the complex node's key gains the target class id; the path stays field-level
    check("classKey.section", yaml.contains("\n    CTRL control:\n"), yaml);
    check("classKey.idLeaf", yaml.contains("\n      CTRL-SUM summary:"), yaml);
    check("classKey.bareLeaf", yaml.contains("\n      owner:"), yaml);

    SpecDocument out = roundTrip(tree, doc);
    check(
        "classKey.rt.summary",
        "controlled summary".equals(out.content("D00/control/CTRL-SUM")),
        "");
    check("classKey.rt.owner", "the owner".equals(out.content("D00/control/owner")), "");
  }

  // --- csmc8: stored codeSpec round-trips through yaml (codespecs_mapping.md
  // §9.2) -----------------

  private static void yamlTestCodeSpecRoundTrip(SomMetaTree tree) {
    SpecDocument doc = populated();
    doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository");
    String yaml = SpecDocumentYaml.encode(doc, tree, null);
    check("codeSpec.yaml.emitted", yaml.contains("codeSpec:"), yaml);
    SpecDocument out = roundTrip(tree, doc);
    check("codeSpec.yaml.restored",
        "CsOrder,CsOrder.total,CsOrderRepository".equals(out.codeSpec("D00/D00-OVR")),
        quote(out.codeSpec("D00/D00-OVR")));
    // Sibling without codeSpec keeps no codeSpec entry.
    check("codeSpec.yaml.sibling",
        out.codeSpec("D00/D00-PRI") == null,
        quote(out.codeSpec("D00/D00-PRI")));
  }

  private static void yamlTestCodeSpecByteStable(SomMetaTree tree) {
    SpecDocument doc = populated();
    doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total");
    String yaml1 = SpecDocumentYaml.encode(doc, tree, "1.2");
    String yaml2 = SpecDocumentYaml.encode(
        SpecDocumentYaml.decode(yaml1, tree).document, tree, "1.2");
    check("codeSpec.yaml.byteStable", yaml2.equals(yaml1), byteDiff(yaml2, yaml1));
  }

  public static void main(String[] args) {
    SomMetaTree tree = yamlTestTree();
    yamlTestEncode(tree);
    yamlTestRoundTrip(tree);
    yamlTestStrictDecode(tree);
    yamlTestClassLevelOnlyKey(tree);
    yamlTestCodeSpecRoundTrip(tree);
    yamlTestCodeSpecByteStable(tree);

    if (!failed.isEmpty()) {
      System.out.println("FAILED (" + failed.size() + " of " + (passed + failed.size()) + "):");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
    }
    System.out.println("OK: " + passed + " checks passed");
  }
}
