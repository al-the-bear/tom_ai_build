/// Provides an AI validation prompt for the section content.
///
/// Applied to model classes. The prompt is used by AI-assisted validators to
/// check that the section content meets domain-specific quality criteria.
class ValidationPrompt {
  final String prompt;

  const ValidationPrompt(this.prompt);
}
