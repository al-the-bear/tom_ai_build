/* Behavioural test for the structural `canHaveContent()` predicate (SOM §21):
 * "does this TYPE declare the standard `content` text leaf?" — answered at the
 * type level, WITHOUT probing the document.
 *
 * `canHaveContent()` is a virtual member of the runtime base `som::SomNode`
 * returning the `false` default; the generated section facades override it to
 * `true`. The full generated model is not regenerated here (the generator runs
 * centrally), so this hand-writes the two facade shapes the emitter produces —
 * a section (override -> true) and a type declaring no `content` leaf
 * (inherits -> false) — and pins:
 *   - the base default is false;
 *   - a content-bearing override reports true;
 *   - a type with no `content` leaf inherits false;
 *   - it is STRUCTURAL — independent of whether content is written now, and
 *     distinct from the state predicates isEmpty() / hasContent();
 *   - it resolves polymorphically through a som::SomNode& reference.
 */
#include <cstdio>
#include <string>

#include "som_facade.hpp"
#include "spec_document.hpp"

namespace {

// A content-bearing section: it declares the standard `content` leaf, so the
// emitter emits the `canHaveContent() const override { return true; }` shape.
class ContentBearing : public som::SomNode {
 public:
  ContentBearing(som::SpecDocument& doc, std::string path)
      : som::SomNode(doc, std::move(path)) {}
  bool canHaveContent() const override { return true; }
  std::string content() const {
    return doc().content(som::joinPath(path(), "content"));
  }
  void setContent(const std::string& value) {
    doc().setContent(som::joinPath(path(), "content"), value);
  }
};

// A type declaring no `content` leaf, so the emitter emits no override and it
// inherits the base `false` default. In the generated facades this shape is a
// non-section node (a `som::SomList` field view): every *section* class carries
// `content` per `tom_specs_model_rules.md` §10.2.
class Leafless : public som::SomNode {
 public:
  Leafless(som::SpecDocument& doc, std::string path)
      : som::SomNode(doc, std::move(path)) {}
};

std::size_t g_passed = 0;
std::size_t g_failed = 0;

void check(const char* name, bool cond) {
  if (cond) {
    g_passed++;
  } else {
    g_failed++;
    std::printf("  FAIL: %s\n", name);
  }
}

}  // namespace

int main() {
  som::SpecDocument doc;

  // The plain base node reports the structural default: false.
  {
    som::SomNode base(doc, "root/plain");
    check("base SomNode default canHaveContent == false",
          base.canHaveContent() == false);
  }

  // A content-bearing section overrides the default to true.
  {
    ContentBearing cb(doc, "root/goals");
    check("content-bearing section canHaveContent == true",
          cb.canHaveContent() == true);
  }

  // A type with no `content` leaf inherits the false default (no override).
  {
    Leafless lf(doc, "root/tags-1");
    check("leafless type inherits canHaveContent == false",
          lf.canHaveContent() == false);
  }

  // Structural, not state: canHaveContent is independent of whether the content
  // leaf holds a value now — and distinct from isEmpty()/hasContent().
  {
    ContentBearing cb(doc, "root/goals2");
    check("empty content-bearing section still canHaveContent == true",
          cb.canHaveContent() == true);
    check("empty content-bearing section isEmpty() == true (state)",
          cb.isEmpty() == true);
    cb.setContent("Grow revenue");
    check("filled content-bearing section still canHaveContent == true",
          cb.canHaveContent() == true);
    check("filled content-bearing section isEmpty() == false (state changed)",
          cb.isEmpty() == false);
  }

  // A leafless node stays false even once a nested value fills it.
  {
    Leafless lf(doc, "root/leafless2");
    doc.setContent("root/leafless2/child/content", "x");
    check("filled leafless node still canHaveContent == false",
          lf.canHaveContent() == false);
    check("filled leafless node isEmpty() == false (state)",
          lf.isEmpty() == false);
  }

  // The predicate resolves polymorphically through a base reference.
  {
    ContentBearing cb(doc, "root/goals3");
    Leafless lf(doc, "root/leafless3");
    som::SomNode& cbRef = cb;
    som::SomNode& lfRef = lf;
    check("polymorphic canHaveContent through base ref (content-bearing)",
          cbRef.canHaveContent() == true);
    check("polymorphic canHaveContent through base ref (leafless)",
          lfRef.canHaveContent() == false);
  }

  if (g_failed == 0) {
    std::printf("can_have_content_test: all %zu checks passed\n", g_passed);
    return 0;
  }
  std::printf("can_have_content_test: %zu passed, %zu FAILED\n", g_passed,
              g_failed);
  return 1;
}
