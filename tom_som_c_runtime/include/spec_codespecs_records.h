/* spec_codespecs_records — reading back what a Phase-4 run wrote: the per-area
 * **extract** files and the Stage-B **gate record** (`codespecs_mapping.md`
 * §1.1.1, `codespecs_prompt.md` §6.3), a faithful port of the Dart
 * `spec_codespecs_records.dart`.
 *
 * The extractor (`CodeSpecsExtractor`) writes `<CE-CODE>.extract.yaml`; this
 * module is the other half, so a consumer that did not run the extractor — a
 * validator, an editor tool, an agent asking which areas are in scope — reads
 * the files with the same rules everywhere instead of re-deriving the shape. The
 * gate record has a writer here too, because it is otherwise written by hand and
 * only checked when something reads it.
 *
 * Both readers **refuse** an unknown `formatVersion`: a later format that moved
 * a key would otherwise read as an extract with no entries, or a scope with no
 * verdicts, and a check with no input passes.
 *
 * YAML is read with the runtime's own `yaml` reader (the docspecs load path). It
 * is a reader for the constrained subset the writers emit, so two things are
 * handled here rather than by it: a non-empty flow list (`["a", "b"]`,
 * `[5, 6]`) — which the extract writer emits as JSON, so it is decoded as JSON —
 * and YAML's typing of plain scalars (`null` / `~` read as null, `true` /
 * `false` and plain floats as non-strings). A key written with no value at all
 * (`key:`) reads as null, as YAML says.
 *
 * Error idiom: C has no exceptions, so where the Dart reference throws
 * `CodeSpecsRecordError` this fills a caller-owned `CodeSpecsRecordError` whose
 * `failed == 0` state is the stand-in for "did not throw" — the shape
 * `CodeSpecsExtractError` uses — and returns 1/0 alongside it. The message is
 * the Dart message, character for character. `err` may be NULL.
 *
 * Ownership: every struct a function here fills is owned by the caller and
 * released with its `*_free`; every `char *` returned is owned by the caller
 * (`free`). Functions returning `const` pointers borrow from their argument.
 */
#ifndef SPEC_CODESPECS_RECORDS_H
#define SPEC_CODESPECS_RECORDS_H

#include <stddef.h>

#include "som_util.h"
#include "spec_codespecs_extract.h"

/* The file name of the gate record, written beside the extracts.
 *
 * Fixed so a partial pass cannot hide its record under a name no reader looks
 * for. */
#define SPEC_CODESPECS_GATE_RECORD_FILE "gate.verdicts.yaml"

/* The gate record `formatVersion` this runtime reads and writes. */
#define SPEC_CODESPECS_GATE_RECORD_FORMAT 1

/* The suffix every extract artifact of record carries. */
#define SPEC_CODESPECS_EXTRACT_FILE_SUFFIX ".extract.yaml"

/* The one resolution a gate record may carry: an insufficient area the user
 * decided to leave out. */
#define SPEC_CODESPECS_GATE_DESCOPED "descoped"

/* ---- the error ----------------------------------------------------------- */

/* A malformed or unreadable extract file or gate record. Owns its message;
 * initialise with `spec_codespecs_record_error_init`, release with
 * `spec_codespecs_record_error_free`. */
typedef struct {
  /* 0 when the read succeeded — the C stand-in for "no exception was thrown". */
  int failed;
  /* What is wrong, naming the file it was read from. NULL when not failed. */
  char *message;
} CodeSpecsRecordError;

/* Resets `*e` to the no-failure state (does not free). */
void spec_codespecs_record_error_init(CodeSpecsRecordError *e);
/* Frees the message of `*e` and resets it. */
void spec_codespecs_record_error_free(CodeSpecsRecordError *e);
/* Reports whether `e` records no failure (NULL counts as no failure). */
int spec_codespecs_record_error_is_ok(const CodeSpecsRecordError *e);
/* `CodeSpecsRecordError: <message>` — the Dart `toString`. Owned result. */
char *spec_codespecs_record_error_string(const CodeSpecsRecordError *e);

/* ---- extract files ------------------------------------------------------- */

