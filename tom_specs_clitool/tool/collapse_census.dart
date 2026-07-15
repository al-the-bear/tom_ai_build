// Census tool for TSMA1: single-field leaf-class collapse.
//
// Enumerates every model class in `tom_specs_model` and classifies which are
// collapse candidates for TSMA1 — a *single-field leaf class* L that is
// referenced by exactly one parent field as a single complex field (never a
// list element). Such L can be inlined onto the parent as a field-level
// `@SectionId(...) String? f`, eliminating the class without changing the
// document tree.
//
// Reports the distribution so the codemod can be designed against real data:
// how many candidates carry a reserved `content` field vs a named-with-id
// field vs a form.
//
// Usage:  dart run tool/collapse_census.dart --package ../tom_specs_model
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package',
        abbr: 'p',
        help: 'Path to the tom_specs_model package.',
        defaultsTo: '../tom_specs_model')
    ..addFlag('list', help: 'List every candidate class name.', defaultsTo: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  final results = parser.parse(arguments);
  if (results.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }

  final packagePath = p.normalize(p.absolute(results.option('package')!));
  final libPath = p.join(packagePath, 'lib');
  if (!Directory(libPath).existsSync()) {
    stderr.writeln('lib/ not found at $libPath');
    exit(1);
  }

  final driver = createAnalysisDriver(packagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);

  final classes = reader.classes;
  final container = findContainerRoot(classes);

  // Reference counts: how many single-complex-field references, and how many
  // list-element references, each class receives across the whole model.
  final complexRef = <String, int>{};
  final listRef = <String, int>{};
  // Track the single referencing (parent, field) for complexRef==1 classes.
  final soleParent = <String, (String, String)>{};

  String baseType(String t) => t.endsWith('?') ? t.substring(0, t.length - 1) : t;

  for (final parent in classes.values) {
    for (final f in parent.fields) {
      if (f.isList) {
        final el = f.listElementTypeName;
        if (el != null && f.listElementIsComplex && classes.containsKey(el)) {
          listRef[el] = (listRef[el] ?? 0) + 1;
        }
      } else if (f.isComplex) {
        final t = baseType(f.typeName);
        if (classes.containsKey(t)) {
          complexRef[t] = (complexRef[t] ?? 0) + 1;
          soleParent[t] = (parent.name, f.name);
        }
      }
    }
  }

  bool isLeafClass(ModelClass c) {
    // All fields are content/form String or enum leaves — no nested classes,
    // no lists, no section types.
    if (c.fields.isEmpty) return false;
    for (final f in c.fields) {
      if (f.isList) return false;
      if (f.isSectionType) return false;
      if (f.isComplex) return false;
    }
    return true;
  }

  bool isDocOrContainer(ModelClass c) =>
      c.name == container || c.getAnnotation('Document') != null;

  final leafClasses = classes.values.where(isLeafClass).toList();
  final contentOnlyLeaves = leafClasses
      .where((c) => c.fields.every((f) => f.isString))
      .toList();

  // Single-complex-ref, never-list candidates.
  final candidates = <ModelClass>[];
  for (final c in classes.values) {
    if (isDocOrContainer(c)) continue;
    if (!isLeafClass(c)) continue;
    if ((complexRef[c.name] ?? 0) != 1) continue;
    if ((listRef[c.name] ?? 0) != 0) continue;
    if (c.fields.length != 1) continue;
    candidates.add(c);
  }

  // Distribution of the single field's shape.
  var reservedContent = 0; // field named `content`, no field-level @SectionId
  var namedWithId = 0; // field with a field-level @SectionId (shape 3)
  var withForm = 0; // single field carries @Form
  var enumField = 0; // single field is an enum
  var other = 0;
  final namedWithIdNames = <String>[];

  for (final c in candidates) {
    final f = c.fields.single;
    final hasFieldSectionId = f.getAnnotation('SectionId') != null;
    final hasForm = f.formFields.isNotEmpty || f.getAnnotation('Form') != null;
    if (hasForm) withForm++;
    if (f.isEnum) {
      enumField++;
    } else if (f.name == 'content' && !hasFieldSectionId) {
      reservedContent++;
    } else if (hasFieldSectionId) {
      namedWithId++;
      namedWithIdNames.add('${c.name}.${f.name}');
    } else {
      other++;
    }
  }

  stdout.writeln('=== TSMA1 census ===');
  stdout.writeln('total classes:            ${classes.length}');
  stdout.writeln('container:                $container');
  stdout.writeln('leaf classes:             ${leafClasses.length}');
  stdout.writeln('content/form-only leaves: ${contentOnlyLeaves.length}');
  stdout.writeln('single-complex-ref, never-list, single-field candidates: '
      '${candidates.length}');
  stdout.writeln('  reserved `content` (no field @SectionId): $reservedContent');
  stdout.writeln('  named field w/ field-level @SectionId:    $namedWithId');
  stdout.writeln('  single field is enum:                     $enumField');
  stdout.writeln('  (of candidates) carrying @Form:           $withForm');
  stdout.writeln('  other:                                    $other');

  if (namedWithIdNames.isNotEmpty) {
    stdout.writeln('\nnamed-with-id examples (first 20):');
    for (final n in namedWithIdNames.take(20)) {
      stdout.writeln('  $n');
    }
  }

  // Per-file distribution of the reserved-content candidates.
  if (results.flag('list')) {
    stdout.writeln('\ncandidates:');
    for (final c in candidates) {
      final f = c.fields.single;
      final sid = c.getAnnotation('SectionId')?.arguments['id'] ??
          f.getAnnotation('SectionId')?.arguments['id'] ??
          '?';
      final sp = soleParent[c.name];
      stdout.writeln('  ${c.name}  [sid=$sid]  field=${f.name}  '
          'parent=${sp?.$1}.${sp?.$2}');
    }
  }
}
