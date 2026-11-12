/// IR Specs' step language (`irspecs_ir.md`, § Steps): every form-3b body of
/// both Meridian trios reads into steps and validates, and each validation
/// rule and each reading refusal fails on a case built for it.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

final _trios = {
  'phase4_codespecs_run': [
    for (final locus in ['shared', 'client', 'server'])
      p.absolute('../tom_specs_samples/phase4_codespecs_run/codespec/$locus'),
  ],
  'meridian_codespecs': [
    for (final locus in ['shared', 'client', 'server'])
      p.absolute(
        '../tom_som_conformance/samples/meridian_codespecs/'
        'meridian_codespec_$locus',
      ),
  ],
};

final _areas = IrAreaIndex(
  CodeSpecsAreaCatalog.fromJson(
    jsonDecode(
          File(
            '../tom_specs_model/generated-doc/codespecs/codespecs_areas.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>,
  ),
);

List<IrDocument> _irOfTrio(List<String> roots) {
  CsLocusProject read(CsLocus locus, String root) =>
      readCsLocusProjectFromDirectory(
        locus: locus,
        packageName: p.basename(root),
        root: root,
      );
  return irFromCsModel(
    shared: read(CsLocus.shared, roots[0]),
    client: read(CsLocus.client, roots[1]),
    server: read(CsLocus.server, roots[2]),
    areas: _areas,
  );
}

/// The IR of a client project holding [caller] and its collaborator class.
List<IrDocument> _irOf(String caller, {String? collaborator}) {
  CsLocusProject empty(CsLocus locus) =>
      readCsLocusProject(locus: locus, packageName: locus.name, sources: {});
  return irFromCsModel(
    shared: empty(CsLocus.shared),
    client: readCsLocusProject(
      locus: CsLocus.client,
      packageName: 'client',
      sources: {
        'lib/src/server_call/c.dart': caller,
        'lib/src/server_call/c_collaborator.dart':
            collaborator ?? _collaborator,
      },
    ),
    server: empty(CsLocus.server),
    areas: _areas,
  );
}

const _collaborator = '''
@CsCollaborator()
abstract class CCollaborator {
  Future<void> runStageIt(R request);
  Future<bool> runCheckApplies(R request);
  Future<int> countTheLines(R request);
  bool runPlainGuardApplies(R request);
  Future<bool> runFlag(R request);
}
''';

/// A caller class whose `run(R request)` body is [body].
String _caller(String body, {String returns = 'Future<void>'}) =>
    '''
class C {
  late final CCollaborator collaborator;

  $returns run(R request) async {
$body
  }
}
''';

List<IrBodySteps> _records(List<IrDocument> documents) => [
  for (final d in documents)
    for (final f in d.files) ...f.steps,
];

void main() {
  for (final MapEntry(key: name, value: roots) in _trios.entries) {
    group('IRST1 ($name): every 3b body is steps', () {
      final documents = _irOfTrio(roots);
      final records = _records(documents);

      test('every collaborator-calling 3b body has a step record', () {
        final bodies = [
          for (final d in documents)
            for (final f in d.files)
              for (final decl in f.file.declarations)
                if (decl.isTopLevel)
                  for (final b in decl.bodies)
                    if (b.isPseudoImplementation &&
                        b.calls.any((c) => c.receiver == kCollaboratorField))
                      '${decl.name}.${b.name}',
        ];
        expect([
          for (final r in records) '${r.owner}.${r.body}',
        ], unorderedEquals(bodies));
      });

      test('every record reads into steps and validates', () {
        expect([
          for (final r in records)
            if (r.issue != null) '${r.owner}.${r.body}: ${r.issue}',
        ], isEmpty);
        expect(validateIrSteps(documents), isEmpty);
      });

      test('the steps survive the YAML round trip', () {
        final back = [for (final d in documents) readIrYaml(writeIrYaml(d))];
        String shape(List<IrBodySteps> rs) => [
          for (final r in rs) '${r.owner}.${r.body}=${_render(r.steps!)}',
        ].join('\n');
        expect(shape(_records(back)), shape(records));
        expect(validateIrSteps(back), isEmpty);
      });
    });
  }

  test('IRST2: the meridian trio holds the four server-call bodies', () {
    final records = _records(_irOfTrio(_trios['meridian_codespecs']!));
    final byBody = {
      for (final r in records) '${r.owner}.${r.body}': _render(r.steps!),
    };
    expect(byBody, {
      'AmendOrderLineCall.assembleRequest':
          'call assembleRequestStageTheCoreFields(request); '
          'if assembleRequestAttachTheJustificationApplies(request) '
          '{ call assembleRequestAttachTheJustification(request) }',
      'AmendOrderLineCall.handleResponse':
          'call handleResponseApplyThePriceSnapshot(response)',
      'AmendOrderLineCall.handleError':
          'call handleErrorSurfaceTheRejection(error)',
      'FetchOrderWorkListCall.handleResponse':
          'call handleResponseRenderTheWorkListPage(response)',
    });
  });

  group('IRST3: the validation rules', () {
    List<String> rulesOf(List<IrDocument> documents) => [
      for (final v in validateIrSteps(documents)) v.rule,
    ];

    test('a valid body passes', () {
      final documents = _irOf(
        _caller('''
    await collaborator.runStageIt(request);
    if (await collaborator.runCheckApplies(request)) {
      await collaborator.runStageIt(request);
      return;
    }
'''),
      );
      expect(validateIrSteps(documents), isEmpty);
    });

    test('S1: a body that is not steps', () {
      final documents = _irOf(
        _caller('''
    for (final x in request.lines) {
      await collaborator.runStageIt(request);
    }
'''),
      );
      expect(rulesOf(documents), ['S1']);
      expect(validateIrSteps(documents).single.message, contains('B7'));
    });

    test('S2: a method the collaborator does not have', () {
      final documents = _irOf(
        _caller('    await collaborator.runMissing(request);'),
      );
      expect(rulesOf(documents), ['S2']);
    });

    test('S2: a collaborator type that is no @CsCollaborator class', () {
      final documents = _irOf(
        _caller('    await collaborator.runStageIt(request);'),
        collaborator: 'abstract class CCollaborator {}',
      );
      expect(rulesOf(documents), contains('S2'));
    });

    test('S3: a condition on a method that is no guard', () {
      final documents = _irOf(
        _caller('''
    if (await collaborator.runFlag(request)) {
      await collaborator.runStageIt(request);
    }
'''),
      );
      expect(rulesOf(documents), ['S3']);
    });

    test('S3: a guard called as a step', () {
      final documents = _irOf(
        _caller('    await collaborator.runCheckApplies(request);'),
      );
      expect(rulesOf(documents), ['S3']);
    });

    test('S4: a void body returning a value', () {
      final documents = _irOf(
        _caller('    return collaborator.runStageIt(request);'),
      );
      expect(rulesOf(documents), ['S4']);
    });

    test('S4: a value body not ending in a returned call', () {
      final documents = _irOf(
        _caller(
          '    await collaborator.countTheLines(request);',
          returns: 'Future<int>',
        ),
      );
      expect(rulesOf(documents), ['S4']);
    });

    test('S5: a call not passing the body\'s parameters', () {
      final documents = _irOf(
        _caller('    await collaborator.runStageIt(request.lines);'),
      );
      expect(rulesOf(documents), ['S5']);
    });
  });

  group('IRST4: what is never a step names its rule', () {
    String? ruleOf(String body) {
      final record = _records(_irOf(_caller(body))).single;
      return record.issue?.rule;
    }

    test('B2: a call on something other than the collaborator', () {
      expect(ruleOf('    await request.save();'), 'B2');
    });

    test('B3: a local binding', () {
      expect(
        ruleOf('    final n = await collaborator.countTheLines(request);'),
        'B3',
      );
    });

    test('B4: a condition that is no guard call', () {
      expect(
        ruleOf('''
    if (request.lines.isEmpty) {
      await collaborator.runStageIt(request);
    }
'''),
        'B4',
      );
    });

    test('B6: an else', () {
      expect(
        ruleOf('''
    if (await collaborator.runCheckApplies(request)) {
      await collaborator.runStageIt(request);
    } else {
      await collaborator.runStageIt(request);
    }
'''),
        'B6',
      );
    });

    test('B7: a switch', () {
      expect(
        ruleOf('''
    switch (request.kind) {
      case 1:
        await collaborator.runStageIt(request);
    }
'''),
        'B7',
      );
    });

    test('3b: a statement no 3b body admits', () {
      expect(ruleOf('    request.count = 1;'), '3b');
    });
  });
}

String _render(List<IrStep> steps) => [
  for (final step in steps)
    switch (step) {
      IrCallStep(:final method, :final arguments) =>
        'call $method(${arguments.join(', ')})',
      IrReturnStep(:final method, :final arguments) =>
        method == null ? 'return' : 'return $method(${arguments.join(', ')})',
      IrGuardedStep(:final guard, :final arguments, :final steps) =>
        'if $guard(${arguments.join(', ')}) { ${_render(steps)} }',
    },
].join('; ');
