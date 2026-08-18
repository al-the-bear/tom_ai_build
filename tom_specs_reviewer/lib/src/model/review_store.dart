import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_core/tom_specs_core.dart';
import 'package:yaml/yaml.dart';

/// Schema version written into the review file.
///
/// Version 2 covers the CodeSpecs-mapping, follow-up, no-artifact, destination
/// and structural feedback axes. Every one of them is purely additive, so a
/// version-1 file loads unchanged — an in-flight review is never lost to the
/// bump. The counter only advances when a change is *not* additive; advancing
/// it for an addition would cry wolf.
const int kReviewFileVersion = 2;

/// The canonical CodeSpecs kind vocabulary, as persistence tokens.
///
/// Sourced from [CodeSpecPart] rather than from the shipped model asset on
/// purpose: the asset only carries the kinds some section already maps to, but
/// the review case that matters most is proposing a kind nothing maps to yet.
final Set<String> kCodeSpecPartTokens = {
  for (final part in CodeSpecPart.values) part.name,
};

/// Prefix a kind may carry when copied from what the tree renders.
const String _kindTokenPrefix = 'CodeSpecPart.';

/// Normalises a CodeSpecs kind token, rejecting anything outside the
/// vocabulary.
///
/// Accepts both the bare enum name (`form`) and the qualified form the tree
/// displays (`CodeSpecPart.form`), because a reviewer hand-editing the review
/// file will copy whichever they saw.
///
/// Throws [ArgumentError] on an unknown token — a typo must surface at entry,
/// not as silently-lost feedback at rework time.
String normalizeCodeSpecKindToken(String raw) {
  final token = tryNormalizeCodeSpecKindToken(raw);
  if (token == null) {
    throw ArgumentError.value(
        raw, 'kind', 'not a known CodeSpecPart (see kCodeSpecPartTokens)');
  }
  return token;
}

/// Lenient counterpart of [normalizeCodeSpecKindToken]: returns `null` instead
/// of throwing.
///
/// Used when reading a file, where an unrecognised token must cost one
/// suggestion rather than the whole review.
String? tryNormalizeCodeSpecKindToken(String raw) {
  var token = raw.trim();
  if (token.startsWith(_kindTokenPrefix)) {
    token = token.substring(_kindTokenPrefix.length);
  }
  return kCodeSpecPartTokens.contains(token) ? token : null;
}

/// The canonical follow-up process vocabulary, as persistence tokens.
///
/// Sourced from [FollowUpProcess], which the model declares to be an
/// *extensible* taxonomy. That extensibility is why a proposal outside this set
/// is warned about rather than rejected — see [normalizeFollowUpKindToken].
final Set<String> kFollowUpProcessTokens = {
  for (final process in FollowUpProcess.values) process.name,
};

/// Prefix a follow-up code may carry when copied from what the tree renders.
const String _followUpTokenPrefix = 'FollowUpProcess.';

/// Normalises a follow-up process code to its lower-case bare form.
///
/// Unlike [normalizeCodeSpecKindToken] this does *not* reject a code outside
/// [kFollowUpProcessTokens]: the follow-up taxonomy is open, so "this belongs to
/// a process we have not named yet" is a legitimate — and valuable — review
/// finding. Only a blank code is rejected, since it carries no judgement at all.
String normalizeFollowUpKindToken(String raw) {
  var token = raw.trim();
  if (token.startsWith(_followUpTokenPrefix)) {
    token = token.substring(_followUpTokenPrefix.length);
  }
  token = token.toLowerCase();
  if (token.isEmpty) {
    throw ArgumentError.value(raw, 'kind', 'follow-up code must not be blank');
  }
  return token;
}

/// Prefix a no-artifact reason may carry when copied from what the tree
/// renders.
const String _noArtifactTokenPrefix = 'NoArtifactReason.';

