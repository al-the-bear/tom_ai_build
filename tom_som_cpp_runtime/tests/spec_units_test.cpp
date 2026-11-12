/* SOM §11.2 `units`: the generation units a section goes to. Kept exactly as
 * `codeSpec` is — a sparse store by section path, the Markdown heading key
 * `units="a,b"` after `codeSpec`, the YAML key `units` after `codeSpec`, the
 * facade's `units()` / `setUnits()`, the snapshot's `units` map — and checked
 * by the instance tier's phase 8.
 *
 * The port of the Dart reference's `test/spec_units_test.dart`. Two of its
 * cases have no counterpart here because this runtime has no such surface:
 * the undo snapshot (`captureState` / `restoreState` / fingerprint) and the
 * path normalizer (`installPathNormalizer`).
 *
 * The shared corpus model (the demo root with the generation-unit register
 * `DEMO/DLV-LST`, classes `Deliverable` / `DeliverableRoute`) is read from the
 * sibling tom_som_conformance package, as docspecs_validator_test does.
 */
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <memory>
#include <sstream>
#include <string>
#include <tuple>
#include <vector>

#include "som_facade.hpp"
#include "som_json.hpp"
#include "spec_document.hpp"
#include "spec_document_assembly.hpp"
#include "spec_document_markdown.hpp"
#include "spec_document_yaml.hpp"
#include "spec_meta.hpp"
#include "spec_meta_bridge.hpp"
#include "spec_model.hpp"
#include "spec_review_merge.hpp"
#include "spec_validator.hpp"

namespace {

int g_checks = 0;
int g_failures = 0;

void check(const std::string& name, bool cond, const std::string& detail = "") {
  ++g_checks;
  if (cond) {
    return;
  }
  ++g_failures;
  if (!detail.empty()) {
    std::fprintf(stderr, "FAIL %s: %s\n", name.c_str(), detail.c_str());
  } else {
    std::fprintf(stderr, "FAIL %s\n", name.c_str());
  }
}

[[noreturn]] void fatal(const std::string& what, const std::string& err) {
  std::fprintf(stderr, "fatal: %s: %s\n", what.c_str(), err.c_str());
  std::exit(2);
}

bool contains(const std::string& hay, const std::string& needle) {
  return hay.find(needle) != std::string::npos;
}

std::string readFile(const std::string& path) {
  std::ifstream f(path, std::ios::binary);
  if (!f) {
    fatal("read " + path, "cannot open");
  }
  std::ostringstream ss;
  ss << f.rdbuf();
  return ss.str();
}

std::string joined(const std::vector<std::string>& v) {
  std::string out;
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) out += ",";
    out += v[i];
  }
  return out;
}

std::unique_ptr<som::SpecModel> g_model;
std::unique_ptr<som::SomMetaTree> g_tree;

/* A register declaring `u_a` and `u_b`, both building something. */
som::SpecDocument registerDoc() {
  som::SpecDocument d;
  const std::string a = d.addListItem("DEMO/DLV-LST");
  d.setFormField(a + "/content", "unitId", "u_a");
  d.setFormField(a + "/content", "component", "ARCM-COMP-A");
  const std::string b = d.addListItem("DEMO/DLV-LST");
  d.setFormField(b + "/content", "unitId", "u_b");
  d.setFormField(b + "/content", "deploymentTarget", "DEPTAR-DEPL-B");
  return d;
}

std::string canonical(const som::SpecDocument& d) {
  return som::documentJsonToCanonicalJson(d.toJson());
}

std::string encode(const som::SpecDocument& d) {
  std::string err;
  auto out = som::encodeYaml(d, *g_tree, "1.0", &err);
  if (!out.has_value()) {
    fatal("encode", err);
  }
  return *out;
}

som::SpecDocument decode(const std::string& yaml) {
  std::string err;
  som::SpecYamlContents out;
  if (!som::decodeYaml(yaml, *g_tree, &out, &err)) {
    fatal("decode", err);
  }
  return std::move(out.document);
}

/* ---- the store ----------------------------------------------------------- */

