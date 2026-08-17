/* spec_model — in-memory representation of the exported TomSpecs class graph, an
 * idiomatic-C++ port of the C `spec_model` module.
 *
 * The model is a class graph, not an expanded tree: each class appears once and
 * field elementType/type references are followed on demand by a traversal.
 * Classes are kept sorted by name (binary-searchable).
 */
#ifndef SPEC_MODEL_HPP
#define SPEC_MODEL_HPP

#include <cstddef>
#include <map>
#include <memory>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

#include "som_json.hpp"

namespace som {

inline constexpr const char* kSpecFieldKindList = "list";
inline constexpr const char* kSpecFieldKindForm = "form";
inline constexpr const char* kSpecFieldKindSection = "section";
inline constexpr const char* kSpecFieldKindContent = "content";
inline constexpr const char* kSpecFieldKindEnum = "enum";
inline constexpr const char* kSpecFieldKindComplex = "complex";
inline constexpr const char* kSpecFieldKindScalar = "scalar";

/* Returns the canonical kind for `raw`, falling back to "scalar". */
std::string specParseFieldKind(const std::string& raw);

/* Derives the `major.minor` DocSpecs version string from a model's integer
 * version and its optional free-form label (port of the C
 * `som_model_version_string` / Go `SomModelVersionString`).
 *
 * When the label's `+`-stripped core has at least two dot-separated integer
 * components, those become `major.minor`; otherwise the result is
 * `<major>.0`. */
std::string somModelVersionString(long long major, const std::string& label);

struct SpecAnnotation {
  std::string name;
  JsonRef arguments;  // borrowed object node into the model source (or null)

  /* Returns the argument value for `key`, or null. */
  JsonRef argument(const std::string& key) const;
};

/* A list-valued taxonomy annotation: a set of enum codes plus an optional
 * explanatory note.
 *
 * The model states where a subtree is headed with two such annotations, which
 * share this shape exactly — `@CodeSpecKind(List<CodeSpecPart>, {note})` names
 * the CodeSpecs part(s) a section type must be realised as
 * (`codespecs_mapping.md` §9.1/§9.5), and
 * `@FollowUpKind(List<FollowUpProcess>, {note})` names the downstream
 * *process(es)* a non-code subtree feeds (`codespecs_mapping.md` §8.3). One
 * reader serves both; which annotation a link came from is expressed by which
 * accessor produced it.
 *
 * Obtaining a link at all means the annotation is present — which is why the
 * accessors return std::optional. That matters: a node with no link has not been
 * classified yet, whereas a link with an empty `kinds` is a recorded decision
 * that the section belongs to no member of that taxonomy. The two are different
 * statements, so they are different values rather than one empty vector. */
struct KindLink {
  /* The enum code names with their type prefix stripped — `validation`, not
   * `CodeSpecPart.validation`; `doc`, not `FollowUpProcess.doc`.
   *
   * Both annotations are list-valued because one section can be realised as
   * several parts, or feed several processes; consumers must handle all of
   * them, not just the first. */
  std::vector<std::string> kinds;
  /* The annotation's free-text `note`, unset when it carries none. */
  std::optional<std::string> note;
};

/* The third routing verdict: `@NoArtifact(NoArtifactReason, {note})` — the
 * section feeds neither a CodeSpecs part nor a follow-up process
 * (`codespecs_mapping.md` §8.3).
 *
 * Single-valued where KindLink is a list, and the asymmetry is the point: a
 * section can feed several parts or several processes at once, but it is
 * unrouted for exactly one reason. That reason is what makes the absence of the
 * other two markers readable as a decision rather than an omission, which is
 * what `tom_specs_model_rules.md` §10.2 invariant `ROUTE-TOTAL` checks. */
struct NoArtifactLink {
  /* The `NoArtifactReason` code name with its type prefix stripped —
   * `container`, not `NoArtifactReason.container`. One of `container`,
   * `overview`, `view`. */
  std::string reason;
  /* The annotation's free-text `note`, unset when it carries none. On an
   * `overview` this customarily names the routed section that states the
   * material normatively. */
  std::optional<std::string> note;
};

/* `CodeSpecPart.validation` → `validation`. A name already given bare is
 * returned unchanged, so readers do not depend on how the exporter chose to
 * spell the enum constant. Splitting on the last dot rather than a fixed prefix
 * keeps this working for any code enum the model adds. */
std::string specStripEnumPrefix(const std::string& raw);

/* ---- the annotation bag -------------------------------------------------
 *
 * The lookups below are the shared behaviour of the two model nodes that carry
 * annotations — classes and fields (the Dart reference's `AnnotatedSpecNode`
 * mixin). They are free functions over the annotation vector rather than
 * members duplicated on both structs, matching how the rest of this port reads
 * annotations. */

/* Returns the annotation named `name`, or null when absent. */
const SpecAnnotation* specAnnotationNamed(
    const std::vector<SpecAnnotation>& annotations, const std::string& name);

/* Whether the annotation named `name` is present. For markers that carry no
 * arguments, presence *is* the whole statement. */
bool specHasAnnotation(const std::vector<SpecAnnotation>& annotations,
                       const std::string& name);

/* The `@CodeSpecKind` link, unset when the node carries no such annotation.
 * Its list argument is named `kinds`. See KindLink for why absent and empty
 * differ. */
std::optional<KindLink> specCodeSpecKind(
    const std::vector<SpecAnnotation>& annotations);

/* The `@FollowUpKind` link, unset when the node carries no such annotation —
 * which downstream process(es) this subtree feeds instead of becoming CodeSpecs
 * code (`codespecs_mapping.md` §8.3). Its list argument is named `processes`. */
std::optional<KindLink> specFollowUpKind(
    const std::vector<SpecAnnotation>& annotations);

/* The `@NoArtifact` verdict, unset when the node carries no such annotation —
 * the recorded decision that the section produces nothing downstream
 * (`codespecs_mapping.md` §8.3). Its single argument is named `reason`. */
std::optional<NoArtifactLink> specNoArtifact(
    const std::vector<SpecAnnotation>& annotations);

struct FormFieldSpec {
  std::string name;
  std::string label;
  std::string type;  // defaults to "String"
  std::string hint;
  bool required = false;
  // Enum constant names when `type` is a model enum; empty for non-enum field
  // types. Lets consumers validate and convert values without the analyzer.
  std::vector<std::string> enumValues;
  // The registry key(s) this field's value is an id drawn from, each written
  // `<SECTIONID>.<formFieldName>`; empty for a non-reference field. A reference
  // field holds a free-text id that must already be declared by some entry of
  // the named registry, so a runtime can resolve it and report a dangling id
  // instead of generating broken code.
  std::vector<std::string> refersTo;
};

struct SpecField {
  std::string name;
  std::string kind;
  std::string doc;
  std::string help;
  std::string headline;  // @Headline(text) default headline (YRD4), "" none
  std::string sectionId;
  std::string sectionIdPattern;
  std::string elementType;
  bool elementIsComplex = false;
  bool hasMin = false;
  long long min = 0;
  std::string contentType;
  std::string sectionType;
  std::string enumType;
  std::vector<std::string> enumValues;
  std::string type;
  bool hasSerializationOrder = false;
  long long serializationOrder = 0;
  std::vector<FormFieldSpec> formFields;
  std::vector<SpecAnnotation> annotations;

