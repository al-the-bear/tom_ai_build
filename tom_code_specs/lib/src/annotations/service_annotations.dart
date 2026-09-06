/// Server-side CodeSpecs part markers (`Cs*`).
///
/// Each annotation marks a CodeSpec class (or member) as realising a
/// *server-side* CodeSpecs part from the authoritative parts catalogue
/// (`codespecs_mapping.md` §4.1). Like the client markers, these are pure
/// markers on a class **built on** an existing `tom_core`-family class — there
/// is no `Cs*` base class to extend.
///
/// The `CE-*` code named by each doc comment is the part's **stable registry
/// key** (`codespecs_mapping.md` §4.1: never reused, never renamed); CE-DB is
/// carried by three markers ([CsTable], [CsColumn], [CsRepository]), CE-NT by
/// two ([CsNotification], [CsNotificationChannel]) and CE-RP by four
/// ([CsReport], [CsReportColumn], [CsReportChart], [CsReportParameter]).
///
/// This file covers the sixteen server-side part markers, plus the one facet
/// value class a marker carries ([CsFileReference] on [CsColumn]). Client/UI
/// markers live in `element_annotations.dart`; shared markers in
/// `contract_annotations.dart`. The closed catalogues these markers select from
/// live in `vocabulary.dart`, and the typed cross-part references they cite in
/// `cross_part_refs.dart`.
///
/// @docImport 'element_annotations.dart';
library;

import 'cross_part_refs.dart';
import 'vocabulary.dart';

/// CE-API — a server endpoint: an operation name plus its request/response and
/// error contract (`codespecs_mapping.md` §5.6.1). All operations are POST
/// (`codespecs_mapping.md` §7).
///
/// One operation, two loci: the shared half declares the operation catalogue and
/// the request/response DTOs, the server half the handler method. Both carry
/// this marker with the **identical** operation string, and a validator asserts
/// they match (`codespecs_derivation_contract.md` §6 check 12).
class CsEndpoint {
  /// The operation name, verbatim from the specification.
  ///
  /// **Required, first positional** — an authored external identifier
  /// (`codespecs_derivation_contract.md` §2.1 N5), so it is never derived and
  /// never re-cased: `'customer.save'` stays `'customer.save'`.
  ///
  /// A plain `String` and not a `CsOperationRef`, because this marker is what
  /// *declares* the operation; the ref const the shared half emits is what
  /// everything else cites.
  ///
  /// The HTTP method and the error-response type are not arguments:
  /// `codespecs_mapping.md` §7 fixes every operation as POST with 5xx-only
  /// transport errors, so neither is spec input. Authorization is the
  /// [CsAuthorize] modifier; the description is CE-TX.
  final String operation;

  /// Optional part-specific note.
  final String? note;

  /// Declares the annotated declaration as the CE-API endpoint for [operation].
  ///
  /// [operation] is the sole positional argument and an **authored key**:
  /// verbatim from the specification, never derived and never re-cased
  /// (`codespecs_derivation_contract.md` §2.1 N5), with a missing one failing
  /// generation under `codespecs_derivation_contract.md` §6 check 4. It is a plain `String` and not a
  /// [CsOperationRef] because this marker is what *declares* the operation; the
  /// ref const the shared half emits is what everything else cites.
  ///
  /// Write the marker **twice for one operation**, once per locus — the shared
  /// half beside the operation catalogue and the DTOs, the server half on the
  /// handler method — with the **identical** string.
  /// `codespecs_derivation_contract.md` §6 check 12 asserts the two agree, so a
  /// typo splits one operation into a declared one nobody serves and a served
  /// one nobody declared, which nothing else in the toolchain would notice.
  ///
  /// The HTTP method and the error-response type are not arguments:
  /// `codespecs_mapping.md` §7 fixes every operation as POST with 5xx-only
  /// transport errors, so neither is spec input. Authorization is a
  /// [CsAuthorize] written beside this marker; the description is CE-TX copy.
  const CsEndpoint(this.operation, {this.note});
}

/// CE-SU — a service unit (a cohesive server-side service).
class CsServiceUnit {
  /// The aggregate root the unit owns.
  ///
  /// **Required**, as a `Type` literal — entities are already Dart types, so
  /// they are cited directly and need no ref const (`codespecs_mapping.md`
  /// §5.23). Owning exactly one root aggregate is the primary boundary criterion
  /// (`codespecs_mapping.md` §5.1), so the unit cannot be declared without it.
  final Type rootAggregate;

  /// The outer bound the unit sits inside, verbatim.
  ///
  /// **Required** — it is the second half of the `codespecs_mapping.md` §5.1
  /// boundary criterion, and a unit with no named context has no stated bound.
  ///
  /// A `String` and not a ref const, because a bounded context is a partition of
  /// the specification and generates no declaration to cite. It is nonetheless a
  /// *checked* name on the document side: it is the `Context Name` of a declared
  /// bounded context, and the entity field it is copied from resolves against
  /// that registry, so two units in one context always carry the identical
  /// string (`codespecs_mapping.md` §5.1 rule 3).
  final String boundedContext;

  /// Optional part-specific note.
  final String? note;

  /// Declares the annotated class as the CE-SU service unit owning
  /// [rootAggregate] inside [boundedContext].
  ///
  /// The two arguments are the two halves of `codespecs_mapping.md` §5.1's
  /// boundary criterion, which is why both are required and neither has a
  /// default: a unit that owns no root aggregate, or sits in no named context,
  /// has no stated boundary — and the boundary is the whole content of the
  /// part.
  ///
  /// [rootAggregate] is a `Type` literal (`rootAggregate: Customer`). Entities
  /// are already Dart types, so `codespecs_mapping.md` §5.23 gives them no ref
  /// const and they are cited directly. Owning **exactly one** root aggregate
  /// is the primary criterion, so a unit that would name two is two units.
  ///
  /// [boundedContext] is a `String` because a bounded context is a partition of
  /// the specification and generates no declaration to cite. It is nonetheless
  /// a *checked* name on the document side: it is a declared bounded context's
  /// `Context Name`, copied from the entity, so two units in one context always
  /// carry the identical string (`codespecs_mapping.md` §5.1 rule 3) — and a
  /// misspelling does not fail, it quietly creates a third context containing
  /// one unit.
  const CsServiceUnit({
    required this.rootAggregate,
    required this.boundedContext,
    this.note,
  });
}

