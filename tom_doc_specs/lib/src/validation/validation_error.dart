/// Represents a validation error with location information.
class ValidationError {
  /// The error message.
  final String message;

  /// Line number where the error occurred (1-based).
  final int? lineNumber;

  /// Section ID where the error occurred.
  final String? sectionId;

  /// Error category for grouping.
  final ValidationErrorCategory category;

  /// The finding's code as the DocSpecs specification names it
  /// (`malformedBlock`, `unknownField`, `unknownSection`, `unclosedDiv`,
  /// `strayClosingFence`, `rejectedBlock`), for the findings the
  /// specification gives a code; `null` for the others.
  final String? code;

  /// Creates a new ValidationError.
  const ValidationError({
    required this.message,
    this.lineNumber,
    this.sectionId,
    this.category = ValidationErrorCategory.general,
    this.code,
  });

  @override
  String toString() {
    final parts = <String>[];
    if (lineNumber != null) {
      parts.add('Line $lineNumber');
    }
    if (sectionId != null) {
      parts.add('"$sectionId"');
    }
    if (parts.isNotEmpty) {
      return '${parts.join(': ')}: $message';
    }
    return message;
  }
}

/// Categories of validation errors.
enum ValidationErrorCategory {
  /// General validation errors.
  general,

  /// Schema declaration errors.
  schemaDeclaration,

  /// Section type resolution errors.
  sectionType,

  /// Section ID errors (uniqueness, pattern).
  sectionId,

  /// Document structure errors (order, required sections).
  structure,

  /// Count limit violations.
  countLimit,

  /// Nesting depth violations.
  nestingDepth,

  /// Tag validation errors.
  tags,

  /// Text content errors.
  textContent,

  /// Format validation errors (code blocks, forms).
  format,

  /// For-each validation errors.
  forEach,

  /// AI validation errors.
  aiValidation,

  /// Reading-notation errors (fenced divs, DocSpecs specification RN-10).
  notation,
}
