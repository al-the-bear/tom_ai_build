/* spec_document_yaml — generic YAML codec for the native `*.docspecs.yaml`
 * document format — **hierarchical format v2** (SOM §12); a faithful port of
 * the Go `spec_document_yaml.go` (which itself ports `spec_document_yaml.dart`
 * / `spec_document_yaml.ts`).
 *
 * One nested YAML tree whose indentation mirrors the document structure: every
 * model node becomes a mapping key (`<section-id> <member-name>`, SOM §12.2),
 * sections nest their children, list items appear under their container keyed
 * by their stored section id (or an anonymous positional `<member>-<n>` key),
 * a node's own body text uses the literal key `content`, and form fields use
 * their bare field names. The former flat two-level path-map format
 * (`document: {content: {"A/b": …}}`) is **retired**; readers reject
 * `version: 1` files with a clear error (no compatibility path).
 *
 * Text values are written as literal block scalars (`|2-`), with the SOM §12.4
 * escaping rules: the emitter is **self-verifying** (it re-parses each scalar
 * it produces via the hand-rolled yaml reader and falls back to a
 * double-quoted JSON-escaped flow scalar when the parse differs), and runs of
 * 2+ consecutive empty lines are collapsed to one before serialization (a
 * deliberate, documented lossy normalization). Non-text values (`int` /
 * `double` / `bool`, enum member names) are plain scalars when they
 * self-verify (SOM §12.5). The JSON quoting is byte-for-byte identical to
 * JavaScript's JSON.stringify (`som_json_encode_str`) so output is stable
 * across every language port.
 *
 * Both `encode_yaml` and `decode_yaml` walk the SomMetaTree of the document
 * root: the file carries **no paths** — the runtime reconstructs them by
 * matching keys against the metadata tree, and a key that matches nothing at
 * its position is a structured load error (no silent skips). Symmetrically,
 * `encode_yaml` errors when the document holds values the tree cannot place
 * (nothing is silently dropped).
 *
 * The optional `review:` pass stays opaque to the runtime (`decode_yaml`
 * returns it as a raw mapping for the editor to interpret).
 *
 * Divergences shared with the hand-rolled parser (documented in the JS/TS
 * ports too): a bare `key:` parses as an empty mapping (which counts as an
 * empty scalar at scalar positions), and the parser never yields booleans, so
 * plain-scalar self-verification needs no bool canonicalisation.
 */
#ifndef SPEC_DOCUMENT_YAML_H
#define SPEC_DOCUMENT_YAML_H

#include "som_util.h"
#include "spec_document.h"
#include "spec_meta.h"
#include "yaml.h"

/* The on-disk format version (independent of the model-version stamp).
 * Version 2 is the hierarchical tree format; version-1 flat files are
 * rejected on read. */
#define SPEC_YAML_FORMAT_VERSION 2

/* SpecYamlContents is the decoded passes of a `*.docspecs.yaml` file: the
 * `document:` pass as a populated SpecDocument (its model_version already set
 * from the file stamp), the `review:` pass as a raw mapping (the runtime is
 * review-agnostic; an owned deep clone, an empty map when absent), and the
 * optional authoring model-version stamp. */
typedef struct {
  SpecDocument document;
  YamlValue *review;   /* owned; YAML_MAP, empty when the pass is absent */
  char *model_version; /* owned; "" when absent */
} SpecYamlContents;

void spec_yaml_contents_free(SpecYamlContents *c);

/* Serializes `document` to a header + `version:` (+ `modelVersion:`) +
 * hierarchical `document:` pass, walking `tree` (the metadata tree of the
 * document's root).
 *
 * Sibling order is the tree's child order (@SerializationOrder), list items
 * follow their stored sequence; emission is sparse (only populated subtrees
 * appear). Returns an owned string; when the document holds values `tree`
 * cannot place returns NULL and, when `err` is non-NULL, writes an owned
 * structured message — nothing is silently dropped. */
char *encode_yaml(const SpecDocument *document, const SomMetaTree *tree,
                  const char *model_version, char **err);

/* Parses a `*.docspecs.yaml` file into its passes, matching every `document:`
 * key against `tree`. On success writes `*out` (owned by the caller; release
 * with `spec_yaml_contents_free`) and returns 1.
 *
 * Returns 0 (writing an owned message to `*err` when non-NULL) for a
 * missing/unsupported `version:` (version 1 is rejected explicitly — the flat
 * format has no compatibility path), for any key the metadata tree cannot
 * place, and for malformed value shapes. A missing/empty `document:` pass
 * decodes as an empty document. */
int decode_yaml(const char *yaml_text, const SomMetaTree *tree,
                SpecYamlContents *out, char **err);

/* ---- shared scalar machinery (public for the editor's review writer) ---- */

/* Returns the mapping key a metadata node writes (SOM §12.2): its effective
 * section id, one space, then the exact member name (class name on the
 * document root); just the name when the node carries no id. Owned result. */
char *spec_yaml_node_key(const SomMetaNode *node);

/* Returns `key` as a plain key when it is YAML-safe by construction (section
 * ids, member names, `<id> <name>` pairs), else a JSON-quoted one. Owned. */
char *spec_yaml_plain_key(const char *key);

/* Collapses runs of two or more consecutive empty lines to a single empty
 * line (SOM §12.4 — the deliberate lossy normalization applied to every text
 * value before serialization). Owned result. */
char *spec_yaml_dedup_empty_lines(const char *value);

/* Writes `<indent><key>: <scalar>` into `out`, where the scalar is a
 * self-verified block scalar (or a JSON-quoted fallback) and the key is
 * JSON-quoted. Block body lines are re-indented past `key_indent`. */
void spec_yaml_write_scalar(SomBuf *out, size_t key_indent, const char *key,
                            const char *value);

#endif /* SPEC_DOCUMENT_YAML_H */
