package tom_som_runtime;

/**
 * One derived number {@link SpecValidator#derivedNumbers} computes: the value
 * the form field {@link #field} of the form at {@link #path} should hold.
 */
public final class SpecDerivedNumber {
  public final String path;
  public final String field;
  public final String value;

  public SpecDerivedNumber(String path, String field, String value) {
    this.path = path;
    this.field = field;
    this.value = value;
  }

  @Override
  public String toString() {
    return path + "#" + field + " = " + value;
  }
}
