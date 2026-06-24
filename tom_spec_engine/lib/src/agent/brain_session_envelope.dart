/// The Tom Brain **session envelope** for §10 mode (b) (plan step 16).
///
/// Mode (b) ([BrainAgentSubstrate]) drives the *same* complex agent procedure as
/// mode (a), but wraps each run in Tom Brain's isolation envelope — a **profile**
/// (the application), a **named session** (the phase/task run), and a **named
/// memory** (the document) — and records the run into that named memory. That
/// envelope is what distinguishes the two modes; the loop body is identical.
///
/// [BrainSessionEnvelope] is the seam at which that envelope plugs in. The
/// substrate hands it a [MemoryScope] (the application→profile / session→named
/// session / document→named memory addressing already established for the memory
/// plane, plan step 2) and the loop body; the envelope opens the session, runs
/// the body, records the run, and closes the session. Keeping it an injected
/// port lets the headless "same loop test" run host-independently against
/// [RecordingBrainEnvelope] while the concrete `tom_brain_memory`-backed
/// envelope (live profile registry + named-memory run trail) is wired where the
/// editor composes the agent plane — exactly as the memory plane (steps 2/10/11)
/// injects its store/embedder ports.
library;

import 'agent_substrate.dart';
import '../memory/memory_scope.dart';

/// One recorded agent run inside a Tom Brain named memory (the run trail).
final class BrainRunRecord {
  /// The Tom Brain addressing the run executed under.
  final MemoryScope scope;

  /// The task the run was given.
  final AgentTask task;

  /// The run's captured result.
  final AgentRunResult result;

  /// Creates a record.
  const BrainRunRecord({
    required this.scope,
    required this.task,
    required this.result,
  });
}

/// Wraps an agent run in a Tom Brain profile + named session + named memory.
abstract interface class BrainSessionEnvelope {
  /// Opens a Tom Brain session for [scope], runs [body] (the loop), records the
  /// run (the [task] plus the body's result) into the scope's named memory, and
  /// closes the session — returning the run's [AgentRunResult].
  ///
  /// The result is always recorded, whether the loop succeeded, reported a
  /// model-rejected edit, or threw (a thrown procedure surfaces as
  /// `ok: false`); the envelope never swallows the body's outcome.
  Future<AgentRunResult> runInSession(
    MemoryScope scope,
    AgentTask task,
    Future<AgentRunResult> Function() body,
  );
}

/// An in-memory [BrainSessionEnvelope] that records the sessions it opens and
/// the runs it captures.
///
/// This is the host-independent realisation used by the headless "same loop
/// test": it models the Tom Brain envelope (open session for the scope → run →
/// record the run into named memory → close) without a live profile registry or
/// vector store, exposing the opened sessions and the run trail for assertion. A
/// `tom_brain_memory`-backed envelope persists the same [BrainRunRecord]s as
/// nodes in the document's named memory.
final class RecordingBrainEnvelope implements BrainSessionEnvelope {
  /// The scopes sessions were opened for, in order.
  final List<MemoryScope> openedSessions = [];

  /// The runs recorded into named memory, in order (the run trail).
  final List<BrainRunRecord> runs = [];

  @override
  Future<AgentRunResult> runInSession(
    MemoryScope scope,
    AgentTask task,
    Future<AgentRunResult> Function() body,
  ) async {
    openedSessions.add(scope);
    final result = await body();
    runs.add(BrainRunRecord(scope: scope, task: task, result: result));
    return result;
  }
}
