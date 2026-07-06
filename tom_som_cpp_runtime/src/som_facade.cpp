/* Idiomatic-C++ port of the C `som_facade` module. */
#include "som_facade.hpp"

#include <optional>

#include "som_util.hpp"
#include "spec_paths.hpp"
#include "spec_section_id.hpp"

namespace som {

std::string joinPath(const std::string& parent, const std::string& segment) {
  return specPathJoin(parent, segment);
}

/* ---- SomList section-id-aware adds --------------------------------------- */

std::string SomList::addGenerated(long long month, long long day) {
  std::string id = specGenerateListItemSectionId(pattern_, month, day,
                                                 doc().listItemSectionIds(path()));
  return doc().addListItemWithSectionId(path(), id);
}

std::string SomList::add() {
  if (pattern_.empty()) {
    return doc().addListItem(path());
  }
  auto md = specTodayMonthDay();
  return addGenerated(md.first, md.second);
}

std::string SomList::addOn(long long month, long long day) {
  if (pattern_.empty()) {
    return doc().addListItem(path());
  }
  return addGenerated(month, day);
}

std::string SomList::addWithId(const std::string& sectionId) {
  return doc().addListItemWithSectionId(path(), sectionId);
}

/* ---- model-version guard ------------------------------------------------ */

namespace {

struct SomVersion {
  long long major = 0;
  long long minor = 0;
  bool ok = false;
};

std::optional<long long> tryInt(const std::string& raw) {
  if (raw.empty()) {
    return std::nullopt;
  }
  std::size_t i = 0;
  if (raw[0] == '-' || raw[0] == '+') {
    if (raw.size() == 1) {
      return std::nullopt;
    }
    i = 1;
  }
  for (std::size_t j = i; j < raw.size(); j++) {
    if (raw[j] < '0' || raw[j] > '9') {
      return std::nullopt;
    }
  }
  return parseI64(raw);
}

SomVersion tryParseSomVersion(const std::string& raw) {
  SomVersion v;
  std::size_t dot = raw.find('.');
  if (dot == std::string::npos) {
    return v;
  }
  if (raw.find('.', dot + 1) != std::string::npos) {
    return v;  // more than two parts
  }
  auto major = tryInt(raw.substr(0, dot));
  auto minor = tryInt(raw.substr(dot + 1));
  if (!major.has_value() || !minor.has_value()) {
    return v;
  }
  v.major = *major;
  v.minor = *minor;
  v.ok = true;
  return v;
}

}  // namespace

void checkSomModelVersion(const std::string& generated,
                          const std::string& documentVersion) {
  if (documentVersion.empty()) {
    return;
  }
  SomVersion gen = tryParseSomVersion(generated);
  if (!gen.ok) {
    throw SomVersionError("\"" + generated +
                          "\" is not a valid major.minor version");
  }
  SomVersion docv = tryParseSomVersion(documentVersion);
  if (!docv.ok) {
    throw SomVersionError("document model version \"" + documentVersion +
                          "\" is not a valid major.minor");
  }
  if (docv.major != gen.major) {
    throw SomVersionError(
        "document major version " + formatI64(docv.major) +
        " differs from the object model major version " + formatI64(gen.major) +
        "; cross-major documents are read-only");
  }
  if (docv.minor > gen.minor) {
    throw SomVersionError(
        "document model version " + documentVersion +
        " is newer than the object model version " + generated +
        "; an older object model cannot edit a newer document");
  }
}

}  // namespace som
