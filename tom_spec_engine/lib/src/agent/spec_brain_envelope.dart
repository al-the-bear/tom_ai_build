/// The **live `tom_brain_memory`-backed** session envelope for
/// `llm_and_d4rt_tools.md` §10 mode (b) (`llm_and_d4rt_tools.md` §10 mode b).
///
/// Where [RecordingBrainEnvelope] models the Tom Brain envelope in memory for
/// the host-independent "same loop test", [SpecBrainSessionEnvelope] is the
/// real one: it opens the document's **profile-isolated named memory** (via
/// [SpecMemory.openDocument], `llm_and_d4rt_tools.md` §9) and **persists each
/// run as a node** in it — the run trail the docstring of
/// [BrainSessionEnvelope] promises. The run's [RunEffort] metrics ride on the
/// node's payload, so the trail is queryable ("which runs took longest / failed
/// / produced nothing").
///
/// It changes nothing about the loop body: [BrainAgentSubstrate] drives the
/// identical procedure through the identical host whether the injected envelope
/// is the recording stand-in or this live one. The only difference is where the
/// run trail lands — an in-memory list versus the document's vector store.
/// @docImport 'brain_agent_substrate.dart';
library;

import 'agent_substrate.dart';
import 'brain_session_envelope.dart';
import '../memory/spec_memory.dart';

/// A [BrainSessionEnvelope] that records each run into the document's live,
/// profile-isolated Tom Brain named memory.
///
/// Bound to one [SpecMemory] (the embeddable, in-process store). For each run it
/// opens (materialising on first use) the named memory for the run's
/// [MemoryScope] document, runs the loop body, and persists a **run node**
/// carrying the task goal, the run's outcome, and its [RunEffort] metrics — so
/// the run trail survives across sessions and is recoverable by recall. The
/// same records are also kept in [runs] for direct in-process inspection.
final class SpecBrainSessionEnvelope implements BrainSessionEnvelope {
  /// Creates the envelope over the embeddable [SpecMemory] store.
  SpecBrainSessionEnvelope(this._memory);

  final SpecMemory _memory;

  /// The runs recorded into named memory this session, in order — the live run
  /// trail (mirrors what was persisted, for in-process inspection).
  final List<BrainRunRecord> runs = <BrainRunRecord>[];

  @override
  List<BrainRunRecord> get recordedRuns => runs;

  @override
  Future<AgentRunResult> runInSession(
    MemoryScope scope,
    AgentTask task,
    Future<AgentRunResult> Function() body,
  ) async {
    final stopwatch = Stopwatch()..start();
    final result = await body();
    stopwatch.stop();

    final effort = RunEffort.measure(
      wallClock: stopwatch.elapsed,
      result: result,
      inputCount: task.inputs.length,
    );

    // Persist the run as a node in the document's named memory. The summary is
    // the searchable headline; the payload carries the structured run trail.
    final document = await _memory.openDocument(scope);
    await document.remember(
      _runSummary(scope, task, effort),
      metadata: <String, Object?>{
        'kind': 'agent-run',
        'application': scope.application,
        'session': scope.session,
        'document': scope.document,
        'goal': task.goal,
        if (result.error != null) 'error': result.error,
        ...effort.toJson(),
      },
    );

    runs.add(BrainRunRecord(
      scope: scope,
      task: task,
      result: result,
      effort: effort,
    ));
    return result;
  }

  /// The searchable one-line summary stored on the run node.
  static String _runSummary(MemoryScope scope, AgentTask task, RunEffort e) =>
      'agent run [${scope.application}/${scope.session}] ${task.goal} '
      '→ ${e.ok ? 'ok' : 'failed'} (${e.wallClock.inMilliseconds}ms)';
}
