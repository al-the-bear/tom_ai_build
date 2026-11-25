package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Why a value, or the whole merge, cannot be merged (SOM §11.10). The codes
 * are {@code crossesBoundary}, {@code sentenceRemoved}, {@code
 * stripTextEdited}, {@code unplaceable}, {@code notation}, {@code
 * annotations}, {@code changedBothSides}, {@code notStrippedBack} and {@code
 * newFinding}.
 */
public final class SpecStripMergeConflict {
  public final String code;
  public final String message;
  /** The value the conflict is about, or {@code null}. */
  public final SpecStripValueRef ref;
  /** The piece that could not be put back, or {@code null}. */
  public final SpecStripPiece piece;
  /** The excerpts of the original, the stripped baseline and the edited text. */
  public final String excerptO;

  public final String excerptB;
  public final String excerptE;

  public SpecStripMergeConflict(String code, String message) {
    this(code, message, null, null, "", "", "");
  }

  public SpecStripMergeConflict(
      String code,
      String message,
      SpecStripValueRef ref,
      SpecStripPiece piece,
      String excerptO,
      String excerptB,
      String excerptE) {
    this.code = code;
    this.message = message;
    this.ref = ref;
    this.piece = piece;
    this.excerptO = excerptO;
    this.excerptB = excerptB;
    this.excerptE = excerptE;
  }

  /** The conflict about value {@code value}. */
  public SpecStripMergeConflict about(SpecStripValueRef value) {
    return new SpecStripMergeConflict(code, message, value, piece, excerptO, excerptB, excerptE);
  }

  /** {@code CONFLICT <value> — <reason>}, then the three excerpts and the piece. */
  public List<String> reportLines() {
    List<String> out = new ArrayList<>();
    out.add(
        "CONFLICT "
            + (ref == null ? "(document)" : SpecStripMerge.specStripMergeLabel(ref))
            + " — "
            + message);
    if (piece != null || !excerptB.isEmpty()) {
      out.add("  O: " + excerptO);
      out.add("  B: " + excerptB);
      out.add("  E: " + excerptE);
    }
    if (piece != null) {
      out.add("  piece: " + SpecStripMerge.visible(piece.removed));
    }
    return out;
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("code", code);
    if (ref != null) {
      out.put("value", ref.toJson());
    }
    if (piece != null) {
      out.put("removed", piece.removed);
    }
    return out;
  }
}
