import 'enums.dart';

/// Metadata annotation for a document section.
///
/// Captures the DocSpecs section type, section ID, and optional seed
/// reference to the Phase 3 document this section expands into.
class SectionMeta {
  String? content;
  String? sectionId;
  SectionType? type;

  /// Phase 3 document this section seeds, e.g. 'RC', 'BP', 'BDM'.
  String? seeds;
}
