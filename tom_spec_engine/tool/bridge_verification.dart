/// Decides whether a bridge regeneration actually produced bridges.
///
/// **Why this is not just `result.isSuccess`.** `GenerationResult.isSuccess` is
/// `errors.isEmpty`, and the generator has a path that resolves cleanly,
/// reports no error, emits nothing, and still names its output file in
/// `outputFiles` — measured with a barrel that parses but exports nothing
/// bridgeable: `totalClasses=0, errors=0, isSuccess=true`, output file absent.
///
/// On that path `regenerate_bridges.dart` would print `Success: true` and then
/// stamp `som_surface.stamp.json`, which is the one outcome the stamp exists to
/// prevent: it would certify a bridge set that was never regenerated, and the
/// freshness test — the gate one step downstream — would then pass over stale
/// bridges. A silent no-op here is worse than a crash.
///
/// The check that actually closes it is the **mtime** one. Existence is not
/// enough: in a real checkout the previous run's bridges are already on disk,
/// so a generation that quietly does nothing leaves files that exist, are
/// non-empty, and are wrong. Only "this run wrote them" distinguishes the two.
/// That check is sound because the generator's write is unconditional — it
/// never skips a file whose content is unchanged — so a legitimate idempotent
/// regeneration still advances every mtime.
library;

import 'dart:io';

/// How much clock skew to forgive when comparing a file's modification time
/// against the instant generation began.
///
/// **Two seconds, not one, and the difference is not caution.** `File`
/// modification times are truncated to whole seconds — measured on this host, a
/// file written at `12:01:19.786` reads back as `12:01:19.000`. So a file
/// written a millisecond *after* the start instant can legitimately read as up
/// to 999 ms *before* it, which makes a one-second tolerance exactly marginal:
/// it is consumed entirely by the truncation, and whether a sound run passes
/// then depends on the sub-second part of the start instant. That is what a
/// flaky test caught here.
///
/// Two seconds clears the quantum with margin while staying far below the
/// runtime of any real generation (the SOM bridges take ~80s), so it cannot
/// mask a file the run left untouched — such a file is at minimum a whole
/// previous run old.
const Duration bridgeMtimeTolerance = Duration(seconds: 2);

/// Why the regeneration must **not** be treated as successful, or `null` when
/// it produced bridges.
///
/// Returns a single human-readable reason rather than a list: the caller's only
/// decision is stamp-or-fail, and the first thing that is wrong is the thing to
/// fix. Checks run cheapest-first, so a caller sees the generator's own errors
/// before a derived symptom of them.
///
/// [startedAt] must be captured *before* generation begins.
String? bridgeRegenerationFailure({
  required int totalClasses,
  required List<String> outputFiles,
  required List<String> errors,
  required DateTime startedAt,
}) {
  if (errors.isNotEmpty) {
    return 'the generator reported ${errors.length} error(s):\n'
        '${errors.map((e) => '    $e').join('\n')}';
  }

  if (outputFiles.isEmpty) {
    return 'the generator named no output files at all — nothing was written';
  }

  if (totalClasses <= 0) {
    return 'the generator produced 0 classes. It reported no error, so this '
        'is the silent-no-op path: the sources resolved but nothing '
        'bridgeable was found. Check that the `d4rtgen:` barrels in '
        'buildkit.yaml still name the packages you mean.';
  }

  final threshold = startedAt.subtract(bridgeMtimeTolerance);
  for (final path in outputFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      return 'the generator named $path as an output but never wrote it';
    }
    if (file.lengthSync() == 0) {
      return 'the generator wrote $path empty';
    }
    if (file.lastModifiedSync().isBefore(threshold)) {
      return 'the generator left $path untouched (last modified '
          '${file.lastModifiedSync().toIso8601String()}, this run began '
          '${startedAt.toIso8601String()}). The file on disk is the previous '
          'run\'s output; stamping now would certify it as freshly generated.';
    }
  }

  return null;
}
