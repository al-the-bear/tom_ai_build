/// The IR's step language (`irspecs_ir.md`, § Steps): a form-3b body as data
/// a mapper prints in its own language.
///
/// `codespecs_derivation_contract.md` §2.4 rules B1–B8 already confine a 3b
/// body to three statement shapes, and those are the three step kinds:
///
/// * [IrCallStep] — `await collaborator.<m>(<the body's parameters>);`
///   (B2, B3);
/// * [IrReturnStep] — `return collaborator.<m>(…);` or a bare `return;`
///   (B3, B6);
/// * [IrGuardedStep] — `if (await collaborator.<m>Applies(…)) { … }`, the
///   statements its condition governs inside (B4, B5, B6).
///
/// Order is the list order (B1). Nothing else is a step: a local binding (B3),
/// a `for` / `switch` / `while` (B7), an `else`, a parsed condition (B4) or a
/// call on anything but the collaborator is reported by [readIrSteps] naming
/// the rule it breaks, never turned into a step.
library;

import '../codespecs/cs_model.dart';
import 'ir_model.dart';

/// The field through which a 3b body reaches its collaborator
/// (`codespecs_derivation_contract.md` §3.0.1).
const String kCollaboratorField = 'collaborator';

/// The fixed suffix of a guard method's name
/// (`codespecs_derivation_contract.md` §2.4 B4).
const String kGuardSuffix = 'Applies';

/// One step of a 3b body.
sealed class IrStep {
  /// The 1-based line of the statement the step was read from.
  final int line;

  /// Creates a step.
  const IrStep(this.line);
}

/// A call on a collaborator method whose result nothing reads (B2, B3).
class IrCallStep extends IrStep {
  /// The collaborator method called.
  final String method;

  /// The arguments as written — the calling body's own parameters (B3).
  final List<String> arguments;

  /// Creates a call step.
  const IrCallStep(this.method, this.arguments, int line) : super(line);
}

/// A `return` (B3, B6): of a collaborator call's result when [method] is set,
/// a bare `return;` when it is not.
class IrReturnStep extends IrStep {
  /// The collaborator method whose result is returned; `null` for `return;`.
  final String? method;

  /// The call's arguments; empty for `return;`.
  final List<String> arguments;

  /// Creates a return step.
  const IrReturnStep(this.method, this.arguments, int line) : super(line);
}

/// A block of steps governed by a stated condition, reached through a guard
/// method of the collaborator (B4); placed before the step it branches from
/// (B5) and ending as its flow's return kind says (B6).
class IrGuardedStep extends IrStep {
  /// The guard method, whose name ends in [kGuardSuffix].
  final String guard;

  /// The guard call's arguments — the calling body's own parameters.
  final List<String> arguments;

  /// The steps the condition governs.
  final List<IrStep> steps;

  /// Creates a guarded step.
  const IrGuardedStep(this.guard, this.arguments, this.steps, int line)
    : super(line);
}

/// Why a 3b body's statements are not steps: the B-rule one of them breaks.
class IrStepIssue {
  /// The rule, `B1` … `B8`, or `3b` for a statement no 3b body may hold.
  final String rule;

  /// What the statement does instead.
  final String message;

  /// The statement's line.
  final int line;

  /// Creates an issue.
  const IrStepIssue(this.rule, this.message, this.line);

  @override
  String toString() => '$rule (line $line): $message';
}

/// The steps of one 3b body — or why it has none.
class IrBodySteps {
  /// The top-level declaration the body belongs to.
  final String owner;

  /// The body's method name.
  final String body;

  /// The steps, in order; `null` when [issue] says why there are none.
  final List<IrStep>? steps;

  /// Why the body's statements are not steps; `null` when they are.
  final IrStepIssue? issue;

  /// Creates the steps of a body that reads into steps.
  const IrBodySteps.read(this.owner, this.body, List<IrStep> this.steps)
    : issue = null;

  /// Creates the record of a body that does not.
  const IrBodySteps.refused(this.owner, this.body, IrStepIssue this.issue)
    : steps = null;
}

/// The declarations of [file] that reach a collaborator: the owners of a
/// `collaborator` field.
Set<String> collaboratorOwners(CsFile file) => {
  for (final d in file.declarations)
    if (d.kind == CsDeclarationKind.field &&
        d.name == kCollaboratorField &&
        d.owner != null)
      d.owner!,
};

