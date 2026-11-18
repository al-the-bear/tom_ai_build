/// The Markdown rendering of the IR (`irspecs_ir.md` §10.3): the Meridian IR
/// rendered through `irspecs emit --standard markdown`, every document valid
/// against `irspecs-md/1.0`, the index and one area checked against the IR,
/// and the schema's workspace mirror held to the canonical copy.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_doc_specs/tom_doc_specs.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';


final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _areas = p.absolute(
  '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
);
final _spec = p.absolute(
  '../tom_som_dart_v0/documents/meridian_order_management.docspecs.yaml',
);
final _schemaFolder = p.absolute('tool/docspecs-schema');
final _schemaName = 'irspecs-md.1.0.docspecs-schema.yaml';

CodeSpecsAreaCatalog _catalog() => CodeSpecsAreaCatalog.fromJson(
  jsonDecode(File(_areas).readAsStringSync()) as Map<String, dynamic>,
);

/// The Meridian IR, through the file form.
List<IrDocument> _ir() {
  CsLocusProject read(CsLocus locus) => readCsLocusProjectFromDirectory(
    locus: locus,
    packageName: 'meridian_codespec_${locus.name}',
    root: p.join(_meridian, 'meridian_codespec_${locus.name}'),
  );
  final documents = irFromCsModel(
    shared: read(CsLocus.shared),
    client: read(CsLocus.client),
    server: read(CsLocus.server),
    areas: IrAreaIndex(_catalog()),
  );
  return [for (final d in documents) readIrYaml(writeIrYaml(d))];
}

