/// The **live conversational substrate** + **multi-turn complex procedures**
/// (`llm_and_d4rt_tools.md` §10 mode a).
///
/// `llm_and_d4rt_tools.md` §10 mode (a) has a *headless* core — the complex
/// agent procedure ([AgentProcedure]) and the single-pass
/// [DirectAgentSubstrate] that drives it once. The **conversational substrate**
/// (the live LLM that decides *what to do next*) and the **multi-turn** loop
/// are an "editor concern", so this library covers them with the same seam
/// pattern [SpecBrainSessionEnvelope] uses for the Tom Brain envelope: an
/// **injected port** the pure-Dart plane can drive host-independently.
///
/// `llm_and_d4rt_tools.md` §10 mode (a) is "the Agent SDK … **augmented with
/// the RAG memory** for per-prompt recall and **driven by a complex agent
/// procedure**". The conversational substrate is the Agent SDK / LLM; this
/// plane cannot host it, so [ConversationalDriver] is the port the editor binds
/// to the live agent loop (Claude Code over the VS Code bridge).
/// [ConversationalAgentSubstrate] is the **multi-turn** realisation: each turn
/// it (1) recalls the RAG memory for the goal (the per-prompt augmentation),
/// (2) hands that recall to the driver to decide the next turn (or stop), and
/// (3) runs the existing complex procedure through a **base** [AgentSubstrate]
/// for the turn's chosen inputs — so the conversational layer composes on top
/// of *either* `llm_and_d4rt_tools.md` §10 mode (mode a's
/// [DirectAgentSubstrate] or mode b's [BrainAgentSubstrate], whose run trail
/// then records every turn for free).
///
/// Keeping the driver an injected port lets the headless multi-turn test run
/// against [RecordingConversationalDriver] (a scripted decision list) while the
/// editor binds the live `AgentSendController`-backed driver — exactly as the
/// memory plane (`llm_and_d4rt_tools.md` §9) and the run envelope
/// (`llm_and_d4rt_tools.md` §10) inject their live ports.
/// @docImport 'brain_agent_substrate.dart';
/// @docImport 'direct_agent_substrate.dart';
/// @docImport 'agent_substrate_factory.dart';
/// @docImport 'spec_brain_envelope.dart';
library;

import 'agent_procedure.dart';
import 'agent_substrate.dart';
import 'agent_tools_api.dart';

/// One completed conversational turn: the [task] the driver chose, the procedure
/// [result] the base substrate produced, and the [recalledPaths] that informed
/// the turn.
final class ConversationalTurn {
  /// The zero-based turn index in the conversation.
  final int index;

  /// The task the driver chose for this turn (goal + structured inputs).
  final AgentTask task;

  /// The procedure's outcome for this turn (run through the base substrate).
  final AgentRunResult result;

  /// The memory paths the per-turn RAG recall surfaced before the driver
  /// decided this turn — the per-prompt augmentation `llm_and_d4rt_tools.md`
  /// §10 mode (a) calls for.
  final List<String> recalledPaths;

  /// Creates a turn record.
  const ConversationalTurn({
    required this.index,
    required this.task,
    required this.result,
    required this.recalledPaths,
  });

  /// A compact JSON view for the trail / MCP surface.
  Map<String, Object?> toJson() => <String, Object?>{
        'index': index,
        'goal': task.goal,
        if (task.inputs.isNotEmpty) 'inputs': task.inputs,
        'result': result.toJson(),
        if (recalledPaths.isNotEmpty) 'recalledPaths': recalledPaths,
      };
}

/// The running context handed to a [ConversationalDriver] to decide the next
/// turn: the standing [goal], the [turnIndex] about to run, the [priorTurns]
/// already completed, and the [recall] (and flattened [recalledPaths]) the
/// substrate pulled for this turn.
final class ConversationContext {
  /// The standing free-text goal driving the whole conversation.
  final String goal;

  /// The zero-based index of the turn the driver is about to decide.
  final int turnIndex;

  /// The turns completed so far (read-only), oldest first.
  final List<ConversationalTurn> priorTurns;

  /// The raw per-turn recall JSON (`hits`, `degraded`) the substrate pulled
  /// before this decision — the RAG augmentation the driver reasons over.
  final Map<String, Object?> recall;

  /// The flattened recall hit paths, oldest-ranked first — the cheap view a
  /// driver usually needs.
  final List<String> recalledPaths;

  /// Creates the context.
  const ConversationContext({
    required this.goal,
    required this.turnIndex,
    required this.priorTurns,
    required this.recall,
    required this.recalledPaths,
  });
}

