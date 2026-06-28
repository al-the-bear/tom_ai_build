/* spec_document_yaml — generic YAML codec for the native `*.docspecs.yaml`
 * document format, a faithful port of the Rust `spec_document_yaml.rs`.
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
 * Note (C-port deviation): the Rust struct also exposes the parsed `review:`
 * pass; the runtime is review-agnostic and nothing in the conformance contract
 * reads it, so the C decoder drops it rather than deep-cloning a YAML subtree.
 */
#ifndef SPEC_DOCUMENT_YAML_H
#define SPEC_DOCUMENT_YAML_H

#include "spec_document.h"

/* The on-disk format version (independent of the model-version stamp). */
#define SPEC_YAML_FORMAT_VERSION 1

typedef struct {
  DocumentJson document;
  char *model_version; /* owned; "" when absent */
} SpecYamlContents;

void spec_yaml_contents_free(SpecYamlContents *c);

/* Serializes `document` to header + version (+ modelVersion) + document pass.
 * Owned result. */
char *encode_yaml(const SpecDocument *document, const char *model_version);

/* Parses a `*.docspecs.yaml` document into its passes, writing `*out` (its
 * members owned by the caller, freed via spec_yaml_contents_free). A missing
 * pass decodes as empty rather than failing. */
void decode_yaml(const char *yaml_text, SpecYamlContents *out);

#endif /* SPEC_DOCUMENT_YAML_H */
