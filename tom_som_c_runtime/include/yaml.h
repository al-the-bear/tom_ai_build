/* yaml — a minimal, dependency-free YAML reader for the constrained
 * `*.docspecs.yaml` subset the codec emits, a faithful port of the Rust
 * `yaml.rs`.
 *
 * It supports exactly what the encoder produces (and what the self-verify
 * round-trip probe needs): block mappings, block sequences (`- item`), literal
 * block scalars (`|`, `|-`, `|2`, `|2-` …), JSON-quoted flow scalars, plain
 * integers, and the empty flow collections `{}` / `[]`.
 *
 * The dynamic value model is `YamlValue`: mappings are **insertion-ordered**
 * maps (a mirror of the Go/Rust YamlMap — the hierarchical codec iterates list
 * items in source order), sequences are arrays, scalars are strings or
 * integers. JSON-quoted scalars are
 * parsed via the hand-rolled `som_json` parser.
 *
 * Ownership: a parsed value owns its whole subtree; free the root returned by
 * `yaml_parse` / `yaml_parse_map` with `yaml_value_free`.
 */
#ifndef YAML_H
#define YAML_H

#include <stddef.h>

typedef enum { YAML_MAP, YAML_SEQ, YAML_STR, YAML_INT } YamlType;

typedef struct YamlValue YamlValue;

typedef struct {
  char *key;
  YamlValue *value;
} YamlMapEntry;

struct YamlValue {
  YamlType type;
  union {
    struct {
      YamlMapEntry *entries; /* insertion-ordered */
      size_t len;
      size_t cap;
    } map;
    struct {
      YamlValue **items;
      size_t len;
      size_t cap;
    } seq;
    char *str;          /* YAML_STR (owned) */
    long long integer;  /* YAML_INT */
  } as;
};

/* Parses `text` into the value model (a map or sequence). Owned result. */
YamlValue *yaml_parse(const char *text);

/* Parses `text`, returning a map (an empty map when not a mapping). */
YamlValue *yaml_parse_map(const char *text);

void yaml_value_free(YamlValue *v);

/* Returns the value at `key` when `v` is a map, else NULL. */
const YamlValue *yaml_get(const YamlValue *v, const char *key);

/* Returns the string when `v` is a string scalar, else NULL. */
const char *yaml_as_str(const YamlValue *v);

/* Writes the integer to `*out` and returns 1 when `v` is an integer scalar. */
int yaml_as_int(const YamlValue *v, long long *out);

/* Returns the scalar rendered as a string (string verbatim, integer formatted),
 * or "" for non-scalars. Owned result. */
char *yaml_scalar_string(const YamlValue *v);

#endif /* YAML_H */
