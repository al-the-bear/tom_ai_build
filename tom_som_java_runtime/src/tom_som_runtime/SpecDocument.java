package tom_som_runtime;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * A sparse, live instance of a TomSpecs document — a faithful port of
 * {@code spec_document.dart} / {@code spec_document.py}.
 *
 * <p>The structure is defined by the {@link SpecModel} class graph; this holds
 * only the <i>values</i> the user/agent has actually set, keyed by the
 * globally-unique section-ID path. Three sparse stores cover the writable field
 * kinds: content/scalar leaves, {@code @Form} sections, and lists. List item
 * paths are {@code "<listPath>-<seq>"} where {@code seq} is a per-list monotonic
 * counter that never reuses a number.
 */
public final class SpecDocument {
  private final Map<String, String> content = new LinkedHashMap<>();
  private final Map<String, Map<String, String>> form = new LinkedHashMap<>();
  private final Map<String, List<String>> listItems = new LinkedHashMap<>();
  private final Map<String, Integer> listSeq = new LinkedHashMap<>();
  // Item path → document section id (AA1 criteria 3–6). Distinct from the
  // internal `-<seq>` path key: the seq path keeps nested values attached across
  // edits (never renumbered), while the section id is what the document exposes
  // and may be overridden or reused same-day after the last item is deleted.
  private final Map<String, String> itemSectionId = new LinkedHashMap<>();
  // Stored headlines (YRD3): any section path → the headline text shown for
  // that section. Sparse like content — absent means "render the effective
  // default title".
  private final Map<String, String> headline = new LinkedHashMap<>();
  // The concrete instance-level forward DocSpecs→CodeSpecs link
  // (codespecs_mapping.md §9.2): any section path → the comma-joined list of
  // CodeSpecs code locations that section maps to. Sparse like `headline`:
  // absent means "no code mapping".
  private final Map<String, String> codeSpec = new LinkedHashMap<>();

  // The authoring object-model version (`major.minor`) this document was loaded
  // from, or null for a brand-new / unstamped document. Retained here by
  // fromYaml so a consumer need not thread decoded.modelVersion to the typed
  // facade by hand; the generated loadYaml / loadFile statics apply it
  // automatically.
  private String modelVersion;

  // --- one-call loading ---------------------------------------------------

  /** The authoring model-version stamp this document was loaded from, or null. */
  public String modelVersion() {
    return modelVersion;
  }

  /** Sets the authoring model-version stamp retained on this document. */
  public void setModelVersion(String modelVersion) {
    this.modelVersion = modelVersion;
  }

  /**
   * Loads a hierarchical-v2 {@code *.docspecs.yaml} document in one call:
   * decode the YAML against the metadata {@code tree} and retain the parsed
   * {@link #modelVersion} on the document (the decoder already stamps it).
   * Collapses the former three-step decode → loadJson →
   * thread-{@code documentVersion} incantation.
   */
  public static SpecDocument fromYaml(String yaml, SomMetaTree tree) {
    return SpecDocumentYaml.decode(yaml, tree).document;
  }

  /**
   * Loads a {@code *.docspecs.yaml} document from the file at {@code path} — the
   * file companion to {@link #fromYaml(String, SomMetaTree)} the generated
   * {@code loadFile} static delegates to.
   */
  public static SpecDocument fromFile(String path, SomMetaTree tree) {
    try {
      return fromYaml(Files.readString(Path.of(path)), tree);
    } catch (IOException e) {
      throw new UncheckedIOException(e);
    }
  }

  /**
   * @deprecated The flat v1 format is gone; loading requires the
   *     metadata tree. Use {@link #fromYaml(String, SomMetaTree)}. The
   *     generated facade regains a tree-threading overload.
   */
  @Deprecated
  public static SpecDocument fromYaml(String yaml) {
    throw new UnsupportedOperationException(
        "fromYaml(String) is gone with the flat v1 format; use "
            + "fromYaml(String, SomMetaTree) (facade regeneration)");
  }

  /**
   * @deprecated The flat v1 format is gone; loading requires the
   *     metadata tree. Use {@link #fromFile(String, SomMetaTree)}. The
   *     generated facade regains a tree-threading overload.
   */
  @Deprecated
  public static SpecDocument fromFile(String path) {
    throw new UnsupportedOperationException(
        "fromFile(String) is gone with the flat v1 format; use "
            + "fromFile(String, SomMetaTree) (facade regeneration)");
  }

  // --- markdown export ----------------------------------------------------

  /**
   * Renders this document to Markdown in one call (SOM §21), using the
   * document's single <b>populated</b> root.
   *
   * <p>Companion to {@link #toMarkdown(SpecModel, String)} with a null
   * {@code rootType}: the root is the one under which this document holds any
   * value ({@link #hasValuesUnder}). Throws {@link IllegalStateException} when
   * the default is ambiguous — zero populated roots, or more than one.
   */
  public String toMarkdown(SpecModel model) {
    return toMarkdown(model, null);
  }

