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
 *   - the YAML `review:` pass (write-back round trip + stale review paths);
 *   - Markdown export == expected.md (byte-for-byte);
 *   - Markdown parse -> memory -> export is clean + byte-stable;
 *   - the Markdown route lands the fixture in the same memory as the YAML route;
 *   - applying a parsed Markdown import (fromMarkdown / applyMarkdownResult);
 *   - the SOM §4.2/§21 editability contract (classification + refusal message);
 *   - reflection resolution cases;
 *   - validation cases;
 *   - the imperative operations script;
 *   - the YRD7 generic editor script (typed values, enum domains, structure);
 *   - the SOM §14 DocSpecs tier (one case per violation rule);
 *   - the SOM §9 text-pattern subset (match spans + compile rejections);
 *   - the SOM §9 query surface, flat node projection and lazy cursor;
 *   - the Phase-4 CodeSpecs extract generator (routing verdicts, the per-area
 *     extracts and their YAML/Markdown goldens, ROUTE-TOTAL refusals);
 *   - reading extracts and the Stage-B gate record back, writing the gate
 *     record, and scoping a set of extracts by it;
 *   - llm_and_d4rt_tools.md §5 constrained node creation (checks + script);
 *   - assembling one document from ordered fragments (refusing overlaps);
 *   - the review annotations (SOM §11.9): listing, counting and editing
 *     comment blocks, question blocks and inline marks.
 *
 * The corpus directory is argv[1], defaulting to
 * "../tom_som_conformance/corpus" relative to the runner's cwd. Exit 0 == all
 * green; non-zero on the first failed group of checks.
 */
