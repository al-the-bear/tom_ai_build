/* tom_som_cpp_runtime — umbrella header for the generic TomSpecs SOM runtime in
 * idiomatic C++ (C++17, RAII).
 *
 * A faithful, value-free port of `tom_som_c_runtime` (which itself ports the
 * Dart reference): the path-keyed document model, its JSON/YAML/Markdown codecs,
 * reflection over the class graph, validation, and the typed-facade support used
 * by a generated `tom_som_cpp_v0`. Depends only on the C++ standard library.
 *
 * Include this single header to use the whole runtime; the per-module headers
 * may also be included directly.
 */
#ifndef TOM_SOM_CPP_RUNTIME_HPP
#define TOM_SOM_CPP_RUNTIME_HPP

#include "som_util.hpp"
#include "som_json.hpp"
#include "spec_paths.hpp"
#include "spec_model.hpp"
#include "spec_reflection.hpp"
#include "spec_section_id.hpp"
#include "spec_serialization_order.hpp"
#include "spec_meta.hpp"
#include "spec_meta_bridge.hpp"
#include "spec_meta_diff.hpp"
#include "spec_document.hpp"
#include "spec_typed_values.hpp"
#include "spec_editor.hpp"
#include "spec_text_pattern.hpp"
#include "spec_query.hpp"
#include "spec_node_creation.hpp"
#include "spec_validator.hpp"
#include "yaml.hpp"
#include "spec_document_yaml.hpp"
#include "spec_document_markdown.hpp"
#include "docspecs_validator.hpp"
#include "som_facade.hpp"

#endif  // TOM_SOM_CPP_RUNTIME_HPP
