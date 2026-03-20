import 'dart:convert';

import 'package:tom_doc_scanner/src/models/section.dart';

import '../models/spec_doc.dart';
import '../models/spec_section.dart';

/// Expands `${...}` placeholders in validation prompts.
///
/// Replaces placeholders with values from the section, document, and parent.
///
/// ## Supported Placeholders
///
/// | Placeholder | Description |
/// |-------------|-------------|
/// | `${id}` | Section ID |
/// | `${text}` | Full section text content |
/// | `${text[fieldname]}` | Extract form field from text |
/// | `${text[]}` | Preamble text (before first field) |
/// | `${index}` | Zero-based index among siblings of same type |
/// | `${lineNumber}` | Line number in source file |
/// | `${type}` | Section type name from schema |
/// | `${tags}` | Comma-separated list of tags |
/// | `${fields}` | JSON object of field key-value pairs |
/// | `${fields.fieldName}` | Value of a specific field |
/// | `${parent.id}` | Parent section's ID |
/// | `${parent.text}` | Parent section's text content |
/// | `${parent.text[fieldname]}` | Extract form field from parent's text |
/// | `${parent.type}` | Parent section's type name |
/// | `${parent.fields}` | Parent section's fields as JSON |
/// | `${parent.fields.fieldName}` | Specific field from parent section |
class PromptExpander {
  static final _placeholderPattern = RegExp(r'\$\{([^}]+)\}');

  /// Expands all `${...}` placeholders in [prompt].
  ///
  /// - [section]: The section being validated
  /// - [document]: Complete document (used for parent resolution)
  String expand(
    String prompt, {
    required SpecSection section,
    required SpecDoc document,
  }) {
    return prompt.replaceAllMapped(_placeholderPattern, (match) {
      final key = match.group(1)!;
      return _resolve(key, section, document);
    });
  }

  String _resolve(String key, SpecSection section, SpecDoc document) {
    // Parent access
    if (key.startsWith('parent.')) {
      final parentKey = key.substring('parent.'.length);
      final parent = _findParent(section, document);
      if (parent == null) return '';
      return _resolveForSection(parentKey, parent);
    }

    return _resolveForSection(key, section);
  }

  String _resolveForSection(String key, Section section) {
    switch (key) {
      case 'id':
        return section.id;
      case 'text':
        return section.text;
      case 'index':
        return section.index.toString();
      case 'lineNumber':
        return section.lineNumber.toString();
      case 'type':
        return section is SpecSection ? (section.type ?? '') : '';
      case 'tags':
        return section is SpecSection ? section.tags.join(', ') : '';
      case 'fields':
        return jsonEncode(section.fields);
      default:
        // ${text[fieldname]} or ${text[]}
        if (key.startsWith('text[') && key.endsWith(']')) {
          final fieldName = key.substring(5, key.length - 1);
          if (section is SpecSection) {
            if (fieldName.isEmpty) {
              return section.preamble ?? '';
            }
            return section.getFormField(fieldName) ?? '';
          }
          return '';
        }

        // ${fields.fieldName}
        if (key.startsWith('fields.')) {
          final fieldName = key.substring('fields.'.length);
          return section.fields[fieldName] ?? '';
        }

        return '\${$key}';
    }
  }

  /// Finds the parent section of [target] in the document tree.
  SpecSection? _findParent(SpecSection target, SpecDoc document) {
    return _findParentInChildren(target, document.sections);
  }

  SpecSection? _findParentInChildren(
    SpecSection target,
    List<Section>? children,
  ) {
    if (children == null) return null;

    for (final child in children) {
      // Check if target is a direct child
      if (child.sections != null) {
        for (final grandchild in child.sections!) {
          if (identical(grandchild, target)) {
            return child is SpecSection ? child : null;
          }
        }
      }
      // Recurse
      final found = _findParentInChildren(target, child.sections);
      if (found != null) return found;
    }
    return null;
  }
}
