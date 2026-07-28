import '../annotations/content_type.dart';
import 'docspecs_section.dart';

/// A free-text section that may contain narrative, diagrams, or references.
class TextSection extends DocSpecsSection {
  @override
  @ContentType(
    'text',
    'The description for the content is provided by the doc-comment on the field declaration of this type',
  )
  String? content;
}
