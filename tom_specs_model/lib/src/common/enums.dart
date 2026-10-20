/// Enums shared across TomSpecs document models.
///
/// ## Which fields a value enum types
///
/// [Priority], [Status], [Probability], [Impact] and [ImportanceBand] are
/// *value* vocabularies: unlike the kind enums, whose constants name a
/// structural choice, theirs name a band an author picks. A form field takes
/// one of them when the band set it documents **is** that enum's band set — a
/// documented subset counts, since nothing an author has written stops being
/// expressible.
///
/// The subset clause is what [ImportanceBand] leans on hardest. It is the
/// model's most-repeated vocabulary — a hundred form fields spelling
/// `Critical / High / Medium / Low` a dozen ways — and about a third of them
/// document only the lower three bands. Those are the same instrument with its
/// top band unused, not a second scale, so they bind here too.
///
/// There is exactly **one** risk matrix in the model, [Probability] ×
/// [Impact], rated on five bands. The goal, system-migration and transition
/// risk entries used to rate on a three-band matrix of their own; they were
/// moved onto the five-band pair so that two risks from different documents
/// can be compared, and so an author never has to work out which instrument a
/// given entry uses.
///
/// A closed vocabulary the model still carries as `String` is one whose band
/// set is *not* one of these — an extra band (`Very High`, `None`, `Full`,
/// `Untrusted`, `Blocking`), a numbered scheme (`P1`–`P5`), or a field that
/// names a *rating scheme* rather than a rating.
library;

/// Priority level for requirements.
///
/// The MoSCoW vocabulary. The four constants are not four points on a scale of
/// wanting something: they differ in *what happens when the item does not
/// ship*, which is the only question a delivery decision actually asks.
enum Priority {
  /// MoSCoW *must have*: the release is not shippable without it. A failed
  /// must-have is a release blocker — the date moves, the requirement does
  /// not. Anything that can be traded away under schedule pressure was never
  /// a must.
  must,

  /// MoSCoW *should have*: painful to omit, but the release still ships
  /// without it. This is the first band traded away when the timebox is
  /// threatened, and dropping one is expected to come with a stated
  /// workaround rather than silence.
  should,

  /// MoSCoW *could have*: included only while it costs nothing that a
  /// [must] or [should] item needs. Dropping it is a routine timebox decision
  /// and requires no re-approval.
  could,

  /// MoSCoW *won't have — this time*: deliberately excluded from **this**
  /// delivery and recorded rather than deleted, so the decision (and its
  /// reasoning) survives into the next planning round. Distinct from
  /// [Status.rejected], which means never; this means not now.
  wontThisTime,
}

/// The four-band qualitative scale — `critical` / `high` / `medium` / `low`.
///
/// The model's most-used vocabulary, and the one an author meets under a dozen
/// different labels: priority, criticality, severity, urgency, risk level,
/// importance, weight, confidence, readiness, feasibility. They are one
/// instrument, not twelve — the words differ, the scale does not — so they are
/// one type. Four ordered bands, **descending**: [critical] is the top.
///
/// Descending is deliberate and is the opposite of [Probability] and [Impact],
/// which ascend. Both orders are the order the bands are *written* in: a risk
/// matrix is read from its low corner upwards, and a priority list is read from
/// its top down. Declaration order is the ordering in both cases; nothing
/// compares a band of this enum with a band of those.
///
/// Not every field that rates something binds here. A field documenting a band
/// this enum does not have — `Very High`, `None`, `Full`, `Untrusted`,
/// `Blocking` — is a different scale and stays free text until it gets its own
/// type.
enum ImportanceBand {
  /// The top band: whatever this rates cannot be traded away, deferred or
  /// absorbed. On a priority it blocks the release; on a severity it stops
  /// work; on a criticality its loss stops the business function. If
  /// everything on a list is critical, the list has not been rated.
  critical,

  /// Below [critical] but ahead of the ordinary queue: it is expected to be
  /// dealt with in the current cycle, and letting it slip is a decision
  /// somebody has to make rather than a routine outcome.
  high,