/// The step bodies of [file]: every form-3b body of a top-level declaration
/// that reaches a collaborator, read into steps.
///
/// A body of a declaration without a collaborator is not a step body — its
/// statements, if any, call a named substrate (statement kind 2 of
/// `codespecs_derivation_contract.md` §2.4), which is no B-rule's subject.
List<IrBodySteps> stepBodiesOf(CsFile file) {
  final owners = collaboratorOwners(file);
  return [
    for (final d in file.declarations)
      if (d.isTopLevel && owners.contains(d.name))
        for (final b in d.bodies)
          if (b.isPseudoImplementation) readIrSteps(d.name, b),
  ];
}

/// The steps of [body], a form-3b body of [owner].
IrBodySteps readIrSteps(String owner, CsMethodBody body) {
  try {
    return IrBodySteps.read(owner, body.name, _steps(body.statements));
  } on _Refused catch (r) {
    return IrBodySteps.refused(owner, body.name, r.issue);
  }
}

class _Refused implements Exception {
  final IrStepIssue issue;
  const _Refused(this.issue);
}

Never _refuse(String rule, String message, CsStatement s) => throw _Refused(
  IrStepIssue(rule, '$message: `${s.source}`', s.location.line),
);

List<IrStep> _steps(List<CsStatement> statements) => [
  for (final s in statements) _step(s),
];

