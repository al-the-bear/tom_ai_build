// The authorization cross-check of a Solution Blueprint (in a project's
// requirements, e.g. RC-353): the operation
// registry, the role matrix, the screens and the use cases must agree.
//
// Six checks, each answering one question:
//
//   A  every operation is reachable by some role, and every custom handler an
//      operation names is in the handler table of `INDM > SVOPR` (and back);
//   B  every screen action's operation is reachable by a role the screen admits;
//   C  every use-case step's operation is reachable by the step's actor — or
//      the step names another actor, or waits for an open question;
//   D  the step-up default list of `SUAP` and the operations' safeguards agree;
//   E  the four-eyes default list of `ROMA` and the safeguards agree;
//   F  each operation's "Called by" line names exactly the screens whose
//      actions call it, and every use case whose steps name it.
//
// The role model the check reads the Blueprint with — which keys each role
// can hold, which roles a custom handler admits, which roles an actor acts
// in — is the project's `<spec-root>/checks/authorization_cross_check.yaml`,
// read by `spec_checks authorization`.
import 'package:yaml/yaml.dart';

import 'sbp_tree.dart';

/// The authorization requirement of an operation or screen.
class Access {
  /// Binds the requirement kind, its entitlement keys, its roles and its
  /// custom handler.
  Access(this.kind, this.keys, this.roles, this.handler);

  /// `public`, `authenticated`, `role`, `entitlement` or `custom`.
  final String kind;

  /// The entitlement key patterns of an `entitlement` requirement
  /// (`AZREQ-ENTL > patterns`), empty for the other kinds.
  final List<String> keys;

  /// The roles of a `role` requirement (`AZREQ-ROLE > roles`), empty for the
  /// other kinds.
  final List<String> roles;

  /// The handler name of a `custom` requirement (`AZREQ-CUST > handler`),
  /// `''` for the other kinds.
  final String handler;

  /// Reads an `AZREQ` section; a missing or non-mapping section gives an
  /// access of kind `''` that no role reaches.
  static Access of(Object? azreq) {
    if (azreq is! YamlMap) return Access('', const [], const [], '');
    final kind = field(azreq['content'], 'requirementKind');
    List<String> split(String text) => text
        .split(RegExp(r'[,\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final keys = split(field(child(azreq, 'AZREQ-ENTL'), 'patterns'));
    final roles = split(field(child(azreq, 'AZREQ-ROLE'), 'roles'));
    final handler = field(child(azreq, 'AZREQ-CUST'), 'handler');
    return Access(kind, keys, roles, handler);
  }

  /// The kind followed by its keys, else its roles, else its handler, as the
  /// findings quote it (e.g. `entitlement orders.read`).
  String describe() =>
      '$kind ${keys.isNotEmpty
              ? keys.join(', ')
              : roles.isNotEmpty
              ? roles.join(', ')
              : handler}'
          .trim();
}

/// A server operation of the operation registry (`INDM > SVOPR`).
class Operation {
  /// Binds the operation's name, access, "Called by" and "Safeguards" lines
  /// and its whole preamble.
  Operation(
    this.name,
    this.access,
    this.calledBy,
    this.safeguards,
    this.preamble,
  );

  /// The operation name (`operationName`).
  final String name;

  /// The operation's authorization requirement (its `AZREQ`).
  final Access access;

  /// The text of the preamble's `**Called by:**` line, whitespace collapsed;
  /// `''` when the line is missing.
  final String calledBy;

  /// The text of the preamble's `**Safeguards:**` line, whitespace collapsed;
  /// `''` when the line is missing.
  final String safeguards;

  /// The operation's prose preamble (its `content` field) as written.
  final String preamble;
}

/// A screen of the screen inventory (`XID > XCS > SCRDZ > SCRINV`).
class Screen {
  /// Binds the screen's name, access and actions.
  Screen(this.name, this.access, this.actions);

  /// The screen id, the list item id without its `SCREN-ITEM-` prefix.
  final String name;

  /// The screen's authorization requirement (its `AZREQ`).
  final Access access;

  /// Action id -> the operations its description names.
  final Map<String, Set<String>> actions;
}

/// A use-case step (main success scenario or extension) that names a server
/// operation.
class Step {
  /// Binds the step's operation, its actor text and its list item id.
  Step(this.operation, this.actorText, this.id);

