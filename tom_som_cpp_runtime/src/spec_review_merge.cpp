/* spec_review_merge — merging reviewed copies (SOM §11.9.9), an idiomatic-C++
 * port of the TypeScript `spec_review_merge.ts`. See the header for the
 * contract. */
#include "spec_review_merge.hpp"

#include <algorithm>
#include <cstdlib>
#include <map>
#include <memory>
#include <set>
#include <tuple>

#include "som_json.hpp"
#include "spec_document_markdown.hpp"
#include "spec_paths.hpp"
#include "spec_reflection.hpp"
#include "spec_section_id.hpp"

namespace som {

using review_internal::decideReviewMarks;
using review_internal::ReviewMark;
using review_internal::reviewMarks;
using review_internal::ReviewPiece;
using review_internal::reviewPieces;
using review_internal::withAttribution;

/* ---- the report's JSON ----------------------------------------------------
 */

namespace {

std::string jsonOptStr(const std::optional<std::string>& v) {
  return v ? jsonEncodeStr(*v) : "null";
}

std::string jsonStrs(const std::vector<std::string>& v) {
  std::string b = "[";
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) b += ",";
    b += jsonEncodeStr(v[i]);
  }
  return b + "]";
}

/* `[f(x) for x in v]` joined as a JSON array. */
template <class T, class F>
std::string jsonArray(const std::vector<T>& v, F f) {
  std::string b = "[";
  for (std::size_t i = 0; i < v.size(); i++) {
    if (i > 0) b += ",";
    b += f(v[i]);
  }
  return b + "]";
}

std::string memberJson(const SpecReviewMember& m) {
  return "\"memberId\":" + jsonEncodeStr(m.memberId) +
         ",\"displayName\":" + jsonEncodeStr(m.displayName) +
         ",\"role\":" + jsonEncodeStr(m.role);
}

}  // namespace

std::string SpecReviewMergeReport::toJson() const {
  std::string b =
      "{\"reviewers\":" + jsonArray(reviewers, [](const SpecMergeReviewer& r) {
        return "{" + memberJson(r.member) +
               ",\"guest\":" + (r.guest ? "true" : "false") + "}";
      });
  b += ",\"conflicts\":" + jsonArray(conflicts, [](const SpecMergeConflict& c) {
         return "{\"id\":" + jsonEncodeStr(c.id) +
                ",\"path\":" + jsonEncodeStr(c.path) +
                ",\"field\":" + jsonOptStr(c.field) + ",\"paragraph\":" +
                (c.paragraph ? std::to_string(*c.paragraph) : "null") +
                ",\"members\":" + jsonStrs(c.members) + "}";
       });
  b += ",\"votes\":" + jsonArray(votes, [](const SpecMergeVotes& v) {
         return "{\"path\":" + jsonEncodeStr(v.path) +
                ",\"field\":" + jsonOptStr(v.field) +
                ",\"markup\":" + jsonEncodeStr(v.markup) + ",\"votes\":" +
                jsonArray(v.votes,
                          [](const SpecMarkVote& x) { return x.toJson(); }) +
                "}";
       });
  b +=
      ",\"unanimous\":" + jsonArray(unanimous, [](const SpecMergeUnanimous& u) {
        return "{\"path\":" + jsonEncodeStr(u.path) +
               ",\"field\":" + jsonOptStr(u.field) +
               ",\"markup\":" + jsonEncodeStr(u.markup) + ",\"decision\":" +
               jsonEncodeStr(u.accept ? "accept" : "reject") +
               ",\"result\":" + jsonEncodeStr(u.result) + "}";
      });
  b += ",\"answers\":" + jsonArray(answers, [](const SpecMergeAnswers& a) {
         return "{\"questionId\":" + jsonEncodeStr(a.questionId) +
                ",\"members\":" + jsonStrs(a.members) + "}";
       });
  b += ",\"comments\":" + jsonArray(comments, [](const SpecMergeComment& c) {
         return "{\"id\":" + jsonEncodeStr(c.id) +
                ",\"author\":" + jsonEncodeStr(c.author) +
                ",\"path\":" + jsonEncodeStr(c.path) +
                ",\"field\":" + jsonOptStr(c.field) + "}";
       });
  b += ",\"additions\":" + jsonArray(additions, [](const SpecMergeAddition& a) {
         return "{\"path\":" + jsonEncodeStr(a.path) +
                ",\"members\":" + jsonStrs(a.members) + "}";
       });
  b += ",\"guestQuestions\":" +
       jsonArray(guestQuestions, [](const SpecMergeGuestQuestion& g) {
         return "{\"id\":" + jsonEncodeStr(g.id) +
                ",\"memberId\":" + jsonEncodeStr(g.memberId) +
                ",\"path\":" + jsonOptStr(g.path) + "}";
       });
  b += ",\"revision\":" +
       (revision ? "{\"path\":" + jsonEncodeStr(revision->path) +
                       ",\"version\":" + jsonEncodeStr(revision->version) + "}"
                 : std::string("null"));
  return b + "}";
}

namespace {

/* ---- small text helpers ---------------------------------------------------
 */

bool startsWith(const std::string& s, const std::string& p) {
  return s.size() >= p.size() && s.compare(0, p.size(), p) == 0;
}

std::vector<std::string> splitOn(const std::string& s, const std::string& sep) {
  std::vector<std::string> out;
  std::size_t from = 0;
  while (true) {
    const std::size_t at = s.find(sep, from);
    if (at == std::string::npos) {
      out.push_back(s.substr(from));
      return out;
    }
    out.push_back(s.substr(from, at - from));
    from = at + sep.size();
  }
}

std::string joinOn(const std::vector<std::string>& v, const std::string& sep,
                   std::size_t from = 0, std::size_t to = std::string::npos) {
  std::string out;
  if (to > v.size()) to = v.size();
  for (std::size_t k = from; k < to; k++) {
    if (k > from) out += sep;
    out += v[k];
  }
  return out;
}

bool isSpaceByte(char c) {
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' ||
         c == '\f';
}

/* `s` trimmed of ASCII whitespace (the text the merge compares is ASCII at its
 * edges in every case it decides on). */
std::string trimText(const std::string& s) {
  std::size_t a = 0, b = s.size();
  while (a < b && isSpaceByte(s[a])) a++;
  while (b > a && isSpaceByte(s[b - 1])) b--;
  return s.substr(a, b - a);
}

bool contains(const std::vector<std::string>& v, const std::string& x) {
  return std::find(v.begin(), v.end(), x) != v.end();
}

long long indexOf(const std::vector<std::string>& v, const std::string& x) {
  const auto it = std::find(v.begin(), v.end(), x);
  return it == v.end() ? -1 : static_cast<long long>(it - v.begin());
}

/* Whether `path` is `item` or lies under it. */
bool under(const std::string& path, const std::string& item) {
  return path == item || startsWith(path, item + "/");
}

std::string fieldSuffix(const std::optional<std::string>& field) {
  return field ? " " + *field : "";
}

/* ---- the engine: one value at a time ------------------------------------- */

/* Ids the merge writes before it can number them: renumbered in merged
 * document order at the end. A placeholder is `\x01<kind><n>\x01`. */
const char kPlaceholderMark = '\x01';

/* One value to merge, located in the merged document. */
struct MergeValue {
  std::string path;
  std::optional<std::string> field;
  std::string base;
  /* Per copy, in round order; nullopt when the copy holds no such value (it
   * removed the item). */
  std::vector<std::optional<std::string>> copies;
  /* A typed leaf (number, bool, enum, code): never marked, any change is a
   * conflict. */
  bool typed = false;
  /* Where a conflict about a form field or a typed leaf goes; nullopt for a
   * content value. */
  std::optional<std::string> conflictHome;
};

/* What one copy did to one unit (SOM §11.9.9, steps 1–4). */
struct UnitReading {
  bool changed = false;
  std::string t;        // the reviewer's text
  std::string written;  // the change as it is written into the merged document
  /* The copy's votes, by the index of the base unit's mark: accept (true) or
   * reject. */
  std::map<std::size_t, bool> votes;
};

using Readings = std::vector<std::optional<UnitReading>>;

/* The changed readings grouped by their text `t`, in order of first
 * appearance. */
struct ChangeGroup {
  std::string text;
  std::vector<std::string> members;
  const UnitReading* first = nullptr;
};

/* The state one merge carries from value to value. */
class MergeContext {
 public:
  SpecReviewMergeReport report;
  /* Blocks to append to the end of a value, by its key. */
  std::map<std::string, std::vector<std::string>> appends;
  std::vector<std::string> members;
  /* Placeholder → report entry, filled in when the ids are numbered. */
  std::map<std::string, SpecMergeConflict> pendingConflicts;
  std::map<std::string, SpecMergeComment> pendingComments;
  std::set<std::string> baseCommentIds;
  std::set<std::string> baseQuestionIds;

  MergeContext(const std::vector<SpecReviewMember>& copies,
               std::set<std::string> comments, std::set<std::string> questions)
      : baseCommentIds(std::move(comments)),
        baseQuestionIds(std::move(questions)) {
    for (const SpecReviewMember& c : copies) members.push_back(c.memberId);
  }

  std::string placeholder(char kind) {
    return std::string(1, kPlaceholderMark) + kind + std::to_string(++next_) +
           kPlaceholderMark;
  }

  void append(const std::string& key, const std::string& block) {
    appends[key].push_back(block);
  }

