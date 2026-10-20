/// The registries a TomSpecs specification declares, read for test derivation
/// (`tom_specs_project_flow.md`, Phase 5).
///
/// Every Tom application declares the same registries, so the part of its
/// test suite that is pure registry data is derived mechanically: the
/// operations with their authorization requirements, error codes and
/// operational controls (SVOPE, AZREQ, SVOCT), the roles with the
/// entitlements they hold (AZRO, ENREFE), the error codes (ERCEN), and the
/// screens with the operations they call (SCREN, SCETR).
///
/// The registries are read from the specification document through the SOM
/// runtime rather than from the Phase-4 CodeSpecs trio: the specification is
/// where they are structured, and every trio is derived from it.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

/// The authorization requirement of an operation (AZREQ).
class RegistryRequirement {
  /// The requirement kind (`role`, `entitlement`, `custom`, `public`, …);
  /// empty when the operation states none.
  final String kind;

  /// The roles a `role` requirement names.
  final List<String> roles;

  /// The entitlement patterns an `entitlement` requirement names (`*` matches
  /// any run of characters).
  final List<String> patterns;

  /// The handler a `custom` requirement names.
  final String handler;

  /// Creates a requirement.
  const RegistryRequirement({
    this.kind = '',
    this.roles = const [],
    this.patterns = const [],
    this.handler = '',
  });
}

/// One operation of the server-operation registry (SVOPE).
class RegistryOperation {
  /// The operation name.
  final String name;

  /// The error codes the operation may return.
  final List<String> errorCodes;

  /// Who may call it.
  final RegistryRequirement requirement;

  /// The idempotency the controls state (empty when unstated).
  final String idempotency;

  /// The audit event the controls state (empty when unstated).
  final String auditEvent;

  /// The rate-limit class the controls state (empty when unstated).
  final String rateLimitClass;

  /// Creates an operation.
  const RegistryOperation({
    required this.name,
    this.errorCodes = const [],
    this.requirement = const RegistryRequirement(),
    this.idempotency = '',
    this.auditEvent = '',
    this.rateLimitClass = '',
  });

  /// Whether a person calls the operation: its requirement is satisfied by a
  /// signed-in principal's roles or entitlements rather than by a service
  /// credential or nobody.
  bool get personCalled => const {
    'role',
    'group',
    'entitlement',
    'authenticated',
    'graded',
  }.contains(requirement.kind);
}

/// One role of the role catalogue (AZRO).
class RegistryRole {
  /// The role name.
  final String name;

  /// The entitlements the role holds (ENREFE).
  final List<String> entitlements;

  /// Creates a role.
  const RegistryRole({required this.name, this.entitlements = const []});
}

/// One screen of the screen inventory (SCREN).
class RegistryScreen {
  /// The screen's section id.
  final String id;

  /// The operations the screen calls (SCETR.serverOperations).
  final List<String> operations;

  /// Creates a screen.
  const RegistryScreen({required this.id, this.operations = const []});
}

/// The registries of one specification.
class RegistrySet {
  /// The operations, in document order.
  final List<RegistryOperation> operations;

  /// The roles, in document order.
  final List<RegistryRole> roles;

  /// The declared error codes.
  final List<String> errorCodes;

  /// The screens, in document order.
  final List<RegistryScreen> screens;

  /// Creates a registry set.
  const RegistrySet({
    this.operations = const [],
    this.roles = const [],
    this.errorCodes = const [],
    this.screens = const [],
  });

  /// The role named [name], or null.
  RegistryRole? role(String name) {
    for (final r in roles) {
      if (r.name == name) return r;
    }
    return null;
  }
}

