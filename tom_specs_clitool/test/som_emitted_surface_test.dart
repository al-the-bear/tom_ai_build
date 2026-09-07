/// What a SOM generation run covers, and the results that report it.
///
/// Two rules decide the emitted slice of the model — the `documentRoots` filter
/// and the reachability walk — and each used to be written out once per
/// emitter: nine copies of the walk, eighteen of the filter, all byte-identical.
/// Nothing owned the question "what did this run cover?", so the nine
/// `Som*GenerationResult` classes answered it with the *model's* size instead:
/// `classes.length` and the meta's `rootCount`, neither of which the filter ever
/// reaches.
///
/// These tests hold the consolidated rules (`som_emitted_surface.dart`) and the
/// results that now report them.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// A three-root model: `A` reaches `Shared` and `OnlyA`, `B` reaches `Shared`
/// only, `C` reaches nothing. `Orphan` is reachable from no root at all — the
/// shape that makes the model's own class count wrong even for an unfiltered
/// run.
Map<String, ModelClass> _fixture() => {
  'A': ModelClass(
    name: 'A',
    annotations: [
      AnnotationData('Document', {'name': 'A doc', 'description': 'd'}),
      AnnotationData('SectionId', {'id': 'AAA'}),
    ],
    fields: [
      ModelField(name: 'content', typeName: 'String'),
      ModelField(name: 'shared', typeName: 'Shared'),
      ModelField(name: 'onlyA', typeName: 'OnlyA'),
    ],
  ),
  'B': ModelClass(
    name: 'B',
    annotations: [
      AnnotationData('Document', {'name': 'B doc', 'description': 'd'}),
      AnnotationData('SectionId', {'id': 'BBB'}),
    ],
    fields: [
      ModelField(name: 'content', typeName: 'String'),
      ModelField(name: 'shared', typeName: 'Shared'),
    ],
  ),
  'C': ModelClass(
    name: 'C',
    annotations: [
      AnnotationData('Document', {'name': 'C doc', 'description': 'd'}),
      AnnotationData('SectionId', {'id': 'CCC'}),
    ],
    fields: [ModelField(name: 'content', typeName: 'String')],
  ),
  'Shared': ModelClass(
    name: 'Shared',
    annotations: [
      AnnotationData('SectionId', {'id': 'SHR'}),
    ],
    fields: [ModelField(name: 'content', typeName: 'String')],
  ),
  'OnlyA': ModelClass(
    name: 'OnlyA',
    annotations: [
      AnnotationData('SectionId', {'id': 'ONA'}),
    ],
    fields: [ModelField(name: 'content', typeName: 'String')],
  ),
  'Orphan': ModelClass(
    name: 'Orphan',
    annotations: [
      AnnotationData('SectionId', {'id': 'ORP'}),
    ],
    fields: [ModelField(name: 'content', typeName: 'String')],
  ),
};

SpecModel _specModel(Map<String, ModelClass> classes) => SpecModel.fromJson(
  ModelJsonExporter(
    classes,
    modelVersion: 1,
    modelVersionLabel: '1.0.0',
  ).export(),
);

