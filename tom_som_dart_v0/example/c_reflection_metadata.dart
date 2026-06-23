// Sample (c) — REFLECTION / meta-information access (plan item #14, spec §3.1).
//
// HAND-AUTHORED — preserved across `generate_som` runs.
//
// Demonstrates the value-free "reflection" surface: load the exported
// meta-data (`meta/spec_model.meta.json`, the lossless class graph) into a
// `SpecModel` and query its shape with `SpecReflection` — enumerate roots and
// fields, and resolve a concrete document *path* to the model node it lands on.
// No document values are involved; this answers "what CAN the model hold?",
// not "what does a given document hold?".
//
// Run from this package:  dart run example/c_reflection_metadata.dart
library;

import 'dart:convert';
import 'dart:io';

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart';

void main() {
  // Locate the meta-data shipped in this package, relative to this script, so
  // the sample runs from any working directory.
  final metaFile = File.fromUri(
      Platform.script.resolve('../meta/spec_model.meta.json'));
  final model = SpecModel.fromJson(
      jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>);
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

  // Inspect the fields of the ProjectDefinition root class.
  final pdRoot = reflection.rootForSegment('PD')!;
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
    'PD',
    'PD/content',
    'PD/currentStateAnalysis',
    'PD/currentStateAnalysis/CUOPME-OPER-LST',
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
