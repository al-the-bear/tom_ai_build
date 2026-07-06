package tom_som_runtime;

/**
 * The section-path grammar shared by the in-memory document and the meta-model
 * traversal — a faithful port of {@code spec_paths.dart} / {@code spec_paths.py}.
 *
 * <p>A path is the globally-unique address of a node in a concrete document:
 * the <b>root</b> is the document root's section segment (its {@code @SectionId}
 * when present, otherwise the root class name); a <b>child field</b> appends
 * {@code /<segment>}; a <b>complex / section</b> field collapses into its target
 * class (no extra segment); a <b>list item</b> appends {@code -<seq>} to the list
 * field's path (no {@code /}). Form-field values are not path segments.
 */
public final class SpecPaths {
  private SpecPaths() {}

  /** The path separator between section segments. */
  public static final String SEPARATOR = "/";

  /** Joins {@code parent} with a child {@code segment} using the separator. */
  public static String join(String parent, String segment) {
    return parent + SEPARATOR + segment;
  }

  /** Splits {@code path} into its {@code /}-separated segments. */
  public static String[] segments(String path) {
    return path.split(SEPARATOR, -1);
  }

  /** The path of the {@code seq}-th item appended to the list at {@code listPath}. */
  public static String listItemPath(String listPath, int seq) {
    return listPath + "-" + seq;
  }

  /** A list-item segment split into its base segment and sequence number. */
  public static final class ListItemSegment {
    public final String base;
    public final int seq;

    public ListItemSegment(String base, int seq) {
      this.base = base;
      this.seq = seq;
    }
  }

  /**
   * Splits a list-item {@code segment} into its base segment and sequence number
   * when it ends in {@code -<digits>}, or returns {@code null} otherwise.
   *
   * <p>Only an all-digit tail counts, so a hyphenated {@code @SectionId} such as
   * {@code CUOPME-OPER-LST} is never mis-read as a list item.
   */
  public static ListItemSegment splitListItemSegment(String segment) {
    int dash = segment.lastIndexOf('-');
    if (dash <= 0 || dash == segment.length() - 1) {
      return null;
    }
    String tail = segment.substring(dash + 1);
    for (int i = 0; i < tail.length(); i++) {
      if (!Character.isDigit(tail.charAt(i))) {
        return null;
      }
    }
    return new ListItemSegment(segment.substring(0, dash), Integer.parseInt(tail));
  }
}
