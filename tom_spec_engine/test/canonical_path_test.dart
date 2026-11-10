// The canonical path form of the file facade (lib/src/scope/canonical_path.dart),
// on both platforms' rules. The Windows cases are what legiondary01 exposed: an
// absolute `C:\…` path counted as relative and was glued onto the workspace root
// (`/C:/ws/C:/ws/agent/scratchpad`), so every file-facade test failed there.
import 'package:test/test.dart';
import 'package:tom_spec_engine/src/scope/canonical_path.dart';

void main() {
  group('CP-1 POSIX', () {
    test('CP-1.1 relative paths resolve against the base', () {
      expect(absoluteAgainst('a/b', '/ws', windows: false), '/ws/a/b');
      expect(absoluteAgainst('/x/y', '/ws', windows: false), '/x/y');
    });

    test('CP-1.2 dot segments collapse, never above the root', () {
      expect(normalizeCanonical('/ws/./a/../b', windows: false), '/ws/b');
      expect(normalizeCanonical('/../..', windows: false), '/');
    });

    test('CP-1.3 a backslash is a file-name character, not a separator', () {
      expect(normalizeCanonical(r'/ws/a\b', windows: false), r'/ws/a\b');
      expect(canonicalRootLength(r'C:\x', windows: false), 0);
    });
  });

  group('CP-2 Windows', () {
    test('CP-2.1 a drive path is absolute, in either separator', () {
      expect(
        absoluteAgainst(r'C:\Temp\out', r'C:\ws', windows: true),
        'C:/Temp/out',
      );
      expect(absoluteAgainst('D:/x', r'C:\ws', windows: true), 'D:/x');
    });

    test('CP-2.2 a relative path resolves against a drive base', () {
      expect(
        normalizeCanonical(
          absoluteAgainst(r'agent\scratchpad', r'C:\ws', windows: true),
          windows: true,
        ),
        'C:/ws/agent/scratchpad',
      );
    });

    test('CP-2.3 the drive is kept, upper-cased, and .. stops at it', () {
      expect(normalizeCanonical(r'c:\ws\..\..\x', windows: true), 'C:/x');
      expect(normalizeCanonical('C:', windows: true), 'C:/');
    });

    test('CP-2.4 the root lengths: drive, UNC, rooted, relative', () {
      expect(canonicalRootLength('C:/x', windows: true), 3);
      expect(canonicalRootLength('//srv/share', windows: true), 2);
      expect(canonicalRootLength('/x', windows: true), 1);
      expect(canonicalRootLength('x/y', windows: true), 0);
    });

    test('CP-2.5 a UNC path keeps its double slash', () {
      expect(
        normalizeCanonical(r'\\srv\share\a\..\b', windows: true),
        '//srv/share/b',
      );
    });
  });
}
