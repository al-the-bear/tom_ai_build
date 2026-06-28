/* spec_document_yaml — generic YAML codec for the native `*.docspecs.yaml`
 * document format, an idiomatic-C++ port of the C `spec_document_yaml` module.
 *
 * A header comment, `version:` (the on-disk format version), an optional
 * `modelVersion:` stamp, then the `document:` pass — the live object-model
 * values, sorted by full section path.
 *
 * All text values are written as literal block scalars (`|2-`) so multi-line
 * content round-trips verbatim. The emitter is self-verifying: it re-parses each
 * block it produces and falls back to a JSON-quoted scalar (always valid YAML)
 * for any value a clean block can't represent.
 *
 * Note (port deviation, inherited from the C reference): the Rust struct also
 * exposes the parsed `review:` pass; the runtime is review-agnostic and nothing
 * in the conformance contract reads it, so the decoder drops it.
 */
#ifndef SPEC_DOCUMENT_YAML_HPP
#define SPEC_DOCUMENT_YAML_HPP

#include <string>

#include "spec_document.hpp"

namespace som {

/* The on-disk format version (independent of the model-version stamp). */
inline constexpr int kSpecYamlFormatVersion = 1;

struct SpecYamlContents {
  DocumentJson document;
  std::string modelVersion;  // "" when absent
};

/* Serializes `document` to header + version (+ modelVersion) + document pass. */
std::string encodeYaml(const SpecDocument& document,
                       const std::string& modelVersion);

/* Parses a `*.docspecs.yaml` document into its passes. A missing pass decodes
 * as empty rather than failing. */
SpecYamlContents decodeYaml(const std::string& yamlText);

}  // namespace som

#endif  // SPEC_DOCUMENT_YAML_HPP
