/// D13 — CodeSpecs Generation Projection.
///
/// The Phase-4 CodeSpecs generation input: an `@Document` projection —
/// analogous to the D01–D12 Phase-3 projections — that reaches the isolated
/// CodeSpecs subtrees carved out by the Band-F follow-up splits (csmc1..csmc5)
/// and the earlier TOM/IFM splits. Where D01–D12 are the *document* projections
/// over the Solution Blueprint, D13 is the *code* projection: the concrete set
/// of SBP sections the Phase-4 generator consumes to emit skeletal
/// `Cs*`-annotated Dart.
///
/// **Membership follows the part, not the parent.** An entry is here because
/// the subtree it names is purely `@CodeSpecKind`-bearing — not because of
/// where the follow-up splits happened to cut. Two entries below
/// (`sensitiveDataEncryption`, `printAndExportLayout`) therefore reach *into* a
/// `@FollowUpKind` root to pick a pure CE-CF band out of it, leaving its
/// genuinely process-delivered siblings behind. That is not a weakening of the
/// §8.3 split: the split's own rule is that a subtree mixing generated and
/// non-generated content is a split point, and reaching past the root is how
/// this projection expresses the split where the root was cut one level too
/// high.
///
/// **`@CodeSpecKind`-driven, not `@DetailedIn`-driven.** No SBP section carries
/// `@DetailedIn(D13CodeSpecsProjection)` — the single-valued `@DetailedIn` /
/// `@MapsTo` pair on each subtree root is already spent on the Phase-3 document
/// that shaped it. The projection instead references the CodeSpecs-relevant
/// subtree roots directly; the `@CodeSpecsProjection()` marker exempts it from
/// the detail-count check (`tom_specs_model_rules.md` §10.2, invariant
/// `DETAIL-PRESENT`). It
/// still satisfies the pure-projection invariant: every type it reaches also
/// lives in the D00SolutionBlueprint tree — it owns no content of its own.
///
/// **Flat by construction.** The pure-projection invariant forbids any reached
/// type without a D00 counterpart, so the projection can introduce no
/// shared/client/server *container* classes of its own. The
/// `codespecs_mapping.md` §4.2 three-way split is therefore expressed by
/// **locus grouping** — the fields are ordered into shared → server → client
/// bands and each carries a `@Comment('locus: …')` naming its target project
/// (`<app>_codespec_shared` / `_client` / `_server`) and the CE-part(s) that
/// route there per the `codespecs_mapping.md` §4 Locus column. The Phase-4
/// generator that *consumes* this projection and performs the physical routing
/// is a later wave (out of scope for the projection definition itself).
///
/// **RSP requirements seed is intentionally excluded.** The RSP `Requirements`
/// subtree is consumed by CodeSpecs as *requirements* (a generation seed /
/// acceptance source), not emitted as generated code, so it is not part of the
/// generation projection (`codespecs_mapping.md` §8.3).
///
library;

import 'package:tom_specs_core/tom_specs_core.dart';

import '../common/document_header.dart';
import '../solution_blueprint/solution_blueprint.dart';

/// CGP00 CodeSpecs Generation Projection.
///
/// The residual `@CodeSpecKind`-tagged content after the Band-F follow-up
/// splits: the shared registries, the server-side data / framework / access
/// models, the process-step interactions, and the client-side experience seed.
@StandardReferences(
  [
    'ISO/IEC/IEEE 42010 — architecture description (the generation input '
        'as an architecture view over the blueprint)',
    'Model-driven engineering — platform-independent model → code generation',
  ],
  'The Phase-4 CodeSpecs generation input: the isolated CodeSpecs subtrees '
  'routed across the shared / client / server three-way split by locus.',
)
@Document(
  name: 'CodeSpecs Generation Projection',
  description: 'The Phase-4 CodeSpecs generation input — a projection over the '
      'Solution Blueprint that reaches only the isolated CodeSpecs subtrees, '
      'grouped by the shared/client/server locus of their CE-parts.',
  basedOn: [D00SolutionBlueprint],
)
@CodeSpecsProjection()
@SectionId('CGP')
class D13CodeSpecsProjection extends DocSpecsSection {
  @ContentHelp('Executive overview of the CodeSpecs generation input: which '
      'blueprint subtrees feed generation and how they route across the '
      'shared/client/server split.')
  @override
  @SerializationOrder(0)
  String? content;

  /// Standard TomSpecs document header.
  @SerializationOrder(1)
  DocumentHeader header = DocumentHeader();

  // ─── Locus: SHARED (<app>_codespec_shared) ───────────────────────────────

