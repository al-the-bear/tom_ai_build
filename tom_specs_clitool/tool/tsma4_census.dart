// Census/probe for TSMA4: single-subsection wrapper classes whose own content
// has no independent meaning, which can be collapsed by promoting the single
// subsection onto the parent field (the dual of TSMA1).
//
// A *wrapper candidate* W is a non-Document, non-container class that:
//   * is referenced by EXACTLY ONE parent field as a single complex field
//     (complexRef == 1, listRef == 0) — unshared (TSMA3 shared rule),
//   * has EXACTLY ONE subsection field `s` (isList | isComplex | isSectionType),
//   * whose every OTHER field is a String/enum leaf (content/form).
//
// TSMA5 keep-the-level blockers (reported, not collapsed):
//   * a content/form leaf that carries @Form,  OR
//   * a content leaf that carries substantive @ContentHelp / @StandardReferences
//     / a non-Form @ContentType (documents the section as a distinct concept).
//
// Read-only. Prints, for each candidate, the subsection kind + ids, the content
// annotations, W's own traceability annotations, and the parent field.
//
// Usage:  dart run tool/tsma4_census.dart --package ../tom_specs_model [--verbose]
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package', abbr: 'p', defaultsTo: '../tom_specs_model')
    ..addFlag('verbose', abbr: 'v', defaultsTo: false)
    ..addFlag('help', abbr: 'h', negatable: false);
  final results = parser.parse(arguments);
  if (results.flag('help')) {
    stdout.writeln(parser.usage);
    return;
  }
  final verbose = results.flag('verbose');

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
  final soleParent = <String, (String, String)>{};
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

  bool isSubsection(ModelField f) => f.isList || f.isComplex || f.isSectionType;

  var singleSubTotal = 0;
  final collapsible = <ModelClass>[]; // clean: content bare/absent, no blockers
  final blockedForm = <ModelClass>[];
  final blockedHelpRefs = <ModelClass>[];
  final blockedMultiLeaf = <ModelClass>[]; // >1 non-subsection leaf field

  for (final c in classes.values) {
    if (c.name == container || c.getAnnotation('Document') != null) continue;
    if ((complexRef[c.name] ?? 0) != 1 || (listRef[c.name] ?? 0) != 0) continue;
    final subs = c.fields.where(isSubsection).toList();
    if (subs.length != 1) continue;
    final others = c.fields.where((f) => !isSubsection(f)).toList();
    // Every non-subsection field must be a leaf (String/enum).
    if (others.any((f) => !f.isLeaf)) continue;
    singleSubTotal++;

    // Classify the content/other leaves.
    final classForm =
        c.getAnnotation('Form') != null || c.formFields.isNotEmpty;
    final anyFieldForm = c.fields.any(
        (f) => f.getAnnotation('Form') != null || f.formFields.isNotEmpty);
    final anyHelpRefs = others.any((f) =>
        f.getAnnotation('ContentHelp') != null ||
        f.getAnnotation('StandardReferences') != null ||
        (f.getAnnotation('ContentType') != null &&
            (f.getAnnotation('ContentType')!.arguments['type'] as String? ??
                    'Form') !=
                'Form'));
    // Non-`content` leaf fields (a named leaf besides `content`) make the
    // wrapper carry independent scalar meaning → keep (multi-leaf).
    final nonContentLeaves =
        others.where((f) => f.name != 'content').toList();

    if (classForm || anyFieldForm) {
      blockedForm.add(c);
    } else if (anyHelpRefs) {
      blockedHelpRefs.add(c);
    } else if (nonContentLeaves.isNotEmpty) {
      blockedMultiLeaf.add(c);
    } else {
      collapsible.add(c);
    }
  }

  String subKind(ModelField f) => f.isList
      ? 'list<${f.listElementTypeName}>'
      : f.isSectionType
          ? 'section:${f.typeName}'
          : 'complex:${baseType(f.typeName)}';
  String annNames(List<AnnotationData> a) =>
      a.isEmpty ? '-' : a.map((x) => x.name).join(',');

  stdout.writeln('=== TSMA4 census (${classes.length} classes) ===');
  stdout.writeln('single-subsection wrappers (unshared, leaf-only siblings): '
      '$singleSubTotal');
  stdout.writeln('  COLLAPSIBLE (content bare/absent, no blockers): '
      '${collapsible.length}');
  stdout.writeln('  blocked @Form (TSMA5):                 ${blockedForm.length}');
  stdout.writeln('  blocked @ContentHelp/@Refs/@CType:     '
      '${blockedHelpRefs.length}');
  stdout.writeln('  blocked extra non-content leaf:        '
      '${blockedMultiLeaf.length}');

  final byKind = <String, int>{};
  for (final c in collapsible) {
    final s = c.fields.firstWhere(isSubsection);
    final k = s.isList ? 'list' : (s.isSectionType ? 'section' : 'complex');
    byKind[k] = (byKind[k] ?? 0) + 1;
  }
  stdout.writeln('  collapsible by child kind: $byKind');

  if (verbose) {
    stdout.writeln('\n--- COLLAPSIBLE candidates ---');
    collapsible.sort((a, b) => a.name.compareTo(b.name));
    for (final c in collapsible) {
      final s = c.fields.firstWhere(isSubsection);
      final sp = soleParent[c.name]!;
      final hasContent = c.fields.any((f) => f.name == 'content');
      stdout.writeln('${c.name}  [classAnn: ${annNames(c.annotations)}]');
      stdout.writeln('    parent      = ${sp.$1}.${sp.$2}');
      stdout.writeln('    subsection  = ${s.name}:${subKind(s)} '
          '[fieldAnn: ${annNames(s.annotations)}]');
      stdout.writeln('    content?    = $hasContent  '
          'otherFields=${c.fields.where((f) => !isSubsection(f)).map((f) => f.name).toList()}');
    }
  }
}
