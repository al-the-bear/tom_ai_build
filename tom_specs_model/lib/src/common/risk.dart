import 'package:tom_specs_core/tom_specs_core.dart';


import 'enums.dart';

/// Risk entry shared across documents.
@SectionId('RISK')
class Risk {
  @Form([
    Field('riskId', String, 'Risk Id', required: true),
    Field('name', String, 'Name', required: true),
    Field('description', String, 'Short description'),
    Field('probability', Probability, 'Probability'),
    Field('impact', Impact, 'Impact assessment'),
    Field('mitigation', String, 'Mitigation strategy'),
    Field('riskOwner', String, 'Risk Owner'),
    Field('reviewFrequency', String, 'Review Frequency'),
  ])
  String? content;
}
