/* yaml — a minimal, dependency-free YAML reader for the constrained
 * `*.docspecs.yaml` subset the codec emits, an idiomatic-C++ port of the C
 * `yaml` module.
 *
 * It supports exactly what the encoder produces (and what the self-verify
 * round-trip probe needs): block mappings, block sequences (`- item`), literal
 * block scalars (`|`, `|-`, `|2`, `|2-` …), JSON-quoted flow scalars, plain
 * integers, and the empty flow collections `{}` / `[]`.
 *
 * The dynamic value model is `YamlValue`: mappings are byte-sorted maps,
 * sequences are arrays, scalars are strings or integers. JSON-quoted scalars are
 * parsed via the hand-rolled `som_json` parser.
 *
 * Ownership: a parsed value owns its whole subtree via std::shared_ptr; values
 * are passed by `YamlRef` (= shared_ptr<const YamlValue>) so accessors can
 * return borrowed nodes without lifetime juggling.
 */
#ifndef YAML_HPP
#define YAML_HPP

#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace som {

enum class YamlType { Map, Seq, Str, Int };

class YamlValue;
using YamlPtr = std::shared_ptr<YamlValue>;
using YamlRef = std::shared_ptr<const YamlValue>;

class YamlValue {
 public:
  YamlType type;
  // Map entries kept byte-sorted by key (std::map iterates in strcmp order for
  // std::string keys, matching the C YamlValue's byte-sorted entries).
  std::map<std::string, YamlPtr> map;
  std::vector<YamlPtr> seq;
  std::string str;
  long long integer = 0;

  explicit YamlValue(YamlType t) : type(t) {}
};

/* Parses `text` into the value model (a map or sequence). Owned result. */
YamlPtr yamlParse(const std::string& text);

/* Parses `text`, returning a map (an empty map when not a mapping). */
YamlPtr yamlParseMap(const std::string& text);

/* Returns the value at `key` when `v` is a map, else null. */
YamlRef yamlGet(const YamlRef& v, const std::string& key);

/* Returns the string when `v` is a string scalar, else nullptr. */
const std::string* yamlAsStr(const YamlRef& v);

/* Returns the integer when `v` is an integer scalar. */
std::optional<long long> yamlAsInt(const YamlRef& v);

/* Returns the scalar rendered as a string (string verbatim, integer formatted),
 * or "" for non-scalars. */
std::string yamlScalarString(const YamlRef& v);

}  // namespace som

#endif  // YAML_HPP
