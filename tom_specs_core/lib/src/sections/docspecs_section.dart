/// The universal section base type of the TomSpecs object model (YRD5).
///
/// Per `docspecs_section_model_decisions.md` §4, every section of a DocSpecs
/// document follows one structural shape — headline (with an `<!--[ID]-->`
/// comment), optional body content, subsections. `DocSpecsSection` is the
/// object-model representation of the *simple* case: a section with no
/// subsections, holding exactly the stored [headline], the stored [id] and the
/// body [content].
///
/// In `tom_specs_model` this type replaces every former `String` section
/// member (`String? foo` → `DocSpecsSection? foo`, `List<String>` →
/// `List<DocSpecsSection>`), and **every model class extends it** — so the
/// whole model becomes an object model into which a `*.md` document can
/// actually be parsed. The one remaining gap is `@Form`-annotated content,
/// which stays unparsed in [content] until mediated by the optional
/// [form] member (a [DocSpecsForm] holding the parsed field values plus the
/// pre-form-field content already split off).
///
/// Why this lives in `tom_specs_core` (decision, YRD5): the clitool's
/// analyzer-based `ModelReader` scans `tom_specs_model/lib/src` and reflects
/// every class it finds into the document meta tree. The base type is
/// *infrastructure of the metamodel* — like `TextSection` and the other
/// section leaves that already live here — not a document section itself, so
/// it must stay outside the scanned package. Members typed `DocSpecsSection`
/// are classified as `content` nodes by the tooling (the runtime
/// representation of a simple section is its `String` content; headline and
/// id are stored per node by the YRD3 runtime), which keeps the exported meta
/// tree identical to the pre-YRD5 `String`-member model.
class DocSpecsSection {
  DocSpecsSection({
    this.headline,
    this.id,
    this.content,
    this.form,
    List<String>? codeSpec,
  }) : codeSpec = codeSpec ?? <String>[];

  /// The stored headline of this section (YRD3 decision (b): the stored value
  /// is authoritative; `@Headline` on the member only supplies the default).
  String? headline;

  /// The stored section id (the `<!--[ID]-->` marker), when present.
  String? id;

  /// The concrete instance-level forward DocSpecs→CodeSpecs link
  /// (`codespecs_mapping.md` §9.2): the exact CodeSpecs code location(s) this
  /// section maps to — e.g. `['CsOrder', 'CsOrder.total', 'CsOrderRepository']`.
  ///
  /// Serialized alongside the id inside the same `<!--[ID] codeSpec="…"-->`
  /// headline HTML comment (one comma-separated, quoted value) on the markdown
  /// side, and as a `codeSpec` field in the section mapping on the yaml side.
  /// Empty by default so untouched sections stay byte-stable.
  List<String> codeSpec;

  /// The section's body content. For `@Form`-annotated members this holds the
  /// full unparsed section text until [form] mediates it.
  String? content;

  /// The parsed form of a `@Form`-annotated section, when parsing has split
  /// the content: pre-form-field text plus one value per form field.
  DocSpecsForm? form;
}

/// The parsed representation of a `@Form`-annotated section's content (YRD5).
///
/// A form section's raw text consists of free-text content followed by the
/// form's field lines. Parsing splits the two: [content] keeps the pre-field
/// text, and [values] holds one entry per parsed form field, keyed by the
/// field name declared in the `@Form([Field(...)])` annotation. Values are
/// kept as `Object?` — YRD7 introduces the *typed* per-field members on the
/// generated SOM classes; this class is the generic model-side holder.
class DocSpecsForm {
  DocSpecsForm({this.content, Map<String, Object?>? values})
      : values = values ?? <String, Object?>{};

  /// The section's free-text content before the first form field line.
  String? content;

  /// Parsed form-field values, keyed by the `@Form` field name.
  final Map<String, Object?> values;
}
