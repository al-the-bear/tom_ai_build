/* Hierarchical `*.docspecs.yaml` v2 codec tests — an idiomatic-C++ port of
 * the C `tom_som_c_runtime/tests/spec_document_yaml_test.c` (itself a port of
 * the Go / TS / JS / Python / Dart suites).
 *
 * The codec walks the document root's SomMetaTree: sections nest, keys are
 * `<section-id> <member-name>`, list items key by stored section id (or an
 * anonymous positional `<member>-<n>`), body text uses the literal `content`
 * key, and form fields use their bare names. Round-trip is lossless modulo the
 * SOM §12.4 empty-line dedup; version-1 files and unmatched keys are
 * structured load errors. Check names byte-match the Go/C suite.
 */
#include <cstdio>
#include <memory>
#include <optional>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_document_yaml.hpp"
#include "spec_meta.hpp"
#include "spec_meta_bridge.hpp"
#include "spec_model.hpp"
#include "spec_section_id.hpp"
#include "yaml.hpp"

namespace {

int g_checks = 0;
int g_failures = 0;

void check(const char* name, bool cond, const std::string& detail = "") {
  ++g_checks;
  if (cond) {
    return;
  }
  ++g_failures;
  if (!detail.empty()) {
    std::fprintf(stderr, "FAIL %s: %s\n", name, detail.c_str());
  } else {
    std::fprintf(stderr, "FAIL %s\n", name);
  }
}

[[noreturn]] void fatal(const char* what, const std::string& err) {
  std::fprintf(stderr, "fatal: %s: %s\n", what, err.c_str());
  std::exit(2);
}

/* Exercises every field kind: root body content, a content section with a
 * nested complex section, a complex list with `@SectionIdPattern`, a scalar
 * list, a `@Form` with a numeric field, enum and int leaves. */
const char* kModelJson = R"({
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
})";

std::unique_ptr<som::SpecModel> g_model;
std::unique_ptr<som::SomMetaTree> g_tree;

std::string yamlEnc(const som::SpecDocument& d, const std::string& stamp) {
  std::string err;
  auto out = som::encodeYaml(d, *g_tree, stamp, &err);
  if (!out.has_value()) {
    fatal("encode", err);
  }
  return *out;
}

som::SpecYamlContents yamlDec(const std::string& yaml) {
  som::SpecYamlContents out;
  std::string err;
  if (!som::decodeYaml(yaml, *g_tree, &out, &err)) {
    fatal("decode", err);
  }
  return out;
}

som::SpecYamlContents yamlRoundTrip(const som::SpecDocument& d) {
  return yamlDec(yamlEnc(d, ""));
}

std::string contentOr(const som::SpecDocument& d, const std::string& path) {
  const std::string* v = d.contentOpt(path);
  return v != nullptr ? *v : "";
}

std::string formFieldOr(const som::SpecDocument& d, const std::string& path,
                        const std::string& field) {
  const std::string* v = d.formFieldOpt(path, field);
  return v != nullptr ? *v : "";
}

bool contains(const std::string& hay, const std::string& needle) {
  return hay.find(needle) != std::string::npos;
}

/* Builds a document touching every store and the SOM §12.4 edge cases. */
som::SpecDocument yamlPopulated() {
  som::SpecDocument doc;
  doc.setContent("D00", "Preamble body text.");
  doc.setContent("D00/D00-OVR", "line one\nline two\nline three");
  doc.setContent("D00/D00-SCO/D00-INS", "  indented first line\n    deeper");
  doc.setContent("D00/D00-SCO/outOfScope", "ends with newline\n");
  doc.setContent("D00/D00-PRI", "high");
  doc.setContent("D00/count", "3");
  doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
  doc.setFormField("D00/D00-HDR", "reviewer", "Grace Hopper");
  doc.setFormField("D00/D00-HDR", "revision", "7");
  std::string a = doc.addListItemWithSectionId("D00/D00-REQ", "REQ-AB1");
  doc.setContent(a + "/text", "value: with: colons # and hash");
  {
    std::string n1 = doc.addListItem(a + "/notes");
    doc.setContent(n1, "a nested scalar note");
  }
  std::string b = doc.addListItem("D00/D00-REQ");  // anonymous
  doc.setContent(b + "/text", "second requirement");
  std::string t1 = doc.addListItem("D00/D00-TAG");
  doc.setContent(t1, "alpha");
  return doc;
}

