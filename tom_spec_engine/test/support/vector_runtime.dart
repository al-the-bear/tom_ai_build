/// The shared **vector-runtime precondition** for the memory-plane suites
/// (§9 / §10).
///
/// `SpecMemory` boots on `SqliteTomBrainMemory`, which refuses to open unless
/// the bundled sqlite-vec (`vec0`) extension registers — vector recall is
/// mandatory, there is no BM25-only fallback. Whether that registration can
/// succeed is a property of the **host process**, not of the engine:
///
///   * the packaged `vec0` binary must exist under `tom_binaries/sqlite_vec`
///     for the running platform, **and**
///   * the `libsqlite3` the process resolves must support extension loading.
///
/// The second condition is the one that is easy to get wrong. `package:sqlite3`
/// resolves the platform's SQLite, and on **macOS** that is Apple's system
/// build, compiled with `SQLITE_OMIT_LOAD_EXTENSION` — it exports neither
/// `sqlite3_load_extension` nor `sqlite3_enable_load_extension`, and
/// `sqlite3_auto_extension` answers `SQLITE_MISUSE` (21). A bare `dart test`
/// there therefore has **no** vector runtime however healthy the `vec0` dylib
/// is. On Linux the distro `libsqlite3.so` normally does support extension
/// loading, and a Flutter desktop host bundles its own full SQLite, so both of
/// those *do* have one.
///
/// Because availability is a host property, the gate has to be a **probe**, not
/// a proxy: [VectorRuntime.probe] runs the real
/// [VecExtensionLoader] pipeline once and reports the outcome. Testing only for
/// the binary's *presence* would pass on macOS — where the file is present and
/// the load still fails — and turn a stated precondition into 15 red tests.
library;

import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:tom_brain_memory/tom_brain_memory.dart';

/// The probed vector-runtime state of the current test process.
///
/// Probed once per test isolate (each test file is its own isolate), so the
/// four memory-plane suites pay a single load attempt each.
final VectorRuntime vectorRuntime = VectorRuntime.probe();

/// Whether this process can serve vector recall, and where its `vec0` binaries
/// live.
///
/// Exposes the two preconditions **separately**, because they are not the same
/// question and different tests need different ones:
///
///   * [binariesSkipReason] — is a packaged `vec0` binary present? A test that
///     only needs to *construct* a `SpecMemory` (for its embedding surface,
///     say) needs the path, not a working runtime.
///   * [skipReason] — can the extension actually register? Everything that
///     opens the store needs this, and it is strictly stronger.
class VectorRuntime {
  /// The `tom_binaries/sqlite_vec` directory found by walking up from the
  /// working directory, or `null` when the tree carries no packaged binaries.
  final String? binariesRoot;

  /// `null` when the vector runtime is live — pass it straight to a test's
  /// `skip:`. Otherwise the reason the runtime is unavailable, phrased so a
  /// skipped test states its precondition instead of hiding it.
  final String? skipReason;

  const VectorRuntime._(this.binariesRoot, this.skipReason);

  /// `true` when [skipReason] is `null`.
  bool get isAvailable => skipReason == null;

  /// `null` when a packaged `vec0` binary was found — the weaker precondition,
  /// for tests that need [requireBinariesRoot] but never open the store.
  String? get binariesSkipReason => binariesRoot == null ? skipReason : null;

  /// [binariesRoot], asserted non-null. Safe inside a test gated on
  /// [binariesSkipReason] (or the stronger [skipReason]); throws otherwise, so
  /// a missing gate fails loudly instead of dereferencing null.
  String get requireBinariesRoot {
    final root = binariesRoot;
    if (root == null) {
      throw StateError('No packaged vec0 binaries; gate on binariesSkipReason '
          'first. ($skipReason)');
    }
    return root;
  }

  /// Locates the packaged binaries and then **actually attempts the load**.
  ///
  /// On success `vec0` is registered through `sqlite3_auto_extension` on the
  /// process-wide `sqlite3` instance — the same registration
  /// `SqliteTomBrainMemory.open` performs later. SQLite de-duplicates identical
  /// entry points, so probing first costs nothing and changes no behaviour.
  factory VectorRuntime.probe() {
    final root = _findSqliteVecRoot();
    if (root == null) {
      return const VectorRuntime._(
          null,
          'No packaged vec0 binary found under tom_binaries/sqlite_vec — the '
              'memory store refuses to boot without it.');
    }

    final result = VecExtensionLoader().load(
      sqlite: sqlite3,
      config: MemoryConfig.forTesting(
        root: Directory.systemTemp.path,
        binariesRoot: root,
      ),
    );
    if (result.isLoaded) return VectorRuntime._(root, null);

    return VectorRuntime._(
        root,
        'No vector runtime in this process: the packaged vec0 binary is '
            'present but did not register (${result.reason?.name}). '
            '${result.summary} — see README "Vector runtime precondition".');
  }
}

/// Walks up from the working directory looking for `tom_binaries/sqlite_vec`.
String? _findSqliteVecRoot() {
  var dir = Directory.current.absolute;
  for (var i = 0; i < 10; i++) {
    final candidate = Directory('${dir.path}${Platform.pathSeparator}'
        'tom_binaries${Platform.pathSeparator}sqlite_vec');
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}
