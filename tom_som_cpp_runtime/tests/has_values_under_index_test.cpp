/* SpecDocument::hasValuesUnder answers from a prefix index rather than a scan
 * of every stored key. The markdown emitter, the validator and the query
 * engine ask it once per model node, so a scan made rendering a large
 * specification quadratic.
 *
 * VI-1 holds the index to the scan it replaces, across every mutator (and
 * across copy / move), so a mutation that forgets to drop the index fails
 * here. VI-2 guards the complexity itself.
 *
 * moveListItem needs a model; the shared corpus model is read from the sibling
 * tom_som_conformance package, as docspecs_validator_test does.
 */
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"

namespace {

std::size_t g_passed = 0;
std::size_t g_failed = 0;

void check(const std::string& name, bool cond) {
  if (cond) {
    g_passed++;
  } else {
    g_failed++;
    std::printf("  FAIL: %s\n", name.c_str());
  }
}

/* The predicate the index must reproduce: a stored key equal to `query`, or
 * continuing it after a `/` or a `-`. */
bool scan(const som::SpecDocument& d, const std::string& query) {
  auto under = [&query](const std::string& k) {
    return k == query || k.rfind(query + "/", 0) == 0 ||
           k.rfind(query + "-", 0) == 0;
  };
  const som::DocumentJson j = d.toJson();
  for (const auto& kv : j.content) if (under(kv.first)) return true;
  for (const auto& kv : j.forms) if (under(kv.first)) return true;
  for (const auto& kv : j.lists) if (under(kv.first)) return true;
  for (const auto& kv : j.headlines) if (under(kv.first)) return true;
  for (const auto& kv : j.codeSpecs) if (under(kv.first)) return true;
  return false;
}

const std::vector<std::string> kProbes = {
    "DEMO",         "DEMO/TTL",     "DEMO/TT",           "DEMO/SUM",
    "DEMO/DET",     "DEMO/items",   "DEMO/items-1",      "DEMO/items-1/label",
    "DEMO/items-2", "DEMO/items-3", "DEMO/REF-LST",      "DEMO/REF",
    "DEMO/CARD-LST-1", "OTHER",     "",
};

void expectAgrees(const som::SpecDocument& d, const std::string& when) {
  for (const std::string& p : kProbes) {
    check("VI-1 " + when + ": \"" + p + "\"", d.hasValuesUnder(p) == scan(d, p));
  }
}

std::string readFile(const std::string& path) {
  std::ifstream f(path, std::ios::binary);
  if (!f) {
    std::fprintf(stderr, "read %s: cannot open\n", path.c_str());
    std::exit(2);
  }
  std::ostringstream ss;
  ss << f.rdbuf();
  return ss.str();
}

void testEquivalence() {
  std::string err;
  auto model = som::SpecModel::fromJsonStr(
      readFile("../tom_som_conformance/corpus/model.meta.json"), &err);
  if (model == nullptr) {
    std::fprintf(stderr, "load model: %s\n", err.c_str());
    std::exit(2);
  }

  som::SpecDocument d;
  expectAgrees(d, "empty");
  d.setContent("DEMO/TTL", "Hello");
  expectAgrees(d, "setContent");
  d.setHeadline("DEMO/SUM", "Summary");
  expectAgrees(d, "setHeadline");
  d.setCodeSpec("DEMO/DET", "a.b");
  expectAgrees(d, "setCodeSpec");
  d.setFormField("DEMO/CARD-LST-1/content", "note", "x");
  expectAgrees(d, "setFormField");
  const std::string item = d.addListItem("DEMO/items");
  d.setContent(item + "/label", "First");
  d.addListItem("DEMO/items");
  expectAgrees(d, "addListItem");
  d.addListItemWithSectionId("DEMO/items", "ITEM-C");
  expectAgrees(d, "addListItemWithSectionId");
  d.setItemSectionId(item, "ITEM-A");
  expectAgrees(d, "setItemSectionId");

  d.moveListItem(*model, "DEMO/items-3", 0);
  expectAgrees(d, "moveListItem");
  d.moveListItem(*model, "DEMO/items-1", 2);
  expectAgrees(d, "moveListItem back");

  d.setContent("DEMO/TTL", "");
  expectAgrees(d, "setContent to empty");
  d.setFormField("DEMO/CARD-LST-1/content", "note", "");
  expectAgrees(d, "setFormField to empty");
  d.setHeadline("DEMO/SUM", "");
  expectAgrees(d, "setHeadline to empty");
  d.setCodeSpec("DEMO/DET", "");
  expectAgrees(d, "setCodeSpec to empty");
  d.setHeadline("DEMO/SUM", "Summary");
  d.setCodeSpec("DEMO/DET", "a.b");
  expectAgrees(d, "set again");

  d.removeListItem("DEMO/items-1");
  expectAgrees(d, "removeListItem");
  d.removeValuesUnder("DEMO/SUM");
  expectAgrees(d, "removeValuesUnder");

  // Copy / move: neither side may answer from an index built for other stores.
  som::SpecDocument copy = d;
  expectAgrees(copy, "copy-constructed");
  copy.setContent("OTHER/X", "y");
  expectAgrees(copy, "copy mutated");
  expectAgrees(d, "original after copy mutated");
  copy = d;
  expectAgrees(copy, "copy-assigned");
  som::SpecDocument moved = std::move(copy);
  expectAgrees(moved, "move-constructed");
  expectAgrees(copy, "moved-from");  // NOLINT(bugprone-use-after-move)
  som::SpecDocument other;
  other.setContent("OTHER/Z", "z");
  expectAgrees(other, "other before move-assign");
  other = std::move(moved);
  expectAgrees(other, "move-assigned");

  som::DocumentJson j;
  j.content["DEMO/REF-LST-1"] = "spec";
  som::DocListEntry e;
  e.seq = 1;
  e.items = {"DEMO/REF-LST-1"};
  j.lists["DEMO/REF-LST"] = e;
  d.loadJson(j);
  expectAgrees(d, "loadJson");
}

void testComplexity() {
  // 20,000 stored values and 20,000 queries. A per-query scan costs 4 * 10^8
  // key comparisons; the index answers in milliseconds. The bound is generous,
  // so only the complexity class can fail it.
  const int n = 20000;
  som::SpecDocument d;
  for (int i = 0; i < n; i++) {
    d.setContent("ROOT/S" + std::to_string(i / 100) + "/F" + std::to_string(i),
                 "v" + std::to_string(i));
  }
  const auto start = std::chrono::steady_clock::now();
  int hits = 0;
  for (int i = 0; i < n; i++) {
    const std::string s = "ROOT/S" + std::to_string(i / 100);
    if (d.hasValuesUnder(s + "/F" + std::to_string(i))) hits++;
    if (d.hasValuesUnder(s + "/G" + std::to_string(i))) hits--;
  }
  const auto elapsed = std::chrono::steady_clock::now() - start;
  check("VI-2 hits", hits == n);
  check("VI-2 under 2 s", elapsed < std::chrono::seconds(2));
}

}  // namespace

int main() {
  testEquivalence();
  testComplexity();
  std::printf("has_values_under_index_test: %zu passed, %zu failed\n", g_passed,
              g_failed);
  return g_failed == 0 ? 0 : 1;
}
