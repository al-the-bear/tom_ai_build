/// `md_export` — Markdown with the reading notation to PDF through Typst.
///
/// ```text
/// dart run tom_md_export:md_export <in.md> [-o <out.pdf>] [--kind-styles=<file>]
///     [--no-kind-styles] [--no-outline] [--typst <path>] [--typ-only] [--keep-typ]
/// ```
library;

import 'dart:io';

import 'package:tom_md_export/tom_md_export.dart';

Future<void> main(List<String> arguments) async {
  final code = await runMdExport(arguments);
  await stdout.flush();
  await stderr.flush();
  exit(code);
}
