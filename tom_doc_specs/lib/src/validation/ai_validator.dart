/// @docImport 'prompt_expander.dart';
library;

import '../models/schema/doc_spec_schema.dart';
import '../models/schema/section_type_def.dart';
import '../models/spec_doc.dart';
import '../models/spec_section.dart';

/// Injectable interface for AI-powered section validation.
///
/// Implementations wrap an LLM API call. The library handles all prompt
/// preparation (expanding `${...}` placeholders via [PromptExpander]), so
/// the implementation can focus purely on the LLM interaction.
///
/// ## Usage
///
/// ```dart
/// class MyAiValidator implements AiValidator {
///   @override
///   Future<String?> validate({
///     required String rawPrompt,
///     required String expandedPrompt,
///     required SpecSection section,
///     required SpecDoc document,
///     required SectionTypeDef? sectionTypeDef,
///     required DocSpecSchema schema,
///   }) async {
///     final response = await callLlm(expandedPrompt);
///     if (response.trim().toLowerCase() == 'ok') return null;
///     return response; // Error description
///   }
/// }
/// ```
abstract class AiValidator {
  /// Validates a section using an LLM.
  ///
  /// Returns `null` if the section passes validation, or a string with the
  /// error description if it fails.
  ///
  /// Parameters:
  /// - [rawPrompt]: Original prompt with `${...}` placeholders intact
  ///   (for logging, debugging, or custom rewriting)
  /// - [expandedPrompt]: Fully resolved prompt, ready to send to an LLM
  /// - [section]: The section being validated
  /// - [document]: Complete document for full context
  /// - [sectionTypeDef]: Section's type definition from schema (null if no match)
  /// - [schema]: Complete schema
  Future<String?> validate({
    required String rawPrompt,
    required String expandedPrompt,
    required SpecSection section,
    required SpecDoc document,
    required SectionTypeDef? sectionTypeDef,
    required DocSpecSchema schema,
  });
}
