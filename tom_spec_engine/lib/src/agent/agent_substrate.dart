/// The pluggable **agent substrate** abstraction (`llm_and_d4rt_tools.md` §10,
/// plan step 15).
///
/// §10 calls for *two* interchangeable agent substrates behind one interface —
/// a **direct Agent SDK** mode (a) and an **Agent-SDK-through-`tom_brain`** mode
/// (b) — both fed by the shared `tom_brain` procedure host + memory, with the
/// application selecting the mode. [AgentSubstrate] is that interface: it names
/// a single operation, [run], which executes an [AgentTask] (a natural-language
/// goal plus structured inputs) and returns an [AgentRunResult] (the procedure's
/// captured output + transcript + error channel).
///
/// The *conversational substrate* (the LLM that decides what to do — Claude Code
/// over the VS Code bridge for mode a) is editor/bridge work this pure-Dart
/// plane cannot host; what the engine owns is the **complex agent procedure**
/// that orchestrates the multi-step search → recall → edit → verify loop over
/// the §8 tools. Mode (a) ([DirectAgentSubstrate]) drives that procedure
/// directly; mode (b) (plan step 16) will drive the *same* procedure wrapped by
/// `tom_brain`. Keeping both behind this one interface is what lets step 16 add
/// the second mode without changing a single caller.
library;

/// A unit of agent work: a natural-language [goal] plus structured [inputs].
///
/// The [goal] is the free-text intent the procedure uses for its search/recall
/// passes; [inputs] carries the concrete, deterministic parameters a headless
/// run needs (e.g. `parentPath`, `childSegment`). In a live run the Agent SDK
/// would derive those from the goal; in a test harness they are supplied so the
/// loop mechanics are exercised deterministically.
final class AgentTask {
  /// The free-text intent driving the run.
  final String goal;

  /// Structured parameters merged into the procedure's task argument under their
  /// own keys (alongside `goal`).
  final Map<String, Object?> inputs;

  /// Creates a task with [goal] and optional [inputs].
  const AgentTask({required this.goal, this.inputs = const {}});
}

/// The outcome of an [AgentSubstrate.run]: the procedure's auto-awaited return,
/// everything it printed, and the error channel.
final class AgentRunResult {
  /// Whether the run completed without the procedure throwing.
  final bool ok;

  /// The procedure's auto-awaited `main()` return value (JSON-able), or `null`
  /// on error.
  final Object? output;

  /// Everything the procedure `print`ed, in order (newline-separated).
  final String transcript;

  /// The error message when the run threw, else `null`.
  final String? error;

  /// The stack trace when the run threw, else `null`.
  final String? stack;

  /// Creates a run result.
  const AgentRunResult({
    required this.ok,
    this.output,
    required this.transcript,
    this.error,
    this.stack,
  });

  /// A compact JSON view for the MCP / agent-loop surface.
  Map<String, Object?> toJson() => {
        'ok': ok,
        if (output != null) 'output': output,
        if (transcript.isNotEmpty) 'transcript': transcript,
        if (error != null) 'error': error,
        if (stack != null) 'stack': stack,
      };
}

/// The pluggable agent substrate (§10): runs an [AgentTask] under one of the two
/// §10 modes.
abstract interface class AgentSubstrate {
  /// A short label for the active mode (`direct` for mode a, `tom_brain` for
  /// mode b).
  String get mode;

  /// Runs [task] — drives the complex agent procedure's search → recall → edit
  /// → verify loop over the §8 tools — and returns its captured result.
  Future<AgentRunResult> run(AgentTask task);
}