/// A driver's decision for one turn: either **stop** the conversation, or **run**
/// the complex procedure with chosen [inputs] (and an optional per-turn [goal]
/// override).
final class ConversationalDecision {
  /// Whether the conversation should stop *before* running this turn.
  final bool stop;

  /// Why the driver stopped (only meaningful when [stop] is `true`).
  final String? reason;

  /// An optional per-turn goal override; when `null` the standing goal is used.
  final String? goal;

  /// The structured inputs merged into the procedure's task argument (e.g.
  /// `parentPath` / `childSegment` for the default add procedure).
  final Map<String, Object?> inputs;

  const ConversationalDecision._({
    required this.stop,
    this.reason,
    this.goal,
    this.inputs = const <String, Object?>{},
  });

  /// Run one turn of the complex procedure with [inputs] (and optional per-turn
  /// [goal] override).
  const ConversationalDecision.run({
    Map<String, Object?> inputs = const <String, Object?>{},
    String? goal,
  }) : this._(stop: false, inputs: inputs, goal: goal);

  /// Stop the conversation (no turn runs); [reason] explains why.
  const ConversationalDecision.stop({String? reason})
      : this._(stop: true, reason: reason);
}

/// The **live conversational substrate** seam (`llm_and_d4rt_tools.md` §10 mode
/// a): the LLM / Agent SDK that, given the running [ConversationContext] (goal
/// + RAG recall + prior turns), decides the next turn or stops.
///
/// The pure-Dart plane cannot host the live model, so this is an injected port:
/// the editor binds it to the live agent loop (Claude Code over the VS Code
/// bridge); a headless test binds [RecordingConversationalDriver].
abstract interface class ConversationalDriver {
  /// Decides the turn at [context].turnIndex — run the procedure with chosen
  /// inputs, or stop the conversation.
  Future<ConversationalDecision> nextTurn(ConversationContext context);
}

/// A host-independent [ConversationalDriver] that replays a scripted list of
/// [ConversationalDecision]s and records every [ConversationContext] it saw.
///
/// This is the realisation the headless multi-turn test drives: it models the
/// live LLM's turn-by-turn decisions without a bridge or a provider, exposing the
/// contexts (so a test can assert the per-turn RAG recall reached the driver) and
/// stopping cleanly once the script is exhausted.
final class RecordingConversationalDriver implements ConversationalDriver {
  /// Creates the driver over a scripted [decisions] list (replayed in order).
  RecordingConversationalDriver(List<ConversationalDecision> decisions)
      : _decisions = List.of(decisions);

  final List<ConversationalDecision> _decisions;

  /// The contexts handed to the driver, in order — the per-turn decision inputs.
  final List<ConversationContext> seenContexts = [];

  int _cursor = 0;

  @override
  Future<ConversationalDecision> nextTurn(ConversationContext context) async {
    seenContexts.add(context);
    if (_cursor >= _decisions.length) {
      return const ConversationalDecision.stop(reason: 'script exhausted');
    }
    return _decisions[_cursor++];
  }
}

/// Runs the complex agent procedure across **multiple conversational turns** —
/// the live mode-(a) realisation (`llm_and_d4rt_tools.md` §10).
///
/// Composition over a base substrate: each turn the substrate (1) recalls the
/// RAG memory for the goal (the per-prompt augmentation), (2) asks the injected
/// [ConversationalDriver] to decide the turn, and (3) — unless the driver stops —
/// runs the chosen task through the base [AgentSubstrate]. That base substrate is
/// usually a [DirectAgentSubstrate] (pure mode a) but may be a
/// [BrainAgentSubstrate] (so every turn lands in that substrate's run trail).
///
/// The aggregate [run] result reports `ok` only if every completed turn
/// succeeded (an empty conversation — the driver stopped immediately — is a
/// successful no-op), with the per-turn outputs and the stop reason in its
/// `output`, and every turn's transcript concatenated. The full per-turn trail is
/// available on [turns].
final class ConversationalAgentSubstrate implements AgentSubstrate {
  /// Drives [base] across turns chosen by [driver], recalling [tools]'s RAG
  /// memory before each decision.
  ///
  /// [maxTurns] caps the conversation length (a guard against a non-terminating
  /// driver); [stopOnError] ends the conversation after the first failed turn;
  /// [recallK] is the per-turn recall depth.
  ConversationalAgentSubstrate({
    required AgentSubstrate base,
    required AgentToolsApi tools,
    required ConversationalDriver driver,
    int maxTurns = 8,
    bool stopOnError = true,
    int recallK = 10,
  })  : _base = base,
        _tools = tools,
        _driver = driver,
        _maxTurns = maxTurns,
        _stopOnError = stopOnError,
        _recallK = recallK;

