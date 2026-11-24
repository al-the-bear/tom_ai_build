/// Places and filters of the link vocabulary (`tom_specs_model_rules.md` §9.7):
/// the grammar every link annotation names places in, parsed once and resolved
/// under an anchor through [SpecReflection].
///
/// * A **place** names a section, a list, a form field, a heading, a content
///   value or a registry id: `FRED.description`, `FRE.@headline`,
///   `FRE-REQU-LST`, `./RQDEP`, `FRE/REQDEP/RQDEP.description`,
///   `<SECTIONID>.@content`, `<SECTIONID>.@sectionId` ([SpecPlace]).
/// * A **filter** selects entries by one of their form values:
///   `<SECTIONID>`, `./<SECTIONID>`, `<SECTIONID>.<field>=<value>` with `|`
///   between alternatives (`FRE.priority=must|should`)
///   ([SpecPlaceFilter]). `countOf` and every `where:` read it.
///
/// Resolution is value-free, like [SpecReflection]: it says where in a
/// document the place is stored, with every list item below the anchor
/// written `<list>-*`, and never reads a value.
library;

import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';

/// What a resolved place is.
enum SpecPlaceKind {
  /// A section (a class's own node or a complex member), whole.
  section,

  /// A `-LST` list container.
  list,

  /// A form member, every field of it.
  form,

  /// One field of a form.
  formField,

  /// The stored headline of a section (`.@headline`).
  headline,

  /// The content value of a section (`.@content`, or a content member).
  content,

  /// The stored section id of a list element (`.@sectionId`).
  sectionId,
}

/// Why a place or a filter does not parse or does not resolve.
enum SpecPlaceProblem {
  /// The text is not a place (or not a filter) of the grammar.
  malformed,

  /// The anchor path resolves to no section of the model.
  anchorUnresolved,

  /// The place is `./`-scoped, but no list element lies at or above the
  /// anchor.
  notScoped,

  /// No section with the place's id (and `/` path) lies in the scope.
  unresolved,

  /// The place's id is reached at more than one position in the scope; a
  /// `/` path is needed.
  ambiguous,

  /// The named field is no form field of the section.
  noSuchField,

  /// `.@content` names a section that holds no content value.
  noContent,

  /// `.@sectionId` names a section that is no list element.
  notListElement,

  /// A slot starting with `@` other than `@headline`, `@content`,
  /// `@sectionId`.
  reservedSlot,
}

/// A place or filter that does not parse or resolve, with the reason.
class SpecPlaceException implements Exception {
  /// What went wrong; the corpus compares this, never [message].
  final SpecPlaceProblem problem;

  /// The place or filter as written.
  final String text;

  /// Prose for the reader.
  final String message;

  /// All three are known where the exception is raised.
  const SpecPlaceException(this.problem, this.text, this.message);

  @override
  String toString() => 'SpecPlaceException(${problem.name}): "$text" $message';
}

/// A place as written: `./` scope, `/` segments, section id and slot.
class SpecPlace {
  /// The text it was parsed from.
  final String text;

  /// Whether it is written `./…`: resolved beneath the nearest list element
  /// at or above the anchor.
  final bool scoped;

  /// The section ids written before the last `/`, which the path to the
  /// place holds in this order.
  final List<String> prefix;

  /// The section id the place names.
  final String sectionId;

  /// The part after the dot: a form field name, `@headline`, `@content`,
  /// `@sectionId`; `null` for the section, list or form itself.
  final String? slot;

  /// The parts of a parsed place; [parse] builds one from text.
  const SpecPlace({
    required this.text,
    required this.scoped,
    required this.prefix,
    required this.sectionId,
    this.slot,
  });