#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <map>
#include <memory>
#include <optional>
#include <set>
#include <sstream>
#include <stdexcept>
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
  c.check("model.classCount", model.classesSize() == 15,
          std::to_string(model.classesSize()));
  const som::SpecClass* demo = model.classNamed("Demo");
  c.check("model.Demo.found", demo != nullptr, "");
  if (demo != nullptr) {
    const char* want[] = {"title", "summary",  "priority", "count",
                          "ratio", "score",    "details",  "items",
                          "refs",  "cards",    "meta",     "control",
                          "notes", "mixed",    "registry"};
    bool ok = demo->fields.size() == 15;
    std::string names;
    for (std::size_t i = 0; i < demo->fields.size(); i++) {
      if (i > 0) names.push_back(',');
      names += demo->fields[i].name;
      if (ok && i < 15 && demo->fields[i].name != want[i]) ok = false;
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

/* Maps a corpus token — spelled as the Dart constant name — to the C++ port's
 * own spelling (which happens to coincide, the enum being lowerCamel). */
static som::SomEditability editability_token(const std::string& token) {
  if (token == "editable") return som::SomEditability::editable;
  if (token == "readOnlyCrossMajor") {
    return som::SomEditability::readOnlyCrossMajor;
  }
  if (token == "rejectedNewerMinor") {
    return som::SomEditability::rejectedNewerMinor;
  }
  if (token == "invalidVersion") return som::SomEditability::invalidVersion;
  std::fprintf(stderr, "unknown editability token: %s\n", token.c_str());
  std::exit(2);
}

/* The SOM §4.2/§21 version check. The classifier and the check are one rule seen
 * twice — `rejects` is just "the classification is not editable" — so asserting
 * both is what makes a port that classifies right and refuses wrong fail. The
 * message is pinned because `invalidVersion` is one outcome with two causes, and
 * the message is where they separate. The corpus spells "no stamp" and "no
 * refusal" as JSON null; `jsonStrOr` maps both to "" — for the stamp that is
 * exactly the CS4-D2 sentinel this port's signature uses. */
static void test_editability(Checker& c) {
  som::JsonPtr table = read_json("editability_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    std::string name = som::jsonStrOr(kase, "name");
    std::string generated = som::jsonStrOr(kase, "generated");
    std::string documentVersion = som::jsonStrOr(kase, "documentVersion");
    const std::string prefix = "editability[" + name + "].";

    som::SomEditability want = editability_token(som::jsonStrOr(kase, "editability"));
    c.check(prefix + "classification",
            som::somEditabilityFor(generated, documentVersion) == want, "");

    std::string raised;
    try {
      som::checkSomModelVersion(generated, documentVersion);
    } catch (const som::SomVersionError& e) {
      raised = e.what();
    }
    c.check(prefix + "rejects",
            !raised.empty() == som::jsonBoolOr(kase, "rejects"), raised);
    c.check(prefix + "message", raised == som::jsonStrOr(kase, "message"),
            raised);
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

/* yaml_review_cases.json: the `review:` pass written back by encodeYaml
 * (roundTrip — byte-for-byte) and specYamlStaleReviewPaths after removing list
 * items (stale — the sorted stale paths). */
static void test_yaml_review(Checker& c, const som::SpecModel& model,
                             const som::SomMetaTree& tree) {
  som::JsonPtr table = read_json("yaml_review_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    const std::string name = "yamlReview[" + som::jsonStrOr(kase, "name") + "]";
    som::SpecYamlContents contents;
    std::string err;
    if (!som::decodeYaml(som::jsonStrOr(kase, "yaml"), tree, &contents, &err)) {
      c.check(name, false, err.empty() ? "(no message)" : err);
      continue;
    }
    std::string op = som::jsonStrOr(kase, "op");
    som::JsonRef expect = som::jsonGet(kase, "expect");
    if (op == "roundTrip") {
      std::string err2;
      auto actual = som::encodeYaml(contents.document, tree,
                                    contents.modelVersion, &err2,
                                    contents.review.get());
      if (!actual.has_value()) {
        c.check(name, false, err2.empty() ? "(no message)" : err2);
        continue;
      }
      std::string want = som::jsonStrOr(kase, "expect");
      c.check(name, *actual == want, byte_diff(name, *actual, want));
    } else if (op == "stale") {
      som::JsonRef remove = som::jsonGet(kase, "removeItems");
      for (std::size_t r = 0; r < som::jsonArrayLen(remove); r++) {
        const std::string* item = som::jsonAsStr(som::jsonArrayAt(remove, r));
        if (item != nullptr) {
          contents.document.removeListItem(*item);
        }
      }
      // An absent review pass (nullptr) has no stale paths: treat it as empty.
      std::vector<std::string> got =
          contents.review != nullptr
              ? som::specYamlStaleReviewPaths(model, contents.document,
                                              *contents.review)
              : std::vector<std::string>();
      std::vector<std::string> want;
      for (std::size_t w = 0; w < som::jsonArrayLen(expect); w++) {
        const std::string* s = som::jsonAsStr(som::jsonArrayAt(expect, w));
        want.push_back(s != nullptr ? *s : std::string());
      }
      std::string detail = "got [";
      for (std::size_t g = 0; g < got.size(); g++) {
        detail += (g == 0 ? "" : ", ") + got[g];
      }
      detail += "]";
      c.check(name, got == want, detail);
    } else {
      c.check(name, false, "unknown op " + op);
    }
  }
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
  som::SpecMarkdownImport imported =
      som::SpecDocument::fromMarkdown(expected_md, model);
  c.check("md.land.clean", imported.rejections().empty(),
          rej_str(imported.result));
  som::DocumentJson dj = imported.document.toJson();
  std::string got = som::documentJsonToCanonicalJson(dj);
  std::string want = som::documentJsonToCanonicalJson(canonical);
  c.check("md.land.memory", got == want, "got " + got + " want " + want);
}

/* The SOM §11.7 rejection protocol: nothing is silently dropped. Each case
 * asserts both halves together — the full `(line, reason, anchor, message)`
 * report *and* the document that still landed. A port that drops an unplaceable
 * block fails the first; one that reports it and abandons the rest of the parse
 * fails the second. The corpus spells "no anchor" as JSON null; `jsonStrOr` maps
 * that to "", which is exactly this port's no-anchor sentinel. */
static void test_markdown_import_rejections(Checker& c, const som::SpecModel& model) {
  som::JsonPtr table = read_json("markdown_import_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    std::string name = som::jsonStrOr(kase, "name");
    som::SpecMarkdownResult result =
        som::markdownParse(model, som::jsonStrOr(kase, "markdown"));

    som::JsonRef wantRejections = som::jsonGet(kase, "rejections");
    std::size_t wantN = som::jsonArrayLen(wantRejections);
    c.check("md.reject[" + name + "].count", result.rejections.size() == wantN,
            rej_str(result));
    for (std::size_t j = 0; j < wantN && j < result.rejections.size(); j++) {
      som::JsonRef want = som::jsonArrayAt(wantRejections, j);
      const som::SpecMarkdownRejection& got = result.rejections[j];
      const std::string tag =
          "md.reject[" + name + "][" + std::to_string(j) + "].";
      std::optional<long long> wantLine =
          som::jsonAsI64(som::jsonGet(want, "line"));
      c.check(tag + "line",
              wantLine.has_value() &&
                  static_cast<long long>(got.line) == *wantLine,
              std::to_string(got.line));
      c.check(tag + "reason", got.reason == som::jsonStrOr(want, "reason"),
              got.reason);
      c.check(tag + "anchor", got.anchor == som::jsonStrOr(want, "anchor"),
              got.anchor);
      c.check(tag + "message", got.message == som::jsonStrOr(want, "message"),
              got.message);
    }

    som::SpecDocument landed;
    landed.loadJson(result.document());
    std::string got = som::documentJsonToCanonicalJson(landed.toJson());
    std::string want = som::documentJsonToCanonicalJson(
        som::documentJsonFromJson(som::jsonGet(kase, "document")));
    c.check("md.reject[" + name + "].landed", got == want,
            "got " + got + " want " + want);
  }
}

/* Applying a parsed import (SOM §11.7): SpecDocument::fromMarkdown, and
 * applyMarkdownResult as a full overwrite of the covered roots that keeps every
 * other root and refuses a result with rejections unless allowed. Each case is
 * run exactly like the Dart reference's `_runMarkdownApplyCase`; the observed
 * {refused, rejectionCount, document} must equal the case's `expect`. */
static void test_markdown_apply(Checker& c, const som::SpecModel& model) {
  som::JsonPtr table = read_json("markdown_apply_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  c.check("mdApply.cases", n > 0, "no cases in markdown_apply_cases.json");
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    const std::string tag = "mdApply[" + som::jsonStrOr(kase, "name") + "]";
    const std::string markdown = som::jsonStrOr(kase, "markdown");

    bool refused = false;
    std::size_t rejectionCount = 0;
    som::DocumentJson landed;
    if (som::jsonStrOr(kase, "op") == "fromMarkdown") {
      som::SpecMarkdownImport imported =
          som::SpecDocument::fromMarkdown(markdown, model);
      rejectionCount = imported.rejections().size();
      landed = imported.document.toJson();
    } else {
      som::SpecDocument document = doc_from_state(
          som::documentJsonFromJson(som::jsonGet(kase, "base")));
      som::SpecMarkdownResult parsed = som::markdownParse(model, markdown);
      rejectionCount = parsed.rejections.size();
      try {
        document.applyMarkdownResult(parsed,
                                     som::jsonBoolOr(kase, "allowRejections"));
      } catch (const std::runtime_error&) {
        refused = true;
      }
      landed = document.toJson();
    }

    som::JsonRef expect = som::jsonGet(kase, "expect");
    bool wantRefused = som::jsonBoolOr(expect, "refused");
    c.check(tag + ".refused", refused == wantRefused,
            refused ? "refused" : "not refused");
    std::optional<long long> wantCount =
        som::jsonAsI64(som::jsonGet(expect, "rejectionCount"));
    c.check(tag + ".rejectionCount",
            wantCount.has_value() &&
                static_cast<long long>(rejectionCount) == *wantCount,
            std::to_string(rejectionCount));
    std::string got = som::documentJsonToCanonicalJson(landed);
    std::string want = som::documentJsonToCanonicalJson(
        som::documentJsonFromJson(som::jsonGet(expect, "document")));
    c.check(tag + ".document", got == want, "got " + got + " want " + want);
  }
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

/* ---- generic editor conformance (YRD7) ---------------------------------- */

/* Defined below, alongside the other corpus-list helpers. */
static std::vector<std::string> json_str_list(const som::JsonRef& arr);
static std::string join(const std::vector<std::string>& v);

/* A corpus JSON node as a SomValue, keeping the distinctions the typed contract
 * rests on: the integer 2 is not the double 2.0, and true is not "true". A
 * missing key (nullptr) is the same "no value" as an explicit JSON null. */
static som::SomValue json_value(const som::JsonRef& v) {
  if (v == nullptr) {
    return som::SomValue::null();
  }
  switch (v->type) {
    case som::JsonType::Bool:
      return som::SomValue::ofBool(v->boolean);
    case som::JsonType::Int:
      return som::SomValue::ofInt(v->integer);
    case som::JsonType::Float:
      return som::SomValue::ofDouble(v->real);
    case som::JsonType::Str:
      return som::SomValue::ofString(v->str);
    default:
      return som::SomValue::null();
  }
}

/* Runs `fn` and passes only when it rejects the operation. The editor's write
 * side signals every rejection by throwing (std::invalid_argument for a wrong
 * type / out-of-domain enum / dangling or wrong-kind path, SomSectionIdError
 * for an id clash), so the check is "did it refuse", not "which type". */
template <typename Fn>
static void expect_throws(Checker& c, const std::string& tag, Fn fn) {
  try {
    fn();
  } catch (const std::exception&) {
    c.check(tag, true, "");
    return;
  }
  c.check(tag, false, "did not throw");
}

/* YRD7: the generic, meta-validated modification API (SpecEditor) — typed
 * value/form-field round-trips through the shared boundary helpers, enum domain
 * validation, and structural create/clear ops.
 *
 * The corpus script is stateful and ordered: one document, each step building on
 * the last, so every language replays the identical sequence. */
static void test_editor(Checker& c, const som::SpecModel& model) {
  som::SpecDocument doc;
  som::SpecEditor ed(doc, model);
  som::JsonPtr steps = read_json("editor_cases.json");
  std::size_t n = som::jsonArrayLen(steps);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef s = som::jsonArrayAt(steps, i);
    std::string op = som::jsonStrOr(s, "op");
    std::string path = som::jsonStrOr(s, "path");
    std::string field = som::jsonStrOr(s, "field");
    std::string tag = "editor[" + std::to_string(i) + "]." + op;

    if (op == "setValue") {
      ed.setValue(path, json_value(som::jsonGet(s, "value")));
    } else if (op == "value") {
      som::SomValue got = ed.value(path);
      som::SomValue want = json_value(som::jsonGet(s, "expect"));
      c.check(tag + " " + path, got == want,
              got.debug() + " != " + want.debug());
    } else if (op == "setValueThrows") {
      som::SomValue v = json_value(som::jsonGet(s, "value"));
      expect_throws(c, tag + " " + path, [&] { ed.setValue(path, v); });
    } else if (op == "valueThrows") {
      expect_throws(c, tag + " " + path, [&] { ed.value(path); });
    } else if (op == "setContent") {
      // raw store write (bypasses the typed boundary)
      doc.setContent(path, som::jsonStrOr(s, "value"));
    } else if (op == "setRawFormField") {
      // raw form write (bypasses the typed boundary)
      doc.setFormField(path, field, som::jsonStrOr(s, "value"));
    } else if (op == "valueUnreadable") {
      // stored text the declared type cannot read: the typed read throws
      // rather than answering null
      expect_throws(c, tag + " " + path, [&] { ed.value(path); });
    } else if (op == "formValueUnreadable") {
      expect_throws(c, tag + " " + path + "#" + field,
                    [&] { ed.formValue(path, field); });
    } else if (op == "rawContent") {
      const std::string* got = doc.contentOpt(path);
      const std::string* want = som::jsonAsStr(som::jsonGet(s, "expect"));
      if (want == nullptr) {
        c.check(tag + " " + path, got == nullptr,
                got != nullptr ? *got : std::string());
      } else {
        c.check(tag + " " + path, got != nullptr && *got == *want,
                got != nullptr ? *got : "(unset)");
      }
    } else if (op == "setFormValue") {
      ed.setFormValue(path, field, json_value(som::jsonGet(s, "value")));
    } else if (op == "formValue") {
      som::SomValue got = ed.formValue(path, field);
      som::SomValue want = json_value(som::jsonGet(s, "expect"));
      c.check(tag + " " + path + "#" + field, got == want,
              got.debug() + " != " + want.debug());
    } else if (op == "setFormValueThrows") {
      som::SomValue v = json_value(som::jsonGet(s, "value"));
      expect_throws(c, tag + " " + path + "#" + field,
                    [&] { ed.setFormValue(path, field, v); });
    } else if (op == "formValueThrows") {
      expect_throws(c, tag + " " + path + "#" + field,
                    [&] { ed.formValue(path, field); });
    } else if (op == "rawFormField") {
      const std::string* got = doc.formFieldOpt(path, field);
      const std::string* want = som::jsonAsStr(som::jsonGet(s, "expect"));
      if (want == nullptr) {
        c.check(tag + " " + path + "#" + field, got == nullptr,
                got != nullptr ? *got : std::string());
      } else {
        c.check(tag + " " + path + "#" + field, got != nullptr && *got == *want,
                got != nullptr ? *got : "(unset)");
      }
    } else if (op == "formFieldNames") {
      std::vector<std::string> got;
      for (const som::FormFieldSpec& ff : ed.formFields(path)) {
        got.push_back(ff.name);
      }
      std::vector<std::string> want = json_str_list(som::jsonGet(s, "expect"));
      c.check(tag + " " + path, got == want, join(got) + " != " + join(want));
    } else if (op == "formFieldNamesThrows") {
      expect_throws(c, tag + " " + path, [&] { ed.formFields(path); });
    } else if (op == "setHeadline") {
      ed.setHeadline(path, som::jsonStrOr(s, "value"));
    } else if (op == "headline") {
      std::optional<std::string> got = ed.headline(path);
      const std::string* want = som::jsonAsStr(som::jsonGet(s, "expect"));
      if (want == nullptr) {
        c.check(tag + " " + path, !got.has_value(), got.value_or(""));
      } else {
        c.check(tag + " " + path, got.has_value() && *got == *want,
                got.value_or("(unset)"));
      }
    } else if (op == "headlineThrows") {
      expect_throws(c, tag + " " + path, [&] { ed.headline(path); });
    } else if (op == "itemSectionId") {
      std::string itemPath = som::jsonStrOr(s, "itemPath");
      std::string got = doc.itemSectionId(itemPath);
      std::string want = som::jsonStrOr(s, "expect");
      c.check(tag + " " + itemPath, got == want, got + " != " + want);
    } else if (op == "addListItem" || op == "addListItemThrows") {
      std::string listPath = som::jsonStrOr(s, "listPath");
      long long month = som::jsonAsI64(som::jsonGet(s, "month")).value_or(1);
      long long day = som::jsonAsI64(som::jsonGet(s, "day")).value_or(1);
      if (op == "addListItemThrows") {
        expect_throws(c, tag + " " + listPath,
                      [&] { ed.addListItem(listPath, "", month, day); });
      } else {
        std::string got = ed.addListItem(listPath, "", month, day);
        std::string want = som::jsonStrOr(s, "expectPath");
        c.check(tag + " " + listPath, got == want, got + " != " + want);
        const std::string* wantId = som::jsonAsStr(som::jsonGet(s, "expectId"));
        if (wantId != nullptr) {
          std::string gotId = doc.itemSectionId(got);
          c.check(tag + " id " + listPath, gotId == *wantId,
                  gotId + " != " + *wantId);
        }
      }
    } else if (op == "removeListItem") {
      std::string itemPath = som::jsonStrOr(s, "itemPath");
      c.check(tag + " " + itemPath,
              ed.removeListItem(itemPath) == som::jsonBoolOr(s, "expect"), "");
    } else if (op == "clearSection") {
      ed.clearSection(path);
    } else if (op == "clearSectionThrows") {
      expect_throws(c, tag + " " + path, [&] { ed.clearSection(path); });
    } else if (op == "hasValuesUnder") {
      std::string prefix = som::jsonStrOr(s, "prefix");
      c.check(tag + " " + prefix,
              doc.hasValuesUnder(prefix) == som::jsonBoolOr(s, "expect"), "");
    } else {
      c.check(tag + ".unknown", false, op);
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

/* The SOM §14 DocSpecs tier: one shared schema, one case per violation rule.
 *
 * The corpus carries the rule/sectionId/line triples the Dart reference
 * produces; matching them is what proves this port implements each rule at all,
 * rather than merely declaring its name. `jsonStrOr` yields "" for the corpus's
 * JSON null, which is exactly this port's absent-section-id value. */
static void test_docspecs(Checker& c) {
  std::string err;
  auto schema =
      som::docspecsSchemaFromYamlText(read_corpus("docspecs_schema.yaml"), &err);
  if (!schema.has_value()) {
    std::fprintf(stderr, "docspecs schema: %s\n", err.c_str());
    std::exit(2);
  }
  c.check("docspecs.schemaWarnings", schema->warnings.empty(),
          join(schema->warnings));
  c.check("docspecs.rootSectionId", schema->rootSectionId() == "D00",
          schema->rootSectionId());

  som::DocSpecsValidator validator(*schema);
  som::JsonPtr cases = read_json("docspecs_cases.json");
  std::set<std::string> covered;
  std::size_t n = som::jsonArrayLen(cases);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef cc = som::jsonArrayAt(cases, i);
    std::string name = som::jsonStrOr(cc, "name");

    std::vector<som::DocSpecsViolation> violations;
    validator.validateMarkdown(som::jsonStrOr(cc, "markdown"), violations);
    // "rule|sectionId|line" joined by '/' — one string per side, so a length
    // mismatch is as visible as a value mismatch.
    std::string got_s;
    for (std::size_t k = 0; k < violations.size(); k++) {
      if (k > 0) got_s.push_back('/');
      got_s += violations[k].rule + "|" + violations[k].sectionId + "|" +
               std::to_string(violations[k].line);
    }

    std::string want_s;
    som::JsonRef warr = som::jsonGet(cc, "violations");
    std::size_t wlen = som::jsonArrayLen(warr);
    for (std::size_t k = 0; k < wlen; k++) {
      som::JsonRef wv = som::jsonArrayAt(warr, k);
      std::string rule = som::jsonStrOr(wv, "rule");
      covered.insert(rule);
      long long line = som::jsonAsI64(som::jsonGet(wv, "line")).value_or(-1);
      if (k > 0) want_s.push_back('/');
      want_s += rule + "|" + som::jsonStrOr(wv, "sectionId") + "|" +
                std::to_string(line);
    }

    c.check("docspecs[" + name + "]", got_s == want_s, got_s + " != " + want_s);
  }

  std::vector<std::string> uncovered;
  for (const char* rule : som::kDocSpecsAllRules) {
    if (covered.count(rule) == 0) uncovered.emplace_back(rule);
  }
  c.check("docspecs.ruleCoverage", uncovered.empty(),
          "uncovered: " + join(uncovered));
}

/* Section-body replacement (DocSpecsDocument::replaceSectionBody), run like
 * the Dart reference's `_runDocSpecsReplaceCase`: std::invalid_argument maps to
 * {error: true}; otherwise the returned text must equal `expect.text`
 * byte-for-byte. */
static void test_docspecs_replace(Checker& c) {
  som::JsonPtr table = read_json("docspecs_replace_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  c.check("docspecsReplace.cases", n > 0,
          "no cases in docspecs_replace_cases.json");
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    const std::string tag =
        "docspecsReplace[" + som::jsonStrOr(kase, "name") + "]";
    bool error = false;
    std::string text;
    try {
      text = som::DocSpecsDocument::replaceSectionBody(
          som::jsonStrOr(kase, "markdown"), som::jsonStrOr(kase, "sectionId"),
          som::jsonStrOr(kase, "body"));
    } catch (const std::invalid_argument&) {
      error = true;
    }
    som::JsonRef expect = som::jsonGet(kase, "expect");
    bool wantError = som::jsonBoolOr(expect, "error");
    if (error != wantError) {
      c.check(tag, false, error ? "threw, expected text" : "expected an error");
      continue;
    }
    if (error) {
      c.check(tag, true, "");
      continue;
    }
    std::string want = som::jsonStrOr(expect, "text");
    c.check(tag, text == want, "got " + text + " want " + want);
  }
}

/* docspecs_path_cases.json, run like the Dart reference: for each case the
 * document loaded from `state` renders with a heading map equal to
 * `headingPaths`, and validateSpecDocument against the table's schema yields
 * `violations` ({rule, line, sectionId, path}) in order. */
static void test_docspecs_path(Checker& c, const som::SpecModel& model) {
  som::JsonPtr table = read_json("docspecs_path_cases.json");
  std::string err;
  auto schema =
      som::docspecsSchemaFromYamlText(som::jsonStrOr(table, "schema"), &err);
  if (!schema.has_value()) {
    std::fprintf(stderr, "docspecs path schema: %s\n", err.c_str());
    std::exit(2);
  }
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  c.check("docspecsPath.cases", n > 0, "no cases in docspecs_path_cases.json");
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    const std::string name = som::jsonStrOr(kase, "name");
    const std::string rootType = som::jsonStrOr(kase, "rootType");
    som::SpecDocument doc =
        doc_from_state(som::documentJsonFromJson(som::jsonGet(kase, "state")));

    // Heading map: "line=path" joined by '/', in ascending line order.
    std::string got_s;
    std::string want_s;
    try {
      som::SpecMarkdownRendition r = doc.toMarkdownWithMap(model, rootType);
      for (const auto& e : r.headingPaths) {
        if (!got_s.empty()) got_s.push_back('/');
        got_s += std::to_string(e.first) + "=" + e.second;
      }
    } catch (const std::exception& e) {
      got_s = std::string("threw: ") + e.what();
    }
    std::map<long long, std::string> want;
    som::JsonRef hp = som::jsonGet(kase, "headingPaths");
    if (hp != nullptr) {
      for (const auto& m : hp->object) {
        const std::string* p = som::jsonAsStr(m.second);
        want[std::stoll(m.first)] = p != nullptr ? *p : "";
      }
    }
    for (const auto& e : want) {
      if (!want_s.empty()) want_s.push_back('/');
      want_s += std::to_string(e.first) + "=" + e.second;
    }
    c.check("docspecsPath[" + name + "].headingPaths", got_s == want_s,
            got_s + " != " + want_s);

    // Violations: "rule|line|sectionId|path" joined by '/'.
    got_s.clear();
    want_s.clear();
    try {
      std::vector<som::DocSpecsViolation> vs =
          som::validateSpecDocument(model, doc, *schema, rootType);
      for (std::size_t k = 0; k < vs.size(); k++) {
        if (k > 0) got_s.push_back('/');
        got_s += vs[k].rule + "|" + std::to_string(vs[k].line) + "|" +
                 vs[k].sectionId + "|" + vs[k].path;
      }
    } catch (const std::exception& e) {
      got_s = std::string("threw: ") + e.what();
    }
    som::JsonRef warr = som::jsonGet(kase, "violations");
    std::size_t wn = som::jsonArrayLen(warr);
    for (std::size_t k = 0; k < wn; k++) {
      som::JsonRef wv = som::jsonArrayAt(warr, k);
      long long line = som::jsonAsI64(som::jsonGet(wv, "line")).value_or(-1);
      if (k > 0) want_s.push_back('/');
      want_s += som::jsonStrOr(wv, "rule") + "|" + std::to_string(line) + "|" +
                som::jsonStrOr(wv, "sectionId") + "|" +
                som::jsonStrOr(wv, "path");
    }
    c.check("docspecsPath[" + name + "].violations", got_s == want_s,
            got_s + " != " + want_s);
  }
}

/* ---- SOM §9 text pattern / query / node creation ------------------------ */

/* The fixture document every §9 group starts from — the same one the Dart
 * reference's `_buildDocument()` produces, which is exactly what `state.json`
 * records (list sequence counters included), so re-loading it is a genuinely
 * fresh build and not a replay of an earlier group's mutations. */
static som::SpecDocument fresh_document() {
  return doc_from_state(som::documentJsonFromJson(read_json("state.json")));
}

/* Null and the empty string are different answers here — an absent headline is
 * not a blank one — so they must not both render as "". */
static const char* kNullText = "<null>";

static std::string opt_text(const std::optional<std::string>& v) {
  return v.has_value() ? *v : std::string(kNullText);
}

static std::string json_opt_text(const som::JsonRef& v) {
  const std::string* s = som::jsonAsStr(v);
  return s != nullptr ? *s : std::string(kNullText);
}

static std::string spans_text(const std::vector<som::SpecMatchSpan>& spans) {
  std::string s;
  for (std::size_t i = 0; i < spans.size(); i++) {
    if (i > 0) s.push_back(',');
    s += std::to_string(spans[i].start) + "-" + std::to_string(spans[i].end);
  }
  return s;
}

/* The corpus writes spans as `[[start, end], …]`. */
static std::string json_spans_text(const som::JsonRef& arr) {
  std::string s;
  std::size_t n = som::jsonArrayLen(arr);
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef pair = som::jsonArrayAt(arr, i);
    if (i > 0) s.push_back(',');
    s += std::to_string(
             som::jsonAsI64(som::jsonArrayAt(pair, 0)).value_or(-1)) +
         "-" +
         std::to_string(som::jsonAsI64(som::jsonArrayAt(pair, 1)).value_or(-1));
  }
  return s;
}

/* SOM §9's portable pattern subset: every match case's spans, and every
 * rejection case's refusal to compile at all. `regex: false` exercises the
 * literal constructor, where `.` `*` `[` are plain characters. */
static void test_text_pattern(Checker& c) {
  som::JsonPtr cases = read_json("pattern_cases.json");
  std::size_t n = som::jsonArrayLen(cases);
  std::size_t matchCases = 0, rejectionCases = 0, literalCases = 0;

  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef k = som::jsonArrayAt(cases, i);
    std::string source = som::jsonStrOr(k, "pattern");
    bool regex = som::jsonBoolOr(k, "regex");
    bool caseInsensitive = som::jsonBoolOr(k, "caseInsensitive");
    std::string tag = "pattern[" + std::to_string(i) + "] " +
                      som::jsonEncodeStr(source);

    if (som::jsonBoolOr(k, "error")) {
      rejectionCases++;
      // A malformed pattern must fail *at compile*, not match nothing later.
      try {
        som::SomTextPattern::compile(source, caseInsensitive);
        c.check(tag + ".rejected", false, "compiled without error");
      } catch (const som::SomPatternError& e) {
        c.check(tag + ".rejected", e.pattern() == source, e.pattern());
      }
      continue;
    }

    matchCases++;
    if (!regex) literalCases++;
    som::SomTextPattern pattern =
        regex ? som::SomTextPattern::compile(source, caseInsensitive)
              : som::SomTextPattern::literal(source, caseInsensitive);
    std::string text = som::jsonStrOr(k, "text");
    std::string got = spans_text(pattern.allMatches(text));
    std::string want = json_spans_text(som::jsonGet(k, "spans"));
    c.check(tag + ".spans", got == want, got + " != " + want);
    c.check(tag + ".hasMatch", pattern.hasMatch(text) == !want.empty(), "");
  }

  // A table of only-matches (or only-rejections) would leave half the contract
  // unexercised while still reporting green.
  c.check("pattern.hasMatchCases", matchCases > 0,
          std::to_string(matchCases));
  c.check("pattern.hasRejectionCases", rejectionCases > 0,
          std::to_string(rejectionCases));
  c.check("pattern.hasLiteralCases", literalCases > 0,
          std::to_string(literalCases));
}

/* Decodes one corpus query. An **absent** key leaves the dimension unset — it
 * must never become a default that happens to match, which is why every
 * dimension is read through jsonGet and tested for null rather than through
 * jsonStrOr. */
static som::SpecQuery query_from_json(const som::JsonRef& q) {
  som::SpecQuery out;
  auto str = [&](const char* key) -> std::optional<std::string> {
    const std::string* s = som::jsonAsStr(som::jsonGet(q, key));
    if (s == nullptr) return std::nullopt;
    return *s;
  };
  out.text = str("text");
  out.regex = som::jsonBoolOr(q, "regex");
  out.caseInsensitive = som::jsonBoolOr(q, "caseInsensitive");
  som::JsonRef kinds = som::jsonGet(q, "kinds");
  if (kinds != nullptr && kinds->type == som::JsonType::Array) {
    std::set<std::string> set;
    std::size_t n = som::jsonArrayLen(kinds);
    for (std::size_t i = 0; i < n; i++) {
      const std::string* s = som::jsonAsStr(som::jsonArrayAt(kinds, i));
      if (s != nullptr) set.insert(*s);
    }
    out.kinds = set;
  }
  out.className = str("className");
  out.sectionIdExact = str("sectionIdExact");
  out.sectionIdPrefix = str("sectionIdPrefix");
  out.pathGlob = str("pathGlob");
  out.mapsTo = str("mapsTo");
  out.detailedIn = str("detailedIn");
  std::optional<std::string> state = str("state");
  if (state.has_value()) {
    out.state = *state == "empty" ? som::SpecStateFilter::Empty
                                  : som::SpecStateFilter::NonEmpty;
  }
  return out;
}

/* One match rendered as a single line, so an extra/missing/reordered match is
 * as visible as a wrong field. */
static std::string match_text(const som::SpecQueryMatch& m) {
  return m.path + "|" + m.kind + "|" + opt_text(m.classId) + "|" +
         opt_text(m.headline) + "|" + opt_text(m.snippet) + "|" +
         spans_text(m.matchSpans);
}

static std::string json_match_text(const som::JsonRef& m) {
  return som::jsonStrOr(m, "path") + "|" + som::jsonStrOr(m, "kind") + "|" +
         json_opt_text(som::jsonGet(m, "classId")) + "|" +
         json_opt_text(som::jsonGet(m, "headline")) + "|" +
         json_opt_text(som::jsonGet(m, "snippet")) + "|" +
         json_spans_text(som::jsonGet(m, "spans"));
}

/* The AND-combined query surface: every dimension, alone and in combination,
 * replayed against a freshly-built fixture. Match **order** is part of the
 * contract (document order), so the drained cursor is compared as an ordered
 * list. `count` is asserted separately on a second cursor: it must agree with
 * the number of committed matches while consuming nothing. */
static void test_query(Checker& c, const som::SpecModel& model) {
  som::SpecDocument doc = fresh_document();
  som::SpecQueryEngine engine(model, doc);
  som::JsonPtr cases = read_json("query_cases.json");
  std::size_t n = som::jsonArrayLen(cases);

  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef k = som::jsonArrayAt(cases, i);
    std::string name = som::jsonStrOr(k, "name");
    som::SpecQuery q = query_from_json(som::jsonGet(k, "query"));

    std::vector<std::string> got;
    for (const som::SpecQueryMatch& m : engine.query(q).toList()) {
      got.push_back(match_text(m));
    }
    std::vector<std::string> want;
    som::JsonRef arr = som::jsonGet(k, "matches");
    std::size_t wn = som::jsonArrayLen(arr);
    for (std::size_t j = 0; j < wn; j++) {
      want.push_back(json_match_text(som::jsonArrayAt(arr, j)));
    }
    c.check("query[" + name + "]", got == want,
            join(got) + " != " + join(want));

    // A fresh cursor: count must see the same matches without consuming them.
    som::SpecQueryCursor counting = engine.query(q);
    long long count = counting.count();
    c.check("query[" + name + "].count",
            count == static_cast<long long>(want.size()),
            std::to_string(count) + " != " + std::to_string(want.size()));
  }
}

/* The tier-1 index source: the full projectNodes() walk in document order. */
static void test_projection(Checker& c, const som::SpecModel& model) {
  som::SpecDocument doc = fresh_document();
  som::SpecQueryEngine engine(model, doc);
  som::JsonPtr cases = read_json("projection_cases.json");
  std::size_t n = som::jsonArrayLen(cases);

  std::vector<som::SpecNodeProjection> got = engine.projectNodes();
  c.check("projection.count", got.size() == n,
          std::to_string(got.size()) + " != " + std::to_string(n));

  std::size_t limit = got.size() < n ? got.size() : n;
  for (std::size_t i = 0; i < limit; i++) {
    som::JsonRef w = som::jsonArrayAt(cases, i);
    const som::SpecNodeProjection& p = got[i];
    std::string tag = "projection[" + std::to_string(i) + "] " + p.path;

    c.check(tag + ".path", p.path == som::jsonStrOr(w, "path"),
            p.path + " != " + som::jsonStrOr(w, "path"));
    c.check(tag + ".kind", p.kind == som::jsonStrOr(w, "kind"), p.kind);
    c.check(tag + ".classId",
            opt_text(p.classId) == json_opt_text(som::jsonGet(w, "classId")),
            opt_text(p.classId));
    c.check(tag + ".sectionId",
            opt_text(p.sectionId) ==
                json_opt_text(som::jsonGet(w, "sectionId")),
            opt_text(p.sectionId));
    c.check(tag + ".mapsTo",
            opt_text(p.mapsTo) == json_opt_text(som::jsonGet(w, "mapsTo")),
            opt_text(p.mapsTo));
    c.check(tag + ".detailedIn",
            opt_text(p.detailedIn) ==
                json_opt_text(som::jsonGet(w, "detailedIn")),
            opt_text(p.detailedIn));
    c.check(tag + ".headline",
            opt_text(p.headline) == json_opt_text(som::jsonGet(w, "headline")),
            opt_text(p.headline));
    std::vector<std::string> wantStrings =
        json_str_list(som::jsonGet(w, "searchableStrings"));
    c.check(tag + ".searchableStrings", p.searchableStrings == wantStrings,
            join(p.searchableStrings) + " != " + join(wantStrings));
    c.check(tag + ".hasValue", p.hasValue == som::jsonBoolOr(w, "hasValue"),
            p.hasValue ? "true" : "false");
  }

  // projectNode() must agree with the walk for every path it visited.
  for (const som::SpecNodeProjection& p : got) {
    std::optional<som::SpecNodeProjection> one = engine.projectNode(p.path);
    c.check("projection.single " + p.path,
            one.has_value() && one->kind == p.kind &&
                one->searchableStrings == p.searchableStrings,
            p.path);
  }
}

/* Renders the `stepCases` shape of `catalog` as one line per fact — the steps
 * as read back, stepsFor per area in catalogue order, then the same for
 * `legacy` (the catalogue with its `steps` key removed). */
static std::string render_step_cases(const som::CodeSpecsAreaCatalog& catalog,
                                     const som::CodeSpecsAreaCatalog& legacy) {
  std::string out;
  for (const som::CodeSpecsStep& s : catalog.steps) {
    std::string codes;
    for (std::size_t i = 0; i < s.areaCodes.size(); i++) {
      codes += (i > 0 ? "," : "") + s.areaCodes[i];
    }
    out += "step " + std::to_string(s.number) + " slice " +
           std::to_string(s.slice) + " | " + s.title + " | " + s.placedBy +
           " | " + codes + "\n";
  }
  const som::CodeSpecsAreaCatalog* cats[2] = {&catalog, &legacy};
  for (int k = 0; k < 2; k++) {
    const som::CodeSpecsAreaCatalog& cat = *cats[k];
    if (k == 1) {
      out += "legacy steps " + std::to_string(cat.steps.size()) + " areas " +
             std::to_string(cat.areas.size()) + "\n";
    }
    for (const som::CodeSpecsArea& a : cat.areas) {
      out += (k == 0 ? "area " : "legacy area ") + a.code + ":";
      for (const som::CodeSpecsStep* s : cat.stepsFor(a)) {
        out += " " + std::to_string(s->number);
      }
      out += "\n";
    }
  }
  return out;
}

/* The committed `stepCases` rendered in render_step_cases's shape. The
 * `stepsByArea` objects are walked in their own member order, which is the
 * catalogue's area order the Dart reference wrote them in. */
static std::string render_want_step_cases(const som::JsonRef& want) {
  std::string out;
  som::JsonRef steps = som::jsonGet(want, "steps");
  for (std::size_t i = 0; i < som::jsonArrayLen(steps); i++) {
    som::JsonRef s = som::jsonArrayAt(steps, i);
    std::vector<std::string> codesList =
        json_str_list(som::jsonGet(s, "areaCodes"));
    std::string codes;
    for (std::size_t k = 0; k < codesList.size(); k++) {
      codes += (k > 0 ? "," : "") + codesList[k];
    }
    out += "step " +
           std::to_string(som::jsonAsI64(som::jsonGet(s, "number")).value_or(0)) +
           " slice " +
           std::to_string(som::jsonAsI64(som::jsonGet(s, "slice")).value_or(0)) +
           " | " + som::jsonStrOr(s, "title") + " | " +
           som::jsonStrOr(s, "placedBy") + " | " + codes + "\n";
  }
  som::JsonRef legacy = som::jsonGet(want, "legacy");
  som::JsonRef byArea[2] = {som::jsonGet(want, "stepsByArea"),
                            som::jsonGet(legacy, "stepsByArea")};
  for (int k = 0; k < 2; k++) {
    if (k == 1) {
      out += "legacy steps " +
             std::to_string(
                 som::jsonAsI64(som::jsonGet(legacy, "steps")).value_or(-1)) +
             " areas " +
             std::to_string(
                 som::jsonAsI64(som::jsonGet(legacy, "areas")).value_or(-1)) +
             "\n";
    }
    if (byArea[k] == nullptr || byArea[k]->type != som::JsonType::Object) {
      continue;
    }
    for (const auto& member : byArea[k]->object) {
      out += (k == 0 ? "area " : "legacy area ") + member.first + ":";
      som::JsonRef numbers = member.second;
      for (std::size_t i = 0; i < som::jsonArrayLen(numbers); i++) {
        out += " " + std::to_string(
                         som::jsonAsI64(som::jsonArrayAt(numbers, i)).value_or(0));
      }
      out += "\n";
    }
  }
  return out;
}

/* The catalogue's §4.4.6 authoring steps read back as committed: the step rows,
 * stepsFor per area, and a legacy catalogue — the same JSON with `steps`
 * removed — which must still load, with no steps. */
static void test_codespecs_steps(Checker& c, const som::JsonRef& table) {
  som::JsonRef catalogJson = som::jsonGet(table, "catalog");
  som::CodeSpecsAreaCatalog catalog =
      som::CodeSpecsAreaCatalog::fromJson(catalogJson);
  auto legacyJson = std::make_shared<som::Json>(som::JsonType::Object);
  if (catalogJson != nullptr && catalogJson->type == som::JsonType::Object) {
    for (const auto& member : catalogJson->object) {
      if (member.first != "steps") {
        legacyJson->object.push_back(member);
      }
    }
  }
  som::CodeSpecsAreaCatalog legacy =
      som::CodeSpecsAreaCatalog::fromJson(legacyJson);

  std::string diff =
      byte_diff("stepCases", render_step_cases(catalog, legacy),
                render_want_step_cases(som::jsonGet(table, "stepCases")));
  c.check("codeSpecsExtract.stepCases", diff.empty(), diff);
  c.check("codeSpecsExtract.stepCases.nonEmpty", !catalog.steps.empty(),
          "the corpus catalogue carries no steps");
  c.check("codeSpecsExtract.stepNumbered.missing",
          catalog.stepNumbered(-1) == nullptr, "found a step numbered -1");
}

/* The Phase-4 CodeSpecs specification-extract generator
 * (`codespecs_mapping.md` §1.1.1): the routing diagnostic, the per-area extract
 * goldens (including the YAML and Markdown artifacts byte for byte), and the two
 * guards that keep the generator a copier rather than an author. */
static void test_codespecs_extract(Checker& c, const som::SpecModel& model) {
  som::SpecDocument doc = fresh_document();
  som::JsonPtr table = read_json("codespecs_extract_cases.json");
  som::JsonRef catalogJson = som::jsonGet(table, "catalog");
  som::CodeSpecsExtractor extractor(
      model, doc, som::CodeSpecsAreaCatalog::fromJson(catalogJson));

  // 0. The §4.4.6 authoring steps read back as committed.
  test_codespecs_steps(c, table);

  // 1. The routing verdicts reproduce the committed diagnostic.
  som::JsonRef wantRoutings = som::jsonGet(table, "routings");
  std::vector<som::CodeSpecsRouting> gotRoutings = extractor.routings();
  std::size_t rn = som::jsonArrayLen(wantRoutings);
  c.check("codeSpecsExtract.routings.count", gotRoutings.size() == rn,
          std::to_string(gotRoutings.size()) + " != " + std::to_string(rn));
  std::size_t rlimit = gotRoutings.size() < rn ? gotRoutings.size() : rn;
  for (std::size_t i = 0; i < rlimit; i++) {
    som::JsonRef w = som::jsonArrayAt(wantRoutings, i);
    const som::CodeSpecsRouting& r = gotRoutings[i];
    std::string tag = "codeSpecsExtract.routings[" + std::to_string(i) + "] " +
                      r.path;
    c.check(tag + ".path", r.path == som::jsonStrOr(w, "path"),
            r.path + " != " + som::jsonStrOr(w, "path"));
    c.check(tag + ".className", r.className == som::jsonStrOr(w, "className"),
            r.className);
    std::string verdict = som::codeSpecsRoutingVerdictName(r.verdict);
    c.check(tag + ".verdict", verdict == som::jsonStrOr(w, "verdict"),
            verdict + " != " + som::jsonStrOr(w, "verdict"));
    std::vector<std::string> wantValues =
        json_str_list(som::jsonGet(w, "values"));
    c.check(tag + ".values", r.values == wantValues,
            join(r.values) + " != " + join(wantValues));
    c.check(tag + ".note",
            opt_text(r.note) == json_opt_text(som::jsonGet(w, "note")),
            opt_text(r.note));
    c.check(tag + ".declaredAt", r.declaredAt == som::jsonStrOr(w, "declaredAt"),
            r.declaredAt);
  }

  // 2. The extracts reproduce the committed goldens byte for byte.
  som::JsonRef wantExtracts = som::jsonGet(table, "extracts");
  std::vector<som::CodeSpecsExtract> gotExtracts = extractor.extractAll();
  std::size_t xn = som::jsonArrayLen(wantExtracts);
  c.check("codeSpecsExtract.extracts.count", gotExtracts.size() == xn,
          std::to_string(gotExtracts.size()) + " != " + std::to_string(xn));
  std::size_t xlimit = gotExtracts.size() < xn ? gotExtracts.size() : xn;
  for (std::size_t i = 0; i < xlimit; i++) {
    som::JsonRef w = som::jsonArrayAt(wantExtracts, i);
    const som::CodeSpecsExtract& x = gotExtracts[i];
    std::string tag = "codeSpecsExtract[" + x.area.code + "]";

    c.check(tag + ".area", x.area.code == som::jsonStrOr(w, "area"),
            x.area.code + " != " + som::jsonStrOr(w, "area"));
    c.check(tag + ".canonicalId",
            x.area.canonicalId == som::jsonStrOr(w, "canonicalId"),
            x.area.canonicalId);
    c.check(tag + ".part", x.area.kindValue() == som::jsonStrOr(w, "part"),
            x.area.kindValue());
    c.check(tag + ".documentRoot",
            x.documentRoot == som::jsonStrOr(w, "documentRoot"),
            x.documentRoot);
    c.check(tag + ".fileStem", x.fileStem() == som::jsonStrOr(w, "fileStem"),
            x.fileStem());
    std::vector<std::string> wantProjects =
        json_str_list(som::jsonGet(w, "projects"));
    c.check(tag + ".projects", x.projects == wantProjects,
            join(x.projects) + " != " + join(wantProjects));
    std::vector<std::string> wantCitable =
        json_str_list(som::jsonGet(w, "citableParts"));
    c.check(tag + ".citableParts", x.citableParts == wantCitable,
            join(x.citableParts) + " != " + join(wantCitable));

    som::JsonRef wantEntries = som::jsonGet(w, "entries");
    std::size_t en = som::jsonArrayLen(wantEntries);
    c.check(tag + ".entries.count", x.entries.size() == en,
            std::to_string(x.entries.size()) + " != " + std::to_string(en));
    std::size_t elimit = x.entries.size() < en ? x.entries.size() : en;
    for (std::size_t j = 0; j < elimit; j++) {
      som::JsonRef we = som::jsonArrayAt(wantEntries, j);
      const som::CodeSpecsExtractEntry& e = x.entries[j];
      std::string etag = tag + ".entries[" + std::to_string(j) + "]";
      c.check(etag + ".sectionId", e.sectionId == som::jsonStrOr(we, "sectionId"),
              e.sectionId + " != " + som::jsonStrOr(we, "sectionId"));
      c.check(etag + ".headline",
              opt_text(e.headline) ==
                  json_opt_text(som::jsonGet(we, "headline")),
              opt_text(e.headline));
      c.check(etag + ".instanceId",
              opt_text(e.instanceId) ==
                  json_opt_text(som::jsonGet(we, "instanceId")),
              opt_text(e.instanceId));
      c.check(etag + ".path", e.path == som::jsonStrOr(we, "path"),
              e.path + " != " + som::jsonStrOr(we, "path"));
      c.check(etag + ".className", e.className == som::jsonStrOr(we, "className"),
              e.className);
      c.check(etag + ".fieldName", e.fieldName == som::jsonStrOr(we, "fieldName"),
              e.fieldName);
      c.check(etag + ".formField",
              opt_text(e.formField) ==
                  json_opt_text(som::jsonGet(we, "formField")),
              opt_text(e.formField));
      c.check(etag + ".routedBy", e.routedBy == som::jsonStrOr(we, "routedBy"),
              e.routedBy);
      c.check(etag + ".routedAt", e.routedAt == som::jsonStrOr(we, "routedAt"),
              e.routedAt);
      c.check(etag + ".routingNote",
              opt_text(e.routingNote) ==
                  json_opt_text(som::jsonGet(we, "routingNote")),
              opt_text(e.routingNote));
      c.check(etag + ".value", e.value == som::jsonStrOr(we, "value"), e.value);
    }

    std::string gotYaml = x.toYaml();
    std::string wantYaml = som::jsonStrOr(w, "yaml");
    c.check(tag + ".yaml", gotYaml == wantYaml,
            byte_diff(tag + ".yaml", gotYaml, wantYaml));
    std::string gotMd = x.toMarkdown();
    std::string wantMd = som::jsonStrOr(w, "markdown");
    c.check(tag + ".markdown", gotMd == wantMd,
            byte_diff(tag + ".markdown", gotMd, wantMd));
  }

  // 3. Every emitted value occurs verbatim in the source document — the guard
  // `codespecs_derivation_contract.md` §2.8 C1 rests on, carried in the corpus
  // rather than left to each port's own conscience: the generator may copy and
  // index, it may not compose. Membership, not substring — that is what makes
  // "verbatim" mean verbatim rather than "derived from".
  som::JsonPtr state = read_json("state.json");
  std::set<std::string> stored;
  som::JsonRef content = som::jsonGet(state, "content");
  if (content != nullptr && content->type == som::JsonType::Object) {
    for (const auto& member : content->object) {
      const std::string* s = som::jsonAsStr(member.second);
      if (s != nullptr) stored.insert(*s);
    }
  }
  som::JsonRef forms = som::jsonGet(state, "forms");
  if (forms != nullptr && forms->type == som::JsonType::Object) {
    for (const auto& section : forms->object) {
      if (section.second == nullptr ||
          section.second->type != som::JsonType::Object) {
        continue;
      }
      for (const auto& field : section.second->object) {
        const std::string* s = som::jsonAsStr(field.second);
        if (s != nullptr) stored.insert(*s);
      }
    }
  }
  c.check("codeSpecsExtract.storedValues", !stored.empty(),
          std::to_string(stored.size()));

  // 4. A @FollowUpKind subtree contributes to no extract. `Control` is
  // populated, and populated distinctively, so its absence cannot be an accident
  // of an empty section; `alice` is a @NoArtifact section's own leaf.
  static const char* kUnroutable[] = {"Controlled summary", "ctrl-owner",
                                      "alice"};
  std::set<std::string> emitted;
  for (std::size_t i = 0; i < xn; i++) {
    som::JsonRef w = som::jsonArrayAt(wantExtracts, i);
    std::string area = som::jsonStrOr(w, "area");
    som::JsonRef entries = som::jsonGet(w, "entries");
    std::size_t en = som::jsonArrayLen(entries);
    for (std::size_t j = 0; j < en; j++) {
      som::JsonRef e = som::jsonArrayAt(entries, j);
      std::string value = som::jsonStrOr(e, "value");
      emitted.insert(value);
      c.check("codeSpecsExtract.verbatim " + area + " " +
                  som::jsonStrOr(e, "path"),
              stored.count(value) != 0, value);
    }
  }
  for (const char* value : kUnroutable) {
    c.check(std::string("codeSpecsExtract.notRouted ") + value,
            emitted.count(value) == 0, value);
  }

  // 5. The error cases: a section routed nowhere is a hard failure of extraction
  // and a reported `unrouted` verdict of the diagnostic. Each case carries its
  // own model and (empty) state rather than mutating the shared fixture —
  // `model.meta.json` is a VALID model by construction (§10.2 ROUTE-TOTAL holds
  // over it) and a port should not have to break it to run this case.
  som::JsonRef errorCases = som::jsonGet(table, "errorCases");
  std::size_t cn = som::jsonArrayLen(errorCases);
  for (std::size_t i = 0; i < cn; i++) {
    som::JsonRef k = som::jsonArrayAt(errorCases, i);
    std::string tag = "codeSpecsExtract.error[" + som::jsonStrOr(k, "name") + "]";
    auto errModel = som::SpecModel::fromJson(som::jsonGet(k, "model"));
    if (errModel == nullptr) {
      c.check(tag + ".model", false, "model did not load");
      continue;
    }
    som::SpecDocument errDoc =
        doc_from_state(som::documentJsonFromJson(som::jsonGet(k, "state")));
    som::CodeSpecsExtractor errExtractor(
        *errModel, errDoc, som::CodeSpecsAreaCatalog::fromJson(catalogJson));

    som::JsonRef want = som::jsonGet(k, "expect");
    std::string wantPath = som::jsonStrOr(want, "path");
    try {
      errExtractor.extractAll();
      c.check(tag, false, "did not throw");
    } catch (const som::CodeSpecsExtractError& e) {
      c.check(tag + ".path", e.path() == wantPath, e.path() + " != " + wantPath);
      c.check(tag + ".className",
              e.className() == som::jsonStrOr(want, "className"),
              e.className());
      std::string contains = som::jsonStrOr(want, "messageContains");
      c.check(tag + ".message",
              e.message().find(contains) != std::string::npos, e.message());
    }

    // The diagnostic reports the same node instead of failing over it.
    std::vector<std::string> verdicts;
    for (const som::CodeSpecsRouting& r : errExtractor.routings()) {
      if (r.path == wantPath) {
        verdicts.emplace_back(som::codeSpecsRoutingVerdictName(r.verdict));
      }
    }
    std::vector<std::string> wantVerdicts{som::jsonStrOr(want, "routingVerdict")};
    c.check(tag + ".routingVerdict", verdicts == wantVerdicts, join(verdicts));
  }

  // 5b. The catalogue error cases: a malformed slice, step or area row fails
  // the load with a message that names the row.
  som::JsonRef catalogErrorCases = som::jsonGet(table, "catalogErrorCases");
  std::size_t cen = som::jsonArrayLen(catalogErrorCases);
  c.check("codeSpecsExtract.catalogErrorCases.nonEmpty", cen > 0, "");
  for (std::size_t i = 0; i < cen; i++) {
    som::JsonRef k = som::jsonArrayAt(catalogErrorCases, i);
    std::string tag =
        "codeSpecsExtract.catalogError[" + som::jsonStrOr(k, "name") + "]";
    std::string contains =
        som::jsonStrOr(som::jsonGet(k, "expect"), "messageContains");
    try {
      som::CodeSpecsAreaCatalog::fromJson(som::jsonGet(k, "catalog"));
      c.check(tag, false, "did not throw");
    } catch (const std::invalid_argument& e) {
      std::string message = e.what();
      c.check(tag + ".message", message.find(contains) != std::string::npos,
              message);
    }
  }

  // 6. Root scoping (`codespecs_prompt.md` §5): the walk starts at ONE root. The
  // models here carry two, because over a single-root model "walks the named
  // root" and "walks every root" give the same answer.
  som::JsonRef rootCases = som::jsonGet(table, "rootCases");
  std::size_t rcn = som::jsonArrayLen(rootCases);
  for (std::size_t i = 0; i < rcn; i++) {
    som::JsonRef k = som::jsonArrayAt(rootCases, i);
    std::string tag = "codeSpecsExtract.root[" + som::jsonStrOr(k, "name") + "]";
    auto rootModel = som::SpecModel::fromJson(som::jsonGet(k, "model"));
    if (rootModel == nullptr) {
      c.check(tag + ".model", false, "model did not load");
      continue;
    }
    som::SpecDocument rootDoc =
        doc_from_state(som::documentJsonFromJson(som::jsonGet(k, "state")));
    som::JsonRef want = som::jsonGet(k, "expect");
    std::optional<som::CodeSpecsExtractor> x;
    std::optional<som::CodeSpecsExtractError> raised;
    try {
      x.emplace(*rootModel, rootDoc,
                som::CodeSpecsAreaCatalog::fromJson(catalogJson),
                som::jsonStrOr(k, "rootType"));
    } catch (const som::CodeSpecsExtractError& e) {
      raised = e;
    }
    if (som::jsonBoolOr(want, "fails")) {
      c.check(tag + ".thrown", raised.has_value(),
              "the extractor bound instead of failing");
      if (raised.has_value()) {
        c.check(tag + ".path", raised->path() == som::jsonStrOr(want, "path"),
                raised->path());
        c.check(tag + ".className",
                raised->className() == som::jsonStrOr(want, "className"),
                raised->className());
        std::string contains = som::jsonStrOr(want, "messageContains");
        c.check(tag + ".message",
                raised->message().find(contains) != std::string::npos,
                raised->message());
      }
      continue;
    }
    c.check(tag + ".bound", x.has_value(),
            raised.has_value() ? raised->message() : std::string());
    if (!x.has_value()) continue;
    c.check(tag + ".root", x->root().type == som::jsonStrOr(want, "root"),
            x->root().type);
    /* `routings` and `extractAll` walk the same resolved root, so the verdict
     * sequence is scoped too — that is what makes the bare `@Document` root of
     * case 2 the corpus's `documentRoot` producer. */
    std::vector<std::string> rootVerdicts;
    for (const som::CodeSpecsRouting& r : x->routings()) {
      rootVerdicts.emplace_back(som::codeSpecsRoutingVerdictName(r.verdict));
    }
    std::vector<std::string> wantVerdicts;
    som::JsonRef verdictsJson = som::jsonGet(want, "routingVerdicts");
    std::size_t vn = som::jsonArrayLen(verdictsJson);
    for (std::size_t v = 0; v < vn; v++) {
      const std::string* s = som::jsonAsStr(som::jsonArrayAt(verdictsJson, v));
      wantVerdicts.push_back(s == nullptr ? std::string() : *s);
    }
    c.check(tag + ".routingVerdicts", rootVerdicts == wantVerdicts,
            join(rootVerdicts) + " != " + join(wantVerdicts));
    std::vector<som::CodeSpecsExtract> rootExtracts = x->extractAll();
    c.check(tag + ".documentRoot",
            rootExtracts.front().documentRoot ==
                som::jsonStrOr(want, "documentRoot"),
            rootExtracts.front().documentRoot);
    std::vector<std::string> paths;
    for (const som::CodeSpecsExtract& g : rootExtracts) {
      for (const som::CodeSpecsExtractEntry& e : g.entries) {
        paths.push_back(e.path);
      }
    }
    std::vector<std::string> wantPaths;
    som::JsonRef pathsJson = som::jsonGet(want, "paths");
    std::size_t pn = som::jsonArrayLen(pathsJson);
    for (std::size_t p = 0; p < pn; p++) {
      const std::string* s = som::jsonAsStr(som::jsonArrayAt(pathsJson, p));
      wantPaths.push_back(s == nullptr ? std::string() : *s);
    }
    c.check(tag + ".paths", paths == wantPaths,
            join(paths) + " != " + join(wantPaths));
  }
}

/* ---- CodeSpecs records: reading extracts and the gate record ------------- */

/* Compact JSON text of a corpus value, keys in source order — the form the
 * summaries below are rendered in, so one string comparison checks a summary. */
static std::string json_text(const som::JsonRef& v) {
  if (v == nullptr) return "null";
  switch (v->type) {
    case som::JsonType::Null:
      return "null";
    case som::JsonType::Bool:
      return v->boolean ? "true" : "false";
    case som::JsonType::Int:
      return std::to_string(v->integer);
    case som::JsonType::Float: {
      char num[64];
      std::snprintf(num, sizeof(num), "%.17g", v->real);
      return num;
    }
    case som::JsonType::Str:
      return som::jsonEncodeStr(v->str);
    case som::JsonType::Array: {
      std::string b = "[";
      for (std::size_t i = 0; i < v->array.size(); i++) {
        if (i > 0) b += ",";
        b += json_text(v->array[i]);
      }
      return b + "]";
    }
    case som::JsonType::Object: {
      std::string b = "{";
      for (std::size_t i = 0; i < v->object.size(); i++) {
        if (i > 0) b += ",";
        b += som::jsonEncodeStr(v->object[i].first) + ":" +
             json_text(v->object[i].second);
      }
      return b + "}";
    }
  }
  return "null";
}

static std::string sum_str(const std::optional<std::string>& s) {
  return s.has_value() ? som::jsonEncodeStr(*s) : std::string("null");
}

static std::string sum_list(const std::vector<std::optional<std::string>>& l) {
  std::string b = "[";
  for (std::size_t i = 0; i < l.size(); i++) {
    if (i > 0) b += ",";
    b += sum_str(l[i]);
  }
  return b + "]";
}

static std::string sum_list(const std::vector<std::string>& l) {
  return sum_list(std::vector<std::optional<std::string>>(l.begin(), l.end()));
}

/* The Dart `_extractSummary`, key for key. */
static std::string extract_summary(const som::CodeSpecsExtract& x) {
  std::vector<std::optional<std::string>> sectionIds, values, classNames,
      headlines;
  for (const som::CodeSpecsExtractEntry& e : x.entries) {
    sectionIds.emplace_back(e.sectionId);
    values.emplace_back(e.value);
    classNames.emplace_back(e.className);
    headlines.push_back(e.headline);
  }
  return "{\"area\":" + sum_str(x.area.code) +
         ",\"canonicalId\":" + sum_str(x.area.canonicalId) +
         ",\"part\":" + sum_str(x.area.part) +
         ",\"documentRoot\":" + sum_str(x.documentRoot) +
         ",\"projects\":" + sum_list(x.projects) +
         ",\"citableParts\":" + sum_list(x.citableParts) +
         ",\"entryCount\":" + std::to_string(x.entries.size()) +
         ",\"sectionIds\":" + sum_list(sectionIds) +
         ",\"values\":" + sum_list(values) +
         ",\"classNames\":" + sum_list(classNames) +
         ",\"headlines\":" + sum_list(headlines) + "}";
}

/* The Dart `_gateSummary`. */
static std::string gate_summary(const som::CodeSpecsGateRecord& g) {
  std::string b = "{\"verdicts\":[";
  for (std::size_t i = 0; i < g.verdicts().size(); i++) {
    const som::CodeSpecsGateEntry& e = g.verdicts()[i];
    if (i > 0) b += ",";
    b += "{\"area\":" + sum_str(e.area) + ",\"verdict\":" +
         sum_str(std::string(som::codeSpecsGateVerdictWord(e.verdict))) +
         ",\"resolution\":" + sum_str(e.resolution) +
         ",\"note\":" + sum_str(e.note);
    // Only when present, so a gap-less entry's summary is unchanged.
    if (!e.gaps.empty()) {
      b += ",\"gaps\":[";
      for (std::size_t k = 0; k < e.gaps.size(); k++) {
        const som::CodeSpecsGateGap& g = e.gaps[k];
        if (k > 0) b += ",";
        b += "{\"sectionId\":" + sum_str(g.sectionId) +
             ",\"required\":" + sum_str(g.required) +
             ",\"carrier\":" + sum_str(g.carrier) + "}";
      }
      b += "]";
    }
    b += "}";
  }
  return b + "]}";
}

/* The Dart `_scopeSummary`. */
static std::string scope_summary(const som::CodeSpecsExtractSet& s) {
  std::vector<std::string> inScope;
  for (const som::CodeSpecsExtract& x : s.extracts()) inScope.push_back(x.area.code);
  std::string b = "{\"inScope\":" + sum_list(inScope) +
                  ",\"sources\":" + sum_list(s.sources()) + ",\"hasGate\":" +
                  (s.gate().has_value() ? "true" : "false") + ",\"excluded\":[";
  for (std::size_t i = 0; i < s.excluded().size(); i++) {
    const som::CodeSpecsExcludedArea& e = s.excluded()[i];
    if (i > 0) b += ",";
    b += "{\"area\":" + sum_str(e.area) + ",\"verdict\":" +
         sum_str(std::string(som::codeSpecsGateVerdictWord(e.verdict))) +
         ",\"descoped\":" + (e.descoped ? "true" : "false") +
         ",\"entryCount\":" + std::to_string(e.entryCount) +
         ",\"source\":" + sum_str(e.source) + "}";
  }
  return b + "]}";
}

/* A gate entry from its corpus form. */
static som::CodeSpecsGateEntry gate_entry_json(const som::JsonRef& v) {
  som::CodeSpecsGateEntry e;
  e.area = som::jsonStrOr(v, "area");
  e.verdict = som::parseCodeSpecsGateVerdict(som::jsonStrOr(v, "verdict"))
                  .value_or(som::CodeSpecsGateVerdict::Sufficient);
  if (const std::string* r = som::jsonAsStr(som::jsonGet(v, "resolution"))) {
    e.resolution = *r;
  }
  if (const std::string* n = som::jsonAsStr(som::jsonGet(v, "note"))) {
    e.note = *n;
  }
  som::JsonRef gaps = som::jsonGet(v, "gaps");
  std::size_t n = gaps ? som::jsonArrayLen(gaps) : 0;
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef g = som::jsonArrayAt(gaps, i);
    e.gaps.push_back({som::jsonStrOr(g, "sectionId"),
                      som::jsonStrOr(g, "required"),
                      som::jsonStrOr(g, "carrier")});
  }
  return e;
}