/// Reads a no-artifact reason token, returning `null` for "no proposal".
///
/// The vocabulary is [NoArtifactReason] itself rather than a mirrored enum: the
/// model already declares it closed at three, so mirroring it would only create
/// something that can drift from it. `null` carries the "undecided" state the
/// enum has no member for — the same split [ReviewDestination.unset] makes, but
/// expressed by nullability because here the judgement vocabulary is not the
/// reviewer's to define.
///
/// Lenient, like every other read path: an unrecognised token degrades to "no
/// proposal" rather than making the file unloadable. Accepts the bare name
/// (`overview`) and the qualified form the tree renders
/// (`NoArtifactReason.overview`), because a reviewer hand-editing the file will
/// copy whichever they saw.
NoArtifactReason? parseNoArtifactReason(String? raw) {
  if (raw == null) return null;
  var token = raw.trim();
  if (token.startsWith(_noArtifactTokenPrefix)) {
    token = token.substring(_noArtifactTokenPrefix.length);
  }
  token = token.toLowerCase();
  for (final reason in NoArtifactReason.values) {
    if (reason.name == token) return reason;
  }
  return null;
}

/// Short human label for [reason], with `null` reading as "no proposal".
String noArtifactReasonLabel(NoArtifactReason? reason) {
  switch (reason) {
    case null:
      return 'Undecided';
    case NoArtifactReason.container:
      return 'Container';
    case NoArtifactReason.overview:
      return 'Overview';
    case NoArtifactReason.view:
      return 'View';
  }
}

/// Where a reviewer thinks a subtree belongs.
///
/// The CodeSpecs / follow-up split is a *choice*, so it is recorded as one
/// value rather than as competing booleans — two flags would admit the
/// meaningless "not CodeSpecs and not follow-up, but also both" states.
///
/// [unset] and [neither] are deliberately distinct: [unset] means no judgement
/// has been made, [neither] is the judgement that the subtree drives no
/// downstream work at all.
enum ReviewDestination {
  unset,
  codeSpecs,
  followUp,
  both,
  neither;

  /// The YAML / persistence token for this destination.
  String get token {
    switch (this) {
      case ReviewDestination.unset:
        return 'unset';
      case ReviewDestination.codeSpecs:
        return 'code_specs';
      case ReviewDestination.followUp:
        return 'follow_up';
      case ReviewDestination.both:
        return 'both';
      case ReviewDestination.neither:
        return 'neither';
    }
  }

  /// Short human label for the UI.
  String get label {
    switch (this) {
      case ReviewDestination.unset:
        return 'Undecided';
      case ReviewDestination.codeSpecs:
        return 'CodeSpecs';
      case ReviewDestination.followUp:
        return 'Follow-up';
      case ReviewDestination.both:
        return 'Both';
      case ReviewDestination.neither:
        return 'Neither';
    }
  }

  static ReviewDestination parse(String? raw) {
    switch (raw) {
      case 'code_specs':
        return ReviewDestination.codeSpecs;
      case 'follow_up':
        return ReviewDestination.followUp;
      case 'both':
        return ReviewDestination.both;
      case 'neither':
        return ReviewDestination.neither;
      default:
        return ReviewDestination.unset;
    }
  }
}

/// Where a reviewed node belongs in the eventual document set.
///
/// This is the primary review decision: does this structural node stay only in
/// the Project Definition, become a global (shared) section, become global but
/// with per-document adaptations, or is it not yet decided?
enum ReviewScope {
  none,
  onlyPd,
  global,
  globalWithAdaptations;

  /// The YAML / persistence token for this scope.
  String get token {
    switch (this) {
      case ReviewScope.none:
        return 'none';
      case ReviewScope.onlyPd:
        return 'only_pd';
      case ReviewScope.global:
        return 'global';
      case ReviewScope.globalWithAdaptations:
        return 'global_with_adaptations';
    }
  }

  /// Short human label for the UI.
  String get label {
    switch (this) {
      case ReviewScope.none:
        return 'Undecided';
      case ReviewScope.onlyPd:
        return 'Only PD';
      case ReviewScope.global:
        return 'Global';
      case ReviewScope.globalWithAdaptations:
        return 'Global w/ adaptations';
    }
  }

