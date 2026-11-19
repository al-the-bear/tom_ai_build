// TomSpecs sample — a Phase 4 CodeSpecs run, as far as the C++ runtime goes.
//
// The C++ port of `../bin/phase4_codespecs_run.dart`. Phase 4 has four stages,
// and the C++ runtime carries the first two:
//
//   stage 1  the starting prompt's quality gate   [MECHANICAL]  here
//   stage 2  the extract generator                [MECHANICAL]  here
//   stage 3  the authoring agent                  [JUDGMENT]    the IR, Dart tools
//   stage 4  validating the emitted trio          [MECHANICAL]  Dart tools
//
// Stages 3 and 4 run on the Dart tools (`tomspecs :ir-map`,
// `tomspecs :codespecs-validate`); the Dart sample shows them. This port runs
// the same specification through the gate and the extract generator, and its
// extracts are the ones the Dart sample writes (`CodeSpecsExtract` is in all
// nine runtimes, byte for byte the same).
//
// Build and run (from this folder; see README.md):  make && ./build/sample
//
// MEMORY OWNERSHIP is RAII throughout. A `CodeSpecsGate` BORROWS its model,
// document, catalogue and schema (they must outlive it); the
// `CodeSpecsGateReport` it returns is a value that OWNS its findings and its
// extracts, each extract holding its own copy of its area. Facades BORROW the
// document. The sample runs clean under AddressSanitizer and a leak checker
// (`tool/validate.sh`).
#include "tom_som_cpp_v0.hpp"
#include "tom_som_cpp_v0_meta.hpp"

#include <cstdio>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <sys/stat.h>
#include <vector>

#ifndef TOMSPECS_CHECKOUT
#define TOMSPECS_CHECKOUT "../../.."
#endif

