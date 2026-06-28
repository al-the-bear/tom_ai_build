#include "spec_paths.h"

#include <stdlib.h>
#include <string.h>

char *spec_path_join(const char *parent, const char *segment) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, parent);
  som_buf_puts(&b, SPEC_PATH_SEPARATOR);
  som_buf_puts(&b, segment);
  return som_buf_take(&b);
}

void spec_path_segments(const char *path, SomStrList *out) {
  som_strlist_init(out);
  const char *start = path;
  for (const char *p = path;; p++) {
    if (*p == '/' || *p == '\0') {
      som_strlist_push(out, som_strdup_n(start, (size_t)(p - start)));
      if (*p == '\0') {
        break;
      }
      start = p + 1;
    }
  }
}

char *spec_list_item_path(const char *list_path, long long seq) {
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, list_path);
  som_buf_putc(&b, '-');
  som_buf_puti(&b, seq);
  return som_buf_take(&b);
}

int spec_split_list_item_segment(const char *segment, char **base, long long *seq) {
  size_t n = strlen(segment);
  /* rfind('-') */
  size_t dash;
  int found = 0;
  for (size_t i = n; i > 0; i--) {
    if (segment[i - 1] == '-') {
      dash = i - 1;
      found = 1;
      break;
    }
  }
  if (!found) {
    return 0;
  }
  if (dash == 0 || dash == n - 1) {
    return 0;
  }
  const char *tail = segment + dash + 1;
  if (!som_is_all_digits(tail)) {
    return 0;
  }
  long long v;
  if (!som_parse_i64(tail, &v)) {
    return 0;
  }
  *base = som_strdup_n(segment, dash);
  *seq = v;
  return 1;
}