/* Parses one `<CE-CODE>.extract.yaml` into `*out` — the inverse of
 * `spec_codespecs_extract_to_yaml`, the Dart `CodeSpecsExtract.fromYaml`.
 * `source` names the file in errors (NULL or "" reads as "the extract").
 *
 * Only `extract.formatVersion` (== SPEC_CODESPECS_EXTRACT_FORMAT) and a
 * non-empty `extract.area.code` are required; any other absent key reads as
 * empty (a string as "", a list as empty, the optional entry fields `headline`,
 * `instanceId`, `formField`, `routingNote` as NULL). A key present with the
 * wrong type is an error, and so is a `document.entryCount` that disagrees with
 * the entries. `area.part` loses a leading `CodeSpecPart.` prefix.
 *
 * The extract owns its area (`owned_area`, which `area` points at). For any
 * extract the extractor wrote, reading it and writing it again is byte-identical.
 *
 * Returns 1 on success. Returns 0 — leaving `*out` zeroed — with `*err` filled
 * on a malformed file. Release `*out` with `spec_codespecs_extract_free`. */
int spec_codespecs_extract_from_yaml(const char *text, const char *source,
                                     CodeSpecsExtract *out,
                                     CodeSpecsRecordError *err);

/* ---- the gate record ----------------------------------------------------- */

/* One of `codespecs_prompt.md` §6.2's three per-area verdicts. */
typedef enum {
  /* The extract carries every input the derivation contract requires. */
  CODESPECS_GATE_SUFFICIENT = 0,
  /* The area does not apply — nothing was routed, with positive evidence of
   * absence (`codespecs_prompt.md` §6.4). */
  CODESPECS_GATE_NOT_APPLICABLE = 1,
  /* The extract is missing required inputs; only a recorded descope lets a run
   * continue without the area. */
  CODESPECS_GATE_INSUFFICIENT = 2,
} CodeSpecsGateVerdict;

/* The verdict word exactly as `codespecs_prompt.md` §6.2 states it —
 * `sufficient`, `not applicable`, `insufficient`. A static literal. */
const char *spec_codespecs_gate_verdict_word(CodeSpecsGateVerdict v);

/* Writes the verdict for `word` to `*out` and returns 1, or returns 0 for a word
 * §6.2 does not know (the Dart `parse` returning null). */
int spec_codespecs_gate_verdict_parse(const char *word,
                                      CodeSpecsGateVerdict *out);

/* One gap line of an insufficient area (`codespecs_prompt.md` §6.3): a missing
 * input, and the section field that should have carried it.
 *
 * Stage C creates one L0 `csopen` todo per gap line, so two sections missing
 * the same field are two gaps — which is why the record carries them as data
 * rather than leaving them in the note. Owns its strings; shape is checked by
 * the gate record. */
typedef struct {
  /* The section whose content is missing the input. */
  char *section_id;
  /* What the derivation contract required, in one line. */
  char *required;
  /* `<section-id>.<field>` — the field that should have carried it. */
  char *carrier;
} CodeSpecsGateGap;

/* The gap as the §6.3 output line, without its indentation:
 * `<sectionId> — <required> — should have been carried by <carrier>`. Owned
 * result. */
char *spec_codespecs_gate_gap_line(const CodeSpecsGateGap *g);
/* Frees the owned members of `*g`. Safe on a zeroed struct. */
void spec_codespecs_gate_gap_free(CodeSpecsGateGap *g);

/* One area's recorded verdict. Owns its strings and its gaps. */
typedef struct {
  /* The area's `CE-*` code. */
  char *area;
  /* The verdict. */
  CodeSpecsGateVerdict verdict;
  /* `descoped`, on an insufficient area only; otherwise NULL. */
  char *resolution;
  /* A free-text note — why the verdict was taken. Never read as data. NULL when
   * there is none. */
  char *note;
  /* The gap lines of an insufficient area, in the order Stage B found them;
   * empty (NULL, 0) for every other verdict, and for an insufficient area
   * recorded before its gaps were. Owned by the entry, freed with it. */
  CodeSpecsGateGap *gaps;
  size_t gaps_len;
} CodeSpecsGateEntry;

