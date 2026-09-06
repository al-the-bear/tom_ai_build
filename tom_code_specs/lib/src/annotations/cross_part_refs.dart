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
///
/// **The family is `cross`-part; intra-part edges are out of scope.** An edge
/// whose target lies inside the same part declaration is a **local
/// coordinate**, not a reference — typing it would widen the family from "how
/// parts cite each other" to "how any id is written". Two exist, both id
/// strings guarded by a generation-time validator check: a CE-LO delta's node
/// id (`codespecs_mapping.md` §5.22), and a CE-NT channel's fallback, which
/// names a **sibling channel** (`codespecs_mapping.md` §4.3.2;
/// `codespecs_derivation_contract.md` §6 check 17). That is why there is no
/// `CsChannelRef` here — not an omission.
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

  /// Wraps the CE-API operation name [id] as a typed reference.
  ///
  /// Positional and required. [id] is an **authored key** carried verbatim from
  /// the specification (`codespecs_derivation_contract.md` §2.1 N5) rather than
  /// a name derived from a declaration: `'customer.save'` stays
  /// `'customer.save'`, dot and case intact.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
  ///
  /// One further check is specific to this type:
  /// `codespecs_derivation_contract.md` §6 check 12 asserts a server handler's
  /// `@CsEndpoint` operation string equals the shared half's ref, so the two
  /// loci cannot drift into a declared operation nobody serves and a served one
  /// nobody declared.
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

  /// Wraps the `@CsServerCall` declaration name [id] as a typed reference.
  ///
  /// Positional and required. [id] is the **camelCase declaration name** of the
  /// target call (`codespecs_derivation_contract.md` §2.1 N9), which the
  /// generator derives from the section's designated name field — so an author
  /// never invents it, and hand-writing a plausible-looking name is how a ref
  /// dangles.
  ///
  /// This is hop 1 of the two-hop CE-AC → CE-SC → CE-API chain
  /// (`codespecs_mapping.md` §5.3): holding each hop as a reference rather than
  /// by containment is what keeps an action, its server call and the operation
  /// independently authorable.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the `@CsAction` declaration name [id] as a typed reference.
  ///
  /// Positional and required, and the camelCase declaration name of the target
  /// action (`codespecs_derivation_contract.md` §2.1 N9).
  ///
  /// This is the const a `@CsTrigger` cites in its action slot, which
  /// `codespecs_mapping.md` §5.10 makes the **single authoring home** of the
  /// element→action edge. A CE-EL element derives its action edge from the
  /// trigger and never carries a copy, so naming the action a second time on
  /// the element does not reinforce the link — it forks it.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the CE-NV route id [id] as a typed reference.
  ///
  /// Positional and required, and verbatim: a route id is an **authored key**
  /// (`codespecs_derivation_contract.md` §2.1 N5), not a derived declaration
  /// name.
  ///
  /// The consts live on the navigation catalogue — the one file holding all of
  /// a document's routes, which is the single several-declarations-per-file
  /// case `codespecs_derivation_contract.md` §2.1 N7 sanctions — and are cited
  /// from CE-AC navigation outcomes and CE-SC response handling.
  ///
  /// There is one route edge this type deliberately does **not** carry: a CE-RP
  /// report column's drill-through target. The column is server-owned and
  /// `codespecs_mapping.md` §5.23's locus rule bars it from citing a
  /// client-owned route, so that edge stays an id string and
  /// `codespecs_derivation_contract.md` §6 check 18 resolves it in the
  /// compiler's place.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the dotted CE-TX message key [id] as a typed reference.
  ///
  /// Positional and required, and verbatim: a message key is an **authored
  /// key** (`codespecs_derivation_contract.md` §2.1 N5), so `'order.shipped'`
  /// is carried character for character and a missing one fails generation
  /// under `codespecs_derivation_contract.md` §6 check 4.
  ///
  /// This is the const every "copy" argument in the framework takes — a
  /// validation rule's error key, a notification's body, a job's failure alert.
  /// None of them accepts a `String`, and that is the point: copy that never
  /// entered the CE-TX catalogue is copy no `TomTextResourceProvider` lookup
  /// can translate.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the CE-ER error code [id] as a typed reference.
  ///
  /// Positional and required, and verbatim from the specification — an error
  /// code is an **authored key** (`codespecs_derivation_contract.md` §2.1 N5).
  ///
  /// The code doubles as the **lookup key for its own copy**:
  /// `codespecs_mapping.md` §5.21 keys error copy by the error code rather than
  /// by a separate message key, which is what makes the catalogue's two halves
  /// load-bearing rather than cosmetic. A code changed here without its
  /// `@CsText` entry following leaves the failure with nothing to show the
  /// user.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps a CE-AZ role's declaration name [id] as a typed reference.
  ///
  /// Positional and required, and the camelCase declaration name of the role in
  /// the CE-AZ role catalogue (`codespecs_derivation_contract.md` §2.1 N9). At
  /// generation it is lowered to a `TomRoleAccess.roles` string; spec-level
  /// code never writes that string itself.
  ///
  /// Roles are declared in the **shared** project because the client cites the
  /// same catalogue the server enforces (`codespecs_derivation_contract.md`
  /// §2.6) — a client-local role list would render an affordance the server
  /// then refuses.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the CE-AZ resource key [id] as a typed reference.
  ///
  /// Positional and required, and verbatim from the specification — a resource
  /// key is an **authored key** (`codespecs_derivation_contract.md` §2.1 N5).
  /// Lowered at generation to `TomResourceKeyAccess.key`.
  ///
  /// This is the const that carries access control where there is no operation
  /// to hang a requirement on: a CE-DB column's access key and a CE-ID identity
  /// attribute's (`codespecs_mapping.md` §5.15, §5.24). On a *public* identity
  /// attribute it is the only guard in existence, because the token carrying
  /// the attribute is readable by anything holding it.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the `@CsServiceUnit` declaration name [id] as a typed reference.
  ///
  /// Positional and required, and the camelCase declaration name of the target
  /// unit (`codespecs_derivation_contract.md` §2.1 N9).
  ///
  /// Declared and cited **server-side only**. `codespecs_mapping.md` §4.2's
  /// dependency arrows run shared → {client, server} and are never inverted
  /// (`codespecs_derivation_contract.md` §6 check 11), so a client declaration
  /// citing this const does not merely breach a convention — the const is not
  /// on its side of the arrow and will not resolve.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
  const CsServiceUnitRef(this.id);
}

