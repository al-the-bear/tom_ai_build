/* spec_document_yaml — generic YAML codec for the native `*.docspecs.yaml`
 * document format — **hierarchical format v2** (DR1 §2); an idiomatic-C++ port
 * of the C `spec_document_yaml` module (which itself ports the Go / Dart / TS
 * references).
 *
 * One nested YAML tree whose indentation mirrors the document structure: every
 * model node becomes a mapping key (`<section-id> <member-name>`, DR1 §2.2),
 * sections nest their children, list items appear under their container keyed
 * by their stored section id (or an anonymous positional `<member>-<n>` key), a
 * node's own body text uses the literal key `content`, and form fields use
 * their bare field names. The former flat two-level path-map format is
 * **retired**; readers reject `version: 1` files with a clear error (no
 * compatibility path).
 *
 * Text values are written as literal block scalars (`|2-`), with the DR1 §2.4
 * escaping rules: the emitter is **self-verifying** (it re-parses each scalar
 * it produces via the hand-rolled yaml reader and falls back to a double-quoted
 * JSON-escaped flow scalar when the parse differs), and runs of 2+ consecutive
 * empty lines are collapsed to one before serialization (a deliberate,
 * documented lossy normalization). Non-text values (`int` / `double` / `bool`,
 * enum member names) are plain scalars when they self-verify (§2.5).
 *
 * Both `encodeYaml` and `decodeYaml` walk the SomMetaTree of the document root:
 * the file carries **no paths** — the runtime reconstructs them by matching
 * keys against the metadata tree, and a key that matches nothing at its
 * position is a structured load error (no silent skips). Symmetrically,
 * `encodeYaml` errors when the document holds values the tree cannot place.
 *
 * The optional `review:` pass stays opaque to the runtime (`decodeYaml` returns
 * it as a raw mapping for the editor to interpret).
 */
#ifndef SPEC_DOCUMENT_YAML_HPP
#define SPEC_DOCUMENT_YAML_HPP

#include <optional>
#include <string>

#include "spec_document.hpp"
#include "spec_meta.hpp"
#include "yaml.hpp"

namespace som {

/* The on-disk format version (independent of the model-version stamp). Version
 * 2 is the hierarchical tree format; version-1 flat files are rejected on
 * read. */
inline constexpr int kSpecYamlFormatVersion = 2;

/* The decoded passes of a `*.docspecs.yaml` file: the `document:` pass as a
 * populated SpecDocument (its modelVersion already set from the file stamp),
 * the `review:` pass as a raw mapping (the runtime is review-agnostic; an empty
 * map when absent), and the optional authoring model-version stamp. */
struct SpecYamlContents {
  SpecDocument document;
  YamlRef review;            // YAML_MAP; empty map when the pass is absent
  std::string modelVersion;  // "" when absent
};

/* Serializes `document` to a header + `version:` (+ `modelVersion:`) +
 * hierarchical `document:` pass, walking `tree` (the metadata tree of the
 * document's root).
 *
 * Sibling order is the tree's child order (@SerializationOrder), list items
 * follow their stored sequence; emission is sparse. Returns the owned string;
 * when the document holds values `tree` cannot place returns std::nullopt and,
 * when `err` is non-null, writes a structured message — nothing is silently
 * dropped. */
std::optional<std::string> encodeYaml(const SpecDocument& document,
                                      const SomMetaTree& tree,
                                      const std::string& modelVersion,
                                      std::string* err);

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

/* ---- shared scalar machinery (public for the editor's review writer) ---- */

/* Returns the mapping key a metadata node writes (DR1 §2.2): its effective
 * section id, one space, then the exact member name (class name on the document
 * root); just the name when the node carries no id. */
std::string specYamlNodeKey(const SomMetaNode& node);

/* Returns `key` as a plain key when it is YAML-safe by construction (section
 * ids, member names, `<id> <name>` pairs), else a JSON-quoted one. */
std::string specYamlPlainKey(const std::string& key);

/* Collapses runs of two or more consecutive empty lines to a single empty line
 * (DR1 §2.4.3 — the deliberate lossy normalization applied to every text value
 * before serialization). */
std::string specYamlDedupEmptyLines(const std::string& value);

/* Appends `<indent><key>: <scalar>` to `out`, where the scalar is a
 * self-verified block scalar (or a JSON-quoted fallback) and the key is
 * JSON-quoted. Block body lines are re-indented past `keyIndent`. */
void specYamlWriteScalar(std::string& out, std::size_t keyIndent,
                         const std::string& key, const std::string& value);

}  // namespace som

#endif  // SPEC_DOCUMENT_YAML_HPP
