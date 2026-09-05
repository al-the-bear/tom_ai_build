/// The thirty-seven validator checks `codespecs_derivation_contract.md` §6
/// names.
///
/// One [CodeSpecsCheck] per numbered row, each carrying the §-reference of the
/// rule that defines it so a failure cites the rule rather than a symptom. The
/// checks read the [CodeSpecsValidationInput] the reader builds; none of them
/// re-derives what the contract says — the contract states the rules, these
/// state nothing.
library;

import 'cs_extract.dart';
import 'cs_model.dart';

/// One failed check.
///
/// Every violation carries the `codespecs_derivation_contract.md` §6 check
/// number and the section that defines the rule, so the message identifies
/// which rule was broken.
class CodeSpecsViolation {
  /// The `codespecs_derivation_contract.md` §6 check number.
  final int check;

  /// The section that defines the rule — a bare `§N` of
  /// `codespecs_derivation_contract.md`, or the trailing form `§N of <file>.md`
  /// for a rule another document owns.
  final String definedIn;

  /// What is wrong, in the vocabulary of the rule.
  final String message;

  /// Where in the generated tree, when the check has a single site.
  final CsLocation? location;

  /// Creates a violation.
  const CodeSpecsViolation({
    required this.check,
    required this.definedIn,
    required this.message,
    this.location,
  });

  @override
  String toString() {
    final where = location == null ? '' : ' — $location';
    return 'codespecs check $check [$definedIn]: $message$where';
  }
}

/// One `codespecs_derivation_contract.md` §6 check.
abstract class CodeSpecsCheck {
  /// Creates a check.
  const CodeSpecsCheck();

  /// The `codespecs_derivation_contract.md` §6 row number.
  int get number;

  /// The section that defines the rule, in the same two forms
  /// [CodeSpecsViolation.definedIn] takes.
  String get definedIn;

  /// The rule, in one line — the `codespecs_derivation_contract.md` §6 row
  /// text.
  String get title;

  /// Runs the check, returning one violation per breach.
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input);

  /// Builds a violation attributed to this check.
  CodeSpecsViolation fail(String message, [CsLocation? at]) =>
      CodeSpecsViolation(
        check: number,
        definedIn: definedIn,
        message: message,
        location: at,
      );
}

// ---------------------------------------------------------------------------
// Shared vocabulary
// ---------------------------------------------------------------------------

/// Which project declares each `Cs*Ref`'s referent
/// (`codespecs_derivation_contract.md` §2.6).
const csRefLocus = <String, CsLocus>{
  'CsOperationRef': CsLocus.shared,
  'CsMessageKey': CsLocus.shared,
  'CsErrorCode': CsLocus.shared,
  'CsRoleRef': CsLocus.shared,
  'CsResourceKeyRef': CsLocus.shared,
  'CsCallRef': CsLocus.client,
  'CsActionRef': CsLocus.client,
  'CsRouteRef': CsLocus.client,
  'CsElementRef': CsLocus.client,
  'CsFormRef': CsLocus.client,
  'CsServiceUnitRef': CsLocus.server,
  'CsReportRef': CsLocus.server,
  'CsJobRef': CsLocus.server,
};

/// The markers whose first positional argument is an authored external
/// identifier (`codespecs_derivation_contract.md` §2.1 N5), and the name that
/// argument carries in the annotation.
const csAuthoredKeyMarkers = <String, String>{
  'CsEndpoint': 'operation',
  'CsLayout': 'nodeId',
  'CsTable': 'table',
  'CsServerConfig': 'key',
  'CsClientConfig': 'key',
  'CsDeviceSetting': 'key',
  'CsUserSetting': 'key',
  'CsClient': 'clientId',
};

/// The per-kind slot maps of the three markers whose arguments are a sum type
/// Dart cannot express (`codespecs_derivation_contract.md` §2.3).
///
/// Keyed by marker name, then by the name of the argument that declares the
/// kind, then by kind → the slots that kind may fill. Every other optional
/// argument of the marker is common and always permitted.
const csPerKindSlots = <String, ({String discriminator, Map<String, Set<String>> slots})>{
  'CsTrigger': (
    discriminator: 'kind',
    slots: {
      'userGesture': {'element', 'gesture'},
      'inFormEvent': {'form', 'formEvent', 'formField'},
      'lifecycle': {'scope', 'phase'},
      'serverEvent': {'channel', 'eventType'},
      'condition': <String>{},
    },
  ),
  'CsAuthorize': (
    discriminator: 'requirement',
    slots: {
      'role': {'roles'},
      'group': {'groups'},
      'entitlement': {'entitlements'},
      'resourceKey': {'resourceKey'},
      'custom': {'handler', 'resourceId'},
      'graded': {'graded'},
      'none': <String>{},
      'public': <String>{},
      'authenticated': <String>{},
      'guest': <String>{},
    },
  ),
  'CsJob': (
    discriminator: 'trigger',
    slots: {
      'cron': {'cron'},
      'calendar': {'calendar'},
      'event': {'event'},
    },
  ),
};

/// The `Cs*` catalogues that mirror a `tom_core` enum, keyed by the mirror
/// (`codespecs_derivation_contract.md` §5.3).
///
/// `codespecs_derivation_contract.md` §5.3 lists fourteen mirror rows, but they
/// mirror a *document* section rather than a declared type: a pair belongs here
/// only when it has a `tom_core` counterpart that can be compared
/// value-for-value.
///
/// The table is currently **empty**. Its one entry was
/// `CsErrorSeverity` ↔ `TomErrorSeverity`, and the kernel's `result` module was
/// removed — a response envelope is application domain, not kernel surface
/// (`codespecs_mapping.md` §7), so `CsErrorSeverity` is now the authority rather
/// than a mirror. Check 9 keeps its machinery and fires again the moment a pair
/// is added; it is not deleted, because rebuilding it for the next mirror would
/// cost more than carrying an empty table.
const csMirroredEnumPairs = <String, String>{};

/// The narrower scopes each configuration marker may open
/// (`codespecs_derivation_contract.md` §3.3.6, §5.3). `none` is always valid.
const csOverridableScopes = <String, Set<String>>{
  'CsServerConfig': {'none', 'client', 'user', 'device'},
  'CsClientConfig': {'none', 'user', 'device'},
  'CsUserSetting': {'none', 'device'},
};

// ---------------------------------------------------------------------------
// Reading helpers
// ---------------------------------------------------------------------------

/// The enum-constant name of [value], however it is written.
///
/// A generated file writes `CsTextRole.error`; a hand-written one may import
/// the constant unqualified.
String? enumConstantName(CsValue? value) => switch (value) {
      CsQualifiedValue(:final name) => name,
      CsUnknownValue(:final source) =>
        source.contains('.') ? source.split('.').last : source,
      _ => null,
    };

/// Every construction reachable from [value], including [value] itself.
Iterable<CsConstructionValue> constructionsIn(CsValue value) sync* {
  switch (value) {
    case CsConstructionValue():
      yield value;
      for (final nested in value.positional) {
        yield* constructionsIn(nested);
      }
      for (final nested in value.named.values) {
        yield* constructionsIn(nested);
      }
    case CsListValue():
      for (final nested in value.values) {
        yield* constructionsIn(nested);
      }
    default:
      break;
  }
}

/// Every construction written inside [marker]'s arguments.
Iterable<CsConstructionValue> markerConstructions(CsMarker marker) sync* {
  for (final value in marker.positional) {
    yield* constructionsIn(value);
  }
  for (final value in marker.named.values) {
    yield* constructionsIn(value);
  }
}

/// The reference id [construction] cites, in the N9 form the resolvable set is
/// keyed by — dotted for a form-qualified `CsElementRef`.
String? refId(CsConstructionValue construction) {
  final id = construction.idArgument;
  if (id == null) return null;
  final form = construction.named['form'];
  if (construction.type == 'CsElementRef' && form is CsStringValue) {
    return '${form.value}.$id';
  }
  return id;
}

/// The SOM sections a declaration traces back to, for a message that names the
/// section rather than the symbol.
String sectionsOf(CsDeclaration declaration) {
  final fromCodeSpec = declaration.codeSpec?.source ?? const <String>[];
  if (fromCodeSpec.isNotEmpty) return fromCodeSpec.join(', ');
  final fromDocSpec = declaration.docSpec ?? const <CsDocRef>[];
  if (fromDocSpec.isNotEmpty) {
    return fromDocSpec.map((r) => r.sectionId).join(', ');
  }
  return 'no section recorded';
}

/// The identifiers a `Cs*Ref` may resolve against in [project]
/// (`codespecs_derivation_contract.md` §2.1 N9): a generated declaration's
/// camelCase name, its `<owner>.<member>` path, an authored marker key, or the
/// id of a ref const the project itself declares.
Set<String> resolvableIdentifiers(CsLocusProject project) {
  final out = <String>{};
  for (final declaration in project.declarations) {
    out.add(declaration.name);
    out.add(declaration.path);
    for (final marker in declaration.markers) {
      if (!csAuthoredKeyMarkers.containsKey(marker.name)) continue;
      final key = marker.firstPositionalString;
      if (key != null && key.trim().isNotEmpty) out.add(key);
    }
  }
  // A ref const *declares* the id an authored key ref is cited by — the member
  // name is camelCase but the id is the key verbatim, so the declaration site is
  // what makes the key resolvable at all.
  for (final construction in project.constructions) {
    if (!csRefLocus.containsKey(construction.type)) continue;
    final first = construction.positional.isEmpty
        ? null
        : construction.positional.first;
    if (first is CsStringValue && first.value.trim().isNotEmpty) {
      out.add(first.value);
    }
  }
  return out;
}

