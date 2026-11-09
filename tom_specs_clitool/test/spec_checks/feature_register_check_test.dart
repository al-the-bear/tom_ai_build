// Tests of the feature-register check (`tom_som_dart_runtime/lib/src/spec_checks/feature_register_check.dart`).
//
//   testkit :test --test-args="test/spec_checks/feature_register_check_test.dart"
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/spec_checks.dart';

/// A register of two features over three functional requirements, with one
/// prototype feature, written in the Blueprint's YAML shapes.
String register({
  String tenancyLinks = 'FRE-REQU-A, FRE-REQU-B, TERQ-REQU-X',
  String auditLinks = 'FRE-REQU-C',
  String prototypeFeature = 'FPE-ITEM-AUDIT',
  String total = '2',
}) =>
    '''
version: 2
document:
  SBP D00SolutionBlueprint:
    BTREQ requirements:
      FRE-REQU-LST functional:
        FRE-REQU-A:
          headline: A
        FRE-REQU-B:
          headline: B
        FRE-REQU-C:
          headline: C
      TERQ-REQU-LST technical:
        TERQ-REQU-X:
          headline: X
    DTRO delivery:
      FPE features:
        content:
          totalRegisteredFeatures: "$total"
        FPE-ITEM-LST items:
          FPE-ITEM-TENANCY:
            FETR traceability:
              linkedRequirements: $tenancyLinks
          FPE-ITEM-AUDIT:
            FETR traceability:
              linkedRequirements: $auditLinks
    XID experience:
      PFE-FEAT-LST features:
        PFE-FEAT-AUDIT-VIEW:
          content:
            featureId: $prototypeFeature
''';

List<String> rules(String yaml) => checkFeatureRegister(
  yaml,
).findings.map((f) => '${f.rule} ${f.id}').toList();

/// The workspace root, from the package folder `dart test` runs in
/// (tom_ai/ai_build/tom_specs_clitool).
const _ws = '../../..';

void main() {
  group('FRC-1: rules', () {
    test('FRC-1.1: a consistent register has no finding', () {
      final report = checkFeatureRegister(register());
      expect(report.findings, isEmpty);
      expect(report.features, 2);
      expect(report.functionalRequirements, 3);
      expect(report.prototypeFeatures, 1);
    });
    test('FRC-1.2: a requirement no feature links is unassigned', () {
      expect(
        rules(register(auditLinks: 'TERQ-REQU-X')),
        contains('unassigned FRE-REQU-C'),
      );
    });
    test('FRC-1.3: a requirement two features link is assigned twice', () {
      expect(
        rules(register(auditLinks: 'FRE-REQU-C, FRE-REQU-A')),
        contains('assignedTwice FRE-REQU-A'),
      );
    });
    test('FRC-1.4: a link to an id the document lacks is reported', () {
      expect(
        rules(register(auditLinks: 'FRE-REQU-C, FRE-REQU-GONE')),
        contains('unknownRequirement FPE-ITEM-AUDIT'),
      );
    });
    test('FRC-1.5: a prototype feature naming no feature is reported', () {
      expect(
        rules(register(prototypeFeature: 'FPE-ITEM-NONE')),
        contains('unknownFeature PFE-FEAT-AUDIT-VIEW'),
      );
    });
    test('FRC-1.6: a stated total that differs is reported', () {
      expect(rules(register(total: '3')), contains('countMismatch FPE'));
    });
  });

  group('FRC-2: the real Blueprint', () {
    test('FRC-2.1: the tom_uam Blueprint passes', () {
      final file = File(
        '$_ws/tom_uam/tom_specs/phase2_solution_blueprint/tom_uam.sbp.docspecs.yaml',
      );
      if (!file.existsSync()) {
        markTestSkipped('run from the workspace root');
        return;
      }
      final report = checkFeatureRegister(file.readAsStringSync());
      expect(report.findings.map((f) => '$f'), isEmpty);
    });
  });
}
