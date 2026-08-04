package tom_som_runtime;

/**
 * Section-ID derivation for list/pattern sections (AA1 acceptance criteria 3–6)
 * — a faithful port of {@code spec_section_id.dart} / {@code spec_section_id.py}.
 *
 * <p>A single-valued section carries a <i>fixed</i> id — its {@code @SectionId},
 * which is already the path segment, so nothing is derived. A <b>list item</b>,
 * by contrast, gets a generated id built from the list field's
 * {@code @SectionIdPattern} (e.g. {@code DACEN-ITEM-xxx}):
 *
 * <pre>{@code <prefix><two-letter-date><number-within-the-day>}</pre>
 *
 * where {@code <prefix>} is the pattern with its trailing placeholder
 * ({@code xxx}) stripped, {@code <two-letter-date>} encodes the creation date
 * (see {@link #encodeTwoLetterDate}), and {@code <number-within-the-day>} is the
 * 1-based ordinal of the item among the list's items created the same day.
 *
 * <p>The within-day number is derived from the list's <i>current</i> ids as
 * {@code max(existing for that day) + 1}. This gives both required behaviours
 * with one rule (criterion 6): deleting a middle item never renumbers the rest
 * (the max is unchanged), while deleting the last item lowers the max so a new
 * same-day item <i>reuses</i> the just-freed id.
 */
public final class SpecSectionId {
  private SpecSectionId() {}

  /**
   * The reserved {@code refersTo} slot naming a registry entry's own section id
   * rather than one of its form fields ({@code tom_specs_model_rules.md} §6.2).
   *
   * <p>A registry key is written {@code <SECTIONID>.<slot>}; this is the one slot
   * that is not a form field name. Named because the instance-tier reference
   * check keys its registries by it, and it must be the same literal the static
   * tier in {@code tom_specs_clitool} accepts.
   */
  public static final String K_SECTION_ID_SLOT = "@sectionId";

  /**
   * The id a list item is <i>identified by</i> — its {@code storedId} when it has
   * one, and otherwise the positional id derived from the list's {@code pattern}
   * (YRD3).
   *
   * <p>An item acquires a stored id when it is created through the editor (an AA1
   * generated id) or when a document overrides one (criterion 5). Items authored
   * without one are <b>anonymous</b> and are identified by their 1-based
   * {@code position} — the pattern with its {@code xxx} placeholder replaced
   * ({@code GOAL-ITEM-xxx} → {@code GOAL-ITEM-1}), falling back to
   * {@code <fallbackStem>-<position>} for a pattern-less list.
   *
   * <p>Named once because two consumers must agree on it exactly: the markdown
   * writer, which emits it as the heading id, and the instance-tier reference
   * check, which resolves {@code @sectionId} references against it. A divergence
   * there would not be a cosmetic difference — it would red-flag a document whose
   * references are correct.
   */
  public static String effectiveListItemSectionId(
      String storedId, String pattern, int position, String fallbackStem) {
    if (storedId != null) {
      return storedId;
    }
    if (pattern != null) {
      return pattern.replace("xxx", String.valueOf(position));
    }
    return fallbackStem + "-" + position;
  }

  /**
   * Encodes a ({@code month}, {@code day}) pair as the two-letter day code used
   * in generated section ids (criterion 4).
   *
   * <ul>
   *   <li>First letter — month: {@code Jan → A}, {@code Feb → B}, … {@code Dec → L}.
   *   <li>Second letter — day-of-month: days {@code 1–26 → A–Z}; days
   *       {@code 27–31 → 0,1,2,3,4}.
   * </ul>
   */
  public static String encodeTwoLetterDate(int month, int day) {
    char monthLetter = (char) (0x41 + (month - 1));
    char dayCode;
    if (day <= 26) {
      dayCode = (char) (0x41 + (day - 1));
    } else {
      // 27 → '0', 28 → '1', … 31 → '4'.
      dayCode = (char) (0x30 + (day - 27));
    }
    return "" + monthLetter + dayCode;
  }

  /**
   * The static prefix of a {@code @SectionIdPattern}: the pattern with its
   * trailing placeholder (the run of trailing {@code x} characters) removed.
   * {@code DACEN-ITEM-xxx} → {@code DACEN-ITEM-}.
   */
  public static String sectionIdPatternPrefix(String pattern) {
    int end = pattern.length();
    while (end > 0 && pattern.charAt(end - 1) == 'x') {
      end--;
    }
    return pattern.substring(0, end);
  }

  /**
   * Builds the generated section id for a new list item (criteria 3–4, 6).
   *
   * <p>{@code pattern} is the list field's {@code @SectionIdPattern};
   * {@code month}/{@code day} are the creation date; {@code existingIds} are the
   * ids already assigned to the list's items. The within-day number is
   * {@code max(existing ids that share this day's prefix) + 1}.
   */
  public static String generateListItemSectionId(
      String pattern, int month, int day, Iterable<String> existingIds) {
    String dayPrefix = sectionIdPatternPrefix(pattern) + encodeTwoLetterDate(month, day);
    int maxForDay = 0;
    for (String id : existingIds) {
      if (id == null || !id.startsWith(dayPrefix)) {
        continue;
      }
      String tail = id.substring(dayPrefix.length());
      Integer n = parseNonNegativeInt(tail);
      if (n != null && n > maxForDay) {
        maxForDay = n;
      }
    }
    return dayPrefix + (maxForDay + 1);
  }

  private static Integer parseNonNegativeInt(String s) {
    if (s.isEmpty()) {
      return null;
    }
    for (int i = 0; i < s.length(); i++) {
      if (!Character.isDigit(s.charAt(i))) {
        return null;
      }
    }
    try {
      return Integer.valueOf(s);
    } catch (NumberFormatException e) {
      return null;
    }
  }
}
