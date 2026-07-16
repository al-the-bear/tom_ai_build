// TSMA4 codemod: collapse a single-subsection wrapper class by promoting its
// one subsection onto the parent field (the dual of TSMA1).
//
// A *wrapper candidate* W is a non-Document, non-container class that:
//   * is referenced by EXACTLY ONE parent field as a single complex field
//     (complexRef == 1, listRef == 0) — unshared (TSMA3 shared-class rule),
//   * has EXACTLY ONE subsection field `s` (isList | isComplex | isSectionType),
//   * whose every OTHER field is a String/enum leaf that carries NO independent
//     meaning: no `@Form`, and no `@ContentHelp` / `@StandardReferences` /
//     non-Form `@ContentType`, and no leaf named anything but `content`
//     (a bare/`@Unused` `content` intro is the only permitted sibling).
//     Form-bearing or content-documented wrappers are TSMA5 keep-the-level cases.
//
// For each candidate the parent field `W w` is rewritten to the promoted
// subsection under the parent's own field name, and class W is deleted:
//     @SerializationOrder(m)  W w = W();
//   → [folded @StandardReferences from W, if the child lacks one]
//     <child annotations except @SerializationOrder, verbatim>
//     [folded @ContentHelp/@MapsTo/@DetailedIn/@SecondLevelSectionId from W,
//      if the child lacks them]
//     @SerializationOrder(m)          // the PARENT field's sibling order wins
//     <childType> w = <childInit>;
// W's own `@SectionId` retires with the removed level; its citations/guidance
// fold onto the promoted field where the child does not already carry them.
//
// Semantics come from the resolved ModelReader; offsets + verbatim annotation
// text come from a second unresolved AST pass. Run iteratively (collapses
// cascade — re-census after each pass) until zero candidates remain.
//
// Usage:
//   dart run tool/collapse_wrappers.dart --package ../tom_specs_model
//       [--only Name] [--dry-run] [--limit N]
//
// One-shot migration utility: uses raw-AST accessors whose names shift between
// analyzer releases, so version-drift deprecations are ignored here.
// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

