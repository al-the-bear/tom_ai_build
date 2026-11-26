package tom_som_runtime;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * SpecDocumentMarkdownGenerated — the generated parts of a rendition (SOM
 * §11.12): tables the rendition derives completely from the links of a
 * document, written at the start of the section they belong to as a
 * {@code derived} block and read back as nothing. A port of the Go runtime's
 * {@code spec_document_markdown_generated.go} (itself a port of the Python,
 * JavaScript, TypeScript and Dart runtimes'
 * {@code spec_document_markdown_generated}).
 *
 * <p>The tables are the four requirement views: the traceability matrix
 * ({@code RSP-TRAC} / {@code RO-TRAC}), the coverage ({@code REQCOV}), the
 * relationships ({@code RERE-REQU-LST}) and the use-case traceability
 * ({@code USCATR}). One instance is one root's generated parts.
 *
 * <p>Internal to {@link SpecDocumentMarkdown}.
 */
final class SpecDocumentMarkdownGenerated {
  /**
   * Written by the emitter at a generated place without a table: replaced by
   * an empty {@code derived} block when the value written after it begins
   * with a {@code derived} block, else removed with its blank line (SOM
   * §11.12).
   */
  static final String DERIVED_PLACEHOLDER = "\u0000derived\u0000";

  /**
   * The requirement classes whose elements are the rows of the requirement
   * views: every element {@code INTR.relatedRequirements} may name.
   */
  private static final List<String> REQUIREMENT_CLASSES = List.of("FRE", "TERQ", "SECRQ", "ORRQ");

  /**
   * A column of a generated table: its header, the place its cells read
   * ({@code null}: the row's id), whether it says only {@code yes} / {@code no}.
   */
  private static final class Column {
    final String header;
    final String place;
    final boolean covered;

    Column(String header, String place, boolean covered) {
      this.header = header;
      this.place = place;
      this.covered = covered;
    }
  }

  /**
   * A generated table: the section ids it opens, its label, the classes of
   * its rows, the classes the row's id is taken from (empty: the row's own),
   * its columns.
   */
  private static final class Table {
    final List<String> at;
    final String label;
    final List<String> rows;
    final List<String> owner;
    final List<Column> columns;

    Table(List<String> at, String label, List<String> rows, List<String> owner,
        List<Column> columns) {
      this.at = at;
      this.label = label;
      this.rows = rows;
      this.owner = owner;
      this.columns = columns;
    }
  }

  private static Column col(String header, String place) {
    return new Column(header, place, false);
  }

  /**
   * The generated tables (SOM §11.12): the requirement views of
   * DP-part-model-links-5 / -11 (D1–D4) where the links hold a table.
   */
  private static final List<Table> TABLES = List.of(
      new Table(
          List.of("RSP-TRAC", "RO-TRAC"),
          "Generated from each requirement's traceability; edit it there",
          REQUIREMENT_CLASSES,
          Collections.emptyList(),
          List.of(
              col("Requirement", null),
              col("Use cases", "RT-TRAC.relatedUseCases"),
              col("Screens", "RETRAR.relatedScreens"),
              col("Data entities", "RETRAR.relatedDataEntities"),
              col("Tests", "RETRAR.relatedTestCases"))),
      new Table(
          List.of("REQCOV"),
          "Generated from each requirement's test cases; edit them there",
          REQUIREMENT_CLASSES,
          Collections.emptyList(),
          List.of(
              col("Requirement", null),
              new Column("Covered", "RETRAR.relatedTestCases", true),
              col("By", "RETRAR.relatedTestCases"))),
      new Table(
          List.of("RERE-REQU-LST"),
          "Generated from each requirement's dependencies; edit them there",
          List.of("RQDEP"),
          REQUIREMENT_CLASSES,
          List.of(
              col("Requirement", null),
              col("Dependency", "RQDEP.dependencyType"),
              col("Related requirement", "RQDEP-RELA-REF.ref"))),
      new Table(
          List.of("USCATR"),
          "Generated from each use case's traceability; edit it there",
          List.of("INEN"),
          Collections.emptyList(),
          List.of(
              col("Use case", null),
              col("Process", "INTR.relatedProcess"),
              col("Requirements", "INTR.relatedRequirements"),
              col("Tests", "INTR.relatedTestCases"))));