static void check_summary(Checker& c, const std::string& tag,
                          const std::string& got, const som::JsonRef& want) {
  std::string w = json_text(want);
  c.check(tag, got == w, byte_diff(tag, got, w));
}

/* Runs `act`, which must throw CodeSpecsRecordError with a message containing
 * `want`; returns the message ("" when it did not throw). */
template <typename F>
static std::string check_record_error(Checker& c, const std::string& tag,
                                      const std::string& want, F act) {
  try {
    act();
  } catch (const som::CodeSpecsRecordError& e) {
    c.check(tag, e.message().find(want) != std::string::npos,
            "got \"" + e.message() + "\" want \"" + want + "\"");
    return e.message();
  }
  c.check(tag, false, "no error; want \"" + want + "\"");
  return "";
}

/* `codespecs_record_cases.json`: reading extracts and the gate record back,
 * writing the gate record, and scoping a set of extracts by it. */
/* ---- CodeSpecs gate: Stage A, A1–A5 ------------------------------------- */

/* The report in the corpus's `expect` shape, as compact JSON text in the key
 * order of the Dart `_runGateCase`. */
static std::string gate_report_text(const som::CodeSpecsGateReport& r) {
  std::string b = "{\"passed\":";
  b += r.passed() ? "true" : "false";
  b += ",\"results\":[";
  for (std::size_t i = 0; i < r.results.size(); i++) {
    const som::CodeSpecsGateCheckResult& res = r.results[i];
    if (i > 0) b += ",";
    b += "{\"check\":" + sum_str(std::string(som::codeSpecsGateCheckLabel(res.check)));
    b += ",\"ran\":";
    b += res.ran ? "true" : "false";
    b += ",\"notRunReason\":" + sum_str(res.notRunReason);
    b += ",\"findings\":[";
    for (std::size_t k = 0; k < res.findings.size(); k++) {
      const som::CodeSpecsGateFinding& f = res.findings[k];
      if (k > 0) b += ",";
      b += "{\"code\":" + sum_str(f.code) + ",\"location\":" +
           sum_str(f.location) + ",\"message\":" + sum_str(f.message) + "}";
    }
    b += "]}";
  }
  b += "]}";
  return b;
}

