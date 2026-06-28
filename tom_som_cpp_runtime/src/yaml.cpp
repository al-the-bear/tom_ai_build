/* Idiomatic-C++ port of the C `yaml` module. */
#include "yaml.hpp"

#include "som_json.hpp"
#include "som_util.hpp"

namespace som {

/* ---- value constructors ------------------------------------------------- */

static YamlPtr yamlNewMap() { return std::make_shared<YamlValue>(YamlType::Map); }
static YamlPtr yamlNewSeq() { return std::make_shared<YamlValue>(YamlType::Seq); }

static YamlPtr yamlNewStr(std::string s) {
  auto v = std::make_shared<YamlValue>(YamlType::Str);
  v->str = std::move(s);
  return v;
}

static YamlPtr yamlNewInt(long long n) {
  auto v = std::make_shared<YamlValue>(YamlType::Int);
  v->integer = n;
  return v;
}

/* ---- accessors ---------------------------------------------------------- */

YamlRef yamlGet(const YamlRef& v, const std::string& key) {
  if (v == nullptr || v->type != YamlType::Map) {
    return nullptr;
  }
  auto it = v->map.find(key);
  return it != v->map.end() ? std::const_pointer_cast<const YamlValue>(it->second)
                            : nullptr;
}

const std::string* yamlAsStr(const YamlRef& v) {
  return (v != nullptr && v->type == YamlType::Str) ? &v->str : nullptr;
}

std::optional<long long> yamlAsInt(const YamlRef& v) {
  if (v != nullptr && v->type == YamlType::Int) {
    return v->integer;
  }
  return std::nullopt;
}

std::string yamlScalarString(const YamlRef& v) {
  if (v == nullptr) {
    return "";
  }
  if (v->type == YamlType::Str) {
    return v->str;
  }
  if (v->type == YamlType::Int) {
    return formatI64(v->integer);
  }
  return "";
}

/* ---- small string helpers ----------------------------------------------- */

static bool isWs(char c) {
  return c == ' ' || c == '\t' || c == '\r' || c == '\n';
}

static std::string trimStr(const std::string& s) {
  std::size_t start = 0, end = s.size();
  while (start < end && isWs(s[start])) {
    start++;
  }
  while (end > start && isWs(s[end - 1])) {
    end--;
  }
  return s.substr(start, end - start);
}

static std::size_t yamlLeading(const std::string& line) {
  std::size_t i = 0;
  while (i < line.size() && line[i] == ' ') {
    i++;
  }
  return i;
}

static bool yamlIsInteger(const std::string& s) {
  if (s.empty()) {
    return false;
  }
  std::size_t i = 0;
  if (s[0] == '-' || s[0] == '+') {
    if (s.size() == 1) {
      return false;
    }
    i = 1;
  }
  for (; i < s.size(); i++) {
    if (s[i] < '0' || s[i] > '9') {
      return false;
    }
  }
  return true;
}

/* Index of the structural ':' in `content`, or -1. */
static long findColon(const std::string& content) {
  if (!content.empty() && content[0] == '"') {
    std::size_t i = 1;
    while (i < content.size()) {
      char c = content[i];
      if (c == '\\') {
        i += 2;
        continue;
      }
      if (c == '"') {
        i += 1;
        break;
      }
      i += 1;
    }
    for (; i < content.size(); i++) {
      if (content[i] == ':') {
        return static_cast<long>(i);
      }
    }
    return -1;
  }
  for (std::size_t i = 0; i < content.size(); i++) {
    if (content[i] == ':') {
      return static_cast<long>(i);
    }
  }
  return -1;
}

/* Parses a JSON-quoted scalar string, or returns it verbatim.
 * `forKey`: when true a non-string parse yields "". */
static std::string parseQuoted(const std::string& t, bool forKey) {
  if (!t.empty() && t[0] == '"') {
    std::string err;
    JsonPtr j = jsonParse(t, &err);
    if (j != nullptr && j->type == JsonType::Str) {
      return j->str;
    }
    return forKey ? std::string() : t;
  }
  return t;
}

static bool lineIsBlankOrComment(const std::string& line) {
  std::string t = trimStr(line);
  return t.empty() || t[0] == '#';
}

/* ---- reader ------------------------------------------------------------- */

namespace {

class YamlReader {
 public:
  std::vector<std::string> lines;
  std::size_t idx = 0;

