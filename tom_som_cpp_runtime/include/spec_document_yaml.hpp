/* spec_document_yaml — generic YAML codec for the native `*.docspecs.yaml`
 * document format — **hierarchical format v2** (SOM §12); an idiomatic-C++ port
 * of the C `spec_document_yaml` module (which itself ports the Go / Dart / TS
 * references).
 *
 * One nested YAML tree whose indentation mirrors the document structure: every
 * model node becomes a mapping key (`<section-id> <member-name>`, SOM §12.2),
 * sections nest their children, list items appear under their container keyed
 * by their stored section id (or an anonymous positional `<member>-<n>` key), a
 * node's own body text uses the literal key `content`, and form fields use
 * their bare field names. A `@Form` node's mapping carries its own preamble
 * text — the free text before its first field (SOM §11.4 rule 7) — under that
 * same literal `content` key, so a form section stores its body exactly as
 * every other section does. The former flat two-level path-map format is
 * **retired**; readers reject `version: 1` files with a clear error (no
 * compatibility path).
 *
 * Text values are written as literal block scalars (`|2-`), with the SOM §12.4
 * escaping rules: the emitter is **self-verifying** (it re-parses each scalar
 * it produces via the hand-rolled yaml reader and falls back to a double-quoted
 * JSON-escaped flow scalar when the parse differs), and runs of 2+ consecutive
 * empty lines are collapsed to one before serialization (a deliberate,
 * documented lossy normalization). Non-text values (`int` / `double` / `bool`,
 * enum member names) are plain scalars when they self-verify (SOM §12.5).
 *
 * Both `encodeYaml` and `decodeYaml` walk the SomMetaTree of the document root:
 * the file carries **no paths** — the runtime reconstructs them by matching
 * keys against the metadata tree, and a key that matches nothing at its
 * position is a structured load error (no silent skips). Symmetrically,
 * `encodeYaml` errors when the document holds values the tree cannot place.
 *
 * The optional `review:` pass is carried by the runtime uninterpreted, read and written back (`decodeYaml` returns
 * it as a raw mapping for the editor to interpret).
 */
#ifndef SPEC_DOCUMENT_YAML_HPP
#define SPEC_DOCUMENT_YAML_HPP

#include <optional>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_meta.hpp"
#include "spec_model.hpp"
#include "yaml.hpp"

