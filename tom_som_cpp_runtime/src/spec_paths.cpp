#include "spec_paths.hpp"

#include "som_util.hpp"

namespace som {

std::string specPathJoin(const std::string& parent, const std::string& segment) {
  return parent + kSpecPathSeparator + segment;
}

std::vector<std::string> specPathSegments(const std::string& path) {
  std::vector<std::string> out;
  std::size_t start = 0;
  for (std::size_t i = 0;; i++) {
    if (i == path.size() || path[i] == '/') {
      out.push_back(path.substr(start, i - start));
      if (i == path.size()) {
        break;
      }
      start = i + 1;
    }
  }
  return out;
}

std::string specListItemPath(const std::string& listPath, long long seq) {
  return listPath + "-" + formatI64(seq);
}

bool specSplitListItemSegment(const std::string& segment, std::string* base,
                              long long* seq) {
  std::size_t n = segment.size();
  std::size_t dash = 0;
  bool found = false;
  for (std::size_t i = n; i > 0; i--) {
    if (segment[i - 1] == '-') {
      dash = i - 1;
      found = true;
      break;
    }
  }
  if (!found) {
    return false;
  }
  if (dash == 0 || dash == n - 1) {
    return false;
  }
  std::string tail = segment.substr(dash + 1);
  if (!isAllDigits(tail)) {
    return false;
  }
  auto v = parseI64(tail);
  if (!v.has_value()) {
    return false;
  }
  *base = segment.substr(0, dash);
  *seq = *v;
  return true;
}

}  // namespace som
