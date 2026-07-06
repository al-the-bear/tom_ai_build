// HAND-AUTHORED — not generated. Preserved across `generate_som` runs (the
// generator only rewrites lib/, meta/, schemas/ and pubspec.yaml).
//
// Behavioural suite for the **actually-committed** generated typed object model
// (`tom_som_dart_v0`), as opposed to the emitter-golden *fixture* exercised by
// `tom_specs_clitool/test/som_dart_emitter_test.dart`. It instantiates the real
// `D00SolutionBlueprint` root over a generic `SpecDocument` and proves the typed
// facade is a faithful editing surface over the shared document (spec §3):
// typed↔generic parity, nested-section path derivation, the generated model
// version, and the instantiation-time version check (§2.2).
//
// Run with `dart test` from this package (`tom_som_dart_v0`).
library;

import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';
import 'package:test/test.dart';

void main() {
  group('tom_som_dart_v0 generated D00SolutionBlueprint', () {
    test('roots at the PD segment', () {
      final pd = D00SolutionBlueprint(SpecDocument());
      expect(pd.path, 'SBP');
    });

    test('content round-trips typed -> generic and generic -> typed', () {
      final doc = SpecDocument();
      final pd = D00SolutionBlueprint(doc);

      // Typed write, generic read.
      pd.content = 'A clear vision';
      expect(doc.content('SBP/content'), 'A clear vision');

      // Generic write, typed read.
      doc.setContent('SBP/content', 'Revised vision');
      expect(pd.content, 'Revised vision');
    });

    test('an unset content leaf reads as the empty string', () {
      expect(D00SolutionBlueprint(SpecDocument()).content, '');
    });

    test('nested complex sections derive their path under the root', () {
      final pd = D00SolutionBlueprint(SpecDocument());
      // A representative nested section accessor returns a SomNode rooted at
      // the parent path — the same path the generic API would address.
      expect(pd.currentLandscape.path, 'SBP/currentLandscape');
      expect(pd.introductionAndScope.path, 'SBP/introductionAndScope');
    });

    test('a value written through a nested typed section is visible generically',
        () {
      final doc = SpecDocument();
      final pd = D00SolutionBlueprint(doc);
      final headerPath = pd.documentControl.path;
      // documentControl is a nested section; set a generic content leaf beneath
      // the nested node and confirm the typed path addresses the same place.
      doc.setContent('$headerPath/probe', 'x');
      expect(doc.content('SBP/documentControl/probe'), 'x');
    });

    test('reports the generated v0 model version (1.0)', () {
      expect(D00SolutionBlueprint.modelVersion, '1.0');
      expect(D00SolutionBlueprint(SpecDocument()).objectModelVersion, '1.0');
    });
  });

  group('tom_som_dart_v0 instantiation-time version check (§2.2)', () {
    test('a new / unstamped document is editable', () {
      expect(() => D00SolutionBlueprint(SpecDocument()), returnsNormally);
      expect(() => D00SolutionBlueprint(SpecDocument(), documentVersion: '1.0'),
          returnsNormally);
    });

    test('a newer same-major document is rejected', () {
      expect(() => D00SolutionBlueprint(SpecDocument(), documentVersion: '1.1'),
          throwsA(isA<SomVersionException>()));
    });

    test('a different major document is rejected', () {
      expect(() => D00SolutionBlueprint(SpecDocument(), documentVersion: '2.0'),
          throwsA(isA<SomVersionException>()));
    });
  });

  group('tom_som_dart_v0 non-throwing editabilityFor (§ item 8)', () {
    test('classifies every §2.2 outcome without throwing', () {
      expect(D00SolutionBlueprint.editabilityFor(null), SomEditability.editable);
      expect(
          D00SolutionBlueprint.editabilityFor('1.0'), SomEditability.editable);
      expect(D00SolutionBlueprint.editabilityFor('1.1'),
          SomEditability.rejectedNewerMinor);
      expect(D00SolutionBlueprint.editabilityFor('2.0'),
          SomEditability.readOnlyCrossMajor);
      expect(D00SolutionBlueprint.editabilityFor('nope'),
          SomEditability.invalidVersion);
    });

    test('editable iff the constructor accepts the same stamp', () {
      for (final stamp in [null, '1.0', '1.1', '2.0', 'nope']) {
        final editable = D00SolutionBlueprint.editabilityFor(stamp) ==
            SomEditability.editable;
        var accepted = true;
        try {
          D00SolutionBlueprint(SpecDocument(), documentVersion: stamp);
        } on SomVersionException {
          accepted = false;
        }
        expect(editable, accepted, reason: 'stamp "$stamp"');
      }
    });
  });

  group('shared sample: typed and generic access agree', () {
    // Loads the language-agnostic shared sample authored by
    // `tool/build_shared_sample.dart` and proves the concrete facade and the
    // raw string-path API read the same values from a real, broad document —
    // the same guarantee the d_/e_ examples demonstrate at runtime.
    late SpecDocument doc;
    late D00SolutionBlueprint sbp;

    setUp(() {
      final file = File(
          '../tom_som_conformance/samples/meridian_order_management.docspecs.yaml');
      final decoded = SpecDocumentYaml.decode(file.readAsStringSync());
      doc = SpecDocument()..loadJson(decoded.document);
      sbp = D00SolutionBlueprint(doc, documentVersion: decoded.modelVersion);
    });

    test('top-level sections match generic reads', () {
      expect(sbp.content, doc.content('SBP/content'));
      expect(sbp.introductionAndScope.content,
          doc.content('SBP/introductionAndScope/content'));
      expect(sbp.requirements.content, doc.content('SBP/requirements/content'));
      expect(sbp.targetOperatingModelConcept.content,
          doc.content('SBP/targetOperatingModelConcept/content'));
    });

    test('nested section matches generic read', () {
      expect(sbp.introductionAndScope.goals.content,
          doc.content('SBP/introductionAndScope/goals/content'));
    });

    test('list is populated and elements match generic reads', () {
      final metrics = sbp.currentLandscape.operationalMetrics;
      final itemPaths = doc.listItems('SBP/currentLandscape/CUOPME-OPER-LST');
      expect(metrics.length, itemPaths.length);
      expect(metrics.length, greaterThanOrEqualTo(4));
      for (var i = 0; i < metrics.length; i++) {
        expect(metrics[i].content, doc.content('${itemPaths[i]}/content'));
      }
    });

    test('sample exercises most of the blueprint breadth', () {
      // Every top-level SBP section that carries a content leaf should be
      // populated, so the sample is a genuine breadth fixture.
      for (final path in const [
        'SBP/content',
        'SBP/documentControl/content',
        'SBP/introductionAndScope/content',
        'SBP/glossaryAndAbbreviations/content',
        'SBP/stakeholdersAndGovernance/content',
        'SBP/currentLandscape/content',
        'SBP/assumptionsConstraintsDependencies/content',
        'SBP/targetOperatingModelConcept/content',
        'SBP/informationAndDataModel/content',
        'SBP/requirements/content',
        'SBP/solutionArchitectureAndTechnology/content',
        'SBP/securityAndAccessModel/content',
        'SBP/experienceAndInterfaceDesign/content',
        'SBP/qualityAndAcceptanceModel/content',
        'SBP/deliveryTransitionAndRollout/content',
      ]) {
        expect(doc.content(path), isNotNull, reason: 'missing $path');
        expect(doc.content(path), isNotEmpty, reason: 'empty $path');
      }
    });
  });

  group('content-only list convenience (§ item 9)', () {
    test('addContent appends and fills a content-only element in one call', () {
      final doc = SpecDocument();
      final sbp = D00SolutionBlueprint(doc);
      final metrics = sbp.currentLandscape.operationalMetrics;
      final m = metrics.addContent('Orders/day: 12k');
      // The element is created and its content leaf set, visible both ways.
      expect(m.content, 'Orders/day: 12k');
      expect(metrics.length, 1);
      expect(doc.content('${m.path}/content'), 'Orders/day: 12k');
    });

    test('contents reads every element content leaf, matching the index loop',
        () {
      final doc = SpecDocument();
      final sbp = D00SolutionBlueprint(doc);
      final metrics = sbp.currentLandscape.operationalMetrics;
      metrics.addContent('one');
      metrics.addContent('two');
      metrics.addContent('three');
      expect(metrics.contents.toList(), ['one', 'two', 'three']);
      // Parity with reading each element's typed .content.
      expect(metrics.contents.toList(),
          [for (var i = 0; i < metrics.length; i++) metrics[i].content]);
    });
  });

  group('aligned absence semantics (§ item 5)', () {
    test('a section isEmpty until any value is written under it', () {
      final doc = SpecDocument();
      final sbp = D00SolutionBlueprint(doc);
      expect(sbp.requirements.isEmpty, isTrue);
      // A nested content value fills the section (subtree emptiness).
      sbp.requirements.content = 'Some requirements';
      expect(sbp.requirements.isEmpty, isFalse);
      // Clearing it empties the section again.
      sbp.requirements.content = '';
      expect(sbp.requirements.isEmpty, isTrue);
    });

    test('typed isEmpty and generic hasValuesUnder agree', () {
      final doc = SpecDocument();
      final sbp = D00SolutionBlueprint(doc);
      final path = sbp.requirements.path;
      expect(sbp.requirements.isEmpty, !doc.hasValuesUnder(path));
      doc.setContent('$path/content', 'x');
      expect(sbp.requirements.isEmpty, !doc.hasValuesUnder(path));
      expect(sbp.requirements.isEmpty, isFalse);
    });

    test('hasContent gives the generic path the typed .content answer', () {
      final doc = SpecDocument();
      final sbp = D00SolutionBlueprint(doc);
      final leaf = '${sbp.requirements.path}/content';
      // Typed '' and generic hasContent(false) now agree the leaf is empty.
      expect(sbp.requirements.content, '');
      expect(doc.hasContent(leaf), isFalse);
      sbp.requirements.content = 'Filled';
      expect(sbp.requirements.content.isNotEmpty, doc.hasContent(leaf));
      expect(doc.hasContent(leaf), isTrue);
    });
  });

  group('canHaveContent structural content-slot predicate (§ item 10)', () {
    test('a content-bearing section reports true', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      // Goals declares the standard `content` leaf.
      expect(sbp.introductionAndScope.goals.canHaveContent, isTrue);
    });

    test('a container-only section reports false', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      // SystemsToReplace holds only child sections — no `content` leaf.
      expect(sbp.introductionAndScope.systemsToReplace.canHaveContent, isFalse);
    });

    test('the document root (which has content) reports true', () {
      expect(D00SolutionBlueprint(SpecDocument()).canHaveContent, isTrue);
    });

    test('it is structural — independent of whether content is written', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      final goals = sbp.introductionAndScope.goals;
      expect(goals.canHaveContent, isTrue);
      goals.content = 'Grow revenue';
      expect(goals.canHaveContent, isTrue);
      // A filled container-only sibling still reports false.
      expect(sbp.introductionAndScope.systemsToReplace.canHaveContent, isFalse);
    });

    test('canHaveContent==true iff the .content accessor is usable', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      final goals = sbp.introductionAndScope.goals;
      // The predicate is true exactly where reading/writing `.content` is valid.
      expect(goals.canHaveContent, isTrue);
      goals.content = 'x';
      expect(goals.content, 'x');
    });
  });

  group('one-call loading (§ item 4)', () {
    const samplePath =
        '../tom_som_conformance/samples/meridian_order_management.docspecs.yaml';

    test('loadYaml collapses decode → loadJson → thread-version to one call', () {
      final yaml = File(samplePath).readAsStringSync();

      // The former three-step incantation.
      final decoded = SpecDocumentYaml.decode(yaml);
      final manualDoc = SpecDocument()..loadJson(decoded.document);
      final manual =
          D00SolutionBlueprint(manualDoc, documentVersion: decoded.modelVersion);

      // The one-call convenience.
      final oneCall = D00SolutionBlueprint.loadYaml(yaml);

      // The document stamp is applied automatically — no manual threading.
      expect(oneCall.doc.modelVersion, decoded.modelVersion);
      // Both paths read identical content from the shared sample.
      expect(oneCall.content, manual.content);
      expect(oneCall.introductionAndScope.goals.content,
          manual.introductionAndScope.goals.content);
      expect(oneCall.currentLandscape.operationalMetrics.length,
          manual.currentLandscape.operationalMetrics.length);
    });

    test('loadFile reads the file then delegates to loadYaml', () {
      final fromFile = D00SolutionBlueprint.loadFile(samplePath);
      final fromYaml =
          D00SolutionBlueprint.loadYaml(File(samplePath).readAsStringSync());
      expect(fromFile.doc.modelVersion, fromYaml.doc.modelVersion);
      expect(fromFile.content, fromYaml.content);
    });

    test('SpecDocument.fromYaml retains the parsed model version', () {
      const yaml = '''
version: 1
modelVersion: "1.0"
document:
  content:
    "SBP/content": |2-
      Hello
''';
      final doc = SpecDocument.fromYaml(yaml);
      expect(doc.modelVersion, '1.0');
      expect(doc.content('SBP/content'), 'Hello');
    });

    test('a document with no modelVersion stamp loads with a null stamp', () {
      const yaml = 'version: 1\ndocument: {}\n';
      final doc = SpecDocument.fromYaml(yaml);
      expect(doc.modelVersion, isNull);
      // A null stamp is accepted by the facade (a new document is editable).
      expect(() => D00SolutionBlueprint.loadYaml(yaml), returnsNormally);
    });
  });
}
