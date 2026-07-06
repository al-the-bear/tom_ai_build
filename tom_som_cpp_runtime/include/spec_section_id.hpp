/* spec_section_id — section-ID derivation for list/pattern sections (AA1
 * acceptance criteria 3–6), an idiomatic-C++ port of the C `spec_section_id`
 * module (which itself ports the Rust reference).
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
 *
 * The C version returned errors through an out-param struct; this port uses the
 * exception idiom the rest of the C++ runtime uses (cf. SomVersionError), so the
 * document write paths throw `SomSectionIdError` on a uniqueness collision or a
 * write to a non-live item.
 */
#ifndef SPEC_SECTION_ID_HPP
#define SPEC_SECTION_ID_HPP

#include <exception>
#include <string>
#include <utility>
#include <vector>

namespace som {

/* Encodes a (month, day) pair as the two-letter day code (criterion 4):
 *   - first letter — month: Jan → A, Feb → B, … Dec → L;
 *   - second letter — day: 1–26 → A–Z; 27–31 → '0','1','2','3','4'. */
std::string specEncodeTwoLetterDate(long long month, long long day);

/* Returns the static prefix of a `@SectionIdPattern`: the pattern with its
 * trailing run of `x` placeholder characters removed. `DACEN-ITEM-xxx` →
 * `DACEN-ITEM-`. */
std::string specSectionIdPatternPrefix(const std::string& pattern);

/* Builds the generated section id for a new list item (criteria 3–4, 6).
 * `existingIds` are the ids already assigned to the list's items; the within-day
 * number is max(existing ids that share this day's prefix) + 1. */
std::string specGenerateListItemSectionId(const std::string& pattern,
                                          long long month, long long day,
                                          const std::vector<std::string>& existingIds);

/* Returns today's (month, day) in UTC civil terms (standard library only). */
std::pair<long long, long long> specTodayMonthDay();

/* ---- section-id error --------------------------------------------------- */

/* Thrown by the section-id write paths (criterion 5). */
class SomSectionIdError : public std::exception {
 public:
  enum class Kind {
    Collision,     // the requested id is already used by another item
    NotLiveItem,   // the path is not (or no longer) a live list item
  };

  static SomSectionIdError collision(std::string id, std::string listPath) {
    SomSectionIdError e;
    e.kind_ = Kind::Collision;
    e.id_ = std::move(id);
    e.listPath_ = std::move(listPath);
    e.message_ = "section id \"" + e.id_ + "\" is already used by another item of \"" +
                 e.listPath_ + "\"";
    return e;
  }

  static SomSectionIdError notLiveItem(std::string itemPath) {
    SomSectionIdError e;
    e.kind_ = Kind::NotLiveItem;
    e.itemPath_ = std::move(itemPath);
    e.message_ = "\"" + e.itemPath_ + "\" is not a live list item";
    return e;
  }

  Kind kind() const { return kind_; }
  bool isCollision() const { return kind_ == Kind::Collision; }
  const std::string& id() const { return id_; }
  const std::string& listPath() const { return listPath_; }
  const std::string& itemPath() const { return itemPath_; }
  const char* what() const noexcept override { return message_.c_str(); }

 private:
  Kind kind_ = Kind::Collision;
  std::string id_;
  std::string listPath_;
  std::string itemPath_;
  std::string message_;
};

}  // namespace som

#endif  // SPEC_SECTION_ID_HPP