  static ReviewScope parse(String? raw) {
    switch (raw) {
      case 'only_pd':
        return ReviewScope.onlyPd;
      case 'global':
        return ReviewScope.global;
      case 'global_with_adaptations':
        return ReviewScope.globalWithAdaptations;
      default:
        return ReviewScope.none;
    }
  }
}

/// The review decision recorded against a single structural path.
///
/// A path identifies a node in the *structure* (not a data instance), e.g.
/// `D00SolutionBlueprint/systemQualityGoals/§item/content`. The three visual
/// instances rendered for a list therefore share one entry.
class ReviewEntry {
  ReviewScope scope;
  bool stopHere;
  bool addDetails;

  /// This node must be modelled as a list.
  bool mustBeList;

  /// This node is only a single entry and should *not* be a list.
  bool singleEntry;

  /// This node must be a plain content string, not a `@Form` field.
  bool mustBeContentString;

  /// A `@Form` field that should be lifted into its own content-string
  /// subsection.
  bool convertFormToContent;

  /// The reviewer has checked this node off as reviewed (progress tracking).
  /// Set via a dedicated checkmark control, independent of the flags above.
  bool reviewed;

  /// This node should carry a `@CodeSpecKind` mapping and does not.
  bool codeSpecKindMissing;

  /// This node carries a `@CodeSpecKind`, but the declared kinds are wrong or
  /// incomplete. What they should be instead goes in [suggestedCodeSpecKinds].
  bool codeSpecKindWrong;

  /// This node should not be realised as code at all.
  ///
  /// Distinct from [codeSpecKindWrong] (mapped, but to the wrong part) and from
  /// [destination], which records where it belongs *instead*.
  bool notCodeSpecs;

  /// Where this subtree belongs — the single most consequential structural
  /// judgement, so it is a first-class value rather than a comment.
  ReviewDestination destination;

  /// This node should carry a `@FollowUpKind` and does not.
  bool followUpKindMissing;

  /// The declared `@FollowUpKind` processes are wrong or incomplete. What they
  /// should be instead goes in [suggestedFollowUpKinds].
  bool followUpKindWrong;

  /// This node produces no downstream artifact and should carry `@NoArtifact`,
  /// but is routed to CodeSpecs or a follow-up process instead.
  ///
  /// The mirror of [codeSpecKindMissing] and [followUpKindMissing] for the
  /// third routing verdict (`codespecs_mapping.md` §8.3).
  bool noArtifactMissing;

  /// This node carries `@NoArtifact` but does feed something downstream — the
  /// verdict itself is wrong, not merely its reason.
  ///
  /// Deliberately a plain flag rather than the counterpart-clearing pair used
  /// for the `@Unused` verdict: neither of these two authorises a deletion, so
  /// a reviewer who has written both has recorded a muddle worth seeing rather
  /// than a hazard worth resolving silently.
  bool noArtifactWrong;

  /// The `@NoArtifact` verdict stands, but its declared reason is the wrong one
  /// of the three. What it should be goes in [suggestedNoArtifactReason].
  bool noArtifactReasonWrong;

  /// The `NoArtifactReason` the reviewer proposes for this node, or `null` for
  /// no proposal.
  ///
  /// Single-valued where the other two mapping axes propose lists, because the
  /// annotation is: a section feeds several parts or several processes at once,
  /// but it is unrouted for one reason.
  NoArtifactReason? suggestedNoArtifactReason;

  /// These siblings are really alternatives and should be an `@OneOf` set.
  bool shouldBeOneOf;

  /// The `@OneOf` set is missing a `@Case`.
  ///
  /// Closure is the point of `@OneOf`, so an incomplete set is a defect rather
  /// than a nit.
  bool caseSetIncomplete;

  /// The `@SectionId` / `@SectionIdPattern` on this node is wrong or collides.
  bool idPatternWrong;

  /// The `@MapsTo` / `@DetailedIn` handoff points at the wrong target.
  bool handoffWrong;

