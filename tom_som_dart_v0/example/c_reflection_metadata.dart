// Sample (c) — REFLECTION / meta-information access (som_multiplatform_spec_model.md §6).
//
// HAND-AUTHORED — preserved across `generate_som` runs.
//
// Demonstrates the value-free "reflection" surface: take the model this
// package was generated from and query its shape with `SpecReflection` —
// enumerate roots and fields, and resolve a concrete document *path* to the
// model node it lands on. No document values are involved; this answers
// "what CAN the model hold?", not "what does a given document hold?".
//
// Run from this package:  dart run example/c_reflection_metadata.dart
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';
import 'package:tom_som_dart_v0/tom_som_dart_v0_model.dart';

void main() {
  // The whole model, in one expression (SOM §10.3). This import is separate
  // from the main facade because the payload is 6.4 MB — a consumer that never
  // reads the model never compiles it.
  //
  // Earlier revisions of this sample read `meta/spec_model.meta.json` through
  // `Platform.script.resolve('../meta/…')`. That works only *inside* this
  // package, which is the trap: copied into a consuming project — exactly what
  // an example invites — it resolves against the consumer's own script and
  // silently reads nothing. `somSpecModel` has no such footgun and, unlike a
  // package-relative read, survives `dart compile exe`.
  final model = somSpecModel;
  final reflection = SpecReflection(model);

  print('Model version: ${model.modelVersion} '
      '(${model.modelVersionLabel ?? 'unstamped'})');
  print('Roots: ${reflection.roots.length}, '
      'classes: ${reflection.classes.length}\n');

  // Enumerate the document roots by their addressable segment.
  print('Document roots:');
  for (final root in reflection.roots) {
    print('  ${reflection.rootSegment(root).padRight(4)} ${root.title}');
  }

  // Inspect the fields of the D00SolutionBlueprint root class.
  final pdRoot = reflection.rootForSegment('SBP')!;
  final pdFields = reflection.fieldsOf(pdRoot.type);
  print('\nFirst fields of ${pdRoot.type} (${pdFields.length} total):');
  for (final field in pdFields.take(6)) {
    print('  ${field.name.padRight(24)} '
        'kind=${field.kind.name}'
        '${field.type != null ? '  type=${field.type}' : ''}'
        '${field.elementType != null ? '  elem=${field.elementType}' : ''}');
  }

  // Resolve concrete document paths to model nodes (value-free).
  print('\nPath resolution:');
  for (final path in [
    'SBP',
    'SBP/content',
    'SBP/currentLandscape',
    'SBP/currentLandscape/CUOPME-OPER-LST',
  ]) {
    final res = reflection.resolve(path);
    if (res == null) {
      print('  $path  ->  (unresolved)');
      continue;
    }
    print('  ${path.padRight(40)} -> kind=${res.kind.name}'
        '${res.targetClass != null ? '  class=${res.targetClass!.name}' : ''}'
        '  valueLeaf=${res.isValueLeaf}');
  }
}
