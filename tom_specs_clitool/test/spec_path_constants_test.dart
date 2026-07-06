import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// A model exercising the item-11 path enumerator: content/list/complex fields,
/// a recursive type (cycle), and a camelCase name collision.
Map<String, dynamic> _json() => {
      'modelVersion': 0,
      'roots': [
        {'type': 'Root', 'title': 'Root', 'sectionId': 'RT'},
      ],
      'classes': {
        'Root': {
          'name': 'Root',
          'sectionId': 'RT',
          'fields': [
            {'name': 'vision', 'kind': 'content', 'sectionId': 'VIS'},
            {
              'name': 'risks',
              'kind': 'list',
              'sectionId': 'RSK',
              'elementType': 'Risk',
              'elementIsComplex': true,
            },
            {'name': 'node', 'kind': 'complex', 'sectionId': 'ND', 'type': 'Node'},
            // Collision pair: [fooBar, baz] and [foo, barBaz] both camel to
            // `fooBarBaz`.
            {'name': 'fooBar', 'kind': 'complex', 'type': 'HolderX'},
            {'name': 'foo', 'kind': 'complex', 'type': 'HolderY'},
          ],
        },
        // Risk is only a *list element* — its fields must NOT be enumerated.
        'Risk': {
          'name': 'Risk',
          'fields': [
            {'name': 'title', 'kind': 'content'},
          ],
        },
        // Node is self-recursive → the cycle guard must not loop forever.
        'Node': {
          'name': 'Node',
          'sectionId': 'ND',
          'fields': [
            {'name': 'label', 'kind': 'content', 'sectionId': 'LBL'},
            {'name': 'self', 'kind': 'complex', 'type': 'Node'},
          ],
        },
        'HolderX': {
          'name': 'HolderX',
          'fields': [
            {'name': 'baz', 'kind': 'content'},
          ],
        },
        'HolderY': {
          'name': 'HolderY',
          'fields': [
            {'name': 'barBaz', 'kind': 'content'},
          ],
        },
      },
    };

void main() {
  group('enumerateSpecPathHolders (item 11)', () {
    late SpecPathHolder holder;
    late Map<String, String> byName;

    setUp(() {
      final model = SpecModel.fromJson(_json());
      holder = enumerateSpecPathHolders(model).single;
      byName = {for (final c in holder.constants) c.name: c.path};
    });

    test('holder name is Pascal(rootSegment) + Paths', () {
      expect(holder.holderName, 'RtPaths');
      expect(holder.rootSegment, 'RT');
    });

    test('a content leaf earns a constant with its absolute path', () {
      expect(byName['vision'], 'RT/VIS');
    });

    test('a list container earns one constant and its element is not recursed',
        () {
      expect(byName['risks'], 'RT/RSK');
      // Risk.title would be `risksTitle` if the element were (wrongly) recursed.
      expect(byName.keys, isNot(contains('risksTitle')));
    });

    test('complex fields recurse into their target class', () {
      expect(byName['node'], 'RT/ND');
      expect(byName['nodeLabel'], 'RT/ND/LBL');
    });

    test('a self-recursive type terminates via cycle detection', () {
      // `node.self` is emitted once, then not re-entered.
      expect(byName['nodeSelf'], 'RT/ND/self');
      expect(byName.keys.where((k) => k.startsWith('nodeSelf')), hasLength(1));
    });

    test('a camelCase collision is disambiguated with a numeric suffix', () {
      // fooBar/baz and foo/barBaz both camel to `fooBarBaz`.
      expect(byName.containsKey('fooBarBaz'), isTrue);
      expect(byName.containsKey('fooBarBaz2'), isTrue);
      expect(byName['fooBarBaz'], isNot(byName['fooBarBaz2']));
    });

    test('all constant names are unique within a holder', () {
      final names = holder.constants.map((c) => c.name).toList();
      expect(names.toSet(), hasLength(names.length));
    });

    test('enumeration is deterministic across runs', () {
      final model = SpecModel.fromJson(_json());
      final a = enumerateSpecPathHolders(model).single.constants;
      final b = enumerateSpecPathHolders(model).single.constants;
      expect(a.map((c) => '${c.name}=${c.path}').toList(),
          b.map((c) => '${c.name}=${c.path}').toList());
    });
  });
}