  static final RegExp _segment = RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]*$');
  static final RegExp _slot = RegExp(r'^@?[A-Za-z_][A-Za-z0-9_]*$');

  /// Parses [text]; throws a [SpecPlaceException] (`malformed`) when it is
  /// not a place.
  static SpecPlace parse(String text) {
    final place = tryParse(text);
    if (place == null) {
      throw SpecPlaceException(
        SpecPlaceProblem.malformed,
        text,
        'is not a place (`<SECTIONID>[.<field>|.@headline|.@content|'
        '.@sectionId]`, optionally `./`-scoped or a `/` path)',
      );
    }
    return place;
  }

  /// Parses [text], or returns `null` when it is not a place.
  static SpecPlace? tryParse(String text) {
    final scoped = text.startsWith('./');
    final body = scoped ? text.substring(2) : text;
    if (body.isEmpty) return null;
    final segments = body.split('/');
    final last = segments.removeLast();
    final dot = last.indexOf('.');
    final id = dot < 0 ? last : last.substring(0, dot);
    final slot = dot < 0 ? null : last.substring(dot + 1);
    if (!_segment.hasMatch(id) || segments.any((s) => !_segment.hasMatch(s))) {
      return null;
    }
    if (slot != null && !_slot.hasMatch(slot)) return null;
    return SpecPlace(
      text: text,
      scoped: scoped,
      prefix: List.unmodifiable(segments),
      sectionId: id,
      slot: slot,
    );
  }

  /// The parsed parts, for the corpus.
  Map<String, Object?> toJson() => {
    'scoped': scoped,
    'prefix': prefix,
    'sectionId': sectionId,
    if (slot != null) 'slot': slot,
  };

  /// Resolves the place under [anchor], a document path of a section (a
  /// root, a complex or section member, or a list item). Throws a
  /// [SpecPlaceException] when it does not resolve.
  ///
  /// The place is looked for in the subtree of the anchor's class — beneath
  /// the nearest list element at or above the anchor when it is `./`-scoped —
  /// among the positions whose section id is [sectionId] and whose path holds
  /// the [prefix] ids in order (only `-LST` containers and the scope's own id
  /// may lie between them). More than one such position is `ambiguous`.
  SpecPlaceResolution resolve(SpecReflection refl, String anchor) {
    final scope = _scopeOf(refl, anchor, scoped: scoped, text: text);
    final candidates = <_Position>[
      for (final p in _positions(refl, scope))
        if (p.node.id == sectionId &&
            _pathMatches(p.ids.sublist(0, p.ids.length - 1), prefix))
          p,
    ];
    if (candidates.isEmpty) {
      throw SpecPlaceException(
        SpecPlaceProblem.unresolved,
        text,
        'resolves to no section beneath ${scope.path}',
      );
    }
    final byPath = <String, _Position>{
      for (final p in candidates) p.node.path: p,
    };
    if (byPath.length > 1) {
      throw SpecPlaceException(
        SpecPlaceProblem.ambiguous,
        text,
        'is ambiguous: $sectionId is reached at '
        '${(byPath.keys.toList()..sort()).join(', ')} — write it as a `/` path',
      );
    }
    return _withSlot(byPath.values.single);
  }

  SpecPlaceResolution _withSlot(_Position p) {
    final n = p.node;
    SpecPlaceResolution result(
      SpecPlaceKind kind,
      String path, [
      FormFieldSpec? field,
    ]) => SpecPlaceResolution(
      place: this,
      kind: kind,
      path: path,
      formField: field,
      className: n.className,
      sectionIds: p.ids,
    );

    final slot = this.slot;
    if (slot == null) {
      return switch (n.shape) {
        _Shape.list => result(SpecPlaceKind.list, n.path),
        _Shape.form => result(SpecPlaceKind.form, n.path),
        _Shape.content => result(SpecPlaceKind.content, n.path),
        _Shape.section => result(SpecPlaceKind.section, n.path),
      };
    }
    if (slot == '@headline') return result(SpecPlaceKind.headline, n.path);
    if (slot == '@content') {
      final path = n.contentPath;
      if (path == null) {
        throw SpecPlaceException(
          SpecPlaceProblem.noContent,
          text,
          'names @content of $sectionId, which holds no content value',
        );
      }
      return result(SpecPlaceKind.content, path);
    }
    if (slot == '@sectionId') {
      if (!n.isListElement) {
        throw SpecPlaceException(
          SpecPlaceProblem.notListElement,
          text,
          'names @sectionId of $sectionId, which is no list element',
        );
      }
      return result(SpecPlaceKind.sectionId, n.path);
    }
    if (slot.startsWith('@')) {
      throw SpecPlaceException(
        SpecPlaceProblem.reservedSlot,
        text,
        'names the slot $slot — "@" is reserved for @headline, @content and '
        '@sectionId',
      );
    }
    final field = n.formFields.where((f) => f.name == slot).firstOrNull;
    if (field == null || n.formPath == null) {
      throw SpecPlaceException(
        SpecPlaceProblem.noSuchField,
        text,
        'names $sectionId.$slot, which is no form field',
      );
    }
    return result(SpecPlaceKind.formField, n.formPath!, field);
  }

  @override
  String toString() => text;
}

