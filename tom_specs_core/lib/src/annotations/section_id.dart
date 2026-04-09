/// Declares the section ID that the annotated class has in the target
/// specification document.
///
/// Applied to model classes.
///
/// Example: `@SectionId('PD00-CSA')` maps the class to section PD00-CSA.
class SectionId {
  final String id;

  const SectionId(this.id);
}
