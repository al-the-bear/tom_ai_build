/// Predefined DEFAULT headline for a section (YRD4).
///
/// Applied to fields or classes. A field-level `@Headline` wins over the
/// target class's class-level one (same precedence rule as `@SectionId`).
///
/// The value is the *default* title only — render precedence is
/// `stored headline > @Headline default > name derivation
/// (titleCase/itemTitleStem)`. Editors use it to prefill the headline when a
/// new section is created; codecs use it as the render fallback when the
/// document carries no stored headline. A stored headline always wins and
/// stays editable.
class Headline {
  final String text;

  const Headline(this.text);
}
