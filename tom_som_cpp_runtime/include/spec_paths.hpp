/* spec_paths — the section-path grammar shared by the in-memory document and the
 * meta-model traversal, an idiomatic-C++ port of the C `spec_paths` module.
 */
#ifndef SPEC_PATHS_HPP
#define SPEC_PATHS_HPP

#include <optional>
#include <string>
#include <vector>

namespace som {

constexpr const char* kSpecPathSeparator = "/";

/* Joins `parent` with `segment` using the path separator. */
std::string specPathJoin(const std::string& parent, const std::string& segment);

/* Splits `path` into its `/`-separated segments. A list-item sequence suffix
 * stays attached to its segment. */
std::vector<std::string> specPathSegments(const std::string& path);

/* The parent path of `path` — everything before the final `/`-separated
 * segment — or `path` itself when it has no separator (a root path).
 *
 * Used by the generated facades' YRD6 role-field accessors: a transparent
 * class-level `@Form` member is hoisted into its parent section's body, so its
 * title/id role fields bind to the **parent** path's headline / stored section
 * id. */
std::string specParentPath(const std::string& path);

/* Returns `<list_path>-<seq>`. */
std::string specListItemPath(const std::string& listPath, long long seq);

/* Splits a list-item segment `<base>-<digits>` into base and seq when the tail
 * is all digits (and the dash is neither first nor last char). Returns true and
 * writes `base`/`seq`; false otherwise. A hyphenated @SectionId such as
 * `CUOPME-OPER-LST` is never mis-read as a list item. */
bool specSplitListItemSegment(const std::string& segment, std::string* base,
                              long long* seq);

}  // namespace som

#endif  // SPEC_PATHS_HPP
