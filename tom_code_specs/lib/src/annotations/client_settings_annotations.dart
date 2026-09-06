/// Client-application, configuration, settings, identity and authentication
/// CodeSpecs part markers (`Cs*`) — `codespecs_mapping.md` §4.1, §5.16, §5.24,
/// §11.
///
/// Like every other `Cs*` marker these annotate a class **built on** an
/// existing `tom_core`-family class; there is no `Cs*` base class to extend.
/// They are grouped in one file because they share the *who owns this value*
/// concern — the four owner-keyed configuration/settings scopes of
/// `codespecs_mapping.md` §11 plus the identity and authentication surfaces
/// that supply the owner.
///
/// Locus (which project of the three-project output trio they land in —
/// `codespecs_mapping.md` §4.2):
///
/// - [CsClient] / [CsClientConfig] / [CsDeviceSetting] — client project.
/// - [CsUserSetting] — client shape + server persistence (the value follows the
///   user, `codespecs_mapping.md` §11).
/// - [CsIdentity] / [CsIdentityAttribute] — shared (the declaration is contract:
///   both sides read attributes from the token) + server (population).
/// - [CsAuth] — shared + client + server (credential/token/session flow).
///
/// The closed catalogues these markers select from live in `vocabulary.dart`,
/// and the typed cross-part references they cite in `cross_part_refs.dart`.
///
/// @docImport 'service_annotations.dart';
library;

import 'cross_part_refs.dart';
import 'vocabulary.dart';

/// CE-CL — a client application (which clients exist: Flutter app, CLI, other
/// server). The client-application descriptor.
class CsClient {
  /// The client's id, verbatim.
  ///
  /// **Required, first positional** — an authored external identifier
  /// (`codespecs_derivation_contract.md` §2.1 N5). A multi-client system
  /// generates one client project per [CsClient]; this names which.
  final String clientId;

  /// Which kind of application this is.
  ///
  /// **Required, with no default**: the kind decides which *other* parts the
  /// client can carry — a CLI has no CE-EL — so defaulting it would silently
  /// admit impossible combinations.
  final CsClientKind kind;

  /// Optional part-specific note.
  ///
  /// Target platforms and the entry route are members of the descriptor, not
  /// arguments here.
  final String? note;

  /// Declares the annotated class as the CE-CL descriptor of the client
  /// application [clientId].
  ///
  /// [clientId] is the first positional argument and an **authored key**: it is
  /// taken from the specification verbatim, never derived and never re-cased
  /// (`codespecs_derivation_contract.md` §2.1 N5), and a missing one fails
  /// generation under `codespecs_derivation_contract.md` §6 check 4. A multi-client system generates one
  /// client
  /// project per `@CsClient`, so this string also names the project.
  ///
  /// [kind] draws from [CsClientKind] (`vocabulary.dart`) —
  /// [CsClientKind.flutterApp], [CsClientKind.cli] or [CsClientKind.server] —
  /// and is required with **no default**, because the kind decides which
  /// *other* parts the client may carry: a [CsClientKind.cli] client has no
  /// CE-EL at all. Defaulted, it would silently admit a client whose generated
  /// project contains elements nothing can render.
  ///
  /// Target platforms and the entry route are members of the descriptor class,
  /// not arguments here.
  const CsClient(this.clientId, {required this.kind, this.note});
}

/// CE-CC — client configuration: per-machine settings of a client app (API base
/// URL, device options, per-install toggles), keyed by (client app, machine).
///
/// Distinct from [CsServerConfig] (server/system configuration) and from
/// [CsUserSetting] (a user's preferences).
class CsClientConfig {
  /// The setting key, verbatim.
  ///
  /// **Required, first positional**, and one of the `codespecs_mapping.md`
  /// §5.23 string-reference exemptions.
  final String key;

  /// The environment variable this setting may also be read from, verbatim.
  final String? envAlias;

  /// Which narrower scope, if any, may shadow this key — a per-user setting
  /// (CE-UP) or a per-user-per-device one (CE-DS).
  ///
  /// **Required**, undefaulted, and authored only here at the wider scope — see
  /// [CsOverridableBy] for both reasons.
  final CsOverridableBy overridableBy;

