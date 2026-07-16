import 'package:test/test.dart';
import 'package:tom_doc_specs/src/models/schema/doc_spec_schema.dart';
import 'package:tom_doc_specs/src/skeleton/skeleton_generator.dart';

/// Builds a schema with a linear chain of required section types
/// t1 -> t2 -> ... -> t[count], rooted at a single document section of
/// type t1.
DocSpecSchema _chainSchema(int count) {
  final sectionTypes = <String, dynamic>{};
  for (var i = 1; i <= count; i++) {
    sectionTypes['t$i'] = <String, dynamic>{
      'prefix': 't$i',
      if (i < count)
        'subsection-types': <String, dynamic>{
          't${i + 1}': <String, dynamic>{'required': true, 'min-count': 1},
        },
    };
  }
  return DocSpecSchema.fromYaml(
    {
      'section-types': sectionTypes,
      'document': {
        'sections': {
          'root': {'section-type': 't1'},
        },
      },
    },
    id: 'chain-test',
    version: '1.0',
  );
}

void main() {
  group('DocSpecsSkeletonGenerator', () {
    test('generates all six levels for a 6-deep chain', () {
      final md = DocSpecsSkeletonGenerator.generate(_chainSchema(6));

      for (var level = 1; level <= 6; level++) {
        expect(md, contains('\n${'#' * level} '),
            reason: 'level $level heading missing');
      }
    });

    test('generates headings beyond level 6 (uncapped nesting, YRD2)', () {
      final md = DocSpecsSkeletonGenerator.generate(_chainSchema(9));

      for (var level = 1; level <= 9; level++) {
        expect(md, contains('\n${'#' * level} '),
            reason: 'level $level heading missing');
      }
      // No spurious deeper level.
      expect(md, isNot(contains('\n${'#' * 10} ')));
    });

    test('self-recursive section type terminates via cycle guard', () {
      final schema = DocSpecSchema.fromYaml(
        {
          'section-types': {
            'node': {
              'prefix': 'node',
              'subsection-types': {
                'node': {'required': true, 'min-count': 1},
              },
            },
          },
          'document': {
            'sections': {
              'root': {'section-type': 'node'},
            },
          },
        },
        id: 'cycle-test',
        version: '1.0',
      );

      // Must terminate (no infinite recursion) and emit the type once.
      final md = DocSpecsSkeletonGenerator.generate(schema);
      expect('# '.allMatches(md).length, greaterThanOrEqualTo(1));
      expect(md, contains('\n# '));
      expect(md, isNot(contains('\n## ')));
    });

    test('mutually recursive section types terminate via cycle guard', () {
      final schema = DocSpecSchema.fromYaml(
        {
          'section-types': {
            'a': {
              'prefix': 'a',
              'subsection-types': {
                'b': {'required': true, 'min-count': 1},
              },
            },
            'b': {
              'prefix': 'b',
              'subsection-types': {
                'a': {'required': true, 'min-count': 1},
              },
            },
          },
          'document': {
            'sections': {
              'root': {'section-type': 'a'},
            },
          },
        },
        id: 'mutual-cycle-test',
        version: '1.0',
      );

      final md = DocSpecsSkeletonGenerator.generate(schema);
      // a -> b, then the guard stops the a recursion: exactly 2 levels.
      expect(md, contains('\n# '));
      expect(md, contains('\n## '));
      expect(md, isNot(contains('\n### ')));
    });
  });
}
