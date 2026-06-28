/* som_util — small string/number helpers shared by the C++ generic runtime.
 *
 * Idiomatic-C++ port of the C `som_util` module. The C version shipped its own
 * growable string builder (SomBuf), owning string list (SomStrList) and
 * byte-sorted string map (SomMap) because the C standard library has none; this
 * port drops all three in favour of std::string / std::vector<std::string> /
 * std::map<std::string, std::string> (which iterates in byte order for
 * std::string keys, matching the C SomMap's strcmp ordering — the byte-stable
 * codecs depend on this).
 *
 * Only the genuinely-shared numeric/string helpers remain here.
 */
#ifndef SOM_UTIL_HPP
#define SOM_UTIL_HPP

#include <cstdint>
#include <optional>
#include <string>

namespace som {

/* Parses a base-10 i64 (optional leading +/-). Returns the value on success;
 * std::nullopt for empty/non-digit input (mirrors the C som_parse_i64). */
std::optional<long long> parseI64(const std::string& s);

/* Reports whether `s` is non-empty and composed solely of ASCII digits. */
bool isAllDigits(const std::string& s);

/* Formats an i64 as a decimal string. */
std::string formatI64(long long v);

}  // namespace som

#endif  // SOM_UTIL_HPP
