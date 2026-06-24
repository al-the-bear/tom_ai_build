/// The audited file-access facade behind the `files` scope (§7, plan step 8).
///
/// [SpecFileFacade] is the **only** file surface a sandboxed script reaches in
/// the `files` scope — the raw `dcli` / `dart:io` write surface is never bridged.
/// Its policy:
///
///   * **read = any path** — the agent may explore arbitrary files read-only;
///   * **write = whitelist only** — mutating operations are permitted only under
///     a small set of writable directories inside the spec workspace, the
///     default being `agent/scratchpad`.
///
/// Enforcement is **path canonicalisation**: every write path is made absolute,
/// has its existing ancestors' symlinks resolved, and `.`/`..` segments
/// collapsed, then checked against the canonicalised whitelist roots. Any write
/// that escapes the whitelist — directly, via `..`, or through a symlink —
/// raises [FilePermissionError] *before* a single byte is written. The `files`
/// scope layers the D4rt permission system (`read=any` + `write=<whitelist>`) on
/// top as a defence-in-depth backstop (see `files_scope.dart`).
library;

import 'dart:io';

/// Raised when a write/mutate operation targets a path outside the facade's
/// writable whitelist. Thrown *before* any filesystem change.
final class FilePermissionError implements Exception {
  /// The (canonicalised) path the operation tried to write.
  final String path;

  /// Human-readable description of the violation.
  final String message;

  /// Creates a file-permission error for [path] with [message].
  FilePermissionError(this.path, this.message);

  @override
  String toString() => 'FilePermissionError: $message (path: $path)';
}

/// A thin, audited file wrapper: read-anywhere, write-only-under-whitelist.
final class SpecFileFacade {
  /// The canonicalised spec workspace root that relative paths resolve against.
  final String workspaceRoot;

  /// The canonicalised directories writes are permitted under.
  final List<String> writableRoots;

  SpecFileFacade._(this.workspaceRoot, this.writableRoots);

  /// Creates a facade rooted at [workspaceRoot].
  ///
  /// [writableDirs] are the directories writes may target, relative to the
  /// workspace root (absolute paths are honoured as-is); the default is the
  /// single `agent/scratchpad` directory. Roots are canonicalised once here so
  /// later checks compare resolved paths.
  factory SpecFileFacade({
    required String workspaceRoot,
    List<String> writableDirs = const ['agent/scratchpad'],
  }) {
    final root = _canonicalize(workspaceRoot, workspaceRoot);
    final roots = [
      for (final dir in writableDirs) _canonicalize(dir, root),
    ];
    return SpecFileFacade._(root, roots);
  }

  // --- read (any path) ----------------------------------------------------

  /// The full text of the file at [path].
  String readText(String path) => File(_resolve(path)).readAsStringSync();

  /// The lines of the file at [path].
  List<String> readLines(String path) =>
      File(_resolve(path)).readAsLinesSync();

  /// The first [lines] lines of the file at [path].
  String head(String path, {int lines = 10}) =>
      File(_resolve(path)).readAsLinesSync().take(lines).join('\n');

  /// The last [lines] lines of the file at [path].
  String tail(String path, {int lines = 10}) {
    final all = File(_resolve(path)).readAsLinesSync();
    final start = all.length <= lines ? 0 : all.length - lines;
    return all.sublist(start).join('\n');
  }

  /// Whether anything exists at [path].
  bool exists(String path) =>
      FileSystemEntity.typeSync(_resolve(path)) !=
      FileSystemEntityType.notFound;

  /// File metadata at [path]: `type`, `size`, and ISO `modified`.
  Map<String, Object?> stat(String path) {
    final resolved = _resolve(path);
    final type = FileSystemEntity.typeSync(resolved);
    if (type == FileSystemEntityType.notFound) {
      return {'type': 'notFound', 'size': 0, 'modified': null};
    }
    final s = FileStat.statSync(resolved);
    return {
      'type': type.toString().split('.').last,
      'size': s.size,
      'modified': s.modified.toIso8601String(),
    };
  }

  /// The paths of entries under directory [dir] (recursively), optionally
  /// filtered to basenames matching the `*` [glob]. Read-only exploration.
  List<String> find(String dir, {String? glob}) {
    final base = Directory(_resolve(dir));
    if (!base.existsSync()) return const [];
    final re = glob == null ? null : _globToRegExp(glob);
    return [
      for (final e in base.listSync(recursive: true))
        if (re == null || re.hasMatch(_basename(e.path))) e.path,
    ];
  }

  // --- write (whitelist only) ---------------------------------------------

