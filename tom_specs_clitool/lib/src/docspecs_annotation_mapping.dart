/// The gate that keeps `tom_specs_core`'s annotation catalogue and the
/// DocSpecs schema surface accountable to each other.
///
/// An annotation in the catalogue is a promise that applying it does
/// something. That promise was silently broken: annotations were declared,
/// documented as live, applied nowhere, and — for most of them — read by
/// nothing, so applying one tomorrow would have changed no output at all.
/// Nothing could catch it, because a construct with no code has no code to
/// diff.
///
/// The fix is to give every annotation a **declared destination** and check
/// the declaration from both sides:
///
/// - **Totality** — every annotation class `tom_specs_core` declares appears
///   in [docSpecsAnnotationBindings], and every binding names a real
///   annotation class. A new annotation therefore cannot be added without a
///   decision about what it means downstream.
/// - **Realisation** — every binding that names a [schemaKey] must actually
///   produce that key in a generated schema. The accompanying test applies
///   each schema-bound annotation in a fixture model and asserts the key
///   appears in the emitted YAML, so a binding cannot claim a destination the
///   generator does not honour.
///
/// A binding with a null [schemaKey] is **model-only** by decision, not by
/// omission — [ModelOnlyReason] names why, and the reason is part of the
/// checked declaration. The DocSpecs schema is a *document* schema; a good
/// deal of the model's metadata (traceability, CodeSpecs routing, member
/// ordering) describes the model itself and has no place in it. Those
/// annotations still reach every consumer: the SOM metadata tree exports every
/// non-slotted annotation losslessly through `MetaNode.extra`, so an editor
/// built on any of the nine runtimes sees them whether or not the DocSpecs
/// schema does.
library;

import 'dart:io';

/// Why an annotation has no DocSpecs schema counterpart.
enum ModelOnlyReason {
  /// Describes how the model maps onto other documents or onto CodeSpecs —
  /// a statement about the model, not about an instance document.
  traceability,

  /// Governs code generation across the nine language runtimes (member order,
  /// discriminated groups, projection markers).
  generation,

  /// Consumed by the generator to *shape* the schema rather than to fill a
  /// property — the annotation's effect is structural (a section vanishes, a
  /// name is derived) and leaves no property of its own.
  structural,
}

/// One annotation's declared destination in a generated DocSpecs schema.
class DocSpecsAnnotationBinding {
  /// Declares one annotation's destination, asserting the either/or this
  /// class exists to enforce.
  ///
  /// A destination is a [schemaKey] with the [owner] that holds it, or a
  /// [modelOnly] reason — never both and never neither. Neither is the
  /// undeclared destination the library note describes: an annotation that
  /// looks accounted for and lands nowhere.
  const DocSpecsAnnotationBinding(
    this.annotation, {
    this.schemaKey,
    this.owner,
    this.modelOnly,
    required this.note,
  })  : assert(
          (schemaKey == null) != (modelOnly == null),
          'A binding is either schema-bound (schemaKey) or model-only '
          '(modelOnly) — exactly one.',
        ),
        assert(
          schemaKey == null || owner != null,
          'A schema-bound binding names the schema object that owns the key.',
        );

  /// The annotation class name as declared in `tom_specs_core`.
  final String annotation;

  /// The DocSpecs YAML key this annotation feeds (e.g. `allowed-tags`), or
  /// null when the annotation is model-only.
  final String? schemaKey;

  /// The `tom_doc_specs` schema object that owns [schemaKey] — the block a
  /// reader should look in (`section-types` entry, `document.sections` entry,
  /// …).
  final DocSpecsOwner? owner;

  /// Why the annotation has no schema counterpart; null when schema-bound.
  final ModelOnlyReason? modelOnly;

  /// How the value is derived, or what the annotation does instead.
  final String note;

