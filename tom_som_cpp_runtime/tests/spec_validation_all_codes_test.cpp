// kSpecValidationAllCodes must list every kSpecValidationCode* constant, in
// declaration order: it is the enumerable vocabulary a constant-based port
// owes its readers in place of an enum, and a code added without it would be
// invisible to every tool that enumerates the list. Reads the header the
// constants live in (run from the package root, as run_tests.sh does).
#include <cstdio>
#include <fstream>
#include <iterator>
#include <regex>
#include <sstream>
#include <string>
#include <vector>

#include "spec_validator.hpp"

int main() {
  std::ifstream in("include/spec_validator.hpp");
  if (!in) {
    std::fprintf(stderr, "FAIL: cannot read include/spec_validator.hpp\n");
    return 1;
  }
  std::stringstream text;
  text << in.rdbuf();
  const std::string source = text.str();
  // A declaration may wrap its value onto the next line.
  const std::regex decl(R"re(inline constexpr const char\* kSpecValidationCode[A-Za-z]+ =\s*"([A-Za-z]+)")re");
  std::vector<std::string> declared;
  for (auto it = std::sregex_iterator(source.begin(), source.end(), decl); it != std::sregex_iterator(); ++it) {
    declared.push_back((*it)[1].str());
  }
  const std::vector<std::string> listed(std::begin(som::kSpecValidationAllCodes), std::end(som::kSpecValidationAllCodes));
  if (declared.empty() || declared != listed) {
    std::fprintf(stderr, "FAIL: the header declares %zu codes, kSpecValidationAllCodes lists %zu (or out of order)\n",
                 declared.size(), listed.size());
    return 1;
  }
  std::printf("spec_validation_all_codes_test: %zu codes, all listed in order\n", declared.size());
  return 0;
}
