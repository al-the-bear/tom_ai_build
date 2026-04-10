import '../annotations/content_type.dart';

/// A generic Mermaid diagram section.
@ContentType('mermaid', 'The description for the content is provided by the doc-comment on the field declaration of this type')
class DiagramSection {
  String? content;
}