  /// The ordinary band, and the default when nobody has actually assessed the
  /// item. A medium with no reasoning behind it is worth challenging — it is
  /// as often "not looked at" as it is "genuinely middling".
  medium,

  /// The bottom band: worth recording, not worth planning around. Items here
  /// are done when they are cheap, and their omission needs no explanation.
  low,
}

/// Status of a requirement or deliverable.
///
/// The lifecycle position of a single item, from authoring to evidence. The
/// boundary that matters most is [approved]: before it the text is still being
/// settled, after it a change is a change request rather than an edit.
enum Status {
  /// Being authored. The wording may change without notice and nothing
  /// downstream may be planned, estimated or built against it.
  draft,

  /// Complete enough to be reviewed and awaiting a decision. Review may still
  /// send it back or reject it outright, so it is not yet a commitment.
  proposed,

  /// Signed off as the agreed intent, and the baseline that downstream work is
  /// planned and estimated against. From here on a change is a change request
  /// with its own approval, not a quiet edit.
  approved,

  /// A realising artifact exists, but nothing has yet confirmed it does what
  /// [approved] committed to. The gap between this and [verified] is exactly
  /// the evidence, which is why the two are separate states rather than one
  /// "done".
  implemented,

  /// Implemented *and* shown to meet its acceptance criteria by test or review
  /// evidence. The only terminal state that means the item is finished.
  verified,

  /// Approved in substance but not scheduled for this delivery, and kept in the
  /// document so it returns to the backlog instead of being lost. This is the
  /// lifecycle position; [Priority.wontThisTime] is the scoping decision that
  /// puts an item here.
  deferred,

  /// Decided against, permanently. Retained rather than deleted so a later
  /// reader can see the option was considered and why it lost, instead of
  /// re-proposing it.
  rejected,
}

/// Probability level for risks.
///
/// The likelihood axis of the risk matrix; [Impact] is the consequence axis,
/// and a risk's rating is the pair. Five ordered bands, ascending — the
/// declaration order *is* the ordering, so comparing two risks means comparing
/// positions in this list.
enum Probability {
  /// Would be surprising: no trigger for it is visible in the current plan.
  /// Carried on the register to be watched, not to be mitigated.
  veryLow,

  /// Plausible but not expected — a known trigger exists and is not currently
  /// active. Cheap mitigations are worth taking; expensive ones are not.
  low,

  /// As likely as not. The band where the decision to mitigate turns on cost
  /// rather than on likelihood, and the one most often used as a default when
  /// nobody has actually estimated — a medium with no reasoning behind it is
  /// worth challenging.
  medium,

  /// Expected unless something about the plan changes. Mitigation is assumed;
  /// its absence needs an explicit reason.
  high,

  /// Effectively certain on the current plan. At this point it is a planned
  /// event, not a risk: it belongs in the plan with an owner and a date, and
  /// leaving it on the risk register hides work rather than tracking it.
  veryHigh,
}

/// Impact level for risks.
///
/// The consequence axis of the risk matrix, paired with [Probability]. The
/// bands are graded by **who has to act** if the risk lands — that keeps the
/// rating decidable, where "how bad is it" alone does not. Five ordered bands,
/// ascending; declaration order is the ordering.
enum Impact {
  /// Absorbed inside normal working. No measurable change to schedule, budget
  /// or quality, and nobody outside the team doing the work has to know.
  negligible,

  /// Felt within one workstream and covered by that workstream's own
  /// contingency. Nothing outside it is replanned.
  minor,

  /// Exceeds a single workstream's contingency and forces replanning across
  /// workstreams. Project management decides; the sponsor is informed.
  moderate,

  /// Threatens a committed date, budget or quality commitment. Recovery
  /// requires a sponsor decision — more money, less scope, or a later date.
  major,

  /// The objective itself fails and no contingency inside the project recovers
  /// it. The decision at this level is whether the project continues at all.
  critical,
}

