/// Running a tool and the `tomspecs` command that replaces it on the same
/// inputs, and holding what they do to each other: stdout, stderr, the files
/// they write and the exit code (tsbin4..6; temporary, removed with the old
/// tools in tsbin8).
///
/// A tool's `main` is `exit(await run<Tool>(args))` (`bin/<tool>.dart`), so its
/// run function is the tool as a process runs it, less the process. Both are
/// run in this process with stdout and stderr captured ([IOOverrides]).
///
/// **Nothing outside the system temp folder is ever deleted or overwritten
/// here** ([_isScratch]): the work folders of [runBoth] must lie in it, and the
/// checked wrappers save and put back only what a test writes there.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart'
    show runExtractAnswers, runIrspecs, runValidateCodespecs, runValidateSpec;

import '../../bin/tomspecs.dart';

/// What one run did.
class ToolRun {
  /// The exit code.
  final int exitCode;

  /// Everything written to stdout.
  final String stdout;

  /// Everything written to stderr.
  final String stderr;

  /// The files in the work folder afterwards, work-relative, with their
  /// bytes as text.
  final Map<String, String> files;

  const ToolRun(this.exitCode, this.stdout, this.stderr, this.files);
}

/// Whether [path] lies strictly inside the system temp folder, and is neither
/// the current directory nor a folder holding it — the only places this file
/// may delete or overwrite.
bool _isScratch(String path) {
  final abs = p.normalize(p.absolute(path));
  final temp = p.normalize(p.absolute(Directory.systemTemp.path));
  final cwd = p.normalize(p.absolute(Directory.current.path));
  return p.isWithin(temp, abs) && !p.equals(abs, cwd) && !p.isWithin(abs, cwd);
}

/// Runs [body] with stdout and stderr captured.
Future<(int, String, String)> captureIo(Future<int> Function() body) async {
  final out = CapturedStdout();
  final err = CapturedStdout();
  final code = await IOOverrides.runZoned(
    body,
    stdout: () => out,
    stderr: () => err,
  );
  return (code, out.text, err.text);
}

/// Runs the old tool ([old] with [oldArgs]) and the command (`:[command]`
/// with [commandArgs]) in [work] (inside the system temp folder), each after
/// [prepare] filled the emptied folder, and returns both runs.
Future<(ToolRun, ToolRun)> runBoth({
  required Directory work,
  required Future<int> Function(List<String>) old,
  required List<String> oldArgs,
  required String command,
  required List<String> commandArgs,
  void Function(Directory work)? prepare,
}) async {
  if (!_isScratch(work.path)) {
    throw ArgumentError.value(
      work.path,
      'work',
      'not inside the system temp folder',
    );
  }
  Future<ToolRun> one(Future<int> Function() body) async {
    if (work.existsSync()) work.deleteSync(recursive: true);
    work.createSync(recursive: true);
    prepare?.call(work);
    final (code, out, err) = await captureIo(body);
    return ToolRun(code, out, err, filesUnder(work));
  }

  final oldRun = await one(() => old(oldArgs));
  final commandRun = await one(
    () => runTomspecs([':$command', ...commandArgs]),
  );
  return (oldRun, commandRun);
}

/// Holds the command's run to the old tool's: the same exit code, stdout,
/// stderr and files.
void expectSameRun(ToolRun old, ToolRun command, {String? reason}) {
  final why = reason == null ? '' : '$reason: ';
  expect(command.exitCode, old.exitCode, reason: '${why}exit code');
  expect(command.stdout, old.stdout, reason: '${why}stdout');
  expect(command.stderr, old.stderr, reason: '${why}stderr');
  expect(
    command.files.keys.toList()..sort(),
    old.files.keys.toList()..sort(),
    reason: '${why}written files',
  );
  for (final MapEntry(key: name, value: text) in old.files.entries) {
    expect(command.files[name], text, reason: '${why}file $name');
  }
}

