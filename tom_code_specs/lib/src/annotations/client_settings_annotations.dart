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

  /// Optional part-specific note.
  ///
  /// The setting's type and default are the member declaration.
  final String? note;

  const CsClientConfig(this.key, {this.envAlias, this.note});
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

  /// Optional part-specific note.
  ///
  /// Type and default are the member declaration.
  final String? note;

  const CsUserSetting(this.key, {this.note});
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
  final IdentityAttributePlacement placement;

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

  const CsAuth({this.note});
}
