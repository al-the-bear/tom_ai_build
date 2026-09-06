/// In-memory representation of the exported TomSpecs class graph (the
/// spec-model meta-data file produced by `tom_specs_clitool/bin/model_json.dart`,
/// schema documented in
/// `tom_ai/ai_build/tom_specs_model/doc/tom_specs_model_meta_schema.md`).
///
/// The model is a *class graph*, not an expanded tree: each class appears once
/// and field `elementType` / `type` references are followed on demand by a
/// traversal (which does its own cycle detection). This is the "reflection"
/// surface — it describes any document's structure, independent of the values a
/// concrete [SpecDocument] holds.
library;

/// The render kind of a field, mirroring the exporter's classification.
enum SpecFieldKind {
  /// A `List<T>` member. The kind-specific keys are [SpecField.elementType],
  /// [SpecField.elementIsComplex] and [SpecField.min]; in markdown the field
  /// heads a `-LST` container heading whose items nest one level deeper
  /// (SOM §11.5), so a path cannot descend through it without an item suffix.
  list,

  /// A `@Form` member. [SpecField.formFields] carries the declared fields in
  /// model order, and the section body is `FieldName: value` lines rather
  /// than prose (SOM §11.4) — which is why free-text length rules do not
  /// apply to it.
  form,

  /// A section-typed member: a content leaf whose declared wrapper class is
  /// named by [SpecField.sectionType] (`TextSection`, `FlowDiagramSection`,
  /// …) and whose render classification is [SpecField.contentType]. The
  /// wrapper classes live in `tom_specs_core` and are deliberately *not*
  /// exported into [SpecModel.classes], so a traversal must treat this as a
  /// leaf rather than trying to resolve the name.
  section,

  /// A plain `String` member rendered as markdown prose under its own
  /// heading (SOM §11.3). [SpecField.contentType] distinguishes ordinary
  /// `text` from the fenced variants (`mermaid`, `code-dart`, …).
  content,

  /// An enum-typed member. Named `enumValue` rather than `enum` only because
  /// `enum` is a Dart keyword — the wire spelling is `enum`, which is why
  /// [parse] has to translate it. [SpecField.enumType] and
  /// [SpecField.enumValues] carry the constant set.
  enumValue,

  /// A member whose type is another *exported* model class, i.e. one present
  /// in [SpecModel.classes]. Unlike [section] this is the kind a traversal
  /// descends through, resolving [SpecField.type] against the class graph.
  complex,

  /// A primitive leaf (`int`, `double`, `bool`, `num`, `DateTime`), typed by
  /// [SpecField.type]. Also the fallback [parse] returns for any unrecognised
  /// kind name, so a snapshot from a newer exporter degrades to a renderable
  /// leaf instead of failing to load.
  scalar;

  /// Maps the meta file's `kind` string onto a constant, translating the wire
  /// spelling `enum` to [enumValue].
  ///
  /// Deliberately total: an unrecognised name yields [scalar] rather than
  /// throwing, because the meta file is a forward-compatible asset (SOM §20)
  /// and one unknown kind must not make a whole snapshot unloadable.
  static SpecFieldKind parse(String raw) {
    switch (raw) {
      case 'list':
        return SpecFieldKind.list;
      case 'form':
        return SpecFieldKind.form;
      case 'section':
        return SpecFieldKind.section;
      case 'content':
        return SpecFieldKind.content;
      case 'enum':
        return SpecFieldKind.enumValue;
      case 'complex':
        return SpecFieldKind.complex;
      default:
        return SpecFieldKind.scalar;
    }
  }
}

/// A single annotation captured losslessly from the model source (SOM §5.3):
/// its name and the resolved argument map (`{ '<arg>': <value> }`). This is the
/// `annotations[]` block emitted by `ModelJsonExporter` — the superset the
/// curated convenience accessors ([SpecClass.sectionId], [SpecField.min], …)
/// are projected from.
class SpecAnnotation {
  /// The annotation's source name **without** the `@` — `SectionId`, not
  /// `@SectionId`. Every lookup on [AnnotatedSpecNode] matches on this string
  /// exactly, so it is the stable key the whole annotation surface turns on.
  final String name;

  /// The resolved argument map, keyed by the *declared parameter name* — the
  /// exporter names positional arguments too, so `@Case(Kind.x)` reads as
  /// `{'value': …}`. Values are the analyzer's resolved constants
  /// (String / int / double / bool / type-name / List), never expressions, so
  /// the map stays JSON-serializable.
  ///
  /// Empty for a marker annotation such as `@Unused`, where presence is the
  /// whole statement.
  final Map<String, Object?> arguments;

  /// [name] is required because an unnamed annotation cannot be looked up;
  /// [arguments] defaults to empty so argumentless markers construct without
  /// ceremony.
  const SpecAnnotation({required this.name, this.arguments = const {}});

