/// Validates a concrete [SpecDocument]'s values against a [SpecModel] via the
/// [SpecReflection] resolver (step 3 "validation against meta-data").
///
/// The check is over the values a document *holds*: every set path must resolve
/// to a node of a compatible kind, every form sub-key must name a real form
/// field, and every populated list must meet its `@Min` item count. Schema
/// completeness (mandatory-but-absent nodes) is a separate concern and is not
/// reported here.
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_reflection.dart';

/// Why a single value in a document is invalid against the model.
enum SpecValidationCode {
  /// The path does not resolve to any reachable model node.
  danglingPath,

  /// The path resolves, but to a node that cannot hold this kind of value.
  kindMismatch,

  /// A form sub-key names a field the form section does not declare.
  unknownFormField,

  /// A populated list holds fewer items than its `@Min` requires.
  minItems,
}

/// One problem found while validating a document.
class SpecValidationError {
  /// The document path the problem is anchored at.
  final String path;

  /// The category of problem.
  final SpecValidationCode code;

  /// A human-readable description.
  final String message;

  const SpecValidationError({
    required this.path,
    required this.code,
    required this.message,
  });

  @override
  String toString() => '[${code.name}] $path: $message';
}

/// Validates [doc] against [model]. Returns an empty list when the document is
/// valid; otherwise one [SpecValidationError] per problem, in a stable order
/// (content paths, then forms, then lists; each group sorted by path).
List<SpecValidationError> validateDocument(SpecModel model, SpecDocument doc) {
  final refl = SpecReflection(model);
  final errors = <SpecValidationError>[];

  List<String> sorted(Iterable<String> keys) => keys.toList()..sort();

  // 1. Content/scalar/enum leaves.
  for (final path in sorted(doc.contentPaths)) {
    final res = refl.resolve(path);
    if (res == null) {
      errors.add(_dangling(path));
      continue;
    }
    if (!res.isValueLeaf) {
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.kindMismatch,
        message: 'expected a value leaf but path resolves to ${res.kind.name}',
      ));
    }
  }

  // 2. Form sections.
  for (final path in sorted(doc.formPaths)) {
    final res = refl.resolve(path);
    if (res == null) {
      errors.add(_dangling(path));
      continue;
    }
    if (res.kind != SpecNodeKind.form || res.field == null) {
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.kindMismatch,
        message: 'expected a form section but path resolves to ${res.kind.name}',
      ));
      continue;
    }
    final declared = {for (final ff in res.field!.formFields) ff.name};
    for (final name in sorted(doc.formFieldNames(path))) {
      if (!declared.contains(name)) {
        errors.add(SpecValidationError(
          path: path,
          code: SpecValidationCode.unknownFormField,
          message: 'form field "$name" is not declared on ${res.field!.name}',
        ));
      }
    }
  }

  // 3. Lists (container kind + `@Min` count on populated lists).
  for (final path in sorted(doc.listPaths)) {
    final res = refl.resolve(path);
    if (res == null) {
      errors.add(_dangling(path));
      continue;
    }
    if (res.kind != SpecNodeKind.list || res.field == null) {
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.kindMismatch,
        message: 'expected a list but path resolves to ${res.kind.name}',
      ));
      continue;
    }
    final min = res.field!.min;
    final count = doc.listItemCount(path);
    if (min != null && count < min) {
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.minItems,
        message: 'list holds $count item(s) but requires at least $min',
      ));
    }
  }

  return errors;
}

SpecValidationError _dangling(String path) => SpecValidationError(
      path: path,
      code: SpecValidationCode.danglingPath,
      message: 'path does not resolve to any model node',
    );
