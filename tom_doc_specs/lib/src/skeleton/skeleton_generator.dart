import '../models/schema/doc_spec_schema.dart';
import '../models/schema/section_type_def.dart';

/// Generates skeleton markdown documents from DocSpec schemas.
///
/// Creates a document with all required sections from the schema,
/// using placeholder text that can be filled in by the user.
class DocSpecsSkeletonGenerator {
  /// Generate a skeleton document from a schema.
  ///
  /// Returns a markdown string with:
  /// - A docspec comment linking to the schema
  /// - All required sections from the document structure
  /// - Placeholder text in each section
  /// - Correct heading levels based on nesting
  static String generate(DocSpecSchema schema) {
    final buffer = StringBuffer();

    // Add schema declaration comment
    buffer.writeln('<!-- docspec: ${schema.id}/${schema.version} -->');

    // Generate sections from document structure
    final documentStructure = schema.document;
    final sections = documentStructure.sections;

    var isFirst = true;
    for (final entry in sections.entries) {
      final sectionName = entry.key;
      final sectionDef = entry.value;

      // Skip optional sections if they don't have required: true
      final isOptional = sectionDef.optional ?? false;
      if (isOptional) continue;

      // Get the section type for this section
      final sectionType = schema.sectionTypes[sectionDef.sectionType];
      if (sectionType == null) continue;

      // Determine heading level (first section is title at level 1)
      final level = isFirst ? 1 : 2;
      isFirst = false;

      // Generate section heading
      _generateSection(
        buffer,
        sectionName: sectionName,
        sectionType: sectionType,
        level: level,
        schema: schema,
      );
    }

    return buffer.toString();
  }

  /// Generate a single section with its subsections.
  static void _generateSection(
    StringBuffer buffer, {
    required String sectionName,
    required SectionTypeDef sectionType,
    required int level,
    required DocSpecSchema schema,
  }) {
    // Generate heading with ID prefix
    final prefix = sectionType.prefix ?? sectionType.name;
    final headingId = _generateId(prefix, sectionName);
    final headingMarker = '#' * level;

    buffer.writeln();
    buffer.writeln('$headingMarker [$headingId] ${_formatSectionName(sectionName)}');
    buffer.writeln();

    // Add placeholder text
    final description = sectionType.description;
    if (description != null) {
      buffer.writeln('<!-- $description -->');
      buffer.writeln();
    }

    if (sectionType.textRequired == true) {
      buffer.writeln('TODO: Add content for this section.');
      buffer.writeln();
    }

    // Generate required subsections
    final subsectionTypes = sectionType.subsectionTypes;
    if (subsectionTypes != null && level < 6) {
      for (final subEntry in subsectionTypes.entries) {
        final subTypeName = subEntry.key;
        final constraint = subEntry.value;

        // Only generate if required or has minCount
        final isRequired = constraint.required ?? false;
        final minCount = constraint.minCount ?? 0;

        if (!isRequired && minCount <= 0) continue;

        final subType = schema.sectionTypes[subTypeName];
        if (subType == null) continue;

        // Generate the minimum required number of subsections
        final count = minCount > 0 ? minCount : 1;
        for (var i = 1; i <= count; i++) {
          _generateSection(
            buffer,
            sectionName: count > 1 ? '${subTypeName}_$i' : subTypeName,
            sectionType: subType,
            level: level + 1,
            schema: schema,
          );
        }
      }
    }
  }

  /// Generate a section ID from prefix and name.
  static String _generateId(String prefix, String sectionName) {
    // Convert section name to kebab-case and combine with prefix
    final kebabName = sectionName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
        .toLowerCase()
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return '$prefix-$kebabName';
  }

  /// Format a section name for display in heading.
  static String _formatSectionName(String name) {
    // Convert kebab-case or snake_case to Title Case
    return name
        .replaceAll(RegExp(r'[-_]'), ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
