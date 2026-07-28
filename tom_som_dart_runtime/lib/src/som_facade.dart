/// The hand-written runtime support for the generated typed object model
/// (`tom_som_dart_v0`).
///
/// The generated classes are a thin **editing facade** over the generic
/// [SpecDocument]: every typed getter/setter reads or writes the path-keyed
/// memory representation directly, so a mutation made through the typed surface
/// is immediately visible through the generic path and vice-versa (SOM §6 — the
/// two access paths share one document). These base types ([SomNode],
/// [SomList], [SomScalar]) hold no state of their own beyond the document and a
/// path; the generated subclasses only add typed accessors.
library;

import 'spec_document.dart';
import 'spec_section_id.dart';

/// The base class every generated typed facade class extends.
///
/// It binds a facade instance to the [doc] it edits and the [path] it lives at
/// (the globally-unique section path, per `spec_paths.dart`). The generated
/// subclass adds typed field accessors that delegate to [doc] at paths derived
/// from [path].
abstract class SomNode {
  /// The underlying generic document this facade edits.
  final SpecDocument doc;

  /// The section path this node lives at.
  final String path;

  SomNode(this.doc, this.path);

  /// Whether this section holds no value at all — neither a
  /// `content`/`scalar`/`enum` leaf, a `@Form` entry, a child section, nor a
  /// list item — at its [path] or nested beneath it (SOM §21).
  ///
  /// The typed counterpart of the generic [SpecDocument.hasValuesUnder], so
  /// "is this section filled?" answers identically through the typed facade and
  /// the generic path (the typed `.content` getter coalescing a missing value
  /// to `''` no longer disagrees with a generic `null`). Emptiness is defined
  /// once, in [SpecDocument.hasValuesUnder].
  ///
  /// Named `isEmpty` (no `$` prefix) to match the proposed API; a model field
  /// literally named `isEmpty` would collide with this getter, but the spec
  /// model carries none.
  bool get isEmpty => !doc.hasValuesUnder(path);

  /// Whether this section **type** declares the standard `content` text leaf —
  /// i.e. whether the `.content` getter/setter exists on it (SOM §21).
  ///
  /// This is a **structural / schema** predicate: a compile-time constant of the
  /// section's type, answering "*can* this section hold body text?" without a
  /// compile-error probe of `.content`. Container-only sections (e.g.
  /// `SystemsToReplace`, which has no `content` leaf) inherit this `false`
  /// default; content-bearing sections (e.g. `Goals`) override it to `true`.
  ///
  /// It is deliberately distinct from the two **state** predicates: the generic
  /// [SpecDocument.hasContent] answers "is a value present at this leaf *now*?"
  /// and [isEmpty] answers "is this subtree empty *now*?". `canHaveContent` never
  /// looks at the document — it describes the model, not the data.
  bool get canHaveContent => false;

  /// This node's section id when it is a list item (AA1 criterion 1 read),
  /// or `null` for non-list nodes (roots, complex/section children — their id
  /// is the fixed `@SectionId` already embedded in [path]).
  ///
  /// Named with a `$` prefix so this structural accessor can never collide with
  /// a typed field a generated subclass emits from a model field. Model field
  /// accessors are plain Dart identifiers (never `$`-prefixed), so a `@Form`
  /// section that happens to carry a field literally named `sectionId` keeps its
  /// own `sectionId` getter/setter alongside this one.
  String? get $sectionId => doc.itemSectionId(path);

  /// Overrides this list item's section id (AA1 criterion 5): an arbitrary
  /// suffix, validated unique within the owning list. Raises
  /// [SpecSectionIdCollision] on a duplicate, or [ArgumentError] if this node
  /// is not a live list item.
  set $sectionId(String? id) {
    if (id == null) return;
    doc.setItemSectionId(path, id);
  }

  /// This section's **stored headline** (YRD3), or `null` when the section
  /// renders its effective default title (`@Headline` default, else name
  /// derivation). Available on every node — fixed sections and list items
  /// alike — and `$`-prefixed for the same collision-proofing as [$sectionId].
  String? get $headline => doc.headline(path);

  /// Sets or clears this section's stored headline (YRD3). `null` or an empty
  /// string clears the store, returning the section to its default title.
  set $headline(String? value) => doc.setHeadline(path, value ?? '');

  /// This section's **CodeSpecs forward link** (`codespecs_mapping.md` §9.2) as
  /// the comma-joined list of code locations, or `null` when the section carries
  /// no mapping. Sparse exactly like [$headline], available on every node, and
  /// `$`-prefixed for the same collision-proofing as [$sectionId].
  String? get $codeSpec => doc.codeSpec(path);

