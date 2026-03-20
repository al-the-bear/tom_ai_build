import 'package:test/test.dart';
import 'package:tom_doc_specs/src/markers/insert_markers.dart';

void main() {
  group('InsertMarkerParser', () {
    late InsertMarkerParser parser;

    setUp(() {
      parser = InsertMarkerParser();
    });

    test('parses single marker region', () {
      const text = '''Line 1
<!--\$insert:chat.lastReply-->
Old content here
<!--\$end-insert-->
Line 5''';

      final markers = parser.parse(text);
      expect(markers, hasLength(1));
      expect(markers[0].variable, 'chat.lastReply');
      expect(markers[0].startLine, 2);
      expect(markers[0].endLine, 4);
      expect(markers[0].content, 'Old content here');
    });

    test('parses multiple marker regions', () {
      const text = '''<!--\$insert:meta.timestamp-->
2025-01-01
<!--\$end-insert-->
Some text
<!--\$insert:chat.lastReply-->
AI response
More response
<!--\$end-insert-->''';

      final markers = parser.parse(text);
      expect(markers, hasLength(2));
      expect(markers[0].variable, 'meta.timestamp');
      expect(markers[0].content, '2025-01-01');
      expect(markers[1].variable, 'chat.lastReply');
      expect(markers[1].content, 'AI response\nMore response');
    });

    test('parses empty content', () {
      const text = '''<!--\$insert:meta.model-->
<!--\$end-insert-->''';

      final markers = parser.parse(text);
      expect(markers, hasLength(1));
      expect(markers[0].content, '');
    });

    test('supports various variable names', () {
      for (final varName in ['chat.lastReply', 'meta.timestamp', 'section.id', 'a1.b2.c3']) {
        final text = '<!--\$insert:$varName-->\n<!--\$end-insert-->';
        final markers = parser.parse(text);
        expect(markers, hasLength(1));
        expect(markers[0].variable, varName);
      }
    });

    test('throws on nested markers', () {
      const text = '''<!--\$insert:a-->
<!--\$insert:b-->
<!--\$end-insert-->
<!--\$end-insert-->''';

      expect(() => parser.parse(text), throwsFormatException);
    });

    test('throws on unclosed marker', () {
      const text = '''<!--\$insert:chat.lastReply-->
Content without end marker''';

      expect(() => parser.parse(text), throwsFormatException);
    });

    test('throws on end marker without start', () {
      const text = '''Some text
<!--\$end-insert-->''';

      expect(() => parser.parse(text), throwsFormatException);
    });

    test('returns empty list for text without markers', () {
      const text = '''# Document
Regular content here
No markers present''';

      final markers = parser.parse(text);
      expect(markers, isEmpty);
    });

    test('ignores markers with spaces (strict syntax)', () {
      const text = '''<!-- \$insert:chat.lastReply -->
Content
<!-- \$end-insert -->''';

      // Spacious markers should not match; no markers returned, no error
      final markers = parser.parse(text);
      expect(markers, isEmpty);
    });
  });

  group('InsertMarkerProcessor', () {
    late InsertMarkerProcessor processor;

    setUp(() {
      processor = InsertMarkerProcessor();
    });

    test('replaces content in single marker', () {
      const input = '''Before
<!--\$insert:chat.lastReply-->
Old content
<!--\$end-insert-->
After''';

      final result = processor.process(input, {
        'chat.lastReply': 'New content',
      });

      expect(result, '''Before
<!--\$insert:chat.lastReply-->
New content
<!--\$end-insert-->
After''');
    });

    test('replaces content in multiple markers', () {
      const input = '''<!--\$insert:meta.timestamp-->
2025-01-01
<!--\$end-insert-->
Middle
<!--\$insert:chat.lastReply-->
Old reply
<!--\$end-insert-->''';

      final result = processor.process(input, {
        'meta.timestamp': '2025-06-15',
        'chat.lastReply': 'New reply here',
      });

      expect(result, '''<!--\$insert:meta.timestamp-->
2025-06-15
<!--\$end-insert-->
Middle
<!--\$insert:chat.lastReply-->
New reply here
<!--\$end-insert-->''');
    });

    test('keeps unchanged markers with original content', () {
      const input = '''<!--\$insert:chat.lastReply-->
Keep this
<!--\$end-insert-->''';

      final result = processor.process(input, {
        'other.variable': 'This should not affect anything',
      });

      expect(result, input);
    });

    test('handles empty replacement content', () {
      const input = '''<!--\$insert:chat.lastReply-->
Old content
<!--\$end-insert-->''';

      final result = processor.process(input, {
        'chat.lastReply': '',
      });

      expect(result, '''<!--\$insert:chat.lastReply-->
<!--\$end-insert-->''');
    });

    test('handles multi-line replacement', () {
      const input = '''<!--\$insert:chat.lastReply-->
old
<!--\$end-insert-->''';

      final result = processor.process(input, {
        'chat.lastReply': 'Line 1\nLine 2\nLine 3',
      });

      expect(result, '''<!--\$insert:chat.lastReply-->
Line 1
Line 2
Line 3
<!--\$end-insert-->''');
    });

    test('returns unchanged text when no markers present', () {
      const input = 'No markers here';
      final result = processor.process(input, {'any': 'value'});
      expect(result, input);
    });

    test('parse convenience method works', () {
      const text = '''<!--\$insert:chat.lastReply-->
Content
<!--\$end-insert-->''';

      final markers = processor.parse(text);
      expect(markers, hasLength(1));
      expect(markers[0].variable, 'chat.lastReply');
    });
  });
}
