import 'package:tom_specs_core/tom_specs_core.dart';


import 'enums.dart';

/// Base requirement shared across documents.
///
/// Document-specific requirement types extend this with additional fields.
/// For example, Solution Blueprint functional requirements add
/// [relatedUseCase], [relatedBusinessProcess], and [affectedDataEntities].
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148:2018 §5 — requirement attributes',
    'INCOSE Guide for Writing Requirements',
  ],
  'The base requirement shared across documents, capturing id, title, description, priority, source, rationale, acceptance criteria, and status.',
)
@SectionId('REQ')
class Requirement {
  @Form([
    Field('requirementId', String, 'Requirement ID (REQ-NNN; NFR-NNN '
        'for non-functional)', required: true),
    Field('title', String, 'Title', required: true),
    Field('description', String, 'Short description'),
    Field('priority', Priority, 'Priority level'),
    Field('source', String, 'Source'),
    Field('rationale', String, 'Rationale'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria'),
    Field('status', Status, 'Current status'),
  ])
  @SerializationOrder(0)
  String? content;
}
