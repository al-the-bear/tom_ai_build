package tom_som_runtime;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * The complete exported model — a <i>class graph</i>, not an expanded tree: each
 * class appears once and field {@code elementType}/{@code type} references are
 * followed on demand by a traversal.
 */
public final class SpecModel {
  /**
   * How old a snapshot may get before {@link #checkStamp} calls it aged.
   *
   * <p>A fortnight: long enough that a healthy working copy is never nagged,
   * short enough that structural feedback keyed to a snapshot's paths is not
   * recorded against a model that has moved past them.
   */
  public static final Duration DEFAULT_MAX_SNAPSHOT_AGE = Duration.ofDays(14);

  /**
   * The generation-stamp timestamp grammar, spelled out rather than delegated to
   * {@code Instant.parse}: {@code YYYY-MM-DDTHH:MM:SS}, an optional fractional
   * part, and an optional {@code Z} / {@code ±HH:MM} / {@code ±HHMM} offset.
   *
   * <p>Every SOM runtime carries this same grammar. Delegating to each
   * platform's own parser would make the accepted set differ by language —
   * several of the nine have no date library at all — and a stamp that reads on
   * one platform and not another is exactly the divergence the shared corpus
   * exists to catch.
   */
  private static final Pattern STAMP_PATTERN =
      Pattern.compile(
          "^(\\d{4})-(\\d{2})-(\\d{2})[Tt ](\\d{2}):(\\d{2}):(\\d{2})"
              + "(?:\\.(\\d+))?(Z|z|[+-]\\d{2}:?\\d{2})?$");

  public final List<SpecRoot> roots;
  public final Map<String, SpecClass> classes;
  public final int modelVersion;
  public final String modelVersionLabel;
  /**
   * When the snapshot was exported (UTC), or {@code null} when it carries no
   * {@code generatedAt} — an export predating the key, or a hand-built model.
   */
  public final Instant generatedAt;
  /**
   * The <i>file format's</i> own version, distinct from {@link #modelVersion}
   * (which model the snapshot describes). Null when undeclared.
   */
  public final Integer metaSchemaVersion;
  /**
   * The class count the snapshot declares, or {@code null} when undeclared. Kept
   * separate from {@code classes.size()}: the declared value is what the
   * exporter recorded, the actual value is what survived to the reader, and
   * comparing them is the point ({@link #checkStamp}).
   */
  public final Integer classCount;
  /** The document-root count the snapshot declares, or {@code null}. */
  public final Integer rootCount;
  /**
   * The canonical container class — the single true tree root, which is not
   * itself a document and so does not appear in {@link #roots}. Null when the
   * model has no container (e.g. a synthetic export).
   */
  public final String containerRoot;

  /** A model with no generation stamp — a hand-built one, or an older export. */
  public SpecModel(
      List<SpecRoot> roots,
      Map<String, SpecClass> classes,
      int modelVersion,
      String modelVersionLabel) {
    this(roots, classes, modelVersion, modelVersionLabel, null, null, null, null, null);
  }

  public SpecModel(
      List<SpecRoot> roots,
      Map<String, SpecClass> classes,
      int modelVersion,
      String modelVersionLabel,
      Instant generatedAt,
      Integer metaSchemaVersion,
      Integer classCount,
      Integer rootCount,
      String containerRoot) {
    this.roots = roots;
    this.classes = classes;
    this.modelVersion = modelVersion;
    this.modelVersionLabel = modelVersionLabel;
    this.generatedAt = generatedAt;
    this.metaSchemaVersion = metaSchemaVersion;
    this.classCount = classCount;
    this.rootCount = rootCount;
    this.containerRoot = containerRoot;
  }

  /**
   * Checks the generation stamp against the payload and the clock.
   *
   * <p>{@code now} is injectable so callers (and tests) can evaluate age against
   * a fixed instant instead of the wall clock; pass {@code null} for "now".
   */
  public SpecModelStampCheck checkStamp(Duration maxAge, Instant now) {
    Instant moment = now == null ? Instant.now() : now;
    Duration maximum = maxAge == null ? DEFAULT_MAX_SNAPSHOT_AGE : maxAge;
    return new SpecModelStampCheck(
        generatedAt == null ? null : Duration.between(generatedAt, moment),
        maximum,
        classCount,
        classes.size(),
        rootCount,
        roots.size());
  }

