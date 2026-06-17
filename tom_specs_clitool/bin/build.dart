import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

/// TomSpecs editor build & packaging orchestrator (§17, N8, B1/B2).
///
/// Drives every build step from a single command so a from-scratch build
/// produces a runnable app stamped with the model version:
///
///   1. `buildkit :versioner` in `tom_specs_model` → the **version stamp**
///      (`TomSpecsModelVersionInfo`). This single stamp is the source for both
///      the bundled `spec_model.json` version and the schema version (B2/S2).
///   2. Generate `spec_model.json` (`model_json.dart`), tagged with the stamp.
///   3. Generate DocSpecs schemas (`docspecs_schema.dart`), versioned from the
///      stamp.
///   4. Embed pre-generated `tom_dart_editor` analyzer **summaries** (B1) — the
///      summaries are committed assets; the build copies them in (it never runs
///      the analyzer per-OS).
///   5. Bundle assets (model json, schemas, embedded summaries).
///   6. `flutter build {linux|windows|macos}`.
///
/// `buildkit` drives step 1 (N8); steps 2–6 are dart/flutter script steps the
/// orchestrator runs in dependency order. Cross-platform: `--os` selects the
/// flutter target (defaults to the host OS).
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('os',
        help: 'Flutter build target: linux | windows | macos. '
            'Defaults to the host OS.')
    ..addOption('model',
        help: 'Path to the tom_specs_model package. '
            'Default: sibling of this clitool package.')
    ..addOption('editor',
        help: 'Path to the tom_specs_editor Flutter package. '
            'Default: <container>/tom_forge/tom_specs_editor.')
    ..addOption('summaries',
        help: 'Optional directory of pre-generated Dart-editor summary assets '
            'to embed (B1). Skipped with a notice when absent.')
    ..addFlag('generate-summaries',
        help: 'Generate the B1 analyzer summaries in-place via '
            'bin/summaries.dart (against the editor\'s resolved deps) instead '
            'of copying a pre-generated --summaries directory. This runs the '
            'analyzer once on the build host; the per-OS build still only '
            'copies the resulting committed assets.',
        negatable: false)
    ..addOption('buildkit',
        help: 'buildkit executable (on PATH or absolute). Default: buildkit.',
        defaultsTo: 'buildkit')
    ..addOption('model-version',
        help: 'Override the integer model-version stamp. '
            'Default: major component of the model pubspec version.')
    ..addFlag('no-flutter-build',
        help: 'Run steps 1–5 (versioner, json, schemas, summaries, bundle) but '
            'skip the final `flutter build` — asset generation only.',
        negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show usage information.',
        negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}\n');
    stdout.writeln(parser.usage);
    exit(2);
  }
  if (args.flag('help')) {
    stdout.writeln('Usage: dart run bin/build.dart [options]\n');
    stdout.writeln(parser.usage);
    exit(0);
  }

  final clitoolRoot = _clitoolRoot();
  final aiBuild = p.dirname(clitoolRoot);
  final container = p.dirname(p.dirname(aiBuild));

  final modelDir = p.normalize(
      args.option('model') ?? p.join(aiBuild, 'tom_specs_model'));
  final editorDir = p.normalize(args.option('editor') ??
      p.join(container, 'tom_forge', 'tom_specs_editor'));
  final buildkit = args.option('buildkit')!;
  final os = (args.option('os') ?? Platform.operatingSystem).toLowerCase();
  if (!const {'linux', 'windows', 'macos'}.contains(os)) {
    _fail('Unsupported --os "$os" (expected linux | windows | macos).');
  }
  for (final dir in [modelDir, editorDir]) {
    if (!Directory(dir).existsSync()) _fail('Directory not found: $dir');
  }

  _banner('TomSpecs build (§17) — target $os');
  stdout.writeln('  model:  $modelDir');
  stdout.writeln('  editor: $editorDir');

  // ── Step 1: version stamp via buildkit (N8/B2) ────────────────────────────
  _step(1, 'buildkit :versioner → model version stamp');
  await _run(buildkit, ['--nested', ':versioner'], cwd: modelDir);
  final stamp = _readStamp(modelDir);
  final modelVersion =
      int.tryParse(args.option('model-version') ?? '') ?? stamp.majorVersion;
  if (modelVersion < 1) {
    _fail('Resolved model version $modelVersion is invalid (must be ≥ 1).');
  }
  stdout.writeln('  → model version $modelVersion  (label: ${stamp.label})');

  // ── Step 2: spec_model.json, stamped (B2) ─────────────────────────────────
  _step(2, 'generate spec_model.json (stamped)');
  final modelJsonOut = p.join(editorDir, 'assets', 'spec_model.json');
  await _run(
    'dart',
    [
      'run',
      p.join('bin', 'model_json.dart'),
      '--package', modelDir,
      '--output', modelJsonOut,
      '--model-version', '$modelVersion',
      '--model-label', stamp.label,
    ],
    cwd: clitoolRoot,
  );

  // ── Step 3: DocSpecs schemas, versioned from the stamp (S2) ───────────────
  // Two destinations (§16/§17): the canonical `<id>/<id>.<ver>...` tree under
  // `.tom/docspecs-schema/` (the DocSpecs resolver layout) and a *flat* copy in
  // the asset dir. Flutter bundles a listed asset directory **non-recursively**,
  // so the nested resolver tree would be silently dropped — the flat copy is
  // what actually ships in the app bundle.
  _step(3, 'generate DocSpecs schemas (versioned, → .tom tree + flat assets)');
  final schemaTree = p.join(editorDir, '.tom', 'docspecs-schema');
  await _run(
    'dart',
    [
      'run',
      p.join('bin', 'docspecs_schema.dart'),
      '--package', modelDir,
      '--out-dir', schemaTree,
      '--version', '$modelVersion',
    ],
    cwd: clitoolRoot,
  );
  final schemaOut = Directory(p.join(editorDir, 'assets', 'docspecs-schema'));
  for (final f in schemaOut
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.docspecs-schema.yaml'))) {
    f.deleteSync(); // clear stale flat copies from a prior build
  }
  var flattened = 0;
  for (final e in Directory(schemaTree).listSync(recursive: true)) {
    if (e is File && e.path.endsWith('.docspecs-schema.yaml')) {
      e.copySync(p.join(schemaOut.path, p.basename(e.path)));
      flattened++;
    }
  }
  stdout.writeln('  → flattened $flattened schema(s) into ${schemaOut.path}');

  // ── Step 4: embed pre-generated summaries (B1) ────────────────────────────
  _step(4, 'embed pre-generated Dart-editor summaries');
  final summaries = args.option('summaries');
  final summariesDest = Directory(p.join(editorDir, 'assets', 'summaries'));
  if (args.flag('generate-summaries')) {
    // Generate in-place into the editor's own asset dir. Needs the editor's
    // resolved package_config, so ensure deps are present first.
    if (summaries != null) {
      _fail('--summaries and --generate-summaries are mutually exclusive.');
    }
    summariesDest.createSync(recursive: true);
    await _run('flutter', ['pub', 'get'], cwd: editorDir);
    await _run(
      'dart',
      [
        'run',
        p.join('bin', 'summaries.dart'),
        '--package', editorDir,
        '--out-dir', summariesDest.path,
      ],
      cwd: clitoolRoot,
    );
    stdout.writeln('  → generated summaries into ${summariesDest.path}');
  } else if (summaries == null) {
    stdout.writeln('  (no --summaries / --generate-summaries given; nothing to '
        'embed. Pass --generate-summaries to build them on this host, or '
        '--summaries <dir> to copy pre-generated assets. Code-typed fields '
        'fall back to a plain text field when the .sum assets are absent.)');
  } else if (!Directory(summaries).existsSync()) {
    _fail('--summaries directory not found: $summaries');
  } else {
    if (summariesDest.existsSync()) summariesDest.deleteSync(recursive: true);
    summariesDest.createSync(recursive: true);
    var copied = 0;
    for (final e in Directory(summaries).listSync(recursive: true)) {
      if (e is File) {
        final rel = p.relative(e.path, from: summaries);
        final out = File(p.join(summariesDest.path, rel));
        out.parent.createSync(recursive: true);
        e.copySync(out.path);
        copied++;
      }
    }
    stdout.writeln('  → embedded $copied summary file(s)');
  }

  // ── Step 5: bundle assets (verify they exist before the build) ────────────
  _step(5, 'bundle assets');
  if (!File(modelJsonOut).existsSync()) {
    _fail('Expected $modelJsonOut after step 2.');
  }
  final schemaCount = schemaOut.existsSync()
      ? schemaOut
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.docspecs-schema.yaml'))
          .length
      : 0;
  stdout.writeln('  → spec_model.json + $schemaCount bundled schema file(s) staged');
  await _run('flutter', ['pub', 'get'], cwd: editorDir);

  // ── Step 6: flutter build ─────────────────────────────────────────────────
  if (args.flag('no-flutter-build')) {
    _step(6, 'flutter build — SKIPPED (--no-flutter-build)');
  } else {
    _step(6, 'flutter build $os');
    await _run('flutter', ['build', os], cwd: editorDir);
  }

  _banner('Build complete — model v$modelVersion (${stamp.label}) → $os');
}

