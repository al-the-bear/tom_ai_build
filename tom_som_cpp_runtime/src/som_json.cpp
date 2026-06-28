#include "som_json.hpp"

#include <cstdlib>

#include "som_util.hpp"

namespace som {

/* ---- accessors ---------------------------------------------------------- */

JsonRef jsonGet(const JsonRef& v, const std::string& key) {
  if (v == nullptr || v->type != JsonType::Object) {
    return nullptr;
  }
  for (const auto& m : v->object) {
    if (m.first == key) {
      return m.second;
    }
  }
  return nullptr;
}

const std::string* jsonAsStr(const JsonRef& v) {
  if (v != nullptr && v->type == JsonType::Str) {
    return &v->str;
  }
  return nullptr;
}

std::optional<long long> jsonAsI64(const JsonRef& v) {
  if (v == nullptr) {
    return std::nullopt;
  }
  if (v->type == JsonType::Int) {
    return v->integer;
  }
  if (v->type == JsonType::Float) {
    double f = v->real;
    if (f == static_cast<double>(static_cast<long long>(f))) {
      return static_cast<long long>(f);
    }
  }
  return std::nullopt;
}

std::optional<bool> jsonAsBool(const JsonRef& v) {
  if (v != nullptr && v->type == JsonType::Bool) {
    return v->boolean;
  }
  return std::nullopt;
}

JsonRef jsonArrayAt(const JsonRef& v, std::size_t i) {
  if (v != nullptr && v->type == JsonType::Array && i < v->array.size()) {
    return v->array[i];
  }
  return nullptr;
}

std::size_t jsonArrayLen(const JsonRef& v) {
  if (v != nullptr && v->type == JsonType::Array) {
    return v->array.size();
  }
  return 0;
}

std::string jsonStrOr(const JsonRef& v, const std::string& key) {
  const std::string* s = jsonAsStr(jsonGet(v, key));
  return s != nullptr ? *s : std::string();
}

bool jsonBoolOr(const JsonRef& v, const std::string& key) {
  auto b = jsonAsBool(jsonGet(v, key));
  return b.value_or(false);
}

/* ---- encode_str --------------------------------------------------------- */

std::string jsonEncodeStr(const std::string& s) {
  static const char HEX[] = "0123456789abcdef";
  std::string b;
  b.push_back('"');
  for (unsigned char c : s) {
    switch (c) {
      case '"':
        b += "\\\"";
        break;
      case '\\':
        b += "\\\\";
        break;
      case '\b':
        b += "\\b";
        break;
      case '\f':
        b += "\\f";
        break;
      case '\n':
        b += "\\n";
        break;
      case '\r':
        b += "\\r";
        break;
      case '\t':
        b += "\\t";
        break;
      default:
        if (c < 0x20) {
          b += "\\u00";
          b.push_back(HEX[(c >> 4) & 0xf]);
          b.push_back(HEX[c & 0xf]);
        } else {
          b.push_back(static_cast<char>(c));
        }
        break;
    }
  }
  b.push_back('"');
  return b;
}

/* ---- parser ------------------------------------------------------------- */

namespace {

struct Parser {
  const std::string& s;
  std::size_t idx = 0;
  std::string err;
  bool failed = false;

  explicit Parser(const std::string& text) : s(text) {}

  void fail(const char* msg) {
    if (!failed) {
      err = msg;
      failed = true;
    }
  }

  int peek() const {
    if (idx < s.size()) {
      return static_cast<unsigned char>(s[idx]);
    }
    return -1;
  }

  void skipWs() {
    while (idx < s.size()) {
      char c = s[idx];
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        idx++;
      } else {
        break;
      }
    }
  }