  /// Whether the annotation reaches a generated schema at all.
  ///
  /// The constructor's assertion makes this the exact complement of
  /// [modelOnly], so the two never have to be consulted together. It is also
  /// the filter the realisation test uses: a schema-bound binding must prove
  /// its key appears in a schema generated from a fixture model, and a
  /// model-only one is exempt by declaration rather than by silence.
  bool get isSchemaBound => schemaKey != null;
}

/// The schema block that owns a [DocSpecsAnnotationBinding.schemaKey].
enum DocSpecsOwner {
  /// A `section-types:` entry (`SectionTypeDef`).
  sectionType,

  /// A `subsection-types:` entry of a section type (`SubsectionConstraint`).
  subsectionConstraint,

  /// A `form-types:` field (`FormFieldDef`).
  formField,

  /// A `document: sections:` entry (`SectionDef`).
  documentSection,

  /// A `subsection-declarations:` entry (`SubsectionDef`).
  subsectionDeclaration,

  /// A top-level schema property or custom tag (`DocSpecSchema`).
  schema,
}

/// Every annotation `tom_specs_core` declares, and where it lands.
///
/// Ordered as the `tom_specs_core` README catalogue orders them, so the two
/// can be read side by side.
const List<DocSpecsAnnotationBinding> docSpecsAnnotationBindings = [
  // --- Identity & structure -------------------------------------------------
  /// The section id, which is the model's globally unique handle for a section
  /// type — so the schema's own identity is derived from it rather than
  /// separately declared.
  DocSpecsAnnotationBinding(
    'SectionId',
    schemaKey: 'prefix',
    owner: DocSpecsOwner.sectionType,
    note: 'Names the section type (id lower-cased) and, with the TomSpecs '
        'dashes transformed to `_`, supplies the default prefix.',
  ),

  /// A list's per-item id template. Its counter slot is what turns one field
  /// into a numbered family of sections, so the schema needs it as an id check
  /// rather than as a name.
  DocSpecsAnnotationBinding(
    'SectionIdPattern',
    schemaKey: 'pattern-check-id',
    owner: DocSpecsOwner.sectionType,
    note: 'The pattern with `xxx` compiled to `.+`; an explicit '
        '`@PatternCheckId` overrides it.',
  ),

  /// The document root. It is the only annotation that decides *which* schema
  /// is being generated at all, which is why its name reaches the schema id as
  /// well as the rendered title.
  DocSpecsAnnotationBinding(
    'Document',
    schemaKey: 'title-format',
    owner: DocSpecsOwner.schema,
    note: 'Marks the root: its `name` becomes the schema id and the '
        '`title-format` custom tag.',
  ),

  /// Stage one of heading resolution — the string a heading is matched on to
  /// decide its section type. Written only where the id-derived default is not
  /// the prefix authors actually type.
  DocSpecsAnnotationBinding(
    'Prefix',
    schemaKey: 'prefix',
    owner: DocSpecsOwner.sectionType,
    note: 'Overrides the section-id-derived prefix for two-stage heading '
        'resolution.',
  ),

  /// Where a subsection may sit among its siblings. The constraint is on the
  /// parent's ordering rather than on the subsection's own type, which is why
  /// it lands in the root's declaration block.
  DocSpecsAnnotationBinding(
    'Position',
    schemaKey: 'position',
    owner: DocSpecsOwner.subsectionDeclaration,
    note: "`first` / `last` / `any`; emitted into the root's "
        '`subsection-declarations` block.',
  ),

  /// Member order for the exported model. It says nothing about a *document* —
  /// a document's section order is the schema's structure — so it is generation
  /// metadata with no schema property to fill.
  DocSpecsAnnotationBinding(
    'SerializationOrder',
    modelOnly: ModelOnlyReason.generation,
    note: 'Pins on-disk member order across the nine runtimes. Document '
        'section order is carried by the schema structure itself.',
  ),

  // --- Content typing & authoring -------------------------------------------
  /// What kind of text the section body holds. Only a non-plain type reaches
  /// the schema: a `format` is what makes the validator insist on a fenced
  /// block, and prose must not be held to that.
  DocSpecsAnnotationBinding(
    'ContentType',
    schemaKey: 'format',
    owner: DocSpecsOwner.sectionType,
    note: 'Code/diagram content types become `format`; plain text carries '
        'none (a `format` makes the validator demand a fenced block).',
  ),

  /// Declares the body to be name-value pairs rather than prose. It emits a
  /// whole `form-types` entry, so its `format` points at a definition the same
  /// generation run produces.
  DocSpecsAnnotationBinding(
    'Form',
    schemaKey: 'format',
    owner: DocSpecsOwner.sectionType,
    note: 'Emits a `form-types` entry and points `format` at it.',
  ),

  /// Not applied to anything itself — a field is written inside a `@Form`'s
  /// field list, so it reaches the schema through the form type its enclosing
  /// annotation emits.
  DocSpecsAnnotationBinding(
    'Field',
    schemaKey: 'fieldname',
    owner: DocSpecsOwner.formField,
    note: 'One `@Form` field: name, `required`, and `description` from the '
        'author hint.',
  ),

  /// Authoring guidance for whoever fills the section in. It beats the doc
  /// comment because it is written for the author of a document, where the doc
  /// comment is written for the reader of the model.
  DocSpecsAnnotationBinding(
    'ContentHelp',
    schemaKey: 'description',
    owner: DocSpecsOwner.sectionType,
    note: 'Preferred over the doc comment.',
  ),

  /// The default title of a section. A stored headline always wins at render
  /// time, so what the schema carries is the fallback rather than the value a
  /// reader will see.
  DocSpecsAnnotationBinding(
    'Headline',
    schemaKey: 'title-format',
    owner: DocSpecsOwner.schema,
    note: 'A root-class headline wins over the `@Document` name in the '
        '`title-format` custom tag (YRD4).',
  ),

  /// Presence of body text, with no threshold on its length — that is
  /// `@MinLength`. `@Min(1)` on a content member states the same thing, so the
  /// key has two sources in the model.
  DocSpecsAnnotationBinding(
    'TextRequired',
    schemaKey: 'text-required',
    owner: DocSpecsOwner.sectionType,
    note: 'Also implied by `@Min(1)` on a content member.',
  ),

  /// The opposite verdict to `@TextRequired`: the section is a container and
  /// its body text is ignored. It takes the node out of the schema, and an
  /// absence has no key to be emitted under.
  DocSpecsAnnotationBinding(
    'Unused',
    modelOnly: ModelOnlyReason.structural,
    note: 'Omits the node and its subtree from the schema entirely — an '
        'absence, not a property.',
  ),

  /// A short note shown in the outliner and carried on to downstream
  /// generators. It addresses the reader of the model, so a document schema has
  /// nowhere to put it.
  DocSpecsAnnotationBinding(
    'Comment',
    modelOnly: ModelOnlyReason.generation,
    note: 'Free-form metadata for downstream generators (e.g. the CodeSpecs '
        'projection loci).',
  ),

  // --- Constraints & validation ---------------------------------------------
  /// The floor on a list's item count. `1` is what makes a section mandatory,
  /// which is why this one annotation also decides `optional:` on a top-level
  /// entry and text presence on a content member.
  DocSpecsAnnotationBinding(
    'Min',
    schemaKey: 'min-count',
    owner: DocSpecsOwner.subsectionConstraint,
    note: 'Also drives `optional:` on a top-level `document.sections` entry '
        'and `text-required` on a content member.',
  ),

  /// The ceiling on a list's item count — the exception rather than the rule,
  /// since a list with no `@Max` is unbounded.
  DocSpecsAnnotationBinding(
    'Max',
    schemaKey: 'max-count',
    owner: DocSpecsOwner.subsectionConstraint,
    note: 'Bounds a list; absent means `infinite`.',
  ),

  /// A floor on the section text that an author has to reach. Distinct from
  /// `@TextRequired`, which asks only that the text be there at all.
  DocSpecsAnnotationBinding(
    'MinLength',
    schemaKey: 'min-text-length',
    owner: DocSpecsOwner.sectionType,
    note: 'Minimum character count of the section text.',
  ),

  /// A ceiling on the section text — the counterpart of `@MinLength`, and like
  /// it a bound on the body and not on the subsections.
  DocSpecsAnnotationBinding(
    'MaxLength',
    schemaKey: 'max-text-length',
    owner: DocSpecsOwner.sectionType,
    note: 'Maximum character count of the section text.',
  ),

  /// How deep subsections may nest under this section type. `0` is the value
  /// that earns it: it declares a leaf type, which nothing else in the model
  /// says.
  DocSpecsAnnotationBinding(
    'MaxDepth',
    schemaKey: 'max-subsection-levels',
    owner: DocSpecsOwner.sectionType,
    note: 'Caps subsection nesting; `0` for a leaf section type.',
  ),

  /// Closes the tag vocabulary of a section type. Absence is the open case
  /// rather than an empty whitelist, so the key is emitted only where the model
  /// actually restricts the set.
  DocSpecsAnnotationBinding(
    'AllowedTags',
    schemaKey: 'allowed-tags',
    owner: DocSpecsOwner.sectionType,
    note: 'Whitelist of inline tags; absent means any tag is allowed.',
  ),

  /// Stage two of heading resolution: the regex a resolved id must match. It is
  /// the author's own rule, so it wins over the check the generator would
  /// otherwise derive from a list's `@SectionIdPattern`.
  DocSpecsAnnotationBinding(
    'PatternCheckId',
    schemaKey: 'pattern-check-id',
    owner: DocSpecsOwner.sectionType,
    note: 'Explicit id-format check; overrides the `@SectionIdPattern`-derived '
        'stem check.',
  ),

  /// A regex over one form field's value — the field-level counterpart of
  /// `@PatternCheckId`, which constrains ids. Applied unanchored, so a
  /// whole-value rule has to anchor itself.
  DocSpecsAnnotationBinding(
    'PatternCheck',
    schemaKey: 'pattern-check',
    owner: DocSpecsOwner.formField,
    note: 'Regex over one form field value.',
  ),

  /// The criterion an AI validator judges a section's content against. The
  /// judgement sees that content alone, so the prompt carries its own context
  /// rather than assuming the surrounding document.
  DocSpecsAnnotationBinding(
    'ValidationPrompt',
    schemaKey: 'validation-prompt',
    owner: DocSpecsOwner.sectionType,
    note: 'AI-assisted validation prompt. Emitted on the section type only — '
        "DocSpecs also allows one per `document.sections` entry, but the "
        'model has a single annotation, so duplicating it there would say the '
        'same thing twice.',
  ),

  /// A closed choice between typed subsections, picked by a model-enum form
  /// field. Keeping the discriminator an enum is what lets case coverage be
  /// checked before any document exists.
  DocSpecsAnnotationBinding(
    'OneOf',
    modelOnly: ModelOnlyReason.generation,
    note: 'A discriminated subsection group. The DocSpecs schema has no '
        'conditional-presence construct, so both arms stay optional there and '
        'the choice is enforced by the runtime `validateDocument`.',
  ),

  /// Binds one subsection to a discriminator constant, and is repeatable. A
  /// subsection carrying no case is common to every case — that absence is a
  /// statement, and an absence has no schema key.
  DocSpecsAnnotationBinding(
    'Case',
    modelOnly: ModelOnlyReason.generation,
    note: 'Binds a subsection to one `@OneOf` discriminator constant; shares '
        "`@OneOf`'s reason.",
  ),

  // --- Cross-references & relationships -------------------------------------
  /// A typed pointer at a section the tree owns elsewhere. The outliner stops
  /// at it rather than recursing, so the target keeps a single home and is
  /// described in the schema once.
  DocSpecsAnnotationBinding(
    'Reference',
    modelOnly: ModelOnlyReason.traceability,
    note: 'A typed pointer at another section class. It adds no section of '
        'its own — the outliner does not recurse into it and the schema has '
        'no cross-reference construct.',
  ),

  /// The key a section is addressed by in the access API, and the value a
  /// `@ForEach` on the matching registry matches against. Only top-level
  /// sections have an entry able to carry it.
  DocSpecsAnnotationBinding(
    'AccessKey',
    schemaKey: 'access-key',
    owner: DocSpecsOwner.documentSection,
    note: 'The key a section is reached by in the DocSpecs access API, '
        'overriding the section name.',
  ),

  /// A 1:1 obligation between a list and a registry section type, in both
  /// directions. The registry must be reachable from the same root, or schema
  /// generation fails rather than emitting a link that validates nothing.
  DocSpecsAnnotationBinding(
    'ForEach',
    schemaKey: 'for-each',
    owner: DocSpecsOwner.documentSection,
    note: 'Links a list section to the registry section type whose entries it '
        'must mirror 1:1, matched by `key`.',
  ),

  // --- Traceability ---------------------------------------------------------
  /// The seed node of a Phase-3 document: the shallowest blueprint class whose
  /// whole subtree flows to that one document. It relates two schemas, so
  /// neither of them is the place to state it.
  DocSpecsAnnotationBinding(
    'MapsTo',
    modelOnly: ModelOnlyReason.traceability,
    note: 'Names the Solution Blueprint seed node for a Phase-3 document — a '
        'relation between two schemas, not a property of either.',
  ),

  /// The take-off point at which a blueprint class becomes a top-level entry of
  /// the target document. It decides which schema a section turns up in — again
  /// a fact about the pair, not a property of either.
  DocSpecsAnnotationBinding(
    'DetailedIn',
    modelOnly: ModelOnlyReason.traceability,
    note: 'Promotes a class to a top-level entry of the target document; '
        'shapes which schema a section appears in, not what it declares.',
  ),

  /// The public standard a section derives from, in the standard's own wording.
  /// Provenance for a reviewer; it constrains nothing an author writes, so it
  /// is not a rule a document can be held to.
  DocSpecsAnnotationBinding(
    'StandardReferences',
    modelOnly: ModelOnlyReason.traceability,
    note: 'The public standard a section derives from. Provenance, not a '
        'constraint on the document.',
  ),

  // --- DocSpecs ↔ CodeSpecs link --------------------------------------------
  /// The type-level DocSpecs to CodeSpecs link: which kinds of code element
  /// every section of this type must be realised as in Phase 4. A statement
  /// about generated code, not about the document.
  DocSpecsAnnotationBinding(
    'CodeSpecKind',
    modelOnly: ModelOnlyReason.traceability,
    note: 'Routes a section type to CodeSpecs part types — a statement about '
        'downstream code generation.',
  ),

  /// The non-CodeSpecs half of the same routing — which downstream processes a
  /// follow-up subtree feeds. With `@CodeSpecKind` and `@NoArtifact` it has to
  /// cover every section of the blueprint.
  DocSpecsAnnotationBinding(
    'FollowUpKind',
    modelOnly: ModelOnlyReason.traceability,
    note: 'The follow-up counterpart of `@CodeSpecKind`; same reason.',
  ),

  /// The verdict that a section feeds nothing downstream. Recording it is what
  /// keeps "produces nothing" distinguishable from "nobody has got round to
  /// routing it yet".
  DocSpecsAnnotationBinding(
    'NoArtifact',
    modelOnly: ModelOnlyReason.traceability,
    note: 'The third routing verdict — records that a section feeds neither '
        'CodeSpecs nor a follow-up process. A statement about downstream '
        'artifacts, not about the document.',
  ),

  /// Marks the projection Phase 4 consumes. It is `@CodeSpecKind`-driven rather
  /// than `@DetailedIn`-driven, which is why it needs exempting from a
  /// detail-count invariant the Phase-3 projections meet by construction.
  DocSpecsAnnotationBinding(
    'CodeSpecsProjection',
    modelOnly: ModelOnlyReason.generation,
    note: 'Marks a `@Document` root as the CodeSpecs generation projection, '
        'exempting it from the detail-count invariant.',
  ),
];

