/* Shared-corpus conformance suite for the C++ generic runtime
 * (`tom_som_cpp_runtime`), an idiomatic-C++ port of the C `tests/conformance.c`.
 *
 * It loads the language-agnostic conformance corpus produced from the Dart
 * reference (`tom_som_conformance/corpus`) and asserts the C++ port reproduces
 * every golden byte-for-byte and matches every behavioural case:
 *   - model meta-data loads (root + class structure);
 *   - state.json loads and re-serialises identically;
 *   - YAML encode == expected.docspecs.yaml (byte-for-byte);
 *   - YAML decode -> memory -> encode is byte-stable + preserves the stamp;
 *   - Markdown export == expected.md (byte-for-byte);
 *   - Markdown parse -> memory -> export is clean + byte-stable;
 *   - the Markdown route lands the fixture in the same memory as the YAML route;
 *   - reflection resolution cases;
 *   - validation cases;
 *   - the imperative operations script.
 *
 * The corpus directory is argv[1], defaulting to
 * "../tom_som_conformance/corpus" relative to the runner's cwd. Exit 0 == all
 * green; non-zero on the first failed group of checks.
 */
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "tom_som_cpp_runtime.hpp"

#define MODEL_VERSION "1.0"

static std::string g_corpus_dir = "../tom_som_conformance/corpus";

/* ---- corpus IO ---------------------------------------------------------- */

static std::string read_corpus(const std::string& name) {
  std::string path = g_corpus_dir + "/" + name;
  std::ifstream f(path, std::ios::binary);
  if (!f) {
    std::fprintf(stderr, "read corpus %s: cannot open\n", path.c_str());
    std::exit(2);
  }
  std::ostringstream ss;
  ss << f.rdbuf();
  return ss.str();
}

static som::JsonPtr read_json(const std::string& name) {
  std::string text = read_corpus(name);
  std::string err;
  som::JsonPtr v = som::jsonParse(text, &err);
  if (v == nullptr) {
    std::fprintf(stderr, "parse corpus %s: %s\n", name.c_str(), err.c_str());
    std::exit(2);
  }
  return v;
}

/* ---- Checker ------------------------------------------------------------ */

class Checker {
 public:
  std::size_t passed = 0;
  std::vector<std::string> failed;

  void check(const std::string& name, bool cond, const std::string& detail) {
    if (cond) {
      passed++;
      return;
    }
    if (detail.empty()) {
      failed.push_back(name);
    } else {
      failed.push_back(name + ": " + detail);
    }
  }

  int finish() {
    std::size_t total = passed + failed.size();
    if (!failed.empty()) {
      for (const std::string& f : failed) {
        std::fprintf(stderr, "  - %s\n", f.c_str());
      }
      std::fprintf(stderr, "FAIL: %zu/%zu checks failed\n", failed.size(), total);
      return 1;
    }
    std::printf("OK: %zu checks passed\n", total);
    return 0;
  }
};

/* ---- helpers ------------------------------------------------------------ */

static std::string byte_diff(const std::string& label, const std::string& actual,
                             const std::string& expected) {
  if (actual == expected) {
    return "";
  }
  std::size_t ai = 0, ei = 0, line = 1;
  while (true) {
    std::size_t as = ai, es = ei;
    while (ai < actual.size() && actual[ai] != '\n') ai++;
    while (ei < expected.size() && expected[ei] != '\n') ei++;
    std::size_t alen = ai - as, elen = ei - es;
    if (alen != elen || actual.compare(as, alen, expected, es, elen) != 0) {
      std::string got = actual.substr(as, alen);
      std::string want = expected.substr(es, elen);
      return label + ": first diff at line " + std::to_string(line) + ": got \"" +
             got + "\" want \"" + want + "\"";
    }
    bool aEnd = ai >= actual.size();
    bool eEnd = ei >= expected.size();
    if (aEnd && eEnd) break;
    if (ai < actual.size() && actual[ai] == '\n') ai++;
    if (ei < expected.size() && expected[ei] == '\n') ei++;
    line++;
  }
  return label + ": differ (len got " + std::to_string(actual.size()) +
         " want " + std::to_string(expected.size()) + ")";
}

