package somruntime

// spec_section_id.go — section-ID derivation for list/pattern sections (AA1
// acceptance criteria 3–6), a faithful port of
// `tom_som_dart_runtime/lib/src/spec_section_id.dart` (and `spec_section_id.js`
// / `spec_section_id.ts` / `spec_section_id.py` / `SpecSectionId.java`).
//
// A single-valued section carries a *fixed* id — its @SectionId, which is
// already the path segment, so nothing is derived. A **list item**, by
// contrast, gets a generated id built from the list field's @SectionIdPattern
// (e.g. `DACEN-ITEM-xxx`):
//
//	<prefix><two-letter-date><number-within-the-day>
//
// where <prefix> is the pattern with its trailing placeholder (`xxx`) stripped
// (`DACEN-ITEM-`), <two-letter-date> encodes the creation date (see
// EncodeTwoLetterDate), and <number-within-the-day> is the 1-based ordinal of
// the item among the list's items created the same day.
//
// The within-day number is derived from the list's *current* ids as
// `max(existing for that day) + 1`. This gives both required behaviours with one
// rule (criterion 6): deleting a middle item never renumbers the rest (the max
// is unchanged, so a new same-day item takes the next free number and the
// numbering may stay non-consecutive), while deleting the last item lowers the
// max so a new same-day item *reuses* the just-freed id.

import "strings"

// EncodeTwoLetterDate encodes a (month, day) pair as the two-letter day code
// used in generated section ids (criterion 4).
//
//   - First letter — month: Jan → A, Feb → B, … Dec → L.
//   - Second letter — day-of-month: days 1–26 → A–Z; days 27–31 → 0,1,2,3,4.
func EncodeTwoLetterDate(month, day int) string {
	monthLetter := rune(0x41 + (month - 1))
	var dayCode rune
	if day <= 26 {
		dayCode = rune(0x41 + (day - 1))
	} else {
		// 27 → '0', 28 → '1', … 31 → '4'.
		dayCode = rune(0x30 + (day - 27))
	}
	return string(monthLetter) + string(dayCode)
}

// SectionIDPatternPrefix returns the static prefix of a @SectionIdPattern: the
// pattern with its trailing placeholder (the run of trailing 'x' characters)
// removed. `DACEN-ITEM-xxx` → `DACEN-ITEM-`.
func SectionIDPatternPrefix(pattern string) string {
	i := len(pattern)
	for i > 0 && pattern[i-1] == 'x' {
		i--
	}
	return pattern[:i]
}

// KSectionIDSlot is the reserved `refersTo` slot naming a registry entry's own
// section id rather than one of its form fields (`tom_specs_model_rules.md`
// §6.2).
//
// A registry key is written `<SECTIONID>.<slot>`; this is the one slot that is
// not a form field name. Named because the instance-tier reference check keys
// its registries by it, and it must be the same literal the static tier in
// `tom_specs_clitool` accepts.
const KSectionIDSlot = "@sectionId"

// EffectiveListItemSectionID returns the id a list item is *identified by* — its
// storedID when it has one (hasStored), and otherwise the positional id derived
// from the list's pattern (YRD3).
//
// An item acquires a stored id when it is created through the editor (an AA1
// generated id) or when a document overrides one (criterion 5). Items authored
// without one are anonymous and are identified by their 1-based position — the
// pattern with its `xxx` placeholder replaced (`GOAL-ITEM-xxx` →
// `GOAL-ITEM-1`), falling back to `<fallbackStem>-<position>` for a pattern-less
// list.
//
// Named once because two consumers must agree on it exactly: the markdown
// writer, which emits it as the heading id, and the instance-tier reference
// check, which resolves `@sectionId` references against it. A divergence there
// would not be a cosmetic difference — it would red-flag a document whose
// references are correct.
func EffectiveListItemSectionID(
	storedID string, hasStored bool, pattern string, position int, fallbackStem string,
) string {
	if hasStored {
		return storedID
	}
	if pattern != "" {
		return strings.Join(strings.Split(pattern, "xxx"), itoa(position))
	}
	return fallbackStem + "-" + itoa(position)
}

// SpecSectionIDCollision is returned when a section id would collide with
// another id in the same list (criterion 5: overriding an id must keep every id
// in the list unique).
type SpecSectionIDCollision struct {
	ID       string
	ListPath string
}

// Error implements the error interface.
func (e *SpecSectionIDCollision) Error() string {
	return "SpecSectionIdCollision: section id \"" + e.ID + "\" is already used in list \"" +
		e.ListPath + "\"; section ids within a list must be unique."
}

// GenerateListItemSectionID builds the generated section id for a new list item
// (criteria 3–4, 6).
//
// pattern is the list field's @SectionIdPattern; month/day are the creation
// date; existingIDs are the ids already assigned to the list's items. The
// within-day number is `max(existing ids that share this day's prefix) + 1`.
func GenerateListItemSectionID(pattern string, month, day int, existingIDs []string) string {
	dayPrefix := SectionIDPatternPrefix(pattern) + EncodeTwoLetterDate(month, day)
	maxForDay := 0
	for _, id := range existingIDs {
		if id == "" || !strings.HasPrefix(id, dayPrefix) {
			continue
		}
		tail := id[len(dayPrefix):]
		if tail == "" || !isAllDigits(tail) {
			continue
		}
		n := atoi(tail)
		if n > maxForDay {
			maxForDay = n
		}
	}
	return dayPrefix + itoa(maxForDay+1)
}
