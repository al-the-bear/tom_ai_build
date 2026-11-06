package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/** The options of {@link SpecReviewMerge#mergeReviews} (SOM §11.9.9). */
public final class SpecReviewMergeOptions {
  /** The members the round started with, in team order; a copy of anybody else is a guest's. */
  public final List<SpecReviewMember> team;

  /**
   * The round's date (ISO 8601): the revision entry's date, and the date of every generated
   * list-item id.
   */
  public final String date;

  /** The revision entry's author. */
  public final String author;

  /** The id prefix of the questions the merge writes; {@code RQ} when not given. */
  public final String questionPrefix;

  /** The model of a SOM document; required when merging {@link SpecDocument}s, else null. */
  public final SpecModel model;

  /** Options with the default question prefix and no model (plain Markdown). */
  public SpecReviewMergeOptions(List<SpecReviewMember> team, String date, String author) {
    this(team, date, author, null, null);
  }

  /** {@code questionPrefix} null means {@code RQ}; {@code model} may be null for plain Markdown. */
  public SpecReviewMergeOptions(
      List<SpecReviewMember> team,
      String date,
      String author,
      String questionPrefix,
      SpecModel model) {
    this.team = Collections.unmodifiableList(new ArrayList<>(team));
    this.date = date;
    this.author = author;
    this.questionPrefix = questionPrefix == null ? "RQ" : questionPrefix;
    this.model = model;
  }
}