/// The eight ISO/IEC 25010:2023 product-quality characteristics.
///
/// The closed vocabulary for the `Iso25010Coverage` cross-map. The 2023
/// edition made two changes to the 2011 eight: it renamed *usability* →
/// interaction capability, and folded *portability* into the new *flexibility*
/// characteristic. (*Compatibility* was already first-class in 2011 and is
/// unchanged.) This enum carries the 2023 spine, matching the eight
/// `*Characteristic` classes under `SystemQualityGoals`.
///
/// Those eight classes are the single source of truth for the taxonomy; this
/// enum is what a coverage entry *references*, which is why it is closed —
/// coverage of a characteristic can only be shown to be missing if the set of
/// characteristics is fixed. The 25010 spine is what
/// `tom_specs_model_rules.md` §2.2 anchors the Quality & Acceptance layer to.
enum Iso25010Characteristic {
  /// ISO/IEC 25010:2023 *functional suitability* — the degree to which the
  /// product provides functions that meet stated **and implied** needs under
  /// specified conditions. The implied half is the reason this is a quality
  /// characteristic and not just "the requirements are done": correctness and
  /// completeness of what was asked for are judged here, not merely presence.
  /// Modelled by `FunctionalSuitabilityCharacteristic`.
  functionalSuitability,

  /// ISO/IEC 25010:2023 *performance efficiency* — performing the functions
  /// within specified time and throughput parameters while being efficient in
  /// its use of resources. Both halves are required: hitting a latency target
  /// by consuming unbounded resources does not satisfy it. Targets under this
  /// characteristic are meaningless without the load profile they are stated
  /// against. Modelled by `PerformanceEfficiencyCharacteristic`.
  performanceEfficiency,

  /// ISO/IEC 25010:2023 *compatibility* — exchanging information with other
  /// products or systems, and performing its required functions while sharing
  /// a common environment and resources. Its two concerns are interoperability
  /// (the exchange) and co-existence (the sharing); the second is the one
  /// routinely forgotten, because nothing in a system's own requirements
  /// mentions the neighbours it must not disturb. Modelled by
  /// `CompatibilityCharacteristic`.
  compatibility,

  /// ISO/IEC 25010:2023 *interaction capability* — the degree to which
  /// specified users can interact with the product to exchange information
  /// through the user interface and complete specified tasks.
  ///
  /// **This is the 2023 renaming of *usability*.** A reader working from the
  /// 2011 edition looking for a `usability` constant lands here. The rename
  /// carries a widening, not just a new label: the characteristic covers the
  /// whole user–system exchange — including user assistance and
  /// self-descriptiveness — rather than ease of use alone, so a 2011 usability
  /// assessment mapped onto it is an under-assessment until those are added.
  /// Modelled by `InteractionCapabilityCharacteristic`.
  interactionCapability,

  /// ISO/IEC 25010:2023 *reliability* — performing specified functions under
  /// specified conditions for a specified period of time. All three
  /// qualifiers are part of the claim: a reliability target without the
  /// conditions and the period states nothing measurable. Modelled by
  /// `ReliabilityCharacteristic`.
  reliability,

  /// ISO/IEC 25010:2023 *security* — protecting information and data so that
  /// persons and other products have the degree of data access appropriate to
  /// their types and levels of authorization.
  ///
  /// This is the *quality target* — what "secure enough" means and how it is
  /// evidenced. The control design that meets it is a separate document,
  /// `D08SecurityAccessSpecification`, anchored to ISO 27001
  /// (`tom_specs_model_rules.md` §2.2); recording controls here instead of
  /// targets produces a coverage entry that cannot be tested. Modelled by
  /// `SecurityCharacteristic`.
  security,

  /// ISO/IEC 25010:2023 *maintainability* — the effectiveness and efficiency
  /// with which the product can be modified by its maintainers, whether to
  /// correct, improve or adapt it. The assessment is meaningless without
  /// naming *who* maintains it and over what horizon. Modelled by
  /// `MaintainabilityCharacteristic`.
  maintainability,

  /// ISO/IEC 25010:2023 *flexibility* — the degree to which the product can be
  /// adapted to changes in its requirements, contexts of use or system
  /// environment.
  ///
  /// **New in the 2023 edition, and where *portability* went.** A reader
  /// working from the 2011 edition looking for a `portability` constant lands
  /// here: the older characteristic's adaptability, installability and
  /// replaceability concerns are carried under flexibility, alongside
  /// scalability. The localization & translation concern cross-maps to exactly
  /// this portability/adaptability content
  /// (`tom_specs_model_rules.md` §2.3). Modelled by
  /// `FlexibilityCharacteristic`.
  flexibility,
}

