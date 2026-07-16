// Probe: for TSMA2 candidates, report each element's content @ContentType and
// whether the element or its content field carries @Form / extra annotations
// that would be lost by collapse to List<String>. Read-only.
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
        if (classes.containsKey(t)) complexRef[t] = (complexRef[t] ?? 0) + 1;
      }
    }
  }
  bool isLeaf(ModelClass c) =>
      c.fields.isNotEmpty &&
      c.fields.every((f) => !f.isList && !f.isSectionType && !f.isComplex);

  final contentTypes = <String, int>{};
  final withElementExtras = <String>[];
  var count = 0;
  for (final c in classes.values) {
    if (c.name == container || c.getAnnotation('Document') != null) continue;
    if (!isLeaf(c)) continue;
    if ((listRef[c.name] ?? 0) != 1 || (complexRef[c.name] ?? 0) != 0) continue;
    final single = c.fields.length == 1 &&
        c.fields.single.name == 'content' &&
        c.fields.single.formFields.isEmpty &&
        c.fields.single.getAnnotation('Form') == null &&
        c.fields.single.isString;
    if (!single) continue;
    count++;
    final cf = c.fields.single;
    final ct = cf.getAnnotation('ContentType')?.arguments['type'] as String? ??
        '(none)';
    contentTypes[ct] = (contentTypes[ct] ?? 0) + 1;
    // Element-class or content-field annotations besides SectionId/ContentType/
    // SerializationOrder/StandardReferences — anything else would be lost.
    const known = {
      'SectionId',
      'ContentType',
      'SerializationOrder',
      'StandardReferences',
    };
    final extras = <String>{};
    for (final a in c.annotations) {
      if (!known.contains(a.name)) extras.add('class:${a.name}');
    }
    for (final a in cf.annotations) {
      if (!known.contains(a.name)) extras.add('content:${a.name}');
    }
    if (extras.isNotEmpty) withElementExtras.add('${c.name} → $extras');
  }

  stdout.writeln('candidates: $count');
  stdout.writeln('content types: $contentTypes');
  stdout.writeln('element extra annotations (would be lost):');
  for (final e in withElementExtras) {
    stdout.writeln('  $e');
  }
}
