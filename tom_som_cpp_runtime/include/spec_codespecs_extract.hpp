/* spec_codespecs_extract — the Phase-4 **specification extract generator**, the
 * machine half of CodeSpecs production (`codespecs_mapping.md` §1.1.1), an
 * idiomatic-C++ port of the Dart `spec_codespecs_extract` library.
 *
 * Phase 4 runs in two passes. This surface is the first: for each CodeSpecs area
 * it collects everything in a filled specification document that
 * `@CodeSpecKind` routes to that area, **verbatim and with provenance**, so the
 * second pass — an authoring agent, one prompt per authoring step — writes
 * against a bounded extract rather than against a 652-section document.
 *
 * The boundary between the two passes is a rule, not a preference. This
 * generator may **copy and index**; it may not summarise, rephrase, compose a
 * sentence out of field values, or choose a name — the prohibitions of
 * `codespecs_derivation_contract.md` §2.8 **C1**, which bind the extract
 * generator word for word. The consequence is checkable rather than trusted:
 * every CodeSpecsExtractEntry::value is a string the document stores, byte for
 * byte, and the conformance corpus asserts it.
 *
 * Three things follow from that and shape the API:
 *
 *   - **Routing is by the three verdicts** (`codespecs_mapping.md` §8.3) — a
 *     class carries `@CodeSpecKind` (feeds code), sits under a `@FollowUpKind`
 *     root (feeds a non-generation process), or carries `@NoArtifact` (feeds
 *     nothing). The trio is exhaustive by construction, so a class carrying none
 *     of them is not "skipped": it is a CodeSpecsExtractError, the `ROUTE-TOTAL`
 *     invariant (`tom_specs_model_rules.md` §10.2) failing loudly at the one
 *     place that depends on it.
 *   - **`@CodeSpecKind` is list-valued** (§9.1), and extracts are **not**
 *     deduplicated across areas: a section feeding three areas appears, whole,
 *     in three extracts. Each area's prompt must be self-sufficient.
 *   - **Every entry carries its provenance** — section id, class, field, the
 *     routing marker that put it here and where that marker was declared — so
 *     the `@DocSpec`/`DocRef` back-links (§9.3) can be written from the extract
 *     alone.
 *
 * The area catalogue (CodeSpecsAreaCatalog) is an **input**, not a table baked
 * into the runtime: it is the machine-readable form of `codespecs_mapping.md`
 * §4.1 (the parts catalogue), §4.4.3 (the emission slices) and §4.4.6 (the
 * authoring steps), authored once and read by all nine runtimes. Carrying it
 * beside the content is what stops an agent having to open the mapping document
 * to find out what `CE-FM` means.
 *
 * ## Ownership
 *
 * A CodeSpecsExtractor *borrows* its model and document — both must outlive it —
 * and *owns* a copy of the catalogue, which is small plain data read from JSON.
 * A produced CodeSpecsExtract owns everything it carries, so it outlives the
 * extractor that made it.
 */
#ifndef SPEC_CODESPECS_EXTRACT_HPP
#define SPEC_CODESPECS_EXTRACT_HPP

#include <exception>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "som_json.hpp"
#include "spec_document.hpp"
#include "spec_model.hpp"
#include "spec_reflection.hpp"

