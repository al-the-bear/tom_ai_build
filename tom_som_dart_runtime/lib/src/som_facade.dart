/// The hand-written runtime support for the generated typed object model
/// (`tom_som_dart_v0`).
///
/// The generated classes are a thin **editing facade** over the generic
/// [SpecDocument]: every typed getter/setter reads or writes the path-keyed
/// memory representation directly, so a mutation made through the typed surface
/// is immediately visible through the generic path and vice-versa (§3 — the two
/// access paths share one document). These base types ([SomNode], [SomList],
/// [SomScalar]) hold no state of their own beyond the document and a path; the
/// generated subclasses only add typed accessors.
library;

import 'spec_document.dart';

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

  SomList(this.doc, this.listPath, this._factory);

  /// The number of items currently in the list.
  int get length => doc.listItemCount(listPath);

  /// The element facades for every item, in order.
  List<T> get items =>
      doc.listItems(listPath).map((p) => _factory(doc, p)).toList();

  /// The element facade for the item at [index].
  T operator [](int index) => _factory(doc, doc.listItems(listPath)[index]);

  /// Appends a new item and returns its element facade.
  T add() => _factory(doc, doc.addListItem(listPath));

  /// Removes the item at [index] and every value nested beneath it.
  void removeAt(int index) =>
      doc.removeListItem(doc.listItems(listPath)[index]);
}

/// Raised when a generated object model is instantiated against a document
/// whose authoring model version it must not edit (§2.2).
class SomVersionException implements Exception {
  final String message;
  const SomVersionException(this.message);

  @override
  String toString() => 'SomVersionException: $message';
}

/// The instantiation-time version check every generated root facade performs
/// (§2.2). [generated] is the object model's own `major.minor` version;
/// [documentVersion] is the document's recorded authoring stamp (`null`/empty
/// for a brand-new, never-stamped document).
///
/// Rules:
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
  if (documentVersion == null || documentVersion.isEmpty) return;
  final gen = _SomVersion.parse(generated);
  final doc = _SomVersion.tryParse(documentVersion);
  if (doc == null) {
    throw SomVersionException(
        'document model version "$documentVersion" is not a valid major.minor');
  }
  if (doc.major != gen.major) {
    throw SomVersionException(
        'document major version ${doc.major} differs from the object model '
        'major version ${gen.major}; cross-major documents are read-only');
  }
  if (doc.minor > gen.minor) {
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
