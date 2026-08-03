import 'package:path/path.dart' as p;

import 'model_version_stamp.dart';

/// The version stamp a `spec_model.json` export is written with.
class ModelJsonStamp {
  const ModelJsonStamp(this.version, this.label);

  /// The `modelVersion` counter.
  final int version;

  /// The `modelVersionLabel`, or `null` when the export carries no label.
  final String? label;

  @override
  String toString() => label == null ? '$version' : '$version ($label)';
}

/// A **committed** `spec_model.json` asset, together with the stamp policy that
/// asset is frozen at.
///
/// `model_json.dart` writes the same class-graph export to two committed
/// locations that must carry *different* stamps. Nothing used to enforce which
/// stamp went where, so a regeneration pass that re-exported "both assets" with
/// one command silently rewrote one of them at the other's version — which is
/// how the editor's copy ended up at `modelVersion: 0`.
///
/// Naming the target instead of the stamp removes the choice: the caller says
/// *which asset*, and the stamp follows from that. Ad-hoc exports to any other
/// path stay freely stampable; only these two paths are governed.
enum ModelJsonTarget {
  /// The spec-authoring app's bundled asset. Refreshed by `bin/build.dart`
  /// (step 3) and stamped from the model's `version.versioner.dart`, so it
  /// tracks the same build as the SOM metas and the DocSpecs schemas.
  editor(
    'editor',
    'tom_forge/tom_specs_editor/assets/spec_model.json',
    null,
  ),

  /// The object-model review app's committed snapshot. Pinned: refreshing it is
  /// a re-export of the current model, never a renumbering of it, so the stamp
  /// must not move (see the v0 fixed-version policy).
  reviewer(
    'reviewer',
    'tom_ai/ai_build/tom_specs_reviewer/assets/spec_model.json',
    ModelJsonStamp(9, '1.0.0+9'),
  );

  const ModelJsonTarget(this.id, this.containerRelativePath, this.pinnedStamp);

  /// The `--target` value naming this asset.
  final String id;

  /// The asset's path relative to the workspace container root, in POSIX form.
  final String containerRelativePath;

  /// The stamp this target is frozen at, or `null` when it takes the stamp
  /// derived from the model's version stamp.
  final ModelJsonStamp? pinnedStamp;

  /// This target's asset path inside the workspace rooted at [containerRoot].
  String outputPathIn(String containerRoot) => p.normalize(
      p.join(containerRoot, p.joinAll(p.posix.split(containerRelativePath))));

  /// The stamp to write, given the model's parsed [versioner] stamp.
  ModelJsonStamp stampFrom(ModelVersionStamp versioner) =>
      pinnedStamp ?? ModelJsonStamp(versioner.majorVersion, versioner.label);

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
