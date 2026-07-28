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
library;

/// CE-CL — a client application (which clients exist: Flutter app, CLI, other
/// server). The client-application descriptor.
class CsClient {
  /// Optional part-specific note.
  final String? note;

  const CsClient({this.note});
}

/// CE-CC — client configuration: per-machine settings of a client app (API base
/// URL, device options, per-install toggles), keyed by (client app, machine).
///
/// Distinct from [CsServerConfig] (server/system configuration) and from
/// [CsUserSetting] (a user's preferences).
class CsClientConfig {
  /// Optional part-specific note.
  final String? note;

  const CsClientConfig({this.note});
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
  /// Optional part-specific note.
  final String? note;

  const CsDeviceSetting({this.note});
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
  /// Optional part-specific note.
  final String? note;

  const CsUserSetting({this.note});
}

/// Where a [CsIdentityAttribute] rides in the token payload
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
/// The rest of the per-attribute surface — the attribute's type, its access
/// guard, its system of record and whether it is required — is carried by the
/// member declaration itself and by the SOM `UserAttributeEntry` section that
/// feeds it.
class CsIdentityAttribute {
  /// Which token payload this attribute rides in.
  final IdentityAttributePlacement placement;

  /// Optional part-specific note.
  final String? note;

  const CsIdentityAttribute({required this.placement, this.note});
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
