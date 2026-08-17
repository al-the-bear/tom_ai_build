/// Declares the form fields for a section whose content is structured as
/// name-value pairs (one per line).
///
/// Applied to the `content` field of form section classes. Each [Field]
/// declares a named form value with its Dart type and a human-readable
/// description.
class Form {
  final List<Field> fields;

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
  /// This is deliberately **not** the `@Reference` annotation. `@Reference`
  /// marks a *Dart model member whose type is a section class* — a structural
  /// link the outliner declines to recurse into. This marks a *form field whose
  /// String value is an id*. Different carrier, different value kind; the two
  /// never apply to the same declaration.
  final List<String> refersTo;

  const Field(
    this.name,
    this.type,
    this.description, {
    this.required = false,
    this.hint,
    this.refersTo = const [],
  });
}
