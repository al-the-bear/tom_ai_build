import '../annotations/content_type.dart';
import 'code_section.dart';

/// An SQL code block section.
@ContentType('code-sql', 'The description for the content is provided by the doc-comment on the field declaration of this type')
class SqlCodeSection extends CodeSection {}