/// CE-DB — a persistent table (a stored entity type, `codespecs_mapping.md`
/// §5.13).
class CsTable {
  /// The physical table name, verbatim.
  ///
  /// **Required, first positional, and never derived**: a generator that
  /// slugified an entity name into a table name could rename a table under a
  /// running system. The Dart class name is the *domain* name; this is the
  /// storage fact.
  final String table;

  /// The configured datasource the table lives in.
  ///
  /// `null` means the deployment default.
  final String? datasource;

  /// The schema within [datasource].
  ///
  /// `null` means the deployment default.
  final String? schema;

  /// Optional part-specific note.
  final String? note;

  /// Declares the annotated entity as persisted in the CE-DB table [table].
  ///
  /// [table] is the sole positional argument, the physical table name verbatim,
  /// and is **never derived**: a generator that slugified an entity name into a
  /// table name could rename a table under a running system. The Dart class
  /// name is the *domain* name; this is the storage fact, and the two are
  /// allowed to differ.
  ///
  /// [datasource] and [schema] are `null` for the deployment default, which is
  /// the normal case; name them only where the table genuinely lives elsewhere.
  /// The pair is not decoration — together with [table] it is what a
  /// [CsMigration] declaration must target for the cumulative DDL to converge
  /// on this entity model, which `codespecs_derivation_contract.md` §6 check 13
  /// verifies against the migration artifacts themselves.
  const CsTable(this.table, {this.datasource, this.schema, this.note});
}

/// CE-DB — a **file-reference** column facet (`codespecs_mapping.md` §5.13).
///
/// A file-reference column stores a **storage key**, not a value: the cell holds
/// the address of a stored file and the file itself lives in a blob store. That
/// is the whole reason the facet exists — every other column kind is fully
/// described by its Dart type plus the storage attributes [CsColumn] already
/// carries, and needs no extra declaration.
///
/// It is a **facet of [CsColumn], not a second annotation**: a file reference is
/// one more kind of column, so it belongs in the column mechanism. Carrying it
/// as an optional nested value rather than as a `ColumnKind` enum keeps the
/// declaration where the extra attributes are — a kind tag with no payload would
/// force the four settings onto [CsColumn] itself, where they are meaningless
/// for every other column.
///
/// Built on `TomFileReference` (`tom_core_server`, `object_persistence`), whose
/// four settings this facet mirrors one-for-one; storage is `TomBlobStore` and
/// key generation `TomFileReferenceKeys`. Per `codespecs_mapping.md` §1.1
/// pillar (b) there is no CodeSpecs-local file-reference type — the substrate
/// class is the one that is built on. See
/// `tom_core_server/doc/file_storage.md`.
///
/// **Boundaries drawn.** Three attributes a file cell might seem to need are
/// deliberately *not* here:
///
/// - **Whether the file is downloadable** is the column's own authorization —
///   the key is an ordinary column, so `@TomDbScope` and the column's access key
///   already gate it, and `openFile` resolves through `findById`. A second flag
///   would be a duplicate rule that could disagree with the first.
/// - **Whether the cell renders a thumbnail or a link** is presentation, so it
///   is CE-EL. CE-DB is server-only (`codespecs_mapping.md` §4.2); a rendering
///   attribute declared here would be unreachable by the client that has to
///   honour it.
/// - **How a file is uploaded and served** is CE-API: `saveFile` / `openFile`
///   are called from an endpoint, which is also where [acceptedMediaTypes] is
///   enforced.
class CsFileReference {
  /// The retention partition the generated key is filed under.
  ///
  /// **Required**: keys are generated as
  /// `<keyPrefix>/<yyyy>/<mm>/<uuid-v4><.ext>` and never taken from the client,
  /// so the prefix is the only part of the address a specification chooses.
  /// There is no sensible default — a shared prefix would put unrelated
  /// retention classes in one partition.
  final String keyPrefix;

  /// Name of the configured blob store holding the file.
  ///
  /// Omitted means the deployment's default store, which is the normal case;
  /// naming one is how a column opts a specific retention class out of it.
  final String? store;

  /// Whether deleting the row also deletes the stored file.
  ///
  /// Defaults to `true` — the file belongs to the row. Set `false` only when the
  /// blob outlives its reference by design (a shared or externally owned asset).
  final bool cascadeDelete;

  /// Media type recorded when the upload supplies none.
  final String? defaultMediaType;

  /// The content kinds a specification permits for this column.
  ///
  /// Empty means unrestricted. This has no `TomFileReference` counterpart by
  /// design: the substrate stores whatever it is handed, and the restriction is
  /// enforced where the bytes arrive — at the CE-API upload endpoint.
  final List<String> acceptedMediaTypes;

  /// Optional facet-specific note.
  final String? note;

  /// Declares a CE-DB column as holding a **file reference** — a storage key
  /// addressing a file in a blob store — filed under [keyPrefix].
  ///
  /// [keyPrefix] is required with no default. Keys are generated as
  /// `<keyPrefix>/<yyyy>/<mm>/<uuid-v4><.ext>` and never taken from the client,
  /// so the prefix is the only part of the stored address a specification
  /// chooses; a shared one would file unrelated retention classes into a single
  /// partition, which is exactly what the prefix exists to keep apart.
  ///
  /// [store] names a configured blob store; omit it for the deployment's
  /// default, which is the normal case. [cascadeDelete] defaults to `true` —
  /// the file belongs to the row — and should be `false` only where the blob
  /// outlives its reference by design, as a shared or externally owned asset.
  /// Reversed, it either orphans blobs in the store or deletes an asset another
  /// row still points at.
  ///
  /// [defaultMediaType] is recorded when an upload supplies none.
  /// [acceptedMediaTypes] is empty for unrestricted and is the one field with
  /// **no `TomFileReference` counterpart** (`codespecs_derivation_contract.md`
  /// §5.3): the substrate stores whatever it is handed, so the restriction is
  /// enforced where the bytes arrive, at the CE-API upload endpoint. Declaring
  /// it here and not enforcing it there restricts nothing.
  ///
  /// This is a **value class, not an annotation**: it is passed as the
  /// [CsColumn.fileReference] argument, and its presence there *is* the column
  /// kind.
  const CsFileReference({
    required this.keyPrefix,
    this.store,
    this.cascadeDelete = true,
    this.defaultMediaType,
    this.acceptedMediaTypes = const [],
    this.note,
  });
}

/// CE-DB — a table column: a stored field of a [CsTable]
/// (`codespecs_mapping.md` §5.13).
class CsColumn {
  /// The physical column name, verbatim.
  ///
  /// `null` means "the same as the member name" — the common case, so a column
  /// name is authored only where storage and domain names genuinely differ.
  final String? column;