/// Where a place is stored in a document.
class SpecPlaceResolution {
  /// The place resolved.
  final SpecPlace place;

  /// What the place is.
  final SpecPlaceKind kind;

  /// The document path the value lives at, with every list item beneath the
  /// anchor written `<list>-*`: the section (or list item) for a section, a
  /// headline or a section id; the list for a list; the form for a form or a
  /// form field; the content leaf for a content value.
  final String path;

  /// For [SpecPlaceKind.formField], the field.
  final FormFieldSpec? formField;

  /// The class of the section the place sits on (for a member, its owner).
  final String className;

  /// The section ids on the way from the scope to the place, the place's own
  /// last.
  final List<String> sectionIds;

  /// The parts of a resolution; [SpecPlace.resolve] builds one.
  const SpecPlaceResolution({
    required this.place,
    required this.kind,
    required this.path,
    required this.className,
    required this.sectionIds,
    this.formField,
  });

  /// The form field name for [SpecPlaceKind.formField], else `null`.
  String? get field => formField?.name;

  /// The canonical JSON form the corpus compares.
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'path': path,
    if (field != null) 'field': field,
  };
}

/// An entry filter: `<SECTIONID>`, `./<SECTIONID>` or
/// `<SECTIONID>.<field>=<value>[|<value>…]`, optionally `./`-scoped.
///
/// It selects the entries (list elements of the class with that section id)
/// one of whose own forms holds one of [values] in [field]; without a field
/// every entry. `countOf` counts the entries it selects, a `where:` keeps the
/// elements or rows it selects.
class SpecPlaceFilter {
  /// The text it was parsed from.
  final String text;

  /// Whether it is written `./…`: only the entries beneath the nearest list
  /// element (for `countOf`: beneath the section holding the form).
  final bool scoped;

  /// The section id of the entries.
  final String sectionId;

  /// The form field compared, or `null` for every entry.
  final String? field;

  /// The values accepted, in written order; empty exactly when [field] is
  /// `null`.
  final List<String> values;

  /// The parts of a parsed filter; [parse] builds one from text.
  const SpecPlaceFilter({
    required this.text,
    required this.scoped,
    required this.sectionId,
    this.field,
    this.values = const [],
  });

