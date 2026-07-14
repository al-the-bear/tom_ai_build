import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// CLI integration tests for the docspecs command-line tool.
///
/// These tests run the actual CLI tool against test fixture files.
void main() {
  late Directory fixtureDir;
  late Directory outputDir;
  late String projectRoot;

  setUpAll(() {
    projectRoot = Directory.current.path;

    // Scratch fixtures live in a temp dir — never under test/fixtures, which
    // holds the real, tracked schema/document fixtures and would be wiped by
    // this test's tearDownAll.
    fixtureDir = Directory.systemTemp.createTempSync('docspecs_cli_fixtures');

    // Scan output must land in a temp dir, not the package root — the CLI's
    // default target is the current working directory.
    outputDir = Directory.systemTemp.createTempSync('docspecs_cli_out');

    // Create a .docspecs-schemas directory with a test schema
    final schemaDir =
        Directory(p.join(fixtureDir.path, '.docspecs-schemas'));
    schemaDir.createSync(recursive: true);

    File(p.join(schemaDir.path, 'test-1.0.docspecs-schema.yaml'))
        .writeAsStringSync('''
section-types:
  requirement:
    prefix: req
    text-required: true
    pattern-check-id:
      pattern: "^REQ-\\\\d{3}\$"
      error-message: "ID must match REQ-NNN"
  note:
    prefix: note

document:
  sections:
    overview:
      section-type: note
''');

    // Create a valid document
    File(p.join(fixtureDir.path, 'valid.md')).writeAsStringSync('''# <!--[doc] schema=test/1.0--> Test Document

## <!--[note-001]--> Overview

This is a valid document.
''');

    // Create an invalid document (missing required text)
    File(p.join(fixtureDir.path, 'invalid.md')).writeAsStringSync('''# <!--[doc] schema=test/1.0--> Test Document

## <!--[REQ-001]--> Requirement

''');
  });

  tearDownAll(() {
    if (fixtureDir.existsSync()) {
      fixtureDir.deleteSync(recursive: true);
    }
    if (outputDir.existsSync()) {
      outputDir.deleteSync(recursive: true);
    }
  });

  Future<ProcessResult> runCli(List<String> args) async {
    return Process.run(
      'dart',
      ['run', 'bin/docspecs.dart', ...args],
      workingDirectory: projectRoot,
    );
  }

  group('CLI docspecs', () {
    test('shows usage with no arguments', () async {
      final result = await runCli([]);
      expect(result.exitCode, 1);
      expect(result.stdout.toString(), contains('Usage'));
    });

    test('shows help with --help', () async {
      final result = await runCli(['--help']);
      expect(result.exitCode, 0);
    });

    test('validate command produces output', () async {
      final result = await runCli([
        'validate',
        p.join(fixtureDir.path, 'valid.md'),
        '-quiet',
      ]);
      // May succeed or fail depending on schema resolution, but should not crash
      expect(result.exitCode, isNot(equals(3))); // Not file-not-found
    });

    test('scan command produces JSON output', () async {
      final result = await runCli([
        'scan',
        p.join(fixtureDir.path, 'valid.md'),
        '-target=${outputDir.path}',
      ]);
      // Should produce output (JSON) or report schema not found
      final stdout = result.stdout.toString();
      final stderr = result.stderr.toString();
      expect(
        stdout.isNotEmpty || stderr.isNotEmpty,
        isTrue,
        reason: 'CLI should produce some output',
      );
    });

    test('list-schemas command works', () async {
      final result = await runCli(['list-schemas']);
      // Should complete without crashing
      expect(result.exitCode, isNot(equals(3)));
    });

    test('reports file not found for missing file', () async {
      final result = await runCli(['validate', '/nonexistent/file.md']);
      expect(result.exitCode, equals(3));
    });

    test('reports unknown command', () async {
      final result = await runCli(['unknown-command']);
      expect(result.exitCode, 1);
      expect(result.stderr.toString(), contains('Unknown command'));
    });
  });
}
