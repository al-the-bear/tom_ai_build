/// The universal section base type of the TomSpecs object model (YRD5).
///
/// Per `tom_specs_model/doc/tom_specs_model_rules.md` §5.2, every section of a
/// DocSpecs document follows one structural shape — headline (with an
/// `<!--[ID]-->` comment), optional body content, subsections.
/// `DocSpecsSection` is the object-model representation of the *simple* case:
/// a section with no subsections, holding exactly the stored [headline], the
/// stored [id] and the body [content].
///
/// In `tom_specs_model` this type replaces every former `String` section
/// member (`String? foo` → `DocSpecsSection? foo`, `List<String>` →
/// `List<DocSpecsSection>`), and **every model class extends it** — so the
/// whole model becomes an object model into which a `*.md` document can
/// actually be parsed. A `@Form`-annotated section is no exception: its free
/// text lives in [content] like any other section's body (the DocSpecs form
/// *preamble*, `${text[]}`, SOM §11.4 rule 7), and its parsed field values
/// live in the optional [form] member. There is exactly one home for a
/// section's free text, whether or not the section carries a form.
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
  /// Creates a section.
  ///
  /// Every argument is optional: a section under construction may have neither
  /// a headline nor an id nor a body yet, and a parser fills them in as it
  /// reads. [codeSpec] defaults to an empty **growable** list rather than a
  /// const one, so links can be added to a freshly built section in place.
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

  /// The section's body content. For a `@Form`-annotated member this is the
  /// form's **preamble** — the free text before the first field line (SOM
  /// §11.4 rule 7); the field values themselves live in [form].
  String? content;

  /// The parsed field values of a `@Form`-annotated section, when parsing has
  /// split them out of the section body. Null when the section carries no form
  /// values; the section's free text stays in [content] either way.
  DocSpecsForm? form;
}

/// The parsed field values of a `@Form`-annotated section (YRD5).
///
/// A form section's text consists of free-text preamble followed by the form's
/// field lines. Parsing splits the two: the preamble stays in
/// [DocSpecsSection.content] — the one home a section's free text has, form or
/// not — and this holds one entry per parsed form field, keyed by the field
/// name declared in the `@Form([Field(...)])` annotation. Values are kept as
/// `Object?` — YRD7 introduces the *typed* per-field members on the generated
/// SOM classes; this class is the generic model-side holder.
class DocSpecsForm {
  /// Creates a form-value holder.
  ///
  /// [values] defaults to an empty **growable** map, so a parser can fill it in
  /// place as it reads the section's field lines.
  DocSpecsForm({Map<String, Object?>? values})
    : values = values ?? <String, Object?>{};

  /// Parsed form-field values, keyed by the `@Form` field name.
  final Map<String, Object?> values;
}
