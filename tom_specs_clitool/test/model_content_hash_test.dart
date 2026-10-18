// The content identity of a spec-model meta and the version-bump check.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Map<String, Object?> _meta() => {
  'generatedAt': '2026-10-13T00:00:00Z',
  'metaSchemaVersion': 1,
  'modelVersion': 1,
  'modelVersionLabel': '1.4.1+3.abc',
  'classCount': 1,
  'rootCount': 1,
  'roots': [
    {'type': 'A', 'title': 'A'},
  ],
  'classes': {
    'A': {
      'name': 'A',
      'fields': [
        {'name': 'x', 'kind': 'content'},
      ],
    },
  },
};

void main() {
  group('specModelContentHash', () {
    test('MH-1: the build stamps do not move it', () {
      final a = _meta();
      final b = _meta()
        ..['generatedAt'] = '2027-01-01T00:00:00Z'
        ..['modelVersion'] = 2
        ..['modelVersionLabel'] = '2.0.0+9.def';
      expect(specModelContentHash(b), specModelContentHash(a));
    });

    test('MH-2: a model change moves it', () {
      final b = _meta();
      ((b['classes']! as Map)['A'] as Map)['fields'] = [
        {'name': 'x', 'kind': 'content'},
        {'name': 'y', 'kind': 'content'},
      ];
      expect(specModelContentHash(b), isNot(specModelContentHash(_meta())));
    });

    test('MH-3: map key order does not move it, list order does', () {
      final reordered = {
        for (final k in _meta().keys.toList().reversed) k: _meta()[k],
      };
      expect(specModelContentHash(reordered), specModelContentHash(_meta()));
      final b = _meta()
        ..['roots'] = [
          {'type': 'A', 'title': 'A'},
          {'type': 'B', 'title': 'B'},
        ];
      final c = _meta()
        ..['roots'] = [
          {'type': 'B', 'title': 'B'},
          {'type': 'A', 'title': 'A'},
        ];
      expect(specModelContentHash(b), isNot(specModelContentHash(c)));
    });
  });

  group('validateSpecModelMeta and modelHash', () {
    test('MH-4: a matching hash validates, a stale one is reported', () {
      final m = _meta()..['modelHash'] = specModelContentHash(_meta());
      expect(validateSpecModelMeta(m), isEmpty);
      ((m['classes']! as Map)['A'] as Map)['name'] = 'Edited';
      expect(
        validateSpecModelMeta(m),
        contains(contains('"modelHash" does not match')),
      );
    });

    test('MH-5: every committed meta carries its own content hash', () {
      // The nine generated metas describe one model: one hash, and each
      // matches its content (the validator checks the second half).
      final root = p.dirname(Directory.current.path);
      final hashes = <String?>{};
      for (final lang in [
        'dart', 'python', 'javascript', 'typescript', 'java', //
        'go', 'rust', 'c', 'cpp',
      ]) {
        final f = File(
          p.join(root, 'tom_som_${lang}_v0', 'meta', 'spec_model.meta.json'),
        );
        final meta = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        expect(validateSpecModelMeta(meta), isEmpty, reason: f.path);
        hashes.add(meta['modelHash'] as String?);
      }
      expect(hashes, hasLength(1));
      expect(hashes.single, isNotNull);
    });
  });

  group('modelChangeWithoutVersionBump', () {
    const h1 = 'a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1';
    const h2 = 'b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2';

    test('MH-6: a changed model under an unchanged version warns', () {
      final w = modelChangeWithoutVersionBump(
        previousHash: h1,
        previousVersion: '1.4.1',
        modelHash: h2,
        version: '1.4.1',
      );
      expect(w, allOf(contains('1.4.1'), contains(':bumpversion')));
    });

    test(
      'MH-7: a bumped version, an unchanged model or no baseline is quiet',
      () {
        expect(
          modelChangeWithoutVersionBump(
            previousHash: h1,
            previousVersion: '1.4.1', //
            modelHash: h2,
            version: '1.4.2',
          ),
          isNull,
        );
        expect(
          modelChangeWithoutVersionBump(
            previousHash: h1,
            previousVersion: '1.4.1', //
            modelHash: h1,
            version: '1.4.1',
          ),
          isNull,
        );
        expect(
          modelChangeWithoutVersionBump(
            previousHash: null,
            previousVersion: null, //
            modelHash: h2,
            version: '1.4.1',
          ),
          isNull,
        );
      },
    );
  });
}
