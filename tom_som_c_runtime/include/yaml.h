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

/* The parser itself only yields MAP / SEQ / STR / INT. BOOL, NULL and FLOAT
 * are produced by the docspecs codec's typed `review:` pass (where a plain
 * `true` is a boolean) and by `yaml_value_from_json`; they never appear in a
 * `document:` pass. */
typedef enum {
  YAML_MAP,
  YAML_SEQ,
  YAML_STR,
  YAML_INT,
  YAML_BOOL,
  YAML_NULL,
  YAML_FLOAT
} YamlType;

typedef struct YamlValue YamlValue;

typedef struct {
  char *key;
  YamlValue *value;
} YamlMapEntry;

struct YamlValue {
  YamlType type;
  /* 1 for a YAML_STR read from an unquoted flow scalar (`key: ok`), 0 for a
   * JSON-quoted or block scalar. Lets the codec type the `review:` pass the
   * way a YAML core-schema reader does (plain `true` is a boolean, quoted
   * `"true"` and block `|2-` text stay strings). */
  int plain;
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
    int boolean;        /* YAML_BOOL */
    double real;        /* YAML_FLOAT */
  } as;
};

/* Parses `text` into the value model (a map or sequence). Owned result. */
YamlValue *yaml_parse(const char *text);

/* Parses `text`, returning a map (an empty map when not a mapping). */
YamlValue *yaml_parse_map(const char *text);

void yaml_value_free(YamlValue *v);

struct SomJson;

/* Converts a JSON value (som_json) into the YAML value model: objects become
 * insertion-ordered maps, arrays sequences, and null / bool / int / float /
 * string their typed scalars. The way to build a `review:` pass in code.
 * Owned result (NULL for a NULL input). */
YamlValue *yaml_value_from_json(const struct SomJson *v);

/* Returns the value at `key` when `v` is a map, else NULL. */
const YamlValue *yaml_get(const YamlValue *v, const char *key);

/* Returns the string when `v` is a string scalar, else NULL. */
const char *yaml_as_str(const YamlValue *v);

/* Writes the integer to `*out` and returns 1 when `v` is an integer scalar. */
int yaml_as_int(const YamlValue *v, long long *out);

/* Returns the scalar rendered as a string (string verbatim, integer formatted,
 * `true`/`false`, `null`, a float in Dart's `double.toString` form), or ""
 * for non-scalars. Owned result. */
char *yaml_scalar_string(const YamlValue *v);

/* Formats a double the way Dart's `double.toString` does (shortest
 * round-tripping digits; `3.0` for integral values; exponent form `1e+21` /
 * `1e-7` outside [1e-6, 1e21); `NaN`, `Infinity`, `-Infinity`). Owned. */
char *yaml_format_double(double v);

#endif /* YAML_H */