  static final RegExp _id = RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]*$');
  static final RegExp _field = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  /// Parses [text]; throws a [SpecPlaceException] (`malformed`) when it is
  /// not a filter.
  static SpecPlaceFilter parse(String text) {
    final filter = tryParse(text);
    if (filter == null) {
      throw SpecPlaceException(
        SpecPlaceProblem.malformed,
        text,
        'is not a filter (`<SECTIONID>[.<field>=<value>[|<value>…]]`, '
        'optionally `./`-scoped)',
      );
    }
    return filter;
  }

  /// Parses [text], or returns `null` when it is not a filter.
  static SpecPlaceFilter? tryParse(String text) {
    final scoped = text.startsWith('./');
    final body = scoped ? text.substring(2) : text;
    final dot = body.indexOf('.');
    final id = dot < 0 ? body : body.substring(0, dot);
    if (!_id.hasMatch(id)) return null;
    if (dot < 0) {
      return SpecPlaceFilter(text: text, scoped: scoped, sectionId: id);
    }
    final eq = body.indexOf('=', dot);
    if (eq < 0) return null;
    final field = body.substring(dot + 1, eq);
    if (!_field.hasMatch(field)) return null;
    final values = body.substring(eq + 1).split('|');
    if (values.any((v) => v.isEmpty)) return null;
    return SpecPlaceFilter(
      text: text,
      scoped: scoped,
      sectionId: id,
      field: field,
      values: List.unmodifiable(values),
    );
  }

  /// Whether an entry whose [field] holds [stored] (trimmed values, as many
  /// as its forms hold) is selected.
  bool matches(Iterable<String> stored) {
    if (field == null) return true;
    for (final v in stored) {
      if (values.contains(v.trim())) return true;
    }
    return false;
  }

  /// The place of the entries: [sectionId], scoped as the filter is.
  SpecPlace get place => SpecPlace(
    text: scoped ? './$sectionId' : sectionId,
    scoped: scoped,
    prefix: const [],
    sectionId: sectionId,
  );

  /// Resolves the entries under [anchor] as [SpecPlace.resolve] does, and
  /// checks that [field] is a field of one of the entry's own forms (a form
  /// member of the entry, or its content form). Throws a [SpecPlaceException]
  /// when it does not resolve.
  SpecPlaceResolution resolve(SpecReflection refl, String anchor) {
    final SpecPlaceResolution r;
    try {
      r = place.resolve(refl, anchor);
    } on SpecPlaceException catch (e) {
      throw SpecPlaceException(e.problem, text, e.message);
    }
    final field = this.field;
    if (field != null) {
      final cls = refl.classNamed(r.className);
      final own = r.kind == SpecPlaceKind.section && cls != null
          ? [
              for (final f in cls.fields)
                if (f.kind == SpecFieldKind.form) ...f.formFields,
            ]
          : const <FormFieldSpec>[];
      if (!own.any((f) => f.name == field)) {
        throw SpecPlaceException(
          SpecPlaceProblem.noSuchField,
          text,
          'names $sectionId.$field, which no form of $sectionId holds',
        );
      }
    }
    return r;
  }

  /// The parsed parts, for the corpus.
  Map<String, Object?> toJson() => {
    'scoped': scoped,
    'sectionId': sectionId,
    if (field != null) 'field': field,
    if (field != null) 'values': values,
  };

  @override
  String toString() => text;
}

/// A `@SameAs` copy at one position of a document root, with its holder.
class SpecSameAsBinding {
  /// The root the positions are in.
  final String root;

  /// The class both positions hold.
  final String className;

  /// The copy's document path (list items written `<list>-*`).
  final String copyPath;

  /// The copy's section-id path from the root.
  final List<String> copySectionIds;

  /// The holder's document path, or `null` when [problem] is set.
  final String? holderPath;

  /// The holder's section-id path from the root, or `null`.
  final List<String>? holderSectionIds;

  /// Why no single holder was found: `unresolved` (no position fits) or
  /// `ambiguous` (several do); `null` when [holderPath] is set.
  final SpecPlaceProblem? problem;

  /// The parts of a binding; [specSameAsBindings] builds them.
  const SpecSameAsBinding({
    required this.root,
    required this.className,
    required this.copyPath,
    required this.copySectionIds,
    this.holderPath,
    this.holderSectionIds,
    this.problem,
  });

  /// The canonical JSON form the corpus compares.
  Map<String, Object?> toJson() => {
    'root': root,
    'className': className,
    'copy': copyPath,
    if (holderPath != null) 'holder': holderPath,
    if (problem != null) 'problem': problem!.name,
  };
}

/// Every `@SameAs` copy the document root [rootType] reaches, each with its
/// holder (`tom_specs_model_rules.md` §9.7, invariant `SAME-AS`): among the
/// positions of the copy's class in the root that are no copy themselves, the
/// one whose section-id path ends with `holder`, or — without `holder` — the
/// one there is. In position order.
List<SpecSameAsBinding> specSameAsBindings(
  SpecReflection refl,
  String rootType,
) {
  final root = refl.model.roots.where((r) => r.type == rootType).firstOrNull;
  final cls = refl.classNamed(rootType);
  if (root == null || cls == null) return const [];
  final scope = _Scope(refl.rootSegment(root), cls, false);
  final sections = [
    for (final p in _positions(refl, scope))
      if (p.node.shape == _Shape.section && p.node.ownNode) p,
  ];
  final out = <SpecSameAsBinding>[];
  for (final copy in sections) {
    final sameAs = copy.member?.sameAs;
    if (sameAs == null) continue;
    final type = copy.node.className;
    final holders = [
      for (final p in sections)
        if (p.node.className == type &&
            p.member?.sameAs == null &&
            (sameAs.holder == null ||
                _endsWith(p.ids, sameAs.holder!.split('/'))))
          p,
    ];
    out.add(
      SpecSameAsBinding(
        root: rootType,
        className: type,
        copyPath: copy.node.path,
        copySectionIds: copy.ids,
        holderPath: holders.length == 1 ? holders.single.node.path : null,
        holderSectionIds: holders.length == 1 ? holders.single.ids : null,
        problem: holders.isEmpty
            ? SpecPlaceProblem.unresolved
            : holders.length > 1
            ? SpecPlaceProblem.ambiguous
            : null,
      ),
    );
  }
  return out;
}

