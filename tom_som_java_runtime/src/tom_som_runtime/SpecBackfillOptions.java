package tom_som_runtime;

import java.util.List;

/** The options of {@link SpecBackfill#backfill}. */
public final class SpecBackfillOptions {
  /** Keeps those pairs (by section id) only; {@code null} for every pair. */
  public List<String> pairs;
  /** Keeps the findings at or below this Blueprint path; {@code null} for every finding. */
  public String path;
  /** Writes a copy of the Blueprint. */
  public boolean dryRun;
  /** The revision entry's author, {@code null} for {@code backfill}. */
  public String author;
  /** The revision entry's date ({@code YYYY-MM-DD}), {@code null} for today. */
  public String date;
}