class _Edit {
  final int start;
  final int end;
  final String replacement;
  final String tag;
  _Edit(this.start, this.end, this.replacement, this.tag);
}

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package', abbr: 'p', defaultsTo: '../tom_specs_model')
    ..addOption('only', help: 'Collapse only this candidate class (by name).')
    ..addOption('limit', help: 'Collapse at most N candidates.')
    ..addFlag('dry-run', defaultsTo: false)
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
  final dryRun = results.flag('dry-run');
  final only = results.option('only');
  final limit = int.tryParse(results.option('limit') ?? '');

  // ── Phase 1: semantic census ────────────────────────────────────────────
  final driver = createAnalysisDriver(packagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(libPath);
  final classes = reader.classes;
  final container = findContainerRoot(classes);
  String baseType(String t) =>
      t.endsWith('?') ? t.substring(0, t.length - 1) : t;

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

  final candidateNames = <String>[];
  for (final c in classes.values) {
    if (c.name == container || c.getAnnotation('Document') != null) continue;
    if ((complexRef[c.name] ?? 0) != 1 || (listRef[c.name] ?? 0) != 0) continue;
    final subs = c.fields.where(isSubsection).toList();
    if (subs.length != 1) continue;
    final others = c.fields.where((f) => !isSubsection(f)).toList();
    if (others.any((f) => !f.isLeaf)) continue;
    // Blockers → TSMA5 keep-the-level.
    final classForm = c.getAnnotation('Form') != null || c.formFields.isNotEmpty;
    final anyFieldForm = c.fields
        .any((f) => f.getAnnotation('Form') != null || f.formFields.isNotEmpty);
    final leafHasMeaning = others.any((f) =>
        f.name != 'content' ||
        f.getAnnotation('ContentHelp') != null ||
        f.getAnnotation('StandardReferences') != null ||
        (f.getAnnotation('ContentType') != null &&
            (f.getAnnotation('ContentType')!.arguments['type'] as String? ??
                    'Form') !=
                'Form'));
    if (classForm || anyFieldForm || leafHasMeaning) continue;
    candidateNames.add(c.name);
  }
  candidateNames.sort();
  if (only != null) {
    candidateNames.retainWhere((n) => n == only);
    if (candidateNames.isEmpty) {
      stderr.writeln('No candidate named "$only".');
      exit(1);
    }
  }
  if (limit != null && candidateNames.length > limit) {
    candidateNames.removeRange(limit, candidateNames.length);
  }

  stdout.writeln('Collapsing ${candidateNames.length} wrapper(s)'
      '${dryRun ? ' (dry-run)' : ''}...');

  // Which model field of W is the subsection (by name) — needed in the AST pass.
  final subFieldName = <String, String>{};
  for (final n in candidateNames) {
    subFieldName[n] = classes[n]!.fields.firstWhere(isSubsection).name;
  }

  // ── Phase 2: source AST pass (offsets + verbatim text) ──────────────────
  final srcDir = Directory(p.join(libPath, 'src'));
  final dartFiles = srcDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !_excluded(srcDir.path, f.path))
      .toList();

  final classDecls = <String, _ClassSrc>{};
  final fileSources = <String, String>{};
  for (final f in dartFiles) {
    final content = f.readAsStringSync();
    fileSources[f.path] = content;
    final unit = parseString(content: content, path: f.path).unit;
    for (final decl in unit.declarations) {
      if (decl is ClassDeclaration) {
        classDecls[decl.name.lexeme] = _ClassSrc(f.path, decl, content);
      }
    }
  }

  // ── Phase 3: compute edits ──────────────────────────────────────────────
  final editsByFile = <String, List<_Edit>>{};
  var planned = 0;
  for (final wName in candidateNames) {
    final wSrc = classDecls[wName];
    final pcName = soleParent[wName]!.$1;
    final pfName = soleParent[wName]!.$2;
    final pcSrc = classDecls[pcName];
    if (wSrc == null || pcSrc == null) {
      stderr.writeln('  SKIP $wName: missing source decl');
      continue;
    }
    final parentField = _findField(pcSrc.decl, pfName);
    final childField = _findField(wSrc.decl, subFieldName[wName]!);
    if (parentField == null || childField == null) {
      stderr.writeln('  SKIP $wName: parent/child field not found');
      continue;
    }

    final newField = _buildPromotedField(
      wDecl: wSrc.decl,
      wSource: wSrc.source,
      childField: childField,
      parentField: parentField,
      parentSource: pcSrc.source,
      fieldName: pfName,
    );

    final pfStart = _memberStart(parentField);
    final pfEnd = parentField.endToken.end;
    editsByFile.putIfAbsent(pcSrc.path, () => []).add(
        _Edit(pfStart, pfEnd, newField, 'field:$pcName.$pfName←$wName'));

    final wStart = _memberStart(wSrc.decl);
    var wEnd = wSrc.decl.endToken.end;
    final srcText = wSrc.source;
    if (wEnd < srcText.length && srcText[wEnd] == '\n') wEnd++;
    editsByFile
        .putIfAbsent(wSrc.path, () => [])
        .add(_Edit(wStart, wEnd, '', 'class:$wName'));

    planned++;
    if (dryRun && candidateNames.length <= 8) {
      stdout.writeln('── $wName → $pcName.$pfName ──');
      stdout.writeln(newField);
    }
  }

  stdout.writeln('Planned $planned collapse(s) across '
      '${editsByFile.length} file(s).');
  if (dryRun) return;

  // ── Phase 4: apply edits per file (descending offset) ───────────────────
  for (final entry in editsByFile.entries) {
    final path = entry.key;
    final edits = entry.value..sort((a, b) => b.start.compareTo(a.start));
    for (var i = 1; i < edits.length; i++) {
      if (edits[i].end > edits[i - 1].start) {
        stderr.writeln('OVERLAP in $path: ${edits[i].tag} vs '
            '${edits[i - 1].tag}');
        exit(1);
      }
    }
    var text = fileSources[path]!;
    for (final e in edits) {
      text = text.substring(0, e.start) + e.replacement + text.substring(e.end);
    }
    File(path).writeAsStringSync(text);
  }
  stdout.writeln('Wrote ${editsByFile.length} file(s).');
}

class _ClassSrc {
  final String path;
  final ClassDeclaration decl;
  final String source;
  _ClassSrc(this.path, this.decl, this.source);
}

bool _excluded(String srcDirPath, String filePath) {
  if (filePath.endsWith('.versioner.dart')) return true;
  final rel = p.relative(filePath, from: srcDirPath);
  final first = p.split(rel).first;
  return first == 'snapshot' || first == 'serialization' || first == 'generated';
}