/* One gate case, like the Dart `_runGateCase`. A case key that is PRESENT
 * overrides the table default — `schema: null` means no schema, `gate: null` a
 * catalogue without gate tables. */
static std::string run_gate_case(const som::JsonRef& table, const som::JsonRef& cc,
                                 const som::JsonRef& meta) {
  // The catalogue JSON: `catalog` plus `gate` unless that is null. A shallow
  // copy, so the shared table is never written to.
  som::JsonRef gate = som::jsonGet(cc, "gate") != nullptr
                          ? som::jsonGet(cc, "gate")
                          : som::jsonGet(table, "gate");
  auto catalogJson = std::make_shared<som::Json>(*som::jsonGet(table, "catalog"));
  if (gate != nullptr && gate->type != som::JsonType::Null) {
    catalogJson->object.emplace_back("gate", std::const_pointer_cast<som::Json>(gate));
  }
  som::CodeSpecsAreaCatalog catalog = som::CodeSpecsAreaCatalog::fromJson(catalogJson);

  som::JsonRef schemaYaml = som::jsonGet(cc, "schema") != nullptr
                                ? som::jsonGet(cc, "schema")
                                : som::jsonGet(table, "schema");
  std::optional<som::DocSpecsSchema> schema;
  if (som::jsonAsStr(schemaYaml) != nullptr) {
    std::string err;
    schema = som::docspecsSchemaFromYamlText(*som::jsonAsStr(schemaYaml), &err);
    if (!schema.has_value()) return "schema did not parse: " + err;
  }
  som::JsonRef modelJson = som::jsonGet(cc, "model");
  std::unique_ptr<som::SpecModel> model =
      som::SpecModel::fromJson(modelJson != nullptr ? modelJson : meta);
  som::SpecDocument doc =
      doc_from_state(som::documentJsonFromJson(som::jsonGet(cc, "state")));
  try {
    som::CodeSpecsGate gateRun(*model, doc, catalog,
                               schema.has_value() ? &*schema : nullptr);
    return gate_report_text(gateRun.run());
  } catch (const std::exception& e) {
    return std::string("gate run threw: ") + e.what();
  }
}

