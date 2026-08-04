import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// Covers `lib/src/outline_writer.dart` and the `tom_specs_model_rules.md` §11
/// specification of it.
///
/// Two halves, for two different ways §11 went stale at once.
///
/// **The excerpt guard** is the one that would have caught the drift. §11.4's
/// worked sample was hand-written in a notation the outliner had stopped
/// emitting — `->` / `-:` arrows, 4-space indents, a bare comma list of form
/// fields — and named classes the model no longer has. Nothing compared it to a
/// real run, so a reader checking their own output against it concluded their
/// run was wrong. Any fenced block introduced by an
/// `<!-- outline-excerpt: FILE -->` marker is now asserted to be a *contiguous*
/// substring of that
/// generated outline, so an excerpt cannot restate generated output inaccurately
/// -- it either is that output or the suite is red.
///
/// **The notation cases** cover the rules §11.2 states that the current model
/// never exercises: the model declares no enum member and uses no `@Position`,
/// `@ForEach`, `@TextRequired` or `@Max` anywhere, so those renderings appear in
/// no committed outline and the excerpt guard cannot reach them. They are
/// exactly the claims that rotted -- a documented rendering with no live example
/// and no test is a guess about one's own code. Fixtures are built by hand
/// rather than read from the model precisely so they keep testing the notation
/// after the model moves on.
void main() {
  final clitoolRoot = Directory.current.path;
  final modelRoot = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model'));

  group('doc excerpts are cut from generated output, not restated', () {
    final docsDir = Directory(p.join(modelRoot, 'doc'));
    final outlinesDir = p.join(modelRoot, 'generated-doc', 'outlines');

    // `<!-- outline-excerpt: File_outline.md -->` followed by a fenced block.
    final marker = RegExp(
      r'<!--\s*outline-excerpt:\s*(?<file>[\w.]+)\s*-->\s*\n'
      r'```[^\n]*\n(?<body>.*?)\n```',
      dotAll: true,
    );

    final docs = docsDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    test('at least one excerpt is pinned, so the guard is not vacuous', () {
      final total = docs.fold<int>(
        0,
        (n, f) => n + marker.allMatches(f.readAsStringSync()).length,
      );
      expect(total, greaterThan(0),
          reason: 'no `<!-- outline-excerpt: ... -->` marker found in '
              '${docsDir.path} -- the guard below would pass by checking '
              'nothing. An absent anchor is a finding, not a pass.');
    });

    for (final doc in docs) {
      final text = doc.readAsStringSync();
      for (final m in marker.allMatches(text)) {
        final file = m.namedGroup('file')!;
        final body = m.namedGroup('body')!;
        final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;

        test('${p.basename(doc.path)}:$line quotes $file verbatim', () {
          final source = File(p.join(outlinesDir, file));
          expect(source.existsSync(), isTrue,
              reason: 'excerpt names $file, which does not exist in '
                  '$outlinesDir');

          final generated = source.readAsStringSync();
          if (generated.contains(body)) return;

          // Locate the first line that diverges, so the failure names the
          // drift rather than dumping two documents at the reader.
          final wanted = body.split('\n');
          final got = generated.split('\n');
          final anchor = got.indexOf(wanted.first);
          final detail = anchor < 0
              ? 'its first line is not in $file at all:\n  ${wanted.first}'
              : () {
                  for (var i = 0; i < wanted.length; i++) {
                    final at = anchor + i;
                    final actual = at < got.length ? got[at] : '<end of file>';
                    if (actual != wanted[i]) {
                      return 'first divergence at excerpt line ${i + 1} '
                          '($file line ${at + 1}):\n'
                          '  doc:       ${wanted[i]}\n'
                          '  generated: $actual';
                    }
                  }
                  return 'excerpt is a prefix but not contiguous';
                }();

          fail('the excerpt in ${p.basename(doc.path)} is not a verbatim cut '
              'of $file -- re-cut it from the regenerated outline rather than '
              'editing it by hand.\n$detail');
        });
      }
    }
  });

  group('notation the model does not exercise (rules §11.2)', () {
    /// Renders [cls] as the whole outline and returns the body under the title.
    String render(
      String root,
      Map<String, ModelClass> classes, {
      bool showSchemaAnnotations = false,
      int maxLineLength = 120,
    }) {
      final out = OutlineWriter(
        classes: classes,
        showSchemaAnnotations: showSchemaAnnotations,
        maxLineLength: maxLineLength,
      ).generate(root);
      // Drop the `# <Title> Outline` heading and the blank line after it.
      return out.split('\n').skip(2).join('\n').trimRight();
    }

    ModelField leaf(String name) => ModelField(name: name, typeName: 'String');

    test('leaf members share one bullet, indented two spaces per level', () {
      final body = render('Root', {
        'Root': ModelClass(
          name: 'Root',
          fields: [leaf('content'), leaf('summary')],
        ),
      });
      expect(body, '  - content, summary');
    });

    test('an enum member renders `name: Type (values)` inline (§11.2.5)', () {
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          leaf('content'),
          ModelField(
            name: 'priority',
            typeName: 'Priority',
            isEnum: true,
            enumValues: ['must', 'should', 'could'],
          ),
        ]),
      });
      expect(body, '  - content, priority: Priority (must, should, could)');
    });

    test('@TextRequired marks the content member `content!` (§11.2.13)', () {
      final body = render('Root', {
        'Root': ModelClass(
          name: 'Root',
          fields: [leaf('content')],
          annotations: [AnnotationData('TextRequired')],
        ),
      });
      expect(body, '  - content!');
    });

    test('@Min/@Max render as a `[min,max]` tag before the name (§11.2.3)', () {
      ModelField list(String name, List<AnnotationData> annotations) =>
          ModelField(
            name: name,
            typeName: 'List<Item>',
            isList: true,
            listElementTypeName: 'Item',
            annotations: annotations,
          );

      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          list('unbounded', []),
          list('atLeastOne', [AnnotationData('Min', {'count': 1})]),
          list('atMostFive', [AnnotationData('Max', {'count': 5})]),
          list('between', [
            AnnotationData('Min', {'count': 1}),
            AnnotationData('Max', {'count': 5}),
          ]),
        ]),
      });

      expect(body.split('\n'), [
        '  - unbounded: `Item`[]',
        '  - [1,] atLeastOne: `Item`[]',
        '  - [,5] atMostFive: `Item`[]',
        '  - [1,5] between: `Item`[]',
      ]);
    });

    test('@Position shows only non-default values (§11.2.11)', () {
      ModelField positioned(String name, String position) => ModelField(
            name: name,
            typeName: 'List<Item>',
            isList: true,
            listElementTypeName: 'Item',
            annotations: [
              AnnotationData('Position', {'position': position})
            ],
          );

      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          positioned('preamble', 'first'),
          positioned('items', 'relative'),
          positioned('appendices', 'last'),
        ]),
      });

      expect(body.split('\n'), [
        '  - preamble: `Item`[] [first]',
        '  - items: `Item`[]',
        '  - appendices: `Item`[] [last]',
      ]);
    });

    test('@ForEach renders the registry key with ⟷ (§11.2.12)', () {
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(
            name: 'implementations',
            typeName: 'List<Item>',
            isList: true,
            listElementTypeName: 'Item',
            annotations: [
              AnnotationData('ForEach', {
                'registryType': 'PRIDN',
                'key': 'processId',
              })
            ],
          ),
        ]),
      });
      expect(body, '  - implementations: `Item`[] ⟷ PRIDN.processId');
    });

    test('@Comment appends `← (text)` with no column padding (§11.2.10)', () {
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(
            name: 'systems',
            typeName: 'List<Item>',
            isList: true,
            listElementTypeName: 'Item',
            annotations: [
              AnnotationData('Comment', {'text': 'seeded'})
            ],
          ),
        ]),
      });
      expect(body, '  - systems: `Item`[] ← (seeded)');
    });

    test('@Reference shows both names, is not followed (§11.2.9)', () {
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(
            name: 'basedOn',
            typeName: 'Requirement',
            annotations: [
              AnnotationData('Reference', {'description': 'Source System'})
            ],
          ),
        ]),
        // Would be expanded if the reference were followed.
        'Requirement':
            ModelClass(name: 'Requirement', fields: [leaf('content')]),
      });
      expect(body, '  - basedOn: `Requirement` (ref: Source System)');
    });

    test('schema-only annotations are HTML comments, between the class line '
        'and its members, at the class line indent (§11.2.14)', () {
      final body = render(
        'Root',
        {
          'Root': ModelClass(
            name: 'Root',
            fields: [ModelField(name: 'general', typeName: 'Settings')],
          ),
          'Settings': ModelClass(
            name: 'Settings',
            fields: [leaf('content')],
            annotations: [
              AnnotationData('Prefix', {'prefix': 'CSA-SYS'}),
              AnnotationData('MaxDepth', {'depth': 2}),
              // Visible-elsewhere annotations must not leak in here.
              AnnotationData('SectionId', {'id': 'ROOT'}),
            ],
          ),
        },
        showSchemaAnnotations: true,
      );

      // The annotation lines align with the class line they annotate, so they
      // sit one level *out* from the members below them -- which is what makes
      // them readable as belonging to the class rather than to a member.
      expect(body.split('\n'), [
        '  - general: `Settings`',
        "  <!-- @Prefix('CSA-SYS') -->",
        '  <!-- @MaxDepth(2) -->',
        '    - content',
      ]);
    });

    test('member-level schema annotations name their target, at the leaf '
        'bullet indent (§11.2.14)', () {
      final body = render(
        'Root',
        {
          'Root': ModelClass(name: 'Root', fields: [
            ModelField(name: 'record', typeName: 'Entry'),
          ]),
          'Entry': ModelClass(name: 'Entry', fields: [
            ModelField(
              name: 'content',
              typeName: 'String',
              annotations: [AnnotationData('MinLength', {'length': 50})],
            ),
            ModelField(
              name: 'systemName',
              typeName: 'String',
              annotations: [
                AnnotationData('AccessKey', {'key': 'systemName'})
              ],
            ),
          ]),
        },
        showSchemaAnnotations: true,
      );

      // Leaf members share one bullet, so an annotation cannot be positioned
      // against an individual member -- it names its target instead.
      expect(body.split('\n'), [
        '  - record: `Entry`',
        '    <!-- @MinLength(50) content -->',
        "    <!-- @AccessKey('systemName') systemName -->",
        '    - content, systemName',
      ]);
    });

    test('a list is marked `[]`, so it cannot be read as a singular member '
        '(§11.2.3)', () {
      // The case the notation used to lose. A singular member whose name does
      // not match its type, and an unconstrained list of that same type, both
      // rendered as ``- name: `Entry` `` -- only a plural name hinted at the
      // difference, and that is a convention, not something a reader can rely
      // on. §11.2.3 calls the list member name structurally significant (a
      // section level, each item a subsection) while a singular member is one
      // section, so this was eliding exactly the distinction it called
      // significant.
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(name: 'header', typeName: 'Entry'),
          ModelField(
            name: 'revisionHistory',
            typeName: 'List<Entry>',
            isList: true,
            listElementTypeName: 'Entry',
            listElementIsComplex: true,
          ),
        ]),
        'Entry': ModelClass(name: 'Entry', fields: [leaf('content')]),
      });

      expect(body.split('\n'), [
        '  - header: `Entry`',
        '    - content',
        '  - revisionHistory: `Entry`[]',
        '    - content',
      ]);
    });

    test('a list of a leaf type is marked `[]` as well (§11.2.3)', () {
      // `List<String>` is still a list, and the `[]` is what says so. It is
      // not followed, so without the marker the line is a bare backticked
      // type with nothing under it -- readable as a singular member of an
      // unexpanded class.
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          leaf('content'),
          ModelField(
            name: 'relatedPainPoints',
            typeName: 'List<String>',
            isList: true,
            listElementTypeName: 'String',
          ),
        ]),
      });

      expect(body.split('\n'), [
        '  - content',
        '  - relatedPainPoints: `String`[]',
      ]);
    });

    test('`[]` marks list-ness, `[min,max]` bounds it -- the two are '
        'independent (§11.2.3)', () {
      // The `[]` suffix is unconditional, so it does not compete with the
      // bounds tag for the job of announcing a list. A reader scans for `[]`
      // to find every list; the bracket tag then says how many, when the
      // model constrains it.
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(
            name: 'unbounded',
            typeName: 'List<Item>',
            isList: true,
            listElementTypeName: 'Item',
          ),
          ModelField(
            name: 'bounded',
            typeName: 'List<Item>',
            isList: true,
            listElementTypeName: 'Item',
            annotations: [AnnotationData('Min', {'count': 1})],
          ),
        ]),
      });

      expect(body.split('\n'), [
        '  - unbounded: `Item`[]',
        '  - [1,] bounded: `Item`[]',
      ]);
    });

    test('`[]` sits on the type, ahead of every trailing annotation '
        '(§11.2.3)', () {
      // The marker belongs to the type -- the member is "many Item" -- so it
      // binds tighter than @Comment/@Position/@ForEach, which describe the
      // member. Placing it outside the backticks keeps the backticked span
      // exactly the class name, so a reader (or a grep) can still lift a type
      // name out of an outline.
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(
            name: 'systems',
            typeName: 'List<Item>',
            isList: true,
            listElementTypeName: 'Item',
            annotations: [
              AnnotationData('Comment', {'text': 'seeded'}),
              AnnotationData('Position', {'position': 'last'}),
              AnnotationData('ForEach', {
                'registryType': 'PRIDN',
                'key': 'processId',
              }),
            ],
          ),
        ]),
      });

      expect(body, '  - systems: `Item`[] ← (seeded) [last] ⟷ PRIDN.processId');
    });

    test('the name-match rule drops a redundant member name (§11.2.2)', () {
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(name: 'systemOverview', typeName: 'SystemOverview'),
          ModelField(name: 'header', typeName: 'DocumentHeader'),
        ]),
        'SystemOverview':
            ModelClass(name: 'SystemOverview', fields: [leaf('content')]),
        'DocumentHeader':
            ModelClass(name: 'DocumentHeader', fields: [leaf('content')]),
      });

      expect(body.split('\n'), [
        '  - `SystemOverview`',
        '    - content',
        '  - header: `DocumentHeader`',
        '    - content',
      ]);
    });

    test('nullability is stripped, not shown (§11.2.7)', () {
      // §11.2.7 long claimed the opposite -- that `Type?` renders with its
      // question mark. It does not, and never could distinguish the two: the
      // writer strips `?` from the type name, and a leaf renders as its bare
      // field name. Pinned so the claim cannot be reinstated unnoticed.
      final body = render('Root', {
        'Root': ModelClass(name: 'Root', fields: [
          ModelField(name: 'required', typeName: 'String'),
          ModelField(name: 'optional', typeName: 'String?'),
          ModelField(name: 'maybeChild', typeName: 'Child?'),
        ]),
        'Child': ModelClass(name: 'Child', fields: [leaf('content')]),
      });

      expect(body.split('\n'), [
        '  - required, optional',
        '  - maybeChild: `Child`',
        '    - content',
      ]);
    });

    test('@Unused and @SectionId are not rendered at all (§11.2.13)', () {
      final body = render('Root', {
        'Root': ModelClass(
          name: 'Root',
          fields: [leaf('content')],
          annotations: [
            AnnotationData('SectionId', {'id': 'ROOT'}),
            AnnotationData('Unused', const {}),
          ],
        ),
      });
      expect(body, '  - content');
    });

    test('a long leaf line wraps one level deeper, commas kept at line end '
        '(§11.2.4)', () {
      final body = render(
        'Root',
        {
          'Root': ModelClass(
            name: 'Root',
            fields: [leaf('alpha'), leaf('bravo'), leaf('charlie')],
          ),
        },
        maxLineLength: 22,
      );

      expect(body.split('\n'), [
        '  - alpha, bravo,',
        '    charlie',
      ]);
    });
  });
}
