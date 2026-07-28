/// Addressing for the Tom Brain memory plane (`llm_and_d4rt_tools.md` §9).
library;

/// Addresses a unit of agent work across the three isolation levels the
/// TomSpecs engine establishes over Tom Brain (`llm_and_d4rt_tools.md` §9 /
/// Q1):
///
///   * [application] → a Tom Brain **profile** (the prompt / tool / MCP bundle
///     an agent runs under). Realised at the agent steps (15–17); carried here
///     as the addressing component so the memory plane and the agent plane
///     speak one vocabulary.
///   * [session] → a Tom Brain **named session** (one phase/task run, with its
///     own settings). Likewise an agent-step concern; carried here.
///   * [document] → a Tom Brain **named memory** — the unit that partitions the
///     in-process memory store. At the *memory* plane this is the only
///     isolation key: each open document gets its own profile-backed
///     `memory.db` / `vectors.db`, so two specs never cross-talk. See
///     `llm_and_d4rt_tools.md` §9.3.
///
/// All three components are validated so none can escape the Tom Brain
/// `<memory-root>/profiles/` directory: each must be non-empty and match
/// `[A-Za-z0-9_-]+` (no path separators, no `.` / `..`). [profileName] is the
/// Tom Brain memory profile this scope binds to — the [document] verbatim.
final class MemoryScope {
  /// The agent application this work belongs to (→ Tom Brain profile).
  final String application;

  /// The phase/task run within the application (→ Tom Brain named session).
  final String session;

  /// The document under work — the memory partition (→ Tom Brain named memory).
  final String document;

  /// Creates a scope, validating each component as a safe profile-path segment.
  MemoryScope({
    required this.application,
    required this.session,
    required this.document,
  }) {
    _validateSegment('application', application);
    _validateSegment('session', session);
    _validateSegment('document', document);
  }

  /// The Tom Brain memory profile this scope binds to.
  ///
  /// The memory partition is the [document]; [application] and [session] are
  /// agent-plane context that does not partition the store (D6). Each document
  /// therefore owns one isolated profile-backed memory.
  String get profileName => document;

  static final RegExp _segment = RegExp(r'^[A-Za-z0-9_-]+$');

  static void _validateSegment(String field, String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, field, 'must be non-empty');
    }
    if (value == '.' || value == '..' || !_segment.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        field,
        'must match [A-Za-z0-9_-]+ (no path separators, no "." / "..")',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is MemoryScope &&
      other.application == application &&
      other.session == session &&
      other.document == document;

  @override
  int get hashCode => Object.hash(application, session, document);

  @override
  String toString() =>
      'MemoryScope(application: $application, session: $session, '
      'document: $document)';
}
