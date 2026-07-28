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
/// resolves the platform's SQLite, and on **macOS** the default resolution ends
/// at Apple's system build, compiled with `SQLITE_OMIT_LOAD_EXTENSION` — it
/// exports neither `sqlite3_load_extension` nor `sqlite3_enable_load_extension`,
/// and `sqlite3_auto_extension` answers `SQLITE_MISUSE` (21). On Linux the
/// distro `libsqlite3.so` normally does support extension loading, and a
/// Flutter desktop host bundles its own full SQLite via `sqlite3_flutter_libs`,
/// so both of those *do* have a vector runtime out of the box.
///
/// ## The host-library override
///
/// A capable `libsqlite3` is usually already on a developer macOS box —
/// Homebrew's `sqlite` formula builds one with extension loading enabled — it
/// is simply not what `package:sqlite3` resolves by default. So before probing,
/// [VectorRuntime.probe] looks for a capable library and, if it finds one,
/// points `package:sqlite3` at it through the public `open.overrideFor` seam.
/// Search order:
///
///   1. `$TOM_SQLITE3_LIB` — an explicit path, honoured on every platform. This
///      is the escape hatch for a host whose capable library lives somewhere
///      this file does not guess.
///   2. Well-known Homebrew prefixes, on macOS only.
///
/// A candidate is accepted only if it opens **and** exports
/// `sqlite3_enable_load_extension`; otherwise nothing is installed and the
/// default resolution stands. Two properties matter here:
///
///   * The override must be installed **before the first `sqlite3` access** —
///     `package:sqlite3` caches its `Sqlite3` instance on first touch, so an
///     override applied afterwards is silently a no-op. Reading
///     [vectorRuntime] is what triggers the install, which is why every suite
///     reads it at the top of the file.
///   * This is **test support only**. Production is deliberately untouched: the
///     Flutter desktop host already bundles a working SQLite, and overriding
///     there would swap correct behaviour for machine-dependent behaviour.
///
/// ## Probe, not proxy
///
/// Because availability is a host property, the gate has to be a **probe**, not
/// a proxy: [VectorRuntime.probe] runs the real
/// [VecExtensionLoader] pipeline once and reports the outcome. Testing only for
/// the binary's *presence* would pass on macOS — where the file is present and
/// the load still fails — and turn a stated precondition into 15 red tests.
/// The override above does not weaken that: it changes which library is
/// resolved, then the real load still has to succeed.
library;

import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';
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

  /// The `libsqlite3` installed by the host-library override, or `null` when
  /// the platform default was left in place. Diagnostic only — it tells you
  /// *why* the same tree behaves differently on two macOS boxes.
  final String? hostSqliteLibrary;

  const VectorRuntime._(this.binariesRoot, this.skipReason,
      [this.hostSqliteLibrary]);

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

  /// Installs the host-library override, locates the packaged binaries and then
  /// **actually attempts the load**.
  ///
  /// On success `vec0` is registered through `sqlite3_auto_extension` on the
  /// process-wide `sqlite3` instance — the same registration
  /// `SqliteTomBrainMemory.open` performs later. SQLite de-duplicates identical
  /// entry points, so probing first costs nothing and changes no behaviour.
  factory VectorRuntime.probe() {
    // Must precede every `sqlite3` touch below: the instance is cached on first
    // access, so a later override would be a no-op.
    final hostLibrary = _installHostSqliteOverride();

    final root = _findSqliteVecRoot();
    if (root == null) {
      return VectorRuntime._(
          null,
          'No packaged vec0 binary found under tom_binaries/sqlite_vec — the '
              'memory store refuses to boot without it.',
          hostLibrary);
    }

    final result = VecExtensionLoader().load(
      sqlite: sqlite3,
      config: MemoryConfig.forTesting(
        root: Directory.systemTemp.path,
        binariesRoot: root,
      ),
    );
    if (result.isLoaded) return VectorRuntime._(root, null, hostLibrary);

    return VectorRuntime._(
        root,
        'No vector runtime in this process: the packaged vec0 binary is '
            'present but did not register (${result.reason?.name}). '
            '${result.summary} — the resolved libsqlite3 '
            '(${hostLibrary ?? 'platform default'}) most likely lacks extension '
            'loading; set TOM_SQLITE3_LIB to one that has it. See README '
            '"Vector runtime precondition".',
        hostLibrary);
  }
}

/// Path of the library [_openHostSqlite] opens, set by
/// [_installHostSqliteOverride] before the override is registered.
///
/// A top-level pair rather than a closure because `package:sqlite3` requires
/// the open function to be top-level or static for its isolate API.
String? _hostSqlitePath;

DynamicLibrary _openHostSqlite() => DynamicLibrary.open(_hostSqlitePath!);

/// Points `package:sqlite3` at a `libsqlite3` that supports extension loading,
/// when the platform default might not.
///
/// Returns the installed path, or `null` when no capable candidate was found
/// and the platform default was left alone.
String? _installHostSqliteOverride() {
  final os = open.os;
  if (os == null) return null;

  for (final candidate in _hostSqliteCandidates()) {
    if (!_supportsExtensionLoading(candidate)) continue;
    _hostSqlitePath = candidate;
    open.overrideFor(os, _openHostSqlite);
    return candidate;
  }
  return null;
}

/// Candidate `libsqlite3` paths, most specific first.
Iterable<String> _hostSqliteCandidates() sync* {
  final configured = Platform.environment['TOM_SQLITE3_LIB'];
  if (configured != null && configured.isNotEmpty) yield configured;

  if (!Platform.isMacOS) return;
  // Homebrew's `sqlite` formula builds with extension loading enabled; Apple's
  // system SQLite does not. Apple Silicon prefix first, then Intel.
  yield '/opt/homebrew/opt/sqlite/lib/libsqlite3.dylib';
  yield '/usr/local/opt/sqlite/lib/libsqlite3.dylib';
}

/// Whether [path] opens and exports the extension-loading entry points.
bool _supportsExtensionLoading(String path) {
  if (!File(path).existsSync()) return false;
  try {
    return DynamicLibrary.open(path)
        .providesSymbol('sqlite3_enable_load_extension');
    // ignore: avoid_catching_errors
  } on ArgumentError {
    return false;
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
