import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:test/test.dart';

import 'fixture.dart';

void main() {
  group('SpecModel.fromJson', () {
    test('decodes roots, classes, and the version stamp', () {
      final model = fixtureModel();
      expect(model.modelVersion, 7);
      expect(model.modelVersionLabel, '0.7.0+7.abc1234');
      expect(model.roots, hasLength(1));
      expect(model.roots.single.type, 'ProjectDefinition');
      expect(model.classNamed('ProjectDefinition'), isNotNull);
      expect(model.classNamed('Risk'), isNotNull);
      expect(model.classNamed('Missing'), isNull);
    });

    test('an unstamped export reports modelVersion 0 and null label', () {
      final model = SpecModel.fromJson(
          <String, dynamic>{'roots': <dynamic>[], 'classes': <String, dynamic>{}});
      expect(model.modelVersion, 0);
      expect(model.modelVersionLabel, isNull);
    });

    test('decodes field kinds and shape', () {
      final cls = fixtureModel().classNamed('ProjectDefinition')!;
      final risks = cls.fieldNamed('risks')!;
      expect(risks.kind, SpecFieldKind.list);
      expect(risks.elementType, 'Risk');
      expect(risks.elementIsComplex, isTrue);
      expect(risks.min, 2);
      expect(risks.isExpandable, isTrue);

      final owner = cls.fieldNamed('owner')!;
      expect(owner.kind, SpecFieldKind.form);
      expect(owner.formFields.map((f) => f.name), <String>['name', 'role']);

      final vision = cls.fieldNamed('vision')!;
      expect(vision.kind, SpecFieldKind.content);
      expect(vision.isExpandable, isFalse);
    });

    test('an enum field carries its Dart enum type name and values', () {
      final prob =
          fixtureModel().classNamed('Risk')!.fieldNamed('probability')!;
      expect(prob.kind, SpecFieldKind.enumValue);
      expect(prob.enumType, 'Probability');
      expect(prob.enumValues, <String>['low', 'medium', 'high']);
    });
  });

  group('model version string (SOM §4.2)', () {
    test('somModelVersionString takes major.minor from the label', () {
      expect(somModelVersionString(1, '1.0.0+7.1f49ac3'), '1.0');
      // A genuine authoring minor in the stamp is preserved, not flattened.
      expect(somModelVersionString(2, '2.3.1+5.deadbee'), '2.3');
      // Build metadata after `+` is ignored.
      expect(somModelVersionString(3, '3.4.0'), '3.4');
    });

    test('somModelVersionString falls back to <major>.0 when unstamped', () {
      expect(somModelVersionString(1, null), '1.0');
      expect(somModelVersionString(4, ''), '4.0');
      // A malformed label (no numeric minor) also falls back to the counter.
      expect(somModelVersionString(2, 'weird'), '2.0');
    });

    test('SpecModel.modelVersionString reports the stamped major.minor', () {
      // The fixture is stamped 0.7.0+7.abc1234.
      expect(fixtureModel().modelVersionString, '0.7');
    });

    test('SpecModel.modelVersionString falls back for an unstamped model', () {
      final model = SpecModel.fromJson(
          <String, dynamic>{'roots': <dynamic>[], 'classes': <String, dynamic>{}});
      expect(model.modelVersionString, '0.0');
    });
  });

  group('generation stamp', () {
    /// The fixture plus the five generation-stamp keys the exporter writes.
    Map<String, dynamic> stampedJson({
      String? generatedAt = '2026-07-20T08:00:00.000000Z',
      int? classCount = 3,
      int? rootCount = 1,
    }) =>
        {
          ...fixtureJson(),
          if (generatedAt != null) 'generatedAt': generatedAt,
          'metaSchemaVersion': 1,
          if (classCount != null) 'classCount': classCount,
          if (rootCount != null) 'rootCount': rootCount,
          'containerRoot': 'DocSpecsProject',
        };

    test('decodes generatedAt, metaSchemaVersion, counts and containerRoot',
        () {
      final model = SpecModel.fromJson(stampedJson());
      expect(model.generatedAt, DateTime.utc(2026, 7, 20, 8));
      expect(model.generatedAt!.isUtc, isTrue);
      expect(model.metaSchemaVersion, 1);
      expect(model.classCount, 3);
      expect(model.rootCount, 1);
      expect(model.containerRoot, 'DocSpecsProject');
    });

    test('an older snapshot without the stamp keys still parses, with nulls',
        () {
      // The shared fixture predates the stamp keys — exactly the compatibility
      // case, so it doubles as the regression guard.
      final model = fixtureModel();
      expect(model.generatedAt, isNull);
      expect(model.metaSchemaVersion, isNull);
      expect(model.classCount, isNull);
      expect(model.rootCount, isNull);
      expect(model.containerRoot, isNull);
      // Absent must not be read as zero — a declared 0 would look like a
      // mismatch against the 3 classes the payload actually carries.
      expect(model.checkStamp().countsDisagree, isFalse);
    });

    test('an unparseable generatedAt degrades to null rather than throwing',
        () {
      final model = SpecModel.fromJson(stampedJson(generatedAt: 'not-a-date'));
      expect(model.generatedAt, isNull);
      // The rest of the stamp still decodes.
      expect(model.classCount, 3);
    });
  });

  group('parseStampTimestamp', () {
    test('reads Z and explicit offsets to the same instant', () {
      final z = parseStampTimestamp('2026-07-20T08:00:00.000000Z')!;
      expect(z, DateTime.utc(2026, 7, 20, 8));
      expect(z.isUtc, isTrue);
      expect(parseStampTimestamp('2026-07-20T10:00:00+02:00'), z);
      expect(parseStampTimestamp('2026-07-20T03:00:00-05:00'), z);
    });

    test('reads a zone-less timestamp as UTC, not as local time', () {
      // `DateTime.parse` would read this as the reader's local time, making the
      // staleness verdict depend on where the reader sits. The other eight SOM
      // runtimes cannot mirror that (several carry no timezone database), so
      // the grammar fixes the fallback instead.
      expect(parseStampTimestamp('2026-07-20T08:00:00'),
          DateTime.utc(2026, 7, 20, 8));
      expect(parseStampTimestamp('2026-07-20T08:00:00.123456')!.microsecond,
          456);
    });

    test('an offset written without a colon is accepted', () {
      expect(parseStampTimestamp('2026-07-20T10:00:00+0200'),
          DateTime.utc(2026, 7, 20, 8));
    });

    test('unparseable, empty and absent input all degrade to null', () {
      expect(parseStampTimestamp('not-a-date'), isNull);
      expect(parseStampTimestamp(''), isNull);
      expect(parseStampTimestamp(null), isNull);
      // A date with no time is outside the grammar.
      expect(parseStampTimestamp('2026-07-20'), isNull);
    });

    test('an out-of-range field is unreadable rather than rolled over', () {
      // `DateTime.utc(2026, 13, …)` would silently become January 2027.
      expect(parseStampTimestamp('2026-13-20T08:00:00Z'), isNull);
      expect(parseStampTimestamp('2026-07-32T08:00:00Z'), isNull);
      expect(parseStampTimestamp('2026-07-20T24:00:00Z'), isNull);
    });
  });

  group('SpecModel.checkStamp', () {
    Map<String, dynamic> json({
      String? generatedAt = '2026-07-20T08:00:00.000000Z',
      int? classCount = 3,
      int? rootCount = 1,
    }) =>
        {
          ...fixtureJson(),
          if (generatedAt != null) 'generatedAt': generatedAt,
          if (classCount != null) 'classCount': classCount,
          if (rootCount != null) 'rootCount': rootCount,
        };

    // One day after the fixture's generatedAt.
    final fresh = DateTime.utc(2026, 7, 21, 8);
    // Sixty days after it.
    final longAfter = DateTime.utc(2026, 9, 18, 8);

    test('a recent, self-consistent snapshot raises nothing', () {
      final check = SpecModel.fromJson(json()).checkStamp(now: fresh);
      expect(check.age, const Duration(days: 1));
      expect(check.isAged, isFalse);
      expect(check.countsDisagree, isFalse);
      expect(check.isStale, isFalse);
      expect(check.warnings, isEmpty);
    });

    test('a snapshot older than the threshold is reported as aged', () {
      final check = SpecModel.fromJson(json()).checkStamp(now: longAfter);
      expect(check.isAged, isTrue);
      expect(check.isStale, isTrue);
      expect(check.warnings.single, contains('60 days old'));
    });

    test('the age threshold is caller-controlled', () {
      final model = SpecModel.fromJson(json());
      expect(
          model
              .checkStamp(now: longAfter, maxAge: const Duration(days: 90))
              .isAged,
          isFalse);
      expect(
          model
              .checkStamp(now: fresh, maxAge: const Duration(hours: 1))
              .isAged,
          isTrue);
    });

    test('a declared class count that disagrees with the payload is flagged',
        () {
      // The exporter derives classCount from the payload, so a disagreement
      // can only mean the file was edited after export.
      final check =
          SpecModel.fromJson(json(classCount: 99)).checkStamp(now: fresh);
      expect(check.classCountDisagrees, isTrue);
      expect(check.rootCountDisagrees, isFalse);
      expect(check.isStale, isTrue);
      expect(check.warnings.single, allOf(contains('99'), contains('3')));
    });

    test('a declared root count that disagrees with the payload is flagged',
        () {
      final check =
          SpecModel.fromJson(json(rootCount: 7)).checkStamp(now: fresh);
      expect(check.rootCountDisagrees, isTrue);
      expect(check.classCountDisagrees, isFalse);
      expect(check.warnings.single, allOf(contains('7'), contains('1')));
    });

    test('age and count findings are independent and both reported', () {
      final check = SpecModel.fromJson(json(classCount: 99, rootCount: 7))
          .checkStamp(now: longAfter);
      expect(check.isAged, isTrue);
      expect(check.classCountDisagrees, isTrue);
      expect(check.rootCountDisagrees, isTrue);
      expect(check.warnings, hasLength(3));
    });

    test('a snapshot without generatedAt is never aged', () {
      final check =
          SpecModel.fromJson(json(generatedAt: null)).checkStamp(now: longAfter);
      expect(check.age, isNull);
      expect(check.isAged, isFalse);
      expect(check.isStale, isFalse);
    });
  });

  group('SpecAnnotation', () {
    test('class-level annotations are captured losslessly', () {
      final cls = fixtureModel().classNamed('ProjectDefinition')!;
      final doc = cls.annotation('Document');
      expect(doc, isNotNull);
      expect(doc!.argument('title'), 'Project Definition');
      expect(cls.annotation('SectionId')!.argument('id'), 'PD00');
      expect(cls.annotation('Nope'), isNull);
    });

    test('field-level annotations are captured', () {
      final risks =
          fixtureModel().classNamed('ProjectDefinition')!.fieldNamed('risks')!;
      expect(risks.annotation('Min')!.argument('value'), 2);
    });
  });

  group('CodeSpecKind link (codespecs_mapping.md §9.1)', () {
    /// A class optionally carrying `@CodeSpecKind`, with a field that may carry
    /// its own — the two places the annotation can appear.
    SpecModel modelWith({
      Map<String, dynamic>? classArgs,
      Map<String, dynamic>? fieldArgs,
    }) =>
        SpecModel.fromJson(<String, dynamic>{
          'roots': <dynamic>[],
          'classes': <String, dynamic>{
            'Section': {
              'name': 'Section',
              'annotations': [
                {'name': 'SectionId', 'arguments': {'id': 'SEC'}},
                if (classArgs != null)
                  {'name': 'CodeSpecKind', 'arguments': classArgs},
              ],
              'fields': [
                {
                  'name': 'body',
                  'kind': 'content',
                  'annotations': [
                    if (fieldArgs != null)
                      {'name': 'CodeSpecKind', 'arguments': fieldArgs},
                  ],
                },
              ],
            },
          },
        });

    SpecClass classOf(SpecModel m) => m.classNamed('Section')!;

    test('reads the kinds with the CodeSpecPart prefix stripped', () {
      final link = classOf(modelWith(classArgs: {
        'kinds': ['CodeSpecPart.validation'],
      })).codeSpecKind;
      expect(link, isNotNull);
      expect(link!.kinds, <String>['validation']);
      expect(link.note, isNull);
    });

    test('reads every kind, not just the first — the link is list-valued', () {
      final link = classOf(modelWith(classArgs: {
        'kinds': [
          'CodeSpecPart.authorization',
          'CodeSpecPart.authentication',
          'CodeSpecPart.identity',
        ],
      })).codeSpecKind;
      expect(
          link!.kinds, <String>['authorization', 'authentication', 'identity']);
    });

    test('carries the optional note verbatim', () {
      final link = classOf(modelWith(classArgs: {
        'kinds': ['CodeSpecPart.serverConfiguration'],
        'note': 'CE-CF — feature flags are config toggles',
      })).codeSpecKind;
      expect(link!.note, 'CE-CF — feature flags are config toggles');
    });

    test('an absent annotation and an empty kind list are different states',
        () {
      // Load-bearing for review: "not yet mapped" is an open question, while
      // "mapped to nothing" is a decision someone already took.
      expect(classOf(modelWith()).codeSpecKind, isNull);

      final empty = classOf(modelWith(classArgs: {'kinds': <String>[]}));
      expect(empty.codeSpecKind, isNotNull);
      expect(empty.codeSpecKind!.kinds, isEmpty);
    });

    test('an annotation with no kinds argument reads as empty, not null', () {
      // Present-but-argumentless is still a present annotation.
      final link =
          classOf(modelWith(classArgs: <String, dynamic>{})).codeSpecKind;
      expect(link, isNotNull);
      expect(link!.kinds, isEmpty);
    });

    test('a bare kind name without the prefix passes through unchanged', () {
      final link = classOf(modelWith(classArgs: {
        'kinds': ['validation'],
      })).codeSpecKind;
      expect(link!.kinds, <String>['validation']);
    });

    test('fields carry the link independently of their class', () {
      final model = modelWith(fieldArgs: {
        'kinds': ['CodeSpecPart.serverConfiguration'],
      });
      final cls = classOf(model);
      expect(cls.codeSpecKind, isNull);
      expect(cls.fieldNamed('body')!.codeSpecKind!.kinds,
          <String>['serverConfiguration']);
    });

    test('a field without the annotation reports null', () {
      expect(classOf(modelWith()).fieldNamed('body')!.codeSpecKind, isNull);
    });
  });

  group('FollowUpKind link (codespecs_mapping.md §8.3)', () {
    /// `@FollowUpKind` marks a subtree that becomes a downstream *process*
    /// rather than CodeSpecs code. It is the same shape as `@CodeSpecKind` —
    /// enum-code list plus optional note — so it is read through the same type.
    SpecModel modelWith({Map<String, dynamic>? args}) =>
        SpecModel.fromJson(<String, dynamic>{
          'roots': <dynamic>[],
          'classes': <String, dynamic>{
            'Section': {
              'name': 'Section',
              'annotations': [
                if (args != null) {'name': 'FollowUpKind', 'arguments': args},
              ],
              'fields': <dynamic>[],
            },
          },
        });

    SpecClass classOf(SpecModel m) => m.classNamed('Section')!;

    test('reads the processes with the FollowUpProcess prefix stripped', () {
      final link = classOf(modelWith(args: {
        'processes': ['FollowUpProcess.doc'],
      })).followUpKind;
      expect(link, isNotNull);
      expect(link!.kinds, <String>['doc']);
    });

    test('reads every process, not just the first — the link is list-valued',
        () {
      // DataModelFollowUp in the real model carries four.
      final link = classOf(modelWith(args: {
        'processes': [
          'FollowUpProcess.doc',
          'FollowUpProcess.cap',
          'FollowUpProcess.cmp',
          'FollowUpProcess.mig',
        ],
      })).followUpKind;
      expect(link!.kinds, <String>['doc', 'cap', 'cmp', 'mig']);
    });

    test('carries the optional note verbatim', () {
      final link = classOf(modelWith(args: {
        'processes': ['FollowUpProcess.org'],
        'note': 'Feeds the governance rollout',
      })).followUpKind;
      expect(link!.note, 'Feeds the governance rollout');
    });

    test('an absent annotation reports null', () {
      expect(classOf(modelWith()).followUpKind, isNull);
    });

    test('the two links are read independently of one another', () {
      // A subtree is CodeSpecs *or* follow-up; reading one must never satisfy
      // the other, or the codespecs_mapping.md §8.3 split becomes invisible.
      final model = SpecModel.fromJson(<String, dynamic>{
        'roots': <dynamic>[],
        'classes': <String, dynamic>{
          'Section': {
            'name': 'Section',
            'annotations': [
              {
                'name': 'FollowUpKind',
                'arguments': {
                  'processes': ['FollowUpProcess.trn'],
                },
              },
            ],
            'fields': <dynamic>[],
          },
        },
      });
      expect(model.classNamed('Section')!.followUpKind!.kinds, <String>['trn']);
      expect(model.classNamed('Section')!.codeSpecKind, isNull);
    });
  });

  group('CodeSpecsProjection marker (codespecs_mapping.md §8.4)', () {
    SpecModel modelWith({required bool projection}) =>
        SpecModel.fromJson(<String, dynamic>{
          'roots': <dynamic>[],
          'classes': <String, dynamic>{
            'Doc': {
              'name': 'Doc',
              'annotations': [
                {'name': 'Document', 'arguments': <String, dynamic>{}},
                if (projection)
                  {'name': 'CodeSpecsProjection', 'arguments': <String, dynamic>{}},
              ],
              'fields': <dynamic>[],
            },
          },
        });

    test('an annotated document reports itself as a projection', () {
      expect(
          modelWith(projection: true).classNamed('Doc')!.isCodeSpecsProjection,
          isTrue);
    });

    test('an ordinary authoring document does not', () {
      expect(
          modelWith(projection: false).classNamed('Doc')!.isCodeSpecsProjection,
          isFalse);
    });

    test('the marker is argumentless — presence alone carries the meaning', () {
      // Serialized with no `arguments` key at all, as the exporter emits it.
      final model = SpecModel.fromJson(<String, dynamic>{
        'roots': <dynamic>[],
        'classes': <String, dynamic>{
          'Doc': {
            'name': 'Doc',
            'annotations': [
              {'name': 'CodeSpecsProjection'},
            ],
            'fields': <dynamic>[],
          },
        },
      });
      expect(model.classNamed('Doc')!.isCodeSpecsProjection, isTrue);
    });
  });

  group('OneOf / Case closed choice (codespecs_mapping.md §8.2)', () {
    /// A container class shaped like the real `ScreenElementEntry`: a `@Form`
    /// `content` section holding the discriminator form-field, some common
    /// subsections, and the `@Case`-annotated alternatives.
    SpecModel modelWith({
      Map<String, dynamic>? oneOfArgs,
      List<String> discriminatorValues = const ['action', 'input', 'display'],
      Map<String, List<String>> cases = const {},
      bool withDiscriminatorFormField = true,
    }) =>
        SpecModel.fromJson(<String, dynamic>{
          'roots': <dynamic>[],
          'classes': <String, dynamic>{
            'Element': {
              'name': 'Element',
              'annotations': [
                if (oneOfArgs != null)
                  {'name': 'OneOf', 'arguments': oneOfArgs},
              ],
              'fields': [
                {
                  'name': 'content',
                  'kind': 'form',
                  'formFields': [
                    {'name': 'elementId', 'type': 'String'},
                    if (withDiscriminatorFormField)
                      {
                        'name': 'elementType',
                        'type': 'ElementKind',
                        'enumValues': discriminatorValues,
                      },
                  ],
                },
                {'name': 'layout', 'kind': 'form'},
                for (final entry in cases.entries)
                  {
                    'name': entry.key,
                    'kind': 'complex',
                    'annotations': [
                      for (final v in entry.value)
                        {
                          'name': 'Case',
                          'arguments': {'value': v},
                        },
                    ],
                  },
              ],
            },
          },
        });

    SpecClass classOf(SpecModel m) => m.classNamed('Element')!;

    test('a class without @OneOf reports no group', () {
      expect(classOf(modelWith()).oneOf, isNull);
    });

    test('reads the discriminator name and the optional note', () {
      final group = classOf(modelWith(oneOfArgs: {
        'discriminator': 'elementType',
        'note': 'CE-EL closed choice',
      })).oneOf;
      expect(group, isNotNull);
      expect(group!.discriminator, 'elementType');
      expect(group.note, 'CE-EL closed choice');
    });

    test('resolves the discriminator through the content form fields', () {
      // The discriminator is a `@Form` form-field, not a SpecField — reading it
      // off `fields` alone would never find it.
      final group = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
      )).oneOf!;
      expect(group.discriminatorField, isNotNull);
      expect(group.discriminatorField!.type, 'ElementKind');
      expect(group.discriminatorValues, <String>['action', 'input', 'display']);
    });

    test('an unresolvable discriminator degrades rather than throwing', () {
      final group = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        withDiscriminatorFormField: false,
      )).oneOf!;
      expect(group.discriminatorField, isNull);
      expect(group.discriminatorValues, isEmpty);
      expect(group.uncoveredValues, isEmpty);
    });

    test('collects every @Case on a field — the annotation is repeatable', () {
      // The real model has 30 `@Case` annotations spread over 7 fields; a
      // reader that returns only the first would misreport 6 of them.
      final cls = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {
          'elementAction': ['ElementKind.action'],
          'fieldSpec': ['ElementKind.input', 'ElementKind.display'],
        },
      ));
      expect(cls.fieldNamed('fieldSpec')!.caseValues,
          <String>['input', 'display']);
      expect(cls.fieldNamed('elementAction')!.caseValues, <String>['action']);
    });

    test('a field carrying no @Case is common to every case', () {
      final cls = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {'elementAction': ['ElementKind.action']},
      ));
      expect(cls.fieldNamed('layout')!.caseValues, isEmpty);
      expect(cls.fieldNamed('layout')!.isCase, isFalse);
      expect(cls.fieldNamed('elementAction')!.isCase, isTrue);
    });

    test('case fields are listed in declaration order, common ones excluded',
        () {
      final group = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {
          'elementAction': ['ElementKind.action'],
          'fieldSpec': ['ElementKind.input'],
        },
      )).oneOf!;
      expect(group.caseFields.map((f) => f.name),
          <String>['elementAction', 'fieldSpec']);
    });

    test('covered and uncovered values partition the discriminator enum', () {
      // The review question codespecs_mapping.md §8.2 poses — "is this set
      // complete?" — is only answerable if the uncovered values are named.
      final group = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {
          'elementAction': ['ElementKind.action'],
          'fieldSpec': ['ElementKind.input'],
        },
      )).oneOf!;
      expect(group.coveredValues, <String>['action', 'input']);
      expect(group.uncoveredValues, <String>['display']);
      expect(group.isComplete, isFalse);
    });

    test('a fully covered group reports complete with no uncovered values', () {
      final group = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {
          'a': ['ElementKind.action'],
          'b': ['ElementKind.input', 'ElementKind.display'],
        },
      )).oneOf!;
      expect(group.uncoveredValues, isEmpty);
      expect(group.isComplete, isTrue);
    });

    test('covered values follow enum order, not case-field order', () {
      // So the coverage line reads against the enum a reviewer is checking.
      final group = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {
          'a': ['ElementKind.display'],
          'b': ['ElementKind.action'],
        },
      )).oneOf!;
      expect(group.coveredValues, <String>['action', 'display']);
    });

    test('a case value outside the enum contributes no coverage', () {
      // Not an error state the model exhibits, but defining coverage as
      // "enum values that are cased" keeps the count honest either way.
      final group = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {
          'a': ['ElementKind.action', 'ElementKind.bogus'],
        },
      )).oneOf!;
      expect(group.coveredValues, <String>['action']);
      expect(group.uncoveredValues, <String>['input', 'display']);
    });

    test('a bare case value without the enum prefix passes through', () {
      final cls = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {'a': ['action']},
      ));
      expect(cls.fieldNamed('a')!.caseValues, <String>['action']);
    });

    test('annotationsNamed returns every occurrence, annotation only the first',
        () {
      final field = classOf(modelWith(
        oneOfArgs: {'discriminator': 'elementType'},
        cases: {
          'a': ['ElementKind.action', 'ElementKind.input'],
        },
      )).fieldNamed('a')!;
      expect(field.annotationsNamed('Case').length, 2);
      expect(field.annotation('Case')!.argument('value'), 'ElementKind.action');
      expect(field.annotationsNamed('Nope'), isEmpty);
    });
  });

  group('Marker, comment and reference annotations', () {
    /// One class carrying every annotation under test at both levels, so a
    /// reader that confuses the class node with the field node fails here.
    SpecModel modelWith({
      List<Map<String, dynamic>> classAnnotations = const [],
      List<Map<String, dynamic>> fieldAnnotations = const [],
      Object? classStandardReferences,
      Object? fieldStandardReferences,
    }) =>
        SpecModel.fromJson(<String, dynamic>{
          'roots': <dynamic>[],
          'classes': <String, dynamic>{
            'Section': {
              'name': 'Section',
              'annotations': classAnnotations,
              if (classStandardReferences != null)
                'standardReferences': classStandardReferences,
              'fields': [
                {
                  'name': 'content',
                  'kind': 'content',
                  'annotations': fieldAnnotations,
                  if (fieldStandardReferences != null)
                    'standardReferences': fieldStandardReferences,
                },
              ],
            },
          },
        });

    SpecClass classOf(SpecModel m) => m.classNamed('Section')!;
    SpecField fieldOf(SpecModel m) => classOf(m).fieldNamed('content')!;

    test('isUnused is false when the marker is absent', () {
      expect(fieldOf(modelWith()).isUnused, isFalse);
      expect(classOf(modelWith()).isUnused, isFalse);
    });

    test('isUnused reads the argumentless @Unused marker', () {
      // Presence is the whole statement — the annotation carries no arguments.
      final field = fieldOf(modelWith(fieldAnnotations: [
        {'name': 'Unused'},
      ]));
      expect(field.isUnused, isTrue);
    });

    test('comment reads @Comment(text)', () {
      final field = fieldOf(modelWith(fieldAnnotations: [
        {
          'name': 'Comment',
          'arguments': {'text': 'locus: shared — CE-ER'},
        },
      ]));
      expect(field.comment, 'locus: shared — CE-ER');
    });

    test('comment is read on classes too', () {
      final cls = classOf(modelWith(classAnnotations: [
        {
          'name': 'Comment',
          'arguments': {'text': 'Seeds → QAP'},
        },
      ]));
      expect(cls.comment, 'Seeds → QAP');
    });

    test('comment is null when absent', () {
      expect(fieldOf(modelWith()).comment, isNull);
      expect(classOf(modelWith()).comment, isNull);
    });

    test('reference reads @Reference(description)', () {
      final field = fieldOf(modelWith(fieldAnnotations: [
        {
          'name': 'Reference',
          'arguments': {'description': 'Related Data Model Entity'},
        },
      ]));
      expect(field.reference, 'Related Data Model Entity');
    });

    test('reference is null when absent', () {
      expect(fieldOf(modelWith()).reference, isNull);
    });

    test('standardReferences reads standards and connotation on a class', () {
      final cls = classOf(modelWith(classStandardReferences: {
        'standards': ['ISO/IEC 25010:2023 §4.2', 'IEEE 829-2008'],
        'connotation': 'What the section owns.',
      }));
      expect(cls.standardReferences, isNotNull);
      expect(cls.standardReferences!.standards,
          ['ISO/IEC 25010:2023 §4.2', 'IEEE 829-2008']);
      expect(cls.standardReferences!.connotation, 'What the section owns.');
    });

    test('standardReferences reads on a field', () {
      final field = fieldOf(modelWith(fieldStandardReferences: {
        'standards': ['ISO 21502:2020'],
        'connotation': 'Lists the individual criteria.',
      }));
      expect(field.standardReferences!.standards, ['ISO 21502:2020']);
      expect(field.standardReferences!.connotation,
          'Lists the individual criteria.');
    });

    test('standardReferences is null when the key is absent', () {
      expect(classOf(modelWith()).standardReferences, isNull);
      expect(fieldOf(modelWith()).standardReferences, isNull);
    });

    test('standardReferences tolerates a missing connotation', () {
      // The exporter always writes both, but a hand-built or older model may
      // carry only the list; dropping the whole block over it would hide the
      // standards.
      final cls = classOf(modelWith(classStandardReferences: {
        'standards': ['ISO 21502:2020'],
      }));
      expect(cls.standardReferences!.standards, ['ISO 21502:2020']);
      expect(cls.standardReferences!.connotation, isNull);
    });

    test('hasReferences is true when either reference kind is present', () {
      expect(fieldOf(modelWith()).hasReferences, isFalse);
      expect(
        fieldOf(modelWith(fieldAnnotations: [
          {
            'name': 'Reference',
            'arguments': {'description': 'objectName'},
          },
        ])).hasReferences,
        isTrue,
      );
      expect(
        fieldOf(modelWith(fieldStandardReferences: {
          'standards': ['ISO 21502:2020'],
          'connotation': 'x',
        })).hasReferences,
        isTrue,
      );
    });
  });

  group('SpecModel.rootByType (one-line export, SOM §21)', () {
    SpecModel twoRootModel() => SpecModel.fromJson(<String, dynamic>{
          'roots': <dynamic>[
            {'type': 'Alpha', 'title': 'Alpha Doc', 'sectionId': 'A00'},
            {'type': 'Beta', 'title': 'Beta Doc', 'sectionId': 'B00'},
          ],
          'classes': <String, dynamic>{},
        });

    test('returns the root whose type matches', () {
      final model = twoRootModel();
      expect(model.rootByType('Alpha').title, 'Alpha Doc');
      expect(model.rootByType('Beta').sectionId, 'B00');
    });

    test('throws ArgumentError naming the missing and available types', () {
      final model = twoRootModel();
      expect(
        () => model.rootByType('Gamma'),
        throwsA(isA<ArgumentError>()
            .having((e) => e.message, 'message', contains('Alpha'))
            .having((e) => e.message, 'message', contains('Beta'))),
      );
    });
  });
}
