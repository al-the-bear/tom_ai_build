/* SPEC_VALIDATION_ALL_CODES must list every SPEC_VALIDATION_CODE_* define, in
 * declaration order: it is the enumerable vocabulary a constant-based port
 * owes its readers in place of an enum, and a code added without it would be
 * invisible to every tool that enumerates the list. Reads the header the
 * defines live in (run from the package root, as run_tests.sh does). */
#include <stdio.h>
#include <string.h>

#include "spec_validator.h"

int main(void) {
  FILE *f = fopen("include/spec_validator.h", "r");
  if (f == NULL) {
    fprintf(stderr, "FAIL: cannot read include/spec_validator.h\n");
    return 1;
  }
  const char *prefix = "#define SPEC_VALIDATION_CODE_";
  char line[512];
  size_t n = 0;
  int failed = 0;
  while (fgets(line, sizeof line, f) != NULL) {
    if (strncmp(line, prefix, strlen(prefix)) != 0) continue;
    const char *open = strchr(line, '"');
    const char *close = open != NULL ? strchr(open + 1, '"') : NULL;
    if (open == NULL || close == NULL) continue;
    size_t len = (size_t)(close - open - 1);
    if (n >= SPEC_VALIDATION_ALL_CODES_COUNT || strlen(SPEC_VALIDATION_ALL_CODES[n]) != len ||
        strncmp(SPEC_VALIDATION_ALL_CODES[n], open + 1, len) != 0) {
      fprintf(stderr, "FAIL: code %zu is %.*s in the header but %s in the list\n", n, (int)len,
              open + 1, n < SPEC_VALIDATION_ALL_CODES_COUNT ? SPEC_VALIDATION_ALL_CODES[n] : "(none)");
      failed = 1;
    }
    n++;
  }
  fclose(f);
  if (n != SPEC_VALIDATION_ALL_CODES_COUNT) {
    fprintf(stderr, "FAIL: the header declares %zu codes, the list holds %d\n", n,
            SPEC_VALIDATION_ALL_CODES_COUNT);
    failed = 1;
  }
  if (!failed) printf("spec_validation_all_codes_test: %zu codes, all listed in order\n", n);
  return failed;
}
