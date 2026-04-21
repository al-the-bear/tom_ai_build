import 'package:tom_specs_core/tom_specs_core.dart';


import 'enums.dart';

/// Base requirement shared across documents.
///
/// Document-specific requirement types extend this with additional fields.
/// For example, PD functional requirements add [relatedUseCase],
/// [relatedBusinessProcess], and [affectedDataEntities].
@SectionId('REQ')
class Requirement {
  @Form([
    Field('requirementId', String, 'Requirement Id', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String, 'Short description'),
    Field('priority', Priority, 'Priority level'),
    Field('source', String, 'Source'),
    Field('rationale', String, 'Rationale'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria'),
    Field('status', Status, 'Current status'),
  ])
  String? content;
}
