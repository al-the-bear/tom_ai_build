import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// A spec model whose fields are named after every structural accessor, in both
/// a plain section and a `@Form` section — or, with [safe] set, the same model
/// with names that cannot collide with anything.
///
/// The two are generated as a matched pair: identical shape, identical field
/// count and kinds, differing only in the names. That is what lets a test tell
/// a **field-derived** accessor apart from an emitter's own deliberate
/// structural emission (every facade emits `canHaveContent`, for instance), by
/// comparing the two outputs rather than pattern-matching intent.
///
/// No real spec-model class carries these names today, which is exactly why the
/// guard needs a fixture: the collision is latent, and a hand-written model is
/// the only way to exercise it before a future model edit does.
Map<String, dynamic> _modelJson({required bool safe}) {
  String named(String name) => safe ? 'zz${_pascal(name)}' : name;
  return {
    'modelVersion': 0,
    'roots': [
      {'type': 'Root', 'title': 'Root', 'sectionId': 'ROOT'},
    ],
    'classes': {
      'Root': {
        'name': 'Root',
        'sectionId': 'ROOT',
        'fields': [
          for (final name in _structuralFieldNames)
            {
              'name': named(name),
              'kind': 'content',
              'sectionId': name.toLowerCase(),
              'contentType': 'text',
            },
          {
            'name': 'form',
            'kind': 'form',
            'sectionId': 'form',
            'formFields': [
              for (final name in _structuralFieldNames)
                {'name': named(name), 'label': name, 'type': 'String'},
            ],
          },
        ],
      },
    },
  };
}

String _pascal(String s) => s[0].toUpperCase() + s.substring(1);

/// The model-field names a spec author could plausibly write that map onto a
/// structural accessor in at least one language.
///
/// Not every one collides in every language, and that is the point of driving
/// the guard from a per-language table rather than one global list: a Python
/// facade member keeps its camelCase model name while the Python structural
/// surface is snake_case (`is_empty`, `spec_headline`), so only `doc` / `path`
/// can collide there; Go pascal-cases to `SectionId`, which is a different
/// identifier from the promoted `SectionID`.
const List<String> _structuralFieldNames = [
  'doc',
  'path',
  'sectionId',
  'headline',
  'codeSpec',
  'isEmpty',
  'canHaveContent',
];

/// Parses the member names declared directly on `SomNode` out of the Dart
/// runtime's `som_facade.dart`.
///
/// Deliberately a source parse rather than reflection: the point is to notice
/// when someone **adds** a member to the reference facade, and a source parse
/// sees the declaration whether or not this package ever calls it.
Set<String> _somNodeMembers() {
  final file = File(p.join(Directory.current.path, '..',
      'tom_som_dart_runtime', 'lib', 'src', 'som_facade.dart'));
  expect(file.existsSync(), isTrue,
      reason: 'the Dart runtime facade must be a sibling package');
  final source = file.readAsStringSync();

  final start = source.indexOf('abstract class SomNode {');
  expect(start, greaterThanOrEqualTo(0),
      reason: 'SomNode must still be declared in som_facade.dart');
  // The class body ends at the first line that is exactly `}` — SomNode holds
  // no nested declarations, so this is unambiguous.
  final bodyEnd = source.indexOf('\n}\n', start);
  expect(bodyEnd, greaterThan(start));
  final body = source.substring(start, bodyEnd);

  final members = <String>{};
  // `final SpecDocument doc;` / `final String path;`
  for (final m
      in RegExp(r'^\s*final\s+\w+\??\s+(\w+);', multiLine: true).allMatches(body)) {
    members.add(m.group(1)!);
  }
  // `bool get isEmpty` / `String? get $headline` / `set $headline(`
  for (final m in RegExp(r'\b(?:get|set)\s+(\$?\w+)').allMatches(body)) {
    members.add(m.group(1)!);
  }
  return members;
}

