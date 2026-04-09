import 'dart:io';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

Future<void> main(List<String> args) async {
  final outputPath = args.isNotEmpty ? args.first : 'assets/sdk_summary.sum';

  final sdkPath = Platform.environment['DART_SDK'] ??
      File(Platform.resolvedExecutable).parent.parent.path;

  print('Building SDK summary from $sdkPath ...');

  final bytes = await buildSdkSummary(
    resourceProvider: PhysicalResourceProvider.INSTANCE,
    sdkPath: sdkPath,
  );

  File(outputPath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  print('SDK summary written to $outputPath (${bytes.length} bytes)');
}
