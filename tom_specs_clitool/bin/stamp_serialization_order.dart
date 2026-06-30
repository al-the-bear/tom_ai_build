import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// One-shot tool (SD-2) that stamps `@SerializationOrder(n)` above **every
/// instance member of every spec-model class**, numbered by source declaration
/// order (0-based, per class).
///
/// It is a pure source rewrite: each `.dart` file under the package's `lib/src`
/// (excluding the snapshot/serialization/generated engine dirs and
/// `*.versioner.dart` build artifacts — the same set [ModelReader] reflects) is
/// parsed, and for every `FieldDeclaration` that is not static the annotation is
/// inserted immediately before the variable declaration (after any existing
/// annotations / doc comment), indented to match the field.
///
/// Re-runnable: any pre-existing `@SerializationOrder(...)` on a member is
/// removed before the fresh ordinal is inserted, so a second run renumbers
/// cleanly after the model is edited.
///
/// Usage:
///   `dart run bin/stamp_serialization_order.dart --package <model-path> [--dry-run]`
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('package',
        abbr: 'p',
        help: 'Path to the target Dart package (its lib/src is rewritten).',
        mandatory: true)
    ..addFlag('dry-run',
        help: 'Report what would change without writing files.',
        negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stdout.writeln(parser.usage);
    exit(2);
  }
  if (results.flag('help')) {
    stdout.writeln('Usage: dart run bin/stamp_serialization_order.dart '
        '--package <path> [--dry-run]');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final packagePath = p.normalize(p.absolute(results.option('package')!));
  final dryRun = results.flag('dry-run');
  final srcDir = Directory(p.join(packagePath, 'lib', 'src'));
  if (!srcDir.existsSync()) {
    stderr.writeln('Error: lib/src not found at ${srcDir.path}');
    exit(1);
  }

  // Same exclusions ModelReader applies (analyzer_bootstrap / model_reader):
  // engine infra dirs directly under lib/src, plus *.versioner.dart artifacts.
  const excludedDirs = {'snapshot', 'serialization', 'generated'};
  bool isExcluded(String filePath) {
    if (filePath.endsWith('.versioner.dart')) return true;
    final rel = p.relative(filePath, from: srcDir.path);
    return excludedDirs.contains(p.split(rel).first);
  }

  final files = srcDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !isExcluded(f.path))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  var filesChanged = 0;
  var membersStamped = 0;
  var membersRestamped = 0;
  final multiVarWarnings = <String>[];

  for (final file in files) {
    final source = file.readAsStringSync();
    final unit = parseString(content: source, path: file.path).unit;

    // Collect edits as (start, end, replacement); end==start is a pure insert.
    final edits = <_Edit>[];
    // Per-class running ordinal, keyed by the enclosing class node. A visitor
    // walks FieldDeclarations in source order, which is exactly the order the
    // ordinal must follow.
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
        multiVarWarnings.add(
            '${p.relative(file.path, from: packagePath)}: '
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
      edits.add(_Edit(
          insertAt, insertAt, '@SerializationOrder($ordinal)\n$indent'));
      membersStamped++;
    }));

    if (edits.isEmpty) continue;

    // Ensure the file imports the annotation's home (the tom_specs_core barrel).
    // Most model files already do (they use @SectionId etc.); the unannotated
    // container root does not, so add it after the last import (or the library
    // directive / file start) when missing.
    const coreImport =
        "import 'package:tom_specs_core/tom_specs_core.dart';";
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

    filesChanged++;
    if (!dryRun) file.writeAsStringSync(out);
  }

  stdout.writeln('stamp_serialization_order: '
      '${dryRun ? '[dry-run] ' : ''}'
      'files changed: $filesChanged, members stamped: $membersStamped'
      '${membersRestamped > 0 ? ', restamped (removed old): $membersRestamped' : ''}');
  if (multiVarWarnings.isNotEmpty) {
    stderr.writeln('WARNING: ${multiVarWarnings.length} multi-variable field '
        'declaration(s) share one ordinal:');
    for (final w in multiVarWarnings) {
      stderr.writeln('  - $w');
    }
  }
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
  final int start;
  final int end;
  final String replacement;
  _Edit(this.start, this.end, this.replacement);
}

/// Visits every [FieldDeclaration] in source order, invoking [onField].
class _FieldVisitor extends RecursiveAstVisitor<void> {
  final void Function(FieldDeclaration) onField;
  _FieldVisitor(this.onField);

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    onField(node);
    super.visitFieldDeclaration(node);
  }
}
