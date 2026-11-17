/// The linked formatter (`lib/src/dart_format.dart`): each file's language
/// version found as `dart format` finds it, and output equal to the SDK's
/// `dart format` for the same input at the same place. The SDK is used here
/// only as the reference the pin promises; no clitool code runs it.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

/// `dart format --output=show` of [source] as if it were the file at [path]
/// (`--stdin-name`, so the SDK finds the same package config), or null when
/// no `dart` is on the PATH.
Future<String?> _formatViaSdk(String source, String path) async {
  try {
    final process = await Process.start('dart', [
      'format',
      '--output=show',
      '--summary=none',
      '--stdin-name',
      path,
    ], runInShell: Platform.isWindows);
    process.stdin.write(source);
    await process.stdin.close();
    final out = await process.stdout.transform(utf8.decoder).join();
    await process.stderr.drain<void>();
    final code = await process.exitCode;
    if (code != 0 && code != 1) return null;
    return out;
  } on ProcessException {
    return null;
  }
}

void main() {
  group('DF1: the language version, as dart format finds it', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('dart_format_lv_'));
    tearDown(() => tmp.deleteSync(recursive: true));

    void write(String rel, String text) => File(p.join(tmp.path, rel))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);

    test('the package config gives the package that holds the file', () {
      write('app/pubspec.yaml', 'name: app\nenvironment:\n  sdk: ^3.9.0\n');
      write(
        'app/.dart_tool/package_config.json',
        jsonEncode({
          'configVersion': 2,
          'packages': [
            {'name': 'app', 'rootUri': '../', 'languageVersion': '3.4'},
            {
              'name': 'inner',
              'rootUri': '../packages/inner/',
              'languageVersion': '3.6',
            },
          ],
        }),
      );
      final format = DartFormat();
      // The config wins over the pubspec, and the deepest root wins.
      expect(
        format.languageVersionOf(p.join(tmp.path, 'app', 'lib', 'a.dart')),
        Version(3, 4, 0),
      );
      expect(
        format.languageVersionOf(
          p.join(tmp.path, 'app', 'packages', 'inner', 'lib', 'b.dart'),
        ),
        Version(3, 6, 0),
      );
    });

    test('without a config, the nearest pubspec; without one, the latest', () {
      write(
        'gen/pubspec.yaml',
        'name: gen\nenvironment:\n  sdk: ">=3.8.0 <4.0.0"\n',
      );
      final format = DartFormat();
      expect(
        format.languageVersionOf(p.join(tmp.path, 'gen', 'lib', 'x.dart')),
        Version(3, 8, 0),
      );
      expect(
        format.languageVersionOf(p.join(tmp.path, 'loose', 'y.dart')),
        DartFormatter.latestLanguageVersion,
      );
    });

    test('a file the config gives no package is in the latest version', () {
      write(
        'ws/.dart_tool/package_config.json',
        jsonEncode({'configVersion': 2, 'packages': <Object>[]}),
      );
      write('ws/tool/pubspec.yaml', 'name: t\nenvironment:\n  sdk: ^3.2.0\n');
      expect(
        DartFormat().languageVersionOf(
          p.join(tmp.path, 'ws', 'tool', 'z.dart'),
        ),
        DartFormatter.latestLanguageVersion,
      );
    });
  });

  test('DF2: a source that does not parse is a DartFormatFailure', () {
    expect(
      () => DartFormat().format('class {', path: 'broken.dart'),
      throwsA(
        isA<DartFormatFailure>().having((f) => f.path, 'path', 'broken.dart'),
      ),
    );
  });

  test('DF3: the same output as the SDK\'s dart format, for real files of '
      'the governed set made unformatted', () async {
    final files = [
      'lib/src/dart_format.dart',
      'lib/src/format_check.dart',
      'bin/tomspecs.dart',
      '../tom_specs_model/lib/src/generated/spec_ops.g.dart',
      '../tom_som_dart_runtime/lib/src/spec_codespecs_extract.dart',
    ];
    final format = DartFormat();
    var compared = 0;
    for (final rel in files) {
      final path = p.normalize(p.absolute(rel));
      if (!File(path).existsSync()) continue;
      final text = File(path).readAsStringSync();
      // Unformatted: every line's indentation dropped and blank lines removed.
      final mangled = [
        for (final l in const LineSplitter().convert(text))
          if (l.trim().isNotEmpty) l.trimLeft(),
      ].join('\n');
      final sdk = await _formatViaSdk(mangled, path);
      if (sdk == null) {
        markTestSkipped('no `dart` on the PATH to compare with');
        return;
      }
      expect(format.format(mangled, path: path), sdk, reason: rel);
      // And the committed file is what both write.
      expect(format.format(text, path: path), text, reason: rel);
      compared++;
    }
    expect(compared, greaterThan(0));
  });
}