IrStep _step(CsStatement s) {
  final call = s.call;
  bool onCollaborator() => call != null && call.receiver == kCollaboratorField;
  switch (s.kind) {
    case CsStatementKind.call:
      if (!onCollaborator()) {
        _refuse(
          'B2',
          'a step calls the collaborator, this calls something else',
          s,
        );
      }
      return IrCallStep(call!.method, call.arguments, s.location.line);
    case CsStatementKind.returned:
      if (s.valueSource == null) {
        return IrReturnStep(null, const [], s.location.line);
      }
      if (!onCollaborator()) {
        _refuse(
          'B3',
          "a return carries a collaborator call's result, this returns another value",
          s,
        );
      }
      return IrReturnStep(call!.method, call.arguments, s.location.line);
    case CsStatementKind.controlFlow:
      if (s.keyword != 'if') {
        _refuse('B7', 'no step states a repetition or a multi-way choice', s);
      }
      if (s.hasElse) {
        _refuse(
          'B6',
          'a branch block ends by its return kind; it has no else',
          s,
        );
      }
      if (!onCollaborator()) {
        _refuse(
          'B4',
          'a condition is a guard call on the collaborator, never a parsed expression',
          s,
        );
      }
      return IrGuardedStep(
        call!.method,
        call.arguments,
        _steps(s.nested),
        s.location.line,
      );
    case CsStatementKind.localBinding:
      _refuse(
        'B3',
        'no step consumes another step\'s result, so nothing is bound',
        s,
      );
    case CsStatementKind.thrown:
    case CsStatementKind.other:
      _refuse('3b', 'not one of the statements a 3b body admits', s);
  }
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

/// One step that breaks a validation rule (`irspecs_ir.md`, § Steps).
class IrStepViolation {
  /// `S1` … `S5`.
  final String rule;

  /// The file the body is in.
  final String file;

  /// The body, `<owner>.<method>`.
  final String body;

  /// The line of the step, or of the body when the rule is about the whole.
  final int line;

  /// What is wrong.
  final String message;

  /// Creates a violation.
  const IrStepViolation(
    this.rule,
    this.file,
    this.body,
    this.line,
    this.message,
  );

  @override
  String toString() => '$rule $file:$line $body — $message';
}

/// The validation rules, each with the contract rule it holds.
const Map<String, String> irStepRules = {
  'S1': 'the body reads into steps (B1–B8)',
  'S2':
      'every method a step calls is a method of the body\'s collaborator '
      '(B2, codespecs_derivation_contract.md §3.0.1)',
  'S3':
      'a guarded step calls a guard method, and only a guarded step does '
      '(B4)',
  'S4': 'the return kind is one the body allows (B3, B6)',
  'S5': 'every call passes the body\'s own parameters, by name (B3)',
};

/// Every violation of the step bodies in [documents], in document order.
List<IrStepViolation> validateIrSteps(List<IrDocument> documents) {
  final out = <IrStepViolation>[];
  for (final document in documents) {
    for (final entry in document.files) {
      final file = entry.file;
      for (final record in entry.steps) {
        out.addAll(_validate(documents, entry.locus, file, record));
      }
    }
  }
  return out;
}

Iterable<IrStepViolation> _validate(
  List<IrDocument> documents,
  CsLocus locus,
  CsFile file,
  IrBodySteps record,
) sync* {
  final name = '${record.owner}.${record.body}';
  final owner = _declaration(file, record.owner);
  final body = owner?.bodies.where((b) => b.name == record.body).firstOrNull;
  if (owner == null || body == null) {
    yield IrStepViolation('S1', file.path, name, 1, 'no such body in the file');
    return;
  }
  IrStepViolation v(String rule, int line, String message) =>
      IrStepViolation(rule, file.path, name, line, message);

  if (record.issue case final issue?) {
    yield v('S1', issue.line, 'not a step body: $issue');
    return;
  }
  final steps = record.steps!;

  final collaboratorType = file.declarations
      .where(
        (d) =>
            d.owner == record.owner &&
            d.kind == CsDeclarationKind.field &&
            d.name == kCollaboratorField,
      )
      .firstOrNull
      ?.declaredType;
  final collaborator = collaboratorType == null
      ? null
      : _collaboratorClass(documents, locus, collaboratorType);
  final methods = {
    for (final b in collaborator?.bodies ?? const <CsMethodBody>[]) b.name: b,
  };
  if (collaborator == null) {
    yield v(
      'S2',
      body.location.line,
      'its collaborator ${collaboratorType ?? '(no type)'} is no '
          '@CsCollaborator class of the ${locus.label} project',
    );
  }

  final parameters = [for (final p in body.parameters) p.name];
  final returnsValue = !_isVoid(body.returnType);

  Iterable<IrStepViolation> walk(List<IrStep> block) sync* {
    for (final step in block) {
      final (method, arguments) = switch (step) {
        IrCallStep(:final method, :final arguments) => (method, arguments),
        IrReturnStep(:final method, :final arguments) => (method, arguments),
        IrGuardedStep(:final guard, :final arguments) => (guard, arguments),
      };
      if (method != null) {
        final target = methods[method];
        if (collaborator != null && target == null) {
          yield v(
            'S2',
            step.line,
            '$method is no method of ${collaborator.name}',
          );
        }
        final isGuard = target != null && _isGuard(target);
        if (step is IrGuardedStep && target != null && !isGuard) {
          yield v(
            'S3',
            step.line,
            '$method is no guard: a guard is named …$kGuardSuffix and returns '
                'bool or Future<bool>',
          );
        }
        if (step is! IrGuardedStep && isGuard) {
          yield v('S3', step.line, 'the guard $method is called as a step');
        }
        if (!_sameList(arguments, parameters)) {
          yield v(
            'S5',
            step.line,
            '$method is passed (${arguments.join(', ')}), the body\'s '
                'parameters are (${parameters.join(', ')})',
          );
        }
      }
      if (step is IrReturnStep) {
        if (returnsValue && step.method == null) {
          yield v(
            'S4',
            step.line,
            'a body returning ${body.returnType} returns no value',
          );
        }
        if (!returnsValue && step.method != null) {
          yield v(
            'S4',
            step.line,
            'a body returning ${body.returnType ?? 'nothing'} returns a value',
          );
        }
      }
      if (step is IrGuardedStep) yield* walk(step.steps);
    }
  }

  yield* walk(steps);
  if (returnsValue && (steps.isEmpty || steps.last is! IrReturnStep)) {
    yield v(
      'S4',
      steps.isEmpty ? body.location.line : steps.last.line,
      'a body returning ${body.returnType} ends without returning the last '
          "step's result",
    );
  }
}

CsDeclaration? _declaration(CsFile file, String name) =>
    file.declarations.where((d) => d.isTopLevel && d.name == name).firstOrNull;

CsDeclaration? _collaboratorClass(
  List<IrDocument> documents,
  CsLocus locus,
  String type,
) {
  for (final document in documents) {
    for (final entry in document.files) {
      if (entry.locus != locus) continue;
      for (final d in entry.file.declarations) {
        if (d.isTopLevel && d.name == type && d.has('CsCollaborator')) return d;
      }
    }
  }
  return null;
}

bool _isVoid(String? type) =>
    type == null || type == 'void' || type == 'Future<void>';

bool _isGuard(CsMethodBody method) =>
    method.name.endsWith(kGuardSuffix) &&
    (method.returnType == 'bool' || method.returnType == 'Future<bool>');

bool _sameList(List<String> a, List<String> b) =>
    a.length == b.length &&
    [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((same) => same);
