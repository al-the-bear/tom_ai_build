/// The twenty validator checks `codespecs_derivation_contract.md` §6 names.
///
/// One [CodeSpecsCheck] per numbered row, each carrying the §-reference of the
/// rule that defines it so a failure cites the rule rather than a symptom. The
/// checks read the [CodeSpecsValidationInput] the reader builds; none of them
/// re-derives what the contract says — the contract states the rules, these
/// state nothing.
library;

import 'cs_model.dart';

/// One failed check.
///
/// Every violation carries the §6 check number and the section that defines the
/// rule, so the message identifies which rule was broken.
class CodeSpecsViolation {
  /// The §6 check number.
  final int check;

  /// The section of `codespecs_derivation_contract.md` that defines the rule.
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

/// One §6 check.
abstract class CodeSpecsCheck {
  /// Creates a check.
  const CodeSpecsCheck();

  /// The §6 row number.
  int get number;

  /// The section that defines the rule.
  String get definedIn;

  /// The rule, in one line — the §6 row text.
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
/// §5.3 lists fourteen mirror rows, but most mirror a *document* section rather
/// than a declared type: only these pairs have a `tom_core` counterpart that can
/// be compared value-for-value, so only these are checkable at all.
const csMirroredEnumPairs = <String, String>{
  'CsErrorSeverity': 'TomErrorSeverity',
};

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

/// §6 check 1.
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

/// §6 check 2.
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

/// §6 check 3.
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

/// §6 check 4.
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

// ---------------------------------------------------------------------------
// 5 — empty explication
// ---------------------------------------------------------------------------

/// §6 check 5.
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
    for (final declaration in input.declarations) {
      for (final body in declaration.bodies) {
        if (body.shape != CsBodyShape.throwOnly) continue;
        final message = body.thrownMessage;
        if (message == null || message.trim().isNotEmpty) continue;
        out.add(
          fail(
            '${declaration.path}.${body.name} throws with no explication — the '
            'SOM description that is the stub body is empty (section(s) '
            '${sectionsOf(declaration)})',
            body.location,
          ),
        );
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 6 — fabricated values
// ---------------------------------------------------------------------------

/// §6 check 6.
class CsFabricatedValueCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsFabricatedValueCheck();

  @override
  int get number => 6;

  @override
  String get definedIn => '§2.4';

  @override
  String get title => 'No generated stub returns a fabricated value';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      for (final body in declaration.bodies) {
        if (body.shape != CsBodyShape.returnsValue) continue;
        out.add(
          fail(
            '${declaration.path}.${body.name} returns a value — a stub has one '
            'exit and it is the throw, so any returned value is fabricated',
            body.location,
          ),
        );
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// 7 — back-link set equality
// ---------------------------------------------------------------------------

/// §6 check 7.
class CsBackLinkAgreementCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsBackLinkAgreementCheck();

  @override
  int get number => 7;

  @override
  String get definedIn => '§2.5 rule 4';

  @override
  String get title => '@CodeSpec.source equals the @DocSpec section-id set';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final codeSpec = declaration.codeSpec;
      final docSpec = declaration.docSpec;
      // Rule 5: a member that adds no section of its own carries neither.
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
      if (_sameSet(fromCodeSpec, fromDocSpec)) continue;
      out.add(
        fail(
          '${declaration.path}: @CodeSpec.source {${fromCodeSpec.join(', ')}} '
          'differs from the @DocSpec section ids {${fromDocSpec.join(', ')}}',
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

/// §6 check 8.
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

/// §6 check 9.
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

/// §6 check 10.
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

/// §6 check 11.
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

/// §6 check 12.
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

/// §6 check 13.
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

/// §6 check 14.
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

/// §6 check 15.
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

/// §6 check 16.
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

/// §6 check 17.
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

/// §6 check 18.
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

/// §6 check 19.
///
/// CE-CF has two authoring shapes (`codespecs_mapping.md` §5.16): the
/// *declared* shape, where the application owns the setting key and authors
/// every property of it, and the *fixed* shape, where the model owns the key
/// and the author supplies the value only. `secret: true` is authorable on the
/// declared shape alone, so a secret member's `@DocSpec` back-link must name
/// [_declaredShapeSection]. One traced to a fixed band means a credential slot
/// was invented in a policy section.
class CsSecretIsDeclaredCheck extends CodeSpecsCheck {
  /// Creates the check.
  const CsSecretIsDeclaredCheck();

  /// The SOM section id of CE-CF's declared shape.
  static const _declaredShapeSection = 'SCSET';

  @override
  int get number => 19;

  @override
  String get definedIn => '§3.3.6';

  @override
  String get title =>
      'A @CsServerConfig(secret: true) member is traced to $_declaredShapeSection';

  @override
  List<CodeSpecsViolation> run(CodeSpecsValidationInput input) {
    final out = <CodeSpecsViolation>[];
    for (final declaration in input.declarations) {
      final marker = declaration.marker('CsServerConfig');
      if (marker == null) continue;
      final secret = marker.named['secret'];
      if (secret is! CsBoolValue || !secret.value) continue;
      final docSpec = declaration.docSpec;
      if (docSpec == null) {
        out.add(
          fail(
            '${declaration.path} is a secret setting with no @DocSpec '
            'back-link — a secret is only ever authored as a '
            '$_declaredShapeSection entry, and the back-link is what says so',
            declaration.location,
          ),
        );
        continue;
      }
      final sections = docSpec.map((r) => r.sectionId).toSet();
      if (sections.contains(_declaredShapeSection)) continue;
      out.add(
        fail(
          '${declaration.path} is a secret setting traced to '
          '{${sections.join(', ')}} rather than $_declaredShapeSection — the '
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

/// §6 check 20.
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

/// §6 check 21.
///
/// The SOM bounds the graded depth **structurally**: a graded level is a
/// `GradedAccessLevelEntry`, whose kind enum has no `graded` constant, so a
/// second grading nested inside a level is unauthorable. `tom_specs_model_rules`
/// §5.7 leaves no alternative — a self-recursive requirement class is a
/// structural cycle and a hard error.
///
/// The code side has no such type barrier: `CsGradedAccess`'s three slots are
/// each a `@CsAuthorize`, and `@CsAuthorize` *does* have a `graded` arm. So the
/// nesting is expressible in hand-written CodeSpecs even though no generator run
/// can produce it, and without this check the two sides diverge exactly where
/// the SOM was made deliberately strict — surfacing as a runtime access decision
/// rather than a generation error.
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
  /// behind the one above it — the whole point of the check is that this nesting
  /// has no depth limit in Dart.
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
// The catalogue
// ---------------------------------------------------------------------------

/// The twenty-one checks, in §6 table order.
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
];