  /// Sets or clears this section's CodeSpecs forward link (codespecs_mapping.md
  /// §9.2). `null` or an empty string clears the store, returning the section
  /// to "no code mapping".
  set $codeSpec(String? value) => doc.setCodeSpec(path, value ?? '');
}

/// A scalar list item — a bare string value held in the document's content
/// store at its own item [path]. Used as the element facade for non-complex
/// (`String`/scalar) lists.
class SomScalar extends SomNode {
  SomScalar(super.doc, super.path);

  /// The string value at this item's path (`''` when unset).
  String get value => doc.content(path) ?? '';

  /// Sets the string value (an empty string clears it, per [SpecDocument]).
  set value(String v) => doc.setContent(path, v);
}

/// A typed view over a list field, layered over the document's list store.
///
/// Items are addressed by their stable item paths ([SpecDocument.listItems]);
/// each is wrapped in an element facade `T` by [_factory]. The wrapper holds no
/// items itself — every operation reads through the live document, so it always
/// reflects the current state.
class SomList<T> {
  /// The document this list edits.
  final SpecDocument doc;

  /// The list container's section path (items hang off it as `$listPath-<seq>`).
  final String listPath;

  final T Function(SpecDocument doc, String itemPath) _factory;

  /// The list field's `@SectionIdPattern` (e.g. `DACEN-ITEM-xxx`), or `null`
  /// for a pattern-less (scalar) list. Drives section-id generation on [add]
  /// (AA1 criteria 3–5).
  final String? pattern;

  SomList(this.doc, this.listPath, this._factory, {this.pattern});

  /// The number of items currently in the list.
  int get length => doc.listItemCount(listPath);

  /// The element facades for every item, in order.
  List<T> get items =>
      doc.listItems(listPath).map((p) => _factory(doc, p)).toList();

  /// The element facade for the item at [index].
  T operator [](int index) => _factory(doc, doc.listItems(listPath)[index]);

  /// The section ids currently assigned within this list, in item order.
  List<String> get sectionIds => doc.listItemSectionIds(listPath);

  /// Appends a new item and returns its element facade.
  ///
  /// When the list has a [pattern], the new item is assigned a section id
  /// (AA1 criteria 3–5): [sectionId] if given (an override, validated unique —
  /// raises [SpecSectionIdCollision] on a collision), otherwise one generated
  /// from the pattern using [date] (defaulting to now) for the two-letter-date
  /// component. A pattern-less list ignores both arguments.
  T add({String? sectionId, DateTime? date}) =>
      _factory(doc, _addItemPath(sectionId: sectionId, date: date));

  /// Appends a **content-only** item, sets its standard `content` leaf, and
  /// returns the element facade — in one call (SOM §21).
  ///
  /// The convenience for element types whose sole field is the standard
  /// `content` leaf (e.g. operational metrics): collapses the recurring
  /// `add().content = …` pair into a single call, and takes the same
  /// [sectionId]/[date] section-id arguments as [add]. The value is written to
  /// the nested `content` leaf (`<item>/content`), matching every generated
  /// content element's `content` accessor.
  ///
  /// For a scalar (`SomScalar`) list — whose value lives at the item path
  /// itself, not a nested `content` leaf — use [add] with `.value` instead.
  T addContent(String content, {String? sectionId, DateTime? date}) {
    final itemPath = _addItemPath(sectionId: sectionId, date: date);
    doc.setContent('$itemPath/content', content);
    return _factory(doc, itemPath);
  }

  /// A read-only view of every item's `content` leaf, in order (SOM §21).
  ///
  /// The content-only companion to [addContent]: yields each element's standard
  /// `content` value (a missing leaf coalesces to `''`, matching the generated
  /// element `content` getter), so a content-only list reads in one expression
  /// instead of an index loop. On a scalar list — whose value is at the item
  /// path, not a nested `content` leaf — every entry reads `''`; use [items]
  /// / element `.value` for those.
  Iterable<String> get contents =>
      doc.listItems(listPath).map((p) => doc.content('$p/content') ?? '');

  /// Removes the item at [index] and every value nested beneath it.
  void removeAt(int index) =>
      doc.removeListItem(doc.listItems(listPath)[index]);

  /// Derives the path for a freshly-appended item, assigning a section id when
  /// the list carries a [pattern] (shared by [add] and [addContent]).
  String _addItemPath({String? sectionId, DateTime? date}) {
    if (pattern == null) return doc.addListItem(listPath);
    final id = sectionId ??
        generateListItemSectionId(
            pattern!, date ?? DateTime.now(), doc.listItemSectionIds(listPath));
    return doc.addListItem(listPath, sectionId: id);
  }
}

