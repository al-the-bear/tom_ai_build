import java.util.ArrayList;
import java.util.List;

import tom_som_runtime.SomEditability;
import tom_som_runtime.SomFacade;
import tom_som_runtime.SomNode;
import tom_som_runtime.SomVersionError;
import tom_som_runtime.SpecDocument;

/**
 * Behavioural test for the root facade's {@code static editabilityFor(...)}
 * (SOM §21), the port of the TypeScript runtime's
 * {@code tests/som_facade_editability_test.ts}.
 *
 * <p>The real facade is generated centrally (this test cannot run the
 * generator), so the stand-in {@code FakeRoot} reproduces what
 * {@code SomJavaEmitter} emits on a root class — a {@code MODEL_VERSION}, a SOM
 * §4.2 constructor check, and the static {@code editabilityFor} delegating to
 * {@code SomFacade.somEditabilityFor(MODEL_VERSION, documentVersion)} — and
 * asserts that shape classifies documents as the pure classifier does. A plain
 * {@code main()} that exits 0 on success and 1 on failure.
 */
public final class SomFacadeEditabilityTest {
  /** Mirrors the emitter output for a root class at model version 1.2. */
  static final class FakeRoot extends SomNode {
    public static final String MODEL_VERSION = "1.2";

    FakeRoot(SpecDocument doc, String documentVersion) {
      super(doc, "root");
      SomFacade.checkModelVersion(MODEL_VERSION, documentVersion);
    }

    public static SomEditability editabilityFor(String documentVersion) {
      return SomFacade.somEditabilityFor(MODEL_VERSION, documentVersion);
    }
  }

  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void eq(String name, SomEditability got, SomEditability want) {
    if (got == want) {
      passed++;
    } else {
      failed.add(name + ": expected " + want + ", got " + got);
    }
  }

  public static void main(String[] args) {
    // editabilityFor mirrors somEditabilityFor(MODEL_VERSION, ...) — no throw.
    eq("root: null -> editable", FakeRoot.editabilityFor(null), SomEditability.EDITABLE);
    eq("root: same -> editable", FakeRoot.editabilityFor("1.2"), SomEditability.EDITABLE);
    eq("root: older minor -> editable", FakeRoot.editabilityFor("1.0"), SomEditability.EDITABLE);
    eq("root: newer minor -> rejectedNewerMinor", FakeRoot.editabilityFor("1.5"),
        SomEditability.REJECTED_NEWER_MINOR);
    eq("root: cross-major -> readOnlyCrossMajor", FakeRoot.editabilityFor("2.0"),
        SomEditability.READ_ONLY_CROSS_MAJOR);
    eq("root: garbage -> invalidVersion", FakeRoot.editabilityFor("nope"),
        SomEditability.INVALID_VERSION);

    // The constructor still THROWS where editabilityFor reports non-editable.
    SpecDocument doc = new SpecDocument();
    try {
      new FakeRoot(doc, "2.0");
      failed.add("root: constructor should throw on cross-major");
    } catch (SomVersionError e) {
      passed++;
    } catch (RuntimeException e) {
      failed.add("root: constructor threw unexpected " + e);
    }
    // ...and does NOT throw where editabilityFor reports editable.
    try {
      new FakeRoot(doc, "1.0");
      passed++;
    } catch (RuntimeException e) {
      failed.add("root: constructor should not throw on editable, got " + e);
    }

    if (failed.isEmpty()) {
      System.out.println("SomFacadeEditabilityTest: all " + passed + " checks passed.");
      System.exit(0);
    }
    System.err.println("SomFacadeEditabilityTest: " + failed.size() + " FAILED (of "
        + (passed + failed.size()) + "):");
    for (String f : failed) {
      System.err.println("  - " + f);
    }
    System.exit(1);
  }
}
