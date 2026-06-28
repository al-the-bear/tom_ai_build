/* Idiomatic-C++ port of the C `spec_document_yaml` module. */
#include "spec_document_yaml.hpp"

#include "som_json.hpp"
#include "som_util.hpp"
#include "yaml.hpp"

namespace som {

/* js_json_string / yaml_key — JSON.stringify-compatible quoting. */
static std::string jsJsonString(const std::string& s) { return jsonEncodeStr(s); }

static std::size_t trailingNewlines(const std::string& value) {
  std::size_t n = value.size();
  std::size_t count = 0;
  while (count < n && value[n - 1 - count] == '\n') {
    count++;
  }
  return count;
}

/* Builds a `|2<chomp>` literal block, or std::nullopt when chomping can't
 * reproduce the value's trailing newlines (two or more). */
static std::optional<std::string> literalBlock(const std::string& value) {
  std::size_t trailing = trailingNewlines(value);
  std::string chomp;
  std::size_t coreLen;
  std::size_t vlen = value.size();
  if (trailing == 0) {
    chomp = "-";
    coreLen = vlen;
  } else if (trailing == 1) {
    chomp = "";
    coreLen = vlen - 1;
  } else {
    return std::nullopt;
  }
  std::string b = "|2";
  b += chomp;
  // core.split('\n')
  std::size_t start = 0;
  for (std::size_t i = 0;; i++) {
    if (i == coreLen || value[i] == '\n') {
      b.push_back('\n');
      if (i > start) {
        b += "  ";
        b += value.substr(start, i - start);
      }
      if (i == coreLen) {
        break;
      }
      start = i + 1;
    }
  }
  return b;
}

/* Reports whether re-parsing `_v: <block>` yields exactly `value`. */
static bool roundTrips(const std::string& block, const std::string& value) {
  std::string probe = "_v: " + block + "\n";
  YamlPtr parsed = yamlParse(probe);
  YamlRef v = yamlGet(parsed, "_v");
  const std::string* s = yamlAsStr(v);
  return s != nullptr && *s == value;
}

/* Literal block at relative indent 2 when it round-trips, else JSON quoting. */
static std::string scalarRepr(const std::string& value) {
  auto block = literalBlock(value);
  if (block.has_value() && roundTrips(*block, value)) {
    return *block;
  }
  return jsJsonString(value);
}

/* Writes `<indent><key>: <scalar>`, re-indenting body lines to key_indent+2. */
static void writeScalar(std::string& out, std::size_t keyIndent,
                        const std::string& key, const std::string& value) {
  std::string repr = scalarRepr(value);
  std::string ek = jsJsonString(key);
  out.append(keyIndent, ' ');
  out += ek;
  out += ": ";
  // repr.split('\n'): first line inline, rest re-indented.
  std::size_t start = 0;
  bool first = true;
  std::size_t rlen = repr.size();
  for (std::size_t i = 0;; i++) {
    if (i == rlen || repr[i] == '\n') {
      std::size_t llen = i - start;
      if (first) {
        out += repr.substr(start, llen);
        out.push_back('\n');
        first = false;
      } else if (llen == 0) {
        out.push_back('\n');
      } else {
        out.append(keyIndent, ' ');
        out += repr.substr(start, llen);
        out.push_back('\n');
      }
      if (i == rlen) {
        break;
      }
      start = i + 1;
    }
  }
}

static void writeHeader(std::string& out, const std::string& modelVersion) {
  out += "# TomSpecs document (*.docspecs.yaml).\n";
  out +=
      "# `document:` holds the object-model values, sorted by section id; text\n";
  out +=
      "# values use block scalars so multi-line content round-trips verbatim "
      "(\xC2\xA7""15.1).\n";
  out += "version: ";
  out += formatI64(kSpecYamlFormatVersion);
  out.push_back('\n');
  if (!modelVersion.empty()) {
    out += "modelVersion: ";
    out += jsJsonString(modelVersion);
    out.push_back('\n');
  }
}

static void writeDocumentPass(std::string& out, const DocumentJson& doc) {
  if (doc.content.empty() && doc.forms.empty() && doc.lists.empty()) {
    out += "document: {}\n";
    return;
  }
  out += "document:\n";

  if (!doc.content.empty()) {
    out += "  content:\n";
    for (const auto& kv : doc.content) {
      writeScalar(out, 4, kv.first, kv.second);
    }
  }

  if (!doc.forms.empty()) {
    out += "  forms:\n";
    for (const auto& kv : doc.forms) {
      if (kv.second.empty()) {
        continue;
      }
      out += "    ";
      out += jsJsonString(kv.first);
      out += ":\n";
      for (const auto& fv : kv.second) {
        writeScalar(out, 6, fv.first, fv.second);
      }
    }
  }

  if (!doc.lists.empty()) {
    out += "  lists:\n";
    for (const auto& kv : doc.lists) {
      out += "    ";
      out += jsJsonString(kv.first);
      out += ":\n";
      out += "      seq: ";
      out += formatI64(kv.second.seq);
      out.push_back('\n');
      if (!kv.second.items.empty()) {
        out += "      items:\n";
        for (const auto& it : kv.second.items) {
          out += "        - ";
          out += jsJsonString(it);
          out.push_back('\n');
        }
      } else {
        out += "      items: []\n";
      }
    }
  }
}

std::string encodeYaml(const SpecDocument& document,
                       const std::string& modelVersion) {
  std::string out;
  writeHeader(out, modelVersion);
  DocumentJson dj = document.toJson();
  writeDocumentPass(out, dj);
  return out;
}

/* Converts the parsed `document:` mapping into a DocumentJson. */
static DocumentJson docJsonFromYaml(const YamlRef& v) {
  DocumentJson out;
  if (v == nullptr || v->type != YamlType::Map) {
    return out;
  }
  YamlRef content = yamlGet(v, "content");
  if (content != nullptr && content->type == YamlType::Map) {
    for (const auto& kv : content->map) {
      out.content[kv.first] =
          yamlScalarString(std::const_pointer_cast<const YamlValue>(kv.second));
    }
  }
  YamlRef forms = yamlGet(v, "forms");
  if (forms != nullptr && forms->type == YamlType::Map) {
    for (const auto& kv : forms->map) {
      if (kv.second->type != YamlType::Map) {
        continue;
      }
      auto& fields = out.forms[kv.first];
      for (const auto& fv : kv.second->map) {
        fields[fv.first] =
            yamlScalarString(std::const_pointer_cast<const YamlValue>(fv.second));
      }
    }
  }
  YamlRef lists = yamlGet(v, "lists");
  if (lists != nullptr && lists->type == YamlType::Map) {
    for (const auto& kv : lists->map) {
      if (kv.second->type != YamlType::Map) {
        continue;
      }
      YamlRef spec = std::const_pointer_cast<const YamlValue>(kv.second);
      DocListEntry& e = out.lists[kv.first];
      auto seq = yamlAsInt(yamlGet(spec, "seq"));
      e.seq = seq.value_or(0);
      YamlRef items = yamlGet(spec, "items");
      if (items != nullptr && items->type == YamlType::Seq) {
        for (const auto& item : items->seq) {
          e.items.push_back(
              yamlScalarString(std::const_pointer_cast<const YamlValue>(item)));
        }
      }
    }
  }
  return out;
}

SpecYamlContents decodeYaml(const std::string& yamlText) {
  SpecYamlContents out;
  YamlPtr root;
  // blank -> empty map
  std::size_t s = 0, e = yamlText.size();
  while (s < e && (yamlText[s] == ' ' || yamlText[s] == '\t' ||
                   yamlText[s] == '\r' || yamlText[s] == '\n')) {
    s++;
  }
  if (s == e) {
    root = yamlParse("");
  } else {
    root = yamlParse(yamlText);
  }

  out.document = docJsonFromYaml(yamlGet(root, "document"));

  const std::string* mv = yamlAsStr(yamlGet(root, "modelVersion"));
  out.modelVersion = mv != nullptr ? *mv : "";

  return out;
}

}  // namespace som