  bool matches(const char* lit) {
    std::size_t n = std::char_traits<char>::length(lit);
    if (idx + n > s.size()) {
      return false;
    }
    if (s.compare(idx, n, lit) != 0) {
      return false;
    }
    idx += n;
    return true;
  }
};

void utf8Append(std::string& b, unsigned int cp) {
  if (cp <= 0x7f) {
    b.push_back(static_cast<char>(cp));
  } else if (cp <= 0x7ff) {
    b.push_back(static_cast<char>(0xc0 | (cp >> 6)));
    b.push_back(static_cast<char>(0x80 | (cp & 0x3f)));
  } else if (cp <= 0xffff) {
    b.push_back(static_cast<char>(0xe0 | (cp >> 12)));
    b.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3f)));
    b.push_back(static_cast<char>(0x80 | (cp & 0x3f)));
  } else {
    b.push_back(static_cast<char>(0xf0 | (cp >> 18)));
    b.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3f)));
    b.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3f)));
    b.push_back(static_cast<char>(0x80 | (cp & 0x3f)));
  }
}

bool hex4(Parser& p, unsigned int* out) {
  unsigned int v = 0;
  for (int k = 0; k < 4; k++) {
    if (p.idx >= p.s.size()) {
      p.fail("unterminated \\u escape");
      return false;
    }
    char c = p.s[p.idx++];
    unsigned int d;
    if (c >= '0' && c <= '9') {
      d = static_cast<unsigned int>(c - '0');
    } else if (c >= 'a' && c <= 'f') {
      d = static_cast<unsigned int>(c - 'a' + 10);
    } else if (c >= 'A' && c <= 'F') {
      d = static_cast<unsigned int>(c - 'A' + 10);
    } else {
      p.fail("bad hex digit");
      return false;
    }
    v = v * 16 + d;
  }
  *out = v;
  return true;
}

bool parseString(Parser& p, std::string* out) {
  p.idx++;  // opening '"'
  std::string b;
  for (;;) {
    if (p.idx >= p.s.size()) {
      p.fail("unterminated string");
      return false;
    }
    char c = p.s[p.idx++];
    if (c == '"') {
      break;
    }
    if (c == '\\') {
      if (p.idx >= p.s.size()) {
        p.fail("unterminated escape");
        return false;
      }
      char esc = p.s[p.idx++];
      switch (esc) {
        case '"':
          b.push_back('"');
          break;
        case '\\':
          b.push_back('\\');
          break;
        case '/':
          b.push_back('/');
          break;
        case 'b':
          b.push_back('\b');
          break;
        case 'f':
          b.push_back('\f');
          break;
        case 'n':
          b.push_back('\n');
          break;
        case 'r':
          b.push_back('\r');
          break;
        case 't':
          b.push_back('\t');
          break;
        case 'u': {
          unsigned int cp;
          if (!hex4(p, &cp)) {
            return false;
          }
          if (cp >= 0xD800 && cp <= 0xDBFF) {
            if (p.peek() == '\\' && p.idx + 1 < p.s.size() &&
                p.s[p.idx + 1] == 'u') {
              p.idx += 2;
              unsigned int low;
              if (!hex4(p, &low)) {
                return false;
              }
              if (low >= 0xDC00 && low <= 0xDFFF) {
                unsigned int combined =
                    0x10000 + ((cp - 0xD800) << 10) + (low - 0xDC00);
                utf8Append(b, combined);
              } else {
                utf8Append(b, 0xFFFD);
                utf8Append(b, low);
              }
            } else {
              utf8Append(b, 0xFFFD);
            }
          } else {
            utf8Append(b, cp);
          }
          break;
        }
        default:
          p.fail("invalid escape");
          return false;
      }
    } else {
      b.push_back(c);
    }
  }
  *out = std::move(b);
  return true;
}

JsonPtr parseValue(Parser& p);