  /// The `@ContentType` is wrong for this content.
  bool contentTypeWrong;

  /// The `@StandardReferences` on this node name the wrong standards.
  bool standardRefWrong;

  /// This node should carry `@StandardReferences` and does not.
  bool standardRefMissing;

  String comment;

  List<String> _suggestedCodeSpecKinds;
  List<String> _suggestedFollowUpKinds;

  /// The `@Unused` marking on this node is correct — the node can be dropped.
  bool _unusedConfirmed;

  /// The `@Unused` marking on this node is wrong — the node must be kept.
  bool _unusedRejected;

  ReviewEntry({
    this.scope = ReviewScope.none,
    this.stopHere = false,
    this.addDetails = false,
    this.mustBeList = false,
    this.singleEntry = false,
    this.mustBeContentString = false,
    this.convertFormToContent = false,
    this.reviewed = false,
    this.codeSpecKindMissing = false,
    this.codeSpecKindWrong = false,
    this.notCodeSpecs = false,
    this.destination = ReviewDestination.unset,
    this.followUpKindMissing = false,
    this.followUpKindWrong = false,
    this.noArtifactMissing = false,
    this.noArtifactWrong = false,
    this.noArtifactReasonWrong = false,
    this.suggestedNoArtifactReason,
    this.shouldBeOneOf = false,
    this.caseSetIncomplete = false,
    this.idPatternWrong = false,
    this.handoffWrong = false,
    this.contentTypeWrong = false,
    this.standardRefWrong = false,
    this.standardRefMissing = false,
    bool unusedConfirmed = false,
    bool unusedRejected = false,
    List<String> suggestedCodeSpecKinds = const [],
    List<String> suggestedFollowUpKinds = const [],
    this.comment = '',
  })  : _suggestedCodeSpecKinds =
            suggestedCodeSpecKinds.map(normalizeCodeSpecKindToken).toList(),
        _suggestedFollowUpKinds =
            suggestedFollowUpKinds.map(normalizeFollowUpKindToken).toList(),
        // A source that states both verdicts is contradictory. Drop the
        // confirmation rather than the rejection: confirming authorises a
        // deletion, and an ambiguous source must never authorise one.
        _unusedConfirmed = unusedConfirmed && !unusedRejected,
        _unusedRejected = unusedRejected;

  /// The `@Unused` marking on this node is correct — the node can be dropped.
  ///
  /// Mutually exclusive with [unusedRejected]: it is one verdict, so setting
  /// either side clears the other everywhere, not just in the UI.
  bool get unusedConfirmed => _unusedConfirmed;

  set unusedConfirmed(bool value) {
    _unusedConfirmed = value;
    if (value) _unusedRejected = false;
  }

  /// The `@Unused` marking on this node is wrong — the node must be kept.
  bool get unusedRejected => _unusedRejected;

  set unusedRejected(bool value) {
    _unusedRejected = value;
    if (value) _unusedConfirmed = false;
  }

  /// The follow-up process codes the reviewer proposes for this node.
  ///
  /// Read-only by design, for the same reason as [suggestedCodeSpecKinds]: a
  /// mutable list would let a raw value in behind [normalizeFollowUpKindToken].
  List<String> get suggestedFollowUpKinds =>
      List.unmodifiable(_suggestedFollowUpKinds);

  set suggestedFollowUpKinds(List<String> kinds) {
    _suggestedFollowUpKinds = kinds.map(normalizeFollowUpKindToken).toList();
  }

  /// Adds [kind] if absent, removes it if present.
  void toggleSuggestedFollowUpKind(String kind) {
    final token = normalizeFollowUpKindToken(kind);
    if (!_suggestedFollowUpKinds.remove(token)) {
      _suggestedFollowUpKinds.add(token);
    }
  }

  /// The proposed codes that are not (yet) in [kFollowUpProcessTokens].
  ///
  /// Not an error — the taxonomy is extensible — but the UI surfaces them so
  /// the reviewer sees that they are proposing to *extend* it, not to pick.
  List<String> get unknownFollowUpKinds => [
        for (final kind in _suggestedFollowUpKinds)
          if (!kFollowUpProcessTokens.contains(kind)) kind,
      ];

