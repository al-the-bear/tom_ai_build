// TSMA2 codemod: collapse pure-content list-element leaf classes into a
// `List<String>` inline content sub-section list
// (`tom_specs_model_rules.md` §5.1 shape 6).
//
// A *collapse candidate* is a leaf class L (all fields are content/form String
// leaves) that:
//   * has exactly one field, a reserved `content` String,
//   * whose `content` field carries no `@Form` and no class-level `@Form`
//     (a form-bearing element keeps per-element structure — TSMA3),
//   * is referenced by exactly one parent field `List<L> f` (listRef == 1) and
//     never as a single complex field (complexRef == 0) — an *unshared* list
//     element (shared elements are TSMA3's keep-a-class cases),
//   * is not a @Document root nor the container.
//
// For each such L the codemod rewrites the parent list field
//     @SectionId('<E>-<F>-LST') @SectionIdPattern('<E>-<F>-xxx') [ann]
//     List<L> f = [];
// into the inline-content-list shape
//     @SectionId('<E>-<F>-LST') @SectionIdPattern('<E>-<F>-xxx') [ann]
//     List<String> f = [];
// (only the element type token `L` → `String`; every annotation and the `= []`
// initializer are preserved) and deletes class L. The `-LST` container id and
// the `-xxx` pattern already encode the element mnemonic, so no annotation
// migration is needed; the element's own `@SectionId`/`@ContentType('text')`/
// `@SerializationOrder` are redundant under shape 6 and retire with the class.
//
// Renders identically: every SOM runtime renders a list whose `elementNode` is
// null (a String element) as "the item's value is its body" — the same output
// a single-`content` leaf element produced.
//
// Usage:
//   dart run tool/collapse_list_leaves.dart --package ../tom_specs_model
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
  // element name → (parent class, list field name) for listRef==1 elements.
  final soleListParent = <String, (String, String)>{};
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

  bool isLeaf(ModelClass c) {
    if (c.fields.isEmpty) return false;
    for (final f in c.fields) {
      if (f.isList || f.isSectionType || f.isComplex) return false;
    }
    return true;
  }

  final candidateNames = <String>[];
  final excludedForm = <String>[];
  final excludedShared = <String>[];
  for (final c in classes.values) {
    if (c.name == container || c.getAnnotation('Document') != null) continue;
    if (!isLeaf(c)) continue;
    if ((listRef[c.name] ?? 0) == 0) continue; // must be a list element
    if (c.fields.length != 1) continue;
    final cf = c.fields.single;
    if (cf.name != 'content' || !cf.isString) continue;
    // Exclude form-bearing elements (field-level or class-level @Form): the
    // scalar-list render path does not emit form fields — TSMA3 keeps them.
    if (cf.formFields.isNotEmpty ||
        cf.getAnnotation('Form') != null ||
        c.formFields.isNotEmpty ||
        c.getAnnotation('Form') != null) {
      excludedForm.add(c.name);
      continue;
    }
    // Exclude shared elements (reached by >1 list field or any complex field).
    if ((listRef[c.name] ?? 0) != 1 || (complexRef[c.name] ?? 0) != 0) {
      excludedShared.add(c.name);
      continue;
    }
    candidateNames.add(c.name);
  }
  if (excludedForm.isNotEmpty || excludedShared.isNotEmpty) {
    stdout.writeln('Excluded ${excludedForm.length} form-bearing + '
        '${excludedShared.length} shared list-element leaves (TSMA3).');
    for (final n in excludedForm) {
      stdout.writeln('  [form]   $n');
    }
    for (final n in excludedShared) {
      stdout.writeln('  [shared] $n');
    }
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

  stdout.writeln('Collapsing ${candidateNames.length} candidate(s)'
      '${dryRun ? ' (dry-run)' : ''}...');

  // ── Phase 2: source AST pass (offsets) ──────────────────────────────────
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
  for (final lname in candidateNames) {
    final lSrc = classDecls[lname];
    final pcName = soleListParent[lname]!.$1;
    final pfName = soleListParent[lname]!.$2;
    final pcSrc = classDecls[pcName];
    if (lSrc == null || pcSrc == null) {
      stderr.writeln('  SKIP $lname: missing source decl');
      continue;
    }

    final pf = _findField(pcSrc.decl, pfName);
    if (pf == null) {
      stderr.writeln('  SKIP $lname: parent field $pcName.$pfName not found');
      continue;
    }

    // Locate the element type argument inside `List<L>` and replace `L` with
    // `String`. Everything else on the field is preserved verbatim.
    final elementArg = _listElementTypeNode(pf, lname);
    if (elementArg == null) {
      stderr.writeln('  SKIP $lname: could not locate List<$lname> type '
          'argument on $pcName.$pfName');
      continue;
    }
    editsByFile.putIfAbsent(pcSrc.path, () => []).add(_Edit(
        elementArg.offset, elementArg.end, 'String', 'type:$pcName.$pfName'));

    // Delete class L (doc/annotation start to `}` + trailing newline).
    final lStart = _memberStart(lSrc.decl);
    var lEnd = lSrc.decl.endToken.end;
    final srcText = lSrc.source;
    if (lEnd < srcText.length && srcText[lEnd] == '\n') lEnd++;
    editsByFile
        .putIfAbsent(lSrc.path, () => [])
        .add(_Edit(lStart, lEnd, '', 'class:$lname'));

    planned++;
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

/// Returns the AST node of the element type argument `L` inside the field's
/// `List<L>` type annotation, or null if the field is not `List<L>`.
TypeAnnotation? _listElementTypeNode(FieldDeclaration field, String elementName) {
  final type = field.fields.type;
  if (type is! NamedType) return null;
  if (type.name.lexeme != 'List') return null;
  final args = type.typeArguments?.arguments;
  if (args == null || args.length != 1) return null;
  final arg = args.single;
  if (arg is NamedType && arg.name.lexeme == elementName) return arg;
  return null;
}