JsonPtr parseObject(Parser& p) {
  p.idx++;  // '{'
  auto v = std::make_shared<Json>(JsonType::Object);
  p.skipWs();
  if (p.peek() == '}') {
    p.idx++;
    return v;
  }
  for (;;) {
    p.skipWs();
    if (p.peek() != '"') {
      p.fail("expected object key");
      return nullptr;
    }
    std::string key;
    if (!parseString(p, &key)) {
      return nullptr;
    }
    p.skipWs();
    if (p.peek() != ':') {
      p.fail("expected ':'");
      return nullptr;
    }
    p.idx++;
    JsonPtr val = parseValue(p);
    if (val == nullptr) {
      return nullptr;
    }
    v->object.emplace_back(std::move(key), std::move(val));
    p.skipWs();
    int c = p.peek();
    if (c == ',') {
      p.idx++;
    } else if (c == '}') {
      p.idx++;
      break;
    } else {
      p.fail("expected ',' or '}'");
      return nullptr;
    }
  }
  return v;
}

JsonPtr parseArray(Parser& p) {
  p.idx++;  // '['
  auto v = std::make_shared<Json>(JsonType::Array);
  p.skipWs();
  if (p.peek() == ']') {
    p.idx++;
    return v;
  }
  for (;;) {
    JsonPtr item = parseValue(p);
    if (item == nullptr) {
      return nullptr;
    }
    v->array.push_back(std::move(item));
    p.skipWs();
    int c = p.peek();
    if (c == ',') {
      p.idx++;
    } else if (c == ']') {
      p.idx++;
      break;
    } else {
      p.fail("expected ',' or ']'");
      return nullptr;
    }
  }
  return v;
}

JsonPtr parseNumber(Parser& p) {
  std::size_t start = p.idx;
  bool isFloat = false;
  if (p.peek() == '-') {
    p.idx++;
  }
  while (p.idx < p.s.size()) {
    char c = p.s[p.idx];
    if (c >= '0' && c <= '9') {
      p.idx++;
    } else if (c == '.' || c == 'e' || c == 'E' || c == '+' || c == '-') {
      isFloat = true;
      p.idx++;
    } else {
      break;
    }
  }
  std::string num = p.s.substr(start, p.idx - start);
  if (isFloat) {
    auto v = std::make_shared<Json>(JsonType::Float);
    v->real = std::strtod(num.c_str(), nullptr);
    return v;
  }
  auto iv = parseI64(num);
  if (iv.has_value()) {
    auto v = std::make_shared<Json>(JsonType::Int);
    v->integer = *iv;
    return v;
  }
  auto v = std::make_shared<Json>(JsonType::Float);
  v->real = std::strtod(num.c_str(), nullptr);
  return v;
}

JsonPtr parseValue(Parser& p) {
  p.skipWs();
  int c = p.peek();
  switch (c) {
    case '{':
      return parseObject(p);
    case '[':
      return parseArray(p);
    case '"': {
      std::string s;
      if (!parseString(p, &s)) {
        return nullptr;
      }
      auto v = std::make_shared<Json>(JsonType::Str);
      v->str = std::move(s);
      return v;
    }
    case 't':
    case 'f': {
      if (p.matches("true")) {
        auto v = std::make_shared<Json>(JsonType::Bool);
        v->boolean = true;
        return v;
      }
      if (p.matches("false")) {
        auto v = std::make_shared<Json>(JsonType::Bool);
        v->boolean = false;
        return v;
      }
      p.fail("invalid literal");
      return nullptr;
    }
    case 'n':
      if (p.matches("null")) {
        return std::make_shared<Json>(JsonType::Null);
      }
      p.fail("invalid literal");
      return nullptr;
    default:
      if (c == '-' || (c >= '0' && c <= '9')) {
        return parseNumber(p);
      }
      p.fail("unexpected token");
      return nullptr;
  }
}

}  // namespace

JsonPtr jsonParse(const std::string& text, std::string* err) {
  Parser p(text);
  p.skipWs();
  JsonPtr v = parseValue(p);
  if (v == nullptr) {
    if (err != nullptr) {
      *err = p.failed ? p.err : "parse error";
    }
    return nullptr;
  }
  p.skipWs();
  if (p.idx != p.s.size()) {
    if (err != nullptr) {
      *err = "trailing data";
    }
    return nullptr;
  }
  if (err != nullptr) {
    err->clear();
  }
  return v;
}

}  // namespace som