  /// The operation the step names (`serverOperation`).
  final String operation;

  /// The step's actor action and system response (an extension step's
  /// action and response), joined by ` // `.
  final String actorText;

  /// The step's list item id.
  final String id;
}

/// A use case of the use-case catalogue (`TOMC > PSAAI > INCA`).
class UseCase {
  /// Binds the use case's name, primary actor, named operations and steps.
  UseCase(this.name, this.actor, this.operations, this.steps);

  /// The use case id, the list item id without its `INEN-INTE-` prefix.
  final String name;

  /// The primary actor (`INID > primaryActor`).
  final String actor;

  /// Every operation named by a `serverOperation` anywhere in the use case.
  final Set<String> operations;

  /// The steps that name an operation, main scenario first, then extensions.
  final List<Step> steps;
}

/// The check's result: findings per check, and the two informational lists.
class CrossCheckReport {
  /// The findings of each check, keyed by its name in [checks].
  final Map<String, List<String>> findings = {
    for (final c in checks) c: <String>[],
  };

  /// The use-case steps check C let pass because another actor than the
  /// primary one performs them (informational).
  final List<String> otherActor = [];

  /// The use-case steps check C let pass because they wait for an open
  /// question of the role model (informational).
  final List<String> pending = [];

  /// The number of operations in the operation registry.
  int operations = 0;

  /// The number of screens in the screen inventory.
  int screens = 0;

  /// The number of use cases in the use-case catalogue.
  int useCases = 0;

  /// The names of the six checks, in report order.
  static const checks = [
    'A operations reachable',
    'B screen actions',
    'C use cases',
    'D step-up',
    'E four-eyes',
    'F called by',
  ];

  /// The number of findings over all checks.
  int get total => findings.values.fold(0, (n, l) => n + l.length);
}

/// The role model of a project's
/// `<spec-root>/checks/authorization_cross_check.yaml`.
class RoleModel {
  /// Binds the expanded role keys, handler roles and actor roles, the
  /// operations other actors perform and the pending questions.
  RoleModel(
    this.roleKeys,
    this.handlerRoles,
    this.actorRoles,
    this.otherActorOperations,
    this.pendingQuestions,
  );

  /// The entitlement keys each role holds (`roleKeys`), with
  /// `platformOnlyKeys` and `tenantKeys` expanded.
  final Map<String, Set<String>> roleKeys;

  /// The roles each custom authorization handler admits (`handlerRoles`).
  final Map<String, Set<String>> handlerRoles;

  /// The roles each use-case actor acts in (`actorRoles`).
  final Map<String, Set<String>> actorRoles;

  /// The operations check C accepts from any actor (`otherActorOperations`).
  final Set<String> otherActorOperations;

  /// The open question ids (`BQ-<n>`) a use-case step may wait for
  /// (`pendingQuestions`).
  final List<String> pendingQuestions;

  /// The role names, in the order of `roleKeys`.
  List<String> get roles => roleKeys.keys.toList();

  /// Reads the config, expanding `platformOnlyKeys`, `tenantKeys` and `allBut:`
  /// against the keys the Blueprint uses ([allKeys]).
  static RoleModel parse(String configYaml, Set<String> allKeys) {
    final cfg = loadYaml(configYaml) as YamlMap;
    final platformOnly = {
      for (final k in cfg['platformOnlyKeys'] as YamlList) '$k',
    };
    final tenant = allKeys.difference(platformOnly);
    final roleKeys = <String, Set<String>>{};
    (cfg['roleKeys'] as YamlMap).forEach((role, keys) {
      final set = <String>{};
      for (final k in keys as YamlList) {
        if (k == 'platformOnlyKeys') {
          set.addAll(platformOnly);
        } else if (k == 'tenantKeys') {
          set.addAll(tenant);
        } else {
          set.add('$k');
        }
      }
      roleKeys['$role'] = set;
    });
    final roles = roleKeys.keys.toSet();
    Set<String> roleSet(Object? v) => v is YamlMap
        ? roles.difference({for (final r in v['allBut'] as YamlList) '$r'})
        : {for (final r in v as YamlList) '$r'};
    final handlers = <String, Set<String>>{};
    (cfg['handlerRoles'] as YamlMap).forEach(
      (h, v) => handlers['$h'] = roleSet(v),
    );
    final actors = <String, Set<String>>{};
    (cfg['actorRoles'] as YamlMap).forEach((a, v) => actors['$a'] = roleSet(v));
    return RoleModel(
      roleKeys,
      handlers,
      actors,
      {for (final o in cfg['otherActorOperations'] as YamlList) '$o'},
      [for (final q in cfg['pendingQuestions'] as YamlList) '$q'],
    );
  }