  /**
   * Renders this document to Markdown in one call (SOM §21).
   *
   * <p>Collapses the former {@code new SpecDocumentMarkdown(model, doc)
   * .exportRoot(model.rootByType(…))} incantation. When {@code rootType} is
   * given, that root is exported (via {@link SpecModel#rootByType}); when
   * {@code null}, the document's single <b>populated</b> root is used — a root
   * is populated when it has any value beneath its segment
   * ({@link #hasValuesUnder}). Throws {@link IllegalStateException} when the
   * default is ambiguous — zero populated roots, or more than one — so the
   * caller names the {@code rootType} explicitly.
   */
  public String toMarkdown(SpecModel model, String rootType) {
    SpecRoot root =
        rootType != null ? model.rootByType(rootType) : singlePopulatedRoot(model);
    return new SpecDocumentMarkdown(model, this).exportRoot(root);
  }

  /**
   * {@link #toMarkdown(SpecModel, String)}, plus the document path behind every
   * heading ({@link SpecDocumentMarkdown#exportRootWithMap}). Root selection is
   * the same: {@code rootType}, else the single populated root.
   */
  public SpecMarkdownRendition toMarkdownWithMap(SpecModel model, String rootType) {
    SpecRoot root =
        rootType != null ? model.rootByType(rootType) : singlePopulatedRoot(model);
    return new SpecDocumentMarkdown(model, this).exportRootWithMap(root);
  }

  // --- markdown import ----------------------------------------------------

  /**
   * Loads a SOM-rendered Markdown document (SOM §11.7) into a fresh document in
   * one call: parse, then {@link #applyMarkdownResult(SpecMarkdownResult,
   * boolean)}.
   *
   * <p>Blocks the parser rejects are not loaded, and are returned with the
   * document, so a caller can show them or refuse to save: re-exporting a
   * document whose source had rejections drops those blocks for good.
   */
  public static SpecMarkdownImport fromMarkdown(String text, SpecModel model) {
    SpecDocument document = new SpecDocument();
    SpecMarkdownResult result = new SpecDocumentMarkdown(model, document).parse(text);
    document.applyMarkdownResult(result, true);
    return new SpecMarkdownImport(document, result);
  }

  /**
   * Assembles one document from fragments — (name, document) pairs, in order —
   * written in parallel. The merge is refusing: a content path, form field,
   * list, headline or code-spec location two fragments both write is a
   * {@link SpecAssemblyOverlap}, and an assembly with any overlap has no
   * document. See {@link SpecDocumentAssembly}.
   */
  public static SpecDocumentAssembly assemble(
      List<? extends Map.Entry<String, SpecDocument>> fragments) {
    return SpecDocumentAssembly.assemble(fragments);
  }

  /** {@link #assemble(List)} over a name → document map, in its iteration order. */
  public static SpecDocumentAssembly assemble(Map<String, SpecDocument> fragments) {
    return SpecDocumentAssembly.assemble(fragments);
  }

  /**
   * Applies a parsed Markdown import, refusing a result with rejections — the
   * {@code allowRejections = false} form of
   * {@link #applyMarkdownResult(SpecMarkdownResult, boolean)}.
   */
  public void applyMarkdownResult(SpecMarkdownResult result) {
    applyMarkdownResult(result, false);
  }

