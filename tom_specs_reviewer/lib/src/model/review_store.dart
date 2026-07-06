import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

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

  String comment;

  ReviewEntry({
    this.scope = ReviewScope.none,
    this.stopHere = false,
    this.addDetails = false,
    this.mustBeList = false,
    this.singleEntry = false,
    this.mustBeContentString = false,
    this.convertFormToContent = false,
    this.reviewed = false,
    this.comment = '',
  });

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
      comment.trim().isEmpty;

  Map<String, Object?> toMap() => {
        'scope': scope.token,
        if (stopHere) 'stop_here': true,
        if (addDetails) 'add_details': true,
        if (mustBeList) 'must_be_list': true,
        if (singleEntry) 'single_entry': true,
        if (mustBeContentString) 'must_be_content_string': true,
        if (convertFormToContent) 'convert_form_to_content': true,
        if (reviewed) 'reviewed': true,
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
        comment: (map['comment'] as String?) ?? '',
      );
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
      ..writeln('version: 1')
      ..writeln('entries:');

    final keys = _entries.keys.toList()..sort();
    if (keys.isEmpty) {
      // Keep `entries:` as an empty map for a valid, round-trippable document.
      buffer.writeln('  {}');
    }
    for (final key in keys) {
      final entry = _entries[key]!;
      buffer.writeln('  ${_yamlString(key)}:');
      buffer.writeln('    scope: ${entry.scope.token}');
      if (entry.stopHere) buffer.writeln('    stop_here: true');
      if (entry.addDetails) buffer.writeln('    add_details: true');
      if (entry.mustBeList) buffer.writeln('    must_be_list: true');
      if (entry.singleEntry) buffer.writeln('    single_entry: true');
      if (entry.mustBeContentString) {
        buffer.writeln('    must_be_content_string: true');
      }
      if (entry.convertFormToContent) {
        buffer.writeln('    convert_form_to_content: true');
      }
      if (entry.reviewed) buffer.writeln('    reviewed: true');
      if (entry.comment.trim().isNotEmpty) {
        buffer.writeln('    comment: ${_yamlString(entry.comment.trim())}');
      }
    }

    file.parent.createSync(recursive: true);
    file.writeAsStringSync(buffer.toString());
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
