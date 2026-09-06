/// The one business rule this walkthrough implements — Phase 6 output.
///
/// Traceability, which is what `tom_specs_project_flow.md` gate G6 checks as an
/// unbroken chain requirement → spec section → CodeSpec → test → code:
///
/// | Link | Artifact |
/// |------|----------|
/// | Requirement | `FR-001` — a booking must not overlap another booking of the same room |
/// | Spec section | `RSP` `FRE-REQU-…` (Phase 3), from `SBP.9` (Phase 2), from the Project Idea |
/// | CodeSpec | `codespec/server/lib/src/services/booking_service.dart` |
/// | Test | `test/booking_rules_test.dart` (Phase 5, derived before this file existed) |
/// | Code | this file |
///
/// Deliberately free of framework dependencies. Phase 6 writes **business
/// code**; the Tom Framework owns persistence, transport and authorization, so
/// the part a person actually writes is a rule about intervals — which is why
/// this file runs under plain `dart test` and the CodeSpecs trio beside it does
/// not need to.
library;

/// One booking of one room, as a half-open time interval on a single day.
///
/// Times are **minutes from midnight**, which removes time-zone and
/// date-arithmetic questions the rule does not depend on. `start` is inclusive
/// and `end` is exclusive: two bookings that merely touch — 10:00–11:00 and
/// 11:00–12:00 — do not overlap, and the boundary test in Phase 5 pins that.
class Booking {
  /// The room this booking is for.
  final String roomId;

  /// The day, as `YYYY-MM-DD`.
  final String day;

  /// Start of the booking, minutes from midnight, inclusive.
  final int startMinute;

  /// End of the booking, minutes from midnight, exclusive.
  final int endMinute;

  /// What the room is booked for.
  final String title;

  /// Who booked it.
  final String organiser;

  /// Creates a booking.
  const Booking({
    required this.roomId,
    required this.day,
    required this.startMinute,
    required this.endMinute,
    required this.title,
    required this.organiser,
  });

  /// Whether this booking's interval is well-formed — a positive duration.
  ///
  /// A zero-length booking is not a booking, and a negative one is a data
  /// defect; both would slip past an overlap check that only compares
  /// endpoints, because an empty interval overlaps nothing.
  bool get hasPositiveDuration => endMinute > startMinute;

  @override
  String toString() =>
      '$roomId $day '
      '${_hhmm(startMinute)}–${_hhmm(endMinute)} "$title" ($organiser)';
}

String _hhmm(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

/// Whether [a] and [b] occupy the same room on the same day at the same time.
///
/// Half-open comparison, so touching intervals do not overlap.
bool bookingsOverlap(Booking a, Booking b) {
  if (a.roomId != b.roomId || a.day != b.day) return false;
  return a.startMinute < b.endMinute && b.startMinute < a.endMinute;
}

/// The first booking in [existing] that [candidate] would clash with, or `null`.
///
/// Returns the conflicting booking rather than a bare `bool` because the caller
/// has to tell the user *what* it clashed with — a rule that can only say "no"
/// moves the problem to the person holding the paper sheet, which is the
/// situation the project exists to end.
///
/// Throws [ArgumentError] on a candidate with no positive duration: that is a
/// caller defect, not a booking conflict, and reporting it as "no conflict"
/// would let a zero-length booking be stored.
Booking? findBookingConflict(Booking candidate, Iterable<Booking> existing) {
  if (!candidate.hasPositiveDuration) {
    throw ArgumentError.value(
      candidate,
      'candidate',
      'a booking must end after it starts',
    );
  }
  for (final other in existing) {
    if (bookingsOverlap(candidate, other)) return other;
  }
  return null;
}
