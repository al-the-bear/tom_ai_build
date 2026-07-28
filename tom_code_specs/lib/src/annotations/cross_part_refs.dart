/// Typed cross-part references — the `Cs*Ref` const family
/// (`codespecs_mapping.md` §5.23).
///
/// Every cross-part reference edge inside CodeSpecs code is a **Dart const
/// reference or `Type` literal — never a string literal**. The part that owns a
/// referenceable element declares its identity **exactly once** as a `static
/// const` on that part's generated catalogue class
/// (`codespecs_derivation_contract.md` §2.1 N7); every citing annotation holds
/// that const. A dangling or renamed reference is therefore a **compile error**
/// — the Dart compiler is the `codespecs_mapping.md` §4.2 cross-part integrity
/// checker.
///
/// ```dart
/// // declared once, on the owning part's catalogue class
/// static const login = CsOperationRef('login');
///
/// // cited elsewhere — the const, never a copy of its string
/// static const operation = Operations.login;
/// ```
///
/// **The string id still exists**, authored once *inside* the const. It is what
/// `codespecs_mapping.md` §9.2/§9.3 serialization and SOM `codeSpec` tracing
/// carry, and what the generated **lowered** runtime forms hold
/// (`ValidationError.errorKey`, `TomServerCallSpecs.url`,
/// `TomRoleAccess.roles`, the dotted `TomTextResourceProvider` keys).
/// Spec-level code never repeats it. Per rule N9 the string is the camelCase
/// declaration name of the target, except where the target is identified by an
/// **authored key** (N5 — message keys, error codes, operation names, route
/// ids), in which case it is that key verbatim.
///
/// **Distinct types, not one generic `CsRef`.** Passing a route ref where an
/// operation ref is expected must itself be a compile error, so cross-*kind*
/// misuse is type-checked rather than convention-checked. That is also why the
/// family has **no shared supertype**: a parameter typed as a common base would
/// accept every kind, which is precisely the generic ref `codespecs_mapping.md`
/// §5.23 rejects. The generation-time validator that resolves every ref string
/// to a declaration works over the source, not over runtime types, so it needs
/// none either.
///
/// **These are not annotations** — they are annotation *parameter* vocabulary,
/// the same role `DocRef` plays for `@DocSpec`. Dart annotation arguments must
/// be const expressions, which is what makes every type here a `const` class.
///
/// **Locus** follows the `codespecs_mapping.md` §4.2 dependency arrows.
/// Shared-owned referents ([CsOperationRef], [CsMessageKey], [CsErrorCode],
/// [CsRoleRef], [CsResourceKeyRef]) are citable from both sides; client-owned
/// referents ([CsCallRef], [CsActionRef], [CsRouteRef], [CsElementRef],
/// [CsFormRef]) only client-side; server-owned referents ([CsServiceUnitRef],
/// [CsReportRef], [CsJobRef]) only server-side.
///
/// **Entities and DTOs are absent by design.** They are already Dart types, so
/// they are cited by `Type` literal (`rootAggregate: Customer`) and need no ref
/// const. Four further reference kinds stay strings (`codespecs_mapping.md`
/// §5.23's normative exemptions), because their referent is not a Dart
/// declaration and integrity comes from the validator instead of the compiler:
/// setting keys and their env/cmdline aliases, deployment-environment names,
/// CE-MG migration artifact filenames, and doc-side `codeSpec` locations /
/// `@DocSpec` section ids.
library;

/// A reference to a **CE-API operation** (shared locus).
///
/// Cited by CE-SC call sites (`codespecs_mapping.md` §5.3/§5.14) and by the
/// CE-SU derived operation sets (`codespecs_mapping.md` §5.17). The operation
/// name is an authored key (N5), so [id] holds it character for character —
/// `'customer.save'`, not a re-derived name.
class CsOperationRef {
  /// The operation name, verbatim from the specification.
  final String id;

  const CsOperationRef(this.id);
}

/// A reference to a **CE-SC server call** (client locus).
///
/// Hop 1 of the two-hop CE-AC → CE-SC → CE-API chain (`codespecs_mapping.md`
/// §5.3): an action cites the call it issues, and the call cites the operation
/// it invokes. Holding each hop as a reference rather than by containment is
/// what keeps an action, its server call and the operation independently
/// authorable.
class CsCallRef {
  /// The camelCase declaration name of the `@CsServerCall` (N9).
  final String id;

  const CsCallRef(this.id);
}

/// A reference to a **CE-AC action** (client locus).
///
/// The target endpoint of a `@CsTrigger` (`codespecs_mapping.md` §5.20) and the
/// source of a CE-EL element's *derived* action edge (`codespecs_mapping.md`
/// §5.18). The trigger is the single authoring home of that edge, so the
/// element never repeats it.
class CsActionRef {
  /// The camelCase declaration name of the `@CsAction` (N9).
  final String id;

  const CsActionRef(this.id);
}

/// A reference to a **CE-NV route** (client locus).
///
/// Cited by CE-AC navigation outcomes (`codespecs_mapping.md` §5.11) and CE-SC
/// response handling (`codespecs_mapping.md` §5.3). The stable route-id string
/// lives inside the const; the route id is an authored key (N5).
class CsRouteRef {
  /// The route id, verbatim from the specification.
  final String id;

  const CsRouteRef(this.id);
}

