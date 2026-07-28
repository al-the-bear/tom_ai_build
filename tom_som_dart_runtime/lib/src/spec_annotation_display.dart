/// What the annotations on a spec node *say* when they are put on screen —
/// which markers a row carries, what each one is labelled, what it explains,
/// and when it must be suppressed.
///
/// This is the semantic half of rendering the model, deliberately separated
/// from the visual half. Two Flutter surfaces show the same class graph — the
/// spec **editor** in a dark Forge shell and the object-model **reviewer** in a
/// light standalone window — and they must not disagree about *what a marker
/// means* while remaining free to disagree about what it looks like. Everything
/// here is theme-free: a chip names a [SpecChipRole], and each app maps roles to
/// its own palette.
///
/// The rules that must hold in both surfaces, and therefore live here rather
/// than in either app:
///
///   * a node tagged for a follow-up process must not also be marked
///     "not yet mapped to CodeSpecs" ([kindChips]);
///   * `@CodeSpecKind` is three-state — mapped, mapped to nothing, undeclared —
///     and all three are rendered ([codeSpecKindChips]);
///   * `@FollowUpKind` has no "undeclared" marker ([followUpKindChips]);
///   * on a row that merges a field with the class it instantiates, the
///     field's annotation wins ([SpecRowExtras.of]);
///   * a closed choice reports its coverage against the discriminator's full
///     value set ([oneOfChips]).
///
/// Pure Dart, no Flutter dependency.
library;

import 'spec_model.dart';

/// Structural-path segment standing in for "any element of this list".
///
/// All visual instances of a list element share this one segment so a review
/// decision targets the *structure*, not a particular rendered instance. Shared
/// because both surfaces key their review state by structural path: an app that
/// spelled this segment differently would silently orphan every entry the other
/// one recorded.
const String kListItemSegment = '§item';

/// Structural-path segment for a list section's own intro content.
///
/// In TomSpecs every list *is* a document section, so besides its repeated
/// items it always carries an introductory content paragraph. This segment
/// keys that paragraph, distinct from the list and its items.
const String kSectionContentSegment = '§content';

/// Structural-path segment for the closed-choice group a class declares.
///
/// The group carries its own path so the *closure decision* — is this case set
/// complete, and is closing it right here? — is addressable in its own right,
/// without hijacking the entry of one of the alternatives (which keep their
/// ordinary field paths).
const String kOneOfSegment = '§oneof';

/// Badge text for a `@CodeSpecsProjection` root (`codespecs_mapping.md` §8.4).
const String kProjectionLabel = 'projection';

/// Why a projection is shallow.
///
/// A projection re-references subtrees authored elsewhere rather than
/// specifying anything itself, which is why the validator exempts it from the
/// detail-count check. Stating that where the model is read turns the exemption
/// from tribal knowledge into something visible on screen.
const String kProjectionExplanation =
    'CodeSpecs projection — this root re-references sections authored '
    'elsewhere, so shallow nodes are correct by construction and the '
    'detail-count check does not apply.';

/// Marker on a node whose `@Unused` annotation says it carries no authored
/// content — the section is a structural container only.
const String kUnusedChipLabel = 'unused';

/// Marker opening a node's provenance panel (`@Reference` /
/// `@StandardReferences`). Collapsed by default: over two thousand fields carry
/// standards, and inlining them would bury the structure.
const String kReferencesChipLabel = 'refs';

/// Label of the switch revealing `@SerializationOrder` ordinals.
const String kSerializationOrderToggleLabel = 'Show serialization order';

/// Every annotation name a spec-model surface accounts for, and where it
/// surfaces.
///
/// This is the contract behind the coverage test both apps run: an annotation
/// the model starts emitting must be given a rendering — or a deliberate
/// decision to suppress it — before it can be added here, so no structural
/// statement can slip into the model unseen. It is shared so the two surfaces
/// cannot answer that question differently.
const Set<String> kRenderedAnnotations = {
  // Identity and headline.
  'Document', // the document root list
  'SectionId', // badge on the row
  'SectionIdPattern', // second badge, beside the section id
  'Headline', // quoted secondary label
  // Shape.
  'Form', // the form panel under the row
  'ContentType', // the row's type label
  'Min', // the row's type label
  'ContentHelp', // the row's doc line
  // Hand-offs and taxonomies.
  'MapsTo', // `maps→` chip
  'DetailedIn', // `detail→` chip
  'CodeSpecKind', // part chips
  'FollowUpKind', // process chips
  'CodeSpecsProjection', // projection chip
  // Closed choices.
  'OneOf', // the choice group node
  'Case', // `case:` chips on the alternatives
  // Markers, notes and provenance.
  'Unused', // struck-through label + `unused` chip
  'Comment', // inline `←` note
  'Reference', // references panel
  'StandardReferences', // references panel
  'SerializationOrder', // `#n` badge, behind the toggle
};