  /**
   * Applies a parsed Markdown import as a <b>full overwrite</b> of the roots it
   * covers (SOM §11.7): every value under each of
   * {@link SpecMarkdownResult#rootPrefixes} is removed, then the parsed content,
   * forms, lists, headlines and codeSpecs are written. Other roots are left as
   * they are.
   *
   * <p>A result with rejections is refused with an
   * {@link IllegalStateException} — and nothing is changed — unless
   * {@code allowRejections} is true: the blocks it rejected would otherwise
   * vanish from a document the caller believes it imported whole.
   *
   * <p>Store-agnostic on both halves: the purge goes through
   * {@link #removeValuesUnder}, which clears every store, and the carry-over is
   * whatever {@link #toJson} emits. Parsed paths are used as-is (this port has
   * no path normalizer).
   */
  @SuppressWarnings("unchecked")
  public void applyMarkdownResult(SpecMarkdownResult result, boolean allowRejections) {
    if (!allowRejections && !result.rejections.isEmpty()) {
      SpecMarkdownRejection first = result.rejections.get(0);
      throw new IllegalStateException(
          "markdown import has " + result.rejections.size() + " rejected block(s); "
              + "first at line " + first.line + ": " + first.message);
    }
    if (result.rootPrefixes.isEmpty()) {
      return;
    }
    for (String prefix : result.rootPrefixes) {
      removeValuesUnder(prefix);
    }

    Map<String, Object> held = toJson();
    Map<String, Object> contentStore = heldStore(held, "content");
    contentStore.putAll(result.content);
    Map<String, Object> formsStore = heldStore(held, "forms");
    formsStore.putAll(result.forms);
    Map<String, Object> headlinesStore = heldStore(held, "headlines");
    headlinesStore.putAll(result.headlines);
    Map<String, Object> codeSpecsStore = heldStore(held, "codeSpecs");
    codeSpecsStore.putAll(result.codeSpecs);

    Map<String, Object> listsStore = heldStore(held, "lists");
    for (Map.Entry<String, Object> entry : result.lists.entrySet()) {
      Map<String, Object> spec = entry.getValue() instanceof Map
          ? (Map<String, Object>) entry.getValue()
          : Collections.emptyMap();
      Map<String, Object> record = new LinkedHashMap<>();
      record.put("seq", spec.get("seq"));
      List<String> items = new ArrayList<>();
      if (spec.get("items") instanceof List) {
        for (Object i : (List<Object>) spec.get("items")) {
          items.add(String.valueOf(i));
        }
      }
      record.put("items", items);
      if (spec.get("ids") instanceof Map) {
        Map<String, Object> ids = new LinkedHashMap<>();
        for (Map.Entry<Object, Object> e : ((Map<Object, Object>) spec.get("ids")).entrySet()) {
          ids.put(String.valueOf(e.getKey()), e.getValue());
        }
        record.put("ids", ids);
      }
      listsStore.put(entry.getKey(), record);
    }

    Map<String, Object> merged = new LinkedHashMap<>();
    merged.put("content", contentStore);
    merged.put("forms", formsStore);
    merged.put("lists", listsStore);
    merged.put("headlines", headlinesStore);
    merged.put("codeSpecs", codeSpecsStore);
    loadJson(merged);
  }

  /** A mutable copy of one {@link #toJson} store, empty when absent. */
  @SuppressWarnings("unchecked")
  private static Map<String, Object> heldStore(Map<String, Object> held, String name) {
    Map<String, Object> out = new LinkedHashMap<>();
    Object raw = held.get(name);
    if (raw instanceof Map) {
      for (Map.Entry<Object, Object> e : ((Map<Object, Object>) raw).entrySet()) {
        out.put(String.valueOf(e.getKey()), e.getValue());
      }
    }
    return out;
  }

  /**
   * The one root under which this document holds any value, for
   * {@link #toMarkdown}'s default. Throws {@link IllegalStateException} when zero
   * or more than one root is populated.
   */
  private SpecRoot singlePopulatedRoot(SpecModel model) {
    List<SpecRoot> populated = new ArrayList<>();
    for (SpecRoot r : model.roots) {
      if (hasValuesUnder(r.sectionId != null ? r.sectionId : r.type)) {
        populated.add(r);
      }
    }
    if (populated.size() == 1) {
      return populated.get(0);
    }
    if (populated.isEmpty()) {
      throw new IllegalStateException(
          "document has no populated root to export; pass rootType to choose one");
    }
    List<String> types = new ArrayList<>();
    for (SpecRoot r : populated) {
      types.add(r.type);
    }
    throw new IllegalStateException(
        "document has " + populated.size() + " populated roots ("
            + String.join(", ", types) + "); pass rootType to choose one");
  }

  // --- content ------------------------------------------------------------

  public String content(String path) {
    return content.get(path);
  }

  /**
   * True iff a non-empty content-leaf value exists at exactly {@code path} (SOM
   * SOM §21). Leaf-exact: a value nested beneath {@code path} does not count.
   * Null-free companion to {@link #content(String)}.
   */
  public boolean hasContent(String path) {
    String v = content(path);
    return v != null && !v.isEmpty();
  }

  /** Sets the content string at {@code path}. An empty value clears it. */
  public void setContent(String path, String value) {
    dropValueIndex();
    if (value.isEmpty()) {
      content.remove(path);
    } else {
      content.put(path, value);
    }
  }

  // --- headlines (YRD3) -----------------------------------------------------

  /**
   * The stored headline at {@code path}, or {@code null} when the section
   * renders its effective default title (YRD3 — headlines are sparse like
   * content).
   */
  public String headline(String path) {
    return headline.get(path);
  }

  /**
   * Sets the stored headline at {@code path}. An empty value clears it,
   * returning the section to its default title.
   */
  public void setHeadline(String path, String value) {
    dropValueIndex();
    if (value.isEmpty()) {
      headline.remove(path);
    } else {
      headline.put(path, value);
    }
  }

  /** All section paths currently carrying a stored headline. */
  public Set<String> headlinePaths() {
    return headline.keySet();
  }

  // --- codeSpecs (codespecs_mapping.md §9.2)
  // -----------------------------------------------------