namespace {

// The one `@Document` root this run extracts from (codespecs_prompt.md §5).
const std::string kRoot = "D00SolutionBlueprint";
// The creation date section-id generation is pinned to (1 January), so the
// ids (and with them `expected_output.txt`) do not change with the calendar.
constexpr long long kAuthoredMonth = 1, kAuthoredDay = 1;

// What every gate run takes: the model, the schema and the area catalogue.
struct Inputs {
  std::unique_ptr<som::SpecModel> model;
  som::DocSpecsSchema schema;
  som::CodeSpecsAreaCatalog catalog;
};

std::string readFile(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  if (!in) throw std::runtime_error("cannot read " + path);
  std::stringstream text;
  text << in.rdbuf();
  return text.str();
}

void writeFile(const std::string& path, const std::string& text) {
  std::ofstream out(path, std::ios::binary);
  if (!out) throw std::runtime_error("cannot write " + path);
  out << text;
}

void rule(const std::string& title) {
  std::cout << std::string(72, '=') << "\n" << title << "\n" << std::string(72, '=') << "\n";
}

std::size_t utf8Len(const std::string& s) {
  std::size_t n = 0;
  for (char c : s) n += (c & 0xC0) != 0x80;
  return n;
}

// `value`, cut to 41 code points and `...` when longer than 44.
std::string shortValue(const std::string& value) {
  if (utf8Len(value) <= 44) return value;
  std::size_t n = 0, i = 0;
  for (; i < value.size(); i++) {
    if ((value[i] & 0xC0) != 0x80) {
      if (n == 41) break;
      n++;
    }
  }
  return value.substr(0, i) + "...";
}

std::string padRight(const std::string& s, std::size_t width) {
  std::size_t n = utf8Len(s);
  return n >= width ? s : s + std::string(width - n, ' ');
}

std::string joined(const std::vector<std::string>& items) {
  std::string out;
  for (std::size_t i = 0; i < items.size(); i++) out += (i == 0 ? "" : ", ") + items[i];
  return out;
}

// ---- the specification — the one the Dart sample authors -------------------

// An attribute: headline, column, description and physical type.
void attribute(som::SpecDocument& doc, som::SomList& list, const std::string& headline, const std::string& column,
               const std::string& description, const std::string& physical) {
  tom_som_v0::DataAttributeEntry a(doc, list.addOn(kAuthoredMonth, kAuthoredDay));
  a.setHeadline(headline);
  a.identity().setColumnName(column);
  a.identity().setDescription(description);
  a.dataTypeSpec().setPhysicalType(physical);
}

// A key: headline, type, columns, description and (when given) generation.
void key(som::SpecDocument& doc, som::SomList& list, const std::string& headline, const std::string& type,
         const std::string& columns, const std::string& description, const std::string& generation) {
  tom_som_v0::KeyAttributeEntry k(doc, list.addOn(kAuthoredMonth, kAuthoredDay));
  k.setHeadline(headline);
  k.content().setKeyType(type);
  k.content().setKeyColumns(columns);
  k.content().setDescription(description);
  if (!generation.empty()) k.generation().setGenerationStrategy(generation);
}

// An entity: its identity and classification.
tom_som_v0::DataEntityEntry entity(som::SpecDocument& doc, som::SomList& entities, const std::string& headline,
                                   const std::string& content, const std::string& name, const std::string& table,
                                   const std::string& alias, const std::string& description,
                                   const std::string& category, const std::string& aggregateRoot) {
  tom_som_v0::DataEntityEntry e(doc, entities.addOn(kAuthoredMonth, kAuthoredDay));
  e.setHeadline(headline);
  e.setContent(content);
  tom_som_v0::DataEntityEntryIdentityForm identity = e.identity();
  identity.setEntityName(name);
  identity.setTableName(table);
  identity.setEntityAlias(alias);
  identity.setDescription(description);
  tom_som_v0::DataEntityEntryClassificationForm classification = e.classification();
  classification.setCategory(category);
  classification.setBoundedContext("Ordering");
  if (!aggregateRoot.empty()) classification.setAggregateRoot(aggregateRoot);
  return e;
}

// Two entities, four attributes and their keys: one area populated and the
// rest empty. `aggregateRoots` false clears the one required field variant B
// removes — `DAENT-CLAS.aggregateRoot` — and nothing else.
void authorSpecification(som::SpecDocument& doc, bool aggregateRoots) {
  tom_som_v0::D00SolutionBlueprint sbp(doc);
  sbp.setContent("Order intake for a single region.");

  // The bounded context CE-SU's required `boundedContext` argument resolves
  // against: an unauthored registry would make the reference dangle at A2.
  som::SomList contexts = sbp.solutionArchitectureAndTechnology()
                              .technicalFramework()
                              .softwareDesign()
                              .layeringAndModuleStructure()
                              .boundedContexts();
  tom_som_v0::BoundedContextEntry ordering(doc, contexts.addOn(kAuthoredMonth, kAuthoredDay));
  ordering.setHeadline("Ordering");
  ordering.content().setContextName("Ordering");
  ordering.content().setDomainArea("Order management");

  som::SomList entities = sbp.informationAndDataModel().dataModel().entities();

  tom_som_v0::DataEntityEntry customer =
      entity(doc, entities, "Customer", "A party that places orders.", "Customer", "customers", "CUST",
             "A person or organisation that places orders.", "MasterData", aggregateRoots ? "Customer" : "");
  som::SomList customerAttributes = customer.attributes();
  attribute(doc, customerAttributes, "email", "email", "The address order confirmations are sent to.", "VARCHAR");
  attribute(doc, customerAttributes, "displayName", "display_name", "The name the customer trades under.",
            "VARCHAR");
  // A customer is identified by the address it trades under: a natural key.
  som::SomList customerKeys = customer.keyAttributes();
  key(doc, customerKeys, "pk_customers", "Natural", "email", "A customer is identified by its e-mail address.", "");

  tom_som_v0::DataEntityEntry order =
      entity(doc, entities, "Order", "One accepted customer order.", "Order", "orders", "ORD",
             "A single order placed by a customer.", "TransactionData", aggregateRoots ? "Order" : "");
  som::SomList orderAttributes = order.attributes();
  attribute(doc, orderAttributes, "orderId", "order_id", "The identifier the order is filed under.", "UUID");
  som::SomList orderKeys = order.keyAttributes();
  key(doc, orderKeys, "pk_orders", "Primary", "order_id", "The order identifier.", "UUID");
  attribute(doc, orderAttributes, "placedAt", "placed_at", "The moment the order was accepted.", "TIMESTAMP");
}

// ---- stage 1 — the mechanical gate (codespecs_prompt.md §4) ----------------

const char* const kTitles[] = {
    "schema completeness  ", "instance-tier values ", "routing totality     ",
    "required arguments   ", "structured carriers  ",
};

// Runs the mechanical tier over `doc` and prints each check's verdict. All
// five checks run as one gate and none stops the others; a check that could
// not run says so, and the gate does not pass.
som::CodeSpecsGateReport runGate(const Inputs& in, const som::SpecDocument& doc) {
  std::cout << "1. The starting prompt's quality gate        [MECHANICAL]\n";
  const som::CodeSpecsGate gate(*in.model, doc, in.catalog, &in.schema, kRoot);
  som::CodeSpecsGateReport report = gate.run();
  for (const som::CodeSpecsGateCheckResult& r : report.results) {
    std::cout << "   " << som::codeSpecsGateCheckLabel(r.check) << " " << kTitles[static_cast<int>(r.check)] << ": ";
    if (!r.ran) {
      std::cout << "NOT RUN — " << r.notRunReason.value_or("") << "\n";
    } else if (r.findings.empty()) {
      std::cout << "pass — 0 findings\n";
    } else {
      std::cout << "FAIL — " << r.findings.size() << " findings\n";
    }
  }
  std::cout << "   (A4 held " << in.catalog.requiredArguments.size() << " required-argument rows, A5 "
            << in.catalog.carriers.size() << " carriers, both from the catalogue's gate tables)\n";
  return report;
}

// ---- stage 2 — the extract generator ----------------------------------------

void stage2(const std::vector<som::CodeSpecsExtract>& extracts) {
  std::cout << "2. The extract generator                      [MECHANICAL]\n";
  std::size_t populated = 0;
  for (const som::CodeSpecsExtract& e : extracts) populated += !e.entries.empty();
  std::cout << "   areas in the catalogue   : " << extracts.size() << "\n";
  std::cout << "   populated                : " << populated << "\n";
  for (const som::CodeSpecsExtract& e : extracts) {
    if (e.entries.empty()) continue;
    std::cout << "     " << padRight(e.area.code, 6) << " " << e.entries.size() << " entries  → " << joined(e.projects)
              << "\n";
  }
  std::cout << "   empty                    : " << extracts.size() - populated << "\n";
  std::cout << "   Most areas are empty because this document says nothing about\n"
               "   screens, jobs, reports or migrations. An empty extract is a\n"
               "   CANDIDATE for \"not applicable\" — never the verdict itself, which\n"
               "   is a judgment and belongs to stage B (codespecs_prompt.md §6.4).\n";

  mkdir("build", 0755);
  mkdir("build/codespecs_extracts", 0755);
  for (const som::CodeSpecsExtract& e : extracts) {
    const std::string stem = "build/codespecs_extracts/" + e.fileStem();
    writeFile(stem + ".yaml", e.toYaml());
    writeFile(stem + ".md", e.toMarkdown());
  }
  std::cout << "\n";

  const som::CodeSpecsExtract* db = nullptr;
  for (const som::CodeSpecsExtract& e : extracts) {
    if (e.area.code == "CE-DB") db = &e;
  }
  std::cout << "   Area " << db->area.code << " — " << db->area.canonicalId << ", the extract the\n";
  std::cout << "   authoring agent reads in stage 3:\n";
  std::cout << "   built on   : " << db->area.builtOn << "\n";
  std::cout << "   may cite   : " << joined(db->citableParts) << "\n";
  std::cout << "   entries carried to the agent (" << db->entries.size() << "):\n";
  for (const som::CodeSpecsExtractEntry& entry : db->entries) {
    std::cout << "     " << padRight(entry.sectionId, 11) << " " << padRight(entry.fieldName, 14) << " "
              << shortValue(entry.value) << "\n";
  }
  std::cout << "\n";
}

void stages3and4() {
  std::cout << "3. The authoring agent                        [JUDGMENT]\n"
               "4. Validating the emitted trio                [MECHANICAL]\n"
               "   Not in the C++ runtime. The authoring agent writes the IR\n"
               "   from these extracts, and the Dart tools map and validate it\n"
               "   (`tomspecs :ir-map`, `tomspecs :codespecs-validate`); the Dart\n"
               "   sample in ../bin/ shows both stages on this same specification.\n"
               "\n";
}

// ---- the two variants -------------------------------------------------------

// Variant A — a document that passes, taken as far as the extracts. Returns
// the number of extracts written.
std::size_t variantA(const Inputs& in) {
  som::SpecDocument doc;
  authorSpecification(doc, true);

  rule("Variant A — a sufficient specification");
  std::cout << "0. The document under Phase 4                 [input]\n"
               "   a Solution Blueprint whose information model holds 2 entities\n"
               "   and 4 stored attributes; every other section is unwritten.\n"
               "\n";

  const som::CodeSpecsGateReport report = runGate(in, doc);
  if (!report.passed()) throw std::runtime_error("variant A was supposed to pass the gate");
  std::cout << "   gate verdict             : PASS — the run may begin\n\n";

  // A passed gate always carries its extracts.
  stage2(*report.extracts);
  stages3and4();
  return report.extracts->size();
}

// Variant B — the same document with one required field cleared.
void variantB(const Inputs& in) {
  som::SpecDocument doc;
  authorSpecification(doc, false);

  rule("Variant B — the same document, one required field cleared");
  std::cout << "Both entities keep their `DAENT-CLAS` section and its `category`, and\n"
               "both have `aggregateRoot` cleared. Nothing else changed.\n"
               "\n";

  const som::CodeSpecsGateReport report = runGate(in, doc);
  if (report.passed()) throw std::runtime_error("variant B was supposed to be rejected");
  std::cout << "   gate verdict             : REJECTED — the run may not begin\n\n";
  std::cout << "   What the gate names, per finding:\n";
  for (const som::CodeSpecsGateFinding& f : report.findings()) {
    std::cout << "     " << som::codeSpecsGateCheckLabel(f.check) << " " << f.code << " [" << f.location << "] "
              << f.message << "\n";
  }
  std::cout << "\n";
  std::cout << "   A2 moved too: " << report[som::CodeSpecsGateCheck::A2].findings.size()
            << " violations, against 0 for variant A. The\n"
               "   classification form still holds other values, so its empty\n"
               "   required field is reported by both tiers. They part where a value\n"
               "   is absent rather than empty: a missing required section is seen by\n"
               "   A1 alone. That is why the gate runs both tiers and not either one\n"
               "   (codespecs_prompt.md §4.1/§4.2 and its §10.1/§10.2 fixtures).\n"
               "\n";
}

}  // namespace

