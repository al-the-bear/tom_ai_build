import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// A hand-built spec-model covering every field kind **plus recursion**
/// (`Risk.mitigation: Risk`) and an id-less section (`details`) so the
/// ID-tree hoisting rule is exercised.
Map<String, dynamic> _fixtureJson() => {
      'modelVersion': 0,
      'roots': [
        {
          'type': 'SolutionBlueprint',
          'title': 'Project Definition',
          'sectionId': 'PD00',
          'description': 'The structured project overview.',
        },
      ],
      'classes': {
        'SolutionBlueprint': {
          'name': 'SolutionBlueprint',
          'sectionId': 'PD00',
          'doc': 'Root of a project definition document.',
          'fields': [
            {
              'name': 'vision',
              'kind': 'content',
              'sectionId': 'vision',
              'contentType': 'text',
              'doc': 'Why the system exists.',
            },
            {
              'name': 'owner',
              'kind': 'form',
              'sectionId': 'owner',
              'formFields': [
                {'name': 'name', 'label': 'Name', 'type': 'String'},
                {'name': 'role', 'label': 'Role', 'type': 'String'},
              ],
            },
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'risks',
              'sectionIdPattern': 'RISK-ITEM-xxx',
              'elementType': 'Risk',
              'elementIsComplex': true,
              'min': 2,
            },
            {
              'name': 'tags',
              'kind': 'list',
              'sectionId': 'tags',
              'elementType': 'String',
              'elementIsComplex': false,
            },
            {
              'name': 'situation',
              'kind': 'complex',
              'sectionId': 'situation',
              'type': 'CurrentLandscapeAssessment',
            },
            {
              // Id-less section: the ID-tree hoists through it (its target's
              // id-bearing fields surface at the root, path-prefixed).
              'name': 'details',
              'kind': 'section',
              'type': 'CurrentLandscapeAssessment',
            },
          ],
        },
        'Risk': {
          'name': 'Risk',
          'sectionId': 'RISK',
          'fields': [
            {
              'name': 'title',
              'kind': 'content',
              'sectionId': 'title',
              'contentType': 'text',
            },
            {
              'name': 'probability',
              'kind': 'enum',
              'sectionId': 'prob',
              'enumType': 'Probability',
              'enumValues': ['low', 'medium', 'high'],
            },
            {
              // Recursive: Risk inside Risk — becomes a terminal re-entry.
              'name': 'mitigation',
              'kind': 'complex',
              'sectionId': 'mitigation',
              'type': 'Risk',
            },
          ],
        },
        'CurrentLandscapeAssessment': {
          'name': 'CurrentLandscapeAssessment',
          'sectionId': 'CS00',
          'fields': [
            {
              'name': 'summary',
              'kind': 'content',
              'sectionId': 'summary',
              'contentType': 'text',
            },
          ],
        },
      },
    };

SpecModel _fixtureModel() => SpecModel.fromJson(_fixtureJson());

/// The functional agreement program compiled into the throwaway package: it
/// compares the generated tree against `buildSomMetaTree` (field for field via
/// `somMetaNodeDiff`) and asserts the dot-notation and ID-tree surfaces agree.
const String _checkProgram = r'''
import 'dart:convert';
import 'dart:io';

import 'package:meta_check/generated_meta.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void fail(String msg) {
  stderr.writeln('CHECK FAILED: $msg');
  exit(1);
}

void expectEq(Object? a, Object? b, String what) {
  if (a != b) fail('$what: $a != $b');
}

void main() {
  final fixture = jsonDecode(File('fixture.json').readAsStringSync())
      as Map<String, dynamic>;
  final bridge = buildSomMetaTree(SpecModel.fromJson(fixture));

  // (a) generated tree == bridge tree, field for field.
  final diff = somMetaNodeDiff(solutionBlueprintMetaTree.root, bridge.root);
  if (diff != null) fail('generated tree != bridge tree: $diff');

  // (b) dot-notation paths.
  expectEq(solutionBlueprint.path, 'PD00', 'root path');
  expectEq(solutionBlueprint.vision.path, 'PD00/vision', 'vision path');
  expectEq(solutionBlueprint.owner.path, 'PD00/owner', 'owner path');
  expectEq(solutionBlueprint.risks.path, 'PD00/risks', 'risks path');
  expectEq(solutionBlueprint.risks.item(2).title.path, 'PD00/risks-2/title',
      'list item path');
  expectEq(solutionBlueprint.situation.summary.path, 'PD00/situation/summary',
      'collapsed complex path');
  expectEq(solutionBlueprint.details.summary.path, 'PD00/details/summary',
      'id-less section path');

  // (b) .meta resolves to the same nodes the dynamic lookups find.
  if (!identical(solutionBlueprint.vision.meta,
      solutionBlueprintMetaTree.byPath('PD00/vision'))) {
    fail('vision .meta is not the byPath node');
  }
  expectEq(solutionBlueprint.vision.meta.sectionId, 'vision', 'vision id');
  expectEq(solutionBlueprint.risks.meta.min, 2, 'risks @Min');
  expectEq(solutionBlueprint.risks.meta.sectionIdPattern, 'RISK-ITEM-xxx',
      'risks pattern');
  expectEq(solutionBlueprint.owner.meta.form!.fields.length, 2, 'form fields');

  // (b) recursion: `.path` chains stay valid past the re-entry, `.meta`
  // resolves at the re-entry itself and throws beyond it (DR1 §4.1 cycle
  // rule).
  final mitigation = solutionBlueprint.risks.item(0).mitigation;
  expectEq(mitigation.path, 'PD00/risks-0/mitigation', 'recursive path');
  if (!mitigation.meta.recursive) fail('mitigation node must be recursive');
  final beyond = mitigation.mitigation;
  expectEq(beyond.path, 'PD00/risks-0/mitigation/mitigation',
      'path beyond re-entry');
  var threw = false;
  try {
    beyond.meta;
  } on StateError {
    threw = true;
  }
  if (!threw) fail('.meta beyond a recursive re-entry must throw StateError');

  // (c) ID-tree agrees with dot-notation for every surfaced position.
  expectEq(PD00.path, solutionBlueprint.path, 'root id path');
  expectEq(PD00.vision.path, solutionBlueprint.vision.path, 'vision id path');
  expectEq(PD00.owner.path, solutionBlueprint.owner.path, 'owner id path');
  expectEq(PD00.risks.path, solutionBlueprint.risks.path, 'risks id path');
  expectEq(PD00.risks.item(2).title.path,
      solutionBlueprint.risks.item(2).title.path, 'item id path');
  expectEq(PD00.situation.summary.path,
      solutionBlueprint.situation.summary.path, 'situation id path');
  // Hoisted through the id-less `details` section.
  expectEq(PD00.summary.path, solutionBlueprint.details.summary.path,
      'hoisted id path');
  if (!identical(PD00.vision.meta, solutionBlueprint.vision.meta)) {
    fail('id-tree and dot-notation .meta must be the same node');
  }

  stdout.writeln('OK');
}
''';

