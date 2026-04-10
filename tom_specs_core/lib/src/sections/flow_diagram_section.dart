import '../annotations/content_type.dart';
import 'diagram_section.dart';

/// A Mermaid flow chart diagram section.
class FlowDiagramSection extends DiagramSection {
  @override
  @ContentType('mermaid-flow', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}
