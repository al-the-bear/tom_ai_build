/// Finding and running the Typst compiler.
library;

import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:path/path.dart' as p;

/// The Typst binary is missing.
class TypstNotFound implements Exception {
  /// The error, naming the places looked in.
  const TypstNotFound(this.message);

  /// What was looked for where.
  final String message;

  @override
  String toString() => 'TypstNotFound: $message';
}

/// The Typst compiler, located.
class TypstCompiler {
  /// The compiler at [executable].
  const TypstCompiler(this.executable);

  /// The path to (or the name of) the `typst` binary.
  final String executable;

  /// The binaries layer's platform folder name for this host
  /// (`darwin-arm64`, `linux-x64`, `win32-x64`, …).
  static String platformFolder() {
    final os = switch (Platform.operatingSystem) {
      'macos' => 'darwin',
      'windows' => 'win32',
      final other => other,
    };
    final abi = Abi.current().toString();
    final arch = abi.contains('arm64')
        ? 'arm64'
        : abi.contains('x64')
        ? 'x64'
        : abi.split('_').last;
    return '$os-$arch';
  }

  /// Finds the compiler: [explicit] when given; else `typst` in the binaries
  /// layer (`$TOM_BINARY_PATH/<platform>/`); else `typst` on `PATH`. Throws
  /// [TypstNotFound] naming where it looked.
  static Future<TypstCompiler> find({
    String? explicit,
    Map<String, String>? environment,
  }) async {
    final env = environment ?? Platform.environment;
    final exe = Platform.isWindows ? 'typst.exe' : 'typst';
    if (explicit != null) {
      if (await _runs(explicit)) return TypstCompiler(explicit);
      throw TypstNotFound('--typst $explicit does not run');
    }
    final layer = env['TOM_BINARY_PATH'];
    final looked = <String>[];
    if (layer != null && layer.isNotEmpty) {
      final candidate = p.join(layer, platformFolder(), exe);
      looked.add(candidate);
      if (File(candidate).existsSync() && await _runs(candidate)) {
        return TypstCompiler(candidate);
      }
    }
    looked.add('$exe on PATH');
    if (await _runs(exe)) return TypstCompiler(exe);
    throw TypstNotFound(
      'typst not found (looked for ${looked.join(', ')}); install it '
      '(e.g. `brew install typst`, or a release from '
      'https://github.com/typst/typst/releases) or pass --typst <path>',
    );
  }

  static Future<bool> _runs(String executable) async {
    try {
      final r = await Process.run(executable, ['--version']);
      return r.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  /// The compiler's version line, `typst 0.15.1 (…)`.
  Future<String> version() async =>
      (await Process.run(executable, ['--version'])).stdout.toString().trim();

  /// Compiles the Typst file [input] to the PDF [output]; returns the exit
  /// code and what Typst wrote to stderr.
  Future<({int exitCode, String errors})> compile(
    String input,
    String output,
  ) async {
    final r = await Process.run(executable, ['compile', input, output]);
    return (exitCode: r.exitCode, errors: r.stderr.toString());
  }
}
