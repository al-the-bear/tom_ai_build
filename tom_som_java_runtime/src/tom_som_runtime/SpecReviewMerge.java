package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.function.Predicate;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import tom_som_runtime.SpecReviewAnnotations.ReviewMark;
import tom_som_runtime.SpecReviewAnnotations.ReviewPiece;

/**
 * Merging the reviewed copies of a team review (SOM §11.9.9) into one document in the team
 * notation of §11.9.8: who proposed, voted for and answered what, and where two members changed
 * the same passage differently. A port of {@code tom_som_typescript_runtime/src/spec_review_merge.ts}.
 *
 * <p>{@link #mergeReviews(SpecDocument, List, SpecReviewMergeOptions)} merges a SOM document (by
 * model path, list items matched by section id); {@link #mergeReviews(String, List,
 * SpecReviewMergeOptions)} a plain annotated Markdown file (by heading path). Both share one engine
 * that works value by value; only the way values are found, and the SOM-only structure and
 * revision entry, differ.
 *
 * <p>The engine is built on the review-annotation building blocks of {@link
 * SpecReviewAnnotations}: the paragraph split and the mark decisions, {@code markChangeText} for
 * edits written as plain text, the individual-answer rules of {@code setAnswer}, and the list-item
 * id generation of {@link SpecSectionId#generateListItemSectionId}.
 */
public final class SpecReviewMerge {
  private SpecReviewMerge() {}

  /**
   * Merges the reviewed {@code copies} of the SOM document {@code base} (SOM §11.9.9). Neither the
   * base nor a copy is written. {@code options.model} is required.
   *
   * @throws SpecReviewMergeError when a copy's structure does not fit the base
   */
  public static SpecReviewMergeResult<SpecDocument> mergeReviews(
      SpecDocument base,
      List<SpecReviewedCopy<SpecDocument>> copies,
      SpecReviewMergeOptions options) {
    if (options.model == null) {
      throw new SpecReviewMergeError("merging a SOM document needs options.model");
    }
    return mergeSom(base, copies, options, options.model);
  }

  /**
   * Merges the reviewed {@code copies} of the plain annotated Markdown file {@code base} (SOM
   * §11.9.9), by heading path.
   *
   * @throws SpecReviewMergeError when a copy has other headings than the base
   */
  public static SpecReviewMergeResult<String> mergeReviews(
      String base, List<SpecReviewedCopy<String>> copies, SpecReviewMergeOptions options) {
    return mergeMarkdown(base, copies, options);
  }

  // -------------------------------------------------------------------------
  // The engine: one value at a time.
  // -------------------------------------------------------------------------

  /** Ids the merge writes before it can number them: renumbered in merged document order at the end. */
  private static final Pattern PLACEHOLDER = Pattern.compile("\u0001([CX])([0-9]+)\u0001");

  /** One value to merge, located in the merged document. */
  private static final class MergeValue {
    final String path;
    final String field;
    final String base;
    /** Per copy, in round order; null when the copy holds no such value (it removed the item). */
    final List<String> copies;
    /** A typed leaf (number, bool, enum, code): never marked, any change is a conflict. */
    final boolean typed;
    /** Where a conflict about a form field or a typed leaf goes; null for a content value. */
    final String conflictHome;

    MergeValue(
        String path,
        String field,
        String base,
        List<String> copies,
        boolean typed,
        String conflictHome) {
      this.path = path;
      this.field = field;
      this.base = base;
      this.copies = copies;
      this.typed = typed;
      this.conflictHome = conflictHome;
    }

    /** The value's place as a conflict's text names it: {@code <path>[ <field>]}. */
    String where() {
      return path + (field == null ? "" : " " + field);
    }
  }

  /** What one copy did to one unit (SOM §11.9.9, steps 1–4). */
  private static final class UnitReading {
    final boolean changed;
    /** The reviewer's text. */
    final String t;
    /** The change as it is written into the merged document. */
    final String written;
    /** The copy's votes, by the index of the base unit's mark: true accepts. */
    final Map<Integer, Boolean> votes;

    UnitReading(boolean changed, String t, String written, Map<Integer, Boolean> votes) {
      this.changed = changed;
      this.t = t;
      this.written = written;
      this.votes = votes;
    }
  }

  /** The copies that made one change: its text, its members, and the first such reading. */
  private static final class ChangeGroup {
    final String text;
    final List<String> members = new ArrayList<>();
    final UnitReading first;

    ChangeGroup(String text, String member, UnitReading first) {
      this.text = text;
      this.members.add(member);
      this.first = first;
    }
  }

  /** The state one merge carries from value to value. */
  private static final class MergeContext {
    final SpecReviewMergeReport report = new SpecReviewMergeReport();
    /** Blocks to append to the end of a content value, by its key. */
    final Map<String, List<String>> appends = new LinkedHashMap<>();
    final List<String> members = new ArrayList<>();
    final Set<String> baseCommentIds;
    final Set<String> baseQuestionIds;
    private int nextPlaceholder = 0;
    /** Placeholder → report entry, filled in when the ids are numbered. */
    final Map<String, SpecReviewMergeReport.Conflict> pendingConflicts = new HashMap<>();
    final Map<String, SpecReviewMergeReport.Comment> pendingComments = new HashMap<>();

    MergeContext(
        List<SpecReviewMember> copies, Set<String> baseCommentIds, Set<String> baseQuestionIds) {
      for (SpecReviewMember c : copies) {
        members.add(c.memberId);
      }
      this.baseCommentIds = baseCommentIds;
      this.baseQuestionIds = baseQuestionIds;
    }

    String placeholder(char kind) {
      return "\u0001" + kind + (++nextPlaceholder) + "\u0001";
    }

    void append(String key, String block) {
      appends.computeIfAbsent(key, k -> new ArrayList<>()).add(block);
    }

    /** Writes a conflict block with a placeholder id and records it for the report. */
    String conflict(
        String topic,
        String text,
        String base,
        List<ChangeGroup> groups,
        String path,
        String field,
        Integer paragraph) {
      String id = placeholder('X');
      List<String> members = new ArrayList<>();
      List<SpecConflictAlternative> alternatives = new ArrayList<>();
      for (int k = 0; k < groups.size(); k++) {
        ChangeGroup g = groups.get(k);
        members.addAll(g.members);
        alternatives.add(
            new SpecConflictAlternative(String.valueOf((char) ('a' + k)), g.members, g.text));
      }
      pendingConflicts.put(
          id, new SpecReviewMergeReport.Conflict(id, path, field, paragraph, members));
      return String.join(
          "\n", SpecReviewAnnotations.formatConflictBlock(id, topic, text, base, alternatives));
    }
  }

  /** Groups the changed readings by their text {@code t}, in order of first appearance. */
  private static List<ChangeGroup> changeGroups(List<UnitReading> readings, List<String> members) {
    List<ChangeGroup> groups = new ArrayList<>();
    for (int k = 0; k < readings.size(); k++) {
      UnitReading r = readings.get(k);
      if (r == null || !r.changed) {
        continue;
      }
      ChangeGroup g = null;
      for (ChangeGroup x : groups) {
        if (x.text.equals(r.t)) {
          g = x;
          break;
        }
      }
      if (g == null) {
        groups.add(new ChangeGroup(r.t, members.get(k), r));
      } else {
        g.members.add(members.get(k));
      }
    }
    return groups;
  }

  /** Aligns two lists by a key (longest common subsequence): index in {@code a} → index in {@code b}. */
  private static <T> Map<Integer, Integer> align(List<T> a, List<T> b, Function<T, String> key) {
    int n = a.size();
    int m = b.size();
    int[][] l = new int[n + 1][m + 1];
    for (int i = n - 1; i >= 0; i--) {
      for (int j = m - 1; j >= 0; j--) {
        l[i][j] =
            key.apply(a.get(i)).equals(key.apply(b.get(j)))
                ? l[i + 1][j + 1] + 1
                : Math.max(l[i + 1][j], l[i][j + 1]);
      }
    }
    Map<Integer, Integer> out = new LinkedHashMap<>();
    int i = 0;
    int j = 0;
    while (i < n && j < m) {
      if (key.apply(a.get(i)).equals(key.apply(b.get(j)))) {
        out.put(i++, j++);
      } else if (l[i + 1][j] >= l[i][j + 1]) {
        i++;
      } else {
        j++;
      }
    }
    return out;
  }

  /** Aligns two mark lists by their markup: index in {@code a} → index in {@code b}. */
  private static Map<Integer, Integer> alignMarks(List<ReviewMark> a, List<ReviewMark> b) {
    return align(a, b, m -> m.markup);
  }

  /**
   * The most base marks a unit may have that a copy no longer holds as written: the combinations
   * of step 2 grow as 2^n. Beyond it the copy's unit is read as an edit (step 4).
   */
  private static final int MAX_DECIDED_MARKS = 16;