  /// Domain enum registry — the closed value sets, shared by client & server.
  ///
  /// `domainEnum` is a **member kind, not a part** (`codespecs_mapping.md`
  /// §4.1): each enum is authored once here and realised as a plain Dart `enum`
  /// marked `@CsEnum`, placed in the shared project iff a shared contract type
  /// references it — which is what this registry's shared locus assumes —
  /// otherwise in the project of the part that introduces it.
  @Comment('locus: shared — domainEnum (member kind)')
  @SerializationOrder(2)
  DomainEnumRegistry domainEnumRegistry = DomainEnumRegistry();

  /// Error code registry — CE-ER shared error-code vocabulary.
  @Comment('locus: shared — CE-ER')
  @SerializationOrder(3)
  ErrorCodeRegistry errorCodeRegistry = ErrorCodeRegistry();

  /// Result envelope — the canonical CE-ER `codespecs_mapping.md` §7 contract.
  ///
  /// The shared success-or-error envelope: success payload **or** structured
  /// error (code, message, field-level details).
  @Comment('locus: shared — CE-ER')
  @SerializationOrder(4)
  ResultEnvelope resultEnvelope = ResultEnvelope();

  /// Message key registry — CE-TX author-copy-once keys, shared.
  @Comment('locus: shared — CE-TX')
  @SerializationOrder(5)
  MessageKeyRegistry messageKeyRegistry = MessageKeyRegistry();

  /// Notification model — CE-NT type / channel / preference declarations.
  ///
  /// The declarations are **shared**: the client renders the preference UI
  /// against the same catalogue the server dispatches from. Delivery is
  /// server-only, but it is not authored here — it rides the reused
  /// `tom_core_server` messaging transport.
  @Comment('locus: shared — CE-NT')
  @SerializationOrder(6)
  NotificationModel notificationModel = NotificationModel();

  // ─── Locus: SERVER (<app>_codespec_server) ───────────────────────────────

  /// Data model — CE-DB persistence + CE-VA server-side rules.
  @Comment('locus: server — CE-DB/CE-VA')
  @SerializationOrder(7)
  DataModel dataModel = DataModel();

  /// Technical framework — the platform foundation and **all four settings
  /// scopes**.
  ///
  /// The subtree spans both loci because the four configuration scopes are
  /// authored under it and route apart (`codespecs_mapping.md` §11): CE-CF
  /// server configuration (`SystemConfigurationManagement`) is server-only,
  /// while CE-CC client configuration, CE-DS device settings and CE-UP user
  /// settings are authored under the client-requirements subtree and route to
  /// the client project. CE-UP additionally has a server-side persistence half
  /// generated from the *same* declarations, so it appears in both projects —
  /// the scope is expressed by which section a setting is declared in, never by
  /// a discriminator field.
  @Comment('locus: server(CE-CF)+client(CE-CC/CE-DS/CE-UP)')
  @SerializationOrder(8)
  TechnicalFrameworkConcept technicalFramework = TechnicalFrameworkConcept();

  /// Access control model — CE-AZ authorization/identity seed.
  @Comment('locus: server — CE-AZ')
  @SerializationOrder(9)
  AccessControlModel accessControl = AccessControlModel();

  /// Audit and logging — CE-LG audit declarations + CE-CF log-sink settings.
  ///
  /// Both bands are server-side and both are authored input: CE-LG declares
  /// *what* is auditable (`SecurityEventsDefinition`, realised as `@CsAudited`
  /// beside the framework's `@TomAudited`), CE-CF configures the sink that
  /// receives it (`AuditLogFormat`, realised as `@CsServerConfig`). The
  /// operational half — the review, reporting and anomaly-detection routines
  /// run against the log — is `ComplianceReporting` under
  /// `SecurityOperationsFollowUp`, and is deliberately unreachable from here.
  @Comment('locus: server — CE-LG/CE-CF')
  @SerializationOrder(10)
  AuditAndLogging auditAndLogging = AuditAndLogging();

  /// Sensitive-data encryption and key management — CE-CF cryptographic
  /// settings.
  ///
  /// Reached **into** `SecurityOperationsFollowUp` rather than through it: that
  /// root is tagged OPS for `ComplianceReporting`, and this sibling was swept
  /// along by the split rather than placed there on a criterion. It is a pure
  /// CE-CF band — encryption at rest (database / file-storage / backup
  /// policies and the encrypted-data category list), encryption in transit
  /// (TLS protocol, certificate management, mTLS, transport policy and the
  /// per-channel entries) and the key lifecycle under `KeyManagement`
  /// (generation, storage, rotation, escrow-and-backup, compromise recovery).
  ///
  /// It belongs here because §5.5's own substrate names its material:
  /// `TomBaseServerConfiguration` declares TLS material and signing keys as
  /// typed fields, so a TLS minimum version is a server-configuration value in
  /// exactly the sense `@CsServerConfig` generates. Its projected siblings
  /// settle it — `StorageEncryptionPolicy` under `AccessControlModel` and
  /// `LogRetentionPolicy` under `AuditAndLogging` are fixed-key policy bands of
  /// the same shape, and no criterion separates them from these.
  @Comment('locus: server — CE-CF')
  @SerializationOrder(11)
  SensitiveDataEncryption sensitiveDataEncryption = SensitiveDataEncryption();