  long nextSignificant(std::size_t from) const {
    for (std::size_t i = from; i < lines.size(); i++) {
      if (!lineIsBlankOrComment(lines[i])) {
        return static_cast<long>(i);
      }
    }
    return -1;
  }
};

YamlPtr parseNode(YamlReader& r, std::size_t minIndent);
YamlPtr parseMapping(YamlReader& r, std::size_t indent);
YamlPtr parseSequence(YamlReader& r, std::size_t indent);
YamlPtr parseNestedAfterKey(YamlReader& r, std::size_t parentIndent);
YamlPtr parseFlowScalar(const std::string& s);
std::string parseBlockScalar(YamlReader& r, const std::string& header,
                             std::size_t keyIndent);

YamlPtr parseNode(YamlReader& r, std::size_t minIndent) {
  long i = r.nextSignificant(r.idx);
  if (i < 0) {
    return yamlNewMap();
  }
  const std::string& line = r.lines[static_cast<std::size_t>(i)];
  std::size_t indent = yamlLeading(line);
  if (indent < minIndent) {
    return yamlNewMap();
  }
  std::string content = line.substr(indent);
  if (content == "-" || content.compare(0, 2, "- ") == 0) {
    return parseSequence(r, indent);
  }
  return parseMapping(r, indent);
}

YamlPtr parseMapping(YamlReader& r, std::size_t indent) {
  YamlPtr m = yamlNewMap();
  for (;;) {
    long i = r.nextSignificant(r.idx);
    if (i < 0) {
      break;
    }
    const std::string& line = r.lines[static_cast<std::size_t>(i)];
    std::size_t curIndent = yamlLeading(line);
    if (curIndent != indent) {
      break;  // dedent -> belongs to the parent.
    }
    r.idx = static_cast<std::size_t>(i) + 1;
    std::string content = line.substr(indent);
    long colon = findColon(content);
    if (colon < 0) {
      continue;  // not a mapping entry — tolerate and skip.
    }
    std::string keyPart = trimStr(content.substr(0, static_cast<std::size_t>(colon)));
    std::string key = parseQuoted(keyPart, true);
    std::string rest = trimStr(content.substr(static_cast<std::size_t>(colon) + 1));
    YamlPtr value;
    if (rest.empty()) {
      value = parseNestedAfterKey(r, indent);
    } else if (rest[0] == '|' || rest[0] == '>') {
      value = yamlNewStr(parseBlockScalar(r, rest, indent));
    } else {
      value = parseFlowScalar(rest);
    }
    m->map[key] = value;
  }
  return m;
}

YamlPtr parseSequence(YamlReader& r, std::size_t indent) {
  YamlPtr list = yamlNewSeq();
  for (;;) {
    long i = r.nextSignificant(r.idx);
    if (i < 0) {
      break;
    }
    const std::string& line = r.lines[static_cast<std::size_t>(i)];
    std::size_t curIndent = yamlLeading(line);
    if (curIndent != indent) {
      break;
    }
    std::string content = line.substr(indent);
    if (content != "-" && content.compare(0, 2, "- ") != 0) {
      break;
    }
    r.idx = static_cast<std::size_t>(i) + 1;
    std::string itemText;
    if (content == "-") {
      itemText = "";
    } else {
      itemText = trimStr(content.substr(2));
    }
    if (itemText.empty()) {
      list->seq.push_back(parseNestedAfterKey(r, indent));
    } else if (itemText[0] == '|' || itemText[0] == '>') {
      list->seq.push_back(yamlNewStr(parseBlockScalar(r, itemText, indent)));
    } else {
      list->seq.push_back(parseFlowScalar(itemText));
    }
  }
  return list;
}

YamlPtr parseNestedAfterKey(YamlReader& r, std::size_t parentIndent) {
  long i = r.nextSignificant(r.idx);
  if (i < 0) {
    return yamlNewMap();
  }
  std::size_t childIndent = yamlLeading(r.lines[static_cast<std::size_t>(i)]);
  if (childIndent <= parentIndent) {
    return yamlNewMap();
  }
  return parseNode(r, childIndent);
}

YamlPtr parseFlowScalar(const std::string& s) {
  std::string t = trimStr(s);
  if (t == "{}") {
    return yamlNewMap();
  }
  if (t == "[]") {
    return yamlNewSeq();
  }
  if (!t.empty() && t[0] == '"') {
    return yamlNewStr(parseQuoted(t, false));
  }
  if (yamlIsInteger(t)) {
    auto n = parseI64(t);
    if (n.has_value()) {
      return yamlNewInt(*n);
    }
    return yamlNewStr(t);
  }
  return yamlNewStr(t);
}

std::string parseBlockScalar(YamlReader& r, const std::string& header,
                             std::size_t keyIndent) {
  std::size_t hlen = header.size();
  std::size_t p = 1;  // skip the leading '|' (or '>').
  std::size_t digitsStart = p;
  while (p < hlen && header[p] >= '0' && header[p] <= '9') {
    p++;
  }
  bool hasExplicit = (p > digitsStart);
  long long explicitIndent = 0;
  if (hasExplicit) {
    auto d = parseI64(header.substr(digitsStart, p - digitsStart));
    explicitIndent = d.value_or(0);
  }
  char chomp = ' ';
  while (p < hlen) {
    char c = header[p];
    if (c == '-' || c == '+') {
      chomp = c;
    }
    p++;
  }

  // Collect the raw body: blank lines plus any line indented past the key.
  std::vector<std::string> raw;
  while (r.idx < r.lines.size()) {
    const std::string& l = r.lines[r.idx];
    bool blank = trimStr(l).empty();
    if (blank) {
      raw.push_back("");
      r.idx++;
      continue;
    }
    if (yamlLeading(l) <= keyIndent) {
      break;
    }
    raw.push_back(l);
    r.idx++;
  }
  // Drop trailing blank lines that belong to the following node.
  while (!raw.empty() && raw.back().empty()) {
    raw.pop_back();
  }

  std::size_t contentIndent;
  if (hasExplicit) {
    contentIndent = keyIndent + static_cast<std::size_t>(explicitIndent);
  } else {
    std::size_t mn = static_cast<std::size_t>(-1);
    for (const std::string& l : raw) {
      if (!l.empty()) {
        std::size_t ld = yamlLeading(l);
        if (ld < mn) {
          mn = ld;
        }
      }
    }
    contentIndent = (mn == static_cast<std::size_t>(-1)) ? keyIndent + 1 : mn;
  }

  std::string joined;
  for (std::size_t i = 0; i < raw.size(); i++) {
    if (i > 0) {
      joined.push_back('\n');
    }
    const std::string& l = raw[i];
    if (!l.empty()) {
      std::size_t strip = contentIndent < l.size() ? contentIndent : l.size();
      joined += l.substr(strip);
    }
  }

  // chomping
  if (chomp == '+') {
    return joined;  // keep
  }
  std::size_t end = joined.size();
  while (end > 0 && joined[end - 1] == '\n') {
    end--;
  }
  if (chomp == '-') {
    return joined.substr(0, end);
  }
  // clip (default): exactly one trailing newline when non-empty.
  if (end == 0) {
    return "";
  }
  return joined.substr(0, end) + "\n";
}

void splitLines(const std::string& text, std::vector<std::string>& out) {
  std::size_t start = 0;
  for (std::size_t p = 0;; p++) {
    if (p == text.size() || text[p] == '\n') {
      out.push_back(text.substr(start, p - start));
      if (p == text.size()) {
        break;
      }
      start = p + 1;
    }
  }
}

}  // namespace

/* ---- entry points ------------------------------------------------------- */

YamlPtr yamlParse(const std::string& text) {
  YamlReader r;
  splitLines(text, r.lines);
  r.idx = 0;
  if (r.nextSignificant(0) < 0) {
    return yamlNewMap();
  }
  return parseNode(r, 0);
}

YamlPtr yamlParseMap(const std::string& text) {
  YamlPtr v = yamlParse(text);
  if (v->type == YamlType::Map) {
    return v;
  }
  return yamlNewMap();
}

}  // namespace som
