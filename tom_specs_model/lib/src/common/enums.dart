/// Enums shared across TomSpecs document models.
library;


/// Section type in DocSpecs annotations.
///
/// Names the *shape of a section's body*, which decides what may be parsed out
/// of it: only a form body yields scalar fields, so a class carrying scalar
/// members alongside its `content` must be a form
/// (`tom_specs_model_rules.md` §5.6).
enum SectionType {
  /// Prose narrative: the body is written for a human reader and nothing is
  /// extracted from it. The default for a section whose entire value is the
  /// text between its headline and the next one.
  description,

  /// Field container: the section's scalar members are the form fields parsed
  /// out of the body. Per `tom_specs_model_rules.md` §5.6 this is the *only*
  /// body shape a class with sibling scalar fields may declare — declaring any
  /// other shape alongside scalar fields is a model error, not a style choice.
  form,

  /// Machine-language body (`SQL`, `DDL`, `Dart`, `Mermaid`, …) carried
  /// verbatim and never parsed for fields. A class using this shape may
  /// therefore have no sibling scalar members
  /// (`tom_specs_model_rules.md` §5.6).
  code,
}

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