  /** {@link #checkStamp(Duration, Instant)} against the default threshold and now. */
  public SpecModelStampCheck checkStamp() {
    return checkStamp(DEFAULT_MAX_SNAPSHOT_AGE, null);
  }

  /**
   * The length of {@code month} in {@code year}, Gregorian. Used to reject a day
   * that does not exist rather than letting it roll into the next month: some
   * SOM runtimes' date types would turn 31 February into 3 March while others
   * reject it outright — so the grammar rejects it everywhere.
   */
  private static int daysInMonth(int year, int month) {
    if (month != 2) {
      return new int[] {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}[month - 1];
    }
    boolean isLeap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    return isLeap ? 29 : 28;
  }

  /**
   * Parses a generation-stamp timestamp to a UTC {@link Instant}, or returns
   * {@code null}.
   *
   * <p>A timestamp carrying <b>no</b> zone is read as UTC — a staleness verdict
   * that changed with the reader's timezone would be a defect in its own right,
   * and one the other eight SOM runtimes could not mirror anyway (several have
   * no timezone database).
   *
   * <p>Anything outside the grammar — or carrying an out-of-range field —
   * degrades to {@code null} rather than throwing: an unreadable stamp is not
   * worth failing a whole model over.
   */
  public static Instant parseStampTimestamp(String raw) {
    if (raw == null) {
      return null;
    }
    Matcher m = STAMP_PATTERN.matcher(raw.trim());
    if (!m.matches()) {
      return null;
    }
    int year = Integer.parseInt(m.group(1));
    int month = Integer.parseInt(m.group(2));
    int day = Integer.parseInt(m.group(3));
    int hour = Integer.parseInt(m.group(4));
    int minute = Integer.parseInt(m.group(5));
    int second = Integer.parseInt(m.group(6));
    if (month < 1 || month > 12 || day < 1 || day > daysInMonth(year, month)) {
      return null;
    }
    if (hour > 23 || minute > 59 || second > 59) {
      return null;
    }
    // Right-pad the fraction to nanoseconds; a longer fraction is truncated.
    String frac = m.group(7) == null ? "" : m.group(7);
    StringBuilder nanos = new StringBuilder(frac.length() > 9 ? frac.substring(0, 9) : frac);
    while (nanos.length() < 9) {
      nanos.append('0');
    }
    long epochSeconds = epochDay(year, month, day) * 86400L + hour * 3600L + minute * 60L + second;
    String zone = m.group(8);
    if (zone != null && !zone.equalsIgnoreCase("Z")) {
      String digits = zone.substring(1).replace(":", "");
      long offset =
          (Integer.parseInt(digits.substring(0, 2)) * 60L
                  + Integer.parseInt(digits.substring(2)))
              * 60L;
      epochSeconds += zone.charAt(0) == '-' ? offset : -offset;
    }
    return Instant.ofEpochSecond(epochSeconds, Integer.parseInt(nanos.toString()));
  }

