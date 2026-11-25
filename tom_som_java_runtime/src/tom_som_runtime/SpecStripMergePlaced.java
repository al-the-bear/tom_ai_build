package tom_som_runtime;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * A piece put back after an edited run rather than between unchanged
 * neighbours (SOM §11.10): an author confirms or moves it ({@code PLACED
 * <value> — check}).
 */
public final class SpecStripMergePlaced {
  public final SpecStripPiece piece;
  /** The offset (UTF-16) in the merged value the piece's text starts at. */
  public final int at;

  public SpecStripMergePlaced(SpecStripPiece piece, int at) {
    this.piece = piece;
    this.at = at;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("at", at);
    out.put("removed", piece.removed);
    return out;
  }
}
