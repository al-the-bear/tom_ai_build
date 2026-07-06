/// Declares the section ID that the annotated class has in the target
/// specification document.
///
/// Applied to model classes.
///
/// Example: `@SectionId('INDM')` maps the class to section INDM.
class SectionId {
  final String id;

  const SectionId(this.id);
}
