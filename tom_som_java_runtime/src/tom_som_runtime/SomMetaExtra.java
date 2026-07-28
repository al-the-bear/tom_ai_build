package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * One annotation captured losslessly into the generic extra list — annotations
 * the tree defines no dedicated slot for (SOM §7.1 note), e.g. {@code @Max},
 * {@code @MinLength}, {@code @PatternCheck}, {@code @TextRequired}. A faithful
 * port of {@code spec_meta.dart} / {@code spec_meta.ts}.
 */
public final class SomMetaExtra {
  /** The annotation's class name ({@code "Max"}, {@code "PatternCheck"}, …). */
  public final String annotation;

  /** The resolved constructor arguments ({@code {count: 4}}). */
  public final Map<String, Object> args;

  public SomMetaExtra(String annotation, Map<String, Object> args) {
    this.annotation = annotation;
    this.args = args != null ? args : new LinkedHashMap<>();
  }
}
