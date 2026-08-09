/// The coverage check on the emitted projection connect bindings (N11).
///
/// `tom_specs_model`'s `projection_connect_test` proves each of the thirteen
/// projection roots *has* a binding. That is the coarse half: a binding that
/// covers ten of a root's nineteen children still returns `true`, and the nine
/// it misses serialize as empty default-constructed sections — a document that
/// looks complete and is not.
///
/// So this test compares the emitted binding against the model itself: every
/// child node of every projection root must be bound, save the deliberately
/// document-local header. Both inputs are committed artifacts, so it runs
/// without the analyzer.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The one child type that is *meant* to stay unbound: document front matter
/// belongs to each of the fourteen entry points individually.
const _documentLocalTypes = {'DocumentHeader'};

/// The Solution Blueprint master — the source every projection binds to, and
/// the one root that is not itself a projection.
const _sourceRoot = 'D00SolutionBlueprint';

void main() {
  final clitoolRoot = Directory.current.path;
  final metaPath = p.normalize(p.join(
      clitoolRoot, '..', 'tom_som_dart_v0', 'meta', 'spec_model.meta.json'));
  final registryPath = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model',
      'lib', 'src', 'generated', 'spec_ops.g.dart'));

  group('emitted connect bindings cover every projection root (N11)', () {
    late Map<String, dynamic> metaClasses;
    late List<String> projectionRoots;
    late Map<String, Map<String, String>> bindings;

    setUpAll(() {
      final meta =
          jsonDecode(File(metaPath).readAsStringSync()) as Map<String, dynamic>;
      metaClasses = meta['classes'] as Map<String, dynamic>;
      projectionRoots = [
        for (final root in (meta['roots'] as List<dynamic>)
            .cast<Map<String, dynamic>>())
          if (root['type'] != _sourceRoot) root['type'] as String,
      ];
      bindings = _readConnectBindings(File(registryPath).readAsStringSync());
    });

    test('one binding per projection root, and no others', () {
      expect(projectionRoots, hasLength(13));
      expect(bindings.keys.toList()..sort(), projectionRoots.toList()..sort());
    });

    test('every child of every projection root is bound', () {
      final missing = <String>[];
      var covered = 0;

      for (final root in projectionRoots) {
        final bound = bindings[root] ?? const <String, String>{};
        final fields = (metaClasses[root] as Map<String, dynamic>)['fields']
            as List<dynamic>;
        for (final f in fields.cast<Map<String, dynamic>>()) {
          if (!_isChildNode(f)) continue;
          if (_documentLocalTypes.contains(_targetType(f))) continue;
          final name = f['name'] as String;
          if (bound.containsKey(name)) {
            covered++;
          } else {
            missing.add('$root.$name (${f['kind']} -> ${_targetType(f)})');
          }
        }
      }

      expect(covered, greaterThan(100),
          reason: 'almost nothing was compared, so the registry parsing below '
              'has probably drifted from the emitted shape');
      expect(missing, isEmpty,
          reason: '${missing.length} projection children have no connect '
              'binding and would serialize as empty sections:\n'
              '${missing.take(20).join('\n')}');
    });

    test('the document header is the only deliberate omission', () {
      // Stated as a test rather than a comment: if a second exclusion is ever
      // added to the codegen it has to be argued for here too.
      for (final root in projectionRoots) {
        final bound = bindings[root] ?? const <String, String>{};
        expect(bound.containsKey('header'), isFalse,
            reason: '$root.header must stay document-local');
      }
    });

    test('every bound path reads from the Solution Blueprint root', () {
      final stray = [
        for (final root in bindings.entries)
          for (final b in root.value.entries)
            if (!b.value.startsWith('b.')) '${root.key}.${b.key} = ${b.value}',
      ];
      expect(stray, isEmpty);
    });
  });
}

/// The `member -> sbp expression` pairs of each emitted `connect:` body, keyed
/// by the projection root class name.
Map<String, Map<String, String>> _readConnectBindings(String source) {
  final out = <String, Map<String, String>>{};
  for (final m in _connectPattern.allMatches(source)) {
    final body = m.group(2)!;
    final assignments = <String, String>{};
    for (final a in _assignmentPattern.allMatches(body)) {
      assignments[a.group(1)!] = a.group(2)!;
    }
    out[m.group(1)!] = assignments;
  }
  return out;
}

/// Matches an emitted `connect: (o, s) { final n = o as <Root>; ... },` block.
final RegExp _connectPattern = RegExp(
    r'connect: \(o, s\) \{\n      final n = o as (\w+);\n(.*?)\n    \},',
    dotAll: true);

/// Matches `n.<member> = <expression>;` inside a connect body.
final RegExp _assignmentPattern = RegExp(r'n\.(\w+) = ([^;]+);');

/// Whether a meta field is a child node the connect pass must bind — the same
/// classification the codegen's `_isChildNode` applies.
bool _isChildNode(Map<String, dynamic> field) =>
    const {'section', 'complex', 'list'}.contains(field['kind']);

/// The class a child field holds. A `complex`/`list` field names it under
/// `type`; a `section` field carries its content-leaf class under
/// `sectionType`.
String? _targetType(Map<String, dynamic> field) =>
    (field['type'] ?? field['sectionType']) as String?;