  /* Reports whether expanding this field reveals further tree nodes. */
  bool isExpandable() const;
};

struct SpecClass {
  std::string name;
  std::string sectionId;
  std::string doc;
  std::string help;
  std::string headline;  // class-level @Headline(text) default (YRD4), "" none
  std::string mapsTo;
  std::string detailedIn;
  std::vector<SpecField> fields;
  std::vector<SpecAnnotation> annotations;

  /* Returns the field named `name`, or null. */
  const SpecField* fieldNamed(const std::string& name) const;
};

struct SpecRoot {
  std::string type;
  std::string title;
  std::string sectionId;
  std::string description;
  std::string doc;
};

/* Seconds in a day — the unit ages and thresholds are reported in. */
inline constexpr long long kSecondsPerDay = 86400;

/* How old a snapshot may get before SpecModel::checkStamp calls it aged.
 *
 * A fortnight: long enough that a healthy working copy is never nagged, short
 * enough that structural feedback keyed to a snapshot's paths is not recorded
 * against a model that has moved past them. */
inline constexpr long long kDefaultMaxSnapshotAgeSeconds = 14 * kSecondsPerDay;

/* Parses the exporter's stamp grammar
 * `YYYY-MM-DD[T ]hh:mm:ss[.fraction][Z|(+|-)hh[:]mm]` to epoch seconds (UTC).
 *
 * The grammar is spelled out here rather than handed to a platform parser, so
 * that all nine runtimes accept exactly the same set of strings: a zone-less
 * stamp is read as UTC (never local time), a day that does not exist in its
 * month is rejected rather than rolled over, and a date-only string is outside
 * the grammar. The fractional part is accepted and discarded — every consumer
 * compares the resulting instant in whole days.
 *
 * Anything outside the grammar degrades to std::nullopt rather than throwing:
 * an unreadable stamp is not worth failing a whole model over. */
std::optional<long long> specParseStampTimestamp(const std::string& raw);

/* The outcome of checking a loaded snapshot's generation stamp against its own
 * payload and against the clock — see SpecModel::checkStamp. */
struct SpecModelStampCheck {
  /* Seconds between the stamp and `now`, or nullopt when unstamped. */
  std::optional<long long> ageSeconds;
  long long maxAgeSeconds = kDefaultMaxSnapshotAgeSeconds;
  /* The class count the stamp declares, or nullopt when it declares none. */
  std::optional<long long> declaredClassCount;
  long long actualClassCount = 0;
  /* The document-root count the stamp declares, or nullopt. */
  std::optional<long long> declaredRootCount;
  long long actualRootCount = 0;