static std::unique_ptr<som::SpecModel> load_model() {
  std::string text = read_corpus("model.meta.json");
  std::string err;
  auto m = som::SpecModel::fromJsonStr(text, &err);
  if (m == nullptr) {
    std::fprintf(stderr, "load model: %s\n", err.c_str());
    std::exit(2);
  }
  return m;
}

static som::SpecDocument doc_from_state(const som::DocumentJson& state) {
  som::SpecDocument doc;
  doc.loadJson(state);
  return doc;
}

/* ---- groups ------------------------------------------------------------- */

static void test_model_meta(Checker& c, const som::SpecModel& model) {
  const som::SpecRoot& root = model.roots[0];
  c.check("model.root.sectionId", root.sectionId == "DEMO", root.sectionId);
  c.check("model.root.type", root.type == "Demo", root.type);
  c.check("model.classCount", model.classesSize() == 11,
          std::to_string(model.classesSize()));
  const som::SpecClass* demo = model.classNamed("Demo");
  c.check("model.Demo.found", demo != nullptr, "");
  if (demo != nullptr) {
    const char* want[] = {"title",   "summary", "priority", "count",
                          "details", "items",   "refs",     "cards",
                          "meta",    "control", "registry"};
    bool ok = demo->fields.size() == 11;
    std::string names;
    for (std::size_t i = 0; i < demo->fields.size(); i++) {
      if (i > 0) names.push_back(',');
      names += demo->fields[i].name;
      if (ok && i < 11 && demo->fields[i].name != want[i]) ok = false;
    }
    c.check("model.Demo.fields", ok, names);
  }
}

/* Reads an optional integer under `key` — absent stays absent, so that a
 * declared count of zero is distinguishable from no declaration at all. */
static std::optional<long long> opt_i64(const som::JsonRef& v,
                                        const char* key) {
  return som::jsonAsI64(som::jsonGet(v, key));
}

/* The generation stamp: the five keys the exporter writes, and the staleness
 * verdict every runtime must reach from the same input. */
static void test_stamp(Checker& c, const som::SpecModel& model) {
  /* The shared model fixture carries the stamp, minus `containerRoot` (it is a
   * single synthetic document with no container class). */
  c.check("stamp.meta.generatedAt", model.generatedAt == 1784534400LL, "");
  c.check("stamp.meta.metaSchemaVersion", model.metaSchemaVersion == 1, "");
  c.check("stamp.meta.classCount",
          model.classCount ==
              std::optional<long long>(
                  static_cast<long long>(model.classesSize())),
          "");
  c.check("stamp.meta.rootCount",
          model.rootCount == std::optional<long long>(
                                 static_cast<long long>(model.roots.size())),
          "");
  c.check("stamp.meta.containerRoot", model.containerRoot.empty(),
          model.containerRoot);

  som::JsonPtr table = read_json("stamp_cases.json");
  c.check("stamp.defaultMaxAgeDays",
          opt_i64(table, "defaultMaxAgeDays") ==
              std::optional<long long>(som::kDefaultMaxSnapshotAgeSeconds /
                                       som::kSecondsPerDay),
          "");

  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    std::string name = som::jsonStrOr(kase, "name");
    auto loaded = som::SpecModel::fromJson(som::jsonGet(kase, "model"));
    som::JsonRef want = som::jsonGet(kase, "expect");
    const std::string prefix = "stamp[" + name + "].";

    c.check(prefix + "generatedAt",
            loaded->generatedAt == opt_i64(want, "generatedAtEpochSeconds"), "");
    c.check(prefix + "metaSchemaVersion",
            loaded->metaSchemaVersion == opt_i64(want, "metaSchemaVersion"), "");
    c.check(prefix + "classCount",
            loaded->classCount == opt_i64(want, "classCount"), "");
    c.check(prefix + "rootCount",
            loaded->rootCount == opt_i64(want, "rootCount"), "");
    c.check(prefix + "containerRoot",
            loaded->containerRoot == som::jsonStrOr(want, "containerRoot"),
            loaded->containerRoot);
    c.check(prefix + "actualClassCount",
            std::optional<long long>(
                static_cast<long long>(loaded->classesSize())) ==
                opt_i64(want, "actualClassCount"),
            "");
    c.check(prefix + "actualRootCount",
            std::optional<long long>(
                static_cast<long long>(loaded->roots.size())) ==
                opt_i64(want, "actualRootCount"),
            "");

    som::JsonRef wc = som::jsonGet(kase, "check");
    som::SpecModelStampCheck got = loaded->checkStamp(
        opt_i64(wc, "maxAgeDays").value_or(0) * som::kSecondsPerDay,
        opt_i64(wc, "nowEpochSeconds").value_or(0));

    c.check(prefix + "ageSeconds", got.ageSeconds == opt_i64(wc, "ageSeconds"),
            "");
    const std::pair<const char*, bool> verdicts[] = {
        {"isAged", got.isAged()},
        {"classCountDisagrees", got.classCountDisagrees()},
        {"rootCountDisagrees", got.rootCountDisagrees()},
        {"countsDisagree", got.countsDisagree()},
        {"isStale", got.isStale()}};
    for (const auto& v : verdicts) {
      c.check(prefix + v.first, v.second == som::jsonBoolOr(wc, v.first), "");
    }

    std::vector<std::string> gotWarnings = got.warnings();
    std::vector<std::string> wantWarnings;
    som::JsonRef warnArr = som::jsonGet(wc, "warnings");
    std::size_t wn = som::jsonArrayLen(warnArr);
    for (std::size_t w = 0; w < wn; w++) {
      const std::string* s = som::jsonAsStr(som::jsonArrayAt(warnArr, w));
      wantWarnings.push_back(s != nullptr ? *s : std::string());
    }
    std::string joined;
    for (std::size_t w = 0; w < gotWarnings.size(); w++) {
      if (w > 0) joined += " | ";
      joined += gotWarnings[w];
    }
    c.check(prefix + "warnings", gotWarnings == wantWarnings, joined);
  }
}

