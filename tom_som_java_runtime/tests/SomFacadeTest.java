import java.util.ArrayList;
import java.util.List;

import tom_som_runtime.SomEditability;
import tom_som_runtime.SomFacade;
import tom_som_runtime.SomVersionError;

/**
 * Dependency-free unit tests for {@link SomFacade#somEditabilityFor} and its
 * throwing companion {@link SomFacade#checkModelVersion} (§ item 8). Mirrors the
 * Dart reference cases in {@code som_facade_test.dart}: JUnit is unavailable on
 * the build host, so this is a plain {@code main()} that exits 0 on success and
 * 1 on failure — the same shape as {@code ConformanceRunner}.
 */
public final class SomFacadeTest {
  private static int passed = 0;
  private static final List<String> failed = new ArrayList<>();

  private static void check(String name, boolean condition, String detail) {
    if (condition) {
      passed++;
    } else {
      failed.add(name + (detail.isEmpty() ? "" : ": " + detail));
    }
  }

  private static void eq(String name, SomEditability got, SomEditability want) {
    check(name, got == want, got + " != " + want);
  }

  /** Whether {@link SomFacade#checkModelVersion} throws for these inputs. */
  private static boolean throwsCheck(String generated, String documentVersion) {
    try {
      SomFacade.checkModelVersion(generated, documentVersion);
      return false;
    } catch (SomVersionError e) {
      return true;
    }
  }

  public static void main(String[] args) {
    // --- somEditabilityFor classification ---------------------------------
    // null / empty document stamp → editable (a brand-new document).
    eq("null->editable", SomFacade.somEditabilityFor("1.0", null), SomEditability.EDITABLE);
    eq("empty->editable", SomFacade.somEditabilityFor("1.0", ""), SomEditability.EDITABLE);

    // same major, older or equal minor → editable.
    eq("same-major-older->editable",
        SomFacade.somEditabilityFor("1.5", "1.2"), SomEditability.EDITABLE);
    eq("same-major-equal->editable",
        SomFacade.somEditabilityFor("1.5", "1.5"), SomEditability.EDITABLE);
    eq("same-major-zero->editable",
        SomFacade.somEditabilityFor("1.0", "1.0"), SomEditability.EDITABLE);

    // same major, newer minor → rejected.
    eq("newer-minor->rejected",
        SomFacade.somEditabilityFor("1.2", "1.5"), SomEditability.REJECTED_NEWER_MINOR);

    // different major (either direction) → cross-major read-only.
    eq("higher-major->cross-major",
        SomFacade.somEditabilityFor("1.0", "2.0"), SomEditability.READ_ONLY_CROSS_MAJOR);
    eq("lower-major->cross-major",
        SomFacade.somEditabilityFor("2.0", "1.9"), SomEditability.READ_ONLY_CROSS_MAJOR);

    // unparseable stamp → invalid.
    eq("nonnumeric->invalid",
        SomFacade.somEditabilityFor("1.0", "abc"), SomEditability.INVALID_VERSION);
    eq("single-part->invalid",
        SomFacade.somEditabilityFor("1.0", "1"), SomEditability.INVALID_VERSION);
    eq("three-part->invalid",
        SomFacade.somEditabilityFor("1.0", "1.0.0"), SomEditability.INVALID_VERSION);
    eq("empty-minor->invalid",
        SomFacade.somEditabilityFor("1.0", "1."), SomEditability.INVALID_VERSION);

    // --- somEditabilityFor never throws where checkModelVersion throws ------
    String[][] cases = {
        {"1.0", null}, {"1.0", ""}, {"1.5", "1.2"}, {"1.5", "1.5"},
        {"1.2", "1.5"}, {"1.0", "2.0"}, {"2.0", "1.9"}, {"1.0", "abc"},
        {"1.0", "1"}, {"1.0", "1.0.0"}, {"1.0", "1."},
    };
    for (String[] c : cases) {
      String label = "no-throw[" + c[0] + "," + c[1] + "]";
      boolean threw = false;
      try {
        SomFacade.somEditabilityFor(c[0], c[1]);
      } catch (RuntimeException e) {
        threw = true;
      }
      check(label, !threw, "somEditabilityFor threw");
    }

    // --- checkModelVersion agrees with the classifier ---------------------
    // Throws exactly for the non-editable classifications.
    check("check-editable-null", !throwsCheck("1.0", null), "");
    check("check-editable-older", !throwsCheck("1.5", "1.2"), "");
    check("check-editable-equal", !throwsCheck("1.5", "1.5"), "");
    check("check-newer-minor-throws", throwsCheck("1.2", "1.5"), "");
    check("check-cross-major-throws", throwsCheck("1.0", "2.0"), "");
    check("check-invalid-throws", throwsCheck("1.0", "abc"), "");

    // Per-case messages preserved (DRY: classifier drives the throw).
    try {
      SomFacade.checkModelVersion("1.0", "abc");
      check("msg-invalid", false, "did not throw");
    } catch (SomVersionError e) {
      check("msg-invalid", e.getMessage().contains("not a valid major.minor"), e.getMessage());
    }
    try {
      SomFacade.checkModelVersion("1.0", "2.0");
      check("msg-cross-major", false, "did not throw");
    } catch (SomVersionError e) {
      check("msg-cross-major", e.getMessage().contains("cross-major documents are read-only"),
          e.getMessage());
    }
    try {
      SomFacade.checkModelVersion("1.2", "1.5");
      check("msg-newer-minor", false, "did not throw");
    } catch (SomVersionError e) {
      check("msg-newer-minor", e.getMessage().contains("cannot edit a newer document"),
          e.getMessage());
    }

    // --- facade behavioural analogue of the root's editabilityFor ----------
    // The generated root's `editabilityFor(documentVersion)` delegates to
    // SomFacade.somEditabilityFor(MODEL_VERSION, documentVersion). Cannot
    // regenerate the facade here, so exercise the delegation directly with a
    // fixed MODEL_VERSION stand-in.
    final String modelVersion = "1.0";
    eq("facade-editabilityFor-null",
        SomFacade.somEditabilityFor(modelVersion, null), SomEditability.EDITABLE);
    eq("facade-editabilityFor-cross",
        SomFacade.somEditabilityFor(modelVersion, "2.3"), SomEditability.READ_ONLY_CROSS_MAJOR);

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

  private SomFacadeTest() {}
}
