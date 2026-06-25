package tom_som_runtime;

/** One rejected block in a Markdown import. Reported, never silently dropped. */
public final class SpecMarkdownRejection {
  public final int line;
  public final SpecMarkdownRejectReason reason;
  public final String message;
  public final String anchor;

  public SpecMarkdownRejection(
      int line, SpecMarkdownRejectReason reason, String message, String anchor) {
    this.line = line;
    this.reason = reason;
    this.message = message;
    this.anchor = anchor;
  }

  @Override
  public String toString() {
    String a = anchor != null ? " (" + anchor + ")" : "";
    return "line " + line + ": " + reason.value + a + " \u2014 " + message;
  }
}
