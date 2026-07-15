// TSMA1 codemod: collapse single-field leaf classes into a parent field.
//
// A *collapse candidate* is a leaf class L (all fields are content/form String
// leaves) that:
//   * has exactly one field (a reserved `content` String, possibly @Form'd),
//   * is referenced by exactly one parent field `PC pf` as a single complex
//     field, and
//   * is never used as a list element,
//   * is not a @Document root nor the container.
//
// For each such L the codemod rewrites the parent field
//     <doc>  @SerializationOrder(n)  L pf = L();
// into a field-level content/form section
//     <doc>  @SectionId('<L.sid>') [migrated annotations] @Form([...])
//            @SerializationOrder(n) String? pf;
// and deletes class L. This eliminates the class without changing the document
// tree: field-level @Form renders (post-YRB2) as a section-with-typed-members,
// so the collapsed field serialises equivalently to the class it replaced.
//
// Semantics come from the resolved ModelReader; source offsets and verbatim
// annotation/doc-comment text come from a second unresolved AST pass.
//
// Usage:
//   dart run tool/collapse_leaves.dart --package ../tom_specs_model [--only Name]
//                                       [--dry-run] [--limit N]
//
// One-shot migration utility: uses raw-AST accessors whose names shift between
// analyzer releases (`ClassDeclaration.name`/`.members`), so version-drift
// deprecations are ignored here rather than pinned to one analyzer API surface.
// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// A text replacement in a specific file: `[start, end)` → [replacement].
/// An empty [replacement] deletes the range.
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
    ..addFlag('dry-run',
        help: 'Report planned collapses without writing files.',
        defaultsTo: false)
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
  final soleParentName = <String, String>{};
  final soleParentField = <String, String>{};
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
          soleParentName[t] = parent.name;
          soleParentField[t] = f.name;
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

  // A parent class whose own `content` field carries @ContentType != "Form"
  // (a pure description/markdown section) must not gain a sibling scalar field
  // (§6.4). Collapsing produces a `String?` scalar, so such parents are ruled
  // out.
  bool parentForbidsScalar(ModelClass parent) {
    final cf =
        parent.fields.where((f) => f.name == 'content').firstOrNull;
    if (cf == null) return false;
    final ct = cf.getAnnotation('ContentType');
    if (ct == null) return false;
    final type = ct.arguments['type'] as String? ?? 'Form';
    return type != 'Form';
  }

  final candidateNames = <String>[];
  final excludedContentParentField = <String>[];
  final excludedContentTypeParent = <String>[];
  for (final c in classes.values) {
    if (c.name == container || c.getAnnotation('Document') != null) continue;
    if (!isLeaf(c)) continue;
    if ((complexRef[c.name] ?? 0) != 1) continue;
    if ((listRef[c.name] ?? 0) != 0) continue;
    if (c.fields.length != 1) continue;
    if (c.fields.single.name != 'content') continue; // TSMA1 = reserved content
    // Guard A: a parent field literally named `content` cannot become a
    // shape-3 field (`content` may not carry a field-level @SectionId, §6.1).
    // These are pre-existing complex-`content` smells; leave them untouched.
    if (soleParentField[c.name] == 'content') {
      excludedContentParentField.add(c.name);
      continue;
    }
    // Guard B: parent is a description/markdown section that forbids scalar
    // siblings (§6.4).
    final parent = classes[soleParentName[c.name]];
    if (parent != null && parentForbidsScalar(parent)) {
      excludedContentTypeParent.add(c.name);
      continue;
    }
    candidateNames.add(c.name);
  }
  if (excludedContentParentField.isNotEmpty ||
      excludedContentTypeParent.isNotEmpty) {
    stdout.writeln('Excluded ${excludedContentParentField.length} '
        '(parent field named `content`) + '
        '${excludedContentTypeParent.length} (parent @ContentType forbids '
        'scalar sibling).');
    for (final n in excludedContentParentField) {
      stdout.writeln('  [content-field] $n → ${soleParentName[n]}.'
          '${soleParentField[n]}');
    }
    for (final n in excludedContentTypeParent) {
      stdout.writeln('  [contenttype]   $n → ${soleParentName[n]}.'
          '${soleParentField[n]}');
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
  final candidateSet = candidateNames.toSet();

  stdout.writeln('Collapsing ${candidateNames.length} candidate(s)'
      '${dryRun ? ' (dry-run)' : ''}...');

  // ── Phase 2: source AST pass (offsets + verbatim text) ──────────────────
  final srcDir = Directory(p.join(libPath, 'src'));
  final dartFiles = srcDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !_excluded(srcDir.path, f.path))
      .toList();

  // Per class name: which file declares it, its ClassDeclaration, and source.
  final classDecls = <String, _ClassSrc>{};
  final fileSources = <String, String>{};
  for (final f in dartFiles) {
    final content = f.readAsStringSync();
    fileSources[f.path] = content;
    final unit = parseString(content: content, path: f.path).unit;
    for (final decl in unit.declarations) {
      if (decl is ClassDeclaration) {
        final name = decl.name.lexeme;
        classDecls[name] = _ClassSrc(f.path, decl, content);
      }
    }
  }

  // ── Phase 3: compute edits ──────────────────────────────────────────────
  final editsByFile = <String, List<_Edit>>{};
  var planned = 0;
  for (final lname in candidateNames) {
    final lSrc = classDecls[lname];
    final pcName = soleParentName[lname]!;
    final pfName = soleParentField[lname]!;
    final pcSrc = classDecls[pcName];
    if (lSrc == null || pcSrc == null) {
      stderr.writeln('  SKIP $lname: missing source decl (L=$lSrc pc=$pcSrc)');
      continue;
    }

    // Parent field declaration.
    final pf = _findField(pcSrc.decl, pfName);
    if (pf == null) {
      stderr.writeln('  SKIP $lname: parent field $pcName.$pfName not found');
      continue;
    }

    // Build the collapsed field text.
    final newField = _buildCollapsedField(
      lDecl: lSrc.decl,
      lSource: lSrc.source,
      parentField: pf,
      parentSource: pcSrc.source,
      fieldName: pfName,
    );

    // Edit A: replace parent field (from its doc/annotation start to `;`).
    final pfStart = _memberStart(pf);
    final pfEnd = pf.endToken.end;
    editsByFile.putIfAbsent(pcSrc.path, () => []).add(
        _Edit(pfStart, pfEnd, newField, 'field:$pcName.$pfName←$lname'));

    // Edit B: delete class L (from its doc/annotation start to `}` + trailing
    // blank line).
    final lStart = _memberStart(lSrc.decl);
    var lEnd = lSrc.decl.endToken.end;
    // Swallow a single trailing newline so we don't leave a blank gap.
    final srcText = lSrc.source;
    if (lEnd < srcText.length && srcText[lEnd] == '\n') lEnd++;
    editsByFile.putIfAbsent(lSrc.path, () => []).add(
        _Edit(lStart, lEnd, '', 'class:$lname'));

    planned++;
    if (dryRun && candidateSet.length <= 5) {
      stdout.writeln('── $lname → $pcName.$pfName ──');
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
    // Detect overlaps (a class L and its parent field never overlap, but guard).
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

/// The start offset of a member/class including its leading doc comment.
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

/// Extracts the single `content` field declaration of a candidate class.
FieldDeclaration? _contentField(ClassDeclaration cls) {
  for (final m in cls.members) {
    if (m is FieldDeclaration) {
      for (final v in m.fields.variables) {
        if (v.name.lexeme == 'content') return m;
      }
    }
  }
  return null;
}

String _annoName(Annotation a) => a.name.name;

/// Builds the replacement source for the collapsed field, migrating
/// annotations and doc-comment from class L and its `content` field onto the
/// parent field. Annotation order mirrors the model's shape-3 convention:
/// @SectionId, then schema/help annotations, then @Form/@ContentType, then the
/// parent's @SerializationOrder last.
String _buildCollapsedField({
  required ClassDeclaration lDecl,
  required String lSource,
  required FieldDeclaration parentField,
  required String parentSource,
  required String fieldName,
}) {
  final contentField = _contentField(lDecl)!;

  // Doc comment: prefer the parent field's, else L's class doc comment.
  String? docText;
  if (parentField.documentationComment != null) {
    docText = _slice(parentSource, parentField.documentationComment!);
  } else if (lDecl.documentationComment != null) {
    docText = _slice(lSource, lDecl.documentationComment!);
  }

  // Collect annotation sources, deduped by annotation name (first wins).
  final byName = <String, String>{};
  final order = <String>[];
  void add(Annotation a, String src) {
    final n = _annoName(a);
    if (byName.containsKey(n)) return;
    byName[n] = src;
    order.add(n);
  }

  // 1. @SectionId from L class (identity of the collapsed section).
  for (final a in lDecl.metadata) {
    if (_annoName(a) == 'SectionId') add(a, _slice(lSource, a));
  }
  // 2. L class annotations (schema/help/traceability), excluding SectionId and
  //    SectionIdPattern (pattern is list-only and never present here).
  for (final a in lDecl.metadata) {
    final n = _annoName(a);
    if (n == 'SectionId' || n == 'SectionIdPattern') continue;
    add(a, _slice(lSource, a));
  }
  // 3. L content-field annotations, excluding SerializationOrder (parent wins).
  for (final a in contentField.metadata) {
    final n = _annoName(a);
    if (n == 'SerializationOrder') continue;
    add(a, _slice(lSource, a));
  }
  // 4. Parent-field annotations, excluding SerializationOrder (added last).
  for (final a in parentField.metadata) {
    final n = _annoName(a);
    if (n == 'SerializationOrder') continue;
    add(a, _slice(parentSource, a));
  }
  // 5. Parent field's @SerializationOrder, last (sibling ordering authority).
  Annotation? parentOrder;
  for (final a in parentField.metadata) {
    if (_annoName(a) == 'SerializationOrder') parentOrder = a;
  }

  // Emit with the model's indentation (2 spaces for standard members).
  final b = StringBuffer();
  const ind = '  ';
  if (docText != null) {
    for (final line in docText.split('\n')) {
      b.writeln('$ind$line');
    }
  }
  for (final n in order) {
    // Multi-line annotation source (e.g. @Form / @StandardReferences) is
    // re-indented so continuation lines sit under the leading two spaces.
    b.writeln(_reindent(byName[n]!, ind));
  }
  if (parentOrder != null) {
    b.writeln('$ind${parentOrder.toSource()}');
  }
  b.write('${ind}String? $fieldName;');
  return b.toString();
}

/// Re-indents a (possibly multi-line) annotation source so its first line gets
/// [indent] and continuation lines keep their relative offset under it.
String _reindent(String src, String indent) {
  final lines = src.split('\n');
  if (lines.length == 1) return '$indent$src';
  final out = StringBuffer('$indent${lines.first}');
  for (var i = 1; i < lines.length; i++) {
    out.write('\n$indent${lines[i]}');
  }
  return out.toString();
}

String _slice(String source, AstNode node) =>
    source.substring(node.offset, node.end);
