# Project Idea — Room Booking

*Phase 1 artifact. Free-form on purpose: nothing is filtered here, and nothing
is required to be structured. Filtering is the Blueprint's job
(`tom_specs_project_flow.md` PF-PHA-P1).*

## The problem

Our office has six meeting rooms. Booking one means finding the paper sheet
taped to its door, or asking whoever booked it last. Double bookings happen
about twice a week, and when they do, the meeting that loses is whichever one
has the more junior organiser. Nobody knows which rooms are actually used.

We want a small internal service where staff can see the rooms, see what is
booked, and book one — and where a double booking is impossible rather than
merely discouraged.

## Who uses it

- **Staff** — anyone in the office. They browse rooms and create bookings.
  About 60 people; perhaps 30 bookings a day.
- **Office manager** — owns the room list. Adds and retires rooms.
- **IT** — runs it. Wants it on the existing internal host, no new database
  server.

## Rough feature set

- A list of rooms with capacity and floor.
- For a chosen room and day, what is already booked.
- Create a booking: room, day, start and end time, a title, the organiser.
- **A booking must not overlap an existing booking of the same room.** This is
  the whole point of the exercise; everything else is convenience.
- Cancel your own booking.

## Out of scope, at least for now

- Recurring bookings. People asked, and we said later.
- Catering, equipment, room layouts.
- Integration with the calendar system. IT would like it; the business would
  like the thing to exist first.
- Approvals. Any member of staff may book any room.

## Constraints and expectations

- Internal only — no access from outside the office network.
- Must be up during office hours; an outage overnight is an inconvenience,
  not an incident.
- Wanted in weeks, not months. Small is a feature.

## Where this came from

- Two conversations with the office manager (May, June).
- The paper sheets themselves, photographed — the current "system".
- A one-page complaint from the sales team after a double booking cost them a
  client meeting room.

## Known contradictions, recorded rather than resolved

- The office manager says only she should add rooms. IT says nobody should
  have to ask her on a Friday afternoon. **Unresolved** — carried into Phase 2
  as a clarification.
- "Cancel your own booking" vs. "the office manager can fix anything".
  **Unresolved.**
