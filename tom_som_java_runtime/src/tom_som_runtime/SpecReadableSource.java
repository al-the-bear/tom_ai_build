package tom_som_runtime;

/** The source a readable rendition was made from, for its header (SOM §11.1). */
public final class SpecReadableSource {
  /** The source file's name. */
  public final String file;
  /** Its revision, or {@code null}. */
  public final String revision;
  /** The commit it was read at, or {@code null}. */
  public final String commit;
  /** Whether the working tree differed from {@link #commit}. */
  public final boolean dirty;

  public SpecReadableSource(String file) {
    this(file, null, null, false);
  }

  public SpecReadableSource(String file, String revision, String commit, boolean dirty) {
    this.file = file;
    this.revision = revision;
    this.commit = commit;
    this.dirty = dirty;
  }
}