  /// Writes [content] to [path] (creating parents), replacing any existing file.
  void writeText(String path, String content) {
    final target = _assertWritable(path);
    File(target)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  /// Appends [content] to the file at [path] (creating parents).
  void append(String path, String content) {
    final target = _assertWritable(path);
    File(target)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(content, mode: FileMode.append);
  }

  /// Creates the directory at [path] (and parents).
  void createDir(String path) {
    final target = _assertWritable(path);
    Directory(target).createSync(recursive: true);
  }

  /// Copies the file at [from] (any path, read) to [to] (must be writable).
  void copy(String from, String to) {
    final source = _resolve(from);
    final target = _assertWritable(to);
    File(target).parent.createSync(recursive: true);
    File(source).copySync(target);
  }

  /// Moves the file at [from] to [to]. Both ends must be writable (a move both
  /// deletes the source and creates the destination).
  void move(String from, String to) {
    final source = _assertWritable(from);
    final target = _assertWritable(to);
    File(target).parent.createSync(recursive: true);
    File(source).renameSync(target);
  }

  /// Deletes the file or directory at [path] (must be writable).
  void delete(String path) {
    final target = _assertWritable(path);
    final type = FileSystemEntity.typeSync(target);
    if (type == FileSystemEntityType.directory) {
      Directory(target).deleteSync(recursive: true);
    } else if (type != FileSystemEntityType.notFound) {
      File(target).deleteSync();
    }
  }

  // --- enforcement --------------------------------------------------------

  /// Resolves [path] for a *read*: absolute-ised against the workspace root and
  /// normalised, with no whitelist check (reads are permitted anywhere).
  String _resolve(String path) => _canonicalize(path, workspaceRoot);

  /// Canonicalises [path] and asserts it falls under a writable root, throwing
  /// [FilePermissionError] *before* any I/O when it does not.
  String _assertWritable(String path) {
    final canonical = _canonicalize(path, workspaceRoot);
    for (final root in writableRoots) {
      if (canonical == root || canonical.startsWith('$root$_sep')) {
        return canonical;
      }
    }
    throw FilePermissionError(
      canonical,
      'write outside the permitted directories '
      '(${writableRoots.join(', ')})',
    );
  }

  static const String _sep = '/';

  String _basename(String path) {
    final i = path.lastIndexOf(Platform.pathSeparator);
    return i < 0 ? path : path.substring(i + 1);
  }

  static RegExp _globToRegExp(String glob) {
    final sb = StringBuffer('^');
    for (final ch in glob.split('')) {
      if (ch == '*') {
        sb.write('[^/]*');
      } else {
        sb.write(RegExp.escape(ch));
      }
    }
    sb.write(r'$');
    return RegExp(sb.toString());
  }

  /// Makes [path] absolute against [base], resolves the symlinks of its longest
  /// existing ancestor, and collapses `.`/`..` — the single canonical form both
  /// the whitelist roots and every checked path are reduced to.
  static String _canonicalize(String path, String base) {
    final abs = _normalize(_absolute(path, base));

    // Resolve symlinks on the longest existing prefix, then re-attach the
    // not-yet-existing tail (so a write to a new file under a symlinked dir is
    // still resolved through the link).
    var probe = abs;
    final tail = <String>[];
    while (FileSystemEntity.typeSync(probe, followLinks: false) ==
        FileSystemEntityType.notFound) {
      final i = probe.lastIndexOf(_sep);
      if (i <= 0) break;
      tail.insert(0, probe.substring(i + 1));
      probe = probe.substring(0, i);
    }
    var real = probe;
    try {
      real = Directory(probe).resolveSymbolicLinksSync();
    } catch (_) {
      try {
        real = File(probe).resolveSymbolicLinksSync();
      } catch (_) {
        real = probe;
      }
    }
    final joined = tail.isEmpty ? real : '$real$_sep${tail.join(_sep)}';
    return _normalize(joined);
  }

  static String _absolute(String path, String base) {
    final p = path.replaceAll(Platform.pathSeparator, _sep);
    if (p.startsWith(_sep)) return p;
    final b = base.replaceAll(Platform.pathSeparator, _sep);
    return '$b$_sep$p';
  }

  /// Collapses `.` and `..` segments in an absolute, `/`-separated path.
  static String _normalize(String path) {
    final out = <String>[];
    for (final seg in path.split(_sep)) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        if (out.isNotEmpty) out.removeLast();
        continue;
      }
      out.add(seg);
    }
    return '$_sep${out.join(_sep)}';
  }
}