// ---------------------------------------------------------------------------
// 1 — identifier collisions
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 1.
class CsIdentifierCollisionCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsIdentifierCollisionCheck();

  @override
  int get number => 1;

  @override
  String get definedIn => '§2.1 N4';

  @override
  String get title =>
      'Identifier collisions within a locus project fail generation, naming '
      'both section ids';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      final seen = <String, CsDeclaration>{};
      for (final declaration in project.declarations) {
        if (!declaration.isTopLevel) continue;
        final first = seen[declaration.name];
        if (first == null) {
          seen[declaration.name] = declaration;
          continue;
        }
        out.add(
          fail(
            "identifier '${declaration.name}' is derived twice in the "
            '${project.locus.label} project — from section(s) '
            '${sectionsOf(first)} (${first.location}) and from section(s) '
            '${sectionsOf(declaration)}; N4 never auto-suffixes',
            declaration.location,
          ),
        );
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 2 — reference resolution
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 2.
///
/// The subject is the **inline** reference — the one written as a
/// `Cs*Ref('…')` inside a marker rather than cited through a declared const.
/// A citation of a const is resolved by the compiler; an inline id is not
/// resolved by anything else, which is why this check exists. A blank id is
/// check 4's, not this one's.
class CsReferenceResolutionCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsReferenceResolutionCheck();

  @override
  int get number => 2;

  @override
  String get definedIn => '§2.1 N9';

  @override
  String get title => 'Every Cs*Ref string resolves to a generated declaration';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final resolvable = <CsLocus, Set<String>>{
      for (final locus in CsLocus.values)
        locus: resolvableIdentifiers(input.project(locus)),
    };
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      for (final marker in declaration.markers) {
        for (final construction in markerConstructions(marker)) {
          final locus = csRefLocus[construction.type];
          if (locus == null) continue;
          final id = refId(construction);
          if (id == null || id.trim().isEmpty) continue;
          if (resolvable[locus]!.contains(id)) continue;
          out.add(
            fail(
              "${construction.type}('$id') on @${marker.name} "
              '(${declaration.path}) resolves to no declaration in the '
              '${locus.label} project',
              marker.location,
            ),
          );
        }
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 3 — missing designated name
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 3.
///
/// Code-side, a name N1 failed to derive shows as a `@CodeSpec` id with an
/// empty half: the canonical part id and the identifier are the two things the
/// derivation produces, so an empty one is a derivation that produced nothing.
class CsMissingNameCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsMissingNameCheck();

  @override
  int get number => 3;

  @override
  String get definedIn => '§2.1 N1';

  @override
  String get title =>
      'A missing designated name field / headline fails, naming the section';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final codeSpec = declaration.codeSpec;
      if (codeSpec == null) continue;
      if (codeSpec.identifier.trim().isNotEmpty &&
          codeSpec.canonicalId.trim().isNotEmpty) {
        continue;
      }
      out.add(
        fail(
          'section(s) ${sectionsOf(declaration)} carry no designated name '
          "field and no headline — @CodeSpec('${codeSpec.id}') has no "
          'identifier to derive',
          codeSpec.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 4 — missing authored key
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 4.
class CsMissingAuthoredKeyCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsMissingAuthoredKeyCheck();

  @override
  int get number => 4;

  @override
  String get definedIn => '§2.1 N5';

  @override
  String get title =>
      'A missing authored key (message key, error code, setting key, operation '
      'name, route id) fails';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      for (final marker in declaration.markers) {
        final argument = csAuthoredKeyMarkers[marker.name];
        if (argument != null) {
          final key = marker.firstPositionalString;
          if (key == null || key.trim().isEmpty) {
            out.add(
              fail(
                '@${marker.name} on ${declaration.path} carries no $argument — '
                'an authored key is never derived, so an absent one has no '
                'fallback (section(s) ${sectionsOf(declaration)})',
                marker.location,
              ),
            );
          }
        }
        for (final construction in markerConstructions(marker)) {
          if (!csRefLocus.containsKey(construction.type)) continue;
          final id = construction.idArgument;
          if (id != null && id.trim().isNotEmpty) continue;
          out.add(
            fail(
              '${construction.type} on @${marker.name} (${declaration.path}) '
              'carries no key',
              marker.location,
            ),
          );
        }
      }
    }
    for (final project in input.projects) {
      for (final construction in project.constructions) {
        if (!csRefLocus.containsKey(construction.type)) continue;
        final first = construction.positional.isEmpty
            ? null
            : construction.positional.first;
        if (first is CsStringValue && first.value.trim().isNotEmpty) continue;
        out.add(
          fail(
            '${construction.type} declared as ${construction.holder} in the '
            '${project.locus.label} project carries no key',
            construction.location,
          ),
        );
      }
    }
    return out;
  }
}

/// Every generated body, once, with the declaration that reads best in a
/// message about it.
///
/// A class declaration aggregates its methods' bodies — check 23 resolves the
/// calls in a form-3b body through the class, not through the method — *and*
/// each method is a declaration in its own right, so a body reached by walking
/// [CodeSpecsValidationInput.declarations] is reached twice. The first reading
/// wins because it is the class's, which is what makes the message say
/// `OrderService.total` rather than `OrderService.total.total`.
Iterable<({CsDeclaration declaration, CsMethodBody body})> csBodies(
  CodeSpecsValidationInput input,
) sync* {
  final seen = <String>{};
  for (final project in input.projects) {
    for (final declaration in project.declarations) {
      for (final body in declaration.bodies) {
        if (!seen.add('${body.location}:${body.name}')) continue;
        yield (declaration: declaration, body: body);
      }
    }
  }
}

/// How to name [body] of [declaration] in a message.
///
/// A method reached through its class needs the method name appended; one
/// reached as itself, or a top-level function, already carries it.
String csBodyPath(CsDeclaration declaration, CsMethodBody body) {
  final path = declaration.path;
  if (path == body.name || path.endsWith('.${body.name}')) return path;
  return '$path.${body.name}';
}

// ---------------------------------------------------------------------------
// 5 — empty explication
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 5.
class CsEmptyExplicationCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsEmptyExplicationCheck();

  @override
  int get number => 5;

  @override
  String get definedIn => '§2.4';

  @override
  String get title => 'A form-3 body with an empty SOM description fails';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final (:declaration, :body) in csBodies(input)) {
      if (body.shape != CsBodyShape.throwOnly) continue;
      final message = body.thrownMessage;
      if (message == null || message.trim().isNotEmpty) continue;
      out.add(
        fail(
          '${csBodyPath(declaration, body)} throws with no explication — the '
          'SOM description that is the stub body is empty (section(s) '
          '${sectionsOf(declaration)})',
          body.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 6 — fabricated values
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 6.
///
/// `codespecs_derivation_contract.md` §2.4 invariant 2 asks *could the
/// generator have made this value up?*, not *does the body return?* — a form-3b
/// body's last statement **is** a `return` (`codespecs_derivation_contract.md`
/// §2.4 B3), so returning is not the offence. The offence is returning
/// something the generator composed: a literal, an arithmetic result, a string
/// built out of the specification's words. A value that came out of a
/// collaborator or substrate call was not made up, because nothing in the
/// generator knows what it will be.
///
/// A `return` of a bare identifier is admitted exactly when that identifier
/// names a `final` local the same body bound from a call —
/// `codespecs_derivation_contract.md` §2.4 kind 5 reads "produced by (1)–(3)",
/// and kind 3 is that binding.
class CsFabricatedValueCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsFabricatedValueCheck();

  @override
  int get number => 6;

  @override
  String get definedIn => '§2.4 invariant 2';

  @override
  String get title =>
      'No generated body returns a fabricated value — a 3b return is admissible '
      'only where the returned value came out of a collaborator or substrate '
      'call';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final (:declaration, :body) in csBodies(input)) {
      // A form-3a body is the throw and nothing else, so it has no return to
      // judge; the empty body of an abstract member has none either.
      if (!body.isPseudoImplementation) continue;
      final fromCalls = _localsBoundFromCalls(body);
      for (final statement in body.allStatements) {
        if (statement.kind != CsStatementKind.returned) continue;
        final value = statement.valueSource;
        // `return;` returns nothing, so there is nothing to fabricate.
        if (value == null) continue;
        if (statement.call != null) continue;
        final identifier = statement.valueIdentifier;
        if (identifier != null && fromCalls.contains(identifier)) continue;
        out.add(
          fail(
            '${csBodyPath(declaration, body)} returns `$value`, which no '
            'collaborator or substrate call produced — §2.4 invariant 2 asks '
            'could the generator have made this value up, and of this value it '
            'could',
            statement.location,
          ),
        );
      }
    }
    return out;
  }

  /// The names [body] binds `final` from a call —
  /// `codespecs_derivation_contract.md` §2.4 kind 3.
  Set<String> _localsBoundFromCalls(CsMethodBody body) => {
        for (final statement in body.allStatements)
          if (statement.kind == CsStatementKind.localBinding &&
              statement.isFinal &&
              statement.call != null &&
              statement.boundName != null)
            statement.boundName!,
      };
}

// ---------------------------------------------------------------------------
// 7 — back-link set equality
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 7.
///
/// Three things, because `codespecs_derivation_contract.md` §2.5 makes the two
/// back-link annotations asymmetric: `@CodeSpec`
/// belongs to the **emission unit** — the top-level declaration — while
/// `@DocSpec` belongs to whichever declaration consumed a section, class or
/// member. So a member carrying `@DocSpec` alone is the normal case and not a
/// violation, a member carrying `@CodeSpec` at all is one, and the equality of
/// rule 4 is asserted where `@CodeSpec` is written.
class CsBackLinkAgreementCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsBackLinkAgreementCheck();

  @override
  int get number => 7;

  @override
  String get definedIn => '§2.5 rules 4–5';

  @override
  String get title =>
      '@CodeSpec sits on the emission unit and its section ids equal '
      'its @DocSpec set';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];

    // Members by their owner's name — the owner is unique in its locus under
    // N4, which check 1 enforces, so the name is the whole key it needs.
    final membersOf = <String, List<CsDeclaration>>{};
    for (final declaration in input.declarations) {
      final owner = declaration.owner;
      if (owner == null) continue;
      (membersOf[owner] ??= []).add(declaration);
    }

    for (final declaration in input.declarations) {
      final codeSpec = declaration.codeSpec;
      final docSpec = declaration.docSpec;

      if (!declaration.isTopLevel) {
        // A member never carries @CodeSpec: `source` accounts for the whole
        // emission unit, and a second one below it would double-count.
        if (codeSpec != null) {
          out.add(
            fail(
              '${declaration.path} carries @CodeSpec, but @CodeSpec belongs to '
              'the emission unit — the member states its sections in @DocSpec '
              'and ${declaration.owner} repeats them',
              codeSpec.location,
            ),
          );
        }
        continue;
      }

      // Rule 6: a declaration that adds no section of its own carries neither.
      if (codeSpec == null && docSpec == null) continue;
      if (codeSpec == null || docSpec == null) {
        out.add(
          fail(
            '${declaration.path} carries '
            '${codeSpec == null ? '@DocSpec without @CodeSpec' : '@CodeSpec without @DocSpec'}'
            ' — the two back-links are written together or not at all',
            declaration.location,
          ),
        );
        continue;
      }
      final fromCodeSpec = codeSpec.source.toSet();
      final fromDocSpec = docSpec.map((r) => r.sectionId).toSet();
      if (!_sameSet(fromCodeSpec, fromDocSpec)) {
        out.add(
          fail(
            '${declaration.path}: @CodeSpec.source {${fromCodeSpec.join(', ')}} '
            'differs from the @DocSpec section ids {${fromDocSpec.join(', ')}}',
            codeSpec.location,
          ),
        );
        continue;
      }

      // Rule 5: the unit's @DocSpec enumerates its members' sections too. This
      // is what makes `source` the union across the class and its members, and
      // so what keeps a member's section visible to the gap analysis — which
      // reads `source` and never looks inside a class.
      final missing = <String, String>{};
      for (final member in membersOf[declaration.path] ?? const <CsDeclaration>[]) {
        for (final ref in member.docSpec ?? const <CsDocRef>[]) {
          if (fromDocSpec.contains(ref.sectionId)) continue;
          missing.putIfAbsent(ref.sectionId, () => member.path);
        }
      }
      if (missing.isEmpty) continue;
      out.add(
        fail(
          '${declaration.path}: the emission unit omits '
          '${missing.entries.map((e) => '${e.key} (from ${e.value})').join(', ')}'
          " — a member's sections belong in the unit's @DocSpec and"
          ' @CodeSpec.source as well as on the member',
          codeSpec.location,
        ),
      );
    }
    return out;
  }

  bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

// ---------------------------------------------------------------------------
// 8 — per-kind slot exclusivity
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 8.
class CsSlotExclusivityCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsSlotExclusivityCheck();

  @override
  int get number => 8;

  @override
  String get definedIn => '§2.3';

  @override
  String get title =>
      "Only the slots of a marker's declared kind are non-null (@CsTrigger, "
      '@CsAuthorize, @CsJob)';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      for (final marker in declaration.markers) {
        final spec = csPerKindSlots[marker.name];
        if (spec == null) continue;
        final kind = enumConstantName(marker.named[spec.discriminator]);
        if (kind == null) continue;
        final allowed = spec.slots[kind];
        if (allowed == null) {
          out.add(
            fail(
              "@${marker.name} on ${declaration.path} declares an unknown "
              "${spec.discriminator} '$kind'",
              marker.location,
            ),
          );
          continue;
        }
        final everySlot = spec.slots.values.expand((s) => s).toSet();
        for (final entry in marker.presentNamed.entries) {
          if (!everySlot.contains(entry.key)) continue;
          if (allowed.contains(entry.key)) continue;
          if (entry.value is CsListValue &&
              (entry.value as CsListValue).values.isEmpty) {
            continue;
          }
          out.add(
            fail(
              "@${marker.name} on ${declaration.path} declares "
              "${spec.discriminator} '$kind' but fills the '${entry.key}' slot, "
              'which belongs to '
              '${_ownersOf(spec.slots, entry.key).join(' / ')}',
              marker.location,
            ),
          );
        }
      }
    }
    return out;
  }

  List<String> _ownersOf(Map<String, Set<String>> slots, String slot) => [
        for (final entry in slots.entries)
          if (entry.value.contains(slot)) entry.key,
      ];
}

// ---------------------------------------------------------------------------
// 9 — mirrored catalogues
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 9.
///
/// The mirror pairs are supplied by the caller because the two sides live in
/// packages that must not depend on each other (`codespecs_mapping.md` §9.5) —
/// this validator is the third party that may read both, as source.
class CsMirroredCatalogueCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsMirroredCatalogueCheck();

  @override
  int get number => 9;

  @override
  String get definedIn => '§5.3';

  @override
  String get title =>
      'Every mirrored enum matches its tom_core counterpart value-for-value';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final mirror in input.enumMirrors) {
      if (_same(mirror.csValues, mirror.coreValues)) continue;
      out.add(
        fail(
          '${mirror.csEnumName} [${mirror.csValues.join(', ')}] does not '
          'mirror ${mirror.coreEnumName} [${mirror.coreValues.join(', ')}] '
          'value-for-value',
        ),
      );
    }
    return out;
  }

  bool _same(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ---------------------------------------------------------------------------
// 10 — error copy category
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 10.
class CsErrorCopyCategoryCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsErrorCopyCategoryCheck();

  @override
  int get number => 10;

  @override
  String get definedIn => '§3.1.3';

  @override
  String get title => '@CsText with role == error has category == errorCopy';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final marker = declaration.marker('CsText');
      if (marker == null) continue;
      if (enumConstantName(marker.named['role']) != 'error') continue;
      final category = enumConstantName(marker.named['category']) ?? 'uiCopy';
      if (category == 'errorCopy') continue;
      out.add(
        fail(
          '@CsText on ${declaration.path} has role error but category '
          '$category — error copy is keyed by the CE-ER error code, so the two '
          'cannot disagree',
          marker.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 11 — locus dependency arrow
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 11.
class CsLocusArrowCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsLocusArrowCheck();

  @override
  int get number => 11;

  @override
  String get definedIn => '§2.2';

  @override
  String get title =>
      'The shared → {client, server} dependency arrow is never inverted';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final forbidden = <CsLocus, Map<String, CsLocus>>{
      CsLocus.shared: {
        input.client.packageName: CsLocus.client,
        input.server.packageName: CsLocus.server,
      },
      CsLocus.client: {input.server.packageName: CsLocus.server},
      CsLocus.server: {input.client.packageName: CsLocus.client},
    };
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      final banned = forbidden[project.locus]!;
      for (final file in project.files) {
        for (final uri in file.imports) {
          final package = _packageOf(uri);
          if (package == null) continue;
          final target = banned[package];
          if (target == null) continue;
          out.add(
            fail(
              'the ${project.locus.label} project imports '
              "'$uri' — only client and server may depend on shared",
              CsLocation(file.path, 1),
            ),
          );
        }
      }
    }
    return out;
  }

  String? _packageOf(String uri) {
    if (!uri.startsWith('package:')) return null;
    final rest = uri.substring('package:'.length);
    final slash = rest.indexOf('/');
    return slash < 0 ? rest : rest.substring(0, slash);
  }
}