  /**
   * The stored codeSpec mapping at {@code path} as the comma-joined list of
   * CodeSpecs code locations, or {@code null} when the section carries no
   * mapping (codespecs_mapping.md §9.2 — codeSpec is sparse like the headline).
   */
  public String codeSpec(String path) {
    return codeSpec.get(path);
  }

  /**
   * Sets the stored codeSpec mapping at {@code path} (the comma-joined list of
   * CodeSpecs code locations). An empty value clears it, returning the section
   * to carrying no mapping.
   */
  public void setCodeSpec(String path, String value) {
    dropValueIndex();
    if (value.isEmpty()) {
      codeSpec.remove(path);
    } else {
      codeSpec.put(path, value);
    }
  }

  /** All section paths currently carrying a stored codeSpec mapping. */
  public Set<String> codeSpecPaths() {
    return codeSpec.keySet();
  }

  // --- forms --------------------------------------------------------------

  public String formField(String path, String fieldName) {
    Map<String, String> fields = form.get(path);
    return fields == null ? null : fields.get(fieldName);
  }

  /**
   * Sets form {@code fieldName} at {@code path}. An empty value clears that field
   * (and the whole form entry once its last field is gone).
   */
  public void setFormField(String path, String fieldName, String value) {
    dropValueIndex();
    Map<String, String> fields = form.computeIfAbsent(path, k -> new LinkedHashMap<>());
    if (value.isEmpty()) {
      fields.remove(fieldName);
      if (fields.isEmpty()) {
        form.remove(path);
      }
    } else {
      fields.put(fieldName, value);
    }
  }

  // --- lists --------------------------------------------------------------

  public List<String> listItems(String listPath) {
    List<String> items = listItems.get(listPath);
    return items == null ? new ArrayList<>() : new ArrayList<>(items);
  }

  /** Appends a new item to the list at {@code listPath} and returns its path. */
  public String addListItem(String listPath) {
    return addListItem(listPath, null);
  }

  /**
   * Appends a new item to the list at {@code listPath} and returns its stable
   * path.
   *
   * <p>When {@code sectionId} is given it becomes the item's section id after a
   * uniqueness check against the list's other items (AA1 criterion 5); a
   * collision raises {@link SpecSectionIdCollision}. Section-id <i>generation</i>
   * from a {@code @SectionIdPattern} lives in the caller (it needs the pattern);
   * this layer only stores and guards uniqueness.
   */
  public String addListItem(String listPath, String sectionId) {
    dropValueIndex();
    if (sectionId != null) {
      assertSectionIdFree(listPath, sectionId, null);
    }
    int seq = listSeq.getOrDefault(listPath, 0) + 1;
    listSeq.put(listPath, seq);
    String itemPath = listPath + "-" + seq;
    listItems.computeIfAbsent(listPath, k -> new ArrayList<>()).add(itemPath);
    if (sectionId != null) {
      itemSectionId.put(itemPath, sectionId);
    }
    return itemPath;
  }

  /**
   * The section id assigned to the list item at {@code itemPath}, or {@code null}
   * if none has been set (AA1 criterion 1 read path).
   */
  public String itemSectionId(String itemPath) {
    return itemSectionId.get(itemPath);
  }

  /**
   * Overrides the section id of the list item at {@code itemPath} (AA1 criterion
   * 5). Validates that the new {@code id} is unique among the <i>other</i> items
   * of the same owning list; a collision raises {@link SpecSectionIdCollision}.
   * Assigning an id equal to the item's current id is a no-op. Throws
   * {@link IllegalArgumentException} if {@code itemPath} is not a live list item.
   */
  public void setItemSectionId(String itemPath, String id) {
    dropValueIndex();
    String owningList = owningListOf(itemPath);
    if (owningList == null) {
      throw new IllegalArgumentException("\"" + itemPath + "\" is not a live list item");
    }
    if (id.equals(itemSectionId.get(itemPath))) {
      return;
    }
    assertSectionIdFree(owningList, id, itemPath);
    itemSectionId.put(itemPath, id);
  }

  /**
   * The section ids currently assigned within the list at {@code listPath}, in
   * item order (items without an id are skipped). Feeds both id generation
   * (existing ids) and uniqueness checks.
   */
  public List<String> listItemSectionIds(String listPath) {
    List<String> out = new ArrayList<>();
    List<String> items = listItems.get(listPath);
    if (items != null) {
      for (String itemPath : items) {
        String id = itemSectionId.get(itemPath);
        if (id != null) {
          out.add(id);
        }
      }
    }
    return out;
  }

  private String owningListOf(String itemPath) {
    for (Map.Entry<String, List<String>> e : listItems.entrySet()) {
      if (e.getValue().contains(itemPath)) {
        return e.getKey();
      }
    }
    return null;
  }