static void test_state_round_trip(Checker& c) {
  som::JsonPtr sj = read_json("state.json");
  som::DocumentJson state = som::documentJsonFromJson(sj);
  som::SpecDocument doc = doc_from_state(state);
  som::DocumentJson dj = doc.toJson();
  std::string got = som::documentJsonToCanonicalJson(dj);
  std::string want = som::documentJsonToCanonicalJson(state);
  c.check("state.toJson", got == want, "got " + got + " want " + want);
}

static void test_yaml_encode(Checker& c, const som::SomMetaTree& tree) {
  som::JsonPtr sj = read_json("state.json");
  som::DocumentJson state = som::documentJsonFromJson(sj);
  som::SpecDocument doc = doc_from_state(state);
  std::string expected = read_corpus("expected.docspecs.yaml");
  std::string err;
  auto actual = som::encodeYaml(doc, tree, MODEL_VERSION, &err);
  if (!actual.has_value()) {
    c.check("yaml.encode", false, err.empty() ? "(no message)" : err);
    return;
  }
  c.check("yaml.encode", *actual == expected,
          byte_diff("yaml.encode", *actual, expected));
}

static void test_yaml_decode_round_trip(Checker& c, const som::SomMetaTree& tree) {
  std::string expected = read_corpus("expected.docspecs.yaml");
  som::SpecYamlContents contents;
  std::string err;
  if (!som::decodeYaml(expected, tree, &contents, &err)) {
    c.check("yaml.decode.stamp", false, err.empty() ? "(no message)" : err);
    return;
  }
  c.check("yaml.decode.stamp", contents.modelVersion == MODEL_VERSION,
          contents.modelVersion);

  /* The decoded memory equals the canonical state (the hierarchical decode
   * lands the same sparse stores state.json describes). */
  {
    som::JsonPtr sj = read_json("state.json");
    som::DocumentJson canonical = som::documentJsonFromJson(sj);
    som::DocumentJson dj = contents.document.toJson();
    std::string got = som::documentJsonToCanonicalJson(dj);
    std::string want = som::documentJsonToCanonicalJson(canonical);
    c.check("yaml.decode.memory", got == want, "got " + got + " want " + want);
  }

  std::string stamp =
      contents.modelVersion.empty() ? std::string(MODEL_VERSION) : contents.modelVersion;
  std::string err2;
  auto actual = som::encodeYaml(contents.document, tree, stamp, &err2);
  if (!actual.has_value()) {
    c.check("yaml.decode.reencode", false, err2.empty() ? "(no message)" : err2);
    return;
  }
  c.check("yaml.decode.reencode", *actual == expected,
          byte_diff("yaml.decode.reencode", *actual, expected));
}

