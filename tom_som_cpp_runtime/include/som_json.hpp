/* som_json — a hand-rolled, dependency-free JSON parser and value model, an
 * idiomatic-C++ port of the C `som_json` module.
 *
 * Object members keep source order in a vector of pairs (callers that need
 * stable ordering sort at use sites; the document stores use std::map). A parsed
 * value owns its whole subtree via std::shared_ptr — values are passed around by
 * `JsonRef` (= shared_ptr<const Json>) so accessors can return borrowed nodes
 * without lifetime juggling.
 */
#ifndef SOM_JSON_HPP
#define SOM_JSON_HPP

#include <memory>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace som {

enum class JsonType { Null, Bool, Int, Float, Str, Array, Object };

class Json;
using JsonPtr = std::shared_ptr<Json>;
using JsonRef = std::shared_ptr<const Json>;

class Json {
 public:
  JsonType type = JsonType::Null;
  bool boolean = false;
  long long integer = 0;
  double real = 0.0;
  std::string str;
  std::vector<JsonPtr> array;
  std::vector<std::pair<std::string, JsonPtr>> object;

  explicit Json(JsonType t) : type(t) {}
};

/* Parses a JSON document. On success returns the owned root; on failure returns
 * nullptr and, when `err` is non-null, writes an error message. */
JsonPtr jsonParse(const std::string& text, std::string* err);

/* Accessors — return nullptr / defaults rather than throwing, mirroring the C
 * Option-returning helpers. */
JsonRef jsonGet(const JsonRef& v, const std::string& key);
const std::string* jsonAsStr(const JsonRef& v);     // nullptr unless Str
std::optional<long long> jsonAsI64(const JsonRef& v);  // Int / integral Float
std::optional<bool> jsonAsBool(const JsonRef& v);   // set only when Bool
JsonRef jsonArrayAt(const JsonRef& v, std::size_t i);
std::size_t jsonArrayLen(const JsonRef& v);

/* Convenience: the string at `key` or "" / the bool at `key` or false. */
std::string jsonStrOr(const JsonRef& v, const std::string& key);
bool jsonBoolOr(const JsonRef& v, const std::string& key);

/* Encodes `s` as a JSON string literal (wrapped in double quotes). Matches
 * JavaScript's JSON.stringify for a string. */
std::string jsonEncodeStr(const std::string& s);

}  // namespace som

#endif  // SOM_JSON_HPP