  /// Optional part-specific note.
  ///
  /// The setting's type and default are the member declaration.
  final String? note;

  /// Declares the annotated member as the CE-CC client-configuration setting
  /// [key], shadowable no more widely than [overridableBy] permits.
  ///
  /// [key] is the first positional argument, verbatim from the specification. A
  /// setting key is an authored key (`codespecs_derivation_contract.md` §2.1
  /// N5) and one of `codespecs_mapping.md` §5.23's four string-reference
  /// exemptions, because it names a runtime lookup rather than a Dart
  /// declaration — so the compiler cannot see it, and
  /// `codespecs_derivation_contract.md` §6 checks 4 and 20 (a missing key, two
  /// declarations claiming one key) stand in for it.
  ///
  /// [overridableBy] draws from [CsOverridableBy] (`vocabulary.dart`) and is
  /// required with no default, per `codespecs_mapping.md` §5.16's fail-safe
  /// rule: a value's blast radius chosen by omission is precisely the failure
  /// the rule exists to prevent. CE-CC has two scopes beneath it in the `CE-DS
  /// ▸ CE-UP ▸ CE-CC ▸ CE-CF` lattice, so [CsOverridableBy.user],
  /// [CsOverridableBy.device] and [CsOverridableBy.none] are the admissible
  /// values here; [CsOverridableBy.client] is not strictly narrower and is
  /// rejected by `codespecs_derivation_contract.md` §6 check 15.
  ///
  /// [envAlias] names the environment variable the value may also be read from,
  /// verbatim; omit it where there is none. The setting's **type and default
  /// are the member declaration**, never arguments.
  const CsClientConfig(
    this.key, {
    required this.overridableBy,
    this.envAlias,
    this.note,
  });
}

/// CE-DS — a device setting: a *user-specific* setting of a user-owned device,
/// keyed by (user, device) and persisted on the device (window layout,
/// last-opened, machine-local cache preferences). See `codespecs_mapping.md`
/// §5.16 and §11.
///
/// The discriminator against [CsClientConfig] is **user identity in the key**: a
/// value that is the same for every user of an install is CE-CC; a value that
/// differs per signed-in user on the same install is CE-DS. The discriminator
/// against [CsUserSetting] is that a device setting never leaves the device,
/// where a user setting follows the user onto any device they sign in on.
///
/// Device binding is implicit-by-storage — the store lives on the device and is
/// keyed by the signed-in user; there is no wire-level device identity, and
/// server-side enumeration of a user's devices is not modelled.
///
/// Spec-authorable surface: the setting's key, type and default. The value
/// itself is the user's persisted choice, never authored. Reuse — the existing
/// `tom_core` property/settings classes carry it, with no gap class.
class CsDeviceSetting {
  /// The setting key, verbatim.
  ///
  /// **Required, first positional**, and one of the `codespecs_mapping.md`
  /// §5.23 string-reference exemptions.
  final String key;

  /// Optional part-specific note.
  ///
  /// Type and default are the member declaration, and there is **no persistence
  /// mode argument** — see the class comment.
  final String? note;

  /// Declares the annotated member as the CE-DS device setting [key].
  ///
  /// [key] is the sole positional argument, verbatim from the specification —
  /// an authored key under `codespecs_derivation_contract.md` §2.1 N5 and one
  /// of `codespecs_mapping.md` §5.23's string-reference exemptions — so
  /// `codespecs_derivation_contract.md` §6 check 4, rather than the compiler,
  /// is what catches a missing one.
  ///
  /// **There is no `overridableBy`**, and that is a property of the lattice
  /// rather than an omission: CE-DS is the narrowest scope in `CE-DS ▸ CE-UP ▸
  /// CE-CC ▸ CE-CF` (`codespecs_mapping.md` §5.16), so there is no narrower
  /// scope left for it to open (`codespecs_derivation_contract.md` §5.1).
  ///
  /// Nor is there a persistence-mode argument. The scope key alone decides
  /// where a value lives, so the choice is *which marker you write*: a value
  /// that must follow the user onto another device is [CsUserSetting], and a
  /// value that is the same for every user of an install is [CsClientConfig].
  /// Type and default are the member declaration.
  const CsDeviceSetting(this.key, {this.note});
}

