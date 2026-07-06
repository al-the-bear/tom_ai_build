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
