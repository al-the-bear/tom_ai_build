#include "spec_document.hpp"

#include <fstream>
#include <iterator>
#include <sstream>
#include <stdexcept>

#include "som_util.hpp"
#include "spec_document_markdown.hpp"
#include "spec_document_yaml.hpp"
#include "spec_model.hpp"
#include "spec_reflection.hpp"
#include "spec_section_id.hpp"

namespace som {

/* ---- one-call Markdown export (SOM §21) --------------------------------- */

std::string SpecDocument::toMarkdown(const SpecModel& model,
                                     const std::string& rootType) const {
  if (!rootType.empty()) {
    return markdownExportRoot(model, *this, model.rootByType(rootType));
  }
  // Default: the single root under which this document holds any value.
  std::vector<const SpecRoot*> populated;
  for (const auto& r : model.roots) {
    const std::string& seg = !r.sectionId.empty() ? r.sectionId : r.type;
    if (hasValuesUnder(seg)) {
      populated.push_back(&r);
    }
  }
  if (populated.size() == 1) {
    return markdownExportRoot(model, *this, *populated.front());
  }
  if (populated.empty()) {
    throw std::runtime_error(
        "document has no populated root to export; pass rootType to choose "
        "one");
  }
  std::string types;
  for (const SpecRoot* r : populated) {
    if (!types.empty()) {
      types += ", ";
    }
    types += r->type;
  }
  throw std::runtime_error("document has " + std::to_string(populated.size()) +
                           " populated roots (" + types +
                           "); pass rootType to choose one");
}

/* ---- Markdown import (SOM §11.7) ---------------------------------------- */

SpecMarkdownImport SpecDocument::fromMarkdown(const std::string& text,
                                              const SpecModel& model) {
  SpecMarkdownImport imported;
  imported.result = markdownParse(model, text);
  imported.document.applyMarkdownResult(imported.result, true);
  return imported;
}

void SpecDocument::applyMarkdownResult(const SpecMarkdownResult& result,
                                       bool allowRejections) {
  if (!allowRejections && !result.rejections.empty()) {
    const SpecMarkdownRejection& first = result.rejections.front();
    throw std::runtime_error(
        "markdown import has " + std::to_string(result.rejections.size()) +
        " rejected block(s); first at line " + std::to_string(first.line) +
        ": " + first.message);
  }
  if (result.rootPrefixes.empty()) {
    return;
  }
  for (const std::string& prefix : result.rootPrefixes) {
    removeValuesUnder(prefix);
  }

  // Carry over everything the purge left, then lay the parsed values on top:
  // a parsed key replaces the held one (a form or list as a whole).
  DocumentJson merged = toJson();
  const DocumentJson& parsed = result.staged;
  for (const auto& kv : parsed.content) merged.content[kv.first] = kv.second;
  for (const auto& kv : parsed.forms) merged.forms[kv.first] = kv.second;
  for (const auto& kv : parsed.lists) merged.lists[kv.first] = kv.second;
  for (const auto& kv : parsed.headlines) {
    merged.headlines[kv.first] = kv.second;
  }
  for (const auto& kv : parsed.codeSpecs) {
    merged.codeSpecs[kv.first] = kv.second;
  }
  loadJson(merged);
}

/* ---- one-call document loading (SOM §21) -------------------------------- */

std::optional<SpecDocument> SpecDocument::fromYaml(const std::string& yaml,
                                                   const SomMetaTree& tree,
                                                   std::string* err) {
  SpecYamlContents decoded;
  if (!decodeYaml(yaml, tree, &decoded, err)) {
    return std::nullopt;
  }
  // The decoded document already carries its stamped model version.
  return std::move(decoded.document);
}

std::optional<SpecDocument> SpecDocument::fromFile(const std::string& path,
                                                   const SomMetaTree& tree,
                                                   std::string* err) {
  std::ifstream in(path, std::ios::binary);
  if (!in) {
    if (err != nullptr) {
      *err = "cannot read file: " + path;
    }
    return std::nullopt;
  }
  std::stringstream buffer;
  buffer << in.rdbuf();
  return fromYaml(buffer.str(), tree, err);
}

/* ---- is_under ----------------------------------------------------------- */

/* Reports whether `key` is `prefix` itself or nested beneath it (`prefix/...`
 * or `prefix-...`). Mirrors the C is_under. */
static bool isUnder(const std::string& key, const std::string& prefix) {
  if (key == prefix) {
    return true;
  }
  if (key.size() < prefix.size() || key.compare(0, prefix.size(), prefix) != 0) {
    return false;
  }
  char next = key[prefix.size()];
  return next == '/' || next == '-';
}

/* ======================================================================== */
/* DocumentJson                                                              */
/* ======================================================================== */

DocumentJson documentJsonFromJson(const JsonRef& v) {
  DocumentJson out;

  JsonRef content = jsonGet(v, "content");
  if (content != nullptr && content->type == JsonType::Object) {
    for (const auto& m : content->object) {
      const std::string* s = jsonAsStr(m.second);
      if (s != nullptr) {
        out.content[m.first] = *s;
      }
    }
  }

  JsonRef forms = jsonGet(v, "forms");
  if (forms != nullptr && forms->type == JsonType::Object) {
    for (const auto& m : forms->object) {
      if (m.second->type != JsonType::Object) {
        continue;
      }
      auto& fields = out.forms[m.first];
      for (const auto& fm : m.second->object) {
        const std::string* s = jsonAsStr(fm.second);
        if (s != nullptr) {
          fields[fm.first] = *s;
        }
      }
    }
  }

  JsonRef lists = jsonGet(v, "lists");
  if (lists != nullptr && lists->type == JsonType::Object) {
    for (const auto& m : lists->object) {
      DocListEntry& e = out.lists[m.first];
      auto seq = jsonAsI64(jsonGet(m.second, "seq"));
      e.seq = seq.value_or(0);
      JsonRef items = jsonGet(m.second, "items");
      std::size_t n = jsonArrayLen(items);
      for (std::size_t j = 0; j < n; j++) {
        const std::string* s = jsonAsStr(jsonArrayAt(items, j));
        if (s != nullptr) {
          e.items.push_back(*s);
        }
      }
      JsonRef ids = jsonGet(m.second, "ids");
      if (ids != nullptr && ids->type == JsonType::Object) {
        for (const auto& im : ids->object) {
          const std::string* s = jsonAsStr(im.second);
          if (s != nullptr) {
            e.ids[im.first] = *s;
          }
        }
      }
    }
  }

  JsonRef headlines = jsonGet(v, "headlines");
  if (headlines != nullptr && headlines->type == JsonType::Object) {
    for (const auto& m : headlines->object) {
      const std::string* s = jsonAsStr(m.second);
      if (s != nullptr) {
        out.headlines[m.first] = *s;
      }
    }
  }

  JsonRef codeSpecs = jsonGet(v, "codeSpecs");
  if (codeSpecs != nullptr && codeSpecs->type == JsonType::Object) {
    for (const auto& m : codeSpecs->object) {
      const std::string* s = jsonAsStr(m.second);
      if (s != nullptr) {
        out.codeSpecs[m.first] = *s;
      }
    }
  }

  return out;
}

std::string documentJsonToCanonicalJson(const DocumentJson& d) {
  std::string b;
  b.push_back('{');
  bool first = true;

  if (!d.content.empty()) {
    first = false;
    b += "\"content\":{";
    bool inner = true;
    for (const auto& kv : d.content) {
      if (!inner) {
        b.push_back(',');
      }
      inner = false;
      b += jsonEncodeStr(kv.first);
      b.push_back(':');
      b += jsonEncodeStr(kv.second);
    }
    b.push_back('}');
  }

  if (!d.forms.empty()) {
    if (!first) {
      b.push_back(',');
    }
    first = false;
    b += "\"forms\":{";
    bool inner = true;
    for (const auto& kv : d.forms) {
      if (!inner) {
        b.push_back(',');
      }
      inner = false;
      b += jsonEncodeStr(kv.first);
      b += ":{";
      bool fi = true;
      for (const auto& fv : kv.second) {
        if (!fi) {
          b.push_back(',');
        }
        fi = false;
        b += jsonEncodeStr(fv.first);
        b.push_back(':');
        b += jsonEncodeStr(fv.second);
      }
      b.push_back('}');
    }
    b.push_back('}');
  }

  if (!d.lists.empty()) {
    if (!first) {
      b.push_back(',');
    }
    first = false;
    b += "\"lists\":{";
    bool inner = true;
    for (const auto& kv : d.lists) {
      if (!inner) {
        b.push_back(',');
      }
      inner = false;
      b += jsonEncodeStr(kv.first);
      b += ":{\"seq\":";
      b += formatI64(kv.second.seq);
      b += ",\"items\":[";
      bool ii = true;
      for (const auto& it : kv.second.items) {
        if (!ii) {
          b.push_back(',');
        }
        ii = false;
        b += jsonEncodeStr(it);
      }
      b.push_back(']');
      if (!kv.second.ids.empty()) {
        b += ",\"ids\":{";
        bool di = true;
        for (const auto& idkv : kv.second.ids) {
          if (!di) {
            b.push_back(',');
          }
          di = false;
          b += jsonEncodeStr(idkv.first);
          b.push_back(':');
          b += jsonEncodeStr(idkv.second);
        }
        b.push_back('}');
      }
      b.push_back('}');
    }
    b.push_back('}');
  }

  if (!d.headlines.empty()) {
    if (!first) {
      b.push_back(',');
    }
    first = false;
    b += "\"headlines\":{";
    bool inner = true;
    for (const auto& kv : d.headlines) {
      if (!inner) {
        b.push_back(',');
      }
      inner = false;
      b += jsonEncodeStr(kv.first);
      b.push_back(':');
      b += jsonEncodeStr(kv.second);
    }
    b.push_back('}');
  }

  if (!d.codeSpecs.empty()) {
    if (!first) {
      b.push_back(',');
    }
    first = false;
    b += "\"codeSpecs\":{";
    bool inner = true;
    for (const auto& kv : d.codeSpecs) {
      if (!inner) {
        b.push_back(',');
      }
      inner = false;
      b += jsonEncodeStr(kv.first);
      b.push_back(':');
      b += jsonEncodeStr(kv.second);
    }
    b.push_back('}');
  }

  b.push_back('}');
  return b;
}

/* ======================================================================== */
/* SpecDocument                                                             */
/* ======================================================================== */

/* --- content --- */

const std::string* SpecDocument::contentOpt(const std::string& path) const {
  auto it = content_.find(path);
  return it != content_.end() ? &it->second : nullptr;
}

std::string SpecDocument::content(const std::string& path) const {
  const std::string* v = contentOpt(path);
  return v != nullptr ? *v : std::string();
}

bool SpecDocument::hasContent(const std::string& path) const {
  // content() returns "" when unset, so a non-empty result means a filled
  // leaf exists at exactly `path` (SOM §21).
  return !content(path).empty();
}

void SpecDocument::setContent(const std::string& path, const std::string& value) {
  if (value.empty()) {
    content_.erase(path);
  } else {
    content_[path] = value;
  }
}

/* --- forms --- */

const std::string* SpecDocument::formFieldOpt(const std::string& path,
                                              const std::string& fieldName) const {
  auto it = forms_.find(path);
  if (it == forms_.end()) {
    return nullptr;
  }
  auto fit = it->second.find(fieldName);
  return fit != it->second.end() ? &fit->second : nullptr;
}

std::string SpecDocument::formField(const std::string& path,
                                    const std::string& fieldName) const {
  const std::string* v = formFieldOpt(path, fieldName);
  return v != nullptr ? *v : std::string();
}

void SpecDocument::setFormField(const std::string& path,
                                const std::string& fieldName,
                                const std::string& value) {
  if (value.empty()) {
    auto it = forms_.find(path);
    if (it != forms_.end()) {
      it->second.erase(fieldName);
      if (it->second.empty()) {
        forms_.erase(it);
      }
    }
    return;
  }
  forms_[path][fieldName] = value;
}

/* --- lists --- */

const std::vector<std::string>* SpecDocument::listItemsPtr(
    const std::string& listPath) const {
  auto it = listItems_.find(listPath);
  return it != listItems_.end() ? &it->second : nullptr;
}

std::vector<std::string> SpecDocument::listItems(
    const std::string& listPath) const {
  const std::vector<std::string>* p = listItemsPtr(listPath);
  return p != nullptr ? *p : std::vector<std::string>();
}

std::string SpecDocument::addListItem(const std::string& listPath) {
  long long seq = 0;
  auto it = listSeq_.find(listPath);
  if (it != listSeq_.end()) {
    seq = it->second;
  }
  seq += 1;
  listSeq_[listPath] = seq;

  std::string itemPath = listPath + "-" + formatI64(seq);
  listItems_[listPath].push_back(itemPath);
  return itemPath;
}

/* --- section ids --- */

std::string SpecDocument::owningListOf(const std::string& itemPath) const {
  for (const auto& kv : listItems_) {
    for (const auto& v : kv.second) {
      if (v == itemPath) {
        return kv.first;
      }
    }
  }
  return "";
}

void SpecDocument::assertSectionIdFree(const std::string& listPath,
                                       const std::string& id,
                                       const std::string& exceptItemPath) const {
  auto it = listItems_.find(listPath);
  if (it == listItems_.end()) {
    return;
  }
  for (const std::string& itemPath : it->second) {
    if (!exceptItemPath.empty() && itemPath == exceptItemPath) {
      continue;
    }
    auto cur = itemSectionId_.find(itemPath);
    if (cur != itemSectionId_.end() && cur->second == id) {
      throw SomSectionIdError::collision(id, listPath);
    }
  }
}

std::string SpecDocument::addListItemWithSectionId(const std::string& listPath,
                                                   const std::string& sectionId) {
  assertSectionIdFree(listPath, sectionId, "");
  std::string itemPath = addListItem(listPath);
  itemSectionId_[itemPath] = sectionId;
  return itemPath;
}

const std::string* SpecDocument::itemSectionIdOpt(
    const std::string& itemPath) const {
  auto it = itemSectionId_.find(itemPath);
  return it != itemSectionId_.end() ? &it->second : nullptr;
}

std::string SpecDocument::itemSectionId(const std::string& itemPath) const {
  const std::string* v = itemSectionIdOpt(itemPath);
  return v != nullptr ? *v : std::string();
}

void SpecDocument::setItemSectionId(const std::string& itemPath,
                                    const std::string& id) {
  std::string owning = owningListOf(itemPath);
  if (owning.empty()) {
    throw SomSectionIdError::notLiveItem(itemPath);
  }
  auto cur = itemSectionId_.find(itemPath);
  if (cur != itemSectionId_.end() && cur->second == id) {
    return;
  }
  assertSectionIdFree(owning, id, itemPath);
  itemSectionId_[itemPath] = id;
}

std::vector<std::string> SpecDocument::listItemSectionIds(
    const std::string& listPath) const {
  std::vector<std::string> out;
  auto it = listItems_.find(listPath);
  if (it == listItems_.end()) {
    return out;
  }
  for (const std::string& itemPath : it->second) {
    const std::string* id = itemSectionIdOpt(itemPath);
    if (id != nullptr) {
      out.push_back(*id);
    }
  }
  return out;
}

/* --- stored headlines (YRD3) --- */

const std::string* SpecDocument::headlineOpt(const std::string& path) const {
  auto it = headline_.find(path);
  return it != headline_.end() ? &it->second : nullptr;
}

std::string SpecDocument::headline(const std::string& path) const {
  const std::string* v = headlineOpt(path);
  return v != nullptr ? *v : std::string();
}

void SpecDocument::setHeadline(const std::string& path,
                               const std::string& value) {
  if (value.empty()) {
    headline_.erase(path);
  } else {
    headline_[path] = value;
  }
}

std::vector<std::string> SpecDocument::headlinePaths() const {
  std::vector<std::string> out;
  for (const auto& kv : headline_) {
    out.push_back(kv.first);
  }
  return out;
}

/* --- stored codeSpec mappings (codespecs_mapping.md §9.2) — mirror of stored headlines --- */

const std::string* SpecDocument::codeSpecOpt(const std::string& path) const {
  auto it = codeSpec_.find(path);
  return it != codeSpec_.end() ? &it->second : nullptr;
}

std::string SpecDocument::codeSpec(const std::string& path) const {
  const std::string* v = codeSpecOpt(path);
  return v != nullptr ? *v : std::string();
}

void SpecDocument::setCodeSpec(const std::string& path,
                               const std::string& value) {
  if (value.empty()) {
    codeSpec_.erase(path);
  } else {
    codeSpec_[path] = value;
  }
}

std::vector<std::string> SpecDocument::codeSpecPaths() const {
  std::vector<std::string> out;
  for (const auto& kv : codeSpec_) {
    out.push_back(kv.first);
  }
  return out;
}

void SpecDocument::removeValuesUnder(const std::string& prefix) {
  purgeUnder(prefix);
}

void SpecDocument::purgeUnder(const std::string& prefix) {
  for (auto it = content_.begin(); it != content_.end();) {
    if (isUnder(it->first, prefix)) {
      it = content_.erase(it);
    } else {
      ++it;
    }
  }
  for (auto it = forms_.begin(); it != forms_.end();) {
    if (isUnder(it->first, prefix)) {
      it = forms_.erase(it);
    } else {
      ++it;
    }
  }
  for (auto it = listItems_.begin(); it != listItems_.end();) {
    if (isUnder(it->first, prefix)) {
      it = listItems_.erase(it);
    } else {
      ++it;
    }
  }
  for (auto it = listSeq_.begin(); it != listSeq_.end();) {
    if (isUnder(it->first, prefix)) {
      it = listSeq_.erase(it);
    } else {
      ++it;
    }
  }
  for (auto it = itemSectionId_.begin(); it != itemSectionId_.end();) {
    if (isUnder(it->first, prefix)) {
      it = itemSectionId_.erase(it);
    } else {
      ++it;
    }
  }
  for (auto it = headline_.begin(); it != headline_.end();) {
    if (isUnder(it->first, prefix)) {
      it = headline_.erase(it);
    } else {
      ++it;
    }
  }
  for (auto it = codeSpec_.begin(); it != codeSpec_.end();) {
    if (isUnder(it->first, prefix)) {
      it = codeSpec_.erase(it);
    } else {
      ++it;
    }
  }
}

bool SpecDocument::removeListItem(const std::string& itemPath) {
  std::string owning;
  bool found = false;
  for (const auto& kv : listItems_) {
    for (const auto& v : kv.second) {
      if (v == itemPath) {
        owning = kv.first;
        found = true;
        break;
      }
    }
    if (found) {
      break;
    }
  }
  if (!found) {
    return false;
  }
  auto& items = listItems_[owning];
  for (auto it = items.begin(); it != items.end(); ++it) {
    if (*it == itemPath) {
      items.erase(it);
      break;
    }
  }
  if (items.empty()) {
    listItems_.erase(owning);
  }
  purgeUnder(itemPath);
  return true;
}

/* --- queries --- */

bool SpecDocument::isEmpty() const {
  return content_.empty() && forms_.empty() && listItems_.empty() &&
         headline_.empty() && codeSpec_.empty();
}

bool SpecDocument::hasValuesUnder(const std::string& prefix) const {
  for (const auto& kv : content_) {
    if (isUnder(kv.first, prefix)) {
      return true;
    }
  }
  for (const auto& kv : forms_) {
    if (isUnder(kv.first, prefix)) {
      return true;
    }
  }
  for (const auto& kv : listItems_) {
    if (isUnder(kv.first, prefix)) {
      return true;
    }
  }
  for (const auto& kv : headline_) {
    if (isUnder(kv.first, prefix)) {
      return true;
    }
  }
  for (const auto& kv : codeSpec_) {
    if (isUnder(kv.first, prefix)) {
      return true;
    }
  }
  return false;
}

std::vector<std::string> SpecDocument::contentPaths() const {
  std::vector<std::string> out;
  for (const auto& kv : content_) {
    out.push_back(kv.first);
  }
  return out;
}

std::vector<std::string> SpecDocument::formPaths() const {
  std::vector<std::string> out;
  for (const auto& kv : forms_) {
    out.push_back(kv.first);
  }
  return out;
}

std::vector<std::string> SpecDocument::listPaths() const {
  std::vector<std::string> out;
  for (const auto& kv : listItems_) {
    out.push_back(kv.first);
  }
  return out;
}

std::vector<std::string> SpecDocument::formFieldNames(
    const std::string& path) const {
  std::vector<std::string> out;
  auto it = forms_.find(path);
  if (it == forms_.end()) {
    return out;
  }
  for (const auto& kv : it->second) {
    out.push_back(kv.first);
  }
  return out;
}

std::size_t SpecDocument::listItemCount(const std::string& listPath) const {
  auto it = listItems_.find(listPath);
  return it != listItems_.end() ? it->second.size() : 0;
}

/* --- persistence --- */

/* --- moving a list item (vsctsa44) --- */

std::string specRekeyPath(const std::string& key, const SpecPathPairs& renamed) {
  for (const auto& [old, now] : renamed) {
    if (isUnder(key, old)) {
      return now + key.substr(old.size());
    }
  }
  return key;
}

/* Whether `s` from `at` matches `.+<segs[i]>.+<segs[i+1]>…` to its end — the
 * tail of the anchored pattern regex, `.` excluding line breaks as a Dart
 * RegExp's does. */
static bool patternTailMatches(const std::vector<std::string>& segs,
                               std::size_t i, const std::string& s,
                               std::size_t at) {
  if (i == segs.size()) {
    return at == s.size();
  }
  const std::string& seg = segs[i];
  for (std::size_t k = at + 1; k <= s.size(); k++) {
    char consumed = s[k - 1];
    if (consumed == '\n' || consumed == '\r') {
      return false;
    }
    if (s.compare(k, seg.size(), seg) == 0 && k + seg.size() <= s.size() &&
        patternTailMatches(segs, i + 1, s, k + seg.size())) {
      return true;
    }
  }
  return false;
}

/* Whether `id` fits the `@SectionIdPattern` `pattern`: each `xxx` stands for
 * one or more characters, everything else is literal, the whole id must match
 * (the Dart `_sectionIdFitsPattern`). */
static bool sectionIdFitsPattern(const std::string& pattern,
                                 const std::string& id) {
  std::vector<std::string> segs;
  std::size_t p = 0, xxx;
  while ((xxx = pattern.find("xxx", p)) != std::string::npos) {
    segs.push_back(pattern.substr(p, xxx - p));
    p = xxx + 3;
  }
  segs.push_back(pattern.substr(p));
  return id.compare(0, segs[0].size(), segs[0]) == 0 &&
         id.size() >= segs[0].size() &&
         patternTailMatches(segs, 1, id, segs[0].size());
}

/* The id an item of `list` (described by `field`, null when unresolved) is
 * identified by at 1-based `position`. */
static std::string moveEffectiveId(const std::string* storedId,
                                   const SpecField* field,
                                   const std::string& list,
                                   long long position) {
  std::string stem;
  if (field != nullptr) {
    stem = field->name;
  } else {
    std::size_t slash = list.rfind('/');
    stem = slash == std::string::npos ? list : list.substr(slash + 1);
  }
  return effectiveListItemSectionId(
      storedId, field != nullptr ? field->sectionIdPattern : std::string(),
      position, stem);
}

/* A copy of `store` with every key re-keyed (a later entry wins a key two
 * entries re-key to, as in a Dart map). */
template <typename V>
static std::map<std::string, V> rekeyStore(const std::map<std::string, V>& store,
                                           const SpecPathPairs& renamed) {
  std::map<std::string, V> out;
  for (const auto& kv : store) {
    out[specRekeyPath(kv.first, renamed)] = kv.second;
  }
  return out;
}

SpecListItemMove SpecDocument::moveListItem(
    const SpecModel& model, const std::string& itemPath, long long toIndex,
    const std::optional<std::string>& toList) {
  // A copy: `itemPath` may be borrowed from a store the move replaces.
  const std::string item = itemPath;
  const std::string from = owningListOf(item);
  if (from.empty()) {
    throw std::invalid_argument("itemPath \"" + item +
                                "\": not a live list item");
  }
  const std::string to = toList.has_value() ? *toList : from;
  const bool cross = to != from;
  const SpecReflection refl(model);
  const std::optional<SpecResolution> fromRes = refl.resolve(from);
  const std::optional<SpecResolution> toRes = refl.resolve(to);
  const SpecField* fromField = fromRes ? fromRes->field : nullptr;
  const SpecField* toField = toRes ? toRes->field : nullptr;
  if (toField == nullptr || toField->kind != kSpecFieldKindList) {
    throw std::invalid_argument("toList \"" + to +
                                "\": not a list of the model");
  }
  if (cross && (fromField == nullptr ||
                toField->elementType != fromField->elementType)) {
    throw std::invalid_argument(
        "toList \"" + to + "\": holds " + toField->elementType +
        ", but the item is a " +
        (fromField != nullptr ? fromField->elementType : std::string("null")) +
        " — an item moves only between lists of its own element class");
  }
  const std::string* storedId = itemSectionIdOpt(item);
  if (cross && storedId != nullptr) {
    const std::string& pattern = toField->sectionIdPattern;
    if (!pattern.empty() && !sectionIdFitsPattern(pattern, *storedId)) {
      throw std::invalid_argument(
          "itemPath \"" + item + "\": section id \"" + *storedId +
          "\" does not fit the destination pattern " + pattern +
          " — set an id that does before moving the item");
    }
    assertSectionIdFree(to, *storedId, "");
  }

  // The new orders.
  const std::vector<std::string>& fromOld = listItems_.at(from);
  std::vector<std::string> fromItems;
  for (const std::string& p : fromOld) {
    if (p != item) {
      fromItems.push_back(p);
    }
  }
  static const std::vector<std::string> kNone;
  auto toIt = cross ? listItems_.find(to) : listItems_.end();
  const std::vector<std::string>& toOld =
      toIt != listItems_.end() ? toIt->second : kNone;
  std::vector<std::string> toOwn = cross ? toOld : std::vector<std::string>();
  std::vector<std::string>& toItems = cross ? toOwn : fromItems;
  if (toIndex < 0 || toIndex > static_cast<long long>(toItems.size())) {
    throw std::out_of_range("toIndex " + formatI64(toIndex) +
                            ": not in range 0.." +
                            formatI64(static_cast<long long>(toItems.size())));
  }
  toItems.insert(toItems.begin() + toIndex, item);

  // Each affected item's effective id before the move, so an anonymous item
  // keeps its identity when its position changes.
  std::map<std::string, std::string> before;
  for (std::size_t i = 0; i < fromOld.size(); i++) {
    before[fromOld[i]] = moveEffectiveId(itemSectionIdOpt(fromOld[i]), fromField,
                                         from, static_cast<long long>(i) + 1);
  }
  for (std::size_t i = 0; cross && i < toOld.size(); i++) {
    before[toOld[i]] = moveEffectiveId(itemSectionIdOpt(toOld[i]), toField, to,
                                       static_cast<long long>(i) + 1);
  }

  // Old -> new item paths, and the ids anonymous items must now store.
  SpecListItemMove result;
  auto renumber = [&](const std::string& list,
                      const std::vector<std::string>& items,
                      const SpecField* field) {
    for (std::size_t i = 0; i < items.size(); i++) {
      const std::string& old = items[i];
      const long long pos = static_cast<long long>(i) + 1;
      std::string now = list + "-" + formatI64(pos);
      if (old != now) {
        result.renamed.emplace_back(old, now);
      }
      const bool crossing = old == item && cross;
      if (itemSectionIdOpt(old) != nullptr || crossing) {
        continue;
      }
      std::string positional = moveEffectiveId(nullptr, field, list, pos);
      const std::string& was = before.at(old);
      if (positional != was) {
        result.pinnedIds.emplace_back(old, was);
      }
    }
  };
  renumber(from, fromItems, fromField);
  if (cross) {
    renumber(to, toOwn, toField);
  }
  const SpecPathPairs& renamed = result.renamed;
  auto remap = [&](const std::string& key) {
    return specRekeyPath(key, renamed);
  };

  auto content = rekeyStore(content_, renamed);
  auto forms = rekeyStore(forms_, renamed);
  auto headline = rekeyStore(headline_, renamed);
  auto codeSpec = rekeyStore(codeSpec_, renamed);
  auto ids = rekeyStore(itemSectionId_, renamed);
  for (const auto& [old, id] : result.pinnedIds) {
    ids[remap(old)] = id;
  }
  auto seq = rekeyStore(listSeq_, renamed);
  std::map<std::string, std::vector<std::string>> lists;
  auto remapItems = [&](const std::vector<std::string>& items) {
    std::vector<std::string> out;
    out.reserve(items.size());
    for (const std::string& p : items) {
      out.push_back(remap(p));
    }
    return out;
  };
  for (const auto& kv : listItems_) {
    lists[remap(kv.first)] = remapItems(kv.second);
  }
  lists[remap(from)] = remapItems(fromItems);
  seq[remap(from)] = static_cast<long long>(fromItems.size());
  if (cross) {
    lists[remap(to)] = remapItems(toOwn);
    seq[remap(to)] = static_cast<long long>(toOwn.size());
  }
  for (auto it = lists.begin(); it != lists.end();) {
    it = it->second.empty() ? lists.erase(it) : std::next(it);
  }

  content_ = std::move(content);
  forms_ = std::move(forms);
  headline_ = std::move(headline);
  codeSpec_ = std::move(codeSpec);
  itemSectionId_ = std::move(ids);
  listSeq_ = std::move(seq);
  listItems_ = std::move(lists);

  result.path = remap(item);
  for (auto& pin : result.pinnedIds) {
    pin.first = remap(pin.first);
  }
  return result;
}

DocumentJson SpecDocument::toJson() const {
  DocumentJson out;
  out.content = content_;
  out.forms = forms_;
  for (const auto& kv : listItems_) {
    DocListEntry e;
    auto sit = listSeq_.find(kv.first);
    if (sit != listSeq_.end()) {
      e.seq = sit->second;
    } else {
      e.seq = static_cast<long long>(kv.second.size());
    }
    e.items = kv.second;
    for (const std::string& itemPath : kv.second) {
      auto idit = itemSectionId_.find(itemPath);
      if (idit != itemSectionId_.end()) {
        e.ids[itemPath] = idit->second;
      }
    }
    out.lists[kv.first] = std::move(e);
  }
  out.headlines = headline_;
  out.codeSpecs = codeSpec_;
  return out;
}

void SpecDocument::loadJson(const DocumentJson& j) {
  content_.clear();
  forms_.clear();
  listItems_.clear();
  listSeq_.clear();
  itemSectionId_.clear();
  headline_.clear();
  codeSpec_.clear();

  content_ = j.content;
  for (const auto& kv : j.forms) {
    if (kv.second.empty()) {
      continue;
    }
    forms_[kv.first] = kv.second;
  }
  for (const auto& kv : j.lists) {
    if (kv.second.items.empty()) {
      continue;
    }
    listItems_[kv.first] = kv.second.items;
    long long seq = kv.second.seq != 0
                        ? kv.second.seq
                        : static_cast<long long>(kv.second.items.size());
    listSeq_[kv.first] = seq;
    for (const auto& idkv : kv.second.ids) {
      itemSectionId_[idkv.first] = idkv.second;
    }
  }
  for (const auto& kv : j.headlines) {
    if (kv.second.empty()) {
      continue;
    }
    headline_[kv.first] = kv.second;
  }
  for (const auto& kv : j.codeSpecs) {
    if (kv.second.empty()) {
      continue;
    }
    codeSpec_[kv.first] = kv.second;
  }
}

}  // namespace som
