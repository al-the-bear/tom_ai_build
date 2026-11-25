package tom_som_runtime;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.function.Predicate;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A never-fail-fast validator of a parsed DocSpecs document against a schema —
 * a faithful port of the Go {@code DocSpecsValidator} (Dart / JavaScript / TypeScript parity
 * chain). Violation messages are byte-identical to the Dart implementation.
 *
 * <p>It reads the reading view beside the {@code Field:} layout (DocSpecs
 * specification, List Bodies): form tables, {@code refs} lines and
 * {@code records} tables as a list's virtual items, section tables at their
 * rows, and the styled-div headings {@link DocSpecsDocument} parses.
 */
public final class DocSpecsValidator {
  private static final Pattern FIELD_LABEL =
      Pattern.compile("^([A-Za-z][A-Za-z0-9_]*): ?(.*)$");
  // A line that starts a table row: `|` after up to three spaces.
  private static final Pattern TABLE_LINE = Pattern.compile("^ {0,3}\\|");
  private static final Pattern DELIMITER_CELL = Pattern.compile("^:?-+:?$");
  private static final Pattern LINK_CELL =
      Pattern.compile("^\\[[^\\]]+\\]\\([^)]*\\)(, \\[[^\\]]+\\]\\([^)]*\\))*$");
  private static final Pattern LINK_TEXT = Pattern.compile("\\[([^\\]]+)\\]\\([^)]*\\)");
  private static final Pattern CELL_ANCHOR = Pattern.compile("<a id=\"([^\"]*)\"></a>\\s*");
  private static final Pattern CELL_PART_SEPARATOR = Pattern.compile("\\s*/\\s*");
  private static final Pattern CELL_LINK = Pattern.compile("\\[([^\\]]+)\\]\\([^)\\s]*\\)");
  private static final Pattern LIST_DIV_OPEN =
      Pattern.compile("^:{3,}\\s*(?:\\{\\.(refs|records)\\}|(refs|records))\\s*$");
  private static final Pattern DIV_CLOSE = Pattern.compile("^:{3,}\\s*$");
  private static final Pattern REF_SEPARATOR = Pattern.compile("[,\\s]+");
  private static final Pattern LINKED_PARAGRAPH = Pattern.compile("^\\[.*\\]\\{\\.linked\\}$");
  private static final Pattern DERIVED_OPEN =
      Pattern.compile("^ {0,3}(:{3,})[ \\t]*\\{\\.derived(?=[\\s}])");

  public final DocSpecsSchema schema;

  /**
   * Whether the documents are TomSpecs renditions: the reading notation is
   * then scanned value by value (a form field's value apart from the next),
   * and a div without a class and an unregistered kind are reported too.
   */
  public final boolean tomSpecs;

  public DocSpecsValidator(DocSpecsSchema schema) {
    this(schema, false);
  }

  /**
   * A validator for {@code schema}; {@code tomSpecs}: the documents are
   * TomSpecs renditions ({@link #tomSpecs}).
   */
  public DocSpecsValidator(DocSpecsSchema schema, boolean tomSpecs) {
    this.schema = schema;
    this.tomSpecs = tomSpecs;
  }

  /** Parses + validates in one step. */
  public List<DocSpecsViolation> validateMarkdown(String markdown) {
    return validate(DocSpecsDocument.parse(markdown));
  }

