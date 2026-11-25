package tom_som_runtime;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Predicate;

import tom_som_runtime.SpecDocumentStrip.Edit;
import tom_som_runtime.SpecDocumentStrip.MarkAt;
import tom_som_runtime.SpecDocumentStrip.Op;

/**
 * The merge back (SOM §11.10; the reading view's part <em>Stripped renditions
 * and the merge back</em>): an edited readable rendition merged onto the
 * document of record, every piece the strip removed put back.
 *
 * <p>The Java port of {@code tom_som_typescript_runtime}'s {@code
 * spec_document_merge.ts} (itself the port of {@code
 * spec_document_merge.dart}); offsets count UTF-16 code units, which a Java
 * {@code String} index is. {@code strip_merge_cases.json} holds all ports to
 * the same results.
 */
public final class SpecStripMerge {
  private SpecStripMerge() {}

  private static final int KEEP = SpecDocumentStrip.KEEP;
  private static final int DEL = SpecDocumentStrip.DEL;
  private static final int INS = SpecDocumentStrip.INS;

  private static final int ROLE_WHOLE = 0;
  private static final int ROLE_OPENER = 1;
  private static final int ROLE_CLOSER = 2;
  private static final int ROLE_BOTH = 3;

  /** The name of a value in a merge report. */
  public static String specStripMergeLabel(SpecStripValueRef ref) {
    return ref.headline
        ? ref.path + " (headline)"
        : ref.field != null ? ref.path + " / " + ref.field : ref.path;
  }

  // ---------------------------------------------------------------------------
  // One value's merge.

  /** Text to write into the edited value at {@code at}. */
  private static final class Put {
    final int at;
    final int order;
    final String text;
    final int replace;
    final boolean normalize;
    final int before;
    final int after;

    Put(int at, int order, String text) {
      this(at, order, text, 0, false, 2, 2);
    }

    Put(int at, int order, String text, int replace, boolean normalize, int before, int after) {
      this.at = at;
      this.order = order;
      this.text = text;
      this.replace = replace;
      this.normalize = normalize;
      this.before = before;
      this.after = after;
    }
  }

  private static SpecStripMergeConflict conflict(
      String code, String message, SpecStripPiece p, String o, String b, String e, int eAt) {
    return new SpecStripMergeConflict(
        code, message, null, p, excerpt(o, p.origin), excerpt(b, p.anchor), excerpt(e, eAt));
  }

  private static int distance(int breaks, boolean edge) {
    return edge ? 2 : Math.min(2, Math.max(1, breaks));
  }

  private static int notationErrors(String s) {
    int n = 0;
    for (NotationFinding f : SpecNotation.scanNotation(s, true).findings) {
      if (f.severity().equals("error") && f.code != NotationFindingCode.REJECTED_BLOCK) {
        n++;
      }
    }
    return n;
  }