namespace som {

/* The on-disk format version (independent of the model-version stamp). Version
 * 2 is the hierarchical tree format; version-1 flat files are rejected on
 * read. */
inline constexpr int kSpecYamlFormatVersion = 2;

/* The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
 * populated SpecDocument (its modelVersion already set from the file stamp),
 * the `review:` pass as a raw mapping (the runtime carries it uninterpreted and writes it back; a null
 * pointer when the file has no `review:` key), and the optional authoring
 * model-version stamp. */
struct SpecYamlContents {
  SpecDocument document;
  YamlRef review;            // nullptr when the file has no `review:` key,
                             // otherwise a YAML_MAP — empty for an explicit
                             // `review: {}` or a bare `review:` — so passing
                             // `review.get()` straight back to encodeYaml
                             // reproduces the file either way (SOM §12.1). A
                             // caller of specYamlStaleReviewPaths /
                             // specYamlRekeyReview treats nullptr as an empty
                             // map. Its plain scalars keep their source text;
                             // the writer types them (SOM §12.5).
  std::string modelVersion;  // "" when absent
};

/* Serializes `document` to a header + `version:` (+ `modelVersion:`) +
 * hierarchical `document:` pass, walking `tree` (the metadata tree of the
 * document's root).
 *
 * Sibling order is the tree's child order (@SerializationOrder), list items
 * follow their stored sequence; emission is sparse. A document with no values
 * still writes its root key, as `document:` + `  <root key>: {}` — never
 * `document: {}` — because the root key is the file's only record of which
 * document root it is (SOM §12.3 rule 4); decode keeps accepting
 * `document: {}`. Returns the owned string;
 * when the document holds values `tree` cannot place returns std::nullopt and,
 * when `err` is non-null, writes a structured message — nothing is silently
 * dropped.
 *
 * `review`, when non-null, is written back as the `review:` pass after the
 * document pass — typically the raw map `decodeYaml` returned, so that a load
 * followed by a save keeps a reviewed document's review state. The runtime does
 * not interpret it (specYamlWriteReviewPass); with nullptr the file carries no
 * `review:` pass. */
std::optional<std::string> encodeYaml(const SpecDocument& document,
                                      const SomMetaTree& tree,
                                      const std::string& modelVersion,
                                      std::string* err,
                                      const YamlValue* review = nullptr);

/* Appends `review` (a YAML_MAP) as the `review:` pass, passed through without
 * interpretation: entries sorted by path (byte order, JSON-quoted keys), each
 * entry's fields sorted by name. Sorting rather than keeping the map's order
 * makes the output the same in every port and keeps decode followed by encode
 * byte-identical. Plain scalars are typed by the YAML 1.2 core schema
 * (SOM §12.5) — quoted and block scalars are always strings: `~` / `null` /
 * `Null` / `NULL` and an empty value (`key:`) → null;
 * `true|True|TRUE|false|False|FALSE` → bool; `[-+]?[0-9]+`, `0o[0-7]+`,
 * `0x[0-9a-fA-F]+` → int, a value outside the signed 64-bit range → float
 * (never saturated); `[-+]?(.[0-9]+|[0-9]+(.[0-9]*)?)([eE][-+]?[0-9]+)?`,
 * `[-+]?.inf` and `.nan` (three case forms each) → float; a plain JSON flow
 * collection → that collection; anything else a string. Each is written in
 * canonical form: `null`, `true` / `false`, ints in decimal, floats as
 * `.nan` / `.inf` / `-.inf` or the shortest round-tripping digits in
 * JavaScript's Number toString layout with `.0` appended to a whole
 * fixed-notation value (`3.0`, `1e+300`, `1e-7`); booleans, numbers and
 * identifier-like strings (not a YAML keyword such as `yes` or `null`) are
 * written plain, any other string as a self-verified block scalar, a nested map
 * one level deeper, a list as a JSON flow sequence. An empty map writes
 * `review: {}`. */
void specYamlWriteReviewPass(std::string& out, const YamlValue& review);

/* The review paths (keys of `review`) that no longer resolve against
 * `document`: paths `model` cannot resolve, and paths running through a list
 * item the document does not hold (an item that was removed). Sorted. Reports
 * only — it never edits `review` — so a consumer that removed a list item can
 * tell its user which review entries it left behind. */
std::vector<std::string> specYamlStaleReviewPaths(const SpecModel& model,
                                                  const SpecDocument& document,
                                                  const YamlValue& review);

/* `review` with every path a list-item move renamed (`renamed`, as
 * SpecDocument::moveListItem returns it) re-keyed — the entry for an item and
 * every entry under it (specRekeyPath); entries under no renamed path are kept
 * as they are, in their order (a key two entries re-key to keeps its first
 * place and the later value). A new map (empty for a non-map `review`) sharing
 * the entry values; `review` is not changed. */
YamlPtr specYamlRekeyReview(const YamlValue& review,
                            const SpecPathPairs& renamed);

/* Parses a `*.docspecs.yaml` file into its passes, matching every `document:`
 * key against `tree`. On success writes `*out` and returns true.
 *
 * Returns false (writing a message to `*err` when non-null) for a
 * missing/unsupported `version:` (version 1 is rejected explicitly — the flat
 * format has no compatibility path), for any key the metadata tree cannot
 * place, and for malformed value shapes. A missing/empty `document:` pass
 * decodes as an empty document. */
bool decodeYaml(const std::string& yamlText, const SomMetaTree& tree,
                SpecYamlContents* out, std::string* err);

/* ---- shared scalar machinery (public for the review-pass writer) ---- */

/* Returns the mapping key a metadata node writes (SOM §12.2): its effective
 * section id, one space, then the exact member name (class name on the document
 * root); just the name when the node carries no id. */
std::string specYamlNodeKey(const SomMetaNode& node);

/* Returns `key` as a plain key when it is YAML-safe by construction (section
 * ids, member names, `<id> <name>` pairs), else a JSON-quoted one. */
std::string specYamlPlainKey(const std::string& key);

/* Collapses runs of two or more consecutive empty lines to a single empty line
 * (SOM §12.4 — the deliberate lossy normalization applied to every text value
 * before serialization). */
std::string specYamlDedupEmptyLines(const std::string& value);

/* Appends `<indent><key>: <scalar>` to `out`, where the scalar is a
 * self-verified block scalar (or a JSON-quoted fallback) and the key is
 * JSON-quoted. Block body lines are re-indented past `keyIndent`. */
void specYamlWriteScalar(std::string& out, std::size_t keyIndent,
                         const std::string& key, const std::string& value);

}  // namespace som

#endif  // SPEC_DOCUMENT_YAML_HPP
