import 'model_reader.dart';

/// Validates model classes against §6 design rules.
///
/// Returns a record of (errors, warnings). Errors prevent output;
/// warnings are reported but don't block generation.
///
/// Also runs [validateStructuralInvariants] for the §8.6 structural checks
/// whenever [ProjectDefinition] is present in [classes].
({List<String> errors, List<String> warnings}) validateModel(
  Map<String, ModelClass> classes,
  String rootTypeName,
) {
  final errors = <String>[];
  final warnings = <String>[];

  // §6.5 — find reachable types from root
  final reachable = _findReachableTypes(classes, rootTypeName);

  // The canonical container (V2, N9) is the structural tree root, not a content
  // section: it owns no `content` and carries no `@SectionId`. Exempt it from
  // the §6 per-class content/field checks when it is reachable (T1).
  final containerRoot = findContainerRoot(classes);

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    if (className == containerRoot) continue;

    // §6.1 — content: String? expected (warning, not error)
    final hasContent = cls.fields.any((f) => f.name == 'content');
    if (!hasContent) {
      warnings.add('$className: missing field "content: String?"');
    }

    for (final field in cls.fields) {
      // §6.1 — no List<String> or List<primitive>
      if (field.isList) {
        final inner = field.listElementTypeName ?? '';
        if (_isPrimitive(inner)) {
          errors.add(
            '$className.${field.name}: List<$inner> not allowed — '
            'list fields must use complex types',
          );
        }
      }

      // §6.1 — no primitive non-String scalars
      if (!field.isList && !field.isEnum && _isNonStringPrimitive(field.typeName)) {
        errors.add(
          '$className.${field.name}: type "${field.typeName}" not allowed — '
          'use String? with @Form Field type parameter instead',
        );
      }
    }

    // §6.4 — ContentType constraints
    final contentField = cls.fields.where((f) => f.name == 'content').firstOrNull;
    if (contentField != null) {
      final contentTypeAnno = contentField.getAnnotation('ContentType');
      final contentType = contentTypeAnno?.arguments['type'] as String? ?? 'Form';
      if (contentType != 'Form') {
        // Non-Form content — class must not have other scalar fields
        final otherScalars = cls.fields
            .where((f) => f.name != 'content' && f.isLeaf)
            .toList();
        if (otherScalars.isNotEmpty) {
          final names = otherScalars.map((f) => f.name).join(', ');
          errors.add(
            '$className: @ContentType("$contentType") prohibits other scalar '
            'fields, but found: $names',
          );
        }
      }
    }
  }

  // §5.2 — cycle detection
  final cycleError = _detectCycles(classes, rootTypeName);
  if (cycleError != null) {
    errors.add(cycleError);
  }

  // §8.6 — structural invariants (PD-global, runs whenever ProjectDefinition
  // is present in the classes map regardless of the current root type).
  _validateStructuralInvariants(classes, errors, warnings);

  return (errors: errors, warnings: warnings);
}

// ---------------------------------------------------------------------------
// §8.6 Structural invariants — public entry point
// ---------------------------------------------------------------------------

