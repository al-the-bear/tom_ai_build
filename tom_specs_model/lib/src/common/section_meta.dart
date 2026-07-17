import 'package:tom_specs_core/tom_specs_core.dart';

import '../snapshot/spec_node.dart';
import 'enums.dart';

/// Metadata annotation for a document section.
///
/// Captures the DocSpecs section type, section ID, and optional seed
/// reference to the Phase 3 document this section expands into.
///
/// A leaf [SpecNode]: only the scalar [content] field, so snapshots share an
/// unchanged instance by identity.
@SectionId('SCMTA')
class SectionMeta extends DocSpecsSection with SpecNode {
  @Form([
    Field('sectionId', String, 'Section Id'),
    Field('type', SectionType, 'Type'),
    Field('seeds', String, 'Seeds'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @override
  SectionMeta cloneShallow() => SectionMeta()..content = content;

  @override
  String? yamlScalar() => content;
}
