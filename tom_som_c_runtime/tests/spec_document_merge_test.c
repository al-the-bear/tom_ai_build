/* The merge back of one value (SOM §11.10) on text beyond ASCII, and the base
 * read from git — what `strip_merge_cases.json` (run by tests/conformance.c)
 * does not reach. The expectations below were computed with the TypeScript
 * runtime's `mergeStrippedValue` (`toJson`, the conflicts' `reportLines`), so
 * the offsets (`placed.at`, UTF-16 code units) and the excerpts (thirty UTF-16
 * units either side) are held to the reference.
 *
 * Exit status is the number of failed checks (0 = green).
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "som_util.h"
#include "spec_document_merge.h"
#include "spec_document_strip.h"

static int g_failures = 0;

static void check(const char *name, int cond, const char *detail) {
  if (cond) return;
  ++g_failures;
  fprintf(stderr, "FAIL %s%s%s\n", name, detail != NULL ? ": " : "",
          detail != NULL ? detail : "");
}

typedef struct {
  const char *original;
  const char *list; /* "drop" or "unmark" */
  const char *names;
  const char *find, *replace;
  const char *text; /* NULL: conflicts */
  long long restored;
  long placed_at; /* -1: nothing placed */
  const char *placed_removed;
  const char *conflict; /* the one conflict's code, NULL: none */
  const char *lines[5]; /* the conflict's report lines */
  int lines_len;
} Case;

static const Case kCases[] = {
  {"Die Gr\xc3""\xb6""\xc3""\x9f""e ist hoch (-> C2.1).", "drop", "trace", "hoch", "stark gestiegen \xf0""\x9f""\x98""\x80""", "Die Gr\xc3""\xb6""\xc3""\x9f""e ist stark gestiegen \xf0""\x9f""\x98""\x80"" (-> C2.1).", 1, 32, " (-> C2.1)", NULL, {NULL}, 0},
  {"Ein \xf0""\x9f""\x98""\x80"" [schnelles braunes]{.aside} Tier l\xc3""\xa4""uft.", "unmark", "aside", "braunes Tier", "Wesen", NULL, 0, -1, NULL, "crossesBoundary", {"CONFLICT (document) \xe2""\x80""\x94"" an edit crosses the boundary of an unmarked element", "  O: \xc2""\xab""Ein \xf0""\x9f""\x98""\x80"" [schnelles braunes]{.aside} Tier l\xc3""\xa4""uft.\xc2""\xbb""", "  B: \xc2""\xab""Ein \xf0""\x9f""\x98""\x80"" schnelles braunes Tier l\xc3""\xa4""uft.\xc2""\xbb""", "  E: \xc2""\xab""Ein \xf0""\x9f""\x98""\x80"" schnelles Wesen l\xc3""\xa4""uft.\xc2""\xbb""", "  piece: \xc2""\xab""]{.aside}\xc2""\xbb"""}, 5},
  {"\xc3""\x84"" Wort{>>Bemerkung \xc3""\xbc""ber \xc3""\x96""l<<} hier.", "drop", "comments", "Wort", "Begriff", "\xc3""\x84"" Begriff{>>Bemerkung \xc3""\xbc""ber \xc3""\x96""l<<} hier.", 2, -1, NULL, NULL, {NULL}, 0},
  {"Gr\xc3""\xb6""\xc3""\x9f""e [weil \xf0""\x9f""\x98""\x80"" so]{.aside} gilt.\n\nZweiter Absatz.", "drop", "aside", "gilt", "bleibt", "Gr\xc3""\xb6""\xc3""\x9f""e [weil \xf0""\x9f""\x98""\x80"" so]{.aside} bleibt.\n\nZweiter Absatz.", 1, -1, NULL, NULL, {NULL}, 0},
  {"Ein \xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc"" langer Satz mit [schnelles braunes]{.aside} Tier und noch viel mehr Text danach \xc3""\xa4""\xc3""\xb6""\xc3""\xbc"".", "unmark", "aside", "braunes Tier", "Wesen", NULL, 0, -1, NULL, "crossesBoundary", {"CONFLICT (document) \xe2""\x80""\x94"" an edit crosses the boundary of an unmarked element", "  O: \xc2""\xab""er Satz mit [schnelles braunes]{.aside} Tier und noch viel m\xc2""\xbb""", "  B: \xc2""\xab""ger Satz mit schnelles braunes Tier und noch viel mehr Text \xc2""\xbb""", "  E: \xc2""\xab""\xc3""\xa4""\xc3""\xb6""\xc3""\xbc"" langer Satz mit schnelles Wesen und noch viel mehr Text \xc2""\xbb""", "  piece: \xc2""\xab""]{.aside}\xc2""\xbb"""}, 5},
};