void testStore() {
  {
    som::SpecDocument d;
    check("store.unsetIsNull", d.unitsOpt("DEMO/TTL") == nullptr);
    d.setUnits("DEMO/TTL", "u_a,u_b");
    check("store.read", d.units("DEMO/TTL") == "u_a,u_b");
    check("store.paths", joined(d.unitsPaths()) == "DEMO/TTL");
    check("store.notEmpty", !d.isEmpty());
    check("store.hasValuesUnder", d.hasValuesUnder("DEMO"));
    d.setUnits("DEMO/TTL", "");
    check("store.emptyClears", d.unitsOpt("DEMO/TTL") == nullptr);
    check("store.pathsCleared", d.unitsPaths().empty());
    check("store.emptyAgain", d.isEmpty());
  }
  {
    // The snapshot carries `units` beside (after) `codeSpecs`, sorted.
    som::SpecDocument d;
    d.setCodeSpec("DEMO/TTL", "A");
    d.setUnits("DEMO/TTL", "u_b");
    d.setUnits("DEMO/SUM", "u_a");
    const std::string json = canonical(d);
    check("snapshot.json",
          json == "{\"codeSpecs\":{\"DEMO/TTL\":\"A\"},\"units\":{\"DEMO/SUM\":"
                  "\"u_a\",\"DEMO/TTL\":\"u_b\"}}",
          json);
    std::string err;
    som::JsonPtr parsed = som::jsonParse(json, &err);
    if (parsed == nullptr) {
      fatal("snapshot parse", err);
    }
    som::SpecDocument back;
    back.loadJson(som::documentJsonFromJson(parsed));
    check("snapshot.roundTrip", canonical(back) == json, canonical(back));
    // No units, no key.
    check("snapshot.noKey",
          !contains(canonical(som::SpecDocument()), "units"));
    // An empty value in a snapshot is no units at all.
    som::DocumentJson j;
    j.units["DEMO/TTL"] = "";
    som::SpecDocument loaded;
    loaded.loadJson(j);
    check("snapshot.emptySkipped", loaded.unitsPaths().empty());
  }
  {
    som::SpecDocument d;
    d.setUnits("DEMO/notes", "u_a");
    d.setUnits("DEMO/notes/NOTE-BDY", "u_b");
    d.setUnits("DEMO/TTL", "u_a");
    d.removeValuesUnder("DEMO/notes");
    check("store.removeValuesUnder", joined(d.unitsPaths()) == "DEMO/TTL",
          joined(d.unitsPaths()));
  }
  {
    // Units move with their list item.
    som::SpecDocument d;
    const std::string first = d.addListItem("DEMO/items");
    const std::string second = d.addListItem("DEMO/items");
    d.setContent(first + "/label", "one");
    d.setContent(second + "/label", "two");
    d.setUnits(second, "u_a");
    d.moveListItem(*g_model, second, 0);
    check("store.moveListItem", d.units("DEMO/items-1") == "u_a");
    check("store.moveListItemOld", d.unitsOpt("DEMO/items-2") == nullptr);
  }
  {
    // removeListItem purges the item's units.
    som::SpecDocument d;
    const std::string item = d.addListItem("DEMO/items");
    d.setUnits(item, "u_a");
    d.removeListItem(item);
    check("store.removeListItem", d.unitsPaths().empty());
  }
}

/* ---- the facade ---------------------------------------------------------- */

void testFacade() {
  som::SpecDocument d;
  som::SomNode node(d, "DEMO/TTL");
  check("facade.unset", node.units().empty());
  node.setUnits("u_a");
  check("facade.write", d.units("DEMO/TTL") == "u_a");
  check("facade.read", node.units() == "u_a");
  node.setUnits("");
  check("facade.clear", node.units().empty() && d.unitsPaths().empty());
}

/* ---- Markdown ------------------------------------------------------------ */