/// One position of a section in a document root: a class reached there (its
/// own node), or a member of a class that carries a section id of its own.
class SpecSectionPosition {
  /// The document path, list items written `<list>-*`.
  final String path;

  /// The class reached ([member] null), or the class the member belongs to.
  final String className;

  /// The section ids from the root to here, this position's own last.
  final List<String> sectionIds;

  /// For a class position, the member it is reached through (null at the
  /// root); for a member position, the member itself.
  final SpecField? member;

  /// Whether this is a member position (a form, list, content or section
  /// member with its own section id) rather than a class reached.
  final bool isMember;

  /// The parts of a position; [specSectionPositions] builds them.
  const SpecSectionPosition({
    required this.path,
    required this.className,
    required this.sectionIds,
    required this.isMember,
    this.member,
  });
}

/// Every section position of the document root [rootType], in walk order: a
/// class reached again on its own path is not descended into, and a
/// `@Reference` member's target is not walked.
List<SpecSectionPosition> specSectionPositions(
  SpecReflection refl,
  String rootType,
) {
  final root = refl.model.roots.where((r) => r.type == rootType).firstOrNull;
  final cls = refl.classNamed(rootType);
  if (root == null || cls == null) return const [];
  return [
    for (final p in _positions(
      refl,
      _Scope(refl.rootSegment(root), cls, false),
    ))
      SpecSectionPosition(
        path: p.node.path,
        className: p.node.className,
        sectionIds: p.ids,
        member: p.member,
        isMember: !p.node.ownNode,
      ),
  ];
}

// ---------------------------------------------------------------------------
// The positions of a subtree
// ---------------------------------------------------------------------------

enum _Shape { section, list, form, content }

/// An addressable section at one position.
class _Node {
  _Node({
    required this.id,
    required this.path,
    required this.className,
    required this.shape,
    required this.ownNode,
    this.formFields = const [],
    this.formPath,
    this.contentPath,
    this.isListElement = false,
  });

  final String id;
  final String path;
  final String className;
  final _Shape shape;

  /// Whether this is a class's own node (a section reached at [path]), as
  /// against a member of the class.
  final bool ownNode;
  final List<FormFieldSpec> formFields;
  final String? formPath;
  final String? contentPath;
  final bool isListElement;
}

/// A node with the section ids on the way to it, and the member that holds
/// it (for a class's own node, the member it is reached through).
class _Position {
  _Position(this.node, this.ids, this.member);
  final _Node node;
  final List<String> ids;
  final SpecField? member;
}

/// Where a resolution walks from.
class _Scope {
  _Scope(this.path, this.cls, this.isListElement);
  final String path;
  final SpecClass cls;
  final bool isListElement;
}

_Scope _scopeOf(
  SpecReflection refl,
  String anchor, {
  required bool scoped,
  required String text,
}) {
  final segs = specPathSegments(anchor);
  for (var n = segs.length; n >= 1; n--) {
    final path = segs.sublist(0, n).join('/');
    final r = refl.resolve(path);
    if (n == segs.length && (r == null || r.targetClass == null)) {
      throw SpecPlaceException(
        SpecPlaceProblem.anchorUnresolved,
        text,
        'has the anchor $anchor, which resolves to no section',
      );
    }
    final isItem = r?.kind == SpecNodeKind.listItemComplex;
    if (!scoped || isItem) {
      return _Scope(path, r!.targetClass!, isItem);
    }
  }
  throw SpecPlaceException(
    SpecPlaceProblem.notScoped,
    text,
    'is `./`-scoped, but no list element lies at or above $anchor',
  );
}

