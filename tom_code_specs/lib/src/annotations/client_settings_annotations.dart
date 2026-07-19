/// Client-application, configuration, user-settings and authentication CodeSpecs
/// part markers (`Cs*`) — the four parts added by the 2026-07-19 revision
/// (csm2r5, `codespecs_mapping.md` §4, §4.1, §11).
///
/// Like every other `Cs*` marker these annotate a class **built on** an existing
/// `tom_core`-family class; there is no `Cs*` base class to extend. They are
/// grouped in one file because they were introduced together and share the
/// configuration/settings/identity concern that §11 splits three ways.
///
/// Locus (which project of the three-project output trio they land in — §4.2):
///
/// - [CsClient] / [CsClientConfig] — client project.
/// - [CsUserSetting] — client (`local`) and server (`roaming`), per its
///   [SettingsPersistence] discriminator.
/// - [CsAuth] — shared + client + server (credential/token/session flow).
library;

/// Where a [CsUserSetting] is persisted (`codespecs_mapping.md` §11).
enum SettingsPersistence {
  /// Machine-persisted: the setting lives on the client machine and does **not**
  /// follow the user across machines (e.g. window layout, last-opened,
  /// machine-local caches).
  local,

  /// Server-persisted: the setting follows the user and is re-materialised on
  /// any machine they sign into (e.g. theme, language, notification prefs).
  roaming,
}

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

/// CE-UP — a user setting / profile value.
///
/// The [persistence] discriminator decides storage: [SettingsPersistence.local]
/// persists on the client machine; [SettingsPersistence.roaming] persists on the
/// server and follows the user across machines. A roaming setting therefore has
/// both a client-side shape and a server-side persistence (`§11`).
class CsUserSetting {
  /// Where this user setting is persisted. Defaults to
  /// [SettingsPersistence.roaming] (follows the user).
  final SettingsPersistence persistence;

  /// Optional part-specific note.
  final String? note;

  const CsUserSetting({
    this.persistence = SettingsPersistence.roaming,
    this.note,
  });
}

/// CE-AU — authentication / session: credential exchange, token, session.
///
/// Distinct from [CsAuthorize] (CE-AZ authorization, which gates individual
/// operations). Authentication spans shared + client + server.
class CsAuth {
  /// Optional part-specific note.
  final String? note;

  const CsAuth({this.note});
}
