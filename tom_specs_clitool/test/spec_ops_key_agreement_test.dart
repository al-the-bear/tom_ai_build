/// The cross-check that the object-model serializer keys sections the same way
/// the nine SOM runtimes do (SOM §12.2).
///
/// `tom_specs_model`'s `SpecYaml` writes each child under `SpecSlot.key`, whose
/// id half the spec-ops codegen stamps into `spec_ops.g.dart`. The nine runtimes
/// compute the same id from `spec_model.meta.json` (`SpecDocumentYaml.nodeKey`
/// and its eight siblings). Two derivations of one rule, over two different
/// inputs — so nothing but a test stops them drifting, and a drift means a
/// document written by the editor is keyed differently from the same document
/// written by any other runtime.
///
/// Both inputs are committed artifacts, so this runs without the analyzer. It
/// compares every slot in the registry, which is the whole model: a rule change
/// on either side that misses the other fails here rather than at a user's
/// round-trip.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final clitoolRoot = Directory.current.path;
  final metaPath = p.normalize(p.join(
      clitoolRoot, '..', 'tom_som_dart_v0', 'meta', 'spec_model.meta.json'));
  final registryPath = p.normalize(p.join(clitoolRoot, '..', 'tom_specs_model',
      'lib', 'src', 'generated', 'spec_ops.g.dart'));

  group('SpecSlot section ids agree with the SOM meta (SOM §12.2)', () {
    late Map<String, dynamic> metaClasses;
    late Map<String, Map<String, String?>> registrySlots;

    setUpAll(() {
      metaClasses = (jsonDecode(File(metaPath).readAsStringSync())
          as Map<String, dynamic>)['classes'] as Map<String, dynamic>;
      registrySlots = _readRegistrySlots(File(registryPath).readAsStringSync());
    });

    /// The id a meta field is keyed by: its own `@SectionId`, else — for a
    /// section/complex field only — the target class's id.
    String? metaKeyId(Map<String, dynamic> field) {
      final own = _annotationArg(field, 'SectionId', 'id');
      if (own != null) return own;
      final kind = field['kind'] as String?;
      if (kind != 'section' && kind != 'complex') return null;
      final target = field['type'] as String?;
      if (target == null) return null;
      final cls = metaClasses[target] as Map<String, dynamic>?;
      return cls?['sectionId'] as String?;
    }

    test('every registered slot carries the meta\'s key id', () {
      final mismatches = <String>[];
      var compared = 0;

      for (final entry in metaClasses.entries) {
        final slots = registrySlots[entry.key];
        if (slots == null) continue; // mixin leaf, or not a registered class
        final fields =
            (entry.value as Map<String, dynamic>)['fields'] as List<dynamic>;
        for (final f in fields.cast<Map<String, dynamic>>()) {
          final member = f['name'] as String;
          if (!slots.containsKey(member)) continue; // scalar, not a child slot
          compared++;
          final expected = metaKeyId(f);
          final actual = slots[member];
          if (expected != actual) {
            mismatches.add('${entry.key}.$member (${f['kind']}'
                '${f['type'] == null ? '' : ' -> ${f['type']}'}): '
                'meta ${expected ?? '<none>'} != registry '
                '${actual ?? '<none>'}');
          }
        }
      }

      expect(compared, greaterThan(1000),
          reason: 'the registry/meta pairing found almost no slots to compare, '
              'so this test is not actually checking anything — the parsing '
              'below has probably drifted from the generated shape.');
      expect(mismatches, isEmpty,
          reason: '${mismatches.length} of $compared slots key differently in '
              'tom_specs_model than in the nine SOM runtimes.\n'
              '${mismatches.take(20).join('\n')}');
    });

    test('most slots do carry an id, so agreement is not vacuous', () {
      // The class fallback is the load-bearing half of the rule: nearly every
      // complex member is named by the id of the class it holds, not by one of
      // its own. If this collapses, the rule above is agreeing on `null`.
      final all = registrySlots.values.expand((s) => s.values).toList();
      final withId = all.where((id) => id != null).length;
      expect(all, isNotEmpty);
      expect(withId / all.length, greaterThan(0.5));
    });
  });
}

/// The `sectionId` (or `null`) stamped on each `SpecSlot` of each registered
/// class, keyed `className -> memberName -> sectionId`.
Map<String, Map<String, String?>> _readRegistrySlots(String source) {
  final out = <String, Map<String, String?>>{};
  final blocks = source.split('  SpecRegistry.register(');
  for (final block in blocks.skip(1)) {
    final className = block.substring(0, block.indexOf(','));
    final slots = <String, String?>{};
    for (final m in _slotPattern.allMatches(block)) {
      slots[m.group(1)!] = m.group(2);
    }
    out[className] = slots;
  }
  return out;
}

/// Matches the tail of an emitted `SpecSlot.node`/`SpecSlot.list`:
/// `label: '<member>'` optionally followed by `, sectionId: '<id>'`.
final RegExp _slotPattern =
    RegExp(r"label: '(\w+)'(?:, sectionId: '([^']+)')?\)");

String? _annotationArg(Map<String, dynamic> node, String name, String arg) {
  final annotations = node['annotations'] as List<dynamic>?;
  if (annotations == null) return null;
  for (final a in annotations.cast<Map<String, dynamic>>()) {
    if (a['name'] != name) continue;
    final args = a['arguments'] as Map<String, dynamic>?;
    final value = args?[arg];
    if (value is String) return value;
  }
  return null;
}
