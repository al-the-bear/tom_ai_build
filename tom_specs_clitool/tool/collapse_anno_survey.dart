// Survey: which annotation types appear on TSMA1 candidate classes, on their
// single `content` field, and on the sole parent field that references them.
// Drives the codemod's annotation-migration rules.
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package', abbr: 'p', defaultsTo: '../tom_specs_model');
  final results = parser.parse(arguments);
  final packagePath = p.normalize(p.absolute(results.option('package')!));
  final libPath = p.join(packagePath, 'lib');

  final driver = createAnalysisDriver(packagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);
  final classes = reader.classes;
  final container = findContainerRoot(classes);

  String baseType(String t) => t.endsWith('?') ? t.substring(0, t.length - 1) : t;

  final complexRef = <String, int>{};
  final listRef = <String, int>{};
  final soleParentField = <String, ModelField>{};
  final soleParentClass = <String, ModelClass>{};
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
          soleParentField[t] = f;
          soleParentClass[t] = parent;
        }
      }
    }
  }

  bool isLeaf(ModelClass c) {
    if (c.fields.isEmpty) return false;
    for (final f in c.fields) {
      if (f.isList || f.isSectionType || f.isComplex) return false;
    }
    return true;
  }

  final classAnno = <String, int>{};
  final fieldAnno = <String, int>{};
  final parentAnno = <String, int>{};

  var count = 0;
  for (final c in classes.values) {
    if (c.name == container || c.getAnnotation('Document') != null) continue;
    if (!isLeaf(c)) continue;
    if ((complexRef[c.name] ?? 0) != 1) continue;
    if ((listRef[c.name] ?? 0) != 0) continue;
    if (c.fields.length != 1) continue;
    count++;
    for (final a in c.annotations) {
      classAnno[a.name] = (classAnno[a.name] ?? 0) + 1;
    }
    for (final a in c.fields.single.annotations) {
      fieldAnno[a.name] = (fieldAnno[a.name] ?? 0) + 1;
    }
    final pf = soleParentField[c.name];
    if (pf != null) {
      for (final a in pf.annotations) {
        parentAnno[a.name] = (parentAnno[a.name] ?? 0) + 1;
      }
    }
  }

  void dump(String label, Map<String, int> m) {
    stdout.writeln('\n$label:');
    final keys = m.keys.toList()..sort((a, b) => m[b]!.compareTo(m[a]!));
    for (final k in keys) {
      stdout.writeln('  @$k: ${m[k]}');
    }
  }

  stdout.writeln('candidates: $count');
  dump('class-level annotations', classAnno);
  dump('content-field annotations', fieldAnno);
  dump('parent-field annotations', parentAnno);
}
