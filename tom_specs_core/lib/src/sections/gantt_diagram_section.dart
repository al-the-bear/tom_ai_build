import '../annotations/content_type.dart';
import 'diagram_section.dart';

/// A Mermaid Gantt chart diagram section.
class GanttDiagramSection extends DiagramSection {
  @override
  @ContentType(
    'mermaid-gantt',
    'The description for the content is provided by the doc-comment on the field declaration of this type',
  )
  String? content;
}
