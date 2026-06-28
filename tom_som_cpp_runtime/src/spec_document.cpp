#include "spec_document.hpp"

#include "som_util.hpp"

namespace som {

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
      b += "]}";
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
  return content_.empty() && forms_.empty() && listItems_.empty();
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
    out.lists[kv.first] = std::move(e);
  }
  return out;
}

void SpecDocument::loadJson(const DocumentJson& j) {
  content_.clear();
  forms_.clear();
  listItems_.clear();
  listSeq_.clear();

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
  }
}

}  // namespace som