/// The kind of statement a chip makes, so an app can colour it without knowing
/// which annotation produced it.
///
/// Roles rather than colours because the two surfaces have opposite
/// backgrounds: a value that reads as "attention" on the reviewer's light
/// canvas is illegible on the editor's dark one. Naming the *statement* lets
/// each pick its own value while keeping the meanings aligned.
enum SpecChipRole {
  /// `@Case` — which alternative of a closed choice this row is.
  caseValue,

  /// `@CodeSpecKind` naming one or more CodeSpecs parts.
  codeSpecMapped,

  /// `@CodeSpecKind` present but empty — recorded as mapping to no part.
  codeSpecNone,

  /// No `@CodeSpecKind` at all — the open question a structural review looks
  /// for.
  codeSpecUnmapped,

  /// `@FollowUpKind` naming one or more downstream processes.
  followUpMapped,

  /// `@FollowUpKind` present but empty.
  followUpNone,

  /// The root of a `@CodeSpecsProjection` document.
  projection,

  /// `@Unused` — a structural container with no authored content.
  unused,

  /// The affordance opening the provenance panel.
  references,

  /// A closed choice whose every discriminator value is covered.
  choiceComplete,

  /// A closed choice with discriminator values left over.
  choiceIncomplete,

  /// The specific values a closed choice leaves uncovered.
  choiceUncovered,

  /// A closed choice whose discriminator field cannot be resolved.
  choiceBroken,

  /// A hand-off marker (`@MapsTo` / `@DetailedIn`) — clickable in both apps.
  handoff,

  /// Structural notes the tree itself makes (recursion, cut points).
  structural,
}

/// One rendered marker: what it says, what kind of statement it is, and the
/// detail too long to fit on it.
class SpecChip {
  /// The text on the chip.
  final String label;

  /// What kind of statement the chip makes — the app's key into its palette.
  final SpecChipRole role;

  /// Detail that does not fit on the chip, shown on hover. Carries the
  /// annotation's own `note` where it has one, which is the only place the
  /// author's explanation of a mapping can surface.
  final String? tooltip;

  const SpecChip(this.label, this.role, {this.tooltip});

  @override
  String toString() => 'SpecChip($label, $role)';
}

/// The marker a `@CodeSpecsProjection` document root carries.
const SpecChip projectionChip =
    SpecChip(kProjectionLabel, SpecChipRole.projection,
        tooltip: kProjectionExplanation);

/// The marker an `@Unused` node carries beside its struck-through label.
const SpecChip unusedChip = SpecChip(
  kUnusedChipLabel,
  SpecChipRole.unused,
  tooltip: 'No section text expected — this section is a structural '
      'container only',
);

/// The affordance that opens a node's provenance panel.
const SpecChip referencesChip = SpecChip(
  kReferencesChipLabel,
  SpecChipRole.references,
  tooltip: 'Show the standards this section derives from',
);

/// The chips stating where a node's subject matter is headed.
///
/// The model splits that subject matter in two (`codespecs_mapping.md` §8.3):
/// subtrees realised as CodeSpecs code, tagged `@CodeSpecKind` (§9.1), and
/// subtrees that feed a downstream *process* — documentation, training,
/// migration, … — tagged `@FollowUpKind`. Both are produced by one function
/// because they interact: a node tagged for a follow-up process **has** been
/// classified, so it must not also carry the "not yet mapped" marker, which
/// would state the opposite and send a reviewer chasing a CodeSpecs mapping
/// that by construction cannot exist.
List<SpecChip> kindChips(KindLink? codeSpec, KindLink? followUp) => [
      ...followUpKindChips(followUp),
      ...codeSpecKindChips(codeSpec, suppressUnmapped: followUp != null),
    ];

/// The `@CodeSpecKind` chips for [link].
///
/// Three-state — mapped, explicitly mapped to nothing, or undeclared. All three
/// are rendered because the third is the open question a structural reviewer is
/// looking for; leaving it blank would hide it among the mapped ones. Pass
/// [suppressUnmapped] when the node is already classified by another taxonomy,
/// so the undeclared marker would be a false statement rather than an open
/// question.
List<SpecChip> codeSpecKindChips(KindLink? link,
    {bool suppressUnmapped = false}) {
  if (link == null) {
    if (suppressUnmapped) return const [];
    return const [
      SpecChip('cs?', SpecChipRole.codeSpecUnmapped,
          tooltip: 'No @CodeSpecKind — not yet mapped to a CodeSpecs part'),
    ];
  }
  if (link.kinds.isEmpty) {
    return const [
      SpecChip('cs:none', SpecChipRole.codeSpecNone,
          tooltip: '@CodeSpecKind with no kinds — recorded as mapping to no '
              'CodeSpecs part'),
    ];
  }
  return [
    for (final kind in link.kinds)
      SpecChip('cs:$kind', SpecChipRole.codeSpecMapped, tooltip: link.note),
  ];
}