static void test_markdown_export(Checker& c, const som::SpecModel& model) {
  som::JsonPtr sj = read_json("state.json");
  som::DocumentJson state = som::documentJsonFromJson(sj);
  som::SpecDocument doc = doc_from_state(state);
  std::string expected = read_corpus("expected.md");
  std::string actual = som::markdownExportRoot(model, doc, model.roots[0]);
  c.check("md.export", actual == expected,
          byte_diff("md.export", actual, expected));
}

static std::string rej_str(const som::SpecMarkdownResult& r) {
  std::string b;
  for (std::size_t i = 0; i < r.rejections.size(); i++) {
    if (i > 0) b += "; ";
    b += r.rejections[i].display();
  }
  return b;
}

static void test_markdown_round_trip(Checker& c, const som::SpecModel& model) {
  std::string expected = read_corpus("expected.md");
  som::SpecMarkdownResult result = som::markdownParse(model, expected);
  c.check("md.parse.clean", result.isClean(), rej_str(result));
  som::SpecDocument applied;
  applied.loadJson(result.document());
  std::string actual = som::markdownExportRoot(model, applied, model.roots[0]);
  c.check("md.parse.reexport", actual == expected,
          byte_diff("md.parse.reexport", actual, expected));

  /* YRD3: the shared sample's stored list-item id and headline round-trip
   * through md. */
  std::string sid = applied.itemSectionId("DEMO/REF-LST-1");
  c.check("md.parse.storedId", sid == "REF-SPEC", sid);
  std::string hl = applied.headline("DEMO/REF-LST-1");
  c.check("md.parse.headline", hl == "Reference to the Spec", hl);
}

static void test_markdown_memory_landing(Checker& c, const som::SpecModel& model) {
  std::string expected_md = read_corpus("expected.md");
  som::JsonPtr sj = read_json("state.json");
  som::DocumentJson canonical = som::documentJsonFromJson(sj);
  som::SpecMarkdownResult result = som::markdownParse(model, expected_md);
  c.check("md.land.clean", result.isClean(), rej_str(result));
  som::SpecDocument landed;
  landed.loadJson(result.document());
  som::DocumentJson dj = landed.toJson();
  std::string got = som::documentJsonToCanonicalJson(dj);
  std::string want = som::documentJsonToCanonicalJson(canonical);
  c.check("md.land.memory", got == want, "got " + got + " want " + want);
}

static void test_reflection(Checker& c, const som::SpecModel& model) {
  som::SpecReflection refl(model);
  som::JsonPtr cases = read_json("reflection_cases.json");
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef cc = som::jsonArrayAt(cases, i);
    std::string path = som::jsonStrOr(cc, "path");
    bool resolves = som::jsonBoolOr(cc, "resolves");
    auto res = refl.resolve(path);
    bool ok = res.has_value();
    if (!resolves) {
      c.check("reflect[" + path + "].none", !ok, "expected no resolution");
      continue;
    }
    if (!ok) {
      c.check("reflect[" + path + "].some", false, "expected resolution, got nil");
      continue;
    }

    std::string want_kind = som::jsonStrOr(cc, "kind");
    c.check("reflect[" + path + "].kind", res->kind == want_kind,
            res->kind + " != " + want_kind);

    std::string field_name = res->field != nullptr ? res->field->name : "";
    const std::string* want_field = som::jsonAsStr(som::jsonGet(cc, "field"));
    bool field_eq = (want_field == nullptr) ? field_name.empty()
                                            : (field_name == *want_field);
    c.check("reflect[" + path + "].field", field_eq, field_name);

    std::string target =
        res->targetClass != nullptr ? res->targetClass->name : "";
    const std::string* want_target =
        som::jsonAsStr(som::jsonGet(cc, "targetClass"));
    bool target_eq = (want_target == nullptr) ? target.empty()
                                              : (target == *want_target);
    c.check("reflect[" + path + "].target", target_eq, target);

    c.check("reflect[" + path + "].leaf",
            res->isValueLeaf() == som::jsonBoolOr(cc, "isValueLeaf"), "");
  }
}