  private void assertSectionIdFree(String listPath, String id, String exceptItemPath) {
    List<String> items = listItems.get(listPath);
    if (items == null) {
      return;
    }
    for (String itemPath : items) {
      if (itemPath.equals(exceptItemPath)) {
        continue;
      }
      if (id.equals(itemSectionId.get(itemPath))) {
        throw new SpecSectionIdCollision(id, listPath);
      }
    }
  }

  /** {@link #moveListItem(SpecModel, String, int, String)} within the item's own list. */
  public SpecListItemMove moveListItem(SpecModel model, String itemPath, int toIndex) {
    return moveListItem(model, itemPath, toIndex, null);
  }

  /**
   * Moves the list item at {@code itemPath} to position {@code toIndex} (0-based)
   * of its list, or of {@code toList}, another list of the same element class
   * (vsctsa44).
   *
   * <p><b>A path is a position, the section id is the identity.</b> Every
   * affected list is renumbered to {@code <list>-1 … <list>-n} in its new order,
   * and every value under each item — content, forms, nested lists, headline,
   * code-spec, stored id — travels with it. An anonymous item whose positional
   * id would change has its old id stored, so its identity survives the
   * renumbering. The result maps every old item path to its new one; a caller
   * holding anything else keyed by path (the {@code review:} pass) re-keys it
   * with {@link SpecDocumentYaml#rekeyReview}.
   *
   * <p>Across lists, the destination must hold the same element class, and an
   * item with a stored id keeps it only when the id fits the destination's
   * {@code @SectionIdPattern} and is free there; otherwise the move is refused
   * ({@link IllegalArgumentException} / {@link SpecSectionIdCollision}) and
   * nothing changes. An anonymous item takes its positional id in the
   * destination. A {@code toIndex} outside {@code 0..n} (n = the destination's
   * length without the item) is an {@link IndexOutOfBoundsException}.
   */
  public SpecListItemMove moveListItem(
      SpecModel model, String itemPath, int toIndex, String toList) {
    dropValueIndex();
    final String item = itemPath;
    final String from = owningListOf(item);
    if (from == null) {
      throw new IllegalArgumentException("\"" + itemPath + "\" is not a live list item");
    }
    final String to = toList == null ? from : toList;
    SpecReflection refl = new SpecReflection(model);
    SpecResolution fromRes = refl.resolve(from);
    SpecResolution toRes = refl.resolve(to);
    final SpecField fromField = fromRes == null ? null : fromRes.field;
    final SpecField toField = toRes == null ? null : toRes.field;
    if (toField == null || toField.kind != SpecFieldKind.LIST) {
      throw new IllegalArgumentException("toList \"" + toList + "\" is not a list of the model");
    }
    final boolean cross = !to.equals(from);
    String fromElement = fromField == null ? null : fromField.elementType;
    if (cross && !java.util.Objects.equals(toField.elementType, fromElement)) {
      throw new IllegalArgumentException(
          "toList \"" + toList + "\" holds " + toField.elementType + ", but the item is a "
              + fromElement + " — an item moves only between lists of its own element class");
    }
    String storedId = itemSectionId.get(item);
    if (cross && storedId != null) {
      String pattern = toField.sectionIdPattern;
      if (pattern != null && !sectionIdFitsPattern(pattern, storedId)) {
        throw new IllegalArgumentException(
            "section id \"" + storedId + "\" does not fit the destination pattern " + pattern
                + " — set an id that does before moving the item");
      }
      assertSectionIdFree(to, storedId, null);
    }

    // The new orders.
    final List<String> fromItems = new ArrayList<>(listItems.get(from));
    fromItems.remove(item);
    final List<String> toItems;
    if (cross) {
      List<String> held = listItems.get(to);
      toItems = held == null ? new ArrayList<>() : new ArrayList<>(held);
    } else {
      toItems = fromItems;
    }
    if (toIndex < 0 || toIndex > toItems.size()) {
      throw new IndexOutOfBoundsException(
          "toIndex " + toIndex + " is not in 0.." + toItems.size());
    }
    toItems.add(toIndex, item);

    // Each affected item's effective id before the move, so an anonymous item
    // keeps its identity when its position changes.
    Map<String, String> before = new LinkedHashMap<>();
    List<String> heldFrom = listItems.get(from);
    for (String p : heldFrom) {
      before.put(p, effectiveItemId(from, fromField, itemSectionId.get(p), heldFrom.indexOf(p) + 1));
    }
    if (cross) {
      List<String> heldTo = listItems.get(to);
      if (heldTo != null) {
        for (String p : heldTo) {
          before.put(p, effectiveItemId(to, toField, itemSectionId.get(p), heldTo.indexOf(p) + 1));
        }
      }
    }

    // Old → new item paths, and the ids anonymous items must now store.
    Map<String, String> renamed = new LinkedHashMap<>();
    Map<String, String> pinned = new LinkedHashMap<>();
    renumberForMove(from, fromField, fromItems, item, cross, before, renamed, pinned);
    if (cross) {
      renumberForMove(to, toField, toItems, item, cross, before, renamed, pinned);
    }

    Map<String, String> newContent = rekeyStore(content, renamed);
    Map<String, Map<String, String>> newForm = rekeyStore(form, renamed);
    Map<String, String> newHeadline = rekeyStore(headline, renamed);
    Map<String, String> newCodeSpec = rekeyStore(codeSpec, renamed);
    Map<String, String> ids = rekeyStore(itemSectionId, renamed);
    for (Map.Entry<String, String> e : pinned.entrySet()) {
      ids.put(remapPath(e.getKey(), renamed), e.getValue());
    }
    Map<String, Integer> seq = rekeyStore(listSeq, renamed);
    Map<String, List<String>> lists = new LinkedHashMap<>();
    for (Map.Entry<String, List<String>> e : listItems.entrySet()) {
      lists.put(remapPath(e.getKey(), renamed), remapAll(e.getValue(), renamed));
    }
    lists.put(remapPath(from, renamed), remapAll(fromItems, renamed));
    seq.put(remapPath(from, renamed), fromItems.size());
    if (cross) {
      lists.put(remapPath(to, renamed), remapAll(toItems, renamed));
      seq.put(remapPath(to, renamed), toItems.size());
    }
    lists.values().removeIf(List::isEmpty);

    content.clear();
    content.putAll(newContent);
    form.clear();
    form.putAll(newForm);
    headline.clear();
    headline.putAll(newHeadline);
    codeSpec.clear();
    codeSpec.putAll(newCodeSpec);
    itemSectionId.clear();
    itemSectionId.putAll(ids);
    listSeq.clear();
    listSeq.putAll(seq);
    listItems.clear();
    listItems.putAll(lists);

    Map<String, String> pinnedIds = new LinkedHashMap<>();
    for (Map.Entry<String, String> e : pinned.entrySet()) {
      pinnedIds.put(remapPath(e.getKey(), renamed), e.getValue());
    }
    return new SpecListItemMove(remapPath(item, renamed), renamed, pinnedIds);
  }

