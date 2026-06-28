/* som_util — foundational building blocks for the C generic runtime:
 * an owning string builder, an owning string list, a byte-sorted string map,
 * and the small string/int helpers the other modules share.
 *
 * The C standard library ships no growable string/collection types, so these
 * stand in for the Vec/String/BTreeMap the Rust reference (tom_som_rust_runtime)
 * leans on. Maps keep keys in strcmp (byte) order so the document codecs are
 * byte-stable across every language port (matching Rust's BTreeMap iteration).
 *
 * Ownership: every container owns the heap memory it holds and frees it in its
 * `*_free`. `som_buf_take` transfers the buffer's bytes to the caller; pushing a
 * char* into a list/map transfers ownership of that char*.
 */
#ifndef SOM_UTIL_H
#define SOM_UTIL_H

#include <stddef.h>

/* ---- C strings ---------------------------------------------------------- */

/* Heap-duplicates a NUL-terminated string (NULL → an empty owned string). */
char *som_strdup(const char *s);

/* Heap-duplicates the first `n` bytes of `s`, NUL-terminating the copy. */
char *som_strdup_n(const char *s, size_t n);

/* Parses a base-10 i64 (optional leading +/-). Returns 1 on success and writes
 * `*out`; returns 0 (and leaves `*out` untouched) for empty/non-digit input. */
int som_parse_i64(const char *s, long long *out);

/* Reports whether `s` is non-empty and composed solely of ASCII digits. */
int som_is_all_digits(const char *s);

/* Formats an i64 as a fresh owned decimal string. */
char *som_format_i64(long long v);

/* ---- string builder ----------------------------------------------------- */

typedef struct {
  char *data;
  size_t len;
  size_t cap;
} SomBuf;

void som_buf_init(SomBuf *b);
void som_buf_putc(SomBuf *b, char c);
void som_buf_puts(SomBuf *b, const char *s);
void som_buf_putn(SomBuf *b, const char *s, size_t n);
void som_buf_puti(SomBuf *b, long long v);
/* Returns the accumulated bytes (NUL-terminated) and resets the buffer to empty,
 * transferring ownership of the returned pointer to the caller. */
char *som_buf_take(SomBuf *b);
void som_buf_free(SomBuf *b);

/* ---- string list (ordered, owning) -------------------------------------- */

typedef struct {
  char **items;
  size_t len;
  size_t cap;
} SomStrList;

void som_strlist_init(SomStrList *l);
/* Takes ownership of the heap string `owned`. */
void som_strlist_push(SomStrList *l, char *owned);
/* Copies `s` and pushes the copy. */
void som_strlist_push_copy(SomStrList *l, const char *s);
/* Reports whether `s` is already present (strcmp equality). */
int som_strlist_contains(const SomStrList *l, const char *s);
/* Removes the element at `index`, shifting the tail down. */
void som_strlist_remove_at(SomStrList *l, size_t index);
/* Deep-copies `src` into `dst` (dst must be uninitialised/empty). */
void som_strlist_copy(SomStrList *dst, const SomStrList *src);
/* Joins with `sep` into a fresh owned string. */
char *som_strlist_join(const SomStrList *l, const char *sep);
void som_strlist_free(SomStrList *l);

/* ---- byte-sorted string map (key → owned string) ------------------------ */

typedef struct {
  char *key;
  char *val;
} SomMapEntry;

typedef struct {
  SomMapEntry *entries;
  size_t len;
  size_t cap;
} SomMap;

void som_map_init(SomMap *m);
/* Inserts or replaces `key`→`val` (both copied), keeping entries strcmp-sorted. */
void som_map_set(SomMap *m, const char *key, const char *val);
/* Returns the value for `key`, or NULL when absent. */
const char *som_map_get(const SomMap *m, const char *key);
/* Removes `key`. Returns 1 when an entry was removed, else 0. */
int som_map_remove(SomMap *m, const char *key);
void som_map_clear(SomMap *m);
void som_map_free(SomMap *m);

#endif /* SOM_UTIL_H */
