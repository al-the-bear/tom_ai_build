/// A class-graph fixture that exercises **every** annotation the display layer
/// knows how to show, plus the labels the shared descriptors produce for it.
///
/// This is the divergence guard between the two Flutter surfaces that render
/// the TomSpecs class graph — `tom_specs_editor` (authoring, dark Forge shell)
/// and `tom_specs_reviewer` (object-model review, light canvas). They share the
/// *readers* and the *display semantics* from this package but each owns its own
/// *rendering*, so nothing stops one tree from quietly ceasing to show what the
/// other shows. Both apps run a widget test over [kAnnotationShowcaseJson] and
/// assert [expectedShowcaseChipLabels] is fully present, so:
///
///   1. a new annotation must be added to [kRenderedAnnotations] (the reviewer's
///      snapshot-coverage test fails otherwise);
///   2. it must then appear in this fixture (`spec_display_fixture_test.dart`
///      fails otherwise);
///   3. and both apps must render it (both apps' tree tests fail otherwise).
///
/// A rendering added to one tree and not the other therefore fails a test rather
/// than accumulating silently.
///
/// Deliberately a separate library from `tom_som_dart_runtime.dart`: it is a
/// testing surface, and importing the runtime must not drag a fixture along.
library;

import 'src/spec_annotation_display.dart';
import 'src/spec_model.dart';

/// The `@Headline` the fixture puts on its overview section.
const String kShowcaseHeadline = 'Showcase Overview';

/// The `@Comment` note the fixture puts on its overview section.
const String kShowcaseComment = 'locus: shared';

/// The `@SectionIdPattern` the fixture puts on its item list.
const String kShowcaseSectionIdPattern = 'SHW-ITM.N';

/// The `@SerializationOrder` ordinal the fixture puts on its overview section —
/// rendered as `#7` behind the serialization-order toggle.
const int kShowcaseSerializationOrder = 7;

/// The `@Reference` description the fixture puts on its provenance section.
const String kShowcaseReference = 'ShowcaseDoc/items';

/// The `@StandardReferences` connotation the fixture carries.
const String kShowcaseConnotation = 'What the showcase section means.';

/// A standard named in the fixture's `@StandardReferences`.
const String kShowcaseStandard = 'ISO 42001 §6.1';