static void test_validation(Checker& c, const som::SpecModel& model) {
  som::JsonPtr cases = read_json("validation_cases.json");
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef cc = som::jsonArrayAt(cases, i);
    std::string name = som::jsonStrOr(cc, "name");
    som::DocumentJson state = som::documentJsonFromJson(som::jsonGet(cc, "state"));
    som::SpecDocument doc = doc_from_state(state);
    auto errs = som::validateDocument(model, doc);

    std::string got_s;
    for (std::size_t e = 0; e < errs.size(); e++) {
      if (e > 0) got_s.push_back('|');
      got_s += errs[e].path;
      got_s.push_back(':');
      got_s += errs[e].code;
    }

    std::string want_s;
    som::JsonRef warr = som::jsonGet(cc, "errors");
    std::size_t wlen = som::jsonArrayLen(warr);
    for (std::size_t e = 0; e < wlen; e++) {
      som::JsonRef we = som::jsonArrayAt(warr, e);
      if (e > 0) want_s.push_back('|');
      want_s += som::jsonStrOr(we, "path");
      want_s.push_back(':');
      want_s += som::jsonStrOr(we, "code");
    }

    c.check("validate[" + name + "]", got_s == want_s, got_s + " != " + want_s);
  }
}

static void test_operations(Checker& c) {
  som::SpecDocument doc;
  som::JsonPtr cases = read_json("operations_cases.json");
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef op = som::jsonArrayAt(cases, i);
    std::string op_name = som::jsonStrOr(op, "op");
    std::string tag = "op[" + std::to_string(i) + "]." + op_name;

    if (op_name == "isEmpty") {
      bool exp = som::jsonBoolOr(op, "expect");
      c.check(tag, doc.isEmpty() == exp, "");
    } else if (op_name == "setContent") {
      doc.setContent(som::jsonStrOr(op, "path"), som::jsonStrOr(op, "value"));
    } else if (op_name == "content") {
      const std::string* val = doc.contentOpt(som::jsonStrOr(op, "path"));
      const std::string* exp = som::jsonAsStr(som::jsonGet(op, "expect"));
      if (exp == nullptr) {
        c.check(tag, val == nullptr, "expected unset");
      } else {
        c.check(tag, val != nullptr && *val == *exp, val ? *val : "");
      }
    } else if (op_name == "setFormField") {
      doc.setFormField(som::jsonStrOr(op, "path"), som::jsonStrOr(op, "field"),
                       som::jsonStrOr(op, "value"));
    } else if (op_name == "formField") {
      const std::string* val = doc.formFieldOpt(som::jsonStrOr(op, "path"),
                                                som::jsonStrOr(op, "field"));
      const std::string* exp = som::jsonAsStr(som::jsonGet(op, "expect"));
      if (exp == nullptr) {
        c.check(tag, val == nullptr, "expected unset");
      } else {
        c.check(tag, val != nullptr && *val == *exp, val ? *val : "");
      }
    } else if (op_name == "addListItem") {
      std::string exp = som::jsonStrOr(op, "expect");
      std::string got = doc.addListItem(som::jsonStrOr(op, "listPath"));
      c.check(tag, got == exp, got + " != " + exp);
    } else if (op_name == "listItems") {
      std::vector<std::string> got =
          doc.listItems(som::jsonStrOr(op, "listPath"));
      std::string got_s;
      for (std::size_t k = 0; k < got.size(); k++) {
        if (k > 0) got_s.push_back(',');
        got_s += got[k];
      }
      som::JsonRef arr = som::jsonGet(op, "expect");
      std::string want_s;
      std::size_t alen = som::jsonArrayLen(arr);
      for (std::size_t k = 0; k < alen; k++) {
        if (k > 0) want_s.push_back(',');
        const std::string* s = som::jsonAsStr(som::jsonArrayAt(arr, k));
        if (s != nullptr) want_s += *s;
      }
      c.check(tag, got_s == want_s, got_s);
    } else if (op_name == "listItemCount") {
      auto exp = som::jsonAsI64(som::jsonGet(op, "expect"));
      std::size_t got = doc.listItemCount(som::jsonStrOr(op, "listPath"));
      c.check(tag, got == static_cast<std::size_t>(exp.value_or(0)),
              std::to_string(got));
    } else if (op_name == "hasValuesUnder") {
      bool exp = som::jsonBoolOr(op, "expect");
      c.check(tag, doc.hasValuesUnder(som::jsonStrOr(op, "prefix")) == exp, "");
    } else if (op_name == "removeListItem") {
      bool exp = som::jsonBoolOr(op, "expect");
      c.check(tag, doc.removeListItem(som::jsonStrOr(op, "itemPath")) == exp, "");
    } else if (op_name == "setHeadline") {
      doc.setHeadline(som::jsonStrOr(op, "path"), som::jsonStrOr(op, "value"));
    } else if (op_name == "headline") {
      const std::string* val = doc.headlineOpt(som::jsonStrOr(op, "path"));
      const std::string* exp = som::jsonAsStr(som::jsonGet(op, "expect"));
      if (exp == nullptr) {
        c.check(tag, val == nullptr, "expected unset");
      } else {
        c.check(tag, val != nullptr && *val == *exp, val ? *val : "");
      }
    } else {
      c.check(tag + ".unknown", false, op_name);
    }
  }
}

