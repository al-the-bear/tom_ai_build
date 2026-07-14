/* tom_som_c_runtime — umbrella header for the generic TomSpecs SOM runtime in C.
 *
 * A faithful, value-free port of `tom_som_rust_runtime` (which itself ports the
 * Dart reference): the path-keyed document model, its JSON/YAML/Markdown codecs,
 * reflection over the class graph, validation, and the typed-facade support used
 * by a generated `tom_som_c_v0`. Depends only on the C standard library.
 *
 * Include this single header to use the whole runtime; the per-module headers
 * may also be included directly.
 */
#ifndef TOM_SOM_C_RUNTIME_H
#define TOM_SOM_C_RUNTIME_H

#include "som_util.h"
#include "som_json.h"
#include "spec_paths.h"
#include "spec_model.h"
#include "spec_meta.h"
#include "spec_meta_bridge.h"
#include "spec_reflection.h"
#include "spec_section_id.h"
#include "spec_serialization_order.h"
#include "spec_document.h"
#include "spec_validator.h"
#include "yaml.h"
#include "spec_document_yaml.h"
#include "spec_document_markdown.h"
#include "som_facade.h"

#endif /* TOM_SOM_C_RUNTIME_H */
