// TomSpecs sample — building tooling ON a specification (C++).
//
// The C++ port of `../bin/build_a_specification_tool.dart`: the same five
// steps over the same fixture. Its output differs from the Dart sample where
// the Dart text names a Dart-only surface, and where C++ names an API
// differently; `expected_output.txt` here records the C++ output, and
// README.md says where it differs.
//
// Build and run (from this folder; see README.md):  make && ./build/sample
//
// For the reader who is not authoring specifications but writing programs
// that read them: an editor, a linter, a report, an importer, a migration.
// That reader needs four things, and this sample walks them in the order they
// are needed:
//
//   1. REFLECTION   — what the model CAN hold, read from the metadata tree
//   2. GENERIC      — what a document DOES hold, with no compile-time
//                     knowledge of its shape
//   3. SCHEMA       — the generated schema, where it comes from and what it is
//   4. VALIDATION   — the two runtime tiers, and the third that is not here
//   5. A TOOL       — a completeness report built on all four
//
// MEMORY OWNERSHIP is RAII throughout. The reflection lookups return pointers
// and references that BORROW from the model (they live as long as it does);
// the metadata tree is a static the facade owns; facades BORROW the document.
// The sample runs clean under AddressSanitizer and a leak checker
// (`tool/validate.sh`).
#include "tom_som_cpp_v0.hpp"
#include "tom_som_cpp_v0_meta.hpp"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <memory>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#ifndef TOMSPECS_CHECKOUT
#define TOMSPECS_CHECKOUT "../../.."
#endif