void testMarkdown() {
  {
    som::SpecDocument d;
    d.setContent("DEMO/TTL", "Hello");
    d.setCodeSpec("DEMO/TTL", "DemoTitle");
    d.setUnits("DEMO/TTL", "u_a,u_b");
    d.setContent("DEMO/SUM", "Sum");
    d.setUnits("DEMO/SUM", "u_a");
    const std::string md = d.toMarkdown(*g_model);
    check("md.emitAfterCodeSpec",
          contains(md,
                   "## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> "
                   "Document Title\n"),
          md);
    check("md.emitAlone", contains(md, "## <!--[SUM] units=\"u_a\"--> Summary\n"),
          md);
  }
  {
    const std::string md =
        "# <!--[DEMO] units=u_root--> Demo Document\n\n"
        "## <!--[TTL] codeSpec=\"DemoTitle\" units=\"u_a,u_b\"--> Title\n\n"
        "Hello\n\n"
        "## <!--[SUM] units='u_c'--> Summary\n\n"
        "Sum\n\n"
        "## <!--[CNT] codeSpec=\"units=no\"--> Count\n\n"
        "3\n";
    som::SpecMarkdownResult r = som::markdownParse(*g_model, md);
    check("md.parse.clean", r.rejections.empty());
    const auto& u = r.staged.units;
    check("md.parse.units",
          u.size() == 3 && u.count("DEMO") && u.at("DEMO") == "u_root" &&
              u.count("DEMO/TTL") && u.at("DEMO/TTL") == "u_a,u_b" &&
              u.count("DEMO/SUM") && u.at("DEMO/SUM") == "u_c");
    check("md.parse.codeSpec", r.staged.codeSpecs.count("DEMO/TTL") &&
                                   r.staged.codeSpecs.at("DEMO/TTL") ==
                                       "DemoTitle");
    // A `units=` inside a quoted codeSpec value is not the key.
    check("md.parse.quotedNotKey",
          r.staged.codeSpecs.count("DEMO/CNT") &&
              r.staged.codeSpecs.at("DEMO/CNT") == "units=no" &&
              u.count("DEMO/CNT") == 0);
  }
  {
    // Both keys read as the pattern `"…"|'…'|[^,\s>]+` reads them: a quote
    // that is never closed is a bare value, and an occurrence with no value
    // is passed over.
    const std::string md =
        "# <!--[DEMO] codeSpec=, codeSpec=Later--> Demo Document\n\n"
        "## <!--[TTL] codeSpec=\"Open--> Title\n\n"
        "Hello\n\n"
        "## <!--[SUM] units=\"u_x--> Summary\n\n"
        "Sum\n";
    som::SpecMarkdownResult r = som::markdownParse(*g_model, md);
    const auto& c = r.staged.codeSpecs;
    check("md.parse.codeSpec.skipsEmpty",
          c.count("DEMO") && c.at("DEMO") == "Later");
    check("md.parse.codeSpec.unclosedIsBare",
          c.count("DEMO/TTL") && c.at("DEMO/TTL") == "\"Open");
    check("md.parse.units.unclosedIsBare",
          r.staged.units.count("DEMO/SUM") &&
              r.staged.units.at("DEMO/SUM") == "\"u_x");
  }
  {
    som::SpecDocument d = registerDoc();
    d.setContent("DEMO/TTL", "Hello");
    d.setCodeSpec("DEMO/TTL", "DemoTitle");
    d.setUnits("DEMO/TTL", "u_a");
    d.setContent("DEMO/notes/NOTE-BDY", "Body");
    d.setUnits("DEMO/notes", "u_a,u_b");
    const std::string md = d.toMarkdown(*g_model);
    som::SpecDocument back = som::SpecDocument::fromMarkdown(md, *g_model).document;
    check("md.roundTrip.TTL", back.units("DEMO/TTL") == "u_a");
    check("md.roundTrip.notes", back.units("DEMO/notes") == "u_a,u_b");
    check("md.roundTrip.bytes", back.toMarkdown(*g_model) == md);
  }
  {
    // applyMarkdownResult overwrites, clears and keeps units.
    som::SpecDocument d;
    d.setUnits("DEMO/TTL", "stale");
    d.setUnits("DEMO/SUM", "stale");
    d.setUnits("OTHER/kept", "kept");
    const std::string md =
        "# <!--[DEMO]--> Demo Document\n\n"
        "## <!--[TTL] units=\"u_a\"--> Document Title\n\nHello\n";
    d.applyMarkdownResult(som::markdownParse(*g_model, md));
    const std::string json = canonical(d);
    check("md.apply",
          contains(json,
                   "\"units\":{\"DEMO/TTL\":\"u_a\",\"OTHER/kept\":\"kept\"}"),
          json);
  }
}