/* `codespecs_gate_cases.json`: the Stage-A gate, A1–A5, every case. */
static void test_codespecs_gate(Checker& c) {
  som::JsonPtr table = read_json("codespecs_gate_cases.json");
  som::JsonPtr meta = read_json("model.meta.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  c.check("codespecsGate.cases.nonEmpty", n > 0, "no cases");
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef cc = som::jsonArrayAt(cases, i);
    std::string tag = "codespecsGate[" + som::jsonStrOr(cc, "name") + "]";
    std::string got = run_gate_case(table, cc, meta);
    std::string want = json_text(som::jsonGet(cc, "expect"));
    c.check(tag, got == want, byte_diff(tag, got, want));
  }
}

static void test_codespecs_records(Checker& c) {
  som::JsonPtr table = read_json("codespecs_record_cases.json");
  som::JsonPtr extractTable = read_json("codespecs_extract_cases.json");
  som::CodeSpecsAreaCatalog catalog =
      som::CodeSpecsAreaCatalog::fromJson(som::jsonGet(extractTable, "catalog"));

  // 1. Extract reads: the summary, and the byte-stable round trip.
  som::JsonRef reads = som::jsonGet(table, "extractReads");
  c.check("codespecsRecords.extractReads.nonEmpty", som::jsonArrayLen(reads) > 0,
          "");
  for (std::size_t i = 0; i < som::jsonArrayLen(reads); i++) {
    som::JsonRef k = som::jsonArrayAt(reads, i);
    std::string yaml = som::jsonStrOr(k, "yaml");
    std::string tag =
        "codespecsRecords.extractRead[" + som::jsonStrOr(k, "source") + "]";
    try {
      som::CodeSpecsExtract x =
          som::CodeSpecsExtract::fromYaml(yaml, som::jsonStrOr(k, "source"));
      check_summary(c, tag, extract_summary(x), som::jsonGet(k, "expect"));
      std::string again = x.toYaml();
      c.check(tag + ".roundTrip", again == yaml,
              byte_diff(tag + ".roundTrip", again, yaml));
    } catch (const som::CodeSpecsRecordError& e) {
      c.check(tag, false, e.message());
    }
  }

  // 2. A minimal hand-written extract: absent keys read as empty.
  {
    som::JsonRef k = som::jsonGet(table, "extractMinimal");
    try {
      som::CodeSpecsExtract x = som::CodeSpecsExtract::fromYaml(
          som::jsonStrOr(k, "yaml"), som::jsonStrOr(k, "source"));
      check_summary(c, "codespecsRecords.extractMinimal", extract_summary(x),
                    som::jsonGet(k, "expect"));
    } catch (const som::CodeSpecsRecordError& e) {
      c.check("codespecsRecords.extractMinimal", false, e.message());
    }
  }

  // 3. Extract errors.
  som::JsonRef xerrs = som::jsonGet(table, "extractErrors");
  for (std::size_t i = 0; i < som::jsonArrayLen(xerrs); i++) {
    som::JsonRef k = som::jsonArrayAt(xerrs, i);
    check_record_error(
        c, "codespecsRecords.extractError[" + som::jsonStrOr(k, "name") + "]",
        som::jsonStrOr(k, "messageContains"), [&] {
          som::CodeSpecsExtract::fromYaml(som::jsonStrOr(k, "yaml"),
                                          som::jsonStrOr(k, "source"));
        });
  }

  // 4. Gate records: parse, summary, byte-stable write, valid against the
  // catalogue.
  som::JsonRef records = som::jsonGet(table, "gateRecords");
  for (std::size_t i = 0; i < som::jsonArrayLen(records); i++) {
    som::JsonRef k = som::jsonArrayAt(records, i);
    std::string yaml = som::jsonStrOr(k, "yaml");
    std::string tag =
        "codespecsRecords.gateRecord[" + som::jsonStrOr(k, "name") + "]";
    try {
      som::CodeSpecsGateRecord g = som::CodeSpecsGateRecord::fromYaml(yaml);
      check_summary(c, tag, gate_summary(g), som::jsonGet(k, "expect"));
      std::string again = g.toYaml();
      c.check(tag + ".toYaml", again == yaml,
              byte_diff(tag + ".toYaml", again, yaml));
      g.checkAgainst(catalog);
      c.check(tag + ".checkAgainst", true, "");
    } catch (const som::CodeSpecsRecordError& e) {
      c.check(tag, false, e.message());
    }
  }

  // 5. Gate writes: built from verdicts, then one recorded with withVerdict.
  som::JsonRef writes = som::jsonGet(table, "gateWrites");
  for (std::size_t i = 0; i < som::jsonArrayLen(writes); i++) {
    som::JsonRef k = som::jsonArrayAt(writes, i);
    std::string tag =
        "codespecsRecords.gateWrite[" + som::jsonStrOr(k, "name") + "]";
    try {
      std::vector<som::CodeSpecsGateEntry> verdicts;
      som::JsonRef list = som::jsonGet(k, "verdicts");
      for (std::size_t v = 0; v < som::jsonArrayLen(list); v++) {
        verdicts.push_back(gate_entry_json(som::jsonArrayAt(list, v)));
      }
      som::CodeSpecsGateRecord g(verdicts);
      std::string yaml = g.toYaml();
      c.check(tag, yaml == som::jsonStrOr(k, "yaml"),
              byte_diff(tag, yaml, som::jsonStrOr(k, "yaml")));
      som::JsonRef then = som::jsonGet(k, "then");
      if (then != nullptr && then->type == som::JsonType::Object) {
        std::string y2 = g.withVerdict(gate_entry_json(then)).toYaml();
        c.check(tag + ".then", y2 == som::jsonStrOr(k, "thenYaml"),
                byte_diff(tag + ".then", y2, som::jsonStrOr(k, "thenYaml")));
      }
    } catch (const som::CodeSpecsRecordError& e) {
      c.check(tag, false, e.message());
    }
  }

  // 6. Gate errors — some only against the catalogue.
  som::JsonRef gerrs = som::jsonGet(table, "gateErrors");
  for (std::size_t i = 0; i < som::jsonArrayLen(gerrs); i++) {
    som::JsonRef k = som::jsonArrayAt(gerrs, i);
    check_record_error(
        c, "codespecsRecords.gateError[" + som::jsonStrOr(k, "name") + "]",
        som::jsonStrOr(k, "messageContains"), [&] {
          som::CodeSpecsGateRecord g =
              som::CodeSpecsGateRecord::fromYaml(som::jsonStrOr(k, "yaml"));
          if (som::jsonBoolOr(k, "againstCatalog")) g.checkAgainst(catalog);
        });
  }

  // 7. Scoping a set of files (an ordered list of [name, text] pairs).
  som::JsonRef scopes = som::jsonGet(table, "scopeCases");
  for (std::size_t i = 0; i < som::jsonArrayLen(scopes); i++) {
    som::JsonRef k = som::jsonArrayAt(scopes, i);
    std::string tag = "codespecsRecords.scope[" + som::jsonStrOr(k, "name") + "]";
    std::vector<std::pair<std::string, std::string>> files;
    som::JsonRef list = som::jsonGet(k, "files");
    for (std::size_t f = 0; f < som::jsonArrayLen(list); f++) {
      som::JsonRef pair = som::jsonArrayAt(list, f);
      const std::string* name = som::jsonAsStr(som::jsonArrayAt(pair, 0));
      const std::string* text = som::jsonAsStr(som::jsonArrayAt(pair, 1));
      files.emplace_back(name ? *name : "", text ? *text : "");
    }
    som::JsonRef want = som::jsonGet(k, "expect");
    if (const std::string* wantError = som::jsonAsStr(som::jsonGet(want, "error"))) {
      std::string got = check_record_error(c, tag, *wantError, [&] {
        som::CodeSpecsExtractSet::fromFiles(files);
      });
      c.check(tag + ".exactMessage", got == *wantError, got);
      continue;
    }
    try {
      som::CodeSpecsExtractSet set = som::CodeSpecsExtractSet::fromFiles(files);
      check_summary(c, tag, scope_summary(set), want);
      for (const som::CodeSpecsExtract& x : set.extracts()) {
        c.check(tag + ".byArea[" + x.area.code + "]",
                set.byArea(x.area.code) == &x, "");
      }
    } catch (const som::CodeSpecsRecordError& e) {
      c.check(tag, false, e.message());
    }
  }

  // 8. The lookups across a scoped set: every entry is found by its section id
  // and by its path, and a token no entry carries finds nothing.
  try {
    std::vector<std::pair<std::string, std::string>> files;
    for (std::size_t f = 0; f < som::jsonArrayLen(reads); f++) {
      som::JsonRef k = som::jsonArrayAt(reads, f);
      files.emplace_back(som::jsonStrOr(k, "source"), som::jsonStrOr(k, "yaml"));
    }
    som::CodeSpecsExtractSet set = som::CodeSpecsExtractSet::fromFiles(files);
    std::size_t total = 0, bySection = 0, byPath = 0;
    for (const som::CodeSpecsExtract& x : set.extracts()) {
      for (const som::CodeSpecsExtractEntry& e : x.entries) {
        for (const som::CodeSpecsExtractEntry* h : set.entriesForSection(e.sectionId)) {
          bySection += h == &e;
        }
        for (const som::CodeSpecsExtractEntry* h : set.entriesAtPath(e.path)) {
          byPath += h == &e;
        }
        total++;
      }
    }
    c.check("codespecsRecords.lookups.entriesForSection",
            total > 0 && bySection == total, "");
    c.check("codespecsRecords.lookups.entriesAtPath",
            total > 0 && byPath == total, "");
    c.check("codespecsRecords.lookups.none",
            set.entriesForSection("NO-SUCH").empty(), "");
    c.check("codespecsRecords.lookups.byArea.missing",
            set.byArea("CE-NONE") == nullptr, "");
  } catch (const som::CodeSpecsRecordError& e) {
    c.check("codespecsRecords.lookups.read", false, e.message());
  }
}

