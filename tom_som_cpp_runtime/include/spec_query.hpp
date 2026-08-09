/* spec_query — lexical/structural query + lazy cursor over a live SpecDocument
 * (`llm_and_d4rt_tools.md` §6, `som_multiplatform_spec_model.md` §15), an
 * idiomatic-C++ port of the Dart `spec_query` library.
 *
 * This is the **grep-like** facility the downstream D4rt scripting layer and the
 * editor's search tools reuse. It is **embedding-free** — exact substring or
 * SomTextPattern match plus structural filters — so it is always current and
 * needs no model calls.
 *
 * A SpecQuery composes (AND-combined) over five dimensions:
 *   - **text** — substring or SomTextPattern over content + form-field values
 *     and over a node's headline, stored or doc-comment (optionally
 *     case-insensitive);
 *   - **kind** — one or more node kinds;
 *   - **class** — the model class a node *is* (by class name);
 *   - **id / path** — exact `@SectionId`, `@SectionId` prefix, path glob, or a
 *     `@MapsTo` / `@DetailedIn` target on the node's class;
 *   - **state** — empty / non-empty (the structural "empty = no value" test).
 *
 * SpecQueryEngine::query returns a SpecQueryCursor the caller iterates lazily
 * (`next` / `take` / `count`). The cursor captures the **structural** candidate
 * set when it is created, then **re-validates each path against the live
 * document on every step** — so a result whose list-item ancestor was removed
 * after the cursor was made is silently skipped (stable against concurrent
 * edits, llm_and_d4rt_tools.md §6).
 *
 * ## Absent vs. empty
 *
 * The Dart original spells "this dimension is not filtered on" as `null`. The
 * generic C++ runtime spells a *model* string's absence as `""` (SpecClass
 * carries `std::string mapsTo`, not an optional), but a query cannot do the
 * same: `sectionIdPrefix: ""` is a real filter that every node with any section
 * id passes, and it must stay distinguishable from "no prefix filter". So the
 * query's dimensions are std::optional and the model's `""` is mapped to
 * std::nullopt at the one place the two meet.
 *
 * ## Ownership
 *
 * A SpecQueryEngine *borrows* its model and document — both must outlive it, and
 * the document is read through the borrow on every cursor step (that is what
 * makes the cursor see edits). A SpecQueryCursor in turn borrows its engine.
 */
#ifndef SPEC_QUERY_HPP
#define SPEC_QUERY_HPP

#include <cstddef>
#include <optional>
#include <set>
#include <string>
#include <vector>

#include "spec_document.hpp"
#include "spec_model.hpp"
#include "spec_reflection.hpp"
#include "spec_text_pattern.hpp"

namespace som {

/* Whether a node currently holds a value, used by the `state` dimension. */
enum class SpecStateFilter {
  /* The node (and everything beneath it) holds no value. */
  Empty,
  /* The node holds at least one value at or beneath its path. */
  NonEmpty,
};

/* A flat, value-bearing projection of one document node — everything the tier-1
 * structural/lexical index (`llm_and_d4rt_tools.md` §9.2) needs to index a
 * section **without re-walking the model itself**: its path, kind, class, the
 * structural facets (section id, `@MapsTo` / `@DetailedIn`), the headline, the
 * searchable strings (stored values + headline), and whether it currently holds
 * a value.
 *
 * Produced by SpecQueryEngine::projectNodes / SpecQueryEngine::projectNode,
 * which reuse the same structural-closure walk and value-extraction the live
 * query uses — so the index and the live llm_and_d4rt_tools.md §6 search agree
 * on what a node is and what text it carries — with no model (LLM) calls. */
struct SpecNodeProjection {
  /* The globally-unique section-id path the node lives at. */
  std::string path;
  /* What kind of node the path lands on (one of kSpecNodeKind*). */
  std::string kind;
  /* The model class the node *is* (unset for value leaves and list
   * containers). */
  std::optional<std::string> classId;
  /* The node's `@SectionId` (field, class, or root), unset when none. */
  std::optional<std::string> sectionId;
  /* The `@MapsTo` target on the node's class, unset when none. */
  std::optional<std::string> mapsTo;
  /* The `@DetailedIn` target on the node's class, unset when none. */
  std::optional<std::string> detailedIn;
  /* The node's headline — the stored one when the author set it, else the
   * model's doc comment. Unset when neither exists. */
  std::optional<std::string> headline;
  /* The strings a text search indexes for this node: stored values (content,
   * scalar item, every form-field value) followed by the headline. Empty for a
   * container node that carries no direct value and has no headline. */
  std::vector<std::string> searchableStrings;
  /* Whether the node (or anything beneath it) currently holds a value — the
   * `state` facet (empty vs non-empty). */
  bool hasValue = false;

