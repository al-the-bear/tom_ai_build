package tom_som_runtime;

/** The options of {@link SpecDeriveFields#deriveFields}. */
public final class SpecDeriveOptions {
  /**
   * Writes every change as inline marks (SOM §11.9.3), for a document under
   * review, and reads values as proposed (pending marks accepted); {@code false}
   * writes plain values. Default {@code true}, as the reference runtime's.
   */
  public boolean marked = true;
  /** The review member the marks are attributed to, {@code null} for none. */
  public String author;
  /** The change time the marks record, {@code null} for now. */
  public String at;
  /** Works on a copy of the document. */
  public boolean dryRun;

  /** Options writing plain values ({@link #marked} {@code false}). */
  public static SpecDeriveOptions plain() {
    SpecDeriveOptions o = new SpecDeriveOptions();
    o.marked = false;
    return o;
  }
}