  /**
   * The first combination of decisions on {@code b}'s marks (step 2) whose result is {@code
   * target}, or null. Each mark takes leave, accept, reject in that order, the first mark varying
   * slowest. A mark the copy still holds as written can only have been left, and a mark it no
   * longer holds cannot have been, so only the others vary — the same first combination, found
   * without trying the rest.
   */
  private static Map<Integer, Boolean> findVotes(
      String b, List<ReviewMark> marks, Set<Integer> left, String target) {
    List<Integer> free = new ArrayList<>();
    for (int i = 0; i < marks.size(); i++) {
      if (!left.contains(i)) {
        free.add(i);
      }
    }
    if (free.size() > MAX_DECIDED_MARKS) {
      return null;
    }
    for (int combo = 0; combo < 1 << free.size(); combo++) {
      Map<Integer, Boolean> decisions = new LinkedHashMap<>();
      for (int k = 0; k < free.size(); k++) {
        // Bit set: reject; the first mark is the most significant bit.
        decisions.put(free.get(k), ((combo >> (free.size() - 1 - k)) & 1) == 0);
      }
      if (SpecReviewAnnotations.decideReviewMarks(b, decisions).equals(target)) {
        return decisions;
      }
    }
    return null;
  }

  /** Step 4: the copy edited text that holds base marks; it casts no votes. */
  private static UnitReading readAsEdit(String b, String c) {
    String t = SpecReviewAnnotations.applyInlineMarksText(c, true);
    return new UnitReading(
        !t.equals(b),
        t,
        SpecReviewAnnotations.markChangeText(
                SpecReviewAnnotations.applyInlineMarksText(b, false), t)
            .text,
        new LinkedHashMap<>());
  }

  /** What copy unit {@code c} did to base unit {@code b} (SOM §11.9.9, steps 1–4). */
  private static UnitReading readUnit(String b, String c) {
    if (c.equals(b)) {
      return new UnitReading(false, b, b, new LinkedHashMap<>());
    }
    List<ReviewMark> baseMarks = SpecReviewAnnotations.reviewMarks(b);
    List<ReviewMark> copyMarks = SpecReviewAnnotations.reviewMarks(c);
    Map<Integer, Integer> kept = alignMarks(copyMarks, baseMarks);
    // 1. Own marks: the copy's marks that are not the base's.
    Map<Integer, Boolean> reject = new LinkedHashMap<>();
    Map<Integer, Boolean> accept = new LinkedHashMap<>();
    for (int i = 0; i < copyMarks.size(); i++) {
      if (!kept.containsKey(i)) {
        reject.put(i, false);
        accept.put(i, true);
      }
    }
    // 2. Votes: the decisions on the base marks that give c with its own marks rejected.
    String cPrime = SpecReviewAnnotations.decideReviewMarks(c, reject);
    Map<Integer, Boolean> votes =
        findVotes(b, baseMarks, new HashSet<>(kept.values()), cPrime);
    if (votes == null) {
      return readAsEdit(b, c);
    }
    if (reject.isEmpty()) {
      return new UnitReading(false, b, b, votes);
    }
    // 3. Change: the own marks, carried over to the base text where marks were voted on.
    String ownAccepted = SpecReviewAnnotations.decideReviewMarks(c, accept);
    String written =
        votes.isEmpty() ? c : SpecReviewAnnotations.transplantEdits(cPrime, c, b);
    String t =
        votes.isEmpty() ? ownAccepted : SpecReviewAnnotations.transplantEdits(cPrime, ownAccepted, b);
    if (written == null || t == null) {
      return readAsEdit(b, c);
    }
    return new UnitReading(!t.equals(b), t, written, votes);
  }

  /** {@code written} with every mark that is not one of the base's attributed to {@code members}. */
  private static String attribute(String written, List<ReviewMark> baseMarks, List<String> members) {
    List<ReviewMark> marks = SpecReviewAnnotations.reviewMarks(written);
    Map<Integer, Integer> base = alignMarks(marks, baseMarks);
    String out = written;
    for (int k = marks.size() - 1; k >= 0; k--) {
      if (!base.containsKey(k)) {
        out = SpecReviewAnnotations.withAttribution(out, marks.get(k), members, marks.get(k).votes);
      }
    }
    return out;
  }

  /**
   * {@code text} with the copies' votes on the base marks it holds: a base mark every copy decided
   * the same way is applied (accept) or dropped (reject); any other voted change mark gets the
   * votes in its token, {@code agent} as author when it had no token. A highlight or comment mark
   * takes no votes and stays.
   */
  private static String applyVotes(
      String text,
      List<ReviewMark> baseMarks,
      List<UnitReading> readings,
      MergeValue v,
      MergeContext ctx) {
    List<ReviewMark> marks = SpecReviewAnnotations.reviewMarks(text);
    Map<Integer, Integer> base = alignMarks(marks, baseMarks);
    int taking = 0;
    for (UnitReading r : readings) {
      if (r != null) {
        taking++;
      }
    }
    List<SpecReviewMergeReport.Votes> votes = new ArrayList<>();
    List<SpecReviewMergeReport.Unanimous> unanimous = new ArrayList<>();
    String out = text;
    for (int k = marks.size() - 1; k >= 0; k--) {
      Integer b = base.get(k);
      if (b == null) {
        continue;
      }
      List<SpecMarkVote> cast = new ArrayList<>();
      for (int i = 0; i < readings.size(); i++) {
        UnitReading r = readings.get(i);
        Boolean d = r == null ? null : r.votes.get(b);
        if (d != null) {
          cast.add(
              new SpecMarkVote(
                  ctx.members.get(i), d ? SpecMarkDecision.ACCEPT : SpecMarkDecision.REJECT));
        }
      }
      if (cast.isEmpty()) {
        continue;
      }
      ReviewMark m = marks.get(k);
      if (cast.size() == taking && allSame(cast)) {
        boolean accept = cast.get(0).accepts();
        Map<Integer, Boolean> decision = new LinkedHashMap<>();
        decision.put(k, accept);
        out = SpecReviewAnnotations.decideReviewMarks(out, decision);
        ReviewMark bm = baseMarks.get(b);
        unanimous.add(
            0,
            new SpecReviewMergeReport.Unanimous(
                v.path, v.field, bm.markup, cast.get(0).vote, accept ? bm.accepted : bm.rejected));
        continue;
      }
      if (!SpecReviewAnnotations.isChangeMark(m.kind)) {
        continue;
      }
      List<String> authors = m.hasToken() ? m.authors : Collections.singletonList("agent");
      List<SpecMarkVote> merged = new ArrayList<>();
      for (SpecMarkVote x : m.votes) {
        boolean recast = false;
        for (SpecMarkVote y : cast) {
          if (y.member.equals(x.member)) {
            recast = true;
            break;
          }
        }
        if (!recast) {
          merged.add(x);
        }
      }
      merged.addAll(cast);
      out = SpecReviewAnnotations.withAttribution(out, m, authors, merged);
      votes.add(
          0,
          new SpecReviewMergeReport.Votes(
              v.path, v.field, SpecReviewAnnotations.reviewMarks(out).get(k).markup, merged));
    }
    ctx.report.votesList.addAll(votes);
    ctx.report.unanimousList.addAll(unanimous);
    return out;
  }

  private static boolean allSame(List<SpecMarkVote> cast) {
    for (SpecMarkVote x : cast) {
      if (x.vote != cast.get(0).vote) {
        return false;
      }
    }
    return true;
  }

  /** One merged unit: its text, and the conflict block that follows it (or null). */
  private static final class MergedUnit {
    final String text;
    final String conflict;

    MergedUnit(String text, String conflict) {
      this.text = text;
      this.conflict = conflict;
    }
  }

  /**
   * One unit merged: the base text with votes when no copy changed it, the one change attributed
   * to every member who made it, or the base text and a conflict block when the copies changed it
   * differently.
   */
  private static MergedUnit mergeUnit(
      String b, List<String> units, Integer paragraph, MergeValue v, MergeContext ctx) {
    List<UnitReading> readings = new ArrayList<>();
    for (String c : units) {
      readings.add(c == null ? null : readUnit(b, c));
    }
    List<ChangeGroup> groups = changeGroups(readings, ctx.members);
    List<ReviewMark> baseMarks = SpecReviewAnnotations.reviewMarks(b);
    String text = b;
    if (groups.size() == 1) {
      text = attribute(groups.get(0).first.written, baseMarks, groups.get(0).members);
    }
    text = applyVotes(text, baseMarks, readings, v, ctx);
    if (groups.size() < 2) {
      return new MergedUnit(text, null);
    }
    String conflict =
        ctx.conflict(
            "Conflicting changes",
            paragraph == null ? v.where() : v.where() + ", paragraph " + paragraph,
            b,
            groups,
            v.path,
            v.field,
            paragraph);
    return new MergedUnit(text, conflict);
  }

  /**
   * A typed leaf: it cannot hold a mark, so a change by any copy is a {@code Value changed}
   * conflict at the leaf's home, the base value kept.
   */
  private static String mergeTyped(MergeValue v, MergeContext ctx) {
    List<UnitReading> readings = new ArrayList<>();
    for (String c : v.copies) {
      readings.add(
          c == null ? null : new UnitReading(!c.equals(v.base), c, c, new LinkedHashMap<>()));
    }
    List<ChangeGroup> groups = changeGroups(readings, ctx.members);
    if (!groups.isEmpty() && v.conflictHome != null) {
      ctx.append(
          v.conflictHome,
          ctx.conflict("Value changed", v.where(), v.base, groups, v.path, v.field, null));
    }
    return v.base;
  }

