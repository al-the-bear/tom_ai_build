/// Declares the form fields for a section whose content is structured as
/// name-value pairs (one per line).
///
/// Applied to the `content` field of form section classes. Each [Field]
/// declares a named form value with its Dart type and a human-readable
/// description.
class Form {
  /// The form's fields, in the order the section body writes them.
  ///
  /// Order is significant: it is the order of the name-value lines in the
  /// serialized document and the order an editor renders the fields in.
  final List<Field> fields;

  /// Declares [fields] as the form carried by the annotated `content` field.
  const Form(this.fields);
}

/// A single form field declaration.
class Field {
  /// Field name as it appears in the document (camelCase; display name
  /// conversion is done by tooling).
  final String name;

  /// Dart type of the value. Use `String` for free text, `int`/`double` for
  /// numbers, an enum type for constrained choices.
  final Type type;

  /// Short description shown in outlines and documentation.
  final String description;

  /// Whether this field is required (non-empty).
  final bool required;

  /// Optional hint text providing guidance on valid values, formats, or
  /// allowed options. Used by AI assistants and UI tools to help users
  /// fill in the field correctly.
  final String? hint;

  /// The registry key(s) this field's value is an **id drawn from**, each
  /// written `<SECTIONID>.<slot>` — e.g. `'SCRTEN.routeId'`.
  ///
  /// A reference field holds a *free-text id that must already be declared
  /// somewhere else in the specification*. Before this existed, that contract
  /// lived only in the [hint] prose ("Route ID (SCRTEN registry) …"), so a
  /// rename or a typo produced a specification that read fine, validated green
  /// and generated broken code. Declaring the target makes the contract
  /// machine-readable and enforceable at both tiers:
  ///
  /// * **static** (`tom_specs_clitool/lib/src/validator.dart`) — the named
  ///   section exists, declares that form field, and really is a repeated
  ///   registry entry;
  /// * **instance** (`spec_validator.dart`) — the id a concrete document writes
  ///   here is actually declared by some entry of the target registry.
  ///
  /// **Why the target names a slot and not just a section.** A section id
  /// alone (`'SCRTEN'`) says where to look but not what to compare against, so
  /// the instance tier could not run and the contract would stay unenforced for
  /// exactly the fields it was introduced to protect. The qualified form is
  /// resolvable end to end, so it is required rather than optional.
  ///
  /// **The two slot forms.** A slot is either a **form field name**, or the
  /// reserved key **`@sectionId`** meaning *the registry entry's own section
  /// id*. The second form exists because some registries store their id in no
  /// form field at all: a functional requirement's id is its stored section id,
  /// supplied by the owning list's `@SectionIdPattern`, and is deliberately not
  /// restated as a form field (`tom_specs_model_rules.md` §8 — exactly one
  /// storage slot per value). Without `@sectionId` those registries would be
  /// unreachable, and every reference to a requirement id would stay
  /// unenforceable. The target still names the **entry class** (`'FRE'`), never
  /// the `-LST` container or the pattern itself, so `tom_specs_model_rules.md`
  /// §6.2 rule 2 is unchanged.
  /// `@` is a reserved namespace: any other `@`-prefixed slot is a hard error
  /// rather than a silently unresolvable target.
  ///
  /// **Why a list.** Some fields legitimately accept an id from more than one
  /// registry — `SCTREN.outcomeReference` holds a system error code *or* a
  /// validation message template; a navigation guard applies to routes *or*
  /// screens. A value is valid when it resolves in **any** listed registry.
  /// A single-target reference is the one-element list form. (Same shape, and
  /// the same reason, as `@CodeSpecKind`'s list of kinds.)
  ///
  /// **Multi-valued values.** A reference field whose value names several ids
  /// writes them comma-separated; the instance tier splits on commas and
  /// resolves each segment, so a single- and a multi-valued reference need no
  /// different declaration.
  ///
  /// This is not the `@Reference` annotation, though the two meet. `@Reference`
  /// marks a *member* as an edge to data owned elsewhere, which the outliner
  /// declines to recurse into; this marks a *form field whose String value is
  /// an id* and names where the id comes from. A `@Reference` section holds its
  /// id in exactly such a field, and a form field may carry `refersTo` without
  /// any `@Reference` — an id written among an entry's other facts.
  final List<String> refersTo;

