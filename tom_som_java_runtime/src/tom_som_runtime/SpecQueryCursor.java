package tom_som_runtime;

import java.util.ArrayList;
import java.util.List;

/**
 * A lazy, forward-only cursor over the nodes matching a {@link SpecQuery}
 * ({@code llm_and_d4rt_tools.md} §6).
 *
 * <p>The cursor holds the structural candidate paths captured when it was
 * created; each step re-validates the path against the <b>live</b> document and
 * re-applies the value-dependent filters, so concurrent edits never surface
 * stale or newly-mismatching results. It is forward-only: {@link #next} /
 * {@link #take} consume matches; {@link #count} peeks the remaining matches
 * without consuming.
 *
 * <p>Built by {@link SpecQueryEngine#query}; not constructed directly.
 */
public final class SpecQueryCursor {
  private final SpecQueryEngine engine;
  private final SpecQuery query;

  /**
   * The query's {@code text} dimension, compiled once when the cursor was built.
   * {@code null} when the query has no text dimension at all.
   */
  private final SomTextPattern pattern;

  private final List<String> candidatePaths;
  private int position;

  SpecQueryCursor(
      SpecQueryEngine engine,
      SpecQuery query,
      SomTextPattern pattern,
      List<String> candidatePaths) {
    this.engine = engine;
    this.query = query;
    this.pattern = pattern;
    this.candidatePaths = candidatePaths;
  }

  /**
   * The next matching node, or {@code null} when the cursor is exhausted. Skips
   * candidates whose path went stale or no longer satisfies the live filters.
   */
  public SpecQueryMatch next() {
    while (position < candidatePaths.size()) {
      String path = candidatePaths.get(position++);
      SpecQueryMatch match = engine.evaluateLive(query, pattern, path);
      if (match != null) {
        return match;
      }
    }
    return null;
  }

  /** Up to {@code n} further matches (fewer when the cursor is exhausted first). */
  public List<SpecQueryMatch> take(int n) {
    List<SpecQueryMatch> out = new ArrayList<>();
    for (int i = 0; i < n; i++) {
      SpecQueryMatch match = next();
      if (match == null) {
        break;
      }
      out.add(match);
    }
    return out;
  }

  /** Every remaining match, draining the cursor. */
  public List<SpecQueryMatch> toList() {
    List<SpecQueryMatch> out = new ArrayList<>();
    SpecQueryMatch match;
    while ((match = next()) != null) {
      out.add(match);
    }
    return out;
  }

  /**
   * How many matches remain from the current position, without consuming any.
   * Re-validates each remaining candidate against the live document, so the count
   * reflects the document as it is <i>now</i>.
   */
  public int count() {
    int remaining = 0;
    for (int i = position; i < candidatePaths.size(); i++) {
      if (engine.evaluateLive(query, pattern, candidatePaths.get(i)) != null) {
        remaining++;
      }
    }
    return remaining;
  }
}
