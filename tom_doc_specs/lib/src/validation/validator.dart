import 'package:tom_doc_scanner/src/models/document.dart';
import 'package:tom_doc_scanner/src/models/section.dart';
import '../models/schema/doc_spec_schema.dart';
import '../models/schema/document_structure.dart';
import '../models/schema/section_type_def.dart';
import '../models/spec_doc.dart';
import '../models/spec_section.dart';
import 'ai_validator.dart';
import 'prompt_expander.dart';
import 'validation_error.dart';

/// Main validation engine for DocSpecs documents.
///
/// Validates documents against their declared schemas, checking:
/// - Schema declaration
/// - Section type resolution
/// - Unique section IDs
/// - Required sections
/// - Section order
/// - Count limits
/// - Nesting depth
/// - Tag validation
/// - Text requirements
/// - Format validation
/// - For-each validation
/// - AI validation (async only, requires [aiValidator])
class DocSpecsValidator {
  /// The schema to validate against.
  final DocSpecSchema schema;

  /// Optional AI validator for LLM-based section validation.
  ///
  /// Only used by [validateAsync]. The sync [validate] method never calls AI.
  final AiValidator? aiValidator;

  /// Creates a new validator with the given schema.
  const DocSpecsValidator({required this.schema, this.aiValidator});

  /// Validates a document and returns all errors.
  List<ValidationError> validate(Document doc) {
    final errors = <ValidationError>[];

    // 1. Validate schema declaration
    errors.addAll(_validateSchemaDeclaration(doc));

    // 2. Collect all sections with types
    final allSections = _collectAllSections(doc);

    // 3. Validate section type resolution
    errors.addAll(_validateSectionTypes(allSections));

    // 4. Validate unique section IDs
    errors.addAll(_validateUniqueSectionIds(allSections));

    // 5. Validate document structure (required sections, order)
    errors.addAll(_validateDocumentStructure(doc));

    // 6. Validate count limits
    errors.addAll(_validateCountLimits(allSections));

    // 7. Validate nesting depth
    errors.addAll(_validateNestingDepth(allSections));

    // 8. Validate tags
    errors.addAll(_validateTags(allSections));

    // 9. Validate text requirements
    errors.addAll(_validateTextRequirements(allSections));

    // 10. Validate ID patterns
    errors.addAll(_validateIdPatterns(allSections));

    // 11. Validate text patterns
    errors.addAll(_validateTextPatterns(allSections));

    // 12. Validate format (code blocks, forms)
    errors.addAll(_validateFormat(allSections));

    // 13. Validate required fields
    errors.addAll(_validateRequiredFields(allSections));

    // 14. Validate child type enforcement (strict)
    errors.addAll(_validateChildTypes(allSections));

    // 15. Validate section-type matching in document structure
    errors.addAll(_validateDocumentSectionTypes(doc));

    // 16. Validate for-each
    errors.addAll(_validateForEach(doc));

    // 17. Validate subsection positions
    errors.addAll(_validateSubsectionPositions(doc));

    return errors;
  }

