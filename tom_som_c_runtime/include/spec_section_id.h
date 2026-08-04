/* spec_section_id — section-ID derivation for list/pattern sections (AA1
 * acceptance criteria 3–6), a faithful port of the Rust `spec_section_id.rs`.
 *
 * A single-valued section carries a *fixed* id — its `@SectionId`, already the
 * path segment, so nothing is derived. A **list item** instead gets a generated
 * id built from the list field's `@SectionIdPattern` (e.g. `DACEN-ITEM-xxx`):
 *
 *   <prefix><two-letter-date><number-within-the-day>
 *
 * where <prefix> is the pattern with its trailing placeholder (`xxx`) stripped,
 * <two-letter-date> encodes the creation date, and <number-within-the-day> is
 * the 1-based ordinal of the item among the list's items created the same day,
 * computed as max(existing for that day) + 1. That single rule gives both
 * required behaviours (criterion 6): deleting a middle item never renumbers the
 * rest, while deleting the last item lowers the max so a new same-day item
 * reuses the just-freed id.
 */
#ifndef SPEC_SECTION_ID_H
#define SPEC_SECTION_ID_H

#include "som_util.h"

/* Encodes a (month, day) pair as the two-letter day code (criterion 4):
 *   - first letter — month: Jan → A, Feb → B, … Dec → L;
 *   - second letter — day: 1–26 → A–Z; 27–31 → '0','1','2','3','4'.
 * Returns a fresh owned 2-char string. */
char *spec_encode_two_letter_date(long long month, long long day);

/* Returns the static prefix of a `@SectionIdPattern`: the pattern with its
 * trailing run of `x` placeholder characters removed. `DACEN-ITEM-xxx` →
 * `DACEN-ITEM-`. Owned result. */
char *spec_section_id_pattern_prefix(const char *pattern);

/* Builds the generated section id for a new list item (criteria 3–4, 6).
 * `existing_ids` are the ids already assigned to the list's items; the
 * within-day number is max(existing ids that share this day's prefix) + 1.
 * Owned result. */
char *spec_generate_list_item_section_id(const char *pattern, long long month,
                                         long long day,
                                         const SomStrList *existing_ids);

/* Returns today's (month, day) in UTC civil terms (standard library only). */
void spec_today_month_day(long long *month, long long *day);

/* The reserved `refersTo` slot naming a registry entry's own section id rather
 * than one of its form fields (`tom_specs_model_rules.md` §6.2).
 *
 * A registry key is written `<SECTIONID>.<slot>`; this is the one slot that is
 * not a form field name. Named because the instance-tier reference check keys
 * its registries by it, and it must be the same literal the static tier in
 * `tom_specs_clitool` accepts. */
#define SPEC_SECTION_ID_SLOT "@sectionId"

/* The id a list item is *identified by* — its `stored_id` when it has one, and
 * otherwise the positional id derived from `pattern` (YRD3).
 *
 * An item acquires a stored id when it is created through the editor (an AA1
 * generated id) or when a document overrides one (criterion 5). Items authored
 * without one are **anonymous** and are identified by their 1-based `position` —
 * the pattern with its `xxx` placeholder replaced (`GOAL-ITEM-xxx` →
 * `GOAL-ITEM-1`), falling back to `<fallback_stem>-<position>` for a
 * pattern-less list. A NULL or empty `pattern` counts as absent.
 *
 * Named once because two consumers must agree on it exactly: the markdown
 * writer, which emits it as the heading id, and the instance-tier reference
 * check, which resolves `@sectionId` references against it. A divergence there
 * would not be cosmetic — it would red-flag a document whose references are
 * correct. Owned result. */
char *spec_effective_list_item_section_id(const char *stored_id,
                                          const char *pattern,
                                          long long position,
                                          const char *fallback_stem);

/* ---- section-id error --------------------------------------------------- */

/* The error kind returned by the section-id write paths. */
typedef enum {
  SPEC_SECTION_ID_OK = 0,
  /* The requested id is already used by another item of the same list
   * (criterion 5). `id` and `list_path` are populated. */
  SPEC_SECTION_ID_COLLISION = 1,
  /* The path is not (or no longer) a live list item. `item_path` is populated. */
  SPEC_SECTION_ID_NOT_LIVE_ITEM = 2,
} SpecSectionIdErrorKind;

/* A section-id error. Owns its populated string fields; the unused fields stay
 * NULL. Initialise with `spec_section_id_error_init` and release with
 * `spec_section_id_error_free`. */
typedef struct {
  SpecSectionIdErrorKind kind;
  char *id;        /* collision: the colliding id */
  char *list_path; /* collision: the owning list path */
  char *item_path; /* not-live-item: the offending item path */
} SpecSectionIdError;

/* Resets `*err` to OK with all fields NULL (does not free — call free first if
 * the struct already owns strings). */
void spec_section_id_error_init(SpecSectionIdError *err);

/* Frees the owned strings of `*err` and resets it to OK/NULL. Safe on an
 * OK/zeroed error. */
void spec_section_id_error_free(SpecSectionIdError *err);

/* Reports whether `err` is a uniqueness collision. */
int spec_section_id_is_collision(const SpecSectionIdError *err);

#endif /* SPEC_SECTION_ID_H */
