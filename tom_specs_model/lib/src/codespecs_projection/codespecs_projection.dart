/// D13 — CodeSpecs Generation Projection.
///
/// The Phase-4 CodeSpecs generation input: an `@Document` projection —
/// analogous to the D01–D12 Phase-3 projections — that reaches **only** the
/// isolated CodeSpecs subtrees carved out by the Band-F follow-up splits
/// (csmc1..csmc5) and the earlier TOM/IFM splits. Where D01–D12 are the
/// *document* projections over the Solution Blueprint, D13 is the *code*
/// projection: the concrete set of SBP sections the Phase-4 generator consumes
/// to emit skeletal `Cs*`-annotated Dart.
///
/// **`@CodeSpecKind`-driven, not `@DetailedIn`-driven.** No SBP section carries
/// `@DetailedIn(D13CodeSpecsProjection)` — the single-valued `@DetailedIn` /
/// `@MapsTo` pair on each subtree root is already spent on the Phase-3 document
/// that shaped it. The projection instead references the CodeSpecs-relevant
/// subtree roots directly; the `@CodeSpecsProjection()` marker exempts it from
/// the detail-count check (`tom_specs_model_rules.md` §10.2, invariant 7). It
/// still satisfies the pure-projection invariant: every type it reaches also
/// lives in the D00SolutionBlueprint tree — it owns no content of its own.
///
/// **Flat by construction.** The pure-projection invariant forbids any reached
/// type without a D00 counterpart, so the projection can introduce no
/// shared/client/server *container* classes of its own. The §4.2 three-way
/// split (`codespecs_mapping.md` §4.2) is therefore expressed by **locus
/// grouping** — the fields are ordered into shared → server → client bands and
/// each carries a `@Comment('locus: …')` naming its target project
/// (`<app>_codespec_shared` / `_client` / `_server`) and the CE-part(s) that
/// route there per the §4 Locus column. The Phase-4 generator that *consumes*
/// this projection and performs the physical routing is a later wave
/// (out of scope for the projection definition itself).
///
/// **RSP requirements seed is intentionally excluded.** The RSP `Requirements`
/// subtree is consumed by CodeSpecs as *requirements* (a generation seed /
/// acceptance source), not emitted as generated code, so it is not part of the
/// generation projection (`codespecs_mapping.md` §8.3).
///
/// **CE-LG is promoted but not yet projected.** Its SOM home `AuditAndLogging`
/// (SAS) mixes the CodeSpecs-authorable half (`SecurityEventsDefinition`'s
/// policy forms, which map onto `@TomAudited`) with CE-CF sink settings
/// (`AuditLogFormat`'s storage / retention / protection) and an ops follow-up
/// (`ComplianceReporting`). Referencing the subtree wholesale would pull
/// follow-up content into generation, so the section needs a Band-F-style split
/// first — until it lands, CE-LG is an active part whose declarations reach
/// generation through the endpoints and repositories they annotate rather than
/// through a projection field of their own.
///
/// **CE-RP is promoted but not yet projected, for the same reason.** Its SOM
/// home `PrintAndExportLayout` (XDS) mixes CE-CF renderer and export settings —
/// the section's own print/paper/branding fields plus the export format, size
/// and template entries — with the CE-RP report band (`ReportEntry` and its
/// subtree). The report list cannot simply be lifted into a projection field of
/// its own, because its `@SectionId`/`@SectionIdPattern` are declared on
/// `PrintAndExportLayout`; the split has to move it. Meanwhile CE-RP reaches
/// generation the same way CE-LG does.
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

  /// Result envelope — CE-ER canonical §7 success-or-error contract, shared.
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

  /// Technical framework — CE-CF platform/config foundation.
  @Comment('locus: server — CE-CF')
  @SerializationOrder(8)
  TechnicalFrameworkConcept technicalFramework = TechnicalFrameworkConcept();

  /// Access control model — CE-AZ authorization/identity seed.
  @Comment('locus: server — CE-AZ')
  @SerializationOrder(9)
  AccessControlModel accessControl = AccessControlModel();

  // ─── Locus: SERVER + CLIENT span ─────────────────────────────────────────

  /// Process steps & actor interactions — CE-SU server-use + CE-SC client-side
  /// interaction; a single subtree whose parts split across both loci.
  @Comment('locus: server(CE-SU)+client(CE-SC)')
  @SerializationOrder(10)
  ProcessStepsAndActorInteractions processStepsAndActorInteractions =
      ProcessStepsAndActorInteractions();

  // ─── Locus: CLIENT (<app>_codespec_client) ───────────────────────────────

  /// Experience CodeSpecs — the client UI seed: CE-EL/FM/LO/TX/AC/NV/ST/ER.
  @Comment('locus: client — CE-EL/FM/LO/TX/AC/NV/ST/ER')
  @SerializationOrder(11)
  ExperienceCodeSpecs experienceCodeSpecs = ExperienceCodeSpecs();
}
