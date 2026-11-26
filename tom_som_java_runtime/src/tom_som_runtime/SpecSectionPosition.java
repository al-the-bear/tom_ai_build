package tom_som_runtime;

import java.util.List;

/**
 * One position of a section in a document root: a class reached there (its own
 * node), or a member of a class that carries a section id of its own.
 */
public final class SpecSectionPosition {
  /** The document path, list items written {@code <list>-*}. */
  public final String path;
  /** The class reached ({@link #isMember} false), or the class the member belongs to. */
  public final String className;
  /** The section ids from the root to here, this position's own last. */
  public final List<String> sectionIds;
  /**
   * Whether this is a member position (a form, list, content or section member
   * with its own section id) rather than a class reached.
   */
  public final boolean isMember;
  /**
   * For a class position, the member it is reached through ({@code null} at the
   * root); for a member position, the member itself.
   */
  public final SpecField member;

  public SpecSectionPosition(
      String path, String className, List<String> sectionIds, boolean isMember, SpecField member) {
    this.path = path;
    this.className = className;
    this.sectionIds = sectionIds;
    this.isMember = isMember;
    this.member = member;
  }
}