/* ---- suites -------------------------------------------------------------- */

void yamlTestEncode() {
  {
    som::SpecDocument populated = yamlPopulated();
    std::string yaml = yamlEnc(populated, "1.0");
    static const std::string header =
        "# TomSpecs document (*.docspecs.yaml). Hierarchical format v2.\n";
    check("encode.header", yaml.compare(0, header.size(), header) == 0, yaml);
    check("encode.version", contains(yaml, "version: 2\n"));
    check("encode.stamp", contains(yaml, "modelVersion: \"1.0\"\n"));
    check("encode.rootKey", contains(yaml, "\ndocument:\n  D00 Demo:\n"));
    check("encode.nesting",
          contains(yaml, "\n    D00-SCO scope:\n      D00-INS inScope:"));
    check("encode.rootContent",
          contains(yaml, "\n    content: |2-\n      Preamble body text.\n"));
    check("encode.storedItemId",
          contains(yaml, "\n    D00-REQ requirements:\n      REQ-AB1:\n"));
    check("encode.anonItem", contains(yaml, "\n      requirements-2:\n"));
    check("encode.noFlatPaths", !contains(yaml, "\"D00/"));
  }

  /* sibling order follows @SerializationOrder, sparse emission */
  {
    som::SpecDocument doc;
    doc.setContent("D00/D00-PRI", "low");    // order 5
    doc.setContent("D00/D00-OVR", "first");  // order 0
    std::string sparse = yamlEnc(doc, "");
    auto ovr = sparse.find("D00-OVR overview:");
    auto pri = sparse.find("D00-PRI priority:");
    check("encode.order", ovr != std::string::npos &&
                              pri != std::string::npos && ovr < pri);
    check("encode.sparse", !contains(sparse, "D00-SCO"));
  }

  /* non-text values are plain scalars (SOM §12.5) */
  {
    som::SpecDocument doc2 = yamlPopulated();
    std::string yaml2 = yamlEnc(doc2, "");
    check("encode.plainEnum", contains(yaml2, "\n    D00-PRI priority: high\n"));
    check("encode.plainInt", contains(yaml2, "\n    count: 3\n"));
    check("encode.plainFormInt", contains(yaml2, "\n      revision: 7\n"));
  }

  /* YAML 1.1-special values are quoted, not plain (SOM §12.5). `on`/`no` are
   * 1.1-only booleans and `1:30` is a 1.1 sexagesimal int: plain strings under
   * YAML 1.2 but bool/number under YAML 1.1. They must emit as block scalars so
   * every runtime reads back the exact string; an ordinary token stays plain. */
  {
    som::SpecDocument special;
    for (const char* v : {"on", "no", "1:30", "plain"}) {
      special.setContent(special.addListItem("D00/D00-TAG"), v);
    }
    std::string yaml3 = yamlEnc(special, "");
    check("encode.yaml11.on", contains(yaml3, "\n      tags-1: |2-\n        on\n"));
    check("encode.yaml11.no", contains(yaml3, "\n      tags-2: |2-\n        no\n"));
    check("encode.yaml11.sexagesimal",
          contains(yaml3, "\n      tags-3: |2-\n        1:30\n"));
    check("encode.yaml11.plain", contains(yaml3, "\n      tags-4: plain\n"));
    som::SpecYamlContents rtSpecial = yamlRoundTrip(special);
    std::vector<std::string> stags = rtSpecial.document.listItems("D00/D00-TAG");
    check("encode.yaml11.roundTrip",
          stags.size() == 4 &&
              contentOr(rtSpecial.document, stags[0]) == "on" &&
              contentOr(rtSpecial.document, stags[1]) == "no" &&
              contentOr(rtSpecial.document, stags[2]) == "1:30" &&
              contentOr(rtSpecial.document, stags[3]) == "plain");
  }

  /* an empty document emits `document: {}` */
  {
    som::SpecDocument empty;
    std::string out = yamlEnc(empty, "");
    check("encode.emptyDoc", contains(out, "document: {}"));
    std::string out2 = yamlEnc(empty, "");
    check("encode.noStamp", !contains(out2, "modelVersion:"));
  }

  /* values the tree cannot place are a structured error */
  {
    som::SpecDocument ghost;
    ghost.setContent("D00/ghost", "x");
    std::string err;
    auto out = som::encodeYaml(ghost, *g_tree, "", &err);
    check("encode.leftoverError", !out.has_value() && !err.empty());
  }

  /* an unknown form field is a structured error */
  {
    som::SpecDocument bogus;
    bogus.setFormField("D00/D00-HDR", "bogus", "v");
    std::string err;
    auto out = som::encodeYaml(bogus, *g_tree, "", &err);
    check("encode.unknownFormField", !out.has_value() && !err.empty());
  }
}