/// A reference to a **CE-TX message key** (shared locus).
///
/// Cited by CE-EL and CE-AC copy references (`codespecs_mapping.md`
/// §5.18/§5.20) and by CE-VA rule error keys (`codespecs_mapping.md` §5.19).
/// Named without a `Ref` suffix because the referent *is* the key: a message
/// key is an authored dotted path (N5), and the const is what makes citing it
/// compiler-checked.
class CsMessageKey {
  /// The message key, verbatim from the specification (e.g. `order.shipped`).
  final String id;

  const CsMessageKey(this.id);
}

/// A reference to a **CE-ER error code** (shared locus).
///
/// Cited by CE-TX error-copy entries (`codespecs_mapping.md` §5.21) and by
/// CE-VA rule failures (`codespecs_mapping.md` §5.19). Like [CsMessageKey] the
/// code is an authored key (N5) held verbatim.
class CsErrorCode {
  /// The error code, verbatim from the specification.
  final String id;

  const CsErrorCode(this.id);
}

/// A reference to a **CE-AZ role** (shared locus).
///
/// Cited by `@CsAuthorize` role requirements (`codespecs_mapping.md` §5.15),
/// and lowered at generation to the `TomRoleAccess.roles` strings. Roles are
/// shared because the client cites them too — it renders against the same
/// catalogue the server enforces.
class CsRoleRef {
  /// The camelCase declaration name of the role in the CE-AZ role catalogue.
  final String id;

  const CsRoleRef(this.id);
}

/// A reference to a **CE-AZ resource key** (shared locus).
///
/// Cited by `@CsAuthorize` resource-key requirements and by field-level access
/// guards — a column's `accessKey`, an identity attribute's `accessKey`
/// (`codespecs_mapping.md` §5.15, §5.24). Lowered at generation to
/// `TomResourceKeyAccess.key`.
class CsResourceKeyRef {
  /// The resource key, verbatim from the specification.
  final String id;

  const CsResourceKeyRef(this.id);
}

/// A reference to a **CE-SU service unit** (server locus).
///
/// Server-side grouping references (`codespecs_mapping.md` §5.17). Server-only:
/// the client has no business naming a server's internal service boundaries,
/// and the `codespecs_mapping.md` §4.2 dependency arrows keep it from being
/// able to.
class CsServiceUnitRef {
  /// The camelCase declaration name of the `@CsServiceUnit` (N9).
  final String id;

  const CsServiceUnitRef(this.id);
}

/// A reference to a **CE-RP report definition** (server locus).
///
/// Cited by CE-JB scheduled work (`codespecs_mapping.md` §5.28/§5.29) — a job
/// that produces a report names it rather than restating its projection.
class CsReportRef {
  /// The camelCase declaration name of the `@CsReport` (N9).
  final String id;

  const CsReportRef(this.id);
}

/// A reference to a **CE-JB background job** (server locus).
///
/// Job citations (`codespecs_mapping.md` §5.29). Server-only, for the same
/// reason as [CsServiceUnitRef]: a job runs off the request thread, entirely
/// inside the server project.
class CsJobRef {
  /// The camelCase declaration name of the `@CsJob` (N9).
  final String id;

  const CsJobRef(this.id);
}

/// A reference to a **CE-EL screen element** (client locus).
///
/// The endpoint `codespecs_mapping.md` §5.10 makes `@CsTrigger` the single
/// authoring home of: a `userGesture` trigger names the element it fires from,
/// and an `inFormEvent` field-change trigger names the field element within its
/// form.
///
/// **One type, with an optional owning-form qualifier.** CE-EL's closed
/// catalogue (`codespecs_mapping.md` §5.18) has both standalone kinds
/// (*Button*, *MenuEntry*, *Label*, *FormHost*) — class-level targets — and
/// form-member kinds (*TextInput*, *Number*, *Toggle*, *DateInput*, *Choice*,
/// *MultiChoice*), which are members of the `@CsForm` class. A single type
/// covers both because `@CsTrigger` takes a `CsElementRef` in *both* its
/// element and field slots (`codespecs_derivation_contract.md` §5.1); two types
/// could not fill one parameter. Qualifying with [form] rather than carrying a
/// `Type` + member pair also keeps the family uniform — every ref here is one
/// const wrapping one resolvable string.
///
/// **N9 const-string form:** the element's own camelCase declaration name when
/// standalone, and the dotted `<form>.<element>` [path] when it is a form
/// member — the same canonical-path convention CE-AC uses for
/// `<controllerId>.<actionId>` (`codespecs_mapping.md` §5.20) and CE-TX for its
/// resource keys.
class CsElementRef {
  /// The camelCase declaration name of the element (N9).
  ///
  /// For a form-member element this is the member name alone; [form] carries
  /// the qualifier and [path] joins them.
  final String id;

  /// The camelCase declaration name of the owning `@CsForm`, when the element
  /// is a form member.
  ///
  /// `null` for a standalone element, which is a class-level target and needs
  /// no qualifier.
  final String? form;

  const CsElementRef(this.id, {this.form});

  /// The N9 const-string form: `<form>.<element>` for a form member, the bare
  /// [id] for a standalone element.
  String get path => form == null ? id : '$form.$id';
}

/// A reference to a **CE-FM form** (client locus).
///
/// The owning-form endpoint of an `inFormEvent` trigger (`codespecs_mapping.md`
/// §5.20). A form is always a class-level target, so — unlike [CsElementRef] —
/// it needs no qualifier.
class CsFormRef {
  /// The camelCase declaration name of the `@CsForm` (N9).
  final String id;

  const CsFormRef(this.id);
}