/// Bindings keyed by annotation name.
Map<String, DocSpecsAnnotationBinding> get docSpecsAnnotationBindingsByName =>
    {for (final b in docSpecsAnnotationBindings) b.annotation: b};

/// The schema keys the generator is expected to be able to emit.
Set<String> get boundDocSpecsSchemaKeys => {
      for (final b in docSpecsAnnotationBindings)
        if (b.schemaKey != null) b.schemaKey!,
    };

/// The result of diffing the declared bindings against the annotation classes
/// `tom_specs_core` actually declares.
class AnnotationCatalogueCorrespondence {
  /// Holds the two name sets to be compared.
  ///
  /// Nothing is diffed here: [undeclaredDestination] and [staleBinding]
  /// compute the two directions on demand, so a caller that only wants one of
  /// them pays for one.
  AnnotationCatalogueCorrespondence({
    required this.declared,
    required this.bound,
  });

  /// Annotation class names found in `tom_specs_core/lib/src/annotations/`.
  final Set<String> declared;

  /// Annotation names named by [docSpecsAnnotationBindings].
  final Set<String> bound;

  /// Declared in `tom_specs_core` but absent from the mapping table — an
  /// annotation with no decision about what it means downstream.
  Set<String> get undeclaredDestination => declared.difference(bound);

