// Phase 5 — derived tests.
//
// Written BEFORE `lib/booking_rules.dart` existed and initially all RED; the
// baseline is `spec/05_phase5_baseline.txt`. Each group names the artifact it
// was derived from, which is what gate G5's "every requirement is reachable
// from at least one test" is checked against.
//
// Derivation, per `tom_specs_project_flow.md` PF-PHA-P5: the CodeSpecs supply
// the surface (what exists, with what types) and the Phase-3 specification
// supplies the semantics (what it must do, at what boundaries, with what
// errors). Neither alone is sufficient — the trio says there is a
// `findBookingConflict`, and only `RSP` `FR-001` says that touching intervals
// are allowed.
library;

import 'package:full_lifecycle_walkthrough/booking_rules.dart';
import 'package:test/test.dart';

Booking _b(
  String room,
  int startMinute,
  int endMinute, {
  String day = '2026-09-07',
  String title = 'Standup',
  String organiser = 'ada',
}) => Booking(
  roomId: room,
  day: day,
  startMinute: startMinute,
  endMinute: endMinute,
  title: title,
  organiser: organiser,
);

const int _t0900 = 9 * 60;
const int _t1000 = 10 * 60;
const int _t1030 = 10 * 60 + 30;
const int _t1100 = 11 * 60;
const int _t1200 = 12 * 60;

void main() {
  // --- FR-001, the rule itself ------------------------------------------
  group(
    'FR-001 a booking must not overlap another booking of the same room',
    () {
      test('an identical interval conflicts', () {
        final existing = [_b('r1', _t1000, _t1100)];
        expect(
          findBookingConflict(_b('r1', _t1000, _t1100), existing),
          isNotNull,
        );
      });

      test('a partially overlapping interval conflicts', () {
        final existing = [_b('r1', _t1000, _t1100)];
        expect(
          findBookingConflict(_b('r1', _t1030, _t1200), existing),
          isNotNull,
        );
      });

      test('an enclosing interval conflicts', () {
        final existing = [_b('r1', _t1000, _t1100)];
        expect(
          findBookingConflict(_b('r1', _t0900, _t1200), existing),
          isNotNull,
        );
      });

      test('an enclosed interval conflicts', () {
        final existing = [_b('r1', _t0900, _t1200)];
        expect(
          findBookingConflict(_b('r1', _t1000, _t1100), existing),
          isNotNull,
        );
      });

      test(
        'it names WHICH booking it clashed with, not merely that it did',
        () {
          final clash = _b('r1', _t1000, _t1100, title: 'Design review');
          final conflict = findBookingConflict(_b('r1', _t1030, _t1200), [
            clash,
          ]);
          expect(conflict?.title, 'Design review');
        },
      );
    },
  );

  // --- FR-001 boundaries -------------------------------------------------
  group('FR-001 boundaries', () {
    test('touching at the end does NOT conflict', () {
      final existing = [_b('r1', _t1000, _t1100)];
      expect(findBookingConflict(_b('r1', _t1100, _t1200), existing), isNull);
    });

    test('touching at the start does NOT conflict', () {
      final existing = [_b('r1', _t1100, _t1200)];
      expect(findBookingConflict(_b('r1', _t1000, _t1100), existing), isNull);
    });

    test('a different room does not conflict', () {
      final existing = [_b('r1', _t1000, _t1100)];
      expect(findBookingConflict(_b('r2', _t1000, _t1100), existing), isNull);
    });

    test('a different day does not conflict', () {
      final existing = [_b('r1', _t1000, _t1100, day: '2026-09-08')];
      expect(findBookingConflict(_b('r1', _t1000, _t1100), existing), isNull);
    });

    test('no existing bookings means no conflict', () {
      expect(findBookingConflict(_b('r1', _t1000, _t1100), const []), isNull);
    });
  });

  // --- FR-001 error paths ------------------------------------------------
  group('FR-001 error paths', () {
    test('a zero-length candidate is rejected, not reported conflict-free', () {
      expect(
        () => findBookingConflict(_b('r1', _t1000, _t1000), const []),
        throwsArgumentError,
      );
    });

    test('an end before its start is rejected', () {
      expect(
        () => findBookingConflict(_b('r1', _t1100, _t1000), const []),
        throwsArgumentError,
      );
    });
  });
}