// ---------------------------------------------------------------------------
// 12 — operation agreement across loci
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 12.
class CsOperationAgreementCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsOperationAgreementCheck();

  @override
  int get number => 12;

  @override
  String get definedIn => '§3.4.2';

  @override
  String get title =>
      "A server handler's operation string equals its shared CsOperationRef";

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final declared = <String>{};
    for (final declaration in input.shared.declarations) {
      final marker = declaration.marker('CsEndpoint');
      final operation = marker?.firstPositionalString;
      if (operation != null && operation.trim().isNotEmpty) {
        declared.add(operation);
      }
    }
    for (final construction in input.shared.constructions) {
      if (construction.type != 'CsOperationRef') continue;
      final first = construction.positional.isEmpty
          ? null
          : construction.positional.first;
      if (first is CsStringValue && first.value.trim().isNotEmpty) {
        declared.add(first.value);
      }
    }

    final out = <CodeSpecsViolation>[];
    for (final declaration in input.server.declarations) {
      final marker = declaration.marker('CsEndpoint');
      if (marker == null) continue;
      final operation = marker.firstPositionalString;
      if (operation == null || operation.trim().isEmpty) continue;
      if (declared.contains(operation)) continue;
      out.add(
        fail(
          "the server handler ${declaration.path} declares operation "
          "'$operation', which the shared project does not declare — both "
          'halves carry the identical string',
          marker.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 13 — cumulative DDL convergence
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 13.
class CsMigrationConvergenceCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsMigrationConvergenceCheck();

  @override
  int get number => 13;

  @override
  String get definedIn => '§3.3.5';

  @override
  String get title =>
      'Cumulative CE-MG DDL converges on the @CsTable / @CsColumn model';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    if (input.migrations.isEmpty) return const [];
    final applied = applyMigrations(input.migrations);
    final model = _modelTables(input.server);

    final out = <CodeSpecsViolation>[];
    for (final entry in model.entries) {
      final table = entry.key;
      final columns = applied[table];
      if (columns == null) {
        out.add(
          fail(
            "@CsTable('$table') has no table in the cumulative CE-MG DDL",
            entry.value.location,
          ),
        );
        continue;
      }
      for (final column in entry.value.columns) {
        if (columns.contains(column.toLowerCase())) continue;
        out.add(
          fail(
            "@CsColumn '$column' of table '$table' has no column in the "
            'cumulative CE-MG DDL',
            entry.value.location,
          ),
        );
      }
    }
    for (final entry in applied.entries) {
      final modelTable = model[entry.key];
      if (modelTable == null) {
        out.add(
          fail(
            "the cumulative CE-MG DDL leaves table '${entry.key}', which no "
            '@CsTable declares',
          ),
        );
        continue;
      }
      final modelColumns = {
        for (final column in modelTable.columns) column.toLowerCase(),
      };
      for (final column in entry.value) {
        if (modelColumns.contains(column)) continue;
        out.add(
          fail(
            "the cumulative CE-MG DDL leaves column '$column' on table "
            "'${entry.key}', which no @CsColumn declares",
          ),
        );
      }
    }
    return out;
  }

  Map<String, _ModelTable> _modelTables(CsLocusProject server) {
    final byOwner = <String, List<CsDeclaration>>{};
    for (final declaration in server.declarations) {
      final owner = declaration.owner;
      if (owner == null) continue;
      byOwner.putIfAbsent(owner, () => []).add(declaration);
    }
    final out = <String, _ModelTable>{};
    for (final declaration in server.declarations) {
      final marker = declaration.marker('CsTable');
      if (marker == null) continue;
      final table = marker.firstPositionalString;
      if (table == null || table.trim().isEmpty) continue;
      final columns = <String>[];
      for (final member in byOwner[declaration.name] ?? const <CsDeclaration>[]) {
        final column = member.marker('CsColumn');
        if (column == null) continue;
        final named = column.named['column'];
        columns.add(named is CsStringValue ? named.value : member.name);
      }
      out[table.toLowerCase()] = _ModelTable(
        columns: columns,
        location: marker.location,
      );
    }
    return out;
  }
}

class _ModelTable {
  final List<String> columns;
  final CsLocation location;

  const _ModelTable({required this.columns, required this.location});
}

final _createTablePattern = RegExp(
  r'^\s*create\s+table\s+(?:if\s+not\s+exists\s+)?([`"\w.]+)\s*\(',
  caseSensitive: false,
);
final _dropTablePattern = RegExp(
  r'^\s*drop\s+table\s+(?:if\s+exists\s+)?([`"\w.]+)',
  caseSensitive: false,
);
final _alterAddPattern = RegExp(
  r'^\s*alter\s+table\s+([`"\w.]+)\s+add\s+(?:column\s+)?([`"\w]+)',
  caseSensitive: false,
);
final _alterDropPattern = RegExp(
  r'^\s*alter\s+table\s+([`"\w.]+)\s+drop\s+(?:column\s+)?([`"\w]+)',
  caseSensitive: false,
);

/// The keywords that open a table constraint rather than a column.
const _constraintKeywords = {
  'primary',
  'foreign',
  'unique',
  'key',
  'constraint',
  'index',
  'check',
};

/// Applies [migrations] in ascending version order, returning table name →
/// lower-cased column names.
///
/// Exposed for the check's test: the DDL walk is the part with behaviour of its
/// own, and a fixture that exercises it directly is what makes the check's
/// verdict readable.
Map<String, Set<String>> applyMigrations(Map<String, String> migrations) {
  final ordered = migrations.keys.toList()
    ..sort((a, b) {
      final byVersion = _versionOf(a).compareTo(_versionOf(b));
      return byVersion != 0 ? byVersion : a.compareTo(b);
    });
  final tables = <String, Set<String>>{};
  for (final path in ordered) {
    for (final statement in _statements(migrations[path]!)) {
      _apply(statement, tables);
    }
  }
  return tables;
}

int _versionOf(String path) {
  final base = path.split(RegExp(r'[/\\]')).last;
  final match = RegExp(r'\d+').firstMatch(base);
  return match == null ? 1 << 30 : int.parse(match.group(0)!);
}

Iterable<String> _statements(String sql) sync* {
  // Line comments would otherwise swallow the statement terminator.
  final stripped = sql.replaceAll(RegExp(r'--[^\n]*'), '');
  for (final part in stripped.split(';')) {
    if (part.trim().isEmpty) continue;
    yield part;
  }
}

void _apply(String statement, Map<String, Set<String>> tables) {
  final create = _createTablePattern.firstMatch(statement);
  if (create != null) {
    final table = _identifier(create.group(1)!);
    tables[table] = _createColumns(statement, create.end);
    return;
  }
  final drop = _dropTablePattern.firstMatch(statement);
  if (drop != null) {
    tables.remove(_identifier(drop.group(1)!));
    return;
  }
  final add = _alterAddPattern.firstMatch(statement);
  if (add != null) {
    final table = _identifier(add.group(1)!);
    tables.putIfAbsent(table, () => <String>{}).add(
          _identifier(add.group(2)!),
        );
    return;
  }
  final dropColumn = _alterDropPattern.firstMatch(statement);
  if (dropColumn != null) {
    tables[_identifier(dropColumn.group(1)!)]
        ?.remove(_identifier(dropColumn.group(2)!));
  }
}

Set<String> _createColumns(String statement, int bodyStart) {
  var depth = 1;
  final buffer = StringBuffer();
  for (var i = bodyStart; i < statement.length && depth > 0; i++) {
    final char = statement[i];
    if (char == '(') depth++;
    if (char == ')') {
      depth--;
      if (depth == 0) break;
    }
    buffer.write(char);
  }
  final columns = <String>{};
  for (final item in _topLevelItems(buffer.toString())) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) continue;
    final name = _identifier(trimmed.split(RegExp(r'\s+')).first);
    if (_constraintKeywords.contains(name)) continue;
    columns.add(name);
  }
  return columns;
}

Iterable<String> _topLevelItems(String body) sync* {
  var depth = 0;
  final buffer = StringBuffer();
  for (final char in body.split('')) {
    if (char == '(') depth++;
    if (char == ')') depth--;
    if (char == ',' && depth == 0) {
      yield buffer.toString();
      buffer.clear();
      continue;
    }
    buffer.write(char);
  }
  if (buffer.isNotEmpty) yield buffer.toString();
}

String _identifier(String raw) {
  final unquoted = raw.replaceAll(RegExp('[`"]'), '');
  final dot = unquoted.lastIndexOf('.');
  return (dot < 0 ? unquoted : unquoted.substring(dot + 1)).toLowerCase();
}