  /** Validates a parsed document, returning ALL findings (never fail-fast). */
  public List<DocSpecsViolation> validate(DocSpecsDocument doc) {
    List<DocSpecsViolation> v = new ArrayList<>(doc.violations);
    if (doc.sections.isEmpty()) {
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_FORMAT_MISMATCH, 1, "document has no root heading"));
      return v;
    }
    DocSpecsSection root = doc.sections.get(0);
    String rootId = schema.rootSectionId();
    if (rootId != null && !rootId.equals(root.id)) {
      String rootIdStr = root.id == null ? "" : root.id;
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_FORMAT_MISMATCH,
              root.line,
              "root heading id \""
                  + rootIdStr
                  + "\" does not match the schema title-format id \""
                  + rootId
                  + "\"",
              root.id));
    }
    for (int i = 1; i < doc.sections.size(); i++) {
      DocSpecsSection extra = doc.sections.get(i);
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_UNKNOWN_SECTION,
              extra.line,
              "unexpected additional top-level section",
              extra.id));
    }
    validateDocumentSections(Node.of(root), v);
    validateNotation(doc, v);
    validateIdPaths(doc.sections, v);
    return v;
  }

  /**
   * The reading notation of every section's own body (DocSpecs specification,
   * Reading Notation RN-10): one value per section, and in a TomSpecs rendition
   * one per form field of a form-formatted section (its preamble included).
   */
  private void validateNotation(DocSpecsDocument doc, List<DocSpecsViolation> v) {
    for (DocSpecsSection section : doc.allSections()) {
      List<String> body = section.bodyLines;
      for (int[] value : notationValues(section)) {
        String text = String.join("\n", body.subList(value[0], value[1]));
        for (NotationFinding f : SpecNotation.scanNotation(text, tomSpecs).findings) {
          v.add(
              new DocSpecsViolation(
                  f.code.value,
                  section.bodyStartLine() + value[0] + f.line - 1,
                  f.message,
                  section.id));
        }
      }
    }
  }

  /** The values of a section's own body, each as {@code [first line, end line)} of its body. */
  private List<int[]> notationValues(DocSpecsSection section) {
    List<String> body = section.bodyLines;
    List<int[]> values = new ArrayList<>();
    DocSpecsSectionType type =
        tomSpecs && section.id != null ? schema.resolveSectionType(section.id) : null;
    DocSpecsFormType form =
        type != null && type.format != null ? schema.formTypes.get(type.format) : null;
    if (form == null) {
      values.add(new int[] {0, body.size()});
      return values;
    }
    Set<String> labels = new HashSet<>();
    for (DocSpecsFormField f : form.fields) {
      labels.add(f.name.toLowerCase(Locale.ROOT));
    }
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    int first = 0;
    for (int i = 0; i < body.size(); i++) {
      if (!fence.inFence() && i > first) {
        Matcher m = FIELD_LABEL.matcher(body.get(i));
        if (m.matches() && labels.contains(m.group(1).toLowerCase(Locale.ROOT))) {
          values.add(new int[] {first, i});
          first = i;
        }
      }
      fence.feed(body.get(i));
    }
    values.add(new int[] {first, body.size()});
    return values;
  }

  /**
   * Every section's id path (the ids from the root down to it) is unique: a
   * section whose id repeats an earlier sibling's is a {@code duplicateIdPath}.
   * Its descendants repeat paths only through it and are not reported again.
   * Sections without an id are skipped (already {@code malformedHeading}).
   * Depth-first, source order.
   */
  private void validateIdPaths(List<DocSpecsSection> sections, List<DocSpecsViolation> v) {
    Set<String> seen = new HashSet<>();
    for (DocSpecsSection s : sections) {
      if (s.id != null) {
        if (seen.contains(s.id)) {
          v.add(
              new DocSpecsViolation(
                  DocSpecsViolation.RULE_DUPLICATE_ID_PATH,
                  s.line,
                  "section id \""
                      + s.id
                      + "\" repeats a sibling's id, so its id path is not unique",
                  s.id));
          continue;
        }
        seen.add(s.id);
      }
      validateIdPaths(s.children, v);
    }
  }

  private DocSpecsSectionType resolveChild(Node section, List<DocSpecsViolation> v) {
    if (section.type != null) {
      return section.type; // a virtual list item: the schema's type.
    }
    if (section.id == null) {
      return null; // already reported as MALFORMED_HEADING by the parse.
    }
    DocSpecsSectionType t = schema.resolveSectionType(section.id);
    if (t == null) {
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_UNKNOWN_SECTION,
              section.line,
              "section id \"" + section.id + "\" resolves to no section-type of the schema",
              section.id));
    }
    return t;
  }

  /**
   * Root children must occupy {@code document: sections:} slots, in their
   * order (a {@code position: any} slot's type stands anywhere); required
   * slots must be present. A section table in the root's body rebuilds root
   * children as virtual sections first.
   */
  private void validateDocumentSections(Node root, List<DocSpecsViolation> v) {
    // Occurrences per section-type name.
    Map<String, Integer> counts = new HashMap<>();
    Set<String> slotTypes = new HashSet<>();
    // Slot types that may stand anywhere, and the slot order (null for an
    // any-position slot) the order check reads.
    Set<String> anywhere = new HashSet<>();
    List<String> order = new ArrayList<>();
    for (DocSpecsDocumentSection slot : schema.documentSections.values()) {
      slotTypes.add(slot.sectionType);
      if (slot.anyPosition()) {
        anywhere.add(slot.sectionType);
      }
      order.add(slot.anyPosition() ? null : slot.sectionType);
    }
    expandSectionTables(root, t -> slotTypes.contains(t.name), v);
    int lastIndex = -1;
    for (Node child : root.children) {
      DocSpecsSectionType t = resolveChild(child, v);
      if (t == null) {
        continue;
      }
      if (!slotTypes.contains(t.name)) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_UNKNOWN_SECTION,
                child.line,
                "section-type \"" + t.name + "\" is not a top-level document section",
                child.id));
        continue;
      }
      if (!anywhere.contains(t.name)) {
        lastIndex = checkOrder(child, t.name, order, lastIndex, v);
      }
      counts.merge(t.name, 1, Integer::sum);
      validateSection(child, t, v);
    }
    for (Map.Entry<String, DocSpecsDocumentSection> entry : schema.documentSections.entrySet()) {
      String slotKey = entry.getKey();
      DocSpecsDocumentSection slot = entry.getValue();
      if (!slot.optional && counts.getOrDefault(slot.sectionType, 0) == 0) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_MISSING_REQUIRED_SECTION,
                root.line,
                "required document section \""
                    + slotKey
                    + "\" (type \""
                    + slot.sectionType
                    + "\") is missing",
                slotKey));
      }
    }
  }

  /**
   * The order check of one root child: its slot is the first of its type at or
   * after the last slot taken, else the first of its type anywhere; a slot
   * before the last one taken is {@code sectionOutOfOrder}. Answers the last
   * slot taken afterwards.
   */
  private static int checkOrder(
      Node child, String typeName, List<String> order, int lastIndex, List<DocSpecsViolation> v) {
    int index = -1;
    for (int i = Math.max(lastIndex, 0); i < order.size(); i++) {
      if (typeName.equals(order.get(i))) {
        index = i;
        break;
      }
    }
    if (index == -1) {
      index = order.indexOf(typeName);
    }
    if (index == -1) {
      return lastIndex;
    }
    if (index < lastIndex) {
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_SECTION_OUT_OF_ORDER,
              child.line,
              "section \""
                  + child.id
                  + "\" (type \""
                  + typeName
                  + "\") stands out of the order of the document sections",
              child.id));
      return lastIndex;
    }
    return index;
  }

  private void validateSection(Node section, DocSpecsSectionType t, List<DocSpecsViolation> v) {
    DocSpecsPatternCheck pc = t.patternCheck;
    if (pc != null && section.id != null && !pc.matches(section.id)) {
      String message = pc.errorMessage;
      if (message == null || message.isEmpty()) {
        message =
            "section id \"" + section.id + "\" does not match pattern \"" + pc.pattern + "\"";
      }
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_ID_PATTERN_MISMATCH, section.line, message, section.id));
    }
    // List bodies and section tables become virtual sections before anything
    // is counted or checked (DocSpecs specification, List Bodies).
    expandSectionTables(section, x -> t.subsectionTypes.containsKey(x.name), v);
    expandListBody(section, t, v);
    validateText(section, t, v);
    validateFormat(section, t, v);
    // Occurrences per subsection type name.
    Map<String, Integer> counts = new HashMap<>();
    for (Node child : section.children) {
      DocSpecsSectionType childType = resolveChild(child, v);
      if (childType == null) {
        continue;
      }
      if (!t.subsectionTypes.containsKey(childType.name)) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_UNKNOWN_SECTION,
                child.line,
                "section-type \""
                    + childType.name
                    + "\" is not an allowed subsection of \""
                    + t.name
                    + "\"",
                child.id));
        continue;
      }
      counts.merge(childType.name, 1, Integer::sum);
      validateSection(child, childType, v);
    }
    // The offending section is the CONTAINER, not the absent child: a
    // cardinality breach has no child occurrence to point at, and `subKey` is a
    // schema type name, not a section id. Dart is the golden reference here.
    for (Map.Entry<String, DocSpecsSubsectionRule> entry : t.subsectionTypes.entrySet()) {
      String subKey = entry.getKey();
      DocSpecsSubsectionRule rule = entry.getValue();
      int count = counts.getOrDefault(subKey, 0);
      if (count < rule.minCount) {
        if (count == 0) {
          v.add(
              new DocSpecsViolation(
                  DocSpecsViolation.RULE_MISSING_REQUIRED_SECTION,
                  section.line,
                  "required subsection \"" + subKey + "\" of \"" + t.name + "\" is missing",
                  section.id));
        } else {
          v.add(
              new DocSpecsViolation(
                  DocSpecsViolation.RULE_TOO_FEW_ITEMS,
                  section.line,
                  "subsection \""
                      + subKey
                      + "\" occurs "
                      + count
                      + " time(s), minimum is "
                      + rule.minCount,
                  section.id));
        }
      }
      if (rule.maxCount != null && count > rule.maxCount) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_TOO_MANY_ITEMS,
                section.line,
                "subsection \""
                    + subKey
                    + "\" occurs "
                    + count
                    + " time(s), maximum is "
                    + rule.maxCount,
                section.id));
      }
    }
  }

  private void validateText(Node section, DocSpecsSectionType t, List<DocSpecsViolation> v) {
    if (t.format != null && schema.formTypes.containsKey(t.format)) {
      return; // form sections carry fields, not body text.
    }
    // A list body or section table already read is blanked in the body, so a
    // container written with one counts as empty (`max-text-length: 0`); the
    // rendition's marker and generated block are no text either.
    String text = withoutGeneratedText(section.text());
    if (t.textRequired && text.isEmpty()) {
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_TEXT_REQUIRED,
              section.line,
              "section requires body text but has none",
              section.id));
      return;
    }
    if (text.isEmpty()) {
      return;
    }
    int length = text.codePointCount(0, text.length());
    Integer minLen = t.minTextLength;
    Integer maxLen = t.maxTextLength;
    if ((minLen != null && length < minLen) || (maxLen != null && length > maxLen)) {
      String minStr = minLen != null ? String.valueOf(minLen) : "0";
      String maxStr = maxLen != null ? String.valueOf(maxLen) : "∞";
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_TEXT_LENGTH_OUT,
              section.line,
              "body text length " + length + " is outside [" + minStr + ", " + maxStr + "]",
              section.id));
    }
  }

  private void validateFormat(Node section, DocSpecsSectionType t, List<DocSpecsViolation> v) {
    String format = t.format;
    // Values a section table or list body gave a section the schema declares
    // no form for are virtual body lines, counted in its text (Node.text).
    if (format == null || format.isEmpty()) {
      return;
    }
    DocSpecsFormType form = schema.formTypes.get(format);
    if (form != null) {
      validateForm(section, form, v);
      return;
    }
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    boolean sawFence = false;
    for (String raw : section.body) {
      fence.feed(raw);
      if (fence.inFence()) {
        sawFence = true;
      }
    }
    if (!sawFence) {
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_FORMAT_MISMATCH,
              section.line,
              "section format \""
                  + format
                  + "\" demands a fenced code block, but the body contains none",
              section.id));
    }
  }

  /**
   * Parses the section body in the DocSpecs plain-text form format
   * ({@code FieldName: value}, case-insensitive labels, continuation lines)
   * and its form tables ({@code TomSpecField | Value}), takes the values a
   * section table or list body gave the section, and checks required fields
   * and field pattern-checks. A field given twice keeps its first occurrence
   * and reports the second ({@code malformedBlock}): a {@code Field:} label
   * counts as given even with an empty value, a row only with a value. A row
   * naming no field is {@code unknownField}.
   */
  private void validateForm(Node section, DocSpecsFormType form, List<DocSpecsViolation> v) {
    // Lowered name → field.
    Map<String, DocSpecsFormField> byLower = new HashMap<>();
    for (DocSpecsFormField f : form.fields) {
      byLower.put(f.name.toLowerCase(Locale.ROOT), f);
    }
    // Every occurrence of a field, from a `Field:` label or a row.
    List<FieldValue> occurrences = new ArrayList<>();
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    List<String> body = section.body;
    String current = null;
    int currentLine = 0;
    List<String> currentLines = new ArrayList<>();
    for (int i = 0; i < body.size(); i++) {
      String raw = body.get(i);
      if (!fence.inFence()) {
        Matcher header = SpecDocumentMarkdown.LAYOUT_TABLE_HEADER.matcher(raw);
        if (header.matches() && header.group(1) == null) {
          // A form table ends the open field; its rows are fields.
          if (current != null) {
            occurrences.add(
                new FieldValue(current, String.join("\n", currentLines).trim(), currentLine, true));
            current = null;
          }
          Table table = readTable(body, i, section.bodyStartLine(), section.id, v);
          for (TableRow row : table.rows) {
            occurrences.add(
                new FieldValue(
                    row.cells.get(0),
                    cellValue(row.cells.get(1)),
                    section.bodyStartLine() + row.index,
                    false));
          }
          i = table.end - 1;
          continue;
        }
        Matcher m = FIELD_LABEL.matcher(raw);
        if (m.matches()) {
          DocSpecsFormField field = byLower.get(m.group(1).toLowerCase(Locale.ROOT));
          if (field != null) {
            if (current != null) {
              occurrences.add(
                  new FieldValue(
                      current, String.join("\n", currentLines).trim(), currentLine, true));
            }
            current = field.name;
            currentLine = section.bodyStartLine() + i;
            currentLines = new ArrayList<>();
            currentLines.add(m.group(2));
            fence.feed(raw);
            continue;
          }
        }
      }
      if (current != null) {
        currentLines.add(raw);
      }
      fence.feed(raw);
    }
    if (current != null) {
      occurrences.add(
          new FieldValue(current, String.join("\n", currentLines).trim(), currentLine, true));
    }
    occurrences.addAll(section.values);
    // Source order decides which occurrence is the first; values from a
    // parent's section table stand above the section's own body. The sort is
    // stable, so occurrences of one line keep their order.
    occurrences.sort(Comparator.comparingInt(o -> o.line));

    // Field name → value, and → 1-based line of the occurrence kept.
    Map<String, String> values = new HashMap<>();
    Map<String, Integer> fieldLines = new HashMap<>();
    Set<String> given = new HashSet<>();
    for (FieldValue o : occurrences) {
      DocSpecsFormField field = byLower.get(o.label.toLowerCase(Locale.ROOT));
      if (field == null) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_UNKNOWN_FIELD,
                o.line,
                "row \"" + o.label + "\" names no field of \"" + form.name + "\"",
                section.id));
        continue;
      }
      if (!o.fromLabel && o.value.isEmpty()) {
        continue;
      }
      if (!given.add(field.name)) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_MALFORMED_BLOCK,
                o.line,
                "field \"" + field.name + "\" given twice",
                section.id));
        continue;
      }
      fieldLines.put(field.name, o.line);
      if (!o.value.isEmpty()) {
        values.put(field.name, o.value);
      }
    }
    for (DocSpecsFormField field : form.fields) {
      String value = values.getOrDefault(field.name, "");
      if (field.required && value.isEmpty()) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_MISSING_REQUIRED_FIELD,
                section.line,
                "required form field \""
                    + field.name
                    + "\" of \""
                    + form.name
                    + "\" is missing",
                section.id));
        continue;
      }
      DocSpecsPatternCheck pc = field.patternCheck;
      if (pc != null && !value.isEmpty() && !pc.matches(value)) {
        int line = fieldLines.getOrDefault(field.name, section.line);
        String message = pc.errorMessage;
        if (message == null || message.isEmpty()) {
          message =
              "form field \"" + field.name + "\" does not match pattern \"" + pc.pattern + "\"";
        }
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_FIELD_PATTERN_MISMATCH, line, message, section.id));
      }
    }
  }

  // --- Tables and list bodies (DocSpecs specification, List Bodies) ----------

  /**
   * Reads the table whose header is {@code lines[start]}: the header cells,
   * the body rows with their line indexes, and the index after the table;
   * {@code firstLine} is the 1-based document line of {@code lines[0]}. A
   * missing or mismatched delimiter row is a {@code malformedBlock} at the
   * header and the table yields no rows; a row of another cell count is a
   * {@code malformedBlock} at that row and is left out.
   */
  private static Table readTable(
      List<String> lines, int start, int firstLine, String sectionId, List<DocSpecsViolation> v) {
    int end = start + 1;
    while (end < lines.size() && TABLE_LINE.matcher(lines.get(end)).find()) {
      end++;
    }
    List<String> header = rowCells(lines.get(start));
    List<String> delimiter = start + 1 < end ? rowCells(lines.get(start + 1)) : null;
    boolean delimiterOk = delimiter != null;
    if (delimiterOk) {
      for (String c : delimiter) {
        if (!DELIMITER_CELL.matcher(c).matches()) {
          delimiterOk = false;
          break;
        }
      }
    }
    Table table = new Table(header, end);
    if (!delimiterOk || delimiter.size() != header.size()) {
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_MALFORMED_BLOCK,
              firstLine + start,
              delimiterOk
                  ? "table whose delimiter row does not match its header"
                  : "table without its delimiter row",
              sectionId));
      return table;
    }
    for (int i = start + 2; i < end; i++) {
      List<String> cells = rowCells(lines.get(i));
      if (cells.size() != header.size()) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_MALFORMED_BLOCK,
                firstLine + i,
                "table row with " + cells.size() + " cells, the header has " + header.size(),
                sectionId));
        continue;
      }
      table.rows.add(new TableRow(i, cells));
    }
    return table;
  }

  /**
   * Reads every section table of {@code node}'s body (header
   * {@code Section | TomSpecField | Value}): each row's {@code Section} cell
   * names a child — by its id relative to {@code node}, a list item as
   * {@code <LIST> / <ITEM>}, an empty cell the row above's — and its
   * {@code TomSpecField} / {@code Value} cells become that child's form
   * values. A child without a heading becomes a virtual section; one whose id
   * resolves to no type {@code allowed} under {@code node} is
   * {@code unknownSection} at the row, and its rows are skipped. The table's
   * lines are blanked.
   */
  private void expandSectionTables(
      Node node, Predicate<DocSpecsSectionType> allowed, List<DocSpecsViolation> v) {
    List<String> body = node.body;
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    int firstLine = node.bodyStartLine();
    for (int i = 0; i < body.size(); i++) {
      String line = body.get(i);
      Matcher h = fence.inFence() ? null : SpecDocumentMarkdown.LAYOUT_TABLE_HEADER.matcher(line);
      if (h == null || !h.matches() || h.group(1) == null) {
        fence.feed(line);
        continue;
      }
      Table table = readTable(body, i, firstLine, node.id, v);
      Node target = null;
      boolean skip = false;
      for (TableRow row : table.rows) {
        int at = firstLine + row.index;
        String cell = cellId(row.cells.get(0));
        if (!cell.isEmpty()) {
          target = sectionTableTarget(node, cell, allowed, at);
          skip = target == null;
          if (target == null) {
            v.add(
                new DocSpecsViolation(
                    DocSpecsViolation.RULE_UNKNOWN_SECTION,
                    at,
                    "section-table row names no child section of \"" + node.id + "\"",
                    cell));
            continue;
          }
        } else if (skip) {
          continue; // the rejected child's further rows
        } else if (target == null) {
          v.add(
              new DocSpecsViolation(
                  DocSpecsViolation.RULE_UNKNOWN_SECTION,
                  at,
                  "section-table row names no section",
                  node.id));
          continue;
        }
        target.values.add(
            new FieldValue(row.cells.get(1), cellValue(row.cells.get(2)), at, false));
      }
      for (int k = i; k < table.end; k++) {
        body.set(k, "");
      }
      i = table.end - 1;
    }
  }

  /**
   * The child a section-table {@code Section} cell names under {@code node}: a
   * child section by its id, or {@code <LIST> / <ITEM>} — an item of a child
   * list. A child or item without a heading is created as a virtual section
   * when its id resolves to a type allowed where it stands; {@code null}
   * otherwise.
   */
  private Node sectionTableTarget(
      Node node, String cell, Predicate<DocSpecsSectionType> allowed, int line) {
    String[] parts = CELL_PART_SEPARATOR.split(cell, -1);
    if (parts.length > 2) {
      return null;
    }
    Node first = tableChild(node, parts[0], allowed, line);
    if (parts.length == 1 || first == null) {
      return first;
    }
    DocSpecsSectionType listType =
        first.type != null ? first.type : schema.resolveSectionType(parts[0]);
    if (listType == null) {
      return null;
    }
    return tableChild(first, parts[1], t -> listType.subsectionTypes.containsKey(t.name), line);
  }

  /**
   * The child of {@code parent} with {@code id}, created virtual when
   * {@code ok} allows its type.
   */
  private Node tableChild(Node parent, String id, Predicate<DocSpecsSectionType> ok, int line) {
    for (Node c : parent.children) {
      if (id.equals(c.id)) {
        return c;
      }
    }
    DocSpecsSectionType t = schema.resolveSectionType(id);
    if (t == null || !ok.test(t)) {
      return null;
    }
    Node created = new Node(id, line, new ArrayList<>(), null);
    parent.children.add(created);
    return created;
  }

  private static void malformed(Node node, int line, String message, List<DocSpecsViolation> v) {
    v.add(new DocSpecsViolation(DocSpecsViolation.RULE_MALFORMED_BLOCK, line, message, node.id));
  }

  /**
   * A list container's body: one {@code refs} div (a reference line) or one
   * {@code records} div (a record table) stands for its items when the
   * container has no item heading; the items become virtual sections of the
   * container's one subsection type, and the div's lines are blanked.
   */
  private void expandListBody(Node node, DocSpecsSectionType type, List<DocSpecsViolation> v) {
    List<String> body = node.body;
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    for (int i = 0; i < body.size(); i++) {
      String line = body.get(i);
      Matcher open = fence.inFence() ? null : LIST_DIV_OPEN.matcher(line);
      if (open == null || !open.matches()) {
        fence.feed(line);
        continue;
      }
      String kind = open.group(1) != null ? open.group(1) : open.group(2);
      int at = node.bodyStartLine() + i;
      int close = -1;
      for (int k = i + 1; k < body.size(); k++) {
        if (DIV_CLOSE.matcher(body.get(k)).matches()) {
          close = k;
          break;
        }
      }
      if (close < 0) {
        malformed(node, at, "unclosed " + kind + " fence", v); // its lines stay text
        return;
      }
      int lead = generatedLead(body);
      boolean besideText = false;
      for (int k = lead; k < body.size(); k++) {
        if ((k < i || k > close) && !body.get(k).trim().isEmpty()) {
          besideText = true;
          break;
        }
      }
      boolean hasItems = !node.children.isEmpty();
      List<String> inner = new ArrayList<>(body.subList(i + 1, close));
      for (int k = i; k <= close; k++) {
        body.set(k, "");
      }
      if (besideText || hasItems) {
        malformed(
            node,
            at,
            "a "
                + kind
                + " div beside "
                + (hasItems ? "item headings" : "other text")
                + " in a list container",
            v);
        return;
      }
      DocSpecsSectionType itemType =
          type.subsectionTypes.size() == 1
              ? schema.sectionTypesByName.get(type.subsectionTypes.keySet().iterator().next())
              : null;
      if (itemType == null) {
        malformed(node, at, "a " + kind + " div in a section that is not a list container", v);
        return;
      }
      if ("refs".equals(kind)) {
        refsItems(node, itemType, inner, at);
      } else {
        recordItems(node, itemType, inner, at, v);
      }
      return;
    }
  }

  private DocSpecsFormType formOf(DocSpecsSectionType t) {
    return t != null && t.format != null ? schema.formTypes.get(t.format) : null;
  }

  /**
   * The one-field form a {@code refs} item of {@code itemType} holds its
   * reference in: the type's own form, else the form of its one subsection
   * type that has one (the item's virtual child then carries the value);
   * {@code null} when the schema gives none. A record table reads the type's
   * own form only ({@link #recordItems}).
   */
  private FormTarget refsForm(DocSpecsSectionType itemType) {
    DocSpecsFormType own = formOf(itemType);
    if (own != null && own.fields.size() == 1) {
      return new FormTarget(own, null);
    }
    FormTarget found = null;
    for (String name : itemType.subsectionTypes.keySet()) {
      DocSpecsSectionType sub = schema.sectionTypesByName.get(name);
      DocSpecsFormType f = formOf(sub);
      if (f != null && f.fields.size() == 1) {
        if (found != null) {
          return null; // more than one candidate
        }
        found = new FormTarget(f, sub);
      }
    }
    return found;
  }

  /**
   * A virtual item of {@code itemType} with id {@code id} at {@code line},
   * added to {@code list}; returns the section its form values go to — the
   * item itself, or its virtual child of {@code childType} (id: the child
   * type's name upper-cased).
   */
  private static Node addItem(
      Node list, DocSpecsSectionType itemType, DocSpecsSectionType childType, String id, int line) {
    Node item = new Node(id, line, new ArrayList<>(), itemType);
    list.children.add(item);
    if (childType == null) {
      return item;
    }
    Node child =
        new Node(childType.name.toUpperCase(Locale.ROOT), line, new ArrayList<>(), childType);
    item.children.add(child);
    return child;
  }

  /**
   * A {@code refs} div: its text split on commas and whitespace into ids, a
   * link counting as its link text; item &lt;n&gt; gets the positional id (the
   * container's id with {@code -LST} replaced by {@code -<n>}, else
   * {@code <id>-<n>}) and the virtual body line {@code <Label>: <id>}.
   */
  private void refsItems(Node node, DocSpecsSectionType itemType, List<String> inner, int at) {
    // Without a one-field form in the schema the reference is the item's
    // virtual body line; nothing in the schema checks it further.
    FormTarget target = refsForm(itemType);
    String container = node.id == null ? "" : node.id;
    String stem =
        container.endsWith("-LST") ? container.substring(0, container.length() - 4) : container;
    int n = 0;
    for (String token : REF_SEPARATOR.split(String.join(" ", inner))) {
      if (token.isEmpty()) {
        continue;
      }
      n++;
      Matcher m = LINK_TEXT.matcher(token);
      String id = m.find() ? m.group(1) : token;
      Node holder =
          addItem(node, itemType, target != null ? target.child : null, stem + "-" + n, at);
      holder.values.add(
          new FieldValue(target != null ? target.form.fields.get(0).name : "", id, at, false));
    }
  }

  /**
   * A {@code records} div: one table, {@code Id} first, {@code Title}
   * optionally second, then field names of the item's form; each row one
   * virtual item in row order.
   */
  private void recordItems(
      Node node,
      DocSpecsSectionType itemType,
      List<String> inner,
      int at,
      List<DocSpecsViolation> v) {
    int start = -1;
    for (int k = 0; k < inner.size(); k++) {
      if (!inner.get(k).trim().isEmpty()) {
        start = k;
        break;
      }
    }
    if (start < 0 || !TABLE_LINE.matcher(inner.get(start)).find()) {
      malformed(node, at, "a records div holding no table", v);
      return;
    }
    List<String> header = rowCells(inner.get(start));
    if (!"Id".equals(header.get(0))) {
      malformed(node, at, "a records table whose first column is not Id", v);
      return;
    }
    // The item type's own form decides the columns; an item type the schema
    // gives no form of its own takes its columns as virtual body lines
    // unchecked. A record's cells are the item's own body lines (DocSpecs
    // specification, The record table): unlike a `refs` reference they never
    // go to a child's form.
    DocSpecsFormType own = formOf(itemType);
    int firstColumn = header.size() > 1 && "Title".equals(header.get(1)) ? 2 : 1;
    List<String> columns = new ArrayList<>();
    for (String label : header.subList(firstColumn, header.size())) {
      String name = own == null ? label : null;
      if (own != null) {
        for (DocSpecsFormField f : own.fields) {
          if (f.name.equalsIgnoreCase(label)) {
            name = f.name;
            break;
          }
        }
      }
      if (name == null) {
        v.add(
            new DocSpecsViolation(
                DocSpecsViolation.RULE_UNKNOWN_FIELD,
                at + 1 + start,
                "records column \"" + label + "\" names no field of the items",
                node.id));
        return;
      }
      columns.add(name);
    }
    Table table = readTable(inner, start, at + 1, node.id, v);
    for (TableRow row : table.rows) {
      int line = at + 1 + row.index;
      Node holder = addItem(node, itemType, null, cellId(row.cells.get(0)), line);
      for (int c = 0; c < columns.size(); c++) {
        String value = cellValue(row.cells.get(firstColumn + c));
        if (!value.isEmpty()) {
          holder.values.add(new FieldValue(columns.get(c), value, line, false));
        }
      }
    }
  }

  // --- Lines, cells and the walk's sections ---------------------------------

  /**
   * The number of leading lines of a section's {@code lines} that the
   * rendition writes from the document and that hold no value: a paragraph
   * that is one {@code linked} span (SOM §11.11), then a {@code derived} block
   * (SOM §11.12), with the blank lines around them (DocSpecs RN-5, Not text).
   */
  private static int generatedLead(List<String> lines) {
    int i = skipBlank(lines, 0);
    int end = i;
    while (end < lines.size() && !lines.get(end).trim().isEmpty()) {
      end++;
    }
    String para = String.join(" ", lines.subList(i, end)).trim();
    if (end > i && LINKED_PARAGRAPH.matcher(para).matches()) {
      i = skipBlank(lines, end);
    }
    Matcher open = i < lines.size() ? DERIVED_OPEN.matcher(lines.get(i)) : null;
    if (open != null && open.find()) {
      Pattern close = Pattern.compile("^ {0,3}:{" + open.group(1).length() + ",}[ \\t]*$");
      int k = i + 1;
      while (k < lines.size() && !close.matcher(lines.get(k)).matches()) {
        k++;
      }
      if (k < lines.size()) {
        i = skipBlank(lines, k + 1);
      }
    }
    return i;
  }

  private static int skipBlank(List<String> lines, int i) {
    while (i < lines.size() && lines.get(i).trim().isEmpty()) {
      i++;
    }
    return i;
  }

  /** {@code text} without its {@link #generatedLead}: what the text rules read. */
  private static String withoutGeneratedText(String text) {
    List<String> lines = Arrays.asList(text.split("\n", -1));
    return String.join("\n", lines.subList(generatedLead(lines), lines.size())).trim();
  }

  /**
   * The cells of a table row: split on every {@code |} not preceded by a
   * backslash, the outer pipes dropped, each cell trimmed; {@code \|} stays in
   * the cell.
   */
  private static List<String> rowCells(String line) {
    String t = line.trim();
    if (t.startsWith("|")) {
      t = t.substring(1);
    }
    if (t.endsWith("|") && !t.endsWith("\\|")) {
      t = t.substring(0, t.length() - 1);
    }
    List<String> cells = new ArrayList<>();
    StringBuilder b = new StringBuilder();
    for (int i = 0; i < t.length(); i++) {
      char c = t.charAt(i);
      if (c == '\\' && i + 1 < t.length() && t.charAt(i + 1) == '|') {
        b.append("\\|");
        i++;
      } else if (c == '|') {
        cells.add(b.toString().trim());
        b.setLength(0);
      } else {
        b.append(c);
      }
    }
    cells.add(b.toString().trim());
    return cells;
  }

  /** A value cell's value: {@code \|} unescaped, a cell of links read as their texts. */
  private static String cellValue(String cell) {
    String text = cell.replace("\\|", "|");
    if (!LINK_CELL.matcher(text).matches()) {
      return text;
    }
    List<String> texts = new ArrayList<>();
    Matcher m = LINK_TEXT.matcher(text);
    while (m.find()) {
      texts.add(m.group(1));
    }
    return String.join(", ", texts);
  }

  /**
   * An {@code Id} or {@code Section} cell with its own anchors
   * ({@code <a id="X"></a>X}) removed (Section Anchors): in a
   * {@code <LIST> / <ITEM>} cell each part's anchor, and one before the whole
   * cell naming its item. Any other anchor stays. An id written as a link is
   * read as its text (SOM §11.5).
   */
  private static String cellId(String cell) {
    String text = CELL_LINK.matcher(cell).replaceAll(r -> Matcher.quoteReplacement(r.group(1)));
    StringBuilder out = new StringBuilder();
    int pos = 0;
    Matcher m = CELL_ANCHOR.matcher(text);
    while (m.find()) {
      out.append(text, pos, m.start());
      String[] rest = CELL_PART_SEPARATOR.split(text.substring(m.end()), -1);
      boolean own =
          DocSpecsDocument.isOwnAnchor(m.group(1), rest[0].trim())
              || (m.start() == 0
                  && DocSpecsDocument.isOwnAnchor(m.group(1), rest[rest.length - 1].trim()));
      if (!own) {
        out.append(m.group());
      }
      pos = m.end();
    }
    return out.append(text.substring(pos)).toString();
  }

  /** One value of a form field: from a {@code Field:} label, a table row or a list body. */
  private static final class FieldValue {
    /** The field's label as written; empty for a reference no form names. */
    final String label;

    final String value;
    final int line;
    /** Whether a {@code Field:} label gave it (given even when empty). */
    final boolean fromLabel;

    FieldValue(String label, String value, int line, boolean fromLabel) {
      this.label = label;
      this.value = value;
      this.line = line;
      this.fromLabel = fromLabel;
    }
  }

  /** A body row of a table: its index in the lines read, and its cells. */
  private static final class TableRow {
    final int index;
    final List<String> cells;

    TableRow(int index, List<String> cells) {
      this.index = index;
      this.cells = cells;
    }
  }

  /** A table as read: its header cells, its well-formed rows, the index after it. */
  private static final class Table {
    final List<String> header;
    final List<TableRow> rows = new ArrayList<>();
    final int end;

    Table(List<String> header, int end) {
      this.header = header;
      this.end = end;
    }
  }

  /** The form a list item's value goes to, and the virtual child holding it (or none). */
  private static final class FormTarget {
    final DocSpecsFormType form;
    final DocSpecsSectionType child;

    FormTarget(DocSpecsFormType form, DocSpecsSectionType child) {
      this.form = form;
      this.child = child;
    }
  }

  /**
   * A section as the validator walks it: a parsed {@link DocSpecsSection}, or
   * a virtual one rebuilt from a list body or a section table (the DocSpecs
   * specification's List Bodies). The body is a copy, so blanking a table or
   * div never touches the parsed document.
   */
  private static final class Node {
    final String id;
    /** The heading's line, or the row's or div's line of a virtual section. */
    final int line;
    /** The own body lines; a list body or section table already read is blank. */
    final List<String> body;
    /** The section-type of a virtual list item, given by the schema. */
    final DocSpecsSectionType type;

    final List<Node> children = new ArrayList<>();
    /** Form values given by a table row or a list body. */
    final List<FieldValue> values = new ArrayList<>();

    Node(String id, int line, List<String> body, DocSpecsSectionType type) {
      this.id = id;
      this.line = line;
      this.body = body;
      this.type = type;
    }

    /** The walk's view of a parsed section and its subtree. */
    static Node of(DocSpecsSection s) {
      Node n = new Node(s.id, s.line, new ArrayList<>(s.bodyLines), null);
      for (DocSpecsSection c : s.children) {
        n.children.add(of(c));
      }
      return n;
    }

    int bodyStartLine() {
      return line + 1;
    }

    /**
     * The trimmed body text, after the virtual body lines of {@link #values} —
     * the text the same section has in the fields layout, where a section
     * without a form in the schema carries its values as {@code FieldName:}
     * lines.
     */
    String text() {
      List<String> lines = new ArrayList<>();
      for (FieldValue fv : values) {
        lines.add(fv.label.isEmpty() ? fv.value : fv.label + ": " + fv.value);
      }
      lines.addAll(body);
      int start = 0;
      int end = lines.size();
      while (start < end && lines.get(start).trim().isEmpty()) {
        start++;
      }
      while (end > start && lines.get(end - 1).trim().isEmpty()) {
        end--;
      }
      return String.join("\n", lines.subList(start, end));
    }
  }

  /**
   * Lands a DocSpecs markdown text in a typed {@link SpecDocument} via the SOM
   * markdown codec — the "bind" entry point (SOM §14).
   */
  public static SpecMarkdownResult bindDocspecsMarkdown(
      SpecModel model, SpecDocument document, String text) {
    return new SpecDocumentMarkdown(model, document).parse(text);
  }
}
