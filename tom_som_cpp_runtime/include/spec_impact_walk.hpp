/* spec_impact_walk — the impact walk: the starting table of a change's impact
 * evaluation (the change mode of the `tom_specs` process, Phase 0 step
 * `impact`). An idiomatic-C++ port of the TypeScript `spec_impact_walk.ts`
 * (and the Dart `spec_impact_walk.dart`).
 *
 * For a specification it lists **every** section of **every** document root
 * of the model, filled or not, and roots the project never created as well:
 * each row with its section-id chain, its model class, whether it holds
 * values, and its CodeSpecs routing. Beside it, specImpactLevel records how
 * far the project has come (documents, extracts, IR, tests, code).
 *
 * Rows: one per class node (the root, each `complex` / `section` field, each
 * list item) and one per list (with its item count). An empty list of a class
 * element gets one **template** row `<list>`/`*` with the element's subtree
 * below it. Value leaves (content, form fields) are counted in their row, not
 * rows of their own. A class already on the branch is not entered again (the
 * model is a graph), exactly as the CodeSpecs routing walk cuts recursion.
 * Below a `@FollowUpKind` section every row carries that routing: the whole
 * subtree is delivered by the process, as the CodeSpecs extractor treats it.
 *
 * Pure: it reads a model and documents and writes nothing. Pinned by
 * `tom_som_conformance/corpus/impact_walk_cases.json`.
 */
#ifndef SPEC_IMPACT_WALK_HPP
#define SPEC_IMPACT_WALK_HPP

#include <map>
#include <optional>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"

namespace som {

/* What a row of the walk stands for (SpecImpactRow::kind). */
inline constexpr const char* kSpecImpactRowKindRoot = "root";
/* A `complex` field's class node. */
inline constexpr const char* kSpecImpactRowKindComplex = "complex";
/* A `section` field's class node. */
inline constexpr const char* kSpecImpactRowKindSection = "section";
/* A list field (its items are rows of their own). */
inline constexpr const char* kSpecImpactRowKindList = "list";
/* One item of a list of class elements. */
inline constexpr const char* kSpecImpactRowKindItem = "item";
/* The element class of an empty list, at `<list>`/`*`: what a new item holds. */
inline constexpr const char* kSpecImpactRowKindTemplate = "template";

/* One row of the impact walk. */
struct SpecImpactRow {
  /* The document path; a template's subtree has `*` for the item segment. */
  std::string path;
  /* The section-id chain, outer first, joined by ` > ` (a list item by its
   * stored id). */
  std::string chain;
  /* One of the kSpecImpactRowKind* names. */
  std::string kind;
  /* The model class; for a list, its element class (empty for a list of
   * scalars). */
  std::string className;
  /* Nesting below the root (the root is 0). */
  int depth = 0;
  /* Whether the document holds anything at or below the path
   * (hasValuesUnder); false for a template row. */
  bool filled = false;
  /* Stored values at or below the path: content leaves plus form-field
   * values. */
  long long values = 0;
  /* A list's item count; unset for every other row. */
  std::optional<long long> items;
  /* The CodeSpecs routing verdict name (`feedsCode`, `feedsProcess`,
   * `feedsNothing`, `documentRoot`, `unrouted`): of the class (a class row),
   * of the element class (a list of classes), or of the field, else its
   * enclosing class (a list of scalars). Below a `feedsProcess` section, that
   * section's routing. */
  std::string routing;
  /* The routing's values verbatim (`CodeSpecPart` / `FollowUpProcess` /
   * `NoArtifactReason` names). */
  std::vector<std::string> routingValues;
  /* Where the routing marker is declared (`Class` or `Class.field`); empty
   * when none. */
  std::string routingDeclaredAt;

  /* The row as JSON text, camelCase keys as the TypeScript `toJson`. */
  std::string toJson() const;
};

/* The walk of one document root. */
struct SpecImpactRootWalk {
  /* The root's model type, e.g. `D00SolutionBlueprint`. */
  std::string type;
  /* The root's section id (its first path segment). */
  std::string sectionId;
  /* Whether the specification has this document; an absent root is walked
   * over an empty document. */
  bool present = false;
  std::vector<SpecImpactRow> rows;

  /* `{type, sectionId, present, rows}` as JSON text. */
  std::string toJson() const;
};

/* Walks every document root of `model`, in model order: a root present in
 * `documents` (keyed by root type) over its document, any other over an empty
 * one. Throws std::invalid_argument for a document keyed by a type the model
 * has no root for. */
std::vector<SpecImpactRootWalk> specImpactWalk(
    const SpecModel& model, const std::map<std::string, SpecDocument>& documents);

/* A folder the caller passed for tests or code, and whether it exists. */
struct SpecImpactFolder {
  std::string path;
  bool present = false;
};

/* One document root of the level: whether the specification has it. */
struct SpecImpactLevelDocument {
  std::string type;
  std::string sectionId;
  bool present = false;
};

/* How far the project has come (impact_evaluation.md § Level). */
struct SpecImpactLevel {
  /* Every document root: whether the specification has it. */
  std::vector<SpecImpactLevelDocument> documents;
  /* `phase1_<...>/` holds a Markdown file. */
  bool projectIdea = false;
  /* `CE-*.extract.yaml` files in `generated-doc/codespecs_extracts/`. */
  long long extracts = 0;
  /* `generated-doc/codespecs_extracts/gate.verdicts.yaml` exists. */
  bool gateRecord = false;
  /* `*.ir.yaml` files in `irspecs/`. */
  long long ir = 0;
  /* Gate checklists and reports under `gates/` and `quality/evidence/gates/`,
   * sorted. */
  std::vector<std::string> gates;
  /* The test folders the caller passed; unset: none given. */
  std::optional<std::vector<SpecImpactFolder>> tests;
  /* The code folders the caller passed; unset: none given. */
  std::optional<std::vector<SpecImpactFolder>> code;
  /* The phases (1–6) the project has reached. */
  std::vector<int> phasesReached;
  /* The phases (1–6) it has not, which a change leaves out. */
  std::vector<int> phasesLeftOut;

  /* The level as JSON text, camelCase keys as the TypeScript `toJson`. */
  std::string toJson() const;
};

/* The project's level from the walk and a listing of the spec root (paths
 * relative to it, `/`-separated; `\` and a leading `./` are normalised).
 * Phase 1 is reached when a `phase1_*` folder holds a Markdown file, Phase 2
 * when the root with section id `SBP` is present, Phase 3 when any other root
 * is that is not a generation input, Phase 4 when extracts or IR exist,
 * Phases 5 and 6 when a test or code folder the caller passed exists. */
SpecImpactLevel specImpactLevel(
    const SpecModel& model, const std::vector<SpecImpactRootWalk>& walk,
    const std::vector<std::string>& listing,
    const std::optional<std::vector<SpecImpactFolder>>& tests,
    const std::optional<std::vector<SpecImpactFolder>>& code);

/* The specification's current documents in a listing of the spec root: the
 * `*.tomspecs.yaml` files directly in a `phase*` folder, sorted. */
std::vector<std::string> specImpactDocumentFiles(
    const std::vector<std::string>& listing);

/* The walk as Markdown (one table per root, then § Level when `level` is not
 * null): the table the change analyst gives verdicts to. */
std::string specImpactWalkMarkdown(const std::vector<SpecImpactRootWalk>& walk,
                                   const SpecImpactLevel* level);

}  // namespace som

#endif  // SPEC_IMPACT_WALK_HPP