/* A `@Form` node carries its own body text — the free text before its first
 * field (SOM §11.4 rule 7) — under the same literal `content` key every other
 * section uses (SOM §12.2); a form declaring a field literally named `content`
 * is a collision (SOM §12.3 rule 6). */
const char* kClashModelJson = R"({
  "modelVersion": 1,
  "roots": [{"type": "Clash", "title": "Clash", "sectionId": "C00"}],
  "classes": {
    "Clash": {
      "name": "Clash",
      "sectionId": "C00",
      "fields": [
        {"name": "header", "kind": "form", "sectionId": "C00-HDR",
         "serializationOrder": 0,
         "formFields": [{"name": "content", "label": "Content", "type": "String"}]}
      ]
    }
  }
})";

void yamlTestFormPreamble() {
  {
    som::SpecDocument doc;
    doc.setContent("D00/D00-HDR", "why this header exists");
    doc.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
    std::string yaml = yamlEnc(doc, "");
    // The reserved key sits above the fields, exactly as for a section.
    check("formPre.shape",
          contains(yaml,
                   "\n    D00-HDR header:\n"
                   "      content: |2-\n"
                   "        why this header exists\n"
                   "      author: |2-\n"
                   "        Ada Lovelace\n"),
          yaml);
  }

  {
    som::SpecDocument only;
    only.setContent("D00/D00-HDR", "nothing filled in yet");
    std::string yaml = yamlEnc(only, "");
    check("formPre.only",
          contains(yaml,
                   "\n    D00-HDR header:\n"
                   "      content: |2-\n"
                   "        nothing filled in yet\n"),
          yaml);
  }

  {
    som::SpecDocument multi;
    multi.setContent("D00/D00-HDR", "first paragraph\n\nsecond paragraph");
    multi.setFormField("D00/D00-HDR", "author", "Ada Lovelace");
    std::string yaml1 = yamlEnc(multi, "");
    som::SpecYamlContents rt = yamlDec(yaml1);
    const som::SpecDocument& out = rt.document;
    check("formPre.rtContent",
          contentOr(out, "D00/D00-HDR") == "first paragraph\n\nsecond paragraph",
          contentOr(out, "D00/D00-HDR"));
    check("formPre.rtField",
          formFieldOr(out, "D00/D00-HDR", "author") == "Ada Lovelace",
          formFieldOr(out, "D00/D00-HDR", "author"));
    check("formPre.byteStable", yamlEnc(out, "") == yaml1, yamlEnc(out, ""));
  }

  /* A form declaring a field literally named `content`: the field alone is
   * fine (a declared field wins on decode), the preamble beside it collides. */
  {
    std::string err;
    auto clashModel = som::SpecModel::fromJsonStr(kClashModelJson, &err);
    if (clashModel == nullptr) {
      fatal("clash model", err);
    }
    auto clashTree = som::somBuildMetaTree(*clashModel, "", &err);
    if (clashTree == nullptr) {
      fatal("clash tree", err);
    }

    som::SpecDocument fieldOnly;
    fieldOnly.setFormField("C00/C00-HDR", "content", "a field value");
    auto fieldYaml = som::encodeYaml(fieldOnly, *clashTree, "", &err);
    if (!fieldYaml.has_value()) {
      fatal("clash encode", err);
    }
    check("formPre.clashFieldOnly",
          contains(*fieldYaml, "      content: |2-\n        a field value\n"),
          *fieldYaml);
    som::SpecYamlContents decoded;
    if (!som::decodeYaml(*fieldYaml, *clashTree, &decoded, &err)) {
      fatal("clash decode", err);
    }
    check("formPre.clashFieldDecodes",
          formFieldOr(decoded.document, "C00/C00-HDR", "content") ==
              "a field value",
          formFieldOr(decoded.document, "C00/C00-HDR", "content"));

    som::SpecDocument withPreamble;
    withPreamble.setContent("C00/C00-HDR", "the preamble");
    withPreamble.setFormField("C00/C00-HDR", "content", "a field value");
    std::string clashErr;
    auto refused = som::encodeYaml(withPreamble, *clashTree, "", &clashErr);
    check("formPre.clashRefused",
          !refused.has_value() && contains(clashErr, "literally named"),
          clashErr);
  }
}