namespace {

// The document root this sample inspects.
const std::string kRoot = "D00SolutionBlueprint";
// That root's addressable segment — the first element of every path in it.
const std::string kRootSegment = "SBP";
// The creation date section-id generation is pinned to (1 January): an
// unpinned run would emit different ids every day.
constexpr long long kAuthoredMonth = 1, kAuthoredDay = 1;
// The report's title column width; titles are clipped, never wrapped.
constexpr std::size_t kTitleWidth = 38;
constexpr long long kDaySeconds = 24 * 3600;

std::string readFile(const std::string& path) {
  std::ifstream in(path, std::ios::binary);
  if (!in) throw std::runtime_error("cannot read " + path);
  std::stringstream text;
  text << in.rdbuf();
  return text.str();
}

void section(int n, const std::string& title) {
  std::cout << "\n" << std::string(74, '=') << "\n" << n << ". " << title << "\n" << std::string(74, '=') << "\n";
}

// UTF-8 code points of `s`.
std::size_t utf8Len(const std::string& s) {
  return static_cast<std::size_t>(std::count_if(s.begin(), s.end(), [](char c) { return (c & 0xC0) != 0x80; }));
}

// The byte offset of code point `cp` in `s` (or s.size()).
std::size_t utf8Offset(const std::string& s, std::size_t cp) {
  std::size_t n = 0;
  for (std::size_t i = 0; i < s.size(); i++) {
    if ((s[i] & 0xC0) != 0x80) {
      if (n == cp) return i;
      n++;
    }
  }
  return s.size();
}

std::string padRight(const std::string& s, std::size_t width) {
  std::size_t n = utf8Len(s);
  return n >= width ? s : s + std::string(width - n, ' ');
}

std::string padLeft(const std::string& s, std::size_t width) {
  return s.size() >= width ? s : std::string(width - s.size(), ' ') + s;
}

std::string clip(std::string s, std::size_t width) {
  std::replace(s.begin(), s.end(), '\n', ' ');
  if (utf8Len(s) <= width) return s;
  return s.substr(0, utf8Offset(s, width - 1)) + "\xE2\x80\xA6";  // …
}

long pct(long written, long offered) { return std::lround(100.0 * written / offered); }

std::string opt(const std::optional<long long>& v) { return v ? std::to_string(*v) : "null"; }

const char* boolText(bool b) { return b ? "true" : "false"; }

// A field kind by the name the Dart enum gives it (`enum` is `enumValue`).
std::string kindName(const std::string& kind) { return kind == som::kSpecFieldKindEnum ? "enumValue" : kind; }

// Writes the small, deliberately incomplete document this run inspects — the
// same one the Dart sample writes.
void authorFixture(som::SpecDocument& doc) {
  tom_som_v0::D00SolutionBlueprint sbp(doc);
  sbp.setContent("A platform that unifies our fragmented order systems.");
  sbp.introductionAndScope().setContent("Replace three regional order desks with one intake service.");
  sbp.currentLandscape().setContent("Three legacy systems with no shared customer record.");

  som::SomList metrics = sbp.currentLandscape().operationalMetrics();
  metrics.addContentOn("Average order turnaround: 4.2 days.", kAuthoredMonth, kAuthoredDay);
  metrics.addContentOn("Manual reconciliation: ~12 hours per week.", kAuthoredMonth, kAuthoredDay);

  som::SomList entities = sbp.informationAndDataModel().dataModel().entities();
  tom_som_v0::DataEntityEntry customer(doc, entities.addOn(kAuthoredMonth, kAuthoredDay));
  customer.setHeadline("Customer");
  tom_som_v0::DataEntityEntryIdentityForm identity = customer.identity();
  identity.setEntityName("Customer");
  identity.setTableName("customers");
  identity.setDescription("A party that places orders.");
  // `category` is written and `aggregateRoot` is not, and `aggregateRoot` is
  // REQUIRED — so the schema tier has one real violation to report in step 4.
  customer.classification().setCategory("MasterData");
}

// ===========================================================================
// 1. Reflection — what the model CAN hold
// ===========================================================================

void reflectionStep(const som::SpecModel& model, const som::JsonRef& metaJson) {
  section(1, "Reflection — what the model CAN hold");
  std::cout << "`SpecModel` is the exported class graph; `SpecReflection` is the\n"
               "value-free query surface over it. No document is involved here.\n\n";

  std::cout << "THE TWO VERSION STAMPS. They answer different questions and a tool\n"
               "that checks one for the other will accept a file it cannot read:\n";
  std::cout << "  modelVersion      = " << model.modelVersion << "  — WHICH MODEL this snapshot describes\n";
  std::cout << "  metaSchemaVersion = " << opt(model.metaSchemaVersion)
            << "  — the FILE FORMAT the snapshot itself is written in\n";
  std::cout << "  modelVersionLabel = " << model.modelVersionLabel << "\n";
  // `generatedAt` holds epoch seconds; the stamp is printed as the snapshot
  // writes it.
  std::cout << "  generatedAt       = " << som::jsonStrOr(metaJson, "generatedAt") << "\n\n";
  std::cout << "A tool reads `metaSchemaVersion` to decide whether it can parse the\n"
               "file at all, and `modelVersion` to decide whether the documents it\n"
               "holds are the ones this model describes. `modelVersionLabel` is a\n"
               "build label for humans — never branch on it.\n\n";

  // A snapshot is a photograph. `checkStamp` compares what the exporter
  // DECLARED against what survived to the reader, and ages the file out.
  // `now` is derived from the model's own stamp so the printed age stays at
  // exactly the offset this sample means to demonstrate; the 30-day threshold
  // is the other runtimes' default.
  const long long exportedAt = model.generatedAt.value_or(1767225600LL);  // 2026-01-01
  const som::SpecModelStampCheck stamp = model.checkStamp(30 * kDaySeconds, exportedAt + 3 * kDaySeconds);
  std::cout << "SNAPSHOT CHECK (`checkStamp`), against a fixed clock:\n";
  std::cout << "  age                 : "
            << (stamp.ageSeconds ? std::to_string(*stamp.ageSeconds / kDaySeconds) : std::string("null"))
            << " days (aged: " << boolText(stamp.isAged()) << ")\n";
  std::cout << "  classes  declared/actual : " << opt(stamp.declaredClassCount) << "/" << stamp.actualClassCount
            << "  disagrees: " << boolText(stamp.classCountDisagrees()) << "\n";
  std::cout << "  roots    declared/actual : " << opt(stamp.declaredRootCount) << "/" << stamp.actualRootCount
            << "  disagrees: " << boolText(stamp.rootCountDisagrees()) << "\n";
  std::cout << "  Declared-vs-actual is not redundant: the declared value is what\n"
               "  the exporter recorded, the actual value is what survived to the\n"
               "  reader, and a truncated file is exactly where they part.\n\n";

  som::SpecReflection reflection(model);
  std::cout << "SHAPE:\n";
  std::cout << "  document roots : " << reflection.roots().size() << "\n";
  std::cout << "  classes        : " << reflection.classes().size() << "\n";
  std::cout << "  container root : " << model.containerRoot
            << " — the one true tree root, which is not itself a document\n\n";

  const som::SpecRoot* root = reflection.rootForSegment("SBP");
  const auto& fields = reflection.fieldsOf(root->type);
  std::cout << "FIELDS of " << root->type << " (" << fields.size() << " total, first 4):\n";
  for (std::size_t i = 0; i < 4 && i < fields.size(); i++) {
    std::cout << "  " << padRight(fields[i].name, 24) << " kind=" << padRight(kindName(fields[i].kind), 8) << " "
              << fields[i].type << "\n";
  }
  std::cout << "\n";

  // A form's slots are on the field itself, not on a separate class — the
  // shape a tool must handle to render or fill one.
  const auto& entityFields = reflection.fieldsOf("DataEntityEntry");
  const auto form = std::find_if(entityFields.begin(), entityFields.end(),
                                 [](const som::SpecField& f) { return f.kind == som::kSpecFieldKindForm; });
  std::cout << "FORM SLOTS of DataEntityEntry." << form->name << " (section id " << form->sectionId << "):\n";
  for (const auto& slot : form->formFields) {
    std::cout << "  " << padRight(slot.name, 16) << " " << slot.label << "\n";
  }
  std::cout << "\n";

  std::cout << "ANNOTATIONS the meta carries — the model's own metadata, exported\n"
               "into the snapshot and therefore visible in ALL NINE language\n"
               "runtimes, not just Dart:\n";
  for (const auto& a : reflection.annotationsOf(root->type)) {
    std::cout << "  @" << a.name;
    if (a.arguments && a.arguments->type == som::JsonType::Object && !a.arguments->object.empty()) {
      std::cout << "(";
      for (std::size_t k = 0; k < a.arguments->object.size(); k++) {
        std::cout << (k == 0 ? "" : ", ") << a.arguments->object[k].first;
      }
      std::cout << ")";
    }
    std::cout << "\n";
  }
  // The display semantics of these annotations (`kRenderedAnnotations`) are
  // in the Dart runtime only: they are what the two Flutter apps share.
  std::cout << "  How each is displayed is the Dart runtime's (`kRenderedAnnotations`,\n"
               "  shared by the two Flutter apps); the annotations themselves are\n"
               "  data every runtime reads.\n\n";

  std::cout << "PATH RESOLUTION — a document path to the model node it lands on:\n";
  for (const std::string p : {"SBP", "SBP/content", "SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST",
                              "SBP/informationAndDataModel/nosuchthing"}) {
    const auto r = reflection.resolve(p);
    std::cout << "  " << padRight(p, 50) << " "
              << (r ? "kind=" + r->kind + "  leaf=" + boolText(r->isValueLeaf()) : std::string("(unresolved)"))
              << "\n";
  }
}

// ===========================================================================
// 2. Generic access — what a document DOES hold
// ===========================================================================

void genericAccess(const som::SpecModel& model, const som::SpecDocument& doc) {
  section(2, "Generic access — what the document DOES hold");
  std::cout << "`SpecDocument` is a sparse, path-keyed store. A tool reads it\n"
               "without knowing the document's shape, and asks the model what each\n"
               "path means. That pairing is the whole of generic access.\n\n";

  som::SpecReflection reflection(model);
  std::cout << "EVERY written content leaf, resolved against the model:\n";
  for (const auto& p : doc.contentPaths()) {  // byte-sorted
    const auto r = reflection.resolve(p);
    std::cout << "  " << padRight(p, 52) << " " << (r ? r->kind : "?") << "\n";
    std::cout << "      " << clip(doc.content(p), 66) << "\n";
  }
  std::cout << "\n";

  std::cout << "EVERY written form section, slot by slot:\n";
  for (const auto& p : doc.formPaths()) {
    std::cout << "  " << p << "\n";
    for (const auto& slot : doc.formFieldNames(p)) {
      std::cout << "      " << padRight(slot, 16) << " " << clip(doc.formField(p, slot), 52) << "\n";
    }
  }
  std::cout << "\n";

  std::cout << "EVERY list, with its items' section ids:\n";
  for (const auto& p : doc.listPaths()) {
    std::cout << "  " << padRight(p, 52) << " " << doc.listItemCount(p) << " item(s)\n";
    for (const auto& id : doc.listItemSectionIds(p)) std::cout << "      " << id << "\n";
  }
  std::cout << "\n";

  const som::SomMetaTree& tree = tom_som_v0_meta::d00SolutionBlueprintMetaTree();
  std::cout << "WHERE PATHS COME FROM. A tool must never hard-code a path literal —\n"
               "a literal is undiscoverable and rots silently when the model moves.\n"
               "Two safe sources, both from the generated metadata module:\n\n";
  std::cout << "  1. the generated metadata refs —\n";
  std::cout << "     navInformationAndDataModel_dataModel(navD00SolutionBlueprint_informationAndDataModel(…)).ref.path\n";
  using namespace tom_som_v0_meta;
  std::cout << "       = "
            << navInformationAndDataModel_dataModel(
                   navD00SolutionBlueprint_informationAndDataModel(d00SolutionBlueprintMetaNav(tree)))
                   .ref.path
            << "\n";
  std::cout << "  2. the id-keyed metadata tree, for a path known only at runtime —\n";
  std::cout << "     tree.byId(\"DAENT-ENTI-LST\")\n";
  const som::SomMetaNode* node = tree.byId("DAENT-ENTI-LST");
  std::cout << "       = " << (node != nullptr ? node->path : std::string("nullptr")) << "\n\n";
  std::cout << "  The tree also goes the other way: byPath gives the node, and with\n"
               "  it the class, kind and children a generic renderer needs.\n";
  const som::SomMetaNode* byPath = tree.byPath("SBP/informationAndDataModel/dataModel");
  std::cout << "     tree.byPath(\"SBP/informationAndDataModel/dataModel\")\n";
  std::cout << "       class=" << byPath->className << " kind=" << byPath->kind
            << " children=" << byPath->children.size() << "\n";
}

// ===========================================================================
// 3. The generated schema
// ===========================================================================

void theSchema(const som::DocSpecsSchema& schema) {
  section(3, "The generated schema");
  std::cout << "Each of the 14 document roots has a schema GENERATED from the model\n"
               "and SHIPPED as data inside the facade package, under\n"
               "`schemas/<document>/<document>.1.0.docspecs-schema.yaml`. A tool\n"
               "loads one; it never writes one, and never derives one itself.\n\n"
               "IT IS A DocSpecs SCHEMA, NOT JSON SCHEMA. It describes a *markdown*\n"
               "document — headings, their ids, their formats, the form fields a\n"
               "section carries and which of them are required. A tool reaching for\n"
               "a JSON-Schema validator will not find one, because the artifact the\n"
               "schema governs is not JSON.\n\n";
  std::cout << "  root section id : " << schema.rootSectionId() << "\n";
  std::cout << "  section types   : " << schema.sectionTypes.size() << "\n\n";
  std::cout << "  That count is large because a Solution Blueprint SEEDS the twelve\n"
               "  Phase-3 documents: its own section classes ARE those documents'\n"
               "  types, so its schema covers every section id they define. Step 5\n"
               "  meets the same fact from the other side.\n\n"
               "  A section type resolves by ID PREFIX, which is how a generated id\n"
               "  like `DAENT-ENTI-7` finds its type without the schema listing\n"
               "  every instance:\n";
  for (const std::string id : {"DAENT-IDEN", "DAENT-ENTI-7", "NOSUCH-1"}) {
    const som::DocSpecsSectionType* t = schema.resolveSectionType(id);
    std::cout << "    " << padRight(id, 16) << " -> "
              << (t != nullptr ? t->prefix : "(no type — a tool treats this as unknownSection)") << "\n";
  }
}

// ===========================================================================
// 4. Validation — the tiers
// ===========================================================================

std::vector<som::DocSpecsViolation> documentTier(const som::SpecModel& model, const som::DocSpecsSchema& schema,
                                                 const som::SpecDocument& doc) {
  std::vector<som::DocSpecsViolation> out;
  som::DocSpecsValidator(schema).validateMarkdown(doc.toMarkdown(model, kRoot), out);
  return out;
}

void validation(const som::SpecModel& model, const som::DocSpecsSchema& schema, const som::SpecDocument& doc) {
  section(4, "Validation — three tiers, two of them here");
  std::cout << "THIS IS THE DISTINCTION TOOLING AUTHORS MISS. A tool that wants one\n"
               "tier and calls another gets nothing useful — not an error, just an\n"
               "empty list that reads like a pass.\n\n"
               "  STATIC tier   — checks the MODEL'S OWN ANNOTATIONS: field-type\n"
               "                  rules, @ContentType compatibility, cycles, the\n"
               "                  §10.2 structural invariants. Runs ONCE at\n"
               "                  generation time, in\n"
               "                  `tom_specs_clitool/lib/src/validator.dart`, and is\n"
               "                  deliberately NOT part of the nine-language runtime\n"
               "                  surface. Not reachable from this sample, and that\n"
               "                  is the point: by the time a document exists, this\n"
               "                  tier has already run.\n"
               "  INSTANCE tier — checks A DOCUMENT'S VALUES against the model:\n"
               "                  `validateDocument` (SOM §9). In every runtime.\n"
               "  DOCUMENT tier — checks a MARKDOWN RENDITION against the generated\n"
               "                  schema: `DocSpecsValidator` (SOM §14).\n\n"
               "The two runtime tiers overlap and neither implies the other:\n"
               "`validateDocument` reports a required field left empty in a form the\n"
               "document holds, but not a required section that is absent; the\n"
               "schema validator reports the absent section, but does not follow a\n"
               "reference it sees filled. A tool that wants \"is this document good?\"\n"
               "runs BOTH.\n\n";

  const auto instance = som::validateDocument(model, doc);
  const auto document = documentTier(model, schema, doc);
  std::cout << "THE FIXTURE, both tiers:\n";
  std::cout << "  instance tier : " << instance.size() << " error(s)\n";
  std::cout << "  document tier : " << document.size() << " violation(s)\n";
  for (std::size_t i = 0; i < document.size() && i < 4; i++) {
    const auto& v = document[i];
    std::cout << "    line " << v.line << ": " << v.rule << " [" << v.sectionId << "] " << clip(v.message, 54) << "\n";
  }
  if (document.size() > 4) std::cout << "    … and " << document.size() - 4 << " more\n";
  std::cout << "\n";

  // A document broken on purpose, to show the instance tier firing where the
  // document tier cannot see anything wrong.
  som::SpecDocument broken;
  authorFixture(broken);
  broken.setContent("SBP/informationAndDataModel/nosuchsection/content", "x");
  broken.setFormField("SBP/informationAndDataModel/dataModel/DAENT-ENTI-LST-1/DAENT-IDEN", "notAField", "x");
  std::cout << "A DELIBERATELY BROKEN COPY — one path the model does not have, one\n"
               "form slot the form does not declare:\n";
  for (const auto& e : som::validateDocument(model, broken)) {
    std::cout << "  " << padRight(e.code, 20) << " " << clip(e.path, 50) << "\n";
  }
  std::cout << "\n";

  std::cout << "THE CLOSED VERDICT SETS. C++ has them as closed lists of string\n"
               "constants, so a tool switches over them exhaustively rather than\n"
               "matching on message text:\n";
  const std::vector<std::string> codes(std::begin(som::kSpecValidationAllCodes),
                                       std::end(som::kSpecValidationAllCodes));
  std::cout << "  kSpecValidationAllCodes (" << codes.size() << "): ";
  for (std::size_t i = 0; i < codes.size(); i++) std::cout << (i == 0 ? "" : ", ") << codes[i];
  std::cout << "\n";
  const std::vector<std::string> rules(std::begin(som::kDocSpecsAllRules), std::end(som::kDocSpecsAllRules));
  std::cout << "  kDocSpecsAllRules (" << rules.size() << "):\n";
  for (std::size_t i = 0; i < rules.size(); i += 4) {
    std::cout << "    ";
    for (std::size_t k = i; k < i + 4 && k < rules.size(); k++) std::cout << (k == i ? "" : ", ") << rules[k];
    std::cout << "\n";
  }
}

// ===========================================================================
// 5. The tool
// ===========================================================================

struct CoverageRow {
  std::string title;
  long offered = 0;
  long written = 0;
};

struct CoverageReport {
  std::vector<CoverageRow> rows;
  long offered = 0;
  long written = 0;
};

// Adds every content position under `field` at `path`. `seen` carries the
// class names already on this branch; the model is a graph, and a section
// type that can contain itself would otherwise recurse forever.
void walk(const som::SpecReflection& reflection, const som::SpecDocument& doc, CoverageRow& counter,
          const som::SpecField& field, const std::string& path, const std::set<std::string>& seen) {
  const std::string& kind = field.kind;
  if (kind == som::kSpecFieldKindContent || kind == som::kSpecFieldKindScalar || kind == som::kSpecFieldKindEnum) {
    counter.offered++;
    if (doc.hasContent(path)) counter.written++;
  } else if (kind == som::kSpecFieldKindForm) {
    for (const auto& slot : field.formFields) {
      counter.offered++;
      if (!doc.formField(path, slot.name).empty()) counter.written++;
    }
  } else if (kind == som::kSpecFieldKindList) {
    counter.offered++;
    if (doc.listItemCount(path) > 0) counter.written++;
  } else if (kind == som::kSpecFieldKindSection || kind == som::kSpecFieldKindComplex) {
    if (field.type.empty() || seen.count(field.type) > 0) return;
    std::set<std::string> next = seen;
    next.insert(field.type);
    for (const auto& child : reflection.fieldsOf(field.type)) {
      walk(reflection, doc, counter, child, path + "/" + som::SpecReflection::fieldSegment(child), next);
    }
  }
}

// A section's title for the report — its model doc comment's first sentence,
// falling back to the field name where the model carries no doc.
std::string rowTitle(const som::SpecField& field) {
  std::string text = field.doc.substr(0, field.doc.find('\n'));
  if (const auto stop = text.find(". "); stop != std::string::npos) text = text.substr(0, stop);
  while (!text.empty() && text.back() == '.') text.pop_back();
  const auto first = text.find_first_not_of(" \t");
  const auto last = text.find_last_not_of(" \t");
  text = first == std::string::npos ? "" : text.substr(first, last - first + 1);
  return text.empty() ? field.name : clip(text, kTitleWidth);
}

// Walks `model` from `rootSegment` and counts, per top-level section, how many
// content positions the model offers and how many `doc` has written.
//
// Lists count as one position, not as their items: a list the author left
// empty offers exactly one thing to write — the first item — and a list with
// forty items has not made the document forty times more complete.
//
// The walk is entirely generic: it knows no class or field name, so it works
// unchanged against any of the fourteen document roots.
CoverageReport specificationCoverage(const som::SpecModel& model, const som::SpecDocument& doc,
                                     const std::string& rootSegment) {
  som::SpecReflection reflection(model);
  const som::SpecRoot* root = reflection.rootForSegment(rootSegment);
  CoverageReport report;
  for (const auto& field : reflection.fieldsOf(root->type)) {
    if (field.kind == som::kSpecFieldKindContent) continue;  // the root's own body
    CoverageRow row;
    walk(reflection, doc, row, field, rootSegment + "/" + som::SpecReflection::fieldSegment(field), {root->type});
    if (row.offered == 0) continue;
    row.title = rowTitle(field);
    report.offered += row.offered;
    report.written += row.written;
    report.rows.push_back(row);
  }
  return report;
}

void theTool(const som::SpecModel& model, const som::DocSpecsSchema& schema, const som::SpecDocument& doc) {
  section(5, "A tool: the completeness report");
  std::cout << "Built on all four surfaces above, and it reports something NEITHER\n"
               "validator can. The schema names what is REQUIRED and missing; an\n"
               "optional section left blank is perfectly valid and no validator will\n"
               "ever mention it. But \"which parts of this specification has nobody\n"
               "written yet?\" is the question a specification author actually has,\n"
               "and answering it means walking the model and asking the document.\n\n";

  const CoverageReport report = specificationCoverage(model, doc, kRootSegment);
  std::cout << "  " << padRight("SECTION", kTitleWidth) << " WRITTEN / OFFERED\n";
  for (const auto& row : report.rows) {
    std::cout << "  " << padRight(row.title, kTitleWidth) << " " << padLeft(std::to_string(row.written), 5) << " / "
              << padLeft(std::to_string(row.offered), 5)
              << (row.offered == 0 ? "" : padLeft(std::to_string(pct(row.written, row.offered)) + "%", 6)) << "\n";
  }
  std::cout << "  " << std::string(kTitleWidth, '-') << " " << std::string(19, '-') << "\n";
  std::cout << "  " << padRight("TOTAL", kTitleWidth) << " " << padLeft(std::to_string(report.written), 5) << " / "
            << padLeft(std::to_string(report.offered), 5)
            << padLeft(std::to_string(pct(report.written, report.offered)) + "%", 6) << "\n\n";
  const CoverageRow* largest = &report.rows[0];
  for (const auto& row : report.rows) {
    if (row.offered > largest->offered) largest = &row;
  }
  std::cout << "  " << largest->title.substr(0, largest->title.find(' ')) << " offers " << largest->offered
            << " positions because a Solution Blueprint SEEDS\n";
  std::cout << "  the twelve Phase-3 documents: its section classes ARE those\n"
               "  documents' types, so the model surface under an SBP root includes\n"
               "  everything it seeds. A tool that reports \"0 %\" against a number\n"
               "  like that should say what the denominator is — which is why the\n"
               "  report is per section and not one headline figure.\n\n"
               "  Required-and-missing, from the schema tier, for contrast:\n";
  const auto document = documentTier(model, schema, doc);
  const auto required = std::count_if(document.begin(), document.end(), [](const som::DocSpecsViolation& v) {
    return v.rule == som::kDocSpecsRuleMissingRequiredField;
  });
  std::cout << "    " << required << " missing required field(s) — the only gaps a validator\n";
  std::cout << "    will name, out of " << report.offered - report.written << " unwritten positions.\n\n";
  std::cout << "That gap between the two numbers is the tool's reason to exist.\n";
}

}  // namespace

