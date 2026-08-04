#include "spec_section_id.h"

#include <stdlib.h>
#include <string.h>
#include <time.h>

char *spec_encode_two_letter_date(long long month, long long day) {
  char out[3];
  out[0] = (char)(0x41 + (month - 1));
  if (day <= 26) {
    out[1] = (char)(0x41 + (day - 1));
  } else {
    /* 27 → '0', 28 → '1', … 31 → '4'. */
    out[1] = (char)(0x30 + (day - 27));
  }
  out[2] = '\0';
  return som_strdup(out);
}

char *spec_section_id_pattern_prefix(const char *pattern) {
  size_t i = strlen(pattern);
  while (i > 0 && pattern[i - 1] == 'x') {
    i--;
  }
  return som_strdup_n(pattern, i);
}

char *spec_generate_list_item_section_id(const char *pattern, long long month,
                                         long long day,
                                         const SomStrList *existing_ids) {
  char *prefix = spec_section_id_pattern_prefix(pattern);
  char *date = spec_encode_two_letter_date(month, day);
  SomBuf b;
  som_buf_init(&b);
  som_buf_puts(&b, prefix);
  som_buf_puts(&b, date);
  char *day_prefix = som_buf_take(&b);
  free(prefix);
  free(date);

  size_t day_prefix_len = strlen(day_prefix);
  long long max_for_day = 0;
  for (size_t i = 0; i < existing_ids->len; i++) {
    const char *id = existing_ids->items[i];
    if (id[0] == '\0' || strncmp(id, day_prefix, day_prefix_len) != 0) {
      continue;
    }
    const char *tail = id + day_prefix_len;
    if (tail[0] == '\0' || !som_is_all_digits(tail)) {
      continue;
    }
    long long n;
    if (som_parse_i64(tail, &n) && n > max_for_day) {
      max_for_day = n;
    }
  }

  som_buf_init(&b);
  som_buf_puts(&b, day_prefix);
  som_buf_puti(&b, max_for_day + 1);
  free(day_prefix);
  return som_buf_take(&b);
}

char *spec_effective_list_item_section_id(const char *stored_id,
                                          const char *pattern,
                                          long long position,
                                          const char *fallback_stem) {
  if (stored_id != NULL) {
    return som_strdup(stored_id);
  }
  SomBuf b;
  som_buf_init(&b);
  if (pattern != NULL && pattern[0] != '\0') {
    /* Every `xxx` placeholder is replaced, matching Dart's `replaceAll`. */
    const char *p = pattern;
    const char *xxx;
    while ((xxx = strstr(p, "xxx")) != NULL) {
      som_buf_putn(&b, p, (size_t)(xxx - p));
      som_buf_puti(&b, position);
      p = xxx + 3;
    }
    som_buf_puts(&b, p);
    return som_buf_take(&b);
  }
  som_buf_puts(&b, fallback_stem);
  som_buf_puts(&b, "-");
  som_buf_puti(&b, position);
  return som_buf_take(&b);
}

void spec_today_month_day(long long *month, long long *day) {
  time_t now = time(NULL);
  if (now == (time_t)-1) {
    *month = 1;
    *day = 1;
    return;
  }
  long long days = (long long)now;
  /* floor division by 86400 (now is >= 0, so integer division suffices). */
  days = days / 86400;

  /* Howard Hinnant's civil_from_days (days since 1970-01-01). */
  long long z = days + 719468;
  long long era = (z >= 0 ? z : z - 146096) / 146097;
  long long doe = z - era * 146097;                          /* [0, 146096] */
  long long yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365; /* [0,399] */
  long long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);   /* [0, 365] */
  long long mp = (5 * doy + 2) / 153;                        /* [0, 11] */
  long long d = doy - (153 * mp + 2) / 5 + 1;                /* [1, 31] */
  long long m = mp < 10 ? mp + 3 : mp - 9;                   /* [1, 12] */
  *month = m;
  *day = d;
}

void spec_section_id_error_init(SpecSectionIdError *err) {
  err->kind = SPEC_SECTION_ID_OK;
  err->id = NULL;
  err->list_path = NULL;
  err->item_path = NULL;
}

void spec_section_id_error_free(SpecSectionIdError *err) {
  free(err->id);
  free(err->list_path);
  free(err->item_path);
  spec_section_id_error_init(err);
}

int spec_section_id_is_collision(const SpecSectionIdError *err) {
  return err->kind == SPEC_SECTION_ID_COLLISION;
}