/// The resolved root of the `tom_specs_clitool` package (parent of `bin/`).
String _clitoolRoot() {
  final scriptPath = p.fromUri(Platform.script);
  // .../tom_specs_clitool/bin/build.dart → .../tom_specs_clitool
  return p.normalize(p.dirname(p.dirname(scriptPath)));
}

/// The parsed model version stamp from `version.versioner.dart`.
class _Stamp {
  _Stamp(this.version, this.buildNumber, this.gitCommit);
  final String version;
  final int buildNumber;
  final String gitCommit;

  /// The integer model version counter (S2): the major component of [version].
  int get majorVersion =>
      int.tryParse(version.split('.').first.trim()) ?? 1;

  /// A human-readable build label (e.g. `1.0.0+3.abc1234`).
  String get label {
    final commit = gitCommit.isEmpty ? '' : '.$gitCommit';
    return '$version+$buildNumber$commit';
  }
}

/// Parses the generated stamp produced by `buildkit :versioner`.
_Stamp _readStamp(String modelDir) {
  final file = File(p.join(modelDir, 'lib', 'src', 'version.versioner.dart'));
  if (!file.existsSync()) {
    _fail('Version stamp not found at ${file.path} (did step 1 run?).');
  }
  final src = file.readAsStringSync();
  String str(String field) =>
      RegExp("$field\\s*=\\s*'([^']*)'").firstMatch(src)?.group(1) ?? '';
  int num(String field) =>
      int.tryParse(RegExp('$field\\s*=\\s*(\\d+)').firstMatch(src)?.group(1) ??
              '') ??
          0;
  final version = str('version');
  if (version.isEmpty) _fail('Could not parse `version` from ${file.path}.');
  return _Stamp(version, num('buildNumber'), str('gitCommit'));
}

Future<void> _run(String exe, List<String> args, {required String cwd}) async {
  stdout.writeln('  \$ $exe ${args.join(' ')}');
  final proc = await Process.start(exe, args,
      workingDirectory: cwd, mode: ProcessStartMode.inheritStdio);
  final code = await proc.exitCode;
  if (code != 0) _fail('`$exe ${args.join(' ')}` failed (exit $code).');
}

void _banner(String msg) => stdout.writeln('\n══ $msg ══\n');
void _step(int n, String msg) => stdout.writeln('\n── step $n: $msg');
Never _fail(String msg) {
  stderr.writeln('Build error: $msg');
  exit(1);
}
