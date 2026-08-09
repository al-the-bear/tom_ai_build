package tom_som_runtime;

/**
 * A {@code [start, end)} half-open span within a matched string — the offsets a
 * pattern hit, surfaced on {@link SpecQueryMatch#matchSpans}.
 *
 * <p>Offsets count UTF-16 code units, the unit Dart's {@code String.codeUnits}
 * and Java's {@link String#charAt} both address, so the nine runtimes report the
 * same numbers for the same text.
 */
public final class SpecMatchSpan {
  /** Inclusive start offset into the matched string. */
  public final int start;

  /** Exclusive end offset into the matched string. */
  public final int end;

  public SpecMatchSpan(int start, int end) {
    this.start = start;
    this.end = end;
  }

  @Override
  public boolean equals(Object other) {
    if (!(other instanceof SpecMatchSpan)) {
      return false;
    }
    SpecMatchSpan o = (SpecMatchSpan) other;
    return o.start == start && o.end == end;
  }

  @Override
  public int hashCode() {
    return start * 31 + end;
  }

  @Override
  public String toString() {
    return "SpecMatchSpan(" + start + ", " + end + ")";
  }
}
