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
  DocSpecsAnnotationBinding(
    'SectionId',
    schemaKey: 'prefix',
    owner: DocSpecsOwner.sectionType,
    note: 'Names the section type (id lower-cased) and, with the TomSpecs '
        'dashes transformed to `_`, supplies the default prefix.',
  ),
  DocSpecsAnnotationBinding(
    'SectionIdPattern',
    schemaKey: 'pattern-check-id',
    owner: DocSpecsOwner.sectionType,
    note: 'The pattern with `xxx` compiled to `.+`; an explicit '
        '`@PatternCheckId` overrides it.',
  ),
  DocSpecsAnnotationBinding(
    'Document',
    schemaKey: 'title-format',
    owner: DocSpecsOwner.schema,
    note: 'Marks the root: its `name` becomes the schema id and the '
        '`title-format` custom tag.',
  ),
  DocSpecsAnnotationBinding(
    'Prefix',
    schemaKey: 'prefix',
    owner: DocSpecsOwner.sectionType,
    note: 'Overrides the section-id-derived prefix for two-stage heading '
        'resolution.',
  ),
  DocSpecsAnnotationBinding(
    'Position',
    schemaKey: 'position',
    owner: DocSpecsOwner.subsectionDeclaration,
    note: "`first` / `last` / `any`; emitted into the root's "
        '`subsection-declarations` block.',
  ),
  DocSpecsAnnotationBinding(
    'SerializationOrder',
    modelOnly: ModelOnlyReason.generation,
    note: 'Pins on-disk member order across the nine runtimes. Document '
        'section order is carried by the schema structure itself.',
  ),

  // --- Content typing & authoring -------------------------------------------
  DocSpecsAnnotationBinding(
    'ContentType',
    schemaKey: 'format',
    owner: DocSpecsOwner.sectionType,
    note: 'Code/diagram content types become `format`; plain text carries '
        'none (a `format` makes the validator demand a fenced block).',
  ),
  DocSpecsAnnotationBinding(
    'Form',
    schemaKey: 'format',
    owner: DocSpecsOwner.sectionType,
    note: 'Emits a `form-types` entry and points `format` at it.',
  ),
  DocSpecsAnnotationBinding(
    'Field',
    schemaKey: 'fieldname',
    owner: DocSpecsOwner.formField,
    note: 'One `@Form` field: name, `required`, and `description` from the '
        'author hint.',
  ),
  DocSpecsAnnotationBinding(
    'ContentHelp',
    schemaKey: 'description',
    owner: DocSpecsOwner.sectionType,
    note: 'Preferred over the doc comment.',
  ),
  DocSpecsAnnotationBinding(
    'Headline',
    schemaKey: 'title-format',
    owner: DocSpecsOwner.schema,
    note: 'A root-class headline wins over the `@Document` name in the '
        '`title-format` custom tag (YRD4).',
  ),
  DocSpecsAnnotationBinding(
    'TextRequired',
    schemaKey: 'text-required',
    owner: DocSpecsOwner.sectionType,
    note: 'Also implied by `@Min(1)` on a content member.',
  ),
  DocSpecsAnnotationBinding(
    'Unused',
    modelOnly: ModelOnlyReason.structural,
    note: 'Omits the node and its subtree from the schema entirely — an '
        'absence, not a property.',
  ),
  DocSpecsAnnotationBinding(
    'Comment',
    modelOnly: ModelOnlyReason.generation,
    note: 'Free-form metadata for downstream generators (e.g. the CodeSpecs '
        'projection loci).',
  ),

  // --- Constraints & validation ---------------------------------------------
  DocSpecsAnnotationBinding(
    'Min',
    schemaKey: 'min-count',
    owner: DocSpecsOwner.subsectionConstraint,
    note: 'Also drives `optional:` on a top-level `document.sections` entry '
        'and `text-required` on a content member.',
  ),
  DocSpecsAnnotationBinding(
    'Max',
    schemaKey: 'max-count',
    owner: DocSpecsOwner.subsectionConstraint,
    note: 'Bounds a list; absent means `infinite`.',
  ),
  DocSpecsAnnotationBinding(
    'MinLength',
    schemaKey: 'min-text-length',
    owner: DocSpecsOwner.sectionType,
    note: 'Minimum character count of the section text.',
  ),
  DocSpecsAnnotationBinding(
    'MaxLength',
    schemaKey: 'max-text-length',
    owner: DocSpecsOwner.sectionType,
    note: 'Maximum character count of the section text.',
  ),
  DocSpecsAnnotationBinding(
    'MaxDepth',
    schemaKey: 'max-subsection-levels',
    owner: DocSpecsOwner.sectionType,
    note: 'Caps subsection nesting; `0` for a leaf section type.',
  ),
  DocSpecsAnnotationBinding(
    'AllowedTags',
    schemaKey: 'allowed-tags',
    owner: DocSpecsOwner.sectionType,
    note: 'Whitelist of inline tags; absent means any tag is allowed.',
  ),
  DocSpecsAnnotationBinding(
    'PatternCheckId',
    schemaKey: 'pattern-check-id',
    owner: DocSpecsOwner.sectionType,
    note: 'Explicit id-format check; overrides the `@SectionIdPattern`-derived '
        'stem check.',
  ),
  DocSpecsAnnotationBinding(
    'PatternCheck',
    schemaKey: 'pattern-check',
    owner: DocSpecsOwner.formField,
    note: 'Regex over one form field value.',
  ),
  DocSpecsAnnotationBinding(
    'ValidationPrompt',
    schemaKey: 'validation-prompt',
    owner: DocSpecsOwner.sectionType,
    note: 'AI-assisted validation prompt. Emitted on the section type only — '
        "DocSpecs also allows one per `document.sections` entry, but the "
        'model has a single annotation, so duplicating it there would say the '
        'same thing twice.',
  ),
  DocSpecsAnnotationBinding(
    'OneOf',
    modelOnly: ModelOnlyReason.generation,
    note: 'A discriminated subsection group. The DocSpecs schema has no '
        'conditional-presence construct, so both arms stay optional there and '
        'the choice is enforced by the runtime `validateDocument`.',
  ),
  DocSpecsAnnotationBinding(
    'Case',
    modelOnly: ModelOnlyReason.generation,
    note: 'Binds a subsection to one `@OneOf` discriminator constant; shares '
        "`@OneOf`'s reason.",
  ),

  // --- Cross-references & relationships -------------------------------------
  DocSpecsAnnotationBinding(
    'Reference',
    modelOnly: ModelOnlyReason.traceability,
    note: 'A typed pointer at another section class. It adds no section of '
        'its own — the outliner does not recurse into it and the schema has '
        'no cross-reference construct.',
  ),
  DocSpecsAnnotationBinding(
    'AccessKey',
    schemaKey: 'access-key',
    owner: DocSpecsOwner.documentSection,
    note: 'The key a section is reached by in the DocSpecs access API, '
        'overriding the section name.',
  ),
  DocSpecsAnnotationBinding(
    'ForEach',
    schemaKey: 'for-each',
    owner: DocSpecsOwner.documentSection,
    note: 'Links a list section to the registry section type whose entries it '
        'must mirror 1:1, matched by `key`.',
  ),

  // --- Traceability ---------------------------------------------------------
  DocSpecsAnnotationBinding(
    'MapsTo',
    modelOnly: ModelOnlyReason.traceability,
    note: 'Names the Solution Blueprint seed node for a Phase-3 document — a '
        'relation between two schemas, not a property of either.',
  ),
  DocSpecsAnnotationBinding(
    'DetailedIn',
    modelOnly: ModelOnlyReason.traceability,
    note: 'Promotes a class to a top-level entry of the target document; '
        'shapes which schema a section appears in, not what it declares.',
  ),
  DocSpecsAnnotationBinding(
    'StandardReferences',
    modelOnly: ModelOnlyReason.traceability,
    note: 'The public standard a section derives from. Provenance, not a '
        'constraint on the document.',
  ),

  // --- DocSpecs ↔ CodeSpecs link --------------------------------------------
  DocSpecsAnnotationBinding(
    'CodeSpecKind',
    modelOnly: ModelOnlyReason.traceability,
    note: 'Routes a section type to CodeSpecs part types — a statement about '
        'downstream code generation.',
  ),
  DocSpecsAnnotationBinding(
    'FollowUpKind',
    modelOnly: ModelOnlyReason.traceability,
    note: 'The follow-up counterpart of `@CodeSpecKind`; same reason.',
  ),
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