static char *replace_first(const char *s, const char *find, const char *rep) {
  const char *at = strstr(s, find);
  if (at == NULL) return som_strdup(s);
  SomBuf b;
  som_buf_init(&b);
  som_buf_putn(&b, s, (size_t)(at - s));
  som_buf_puts(&b, rep);
  som_buf_puts(&b, at + strlen(find));
  return som_buf_take(&b);
}

static void test_values(void) {
  for (size_t i = 0; i < sizeof(kCases) / sizeof(kCases[0]); i++) {
    const Case *c = &kCases[i];
    char tag[64];
    SomStrList names, none;
    som_strlist_init(&names);
    som_strlist_init(&none);
    som_strlist_push_copy(&names, c->names);
    SpecStripOptions o;
    char *err = NULL;
    int drop = strcmp(c->list, "drop") == 0;
    spec_strip_options_from_names(drop ? &names : &none, drop ? &none : &names,
                                  &none, 0, 0, &o, &err);
    free(err);
    SpecStripTextResult st;
    spec_strip_notation_text(c->original, &o, &st);
    char *edited = replace_first(st.text, c->find, c->replace);
    SpecStripValueMerge m;
    spec_merge_stripped_value(c->original, st.text, edited, st.pieces,
                              st.pieces_len, &m);
    snprintf(tag, sizeof(tag), "value %zu: text", i);
    check(tag, (c->text == NULL && m.text == NULL) ||
                   (c->text != NULL && m.text != NULL && strcmp(c->text, m.text) == 0),
          m.text != NULL ? m.text : "null");
    snprintf(tag, sizeof(tag), "value %zu: restored", i);
    check(tag, m.restored == c->restored, NULL);
    snprintf(tag, sizeof(tag), "value %zu: placed", i);
    if (c->placed_at < 0) {
      check(tag, m.placed_len == 0, NULL);
    } else {
      char got[32];
      snprintf(got, sizeof(got), "%zu", m.placed_len > 0 ? m.placed[0].at : 0);
      check(tag, m.placed_len == 1 && (long)m.placed[0].at == c->placed_at &&
                     strcmp(m.placed[0].removed, c->placed_removed) == 0,
            got);
    }
    snprintf(tag, sizeof(tag), "value %zu: conflicts", i);
    if (c->conflict == NULL) {
      check(tag, m.conflicts_len == 0, NULL);
    } else {
      check(tag, m.conflicts_len == 1 && strcmp(m.conflicts[0].code, c->conflict) == 0,
            NULL);
      if (m.conflicts_len == 1) {
        SomStrList lines;
        spec_strip_merge_conflict_report_lines(&m.conflicts[0], &lines);
        snprintf(tag, sizeof(tag), "value %zu: report lines", i);
        check(tag, (int)lines.len == c->lines_len, NULL);
        for (size_t k = 0; k < lines.len && (int)k < c->lines_len; k++) {
          snprintf(tag, sizeof(tag), "value %zu: report line %zu", i, k);
          check(tag, strcmp(lines.items[k], c->lines[k]) == 0, lines.items[k]);
        }
        som_strlist_free(&lines);
      }
    }
    spec_strip_value_merge_free(&m);
    free(edited);
    spec_strip_text_result_free(&st);
    som_strlist_free(&names);
    som_strlist_free(&none);
  }
}

/* The base read from git: the runner runs in the package root, a clone. */
static void test_git_show(void) {
  char *readme = spec_strip_merge_git_show_file("HEAD", "README.md");
  check("git: a committed file is read", readme != NULL && readme[0] == '#',
        readme != NULL ? "unexpected text" : "null");
  free(readme);
  char *nested = spec_strip_merge_git_show_file("HEAD", "src/spec_document_strip.c");
  check("git: a file in a folder is read from its folder",
        nested != NULL && strstr(nested, "spec_document_strip") != NULL, NULL);
  free(nested);
  char *none = spec_strip_merge_git_show_file(
      "0000000000000000000000000000000000000000", "README.md");
  check("git: an unknown commit gives null", none == NULL, none);
  free(none);
  char *missing = spec_strip_merge_git_show_file("HEAD", "no_such_file.md");
  check("git: an unknown file gives null", missing == NULL, missing);
  free(missing);
}

int main(void) {
  test_values();
  test_git_show();
  if (g_failures == 0) printf("spec_document_merge_test: OK\n");
  return g_failures;
}
