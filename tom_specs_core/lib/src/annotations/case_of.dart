/// Binds one complex-subsection field of a [OneOf] container to a discriminator
/// value (`codespecs_mapping.md` §8.2, csm-7-4/csmb6).
///
/// `@Case` is **repeatable**: a subsection that applies to several kinds carries
/// one `@Case` per discriminator constant. A subsection field with **no**
/// `@Case` is *common* — present regardless of the chosen case.
///
/// [value] is a constant of the discriminator enum named by the enclosing
/// class's `@OneOf`. It is declared as `Object` because a single annotation type
/// must accept whichever model enum a given container discriminates on; the
/// static validator checks that the value is actually a constant of the
/// discriminator's enum. The value is carried losslessly (as the qualified
/// `EnumType.constant` token) into the exported model and the SOM meta `extra`
/// list.
///
/// Example:
/// ```dart
/// @Case(ScreenElementFieldKind.date)
/// @Case(ScreenElementFieldKind.dateTime)
/// @Case(ScreenElementFieldKind.time)
/// DocSpecsSection? dateOptions;
/// ```
class Case {
  /// The discriminator enum constant this subsection is bound to.
  final Object value;

  /// Binds the annotated subsection to the discriminator constant [value].
  ///
  /// Repeat the annotation to bind one subsection to several constants; omit
  /// it entirely to make the subsection *common* — present whichever case the
  /// document chooses.
  const Case(this.value);
}