/* A complex field with no field-level @SectionId keys on its target class's
 * own @SectionId (SOM §12.2 class fallback); its id-less leaf keeps a bare key
 * while its own document path segment stays field-level (`control`). */
void yamlTestClassLevelOnlyKey() {
  som::SpecDocument doc;
  doc.setContent("D00/control/CTRL-SUM", "control summary");
  doc.setContent("D00/control/owner", "team alpha");
  std::string yaml = yamlEnc(doc, "");
  check("classKey.complexKey", contains(yaml, "\n    CTRL control:\n"), yaml);
  check("classKey.leafId", contains(yaml, "\n      CTRL-SUM summary: |2-\n"), yaml);
  check("classKey.leafBare", contains(yaml, "\n      owner: |2-\n"), yaml);
  som::SpecYamlContents rt = yamlRoundTrip(doc);
  check("classKey.roundTripSummary",
        contentOr(rt.document, "D00/control/CTRL-SUM") == "control summary");
  check("classKey.roundTripOwner",
        contentOr(rt.document, "D00/control/owner") == "team alpha");
}

void yamlTestRoundTrip() {
  som::SpecDocument populated = yamlPopulated();

  {
    som::SpecYamlContents rt = yamlRoundTrip(populated);
    const som::SpecDocument& out = rt.document;
    check("rt.root", contentOr(out, "D00") == "Preamble body text.");
    check("rt.overview",
          contentOr(out, "D00/D00-OVR") == "line one\nline two\nline three");
    check("rt.inScope", contentOr(out, "D00/D00-SCO/D00-INS") ==
                            "  indented first line\n    deeper");
    check("rt.outOfScope",
          contentOr(out, "D00/D00-SCO/outOfScope") == "ends with newline\n");
    check("rt.priority", contentOr(out, "D00/D00-PRI") == "high");
    check("rt.count", contentOr(out, "D00/count") == "3");
    check("rt.author",
          formFieldOr(out, "D00/D00-HDR", "author") == "Ada Lovelace");
    check("rt.reviewer",
          formFieldOr(out, "D00/D00-HDR", "reviewer") == "Grace Hopper");
    check("rt.revision", formFieldOr(out, "D00/D00-HDR", "revision") == "7");
    check("rt.reqCount", out.listItemCount("D00/D00-REQ") == 2);
    std::vector<std::string> items = out.listItems("D00/D00-REQ");
    check("rt.item0.id",
          items.size() == 2 && out.itemSectionId(items[0]) == "REQ-AB1");
    check("rt.item1.id",
          items.size() == 2 && out.itemSectionIdOpt(items[1]) == nullptr);
    if (items.size() == 2) {
      check("rt.item0.text", contentOr(out, items[0] + "/text") ==
                                 "value: with: colons # and hash");
      check("rt.item1.text",
            contentOr(out, items[1] + "/text") == "second requirement");
      std::vector<std::string> notes = out.listItems(items[0] + "/notes");
      check("rt.notes", notes.size() == 1 &&
                            contentOr(out, notes[0]) == "a nested scalar note");
    } else {
      check("rt.item0.text", false);
      check("rt.item1.text", false);
      check("rt.notes", false);
    }
    std::vector<std::string> tags = out.listItems("D00/D00-TAG");
    check("rt.tags",
          tags.size() == 1 && contentOr(out, tags[0]) == "alpha");
  }

  /* encode is byte-stable across decode → re-encode */
  {
    std::string yaml1 = yamlEnc(populated, "1.2");
    som::SpecYamlContents c1 = yamlDec(yaml1);
    std::string yaml2 = yamlEnc(c1.document, "1.2");
    check("rt.byteStable", yaml2 == yaml1);
  }

  /* the model-version stamp lands on the decoded document */
  {
    std::string yaml = yamlEnc(populated, "2.5");
    som::SpecYamlContents decoded = yamlDec(yaml);
    check("rt.stamp.contents", decoded.modelVersion == "2.5");
    check("rt.stamp.document", decoded.document.modelVersion == "2.5");
  }

  /* markdown edge cases survive */
  {
    const std::vector<std::string> cases = {
        "\nleading blank line",
        "trailing blank line kept as one\n\nend",
        "two trailing newlines\n\n",  // block cannot represent → JSON fallback
        "trailing space on a line \nnext",
        "\ttab\tpreserved",
        "- looks: like\n  yaml: [a, b]\n# comment-ish",
        "\"double\" and 'single' quotes",
        "ends with newline\n",
        "   only-indentation-sensitive\n      nested deeper\n   back",
    };
    for (std::size_t i = 0; i < cases.size(); ++i) {
      som::SpecDocument doc;
      doc.setContent("D00/D00-OVR", cases[i]);
      som::SpecYamlContents c = yamlRoundTrip(doc);
      std::string got = contentOr(c.document, "D00/D00-OVR");
      check(("rt.edge[" + std::to_string(i) + "]").c_str(), got == cases[i],
            got);
    }
  }

  /* runs of 2+ empty lines collapse to one on write (SOM §12.4) */
  {
    som::SpecDocument doc;
    doc.setContent("D00/D00-OVR", "a\n\n\n\nb\n\n\nc");
    som::SpecYamlContents c = yamlRoundTrip(doc);
    check("rt.emptyLineDedup",
          contentOr(c.document, "D00/D00-OVR") == "a\n\nb\n\nc");
  }

  /* an empty complex list item round-trips as `{}` */
  {
    som::SpecDocument emptyItem;
    emptyItem.addListItem("D00/D00-REQ");
    std::string yaml3 = yamlEnc(emptyItem, "");
    check("rt.emptyItem.enc", contains(yaml3, "requirements-1: {}"), yaml3);
    som::SpecYamlContents c = yamlRoundTrip(emptyItem);
    check("rt.emptyItem.count", c.document.listItemCount("D00/D00-REQ") == 1);
  }
}