  /// The physical column type, verbatim.
  ///
  /// `null` means the datasource's default mapping for the member's Dart type.
  final String? columnType;

  /// The maximum stored length.
  ///
  /// `codespecs_mapping.md` §4.1.1 names maximum lengths as exactly the kind of
  /// thing simple code cannot express — the Dart type says `String`, not
  /// `String` of at most 80 characters.
  final int? length;

  /// The resource key gating field-level access to this column.
  ///
  /// A `codespecs_mapping.md` §5.15 resource-key requirement attached to a
  /// *field* rather than an operation, lowered to `TomDbColumn.authKey`.
  final CsResourceKeyRef? accessKey;

  /// Present when the column stores a file reference rather than a value.
  ///
  /// Its **presence is the column kind** (`codespecs_mapping.md` §5.13): a
  /// column with no [fileReference] is an ordinary stored attribute, described
  /// by its Dart type and the entity's storage annotations.
  final CsFileReference? fileReference;

  /// The sensitivity classification of the stored value
  /// (`codespecs_mapping.md` §5.13).
  ///
  /// ← the SOM's `DAATT-SECU.sensitivityLevel`, constant-for-constant. `null`
  /// means the specification authored no data-security subform for this
  /// attribute — never a claim that the value is public.
  final CsSensitivityLevel? sensitivityLevel;

  /// Whether the stored value is personal data (PII).
  ///
  /// ← the SOM's `DAATT-SECU.isPii`. Carried separately from
  /// [sensitivityLevel] because the SOM authors them separately — a column can
  /// be `confidential` without being personal, and a `pii`-classified column's
  /// flag is then redundantly `true` rather than inferred. `null` means the
  /// subform was not authored.
  final bool? isPii;

  /// Optional part-specific note.
  final String? note;

  /// The Dart **value type** is never an argument — it is the member's declared
  /// type. `read-only`, `not-loaded`, `json-encoded` and converters are the
  /// framework's own persistence annotations, carried beside this marker.
  const CsColumn({
    this.column,
    this.columnType,
    this.length,
    this.accessKey,
    this.fileReference,
    this.sensitivityLevel,
    this.isPii,
    this.note,
  });
}

/// CE-DB — a repository: the data-access surface over one or more [CsTable]s.
class CsRepository {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated class as a CE-DB repository — the data-access surface
  /// over one or more [CsTable]s.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): the surface is the
  /// class's own methods and the tables it reads are their signatures, so there
  /// is no attribute the marker could hold that the declaration does not
  /// already carry.
  ///
  /// The marker is emitted all the same, and not as decoration:
  /// `codespecs_derivation_contract.md` §2.7 point 4 requires a `Cs*` marker on
  /// every generated top-level declaration, and `codespecs_derivation_contract.md` §6 checks
  /// have to be able
  /// to *find* repositories — which a name suffix would turn into load-bearing
  /// convention.
  const CsRepository({this.note});
}

/// CE-AZ — the **graded** requirement facet: a three-slot requirement tree
/// (`codespecs_mapping.md` §5.15).
///
/// The graded arm is the only requirement kind reaching all four
/// `TomAuthState` values, so it is a *tree* rather than a scalar: each slot
/// carries the requirement a principal must satisfy to reach that access level.
///
/// Slots hold a whole [CsAuthorize] because `codespecs_mapping.md` §5.15
/// defines them as recursion into
/// the other requirement kinds — a role set for `full`, a resource key for
/// `read`, and so on. Reusing the annotation type rather than declaring a
/// parallel "requirement" value class is what keeps the two from drifting.
///
/// **What is deliberately absent.** The four states `none < disabled < read <
/// full` and the monotonic defaults `read ⇐ full`, `disabled ⇐ read` are
/// *derived*, which is why the three slots are nullable with no defaults: an
/// omitted slot inherits from the next-higher one, so the common case authors
/// only [full]. The level→render mapping (`none` hidden · `disabled`
/// visible-but-locked · `read` value-shown · `full` interactive) is
/// framework-fixed and not spec input.
class CsGradedAccess {
  /// What a principal must satisfy for interactive access.
  final CsAuthorize? full;

  /// What a principal must satisfy to see the value without changing it.
  ///
  /// `null` inherits from [full].
  final CsAuthorize? read;

  /// What a principal must satisfy to see the element locked.
  ///
  /// `null` inherits from [read].
  final CsAuthorize? disabled;

  /// Declares a CE-AZ **graded** requirement tree: what a principal must
  /// satisfy to reach each access level.
  ///
  /// All three slots are nullable with **no defaults**, and that is the
  /// mechanism rather than laxity. The four states `none < disabled < read <
  /// full` are ordered and the defaults are monotonic — [read] inherits from
  /// [full], [disabled] from [read] — so the common case authors [full] alone
  /// and the levels beneath it follow. Filling a lower slot is how you make it
  /// *stricter* than the inheritance would give.
  ///
  /// Each slot holds a whole [CsAuthorize] because `codespecs_mapping.md` §5.15
  /// defines the graded arm as recursion into the other requirement kinds: a
  /// role set for [full], a resource key for [read], and so on. Reusing the
  /// annotation type rather than declaring a parallel requirement class is what
  /// keeps the two from drifting. The recursion is exactly **one level deep** —
  /// a slot whose [CsAuthorize] is itself [CsAuthRequirement.graded] fails
  /// `codespecs_derivation_contract.md` §6 check 21.
  ///
  /// The level→render mapping (`none` hidden, `disabled` visible-but-locked,
  /// `read` value-shown, `full` interactive) is framework-fixed and not spec
  /// input. This is a **value class, not an annotation**: it is passed as
  /// [CsAuthorize.graded].
  const CsGradedAccess({this.full, this.read, this.disabled});
}

/// CE-AZ — an authorization rule: a **modifier** applied to the [CsEndpoint] it
/// gates (`codespecs_mapping.md` §5.6.3, §5.15).
///
/// **The head is [requirement]; everything after it is a per-kind slot.** As on
/// [CsTrigger], Dart annotations have no sum types, so each requirement kind's
/// payload is a separate optional argument and a validator asserts only the
/// declared kind's are non-null (`codespecs_derivation_contract.md` §6 check 8).
///
/// | [requirement] | Slots it may fill |
/// |---------------|-------------------|
/// | `role` | [roles] |
/// | `group` | [groups] |
/// | `entitlement` | [entitlements] |
/// | `resourceKey` | [resourceKey] |
/// | `custom` | [handler], [resourceId] |
/// | `graded` | [graded] |
/// | `none` · `public` · `authenticated` · `guest` | *none* |
///
/// Also used at **field level** — on a CE-DB column, a CE-EL/CE-FM field, a
/// CE-AC action or a CE-NV destination — where it rides its host part rather
/// than an endpoint (`codespecs_mapping.md` §5.15).
class CsAuthorize {
  /// What a caller must satisfy.
  ///
  /// **Required, and no arm is a default**: defaulting an authorization
  /// requirement is the exact failure `codespecs_mapping.md` §5.16's fail-safe
  /// rule exists to prevent.
  final CsAuthRequirement requirement;

