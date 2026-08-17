/// The recurrence guard for **nine-language enumerations** (SOM §19).
///
/// ## The rule it enforces
///
/// A shared corpus table is what makes the eight ports *prove* they implement a
/// check: a committed case expecting a result a runtime does not produce fails
/// that runtime's own conformance runner. The corollary is the dangerous part —
/// a constant with **no** case is not weakly covered, it is **invisible**, and
/// the harness will report nine-way parity about a question none of the nine
/// was asked.
///
/// So a nine-language enumeration is only safe when *adding a constant is
/// itself the act that demands its corpus case*. That is achieved by deriving
/// the covered set from `<Enum>.values` rather than from a second hand-kept
/// list.
///
/// ## Why this file exists rather than a third hand-written guard
///
/// The rule was first written for `SpecValidationCode` (csrf3) after
/// `danglingReference` and `oneOfCaseMismatch` stayed Dart-only for two rounds.
/// It was then copied for `DocSpecsViolationRule`, whose eleven rules had gone
/// unexercised for exactly the same reason — the copy was made *after* the gap
/// had already cost a round. Copying a guard does not scale, and it cannot see
/// the enum nobody thought to copy it for.
///
/// This file is therefore the single mechanism, in two halves:
///
///   * **Realisation** — every registered enum's constants must be exercised by
///     its corpus table (ECG2), and every token a table exercises must name a
///     real constant (ECG5).
///   * **Totality** — *every* enum declared in `lib/` must be either registered
///     or explicitly exempt with a reason (ECG1). This is the half that turns
///     "remember to register your enum" from a convention into a mechanical
///     check: a new enum fails the default `dart test` run until someone has
///     said, in the table below, what its relationship to the corpus is.
///
/// Adding a third guarded enumeration is one entry in [_guarded].
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

// ---------------------------------------------------------------------------
// The mechanism
// ---------------------------------------------------------------------------

/// One enum whose constants must each be exercised by a committed corpus table.
class CorpusGuardedEnum {
  const CorpusGuardedEnum({
    required this.enumName,
    required this.declared,
    required this.corpusFile,
    required this.exercised,
    required this.why,
    this.waived = const {},
  });

  /// The Dart enum's name, as written in `lib/` — the key totality matches on.
  final String enumName;

  /// Constant name → the token the corpus writes for it.
  ///
  /// Almost always the identity, so most registrations use [_wire] with no
  /// aliases. The exception is [SpecFieldKind.enumValue], whose wire spelling
  /// is `enum` because the Dart constant cannot be.
  final Map<String, String> declared;

  /// The corpus file, relative to `tom_som_conformance/corpus/`.
  final String corpusFile;

  /// Every token [corpusFile] exercises, extracted from its decoded JSON.
  ///
  /// An extractor rather than a declarative `listKey`/`memberKey` pair because
  /// the tables genuinely differ in shape: a list of cases each holding a list
  /// of errors, a list of cases each holding one scalar kind, a map of classes
  /// each holding a list of fields. A function covers all three; a schema for
  /// them would be a worse description of the same thing.
  ///
  /// It is deliberately **per-enum-per-file** and never a global token scan:
  /// `malformedHeading` is a constant of *both* [DocSpecsViolationRule] and
  /// [SpecMarkdownRejectReason], in different tiers with different validators,
  /// so a scan for the bare token would credit one enum with the other's
  /// coverage.
  final Set<String> Function(dynamic corpus) exercised;

  /// Constants knowingly unexercised, mapped to the todo that closes the gap.
  ///
  /// A waiver is a **tracked exception, not a suppression**: it names one
  /// constant (never a whole enum), it carries the id of the work that removes
  /// it, and ECG3 fails the moment the constant becomes exercised — so it
  /// cannot outlive its cause.
  final Map<String, String> waived;

  /// What a missing case would let through. Quoted in the failure message,
  /// because the person reading that message is deciding whether to write the
  /// case or widen the waiver, and needs the stakes in front of them.
  final String why;
}

/// Why an enum declared in `lib/` is not diffed against a corpus table.
enum ExemptionReason {
  /// Spelled twice in the runtime; pinned constant-for-constant against a
  /// registered twin by ECG4, so the twin's coverage carries it.
  mirrors,

