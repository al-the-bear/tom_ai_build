import 'package:tom_specs_core/tom_specs_core.dart';


import 'enums.dart';

/// Base requirement shared across documents.
///
/// Document-specific requirement types add fields to this shape — the
/// Solution Blueprint's `FunctionalRequirementEntry` elaborates it with
/// traceability, acceptance criteria, UI specification, and business rules.
/// Its id is its section id and its title its stored headline, in common with
/// every requirement family (`tom_specs_model_rules.md` §8 rule 4).
@StandardReferences(
  [
    'ISO/IEC/IEEE 29148:2018 §5 — requirement attributes',
    'INCOSE Guide for Writing Requirements',
  ],
  'The base requirement shared across documents, capturing description, priority, source, rationale, acceptance criteria, and status.',
)
@SectionId('REQ')
class Requirement extends DocSpecsSection {
  // Why: there is a single authoritative storage slot for each of the
  // requirement's title and id — the id in `@SectionId('REQ')` (or, for a
  // list element, the owning list's `@SectionIdPattern`), the title in the
  // stored headline. No form field restates either
  // (tom_specs_model_rules.md §8 rule 4); a short human code such as
  // REQ-001 belongs in that heading, not in a field.
  @Form([
    Field('description', String, 'Short description'),
    Field('priority', Priority, 'Priority level'),
    Field('source', String, 'Source'),
    Field('rationale', String, 'Rationale'),
    Field('acceptanceCriteria', String, 'Acceptance Criteria'),
    Field('status', Status, 'Current status'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
