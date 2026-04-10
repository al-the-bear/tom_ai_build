import '../annotations/content_type.dart';

/// A language-agnostic code block section.
class CodeSection {
  @ContentType('code', 'The description for the content is provided by the doc-comment on the field declaration of this type')
  String? content;
}