  /** The generated table opening a heading with section id {@code id}, or {@code null}. */
  private static Table tableAt(String id) {
    for (Table t : TABLES) {
      if (t.at.contains(id)) {
        return t;
      }
    }
    return null;
  }

  private final SpecDocumentMarkdownLinked nav;
  private Map<String, List<String>> blockMap;
  private List<String> itemsList;

  SpecDocumentMarkdownGenerated(SpecDocumentMarkdownLinked nav) {
    this.nav = nav;
  }

  /**
   * Whether the heading at {@code path} is a generated place (structural: its
   * section id opens a generated table).
   */
  boolean isPlace(String path) {
    SomMetaNode node = nav.tree.byPath(path);
    if (node == null || !nav.walk(path, null, nav.doc(), null).headingPath.equals(path)) {
      return false;
    }
    return tableAt(nav.codec.headingIdOf(node)) != null;
  }

  /** The blocks of this document, by heading path: only the places whose table has rows. */
  Map<String, List<String>> blocks() {
    if (blockMap != null) {
      return blockMap;
    }
    Map<String, List<String>> out = new LinkedHashMap<>();
    SpecDocumentMarkdown codec = nav.codec;
    for (SomMetaNode n : nav.tree.allNodes()) {
      String path = n.path();
      if (path == null || path.isEmpty() || codec.isTransparentSection(n)
          || SpecDocumentMarkdown.isTransparentValue(n)) {
        continue;
      }
      Table table = tableAt(codec.headingIdOf(n));
      if (table == null) {
        continue;
      }
      List<String> block = block(table);
      if (block != null) {
        out.put(path, block);
      }
    }
    blockMap = out;
    return out;
  }

  /**
   * Whether a generated block stands at or beneath {@code path}, so the
   * heading is written even when the document holds no value there.
   */
  boolean forces(String path) {
    for (String p : blocks().keySet()) {
      if (p.equals(path) || p.startsWith(path + "/")) {
        return true;
      }
    }
    return false;
  }

  /** Every element of the document, in rendition order. */
  private List<String> items() {
    if (itemsList == null) {
      itemsList = new ArrayList<>();
      collectItems(nav.tree.root, nav.rootSeg(), itemsList);
    }
    return itemsList;
  }

  private void collectItems(SomMetaNode node, String path, List<String> out) {
    SpecDocument doc = nav.doc();
    for (SpecDocumentMarkdown.NodeRel child : nav.codec.effectiveChildren(node)) {
      String p = path + "/" + child.rel;
      if (!doc.hasValuesUnder(p)) {
        continue;
      }
      if (SomMetaKind.LIST.equals(child.node.kind)) {
        for (String item : doc.listItems(p)) {
          out.add(item);
          SomMetaNode element = child.node.elementNode;
          if (element != null && !element.recursive) {
            collectItems(element, item, out);
          }
        }
      } else if (SomMetaKind.SECTION.equals(child.node.kind)
          || SomMetaKind.COMPLEX.equals(child.node.kind)) {
        collectItems(child.node, p, out);
      }
    }
  }

  /** The section id of the class of the element at {@code item}, or {@code null}. */
  private String classId(String item) {
    SpecResolution r = nav.refl.resolve(item);
    if (r == null || r.targetClass == null) {
      return null;
    }
    return r.targetClass.sectionId;
  }