  /// `role`: any one of these roles admits the caller.
  ///
  /// Typed consts from the shared role catalogue, lowered to
  /// `TomRoleAccess.roles` strings at generation.
  final List<CsRoleRef> roles;

  /// `group`: any one of these group names admits the caller.
  ///
  /// Strings, not refs — group names reference runtime principal data, not Dart
  /// declarations (`codespecs_mapping.md` §5.23).
  final List<String> groups;

  /// `entitlement`: entitlement match patterns.
  ///
  /// Strings for the same reason as [groups].
  final List<String> entitlements;

  /// `resourceKey`: the key the caller must hold a grant on.
  final CsResourceKeyRef? resourceKey;

  /// `custom`: the registered handler that decides.
  ///
  /// A string — it names a runtime handler registration, not a Dart
  /// declaration.
  final String? handler;

  /// `custom`: the resource the [handler] decides about.
  final String? resourceId;

  /// `graded`: the three-slot requirement tree.
  final CsGradedAccess? graded;

  /// Optional part-specific note.
  final String? note;

  /// Declares the annotated declaration as gated by [requirement], filling the
  /// slots that requirement kind admits.
  ///
  /// [requirement] draws from [CsAuthRequirement] (`vocabulary.dart`) and is
  /// required with **no default**, deliberately: defaulting an authorization
  /// requirement is the exact failure `codespecs_mapping.md` §5.16's fail-safe
  /// rule exists to prevent, so an unstated gate is a compile error rather than
  /// an open door.
  ///
  /// **Fill only the slots [requirement] admits** — Dart annotations have no
  /// sum types, so each kind's payload is a separate optional argument:
  ///
  /// - [CsAuthRequirement.role] → [roles]
  /// - [CsAuthRequirement.group] → [groups]
  /// - [CsAuthRequirement.entitlement] → [entitlements]
  /// - [CsAuthRequirement.resourceKey] → [resourceKey]
  /// - [CsAuthRequirement.custom] → [handler], [resourceId]
  /// - [CsAuthRequirement.graded] → [graded]
  /// - [CsAuthRequirement.none], [CsAuthRequirement.public],
  ///   [CsAuthRequirement.authenticated], [CsAuthRequirement.guest] → *no
  ///   slot*; the kind is the whole requirement.
  ///
  /// `codespecs_derivation_contract.md` §6 check 8 asserts only the declared
  /// kind's slots are non-null. It runs at generation time and not as a const
  /// `assert`, because Dart does not const-evaluate an annotation — a
  /// [CsAuthRequirement.role] requirement carrying a stray [resourceKey] passes
  /// `dart analyze` untouched, and the annotation is the only site this marker
  /// is ever written at.
  ///
  /// [roles] holds typed [CsRoleRef] consts and is therefore compiler-checked,
  /// while [groups], [entitlements] and [handler] are strings because they name
  /// runtime principal data and handler registrations rather than Dart
  /// declarations (`codespecs_mapping.md` §5.23). The three list slots default
  /// to empty, which is not a neutral value under a matching [requirement]: a
  /// [CsAuthRequirement.role] gate whose [roles] was left empty names no
  /// admissible role at all.
  ///
  /// The same annotation gates a **field** — a CE-DB column, a CE-EL or CE-FM
  /// field, a CE-AC action, a CE-NV destination — where it rides its host part
  /// instead of an endpoint (`codespecs_mapping.md` §5.15).
  const CsAuthorize({
    required this.requirement,
    this.roles = const [],
    this.groups = const [],
    this.entitlements = const [],
    this.resourceKey,
    this.handler,
    this.resourceId,
    this.graded,
    this.note,
  });
}

/// CE-CF — server configuration (per-server settings).
///
/// CE-CF is **server** configuration only — it never carries user or
/// client-machine settings. It is one of the four config/settings scopes
/// (`codespecs_mapping.md` §11), and the scope key alone decides where a value
/// lives: the other three — CE-CC (client app + machine), CE-DS (user +
/// device), CE-UP (user, server-persisted) — are client-side parts and are not
/// in this file.
class CsServerConfig {
  /// The setting key, verbatim.
  ///
  /// **Required, first positional** — an authored external identifier
  /// (`codespecs_derivation_contract.md` §2.1 N5) and one of the
  /// `codespecs_mapping.md` §5.23 string-reference exemptions: a setting key
  /// names a runtime lookup, not a Dart declaration.
  final String key;

  /// The environment variable this setting may also be read from, verbatim.
  final String? envAlias;

  /// The command-line option this setting may also be read from, verbatim.
  final String? cmdlineAlias;

  /// Whether the value is a secret — a certificate, private key or shared
  /// secret.
  ///
  /// The declaration states the setting's **presence and shape**; the content is
  /// supplied out of band by deployment tooling and is never written into a
  /// specification (`codespecs_mapping.md` §5.16). The marking is what lets
  /// `codespecs_mapping.md` §12 production-stripping and the deployment tooling
  /// find these settings mechanically instead of by naming convention.
  final bool secret;

  /// Which narrower scope, if any, may shadow this key.
  ///
  /// **Required** — the fail-safe rule that keeps `requirement` on
  /// `@CsAuthorize` undefaulted applies here for the same reason: a setting's
  /// blast radius chosen by omission is the failure the rule exists to prevent.
  /// Security and infrastructure settings take [CsOverridableBy.none].
  ///
  /// This is the *permission*, not the precedence: `codespecs_mapping.md` §5.16
  /// fixes the precedence order for every setting, so a per-setting ordering
  /// would be a second rule that could disagree with the first. The permission
  /// is authored only here, at the wider scope; the narrower scope's declaration
  /// of the same key does the shadowing without re-stating the permission.
  final CsOverridableBy overridableBy;

  /// Optional part-specific note.
  ///
  /// The setting's **type** is the member's declared type and its **default**
  /// the member initialiser, so neither is an argument.
  final String? note;

