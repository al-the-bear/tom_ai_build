import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

SpecAnnotation _ann(String name, [Map<String, Object?> args = const {}]) =>
    SpecAnnotation(name: name, arguments: args);

SpecField _field(
  String name, {
  List<SpecAnnotation> annotations = const [],
  String? headline,
  String? sectionIdPattern,
  int? serializationOrder,
  StandardReferences? standardReferences,
  List<FormFieldSpec> formFields = const [],
}) =>
    SpecField(
      name: name,
      kind: SpecFieldKind.section,
      headline: headline,
      sectionIdPattern: sectionIdPattern,
      serializationOrder: serializationOrder,
      annotations: annotations,
      standardReferences: standardReferences,
      formFields: formFields,
    );

void main() {
  group('codeSpecKindChips', () {
    test('AD1: an undeclared @CodeSpecKind is rendered as an open question '
        '[2026-07-28] (OK)', () {
      final chips = codeSpecKindChips(null);
      expect(chips, hasLength(1));
      expect(chips.single.label, 'cs?');
      expect(chips.single.role, SpecChipRole.codeSpecUnmapped);
    });

    test('AD2: an explicitly empty @CodeSpecKind is distinct from an '
        'undeclared one [2026-07-28] (OK)', () {
      final chips = codeSpecKindChips(const KindLink(kinds: []));
      expect(chips.single.label, 'cs:none');
      expect(chips.single.role, SpecChipRole.codeSpecNone);
    });

    test('AD3: every kind of a list-valued link gets its own chip, carrying '
        'the note [2026-07-28] (OK)', () {
      final chips = codeSpecKindChips(
          const KindLink(kinds: ['form', 'validation'], note: 'why'));
      expect(chips.map((c) => c.label), ['cs:form', 'cs:validation']);
      expect(chips.every((c) => c.role == SpecChipRole.codeSpecMapped), isTrue);
      expect(chips.first.tooltip, 'why');
    });

    test('AD4: suppressUnmapped removes only the undeclared marker '
        '[2026-07-28] (OK)', () {
      expect(codeSpecKindChips(null, suppressUnmapped: true), isEmpty);
      expect(
          codeSpecKindChips(const KindLink(kinds: ['form']),
              suppressUnmapped: true),
          hasLength(1));
    });
  });

  group('followUpKindChips', () {
    test('AD5: an undeclared @FollowUpKind produces no chip at all '
        '[2026-07-28] (OK)', () {
      expect(followUpKindChips(null), isEmpty);
    });

    test('AD6: an explicitly empty @FollowUpKind is still stated '
        '[2026-07-28] (OK)', () {
      final chips = followUpKindChips(const KindLink(kinds: []));
      expect(chips.single.label, 'fu:none');
      expect(chips.single.role, SpecChipRole.followUpNone);
    });

    test('AD7: each process gets a chip, defaulting its own explanation when '
        'the link has no note [2026-07-28] (OK)', () {
      final chips = followUpKindChips(const KindLink(kinds: ['doc', 'trn']));
      expect(chips.map((c) => c.label), ['fu:doc', 'fu:trn']);
      expect(chips.first.tooltip, contains('doc work'));
    });
  });

  group('noArtifactChips', () {
    test('AD24: an undeclared @NoArtifact produces no chip at all '
        '[2026-08-16] (OK)', () {
      expect(noArtifactChips(null), isEmpty);
    });

    test('AD25: the verdict names its reason and defaults an explanation '
        '[2026-08-16] (OK)', () {
      final chips = noArtifactChips(const NoArtifactLink(reason: 'overview'));
      expect(chips.single.label, 'na:overview');
      expect(chips.single.role, SpecChipRole.noArtifact);
      expect(chips.single.tooltip, contains('overview'));
    });

    test('AD26: the annotation note wins over the default explanation '
        '[2026-08-16] (OK)', () {
      final chips = noArtifactChips(
          const NoArtifactLink(reason: 'container', note: 'children route'));
      expect(chips.single.tooltip, 'children route');
    });
  });

  group('kindChips', () {
    test('AD8: a follow-up-tagged node is never also marked unmapped '
        '[2026-07-28] (OK)', () {
      final chips = kindChips(null, const KindLink(kinds: ['doc']), null);
      expect(chips.map((c) => c.label), ['fu:doc']);
      expect(chips.any((c) => c.role == SpecChipRole.codeSpecUnmapped), isFalse);
    });

    test('AD9: follow-up chips precede CodeSpecs chips [2026-07-28] (OK)', () {
      final chips = kindChips(
          const KindLink(kinds: ['form']), const KindLink(kinds: ['doc']), null);
      expect(chips.map((c) => c.label), ['fu:doc', 'cs:form']);
    });

    test('AD10: an untagged node keeps its open question [2026-07-28] (OK)',
        () {
      expect(kindChips(null, null, null).single.role,
          SpecChipRole.codeSpecUnmapped);
    });

    test('AD27: a @NoArtifact node is never also marked unmapped — the third '
        'verdict is a decision, not a gap [2026-08-16] (OK)', () {
      final chips =
          kindChips(null, null, const NoArtifactLink(reason: 'container'));
      expect(chips.map((c) => c.label), ['na:container']);
      expect(chips.any((c) => c.role == SpecChipRole.codeSpecUnmapped), isFalse);
    });
  });

  group('fieldChips', () {
    test('AD11: @Case is repeatable and yields one chip per value '
        '[2026-07-28] (OK)', () {
      final f = _field('alt', annotations: [
        _ann('Case', {'value': 'FieldKind.text'}),
        _ann('Case', {'value': 'FieldKind.number'}),
      ]);
      expect(caseChips(f).map((c) => c.label), ['case:text', 'case:number']);
    });

    test('AD12: case chips precede the destination chips [2026-07-28] (OK)',
        () {
      final f = _field('alt', annotations: [
        _ann('Case', {'value': 'text'}),
        _ann('CodeSpecKind', {
          'kinds': ['CodeSpecPart.form']
        }),
      ]);
      expect(fieldChips(f).map((c) => c.label), ['case:text', 'cs:form']);
    });
  });

  group('oneOfChips', () {
    OneOfGroup group({
      List<String> enumValues = const ['text', 'number', 'date'],
      List<String> cased = const ['text'],
      bool resolveDiscriminator = true,
    }) =>
        OneOfGroup(
          discriminator: 'kind',
          discriminatorField: resolveDiscriminator
              ? FormFieldSpec(
                  name: 'kind',
                  label: 'Kind',
                  type: 'enum',
                  enumValues: enumValues)
              : null,
          caseFields: [
            for (final v in cased)
              _field(v, annotations: [
                _ann('Case', {'value': v})
              ]),
          ],
        );

    test('AD13: an incomplete choice reports coverage and names the gap '
        '[2026-07-28] (OK)', () {
      final chips = oneOfChips(group());
      expect(chips.first.label, 'covers 1/3');
      expect(chips.first.role, SpecChipRole.choiceIncomplete);
      expect(chips[1].label, 'uncovered: number, date');
      expect(chips[1].role, SpecChipRole.choiceUncovered);
    });

    test('AD14: a complete choice reports no gap [2026-07-28] (OK)', () {
      final chips = oneOfChips(group(cased: ['text', 'number', 'date']));
      expect(chips.single.label, 'covers 3/3');
      expect(chips.single.role, SpecChipRole.choiceComplete);
    });

    test('AD15: an unresolvable discriminator is flagged as broken '
        '[2026-07-28] (OK)', () {
      final chips = oneOfChips(group(resolveDiscriminator: false));
      expect(chips.single.role, SpecChipRole.choiceBroken);
    });
  });

  group('SpecRowExtras', () {
    test('AD16: on a merged row the field annotation wins over the class '
        '[2026-07-28] (OK)', () {
      final extras = SpecRowExtras.of(
        field: _field('f',
            headline: 'field headline',
            annotations: [
              _ann('Comment', {'text': 'field note'})
            ]),
        cls: SpecClass(name: 'C', headline: 'class headline', annotations: [
          _ann('Comment', {'text': 'class note'})
        ]),
      );
      expect(extras.headline, 'field headline');
      expect(extras.comment, 'field note');
    });

    test('AD17: the class annotation is used when the field is silent '
        '[2026-07-28] (OK)', () {
      final extras = SpecRowExtras.of(
        field: _field('f'),
        cls: SpecClass(name: 'C', headline: 'class headline'),
      );
      expect(extras.headline, 'class headline');
    });

    test('AD18: @Unused on either side marks the row [2026-07-28] (OK)', () {
      expect(
          SpecRowExtras.of(cls: SpecClass(name: 'C', annotations: [_ann('Unused')]))
              .unused,
          isTrue);
      expect(
          SpecRowExtras.of(field: _field('f', annotations: [_ann('Unused')]))
              .unused,
          isTrue);
    });

    test('AD19: the section-id pattern is read independently of the section '
        'id [2026-07-28] (OK)', () {
      final extras = SpecRowExtras.of(
          field: _field('items', sectionIdPattern: 'RQ-{n}'));
      expect(extras.sectionIdPattern, 'RQ-{n}');
    });

    test('AD20: hasReferences covers both provenance kinds [2026-07-28] (OK)',
        () {
      expect(SpecRowExtras.none.hasReferences, isFalse);
      expect(
          SpecRowExtras.of(
                  field: _field('f', annotations: [
            _ann('Reference', {'description': 'see RSP'})
          ])).hasReferences,
          isTrue);
      expect(
          SpecRowExtras.of(
                  field: _field('f',
                      standardReferences:
                          const StandardReferences(standards: ['ISO 1'])))
              .hasReferences,
          isTrue);
    });

    test('AD21: a synthetic row carries no extras [2026-07-28] (OK)', () {
      expect(SpecRowExtras.none.unused, isFalse);
      expect(SpecRowExtras.none.comment, isNull);
      expect(SpecRowExtras.none.serializationOrder, isNull);
    });
  });

  group('coverage contract', () {
    test('AD22: every chip constant names a role its label matches '
        '[2026-07-28] (OK)', () {
      expect(projectionChip.role, SpecChipRole.projection);
      expect(unusedChip.role, SpecChipRole.unused);
      expect(referencesChip.role, SpecChipRole.references);
    });

    test('AD23: the rendered-annotation contract is non-empty and names the '
        'taxonomy links [2026-07-28] (OK)', () {
      expect(kRenderedAnnotations, contains('CodeSpecKind'));
      expect(kRenderedAnnotations, contains('FollowUpKind'));
      expect(kRenderedAnnotations, contains('SectionIdPattern'));
      expect(kRenderedAnnotations, contains('SerializationOrder'));
    });
  });
}