/// A reference to a **CE-RP report definition** (server locus).
///
/// Cited by CE-JB scheduled work (`codespecs_mapping.md` §5.28/§5.29) — a job
/// that produces a report names it rather than restating its projection.
class CsReportRef {
  /// The camelCase declaration name of the `@CsReport` (N9).
  final String id;

  /// Wraps the `@CsReport` declaration name [id] as a typed reference.
  ///
  /// Positional and required, and the camelCase declaration name of the target
  /// report definition (`codespecs_derivation_contract.md` §2.1 N9).
  ///
  /// Cited from CE-JB scheduled work (`codespecs_mapping.md` §5.29): a job that
  /// produces a report names it here rather than restating its projection, so
  /// the projection keeps exactly one home and a changed grouping cannot leave
  /// a second description of it behind. Server locus, like the report itself.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the `@CsJob` declaration name [id] as a typed reference.
  ///
  /// Positional and required, and the camelCase declaration name of the target
  /// job (`codespecs_derivation_contract.md` §2.1 N9).
  ///
  /// Server locus for the same reason as [CsServiceUnitRef]: a job runs off the
  /// request thread, entirely inside the server project, and the
  /// `codespecs_mapping.md` §4.2 dependency arrows keep the client from citing
  /// it (`codespecs_derivation_contract.md` §6 check 11).
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps a CE-EL element's declaration name [id] as a typed reference,
  /// qualified by [form] when the element is a form member.
  ///
  /// [id] is positional and required, the camelCase declaration name of the
  /// element (`codespecs_derivation_contract.md` §2.1 N9) — for a form member,
  /// the member name **alone**, because [form] carries the qualifier and [path]
  /// joins them.
  ///
  /// [form] is the one thing to get right on this type. Omit it for a
  /// standalone element — the class-level kinds *Button*, *MenuEntry*, *Label*,
  /// *FormHost* — and supply the owning `@CsForm`'s camelCase declaration name
  /// for a form-member kind (*TextInput*, *Number*, *Toggle*, *DateInput*,
  /// *Choice*, *MultiChoice*, *FileInput*), which is a member of the form class
  /// and is not resolvable on its own. The string the validator resolves is
  /// [path], not [id], so an unqualified form member fails
  /// `codespecs_derivation_contract.md` §6 check 2 rather than matching some
  /// other declaration.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
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

  /// Wraps the `@CsForm` declaration name [id] as a typed reference.
  ///
  /// Positional and required, and the camelCase declaration name of the target
  /// form (`codespecs_derivation_contract.md` §2.1 N9). A form is always a
  /// class-level target, so — unlike [CsElementRef] — there is no qualifier and
  /// nothing to omit.
  ///
  /// Cited as the source of an `inFormEvent` trigger. Where that trigger is a
  /// `fieldChange`, the field is a **separate** [CsElementRef] carrying this
  /// same form as its qualifier; the two arguments are not interchangeable and
  /// filling one with the other's value is the mistake this pairing invites.
  ///
  /// Declared **once**, as a `static const` on the owning part's generated
  /// catalogue class, and cited from there (`codespecs_derivation_contract.md`
  /// §2.6); re-constructing it at a call site compiles but puts the string
  /// literal back into the code a rename must break.
  /// `codespecs_derivation_contract.md` §6 check 2 resolves every ref string to
  /// a generated declaration and calls an unresolved one a generation error,
  /// never a warning.
  const CsFormRef(this.id);
}