/// Reads the registries of [doc] under [model].
RegistrySet readRegistries(SpecModel model, SpecDocument doc) {
  final refl = SpecReflection(model);

  // Every held form, indexed by the path of the section it sits on, with the
  // section id of that section's class and of the form itself.
  final formsByOwner =
      <
        String,
        List<({String ownerSid, String formSid, Map<String, String> values})>
      >{};
  for (final path in doc.formPaths) {
    final res = refl.resolve(path);
    final field = res?.field;
    if (res == null || res.kind != SpecNodeKind.form || field == null) continue;
    final slash = path.lastIndexOf('/');
    if (slash <= 0) continue;
    final parent = path.substring(0, slash);
    final ownerSid = refl.resolve(parent)?.targetClass?.sectionId ?? '';
    final values = <String, String>{
      for (final ff in field.formFields)
        if ((doc.formField(path, ff.name) ?? '').trim().isNotEmpty)
          ff.name: doc.formField(path, ff.name)!.trim(),
    };
    (formsByOwner[parent] ??= []).add((
      ownerSid: ownerSid,
      formSid: field.sectionId ?? field.name,
      values: values,
    ));
  }

  List<String> split(String? v) => [
    for (final s in (v ?? '').split(','))
      if (s.trim().isNotEmpty) s.trim(),
  ];

  // The forms of [item] and of every section beneath it.
  Iterable<
    ({
      String owner,
      String ownerSid,
      String formSid,
      Map<String, String> values,
    })
  >
  formsUnder(String item) sync* {
    for (final entry in formsByOwner.entries) {
      if (entry.key != item && !entry.key.startsWith('$item/')) continue;
      for (final f in entry.value) {
        yield (
          owner: entry.key,
          ownerSid: f.ownerSid,
          formSid: f.formSid,
          values: f.values,
        );
      }
    }
  }

  final operations = <RegistryOperation>[];
  final roles = <RegistryRole>[];
  final errorCodes = <String>[];
  final screens = <RegistryScreen>[];

  for (final listPath in doc.listPaths.toList()..sort()) {
    final listRes = refl.resolve(listPath);
    final items = doc.listItems(listPath);
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final sid = refl.resolve(item)?.targetClass?.sectionId;
      final own = [
        for (final f in formsUnder(item))
          if (f.owner == item) f,
      ];
      String ownValue(String formSid, String field) {
        for (final f in own) {
          if (f.formSid == formSid && f.values.containsKey(field)) {
            return f.values[field]!;
          }
        }
        return '';
      }

      switch (sid) {
        case 'SVOPE':
          final name = ownValue('content', 'operationName');
          if (name.isEmpty) continue;
          var kind = '';
          var reqRoles = <String>[];
          var patterns = <String>[];
          var handler = '';
          for (final f in formsUnder(item)) {
            if (f.ownerSid != 'AZREQ') continue;
            switch (f.formSid) {
              case 'content':
                kind = f.values['requirementKind'] ?? kind;
              case 'AZREQ-ROLE':
                reqRoles = split(f.values['roles']);
              case 'AZREQ-ENTL':
                patterns = split(f.values['patterns']);
              case 'AZREQ-CUST':
                handler = f.values['handler'] ?? '';
            }
          }
          operations.add(
            RegistryOperation(
              name: name,
              errorCodes: split(ownValue('content', 'errorCodes')),
              requirement: RegistryRequirement(
                kind: kind,
                roles: reqRoles,
                patterns: patterns,
                handler: handler,
              ),
              idempotency: ownValue('SVOCT', 'idempotency'),
              auditEvent: ownValue('SVOCT', 'auditEvent'),
              rateLimitClass: ownValue('SVOCT', 'rateLimitClass'),
            ),
          );
        case 'AZRO':
          final name = ownValue('content', 'roleName');
          if (name.isEmpty) continue;
          roles.add(
            RegistryRole(
              name: name,
              entitlements: [
                for (final f in formsUnder(item))
                  if (f.ownerSid == 'ENREFE' &&
                      (f.values['entitlementName'] ?? '').isNotEmpty)
                    f.values['entitlementName']!,
              ],
            ),
          );
        case 'ERCEN':
          final code = ownValue('content', 'code');
          if (code.isNotEmpty) errorCodes.add(code);
        case 'SCREN':
          screens.add(
            RegistryScreen(
              id: effectiveListItemSectionId(
                storedId: doc.itemSectionId(item),
                pattern: listRes?.field?.sectionIdPattern,
                position: i + 1,
                fallbackStem: listRes?.field?.name ?? listPath.split('/').last,
              ),
              operations: split(ownValue('SCETR', 'serverOperations')),
            ),
          );
      }
    }
  }
  return RegistrySet(
    operations: operations,
    roles: roles,
    errorCodes: errorCodes,
    screens: screens,
  );
}
