package tom_som_runtime;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * A never-fail-fast validator of a parsed DocSpecs document against a schema —
 * a faithful port of the Go {@code DocSpecsValidator} (Dart / JavaScript / TypeScript parity
 * chain). Violation messages are byte-identical to the Dart implementation.
 */
public final class DocSpecsValidator {
  private static final Pattern FIELD_LABEL =
      Pattern.compile("^([A-Za-z][A-Za-z0-9_]*): ?(.*)$");

  public final DocSpecsSchema schema;

  public DocSpecsValidator(DocSpecsSchema schema) {
    this.schema = schema;
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
    validateDocumentSections(root, v);
    return v;
  }

  private DocSpecsSectionType resolveChild(DocSpecsSection section, List<DocSpecsViolation> v) {
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

  private void validateDocumentSections(DocSpecsSection root, List<DocSpecsViolation> v) {
    // Occurrences per section-type name.
    Map<String, Integer> counts = new HashMap<>();
    Set<String> slotTypes = new HashSet<>();
    for (DocSpecsDocumentSection slot : schema.documentSections.values()) {
      slotTypes.add(slot.sectionType);
    }
    for (DocSpecsSection child : root.children) {
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

  private void validateSection(
      DocSpecsSection section, DocSpecsSectionType t, List<DocSpecsViolation> v) {
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
    validateText(section, t, v);
    validateFormat(section, t, v);
    // Occurrences per subsection type name.
    Map<String, Integer> counts = new HashMap<>();
    for (DocSpecsSection child : section.children) {
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

  private void validateText(
      DocSpecsSection section, DocSpecsSectionType t, List<DocSpecsViolation> v) {
    if (t.format != null && schema.formTypes.containsKey(t.format)) {
      return; // form sections carry fields, not body text.
    }
    String text = section.text();
    if (t.textRequired && text.isEmpty()) {
      v.add(
          new DocSpecsViolation(
              DocSpecsViolation.RULE_TEXT_REQUIRED,
              section.line,
              "section requires body text but has none",
              section.id));
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

  private void validateFormat(
      DocSpecsSection section, DocSpecsSectionType t, List<DocSpecsViolation> v) {
    String format = t.format;
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
    for (String raw : section.bodyLines) {
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

  private void validateForm(
      DocSpecsSection section, DocSpecsFormType form, List<DocSpecsViolation> v) {
    // Lowered name → field.
    Map<String, DocSpecsFormField> byLower = new HashMap<>();
    for (DocSpecsFormField f : form.fields) {
      byLower.put(f.name.toLowerCase(Locale.ROOT), f);
    }
    // Field name → collected value lines.
    Map<String, List<String>> values = new LinkedHashMap<>();
    // Field name → 1-based label line.
    Map<String, Integer> fieldLines = new HashMap<>();
    MarkdownFenceTracker fence = new MarkdownFenceTracker();
    String current = null;
    for (int i = 0; i < section.bodyLines.size(); i++) {
      String raw = section.bodyLines.get(i);
      if (!fence.inFence()) {
        Matcher m = FIELD_LABEL.matcher(raw);
        if (m.matches()) {
          DocSpecsFormField field = byLower.get(m.group(1).toLowerCase(Locale.ROOT));
          if (field != null) {
            current = field.name;
            List<String> collected = new ArrayList<>();
            collected.add(m.group(2));
            values.put(current, collected);
            fieldLines.put(current, section.bodyStartLine() + i);
            fence.feed(raw);
            continue;
          }
        }
      }
      if (current != null) {
        values.get(current).add(raw);
      }
      fence.feed(raw);
    }
    for (DocSpecsFormField field : form.fields) {
      String value = "";
      List<String> collected = values.get(field.name);
      if (collected != null) {
        value = String.join("\n", collected).trim();
      }
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

  /**
   * Lands a DocSpecs markdown text in a typed {@link SpecDocument} via the SOM
   * markdown codec — the "bind" entry point (SOM §14).
   */
  public static SpecMarkdownResult bindDocspecsMarkdown(
      SpecModel model, SpecDocument document, String text) {
    return new SpecDocumentMarkdown(model, document).parse(text);
  }
}