/* The cursor's laziness and its view of a **mutating** document: the script
 * removes a list item between opening a cursor and draining it, and the removed
 * item must not surface. */
static void test_cursor(Checker& c, const som::SpecModel& model) {
  som::SpecDocument doc = fresh_document();
  som::SpecQueryEngine engine(model, doc);
  som::JsonPtr steps = read_json("cursor_cases.json");
  std::size_t n = som::jsonArrayLen(steps);
  std::optional<som::SpecQueryCursor> cursor;

  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef s = som::jsonArrayAt(steps, i);
    std::string op = som::jsonStrOr(s, "op");
    std::string tag = "cursor[" + std::to_string(i) + "]." + op;

    if (op == "open") {
      cursor = engine.query(query_from_json(som::jsonGet(s, "query")));
    } else if (op == "count") {
      long long want = som::jsonAsI64(som::jsonGet(s, "expect")).value_or(-1);
      long long got = cursor.has_value() ? cursor->count() : -1;
      c.check(tag, got == want,
              std::to_string(got) + " != " + std::to_string(want));
    } else if (op == "take") {
      long long take = som::jsonAsI64(som::jsonGet(s, "n")).value_or(0);
      std::vector<std::string> got;
      if (cursor.has_value()) {
        for (const som::SpecQueryMatch& m : cursor->take(take)) {
          got.push_back(m.path);
        }
      }
      std::vector<std::string> want =
          json_str_list(som::jsonGet(s, "expect"));
      c.check(tag, got == want, join(got) + " != " + join(want));
    } else if (op == "next") {
      std::optional<som::SpecQueryMatch> m =
          cursor.has_value() ? cursor->next() : std::nullopt;
      std::string got = m.has_value() ? m->path : std::string(kNullText);
      std::string want = json_opt_text(som::jsonGet(s, "expect"));
      c.check(tag, got == want, got + " != " + want);
    } else if (op == "toList") {
      std::vector<std::string> got;
      if (cursor.has_value()) {
        for (const som::SpecQueryMatch& m : cursor->toList()) {
          got.push_back(m.path);
        }
      }
      std::vector<std::string> want =
          json_str_list(som::jsonGet(s, "expect"));
      c.check(tag, got == want, join(got) + " != " + join(want));
    } else if (op == "removeListItem") {
      std::string itemPath = som::jsonStrOr(s, "itemPath");
      c.check(tag + " " + itemPath, doc.removeListItem(itemPath), itemPath);
    } else {
      c.check(tag + ".unknown", false, op);
    }
  }
}

