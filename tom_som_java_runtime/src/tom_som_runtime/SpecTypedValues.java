package tom_som_runtime;

import java.util.List;
import java.util.regex.Pattern;

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
 *   <li>numbers are read the way the TypeScript runtime reads them (the
 *       canonical reading, decision tspubnondart20 (a)): the text is trimmed of
 *       surrounding whitespace, an {@code int} is an optional sign and ASCII
 *       digits ({@code ^[+-]?[0-9]+$}), a {@code double} / {@code num} a
 *       decimal or exponent literal
 *       ({@code ^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$});
 *       everything else — {@code NaN}, {@code Infinity}, hexadecimal, digit
 *       separators, a {@code d}/{@code f} suffix, non-ASCII digits — reads as
 *       {@code null}, although {@code Integer.valueOf} / {@code Double.valueOf}
 *       would take some of it, because a spec value is finite;
 *   <li>{@code int} — {@link #somParseInt} also reads {@code null} for an
 *       integer literal outside the {@link Integer} range;
 *   <li>{@code double} — formatting always carries a fraction or an exponent,
 *       so an integral value
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

  /** A decimal integer literal with an optional sign. */
  private static final Pattern INT_TEXT = Pattern.compile("[+-]?[0-9]+");

  /** A floating literal with an optional exponent (also a plain integer). */
  private static final Pattern FLOAT_TEXT =
      Pattern.compile("[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)(?:[eE][+-]?[0-9]+)?");

  /**
   * The characters JavaScript's {@code String.prototype.trim} removes (its
   * WhiteSpace and LineTerminator sets), so every runtime trims the same text;
   * Java's {@code strip()} / {@code trim()} use other sets.
   */
  private static final String TRIM_CHARS =
      "\t\n\u000B\f\r \u00A0\u1680\u2000\u2001\u2002\u2003\u2004\u2005\u2006"
          + "\u2007\u2008\u2009\u200A\u2028\u2029\u202F\u205F\u3000\uFEFF";

  private static String trimmed(String raw) {
    int start = 0;
    int end = raw.length();
    while (start < end && TRIM_CHARS.indexOf(raw.charAt(start)) >= 0) {
      start++;
    }
    while (end > start && TRIM_CHARS.indexOf(raw.charAt(end - 1)) >= 0) {
      end--;
    }
    return raw.substring(start, end);
  }

  /** Parses a stored string as {@code int}, or {@code null} when absent/unparsable. */
  public static Integer somParseInt(String raw) {
    if (raw == null || raw.isEmpty()) {
      return null;
    }
    String text = trimmed(raw);
    if (!INT_TEXT.matcher(text).matches()) {
      return null;
    }
    try {
      return Integer.valueOf(text);
    } catch (NumberFormatException e) {
      return null; // outside the Integer range
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
   * <p>The text is trimmed and must match the decimal literal grammar; the
   * forms {@code Double.valueOf} additionally accepts — {@code NaN},
   * {@code Infinity}, a {@code d}/{@code f} type suffix, hexadecimal floats —
   * read as {@code null}, because the store is language-neutral.
   */
  public static Double somParseDouble(String raw) {
    if (raw == null || raw.isEmpty()) {
      return null;
    }
    String text = trimmed(raw);
    if (!FLOAT_TEXT.matcher(text).matches()) {
      return null;
    }
    Double value = Double.valueOf(text);
    // A literal that overflows (1e400) is no value: a spec value is finite.
    return Double.isFinite(value) ? value : null;
  }

  /**
   * Formats a {@code double} for the store; {@code null} becomes {@code ""}
   * (clear, D4).
   *
   * <p>A {@code double} always renders with a fraction or an exponent
   * ({@code 2.0}, {@code 1e+21}),
   * matching Dart's {@code double.toString} — the store is language-neutral, so
   * the same value must serialize identically everywhere.
   */
  public static String somFormatDouble(Double value) {
    if (value == null) {
      return "";
    }
    if (Double.isNaN(value) || Double.isInfinite(value)) {
      return value.toString();
    }
    // One layout in every runtime (decision tspubnondart29 (a)): the shortest
    // digits in JavaScript's Number toString layout, ".0" on a whole value
    // (10000000.0, 1e-7, 1e+21) — the review pass's float form. Double.toString
    // writes 1.0E7 and 5.0E-4.
    return SpecDocumentYaml.formatFloat(value);
  }

  /**
   * Parses a stored string as {@link Integer} when integral, else {@link Double}
   * — Dart's {@code num.tryParse}, so a {@code num} field keeps the narrower
   * type when the text carries no fraction.
   */
  public static Number somParseNum(String raw) {
    Integer asInt = somParseInt(raw);
    // Why: deliberately not a ternary. `cond ? Integer : Double` is a Java
    // conditional expression over two different boxed numeric types, so binary
    // numeric promotion applies: BOTH arms are unboxed to `double` and the
    // result re-boxed as `Double`. That would (a) throw NPE when the double
    // parse legitimately returns null, and (b) silently widen an integral `7`
    // to `7.0`, which `somFormatNum` would then write back as "7.0" instead of
    // "7" — the exact single-numeric-type divergence this contract forbids.
    if (asInt != null) {
      return asInt;
    }
    return somParseDouble(raw);
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
   * The scalar base of a declared field type: {@code int?} → {@code int},
   * {@code null} stays {@code null}.
   */
  public static String somScalarBase(String typeName) {
    if (typeName == null) {
      return null;
    }
    return typeName.endsWith("?")
        ? typeName.substring(0, typeName.length() - 1)
        : typeName;
  }

  /**
   * Whether {@code raw}, stored in a field declared as {@code typeName}, is text
   * that type's parser can read.
   *
   * <p>Only {@code int}, {@code double}, {@code num} and {@code bool} constrain
   * their text; every other type (strings, and enums, whose domain
   * {@code enumValueUnknown} checks) accepts any text. Empty or absent text is
   * readable: it is how a field is unset. The validator reports a stored value
   * this rejects as {@code valueTypeMismatch}, the setters refuse to store one,
   * and the typed reads throw on one — so text a typed field cannot read is
   * never silently read as unset.
   */
  public static boolean somTypedTextReadable(String typeName, String raw) {
    if (raw == null || raw.isEmpty()) {
      return true;
    }
    String base = somScalarBase(typeName);
    if ("int".equals(base)) {
      return somParseInt(raw) != null;
    }
    if ("double".equals(base)) {
      return somParseDouble(raw) != null;
    }
    if ("num".equals(base)) {
      return somParseNum(raw) != null;
    }
    if ("bool".equals(base)) {
      return somParseBool(raw) != null;
    }
    return true;
  }
}
