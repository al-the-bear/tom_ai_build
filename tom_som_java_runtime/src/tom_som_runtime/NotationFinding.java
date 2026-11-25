package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One finding of {@link SpecNotation#scanNotation}. */
public final class NotationFinding {
  /** What was found. */
  public final NotationFindingCode code;
  /** The UTF-16 offset it stands at. */
  public final int offset;
  /** Its 1-based line. */
  public final int line;
  public final String message;

  public NotationFinding(NotationFindingCode code, int offset, int line, String message) {
    this.code = code;
    this.offset = offset;
    this.line = line;
    this.message = message;
  }

  /** The severity of the code: {@code "error"} or {@code "warning"}. */
  public String severity() {
    return SpecNotation.notationSeverity(code);
  }

  /** The finding as the conformance corpus writes it. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("code", code.value);
    out.put("severity", severity());
    out.put("line", line);
    return out;
  }

  @Override
  public String toString() {
    return "line " + line + ": " + code.value + " — " + message;
  }
}
