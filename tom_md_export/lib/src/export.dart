/// Markdown with the reading notation to Typst, and to PDF.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'html_export.dart';
import 'kind_styles.dart';
import 'md_reader.dart';
import 'typst_emitter.dart';
import 'typst_runner.dart';

/// How a document is exported.
class ExportOptions {
  /// Options; see the fields.
  const ExportOptions({
    this.kindStylesFile,
    this.kindCssFile,
    this.notation = true,
    this.outline = true,
    this.documentNames = const {},
  });

  /// A Typst file replacing the built-in kind styles (`--kind-styles`).
  final String? kindStylesFile;

  /// A CSS file replacing the built-in kinds stylesheet of the HTML export
  /// (`--kind-css`).
  final String? kindCssFile;

  /// False reads the notation as text (`--no-kind-styles`).
  final bool notation;

  /// Whether the PDF opens with an outline.
  final bool outline;

  /// The names under which the document links to itself (see
  /// [TypstOptions.documentNames]); the input's own name is added.
  final Set<String> documentNames;
}

/// The names under which [markdown] links to itself: [extra], its own file
/// [name], and — for a readable rendition, which names its document of
/// record in its header (`<!-- readable: …; of=<doc>.tomspecs.yaml; … -->`) —
/// that document's `.tomspecs.md` and `.readable.md` renditions.
Set<String> documentNamesOf(
  String markdown, {
  String? name,
  Set<String> extra = const {},
}) {
  final names = {...extra, ?name};
  final of = RegExp(
    r'<!-- readable:[^>]*\bof=([^;@ >]+)',
  ).firstMatch(markdown)?.group(1);
  if (of != null) {
    final stem = of.replaceFirst(RegExp(r'\.tomspecs\.(yaml|md)$'), '');
    names
      ..add('$stem.tomspecs.md')
      ..add('$stem.readable.md');
  }
  return names;
}

/// The Typst source for [markdown]; [name] is the input's file name, which
/// links within the document may use.
String markdownToTypst(
  String markdown, {
  ExportOptions options = const ExportOptions(),
  String? name,
}) {
  final styles = options.kindStylesFile == null
      ? builtInKindStyles
      : File(options.kindStylesFile!).readAsStringSync();
  final names = documentNamesOf(
    markdown,
    name: name,
    extra: options.documentNames,
  );
  final blocks = MarkdownReader(notation: options.notation).parse(markdown);
  return TypstEmitter(
    TypstOptions(
      kindStyles: options.notation ? styles : noKindStyles,
      notation: options.notation,
      outline: options.outline,
      documentNames: names,
    ),
  ).emit(blocks);
}

/// The result of an export.
class ExportResult {
  /// An export that wrote [typstFile] and, when compiled, [pdfFile].
  const ExportResult({
    required this.typstFile,
    this.pdfFile,
    this.exitCode = 0,
    this.errors = '',
  });

  /// The Typst source written.
  final String typstFile;

  /// The PDF, when Typst compiled it.
  final String? pdfFile;

  /// Typst's exit code (0 when not compiled).
  final int exitCode;

  /// What Typst reported on failure.
  final String errors;

  /// Whether the export succeeded.
  bool get ok => exitCode == 0;
}

/// Exports the Markdown file [input] to the PDF [output] (default: beside the
/// input with `.pdf`): writes the Typst source beside the PDF (`.typ`),
/// compiles it with [compiler], and deletes the source unless [keepTypst].
/// With [typstOnly] it writes the source and compiles nothing.
Future<ExportResult> exportMarkdownFile(
  String input, {
  String? output,
  ExportOptions options = const ExportOptions(),
  TypstCompiler? compiler,
  bool keepTypst = false,
  bool typstOnly = false,
}) async {
  final pdf = output ?? '${p.withoutExtension(input)}.pdf';
  final typ = '${p.withoutExtension(pdf)}.typ';
  final source = markdownToTypst(
    File(input).readAsStringSync(),
    options: options,
    name: p.basename(input),
  );
  File(typ).writeAsStringSync(source);
  if (typstOnly) return ExportResult(typstFile: typ);
  final c = compiler ?? await TypstCompiler.find();
  final r = await c.compile(typ, pdf);
  if (r.exitCode == 0 && !keepTypst) File(typ).deleteSync();
  return ExportResult(
    typstFile: typ,
    pdfFile: r.exitCode == 0 ? pdf : null,
    exitCode: r.exitCode,
    errors: r.errors,
  );
}

/// Exports the Markdown file [input] to the HTML file [output] (default:
/// beside the input with `.html`) with [exporter] — the MD Browser's renderer
/// in Node. The page carries its stylesheet: the base style and the kinds
/// stylesheet (or [ExportOptions.kindCssFile]); with the notation read as
/// text, no kinds stylesheet.
Future<({int exitCode, String errors, String output})> exportMarkdownFileToHtml(
  String input, {
  String? output,
  ExportOptions options = const ExportOptions(),
  required HtmlExporter exporter,
}) async {
  final html = output ?? '${p.withoutExtension(input)}.html';
  final kindCss = !options.notation
      ? ''
      : options.kindCssFile == null
      ? htmlKindCss
      : File(options.kindCssFile!).readAsStringSync();
  final r = await exporter.render(
    input,
    html,
    css: '$htmlBaseCss$kindCss',
    notation: options.notation,
    documentNames: documentNamesOf(
      File(input).readAsStringSync(),
      name: p.basename(input),
      extra: options.documentNames,
    ),
  );
  return (exitCode: r.exitCode, errors: r.errors, output: html);
}