  /// Validates a document asynchronously, including AI validation.
  ///
  /// Runs all sync validations first, then invokes [aiValidator] for each
  /// section that has a `validationPrompt` in its type definition.
  /// If no [aiValidator] is set, this is identical to [validate].
  Future<List<ValidationError>> validateAsync(Document doc) async {
    // Run all sync validations
    final errors = validate(doc);

    // AI validation requires aiValidator and a SpecDoc
    if (aiValidator == null || doc is! SpecDoc) return errors;

    final specDoc = doc;
    final allSections = _collectAllSections(doc);
    final promptExpander = PromptExpander();

    // Build a lookup of document-level SectionDef by section id
    final sectionDefById = <String, SectionDef>{};
    for (final entry in schema.document.sections.entries) {
      sectionDefById[entry.key] = entry.value;
    }

    for (final info in allSections) {
      if (info.section is! SpecSection) continue;
      final specSection = info.section as SpecSection;

      // Find the section type definition
      final typeDef = specSection.type != null
          ? schema.sectionTypes[specSection.type]
          : null;

      // Determine the raw prompt: SectionDef.validationPrompt overrides type's
      final sectionDef = sectionDefById[specSection.id];
      final rawPrompt = sectionDef?.validationPrompt ??
          typeDef?.validationPrompt;

      if (rawPrompt != null && rawPrompt.isNotEmpty) {
        await _runAiValidation(
          errors: errors,
          rawPrompt: rawPrompt,
          specSection: specSection,
          specDoc: specDoc,
          typeDef: typeDef,
          promptExpander: promptExpander,
        );
      }

      // subsection-validation-prompt: validate all children of this section
      final subsectionPrompt = sectionDef?.subsectionValidationPrompt;
      if (subsectionPrompt != null && subsectionPrompt.isNotEmpty) {
        if (specSection.sections != null) {
          for (final child in specSection.sections!) {
            if (child is! SpecSection) continue;
            final childTypeDef = child.type != null
                ? schema.sectionTypes[child.type]
                : null;
            await _runAiValidation(
              errors: errors,
              rawPrompt: subsectionPrompt,
              specSection: child,
              specDoc: specDoc,
              typeDef: childTypeDef,
              promptExpander: promptExpander,
            );
          }
        }
      }
    }

    return errors;
  }

  /// Runs AI validation for a single section with the given prompt.
  Future<void> _runAiValidation({
    required List<ValidationError> errors,
    required String rawPrompt,
    required SpecSection specSection,
    required SpecDoc specDoc,
    required SectionTypeDef? typeDef,
    required PromptExpander promptExpander,
  }) async {
    final expandedPrompt = promptExpander.expand(
      rawPrompt,
      section: specSection,
      document: specDoc,
    );

    try {
      final result = await aiValidator!.validate(
        rawPrompt: rawPrompt,
        expandedPrompt: expandedPrompt,
        section: specSection,
        document: specDoc,
        sectionTypeDef: typeDef,
        schema: schema,
      );

      if (result != null) {
        errors.add(ValidationError(
          message: 'AI validation: $result',
          lineNumber: specSection.lineNumber,
          sectionId: specSection.id,
          category: ValidationErrorCategory.aiValidation,
        ));
      }
    } catch (e) {
      errors.add(ValidationError(
        message: 'AI validation failed: $e',
        lineNumber: specSection.lineNumber,
        sectionId: specSection.id,
        category: ValidationErrorCategory.aiValidation,
      ));
    }
  }

  /// Validates schema declaration.
  List<ValidationError> _validateSchemaDeclaration(Document doc) {
    final schemaField = doc.fields['schema'];
    if (schemaField != null && schemaField.isNotEmpty) return [];

    // Also accept SpecDoc with schemaId set (e.g. from <!-- docspec: ... --> format)
    if (doc is SpecDoc && doc.schemaId.isNotEmpty) return [];

    return [
      const ValidationError(
        message: 'Document must declare a schema using <!-- schema=<schema-id> --> or <!-- docspec: <id>/<version> -->',
        category: ValidationErrorCategory.schemaDeclaration,
      ),
    ];
  }

  /// Collects all sections from the document tree.
  List<_SectionInfo> _collectAllSections(Document doc) {
    final result = <_SectionInfo>[];

    void collect(Section section, int depth, Section? parent) {
      result.add(_SectionInfo(
        section: section,
        depth: depth,
        parent: parent,
      ));

      if (section.sections != null) {
        for (final child in section.sections!) {
          collect(child, depth + 1, section);
        }
      }
    }

    if (doc.sections != null) {
      for (final section in doc.sections!) {
        collect(section, 1, doc);
      }
    }

    return result;
  }

  /// Builds a descriptive error message for a missing required section.
  String _missingRequiredSectionMessage(String sectionKey, String sectionType) {
    final typeDef = schema.sectionTypes[sectionType];
    final prefix = typeDef?.prefix;
    if (prefix != null) {
      return "Required section '$sectionKey' (type '$sectionType') is missing. "
          "Add a section whose ID starts with '$prefix' (e.g. '$prefix-001' or '$prefix-$sectionKey').";
    }
    return "Required section '$sectionKey' (type '$sectionType') is missing.";
  }