void main() {
  group('SomDartMetaEmitter', () {
    late String source;

    setUpAll(() {
      source = SomDartMetaEmitter(_fixtureModel()).generateLibrary();
    });

    test('emits per-root tree, dot-notation and ID-tree entry points', () {
      expect(source,
          contains('final SomMetaTree solutionBlueprintMetaTree = '));
      expect(source, contains(r'final SolutionBlueprint$Nav solutionBlueprint'));
      expect(source, contains(r'final SolutionBlueprint$Id PD00'));
    });

    test('emits one \$Nav class per model class with member-named getters',
        () {
      expect(source, contains(r'class SolutionBlueprint$Nav extends SomMetaRef'));
      expect(source, contains(r'class Risk$Nav extends SomMetaRef'));
      expect(
          source, contains(r'class CurrentLandscapeAssessment$Nav extends'));
      // A list getter is a SomListMetaRef parameterised by the element class.
      expect(source, contains(r'SomListMetaRef<Risk$Nav> get risks'));
      // A scalar list's items are plain refs (no element accessor class).
      expect(source, contains('SomListMetaRef<SomMetaRef> get tags'));
    });

    test('ID-tree getters are named by section id and hoist through id-less '
        'members', () {
      expect(source, contains(r'class SolutionBlueprint$Id extends SomMetaRef'));
      expect(source, contains(r'class Risk$Id extends SomMetaRef'));
      // Hoisted: CurrentLandscapeAssessment.summary surfaces on the root's
      // Id class through the id-less `details` section.
      expect(source, contains(r"$path/details/summary"));
    });

    test('cycle handling emits the _cx re-entry helper and uses it for '
        'complex fields', () {
      expect(source, contains('SomMetaNode _cx('));
      expect(source, contains('if (stack.contains(cls)) return '
          'make(true, const []);'));
      // Risk.mitigation (recursive) goes through _cx like any complex field.
      expect(source, contains("_cx('Risk', s, _mc\$Risk,"));
    });

    test('generated tree == bridge tree; dot-notation and ID-tree agree '
        '(functional)', () async {
      final dir = await Directory.systemTemp.createTemp('som_meta_emit_');
      try {
        final runtimePath = p.normalize(
            p.join(Directory.current.path, '..', 'tom_som_dart_runtime'));
        File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('''
name: meta_check
publish_to: none
environment:
  sdk: ^3.11.4
dependencies:
  tom_som_dart_runtime:
    path: $runtimePath
''');
        final libDir = Directory(p.join(dir.path, 'lib'))..createSync();
        File(p.join(libDir.path, 'generated_meta.dart'))
            .writeAsStringSync(source);
        File(p.join(dir.path, 'fixture.json'))
            .writeAsStringSync(jsonEncode(_fixtureJson()));
        final binDir = Directory(p.join(dir.path, 'bin'))..createSync();
        File(p.join(binDir.path, 'check.dart'))
            .writeAsStringSync(_checkProgram);

        final pubGet = await Process.run('dart', ['pub', 'get'],
            workingDirectory: dir.path);
        expect(pubGet.exitCode, 0, reason: 'pub get failed:\n${pubGet.stderr}');
        final run = await Process.run('dart', ['run', 'bin/check.dart'],
            workingDirectory: dir.path);
        expect(run.exitCode, 0,
            reason: 'check program failed:\n${run.stdout}\n${run.stderr}');
        expect(run.stdout.toString().trim(), 'OK');
      } finally {
        dir.deleteSync(recursive: true);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('a reserved member name in the model is rejected loudly', () {
      final bad = SpecModel.fromJson({
        'modelVersion': 0,
        'roots': [
          {'type': 'Root', 'title': 'Root', 'sectionId': 'R0'},
        ],
        'classes': {
          'Root': {
            'name': 'Root',
            'sectionId': 'R0',
            'fields': [
              {'name': 'path', 'kind': 'content', 'sectionId': 'p'},
            ],
          },
        },
      });
      expect(() => SomDartMetaEmitter(bad).generateLibrary(),
          throwsStateError);
    });

    test('documentRoots subsets the emitted roots but accessor classes stay '
        'complete', () {
      final all = SomDartMetaEmitter(_fixtureModel()).generateLibrary();
      final subset = SomDartMetaEmitter(_fixtureModel(),
          documentRoots: ['SolutionBlueprint']).generateLibrary();
      expect(all, contains('solutionBlueprintMetaTree'));
      expect(subset, contains('solutionBlueprintMetaTree'));
    });
  });
}
