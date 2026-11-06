package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** One line of individual answers, {@code **Answer (alice, bob):** (a)} (SOM §11.9.8). */
public final class SpecIndividualAnswer {
  /** The members who gave this answer, in the order written. */
  public final List<String> members;

  /** The answer, trimmed. */
  public final String answer;

  /** The letter the answer starts with ({@code (a)} or {@code **(a)**}), or null. */
  public final String answerLetter;

  public SpecIndividualAnswer(List<String> members, String answer) {
    this.members = Collections.unmodifiableList(new ArrayList<>(members));
    this.answer = answer;
    this.answerLetter = SpecReviewAnnotations.leadingLetter(answer);
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("members", new ArrayList<Object>(members));
    out.put("answer", answer);
    out.put("answerLetter", answerLetter);
    return out;
  }
}