namespace som {

/* The version of the emitted extract artifact's on-disk shape. Bumped when the
 * YAML or Markdown layout changes in a way a reader could notice. */
inline constexpr long long kCodeSpecsExtractFormat = 1;

/* The annotation names of the three routing verdicts (`codespecs_mapping.md`
 * §8.3). All three ride the generic annotation bag in every SOM runtime (§8.4),
 * so they are read by name rather than through a meta slot. */
inline constexpr const char* kCodeSpecKindAnnotation = "CodeSpecKind";

/* See kCodeSpecKindAnnotation. */
inline constexpr const char* kFollowUpKindAnnotation = "FollowUpKind";

/* See kCodeSpecKindAnnotation. */
inline constexpr const char* kNoArtifactAnnotation = "NoArtifact";

/* Which of the three `codespecs_mapping.md` §8.3 verdicts a class carries. */
enum class CodeSpecsRoutingVerdict {
  /* `@CodeSpecKind(List<CodeSpecPart>)` — the section's content is shown to
   * every named area's extract. */
  FeedsCode,
  /* `@FollowUpKind(List<FollowUpProcess>)` — the section is delivered by a
   * non-generation process. The whole subtree is excluded from every extract. */
  FeedsProcess,
  /* `@NoArtifact(NoArtifactReason)` — the section deliberately produces no
   * downstream artifact. Its own leaves contribute nothing; its children are
   * still routed individually (that is what `container` means). */
  FeedsNothing,
  /* A `@Document` root carrying no verdict. Structurally exempt from
   * `ROUTE-TOTAL`: a root is the document, not a section of it. */
  DocumentRoot,
  /* No verdict, and not a `@Document` root — a `ROUTE-TOTAL` violation, and the
   * reason CodeSpecsExtractor::extractAll throws. */
  Unrouted,
};

/* The Dart enum's `.name`, which is what the shared corpus records. */
const char* codeSpecsRoutingVerdictName(CodeSpecsRoutingVerdict verdict);

/* The verdict recorded for one class node of the walked document, with the
 * provenance of the marker that decided it. */
struct CodeSpecsRouting {
  /* The document path of the node the verdict was computed for. */
  std::string path;
  /* The model class at `path`. */
  std::string className;
  /* Which verdict the class carries. */
  CodeSpecsRoutingVerdict verdict = CodeSpecsRoutingVerdict::Unrouted;
  /* The verdict's payload, verbatim from the annotation: the `CodeSpecPart.*`
   * values for FeedsCode, the `FollowUpProcess.*` values for FeedsProcess, the
   * single `NoArtifactReason.*` for FeedsNothing, and empty for the two verdicts
   * that have no marker. */
  std::vector<std::string> values;
  /* The marker's optional `note`, verbatim; unset when it carries none. */
  std::optional<std::string> note;
  /* Where the marker was declared — the class name, or `Class.field` when a
   * field-level `@CodeSpecKind` overrode its class. Empty when there is no
   * marker. */
  std::string declaredAt;

  /* Renders as `CodeSpecsRouting(<path>, <className>, <verdict>)`. */
  std::string display() const;
};

/* One extract entry: a single value the specification document stores, with
 * everything needed to trace it back (`codespecs_mapping.md` §1.1.1,
 * "Entry"). */
struct CodeSpecsExtractEntry {
  /* The `CE-*` code of the area this entry was collected for. */
  std::string areaCode;
  /* The section id of the leaf the value sits on (`@SectionId`, else the model
   * field name). */
  std::string sectionId;
  /* The document path of the leaf — the source location. */
  std::string path;
  /* The model class declaring the leaf. */
  std::string className;
  /* The model field name of the leaf. */
  std::string fieldName;
  /* The form-field name when the value is one field of a `@Form` section; unset
   * for a content, enum, scalar or scalar-list leaf. */
  std::optional<std::string> formField;
  /* The `CodeSpecPart.*` value that routed this entry here, verbatim. */
  std::string routedBy;
  /* Where that `@CodeSpecKind` was declared — the class name, or `Class.field`
   * for a field-level override. */
  std::string routedAt;
  /* The `@CodeSpecKind` `note`, verbatim; unset when it carries none. */
  std::optional<std::string> routingNote;
  /* The stored value, **verbatim**. Never assembled, reformatted or trimmed. */
  std::string value;