  /**
   * Merges the edited text {@code e} of one value back onto its original
   * {@code o} (SOM §11.10): {@code b} is {@code o} stripped and {@code pieces}
   * what the strip removed, anchored in {@code b}. A piece goes back between
   * its unchanged neighbours; next to an edit it is placed after the edited
   * run (reported as placed) or, where that would be a guess — an edit across
   * the boundary of an unmarked element ({@code crossesBoundary}), the whole
   * sentence holding the piece removed ({@code sentenceRemoved}), the text the
   * strip wrote edited ({@code stripTextEdited}), a block without a line to go
   * back to ({@code unplaceable}) — it is a conflict, and so is a merged value
   * with a notation error or a malformed annotation neither side had.
   */
  public static SpecStripValueMerge mergeStrippedValue(
      String o, String b, String e, List<SpecStripPiece> pieces) {
    if (e.equals(b)) {
      return new SpecStripValueMerge(o, pieces.size(), new ArrayList<>(), new ArrayList<>());
    }
    int[] roles = pieceRoles(o, pieces);
    List<Op> ops = SpecDocumentStrip.diff(b, e, "edit");
    EditMap map = new EditMap(ops, b.length());
    // An opening marker is judged on the script whose whitespace edits trail
    // their run, a closing one on the script whose whitespace edits lead it.
    EditMap trailing = new EditMap(slide(ops, false), b.length());
    EditMap leading = new EditMap(slide(ops, true), b.length());
    LineEditMap lines = null;
    List<Put> puts = new ArrayList<>();
    Set<Integer> placedAt = new HashSet<>();
    List<SpecStripMergeConflict> conflicts = new ArrayList<>();
    int restored = 0;
    for (int i = 0; i < pieces.size(); i++) {
      SpecStripPiece p = pieces.get(i);

      if (!p.inserted.isEmpty()) {
        int at = map.keptRange(p.anchor, p.anchor + p.inserted.length());
        if (at < 0) {
          conflicts.add(
              conflict(
                  "stripTextEdited",
                  "the text the strip wrote in place of a piece was edited",
                  p, o, b, e, map.gap(p.anchor).start));
          continue;
        }
        puts.add(new Put(at, i, p.removed, p.inserted.length(), false, 2, 2));
        restored++;
        continue;
      }

      int role = roles[i];
      int g = p.anchor;
      String text = p.removed;
      if (role == ROLE_WHOLE && text.indexOf('\n') >= 0) {
        while (g > 0
            && b.charAt(g - 1) != '\n'
            && g < b.length()
            && text.charAt(0) == b.charAt(g)) {
          text = text.substring(1) + text.charAt(0);
          g++;
        }
        if (g == 0 || b.charAt(g - 1) == '\n' || g == b.length()) {
          if (lines == null) {
            lines = new LineEditMap(b, e);
          }
          int k = lineIndex(b, g);
          Gap gap = lines.gap(k);
          if (gap.unchanged()) {
            puts.add(new Put(gap.start, i, text));
            restored++;
            continue;
          }
          int at =
              !gap.leftEdited
                  ? gap.start
                  : !gap.rightEdited ? gap.end : lines.paragraphPlace(gap, k);
          if (at > 0 && at < e.length() && e.charAt(at - 1) != '\n') {
            conflicts.add(
                conflict(
                    "unplaceable", "the block has no line boundary to go back to", p, o, b, e,
                    at));
            continue;
          }
          // The block keeps the distance it had from the text around it in the
          // original: a blank line, or none when it stood right against a line.
          int core = p.origin + leadingBreaks(p.removed);
          int coreEnd = p.origin + p.removed.length() - trailingBreaks(p.removed);
          puts.add(
              new Put(
                  at,
                  i,
                  text,
                  0,
                  true,
                  distance(trailingBreaks(o.substring(0, core)), core == 0),
                  distance(leadingBreaks(o.substring(coreEnd)), coreEnd >= o.length())));
          restored++;
          continue;
        }
        g = p.anchor;
        text = p.removed;
      }

      Gap gap = (role == ROLE_OPENER ? trailing : role == ROLE_CLOSER ? leading : map).gap(g);
      if (gap.unchanged()) {
        puts.add(new Put(gap.start, i, text));
        restored++;
        continue;
      }
      if (SpecNotation.isBlank(text)) {
        continue; // normalised whitespace at an edit
      }
      if (role == ROLE_OPENER || role == ROLE_CLOSER) {
        if (gap.leftEdited && gap.rightEdited) {
          conflicts.add(
              conflict(
                  "crossesBoundary",
                  "an edit crosses the boundary of an unmarked element",
                  p, o, b, e, gap.start));
          continue;
        }
        // The edit on the inner side of the marker goes inside the element.
        int at =
            role == ROLE_OPENER
                ? (!gap.leftEdited ? gap.start : gap.end)
                : (!gap.rightEdited ? gap.end : gap.start);
        puts.add(new Put(at, i, text));
        restored++;
      } else if (role == ROLE_BOTH) {
        conflicts.add(
            conflict(
                "crossesBoundary",
                "an edit touches the boundary between two unmarked elements",
                p, o, b, e, gap.start));
      } else {
        if (sentenceRemoved(b, g, map)) {
          conflicts.add(
              conflict(
                  "sentenceRemoved",
                  "the edit removed the whole sentence holding the piece",
                  p, o, b, e, gap.start));
          continue;
        }
        puts.add(new Put(gap.end, i, text));
        placedAt.add(i);
        restored++;
      }
    }
    if (!conflicts.isEmpty()) {
      return new SpecStripValueMerge(null, 0, new ArrayList<>(), conflicts);
    }

    puts.sort(
        (x, y) ->
            x.at != y.at ? Integer.compare(x.at, y.at) : Integer.compare(x.order, y.order));
    StringBuilder out = new StringBuilder();
    List<SpecStripMergePlaced> placed = new ArrayList<>();
    int pos = 0;
    for (Put put : puts) {
      if (put.at < pos) {
        conflicts.add(
            new SpecStripMergeConflict(
                "stripTextEdited",
                "two pieces claim the same text",
                null,
                pieces.get(put.order),
                "",
                "",
                ""));
        continue;
      }
      out.append(e, pos, put.at);
      pos = put.at;
      if (put.normalize) {
        int s = leadingBreaks(put.text);
        int z = put.text.length() - trailingBreaks(put.text);
        String core = z > s ? put.text.substring(s, z) : "";
        if (out.length() > 0) {
          appendBreaks(out, put.before - trailingBreaks(out));
        }
        if (placedAt.contains(put.order)) {
          placed.add(new SpecStripMergePlaced(pieces.get(put.order), out.length()));
        }
        out.append(core);
        String right = e.substring(pos);
        if (!right.isEmpty()) {
          appendBreaks(out, put.after - leadingBreaks(right));
        }
      } else {
        if (placedAt.contains(put.order)) {
          placed.add(new SpecStripMergePlaced(pieces.get(put.order), out.length()));
        }
        out.append(put.text);
      }
      pos += put.replace;
    }
    out.append(e.substring(pos));
    String merged = out.toString();

    if (notationErrors(merged) > notationErrors(e) + notationErrors(o)) {
      conflicts.add(
          new SpecStripMergeConflict(
              "notation",
              "the merged value has a notation error neither the original nor the edited text"
                  + " has"));
    }
    if (SpecReviewAnnotations.annotationIssuesText(merged).size()
        > SpecReviewAnnotations.annotationIssuesText(e).size()
            + SpecReviewAnnotations.annotationIssuesText(o).size()) {
      conflicts.add(
          new SpecStripMergeConflict(
              "annotations",
              "the merged value has a malformed review annotation neither the original nor the"
                  + " edited text has"));
    }
    if (!conflicts.isEmpty()) {
      return new SpecStripValueMerge(null, 0, new ArrayList<>(), conflicts);
    }
    return new SpecStripValueMerge(merged, restored, placed, new ArrayList<>());
  }

