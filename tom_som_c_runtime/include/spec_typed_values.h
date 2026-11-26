/* spec_typed_values — shared typed-value conversion at the store boundary
 * (YRD7), a faithful port of the Dart `spec_typed_values.dart` and the Python
 * `spec_typed_values.py`.
 *
 * A `SpecDocument`'s stores hold **plain strings** — that is what the md/yaml
 * serialization writes (`FieldName: value`) and what keeps every language
 * runtime's persistence identical. Typed access therefore converts *at the
 * boundary*: parse on read, format on write. These helpers are that single
 * boundary — a generated typed facade and the generic `SpecEditor` call the
 * **same** functions, so a facade is provably a thin layer over the generic API
 * (they cannot disagree on a conversion).
 *
 * Conventions (the typed contract, mirrored by all nine runtimes):
 *   - absent / empty string => "no value" on read; no value on write => clear
 *     (D4, so the key is REMOVED rather than stored as "");
 *   - numbers follow the canonical reading (decision tspubnondart20 (a), the
 *     TypeScript `spec_typed_values.ts`): the text is read with surrounding
 *     whitespace trimmed; NaN, Infinity, hexadecimal, digit separators and
 *     anything else are refused, because a spec value is finite;
 *   - `int` — `^[+-]?[0-9]+$`; the raw parser answers "no value" for any
 *     other text, but the editor's typed reads fail on it
 *     (`som_typed_text_readable`);
 *   - `double` — `^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`
 *     (also plain integers); formatting is the shortest round-trip digits and
 *     always carries a fraction or an exponent, so an integral value
 *     round-trips as `2.0` rather than `2` (Dart's `double.toString`);
 *   - `num` — an integral literal keeps the narrower int shape, otherwise
 *     double (Dart's `num.tryParse`);
 *   - `bool` — stored as `true` / `false` (lower case, language-neutral);
 *     parsing accepts exactly those, anything else reads as no value;
 *   - enums — stored as the constant **name** (e.g. `high`); the generic layer
 *     validates against the field's `enum_values` domain, a generated facade
 *     converts name <-> native constant;
 *   - a typed value holding inline marks (SOM §11.9.3, a change under
 *     review: `{~~ 30 ~> 15 ~~}`) reads as its **old** value, every mark
 *     rejected, until the marks are decided (`som_typed_reading`).
 *
 * Ownership: every `som_format_*` returns a fresh owned string (free with
 * `free`); a `SomValue` owns its `str` (free with `som_value_free`).
 */
#ifndef SPEC_TYPED_VALUES_H
#define SPEC_TYPED_VALUES_H

#include "som_util.h"

/* ---- SomValue — the tagged value the typed boundary carries ------------- */

/* C has no dynamic `Object?`, so the typed positions of the generic editing API
 * travel as an explicitly tagged value. Collapsing them into a string would
 * lose exactly the distinctions the typed contract rests on: the integer `2`
 * from the string `"2"`, `true` from `"not-a-bool"`. */
typedef enum {
  /* No value — the read side's "unset" and the write side's "clear" (D4). */
  SOM_VALUE_NONE = 0,
  SOM_VALUE_STR,
  SOM_VALUE_INT,
  SOM_VALUE_DOUBLE,
  SOM_VALUE_BOOL
} SomValueKind;

typedef struct {
  SomValueKind kind;
  char *str;         /* owned; populated only for SOM_VALUE_STR */
  long long integer; /* SOM_VALUE_INT */
  double real;       /* SOM_VALUE_DOUBLE */
  int boolean;       /* SOM_VALUE_BOOL (0/1) */
} SomValue;

/* Constructors — return a value the caller owns (release with
 * `som_value_free`, which is a no-op for every kind but SOM_VALUE_STR). */
SomValue som_value_none(void);
SomValue som_value_str(const char *s); /* copies `s`; NULL yields NONE */
SomValue som_value_int(long long v);
SomValue som_value_double(double v);
SomValue som_value_bool(int v);

/* Frees the owned string (when any) and resets `*v` to NONE. */
void som_value_free(SomValue *v);

/* Structural equality: same kind and same payload (strcmp for strings). */
int som_value_equals(const SomValue *a, const SomValue *b);

/* A short human-readable rendering for diagnostics ("none", "int 3",
 * "str \"high\"", ...). Owned result. */
