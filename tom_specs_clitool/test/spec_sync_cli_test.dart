import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';
import 'package:tom_specs_clitool/src/spec_sync_cli.dart';

/// The cut of Tom UAM's requirements the conformance corpus holds: its
/// Blueprint and its Requirements Specification, as documents.
Map<String, SpecDocument> _cut() {
  final cut =
      jsonDecode(
            File(
              '${Directory.current.path}/../tom_som_conformance/corpus/'
              'uam_requirements_cut.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  return {
    'SBP': SpecDocument()..loadJson(cut['blueprint'] as Map),
    'RSP': SpecDocument()..loadJson(cut['rsp'] as Map),
  };
}

String _yaml(SpecDocument doc, String rootType) => SpecDocumentYaml.encode(
  document: doc,
  tree: buildSomMetaTree(somSpecModel, rootType: rootType),
  modelVersion: somSpecModel.modelVersionString,
);

SpecDocument _read(String path, String rootType) => SpecDocumentYaml.decode(
  File(path).readAsStringSync(),
  buildSomMetaTree(somSpecModel, rootType: rootType),
).document;

const _status = 'RSP/functionalRequirements/FRE-REQU-LST-1/content';
const _bpStatus =
    'SBP/introductionAndScope/requirements/functionalRequirements/'
    'FRE-REQU-LST-1/content';

void main() {
  late Directory dir;
  late String sbp, rsp;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('spec_sync_');
    final cut = _cut();
    sbp = '${dir.path}/tom_uam.sbp.tomspecs.yaml';
    rsp = '${dir.path}/tom_uam.rsp.tomspecs.yaml';
    File(sbp).writeAsStringSync(_yaml(cut['SBP']!, 'D00SolutionBlueprint'));
    File(
      rsp,
    ).writeAsStringSync(_yaml(cut['RSP']!, 'D04RequirementsSpecification'));
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// The RSP's first requirement set to [status] (the Blueprint's is
  /// `approved`).
  void driftStatus(String status) {
    final doc = _read(rsp, 'D04RequirementsSpecification')
      ..setFormField(_status, 'status', status);
    File(rsp).writeAsStringSync(_yaml(doc, 'D04RequirementsSpecification'));
  }

  Future<(int, String, String)> run(
    Future<int> Function(List<String>, {StringSink? out, StringSink? err}) f,
    List<String> args,
  ) async {
    final o = StringBuffer(), e = StringBuffer();
    final code = await f(args, out: o, err: e);
    return (code, '$o', '$e');
  }

  group(':spec-sync-report', () {
    test('a set that agrees exits 0 and writes nothing', () async {
      final before = File(sbp).readAsStringSync();
      final (code, out, _) = await run(runSpecSyncReport, [sbp, rsp]);
      expect(code, 0, reason: out);
      expect(out, contains('clean'));
      expect(File(sbp).readAsStringSync(), before);
      expect(dir.listSync().length, 2);
    });

    test('a finding exits 1; --json prints the report', () async {
      driftStatus('proposed');
      final (code, out, _) = await run(runSpecSyncReport, [sbp, rsp, '--json']);
      expect(code, 1);
      final json = jsonDecode(out) as Map<String, dynamic>;
      expect(json['clean'], isFalse);
      expect([
        for (final f in json['findings'] as List) f['code'],
      ], contains('sharedValueDiffers'));
      // Every finding, and every document finding, carries its message.
      final drift = (json['findings'] as List).firstWhere(
        (f) => f['code'] == 'sharedValueDiffers',
      );
      expect(drift['message'], contains('status'));
      for (final f in json['findings'] as List) {
        expect(f['message'], isA<String>());
        expect(f['message'], isNotEmpty);
      }
      for (final e in json['documentFindings'] as List) {
        for (final f in (e as List)[1] as List) {
          expect(f['message'], isNotEmpty);
        }
      }
    });

    test('--pairs scopes the report', () async {
      driftStatus('proposed');
      final (code, _, _) = await run(runSpecSyncReport, [
        sbp,
        rsp,
        '--pairs',
        'TR1',
      ]);
      expect(code, 0);
    });

    test('a refused set exits 2', () async {
      final copy = '${dir.path}/other.rsp.tomspecs.yaml';
      File(rsp).copySync(copy);
      final (code, out, err) = await run(runSpecSyncReport, [
        sbp,
        rsp,
        copy,
        '--json',
      ]);
      expect(code, 2);
      expect(err, contains('refused'));
      expect((jsonDecode(out) as Map)['refused'], isNotNull);
    });

    test('--help shows the usage and exits 0', () async {
      final (code, out, _) = await run(runSpecSyncReport, ['--help']);
      expect(code, 0);
      expect(out, contains('Usage: tomspecs :spec-sync-report'));
      expect(out, contains('--pairs'));
    });
  });

  group(':spec-backfill', () {
    test('writes the Blueprint and its rendition; a second run writes '
        'nothing', () async {
      driftStatus('proposed');
      final (code, out, _) = await run(runSpecBackfill, [sbp, rsp]);
      expect(code, 0, reason: out);
      expect(out, contains('wrote $sbp'));
      expect(
        _read(sbp, 'D00SolutionBlueprint').formField(_bpStatus, 'status'),
        'proposed',
      );
      final md = File(sbp.replaceFirst(RegExp(r'\.yaml$'), '.md'));
      expect(md.existsSync(), isTrue);
      expect(md.readAsStringSync(), startsWith('<!-- docspec:'));
      final after = File(sbp).readAsStringSync();
      final (code2, out2, _) = await run(runSpecBackfill, [sbp, rsp]);
      expect(code2, 0);
      expect(out2, contains('nothing to write'));
      expect(File(sbp).readAsStringSync(), after);
      expect(dir.listSync().where((e) => e.path.contains('.stage')), isEmpty);
    });

    test('--dry-run writes nothing; --json prints the result', () async {
      driftStatus('proposed');
      final before = File(sbp).readAsStringSync();
      final (code, out, _) = await run(runSpecBackfill, [
        sbp,
        rsp,
        '--dry-run',
        '--json',
      ]);
      expect(code, 0);
      expect((jsonDecode(out) as Map)['changes'], isNotEmpty);
      expect(File(sbp).readAsStringSync(), before);
    });

    test('a staged write leaves the document of record untouched until the '
        'stage is complete', () async {
      driftStatus('proposed');
      final stage = '${dir.path}/03_Step';
      final before = File(sbp).readAsStringSync();
      String? stagedText, recordAtStage;
      final o = StringBuffer();
      final code = await runSpecBackfill(
        [sbp, rsp, '--stage-folder', stage],
        out: o,
        onStaged: (staged, record) {
          stagedText = File(staged).readAsStringSync();
          recordAtStage = File(record).readAsStringSync();
          // The stage is complete: the YAML and its rendition, no temp file.
          expect(File('$stage/tom_uam.sbp.tomspecs.md').existsSync(), isTrue);
          expect(
            Directory(stage).listSync().where((e) => e.path.endsWith('.tmp')),
            isEmpty,
          );
        },
      );
      expect(code, 0, reason: '$o');
      expect(recordAtStage, before);
      expect(stagedText, isNot(before));
      expect(File(sbp).readAsStringSync(), stagedText);
      expect(
        File('${dir.path}/tom_uam.sbp.tomspecs.md').readAsStringSync(),
        File('$stage/tom_uam.sbp.tomspecs.md').readAsStringSync(),
      );
      // The stage carries the backfill's revision entry.
      expect(stagedText, contains('RVENT'));
    });

    test('a set holding a mark is refused with 2', () async {
      final doc = _read(rsp, 'D04RequirementsSpecification')
        ..setFormField(_status, 'status', '{~~approved~>proposed~~}');
      File(rsp).writeAsStringSync(_yaml(doc, 'D04RequirementsSpecification'));
      final before = File(sbp).readAsStringSync();
      final (code, out, _) = await run(runSpecBackfill, [sbp, rsp, '--json']);
      expect(code, 2);
      expect(
        ((jsonDecode(out) as Map)['refused'] as Map)['code'],
        'setHasMarks',
      );
      expect(File(sbp).readAsStringSync(), before);
    });
  });

  group(':spec-prefill', () {
    test('creates the Phase 3 document from the Blueprint; a second run '
        'writes nothing', () async {
      final target = '${dir.path}/new.rsp.tomspecs.yaml';
      File(rsp).deleteSync();
      final (code, out, _) = await run(runSpecPrefill, [
        sbp,
        '--root',
        'RSP',
        '--target',
        target,
      ]);
      expect(code, anyOf(0, 1), reason: out);
      expect(out, contains('FILLED   FR'));
      final doc = _read(target, 'D04RequirementsSpecification');
      expect(doc.formField(_status, 'status'), 'approved');
      expect(File('${dir.path}/new.rsp.tomspecs.md').existsSync(), isTrue);
      final after = File(target).readAsStringSync();
      final (_, out2, _) = await run(runSpecPrefill, [
        sbp,
        '--root',
        'RSP',
        '--target',
        target,
      ]);
      expect(out2, contains('nothing to write'));
      expect(File(target).readAsStringSync(), after);
    });

    test('without --root, and a target of another root, exit 2', () async {
      expect((await run(runSpecPrefill, [sbp])).$1, 2);
      final (code, _, err) = await run(runSpecPrefill, [
        sbp,
        '--root',
        'ISC',
        '--target',
        rsp,
      ]);
      expect(code, 2);
      expect(err, contains('refused'));
    });
  });

  group(':spec-derive-fields', () {
    test('--dry-run lists the changes and writes nothing; a write takes '
        'them', () async {
      final doc = _read(rsp, 'D04RequirementsSpecification');
      final derived = deriveFields(
        somSpecModel,
        doc,
        dryRun: true,
      ).changes.isNotEmpty;
      final before = File(rsp).readAsStringSync();
      final (code, out, _) = await run(runSpecDeriveFields, [
        rsp,
        '--dry-run',
        '--json',
      ]);
      expect(code, anyOf(0, 1));
      expect(((jsonDecode(out) as Map)['changes'] as List).isNotEmpty, derived);
      expect(File(rsp).readAsStringSync(), before);
      final (_, out2, _) = await run(runSpecDeriveFields, [rsp, '--unmarked']);
      if (derived) {
        expect(out2, contains('wrote $rsp'));
        final (_, out3, _) = await run(runSpecDeriveFields, [
          rsp,
          '--unmarked',
        ]);
        expect(out3, contains('nothing to write'));
      } else {
        expect(out2, contains('nothing to write'));
      }
    });

    test('more than one document is a usage error', () async {
      expect((await run(runSpecDeriveFields, [sbp, rsp])).$1, 2);
    });
  });

  group(':spec-rename-id', () {
    test('renames an id in every document; --dry-run writes nothing', () async {
      final args = [
        sbp,
        rsp,
        '--from',
        'FRE-REQU-TENANT-FEATURES',
        '--to',
        'FRE-REQU-TENANT-FEATURE-SET',
      ];
      final before = File(rsp).readAsStringSync();
      final (dry, _, _) = await run(runSpecRenameId, [...args, '--dry-run']);
      expect(dry, 0);
      expect(File(rsp).readAsStringSync(), before);
      final (code, out, _) = await run(runSpecRenameId, [...args, '--json']);
      expect(code, 0);
      final docs = {
        for (final c in (jsonDecode(out) as Map)['changes'] as List)
          c['document'],
      };
      expect(docs, {'tom_uam.sbp.tomspecs.yaml', 'tom_uam.rsp.tomspecs.yaml'});
      for (final f in [sbp, rsp]) {
        expect(
          File(f).readAsStringSync(),
          contains('FRE-REQU-TENANT-FEATURE-SET'),
        );
        expect(
          File(f).readAsStringSync(),
          isNot(contains('FRE-REQU-TENANT-FEATURES\n')),
        );
      }
    });

    test('a rename onto an id that exists is refused with 2', () async {
      final before = File(rsp).readAsStringSync();
      final (code, out, _) = await run(runSpecRenameId, [
        sbp,
        rsp,
        '--from',
        'FRE-REQU-TENANT-FEATURES',
        '--to',
        'FRE-REQU-TENANT-LIFECYCLE',
        '--json',
      ]);
      expect(code, 2);
      expect(((jsonDecode(out) as Map)['refused'] as Map)['code'], 'exists');
      expect(File(rsp).readAsStringSync(), before);
    });

    test('without --from or --to, exit 2', () async {
      expect((await run(runSpecRenameId, [sbp, '--from', 'X'])).$1, 2);
    });
  });
}
