package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * The merge report of {@link SpecReviewMerge#mergeReviews} (SOM §11.9.9), every list in merged
 * document order. The lists are filled by the merge and read-only to everybody else.
 */
public final class SpecReviewMergeReport {
  /** A reviewer as the report lists it. */
  public static final class Reviewer {
    public final SpecReviewMember member;
    /** Whether the reviewer was not in the team the round started with. */
    public final boolean guest;

    Reviewer(SpecReviewMember member, boolean guest) {
      this.member = member;
      this.guest = guest;
    }
  }

  /** A conflict block the merge wrote. */
  public static final class Conflict {
    public final String id;
    public final String path;
    /** The form field, or null for content. */
    public final String field;
    /** The unit's index among the value's text paragraphs; null for a whole value or a structural conflict. */
    public final Integer paragraph;
    public final List<String> members;

    Conflict(String id, String path, String field, Integer paragraph, List<String> members) {
      this.id = id;
      this.path = path;
      this.field = field;
      this.paragraph = paragraph;
      this.members = Collections.unmodifiableList(new ArrayList<>(members));
    }

    Conflict withId(String newId) {
      return new Conflict(newId, path, field, paragraph, members);
    }
  }

  /** A base mark left with votes. */
  public static final class Votes {
    public final String path;
    public final String field;
    /** The mark as merged, its token carrying the votes. */
    public final String markup;
    public final List<SpecMarkVote> votes;

    Votes(String path, String field, String markup, List<SpecMarkVote> votes) {
      this.path = path;
      this.field = field;
      this.markup = markup;
      this.votes = Collections.unmodifiableList(new ArrayList<>(votes));
    }
  }

  /** A base mark every copy decided the same way, applied or dropped. */
  public static final class Unanimous {
    public final String path;
    public final String field;
    /** The mark as the base wrote it. */
    public final String markup;
    /** {@link SpecMarkDecision#ACCEPT} or {@link SpecMarkDecision#REJECT}. */
    public final SpecMarkDecision decision;
    public final String result;

    Unanimous(String path, String field, String markup, SpecMarkDecision decision, String result) {
      this.path = path;
      this.field = field;
      this.markup = markup;
      this.decision = decision;
      this.result = result;
    }
  }

  /** A base question the copies answered. */
  public static final class Answers {
    public final String questionId;
    public final List<String> members;

    Answers(String questionId, List<String> members) {
      this.questionId = questionId;
      this.members = Collections.unmodifiableList(new ArrayList<>(members));
    }
  }

  /** A new comment. */
  public static final class Comment {
    public final String id;
    public final String author;
    public final String path;
    public final String field;

    Comment(String id, String author, String path, String field) {
      this.id = id;
      this.author = author;
      this.path = path;
      this.field = field;
    }

    Comment withId(String newId) {
      return new Comment(newId, author, path, field);
    }
  }

  /** An item a copy added. */
  public static final class Addition {
    public final String path;
    public final List<String> members;

    Addition(String path, List<String> members) {
      this.path = path;
      this.members = Collections.unmodifiableList(new ArrayList<>(members));
    }
  }

  /** The question proposing a guest for the next round's team. */
  public static final class GuestQuestion {
    public final String id;
    public final String memberId;
    /** Where it was written; null when the document has no place for it. */
    public final String path;

    GuestQuestion(String id, String memberId, String path) {
      this.id = id;
      this.memberId = memberId;
      this.path = path;
    }
  }

  /** The draft revision entry the merge appended. */
  public static final class Revision {
    public final String path;
    public final String version;

    Revision(String path, String version) {
      this.path = path;
      this.version = version;
    }
  }

  final List<Reviewer> reviewersList = new ArrayList<>();
  final List<Conflict> conflictsList = new ArrayList<>();
  final List<Votes> votesList = new ArrayList<>();
  final List<Unanimous> unanimousList = new ArrayList<>();
  final List<Answers> answersList = new ArrayList<>();
  final List<Comment> commentsList = new ArrayList<>();
  final List<Addition> additionsList = new ArrayList<>();
  final List<GuestQuestion> guestQuestionsList = new ArrayList<>();
  Revision revisionEntry;

  /** Every copy's reviewer, in round order. */
  public List<Reviewer> reviewers() {
    return Collections.unmodifiableList(reviewersList);
  }

  /** The conflict blocks written. */
  public List<Conflict> conflicts() {
    return Collections.unmodifiableList(conflictsList);
  }

  /** The base marks left with votes. */
  public List<Votes> votes() {
    return Collections.unmodifiableList(votesList);
  }

  /** The base marks applied or dropped because every copy decided them alike. */
  public List<Unanimous> unanimous() {
    return Collections.unmodifiableList(unanimousList);
  }

  /** The base questions the copies answered. */
  public List<Answers> answers() {
    return Collections.unmodifiableList(answersList);
  }

  /** The new comments. */
  public List<Comment> comments() {
    return Collections.unmodifiableList(commentsList);
  }

  /** The items the copies added. */
  public List<Addition> additions() {
    return Collections.unmodifiableList(additionsList);
  }

  /** The questions proposing guests for the next round's team. */
  public List<GuestQuestion> guestQuestions() {
    return Collections.unmodifiableList(guestQuestionsList);
  }

  /** The draft revision entry, or null when the document has no revision history. */
  public Revision revision() {
    return revisionEntry;
  }

  private static List<Object> voteList(List<SpecMarkVote> votes) {
    List<Object> out = new ArrayList<>();
    for (SpecMarkVote v : votes) {
      out.add(v.toJson());
    }
    return out;
  }

  /** The canonical JSON form {@code review_merge_cases.json} pins. */
  public Map<String, Object> toJson() {
    List<Object> reviewers = new ArrayList<>();
    for (Reviewer r : reviewersList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("memberId", r.member.memberId);
      o.put("displayName", r.member.displayName);
      o.put("role", r.member.role);
      o.put("guest", r.guest);
      reviewers.add(o);
    }
    List<Object> conflicts = new ArrayList<>();
    for (Conflict c : conflictsList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("id", c.id);
      o.put("path", c.path);
      o.put("field", c.field);
      o.put("paragraph", c.paragraph);
      o.put("members", new ArrayList<Object>(c.members));
      conflicts.add(o);
    }
    List<Object> votes = new ArrayList<>();
    for (Votes v : votesList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("path", v.path);
      o.put("field", v.field);
      o.put("markup", v.markup);
      o.put("votes", voteList(v.votes));
      votes.add(o);
    }
    List<Object> unanimous = new ArrayList<>();
    for (Unanimous u : unanimousList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("path", u.path);
      o.put("field", u.field);
      o.put("markup", u.markup);
      o.put("decision", u.decision.value);
      o.put("result", u.result);
      unanimous.add(o);
    }
    List<Object> answers = new ArrayList<>();
    for (Answers a : answersList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("questionId", a.questionId);
      o.put("members", new ArrayList<Object>(a.members));
      answers.add(o);
    }
    List<Object> comments = new ArrayList<>();
    for (Comment c : commentsList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("id", c.id);
      o.put("author", c.author);
      o.put("path", c.path);
      o.put("field", c.field);
      comments.add(o);
    }
    List<Object> additions = new ArrayList<>();
    for (Addition a : additionsList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("path", a.path);
      o.put("members", new ArrayList<Object>(a.members));
      additions.add(o);
    }
    List<Object> guests = new ArrayList<>();
    for (GuestQuestion g : guestQuestionsList) {
      Map<String, Object> o = new LinkedHashMap<>();
      o.put("id", g.id);
      o.put("memberId", g.memberId);
      o.put("path", g.path);
      guests.add(o);
    }
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("reviewers", reviewers);
    out.put("conflicts", conflicts);
    out.put("votes", votes);
    out.put("unanimous", unanimous);
    out.put("answers", answers);
    out.put("comments", comments);
    out.put("additions", additions);
    out.put("guestQuestions", guests);
    if (revisionEntry == null) {
      out.put("revision", null);
    } else {
      Map<String, Object> r = new LinkedHashMap<>();
      r.put("path", revisionEntry.path);
      r.put("version", revisionEntry.version);
      out.put("revision", r);
    }
    return out;
  }
}