// ---------------------------------------------------------------------------
// 14 — the non-declarable compose token
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 14.
class CsComposeTokenCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsComposeTokenCheck();

  @override
  int get number => 14;

  @override
  String get definedIn => '§3.2.2';

  @override
  String get title => '@CsValidation never emits the non-declarable compose token';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final marker = declaration.marker('CsValidation');
      if (marker == null) continue;
      final rules = marker.named['rules'];
      if (rules is! CsStringValue) continue;
      for (final term in rules.value.split(',')) {
        final name = term.split(':').first.trim();
        if (name != 'compose') continue;
        out.add(
          fail(
            "@CsValidation on ${declaration.path} declares 'compose' — the "
            'comma list is the composition, so the token is not declarable',
            marker.location,
          ),
        );
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 15 — overridableBy scope narrowing
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 15.
class CsOverridableScopeCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsOverridableScopeCheck();

  @override
  int get number => 15;

  @override
  String get definedIn => '§3.3.6, §5.3';

  @override
  String get title =>
      'overridableBy names a scope strictly narrower than the marker\'s own';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      for (final marker in declaration.markers) {
        final allowed = csOverridableScopes[marker.name];
        if (allowed == null) continue;
        final scope = enumConstantName(marker.named['overridableBy']);
        if (scope == null || allowed.contains(scope)) continue;
        out.add(
          fail(
            '@${marker.name} on ${declaration.path} opens scope '
            "'$scope', which is not strictly narrower than its own — it may "
            'open ${allowed.join(' / ')}',
            marker.location,
          ),
        );
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 16 — a secret carries no default
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 16.
class CsSecretInitialiserCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsSecretInitialiserCheck();

  @override
  int get number => 16;

  @override
  String get definedIn => '§3.3.6';

  @override
  String get title =>
      'A @CsServerConfig(secret: true) member has no initialiser';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final marker = declaration.marker('CsServerConfig');
      if (marker == null) continue;
      final secret = marker.named['secret'];
      if (secret is! CsBoolValue || !secret.value) continue;
      if (!declaration.hasInitialiser) continue;
      out.add(
        fail(
          '${declaration.path} is a secret setting with an initialiser — a '
          'secret declares presence and shape only, so a default is a '
          'credential in the source tree',
          declaration.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 17 — notification fallback channel
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 17.
///
/// A declaration **cycle is not a violation**: membership is all that is
/// asked, and `fallbackChainFrom` stops at the first channel already visited.
class CsFallbackChannelCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsFallbackChannelCheck();

  @override
  int get number => 17;

  @override
  String get definedIn => '§3.2.9';

  @override
  String get title =>
      'Every TomNotificationChannelDeclaration.fallbackChannelId resolves to a '
      'channel declared in the same catalogue';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      final byCatalogue = <String, List<CsConstruction>>{};
      for (final construction in project.constructions) {
        if (construction.type != 'TomNotificationChannelDeclaration') continue;
        byCatalogue
            .putIfAbsent(_catalogueOf(construction), () => [])
            .add(construction);
      }
      for (final entry in byCatalogue.entries) {
        final declared = <String>{
          for (final channel in entry.value)
            if (channel.stringArgument('channelId') != null)
              channel.stringArgument('channelId')!,
        };
        for (final channel in entry.value) {
          final fallback = channel.stringArgument('fallbackChannelId');
          if (fallback == null || fallback.trim().isEmpty) continue;
          if (declared.contains(fallback)) continue;
          out.add(
            fail(
              "channel '${channel.stringArgument('channelId') ?? '?'}' falls "
              "back to '$fallback', which the catalogue ${entry.key} does not "
              'declare',
              channel.location,
            ),
          );
        }
      }
    }
    return out;
  }

  String _catalogueOf(CsConstruction construction) {
    final holder = construction.holder;
    if (holder == null) return '<file>';
    final dot = holder.indexOf('.');
    return dot < 0 ? holder : holder.substring(0, dot);
  }
}

// ---------------------------------------------------------------------------
// 18 — report drill-through route
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 18.
///
/// The one check that looks **across projects** in the direction generated code
/// may not take: it resolves a server-owned column's route id against the
/// client project, which the server never depends on.
class CsDrillThroughRouteCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsDrillThroughRouteCheck();

  @override
  int get number => 18;

  @override
  String get definedIn => '§3.3.9';

  @override
  String get title =>
      'Every TomReportColumn.drillThroughRouteId resolves to a CE-NV route '
      'declared in the client project';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final routes = <String>{};
    for (final declaration in input.client.declarations) {
      if (declaration.has('CsRoute')) {
        routes.add(declaration.name);
        routes.add(declaration.path);
      }
    }
    for (final construction in input.client.constructions) {
      if (construction.type != 'CsRouteRef') continue;
      final first = construction.positional.isEmpty
          ? null
          : construction.positional.first;
      if (first is CsStringValue) routes.add(first.value);
    }

    final out = <CodeSpecsViolation>[];
    for (final construction in input.server.constructions) {
      if (construction.type != 'TomReportColumn') continue;
      final route = construction.stringArgument('drillThroughRouteId');
      if (route == null || route.trim().isEmpty) continue;
      if (routes.contains(route)) continue;
      out.add(
        fail(
          "the report column ${construction.holder ?? '<anonymous>'} drills "
          "through to route '$route', which the client project does not "
          'declare',
          construction.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 19 — a secret is only ever declared
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 19.
///
/// CE-CF has two authoring shapes (`codespecs_mapping.md` §5.16): the
/// *declared* shape, where the application owns the setting key and authors
/// every property of it, and the *fixed* shape, where the model owns the key
/// and the author supplies the value only. `secret: true` is authorable on the
/// declared shape alone. Both shapes ride narrative-borne forms, so both emit
/// the same back-link token (`codespecs_derivation_contract.md` §2.5 rule 2)
/// and the `@DocSpec` cannot tell them
/// apart — what can is the **key**: the declared shape's key is authored
/// verbatim into the extract as a [_declaredShapeClass] `settingKey` value,
/// while a fixed band's key is N10-derived and appears in no extract. A secret
/// member whose key the extracts do not declare means a credential slot was
/// invented in a policy section.
class CsSecretIsDeclaredCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsSecretIsDeclaredCheck();

  /// The SOM model class of CE-CF's declared shape.
  static const _declaredShapeClass = 'ServerConfigurationSettingEntry';

  /// The `@Form` field of [_declaredShapeClass] that authors the key.
  static const _keyFormField = 'settingKey';

  @override
  int get number => 19;

  @override
  String get definedIn => '§3.3.6';

  @override
  String get title =>
      'A @CsServerConfig(secret: true) member keys a declared setting';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    if (input.extracts.isEmpty) return const [];
    final declaredKeys = <String>{
      for (final e in input.extracts.entries)
        if (e.className == _declaredShapeClass && e.formField == _keyFormField)
          e.value.trim(),
    };
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final marker = declaration.marker('CsServerConfig');
      if (marker == null) continue;
      final secret = marker.named['secret'];
      if (secret is! CsBoolValue || !secret.value) continue;
      final key = marker.firstPositionalString?.trim();
      // A blank key is check 4's violation, not this one's.
      if (key == null || key.isEmpty) continue;
      if (declaredKeys.contains(key)) continue;
      out.add(
        fail(
          "${declaration.path} is a secret setting whose key '$key' matches "
          'no declared $_declaredShapeClass entry in the extracts — the '
          'fixed-shape CE-CF bands name settings the model owns and carry '
          'values only, so a credential slot there is a specification defect',
          declaration.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 20 — setting keys share one namespace
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 20.
///
/// N10 puts CE-CF's derived keys (`<band>.<field>`, the fixed shape) and its
/// authored keys (`SCSET`, the declared shape) in **one** namespace under one
/// collision rule. Neither shape can see the other while it is being authored:
/// a band's key is derived from a class name whose `Policy`/`Settings`/
/// `Selection`/`Entry` suffix is dropped — so two differently-named bands can
/// reduce to the same `<band>` — and an `SCSET` author writes free strings with
/// no view of what the bands derived. The trio is the first place both are
/// visible, which is why the collision is caught here and not in either shape.
///
/// This is N4 applied to the key rather than the identifier, so like check 1 it
/// never auto-suffixes: a deployment key is a contract with the operator and
/// silently renaming one loses whichever value was set against it.
class CsSettingKeyCollisionCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsSettingKeyCollisionCheck();

  @override
  int get number => 20;

  @override
  String get definedIn => '§2.1 N10';

  @override
  String get title =>
      'Two @CsServerConfig members claiming the same setting key fail, naming '
      'both section ids';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    final seen = <String, CsDeclaration>{};
    for (final declaration in input.declarations) {
      final marker = declaration.marker('CsServerConfig');
      if (marker == null) continue;
      final key = marker.firstPositionalString?.trim();
      // A blank key is check 4's violation, not this one's.
      if (key == null || key.isEmpty) continue;
      final first = seen[key];
      if (first == null) {
        seen[key] = declaration;
        continue;
      }
      out.add(
        fail(
          "setting key '$key' is claimed twice — by ${first.path} from "
          'section(s) ${sectionsOf(first)} (${first.location}) and by '
          '${declaration.path} from section(s) ${sectionsOf(declaration)}; '
          'derived and authored setting keys share one namespace (N10) and '
          'N4 never auto-suffixes',
          declaration.location,
        ),
      );
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 21 — graded depth is exactly one level
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 21.
///
/// The SOM bounds the graded depth **structurally**: a graded level is a
/// `GradedAccessLevelEntry`, whose kind enum has no `graded` constant, so a
/// second grading nested inside a level is unauthorable.
/// `tom_specs_model_rules.md` §5.7 leaves no alternative — a self-recursive
/// requirement class is a structural cycle and a hard error.
///
/// The code side has no such type barrier: `CsGradedAccess`'s three slots are
/// each a `@CsAuthorize`, and `@CsAuthorize` *does* have a `graded` arm. So the
/// nesting is expressible in hand-written CodeSpecs even though no generator
/// run can produce it, and without this check the two sides diverge exactly
/// where the SOM was made deliberately strict — surfacing as a runtime access
/// decision rather than a generation error.
///
/// The bound is not arbitrary. A graded requirement resolves to one of four
/// **terminal** access states (`none < disabled < read < full`), so a grading
/// nested inside a level has nothing left to resolve to.
class CsGradedDepthCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsGradedDepthCheck();

  @override
  int get number => 21;

  @override
  String get definedIn => '§3.4.3';

  @override
  String get title =>
      "A CsGradedAccess slot's @CsAuthorize is never itself graded — the graded "
      'depth is exactly one level';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      for (final marker in declaration.markers) {
        if (marker.name != 'CsAuthorize') continue;
        final graded = marker.named['graded'];
        if (graded is! CsConstructionValue) continue;
        _walkGraded(graded, declaration, marker, out);
      }
    }
    return out;
  }

  /// Reports every nested `@CsAuthorize` under [graded] that is itself graded.
  ///
  /// Recursive so a violation two levels down is still named rather than hidden
  /// behind the one above it — the whole point of the check is that this
  /// nesting has no depth limit in Dart.
  void _walkGraded(
    CsConstructionValue graded,
    CsDeclaration declaration,
    CsMarker marker,
    List<CodeSpecsViolation> out,
  ) {
    for (final slot in const ['full', 'read', 'disabled']) {
      final nested = graded.named[slot];
      if (nested is! CsConstructionValue) continue;
      if (nested.type != 'CsAuthorize') continue;
      final requirement = enumConstantName(nested.named['requirement']);
      if (requirement != 'graded') continue;
      out.add(
        fail(
          '@CsAuthorize on ${declaration.path} nests a graded requirement in '
          "its CsGradedAccess '$slot' slot; the graded depth is exactly one "
          'level, because a graded requirement resolves to one of four terminal '
          'access states and the SOM (AZLVL) cannot author a second grading',
          marker.location,
        ),
      );
      final inner = nested.named['graded'];
      if (inner is CsConstructionValue) {
        _walkGraded(inner, declaration, marker, out);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 22 — a persisted column is never an observable
// ---------------------------------------------------------------------------

/// `tom_core_kernel`'s observable family, by name
/// (`tom_core_kernel/lib/src/tombase/observable/tom_observable_objects.dart`).
///
/// A **closed list**, not a `Tom` prefix rule: `TomZonedDate`, `TomZonedTime`
/// and `TomZonedDateTime` are plain value types and legitimate column types, so
/// a prefix rule would reject code the contract permits. Every name here is a
/// `TomObservable` subtype and therefore something
/// [TomColumnInformation.getVariableValue] would hand the driver *as an
/// object*.
const csObservableTypes = <String>{
  'TomObservable',
  'TomObject',
  'TomString',
  'TomInt',
  'TomDouble',
  'TomBool',
  'TomDateTime',
  'TomOTimezoned',
  'TomOZonedTime',
  'TomOZonedDate',
  'TomOZonedDateTime',
  'TomNString',
  'TomNInt',
  'TomNDouble',
  'TomNBool',
  'TomNDateTime',
  'TomNOTimezoned',
  'TomNOZonedTime',
  'TomNOZonedDate',
  'TomNOZonedDateTime',
  'TomClass',
  'TomList',
  'TomMap',
  'TomDateRange',
  'TomTimeRange',
  'TomDateTimeRange',
};

/// `codespecs_derivation_contract.md` §6 check 22.
///
/// The one asymmetry a reviewer cannot see by reading the entity: an observable
/// member **reads** back correctly — `MariadbDatasource` normalises a `String?`
/// onto `String` before dispatching to the observable's setter — but has no
/// write path at all. `TomSqlDatasourceRepository.save` binds each column from
/// `TomColumnInformation.getVariableValue`, which is
/// `invokeGetter(declaredName)` and so yields the `TomNString` *object* rather
/// than the `String?` it holds.
///
/// So the wrong shape compiles, analyses clean, and passes any test that only
/// selects — right up to the first save, where it throws a `TypeError` deep in
/// the repository. That is exactly the class of defect a generation-time check
/// exists for, and it is why `codespecs_derivation_contract.md` §3.3.2 emits an
/// optional CE-DB attribute as a plain nullable field `T?`. The observable
/// family belongs to CE-ST (`codespecs_derivation_contract.md` §3.5.1), where
/// there is no persistence step to break.
class CsColumnNotObservableCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsColumnNotObservableCheck();

  @override
  int get number => 22;

  @override
  String get definedIn => '§3.3.2';

  @override
  String get title =>
      'A @CsColumn member is a plain Dart field, never a TomN*/observable — an '
      'observable column reads but cannot be written';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      // Resolved per project: a holder path is only unique within one project,
      // and an entity never spans two.
      final observableHolders = <String, String>{};
      for (final construction in project.constructions) {
        if (!csObservableTypes.contains(construction.type)) continue;
        final holder = construction.holder;
        if (holder == null) continue;
        observableHolders[holder] = construction.type;
      }

      for (final declaration in project.declarations) {
        if (!declaration.has('CsColumn')) continue;
        // Two spellings, and both have to be caught: `TomNString name;` names
        // the type, while the far commoner `final name = TomNString(null);`
        // never does — it is only visible through what the initialiser builds.
        final named = _observableIn(declaration.declaredType);
        final built = observableHolders[declaration.path];
        final offender = named ?? built;
        if (offender == null) continue;
        out.add(
          fail(
            '${declaration.path} is a @CsColumn declared as $offender; a '
            'persisted attribute is a plain Dart field (`T?` when optional), '
            'because the repository binds a column from invokeGetter and would '
            'hand the driver the $offender object rather than its value — the '
            'observable family is CE-ST (§3.5.1), not CE-DB',
            declaration.location,
          ),
        );
      }
    }
    return out;
  }

  /// The observable [source] declares, or `null` when it declares none.
  ///
  /// Strips the nullability suffix and any type arguments, so
  /// `TomList<TomInt>?` is recognised by its head — the family membership is
  /// the head's, and a generic argument may itself be a legitimate value type.
  String? _observableIn(String? source) {
    if (source == null) return null;
    var head = source.trim();
    final angle = head.indexOf('<');
    if (angle >= 0) head = head.substring(0, angle);
    head = head.replaceAll('?', '').trim();
    final dot = head.lastIndexOf('.');
    if (dot >= 0) head = head.substring(dot + 1);
    return csObservableTypes.contains(head) ? head : null;
  }
}

// ---------------------------------------------------------------------------
// 23, 24 — the abstract collaborator
// ---------------------------------------------------------------------------

/// The single field name a form-3b body reaches its collaborator through
/// (`codespecs_derivation_contract.md` §3.0.1 point 2).
///
/// Fixed rather than derived: the injection is one `late final NameCollaborator
/// collaborator;` field per declaration, so the receiver spelling in every 3b
/// body is this word. That is what lets a *syntax* pass resolve the call at
/// all.
const csCollaboratorField = 'collaborator';

/// The collaborator classes an [input] emits, by name.
Map<String, CsDeclaration> _collaboratorClasses(
  CodeSpecsValidationInput input,
) =>
    {
      for (final declaration in input.declarations)
        if (declaration.isTopLevel && declaration.has('CsCollaborator'))
          declaration.name: declaration,
    };

/// The type name [source] declares, stripped of nullability, type arguments and
/// any library prefix.
String? _typeHead(String? source) {
  if (source == null) return null;
  var head = source.trim();
  final angle = head.indexOf('<');
  if (angle >= 0) head = head.substring(0, angle);
  head = head.replaceAll('?', '').trim();
  final dot = head.lastIndexOf('.');
  if (dot >= 0) head = head.substring(dot + 1);
  return head.isEmpty ? null : head;
}

/// `codespecs_derivation_contract.md` §6 check 23.
///
/// The check that makes "compiles" checkable *before* a compiler sees it, and
/// the two halves fail in opposite directions. A `collaborator.<m>(…)` that
/// resolves to nothing is a body `codespecs_derivation_contract.md` §2.4
/// forbade — the generator wrote a statement against a declaration it never
/// emitted. A collaborator method nothing calls is the reverse: a step's
/// behaviour was lifted out of the body and then dropped, so the specification
/// survives in the output but is no longer reached by it, and Phase 6 would
/// implement a method that runs nowhere.
///
/// **What it does not do.** The substrate half of the
/// `codespecs_derivation_contract.md` §6 row — a call on the `tom_core`-family
/// class an entry's point 2 names — needs the resolved element model, which
/// this pass deliberately does not have (`cs_reader`). A wrong substrate call
/// is a compile error in the emitted trio; a wrong collaborator call is silent,
/// or (the reverse half) never caught at all. The check covers exactly the
/// failures a compiler would find late or not at all.
class CsCollaboratorCallResolutionCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsCollaboratorCallResolutionCheck();

  @override
  int get number => 23;

  @override
  String get definedIn => '§2.4, §3.0.1';

  @override
  String get title =>
      'Every collaborator call in a form-3b body resolves to a method of the '
      'declaration\'s own @CsCollaborator class, and every collaborator method '
      'is called by at least one body of its owning declaration';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    final collaborators = _collaboratorClasses(input);
    // Method name → owning collaborator, so the reverse half can subtract what
    // the forward half saw called.
    final called = <String, Set<String>>{
      for (final name in collaborators.keys) name: <String>{},
    };

    for (final project in input.projects) {
      final fieldsByOwner = <String, CsDeclaration>{};
      for (final declaration in project.declarations) {
        if (declaration.kind != CsDeclarationKind.field) continue;
        if (declaration.name != csCollaboratorField) continue;
        final owner = declaration.owner;
        if (owner != null) fieldsByOwner[owner] = declaration;
      }

      for (final declaration in project.declarations) {
        if (!declaration.isTopLevel) continue;
        if (declaration.has('CsCollaborator')) continue;
        final field = fieldsByOwner[declaration.name];
        final collaboratorName = _typeHead(field?.declaredType);
        final collaborator = collaboratorName == null
            ? null
            : collaborators[collaboratorName];

        for (final body in declaration.bodies) {
          for (final call in body.calls) {
            if (call.receiver != csCollaboratorField) continue;
            if (field == null) {
              out.add(
                fail(
                  '${declaration.name}.${body.name} calls '
                  'collaborator.${call.method}, but ${declaration.name} '
                  'declares no `late final <Name>Collaborator collaborator;` '
                  'field — a form-3b body reaches its collaborator through that '
                  'one field and through nothing else',
                  call.location,
                ),
              );
              continue;
            }
            if (collaborator == null) {
              out.add(
                fail(
                  '${declaration.name}.collaborator is declared '
                  '${field.declaredType ?? 'without a type'}, which names no '
                  'emitted @CsCollaborator class, so '
                  '${declaration.name}.${body.name} resolves against nothing',
                  field.location,
                ),
              );
              continue;
            }
            final methods = _abstractMethodsOf(input, collaborator);
            if (!methods.contains(call.method)) {
              out.add(
                fail(
                  '${declaration.name}.${body.name} calls '
                  'collaborator.${call.method}, which '
                  '${collaborator.name} does not declare',
                  call.location,
                ),
              );
              continue;
            }
            called[collaborator.name]!.add(call.method);
          }
        }
      }
    }

    for (final collaborator in collaborators.values) {
      final reached = called[collaborator.name] ?? const <String>{};
      for (final method in _abstractMethodsOf(input, collaborator)) {
        if (reached.contains(method)) continue;
        out.add(
          fail(
            '${collaborator.name}.$method is declared but no body calls it — a '
            'collaborator method is one contributing step of its owning '
            'declaration, so an uncalled one is a step whose behaviour left the '
            'body and was never reached again',
            collaborator.location,
          ),
        );
      }
    }
    return out;
  }

  /// The abstract method names [collaborator] declares.
  Set<String> _abstractMethodsOf(
    CodeSpecsValidationInput input,
    CsDeclaration collaborator,
  ) =>
      {
        for (final declaration in input.project(collaborator.locus).declarations)
          if (declaration.owner == collaborator.name &&
              declaration.kind == CsDeclarationKind.method)
            declaration.name,
      };
}

/// `codespecs_derivation_contract.md` §6 check 24.
///
/// A collaborator is the one generated declaration built on **nothing**
/// (`codespecs_derivation_contract.md` §3.0.1 point 2, `@CsEnum` being the only
/// other): an `abstract class` holding one abstract method per contributing
/// step and not one member more. Every shape this rejects is a way of putting
/// behaviour or state back into the seam Phase 6 is supposed to fill — an
/// implemented method pre-empts the implementation, a field gives the seam
/// state the specification never described, a constructor makes it
/// constructible where it is only ever implemented, and a static member hides
/// logic in a place no step maps to.
class CsCollaboratorShapeCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsCollaboratorShapeCheck();

  @override
  int get number => 24;

  @override
  String get definedIn => '§3.0.1';

  @override
  String get title =>
      'A @CsCollaborator class is abstract, declares only abstract methods, and '
      'has no field, constructor or static member';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      final collaborators = <String, CsDeclaration>{};
      for (final declaration in project.declarations) {
        if (!declaration.isTopLevel) continue;
        if (!declaration.has('CsCollaborator')) continue;
        collaborators[declaration.name] = declaration;
        if (declaration.isAbstract) continue;
        out.add(
          fail(
            '${declaration.name} carries @CsCollaborator but is not declared '
            'abstract — a collaborator is implemented in Phase 6, never '
            'instantiated by the generated code',
            declaration.location,
          ),
        );
      }

      for (final member in project.declarations) {
        final owner = member.owner;
        if (owner == null) continue;
        final collaborator = collaborators[owner];
        if (collaborator == null) continue;
        final offence = switch (member.kind) {
          CsDeclarationKind.field => 'a field',
          CsDeclarationKind.constructor => 'a constructor',
          CsDeclarationKind.method when member.isStatic => 'a static member',
          CsDeclarationKind.method
              when member.bodies.any((b) => b.shape != CsBodyShape.none) =>
            'an implemented method',
          _ => null,
        };
        if (offence == null) continue;
        out.add(
          fail(
            '$owner.${member.name} is $offence on a @CsCollaborator class, '
            'which holds one abstract method per contributing step and nothing '
            'else',
            member.location,
          ),
        );
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 25, 26, 27 — the emitted comments
// ---------------------------------------------------------------------------

/// Whether [declaration] is a form-3a or form-3b declaration — one that carries
/// a generated body rather than only a signature.
///
/// `codespecs_derivation_contract.md` §2.8 C2 P3 attaches its requirement to
/// the *declaration*, not to the individual method, so the classification is
/// made once over all its bodies: a declaration one of whose methods throws its
/// explication (3a) or calls a collaborator (3b) is a form-3 declaration, and
/// then **every** method of it carries a comment. A form-1/2/4 declaration
/// carries none of this — its members are covered by P2 instead.
bool _isFormThreeDeclaration(CodeSpecsValidationInput input, CsDeclaration d) {
  if (!d.isTopLevel) return false;
  for (final member in input.project(d.locus).declarations) {
    if (member.owner != d.name) continue;
    for (final body in member.bodies) {
      if (body.shape == CsBodyShape.throwOnly) return true;
      if (body.isPseudoImplementation) return true;
    }
  }
  for (final body in d.bodies) {
    if (body.shape == CsBodyShape.throwOnly) return true;
    if (body.isPseudoImplementation) return true;
  }
  return false;
}

/// `codespecs_derivation_contract.md` §6 check 25.
///
/// `codespecs_derivation_contract.md` §2.8 C2's fourth position is the one
/// whose absence the contract calls a **generation error** rather than a lapse
/// of style, and the reason is what a form-3 method is *for*: the body says
/// nothing (it throws, or it delegates), so the doc comment is the only place
/// the specification's own words survive into the code Phase 6 implements. A
/// method of a form-3 declaration with no comment is a step whose description
/// was dropped between the SOM and the output — the seam is there, but nobody
/// can see what it was supposed to do.
///
/// The abstract collaborator is held to the same rule for the same reason, and
/// more sharply: every one of its methods is a contributing step and has no
/// body at all.
class CsMethodCommentCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsMethodCommentCheck();

  @override
  int get number => 25;

  @override
  String get definedIn => '§2.8 C2 P3, §3.0.1';

  @override
  String get title =>
      'Every method of a form-3a or form-3b declaration, and every method of a '
      '@CsCollaborator class, carries a doc comment';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      final owners = <String, String>{};
      for (final declaration in project.declarations) {
        if (!declaration.isTopLevel) continue;
        if (declaration.has('CsCollaborator')) {
          owners[declaration.name] = 'a @CsCollaborator class';
        } else if (_isFormThreeDeclaration(input, declaration)) {
          owners[declaration.name] = 'a form-3 declaration';
        }
      }

      for (final member in project.declarations) {
        if (member.kind != CsDeclarationKind.method) continue;
        final owner = member.owner;
        if (owner == null) continue;
        final why = owners[owner];
        if (why == null) continue;
        final comment = member.docComment;
        if (comment != null && !comment.isEmpty) continue;
        out.add(
          fail(
            '$owner.${member.name} carries no doc comment, and $owner is $why — '
            'a form-3 method says nothing in its body, so the comment is the '
            'only place its SOM description reaches the code',
            member.location,
          ),
        );
      }
    }
    return out;
  }
}

/// The number of `//` lines `codespecs_derivation_contract.md` §2.7's banner
/// is.
const _csBannerLines = 3;

/// `codespecs_derivation_contract.md` §6 check 26.
///
/// `codespecs_derivation_contract.md` §2.8 C6 gives the in-body comment
/// position a value, and the value is *nothing*. It is the one C-rule that
/// forbids rather than requires, and it exists because an in-body comment is
/// where a generator starts explaining itself — "// TODO: implement", "// step
/// 2 of 3", "// derived from CLA-4.2". Every one of those is either already in
/// the doc comment (C2) or is generator commentary that no SOM section said,
/// which C1 forbids as a source.
///
/// `codespecs_derivation_contract.md` §2.7's three-line banner is the sole `//`
/// an emitted file may hold, so the check counts it out rather than filtering
/// all banner-position comments away: a fourth `//` above the imports is a
/// comment that has crept in beside the banner, and is exactly as forbidden as
/// one inside a body.
class CsNoInBodyCommentCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsNoInBodyCommentCheck();

  @override
  int get number => 26;

  @override
  String get definedIn => '§2.8 C6, §2.7';

  @override
  String get title =>
      'No generated file holds a non-documentation comment other than §2.7\'s '
      'three-line banner';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      for (final file in project.files) {
        var banner = 0;
        for (final comment in file.comments) {
          if (comment.isDocumentation) continue;
          if (comment.isBanner && banner < _csBannerLines) {
            banner++;
            continue;
          }
          out.add(
            fail(
              '${file.path} holds the comment `${comment.text.trim()}`; the only '
              '`//` an emitted file carries is §2.7\'s $_csBannerLines-line '
              'banner, and C6 gives every other position the value nothing',
              comment.location,
            ),
          );
        }
      }
    }
    return out;
  }
}

