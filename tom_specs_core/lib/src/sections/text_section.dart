import '../annotations/content_type.dart';

/// A free-text section that may contain narrative, diagrams, or references.
@ContentType('text')
class TextSection {
  String? content;
}