/* Decodes expecting failure; reports whether an error containing `needle` was
 * produced. */
bool decodeFailsWith(const std::string& yaml, const std::string& needle) {
  som::SpecYamlContents c;
  std::string err;
  if (som::decodeYaml(yaml, *g_tree, &c, &err)) {
    return false;
  }
  return !err.empty() && (needle.empty() || contains(err, needle));
}

void yamlTestStrictDecode() {
  check("decode.v1Rejected",
        decodeFailsWith("version: 1\ndocument: {}\n", "version 1"));
  check("decode.missingVersion", decodeFailsWith("document: {}\n", ""));
  check("decode.emptyText", decodeFailsWith("", ""));
  check("decode.unmatchedKey",
        decodeFailsWith(
            "version: 2\ndocument:\n  D00 Demo:\n    nonsense: |-\n      x\n",
            "nonsense"));
  check("decode.wrongRoot",
        decodeFailsWith("version: 2\ndocument:\n  WRONG Other: {}\n", ""));
  check("decode.unknownFormField",
        decodeFailsWith("version: 2\ndocument:\n  D00 Demo:\n"
                        "    D00-HDR header:\n      bogus: |-\n        v\n",
                        ""));

  {
    som::SpecYamlContents c = yamlDec("version: 2\n");
    check("decode.noDocKey", c.document.isEmpty());
  }
  {
    som::SpecYamlContents c = yamlDec("version: 2\ndocument: {}\n");
    check("decode.emptyDoc", c.document.isEmpty());
  }

  {
    som::SpecYamlContents c = yamlDec(
        "version: 2\n"
        "document: {}\n"
        "review:\n"
        "  \"D00/a\":\n"
        "    scope: global\n");
    check("decode.review", som::yamlGet(c.review, "D00/a") != nullptr);
  }
}