/// `codespecs_derivation_contract.md` §6 check 27.
///
/// The three C4 shape rules a syntax pass can see. Each one is a way the same
/// promise breaks: C4.1's trailing whitespace and C4.3's blank line are
/// whitespace a second run may or may not reproduce, and C4.4's escapes decide
/// whether dartdoc renders the specification's own words or silently eats them
/// — an unescaped `[Order]` becomes a broken reference, an unescaped `<name>`
/// an HTML tag that renders as nothing at all.
///
/// **Why it is not all of C4.** C4.2 (no re-wrapping, no truncation) compares
/// the emitted text against the SOM text it came from, which is not in the
/// trio. It is [CsCommentFidelityCheck]'s, over the extract; this check reads
/// what a reader of the emitted file alone can see.
class CsDocCommentShapeCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsDocCommentShapeCheck();

  @override
  int get number => 27;

  @override
  String get definedIn => '§2.8 C4';

  @override
  String get title =>
      'A doc comment carries no trailing whitespace, sits immediately above the '
      'first annotation with no blank line, and escapes `[`, `]` and `<` outside '
      'fenced code blocks';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final comment = declaration.docComment;
      if (comment == null) continue;

      for (final line in comment.lines) {
        if (line.trimRight().length == line.length) continue;
        out.add(
          fail(
            '${declaration.path} has a doc-comment line with trailing '
            'whitespace (`$line`) — C4.1 emits one source line as one `/// ` '
            'line and nothing after it',
            comment.location,
          ),
        );
      }

      final next = declaration.firstAnnotationLine;
      if (next != comment.endLine + 1) {
        out.add(
          fail(
            '${declaration.path} has ${next - comment.endLine - 1} blank line(s) '
            'between its doc comment and the first annotation — C4.3 puts the '
            'block\'s last line immediately above it',
            comment.location,
          ),
        );
      }

      var fenced = false;
      for (final line in comment.text) {
        if (line.trimLeft().startsWith('```')) {
          fenced = !fenced;
          continue;
        }
        if (fenced) continue;
        final offender = _unescaped(line);
        if (offender == null) continue;
        out.add(
          fail(
            '${declaration.path} has an unescaped `$offender` in its doc comment '
            '(`$line`) — C4.4 escapes `[` and `]` and writes `<` as `&lt;`, so '
            'the specification\'s own words survive dartdoc',
            comment.location,
          ),
        );
      }
    }
    return out;
  }

  /// The first character of [line] C4.4 requires escaped and which is not, or
  /// `null` when every one of them is.
  String? _unescaped(String line) {
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == r'\') {
        i++;
        continue;
      }
      if (char == '[' || char == ']' || char == '<') return char;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// 28, 29, 30 — the form-3b body
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 28.
///
/// `codespecs_derivation_contract.md` §2.4 lists five statement kinds a form-3b
/// body may contain, and the list is closed for one reason: a body that stays
/// inside it cannot compute anything. The excluded shapes are all ways of
/// computing — a literal is a value the generator invented, arithmetic and
/// string building are results derived in the body rather than obtained from a
/// seam, and an unstated `try` is control flow no section asked for. Each of
/// them would make the pseudo-implementation run to a result, which
/// `codespecs_derivation_contract.md` §2.4 invariant 4 forbids outright.
///
/// The `final` half of kind 3 is not decoration: a non-`final` local can be
/// reassigned, and a body that reassigns is a body that computes.
/// `codespecs_derivation_contract.md` §2.4 B3 goes further for the collaborator
/// specifically — this derivation binds nothing, it awaits or returns — so a
/// binding of a *collaborator* call is a B3 breach even though kind 3 would
/// admit the shape in general.
class CsBodyStatementShapeCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsBodyStatementShapeCheck();

  @override
  int get number => 28;

  @override
  String get definedIn => '§2.4, §2.4 B3';

  @override
  String get title =>
      'A form-3b body contains only the five §2.4 statement kinds, its local '
      'bindings are final and initialised from a call, and it binds no '
      'collaborator result';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final (:declaration, :body) in csBodies(input)) {
      if (!body.isPseudoImplementation) continue;
      final where = csBodyPath(declaration, body);
      for (final statement in body.allStatements) {
        switch (statement.kind) {
          case CsStatementKind.other:
            out.add(
              fail(
                '$where contains `${statement.source}`, which is none of the '
                'five §2.4 statement kinds — a form-3b body obtains values, '
                'it does not compute them',
                statement.location,
              ),
            );
          case CsStatementKind.thrown:
            out.add(
              fail(
                '$where contains `${statement.source}`; a throw is the whole '
                'of a form-3a body and never a statement of a 3b one',
                statement.location,
              ),
            );
          case CsStatementKind.localBinding:
            if (!statement.isFinal) {
              out.add(
                fail(
                  '$where binds `${statement.boundName}` without `final` — a '
                  'reassignable local is a body that computes, and §2.4 kind '
                  '3 binds a call result once',
                  statement.location,
                ),
              );
            } else if (statement.call == null) {
              out.add(
                fail(
                  '$where binds `${statement.boundName}` from '
                  '`${statement.valueSource}`, which is not a call — §2.4 '
                  'kind 3 binds the result of kind 1 or kind 2 and of nothing '
                  'else',
                  statement.location,
                ),
              );
            } else if (statement.call!.receiver == csCollaboratorField) {
              out.add(
                fail(
                  '$where binds the result of '
                  'collaborator.${statement.call!.method} — §2.4 B3 emits '
                  '`await collaborator.<m>(…);` on every step but the last '
                  'and `return collaborator.<m>(…)` on it, and no local '
                  'binding at all',
                  statement.location,
                ),
              );
            }
          case CsStatementKind.call:
          case CsStatementKind.controlFlow:
          case CsStatementKind.returned:
            break;
        }
      }
    }
    return out;
  }
}