void main() {
  group('the root filter, stated once', () {
    test('an empty documentRoots selects every root', () {
      final model = _specModel(_fixture());
      expect(
        somSelectedRoots(model, const []).map((r) => r.type),
        containsAll(['A', 'B', 'C']),
      );
      expect(somSelectedRoots(model, const []).length, model.roots.length);
    });

    test('a named subset selects exactly that subset', () {
      final model = _specModel(_fixture());
      expect(somSelectedRoots(model, ['B']).map((r) => r.type).toList(), ['B']);
    });

    test('a name the model does not declare selects nothing for it', () {
      final model = _specModel(_fixture());
      expect(
        somSelectedRoots(model, [
          'B',
          'NoSuchRoot',
        ]).map((r) => r.type).toList(),
        ['B'],
        reason: 'the filter selects; it does not assert',
      );
    });
  });

  group('the reachability walk, stated once', () {
    test('follows complex members and includes the root itself', () {
      final model = _specModel(_fixture());
      expect(somReachableClasses(model, {'A'}), {'A', 'Shared', 'OnlyA'});
    });

    test('two roots sharing a class count it once', () {
      final model = _specModel(_fixture());
      expect(somReachableClasses(model, {'A', 'B'}), {
        'A',
        'B',
        'Shared',
        'OnlyA',
      });
    });

    test('a class no root reaches is not in the closure', () {
      final model = _specModel(_fixture());
      final all = somReachableClasses(model, {'A', 'B', 'C'});
      expect(all, isNot(contains('Orphan')));
      expect(
        all.length,
        lessThan(model.classes.length),
        reason:
            'the model is larger than any run over it — which is why a '
            'result reporting the model size is wrong even unfiltered',
      );
    });

    test('a dangling type reference is skipped, not thrown on', () {
      final model = _specModel({
        'Root': ModelClass(
          name: 'Root',
          annotations: [
            AnnotationData('Document', {'name': 'R', 'description': 'd'}),
            AnnotationData('SectionId', {'id': 'RRR'}),
          ],
          fields: [
            ModelField(name: 'content', typeName: 'String'),
            ModelField(name: 'gone', typeName: 'NotInTheModel'),
          ],
        ),
      });
      // The name is still visited (it is what the field says), but resolving it
      // yields nothing rather than crashing halfway through emission.
      expect(somReachableClasses(model, {'Root'}), {'Root', 'NotInTheModel'});
    });
  });

  group('SomEmittedSurface combines the two', () {
    test('an unfiltered run covers every root and its closure', () {
      final surface = somEmittedSurface(_specModel(_fixture()));
      expect(surface.rootCount, 3);
      expect(surface.classNames, {'A', 'B', 'C', 'Shared', 'OnlyA'});
      expect(surface.classCount, 5);
    });

    test('a narrowed run covers only the named root and its closure', () {
      final surface = somEmittedSurface(
        _specModel(_fixture()),
        documentRoots: ['B'],
      );
      expect(surface.rootCount, 1);
      expect(surface.classNames, {'B', 'Shared'});
    });
  });

  group('the generation results report the run, not the model', () {
    // The write step alone — no analyzer — over the hand-built fixture.
    late Map<String, ModelClass> classes;
    late Directory runtimeStub;

    setUp(() {
      classes = _fixture();
      runtimeStub = Directory.systemTemp.createTempSync('som_rt_');
    });

    tearDown(() => runtimeStub.deleteSync(recursive: true));

    SomGenerationResult write({List<String> roots = const []}) {
      final dir = Directory.systemTemp.createTempSync('som_surface_');
      addTearDown(() => dir.deleteSync(recursive: true));
      return writeSomDartProject(
        classes: classes,
        runtimePackagePath: runtimeStub.path,
        outputRoot: dir.path,
        modelVersion: 1,
        modelLabel: '1.0.0+1',
        generatedAt: '2026-01-01T00:00:00.000000Z',
        documentRoots: roots,
      );
    }

    test('an unfiltered run reports its closure, not the model size', () {
      final result = write();
      expect(result.emittedRootCount, 3);
      expect(
        result.emittedClassCount,
        5,
        reason:
            'the model holds 6 classes; Orphan is reachable from no root, so '
            'a run can never cover it',
      );
      expect(
        result.emittedClassCount,
        lessThan(classes.length),
        reason: 'the old classes.length would have reported 6',
      );
    });

    test('a narrowed run reports the narrowed counts', () {
      final result = write(roots: ['B']);
      expect(result.emittedRootCount, 1);
      expect(result.emittedClassCount, 2, reason: 'B and Shared');
    });

    test('schemaPaths still carries the model root count under a filter', () {
      final result = write(roots: ['B']);
      expect(result.emittedRootCount, 1);
      expect(
        result.schemaPaths.length,
        3,
        reason:
            'schemas are selection-agnostic by design — this is the one place '
            'a narrowed run still reports the full root count, and the '
            'emittedRootCount doc points a reader here for it',
      );
    });

    test('the counts describe files that were actually written', () {
      final result = write(roots: ['B']);
      final facade = File(result.libPath).readAsStringSync();
      expect(facade, contains('class B extends SomNode'));
      expect(facade, contains('class Shared extends SomNode'));
      expect(
        facade,
        isNot(contains('class OnlyA extends SomNode')),
        reason: 'OnlyA is reachable from A only, which was not selected',
      );
    });
  });

  group('every result names the metadata module it wrote', () {
    // The metadata module is not optional on any path — the facade exports,
    // imports or requires it — so a caller verifying the committed tree from a
    // result alone must be able to reach it. Four of the nine paths wrote one
    // and did not report it.
    test('the Dart result names an existing meta library', () {
      final dir = Directory.systemTemp.createTempSync('som_meta_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final runtimeStub = Directory.systemTemp.createTempSync('som_rt_');
      addTearDown(() => runtimeStub.deleteSync(recursive: true));

      final result = writeSomDartProject(
        classes: _fixture(),
        runtimePackagePath: runtimeStub.path,
        outputRoot: dir.path,
        modelVersion: 1,
        modelLabel: '1.0.0+1',
        generatedAt: '2026-01-01T00:00:00.000000Z',
      );

      expect(result.metaModulePath, endsWith('_meta.dart'));
      expect(File(result.metaModulePath).existsSync(), isTrue);
      expect(
        p.isWithin(result.outputRoot, result.metaModulePath),
        isTrue,
        reason: 'every path in a result lies under its outputRoot',
      );
    });
  });
}