  /// Named by the mapping table but no longer declared — a stale binding.
  Set<String> get staleBinding => bound.difference(declared);

  /// Whether the two catalogues name the same annotations.
  ///
  /// Both directions must be empty, because they fail differently: an
  /// annotation with no binding is a promise nothing downstream keeps, and a
  /// binding with no annotation points at a class that no longer exists. Use
  /// [describeMismatch] for the report a failing gate should print.
  bool get isConsistent =>
      undeclaredDestination.isEmpty && staleBinding.isEmpty;

  /// A human-readable failure report, or null when consistent.
  String? describeMismatch() {
    if (isConsistent) return null;
    final lines = <String>[];
    if (undeclaredDestination.isNotEmpty) {
      lines.add(
        'Annotations declared in tom_specs_core with no DocSpecs destination '
        'declared in docSpecsAnnotationBindings: '
        '${(undeclaredDestination.toList()..sort()).join(', ')}. '
        'Add a binding — schema-bound with a schemaKey, or model-only with a '
        'ModelOnlyReason.',
      );
    }
    if (staleBinding.isNotEmpty) {
      lines.add(
        'Bindings naming annotations that tom_specs_core no longer declares: '
        '${(staleBinding.toList()..sort()).join(', ')}. Remove them.',
      );
    }
    return lines.join('\n');
  }
}