void main() {
  late Directory scratch;
  late String ir;
  late String out;
  late List<IrDocument> documents;
  late String stdoutText;

  setUpAll(() async {
    scratch = Directory.systemTemp.createTempSync('irspecs_md');
    documents = _ir();
    final areas = IrAreaIndex(_catalog());
    ir = p.join(scratch.path, 'ir');
    Directory(ir).createSync();
    for (final d in documents) {
      File(
        p.join(ir, areas.fileNameOf(d.area)),
      ).writeAsStringSync(writeIrYaml(d));
    }
    out = p.join(scratch.path, 'md');
    final buffer = StringBuffer();
    final code = await runIrspecs([
      'emit',
      '--standard',
      'markdown',
      '--ir',
      ir,
      '--areas',
      _areas,
      '--spec',
      _spec,
      '--out',
      out,
    ], out: buffer);
    expect(code, 0, reason: '$buffer');
    stdoutText = '$buffer';
  });
  tearDownAll(() => scratch.deleteSync(recursive: true));

  test('IRMD1: one document per IR document, named like it, and index.md', () {
    final names = Directory(
      out,
    ).listSync().map((e) => p.basename(e.path)).toList();
    final areas = IrAreaIndex(_catalog());
    final expected = {
      for (final d in documents)
        areas.fileNameOf(d.area).replaceFirst(RegExp(r'\.ir\.yaml$'), '.md'),
      'index.md',
    };
    expect(names.toSet(), expected);
    expect(names, contains('CE-DB_data_access.md'));
    expect(stdoutText, contains('index.md written'));
  });

  test('IRMD2: every document validates against irspecs-md/1.0', () async {
    for (final f in Directory(out).listSync().whereType<File>()) {
      expect(
        f.readAsStringSync(),
        startsWith('<!-- docspec: irspecs-md/1.0 -->\n'),
      );
      final doc = await DocSpecs.scanDocument(
        filePath: f.path,
        schemaFolder: _schemaFolder,
      );
      expect(doc.validationErrors, isEmpty, reason: p.basename(f.path));
    }
  });

  test('IRMD3: the index lists every area, the projects and the register\'s '
      'units with their areas', () {
    final index = File(p.join(out, 'index.md')).readAsStringSync();
    for (final d in documents) {
      expect(index, contains('| ${d.area} |'));
    }
    expect(index, contains('| server | `meridian_codespec_server` |'));
    expect(
      index,
      contains(
        '| `meridian_codespec_server` | server | CE-CF (dart-tom), CE-DB '
        '(dart-tom), CE-SU (dart-tom) | openapi, jsonschema |',
      ),
    );
  });

  test('IRMD4: CE-DB shows every declaration, marker and back-link of its IR '
      'document, a back-link linked into the rendition only when a heading '
      'there carries its token', () {
    final md = File(p.join(out, 'CE-DB_data_access.md')).readAsStringSync();
    final db = documents.firstWhere((d) => d.area == 'CE-DB');
    final headingIds = markdownHeadingSectionIds(
      File(_spec.replaceFirst('.docspecs.yaml', '.md')).readAsStringSync(),
    );
    var linked = 0;
    var plain = 0;
    for (final f in db.files) {
      expect(md, contains('--> ${f.file.path}\n'));
      for (final decl in f.file.declarations) {
        expect(md, contains('${decl.kind.name} `${decl.name}`'));
        for (final m in decl.markers) {
          expect(md, contains('`@${m.name}'));
        }
        for (final r in decl.docSpec ?? const <CsDocRef>[]) {
          if (headingIds.contains(r.sectionId)) {
            linked++;
            expect(
              md,
              contains(
                'meridian_order_management.md#${r.sectionId}): '
                '${r.description}',
              ),
            );
          } else {
            plain++;
            expect(md, contains('  - `${r.sectionId}`: ${r.description}'));
            expect(md, isNot(contains('#${r.sectionId})')));
          }
        }
      }
    }
    // Meridian has both: section-id tokens, and the field token `content`.
    expect(linked, greaterThan(0));
    expect(plain, greaterThan(0));
  });

  test('IRMD8: the section ids a rendition\'s headings carry', () {
    final ids = markdownHeadingSectionIds(
      '# <!--[SBP]--> Blueprint\n'
      'text <!--[NOT]--> here\n'
      '########### <!--[SSEL]--> Layout\n'
      '## <!--[SBP.ATS.ORD]--> Orders\n'
      '```markdown\n'
      '# <!--[FENCED]--> In a fence\n'
      '```\n',
    );
    expect(ids, {'SBP', 'SSEL', 'SBP.ATS.ORD', 'ORD'});
    final rendered = emitMarkdown(
      documents,
      catalog: _catalog(),
      specRendition: 'spec.md',
      renditionSectionIds: const {},
    );
    expect(
      rendered.files['CE-DB_data_access.md'],
      isNot(contains('](spec.md#')),
    );
  });

  test('IRMD5: a form-3b body is its steps in a fenced block', () {
    final sc = File(p.join(out, 'CE-SC_server_call.md')).readAsStringSync();
    expect(
      sc,
      contains(
        '```text\n'
        'call assembleRequestStageTheCoreFields(request)\n'
        'when assembleRequestAttachTheJustificationApplies(request):\n'
        '  call assembleRequestAttachTheJustification(request)\n'
        '```',
      ),
    );
  });

  test('IRMD6: markdown needs --areas; without --spec there are no unit '
      'rows and no links, and --out is required', () async {
    final err = StringBuffer();
    expect(
      await runIrspecs([
        'emit',
        '--standard',
        'markdown',
        '--ir',
        ir,
        '--out',
        p.join(scratch.path, 'x'),
      ], err: err),
      2,
    );
    expect('$err', contains('markdown needs --areas'));
    final plain = emitMarkdown(documents, catalog: _catalog());
    expect(plain.files['index.md'], contains('No generation-unit register'));
    expect(plain.files['CE-DB_data_access.md'], isNot(contains('](')));
    expect(
      await runIrspecs([
        'emit',
        '--standard',
        'markdown',
        '--ir',
        ir,
        '--areas',
        _areas,
      ], err: StringBuffer()),
      2,
    );
    final specAlone = StringBuffer();
    expect(
      await runIrspecs([
        'emit',
        '--ir',
        ir,
        '--spec',
        _spec,
        '--out',
        p.join(scratch.path, 'y'),
      ], err: specAlone),
      2,
    );
    expect('$specAlone', contains('--spec goes with --unit'));
  });

  test('IRMD7: the workspace mirror of the schema is the canonical copy', () {
    final mirror = File(
      p.join('../../../.tom/docspecs-schema/irspecs-md', _schemaName),
    );
    if (!mirror.existsSync()) {
      markTestSkipped('no workspace .tom/docspecs-schema (a lone checkout)');
      return;
    }
    expect(
      mirror.readAsStringSync(),
      File(p.join(_schemaFolder, _schemaName)).readAsStringSync(),
    );
  });
}