  /* Renders as `SpecNodeProjection(path, kind)`. */
  std::string display() const;
};

/* One node matched by a SpecQuery (the llm_and_d4rt_tools.md §6 cursor
 * record). */
struct SpecQueryMatch {
  /* The globally-unique section-ID path the node lives at. */
  std::string path;
  /* What kind of node the path lands on (one of kSpecNodeKind*). */
  std::string kind;
  /* The model class the node *is* (unset for value leaves and list
   * containers). */
  std::optional<std::string> classId;
  /* The node's headline — stored if the author set one, else the model's doc
   * comment (unset when neither exists). */
  std::optional<std::string> headline;
  /* The matched text, when the query carried a `text` dimension (unset
   * otherwise) — the value/headline that the pattern hit. */
  std::optional<std::string> snippet;
  /* The spans within `snippet` the `text` pattern matched (empty for non-text
   * queries). */
  std::vector<SpecMatchSpan> matchSpans;

  /* Renders as `SpecQueryMatch(path, kind)`. */
  std::string display() const;
};

/* An AND-combined lexical/structural query (llm_and_d4rt_tools.md §6). Every
 * supplied dimension must hold for a node to match; an all-unset query matches
 * every node in the document's structural closure. */
struct SpecQuery {
  /* Substring (or `regex` pattern) to find in content + form values and the
   * headline. */
  std::optional<std::string> text;
  /* Treat `text` as a SomTextPattern — the portable pattern subset (`.`, `*`,
   * `+`, `?`, `[…]`, `^`, `$`) — instead of a literal substring. Named `regex`
   * because that is what a caller reaches for it expecting; the grammar is
   * deliberately narrower than a full regex, and SomPatternError says so rather
   * than silently reinterpreting. */
  bool regex = false;
  /* Match `text` case-insensitively. */
  bool caseInsensitive = false;
  /* The node kinds to include (any-of); unset admits every kind. */
  std::optional<std::set<std::string>> kinds;
  /* The model class name a node must *be* (SpecResolution::targetClass). */
  std::optional<std::string> className;
  /* The node's `@SectionId` must equal this exactly. */
  std::optional<std::string> sectionIdExact;
  /* The node's `@SectionId` must start with this prefix. */
  std::optional<std::string> sectionIdPrefix;
  /* A glob over the node's path (`*` matches within one segment, `**` across
   * segments). */
  std::optional<std::string> pathGlob;
  /* The node's class must carry `@MapsTo(<this>)`. */
  std::optional<std::string> mapsTo;
  /* The node's class must carry `@DetailedIn(<this>)`. */
  std::optional<std::string> detailedIn;
  /* The node's value-presence state must match this. */
  std::optional<SpecStateFilter> state;
};

class SpecQueryCursor;

/* Runs SpecQuerys over a (SpecModel, SpecDocument) pair, producing
 * SpecQueryCursors. Both are borrowed — they must outlive the engine, and the
 * engine must outlive every cursor it hands out. */
class SpecQueryEngine {
 public:
  SpecQueryEngine(const SpecModel& model, const SpecDocument& document)
      : model_(&model), document_(&document), reflection_(model) {}

  const SpecModel& model() const { return *model_; }
  const SpecDocument& document() const { return *document_; }

  /* Builds a cursor over the nodes matching `q`. The structural candidate set
   * is computed now (document order); value-dependent filters and path liveness
   * are re-checked as the cursor advances.
   *
   * Throws SomPatternError when `q.regex` is set and `q.text` is not in the
   * portable subset. The pattern is compiled **here**, not on first use, for two
   * reasons: a malformed pattern is the caller's mistake and should surface at
   * the call that made it, and a cursor that happens to visit no candidate would
   * otherwise swallow the error entirely. */
  SpecQueryCursor query(const SpecQuery& q) const;

  // --- flat node projection (tier-1 index source) --------------------------

  /* Projects every indexable node of the live document (the
   * llm_and_d4rt_tools.md §6 structural closure) as a flat SpecNodeProjection,
   * in document order. Reuses the same walk and value extraction the query uses,
   * so the index built from these projections and the live
   * llm_and_d4rt_tools.md §6 search agree on what a node is and what text it
   * carries. Pure object-model traversal — no model (LLM) calls. */
  std::vector<SpecNodeProjection> projectNodes() const;

