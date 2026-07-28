package tom_som_runtime;

/**
 * Hand-written runtime support for the generated typed object model ({@code
 * tom_som_java_v0}) — the instantiation-time version check (SOM §4.2) every
 * generated root facade performs. A faithful port of {@code som_facade.dart} /
 * {@code som_facade.py}.
 */
public final class SomFacade {
  private SomFacade() {}

  private static final class SomVersion {
    final int major;
    final int minor;

    SomVersion(int major, int minor) {
      this.major = major;
      this.minor = minor;
    }

    static SomVersion parse(String raw) {
      SomVersion v = tryParse(raw);
      if (v == null) {
        throw new SomVersionError("\"" + raw + "\" is not a valid major.minor version");
      }
      return v;
    }

    static SomVersion tryParse(String raw) {
      String[] parts = raw.split("\\.", -1);
      if (parts.length != 2) {
        return null;
      }
      Integer major = tryInt(parts[0]);
      Integer minor = tryInt(parts[1]);
      if (major == null || minor == null) {
        return null;
      }
      return new SomVersion(major, minor);
    }
  }

  private static Integer tryInt(String raw) {
    if (raw.isEmpty()) {
      return null;
    }
    int start = raw.charAt(0) == '-' ? 1 : 0;
    if (start == raw.length()) {
      return null;
    }
    for (int i = start; i < raw.length(); i++) {
      if (!Character.isDigit(raw.charAt(i))) {
        return null;
      }
    }
    try {
      return Integer.valueOf(Integer.parseInt(raw));
    } catch (NumberFormatException e) {
      return null;
    }
  }

  /**
   * Classifies a document's editability under the SOM §4.2 rules <b>without
   * throwing</b> (SOM §21). {@code generated} is the object model's own
   * {@code major.minor} version; {@code documentVersion} is the document's
   * recorded authoring stamp ({@code null}/empty for a brand-new, never-stamped
   * document).
   *
   * <p>This is the single definition of the version rules;
   * {@link #checkModelVersion(String, String)} throws based on the value
   * returned here, so the two never diverge.
   */
  public static SomEditability somEditabilityFor(String generated, String documentVersion) {
    if (documentVersion == null || documentVersion.isEmpty()) {
      return SomEditability.EDITABLE;
    }
    SomVersion gen = SomVersion.parse(generated);
    SomVersion doc = SomVersion.tryParse(documentVersion);
    if (doc == null) {
      return SomEditability.INVALID_VERSION;
    }
    if (doc.major != gen.major) {
      return SomEditability.READ_ONLY_CROSS_MAJOR;
    }
    if (doc.minor > gen.minor) {
      return SomEditability.REJECTED_NEWER_MINOR;
    }
    return SomEditability.EDITABLE;
  }

  /**
   * The instantiation-time version check every generated root facade performs
   * (SOM §4.2). {@code generated} is the object model's own {@code major.minor}
   * version; {@code documentVersion} is the document's recorded authoring stamp
   * ({@code null}/empty for a brand-new, never-stamped document).
   *
   * <ul>
   *   <li>a {@code null}/empty document stamp is always accepted;
   *   <li>within the same major version, a document whose minor is &le; the
   *       generated minor is editable; a greater minor is rejected;
   *   <li>a different major version is always rejected.
   * </ul>
   *
   * <p>Throws based on {@link #somEditabilityFor(String, String)}, so the check
   * and the classification never diverge.
   *
   * @throws SomVersionError on any rejection or an unparseable stamp.
   */
  public static void checkModelVersion(String generated, String documentVersion) {
    switch (somEditabilityFor(generated, documentVersion)) {
      case EDITABLE:
        return;
      case INVALID_VERSION:
        throw new SomVersionError(
            "document model version \"" + documentVersion + "\" is not a valid major.minor");
      case READ_ONLY_CROSS_MAJOR:
        {
          SomVersion gen = SomVersion.parse(generated);
          SomVersion doc = SomVersion.parse(documentVersion);
          throw new SomVersionError(
              "document major version "
                  + doc.major
                  + " differs from the object model major version "
                  + gen.major
                  + "; cross-major documents are read-only");
        }
      case REJECTED_NEWER_MINOR:
        throw new SomVersionError(
            "document model version "
                + documentVersion
                + " is newer than the object model version "
                + generated
                + "; an older object model cannot edit a newer document");
      default:
        return;
    }
  }
}
