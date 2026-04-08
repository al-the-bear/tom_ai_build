import 'enums.dart';

/// Base requirement shared across documents.
///
/// Document-specific requirement types extend this with additional fields.
/// For example, PD functional requirements add [relatedUseCase],
/// [relatedBusinessProcess], and [affectedDataEntities].
class Requirement {
  final String requirementId;
  final String title;
  final String description;
  final Priority priority;
  final String source;
  final String? rationale;
  final String acceptanceCriteria;
  final Status status;

  const Requirement({
    required this.requirementId,
    required this.title,
    required this.description,
    required this.priority,
    required this.source,
    this.rationale,
    required this.acceptanceCriteria,
    this.status = Status.draft,
  });
}