  private static void appendBreaks(StringBuilder out, int n) {
    for (int k = 0; k < n; k++) {
      out.append('\n');
    }
  }

  // ---------------------------------------------------------------------------
  // A whole document's merge.

  private static SpecStripMergeResult refused(
      SpecStripOptions opts, List<SpecStripMergeRefusal> r, boolean stale) {
    return new SpecStripMergeResult(null, opts, stale, new ArrayList<>(), new ArrayList<>(), r);
  }

  private static boolean refusedAt(List<SpecStripMergeRefusal> refusals, String path) {
    for (SpecStripMergeRefusal r : refusals) {
      if (r.path.equals(path)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Merges {@code edited}, a {@code .readable.md} made from {@code original}
   * and changed by a reader, back onto {@code original} (SOM §11.10).
   *
   * <p>The switches come from the rendition's readable header, or from {@link
   * SpecStripMergeOptions#options} (which must agree with a header); with
   * neither, a {@link SpecStripUsageError} is thrown. The original is stale
   * when a {@link SpecStripMergeOptions#base} is given or the header's
   * revision differs from {@link SpecStripMergeOptions#currentRevision}: the
   * merge is then three-way, from the base given or from the header's commit
   * through {@link SpecStripMergeOptions#loadBase}, and refused ({@code
   * stale}) without one. Structural edits — sections or list items added,
   * removed or moved, a changed codeSpec or units — and a rendition with
   * rejected blocks are refused; every other changed value is merged with
   * {@link #mergeStrippedValue}. The merged document is checked to change
   * only the merged values, to strip back to the edited text and to add no
   * finding; {@link SpecStripMergeResult#document} is {@code null} unless all
   * of that holds. {@code original} is never changed.
   */
  public static SpecStripMergeResult merge(
      SpecDocument original, String edited, SpecStripMergeOptions extra) {
    SpecModel model = extra.model;
    DocSpecsSchema schema = extra.schema;
    String rootType = extra.rootType;
    String fileStem = extra.fileStem;
    Map<String, String> documentFiles = extra.documentFiles;
    SpecMarkdownResult parsed =
        new SpecDocumentMarkdown(model, new SpecDocument(), fileStem, documentFiles)
            .parse(edited);
    String headerLine = parsed.readableHeader;
    SpecReadableHeader header = headerLine == null ? null : SpecReadableHeader.parse(headerLine);
    if (headerLine != null && header == null) {
      throw new SpecStripUsageError("the readable header cannot be read: " + headerLine);
    }
    SpecStripOptions given = extra.options;
    SpecStripOptions opts;
    if (given != null) {
      if (header != null && !optionsText(header.options).equals(optionsText(given))) {
        throw new SpecStripUsageError(
            "the switches given ("
                + optionsText(given)
                + ") disagree with the readable header ("
                + optionsText(header.options)
                + ")");
      }
      opts = given;
    } else if (header != null) {
      opts = header.options;
    } else {
      throw new SpecStripUsageError(
          "the rendition has no readable header: name the switches it was stripped with");
    }

    if (!parsed.rejections.isEmpty()) {
      List<SpecStripMergeRefusal> r = new ArrayList<>();
      for (SpecMarkdownRejection x : parsed.rejections) {
        r.add(new SpecStripMergeRefusal("rejected", "", "line " + x.line + ": " + x.message));
      }
      return refused(opts, r, false);
    }

    SpecReadableSource source = header == null ? null : header.source;
    String currentRevision = extra.currentRevision;
    SpecDocument base = extra.base;
    boolean stale =
        base != null
            || (source != null
                && source.revision != null
                && currentRevision != null
                && !source.revision.equals(currentRevision));
    SpecDocument origin = original;
    if (stale) {
      SpecDocument loaded = base;
      if (loaded == null
          && source != null
          && source.commit != null
          && !source.dirty
          && extra.loadBase != null) {
        loaded = extra.loadBase.apply(source);
      }
      if (loaded == null) {
        String why =
            source == null || source.commit == null
                ? "names no commit"
                : source.dirty
                    ? "names a dirty commit"
                    : "names a commit that could not be read";
        List<SpecStripMergeRefusal> r = new ArrayList<>();
        r.add(
            new SpecStripMergeRefusal(
                "stale",
                "",
                "the original moved since the export (revision "
                    + (source == null ? null : source.revision)
                    + " then, "
                    + currentRevision
                    + " now) and there is no base: the header "
                    + why
                    + "; give the original as it was at the export"));
        return refused(opts, r, true);
      }
      origin = loaded;
    }

    SpecStripResult strip =
        SpecDocumentStrip.strip(
            origin, opts, model, schema, rootType, fileStem, documentFiles, null);
    if (!strip.ok() || strip.readable == null) {
      List<SpecStripMergeRefusal> r = new ArrayList<>();
      for (SpecStripFinding f : strip.findings) {
        r.add(
            new SpecStripMergeRefusal("strip", f.ref == null ? "" : f.ref.label(), f.toString()));
      }
      if (r.isEmpty()) {
        r.add(new SpecStripMergeRefusal("strip", "", "the base renders no rendition"));
      }
      return refused(opts, r, stale);
    }
    SpecDocument bDoc = strip.document;
    SpecDocument eDoc = new SpecDocument();
    eDoc.applyMarkdownResult(parsed);
    List<String> roots = new ArrayList<>(parsed.rootPrefixes);
    Predicate<String> inRoot =
        p -> {
          for (String r : roots) {
            if (p.equals(r) || p.startsWith(r + "/") || p.startsWith(r + "-")) {
              return true;
            }
          }
          return false;
        };

    // Structural edits.
    List<SpecStripMergeRefusal> refusals = new ArrayList<>();
    List<String> bHeadings = headingPaths(strip.readable);
    List<String> eHeadings = headingPaths(edited);
    if (!bHeadings.equals(eHeadings)) {
      Set<String> bSet = new HashSet<>(bHeadings);
      Set<String> eSet = new HashSet<>(eHeadings);
      for (String p : eHeadings) {
        if (!bSet.contains(p)) {
          refusals.add(new SpecStripMergeRefusal("sectionAdded", p, "a section added"));
        }
      }
      for (String p : bHeadings) {
        if (!eSet.contains(p)) {
          refusals.add(new SpecStripMergeRefusal("sectionRemoved", p, "a section removed"));
        }
      }
      if (refusals.isEmpty()) {
        List<String> common = new ArrayList<>();
        for (String p : eHeadings) {
          if (bSet.contains(p)) {
            common.add(p);
          }
        }
        List<String> want = new ArrayList<>();
        for (String p : bHeadings) {
          if (eSet.contains(p)) {
            want.add(p);
          }
        }
        for (int i = 0; i < common.size(); i++) {
          if (i >= want.size() || !common.get(i).equals(want.get(i))) {
            refusals.add(
                new SpecStripMergeRefusal("sectionMoved", common.get(i), "a section moved"));
            break;
          }
        }
      }
    }
    Map<String, String> bLists = listsUnder(bDoc, inRoot);
    Map<String, String> eLists = listsUnder(eDoc, inRoot);
    TreeSet<String> listKeys = new TreeSet<>(bLists.keySet());
    listKeys.addAll(eLists.keySet());
    for (String l : listKeys) {
      if (!Objects.equals(bLists.get(l), eLists.get(l))) {
        refusals.add(
            new SpecStripMergeRefusal(
                "listItems", l, "list items added, removed, moved or renamed"));
      }
    }
    for (String code : Arrays.asList("codeSpec", "units")) {
      boolean codeSpec = code.equals("codeSpec");
      TreeSet<String> all = new TreeSet<>(codeSpec ? bDoc.codeSpecPaths() : bDoc.unitsPaths());
      all.addAll(codeSpec ? eDoc.codeSpecPaths() : eDoc.unitsPaths());
      for (String p : all) {
        if (!inRoot.test(p)) {
          continue;
        }
        String was = codeSpec ? bDoc.codeSpec(p) : bDoc.units(p);
        String now = codeSpec ? eDoc.codeSpec(p) : eDoc.units(p);
        if (!Objects.equals(was, now)) {
          refusals.add(new SpecStripMergeRefusal(code, p, "a changed " + code));
        }
      }
    }
    Map<String, SpecStripValueRef> byKey = new LinkedHashMap<>();
    for (SpecDocument d : Arrays.asList(bDoc, eDoc)) {
      for (SpecStripValueRef r : SpecDocumentStrip.valueRefs(d)) {
        if (inRoot.test(r.path)) {
          byKey.put(refKey(r), r);
        }
      }
    }
    List<SpecStripValueRef> refs = new ArrayList<>(byKey.values());
    refs.sort(
        (x, y) -> {
          int c = x.path.compareTo(y.path);
          if (c != 0) {
            return c;
          }
          if (x.headline != y.headline) {
            return x.headline ? -1 : 1;
          }
          return (x.field == null ? "" : x.field).compareTo(y.field == null ? "" : y.field);
        });
    for (SpecStripValueRef ref : refs) {
      if (ref.read(bDoc).isEmpty()
          && !ref.read(eDoc).isEmpty()
          && !bDoc.hasValuesUnder(ref.path)
          && !refusedAt(refusals, ref.path)) {
        refusals.add(
            new SpecStripMergeRefusal(
                "sectionAdded", ref.path, "a value in a section the rendition does not show"));
      }
    }

    // The values.
    Map<String, List<SpecStripPiece>> pieces = new HashMap<>();
    for (SpecStrippedValue v : strip.values) {
      pieces.put(refKey(v.ref), v.pieces);
    }
    List<SpecStripMergedValue> merged = new ArrayList<>();
    List<SpecStripMergeConflict> conflicts = new ArrayList<>();
    for (SpecStripValueRef ref : refs) {
      String bText = ref.read(bDoc);
      String eText = ref.read(eDoc);
      // A wrapped paragraph written in a table cell reads back on one line
      // (SOM §11.4 rule 13): that alone is no edit.
      if (bText.equals(eText)
          || eText.equals(SpecDocumentMarkdown.wrappedParagraphJoined(bText))) {
        continue;
      }
      if (refusedAt(refusals, ref.path)) {
        continue;
      }
      // A value whose section came or went with a refused edit is that edit.
      if (!refusals.isEmpty()
          && (!bDoc.hasValuesUnder(ref.path) || !eDoc.hasValuesUnder(ref.path))) {
        continue;
      }
      String o = ref.read(origin);
      List<SpecStripPiece> ps = pieces.get(refKey(ref));
      SpecStripValueMerge r =
          mergeStrippedValue(o, bText, eText, ps == null ? new ArrayList<>() : ps);
      String now = ref.read(original);
      if (stale && !now.equals(o)) {
        // The edit is already in the moved original (the same rendition
        // merged before): nothing to do for this value.
        if (r.ok() && now.equals(r.text)) {
          continue;
        }
        int at = firstDifference(bText, eText);
        conflicts.add(
            new SpecStripMergeConflict(
                "changedBothSides",
                "the value changed in the original since the export, and in the rendition",
                ref,
                null,
                excerpt(now, firstDifference(o, now)),
                excerpt(bText, at),
                excerpt(eText, at)));
        continue;
      }
      if (!r.ok()) {
        for (SpecStripMergeConflict c : r.conflicts) {
          conflicts.add(c.about(ref));
        }
        continue;
      }
      merged.add(new SpecStripMergedValue(ref, r.text, r.restored, r.placed));
    }
    if (!conflicts.isEmpty() || !refusals.isEmpty()) {
      return new SpecStripMergeResult(null, opts, stale, merged, conflicts, refusals);
    }

    // Write and verify.
    SpecDocument out = new SpecDocument();
    out.loadJson(original.toJson());
    Set<String> expected = new HashSet<>();
    for (SpecStripMergedValue m : merged) {
      if (!m.text.equals(m.ref.read(original))) {
        expected.add(refKey(m.ref));
      }
      m.ref.write(out, m.text);
    }
    Set<String> changed = new HashSet<>();
    for (SpecDocument d : Arrays.asList(original, out)) {
      for (SpecStripValueRef r : SpecDocumentStrip.valueRefs(d)) {
        if (!r.read(original).equals(r.read(out))) {
          changed.add(refKey(r));
        }
      }
    }
    if (!changed.equals(expected)) {
      conflicts.add(
          new SpecStripMergeConflict(
              "newFinding", "the merged document changes other values than the merged ones"));
    }
    SpecStripResult again =
        SpecDocumentStrip.strip(out, opts, model, schema, rootType, fileStem, documentFiles, null);
    for (SpecStripMergedValue m : merged) {
      String back = m.ref.read(again.document);
      String want = m.ref.read(eDoc);
      if (!back.equals(want)) {
        conflicts.add(
            new SpecStripMergeConflict(
                "notStrippedBack",
                "the merged value does not strip back to the edited text",
                m.ref,
                null,
                excerpt(m.text, 0),
                excerpt(back, 0),
                excerpt(want, 0)));
      }
    }
    Map<String, String> before = SpecDocumentStrip.tierFindings(model, schema, rootType, original);
    for (String k : SpecDocumentStrip.tierFindings(model, schema, rootType, out).keySet()) {
      if (!before.containsKey(k)) {
        conflicts.add(
            new SpecStripMergeConflict(
                "newFinding", "the merged document has a new finding: " + k));
      }
    }
    return new SpecStripMergeResult(
        conflicts.isEmpty() ? out : null, opts, stale, merged, conflicts, new ArrayList<>());
  }

  /**
   * The file at {@code filePath} as it was at {@code commit} ({@code git show
   * <commit>:./<name>}, run in the file's folder), or {@code null} when git
   * cannot give it. What a {@link SpecStripMergeOptions#loadBase} reads the
   * base of a stale original with.
   */
  public static String gitShowFile(String commit, String filePath) {
    if (commit == null || commit.isEmpty() || commit.startsWith("-")) {
      return null; // never an option to git
    }
    File file = new File(filePath).getAbsoluteFile();
    File folder = file.getParentFile();
    if (folder == null || !folder.isDirectory()) {
      return null;
    }
    try {
      Process process =
          new ProcessBuilder("git", "show", commit + ":./" + file.getName())
              .directory(folder)
              .redirectError(ProcessBuilder.Redirect.DISCARD)
              .start();
      process.getOutputStream().close();
      byte[] bytes = process.getInputStream().readAllBytes();
      return process.waitFor() == 0 ? new String(bytes, StandardCharsets.UTF_8) : null;
    } catch (IOException e) {
      return null;
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      return null;
    }
  }

  private static String optionsText(SpecStripOptions o) {
    String s = new SpecReadableHeader(o).format();
    return SpecNotation.jsTrim(s.substring("<!-- readable:".length(), s.length() - 3));
  }

  private static String refKey(SpecStripValueRef r) {
    return (r.headline ? "h" : r.field != null ? "f" : "c")
        + "\u0000"
        + r.path
        + "\u0000"
        + (r.field == null ? "" : r.field);
  }

  /** The section-id paths of {@code markdown}'s headings, in order. */
  private static List<String> headingPaths(String markdown) {
    List<String> out = new ArrayList<>();
    walkHeadings(DocSpecsDocument.parse(markdown).sections, "", out);
    return out;
  }

  private static void walkHeadings(List<DocSpecsSection> list, String prefix, List<String> out) {
    for (DocSpecsSection s : list) {
      String id = s.id == null ? "?" : s.id;
      String p = prefix.isEmpty() ? id : prefix + "/" + id;
      out.add(p);
      walkHeadings(s.children, p, out);
    }
  }

  /** The lists of {@code doc} under the roots, each as its items and their ids. */
  private static Map<String, String> listsUnder(SpecDocument doc, Predicate<String> inRoot) {
    Map<String, String> out = new HashMap<>();
    Object lists = doc.toJson().get("lists");
    if (lists instanceof Map) {
      for (Map.Entry<?, ?> e : ((Map<?, ?>) lists).entrySet()) {
        String k = String.valueOf(e.getKey());
        if (inRoot.test(k) && e.getValue() instanceof Map) {
          Map<?, ?> v = (Map<?, ?>) e.getValue();
          out.put(k, Json.write(v.get("items")) + " " + Json.write(v.get("ids")));
        }
      }
    }
    return out;
  }

  /**
   * What each piece is, read from the original {@code o}: the opening marker
   * of an unmarked element, its closing marker, both (the closer of one and
   * the opener of the next), or a whole removed run.
   */
  private static int[] pieceRoles(String o, List<SpecStripPiece> pieces) {
    int[] at = new int[o.length()];
    Arrays.fill(at, -1);
    for (int i = 0; i < pieces.size(); i++) {
      SpecStripPiece p = pieces.get(i);
      for (int k = p.origin; k < p.origin + p.removed.length() && k < o.length(); k++) {
        at[k] = i;
      }
    }
    boolean[] opener = new boolean[pieces.size()];
    boolean[] closer = new boolean[pieces.size()];
    walkRoles(SpecNotation.scanNotation(o, true).elements, o, at, opener, closer);
    for (MarkAt m : SpecDocumentStrip.findMarks(o)) {
      pair(o, at, opener, closer, m.start, m.sep >= 0 ? m.sep + 2 : m.bodyStart, m.bodyEnd, m.end);
    }
    int[] roles = new int[pieces.size()];
    for (int i = 0; i < roles.length; i++) {
      roles[i] =
          opener[i] && closer[i]
              ? ROLE_BOTH
              : opener[i] ? ROLE_OPENER : closer[i] ? ROLE_CLOSER : ROLE_WHOLE;
    }
    return roles;
  }

  /** The piece holding the first solid character of {@code o[s, e)}, or -1. */
  private static int firstPiece(String o, int[] at, int s, int e) {
    for (int k = Math.max(0, s); k < e && k < o.length(); k++) {
      if (!SpecNotation.isJsWhitespace(o.charAt(k))) {
        return at[k];
      }
    }
    return -1;
  }

  /** Whether {@code [start, end)} lies in one piece. */
  private static boolean wholePiece(int[] at, int start, int end) {
    if (!(start < end && start >= 0 && start < at.length && at[start] >= 0)) {
      return false;
    }
    for (int k = start; k < end; k++) {
      if (k >= at.length || at[k] != at[start]) {
        return false;
      }
    }
    return true;
  }

  private static void pair(
      String o,
      int[] at,
      boolean[] opener,
      boolean[] closer,
      int start,
      int openEnd,
      int closeStart,
      int end) {
    if (wholePiece(at, start, end)) {
      return;
    }
    int po = firstPiece(o, at, start, openEnd);
    int pc = firstPiece(o, at, closeStart, end);
    if (po >= 0 && po != pc) {
      opener[po] = true;
    }
    if (pc >= 0 && pc != po) {
      closer[pc] = true;
    }
  }

  private static void walkRoles(
      List<NotationElement> list, String o, int[] at, boolean[] opener, boolean[] closer) {
    for (NotationElement e : list) {
      if (e.type.equals("citation")) {
        if (!wholePiece(at, e.start, e.end)) {
          int po = firstPiece(o, at, e.start + 1, e.contentStart);
          if (po >= 0) {
            opener[po] = true;
          }
        }
      } else {
        pair(o, at, opener, closer, e.start, e.contentStart, e.contentEnd, e.end);
      }
      walkRoles(e.children, o, at, opener, closer);
    }
  }

  /** Where a gap of the baseline lies in the edited text. */
  private static final class Gap {
    final boolean leftEdited;
    final boolean rightEdited;
    final int start;
    final int end;

    Gap(boolean leftEdited, boolean rightEdited, int start, int end) {
      this.leftEdited = leftEdited;
      this.rightEdited = rightEdited;
      this.start = start;
      this.end = end;
    }

    boolean unchanged() {
      return !leftEdited && !rightEdited && start == end;
    }
  }

  /** The gap after {@code p} operations of a script whose types {@code type} gives. */
  private static Gap gapAt(int p, boolean first, int[] types, int[] eBefore) {
    int n = types.length;
    boolean leftEdited = !first && types[p - 1] == DEL;
    int r = p;
    while (r < n && types[r] == INS) {
      r++;
    }
    boolean rightEdited = r < n && types[r] == DEL;
    if (!leftEdited && r == p && !rightEdited) {
      return new Gap(false, false, eBefore[p], eBefore[p]);
    }
    int s = p;
    while (s > 0 && types[s - 1] != KEEP) {
      s--;
    }
    int t = p;
    while (t < n && types[t] != KEEP) {
      t++;
    }
    return new Gap(leftEdited, rightEdited, eBefore[s], eBefore[t]);
  }

  /** An edit script from a baseline to an edited text, indexed by baseline offset. */
  private static final class EditMap {
    final int[] types;
    final int[] after;
    final int[] eBefore;
    final boolean[] deleted;

    EditMap(List<Op> ops, int bLength) {
      types = new int[ops.size()];
      after = new int[bLength + 1];
      eBefore = new int[ops.size() + 1];
      deleted = new boolean[bLength];
      int g = 0;
      for (int i = 0; i < ops.size(); i++) {
        int type = ops.get(i).type;
        types[i] = type;
        eBefore[i + 1] = eBefore[i] + (type == DEL ? 0 : 1);
        if (type != INS) {
          if (type == DEL) {
            deleted[g] = true;
          }
          g++;
          after[g] = i + 1;
        }
      }
    }

    Gap gap(int g) {
      return gapAt(after[g], g == 0, types, eBefore);
    }

    /** The edited-text offset of baseline range {@code [a, z)} kept whole, else -1. */
    int keptRange(int a, int z) {
      int first = after[a + 1] - 1;
      for (int k = a; k < z; k++) {
        int i = after[k + 1] - 1;
        if (types[i] != KEEP || i != first + (k - a)) {
          return -1;
        }
      }
      return eBefore[first];
    }
  }

  /** A line edit script from a baseline to an edited text. */
  private static final class LineEditMap {
    final List<Edit> ops;
    final int[] types;
    final int[] after;
    final int[] eBefore;

    LineEditMap(String b, String e) {
      List<String> bl = SpecDocumentStrip.lines(b);
      ops = SpecDocumentStrip.myers(bl, SpecDocumentStrip.lines(e));
      types = new int[ops.size()];
      after = new int[bl.size() + 1];
      eBefore = new int[ops.size() + 1];
      int k = 0;
      for (int i = 0; i < ops.size(); i++) {
        Edit op = ops.get(i);
        types[i] = op.type;
        eBefore[i + 1] = eBefore[i] + (op.type == DEL ? 0 : op.text.length());
        if (op.type != INS) {
          k++;
          after[k] = i + 1;
        }
      }
    }

    Gap gap(int k) {
      return gapAt(after[k], k == 0, types, eBefore);
    }

    /**
     * Where a block between two edited runs goes: before the inserted
     * paragraph that stands where the block's following paragraph stood,
     * counted in paragraphs of the run.
     */
    int paragraphPlace(Gap gap, int k) {
      int p = after[k];
      int s = p;
      while (s > 0 && types[s - 1] != KEEP) {
        s--;
      }
      int before = 0;
      boolean blank = true;
      for (int i = s; i < p; i++) {
        if (types[i] != DEL) {
          continue;
        }
        boolean isBlank = SpecNotation.isBlank(ops.get(i).text);
        if (!isBlank && blank) {
          before++;
        }
        blank = isBlank;
      }
      if (before == 0) {
        return gap.start;
      }
      int count = 0;
      blank = true;
      for (int i = s; i < types.length && types[i] != KEEP; i++) {
        if (types[i] != INS) {
          continue;
        }
        boolean isBlank = SpecNotation.isBlank(ops.get(i).text);
        if (!isBlank && blank) {
          if (count == before) {
            return eBefore[i];
          }
          count++;
        }
        blank = isBlank;
      }
      return gap.end;
    }
  }

  /**
   * {@code ops} with every lone run of deletions or insertions slid over equal
   * whitespace: to the front of it ({@code leading}) or to its end.
   */
  private static List<Op> slide(List<Op> ops, boolean leading) {
    List<Op> out = new ArrayList<>(ops);
    int s = 0;
    while (s < out.size()) {
      if (out.get(s).type == KEEP) {
        s++;
        continue;
      }
      int t = s;
      while (t < out.size() && out.get(t).type == out.get(s).type) {
        t++;
      }
      if (t < out.size() && out.get(t).type != KEEP) {
        while (t < out.size() && out.get(t).type != KEEP) {
          t++;
        }
        s = t;
        continue;
      }
      int type = out.get(s).type;
      if (leading) {
        while (s > 0
            && out.get(s - 1).type == KEEP
            && SpecNotation.isJsWhitespace(out.get(t - 1).ch)
            && out.get(s - 1).ch == out.get(t - 1).ch) {
          out.set(t - 1, new Op(KEEP, out.get(t - 1).ch, null));
          out.set(s - 1, new Op(type, out.get(s - 1).ch, "edit"));
          s--;
          t--;
        }
      } else {
        while (t < out.size()
            && out.get(t).type == KEEP
            && SpecNotation.isJsWhitespace(out.get(s).ch)
            && out.get(s).ch == out.get(t).ch) {
          out.set(s, new Op(KEEP, out.get(s).ch, null));
          out.set(t, new Op(type, out.get(t).ch, "edit"));
          s++;
          t++;
        }
      }
      s = t;
    }
    return out;
  }

  private static int lineIndex(String b, int g) {
    int k = 0;
    for (int i = 0; i < g; i++) {
      if (b.charAt(i) == '\n') {
        k++;
      }
    }
    if (g == b.length() && !b.isEmpty() && !b.endsWith("\n")) {
      k++;
    }
    return k;
  }

  private static boolean sentenceEnds(String b, int i) {
    char c = b.charAt(i);
    return (c == '.' || c == '!' || c == '?')
        && (i + 1 >= b.length() || SpecNotation.isJsWhitespace(b.charAt(i + 1)));
  }

  /** Whether the edit deleted every solid character of the sentence around gap {@code g}. */
  private static boolean sentenceRemoved(String b, int g, EditMap map) {
    int s = g;
    while (s > 0 && b.charAt(s - 1) != '\n' && !(s - 1 < g - 1 && sentenceEnds(b, s - 1))) {
      s--;
    }
    int e = g;
    while (e < b.length() && b.charAt(e) != '\n') {
      if (sentenceEnds(b, e)) {
        e++;
        break;
      }
      e++;
    }
    boolean any = false;
    for (int i = s; i < e; i++) {
      if (SpecNotation.isJsWhitespace(b.charAt(i))) {
        continue;
      }
      any = true;
      if (!map.deleted[i]) {
        return false;
      }
    }
    return any;
  }

  private static int trailingBreaks(CharSequence s) {
    int n = 0;
    for (int i = s.length() - 1; i >= 0 && s.charAt(i) == '\n'; i--) {
      n++;
    }
    return n;
  }

  private static int leadingBreaks(String s) {
    int n = 0;
    for (int i = 0; i < s.length() && s.charAt(i) == '\n'; i++) {
      n++;
    }
    return n;
  }

  /** Thirty UTF-16 units of {@code s} either side of {@code at}, made visible. */
  private static String excerpt(String s, int at) {
    int a = Math.max(0, Math.min(at, s.length()) - 30);
    int z = Math.max(a, Math.min(s.length(), at + 30));
    return visible(s.substring(a, z));
  }

  /**
   * The first offset at which {@code a} and {@code b} differ (the shorter
   * length when one is a prefix of the other).
   */
  private static int firstDifference(String a, String b) {
    int n = Math.min(a.length(), b.length());
    for (int i = 0; i < n; i++) {
      if (a.charAt(i) != b.charAt(i)) {
        return i;
      }
    }
    return n;
  }

  /** {@code s} in guillemets, its line breaks shown. */
  static String visible(String s) {
    return "«" + s.replace("\n", "⏎") + "»";
  }
}
