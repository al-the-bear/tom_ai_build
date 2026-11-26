package tom_som_runtime;

/** One value of a {@link SpecSetSide}, keyed for comparison. */
public final class SpecSetValue {
  public final String path;
  /** The form field ({@code @headline} for a headline), {@code null} for content. */
  public final String field;
  /** The value, read with pending marks rejected, trimmed. */
  public final String value;
  /** Whether the stored value holds pending change marks. */
  public final boolean pending;
  /** The form field's spec, {@code null} for none. */
  public final FormFieldSpec spec;

  public SpecSetValue(String path, String field, String value, boolean pending, FormFieldSpec spec) {
    this.path = path;
    this.field = field;
    this.value = value;
    this.pending = pending;
    this.spec = spec;
  }
}
