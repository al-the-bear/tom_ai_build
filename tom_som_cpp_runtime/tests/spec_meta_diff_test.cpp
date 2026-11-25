// Meta-tree diff tests: som::somMetaNodeDiff reports a form field that differs
// only in one of its flags (`code`, `multiParagraph`), so the generated-tree ==
// bridge-tree agreement cannot pass over a lost flag.
//
// Two trees are built by the bridge from one inline model, then one flag of one
// form field is changed in the second. Exit status is the number of failed
// checks (0 = green).

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <string>

#include "spec_meta.hpp"
#include "spec_meta_bridge.hpp"
#include "spec_meta_diff.hpp"
#include "spec_model.hpp"

namespace {

int g_checks = 0;
int g_failures = 0;

void check(const char* name, bool cond, const std::string& detail = "") {
  ++g_checks;
  if (cond) return;
  ++g_failures;
  std::fprintf(stderr, "FAIL %s%s%s\n", name, detail.empty() ? "" : ": ",
               detail.c_str());
}

const char* kModel =
    "{\"roots\":[{\"type\":\"DiffDoc\",\"title\":\"Diff Doc\","
    "\"sectionId\":\"DIF\"}],"
    "\"classes\":{\"DiffDoc\":{\"name\":\"DiffDoc\",\"sectionId\":\"DIF\","
    "\"annotations\":[{\"name\":\"Document\"},"
    "{\"name\":\"SectionId\",\"arguments\":{\"id\":\"DIF\"}}],"
    "\"fields\":[{\"name\":\"control\",\"kind\":\"form\","
    "\"sectionId\":\"DIF-CTL\",\"formFields\":["
    "{\"name\":\"notes\",\"type\":\"String\",\"multiParagraph\":true},"
    "{\"name\":\"pattern\",\"type\":\"String\",\"code\":true}]}]}}}";

std::unique_ptr<som::SomMetaTree> build(const som::SpecModel& model) {
  std::string err;
  std::unique_ptr<som::SomMetaTree> t =
      som::somBuildMetaTree(model, "DiffDoc", &err);
  if (t == nullptr) {
    std::fprintf(stderr, "fatal: somBuildMetaTree: %s\n", err.c_str());
    std::exit(2);
  }
  return t;
}

som::SomFormFieldMeta* field(som::SomMetaTree& t, const std::string& name) {
  som::SomMetaNode* n = t.byId("DIF-CTL");
  if (n == nullptr || !n->form.has_value()) return nullptr;
  for (som::SomFormFieldMeta& f : n->form->fields) {
    if (f.name == name) return &f;
  }
  return nullptr;
}

}  // namespace

int main() {
  std::string err;
  std::unique_ptr<som::SpecModel> model =
      som::SpecModel::fromJsonStr(kModel, &err);
  if (model == nullptr) {
    std::fprintf(stderr, "fatal: model: %s\n", err.c_str());
    return 2;
  }

  std::unique_ptr<som::SomMetaTree> a = build(*model);
  std::unique_ptr<som::SomMetaTree> b = build(*model);
  som::SomFormFieldMeta* notes = field(*b, "notes");
  som::SomFormFieldMeta* pattern = field(*b, "pattern");
  check("MD0: the model reads multiParagraph into the form-field meta",
        notes != nullptr && notes->multiParagraph && !notes->code);
  check("MD0: the model reads code into the form-field meta",
        pattern != nullptr && pattern->code && !pattern->multiParagraph);

  std::string same = som::somMetaNodeDiff(*a->root(), *b->root());
  check("MD1: two trees of one model agree", same.empty(), same);

  if (notes != nullptr) notes->multiParagraph = false;
  std::string d1 = som::somMetaNodeDiff(*a->root(), *b->root());
  check("MD2: a form field differing only in multiParagraph is reported",
        d1.find("form field notes differs") != std::string::npos, d1);
  if (notes != nullptr) notes->multiParagraph = true;

  if (pattern != nullptr) pattern->code = false;
  std::string d2 = som::somMetaNodeDiff(*a->root(), *b->root());
  check("MD3: a form field differing only in code is reported",
        d2.find("form field pattern differs") != std::string::npos, d2);

  if (g_failures == 0) {
    std::printf("spec_meta_diff_test: %d checks passed\n", g_checks);
  } else {
    std::fprintf(stderr, "spec_meta_diff_test: %d/%d checks FAILED\n",
                 g_failures, g_checks);
  }
  return g_failures;
}
