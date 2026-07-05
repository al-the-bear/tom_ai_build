/// Section-ID derivation for list/pattern sections (§ "auto section-id
/// generation", AA1 acceptance criteria 3–6).
///
/// A single-valued section carries a *fixed* id — its `@SectionId`, which is
/// already the path segment, so nothing is derived. A **list item**, by
/// contrast, gets a generated id built from the list field's `@SectionIdPattern`
/// (e.g. `DACEN-ITEM-xxx`):
///
///   `<prefix><two-letter-date><number-within-the-day>`
///
/// where `<prefix>` is the pattern with its trailing placeholder (`xxx`)
/// stripped (`DACEN-ITEM-`), `<two-letter-date>` encodes the creation date (see
/// [encodeTwoLetterDate]), and `<number-within-the-day>` is the 1-based ordinal
/// of the item among the list's items created the same day.
///
/// The within-day number is derived from the list's *current* ids as
/// `max(existing for that day) + 1`. This gives both required behaviours with
/// one rule (criterion 6): deleting a middle item never renumbers the rest (the
/// max is unchanged, so a new same-day item takes the next free number and the
/// numbering may stay non-consecutive), while deleting the last item lowers the
/// max so a new same-day item *reuses* the just-freed id.
library;

/// Encodes [date] as the two-letter day code used in generated section ids
/// (criterion 4).
///
/// * First letter — month: `Jan → A`, `Feb → B`, … `Dec → L`.
/// * Second letter — day-of-month: days `1–26 → A–Z`; days `27–31 → 0,1,2,3,4`.
String encodeTwoLetterDate(DateTime date) {
  final monthLetter = String.fromCharCode(0x41 + (date.month - 1));
  final day = date.day;
  final String dayCode;
  if (day <= 26) {
    dayCode = String.fromCharCode(0x41 + (day - 1));
  } else {
    // 27 → '0', 28 → '1', … 31 → '4'.
    dayCode = String.fromCharCode(0x30 + (day - 27));
  }
  return '$monthLetter$dayCode';
}

/// The static prefix of a `@SectionIdPattern`: the pattern with its trailing
/// placeholder (the run of trailing `x` characters) removed. `DACEN-ITEM-xxx`
/// → `DACEN-ITEM-`.
String sectionIdPatternPrefix(String pattern) =>
    pattern.replaceFirst(RegExp(r'x+$'), '');

/// Raised when a section id would collide with another id in the same list
/// (criterion 5: overriding an id must keep every id in the list unique).
class SpecSectionIdCollision implements Exception {
  /// The offending id that already exists in the list.
  final String id;

  /// The list path whose items must stay unique.
  final String listPath;

  const SpecSectionIdCollision(this.id, this.listPath);

  @override
  String toString() =>
      'SpecSectionIdCollision: section id "$id" is already used in list '
      '"$listPath"; section ids within a list must be unique.';
}

/// Builds the generated section id for a new list item (criteria 3–4, 6).
///
/// [pattern] is the list field's `@SectionIdPattern`; [date] is the creation
/// date; [existingIds] are the ids already assigned to the list's items. The
/// within-day number is `max(existing ids that share this day's prefix) + 1`.
String generateListItemSectionId(
  String pattern,
  DateTime date,
  Iterable<String> existingIds,
) {
  final dayPrefix = '${sectionIdPatternPrefix(pattern)}${encodeTwoLetterDate(date)}';
  var maxForDay = 0;
  for (final id in existingIds) {
    if (!id.startsWith(dayPrefix)) continue;
    final tail = id.substring(dayPrefix.length);
    final n = int.tryParse(tail);
    if (n != null && n > maxForDay) maxForDay = n;
  }
  return '$dayPrefix${maxForDay + 1}';
}
