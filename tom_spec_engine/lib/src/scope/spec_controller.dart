/// The live-document controller contract the `spec` scope binds to (§5).
///
/// The TomSpecs editor's `SpecDocumentController` is the single document
/// controller shared by the UI and the agent tools: every mutation routes
/// through it so the change log and undo stack see one stream of edits. That
/// controller is a **Flutter** class (`tom_specs_editor`), which this pure-Dart
/// engine cannot depend on. [SpecController] is the engine-side *port* the real
/// controller satisfies — the minimal read + mutation surface the `spec` scope's
/// script API delegates to.
///
/// The contract that makes the `spec` scope's "one change log" guarantee
/// (§5) hold: **every effective (non-no-op) mutation MUST produce one change-log
/// entry and one undo snapshot.** Because a script and a tool both call the same
/// methods, a script mutation is indistinguishable from a tool mutation — it
/// lands in the same change log and undo stack by construction, not by a
/// parallel path.
library;

/// The document read + mutation surface the `spec` scope routes through.
///
/// Implementations (the live `SpecDocumentController`, or a test stub) own the
/// change-log + undo bookkeeping; this port only names the operations. Reads are
/// side-effect free; every mutation that changes the document records exactly
/// one change-log entry and one undo snapshot (no-op edits record neither).
abstract interface class SpecController {
  /// The content value at [path], or `null` when unset.
  String? content(String path);

  /// The form [field] value at [path], or `null` when unset.
  String? formField(String path, String field);

  /// The ordered item paths of the list at [listPath] (empty when none).
  List<String> listItems(String listPath);

  /// Sets the content at [path] (an empty value clears it). Records a change-log
  /// entry + undo snapshot unless it is a no-op.
  void setContent(String path, String value);

  /// Sets the form [field] at [path] (an empty value clears it). Records a
  /// change-log entry + undo snapshot unless it is a no-op.
  void setFormField(String path, String field, String value);

  /// Appends an item to the list at [listPath] and returns its new path.
  /// Records a change-log entry + undo snapshot.
  String addListItem(String listPath);

  /// Removes the list item at [itemPath]; returns whether one was removed.
  /// Records a change-log entry + undo snapshot when something was removed.
  bool removeListItem(String itemPath);

  /// Adds the model-permitted child [childSegment] under [parentPath],
  /// returning the new node's path (§5 constrained creation).
  ///
  /// The add is validated against the meta-model (allowed kind / section-id
  /// pattern / cardinality); an illegal add throws `SpecCreationError`
  /// (`tom_som_dart_runtime`) and mutates nothing. A successful add records a
  /// change-log entry + undo snapshot.
  String addChild(String parentPath, String childSegment, {String? itemId});
}
