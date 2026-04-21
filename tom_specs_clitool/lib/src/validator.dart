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

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;

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
///   `ProjectDefinition` may carry the same `@SectionId` string.  Field-level
///   `@SectionId` values (the `-LST` container IDs on list fields) are included
///   in the same uniqueness namespace.
/// - **`@SectionId` coverage** — every class reachable from
///   `ProjectDefinition` must carry a class-level `@SectionId`, unless it
///   is a list-element type reached via a field annotated with
///   `@SectionIdPattern`.
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
  // Under the flat-ID scheme, multiple list fields containing the same element
  // type INTENTIONALLY share the same @SectionIdPattern value (e.g. all
  // List<DeliverableEntry> fields share '@SectionIdPattern("DLVEN-xxx")').
  // Pattern-string and pattern-prefix uniqueness checks are therefore not
  // performed.  What IS checked is that field-level @SectionId values ("-LST"
  // IDs) are globally unique — that check happens in section 2 below.

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

  // --- 2b. Field-level @SectionId ("-LST") consistency check ---------------
  //
  // Field-level @SectionId values are type-scoped: all list fields containing
  // the same element type share the same "-LST" ID.  The invariant to enforce
  // is therefore consistency — a given "-LST" ID must always correspond to
  // exactly one element type.  (Multiple fields of the same type sharing one
  // "-LST" ID is valid and expected under the flat-ID scheme.)

  // lstId → element type name (first field seen wins)
  final lstIdToElementType = <String, String>{};

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    for (final field in cls.fields) {
      if (!field.isList || !field.listElementIsComplex) continue;
      final fieldSectionIdAnno = field.getAnnotation('SectionId');
      if (fieldSectionIdAnno == null) continue;
      final lstId = fieldSectionIdAnno.arguments['id'] as String? ?? '';
      if (lstId.isEmpty) continue;
      final elementType = field.listElementTypeName ?? '';
      if (lstIdToElementType.containsKey(lstId)) {
        final existing = lstIdToElementType[lstId]!;
        if (existing != elementType) {
          errors.add(
            '§8.6 @SectionId consistency: "-LST" id "$lstId" used for both '
            '$existing and $elementType — a "-LST" id must always correspond '
            'to exactly one element type',
          );
        }
      } else {
        lstIdToElementType[lstId] = elementType;
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