  /// Declared in all nine runtimes but no corpus table exists yet. The named
  /// todo creates one; closing it moves the entry into [_guarded].
  noCorpusYet,

  /// The surface it belongs to is Dart-only today — no port implements it, so
  /// there is nothing for a shared table to hold nine languages to. The named
  /// todo is the one that ports the surface.
  dartOnly,

  /// App display semantics, deliberately outside the SOM contract. No port
  /// should ever implement it, so it will never be corpus-guarded.
  presentation,

  /// Private to its library: never serialized, never returned across the API
  /// boundary, so no corpus token could name one of its constants even in
  /// principle. What such an enum drives is behaviour, and the behaviour is
  /// guarded by the table of the surface that uses it — the entry must say
  /// which. Adding a constant to one is an internal refactor, not a change to
  /// the nine-language vocabulary.
  internal;

  /// Whether this exemption describes a **gap** (which must name the todo that
  /// ends it) rather than a **decision** (which is the permanent right answer).
  ///
  /// Declared on the reason rather than listed at the check site so that adding
  /// a reason forces the question to be answered here, once, next to the
  /// reason's own description.
  bool get isTemporary => switch (this) {
        ExemptionReason.noCorpusYet || ExemptionReason.dartOnly => true,
        ExemptionReason.mirrors ||
        ExemptionReason.presentation ||
        ExemptionReason.internal =>
          false,
      };
}

/// One enum deliberately left out of [_guarded].
class ExemptEnum {
  const ExemptEnum({
    required this.enumName,
    required this.reason,
    required this.note,
    this.names,
    this.mirrorNames,
  });

  final String enumName;
  final ExemptionReason reason;

  /// Why this disposition is the right one — and, whenever the reason is
  /// [ExemptionReason.isTemporary], the id of the todo that ends it.
  final String note;

  /// This enum's own constant names. Required for [ExemptionReason.mirrors].
  final List<String>? names;

  /// The registered twin's constant names. Required for
  /// [ExemptionReason.mirrors]; ECG4 asserts the two lists are equal, which is
  /// what makes "mirrors" a mechanical claim rather than a remembered one.
  final List<String>? mirrorNames;
}

/// Builds a `constant name → corpus token` map from an enum's values, applying
/// [aliases] where the wire spelling differs from the Dart constant.
Map<String, String> _wire(List<Enum> values,
        [Map<Enum, String> aliases = const {}]) =>
    {for (final v in values) v.name: aliases[v] ?? v.name};

// ---------------------------------------------------------------------------
// The registry
// ---------------------------------------------------------------------------