/// Every addressable position beneath (and including) [scope], in model
/// order. A class reached again on its own path is not descended into, and a
/// `@Reference` member is a place whose target is not walked.
List<_Position> _positions(SpecReflection refl, _Scope scope) {
  final out = <_Position>[];

  void walk(
    SpecClass cls,
    String path,
    List<String> ids,
    bool isItem,
    SpecField? via,
    Set<String> onPath,
  ) {
    if (!onPath.add(cls.name)) return;
    final content = cls.fields.where((f) => f.name == 'content').firstOrNull;
    var here = ids;
    final ownId = cls.sectionId;
    if (ownId != null && ownId.isNotEmpty) {
      here = [...ids, ownId];
      final contentSeg = content == null ? null : refl.fieldSegment(content);
      out.add(
        _Position(
          _Node(
            id: ownId,
            path: path,
            className: cls.name,
            shape: _Shape.section,
            ownNode: true,
            formFields: content?.kind == SpecFieldKind.form
                ? content!.formFields
                : const [],
            formPath: content?.kind == SpecFieldKind.form
                ? '$path/$contentSeg'
                : null,
            contentPath: content?.kind == SpecFieldKind.content
                ? '$path/$contentSeg'
                : null,
            isListElement: isItem,
          ),
          here,
          via,
        ),
      );
    }
    for (final field in cls.fields) {
      final seg = refl.fieldSegment(field);
      final memberPath = '$path/$seg';
      final sid = field.sectionId;
      var below = here;
      if (field.name != 'content' && sid != null && sid.isNotEmpty) {
        below = [...here, sid];
        final shape = switch (field.kind) {
          SpecFieldKind.list => _Shape.list,
          SpecFieldKind.form => _Shape.form,
          SpecFieldKind.complex || SpecFieldKind.section => _Shape.section,
          _ => _Shape.content,
        };
        out.add(
          _Position(
            _Node(
              id: sid,
              path: memberPath,
              className: cls.name,
              shape: shape,
              ownNode: false,
              formFields: field.kind == SpecFieldKind.form
                  ? field.formFields
                  : const [],
              formPath: field.kind == SpecFieldKind.form ? memberPath : null,
              contentPath: shape == _Shape.content ? memberPath : null,
            ),
            below,
            field,
          ),
        );
      }
      if (field.hasAnnotation('Reference')) continue;
      if (field.kind == SpecFieldKind.list && field.elementIsComplex) {
        final el = refl.classNamed(field.elementType);
        if (el != null) {
          walk(el, '$memberPath-*', below, true, field, onPath);
        }
      } else if (field.kind == SpecFieldKind.complex ||
          field.kind == SpecFieldKind.section) {
        final child = refl.classNamed(field.type?.replaceAll('?', ''));
        if (child != null) walk(child, memberPath, below, false, field, onPath);
      }
    }
    onPath.remove(cls.name);
  }

  walk(scope.cls, scope.path, const [], scope.isListElement, null, {});
  return out;
}

/// Whether the `/` [segments] lead to a position whose ancestors are [path]:
/// they name every section on the way, leaving out only `-LST` containers
/// and the scope's own id. No segments: any position.
bool _pathMatches(List<String> path, List<String> segments) {
  if (segments.isEmpty) return true;
  bool from(int start) {
    var j = 0;
    for (var i = start; i < path.length; i++) {
      if (j < segments.length && path[i] == segments[j]) {
        j++;
      } else if (!path[i].endsWith('-LST')) {
        return false;
      }
    }
    return j == segments.length;
  }

  return from(0) || (path.isNotEmpty && from(1));
}

/// Whether [path] ends with exactly the ids of [tail], as the static
/// validator's `SAME-AS` reads a holder.
bool _endsWith(List<String> path, List<String> tail) {
  if (path.length < tail.length) return false;
  for (var i = 0; i < tail.length; i++) {
    if (path[path.length - tail.length + i] != tail[i]) return false;
  }
  return true;
}
