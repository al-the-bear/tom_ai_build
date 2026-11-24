/// The section-link conformance tables (idea `section_automation`,
/// part-conformance): the link fixture model `corpus/links.meta.json` and the
/// tables built over it, written by the live runtime under `UPDATE_CORPUS=1`
/// and checked on every other run.
///
/// Tables so far:
///
/// * `link_reader_cases.json` — the typed readers of the link annotations
///   (`syncedWith`, `summaryOf`, `derivedFrom`, `extractsLinks`, `sameAs`, the
///   form-field qualifiers), the `@SameAs` holder of each copy, an older meta
///   loading unchanged, and `textCases` for the place grammar ([SpecPlace])
///   and the filter ([SpecPlaceFilter]), malformed ones included.
///
/// * `link_validation_cases.json` — `validateLinks` over one Blueprint of the
///   fixture: a base document in which every link holds, and one case per
///   finding, each the base with one edit; every case also records the
///   instance tier (`validateDocument`), which is where a `countOf` with `|`
///   is checked.
///
/// * `document_set_cases.json` — `SpecDocumentSet`, `syncReport` and
///   `renameId`: the set's construction (its pairs, its missing roots, every
///   refusal — the last over an inline model), one report case per finding of
///   the set and per comparison rule, scoping, and the global rename.
///
/// * `derive_cases.json` — `deriveFields`: each step, plain and under review
///   (marked), a dry run, what it leaves unresolved; every case run twice, the
///   second run's result the proof of idempotence, with both tiers' findings
///   on the document after it.
///
/// Each case carries a hand-written `intent`: what it exists to show. A run
/// checks that the intent holds in the expectation, so a case that silently
/// stops showing it fails even though Dart reproduces its own output.
///
/// ## Manual review of the generated expectations (DP-part-conformance-1)
///
/// Reviewed 2026-11-24, case by case, against the intents and the decisions
/// of `section_automation.docspecs.md` (part-vocabulary, part-meta,
/// part-operations section 1, part-conformance section 1):
///
/// * **fixture meta read back** — every class sync (`Acceptance` → Screens,
///   `Criteria` and `Requirements` → Detail) has its document as a class name,
///   `detailOnly` / `heldHere` as written and each relation with its prefix
///   stripped (`subset`, the `where` with its `|` kept); `Criteria`'s relation
///   is the only one with a filter. Member links: `KeyRequirements.items`
///   (`subset`, match `KEY.requirementRef`, one repeat),
///   `ScreenOverview.rows` (`document: Screens`, `equal`), `Requirement.links`
///   with two `@ExtractsLinks` in source order (`generate`, then `warn`), the
///   member `@DerivedFrom.copy` on `abstract` and `.rows` with its `map` on
///   `prerequisites`, `CriteriaSummary.criteria` with its `@SameAs` holder.
///   Form-field qualifiers: `conflictsWith` (`rows`, `where`, `take`),
///   `lastVersion` (`lookup`, `key` / `by`), `relatedScreens` and
///   `relatedRequirements` naming each other, the symmetric `LNK-REF.ref`
///   (`@self`, `where`), `focusScreens` (`summaryOf` across documents, its
///   default relation written). Defaults are written where the annotation
///   has one (`relation`, `mode`, empty `repeats` / `map` / `take`), nulls
///   left out. The one binding: Blueprint's `criteriaSummary/criteria` copy
///   held by `acceptance/criteria`; Detail and Screens reach `Criteria` once
///   and have no copy. Correct.
/// * **older meta** — a meta with an unknown annotation and an unknown
///   form-field key, and none of the link keys, loads; every reader answers
///   absent. Correct (part-meta: an older meta loads unchanged).
/// * **places** — each resolved path is the document path where the value is
///   stored: a form field in its form (`…/content` for a class's own form,
///   `…/REQD` for a form member), a headline and a section id at the list
///   item, the list at its container, list items below the anchor as `-*`,
///   items at and above it as written. `./` resolves beneath the nearest list
///   element at or above the anchor; a `/` path names every section on the
///   way but `-LST` containers and the scope's own id. Every problem appears
///   once with the case that should provoke it: `CRITE.text` from the
///   Blueprint root is `ambiguous` (the copy and its holder), from
///   `acceptance` it resolves. Correct.
/// * **filters** — parsed parts, the entries' place, `matches` comparing
///   trimmed stored values against the alternatives, malformed texts (no `=`,
///   an empty alternative, a `/` path, no id) refused; `REQ.nope=x` is
///   `noSuchField`. Correct.
/// * **fixture additions for the link validation table** — the one-way
///   inverse pair `REQT.relatedCriteria` ↔ `CRITE.relatedRequirements` and the
///   `equal` field summary `REQS-SUM.allRequirements` read back as written
///   (bare `equal`, empty `repeats`). Correct.
///
/// ## Manual review of `link_validation_cases.json` (DP-part-conformance-1)
///
/// Reviewed 2026-11-24 against the intents and part-operations section 2:
///
/// * **the clean base** reports nothing, on either tier: REQ-EXPORT's text
///   names REQ-PURGE, which it has a conflict row for (an id with a row of
///   any type is a reference, DP-part-cleanup-7); the screen overview and the
///   focus screens summarise another document and are skipped; the relatedScreens
///   end names a registry the Blueprint does not hold and is skipped. A derived
///   value left empty is not reported (deriveFields writes it). Correct.
/// * **derivedValueMismatch** — the copy (`REQAB`), the collected conflict ids
///   (`REQC`), the looked-up version (`content`), the derived prerequisite list
///   (`PRE-ITEM-LST`) and a repeated summary title, each at the place holding
///   the stored value. Correct.
/// * **derivedLookupMiss** — REQ-PURGE with its revision removed, REQ-EXPORT
///   with two; the stored version is then not compared. Correct.
/// * **duplicateLinkRow** at the second `namedInText` row naming REQ-IMPORT;
///   **inverseMissing** at REQ-EXPORT's conflict row once REQ-PURGE's is gone,
///   and at REQ-EXPORT's `REQT` once the criterion no longer names it back
///   (cleared in holder and copy, so no copy finding). Correct.
/// * **extractedLinkMissing** at the link list of REQ-IMPORT, once from the
///   generate-mode description and once from the warn-mode constraints;
///   **extractedLinkStale** at the generated row whose id the text dropped.
///   Correct.
/// * **summaryNotInDetail** for a row and for the field summary naming
///   REQ-GONE — the instance tier reports the same id as a dangling reference,
///   as it should; **summaryDuplicate** at the second key row;
///   **detailNotInSummary** at REQ-PURGE, which the `equal` field summary
///   leaves out. Correct.
/// * **sameAsMismatch** at the copy's differing criterion text, and once — not
///   per field — for a criterion the copy lacks. Correct.
/// * **countMismatch** (instance tier) for `settled: 3` against approved|done;
///   **linkValuePending** at a description holding a pending change, read with
///   the mark rejected, so nothing else moves. Correct.
/// * The base gained a `weight` and names the one screen of the base set
///   (`SCRN-LOGIN`) in its overview and focus, so the document-set table can
///   reuse it; every case above reads the same after it.
///
/// ## Manual review of `document_set_cases.json` (DP-part-conformance-1)
///
/// Reviewed 2026-11-24 against the intents and part-operations sections 3–4:
///
/// * **construction** — the base set's three pairs (`REQS` and `CRIT` with
///   Detail, `ACC` with Screens), `CRIT` paired at the acceptance's criteria,
///   not at the summary's `@SameAs` copy; without Screens its root is missing
///   and the pairs stay; two Blueprint fragments assembled under the first
///   fragment's name; the refusals `sameRoot` (both documents named),
///   `noRoot`, `twoRoots`, `projection`, `overlap` (both fragments) and
///   `unpairable` (the inline model's `Part`, reached twice). Correct.
/// * **the base set** is clean: Detail's rationale (detailOnly `REQX`), the
///   criteria under the Screens' acceptance (detailOnly `CRIT`), the derived
///   `lastVersion` and counts, and the copy are not compared. Correct.
/// * **values** — a status differing (`backfill`, held by Detail); the owner,
///   which the Blueprint holds (`heldHere`), differing (`agent`, holder
///   `blueprint`); a description the Blueprint lacks (`sharedValueMissing`)
///   and one Detail emptied (`sharedValueOnlyInBlueprint`), each side naming
///   the field. Correct.
/// * **elements** — a requirement only in Detail (`sharedElementMissing`,
///   the Blueprint side the list it goes in), with Detail's own count and
///   equal summary moving in its document findings; a key row only in the
///   Blueprint; under the criteria's `subset` with `where`, a quality
///   criterion only in Detail may be added (`info`, the report clean) and a
///   legal one, outside the filter, is held to equal; the `subset` reference
///   field `relatedScreens` one screen more in Detail (`info`) and one only in
///   the Blueprint (`sharedElementOnlyInBlueprint`). Correct.
/// * **across documents** — a screen the Blueprint's `equal` overview leaves
///   out, a focus screen the Screens document lacks (`crossSummaryMismatch`),
///   and a requirement in Detail naming a screen that does not name it back
///   (`crossInverseMissing`, read from Detail, the requirements' own
///   document, never twice from the Blueprint). Correct.
/// * **rules** — a pending mark listed as `pendingReview` (`info`, clean) with
///   Detail's own `linkValuePending` beside; trimmed text, `2` / `2.0` in a
///   double and reordered criteria agree; Screens missing is `notStarted`;
///   scoping to `CRIT` drops a `REQS` finding, scoping to `REQS` keeps it;
///   findings of two pairs come in pair order. Correct.
/// * **renameId** — `REQ-IMPORT` renamed in both documents: the element, the
///   references (link rows, a revision, the prerequisite, the summary field)
///   and the texts naming it; the set is clean after it. A rename onto
///   `REQ-PURGE` is refused, naming the two documents that hold it. Correct.
/// * **unmarkable** (added with `deriveFields`) — a description whose copy
///   differs inside fenced code, in the Blueprint and in Detail: one
///   `unmarkable` finding per document, resolution `agent`. Correct.
///
/// ## Manual review of `derive_cases.json` (DP-part-conformance-1)
///
/// Reviewed 2026-11-24 against the intents and part-operations section 5:
///
/// * **the base Blueprint** (every derived place filled, `REQAB` of all three
///   requirements included) writes nothing; the `relatedScreens` end, whose
///   screens the document does not hold, is not written. Correct.
/// * **step 1** — REQ-PURGE's missing conflict row added back (`conflict`,
///   naming REQ-EXPORT), and step 2 then deriving its `conflictsWith`; the
///   criterion's missing `relatedRequirements` written back, and step 2
///   copying it into the `@SameAs` copy; a row added for REQ-EXPORT named in
///   REQ-IMPORT's description (`namedInText`), the description's copy
///   following; the stale `namedInText` row of REQ-EXPORT removed, its copy
///   re-derived; a link row with no value removed. Each leaves the document
///   clean on both tiers, and a second run writes nothing. Correct.
/// * **step 2** — the copy (`REQAB`), the collected conflict ids, the
///   looked-up version, the prerequisite list (one element added for the
///   prerequisite row), the key row's repeated title and the `@SameAs` copy
///   (the holder's element added with its section id, the copy's own element
///   removed, a differing text rewritten). Correct.
/// * **step 3** — `total` 3, `settled` 2 (approved | done), the products
///   weight × effort written as doubles (`6.0`, `3.0`, `4.0`) and the ranks by
///   score, highest first. Correct.
/// * **unresolved** — REQ-PURGE's lookup without its revision row
///   (`derivedLookupMiss`), nothing written for it. Correct.
/// * **dry run** — the same changes answered, the given document unchanged
///   (its second run answers them again). Correct.
/// * **under review** — every value written as a mark attributed to
///   `agent_spec_author`: insertions for empty places, a substitution for
///   the rewritten copy text, typed values (`{~~ 3 ~> 2 ~~}`, `{++ 6.0 ++}`)
///   alike; a removed row's values proposed for deletion, the row kept;
///   a change inside fenced code left `unmarkable` while the rest is written.
///   The findings after a marked run are those of the reviewed state (the
///   marks pending), as they should be; a second run writes nothing. Correct.
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  final corpusDir = Directory(
    '${Directory.current.path}/../tom_som_conformance/corpus',
  );
  final update = Platform.environment['UPDATE_CORPUS'] == '1';
  final meta = buildLinksMeta();
  final readerCases = buildLinkReaderCases(meta);
  final validationCases = buildLinkValidationCases(meta);
  final setCases = buildDocumentSetCases(meta);
  final deriveCases = buildDeriveCases(meta);

  String encode(Object? json) =>
      '${const JsonEncoder.withIndent('  ').convert(json)}\n';

  setUpAll(() {
    if (!update) return;
    File('${corpusDir.path}/links.meta.json').writeAsStringSync(encode(meta));
    File(
      '${corpusDir.path}/link_reader_cases.json',
    ).writeAsStringSync(encode(readerCases));
    File(
      '${corpusDir.path}/link_validation_cases.json',
    ).writeAsStringSync(encode(validationCases));
    File(
      '${corpusDir.path}/document_set_cases.json',
    ).writeAsStringSync(encode(setCases));
    File(
      '${corpusDir.path}/derive_cases.json',
    ).writeAsStringSync(encode(deriveCases));
  });

  Object? onDisk(String name) =>
      jsonDecode(File('${corpusDir.path}/$name').readAsStringSync());

  group('corpus files', () {
    test('LRC1: links.meta.json is the fixture the builder writes', () {
      expect(onDisk('links.meta.json'), jsonDecode(jsonEncode(meta)));
    });

    test('LRC2: link_reader_cases.json is the table the builder writes', () {
      expect(
        onDisk('link_reader_cases.json'),
        jsonDecode(jsonEncode(readerCases)),
      );
    });

    test('LRC3: the table on disk is reproduced from its own inputs', () {
      // What a runner of another language does: read the inputs of each case
      // from the files and compare its own results with `expect`.
      final diskMeta = onDisk('links.meta.json') as Map<String, dynamic>;
      final table = onDisk('link_reader_cases.json') as Map<String, dynamic>;
      for (final c in (table['cases'] as List).cast<Map<String, dynamic>>()) {
        final m = c['model'] == 'links.meta.json'
            ? diskMeta
            : c['meta'] as Map<String, dynamic>;
        expect(
          jsonDecode(jsonEncode(linkReadBack(SpecModel.fromJson(m)))),
          c['expect'],
          reason: c['name'] as String,
        );
      }
      final refl = SpecReflection(SpecModel.fromJson(diskMeta));
      final text = table['textCases'] as Map<String, dynamic>;
      for (final c in (text['places'] as List).cast<Map<String, dynamic>>()) {
        expect(
          jsonDecode(jsonEncode(placeCase(refl, c))),
          c['expect'],
          reason: c['name'] as String,
        );
      }
      for (final c in (text['filters'] as List).cast<Map<String, dynamic>>()) {
        expect(
          jsonDecode(jsonEncode(filterCase(refl, c))),
          c['expect'],
          reason: c['name'] as String,
        );
      }
    });

    test('LRC4: every case shows its intent', () {
      for (final c
          in (readerCases['cases'] as List).cast<Map<String, dynamic>>()) {
        final expectation = c['expect'] as Map<String, dynamic>;
        for (final token in (c['intent'] as List).cast<String>()) {
          expect(
            _readerIntentHolds(token, expectation),
            isTrue,
            reason: '${c['name']}: intent "$token"',
          );
        }
      }
      final text = readerCases['textCases'] as Map<String, dynamic>;
      for (final c in [
        ...(text['places'] as List).cast<Map<String, dynamic>>(),
        ...(text['filters'] as List).cast<Map<String, dynamic>>(),
      ]) {
        final shown = _tokens(c['expect']);
        for (final token in (c['intent'] as List).cast<String>()) {
          expect(
            shown,
            contains(token),
            reason: '${c['name']}: intent "$token"',
          );
        }
      }
    });
  });

  group('link validation', () {
    test(
      'LVC1: link_validation_cases.json is the table the builder writes',
      () {
        expect(
          onDisk('link_validation_cases.json'),
          jsonDecode(jsonEncode(validationCases)),
        );
      },
    );

    test('LVC2: the table on disk is reproduced from its own inputs', () {
      final model = SpecModel.fromJson(
        onDisk('links.meta.json') as Map<String, dynamic>,
      );
      final table =
          onDisk('link_validation_cases.json') as Map<String, dynamic>;
      for (final c in (table['cases'] as List).cast<Map<String, dynamic>>()) {
        final got = linkValidationCase(model, c['state'] as Map);
        expect(got['errors'], c['errors'], reason: c['name'] as String);
        expect(
          got['instanceErrors'],
          c['instanceErrors'],
          reason: c['name'] as String,
        );
      }
    });

    test('LVC3: every case shows its intent', () {
      for (final c
          in (validationCases['cases'] as List).cast<Map<String, dynamic>>()) {
        final codes = {
          for (final e in [
            ...(c['errors'] as List),
            ...(c['instanceErrors'] as List),
          ])
            (e as Map)['code'] as String,
        };
        for (final token in (c['intent'] as List).cast<String>()) {
          if (token == 'clean') {
            expect(codes, isEmpty, reason: '${c['name']}: intent "clean"');
          } else {
            expect(
              codes,
              contains(token),
              reason: '${c['name']}: intent "$token"',
            );
          }
        }
      }
    });

    test('LVC4: every link code has a provoking case', () {
      final provoked = {
        for (final c in (validationCases['cases'] as List))
          for (final e in ((c as Map)['errors'] as List))
            (e as Map)['code'] as String,
      };
      const linkCodes = [
        SpecValidationCode.derivedValueMismatch,
        SpecValidationCode.derivedLookupMiss,
        SpecValidationCode.duplicateLinkRow,
        SpecValidationCode.inverseMissing,
        SpecValidationCode.extractedLinkMissing,
        SpecValidationCode.extractedLinkStale,
        SpecValidationCode.summaryNotInDetail,
        SpecValidationCode.detailNotInSummary,
        SpecValidationCode.summaryDuplicate,
        SpecValidationCode.sameAsMismatch,
        SpecValidationCode.linkValuePending,
      ];
      expect(provoked, containsAll(linkCodes.map((c) => c.name)));
    });
  });

  group('deriveFields', () {
    test('DRC1: derive_cases.json is the table the builder writes', () {
      expect(onDisk('derive_cases.json'), jsonDecode(jsonEncode(deriveCases)));
    });

    test('DRC2: the table on disk is reproduced from its own inputs', () {
      final model = SpecModel.fromJson(
        onDisk('links.meta.json') as Map<String, dynamic>,
      );
      final table = onDisk('derive_cases.json') as Map<String, dynamic>;
      for (final c in (table['cases'] as List).cast<Map<String, dynamic>>()) {
        expect(
          jsonDecode(jsonEncode(deriveCase(model, c))),
          c['expect'],
          reason: c['name'] as String,
        );
      }
    });

    test('DRC3: every case shows its intent', () {
      for (final c
          in (jsonDecode(jsonEncode(deriveCases))['cases'] as List)
              .cast<Map<String, dynamic>>()) {
        for (final token in (c['intent'] as List).cast<String>()) {
          expect(
            _deriveIntentHolds(token, c),
            isTrue,
            reason: '${c['name']}: intent "$token"',
          );
        }
      }
    });
  });

  group('document set', () {
    test('DSC1: document_set_cases.json is the table the builder writes', () {
      expect(
        onDisk('document_set_cases.json'),
        jsonDecode(jsonEncode(setCases)),
      );
    });

    test('DSC2: the table on disk is reproduced from its own inputs', () {
      final model = SpecModel.fromJson(
        onDisk('links.meta.json') as Map<String, dynamic>,
      );
      final table = onDisk('document_set_cases.json') as Map<String, dynamic>;
      for (final c
          in (table['construction'] as List).cast<Map<String, dynamic>>()) {
        final m = c['meta'] == null
            ? model
            : SpecModel.fromJson(c['meta'] as Map<String, dynamic>);
        expect(
          jsonDecode(jsonEncode(setConstructionCase(m, c))),
          c['expect'],
          reason: c['name'] as String,
        );
      }
      for (final c in (table['reports'] as List).cast<Map<String, dynamic>>()) {
        expect(
          jsonDecode(jsonEncode(setReportCase(model, c))),
          c['expect'],
          reason: c['name'] as String,
        );
      }
      for (final c in (table['renames'] as List).cast<Map<String, dynamic>>()) {
        expect(
          jsonDecode(jsonEncode(setRenameCase(model, c))),
          c['expect'],
          reason: c['name'] as String,
        );
      }
    });

    test('DSC3: every case shows its intent', () {
      for (final group in ['construction', 'reports', 'renames']) {
        for (final c
            in (setCases[group] as List).cast<Map<String, dynamic>>()) {
          final shown = _setTokens(
            jsonDecode(jsonEncode(c['expect'])) as Map<String, dynamic>,
          );
          for (final token in (c['intent'] as List).cast<String>()) {
            expect(
              shown,
              contains(token),
              reason: '${c['name']}: intent "$token"',
            );
          }
        }
      }
    });

    test('DSC4: the real model pairs every synced class', () {
      final real = SpecModel.fromJson(
        jsonDecode(
              File(
                '${Directory.current.path}/../tom_som_dart_v0/meta/'
                'spec_model.meta.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final set = SpecDocumentSet(real, const {});
      expect(set.blueprintRoot, 'D00SolutionBlueprint');
      expect(set.pairs, hasLength(132));
    });
  });

  group('readers', () {
    final model = SpecModel.fromJson(meta);

    test('LR1: the class sync is read with its relations', () {
      final sync = model.classes['Requirements']!.syncedWith!;
      expect(sync.document, 'Detail');
      expect(sync.detailOnly, ['REQX']);
      expect(sync.heldHere, ['REQ.owner']);
      expect(sync.relations.single.relation, 'subset');
      expect(
        model.classes['Criteria']!.syncedWith!.relations.single.where,
        'CRITE.kind=functional|quality',
      );
      expect(model.classes['Blueprint']!.syncedWith, isNull);
    });

    test('LR2: member links and the repeated @ExtractsLinks', () {
      final req = model.classes['Requirement']!;
      final links = req.fieldNamed('links')!.extractsLinks;
      expect(links.map((e) => e.mode), ['generate', 'warn']);
      expect(links.first.set, {'LNK.linkType': 'namedInText'});
      expect(req.fieldNamed('abstract')!.derivedFrom!.kind, 'copy');
      expect(req.fieldNamed('prerequisites')!.derivedFrom!.map, {
        'PRE.ref': 'LNK-REF.ref',
      });
      expect(req.fieldNamed('links')!.summaryOf, isNull);
    });

    test('LR3: the form-field qualifiers', () {
      FormFieldSpec ff(String cls, String field, String name) => model
          .classes[cls]!
          .fieldNamed(field)!
          .formFields
          .firstWhere((f) => f.name == name);
      expect(
        ff('Requirement', 'constraints', 'conflictsWith').derivedFrom!.where,
        'LNK.linkType=conflict',
      );
      expect(ff('Link', 'ref', 'ref').inverseOf!.symmetric, isTrue);
      expect(
        ff('Requirement', 'trace', 'relatedScreens').inverseOf!.symmetric,
        isFalse,
      );
      expect(
        ff('Blueprint', 'focus', 'focusScreens').summaryOf!.document,
        'Screens',
      );
    });

    test('LR4: the real model — S1 has one holder in each document', () {
      final real = SpecModel.fromJson(
        jsonDecode(
              File(
                '${Directory.current.path}/../tom_som_dart_v0/meta/'
                'spec_model.meta.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>,
      );
      final refl = SpecReflection(real);
      for (final root in ['D00SolutionBlueprint', 'D10QualityAcceptancePlan']) {
        final bindings = specSameAsBindings(refl, root);
        expect(bindings, hasLength(1), reason: root);
        expect(bindings.single.className, 'AcceptanceCriteriaList');
        expect(bindings.single.problem, isNull, reason: root);
        expect(bindings.single.copyPath, endsWith('/detailedCriteria'));
      }
    });
  });

  group('countOf reads the filter', () {
    final model = SpecModel.fromJson(meta);
    const reqs = 'BLU/requirements';

    SpecDocument doc(String settled, {String total = '3'}) {
      final d = SpecDocument();
      for (final status in ['approved', 'done', 'draft']) {
        final item = d.addListItem('$reqs/REQ-ITEM-LST');
        d.setFormField('$item/content', 'status', status);
      }
      d.setFormField('$reqs/REQS-SUM', 'total', total);
      d.setFormField('$reqs/REQS-SUM', 'settled', settled);
      return d;
    }

    List<String> counts(SpecDocument d) => [
      for (final e in validateDocument(model, d))
        if (e.code == SpecValidationCode.countMismatch) e.path,
    ];

    test('CO1: `|` counts the entries holding either alternative', () {
      expect(counts(doc('2')), isEmpty);
    });

    test('CO2: a count that disagrees with the alternatives is reported', () {
      expect(counts(doc('3')), ['$reqs/REQS-SUM']);
      expect(counts(doc('2', total: '2')), ['$reqs/REQS-SUM']);
    });
  });
}

// ---------------------------------------------------------------------------
// The evaluation a runner of every language performs
// ---------------------------------------------------------------------------

/// What the readers return for [model], in canonical JSON: every class sync,
/// every member link, every form-field qualifier, and the `@SameAs` bindings
/// per root. Classes by name, fields and form fields in declaration order.
Map<String, Object?> linkReadBack(SpecModel model) {
  final names = model.classes.keys.toList()..sort();
  return {
    'classes': [
      for (final n in names)
        if (model.classes[n]!.syncedWith != null)
          {'class': n, 'syncedWith': model.classes[n]!.syncedWith!.toJson()},
    ],
    'fields': [
      for (final n in names)
        for (final f in model.classes[n]!.fields)
          if (f.syncedWith != null ||
              f.summaryOf != null ||
              f.derivedFrom != null ||
              f.extractsLinks.isNotEmpty ||
              f.sameAs != null)
            {
              'class': n,
              'field': f.name,
              if (f.syncedWith != null) 'syncedWith': f.syncedWith!.toJson(),
              if (f.summaryOf != null) 'summaryOf': f.summaryOf!.toJson(),
              if (f.derivedFrom != null) 'derivedFrom': f.derivedFrom!.toJson(),
              if (f.extractsLinks.isNotEmpty)
                'extractsLinks': [for (final e in f.extractsLinks) e.toJson()],
              if (f.sameAs != null) 'sameAs': f.sameAs!.toJson(),
            },
    ],
    'formFields': [
      for (final n in names)
        for (final f in model.classes[n]!.fields)
          for (final ff in f.formFields)
            if (ff.derivedFrom != null ||
                ff.inverseOf != null ||
                ff.summaryOf != null)
              {
                'class': n,
                'field': f.name,
                'formField': ff.name,
                if (ff.derivedFrom != null)
                  'derivedFrom': ff.derivedFrom!.toJson(),
                if (ff.inverseOf != null) 'inverseOf': ff.inverseOf!.toJson(),
                if (ff.summaryOf != null) 'summaryOf': ff.summaryOf!.toJson(),
              },
    ],
    'sameAsBindings': [
      for (final r in model.roots)
        for (final b in specSameAsBindings(SpecReflection(model), r.type))
          b.toJson(),
    ],
    'classCount': model.classes.length,
  };
}

/// One place case: the text parsed, then resolved under `anchor` when given.
Map<String, Object?> placeCase(SpecReflection refl, Map<String, dynamic> c) {
  final text = c['text'] as String;
  final place = SpecPlace.tryParse(text);
  if (place == null) return {'problem': SpecPlaceProblem.malformed.name};
  final anchor = c['anchor'] as String?;
  if (anchor == null) return {'parsed': place.toJson()};
  try {
    return {
      'parsed': place.toJson(),
      'resolved': place.resolve(refl, anchor).toJson(),
    };
  } on SpecPlaceException catch (e) {
    return {'parsed': place.toJson(), 'problem': e.problem.name};
  }
}

/// One filter case: the text parsed, resolved under `anchor` when given, and
/// matched against `stored` when given.
Map<String, Object?> filterCase(SpecReflection refl, Map<String, dynamic> c) {
  final text = c['text'] as String;
  final filter = SpecPlaceFilter.tryParse(text);
  if (filter == null) return {'problem': SpecPlaceProblem.malformed.name};
  final out = <String, Object?>{'parsed': filter.toJson()};
  final stored = c['stored'] as List?;
  if (stored != null) out['matches'] = filter.matches(stored.cast<String>());
  final anchor = c['anchor'] as String?;
  if (anchor != null) {
    try {
      out['resolved'] = filter.resolve(refl, anchor).toJson();
    } on SpecPlaceException catch (e) {
      out['problem'] = e.problem.name;
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// The intents
// ---------------------------------------------------------------------------

/// Whether the reader-case intent [token] holds in [e].
bool _readerIntentHolds(String token, Map<String, dynamic> e) {
  List<Map<String, dynamic>> rows(String key) =>
      (e[key] as List).cast<Map<String, dynamic>>();
  bool fieldHas(String key) => rows('fields').any((r) => r.containsKey(key));
  bool formHas(String key) => rows('formFields').any((r) => r.containsKey(key));
  return switch (token) {
    'syncedWith' => rows('classes').isNotEmpty,
    'syncRelationWhere' => rows('classes').any(
      (r) => ((r['syncedWith'] as Map)['relations'] as List).any(
        (x) => (x as Map).containsKey('where'),
      ),
    ),
    'summaryOf' => fieldHas('summaryOf'),
    'summaryOfDocument' => rows(
      'fields',
    ).any((r) => (r['summaryOf'] as Map?)?.containsKey('document') ?? false),
    'derivedFrom' => fieldHas('derivedFrom'),
    'extractsLinksRepeated' => rows(
      'fields',
    ).any((r) => ((r['extractsLinks'] as List?)?.length ?? 0) > 1),
    'sameAs' => fieldHas('sameAs'),
    'formDerivedFrom' => formHas('derivedFrom'),
    'formInverseOf' => formHas('inverseOf'),
    'formSymmetric' => rows('formFields').any(
      (r) =>
          ((r['inverseOf'] as Map?)?['fields'] as List?)?.contains('@self') ??
          false,
    ),
    'formSummaryOf' => formHas('summaryOf'),
    'sameAsHolder' => rows(
      'sameAsBindings',
    ).any((r) => r.containsKey('holder')),
    'loadsUnchanged' =>
      (e['classCount'] as int) > 0 &&
          rows('classes').isEmpty &&
          rows('fields').isEmpty &&
          rows('formFields').isEmpty &&
          rows('sameAsBindings').isEmpty,
    _ => throw StateError('unknown intent token "$token"'),
  };
}

/// Every string a text case's expectation shows: kinds, problems, and
/// `matches` / `noMatch`.
Set<String> _tokens(Object? e) {
  final out = <String>{};
  void walk(Object? v, [String? key]) {
    if (v is Map) {
      v.forEach((k, x) => walk(x, k as String));
    } else if (v is List) {
      v.forEach(walk);
    } else if (key == 'matches' && v is bool) {
      out.add(v ? 'matches' : 'noMatch');
    } else if (v is String && (key == 'kind' || key == 'problem')) {
      out.add(v);
    }
  }

  walk(e);
  return out;
}

// ---------------------------------------------------------------------------
// The cases
// ---------------------------------------------------------------------------

/// The table `link_reader_cases.json`, its expectations computed live.
Map<String, Object?> buildLinkReaderCases(Map<String, dynamic> meta) {
  final model = SpecModel.fromJson(meta);
  final refl = SpecReflection(model);
  final older = _olderMeta();

  Map<String, Object?> place(
    String name,
    List<String> intent,
    String text, [
    String? anchor,
  ]) {
    final c = <String, dynamic>{
      'name': name,
      'intent': intent,
      'text': text,
      if (anchor != null) 'anchor': anchor,
    };
    return {...c, 'expect': placeCase(refl, c)};
  }

  Map<String, Object?> filter(
    String name,
    List<String> intent,
    String text, {
    String? anchor,
    List<String>? stored,
  }) {
    final c = <String, dynamic>{
      'name': name,
      'intent': intent,
      'text': text,
      if (anchor != null) 'anchor': anchor,
      if (stored != null) 'stored': stored,
    };
    return {...c, 'expect': filterCase(refl, c)};
  }

  const blu = 'BLU';
  const reqs = 'BLU/requirements';
  const item = 'BLU/requirements/REQ-ITEM-LST-1';

  return {
    'model': 'links.meta.json',
    'cases': [
      {
        'name': 'the fixture meta read back',
        'intent': [
          'syncedWith',
          'syncRelationWhere',
          'summaryOf',
          'summaryOfDocument',
          'derivedFrom',
          'extractsLinksRepeated',
          'sameAs',
          'formDerivedFrom',
          'formInverseOf',
          'formSymmetric',
          'formSummaryOf',
          'sameAsHolder',
        ],
        'model': 'links.meta.json',
        'expect': linkReadBack(model),
      },
      {
        'name': 'an older meta without the link keys loads unchanged',
        'intent': ['loadsUnchanged'],
        'meta': older,
        'expect': linkReadBack(SpecModel.fromJson(older)),
      },
    ],
    'textCases': {
      'places': [
        place(
          'a form field of a form member',
          ['formField'],
          'REQD.description',
          reqs,
        ),
        place(
          "a form field of a class's own form",
          ['formField'],
          'REQ.status',
          reqs,
        ),
        place('a whole form member', ['form'], 'REQD', reqs),
        place('a heading', ['headline'], 'REQ.@headline', reqs),
        place('a list', ['list'], 'REQ-ITEM-LST', blu),
        place('a section', ['section'], 'REQS', blu),
        place('a registry id', ['sectionId'], 'REQ.@sectionId', reqs),
        place('a content member', ['content'], 'REQAB', reqs),
        place(
          '@content of a narrative section',
          ['content'],
          'CSUM.@content',
          blu,
        ),
        place(
          'a ./ place beneath the list element of the anchor',
          ['formField'],
          './LNK.linkType',
          item,
        ),
        place(
          'a ./ place resolves beneath the nearest list element only',
          ['unresolved'],
          './REQD.description',
          '$item/LNK-ITEM-LST-1',
        ),
        place('a / path', ['formField'], 'REQ/LNK.description', reqs),
        place(
          'a / path naming the copy',
          ['formField'],
          'CSUM/CRIT/CRITE.text',
          blu,
        ),
        place(
          'one id reached twice is ambiguous',
          ['ambiguous'],
          'CRITE.text',
          blu,
        ),
        place(
          'the same id under one of the two positions',
          ['formField'],
          'CRITE.text',
          'BLU/acceptance',
        ),
        place(
          'an id the scope does not reach',
          ['unresolved'],
          'SCRN.purpose',
          blu,
        ),
        place(
          'a / path skipping a section',
          ['unresolved'],
          'REQS/LNK.description',
          blu,
        ),
        place('no such form field', ['noSuchField'], 'REQ.nope', reqs),
        place(
          '@content of a form section',
          ['noContent'],
          'REQ.@content',
          reqs,
        ),
        place(
          '@sectionId of no list element',
          ['notListElement'],
          'REQS.@sectionId',
          blu,
        ),
        place('a reserved slot', ['reservedSlot'], 'REQ.@title', reqs),
        place(
          './ with no list element at or above',
          ['notScoped'],
          './LNK',
          reqs,
        ),
        place(
          'an anchor that resolves to no section',
          ['anchorUnresolved'],
          'REQ.status',
          'BLU/nowhere',
        ),
        place('parsed only', [], 'FRE/REQDEP/RQDEP.description'),
        place('empty', ['malformed'], ''),
        place('a bare ./', ['malformed'], './'),
        place('an empty slot', ['malformed'], 'REQ.'),
        place('two dots', ['malformed'], 'REQ.status.x'),
        place('an id starting with a hyphen', ['malformed'], '-REQ.status'),
        place('an empty / segment', ['malformed'], 'REQ//LNK'),
      ],
      'filters': [
        filter('every entry', ['section'], 'REQ', anchor: blu),
        filter('a ./ entry', ['section'], './LNK', anchor: item),
        filter(
          'one value',
          ['section', 'matches'],
          'REQ.status=approved',
          anchor: reqs,
          stored: ['approved'],
        ),
        filter(
          'alternatives, the stored value trimmed',
          ['matches'],
          'REQ.status=approved|done',
          stored: [' done '],
        ),
        filter(
          'alternatives, none stored',
          ['noMatch'],
          'REQ.status=approved|done',
          stored: ['draft'],
        ),
        filter(
          'alternatives, nothing stored',
          ['noMatch'],
          'REQ.status=approved|done',
          stored: [],
        ),
        filter(
          'without a field every entry matches',
          ['matches'],
          'REQ',
          stored: [],
        ),
        filter(
          'a scoped filter with alternatives',
          ['section'],
          './LNK.linkType=conflict|namedInText',
          anchor: item,
        ),
        filter(
          'no such form field',
          ['noSuchField'],
          'REQ.nope=x',
          anchor: reqs,
        ),
        filter(
          './ with no list element at or above',
          ['notScoped'],
          './LNK',
          anchor: reqs,
        ),
        filter('a field without a value', ['malformed'], 'REQ.status'),
        filter('an empty value', ['malformed'], 'REQ.status='),
        filter('an empty trailing alternative', [
          'malformed',
        ], 'REQ.status=approved|'),
        filter('an empty leading alternative', [
          'malformed',
        ], 'REQ.status=|approved'),
        filter('a / path', ['malformed'], 'REQ/LNK.linkType=conflict'),
        filter('no id', ['malformed'], '.status=x'),
        filter('a bare ./', ['malformed'], './'),
      ],
    },
  };
}

/// An older meta: none of the link annotations or keys, an annotation and a
/// form-field key no reader knows.
Map<String, dynamic> _olderMeta() => {
  'metaSchemaVersion': 1,
  'modelVersion': 1,
  'modelVersionLabel': 'links-older-1.0',
  'generatedAt': '2026-11-24T08:00:00.000000Z',
  'classCount': 2,
  'rootCount': 1,
  'roots': [
    {'type': 'Old', 'title': 'Old Document', 'sectionId': 'OLD'},
  ],
  'classes': {
    'Old': _cls(
      'Old',
      'OLD',
      [_list('entries', 'ENT-LST', 'ENT-xxx', 'OldEntry')],
      annotations: [
        _a('Document', {'name': 'Old Document', 'description': 'older'}),
        _a('DetailedIn', {'target': 'Old'}),
      ],
    ),
    'OldEntry': _cls(
      'OldEntry',
      'ENT',
      [
        _form('content', null, [
          _ff('ref', 'String', {
            'refersTo': ['ENT.@sectionId'],
            'futureKey': {'kind': 'something'},
          }),
        ]),
      ],
      annotations: [
        _a('FutureLink', {'place': 'ENT.ref', 'relation': 'Future.kind'}),
      ],
    ),
  },
};

// ---------------------------------------------------------------------------
// The table `link_validation_cases.json`
// ---------------------------------------------------------------------------

/// One validation case: [state] loaded, then `validateLinks` and the instance
/// tier, each finding as `{path, code}`.
Map<String, Object?> linkValidationCase(
  SpecModel model,
  Map<dynamic, dynamic> state,
) {
  final doc = SpecDocument()..loadJson(state);
  List<Map<String, String>> pairs(List<SpecValidationError> errors) => [
    for (final e in errors) {'path': e.path, 'code': e.code.name},
  ];
  return {
    'errors': pairs(validateLinks(model, doc)),
    'instanceErrors': pairs(validateDocument(model, doc)),
  };
}

/// The paths of the base Blueprint.
const _req = 'BLU/requirements';
const _reqList = '$_req/REQ-ITEM-LST';
const _ra = '$_reqList-1';
const _rb = '$_reqList-2';
const _rc = '$_reqList-3';
const _holder = 'BLU/acceptance/criteria/CRIT-ITEM-LST';
const _copy = 'BLU/criteriaSummary/criteria/CRIT-ITEM-LST';

/// The base Blueprint of the link validation cases: every link of the fixture
/// holds. Three requirements (`REQ-EXPORT`, `REQ-IMPORT`, `REQ-PURGE`) with
/// their link rows, revisions, a key requirement, the full-list summary, the
/// acceptance criteria and their `@SameAs` copy, and two cross-document
/// references (a screen overview row, the focus screens) that `validateLinks`
/// leaves to the document set.
SpecDocument _baseBlueprint() {
  final d = SpecDocument();
  void form(String path, Map<String, String> values) =>
      values.forEach((k, v) => d.setFormField(path, k, v));
  String row(String list, String type, String ref, [String? id]) {
    final r = d.addListItem(list, sectionId: id);
    form('$r/content', {'linkType': type});
    form('$r/LNK-REF', {'ref': ref});
    return r;
  }

  form('$_req/REQS-SUM', {
    'total': '3',
    'settled': '2',
    'allRequirements': 'REQ-EXPORT, REQ-IMPORT, REQ-PURGE',
  });
  for (final (id, title, status, version) in [
    ('REQ-EXPORT', 'Export presets', 'approved', '1.1'),
    ('REQ-IMPORT', 'Import', 'done', '1.0'),
    ('REQ-PURGE', 'Purge', 'draft', '0.9'),
  ]) {
    final item = d.addListItem(_reqList, sectionId: id);
    d.setHeadline(item, title);
    form('$item/content', {'status': status, 'lastVersion': version});
  }
  // REQ-EXPORT names REQ-IMPORT (its generated row) and REQ-PURGE, which it
  // has a conflict row for: an id with a row of another type is a reference
  // and not reported (DP-part-cleanup-7).
  const exportText =
      'Exports use the formats of REQ-IMPORT and never run with REQ-PURGE.';
  form('$_ra/content', {'owner': 'ana', 'weight': '2'});
  form('$_ra/REQD', {'description': exportText});
  d.setContent('$_ra/REQAB', exportText);
  form('$_ra/REQC', {'conflictsWith': 'REQ-PURGE'});
  form('$_ra/REQT', {
    'relatedScreens': 'SCRN-LOGIN',
    'relatedCriteria': 'CRIT-SPEED',
  });
  row('$_ra/LNK-ITEM-LST', 'namedInText', 'REQ-IMPORT');
  row('$_ra/LNK-ITEM-LST', 'conflict', 'REQ-PURGE');

  form('$_rb/REQD', {'description': 'Imports files.'});
  d.setContent('$_rb/REQAB', 'Imports files.');
  form('$_rb/REQC', {'constraints': 'Bounded by REQ-PURGE.'});
  row('$_rb/LNK-ITEM-LST', 'constrainedBy', 'REQ-PURGE');

  form('$_rc/REQD', {'description': 'Purges old data.'});
  d.setContent('$_rc/REQAB', 'Purges old data.');
  form('$_rc/REQC', {'conflictsWith': 'REQ-EXPORT'});
  row('$_rc/LNK-ITEM-LST', 'conflict', 'REQ-EXPORT');
  row('$_rc/LNK-ITEM-LST', 'prerequisite', 'REQ-IMPORT');
  final pre = d.addListItem('$_rc/PRE-ITEM-LST');
  form('$pre/content', {'ref': 'REQ-IMPORT'});

  for (final (ref, version) in [
    ('REQ-EXPORT', '1.1'),
    ('REQ-IMPORT', '1.0'),
    ('REQ-PURGE', '0.9'),
  ]) {
    final r = d.addListItem('BLU/REV-ITEM-LST');
    form('$r/content', {'requirementRef': ref, 'version': version});
  }
  final key = d.addListItem('$_req/keyRequirements/KEY-ITEM-LST');
  form('$key/content', {
    'requirementRef': 'REQ-EXPORT',
    'title': 'Export presets',
  });

  form('BLU/acceptance/content', {'owner': 'quality team'});
  d.setContent('BLU/criteriaSummary/content', 'The criteria at a glance.');
  for (final list in [_holder, _copy]) {
    for (final (id, kind, text, refs) in [
      ('CRIT-SPEED', 'functional', 'Exports finish in 5 s.', 'REQ-EXPORT'),
      ('CRIT-AUDIT', 'quality', 'Every purge is logged.', ''),
    ]) {
      final c = d.addListItem(list, sectionId: id);
      form('$c/content', {
        'kind': kind,
        'text': text,
        if (refs.isNotEmpty) 'relatedRequirements': refs,
      });
    }
  }
  final ovr = d.addListItem('BLU/screenOverview/OVR-ITEM-LST');
  form('$ovr/content', {'screenRef': 'SCRN-LOGIN'});
  form('BLU/FOC', {'focusScreens': 'SCRN-LOGIN'});
  return d;
}

/// The table `link_validation_cases.json`, its expectations computed live.
Map<String, Object?> buildLinkValidationCases(Map<String, dynamic> meta) {
  final model = SpecModel.fromJson(meta);
  Map<String, Object?> kase(
    String name,
    List<String> intent, [
    void Function(SpecDocument d)? edit,
  ]) {
    final d = _baseBlueprint();
    edit?.call(d);
    final state = d.toJson();
    return {
      'name': name,
      'intent': intent,
      'state': state,
      ...linkValidationCase(model, state),
    };
  }

  return {
    'model': 'links.meta.json',
    'cases': [
      kase(
        'a clean Blueprint: every link holds; an id with a row of another '
        'type, a summary of another document and an end whose registry the '
        'document does not hold are not reported',
        ['clean'],
      ),
      kase('a derived value not written yet is not reported', [
        'clean',
      ], (d) => d.setContent('$_ra/REQAB', '')),
      kase('a copy differing from its source', [
        'derivedValueMismatch',
      ], (d) => d.setContent('$_ra/REQAB', 'Exports use other formats.')),
      kase('collected rows differing from the field', [
        'derivedValueMismatch',
      ], (d) => d.setFormField('$_ra/REQC', 'conflictsWith', 'REQ-IMPORT')),
      kase('a looked-up value differing', [
        'derivedValueMismatch',
      ], (d) => d.setFormField('$_ra/content', 'lastVersion', '1.0')),
      kase(
        'a derived list differing from its rows',
        ['derivedValueMismatch'],
        (d) =>
            d.setFormField('$_rc/PRE-ITEM-LST-1/content', 'ref', 'REQ-EXPORT'),
      ),
      kase(
        'a summary row repeating a value its detail element does not hold',
        ['derivedValueMismatch'],
        (d) => d.setFormField(
          '$_req/keyRequirements/KEY-ITEM-LST-1/content',
          'title',
          'Presets',
        ),
      ),
      kase('a lookup finding no row', [
        'derivedLookupMiss',
      ], (d) => d.removeListItem('BLU/REV-ITEM-LST-3')),
      kase('a lookup finding two rows', ['derivedLookupMiss'], (d) {
        final r = d.addListItem('BLU/REV-ITEM-LST');
        d.setFormField('$r/content', 'requirementRef', 'REQ-EXPORT');
        d.setFormField('$r/content', 'version', '1.2');
      }),
      kase('a link row twice', ['duplicateLinkRow'], (d) {
        final r = d.addListItem('$_ra/LNK-ITEM-LST');
        d.setFormField('$r/content', 'linkType', 'namedInText');
        d.setFormField('$r/LNK-REF', 'ref', 'REQ-IMPORT');
      }),
      kase('a symmetric row without its counterpart', ['inverseMissing'], (d) {
        d.removeListItem('$_rc/LNK-ITEM-LST-1');
        d.setFormField('$_rc/REQC', 'conflictsWith', '');
      }),
      kase('a one-way link not named back', ['inverseMissing'], (d) {
        for (final list in [_holder, _copy]) {
          d.setFormField('$list-1/content', 'relatedRequirements', '');
        }
      }),
      kase(
        'an id named in a generate-mode text without a row',
        ['extractedLinkMissing'],
        (d) => d.setFormField(
          '$_rb/REQD',
          'description',
          'Imports files for REQ-EXPORT.',
        ),
      ),
      kase(
        'an id named in a warn-mode text without a row',
        ['extractedLinkMissing'],
        (d) => d.setFormField(
          '$_rb/REQC',
          'constraints',
          'Bounded by REQ-PURGE and REQ-EXPORT.',
        ),
      ),
      kase('a generated row the text no longer names', ['extractedLinkStale'], (
        d,
      ) {
        const text = 'Exports never run with REQ-PURGE.';
        d.setFormField('$_ra/REQD', 'description', text);
        d.setContent('$_ra/REQAB', text);
      }),
      kase(
        'a summary row naming no element of the detail list',
        ['summaryNotInDetail'],
        (d) => d.setFormField(
          '$_req/keyRequirements/KEY-ITEM-LST-1/content',
          'requirementRef',
          'REQ-GONE',
        ),
      ),
      kase(
        'a summary field naming no element of the detail list',
        ['summaryNotInDetail'],
        (d) => d.setFormField(
          '$_req/REQS-SUM',
          'allRequirements',
          'REQ-EXPORT, REQ-IMPORT, REQ-PURGE, REQ-GONE',
        ),
      ),
      kase('two summary rows naming one element', ['summaryDuplicate'], (d) {
        final k = d.addListItem('$_req/keyRequirements/KEY-ITEM-LST');
        d.setFormField('$k/content', 'requirementRef', 'REQ-EXPORT');
        d.setFormField('$k/content', 'title', 'Export presets');
      }),
      kase(
        'an element missing from an equal summary',
        ['detailNotInSummary'],
        (d) => d.setFormField(
          '$_req/REQS-SUM',
          'allRequirements',
          'REQ-EXPORT, REQ-IMPORT',
        ),
      ),
      kase(
        'a copy edited apart from its holder',
        ['sameAsMismatch'],
        (d) => d.setFormField('$_copy-2/content', 'text', 'Purges are logged.'),
      ),
      kase('a copy missing an element of its holder', [
        'sameAsMismatch',
      ], (d) => d.removeListItem('$_copy-2')),
      kase('a count over alternatives drifting (the instance tier)', [
        'countMismatch',
      ], (d) => d.setFormField('$_req/REQS-SUM', 'settled', '3')),
      kase(
        'a source holding a pending change, read with the mark rejected',
        ['linkValuePending'],
        (d) => d.setFormField(
          '$_ra/REQD',
          'description',
          'Exports use the formats of REQ-IMPORT and never run with '
              '{~~REQ-PURGE~>nothing~~}.',
        ),
      ),
    ],
  };
}

// ---------------------------------------------------------------------------
// The table `derive_cases.json`
// ---------------------------------------------------------------------------

/// One derive case: `deriveFields` run twice on the case's document (the
/// second run shows idempotence), each as its result, then the findings of
/// both tiers on the document after it, and the given document after both
/// runs (unchanged on a dry run).
Map<String, Object?> deriveCase(SpecModel model, Map<String, dynamic> c) {
  final doc = SpecDocument()..loadJson(c['state'] as Map);
  SpecDeriveResult run() => deriveFields(
    model,
    doc,
    marked: c['marked'] as bool? ?? true,
    author: c['author'] as String?,
    at: c['at'] as String?,
    dryRun: c['dryRun'] as bool? ?? false,
  );
  final first = run();
  final second = run();
  List<Map<String, String>> pairs(List<SpecValidationError> errors) => [
    for (final e in errors) {'path': e.path, 'code': e.code.name},
  ];
  return {
    'first': first.toJson(),
    'second': second.toJson(),
    'findingsAfter': pairs([
      ...validateLinks(model, second.document),
      ...validateDocument(model, second.document),
    ]),
    'given': doc.toJson(),
  };
}

/// The table `derive_cases.json`, its expectations computed live.
Map<String, Object?> buildDeriveCases(Map<String, dynamic> meta) {
  final model = SpecModel.fromJson(meta);
  const author = 'agent_spec_author';
  const at = '2026-11-24T10:00+01:00';

  Map<String, Object?> kase(
    String name,
    List<String> intent,
    void Function(SpecDocument d)? edit, {
    bool marked = false,
    bool dryRun = false,
  }) {
    final d = _baseBlueprint();
    edit?.call(d);
    final c = <String, dynamic>{
      'name': name,
      'intent': intent,
      'marked': marked,
      if (marked) 'author': author,
      if (marked) 'at': at,
      if (dryRun) 'dryRun': true,
      'state': d.toJson(),
    };
    return {...c, 'expect': deriveCase(model, jsonDecode(jsonEncode(c)))};
  }

  void clearDerived(SpecDocument d) {
    d.setContent('$_ra/REQAB', '');
    d.setFormField('$_ra/REQC', 'conflictsWith', '');
    d.setFormField('$_ra/content', 'lastVersion', '');
    d.setFormField('$_req/keyRequirements/KEY-ITEM-LST-1/content', 'title', '');
    d.removeListItem('$_rc/PRE-ITEM-LST-1');
    d.setFormField('$_copy-1/content', 'text', 'An old copy.');
    d.removeListItem('$_copy-2');
    // An element only the copy holds goes.
    final extra = d.addListItem(_copy, sectionId: 'CRIT-EXTRA');
    d.setFormField('$extra/content', 'text', 'Not in the holder.');
  }

  void scores(SpecDocument d) {
    for (final (item, weight, effort) in [
      (_ra, '2', '3'),
      (_rb, '1.5', '2'),
      (_rc, '4', '1'),
    ]) {
      d.setFormField('$item/content', 'weight', weight);
      d.setFormField('$item/content', 'effort', effort);
    }
  }

  return {
    'model': 'links.meta.json',
    'cases': [
      kase(
        'a document whose derived places hold: nothing is written, and the '
        'end whose registry the document does not hold is not written',
        ['nothing', 'clean'],
        null,
      ),
      kase(
        'step 1: a missing symmetric row restored, step 2 deriving from it',
        ['step1', 'rowAdded', 'step2', 'clean', 'idempotent'],
        (d) {
          d.removeListItem('$_rc/LNK-ITEM-LST-1');
          d.setFormField('$_rc/REQC', 'conflictsWith', '');
        },
      ),
      kase(
        'step 1: a one-way end written back, step 2 copying it into the '
        '@SameAs copy',
        ['step1', 'step2', 'clean', 'idempotent'],
        (d) {
          for (final list in [_holder, _copy]) {
            d.setFormField('$list-1/content', 'relatedRequirements', '');
          }
        },
      ),
      kase(
        'step 1: a row added for an id named in a generate-mode text',
        ['step1', 'rowAdded', 'clean', 'idempotent'],
        (d) => d.setFormField(
          '$_rb/REQD',
          'description',
          'Imports files for REQ-EXPORT.',
        ),
      ),
      kase(
        'step 1: a stale generated row removed, step 2 re-deriving the copy '
        'of the text',
        ['step1', 'rowRemoved', 'step2', 'clean', 'idempotent'],
        (d) => d.setFormField(
          '$_ra/REQD',
          'description',
          'Exports never run with REQ-PURGE.',
        ),
      ),
      kase('a link row left with no value is removed', [
        'rowRemoved',
        'clean',
        'idempotent',
      ], (d) => d.addListItem('$_ra/LNK-ITEM-LST')),
      kase(
        'step 2: a copy, collected rows, a lookup, a derived list, a repeated '
        'value and a @SameAs copy written',
        ['step2', 'rowAdded', 'rowRemoved', 'clean', 'idempotent'],
        clearDerived,
      ),
      kase(
        'step 3: counts, products and ranks written',
        ['step3', 'clean', 'idempotent'],
        (d) {
          scores(d);
          d.setFormField('$_req/REQS-SUM', 'total', '');
          d.setFormField('$_req/REQS-SUM', 'settled', '3');
        },
      ),
      kase('a lookup without its row is left unresolved', [
        'derivedLookupMiss',
      ], (d) => d.removeListItem('BLU/REV-ITEM-LST-3')),
      kase(
        'a dry run writes nothing and answers the same changes',
        ['step2', 'unchanged'],
        clearDerived,
        dryRun: true,
      ),
      kase(
        'under review: every derived value written as marks, typed values '
        'and the copy included; a second run writes nothing',
        ['marked', 'step2', 'rowAdded', 'idempotent'],
        clearDerived,
        marked: true,
      ),
      kase(
        'under review: counts, products and ranks as typed marks',
        ['marked', 'step3', 'idempotent'],
        (d) {
          scores(d);
          d.setFormField('$_req/REQS-SUM', 'settled', '3');
        },
        marked: true,
      ),
      kase(
        'under review: a stale row proposed for deletion, not removed',
        ['marked', 'rowRemoved', 'idempotent'],
        (d) {
          const text = 'Exports never run with REQ-PURGE.';
          d.setFormField('$_ra/REQD', 'description', text);
          d.setContent('$_ra/REQAB', text);
        },
        marked: true,
      ),
      kase(
        'under review: a change inside fenced code cannot be marked and is '
        'left unmarkable',
        ['unmarkable'],
        (d) {
          const text = 'Exports run:\n\n```\nexport --all\n```';
          d.setFormField('$_ra/REQD', 'description', text);
          d.setContent('$_ra/REQAB', 'Exports run:\n\n```\nexport --some\n```');
        },
        marked: true,
      ),
    ],
  };
}

/// Whether the derive-case intent [token] holds in [e].
bool _deriveIntentHolds(String token, Map<String, dynamic> c) {
  final e = c['expect'] as Map<String, dynamic>;
  final first = e['first'] as Map<String, dynamic>;
  final second = e['second'] as Map<String, dynamic>;
  final changes = (first['changes'] as List).cast<Map<String, dynamic>>();
  bool unresolved(String code) =>
      (first['unresolved'] as List).any((u) => (u as Map)['code'] == code);
  return switch (token) {
    'nothing' => changes.isEmpty,
    'step1' => changes.any((x) => x['step'] == 1),
    'step2' => changes.any((x) => x['step'] == 2),
    'step3' => changes.any((x) => x['step'] == 3),
    'rowAdded' => changes.any((x) => x['kind'] == 'rowAdded'),
    'rowRemoved' => changes.any((x) => x['kind'] == 'rowRemoved'),
    'marked' => changes.any((x) => (x['new'] as String).contains('{')),
    'clean' => (e['findingsAfter'] as List).isEmpty,
    'idempotent' =>
      (second['changes'] as List).isEmpty &&
          jsonEncode(second['document']) == jsonEncode(first['document']),
    'unchanged' => jsonEncode(e['given']) == jsonEncode(c['state']),
    'unmarkable' => unresolved('unmarkable'),
    'derivedLookupMiss' => unresolved('derivedLookupMiss'),
    _ => throw StateError('unknown intent token "$token"'),
  };
}

// ---------------------------------------------------------------------------
// The table `document_set_cases.json`
// ---------------------------------------------------------------------------

/// [into] gains every value of [from] beneath [src], moved beneath [dst].
void _copyTree(SpecDocument from, String src, SpecDocument into, String dst) {
  String move(String path) => path == src
      ? dst
      : path.startsWith('$src/')
      ? '$dst${path.substring(src.length)}'
      : path;
  bool under(String path) => path == src || path.startsWith('$src/');
  final a = from.toJson();
  final b = into.toJson();
  for (final store in ['content', 'forms', 'headlines']) {
    final target = <String, Object?>{
      ...?(b[store] as Map?)?.cast<String, Object?>(),
    };
    (a[store] as Map? ?? {}).forEach((k, v) {
      if (under(k as String)) target[move(k)] = v;
    });
    if (target.isNotEmpty) b[store] = target;
  }
  final lists = <String, Object?>{
    ...?(b['lists'] as Map?)?.cast<String, Object?>(),
  };
  (a['lists'] as Map? ?? {}).forEach((k, v) {
    if (!under(k as String)) return;
    final l = v as Map;
    lists[move(k)] = {
      'seq': l['seq'],
      'items': [for (final i in l['items'] as List) move(i as String)],
      if (l['ids'] != null)
        'ids': {
          for (final e in (l['ids'] as Map).entries)
            move(e.key as String): e.value,
        },
    };
  });
  if (lists.isNotEmpty) b['lists'] = lists;
  into.loadJson(b);
}

/// The base set: the Blueprint of the validation table, the Detail
/// document holding its requirements and criteria, and the Screens document
/// holding the one screen the Blueprint names and the acceptance. Every
/// shared place agrees; the places only Detail and Screens carry
/// (`detailOnly`) differ, and are not compared.
Map<String, SpecDocument> _baseSet() {
  final blu = _baseBlueprint();
  final det = SpecDocument();
  _copyTree(blu, 'BLU/requirements', det, 'DET/requirements');
  _copyTree(blu, 'BLU/acceptance/criteria', det, 'DET/criteria');
  // Only Detail carries a requirement's rationale (detailOnly REQX).
  det.setFormField(
    'DET/requirements/REQ-ITEM-LST-1/REQX',
    'rationale',
    'Presets save the export settings once.',
  );
  final scr = SpecDocument();
  final screen = scr.addListItem('SCR/SCRN-ITEM-LST', sectionId: 'SCRN-LOGIN');
  scr.setHeadline(screen, 'Login');
  scr.setFormField('$screen/content', 'purpose', 'Sign in.');
  scr.setFormField('$screen/content', 'relatedRequirements', 'REQ-EXPORT');
  scr.setFormField('SCR/acceptance/content', 'owner', 'quality team');
  // The criteria under the Screens' acceptance are detailOnly there.
  final c = scr.addListItem(
    'SCR/acceptance/criteria/CRIT-ITEM-LST',
    sectionId: 'CRIT-UX',
  );
  scr.setFormField('$c/content', 'text', 'Every screen is reachable by key.');
  return {'blueprint': blu, 'detail': det, 'screens': scr};
}

/// The canonical form of a set's documents: `[[name, state], …]`.
List<Object?> _documentsJson(Map<String, SpecDocument> docs) => [
  for (final e in docs.entries) [e.key, e.value.toJson()],
];

Map<String, SpecDocument> _documentsFrom(List<dynamic> json) => {
  for (final e in json)
    (e as List)[0] as String: SpecDocument()..loadJson(e[1] as Map),
};

/// One construction case: the set built (from fragments when [fragments]),
/// answered as its pairs and roots, or the refusal.
Map<String, Object?> setConstructionCase(
  SpecModel model,
  Map<String, dynamic> c,
) {
  final docs = _documentsFrom(c['documents'] as List);
  try {
    final set = c['fragments'] == true
        ? SpecDocumentSet.fromFragments(model, docs)
        : SpecDocumentSet(model, docs);
    return {
      'blueprintRoot': set.blueprintRoot,
      'names': set.names,
      'roots': set.roots.toList(),
      'missingRoots': set.missingRoots,
      'pairs': [for (final p in set.pairs) p.toJson()],
    };
  } on SpecDocumentSetError catch (e) {
    return {'refused': e.toJson()};
  }
}

/// One report case: `syncReport` over the documents, optionally scoped.
Map<String, Object?> setReportCase(SpecModel model, Map<String, dynamic> c) {
  final set = SpecDocumentSet(model, _documentsFrom(c['documents'] as List));
  final pairs = (c['pairs'] as List?)?.cast<String>().toSet();
  return syncReport(set, pairs: pairs).toJson();
}

/// One rename case: `renameId`, answered as its changes and the report after
/// it, or the documents that refused it.
Map<String, Object?> setRenameCase(SpecModel model, Map<String, dynamic> c) {
  final set = SpecDocumentSet(model, _documentsFrom(c['documents'] as List));
  try {
    final changes = renameId(set, c['from'] as String, c['to'] as String);
    final after = syncReport(set);
    return {
      'changes': [for (final x in changes) x.toJson()],
      'cleanAfter': after.clean,
      'findingsAfter': after.findings.where((f) => !f.isInfo).length,
    };
  } on SpecRenameError catch (e) {
    return {'refused': e.documents};
  }
}

/// A small inline model whose synced class is reached twice in the
/// Blueprint and once in its document: the positions cannot be paired.
Map<String, dynamic> _unpairableMeta() => {
  'metaSchemaVersion': 1,
  'modelVersion': 1,
  'modelVersionLabel': 'links-unpairable-1.0',
  'generatedAt': '2026-11-24T08:00:00.000000Z',
  'classCount': 3,
  'rootCount': 2,
  'roots': [
    {'type': 'Mini', 'title': 'Mini', 'sectionId': 'MINI'},
    {'type': 'MiniDetail', 'title': 'Mini Detail', 'sectionId': 'MDET'},
  ],
  'classes': {
    'Mini': _cls(
      'Mini',
      'MINI',
      [_complex('first', 'Part'), _complex('second', 'Part')],
      annotations: [
        _a('Document', {'name': 'Mini', 'description': 'two positions'}),
      ],
    ),
    'MiniDetail': _cls(
      'MiniDetail',
      'MDET',
      [_complex('part', 'Part')],
      annotations: [
        _a('Document', {
          'name': 'Mini Detail',
          'description': 'one position',
          'basedOn': ['Mini'],
        }),
      ],
    ),
    'Part': _cls(
      'Part',
      'PART',
      [
        _form('content', null, [_ff('note', 'String')]),
      ],
      annotations: [
        _a('DetailedIn', {'target': 'MiniDetail'}),
        _a('SyncedWith', {
          'document': 'MiniDetail',
          'detailOnly': <String>[],
          'heldHere': <String>[],
          'relations': <Object?>[],
        }),
      ],
    ),
  },
};

const _det = 'DET/requirements/REQ-ITEM-LST';

/// The table `document_set_cases.json`, its expectations computed live.
Map<String, Object?> buildDocumentSetCases(Map<String, dynamic> meta) {
  final model = SpecModel.fromJson(meta);

  Map<String, Object?> construct(
    String name,
    List<String> intent,
    Map<String, SpecDocument> docs, {
    bool fragments = false,
    Map<String, dynamic>? inline,
  }) {
    final c = <String, dynamic>{
      'name': name,
      'intent': intent,
      if (inline != null) 'meta': inline,
      if (fragments) 'fragments': true,
      'documents': _documentsJson(docs),
    };
    final m = inline == null ? model : SpecModel.fromJson(inline);
    return {...c, 'expect': setConstructionCase(m, jsonDecode(jsonEncode(c)))};
  }

  Map<String, Object?> report(
    String name,
    List<String> intent,
    void Function(Map<String, SpecDocument> docs)? edit, {
    List<String>? pairs,
  }) {
    final docs = _baseSet();
    edit?.call(docs);
    final c = <String, dynamic>{
      'name': name,
      'intent': intent,
      if (pairs != null) 'pairs': pairs,
      'documents': _documentsJson(docs),
    };
    return {...c, 'expect': setReportCase(model, jsonDecode(jsonEncode(c)))};
  }

  Map<String, Object?> rename(
    String name,
    List<String> intent,
    String from,
    String to,
  ) {
    final c = <String, dynamic>{
      'name': name,
      'intent': intent,
      'from': from,
      'to': to,
      'documents': _documentsJson(_baseSet()),
    };
    return {...c, 'expect': setRenameCase(model, jsonDecode(jsonEncode(c)))};
  }

  final base = _baseSet();
  SpecDocument part(SpecDocument d, String keep) {
    final j = d.toJson();
    bool k(String p) => p == keep || p.startsWith('$keep/');
    for (final store in ['content', 'forms', 'headlines']) {
      (j[store] as Map?)?.removeWhere((key, _) => !k(key as String));
    }
    (j['lists'] as Map?)?.removeWhere((key, _) => !k(key as String));
    return SpecDocument()..loadJson(j);
  }

  final projection = SpecDocument()
    ..setFormField('PRJ/requirements/REQS-SUM', 'total', '0');
  final twoRoots = _baseBlueprint()
    ..setFormField('DET/requirements/REQS-SUM', 'total', '0');
  final overlapA = part(_baseBlueprint(), 'BLU/requirements');
  final overlapB = part(_baseBlueprint(), 'BLU/requirements');
  final mini = SpecDocument()..setFormField('MINI/first/content', 'note', 'a');

  return {
    'model': 'links.meta.json',
    'construction': [
      construct('the base set: three documents, the pairs computed', [
        'built',
      ], base),
      construct(
        'without the Screens document: its root is missing, not a finding',
        ['missingRoots'],
        {'blueprint': base['blueprint']!, 'detail': base['detail']!},
      ),
      construct(
        'fragments of one root assembled into one document',
        ['built'],
        {
          'blueprint-requirements': part(_baseBlueprint(), 'BLU/requirements'),
          'blueprint-acceptance': part(_baseBlueprint(), 'BLU/acceptance'),
          'detail': base['detail']!,
        },
        fragments: true,
      ),
      construct(
        'two documents of one root',
        ['sameRoot'],
        {'a': _baseBlueprint(), 'b': _baseBlueprint()},
      ),
      construct(
        'a document with no root',
        ['noRoot'],
        {'blueprint': base['blueprint']!, 'empty': SpecDocument()},
      ),
      construct('a document with two roots', ['twoRoots'], {'both': twoRoots}),
      construct(
        'the CodeSpecs projection',
        ['projection'],
        {'blueprint': base['blueprint']!, 'projection': projection},
      ),
      construct(
        'fragments of one root that overlap',
        ['overlap'],
        {'one': overlapA, 'two': overlapB},
        fragments: true,
      ),
      construct(
        'a synced class whose positions cannot be paired',
        ['unpairable'],
        {'mini': mini},
        inline: _unpairableMeta(),
      ),
    ],
    'reports': [
      report(
        'the base set agrees: detailOnly places, derived places and the '
        '@SameAs copy are not compared',
        ['clean'],
        null,
      ),
      report('an enum value differs', [
        'sharedValueDiffers',
      ], (d) => d['detail']!.setFormField('$_det-1/content', 'status', 'done')),
      report(
        'a value the Blueprint holds (heldHere) differs: the agent corrects '
        'the Phase 3 document',
        ['sharedValueDiffers', 'agent'],
        (d) => d['detail']!.setFormField('$_det-1/content', 'owner', 'bo'),
      ),
      report('a value the Blueprint leaves empty', [
        'sharedValueMissing',
      ], (d) => d['blueprint']!.setFormField('$_rb/REQD', 'description', '')),
      report('a value the Phase 3 document emptied', [
        'sharedValueOnlyInBlueprint',
      ], (d) => d['detail']!.setFormField('$_det-3/REQD', 'description', '')),
      report(
        'an element only in the Phase 3 document (equal), its counts and '
        'summary moving in its own findings',
        ['sharedElementMissing', 'countMismatch', 'detailNotInSummary'],
        (d) {
          final x = d['detail']!.addListItem(
            'DET/requirements/REQ-ITEM-LST',
            sectionId: 'REQ-PRESETS',
          );
          d['detail']!.setFormField('$x/content', 'status', 'draft');
        },
      ),
      report(
        'an element only in the Blueprint (equal)',
        ['sharedElementOnlyInBlueprint'],
        (d) {
          final k = d['blueprint']!.addListItem(
            '$_req/keyRequirements/KEY-ITEM-LST',
          );
          d['blueprint']!.setFormField(
            '$k/content',
            'requirementRef',
            'REQ-IMPORT',
          );
          d['blueprint']!.setFormField('$k/content', 'title', 'Import');
        },
      ),
      report(
        'under subset, a matching element only in the Phase 3 document may '
        'be added; the report stays clean',
        ['sharedElementMayBeAdded', 'clean'],
        (d) {
          final c = d['detail']!.addListItem(
            'DET/criteria/CRIT-ITEM-LST',
            sectionId: 'CRIT-NEW',
          );
          d['detail']!.setFormField('$c/content', 'kind', 'quality');
        },
      ),
      report(
        'under subset with where, an element outside the filter is held to '
        'equal',
        ['sharedElementMissing'],
        (d) {
          final c = d['detail']!.addListItem(
            'DET/criteria/CRIT-ITEM-LST',
            sectionId: 'CRIT-LEGAL',
          );
          d['detail']!.setFormField('$c/content', 'kind', 'legal');
        },
      ),
      report(
        'a subset reference field naming one more screen in the Phase 3 '
        'document',
        ['sharedElementMayBeAdded'],
        (d) => d['detail']!.setFormField(
          '$_det-1/REQT',
          'relatedScreens',
          'SCRN-LOGIN, SCRN-HOME',
        ),
      ),
      report(
        'a subset reference field naming a screen only in the Blueprint',
        ['sharedElementOnlyInBlueprint'],
        (d) => d['blueprint']!.setFormField(
          '$_ra/REQT',
          'relatedScreens',
          'SCRN-LOGIN, SCRN-OLD',
        ),
      ),
      report(
        'a summary of another document leaving out an element (equal)',
        ['crossSummaryMismatch'],
        (d) {
          final x = d['screens']!.addListItem(
            'SCR/SCRN-ITEM-LST',
            sectionId: 'SCRN-HOME',
          );
          d['screens']!.setFormField('$x/content', 'purpose', 'Start.');
        },
      ),
      report(
        'a summary field naming no element of the other document',
        ['crossSummaryMismatch'],
        (d) => d['blueprint']!.setFormField(
          'BLU/FOC',
          'focusScreens',
          'SCRN-LOGIN, SCRN-GONE',
        ),
      ),
      report(
        'a link across two documents not named back',
        ['crossInverseMissing'],
        (d) => d['screens']!.setFormField(
          'SCR/SCRN-ITEM-LST-1/content',
          'relatedRequirements',
          '',
        ),
      ),
      report(
        'a value holding a pending change is listed; the report stays clean',
        ['pendingReview', 'clean'],
        (d) => d['detail']!.setFormField(
          '$_det-2/REQD',
          'description',
          'Imports {++all ++}files.',
        ),
      ),
      report(
        'the comparison rules: text trimmed, 2 and 2.0 in a double, list '
        'order ignored',
        ['clean'],
        (d) {
          final det = d['detail']!;
          det.setFormField('$_det-2/REQD', 'description', '  Imports files. ');
          det.setFormField('$_det-1/content', 'weight', '2.0');
          // The criteria in the other order.
          final j = det.toJson();
          final lists = j['lists'] as Map;
          final crit = lists['DET/criteria/CRIT-ITEM-LST'] as Map;
          crit['items'] = (crit['items'] as List).reversed.toList();
          det.loadJson(j);
        },
      ),
      report('a document not started yet', [
        'notStarted',
      ], (d) => d.remove('screens')),
      report(
        'scoped to one pair, a finding of another pair is left out',
        ['clean'],
        (d) => d['detail']!.setFormField('$_det-1/content', 'status', 'done'),
        pairs: ['CRIT'],
      ),
      report(
        'scoped to its own pair, the finding is reported',
        ['sharedValueDiffers'],
        (d) => d['detail']!.setFormField('$_det-1/content', 'status', 'done'),
        pairs: ['REQS'],
      ),
      report(
        'a derived change that cannot be marked is left for the agent',
        ['unmarkable', 'agent'],
        (d) {
          const text = 'Exports run:\n\n```\nexport --all\n```';
          const stale = 'Exports run:\n\n```\nexport --some\n```';
          for (final (doc, item) in [
            (d['blueprint']!, _ra),
            (d['detail']!, '$_det-1'),
          ]) {
            doc.setFormField('$item/REQD', 'description', text);
            doc.setContent('$item/REQAB', stale);
          }
        },
      ),
      report(
        'findings of several pairs, in pair order',
        ['sharedValueDiffers', 'sharedElementMissing'],
        (d) {
          final c = d['detail']!.addListItem(
            'DET/criteria/CRIT-ITEM-LST',
            sectionId: 'CRIT-LEGAL',
          );
          d['detail']!.setFormField('$c/content', 'kind', 'legal');
          d['detail']!.setFormField('$_det-1/content', 'status', 'done');
        },
      ),
    ],
    'renames': [
      rename(
        'an id renamed in every document at once',
        ['renamed'],
        'REQ-IMPORT',
        'REQ-INGEST',
      ),
      rename(
        'a rename onto an id that exists is refused',
        ['refused'],
        'REQ-IMPORT',
        'REQ-PURGE',
      ),
    ],
  };
}

/// Every token a set case's expectation shows, for its intent.
Set<String> _setTokens(Map<String, dynamic> e) {
  final out = <String>{};
  if (e['refused'] is Map) out.add((e['refused'] as Map)['refusal'] as String);
  if (e['refused'] is List) out.add('refused');
  if (e['pairs'] != null && e['refused'] == null) {
    out.add('built');
    if ((e['missingRoots'] as List).isNotEmpty) out.add('missingRoots');
  }
  if (e['findings'] != null) {
    if (e['clean'] == true) out.add('clean');
    if ((e['notStarted'] as List).isNotEmpty) out.add('notStarted');
    for (final f in (e['findings'] as List).cast<Map<String, dynamic>>()) {
      out
        ..add(f['code'] as String)
        ..add(f['resolution'] as String);
    }
    for (final d in e['documentFindings'] as List) {
      for (final x in (d as List)[1] as List) {
        out.add((x as Map)['code'] as String);
      }
    }
  }
  if (e['changes'] != null && (e['changes'] as List).isNotEmpty) {
    out.add('renamed');
  }
  return out;
}

// ---------------------------------------------------------------------------
// The fixture model `links.meta.json` (part-conformance, section 1)
// ---------------------------------------------------------------------------

/// The link fixture model: a Blueprint (`BLU`), two Phase 3 roots based on it
/// (`DET`, `SCR`) and a projection root (`PRJ`), holding each construct of the
/// link vocabulary once, in the meta shapes of part-meta.
Map<String, dynamic> buildLinksMeta() {
  final classes = <String, dynamic>{
    'Blueprint': _cls(
      'Blueprint',
      'BLU',
      [
        _complex('requirements', 'Requirements'),
        _complex('acceptance', 'Acceptance'),
        _complex('criteriaSummary', 'CriteriaSummary'),
        _complex('screenOverview', 'ScreenOverview'),
        _form('focus', 'FOC', [
          _ff('focusScreens', 'String', {
            'refersTo': ['SCRN.@sectionId'],
            'multiple': true,
            'summaryOf': {
              'detail': 'SCRN-ITEM-LST',
              'document': 'Screens',
              'relation': 'subset',
              'repeats': <String, String>{},
            },
          }),
        ]),
        _list('revisions', 'REV-ITEM-LST', 'REV-xxx', 'Revision'),
      ],
      annotations: [
        _a('Document', {
          'name': 'Blueprint',
          'description': 'The overview every other document starts from.',
        }),
      ],
    ),
    'Detail': _cls(
      'Detail',
      'DET',
      [
        _complex('requirements', 'Requirements'),
        _complex('criteria', 'Criteria'),
      ],
      annotations: [
        _a('Document', {
          'name': 'Detail',
          'description': 'The requirements in detail (the RSP role).',
          'basedOn': ['Blueprint'],
        }),
      ],
    ),
    'Screens': _cls(
      'Screens',
      'SCR',
      [
        _list('screens', 'SCRN-ITEM-LST', 'SCRN-xxx', 'Screen'),
        _complex('acceptance', 'Acceptance'),
      ],
      annotations: [
        _a('Document', {
          'name': 'Screens',
          'description': 'The screens in detail (the XDS role).',
          'basedOn': ['Blueprint'],
        }),
      ],
    ),
    'Projection': _cls(
      'Projection',
      'PRJ',
      [_complex('requirements', 'Requirements')],
      annotations: [
        _a('Document', {
          'name': 'Projection',
          'description': 'A CodeSpecs projection, refused by the set.',
        }),
        _a('CodeSpecsProjection', {}),
      ],
    ),
    'Requirements': _cls(
      'Requirements',
      'REQS',
      [
        _form('summary', 'REQS-SUM', [
          _ff('total', 'int', {
            'countOf': ['REQ'],
          }),
          _ff('settled', 'int', {
            'countOf': ['REQ.status=approved|done'],
          }),
          _ff('allRequirements', 'String', {
            'refersTo': ['REQ.@sectionId'],
            'multiple': true,
            'summaryOf': {
              'detail': 'REQ-ITEM-LST',
              'relation': 'equal',
              'repeats': <String, String>{},
            },
          }),
        ]),
        _list('items', 'REQ-ITEM-LST', 'REQ-xxx', 'Requirement'),
        _complex('keyRequirements', 'KeyRequirements'),
      ],
      annotations: [
        _a('DetailedIn', {'target': 'Detail'}),
        _a('SyncedWith', {
          'document': 'Detail',
          'detailOnly': ['REQX'],
          'heldHere': ['REQ.owner'],
          'relations': [
            {'place': 'REQT.relatedScreens', 'relation': 'LinkRelation.subset'},
          ],
          'note': 'the requirements of the Blueprint are those of Detail',
        }),
      ],
    ),
    'KeyRequirements': _cls('KeyRequirements', 'KEYS', [
      _list(
        'items',
        'KEY-ITEM-LST',
        'KEY-xxx',
        'KeyRequirement',
        annotations: [
          _a('SummaryOf', {
            'detail': 'REQ-ITEM-LST',
            'match': 'KEY.requirementRef',
            'relation': 'LinkRelation.subset',
            'repeats': {'KEY.title': 'REQ.@headline'},
            'note': 'the key requirements are a selection of the full list',
          }),
        ],
      ),
    ]),
    'KeyRequirement': _cls('KeyRequirement', 'KEY', [
      _form('content', null, [
        _ff('requirementRef', 'String', {
          'refersTo': ['REQ.@sectionId'],
        }),
        _ff('title', 'String'),
      ]),
    ]),
    'Requirement': _cls('Requirement', 'REQ', [
      _form('content', null, [
        _ff('status', 'RequirementStatus', {
          'enumValues': ['draft', 'approved', 'done'],
        }),
        _ff('owner', 'String'),
        _ff('weight', 'double'),
        _ff('effort', 'int'),
        _ff('score', 'double', {
          'productOf': ['weight', 'effort'],
        }),
        _ff('rank', 'int', {'rankOf': 'score'}),
        _ff('lastVersion', 'String', {
          'derivedFrom': {
            'kind': 'lookup',
            'source': 'REV',
            'take': ['REV.version'],
            'key': 'REV.requirementRef',
            'by': 'REQ.@sectionId',
            'map': <String, String>{},
          },
        }),
      ]),
      _form('details', 'REQD', [_ff('description', 'String')]),
      _form('constraints', 'REQC', [
        _ff('constraints', 'String'),
        _ff('conflictsWith', 'String', {
          'refersTo': ['REQ.@sectionId'],
          'multiple': true,
          'derivedFrom': {
            'kind': 'rows',
            'source': './LNK',
            'where': 'LNK.linkType=conflict',
            'take': ['LNK-REF.ref'],
            'map': <String, String>{},
          },
        }),
      ]),
      _form('trace', 'REQT', [
        _ff('relatedScreens', 'String', {
          'refersTo': ['SCRN.@sectionId'],
          'multiple': true,
          'inverseOf': {
            'fields': ['SCRN.relatedRequirements'],
          },
        }),
        _ff('relatedCriteria', 'String', {
          'refersTo': ['CRITE.@sectionId'],
          'multiple': true,
          'inverseOf': {
            'fields': ['CRITE.relatedRequirements'],
          },
        }),
      ]),
      _form('rationale', 'REQX', [_ff('rationale', 'String')]),
      _content(
        'abstract',
        'REQAB',
        annotations: [
          _a('DerivedFrom', {
            'kind': 'DerivationKind.copy',
            'source': 'REQD.description',
            'take': <String>[],
            'map': <String, String>{},
          }),
        ],
      ),
      _list(
        'links',
        'LNK-ITEM-LST',
        'LNK-xxx',
        'Link',
        annotations: [
          _a('ExtractsLinks', {
            'from': ['REQD.description'],
            'ref': 'LNK-REF.ref',
            'set': {'LNK.linkType': 'namedInText'},
            'mode': 'ExtractMode.generate',
          }),
          _a('ExtractsLinks', {
            'from': ['REQC.constraints'],
            'ref': 'LNK-REF.ref',
            'set': {'LNK.linkType': 'constrainedBy'},
            'mode': 'ExtractMode.warn',
            'note': 'an id in the constraints text without its row is reported',
          }),
        ],
      ),
      _list(
        'prerequisites',
        'PRE-ITEM-LST',
        'PRE-xxx',
        'Prerequisite',
        annotations: [
          _a('DerivedFrom', {
            'kind': 'DerivationKind.rows',
            'source': './LNK',
            'where': 'LNK.linkType=prerequisite',
            'take': <String>[],
            'map': {'PRE.ref': 'LNK-REF.ref'},
          }),
        ],
      ),
    ]),
    'Link': _cls('Link', 'LNK', [
      _form('content', null, [
        _ff('linkType', 'LinkType', {
          'enumValues': [
            'prerequisite',
            'conflict',
            'namedInText',
            'constrainedBy',
          ],
        }),
        _ff('description', 'String'),
      ]),
      _form(
        'ref',
        'LNK-REF',
        [
          _ff('ref', 'String', {
            'refersTo': ['REQ.@sectionId'],
            'inverseOf': {
              'fields': ['@self'],
              'where': 'LNK.linkType=conflict',
            },
          }),
        ],
        annotations: [
          _a('Reference', {'description': 'the requirement linked'}),
        ],
      ),
    ]),
    'Prerequisite': _cls('Prerequisite', 'PRE', [
      _form('content', null, [
        _ff('ref', 'String', {
          'refersTo': ['REQ.@sectionId'],
        }),
      ]),
    ]),
    'Revision': _cls('Revision', 'REV', [
      _form('content', null, [
        _ff('requirementRef', 'String', {
          'refersTo': ['REQ.@sectionId'],
        }),
        _ff('version', 'String'),
      ]),
    ]),
    'Acceptance': _cls(
      'Acceptance',
      'ACC',
      [
        _form('content', null, [_ff('owner', 'String')]),
        _complex('criteria', 'Criteria'),
      ],
      annotations: [
        _a('DetailedIn', {'target': 'Screens'}),
        _a('SyncedWith', {
          'document': 'Screens',
          'detailOnly': ['CRIT'],
          'heldHere': <String>[],
          'relations': <Object?>[],
        }),
      ],
    ),
    'Criteria': _cls(
      'Criteria',
      'CRIT',
      [_list('items', 'CRIT-ITEM-LST', 'CRITE-xxx', 'Criterion')],
      annotations: [
        _a('DetailedIn', {'target': 'Detail'}),
        _a('SyncedWith', {
          'document': 'Detail',
          'detailOnly': <String>[],
          'heldHere': <String>[],
          'relations': [
            {
              'place': 'CRIT-ITEM-LST',
              'relation': 'LinkRelation.subset',
              'where': 'CRITE.kind=functional|quality',
            },
          ],
        }),
      ],
    ),
    'Criterion': _cls('Criterion', 'CRITE', [
      _form('content', null, [
        _ff('kind', 'CriterionKind', {
          'enumValues': ['functional', 'quality', 'legal'],
        }),
        _ff('text', 'String'),
        _ff('relatedRequirements', 'String', {
          'refersTo': ['REQ.@sectionId'],
          'multiple': true,
          'inverseOf': {
            'fields': ['REQT.relatedCriteria'],
          },
        }),
      ]),
    ]),
    'CriteriaSummary': _cls('CriteriaSummary', 'CSUM', [
      _content('content', null),
      _complex(
        'criteria',
        'Criteria',
        annotations: [
          _a('SameAs', {
            'holder': 'ACC/CRIT',
            'note': 'the acceptance holds the criteria; this is their copy',
          }),
        ],
      ),
    ]),
    'ScreenOverview': _cls('ScreenOverview', 'SOV', [
      _list(
        'rows',
        'OVR-ITEM-LST',
        'OVR-xxx',
        'OverviewRow',
        annotations: [
          _a('SummaryOf', {
            'detail': 'SCRN-ITEM-LST',
            'document': 'Screens',
            'match': 'OVR.screenRef',
            'relation': 'LinkRelation.equal',
            'repeats': <String, String>{},
          }),
        ],
      ),
    ]),
    'OverviewRow': _cls('OverviewRow', 'OVR', [
      _form('content', null, [
        _ff('screenRef', 'String', {
          'refersTo': ['SCRN.@sectionId'],
        }),
      ]),
    ]),
    'Screen': _cls('Screen', 'SCRN', [
      _form('content', null, [
        _ff('purpose', 'String'),
        _ff('relatedRequirements', 'String', {
          'refersTo': ['REQ.@sectionId'],
          'multiple': true,
          'inverseOf': {
            'fields': ['REQT.relatedScreens'],
          },
        }),
      ]),
    ]),
  };
  return {
    'metaSchemaVersion': 1,
    'modelVersion': 1,
    'modelVersionLabel': 'links-1.0',
    'generatedAt': '2026-11-24T08:00:00.000000Z',
    'classCount': classes.length,
    'rootCount': 4,
    'roots': [
      for (final r in [
        ('Blueprint', 'BLU'),
        ('Detail', 'DET'),
        ('Screens', 'SCR'),
        ('Projection', 'PRJ'),
      ])
        {'type': r.$1, 'title': r.$1, 'sectionId': r.$2},
    ],
    'classes': classes,
  };
}

Map<String, dynamic> _a(String name, Map<String, Object?> arguments) => {
  'name': name,
  'arguments': arguments,
};

Map<String, dynamic> _cls(
  String name,
  String id,
  List<Map<String, dynamic>> fields, {
  List<Map<String, dynamic>> annotations = const [],
}) => {
  'name': name,
  'sectionId': id,
  'annotations': [
    _a('SectionId', {'id': id}),
    ...annotations,
  ],
  'fields': fields,
};

Map<String, dynamic> _form(
  String name,
  String? id,
  List<Map<String, dynamic>> formFields, {
  List<Map<String, dynamic>> annotations = const [],
}) => {
  'name': name,
  'kind': 'form',
  if (id != null) 'sectionId': id,
  if (annotations.isNotEmpty) 'annotations': annotations,
  'formFields': formFields,
};

Map<String, dynamic> _ff(
  String name,
  String type, [
  Map<String, Object?> extra = const {},
]) => {
  'name': name,
  'label': name[0].toUpperCase() + name.substring(1),
  'type': type,
  ...extra,
};

Map<String, dynamic> _content(
  String name,
  String? id, {
  List<Map<String, dynamic>> annotations = const [],
}) => {
  'name': name,
  'kind': 'content',
  if (id != null) 'sectionId': id,
  'contentType': 'markdown',
  if (annotations.isNotEmpty) 'annotations': annotations,
};

Map<String, dynamic> _list(
  String name,
  String id,
  String pattern,
  String element, {
  List<Map<String, dynamic>> annotations = const [],
}) => {
  'name': name,
  'kind': 'list',
  'sectionId': id,
  'sectionIdPattern': pattern,
  'elementType': element,
  'elementIsComplex': true,
  if (annotations.isNotEmpty) 'annotations': annotations,
};

Map<String, dynamic> _complex(
  String name,
  String type, {
  List<Map<String, dynamic>> annotations = const [],
}) => {
  'name': name,
  'kind': 'complex',
  'type': type,
  if (annotations.isNotEmpty) 'annotations': annotations,
};
