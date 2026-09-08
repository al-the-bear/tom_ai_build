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
  /// - A document title at level 1
  /// - All required sections from the document structure, at level 2 and below
  /// - Placeholder text in each section
  /// - Correct heading levels based on nesting
  ///
  /// **The title is a heading, not the first section.** The scanner reads a
  /// level-1 heading as the document title, so emitting the first document
  /// section there made it disappear as a section and then be reported
  /// missing — a skeleton that its own schema rejected. Sections therefore
  /// start at level 2, which is also the shape every hand-written fixture in
  /// this package uses.
  ///
  /// The title text is the schema id, title-cased. The schema model carries no
  /// title field, so the id is the only thing available that says anything at
  /// all; it is a placeholder an author is expected to replace, and it carries
  /// no section id because a title is not a section.
  static String generate(DocSpecSchema schema) {
    final buffer = StringBuffer();

    // Add schema declaration comment
    buffer.writeln('<!-- docspec: ${schema.id}/${schema.version} -->');

    buffer.writeln();
    buffer.writeln('# ${_formatSectionName(schema.id)}');

    // Generate sections from document structure
    final documentStructure = schema.document;
    final sections = documentStructure.sections;

    for (final entry in sections.entries) {
      final sectionName = entry.key;
      final sectionDef = entry.value;

      // Skip optional sections if they don't have required: true
      final isOptional = sectionDef.optional ?? false;
      if (isOptional) continue;

      // Get the section type for this section
      final sectionType = schema.sectionTypes[sectionDef.sectionType];
      if (sectionType == null) continue;

      // Generate section heading, beneath the document title.
      _generateSection(
        buffer,
        sectionName: sectionName,
        sectionType: sectionType,
        level: 2,
        schema: schema,
        displayName: sectionDef.accessKey,
      );
    }

    return buffer.toString();
  }

  /// Generate a single section with its subsections.
  ///
  /// [typePath] holds the section-type names on the current recursion path;
  /// it guards against infinite recursion for self-/mutually-recursive
  /// section types. There is no fixed depth cap: DocSpecs documents support
  /// arbitrary section nesting (heading level = 1 + depth, uncapped).
  static void _generateSection(
    StringBuffer buffer, {
    required String sectionName,
    required SectionTypeDef sectionType,
    required int level,
    required DocSpecSchema schema,
    Set<String> typePath = const {},
    String? displayName,
  }) {
    // Generate heading with ID prefix
    final prefix = sectionType.prefix ?? sectionType.name;
    final headingId = _generateId(prefix, sectionName);
    final headingMarker = '#' * level;

    // A section's `access-key` is the name it is addressed by, so it is the
    // better heading text when the schema states one; the map key is a
    // structural identifier and often reads like one (`note-001`).
    final heading = _formatSectionName(displayName ?? sectionName);

    buffer.writeln();
    buffer.writeln('$headingMarker [$headingId] $heading');
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

    // Generate required subsections (no depth cap — nesting is uncapped;
    // recursion is bounded by the cycle guard on section-type names).
    final subsectionTypes = sectionType.subsectionTypes;
    if (subsectionTypes != null) {
      final nextPath = {...typePath, sectionType.name};
      for (final subEntry in subsectionTypes.entries) {
        final subTypeName = subEntry.key;
        final constraint = subEntry.value;

        // Only generate if required or has minCount
        final isRequired = constraint.required ?? false;
        final minCount = constraint.minCount ?? 0;

        if (!isRequired && minCount <= 0) continue;

        final subType = schema.sectionTypes[subTypeName];
        if (subType == null) continue;

        // Cycle guard: don't recurse into a type already on this path.
        if (nextPath.contains(subType.name)) continue;

        // Generate the minimum required number of subsections
        final count = minCount > 0 ? minCount : 1;
        for (var i = 1; i <= count; i++) {
          _generateSection(
            buffer,
            sectionName: count > 1 ? '${subTypeName}_$i' : subTypeName,
            sectionType: subType,
            level: level + 1,
            schema: schema,
            typePath: nextPath,
          );
        }
      }
    }
  }

  /// Generate a section ID from prefix and name.
  ///
  /// The validator requires a section id to *start with* its type's prefix, so
  /// a key that already does needs no second one: a section keyed `note-001`
  /// under prefix `note` is `note-001`, not `note-note-001`. Only a key that
  /// does not carry the prefix gets it added.
  static String _generateId(String prefix, String sectionName) {
    // Convert section name to kebab-case and combine with prefix
    final kebabName = sectionName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-')
        .toLowerCase()
        .replaceAll(RegExp(r'^-+|-+$'), '');

    final kebabPrefix = prefix.toLowerCase();
    if (kebabName == kebabPrefix || kebabName.startsWith('$kebabPrefix-')) {
      return kebabName;
    }
    return '$prefix-$kebabName';
  }

  /// Format a section name for display in heading.
  static String _formatSectionName(String name) {
    // Convert kebab-case or snake_case to Title Case
    return name
        .replaceAll(RegExp(r'[-_]'), ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
