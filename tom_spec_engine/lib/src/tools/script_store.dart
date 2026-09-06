/// Persistence port for authored D4rt scripts (`llm_and_d4rt_tools.md` §8.1).
///
/// `script_author` writes named `*.d4rt.dart` files into the curated
/// **`agent/scripts/`** workspace directory so they are reviewable, re-runnable,
/// and diffable. [ScriptStore] is the engine-side port over that storage; the
/// default [FileScriptStore] writes real files, and a test (or an in-memory
/// editor binding) can substitute its own implementation.
/// @docImport 'script_tools.dart';
library;

import 'dart:io';

/// The `.d4rt.dart` file-name suffix every stored script carries.
const String scriptFileSuffix = '.d4rt.dart';

/// Stores, reads, and enumerates authored scripts by name.
///
/// A *name* is the script's identity (a single path segment); implementations
/// map it to concrete storage. [store] persists or replaces a script's full
/// file contents (header + source) and returns its path.
abstract interface class ScriptStore {
  /// Persists [contents] under [name], replacing any existing script; returns
  /// the stored path.
  String store(String name, String contents);

  /// Whether a script named [name] exists.
  bool exists(String name);

  /// The full stored contents of [name], or `null` when absent.
  String? read(String name);

  /// The names of all stored scripts (sorted).
  List<String> names();

  /// The path a script named [name] maps to (whether or not it exists).
  String pathOf(String name);
}

/// A [ScriptStore] backed by real files under `<workspaceRoot>/agent/scripts/`.
///
/// The directory is created lazily on first [store]. Names are mapped to
/// `<name>$scriptFileSuffix`; [ScriptTools] is responsible for rejecting unsafe
/// names before they reach the store, so this implementation does plain joins.
final class FileScriptStore implements ScriptStore {
  /// Creates a store rooted at [workspaceRoot] (the `agent/scripts/` subtree is
  /// resolved beneath it).
  FileScriptStore(this.workspaceRoot);

  /// The workspace root the `agent/scripts/` directory lives under.
  final String workspaceRoot;

  /// The directory authored scripts are written to.
  String get scriptsDir => '$workspaceRoot/agent/scripts';

  @override
  String pathOf(String name) => '$scriptsDir/$name$scriptFileSuffix';

  @override
  String store(String name, String contents) {
    Directory(scriptsDir).createSync(recursive: true);
    final file = File(pathOf(name))..writeAsStringSync(contents);
    return file.path;
  }

  @override
  bool exists(String name) => File(pathOf(name)).existsSync();

  @override
  String? read(String name) {
    final file = File(pathOf(name));
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  @override
  List<String> names() {
    final dir = Directory(scriptsDir);
    if (!dir.existsSync()) return const [];
    final names = <String>[];
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final base = entity.path.split('/').last;
      if (base.endsWith(scriptFileSuffix)) {
        names.add(base.substring(0, base.length - scriptFileSuffix.length));
      }
    }
    names.sort();
    return names;
  }
}