  /// The roles an access requirement admits.
  Set<String> reach(Access access) {
    switch (access.kind) {
      case 'public':
        return roles.toSet();
      case 'authenticated':
        return roles.toSet()..remove('operations');
      case 'role':
        return access.roles.toSet();
      case 'entitlement':
        // A key covers every key below it (a rule such as FR-26): for example
        // a role holding `orders` reaches an operation that requires
        // `orders.read`.
        bool covers(String held, String required) =>
            required == held || required.startsWith('$held.');
        return {
          for (final r in roles)
            if (access.keys.any((k) => roleKeys[r]!.any((h) => covers(h, k))))
              r,
        };
      case 'custom':
        return handlerRoles[access.handler] ?? <String>{};
    }
    return <String>{};
  }
}

final RegExp _word = RegExp(r'\b([a-z]\w+)\b');
final RegExp _backticked = RegExp(r'`(\w+)`');

String _line(String preamble, String label) {
  final m = RegExp(
    r'- \*\*' + label + r':\*\*(.*?)(?=\n- \*\*|\n\n|$)',
    dotAll: true,
  ).firstMatch(preamble);
  return m == null ? '' : m.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void _serverOperations(Object? node, Set<String> into) {
  if (node is YamlMap) {
    node.forEach((k, v) {
      if (k == 'serverOperation' &&
          v is String &&
          RegExp(r'^\w+$').hasMatch(v)) {
        into.add(v);
      }
      _serverOperations(v, into);
    });
  } else if (node is YamlList) {
    for (final v in node) {
      _serverOperations(v, into);
    }
  }
}

/// Runs the six checks over the Blueprint in [yamlText] with the role model
/// in [configYaml].
CrossCheckReport crossCheckAuthorization(String yamlText, String configYaml) {
  final d = sbpRoot(yamlText);
  final report = CrossCheckReport();

  // --- the registries ------------------------------------------------------
  final ops = <String, Operation>{};
  entriesOf(at(d, ['INDM', 'SVOPR', 'SVOPE-OPER-LST'])).forEach((_, v) {
    final content = child(v, 'content');
    final name = field(content, 'operationName');
    final pre = field(content, 'content');
    ops[name] = Operation(
      name,
      Access.of(child(v, 'AZREQ')),
      _line(pre, 'Called by'),
      _line(pre, 'Safeguards'),
      pre,
    );
  });
  final opNames = ops.keys.toSet();

  final screens = <String, Screen>{};
  entriesOf(at(d, ['XID', 'XCS', 'SCRDZ', 'SCRINV', 'SCREN-ITEM-LST'])).forEach(
    (k, v) {
      final actions = <String, Set<String>>{};
      entriesOf(at(v, ['SCAC', 'SCRAC-ITEM-LST'])).forEach((ak, av) {
        final description = field(child(av, 'content'), 'description');
        actions[ak] = {
          for (final m in _word.allMatches(description))
            if (opNames.contains(m.group(1))) m.group(1)!,
        };
      });
      final name = k.replaceFirst('SCREN-ITEM-', '');
      screens[name] = Screen(name, Access.of(child(v, 'AZREQ')), actions);
    },
  );

  final useCases = <String, UseCase>{};
  entriesOf(at(d, ['TOMC', 'PSAAI', 'INCA', 'INEN-INTE-LST'])).forEach((k, v) {
    final all = <String>{};
    _serverOperations(v, all);
    final steps = <Step>[];
    entriesOf(at(v, ['MASUSC', 'MNSST-STEP-LST'])).forEach((sk, st) {
      final c = child(st, 'content');
      final op = field(c, 'serverOperation');
      if (op.isNotEmpty) {
        steps.add(
          Step(
            op,
            '${_raw(c, 'actorAction')} // ${_raw(c, 'systemResponse')}',
            sk,
          ),
        );
      }
    });
    entriesOf(at(v, ['USCAEX', 'EXTEN-EXTE-LST'])).forEach((_, ev) {
      entriesOf(child(ev, 'EXTST-STEP-LST')).forEach((sk, st) {
        final c = child(st, 'content');
        final op = field(c, 'serverOperation');
        if (op.isNotEmpty) {
          steps.add(
            Step(op, '${_raw(c, 'action')} // ${_raw(c, 'response')}', sk),
          );
        }
      });
    });
    final name = k.replaceFirst('INEN-INTE-', '');
    useCases[name] = UseCase(
      name,
      field(child(v, 'INID'), 'primaryActor'),
      all,
      steps,
    );
  });
  report
    ..operations = ops.length
    ..screens = screens.length
    ..useCases = useCases.length;

  final allKeys = <String>{
    for (final o in ops.values) ...o.access.keys,
    for (final s in screens.values) ...s.access.keys,
  };
  final model = RoleModel.parse(configYaml, allKeys);
  void finding(String check, String message) =>
      report.findings[check]!.add(message);

  // --- A operations --------------------------------------------------------
  final svopr = textOf(child(at(d, ['INDM', 'SVOPR']), 'content'));
  final handlerTable = svopr.contains('**Custom authorization handlers')
      ? svopr
            .split('**Custom authorization handlers')[1]
            .split('**Operations per area')
            .first
      : '';
  final handlers = [
    for (final m in RegExp(
      r'^\| `(\w+)` \|',
      multiLine: true,
    ).allMatches(handlerTable))
      m.group(1)!,
  ];
  ops.forEach((name, o) {
    if (model.reach(o.access).isEmpty) {
      finding(
        'A operations reachable',
        '$name: no role reaches it (${o.access.describe()})',
      );
    }
    final h = o.access.handler;
    if (h.isNotEmpty && !handlers.contains(h)) {
      finding(
        'A operations reachable',
        '$name: handler $h not in the SVOPR handler table',
      );
    }
  });
  for (final h in handlers) {
    if (!ops.values.any((o) => o.access.handler == h)) {
      finding(
        'A operations reachable',
        'handler $h in the table but used by no operation',
      );
    }
  }

  // --- B screens -----------------------------------------------------------
  screens.forEach((s, screen) {
    final sr = model.reach(screen.access);
    screen.actions.forEach((a, actionOps) {
      for (final o in actionOps) {
        if (sr.intersection(model.reach(ops[o]!.access)).isEmpty) {
          finding(
            'B screen actions',
            '$s $a: $o (${ops[o]!.access.describe()}) not reachable by any role admitted to the screen (${screen.access.kind})',
          );
        }
      }
    });
  });

  // --- C use cases ---------------------------------------------------------
  // Only meaningful when questions are pending: an empty list would match
  // every `BQ-` citation.
  final pendingPattern = RegExp(
    r'BQ-(' +
        model.pendingQuestions.map((q) => q.substring(3)).join('|') +
        r')\b',
  );
  final otherPattern = RegExp(
    r'\b(administrator|approver|service desk|service-desk|agent|job|scheduler|former|owner of the tenant|platform)\b',
    caseSensitive: false,
  );
  final selfPattern = RegExp(
    r'^\s*The (application owner|user|end user|person)\b',
  );
  useCases.forEach((u, uc) {
    final actorRoles = model.actorRoles[uc.actor.trim()] ?? <String>{};
    for (final step in uc.steps) {
      final o = ops[step.operation];
      if (o == null) {
        finding(
          'C use cases',
          '$u: step names unknown operation ${step.operation}',
        );
        continue;
      }
      if (actorRoles.contains('system') ||
          actorRoles.intersection(model.reach(o.access)).isNotEmpty ||
          model.otherActorOperations.contains(step.operation)) {
        continue;
      }
      final act = step.actorText.split(' // ').first;
      final short = act.trim();
      if (model.pendingQuestions.isNotEmpty && pendingPattern.hasMatch(act)) {
        report.pending.add(
          '$u ${step.id}: ${step.operation} — waits for an open question: '
          '"${short.length > 90 ? short.substring(0, 90) : short}"',
        );
        continue;
      }
      if (otherPattern.hasMatch(act) && !selfPattern.hasMatch(act)) {
        report.otherActor.add(
          '$u ${step.id}: ${step.operation} — by another actor: '
          '"${short.length > 90 ? short.substring(0, 90) : short}"',
        );
        continue;
      }
      finding(
        'C use cases',
        '$u ${step.id} (${uc.actor}): ${step.operation} needs ${o.access.describe()} — '
            '"${short.length > 100 ? short.substring(0, 100) : short}"',
      );
    }
  });

  // --- D step-up -----------------------------------------------------------
  final suap = textOf(
    child(
      at(d, ['SAAM', 'ACCM', 'IDAUT', 'AUTHEN', 'AUFL', 'SUAP']),
      'content',
    ),
  );
  final suapList = suap.contains('| Default step-up')
      ? suap.split('| Default step-up')[1].split('\n\n').first
      : '';
  final suapOps = {
    for (final m in _backticked.allMatches(suapList))
      if (ops.containsKey(m.group(1))) m.group(1)!,
  };
  for (final o in suapOps.toList()..sort()) {
    if (!('${ops[o]!.safeguards}${ops[o]!.preamble}').toLowerCase().contains(
      'step-up',
    )) {
      finding(
        'D step-up',
        '$o: in the SUAP default list but its preamble names no step-up',
      );
    }
  }
  ops.forEach((name, o) {
    if (RegExp('step-up', caseSensitive: false).hasMatch(o.safeguards) &&
        !suapOps.contains(name) &&
        !o.safeguards.contains('tenant lists')) {
      finding(
        'D step-up',
        '$name: safeguards name step-up but SUAP does not list it',
      );
    }
  });

  // --- E four-eyes ---------------------------------------------------------
  final roma = textOf(child(at(d, ['SAAM', 'ACCM', 'ROMA']), 'content'));
  if (roma.contains('**Step-up and four-eyes by default.**')) {
    final para = roma
        .split('**Step-up and four-eyes by default.**')[1]
        .split('**Small installations.**')
        .first;
    final part = para.contains('Four-eyes, where the tenant has it on')
        ? para
              .split('Four-eyes, where the tenant has it on')[1]
              .split('Two platform administrators')
              .first
        : '';
    final feOps = {
      for (final m in _backticked.allMatches(part))
        if (ops.containsKey(m.group(1))) m.group(1)!,
    };
    for (final o in feOps.toList()..sort()) {
      if (!('${ops[o]!.safeguards}${ops[o]!.preamble}').toLowerCase().contains(
        'four-eyes',
      )) {
        finding(
          'E four-eyes',
          '$o: in the ROMA four-eyes default list but its preamble names no four-eyes',
        );
      }
    }
  }

  // --- F called by ---------------------------------------------------------
  ops.forEach((name, o) {
    final cb = o.calledBy;
    final registeredScreens = {
      for (final m in RegExp(r'`([A-Z][A-Z0-9\-]+)`').allMatches(cb))
        m.group(1)!,
    };
    final registeredUseCases = {
      for (final m in RegExp(r'UC-\d+').allMatches(cb)) m.group(0)!,
    };
    final actingScreens = {
      for (final e in screens.entries)
        if (e.value.actions.values.any((s) => s.contains(name))) e.key,
    };
    final namingUseCases = {
      for (final e in useCases.entries)
        if (e.value.operations.contains(name)) e.key,
    };
    for (final s
        in actingScreens.difference(registeredScreens).toList()..sort()) {
      finding('F called by', '$name: screen $s calls it, "Called by" lacks it');
    }
    for (final s
        in registeredScreens.difference(actingScreens).toList()..sort()) {
      if (screens.containsKey(s)) {
        finding(
          'F called by',
          '$name: "Called by" names $s, whose actions do not call it',
        );
      }
    }
    for (final u
        in namingUseCases.difference(registeredUseCases).toList()..sort()) {
      finding(
        'F called by',
        '$name: $u names it in a step, "Called by" lacks it',
      );
    }
    if (cb.isEmpty) finding('F called by', '$name: no "Called by" line');
    if (RegExp(r'sbpa\d+|no screen yet').hasMatch(cb)) {
      finding(
        'F called by',
        '$name: "Called by" still says ${cb.length > 80 ? cb.substring(0, 80) : cb}',
      );
    }
  });
  return report;
}

/// A text field as written (not trimmed), `''` when absent — the step texts
/// are joined as the source holds them.
String _raw(Object? node, String name) =>
    node is YamlMap && node[name] != null ? '${node[name]}' : '';