  /// Declares the annotated member as the CE-CF server-configuration setting
  /// [key], shadowable no more widely than [overridableBy] permits.
  ///
  /// [key] is the first positional argument, verbatim. A setting key is an
  /// authored key (`codespecs_derivation_contract.md` §2.1 N5) and one of
  /// `codespecs_mapping.md` §5.23's string-reference exemptions, because it
  /// names a runtime lookup rather than a Dart declaration — so the compiler
  /// cannot catch a duplicate and `codespecs_derivation_contract.md` §6 check
  /// 20 does, over the one namespace that authored and derived keys share
  /// (`codespecs_derivation_contract.md` §2.1 N10).
  ///
  /// [overridableBy] draws from [CsOverridableBy] (`vocabulary.dart`) and is
  /// required with no default, per `codespecs_mapping.md` §5.16's fail-safe
  /// rule. CE-CF is the widest scope in `CE-DS ▸ CE-UP ▸ CE-CC ▸ CE-CF`, so
  /// every arm is admissible here (`codespecs_derivation_contract.md` §6 check
  /// 15) — which makes [CsOverridableBy.none], the value every security and
  /// infrastructure setting keeps, a choice rather than a formality. This
  /// argument is the *permission*, never the precedence: `codespecs_mapping.md`
  /// §5.16 fixes the precedence order for every setting, so a per-setting
  /// ordering would be a second rule that could disagree with the first.
  ///
  /// [secret] marks a certificate, private key or shared secret; it defaults to
  /// `false`, and setting it is what lets `codespecs_mapping.md` §12
  /// production-stripping and the deployment tooling find these settings
  /// mechanically instead of by naming convention. It carries two obligations
  /// the validator enforces: the member must have **no initialiser**, since a
  /// default would be a credential committed to the source tree
  /// (`codespecs_derivation_contract.md` §6 check 16), and [key] must match a
  /// declared `SCSET` entry in the run's extracts — a key no entry declares
  /// means a credential slot was invented in a policy section (check 19).
  ///
  /// [envAlias] and [cmdlineAlias] name the environment variable and
  /// command-line option the value may also be read from, verbatim. The
  /// setting's **type is the member's declared type and its default the member
  /// initialiser**, so neither is an argument.
  const CsServerConfig(
    this.key, {
    required this.overridableBy,
    this.envAlias,
    this.cmdlineAlias,
    this.secret = false,
    this.note,
  });
}

/// CE-MG — a schema-migration artifact set (`codespecs_mapping.md` §5.27).
///
/// Marks the *spec-side* declaration of an application's migration artifacts.
/// The artifacts themselves are numbered **SQL files**, not Dart classes: they
/// live under `<databaseMigrationsDirectory>/<datasource>/<schema>/`, are named
/// `[<version>]-<description>[@<env>…].<ext>`, and apply in ascending version
/// order. A CodeSpec authors three artifact kinds — the initial DDL, the new
/// system's base/seed reference data, and the append-only iteration scripts.
/// Business-data migration from a legacy system is explicitly *not* CE-MG.
///
/// Pure reuse of the `tom_core_server` migration engine (`TomDbMigrations` /
/// `TomDbMigrator` / `TomMigrationFileName` / `@TomDbMigrationAdaptor` /
/// `MariadbMigrationAdaptor`) — no gap class. Applied artifacts are immutable;
/// schema change is always a new numbered artifact. The cumulative DDL must
/// converge on the shape the [CsTable] / [CsColumn] entity model declares — a
/// named CodeSpecs validator check, since artifact filenames are one of the
/// `codespecs_mapping.md` §5.23 string-reference exemptions.
class CsMigration {
  /// The datasource whose schema the artifacts migrate.
  ///
  /// **Required** — with [schema] it *is* the artifact directory path, and
  /// defaulting it would silently retarget a database.
  final String datasource;

  /// The schema within [datasource].
  ///
  /// **Required**, for the same reason as [datasource].
  final String schema;

  /// Which of the three artifact kinds this declaration ships.
  ///
  /// **Required, with no default**: generating an initial DDL where an iteration
  /// was meant would rewrite a live schema.
  final CsMigrationKind kind;

  /// Optional part-specific note.
  ///
  /// Artifact **filenames** are not arguments — they are file-system facts and
  /// one of the four `codespecs_mapping.md` §5.23 string-reference exemptions.
  /// That exemption is also why the convergence obligation (cumulative DDL vs.
  /// the [CsTable] / [CsColumn] model) is a named generation-time validator
  /// check rather than a compile-time edge.
  final String? note;

  /// Declares the annotated declaration as the CE-MG artifact set of [kind] for
  /// [datasource] / [schema].
  ///
  /// [datasource] and [schema] are both required because together they *are*
  /// the artifact directory —
  /// `<databaseMigrationsDirectory>/<datasource>/<schema>/` — so a default
  /// would silently retarget a database. They must name the same pair the
  /// [CsTable] declarations they migrate name.
  ///
  /// [kind] draws from [CsMigrationKind] (`vocabulary.dart`) and is required
  /// with no default, which is the argument in this package with the most
  /// direct consequence: emitting [CsMigrationKind.initialDdl] where
  /// [CsMigrationKind.iteration] was meant rewrites a live schema. Use
  /// [CsMigrationKind.baseData] for the new system's seed reference data —
  /// business-data migration from a legacy system is explicitly not CE-MG.
  ///
  /// Artifact **filenames** are not arguments: they are file-system facts and
  /// one of `codespecs_mapping.md` §5.23's string-reference exemptions. That
  /// exemption is also why the obligation that the cumulative DDL converge on
  /// the [CsTable] / [CsColumn] model is a generation-time check
  /// (`codespecs_derivation_contract.md` §6 check 13) rather than a
  /// compile-time edge — and why applied artifacts are immutable, schema change
  /// always being a new numbered artifact rather than an edit to an old one.
  const CsMigration({
    required this.datasource,
    required this.schema,
    required this.kind,
    this.note,
  });
}