/// Every enum diffed against a corpus table. **Adding one is one entry.**
final List<CorpusGuardedEnum> _guarded = [
  CorpusGuardedEnum(
    enumName: 'SpecValidationCode',
    declared: _wire(SpecValidationCode.values),
    corpusFile: 'validation_cases.json',
    exercised: (c) => {
      for (final k in (c as List).cast<Map<String, dynamic>>())
        for (final e in (k['errors'] as List).cast<Map<String, dynamic>>())
          e['code'] as String,
    },
    why: 'an instance-tier check that eight runtimes need not implement, while '
        'the harness reports nine-way parity',
  ),
  CorpusGuardedEnum(
    enumName: 'DocSpecsViolationRule',
    declared: _wire(DocSpecsViolationRule.values),
    corpusFile: 'docspecs_cases.json',
    exercised: (c) => {
      for (final k in (c as List).cast<Map<String, dynamic>>())
        for (final v in (k['violations'] as List).cast<Map<String, dynamic>>())
          v['rule'] as String,
    },
    why: 'a §14 DocSpecs rule that eight runtimes need not implement — the '
        'exact gap that let all eleven rules go unexercised until tscomp8',
  ),
  CorpusGuardedEnum(
    enumName: 'SpecFieldKind',
    // The meta writes `enum`; the Dart constant cannot be spelled that way.
    declared: _wire(SpecFieldKind.values, {SpecFieldKind.enumValue: 'enum'}),
    corpusFile: 'model.meta.json',
    exercised: (c) => {
      for (final cls in ((c as Map<String, dynamic>)['classes'] as Map).values)
        for (final f in (((cls as Map)['fields'] as List?) ?? const [])
            .cast<Map<String, dynamic>>())
          if (f['kind'] != null) f['kind'] as String,
    },
    why: 'a §7.1 field kind no port is ever asked to classify, so eight '
        'decoders could disagree about it undetected',
  ),
  CorpusGuardedEnum(
    enumName: 'SpecStateFilter',
    declared: _wire(SpecStateFilter.values),
    corpusFile: 'query_cases.json',
    // The dimension is optional, so most cases omit it; only the cases that
    // set it count as exercising a constant.
    exercised: (c) => {
      for (final k in (c as List).cast<Map<String, dynamic>>())
        if ((k['query'] as Map)['state'] != null)
          (k['query'] as Map)['state'] as String,
    },
    why: 'a value-presence filter eight query engines could implement '
        'backwards — `empty` and `nonEmpty` are each other\'s negation, so a '
        'port that swaps them passes every query that omits the dimension',
  ),
  CorpusGuardedEnum(
    enumName: 'SpecCreationCode',
    declared: _wire(SpecCreationCode.values),
    corpusFile: 'node_creation_cases.json',
    exercised: (c) => {
      for (final k in (c as List).cast<Map<String, dynamic>>())
        if (k['code'] != null) k['code'] as String,
    },
    why: 'a structural rule the creation gate must refuse on — an unexercised '
        'code is a port that silently *accepts* the add, corrupting the '
        'document rather than merely reporting the wrong reason',
  ),
  CorpusGuardedEnum(
    enumName: 'SpecNodeKind',
    declared: _wire(SpecNodeKind.values),
    corpusFile: 'reflection_cases.json',
    exercised: (c) => {
      for (final k in (c as List).cast<Map<String, dynamic>>())
        if (k['kind'] != null) k['kind'] as String,
    },
    why: 'a resolution outcome no port is ever asked to produce, so eight path '
        'resolvers could disagree about it undetected',
  ),
  CorpusGuardedEnum(
    enumName: 'SomEditability',
    declared: _wire(SomEditability.values),
    corpusFile: 'editability_cases.json',
    exercised: (c) => {
      for (final k in ((c as Map<String, dynamic>)['cases'] as List)
          .cast<Map<String, dynamic>>())
        k['editability'] as String,
    },
    why: 'the §4.2/§21 verdict on whether a document may be edited at all — a '
        'port that classifies `readOnlyCrossMajor` as `editable` corrupts a '
        'document it was supposed to refuse, and `somEditabilityFor` is the '
        'single definition the throwing check switches on, so a wrong '
        'classification is also a wrong refusal',
  ),
  CorpusGuardedEnum(
    enumName: 'SpecMarkdownRejectReason',
    declared: _wire(SpecMarkdownRejectReason.values),
    corpusFile: 'markdown_import_cases.json',
    exercised: (c) => {
      for (final k in ((c as Map<String, dynamic>)['cases'] as List)
          .cast<Map<String, dynamic>>())
        for (final r in (k['rejections'] as List).cast<Map<String, dynamic>>())
          r['reason'] as String,
    },
    why: 'a §11.7 import rejection no port is ever asked to report — and the '
        'failure that hides behind an unexercised reason is the one the '
        'protocol exists to prevent: a port that *drops* the unplaceable block '
        'instead of reporting it looks identical to one that never met it',
  ),
  CorpusGuardedEnum(
    enumName: 'CodeSpecsRoutingVerdict',
    declared: _wire(CodeSpecsRoutingVerdict.values),
    corpusFile: 'codespecs_extract_cases.json',
    // Two tables, because the vocabulary is genuinely split across them: the
    // four verdicts a well-formed section can carry are the `routings` rows,
    // while `unrouted` is by construction never a row — a section that reaches
    // it is the ROUTE-TOTAL failure, so its only home is an error case.
    exercised: (c) => {
      for (final r in ((c as Map<String, dynamic>)['routings'] as List)
          .cast<Map<String, dynamic>>())
        r['verdict'] as String,
      for (final e in (c['errorCases'] as List).cast<Map<String, dynamic>>())
        if ((e['expect'] as Map<String, dynamic>)['routingVerdict']
            case final String v)
          v,
    },
    why: 'the §8.3 routing verdict that decides whether a section reaches the '
        'Phase-4 extract at all — and the two failures it hides are opposite '
        'and both silent: a port that misreads `feedsProcess` as `feedsCode` '
        'puts follow-up prose in front of the authoring agent as if it were '
        'specification, while one that never produces `unrouted` accepts a '
        'section no verdict covers, quietly dropping it instead of failing '
        'ROUTE-TOTAL',
  ),
];