  /// Reads one `annotations[]` entry. A missing `arguments` key is read as
  /// empty rather than as an error — the exporter omits it for markers.
  factory SpecAnnotation.fromJson(Map<String, dynamic> j) => SpecAnnotation(
        name: j['name'] as String,
        arguments: (j['arguments'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  /// The argument named [key], or `null` when absent.
  Object? argument(String key) => arguments[key];

  /// Reads a whole `annotations` block, preserving source order — which
  /// matters because repeatable annotations such as `@Case` are read as a
  /// sequence by [AnnotatedSpecNode.annotationsNamed].
  ///
  /// Accepts `null` and returns the empty list: the exporter omits the block
  /// entirely when a node carries no annotations, so absent and empty must
  /// load identically.
  static List<SpecAnnotation> listFromJson(Object? raw) =>
      (raw as List?)
          ?.map((e) => SpecAnnotation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];
}

/// A single form field within a `@Form` content section.
class FormFieldSpec {
  /// The declared field name. This is the *machine* identity: it is the
  /// storage key, and — first letter upper-cased — the `FieldName:` label the
  /// markdown form format writes and matches case-insensitively
  /// (SOM §11.4 rule 1). Renaming it breaks stored documents.
  final String name;

  /// The human-facing caption: the field's declared description, or a
  /// PascalCase split of [name] when none was authored. Never `null`, so a
  /// renderer needs no fallback of its own — but it is display text only and
  /// must not be used as a key.
  final String label;

  /// Author-facing guidance for filling the field in, or `null` when none was
  /// declared. Omitted from the export when empty, so `null` and "no hint"
  /// are the same state.
  final String? hint;

  /// The declared Dart type name (`String`, `int`, an enum type, …), defaulted
  /// to `String` on load. Consumers convert values against this — with
  /// [enumValues] supplying the legal set when it names a model enum.
  final String type;

  /// Whether the field must be filled in.
  ///
  /// Nothing in this class enforces it — the flag is carried into the meta
  /// tree and into the generated schema's `required:`, where the DocSpecs
  /// instance tier turns an absent or empty value into a
  /// `missingRequiredField` violation. It is a statement about a *filled*
  /// document; an unfilled model is not thereby invalid.
  final bool required;

  /// Enum constant names when [type] is a model enum (YRD7); empty for
  /// non-enum field types. Lets consumers validate and convert values
  /// without the analyzer.
  final List<String> enumValues;

  /// The registry key(s) this field's value is an id drawn from, each written
  /// `<SECTIONID>.<formFieldName>` (csrb3); empty for a non-reference field. A
  /// reference field holds a free-text id that must already be declared by some
  /// entry of the named registry, so a runtime can resolve it and report a
  /// dangling id instead of generating broken code.
  final List<String> refersTo;

  /// Only [name], [label] and [type] are required — the three a form line
  /// cannot be written without. Everything else defaults to the "nothing was
  /// declared" state: no [hint], not [required], and empty [enumValues] /
  /// [refersTo], each of which the export omits rather than emitting empty.
  FormFieldSpec({
    required this.name,
    required this.label,
    required this.type,
    this.hint,
    this.required = false,
    this.enumValues = const [],
    this.refersTo = const [],
  });

  /// Reads one `formFields[]` entry
  /// (`tom_specs_model_meta_schema.md`, "`formFields[]` entry").
  ///
  /// Every optional key degrades rather than throws: an absent `label` falls
  /// back to [name], an absent `type` to `String`, an absent `required` to
  /// `false`. `enumValues` / `refersTo` are stringified element-wise so a
  /// numerically-spelled entry still loads.
  factory FormFieldSpec.fromJson(Map<String, dynamic> j) => FormFieldSpec(
        name: j['name'] as String,
        label: j['label'] as String? ?? j['name'] as String,
        hint: j['hint'] as String?,
        type: j['type'] as String? ?? 'String',
        required: j['required'] as bool? ?? false,
        enumValues:
            (j['enumValues'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        refersTo:
            (j['refersTo'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );
}

/// A list-valued taxonomy annotation: a set of enum codes plus an optional
/// explanatory note.
///
/// The model states where a subtree is headed with two such annotations, which
/// share this shape exactly — `@CodeSpecKind(List<CodeSpecPart>, {note})` names
/// the CodeSpecs part(s) a section type must be realised as
/// (`codespecs_mapping.md` §9.1/§9.5), and
/// `@FollowUpKind(List<FollowUpProcess>, {note})` names the downstream
/// *process(es)* a non-code subtree feeds (codespecs_mapping.md §8.3). One
/// reader serves both; which annotation a link came from is expressed by which
/// accessor produced it.
///
/// Obtaining a link at all means the annotation is present. That matters: a
/// node with no link has not been classified yet, whereas a link with empty
/// [kinds] is a recorded decision that the section belongs to no member of that
/// taxonomy. The two are different statements, so they are different values
/// rather than one nullable list.
class KindLink {
  /// The enum code names with their type prefix stripped — `validation`, not
  /// `CodeSpecPart.validation`; `doc`, not `FollowUpProcess.doc`.
  ///
  /// Both annotations are list-valued because one section can be realised as
  /// several parts, or feed several processes; consumers must handle all of
  /// them, not just the first.
  final List<String> kinds;

  /// The annotation's free-text `note`, explaining the classification.
  final String? note;

  /// Both arguments are optional, because *constructing* the link is already
  /// the statement that the annotation was present: a link with no [kinds]
  /// and no [note] records a classification that resolved to no member of the
  /// taxonomy, which is a different fact from having no link at all.
  const KindLink({this.kinds = const [], this.note});

  /// Reads a link out of [annotation], taking the code list from the argument
  /// named [listArgument] — `kinds` for `@CodeSpecKind`, `processes` for
  /// `@FollowUpKind`.
  factory KindLink.fromAnnotation(
    SpecAnnotation annotation, {
    required String listArgument,
  }) {
    final raw = annotation.argument(listArgument);
    return KindLink(
      kinds: raw is List
          ? [
              for (final k in raw)
                if (k != null) _stripEnumPrefix(k.toString()),
            ]
          : const [],
      note: annotation.argument('note') as String?,
    );
  }

}

/// The third routing verdict: `@NoArtifact(NoArtifactReason, {note})` — the
/// section feeds neither a CodeSpecs part nor a follow-up process
/// (`codespecs_mapping.md` §8.3).
///
/// Single-valued where [KindLink] is a list, and the asymmetry is the point: a
/// section can feed several parts or several processes at once, but it is
/// unrouted for exactly one reason. That reason is what makes the absence of
/// the other two markers readable as a decision rather than an omission, which
/// is what `tom_specs_model_rules.md` §10.2 invariant `ROUTE-TOTAL` checks.
class NoArtifactLink {
  /// The `NoArtifactReason` code name with its type prefix stripped —
  /// `container`, not `NoArtifactReason.container`. One of `container`,
  /// `overview`, `view`.
  final String reason;

  /// The annotation's free-text `note`. On an `overview` this customarily names
  /// the routed section that states the material normatively.
  final String? note;

  /// [reason] is required and [note] is not, mirroring the annotation: the
  /// verdict is only readable as a decision if it says *why*, whereas the
  /// prose gloss is optional. [NoArtifactLink.fromAnnotation] accordingly
  /// substitutes `container` for a missing argument rather than admitting a
  /// reasonless verdict.
  const NoArtifactLink({required this.reason, this.note});

  /// Reads the verdict out of [annotation].
  factory NoArtifactLink.fromAnnotation(SpecAnnotation annotation) =>
      NoArtifactLink(
        reason: _stripEnumPrefix(
            annotation.argument('reason')?.toString() ?? 'container'),
        note: annotation.argument('note') as String?,
      );
}

/// `CodeSpecPart.validation` → `validation`. A name already given bare is
/// returned unchanged, so readers do not depend on how the exporter chose to
/// spell the enum constant. Splitting on the last dot rather than a fixed
/// prefix keeps this working for any code enum the model adds.
String _stripEnumPrefix(String raw) {
  final dot = raw.lastIndexOf('.');
  return dot < 0 ? raw : raw.substring(dot + 1);
}

/// The provenance recorded by `@StandardReferences(standards, connotation)`:
/// which public standard(s) a section or field derives from, and what the
/// section *means*.
///
/// Distinct from the author-facing `@ContentHelp` guidance — [connotation]
/// states intent and ownership ("what this section is"), not "how to fill it
/// in". The exporter emits it as a curated top-level key rather than leaving it
/// to be dug out of the annotation list, so this reads that key.
class StandardReferences {
  /// The standards this node traces back to; each entry is the standard's ID
  /// plus the clause in the standard's own wording.
  final List<String> standards;

  /// What the section means — its intent / what it owns.
  final String? connotation;

  /// Both halves are optional and independent: `@StandardReferences` is used
  /// both to cite standards without glossing them and to state a
  /// [connotation] for a node that traces to no published standard, so
  /// neither can be required without rejecting a legitimate annotation.
  const StandardReferences({this.standards = const [], this.connotation});

  /// Returns `null` for a missing block, so absent provenance stays
  /// distinguishable from provenance recorded as empty.
  static StandardReferences? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return StandardReferences(
      standards: (raw['standards'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      connotation: raw['connotation'] as String?,
    );
  }
}

/// Shared behaviour of the two model nodes that carry annotations — classes and
/// fields. Keeps the annotation lookups defined once instead of per node type.
mixin AnnotatedSpecNode {
  /// The lossless annotation list captured on this node (SOM §5.3).
  List<SpecAnnotation> get annotations;

  /// The `@StandardReferences` provenance block, or `null` when unannotated.
  StandardReferences? get standardReferences;

  /// The annotation named [name], or `null` when absent.
  SpecAnnotation? annotation(String name) {
    for (final a in annotations) {
      if (a.name == name) return a;
    }
    return null;
  }

  /// Every annotation named [name], in source order — empty when absent.
  ///
  /// Distinct from [annotation] because some annotations are *repeatable*:
  /// `@Case` is applied once per discriminator value, so a single field can
  /// carry several. Reading only the first would silently drop the rest.
  List<SpecAnnotation> annotationsNamed(String name) =>
      [for (final a in annotations) if (a.name == name) a];

  /// Whether the annotation named [name] is present. For markers that carry no
  /// arguments, presence *is* the whole statement.
  bool hasAnnotation(String name) => annotation(name) != null;

  /// Whether `@Unused` marks this node as carrying no authored content — the
  /// section is a structural container only, and tooling ignores any text.
  ///
  /// The annotation is argumentless, so presence is the whole statement.
  bool get isUnused => hasAnnotation('Unused');

  /// The `@Comment(text)` inline note, or `null`.
  ///
  /// Several of these carry the `locus: shared|client|server` grouping that
  /// drives the `codespecs_mapping.md` §4.2 project split, so the text is a
  /// structural statement rather than decoration.
  String? get comment => annotation('Comment')?.argument('text') as String?;

  /// The `@Reference(description)` label when this node points at data owned
  /// elsewhere in the model tree, or `null`.
  String? get reference =>
      annotation('Reference')?.argument('description') as String?;

  /// Whether this node carries provenance of either kind — the `@Reference`
  /// cross-link or the `@StandardReferences` block. Lets a consumer decide
  /// whether a references affordance has anything to show.
  bool get hasReferences => reference != null || standardReferences != null;

  /// The `@CodeSpecKind` link, or `null` when this node carries no such
  /// annotation. See [KindLink] for why absent and empty differ.
  KindLink? get codeSpecKind => _link('CodeSpecKind', 'kinds');

  /// The `@FollowUpKind` link, or `null` when this node carries no such
  /// annotation — which downstream process(es) this subtree feeds instead of
  /// becoming CodeSpecs code (codespecs_mapping.md §8.3).
  KindLink? get followUpKind => _link('FollowUpKind', 'processes');

  /// The `@NoArtifact` verdict, or `null` when this node carries no such
  /// annotation — the recorded decision that the section produces nothing
  /// downstream (`codespecs_mapping.md` §8.3).
  NoArtifactLink? get noArtifact {
    final a = annotation('NoArtifact');
    return a == null ? null : NoArtifactLink.fromAnnotation(a);
  }

  KindLink? _link(String name, String listArgument) {
    final a = annotation(name);
    return a == null
        ? null
        : KindLink.fromAnnotation(a, listArgument: listArgument);
  }
}

/// A single field of a [SpecClass].
class SpecField with AnnotatedSpecNode {
  /// The exact source member name. It is the path segment a resolver matches
  /// on when the field declares no [sectionId] (SOM §7.1), so it is part of
  /// the stored document's addressing grammar, not merely a label.
  final String name;

  /// How the field renders and which of the kind-specific members below are
  /// populated — see [SpecFieldKind] for the per-kind key sets. A traversal
  /// must branch on this before reading [type] / [elementType] /
  /// [formFields], because only one group is ever filled.
  final SpecFieldKind kind;

  /// The cleaned `///` doc comment from the model source, or `null`. Written
  /// for a developer reading the model; [help] is what an *author* filling
  /// the section in is shown.
  final String? doc;

  /// The `@ContentHelp(guidance)` authoring guidance, or `null`. Distinct
  /// from [doc]: this is instruction for whoever fills the section in, and it
  /// is also what the schema generator emits as the section-type's
  /// `description:` (SOM §13).
  final String? help;

  /// The `@Headline(text)` default headline (YRD4), or `null`. Render
  /// precedence: stored headline > this default > name derivation.
  final String? headline;
  /// The field-level `@SectionId`, or `null` when the member declares none.
  ///
  /// When present it both keys the markdown heading comment
  /// (`<!--[<id>]-->`) and replaces [name] as the path segment. When absent
  /// the member is *transparent* — it keys on its target class's own section
  /// id while still pathing on [name] (SOM §7.1, SOM §11.6).
  final String? sectionId;

  /// The `@SectionIdPattern` the field's *items* take (e.g. `GOAL-ITEM-xxx`),
  /// or `null`.
  ///
  /// Independent of [sectionId], not a fallback for it: a list field
  /// routinely carries both — its own id and the pattern its elements are
  /// numbered under — so a consumer must read the pair
  /// (`tom_specs_model_meta_schema.md`, "`fields[]` entry"). The generated
  /// schema compiles the `xxx` stem to `.+`, so any id that keeps the stem
  /// validates (SOM §13).
  final String? sectionIdPattern;

  /// The member's serialization ordinal from `@SerializationOrder(n)` (SOM
  /// source declaration order), or `null` when unannotated. Drives the YAML
  /// member emission order (AA1 criterion 7).
  final int? serializationOrder;

  // list
  /// For [SpecFieldKind.list], the element's type name; `null` otherwise.
  ///
  /// Resolve it against [SpecModel.classes] only when [elementIsComplex] —
  /// otherwise it names a scalar to render directly.
  final String? elementType;

  /// Whether [elementType] names an exported model class (descend into it)
  /// rather than a scalar (render it).
  ///
  /// Carried explicitly instead of being inferred from a class-graph lookup
  /// so the eight non-Dart runtimes need no lookup at all, and so a
  /// truncated snapshot cannot silently turn a complex element into a scalar
  /// (`tom_specs_model_meta_schema.md`, "`fields[]` entry").
  final bool elementIsComplex;

  /// The `@Min(count)` minimum item count for a list, or `null` when
  /// unconstrained.
  ///
  /// Instance-tier only: the model is not invalid for having fewer, a
  /// *filled document* is — `validateDocument` reports a shortfall as a
  /// `minItems` error. It is also what the schema generator writes as the
  /// subsection `min-count` (SOM §13).
  final int? min;

  // section / content
  /// The `@ContentType(type)` render classification of a section-kind or
  /// content-kind field — `text` by default, else a fenced form such as
  /// `mermaid`, `mermaid-flow` or `code-dart`. `null` for every other kind.
  ///
  /// A renderer that ignores it will emit a diagram body as prose, and the
  /// generated schema turns the non-`text` values into a `format:` that
  /// *demands* a fenced block.
  final String? contentType;

  /// For [SpecFieldKind.section], the declared wrapper class name with any
  /// `?` stripped (`TextSection`, `FlowDiagramSection`, …); `null` otherwise.
  ///
  /// These wrappers belong to `tom_specs_core` and are deliberately absent
  /// from [SpecModel.classes], so this is descriptive metadata — not a name
  /// to look up. A section is a content leaf; [contentType] is what decides
  /// how it renders.
  final String? sectionType;

  // enum
  /// The Dart enum type name backing an `enum` field (e.g. `Probability`), or
  /// `null` for non-enum fields. Mirrors the exporter's `enumType` key.
  final String? enumType;
  /// The enum's constant names in declaration order, empty for a non-enum
  /// field. Declaration order is load-bearing: [OneOfGroup] reports case
  /// coverage against this sequence so the result reads against the enum a
  /// reviewer is checking.
  final List<String> enumValues;

  // complex / scalar
  /// The declared type name with any `?` stripped, for
  /// [SpecFieldKind.complex] and [SpecFieldKind.scalar] fields only; `null`
  /// for every other kind — notably for a section, whose class name lives in
  /// [sectionType], and for a list, whose element name lives in
  /// [elementType].
  ///
  /// For a complex field this is the key to look up in [SpecModel.classes] to
  /// descend; for a scalar it is a primitive name (`int`, `bool`, `DateTime`,
  /// …) to convert against.
  final String? type;

  // form
  /// The `@Form` fields of a [SpecFieldKind.form] field, in **model
  /// declaration order**; empty for every other kind.
  ///
  /// The order is the on-disk emission order of the form lines (SOM §11.4),
  /// so it must be preserved rather than sorted. No entry ever restates the
  /// section's title or id — those live solely in the heading and its id
  /// comment.
  final List<FormFieldSpec> formFields;

  /// The lossless annotation list captured on this field (SOM §5.3).
  @override
  final List<SpecAnnotation> annotations;

  @override
  final StandardReferences? standardReferences;

  /// Only [name] and [kind] are required: they are the two every exported
  /// field carries, and [kind] is what tells a reader which of the optional
  /// groups below it may consult.
  ///
  /// Every remaining argument is kind-specific and defaults to the "not
  /// applicable / not annotated" state, so constructing a field of one kind
  /// never forces null placeholders for another kind's keys. Nothing here
  /// cross-checks kind against the group actually supplied — the exporter is
  /// the authority on that, and a hand-built field that mixes them will
  /// simply be ignored by the traversal that branches on [kind].
  SpecField({
    required this.name,
    required this.kind,
    this.doc,
    this.help,
    this.headline,
    this.sectionId,
    this.sectionIdPattern,
    this.serializationOrder,
    this.elementType,
    this.elementIsComplex = false,
    this.min,
    this.contentType,
    this.sectionType,
    this.enumType,
    this.enumValues = const [],
    this.type,
    this.formFields = const [],
    this.annotations = const [],
    this.standardReferences,
  });

  /// Reads one `fields[]` entry
  /// (`tom_specs_model_meta_schema.md`, "`fields[]` entry").
  ///
  /// `name` and `kind` are the only keys read as mandatory — an entry missing
  /// either throws, because a nameless or kindless field cannot be addressed
  /// or rendered. Every other key is optional and absent means "not
  /// annotated"; unrecognised kind strings degrade via
  /// [SpecFieldKind.parse] rather than failing the load.
  factory SpecField.fromJson(Map<String, dynamic> j) {
    return SpecField(
      name: j['name'] as String,
      kind: SpecFieldKind.parse(j['kind'] as String),
      doc: j['doc'] as String?,
      help: j['help'] as String?,
      headline: j['headline'] as String?,
      sectionId: j['sectionId'] as String?,
      sectionIdPattern: j['sectionIdPattern'] as String?,
      serializationOrder: (j['serializationOrder'] as num?)?.toInt(),
      elementType: j['elementType'] as String?,
      elementIsComplex: j['elementIsComplex'] as bool? ?? false,
      min: j['min'] as int?,
      contentType: j['contentType'] as String?,
      sectionType: j['sectionType'] as String?,
      enumType: j['enumType'] as String?,
      enumValues:
          (j['enumValues'] as List?)?.map((e) => e.toString()).toList() ??
              const [],
      type: j['type'] as String?,
      formFields: (j['formFields'] as List?)
              ?.map((e) => FormFieldSpec.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      annotations: SpecAnnotation.listFromJson(j['annotations']),
      standardReferences:
          StandardReferences.fromJson(j['standardReferences']),
    );
  }

  /// Whether expanding this field reveals further tree nodes.
  bool get isExpandable =>
      kind == SpecFieldKind.list || kind == SpecFieldKind.complex;

  /// The discriminator values this subsection is bound to by `@Case`, with
  /// their enum prefix stripped — empty when the field carries no `@Case`.
  ///
  /// `@Case` is repeatable, so this is a list rather than a single value: one
  /// subsection may serve several kinds. Per `codespecs_mapping.md` §8.2 an
  /// empty result means *common* — the subsection applies to every case — not
  /// "unassigned".
  List<String> get caseValues => [
        for (final a in annotationsNamed('Case'))
          if (a.argument('value') != null)
            _stripEnumPrefix(a.argument('value').toString()),
      ];

  /// Whether this field is one alternative of a closed choice, as opposed to a
  /// section common to every case.
  bool get isCase => caseValues.isNotEmpty;
}

/// A closed choice declared by `@OneOf` on a container class
/// (`codespecs_mapping.md` §8.2): a set of mutually exclusive subsections of
/// which exactly one applies, selected by a discriminator form-field.
///
/// The group is the strongest structural statement the model makes about a set
/// of sibling fields, and the question it invites — *is the case set complete,
/// and is closure right here?* — is only answerable when the discriminator's
/// full value set is visible next to the values actually covered. Hence
/// [coveredValues] / [uncoveredValues] rather than just the case fields.
class OneOfGroup {
  /// The name of the `@Form` form-field whose value selects the alternative.
  final String discriminator;

  /// The annotation's free-text `note`, explaining the closed choice.
  final String? note;

  /// The resolved discriminator form-field, or `null` when the named field
  /// cannot be found on the class.
  final FormFieldSpec? discriminatorField;

  /// The `@Case`-annotated fields, in declaration order. Common (uncased)
  /// fields are deliberately excluded — they are not alternatives.
  final List<SpecField> caseFields;

  /// [discriminator] and [caseFields] are required — they are the choice
  /// itself, and a group without them says nothing. [discriminatorField] is
  /// optional so that an *unresolvable* discriminator still yields a group
  /// rather than nothing at all — the case fields stay visible for review.
  ///
  /// Note the consequence: with no resolved field, [discriminatorValues] is
  /// empty and every coverage answer is therefore vacuous — [isComplete]
  /// reads `true`. A caller judging coverage must check
  /// [discriminatorValues] is non-empty first.
  const OneOfGroup({
    required this.discriminator,
    required this.caseFields,
    this.note,
    this.discriminatorField,
  });

  /// Every value the discriminator enum admits, in enum order. Empty when the
  /// discriminator could not be resolved or is not an enum.
  List<String> get discriminatorValues =>
      discriminatorField?.enumValues ?? const [];

  /// The discriminator values some case field claims, in *enum* order so the
  /// coverage reads against the enum a reviewer is checking.
  ///
  /// Defined as "enum values that are cased" rather than "case values seen":
  /// a case value outside the enum then shows up as a coverage shortfall
  /// instead of inflating the count.
  List<String> get coveredValues {
    final claimed = {for (final f in caseFields) ...f.caseValues};
    return [
      for (final v in discriminatorValues)
        if (claimed.contains(v)) v,
    ];
  }

  /// The discriminator values no case field claims, in enum order.
  ///
  /// codespecs_mapping.md §8.2 makes an uncovered case a *warning*, not an
  /// error — a kind with no attributes yet is legal — so this is information
  /// for the reviewer to judge, not a defect to flag.
  List<String> get uncoveredValues {
    final claimed = {for (final f in caseFields) ...f.caseValues};
    return [
      for (final v in discriminatorValues)
        if (!claimed.contains(v)) v,
    ];
  }

  /// Whether every discriminator value is covered by some case field.
  bool get isComplete => uncoveredValues.isEmpty;
}

/// A model class with its fields.
class SpecClass with AnnotatedSpecNode {
  /// The exact source class name. This is the key the class is filed under in
  /// [SpecModel.classes] and the value [SpecField.type] /
  /// [SpecField.elementType] refer back to, so it is the join key of the whole
  /// graph — each class appears exactly once and every edge is this string.
  final String name;

  /// The class-level `@SectionId`, or `null`.
  ///
  /// Used as the *key fallback*: a section or complex member whose own
  /// [SpecField.sectionId] is absent keys its markdown heading on this id
  /// while still pathing on the member name. The two ids are never merged
  /// (SOM §7.1).
  final String? sectionId;

  /// The cleaned class-level `///` doc comment, or `null` — developer-facing,
  /// as against the author-facing [help].
  final String? doc;

  /// The class-level `@ContentHelp(guidance)` authoring guidance, or `null`.
  ///
  /// A member-level [SpecField.help] on the instantiating field is the more
  /// specific statement; unlike [headline], this one is *not* folded into a
  /// per-member fallback chain, so a consumer that wants the class default
  /// has to reach for it here deliberately.
  final String? help;

  /// The class-level `@Headline(text)` default headline (YRD4), or `null`.
  /// A field-level `@Headline` on the instantiating field wins over this.
  final String? headline;
  /// The `@MapsTo` traceability target — the name of the class this one is
  /// the counterpart of elsewhere in the model — or `null`.
  ///
  /// A documentation-level cross-link only: nothing in this runtime
  /// dereferences it, and the named class may legitimately live outside
  /// [SpecModel.classes].
  final String? mapsTo;

  /// The `@DetailedIn` traceability target — the class that elaborates this
  /// one — or `null`. Carried on the same terms as [mapsTo]: a cross-link
  /// for readers and tooling, never followed here.
  final String? detailedIn;

  /// The class's fields in source declaration order, as the exporter read
  /// them.
  ///
  /// This is a *display* order, not the serialization contract: on-disk member
  /// order is decided by the explicit [SpecField.serializationOrder] ordinals,
  /// which `SpecSerializationOrder` sorts on. The two normally coincide, and a
  /// consumer that needs the guarantee must use the ordinals rather than this
  /// list's order.
  final List<SpecField> fields;

  /// The lossless annotation list captured on this class (SOM §5.3).
  @override
  final List<SpecAnnotation> annotations;

  @override
  final StandardReferences? standardReferences;

  /// [name] alone is required — it is the graph's join key, and a class
  /// without one could neither be filed in [SpecModel.classes] nor referred
  /// to by a field.
  ///
  /// [fields] defaults to empty so a marker or projection class constructs
  /// without ceremony; every remaining argument is an annotation projection
  /// whose absence means "not annotated", never "empty".
  SpecClass({
    required this.name,
    this.sectionId,
    this.doc,
    this.help,
    this.headline,
    this.mapsTo,
    this.detailedIn,
    this.fields = const [],
    this.annotations = const [],
    this.standardReferences,
  });

  /// Reads one `classes[name]` entry
  /// (`tom_specs_model_meta_schema.md`, "`classes[name]` entry").
  ///
  /// `name` and `fields` are read as mandatory and throw when absent —
  /// `fields` deliberately so, because a class entry with the key omitted
  /// rather than empty means the snapshot was truncated, and loading it as a
  /// field-less class would present a mutilated document as a valid one.
  factory SpecClass.fromJson(Map<String, dynamic> j) => SpecClass(
        name: j['name'] as String,
        sectionId: j['sectionId'] as String?,
        doc: j['doc'] as String?,
        help: j['help'] as String?,
        headline: j['headline'] as String?,
        mapsTo: j['mapsTo'] as String?,
        detailedIn: j['detailedIn'] as String?,
        fields: (j['fields'] as List)
            .map((e) => SpecField.fromJson(e as Map<String, dynamic>))
            .toList(),
        annotations: SpecAnnotation.listFromJson(j['annotations']),
        standardReferences:
            StandardReferences.fromJson(j['standardReferences']),
      );

  /// The field named [name], or `null` when absent.
  SpecField? fieldNamed(String name) {
    for (final f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }

  /// The `@OneOf` closed choice this class declares, or `null` when it
  /// declares none (`codespecs_mapping.md` §8.2).
  ///
  /// Classes only: the choice is a statement about a *set* of sibling fields,
  /// so it has no meaning on a field and does not belong on
  /// [AnnotatedSpecNode].
  OneOfGroup? get oneOf {
    final a = annotation('OneOf');
    if (a == null) return null;
    final discriminator = a.argument('discriminator')?.toString() ?? '';
    return OneOfGroup(
      discriminator: discriminator,
      note: a.argument('note') as String?,
      discriminatorField: formFieldNamed(discriminator),
      caseFields: [
        for (final f in fields)
          if (f.isCase) f,
      ],
    );
  }

  /// The form-field named [name] from whichever `@Form` section of this class
  /// declares it, or `null` when no section does.
  ///
  /// Form-fields are not [SpecField]s — they live inside a form section's
  /// [SpecField.formFields] — so a lookup that only walked [fields] would
  /// never find a discriminator.
  FormFieldSpec? formFieldNamed(String name) {
    for (final f in fields) {
      for (final ff in f.formFields) {
        if (ff.name == name) return ff;
      }
    }
    return null;
  }

  /// Whether this class is a `@CodeSpecsProjection` — a flat re-reference of
  /// subtrees authored elsewhere, not an authoring document of its own
  /// (`codespecs_mapping.md` §8.4).
  ///
  /// The distinction is load-bearing for anything that judges a document's
  /// depth: a projection is *supposed* to be shallow, which is why the
  /// validator exempts it from the per-document detail count. Consumers that
  /// ask "does this need more detail?" must ask this first.
  ///
  /// Classes only — a projection is a property of a whole document root, so
  /// this does not belong on [AnnotatedSpecNode] alongside the field-capable
  /// links.
  bool get isCodeSpecsProjection => hasAnnotation('CodeSpecsProjection');
}

/// A document root (a class carrying `@Document`).
class SpecRoot {
  /// The root's class name — the key into [SpecModel.classes], and what
  /// [SpecModel.rootByType] and [SpecModel.isGenerationInput] resolve
  /// against. A root whose type is absent from the class graph is a
  /// truncated snapshot, not a documentless root.
  final String type;

  /// The document's display name: `@Document(name:)`, or a PascalCase split
  /// of [type] when the annotation named none. Never `null`, so a picker has
  /// something to show without inventing a fallback — but it is display text,
  /// and [type] is the identity.
  final String title;

  /// The root's `@SectionId`, or `null`. It is the id the document's level-1
  /// heading carries, and the schema's `title-format` demands it as the root
  /// heading id (SOM §11.2, SOM §13) — so a mismatch is a `formatMismatch`,
  /// not a cosmetic difference.
  final String? sectionId;

  /// `@Document(description:)` when non-empty, else `null`. A one-line gloss
  /// for a chooser; the substantive prose is [doc].
  final String? description;

  /// The cleaned class doc comment of the root class, or `null` — the
  /// developer-facing explanation of what the document is for.
  final String? doc;

  /// [type] and [title] are required: the identity and the label, the two
  /// keys the meta schema marks mandatory on a `roots[]` entry. The three
  /// optional arguments are annotation projections whose absence means the
  /// root simply was not annotated.
  SpecRoot({
    required this.type,
    required this.title,
    this.sectionId,
    this.description,
    this.doc,
  });

  /// Reads one `roots[]` entry
  /// (`tom_specs_model_meta_schema.md`, "`roots[]` entry"). `type` and
  /// `title` throw when absent; the rest degrade to `null`.
  factory SpecRoot.fromJson(Map<String, dynamic> j) => SpecRoot(
        type: j['type'] as String,
        title: j['title'] as String,
        sectionId: j['sectionId'] as String?,
        description: j['description'] as String?,
        doc: j['doc'] as String?,
      );
}

/// Computes the `major.minor` model-version string from a [major] version
/// counter and an optional full [label] (the `tom_specs_model` version stamp,
/// e.g. `1.0.0+3.abc1234`).
///
/// When [label] carries at least two leading numeric dotted components
/// (`major.minor…`, ignoring any `+build` metadata) those win, so a genuine
/// authoring minor is preserved (`2.3.1+5` → `2.3`). Otherwise the result is
/// `<major>.0`.
String somModelVersionString(int major, String? label) {
  if (label != null && label.isNotEmpty) {
    final core = label.split('+').first.trim();
    final parts = core.split('.');
    if (parts.length >= 2) {
      final maj = int.tryParse(parts[0].trim());
      final min = int.tryParse(parts[1].trim());
      if (maj != null && min != null) return '$maj.$min';
    }
  }
  return '$major.0';
}

/// How old a snapshot may be before [SpecModel.checkStamp] calls it aged.
///
/// Why two weeks: the object model is regenerated whenever a section is added
/// or reshaped, which in practice happens weekly or more often. A snapshot that
/// has survived a fortnight has most likely been overtaken, and structural
/// feedback recorded against it would be keyed to paths the model has moved
/// past. Callers that know better pass their own `maxAge`.
const Duration defaultMaxSnapshotAge = Duration(days: 14);

/// The generation-stamp timestamp grammar, spelled out rather than delegated to
/// `DateTime.parse`: `YYYY-MM-DDTHH:MM:SS`, an optional fractional part, and an
/// optional `Z` / `±HH:MM` / `±HHMM` offset.
///
/// Every SOM runtime carries this same grammar. Delegating to each platform's
/// own parser would make the accepted set differ by language — several of the
/// nine have no date library at all — and a stamp that reads on one platform
/// and not another is exactly the divergence the shared corpus exists to catch.
final RegExp _stampPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})[Tt ]'
    r'(\d{2}):(\d{2}):(\d{2})(?:\.(\d+))?(Z|z|[+-]\d{2}:?\d{2})?$');

/// The length of [month] in [year], Gregorian. Used to reject a day that does
/// not exist rather than letting it roll into the next month: `DateTime.utc`
/// would turn 31 February into 3 March, while several other SOM runtimes'
/// date types reject it outright — so the grammar rejects it everywhere.
int _daysInMonth(int year, int month) {
  const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  if (month != 2) return lengths[month - 1];
  final isLeap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  return isLeap ? 29 : 28;
}

/// Parses a generation-stamp timestamp to UTC, or returns null.
///
/// A timestamp carrying **no** zone is read as UTC. `DateTime.parse` would read
/// it as the reader's local time, which would make a staleness verdict depend
/// on where the reader sits — a defect in its own right, and one the other
/// eight SOM runtimes could not mirror anyway (several have no timezone
/// database). Fixing the fallback here is what lets all nine agree.
///
/// Anything outside the grammar — or carrying an out-of-range field — degrades
/// to null rather than throwing: an unreadable stamp is not worth failing a
/// whole model over, and rolling `2026-13-01` over into January is worse than
/// admitting the stamp is unreadable.
DateTime? parseStampTimestamp(String? raw) {
  if (raw == null) return null;
  final m = _stampPattern.firstMatch(raw.trim());
  if (m == null) return null;
  final year = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final day = int.parse(m.group(3)!);
  final hour = int.parse(m.group(4)!);
  final minute = int.parse(m.group(5)!);
  final second = int.parse(m.group(6)!);
  if (month < 1 || month > 12 || day < 1 || day > _daysInMonth(year, month)) {
    return null;
  }
  if (hour > 23 || minute > 59 || second > 59) return null;
  // Right-pad the fraction to microseconds; a longer fraction is truncated.
  final frac = (m.group(7) ?? '').padRight(6, '0').substring(0, 6);
  var value = DateTime.utc(year, month, day, hour, minute, second,
      int.parse(frac.substring(0, 3)), int.parse(frac.substring(3)));
  final zone = m.group(8);
  if (zone != null && zone != 'Z' && zone != 'z') {
    final digits = zone.substring(1).replaceAll(':', '');
    final offset = Duration(
        hours: int.parse(digits.substring(0, 2)),
        minutes: int.parse(digits.substring(2)));
    value = zone[0] == '-' ? value.add(offset) : value.subtract(offset);
  }
  return value;
}

/// The outcome of checking a loaded snapshot's generation stamp against its own
/// payload and against the clock — see [SpecModel.checkStamp].
///
/// The two findings are independent and can both hold at once: [isAged] says
/// the snapshot is probably behind the live model, while [countsDisagree] says
/// the file no longer describes itself correctly. Only the second is a defect
/// in the file.
class SpecModelStampCheck {
  /// How long ago the snapshot was generated, or `null` when it carries no
  /// `generatedAt` (an older export, or a hand-built model).
  final Duration? age;

  /// The threshold [age] was judged against.
  final Duration maxAge;

  /// The class count the stamp declares, or `null` when it declares none.
  final int? declaredClassCount;

  /// The number of classes the payload actually carries.
  final int actualClassCount;

  /// The root count the stamp declares, or `null` when it declares none.
  final int? declaredRootCount;

  /// The number of document roots the payload actually carries.
  final int actualRootCount;

  /// Every argument is required, including the three nullable ones.
  ///
  /// That is deliberate: each nullable field encodes "the snapshot declared
  /// nothing here", and defaulting any of them would let a caller construct a
  /// check that quietly reports no finding because a value was forgotten
  /// rather than because the snapshot was silent. The check is only
  /// meaningful when every input is stated.
  const SpecModelStampCheck({
    required this.age,
    required this.maxAge,
    required this.declaredClassCount,
    required this.actualClassCount,
    required this.declaredRootCount,
    required this.actualRootCount,
  });

  /// Whether the snapshot is older than [maxAge]. Always `false` when the
  /// snapshot carries no `generatedAt` — an unknown age is not evidence of a
  /// stale one.
  bool get isAged => age != null && age! > maxAge;

  /// Whether the declared and actual class counts differ.
  ///
  /// An absent declaration is not a disagreement: older snapshots predate the
  /// stamp keys, and reading absent as `0` would make every one of them look
  /// corrupt.
  bool get classCountDisagrees =>
      declaredClassCount != null && declaredClassCount != actualClassCount;

  /// Whether the declared and actual root counts differ. Absent declarations
  /// are ignored, as for [classCountDisagrees].
  bool get rootCountDisagrees =>
      declaredRootCount != null && declaredRootCount != actualRootCount;

  /// Whether either declared size disagrees with the payload.
  ///
  /// The exporter derives both counts *from* the payload it writes, so a
  /// disagreement cannot arise from a normal export — it means the file was
  /// edited or truncated afterwards.
  bool get countsDisagree => classCountDisagrees || rootCountDisagrees;

  /// Whether anything at all was found.
  bool get isStale => isAged || countsDisagree;

  /// The findings as ready-to-display sentences, empty when there are none.
  List<String> get warnings => [
        if (isAged)
          'Snapshot is ${age!.inDays} days old (threshold ${maxAge.inDays} '
              'days) — the model may have moved on since it was exported.',
        if (classCountDisagrees)
          'Stamp declares $declaredClassCount classes but the snapshot '
              'carries $actualClassCount — it was edited after export.',
        if (rootCountDisagrees)
          'Stamp declares $declaredRootCount document roots but the snapshot '
              'carries $actualRootCount — it was edited after export.',
      ];
}

/// The complete exported model.
class SpecModel {
  /// The document entry points, in export order — one per `@Document` class.
  ///
  /// These are the *authored* documents only; the canonical container named
  /// by [containerRoot] is not among them, and a generation input such as a
  /// CodeSpecs projection is (test it with [isGenerationInput] before
  /// offering it to an author).
  final List<SpecRoot> roots;

  /// The whole class graph keyed by [SpecClass.name] — each class exactly
  /// once, with `type` / `elementType` edges followed on demand.
  ///
  /// A map rather than a list because resolution is the hot path: every
  /// descent through a complex field is one lookup here. Note the graph is
  /// *not* closed — [SpecField.sectionType], [SpecClass.mapsTo] and
  /// [SpecClass.detailedIn] may name classes deliberately absent from it, so
  /// a missing key is not automatically a corrupt snapshot.
  final Map<String, SpecClass> classes;

  /// The model-version counter the meta-data was generated against. `0` means
  /// the file was produced by a manual, unstamped export rather than an
  /// official build.
  final int modelVersion;

  /// A human-readable build label for the same stamp (e.g. `1.0.0+3.abc1234`),
  /// or `null` when the meta-data is unstamped.
  final String? modelVersionLabel;

  /// When the snapshot was exported (UTC), or `null` when it carries no
  /// `generatedAt` — an export predating the key, or a hand-built model.
  final DateTime? generatedAt;

  /// The *file format's* own version, distinct from [modelVersion] (which
  /// model the snapshot describes). `null` when undeclared.
  final int? metaSchemaVersion;

  /// The class count the snapshot declares, or `null` when undeclared.
  ///
  /// Kept separate from `classes.length`: the declared value is what the
  /// exporter recorded, the actual value is what survived to the reader, and
  /// comparing them is the point ([checkStamp]).
  final int? classCount;

  /// The document-root count the snapshot declares, or `null` when undeclared.
  final int? rootCount;

  /// The canonical container class — the single true tree root, which is not
  /// itself a document and so does not appear in [roots]. `null` when the
  /// model has no container (e.g. a synthetic export).
  final String? containerRoot;

  /// Only [roots] and [classes] — the payload — are required. Every stamp
  /// argument is optional and defaults to the unstamped state ([modelVersion]
  /// to `0`, the rest to `null`), so a hand-built or synthetic model
  /// constructs without inventing provenance it does not have.
  ///
  /// The consequence is that [checkStamp] reports no count disagreement for
  /// such a model: absent declarations are not compared. That is intended —
  /// only a snapshot that *claimed* a size can contradict itself.
  SpecModel({
    required this.roots,
    required this.classes,
    this.modelVersion = 0,
    this.modelVersionLabel,
    this.generatedAt,
    this.metaSchemaVersion,
    this.classCount,
    this.rootCount,
    this.containerRoot,
  });

  /// Checks the generation stamp against the payload and the clock.
  ///
  /// [now] is injectable so callers (and tests) can evaluate age against a
  /// fixed instant instead of the wall clock.
  SpecModelStampCheck checkStamp({
    Duration maxAge = defaultMaxSnapshotAge,
    DateTime? now,
  }) {
    final generated = generatedAt;
    return SpecModelStampCheck(
      age: generated == null
          ? null
          : (now ?? DateTime.now().toUtc()).difference(generated),
      maxAge: maxAge,
      declaredClassCount: classCount,
      actualClassCount: classes.length,
      declaredRootCount: rootCount,
      actualRootCount: roots.length,
    );
  }

  /// The class named [name], or `null` when the graph does not carry it.
  ///
  /// Accepts `null` and answers `null` so callers can feed a nullable edge
  /// ([SpecField.type], [SpecField.elementType], [SpecRoot.type]) straight in
  /// — the traversals in this runtime chain these lookups per path segment,
  /// and a null-check at every call site would be noise.
  ///
  /// An unresolved name is *not* an error here: an edge may legitimately
  /// point outside the exported graph, so a caller that needs the distinction
  /// between "absent by design" and "truncated snapshot" must draw it itself
  /// (see [SpecModelStampCheck.countsDisagree]).
  SpecClass? classNamed(String? name) => name == null ? null : classes[name];

  /// Whether [root] is a **generation input** rather than an authored document.
  ///
  /// A generation input is an `@Document` root whose audience is a generator,
  /// not a spec author: it projects existing Solution Blueprint sections into
  /// the shape a downstream phase consumes. `D13CodeSpecsProjection` is the
  /// only one today — it is `@CodeSpecKind`-driven, flat, locus-grouped, and
  /// carries no document identity anybody would sit down and write.
  ///
  /// Derived from the class's `@CodeSpecsProjection()` marker, which the export
  /// already carries losslessly in `classes[type].annotations`. Reading it here
  /// keeps the classification single-sourced in the model — a consumer that
  /// hard-coded the root's type name would silently misclassify the next
  /// projection to be added.
  ///
  /// A root whose class is absent from [classes] (a synthetic or truncated
  /// model) is *not* a generation input: an unknown class is not evidence.
  bool isGenerationInput(SpecRoot root) =>
      classNamed(root.type)?.hasAnnotation('CodeSpecsProjection') ?? false;

  /// The document root whose [SpecRoot.type] equals [type] (SOM §21).
  ///
  /// Replaces the recurring `roots.firstWhere((r) => r.type == …)` boilerplate.
  /// Throws [ArgumentError] when no root carries that type — the same failure
  /// mode as an `orElse`-less `firstWhere`, but with a message that names the
  /// missing type and the ones that do exist.
  SpecRoot rootByType(String type) {
    for (final r in roots) {
      if (r.type == type) return r;
    }
    throw ArgumentError.value(
        type,
        'type',
        'no document root with this type (have: '
            '${roots.map((r) => r.type).join(', ')})');
  }

  /// The model version the generated object model reports (SOM §4.2), as a
  /// `major.minor` string derived from the `tom_specs_model` project version
  /// stamp.
  ///
  /// The real `major.minor` comes from [modelVersionLabel] (e.g.
  /// `1.0.0+3.abc1234` → `1.0`) so a genuine authoring minor is preserved.
  /// When the model is unstamped ([modelVersionLabel] is `null`) the result
  /// falls back to `<modelVersion>.0`.
  String get modelVersionString =>
      somModelVersionString(modelVersion, modelVersionLabel);

  /// Decodes a whole `meta/spec_model.meta.json` payload
  /// (`tom_specs_model_meta_schema.md`, "Top-level keys").
  ///
  /// `classes` and `roots` are mandatory and throw when absent or of the
  /// wrong shape — without them there is no model. Every stamp key is
  /// optional so that snapshots exported before the keys existed still load,
  /// and an empty `modelVersionLabel` is normalised to `null` so "unstamped"
  /// has one representation rather than two.
  ///
  /// This constructor does **not** validate the payload; it only decodes it.
  /// Run `validateSpecModelMeta` first when the file's conformance is in
  /// question, and [checkStamp] afterwards to catch a file edited after
  /// export.
  factory SpecModel.fromJson(Map<String, dynamic> j) {
    final classes = <String, SpecClass>{};
    (j['classes'] as Map<String, dynamic>).forEach((name, value) {
      classes[name] = SpecClass.fromJson(value as Map<String, dynamic>);
    });
    final roots = (j['roots'] as List)
        .map((e) => SpecRoot.fromJson(e as Map<String, dynamic>))
        .toList();
    final label = j['modelVersionLabel'] as String?;
    return SpecModel(
      roots: roots,
      classes: classes,
      modelVersion: (j['modelVersion'] as num?)?.toInt() ?? 0,
      modelVersionLabel: (label?.isNotEmpty ?? false) ? label : null,
      // Every stamp key is optional: snapshots exported before the key existed
      // must still load. A malformed timestamp degrades to `null` for the same
      // reason — an unreadable stamp is not worth failing a whole model over.
      generatedAt: parseStampTimestamp(j['generatedAt'] as String?),
      metaSchemaVersion: (j['metaSchemaVersion'] as num?)?.toInt(),
      classCount: (j['classCount'] as num?)?.toInt(),
      rootCount: (j['rootCount'] as num?)?.toInt(),
      containerRoot: j['containerRoot'] as String?,
    );
  }
}
