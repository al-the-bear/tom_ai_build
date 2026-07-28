// YRD10 census: single-*list* wrapper classes whose only members are exactly
// one list field (optionally preceded by one bare `content` leaf) and which add
// a redundant hierarchy level over the list they carry.
//
// This is the LIST specialisation of the TSMA4/TSMA5 single-subsection wrapper
// audit (see `tsma4_census.dart` and the validator's
// `tom_specs_model_rules.md` §5.8 check). It was surfaced by the
// headline/id analysis, where `FR → FRE-REQU-LST → FRE-REQU-1` looked one level
// too deep. The audit records, for every class matching the pure list-wrapper
// *member shape*, the referrer shape and the keep/collapse verdict, so the
// decision for each is traceable.
//
// A class W matches the pure list-wrapper shape when:
//   * it has EXACTLY ONE list field `s`, AND
//   * every other field is a `content` leaf (isLeaf && isContentLike, named
//     `content`) — zero or one such leaf.
//
// The collapse verdict then applies the keep-a-level exemptions
// (`tom_specs_model_rules.md` §5.8 / TSMA5):
//   KEEP if @Document / container / SBP root;
//   KEEP if shared/list-element (not exactly one complex referrer, or reached
//         as a list element anywhere) — TSMA3 sharing rule;
//   KEEP if @Form (class-, list-field-, or content-leaf-level) — form structure
//         would be lost by promotion;
//   KEEP if the content leaf carries substantive @ContentHelp /
//         @StandardReferences / a non-Form @ContentType — documents a distinct
//         concept;
//   otherwise COLLAPSE (promote the list onto the parent field, folding W's
//   @SectionId semantics into the -LST field — TSMA4 mechanics).
//
// Non-pure list-owning classes (a list plus a @Form summary, a named scalar,
// or multiple leaves — e.g. FunctionalRequirements) are reported separately as
// KEPT with the disqualifying reason, so the "keep" decisions are on record.
//
// Read-only. Usage:
//   dart run tool/yrd10_list_wrapper_census.dart --package ../tom_specs_model [--verbose]
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

  // Referrer counts across the whole model (TSMA3 sharing semantics).
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

  final collapse = <ModelClass>[]; // pure shape, no exemption → collapse
  final keptShared = <ModelClass>[]; // pure shape but shared/list-element
  final keptForm = <ModelClass>[]; // pure shape but @Form present
  final keptHelpRefs = <ModelClass>[]; // pure shape but help/refs/@CType
  final keptNonPure = <(ModelClass, String)>[]; // one list + disqualifying sibling

  for (final c in classes.values) {
    if (c.name == container) continue;
    if (c.name == 'D00SolutionBlueprint') continue;
    if (c.getAnnotation('Document') != null) continue;

    final lists = c.fields.where((f) => f.isList).toList();
    if (lists.length != 1) continue; // must own exactly one list
    final others = c.fields.where((f) => !f.isList).toList();

    // Pure shape: every non-list field is a bare `content` leaf.
    final isPure = others.every(
      (f) => f.isLeaf && f.isContentLike && f.name == 'content',
    );
    if (!isPure) {
      // Report why this list-owner is NOT a pure wrapper (kept unchanged).
      final reasons = <String>[];
      final formSibling = others.any(
          (f) => f.getAnnotation('Form') != null || f.formFields.isNotEmpty);
      if (c.getAnnotation('Form') != null || c.formFields.isNotEmpty) {
        reasons.add('class @Form');
      }
      if (formSibling) reasons.add('@Form sibling');
      final nonContentLeaves =
          others.where((f) => f.name != 'content').map((f) => f.name).toList();
      if (nonContentLeaves.isNotEmpty) {
        reasons.add('named siblings $nonContentLeaves');
      }
      final complexSibling =
          others.any((f) => f.isComplex || f.isSectionType);
      if (complexSibling) reasons.add('complex/section sibling');
      if (reasons.isEmpty) reasons.add('non-content sibling');
      keptNonPure.add((c, reasons.join(', ')));
      continue;
    }

    // Pure list-wrapper. Apply keep-a-level exemptions.
    final unshared = (complexRef[c.name] ?? 0) == 1 && (listRef[c.name] ?? 0) == 0;
    if (!unshared) {
      keptShared.add(c);
      continue;
    }
    final classForm = c.getAnnotation('Form') != null || c.formFields.isNotEmpty;
    final anyFieldForm = c.fields
        .any((f) => f.getAnnotation('Form') != null || f.formFields.isNotEmpty);
    if (classForm || anyFieldForm) {
      keptForm.add(c);
      continue;
    }
    final helpRefs = others.any((f) {
      if (f.getAnnotation('ContentHelp') != null) return true;
      if (f.getAnnotation('StandardReferences') != null) return true;
      final ct = f.getAnnotation('ContentType');
      return ct != null && (ct.arguments['type'] as String? ?? 'Form') != 'Form';
    });
    if (helpRefs) {
      keptHelpRefs.add(c);
      continue;
    }
    collapse.add(c);
  }

  String listOf(ModelClass c) {
    final s = c.fields.firstWhere((f) => f.isList);
    return '${s.name}:List<${s.listElementTypeName}>';
  }

  String annNames(List<AnnotationData> a) =>
      a.isEmpty ? '-' : a.map((x) => x.name).join(',');

  final pureTotal =
      collapse.length + keptShared.length + keptForm.length + keptHelpRefs.length;
  stdout.writeln('=== YRD10 list-wrapper census (${classes.length} classes) ===');
  stdout.writeln('pure single-list wrappers ({content?}+1 list): $pureTotal');
  stdout.writeln('  COLLAPSE (unshared, no @Form/help/refs):  ${collapse.length}');
  stdout.writeln('  kept: shared / list-element:               ${keptShared.length}');
  stdout.writeln('  kept: @Form present:                       ${keptForm.length}');
  stdout.writeln('  kept: @ContentHelp/@Refs/@CType:           ${keptHelpRefs.length}');
  stdout.writeln('non-pure list owners (kept unchanged):       ${keptNonPure.length}');

  if (collapse.isNotEmpty) {
    stdout.writeln('\n--- COLLAPSE candidates ---');
    collapse.sort((a, b) => a.name.compareTo(b.name));
    for (final c in collapse) {
      final sp = soleParent[c.name];
      final where = sp == null ? '(unknown)' : '${sp.$1}.${sp.$2}';
      stdout.writeln('${c.name}  [classAnn: ${annNames(c.annotations)}]');
      stdout.writeln('    parent = $where   list = ${listOf(c)}');
    }
  }

  if (verbose) {
    void dump(String title, List<ModelClass> cs) {
      if (cs.isEmpty) return;
      stdout.writeln('\n--- $title ---');
      cs.sort((a, b) => a.name.compareTo(b.name));
      for (final c in cs) {
        stdout.writeln('${c.name}  list=${listOf(c)}  '
            'refs(cx=${complexRef[c.name] ?? 0},lst=${listRef[c.name] ?? 0})');
      }
    }

    dump('kept: shared / list-element', keptShared);
    dump('kept: @Form present', keptForm);
    dump('kept: @ContentHelp/@Refs/@CType', keptHelpRefs);

    if (keptNonPure.isNotEmpty) {
      stdout.writeln('\n--- non-pure list owners (kept) ---');
      keptNonPure.sort((a, b) => a.$1.name.compareTo(b.$1.name));
      for (final (c, reason) in keptNonPure) {
        stdout.writeln('${c.name}  list=${listOf(c)}  → keep: $reason');
      }
    }
  }
}