/// Every file under [dir], [dir]-relative with `/`, its bytes as text.
Map<String, String> filesUnder(Directory dir) => {
  for (final f in dir.listSync(recursive: true).whereType<File>())
    p.relative(f.path, from: dir.path).replaceAll(r'\', '/'): utf8.decode(
      f.readAsBytesSync(),
      allowMalformed: true,
    ),
};

/// A [Stdout] that keeps what is written.
class CapturedStdout implements Stdout {
  final _buffer = StringBuffer();

  /// Everything written.
  String get text => '$_buffer';

  @override
  Encoding encoding = utf8;

  @override
  String lineTerminator = '\n';

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) {
    _buffer.write(object);
    _buffer.write(lineTerminator);
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) =>
      _buffer.writeAll(objects, separator);

  @override
  void writeCharCode(int charCode) => _buffer.writeCharCode(charCode);

  @override
  void add(List<int> data) => _buffer.write(encoding.decode(data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.forEach(add);

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> get done async {}

  @override
  bool get hasTerminal => false;

  @override
  bool get supportsAnsiEscapes => false;

  @override
  int get terminalColumns => throw const StdoutException('no terminal');

  @override
  int get terminalLines => throw const StdoutException('no terminal');

  @override
  IOSink get nonBlocking => this;
}

// ---------------------------------------------------------------------------
// The tool tests, run through the commands as well
// ---------------------------------------------------------------------------

/// The irspecs subcommands and the command each became.
const _irCommands = {
  'from-codespecs': 'ir-from-codespecs',
  'map': 'ir-map',
  'emit': 'ir-emit',
  'export': 'ir-export',
};

/// [runIrspecs] as the irspecs tests call it, also run as the `tomspecs`
/// command the subcommand became: the command runs first, against the state
/// the test prepared (the `--out` folder saved and put back), then the tool
/// with the test's own [out] and [err]; both must end alike (see
/// [_runChecked]). Without a subcommand (a usage test) only the tool runs.
Future<int> runIrspecsChecked(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) {
  final index = args.indexWhere(_irCommands.containsKey);
  if (index < 0) return runIrspecs(args, out: out, err: err);
  final command = _irCommands[args[index]]!;
  final commandArgs = [...args]..removeAt(index);
  return _runChecked(
    command: command,
    commandArgs: commandArgs,
    old: (o, e) => runIrspecs(args, out: o, err: e),
    writes: [_optionValue(args, 'out')],
    out: out,
    err: err,
  );
}

/// [runValidateCodespecs], also run as `tomspecs :codespecs-validate`
/// ([runIrspecsChecked]); `coverage_gaps.yaml` beside `--extracts` is the one
/// file it may write, so the extracts folder is saved and put back.
Future<int> runValidateCodespecsChecked(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) => _runChecked(
  command: 'codespecs-validate',
  commandArgs: args,
  old: (o, e) => runValidateCodespecs(args, out: o, err: e),
  writes: [_optionValue(args, 'extracts')],
  out: out,
  err: err,
);

/// [runValidateSpec], also run as `tomspecs :spec-validate`
/// ([runIrspecsChecked]).
Future<int> runValidateSpecChecked(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) => _runChecked(
  command: 'spec-validate',
  commandArgs: args,
  old: (o, e) => runValidateSpec(args, out: o, err: e),
  writes: [
    _optionValue(args, 'markdown-out'),
    _optionValue(args, 'assembled-out'),
  ],
  out: out,
  err: err,
);

/// [runExtractAnswers], also run as `tomspecs :spec-answers`
/// ([runIrspecsChecked]).
Future<int> runExtractAnswersChecked(
  List<String> args, {
  StringSink? out,
  StringSink? err,
}) => _runChecked(
  command: 'spec-answers',
  commandArgs: args,
  old: (o, e) => runExtractAnswers(args, out: o, err: e),
  writes: [_optionValue(args, 'output'), _optionValue(args, 'o')],
  out: out,
  err: err,
);

String? _optionValue(List<String> args, String name) {
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if ((a == '--$name' || (name.length == 1 && a == '-$name')) &&
        i + 1 < args.length) {
      return args[i + 1];
    }
    if (a.startsWith('--$name=')) return a.substring(name.length + 3);
  }
  return null;
}

