// A `@Reference` section of the Solution Blueprint holds the section id of the
// entry it names, in a one-field form whose field declares `refersTo` the
// target registry (`tom_specs_model_rules.md` §6.2). The instance tier then
// resolves it in every runtime: a declared id is clean, any other id is a
// `danglingReference` at the section's own path.
//
// RS-1 runs both halves over the real model for every such section, on the
// full-model exercise sample, which holds at least one entry of every
// registry. RS-2 holds every `@Reference` section of the Blueprint to this
// table, so a reference added without a resolvable target fails here.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0.dart';

final _aiBuild = p.normalize(p.join(Directory.current.path, '..'));

/// Reference section id → the registries its `ref`/`refs` field resolves in;
/// the first is the one the test draws a valid id from.
const _references = {
  'EXSDE-PRIM-REF': ['ESENT'],
  'SYDE-SOUR-REF': ['ESENT'],
  'SYDE-TARG-REF': ['ESENT'],
  'SYIN-SOUR-REF': ['ESENT'],
  'SYIN-TARG-REF': ['ESENT'],
  'WAE-PART-REF': ['WSE'],
  'PME-PROC-REF': ['CUBIPR'],
  'SYTS-RELA-REF': ['INEN'],
  'GOLDE-RELA-REF': ['BGE'],
  'KEATT-REFE-REF': ['DAENT'],
  'ENRLE-SOUR-REF': ['DAENT'],
  'ENRLE-TARG-REF': ['DAENT'],
  'DAENRE-RELA-REF': ['DAENT'],
  'BIRURE-RULE-REF': ['BIRU'],
  'AFOB-OBJE-REF': ['BJOEN'],
  'AFFN-FUNC-REF': ['FUNCT'],
  'RQDEP-RELA-REF': ['FRE', 'TERQ', 'SECRQ', 'ORRQ'],
  'RQTSC-RELA-REF': ['ACE'],
};

