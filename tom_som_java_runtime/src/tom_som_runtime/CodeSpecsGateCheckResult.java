package tom_som_runtime;

import java.util.Collections;
import java.util.List;

/** One Stage-A check's outcome. */
public final class CodeSpecsGateCheckResult {
  /** Which check. */
  public final CodeSpecsGateCheck check;

  /** Whether it ran. A check that did not run never passes. */
  public final boolean ran;

  /** Why it did not run; {@code null} when it ran. */
  public final String notRunReason;

  /** What it found, in the order found. */
  public final List<CodeSpecsGateFinding> findings;

  public CodeSpecsGateCheckResult(
      CodeSpecsGateCheck check,
      boolean ran,
      String notRunReason,
      List<CodeSpecsGateFinding> findings) {
    this.check = check;
    this.ran = ran;
    this.notRunReason = notRunReason;
    this.findings = Collections.unmodifiableList(findings);
  }

  /** A check that ran, with what it found. */
  public static CodeSpecsGateCheckResult ran(
      CodeSpecsGateCheck check, List<CodeSpecsGateFinding> findings) {
    return new CodeSpecsGateCheckResult(check, true, null, findings);
  }

  /** A check that did not run, and why. */
  public static CodeSpecsGateCheckResult notRun(CodeSpecsGateCheck check, String reason) {
    return new CodeSpecsGateCheckResult(
        check, false, reason, Collections.<CodeSpecsGateFinding>emptyList());
  }

  /** Ran and found nothing. */
  public boolean passed() {
    return ran && findings.isEmpty();
  }
}