/// `codespecs_derivation_contract.md` §6 check 29.
///
/// `codespecs_derivation_contract.md` §2.4 B4 turns a stated condition into a
/// **guard method on the collaborator** rather than into an expression, and the
/// reason is that the condition arrives as prose. A generator that emitted `if
/// (order.total > limit)` would have parsed English into Dart and guessed at
/// both the operands and the operator; a generator that emits `if (await
/// collaborator.chargeOrderOverLimitApplies(…))` has moved the same sentence
/// into a named seam, where Phase 6 reads the comment and implements it. The
/// first is a guess that compiles, which is the worst kind.
///
/// **Repetition and multi-way choice.** `codespecs_derivation_contract.md` §2.4
/// kind 4 permits `for` and `switch`, but B7 states that this derivation
/// produces neither: no `codespecs_derivation_contract.md` §3 entry names a
/// structured surface that states repetition or a multi-way selection, so a
/// `for` or a `switch` in a generated body came from somewhere other than the
/// specification. The check moves when an entry names such a surface — the same
/// stated bound as check 21's and check 23's.
class CsBranchConditionCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsBranchConditionCheck();

  @override
  int get number => 29;

  @override
  String get definedIn => '§2.4 B4, §2.4 B7';

  @override
  String get title =>
      'Every branch in a generated body is an `if` on a collaborator guard '
      'call, never a composed expression, and no body repeats or selects '
      'multi-way';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final (:declaration, :body) in csBodies(input)) {
      if (!body.isPseudoImplementation) continue;
      final where = csBodyPath(declaration, body);
      for (final statement in body.allStatements) {
        if (statement.kind != CsStatementKind.controlFlow) continue;
        switch (statement.keyword) {
          case 'block':
            break;
          case 'for':
          case 'while':
            out.add(
              fail(
                '$where repeats (`${statement.source}`) — §2.4 B7 states that '
                'no §3 entry names a structured surface stating repetition, '
                'so this derivation produces none',
                statement.location,
              ),
            );
          case 'switch':
            out.add(
              fail(
                '$where selects multi-way (`${statement.source}`) — §2.4 B7 '
                'states that no §3 entry names a structured surface stating a '
                'multi-way choice, so this derivation produces none',
                statement.location,
              ),
            );
          case 'if':
            final call = statement.call;
            if (call != null &&
                call.receiver == csCollaboratorField &&
                call.method.endsWith(csGuardSuffix)) {
              break;
            }
            out.add(
              fail(
                '$where branches on `${statement.valueSource}`, which is not a '
                'collaborator guard call — §2.4 B4 makes a stated condition a '
                '`…$csGuardSuffix` method on the collaborator rather than an '
                'expression the generator parsed out of prose',
                statement.location,
              ),
            );
          default:
            break;
        }
      }
    }
    return out;
  }
}

/// The fixed suffix a `codespecs_derivation_contract.md` §2.4 B4 guard method's
/// name ends in.
const csGuardSuffix = 'Applies';

/// Where a collaborator call sits in the body that makes it.
enum CsCallPosition {
  /// The call is the body's `return` — `codespecs_derivation_contract.md` §2.4
  /// B3's last contributing step.
  returned,

  /// The call is a statement of its own — an earlier contributing step.
  statement,

  /// The call is a branch condition — a `codespecs_derivation_contract.md` §2.4
  /// B4 guard.
  guard,

  /// The call initialises a local binding, which
  /// `codespecs_derivation_contract.md` §2.4 B3 does not emit; check 28 owns
  /// that breach, so check 30 does not judge the signature.
  binding,
}

/// One `collaborator.<m>(…)` call, with the body that makes it.
typedef CsCollaboratorCall = ({
  String collaborator,
  String method,
  CsCallPosition position,
  CsDeclaration caller,
  CsMethodBody body,
  CsLocation location,
});

/// Every collaborator call across the trio, with the body that makes it.
///
/// The receiver spelling is the whole resolution mechanism: point 2 of
/// `codespecs_derivation_contract.md` §3.0.1 fixes one
/// `late final <Name>Collaborator collaborator;` field per declaration, so a
/// syntax pass can name the collaborator a call reaches by reading that field's
/// declared type.
List<CsCollaboratorCall> csCollaboratorCalls(CodeSpecsValidationInput input) {
  final out = <CsCollaboratorCall>[];
  for (final project in input.projects) {
    final fieldsByOwner = <String, CsDeclaration>{};
    for (final declaration in project.declarations) {
      if (declaration.kind != CsDeclarationKind.field) continue;
      if (declaration.name != csCollaboratorField) continue;
      final owner = declaration.owner;
      if (owner != null) fieldsByOwner[owner] = declaration;
    }

    for (final declaration in project.declarations) {
      if (!declaration.isTopLevel) continue;
      if (declaration.has('CsCollaborator')) continue;
      final collaborator = _typeHead(fieldsByOwner[declaration.name]?.declaredType);
      if (collaborator == null) continue;

      for (final member in project.declarations) {
        if (member.owner != declaration.name) continue;
        for (final body in member.bodies) {
          for (final statement in body.allStatements) {
            final call = statement.call;
            if (call == null || call.receiver != csCollaboratorField) continue;
            final position = switch (statement.kind) {
              CsStatementKind.returned => CsCallPosition.returned,
              CsStatementKind.call => CsCallPosition.statement,
              CsStatementKind.controlFlow => CsCallPosition.guard,
              CsStatementKind.localBinding => CsCallPosition.binding,
              _ => null,
            };
            if (position == null) continue;
            out.add((
              collaborator: collaborator,
              method: call.method,
              position: position,
              caller: declaration,
              body: body,
              location: call.location,
            ));
          }
        }
      }
    }
  }
  return out;
}

/// `codespecs_derivation_contract.md` §6 check 30.
///
/// `codespecs_derivation_contract.md` §3.0.1 point 2 derives a collaborator
/// method's whole signature from the body that calls it — the parameters
/// "name-for-name and type-for-type", the return type from the call's position
/// — and a syntax pass can hold the generator to every part of it. The rule is
/// not tidiness. A collaborator method exists so a step's behaviour can be
/// *moved* out of the body without being *changed*; a parameter the caller does
/// not have is an input the specification never named, and a missing one is an
/// input the step needs and cannot reach. The return type says which of the
/// three positions the call is in, so a mismatch means the generator emitted a
/// step in a place its own derivation did not put it.
///
/// Where the check is silent: on a method it cannot find (check 23 reports the
/// unresolved call) and on a call that binds a local (check 28 reports the
/// binding, and a binding has no derived return type to compare).
class CsCollaboratorSignatureCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsCollaboratorSignatureCheck();

  @override
  int get number => 30;

  @override
  String get definedIn => '§3.0.1, §2.4 B3, §2.4 B4';

  @override
  String get title =>
      'A collaborator method repeats its calling body\'s parameters '
      'name-for-name and type-for-type, and its return type follows the call\'s '
      'position';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    final collaborators = _collaboratorClasses(input);

    for (final call in csCollaboratorCalls(input)) {
      if (call.position == CsCallPosition.binding) continue;
      final owner = collaborators[call.collaborator];
      if (owner == null) continue;
      final method = _methodOf(input, owner, call.method);
      if (method == null) continue;
      final signature = method.bodies.isEmpty ? null : method.bodies.first;
      if (signature == null) continue;
      final where = '${call.collaborator}.${call.method}';

      final declared = _spell(signature.parameters);
      final expected = _spell(call.body.parameters);
      if (declared != expected) {
        out.add(
          fail(
            '$where declares ($declared) but '
            '${call.caller.name}.${call.body.name} passes ($expected) — '
            '§3.0.1 point 2 repeats the calling body\'s list name-for-name and '
            'type-for-type, because a step that moved out of a body must not '
            'change on the way',
            method.location,
          ),
        );
      }

      final returned = signature.returnType?.trim();
      final wanted = switch (call.position) {
        CsCallPosition.returned => {call.body.returnType?.trim()},
        CsCallPosition.statement => {'void', 'Future<void>'},
        CsCallPosition.guard => {'bool', 'Future<bool>'},
        CsCallPosition.binding => const <String?>{},
      };
      if (wanted.isEmpty || wanted.contains(returned)) continue;
      final why = switch (call.position) {
        CsCallPosition.returned =>
          'the call is the body\'s return, so §2.4 B3 makes it the last '
              'contributing step and §3.0.1 gives it the calling body\'s return '
              'type',
        CsCallPosition.statement =>
          'the call is a statement, so §2.4 B3 makes it an earlier contributing '
              'step, which produces no value',
        CsCallPosition.guard =>
          'the call is a branch condition, so §2.4 B4 makes it a guard',
        CsCallPosition.binding => '',
      };
      out.add(
        fail(
          '$where returns ${returned ?? 'no declared type'} where '
          '${wanted.map((t) => t ?? 'no declared type').join(' or ')} is '
          'derived: $why',
          method.location,
        ),
      );
    }
    return out;
  }

  /// The method [name] of collaborator [owner], or `null` when it declares
  /// none.
  CsDeclaration? _methodOf(
    CodeSpecsValidationInput input,
    CsDeclaration owner,
    String name,
  ) {
    for (final declaration in input.project(owner.locus).declarations) {
      if (declaration.owner != owner.name) continue;
      if (declaration.kind != CsDeclarationKind.method) continue;
      if (declaration.name == name) return declaration;
    }
    return null;
  }

  /// The parameter list as one comparable string.
  String _spell(List<CsParameter> parameters) =>
      parameters.map((p) => p.toString()).join(', ');
}

