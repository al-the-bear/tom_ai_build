/**
 * Section-ID derivation for list/pattern sections (AA1 acceptance criteria
 * 3–6) — a faithful port of `tom_som_dart_runtime/lib/src/spec_section_id.dart`
 * (and `spec_section_id.py` / `SpecSectionId.java` / the JavaScript
 * `spec_section_id.js`).
 *
 * A single-valued section carries a *fixed* id — its `@SectionId`, which is
 * already the path segment, so nothing is derived. A **list item**, by
 * contrast, gets a generated id built from the list field's
 * `@SectionIdPattern` (e.g. `DACEN-ITEM-xxx`):
 *
 *     `<prefix><two-letter-date><number-within-the-day>`
 *
 * where `<prefix>` is the pattern with its trailing placeholder (`xxx`)
 * stripped (`DACEN-ITEM-`), `<two-letter-date>` encodes the creation date (see
 * {@link encodeTwoLetterDate}), and `<number-within-the-day>` is the 1-based
 * ordinal of the item among the list's items created the same day.
 *
 * The within-day number is derived from the list's *current* ids as
 * `max(existing for that day) + 1`. This gives both required behaviours with
 * one rule (criterion 6): deleting a middle item never renumbers the rest (the
 * max is unchanged, so a new same-day item takes the next free number and the
 * numbering may stay non-consecutive), while deleting the last item lowers the
 * max so a new same-day item *reuses* the just-freed id.
 */

const _TRAILING_X = /x+$/;

/**
 * Encodes a (`month`, `day`) pair as the two-letter day code used in generated
 * section ids (criterion 4).
 *
 *   * First letter — month: `Jan → A`, `Feb → B`, … `Dec → L`.
 *   * Second letter — day-of-month: days `1–26 → A–Z`; days
 *     `27–31 → 0,1,2,3,4`.
 */
export function encodeTwoLetterDate(month: number, day: number): string {
  const monthLetter = String.fromCharCode(0x41 + (month - 1));
  let dayCode: string;
  if (day <= 26) {
    dayCode = String.fromCharCode(0x41 + (day - 1));
  } else {
    // 27 → '0', 28 → '1', … 31 → '4'.
    dayCode = String.fromCharCode(0x30 + (day - 27));
  }
  return `${monthLetter}${dayCode}`;
}

/**
 * The static prefix of a `@SectionIdPattern`: the pattern with its trailing
 * placeholder (the run of trailing `x` characters) removed.
 * `DACEN-ITEM-xxx` → `DACEN-ITEM-`.
 */
export function sectionIdPatternPrefix(pattern: string): string {
  return pattern.replace(_TRAILING_X, '');
}

/**
 * Raised when a section id would collide with another id in the same list
 * (criterion 5: overriding an id must keep every id in the list unique).
 */
export class SpecSectionIdCollision extends Error {
  id: string;
  listPath: string;

  constructor(id: string, listPath: string) {
    super(
      `section id "${id}" is already used in list "${listPath}"; ` +
        'section ids within a list must be unique.',
    );
    this.name = 'SpecSectionIdCollision';
    this.id = id;
    this.listPath = listPath;
    // Restore the prototype chain across the ES5 `Error` boundary.
    Object.setPrototypeOf(this, SpecSectionIdCollision.prototype);
  }
}

/**
 * Builds the generated section id for a new list item (criteria 3–4, 6).
 *
 * `pattern` is the list field's `@SectionIdPattern`; `month`/`day` are the
 * creation date; `existingIds` are the ids already assigned to the list's
 * items. The within-day number is `max(existing ids that share this day's
 * prefix) + 1`.
 */
export function generateListItemSectionId(
  pattern: string,
  month: number,
  day: number,
  existingIds: Iterable<string>,
): string {
  const dayPrefix = `${sectionIdPatternPrefix(pattern)}${encodeTwoLetterDate(month, day)}`;
  let maxForDay = 0;
  for (const id of existingIds) {
    if (id === null || id === undefined || !id.startsWith(dayPrefix)) {
      continue;
    }
    const tail = id.slice(dayPrefix.length);
    if (tail === '' || !/^[0-9]+$/.test(tail)) {
      continue;
    }
    const n = parseInt(tail, 10);
    if (n > maxForDay) {
      maxForDay = n;
    }
  }
  return `${dayPrefix}${maxForDay + 1}`;
}