  bool get hasUnknownFollowUpKind => unknownFollowUpKinds.isNotEmpty;

  /// The `CodeSpecPart` kinds the reviewer proposes for this node.
  ///
  /// Read-only by design — every token that gets in passes
  /// [normalizeCodeSpecKindToken] first, so the list cannot hold a value that
  /// fails to map back onto the model.
  List<String> get suggestedCodeSpecKinds =>
      List.unmodifiable(_suggestedCodeSpecKinds);

  set suggestedCodeSpecKinds(List<String> kinds) {
    // Normalise the whole list before assigning: a rejected token must leave
    // the entry as it was rather than half-applied.
    _suggestedCodeSpecKinds =
        kinds.map(normalizeCodeSpecKindToken).toList();
  }

  /// Adds [kind] if absent, removes it if present.
  void toggleSuggestedCodeSpecKind(String kind) {
    final token = normalizeCodeSpecKindToken(kind);
    if (!_suggestedCodeSpecKinds.remove(token)) {
      _suggestedCodeSpecKinds.add(token);
    }
  }

  /// Whether this entry carries any information worth persisting.
  bool get isEmpty =>
      scope == ReviewScope.none &&
      !stopHere &&
      !addDetails &&
      !mustBeList &&
      !singleEntry &&
      !mustBeContentString &&
      !convertFormToContent &&
      !reviewed &&
      !codeSpecKindMissing &&
      !codeSpecKindWrong &&
      !notCodeSpecs &&
      destination == ReviewDestination.unset &&
      !followUpKindMissing &&
      !followUpKindWrong &&
      !noArtifactMissing &&
      !noArtifactWrong &&
      !noArtifactReasonWrong &&
      suggestedNoArtifactReason == null &&
      !shouldBeOneOf &&
      !caseSetIncomplete &&
      !idPatternWrong &&
      !handoffWrong &&
      !contentTypeWrong &&
      !standardRefWrong &&
      !standardRefMissing &&
      !_unusedConfirmed &&
      !_unusedRejected &&
      _suggestedCodeSpecKinds.isEmpty &&
      _suggestedFollowUpKinds.isEmpty &&
      comment.trim().isEmpty;

  /// The persisted form of this entry — the write counterpart of [fromMap], and
  /// the single source `ReviewStore` emits from.
  ///
  /// Every axis is threaded through exactly one writer, because it was
  /// previously threaded through two: this map and a hand-written YAML builder
  /// that repeated the same key list. Two writers for one schema is one that
  /// can be forgotten, and a forgotten writer loses a reviewer's judgement
  /// silently.
  Map<String, Object?> toMap() => {
        'scope': scope.token,
        if (stopHere) 'stop_here': true,
        if (addDetails) 'add_details': true,
        if (mustBeList) 'must_be_list': true,
        if (singleEntry) 'single_entry': true,
        if (mustBeContentString) 'must_be_content_string': true,
        if (convertFormToContent) 'convert_form_to_content': true,
        if (reviewed) 'reviewed': true,
        if (codeSpecKindMissing) 'code_spec_kind_missing': true,
        if (codeSpecKindWrong) 'code_spec_kind_wrong': true,
        if (notCodeSpecs) 'not_code_specs': true,
        if (destination != ReviewDestination.unset)
          'destination': destination.token,
        if (followUpKindMissing) 'follow_up_kind_missing': true,
        if (followUpKindWrong) 'follow_up_kind_wrong': true,
        if (noArtifactMissing) 'no_artifact_missing': true,
        if (noArtifactWrong) 'no_artifact_wrong': true,
        if (noArtifactReasonWrong) 'no_artifact_reason_wrong': true,
        if (suggestedNoArtifactReason != null)
          'suggested_no_artifact_reason': suggestedNoArtifactReason!.name,
        if (shouldBeOneOf) 'should_be_one_of': true,
        if (caseSetIncomplete) 'case_set_incomplete': true,
        if (idPatternWrong) 'id_pattern_wrong': true,
        if (handoffWrong) 'handoff_wrong': true,
        if (contentTypeWrong) 'content_type_wrong': true,
        if (standardRefWrong) 'standard_ref_wrong': true,
        if (standardRefMissing) 'standard_ref_missing': true,
        if (_unusedConfirmed) 'unused_confirmed': true,
        if (_unusedRejected) 'unused_rejected': true,
        if (_suggestedCodeSpecKinds.isNotEmpty)
          'suggested_code_spec_kinds': List<String>.of(_suggestedCodeSpecKinds),
        if (_suggestedFollowUpKinds.isNotEmpty)
          'suggested_follow_up_kinds': List<String>.of(_suggestedFollowUpKinds),
        if (comment.trim().isNotEmpty) 'comment': comment.trim(),
      };

