/// The shared **vector-runtime precondition** for the memory-plane suites
/// (§9 / §10).
///
/// `SpecMemory` boots on `SqliteTomBrainMemory`, which refuses to open unless
/// the bundled sqlite-vec (`vec0`) extension registers — vector recall is
/// mandatory, there is no BM25-only fallback. Whether that registration can
/// succeed is a property of the **host process**, not of the engine, so the
/// precondition and its repair belong to the package that owns the store.
/// They live there: `VectorRuntimeProbe` and `SqliteHostLibrary` in
/// `package:tom_brain_memory`, documented under README "Vector runtime
/// precondition". This file is the engine-side name for them, nothing more —
/// the logic used to be duplicated here and no longer is.
///
/// Two things are worth knowing without opening that README:
///
///   * **The repair is production behaviour, not test support.** Reaching
///     `SqliteTomBrainMemory` at all installs it, because the package ships
///     `bin/memory_mcp_server.dart` — a plain-Dart-VM host that hits the same
///     wall on macOS. It is conditional: it only acts where the platform
///     default is *known* to lack extension loading, so a Flutter or Linux
///     host keeps the SQLite it already has.
///   * **This is a probe, not a proxy.** [VectorRuntime.probe] runs the real
///     load pipeline once. Testing for the packaged binary's *presence* would
///     pass on macOS — where the file is there and the load still fails — and
///     put a green gate in front of a red test.
///
/// The two preconditions stay separate because they are different questions:
/// [VectorRuntime.binariesSkipReason] asks whether a `vec0` binary is
/// published for this ABI (enough for a test that only needs the path), while
/// [VectorRuntime.skipReason] asks whether it can actually register — strictly
/// stronger, and what anything that opens the store needs.
library;

import 'package:tom_brain_memory/tom_brain_memory.dart';

/// The engine-side name for `package:tom_brain_memory`'s probe.
typedef VectorRuntime = VectorRuntimeProbe;

/// The probed vector-runtime state of the current test process.
///
/// Probed once per test isolate (each test file is its own isolate), so the
/// four memory-plane suites pay a single load attempt each.
final VectorRuntime vectorRuntime = VectorRuntime.probe();
