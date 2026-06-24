/// The `files` base scope and the D4rt bridge for its [SpecFileFacade] (§7,
/// plan step 8).
///
/// [filesScope] builds the [ScriptScope] that exposes the audited file facade —
/// and nothing else — to a sandboxed script: one `spec_files` bridged-library
/// block that registers the [SpecFileFacade] bridge and injects a single
/// facade-bound `files` global under [specFilesLibrary]. The raw `dcli` /
/// `dart:io` write surface is deliberately **not** bridged, so the facade's
/// read-anywhere / write-whitelist policy is the only file surface available.
///
/// The scope also grants the D4rt permission system `read=any` plus a
/// `write=<dir>` for each writable root, as the §7 defence-in-depth backstop.
/// The facade's own path canonicalisation is the primary (and, since only the
/// facade is bridged, the operative) enforcement; the grants matter the moment
/// any raw filesystem surface is ever added to the scope.
library;

import 'package:tom_d4rt/tom_d4rt.dart';

import 'scope.dart';
import 'spec_file_facade.dart';

/// The library URI a script imports to reach the injected `files` global (and
/// the `SpecFileFacade` type).
const String specFilesLibrary = 'package:tom_spec_engine/spec_files.dart';

/// The name of the injected file-facade global (`files`).
const String specFilesGlobalName = 'files';

/// The de-duplication name of the `spec_files` bridged-library block.
const String specFilesLibraryName = 'spec_files';

/// The conventional name of the `files` base scope.
const String filesScopeName = 'files';

/// Builds the `files` scope bound to [facade].
///
/// [name] defaults to [filesScopeName]. The scope's grants are derived from the
/// facade's whitelist: `read=any` + one `write=<root>` per writable root.
ScriptScope filesScope(SpecFileFacade facade, {String name = filesScopeName}) {
  return ScriptScope(
    name: name,
    libraries: [
      BridgedLibrary(specFilesLibraryName, (interpreter) {
        interpreter.registerBridgedClass(
            specFileFacadeBridgedClass(), specFilesLibrary);
        interpreter.registerGlobalVariable(
            specFilesGlobalName, facade, specFilesLibrary);
      }),
    ],
    grants: [
      FilesystemPermission.read,
      for (final root in facade.writableRoots)
        FilesystemPermission.writePath(root),
    ],
  );
}

/// The [BridgedClass] exposing [SpecFileFacade]'s methods to a D4rt script.
///
/// `SpecFileFacade` is never constructed from a script (the `files` scope
/// injects a single facade-bound instance), so the bridge declares no
/// constructors — only the read and whitelist-guarded write methods.
BridgedClass specFileFacadeBridgedClass() => BridgedClass(
      nativeType: SpecFileFacade,
      name: 'SpecFileFacade',
      isAssignable: (v) => v is SpecFileFacade,
      methods: {
        // read — any path
        'readText': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecFileFacade).readText(positionalArgs[0] as String),
        'readLines': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecFileFacade).readLines(positionalArgs[0] as String),
        'head': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecFileFacade).head(positionalArgs[0] as String,
                lines: (namedArgs['lines'] as int?) ?? 10),
        'tail': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecFileFacade).tail(positionalArgs[0] as String,
                lines: (namedArgs['lines'] as int?) ?? 10),
        'exists': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecFileFacade).exists(positionalArgs[0] as String),
        'stat': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecFileFacade).stat(positionalArgs[0] as String),
        'find': (visitor, target, positionalArgs, namedArgs, _) =>
            (target as SpecFileFacade).find(positionalArgs[0] as String,
                glob: namedArgs['glob'] as String?,
                includeAssets: (namedArgs['includeAssets'] as bool?) ?? false),
        // write — whitelist only
        'writeText': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecFileFacade).writeText(
              positionalArgs[0] as String, positionalArgs[1] as String);
          return null;
        },
        'append': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecFileFacade).append(
              positionalArgs[0] as String, positionalArgs[1] as String);
          return null;
        },
        'createDir': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecFileFacade).createDir(positionalArgs[0] as String);
          return null;
        },
        'copy': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecFileFacade).copy(
              positionalArgs[0] as String, positionalArgs[1] as String);
          return null;
        },
        'move': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecFileFacade).move(
              positionalArgs[0] as String, positionalArgs[1] as String);
          return null;
        },
        'delete': (visitor, target, positionalArgs, namedArgs, _) {
          (target as SpecFileFacade).delete(positionalArgs[0] as String);
          return null;
        },
      },
    );
