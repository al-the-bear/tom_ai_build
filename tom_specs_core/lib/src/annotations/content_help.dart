/// Provides content creation guidance for a section or field.
///
/// Applied to classes or fields that need specific guidance about content format,
/// how to obtain the data, what to include, or other authoring instructions.
/// This annotation helps AI assistants and human authors understand the intent
/// and approach for populating the section.
///
/// Example:
/// ```dart
/// @ContentHelp('Interview stakeholders to identify key pain points. '
///     'Document each pain point with severity (High/Medium/Low) and '
///     'estimated business impact.')
/// @SectionId('BUPAPO')
/// List<PainPoint> operationalPainPoints = [];
/// ```
class ContentHelp {
  /// The guidance text explaining how to create or populate this content.
  final String guidance;

  /// Attaches authoring [guidance] to the annotated section or field.
  const ContentHelp(this.guidance);
}
