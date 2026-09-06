import 'package:path/path.dart' as p;

import 'model_version_stamp.dart';

/// The version stamp a `spec_model.json` export is written with.
///
/// [version] is the model **major**, and [label] the build it was generated
/// from. The two are not independent: `version` is by definition the major
/// component of `label`, so a stamp whose parts disagree describes no model
/// that ever existed. [from] is the only derivation that can produce a
/// consistent pair, which is why every committed artifact goes through it.
class ModelJsonStamp {
  /// Records a version/label pair directly.
  ///
  /// Prefer `ModelJsonStamp.from`, which derives both from one versioner stamp
  /// and so cannot produce the inconsistent pair this constructor allows. This
  /// one exists for tests and for reading a stamp back off disk.
  const ModelJsonStamp(this.version, this.label);

  /// The stamp describing the model build [versioner] was generated from.
  ModelJsonStamp.from(ModelVersionStamp versioner)
      : version = versioner.majorVersion,
        label = versioner.label;

  /// The `modelVersion` counter: the model major.
  final int version;

  /// The `modelVersionLabel`, or `null` when the export carries no label.
  final String? label;

  @override
  String toString() => label == null ? '$version' : '$version ($label)';
}

/// The model major [label] declares, or `null` when it declares none.
///
/// The inverse of the [ModelJsonStamp.from] derivation, used to check a stamp
/// found on disk against itself: `modelVersion` must be the major of
/// `modelVersionLabel`.
int? modelMajorOfLabel(String? label) {
  if (label == null || label.isEmpty) return null;
  return int.tryParse(label.split('+').first.split('.').first.trim());
}

/// A **committed** `spec_model.json` asset.
///
/// `model_json.dart` writes the same class-graph export to two committed
/// locations. Nothing used to pair a destination with a stamp, so a regeneration
/// pass that re-exported "both assets" with one command silently rewrote one of
/// them at the other's version — which is how the editor's copy ended up at
/// `modelVersion: 0`.
///
/// Naming the target instead of the stamp removes the choice: the caller says
/// *which asset*, and both the path and the stamp follow from that. Ad-hoc
/// exports to any other path stay freely stampable; only these two paths are
/// governed.
///
/// Both targets take the **same** stamp, derived from the model's
/// `version.versioner.dart` — the two assets are one export of one model, so
/// they can only honestly claim one version. A per-target pin used to exist and
/// is deliberately gone: it recorded the build *number* in the model *major*
/// slot, so the asset disagreed with its own label about which model it
/// described and reported a build it had not been generated from.
enum ModelJsonTarget {
  /// The spec-authoring app's bundled asset. Refreshed by `bin/build.dart`
  /// (step 3), so it tracks the same build as the SOM metas and the DocSpecs
  /// schemas.
  editor(
    'editor',
    'tom_forge/tom_specs_editor/assets/spec_model.json',
  ),

  /// The object-model review app's committed snapshot, refreshed periodically.
  /// Refreshing it is a re-export of the current model, never a renumbering of
  /// it — which the derived stamp expresses exactly, since the major stays put
  /// while the label records the build the snapshot was taken from.
  reviewer(
    'reviewer',
    'tom_ai/ai_build/tom_specs_reviewer/assets/spec_model.json',
  );

  /// Binds a `--target` id to the committed asset path it writes.
  const ModelJsonTarget(this.id, this.containerRelativePath);

  /// The `--target` value naming this asset.
  final String id;

  /// The asset's path relative to the workspace container root, in POSIX form.
  final String containerRelativePath;

  /// This target's asset path inside the workspace rooted at [containerRoot].
  String outputPathIn(String containerRoot) => p.normalize(
      p.join(containerRoot, p.joinAll(p.posix.split(containerRelativePath))));

  /// The target named [id], or `null` when [id] names no committed asset.
  static ModelJsonTarget? byId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// The committed target [outputPath] refers to, or `null` when it is an
/// ad-hoc export location.
///
/// Matched on the path *suffix* rather than against a resolved container root,
/// so the guard holds regardless of where the workspace is checked out or which
/// package the export was launched from.
ModelJsonTarget? targetForOutputPath(String outputPath) {
  final normalized = p.split(p.normalize(p.absolute(outputPath)));
  for (final target in ModelJsonTarget.values) {
    final wanted = p.posix.split(target.containerRelativePath);
    if (normalized.length < wanted.length) continue;
    final tail = normalized.sublist(normalized.length - wanted.length);
    var matches = true;
    for (var i = 0; i < wanted.length; i++) {
      if (tail[i] != wanted[i]) {
        matches = false;
        break;
      }
    }
    if (matches) return target;
  }
  return null;
}
