
import 'enums.dart';

/// Base requirement shared across documents.
///
/// Document-specific requirement types extend this with additional fields.
/// For example, PD functional requirements add [relatedUseCase],
/// [relatedBusinessProcess], and [affectedDataEntities].
class Requirement {
  String? requirementId;
  String? title;
  String? description;
  Priority? priority;
  String? source;
  String? rationale;
  String? acceptanceCriteria;
  Status status = Status.draft;
}