  /* Projects the single node at `path`, or std::nullopt when the path no longer
   * resolves against the model. Used for the index's incremental refresh: a
   * caller re-projects only the changed section paths. */
  std::optional<SpecNodeProjection> projectNode(const std::string& path) const;

  /* Every addressable node of the document in document order: the root, each
   * singular complex/section node on the spine (bounded by cycle detection),
   * each list container, each *existing* list item, and every declared leaf. */
  std::vector<std::string> enumeratePaths() const;

 private:
  friend class SpecQueryCursor;

  void walk(const std::string& path, const SpecClass* cls,
            std::set<std::string> ancestorTypes,
            std::vector<std::string>& out) const;

  /* The model-fixed dimensions (kind / class / id / path / mapsTo /
   * detailedIn). */
  bool matchesStructural(const SpecQuery& q,
                         const SpecResolution& resolution) const;

  /* The value-reading dimensions (text / state), re-evaluated against the live
   * document. Writes the built match (with snippet/spans) and returns true, or
   * returns false when the node no longer satisfies the query. Assumes the path
   * is structurally valid. */
  bool evaluateLive(const SpecQuery& q, const SomTextPattern* pattern,
                    const std::string& path, SpecQueryMatch* out) const;

  /* The strings a `text` query searches at `resolution`: stored values first
   * (content leaf, scalar list item, every form field), then the node's
   * headline. */
  std::vector<std::string> searchableStrings(
      const SpecResolution& resolution) const;

  /* Whether `path` still exists in the live document: every `-<seq>` list-item
   * segment must still be present in its parent list. Model-fixed segments
   * (root, complex/section, declared leaves) are always structurally live, so
   * only list items can go stale (via SpecDocument::removeListItem). */
  bool isLivePath(const std::string& path) const;

  std::optional<std::string> sectionIdOf(const SpecResolution& r) const;
  /* The headline a node actually shows: the document's **stored** headline when
   * the author set one, otherwise the model's doc comment.
   *
   * The stored value comes first because it is the one a reader sees and the one
   * an author would search for. Consulting only the doc comment made renamed
   * sections unfindable — `setHeadline("DEMO/SUM", "Executive Summary")` stored
   * text that no query could reach and that never entered the search index built
   * from projectNodes. */
  std::optional<std::string> headlineOf(const SpecResolution& r) const;

  const SpecModel* model_;
  const SpecDocument* document_;
  SpecReflection reflection_;
};

/* Glob match over a whole path: `**` spans `/`, a single `*` stays within one
 * segment, every other character is literal.
 *
 * Matched directly rather than compiled to a regex, because two of the nine
 * runtimes have no regex engine and because a wildcard walk is a smaller, more
 * obviously identical thing to transcribe than an escaping rule plus somebody
 * else's matcher (see SomTextPattern). */
bool specGlobMatches(const std::string& glob, const std::string& path);

/* A lazy, forward-only cursor over the nodes matching a SpecQuery
 * (llm_and_d4rt_tools.md §6).
 *
 * The cursor holds the structural candidate paths captured when it was created;
 * each step re-validates the path against the **live** document and re-applies
 * the value-dependent filters, so concurrent edits never surface stale or
 * newly-mismatching results. It is forward-only: `next` / `take` consume
 * matches; `count` peeks the remaining matches without consuming. */
class SpecQueryCursor {
 public:
  /* The next matching node, or std::nullopt when the cursor is exhausted. Skips
   * candidates whose path went stale or no longer satisfies the live filters. */
  std::optional<SpecQueryMatch> next();

  /* Up to `n` further matches (fewer when the cursor is exhausted first). */
  std::vector<SpecQueryMatch> take(long long n);

  /* Every remaining match, draining the cursor. */
  std::vector<SpecQueryMatch> toList();

  /* How many matches remain from the current position, without consuming any.
   * Re-validates each remaining candidate against the live document, so the
   * count reflects the document as it is *now*. */
  long long count() const;

 private:
  friend class SpecQueryEngine;

  SpecQueryCursor(const SpecQueryEngine& engine, SpecQuery query,
                  std::optional<SomTextPattern> pattern,
                  std::vector<std::string> candidatePaths)
      : engine_(&engine),
        query_(std::move(query)),
        pattern_(std::move(pattern)),
        candidatePaths_(std::move(candidatePaths)) {}

  const SpecQueryEngine* engine_;
  SpecQuery query_;
  /* The query's `text` dimension, compiled once when the cursor was built.
   * Unset when the query has no text dimension at all. */
  std::optional<SomTextPattern> pattern_;
  std::vector<std::string> candidatePaths_;
  std::size_t position_ = 0;
};

}  // namespace som

#endif  // SPEC_QUERY_HPP
