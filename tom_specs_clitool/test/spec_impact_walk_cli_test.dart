/// `tomspecs :spec-impact-walk`: the impact walk of the change mode over a
/// spec root — the documents found in its `phase*` folders (not the step
/// folders below them), every root walked (an absent one too), the level read
/// from the listing, the output as Markdown or JSON.
///
/// The subject is the Meridian Solution Blueprint shipped with
/// `tom_som_dart_v0`, laid out as a project would keep it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/src/commands/spec_impact_walk.dart';

final String _meridian = p.normalize(
  p.absolute(
    '../tom_som_dart_v0/documents/meridian_order_management.tomspecs.yaml',
  ),
);

final Directory _tmp = Directory(
  p.join('.dart_tool', 'test_tmp', 'tom_spec_change5'),
);

/// A spec root holding the Meridian Blueprint as its Phase-2 document, a
/// round copy in a step folder, a Project Idea, and one gate checklist.
Directory _specRoot() {
  if (_tmp.existsSync()) _tmp.deleteSync(recursive: true);
  final root = Directory(p.join(_tmp.path, 'spec'))
    ..createSync(recursive: true);
  final blueprint = File(_meridian).readAsStringSync();
  void write(String rel, String text) => File(p.join(root.path, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);
  write('phase1_project_idea/project_idea.md', '# Idea\n');
  write('phase2_solution_blueprint/meridian.sbp.tomspecs.yaml', blueprint);
  write(
    'phase2_solution_blueprint/01_Initial Version/meridian.sbp.tomspecs.yaml',
    blueprint,
  );
  write('gates/G2.checklist.yaml', 'items: []\n');
  return root;
}

void main() {
  test(
    'walks every root, reads the phase document, records the level',
    () async {
      final root = _specRoot();
      final out = p.join(_tmp.path, 'walk.json');
      final code = await runSpecImpactWalk([
        '--spec-root',
        root.path,
        '--tests',
        p.join(root.path, 'no_such_tests'),
        '--json',
        '--out',
        out,
      ]);
      expect(code, 0);
      final json =
          jsonDecode(File(out).readAsStringSync()) as Map<String, dynamic>;
      final walk = (json['walk'] as List).cast<Map<String, dynamic>>();
      expect(walk, hasLength(14), reason: 'every root of the model');
      final sbp = walk.firstWhere((r) => r['sectionId'] == 'SBP');
      expect(sbp['present'], isTrue);
      expect(
        walk.where((r) => r['present'] == true).map((r) => r['sectionId']),
        ['SBP'],
        reason: 'the step folder copy is not a second document',
      );
      final rows = (sbp['rows'] as List).cast<Map<String, dynamic>>();
      expect(rows.first['kind'], 'root');
      expect(
        rows.any((r) => r['filled'] == true && r['kind'] == 'item'),
        isTrue,
      );
      expect(rows.any((r) => r['kind'] == 'template'), isTrue);
      final absent = walk.firstWhere((r) => r['sectionId'] == 'CLA');
      expect(absent['present'], isFalse);
      expect(
        (absent['rows'] as List).cast<Map<String, dynamic>>().every(
          (r) => r['filled'] == false,
        ),
        isTrue,
      );
      final level = json['level'] as Map<String, dynamic>;
      expect(level['phasesReached'], [1, 2]);
      expect(level['gates'], ['gates/G2.checklist.yaml']);
      expect(level['tests'], [
        {'path': p.join(root.path, 'no_such_tests'), 'present': false},
      ]);
      expect(level['code'], isNull, reason: 'not given');
    },
  );

  test('--root narrows the Markdown to the named roots', () async {
    final root = _specRoot();
    final out = p.join(_tmp.path, 'walk.md');
    final code = await runSpecImpactWalk([
      '--spec-root',
      root.path,
      '--root',
      'SBP',
      '--out',
      out,
    ]);
    expect(code, 0);
    final md = File(out).readAsStringSync();
    expect(md, contains('## SBP — D00SolutionBlueprint'));
    expect(md, isNot(contains('## CLA —')));
    expect(md, contains('## Level'));
    expect(md, contains('- Documents absent: CLA,'));
  });

  test('refuses two documents of one root, and an unknown --root', () async {
    final root = _specRoot();
    final second = p.join(
      root.path,
      'phase2_solution_blueprint',
      'copy.sbp.tomspecs.yaml',
    );
    File(_meridian).copySync(second);
    expect(
      await runSpecImpactWalk([
        '--spec-root',
        root.path,
        '--out',
        p.join(_tmp.path, 'x.md'),
      ]),
      2,
    );
    File(second).deleteSync();
    expect(
      await runSpecImpactWalk([
        '--spec-root',
        root.path,
        '--root',
        'NOPE',
        '--out',
        p.join(_tmp.path, 'x.md'),
      ]),
      2,
    );
    expect(
      await runSpecImpactWalk(['--out', p.join(_tmp.path, 'x.md')]),
      2,
      reason: 'no --spec-root',
    );
  });
}
