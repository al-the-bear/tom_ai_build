// HAND-AUTHORED — not generated. Preserved across `generate_som` runs (the
// generator only rewrites lib/, meta/, schemas/ and pubspec.yaml).
//
// Behavioural suite for the **actually-committed** generated typed object model
// (`tom_som_dart_v0`), as opposed to the emitter-golden *fixture* exercised by
// `tom_specs_clitool/test/som_dart_emitter_test.dart`. It instantiates the real
// `D00SolutionBlueprint` root over a generic `SpecDocument` and proves the typed
// facade is a faithful editing surface over the shared document (SOM §6):
// typed↔generic parity, nested-section path derivation, the generated model
// version, and the instantiation-time version check (SOM §4.2).
//
// Run with `dart test` from this package (`tom_som_dart_v0`).
library;

import 'dart:convert';
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

    test('reports the generated v0 model version (1.1)', () {
      expect(D00SolutionBlueprint.modelVersion, '1.1');
      expect(D00SolutionBlueprint(SpecDocument()).objectModelVersion, '1.1');
    });
  });

  group('tom_som_dart_v0 instantiation-time version check (SOM §4.2)', () {
    test('a new / unstamped document is editable', () {
      expect(() => D00SolutionBlueprint(SpecDocument()), returnsNormally);
      expect(() => D00SolutionBlueprint(SpecDocument(), documentVersion: '1.1'),
          returnsNormally);
    });

    test('an older same-major document is editable', () {
      expect(() => D00SolutionBlueprint(SpecDocument(), documentVersion: '1.0'),
          returnsNormally);
    });

    test('a newer same-major document is rejected', () {
      expect(() => D00SolutionBlueprint(SpecDocument(), documentVersion: '1.2'),
          throwsA(isA<SomVersionException>()));
    });

    test('a different major document is rejected', () {
      expect(() => D00SolutionBlueprint(SpecDocument(), documentVersion: '2.0'),
          throwsA(isA<SomVersionException>()));
    });
  });

  group('tom_som_dart_v0 non-throwing editabilityFor (SOM §21)', () {
    test('classifies every SOM §4.2 outcome without throwing', () {
      expect(D00SolutionBlueprint.editabilityFor(null), SomEditability.editable);
      expect(
          D00SolutionBlueprint.editabilityFor('1.0'), SomEditability.editable);
      expect(
          D00SolutionBlueprint.editabilityFor('1.1'), SomEditability.editable);
      expect(D00SolutionBlueprint.editabilityFor('1.2'),
          SomEditability.rejectedNewerMinor);
      expect(D00SolutionBlueprint.editabilityFor('2.0'),
          SomEditability.readOnlyCrossMajor);
      expect(D00SolutionBlueprint.editabilityFor('nope'),
          SomEditability.invalidVersion);
    });

    test('editable iff the constructor accepts the same stamp', () {
      for (final stamp in [null, '1.0', '1.1', '1.2', '2.0', 'nope']) {
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
      // The shared sample is a hierarchical-v2 `*.docspecs.yaml` (SOM §12): load
      // it with the generated one-call loader, which decodes against the SBP
      // metadata tree and applies the yaml's modelVersion stamp.
      sbp = D00SolutionBlueprint.loadFile(
          '../tom_som_conformance/samples/meridian_order_management.docspecs.yaml');
      doc = sbp.doc;
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

  group('content-only list convenience (SOM §21)', () {
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

  group('aligned absence semantics (SOM §21)', () {
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

  // `canHaveContent` (SOM §21) asks of a *type*, never of a document: does this
  // node declare the standard `content` text leaf? Since
  // `tom_specs_model_rules.md` §10.2 requires `content: String?` on every
  // section class, the line the predicate draws in the generated facade runs
  // between a **section** (always true) and a **non-section node** — a scalar
  // list item, which carries its value at its own item path and has no nested
  // `content` leaf.
  group('canHaveContent structural content-slot predicate (SOM §21)', () {
    test('a content-bearing section reports true', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      // Goals declares the standard `content` leaf.
      expect(sbp.introductionAndScope.goals.canHaveContent, isTrue);
    });

    test('a scalar list item reports false', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      // A scalar list element is a `SomScalar`: its value *is* its item path,
      // so it declares no `content` leaf and inherits the `SomNode` false
      // default. This is the whole of the predicate's surviving false side.
      final item = sbp.introductionAndScope.systemsToReplace
          .migrationConsiderations.escalationProcedures
          .add();
      expect(item.canHaveContent, isFalse);
    });

    test('every section class reports true — including a pure container', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      // SystemsToReplace holds two child sections and no fields of its own, yet
      // it still declares `content` (its `@ContentHelp` asks the author to
      // introduce the replacement portfolio). Pins §10.2's universal-content
      // rule at the generated facade: this goes red the day a section class
      // without a `content` leaf is reintroduced.
      expect(sbp.introductionAndScope.systemsToReplace.canHaveContent, isTrue);
    });

    test('the document root (which has content) reports true', () {
      expect(D00SolutionBlueprint(SpecDocument()).canHaveContent, isTrue);
    });

    test('a section whose content is @Unused still reports true', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      // DocumentControl carries `@Unused()` on its `content` member — one of
      // the ten in the model. That is an *authoring* statement ("no prose is
      // expected here", `tom_specs_model_rules.md` §5.6), not a claim that the
      // slot is absent, so the *capability* answer stays true and the slot
      // stays writable. Pins SOM §21: `canHaveContent` never consults the
      // annotation, and no second predicate exists for the authoring question
      // — a consumer reads the content node's `unused` flag in the metadata.
      final control = sbp.documentControl;
      expect(control.canHaveContent, isTrue);
      control.content = 'Prose is possible even where it is not expected.';
      expect(control.content,
          'Prose is possible even where it is not expected.');
      expect(control.canHaveContent, isTrue);
    });

    test('it is structural — independent of whether content is written', () {
      final sbp = D00SolutionBlueprint(SpecDocument());
      final goals = sbp.introductionAndScope.goals;
      expect(goals.canHaveContent, isTrue);
      goals.content = 'Grow revenue';
      expect(goals.canHaveContent, isTrue);
      // A filled scalar item still reports false.
      final item = sbp.introductionAndScope.systemsToReplace
          .migrationConsiderations.escalationProcedures
          .add();
      item.value = 'Escalate to the migration board';
      expect(item.canHaveContent, isFalse);
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

  group('one-call loading (SOM §21)', () {
    // The round-trip fixtures are built in-memory and encoded to the canonical
    // v2 wire format, so the suite stays independent of the shared conformance
    // sample.
    String buildV2Yaml({String? modelVersion = '1.0'}) {
      final doc = SpecDocument();
      final sbp = D00SolutionBlueprint(doc);
      sbp.content = 'A clear vision';
      sbp.introductionAndScope.goals.content = 'Grow revenue';
      sbp.currentLandscape.operationalMetrics
        ..addContent('Orders/day: 12k')
        ..addContent('Manual reconciliation: ~12 h/week');
      return SpecDocumentYaml.encode(
          document: doc,
          tree: d00SolutionBlueprintMetaTree,
          modelVersion: modelVersion);
    }

    test('loadYaml collapses decode → thread-version to one call', () {
      final yaml = buildV2Yaml();

      // The former multi-step incantation.
      final decoded =
          SpecDocumentYaml.decode(yaml, d00SolutionBlueprintMetaTree);
      final manual = D00SolutionBlueprint(decoded.document,
          documentVersion: decoded.modelVersion);

      // The one-call convenience.
      final oneCall = D00SolutionBlueprint.loadYaml(yaml);

      // The document stamp is applied automatically — no manual threading.
      expect(oneCall.doc.modelVersion, decoded.modelVersion);
      // Both paths read identical content from the round-tripped document.
      expect(oneCall.content, manual.content);
      expect(oneCall.introductionAndScope.goals.content,
          manual.introductionAndScope.goals.content);
      expect(oneCall.currentLandscape.operationalMetrics.length,
          manual.currentLandscape.operationalMetrics.length);
    });

    test('loadFile reads the file then delegates to loadYaml', () {
      final tmp = Directory.systemTemp.createTempSync('som_v0_test_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final yaml = buildV2Yaml();
      final path = '${tmp.path}/sample.docspecs.yaml';
      File(path).writeAsStringSync(yaml);
      final fromFile = D00SolutionBlueprint.loadFile(path);
      final fromYaml = D00SolutionBlueprint.loadYaml(yaml);
      expect(fromFile.doc.modelVersion, fromYaml.doc.modelVersion);
      expect(fromFile.content, fromYaml.content);
    });

    test('SpecDocument.fromYaml retains the parsed model version', () {
      final doc = SpecDocument.fromYaml(
          buildV2Yaml(), d00SolutionBlueprintMetaTree);
      expect(doc.modelVersion, '1.0');
      expect(doc.content('SBP/content'), 'A clear vision');
    });

    test('a document with no modelVersion stamp loads with a null stamp', () {
      final yaml = buildV2Yaml(modelVersion: null);
      final doc = SpecDocument.fromYaml(yaml, d00SolutionBlueprintMetaTree);
      expect(doc.modelVersion, isNull);
      // A null stamp is accepted by the facade (a new document is editable).
      expect(() => D00SolutionBlueprint.loadYaml(yaml), returnsNormally);
    });
  });

  // Live-document conformance case (YRD8 / dsa7). The cross-language golden
  // harness (`tom_som_conformance/tool/regenerate_golden.sh` +
  // `compare_golden.dart`) already exercises the shared Meridian sample end to
  // end and the Dart golden is the reference reading. This committed group is
  // the *durability guard* for the three live-document guarantees the golden's
  // `generic-*`, `docspecs`, and `meta-*` sections encode, plus a fourth the
  // golden has no section for — instance-tier cleanliness — so a regression
  // that silently drops any of them from the Dart reference fails `dart test` —
  // not only a full nine-toolchain golden run.
  group('shared sample: live-document case durability (YRD8 / dsa7)', () {
    const samplePath =
        '../tom_som_conformance/samples/meridian_order_management.docspecs.yaml';
    const sampleMdPath =
        '../tom_som_conformance/samples/meridian_order_management.md';
    const schemaPath =
        'schemas/solution-blueprint/solution-blueprint.1.0.docspecs-schema.yaml';
    const modelMetaPath = 'meta/spec_model.meta.json';

    test('round-trip: decode → encode → decode is a stable reading', () {
      // Mirrors the golden's `generic-content` / `generic-lists` sections: the
      // full generic reading survives a re-serialisation round-trip byte-for-
      // byte at the value level.
      final original =
          SpecDocument.fromFile(samplePath, d00SolutionBlueprintMetaTree);
      final reEncoded = SpecDocumentYaml.encode(
        document: original,
        tree: d00SolutionBlueprintMetaTree,
        modelVersion: original.modelVersion,
      );
      final roundTripped =
          SpecDocument.fromYaml(reEncoded, d00SolutionBlueprintMetaTree);

      expect(roundTripped.modelVersion, original.modelVersion);

      final originalContent = original.contentPaths.toList()..sort();
      final roundTripContent = roundTripped.contentPaths.toList()..sort();
      expect(roundTripContent, originalContent,
          reason: 'content-path set changed across round-trip');
      for (final p in originalContent) {
        expect(roundTripped.content(p), original.content(p),
            reason: 'content diverged at $p');
      }

      final originalLists = original.listPaths.toList()..sort();
      final roundTripLists = roundTripped.listPaths.toList()..sort();
      expect(roundTripLists, originalLists,
          reason: 'list-path set changed across round-trip');
      for (final p in originalLists) {
        expect(roundTripped.listItems(p), original.listItems(p),
            reason: 'list items diverged at $p');
      }
    });

    test('validation: sample markdown validates cleanly against the schema',
        () {
      // Mirrors the golden's `docspecs` section: root `SBP`, zero schema
      // warnings, zero markdown violations.
      final schema =
          DocSpecsSchema.fromYamlText(File(schemaPath).readAsStringSync());
      final sampleMd = File(sampleMdPath).readAsStringSync();
      final violations = DocSpecsValidator(schema).validateMarkdown(sampleMd);

      expect(schema.rootSectionId, 'SBP');
      expect(schema.warnings, isEmpty,
          reason: 'generated schema carries warnings');
      expect(violations, isEmpty,
          reason: 'sample markdown violates the generated schema');
    });

    test('validation: sample document validates cleanly on the instance tier',
        () {
      // The second tier of the same gate `build_shared_sample.dart` applies.
      // It is a separate assertion because the two tiers ask disjoint
      // questions: the schema tier above asks whether every required field is
      // filled, this one asks whether the values are admissible — kinds, form
      // keys, list minima, and `refersTo` resolution (SOM §9). A sample that
      // names a message key, a role or a route nothing declares passes the
      // first and fails this one. Asserted here as well as in the builder
      // because the sample is *committed*: a hand-edit or a merge can reach it
      // without anyone re-running the builder.
      final model = SpecModel.fromJson(
          jsonDecode(File(modelMetaPath).readAsStringSync())
              as Map<String, dynamic>);
      final doc =
          SpecDocument.fromFile(samplePath, d00SolutionBlueprintMetaTree);

      expect(validateDocument(model, doc), isEmpty,
          reason: 'sample document violates the instance tier');
    });

    test('node operations: metadata tree / nav / id resolve to the same node',
        () {
      // Mirrors the golden's `meta` / `meta-nav` / `meta-id` sections: a node
      // reached by path, by dot-notation nav, and by hoisted id is one and the
      // same node.
      final tree = d00SolutionBlueprintMetaTree;

      final listByPath = tree.byPath('SBP/currentLandscape/CUOPME-OPER-LST');
      expect(listByPath, isNotNull);
      expect(listByPath!.kind, SomMetaKind.list);

      final navRef = d00SolutionBlueprint.currentLandscape.operationalMetrics;
      expect(navRef.path, 'SBP/currentLandscape/CUOPME-OPER-LST');
      expect(identical(navRef.meta, listByPath), isTrue,
          reason: 'nav did not resolve to the byPath node');

      // Hoisted-id accessor agrees with the dot-notation position.
      final idRef = SBP.RVENT_REVS_LST.item(0);
      final navItem =
          d00SolutionBlueprint.documentControl.revisionHistory.item(0);
      expect(idRef.path, navItem.path);
      expect(identical(idRef.meta, navItem.meta), isTrue,
          reason: 'id-tree and nav positions disagree');
    });
  });
}