  final AgentSubstrate _base;
  final AgentToolsApi _tools;
  final ConversationalDriver _driver;
  final int _maxTurns;
  final bool _stopOnError;
  final int _recallK;

  final List<ConversationalTurn> _turns = [];

  /// The mode of the base substrate each turn runs through (`direct` or
  /// `tom_brain`).
  String get baseMode => _base.mode;

  /// The completed turns of the most recent [run], oldest first.
  List<ConversationalTurn> get turns => List.unmodifiable(_turns);

  @override
  String get mode => 'conversational';

  @override
  Future<AgentRunResult> run(AgentTask task) async {
    final goal = task.goal;
    final transcript = StringBuffer();
    final completed = <ConversationalTurn>[];
    String? stopReason;

    for (var i = 0; i < _maxTurns; i++) {
      // 1. Per-prompt RAG recall — the augmentation `llm_and_d4rt_tools.md` §10
      //    mode (a) calls for.
      final recall = await _tools.recall(goal, k: _recallK);
      final recalledPaths = _pathsOf(recall);

      // 2. The live conversational substrate decides the turn (or stops).
      final decision = await _driver.nextTurn(ConversationContext(
        goal: goal,
        turnIndex: i,
        priorTurns: List.unmodifiable(completed),
        recall: recall,
        recalledPaths: recalledPaths,
      ));
      if (decision.stop) {
        stopReason = decision.reason ?? 'driver stopped';
        break;
      }

      // 3. Run the complex procedure for the chosen task through the base
      //    substrate (mode a or b) — its edits land in the one change log.
      final turnTask = AgentTask(
        goal: decision.goal ?? goal,
        inputs: decision.inputs,
      );
      final result = await _base.run(turnTask);
      completed.add(ConversationalTurn(
        index: i,
        task: turnTask,
        result: result,
        recalledPaths: recalledPaths,
      ));
      // Always mark the turn boundary so the aggregate transcript documents the
      // conversation structure, even for a silent turn.
      transcript.writeln('— turn $i —');
      transcript.write(result.transcript);
      if (_stopOnError && !result.ok) {
        stopReason = 'turn $i failed';
        break;
      }
    }
    if (stopReason == null && completed.length >= _maxTurns) {
      stopReason = 'reached maxTurns ($_maxTurns)';
    }

    _turns
      ..clear()
      ..addAll(completed);

    // An empty conversation (driver stopped immediately) is a successful no-op;
    // otherwise the run is ok only if every completed turn succeeded.
    final allOk = completed.every((t) => t.result.ok);
    return AgentRunResult(
      ok: allOk,
      output: <String, Object?>{
        'turns': completed.length,
        'stopReason': ?stopReason,
        'results': [for (final t in completed) t.result.output],
      },
      transcript: transcript.toString(),
      error: allOk ? null : 'one or more conversational turns failed',
    );
  }

  /// Flattens a recall result's `hits` into their `path`s, preserving rank order.
  List<String> _pathsOf(Map<String, Object?> recall) {
    final hits = recall['hits'];
    if (hits is! List) return const <String>[];
    final paths = <String>[];
    for (final hit in hits) {
      if (hit is Map && hit['path'] != null) paths.add(hit['path'].toString());
    }
    return paths;
  }
}

/// Builds a [ConversationalAgentSubstrate] over [base] driven by [driver],
/// recalling [tools]'s RAG memory per turn.
///
/// A thin convenience mirroring [buildAgentSubstrate] for the conversational
/// layer (`llm_and_d4rt_tools.md` §10 mode a, multi-turn). The conversational
/// substrate is *not* one of the two [AgentSubstrateMode]s — it is the live,
/// multi-turn realisation that composes on top of either mode — so it has its
/// own builder rather than an enum case.
ConversationalAgentSubstrate buildConversationalSubstrate({
  required AgentSubstrate base,
  required AgentToolsApi tools,
  required ConversationalDriver driver,
  int maxTurns = 8,
  bool stopOnError = true,
  int recallK = 10,
}) =>
    ConversationalAgentSubstrate(
      base: base,
      tools: tools,
      driver: driver,
      maxTurns: maxTurns,
      stopOnError: stopOnError,
      recallK: recallK,
    );
