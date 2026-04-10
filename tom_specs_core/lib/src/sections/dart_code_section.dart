import '../annotations/content_type.dart';
import 'code_section.dart';

/// A Dart code block section.
class DartCodeSection extends CodeSection {
  @override
  @ContentType('code-dart', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}
