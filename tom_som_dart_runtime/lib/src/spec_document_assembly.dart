/// Assembling one spec document from fragments written in parallel.
///
/// A large document is often authored in parts — one group, or one agent, per
/// set of sections — each part a document of its own holding a subset of the
/// sections. References between parts can only be judged on the whole: the
/// instance tier resolves a `refersTo` against the document it is given, so a
/// part validated alone reports every reference into another part as
/// dangling. [SpecDocument.assemble] is the step that produces the whole.
///
/// The merge is over the plain-data stores ([SpecDocument.toJson]), and it is
/// **refusing**: a value two fragments both write — a content path, a form
/// field, a list, a headline, a code-spec location — is an overlap, and an
/// assembly with any overlap yields no document. Choosing a winner would make
/// the result depend on fragment order, and two parts writing one place is an
/// authoring conflict the parts' authors have to settle.
library;

import 'spec_document.dart';

/// One place two or more fragments both write.
class SpecAssemblyOverlap {
  /// The store: `content`, `forms`, `lists`, `headlines` or `codeSpecs`.
  final String store;

  /// The document path.
  final String path;

  /// The form field, for the `forms` store; `null` otherwise.
  final String? field;

  /// The fragments that write it, in the order they were given.
  final List<String> fragments;

  /// Creates an overlap.
  const SpecAssemblyOverlap({
    required this.store,
    required this.path,
    required this.fragments,
    this.field,
  });

  /// One sentence naming the place and every fragment that writes it.
  String get message =>
      '${field == null ? path : '$path field `$field`'} ($store) is written by '
      '${fragments.join(' and ')} — a place two fragments both write is an '
      'authoring conflict, not something the assembly may resolve';

  @override
  String toString() => message;
}

/// The result of [SpecDocument.assemble].
class SpecDocumentAssembly {
  /// The assembled document; `null` when there is any overlap.
  final SpecDocument? document;

  /// Every overlap, in store order and then path order.
  final List<SpecAssemblyOverlap> overlaps;

  /// Creates a result.
  const SpecDocumentAssembly({this.document, this.overlaps = const []});

  /// Whether the fragments assembled.
  bool get ok => overlaps.isEmpty;
}

/// The stores whose entries are a single value at a path.
const List<String> _pathStores = ['content', 'headlines', 'codeSpecs'];

/// The fixed order overlaps are reported in.
const List<String> _storeOrder = [
  'content',
  'forms',
  'lists',
  'headlines',
  'codeSpecs',
];

/// Merges [fragments] — name → document, in order — into one document. See
/// the library comment for the refusing rule.
SpecDocumentAssembly assembleSpecDocuments(
  Map<String, SpecDocument> fragments,
) {
  // store → key → writer fragments; key is the path, or `path\u0000field`.
  final writers = <String, Map<String, List<String>>>{
    for (final s in _storeOrder) s: {},
  };
  final merged = <String, Map<String, Object?>>{
    for (final s in _storeOrder) s: {},
  };

  for (final MapEntry(key: name, value: doc) in fragments.entries) {
    final json = doc.toJson();
    for (final store in _pathStores) {
      final entries = (json[store] as Map?)?.cast<String, Object?>() ?? {};
      for (final MapEntry(key: path, value: value) in entries.entries) {
        (writers[store]![path] ??= []).add(name);
        merged[store]!.putIfAbsent(path, () => value);
      }
    }
    final forms = (json['forms'] as Map?)?.cast<String, Object?>() ?? {};
    for (final MapEntry(key: path, value: fields) in forms.entries) {
      final target =
          merged['forms']!.putIfAbsent(path, () => <String, Object?>{})
              as Map<String, Object?>;
      for (final MapEntry(key: field, value: value)
          in (fields as Map).cast<String, Object?>().entries) {
        (writers['forms']!['$path\u0000$field'] ??= []).add(name);
        target.putIfAbsent(field, () => value);
      }
    }
    final lists = (json['lists'] as Map?)?.cast<String, Object?>() ?? {};
    for (final MapEntry(key: path, value: spec) in lists.entries) {
      (writers['lists']![path] ??= []).add(name);
      merged['lists']!.putIfAbsent(path, () => spec);
    }
  }

  final overlaps = <SpecAssemblyOverlap>[];
  for (final store in _storeOrder) {
    final keys = writers[store]!.keys.toList()..sort();
    for (final key in keys) {
      final who = writers[store]![key]!;
      if (who.length < 2) continue;
      final sep = key.indexOf('\u0000');
      overlaps.add(
        SpecAssemblyOverlap(
          store: store,
          path: sep < 0 ? key : key.substring(0, sep),
          field: sep < 0 ? null : key.substring(sep + 1),
          fragments: who,
        ),
      );
    }
  }
  if (overlaps.isNotEmpty) {
    return SpecDocumentAssembly(overlaps: List.unmodifiable(overlaps));
  }
  final document = SpecDocument()
    ..loadJson({
      for (final store in _storeOrder)
        if (merged[store]!.isNotEmpty) store: merged[store],
    });
  return SpecDocumentAssembly(document: document);
}