void main() {
  group('somStructuralAccessorNames', () {
    test('SSA1: has an entry for every member in every language [2026-07-28]',
        () {
      for (final language in SomLanguage.values) {
        final entry = somStructuralAccessorNames[language];
        expect(entry, isNotNull,
            reason: 'language ${language.name} has no structural-accessor '
                'entry — adding a language means recording its facade shape');
        for (final member in SomStructuralMember.values) {
          expect(entry!.containsKey(member), isTrue,
              reason: 'language ${language.name} has no entry for '
                  '${member.name} — an omission and a deliberate "cannot '
                  'collide here" must be told apart, so record the empty list '
                  'explicitly');
        }
        expect(entry!.length, SomStructuralMember.values.length,
            reason: 'language ${language.name} carries an entry for a member '
                'that is no longer in SomStructuralMember');
      }
    });

    test('SSA2: the dart entry agrees with the real SomNode [2026-07-28]', () {
      final declared = _somNodeMembers();
      final tabled = somReservedAccessorNames(SomLanguage.dart);

      // Every name the table claims is structural must really be on SomNode —
      // otherwise the table is over-reserving and renames accessors for nothing.
      for (final name in tabled) {
        expect(declared, contains(name),
            reason: '`$name` is reserved for Dart but is not declared on '
                'SomNode — remove it from the table');
      }
      // …and every member SomNode declares must be reserved. This is the
      // direction that catches the bug the table exists for: a new structural
      // accessor added to the reference facade without updating the table.
      for (final name in declared) {
        expect(tabled, contains(name),
            reason: 'SomNode declares `$name` but the structural-accessor '
                'table does not reserve it — a generated field of that name '
                'would silently shadow it');
      }
    });

    test('SSA3: rust and c record an empty surface deliberately [2026-07-28]',
        () {
      // Rust composes the node (`pub node: SomNode`) and C allocates every
      // function name from one flat deduplicated namespace, so neither can
      // shadow. Pinning this keeps the emptiness a recorded decision: if either
      // facade ever switches to inheritance, this test is the reminder.
      expect(somReservedAccessorNames(SomLanguage.rust), isEmpty);
      expect(somReservedAccessorNames(SomLanguage.c), isEmpty);
    });
  });

  group('emitters honour the structural surface', () {
    final colliding = _emitAll(SpecModel.fromJson(_modelJson(safe: false)));
    final baseline = _emitAll(SpecModel.fromJson(_modelJson(safe: true)));

    test('SSA4: a colliding model adds no structural-named accessor [2026-07-28]',
        () {
      // Every facade emits some structural members of its own — `canHaveContent`
      // is overridden on every content-bearing section, for instance. Counting
      // occurrences in the *baseline* (same model shape, non-colliding names)
      // and requiring the colliding model to match it isolates exactly the
      // field-derived accessors, with no need to guess at intent.
      for (final language in SomLanguage.values) {
        for (final name in somReservedAccessorNames(language)) {
          expect(_countAccessors(colliding[language]!, language, name),
              _countAccessors(baseline[language]!, language, name),
              reason: '${language.name} emits an extra accessor named `$name` '
                  'when a model field carries that name — it shadows the '
                  'structural member instead of being renamed');
        }
      }
    });

    test('SSA5: the collision is resolved, not dropped [2026-07-28]', () {
      // The counterpart to SSA4: an emitter that silently *skipped* a colliding
      // field would also add no structural-named accessor. Dart is the
      // reference implementation, so its exact resolution is pinned here.
      final dart = colliding[SomLanguage.dart]!;
      expect(dart, contains('get doc_'));
      expect(dart, contains('set doc_'));
      expect(dart, contains('get path_'));
      expect(dart, contains('get isEmpty_'));
      expect(dart, contains('get canHaveContent_'));
      // `sectionId` / `headline` / `codeSpec` are `$`-prefixed on the Dart
      // facade, so a model field of that name needs no renaming.
      expect(dart, contains('get sectionId '));
      expect(dart, contains('get headline '));
      expect(dart, contains('get codeSpec '));
      // Every field still round-trips through its own document path, whatever
      // the accessor ended up being called.
      expect(dart, contains(r"doc.content('$path/isempty')"));
    });

    test('SSA6: every language emits one accessor pair per field [2026-07-28]',
        () {
      // The renaming must not collapse two fields onto one accessor, in any
      // language. Comparing generated line counts against the baseline catches
      // a dropped or merged member.
      for (final language in SomLanguage.values) {
        expect(colliding[language]!.split('\n').length,
            baseline[language]!.split('\n').length,
            reason: '${language.name} emits a different number of lines for a '
                'colliding model than for the same model with safe names — a '
                'field was dropped or merged rather than renamed');
      }
    });
  });
}

/// Generates every language's facade source for [model].
Map<SomLanguage, String> _emitAll(SpecModel model) => {
      SomLanguage.dart: SomDartEmitter(model).generateLibrary(),
      SomLanguage.python: SomPythonEmitter(model).generateLibrary(),
      SomLanguage.java: SomJavaEmitter(model).generateLibrary(),
      SomLanguage.javascript: SomJavaScriptEmitter(model).generateLibrary(),
      SomLanguage.typescript: SomTypeScriptEmitter(model).generateLibrary(),
      SomLanguage.go: SomGoEmitter(model).generateLibrary(),
      SomLanguage.rust: SomRustEmitter(model).generateLibrary(),
      // C / C++ split their output; declarations live in the header and
      // definitions in the source, so both are searched.
      SomLanguage.cpp: '${SomCppEmitter(model).generateHeader()}\n'
          '${SomCppEmitter(model).generateSource()}',
      SomLanguage.c: '${SomCEmitter(model).generateHeader()}\n'
          '${SomCEmitter(model).generateSource()}',
    };

/// Counts declarations of an accessor literally named [name] in [source].
///
/// Matches the accessor-declaration shapes each emitter produces, so a mention
/// of the name in a doc comment or a path string is not counted. A sanitised
/// accessor is `<name>_`, which the `\b` boundary excludes.
int _countAccessors(String source, SomLanguage language, String name) {
  final n = RegExp.escape(name);
  final patterns = switch (language) {
    SomLanguage.dart => [r'\b(?:get|set)\s+' + n + r'\b'],
    SomLanguage.python => [r'^\s*def\s+' + n + r'\s*\('],
    SomLanguage.java => [r'\b' + n + r'\s*\('],
    SomLanguage.javascript ||
    SomLanguage.typescript =>
      [r'\b(?:get|set)\s+' + n + r'\s*\('],
    SomLanguage.go => [r'\)\s*' + n + r'\s*\('],
    SomLanguage.cpp => [r'\b' + n + r'\s*\('],
    SomLanguage.rust => [r'\bfn\s+' + n + r'\s*\('],
    SomLanguage.c => [r'\b\w+_' + n + r'\s*\('],
  };
  return patterns
      .map((pat) => RegExp(pat, multiLine: true).allMatches(source).length)
      .fold(0, (a, b) => a + b);
}
