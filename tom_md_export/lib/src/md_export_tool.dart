/// The `md_export` tool on `tom_build_base`: one command, a Markdown file in,
/// a PDF or an HTML page out.
library;

import 'dart:io';

import 'package:tom_build_base/tom_build_base_v2.dart';

import 'export.dart';
import 'html_export.dart';
import 'typst_runner.dart';
import 'version.versioner.dart';

/// The options of `md_export`.
const mdExportOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'output',
    abbr: 'o',
    description:
        'The file to write (default: the input with .pdf or .html); an .html '
        'output selects the HTML export',
    valueName: 'file',
  ),
  OptionDefinition.option(
    name: 'format',
    description: 'pdf (through Typst) or html (the MD Browser renderer)',
    allowedValues: ['pdf', 'html'],
    valueName: 'format',
  ),
  OptionDefinition.option(
    name: 'kind-css',
    description:
        'A CSS file in place of the built-in kinds stylesheet of the HTML export',
    valueName: 'file',
  ),
  OptionDefinition.option(
    name: 'node',
    description: 'The node binary for the HTML export (default: node on PATH)',
    valueName: 'path',
  ),
  OptionDefinition.option(
    name: 'md-browser',
    description:
        'The tom_vscode_extension checkout whose MD Browser renders the HTML '
        '(default: \$TOM_VSCODE_EXTENSION, else found in the workspace)',
    valueName: 'dir',
  ),
  OptionDefinition.option(
    name: 'kind-styles',
    description:
        'A Typst file defining tm-block, tm-span and tm-cite, in place of the '
        'built-in kind styles',
    valueName: 'file',
  ),
  OptionDefinition.flag(
    name: 'no-kind-styles',
    description:
        'Read the reading notation as text: fences, spans and citations are '
        'written as they stand',
    negatable: false,
  ),
  OptionDefinition.flag(
    name: 'no-outline',
    description:
        'Leave out the outline (three heading levels) the PDF opens with',
    negatable: false,
  ),
  OptionDefinition.option(
    name: 'typst',
    description:
        'The typst binary (default: the binaries layer, then typst on PATH)',
    valueName: 'path',
  ),
  OptionDefinition.flag(
    name: 'typ-only',
    description: 'Write the Typst source (<output>.typ) and compile nothing',
    negatable: false,
  ),
  OptionDefinition.flag(
    name: 'keep-typ',
    description: 'Keep the Typst source beside the PDF',
    negatable: false,
  ),
];

const _help = r'''
md_export reads Markdown carrying the reading notation (DocSpecs Reading
Notation: fenced divs, bracketed spans, citation shapes) and writes a PDF
through Typst, or an HTML page through the MD Browser's renderer. In TomSpecs
its input is a readable rendition (`tomspecs :spec-readable`); it never strips
anything itself.

Typst (Apache-2.0) is one binary: md_export takes it from the binaries layer
($TOM_BINARY_PATH/<platform>/typst), else from PATH, else --typst. The HTML
export runs marked and the MD Browser's blocks.js from the tom_vscode_extension
checkout in Node.

Exit codes: 0 written; 1 Typst, Node or the MD Browser failed or was not found;
2 usage error.''';

/// The `md_export` tool.
final mdExportTool = ToolDefinition(
  name: 'md_export',
  description:
      'Markdown with the reading notation to PDF through Typst, or to HTML',
  version: TomMdExportVersionInfo.version,
  versionString: 'md_export ${TomMdExportVersionInfo.versionMedium}',
  mode: ToolMode.singleCommand,
  features: const NavigationFeatures(
    projectTraversal: false,
    gitTraversal: false,
    recursiveScan: false,
    interactiveMode: false,
    dryRun: false,
    jsonOutput: false,
    verbose: false,
  ),
  globalOptions: mdExportOptions,
  usageErrorExitCode: 2,
  helpFooter: _help,
);