  /** The effective section id of an item of {@code list} at 1-based {@code position}. */
  private static String effectiveItemId(
      String list, SpecField field, String storedId, int position) {
    return SpecSectionId.effectiveListItemSectionId(
        storedId,
        field == null ? null : field.sectionIdPattern,
        position,
        field != null ? field.name : list.substring(list.lastIndexOf('/') + 1));
  }

  /**
   * Records the renames of {@code list} renumbered in {@code items} order, and
   * the old effective id of each anonymous item whose positional id changes.
   */
  private void renumberForMove(
      String list,
      SpecField field,
      List<String> items,
      String item,
      boolean cross,
      Map<String, String> before,
      Map<String, String> renamed,
      Map<String, String> pinned) {
    for (int i = 0; i < items.size(); i++) {
      String old = items.get(i);
      String now = list + "-" + (i + 1);
      if (!old.equals(now)) {
        renamed.put(old, now);
      }
      boolean crossing = old.equals(item) && cross;
      if (itemSectionId.get(old) != null || crossing) {
        continue;
      }
      String positional = effectiveItemId(list, field, null, i + 1);
      if (!positional.equals(before.get(old))) {
        pinned.put(old, before.get(old));
      }
    }
  }

  /**
   * {@code key} with its leading renamed item path ({@code old}, {@code old/…}
   * or {@code old-…}) replaced by the new one; unchanged when under none.
   */
  static String remapPath(String key, Map<String, String> renamed) {
    for (Map.Entry<String, String> e : renamed.entrySet()) {
      String old = e.getKey();
      if (key.equals(old)) {
        return e.getValue();
      }
      if (key.startsWith(old + "/") || key.startsWith(old + "-")) {
        return e.getValue() + key.substring(old.length());
      }
    }
    return key;
  }

  private static List<String> remapAll(List<String> paths, Map<String, String> renamed) {
    List<String> out = new ArrayList<>();
    for (String p : paths) {
      out.add(remapPath(p, renamed));
    }
    return out;
  }

  private static <V> Map<String, V> rekeyStore(Map<String, V> store, Map<String, String> renamed) {
    Map<String, V> out = new LinkedHashMap<>();
    for (Map.Entry<String, V> e : store.entrySet()) {
      out.put(remapPath(e.getKey(), renamed), e.getValue());
    }
    return out;
  }

