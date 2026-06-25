package tom_som_runtime;

/**
 * The base class every generated typed facade class extends — a faithful port of
 * {@code som_facade.dart} / {@code som_facade.py}.
 *
 * <p>It binds a facade instance to the {@link SpecDocument} it edits and the
 * {@code path} it lives at (the globally-unique section path). The generated
 * subclass adds typed field accessors that delegate to {@code doc} at paths
 * derived from {@code path}.
 */
public class SomNode {
  public final SpecDocument doc;
  public final String path;

  public SomNode(SpecDocument doc, String path) {
    this.doc = doc;
    this.path = path;
  }
}