/// Runs `:[command]` with [commandArgs] (stdout and stderr captured), puts
/// back what it wrote at [writes], then runs [old] with the test's sinks. The
/// exit codes must agree; so must stdout and stderr, except on a usage error
/// (exit 2), which tom_build_base reports in its own words when it is the one
/// that catches it (an undeclared option, a value outside the allowed ones).
///
/// A write target outside the system temp folder is never saved, restored or
/// deleted ([_isScratch]); then only the tool runs.
Future<int> _runChecked({
  required String command,
  required List<String> commandArgs,
  required Future<int> Function(StringSink out, StringSink err) old,
  required List<String?> writes,
  StringSink? out,
  StringSink? err,
}) async {
  final targets = writes.nonNulls.toList();
  Future<int> oldOnly() async {
    final oldOut = StringBuffer();
    final oldErr = StringBuffer();
    final code = await old(oldOut, oldErr);
    (out ?? stdout).write('$oldOut');
    (err ?? stderr).write('$oldErr');
    return code;
  }

  if (!targets.every(_isScratch)) return oldOnly();
  final keep = Directory.systemTemp.createTempSync('tomspecs_checked_');
  try {
    final kept = <String, Directory?>{
      for (final (i, path) in targets.indexed)
        path: _save(path, p.join(keep.path, '$i')),
    };
    final (commandCode, commandOut, commandErr) = await captureIo(
      () => runTomspecs([':$command', ...commandArgs]),
    );
    for (final MapEntry(key: path, value: copy) in kept.entries) {
      _restore(path, copy);
    }
    final oldOut = StringBuffer();
    final oldErr = StringBuffer();
    final code = await old(oldOut, oldErr);
    (out ?? stdout).write('$oldOut');
    (err ?? stderr).write('$oldErr');
    expect(
      commandCode,
      code,
      reason:
          ':$command ${commandArgs.join(' ')}: exit code\n'
          'command stderr: $commandErr',
    );
    if (code != 2) {
      expect(commandOut, '$oldOut', reason: ':$command: stdout');
      expect(commandErr, '$oldErr', reason: ':$command: stderr');
    }
    return code;
  } finally {
    keep.deleteSync(recursive: true);
  }
}

/// A copy of [path] under [to] (a folder holding it), or null when [path]
/// does not exist.
Directory? _save(String path, String to) {
  final type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.notFound) return null;
  final copy = Directory(to)..createSync(recursive: true);
  if (type == FileSystemEntityType.file) {
    File(path).copySync(p.join(copy.path, 'file'));
  } else {
    _copyTree(Directory(path), Directory(p.join(copy.path, 'dir')));
  }
  return copy;
}

/// Puts [path] back as [copy] holds it (gone when [copy] is null). Only ever
/// called for a [_isScratch] path.
void _restore(String path, Directory? copy) {
  if (!_isScratch(path)) {
    throw StateError('refusing to restore outside the temp folder: $path');
  }
  final type = FileSystemEntity.typeSync(path);
  if (type == FileSystemEntityType.directory) {
    Directory(path).deleteSync(recursive: true);
  } else if (type != FileSystemEntityType.notFound) {
    File(path).deleteSync();
  }
  if (copy == null) return;
  final file = File(p.join(copy.path, 'file'));
  if (file.existsSync()) {
    file.copySync(path);
  } else {
    _copyTree(Directory(p.join(copy.path, 'dir')), Directory(path));
  }
}

void _copyTree(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final e in from.listSync(recursive: true)) {
    final target = p.join(to.path, p.relative(e.path, from: from.path));
    if (e is Directory) {
      Directory(target).createSync(recursive: true);
    } else if (e is File) {
      File(target).parent.createSync(recursive: true);
      e.copySync(target);
    }
  }
}
