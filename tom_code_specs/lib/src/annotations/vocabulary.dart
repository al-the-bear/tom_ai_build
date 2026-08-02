/// The closed catalogues the `Cs*` markers select from
/// (`codespecs_derivation_contract.md` §5.3).
///
/// **Why they live here and not in `tom_core`.** `tom_code_specs` is
/// annotations-only and deliberately does **not** depend on `tom_core`
/// (`codespecs_mapping.md` §9.5). Every closed catalogue a marker selects from is
/// therefore declared locally, mirroring its `tom_core` counterpart one-for-one
/// where one exists ([CsErrorSeverity] ↔ `TomErrorSeverity`). A named validator
/// check asserts each mirror is complete
/// (`codespecs_derivation_contract.md` §6 check 9): a `tom_core` catalogue that
/// grows without its mirror growing is a build failure, not a silent divergence.
///
/// **Why they are enums and not strings.** A catalogue is *closed* — adding a
/// value is an edit to the taxonomy, reviewed as such, not a free-form attribute
/// a specification can invent in passing. Making them enums moves that
/// discipline from convention into the type system, the same reason
/// `codespecs_mapping.md` §5.23 makes cross-part references typed consts rather
/// than id strings.
///
/// **These are not annotations** — they are annotation *parameter* vocabulary,
/// the same role `DocRef` plays for `@DocSpec` and the `Cs*Ref` family plays for
/// cross-part edges.
///
/// Two catalogues here predate the rest — [TriggerKind] and
/// [IdentityAttributePlacement] shipped with their markers. They keep their
/// established names (`codespecs_derivation_contract.md` §5.1 retains them
/// verbatim) and are gathered here so that *all* closed catalogues sit in one
/// file rather than beside whichever marker happened to introduce them.
library;

/// How severe a CE-ER error code is (`codespecs_derivation_contract.md` §3.1.2).
///
/// Mirrors `TomErrorSeverity` (`tom_core_kernel`) value-for-value.
enum CsErrorSeverity {
  /// Informational — the operation succeeded and is reporting something.
  info,

  /// The operation succeeded but the result is degraded or suspect.
  warning,

  /// The operation failed and the caller can act on it.
  error,

  /// The operation failed unrecoverably.
  fatal,
}

/// What a CE-TX message key is copy *for* (`codespecs_mapping.md` §5.21).
///
/// The role selects which resolution path the copy takes at runtime and, for
/// [error], constrains the category — a validator asserts
/// `role == error ⇒ category == errorCopy`
/// (`codespecs_derivation_contract.md` §6 check 10).
enum CsTextRole {
  /// Copy shown when an error code or a validation rule fails.
  error,

  /// Copy carried by a CE-NT notification.
  notification,

  /// Copy carried by an outbound email.
  email,

  /// A CE-RP report label.
  report,

  /// Ordinary interface copy with no specialised role.
  generic,
}

/// Which catalogue half a CE-TX message key belongs to
/// (`codespecs_mapping.md` §5.21).
///
/// Error copy is keyed **by the error code**, which is what makes the split
/// load-bearing rather than cosmetic: the two halves are resolved by different
/// lookups.
enum CsTextCategory {
  /// Interface copy, keyed by its own dotted message key.
  uiCopy,

  /// Error copy, keyed by the CE-ER error code it explains.
  errorCopy,
}

/// The closed CE-EL semantic element catalogue
/// (`codespecs_mapping.md` §5.18).
///
/// The kind is the **specification**; the concrete `tom_flutter_ui` widget that
/// realises it is the *implementation* and is carried by the `@CsWidget`
/// instantiation. That two-step split (`codespecs_mapping.md` §5.7.1) is what
/// lets a specification stay at the semantic level while the generated code
/// stays typed.
///
/// The first six kinds are **form members** — they carry a value and are
/// declared inside a `@CsForm`. The last four are **standalone**: they are
/// class-level declarations. `CsElementRef` spans both, qualifying a form member
/// with its owning form.
enum CsElementKind {
  /// A free-text value.
  textInput,

  /// A numeric value.
  number,

  /// A boolean value.
  toggle,

  /// A date or date-time value.
  dateInput,

  /// One value chosen from a closed set.
  choice,

  /// Several values chosen from a closed set.
  multiChoice,

  /// Static copy with no value of its own.
  label,

  /// An action affordance.
  button,

  /// An action affordance inside a menu.
  menuEntry,

  /// A container element hosting a form.
  formHost,
}

/// The gesture arm of a `userGesture` trigger (`codespecs_mapping.md` §5.20).
enum CsGesture {
  /// A short activation.
  tap,

  /// A press-and-hold that fires on press.
  press,

  /// A press-and-hold that fires after the long-press threshold.
  longPress,
}

/// The form-event arm of an `inFormEvent` trigger
/// (`codespecs_mapping.md` §5.20).
enum CsFormEvent {
  /// A named field's value changed.
  fieldChange,

  /// The form was submitted.
  submit,

  /// Form validation completed with no errors.
  validationPass,

  /// Form validation completed with at least one error.
  validationFail,
}

