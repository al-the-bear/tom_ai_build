package tom_som_runtime;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A fence state machine (CommonMark-ish): a line whose first non-space run (up
 * to 3 spaces indent) is 3+ backticks or tildes opens a fence; a matching
 * same-character run at least as long closes it.
 *
 * <p>Public so other markdown-processing modules (the DocSpecs validator's
 * generic parser) share exactly the same fence semantics as the
 * {@link SpecDocumentMarkdown} codec. A faithful port of the Go/TS
 * {@code MarkdownFenceTracker}.
 */
public final class MarkdownFenceTracker {
  static final Pattern FENCE_OPEN = Pattern.compile("^ {0,3}(`{3,}|~{3,})");

  private char ch;
  private int size;

  /** Whether the tracker is currently inside a fence. */
  public boolean inFence() {
    return ch != 0;
  }

  /** Advances the state machine by one line. */
  public void feed(String line) {
    Matcher m = FENCE_OPEN.matcher(line);
    if (!m.find()) {
      return;
    }
    String run = m.group(1);
    if (ch == 0) {
      ch = run.charAt(0);
      size = run.length();
      return;
    }
    String trimmed = line.trim();
    if (run.charAt(0) == ch
        && run.length() >= size
        && trimmed.equals(String.valueOf(ch).repeat(trimmed.length()))) {
      ch = 0;
      size = 0;
    }
  }
}