/// CE-JB — a background-job definition (`codespecs_mapping.md` §5.29).
///
/// Work that runs *off* the request thread — the axis that separates CE-JB from
/// the request-driven [CsEndpoint]. Server-only (`codespecs_mapping.md` §4.2).
/// One definition names:
///
/// 1. a **trigger** — cron, calendar date/time, or a named system event;
/// 2. a **work definition** — compilable pseudo-code over a later-injected
///    abstract service class (the `codespecs_mapping.md` §3
///    first-level-implementation latitude), run on the `tom_core_kernel`
///    isolate-pooling substrate (`TomCommand` dispatched through `TomExecutor`
///    / `TomWorker`);
/// 3. **target references** — the entities and reports the job acts on, held as
///    typed const refs and `Type` literals, never strings. The two kinds sit in
///    different places: reports here as [targetReports], entities on
///    `TomJobDeclaration.readEntities` / `.writtenEntities` — see
///    [targetReports] for why;
/// 4. **retry / backoff / timeout / failure-alerting** policy.
///
/// Scheduler runtime, job store and multi-node locking are all present in the
/// `tom_core_kernel` scheduling substrate (`TomScheduler`, `TomJobStore`,
/// `TomLeaseLock`), so a declared trigger is a wired schedule. The single
/// residual gap is the declaration envelope — `enabled`, deployment
/// environments, owning service unit and entity targets — which is the
/// `tom_core_codespecs` gap class `TomJobDeclaration`.
///
/// **The head is [trigger]; the three schedule slots are per-kind.** As on
/// [CsAuthorize] and `CsTrigger`, Dart annotations have no sum types, so each
/// trigger kind's payload is a separate optional argument and a validator
/// asserts only the declared kind's is non-null
/// (`codespecs_derivation_contract.md` §6 check 8).
///
/// | [trigger] | Slot it may fill |
/// |-----------|------------------|
/// | `cron` | [cron] |
/// | `calendar` | [calendar] |
/// | `event` | [event] |
class CsJob {
  /// What starts the job.
  ///
  /// **Required** — a job with no declared trigger is a job that never runs.
  /// Each arm lowers onto the matching `tom_core_kernel` schedule
  /// (`TomCronSchedule` / `TomCalendarSchedule` / `TomEventSchedule`) on
  /// `TomJobDefinition.schedule`: the trigger is a **wired** schedule, not a
  /// name.
  final CsJobTrigger trigger;

  /// `cron`: the cron expression, verbatim.
  final String? cron;

  /// `calendar`: the calendar date/time rule, verbatim.
  final String? calendar;

  /// `event`: the system event name, verbatim.
  final String? event;

  /// How many times a failed run is retried.
  ///
  /// Defaults to `0` — a job retries only when the specification says so.
  /// Lowered onto `TomRetryPolicy`.
  final int maxRetries;

  /// The delay before the first retry.
  ///
  /// `null` means the substrate's own default. Lowered onto `TomRetryPolicy`.
  final Duration? backoff;

  /// How long a single run may take before it is abandoned.
  ///
  /// `null` means unbounded. Lowered onto `TomJobDefinition.timeout`.
  final Duration? timeout;

  /// The message raised to the deployment's alert sink when the job fails.
  ///
  /// A CE-TX message key, never inline text — carried by `TomJobAlert` to
  /// `TomScheduler.onAlert`.
  final CsMessageKey? failureAlert;

  /// The CE-RP reports this job produces, where the work is a report run.
  ///
  /// Half of `codespecs_mapping.md` §5.29 scope part 3; the other half — the
  /// CE-DB entities the job reads and writes — rides
  /// `TomJobDeclaration.readEntities` / `.writtenEntities` as `Type` literals,
  /// since entities are already Dart types and `codespecs_mapping.md` §5.23
  /// gives them no ref const by design.
  ///
  /// **Reports are cited here rather than on the declaration** because
  /// `codespecs_mapping.md` §5.23
  /// places the `Cs*Ref` family in the annotation *parameter* vocabulary, which
  /// is exactly where [failureAlert]'s [CsMessageKey] already sits. Putting a
  /// ref const on a `tom_core`-family class instead would make it the outlier —
  /// those classes hold plain ids (`TomReportDefinition.reportId` is the string
  /// a [CsReportRef] *wraps*) — and would cost `tom_core_codespecs` the
  /// dependency-freedom it treats as a design property.
  ///
  /// Empty means the job produces no report, which is the common case.
  final List<CsReportRef> targetReports;

  /// Optional part-specific note.
  ///
  /// `enabled`, `environments`, `serviceUnitId` and the entity targets ride
  /// `TomJobDeclaration`'s own constructor, so none of them is an argument here.
  final String? note;

  /// Declares the annotated declaration as a CE-JB background job started by
  /// [trigger].
  ///
  /// [trigger] draws from [CsJobTrigger] (`vocabulary.dart`) and is required —
  /// a job with no declared trigger is a job that never runs. Each arm lowers
  /// onto the matching `tom_core_kernel` schedule (`TomCronSchedule` /
  /// `TomCalendarSchedule` / `TomEventSchedule`) on
  /// `TomJobDefinition.schedule`, so a declared trigger is a **wired** schedule
  /// and not a name.
  ///
  /// **Fill only the schedule slot [trigger] admits** — [CsJobTrigger.cron] →
  /// [cron], [CsJobTrigger.calendar] → [calendar], [CsJobTrigger.event] →
  /// [event], each verbatim from the specification.
  /// `codespecs_derivation_contract.md` §6 check 8 asserts the other two are
  /// null, at generation time rather than as a const `assert`, because Dart
  /// does not const-evaluate an annotation.
  ///
  /// [maxRetries] defaults to `0` — a job retries only where the specification
  /// says so — and lowers onto `TomRetryPolicy` together with [backoff], whose
  /// `null` takes the substrate's own default. [timeout] is `null` for
  /// unbounded, which for work on a shared isolate pool is a decision rather
  /// than an absence.
  ///
  /// [failureAlert] is a [CsMessageKey] and never inline text: it is the copy
  /// `TomJobAlert` raises to `TomScheduler.onAlert` and the deployment's alert
  /// sink.
  ///
  /// [targetReports] holds [CsReportRef] consts and is empty for the common
  /// case. It is half of `codespecs_mapping.md` §5.29's target set; the other
  /// half — the CE-DB entities the job reads and writes — rides
  /// `TomJobDeclaration.readEntities` / `.writtenEntities` as `Type` literals,
  /// since entities are already Dart types and `codespecs_mapping.md` §5.23
  /// gives them no ref const by design.
  ///
  /// `enabled`, `environments` and `serviceUnitId` are `TomJobDeclaration`'s
  /// own constructor parameters, so none of them is an argument here.
  const CsJob({
    required this.trigger,
    this.cron,
    this.calendar,
    this.event,
    this.maxRetries = 0,
    this.backoff,
    this.timeout,
    this.failureAlert,
    this.targetReports = const <CsReportRef>[],
    this.note,
  });
}