int main() {
  const std::string metaText = readFile(TOMSPECS_CHECKOUT "/tom_som_cpp_v0/meta/spec_model.meta.json");
  std::string err;
  const som::JsonRef metaJson = som::jsonParse(metaText, &err);
  std::unique_ptr<som::SpecModel> model = som::SpecModel::fromJsonStr(metaText, &err);
  if (!model) {
    std::cerr << "model: " << err << "\n";
    return 1;
  }
  const std::optional<som::DocSpecsSchema> schema = som::docspecsSchemaFromYamlText(
      readFile(TOMSPECS_CHECKOUT "/tom_som_cpp_v0/schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml"),
      &err);
  if (!schema) {
    std::cerr << "schema: " << err << "\n";
    return 1;
  }

  som::SpecDocument doc;
  authorFixture(doc);

  section(0, "The document this run inspects");
  std::cout << "A Solution Blueprint with a handful of sections written and the\n"
               "rest left blank — small enough that every number below can be\n"
               "checked by reading `authorFixture` in this file.\n\n";
  std::cout << "  content leaves written : " << doc.contentPaths().size() << "\n";
  std::cout << "  form sections written  : " << doc.formPaths().size() << "\n";
  std::cout << "  lists with items       : " << doc.listPaths().size() << "\n";

  reflectionStep(*model, metaJson);
  genericAccess(*model, doc);
  theSchema(*schema);
  validation(*model, *schema, doc);
  theTool(*model, *schema, doc);
  return 0;
}