/* ---- codespecs_mapping.md §9.2 codeSpec forward-link (mirror of stored headline) -------------- */

void yamlTestCodeSpecRoundTrip() {
  // csmc8 (codespecs_mapping.md §9.2): a stored codeSpec survives the yaml
  // round-trip.
  som::SpecDocument doc = yamlPopulated();
  doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total,CsOrderRepository");
  std::string yaml = yamlEnc(doc, "");
  check("codeSpec.yaml.emitted", contains(yaml, "codeSpec:"), yaml);
  som::SpecYamlContents rt = yamlRoundTrip(doc);
  check("codeSpec.yaml.restored",
        rt.document.codeSpec("D00/D00-OVR") ==
            "CsOrder,CsOrder.total,CsOrderRepository",
        rt.document.codeSpec("D00/D00-OVR"));
  // Sibling without codeSpec keeps no codeSpec entry.
  check("codeSpec.yaml.sibling",
        rt.document.codeSpecOpt("D00/D00-PRI") == nullptr,
        rt.document.codeSpec("D00/D00-PRI"));
}

void yamlTestCodeSpecByteStable() {
  // csmc8 (codespecs_mapping.md §9.2): encode is byte-stable with codeSpec
  // across decode → re-encode.
  som::SpecDocument doc = yamlPopulated();
  doc.setCodeSpec("D00/D00-OVR", "CsOrder,CsOrder.total");
  std::string yaml1 = yamlEnc(doc, "1.2");
  std::string err;
  som::SpecYamlContents c = yamlDec(yaml1);
  auto out = som::encodeYaml(c.document, *g_tree, "1.2", &err);
  if (!out.has_value()) {
    fatal("encode", err);
  }
  check("codeSpec.yaml.byteStable", *out == yaml1);
}

}  // namespace

int main() {
  std::string err;
  g_model = som::SpecModel::fromJsonStr(kModelJson, &err);
  if (g_model == nullptr) {
    fatal("model", err);
  }
  g_tree = som::somBuildMetaTree(*g_model, "", &err);
  if (g_tree == nullptr) {
    fatal("tree", err);
  }

  yamlTestEncode();
  yamlTestClassLevelOnlyKey();
  yamlTestFormPreamble();
  yamlTestRoundTrip();
  yamlTestStrictDecode();
  yamlTestCodeSpecRoundTrip();
  yamlTestCodeSpecByteStable();

  if (g_failures == 0) {
    std::printf("spec_document_yaml_test: %d checks passed\n", g_checks);
    return 0;
  }
  std::fprintf(stderr, "spec_document_yaml_test: %d/%d checks FAILED\n",
               g_failures, g_checks);
  return 1;
}