/// CE-LG — an audited element: an entity or endpoint whose access is recorded
/// in the audit trail (`codespecs_mapping.md` §4.3).
///
/// Pure reuse of `tom_core_server`'s `audit` module — no gap class. The trail
/// records **automatically** at two chokepoints no handler can opt out of
/// (`TomEndpointHandler.handleMethodCall` and `TomSqlDatasourceRepository`'s
/// write path), so what a specification authors is the *declared* half only:
/// which endpoint invocations are auditable, whether the type is audited at
/// all, and which fields must never appear in a record. Those decisions are
/// exactly `@TomAudited(enabled:, redact:)`, which the CodeSpec carries
/// alongside this marker — the same shape CE-SU uses, where the CodeSpec is an
/// ordinary class carrying the framework's own `@tomService` and [CsServiceUnit]
/// marks it as the part.
///
/// Retention, log format and the compliance report are **not** CE-LG: they are
/// deployment settings on the sink, and belong to [CsServerConfig].
class CsAudited {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated entity or endpoint as CE-LG audited.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2), and unusually so: the
  /// trail records **automatically**, at two chokepoints no handler can opt out
  /// of (`TomEndpointHandler.handleMethodCall` and
  /// `TomSqlDatasourceRepository`'s write path), so there is no "switch it on"
  /// argument for the marker to carry.
  ///
  /// The *declared* half — whether the type is audited at all, and which fields
  /// must never appear in a record — is `@TomAudited(enabled:, redact:)`, which
  /// the CodeSpec carries **beside** this marker, the same shape CE-SU uses
  /// with `@tomService`. Omitting a field from `redact:` is what puts its value
  /// into the trail, so the redaction list is where a mistake here actually
  /// costs something.
  ///
  /// Retention, log format and the compliance report are **not** CE-LG: they
  /// are deployment settings on the sink and belong to [CsServerConfig].
  const CsAudited({this.note});
}

/// CE-NT — a notification type: an outbound communication a system event emits
/// (`codespecs_mapping.md` §4.3).
///
/// Built on `TomNotificationType` (`tom_core_codespecs`) for the declaration and
/// `TomMessage` / `TomMessageRouter` / `TomMessageOutbox` (`tom_core_server`
/// `messaging`) for delivery. The transport is pure reuse; the gap it leaves —
/// which types exist, which channels each goes out on, and how a user's
/// preferences narrow that set — is what this marker names.
///
/// The declaration is **shared** (the client renders the preference UI against
/// the same catalogue the server dispatches from); delivery is server-only.
/// The body copy is a `CsText` message key, never inline text.
class CsNotification {
  /// The body copy, as a CE-TX message key.
  ///
  /// **Required** — a notification with no body is not a notification — and a
  /// key rather than inline text, so the copy stays translatable and stays in
  /// one catalogue.
  final CsMessageKey body;

  /// Optional part-specific note.
  ///
  /// Type id, urgency and default channels are `TomNotificationType`'s own
  /// constructor parameters, and the preference narrowing rides
  /// `TomNotificationPreferences` / `TomNotificationCatalog`; none is an
  /// argument here. Channels are cited by `channelId` **string**, per
  /// [CsNotificationChannel].
  final String? note;

  /// Declares the annotated declaration as a CE-NT notification type whose body
  /// copy is [body].
  ///
  /// [body] is a required [CsMessageKey] — a notification with no body is not a
  /// notification — and a key rather than inline text, so the copy stays
  /// translatable and stays in the one CE-TX catalogue.
  ///
  /// Everything else the type configures is `TomNotificationType`'s own
  /// constructor: type id, urgency and default channels. Preference narrowing
  /// rides `TomNotificationPreferences` / `TomNotificationCatalog`, so a user's
  /// opt-out is runtime data and not spec input.
  ///
  /// Channels are cited by `channelId` **string** rather than by a ref const —
  /// see [CsNotificationChannel] for why there is no `CsChannelRef` to use.
  const CsNotification({required this.body, this.note});
}

/// CE-NT — a notification channel: a declared delivery route
/// (`codespecs_mapping.md` §4.3).
///
/// Built on `TomNotificationChannelDeclaration` (`tom_core_codespecs`), whose
/// `channelId` is the name of a `TomMessageChannel` — an **open** named value,
/// so a deployment can declare a channel the framework never anticipated.
///
/// Separate from [CsNotification] because the two are authored independently:
/// the channel catalogue is a property of the deployment, the type catalogue a
/// property of the domain, and a type references channels by id rather than
/// containing them.
class CsNotificationChannel {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated declaration as a CE-NT delivery channel.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): the declaration is
  /// `TomNotificationChannelDeclaration`, whose `channelId` names a
  /// `TomMessageChannel` — an **open** named value, so a deployment may declare
  /// a channel the framework never anticipated. An open name has no Dart
  /// declaration to resolve against, which is why the `Cs*Ref` family has no
  /// `CsChannelRef` and channels are cited by string.
  ///
  /// One channel edge is still checked: every
  /// `TomNotificationChannelDeclaration.fallbackChannelId` must name a channel
  /// declared in the **same** catalogue (`codespecs_derivation_contract.md` §6
  /// check 17). That is a *sibling* reference — a local coordinate rather than
  /// a cross-part edge — which is exactly why it is a validator check and not a
  /// typed const.
  ///
  /// Kept separate from [CsNotification] because the two are authored
  /// independently: the channel catalogue is a property of the deployment, the
  /// type catalogue a property of the domain.
  const CsNotificationChannel({this.note});
}

