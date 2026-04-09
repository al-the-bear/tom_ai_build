import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

void main(List<String> args) {
  final inputPath = args.isNotEmpty ? args.first : 'assets/sdk_summary.sum';
  final outputDir = args.length > 1 ? args[1] : 'lib/src/sdk_summary';

  final bytes = File(inputPath).readAsBytesSync();
  final base64String = base64Encode(bytes);

  const chunkSize = 60000; // ~60 KB per chunk
  final chunks = <String>[];
  for (var i = 0; i < base64String.length; i += chunkSize) {
    final end = (i + chunkSize).clamp(0, base64String.length);
    chunks.add(base64String.substring(i, end));
  }

  final dir = Directory(outputDir);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
  dir.createSync(recursive: true);

  final imports = StringBuffer();
  final list = StringBuffer();

  for (var i = 0; i < chunks.length; i++) {
    final index = (i + 1).toString().padLeft(3, '0');
    final fileName = 'chunk_$index.dart';
    final constName = 'sdkSummaryChunk$index';

    File(p.join(outputDir, fileName)).writeAsStringSync(
      "const $constName =\n    '${chunks[i]}';\n",
    );

    imports.writeln("import '$fileName';");
    list.writeln('  $constName,');
  }

  File(p.join(outputDir, 'sdk_summary_chunks.dart')).writeAsStringSync(
    '$imports\n'
    'const sdkSummaryChunks = [\n'
    '$list];\n',
  );

  print(
    'Split ${bytes.length} bytes (${base64String.length} base64 chars) '
    'into ${chunks.length} chunks in $outputDir',
  );
}