  /* Renders as `CodeSpecsExtractEntry(<areaCode>, <path>)`. */
  std::string display() const;
};

/* One emission slice of `codespecs_mapping.md` §4.4.3. */
struct CodeSpecsSlice {
  /* The slice's number, 1–7. */
  long long number = 0;
  /* The slice's name as §4.4.3 gives it. */
  std::string title;
  /* The §4.2 project the slice emits into. */
  std::string project;
  /* The slices this one may cite — §4.4.3's across-slice edges. Transitively
   * closed by CodeSpecsAreaCatalog::citableAreaCodes. */
  std::vector<long long> cites;

  /* Decodes one slice from its catalogue JSON object. */
  static CodeSpecsSlice fromJson(const JsonRef& j);
};

/* One row of the `codespecs_mapping.md` §4.1 parts catalogue, plus the §4.4.3
 * slice and §4.4.6 authoring steps that place it. This is the **per-area
 * context** an extract carries beside its content. */
struct CodeSpecsArea {
  /* The permanent registry key — `CE-FM`, `CE-API`. Never reused, never
   * renamed, and the extract file's name. */
  std::string code;
  /* The §4.1 canonical id — the PascalCase noun (`Form`, `ServerApi`). */
  std::string canonicalId;
  /* The `CodeSpecPart` value, camelCase and **without** the enum prefix
   * (`form`, `serverApi`). */
  std::string part;
  /* The `Cs*` annotation names of the §4.1 row. */
  std::vector<std::string> annotations;
  /* The §4.1 "Built on" cell, verbatim. */
  std::string builtOn;
  /* Where the area's spec-authorable attribute surface is stated — a §5.x
   * citation. */
  std::string attributeSurface;
  /* The §4.4.3 slice(s) the area's emission units sit in. More than one when the
   * area is split by locus. */
  std::vector<long long> slices;
  /* The §4.4.6 authoring step(s) that write the area. */
  std::vector<long long> authoringSteps;
  /* Whether the part is active. A deferred part (§4.3) holds a reserved
   * `CodeSpecPart` value but has no generated surface, so it gets no extract. */
  bool active = true;

  /* Decodes one area from its catalogue JSON object. */
  static CodeSpecsArea fromJson(const JsonRef& j);

  /* The fully-qualified `@CodeSpecKind` value — `CodeSpecPart.form`. */
  std::string kindValue() const;

  /* Renders as `CodeSpecsArea(<code>)`. */
  std::string display() const;
};

/* The machine-readable form of `codespecs_mapping.md` §4.1 + §4.4.3 + §4.4.6.
 *
 * Authored once, read by all nine runtimes. It is an input rather than a baked
 * table because the catalogue is the mapping document's content: a copy per
 * runtime would be nine things to keep current, and the one thing this quest has
 * learned three times is that a vocabulary duplicated nine ways can be wrong in
 * agreement. */
struct CodeSpecsAreaCatalog {
  /* Where the catalogue was transcribed from, for the extract header. */
  std::string source;
  /* The §4.4.3 slices, in emission order. */
  std::vector<CodeSpecsSlice> slices;
  /* The §4.1 areas, in catalogue order. Catalogue order is the tie-break §4.4.6
   * rule 2 uses, so it is load-bearing rather than cosmetic. */
  std::vector<CodeSpecsArea> areas;

  /* Decodes a catalogue from its `{source, slices, areas}` JSON object. */
  static CodeSpecsAreaCatalog fromJson(const JsonRef& j);

  /* The active areas, in catalogue order — one extract each. */
  std::vector<CodeSpecsArea> activeAreas() const;

  /* The area with this `CE-*` code, or null. Borrowed from `areas`. */
  const CodeSpecsArea* byCode(const std::string& code) const;

  /* The area a `@CodeSpecKind` value names, or null. Accepts both the bare value
   * (`form`) and the qualified one (`CodeSpecPart.form`), because the meta
   * carries the qualified spelling and callers reach for the bare one. */
  const CodeSpecsArea* byPart(const std::string& value) const;

