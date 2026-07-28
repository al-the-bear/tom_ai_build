import '../annotations/content_type.dart';
import 'diagram_section.dart';

/// A Mermaid sequence diagram section.
class SequenceDiagramSection extends DiagramSection {
  @override
  @ContentType(
    'mermaid-sequence',
    'The description for the content is provided by the doc-comment on the field declaration of this type',
  )
  String? content;
}
