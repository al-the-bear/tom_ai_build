/* The surface the TypeScript runtime has and this port lacked: SomScalar, the
 * SpecReflection lookups, SpecSerializationOrder::orderKey,
 * SpecModel::modelVersionString, systemReviewTime(now), extractAnswers on a
 * const document, and the YAML / Markdown helpers. The expected values are the
 * TypeScript runtime's output for the same inputs (the corpus model, and the
 * small model below). */
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "tom_som_cpp_runtime.hpp"

namespace {

std::size_t g_passed = 0;
std::vector<std::string> g_failed;

void check(const std::string& name, bool cond) {
  if (cond) {
    g_passed++;
  } else {
    g_failed.push_back(name);
  }
}

void checkEq(const std::string& name, const std::string& got,
             const std::string& want) {
  check(name + " (got <" + got + ">, want <" + want + ">)", got == want);
}

std::unique_ptr<som::SpecModel> modelFrom(const std::string& json) {
  std::string err;
  auto m = som::SpecModel::fromJsonStr(json, &err);
  if (!m) {
    std::fprintf(stderr, "fatal: model: %s\n", err.c_str());
    std::exit(2);
  }
  return m;
}

std::unique_ptr<som::SpecModel> corpusModel() {
  std::ifstream in("../tom_som_conformance/corpus/model.meta.json");
  if (!in) {
    std::fprintf(stderr, "fatal: cannot read the corpus model\n");
    std::exit(2);
  }
  std::stringstream ss;
  ss << in.rdbuf();
  return modelFrom(ss.str());
}

// Ordered members, an unordered one, and a complex list.
const char* kSmallModel =
    "{\"metaSchemaVersion\":1,\"modelVersion\":1,\"classCount\":2,"
    "\"rootCount\":1,"
    "\"roots\":[{\"type\":\"Demo\",\"title\":\"Demo\",\"sectionId\":\"DEMO\"}],"
    "\"classes\":{"
    "\"Demo\":{\"name\":\"Demo\",\"sectionId\":\"DEMO\",\"fields\":["
    "{\"name\":\"title\",\"kind\":\"content\",\"sectionId\":\"TTL\","
    "\"serializationOrder\":3},"
    "{\"name\":\"items\",\"kind\":\"list\",\"elementType\":\"Item\","
    "\"elementIsComplex\":true,\"serializationOrder\":1}]},"
    "\"Item\":{\"name\":\"Item\",\"fields\":["
    "{\"name\":\"label\",\"kind\":\"content\",\"serializationOrder\":0},"
    "{\"name\":\"note\",\"kind\":\"content\"}]}}}";

void testSomScalar() {
  som::SpecDocument doc;
  som::SomScalar item(doc, "DEMO/tags-0");
  checkEq("SomScalar unset", item.value(), "");
  item.setValue("alpha");
  checkEq("SomScalar value", item.value(), "alpha");
  checkEq("SomScalar writes the item path", doc.content("DEMO/tags-0"), "alpha");
  item.setValue("");
  check("SomScalar clears", doc.contentOpt("DEMO/tags-0") == nullptr);
}

void testReflection() {
  auto m = corpusModel();
  som::SpecReflection r(*m);
  check("roots", r.roots().size() == 2 && r.roots()[0].type == "Demo" &&
                     r.roots()[1].type == "Sidecar");
  // The model's order, not sorted.
  const std::vector<const som::SpecClass*> classes = r.classes();
  check("classes", classes.size() == 18 && classes[0]->name == "Demo" &&
                       classes[1]->name == "Registry" &&
                       classes[8]->name == "Sidecar" &&
                       classes.back()->name == "Meta");
  check("classNamed", r.classNamed("Demo") != nullptr);
  check("classNamed unknown", r.classNamed("Nope") == nullptr);

  const std::vector<std::string> wantFields = {
      "title", "summary", "priority", "count", "ratio",   "score",
      "details", "items", "refs",     "cards", "meta",    "control",
      "notes", "mixed",   "registry", "deliverables"};
  const std::vector<som::SpecField>& fields = r.fieldsOf("Demo");
  bool ok = fields.size() == wantFields.size();
  for (std::size_t i = 0; ok && i < fields.size(); i++) {
    ok = fields[i].name == wantFields[i];
  }
  check("fieldsOf", ok);
  check("fieldsOf unknown", r.fieldsOf("Nope").empty());

  const std::vector<som::SpecAnnotation>& anns = r.annotationsOf("Demo");
  check("annotationsOf", anns.size() == 3 && anns[0].name == "Document" &&
                             anns[1].name == "SectionId" &&
                             anns[2].name == "CodeSpecKind");
  check("annotationsOf unknown", r.annotationsOf("Nope").empty());
  const std::vector<som::SpecAnnotation>& fa =
      r.fieldAnnotations("Demo", "priority");
  check("fieldAnnotations", fa.size() == 1 && fa[0].name == "CodeSpecKind");
  check("fieldAnnotations unknown field",
        r.fieldAnnotations("Demo", "nope").empty());
  check("fieldAnnotations unknown class",
        r.fieldAnnotations("Nope", "title").empty());

  checkEq("modelVersionString", m->modelVersionString(), "1.0");
}

void testOrderKey() {
  auto m = modelFrom(kSmallModel);
  som::SpecSerializationOrder o(*m);
  using Key = std::vector<long long>;
  const long long fb = 1LL << 30;
  check("orderKey DEMO/TTL", o.orderKey("DEMO/TTL") == Key{3});
  check("orderKey DEMO/items", o.orderKey("DEMO/items") == Key{1});
  check("orderKey DEMO/items-4", o.orderKey("DEMO/items-4") == Key{1, 4});
  check("orderKey DEMO/items-4/label",
        o.orderKey("DEMO/items-4/label") == Key{1, 4, 0});
  check("orderKey DEMO/items-4/note",
        o.orderKey("DEMO/items-4/note") == Key{1, 4, fb});
  check("orderKey DEMO/nope", o.orderKey("DEMO/nope").empty());
  check("orderKey NOPE/x", o.orderKey("NOPE/x").empty());
}

void testReviewTime() {
  setenv("TZ", "UTC", 1);
  tzset();
  checkEq("systemReviewTime(0) in UTC", som::systemReviewTime(std::time_t{0}),
          "1970-01-01T00:00+00:00");
  setenv("TZ", "Europe/Berlin", 1);
  tzset();
  checkEq("systemReviewTime in Berlin",
          som::systemReviewTime(std::time_t{1700000000}),
          "2023-11-14T23:13+01:00");
  check("systemReviewTime() is a review time",
        som::isReviewTime(som::systemReviewTime()));
}

void testExtractAnswersConst() {
  auto m = corpusModel();
  som::SpecDocument doc;
  doc.setContent("DEMO/TTL", "Hello");
  const som::SpecDocument& ro = doc;
  const som::SpecAnswerExtract x = som::extractAnswers(*m, ro, "demo");
  check("extractAnswers on a const document", x.entries.empty());
  checkEq("extractAnswers leaves the document", doc.content("DEMO/TTL"),
          "Hello");
}

void testYamlAndMarkdownHelpers() {
  checkEq("specYamlKey", som::specYamlKey("a b"), "\"a b\"");
  checkEq("specYamlKey escapes", som::specYamlKey("q\"\n"), "\"q\\\"\\n\"");
  std::string out;
  som::specYamlWriteHeader(out, "1.2.3");
  som::specYamlWriteHeader(out, "");
  checkEq("specYamlWriteHeader", out,
          "# TomSpecs document (*.tomspecs.yaml). Hierarchical format v2.\n"
          "version: 2\nmodelVersion: \"1.2.3\"\n"
          "# TomSpecs document (*.tomspecs.yaml). Hierarchical format v2.\n"
          "version: 2\n");
  checkEq("markdownCodeSpecOf",
          som::markdownCodeSpecOf("sectionId=\"X\" codeSpec=\" a,b \""), "a,b");
  checkEq("markdownCodeSpecOf absent",
          som::markdownCodeSpecOf("sectionId=\"X\""), "");
  checkEq("markdownUnitsOf", som::markdownUnitsOf("units='server,web'"),
          "server,web");
  checkEq("markdownUnitsOf inside codeSpec",
          som::markdownUnitsOf("codeSpec=\"units=x\""), "");
}

void testTypedReview() {
  // A review entry as a file holds it: plain scalars stay source text in the
  // parsed pass, and specYamlTypedReview reads them as TS and Dart do.
  som::YamlPtr parsed = som::yamlParseMap(
      "\"DEMO/TTL\":\n  a: true\n  b: 3.0\n  c: 0x1F\n  d: ~\n  e: keep\n"
      "  f: |2-\n    true\n  g: 1e400\n  h: [1, \"x\"]\n");
  som::JsonPtr typed = som::specYamlTypedReview(*parsed);
  check("typed review is a map", typed->type == som::JsonType::Object &&
                                     typed->object.size() == 1);
  const som::Json& e = *typed->object[0].second;
  auto at = [&e](const std::string& k) -> const som::Json& {
    for (const auto& kv : e.object) {
      if (kv.first == k) return *kv.second;
    }
    static const som::Json none(som::JsonType::Null);
    return none;
  };
  check("bool", at("a").type == som::JsonType::Bool && at("a").boolean);
  check("whole float stays float", at("b").type == som::JsonType::Float);
  check("hex int", at("c").type == som::JsonType::Int && at("c").integer == 31);
  check("tilde null", at("d").type == som::JsonType::Null);
  check("plain string", at("e").type == som::JsonType::Str && at("e").str == "keep");
  check("block stays a string", at("f").type == som::JsonType::Str && at("f").str == "true");
  check("overflow is an infinite float",
        at("g").type == som::JsonType::Float && std::isinf(at("g").real));
  check("flow list", at("h").type == som::JsonType::Array && at("h").array.size() == 2);

  checkEq("reviewScalar float", som::specYamlReviewScalar(at("b")), "3.0");
  checkEq("reviewScalar inf", som::specYamlReviewScalar(at("g")), ".inf");
  checkEq("reviewScalar int", som::specYamlReviewScalar(at("c")), "31");
  checkEq("reviewScalar bool", som::specYamlReviewScalar(at("a")), "true");
  checkEq("reviewScalar null", som::specYamlReviewScalar(at("d")), "null");
  checkEq("reviewScalar list", som::specYamlReviewScalar(at("h")), "[1,\"x\"]");
  checkEq("formatYamlFloat", som::specYamlFormatYamlFloat(1e21), "1e+21");
  checkEq("formatYamlFloat nan", som::specYamlFormatYamlFloat(std::nan("")), ".nan");

  // Writing the typed pass back gives what writing the parsed pass gives.
  std::string fromParsed;
  som::specYamlWriteReviewPass(fromParsed, *parsed);
  std::string fromTyped;
  som::specYamlWriteTypedReviewPass(fromTyped, *typed);
  checkEq("typed pass writes back the same", fromTyped, fromParsed);
  std::string empty;
  som::specYamlWriteTypedReviewPass(empty, som::Json(som::JsonType::Object));
  checkEq("empty typed pass", empty, "review: {}\n");
}

}  // namespace

int main() {
  testSomScalar();
  testReflection();
  testOrderKey();
  testReviewTime();
  testExtractAnswersConst();
  testYamlAndMarkdownHelpers();
  testTypedReview();
  if (g_failed.empty()) {
    std::printf("public_accessors_test: all %zu checks passed.\n", g_passed);
    return 0;
  }
  std::fprintf(stderr, "public_accessors_test: %zu of %zu checks FAILED\n",
               g_failed.size(), g_passed + g_failed.size());
  for (const std::string& f : g_failed) {
    std::fprintf(stderr, "  - %s\n", f.c_str());
  }
  return 1;
}
