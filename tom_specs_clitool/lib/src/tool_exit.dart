/// The end of a tool run with an exit code, thrown where a tool used to call
/// `exit()`: the tool's run function catches it and returns the code, so the
/// `tomspecs` binary can run several tools' commands in one process.
library;

/// A tool's run ends here with [code].
class ToolExit implements Exception {
  /// The exit code of the run.
  final int code;

  /// A run that ends with [code].
  const ToolExit(this.code);

  @override
  String toString() => 'ToolExit($code)';
}