/// CE-RP — a report: a grouped projection over the domain model, delivered as
/// a rendered artifact (`codespecs_mapping.md` §5.28).
///
/// Built on `TomReportDefinition` (`tom_core_codespecs`) for the definition and
/// `TomReportResult` for the **shared** result envelope. Query execution
/// (`TomGroupedSelect`, `TomAggregate`) and rendering (`TomTabularResult` and
/// its CSV / XLSX / PDF renderers) are pure `tom_core_server` reuse; the gap
/// they leave — the **grouped projection** a specification authors, dimension
/// by dimension and measure by measure — is what this marker names.
///
/// CE-RP is a part and not a composition of [CsEndpoint] + [CsTable] +
/// `CsForm`: none of those can hold a dimension or a measure, and a report
/// column is an *output projection* carrying an aggregate and a format, not an
/// input field.
///
/// The definition is **server-only** (that is where the report runs); the
/// result envelope and the parameter shape are **shared**. Every label is a
/// `CsText` message key, never inline text.
///
/// **Note-only, and its cross-part edges are carried elsewhere.**
/// `codespecs_mapping.md` §5.28's
/// attribute surface maps onto `TomReportDefinition`'s constructor, so nothing
/// is left for an argument to hold — including the outbound references:
///
/// - the **source entity** is a `Type` literal on the definition, since an
///   entity is already a Dart type and `codespecs_mapping.md` §5.23 gives it no
///   ref const;
/// - the **schedule** is a recurrence expression on the definition, not a job
///   reference — `codespecs_mapping.md` §5.29 realises the CE-JB job *from* it;
/// - **authorization** rides a [CsAuthorize] **beside this marker**, per
///   `codespecs_mapping.md` §5.15's
///   field-level rule: the report's access level and permitted roles are
///   exactly that annotation's requirement kind and its typed `CsRoleRef` list;
/// - the **drill-through** target is an open route id string on the column, the
///   one edge `codespecs_mapping.md` §5.23's locus rule permanently denies a
///   typed ref.
class CsReport {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated declaration as a CE-RP report definition.
  ///
  /// Note-only, and the clearest case in the contract
  /// (`codespecs_derivation_contract.md` §5.2): `codespecs_mapping.md` §5.28's
  /// 22-row attribute surface is large, and *all* of it landed on
  /// `TomReportDefinition` and its dimension and measure members, leaving the
  /// marker nothing to hold.
  ///
  /// Its cross-part edges are carried elsewhere too, each for a stated reason.
  /// The **source entity** is a `Type` literal on the definition, since an
  /// entity is already a Dart type. The **schedule** is a recurrence expression
  /// on the definition rather than a job reference — `codespecs_mapping.md`
  /// §5.29 realises the CE-JB job *from* it. **Authorization** is a
  /// [CsAuthorize] written beside this marker, per `codespecs_mapping.md`
  /// §5.15's field-level rule: the report's access level and permitted roles
  /// are exactly that annotation's requirement kind and its typed [CsRoleRef]
  /// list. The **drill-through** target is an open route id string on the
  /// column, the one edge `codespecs_mapping.md` §5.23's locus rule permanently
  /// denies a typed ref, replaced by `codespecs_derivation_contract.md` §6
  /// check 18.
  ///
  /// The definition is server-only; the result envelope and the parameter shape
  /// are shared. Every label is a [CsMessageKey], never inline text.
  const CsReport({this.note});
}

/// CE-RP — one projected output column of a [CsReport] (`codespecs_mapping.md`
/// §5.28).
///
/// Built on `TomReportColumn`. A column **displays** a declared dimension or
/// measure — it never introduces data of its own, which is why it names a
/// source key rather than an entity column: the grouped projection decides what
/// exists, the column decides how it appears.
///
/// Separate from [CsColumn] (CE-DB), which is a stored attribute of an entity.
/// The two are authored at different levels: a persisted column is part of the
/// data model, a report column part of one report's output.
///
/// Its **drill-through** target stays an open route id string on
/// `TomReportColumn` rather than becoming a [CsRouteRef]:
/// `codespecs_mapping.md` §5.23's locus rule
/// bars a server-owned definition from citing a client-owned route. That is a
/// lost compile-time edge rather than an absent one, so
/// `codespecs_derivation_contract.md` §6 check 18 replaces it.
class CsReportColumn {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated member as one projected output column of a [CsReport].
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): `TomReportColumn`
  /// carries the source key, the aggregate and the format.
  ///
  /// A column **displays** a declared dimension or measure and never introduces
  /// data of its own, which is why it names a source key rather than an entity
  /// column: the grouped projection decides what exists, the column decides how
  /// it appears. Do not reach for [CsColumn] here — that is a stored attribute
  /// of an entity, authored at a different level and in a different project.
  ///
  /// Its drill-through target stays an open route id string on
  /// `TomReportColumn` rather than becoming a [CsRouteRef]:
  /// `codespecs_mapping.md` §5.23's locus rule bars a server-owned definition
  /// from citing a client-owned route. That is a lost compile-time edge rather
  /// than an absent one, so `codespecs_derivation_contract.md` §6 check 18
  /// resolves it instead.
  const CsReportColumn({this.note});
}

/// CE-RP — a chart declared over a [CsReport]'s projected columns
/// (`codespecs_mapping.md` §5.28).
///
/// Built on `TomReportChart`. **Declared here, rendered by whoever can:** the
/// declaration is authored input (the SOM carries chart type, series and axes
/// as structured fields), while rendering is implementation-owned — a client
/// draws charts natively, and an export format that cannot express one omits it
/// rather than failing.
///
/// A chart plots columns the report already projects, so it adds a view over
/// the projection and never a second query.
class CsReportChart {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated declaration as a chart over a [CsReport]'s projected
  /// columns.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): chart type, series
  /// and axes are structured fields the SOM carries onto `TomReportChart`.
  ///
  /// **Declared here, rendered by whoever can.** The declaration is authored
  /// input; rendering is implementation-owned, so a client draws charts
  /// natively and an export format that cannot express one omits it rather than
  /// failing the run. A chart plots columns the report already projects, so it
  /// adds a view over the projection and never a second query — a chart naming
  /// a column the projection does not produce has nothing to plot.
  const CsReportChart({this.note});
}

/// CE-RP — a runtime input a [CsReport] takes when it is run
/// (`codespecs_mapping.md` §5.28).
///
/// Built on `TomReportParameter`. Distinct from a CE-DB row filter authored
/// into the query: a parameter is **supplied per execution**, so it is part of
/// the report's request shape and carries a type, a bound and a presentation.
///
/// Distinct from a `CsForm` field (CE-FM) for the same reason a report column
/// is: a form field belongs to a form the user submits, a report parameter to
/// the report's own request contract.
class CsReportParameter {
  /// Optional part-specific note.
  final String? note;

  /// Marks the annotated member as a runtime input a [CsReport] takes when it
  /// is run.
  ///
  /// Note-only (`codespecs_derivation_contract.md` §5.2): type, bound and
  /// presentation are `TomReportParameter`'s own surface.
  ///
  /// A parameter is **supplied per execution**, which is what separates it from
  /// a row filter authored into the query, and what puts it in the report's
  /// *shared* request shape rather than in the server-only definition
  /// (`codespecs_derivation_contract.md` §3.2.10). It is not a [CsForm] field
  /// either, for the same reason a report column is not a [CsColumn]: a form
  /// field belongs to a form the user submits, a report parameter to the
  /// report's own request contract.
  const CsReportParameter({this.note});
}
