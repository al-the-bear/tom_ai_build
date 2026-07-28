/// The **file tools** — the engine-side logic behind the `file_*` MCP tools
/// (`llm_and_d4rt_tools.md` §8.2).
///
/// [FileTools] is the in-process surface the editor's `AgentToolsModule` wraps
/// as `file_read` / `file_find` / `file_write`. It binds the audited
/// [SpecFileFacade] (`llm_and_d4rt_tools.md` §7) — **read = any path, write =
/// whitelist only** — and projects each operation to a typed value with a
/// compact [toJson]. A `file_write` outside the whitelist is reported as a
/// failed result (the facade's [FilePermissionError] message), never a thrown
/// stack, so the agent can react to it like any other tool error.
library;

import '../scope/spec_file_facade.dart';

/// The `file_read` result.
final class FileReadResult {
  /// The path that was read.
  final String path;

  /// Whether anything exists at [path].
  final bool exists;

  /// The file's full text (`null` when it does not exist).
  final String? content;

  const FileReadResult({
    required this.path,
    required this.exists,
    this.content,
  });

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'path': path,
        'exists': exists,
        if (content != null) 'content': content,
      };
}

/// The `file_find` result.
final class FileFindResult {
  /// The basename glob that was searched.
  final String glob;

  /// The matching paths.
  final List<String> matches;

  const FileFindResult({required this.glob, required this.matches});

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {'glob': glob, 'matches': matches};
}

/// The `file_write` result.
final class FileWriteResult {
  /// Whether the write succeeded (the path was inside the whitelist).
  final bool ok;

  /// The path that was written.
  final String path;

  /// The permission-violation message when the write was rejected.
  final String? error;

  const FileWriteResult({required this.ok, required this.path, this.error});

  /// A compact JSON view for the MCP tool result.
  Map<String, Object?> toJson() => {
        'ok': ok,
        'path': path,
        if (error != null) 'error': error,
      };
}

/// Reads, finds, and writes files under the `llm_and_d4rt_tools.md` §8.2
/// `file_*` tools, mediated by the audited [SpecFileFacade]
/// (`llm_and_d4rt_tools.md` §7).
final class FileTools {
  /// Creates the toolset over the audited [facade].
  FileTools(this.facade);

  /// The read-anywhere / write-whitelist file facade.
  final SpecFileFacade facade;

  /// `file_read` — the full text of the file at [path] (read is permitted
  /// anywhere). Reports `exists: false` for a missing file rather than throwing.
  FileReadResult read(String path) {
    if (!facade.exists(path)) {
      return FileReadResult(path: path, exists: false);
    }
    return FileReadResult(
      path: path,
      exists: true,
      content: facade.readText(path),
    );
  }

  /// `file_find` — the paths under [dir] matching [glob] (read-only
  /// exploration; `dir` defaults to the workspace root). The glob supports
  /// `*` / `**` / `?` / `[...]` / `{a,b}`; a glob containing `/` matches the
  /// path relative to the search root, otherwise the basename (see
  /// [SpecFileFacade.find]). With [includeAssets] the search also walks the
  /// profile's declared asset directories and returns the de-duplicated union.
  FileFindResult find(String glob, {String dir = '.', bool includeAssets = false}) =>
      FileFindResult(
        glob: glob,
        matches: facade.find(dir, glob: glob, includeAssets: includeAssets),
      );

  /// `file_write` — writes [content] to [path] (whitelist-checked). A path
  /// outside the writable whitelist returns a failed result carrying the
  /// [FilePermissionError] message; nothing is written.
  FileWriteResult write(String path, String content) {
    try {
      facade.writeText(path, content);
      return FileWriteResult(ok: true, path: path);
    } on FilePermissionError catch (e) {
      return FileWriteResult(ok: false, path: path, error: e.message);
    }
  }
}