/* ---- YAML ---------------------------------------------------------------- */

const char* kClashModelJson = R"({
  "modelVersion": 1,
  "roots": [{"type": "R", "title": "R", "sectionId": "R"}],
  "classes": {
    "R": {
      "name": "R",
      "sectionId": "R",
      "fields": [
        {"name": "units", "kind": "content"},
        {"name": "shape", "kind": "form", "sectionId": "SHP",
         "formFields": [{"name": "units", "label": "Units", "type": "String"}]}
      ]
    }
  }
})";

void testYaml() {
  {
    som::SpecDocument d;
    d.setContent("DEMO/TTL", "Hello");
    d.setHeadline("DEMO/TTL", "Title");
    d.setCodeSpec("DEMO/TTL", "DemoTitle");
    d.setUnits("DEMO/TTL", "u_a");
    d.setContent("DEMO/CNT", "3");
    d.setUnits("DEMO/CNT", "u_b");
    d.setContent("DEMO/notes/NOTE-BDY", "Body");
    d.setUnits("DEMO/notes", "u_a,u_b");
    const std::string yaml = encode(d);
    check("yaml.scalarPromotion",
          contains(yaml,
                   "    TTL title:\n"
                   "      headline: |2-\n        Title\n"
                   "      codeSpec: |2-\n        DemoTitle\n"
                   "      units: |2-\n        u_a\n"
                   "      content: |2-\n        Hello\n"),
          yaml);
    // A non-text scalar keeps its plain content inside the mapping.
    check("yaml.plainScalar",
          contains(yaml,
                   "    CNT count:\n      units: |2-\n        u_b\n"
                   "      content: 3\n"),
          yaml);
    check("yaml.section",
          contains(yaml, "    NOTE notes:\n      units: |2-\n        u_a,u_b\n"),
          yaml);
    som::SpecDocument back = decode(yaml);
    check("yaml.roundTrip.json", canonical(back) == canonical(d),
          canonical(back));
    check("yaml.roundTrip.bytes", encode(back) == yaml);
  }
  {
    // Units on a form, a list container and a list item round-trip.
    som::SpecDocument d = registerDoc();
    d.setFormField("DEMO/DET", "owner", "Bob");
    d.setUnits("DEMO/DET", "u_a");
    d.setUnits("DEMO/DLV-LST", "u_b");
    d.setUnits("DEMO/DLV-LST-1", "u_a");
    const std::string tagItem = d.addListItem("DEMO/META/tags");
    d.setContent(tagItem, "on");
    d.setUnits(tagItem, "u_b");
    const std::string yaml = encode(d);
    som::SpecDocument back = decode(yaml);
    check("yaml.formListItem.json", canonical(back) == canonical(d),
          canonical(back) + " vs " + canonical(d));
    check("yaml.formListItem.bytes", encode(back) == yaml);
  }
  {
    // Refuses units where a child or form field is named `units`.
    std::string err;
    auto clashModel = som::SpecModel::fromJsonStr(kClashModelJson, &err);
    if (clashModel == nullptr) {
      fatal("clash model", err);
    }
    auto clashTree = som::somBuildMetaTree(*clashModel, "", &err);
    if (clashTree == nullptr) {
      fatal("clash tree", err);
    }
    som::SpecDocument own;
    own.setUnits("R", "u_a");
    std::string ownErr;
    auto refused = som::encodeYaml(own, *clashTree, "1.0", &ownErr);
    check("yaml.clash.child",
          !refused.has_value() &&
              contains(ownErr, "also serializes as key `units`"),
          ownErr);
    som::SpecDocument form;
    form.setFormField("R/SHP", "units", "3");
    form.setUnits("R/SHP", "u_a");
    std::string formErr;
    auto refusedForm = som::encodeYaml(form, *clashTree, "1.0", &formErr);
    check("yaml.clash.formField",
          !refusedForm.has_value() &&
              contains(formErr, "field literally named `units`"),
          formErr);
  }
  {
    // A list item may not be keyed `units`.
    som::SpecDocument d;
    d.addListItemWithSectionId("DEMO/DLV-LST", "units");
    std::string err;
    auto out = som::encodeYaml(d, *g_tree, "1.0", &err);
    check("yaml.itemKeyedUnits", !out.has_value(), err);
  }
  {
    // The scalar-promotion mapping names `units` among its allowed keys.
    std::string yaml = encode([] {
      som::SpecDocument d;
      d.setContent("DEMO/TTL", "Hello");
      d.setUnits("DEMO/TTL", "u_a");
      return d;
    }());
    const std::string from = "      units: |2-\n        u_a\n";
    yaml.replace(yaml.find(from), from.size(), "      bogus: x\n");
    std::string err;
    som::SpecYamlContents out;
    check("yaml.promotion.unknownKey",
          !som::decodeYaml(yaml, *g_tree, &out, &err) &&
              contains(err, "`headline`/`codeSpec`/`units`/`content`"),
          err);
  }
}

