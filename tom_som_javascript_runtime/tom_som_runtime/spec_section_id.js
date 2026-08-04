'use strict';

/**
 * Section-ID derivation for list/pattern sections (AA1 acceptance criteria
 * 3–6) — a faithful port of `tom_som_dart_runtime/lib/src/spec_section_id.dart`
 * (and `spec_section_id.py` / `SpecSectionId.java`).
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
 *
 * @param {number} month
 * @param {number} day
 * @returns {string}
 */
function encodeTwoLetterDate(month, day) {
  const monthLetter = String.fromCharCode(0x41 + (month - 1));
  let dayCode;
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
 *
 * @param {string} pattern
 * @returns {string}
 */
function sectionIdPatternPrefix(pattern) {
  return pattern.replace(_TRAILING_X, '');
}

/**
 * Raised when a section id would collide with another id in the same list
 * (criterion 5: overriding an id must keep every id in the list unique).
 */
class SpecSectionIdCollision extends Error {
  /**
   * @param {string} id
   * @param {string} listPath
   */
  constructor(id, listPath) {
    super(
      `section id "${id}" is already used in list "${listPath}"; ` +
        'section ids within a list must be unique.'
    );
    this.name = 'SpecSectionIdCollision';
    this.id = id;
    this.listPath = listPath;
  }
}

/**
 * Builds the generated section id for a new list item (criteria 3–4, 6).
 *
 * `pattern` is the list field's `@SectionIdPattern`; `month`/`day` are the
 * creation date; `existingIds` are the ids already assigned to the list's
 * items. The within-day number is `max(existing ids that share this day's
 * prefix) + 1`.
 *
 * @param {string} pattern
 * @param {number} month
 * @param {number} day
 * @param {Iterable<string>} existingIds
 * @returns {string}
 */
function generateListItemSectionId(pattern, month, day, existingIds) {
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

/**
 * The reserved `refersTo` slot naming a registry entry's own section id rather
 * than one of its form fields (`tom_specs_model_rules.md` §6.2).
 *
 * A registry key is written `<SECTIONID>.<slot>`; this is the one slot that is
 * not a form field name. Named because the instance-tier reference check keys
 * its registries by it, and it must be the same literal the static tier in
 * `tom_specs_clitool` accepts.
 */
const K_SECTION_ID_SLOT = '@sectionId';

/**
 * The id a list item is *identified by* — its `storedId` when it has one, and
 * otherwise the positional id derived from the list's `pattern` (YRD3).
 *
 * An item acquires a stored id when it is created through the editor (an AA1
 * generated id) or when a document overrides one (criterion 5). Items authored
 * without one are **anonymous** and are identified by their 1-based `position`
 * — the pattern with its `xxx` placeholder replaced (`GOAL-ITEM-xxx` →
 * `GOAL-ITEM-1`), falling back to `<fallbackStem>-<position>` for a
 * pattern-less list.
 *
 * Named once because two consumers must agree on it exactly: the markdown
 * writer, which emits it as the heading id, and the instance-tier reference
 * check, which resolves `@sectionId` references against it. A divergence there
 * would not be a cosmetic difference — it would red-flag a document whose
 * references are correct.
 *
 * @param {?string} storedId
 * @param {?string} pattern
 * @param {number} position
 * @param {string} fallbackStem
 * @returns {string}
 */
function effectiveListItemSectionId(storedId, pattern, position, fallbackStem) {
  if (storedId !== null && storedId !== undefined) {
    return storedId;
  }
  if (pattern !== null && pattern !== undefined) {
    return pattern.split('xxx').join(String(position));
  }
  return `${fallbackStem}-${position}`;
}

module.exports = {
  K_SECTION_ID_SLOT,
  effectiveListItemSectionId,
  encodeTwoLetterDate,
  sectionIdPatternPrefix,
  SpecSectionIdCollision,
  generateListItemSectionId,
};