  /**
   * Days since 1970-01-01 for a proleptic-Gregorian civil date (Howard Hinnant's
   * {@code days_from_civil}). Hand-rolled rather than via {@code LocalDate} so
   * the arithmetic is the same one the Go / Rust / C / C++ ports carry.
   */
  private static long epochDay(int year, int month, int day) {
    long y = year - (month <= 2 ? 1 : 0);
    long era = (y >= 0 ? y : y - 399) / 400;
    long yoe = y - era * 400;
    long doy = (153L * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1;
    long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
  }

  /**
   * The {@code major.minor} version string used in the DocSpecs markdown
   * declaration (Dart / Python parity — mirrors Python's
   * {@code SpecModel.model_version_string}).
   */
  public String modelVersionString() {
    return somModelVersionString(modelVersion, modelVersionLabel);
  }

  /**
   * Derives the {@code major.minor} DocSpecs version string from a model's
   * integer version and its optional free-form label (port of Python's
   * {@code som_model_version_string}).
   *
   * <p>When the label's {@code +}-stripped core has at least two dot-separated
   * integer components, those become {@code major.minor}; otherwise the result
   * is {@code <major>.0}.
   */
  public static String somModelVersionString(int major, String label) {
    if (label != null && !label.isEmpty()) {
      String core = label.split("\\+", 2)[0].trim();
      String[] parts = core.split("\\.", -1);
      if (parts.length >= 2) {
        String maj = parts[0].trim();
        String minor = parts[1].trim();
        if (isSignedDigits(maj) && isSignedDigits(minor)) {
          return Integer.parseInt(maj) + "." + Integer.parseInt(minor);
        }
      }
    }
    return major + ".0";
  }

  /** Whether {@code s} matches {@code /^[+-]?[0-9]+$/}. */
  private static boolean isSignedDigits(String s) {
    if (s.isEmpty()) {
      return false;
    }
    int i = (s.charAt(0) == '+' || s.charAt(0) == '-') ? 1 : 0;
    if (i == s.length()) {
      return false;
    }
    for (; i < s.length(); i++) {
      if (s.charAt(i) < '0' || s.charAt(i) > '9') {
        return false;
      }
    }
    return true;
  }

  public SpecClass classNamed(String name) {
    if (name == null) {
      return null;
    }
    return classes.get(name);
  }

  /**
   * The document root whose {@link SpecRoot#type} equals {@code type} (SOM
   * § item 12).
   *
   * <p>Replaces the recurring {@code roots.firstWhere((r) => r.type == …)}
   * boilerplate. Throws {@link IllegalArgumentException} when no root carries
   * that type — with a message that names the missing type and the ones that do
   * exist.
   */
  public SpecRoot rootByType(String type) {
    for (SpecRoot r : roots) {
      if (r.type.equals(type)) {
        return r;
      }
    }
    List<String> available = new ArrayList<>();
    for (SpecRoot r : roots) {
      available.add(r.type);
    }
    throw new IllegalArgumentException(
        "no document root with type \"" + type + "\" (have: "
            + String.join(", ", available) + ")");
  }

  @SuppressWarnings("unchecked")
  public static SpecModel fromJson(Map<String, Object> j) {
    Map<String, SpecClass> classes = new LinkedHashMap<>();
    Object rawClasses = j.get("classes");
    if (rawClasses instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawClasses).entrySet()) {
        classes.put(e.getKey(), SpecClass.fromJson((Map<String, Object>) e.getValue()));
      }
    }
    List<SpecRoot> roots = new ArrayList<>();
    Object rawRoots = j.get("roots");
    if (rawRoots instanceof List) {
      for (Object e : (List<Object>) rawRoots) {
        roots.add(SpecRoot.fromJson((Map<String, Object>) e));
      }
    }
    Object version = j.get("modelVersion");
    Object label = j.get("modelVersionLabel");
    String labelStr = (label == null || label.toString().isEmpty()) ? null : label.toString();
    Object container = j.get("containerRoot");
    String containerStr =
        (container == null || container.toString().isEmpty()) ? null : container.toString();
    Object generated = j.get("generatedAt");
    return new SpecModel(
        roots,
        classes,
        version instanceof Number ? ((Number) version).intValue() : 0,
        labelStr,
        parseStampTimestamp(generated == null ? null : generated.toString()),
        optionalInt(j.get("metaSchemaVersion")),
        optionalInt(j.get("classCount")),
        optionalInt(j.get("rootCount")),
        containerStr);
  }

  /**
   * A stamp count as an {@link Integer}, or {@code null} when the key is absent.
   *
   * <p>Absent must stay {@code null} rather than becoming {@code 0}: a snapshot
   * predating the stamp keys would otherwise declare zero classes and read as
   * corrupt.
   */
  private static Integer optionalInt(Object raw) {
    return raw instanceof Number ? ((Number) raw).intValue() : null;
  }
}