// ---------------------------------------------------------------------------
// 31 — determinism
// ---------------------------------------------------------------------------

/// `codespecs_derivation_contract.md` §6 check 31.
///
/// The one check whose subject is two runs rather than one trio.
/// `codespecs_derivation_contract.md` §2.8 C5 and
/// `codespecs_derivation_contract.md` §2.1 N1 promise that regenerating over an
/// unchanged document reproduces the output byte-for-byte, and nothing inside a
/// single trio can witness that: a generator that iterates an unordered map, or
/// stamps a time, or numbers a name from a counter that survives between runs,
/// emits perfectly plausible output every time — it is only the *second* run
/// that shows the difference.
///
/// tscomp17's derivation is where this stops being hypothetical. B1 orders a 3b
/// body's statements by `codespecs_derivation_contract.md` §2.1 N8 document
/// order, and B4 names a guard method out of two headlines; both are
/// derivations over collections, and both would still compile if the collection
/// came back in another order. So the check diffs the two runs' file sets first
/// (a name that changed is a naming derivation that is not a function of its
/// input) and then their bytes.
///
/// The check needs a caller who ran the generator twice. When none did, it
/// raises nothing — see `bin/validate_codespecs.dart`, which says so on stdout
/// rather than letting a silent pass read as a verified one.
class CsDeterminismCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsDeterminismCheck();

  @override
  int get number => 31;

  @override
  String get definedIn => '§2.8 C5, §2.1 N1';

  @override
  String get title =>
      'Regenerating over an unchanged model reproduces the trio byte-for-byte';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final again = input.regeneration;
    if (again == null) return const [];

    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      final second = again.project(project.locus);
      final first = {for (final file in project.files) file.path: file.source};
      final repeat = {for (final file in second.files) file.path: file.source};

      for (final path in first.keys.toList()..sort()) {
        if (repeat.containsKey(path)) continue;
        out.add(
          fail(
            '${project.locus.label}: $path was emitted by the first run and not '
            'by the second — a file name that is not a function of the model is '
            'a naming derivation that read something other than the model',
          ),
        );
      }
      for (final path in repeat.keys.toList()..sort()) {
        if (first.containsKey(path)) continue;
        out.add(
          fail(
            '${project.locus.label}: $path was emitted by the second run and '
            'not by the first — the two runs read the same model and disagreed '
            'about what to emit',
          ),
        );
      }
      for (final path in first.keys.toList()..sort()) {
        final before = first[path];
        final after = repeat[path];
        if (after == null || before == after) continue;
        out.add(
          fail(
            '${project.locus.label}: $path differs between the two runs '
            '(${_firstDifference(before!, after)}) — §2.8 C5 reproduces every '
            'byte, and a difference here is an ordering or a stamp that is not '
            'derived from the model',
          ),
        );
      }
    }
    return out;
  }

  /// Where two texts first diverge, in the vocabulary of a reader of the file.
  String _firstDifference(String before, String after) {
    final a = before.split('\n');
    final b = after.split('\n');
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] == b[i]) continue;
      return 'line ${i + 1}: `${a[i].trim()}` became `${b[i].trim()}`';
    }
    return 'the second run emitted ${b.length} line(s) where the first emitted '
        '${a.length}';
  }
}

// ---------------------------------------------------------------------------
// 32, 33, 34 — the comment rules, read against the extract
// ---------------------------------------------------------------------------

/// What one declaration's doc comment is allowed to say, and where that
/// permission came from.
///
/// Built once per declaration and read by checks 32 and 34, which ask two
/// questions of the same evidence: *is this line in the specification at all*
/// and *is it the line the specification holds, whole*.
class _CsCommentSources {
  /// The entries the declaration's `@DocSpec` sections contributed.
  final List<CsExtractEntry> entries;

  /// Whether the sections were named by a `@DocSpec` (traced) or the whole
  /// extract set stood in for them (untraced —
  /// `codespecs_derivation_contract.md` §3.1.1's enum constants).
  final bool traced;

  const _CsCommentSources(this.entries, {required this.traced});

  /// Every permitted line, in both the escaped and the raw spelling.
  Set<String> get lines => {
        for (final entry in entries) ...entry.escapedLines,
        for (final entry in entries) ...entry.rawLines,
      };

  /// Whether [line] is a fragment of a permitted line — the signature of a
  /// re-wrap, which is check 34's business rather than check 32's.
  ///
  /// Only asked of a line that is not itself permitted, so a short line that
  /// happens to also occur inside a longer one never reaches here.
  bool holdsFragment(String line) => fragmentOf(line) != null;

  /// The permitted line [line] is part of, or `null` when it is part of none.
  String? fragmentOf(String line) {
    final needle = line.trim();
    if (needle.isEmpty) return null;
    for (final permitted in lines) {
      if (permitted.contains(needle)) return permitted;
    }
    return null;
  }
}

/// The permitted sources for [declaration], or `null` when the extract tree
/// says nothing that bears on it.
_CsCommentSources? _commentSources(
  CsDeclaration declaration,
  CsExtractSet extracts,
) {
  final refs = declaration.docSpec;
  if (refs != null) {
    final ids = [for (final ref in refs) ref.sectionId];
    if (!ids.any(extracts.knowsSection)) return null;
    return _CsCommentSources(extracts.entriesForAll(ids), traced: true);
  }
  // A top-level declaration with no back-link is C3's grouped holder — check 33
  // owns it, and its one sentence is the single piece of generated prose C1
  // permits.
  if (declaration.isTopLevel) return null;
  // §2.8's one exception: §3.1.1 withholds the per-constant `@DocSpec` from a
  // domain enum *because* the constant's own comment identifies it. The comment
  // is still author text, so it must still occur in the specification — the
  // extract can say that much even though it cannot say which section.
  return _CsCommentSources(extracts.entries.toList(), traced: false);
}

/// `codespecs_derivation_contract.md` §6 check 32.
///
/// C1's fourth prohibition — *anything the agent composes* — made checkable.
/// Every other comment rule constrains text that came from somewhere; this one
/// constrains text that came from nowhere, and it is the failure
/// `codespecs_derivation_contract.md` §2.8 calls the one "where an authoring
/// agent is most tempted and least detectable". A summarised description reads
/// exactly like a written one, so the only evidence that separates them is the
/// specification text itself, which is what the extract carries.
///
/// **What it leaves to the SOM side.** C1 narrows the summary to a section's
/// *designated* description field, and the extract cannot say which field that
/// is — an entry names it in prose, in point 1, beside the designated name
/// field. So a comment built from the right section but the wrong field of it
/// passes here. The check catches invention, not mis-selection; the narrowing
/// stays an assertion about the authoring step rather than about its output.
class CsCommentSourceCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsCommentSourceCheck();

  @override
  int get number => 32;

  @override
  String get definedIn => '§2.8 C1';

  @override
  String get title =>
      'Every doc-comment line occurs in the extract of a section the '
      'declaration traces to — a line that occurs nowhere is composed prose';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    if (input.extracts.isEmpty) return const [];
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final comment = declaration.docComment;
      if (comment == null) continue;
      final sources = _commentSources(declaration, input.extracts);
      if (sources == null) continue;
      final permitted = sources.lines;

      for (final line in comment.verbatimText) {
        if (line.trim().isEmpty) continue;
        if (permitted.contains(line)) continue;
        // A fragment of a permitted line is a re-wrap or a truncation, which
        // check 34 diagnoses precisely. Reporting it here as well would give
        // one fault two messages and neither of them the right one.
        if (sources.holdsFragment(line)) continue;
        out.add(
          fail(
            '${declaration.path} has a doc-comment line no extract holds '
            '(`$line`) — C1 takes a comment from ${sources.traced ? 'the '
                'section its `@DocSpec` names' : 'the specification'}, and '
            'composes nothing',
            comment.location,
          ),
        );
      }
    }
    return out;
  }
}

/// `codespecs_derivation_contract.md` §6 check 33.
///
/// C3 grants exactly one generated sentence in the entire output, and grants it
/// only to a holder the agent created by grouping. The rule is worth a check
/// because the exception is where a second one would be added: a holder already
/// has no section, so a paragraph written for it breaks no back-link and reads
/// like the rest of the file.
///
/// **What it leaves to the SOM side.** The template's two slots are checked for
/// *shape*, not for content. `codespecs_mapping.md` §4.1 gives each part a
/// canonical id (`ErrorResult`) while C3's own illustration renders one as
/// prose (`Error codes`), and no rule states that rendering; and the extract's
/// document root is the model's root section segment, not the document's name.
/// Deciding the slots would mean inventing both mappings, which is how a
/// checker starts specifying.
class CsGroupedHolderCommentCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsGroupedHolderCommentCheck();

  /// The one sentence C3 permits: `<part name> for <document root name>.`
  static final RegExp _template = RegExp(r'^(\S.*) for (\S.*)\.$');

  @override
  int get number => 33;

  @override
  String get definedIn => '§2.8 C3';

  @override
  String get title =>
      'A grouped holder — a top-level declaration with no `@DocSpec` — carries '
      'C3\'s one-line template and no other generated prose';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    if (input.extracts.isEmpty) return const [];
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      if (!declaration.isTopLevel) continue;
      if (declaration.docSpec != null) continue;
      final comment = declaration.docComment;
      if (comment == null) continue;

      final said = [
        for (final line in comment.verbatimText)
          if (line.trim().isNotEmpty) line.trim(),
      ];
      if (said.isEmpty) continue;

      if (said.length > 1) {
        out.add(
          fail(
            '${declaration.path} traces to no section and carries '
            '${said.length} lines of prose — C3 grants a grouped holder the '
            'one-line template `<part name> for <document root name>.` and '
            'says no other generated sentence exists anywhere in the output',
            comment.location,
          ),
        );
        continue;
      }

      if (_template.hasMatch(said.single)) continue;
      out.add(
        fail(
          '${declaration.path} traces to no section and its comment '
          '(`${said.single}`) is not C3\'s template `<part name> for '
          '<document root name>.` — a declaration with author text behind it '
          'carries a `@DocSpec` instead',
          comment.location,
        ),
      );
    }
    return out;
  }
}