/* A JSON string array as a vector; non-string / missing entries drop out. */
static std::vector<std::string> json_str_list(const som::JsonRef& arr) {
  std::vector<std::string> out;
  std::size_t n = som::jsonArrayLen(arr);
  for (std::size_t i = 0; i < n; i++) {
    const std::string* s = som::jsonAsStr(som::jsonArrayAt(arr, i));
    if (s != nullptr) {
      out.push_back(*s);
    }
  }
  return out;
}

static std::string join(const std::vector<std::string>& v) {
  std::string s;
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) s.push_back(',');
    s += v[i];
  }
  return s;
}

/* ---- section-id conformance (AA1 criteria 3–6) -------------------------- */

static void test_section_id(Checker& c) {
  som::JsonPtr cases = read_json("section_id_cases.json");

  // Criterion 4: the two-letter day code.
  som::JsonRef tld = som::jsonGet(cases, "twoLetterDate");
  std::size_t tn = som::jsonArrayLen(tld);
  for (std::size_t i = 0; i < tn; i++) {
    som::JsonRef tc = som::jsonArrayAt(tld, i);
    long long month = som::jsonAsI64(som::jsonGet(tc, "month")).value_or(0);
    long long day = som::jsonAsI64(som::jsonGet(tc, "day")).value_or(0);
    std::string expect = som::jsonStrOr(tc, "expect");
    std::string got = som::specEncodeTwoLetterDate(month, day);
    c.check("sectionId.twoLetterDate[" + std::to_string(month) + "/" +
                std::to_string(day) + "]",
            got == expect, got + " != " + expect);
  }

  // Criteria 3 & 6: generated id = prefix + day + (max-for-day + 1).
  som::JsonRef gen = som::jsonGet(cases, "generate");
  std::size_t gn = som::jsonArrayLen(gen);
  for (std::size_t i = 0; i < gn; i++) {
    som::JsonRef tc = som::jsonArrayAt(gen, i);
    std::string pattern = som::jsonStrOr(tc, "pattern");
    long long month = som::jsonAsI64(som::jsonGet(tc, "month")).value_or(0);
    long long day = som::jsonAsI64(som::jsonGet(tc, "day")).value_or(0);
    std::vector<std::string> existing = json_str_list(som::jsonGet(tc, "existing"));
    std::string expect = som::jsonStrOr(tc, "expect");
    std::string got =
        som::specGenerateListItemSectionId(pattern, month, day, existing);
    c.check("sectionId.generate[" + pattern + "]", got == expect,
            got + " != " + expect);
  }

  // Criteria 5 & 6 at the document level.
  som::SpecDocument doc;
  som::JsonRef ops = som::jsonGet(cases, "documentOps");
  std::size_t on = som::jsonArrayLen(ops);
  for (std::size_t i = 0; i < on; i++) {
    som::JsonRef s = som::jsonArrayAt(ops, i);
    std::string op = som::jsonStrOr(s, "op");
    std::string tag = "sectionId.op[" + std::to_string(i) + "]." + op;

    if (op == "addGen") {
      std::string listPath = som::jsonStrOr(s, "listPath");
      std::string pattern = som::jsonStrOr(s, "pattern");
      long long month = som::jsonAsI64(som::jsonGet(s, "month")).value_or(0);
      long long day = som::jsonAsI64(som::jsonGet(s, "day")).value_or(0);
      std::string expectId = som::jsonStrOr(s, "expectId");
      std::string expectPath = som::jsonStrOr(s, "expectPath");
      std::vector<std::string> existing = doc.listItemSectionIds(listPath);
      std::string genId =
          som::specGenerateListItemSectionId(pattern, month, day, existing);
      c.check(tag + ".id", genId == expectId, genId + " != " + expectId);
      try {
        std::string path = doc.addListItemWithSectionId(listPath, genId);
        c.check(tag + ".path", path == expectPath, path + " != " + expectPath);
      } catch (const som::SomSectionIdError&) {
        c.check(tag + ".path", false, "unexpected add failure");
      }
    } else if (op == "sectionIds") {
      std::vector<std::string> exp = json_str_list(som::jsonGet(s, "expect"));
      std::vector<std::string> got =
          doc.listItemSectionIds(som::jsonStrOr(s, "listPath"));
      c.check(tag, got == exp, join(got));
    } else if (op == "removeListItem") {
      bool exp = som::jsonBoolOr(s, "expect");
      c.check(tag, doc.removeListItem(som::jsonStrOr(s, "itemPath")) == exp, "");
    } else if (op == "override") {
      bool okv = true;
      try {
        doc.setItemSectionId(som::jsonStrOr(s, "itemPath"),
                             som::jsonStrOr(s, "id"));
      } catch (const som::SomSectionIdError&) {
        okv = false;
      }
      c.check(tag, okv, "unexpected error");
    } else if (op == "overrideThrows") {
      bool collided = false;
      try {
        doc.setItemSectionId(som::jsonStrOr(s, "itemPath"),
                             som::jsonStrOr(s, "id"));
      } catch (const som::SomSectionIdError& e) {
        collided = e.isCollision();
      }
      c.check(tag, collided, "expected collision");
    } else if (op == "addExplicitThrows") {
      bool collided = false;
      try {
        doc.addListItemWithSectionId(som::jsonStrOr(s, "listPath"),
                                     som::jsonStrOr(s, "id"));
      } catch (const som::SomSectionIdError& e) {
        collided = e.isCollision();
      }
      c.check(tag, collided, "expected collision");
    } else {
      c.check(tag + ".unknown", false, op);
    }
  }
}

