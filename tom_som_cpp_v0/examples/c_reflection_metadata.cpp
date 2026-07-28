// Sample (c) — REFLECTION / meta-information access (som_multiplatform_spec_model.md §6).
//
// HAND-AUTHORED — preserved across `generate_som` runs (the generator only
// rewrites the header/source pair (include/, src/), meta/, schemas/ and the
// Makefile).
//
// Demonstrates the value-free "reflection" surface: load the exported meta-data
// (`meta/spec_model.meta.json`, the lossless class graph) into a `som::SpecModel`
// and query its shape with `som::SpecReflection` — enumerate roots and fields,
// and resolve a concrete document *path* to the model node it lands on. No
// document values are involved; this answers "what CAN the model hold?", not
// "what does a given document hold?".
//
// Run from the project root:  ./build/c_reflection_metadata [meta.json]
// The meta-data path defaults to `meta/spec_model.meta.json` (relative to cwd);
// pass an explicit path to run from elsewhere. `run_tests.sh` runs it from the
// project root so the default resolves.
#include "tom_som_cpp_runtime.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

int main(int argc, char** argv) {
  const std::string metaPath =
      argc > 1 ? argv[1] : "meta/spec_model.meta.json";

  std::ifstream in(metaPath, std::ios::binary);
  if (!in) {
    std::cerr << "could not read meta-data at " << metaPath << "\n";
    return 1;
  }
  std::ostringstream buf;
  buf << in.rdbuf();
  const std::string data = buf.str();

  std::string err;
  std::unique_ptr<som::SpecModel> model = som::SpecModel::fromJsonStr(data, &err);
  if (model == nullptr) {
    std::cerr << "parse meta-data failed: " << (err.empty() ? "?" : err) << "\n";
    return 1;
  }

  som::SpecReflection ref(*model);

  const std::string label =
      model->modelVersionLabel.empty() ? "unstamped" : model->modelVersionLabel;
  std::cout << "Model version: " << model->modelVersion << " (" << label
            << ")\n";
  std::cout << "Roots: " << model->roots.size()
            << ", classes: " << model->classesSize() << "\n\n";

  // Enumerate the document roots by their addressable segment.
  std::cout << "Document roots:\n";
  for (const som::SpecRoot& root : model->roots) {
    std::cout << "  " << som::SpecReflection::rootSegment(root) << "  "
              << root.title << "\n";
  }

  // Inspect the fields of the D00SolutionBlueprint root class.
  const som::SpecRoot* pdRoot = ref.rootForSegment("SBP");
  if (pdRoot == nullptr) {
    std::cout << "SBP root not found\n";
    return 1;
  }
  const som::SpecClass* pdCls = model->classNamed(pdRoot->type);
  const std::size_t total = pdCls != nullptr ? pdCls->fields.size() : 0;
  std::cout << "\nFirst fields of " << pdRoot->type << " (" << total
            << " total):\n";
  for (std::size_t i = 0; pdCls != nullptr && i < pdCls->fields.size() && i < 6;
       i++) {
    const som::SpecField& field = pdCls->fields[i];
    std::cout << "  " << field.name << "  kind=" << field.kind;
    if (!field.type.empty()) std::cout << "  type=" << field.type;
    if (!field.elementType.empty()) std::cout << "  elem=" << field.elementType;
    std::cout << "\n";
  }

  // Resolve concrete document paths to model nodes (value-free).
  std::cout << "\nPath resolution:\n";
  const std::string paths[] = {
      "SBP",
      "SBP/content",
      "SBP/currentLandscape",
      "SBP/currentLandscape/CUOPME-OPER-LST",
  };
  for (const std::string& path : paths) {
    std::optional<som::SpecResolution> res = ref.resolve(path);
    if (!res.has_value()) {
      std::cout << "  " << path << "  ->  (unresolved)\n";
      continue;
    }
    std::cout << "  " << path << " -> kind=" << res->kind;
    if (res->targetClass != nullptr) {
      std::cout << "  class=" << res->targetClass->name;
    }
    std::cout << "  value_leaf=" << (res->isValueLeaf() ? 1 : 0) << "\n";
  }

  return 0;
}
