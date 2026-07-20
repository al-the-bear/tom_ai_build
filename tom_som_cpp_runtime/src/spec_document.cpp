#include "spec_document.hpp"

#include <fstream>
#include <sstream>
#include <stdexcept>

#include "som_util.hpp"
#include "spec_document_markdown.hpp"
#include "spec_document_yaml.hpp"
#include "spec_model.hpp"
#include "spec_section_id.hpp"

namespace som {

/* ---- one-call Markdown export (item 12) --------------------------------- */

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

/* ---- one-call document loading (item 4) --------------------------------- */

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
  // leaf exists at exactly `path` (§ item 5).
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

/* --- stored codeSpec mappings (§9.2) — mirror of stored headlines --- */

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