  factory ReviewEntry.fromMap(Map map) => ReviewEntry(
        scope: ReviewScope.parse(map['scope'] as String?),
        stopHere: map['stop_here'] == true,
        addDetails: map['add_details'] == true,
        mustBeList: map['must_be_list'] == true,
        singleEntry: map['single_entry'] == true,
        mustBeContentString: map['must_be_content_string'] == true,
        convertFormToContent: map['convert_form_to_content'] == true,
        reviewed: map['reviewed'] == true,
        codeSpecKindMissing: map['code_spec_kind_missing'] == true,
        codeSpecKindWrong: map['code_spec_kind_wrong'] == true,
        notCodeSpecs: map['not_code_specs'] == true,
        destination: ReviewDestination.parse(map['destination'] as String?),
        followUpKindMissing: map['follow_up_kind_missing'] == true,
        followUpKindWrong: map['follow_up_kind_wrong'] == true,
        noArtifactMissing: map['no_artifact_missing'] == true,
        noArtifactWrong: map['no_artifact_wrong'] == true,
        noArtifactReasonWrong: map['no_artifact_reason_wrong'] == true,
        suggestedNoArtifactReason: parseNoArtifactReason(
            map['suggested_no_artifact_reason'] as String?),
        shouldBeOneOf: map['should_be_one_of'] == true,
        caseSetIncomplete: map['case_set_incomplete'] == true,
        idPatternWrong: map['id_pattern_wrong'] == true,
        handoffWrong: map['handoff_wrong'] == true,
        contentTypeWrong: map['content_type_wrong'] == true,
        standardRefWrong: map['standard_ref_wrong'] == true,
        standardRefMissing: map['standard_ref_missing'] == true,
        unusedConfirmed: map['unused_confirmed'] == true,
        unusedRejected: map['unused_rejected'] == true,
        suggestedCodeSpecKinds: _kindsFromYaml(map['suggested_code_spec_kinds']),
        suggestedFollowUpKinds:
            _followUpKindsFromYaml(map['suggested_follow_up_kinds']),
        comment: (map['comment'] as String?) ?? '',
      );

  /// Reads the suggested-kind list off a file, dropping anything unrecognised.
  ///
  /// Reading is deliberately lenient where entry is strict: a token typo'd by
  /// hand should cost that one suggestion, not make the whole review file
  /// unloadable.
  static List<String> _kindsFromYaml(Object? raw) {
    if (raw is! Iterable) return const [];
    return [
      for (final item in raw) ?tryNormalizeCodeSpecKindToken(item.toString()),
    ];
  }

  /// Reads the suggested follow-up list off a file.
  ///
  /// Only blanks are dropped — an unrecognised code is kept, because the
  /// taxonomy is extensible and the proposal to extend it is the finding.
  static List<String> _followUpKindsFromYaml(Object? raw) {
    if (raw is! Iterable) return const [];
    return [
      for (final item in raw)
        if (item.toString().trim().isNotEmpty)
          normalizeFollowUpKindToken(item.toString()),
    ];
  }
}