/* Whether this is an insufficient area resolved by descoping. */
int spec_codespecs_gate_entry_descoped(const CodeSpecsGateEntry *e);
/* Frees the owned members of `*e`. Safe on a zeroed struct. */
void spec_codespecs_gate_entry_free(CodeSpecsGateEntry *e);

/* The Stage-B gate record, `gate.verdicts.yaml` (`codespecs_prompt.md` §6.3).
 *
 * Every function that produces one checks it: every area is a `CE-*` code named
 * once, and a `resolution:` appears only as `descoped` on an insufficient area.
 * So a record that exists is a record of the checked shape, whether it was read
 * or built to be written. Owns its entries. */
typedef struct {
  /* The verdicts, in the order they were recorded. */
  CodeSpecsGateEntry *verdicts;
  size_t verdicts_len;
} CodeSpecsGateRecord;

/* Builds and checks a record from `len` entries (copied — the caller keeps
 * `verdicts`) into `*out` — the Dart constructor. `source` names it in errors
 * (NULL: SPEC_CODESPECS_GATE_RECORD_FILE). Returns 0 — `*out` empty — with
 * `*err` filled on a shape §6.3 does not allow. */
int spec_codespecs_gate_record_make(const CodeSpecsGateEntry *verdicts,
                                    size_t len, const char *source,
                                    CodeSpecsGateRecord *out,
                                    CodeSpecsRecordError *err);

/* Parses `gate.verdicts.yaml` into `*out`. `source` names the file in errors
 * (NULL: SPEC_CODESPECS_GATE_RECORD_FILE). Rejects an unknown key at gate and at
 * entry level and a `formatVersion` other than SPEC_CODESPECS_GATE_RECORD_FORMAT.
 * Returns 0 — `*out` empty — with `*err` filled on failure. */
int spec_codespecs_gate_record_from_yaml(const char *text, const char *source,
                                         CodeSpecsGateRecord *out,
                                         CodeSpecsRecordError *err);

/* Frees the entries of `*r` and resets it. Safe on a zeroed struct. */
void spec_codespecs_gate_record_free(CodeSpecsGateRecord *r);

/* The entry for `area`, or NULL when the record says nothing about it.
 * Borrowed. */
const CodeSpecsGateEntry *
spec_codespecs_gate_record_verdict_for(const CodeSpecsGateRecord *r,
                                       const char *area);

/* Returns 0 with `*err` filled when an area is not an active area of `catalog` —
 * a verdict for an area that does not exist scopes nothing. `source` names the
 * record (NULL: SPEC_CODESPECS_GATE_RECORD_FILE). */
int spec_codespecs_gate_record_check_against(const CodeSpecsGateRecord *r,
                                             const CodeSpecsAreaCatalog *catalog,
                                             const char *source,
                                             CodeSpecsRecordError *err);

/* A copy of `r` with `entry` recorded — replacing the area's earlier verdict in
 * place, or appended when the area had none — written into `*out` and checked.
 * Returns 0 — `*out` empty — with `*err` filled when the result is not a valid
 * record. */
int spec_codespecs_gate_record_with_verdict(const CodeSpecsGateRecord *r,
                                            const CodeSpecsGateEntry *entry,
                                            CodeSpecsGateRecord *out,
                                            CodeSpecsRecordError *err);

/* The record as `gate.verdicts.yaml`. Byte-stable: the same record always writes
 * the same text, and reading it back writes it again unchanged. `area`,
 * `verdict` and `resolution` are written plain, a note and every gap field as
 * double-quoted scalars (`spec_codespecs_yaml_string`). Owned result. */
char *spec_codespecs_gate_record_to_yaml(const CodeSpecsGateRecord *r);

/* ---- a tree of extracts, scoped by its gate record ----------------------- */

/* One area the gate record left out of scope.
 *
 * Kept visible rather than dropped, so a consumer can say so: a scoped-out area
 * must never read as a covered one. Owns its strings. */