char *som_value_debug(const SomValue *v);

/* ---- typed values under review (SOM §11.9.3) ---------------------------- */

/* The reading of a typed value under review: `raw` with every inline mark
 * rejected (its old value), trimmed; `raw` itself when it holds no mark.
 *
 * A typed value marked as a change (`{~~ 30 ~> 15 ~~}`) is the old value until
 * the change is accepted: the parsers below, the validator and every typed
 * read see that value, never the markup. Owned result; NULL for a NULL `raw`. */
char *som_typed_reading(const char *raw);

/* Whether a form field holds a typed value: an enum (`enum_values` not empty),
 * or `int`, `double`, `num` or `bool` — the values that read as their old
 * value while marked. `enum_values` may be NULL. */
int som_is_typed_field(const char *type_name, const SomStrList *enum_values);

/* ---- the ten boundary helpers ------------------------------------------- */

/* Parses a stored string as `int` (whitespace trimmed, `^[+-]?[0-9]+$`).
 * Returns 1 and writes `*out` on success; 0 (leaving `*out` untouched) when
 * absent/empty/unparsable — reads are forgiving. */
int som_parse_int(const char *raw, long long *out);

/* Formats an `int` for the store. Owned result. */
char *som_format_int(long long value);

/* Parses a stored string as `double` (whitespace trimmed, a decimal or
 * exponent literal; NaN, Infinity, hex and a literal overflowing to infinity are
 * refused). Returns 1 and writes
 * `*out` on success; 0 when absent/empty/unparsable. */
int som_parse_double(const char *raw, double *out);

/* Formats a `double` for the store, shortest round-trip and **always with a
 * fraction or an exponent** (`2.0`, never `2`; `1000.0`; `1e+21`) so an integral double is distinguishable
 * from an int in the language-neutral store. Owned result. */
char *som_format_double(double value);

/* Parses a stored string as `num` — SOM_VALUE_INT for an integral literal,
 * else SOM_VALUE_DOUBLE. Returns 1 and writes `*out` on success; 0 when
 * absent/empty/unparsable. */
int som_parse_num(const char *raw, SomValue *out);

/* Formats a `num` (an INT or DOUBLE `SomValue`) for the store; any other kind
 * formats as "" (clear, D4). Owned result. */
char *som_format_num(const SomValue *value);

/* Parses a stored string as `bool` — exactly `true`/`false`. Returns 1 and
 * writes `*out` (0/1) on success; 0 for anything else. */
int som_parse_bool(const char *raw, int *out);

/* Formats a `bool` for the store (`true` / `false`). Owned result. */
char *som_format_bool(int value);

/* Parses a stored string as an enum constant name against `values` (the
 * field's `enum_values` domain). Returns 1 and writes an owned copy to `*out`
 * when `raw` is in the domain; returns 0 otherwise — a stale/foreign name reads
 * as unset rather than failing, the same forgiveness the other parsers extend
 * to malformed numbers. */
int som_parse_enum_name(const char *raw, const SomStrList *values, char **out);

/* Validates an enum constant `name` against `values` before storing.
 *
 * NULL/empty clears (returns an owned ""); a name outside the domain returns
 * NULL and, when `err` is non-NULL, writes an owned message — writes are strict
 * where reads are forgiving, so a typo cannot enter the store. */
char *som_format_enum_name(const char *name, const SomStrList *values,
                           char **err);

/* ---- typed-text readability (valueTypeMismatch) ------------------------ */

/* The scalar base of a declared field type: `int?` -> `int`. Returns an owned
 * copy (free with `free`), or NULL when `type_name` is NULL. */
char *som_scalar_base(const char *type_name);

/* Whether `raw`, stored in a field declared as `type_name`, is text that
 * type's parser can read (1) or not (0).
 *
 * Only `int`, `double`, `num` and `bool` (and their `?` variants) constrain
 * their text; every other type (strings, and enums, whose domain
 * `enumValueUnknown` checks) accepts any text. NULL or empty text is readable:
 * it is how a field is unset. The validator reports a stored value this
 * rejects as `valueTypeMismatch`, the editor's setters refuse to store one,
 * and the typed reads fail on one — so text a typed field cannot read is never
 * silently read as unset. */
int som_typed_text_readable(const char *type_name, const char *raw);

#endif /* SPEC_TYPED_VALUES_H */
