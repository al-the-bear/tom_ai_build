package tom_som_runtime;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * A typed view over a list field, layered over the document's list store.
 *
 * <p>Items are addressed by their stable item paths
 * ({@link SpecDocument#listItems}); each is wrapped in an element facade {@code T}
 * by {@code factory}. The wrapper holds no items itself — every operation reads
 * through the live document, so it always reflects the current state.
 */
public final class SomList<T> {
  public final SpecDocument doc;
  public final String listPath;
  private final SomElementFactory<T> factory;

  /**
   * The list field's {@code @SectionIdPattern} (e.g. {@code DACEN-ITEM-xxx}), or
   * {@code null} for a pattern-less (scalar) list. Drives section-id generation
   * on {@link #add()} (AA1 criteria 3–5).
   */
  public final String pattern;

  public SomList(SpecDocument doc, String listPath, SomElementFactory<T> factory) {
    this(doc, listPath, factory, null);
  }

  public SomList(
      SpecDocument doc, String listPath, SomElementFactory<T> factory, String pattern) {
    this.doc = doc;
    this.listPath = listPath;
    this.factory = factory;
    this.pattern = pattern;
  }

  /** The number of items currently in the list. */
  public int length() {
    return doc.listItemCount(listPath);
  }

  /** The element facades for every item, in order. */
  public List<T> items() {
    List<T> out = new ArrayList<>();
    for (String p : doc.listItems(listPath)) {
      out.add(factory.create(doc, p));
    }
    return out;
  }

  /** The element facade for the item at {@code index}. */
  public T get(int index) {
    return factory.create(doc, doc.listItems(listPath).get(index));
  }

  /** The section ids currently assigned within this list, in item order. */
  public List<String> sectionIds() {
    return doc.listItemSectionIds(listPath);
  }

  /**
   * Appends a new item and returns its element facade. When the list has a
   * {@link #pattern}, the new item is assigned a section id generated from the
   * pattern using today's date for the two-letter-date component (AA1 criteria
   * 3–4); a pattern-less list ignores section ids.
   */
  public T add() {
    return add(null, null);
  }

  /**
   * Appends a new item with an explicit section-id override (AA1 criterion 5),
   * validated unique within the list — raises {@link SpecSectionIdCollision} on
   * a collision. A pattern-less list ignores the argument.
   */
  public T add(String sectionId) {
    return add(sectionId, null);
  }

  /**
   * Appends a new item and returns its element facade.
   *
   * <p>When the list has a {@link #pattern}, the new item is assigned a section
   * id (AA1 criteria 3–5): {@code sectionId} if given (an override, validated
   * unique — raises {@link SpecSectionIdCollision} on a collision), otherwise one
   * generated from the pattern using {@code date} (defaulting to today) for the
   * two-letter-date component. A pattern-less list ignores both arguments.
   */
  public T add(String sectionId, LocalDate date) {
    return factory.create(doc, addItemPath(sectionId, date));
  }

  /**
   * Appends a content-only item and sets its {@code content} leaf in one call,
   * returning the new item's element facade. Equivalent to {@link #add()}
   * followed by writing {@code content} to the item's nested
   * {@code <itemPath>/content} leaf.
   *
   * <p>Targets the nested {@code <item>/content} leaf; scalar (pattern-less
   * value) lists are out of scope for this convenience.
   */
  public T addContent(String content) {
    return addContent(content, null, null);
  }

  /**
   * Appends a content-only item with an explicit section-id override (AA1
   * criterion 5) and sets its {@code content} leaf in one call. See
   * {@link #add(String)} for the section-id semantics.
   */
  public T addContent(String content, String sectionId) {
    return addContent(content, sectionId, null);
  }

  /**
   * Appends a content-only item, writes {@code content} to its nested
   * {@code <itemPath>/content} leaf, and returns the new item's element facade.
   *
   * <p>Section-id handling mirrors {@link #add(String, LocalDate)}: with a
   * {@link #pattern}, {@code sectionId} is an override (validated unique —
   * raises {@link SpecSectionIdCollision}) else a section id is generated from
   * the pattern using {@code date} (defaulting to today); a pattern-less list
   * ignores both arguments. Targets the nested {@code <item>/content} leaf;
   * scalar lists are out of scope.
   */
  public T addContent(String content, String sectionId, LocalDate date) {
    String itemPath = addItemPath(sectionId, date);
    doc.setContent(itemPath + "/content", content); // nested <item>/content leaf
    return factory.create(doc, itemPath);
  }

  /**
   * An ordered read-only view of every item's {@code content} leaf; a missing
   * leaf coalesces to {@code ""}. Reads the nested {@code <item>/content} leaf.
   */
  public List<String> contents() {
    List<String> out = new ArrayList<>();
    for (String p : doc.listItems(listPath)) {
      String value = doc.content(p + "/content");
      out.add(value == null ? "" : value);
    }
    return out;
  }

  /**
   * Appends an item and returns its path, deriving the section id the same way
   * for {@link #add} and {@link #addContent}: a pattern-less list ignores
   * section ids; otherwise {@code sectionId} is used as an override when given,
   * else one is generated from the {@link #pattern} using {@code date}
   * (defaulting to today) for the two-letter-date component.
   */
  private String addItemPath(String sectionId, LocalDate date) {
    if (pattern == null) {
      return doc.addListItem(listPath);
    }
    String id;
    if (sectionId != null) {
      id = sectionId;
    } else {
      LocalDate when = date != null ? date : LocalDate.now();
      id =
          SpecSectionId.generateListItemSectionId(
              pattern, when.getMonthValue(), when.getDayOfMonth(), doc.listItemSectionIds(listPath));
    }
    return doc.addListItem(listPath, id);
  }

  /** Removes the item at {@code index} and every value nested beneath it. */
  public void removeAt(int index) {
    doc.removeListItem(doc.listItems(listPath).get(index));
  }
}
