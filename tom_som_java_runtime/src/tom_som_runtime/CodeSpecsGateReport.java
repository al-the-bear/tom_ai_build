package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** The Stage-A gate's report: one result per check, A1 to A5. */
public final class CodeSpecsGateReport {
  /** The five results, in check order. */
  public final List<CodeSpecsGateCheckResult> results;

  /**
   * The extraction run's extracts, when A3 passed (A4 reads them; Stage B is
   * handed them). {@code null} when the walk could not complete.
   */
  public final List<CodeSpecsExtract> extracts;

  public CodeSpecsGateReport(
      List<CodeSpecsGateCheckResult> results, List<CodeSpecsExtract> extracts) {
    this.results = Collections.unmodifiableList(results);
    this.extracts = extracts;
  }

  /** The result of {@code check}. */
  public CodeSpecsGateCheckResult get(CodeSpecsGateCheck check) {
    for (CodeSpecsGateCheckResult r : results) {
      if (r.check == check) {
        return r;
      }
    }
    throw new IllegalStateException("no result for " + check.label());
  }

  /** Every check ran and found nothing — the run may begin. */
  public boolean passed() {
    for (CodeSpecsGateCheckResult r : results) {
      if (!r.passed()) {
        return false;
      }
    }
    return true;
  }

  /** Every finding, in check order. */
  public List<CodeSpecsGateFinding> findings() {
    List<CodeSpecsGateFinding> out = new ArrayList<>();
    for (CodeSpecsGateCheckResult r : results) {
      out.addAll(r.findings);
    }
    return out;
  }
}
