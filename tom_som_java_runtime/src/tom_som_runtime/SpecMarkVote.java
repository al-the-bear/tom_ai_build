package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/** One reviewer's vote on a mark someone else proposed (SOM §11.9.8). */
public final class SpecMarkVote {
  /** The voter's member id. */
  public final String member;

  /** {@link SpecMarkDecision#ACCEPT} ({@code +id}) or {@link SpecMarkDecision#REJECT} ({@code -id}). */
  public final SpecMarkDecision vote;

  public SpecMarkVote(String member, SpecMarkDecision vote) {
    this.member = member;
    this.vote = vote;
  }

  /** Whether the vote accepts the mark. */
  public boolean accepts() {
    return vote == SpecMarkDecision.ACCEPT;
  }

  /** The canonical JSON form. */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("member", member);
    out.put("vote", vote.value);
    return out;
  }
}
