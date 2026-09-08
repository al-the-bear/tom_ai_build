/// A section id may sit in an HTML comment on the line *after* its heading.
///
/// Both placements are used in practice and both are documented, but only the
/// in-heading form was read. The following-line form fell back to an id derived
/// from the heading text, and that failure is silent in the worst way: the
/// section still scans, it just carries a different id. Whether anything
/// noticed depended on luck of naming — `## Introduction` derives `introduction`
/// which happens to start with the prefix `intro`, so it resolved; `## Overview`
/// derives `overview`, which does not start with `note`, so it did not.
library;

import 'package:test/test.dart';
import 'package:tom_doc_scanner/src/markdown_parser.dart';

/// The single parsed headline of [md], which must contain exactly one.
ParsedHeadline only(String md) {
  final parsed = MarkdownParser.parseHeadlines(md);
  expect(parsed, hasLength(1), reason: 'fixture must hold one headline');
  return parsed.single.$1;
}

void main() {
  group('FLI1: the following-line form is read', () {
    test('an id on the next line is the section id', () {
      expect(
        only('## Overview\n<!--[note-001] -->\n\nBody.\n').explicitId,
        'note-001',
      );
    });

    test('it agrees with the in-heading form for the same document', () {
      // The property that matters: placement must not change the id.
      final inHeading = only('## <!--[note-001] --> Overview\n\nBody.\n');
      final following = only('## Overview\n<!--[note-001] -->\n\nBody.\n');
      expect(following.explicitId, inHeading.explicitId);
      expect(following.text, inHeading.text);
    });

    test('key=value fields on that line are read too', () {
      // The in-heading form parses them, so the following-line form must, or
      // the two placements would differ in what they carry rather than only in
      // where they sit.
      final h = only(
        '## Auth\n<!--[comp-auth] component-id=auth, targets=web -->\n',
      );
      expect(h.explicitId, 'comp-auth');
      expect(h.fields['component-id'], 'auth');
    });

    test('a following comment with no id leaves the id underived', () {
      final h = only('## Overview\n<!-- just a note -->\n\nBody.\n');
      expect(h.explicitId, isNull);
    });
  });

  group('FLI2: what it must not swallow', () {
    test('the in-heading form still wins over a following line', () {
      // Two ids is a malformed document; the heading is the more specific
      // placement, so it takes precedence rather than being overwritten.
      expect(
        only(
          '## <!--[in-heading] --> Overview\n<!--[following] -->\n',
        ).explicitId,
        'in-heading',
      );
    });

    test(
      'a blank line between heading and comment is not the following line',
      () {
        // Deliberately strict: the rule is "the next line", so a comment further
        // down belongs to the body. A generous scan could swallow a comment that
        // is part of the content.
        expect(only('## Overview\n\n<!--[note-001] -->\n').explicitId, isNull);
      },
    );

    test('a comment on the line before a heading is not read', () {
      final parsed = MarkdownParser.parseHeadlines(
        '<!--[note-001] -->\n## Overview\n\nBody.\n',
      );
      expect(parsed.single.$1.explicitId, isNull);
    });

    test('the next line being another heading is not consumed', () {
      final parsed = MarkdownParser.parseHeadlines(
        '## Overview\n### Detail\n\nBody.\n',
      );
      expect(parsed, hasLength(2));
      expect(parsed[0].$1.explicitId, isNull);
      expect(parsed[1].$1.explicitId, isNull);
    });

    test('a bracket in ordinary prose on the next line is not an id', () {
      // Only an HTML comment carries metadata; `[x]` in prose is a link or a
      // citation, and reading it would invent ids from body text.
      expect(only('## Overview\nSee [1] for details.\n').explicitId, isNull);
    });
  });
}