/// Validates the §8.6 structural invariants of the TomSpecs object model.
///
/// These checks operate globally from [ProjectDefinition] as the root and are
/// independent of the `rootTypeName` passed to [validateModel]:
///
/// - **`@SectionId` global uniqueness** — no two classes reachable from
///   `ProjectDefinition` may carry the same class-level `@SectionId` string.
///   Field-level `@SectionId` values (the `-LST` container IDs on list fields)
///   occupy a *separate* namespace and are checked independently (see the
///   `-LST` checks below).
/// - **Field-level `-LST` checks** — list container IDs follow the form
///   `<E>-<FIELDSUFFIX>-LST`, where `<E>` is the element type's class-level
///   `@SectionId` and `<FIELDSUFFIX>` is the field name uppercased. Two
///   invariants hold: (i) *type-consistency* — a container ID always maps to
///   exactly one element type; (ii) *per-class uniqueness* — within one class,
///   no two list fields may share a container ID (the field-name suffix
///   guarantees this; the check guards hand-authored deviations). Cross-class
///   sharing of a container ID is allowed when both the element type and the
///   field name coincide (interpretation X: addressing is parent-path + local
///   ID). The `@SectionIdPattern` must mirror the container ID
///   (`<E>-<FIELDSUFFIX>-xxx` ↔ `<E>-<FIELDSUFFIX>-LST`).
/// - **`@SectionId` coverage** — every class reachable from
///   `ProjectDefinition` must carry a class-level `@SectionId`, unless it is
///   exempt by `@SectionIdPattern`. The exemption is transitive: a direct
///   list-element type reached via a `@SectionIdPattern` field is exempt, and
///   so is the entire subtree reachable from that element type (those nested
///   classes are template sub-sections that inherit the pattern's instance ID).
/// - **`@SectionIdPattern` list-coverage** — every reachable complex
///   `List<T>` field must carry `@SectionIdPattern` (so its repeated elements
///   get per-instance section IDs), unless the field is `@Reference`. This is
///   the authoritative analyzer-based replacement for the heuristic
///   `missing_pattern_scan.py`, which suffered line-proximity false negatives.
/// - **`@SecondLevelSectionId` implies `@DetailedIn`** — any class carrying
///   `@SecondLevelSectionId(D, …)` must also carry `@DetailedIn(D)`.
/// - **`@DetailedIn` → ancestor `@MapsTo` check** — for every class
///   `C` carrying `@DetailedIn(D)`, some class on the path from
///   `ProjectDefinition` to `C` (inclusive) must carry `@MapsTo(D)`.
/// - **Detail-count per `@Document` class** — warns if a `@Document`-tagged
///   class has zero `@DetailedIn` entries in the PD tree (likely omission).
///
/// If [ProjectDefinition] is not present in [classes] the function is a
/// no-op (useful for unit tests against small synthetic models that don't
/// include a full PD tree).
({List<String> errors, List<String> warnings}) validateStructuralInvariants(
  Map<String, ModelClass> classes,
) {
  final errors = <String>[];
  final warnings = <String>[];
  _validateStructuralInvariants(classes, errors, warnings);
  return (errors: errors, warnings: warnings);
}

// ---------------------------------------------------------------------------
// §8.6 implementation
// ---------------------------------------------------------------------------

