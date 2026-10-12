/* spec_document_assembly — see spec_document_assembly.hpp. */
#include "spec_document_assembly.hpp"

#include <array>
#include <map>

namespace som {

namespace {

/* A written place: (path, field), field std::nullopt outside `forms`. The
 * std::pair ordering (path, then field, nullopt first) is the Dart
 * reference's compound key `path\u0000field` order, byte-wise. */
using Place = std::pair<std::string, std::optional<std::string>>;
using Writers = std::map<Place, std::vector<std::string>>;

enum Store { kContent, kForms, kLists, kHeadlines, kCodeSpecs, kStoreCount };

/* The fixed order overlaps are reported in. */
const std::array<const char*, kStoreCount> kStoreNames = {
    "content", "forms", "lists", "headlines", "codeSpecs"};

/* Records `name` as a writer of `place`; true when it is the first. */
bool addWriter(Writers& writers, Place place, const std::string& name) {
  std::vector<std::string>& who = writers[std::move(place)];
  who.push_back(name);
  return who.size() == 1;
}

/* Merges one path store (content / headlines / codeSpecs): the first writer's
 * value is kept, every writer is recorded. */
void mergePathStore(Writers& writers, std::map<std::string, std::string>& merged,
                    const std::map<std::string, std::string>& src,
                    const std::string& name) {
  for (const auto& kv : src) {
    if (addWriter(writers, Place(kv.first, std::nullopt), name)) {
      merged[kv.first] = kv.second;
    }
  }
}

}  // namespace

std::string SpecAssemblyOverlap::message() const {
  std::string out = field ? path + " field `" + *field + "`" : path;
  out += " (" + store + ") is written by ";
  for (std::size_t i = 0; i < fragments.size(); i++) {
    if (i > 0) out += " and ";
    out += fragments[i];
  }
  out +=
      " \xe2\x80\x94 a place two fragments both write is an authoring "
      "conflict, not something the assembly may resolve";
  return out;
}

SpecDocumentAssembly assembleSpecDocuments(const SpecAssemblyFragments& fragments) {
  std::array<Writers, kStoreCount> writers;
  DocumentJson merged;

  for (const auto& [name, doc] : fragments) {
    const DocumentJson json = doc.toJson();
    mergePathStore(writers[kContent], merged.content, json.content, name);
    mergePathStore(writers[kHeadlines], merged.headlines, json.headlines, name);
    mergePathStore(writers[kCodeSpecs], merged.codeSpecs, json.codeSpecs, name);
    for (const auto& [path, fields] : json.forms) {
      auto& target = merged.forms[path];
      for (const auto& [field, value] : fields) {
        if (addWriter(writers[kForms], Place(path, field), name)) {
          target[field] = value;
        }
      }
    }
    for (const auto& [path, spec] : json.lists) {
      if (addWriter(writers[kLists], Place(path, std::nullopt), name)) {
        merged.lists[path] = spec;
      }
    }
  }

  SpecDocumentAssembly result;
  for (int s = 0; s < kStoreCount; s++) {
    for (auto& [place, who] : writers[s]) {
      if (who.size() < 2) continue;
      SpecAssemblyOverlap o;
      o.store = kStoreNames[s];
      o.path = place.first;
      o.field = place.second;
      o.fragments = std::move(who);
      result.overlaps.push_back(std::move(o));
    }
  }
  if (result.overlaps.empty()) {
    SpecDocument document;
    document.loadJson(merged);
    result.document = std::move(document);
  }
  return result;
}

SpecDocumentAssembly SpecDocument::assemble(const SpecAssemblyFragments& fragments) {
  return assembleSpecDocuments(fragments);
}

}  // namespace som