/// CE-UP — a user setting / profile value, keyed by the **user** and persisted
/// **server-side**, so it follows the user onto any device they sign into
/// (theme, language, notification prefs). See `codespecs_mapping.md` §11.
///
/// **Single-moded — there is no persistence argument.** `codespecs_mapping.md`
/// §11 splits configuration and settings into four parts, one per scope key,
/// and the scope key alone decides where a value lives; the choice is therefore
/// *which marker you use*, never a mode on one of them. A setting that must
/// stay on the machine is [CsDeviceSetting] (keyed by user *and* device) or
/// [CsClientConfig] (no user in the key at all).
///
/// A CE-UP setting spans two of the three generated projects
/// (`codespecs_mapping.md` §4.2): its shape is declared in the client project,
/// its persistence lives in the server project. Spec-authorable surface: the
/// setting's key, type and default (`codespecs_mapping.md` §5.16) — the value
/// is the user's persisted choice, never authored.
class CsUserSetting {
  /// The setting key, verbatim.
  ///
  /// **Required, first positional**. Both halves of the declaration — the
  /// client shape and the server persistence — use the same key and the same
  /// member names, so the wire mapping is identity.
  final String key;

  /// Whether a per-user-per-device setting (CE-DS) may shadow this key.
  ///
  /// **Required**, undefaulted, and authored only here at the wider scope — see
  /// [CsOverridableBy] for both reasons. CE-DS is the narrowest scope, so
  /// [CsDeviceSetting] carries no counterpart: the lattice bottoms out there.
  final CsOverridableBy overridableBy;

  /// Optional part-specific note.
  ///
  /// Type and default are the member declaration.
  final String? note;

  /// Declares the annotated member as the CE-UP user setting [key], shadowable
  /// no more widely than [overridableBy] permits.
  ///
  /// [key] is the first positional argument, verbatim
  /// (`codespecs_derivation_contract.md` §2.1 N5). A CE-UP setting spans two of
  /// the three generated projects — its shape in the client project, its
  /// persistence in the server project — and **both halves use this same key
  /// and the same member names**, so the wire mapping is identity. A key that
  /// differs between the halves does not fail to compile; it quietly becomes
  /// two settings.
  ///
  /// [overridableBy] draws from [CsOverridableBy] (`vocabulary.dart`) and is
  /// required with no default (`codespecs_mapping.md` §5.16's fail-safe rule).
  /// CE-UP has exactly one scope beneath it, so only [CsOverridableBy.device]
  /// and [CsOverridableBy.none] are admissible here; [CsOverridableBy.client]
  /// or [CsOverridableBy.user] name scopes that are not strictly narrower and
  /// are rejected by `codespecs_derivation_contract.md` §6 check 15.
  const CsUserSetting(this.key, {required this.overridableBy, this.note});
}

/// CE-ID — the app's identity-extension declaration holder
/// (`codespecs_mapping.md` §5.24).
///
/// The principal *core* is framework-fixed: `TomUser` (username, names, email,
/// phone, address, time zone) wrapped by `TomPrincipal` (`tom_core_kernel`).
/// Those runtime fields are not spec input. What an app declares is the
/// **extension** riding on top — an ordinary class whose members are marked
/// [CsIdentityAttribute] and which is carried as JSON via reflection into the
/// user-profile carrier. Reuse, no gap class: the typing comes from the
/// app-authored class, not a framework type.
///
/// Distinct from [CsAuth], which *establishes* the principal and performs the
/// public/encrypted token projection — CE-AU consumes CE-ID. Distinct from
/// [CsUserSetting]: identity attributes describe who the user *is* and travel in
/// the token; settings are changeable preferences and live in the settings
/// store.
class CsIdentity {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated class as the application's CE-ID identity-extension
  /// holder (`codespecs_derivation_contract.md` §3.2.5).
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): the holder has no
  /// attribute of its own. What it *is* is the set of members marked
  /// [CsIdentityAttribute], and the typing comes from this app-authored class
  /// rather than from a framework type — reuse with no gap class — so there is
  /// nothing left for an argument to carry.
  ///
  /// [note] records why the extension exists, not what is in it. An attribute
  /// described here but not declared as a marked member is invisible to the
  /// public/encrypted token projection [CsAuth] performs.
  const CsIdentity({this.note});
}