void _validateStructuralInvariants(
  Map<String, ModelClass> classes,
  List<String> errors,
  List<String> warnings,
) {
  const pdRoot = 'ProjectDefinition';
  if (!classes.containsKey(pdRoot)) return;

  final reachable = _findReachableTypes(classes, pdRoot);

  // Collect all @Document classes from the full map (Phase 3 roots are NOT
  // reachable from PD — they type against PD classes, not the other way).
  final documentClasses = <String>{};
  for (final entry in classes.entries) {
    if (entry.value.getAnnotation('Document') != null) {
      documentClasses.add(entry.key);
    }
  }

  // --- 1. @SectionIdPattern coverage collection ----------------------------
  //
  // Under the field-suffixed ID scheme, every list field carries a container
  // ID `<E>-<FIELDSUFFIX>-LST` and a matching pattern `<E>-<FIELDSUFFIX>-xxx`.
  // Two different classes that each declare a list of the same element type
  // with the same field name legitimately share one container/pattern pair
  // (cross-class sharing). Global pattern-string uniqueness is therefore not
  // required. What IS checked (in section 2b below) is: type-consistency (a
  // container ID maps to exactly one element type), per-class uniqueness (no
  // two list fields in one class share a container ID), and container/pattern
  // pairing.

  // Direct element types of @SectionIdPattern list fields.
  final directPatternElements = <String>{};

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    for (final field in cls.fields) {
      if (!field.isList || !field.listElementIsComplex) continue;
      final patAnno = field.getAnnotation('SectionIdPattern');
      if (patAnno == null) continue;

      if (field.listElementTypeName != null) {
        directPatternElements.add(field.listElementTypeName!);
      }
    }
  }

  // Expand exemption to the full subtree reachable from each direct pattern
  // element.  These are "template" types — each instance of the list entry
  // carries the list element's sectioning ID (via @SectionIdPattern), so
  // their nested sub-classes do not need their own static @SectionId.
  final patternCovered = <String>{};
  final toExpand = [...directPatternElements];
  final expandVisited = <String>{};
  while (toExpand.isNotEmpty) {
    final current = toExpand.removeLast();
    if (!expandVisited.add(current)) continue;
    patternCovered.add(current);
    final cls = classes[current];
    if (cls == null) continue;
    for (final field in cls.fields) {
      String? childType;
      if (field.isList && field.listElementIsComplex) {
        childType = field.listElementTypeName;
      } else if (field.isComplex) {
        childType = field.typeName.replaceAll('?', '');
      }
      if (childType != null) toExpand.add(childType);
    }
  }

  // --- 2. @SectionId uniqueness + coverage; collect traceability data ------

  final sectionIdSeen = <String, String>{}; // id → className
  final mapsToByClass = <String, Set<String>>{}; // className → {docTypeName}
  final detailedInByClass = <String, Set<String>>{}; // className → {docTypeName}
  final secondLevelByClass = <String, Set<String>>{}; // className → {docTypeName}

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;

    // @SectionId uniqueness — class-level annotation
    final sectionIdAnno = cls.getAnnotation('SectionId');
    if (sectionIdAnno != null) {
      final id = sectionIdAnno.arguments['id'] as String? ?? '';
      if (id.isNotEmpty) {
        if (sectionIdSeen.containsKey(id)) {
          errors.add(
            '§8.6 @SectionId uniqueness: id "$id" used by both '
            '${sectionIdSeen[id]} and $className '
            '— IDs must be globally unique',
          );
        } else {
          sectionIdSeen[id] = className;
        }
      }
    } else if (!patternCovered.contains(className)) {
      // Coverage: class is reachable but has neither @SectionId nor is
      // covered by a @SectionIdPattern field.
      warnings.add(
        '§8.6 @SectionId coverage: $className is reachable from '
        'ProjectDefinition but has no class-level @SectionId and is not '
        'a @SectionIdPattern list-element type',
      );
    }

    // Collect traceability annotations — arguments['documentClass'] holds the
    // target doc class name as a String (extracted by ModelReader after the
    // Type-extraction fix in _extractDartValue).
    for (final anno in cls.annotations) {
      final docType = anno.arguments['documentClass'] as String?;
      if (docType == null) continue;
      switch (anno.name) {
        case 'MapsTo':
          (mapsToByClass[className] ??= {}).add(docType);
        case 'DetailedIn':
          (detailedInByClass[className] ??= {}).add(docType);
        case 'SecondLevelSectionId':
          (secondLevelByClass[className] ??= {}).add(docType);
      }
    }
  }

  // --- 2b. Field-level @SectionId ("-LST") checks --------------------------
  //
  // Container IDs follow `<E>-<FIELDSUFFIX>-LST`. Enforced invariants:
  //   (i)   type-consistency  — a container ID maps to exactly one element type.
  //   (ii)  per-class unique   — within one class, list fields have distinct
  //                              container IDs (field-name suffix guarantees it).
  //   (iii) pattern pairing    — @SectionIdPattern mirrors the container ID.
  // Cross-class sharing of a container ID is allowed (same element type AND
  // same field name) — interpretation X, parent-path addressing.

  // container id → element type name (first field seen wins)
  final lstIdToElementType = <String, String>{};

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    // container id → field name, scoped to this class (for per-class uniqueness)
    final seenInClass = <String, String>{};
    for (final field in cls.fields) {
      if (!field.isList || !field.listElementIsComplex) continue;
      final fieldSectionIdAnno = field.getAnnotation('SectionId');
      if (fieldSectionIdAnno == null) continue;
      final lstId = fieldSectionIdAnno.arguments['id'] as String? ?? '';
      if (lstId.isEmpty) continue;
      final elementType = field.listElementTypeName ?? '';

      // (i) type-consistency (global)
      if (lstIdToElementType.containsKey(lstId)) {
        final existing = lstIdToElementType[lstId]!;
        if (existing != elementType) {
          errors.add(
            '§8.6 @SectionId consistency: container id "$lstId" used for both '
            '$existing and $elementType — a container id must always correspond '
            'to exactly one element type',
          );
        }
      } else {
        lstIdToElementType[lstId] = elementType;
      }

      // (ii) per-class uniqueness
      if (seenInClass.containsKey(lstId)) {
        errors.add(
          '§8.6 @SectionId per-class uniqueness: container id "$lstId" used by '
          'both $className.${seenInClass[lstId]} and $className.${field.name} — '
          'sibling list fields must carry distinct container IDs',
        );
      } else {
        seenInClass[lstId] = field.name;
      }

      // (iii) container/pattern pairing
      final patAnno = field.getAnnotation('SectionIdPattern');
      final pattern = patAnno?.arguments['pattern'] as String? ?? '';
      if (pattern.isNotEmpty && lstId.endsWith('-LST')) {
        final expected =
            '${lstId.substring(0, lstId.length - '-LST'.length)}-xxx';
        if (pattern != expected) {
          errors.add(
            '§8.6 @SectionId/@SectionIdPattern pairing: '
            '$className.${field.name} has container id "$lstId" but pattern '
            '"$pattern" (expected "$expected")',
          );
        }
      }
    }
  }

  // --- 2c. @SectionIdPattern list-coverage check ---------------------------
  //
  // Every reachable complex `List<T>` field must carry @SectionIdPattern so its
  // elements receive per-instance section IDs under the flat-ID scheme. The
  // only exemption is @Reference fields, which point at sections owned
  // elsewhere and therefore do not introduce repeated sections of their own.
  // This is the authoritative replacement for the buggy `missing_pattern_scan.py`
  // heuristic (see section_id_pattern_plan O6.1): it walks the real reachable
  // type graph via the analyzer and cannot suffer the scan's line-proximity
  // false negatives.
  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    for (final field in cls.fields) {
      if (!field.isList || !field.listElementIsComplex) continue;
      if (field.getAnnotation('Reference') != null) continue;
      if (field.getAnnotation('SectionIdPattern') == null) {
        errors.add(
          '§8.6 @SectionIdPattern list-coverage: $className.${field.name} '
          '(List<${field.listElementTypeName}>) has no @SectionIdPattern and '
          'is not @Reference — repeated sections must carry a numbering pattern',
        );
      }
    }
  }

  // --- 3. @SecondLevelSectionId implies @DetailedIn ------------------------

  for (final entry in secondLevelByClass.entries) {
    final className = entry.key;
    for (final docType in entry.value) {
      if (!(detailedInByClass[className]?.contains(docType) ?? false)) {
        errors.add(
          '§8.6 @SecondLevelSectionId implies @DetailedIn: '
          '$className has @SecondLevelSectionId($docType, …) '
          'but no @DetailedIn($docType) on the same class',
        );
      }
    }
  }

  // --- 4. @DetailedIn → ancestor @MapsTo check ----------------------------

  // Build a reverse-adjacency (parent) map for the PD-reachable subgraph.
  // childType → set of parent class names that own a field of that type.
  // @Reference fields are excluded — they don't represent ownership.
  final parentMap = <String, Set<String>>{};
  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    for (final field in cls.fields) {
      if (field.getAnnotation('Reference') != null) continue;
      String? childType;
      if (field.isList && field.listElementIsComplex) {
        childType = field.listElementTypeName;
      } else if (field.isComplex) {
        childType = field.typeName.replaceAll('?', '');
      }
      if (childType != null && reachable.contains(childType)) {
        (parentMap[childType] ??= {}).add(className);
      }
    }
  }

  // Walk UP the parent chain (BFS) to find @MapsTo(docType) on the class
  // itself or any ancestor reachable from the root.
  bool hasAncestorOrSelfMapsTo(String startClass, String docType) {
    final visited = <String>{};
    final queue = [startClass];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) continue;
      if (mapsToByClass[current]?.contains(docType) ?? false) return true;
      for (final parent in (parentMap[current] ?? {})) {
        if (!visited.contains(parent)) queue.add(parent);
      }
    }
    return false;
  }

  for (final entry in detailedInByClass.entries) {
    final className = entry.key;
    for (final docType in entry.value) {
      if (!hasAncestorOrSelfMapsTo(className, docType)) {
        errors.add(
          '§8.6 @DetailedIn ancestor check: $className has '
          '@DetailedIn($docType) but no @MapsTo($docType) on itself or '
          'any ancestor in the ProjectDefinition tree',
        );
      }
    }
  }

  // --- 5. Detail-count per @Document class (warn if 0) --------------------

  for (final docClassName in documentClasses) {
    if (docClassName == pdRoot) continue; // PD is the root, not a target
    final count = reachable
        .where((c) => detailedInByClass[c]?.contains(docClassName) ?? false)
        .length;
    if (count == 0) {
      warnings.add(
        '§8.6 detail-count: @Document class $docClassName has no '
        '@DetailedIn($docClassName) entries in the ProjectDefinition tree',
      );
    }
  }

  // --- 6. Pure-projection invariant (T2, N12) ------------------------------
  //
  // The twelve Phase 3 roots are `@Document(basedOn: [ProjectDefinition])`
  // *projections*: they aggregate PD00 sections and own no content of their own
  // (§14). The single-tree model is sound only if a projection root contains
  // **no content absent from the Project Definition** — otherwise the global
  // `toYaml` could not emit each section exactly once, and the connect pass
  // (§15.1) would have to invent or drop content.
  //
  // Check: every type reachable from a projection root (other than the root
  // class itself) must also be reachable from ProjectDefinition. A reachable
  // type with no PD counterpart is projection-local content — a violation.
  // The unannotated container is structural, never a projection target, so it
  // is excluded here.
  for (final docClassName in documentClasses) {
    if (docClassName == pdRoot) continue;
    final projectionReachable = _findReachableTypes(classes, docClassName);
    for (final type in projectionReachable) {
      if (type == docClassName) continue; // the projection root class itself
      if (reachable.contains(type)) continue; // has a PD counterpart
      errors.add(
        '§8.6 pure-projection: projection root $docClassName reaches "$type", '
        'which is not present in the ProjectDefinition tree — a projection '
        'root must contain no content without a PD counterpart (N12)',
      );
    }
  }
}

