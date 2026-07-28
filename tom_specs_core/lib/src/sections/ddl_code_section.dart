import '../annotations/content_type.dart';
import 'code_section.dart';

/// A DDL code block section.
class DdlCodeSection extends CodeSection {
  @override
  @ContentType(
    'code-ddl',
    'The description for the content is provided by the doc-comment on the field declaration of this type',
  )
  String? content;
}
