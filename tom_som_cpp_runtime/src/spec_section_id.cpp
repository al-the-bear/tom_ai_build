/* Idiomatic-C++ port of the C `spec_section_id` module. */
#include "spec_section_id.hpp"

#include <ctime>

#include "som_util.hpp"

namespace som {

std::string specEncodeTwoLetterDate(long long month, long long day) {
  std::string out(2, '\0');
  out[0] = static_cast<char>(0x41 + (month - 1));
  if (day <= 26) {
    out[1] = static_cast<char>(0x41 + (day - 1));
  } else {
    /* 27 → '0', 28 → '1', … 31 → '4'. */
    out[1] = static_cast<char>(0x30 + (day - 27));
  }
  return out;
}

std::string specSectionIdPatternPrefix(const std::string& pattern) {
  std::size_t i = pattern.size();
  while (i > 0 && pattern[i - 1] == 'x') {
    i--;
  }
  return pattern.substr(0, i);
}

std::string specGenerateListItemSectionId(
    const std::string& pattern, long long month, long long day,
    const std::vector<std::string>& existingIds) {
  std::string dayPrefix = specSectionIdPatternPrefix(pattern) +
                          specEncodeTwoLetterDate(month, day);
  std::size_t dpl = dayPrefix.size();

  long long maxForDay = 0;
  for (const std::string& id : existingIds) {
    if (id.empty() || id.size() < dpl || id.compare(0, dpl, dayPrefix) != 0) {
      continue;
    }
    std::string tail = id.substr(dpl);
    if (tail.empty() || !isAllDigits(tail)) {
      continue;
    }
    auto n = parseI64(tail);
    if (n.has_value() && *n > maxForDay) {
      maxForDay = *n;
    }
  }

  return dayPrefix + formatI64(maxForDay + 1);
}

std::pair<long long, long long> specTodayMonthDay() {
  std::time_t now = std::time(nullptr);
  if (now == static_cast<std::time_t>(-1)) {
    return {1, 1};
  }
  long long days = static_cast<long long>(now);
  /* floor division by 86400 (now is >= 0, so integer division suffices). */
  days = days / 86400;

  /* Howard Hinnant's civil_from_days (days since 1970-01-01). */
  long long z = days + 719468;
  long long era = (z >= 0 ? z : z - 146096) / 146097;
  long long doe = z - era * 146097;                                      // [0, 146096]
  long long yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;  // [0,399]
  long long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);                // [0, 365]
  long long mp = (5 * doy + 2) / 153;                                     // [0, 11]
  long long d = doy - (153 * mp + 2) / 5 + 1;                             // [1, 31]
  long long m = mp < 10 ? mp + 3 : mp - 9;                                // [1, 12]
  return {m, d};
}

}  // namespace som