/// `codespecs_derivation_contract.md` §6 check 34.
///
/// C4.2 forbids the two edits that leave a comment still reading as the
/// specification: a re-wrap, which preserves every word and destroys the
/// markdown the words are written in, and a truncation, which preserves the
/// shape and drops the qualification that changes the meaning. Both survive
/// every other check — the comment is well-formed, its lines escape correctly,
/// and each word in it really does come from the specification — which is why
/// the rule needs the source text and not just the file.
///
/// The two failures are looked for from opposite ends. A re-wrap shows up
/// line-by-line: an emitted line that is a proper fragment of a source line is
/// a source line that was split. A truncation shows up value-by-value: a value
/// the comment started to render and did not finish.
class CsCommentFidelityCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsCommentFidelityCheck();

  @override
  int get number => 34;

  @override
  String get definedIn => '§2.8 C4.2';

  @override
  String get title =>
      'A doc-comment line is its source line entire — not a re-wrap of it, and '
      'not a value the comment stopped rendering part-way';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    if (input.extracts.isEmpty) return const [];
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final comment = declaration.docComment;
      if (comment == null) continue;
      final sources = _commentSources(declaration, input.extracts);
      // Only the traced tier: a value boundary is only meaningful when the
      // values are the ones this declaration claims, and the untraced tier
      // stands in the whole extract set for them.
      if (sources == null || !sources.traced) continue;

      final emitted = comment.verbatimText;
      final permitted = sources.lines;

      for (final line in emitted) {
        if (line.trim().isEmpty) continue;
        if (permitted.contains(line)) continue;
        final whole = sources.fragmentOf(line);
        if (whole == null) continue;
        out.add(
          fail(
            '${declaration.path} emits `$line`, which is part of the source '
            'line `$whole` — C4.2 preserves the source\'s line structure '
            'exactly, because a wrap width is a constant the contract does not '
            'state and a naive wrap destroys the markdown',
            comment.location,
          ),
        );
      }

      for (final entry in sources.entries) {
        final short = _truncationOf(entry, emitted);
        if (short == null) continue;
        out.add(
          fail(
            '${declaration.path} renders ${short.rendered} of the '
            '${short.total} lines of ${entry.origin} (${entry.sectionId}) — '
            'C4.2 forbids truncation, so a value a comment starts it finishes',
            comment.location,
          ),
        );
      }
    }
    return out;
  }

  /// How much of [entry] [emitted] rendered, when it rendered some and not all.
  ({int rendered, int total})? _truncationOf(
    CsExtractEntry entry,
    List<String> emitted,
  ) {
    for (final candidate in [entry.escapedLines, entry.rawLines]) {
      if (candidate.length < 2) continue;
      if (_contains(emitted, candidate)) return null;
      if (!emitted.contains(candidate.first)) continue;
      var rendered = 1;
      final start = emitted.indexOf(candidate.first);
      while (start + rendered < emitted.length &&
          rendered < candidate.length &&
          emitted[start + rendered] == candidate[rendered]) {
        rendered++;
      }
      return (rendered: rendered, total: candidate.length);
    }
    return null;
  }

  /// Whether [run] occurs in [lines] as a contiguous run.
  bool _contains(List<String> lines, List<String> run) {
    if (run.isEmpty || run.length > lines.length) return false;
    for (var i = 0; i <= lines.length - run.length; i++) {
      var match = true;
      for (var j = 0; j < run.length; j++) {
        if (lines[i + j] == run[j]) continue;
        match = false;
        break;
      }
      if (match) return true;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// 35, 36 — the transfer between the extract and the trio
// ---------------------------------------------------------------------------

/// Every extract token [declaration] traces to, across **both** back-links.
///
/// A token is `codespecs_derivation_contract.md` §2.5 rule 2's vocabulary: the
/// `@SectionId` of the SOM *field* the extract routed the value from, or the
/// field's own name where it carries none — which for a narrative field is the
/// pseudo-id `content`.
///
/// The union rather than either one alone. `codespecs_derivation_contract.md`
/// §2.5 rule 4 makes the two sets equal per declaration and check 7 enforces
/// it, so where they differ the fault is already reported — taking the union
/// means checks 35 and 36 fire only on a token cited by *neither*, which is
/// unambiguously a transfer defect and not a second message for check 7's.
Set<String> csCitedSectionIdsOf(CsDeclaration declaration) => {
      ...?declaration.codeSpec?.source,
      ...?declaration.docSpec?.map((r) => r.sectionId),
    };

/// Every extract token the trio traces to.
Set<String> csCitedSectionIds(CodeSpecsValidationInput input) => {
      for (final declaration in input.declarations)
        ...csCitedSectionIdsOf(declaration),
    };

/// `codespecs_derivation_contract.md` §6 check 35.
///
/// `codespecs_mapping.md` §9.6 comparison 1, at the granularity it names: the
/// set of routed extract tokens, set-differenced against what the trio's
/// back-links cite. A token on the left and not on the right is a
/// specification fact that reached no code, and it is invisible from the trio
/// alone — the output is the answer, and this comparison needs the question.
///
/// **Why the extract is what makes it decidable.** Nothing in a generated file
/// states what was supposed to be in it, so a complete transfer and a partial
/// one read identically. The extract is the other side: it enumerates, bounded
/// and verbatim, exactly what the authoring step was given, so "did everything
/// arrive" becomes a set difference over two artifacts instead of a search
/// through a document set.
///
/// **Whole tree or none.** The extract tree and the trio are two artifacts of
/// one run, so the check compares them as such. A partial `--extracts`
/// directory understates the left-hand set and the check passes on a gap it
/// simply could not see; that is the same "a skipped check must not read as a
/// passed one" reason the CLI announces an absent input, applied to a
/// half-present one.
class CsExtractCoverageCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsExtractCoverageCheck();

  @override
  int get number => 35;

  @override
  String get definedIn => '§9.6 of codespecs_mapping.md';

  @override
  String get title =>
      'Every token the extracts hold a value for is cited by a back-link in '
      'the trio — an uncited token is a specification fact that reached no '
      'code';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    if (input.extracts.isEmpty) return const [];
    final cited = csCitedSectionIds(input);
    final out = <CodeSpecsViolation>[];
    for (final extract in input.extracts.extracts) {
      // One violation per uncited token of an area, not per value: the gap is
      // that the *token* reached no code, and a token with nine values behind
      // it would otherwise be reported nine times over one fault.
      final reported = <String>{};
      for (final entry in extract.entries) {
        if (cited.contains(entry.sectionId)) continue;
        if (!reported.add(entry.sectionId)) continue;
        final values =
            extract.entries.where((e) => e.sectionId == entry.sectionId);
        final origins = values.map((e) => e.origin).toSet().join(', ');
        final at = entry.path.isEmpty ? '' : ' at ${entry.path}';
        out.add(
          fail(
            '${extract.source} routes ${values.length} value(s) of '
            '${entry.sectionId} to ${extract.areaCode}$at ($origins), and no '
            '@CodeSpec or @DocSpec in the trio names that token — the '
            'specification fact reached no code, so Phase 5 and Phase 6 would '
            'have to reopen the document to find it',
          ),
        );
      }
    }
    return out;
  }
}

/// `codespecs_derivation_contract.md` §6 check 36.
///
/// The converse of check 35, and a different defect rather than the same one
/// read backwards. A `DocRef` naming a token no extract holds is a back-link
/// with nothing behind it: either the token is stale — the model renamed the
/// field and the trio still points at the old one — or the agent invented it to
/// satisfy `codespecs_derivation_contract.md` §2.5's requirement that every
/// declaration carry one. Both make the `codespecs_mapping.md` §9.6 trace lie,
/// and both are silent otherwise: a token is a string, and no reading of the
/// trio can tell a real token from a plausible one.
///
/// Check 32 deliberately *skips* a token the extracts do not know, on the
/// grounds that it cannot judge a comment against text it does not have. This
/// check is where that skip is accounted for, so an unknown token is reported
/// exactly once and by the check whose rule it breaks.
class CsBackLinkExtractedCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsBackLinkExtractedCheck();

  @override
  int get number => 36;

  @override
  String get definedIn => '§9.6 of codespecs_mapping.md';

  @override
  String get title =>
      'Every token a back-link names exists in the extracts — a trace to a '
      'token no area routed is stale or invented';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    if (input.extracts.isEmpty) return const [];
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      for (final sectionId in csCitedSectionIdsOf(declaration)) {
        if (input.extracts.knowsSection(sectionId)) continue;
        out.add(
          fail(
            '${declaration.path} traces to $sectionId, which no extract holds '
            '— a back-link to a token no area routed is either a stale id or '
            'one written to satisfy §2.5, and neither states where the code '
            'came from',
            declaration.location,
          ),
        );
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 37 — a member reflection writes is never final
// ---------------------------------------------------------------------------

/// The two names `codespecs_derivation_contract.md` §3.2.1 point 4 gives a
/// CE-API DTO: the PascalCase operation name plus one of these.
///
/// The suffix is the whole of the recogniser because there is no `@CsDto`
/// marker — a DTO is a plain class, and `codespecs_derivation_contract.md`
/// §3.2.1 point 4 makes the suffix normative rather than conventional. Its
/// point 5 puts DTOs in the shared locus, which is what keeps the recogniser
/// from claiming a client view-model that happens to end in `Request`.
const _csDtoSuffixes = ['Request', 'Response'];

/// `codespecs_derivation_contract.md` §6 check 37.
///
/// The rule `codespecs_derivation_contract.md` §2.4 states — where reflection
/// writes a member it is `late` and **never `late final`** — is about a write
/// path that does not exist at the call site the author is looking at. A `@CsColumn` field is assigned by
/// `TomColumnInformation.setVariableValue`, a DTO field by the JSON decoder;
/// both go through `invokeSetter`, and a `final` field has no setter to invoke.
/// The declaration still compiles, still analyses clean, and still passes any
/// test that constructs the object by hand — the shape only fails when
/// something reflective tries to fill it, which is the first real read from the
/// database or the first request off the wire.
///
/// The three carve-outs `codespecs_derivation_contract.md` §2.4 states are
/// members nothing reflective writes, so the rule has nothing to say about
/// them and `late final` is the better spelling: a `static` catalogue,
/// configuration or secret holder (`codespecs_derivation_contract.md` §3.1.2,
/// §3.1.3, §3.3.6 and §3.6.1), the `collaborator` seam of
/// `codespecs_derivation_contract.md` §3.0.1, which Phase 6 binds by hand, and
/// a holder the declaration populates in one of its own method bodies — a
/// CE-CC `TomSetting` assigned in `declareSettings()`, a CE-FM field member
/// assigned where the form declares its fields.
class CsReflectionWrittenNotFinalCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsReflectionWrittenNotFinalCheck();

  @override
  int get number => 37;

  @override
  String get definedIn => '§2.4';

  @override
  String get title =>
      'A member reflection writes — a @CsColumn attribute, a CE-API DTO field '
      '— is late and never final, because reflection assigns through a setter '
      'a final field does not have';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final project in input.projects) {
      // Both maps are per project: an owner name is only unique within one, and
      // no declaration spans two.
      final owners = <String, CsDeclaration>{};
      final members = <String, List<CsDeclaration>>{};
      for (final declaration in project.declarations) {
        final owner = declaration.owner;
        if (owner == null) {
          owners[declaration.name] = declaration;
        } else {
          members.putIfAbsent(owner, () => []).add(declaration);
        }
      }

      for (final entry in members.entries) {
        final owner = owners[entry.key];
        final ownerIsDto = owner != null &&
            owner.kind == CsDeclarationKind.classType &&
            project.locus == CsLocus.shared &&
            _csDtoSuffixes.any((s) => owner.name.endsWith(s));

        for (final member in entry.value) {
          if (member.kind != CsDeclarationKind.field) continue;
          if (!member.isFinal) continue;

          final written = member.has('CsColumn')
              ? 'a @CsColumn attribute, which the repository assigns through '
                  'TomColumnInformation.setVariableValue'
              : ownerIsDto
                  ? 'a field of the CE-API DTO ${entry.key}, which the wire '
                      'decoder assigns'
                  : null;
          if (written == null) continue;

          // The §2.4 carve-outs, in the order the section states them.
          if (member.isStatic) continue;
          if (member.name == csCollaboratorField) continue;
          if (_assignedByOwner(owner, member.name)) continue;

          final spelling = member.isLate ? '`late final`' : '`final`';
          out.add(
            fail(
              '${member.path} is declared $spelling, and it is $written — §2.4 '
              'writes such a member `late` and never `late final`, because '
              'reflection assigns it through a setter a final field does not '
              'have, so the shape fails at the first reflective write rather '
              'than at generation',
              member.location,
            ),
          );
        }
      }
    }
    return out;
  }

  /// Whether [owner] assigns [name] in one of its own method bodies — the
  /// self-assignment carve-out of `codespecs_derivation_contract.md` §2.4.
  ///
  /// Read off the statement source rather than a resolved element, like the
  /// rest of this pass. The pattern requires an `=` that is not `==`, `>=`,
  /// `<=` or `!=`, so a comparison against the member does not read as a write
  /// to it.
  bool _assignedByOwner(CsDeclaration? owner, String name) {
    if (owner == null) return false;
    final assignment = RegExp(
      '(^|[^A-Za-z0-9_.])(this\\.)?${RegExp.escape(name)}\\s*=[^=]',
    );
    for (final body in owner.bodies) {
      for (final statement in body.allStatements) {
        if (assignment.hasMatch('${statement.source} ')) return true;
      }
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// The catalogue
// ---------------------------------------------------------------------------

/// The thirty-seven checks, in `codespecs_derivation_contract.md` §6 table
/// order.
const codeSpecsChecks = <CodeSpecsCheck>[
  CsIdentifierCollisionCheck(),
  CsReferenceResolutionCheck(),
  CsMissingNameCheck(),
  CsMissingAuthoredKeyCheck(),
  CsEmptyExplicationCheck(),
  CsFabricatedValueCheck(),
  CsBackLinkAgreementCheck(),
  CsSlotExclusivityCheck(),
  CsMirroredCatalogueCheck(),
  CsErrorCopyCategoryCheck(),
  CsLocusArrowCheck(),
  CsOperationAgreementCheck(),
  CsMigrationConvergenceCheck(),
  CsComposeTokenCheck(),
  CsOverridableScopeCheck(),
  CsSecretInitialiserCheck(),
  CsFallbackChannelCheck(),
  CsDrillThroughRouteCheck(),
  CsSecretIsDeclaredCheck(),
  CsSettingKeyCollisionCheck(),
  CsGradedDepthCheck(),
  CsColumnNotObservableCheck(),
  CsCollaboratorCallResolutionCheck(),
  CsCollaboratorShapeCheck(),
  CsMethodCommentCheck(),
  CsNoInBodyCommentCheck(),
  CsDocCommentShapeCheck(),
  CsBodyStatementShapeCheck(),
  CsBranchConditionCheck(),
  CsCollaboratorSignatureCheck(),
  CsDeterminismCheck(),
  CsCommentSourceCheck(),
  CsGroupedHolderCommentCheck(),
  CsCommentFidelityCheck(),
  CsExtractCoverageCheck(),
  CsBackLinkExtractedCheck(),
  CsReflectionWrittenNotFinalCheck(),
];