/// How severe an alert is — what its arrival asks of the person on call.
///
/// Distinct from [ImportanceBand], which rates how much something *matters*:
/// an alert's severity says how fast someone has to act, and the three values
/// are the ones monitoring tools route on.
enum AlertSeverity {
  /// Someone acts now: the service, or a promise it makes, is broken.
  critical,

  /// Someone acts soon: a threshold is crossed and the trend leads to a
  /// critical alert if nothing changes.
  warning,

  /// No one has to act: recorded for the picture, not for a page.
  info,
}

/// How a rule about roles is enforced.
enum ConstraintEnforcement {
  /// The system refuses the combination; no override exists — including a
  /// combination that cannot arise by construction.
  hard,

  /// The system warns and the combination may stand, with the override the
  /// rule names (an approval, a recorded reason).
  soft,
}

/// The narrowest configuration scope permitted to shadow a key; every scope
/// in between is opened too. Mirrors `CsOverridableBy` (`tom_code_specs`).
///
/// **Not a default.** Pinning a key must be authored, not fallen into, so a
/// field of this type is never defaulted.
enum OverridableBy {
  /// Scope-pinned: no narrower scope may shadow the key.
  none,

  /// A per-install client configuration value may shadow the key.
  client,

  /// A per-user setting may shadow the key.
  user,

  /// A per-user-per-device setting may shadow the key.
  device,
}

/// The type of a configuration value.
///
/// Named by what the value is rather than by a language's type keyword, so
/// every generated runtime can carry the constants unchanged.
enum ConfigValueType {
  /// Text.
  text,

  /// A whole number.
  integer,

  /// A decimal number.
  decimal,

  /// True or false.
  boolean,

  /// One of a closed set of values, which the setting names.
  enumeration,

  /// A length of time.
  duration,
}

/// A yes/no fact that may also legitimately be open.
///
/// A plain `bool` forces an author to pick true or false where the honest
/// answer is "it depends on the installation" or "not decided yet", and the
/// nuance then hides in a notes field the typed reader never sees.
enum DecisionState {
  /// Yes, everywhere.
  yes,

  /// No, everywhere.
  no,

  /// Depends on the installation or context; the notes say on what.
  depends,

  /// Not decided yet.
  undecided,
}

/// How a role's membership arises.
enum RoleMembershipSource {
  /// Holders are assigned to the role directly.
  assigned,

  /// Membership follows from grants the holder has: the role is a name for a
  /// set of grants, not something anyone is assigned.
  derivedFromGrants,

  /// Both: holders are assigned, and a grant can also confer membership.
  both,
}

/// Whether repeating an operation with the same input repeats its effect.
enum OperationIdempotency {
  /// Repeating it has no further effect.
  idempotent,

  /// Repeating it has no further effect when the caller sends the same
  /// idempotency key.
  idempotentWithKey,

  /// Each call has its own effect; a retry must be decided by the caller.
  notIdempotent,
}

/// The relationship between two bounded contexts (context mapping, after
/// Evans and Vernon).
enum ContextRelationshipType {
  /// The two teams succeed or fail together and plan jointly.
  partnership,

  /// The two share a small common model both depend on.
  sharedKernel,

  /// The downstream context's needs shape what the upstream provides.
  customerSupplier,

  /// The downstream context adopts the upstream model as it is.
  conformist,

  /// The downstream context translates the upstream model at its boundary.
  anticorruptionLayer,

  /// The upstream context offers a protocol any context may use.
  openHostService,

  /// The two exchange a documented, shared language.
  publishedLanguage,

  /// The two have no integration.
  separateWays,
}

/// How far a translated text has been checked.
enum TranslationReviewStatus {
  /// Written, not yet reviewed.
  draft,

  /// Produced by a machine, not yet reviewed by a person.
  machineTranslated,

  /// Reviewed by a person fluent in the language.
  reviewed,

  /// Approved for release.
  approved,
}