/// Scans [annotationsDir] (`tom_specs_core/lib/src/annotations/`) for the
/// annotation classes it declares.
///
/// Enums are skipped: they are argument vocabularies (`CodeSpecPart`,
/// `FollowUpProcess`), not annotations, and carry no destination of their own.
Set<String> readDeclaredAnnotationClasses(Directory annotationsDir) {
  if (!annotationsDir.existsSync()) {
    throw ArgumentError(
      'Annotations directory not found: ${annotationsDir.path}',
    );
  }
  final classPattern = RegExp(r'^class\s+(\w+)\b');
  final names = <String>{};
  for (final entity in annotationsDir.listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    // The barrel re-exports the siblings; it declares nothing.
    if (entity.uri.pathSegments.last == 'annotations.dart') continue;
    for (final line in entity.readAsLinesSync()) {
      final match = classPattern.firstMatch(line);
      if (match != null) names.add(match.group(1)!);
    }
  }
  return names;
}

/// Compares the declared annotation classes against the mapping table.
AnnotationCatalogueCorrespondence checkAnnotationCatalogue(
  Directory annotationsDir,
) =>
    AnnotationCatalogueCorrespondence(
      declared: readDeclaredAnnotationClasses(annotationsDir),
      bound: docSpecsAnnotationBindingsByName.keys.toSet(),
    );