  /// Report definitions — CE-RP grouped projections over the domain model.
  ///
  /// The definition is where the report runs, so the subtree's locus is the
  /// server. Its shared half — the result envelope and the parameter shapes the
  /// client reads — is **derived from this same subtree** rather than authored
  /// in a second SOM section, so it needs no separate shared-locus entry; the
  /// generic `ResultEnvelope` above covers the CE-ER contract it rides on. The
  /// environment-wide print and export *settings* are CE-CF, not CE-RP, and are
  /// the sibling entry below.
  @Comment('locus: server — CE-RP')
  @SerializationOrder(12)
  ReportDefinitions reportDefinitions = ReportDefinitions();

  /// Print and export layout — CE-CF renderer settings.
  ///
  /// Reached **into** `ExperienceDesignFollowUp` for the same reason as
  /// `sensitiveDataEncryption` above: that root is tagged DOC for the design
  /// vision, wireframes and user-assistance children, and this band is not one
  /// of them. It is the environment-wide print and export configuration — print
  /// strategy, paper size, orientation, page setup, branding, watermark,
  /// header/footer and archive policy, plus the export format, size, field-
  /// mapping and template catalogue.
  ///
  /// Its own `@CodeSpecKind` note appeals to the CE-LG boundary between an
  /// audit *declaration* and its *sink* — and the sink half, `AuditLogFormat`,
  /// is projected two entries up. A renderer's deployment settings sit on the
  /// same side of that boundary, so this entry is what makes the appeal true.
  /// It sits beside `reportDefinitions` because that is the projection the
  /// renderer renders.
  @Comment('locus: server — CE-CF')
  @SerializationOrder(13)
  PrintAndExportLayout printAndExportLayout = PrintAndExportLayout();

  /// Schema versioning and migration — CE-MG migration artifacts.
  ///
  /// The artifacts ship with the server project because that is where the
  /// migration engine runs them (`codespecs_mapping.md` §4.2). The subtree
  /// supplies all three inputs the `@CsMigration` declaration needs: `MIGTG`
  /// gives the data source / schema directory placement, `SCMST.artifactKind`
  /// the artifact kind, and `SCMST.environments` the filename environment tag.
  /// The artifact *filenames* are authored, not derived — a §5.23 string
  /// exemption — so they are not part of the generated surface.
  ///
  /// The subtree sits beside `dataModel` above for a reason: the cumulative
  /// effect of a schema's artifacts must converge on the CE-DB model that entry
  /// generates, and that convergence is a validator check over both.
  @Comment('locus: server — CE-MG')
  @SerializationOrder(14)
  SchemaVersioningAndMigration schemaVersioningAndMigration =
      SchemaVersioningAndMigration();

  // ─── Locus: SHARED + SERVER span ─────────────────────────────────────────

  /// Server operation registry — the application's **own** CE-API surface.
  ///
  /// The one subtree that declares what the system answers. It spans two loci
  /// because a CE-API operation generates two halves (`codespecs_mapping.md`
  /// §4.2): the **operation catalogue and the request/response types** are
  /// shared — the client cites an operation and depends on its shapes — while
  /// the **operation itself** lands on the owning service unit in the server
  /// project. Which service unit that is follows from each operation's primary
  /// written data entity (§5.17), so ownership is derived here rather than
  /// declared.
  ///
  /// The external-interface inventory (EXIN, D07 IIS) is deliberately **not**
  /// reachable from this projection: it describes third-party interfaces the
  /// system talks to, not the surface the system generates.
  @Comment('locus: shared(CE-API contract)+server(CE-API operations)')
  @SerializationOrder(15)
  ServerOperationRegistry serverOperationRegistry = ServerOperationRegistry();

  // ─── Locus: SERVER + CLIENT span ─────────────────────────────────────────

  /// Process steps & actor interactions — CE-SU server-use + CE-SC client-side
  /// interaction; a single subtree whose parts split across both loci.
  @Comment('locus: server(CE-SU)+client(CE-SC)')
  @SerializationOrder(16)
  ProcessStepsAndActorInteractions processStepsAndActorInteractions =
      ProcessStepsAndActorInteractions();

  // ─── Locus: CLIENT (<app>_codespec_client) ───────────────────────────────

  /// Experience CodeSpecs — the client UI seed: CE-EL/FM/LO/TX/AC/NV/ST/ER.
  @Comment('locus: client — CE-EL/FM/LO/TX/AC/NV/ST/ER')
  @SerializationOrder(17)
  ExperienceCodeSpecs experienceCodeSpecs = ExperienceCodeSpecs();
}