/// How long a scoped thing lives (`codespecs_mapping.md` §5.4, §5.20).
///
/// Shared by CE-ST view models (whose state it bounds) and by `lifecycle`
/// triggers (whose phase it qualifies). [screen] is the narrowest arm and is the
/// CE-ST default, so widening a view model's lifetime is a deliberate act.
enum CsLifecycleScope {
  /// Lives as long as the screen that owns it.
  screen,

  /// Lives as long as the route, across the screens it contains.
  route,

  /// Lives as long as the application session.
  app,
}

/// The phase arm of a `lifecycle` trigger (`codespecs_mapping.md` §5.20).
enum CsLifecyclePhase {
  /// The scope became visible.
  enter,

  /// The scope stopped being visible.
  leave,

  /// The scope was created.
  init,

  /// The scope was destroyed.
  dispose,
}

/// What a CE-AZ authorization requirement demands
/// (`codespecs_mapping.md` §5.15).
///
/// One closed enum folding together §5.15's **six attribute-bearing requirement
/// kinds** ([role], [group], [entitlement], [resourceKey], [custom], [graded])
/// and its **four attribute-less presets** ([none], [public], [authenticated],
/// [guest]). The presets carry no payload because the kind *is* the whole
/// requirement.
///
/// No arm is a default. Defaulting an authorization requirement is the exact
/// failure `codespecs_mapping.md` §5.16's fail-safe rule exists to prevent, so
/// `@CsAuthorize.requirement` is required.
enum CsAuthRequirement {
  /// The principal must hold one of a named set of roles.
  role,

  /// The principal must belong to one of a named set of groups.
  group,

  /// The principal's entitlements must match one of a set of patterns.
  entitlement,

  /// The principal must hold a grant on a named resource key.
  resourceKey,

  /// A registered handler decides, against a named resource id.
  custom,

  /// A graded requirement tree resolving to one of the four access states.
  graded,

  /// Deny unconditionally.
  none,

  /// Allow unconditionally, signed in or not.
  public,

  /// Allow any signed-in principal.
  authenticated,

  /// Allow the guest principal.
  guest,
}

/// Which kind of client application a CE-CL descriptor declares
/// (`codespecs_mapping.md` §4.1).
///
/// Required on `@CsClient` because the kind decides which *other* parts the
/// client can carry — a CLI has no CE-EL — and defaulting it would silently
/// admit impossible combinations.
enum CsClientKind {
  /// A Flutter application.
  flutterApp,

  /// A command-line application.
  cli,

  /// Another server calling this one as a client.
  server,
}

/// The three CE-MG artifact kinds (`codespecs_mapping.md` §5.27).
///
/// No arm is a safe default: generating an initial DDL where an iteration was
/// meant would rewrite a live schema.
enum CsMigrationKind {
  /// The schema-creating DDL for a new deployment.
  initialDdl,

  /// The new system's base / seed reference data.
  baseData,

  /// An append-only change applied on top of an existing schema.
  iteration,
}

/// What starts a CE-JB background job (`codespecs_mapping.md` §5.29).
///
/// Each arm lowers onto the matching `tom_core_kernel` schedule —
/// `TomCronSchedule` / `TomCalendarSchedule` / `TomEventSchedule` — on
/// `TomJobDefinition.schedule`. The trigger is a **wired** schedule, not a name.
enum CsJobTrigger {
  /// A cron expression.
  cron,

  /// A calendar date/time rule.
  calendar,

  /// A named system event.
  event,
}

/// How a CE-AC action is invoked (`codespecs_mapping.md` §5.20).
///
/// The taxonomy is **closed**: a new invocation path is an edit to this
/// classification, not a free-form attribute — the same closed-catalogue
/// discipline as [CsElementKind] and the CE-VA rule set. The kinds are a
/// *documented framing* over the reused `tom_flutter_ui` action classes
/// (`TomAction` has no trigger concept of its own), which is why the vocabulary
/// lives with the annotations rather than in a new class:
/// `codespecs_mapping.md` §5.10/§5.20 record CE-AC as "no gap — full action
/// implementation reused".
enum TriggerKind {
  /// Fired by a user acting on a CE-EL element (tap / press / long-press).
  userGesture,

  /// Fired by a CE-FM form event (field change, submit, validation pass/fail).
  inFormEvent,

  /// Fired by a screen, route or app lifecycle phase.
  lifecycle,

  /// Fired by an inbound server push or notification.
  serverEvent,

  /// Fired by a reactive predicate over CE-ST observable state — the
  /// `canExecute` case.
  condition,
}

/// Where a CE-ID identity attribute rides in the token payload
/// (`codespecs_mapping.md` §5.24).
///
/// The two arms are the two carriers the `tom_core` principal already has, so
/// the choice is a placement decision, not a new mechanism.
enum IdentityAttributePlacement {
  /// Rides the **public** token payload, in `TomUser.attributes`. Readable by
  /// anything holding the token, so a public attribute is guarded field-level by
  /// a resource key rather than by the transport.
  public,

  /// Rides the **encrypted** context of the authorization JWT, in
  /// `TomPrincipal.currentContext`. Readable only by the token-decrypting
  /// layers.
  encrypted,
}