  /* Writes a conflict block with a placeholder id and records it for the
   * report. */
  std::string conflict(const std::string& topic, const std::string& text,
                       const std::string& base,
                       const std::vector<ChangeGroup>& groups,
                       const std::string& path,
                       const std::optional<std::string>& field,
                       std::optional<std::size_t> paragraph) {
    const std::string id = placeholder('X');
    SpecMergeConflict entry{id, path, field, paragraph, {}};
    std::vector<SpecConflictAlternative> alternatives;
    for (std::size_t k = 0; k < groups.size(); k++) {
      entry.members.insert(entry.members.end(), groups[k].members.begin(),
                           groups[k].members.end());
      alternatives.push_back({std::string(1, static_cast<char>('a' + k)),
                              groups[k].members, groups[k].text});
    }
    pendingConflicts[id] = entry;
    return joinOn(formatConflictBlock(id, topic, text, base, alternatives),
                  "\n");
  }

 private:
  std::size_t next_ = 0;
};

std::vector<ChangeGroup> changeGroups(const Readings& readings,
                                      const std::vector<std::string>& members) {
  std::vector<ChangeGroup> groups;
  for (std::size_t k = 0; k < readings.size(); k++) {
    if (!readings[k] || !readings[k]->changed) continue;
    auto g = std::find_if(
        groups.begin(), groups.end(),
        [&](const ChangeGroup& x) { return x.text == readings[k]->t; });
    if (g == groups.end()) {
      groups.push_back({readings[k]->t, {members[k]}, &*readings[k]});
    } else {
      g->members.push_back(members[k]);
    }
  }
  return groups;
}

/* Aligns two mark lists by their markup (longest common subsequence): index
 * in `a` → index in `b`. */
std::map<std::size_t, std::size_t> alignMarks(
    const std::vector<ReviewMark>& a, const std::vector<ReviewMark>& b) {
  const std::size_t n = a.size(), m = b.size();
  std::vector<std::vector<std::size_t>> l(n + 1,
                                          std::vector<std::size_t>(m + 1, 0));
  for (std::size_t i = n; i-- > 0;) {
    for (std::size_t j = m; j-- > 0;) {
      l[i][j] = a[i].markup == b[j].markup ? l[i + 1][j + 1] + 1
                                           : std::max(l[i + 1][j], l[i][j + 1]);
    }
  }
  std::map<std::size_t, std::size_t> out;
  std::size_t i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i].markup == b[j].markup) {
      out[i++] = j++;
    } else if (l[i + 1][j] >= l[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  return out;
}

/* The most base marks a unit may have that a copy no longer holds as written:
 * the combinations of step 2 grow as 2^n. Beyond it the copy's unit is read as
 * an edit (step 4), so every runtime gives up at the same point. */
const std::size_t kMaxDecidedMarks = 16;

/* The first combination of decisions on `b`'s marks (step 2) whose result is
 * `target`, or nullopt. Each mark takes leave, accept, reject in that order,
 * the first mark varying slowest. A mark the copy still holds as written can
 * only have been left, and a mark it no longer holds cannot have been, so only
 * the others vary — the same first combination, found without trying the
 * rest. */
std::optional<std::map<std::size_t, bool>> findVotes(
    const std::string& b, std::size_t marks, const std::set<std::size_t>& left,
    const std::string& target) {
  std::vector<std::size_t> free;
  for (std::size_t i = 0; i < marks; i++) {
    if (left.count(i) == 0) free.push_back(i);
  }
  if (free.size() > kMaxDecidedMarks) return std::nullopt;
  for (unsigned long combo = 0; combo < (1UL << free.size()); combo++) {
    std::map<std::size_t, bool> decisions;
    for (std::size_t k = 0; k < free.size(); k++) {
      // Bit set: reject; the first mark is the most significant bit.
      decisions[free[k]] = ((combo >> (free.size() - 1 - k)) & 1UL) == 0;
    }
    if (decideReviewMarks(b, decisions) == target) return decisions;
  }
  return std::nullopt;
}

/* Step 4: the copy edited text that holds base marks; it casts no votes. */
UnitReading readAsEdit(const std::string& b, const std::string& c) {
  UnitReading r;
  r.t = applyInlineMarksText(c, true);
  r.changed = r.t != b;
  r.written = markChangeText(applyInlineMarksText(b, false), r.t).text;
  return r;
}

/* What copy unit `c` did to base unit `b` (SOM §11.9.9, steps 1–4). */
UnitReading readUnit(const std::string& b, const std::string& c) {
  if (c == b) return {false, b, b, {}};
  const std::vector<ReviewMark> baseMarks = reviewMarks(b);
  const std::vector<ReviewMark> copyMarks = reviewMarks(c);
  const std::map<std::size_t, std::size_t> kept =
      alignMarks(copyMarks, baseMarks);
  // 1. Own marks: the copy's marks that are not the base's.
  std::map<std::size_t, bool> reject, accept;
  for (std::size_t i = 0; i < copyMarks.size(); i++) {
    if (kept.count(i) > 0) continue;
    reject[i] = false;
    accept[i] = true;
  }
  // 2. Votes: the decisions on the base marks that give c with its own marks
  // rejected.
  const std::string cPrime = decideReviewMarks(c, reject);
  std::set<std::size_t> left;
  for (const auto& [copyIndex, baseIndex] : kept) left.insert(baseIndex);
  const auto votes = findVotes(b, baseMarks.size(), left, cPrime);
  if (!votes) return readAsEdit(b, c);
  if (accept.empty()) return {false, b, b, *votes};
  // 3. Change: the own marks, carried over to the base text where marks were
  // voted on.
  const std::string ownAccepted = decideReviewMarks(c, accept);
  const std::optional<std::string> written =
      votes->empty() ? std::optional<std::string>(c)
                     : review_internal::transplantEdits(cPrime, c, b);
  const std::optional<std::string> t =
      votes->empty() ? std::optional<std::string>(ownAccepted)
                     : review_internal::transplantEdits(cPrime, ownAccepted, b);
  if (!written || !t) return readAsEdit(b, c);
  return {*t != b, *t, *written, *votes};
}

/* `written` with every mark that is not one of the base's attributed to
 * `members`. */
std::string attribute(const std::string& written,
                      const std::vector<ReviewMark>& baseMarks,
                      const std::vector<std::string>& members) {
  const std::vector<ReviewMark> marks = reviewMarks(written);
  const std::map<std::size_t, std::size_t> base = alignMarks(marks, baseMarks);
  std::string out = written;
  for (std::size_t k = marks.size(); k-- > 0;) {
    if (base.count(k) == 0)
      out = withAttribution(out, marks[k], members, marks[k].votes);
  }
  return out;
}

bool isChange(const ReviewMark& m) {
  return m.kind == SpecMarkKind::Insertion ||
         m.kind == SpecMarkKind::Deletion ||
         m.kind == SpecMarkKind::Substitution;
}

/* `text` with the copies' votes on the base marks it holds: a base mark every
 * copy decided the same way is applied (accept) or dropped (reject); any other
 * voted change mark gets the votes in its token, `agent` as author when it had
 * no token. A highlight or comment mark takes no votes and stays. */
std::string applyVotes(const std::string& text,
                       const std::vector<ReviewMark>& baseMarks,
                       const Readings& readings, const MergeValue& v,
                       MergeContext& ctx) {
  const std::vector<ReviewMark> marks = reviewMarks(text);
  const std::map<std::size_t, std::size_t> base = alignMarks(marks, baseMarks);
  std::size_t taking = 0;
  for (const auto& r : readings) taking += r ? 1 : 0;
  std::vector<SpecMergeVotes> votes;
  std::vector<SpecMergeUnanimous> unanimous;
  std::string out = text;
  for (std::size_t k = marks.size(); k-- > 0;) {
    const auto b = base.find(k);
    if (b == base.end()) continue;
    std::vector<SpecMarkVote> cast;
    for (std::size_t i = 0; i < readings.size(); i++) {
      if (!readings[i]) continue;
      const auto d = readings[i]->votes.find(b->second);
      if (d != readings[i]->votes.end())
        cast.push_back({ctx.members[i], d->second});
    }
    if (cast.empty()) continue;
    const ReviewMark& m = marks[k];
    const bool same = std::all_of(
        cast.begin(), cast.end(),
        [&](const SpecMarkVote& x) { return x.accept == cast[0].accept; });
    if (cast.size() == taking && same) {
      const bool accept = cast[0].accept;
      out = decideReviewMarks(out, {{k, accept}});
      const ReviewMark& bm = baseMarks[b->second];
      unanimous.insert(unanimous.begin(),
                       SpecMergeUnanimous{v.path, v.field, bm.markup, accept,
                                          accept ? bm.accepted : bm.rejected});
      continue;
    }
    if (!isChange(m)) continue;
    const std::vector<std::string> authors =
        m.end > m.bodyEnd ? m.authors : std::vector<std::string>{"agent"};
    std::vector<SpecMarkVote> merged;
    for (const SpecMarkVote& x : m.votes) {
      const bool recast = std::any_of(
          cast.begin(), cast.end(),
          [&](const SpecMarkVote& y) { return y.member == x.member; });
      if (!recast) merged.push_back(x);
    }
    merged.insert(merged.end(), cast.begin(), cast.end());
    out = withAttribution(out, m, authors, merged);
    votes.insert(
        votes.begin(),
        SpecMergeVotes{v.path, v.field, reviewMarks(out)[k].markup, merged});
  }
  ctx.report.votes.insert(ctx.report.votes.end(), votes.begin(), votes.end());
  ctx.report.unanimous.insert(ctx.report.unanimous.end(), unanimous.begin(),
                              unanimous.end());
  return out;
}

/* One unit merged: the base text with votes when no copy changed it, the one
 * change attributed to every member who made it, or the base text and a
 * conflict block when the copies changed it differently. */
std::pair<std::string, std::optional<std::string>> mergeUnit(
    const std::string& b, const std::vector<std::optional<std::string>>& units,
    std::optional<std::size_t> paragraph, const MergeValue& v,
    MergeContext& ctx) {
  Readings readings;
  for (const auto& c : units) {
    readings.push_back(c ? std::optional<UnitReading>(readUnit(b, *c))
                         : std::nullopt);
  }
  const std::vector<ChangeGroup> groups = changeGroups(readings, ctx.members);
  const std::vector<ReviewMark> baseMarks = reviewMarks(b);
  std::string text = b;
  if (groups.size() == 1)
    text = attribute(groups[0].first->written, baseMarks, groups[0].members);
  text = applyVotes(text, baseMarks, readings, v, ctx);
  if (groups.size() < 2) return {text, std::nullopt};
  const std::string where = v.path + fieldSuffix(v.field);
  return {text, ctx.conflict("Conflicting changes",
                             paragraph ? where + ", paragraph " +
                                             std::to_string(*paragraph)
                                       : where,
                             b, groups, v.path, v.field, paragraph)};
}

/* A typed leaf: it cannot hold a mark, so a change by any copy is a `Value
 * changed` conflict at the leaf's home, the base value kept. */
std::string mergeTyped(const MergeValue& v, MergeContext& ctx) {
  Readings readings;
  for (const auto& c : v.copies) {
    readings.push_back(
        c ? std::optional<UnitReading>(UnitReading{*c != v.base, *c, *c, {}})
          : std::nullopt);
  }
  const std::vector<ChangeGroup> groups = changeGroups(readings, ctx.members);
  if (!groups.empty() && v.conflictHome) {
    ctx.append(*v.conflictHome,
               ctx.conflict("Value changed", v.path + fieldSuffix(v.field),
                            v.base, groups, v.path, v.field, std::nullopt));
  }
  return v.base;
}

/* A form-field value: always one unit; its conflict goes to the end of the
 * form's preamble. */
std::string mergeField(const MergeValue& v, MergeContext& ctx) {
  auto [text, conflict] = mergeUnit(v.base, v.copies, std::nullopt, v, ctx);
  if (conflict && v.conflictHome) ctx.append(*v.conflictHome, *conflict);
  return text;
}

/* Whether a copy's block is new: a comment whose id the base lacks, a question
 * block with no base question. */
bool isNewBlock(const ReviewPiece& piece, const MergeContext& ctx) {
  if (piece.kind == SpecReviewAnnotationKind::Comment) {
    return !piece.id || ctx.baseCommentIds.count(*piece.id) == 0;
  }
  if (piece.kind == SpecReviewAnnotationKind::Question) {
    return !piece.questionIds.empty() &&
           std::all_of(piece.questionIds.begin(), piece.questionIds.end(),
                       [&](const std::string& id) {
                         return ctx.baseQuestionIds.count(id) == 0;
                       });
  }
  return false;
}

/* The anchor of each block of a value: the index of the text paragraph it
 * follows (-1: before every one). In whole-value mode every block that follows
 * text follows the one unit. */
std::vector<long long> anchors(const std::vector<ReviewPiece>& pieces,
                               bool whole) {
  std::vector<long long> out;
  long long texts = -1;
  for (const ReviewPiece& p : pieces) {
    if (!p.kind) {
      out.push_back(++texts);
    } else {
      out.push_back(whole ? std::min(texts, 0LL) : texts);
    }
  }
  return out;
}

std::vector<std::string> textsOf(const std::vector<ReviewPiece>& pieces) {
  std::vector<std::string> out;
  for (const ReviewPiece& p : pieces) {
    if (!p.kind) out.push_back(p.text);
  }
  return out;
}

/* A copy's new block as merged: a comment renumbered and attributed, a
 * question as written. */
std::string newBlock(const ReviewPiece& p, const std::string& member,
                     const MergeValue& v, MergeContext& ctx) {
  if (p.kind != SpecReviewAnnotationKind::Comment) return p.text;
  const std::string id = ctx.placeholder('C');
  const std::string author = p.author.value_or(member);
  ctx.pendingComments[id] = SpecMergeComment{id, author, v.path, v.field};
  return joinOn(formatCommentBlock(id, p.commentText, author), "\n");
}

/* A content value: split into text paragraphs and annotation blocks, merged
 * unit by unit, the copies' new comments and questions placed after the unit
 * they followed. A copy whose text-paragraph count differs from the base's
 * makes the whole text one unit, for every copy. */
std::string mergeContent(const MergeValue& v, MergeContext& ctx) {
  const std::vector<ReviewPiece> basePieces = reviewPieces(v.base);
  std::vector<std::optional<std::vector<ReviewPiece>>> copyPieces;
  for (const auto& c : v.copies) {
    copyPieces.push_back(
        c ? std::optional<std::vector<ReviewPiece>>(reviewPieces(*c))
          : std::nullopt);
  }
  const std::size_t baseTextCount = textsOf(basePieces).size();
  const bool whole =
      std::any_of(copyPieces.begin(), copyPieces.end(), [&](const auto& ps) {
        return ps && textsOf(*ps).size() != baseTextCount;
      });
  auto unitsOf = [&](const std::vector<ReviewPiece>& ps) {
    const std::vector<std::string> texts = textsOf(ps);
    return whole ? std::vector<std::string>{joinOn(texts, "\n\n")} : texts;
  };
  const std::vector<std::string> baseUnits = unitsOf(basePieces);
  std::vector<std::optional<std::vector<std::string>>> copyUnits;
  for (const auto& ps : copyPieces) {
    copyUnits.push_back(
        ps ? std::optional<std::vector<std::string>>(unitsOf(*ps))
           : std::nullopt);
  }

  // Blocks by anchor: the base's first, then each copy's new ones in round
  // order.
  std::map<long long, std::vector<std::string>> after;
  const std::vector<long long> baseAnchors = anchors(basePieces, whole);
  for (std::size_t k = 0; k < basePieces.size(); k++) {
    if (basePieces[k].kind) after[baseAnchors[k]].push_back(basePieces[k].text);
  }
  for (std::size_t i = 0; i < copyPieces.size(); i++) {
    if (!copyPieces[i]) continue;
    const std::vector<ReviewPiece>& ps = *copyPieces[i];
    const std::vector<long long> at = anchors(ps, false);
    for (std::size_t k = 0; k < ps.size(); k++) {
      if (!ps[k].kind || !isNewBlock(ps[k], ctx)) continue;
      const long long anchor =
          whole ? static_cast<long long>(baseUnits.size()) - 1 : at[k];
      after[anchor].push_back(newBlock(ps[k], ctx.members[i], v, ctx));
    }
  }

  std::vector<std::string> out = after[-1];
  for (std::size_t u = 0; u < baseUnits.size(); u++) {
    std::vector<std::optional<std::string>> units;
    for (const auto& cs : copyUnits) {
      units.push_back(cs ? std::optional<std::string>((*cs)[u]) : std::nullopt);
    }
    auto [text, conflict] =
        mergeUnit(baseUnits[u], units,
                  whole ? std::nullopt : std::optional<std::size_t>(u), v, ctx);
    if (!text.empty()) out.push_back(text);
    if (conflict) out.push_back(*conflict);
    const auto& blocks = after[static_cast<long long>(u)];
    out.insert(out.end(), blocks.begin(), blocks.end());
  }
  return joinOn(out, "\n\n");
}

/* One value merged; the base text when no copy differs from it. */
std::string mergeValue(const MergeValue& v, MergeContext& ctx) {
  const bool unchanged =
      std::all_of(v.copies.begin(), v.copies.end(),
                  [&](const auto& c) { return !c || *c == v.base; });
  if (unchanged) return v.base;
  if (v.typed) return mergeTyped(v, ctx);
  if (v.field) return mergeField(v, ctx);
  return mergeContent(v, ctx);
}

/* ---- shared phases over the merged texts --------------------------------- */

/* The merged document's values, by key, in merged document order. */
class MergeTexts {
 public:
  virtual ~MergeTexts() = default;
  virtual std::vector<std::string> keys() const = 0;
  virtual std::string get(const std::string& key) const = 0;
  virtual void set(const std::string& key, const std::string& value) = 0;
};

/* Appends `block` to `value`, one blank line between them. */
std::string appendBlock(const std::string& value, const std::string& block) {
  return value.empty() ? block : value + "\n\n" + block;
}

/* Appends the collected blocks (field and structural conflicts) to the end of
 * their values. */
void applyAppends(MergeTexts& texts, const MergeContext& ctx) {
  for (const auto& [key, blocks] : ctx.appends) {
    std::string value = texts.get(key);
    for (const std::string& b : blocks) value = appendBlock(value, b);
    texts.set(key, value);
  }
}

/* The highest `<prefix>-<n>` of the texts' annotations of one kind. */
long long highestId(const std::vector<std::string>& texts,
                    const std::string& prefix, SpecReviewAnnotationKind kind) {
  long long high = 0;
  for (const std::string& t : texts) {
    for (const ReviewPiece& p : reviewPieces(t)) {
      if (p.kind != kind) continue;
      std::vector<std::string> ids = p.questionIds;
      if (kind != SpecReviewAnnotationKind::Question && p.id) ids = {*p.id};
      for (const std::string& id : ids) {
        if (!startsWith(id, prefix + "-")) continue;
        const std::string digits = id.substr(prefix.size() + 1);
        if (digits.empty() || digits[0] < '0' || digits[0] > '9') continue;
        const long long n = std::strtoll(digits.c_str(), nullptr, 10);
        if (n > high) high = n;
      }
    }
  }
  return high;
}

/* Numbers the new comments and conflicts in merged document order, above the
 * base's highest `C-<n>` and `X-<n>`, and fills their report entries in. */
void numberIds(MergeTexts& texts, const std::vector<std::string>& baseTexts,
               MergeContext& ctx) {
  long long nextC =
      highestId(baseTexts, "C", SpecReviewAnnotationKind::Comment);
  long long nextX =
      highestId(baseTexts, "X", SpecReviewAnnotationKind::Conflict);
  for (const std::string& key : texts.keys()) {
    const std::string value = texts.get(key);
    if (value.find(kPlaceholderMark) == std::string::npos) continue;
    std::string out;
    std::size_t i = 0;
    while (i < value.size()) {
      const std::size_t at = value.find(kPlaceholderMark, i);
      const std::size_t close =
          at == std::string::npos ? at : value.find(kPlaceholderMark, at + 1);
      if (close == std::string::npos) {
        out += value.substr(i);
        break;
      }
      out += value.substr(i, at - i);
      const std::string placeholder = value.substr(at, close - at + 1);
      if (value[at + 1] == 'C') {
        const std::string id = "C-" + std::to_string(++nextC);
        SpecMergeComment entry = ctx.pendingComments.at(placeholder);
        entry.id = id;
        ctx.report.comments.push_back(entry);
        out += id;
      } else {
        const std::string id = "X-" + std::to_string(++nextX);
        SpecMergeConflict entry = ctx.pendingConflicts.at(placeholder);
        entry.id = id;
        ctx.report.conflicts.push_back(entry);
        out += id;
      }
      i = close + 1;
    }
    texts.set(key, out);
  }
}

/* The team answers of `texts`' questions, by id, first occurrence winning. */
std::vector<std::pair<std::string, std::string>> teamAnswers(
    const std::vector<std::string>& texts) {
  std::vector<std::pair<std::string, std::string>> out;
  for (const std::string& t : texts) {
    for (const auto& answer : review_internal::reviewTeamAnswers(t)) {
      const bool seen = std::any_of(out.begin(), out.end(), [&](const auto& e) {
        return e.first == answer.first;
      });
      if (!seen) out.push_back(answer);
    }
  }
  return out;
}

/* Writes each copy's team answer to a base question, where it differs from
 * the base's, as that member's individual answer (copies in round order). */
void mergeAnswers(MergeTexts& texts, const std::vector<std::string>& baseTexts,
                  const std::vector<std::vector<std::string>>& copyTexts,
                  MergeContext& ctx) {
  std::vector<std::vector<std::pair<std::string, std::string>>> copyAnswers;
  for (const auto& ts : copyTexts) copyAnswers.push_back(teamAnswers(ts));
  for (const auto& baseEntry : teamAnswers(baseTexts)) {
    const std::string& id = baseEntry.first;
    const std::string& baseAnswer = baseEntry.second;
    std::vector<std::string> members;
    for (std::size_t i = 0; i < copyAnswers.size(); i++) {
      const auto a = std::find_if(copyAnswers[i].begin(), copyAnswers[i].end(),
                                  [&](const auto& e) { return e.first == id; });
      if (a == copyAnswers[i].end() || a->second == baseAnswer ||
          a->second.empty())
        continue;
      for (const std::string& key : texts.keys()) {
        const auto written = review_internal::setIndividualAnswerText(
            texts.get(key), id, ctx.members[i], a->second);
        if (!written) continue;
        texts.set(key, *written);
        members.push_back(ctx.members[i]);
        break;
      }
    }
    if (!members.empty()) ctx.report.answers.push_back({id, members});
  }
}

/* The question proposing guest `g` for the next round's team. */
std::string guestQuestion(const std::string& id, const SpecReviewMember& g) {
  const std::string who =
      g.role.empty() ? g.displayName : g.displayName + ", " + g.role;
  SpecQuestionDraft q;
  q.id = id;
  q.topic = "Guest " + g.memberId;
  q.text = "add " + g.memberId + " (" + who + ") to the review team?";
  q.options = {"(a) yes, from the next round on", "(b) no, this round only"};
  q.recommended = "a";
  return joinOn(formatQuestionBlock(q), "\n");
}

/* Where the guest questions go: a value's key and the path the report
 * names. */
struct GuestHome {
  std::string key;
  std::string path;
};

/* Lists the reviewers and writes one question per guest to the end of the
 * value at `home` (nullopt: the report only), numbered above the base's
 * highest question id with the prefix. */
void addGuests(MergeTexts& texts, const std::vector<std::string>& baseTexts,
               const std::vector<SpecReviewMember>& copies,
               const SpecReviewMergeOptions& options,
               const std::optional<GuestHome>& home, MergeContext& ctx) {
  std::set<std::string> team;
  for (const SpecReviewMember& m : options.team) team.insert(m.memberId);
  long long n = highestId(baseTexts, options.questionPrefix,
                          SpecReviewAnnotationKind::Question);
  for (const SpecReviewMember& c : copies) {
    const bool guest = team.count(c.memberId) == 0;
    ctx.report.reviewers.push_back({c, guest});
    if (!guest) continue;
    const std::string id = options.questionPrefix + "-" + std::to_string(++n);
    ctx.report.guestQuestions.push_back(
        {id, c.memberId,
         home ? std::optional<std::string>(home->path) : std::nullopt});
    if (!home) continue;
    texts.set(home->key,
              appendBlock(texts.get(home->key), guestQuestion(id, c)));
  }
}

/* The ids of the comments and questions of `texts`. */
std::pair<std::set<std::string>, std::set<std::string>> blockIds(
    const std::vector<std::string>& texts) {
  std::set<std::string> comments, questions;
  for (const std::string& t : texts) {
    for (const ReviewPiece& p : reviewPieces(t)) {
      if (p.kind == SpecReviewAnnotationKind::Comment && p.id)
        comments.insert(*p.id);
      questions.insert(p.questionIds.begin(), p.questionIds.end());
    }
  }
  return {comments, questions};
}

/* The phases after the structure, shared by both formats. */
void mergeTexts(const std::vector<MergeValue>& values,
                const std::vector<std::string>& valueKeys, MergeTexts& texts,
                const std::vector<std::string>& baseTexts,
                const std::vector<std::vector<std::string>>& copyTexts,
                const std::vector<SpecReviewMember>& copies,
                const SpecReviewMergeOptions& options,
                const std::optional<GuestHome>& home, MergeContext& ctx) {
  for (std::size_t k = 0; k < values.size(); k++) {
    const std::string merged = mergeValue(values[k], ctx);
    if (merged != values[k].base) texts.set(valueKeys[k], merged);
  }
  applyAppends(texts, ctx);
  numberIds(texts, baseTexts, ctx);
  mergeAnswers(texts, baseTexts, copyTexts, ctx);
  addGuests(texts, baseTexts, copies, options, home, ctx);
}

/* ---- plain Markdown: values by heading path ------------------------------ */

/* A Markdown file cut at its headings: body `i` follows heading `i - 1` (body
 * 0 precedes them all). */
struct MarkdownSplit {
  std::vector<std::string> headings;
  /* The heading path of each body, its heading texts joined by ` > ` (body 0:
   * ``). */
  std::vector<std::string> paths{""};
  std::vector<std::vector<std::string>> bodies{{}};
};

/* An ATX heading's level and text (`# Title` → 1, `Title`), or nullopt. */
std::optional<std::pair<std::size_t, std::string>> atxHeading(
    const std::string& line) {
  std::size_t level = 0;
  while (level < line.size() && line[level] == '#') level++;
  if (level == 0 || level > 6) return std::nullopt;
  const std::string rest = line.substr(level);
  if (!rest.empty() && rest[0] != ' ' && rest[0] != '\t') return std::nullopt;
  std::size_t a = 0, b = rest.size();
  while (a < b && (rest[a] == ' ' || rest[a] == '\t')) a++;
  while (b > a && (rest[b - 1] == ' ' || rest[b - 1] == '\t')) b--;
  return std::make_pair(level, rest.substr(a, b - a));
}

MarkdownSplit splitMarkdown(const std::string& text) {
  MarkdownSplit out;
  SpecMarkdownFenceTracker fence;
  std::vector<std::pair<std::size_t, std::string>> stack;
  for (const std::string& line : splitOn(text, "\n")) {
    const bool wasFenced = fence.inFence();
    fence.feed(line);
    const auto h =
        wasFenced || fence.inFence() ? std::nullopt : atxHeading(line);
    if (!h) {
      out.bodies.back().push_back(line);
      continue;
    }
    while (!stack.empty() && stack.back().first >= h->first) stack.pop_back();
    stack.push_back(*h);
    std::vector<std::string> names;
    for (const auto& s : stack) names.push_back(s.second);
    out.headings.push_back(line);
    out.paths.push_back(joinOn(names, " > "));
    out.bodies.emplace_back();
  }
  return out;
}

/* A body's blank lines before and after its value, and the value. */
struct BodyParts {
  std::size_t lead = 0;
  std::size_t trail = 0;
  std::string value;
};

BodyParts bodyParts(const std::vector<std::string>& lines) {
  BodyParts p;
  while (p.lead < lines.size() && trimText(lines[p.lead]).empty()) p.lead++;
  if (p.lead == lines.size()) return p;
  while (trimText(lines[lines.size() - 1 - p.trail]).empty()) p.trail++;
  p.value = joinOn(lines, "\n", p.lead, lines.size() - p.trail);
  return p;
}

/* The body lines for a new value, keeping the body's blank lines around it. */
std::vector<std::string> bodyLines(const std::vector<std::string>& lines,
                                   const std::string& value,
                                   bool afterHeading) {
  const BodyParts parts = bodyParts(lines);
  if (value == parts.value) return lines;
  if (value.empty())
    return std::vector<std::string>(lines.begin(), lines.begin() + parts.lead);
  std::vector<std::string> out;
  const std::vector<std::string> v = splitOn(value, "\n");
  if (parts.value.empty()) {
    if (afterHeading) out.push_back("");
    out.insert(out.end(), v.begin(), v.end());
    if (!lines.empty()) out.push_back("");
    return out;
  }
  out.assign(lines.begin(), lines.begin() + parts.lead);
  out.insert(out.end(), v.begin(), v.end());
  out.insert(out.end(), lines.end() - parts.trail, lines.end());
  return out;
}

/* The values of a Markdown merge: one per body, keyed by its index. */
class MarkdownTexts : public MergeTexts {
 public:
  explicit MarkdownTexts(std::vector<std::string> values)
      : values_(std::move(values)) {}
  std::vector<std::string> keys() const override {
    std::vector<std::string> out;
    for (std::size_t k = 0; k < values_.size(); k++)
      out.push_back(std::to_string(k));
    return out;
  }
  std::string get(const std::string& key) const override {
    return values_[std::stoul(key)];
  }
  void set(const std::string& key, const std::string& value) override {
    values_[std::stoul(key)] = value;
  }
  const std::vector<std::string>& values() const { return values_; }

 private:
  std::vector<std::string> values_;
};

/* ---- SOM documents: values by model path, list items by section id ------- */

/* A document's paths with every list item named by its section id instead of
 * its position (`DEMO/CARD-LST#CARD-BETA/content`), so the same item has the
 * same name in the base, in every copy and in the merged document. */
class CanonicalPaths {
 public:
  CanonicalPaths(const SpecDocument& doc, const SpecReflection& refl)
      : doc_(&doc) {
    for (const std::string& list : doc.listPaths()) {
      const auto res = refl.resolve(list);
      const SpecField* field = res ? res->field : nullptr;
      const std::vector<std::string> items = doc.listItems(list);
      for (std::size_t k = 0; k < items.size(); k++) {
        listOf_[items[k]] = list;
        ids_[items[k]] = effectiveListItemSectionId(
            doc.itemSectionIdOpt(items[k]),
            field ? field->sectionIdPattern : "", static_cast<long long>(k + 1),
            field ? field->name : list);
      }
    }
    for (const auto& [item, list] : listOf_) byCanonical_[of(item)] = item;
  }

  /* The item paths of the list at `list`, in order. */
  std::vector<std::string> items(const std::string& list) const {
    return doc_->listItems(list);
  }

  /* The section id an item is matched by. */
  const std::string& idOf(const std::string& item) const {
    return ids_.at(item);
  }

  /* The canonical form of `path`. */
  std::string of(const std::string& path) const {
    const auto memo = memo_.find(path);
    if (memo != memo_.end()) return memo->second;
    const std::vector<std::string> segs = splitOn(path, "/");
    std::string out = path;
    for (std::size_t k = segs.size(); k > 0; k--) {
      const auto list = listOf_.find(joinOn(segs, "/", 0, k));
      if (list == listOf_.end()) continue;
      const std::string rest = joinOn(segs, "/", k);
      out = of(list->second) + "#" + idOf(list->first) +
            (rest.empty() ? "" : "/" + rest);
      break;
    }
    memo_[path] = out;
    return out;
  }

  /* The document's path for a canonical path, or nullopt when the document
   * lacks one of its items. */
  std::optional<std::string> pathOf(const std::string& canonical) const {
    const std::vector<std::string> segs = splitOn(canonical, "/");
    for (std::size_t k = segs.size(); k > 0; k--) {
      const auto item = byCanonical_.find(joinOn(segs, "/", 0, k));
      if (item == byCanonical_.end()) continue;
      const std::string rest = joinOn(segs, "/", k);
      return item->second + (rest.empty() ? "" : "/" + rest);
    }
    if (canonical.find('#') != std::string::npos) return std::nullopt;
    return canonical;
  }

 private:
  const SpecDocument* doc_;
  std::map<std::string, std::string> listOf_;
  std::map<std::string, std::string> ids_;
  std::map<std::string, std::string> byCanonical_;
  mutable std::map<std::string, std::string> memo_;
};

/* Every stored path of a document: values, headlines, codeSpecs, lists and
 * their items. */
std::vector<std::string> storedPaths(const DocumentJson& json) {
  std::vector<std::string> out;
  for (const auto& e : json.content) out.push_back(e.first);
  for (const auto& e : json.forms) out.push_back(e.first);
  for (const auto& e : json.headlines) out.push_back(e.first);
  for (const auto& e : json.codeSpecs) out.push_back(e.first);
  for (const auto& [list, entry] : json.lists) {
    out.push_back(list);
    out.insert(out.end(), entry.items.begin(), entry.items.end());
  }
  return out;
}

/* A copy whose paths the model does not resolve does not fit the base. */
void checkStructure(const SpecDocument& doc, const std::string& what,
                    const SpecReflection& refl) {
  for (const std::string& p : storedPaths(doc.toJson())) {
    if (!refl.resolve(p)) {
      throw SpecReviewMergeError(what + " holds " + p +
                                 ", a path the base model does not resolve");
    }
  }
}

/* The form field `field` of the form at `path`, or null. */
const FormFieldSpec* formFieldSpec(const SpecReflection& refl,
                                   const std::string& path,
                                   const std::string& field) {
  const auto res = refl.resolve(path);
  if (!res || res->field == nullptr) return nullptr;
  for (const FormFieldSpec& f : res->field->formFields) {
    if (f.name == field) return &f;
  }
  return nullptr;
}

/* Whether the value at `path` / `field` is text, which can hold marks: a
 * content value (a form's preamble included) or a String form field that is
 * not code. Scalar and enum leaves, and typed or code fields, are not. */
bool isText(const SpecReflection& refl, const std::string& path,
            const std::optional<std::string>& field) {
  if (field) {
    const FormFieldSpec* spec = formFieldSpec(refl, path, *field);
    return spec == nullptr || (spec->type == "String" && !spec->code);
  }
  const auto res = refl.resolve(path);
  if (!res) return true;
  if (res->kind == kSpecNodeKindScalar || res->kind == kSpecNodeKindEnumValue)
    return false;
  return res->kind != kSpecNodeKindListItemScalar ||
         (res->field != nullptr && res->field->elementType == "String");
}

/* The first node at or below `path` that holds content (a content leaf or a
 * form's preamble), in model order. */
std::optional<std::string> firstContentSlot(const SpecReflection& refl,
                                            const std::string& path,
                                            bool deep) {
  const auto res = refl.resolve(path);
  if (!res) return std::nullopt;
  if (res->kind == kSpecNodeKindContent || res->kind == kSpecNodeKindForm)
    return path;
  if (res->targetClass == nullptr) return std::nullopt;
  for (const SpecField& f : res->targetClass->fields) {
    const std::string child = path + "/" + SpecReflection::fieldSegment(f);
    if (f.kind == kSpecFieldKindContent || f.kind == kSpecFieldKindForm)
      return child;
    if (deep &&
        (f.kind == kSpecFieldKindComplex || f.kind == kSpecFieldKindSection)) {
      if (auto found = firstContentSlot(refl, child, true)) return found;
    }
  }
  return std::nullopt;
}

/* Where a block about the node at `path` goes (SOM §11.9.9, "Structure"): the
 * first content value at or below it in document order; else the first node
 * at or below it that can hold content; else its nearest ancestor's own. */
std::optional<std::string> blockHome(const SpecDocument& doc,
                                     const SpecReflection& refl,
                                     const std::string& path, bool ownFirst) {
  if (ownFirst) {
    for (const std::string& p : doc.contentPaths()) {  // byte-sorted
      if (under(p, path)) return p;
    }
    if (auto slot = firstContentSlot(refl, path, true)) return slot;
  }
  std::string a = specParentPath(path);
  while (!a.empty()) {
    if (doc.contentOpt(a) != nullptr) return a;
    if (auto slot = firstContentSlot(refl, a, false)) return slot;
    const std::string parent = specParentPath(a);
    if (parent == a) break;
    a = parent;
  }
  return std::nullopt;
}

/* One structural change the copies disagree with the base on. */
struct Structural {
  std::string node;   // the canonical path of the item (or section) concerned
  std::string topic;  // `Item removed`, `Item moved` or `Headline changed`
  std::string base;
  std::vector<ChangeGroup> groups;
};

void addStructural(std::vector<Structural>& all, const std::string& node,
                   const std::string& topic, const std::string& base,
                   const std::string& text, const std::string& member) {
  auto s = std::find_if(all.begin(), all.end(), [&](const Structural& x) {
    return x.node == node && x.topic == topic;
  });
  if (s == all.end()) {
    all.push_back({node, topic, base, {}});
    s = all.end() - 1;
  }
  auto g = std::find_if(s->groups.begin(), s->groups.end(),
                        [&](const ChangeGroup& x) { return x.text == text; });
  if (g == s->groups.end()) {
    s->groups.push_back({text, {member}, nullptr});
  } else {
    g->members.push_back(member);
  }
}

/* The ids of `ids` that are not in their longest common subsequence with
 * `order`. */
std::set<std::string> moved(const std::vector<std::string>& order,
                            const std::vector<std::string>& ids) {
  const std::size_t n = order.size(), m = ids.size();
  std::vector<std::vector<std::size_t>> l(n + 1,
                                          std::vector<std::size_t>(m + 1, 0));
  for (std::size_t i = n; i-- > 0;) {
    for (std::size_t j = m; j-- > 0;) {
      l[i][j] = order[i] == ids[j] ? l[i + 1][j + 1] + 1
                                   : std::max(l[i + 1][j], l[i][j + 1]);
    }
  }
  std::set<std::string> stay;
  std::size_t i = 0, j = 0;
  while (i < n && j < m) {
    if (order[i] == ids[j]) {
      stay.insert(order[i]);
      i++;
      j++;
    } else if (l[i + 1][j] >= l[i][j + 1]) {
      i++;
    } else {
      j++;
    }
  }
  std::set<std::string> out;
  for (const std::string& id : ids) {
    if (stay.count(id) == 0) out.insert(id);
  }
  return out;
}

/* Whether a paragraph opens a fenced code block. */
bool opensFence(const std::string& text) {
  std::size_t i = 0;
  while (i < text.size() && isSpaceByte(text[i])) i++;
  return text.compare(i, 3, "```") == 0 || text.compare(i, 3, "~~~") == 0;
}

/* `value` written as attributed insertions, one per text paragraph (an added
 * item's text). */
std::string asInsertion(const std::string& value,
                        const std::vector<std::string>& members) {
  const std::string token = "{@" + joinOn(members, ",") + "}";
  std::vector<std::string> out;
  for (const ReviewPiece& p : reviewPieces(value)) {
    out.push_back(p.kind || opensFence(p.text)
                      ? p.text
                      : "{++ " + trimText(p.text) + " ++}" + token);
  }
  return joinOn(out, "\n\n");
}

std::vector<std::string> pathsUnder(const std::vector<std::string>& paths,
                                    const std::string& item) {
  std::vector<std::string> out;
  for (const std::string& p : paths) {
    if (under(p, item)) out.push_back(p);
  }
  return out;
}

/* Copies item `from` of `src`, with everything under it, to item `to` of
 * `dst`. */
void copyItem(const SpecDocument& src, const std::string& from,
              SpecDocument& dst, const std::string& to,
              const std::vector<std::string>& members,
              const SpecReflection& refl) {
  std::map<std::string, std::string> movedTo{{from, to}};
  auto remap = [&](const std::string& p) {
    const std::vector<std::string> segs = splitOn(p, "/");
    for (std::size_t k = segs.size(); k > 0; k--) {
      const auto target = movedTo.find(joinOn(segs, "/", 0, k));
      if (target == movedTo.end()) continue;
      const std::string rest = joinOn(segs, "/", k);
      return target->second + (rest.empty() ? "" : "/" + rest);
    }
    return p;
  };
  std::vector<std::string> lists = pathsUnder(src.listPaths(), from);
  std::stable_sort(lists.begin(), lists.end(),
                   [](const std::string& a, const std::string& b) {
                     return std::count(a.begin(), a.end(), '/') <
                            std::count(b.begin(), b.end(), '/');
                   });
  const CanonicalPaths canonical(src, refl);
  for (const std::string& list : lists) {
    for (const std::string& item : src.listItems(list)) {
      movedTo[item] =
          dst.addListItemWithSectionId(remap(list), canonical.idOf(item));
    }
  }
  for (const std::string& p : pathsUnder(src.contentPaths(), from)) {
    const std::string value = src.content(p);
    dst.setContent(remap(p), isText(refl, p, std::nullopt)
                                 ? asInsertion(value, members)
                                 : value);
  }
  for (const std::string& p : pathsUnder(src.formPaths(), from)) {
    for (const std::string& f : src.formFieldNames(p)) {
      const std::string value = src.formField(p, f);
      dst.setFormField(
          remap(p), f,
          isText(refl, p, f) ? asInsertion(value, members) : value);
    }
  }
  for (const std::string& p : pathsUnder(src.headlinePaths(), from)) {
    dst.setHeadline(remap(p), src.headline(p));
  }
  for (const std::string& p : pathsUnder(src.codeSpecPaths(), from)) {
    dst.setCodeSpec(remap(p), src.codeSpec(p));
  }
}

/* Everything under an item, as one comparable value, its own path cut from
 * every path in it: copies adding the same item alike add it once. */
std::string itemSignature(const SpecDocument& doc, const std::string& item) {
  const DocumentJson json = doc.toJson();
  auto rel = [&](const std::string& p) {
    return startsWith(p, item) ? p.substr(item.size()) : p;
  };
  std::string out;
  auto add = [&](const std::string& s) { out += jsonEncodeStr(s) + ","; };
  for (const auto& [k, v] : json.content) {
    if (under(k, item)) add("c" + rel(k)), add(v);
  }
  for (const auto& [k, fields] : json.forms) {
    if (!under(k, item)) continue;
    add("f" + rel(k));
    for (const auto& [f, v] : fields) add(f), add(v);
  }
  for (const auto& [k, v] : json.headlines) {
    if (under(k, item)) add("h" + rel(k)), add(v);
  }
  for (const auto& [k, entry] : json.lists) {
    if (!under(k, item)) continue;
    add("l" + rel(k) + "#" + std::to_string(entry.seq));
    for (const std::string& i : entry.items) add(rel(i));
    for (const auto& [i, id] : entry.ids) add(rel(i)), add(id);
  }
  return out;
}

/* The keys of the SOM texts: `c\0<path>` for content, `f\0<path>\0<field>`
 * for a form field. */
std::string contentKey(const std::string& path) {
  return std::string("c") + '\0' + path;
}

std::string fieldKey(const std::string& path, const std::string& field) {
  return std::string("f") + '\0' + path + '\0' + field;
}

std::string valueKey(const MergeValue& v) {
  return v.field ? fieldKey(v.path, *v.field) : contentKey(v.path);
}

/* A SOM document's values as MergeTexts, in document order (content sorted,
 * then forms and fields sorted). */
class SomTexts : public MergeTexts {
 public:
  explicit SomTexts(SpecDocument& doc) : doc_(&doc) {}
  std::vector<std::string> keys() const override {
    std::vector<std::string> out;
    for (const std::string& p : doc_->contentPaths())
      out.push_back(contentKey(p));
    for (const std::string& p : doc_->formPaths()) {
      for (const std::string& f : doc_->formFieldNames(p))
        out.push_back(fieldKey(p, f));
    }
    return out;
  }
  std::string get(const std::string& key) const override {
    const std::vector<std::string> parts = splitOn(key, std::string(1, '\0'));
    return parts[0] == "c" ? doc_->content(parts[1])
                           : doc_->formField(parts[1], parts[2]);
  }
  void set(const std::string& key, const std::string& value) override {
    const std::vector<std::string> parts = splitOn(key, std::string(1, '\0'));
    if (parts[0] == "c") {
      doc_->setContent(parts[1], value);
    } else {
      doc_->setFormField(parts[1], parts[2], value);
    }
  }

 private:
  SpecDocument* doc_;
};

/* Every value of `doc`, in document order. */
std::vector<std::string> somValueTexts(const SpecDocument& doc) {
  std::vector<std::string> out;
  for (const std::string& p : doc.contentPaths()) out.push_back(doc.content(p));
  for (const std::string& p : doc.formPaths()) {
    for (const std::string& f : doc.formFieldNames(p))
      out.push_back(doc.formField(p, f));
  }
  return out;
}

/* Whether `node` lies under one of the `added` items. */
bool underAdded(const std::string& node, const std::set<std::string>& added) {
  return std::any_of(added.begin(), added.end(),
                     [&](const std::string& a) { return under(node, a); });
}

/* Every headline a copy changed (items it added aside) is a structural
 * conflict. */
void headlineChanges(const SpecDocument& base, const CanonicalPaths& baseCanon,
                     const std::vector<SpecReviewedDocument>& copies,
                     const std::vector<CanonicalPaths>& copyCanon,
                     const std::set<std::string>& added,
                     std::vector<Structural>& structural) {
  std::set<std::string> nodes;
  for (const std::string& p : base.headlinePaths())
    nodes.insert(baseCanon.of(p));
  for (std::size_t i = 0; i < copies.size(); i++) {
    for (const std::string& p : copies[i].document.headlinePaths()) {
      nodes.insert(copyCanon[i].of(p));
    }
  }
  for (const std::string& node : nodes) {
    if (underAdded(node, added)) continue;
    const auto basePath = baseCanon.pathOf(node);
    if (!basePath) continue;
    const std::string was = base.headline(*basePath);
    for (std::size_t i = 0; i < copies.size(); i++) {
      const auto path = copyCanon[i].pathOf(node);
      if (!path) continue;
      const std::string now = copies[i].document.headline(*path);
      if (now != was) {
        addStructural(structural, node, "Headline changed", was, now,
                      copies[i].member.memberId);
      }
    }
  }
}

/* An item a copy added, as the structure phase collects it. */
struct Addition {
  std::string id;
  std::size_t copy = 0;
  std::optional<std::string> anchor;  // the base item it follows in the copy
  std::vector<std::string> members;
  std::string signature;
};

/* The structure phase: items the copies added are added (attributed to every
 * copy that added them alike); items removed or moved, and changed headlines,
 * become structural conflicts. Returns the canonical paths of the added
 * items. */
std::set<std::string> mergeStructure(
    SpecDocument& merged, const SpecDocument& base,
    const std::vector<SpecReviewedDocument>& copies, const SpecReflection& refl,
    const SpecModel& model, MergeContext& ctx) {
  const CanonicalPaths baseCanon(base, refl);
  std::vector<CanonicalPaths> copyCanon;
  for (const SpecReviewedDocument& c : copies)
    copyCanon.emplace_back(c.document, refl);
  std::set<std::string> added;
  std::vector<Structural> structural;
  std::vector<std::pair<std::string, std::vector<std::string>>> additions;
  std::set<std::string> lists;
  for (const std::string& l : base.listPaths()) lists.insert(baseCanon.of(l));
  for (std::size_t i = 0; i < copies.size(); i++) {
    for (const std::string& l : copies[i].document.listPaths())
      lists.insert(copyCanon[i].of(l));
  }
  std::vector<std::string> ordered(lists.begin(), lists.end());  // byte-sorted
  std::stable_sort(ordered.begin(), ordered.end(),
                   [](const std::string& a, const std::string& b) {
                     return std::count(a.begin(), a.end(), '#') <
                            std::count(b.begin(), b.end(), '#');
                   });
  for (const std::string& list : ordered) {
    if (underAdded(list, added)) continue;
    const auto basePath = baseCanon.pathOf(list);
    if (!basePath) continue;
    std::vector<std::string> baseIds;
    for (const std::string& p : baseCanon.items(*basePath))
      baseIds.push_back(baseCanon.idOf(p));
    std::vector<Addition> groups;
    for (std::size_t i = 0; i < copies.size(); i++) {
      const auto copyPath = copyCanon[i].pathOf(list);
      if (!copyPath) continue;
      const std::vector<std::string> items = copyCanon[i].items(*copyPath);
      std::vector<std::string> ids;
      for (const std::string& p : items) ids.push_back(copyCanon[i].idOf(p));
      const std::string& member = copies[i].member.memberId;
      for (std::size_t k = 0; k < ids.size(); k++) {
        if (contains(baseIds, ids[k])) continue;
        const std::string signature =
            itemSignature(copies[i].document, items[k]);
        auto g =
            std::find_if(groups.begin(), groups.end(),
                         [&](const Addition& x) { return x.id == ids[k]; });
        if (g == groups.end()) {
          std::optional<std::string> anchor;
          for (std::size_t q = k; q-- > 0;) {
            if (contains(baseIds, ids[q])) {
              anchor = ids[q];
              break;
            }
          }
          groups.push_back({ids[k], i, anchor, {member}, signature});
        } else if (g->signature == signature) {
          g->members.push_back(member);
        }
      }
      for (const std::string& id : baseIds) {
        if (!contains(ids, id)) {
          addStructural(structural, list + "#" + id, "Item removed", "kept",
                        "removed", member);
        }
      }
      std::vector<std::string> keptOrder, keptIds;
      for (const std::string& id : baseIds) {
        if (contains(ids, id)) keptOrder.push_back(id);
      }
      for (const std::string& id : ids) {
        if (contains(baseIds, id)) keptIds.push_back(id);
      }
      const std::set<std::string> movedIds = moved(keptOrder, keptIds);
      for (const std::string& id : keptIds) {  // in the copy's order
        if (movedIds.count(id) == 0) continue;
        addStructural(
            structural, list + "#" + id, "Item moved",
            "position " + std::to_string(indexOf(baseIds, id) + 1),
            "moved to position " + std::to_string(indexOf(ids, id) + 1),
            member);
      }
    }
    for (const Addition& g : groups) {
      const CanonicalPaths mergedCanon(merged, refl);
      const std::string listPath = *mergedCanon.pathOf(list);
      std::vector<std::string> mergedIds;
      for (const std::string& p : mergedCanon.items(listPath))
        mergedIds.push_back(mergedCanon.idOf(p));
      std::size_t at =
          g.anchor ? static_cast<std::size_t>(indexOf(mergedIds, *g.anchor) + 1)
                   : 0;
      while (at < mergedIds.size() && !contains(baseIds, mergedIds[at])) at++;
      std::string item = merged.addListItemWithSectionId(listPath, g.id);
      if (at < mergedIds.size()) {
        item =
            merged.moveListItem(model, item, static_cast<long long>(at)).path;
      }
      copyItem(copies[g.copy].document,
               *copyCanon[g.copy].pathOf(list + "#" + g.id), merged, item,
               g.members, refl);
      added.insert(list + "#" + g.id);
      additions.emplace_back(list + "#" + g.id, g.members);
    }
  }
  headlineChanges(base, baseCanon, copies, copyCanon, added, structural);
  const CanonicalPaths mergedCanon(merged, refl);
  for (const auto& [node, members] : additions) {
    ctx.report.additions.push_back({*mergedCanon.pathOf(node), members});
  }
  for (const Structural& s : structural) {
    const std::string node = *mergedCanon.pathOf(s.node);
    const auto home = blockHome(merged, refl, node, true);
    const std::string block = ctx.conflict(s.topic, node, s.base, s.groups,
                                           node, std::nullopt, std::nullopt);
    if (home) ctx.append(contentKey(*home), block);
  }
  return added;
}

/* The values to merge: every value of the base and of the copies, items the
 * copies added aside, located in the merged document; in its document order
 * (content first, then form fields, each by path). */
std::vector<MergeValue> somValues(
    const SpecDocument& merged, const SpecDocument& base,
    const std::vector<SpecReviewedDocument>& copies,
    const std::set<std::string>& added, const SpecReflection& refl) {
  const CanonicalPaths baseCanon(base, refl);
  std::vector<CanonicalPaths> copyCanon;
  for (const SpecReviewedDocument& c : copies)
    copyCanon.emplace_back(c.document, refl);
  const CanonicalPaths mergedCanon(merged, refl);
  // (content 0 / field 1, canonical path, field): ordered as the result sorts.
  std::set<std::tuple<int, std::string, std::string>> nodes;
  auto collect = [&](const SpecDocument& doc, const CanonicalPaths& canon) {
    for (const std::string& p : doc.contentPaths())
      nodes.insert({0, canon.of(p), ""});
    for (const std::string& p : doc.formPaths()) {
      for (const std::string& f : doc.formFieldNames(p))
        nodes.insert({1, canon.of(p), f});
    }
  };
  collect(base, baseCanon);
  for (std::size_t i = 0; i < copies.size(); i++)
    collect(copies[i].document, copyCanon[i]);
  auto read = [](const SpecDocument& doc, const std::string& path,
                 const std::optional<std::string>& field) {
    return field ? doc.formField(path, *field) : doc.content(path);
  };
  std::vector<MergeValue> values;
  for (const auto& [isField, node, fieldName] : nodes) {
    if (underAdded(node, added)) continue;
    const auto basePath = baseCanon.pathOf(node);
    if (!basePath) continue;
    const std::optional<std::string> field =
        isField ? std::optional<std::string>(fieldName) : std::nullopt;
    MergeValue v;
    v.path = *mergedCanon.pathOf(node);
    v.field = field;
    v.base = read(base, *basePath, field);
    for (std::size_t i = 0; i < copies.size(); i++) {
      const auto p = copyCanon[i].pathOf(node);
      v.copies.push_back(
          p ? std::optional<std::string>(read(copies[i].document, *p, field))
            : std::nullopt);
    }
    const bool text = isText(refl, v.path, field);
    v.typed = !text;
    if (field) {
      v.conflictHome = contentKey(v.path);
    } else if (!text) {
      if (auto home = blockHome(merged, refl, v.path, false))
        v.conflictHome = contentKey(*home);
    }
    values.push_back(std::move(v));
  }
  // The merged path decides the order: it is the canonical one's position.
  std::stable_sort(
      values.begin(), values.end(),
      [](const MergeValue& a, const MergeValue& b) {
        const std::string ka = std::string(a.field ? "1" : "0") + '\0' +
                               a.path + '\0' + a.field.value_or("");
        const std::string kb = std::string(b.field ? "1" : "0") + '\0' +
                               b.path + '\0' + b.field.value_or("");
        return ka < kb;
      });
  return values;
}

/* The class field of `cls` named `name` with kind `kind`, or null. */
const SpecField* classField(const SpecClass* cls, const std::string& name,
                            const char* kind) {
  const SpecField* f = cls == nullptr ? nullptr : cls->fieldNamed(name);
  return f != nullptr && f->kind == kind ? f : nullptr;
}

/* The model classes the revision entry is written with (`tom_specs_model`'s
 * document front matter). */
const char* const kRevisionEntry = "RevisionEntry";
const char* const kDocumentHeader = "DocumentHeader";

bool allDigits(const std::string& s) {
  return !s.empty() && std::all_of(s.begin(), s.end(),
                                   [](char c) { return c >= '0' && c <= '9'; });
}

/* The next minor of a `major.minor[.patch]` version; `0.1.0` for anything
 * else. */
std::string nextMinor(const std::optional<std::string>& version) {
  const std::vector<std::string> parts =
      splitOn(trimText(version.value_or("")), ".");
  if (parts.size() < 2 || parts.size() > 3 ||
      !std::all_of(parts.begin(), parts.end(), allDigits)) {
    return "0.1.0";
  }
  const std::string minor =
      parts[0] + "." + std::to_string(std::stoll(parts[1]) + 1);
  return parts.size() == 2 ? minor : minor + ".0";
}

/* The month and day of an ISO 8601 date. */
std::pair<long long, long long> monthDay(const std::string& date) {
  const bool ok = date.size() >= 10 && allDigits(date.substr(0, 4)) &&
                  date[4] == '-' && allDigits(date.substr(5, 2)) &&
                  date[7] == '-' && allDigits(date.substr(8, 2));
  if (!ok)
    throw SpecReviewMergeError("options.date \"" + date +
                               "\" is not an ISO 8601 date");
  return {std::stoll(date.substr(5, 2)), std::stoll(date.substr(8, 2))};
}

/* Adds an item with a generated id to the list `field` at `list`, and returns
 * its path. */
std::string addGeneratedItem(SpecDocument& doc, const std::string& list,
                             const SpecField& field,
                             std::pair<long long, long long> date) {
  const std::string pattern = field.sectionIdPattern.empty()
                                  ? field.name + "-xxx"
                                  : field.sectionIdPattern;
  return doc.addListItemWithSectionId(
      list, specGenerateListItemSectionId(pattern, date.first, date.second,
                                          doc.listItemSectionIds(list)));
}

/* Writes one reviewer record into the list `field` at `list`. */
void addReviewerRecord(SpecDocument& doc, const SpecModel& model,
                       const std::string& list, const SpecField& field,
                       const SpecReviewMember& member, bool guest,
                       std::pair<long long, long long> date) {
  const std::string item = addGeneratedItem(doc, list, field, date);
  const SpecField* form = classField(model.classNamed(field.elementType),
                                     "content", kSpecFieldKindForm);
  if (form == nullptr) return;
  const std::string path = item + "/" + SpecReflection::fieldSegment(*form);
  doc.setFormField(path, "memberId", member.memberId);
  doc.setFormField(path, "displayName", member.displayName);
  doc.setFormField(path, "role", member.role);
  if (guest) doc.setFormField(path, "guest", "true");
}

/* Appends the draft revision entry when the root has a revision history: the
 * next minor version, the date and author, the team the round started with and
 * every reviewer who returned a copy, guests marked. */
void addRevisionEntry(SpecDocument& merged, const std::string& root,
                      const std::vector<SpecReviewMember>& copies,
                      const SpecReviewMergeOptions& options,
                      const SpecReflection& refl, const SpecModel& model,
                      MergeContext& ctx) {
  const SpecRoot* rootSpec = refl.rootForSegment(root);
  const SpecClass* rootClass =
      rootSpec == nullptr ? nullptr : model.classNamed(rootSpec->type);
  if (rootClass == nullptr) return;
  const SpecField* history = nullptr;
  const SpecField* header = nullptr;
  for (const SpecField& f : rootClass->fields) {
    if (history == nullptr && f.kind == kSpecFieldKindList &&
        f.elementType == kRevisionEntry) {
      history = &f;
    }
    if (header == nullptr && f.type == kDocumentHeader) header = &f;
  }
  if (history == nullptr) return;
  const auto date = monthDay(options.date);
  const SpecField* headerForm =
      header ? classField(model.classNamed(kDocumentHeader), "content",
                          kSpecFieldKindForm)
             : nullptr;
  std::optional<std::string> current;
  if (header && headerForm) {
    const std::string* v =
        merged.formFieldOpt(root + "/" + SpecReflection::fieldSegment(*header) +
                                "/" + SpecReflection::fieldSegment(*headerForm),
                            "version");
    if (v != nullptr) current = *v;
  }
  const std::string version = nextMinor(current);
  const std::string item = addGeneratedItem(
      merged, root + "/" + SpecReflection::fieldSegment(*history), *history,
      date);
  const SpecClass* entry = model.classNamed(kRevisionEntry);
  if (const SpecField* form =
          classField(entry, "content", kSpecFieldKindForm)) {
    const std::string path = item + "/" + SpecReflection::fieldSegment(*form);
    merged.setFormField(path, "version", version);
    merged.setFormField(path, "date", options.date);
    merged.setFormField(path, "author", options.author);
  }
  std::set<std::string> team;
  for (const SpecReviewMember& m : options.team) team.insert(m.memberId);
  const std::pair<const char*, const std::vector<SpecReviewMember>*> records[] =
      {{"reviewTeam", &options.team}, {"reviewers", &copies}};
  for (const auto& [name, members] : records) {
    const SpecField* list = classField(entry, name, kSpecFieldKindList);
    if (list == nullptr) continue;
    const bool reviewers = members == &copies;
    for (const SpecReviewMember& m : *members) {
      addReviewerRecord(merged, model,
                        item + "/" + SpecReflection::fieldSegment(*list), *list,
                        m, reviewers && team.count(m.memberId) == 0, date);
    }
  }
  ctx.report.revision = SpecMergeRevision{item, version};
}

/* The root segment of a document: the first segment of its paths. */
std::optional<std::string> rootOf(const SpecDocument& doc,
                                  const SpecModel& model) {
  const DocumentJson json = doc.toJson();
  std::optional<std::string> any;
  if (!json.content.empty()) {
    any = json.content.begin()->first;
  } else if (!json.forms.empty()) {
    any = json.forms.begin()->first;
  } else if (!json.lists.empty()) {
    any = json.lists.begin()->first;
  } else if (!json.headlines.empty()) {
    any = json.headlines.begin()->first;
  }
  if (any) return splitOn(*any, "/")[0];
  if (model.roots.empty()) return std::nullopt;
  return SpecReflection::rootSegment(model.roots[0]);
}

std::vector<SpecReviewMember> membersOf(
    const std::vector<SpecReviewedDocument>& copies) {
  std::vector<SpecReviewMember> out;
  for (const SpecReviewedDocument& c : copies) out.push_back(c.member);
  return out;
}

}  // namespace

