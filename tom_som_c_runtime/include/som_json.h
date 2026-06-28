/* som_json — a hand-rolled, dependency-free JSON parser and value model, a
 * faithful port of the Rust `json.rs` (which itself stands in for serde_json).
 *
 * It reads the meta-data file, the conformance corpus fixtures, and the
 * `document:` pass loaded from YAML. Output of the byte-stable `*.docspecs.yaml`
 * scalars is produced by `js_json_string` (spec_document_yaml) via
 * `som_json_encode_str`, so this parser only needs to *read*.
 *
 * Object members keep source order in an array of pairs; callers that need stable
 * ordering sort at use sites (the document stores use the byte-sorted SomMap).
 *
 * Ownership: a parsed value owns its whole subtree; free the root with
 * `som_json_free`.
 */
#ifndef SOM_JSON_H
#define SOM_JSON_H

#include <stddef.h>

typedef enum {
  SOM_JSON_NULL,
  SOM_JSON_BOOL,
  SOM_JSON_INT,
  SOM_JSON_FLOAT,
  SOM_JSON_STR,
  SOM_JSON_ARRAY,
  SOM_JSON_OBJECT
} SomJsonType;

typedef struct SomJson SomJson;

typedef struct {
  char *key;
  SomJson *value;
} SomJsonMember;

struct SomJson {
  SomJsonType type;
  union {
    int boolean;       /* SOM_JSON_BOOL */
    long long integer; /* SOM_JSON_INT */
    double real;       /* SOM_JSON_FLOAT */
    char *str;         /* SOM_JSON_STR (owned) */
    struct {           /* SOM_JSON_ARRAY */
      SomJson **items;
      size_t len;
    } array;
    struct { /* SOM_JSON_OBJECT */
      SomJsonMember *members;
      size_t len;
    } object;
  } as;
};

/* Parses a JSON document. On success returns the owned root (free with
 * som_json_free) and leaves `*err` NULL. On failure returns NULL and, when
 * `err` is non-NULL, writes an owned error message the caller must free. */
SomJson *som_json_parse(const char *text, char **err);

void som_json_free(SomJson *v);

/* Accessors — return NULL / defaults rather than aborting, mirroring the Rust
 * `Option`-returning helpers. */
const SomJson *som_json_get(const SomJson *v, const char *key);
const char *som_json_as_str(const SomJson *v);  /* NULL unless SOM_JSON_STR */
int som_json_as_i64(const SomJson *v, long long *out); /* 1 on Int/integral Float */
int som_json_as_bool(const SomJson *v, int *out);      /* 1 when SOM_JSON_BOOL */
const SomJson *som_json_array_at(const SomJson *v, size_t i);
size_t som_json_array_len(const SomJson *v);

/* Convenience: the string at `key` or "" / the bool at `key` or 0. */
const char *som_json_str_or(const SomJson *v, const char *key);
int som_json_bool_or(const SomJson *v, const char *key);

/* Encodes `s` as a JSON string literal (wrapped in double quotes). Matches
 * JavaScript's JSON.stringify for a string: short escapes for the C0 set,
 * `\u00xx` for the remaining control characters, everything else verbatim.
 * Returns a fresh owned string. */
char *som_json_encode_str(const char *s);

#endif /* SOM_JSON_H */
