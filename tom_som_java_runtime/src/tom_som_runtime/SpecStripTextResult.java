package tom_som_runtime;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** The result of stripping one value ({@link SpecDocumentStrip#stripNotationText}). */
public final class SpecStripTextResult {
  /** The stripped text; the value itself when it was refused. */
  public final String text;
  /** What went, in order; applying every piece at its anchor gives the value back. */
  public final List<SpecStripPiece> pieces;
  /** The elements dropped, per kind. */
  public final Map<String, Integer> dropped;
  /** The elements unmarked, per kind. */
  public final Map<String, Integer> unmarked;
  /** The elements moved to the appendix, per kind. */
  public final Map<String, Integer> appended;
  /** The review marks that went inside a dropped element. */
  public final int marksDropped;
  /** The appendix entries the value gave. */
  public final List<SpecAppendixEntry> appendix;
  /** The error findings a refused value has. */
  public final List<NotationFinding> findings;

  public SpecStripTextResult(
      String text,
      List<SpecStripPiece> pieces,
      Map<String, Integer> dropped,
      Map<String, Integer> unmarked,
      Map<String, Integer> appended,
      int marksDropped,
      List<SpecAppendixEntry> appendix,
      List<NotationFinding> findings) {
    this.text = text;
    this.pieces = pieces;
    this.dropped = dropped;
    this.unmarked = unmarked;
    this.appended = appended;
    this.marksDropped = marksDropped;
    this.appendix = appendix;
    this.findings = findings;
  }

  /** Whether the value was refused for its findings. */
  public boolean refused() {
    return !findings.isEmpty();
  }

  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    out.put("text", text);
    out.put("dropped", new LinkedHashMap<String, Object>(dropped));
    out.put("unmarked", new LinkedHashMap<String, Object>(unmarked));
    out.put("appended", new LinkedHashMap<String, Object>(appended));
    out.put("marksDropped", marksDropped);
    List<Object> entries = new ArrayList<>();
    for (SpecAppendixEntry e : appendix) {
      entries.add(e.toJson());
    }
    out.put("appendix", entries);
    List<Object> ps = new ArrayList<>();
    for (SpecStripPiece p : pieces) {
      ps.add(p.toJson());
    }
    out.put("pieces", ps);
    List<Object> codes = new ArrayList<>();
    for (NotationFinding f : findings) {
      codes.add(f.code.value);
    }
    out.put("refused", codes);
    return out;
  }
}
