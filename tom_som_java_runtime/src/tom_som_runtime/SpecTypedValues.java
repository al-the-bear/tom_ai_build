package tom_som_runtime;

import java.util.List;

/**
 * Shared typed-value conversion at the store boundary (YRD7) — a faithful port
 * of {@code spec_typed_values.dart} / {@code spec_typed_values.py}.
 *
 * <p>A {@link SpecDocument}'s stores hold <b>plain strings</b> — that is what the
 * md/yaml serialization writes ({@code FieldName: value}) and what keeps every
 * language runtime's persistence identical. Typed access therefore converts
 * <i>at the boundary</i>: parse on read, format on write. These helpers are that
 * single boundary — a generated typed facade and the generic {@link SpecEditor}
 * call the <b>same</b> methods, so a facade is provably a thin layer over the
 * generic API (they cannot disagree on a conversion).
 *
 * <p>Conventions (the typed contract, mirrored by all nine runtimes):
 *
 * <ul>
 *   <li>absent / empty string ⇒ {@code null} on read; {@code null} on write ⇒
 *       clear (D4);
 *   <li>{@code int} — decimal integer, {@link #somParseInt} returns {@code null}
 *       for non-numeric text;
 *   <li>{@code double} — accepts any floating literal (also a plain integer);
 *       formatting always carries a decimal point, so an integral value
 *       round-trips as {@code 2.0} rather than {@code 2} (Dart's
 *       {@code double.toString});
 *   <li>{@code num} — an integral literal parses to {@link Integer}, anything
 *       else to {@link Double} (Dart's {@code num.tryParse});
 *   <li>{@code bool} — stored as {@code true} / {@code false} (lower case,
 *       language-neutral); parsing accepts exactly those, anything else reads as
 *       {@code null};
 *   <li>enums — stored as the constant <b>name</b> (e.g. {@code high}); the
 *       generic layer validates against the field's {@code enumValues} domain,
 *       a generated facade converts name ⇄ native constant.
 * </ul>
 *
 * <p>Reads are forgiving and writes are strict: unparsable stored text reads as
 * {@code null}, while an out-of-domain enum name raises
 * {@link IllegalArgumentException} so a typo cannot enter the store.
 */
public final class SpecTypedValues {
  private SpecTypedValues() {}

  /** Parses a stored string as {@code int}, or {@code null} when absent/unparsable. */
  public static Integer somParseInt(String raw) {
    if (raw == null || raw.isEmpty()) {
      return null;
    }
    try {
      return Integer.valueOf(raw);
    } catch (NumberFormatException e) {
      return null;
    }
  }

  /** Formats an {@code int} for the store; {@code null} becomes {@code ""} (clear, D4). */
  public static String somFormatInt(Integer value) {
    return value == null ? "" : value.toString();
  }

  /**
   * Parses a stored string as {@code double}, or {@code null} when
   * absent/unparsable.
   *
   * <p>The Java-only literal forms {@code Double.parseDouble} additionally
   * accepts — a {@code d}/{@code f} type suffix and hexadecimal floats — are
   * rejected here, because the store is language-neutral and the Dart/Python
   * references read those as unset.
   */
  public static Double somParseDouble(String raw) {
    if (raw == null || raw.isEmpty() || !isFloatLiteral(raw)) {
      return null;
    }
    try {
      return Double.valueOf(raw);
    } catch (NumberFormatException e) {
      return null;
    }
  }

  /**
   * Formats a {@code double} for the store; {@code null} becomes {@code ""}
   * (clear, D4).
   *
   * <p>A {@code double} always renders with a decimal point ({@code 2.0}),
   * matching Dart's {@code double.toString} — the store is language-neutral, so
   * the same value must serialize identically everywhere.
   */
  public static String somFormatDouble(Double value) {
    return value == null ? "" : value.toString();
  }

  /**
   * Parses a stored string as {@link Integer} when integral, else {@link Double}
   * — Dart's {@code num.tryParse}, so a {@code num} field keeps the narrower
   * type when the text carries no fraction.
   */
  public static Number somParseNum(String raw) {
    Integer asInt = somParseInt(raw);
    return asInt != null ? asInt : somParseDouble(raw);
  }

  /** Formats a {@code num} for the store; {@code null} becomes {@code ""} (clear, D4). */
  public static String somFormatNum(Number value) {
    if (value == null) {
      return "";
    }
    if (value instanceof Double || value instanceof Float) {
      return somFormatDouble(value.doubleValue());
    }
    return String.valueOf(value.longValue());
  }

  /** Parses a stored string as {@code bool} — exactly {@code true}/{@code false}, else {@code null}. */
  public static Boolean somParseBool(String raw) {
    if ("true".equals(raw)) {
      return Boolean.TRUE;
    }
    if ("false".equals(raw)) {
      return Boolean.FALSE;
    }
    return null;
  }

  /** Formats a {@code bool} for the store; {@code null} becomes {@code ""} (clear, D4). */
  public static String somFormatBool(Boolean value) {
    return value == null ? "" : (value ? "true" : "false");
  }

  /**
   * Parses a stored string as an enum constant name against {@code values} (the
   * field's {@code enumValues} domain). Returns {@code null} when absent or not
   * in the domain — a stale/foreign name reads as unset rather than throwing,
   * the same forgiveness the other parsers extend to malformed numbers.
   */
  public static String somParseEnumName(String raw, List<String> values) {
    return (raw != null && values != null && values.contains(raw)) ? raw : null;
  }

  /**
   * Validates an enum constant {@code name} against {@code values} before
   * storing.
   *
   * <p>{@code null}/empty clears (returns {@code ""}); a name outside the domain
   * throws {@link IllegalArgumentException} — writes are strict where reads are
   * forgiving, so a typo cannot enter the store.
   */
  public static String somFormatEnumName(String name, List<String> values) {
    if (name == null || name.isEmpty()) {
      return "";
    }
    List<String> domain = values == null ? List.of() : values;
    if (!domain.contains(name)) {
      throw new IllegalArgumentException(
          "\"" + name + "\" is not one of the enum values " + String.join(", ", domain));
    }
    return name;
  }

  /**
   * Whether {@code raw} is a decimal floating literal in the language-neutral
   * shape the store uses — the guard that keeps {@link #somParseDouble} from
   * accepting Java's extra {@code 12f} / {@code 0x1p3} spellings.
   */
  private static boolean isFloatLiteral(String raw) {
    if (raw.indexOf('x') >= 0 || raw.indexOf('X') >= 0) {
      return false;
    }
    char last = raw.charAt(raw.length() - 1);
    return last != 'd' && last != 'D' && last != 'f' && last != 'F';
  }
}