/// Runs one export with the options of [mdExportTool].
class MdExportExecutor extends CommandExecutor {
  /// The executor; reports go to [out] and [err] (stdout and stderr by
  /// default).
  MdExportExecutor({this.out, this.err});

  /// Where the result line goes.
  final StringSink? out;

  /// Where errors go.
  final StringSink? err;

  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async =>
      ItemResult.failure(
        path: context.path,
        name: context.name,
        error: 'md_export visits no projects',
      );

  ToolResult _failure(String message, int code) {
    (err ?? stderr).writeln('md_export: $message');
    return ToolResult(
      success: false,
      errorMessage: message,
      itemResults: [
        ItemResult.failure(
          path: '.',
          name: 'md_export',
          error: message,
          exitCode: code,
        ),
      ],
    );
  }

  @override
  Future<ToolResult> executeWithoutTraversal(CliArgs args) async {
    final o = args.optionsFor('md_export');
    final positional = args.positionalArgs;
    if (positional.length != 1) {
      return _failure('name one Markdown file to export', 2);
    }
    final input = positional.single;
    if (!File(input).existsSync()) return _failure('no file $input', 2);
    final styles = o['kind-styles'] as String?;
    final noStyles = o['no-kind-styles'] == true;
    if (styles != null && noStyles) {
      return _failure(
        '--kind-styles and --no-kind-styles exclude each other',
        2,
      );
    }
    if (styles != null && !File(styles).existsSync()) {
      return _failure('no kind styles file $styles', 2);
    }
    final css = o['kind-css'] as String?;
    if (css != null && !File(css).existsSync()) {
      return _failure('no kind CSS file $css', 2);
    }
    final output = o['output'] as String?;
    final format =
        o['format'] as String? ??
        (output != null && output.toLowerCase().endsWith('.html')
            ? 'html'
            : 'pdf');
    final options = ExportOptions(
      kindStylesFile: styles,
      kindCssFile: css,
      notation: !noStyles,
      outline: o['no-outline'] != true,
    );
    if (format == 'html') {
      final HtmlExporter exporter;
      try {
        exporter = await HtmlExporter.find(
          node: o['node'] as String?,
          extension: o['md-browser'] as String?,
        );
      } on HtmlExportUnavailable catch (e) {
        return _failure(e.message, 1);
      }
      final r = await exportMarkdownFileToHtml(
        input,
        output: output,
        options: options,
        exporter: exporter,
      );
      if (r.exitCode != 0) {
        return _failure(
          'the HTML export failed (${r.exitCode})\n${r.errors}',
          1,
        );
      }
      (out ?? stdout).writeln('html  ${r.output}');
      return const ToolResult.success();
    }
    final typOnly = o['typ-only'] == true;
    TypstCompiler? compiler;
    if (!typOnly) {
      try {
        compiler = await TypstCompiler.find(explicit: o['typst'] as String?);
      } on TypstNotFound catch (e) {
        return _failure(e.message, 1);
      }
    }
    final result = await exportMarkdownFile(
      input,
      output: output,
      options: options,
      compiler: compiler,
      keepTypst: o['keep-typ'] == true,
      typstOnly: typOnly,
    );
    if (!result.ok) {
      return _failure(
        'typst failed (${result.exitCode}); the source is kept at '
        '${result.typstFile}\n${result.errors}',
        1,
      );
    }
    (out ?? stdout).writeln(
      typOnly ? 'typst source  ${result.typstFile}' : 'pdf  ${result.pdfFile}',
    );
    return const ToolResult.success();
  }
}

/// Runs `md_export` with [arguments]; returns the exit code.
Future<int> runMdExport(
  List<String> arguments, {
  StringSink? out,
  StringSink? err,
}) async {
  final runner = ToolRunner(
    tool: mdExportTool,
    executors: {'default': MdExportExecutor(out: out, err: err)},
    output: out ?? ConsoleMarkdownSink(stdout),
    errorOutput: err ?? stderr,
  );
  final result = await runner.run(arguments);
  return result.exitCode;
}