/* ---- serialization-order conformance (AA1 criterion 7) ------------------ */

static void test_serialization_order(Checker& c) {
  som::JsonPtr cases = read_json("serialization_order_cases.json");
  auto model = som::SpecModel::fromJson(som::jsonGet(cases, "model"));
  c.check("serialOrder.model", model != nullptr, "model failed to build");
  if (model == nullptr) {
    return;
  }
  som::SpecSerializationOrder order(*model);

  std::vector<std::string> contentPaths =
      json_str_list(som::jsonGet(cases, "contentPaths"));
  std::vector<std::string> expectedOrder =
      json_str_list(som::jsonGet(cases, "expectedOrder"));
  std::vector<std::string> gotPaths = order.orderPaths(contentPaths);
  c.check("serialOrder.orderPaths", gotPaths == expectedOrder,
          join(gotPaths) + " != " + join(expectedOrder));

  std::vector<std::string> formFields =
      json_str_list(som::jsonGet(cases, "formFields"));
  std::vector<std::string> expectedFormOrder =
      json_str_list(som::jsonGet(cases, "expectedFormOrder"));
  std::vector<std::string> gotFields =
      order.orderFormFields(som::jsonStrOr(cases, "formPath"), formFields);
  c.check("serialOrder.orderFormFields", gotFields == expectedFormOrder,
          join(gotFields) + " != " + join(expectedFormOrder));
}

int main(int argc, char** argv) {
  if (argc > 1) {
    g_corpus_dir = argv[1];
  }
  Checker c;
  auto model = load_model();

  std::string tree_err;
  auto tree = som::somBuildMetaTree(*model, "", &tree_err);
  if (tree == nullptr) {
    std::fprintf(stderr, "build meta tree: %s\n", tree_err.c_str());
    std::exit(2);
  }

  test_model_meta(c, *model);
  test_stamp(c, *model);
  test_state_round_trip(c);
  test_yaml_encode(c, *tree);
  test_yaml_decode_round_trip(c, *tree);
  test_markdown_export(c, *model);
  test_markdown_round_trip(c, *model);
  test_markdown_memory_landing(c, *model);
  test_reflection(c, *model);
  test_validation(c, *model);
  test_operations(c);
  test_section_id(c);
  test_serialization_order(c);

  return c.finish();
}