  /* The slice numbered `number`, or null. Borrowed from `slices`. */
  const CodeSpecsSlice* sliceNumbered(long long number) const;

  /* The §4.2 projects `area`'s code lands in, in slice order.
   *
   * Derived from the area's slices rather than authored on the area: §4.4.3
   * already fixes one project per slice, so a per-area project column would be a
   * second place for the same fact to be stated — and the areas that would need
   * it are exactly the locus-split ones, where getting it wrong is easiest. */
  std::vector<std::string> projectsFor(const CodeSpecsArea& area) const;

  /* The area codes `area` may cite — every other active area whose emission
   * units sit in a slice `area`'s slices reach, following §4.4.3's edges
   * transitively. Within-slice citation is legal, so an area's own slices are
   * part of the reachable set; the area itself is excluded.
   *
   * Derived rather than authored: a hand-kept per-area citation list is a second
   * source of truth for something the slice graph already decides. */
  std::vector<std::string> citableAreaCodes(const CodeSpecsArea& area) const;
};

/* One area's extract: the area's context plus every routed entry, in SOM
 * document order. */
struct CodeSpecsExtract {
  /* The area this extract is for. */
  CodeSpecsArea area;
  /* The `codespecs_mapping.md` §4.1/§4.4.3 source the catalogue names. */
  std::string catalogSource;
  /* The section segment of the document root the entries were collected from. */
  std::string documentRoot;
  /* The area codes this area may cite (§4.4.3), for the agent's prompt. */
  std::vector<std::string> citableParts;
  /* The §4.2 projects the area's code lands in (§4.4.3, via the slices). */
  std::vector<std::string> projects;
  /* The routed entries, in SOM document order. */
  std::vector<CodeSpecsExtractEntry> entries;

  /* The extract's file name stem — `CE-FM.extract`. */
  std::string fileStem() const;

  /* The artifact of record (`codespecs_mapping.md` §1.1.1). Scalars are emitted
   * as JSON strings, which are valid YAML 1.2 double-quoted scalars — so one
   * escaping rule, identical in all nine runtimes, covers every value a
   * specification can hold. */
  std::string toYaml() const;

  /* The rendered view. Regenerated from the YAML's own data — nothing reads the
   * Markdown as input — and exists because the agent reads it far better than it
   * reads YAML. */
  std::string toMarkdown() const;
};

/* Thrown when the document cannot be extracted from at all.
 *
 * Two causes: a section routed nowhere — `ROUTE-TOTAL`
 * (`tom_specs_model_rules.md` §10.2) failing — and a walk root that cannot be
 * resolved to exactly one (`codespecs_prompt.md` §5). Both are errors rather than
 * skips: a section routed nowhere is a section the agent writing that area never
 * sees, and a walk over the wrong root is every area empty. A silent omission at
 * this boundary is indistinguishable from a specification that genuinely said
 * nothing. */
class CodeSpecsExtractError : public std::exception {
 public:
  CodeSpecsExtractError(std::string message, std::string path,
                        std::string className);

  /* What went wrong, in one sentence. */
  const std::string& message() const { return message_; }
  /* The document path of the offending node. */
  const std::string& path() const { return path_; }
  /* The model class at `path`. */
  const std::string& className() const { return className_; }

  /* Renders as `CodeSpecsExtractError: <message> (<path>, <className>)`. */
  const char* what() const noexcept override { return rendered_.c_str(); }