  /// Validates that all sections have resolved types.
  List<ValidationError> _validateSectionTypes(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      final section = info.section;
      final id = section.id;

      // Skip sections without an ID — these are title/wrapper sections
      // or sections without explicit ID markers in the document.
      if (id.isEmpty) continue;

      // Check if section has a type (for SpecSection)
      if (section is SpecSection && section.type == null) {
        // Try to match against prefixes
        var matched = false;
        for (final entry in schema.sectionTypes.entries) {
          final prefix = entry.value.prefix;
          if (prefix != null &&
              id.toLowerCase().startsWith(prefix.toLowerCase())) {
            matched = true;
            break;
          }
        }

        if (!matched) {
          final prefixes = schema.sectionTypes.entries
              .where((e) => e.value.prefix != null)
              .map((e) => "'${e.value.prefix}' (${e.key})")
              .join(', ');
          errors.add(ValidationError(
            message: "Unknown section type: section '$id' does not match any known prefix. "
                "The section ID must start with one of: $prefixes",
            lineNumber: section.lineNumber,
            sectionId: id,
            category: ValidationErrorCategory.sectionType,
          ));
        }
      }
    }

    return errors;
  }

  /// Validates unique section IDs.
  List<ValidationError> _validateUniqueSectionIds(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];
    final seenIds = <String, int>{}; // id -> first line number

    for (final info in sections) {
      final id = info.section.id;
      final lineNumber = info.section.lineNumber;

      // Skip empty IDs — these are title/wrapper sections without explicit IDs
      if (id.isEmpty) continue;

      if (seenIds.containsKey(id)) {
        errors.add(ValidationError(
          message: "Duplicate section ID '$id' (first occurrence at line ${seenIds[id]})",
          lineNumber: lineNumber,
          sectionId: id,
          category: ValidationErrorCategory.sectionId,
        ));
      } else {
        seenIds[id] = lineNumber;
      }
    }

    return errors;
  }

  /// Validates document structure (required sections, order).
  List<ValidationError> _validateDocumentStructure(Document doc) {
    final errors = <ValidationError>[];
    final docSections = schema.document.sections;

    if (doc.sections == null || doc.sections!.isEmpty) {
      // Check for required sections
      for (final entry in docSections.entries) {
        if (entry.value.optional != true) {
          errors.add(ValidationError(
            message: _missingRequiredSectionMessage(entry.key, entry.value.sectionType),
            category: ValidationErrorCategory.structure,
          ));
        }
      }
      return errors;
    }

    // Check required sections exist by matching resolved type against sectionType
    final presentTypes = <String>{};
    for (final section in doc.sections!) {
      if (section is SpecSection && section.type != null) {
        presentTypes.add(section.type!);
      }
    }

    for (final entry in docSections.entries) {
      final sectionDef = entry.value;
      if (sectionDef.optional != true &&
          !presentTypes.contains(sectionDef.sectionType)) {
        errors.add(ValidationError(
          message: _missingRequiredSectionMessage(entry.key, sectionDef.sectionType),
          category: ValidationErrorCategory.structure,
        ));
      }
    }

    // Check section order by matching resolved types to expected order.
    // Use a consumed-index to handle types that appear multiple times
    // (e.g. 'overview' for both 'title' and 'overview' entries).
    final expectedTypeOrder =
        docSections.values.map((d) => d.sectionType).toList();
    var lastIndex = -1;

    for (final section in doc.sections!) {
      if (section is! SpecSection || section.type == null) continue;
      // Find the first occurrence of this type at or after lastIndex.
      var expectedIdx = -1;
      for (var i = (lastIndex < 0 ? 0 : lastIndex); i < expectedTypeOrder.length; i++) {
        if (expectedTypeOrder[i] == section.type) {
          expectedIdx = i;
          break;
        }
      }
      // Fallback: also look before lastIndex (may indicate out-of-order).
      if (expectedIdx == -1) {
        expectedIdx = expectedTypeOrder.indexOf(section.type!);
      }
      if (expectedIdx != -1) {
        if (expectedIdx < lastIndex) {
          errors.add(ValidationError(
            message: "Section '${section.id}' appears out of order",
            lineNumber: section.lineNumber,
            sectionId: section.id,
            category: ValidationErrorCategory.structure,
          ));
        } else {
          lastIndex = expectedIdx;
        }
      }
    }

    return errors;
  }

  /// Validates count limits.
  List<ValidationError> _validateCountLimits(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    // Count only top-level (depth == 1) sections by type.
    // Subsections are governed by subsection-type constraints, not
    // document-level max-count-in-document.
    final typeCounts = <String, int>{};
    for (final info in sections) {
      if (info.depth == 1 && info.section is SpecSection) {
        final type = (info.section as SpecSection).type;
        if (type != null) {
          typeCounts[type] = (typeCounts[type] ?? 0) + 1;
        }
      }
    }

    // Check max-count-in-document
    for (final entry in schema.sectionTypes.entries) {
      final typeDef = entry.value;
      final maxCount = typeDef.maxCountInDocument;
      if (maxCount != null) {
        final count = typeCounts[entry.key] ?? 0;
        if (count > maxCount) {
          errors.add(ValidationError(
            message: "Section type '${entry.key}' appears $count times, but max-count-in-document is $maxCount",
            category: ValidationErrorCategory.countLimit,
          ));
        }
      }
    }

    // Check subsection max-count per parent
    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null && section.sections != null) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.subsectionTypes != null) {
            final childCounts = <String, int>{};
            for (final child in section.sections!) {
              if (child is SpecSection && child.type != null) {
                childCounts[child.type!] = (childCounts[child.type!] ?? 0) + 1;
              }
            }

            for (final subEntry in typeDef!.subsectionTypes!.entries) {
              final constraint = subEntry.value;
              final count = childCounts[subEntry.key] ?? 0;

              if (constraint.maxCount != null && count > constraint.maxCount!) {
                errors.add(ValidationError(
                  message: "Section '${section.id}' has $count children of type '${subEntry.key}', but max-count is ${constraint.maxCount}",
                  lineNumber: section.lineNumber,
                  sectionId: section.id,
                  category: ValidationErrorCategory.countLimit,
                ));
              }

              final minCount = constraint.minCount ?? (constraint.required == true ? 1 : null);
              if (minCount != null && count < minCount) {
                errors.add(ValidationError(
                  message: "Section '${section.id}' has $count children of type '${subEntry.key}', but min-count is $minCount",
                  lineNumber: section.lineNumber,
                  sectionId: section.id,
                  category: ValidationErrorCategory.countLimit,
                ));
              }
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates nesting depth.
  List<ValidationError> _validateNestingDepth(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.maxSubsectionLevels != null) {
            final maxLevels = typeDef!.maxSubsectionLevels!;
            final actualDepth = _getSubsectionDepth(section);

            if (actualDepth > maxLevels) {
              errors.add(ValidationError(
                message: "Section '${section.id}' has subsections nested $actualDepth levels deep, but max-subsection-levels is $maxLevels",
                lineNumber: section.lineNumber,
                sectionId: section.id,
                category: ValidationErrorCategory.nestingDepth,
              ));
            }
          }
        }
      }
    }

    return errors;
  }

  /// Gets the maximum subsection depth of a section.
  int _getSubsectionDepth(Section section) {
    if (section.sections == null || section.sections!.isEmpty) return 0;

    var maxDepth = 0;
    for (final child in section.sections!) {
      final childDepth = 1 + _getSubsectionDepth(child);
      if (childDepth > maxDepth) maxDepth = childDepth;
    }
    return maxDepth;
  }

  /// Validates tags.
  List<ValidationError> _validateTags(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null && section.tags.isNotEmpty) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.allowedTags != null) {
            for (final tag in section.tags) {
              if (!typeDef!.allowedTags!.contains(tag)) {
                errors.add(ValidationError(
                  message: "Tag '$tag' is not allowed for section type '${section.type}'. Allowed tags: ${typeDef.allowedTags!.join(', ')}",
                  lineNumber: section.lineNumber,
                  sectionId: section.id,
                  category: ValidationErrorCategory.tags,
                ));
              }
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates text requirements.
  List<ValidationError> _validateTextRequirements(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef != null) {
            final text = section.text;

            // text-required — skip for container sections that have
            // subsections, since their content lives in children.
            final isContainer = section.sections != null &&
                section.sections!.isNotEmpty;
            if (typeDef.textRequired == true &&
                text.trim().isEmpty &&
                !isContainer) {
              errors.add(ValidationError(
                message: "Section '${section.id}' requires text content",
                lineNumber: section.lineNumber,
                sectionId: section.id,
                category: ValidationErrorCategory.textContent,
              ));
            }

            // min-text-length
            if (typeDef.minTextLength != null && text.length < typeDef.minTextLength!) {
              errors.add(ValidationError(
                message: "Section '${section.id}' text is ${text.length} characters, but min-text-length is ${typeDef.minTextLength}",
                lineNumber: section.lineNumber,
                sectionId: section.id,
                category: ValidationErrorCategory.textContent,
              ));
            }

            // max-text-length
            if (typeDef.maxTextLength != null && text.length > typeDef.maxTextLength!) {
              errors.add(ValidationError(
                message: "Section '${section.id}' text is ${text.length} characters, but max-text-length is ${typeDef.maxTextLength}",
                lineNumber: section.lineNumber,
                sectionId: section.id,
                category: ValidationErrorCategory.textContent,
              ));
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates ID patterns.
  List<ValidationError> _validateIdPatterns(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.patternCheckId != null) {
            final pattern = typeDef!.patternCheckId!;
            final regex = RegExp(pattern.pattern, caseSensitive: false);

            if (!regex.hasMatch(section.id)) {
              errors.add(ValidationError(
                message: "Invalid ID format for type '${section.type}': ${pattern.errorMessage}",
                lineNumber: section.lineNumber,
                sectionId: section.id,
                category: ValidationErrorCategory.sectionId,
              ));
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates text patterns.
  List<ValidationError> _validateTextPatterns(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.patternCheckText != null) {
            final pattern = typeDef!.patternCheckText!;
            final regex = RegExp(pattern.pattern, caseSensitive: false);

            if (!regex.hasMatch(section.text)) {
              errors.add(ValidationError(
                message: "Text pattern check failed for section '${section.id}': ${pattern.errorMessage}",
                lineNumber: section.lineNumber,
                sectionId: section.id,
                category: ValidationErrorCategory.textContent,
              ));
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates format (code blocks, forms).
  List<ValidationError> _validateFormat(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.format != null) {
            final format = typeDef!.format!;

            if (format.endsWith('-form')) {
              // Form validation
              errors.addAll(_validateFormFormat(section, format));
            } else {
              // Code block validation
              errors.addAll(_validateCodeBlockFormat(section, format));
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates code block format.
  List<ValidationError> _validateCodeBlockFormat(
    SpecSection section,
    String format,
  ) {
    final errors = <ValidationError>[];
    final allowedLanguages = format.split('|').map((l) => l.trim()).toSet();

    // Check if text contains a code block
    final codeBlockPattern = RegExp(r'```(\w+)?');
    final match = codeBlockPattern.firstMatch(section.text);

    if (match == null) {
      errors.add(ValidationError(
        message: "Section '${section.id}' must contain a code block with format: $format",
        lineNumber: section.lineNumber,
        sectionId: section.id,
        category: ValidationErrorCategory.format,
      ));
    } else {
      final language = match.group(1);
      if (language != null && !allowedLanguages.contains(language)) {
        errors.add(ValidationError(
          message: "Section '${section.id}' has code block with language '$language', but expected one of: $format",
          lineNumber: section.lineNumber,
          sectionId: section.id,
          category: ValidationErrorCategory.format,
        ));
      }
    }

    return errors;
  }

  /// Validates form format.
  List<ValidationError> _validateFormFormat(
    SpecSection section,
    String format,
  ) {
    final errors = <ValidationError>[];
    // Look up by full format name first, then without '-form' suffix for compatibility
    final formTypeName = format;
    final formType = schema.formTypes?[formTypeName] ??
        schema.formTypes?[format.substring(0, format.length - 5)];
    if (formType == null) {
      errors.add(ValidationError(
        message: "Form type '$formTypeName' not found in schema",
        lineNumber: section.lineNumber,
        sectionId: section.id,
        category: ValidationErrorCategory.format,
      ));
      return errors;
    }

    // Check required fields
    for (final field in formType.fields) {
      if (field.required == true) {
        final value = section.getFormField(field.fieldname);
        final commentValue = section.fields[field.fieldname];

        if ((value == null || value.isEmpty) &&
            (commentValue == null || commentValue.isEmpty)) {
          errors.add(ValidationError(
            message: "Required field '${field.fieldname}' is missing in section '${section.id}'",
            lineNumber: section.lineNumber,
            sectionId: section.id,
            category: ValidationErrorCategory.format,
          ));
        }

        // Check for duplicates
        if (value != null &&
            value.isNotEmpty &&
            commentValue != null &&
            commentValue.isNotEmpty) {
          errors.add(ValidationError(
            message: "Field '${field.fieldname}' appears in both comment and form text in section '${section.id}'",
            lineNumber: section.lineNumber,
            sectionId: section.id,
            category: ValidationErrorCategory.format,
          ));
        }
      }

      // Validate field pattern
      if (field.patternCheck != null) {
        final value = section.getFormField(field.fieldname) ??
            section.fields[field.fieldname];
        if (value != null && value.isNotEmpty) {
          final regex = RegExp(field.patternCheck!.pattern);
          if (!regex.hasMatch(value)) {
            errors.add(ValidationError(
              message: "Field '${field.fieldname}' value '$value' does not match pattern: ${field.patternCheck!.errorMessage}",
              lineNumber: section.lineNumber,
              sectionId: section.id,
              category: ValidationErrorCategory.format,
            ));
          }
        }
      }
    }

    return errors;
  }

  /// Validates required fields on sections.
  List<ValidationError> _validateRequiredFields(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.requiredFields != null) {
            for (final fieldName in typeDef!.requiredFields!) {
              final value = section.getFormField(fieldName) ??
                  section.fields[fieldName];
              if (value == null || value.isEmpty) {
                errors.add(ValidationError(
                  message:
                      "Required field '$fieldName' is missing in section '${section.id}' (type '${section.type}')",
                  lineNumber: section.lineNumber,
                  sectionId: section.id,
                  category: ValidationErrorCategory.format,
                ));
              }
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates that child section types match allowed subsection-types (strict).
  List<ValidationError> _validateChildTypes(List<_SectionInfo> sections) {
    final errors = <ValidationError>[];

    for (final info in sections) {
      if (info.section is SpecSection) {
        final section = info.section as SpecSection;
        if (section.type != null && section.sections != null && section.sections!.isNotEmpty) {
          final typeDef = schema.sectionTypes[section.type];
          if (typeDef?.subsectionTypes != null) {
            final allowedTypes = typeDef!.subsectionTypes!.keys.toSet();

            for (final child in section.sections!) {
              if (child is SpecSection && child.type != null) {
                // Skip children whose type matches the parent type due to
                // auto-generated IDs inheriting the parent's prefix.
                if (child.type == section.type) continue;
                if (!allowedTypes.contains(child.type)) {
                  errors.add(ValidationError(
                    message:
                        "Section '${section.id}' (type '${section.type}') does not allow child type '${child.type}'. Allowed: ${allowedTypes.join(', ')}",
                    lineNumber: child.lineNumber,
                    sectionId: child.id,
                    category: ValidationErrorCategory.sectionType,
                  ));
                }
              }
            }
          }
        }
      }
    }

    return errors;
  }

  /// Validates that document sections match their declared section-type.
  List<ValidationError> _validateDocumentSectionTypes(Document doc) {
    final errors = <ValidationError>[];

    if (doc.sections == null) return errors;

    for (final section in doc.sections!) {
      if (section is SpecSection && section.type != null) {
        // Find the SectionDef whose sectionType matches this section's type
        SectionDef? sectionDef;
        for (final entry in schema.document.sections.entries) {
          if (entry.value.sectionType == section.type) {
            sectionDef = entry.value;
            break;
          }
        }
        if (sectionDef != null && section.type != sectionDef.sectionType) {
          errors.add(ValidationError(
            message:
                "Section '${section.id}' has type '${section.type}' but document structure declares it as type '${sectionDef.sectionType}'",
            lineNumber: section.lineNumber,
            sectionId: section.id,
            category: ValidationErrorCategory.structure,
          ));
        }
      }
    }

    return errors;
  }

  /// Validates for-each patterns.
  List<ValidationError> _validateForEach(Document doc) {
    final errors = <ValidationError>[];

    // For-each is declared on document sections
    for (final entry in schema.document.sections.entries) {
      final sectionDef = entry.value;
      final forEach = sectionDef.forEach;
      if (forEach == null) continue;

      // Find all target sections in the document by matching resolved type
      final targetSections = <SpecSection>[];
      if (doc.sections != null) {
        for (final s in doc.sections!) {
          if (s is SpecSection && s.type == sectionDef.sectionType) {
            targetSections.add(s);
          }
        }
      }

      if (targetSections.isEmpty) continue;

      // Find all registry entries of the specified type
      final registryType = forEach.sectionType;
      final keyField = forEach.key;

      // Collect registry entries (sections of registryType across the whole document)
      final registryKeys = <String>{};
      void collectRegistryEntries(Section section) {
        if (section is SpecSection && section.type == registryType) {
          final keyValue = section.fields[keyField] ?? section.getFormField(keyField);
          if (keyValue != null && keyValue.isNotEmpty) {
            registryKeys.add(keyValue);
          }
        }
        if (section.sections != null) {
          for (final child in section.sections!) {
            collectRegistryEntries(child);
          }
        }
      }

      if (doc.sections != null) {
        for (final s in doc.sections!) {
          collectRegistryEntries(s);
        }
      }

      // Collect keys from target sections and their children
      final subsectionKeys = <String>{};
      for (final targetSection in targetSections) {
        // Check the target section itself
        final keyValue = targetSection.fields[keyField] ?? targetSection.getFormField(keyField);
        if (keyValue != null && keyValue.isNotEmpty) {
          subsectionKeys.add(keyValue);
        }
        // Also check direct children of the target section
        if (targetSection.sections != null) {
          for (final child in targetSection.sections!) {
            if (child is SpecSection) {
              final childKey = child.fields[keyField] ?? child.getFormField(keyField);
              if (childKey != null && childKey.isNotEmpty) {
                subsectionKeys.add(childKey);
              }
            }
          }
        }
      }

      // Check: every registry entry should have a corresponding subsection
      for (final key in registryKeys) {
        if (!subsectionKeys.contains(key)) {
          errors.add(ValidationError(
            message:
                "Registry entry '$key' (type '$registryType') has no corresponding subsection in '${entry.key}'",
            sectionId: entry.key,
            category: ValidationErrorCategory.forEach,
          ));
        }
      }

      // Check: every subsection should have a corresponding registry entry
      for (final key in subsectionKeys) {
        if (!registryKeys.contains(key)) {
          errors.add(ValidationError(
            message:
                "Subsection with $keyField='$key' in '${entry.key}' has no corresponding registry entry of type '$registryType'",
            sectionId: entry.key,
            category: ValidationErrorCategory.forEach,
          ));
        }
      }
    }

    return errors;
  }

  /// Validates subsection positions.
  List<ValidationError> _validateSubsectionPositions(Document doc) {
    final errors = <ValidationError>[];

    // Check subsection declarations (top-level block)
    if (schema.subsectionDeclarations != null) {
      for (final declEntry in schema.subsectionDeclarations!.entries) {
        final parentSectionName = declEntry.key;
        final subsectionDefs = declEntry.value;

        // Find the parent section in the document by matching resolved type
        final parentSectionDef = schema.document.sections[parentSectionName];
        final parentType = parentSectionDef?.sectionType;
        Section? parentSection;
        if (doc.sections != null && parentType != null) {
          for (final s in doc.sections!) {
            if (s is SpecSection && s.type == parentType) {
              parentSection = s;
              break;
            }
          }
        }

        if (parentSection == null || parentSection.sections == null) continue;

        final children = parentSection.sections!;

        for (final subEntry in subsectionDefs.entries) {
          final subDef = subEntry.value;
          final position = subDef.position ?? 'relative';
          final subType = subDef.sectionType;

          // Check required subsections
          if (subDef.required == true) {
            final hasType = children.any(
              (c) => c is SpecSection && c.type == subType,
            );
            if (!hasType) {
              errors.add(ValidationError(
                message:
                    "Required subsection of type '$subType' is missing in section '$parentSectionName'",
                sectionId: parentSectionName,
                category: ValidationErrorCategory.structure,
              ));
            }
          }

          // Check position constraints
          errors.addAll(
            _checkPositionConstraint(children, subType, position, parentSectionName),
          );
        }
      }
    }

    return errors;
  }

  /// Checks position constraints for children of a given type.
  List<ValidationError> _checkPositionConstraint(
    List<Section> children,
    String subType,
    String position,
    String parentId,
  ) {
    final errors = <ValidationError>[];
    if (children.isEmpty || position == 'any') return errors;

    final typedIndices = <int>[];
    for (var i = 0; i < children.length; i++) {
      if (children[i] is SpecSection &&
          (children[i] as SpecSection).type == subType) {
        typedIndices.add(i);
      }
    }

    if (typedIndices.isEmpty) return errors;

    switch (position) {
      case 'first':
        // All instances of this type must come before all other types
        if (typedIndices.isNotEmpty) {
          final lastTypedIdx = typedIndices.last;
          // Check that no non-typed section appears before the last typed one
          for (var i = 0; i < lastTypedIdx; i++) {
            if (!typedIndices.contains(i)) {
              errors.add(ValidationError(
                message:
                    "Subsection of type '$subType' must appear first in '$parentId', but non-'$subType' section found before it",
                lineNumber: children[typedIndices.last].lineNumber,
                sectionId: parentId,
                category: ValidationErrorCategory.structure,
              ));
              break;
            }
          }
        }
      case 'last':
        // All instances of this type must come after all other types
        if (typedIndices.isNotEmpty) {
          final firstTypedIdx = typedIndices.first;
          for (var i = firstTypedIdx + 1; i < children.length; i++) {
            if (!typedIndices.contains(i)) {
              errors.add(ValidationError(
                message:
                    "Subsection of type '$subType' must appear last in '$parentId', but non-'$subType' section found after it",
                lineNumber: children[firstTypedIdx].lineNumber,
                sectionId: parentId,
                category: ValidationErrorCategory.structure,
              ));
              break;
            }
          }
        }
      case 'relative':
        // All instances of this type must be contiguous (together)
        for (var i = 1; i < typedIndices.length; i++) {
          if (typedIndices[i] != typedIndices[i - 1] + 1) {
            errors.add(ValidationError(
              message:
                  "Subsections of type '$subType' must be contiguous in '$parentId', but they are separated by other sections",
              lineNumber: children[typedIndices[i]].lineNumber,
              sectionId: parentId,
              category: ValidationErrorCategory.structure,
            ));
            break;
          }
        }
    }

    return errors;
  }
}

/// Helper class for section traversal.
class _SectionInfo {
  final Section section;
  final int depth;
  final Section? parent;

  const _SectionInfo({
    required this.section,
    required this.depth,
    this.parent,
  });
}
