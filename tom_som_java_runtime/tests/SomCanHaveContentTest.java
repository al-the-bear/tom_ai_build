import java.util.ArrayList;
import java.util.List;

import tom_som_runtime.SomNode;
import tom_som_runtime.SomScalar;
import tom_som_runtime.SpecDocument;

/**
 * Behavioural test for the structural {@link SomNode#canHaveContent} predicate
 * (SOM §21): "does this section TYPE declare the standard {@code content}
 * text leaf?" — a compile-time / per-type schema fact, answered WITHOUT probing
 * {@code content()} and WITHOUT ever looking at the document.
 *
 * <p>The real subclasses are generated centrally (this test cannot run the
 * generator), so these stand-ins reproduce what the emitter produces: a
 * content-bearing section overrides the base default to {@code true}, while
 * scalar/container-only sections inherit the {@code false} default. It asserts
 * the base default, the content-bearing override, the inherited-false cases,
 * and — crucially — that the STATE predicates ({@code hasContent(path)} on the
 * document, {@code isEmpty()} on the node) stay independent of this STRUCTURAL
 * predicate.
 *
 * <p>JUnit is unavailable on the build host, so this is a plain {@code main()}
 * that exits 0 on success and 1 on failure — the same shape as
 * {@code SomFacadeTest} / {@code SomListContentTest}.
 */
public final class SomCanHaveContentTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void eq(String name, boolean got, boolean want) {
    if (got == want) {
      passed++;
    } else {
      failed.add(name + ": expected " + want + ", got " + got);
    }
  }

  /**
   * A content-bearing section facade: it declares a {@code content} leaf, so it
   * overrides the structural default to {@code true} (what the emitter emits for
   * a {@code content}-bearing class such as {@code Goals}).
   */
  static final class ContentBearing extends SomNode {
    ContentBearing(SpecDocument doc, String path) {
      super(doc, path);
    }

    @Override
    public boolean canHaveContent() {
      return true;
    }

    public String content() {
      String v = doc.content(path + "/content");
      return v == null ? "" : v;
    }

    public void content(String value) {
      doc.setContent(path + "/content", value);
    }
  }

  /**
   * A container-only section facade: no {@code content} leaf, so it inherits the
   * structural {@code false} default (what a class like {@code SystemsToReplace}
   * does).
   */
  static final class ContainerOnly extends SomNode {
    ContainerOnly(SpecDocument doc, String path) {
      super(doc, path);
    }
  }

  public static void main(String[] args) {
    // (a) The base SomNode default is `false` — a bare node cannot hold content.
    {
      SpecDocument doc = new SpecDocument();
      SomNode node = new SomNode(doc, "root");
      eq("base SomNode default is false", node.canHaveContent(), false);
    }

    // (b) A content-bearing section overrides the default to `true`.
    {
      SpecDocument doc = new SpecDocument();
      ContentBearing section = new ContentBearing(doc, "root/goals");
      eq("content-bearing override is true", section.canHaveContent(), true);
    }

    // (c) A scalar list item inherits the `false` default.
    {
      SpecDocument doc = new SpecDocument();
      SomScalar scalar = new SomScalar(doc, "root/item");
      eq("SomScalar inherits false", scalar.canHaveContent(), false);
    }

    // (d) A container-only section inherits the `false` default.
    {
      SpecDocument doc = new SpecDocument();
      ContainerOnly container = new ContainerOnly(doc, "root/systemsToReplace");
      eq("container-only inherits false", container.canHaveContent(), false);
    }

    // (e) Structural vs state independence: `canHaveContent` never looks at the
    // document — it is `true` for a content-bearing section whether or not any
    // content value is present, and the state predicates (`hasContent`,
    // `isEmpty`) move independently of it.
    {
      SpecDocument doc = new SpecDocument();
      ContentBearing section = new ContentBearing(doc, "root/goals");
      String leaf = section.path + "/content";

      // Empty document: structural true, but no value present and node is empty.
      eq("empty: canHaveContent true", section.canHaveContent(), true);
      eq("empty: doc.hasContent false", doc.hasContent(leaf), false);
      eq("empty: node isEmpty true", section.isEmpty(), true);

      // After writing content: structural predicate unchanged; state flips.
      section.content("body");
      eq("filled: canHaveContent unchanged true", section.canHaveContent(), true);
      eq("filled: doc.hasContent true", doc.hasContent(leaf), true);
      eq("filled: node isEmpty false", section.isEmpty(), false);

      // A container-only section stays structurally false regardless of state.
      ContainerOnly container = new ContainerOnly(doc, "root/goals");
      eq("container over same path stays false", container.canHaveContent(), false);
    }

    int total = passed + failed.size();
    if (!failed.isEmpty()) {
      System.out.println("FAIL: " + failed.size() + "/" + total + " checks failed");
      for (String f : failed) {
        System.out.println("  - " + f);
      }
      System.exit(1);
      return;
    }
    System.out.println("OK: " + total + " checks passed");
  }

  private SomCanHaveContentTest() {}
}
