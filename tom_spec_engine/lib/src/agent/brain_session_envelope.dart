/// The Tom Brain **session envelope** for `llm_and_d4rt_tools.md` §10 mode (b).
///
/// Mode (b) ([BrainAgentSubstrate]) drives the *same* complex agent procedure as
/// mode (a), but wraps each run in Tom Brain's isolation envelope — a **profile**
/// (the application), a **named session** (the phase/task run), and a **named
/// memory** (the document) — and records the run into that named memory. That
/// envelope is what distinguishes the two modes; the loop body is identical.
///
/// [BrainSessionEnvelope] is the seam at which that envelope plugs in. The
/// substrate hands it a [MemoryScope] (the application→profile / session→named
/// session / document→named memory addressing already established for the
/// memory plane, `llm_and_d4rt_tools.md` §9) and the loop body; the envelope
/// opens the session, runs the body, records the run, and closes the session.
/// Keeping it an injected port lets the headless "same loop test" run
/// host-independently against [RecordingBrainEnvelope] while the concrete
/// `tom_brain_memory`-backed envelope (live profile registry + named-memory run
/// trail) is wired where the editor composes the agent plane — exactly as the
/// memory plane (`llm_and_d4rt_tools.md` §9) injects its store/embedder ports.
/// @docImport 'brain_agent_substrate.dart';
library;

import 'agent_substrate.dart';
import '../memory/memory_scope.dart';

/// The **effort metrics** of one agent run — the quantitative trail the run
/// envelope records alongside each [BrainRunRecord].
///
/// These are the cheap, host-independent measures of "how much work the run
/// did", derived purely from the wall-clock time the loop body took and the
/// [AgentRunResult] it produced — no model token accounting (that lives at the
/// conversational substrate, decision D72). Persisted as the run node's
/// `payload` so the run trail is queryable: a later phase can ask "which runs
/// in this document took longest / failed / produced no output".
final class RunEffort {
  /// Wall-clock time the loop body took.
  final Duration wallClock;

  /// Characters the run printed (the captured transcript length).
  final int transcriptChars;

  /// Lines the run printed (newline-delimited transcript lines; `0` for an
  /// empty transcript).
  final int transcriptLines;

  /// Number of structured inputs the task carried.
  final int inputCount;

  /// Whether the run completed without throwing.
  final bool ok;

  /// Whether the run produced a non-null `main()` output.
  final bool produced;

  /// Creates an effort record from its measured components.
  const RunEffort({
    required this.wallClock,
    required this.transcriptChars,
    required this.transcriptLines,
    required this.inputCount,
    required this.ok,
    required this.produced,
  });

  /// Measures the effort of [result] (the loop body's outcome) that took
  /// [wallClock], for a task carrying [inputCount] inputs. Derives the
  /// transcript char/line counts from the result's captured transcript.
  factory RunEffort.measure({
    required Duration wallClock,
    required AgentRunResult result,
    required int inputCount,
  }) {
    final transcript = result.transcript;
    // The host builds the transcript with `writeln`, so every emitted line ends
    // in a newline; counting newlines counts lines.
    return RunEffort(
      wallClock: wallClock,
      transcriptChars: transcript.length,
      transcriptLines: '\n'.allMatches(transcript).length,
      inputCount: inputCount,
      ok: result.ok,
      produced: result.output != null,
    );
  }

  /// A JSON-able view of the metrics — the run node's `payload`.
  Map<String, Object?> toJson() => <String, Object?>{
        'wallClockMs': wallClock.inMilliseconds,
        'transcriptChars': transcriptChars,
        'transcriptLines': transcriptLines,
        'inputCount': inputCount,
        'ok': ok,
        'produced': produced,
      };

  @override
  String toString() => 'RunEffort(${wallClock.inMilliseconds}ms, '
      '$transcriptChars chars, ok: $ok)';
}

/// One recorded agent run inside a Tom Brain named memory (the run trail).
final class BrainRunRecord {
  /// The Tom Brain addressing the run executed under.
  final MemoryScope scope;

  /// The task the run was given.
  final AgentTask task;

  /// The run's captured result.
  final AgentRunResult result;

  /// The run's effort metrics (wall-clock, transcript size, outcome).
  final RunEffort effort;

  /// Creates a record.
  const BrainRunRecord({
    required this.scope,
    required this.task,
    required this.result,
    required this.effort,
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

  /// The runs recorded so far, in order — the run trail. Read-only; a consumer
  /// (e.g. the editor's `agent_trail` MCP tool) reads back the per-run
  /// [RunEffort] without depending on the concrete envelope.
  List<BrainRunRecord> get recordedRuns;
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
  List<BrainRunRecord> get recordedRuns => runs;

  @override
  Future<AgentRunResult> runInSession(
    MemoryScope scope,
    AgentTask task,
    Future<AgentRunResult> Function() body,
  ) async {
    openedSessions.add(scope);
    final stopwatch = Stopwatch()..start();
    final result = await body();
    stopwatch.stop();
    runs.add(BrainRunRecord(
      scope: scope,
      task: task,
      result: result,
      effort: RunEffort.measure(
        wallClock: stopwatch.elapsed,
        result: result,
        inputCount: task.inputs.length,
      ),
    ));
    return result;
  }
}
