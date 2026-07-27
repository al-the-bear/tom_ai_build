/// The headless **procedure host** (§10).
///
/// Both §10 [AgentSubstrate] modes drive the *same* complex agent procedure
/// through the *same* execution machinery — a permission-scoped [D4rt], a
/// print-intercepting [Zone], and the auto-awaited `main()` return + error/stack
/// (the §8.1 `script_*` host pattern). [runAgentProcedure] is that machinery,
/// extracted so mode (a) ([DirectAgentSubstrate]) and mode (b)
/// ([BrainAgentSubstrate]) share one loop body verbatim (the
/// "same loop test").
library;

import 'dart:async';

import 'package:tom_d4rt/tom_d4rt.dart';

import 'agent_procedure.dart';
import 'agent_substrate.dart';
import '../scope/scope_registry.dart';

/// Runs [procedure] under the [scopeNames] granted by [registry], passing [task]
/// as the procedure's single `Map` argument (`goal` plus the task's `inputs`).
///
/// Captures all three channels — the auto-awaited `main()` return, everything
/// the procedure `print`ed, and the error/stack if it threw — into an
/// [AgentRunResult]. A procedure that throws never escapes: it comes back as
/// `ok: false` with the error channel populated.
Future<AgentRunResult> runAgentProcedure({
  required ScopeRegistry registry,
  required List<String> scopeNames,
  required AgentProcedure procedure,
  required AgentTask task,
}) async {
  final env = registry.build(scopeNames);
  // The procedure's single Map argument: the goal plus the structured inputs.
  final taskArg = <String, Object?>{'goal': task.goal, ...task.inputs};

  final out = StringBuffer();
  Object? output;
  Object? error;
  StackTrace? stack;

  await runZoned(
    () async {
      final interpreter = D4rt();
      env.applyTo(interpreter);
      try {
        final returned = interpreter.execute(
          source: procedure.source,
          positionalArgs: [taskArg],
        );
        output = returned is Future ? await returned : returned;
      } catch (e, s) {
        error = e;
        stack = s;
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => out.writeln(line),
    ),
  );

  final failed = error != null;
  return AgentRunResult(
    ok: !failed,
    output: failed ? null : output,
    transcript: out.toString(),
    error: failed ? error.toString() : null,
    stack: failed ? stack?.toString() : null,
  );
}
