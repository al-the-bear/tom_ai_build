import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:tom_specs_clitool/tom_specs_clitool.dart';
import 'package:yaml/yaml.dart';

/// TomSpecs editor build & packaging orchestrator
/// (`som_multiplatform_spec_model.md` §17, N8, B1/B2).
///
/// Drives every build step from a single command so a from-scratch build
/// produces a runnable app stamped with the model version:
///
///   1. `buildkit :versioner` in `tom_specs_model` → the **version stamp**
///      (`TomSpecsModelVersionInfo`). This single stamp is the source for both
///      the bundled `spec_model.json` version and the schema version (B2/S2).
///   2. Regenerate `spec_ops.g.dart` (`spec_ops.dart`) — the reflection-free
///      snapshot/serialization registry for every model class (OE-2). It is a
///      committed model source artifact, regenerated here so it tracks the
///      model the rest of the build runs against.
///   3. Generate `spec_model.json` (`model_json.dart`), tagged with the stamp.
///   4. Generate DocSpecs schemas (`docspecs_schema.dart`), versioned from the
///      stamp.
///   5. Provide the `tom_dart_editor` analyzer **summaries** (B1). By default
///      they are pre-generated assets the build copies in (it never runs the
///      analyzer per-OS); with `--generate-summaries` the build produces them
///      on this host by invoking **tom_dart_editor_bundler** against the
///      editor's own `buildkit.yaml`. The bundler is the only generator of this
///      asset set — it also emits the `summary_scopes.g.dart` helper the app
///      reads, so the assets and the paths the app asks for cannot disagree.
///   6. Bundle assets (model json, schemas, embedded summaries).
///   7. `flutter build {linux|windows|macos}`.
///
/// `buildkit` drives step 1 (N8); steps 2–7 are dart/flutter script steps the
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
        help: 'Generate the B1 analyzer summaries in-place by running '
            'tom_dart_editor_bundler against the editor\'s buildkit.yaml '
            '(which declares the scopes and their package closures), instead '
            'of copying a pre-generated --summaries directory. This runs the '
            'analyzer once on the build host; the per-OS build still only '
            'copies the resulting committed assets.',
        negatable: false)
    ..addOption('buildkit',
        help: 'buildkit executable (on PATH or absolute). Default: buildkit.',
        defaultsTo: 'buildkit')
    ..addFlag('no-flutter-build',
        help: 'Run steps 1–6 (versioner, spec-ops, json, schemas, summaries, '
            'bundle) but skip the final `flutter build` — generation only.',
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

  _banner('TomSpecs build (SOM §17) — target $os');
  stdout.writeln('  model:  $modelDir');
  stdout.writeln('  editor: $editorDir');

  // ── Step 1: version stamp via buildkit (N8/B2) ────────────────────────────
  _step(1, 'buildkit :versioner → model version stamp');
  await _run(buildkit, ['--nested', ':versioner'], cwd: modelDir);
  final stamp = _readStamp(modelDir);
  // The stamp is *derived*, never supplied: every artifact this build writes —
  // the editor's spec_model.json, the DocSpecs schemas — takes its version from
  // this one file, so they cannot drift apart and a caller cannot inject a
  // version the model does not actually carry.
  final modelVersion = stamp.majorVersion;
  if (modelVersion < 1) {
    _fail('Resolved model version $modelVersion is invalid (must be ≥ 1).');
  }
  stdout.writeln('  → model version $modelVersion  (label: ${stamp.label})');

  // ── Step 2: regenerate spec_ops.g.dart registry (OE-2) ────────────────────
  // The reflection-free snapshot/serialization ops for every model class. It is
  // a committed source artifact inside the model package; regenerating it here
  // keeps it in lock-step with the model the build compiles and ships.
  //
  // The canonical producer is `bin/generate_som.dart`, which emits it alongside
  // the nine language packages and stamps the model fingerprint that certifies
  // it. This step is the app build's own belt-and-braces: it must not ship an
  // editor whose registry is older than the model it bundles, whatever ran
  // before it. Both go through `generateSpecOpsRegistry`, so there is one
  // emitter and one output path.
  _step(2, 'generate spec_ops.g.dart (snapshot/serialization registry)');
  final specOps = await generateSpecOpsRegistry(modelPackagePath: modelDir);
  stdout.writeln('  → ${specOps.classCount} classes, '
      '${specOps.changed ? 'rewritten' : 'already current'}: '
      '${specOps.outputPath}');

  // ── Step 3: spec_model.json, stamped (B2) ─────────────────────────────────
  // Written through the named `editor` target, which owns both the path and the
  // stamp — the two committed spec_model.json assets carry different frozen
  // stamps, and naming the target is what stops this build from re-exporting
  // one of them at the other's version.
  _step(3, 'generate spec_model.json (stamped)');
  final modelJsonOut = p.join(editorDir, 'assets', 'spec_model.json');
  final targetJsonOut = ModelJsonTarget.editor.outputPathIn(container);
  if (p.normalize(modelJsonOut) != targetJsonOut) {
    _fail('--editor points at $editorDir, whose asset '
        '(${p.normalize(modelJsonOut)}) is not the committed editor asset '
        '($targetJsonOut). The committed asset is refreshed by target, so a '
        'relocated editor cannot be stamped from here.');
  }
  await _run(
    'dart',
    [
      'run',
      p.join('bin', 'model_json.dart'),
      '--target', ModelJsonTarget.editor.id,
      '--package', modelDir,
    ],
    cwd: clitoolRoot,
  );

  // ── Step 4: DocSpecs schemas, versioned from the stamp (S2) ───────────────
  // Two destinations: the canonical `<id>/<id>.<ver>...` tree under
  // `.tom/docspecs-schema/` (the DocSpecs resolver layout) and a *flat* copy in
  // the asset dir. Flutter bundles a listed asset directory **non-recursively**,
  // so the nested resolver tree would be silently dropped — the flat copy is
  // what actually ships in the app bundle.
  _step(4, 'generate DocSpecs schemas (versioned, → .tom tree + flat assets)');
  final schemaTree = p.join(editorDir, '.tom', 'docspecs-schema');
  // Clear the resolver tree first. Schema dirs are named after the document
  // root, so a rename leaves the old-named dir behind; without this prune the
  // stale schema would survive and be resurrected by the recursive flat-copy
  // below. Regenerating from scratch keeps the tree a faithful mirror.
  final schemaTreeDir = Directory(schemaTree);
  if (schemaTreeDir.existsSync()) {
    schemaTreeDir.deleteSync(recursive: true);
  }
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

  // ── Step 5: embed pre-generated summaries (B1) ────────────────────────────
  _step(5, 'embed pre-generated Dart-editor summaries');
  final summaries = args.option('summaries');
  final summariesDest = Directory(p.join(editorDir, 'assets', 'summaries'));
  if (args.flag('generate-summaries')) {
    if (summaries != null) {
      _fail('--summaries and --generate-summaries are mutually exclusive.');
    }
    // Delegated wholesale to tom_dart_editor_bundler, which is the single
    // generator of this asset set. It reads the editor's own `buildkit.yaml`
    // (`dart-editor-bundler` block) for the scopes and their package closures,
    // writes `<out-dir>/<sdk-summary>` plus `<out-dir>/<scope>/packages.sum`,
    // and emits the `summary_scopes.g.dart` helper that names those very asset
    // paths — so what this step produces is by construction what the app asks
    // for at runtime. The closure (including tom_flutter_ui, OE-25) is declared
    // in that config and nowhere here.
    final bundlerDir =
        p.join(container, 'tom_forge', 'tom_dart_editor_bundler');
    final editorBuildkit = p.join(editorDir, 'buildkit.yaml');
    if (!File(editorBuildkit).existsSync()) {
      _fail('No buildkit.yaml in $editorDir — the summary scopes are declared '
          'in its `dart-editor-bundler` block.');
    }
    if (!Directory(bundlerDir).existsSync()) {
      _fail('tom_dart_editor_bundler not found at $bundlerDir.');
    }
    // The bundler analyses each configured package *closure*, so every package
    // dir named in the config must have a resolved package_config first. Read
    // back from the same config so this step never carries its own list.
    for (final dir in _bundlerPackageDirs(editorBuildkit)) {
      if (!Directory(dir).existsSync()) {
        _fail('buildkit.yaml names a summary package dir that does not exist: '
            '$dir');
      }
      await _run('flutter', ['pub', 'get'], cwd: dir);
    }
    await _run('dart', ['pub', 'get'], cwd: bundlerDir);
    await _run(
      'dart',
      [
        'run',
        p.join('bin', 'dart_editor_bundler.dart'),
        '--config', editorBuildkit,
        '--verbose',
      ],
      cwd: bundlerDir,
    );
    stdout.writeln('  → bundler wrote the summary assets and '
        'lib/generated/summary_scopes.g.dart under $editorDir');
  } else if (summaries == null) {
    stdout.writeln('  (no --summaries / --generate-summaries given; nothing to '
        'embed. Pass --generate-summaries to build them on this host with '
        'tom_dart_editor_bundler, or --summaries <dir> to copy a pre-generated '
        'asset tree. Code-typed fields fall back to a plain text field when the '
        '.sum assets are absent.)');
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

  // ── Step 6: bundle assets (verify they exist before the build) ────────────
  _step(6, 'bundle assets');
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

  // ── Step 7: flutter build ─────────────────────────────────────────────────
  if (args.flag('no-flutter-build')) {
    _step(7, 'flutter build — SKIPPED (--no-flutter-build)');
  } else {
    _step(7, 'flutter build $os');
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

/// The package directories every summary scope in [buildkitPath] covers,
/// resolved against the config file's own directory.
///
/// Read back out of the config rather than listed here: `buildkit.yaml` is the
/// single declaration of the summary closure, and a copy of it in this
/// orchestrator is exactly the duplication step 5 was rebuilt to remove. Only
/// the `packages:` lists are read — the output layout stays the bundler's.
List<String> _bundlerPackageDirs(String buildkitPath) {
  final baseDir = p.dirname(p.absolute(buildkitPath));
  final dynamic doc = loadYaml(File(buildkitPath).readAsStringSync());
  if (doc is! Map) return const [];
  final block = doc['dart-editor-bundler'];
  if (block is! Map) {
    _fail('$buildkitPath has no `dart-editor-bundler` block; there are no '
        'summary scopes to generate.');
  }
  final bundles = block['bundles'];
  if (bundles is! List) return const [];
  final dirs = <String>{};
  for (final bundle in bundles) {
    if (bundle is! Map) continue;
    final packages = bundle['packages'];
    if (packages is! List) continue;
    for (final pkg in packages) {
      if (pkg is String) dirs.add(p.normalize(p.join(baseDir, pkg)));
    }
  }
  return dirs.toList(growable: false);
}

/// Parses the generated stamp produced by `buildkit :versioner` (step 1),
/// reporting a missing or unparseable stamp as a build failure.
ModelVersionStamp _readStamp(String modelDir) {
  try {
    return readModelVersionStamp(modelDir);
  } on ModelVersionStampException catch (e) {
    _fail('${e.message} (did step 1 run?)');
  }
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