/// Every enum in `lib/` deliberately **not** in [_guarded], with why.
///
/// Totality (ECG1) requires an entry here for anything absent from the registry
/// above, so the list doubles as the standing answer to "which parts of the
/// runtime vocabulary are outside the shared corpus, and on whose authority".
final List<ExemptEnum> _exempt = [
  ExemptEnum(
    enumName: '_AtomKind',
    reason: ExemptionReason.internal,
    note: 'The portable pattern matcher\'s atom taxonomy (literal / any / '
        'anchor / class), private to spec_text_pattern.dart. A pattern is '
        'compiled and matched entirely within the library; only the resulting '
        'spans leave it, and those are what query_cases.json pins across all '
        'nine runtimes. A port is free to represent atoms differently — a C '
        'tagged union, a Rust enum with payload — so long as the spans agree.',
  ),
  ExemptEnum(
    enumName: '_Repeat',
    reason: ExemptionReason.internal,
    note: 'The same matcher\'s quantifier taxonomy, private for the same '
        'reason and pinned by the same spans in query_cases.json.',
  ),
  ExemptEnum(
    enumName: 'SomMetaKind',
    reason: ExemptionReason.mirrors,
    names: SomMetaKind.values.map((v) => v.name).toList(),
    mirrorNames: SpecFieldKind.values.map((v) => v.name).toList(),
    note: 'The metadata tree\'s spelling of the same §7.1 kind vocabulary as '
        'SpecFieldKind, which is registered. The tree is built from the model '
        'rather than serialized, so there is no token in the corpus to diff '
        'against; ECG4 pins the two enums constant-for-constant instead, which '
        'is the stronger statement — a constant added to either alone fails.',
  ),
  ExemptEnum(
    enumName: 'SpecChipRole',
    reason: ExemptionReason.presentation,
    note: 'The display semantics the editor and the reviewer share so they '
        'cannot disagree about what a marker means. It lives here to be '
        'inherited by two Flutter apps, not because it is part of the '
        'nine-language contract, and is already pinned against the shipped '
        'model asset by kRenderedAnnotations. No port will implement it.',
  ),
];

// ---------------------------------------------------------------------------
// The guard
// ---------------------------------------------------------------------------

