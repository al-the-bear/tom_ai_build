/// The static invariants of the link vocabulary (`tom_specs_model_rules.md`
/// §9.7 and §10.2): `@SyncedWith`, `@SummaryOf`, `@DerivedFrom`,
/// `InverseOf` and `@ExtractsLinks` name *places* in the model, and these
/// checks hold every place to something that exists, is unambiguous and fits
/// the link it takes part in.
///
/// `validator.dart` runs one step per invariant (`SYNC-PLACE`, `SYNC-ANCHOR`,
/// `SHARED-COVER`, `SHARED-ONE-HOLDER`, `SHARED-ANCHOR`, `SUMMARY-LINK`,
/// `DERIVE-SOURCE`, `DERIVE-ACYCLIC`, `INVERSE-PAIR`, `EXTRACT-LINK`); this
/// library holds the place resolver they share and the checks themselves.
library;

import 'model_reader.dart';

/// The document section every message cites, as in `validator.dart`.
const String _invariants = 'tom_specs_model_rules.md §10.2';

/// The checks of the link vocabulary over one model.
///
/// Built once per validation run; every check reads the same section index,
/// subtree cache and derivation analysis, and appends its findings to the
/// lists it is given.
class LinkInvariants {
  /// Indexes [classes]; [documentClasses] are the `@Document` roots and
  /// [reachableFrom] the validator's own reachability walk, so the two agree
  /// on what a root reaches.
  LinkInvariants(this.classes, this.documentClasses, this.reachableFrom) {
    _index();
  }

  /// The model's classes by name.
  final Map<String, ModelClass> classes;

  /// The names of the `@Document` root classes.
  final Set<String> documentClasses;

  /// The classes a root reaches through complex and list members.
  final Set<String> Function(String root) reachableFrom;

  // -------------------------------------------------------------------------
  // The section index
  // -------------------------------------------------------------------------

  /// Class-level section id per class.
  final Map<String, String> _classId = {};

  /// Every addressable section of each class: its own node (when it carries
  /// a class-level `@SectionId`) and one per member with a field-level id.
  final Map<String, List<_Node>> _nodesOf = {};

  /// Every node by section id, across the model.
  final Map<String, List<_Node>> _nodesById = {};

  /// Classes that are the element type of a complex list.
  final Set<String> _listElements = {};

  /// Owned (non-`@Reference`) parent classes of each class.
  final Map<String, Set<String>> _parents = {};