/// The `@FollowUpKind` process chips for [link].
///
/// There is no "not declared" chip here: the absence of a follow-up tag is not
/// an open question — the overwhelming majority of the model is CodeSpecs-bound
/// — so a marker on every node would be noise, unlike its `cs?` counterpart.
List<SpecChip> followUpKindChips(KindLink? link) {
  if (link == null) return const [];
  if (link.kinds.isEmpty) {
    return const [
      SpecChip('fu:none', SpecChipRole.followUpNone,
          tooltip: '@FollowUpKind with no processes — recorded as feeding no '
              'follow-up process'),
    ];
  }
  return [
    for (final process in link.kinds)
      SpecChip('fu:$process', SpecChipRole.followUpMapped,
          tooltip: link.note ??
              'Follow-up process — this subtree becomes $process work, '
                  'not CodeSpecs code'),
  ];
}

/// One chip per discriminator value [field] is bound to by `@Case`.
///
/// One chip *per value* rather than one listing them all, matching the `cs:` /
/// `fu:` convention — and because `@Case` is repeatable, so a single chip would
/// have to invent a joining syntax for something the model states as a list.
List<SpecChip> caseChips(SpecField field) => [
      for (final value in field.caseValues)
        SpecChip('case:$value', SpecChipRole.caseValue,
            tooltip: 'Applies when the discriminator is "$value"'),
    ];

/// The chips a field row carries: which alternative of a closed choice it is,
/// then where its subtree is headed.
///
/// Case chips come first because they say *whether this row applies at all* —
/// a stronger statement about the row than its CodeSpecs/follow-up mapping, and
/// the one a reviewer scanning a choice group is reading for.
List<SpecChip> fieldChips(SpecField field) => [
      ...caseChips(field),
      ...kindChips(field.codeSpecKind, field.followUpKind),
    ];

/// The chips a closed-choice group header carries: how much of the
/// discriminator's value set the alternatives cover, which values they miss,
/// and whether the discriminator resolved at all.
List<SpecChip> oneOfChips(OneOfGroup group) {
  final total = group.discriminatorValues.length;
  final covered = group.coveredValues.length;
  final uncovered = group.uncoveredValues;
  return [
    if (total > 0)
      SpecChip(
        'covers $covered/$total',
        group.isComplete
            ? SpecChipRole.choiceComplete
            : SpecChipRole.choiceIncomplete,
        tooltip: '${group.discriminator} admits $total values; '
            '$covered have a subsection of their own',
      ),
    if (uncovered.isNotEmpty)
      SpecChip(
        'uncovered: ${uncovered.join(', ')}',
        SpecChipRole.choiceUncovered,
        // §8.2 makes this a warning, not an error — the reviewer judges
        // whether the gap is deliberate.
        tooltip: 'These discriminator values carry only the common sections. '
            'Legal, but worth confirming it is intended.',
      ),
    if (group.discriminatorField == null)
      SpecChip('discriminator not found', SpecChipRole.choiceBroken,
          tooltip: 'No form field named "${group.discriminator}" on this '
              'class — the choice cannot be checked for completeness'),
  ];
}

/// The annotations a row renders beside its structural label: the `@Unused`
/// marker, the `@Comment` note, the `@Headline` default, the
/// `@SectionIdPattern` badge, the provenance and the `@SerializationOrder`
/// ordinal.
///
/// Gathered into one value so a row widget does not have to know whether its
/// subject is a class, a field, or — at a complex subsection, where a tree
/// collapses the two into a single row — both. Synthetic rows (item banners,
/// injected content, a choice group) have no model node and use [none].
class SpecRowExtras {
  /// `@Unused` on either side of the row.
  final bool unused;

  /// The `@Comment` note.
  final String? comment;

  /// The `@Headline` default headline.
  final String? headline;

  /// The `@SectionIdPattern` each list item's id follows.
  ///
  /// Independent of the section id, never a fallback for it: a patterned list
  /// field carries both, so reading the pattern only when the id is missing
  /// hides every pattern in the model.
  final String? sectionIdPattern;

  /// The `@Reference` cross-link description.
  final String? reference;

  /// The `@StandardReferences` provenance block.
  final StandardReferences? standardReferences;

  /// The `@SerializationOrder` ordinal.
  final int? serializationOrder;

  const SpecRowExtras({
    this.unused = false,
    this.comment,
    this.headline,
    this.sectionIdPattern,
    this.reference,
    this.standardReferences,
    this.serializationOrder,
  });

  /// The extras of a synthetic row that has no model node behind it.
  static const SpecRowExtras none = SpecRowExtras();

  /// Collects the extras of [field], of [cls], or of the merged pair.
  ///
  /// On a merged row the field's statement wins: it annotates *this* use of the
  /// type, while the class's annotation describes every use of it.
  factory SpecRowExtras.of({SpecField? field, SpecClass? cls}) => SpecRowExtras(
        unused: (field?.isUnused ?? false) || (cls?.isUnused ?? false),
        comment: field?.comment ?? cls?.comment,
        headline: field?.headline ?? cls?.headline,
        sectionIdPattern: field?.sectionIdPattern,
        reference: field?.reference ?? cls?.reference,
        standardReferences: field?.standardReferences ?? cls?.standardReferences,
        serializationOrder: field?.serializationOrder,
      );

  /// Whether the row has provenance to show behind the [referencesChip].
  bool get hasReferences => reference != null || standardReferences != null;
}
