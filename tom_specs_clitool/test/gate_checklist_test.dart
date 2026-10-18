// The generic gate checklists (tom_specs_model/doc/gate_checklists/) are held
// to tom_specs_gate_checklists.md §3, and to the criteria tables of
// tom_specs_project_flow.md §PF-GAT-G1..G8 they expand: every criterion has at
// least one item, and every item names a criterion of its gate.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

final _docDir = p.normalize(
  p.join(Directory.current.path, '..', 'tom_specs_model', 'doc'),
);

const _methods = {'tool', 'query', 'reading', 'sign-off'};
const _itemKeys = {
  'id',
  'criterion',
  'inspect',
  'method',
  'how',
  'evidence',
  'pass',
  'parameters',
};
const _requiredItemKeys = {
  'id',
  'criterion',
  'inspect',
  'method',
  'how',
  'evidence',
  'pass',
};

/// The criterion column of the `### PF-GAT-G<n>` table in the project flow.
List<String> _criteriaOf(String flow, String gate) {
  final lines = flow.split('\n');
  final start = lines.indexWhere((l) => l.startsWith('### PF-GAT-$gate '));
  if (start < 0) return const [];
  final criteria = <String>[];
  var inTable = false;
  for (final line in lines.skip(start + 1)) {
    if (line.startsWith('### ')) break;
    if (line.startsWith('|')) {
      final cell = line.split('|')[1].trim();
      if (!inTable) {
        inTable = true; // the header row
        continue;
      }
      if (cell.startsWith('---')) continue;
      criteria.add(cell);
    } else if (inTable) {
      break;
    }
  }
  return criteria;
}

void main() {
  final flow = File(
    p.join(_docDir, 'tom_specs_project_flow.md'),
  ).readAsStringSync();
  final files =
      Directory(p.join(_docDir, 'gate_checklists'))
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.checklist.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('GC-1: the generic checklists exist, G2 among them', () {
    expect(
      files.map((f) => p.basename(f.path)),
      containsAll(['G1.checklist.yaml', 'G2.checklist.yaml']),
    );
  });

  for (final file in files) {
    final name = p.basename(file.path);
    group(name, () {
      final doc = loadYaml(file.readAsStringSync()) as YamlMap;
      final gate = name.split('.').first;

      test('GC-2: the header is the documented format', () {
        expect(doc['formatVersion'], 1);
        expect(doc['gate'], gate);
        expect(doc['title'], isA<String>());
        expect(doc['checklistVersion'], matches(RegExp(r'^\d+\.\d+\.\d+$')));
        expect(doc['criteria'], 'tom_specs_project_flow.md §PF-GAT-$gate');
        expect(doc['items'], isA<YamlList>());
      });

      final items = (doc['items'] as YamlList).cast<YamlMap>();

      test('GC-3: every item has the documented fields and a valid id', () {
        final ids = <String>{};
        for (final item in items) {
          final id = item['id'] as String;
          expect(
            id,
            matches(RegExp('^$gate-[A-Z]+-[0-9]+\$')),
            reason: 'id shape',
          );
          expect(ids.add(id), isTrue, reason: '$id is not unique');
          expect(
            item.keys.toSet().difference(_itemKeys),
            isEmpty,
            reason: '$id has an unknown key',
          );
          for (final key in _requiredItemKeys) {
            expect(
              (item[key] as String?)?.trim(),
              isNotEmpty,
              reason: '$id lacks $key',
            );
          }
          expect(_methods, contains(item['method']), reason: '$id method');
        }
      });

      test('GC-4: items cover exactly the criteria of §PF-GAT-$gate', () {
        final criteria = _criteriaOf(flow, gate);
        expect(criteria, isNotEmpty, reason: 'no criteria table found');
        final named = items.map((i) => i['criterion'] as String).toSet();
        expect(
          named.difference(criteria.toSet()),
          isEmpty,
          reason: 'items naming a criterion the gate does not have',
        );
        expect(
          criteria.toSet().difference(named),
          isEmpty,
          reason: 'criteria with no item',
        );
      });
    });
  }
}