  void _index() {
    for (final cls in classes.values) {
      final id = cls.getAnnotation('SectionId')?.arguments['id'];
      if (id is String && id.isNotEmpty) _classId[cls.name] = id;
    }
    for (final cls in classes.values) {
      final nodes = <_Node>[];
      final ownId = _classId[cls.name];
      final contentField = cls.fields
          .where((f) => f.name == 'content')
          .firstOrNull;
      if (ownId != null) {
        nodes.add(
          _Node(
            id: ownId,
            owner: cls.name,
            type: cls.name,
            form: [...cls.formFields, ...?contentField?.formFields],
            hasContent: contentField != null,
          ),
        );
      }
      for (final field in cls.fields) {
        // A `@Reference` member stores its target's id in its own form: the
        // member is a place of this class (`RQDEP-RELA-REF.ref`), but its
        // target is never followed (tom_specs_model_rules.md §9.2), so it adds no
        // child.
        final isReference = field.getAnnotation('Reference') != null;
        String? child;
        if (isReference) {
          // no child: the reference is not traversed
        } else if (field.isList && field.listElementIsComplex) {
          child = field.listElementTypeName;
          if (child != null) _listElements.add(child);
        } else if (field.isComplex) {
          child = field.typeName.replaceAll('?', '');
        }
        if (child != null) (_parents[child] ??= {}).add(cls.name);

        if (field.name == 'content') continue;
        final sid = field.getAnnotation('SectionId')?.arguments['id'];
        if (sid is! String || sid.isEmpty) continue;
        if (field.isList) {
          nodes.add(
            _Node(
              id: sid,
              owner: cls.name,
              member: field.name,
              isList: true,
              elementType: field.listElementIsComplex
                  ? field.listElementTypeName
                  : null,
            ),
          );
        } else if (field.isComplex) {
          nodes.add(
            _Node(
              id: sid,
              owner: cls.name,
              member: field.name,
              type: field.typeName.replaceAll('?', ''),
            ),
          );
        } else {
          nodes.add(
            _Node(
              id: sid,
              owner: cls.name,
              member: field.name,
              form: field.formFields,
              hasContent: field.isContentLike,
            ),
          );
        }
      }
      _nodesOf[cls.name] = nodes;
      for (final n in nodes) {
        (_nodesById[n.id] ??= []).add(n);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Subtrees, reach, nearest list elements
  // -------------------------------------------------------------------------

  final Map<String, List<_Occ>> _subtreeCache = {};

  /// Every addressable position beneath (and including) [root], each with
  /// the section ids on the way to it.
  List<_Occ> _subtree(String root) => _subtreeCache.putIfAbsent(root, () {
    final out = <_Occ>[];
    void walk(String className, List<String> path, Set<String> onPath) {
      final cls = classes[className];
      if (cls == null || !onPath.add(className)) return;
      final own = _nodesOf[className]!.where((n) => n.member == null);
      var here = path;
      for (final n in own) {
        here = [...path, n.id];
        out.add(_Occ(n, here));
      }
      for (final field in cls.fields) {
        final member = _nodesOf[className]!
            .where((n) => n.member == field.name)
            .firstOrNull;
        var below = here;
        if (member != null) {
          below = [...here, member.id];
          out.add(_Occ(member, below));
        }
        // A `@Reference` member is a place; its target is not walked.
        if (field.getAnnotation('Reference') != null) continue;
        if (field.isList && field.listElementIsComplex) {
          final el = field.listElementTypeName;
          if (el != null) walk(el, below, onPath);
        } else if (field.isComplex) {
          walk(field.typeName.replaceAll('?', ''), below, onPath);
        }
      }
      onPath.remove(className);
    }

    walk(root, const [], {});
    return out;
  });

  final Map<String, Set<String>> _reachCache = {};

  /// The classes [root] reaches, itself included.
  Set<String> _reach(String root) =>
      _reachCache.putIfAbsent(root, () => reachableFrom(root));

  /// The `@Document` roots that reach [className].
  List<String> _rootsReaching(String className) => [
    for (final r in documentClasses.toList()..sort())
      if (_reach(r).contains(className)) r,
  ];

  /// Whether one `@Document` root reaches both classes.
  bool _coReachable(String a, String b) => documentClasses.any(
    (r) => _reach(r).contains(a) && _reach(r).contains(b),
  );

  /// The list elements nearest above [className], itself when it is one: the
  /// scope a `./` place resolves in.
  Set<String> _nearestListElements(String className) {
    if (_listElements.contains(className)) return {className};
    final out = <String>{};
    final seen = <String>{className};
    final queue = [...?_parents[className]];
    while (queue.isNotEmpty) {
      final c = queue.removeLast();
      if (!seen.add(c)) continue;
      if (_listElements.contains(c)) {
        out.add(c);
      } else {
        queue.addAll(_parents[c] ?? const {});
      }
    }
    return out;
  }

  // -------------------------------------------------------------------------
  // Place resolution
  // -------------------------------------------------------------------------

  /// Resolves [place] among [occs]: the positions whose node carries the
  /// place's section id, whose path holds the `/` segments in order, and
  /// whose node has the slot.
  _Resolution _resolveIn(String place, List<_Occ> occs) {
    final parsed = _ParsedPlace.parse(place);
    if (parsed == null) {
      return _Resolution.error(
        'is not a place (`<SECTIONID>[.<field>|.@headline|.@content|'
        '.@sectionId]`, optionally `./`-scoped or a `/` path)',
      );
    }
    final candidates = <_Occ>[
      for (final o in occs)
        if (o.node.id == parsed.id &&
            _pathMatches(o.path.sublist(0, o.path.length - 1), parsed.prefix))
          o,
    ];
    if (candidates.isEmpty) {
      return _Resolution.error('resolves to no section in its scope');
    }
    final byPath = <String, _Occ>{
      for (final o in candidates) o.path.join('/'): o,
    };
    if (byPath.length > 1) {
      return _Resolution.error(
        'is ambiguous: ${parsed.id} is reached at '
        '${(byPath.keys.toList()..sort()).join(', ')} — write it as a `/` path',
      );
    }
    final occ = byPath.values.single;
    return _withSlot(occ.node, parsed.slot, occ.path);
  }

  /// Resolves [place] by section id across the whole model, for places that
  /// are not scoped to a subtree. Several declarations of one id are one
  /// place when they are alike (a shared `-LST` container).
  _Resolution _resolveGlobal(String place, {String? withinRoot}) {
    final parsed = _ParsedPlace.parse(place);
    if (parsed == null || parsed.prefix.isNotEmpty) {
      return _Resolution.error(
        'is not a place (`<SECTIONID>[.<field>|.@headline|.@content|'
        '.@sectionId]`)',
      );
    }
    var nodes = _nodesById[parsed.id] ?? const <_Node>[];
    if (withinRoot != null) {
      final reach = _reach(withinRoot);
      nodes = [
        for (final n in nodes)
          if (reach.contains(n.owner)) n,
      ];
    }
    if (nodes.isEmpty) {
      return _Resolution.error(
        withinRoot == null
            ? 'names section ${parsed.id}, which no class declares'
            : 'names section ${parsed.id}, which $withinRoot does not reach',
      );
    }
    final defs = {for (final n in nodes) n.definition: n};
    if (defs.length > 1) {
      return _Resolution.error(
        'is ambiguous: section ${parsed.id} is declared by '
        '${(nodes.map((n) => n.key).toSet().toList()..sort()).join(', ')}',
      );
    }
    return _withSlot(defs.values.first, parsed.slot, [parsed.id]);
  }

  /// Resolves a `./` place beneath the list elements nearest above [owner],
  /// any other place among [occs].
  _Resolution _resolveScoped(String place, String owner, List<_Occ> occs) {
    if (!place.startsWith('./')) return _resolveIn(place, occs);
    final scopes = _nearestListElements(owner).toList()..sort();
    if (scopes.isEmpty) {
      return _Resolution.error(
        'is `./`-scoped, but $owner lies beneath no list element',
      );
    }
    _Resolution? first;
    for (final scope in scopes) {
      final r = _resolveIn(place, _subtree(scope));
      if (r.ok) return r;
      first ??= r;
    }
    return first!;
  }

  _Resolution _withSlot(_Node node, String? slot, List<String> path) {
    if (slot == null) return _Resolution(node, null, null, path);
    if (slot == '@headline') return _Resolution(node, slot, null, path);
    if (slot == '@content') {
      return node.hasContent
          ? _Resolution(node, slot, null, path)
          : _Resolution.error('names @content of ${node.id}, which has none');
    }
    if (slot == '@sectionId') {
      return node.member == null && _listElements.contains(node.owner)
          ? _Resolution(node, slot, null, path)
          : _Resolution.error(
              'names @sectionId of ${node.id}, which is no list element',
            );
    }
    if (slot.startsWith('@')) {
      return _Resolution.error(
        'names the slot $slot — "@" is reserved for @headline, @content and '
        '@sectionId',
      );
    }
    final field = node.form.where((f) => f.name == slot).firstOrNull;
    if (field == null) {
      return _Resolution.error(
        'names ${node.id}.$slot, which is no form field',
      );
    }
    return _Resolution(node, slot, field, path);
  }

  /// Whether a `/` path's [segments] lead to a position whose ancestors are
  /// [path]: the segments name every section on the way, leaving out only the
  /// scope's own root and `-LST` containers (`FRE/REQDEP/RQDEP.description`
  /// passes `RQDEP-ITEM-LST`). No segments: any position.
  static bool _pathMatches(List<String> path, List<String> segments) {
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

  static bool _holdsInOrder(List<String> path, List<String> segments) {
    var i = 0;
    for (final p in path) {
      if (i < segments.length && p == segments[i]) i++;
    }
    return i == segments.length;
  }

  /// The type a value place holds, null for a whole section or list.
  static String? _valueType(_Resolution r) {
    if (r.field != null) return r.field!.typeName.replaceAll('?', '');
    if (r.slot != null) return 'String';
    return null;
  }

  static bool _isText(_Resolution r) => _valueType(r) == 'String';

  static bool _isReference(_Resolution r) =>
      r.slot == '@sectionId' || (r.field?.refersTo.isNotEmpty ?? false);

  /// Whether [refersTo] names the entry class [entryClass].
  bool _namesClass(List<String> refersTo, String entryClass) {
    final id = _classId[entryClass];
    return id != null && refersTo.any((t) => t.split('.').first == id);
  }

  /// The entry classes of a form on [className]: the list elements nearest
  /// above it, itself when it is one. A form on a section below its entry
  /// (`RT-TRAC` under a requirement) belongs to that entry, which is what the
  /// other end of a link names.
  Set<String> _entryClasses(String className) {
    final near = _nearestListElements(className);
    return near.isEmpty ? {className} : near;
  }

  /// Every list element [className] lies beneath, itself included: a link
  /// row (`RQDEP`) belongs to the entry that holds its list (the requirement),
  /// which is what a symmetric link's ids name.
  Set<String> _enclosingEntries(String className) {
    final out = <String>{};
    final queue = [className];
    while (queue.isNotEmpty) {
      final c = queue.removeLast();
      for (final e in _nearestListElements(c)) {
        if (out.add(e)) queue.addAll(_parents[e] ?? const {});
      }
    }
    return out.isEmpty ? {className} : out;
  }

  bool _namesAny(List<String> refersTo, Set<String> classes) =>
      classes.any((c) => _namesClass(refersTo, c));

  /// Checks a filter `<place>=<value>[|<value>…]` against [occs]; returns the
  /// problem or null.
  String? _checkFilter(String filter, List<_Occ> occs) {
    final eq = filter.indexOf('=');
    if (eq <= 0 || eq == filter.length - 1) {
      return 'filter "$filter" is not `<SECTIONID>.<field>=<value>[|<value>…]`';
    }
    final r = _resolveIn(filter.substring(0, eq), occs);
    if (!r.ok) return 'filter "$filter" ${r.problem}';
    final field = r.field;
    if (field == null) {
      return 'filter "$filter" names no form field';
    }
    for (final v in filter.substring(eq + 1).split('|')) {
      if (field.enumValues.isNotEmpty && !field.enumValues.contains(v)) {
        return 'filter "$filter" names "$v", which is not a constant of '
            '${field.typeName} (${field.enumValues.join(', ')})';
      }
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Sites
  // -------------------------------------------------------------------------

  List<ModelClass> get _sorted =>
      classes.values.toList()..sort((a, b) => a.name.compareTo(b.name));

  /// Every form of every class, with its node and owner.
  Iterable<({ModelClass cls, _Node node, FormFieldInfo field})>
  get _formFields sync* {
    for (final cls in _sorted) {
      for (final node in _nodesOf[cls.name]!) {
        for (final ff in node.form) {
          yield (cls: cls, node: node, field: ff);
        }
      }
    }
  }

  /// The `@SyncedWith` sites: on a class, or on a member of it.
  Iterable<({ModelClass cls, ModelField? member, AnnotationData anno})>
  get _syncSites sync* {
    for (final cls in _sorted) {
      for (final a in cls.annotations) {
        if (a.name == 'SyncedWith') yield (cls: cls, member: null, anno: a);
      }
      for (final f in cls.fields) {
        for (final a in f.annotations) {
          if (a.name == 'SyncedWith') yield (cls: cls, member: f, anno: a);
        }
      }
    }
  }

  Iterable<({ModelClass cls, ModelField member, AnnotationData anno})>
  _memberSites(String annotation) sync* {
    for (final cls in _sorted) {
      for (final f in cls.fields) {
        for (final a in f.annotations) {
          if (a.name == annotation) yield (cls: cls, member: f, anno: a);
        }
      }
    }
  }

  /// The positions a `@SyncedWith` covers: the class's subtree, or the
  /// member's own section and what lies beneath it.
  List<_Occ> _syncScope(ModelClass cls, ModelField? member) {
    final all = _subtree(cls.name);
    if (member == null) return all;
    final own = all
        .where((o) => o.node.owner == cls.name && o.node.member == member.name)
        .fold<_Occ?>(
          null,
          (best, o) =>
              best == null || o.path.length < best.path.length ? o : best,
        );
    if (own == null) return const [];
    return [
      for (final o in all)
        if (o.path.length >= own.path.length &&
            _holdsInOrder(o.path.sublist(0, own.path.length), own.path))
          o,
    ];
  }

  static List<String> _strings(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  static String _bare(Object? v) =>
      v is String ? v.substring(v.lastIndexOf('.') + 1) : '';

  static String _site(ModelClass cls, ModelField? member) =>
      member == null ? cls.name : '${cls.name}.${member.name}';

  // -------------------------------------------------------------------------
  // SYNC-PLACE
  // -------------------------------------------------------------------------

  /// Invariant `SYNC-PLACE`: every place of a `@SyncedWith` resolves,
  /// unambiguously, in the annotated section's subtree; a relation other than
  /// `equal` stands on a list or a multi-valued reference field, and its
  /// `where` names a field of the list's element class; a place is named once.
  void checkSyncPlaces(List<String> errors) {
    for (final site in _syncSites) {
      final where = _site(site.cls, site.member);
      final scope = _syncScope(site.cls, site.member);
      final seen = <String>{};
      void place(String p, String arg, {String? relation, String? filter}) {
        if (!seen.add(p)) {
          errors.add(
            '$_invariants SYNC-PLACE: @SyncedWith on $where names "$p" twice — '
            'a place is named once per @SyncedWith',
          );
          return;
        }
        final r = _resolveIn(p, scope);
        if (!r.ok) {
          errors.add(
            '$_invariants SYNC-PLACE: @SyncedWith on $where names "$p" in '
            '$arg, which ${r.problem}',
          );
          return;
        }
        if (r.slot == '@sectionId') {
          errors.add(
            '$_invariants SYNC-PLACE: @SyncedWith on $where names "$p" — a '
            'section id is never synced, it is how elements are matched',
          );
          return;
        }
        final isList = r.node.isList && r.slot == null;
        final isMultiRef =
            r.field != null &&
            r.field!.multiple &&
            r.field!.refersTo.isNotEmpty;
        if (relation != null && relation != 'equal' && !isList && !isMultiRef) {
          errors.add(
            '$_invariants SYNC-PLACE: @SyncedWith on $where relates "$p" as '
            '$relation — a relation other than equal stands only on a list or '
            'a multiple reference field',
          );
          return;
        }
        if (filter != null) {
          List<_Occ> elementScope;
          if (isList && r.node.elementType != null) {
            elementScope = _subtree(r.node.elementType!);
          } else if (isMultiRef) {
            elementScope = [
              for (final t in r.field!.refersTo)
                for (final n
                    in _nodesById[t.split('.').first] ?? const <_Node>[])
                  ..._subtree(n.owner),
            ];
          } else {
            errors.add(
              '$_invariants SYNC-PLACE: @SyncedWith on $where filters "$p", '
              'which is no list of sections nor a multiple reference field',
            );
            return;
          }
          final problem = _checkFilter(filter, elementScope);
          if (problem != null) {
            errors.add(
              '$_invariants SYNC-PLACE: @SyncedWith on $where relates "$p": '
              '$problem of its elements',
            );
          }
        }
      }

      for (final p in _strings(site.anno.arguments['detailOnly'])) {
        place(p, 'detailOnly');
      }
      for (final p in _strings(site.anno.arguments['heldHere'])) {
        place(p, 'heldHere');
      }
      final relations = site.anno.arguments['relations'];
      if (relations is List) {
        for (final rel in relations.whereType<Map>()) {
          final p = rel['place'];
          if (p is! String) continue;
          place(
            p,
            'relations',
            relation: _bare(rel['relation']),
            filter: rel['where'] as String?,
          );
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // SYNC-ANCHOR
  // -------------------------------------------------------------------------

  /// Invariant `SYNC-ANCHOR`: a `@SyncedWith` names a `@Document`; beside a
  /// `@DetailedIn` it names the same document, and without one the section is
  /// reachable from the roots of both documents.
  void checkSyncAnchors(List<String> errors) {
    for (final site in _syncSites) {
      final where = _site(site.cls, site.member);
      final doc = site.anno.arguments['document'];
      if (doc is! String || !documentClasses.contains(doc)) {
        errors.add(
          '$_invariants SYNC-ANCHOR: @SyncedWith on $where names "$doc", which '
          'is no @Document class',
        );
        continue;
      }
      final detailed = [
        for (final a in site.member?.annotations ?? site.cls.annotations)
          if (a.name == 'DetailedIn') a.arguments['documentClass'],
      ].whereType<String>().toList();
      if (detailed.isNotEmpty) {
        if (!detailed.contains(doc)) {
          errors.add(
            '$_invariants SYNC-ANCHOR: @SyncedWith($doc) on $where stands '
            'beside @DetailedIn(${detailed.join(', ')}) — both name the same '
            'document',
          );
        }
        continue;
      }
      final roots = _rootsReaching(site.cls.name);
      final others = roots.where((r) => r != doc).toList();
      if (!roots.contains(doc) || others.isEmpty) {
        errors.add(
          '$_invariants SYNC-ANCHOR: @SyncedWith($doc) on $where — '
          '${site.cls.name} is reachable from '
          '${roots.isEmpty ? 'no root' : roots.join(', ')}, but a section in '
          'sync without @DetailedIn is reachable from $doc and from the root '
          'of its own document',
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // SHARED-COVER
  // -------------------------------------------------------------------------

  /// Invariant `SHARED-COVER` (a warning): every `@DetailedIn` has a
  /// `@SyncedWith` beside it, on the class or on the member that carries it.
  void checkSharedCover(List<String> warnings) {
    void check(String where, List<AnnotationData> annotations) {
      final detailed = [
        for (final a in annotations)
          if (a.name == 'DetailedIn') a.arguments['documentClass'],
      ].whereType<String>().toList();
      if (detailed.isEmpty) return;
      if (annotations.any((a) => a.name == 'SyncedWith')) return;
      warnings.add(
        '$_invariants SHARED-COVER: $where carries '
        '@DetailedIn(${detailed.join(', ')}) but no @SyncedWith beside it — '
        'what it shares with ${detailed.join(', ')} is not declared yet',
      );
    }

    for (final cls in _sorted) {
      check(cls.name, cls.annotations);
      for (final f in cls.fields) {
        check('${cls.name}.${f.name}', f.annotations);
      }
    }
  }

  // -------------------------------------------------------------------------
  // SHARED-ONE-HOLDER
  // -------------------------------------------------------------------------

  /// The classes a `@SyncedWith` seed governs: its subtree, stopping before
  /// another class-level seed (a nested sync is a pair of its own).
  Set<String> _seedSubtree(String seed, Set<String> seeds) {
    final out = <String>{};
    final queue = [seed];
    while (queue.isNotEmpty) {
      final c = queue.removeLast();
      if (c != seed && seeds.contains(c)) continue;
      if (!out.add(c)) continue;
      for (final f in classes[c]?.fields ?? const <ModelField>[]) {
        if (f.getAnnotation('Reference') != null) continue;
        if (f.isList && f.listElementIsComplex) {
          final el = f.listElementTypeName;
          if (el != null) queue.add(el);
        } else if (f.isComplex) {
          queue.add(f.typeName.replaceAll('?', ''));
        }
      }
    }
    return out;
  }

  /// The value places a class holds: each section's headline and content and
  /// each field of its forms, keyed `<class>:<section>.<slot>`.
  Set<String> _placesOf(String className) => {
    for (final n in _nodesOf[className] ?? const <_Node>[]) ..._nodePlaces(n),
  };

  Set<String> _nodePlaces(_Node n) => {
    '${n.owner}:${n.id}.@headline',
    if (n.hasContent) '${n.owner}:${n.id}.@content',
    for (final f in n.form) '${n.owner}:${n.id}.${f.name}',
  };

  /// The value places a resolved `heldHere` place holds.
  Set<String> _heldBy(_Resolution r) {
    if (r.slot != null) return {'${r.node.owner}:${r.node.id}.${r.slot}'};
    final below = r.node.isList ? r.node.elementType : r.node.type;
    return {
      ..._nodePlaces(r.node),
      if (below != null)
        for (final c in _reach(below)) ..._placesOf(c),
    };
  }

  /// Invariant `SHARED-ONE-HOLDER`: a place has one holder. A place is an
  /// instance, found by its path from the document root, and belongs to the
  /// pair of the nearest synced anchor above it; a nested pair is a pair of
  /// its own. A class type reused beneath two pairs (`PURE-PROJECTION` allows
  /// it) is two sets of places, each held by its own pair's document. Two
  /// holders arise only where one anchor carries `@SyncedWith` towards two
  /// different documents: then every place beneath it is listed in the
  /// `heldHere` of one of them.
  void checkSharedOneHolder(List<String> errors) {
    final seeds = [
      for (final site in _syncSites)
        if (site.member == null) site,
    ];
    final seedNames = {for (final s in seeds) s.cls.name};
    for (var i = 0; i < seeds.length; i++) {
      for (var j = i + 1; j < seeds.length; j++) {
        final a = seeds[i], b = seeds[j];
        if (a.cls.name != b.cls.name) continue;
        final docA = a.anno.arguments['document'];
        final docB = b.anno.arguments['document'];
        if (docA == docB) continue;
        final shared = _seedSubtree(a.cls.name, seedNames).toList()..sort();
        final held = <String>{};
        for (final s in [a, b]) {
          final scope = _syncScope(s.cls, null);
          for (final p in _strings(s.anno.arguments['heldHere'])) {
            final r = _resolveIn(p, scope);
            if (r.ok) held.addAll(_heldBy(r));
          }
        }
        final open = [
          for (final c in shared)
            for (final p in _placesOf(c).toList()..sort())
              if (!held.contains(p)) p,
        ];
        if (open.isEmpty) continue;
        errors.add(
          '$_invariants SHARED-ONE-HOLDER: ${a.cls.name} carries '
          '@SyncedWith($docA) and @SyncedWith($docB); ${open.length} of the '
          'places beneath it would be held by both documents '
          '(${open.take(5).join(', ')}${open.length > 5 ? ', …' : ''}) — list '
          'them in the heldHere of one of the two',
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // SHARED-ANCHOR
  // -------------------------------------------------------------------------

  /// Invariant `SHARED-ANCHOR`: a section anchored to a document
  /// (`@DetailedIn` or a class-level `@SyncedWith`) can be paired: its
  /// positions beneath the Solution Blueprint's root and beneath the
  /// document's root match one to one by their member path below the nearest
  /// enclosing anchor of that document, at most one of them on each side
  /// enclosed by no anchor.
  void checkSharedAnchors(List<String> errors, String blueprintRoot) {
    final anchorsByDoc = <String, Set<String>>{};
    for (final cls in classes.values) {
      for (final a in cls.annotations) {
        final doc = switch (a.name) {
          'DetailedIn' => a.arguments['documentClass'],
          'SyncedWith' => a.arguments['document'],
          _ => null,
        };
        if (doc is String && documentClasses.contains(doc)) {
          (anchorsByDoc[doc] ??= {}).add(cls.name);
        }
      }
    }
    for (final doc in anchorsByDoc.keys.toList()..sort()) {
      if (doc == blueprintRoot) continue;
      final anchors = anchorsByDoc[doc]!;
      for (final anchor in anchors.toList()..sort()) {
        final mine = _anchorKeys(blueprintRoot, anchor, anchors);
        final theirs = _anchorKeys(doc, anchor, anchors);
        if (mine.isEmpty || theirs.isEmpty) continue;
        final rootMine = mine['<root>'] ?? 0;
        final rootTheirs = theirs['<root>'] ?? 0;
        final same =
            mine.length == theirs.length &&
            mine.entries.every((e) => theirs[e.key] == e.value);
        if (rootMine <= 1 && rootTheirs <= 1 && same) continue;
        String show(Map<String, int> keys) =>
            (keys.entries
                    .map((e) => e.value == 1 ? e.key : '${e.key} ×${e.value}')
                    .toList()
                  ..sort())
                .join('; ');
        errors.add(
          '$_invariants SHARED-ANCHOR: $anchor (anchored to $doc) cannot be '
          'paired — beneath $blueprintRoot at ${show(mine)}, beneath $doc at '
          '${show(theirs)}; positions pair by their path below the nearest '
          'enclosing anchor of $doc, one to one',
        );
      }
    }
  }

  /// The positions of [anchor] beneath [root], each keyed by the nearest
  /// enclosing anchor of the same document and the member path below it
  /// (`<root>` when none encloses it), counted.
  Map<String, int> _anchorKeys(
    String root,
    String anchor,
    Set<String> anchors,
  ) {
    final keys = <String, int>{};
    void walk(String c, String? enclosing, List<String> below, Set<String> on) {
      if (!on.add(c)) return;
      if (c == anchor && c != root) {
        final key = enclosing == null
            ? '<root>'
            : '$enclosing/${below.join('/')}';
        keys[key] = (keys[key] ?? 0) + 1;
      }
      final anchorHere = c != root && anchors.contains(c);
      final nextEnclosing = anchorHere ? c : enclosing;
      final nextBelow = anchorHere ? const <String>[] : below;
      for (final f in classes[c]?.fields ?? const <ModelField>[]) {
        if (f.getAnnotation('Reference') != null) continue;
        String? child;
        if (f.isList && f.listElementIsComplex) {
          child = f.listElementTypeName;
        } else if (f.isComplex) {
          child = f.typeName.replaceAll('?', '');
        }
        if (child == null || !_reach(child).contains(anchor)) continue;
        walk(child, nextEnclosing, [...nextBelow, f.name], on);
      }
      on.remove(c);
    }

    walk(root, null, const [], {});
    return keys;
  }

  // -------------------------------------------------------------------------
  // SUMMARY-LINK
  // -------------------------------------------------------------------------

  /// Invariant `SUMMARY-LINK`: the `detail` of a `@SummaryOf` is a `-LST`
  /// container the named document reaches (or, with no document, one root
  /// reaches together with the summary); `match` is a reference field of the
  /// summary element naming the detail element class; every `repeats` pair
  /// resolves on its side with one type. A summary element may be of the
  /// detail element's own class.
  void checkSummaryLinks(List<String> errors) {
    void check(
      String where,
      String owner,
      Map<Object?, Object?> args, {
      String? summaryElement,
      FormFieldInfo? refField,
    }) {
      void fail(String what) =>
          errors.add('$_invariants SUMMARY-LINK: $where — $what');
      final detail = args['detail'];
      final document = args['document'];
      if (detail is! String) {
        fail('the summary names no detail list');
        return;
      }
      if (document != null &&
          (document is! String || !documentClasses.contains(document))) {
        fail('document "$document" is no @Document class');
        return;
      }
      final r = _resolveGlobal(detail, withinRoot: document as String?);
      if (!r.ok) {
        fail('detail "$detail" ${r.problem}');
        return;
      }
      if (!r.node.isList || r.slot != null) {
        fail('detail "$detail" is no -LST container');
        return;
      }
      final detailElement = r.node.elementType;
      if (detailElement == null) {
        fail('detail "$detail" holds no sections');
        return;
      }
      if (document == null && !_coReachable(owner, r.node.owner)) {
        fail(
          'detail "$detail" is reached by no root that reaches $owner — name '
          'its document',
        );
        return;
      }
      if (refField != null) {
        if (refField.refersTo.isEmpty || !refField.multiple) {
          fail('summaryOf: stands on a multiple reference field');
        } else if (!_namesClass(refField.refersTo, detailElement)) {
          fail(
            'its refersTo (${refField.refersTo.join(', ')}) does not name '
            '$detailElement, the element of "$detail"',
          );
        }
        if (args['match'] != null) {
          fail(
            'match names a field of a summary element; a summaryOf: field '
            'is that reference itself',
          );
        }
        final repeats = args['repeats'];
        if (repeats is Map && repeats.isNotEmpty) {
          fail('repeats needs summary elements; a summaryOf: field has none');
        }
        return;
      }
      final summaryScope = _subtree(summaryElement!);
      final match = args['match'];
      if (match is String) {
        final m = _resolveIn(match, summaryScope);
        if (!m.ok) {
          fail('match "$match" ${m.problem}');
        } else if (m.field == null || m.field!.refersTo.isEmpty) {
          fail('match "$match" is no reference field');
        } else if (!_namesClass(m.field!.refersTo, detailElement)) {
          fail(
            'match "$match" refers to ${m.field!.refersTo.join(', ')}, not to '
            '$detailElement, the element of "$detail"',
          );
        }
      }
      final repeats = args['repeats'];
      if (repeats is Map) {
        final detailScope = _subtree(detailElement);
        for (final e in repeats.entries) {
          final s = _resolveIn('${e.key}', summaryScope);
          final d = _resolveIn('${e.value}', detailScope);
          if (!s.ok) {
            fail('repeats "${e.key}" ${s.problem}');
          } else if (!d.ok) {
            fail('repeats "${e.value}" ${d.problem}');
          } else if (_valueType(s) == null || _valueType(s) != _valueType(d)) {
            fail(
              'repeats "${e.key}" (${_valueType(s) ?? 'a section'}) from '
              '"${e.value}" (${_valueType(d) ?? 'a section'}) — the two hold '
              'one type of value',
            );
          }
        }
      }
    }

    for (final site in _memberSites('SummaryOf')) {
      final where = '@SummaryOf on ${_site(site.cls, site.member)}';
      final m = site.member;
      if (!m.isList || !m.listElementIsComplex) {
        errors.add(
          '$_invariants SUMMARY-LINK: $where — @SummaryOf stands on a list of '
          'sections (or as summaryOf: on a reference field)',
        );
        continue;
      }
      check(
        where,
        site.cls.name,
        site.anno.arguments,
        summaryElement: m.listElementTypeName,
      );
    }
    for (final s in _formFields) {
      final args = s.field.summaryOf;
      if (args == null) continue;
      check(
        'summaryOf: on ${s.node.id}.${s.field.name} (${s.cls.name})',
        s.cls.name,
        args,
        refField: s.field,
      );
    }
  }

  // -------------------------------------------------------------------------
  // DERIVE-SOURCE and DERIVE-ACYCLIC
  // -------------------------------------------------------------------------

  ({List<String> problems, List<_Derivation> derivations})? _derivationCache;

  ({List<String> problems, List<_Derivation> derivations}) get _derived =>
      _derivationCache ??= _analyzeDerivations();

  /// Invariant `DERIVE-SOURCE`: every place of a `@DerivedFrom` resolves,
  /// with the derived place, from one `@Document` root; its filter names a
  /// field (an enum's value one of its constants); `take` and `map` fit the
  /// target; `key` and `by` hold one type; a derived field is not `required`
  /// and carries one derivation of `derivedFrom`, `countOf`, `productOf` and
  /// `rankOf`.
  void checkDeriveSources(List<String> errors) =>
      errors.addAll(_derived.problems);

  /// Invariant `DERIVE-ACYCLIC`: no derivation reads, directly or through
  /// other derived places, the place it writes.
  void checkDeriveAcyclic(List<String> errors) {
    final derivations = _derived.derivations;
    final byKey = {for (final d in derivations) d.key: d};
    // The derived places beneath each class, for reads of a whole section.
    final within = <String, Set<String>>{};
    for (final d in derivations) {
      (within[d.owner] ??= {}).add(d.key);
    }
    Set<String> region(_Resolution r) {
      if (r.field != null) return {'${r.node.key}.${r.field!.name}'};
      if (r.slot != null) return const {};
      final below = r.node.isList ? r.node.elementType : r.node.type;
      return {
        r.node.key,
        for (final f in r.node.form) '${r.node.key}.${f.name}',
        if (below != null)
          for (final c in _reach(below)) ...?within[c],
      };
    }

    final edges = <String, Set<String>>{
      for (final d in derivations)
        d.key: {
          for (final r in d.reads) ...region(r).where(byKey.containsKey),
          ...d.readKeys.where(byKey.containsKey),
        },
    };
    final reported = <String>{};
    final state = <String, int>{}; // 1 on the stack, 2 done
    final stack = <String>[];
    void visit(String k) {
      state[k] = 1;
      stack.add(k);
      for (final next in (edges[k] ?? const <String>{}).toList()..sort()) {
        if (state[next] == 1) {
          final cycle = stack.sublist(stack.indexOf(next));
          final id = (cycle.toList()..sort()).join(',');
          if (reported.add(id)) {
            errors.add(
              '$_invariants DERIVE-ACYCLIC: ${[...cycle, next].map((k) => byKey[k]!.label).join(' ← ')} '
              '— a derivation reads the place it writes',
            );
          }
        } else if (state[next] == null) {
          visit(next);
        }
      }
      stack.removeLast();
      state[k] = 2;
    }

    for (final k in edges.keys.toList()..sort()) {
      if (state[k] == null) visit(k);
    }
  }

  ({List<String> problems, List<_Derivation> derivations})
  _analyzeDerivations() {
    final problems = <String>[];
    final derivations = <_Derivation>[];

    void derive(
      String label,
      String key,
      String owner,
      Map<Object?, Object?> args, {
      FormFieldInfo? target,
      ModelField? member,
    }) {
      void fail(String what) =>
          problems.add('$_invariants DERIVE-SOURCE: $label — $what');
      final reads = <_Resolution>[];
      final kind = _bare(args['kind']);
      final source = args['source'];
      if (source is! String) {
        fail('it names no source');
        return;
      }
      final ownerScope = _subtree(owner);
      _Resolution resolveSource() {
        if (source.startsWith('./') || source.contains('/')) {
          return _resolveScoped(source, owner, ownerScope);
        }
        final r = _resolveGlobal(source);
        if (r.ok && !_coReachable(owner, r.node.owner)) {
          return _Resolution.error('is reached by no root that reaches $owner');
        }
        return r;
      }

      final src = resolveSource();
      if (!src.ok) {
        fail('source "$source" ${src.problem}');
        return;
      }
      reads.add(src);
      String? targetType;
      var multiRef = false;
      if (target != null) {
        targetType = target.typeName.replaceAll('?', '');
        multiRef = target.multiple && target.refersTo.isNotEmpty;
      }
      final targetIsList = member != null && member.isList;
      final targetElement = targetIsList && member.listElementIsComplex
          ? member.listElementTypeName
          : null;

      if (kind == 'copy') {
        final t = _valueType(src);
        if (t == null) {
          fail('copy reads one value, but "$source" is a whole section');
        } else if (targetIsList) {
          fail('copy writes one value, not a list');
        } else if (multiRef
            ? !_isReference(src)
            : t != (targetType ?? 'String')) {
          fail(
            'copy of "$source" ($t) does not fit a ${targetType ?? 'section'}',
          );
        }
        derivations.add(_Derivation(key, owner, label, reads));
        return;
      }
      if (kind != 'rows' && kind != 'lookup') {
        fail('kind "${args['kind']}" is none of copy, rows, lookup');
        return;
      }
      String? rowClass;
      if (src.slot == null && src.node.isList) {
        rowClass = src.node.elementType;
      } else if (src.slot == null &&
          src.node.member == null &&
          _listElements.contains(src.node.owner)) {
        rowClass = src.node.owner;
      }
      if (rowClass == null) {
        fail(
          '$kind reads rows, but "$source" is no list of sections nor a list '
          'element',
        );
        return;
      }
      final rowScope = _subtree(rowClass);
      final filter = args['where'];
      if (filter is String) {
        final problem = _checkFilter(filter, rowScope);
        if (problem != null) fail('$problem of $rowClass');
        final eq = filter.indexOf('=');
        if (eq > 0) {
          final w = _resolveIn(filter.substring(0, eq), rowScope);
          if (w.ok) reads.add(w);
        }
      }
      final takes = <_Resolution>[];
      for (final t in _strings(args['take'])) {
        final r = _resolveIn(t, rowScope);
        if (!r.ok) {
          fail('take "$t" ${r.problem}');
        } else if (_valueType(r) == null) {
          fail('take "$t" is a whole section, not a value');
        } else {
          takes.add(r);
          reads.add(r);
        }
      }
      // rows and lookup alike: key and by select the rows of this element.
      {
        final k = args['key'], by = args['by'];
        final kr = k is String ? _resolveIn(k, rowScope) : null;
        final br = by is String ? _resolveIn(by, ownerScope) : null;
        if (kr == null && br == null) {
          // Neither: every row matches, the last row is read.
        } else if (kr == null || br == null) {
          fail(
            '$kind names a key and a by, or neither'
            '${kind == 'lookup' ? ' (the last row)' : ' (every row)'}',
          );
        } else if (!kr.ok) {
          fail('key "$k" ${kr.problem}');
        } else if (!br.ok) {
          fail('by "$by" ${br.problem}');
        } else if (_valueType(kr) == null || _valueType(kr) != _valueType(br)) {
          fail('key "$k" and by "$by" hold different types of value');
        } else {
          reads
            ..add(kr)
            ..add(br);
        }
      }
      final map = args['map'];
      if (map is Map && map.isNotEmpty) {
        if (targetElement == null) {
          fail(
            'map builds list elements, but the target is no list of sections',
          );
        } else {
          final elementScope = _subtree(targetElement);
          for (final e in map.entries) {
            final to = _resolveIn('${e.key}', elementScope);
            final from = _resolveIn('${e.value}', rowScope);
            if (!to.ok) {
              fail('map "${e.key}" ${to.problem}');
            } else if (!from.ok) {
              fail('map "${e.value}" ${from.problem}');
            } else if (_valueType(to) == null ||
                _valueType(to) != _valueType(from)) {
              fail(
                'map "${e.key}" ← "${e.value}" hold different types of value',
              );
            } else {
              reads.add(from);
            }
          }
        }
      } else if (targetIsList) {
        fail('a derived list is built by map, one element per row');
      }
      if (target != null) {
        if (multiRef) {
          if (takes.length != 1 || !_isReference(takes.single)) {
            fail('a multiple reference field takes one reference place');
          }
        } else if (targetType == 'String') {
          final bad = [
            for (final t in takes)
              if (!_isText(t)) t,
          ];
          if (takes.isEmpty || bad.isNotEmpty) {
            fail('a text field takes text places');
          }
        } else if (takes.length != 1 ||
            _valueType(takes.single) != targetType) {
          fail('a $targetType field takes one $targetType place');
        }
      } else if (!targetIsList && takes.any((t) => !_isText(t))) {
        fail('a section takes text places');
      }
      derivations.add(_Derivation(key, owner, label, reads));
    }

    for (final site in _memberSites('DerivedFrom')) {
      final m = site.member;
      final node = _nodesOf[site.cls.name]!
          .where((n) => n.member == m.name)
          .firstOrNull;
      final label = '@DerivedFrom on ${_site(site.cls, m)}';
      if (!(m.isList || m.isContentLike || m.isSectionType)) {
        problems.add(
          '$_invariants DERIVE-SOURCE: $label — @DerivedFrom stands on a '
          'section or a list (on a form field, derivedFrom:)',
        );
        continue;
      }
      derive(
        label,
        node?.key ?? '${site.cls.name}.${m.name}',
        site.cls.name,
        site.anno.arguments,
        member: m,
      );
    }
    for (final s in _formFields) {
      final ff = s.field;
      final label = '${s.node.id}.${ff.name} (${s.cls.name})';
      final key = '${s.node.key}.${ff.name}';
      final count = [
        ff.derivedFrom != null,
        ff.countOf.isNotEmpty,
        ff.productOf.isNotEmpty,
        ff.rankOf.isNotEmpty,
      ].where((b) => b).length;
      if (count == 0) continue;
      if (count > 1) {
        problems.add(
          '$_invariants DERIVE-SOURCE: $label carries $count of derivedFrom, '
          'countOf, productOf and rankOf — a field has one derivation',
        );
      }
      if (ff.required) {
        problems.add(
          '$_invariants DERIVE-SOURCE: $label is derived and required — a '
          'derived field is written by deriveFields, never by its author',
        );
      }
      if (ff.derivedFrom != null) {
        derive(
          'derivedFrom: on $label',
          key,
          s.cls.name,
          ff.derivedFrom!,
          target: ff,
        );
      } else {
        // countOf, productOf and rankOf read fields too; they join the
        // acyclicity graph, their own checks stay with REFERS-TO.
        final readKeys = <String>{
          for (final op in [
            ...ff.productOf,
            if (ff.rankOf.isNotEmpty) ff.rankOf,
          ])
            if (!op.contains('.'))
              '${s.node.key}.$op'
            else
              for (final n in _nodesOf[s.cls.name]!)
                if (n.id == op.substring(0, op.indexOf('.')))
                  '${n.key}.${op.substring(op.indexOf('.') + 1)}',
        };
        derivations.add(
          _Derivation(key, s.cls.name, label, const [], readKeys: readKeys),
        );
      }
    }
    return (problems: problems, derivations: derivations);
  }

  // -------------------------------------------------------------------------
  // INVERSE-PAIR
  // -------------------------------------------------------------------------

  /// Invariant `INVERSE-PAIR`: both ends of an `inverseOf` are reference
  /// fields, each referring to the other's entry class and listing the other;
  /// `symmetric` stands on a field referring to its own entry class, and a
  /// `where` names fields of that row.
  void checkInversePairs(List<String> errors) {
    for (final s in _formFields) {
      final inv = s.field.inverseOf;
      if (inv == null) continue;
      final me = '${s.node.id}.${s.field.name}';
      final where = 'inverseOf: on $me (${s.cls.name})';
      void fail(String what) =>
          errors.add('$_invariants INVERSE-PAIR: $where — $what');
      if (s.field.refersTo.isEmpty) {
        fail('inverseOf stands on a refersTo field');
        continue;
      }
      final filter = inv['where'];
      if (filter is String) {
        final problem = _checkFilter(filter, _subtree(s.cls.name));
        if (problem != null) fail('$problem of ${s.cls.name}');
      }
      final ends = _strings(inv['fields']);
      if (ends.contains('@self')) {
        if (ends.length != 1) {
          fail('@self (symmetric) stands alone');
        } else if (!_namesAny(
          s.field.refersTo,
          _enclosingEntries(s.cls.name),
        )) {
          fail(
            'symmetric needs a refersTo naming its own entry class '
            '(${(_enclosingEntries(s.cls.name).toList()..sort()).join(', ')}), '
            'not ${s.field.refersTo.join(', ')}',
          );
        }
        continue;
      }
      if (ends.isEmpty) fail('it names no other end');
      for (final end in ends) {
        final r = _resolveGlobal(end);
        if (!r.ok) {
          fail('other end "$end" ${r.problem}');
          continue;
        }
        final other = r.field;
        if (other == null || other.refersTo.isEmpty) {
          fail('other end "$end" is no refersTo field');
          continue;
        }
        final theirs = _entryClasses(r.node.owner);
        if (!_namesAny(s.field.refersTo, theirs)) {
          fail(
            'its refersTo (${s.field.refersTo.join(', ')}) does not name '
            '${(theirs.toList()..sort()).join(', ')}, the entry class of '
            '"$end"',
          );
        }
        final mine = _entryClasses(s.cls.name);
        if (!_namesAny(other.refersTo, mine)) {
          fail(
            '"$end" refers to ${other.refersTo.join(', ')}, not to '
            '${(mine.toList()..sort()).join(', ')}',
          );
        }
        final back = _strings(other.inverseOf?['fields']);
        if (!back.contains(me)) {
          fail(
            '"$end" does not list $me in its inverseOf — both ends declare it',
          );
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // EXTRACT-LINK
  // -------------------------------------------------------------------------

  /// Invariant `EXTRACT-LINK`: `@ExtractsLinks` stands on a list of link
  /// rows; `from` names text fields beneath the nearest list element above;
  /// `ref` is a reference field of the row; every `set` key is a field of the
  /// row, its value a constant of an enum field.
  void checkExtractLinks(List<String> errors) {
    for (final site in _memberSites('ExtractsLinks')) {
      final where = '@ExtractsLinks on ${_site(site.cls, site.member)}';
      void fail(String what) =>
          errors.add('$_invariants EXTRACT-LINK: $where — $what');
      final m = site.member;
      final row = m.isList && m.listElementIsComplex
          ? m.listElementTypeName
          : null;
      if (row == null) {
        fail('@ExtractsLinks stands on a list of link rows');
        continue;
      }
      final args = site.anno.arguments;
      final scopes = _nearestListElements(site.cls.name).toList()..sort();
      final from = _strings(args['from']);
      if (from.isEmpty) fail('from names no text place');
      for (final p in from) {
        if (scopes.isEmpty) {
          fail('from "$p" — ${site.cls.name} lies beneath no list element');
          break;
        }
        _Resolution? found;
        String? problem;
        for (final scope in scopes) {
          final r = _resolveIn(p, _subtree(scope));
          if (r.ok) {
            found = r;
            break;
          }
          problem ??= r.problem;
        }
        if (found == null) {
          fail('from "$p" $problem');
        } else if (!_isText(found) || found.slot == '@sectionId') {
          fail('from "$p" is no text field');
        }
      }
      final rowScope = _subtree(row);
      final ref = args['ref'];
      if (ref is! String) {
        fail('ref names no field');
      } else {
        final r = _resolveIn(ref, rowScope);
        if (!r.ok) {
          fail('ref "$ref" ${r.problem} of $row');
        } else if (r.field == null || r.field!.refersTo.isEmpty) {
          fail('ref "$ref" is no refersTo field of $row');
        }
      }
      final set = args['set'];
      if (set is Map) {
        for (final e in set.entries) {
          final r = _resolveIn('${e.key}', rowScope);
          if (!r.ok) {
            fail('set "${e.key}" ${r.problem} of $row');
          } else if (r.field == null) {
            fail('set "${e.key}" is no form field of $row');
          } else if (r.field!.enumValues.isNotEmpty &&
              !r.field!.enumValues.contains('${e.value}')) {
            fail(
              'set "${e.key}" to "${e.value}", which is not a constant of '
              '${r.field!.typeName} (${r.field!.enumValues.join(', ')})',
            );
          }
        }
      }
    }
  }
}

/// An addressable section of the model: a class carrying a `@SectionId`, or
/// a member carrying a field-level one.
class _Node {
  _Node({
    required this.id,
    required this.owner,
    this.member,
    this.type,
    this.form = const [],
    this.hasContent = false,
    this.isList = false,
    this.elementType,
  });

  final String id;
  final String owner;
  final String? member;
  final String? type;
  final List<FormFieldInfo> form;
  final bool hasContent;
  final bool isList;
  final String? elementType;

  String get key => member == null ? owner : '$owner.$member';

  /// What makes two declarations of one id the same place.
  String get definition => member == null
      ? 'class:$owner'
      : 'member:$id:${isList ? 'list:$elementType' : type ?? ''}:'
            '${form.map((f) => f.name).join(',')}';
}

/// A node at one position in a subtree, with the section ids leading to it.
class _Occ {
  _Occ(this.node, this.path);
  final _Node node;
  final List<String> path;
}

/// A place as written: `./` scope, `/` segments, section id and slot.
class _ParsedPlace {
  _ParsedPlace(this.prefix, this.id, this.slot);

  final List<String> prefix;
  final String id;
  final String? slot;

  static final RegExp _segment = RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]*$');

  static _ParsedPlace? parse(String place) {
    final p = place.startsWith('./') ? place.substring(2) : place;
    if (p.isEmpty) return null;
    final segments = p.split('/');
    final last = segments.removeLast();
    final dot = last.indexOf('.');
    final id = dot < 0 ? last : last.substring(0, dot);
    final slot = dot < 0 ? null : last.substring(dot + 1);
    if (!_segment.hasMatch(id) || segments.any((s) => !_segment.hasMatch(s))) {
      return null;
    }
    if (slot != null && (slot.isEmpty || slot.contains('.'))) return null;
    return _ParsedPlace(segments, id, slot);
  }
}

/// A resolved place, or why it did not resolve.
class _Resolution {
  _Resolution(_Node this._node, this.slot, this.field, this.path)
    : problem = null;
  _Resolution.error(this.problem)
    : _node = null,
      slot = null,
      field = null,
      path = const [];

  final _Node? _node;
  final String? slot;
  final FormFieldInfo? field;
  final List<String> path;
  final String? problem;

  bool get ok => problem == null;
  _Node get node => _node!;
}

/// One derived place and the places it reads.
class _Derivation {
  _Derivation(
    this.key,
    this.owner,
    this.label,
    this.reads, {
    this.readKeys = const {},
  });

  final String key;
  final String owner;
  final String label;
  final List<_Resolution> reads;
  final Set<String> readKeys;
}