/// Holds all review entries and persists them to a YAML file on every edit.
///
/// The store is keyed by structural path so a reviewer's decision can later be
/// mapped straight back onto the object model for rework. Saving happens
/// synchronously after each mutation — the data set is small (one entry per
/// reviewed node) and the guarantee that nothing is lost on crash is worth more
/// than micro-optimising writes.
class ReviewStore extends ChangeNotifier {
  final File file;
  final Map<String, ReviewEntry> _entries = {};

  ReviewStore(this.file);

  /// Resolves the review file location. Honors `TOM_SPECS_REVIEW_FILE`; falls
  /// back to `<cwd>/review/structure_review.yaml`.
  factory ReviewStore.resolveDefault() {
    final override = Platform.environment['TOM_SPECS_REVIEW_FILE'];
    final path = (override != null && override.isNotEmpty)
        ? override
        : p.join(Directory.current.path, 'review', 'structure_review.yaml');
    return ReviewStore(File(path));
  }

  /// Number of non-empty review entries currently held.
  int get count => _entries.length;

  /// Loads entries from disk if the file exists. Safe to call once at startup.
  void load() {
    if (!file.existsSync()) return;
    final content = file.readAsStringSync();
    if (content.trim().isEmpty) return;
    final doc = loadYaml(content);
    if (doc is! YamlMap) return;
    final entries = doc['entries'];
    if (entries is! YamlMap) return;
    _entries.clear();
    entries.forEach((key, value) {
      if (value is YamlMap) {
        _entries[key.toString()] = ReviewEntry.fromMap(value);
      }
    });
  }

  /// Returns the entry for [path], or `null` if none has been recorded.
  ReviewEntry? entryFor(String path) => _entries[path];

  /// Returns the entry for [path], creating an empty one if absent. The
  /// returned object is *not* yet stored — call [update] to persist edits.
  ReviewEntry entryOrNew(String path) =>
      _entries[path] ?? ReviewEntry();

  /// Applies [mutate] to the entry at [path] and persists immediately.
  ///
  /// If the resulting entry is empty it is removed (keeping the file tidy and
  /// the reverse mapping unambiguous).
  void update(String path, void Function(ReviewEntry) mutate) {
    final entry = _entries[path] ?? ReviewEntry();
    mutate(entry);
    if (entry.isEmpty) {
      _entries.remove(path);
    } else {
      _entries[path] = entry;
    }
    _save();
    notifyListeners();
  }

  void _save() {
    final buffer = StringBuffer()
      ..writeln('# TomSpecs structure review.')
      ..writeln('# Keyed by structural path into the specification object '
          'model.')
      ..writeln('# Generated by tom_specs_reviewer — edit via the app.')
      ..writeln('version: $kReviewFileVersion')
      ..writeln('entries:');

    final keys = _entries.keys.toList()..sort();
    if (keys.isEmpty) {
      // Keep `entries:` as an empty map for a valid, round-trippable document.
      buffer.writeln('  {}');
    }
    for (final key in keys) {
      buffer.writeln('  ${_yamlString(key)}:');
      _entries[key]!.toMap().forEach((field, value) {
        buffer.writeln('    $field: ${_yamlValue(value)}');
      });
    }

    file.parent.createSync(recursive: true);
    file.writeAsStringSync(buffer.toString());
  }

  /// Renders one [ReviewEntry.toMap] value as a YAML scalar or flow sequence.
  ///
  /// Strings are quoted unconditionally — including the closed tokens, which
  /// would survive bare. A free-text comment reading `true` or `12` must not
  /// come back off disk as a bool or an int, and no rule that inspects the
  /// *value* can tell that comment from a token; only a rule that quotes every
  /// string is safe by construction.
  String _yamlValue(Object? value) {
    if (value is String) return _yamlString(value);
    if (value is List) {
      return '[${value.map((e) => _yamlString(e.toString())).join(', ')}]';
    }
    return '$value';
  }

  /// Double-quotes and escapes a string for safe YAML emission.
  String _yamlString(String value) {
    final escaped = value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\t', '\\t');
    return '"$escaped"';
  }
}