  /// Declares that this field states a **count of entries the document
  /// holds** — the instance tier then checks the stated number against them
  /// (`countMismatch`), so a total kept by hand cannot silently drift from the
  /// list it describes.
  ///
  /// Each element is `<SECTIONID>` — every list entry of the class carrying
  /// that `@SectionId` in this document — or `<SECTIONID>.<formField>=<value>`,
  /// only the entries one of whose own forms (a form member of the entry
  /// class) holds [value] in that form field. The count is the **sum** over
  /// the elements, so `['TERQ', 'SECRQ']` counts technical and security
  /// requirements together. A target written `./<SECTIONID>…` counts only the
  /// entries beneath the section that holds this form — a use case's own
  /// steps rather than every step in the document. Like [refersTo], a target
  /// the document's root cannot reach is skipped rather than reported, and an
  /// empty value is not checked — it is completeness, which the schema tier
  /// owns.
  ///
  /// The value is still written by the author: the field states the count,
  /// the check holds it to the document. Deriving it at render time would make
  /// the stored document differ from what a reader sees.
  final List<String> countOf;

  /// Declares that this reference field holds **several ids**, written
  /// comma-separated — `dependsOnFeatures`, a reference section's `refs`.
  ///
  /// Only meaningful with [refersTo]. A reference field without it holds
  /// exactly one id, and the instance tier reports a comma-separated list in
  /// it (`multipleReferences`): a field meant for one reference must not
  /// silently hold several. Every id of a list is resolved on its own, so a
  /// dangling id inside a list is reported as `danglingReference` either way.
  final bool multiple;

  /// Declares that this field's value is the **product** of other fields — a
  /// risk score from probability and impact. The instance tier checks the
  /// stated number against it (`derivedValueMismatch`).
  ///
  /// Each operand is a form field of this form, or `<FORMSECTIONID>.<field>`
  /// for a form that sits beside this one on the same section. A numeric
  /// operand contributes its number; an enum operand its 1-based position in
  /// the enum, so `medium` × `critical` on the five-band scales is 3 × 5. The
  /// check runs only when the value and every operand are filled.
  final List<String> productOf;

  /// Declares that this field's value is a **rank** by another field of the
  /// same form, highest first — a risk's ranking by its score. Over every
  /// instance of this form in the document whose rank and score are filled,
  /// the ranks must be the whole numbers 1 to n, each once, and a higher score
  /// may never rank below a lower one; equal scores may take their ranks in
  /// any order. A violation is a `derivedValueMismatch`.
  final String? rankOf;

  /// Declares that the field's value is **code, not prose** — a regular
  /// expression, a CHECK expression, a formula.
  ///
  /// The markdown rendition writes such a value as an inline code span, so the
  /// characters markdown would otherwise interpret stay literal: the regex
  /// `^[a-z0-9](-?[a-z0-9]){1,62}$` written as prose becomes a link, reads
  /// wrongly, and fails every link check that sees it. The import unwraps the
  /// span again, so the stored value is the bare code either way
  /// (SOM §11.4 rule 8). The
  /// flag says nothing about the value's language and is not checked against
  /// it; it only changes how the value is written.
  final bool code;

  /// Declares a form field called [name] holding a value of [type].
  ///
  /// The three positional arguments are the ones every field has; the named
  /// ones are the qualifiers a field may do without, so a plain optional
  /// free-text field is the three-argument form.
  const Field(
    this.name,
    this.type,
    this.description, {
    this.required = false,
    this.hint,
    this.refersTo = const [],
    this.countOf = const [],
    this.multiple = false,
    this.productOf = const [],
    this.rankOf,
    this.code = false,
  });
}
