/// The dart-tom mapper formats with the `dart_style` linked into this package
/// (so a compiled `irspecs` needs no Dart SDK). The trio is held to the SDK's
/// layout byte for byte, so the linked formatter has to be the SDK's: this
/// test holds the constant, the pubspec pin, the lock and the formatter of the
/// SDK running the tests to one version. When the SDK moves, it fails with the
/// version to move the pin to, instead of the layouts drifting apart.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';
import 'package:yaml/yaml.dart';

void main() {
  final root = Directory.current.path;

  test('the pubspec pins dart_style exactly to kDartStyleVersion', () {
    final pubspec =
        loadYaml(File(p.join(root, 'pubspec.yaml')).readAsStringSync())
            as YamlMap;
    final pin = (pubspec['dependencies'] as YamlMap)['dart_style'];
    expect(
      '$pin',
      kDartStyleVersion,
      reason:
          'dart_style is pinned to one exact version, and kDartStyleVersion '
          '(lib/src/dart_format.dart) names it',
    );
  });

  test('the lock resolves that version', () {
    final lock = File(p.join(root, 'pubspec.lock'));
    if (!lock.existsSync()) {
      markTestSkipped('no pubspec.lock (run `dart pub get`)');
      return;
    }
    final packages =
        (loadYaml(lock.readAsStringSync()) as YamlMap)['packages'] as YamlMap;
    expect(
      '${(packages['dart_style'] as YamlMap)['version']}',
      kDartStyleVersion,
    );
  });

  test('the SDK running the tests formats with the same dart_style', () {
    final dart = Platform.resolvedExecutable;
    final name = p.basenameWithoutExtension(dart).toLowerCase();
    if (name != 'dart') {
      markTestSkipped('not run by the dart VM ($dart): no SDK to compare with');
      return;
    }
    final result = Process.runSync(dart, ['format', '--version']);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    final sdkFormatter = '${result.stdout}'.trim();
    expect(
      sdkFormatter,
      kDartStyleVersion,
      reason:
          'The SDK formats with dart_style $sdkFormatter, the dart-tom mapper '
          'with $kDartStyleVersion. Move the pin: dart_style: $sdkFormatter in '
          'pubspec.yaml and kDartStyleVersion in lib/src/dart_format.dart, then '
          '`dart pub get` and run the dart-tom round trip.',
    );
  });
}
