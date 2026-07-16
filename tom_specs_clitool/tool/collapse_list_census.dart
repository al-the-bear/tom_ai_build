// Census tool for TSMA2: pure-content list-element leaf-class collapse.
//
// Enumerates every model class in `tom_specs_model` and classifies which are
// TSMA2 collapse candidates — a *leaf class* L (all fields content/form String
// leaves) that is used ONLY as a `List<L>` element type and has exactly one
// `content` field. Such L can be inlined onto the parent list field as
// `@SectionId(<list id>) @SectionIdPattern(<pattern>) List<String> xs`,
// eliminating the class without changing the document tree.
//
// A candidate must be referenced by exactly one parent field total (the list
// field); shared leaves (reached by >1 field, or also as a single complex
// field) are TSMA3's keep-a-class cases and are excluded.
//
// Usage:  dart run tool/collapse_list_census.dart --package ../tom_specs_model
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

  final complexRef = <String, int>{};
  final listRef = <String, int>{};
  // Track the single referencing list (parent, field) for listRef==1 classes.
  final soleListParent = <String, (String, String)>{};

  String baseType(String t) => t.endsWith('?') ? t.substring(0, t.length - 1) : t;

  for (final parent in classes.values) {
    for (final f in parent.fields) {
      if (f.isList) {
        final el = f.listElementTypeName;
        if (el != null && f.listElementIsComplex && classes.containsKey(el)) {
          listRef[el] = (listRef[el] ?? 0) + 1;
          soleListParent[el] = (parent.name, f.name);
        }
      } else if (f.isComplex) {
        final t = baseType(f.typeName);
        if (classes.containsKey(t)) {
          complexRef[t] = (complexRef[t] ?? 0) + 1;
        }
      }
    }
  }

  bool isLeafClass(ModelClass c) {
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
  final listElementLeaves =
      leafClasses.where((c) => (listRef[c.name] ?? 0) > 0).toList();

  // TSMA2 candidates: leaf, list-element, exactly ONE `content` field,
  // referenced only via a single list field (no complex ref, listRef == 1).
  final candidates = <ModelClass>[];
  final sharedExcluded = <ModelClass>[]; // listRef>1 or complexRef>0
  final multiFieldExcluded = <ModelClass>[]; // form/subsection or >1 field
  for (final c in classes.values) {
    if (isDocOrContainer(c)) continue;
    if (!isLeafClass(c)) continue;
    if ((listRef[c.name] ?? 0) == 0) continue; // must be a list element
    // Single `content` field, no form.
    final single = c.fields.length == 1 &&
        c.fields.single.name == 'content' &&
        c.fields.single.formFields.isEmpty &&
        c.fields.single.getAnnotation('Form') == null &&
        c.fields.single.isString;
    if (!single) {
      multiFieldExcluded.add(c);
      continue;
    }
    // Not shared: exactly one referencing field total.
    if ((listRef[c.name] ?? 0) != 1 || (complexRef[c.name] ?? 0) != 0) {
      sharedExcluded.add(c);
      continue;
    }
    candidates.add(c);
  }

  stdout.writeln('=== TSMA2 census ===');
  stdout.writeln('total classes:              ${classes.length}');
  stdout.writeln('container:                  $container');
  stdout.writeln('leaf classes:               ${leafClasses.length}');
  stdout.writeln('list-element leaf classes:  ${listElementLeaves.length}');
  stdout.writeln('single-content list-element candidates (unshared): '
      '${candidates.length}');
  stdout.writeln('  excluded (shared / multi-ref):   ${sharedExcluded.length}');
  stdout.writeln('  excluded (form/subsection/multi): '
      '${multiFieldExcluded.length}');

  if (sharedExcluded.isNotEmpty) {
    stdout.writeln('\nshared single-content list-elements (kept, TSMA3):');
    for (final c in sharedExcluded) {
      stdout.writeln('  ${c.name}  listRef=${listRef[c.name]} '
          'complexRef=${complexRef[c.name] ?? 0}');
    }
  }

  if (results.flag('list')) {
    stdout.writeln('\ncandidates:');
    for (final c in candidates) {
      final f = c.fields.single;
      final sid = c.getAnnotation('SectionId')?.arguments['id'] ??
          f.getAnnotation('SectionId')?.arguments['id'] ??
          '?';
      final sp = soleListParent[c.name];
      final listSid = classes[sp?.$1]
          ?.fields
          .where((pf) => pf.name == sp?.$2)
          .firstOrNull
          ?.getAnnotation('SectionId')
          ?.arguments['id'];
      final listPat = classes[sp?.$1]
          ?.fields
          .where((pf) => pf.name == sp?.$2)
          .firstOrNull
          ?.getAnnotation('SectionIdPattern')
          ?.arguments['pattern'];
      stdout.writeln('  ${c.name}  [elSid=$sid]  parent=${sp?.$1}.${sp?.$2}  '
          'listSid=$listSid  listPat=$listPat');
    }
  }
}
