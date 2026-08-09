/// Unit coverage for the portable pattern subset (SOM §9).
///
/// The nine-language contract is pinned by the shared corpus
/// (`query_cases.json`); this file pins the *reference's* behaviour at a
/// finer grain than a query table can — the empty-match advance rule, greedy
/// give-back, ASCII-only folding, and each compile rejection — so a change to
/// the matcher fails here with a pointed message before it fails eight ports
/// with a diff of query results.
library;

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

List<List<int>> spans(String pattern, String text,
        {bool caseInsensitive = false}) =>
    SomTextPattern.compile(pattern, caseInsensitive: caseInsensitive)
        .allMatches(text)
        .map((s) => [s.start, s.end])
        .toList();

void main() {
  group('STP1: literal patterns are uninterpreted [2026-08-09]', () {
    test('metacharacters in a literal match themselves', () {
      final p = SomTextPattern.literal('a.c');
      expect(p.allMatches('a.c abc').map((s) => [s.start, s.end]), [
        [0, 3]
      ]);
    });

    test('a literal finds every non-overlapping occurrence', () {
      final p = SomTextPattern.literal('aa');
      expect(p.allMatches('aaaa').map((s) => [s.start, s.end]), [
        [0, 2],
        [2, 4]
      ]);
    });

    test('overlapping occurrences are not both reported', () {
      final p = SomTextPattern.literal('aba');
      expect(p.allMatches('ababa').map((s) => [s.start, s.end]), [
        [0, 3]
      ]);
    });

    test('an empty literal matches at every position including the end', () {
      final p = SomTextPattern.literal('');
      expect(p.allMatches('ab').map((s) => [s.start, s.end]), [
        [0, 0],
        [1, 1],
        [2, 2]
      ]);
    });
  });

  group('STP2: the compiled grammar [2026-08-09]', () {
    test('. matches any single character', () {
      expect(spans('a.c', 'abc adc a c'), [
        [0, 3],
        [4, 7],
        [8, 11]
      ]);
    });

    test('* is greedy and gives back until the tail fits', () {
      expect(spans('a.*c', 'abcxxc'), [
        [0, 6]
      ]);
    });

    test('+ requires at least one', () {
      expect(spans('ab+', 'a ab abb'), [
        [2, 4],
        [5, 8]
      ]);
    });

    test('? is optional and prefers the longer match', () {
      expect(spans('ab?c', 'ac abc'), [
        [0, 2],
        [3, 6]
      ]);
    });

    test('a character class matches its members and ranges', () {
      expect(spans('[a-c1]x', 'ax bx cx dx 1x'), [
        [0, 2],
        [3, 5],
        [6, 8],
        [12, 14]
      ]);
    });

    test('a negated class excludes its members', () {
      expect(spans('[^abc]', 'abcd'), [
        [3, 4]
      ]);
    });

    test('a ] straight after [ is a literal ]', () {
      expect(spans('[]a]', ']a'), [
        [0, 1],
        [1, 2]
      ]);
    });

    test('a trailing - inside a class is a literal -', () {
      expect(spans('[a-]', 'a-'), [
        [0, 1],
        [1, 2]
      ]);
    });

    test('anchors bind to the whole text, not to a line', () {
      expect(spans('^a', 'aa'), [
        [0, 1]
      ]);
      expect(spans(r'a$', 'aa'), [
        [1, 2]
      ]);
      expect(spans(r'^ab$', 'ab'), [
        [0, 2]
      ]);
      expect(spans(r'^a$', 'a\na'), isEmpty);
    });

    test('a backslash escapes a metacharacter', () {
      expect(spans(r'a\.c', 'a.c abc'), [
        [0, 3]
      ]);
    });

    test('alternation and group characters are ordinary literals', () {
      // Outside the grammar, but text really does contain parentheses and
      // pipes, so a literal reading is the useful one.
      expect(spans('a|b', 'a|b'), [
        [0, 3]
      ]);
      expect(spans('(a)', '(a)'), [
        [0, 3]
      ]);
    });
  });

  group('STP3: case-insensitive matching folds ASCII only [2026-08-09]', () {
    test('literals fold both directions', () {
      expect(spans('abc', 'ABC', caseInsensitive: true), [
        [0, 3]
      ]);
      expect(spans('ABC', 'abc', caseInsensitive: true), [
        [0, 3]
      ]);
    });

    test('a class range admits the other case of its members', () {
      expect(spans('[a-z]+', 'ABC', caseInsensitive: true), [
        [0, 3]
      ]);
      expect(spans('[A-Z]+', 'abc', caseInsensitive: true), [
        [0, 3]
      ]);
    });

    test('non-ASCII is not folded', () {
      // Deliberate: the nine standard libraries disagree about Unicode case
      // folding, so the contract stops at ASCII.
      expect(spans('ä', 'Ä', caseInsensitive: true), isEmpty);
    });
  });

  group('STP5: offsets are UTF-16 code units [2026-08-09]', () {
    // Spans are contract, so what they count has to be too. Every plausible
    // alternative — UTF-8 bytes, code points, grapheme clusters — agrees with
    // code units across ASCII and disagrees somewhere past it, so only
    // non-ASCII text can tell them apart.
    test('a multi-byte BMP character counts as one unit, not its bytes', () {
      expect(spans('x', 'äöü-x'), [
        [4, 5]
      ]); // byte indexing would say 7
    });

    test('an astral character counts as two units, not one code point', () {
      expect(spans('x', '𝄞-x'), [
        [3, 4]
      ]); // code-point indexing would say 2
    });

    test('. matches one code unit, so a surrogate pair matches twice', () {
      // Unlovely but forced: if offsets are code units then so is the unit `.`
      // consumes. Pinned because walking characters is the natural reading in
      // several of the ported languages.
      expect(spans('.', '𝄞'), [
        [0, 1],
        [1, 2]
      ]);
    });

    test('an astral literal in the pattern matches its own surrogate pair', () {
      expect(spans('𝄞', 'a𝄞b'), [
        [1, 3]
      ]);
    });
  });

  group('STP4: a malformed pattern is rejected at compile [2026-08-09]', () {
    void rejects(String pattern) {
      expect(() => SomTextPattern.compile(pattern),
          throwsA(isA<SomPatternError>()),
          reason: 'compile("$pattern") should not silently match nothing');
    }

    test('a quantifier with nothing to repeat', () => rejects('*a'));
    test('a quantifier on a start anchor', () => rejects('^*'));
    test('a quantifier on an end anchor', () => rejects(r'$?'));
    test('an unterminated character class', () => rejects('[abc'));
    test('a backwards class range', () => rejects('[z-a]'));
    test('a dangling escape', () => rejects('ab\\'));
    test('a dangling escape inside a class', () => rejects('[a\\'));

    test('a character-class shorthand is refused, not read as a literal', () {
      // The trap this rule exists for: `slip\w+` silently meaning "slip then
      // one or more w" matches nothing and reports nothing.
      for (final p in [r'\w', r'\d', r'\s', r'\b', r'\n', r'\1', r'slip\w+']) {
        rejects(p);
      }
    });

    test('escaping a non-alphanumeric still writes it literally', () {
      expect(spans(r'\(a\)', '(a)'), [
        [0, 3]
      ]);
      expect(spans(r'[\.\*]', '.*a'), [
        [0, 1],
        [1, 2]
      ]);
    });

    test('the error names the pattern and the reason', () {
      expect(
          () => SomTextPattern.compile('[z-a]'),
          throwsA(isA<SomPatternError>()
              .having((e) => e.pattern, 'pattern', '[z-a]')
              .having((e) => e.message, 'message', contains('backwards'))));
    });
  });
}