int main() {
  std::string err;
  const std::string metaText = readFile(TOMSPECS_CHECKOUT "/tom_som_cpp_v0/meta/spec_model.meta.json");
  std::unique_ptr<som::SpecModel> model = som::SpecModel::fromJsonStr(metaText, &err);
  if (!model) {
    std::cerr << "model: " << err << "\n";
    return 1;
  }
  std::optional<som::DocSpecsSchema> schema = som::docspecsSchemaFromYamlText(
      readFile(TOMSPECS_CHECKOUT "/tom_som_cpp_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml"),
      &err);
  if (!schema) {
    std::cerr << "schema: " << err << "\n";
    return 1;
  }
  const som::JsonRef catalogJson =
      som::jsonParse(readFile(TOMSPECS_CHECKOUT "/tom_specs_model/generated-doc/codespecs/codespecs_areas.json"), &err);
  if (!err.empty()) {
    std::cerr << "catalogue: " << err << "\n";
    return 1;
  }
  const Inputs in{std::move(model), std::move(*schema), som::CodeSpecsAreaCatalog::fromJson(catalogJson)};

  rule("A Phase 4 CodeSpecs run, stage by stage");
  std::cout << "Every step is marked [MECHANICAL] or [JUDGMENT].\n\n";

  const std::size_t extracts = variantA(in);
  variantB(in);

  std::cout << "\nExtracts written to build/codespecs_extracts/ (" << extracts * 2 << " files).\n";
  return 0;
}