/* ---- assembly and review merge ------------------------------------------- */

void testAssemblyAndMerge() {
  {
    som::SpecDocument a;
    a.setUnits("DEMO/TTL", "u_a");
    som::SpecDocument b;
    b.setUnits("DEMO/SUM", "u_b");
    som::SpecDocumentAssembly ok = som::SpecDocument::assemble({{"a", a}, {"b", b}});
    check("assembly.ok", ok.ok() && ok.document.has_value() &&
                             ok.document->units("DEMO/SUM") == "u_b");
    som::SpecDocument c;
    c.setUnits("DEMO/TTL", "u_b");
    som::SpecDocumentAssembly clash =
        som::SpecDocument::assemble({{"a", a}, {"c", c}});
    check("assembly.clash",
          !clash.ok() && clash.overlaps.size() == 1 &&
              clash.overlaps[0].store == "units" &&
              clash.overlaps[0].path == "DEMO/TTL");
  }
  {
    // A review merge carries the units of an item a copy added.
    som::SpecDocument base;
    const std::string first = base.addListItem("DEMO/items");
    base.setContent(first + "/label", "one");
    som::SpecDocument copy;
    copy.loadJson(base.toJson());
    const std::string added = copy.addListItem("DEMO/items");
    copy.setContent(added + "/label", "two");
    copy.setUnits(added, "u_a");
    const som::SpecReviewMember member{"alice", "Alice", ""};
    som::SpecReviewMergeOptions options;
    options.team = {member};
    options.date = "2026-11-12";
    options.author = "alice";
    auto result = som::mergeReviews(*g_model, base, {{member, copy}}, options);
    const std::vector<std::string> items =
        result.merged.listItems("DEMO/items");
    check("merge.items", items.size() == 2, joined(items));
    check("merge.units",
          !items.empty() && result.merged.units(items.back()) == "u_a",
          canonical(result.merged));
  }
}

/* ---- validation phase 8 -------------------------------------------------- */

using Finding = std::tuple<std::string, std::string, std::string>;

std::vector<Finding> validate(const som::SpecDocument& d) {
  std::vector<Finding> out;
  for (const som::SpecValidationError& e : som::validateDocument(*g_model, d)) {
    out.emplace_back(e.path, e.code, e.message);
  }
  return out;
}

std::string show(const std::vector<Finding>& fs) {
  std::string out;
  for (const Finding& f : fs) {
    out += "\n  " + std::get<0>(f) + " " + std::get<1>(f) + " " + std::get<2>(f);
  }
  return out;
}

