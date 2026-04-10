import 'package:tom_specs_core/tom_specs_core.dart';

import 'enums.dart';

/// Metadata annotation for a document section.
///
/// Captures the DocSpecs section type, section ID, and optional seed
/// reference to the Phase 3 document this section expands into.
class SectionMeta {
  @Form([
    Field('sectionId', String, 'Section Id'),
    Field('type', SectionType, 'Type'),
    Field('seeds', String, 'Seeds'),
  ])
  String? content;
}