/// CE-ID — one declared identity-extension attribute; a **member marker** on a
/// [CsIdentity] holder, the same pattern as `@CsColumn` (`codespecs_mapping.md`
/// §5.24).
///
/// [placement] is **required**: it decides whether the attribute is readable by
/// anything holding the token or only by the decrypting layers, and
/// `codespecs_mapping.md` §5.16's fail-safe rule is that broadening a value's
/// blast radius must be a deliberate authored act. Neither arm is therefore a
/// default.
///
/// The attribute's **type** stays on the member declaration; everything else the
/// SOM `UserAttributeEntry` section carries is an argument here.
class CsIdentityAttribute {
  /// Which token payload this attribute rides in.
  final CsIdentityAttributePlacement placement;

  /// The resource key gating field-level access to this attribute.
  ///
  /// A public attribute is readable by anything holding the token, so this —
  /// not the transport — is what guards it (`codespecs_mapping.md` §5.24).
  final CsResourceKeyRef? accessKey;

  /// The system the attribute's value is sourced from, verbatim.
  ///
  /// `null` means this application owns it.
  final String? systemOfRecord;

  /// Whether a principal without this attribute is incomplete.
  ///
  /// Defaults to `false` — an identity extension is additive, and demanding an
  /// attribute is the deliberate act.
  final bool required;

  /// Optional part-specific note.
  final String? note;

  /// Declares the annotated member as one CE-ID identity-extension attribute,
  /// carried in the [placement] half of the token.
  ///
  /// [placement] draws from [CsIdentityAttributePlacement] (`vocabulary.dart`)
  /// and is required with no default, because it is a **disclosure decision**:
  /// [CsIdentityAttributePlacement.public] rides `TomUser.attributes` and is
  /// readable by anything holding the token, while
  /// [CsIdentityAttributePlacement.encrypted] rides
  /// `TomPrincipal.currentContext` and is readable only by the token-decrypting
  /// layers. Choosing `public` for an attribute that should not have been
  /// discloses it to every token holder for as long as the token lives, which
  /// is why `codespecs_mapping.md` §5.16's fail-safe rule leaves neither arm as
  /// a default.
  ///
  /// [accessKey] is the CE-AZ resource key gating **field-level** access. On a
  /// public attribute it is the only guard there is, since the transport is not
  /// one. It is a typed [CsResourceKeyRef] const, so a renamed key is a compile
  /// break and `codespecs_derivation_contract.md` §6 check 2 resolves the
  /// string it wraps.
  ///
  /// [systemOfRecord] names the external system the value is sourced from,
  /// verbatim; `null` means this application owns it.
  /// [CsIdentityAttribute.required] — the attribute's own field name, not the
  /// Dart modifier — defaults to `false`, because an identity extension is
  /// additive and demanding an attribute of every principal is the deliberate
  /// act. The attribute's **type** stays on the member declaration.
  const CsIdentityAttribute({
    required this.placement,
    this.accessKey,
    this.systemOfRecord,
    this.required = false,
    this.note,
  });
}

/// CE-AU — authentication / session: credential exchange, token, session.
///
/// Distinct from [CsAuthorize] (CE-AZ authorization, which gates individual
/// operations). Authentication spans shared + client + server. It **consumes**
/// [CsIdentity]: the attributes an app declares there are what CE-AU projects
/// into the public and encrypted halves of the token.
class CsAuth {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated declaration as the CE-AU authentication / session
  /// surface (`codespecs_derivation_contract.md` §3.2.7, §3.4.4, §3.5.10).
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): the mechanics —
  /// credential exchange, token minting, session lifetime — are
  /// framework-fixed, and the spec-authorable policy surface
  /// `codespecs_mapping.md` §5.25 identifies lands on the substrate's own
  /// constructors rather than on this marker.
  ///
  /// The marker is written **three times for one part**, once per locus: shared
  /// for the wire/token half, server for the flow and CE-ID population, client
  /// for the login flow. Do not confuse it with [CsAuthorize], which gates
  /// individual operations — CE-AU *establishes* the principal that CE-AZ then
  /// tests, and consumes [CsIdentity] to decide what rides in each half of the
  /// token.
  const CsAuth({this.note});
}
