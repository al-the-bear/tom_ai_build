// Census tool for TSMA3: the *keep-a-class* boundary of the TSMA simplification.
//
// TSMA1 collapsed single-`content` leaf classes into shape-(3) fields; TSMA2
// collapsed single-`content` *unshared* list-element leaves into shape-(6)
// `List<String>`. TSMA3 is the complement: it enumerates the leaf classes that
// must STAY classes and confirms none of them is a collapse candidate.
//
// Two keep-a-class groups (`tom_specs_model_rules.md` §5.8):
//   (1) SHARED substructure — a leaf class referenced by MORE THAN ONE parent
//       field (complexRef + listRef > 1). Inlining it would duplicate the
//       definition at each use site, so it stays a class (shape (4)/(5)).
//   (2) FORM-BEARING list elements — a leaf class used as a `List<L>` element
//       whose element carries `@Form` (field-level on `content`, or class-level).
//       A scalar `List<String>` (shape (6)) cannot express per-element form
//       structure, so it stays `List<SectionClass>` (shape (5)).
//
// Read-only. Usage:  dart run tool/keep_class_census.dart --package ../tom_specs_model
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package', abbr: 'p', defaultsTo: '../tom_specs_model')
    ..addFlag('list', help: 'List every kept class name.', defaultsTo: false)
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
        }
      }
    }
  }

  bool isLeafClass(ModelClass c) {
    if (c.fields.isEmpty) return false;
    for (final f in c.fields) {
      if (f.isList || f.isSectionType || f.isComplex) return false;
    }
    return true;
  }

  bool isDocOrContainer(ModelClass c) =>
      c.name == container || c.getAnnotation('Document') != null;

  bool carriesForm(ModelClass c) {
    if (c.getAnnotation('Form') != null || c.formFields.isNotEmpty) return true;
    for (final f in c.fields) {
      if (f.getAnnotation('Form') != null || f.formFields.isNotEmpty) return true;
    }
    return false;
  }

  final leafClasses =
      classes.values.where((c) => isLeafClass(c) && !isDocOrContainer(c)).toList();

  int refs(String name) => (complexRef[name] ?? 0) + (listRef[name] ?? 0);

  final shared = <ModelClass>[]; // group (1): total refs > 1
  final formList = <ModelClass>[]; // group (2): list element carrying @Form
  for (final c in leafClasses) {
    final isShared = refs(c.name) > 1;
    final isFormList = (listRef[c.name] ?? 0) > 0 && carriesForm(c);
    if (isShared) shared.add(c);
    if (isFormList) formList.add(c);
  }
  final union = {...shared, ...formList}.toList();

  stdout.writeln('=== TSMA3 keep-a-class census ===');
  stdout.writeln('total classes:                 ${classes.length}');
  stdout.writeln('leaf classes (non-doc):        ${leafClasses.length}');
  stdout.writeln('(1) shared leaves (refs>1):    ${shared.length}');
  stdout.writeln('(2) form-bearing list leaves:  ${formList.length}');
  stdout.writeln('union kept (1)+(2):            ${union.length}');

  shared.sort((a, b) => refs(b.name).compareTo(refs(a.name)));
  stdout.writeln('\ntop shared leaves by reference count:');
  for (final c in shared.take(10)) {
    stdout.writeln('  ${c.name}  refs=${refs(c.name)} '
        '(complex=${complexRef[c.name] ?? 0}, list=${listRef[c.name] ?? 0})');
  }

  if (results.flag('list')) {
    stdout.writeln('\n--- (1) shared leaves ---');
    for (final c in shared) {
      stdout.writeln('  ${c.name}  refs=${refs(c.name)}');
    }
    stdout.writeln('\n--- (2) form-bearing list leaves ---');
    formList.sort((a, b) => a.name.compareTo(b.name));
    for (final c in formList) {
      stdout.writeln('  ${c.name}  listRef=${listRef[c.name]}');
    }
  }
}