/// A class graph exercising every annotation the display layer renders.
///
/// One root, `ShowcaseDoc`, marked `@CodeSpecsProjection` so the projection
/// marker has a home. Its fields spread the three `@CodeSpecKind` states, both
/// `@FollowUpKind` states, `@Unused`, `@Comment`, `@Headline`, `@Reference`,
/// `@StandardReferences`, `@SectionIdPattern` and `@SerializationOrder` across
/// separate rows so no row's rendering can mask another's.
Map<String, dynamic> kAnnotationShowcaseJson() => {
      'modelVersion': 1,
      'roots': [
        {
          'type': 'ShowcaseDoc',
          'title': 'Showcase Document',
          'sectionId': 'SHW',
        },
      ],
      'classes': {
        'ShowcaseDoc': {
          'name': 'ShowcaseDoc',
          'sectionId': 'SHW',
          'annotations': [
            {'name': 'Document'},
            {
              'name': 'SectionId',
              'arguments': {'id': 'SHW'},
            },
            {'name': 'CodeSpecsProjection'},
          ],
          'fields': [
            {
              'name': 'overview',
              'kind': 'content',
              'sectionId': 'SHW-OVR',
              'contentType': 'markdown',
              'help': 'Intro paragraph.',
              'headline': kShowcaseHeadline,
              'serializationOrder': kShowcaseSerializationOrder,
              'annotations': [
                {
                  'name': 'SectionId',
                  'arguments': {'id': 'SHW-OVR'},
                },
                {
                  'name': 'Headline',
                  'arguments': {'text': kShowcaseHeadline},
                },
                {
                  'name': 'ContentType',
                  'arguments': {'type': 'markdown'},
                },
                {
                  'name': 'ContentHelp',
                  'arguments': {'text': 'Intro paragraph.'},
                },
                {
                  'name': 'Comment',
                  'arguments': {'text': kShowcaseComment},
                },
                {
                  'name': 'SerializationOrder',
                  'arguments': {'order': kShowcaseSerializationOrder},
                },
              ],
            },
            {
              // Unmapped: no `@CodeSpecKind` at all, so the row states `cs?`.
              'name': 'unmapped',
              'kind': 'scalar',
              'type': 'String',
              'sectionId': 'SHW-UNM',
            },
            {
              // Explicitly mapped to no CodeSpecs part — a decision, not a gap.
              'name': 'notCode',
              'kind': 'scalar',
              'type': 'String',
              'sectionId': 'SHW-NOC',
              'annotations': [
                {
                  'name': 'CodeSpecKind',
                  'arguments': {'kinds': <String>[]},
                },
              ],
            },
            {
              'name': 'unusedContainer',
              'kind': 'scalar',
              'type': 'String',
              'sectionId': 'SHW-UNU',
              'annotations': [
                {'name': 'Unused'},
              ],
            },
            {
              'name': 'provenance',
              'kind': 'scalar',
              'type': 'String',
              'sectionId': 'SHW-PRV',
              'standardReferences': {
                'connotation': kShowcaseConnotation,
                'standards': [kShowcaseStandard],
              },
              'annotations': [
                {
                  'name': 'Reference',
                  'arguments': {'description': kShowcaseReference},
                },
                {
                  'name': 'StandardReferences',
                  'arguments': {
                    'connotation': kShowcaseConnotation,
                    'standards': [kShowcaseStandard],
                  },
                },
              ],
            },
            {
              'name': 'trainingMaterial',
              'kind': 'scalar',
              'type': 'String',
              'sectionId': 'SHW-TRN',
              'annotations': [
                {
                  'name': 'FollowUpKind',
                  'arguments': {
                    'processes': ['FollowUpProcess.trn'],
                  },
                },
              ],
            },
            {
              'name': 'followUpUndecided',
              'kind': 'scalar',
              'type': 'String',
              'sectionId': 'SHW-FUN',
              'annotations': [
                {
                  'name': 'FollowUpKind',
                  'arguments': {'processes': <String>[]},
                },
              ],
            },
            {
              'name': 'items',
              'kind': 'list',
              'elementType': 'ShowcaseItem',
              'elementIsComplex': true,
              'sectionIdPattern': kShowcaseSectionIdPattern,
              'min': 1,
              'annotations': [
                {
                  'name': 'SectionIdPattern',
                  'arguments': {'pattern': kShowcaseSectionIdPattern},
                },
                {
                  'name': 'Min',
                  'arguments': {'count': 1},
                },
              ],
            },
            {
              'name': 'handoff',
              'kind': 'complex',
              'type': 'HandoffSection',
              'sectionId': 'SHW-HND',
            },
            {
              'name': 'choice',
              'kind': 'complex',
              'type': 'ChoiceSection',
              'sectionId': 'SHW-CHO',
            },
          ],
        },
        'ShowcaseItem': {
          'name': 'ShowcaseItem',
          'fields': [
            {'name': 'label', 'kind': 'scalar', 'type': 'String'},
          ],
        },
        // A section whose subject matter is detailed and mapped elsewhere, and
        // which declares which CodeSpecs parts it becomes.
        'HandoffSection': {
          'name': 'HandoffSection',
          'sectionId': 'SHW-HND',
          'mapsTo': 'OtherDoc',
          'detailedIn': 'OtherDoc',
          'annotations': [
            {
              'name': 'SectionId',
              'arguments': {'id': 'SHW-HND'},
            },
            {
              'name': 'MapsTo',
              'arguments': {'target': 'OtherDoc'},
            },
            {
              'name': 'DetailedIn',
              'arguments': {'target': 'OtherDoc'},
            },
            {
              'name': 'CodeSpecKind',
              'arguments': {
                'kinds': ['CodeSpecPart.form'],
                'note': 'Becomes the entry form.',
              },
            },
          ],
          'fields': [
            {'name': 'note', 'kind': 'scalar', 'type': 'String'},
          ],
        },
        // A closed choice: a `@Form` declaring the discriminator, then two of
        // the three enum values cased — leaving one uncovered so the coverage
        // arithmetic has something to report.
        'ChoiceSection': {
          'name': 'ChoiceSection',
          'sectionId': 'SHW-CHO',
          'annotations': [
            {
              'name': 'OneOf',
              'arguments': {
                'discriminator': 'kind',
                'note': 'Exactly one alternative applies.',
              },
            },
          ],
          'fields': [
            {
              'name': 'settings',
              'kind': 'form',
              'sectionId': 'SHW-CHO-SET',
              'annotations': [
                {'name': 'Form'},
              ],
              'formFields': [
                {
                  'name': 'kind',
                  'label': 'Kind',
                  'type': 'enum',
                  'enumValues': ['alpha', 'beta', 'gamma'],
                },
              ],
            },
            {
              'name': 'alphaDetail',
              'kind': 'scalar',
              'type': 'String',
              'annotations': [
                {
                  'name': 'Case',
                  'arguments': {'value': 'ChoiceKind.alpha'},
                },
              ],
            },
            {
              'name': 'betaDetail',
              'kind': 'scalar',
              'type': 'String',
              'annotations': [
                {
                  'name': 'Case',
                  'arguments': {'value': 'ChoiceKind.beta'},
                },
              ],
            },
          ],
        },
      },
    };

/// The fixture, parsed.
SpecModel showcaseModel() => SpecModel.fromJson(kAnnotationShowcaseJson());

/// Every chip label the shared descriptors produce anywhere in [model].
///
/// Computed from the descriptor functions rather than written out, so a chip
/// the display layer starts producing joins this set automatically — and then
/// fails in whichever app has not rendered it.
Set<String> expectedShowcaseChipLabels(SpecModel model) {
  final labels = <String>{};
  void addAll(List<SpecChip> chips) {
    labels.addAll(chips.map((c) => c.label));
  }

  for (final cls in model.classes.values) {
    if (cls.isCodeSpecsProjection) labels.add(projectionChip.label);
    if (cls.isUnused) labels.add(unusedChip.label);
    if (cls.hasReferences) labels.add(referencesChip.label);
    final group = cls.oneOf;
    if (group != null) addAll(oneOfChips(group));
    addAll(kindChips(cls.codeSpecKind, cls.followUpKind));
    for (final field in cls.fields) {
      if (field.isUnused) labels.add(unusedChip.label);
      if (field.hasReferences) labels.add(referencesChip.label);
      addAll(fieldChips(field));
    }
  }
  return labels;
}