SpecReviewMergeResult<std::string> mergeReviews(
    const std::string& base, const std::vector<SpecReviewedMarkdown>& copies,
    const SpecReviewMergeOptions& options) {
  const MarkdownSplit b = splitMarkdown(base);
  std::vector<MarkdownSplit> cs;
  std::vector<SpecReviewMember> members;
  for (const SpecReviewedMarkdown& c : copies) {
    MarkdownSplit split = splitMarkdown(c.document);
    bool same = split.headings.size() == b.headings.size();
    for (std::size_t k = 0; same && k < b.headings.size(); k++) {
      same = trimText(split.headings[k]) == trimText(b.headings[k]);
    }
    if (!same) {
      throw SpecReviewMergeError("the copy of " + c.member.memberId +
                                 " has other headings than the base");
    }
    cs.push_back(std::move(split));
    members.push_back(c.member);
  }
  std::vector<std::string> baseTexts;
  for (const auto& lines : b.bodies)
    baseTexts.push_back(bodyParts(lines).value);
  std::vector<std::vector<std::string>> copyTexts;
  for (const MarkdownSplit& c : cs) {
    std::vector<std::string> ts;
    for (const auto& lines : c.bodies) ts.push_back(bodyParts(lines).value);
    copyTexts.push_back(std::move(ts));
  }
  MarkdownTexts texts(baseTexts);
  auto [comments, questions] = blockIds(baseTexts);
  MergeContext ctx(members, comments, questions);
  std::vector<MergeValue> values;
  std::vector<std::string> keys;
  for (std::size_t k = 0; k < baseTexts.size(); k++) {
    MergeValue v;
    v.path = b.paths[k];
    v.base = baseTexts[k];
    for (const auto& ct : copyTexts) v.copies.push_back(ct[k]);
    values.push_back(std::move(v));
    keys.push_back(std::to_string(k));
  }
  const std::size_t first = b.headings.empty() ? 0 : 1;
  mergeTexts(values, keys, texts, baseTexts, copyTexts, members, options,
             GuestHome{std::to_string(first), b.paths[first]}, ctx);
  std::vector<std::string> lines;
  for (std::size_t k = 0; k < b.bodies.size(); k++) {
    if (k > 0) lines.push_back(b.headings[k - 1]);
    for (std::string& l : bodyLines(b.bodies[k], texts.values()[k], k > 0)) {
      lines.push_back(std::move(l));
    }
  }
  return {joinOn(lines, "\n"), std::move(ctx.report)};
}