void main() {
  final model = SpecModel.fromJson(
    jsonDecode(
          File(
            p.join(_aiBuild, 'tom_som_dart_v0', 'meta', 'spec_model.meta.json'),
          ).readAsStringSync(),
        )
        as Map<String, dynamic>,
  );
  final refl = SpecReflection(model);

  SpecDocument sample() => SpecDocumentYaml.decode(
    File(
      p.join(
        _aiBuild,
        'tom_som_conformance',
        'samples',
        'exercise_full_model.docspecs.yaml',
      ),
    ).readAsStringSync(),
    d00SolutionBlueprintMetaTree,
  ).document;

  /// The effective id of the first entry of the registry whose element class
  /// carries [sectionId].
  String firstId(SpecDocument doc, String sectionId) {
    for (final list in doc.listPaths.toList()..sort()) {
      final items = doc.listItems(list);
      if (items.isEmpty) continue;
      if (refl.resolve(items.first)?.targetClass?.sectionId != sectionId) {
        continue;
      }
      final res = refl.resolve(list);
      return effectiveListItemSectionId(
        storedId: doc.itemSectionId(items.first),
        pattern: res?.field?.sectionIdPattern,
        position: 1,
        fallbackStem: res?.field?.name ?? list.split('/').last,
      );
    }
    throw StateError('the sample holds no $sectionId entry');
  }

  /// Every path of a reference section, found through the sample's values:
  /// the exercise sample fills each section's form preamble.
  List<String> pathsOf(SpecDocument doc, String referenceId) => [
    for (final path in doc.contentPaths)
      if (path.endsWith('/$referenceId')) path,
  ];

  for (final MapEntry(key: referenceId, value: targets)
      in _references.entries) {
    final target = targets.first;
    test('RS-1: $referenceId holds an id resolved against $target', () {
      final doc = sample();
      final paths = pathsOf(doc, referenceId);
      expect(paths, isNotEmpty, reason: 'no $referenceId in the sample');
      final field = referenceId == 'WAE-PART-REF' ? 'refs' : 'ref';
      final id = firstId(doc, target);

      for (final path in paths) {
        doc.setFormField(path, field, id);
      }
      List<SpecValidationError> dangling() => [
        for (final e in validateDocument(model, doc))
          if (e.code == SpecValidationCode.danglingReference &&
              paths.contains(e.path))
            e,
      ];
      expect(dangling(), isEmpty, reason: 'a declared $target id');

      for (final path in paths) {
        doc.setFormField(path, field, 'NO-SUCH-ID');
      }
      expect(
        dangling().map((e) => e.path).toSet(),
        paths.toSet(),
        reason: 'an undeclared id is a danglingReference at each section',
      );
    });
  }

  // RS-3: reference-valued form fields that used to be plain text. Each is
  // keyed by its form's section id — a field-level `@Form`'s own id, else the
  // id of the list entry whose transparent `content` form holds it.
  const formReferences = {
    ('PICLS', 'parentProcess'): ['BPREN'],
    ('PCRLT', 'sourceProcess'): ['BPREN', 'CUBIPR'],
    ('PCRLT', 'targetProcess'): ['BPREN', 'CUBIPR'],
    ('INID', 'processReference'): ['BPREN'],
    ('INTR', 'relatedProcess'): ['BPREN'],
    ('INTR', 'relatedBusinessObjects'): ['BJOEN'],
    ('INTR', 'relatedBusinessRules'): ['BIRU'],
    ('INTR', 'relatedIntegrations'): ['EIE'],
    ('SSEC', 'interactionReference'): ['INEN'],
    ('SCCO', 'relatedInteractions'): ['INEN'],
    ('TMED', 'dependsOnPhases'): ['TRPHE'],
    ('TMED', 'dependsOnMilestones'): ['TRMIL'],
    ('TESCBU', 'businessProcessRef'): ['BPREN'],
    ('TESCTR', 'acceptanceCriterionRef'): ['DACEN'],
    ('FESTAS', 'targetStage'): ['STAGE'],
    // uamtc8: links to the right registry. A target written `X.field` resolves
    // against the values entries of X declare in that field.
    ('IOE', 'serverOperation'): ['SVOPE.operationName'],
    ('FNDMX', 'functionRef'): ['FUNCT'],
    ('FNDMX', 'entityName'): ['DAENT.entityName'],
    ('DAATT-SECU', 'sensitivityLevel'): ['DCLSE'],
    ('MOENOW', 'owningContext'): ['BCE.contextName'],
    ('CMPVD', 'libraryRef'): ['FRREEN', 'THPALI'],
    ('FAMREF', 'componentId'): ['UICOM'],
    ('SCETR', 'serverOperations'): ['SVOPE.operationName'],
    ('REID', 'exportOperation'): ['SVOPE.operationName'],
    ('REID', 'displayScreen'): ['SCREN'],
    ('RFEIE', 'entityType'): ['DAENT.entityName'],
    ('QLWGT', 'qualityCategory'): ['QCATE'],
    // uamtcb4: a custom requirement names its handler from the catalogue.
    ('AZREQ-CUST', 'handler'): ['AZHAN.handlerName'],
    ('AZLVL-CUST', 'handler'): ['AZHAN.handlerName'],
  };

  String? formKey(String path) {
    final res = refl.resolve(path);
    final own = res?.field?.sectionId;
    if (own != null) return own;
    final parent = path.substring(0, path.lastIndexOf('/'));
    return refl.resolve(parent)?.targetClass?.sectionId;
  }

  /// The registry key a table entry stands for: `X` is `X.@sectionId`.
  String key(String target) =>
      target.contains('.') ? target : '$target.$kSectionIdSlot';

  /// A value the registry [target] declares in [doc]: an entry's section id,
  /// or for `X.field` the value one of X's forms holds (written there when the
  /// sample leaves it empty).
  String declaredValue(SpecDocument doc, String target) {
    if (!target.contains('.')) return firstId(doc, target);
    final [registry, slot] = target.split('.');
    for (final path in {...doc.contentPaths, ...doc.formPaths}) {
      final parent = path.substring(0, path.lastIndexOf('/'));
      final owner = refl.resolve(parent)?.targetClass?.sectionId;
      if (formKey(path) != registry && owner != registry) continue;
      final fields = refl.resolve(path)?.field?.formFields ?? const [];
      if (!fields.any((f) => f.name == slot)) continue;
      final value = doc.formField(path, slot);
      if (value != null && value.trim().isNotEmpty) return value.trim();
      doc.setFormField(path, slot, 'RS3-DECLARED');
      return 'RS3-DECLARED';
    }
    throw StateError('the sample holds no $target');
  }

  for (final MapEntry(key: (form, field), value: targets)
      in formReferences.entries) {
    test(
      'RS-3: $form.$field holds ids resolved against ${targets.join('/')}',
      () {
        final doc = sample();
        final paths = [
          for (final path in {...doc.contentPaths, ...doc.formPaths})
            if (formKey(path) == form &&
                (refl.resolve(path)?.field?.formFields ?? const []).any(
                  (f) => f.name == field,
                ))
              path,
        ];
        expect(paths, isNotEmpty, reason: 'no $form form in the sample');
        final declared = refl
            .resolve(paths.first)!
            .field!
            .formFields
            .firstWhere((f) => f.name == field)
            .refersTo;
        expect(declared, [for (final t in targets) key(t)]);

        List<SpecValidationError> dangling() => [
          for (final e in validateDocument(model, doc))
            if (e.code == SpecValidationCode.danglingReference &&
                paths.contains(e.path) &&
                e.message.contains('"$field"'))
              e,
        ];
        final id = declaredValue(doc, targets.first);
        for (final path in paths) {
          doc.setFormField(path, field, id);
        }
        expect(dangling(), isEmpty, reason: 'a declared ${targets.first} id');
        for (final path in paths) {
          doc.setFormField(path, field, 'NO-SUCH-ID');
        }
        expect(dangling().map((e) => e.path).toSet(), paths.toSet());
      },
    );
  }

  test('RS-2: every @Reference section of the Blueprint holds a reference', () {
    final found = <String>{};
    void walk(String className, Set<String> seen) {
      if (!seen.add(className)) return;
      final cls = model.classes[className];
      if (cls == null) return;
      for (final f in cls.fields) {
        if (f.reference != null && f.sectionId != null) {
          found.add(f.sectionId!);
          expect(
            f.formFields.single.refersTo,
            [for (final t in _references[f.sectionId]!) '$t.$kSectionIdSlot'],
            reason: '${f.sectionId} resolves against its registry',
          );
        }
        final t = f.type ?? f.elementType;
        if (t != null) walk(t, seen);
      }
    }

    walk('D00SolutionBlueprint', {});
    expect(found, _references.keys.toSet());
  });
}
