/// The canonical path form of the file facade (`spec_file_facade.dart`):
/// absolute, `/`-separated, `.` and `..` collapsed.
///
/// Every whitelist root and every checked path is reduced to this one form, so
/// a write check is a string-prefix test. On Windows a path keeps its drive
/// (`C:/Users/x`, the letter upper-cased) or its UNC prefix (`//server/share`);
/// Windows accepts `/` as a separator, so the canonical form opens as it is.
///
/// The functions take the platform as a parameter rather than reading
/// `Platform` so that the Windows rules are tested on every host.
library;

final RegExp _drive = RegExp(r'^([A-Za-z]:)(/|$)');

/// [path] with every separator written `/`; on Windows `\` is a separator, on
/// POSIX it is an ordinary file-name character and is kept.
String toSlashes(String path, {required bool windows}) =>
    windows ? path.replaceAll(r'\', '/') : path;

/// The length of the root of a `/`-separated absolute [path]: 1 for `/`, 3 for
/// a Windows drive (`C:/`), 2 for a UNC path (`//`); 0 when [path] is relative.
int canonicalRootLength(String path, {required bool windows}) {
  if (windows) {
    if (_drive.hasMatch(path)) return 3;
    if (path.startsWith('//')) return 2;
  }
  return path.startsWith('/') ? 1 : 0;
}

/// [path] made absolute against [base] (itself absolute), `/`-separated.
String absoluteAgainst(String path, String base, {required bool windows}) {
  final p = toSlashes(path, windows: windows);
  if (canonicalRootLength(p, windows: windows) > 0) return p;
  return '${toSlashes(base, windows: windows)}/$p';
}

/// Collapses `.` and `..` segments in an absolute, `/`-separated [path] and
/// writes its root canonically; `..` never climbs above the root.
String normalizeCanonical(String path, {required bool windows}) {
  final p = toSlashes(path, windows: windows);
  var root = '/';
  var rest = p;
  if (windows) {
    final drive = _drive.firstMatch(p);
    if (drive != null) {
      root = '${drive.group(1)!.toUpperCase()}/';
      rest = p.substring(drive.group(1)!.length);
    } else if (p.startsWith('//')) {
      root = '//';
    }
  }
  final out = <String>[];
  for (final seg in rest.split('/')) {
    if (seg.isEmpty || seg == '.') continue;
    if (seg == '..') {
      if (out.isNotEmpty) out.removeLast();
      continue;
    }
    out.add(seg);
  }
  return '$root${out.join('/')}';
}
