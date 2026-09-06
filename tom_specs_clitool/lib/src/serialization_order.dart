/// Serialization-order enforcement for the spec-model (SOM §5.2).
///
/// The on-disk emission order for **every** SOM language is driven by the
/// per-class `@SerializationOrder(n)` stamps in `tom_specs_model`. This module
/// owns the two operations that keep those stamps correct:
///
/// * [stampSerializationOrder] — a pure source rewrite that numbers every
///   non-static instance member of every spec-model class by source-declaration
///   order (0-based, per class). It is idempotent/re-runnable (it strips any old
///   ordinal before writing the fresh one). This is the same logic the
///   `bin/stamp_serialization_order.dart` CLI exposes, extracted here so the SOM
///   language generator can invoke it as its mandatory **first step**.
/// * [findUnstampedModelMembers] / [unstampedMembers] — the **guard**: after a
///   restamp, verify that every member the model reflects into the wire format
///   carries a current `@SerializationOrder`. Any un-stamped member is a hard
///   error the generator refuses to run past — a safety net against the stamper
///   silently missing a construct it does not visit.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:path/path.dart' as p;

import 'analyzer_bootstrap.dart';
import 'model_reader.dart';

/// Whether [filePath] is engine/generated infrastructure rather than document
/// model: it lives in one of [ModelReader.excludedSrcDirs] directly under
/// [srcDirPath], or is a `*.versioner.dart` build-version artifact.
///
/// The exclusion list is [ModelReader]'s, not a copy of it: the stamper, the
/// reader and the freshness gate must agree on exactly which files make up the
/// spec-model, and three independently-maintained lists would eventually not.
bool _isExcluded(String srcDirPath, String filePath) {
  if (filePath.endsWith('.versioner.dart')) return true;
  final rel = p.relative(filePath, from: srcDirPath);
  return ModelReader.excludedSrcDirs.contains(p.split(rel).first);
}

