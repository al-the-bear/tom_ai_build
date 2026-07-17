import 'package:tom_specs_core/tom_specs_core.dart';


import 'enums.dart';

/// Risk entry shared across documents.
@StandardReferences(
  ['ISO 31000:2018 — risk management'],
  'A single risk entry with its probability, impact, mitigation, owner, and review frequency.',
)
@SectionId('RISK')
class Risk extends DocSpecsSection {
  @Form([
    Field('riskId', String, 'Risk ID (RISK-NNN)', required: true),
    Field('name', String, 'Name', required: true),
    Field('description', String, 'Short description'),
    Field('probability', Probability, 'Probability'),
    Field('impact', Impact, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
    Field('riskOwner', String, 'Risk Owner'),
    Field('reviewFrequency', String, 'Review Frequency'),
  ])
  @override
  @SerializationOrder(0)
  String? content;
}