  /* Whether the snapshot is older than `maxAgeSeconds`. Always false when it
   * carries no `generatedAt` — an unknown age is not evidence of a stale one. */
  bool isAged() const;
  /* Whether the declared and actual class counts differ. An absent declaration
   * is not a disagreement: older snapshots predate the stamp keys, and reading
   * absent as 0 would make every one of them look corrupt. */
  bool classCountDisagrees() const;
  /* Whether the declared and actual root counts differ. */
  bool rootCountDisagrees() const;
  /* Whether either declared size disagrees with the payload. The exporter
   * derives both counts *from* the payload it writes, so a disagreement cannot
   * arise from a normal export — it means the file was edited afterwards. */
  bool countsDisagree() const;
  /* Whether anything at all was found. */
  bool isStale() const;
  /* The findings as ready-to-display sentences, empty when there are none. The
   * wording is identical in all nine runtimes. */
  std::vector<std::string> warnings() const;
};

class SpecModel {
 public:
  std::vector<SpecRoot> roots;
  long long modelVersion = 0;
  std::string modelVersionLabel;

  /* Generation stamp. Every key is optional — a pre-stamp snapshot leaves it
   * nullopt, which is *not* the same as a declared count of zero. C++ has no
   * calendar type in the standard library, so the instant is carried as epoch
   * seconds and the sub-second part of the stamp is accepted but discarded. */
  std::optional<long long> generatedAt;
  std::optional<long long> metaSchemaVersion;
  /* The class count the snapshot declares, kept separate from classesSize():
   * the declared value is what the exporter recorded, the actual value is what
   * survived to the reader, and comparing them is the point (checkStamp). */
  std::optional<long long> classCount;
  std::optional<long long> rootCount;
  /* The canonical container class — the single true tree root, which is not
   * itself a document and so does not appear in `roots`. Empty when absent. */
  std::string containerRoot;

  /* Returns the class named `name`, or null. */
  const SpecClass* classNamed(const std::string& name) const;

  /* Returns the document root whose `type` equals `type` (SOM §21).
   * Replaces the recurring firstWhere((r) => r.type == …) boilerplate. Throws
   * std::invalid_argument when no root carries that type, with a message that
   * names the missing type and the ones that do exist. */
  const SpecRoot& rootByType(const std::string& type) const;

  /* The number of classes the payload actually carries (the other ports read
   * `classes.size()` directly; here the map is private). */
  std::size_t classesSize() const { return classesByName_.size(); }

  /* Compares this model's stamp against `nowEpochSeconds` with
   * `maxAgeSeconds` as the staleness threshold. */
  SpecModelStampCheck checkStamp(long long maxAgeSeconds,
                                 long long nowEpochSeconds) const;

  /* Decodes a meta-data JSON document. On failure returns null and, when `err`
   * is non-null, writes an error message. */
  static std::unique_ptr<SpecModel> fromJsonStr(const std::string& data,
                                                std::string* err);

  /* Builds a model from an already-parsed meta-data JSON node. The node is
   * retained (annotation arguments borrow from it) via shared ownership, so it
   * stays alive for the model's lifetime. Mirrors the C `spec_model_from_json`. */
  static std::unique_ptr<SpecModel> fromJson(const JsonRef& root);

 private:
  // Shared builder for both fromJsonStr and fromJson: fills the model from an
  // already-parsed root node and retains it (annotations borrow from it).
  static std::unique_ptr<SpecModel> buildFromRoot(const JsonRef& root);

  // sorted-by-name map (std::map gives byte-ordered, binary-searchable access).
  std::map<std::string, SpecClass> classesByName_;
  JsonRef source_;  // owned parsed tree; annotations borrow from it
};

}  // namespace som

#endif  // SPEC_MODEL_HPP