  /** Whether {@code id} fits {@code pattern} ({@code xxx} = one or more characters, anchored). */
  private static boolean sectionIdFitsPattern(String pattern, String id) {
    StringBuilder re = new StringBuilder();
    String[] parts = pattern.split(java.util.regex.Pattern.quote("xxx"), -1);
    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        re.append(".+");
      }
      re.append(java.util.regex.Pattern.quote(parts[i]));
    }
    return java.util.regex.Pattern.compile(re.toString()).matcher(id).matches();
  }

  /**
   * Removes the list item at {@code itemPath} along with every value nested
   * beneath it. The counter is left untouched so future items keep getting fresh
   * sequence numbers (no renumbering).
   */
  public boolean removeListItem(String itemPath) {
    dropValueIndex();
    String owningList = null;
    for (Map.Entry<String, List<String>> e : listItems.entrySet()) {
      if (e.getValue().contains(itemPath)) {
        owningList = e.getKey();
        break;
      }
    }
    if (owningList == null) {
      return false;
    }
    List<String> items = listItems.get(owningList);
    items.remove(itemPath);
    if (items.isEmpty()) {
      listItems.remove(owningList);
    }
    purgeUnder(itemPath);
    return true;
  }

  private boolean isUnder(String key, String prefix) {
    return key.equals(prefix)
        || key.startsWith(prefix + "/")
        || key.startsWith(prefix + "-");
  }

  private void purgeUnder(String prefix) {
    dropValueIndex();
    content.keySet().removeIf(k -> isUnder(k, prefix));
    form.keySet().removeIf(k -> isUnder(k, prefix));
    listItems.keySet().removeIf(k -> isUnder(k, prefix));
    listSeq.keySet().removeIf(k -> isUnder(k, prefix));
    itemSectionId.keySet().removeIf(k -> isUnder(k, prefix));
    headline.keySet().removeIf(k -> isUnder(k, prefix));
    codeSpec.keySet().removeIf(k -> isUnder(k, prefix));
  }

  /**
   * Drops every value at {@code prefix} or nested beneath it — content, form
   * entries, list items (with their nested values, ids and counters), and stored
   * headlines (YRD7 generic modification API: "clear section").
   *
   * <p>The predicate is the same one {@link #hasValuesUnder} uses, so after this
   * call {@code hasValuesUnder(prefix)} is {@code false}. Note this clears
   * <i>values under a section path</i>; removing a single list item from its
   * owning list is {@link #removeListItem}.
   */
  public void removeValuesUnder(String prefix) {
    purgeUnder(prefix);
  }

  // --- queries ------------------------------------------------------------

  public boolean isEmpty() {
    return content.isEmpty() && form.isEmpty() && listItems.isEmpty()
        && headline.isEmpty() && codeSpec.isEmpty();
  }

  /**
   * Whether any value exists at {@code prefix} or nested beneath it — the
   * structural "empty = no value" test (the exact inverse of the purge
   * predicate).
   */
  public boolean hasValuesUnder(String prefix) {
    if (valueIndex == null) {
      valueIndex = buildValueIndex();
    }
    return valueIndex.contains(prefix);
  }

  /**
   * Every stored key plus every prefix of one that ends right before a {@code /}
   * or a {@code -} — exactly the paths for which "a key equals it, or continues
   * it after {@code /} or {@code -}" holds, so {@link #hasValuesUnder} is one set
   * lookup.
   *
   * <p>Why: the markdown emitter, the validator and the query engine ask
   * {@link #hasValuesUnder} once per model node, and a scan of every stored key
   * per question made rendering a large specification quadratic. Built on the
   * first question and dropped by every mutator ({@link #dropValueIndex}).
   */
  private Set<String> valueIndex;

  private Set<String> buildValueIndex() {
    Set<String> index = new HashSet<>();
    List<Set<String>> stores = List.of(
        content.keySet(), form.keySet(), listItems.keySet(),
        headline.keySet(), codeSpec.keySet());
    for (Set<String> keys : stores) {
      for (String key : keys) {
        index.add(key);
        for (int i = 0; i < key.length(); i++) {
          char c = key.charAt(i);
          if (c == '/' || c == '-') {
            index.add(key.substring(0, i));
          }
        }
      }
    }
    return index;
  }

  /** Called first by every method that changes a store's key set. */
  private void dropValueIndex() {
    valueIndex = null;
  }


  public Set<String> contentPaths() {
    return content.keySet();
  }

  public Set<String> formPaths() {
    return form.keySet();
  }

  public Set<String> listPaths() {
    return listItems.keySet();
  }

  public Set<String> formFieldNames(String path) {
    Map<String, String> fields = form.get(path);
    return fields == null ? Collections.emptySet() : fields.keySet();
  }

  public int listItemCount(String listPath) {
    List<String> items = listItems.get(listPath);
    return items == null ? 0 : items.size();
  }

  // --- persistence --------------------------------------------------------

  /**
   * A plain-data view of every value held, for persistence. Only non-empty
   * stores are included, and each is sorted by full section-ID path so the saved
   * file diffs/merges cleanly. The inverse of {@link #loadJson}.
   */
  public Map<String, Object> toJson() {
    Map<String, Object> out = new LinkedHashMap<>();
    if (!content.isEmpty()) {
      out.put("content", new TreeMap<>(content));
    }
    if (!form.isEmpty()) {
      Map<String, Object> forms = new TreeMap<>();
      for (Map.Entry<String, Map<String, String>> e : form.entrySet()) {
        forms.put(e.getKey(), new TreeMap<>(e.getValue()));
      }
      out.put("forms", forms);
    }
    if (!listItems.isEmpty()) {
      Map<String, Object> lists = new TreeMap<>();
      for (Map.Entry<String, List<String>> e : listItems.entrySet()) {
        Map<String, Object> spec = new LinkedHashMap<>();
        spec.put("seq", listSeq.getOrDefault(e.getKey(), e.getValue().size()));
        spec.put("items", new ArrayList<>(e.getValue()));
        Map<String, Object> ids = new TreeMap<>();
        for (String itemPath : e.getValue()) {
          String id = itemSectionId.get(itemPath);
          if (id != null) {
            ids.put(itemPath, id);
          }
        }
        if (!ids.isEmpty()) {
          spec.put("ids", ids);
        }
        lists.put(e.getKey(), spec);
      }
      out.put("lists", lists);
    }
    if (!headline.isEmpty()) {
      out.put("headlines", new TreeMap<>(headline));
    }
    if (!codeSpec.isEmpty()) {
      out.put("codeSpecs", new TreeMap<>(codeSpec));
    }
    return out;
  }

  /**
   * Replaces every store from a {@link #toJson}-shaped map. Coerces leaf values
   * to strings and skips unknown/empty entries.
   */
  @SuppressWarnings("unchecked")
  public void loadJson(Map<String, Object> json) {
    dropValueIndex();
    content.clear();
    form.clear();
    listItems.clear();
    listSeq.clear();
    itemSectionId.clear();
    headline.clear();
    codeSpec.clear();

    Object rawContent = json.get("content");
    if (rawContent instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawContent).entrySet()) {
        if (e.getValue() != null) {
          content.put(e.getKey(), e.getValue().toString());
        }
      }
    }

    Object rawForms = json.get("forms");
    if (rawForms instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawForms).entrySet()) {
        if (e.getValue() instanceof Map) {
          Map<String, String> entry = new LinkedHashMap<>();
          for (Map.Entry<String, Object> fe :
              ((Map<String, Object>) e.getValue()).entrySet()) {
            if (fe.getValue() != null) {
              entry.put(fe.getKey(), fe.getValue().toString());
            }
          }
          if (!entry.isEmpty()) {
            form.put(e.getKey(), entry);
          }
        }
      }
    }

    Object rawLists = json.get("lists");
    if (rawLists instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawLists).entrySet()) {
        if (e.getValue() instanceof Map) {
          Map<String, Object> spec = (Map<String, Object>) e.getValue();
          List<String> itemList = new ArrayList<>();
          Object items = spec.get("items");
          if (items instanceof List) {
            for (Object it : (List<Object>) items) {
              itemList.add(it.toString());
            }
          }
          if (!itemList.isEmpty()) {
            listItems.put(e.getKey(), itemList);
          }
          Object seq = spec.get("seq");
          if (seq instanceof Number) {
            listSeq.put(e.getKey(), ((Number) seq).intValue());
          } else if (seq instanceof String && isSignedInt((String) seq)) {
            listSeq.put(e.getKey(), Integer.parseInt((String) seq));
          } else {
            listSeq.put(e.getKey(), itemList.size());
          }
          Object ids = spec.get("ids");
          if (ids instanceof Map) {
            for (Map.Entry<String, Object> ie : ((Map<String, Object>) ids).entrySet()) {
              if (ie.getValue() != null) {
                itemSectionId.put(ie.getKey(), ie.getValue().toString());
              }
            }
          }
        }
      }
    }

    Object rawHeadlines = json.get("headlines");
    if (rawHeadlines instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawHeadlines).entrySet()) {
        if (e.getValue() != null && !e.getValue().toString().isEmpty()) {
          headline.put(e.getKey(), e.getValue().toString());
        }
      }
    }

    Object rawCodeSpecs = json.get("codeSpecs");
    if (rawCodeSpecs instanceof Map) {
      for (Map.Entry<String, Object> e : ((Map<String, Object>) rawCodeSpecs).entrySet()) {
        if (e.getValue() != null && !e.getValue().toString().isEmpty()) {
          codeSpec.put(e.getKey(), e.getValue().toString());
        }
      }
    }
  }

  private static boolean isSignedInt(String s) {
    String t = s.startsWith("-") ? s.substring(1) : s;
    if (t.isEmpty()) {
      return false;
    }
    for (int i = 0; i < t.length(); i++) {
      if (!Character.isDigit(t.charAt(i))) {
        return false;
      }
    }
    return true;
  }
}
