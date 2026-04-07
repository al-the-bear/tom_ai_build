import 'enums.dart';

/// Metadata annotation for a document section.
///
/// Captures the DocSpecs section type, section ID, and optional seed
/// reference to the Phase 3 document this section expands into.
class SectionMeta {
  final String sectionId;
  final SectionType type;

  /// Phase 3 document this section seeds, e.g. 'RC', 'BP', 'BDM'.
  final String? seeds;

  const SectionMeta({
    required this.sectionId,
    required this.type,
    this.seeds,
  });
}