/* llm_and_d4rt_tools.md §5: the stateless rule check. Every probe runs against a
 * *freshly built* document, so an accepted add in one case cannot change the
 * verdict of the next. A rejection is asserted on its code and the pair it names
 * — not on the message text, which is prose and not part of the contract. */
static void test_node_creation_cases(Checker& c, const som::SpecModel& model) {
  som::JsonPtr cases = read_json("node_creation_cases.json");
  std::size_t n = som::jsonArrayLen(cases);
  std::set<std::string> coveredCodes;

  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef k = som::jsonArrayAt(cases, i);
    std::string name = som::jsonStrOr(k, "name");
    som::SpecDocument doc = fresh_document();
    std::optional<som::SpecCreationError> error = som::checkAddNode(
        model, doc, som::jsonStrOr(k, "parentPath"),
        som::jsonStrOr(k, "childSegment"), som::jsonStrOr(k, "itemId"));

    bool accepted = som::jsonBoolOr(k, "accepted");
    c.check("nodeCreation[" + name + "].accepted", !error.has_value() == accepted,
            error.has_value() ? error->what() : "accepted");
    if (accepted || !error.has_value()) {
      continue;
    }
    std::string wantCode = som::jsonStrOr(k, "code");
    coveredCodes.insert(wantCode);
    c.check("nodeCreation[" + name + "].code",
            som::specCreationCodeName(error->code()) == wantCode,
            std::string(som::specCreationCodeName(error->code())) + " != " +
                wantCode);
    c.check("nodeCreation[" + name + "].parentPath",
            error->parentPath() == som::jsonStrOr(k, "parentPath"),
            error->parentPath());
    c.check("nodeCreation[" + name + "].childSegment",
            error->childSegment() == som::jsonStrOr(k, "childSegment"),
            error->childSegment());
  }

  std::vector<std::string> uncovered;
  for (som::SpecCreationCode code : som::kSpecCreationCodeAll) {
    if (coveredCodes.count(som::specCreationCodeName(code)) == 0) {
      uncovered.emplace_back(som::specCreationCodeName(code));
    }
  }
  c.check("nodeCreation.codeCoverage", uncovered.empty(),
          "uncovered: " + join(uncovered));
}

/* The stateful companion: one document, each add building on the last, then the
 * whole document state compared as canonical JSON. */
static void test_node_creation_script(Checker& c, const som::SpecModel& model) {
  som::SpecDocument doc = fresh_document();
  som::SpecNodeCreator creator(model, doc);
  som::JsonPtr steps = read_json("node_creation_script.json");
  std::size_t n = som::jsonArrayLen(steps);

  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef s = som::jsonArrayAt(steps, i);
    std::string op = som::jsonStrOr(s, "op");
    std::string tag = "nodeScript[" + std::to_string(i) + "]." + op;

    if (op == "add") {
      std::string path = creator.add(som::jsonStrOr(s, "parentPath"),
                                     som::jsonStrOr(s, "childSegment"),
                                     som::jsonStrOr(s, "itemId"),
                                     som::jsonAsI64(som::jsonGet(s, "month")),
                                     som::jsonAsI64(som::jsonGet(s, "day")));
      std::string wantPath = som::jsonStrOr(s, "expectPath");
      c.check(tag + ".path", path == wantPath, path + " != " + wantPath);
      std::string gotId = doc.itemSectionId(path);
      std::string wantId = json_opt_text(som::jsonGet(s, "expectId"));
      c.check(tag + ".id",
              (gotId.empty() ? std::string(kNullText) : gotId) == wantId,
              gotId + " != " + wantId);
    } else if (op == "addThrows") {
      std::string wantCode = som::jsonStrOr(s, "expectCode");
      try {
        creator.add(som::jsonStrOr(s, "parentPath"),
                    som::jsonStrOr(s, "childSegment"),
                    som::jsonStrOr(s, "itemId"), 3, 4);
        c.check(tag, false, "did not throw");
      } catch (const som::SpecCreationError& e) {
        c.check(tag, som::specCreationCodeName(e.code()) == wantCode,
                std::string(som::specCreationCodeName(e.code())) + " != " +
                    wantCode);
      }
    } else if (op == "finalState") {
      std::string got = som::documentJsonToCanonicalJson(doc.toJson());
      std::string want = som::documentJsonToCanonicalJson(
          som::documentJsonFromJson(som::jsonGet(s, "expect")));
      c.check(tag, got == want, byte_diff("finalState", got, want));
    } else {
      c.check(tag + ".unknown", false, op);
    }
  }
}

/* ---- assembling a document from fragments (spec_document_assembly) ------- */

/* assembly_cases.json, run like the Dart reference's `_runAssemblyCase`: each
 * fragment state is loaded into a fresh document, the ordered fragments are
 * assembled, and `ok`, the document (as toJson) and every overlap — store,
 * path, field, fragments and message — must match `expect`. */
static void test_assembly(Checker& c) {
  som::JsonPtr table = read_json("assembly_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  c.check("assembly.cases", n > 0, "no cases in assembly_cases.json");
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    const std::string label = "assembly[" + som::jsonStrOr(kase, "name") + "]";
    som::SpecAssemblyFragments fragments;
    som::JsonRef frags = som::jsonGet(kase, "fragments");
    for (std::size_t f = 0; f < som::jsonArrayLen(frags); f++) {
      som::JsonRef pair = som::jsonArrayAt(frags, f);
      const std::string* name = som::jsonAsStr(som::jsonArrayAt(pair, 0));
      fragments.emplace_back(
          name != nullptr ? *name : "",
          doc_from_state(som::documentJsonFromJson(som::jsonArrayAt(pair, 1))));
    }
    som::SpecDocumentAssembly result = som::SpecDocument::assemble(fragments);

    som::JsonRef expect = som::jsonGet(kase, "expect");
    bool wantOk = som::jsonBoolOr(expect, "ok");
    c.check(label + ".ok", result.ok() == wantOk,
            result.ok() ? "got true" : "got false");

    som::JsonRef wantDoc = som::jsonGet(expect, "document");
    if (wantDoc == nullptr || wantDoc->type == som::JsonType::Null) {
      c.check(label + ".document", !result.document.has_value(),
              "expected no document");
    } else if (!result.document) {
      c.check(label + ".document", false, "expected a document, got none");
    } else {
      std::string got = som::documentJsonToCanonicalJson(result.document->toJson());
      std::string want =
          som::documentJsonToCanonicalJson(som::documentJsonFromJson(wantDoc));
      c.check(label + ".document", got == want,
              byte_diff(label + ".document", got, want));
      if (i == 0) {
        // The first case's fragments were cut from `whole`: assembled, they
        // are the whole again.
        std::string whole = som::documentJsonToCanonicalJson(
            som::documentJsonFromJson(som::jsonGet(table, "whole")));
        c.check(label + ".whole", got == whole, "differs from `whole`");
      }
    }

    som::JsonRef wantOv = som::jsonGet(expect, "overlaps");
    std::size_t wn = som::jsonArrayLen(wantOv);
    c.check(label + ".overlaps", result.overlaps.size() == wn,
            "got " + std::to_string(result.overlaps.size()) + " want " +
                std::to_string(wn));
    for (std::size_t k = 0; k < wn && k < result.overlaps.size(); k++) {
      som::JsonRef w = som::jsonArrayAt(wantOv, k);
      const som::SpecAssemblyOverlap& o = result.overlaps[k];
      const std::string tag = label + ".overlaps[" + std::to_string(k) + "]";
      c.check(tag + ".store", o.store == som::jsonStrOr(w, "store"), o.store);
      c.check(tag + ".path", o.path == som::jsonStrOr(w, "path"), o.path);
      const std::string* wantField = som::jsonAsStr(som::jsonGet(w, "field"));
      bool fieldOk = wantField == nullptr ? !o.field.has_value()
                                          : (o.field && *o.field == *wantField);
      c.check(tag + ".field", fieldOk, o.field ? *o.field : "<null>");
      c.check(tag + ".fragments",
              o.fragments == json_str_list(som::jsonGet(w, "fragments")),
              join(o.fragments));
      c.check(tag + ".message", o.message() == som::jsonStrOr(w, "message"),
              o.message());
    }
  }
}

/* ---- moving a list item (SpecDocument::moveListItem, vsctsa44) ---------- */

/* Path pairs as a map, for comparing with a corpus object as a map
 * (order-insensitive, like the Dart reference's map equality). */
static std::map<std::string, std::string> pairs_map(const som::SpecPathPairs& p) {
  return std::map<std::string, std::string>(p.begin(), p.end());
}

static std::map<std::string, std::string> json_str_map(const som::JsonRef& v) {
  std::map<std::string, std::string> out;
  if (v == nullptr || v->type != som::JsonType::Object) {
    return out;
  }
  for (const auto& m : v->object) {
    const std::string* s = som::jsonAsStr(m.second);
    out[m.first] = s != nullptr ? *s : std::string("<non-string>");
  }
  return out;
}

static std::string map_text(const std::map<std::string, std::string>& m) {
  std::string out;
  for (const auto& kv : m) {
    out += kv.first + "=" + kv.second + ";";
  }
  return out;
}

/* A corpus JSON value in the YAML value model (objects as maps, scalars as
 * plain strings), for building and comparing review maps. */
static som::YamlPtr json_to_yaml(const som::JsonRef& v) {
  if (v != nullptr && v->type == som::JsonType::Object) {
    auto out = std::make_shared<som::YamlValue>(som::YamlType::Map);
    for (const auto& m : v->object) {
      out->mapSet(m.first, json_to_yaml(m.second));
    }
    return out;
  }
  if (v != nullptr && v->type == som::JsonType::Array) {
    auto out = std::make_shared<som::YamlValue>(som::YamlType::Seq);
    for (std::size_t i = 0; i < som::jsonArrayLen(v); i++) {
      out->seq.push_back(json_to_yaml(som::jsonArrayAt(v, i)));
    }
    return out;
  }
  auto out = std::make_shared<som::YamlValue>(som::YamlType::Str);
  const std::string* s = som::jsonAsStr(v);
  out->str = s != nullptr ? *s : std::string();
  out->plain = true;
  return out;
}

/* list_move_cases.json, run like the Dart reference's `_runListMoveCase`:
 * each case loads its state, moves the item, and the outcome — the moved
 * path, renames, pins and resulting document, or the refusal's name — must
 * match `expect`. Each review case re-keys a review map by the renames. */