void testValidation() {
  {
    som::SpecDocument d = registerDoc();
    d.setUnits("DEMO/TTL", "u_a");
    d.setUnits("DEMO/REG", "u_a,u_b");
    const auto got = validate(d);
    check("phase8.clean", got.empty(), show(got));
  }
  {
    som::SpecDocument d = registerDoc();
    d.setUnits("DEMO/TTL", "u_x, u_a ,u_y");
    const std::vector<Finding> want = {
        {"DEMO/TTL", "unknownUnit",
         "units names \"u_x\", which no generation unit declares"},
        {"DEMO/TTL", "unknownUnit",
         "units names \"u_y\", which no generation unit declares"},
    };
    const auto got = validate(d);
    check("phase8.unknownUnit", got == want, show(got));
  }
  {
    som::SpecDocument d = registerDoc();
    d.setUnits("DEMO/META", "u_a");
    d.setUnits("DEMO/META/tags", "u_a");
    d.setUnits("DEMO/control", "u_a");
    d.setUnits("DEMO/DLV-LST-1", "u_a");
    // Routed: a field of a routed class, a list of a routed element.
    d.setUnits("DEMO/PRI", "u_a");
    d.setUnits("DEMO/CARD-LST", "u_a");
    const std::string message =
        "units is set on a section that routes nothing to CodeSpecs";
    const std::vector<Finding> want = {
        {"DEMO/DLV-LST-1", "unitsUnrouted", message},
        {"DEMO/META", "unitsUnrouted", message},
        {"DEMO/META/tags", "unitsUnrouted", message},
        {"DEMO/control", "unitsUnrouted", message},
    };
    const auto got = validate(d);
    check("phase8.unitsUnrouted", got == want, show(got));
  }
  {
    som::SpecDocument d = registerDoc();
    const std::string dup = d.addListItem("DEMO/DLV-LST");
    d.setFormField(dup + "/content", "unitId", "u_a");
    d.setFormField(dup + "/content", "kind", "server");
    // An item with no value at all is absence, not a finding.
    d.addListItem("DEMO/DLV-LST");
    for (const char* area : {"CE-DB", "ce-db", "CE-", "CE-D1"}) {
      const std::string route = d.addListItem("DEMO/DLV-LST-1/DLR-LST");
      d.setFormField(route + "/content", "area", area);
      d.setFormField(route + "/content", "mapping", "dart-tom");
    }
    const std::vector<Finding> want = {
        {"DEMO/DLV-LST-1/DLR-LST-2", "unitAreaMalformed",
         "mapping area \"ce-db\" is not an area code (CE-\xe2\x80\xa6)"},
        {"DEMO/DLV-LST-1/DLR-LST-3", "unitAreaMalformed",
         "mapping area \"CE-\" is not an area code (CE-\xe2\x80\xa6)"},
        {"DEMO/DLV-LST-1/DLR-LST-4", "unitAreaMalformed",
         "mapping area \"CE-D1\" is not an area code (CE-\xe2\x80\xa6)"},
        {"DEMO/DLV-LST-3", "duplicateUnitId",
         "generation unit \"u_a\" is declared twice"},
        {"DEMO/DLV-LST-3", "unitBuildsNothing",
         "generation unit \"u_a\" builds neither a deploymentTarget nor a "
         "component"},
    };
    const auto got = validate(d);
    check("phase8.register", got == want, show(got));
  }
  {
    // Phase 8 follows the derived values and precedes the annotations.
    som::SpecDocument d = registerDoc();
    d.setUnits("DEMO/TTL", "u_x");
    d.setContent("DEMO/SUM",
                 "> \xe2\xac\x86\xef\xb8\x8f **C-1** a\n\n"
                 "> \xe2\xac\x86\xef\xb8\x8f **C-1** b");
    std::vector<std::string> codes;
    for (const som::SpecValidationError& e : som::validateDocument(*g_model, d)) {
      codes.push_back(e.code);
    }
    check("phase8.order", joined(codes) == "unknownUnit,duplicateAnnotationId",
          joined(codes));
  }
}

}  // namespace

int main() {
  std::string err;
  g_model = som::SpecModel::fromJsonStr(
      readFile("../tom_som_conformance/corpus/model.meta.json"), &err);
  if (g_model == nullptr) {
    fatal("load model", err);
  }
  g_tree = som::somBuildMetaTree(*g_model, "", &err);
  if (g_tree == nullptr) {
    fatal("tree", err);
  }

  testStore();
  testFacade();
  testMarkdown();
  testYaml();
  testAssemblyAndMerge();
  testValidation();

  if (g_failures == 0) {
    std::printf("spec_units_test: all %d checks passed\n", g_checks);
    return 0;
  }
  std::printf("spec_units_test: %d/%d checks failed\n", g_failures, g_checks);
  return 1;
}
