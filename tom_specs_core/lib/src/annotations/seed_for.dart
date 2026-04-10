/// Marks a section or field as seeding a single downstream document.
///
/// Applied to classes or fields whose content seeds exactly one document type.
/// Establishes a compile-time link between the source model and the target
/// document root class.
///
/// Example:
/// ```dart
/// @SeedFor(TechnicalRequirements)
/// @Comment('Seeds → TR')
/// TechnicalFrameworkConditions technicalFrameworkConditions = ...;
/// ```
class SeedFor {
  final Type documentRootClass;

  const SeedFor(this.documentRootClass);
}