  /** A form-field value: always one unit; its conflict goes to the end of the form's preamble. */
  private static String mergeField(MergeValue v, MergeContext ctx) {
    MergedUnit u = mergeUnit(v.base, v.copies, null, v, ctx);
    if (u.conflict != null && v.conflictHome != null) {
      ctx.append(v.conflictHome, u.conflict);
    }
    return u.text;
  }

  /**
   * Whether a copy's block is new: a comment whose id the base lacks, a question block with no
   * base question.
   */
  private static boolean isNewBlock(ReviewPiece piece, MergeContext ctx) {
    if (piece.kind.equals(SpecReviewAnnotationKind.COMMENT.value)) {
      return piece.id == null || !ctx.baseCommentIds.contains(piece.id);
    }
    if (piece.kind.equals(SpecReviewAnnotationKind.QUESTION.value)) {
      if (piece.questionIds.isEmpty()) {
        return false;
      }
      for (String id : piece.questionIds) {
        if (ctx.baseQuestionIds.contains(id)) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  /**
   * The anchor of each block of a value: the index of the text paragraph it follows (-1: before
   * every one). In whole-value mode every block that follows text follows the one unit.
   */
  private static List<Integer> anchors(List<ReviewPiece> pieces, boolean whole) {
    List<Integer> out = new ArrayList<>();
    int texts = -1;
    for (ReviewPiece p : pieces) {
      if (p.isText()) {
        texts++;
        out.add(texts);
      } else {
        out.add(whole ? Math.min(texts, 0) : texts);
      }
    }
    return out;
  }

  private static List<String> textsOf(List<ReviewPiece> pieces) {
    List<String> out = new ArrayList<>();
    for (ReviewPiece p : pieces) {
      if (p.isText()) {
        out.add(p.text);
      }
    }
    return out;
  }

  /**
   * A content value: split into text paragraphs and annotation blocks, merged unit by unit, the
   * copies' new comments and questions placed after the unit they followed. A copy whose
   * text-paragraph count differs from the base's makes the whole text one unit, for every copy.
   */
  private static String mergeContent(MergeValue v, MergeContext ctx) {
    List<ReviewPiece> basePieces = SpecReviewAnnotations.reviewPieces(v.base);
    List<List<ReviewPiece>> copyPieces = new ArrayList<>();
    for (String c : v.copies) {
      copyPieces.add(c == null ? null : SpecReviewAnnotations.reviewPieces(c));
    }
    int baseTextCount = textsOf(basePieces).size();
    boolean whole = false;
    for (List<ReviewPiece> ps : copyPieces) {
      if (ps != null && textsOf(ps).size() != baseTextCount) {
        whole = true;
      }
    }
    List<String> baseUnits = unitsOf(basePieces, whole);
    List<List<String>> copyUnits = new ArrayList<>();
    for (List<ReviewPiece> ps : copyPieces) {
      copyUnits.add(ps == null ? null : unitsOf(ps, whole));
    }

    // Blocks by anchor: the base's first, then each copy's new ones in round order.
    Map<Integer, List<String>> after = new HashMap<>();
    List<Integer> baseAnchors = anchors(basePieces, whole);
    for (int k = 0; k < basePieces.size(); k++) {
      if (!basePieces.get(k).isText()) {
        after.computeIfAbsent(baseAnchors.get(k), x -> new ArrayList<>()).add(basePieces.get(k).text);
      }
    }
    for (int i = 0; i < copyPieces.size(); i++) {
      List<ReviewPiece> ps = copyPieces.get(i);
      if (ps == null) {
        continue;
      }
      List<Integer> as = anchors(ps, false);
      for (int k = 0; k < ps.size(); k++) {
        ReviewPiece p = ps.get(k);
        if (p.isText() || !isNewBlock(p, ctx)) {
          continue;
        }
        int anchor = whole ? baseUnits.size() - 1 : as.get(k);
        after
            .computeIfAbsent(anchor, x -> new ArrayList<>())
            .add(newBlock(p, ctx.members.get(i), v, ctx));
      }
    }

    List<String> out = new ArrayList<>(after.getOrDefault(-1, Collections.emptyList()));
    for (int u = 0; u < baseUnits.size(); u++) {
      List<String> units = new ArrayList<>();
      for (List<String> cs : copyUnits) {
        units.add(cs == null ? null : cs.get(u));
      }
      MergedUnit m = mergeUnit(baseUnits.get(u), units, whole ? null : u, v, ctx);
      if (!m.text.isEmpty()) {
        out.add(m.text);
      }
      if (m.conflict != null) {
        out.add(m.conflict);
      }
      out.addAll(after.getOrDefault(u, Collections.emptyList()));
    }
    return String.join("\n\n", out);
  }

  /** A value's units: its text paragraphs, or in whole-value mode their join as one. */
  private static List<String> unitsOf(List<ReviewPiece> pieces, boolean whole) {
    List<String> texts = textsOf(pieces);
    if (!whole) {
      return texts;
    }
    List<String> out = new ArrayList<>();
    out.add(String.join("\n\n", texts));
    return out;
  }

  /** A copy's new block as merged: a comment renumbered and attributed, a question as written. */
  private static String newBlock(ReviewPiece p, String member, MergeValue v, MergeContext ctx) {
    if (!p.kind.equals(SpecReviewAnnotationKind.COMMENT.value)) {
      return p.text;
    }
    String id = ctx.placeholder('C');
    String author = p.author != null ? p.author : member;
    ctx.pendingComments.put(id, new SpecReviewMergeReport.Comment(id, author, v.path, v.field));
    return String.join("\n", SpecReviewAnnotations.formatCommentBlock(id, p.commentText, author));
  }

  /** One value merged; the base text when no copy differs from it. */
  private static String mergeValue(MergeValue v, MergeContext ctx) {
    boolean unchanged = true;
    for (String c : v.copies) {
      if (c != null && !c.equals(v.base)) {
        unchanged = false;
      }
    }
    if (unchanged) {
      return v.base;
    }
    if (v.typed) {
      return mergeTyped(v, ctx);
    }
    if (v.field != null) {
      return mergeField(v, ctx);
    }
    return mergeContent(v, ctx);
  }

  // -------------------------------------------------------------------------
  // Shared phases over the merged texts.
  // -------------------------------------------------------------------------

  /** The merged document's values, by key, in merged document order. */
  private interface Texts {
    List<String> keys();

    String get(String key);

    void set(String key, String value);
  }

  /** Appends the collected blocks (field and structural conflicts) to the end of their values. */
  private static void applyAppends(Texts texts, MergeContext ctx) {
    for (Map.Entry<String, List<String>> e : ctx.appends.entrySet()) {
      String value = texts.get(e.getKey());
      List<String> parts = new ArrayList<>();
      if (!value.isEmpty()) {
        parts.add(value);
      }
      parts.addAll(e.getValue());
      texts.set(e.getKey(), String.join("\n\n", parts));
    }
  }

  /** The number {@code s} starts with, as JavaScript's {@code parseInt}; null for none. */
  private static Long leadingNumber(String s) {
    int k = 0;
    while (k < s.length() && s.charAt(k) >= '0' && s.charAt(k) <= '9') {
      k++;
    }
    return k == 0 ? null : Long.valueOf(s.substring(0, k));
  }

  /** The highest {@code <prefix>-<n>} of the texts' annotations of the given kinds. */
  private static long highestId(List<String> texts, String prefix, Set<String> kinds) {
    long high = 0;
    for (String t : texts) {
      for (ReviewPiece p : SpecReviewAnnotations.reviewPieces(t)) {
        if (!kinds.contains(p.kind)) {
          continue;
        }
        List<String> ids =
            p.kind.equals(SpecReviewAnnotationKind.QUESTION.value)
                ? p.questionIds
                : Collections.singletonList(p.id);
        for (String id : ids) {
          if (id != null && id.startsWith(prefix + "-")) {
            Long n = leadingNumber(id.substring(prefix.length() + 1));
            if (n != null && n > high) {
              high = n;
            }
          }
        }
      }
    }
    return high;
  }

  private static Set<String> kinds(SpecReviewAnnotationKind kind) {
    return Collections.singleton(kind.value);
  }

  /**
   * Numbers the new comments and conflicts in merged document order, above the base's highest
   * {@code C-<n>} and {@code X-<n>}, and fills their report entries in.
   */
  private static void numberIds(Texts texts, List<String> baseTexts, MergeContext ctx) {
    long[] nextC = {highestId(baseTexts, "C", kinds(SpecReviewAnnotationKind.COMMENT))};
    long[] nextX = {highestId(baseTexts, "X", kinds(SpecReviewAnnotationKind.CONFLICT))};
    for (String key : texts.keys()) {
      String value = texts.get(key);
      if (value.indexOf('\u0001') < 0) {
        continue;
      }
      Matcher m = PLACEHOLDER.matcher(value);
      StringBuilder sb = new StringBuilder();
      while (m.find()) {
        String placeholder = m.group();
        String id;
        if (m.group(1).equals("C")) {
          id = "C-" + (++nextC[0]);
          ctx.report.commentsList.add(ctx.pendingComments.get(placeholder).withId(id));
        } else {
          id = "X-" + (++nextX[0]);
          ctx.report.conflictsList.add(ctx.pendingConflicts.get(placeholder).withId(id));
        }
        m.appendReplacement(sb, Matcher.quoteReplacement(id));
      }
      m.appendTail(sb);
      texts.set(key, sb.toString());
    }
  }

  /** The team answer of every question of {@code texts}, by id, the first occurrence winning. */
  private static Map<String, String> teamAnswers(List<String> texts) {
    Map<String, String> out = new LinkedHashMap<>();
    for (String t : texts) {
      for (Map.Entry<String, String> e : SpecReviewAnnotations.reviewTeamAnswers(t).entrySet()) {
        out.putIfAbsent(e.getKey(), e.getValue());
      }
    }
    return out;
  }

  /**
   * Writes each copy's team answer to a base question, where it differs from the base's, as that
   * member's individual answer (copies in round order).
   */
  private static void mergeAnswers(
      Texts texts, List<String> baseTexts, List<List<String>> copyTexts, MergeContext ctx) {
    Map<String, String> baseAnswers = teamAnswers(baseTexts);
    List<Map<String, String>> copyAnswers = new ArrayList<>();
    for (List<String> ts : copyTexts) {
      copyAnswers.add(teamAnswers(ts));
    }
    for (Map.Entry<String, String> e : baseAnswers.entrySet()) {
      String id = e.getKey();
      List<String> members = new ArrayList<>();
      for (int i = 0; i < copyAnswers.size(); i++) {
        String a = copyAnswers.get(i).get(id);
        if (a == null || a.equals(e.getValue()) || a.isEmpty()) {
          continue;
        }
        for (String key : texts.keys()) {
          String written =
              SpecReviewAnnotations.setIndividualAnswerText(
                  texts.get(key), id, ctx.members.get(i), a);
          if (written == null) {
            continue;
          }
          texts.set(key, written);
          members.add(ctx.members.get(i));
          break;
        }
      }
      if (!members.isEmpty()) {
        ctx.report.answersList.add(new SpecReviewMergeReport.Answers(id, members));
      }
    }
  }

  /** The question proposing guest {@code g} for the next round's team. */
  private static String guestQuestion(String id, SpecReviewMember g) {
    String who = g.role.isEmpty() ? g.displayName : g.displayName + ", " + g.role;
    List<String> options = new ArrayList<>();
    options.add("(a) yes, from the next round on");
    options.add("(b) no, this round only");
    return String.join(
        "\n",
        SpecReviewAnnotations.formatQuestionBlock(
            new SpecQuestionDraft(
                id,
                "Guest " + g.memberId,
                "add " + g.memberId + " (" + who + ") to the review team?",
                options,
                "",
                "",
                false,
                "a")));
  }

  /** Where the guest questions go: a value's key and its path. */
  private static final class Home {
    final String key;
    final String path;

    Home(String key, String path) {
      this.key = key;
      this.path = path;
    }
  }

  /**
   * Lists the reviewers and writes one question per guest to the end of the value at {@code home}
   * (null: the report only), numbered above the base's highest question id with the prefix.
   */
  private static void addGuests(
      Texts texts,
      List<String> baseTexts,
      List<SpecReviewMember> copies,
      SpecReviewMergeOptions options,
      Home home,
      MergeContext ctx) {
    Set<String> team = new HashSet<>();
    for (SpecReviewMember m : options.team) {
      team.add(m.memberId);
    }
    String prefix = options.questionPrefix;
    long n = highestId(baseTexts, prefix, kinds(SpecReviewAnnotationKind.QUESTION));
    for (SpecReviewMember c : copies) {
      boolean guest = !team.contains(c.memberId);
      ctx.report.reviewersList.add(new SpecReviewMergeReport.Reviewer(c, guest));
      if (!guest) {
        continue;
      }
      String id = prefix + "-" + (++n);
      ctx.report.guestQuestionsList.add(
          new SpecReviewMergeReport.GuestQuestion(id, c.memberId, home == null ? null : home.path));
      if (home == null) {
        continue;
      }
      String value = texts.get(home.key);
      texts.set(
          home.key, (value.isEmpty() ? "" : value + "\n\n") + guestQuestion(id, c));
    }
  }

  /** The ids of the comments (first) and questions (second) of {@code texts}. */
  private static List<Set<String>> blockIds(List<String> texts) {
    Set<String> comments = new HashSet<>();
    Set<String> questions = new HashSet<>();
    for (String t : texts) {
      for (ReviewPiece p : SpecReviewAnnotations.reviewPieces(t)) {
        if (p.kind.equals(SpecReviewAnnotationKind.COMMENT.value) && p.id != null) {
          comments.add(p.id);
        }
        questions.addAll(p.questionIds);
      }
    }
    List<Set<String>> out = new ArrayList<>();
    out.add(comments);
    out.add(questions);
    return out;
  }

  private static MergeContext context(List<SpecReviewMember> copies, List<String> baseTexts) {
    List<Set<String>> ids = blockIds(baseTexts);
    return new MergeContext(copies, ids.get(0), ids.get(1));
  }

  /** The phases after the structure, shared by both formats. */
  private static void mergeTexts(
      List<MergeValue> values,
      Function<MergeValue, String> keyOf,
      Texts texts,
      List<String> baseTexts,
      List<List<String>> copyTexts,
      List<SpecReviewMember> copies,
      SpecReviewMergeOptions options,
      Home home,
      MergeContext ctx) {
    for (MergeValue v : values) {
      String merged = mergeValue(v, ctx);
      if (!merged.equals(v.base)) {
        texts.set(keyOf.apply(v), merged);
      }
    }
    applyAppends(texts, ctx);
    numberIds(texts, baseTexts, ctx);
    mergeAnswers(texts, baseTexts, copyTexts, ctx);
    addGuests(texts, baseTexts, copies, options, home, ctx);
  }

  private static <D> List<SpecReviewMember> membersOf(List<SpecReviewedCopy<D>> copies) {
    List<SpecReviewMember> out = new ArrayList<>();
    for (SpecReviewedCopy<D> c : copies) {
      out.add(c.member);
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // Plain Markdown: values by heading path.
  // -------------------------------------------------------------------------

  /** A Markdown file cut at its headings: body {@code i} follows heading {@code i - 1}. */
  private static final class MarkdownSplit {
    final List<String> headings = new ArrayList<>();
    /** The heading path of each body, its heading texts joined by {@code  > } (body 0: empty). */
    final List<String> paths = new ArrayList<>();
    final List<List<String>> bodies = new ArrayList<>();

    MarkdownSplit() {
      paths.add("");
      bodies.add(new ArrayList<>());
    }
  }

  private static final Pattern HEADING = Pattern.compile("(#{1,6})(?:[ \\t]+(.*?))?[ \\t]*");

  private static MarkdownSplit splitMarkdown(String text) {
    MarkdownSplit out = new MarkdownSplit();
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    List<Object[]> stack = new ArrayList<>();
    for (String line : text.split("\n", -1)) {
      boolean wasFenced = fence.inFence();
      fence.feed(line);
      Matcher h = wasFenced || fence.inFence() ? null : HEADING.matcher(line);
      if (h == null || !h.matches()) {
        out.bodies.get(out.bodies.size() - 1).add(line);
        continue;
      }
      int level = h.group(1).length();
      while (!stack.isEmpty() && (Integer) stack.get(stack.size() - 1)[0] >= level) {
        stack.remove(stack.size() - 1);
      }
      stack.add(new Object[] {level, h.group(2) == null ? "" : h.group(2)});
      List<String> names = new ArrayList<>();
      for (Object[] s : stack) {
        names.add((String) s[1]);
      }
      out.headings.add(line);
      out.paths.add(String.join(" > ", names));
      out.bodies.add(new ArrayList<>());
    }
    return out;
  }

  private static boolean isBlank(String s) {
    return SpecReviewAnnotations.trim(s).isEmpty();
  }

  /** A body's blank lines before ({@code [0]}) and after ({@code [1]}) its value. */
  private static int[] bodyMargins(List<String> lines) {
    int lead = 0;
    while (lead < lines.size() && isBlank(lines.get(lead))) {
      lead++;
    }
    if (lead == lines.size()) {
      return new int[] {lead, 0};
    }
    int trail = 0;
    while (isBlank(lines.get(lines.size() - 1 - trail))) {
      trail++;
    }
    return new int[] {lead, trail};
  }

  /** A body's value: its lines without the blank lines around them. */
  private static String bodyValue(List<String> lines) {
    int[] m = bodyMargins(lines);
    if (m[0] == lines.size()) {
      return "";
    }
    return String.join("\n", lines.subList(m[0], lines.size() - m[1]));
  }

  /** The body lines for a new value, keeping the body's blank lines around it. */
  private static List<String> bodyLines(List<String> lines, String value, boolean afterHeading) {
    int[] m = bodyMargins(lines);
    String current = bodyValue(lines);
    if (value.equals(current)) {
      return lines;
    }
    if (value.isEmpty()) {
      return new ArrayList<>(lines.subList(0, m[0]));
    }
    List<String> out = new ArrayList<>();
    if (current.isEmpty()) {
      if (afterHeading) {
        out.add("");
      }
      out.addAll(Arrays.asList(value.split("\n", -1)));
      if (!lines.isEmpty()) {
        out.add("");
      }
      return out;
    }
    out.addAll(lines.subList(0, m[0]));
    out.addAll(Arrays.asList(value.split("\n", -1)));
    out.addAll(lines.subList(lines.size() - m[1], lines.size()));
    return out;
  }

  private static SpecReviewMergeResult<String> mergeMarkdown(
      String base, List<SpecReviewedCopy<String>> copies, SpecReviewMergeOptions options) {
    MarkdownSplit b = splitMarkdown(base);
    List<MarkdownSplit> cs = new ArrayList<>();
    for (SpecReviewedCopy<String> c : copies) {
      MarkdownSplit split = splitMarkdown(c.document);
      boolean fits = split.headings.size() == b.headings.size();
      for (int k = 0; fits && k < split.headings.size(); k++) {
        fits = split.headings.get(k).trim().equals(b.headings.get(k).trim());
      }
      if (!fits) {
        throw new SpecReviewMergeError(
            "the copy of " + c.member.memberId + " has other headings than the base");
      }
      cs.add(split);
    }
    List<String> baseTexts = new ArrayList<>();
    for (List<String> lines : b.bodies) {
      baseTexts.add(bodyValue(lines));
    }
    List<List<String>> copyTexts = new ArrayList<>();
    for (MarkdownSplit c : cs) {
      List<String> ts = new ArrayList<>();
      for (List<String> lines : c.bodies) {
        ts.add(bodyValue(lines));
      }
      copyTexts.add(ts);
    }
    List<String> merged = new ArrayList<>(baseTexts);
    Texts texts =
        new Texts() {
          @Override
          public List<String> keys() {
            List<String> out = new ArrayList<>();
            for (int k = 0; k < merged.size(); k++) {
              out.add(String.valueOf(k));
            }
            return out;
          }

          @Override
          public String get(String key) {
            return merged.get(Integer.parseInt(key));
          }

          @Override
          public void set(String key, String value) {
            merged.set(Integer.parseInt(key), value);
          }
        };
    List<SpecReviewMember> members = membersOf(copies);
    MergeContext ctx = context(members, baseTexts);
    List<MergeValue> values = new ArrayList<>();
    Map<MergeValue, String> keys = new HashMap<>();
    for (int k = 0; k < baseTexts.size(); k++) {
      List<String> perCopy = new ArrayList<>();
      for (List<String> ct : copyTexts) {
        perCopy.add(ct.get(k));
      }
      MergeValue v = new MergeValue(b.paths.get(k), null, baseTexts.get(k), perCopy, false, null);
      values.add(v);
      keys.put(v, String.valueOf(k));
    }
    int first = b.headings.isEmpty() ? 0 : 1;
    mergeTexts(
        values,
        keys::get,
        texts,
        baseTexts,
        copyTexts,
        members,
        options,
        new Home(String.valueOf(first), b.paths.get(first)),
        ctx);
    List<String> lines = new ArrayList<>();
    for (int k = 0; k < b.bodies.size(); k++) {
      if (k > 0) {
        lines.add(b.headings.get(k - 1));
      }
      lines.addAll(bodyLines(b.bodies.get(k), merged.get(k), k > 0));
    }
    return new SpecReviewMergeResult<>(String.join("\n", lines), ctx.report);
  }

  // -------------------------------------------------------------------------
  // SOM documents: values by model path, list items by section id.
  // -------------------------------------------------------------------------

  /**
   * A document's paths with every list item named by its section id instead of its position
   * ({@code DEMO/CARD-LST#CARD-BETA/content}), so the same item has the same name in the base, in
   * every copy and in the merged document.
   */
  private static final class CanonicalPaths {
    final SpecDocument doc;
    private final Map<String, String> listOf = new LinkedHashMap<>();
    private final Map<String, String> ids = new HashMap<>();
    private final Map<String, String> byCanonical = new HashMap<>();
    private final Map<String, String> memo = new HashMap<>();

    CanonicalPaths(SpecDocument doc, SpecReflection refl) {
      this.doc = doc;
      for (String list : doc.listPaths()) {
        SpecResolution res = refl.resolve(list);
        SpecField field = res == null ? null : res.field;
        List<String> items = doc.listItems(list);
        for (int k = 0; k < items.size(); k++) {
          String item = items.get(k);
          listOf.put(item, list);
          ids.put(
              item,
              SpecSectionId.effectiveListItemSectionId(
                  doc.itemSectionId(item),
                  field == null ? null : field.sectionIdPattern,
                  k + 1,
                  field == null ? list : field.name));
        }
      }
      for (String item : listOf.keySet()) {
        byCanonical.put(of(item), item);
      }
    }

    /** The item paths of the list at {@code list}, in order. */
    List<String> items(String list) {
      return doc.listItems(list);
    }

    /** The section id an item is matched by. */
    String idOf(String item) {
      return ids.get(item);
    }

    /** The canonical form of {@code path}. */
    String of(String path) {
      String known = memo.get(path);
      if (known != null) {
        return known;
      }
      String[] segs = path.split("/", -1);
      String out = path;
      for (int k = segs.length; k > 0; k--) {
        String prefix = join(segs, 0, k);
        String list = listOf.get(prefix);
        if (list == null) {
          continue;
        }
        String rest = join(segs, k, segs.length);
        out = of(list) + "#" + idOf(prefix) + (rest.isEmpty() ? "" : "/" + rest);
        break;
      }
      memo.put(path, out);
      return out;
    }

    /** The document's path for a canonical path, or null when the document lacks one of its items. */
    String pathOf(String canonical) {
      String[] segs = canonical.split("/", -1);
      for (int k = segs.length; k > 0; k--) {
        String item = byCanonical.get(join(segs, 0, k));
        if (item == null) {
          continue;
        }
        String rest = join(segs, k, segs.length);
        return item + (rest.isEmpty() ? "" : "/" + rest);
      }
      return canonical.contains("#") ? null : canonical;
    }
  }

  private static String join(String[] segs, int from, int to) {
    return String.join("/", Arrays.asList(segs).subList(from, to));
  }

  /** Whether canonical {@code path} is {@code item} or lies under it. */
  private static boolean under(String path, String item) {
    return path.equals(item) || path.startsWith(item + "/");
  }

  private static boolean underAny(String path, Set<String> items) {
    for (String a : items) {
      if (under(path, a)) {
        return true;
      }
    }
    return false;
  }

  /** A copy whose paths the model does not resolve does not fit the base. */
  private static void checkStructure(SpecDocument doc, String what, SpecReflection refl) {
    List<String> paths = new ArrayList<>(doc.contentPaths());
    paths.addAll(doc.formPaths());
    paths.addAll(doc.headlinePaths());
    paths.addAll(doc.codeSpecPaths());
    for (String list : doc.listPaths()) {
      paths.add(list);
      paths.addAll(doc.listItems(list));
    }
    for (String p : paths) {
      if (refl.resolve(p) == null) {
        throw new SpecReviewMergeError(
            what + " holds " + p + ", a path the base model does not resolve");
      }
    }
  }

  private static SpecDocument copyDocument(SpecDocument doc) {
    SpecDocument out = new SpecDocument();
    out.loadJson(Json.parseObject(Json.write(doc.toJson())));
    return out;
  }

  /** The form field {@code field} of the form at {@code path}, or null. */
  private static FormFieldSpec formField(SpecReflection refl, String path, String field) {
    SpecResolution res = refl.resolve(path);
    if (res == null || res.field == null) {
      return null;
    }
    for (FormFieldSpec f : res.field.formFields) {
      if (f.name.equals(field)) {
        return f;
      }
    }
    return null;
  }

  /**
   * Whether the value at {@code path} / {@code field} is text, which can hold marks: a content
   * value (a form's preamble included) or a String form field that is not code. Scalar and enum
   * leaves, and typed or code fields, are not.
   */
  private static boolean isText(SpecReflection refl, String path, String field) {
    if (field != null) {
      FormFieldSpec spec = formField(refl, path, field);
      return spec == null || ("String".equals(spec.type) && !spec.code);
    }
    SpecResolution res = refl.resolve(path);
    if (res == null) {
      return true;
    }
    if (res.kind == SpecNodeKind.SCALAR || res.kind == SpecNodeKind.ENUM_VALUE) {
      return false;
    }
    return res.kind != SpecNodeKind.LIST_ITEM_SCALAR
        || (res.field != null && "String".equals(res.field.elementType));
  }

  /**
   * The first node at or below {@code path} that holds content (a content leaf or a form's
   * preamble), in model order.
   */
  private static String firstContentSlot(SpecReflection refl, String path, boolean deep) {
    SpecResolution res = refl.resolve(path);
    if (res == null) {
      return null;
    }
    if (res.kind == SpecNodeKind.CONTENT || res.kind == SpecNodeKind.FORM) {
      return path;
    }
    SpecClass cls = res.targetClass;
    if (cls == null) {
      return null;
    }
    for (SpecField f : cls.fields) {
      String child = path + "/" + refl.fieldSegment(f);
      if (f.kind == SpecFieldKind.CONTENT || f.kind == SpecFieldKind.FORM) {
        return child;
      }
      if (deep && (f.kind == SpecFieldKind.COMPLEX || f.kind == SpecFieldKind.SECTION)) {
        String found = firstContentSlot(refl, child, true);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  /**
   * Where a block about the node at {@code path} goes (SOM §11.9.9, "Structure"): the first content
   * value at or below it in document order; else the first node at or below it that can hold
   * content; else its nearest ancestor's own.
   */
  private static String blockHome(
      SpecDocument doc, SpecReflection refl, String path, boolean ownFirst) {
    if (ownFirst) {
      List<String> existing = new ArrayList<>();
      for (String p : doc.contentPaths()) {
        if (under(p, path)) {
          existing.add(p);
        }
      }
      if (!existing.isEmpty()) {
        Collections.sort(existing);
        return existing.get(0);
      }
      String slot = firstContentSlot(refl, path, true);
      if (slot != null) {
        return slot;
      }
    }
    for (String a = SpecPaths.parentPath(path); !a.isEmpty(); ) {
      if (doc.content(a) != null) {
        return a;
      }
      String slot = firstContentSlot(refl, a, false);
      if (slot != null) {
        return slot;
      }
      String parent = SpecPaths.parentPath(a);
      if (parent.equals(a)) {
        break;
      }
      a = parent;
    }
    return null;
  }

  /** One structural change the copies disagree with the base on. */
  private static final class Structural {
    /** The canonical path of the item (or section) concerned. */
    final String node;
    /** {@code Item removed}, {@code Item moved} or {@code Headline changed}. */
    final String topic;
    final String base;
    final List<ChangeGroup> groups = new ArrayList<>();

    Structural(String node, String topic, String base) {
      this.node = node;
      this.topic = topic;
      this.base = base;
    }
  }

  private static void addStructural(
      List<Structural> all, String node, String topic, String base, String text, String member) {
    Structural s = null;
    for (Structural x : all) {
      if (x.node.equals(node) && x.topic.equals(topic)) {
        s = x;
        break;
      }
    }
    if (s == null) {
      s = new Structural(node, topic, base);
      all.add(s);
    }
    for (ChangeGroup g : s.groups) {
      if (g.text.equals(text)) {
        g.members.add(member);
        return;
      }
    }
    s.groups.add(new ChangeGroup(text, member, null));
  }

  /** The ids of {@code ids} that are not in their longest common subsequence with {@code order}. */
  private static Set<String> moved(List<String> order, List<String> ids) {
    Set<String> stay = new HashSet<>();
    for (Map.Entry<Integer, Integer> e : align(order, ids, x -> x).entrySet()) {
      stay.add(order.get(e.getKey()));
    }
    Set<String> out = new LinkedHashSet<>();
    for (String id : ids) {
      if (!stay.contains(id)) {
        out.add(id);
      }
    }
    return out;
  }

  private static final Pattern FENCE_START = Pattern.compile("^\\s*(```|~~~)");

  /** {@code value} written as attributed insertions, one per text paragraph (an added item's text). */
  private static String asInsertion(String value, List<String> members) {
    String token = "{@" + String.join(",", members) + "}";
    List<String> out = new ArrayList<>();
    for (ReviewPiece p : SpecReviewAnnotations.reviewPieces(value)) {
      out.add(
          !p.isText() || FENCE_START.matcher(p.text).find()
              ? p.text
              : "{++ " + SpecReviewAnnotations.trim(p.text) + " ++}" + token);
    }
    return String.join("\n\n", out);
  }

  /** {@code p} with the longest moved prefix replaced by its new path. */
  private static String remap(Map<String, String> moved, String p) {
    String[] segs = p.split("/", -1);
    for (int k = segs.length; k > 0; k--) {
      String target = moved.get(join(segs, 0, k));
      if (target != null) {
        String rest = join(segs, k, segs.length);
        return rest.isEmpty() ? target : target + "/" + rest;
      }
    }
    return p;
  }

  private static List<String> pathsUnder(Iterable<String> paths, String from) {
    List<String> out = new ArrayList<>();
    for (String p : paths) {
      if (under(p, from)) {
        out.add(p);
      }
    }
    return out;
  }

  /** Copies item {@code from} of {@code src}, with everything under it, to item {@code to} of {@code dst}. */
  private static void copyItem(
      SpecDocument src,
      String from,
      SpecDocument dst,
      String to,
      List<String> members,
      SpecReflection refl) {
    Map<String, String> moved = new HashMap<>();
    moved.put(from, to);
    List<String> lists = pathsUnder(src.listPaths(), from);
    // Outer lists first (a stable sort keeps the document's order among equals).
    lists.sort(Comparator.comparingInt(l -> l.split("/", -1).length));
    CanonicalPaths canonical = new CanonicalPaths(src, refl);
    for (String list : lists) {
      for (String item : src.listItems(list)) {
        moved.put(item, dst.addListItem(remap(moved, list), canonical.idOf(item)));
      }
    }
    for (String p : pathsUnder(src.contentPaths(), from)) {
      String value = src.content(p);
      dst.setContent(remap(moved, p), isText(refl, p, null) ? asInsertion(value, members) : value);
    }
    for (String p : pathsUnder(src.formPaths(), from)) {
      for (String f : src.formFieldNames(p)) {
        String value = src.formField(p, f);
        dst.setFormField(
            remap(moved, p), f, isText(refl, p, f) ? asInsertion(value, members) : value);
      }
    }
    for (String p : pathsUnder(src.headlinePaths(), from)) {
      dst.setHeadline(remap(moved, p), src.headline(p));
    }
    for (String p : pathsUnder(src.codeSpecPaths(), from)) {
      dst.setCodeSpec(remap(moved, p), src.codeSpec(p));
    }
  }

  /**
   * Everything under an item, as one comparable value: copies adding the same item alike add it
   * once. Paths are written relative to the item, since the item's own path is a position.
   */
  @SuppressWarnings("unchecked")
  private static String itemSignature(SpecDocument doc, String item) {
    Map<String, Object> json = doc.toJson();
    List<Object> parts = new ArrayList<>();
    for (String store : new String[] {"content", "forms", "headlines", "lists"}) {
      List<Object> picked = new ArrayList<>();
      Object raw = json.get(store);
      if (raw instanceof Map) {
        for (Map.Entry<String, Object> e : ((Map<String, Object>) raw).entrySet()) {
          if (under(e.getKey(), item)) {
            List<Object> pair = new ArrayList<>();
            pair.add(e.getKey().substring(item.length()));
            pair.add(e.getValue());
            picked.add(pair);
          }
        }
      }
      parts.add(picked);
    }
    // Nested item paths start with the item's own path, which is a position: cut it.
    String own = Json.write(item);
    own = own.substring(0, own.length() - 1);
    return Json.write(parts).replace(own, "\"");
  }

  /** The copies adding one item: the first one's position and version, and every member alike. */
  private static final class AddGroup {
    final int copy;
    final String anchor;
    final List<String> members = new ArrayList<>();
    final String signature;

    AddGroup(int copy, String anchor, String member, String signature) {
      this.copy = copy;
      this.anchor = anchor;
      this.members.add(member);
      this.signature = signature;
    }
  }

  private static int depth(String canonical) {
    return canonical.split("#", -1).length;
  }

  /**
   * The structure phase: items the copies added are added (attributed to every copy that added
   * them alike); items removed or moved, and changed headlines, become structural conflicts.
   * Returns the canonical paths of the added items.
   */
  private static Set<String> mergeStructure(
      SpecDocument merged,
      SpecDocument base,
      List<SpecReviewedCopy<SpecDocument>> copies,
      SpecReflection refl,
      SpecModel model,
      MergeContext ctx) {
    CanonicalPaths baseCanon = new CanonicalPaths(base, refl);
    List<CanonicalPaths> copyCanon = new ArrayList<>();
    for (SpecReviewedCopy<SpecDocument> c : copies) {
      copyCanon.add(new CanonicalPaths(c.document, refl));
    }
    Set<String> added = new LinkedHashSet<>();
    List<Structural> structural = new ArrayList<>();
    List<String> additionNodes = new ArrayList<>();
    List<List<String>> additionMembers = new ArrayList<>();
    Set<String> lists = new LinkedHashSet<>();
    for (String l : base.listPaths()) {
      lists.add(baseCanon.of(l));
    }
    for (int i = 0; i < copies.size(); i++) {
      for (String l : copies.get(i).document.listPaths()) {
        lists.add(copyCanon.get(i).of(l));
      }
    }
    List<String> ordered = new ArrayList<>(lists);
    ordered.sort(Comparator.comparingInt(SpecReviewMerge::depth).thenComparing(x -> x));
    for (String list : ordered) {
      if (underAny(list, added)) {
        continue;
      }
      String basePath = baseCanon.pathOf(list);
      if (basePath == null) {
        continue;
      }
      List<String> baseIds = new ArrayList<>();
      for (String p : baseCanon.items(basePath)) {
        baseIds.add(baseCanon.idOf(p));
      }
      Map<String, AddGroup> groups = new LinkedHashMap<>();
      for (int i = 0; i < copies.size(); i++) {
        SpecReviewedCopy<SpecDocument> c = copies.get(i);
        String copyPath = copyCanon.get(i).pathOf(list);
        if (copyPath == null) {
          continue;
        }
        List<String> items = copyCanon.get(i).items(copyPath);
        List<String> ids = new ArrayList<>();
        for (String p : items) {
          ids.add(copyCanon.get(i).idOf(p));
        }
        String member = c.member.memberId;
        for (int k = 0; k < ids.size(); k++) {
          String id = ids.get(k);
          if (baseIds.contains(id)) {
            continue;
          }
          String signature = itemSignature(c.document, items.get(k));
          AddGroup g = groups.get(id);
          if (g == null) {
            String anchor = null;
            for (int a = k - 1; a >= 0; a--) {
              if (baseIds.contains(ids.get(a))) {
                anchor = ids.get(a);
                break;
              }
            }
            groups.put(id, new AddGroup(i, anchor, member, signature));
          } else if (g.signature.equals(signature)) {
            g.members.add(member);
          }
        }
        for (String id : baseIds) {
          if (!ids.contains(id)) {
            addStructural(structural, list + "#" + id, "Item removed", "kept", "removed", member);
          }
        }
        List<String> keptOrder = new ArrayList<>();
        for (String x : baseIds) {
          if (ids.contains(x)) {
            keptOrder.add(x);
          }
        }
        List<String> keptIds = new ArrayList<>();
        for (String x : ids) {
          if (baseIds.contains(x)) {
            keptIds.add(x);
          }
        }
        for (String id : moved(keptOrder, keptIds)) {
          addStructural(
              structural,
              list + "#" + id,
              "Item moved",
              "position " + (baseIds.indexOf(id) + 1),
              "moved to position " + (ids.indexOf(id) + 1),
              member);
        }
      }
      for (Map.Entry<String, AddGroup> e : groups.entrySet()) {
        String id = e.getKey();
        AddGroup g = e.getValue();
        CanonicalPaths mergedCanon = new CanonicalPaths(merged, refl);
        String listPath = mergedCanon.pathOf(list);
        List<String> mergedIds = new ArrayList<>();
        for (String p : mergedCanon.items(listPath)) {
          mergedIds.add(mergedCanon.idOf(p));
        }
        int at = g.anchor == null ? 0 : mergedIds.indexOf(g.anchor) + 1;
        while (at < mergedIds.size() && !baseIds.contains(mergedIds.get(at))) {
          at++;
        }
        String item = merged.addListItem(listPath, id);
        if (at < mergedIds.size()) {
          item = merged.moveListItem(model, item, at).path;
        }
        SpecDocument src = copies.get(g.copy).document;
        copyItem(
            src, copyCanon.get(g.copy).pathOf(list + "#" + id), merged, item, g.members, refl);
        added.add(list + "#" + id);
        additionNodes.add(list + "#" + id);
        additionMembers.add(g.members);
      }
    }
    headlineChanges(base, baseCanon, copies, copyCanon, added, structural);
    CanonicalPaths mergedCanon = new CanonicalPaths(merged, refl);
    for (int k = 0; k < additionNodes.size(); k++) {
      ctx.report.additionsList.add(
          new SpecReviewMergeReport.Addition(
              mergedCanon.pathOf(additionNodes.get(k)), additionMembers.get(k)));
    }
    for (Structural s : structural) {
      String node = mergedCanon.pathOf(s.node);
      String home = blockHome(merged, refl, node, true);
      String block = ctx.conflict(s.topic, node, s.base, s.groups, node, null, null);
      if (home != null) {
        ctx.append(contentKey(home), block);
      }
    }
    return added;
  }

  /** Every headline a copy changed (items it added aside) is a structural conflict. */
  private static void headlineChanges(
      SpecDocument base,
      CanonicalPaths baseCanon,
      List<SpecReviewedCopy<SpecDocument>> copies,
      List<CanonicalPaths> copyCanon,
      Set<String> added,
      List<Structural> structural) {
    Set<String> nodes = new HashSet<>();
    for (String p : base.headlinePaths()) {
      nodes.add(baseCanon.of(p));
    }
    for (int i = 0; i < copies.size(); i++) {
      for (String p : copies.get(i).document.headlinePaths()) {
        nodes.add(copyCanon.get(i).of(p));
      }
    }
    List<String> sorted = new ArrayList<>(nodes);
    Collections.sort(sorted);
    for (String node : sorted) {
      if (underAny(node, added)) {
        continue;
      }
      String basePath = baseCanon.pathOf(node);
      if (basePath == null) {
        continue;
      }
      String was = Objects.toString(base.headline(basePath), "");
      for (int i = 0; i < copies.size(); i++) {
        String path = copyCanon.get(i).pathOf(node);
        if (path == null) {
          continue;
        }
        String now = Objects.toString(copies.get(i).document.headline(path), "");
        if (!now.equals(was)) {
          addStructural(
              structural, node, "Headline changed", was, now, copies.get(i).member.memberId);
        }
      }
    }
  }

  /** The keys of the SOM texts: {@code c\0<path>} for content, {@code f\0<path>\0<field>} for a field. */
  private static String contentKey(String path) {
    return "c\u0000" + path;
  }

  private static String fieldKey(String path, String field) {
    return "f\u0000" + path + "\u0000" + field;
  }

  private static List<String> sorted(Set<String> keys) {
    List<String> out = new ArrayList<>(keys);
    Collections.sort(out);
    return out;
  }

  /**
   * The SOM document's values as {@link Texts}, in document order (content sorted, then forms and
   * fields sorted).
   */
  private static Texts somTexts(SpecDocument doc) {
    return new Texts() {
      @Override
      public List<String> keys() {
        List<String> out = new ArrayList<>();
        for (String p : sorted(doc.contentPaths())) {
          out.add(contentKey(p));
        }
        for (String p : sorted(doc.formPaths())) {
          for (String f : sorted(doc.formFieldNames(p))) {
            out.add(fieldKey(p, f));
          }
        }
        return out;
      }

      @Override
      public String get(String key) {
        String[] k = key.split("\u0000", -1);
        String v = k[0].equals("c") ? doc.content(k[1]) : doc.formField(k[1], k[2]);
        return v == null ? "" : v;
      }

      @Override
      public void set(String key, String value) {
        String[] k = key.split("\u0000", -1);
        if (k[0].equals("c")) {
          doc.setContent(k[1], value);
        } else {
          doc.setFormField(k[1], k[2], value);
        }
      }
    };
  }

  private static List<String> valuesOf(Texts texts) {
    List<String> out = new ArrayList<>();
    for (String k : texts.keys()) {
      out.add(texts.get(k));
    }
    return out;
  }

  private static String read(SpecDocument doc, String path, String field) {
    String v = field == null ? doc.content(path) : doc.formField(path, field);
    return v == null ? "" : v;
  }

  /**
   * The values to merge: every value of the base and of the copies, items the copies added aside,
   * located in the merged document; in its document order.
   */
  private static List<MergeValue> somValues(
      SpecDocument merged,
      SpecDocument base,
      List<SpecReviewedCopy<SpecDocument>> copies,
      Set<String> added,
      SpecReflection refl) {
    CanonicalPaths baseCanon = new CanonicalPaths(base, refl);
    List<CanonicalPaths> copyCanon = new ArrayList<>();
    for (SpecReviewedCopy<SpecDocument> c : copies) {
      copyCanon.add(new CanonicalPaths(c.document, refl));
    }
    CanonicalPaths mergedCanon = new CanonicalPaths(merged, refl);
    Map<String, String[]> keys = new LinkedHashMap<>();
    collect(base, baseCanon, keys);
    for (int i = 0; i < copies.size(); i++) {
      collect(copies.get(i).document, copyCanon.get(i), keys);
    }
    List<MergeValue> values = new ArrayList<>();
    for (String[] nf : keys.values()) {
      String node = nf[0];
      String field = nf[1];
      if (underAny(node, added)) {
        continue;
      }
      String basePath = baseCanon.pathOf(node);
      if (basePath == null) {
        continue;
      }
      String path = mergedCanon.pathOf(node);
      boolean text = isText(refl, path, field);
      List<String> perCopy = new ArrayList<>();
      for (int i = 0; i < copies.size(); i++) {
        String p = copyCanon.get(i).pathOf(node);
        perCopy.add(p == null ? null : read(copies.get(i).document, p, field));
      }
      String conflictHome;
      if (field != null) {
        conflictHome = contentKey(path);
      } else if (text) {
        conflictHome = null;
      } else {
        String home = blockHome(merged, refl, path, false);
        conflictHome = home == null ? null : contentKey(home);
      }
      values.add(
          new MergeValue(path, field, read(base, basePath, field), perCopy, !text, conflictHome));
    }
    values.sort(Comparator.comparing(SpecReviewMerge::documentOrder));
    return values;
  }

  private static String documentOrder(MergeValue v) {
    return (v.field == null ? "0" : "1")
        + "\u0000"
        + v.path
        + "\u0000"
        + (v.field == null ? "" : v.field);
  }

  private static void collect(SpecDocument doc, CanonicalPaths canon, Map<String, String[]> keys) {
    for (String p : doc.contentPaths()) {
      keys.put(contentKey(canon.of(p)), new String[] {canon.of(p), null});
    }
    for (String p : doc.formPaths()) {
      for (String f : doc.formFieldNames(p)) {
        keys.put(fieldKey(canon.of(p), f), new String[] {canon.of(p), f});
      }
    }
  }

  /** The class field of {@code cls} named {@code name} with kind {@code kind}, or null. */
  private static SpecField classField(SpecClass cls, String name, SpecFieldKind kind) {
    SpecField f = cls == null ? null : cls.fieldNamed(name);
    return f != null && f.kind == kind ? f : null;
  }

  /** The model classes the revision entry is written with ({@code tom_specs_model}'s front matter). */
  private static final String REVISION_ENTRY = "RevisionEntry";

  private static final String DOCUMENT_HEADER = "DocumentHeader";

  private static final Pattern VERSION = Pattern.compile("([0-9]+)\\.([0-9]+)(\\.[0-9]+)?");

  /** The next minor of a {@code major.minor[.patch]} version; {@code 0.1.0} for anything else. */
  private static String nextMinor(String version) {
    Matcher m = VERSION.matcher(SpecReviewAnnotations.trim(version == null ? "" : version));
    if (!m.matches()) {
      return "0.1.0";
    }
    String minor = m.group(1) + "." + (Long.parseLong(m.group(2)) + 1);
    return m.group(3) == null ? minor : minor + ".0";
  }

  private static final Pattern ISO_DATE = Pattern.compile("[0-9]{4}-([0-9]{2})-([0-9]{2})");

  /** The month and day of an ISO 8601 date. */
  private static int[] monthDay(String date) {
    Matcher m = ISO_DATE.matcher(date == null ? "" : date);
    if (!m.lookingAt()) {
      throw new SpecReviewMergeError("options.date \"" + date + "\" is not an ISO 8601 date");
    }
    return new int[] {Integer.parseInt(m.group(1)), Integer.parseInt(m.group(2))};
  }

  /** Adds an item with a generated id to the list {@code field} at {@code list}, and returns its path. */
  private static String addGeneratedItem(
      SpecDocument doc, String list, SpecField field, int[] date) {
    String id =
        SpecSectionId.generateListItemSectionId(
            field.sectionIdPattern != null ? field.sectionIdPattern : field.name + "-xxx",
            date[0],
            date[1],
            doc.listItemSectionIds(list));
    return doc.addListItem(list, id);
  }

  /** Writes one reviewer record into the list {@code field} at {@code list}. */
  private static void addReviewerRecord(
      SpecDocument doc,
      SpecReflection refl,
      String list,
      SpecField field,
      SpecReviewMember member,
      boolean guest,
      int[] date) {
    String item = addGeneratedItem(doc, list, field, date);
    SpecField form =
        classField(refl.classNamed(field.elementType), "content", SpecFieldKind.FORM);
    if (form == null) {
      return;
    }
    String path = item + "/" + refl.fieldSegment(form);
    doc.setFormField(path, "memberId", member.memberId);
    doc.setFormField(path, "displayName", member.displayName);
    doc.setFormField(path, "role", member.role);
    if (guest) {
      doc.setFormField(path, "guest", "true");
    }
  }

  private static SpecClass rootClass(SpecReflection refl, String root) {
    SpecRoot r = root == null ? null : refl.rootForSegment(root);
    return r == null ? null : refl.classNamed(r.type);
  }

  /**
   * Appends the draft revision entry when the root has a revision history: the next minor
   * version, the date and author, the team the round started with and every reviewer who returned
   * a copy, guests marked.
   */
  private static void addRevisionEntry(
      SpecDocument merged,
      String root,
      List<SpecReviewMember> copies,
      SpecReviewMergeOptions options,
      SpecReflection refl,
      MergeContext ctx) {
    SpecClass rootClass = rootClass(refl, root);
    if (rootClass == null) {
      return;
    }
    SpecField history = null;
    SpecField header = null;
    for (SpecField f : rootClass.fields) {
      if (history == null
          && f.kind == SpecFieldKind.LIST
          && REVISION_ENTRY.equals(f.elementType)) {
        history = f;
      }
      if (header == null && DOCUMENT_HEADER.equals(f.type)) {
        header = f;
      }
    }
    if (history == null) {
      return;
    }
    int[] date = monthDay(options.date);
    SpecField headerForm =
        header == null
            ? null
            : classField(refl.classNamed(DOCUMENT_HEADER), "content", SpecFieldKind.FORM);
    String current =
        header != null && headerForm != null
            ? merged.formField(
                root + "/" + refl.fieldSegment(header) + "/" + refl.fieldSegment(headerForm),
                "version")
            : null;
    String version = nextMinor(current);
    String item =
        addGeneratedItem(merged, root + "/" + refl.fieldSegment(history), history, date);
    SpecClass entry = refl.classNamed(REVISION_ENTRY);
    SpecField form = classField(entry, "content", SpecFieldKind.FORM);
    if (form != null) {
      String path = item + "/" + refl.fieldSegment(form);
      merged.setFormField(path, "version", version);
      merged.setFormField(path, "date", options.date);
      merged.setFormField(path, "author", options.author);
    }
    Set<String> team = new HashSet<>();
    for (SpecReviewMember m : options.team) {
      team.add(m.memberId);
    }
    addRecords(merged, refl, entry, item, "reviewTeam", options.team, m -> false, date);
    addRecords(
        merged, refl, entry, item, "reviewers", copies, m -> !team.contains(m.memberId), date);
    ctx.report.revisionEntry = new SpecReviewMergeReport.Revision(item, version);
  }

  /** Writes one record per member into the revision entry's list {@code name}, if it has one. */
  private static void addRecords(
      SpecDocument merged,
      SpecReflection refl,
      SpecClass entry,
      String item,
      String name,
      List<SpecReviewMember> members,
      Predicate<SpecReviewMember> guest,
      int[] date) {
    SpecField list = classField(entry, name, SpecFieldKind.LIST);
    if (list == null) {
      return;
    }
    for (SpecReviewMember m : members) {
      addReviewerRecord(
          merged, refl, item + "/" + refl.fieldSegment(list), list, m, guest.test(m), date);
    }
  }

  /** The root segment of a document: the first segment of its paths. */
  @SuppressWarnings("unchecked")
  private static String rootOf(SpecDocument doc, SpecReflection refl) {
    Map<String, Object> json = doc.toJson();
    for (String store : new String[] {"content", "forms", "lists", "headlines"}) {
      Object raw = json.get(store);
      if (raw instanceof Map && !((Map<String, Object>) raw).isEmpty()) {
        String any = ((Map<String, Object>) raw).keySet().iterator().next();
        return any.split("/", -1)[0];
      }
    }
    return refl.roots().isEmpty() ? null : refl.rootSegment(refl.roots().get(0));
  }

  private static SpecReviewMergeResult<SpecDocument> mergeSom(
      SpecDocument base,
      List<SpecReviewedCopy<SpecDocument>> copies,
      SpecReviewMergeOptions options,
      SpecModel model) {
    SpecReflection refl = new SpecReflection(model);
    checkStructure(base, "the base", refl);
    for (SpecReviewedCopy<SpecDocument> c : copies) {
      checkStructure(c.document, "the copy of " + c.member.memberId, refl);
    }
    List<String> baseValues = valuesOf(somTexts(base));
    List<List<String>> copyValues = new ArrayList<>();
    for (SpecReviewedCopy<SpecDocument> c : copies) {
      copyValues.add(valuesOf(somTexts(c.document)));
    }
    List<SpecReviewMember> members = membersOf(copies);
    MergeContext ctx = context(members, baseValues);
    SpecDocument merged = copyDocument(base);
    Set<String> added = mergeStructure(merged, base, copies, refl, model, ctx);
    List<MergeValue> values = somValues(merged, base, copies, added, refl);
    String root = rootOf(base, refl);
    SpecField rootContent =
        classField(rootClass(refl, root), "content", SpecFieldKind.CONTENT);
    Home home = null;
    if (root != null && rootContent != null) {
      String path = root + "/" + refl.fieldSegment(rootContent);
      home = new Home(contentKey(path), path);
    }
    mergeTexts(
        values,
        v -> v.field == null ? contentKey(v.path) : fieldKey(v.path, v.field),
        somTexts(merged),
        baseValues,
        copyValues,
        members,
        options,
        home,
        ctx);
    if (root != null) {
      addRevisionEntry(merged, root, members, options, refl, ctx);
    }
    return new SpecReviewMergeResult<>(merged, ctx.report);
  }
}
