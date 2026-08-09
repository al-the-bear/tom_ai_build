/* Idiomatic-C++ port of the Dart `spec_query` library. */
#include "spec_query.hpp"

#include "spec_paths.hpp"

namespace som {
namespace {

/* The model spells an absent string as `""`; the query surface spells it as
 * std::nullopt (see the header's "Absent vs. empty"). This is the one place the
 * two meet. */
std::optional<std::string> optStr(const std::string& s) {
  if (s.empty()) {
    return std::nullopt;
  }
  return s;
}

constexpr char16_t kAsterisk = 0x2A;  // *
constexpr char16_t kSlash = 0x2F;     // /

/* Greedy wildcard walk with backtracking: at a `*`/`**` try the longest
 * remaining span first and give characters back until the tail fits. */
bool globAt(const std::u16string& glob, std::size_t g,
            const std::u16string& path, std::size_t p) {
  while (g < glob.size()) {
    if (glob[g] != kAsterisk) {
      if (p >= path.size() || path[p] != glob[g]) {
        return false;
      }
      g++;
      p++;
      continue;
    }
    const bool crossesSegments = g + 1 < glob.size() && glob[g + 1] == kAsterisk;
    const std::size_t afterWildcard = g + (crossesSegments ? 2 : 1);
    // Longest first, so `*` behaves greedily exactly as the regex did.
    std::size_t limit = path.size();
    if (!crossesSegments) {
      for (std::size_t i = p; i < path.size(); i++) {
        if (path[i] == kSlash) {
          limit = i;
          break;
        }
      }
    }
    for (std::size_t take = limit + 1; take-- > p;) {
      if (globAt(glob, afterWildcard, path, take)) {
        return true;
      }
    }
    return false;
  }
  return p == path.size();
}

}  // namespace

std::string SpecNodeProjection::display() const {
  return "SpecNodeProjection(" + path + ", " + kind + ")";
}

std::string SpecQueryMatch::display() const {
  return "SpecQueryMatch(" + path + ", " + kind + ")";
}

bool specGlobMatches(const std::string& glob, const std::string& path) {
  return globAt(somUtf16Units(glob), 0, somUtf16Units(path), 0);
}

// --- structural-closure enumeration ----------------------------------------

std::vector<std::string> SpecQueryEngine::enumeratePaths() const {
  std::vector<std::string> out;
  for (const SpecRoot& root : model_->roots) {
    const std::string segment = SpecReflection::rootSegment(root);
    walk(segment, model_->classNamed(root.type), {root.type}, out);
  }
  return out;
}

void SpecQueryEngine::walk(const std::string& path, const SpecClass* cls,
                           std::set<std::string> ancestorTypes,
                           std::vector<std::string>& out) const {
  out.push_back(path);  // the node itself (root / complex / section container)
  if (cls == nullptr) {
    return;
  }
  for (const SpecField& field : cls->fields) {
    const std::string fieldPath =
        specPathJoin(path, SpecReflection::fieldSegment(field));
    if (field.kind == kSpecFieldKindContent ||
        field.kind == kSpecFieldKindEnum ||
        field.kind == kSpecFieldKindScalar ||
        field.kind == kSpecFieldKindForm) {
      out.push_back(fieldPath);  // a value leaf
    } else if (field.kind == kSpecFieldKindList) {
      out.push_back(fieldPath);  // the list container node
      for (const std::string& itemPath : document_->listItems(fieldPath)) {
        if (field.elementIsComplex && !field.elementType.empty() &&
            ancestorTypes.count(field.elementType) == 0) {
          std::set<std::string> nested = ancestorTypes;
          nested.insert(field.elementType);
          walk(itemPath, model_->classNamed(field.elementType),
               std::move(nested), out);
        } else {
          // scalar item, or a recursive/unknown element
          out.push_back(itemPath);
        }
      }
    } else {  // complex / section
      if (!field.type.empty() && ancestorTypes.count(field.type) == 0) {
        std::set<std::string> nested = ancestorTypes;
        nested.insert(field.type);
        walk(fieldPath, model_->classNamed(field.type), std::move(nested), out);
      } else {
        out.push_back(fieldPath);  // recursive/unknown target: a terminal node
      }
    }
  }
}

// --- flat node projection ---------------------------------------------------

std::vector<SpecNodeProjection> SpecQueryEngine::projectNodes() const {
  std::vector<SpecNodeProjection> out;
  for (const std::string& path : enumeratePaths()) {
    std::optional<SpecNodeProjection> projection = projectNode(path);
    if (projection.has_value()) {
      out.push_back(std::move(*projection));
    }
  }
  return out;
}

std::optional<SpecNodeProjection> SpecQueryEngine::projectNode(
    const std::string& path) const {
  std::optional<SpecResolution> resolution = reflection_.resolve(path);
  if (!resolution.has_value()) {
    return std::nullopt;
  }
  SpecNodeProjection p;
  p.path = path;
  p.kind = resolution->kind;
  if (resolution->targetClass != nullptr) {
    p.classId = resolution->targetClass->name;
    p.mapsTo = optStr(resolution->targetClass->mapsTo);
    p.detailedIn = optStr(resolution->targetClass->detailedIn);
  }
  p.sectionId = sectionIdOf(*resolution);
  p.headline = headlineOf(*resolution);
  p.searchableStrings = searchableStrings(*resolution);
  p.hasValue = document_->hasValuesUnder(path);
  return p;
}

// --- query ------------------------------------------------------------------

SpecQueryCursor SpecQueryEngine::query(const SpecQuery& q) const {
  std::optional<SomTextPattern> pattern;
  if (q.text.has_value()) {
    pattern = q.regex ? SomTextPattern::compile(*q.text, q.caseInsensitive)
                      : SomTextPattern::literal(*q.text, q.caseInsensitive);
  }
  std::vector<std::string> candidates;
  for (const std::string& path : enumeratePaths()) {
    std::optional<SpecResolution> resolution = reflection_.resolve(path);
    if (!resolution.has_value()) {
      continue;
    }
    if (matchesStructural(q, *resolution)) {
      candidates.push_back(path);
    }
  }
  return SpecQueryCursor(*this, q, std::move(pattern), std::move(candidates));
}

// --- predicates -------------------------------------------------------------

bool SpecQueryEngine::matchesStructural(const SpecQuery& q,
                                        const SpecResolution& r) const {
  if (q.kinds.has_value() && q.kinds->count(r.kind) == 0) {
    return false;
  }
  if (q.className.has_value()) {
    if (r.targetClass == nullptr || r.targetClass->name != *q.className) {
      return false;
    }
  }

  const std::optional<std::string> sectionId = sectionIdOf(r);
  if (q.sectionIdExact.has_value() && sectionId != q.sectionIdExact) {
    return false;
  }
  if (q.sectionIdPrefix.has_value()) {
    const std::string& prefix = *q.sectionIdPrefix;
    if (!sectionId.has_value() || sectionId->size() < prefix.size() ||
        sectionId->compare(0, prefix.size(), prefix) != 0) {
      return false;
    }
  }
  if (q.pathGlob.has_value() && !specGlobMatches(*q.pathGlob, r.path)) {
    return false;
  }
  if (q.mapsTo.has_value()) {
    const std::optional<std::string> mapsTo =
        r.targetClass == nullptr ? std::nullopt : optStr(r.targetClass->mapsTo);
    if (mapsTo != q.mapsTo) {
      return false;
    }
  }
  if (q.detailedIn.has_value()) {
    const std::optional<std::string> detailedIn =
        r.targetClass == nullptr ? std::nullopt
                                 : optStr(r.targetClass->detailedIn);
    if (detailedIn != q.detailedIn) {
      return false;
    }
  }
  return true;
}

bool SpecQueryEngine::evaluateLive(const SpecQuery& q,
                                   const SomTextPattern* pattern,
                                   const std::string& path,
                                   SpecQueryMatch* out) const {
  if (!isLivePath(path)) {
    return false;
  }
  std::optional<SpecResolution> resolution = reflection_.resolve(path);
  if (!resolution.has_value()) {
    return false;
  }

  if (q.state.has_value()) {
    const bool hasValue = document_->hasValuesUnder(path);
    const bool wantValue = *q.state == SpecStateFilter::NonEmpty;
    if (hasValue != wantValue) {
      return false;
    }
  }

  std::optional<std::string> snippet;
  std::vector<SpecMatchSpan> spans;
  if (pattern != nullptr) {
    // Search each candidate string in turn; the first that hits wins, so the
    // snippet is the actual text the pattern matched.
    bool hit = false;
    for (const std::string& text : searchableStrings(*resolution)) {
      std::vector<SpecMatchSpan> found = pattern->allMatches(text);
      if (!found.empty()) {
        snippet = text;
        spans = std::move(found);
        hit = true;
        break;
      }
    }
    if (!hit) {
      return false;
    }
  }

  if (out != nullptr) {
    out->path = path;
    out->kind = resolution->kind;
    out->classId = resolution->targetClass == nullptr
                       ? std::nullopt
                       : std::optional<std::string>(resolution->targetClass->name);
    out->headline = headlineOf(*resolution);
    out->snippet = std::move(snippet);
    out->matchSpans = std::move(spans);
  }
  return true;
}

std::vector<std::string> SpecQueryEngine::searchableStrings(
    const SpecResolution& r) const {
  std::vector<std::string> out;
  const std::string& path = r.path;
  if (r.kind == kSpecNodeKindContent || r.kind == kSpecNodeKindEnumValue ||
      r.kind == kSpecNodeKindScalar || r.kind == kSpecNodeKindListItemScalar) {
    const std::string* value = document_->contentOpt(path);
    if (value != nullptr) {
      out.push_back(*value);
    }
  } else if (r.kind == kSpecNodeKindForm) {
    /* Dart iterates `document.formFieldNames(path)`, whose order is the order
     * the author called `setFormField` in. C++'s store is a byte-sorted
     * std::map, so reproducing that literally would reorder the snippets. The
     * *model* carries the only order that is a property of the document rather
     * than of how it happened to be built — the field's declaration order — and
     * that is what the corpus records, so it is what is replayed here. Stored
     * names the model does not declare keep their (byte-sorted) store order at
     * the end, since nothing else orders them. */
    std::vector<std::string> stored = document_->formFieldNames(path);
    std::vector<bool> taken(stored.size(), false);
    if (r.field != nullptr) {
      for (const FormFieldSpec& spec : r.field->formFields) {
        for (std::size_t i = 0; i < stored.size(); i++) {
          if (taken[i] || stored[i] != spec.name) {
            continue;
          }
          taken[i] = true;
          const std::string* value = document_->formFieldOpt(path, stored[i]);
          if (value != nullptr) {
            out.push_back(*value);
          }
          break;
        }
      }
    }
    for (std::size_t i = 0; i < stored.size(); i++) {
      if (taken[i]) {
        continue;
      }
      const std::string* value = document_->formFieldOpt(path, stored[i]);
      if (value != nullptr) {
        out.push_back(*value);
      }
    }
  }
  // root / complex / section / list / listItemComplex carry no direct value.

  const std::optional<std::string> headline = headlineOf(r);
  if (headline.has_value()) {
    out.push_back(*headline);
  }
  return out;
}

// --- path liveness (cursor stability) ---------------------------------------

bool SpecQueryEngine::isLivePath(const std::string& path) const {
  const std::vector<std::string> segments = specPathSegments(path);
  std::string prefix;
  for (std::size_t i = 0; i < segments.size(); i++) {
    const std::string previous = prefix;
    prefix = i == 0 ? segments[i] : specPathJoin(prefix, segments[i]);
    std::string base;
    long long seq = 0;
    if (!specSplitListItemSegment(segments[i], &base, &seq)) {
      continue;
    }
    const std::string listPath = i == 0 ? base : specPathJoin(previous, base);
    std::optional<SpecResolution> resolution = reflection_.resolve(listPath);
    if (resolution.has_value() && resolution->kind == kSpecNodeKindList) {
      const std::vector<std::string> items = document_->listItems(listPath);
      bool found = false;
      for (const std::string& item : items) {
        if (item == prefix) {
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }
  }
  return true;
}

// --- node descriptors --------------------------------------------------------

std::optional<std::string> SpecQueryEngine::sectionIdOf(
    const SpecResolution& r) const {
  if (r.field != nullptr && !r.field->sectionId.empty()) {
    return r.field->sectionId;
  }
  if (r.targetClass != nullptr && !r.targetClass->sectionId.empty()) {
    return r.targetClass->sectionId;
  }
  if (r.root != nullptr) {
    return optStr(r.root->sectionId);
  }
  return std::nullopt;
}

std::optional<std::string> SpecQueryEngine::headlineOf(
    const SpecResolution& r) const {
  const std::string* stored = document_->headlineOpt(r.path);
  if (stored != nullptr) {
    return *stored;
  }
  if (r.field != nullptr && !r.field->doc.empty()) {
    return r.field->doc;
  }
  if (r.targetClass != nullptr && !r.targetClass->doc.empty()) {
    return r.targetClass->doc;
  }
  if (r.kind == kSpecNodeKindRoot && r.root != nullptr) {
    return optStr(r.root->description);
  }
  return std::nullopt;
}

// --- cursor ------------------------------------------------------------------

std::optional<SpecQueryMatch> SpecQueryCursor::next() {
  while (position_ < candidatePaths_.size()) {
    const std::string path = candidatePaths_[position_++];
    SpecQueryMatch match;
    if (engine_->evaluateLive(query_,
                              pattern_.has_value() ? &*pattern_ : nullptr, path,
                              &match)) {
      return match;
    }
  }
  return std::nullopt;
}

std::vector<SpecQueryMatch> SpecQueryCursor::take(long long n) {
  std::vector<SpecQueryMatch> out;
  for (long long i = 0; i < n; i++) {
    std::optional<SpecQueryMatch> match = next();
    if (!match.has_value()) {
      break;
    }
    out.push_back(std::move(*match));
  }
  return out;
}

std::vector<SpecQueryMatch> SpecQueryCursor::toList() {
  std::vector<SpecQueryMatch> out;
  for (;;) {
    std::optional<SpecQueryMatch> match = next();
    if (!match.has_value()) {
      break;
    }
    out.push_back(std::move(*match));
  }
  return out;
}

long long SpecQueryCursor::count() const {
  long long remaining = 0;
  for (std::size_t i = position_; i < candidatePaths_.size(); i++) {
    if (engine_->evaluateLive(query_,
                              pattern_.has_value() ? &*pattern_ : nullptr,
                              candidatePaths_[i], nullptr)) {
      remaining++;
    }
  }
  return remaining;
}

}  // namespace som
