#include "som_util.hpp"

#include <cstdlib>

namespace som {

std::optional<long long> parseI64(const std::string& s) {
  if (s.empty()) {
    return std::nullopt;
  }
  std::size_t i = 0;
  if (s[0] == '-' || s[0] == '+') {
    if (s.size() == 1) {
      return std::nullopt;
    }
    i = 1;
  }
  for (std::size_t k = i; k < s.size(); k++) {
    if (s[k] < '0' || s[k] > '9') {
      return std::nullopt;
    }
  }
  return std::strtoll(s.c_str(), nullptr, 10);
}

bool isAllDigits(const std::string& s) {
  if (s.empty()) {
    return false;
  }
  for (char c : s) {
    if (c < '0' || c > '9') {
      return false;
    }
  }
  return true;
}

std::string formatI64(long long v) { return std::to_string(v); }

}  // namespace som
