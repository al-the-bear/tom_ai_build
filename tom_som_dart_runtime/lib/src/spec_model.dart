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
  list,
  form,
  section,
  content,
  enumValue,
  complex,
  scalar;

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

/// A single annotation captured losslessly from the model source (§3.1): its
/// name and the resolved argument map (`{ '<arg>': <value> }`). This is the
/// `annotations[]` block emitted by `ModelJsonExporter` — the superset the
/// curated convenience accessors ([SpecClass.sectionId], [SpecField.min], …)
/// are projected from.
class SpecAnnotation {
  final String name;
  final Map<String, Object?> arguments;

  const SpecAnnotation({required this.name, this.arguments = const {}});

  factory SpecAnnotation.fromJson(Map<String, dynamic> j) => SpecAnnotation(
        name: j['name'] as String,
        arguments: (j['arguments'] as Map?)?.cast<String, Object?>() ?? const {},
      );

  /// The argument named [key], or `null` when absent.
  Object? argument(String key) => arguments[key];

  static List<SpecAnnotation> listFromJson(Object? raw) =>
      (raw as List?)
          ?.map((e) => SpecAnnotation.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];
}

/// A single form field within a `@Form` content section.
class FormFieldSpec {
  final String name;
  final String label;
  final String? hint;
  final String type;
  final bool required;

  /// Enum constant names when [type] is a model enum (YRD7); empty for
  /// non-enum field types. Lets consumers validate and convert values
  /// without the analyzer.
  final List<String> enumValues;

  FormFieldSpec({
    required this.name,
    required this.label,
    required this.type,
    this.hint,
    this.required = false,
    this.enumValues = const [],
  });

  factory FormFieldSpec.fromJson(Map<String, dynamic> j) => FormFieldSpec(
        name: j['name'] as String,
        label: j['label'] as String? ?? j['name'] as String,
        hint: j['hint'] as String?,
        type: j['type'] as String? ?? 'String',
        required: j['required'] as bool? ?? false,
        enumValues:
            (j['enumValues'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
      );
}

/// A list-valued taxonomy annotation: a set of enum codes plus an optional
/// explanatory note.
///
/// The model states where a subtree is headed with two such annotations, which
/// share this shape exactly — `@CodeSpecKind(List<CodeSpecPart>, {note})` names
/// the CodeSpecs part(s) a section type must be realised as
/// (`codespecs_mapping.md` §9.1/§9.5), and `@FollowUpKind(List<FollowUpProcess>,
/// {note})` names the downstream *process(es)* a non-code subtree feeds (§8.3).
/// One reader serves both; which annotation a link came from is expressed by
/// which accessor produced it.
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
  /// The lossless annotation list captured on this node (§3.1).
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
  /// becoming CodeSpecs code (§8.3).
  KindLink? get followUpKind => _link('FollowUpKind', 'processes');

  KindLink? _link(String name, String listArgument) {
    final a = annotation(name);
    return a == null
        ? null
        : KindLink.fromAnnotation(a, listArgument: listArgument);
  }
}

/// A single field of a [SpecClass].
class SpecField with AnnotatedSpecNode {
  final String name;
  final SpecFieldKind kind;
  final String? doc;
  final String? help;

  /// The `@Headline(text)` default headline (YRD4), or `null`. Render
  /// precedence: stored headline > this default > name derivation.
  final String? headline;
  final String? sectionId;
  final String? sectionIdPattern;

  /// The member's serialization ordinal from `@SerializationOrder(n)` (SOM
  /// source declaration order), or `null` when unannotated. Drives the YAML
  /// member emission order (AA1 criterion 7).
  final int? serializationOrder;

  // list
  final String? elementType;
  final bool elementIsComplex;
  final int? min;

  // section / content
  final String? contentType;
  final String? sectionType;

  // enum
  /// The Dart enum type name backing an `enum` field (e.g. `Probability`), or
  /// `null` for non-enum fields. Mirrors the exporter's `enumType` key.
  final String? enumType;
  final List<String> enumValues;

  // complex / scalar
  final String? type;

  // form
  final List<FormFieldSpec> formFields;

  /// The lossless annotation list captured on this field (§3.1).
  @override
  final List<SpecAnnotation> annotations;

  @override
  final StandardReferences? standardReferences;

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
  /// §8.2 makes an uncovered case a *warning*, not an error — a kind with no
  /// attributes yet is legal — so this is information for the reviewer to
  /// judge, not a defect to flag.
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
  final String name;
  final String? sectionId;
  final String? doc;
  final String? help;

  /// The class-level `@Headline(text)` default headline (YRD4), or `null`.
  /// A field-level `@Headline` on the instantiating field wins over this.
  final String? headline;
  final String? mapsTo;
  final String? detailedIn;
  final List<SpecField> fields;

  /// The lossless annotation list captured on this class (§3.1).
  @override
  final List<SpecAnnotation> annotations;

  @override
  final StandardReferences? standardReferences;

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
  final String type;
  final String title;
  final String? sectionId;
  final String? description;
  final String? doc;

  SpecRoot({
    required this.type,
    required this.title,
    this.sectionId,
    this.description,
    this.doc,
  });

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
  final List<SpecRoot> roots;
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

  SpecClass? classNamed(String? name) => name == null ? null : classes[name];

  /// The document root whose [SpecRoot.type] equals [type] (§ item 12).
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

  /// The model version the generated object model reports (§2.1), as a
  /// `major.minor` string derived from the `tom_specs_model` project version
  /// stamp.
  ///
  /// The real `major.minor` comes from [modelVersionLabel] (e.g.
  /// `1.0.0+3.abc1234` → `1.0`) so a genuine authoring minor is preserved.
  /// When the model is unstamped ([modelVersionLabel] is `null`) the result
  /// falls back to `<modelVersion>.0`.
  String get modelVersionString =>
      somModelVersionString(modelVersion, modelVersionLabel);

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