static void test_list_move(Checker& c, const som::SpecModel& model) {
  som::JsonPtr table = read_json("list_move_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  std::size_t n = som::jsonArrayLen(cases);
  c.check("listMove.cases", n > 0, "no cases in list_move_cases.json");
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    const std::string label = "listMove[" + som::jsonStrOr(kase, "name") + "]";
    som::JsonRef state = som::jsonGet(kase, "state");
    som::SpecDocument doc = doc_from_state(som::documentJsonFromJson(state));
    som::JsonRef move = som::jsonGet(kase, "move");
    std::optional<long long> toIndex = opt_i64(move, "toIndex");
    const std::string* toListStr = som::jsonAsStr(som::jsonGet(move, "toList"));
    std::optional<std::string> toList;
    if (toListStr != nullptr) {
      toList = *toListStr;
    }

    std::optional<som::SpecListItemMove> result;
    std::string error;
    try {
      result = doc.moveListItem(model, som::jsonStrOr(move, "itemPath"),
                                toIndex.value_or(0), toList);
    } catch (const som::SomSectionIdError&) {
      error = "collision";
    } catch (const std::out_of_range&) {
      error = "range";
    } catch (const std::invalid_argument&) {
      error = "argument";
    }

    som::JsonRef expect = som::jsonGet(kase, "expect");
    bool wantOk = som::jsonBoolOr(expect, "ok");
    c.check(label + ".ok", result.has_value() == wantOk,
            result ? "got ok" : error);
    if (wantOk && result) {
      c.check(label + ".path", result->path == som::jsonStrOr(expect, "path"),
              result->path);
      c.check(label + ".renamed",
              pairs_map(result->renamed) ==
                  json_str_map(som::jsonGet(expect, "renamed")),
              map_text(pairs_map(result->renamed)));
      c.check(label + ".pinnedIds",
              pairs_map(result->pinnedIds) ==
                  json_str_map(som::jsonGet(expect, "pinnedIds")),
              map_text(pairs_map(result->pinnedIds)));
      std::string got = som::documentJsonToCanonicalJson(doc.toJson());
      std::string want = som::documentJsonToCanonicalJson(
          som::documentJsonFromJson(som::jsonGet(expect, "document")));
      c.check(label + ".document", got == want,
              byte_diff(label + ".document", got, want));
    } else if (!wantOk && !result) {
      c.check(label + ".error", error == som::jsonStrOr(expect, "error"),
              error);
      std::string got = som::documentJsonToCanonicalJson(doc.toJson());
      std::string want =
          som::documentJsonToCanonicalJson(som::documentJsonFromJson(state));
      c.check(label + ".unchanged", got == want,
              "a refused move changed the document");
    }
  }

  som::JsonRef reviewCases = som::jsonGet(table, "reviewCases");
  std::size_t rn = som::jsonArrayLen(reviewCases);
  c.check("listMove.reviewCases", rn > 0, "no reviewCases");
  for (std::size_t i = 0; i < rn; i++) {
    som::JsonRef kase = som::jsonArrayAt(reviewCases, i);
    const std::string tag =
        "listMove.review[" + som::jsonStrOr(kase, "name") + "]";
    som::SpecPathPairs renamed;
    som::JsonRef r = som::jsonGet(kase, "renamed");
    if (r != nullptr && r->type == som::JsonType::Object) {
      for (const auto& m : r->object) {
        const std::string* s = som::jsonAsStr(m.second);
        renamed.emplace_back(m.first, s != nullptr ? *s : std::string());
      }
    }
    som::YamlPtr review = json_to_yaml(som::jsonGet(kase, "review"));
    som::YamlPtr want = json_to_yaml(som::jsonGet(kase, "expect"));
    som::YamlPtr got = som::specYamlRekeyReview(*review, renamed);
    std::string gt, wt;
    som::specYamlWriteReviewPass(gt, *got);
    som::specYamlWriteReviewPass(wt, *want);
    c.check(tag, got->map.size() == want->map.size() && gt == wt,
            byte_diff(tag, gt, wt));
  }
}

/* ---- review annotations (spec_review_annotations, SOM §11.9) ------------- */

/* `v` as JSON text with every object's keys byte-sorted, so two values compare
 * structurally (JSON equality) by comparing their texts. */
static std::string json_canon(const som::JsonRef& v) {
  if (v != nullptr && v->type == som::JsonType::Array) {
    std::string b = "[";
    for (std::size_t i = 0; i < v->array.size(); i++) {
      if (i > 0) b += ",";
      b += json_canon(v->array[i]);
    }
    return b + "]";
  }
  if (v == nullptr || v->type != som::JsonType::Object) return json_text(v);
  std::vector<std::pair<std::string, som::JsonPtr>> members = v->object;
  std::stable_sort(members.begin(), members.end(),
                   [](const auto& a, const auto& b) { return a.first < b.first; });
  std::string b = "{";
  for (std::size_t i = 0; i < members.size(); i++) {
    if (i > 0) b += ",";
    b += som::jsonEncodeStr(members[i].first) + ":" + json_canon(members[i].second);
  }
  return b + "}";
}

/* The canonical form of JSON `text` this runner wrote. */
static std::string json_text_canon(const std::string& text) {
  std::string err;
  som::JsonPtr v = som::jsonParse(text, &err);
  return v == nullptr ? "(unparsable: " + err + ")" : json_canon(v);
}

static std::string doc_canonical(const som::SpecDocument& doc) {
  return som::documentJsonToCanonicalJson(doc.toJson());
}

static std::string state_canonical(const som::JsonRef& v) {
  return som::documentJsonToCanonicalJson(som::documentJsonFromJson(v));
}

static std::optional<std::string> json_opt_str(const som::JsonRef& o,
                                               const std::string& key) {
  const std::string* s = som::jsonAsStr(som::jsonGet(o, key));
  return s ? std::optional<std::string>(*s) : std::nullopt;
}

static som::SpecQuestionDraft draft_from_json(const som::JsonRef& j) {
  som::SpecQuestionDraft d;
  d.id = som::jsonStrOr(j, "id");
  d.topic = som::jsonStrOr(j, "topic");
  d.text = som::jsonStrOr(j, "text");
  som::JsonRef opts = som::jsonGet(j, "options");
  for (std::size_t i = 0; i < som::jsonArrayLen(opts); i++) {
    const std::string* s = som::jsonAsStr(som::jsonArrayAt(opts, i));
    d.options.push_back(s ? *s : "");
  }
  d.recommendation = som::jsonStrOr(j, "recommendation");
  d.assumption = som::jsonStrOr(j, "assumption");
  d.starred = som::jsonBoolOr(j, "starred");
  return d;
}

/* Runs one op and returns its result as canonical JSON text — `{"error":true}`
 * when it raised SpecReviewAnnotationError. A `strip` result is returned as
 * the stripped document's canonical form (compared against the expected
 * state's). */
static std::string run_annotation_op(const som::SpecModel& model,
                                     const som::SomMetaTree& tree,
                                     som::SpecReviewAnnotations& api,
                                     const som::JsonRef& op) {
  const std::string name = som::jsonStrOr(op, "op");
  const long long floor = som::jsonAsI64(som::jsonGet(op, "floor")).value_or(0);
  try {
    if (name == "list") {
      std::string b = "[";
      const auto all = api.list();
      for (std::size_t i = 0; i < all.size(); i++) {
        if (i > 0) b += ",";
        b += all[i].toJson();
      }
      return json_text_canon(b + "]");
    }
    if (name == "counts") return json_text_canon(api.counts().toJson());
    if (name == "nextId") return som::jsonEncodeStr(api.nextCommentId(floor));
    if (name == "assignIds") {
      std::string b = "[";
      const auto ids = api.assignCommentIds(floor);
      for (std::size_t i = 0; i < ids.size(); i++) {
        if (i > 0) b += ",";
        b += som::jsonEncodeStr(ids[i]);
      }
      return b + "]";
    }
    const long long afterParagraph =
        som::jsonAsI64(som::jsonGet(op, "afterParagraph")).value_or(0);
    if (name == "insertComment") {
      return som::jsonEncodeStr(api.insertComment(
          som::jsonStrOr(op, "path"), json_opt_str(op, "field"), afterParagraph,
          som::jsonStrOr(op, "text"), json_opt_str(op, "author"),
          json_opt_str(op, "id")));
    }
    if (name == "insertQuestion") {
      api.insertQuestion(som::jsonStrOr(op, "path"), json_opt_str(op, "field"),
                         afterParagraph,
                         draft_from_json(som::jsonGet(op, "question")));
      return "null";
    }
    if (name == "insertQuestionAfterComment") {
      api.insertQuestionAfterComment(
          som::jsonStrOr(op, "commentId"),
          draft_from_json(som::jsonGet(op, "question")));
      return "null";
    }
    if (name == "setAnswer") {
      api.setAnswer(som::jsonStrOr(op, "id"), som::jsonStrOr(op, "answer"));
      return "null";
    }
    if (name == "editComment") {
      api.editComment(som::jsonStrOr(op, "id"), som::jsonStrOr(op, "text"));
      return "null";
    }
    if (name == "resolve") {
      api.resolve(som::jsonStrOr(op, "id"));
      return "null";
    }
    if (name == "applyMark") {
      api.applyMark(som::jsonStrOr(op, "path"), json_opt_str(op, "field"),
                    som::jsonAsI64(som::jsonGet(op, "index")).value_or(0),
                    som::jsonAsBool(som::jsonGet(op, "accept")).value_or(true));
      return "null";
    }
    if (name == "strip") return doc_canonical(api.stripped());
    if (name == "roundTrip") {
      const std::string before = doc_canonical(api.doc());
      bool yamlOk = false;
      std::string err;
      auto yaml = som::encodeYaml(api.doc(), tree, MODEL_VERSION, &err);
      if (yaml.has_value()) {
        som::SpecYamlContents contents;
        if (som::decodeYaml(*yaml, tree, &contents, &err)) {
          yamlOk = doc_canonical(contents.document) == before;
        }
      }
      const std::string md =
          som::markdownExportRoot(model, api.doc(), model.roots[0]);
      som::SpecMarkdownImport imported = som::SpecDocument::fromMarkdown(md, model);
      const bool mdOk = imported.rejections().empty() &&
                        doc_canonical(imported.document) == before;
      return json_text_canon(std::string("{\"yaml\":") +
                             (yamlOk ? "true" : "false") + ",\"markdown\":" +
                             (mdOk ? "true" : "false") + "}");
    }
  } catch (const som::SpecReviewAnnotationError&) {
    return json_text_canon("{\"error\":true}");
  }
  std::fprintf(stderr, "unknown annotation op %s\n", name.c_str());
  std::exit(2);
}

/* annotation_cases.json, run like the Dart reference's `_runAnnotationCase`:
 * every op runs in order on one document loaded from `state`; each op's
 * result and the final state must equal `expect` (JSON equality). */
static void test_annotations(Checker& c, const som::SpecModel& model,
                             const som::SomMetaTree& tree) {
  som::JsonPtr table = read_json("annotation_cases.json");
  som::JsonRef cases = som::jsonGet(table, "cases");
  const std::size_t n = som::jsonArrayLen(cases);
  c.check("annotations.cases", n > 0, "no cases in annotation_cases.json");
  for (std::size_t i = 0; i < n; i++) {
    som::JsonRef kase = som::jsonArrayAt(cases, i);
    const std::string label = "annotations[" + som::jsonStrOr(kase, "name") + "]";
    som::SpecDocument doc =
        doc_from_state(som::documentJsonFromJson(som::jsonGet(kase, "state")));
    som::SpecReviewAnnotations api(doc, json_opt_str(kase, "qualifier"));
    som::JsonRef ops = som::jsonGet(kase, "ops");
    som::JsonRef expect = som::jsonGet(kase, "expect");
    som::JsonRef wantResults = som::jsonGet(expect, "results");
    const std::size_t on = som::jsonArrayLen(ops);
    c.check(label + ".results", on == som::jsonArrayLen(wantResults),
            "got " + std::to_string(on) + " want " +
                std::to_string(som::jsonArrayLen(wantResults)));
    for (std::size_t k = 0; k < on; k++) {
      som::JsonRef op = som::jsonArrayAt(ops, k);
      som::JsonRef want = som::jsonArrayAt(wantResults, k);
      const std::string opName = som::jsonStrOr(op, "op");
      const std::string got = run_annotation_op(model, tree, api, op);
      const std::string w =
          opName == "strip" ? state_canonical(want) : json_canon(want);
      const std::string tag =
          label + ".op[" + std::to_string(k) + ":" + opName + "]";
      c.check(tag, got == w, byte_diff(tag, got, w));
    }
    const std::string got = doc_canonical(doc);
    const std::string w = state_canonical(som::jsonGet(expect, "state"));
    c.check(label + ".state", got == w, byte_diff(label + ".state", got, w));
  }
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
  test_editability(c);
  test_state_round_trip(c);
  test_yaml_encode(c, *tree);
  test_yaml_decode_round_trip(c, *tree);
  test_yaml_review(c, *model, *tree);
  test_markdown_export(c, *model);
  test_markdown_round_trip(c, *model);
  test_markdown_memory_landing(c, *model);
  test_markdown_import_rejections(c, *model);
  test_markdown_apply(c, *model);
  test_reflection(c, *model);
  test_validation(c, *model);
  test_operations(c);
  test_editor(c, *model);
  test_section_id(c);
  test_serialization_order(c);
  test_docspecs(c);
  test_docspecs_replace(c);
  test_docspecs_path(c, *model);
  test_text_pattern(c);
  test_query(c, *model);
  test_projection(c, *model);
  test_codespecs_extract(c, *model);
  test_codespecs_records(c);
  test_codespecs_gate(c);
  test_cursor(c, *model);
  test_node_creation_cases(c, *model);
  test_node_creation_script(c, *model);
  test_assembly(c);
  test_list_move(c, *model);
  test_annotations(c, *model, *tree);

  return c.finish();
}