typedef struct {
  /* The `CE-*` code. */
  char *area;
  /* CODESPECS_GATE_NOT_APPLICABLE, or CODESPECS_GATE_INSUFFICIENT with a
   * recorded descope. */
  CodeSpecsGateVerdict verdict;
  /* Whether an insufficient verdict was resolved by descoping. */
  int descoped;
  /* How many routed entries the excluded extract carried (0 with no file). */
  size_t entry_count;
  /* The file the excluded extract was read from, or "" when there was none. */
  char *source;
} CodeSpecsExcludedArea;

/* One input file of `spec_codespecs_extract_set_from_files`: its name (a path;
 * the basename decides whether it is the gate record) and its text. Borrowed. */
typedef struct {
  const char *name;
  const char *text;
} CodeSpecsRecordFile;

/* Every extract one run produced, read back and scoped by its gate record. */
typedef struct {
  /* The in-scope extracts. With a gate record: the areas it marks
   * `sufficient`, in the record's order. Without: every extract, in source
   * order. Each owns its area. */
  CodeSpecsExtractList extracts;
  /* The file each in-scope extract was read from, parallel to `extracts`. */
  SomStrList sources;
  /* The areas the gate record excluded — empty without a record. */
  CodeSpecsExcludedArea *excluded;
  size_t excluded_len;
  /* 1 when a gate record was among the sources; `gate` is then that record. */
  int has_gate;
  CodeSpecsGateRecord gate;
} CodeSpecsExtractSet;

/* Reads `n` files — in the order given — into a scoped set in `*out`.
 *
 * The file whose basename is SPEC_CODESPECS_GATE_RECORD_FILE is the gate
 * record; every other file is an extract. The area code comes from the file's
 * content, never its name. With a record, an area is in scope **iff** its
 * verdict is `sufficient`, and:
 *
 *   - the record must carry a verdict for every extract supplied — a scope
 *     silent about an area would let a skipped area read as a passed one;
 *   - a `not applicable` area whose extract has entries is an error — a routed
 *     value is evidence the area applies (`codespecs_prompt.md` §6.4);
 *   - an `insufficient` area without `resolution: descoped` is an error — the
 *     run may not have continued past it (`codespecs_prompt.md` §6.2).
 *
 * Two extracts for one area, or two gate records, are errors. Returns 0 —
 * `*out` empty — with `*err` filled on any of them. Release `*out` with
 * `spec_codespecs_extract_set_free`. */
int spec_codespecs_extract_set_from_files(const CodeSpecsRecordFile *files,
                                          size_t n, CodeSpecsExtractSet *out,
                                          CodeSpecsRecordError *err);

/* Reads a directory of extracts — `<CE-CODE>.extract.yaml` plus an optional
 * `gate.verdicts.yaml`; other files (the `.extract.md` views) are ignored. Files
 * are read in name order (byte order), so the set is the same on every file
 * system. A missing directory or an unreadable file is an error. */
int spec_codespecs_extract_set_from_directory(const char *path,
                                              CodeSpecsExtractSet *out,
                                              CodeSpecsRecordError *err);

/* Frees everything `*s` owns and resets it. Safe on a zeroed struct. */
void spec_codespecs_extract_set_free(CodeSpecsExtractSet *s);

/* The in-scope extract for `area`, or NULL. Borrowed. */
const CodeSpecsExtract *
spec_codespecs_extract_set_by_area(const CodeSpecsExtractSet *s,
                                   const char *area);

/* Every in-scope entry routed from `section_id` — the back-link token a
 * `DocRef` names — across every area, in extract order. Writes an owned array of
 * **borrowed** entry pointers to `*out` (release the array with `free`, never
 * the entries) and returns its length; `*out` is NULL when there are none. */
size_t spec_codespecs_extract_set_entries_for_section(
    const CodeSpecsExtractSet *s, const char *section_id,
    const CodeSpecsExtractEntry ***out);

/* Every in-scope entry read from document `path`, in extract order. Same
 * ownership as `spec_codespecs_extract_set_entries_for_section`. */
size_t spec_codespecs_extract_set_entries_at_path(
    const CodeSpecsExtractSet *s, const char *path,
    const CodeSpecsExtractEntry ***out);

#endif /* SPEC_CODESPECS_RECORDS_H */