Set<String> _findReachableTypes(
  Map<String, ModelClass> classes,
  String rootTypeName,
) {
  final visited = <String>{};
  final queue = <String>[rootTypeName];

  while (queue.isNotEmpty) {
    final current = queue.removeLast();
    if (!visited.add(current)) continue;

    final cls = classes[current];
    if (cls == null) continue;

    for (final field in cls.fields) {
      if (field.isList && field.listElementIsComplex) {
        final inner = field.listElementTypeName;
        if (inner != null && !visited.contains(inner)) {
          queue.add(inner);
        }
      } else if (field.isComplex) {
        final typeName = field.typeName.replaceAll('?', '');
        if (!visited.contains(typeName)) {
          queue.add(typeName);
        }
      }
    }
  }

  return visited;
}

String? _detectCycles(
  Map<String, ModelClass> classes,
  String rootTypeName,
) {
  final visiting = <String>{};
  final visited = <String>{};
  final path = <String>[];

  bool dfs(String typeName) {
    if (visited.contains(typeName)) return false;
    if (visiting.contains(typeName)) {
      return true;
    }

    visiting.add(typeName);
    path.add(typeName);

    final cls = classes[typeName];
    if (cls != null) {
      for (final field in cls.fields) {
        // Skip @Reference fields — they don't create ownership cycles
        if (field.getAnnotation('Reference') != null) continue;

        String? childType;
        if (field.isList && field.listElementIsComplex) {
          childType = field.listElementTypeName;
        } else if (field.isComplex) {
          childType = field.typeName.replaceAll('?', '');
        }

        if (childType != null && classes.containsKey(childType)) {
          if (dfs(childType)) return true;
        }
      }
    }

    path.removeLast();
    visiting.remove(typeName);
    visited.add(typeName);
    return false;
  }

  if (dfs(rootTypeName)) {
    // Reconstruct cycle from path
    return 'Cycle detected in model: ${path.join(' → ')}';
  }

  return null;
}

bool _isPrimitive(String typeName) {
  final base = typeName.replaceAll('?', '');
  return const {'String', 'int', 'double', 'bool', 'num', 'DateTime'}
      .contains(base);
}

bool _isNonStringPrimitive(String typeName) {
  final base = typeName.replaceAll('?', '');
  return const {'int', 'double', 'bool', 'num', 'DateTime'}.contains(base);
}