SpecReviewMergeResult<SpecDocument> mergeReviews(
    const SpecModel& model, const SpecDocument& base,
    const std::vector<SpecReviewedDocument>& copies,
    const SpecReviewMergeOptions& options) {
  const SpecReflection refl(model);
  checkStructure(base, "the base", refl);
  for (const SpecReviewedDocument& c : copies) {
    checkStructure(c.document, "the copy of " + c.member.memberId, refl);
  }
  const std::vector<std::string> baseValues = somValueTexts(base);
  std::vector<std::vector<std::string>> copyValues;
  for (const SpecReviewedDocument& c : copies)
    copyValues.push_back(somValueTexts(c.document));
  const std::vector<SpecReviewMember> members = membersOf(copies);
  auto [comments, questions] = blockIds(baseValues);
  MergeContext ctx(members, comments, questions);
  SpecDocument merged;
  merged.loadJson(base.toJson());
  const std::set<std::string> added =
      mergeStructure(merged, base, copies, refl, model, ctx);
  const std::vector<MergeValue> values =
      somValues(merged, base, copies, added, refl);
  std::vector<std::string> keys;
  for (const MergeValue& v : values) keys.push_back(valueKey(v));
  const std::optional<std::string> root = rootOf(base, model);
  std::optional<GuestHome> home;
  if (root) {
    const SpecRoot* rootSpec = refl.rootForSegment(*root);
    const SpecClass* rootClass =
        rootSpec == nullptr ? nullptr : model.classNamed(rootSpec->type);
    if (const SpecField* content =
            classField(rootClass, "content", kSpecFieldKindContent)) {
      const std::string path =
          *root + "/" + SpecReflection::fieldSegment(*content);
      home = GuestHome{contentKey(path), path};
    }
  }
  SomTexts texts(merged);
  mergeTexts(values, keys, texts, baseValues, copyValues, members, options,
             home, ctx);
  if (root) addRevisionEntry(merged, *root, members, options, refl, model, ctx);
  return {std::move(merged), std::move(ctx.report)};
}

}  // namespace som
