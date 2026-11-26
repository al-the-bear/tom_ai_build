package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** The validation of a {@link SpecDocumentSet} ({@link SpecDocumentSet#syncReport}). */
public final class SpecSyncReport {
  /** The findings in pair and path order, {@code info} entries included. */
  public final List<SpecSyncFinding> findings;
  /** Each document's own findings ({@code validateDocument}, then {@code validateLinks}), in the set's order. */
  public final List<SpecDocumentFindings> documentFindings;
  /** The Phase 3 roots with no document yet. */
  public final List<String> notStarted;
  /**
   * The pairs (by section id) whose Phase 3 document exists but holds nothing
   * beneath the pair's anchor: not started, like a missing document.
   */
  public final List<String> notStartedPairs;

  public SpecSyncReport(
      List<SpecSyncFinding> findings,
      List<SpecDocumentFindings> documentFindings,
      List<String> notStarted,
      List<String> notStartedPairs) {
    this.findings = Collections.unmodifiableList(new ArrayList<>(findings));
    this.documentFindings = Collections.unmodifiableList(new ArrayList<>(documentFindings));
    this.notStarted = Collections.unmodifiableList(new ArrayList<>(notStarted));
    this.notStartedPairs = Collections.unmodifiableList(new ArrayList<>(notStartedPairs));
  }

  /** The findings per code, {@code info} entries included, in code order (codes without findings left out). */
  public Map<SpecSyncCode, Integer> countsByCode() {
    Map<SpecSyncCode, Integer> out = new LinkedHashMap<>();
    for (SpecSyncCode c : SpecSyncCode.values()) {
      int n = 0;
      for (SpecSyncFinding f : findings) {
        if (f.code == c) {
          n++;
        }
      }
      if (n > 0) {
        out.put(c, n);
      }
    }
    return out;
  }

  /** The findings per resolution, in resolution order. */
  public Map<SpecSyncResolution, Integer> countsByResolution() {
    Map<SpecSyncResolution, Integer> out = new LinkedHashMap<>();
    for (SpecSyncResolution r : SpecSyncResolution.values()) {
      int n = 0;
      for (SpecSyncFinding f : findings) {
        if (f.resolution == r) {
          n++;
        }
      }
      if (n > 0) {
        out.put(r, n);
      }
    }
    return out;
  }

  /** Whether there is no finding other than {@code info}. */
  public boolean clean() {
    for (SpecSyncFinding f : findings) {
      if (!f.isInfo()) {
        return false;
      }
    }
    return true;
  }

  /** {@link #countsByCode} as the canonical {@code [[code, count], …]} form. */
  public List<Object> countsByCodeJson() {
    List<Object> out = new ArrayList<>();
    for (Map.Entry<SpecSyncCode, Integer> e : countsByCode().entrySet()) {
      out.add(List.of(e.getKey().value, e.getValue()));
    }
    return out;
  }

  /** {@link #countsByResolution} as the canonical {@code [[resolution, count], …]} form. */
  public List<Object> countsByResolutionJson() {
    List<Object> out = new ArrayList<>();
    for (Map.Entry<SpecSyncResolution, Integer> e : countsByResolution().entrySet()) {
      out.add(List.of(e.getKey().value, e.getValue()));
    }
    return out;
  }

  /** {@code errors} as {@code [{path, code, message}]}. */
  static List<Object> errorsJson(List<SpecValidationError> errors) {
    List<Object> out = new ArrayList<>();
    for (SpecValidationError e : errors) {
      Map<String, Object> m = new LinkedHashMap<>();
      m.put("path", e.path);
      m.put("code", e.code.value);
      m.put("message", e.message);
      out.add(m);
    }
    return out;
  }

  /** The canonical JSON form; every ordered value is a list. */
  public Map<String, Object> toJson() {
    List<Object> fs = new ArrayList<>();
    for (SpecSyncFinding f : findings) {
      fs.add(f.toJson());
    }
    List<Object> ds = new ArrayList<>();
    for (SpecDocumentFindings d : documentFindings) {
      ds.add(List.of(d.name, errorsJson(d.errors)));
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("findings", fs);
    out.put("documentFindings", ds);
    out.put("notStarted", new ArrayList<Object>(notStarted));
    out.put("notStartedPairs", new ArrayList<Object>(notStartedPairs));
    out.put("countsByCode", countsByCodeJson());
    out.put("countsByResolution", countsByResolutionJson());
    out.put("clean", clean());
    return out;
  }
}