/// The spec-model `.dart` source files under `[packagePath]/lib/src`, in a
/// stable (path-sorted) order — the same set [ModelReader] reflects.
List<File> collectModelSourceFiles(String packagePath) {
  final srcDir = Directory(p.join(packagePath, 'lib', 'src'));
  if (!srcDir.existsSync()) {
    throw StateError('lib/src not found at ${srcDir.path}');
  }
  return srcDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !_isExcluded(srcDir.path, f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

/// Outcome of a [stampSerializationOrder] run.
class SerializationStampResult {
  const SerializationStampResult({
    required this.filesChanged,
    required this.membersStamped,
    required this.membersRestamped,
    required this.multiVarWarnings,
  });

  /// How many source files the run rewrote (0 on a fully-stamped, unchanged
  /// model — the idempotent case).
  final int filesChanged;

  /// How many member annotations were (re)written in total.
  final int membersStamped;

  /// How many pre-existing `@SerializationOrder` annotations were stripped and
  /// replaced (the renumber count).
  final int membersRestamped;

  /// One entry per multi-variable field declaration (`int a, b;`), which shares
  /// a single ordinal. Advisory, not an error.
  final List<String> multiVarWarnings;
}

/// Stamps `@SerializationOrder(n)` above every non-static instance member of
/// every class under `[packagePath]/lib/src`, numbered by source-declaration
/// order (0-based, per class).
///
/// A pure source rewrite: each file is parsed syntactically (no resolution),
/// any existing `@SerializationOrder` on a member is stripped, and the fresh
/// ordinal is inserted immediately before the variable declaration (after any
/// other annotations / doc comment), indented to match the field. The
/// `tom_specs_core` import is added to any file that gains an annotation but did
/// not already import it. Re-runnable: a second run renumbers cleanly.
///
/// When [dryRun] is true, no files are written but the counts still report what
/// would change.
SerializationStampResult stampSerializationOrder({
  required String packagePath,
  bool dryRun = false,
}) {
  final files = collectModelSourceFiles(packagePath);

  var filesChanged = 0;
  var membersStamped = 0;
  var membersRestamped = 0;
  final multiVarWarnings = <String>[];

  for (final file in files) {
    final source = file.readAsStringSync();
    final unit = parseString(content: source, path: file.path).unit;

    // Collect edits as (start, end, replacement); end==start is a pure insert.
    final edits = <_Edit>[];
    // Per-class running ordinal, keyed by the enclosing class node. The visitor
    // walks FieldDeclarations in source order — exactly the order the ordinal
    // must follow.
    final ordinals = <ClassDeclaration, int>{};

    unit.accept(_FieldVisitor((member) {
      // Only instance members of *classes* are stamped (enum/mixin/extension
      // fields are out of scope for the spec-model).
      final cls = member.thisOrAncestorOfType<ClassDeclaration>();
      if (cls == null) return;
      if (member.isStatic) return;

      final ordinal = ordinals[cls] = (ordinals[cls] ?? -1) + 1;

      final vars = member.fields.variables;
      if (vars.length > 1) {
        multiVarWarnings.add('${p.relative(file.path, from: packagePath)}: '
            '${cls.namePart.typeName.lexeme}.'
            '${vars.map((v) => v.name.lexeme).join(',')} '
            '(multi-variable declaration — single shared ordinal $ordinal)');
      }

      // Strip any pre-existing @SerializationOrder annotation on this member.
      for (final ann in member.metadata) {
        if (ann.name.name == 'SerializationOrder') {
          final endOffset = ann.endToken.next?.offset ?? ann.end;
          edits.add(_Edit(ann.offset, endOffset, ''));
          membersRestamped++;
        }
      }

      // Insert before the variable declaration's first token (the type /
      // final / var keyword), i.e. after any other annotations & doc comment.
      final insertAt = member.fields.beginToken.offset;
      final indent = _lineIndent(source, insertAt);
      edits.add(
          _Edit(insertAt, insertAt, '@SerializationOrder($ordinal)\n$indent'));
      membersStamped++;
    }));

    if (edits.isEmpty) continue;

    // Ensure the file imports the annotation's home (the tom_specs_core barrel).
    // Most model files already do (they use @SectionId etc.); a bare container
    // root may not, so add it after the last import (or library directive /
    // file start) when missing.
    const coreImport = "import 'package:tom_specs_core/tom_specs_core.dart';";
    if (!source.contains(coreImport)) {
      final imports = unit.directives.whereType<ImportDirective>().toList();
      final int anchorEnd;
      final String insertText;
      if (imports.isNotEmpty) {
        anchorEnd = imports.last.end;
        insertText = '\n$coreImport';
      } else {
        final libs = unit.directives.whereType<LibraryDirective>().toList();
        anchorEnd = libs.isNotEmpty ? libs.first.end : 0;
        insertText = libs.isNotEmpty ? '\n\n$coreImport' : '$coreImport\n';
      }
      edits.add(_Edit(anchorEnd, anchorEnd, insertText));
    }

    // Apply highest-offset-first so earlier offsets stay valid.
    edits.sort((a, b) => b.start.compareTo(a.start));
    var out = source;
    for (final e in edits) {
      out = out.substring(0, e.start) + e.replacement + out.substring(e.end);
    }

    // Compare before counting. Stamping is remove-and-rewrite, so a file whose
    // stamps are already correct still produces a full edit list — counting the
    // edit list would report every stamped file as changed on every run, which
    // is exactly what [filesChanged]'s contract says it does not do. Not writing
    // an identical file also keeps mtimes still, so a re-stamp does not look
    // like a model edit to anything watching the tree.
    if (out == source) continue;
    filesChanged++;
    if (!dryRun) file.writeAsStringSync(out);
  }

  return SerializationStampResult(
    filesChanged: filesChanged,
    membersStamped: membersStamped,
    membersRestamped: membersRestamped,
    multiVarWarnings: multiVarWarnings,
  );
}

/// The `Class.member` identifiers for every reflected field that lacks a
/// current `@SerializationOrder` — empty when the model is fully stamped.
///
/// Pure over an already-read model, so it is trivially testable and is the
/// unit both the CLI verifier and the generator's error guard build on. It
/// inspects the **reflected** fields (exactly what reaches the wire format via
/// [ModelJsonExporter]), so it catches any member the AST-based stamper failed
/// to reach.
List<String> unstampedMembers(Map<String, ModelClass> classes) {
  final offenders = <String>[];
  final names = classes.keys.toList()..sort();
  for (final name in names) {
    for (final field in classes[name]!.fields) {
      if (field.serializationOrder == null) {
        offenders.add('$name.${field.name}');
      }
    }
  }
  return offenders;
}

/// Reads the spec-model at [modelPackagePath] and returns [unstampedMembers]
/// over it — the resolved-model verifier the generator runs after restamping.
Future<List<String>> findUnstampedModelMembers(String modelPackagePath) async {
  final driver = createAnalysisDriver(modelPackagePath);
  final reader = ModelReader(driver);
  await reader.analyzePackage(p.join(modelPackagePath, 'lib'));
  return unstampedMembers(reader.classes);
}

/// The leading-whitespace indentation of the line containing [offset].
String _lineIndent(String source, int offset) {
  final lineStart = source.lastIndexOf('\n', offset - 1) + 1;
  var i = lineStart;
  while (i < source.length && (source[i] == ' ' || source[i] == '\t')) {
    i++;
  }
  return source.substring(lineStart, i);
}

class _Edit {
  _Edit(this.start, this.end, this.replacement);
  final int start;
  final int end;
  final String replacement;
}

/// Visits every [FieldDeclaration] in source order, invoking [onField].
class _FieldVisitor extends RecursiveAstVisitor<void> {
  _FieldVisitor(this.onField);
  final void Function(FieldDeclaration) onField;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    onField(node);
    super.visitFieldDeclaration(node);
  }
}
