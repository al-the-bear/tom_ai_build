/// The shared CE-AZ authorization requirement
/// (`codespecs_mapping.md` §5.15).
///
/// **One shape, embedded everywhere.** CE-AZ is a *modifier*, not a standalone
/// part (`codespecs_mapping.md` §4.1), so the requirement is authored once as a
/// reusable section type that every guarded site embeds — a screen, a
/// navigation group, a server operation, a report, an export. Before this, each
/// of those sites carried its own free-text `accessLevel` / `requiredRoles`
/// pair, and no two agreed on the vocabulary.
///
/// **This is not a second authoring home for roles or entitlements.** The role
/// catalogue (`AZRO`), the role/permission matrix (`ROLPER`) and the
/// entitlement catalogue (`ENT`) define what a role or entitlement *means*; the
/// sections here only *name* one as a requirement, by reference. Adding a role
/// is still an edit to the catalogue.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// The ten CE-AZ requirement kinds (`codespecs_mapping.md` §5.15).
///
/// Six kinds carry a payload — [role], [group], [entitlement], [resourceKey],
/// [custom], [graded] — and bind a case subsection on
/// [AuthorizationRequirementSpec]. The four presets ([denied], [public],
/// [authenticated], [guest]) carry none: the kind *is* the whole requirement,
/// so they bind no case.
///
/// **No arm is a default.** Choosing an access rule by omission is the failure
/// `codespecs_mapping.md` §5.16's fail-safe rule exists to prevent, so the
/// discriminator field is `required`.
///
/// Mirrors `CsAuthRequirement` (`tom_code_specs`) arm-for-arm, with one
/// deliberate rename: the deny preset is [denied] here where the code side
/// calls it `none`. On the code side `none` sits among typed slots and cannot
/// be misread; in an authored document "None" reads as *no authorization
/// needed* — the exact fail-open misreading §5.16 guards against.
enum AuthorizationRequirementKind {
  /// The caller must hold one of a named set of roles.
  role,

  /// The caller must belong to one of a named set of groups.
  group,

  /// The caller's entitlements must match one of a set of patterns.
  entitlement,

  /// The caller must hold a grant on a named resource key.
  resourceKey,

  /// A registered handler decides, against a named resource id.
  custom,

  /// A graded requirement resolving to one of the four access states.
  graded,

  /// Deny unconditionally.
  denied,

  /// Allow unconditionally, signed in or not.
  public,

  /// Allow any signed-in caller.
  authenticated,

  /// Allow the guest caller.
  guest,
}

/// The four access states a graded requirement resolves to
/// (`codespecs_mapping.md` §5.15).
///
/// Only three are authorable: a caller who meets none of the levels gets no
/// access, so "no access" is the absence of a match rather than a level someone
/// writes down.
///
/// **What each state renders as is framework-fixed** — no access hides the
/// thing, [disabled] shows it locked, [read] shows its value, [full] makes it
/// interactive. That mapping is not a spec attribute and is deliberately absent
/// from [GradedAccessLevelEntry].
enum GradedAccessLevel {
  /// Full, interactive access.
  full,

  /// The value is shown but cannot be changed.
  read,

  /// The thing is visible but locked.
  disabled,
}

/// The nine requirement kinds a *graded* access level may resolve to.
///
/// [AuthorizationRequirementKind] minus `graded` — the bound that keeps the
/// graded arm from recursing (see [GradedAuthorizationRequirement]).
enum BasicAuthorizationRequirementKind {
  /// The caller must hold one of a named set of roles.
  role,

  /// The caller must belong to one of a named set of groups.
  group,

  /// The caller's entitlements must match one of a set of patterns.
  entitlement,

  /// The caller must hold a grant on a named resource key.
  resourceKey,

  /// A registered handler decides, against a named resource id.
  custom,

  /// Deny unconditionally.
  denied,

  /// Allow unconditionally, signed in or not.
  public,

  /// Allow any signed-in caller.
  authenticated,

  /// Allow the guest caller.
  guest,
}