int _memberStart(AnnotatedNode node) {
  final doc = node.documentationComment;
  if (doc != null) return doc.offset;
  if (node.metadata.isNotEmpty) return node.metadata.first.offset;
  return node.firstTokenAfterCommentAndMetadata.offset;
}

FieldDeclaration? _findField(ClassDeclaration cls, String name) {
  for (final m in cls.members) {
    if (m is FieldDeclaration) {
      for (final v in m.fields.variables) {
        if (v.name.lexeme == name) return m;
      }
    }
  }
  return null;
}

String _annoName(Annotation a) => a.name.name;
String _slice(String source, AstNode node) =>
    source.substring(node.offset, node.end);

/// Builds the replacement source for the promoted field.
///
/// Order: [folded @StandardReferences at front] + child annotations (verbatim,
/// minus @SerializationOrder) + [folded @ContentHelp / traceability from W] +
/// the parent field's @SerializationOrder (sibling-ordering authority) last,
/// then `<childType> <fieldName> = <childInit>;`. W's `@SectionId` is dropped
/// (the level is removed); its citations/guidance fold only where the child
/// does not already carry them.
String _buildPromotedField({
  required ClassDeclaration wDecl,
  required String wSource,
  required FieldDeclaration childField,
  required FieldDeclaration parentField,
  required String parentSource,
  required String fieldName,
}) {
  // Child annotations (verbatim), excluding @SerializationOrder.
  final childAnnoNames = <String>{};
  final frontStandardRefs = <String>[]; // @StandardReferences goes first.
  final childAnnos = <String>[];
  for (final a in childField.metadata) {
    final n = _annoName(a);
    if (n == 'SerializationOrder') continue;
    childAnnoNames.add(n);
    final src = _slice(wSource, a);
    if (n == 'StandardReferences') {
      frontStandardRefs.add(src);
    } else {
      childAnnos.add(src);
    }
  }

  // Fold W's own annotations onto the promoted field where the child lacks them.
  // @SectionId / @SectionIdPattern are never folded (the W level is retired).
  final foldFront = <String>[]; // @StandardReferences
  final foldMid = <String>[]; // @ContentHelp + traceability
  for (final a in wDecl.metadata) {
    final n = _annoName(a);
    if (childAnnoNames.contains(n)) continue;
    if (n == 'SectionId' || n == 'SectionIdPattern') continue;
    final src = _slice(wSource, a);
    if (n == 'StandardReferences' && frontStandardRefs.isEmpty) {
      foldFront.add(src);
    } else if (n == 'ContentHelp' ||
        n == 'MapsTo' ||
        n == 'DetailedIn' ||
        n == 'SecondLevelSectionId') {
      foldMid.add(src);
    }
  }

  // Parent field's @SerializationOrder (last).
  Annotation? parentOrder;
  for (final a in parentField.metadata) {
    if (_annoName(a) == 'SerializationOrder') parentOrder = a;
  }

  // Doc comment: prefer the parent field's (describes the section at its
  // position), else the child field's, else W's class doc.
  String? docText;
  if (parentField.documentationComment != null) {
    docText = _slice(parentSource, parentField.documentationComment!);
  } else if (childField.documentationComment != null) {
    docText = _slice(wSource, childField.documentationComment!);
  } else if (wDecl.documentationComment != null) {
    docText = _slice(wSource, wDecl.documentationComment!);
  }

  // Child field type + initializer (verbatim).
  final typeSrc =
      childField.fields.type != null ? _slice(wSource, childField.fields.type!) : 'String?';
  final childVar = childField.fields.variables.single;
  final initSrc = childVar.initializer != null
      ? _slice(wSource, childVar.initializer!)
      : null;

  const ind = '  ';
  final b = StringBuffer();
  if (docText != null) {
    for (final line in docText.split('\n')) {
      b.writeln('$ind$line');
    }
  }
  for (final src in [...foldFront, ...frontStandardRefs, ...childAnnos, ...foldMid]) {
    b.writeln(_reindent(src, ind));
  }
  if (parentOrder != null) {
    b.writeln('$ind${parentOrder.toSource()}');
  }
  b.write('$ind$typeSrc $fieldName');
  if (initSrc != null) b.write(' = $initSrc');
  b.write(';');
  return b.toString();
}

String _reindent(String src, String indent) {
  final lines = src.split('\n');
  if (lines.length == 1) return '$indent$src';
  final out = StringBuffer('$indent${lines.first}');
  for (var i = 1; i < lines.length; i++) {
    out.write('\n$indent${lines[i]}');
  }
  return out.toString();
}