/// Raised when a generated object model is instantiated against a document
/// whose authoring model version it must not edit (SOM §4.2).
class SomVersionException implements Exception {
  final String message;
  const SomVersionException(this.message);

  @override
  String toString() => 'SomVersionException: $message';
}

/// The outcome of the SOM §4.2 version check, as a value a read-only viewer can
/// branch on instead of catching [SomVersionException] (SOM §21).
///
/// It is the non-throwing companion to [checkSomModelVersion]: the constructor
/// throws on any value other than [editable], while [somEditabilityFor] returns
/// the same classification without throwing so a consumer can decide *open for
/// edit* vs *open read-only* up front.
enum SomEditability {
  /// The object model may edit the document in place — a `null`/empty stamp
  /// (a brand-new document) or a same-major, minor-`≤` stamp.
  editable,

  /// The document was authored under a **different major** version; it may be
  /// read/converted but never edited in place.
  readOnlyCrossMajor,

  /// The document is same-major but a **newer minor** than the object model; an
  /// older model must not edit a newer document.
  rejectedNewerMinor,

  /// The document stamp is not a valid `major.minor` string.
  invalidVersion,
}

/// Classifies a document's editability under the SOM §4.2 rules **without
/// throwing** (SOM §21). [generated] is the object model's own `major.minor`
/// version; [documentVersion] is the document's recorded authoring stamp
/// (`null`/empty for a brand-new, never-stamped document).
///
/// This is the single definition of the version rules; [checkSomModelVersion]
/// throws based on the value returned here, so the two never diverge.
SomEditability somEditabilityFor(String generated, String? documentVersion) {
  if (documentVersion == null || documentVersion.isEmpty) {
    return SomEditability.editable;
  }
  final gen = _SomVersion.parse(generated);
  final doc = _SomVersion.tryParse(documentVersion);
  if (doc == null) return SomEditability.invalidVersion;
  if (doc.major != gen.major) return SomEditability.readOnlyCrossMajor;
  if (doc.minor > gen.minor) return SomEditability.rejectedNewerMinor;
  return SomEditability.editable;
}

/// The instantiation-time version check every generated root facade performs
/// (SOM §4.2). [generated] is the object model's own `major.minor` version;
/// [documentVersion] is the document's recorded authoring stamp (`null`/empty
/// for a brand-new, never-stamped document).
///
/// Rules (see [somEditabilityFor], which this delegates to):
///   * a `null`/empty document stamp is always accepted — a new document is
///     stamped on first edit;
///   * within the **same major** version, a document whose minor is **≤** the
///     generated minor is editable (older or equal — upgraded on edit); a
///     document whose minor is **greater** is rejected (an older model must not
///     edit a newer document);
///   * a **different major** version is always rejected (cross-major is
///     read/convert only, never in-place edit).
///
/// Throws [SomVersionException] on any rejection or an unparseable stamp.
void checkSomModelVersion(String generated, String? documentVersion) {
  switch (somEditabilityFor(generated, documentVersion)) {
    case SomEditability.editable:
      return;
    case SomEditability.invalidVersion:
      throw SomVersionException(
          'document model version "$documentVersion" is not a valid major.minor');
    case SomEditability.readOnlyCrossMajor:
      final gen = _SomVersion.parse(generated);
      final doc = _SomVersion.parse(documentVersion!);
      throw SomVersionException(
          'document major version ${doc.major} differs from the object model '
          'major version ${gen.major}; cross-major documents are read-only');
    case SomEditability.rejectedNewerMinor:
      throw SomVersionException(
          'document model version $documentVersion is newer than the object '
          'model version $generated; an older object model cannot edit a newer '
          'document');
  }
}

/// A parsed `major.minor` version pair.
class _SomVersion {
  final int major;
  final int minor;
  const _SomVersion(this.major, this.minor);

  static _SomVersion parse(String raw) {
    final v = tryParse(raw);
    if (v == null) {
      throw SomVersionException('"$raw" is not a valid major.minor version');
    }
    return v;
  }

  static _SomVersion? tryParse(String raw) {
    final parts = raw.split('.');
    if (parts.length != 2) return null;
    final major = int.tryParse(parts[0]);
    final minor = int.tryParse(parts[1]);
    if (major == null || minor == null) return null;
    return _SomVersion(major, minor);
  }
}
