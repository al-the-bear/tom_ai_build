import '../annotations/content_type.dart';
import 'diagram_section.dart';

/// A Mermaid ER diagram section.
class ErDiagramSection extends DiagramSection {
  @override
  @ContentType('mermaid-er', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}