 private:
  std::string message_;
  std::string path_;
  std::string className_;
  std::string rendered_;
};

/* Produces one CodeSpecsExtract per active area from a filled specification
 * document.
 *
 * A Phase-4 run extracts from **one** specification document, so the walk has
 * exactly one root (`root()`, `codespecs_prompt.md` §5). The two ways to get that
 * wrong are both closed here rather than left to the caller: the walk cannot
 * union every `@Document` root, because there is no way to ask for that; and
 * naming a root the document never populates — the `D13CodeSpecsProjection`
 * mistake, whose `CGP/…` path space misses a blueprint's `SBP/…` values and
 * yields every area silently empty — is a CodeSpecsExtractError rather than an
 * empty result. */
class CodeSpecsExtractor {
 public:
  /* `model` describes the document's structure and carries the routing verdicts;
   * `document` is the filled specification document; `catalog` is
   * `codespecs_mapping.md` §4.1/§4.4.3/§4.4.6. Model and document are borrowed
   * and must outlive the extractor.
   *
   * `rootType` names the specification document's own root, by type name or by
   * section id. An empty `rootType` means "omitted": the document's single
   * **populated** root is used — the root under which the document holds any
   * value — falling back to the model's only root when the document is empty, so
   * an unfilled single-root model still reaches the routing walk.
   *
   * Throws CodeSpecsExtractError when the root cannot be resolved to exactly one:
   * an unknown `rootType`, a `rootType` holding no value while another root does,
   * more than one populated root, or an empty document over a multi-root model. */
  CodeSpecsExtractor(const SpecModel& model, const SpecDocument& document,
                     CodeSpecsAreaCatalog catalog,
                     const std::string& rootType = std::string());

  const SpecModel& model() const { return *model_; }
  const SpecDocument& document() const { return *document_; }
  const CodeSpecsAreaCatalog& catalog() const { return catalog_; }

  /* The one `@Document` root this extractor walks.
   *
   * Resolved once, by the constructor, so `routings()` and `extractAll()` cannot
   * disagree about what was walked. */
  const SpecRoot& root() const { return *root_; }

  /* The verdict of every class node the walk reaches, in document order.
   *
   * Computed by the same walk extractAll uses, so "what was routed where" and
   * "what landed in which extract" cannot disagree. Unlike extractAll this does
   * **not** throw on an unrouted class — it reports it, which is what a
   * diagnostic is for. */
  std::vector<CodeSpecsRouting> routings() const;

  /* One extract per active area, in catalogue order.
   *
   * Throws CodeSpecsExtractError on the first class the walk reaches that
   * carries none of the three verdicts. */
  std::vector<CodeSpecsExtract> extractAll() const;

  /* The single extract for `areaCode`, or std::nullopt when the catalogue holds
   * no such active area. */
  std::optional<CodeSpecsExtract> extractFor(const std::string& areaCode) const;

 private:
  // --- the walk ------------------------------------------------------------
  // `routings` / `entries` are output sinks; either may be null, which is how
  // the diagnostic pass and the collecting pass share one traversal.
  void walkAll(std::vector<CodeSpecsRouting>* routings,
               std::vector<CodeSpecsExtractEntry>* entries, bool strict) const;
  void walk(const std::string& path, const SpecClass* cls,
            const std::set<std::string>& ancestorTypes,
            std::vector<CodeSpecsRouting>* routings,
            std::vector<CodeSpecsExtractEntry>* entries, bool strict) const;

  /* Appends one entry **per area the routing names** — never deduplicated,
   * because each area's prompt must be self-sufficient (§1.1.1). */
  void emitValue(std::vector<CodeSpecsExtractEntry>* entries,
                 const CodeSpecsRouting* routing, const SpecClass& cls,
                 const SpecField& field, const std::string& path,
                 const std::optional<std::string>& formField,
                 const std::string& value) const;

  // --- verdict resolution --------------------------------------------------
  CodeSpecsRouting verdictOf(const SpecClass& cls,
                             const std::string& path) const;
  std::optional<CodeSpecsRouting> fieldRouting(const SpecClass& cls,
                                               const SpecField& field) const;

  const SpecModel* model_;
  const SpecDocument* document_;
  CodeSpecsAreaCatalog catalog_;
  const SpecRoot* root_;
};

}  // namespace som

#endif  // SPEC_CODESPECS_EXTRACT_HPP
