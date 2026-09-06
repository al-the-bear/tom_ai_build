/// Declares the section ID pattern for items in a `List<T>` field.
///
/// Applied to list fields. The pattern uses a suffix (e.g., `-xx`) indicating
/// each list item gets a unique numbered section in the target document.
///
/// This implies a section level: the field is a section, each list item is a
/// subsection.
///
/// Example: `@SectionIdPattern('ACCH-ITEM-xxx')` → first item is
/// `ACCH-ITEM-1`, second `ACCH-ITEM-2`, and so on.
class SectionIdPattern {
  /// The per-item id template, whose trailing `xxx` is the counter slot.
  ///
  /// The counter is a **plain 1-based number, never zero-padded**
  /// (`tom_specs_model_rules.md` §7.5) — the `xxx` fixes the position of the
  /// number, not its width.
  ///
  /// The pattern must mirror the owning list's own `@SectionId` with `-LST`
  /// replaced by `-xxx`; the static validator enforces that pairing, because
  /// the container id and the item ids have to agree for a parsed document to
  /// reattach its items to the list they came from.
  ///
  /// In the generated schema the `xxx` compiles to `.+` — a stem check, since
  /// numbering and list-scoped id uniqueness are owned by the runtime rather
  /// than by the schema, and stored ids (`GOAL-ITEM-GL1`) are not numbers.
  final String pattern;

  /// Declares [pattern] as the per-item id template of the annotated list.
  const SectionIdPattern(this.pattern);
}
