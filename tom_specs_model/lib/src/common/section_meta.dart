import 'enums.dart';
import 'package:tom_core_kernel/tom_core_kernel.dart';

/// Metadata annotation for a document section.
///
/// Captures the DocSpecs section type, section ID, and optional seed
/// reference to the Phase 3 document this section expands into.
@tomReflector
class SectionMeta {
  String? sectionId;
  SectionType? type;

  /// Phase 3 document this section seeds, e.g. 'RC', 'BP', 'BDM'.
  String? seeds;
}