  /** The block lines of {@code table}, {@code null} when it has no row. */
  private List<String> block(Table table) {
    List<List<String>> rows = new ArrayList<>();
    SpecDocument doc = nav.doc();
    for (String item : items()) {
      String classId = classId(item);
      if (classId == null || classId.isEmpty() || !table.rows.contains(classId)) {
        continue;
      }
      List<String> cells = new ArrayList<>();
      for (Column c : table.columns) {
        if (c.place == null) {
          cells.add(idCell(rowOwner(item, table)));
          continue;
        }
        SpecPlaceResolution r = SpecLinkValidator.resolvePlaceAt(nav.refl, c.place, item);
        String fld = r == null ? null : r.field();
        String value = "";
        if (r != null && fld != null && !fld.isEmpty()) {
          String v = doc.formField(r.path, fld);
          if (v != null) {
            value = v.trim();
          }
        }
        if (c.covered) {
          cells.add(value.isEmpty() ? "no" : "yes");
          continue;
        }
        if (value.isEmpty()) {
          cells.add("");
          continue;
        }
        SomFormFieldMeta meta = null;
        SomMetaNode formNode = nav.tree.byPath(r.path);
        if (formNode != null && formNode.form != null) {
          for (SomFormFieldMeta f : formNode.form.fields) {
            if (f.name.equals(fld)) {
              meta = f;
              break;
            }
          }
        }
        cells.add(meta == null ? value.replace("|", "\\|") : nav.codec.linkedCellText(meta, value));
      }
      rows.add(cells);
    }
    if (rows.isEmpty()) {
      return null;
    }
    List<String> headers = new ArrayList<>();
    for (Column c : table.columns) {
      headers.add(c.header);
    }
    List<String> out = new ArrayList<>();
    out.add("::: {.derived label=\"" + table.label + "\"}");
    out.add("| " + String.join(" | ", headers) + " |");
    out.add("| " + String.join(" | ", Collections.nCopies(headers.size(), "---")) + " |");
    for (List<String> r : rows) {
      out.add("| " + String.join(" | ", r) + " |");
    }
    out.add(":::");
    return out;
  }

  /**
   * The element a row names: itself, or its nearest owner of the table's
   * owner classes ({@code null}: none).
   */
  private String rowOwner(String item, Table table) {
    if (table.owner.isEmpty()) {
      return item;
    }
    String p = item;
    while (p.contains("/")) {
      p = p.substring(0, p.lastIndexOf('/'));
      if (nav.itemParts(p) != null) {
        String id = classId(p);
        if (id != null && !id.isEmpty() && table.owner.contains(id)) {
          return p;
        }
      }
    }
    return null;
  }

  /** A link to the element at {@code item} by its id and anchor. */
  private String idCell(String item) {
    if (item == null) {
      return "";
    }
    SpecDocumentMarkdownLinked.Walk w = nav.walk(item, null, nav.doc(), null);
    return "[" + w.headingId + "](#" + w.anchor + ")";
  }

  // --- the block as text -----------------------------------------------------

  private static final Pattern OPENS_DERIVED = Pattern.compile("^ {0,3}:{3,}[ \\t]*\\{\\.derived[\\s}]");
  private static final Pattern DERIVED_FENCE = Pattern.compile("^ {0,3}(:{3,})");

  /** Whether {@code line} opens a {@code derived} block. */
  static boolean opensDerived(String line) {
    return OPENS_DERIVED.matcher(line).find();
  }

  /** The closing line pattern of the {@code derived} block {@code line} opens. */
  static Pattern derivedFenceClose(String line) {
    Matcher m = DERIVED_FENCE.matcher(line);
    int n = m.find() ? m.group(1).length() : 3;
    return Pattern.compile("^ {0,3}:{" + n + ",}[ \\t]*$");
  }

  /**
   * {@code markdown} with every derived placeholder resolved: an empty
   * {@code derived} block where the block after it opens a {@code derived}
   * block, else removed with its blank line.
   */
  static String resolveDerivedPlaceholders(String markdown) {
    if (!markdown.contains(DERIVED_PLACEHOLDER)) {
      return markdown;
    }
    String[] lines = markdown.split("\n", -1);
    List<String> out = new ArrayList<>(lines.length);
    for (int i = 0; i < lines.length; ) {
      if (!lines[i].equals(DERIVED_PLACEHOLDER)) {
        out.add(lines[i]);
        i++;
        continue;
      }
      int k = i + 1;
      while (k < lines.length && lines[k].trim().isEmpty()) {
        k++;
      }
      if (k < lines.length && opensDerived(lines[k])) {
        out.add("::: {.derived}");
        out.add(":::");
        i++;
      } else {
        i += 2; // the blank line after the placeholder goes with it
      }
    }
    return String.join("\n", out);
  }
}