/// What a caller must satisfy to reach the thing this section modifies
/// (`codespecs_mapping.md` §5.15).
///
/// Embed this section wherever a guarded thing is authored — do not restate its
/// fields inline. The kind selects at most one payload subsection; the four
/// presets select none, which is why four of the ten arms bind no case.
@SectionId('AZREQ')
@StandardReferences(
  [
    'ISO/IEC 25010:2023 — security: confidentiality and integrity through access control',
    'NIST SP 800-162 — attribute-based access control (ABAC)',
    'NIST RBAC (INCITS 359) — role-based access control',
  ],
  'The single authorization requirement a caller must satisfy, expressed as one of ten closed kinds with the payload that kind needs.',
)
@OneOf(
  discriminator: 'requirementKind',
  noCase: [
    AuthorizationRequirementKind.denied,
    AuthorizationRequirementKind.public,
    AuthorizationRequirementKind.authenticated,
    AuthorizationRequirementKind.guest,
  ],
  note:
      'Authorization requirement closed choice: the kind selects its payload '
      'subsection — a role list, a group list, entitlement patterns, a resource '
      'key, a custom handler, or a graded level set. The four presets (Denied, '
      'Public, Authenticated, Guest) bind no case because the kind is the whole '
      'requirement; a document authoring one of them carries no subsection here.',
)
@CodeSpecKind(
  [CodeSpecPart.authorization],
  note:
      'Lowers onto a `@CsAuthorize` whose `requirement` is this kind and whose '
      'per-kind slot is filled from the selected case subsection '
      '(`codespecs_derivation_contract.md` §3.4.3).',
)
class AuthorizationRequirementSpec extends DocSpecsSection {
  @ContentHelp('''
What a caller must satisfy to reach the guarded thing.

**State it explicitly.** There is no default requirement. A guarded thing with
no requirement authored is a specification defect, not an open door.

**Pick the narrowest kind that says what you mean.** *Role* and *Resource Key*
name entries in the security catalogues and are checked against them. *Group*
and *Entitlement* match runtime principal data, so they are free-text and cannot
be checked at specification time — prefer a catalogued kind where one fits.

**Graded** is for a thing that is not simply reachable or unreachable but has
degrees — hidden, visible-but-locked, readable, fully interactive. Use it only
when the degrees genuinely differ; a thing that is either reachable or not is
one of the other nine kinds.

**Do not author what the framework fixes.** How an unmet requirement renders —
hidden, disabled, read-only — follows from the access state and is fixed by the
framework. It is not something to restate per site.
''')
  @Form([
    Field(
      'requirementKind',
      AuthorizationRequirementKind,
      'Requirement Kind',
      required: true,
      hint: 'What the caller must satisfy — selects the payload subsection '
          'below. Denied | Public | Authenticated | Guest carry no payload.',
    ),
    Field(
      'rationale',
      String,
      'Rationale',
      hint: 'Why this requirement and not a wider or narrower one',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Role requirement payload — a promoted `@OneOf` case.
  @SectionId('AZREQ-ROLE')
  @Case(AuthorizationRequirementKind.role)
  @Form([
    Field(
      'roles',
      String,
      'Roles',
      required: true,
      refersTo: ['AZRO.roleName'],
      hint: 'Comma-separated role names from the role catalogue; the caller '
          'must hold at least one',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? roleRequirement;

  /// Group requirement payload — a promoted `@OneOf` case.
  @SectionId('AZREQ-GRUP')
  @Case(AuthorizationRequirementKind.group)
  @Form([
    Field(
      'groups',
      String,
      'Groups',
      required: true,
      hint: 'Comma-separated group names the caller must belong to (at least '
          'one). Groups are runtime principal data, so these are not checked '
          'against a catalogue.',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? groupRequirement;

  /// Entitlement requirement payload — a promoted `@OneOf` case.
  @SectionId('AZREQ-ENTL')
  @Case(AuthorizationRequirementKind.entitlement)
  @Form([
    Field(
      'patterns',
      String,
      'Entitlement Patterns',
      required: true,
      hint: 'Comma-separated entitlement match patterns; the caller must match '
          'at least one',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? entitlementRequirement;

  /// Resource-key requirement payload — a promoted `@OneOf` case.
  @SectionId('AZREQ-RKEY')
  @Case(AuthorizationRequirementKind.resourceKey)
  @Form([
    Field(
      'resourceKey',
      String,
      'Resource Key',
      required: true,
      refersTo: ['RESKEY.resourceKey'],
      hint: 'The resource key from the resource-key catalogue the caller must '
          'hold a grant on',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? resourceKeyRequirement;

  /// Custom requirement payload — a promoted `@OneOf` case.
  @SectionId('AZREQ-CUST')
  @Case(AuthorizationRequirementKind.custom)
  @Form([
    Field(
      'handler',
      String,
      'Handler',
      required: true,
      hint: 'The registered access handler that decides',
    ),
    Field(
      'resourceId',
      String,
      'Resource ID',
      hint: 'The resource id passed to the handler, where it needs one',
    ),
    Field(
      'decisionRule',
      String,
      'Decision Rule',
      required: true,
      hint: 'What the handler must decide, in business terms — this is the '
          'specification the handler is implemented against',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? customRequirement;

  /// Graded requirement payload — a promoted `@OneOf` case.
  @Case(AuthorizationRequirementKind.graded)
  @SerializationOrder(6)
  GradedAuthorizationRequirement? gradedRequirement;
}

/// A graded requirement: what a caller must satisfy for each access state
/// (`codespecs_mapping.md` §5.15).
///
/// **Why a level takes a [GradedAccessLevelEntry] and not an
/// [AuthorizationRequirementSpec].** A graded level whose requirement could
/// itself be graded would make the model structurally cyclic, and
/// `tom_specs_model_rules.md` §5.7 makes a structural cycle a hard error — the
/// outliner, the serializers and the nine generated language runtimes all walk
/// the class graph as a tree. Bounding the depth at one level is not a
/// workaround for that constraint: a graded thing resolves to one of four
/// *terminal* access states, so nesting a second grading inside a level has
/// nothing left to resolve to.
///
/// The price is that [GradedAccessLevelEntry] restates five of
/// [AuthorizationRequirementSpec]'s case forms. That duplication is deliberate —
/// the SOM composes by field, not by subtyping (`codespecs_mapping.md` §8.2) —
/// and removing it by pointing the levels back at [AuthorizationRequirementSpec]
/// reintroduces the cycle.
@SectionId('AZGRD')
@StandardReferences(
  ['NIST SP 800-162 — attribute-based access control (ABAC)'],
  'The per-level requirements of a graded access rule: what earns full access, what earns read access, and what earns a visible-but-locked view.',
)
class GradedAuthorizationRequirement extends DocSpecsSection {
  @ContentHelp('''
The requirement for each access state, from the most permissive down.

**Author only what differs.** The levels default downwards: a caller who meets
*Full* also has *Read*, and a caller who meets *Read* also has *Disabled*. Omit
a level to inherit the one above it. A caller meeting none of them gets no
access and the thing is not shown, which is why there is no "none" level to
author.

**Author each state at most once.** The three states are a ladder, not a set of
independent rules.

**What the states mean is fixed by the framework** — no access hides the thing,
disabled shows it locked, read shows its value, full makes it interactive. Do
not restate that here; author only *who* reaches each state.
''')
  @Form([
    Field(
      'gradingRationale',
      String,
      'Grading Rationale',
      hint: 'Why this thing is graded rather than simply reachable or not',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// The authored rungs of the ladder — contains 1..3× Graded Access Level.
  @SectionId('AZLVL-LEVE-LST')
  @SectionIdPattern('AZLVL-LEVE-xxx')
  @Min(1)
  @ContentHelp(
    'Add one entry per access state that has its own requirement. At least '
    'Full must be authored; Read and Disabled inherit downwards when omitted.',
  )
  @SerializationOrder(1)
  List<GradedAccessLevelEntry> accessLevels = [];
}

/// One rung of a graded access ladder: an access state and the non-graded
/// requirement that earns it (`codespecs_mapping.md` §5.15).
///
/// The requirement half is [AuthorizationRequirementSpec] minus the graded arm.
/// See [GradedAuthorizationRequirement] for why that bound exists and why the
/// case forms are restated rather than shared.
@SectionId('AZLVL')
@StandardReferences(
  [
    'NIST SP 800-162 — attribute-based access control (ABAC)',
    'NIST RBAC (INCITS 359) — role-based access control',
  ],
  'One rung of a graded access ladder: the access state and the non-graded authorization requirement that earns it.',
)
@OneOf(
  discriminator: 'requirementKind',
  noCase: [
    BasicAuthorizationRequirementKind.denied,
    BasicAuthorizationRequirementKind.public,
    BasicAuthorizationRequirementKind.authenticated,
    BasicAuthorizationRequirementKind.guest,
  ],
  note:
      'Non-graded authorization requirement closed choice: the same mechanism '
      'as AZREQ with the graded arm removed, which is what bounds the graded '
      'recursion. The four presets bind no case.',
)
@CodeSpecKind(
  [CodeSpecPart.authorization],
  note:
      'Lowers onto the `@CsAuthorize` held in the `CsGradedAccess` slot named '
      'by `accessLevel`; its `requirement` is never `graded` '
      '(`codespecs_derivation_contract.md` §6 check 21).',
)
class GradedAccessLevelEntry extends DocSpecsSection {
  @ContentHelp('''
One access state and what earns it.

The requirement kinds are the same as for an ungraded requirement, minus
*Graded* — an access state is already the outcome of a grading, so it cannot
itself be graded.
''')
  @Form([
    Field(
      'accessLevel',
      GradedAccessLevel,
      'Access Level',
      required: true,
      hint: 'The state this requirement earns. Full | Read | Disabled — each '
          'authored at most once per graded requirement.',
    ),
    Field(
      'requirementKind',
      BasicAuthorizationRequirementKind,
      'Requirement Kind',
      required: true,
      hint: 'What the caller must satisfy to reach this access state — selects '
          'the payload subsection below',
    ),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  /// Role requirement payload — a promoted `@OneOf` case.
  @SectionId('AZLVL-ROLE')
  @Case(BasicAuthorizationRequirementKind.role)
  @Form([
    Field(
      'roles',
      String,
      'Roles',
      required: true,
      refersTo: ['AZRO.roleName'],
      hint: 'Comma-separated role names from the role catalogue; the caller '
          'must hold at least one',
    ),
  ])
  @SerializationOrder(1)
  DocSpecsSection? roleRequirement;

  /// Group requirement payload — a promoted `@OneOf` case.
  @SectionId('AZLVL-GRUP')
  @Case(BasicAuthorizationRequirementKind.group)
  @Form([
    Field(
      'groups',
      String,
      'Groups',
      required: true,
      hint: 'Comma-separated group names the caller must belong to (at least '
          'one)',
    ),
  ])
  @SerializationOrder(2)
  DocSpecsSection? groupRequirement;

  /// Entitlement requirement payload — a promoted `@OneOf` case.
  @SectionId('AZLVL-ENTL')
  @Case(BasicAuthorizationRequirementKind.entitlement)
  @Form([
    Field(
      'patterns',
      String,
      'Entitlement Patterns',
      required: true,
      hint: 'Comma-separated entitlement match patterns; the caller must match '
          'at least one',
    ),
  ])
  @SerializationOrder(3)
  DocSpecsSection? entitlementRequirement;

  /// Resource-key requirement payload — a promoted `@OneOf` case.
  @SectionId('AZLVL-RKEY')
  @Case(BasicAuthorizationRequirementKind.resourceKey)
  @Form([
    Field(
      'resourceKey',
      String,
      'Resource Key',
      required: true,
      refersTo: ['RESKEY.resourceKey'],
      hint: 'The resource key from the resource-key catalogue the caller must '
          'hold a grant on',
    ),
  ])
  @SerializationOrder(4)
  DocSpecsSection? resourceKeyRequirement;

  /// Custom requirement payload — a promoted `@OneOf` case.
  @SectionId('AZLVL-CUST')
  @Case(BasicAuthorizationRequirementKind.custom)
  @Form([
    Field(
      'handler',
      String,
      'Handler',
      required: true,
      hint: 'The registered access handler that decides',
    ),
    Field(
      'resourceId',
      String,
      'Resource ID',
      hint: 'The resource id passed to the handler, where it needs one',
    ),
    Field(
      'decisionRule',
      String,
      'Decision Rule',
      required: true,
      hint: 'What the handler must decide, in business terms',
    ),
  ])
  @SerializationOrder(5)
  DocSpecsSection? customRequirement;
}
