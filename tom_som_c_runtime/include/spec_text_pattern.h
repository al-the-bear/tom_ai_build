/* spec_text_pattern — the **portable text-pattern subset** the `text` dimension
 * of a spec query matches with (`som_multiplatform_spec_model.md` §9), a
 * faithful port of the Dart `spec_text_pattern.dart`.
 *
 * ## Why this exists rather than each language's own regex
 *
 * The query surface reports `matchSpans` — offsets into the matched string —
 * and those spans are part of the nine-language contract. Delegating to each
 * language's regex engine would make that contract unkeepable twice over:
 *
 *   - **Two runtimes have no regex to delegate to.** `tom_som_rust_runtime` is
 *     std-only by charter and *this* runtime is dependency-free; both would need
 *     a hand-rolled matcher regardless. Native-regex-elsewhere therefore does
 *     not remove the work, it only makes there be *two* implementations of the
 *     same semantics instead of one.
 *   - **The engines disagree where it matters.** Go's `regexp` is RE2
 *     (leftmost-longest for alternation), Dart/JS/Java/Python backtrack
 *     (leftmost-first); case folding is Unicode-aware in some and not others.
 *
 * So the matcher is one algorithm, transcribed into all nine runtimes. Equal
 * spans follow from equal code rather than from a hope about two libraries.
 *
 * ## The grammar
 *
 *   pattern   := term*
 *   term      := atom quantifier?
 *   quantifier:= '*' | '+' | '?'          (greedy; no lazy forms)
 *   atom      := '.'                       any character
 *              | '^'                       start-of-text anchor
 *              | '$'                       end-of-text anchor
 *              | '[' '^'? item* ']'        character class
 *              | '\' PUNCT                 the literal PUNCT (non-alphanumeric)
 *              | CHAR                      itself
 *   item      := CHAR | CHAR '-' CHAR      a member or an inclusive range
 *
 * Deliberately **absent**: alternation, groups, backreferences, lazy
 * quantifiers, and the `\d`/`\w`/`\s` shorthands. Absent constructs are handled
 * two different ways, and the line between them is whether a literal reading is
 * plausible: `(`, `)`, `|`, `{`, `}` are ordinary literals (text genuinely
 * contains parentheses), while `\` + an ASCII letter or digit is a compile
 * error — that is exactly where `\d` `\w` `\s` `\b` `\n` `\1` live, and none has
 * a literal reading anyone wants.
 *
 * Anchors bind to the whole text, never to a line.
 *
 * ## Matching semantics
 *
 * Greedy backtracking, leftmost match wins. `spec_text_pattern_all_matches`
 * scans start offsets left to right; a match of length `L > 0` resumes the scan
 * at its end, an empty match advances one character. Case-insensitive matching
 * folds **ASCII only** (`A`–`Z` <-> `a`–`z`).
 *
 * ## Offsets
 *
 * Spans are **UTF-16 code-unit offsets**, matching the Dart reference (whose
 * `String.codeUnits` are UTF-16). Input arrives as UTF-8 `char *` here, so the
 * matcher decodes to UTF-16 internally and matches over that; the reported
 * offsets index the decoded units, not the UTF-8 bytes.
 *
 * Error idiom: `spec_text_pattern_compile` returns 1 on success and 0 on a
 * malformed pattern, filling the caller-owned `SomPatternError` (released with
 * `som_pattern_error_free`) — the typed-error counterpart of `SpecSectionIdError`
 * rather than a bare `char **err`, because a caller has to surface the offending
 * pattern alongside the reason.
 *
 * Ownership: a compiled pattern owns its terms; release it with
 * `spec_text_pattern_free`. A `SpecMatchSpanList` owns its array; release it
 * with `spec_match_span_list_free`.
 */
#ifndef SPEC_TEXT_PATTERN_H
#define SPEC_TEXT_PATTERN_H

#include <stddef.h>

/* A `[start, end)` half-open span within a matched string — the offsets a
 * pattern hit, surfaced on `SpecQueryMatch.spans`. Offsets are UTF-16 code
 * units. */
typedef struct {
  long long start; /* inclusive start offset into the matched string */
  long long end;   /* exclusive end offset into the matched string */
} SpecMatchSpan;

/* An owning, growable span array. */
typedef struct {
  SpecMatchSpan *items;
  size_t len;
  size_t cap;
} SpecMatchSpanList;

void spec_match_span_list_init(SpecMatchSpanList *l);
void spec_match_span_list_push(SpecMatchSpanList *l, long long start,
                               long long end);
void spec_match_span_list_free(SpecMatchSpanList *l);

/* A pattern that is not in the `SomTextPattern` grammar.
 *
 * Reported at *compile* time rather than silently matching nothing, so a caller
 * that mistyped a pattern learns that instead of reading an empty result as
 * "no hits". Owns both strings; release with `som_pattern_error_free`. */
typedef struct {
  char *pattern; /* the offending pattern source */
  char *message; /* what is wrong with it */
} SomPatternError;

/* Resets `*err` with both fields NULL (does not free — free first if the struct
 * already owns strings). */
void som_pattern_error_init(SomPatternError *err);
/* Frees the owned strings and resets to NULL. Safe on a zeroed error. */
void som_pattern_error_free(SomPatternError *err);
/* `SomPatternError("<pattern>"): <message>` — the Dart `toString`. Owned. */
char *som_pattern_error_string(const SomPatternError *err);

/* One compiled atom plus its quantifier; opaque to callers. */
typedef struct SomPatternTerm SomPatternTerm;

/* A compiled pattern over the portable subset described above. Compile once
 * with `spec_text_pattern_compile` (or `spec_text_pattern_literal` for a plain
 * substring) and match with `spec_text_pattern_all_matches`. */
typedef struct {
  SomPatternTerm *terms; /* owned */
  size_t terms_len;
  int case_insensitive;
} SomTextPattern;

/* Compiles `text` as a plain, uninterpreted substring — every character is a
 * literal, including `.` `*` `[` and the rest. Never fails. */
void spec_text_pattern_literal(SomTextPattern *out, const char *text,
                               int case_insensitive);

/* Compiles `source` against the subset grammar. Returns 1 on success (fills
 * `*out`, free with `spec_text_pattern_free`); returns 0 when `source` is not in
 * the grammar — an unterminated or reversed character class, a trailing `\`, a
 * class shorthand escape, or a quantifier with nothing to quantify — filling
 * `*err` when `err` is non-NULL and leaving `*out` untouched. */
int spec_text_pattern_compile(SomTextPattern *out, const char *source,
                              int case_insensitive, SomPatternError *err);

/* Releases a compiled pattern. Safe on a zeroed struct. */
void spec_text_pattern_free(SomTextPattern *p);

/* Every non-overlapping match in the UTF-8 string `text`, left to right,
 * appended to `out` (which the caller initialises and frees). */
void spec_text_pattern_all_matches(const SomTextPattern *p, const char *text,
                                   SpecMatchSpanList *out);

/* Whether `text` contains at least one match. */
int spec_text_pattern_has_match(const SomTextPattern *p, const char *text);

#endif /* SPEC_TEXT_PATTERN_H */