void main() {
  final corpusDir =
      Directory('${Directory.current.path}/../tom_som_conformance/corpus');

  dynamic corpus(String name) =>
      jsonDecode(File('${corpusDir.path}/$name').readAsStringSync());

  test('ECG1: every enum in lib/ is corpus-guarded or explicitly exempt '
      '[2026-08-09]', () {
    // Deliberately a source parse rather than reflection, for the reason the
    // structural-accessor guard states: the point is to notice when someone
    // **adds** an enum, and a source parse sees the declaration whether or not
    // this test — or anything else — ever references it.
    final declared = <String, String>{};
    for (final f in Directory('${Directory.current.path}/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      for (final m in RegExp(r'^enum\s+(\w+)\s*\{', multiLine: true)
          .allMatches(f.readAsStringSync())) {
        declared[m.group(1)!] = f.path.split('/lib/').last;
      }
    }
    expect(declared, isNotEmpty,
        reason: 'the source parse found no enums at all — it has stopped '
            'matching the declarations it is supposed to police');

    final accounted = {
      ..._guarded.map((g) => g.enumName),
      ..._exempt.map((e) => e.enumName),
    };

    final unaccounted = declared.keys.where((n) => !accounted.contains(n));
    expect(unaccounted, isEmpty,
        reason: 'these enums are declared in lib/ and neither guarded nor '
            'exempt: ${unaccounted.map((n) => '$n (${declared[n]})').join(', ')}'
            ' — a nine-language enumeration with no corpus table is invisible, '
            'not merely untested, so say which it is: add a CorpusGuardedEnum '
            'entry, or an ExemptEnum entry naming the reason and the todo');

    final stale = accounted.where((n) => !declared.containsKey(n));
    expect(stale, isEmpty,
        reason: 'the table accounts for ${stale.join(', ')}, which lib/ no '
            'longer declares — remove the entry rather than leaving a rule '
            'about a vocabulary that is gone');
  });

  group('ECG2: every guarded constant has a corpus case [2026-08-09]', () {
    for (final g in _guarded) {
      test(g.enumName, () {
        final exercised = g.exercised(corpus(g.corpusFile));
        final uncovered = g.declared.entries
            .where((e) => !exercised.contains(e.value))
            .where((e) => !g.waived.containsKey(e.key))
            .map((e) => e.key)
            .toList();
        expect(uncovered, isEmpty,
            reason: '${g.corpusFile} exercises no case producing '
                '${uncovered.join(', ')}. Add one — and implement it in all '
                'nine runtimes — rather than shipping ${g.why}.');
      });
    }
  });

  group('ECG3: no waiver outlives its cause [2026-08-09]', () {
    // Currently DORMANT — [_guarded] holds no waiver, so this group emits no
    // tests. That is the goal state, not a broken check: every registered
    // constant has a corpus case. It revives by itself the moment a waiver is
    // added, which is why the mechanism stays rather than being deleted along
    // with its last user.
    for (final g in _guarded.where((g) => g.waived.isNotEmpty)) {
      test(g.enumName, () {
        final exercised = g.exercised(corpus(g.corpusFile));
        final stale =
            g.waived.keys.where((n) => exercised.contains(g.declared[n]));
        expect(stale, isEmpty,
            reason: '${g.enumName}.${stale.join(', ')} is waived but '
                '${g.corpusFile} now exercises it — delete the waiver, and '
                'close the todo it names');

        final unknown = g.waived.keys.where((n) => !g.declared.containsKey(n));
        expect(unknown, isEmpty,
            reason: '${g.enumName} waives ${unknown.join(', ')}, which is not '
                'one of its constants — a waiver that names nothing silently '
                'protects nothing');
      });
    }
  });

  test('ECG4: a mirrored enum matches its twin constant-for-constant '
      '[2026-08-09]', () {
    final mirrors =
        _exempt.where((e) => e.reason == ExemptionReason.mirrors).toList();
    expect(mirrors, isNotEmpty,
        reason: 'the mirrors reason is unused — drop it from ExemptionReason '
            'rather than leaving an unexercised exemption kind available');
    for (final e in mirrors) {
      expect(e.names, isNotNull, reason: '${e.enumName} declares no names');
      expect(e.names, e.mirrorNames,
          reason: '${e.enumName} claims to mirror a registered enum but their '
              'constants differ — either restore the correspondence, or drop '
              'the mirrors exemption and give ${e.enumName} a corpus table of '
              'its own, because the twin\'s coverage no longer carries it');
    }
  });

  group('ECG5: every corpus token names a real constant [2026-08-09]', () {
    for (final g in _guarded) {
      test(g.enumName, () {
        // The reverse direction, and the reason it earns its place: an
        // extractor that reads the wrong key would return tokens that are not
        // constants, and ECG2 alone would report that as *missing coverage* —
        // pointing at the enum instead of at the extractor.
        final tokens = g.declared.values.toSet();
        final unknown =
            g.exercised(corpus(g.corpusFile)).where((t) => !tokens.contains(t));
        expect(unknown, isEmpty,
            reason: '${g.corpusFile} exercises ${unknown.join(', ')}, which '
                '${g.enumName} does not declare — either the extractor is '
                'reading the wrong key, or the corpus expects a constant the '
                'reference runtime has dropped');
      });
    }
  });

  test('ECG6: every exemption states its reason and its exit [2026-08-09]', () {
    for (final e in _exempt) {
      expect(e.note.trim(), isNotEmpty, reason: '${e.enumName} has no note');
      if (!e.reason.isTemporary) continue;
      // Every temporary exemption is temporary *by reference*: it names the
      // todo that ends it, so the list cannot quietly become permanent.
      expect(e.note, contains('tscomp'),
          reason: '${e.enumName} is exempt as ${e.reason.name}, which is a '
              'temporary state, but its note names no todo that ends it');
    }
  });
}
