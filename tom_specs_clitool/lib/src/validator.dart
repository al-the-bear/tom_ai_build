import 'model_reader.dart';

/// The document section every structural-invariant tag cites.
///
/// Named once so the tags stay short and a future renumbering of the rules
/// document is a one-line change rather than 27 — the tests match on the
/// expanded text, so they follow automatically.
const String _invariants = 'tom_specs_model_rules.md §10.2';

/// The document section every canonical-member-shape tag cites.
///
/// Named for the same reason as [_invariants]. The shapes these errors enforce
/// are the six *member shapes*, not the field *categories* the rules document's
/// §6 covers.
const String _shapes = 'tom_specs_model_rules.md §5.1';

/// The document section the keep-a-class / keep-a-level tags cite.
const String _keepRules = 'tom_specs_model_rules.md §5.8';

/// Validates model classes against the `tom_specs_model_rules.md` §5 design
/// rules.
///
/// Returns a record of (errors, warnings). Errors prevent output;
/// warnings are reported but don't block generation.
///
/// Also runs [validateStructuralInvariants] for the `tom_specs_model_rules.md`
/// §10.2 structural checks whenever [D00SolutionBlueprint] is present in
/// [classes].
({List<String> errors, List<String> warnings}) validateModel(
  Map<String, ModelClass> classes,
  String rootTypeName,
) {
  final errors = <String>[];
  final warnings = <String>[];

  // `tom_specs_model_rules.md` §5.7 — find reachable types from root
  final reachable = _findReachableTypes(classes, rootTypeName);

  // The canonical container (V2, N9) is the structural tree root, not a content
  // section: it owns no `content` and carries no `@SectionId`. Exempt it from
  // the `tom_specs_model_rules.md` §5 per-class content/field checks when it
  // is reachable (T1).
  final containerRoot = findContainerRoot(classes);

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    if (className == containerRoot) continue;

    // `tom_specs_model_rules.md` §5.4 — content: String? expected (warning)
    final hasContent = cls.fields.any((f) => f.name == 'content');
    if (!hasContent) {
      warnings.add('$className: missing field "content: String?"');
    }

    for (final field in cls.fields) {
      // `tom_specs_model_rules.md` §5.1 — list fields. Shape (5) uses
      // `List<ComplexType>`; shape (6) is an
      // inline list of content sub-sections written as `List<String>` carrying
      // both `@SectionId` (the `-LST` container id) and `@SectionIdPattern`. A
      // `List<String>` (or `List<primitive>`) WITHOUT that annotated pair is a
      // bare primitive list and remains an error.
      if (field.isList) {
        final inner = field.listElementTypeName ?? '';
        // YRD5: `List<DocSpecsSection>` replaces `List<String>` as the inline
        // content sub-section list shape — same annotated-pair requirement.
        if (_isPrimitive(inner) || field.listElementIsContentSection) {
          final isInlineContentList =
              (inner == 'String' || field.listElementIsContentSection) &&
                  field.getAnnotation('SectionId') != null &&
                  field.getAnnotation('SectionIdPattern') != null;
          if (!isInlineContentList) {
            errors.add(
              '$className.${field.name}: List<$inner> not allowed — '
              'list fields must use complex types, or (for List<String>) carry '
              '@SectionId + @SectionIdPattern as an inline content sub-section '
              'list (`tom_specs_model_rules.md` §5.1 shape 6)',
            );
          }
        }
      }

      // `tom_specs_model_rules.md` §5.4 — no primitive non-String scalars
      if (!field.isList && !field.isEnum && _isNonStringPrimitive(field.typeName)) {
        errors.add(
          '$className.${field.name}: type "${field.typeName}" not allowed — '
          'use String? with @Form Field type parameter instead',
        );
      }

      // `tom_specs_model_rules.md` §5.1 (YRB1) — canonical field shapes. The
      // name `content` is reserved
      // for the section's OWN content (shapes (1)/(2)): its section id comes
      // from the class, so it must be a String and must NOT carry a
      // field-level @SectionId. Every OTHER String field is an inline
      // sub-section (shape (3)) and MUST carry a field-level @SectionId.
      if (field.name == 'content') {
        if (!field.isString) {
          errors.add(
            '$_shapes field-shape: $className.content — the reserved field name '
            '"content" is only valid for the section\'s own String content, '
            'but its type is "${field.typeName}"',
          );
        } else if (field.getAnnotation('SectionId') != null) {
          errors.add(
            '$_shapes field-shape: $className.content — the section\'s own '
            '"content" must not carry a field-level @SectionId; its id comes '
            'from the class',
          );
        }
      } else if (field.isContentLike &&
          field.getAnnotation('SectionId') == null) {
        // YRD5: inline sub-sections are `DocSpecsSection?` members (formerly
        // `String?`); both shapes must carry the field-level @SectionId.
        errors.add(
          '$_shapes field-shape: $className.${field.name} — a non-"content" '
          'section field must carry a field-level @SectionId (it is an inline '
          'sub-section), or be named "content" if it is the section\'s own '
          'content',
        );
      }
    }

    // `tom_specs_model_rules.md` §5.6 — ContentType constraints
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

  // YRD5 — once the model has adopted the DocSpecsSection base class, EVERY
  // model class must extend it (tom_specs_model_rules.md §5.2). The
  // check only activates when at least one class extends the base, so
  // synthetic test fixtures that predate YRD5 keep validating.
  if (classes.values.any((c) => c.extendsDocSpecsSection)) {
    for (final className in reachable) {
      final cls = classes[className];
      if (cls == null) continue;
      if (!cls.extendsDocSpecsSection) {
        errors.add(
          'YRD5: $className must extend DocSpecsSection — every model class '
          'is a section (tom_specs_model_rules.md §5.2)',
        );
      }
    }
  }

  // YRD7 — a form field's type must be a supported scalar: a primitive
  // (String/int/double/num/bool) or a model enum (resolved to its constant
  // names at read time). Anything else cannot get a typed accessor or a
  // plain-text `FieldName: value` serialization.
  void checkFormFieldTypes(String where, List<FormFieldInfo> fields) {
    for (final ff in fields) {
      const primitives = {'String', 'int', 'double', 'num', 'bool'};
      final base = ff.typeName.endsWith('?')
          ? ff.typeName.substring(0, ff.typeName.length - 1)
          : ff.typeName;
      if (!primitives.contains(base) && ff.enumValues.isEmpty) {
        errors.add(
          'YRD7 form-field type: $where — field "${ff.name}" has unsupported '
          'type "${ff.typeName}"; form fields must be String/int/double/num/'
          'bool or a model enum',
        );
      }
    }
  }

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    if (cls.formFields.isNotEmpty) {
      checkFormFieldTypes('$className (class-level @Form)', cls.formFields);
    }
    for (final field in cls.fields) {
      if (field.formFields.isNotEmpty) {
        checkFormFieldTypes('$className.${field.name}', field.formFields);
      }
    }
  }

  // `tom_specs_model_rules.md` §5.7 — cycle detection
  final cycleError = _detectCycles(classes, rootTypeName);
  if (cycleError != null) {
    errors.add(cycleError);
  }

  // `tom_specs_model_rules.md` §10.2 — structural invariants (SBP-global, runs
  // whenever D00SolutionBlueprint is present in the classes map regardless of
  // the current root type).
  _validateStructuralInvariants(classes, errors, warnings);

  return (errors: errors, warnings: warnings);
}

// ---------------------------------------------------------------------------
// `tom_specs_model_rules.md` §10.2 Structural invariants — public entry point
// ---------------------------------------------------------------------------

/// Validates the `tom_specs_model_rules.md` §10.2 structural invariants of the
/// TomSpecs object model.
///
/// These checks operate globally from [D00SolutionBlueprint] as the root and are
/// independent of the `rootTypeName` passed to [validateModel]:
///
/// - **`@SectionId` global uniqueness** — no two classes reachable from
///   `D00SolutionBlueprint` may carry the same class-level `@SectionId` string.
///   Field-level `@SectionId` values (the `-LST` container IDs on list fields)
///   occupy a *separate* namespace and are checked independently (see the
///   `-LST` checks below).
/// - **`@SectionId` single-occurrence (per class)** — a class may declare at
///   most one class-level `@SectionId`. A duplicate annotation on the same
///   class would pass the global-uniqueness check silently (the repeated id
///   only ever collides with itself, and the reader's `getAnnotation` returns
///   only the first occurrence), so it is rejected explicitly here.
/// - **Field-level `-LST` checks** — list container IDs follow the form
///   `<E>-<FIELDSUFFIX>-LST`, where `<E>` is a mnemonic for the element type
///   (normally its class-level `@SectionId`) and `<FIELDSUFFIX>` is a
///   4-character mnemonic for the field (normally its first four letters).
///   Both tokens are hand-authored: this validator checks the *shape* and the
///   uniqueness properties of the pair, never the derivation of either token.
///   Two invariants hold: (i) *type-consistency* — a container ID always maps
///   to exactly one element type; (ii) *per-class uniqueness* — within one
///   class, no two list fields may share a container ID (the field suffix
///   guarantees this; the check guards hand-authored deviations). Cross-class
///   sharing of a container ID is allowed when both the element type and the
///   field name coincide (interpretation X: addressing is parent-path + local
///   ID). The `@SectionIdPattern` must mirror the container ID
///   (`<E>-<FIELDSUFFIX>-xxx` ↔ `<E>-<FIELDSUFFIX>-LST`).
/// - **`@SectionId` coverage** — every class reachable from
///   `D00SolutionBlueprint` must carry a class-level `@SectionId`, unless it is
///   exempt by `@SectionIdPattern`. The exemption is transitive: a direct
///   list-element type reached via a `@SectionIdPattern` field is exempt, and
///   so is the entire subtree reachable from that element type (those nested
///   classes are template sub-sections that inherit the pattern's instance ID).
/// - **`@SectionIdPattern` list-coverage** — every reachable complex
///   `List<T>` field must carry `@SectionIdPattern` (so its repeated elements
///   get per-instance section IDs), unless the field is `@Reference`. This is
///   the authoritative analyzer-based replacement for the heuristic
///   `missing_pattern_scan.py`, which suffered line-proximity false negatives.
/// - **`@DetailedIn` → ancestor `@MapsTo` check** — for every class
///   `C` carrying `@DetailedIn(D)`, some class on the path from
///   `D00SolutionBlueprint` to `C` (inclusive) must carry `@MapsTo(D)`.
/// - **Detail-count per `@Document` class** — warns if a `@Document`-tagged
///   class has zero `@DetailedIn` entries in the SBP tree (likely omission).
/// - **Root-independent section-id resolution (dsa4)** — a class reachable
///   from more than one `@Document` root must resolve to the same section id
///   from every root. Both id mechanisms are root-independent by construction:
///   a class-level `@SectionId` is a fixed property of the class, and a
///   `@SectionIdPattern` list instance id is derived from the *element* class's
///   own `@SectionId` (the `<E>` prefix, e.g. `STKNT` → `STKNT-PRIM-xxx`), so an
///   element class carrying a class-level `@SectionId` is by design, not a
///   conflict. The genuine cross-root divergence is *structural-mode mixing*: a
///   class reached in one place as the direct element of a `@SectionIdPattern`
///   list (→ addressed by the list instance pattern) and in another as a
///   standalone complex section field (→ addressed by its own class-level
///   `@SectionId`) resolves to a different id depending on the traversal root
///   and is rejected. `@Reference` edges are excluded.
/// - **Collapsible-wrapper detection** (`tom_specs_model_rules.md` §5.8 /
///   TSMA4–TSMA5) — warns when a
///   *single-subsection wrapper* with vacuous content adds a redundant
///   hierarchy level: a class referenced by exactly one complex parent field
///   (unshared), holding exactly one subsection field, whose every other field
///   is a bare `content` leaf carrying no `@Form`, no substantive
///   `@ContentHelp`/`@StandardReferences`/non-Form `@ContentType`, and no named
///   scalar. The keep-a-level exemptions (form-bearing, meaningful content,
///   shared/multi-referrer) are canonical shape (4)/(5) sections and are NOT
///   flagged. Reported as a warning (a design smell), not an error.
///
/// If [D00SolutionBlueprint] is not present in [classes] the function is a
/// no-op (useful for unit tests against small synthetic models that don't
/// include a full SBP tree).
({List<String> errors, List<String> warnings}) validateStructuralInvariants(
  Map<String, ModelClass> classes,
) {
  final errors = <String>[];
  final warnings = <String>[];
  _validateStructuralInvariants(classes, errors, warnings);
  return (errors: errors, warnings: warnings);
}

/// Returns the `tom_specs_model_rules.md` §10.2 `@SectionId` coverage gaps
/// reachable from [rootTypeName].
///
/// A *gap* is a class reachable from the root that carries no class-level
/// `@SectionId` and is not covered by a `@SectionIdPattern` list field (neither
/// as a direct list element nor anywhere in a pattern element's subtree). The
/// canonical container root (which owns no `@SectionId` by design) is exempt.
///
/// The embedded `_validateStructuralInvariants` check emits the same gaps as
/// warnings, but only from the `D00SolutionBlueprint` root. This helper is
/// root-parametric so a caller can assert coverage from *every* `@Document`
/// root independently (dsa5), rather than relying on the pure-projection
/// invariant to transfer SBP coverage to the projection roots.
List<String> sectionIdCoverageGaps(
  Map<String, ModelClass> classes,
  String rootTypeName,
) {
  final reachable = _findReachableTypes(classes, rootTypeName);

  // Direct element types of @SectionIdPattern list fields, then the full
  // subtree reachable from each — those are pattern-covered "template" types
  // that inherit their sectioning id from the list instance.
  final patternCovered = <String>{};
  final toExpand = <String>[];
  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    for (final field in cls.fields) {
      if (!field.isList || !field.listElementIsComplex) continue;
      if (field.getAnnotation('SectionIdPattern') == null) continue;
      final element = field.listElementTypeName;
      if (element != null) toExpand.add(element);
    }
  }
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

  final container = findContainerRoot(classes);
  final gaps = <String>[];
  for (final className in reachable) {
    if (className == container) continue;
    final cls = classes[className];
    if (cls == null) continue;
    if (cls.getAnnotation('SectionId') != null) continue;
    if (patternCovered.contains(className)) continue;
    gaps.add(className);
  }
  gaps.sort();
  return gaps;
}

// ---------------------------------------------------------------------------
// `tom_specs_model_rules.md` §10.2 implementation
// ---------------------------------------------------------------------------

void _validateStructuralInvariants(
  Map<String, ModelClass> classes,
  List<String> errors,
  List<String> warnings,
) {
  const sbpRoot = 'D00SolutionBlueprint';
  if (!classes.containsKey(sbpRoot)) return;

  final reachable = _findReachableTypes(classes, sbpRoot);

  // Collect all @Document classes from the full map (Phase 3 roots are NOT
  // reachable from SBP — they type against SBP classes, not the other way).
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

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;

    // @SectionId single-occurrence — a class may declare @SectionId at most
    // once. `getAnnotation` returns only the first match, so a duplicate on the
    // same class would otherwise pass the global-uniqueness check below
    // silently (the repeated id only collides with itself).
    final sectionIdCount =
        cls.annotations.where((a) => a.name == 'SectionId').length;
    if (sectionIdCount > 1) {
      errors.add(
        '$_invariants @SectionId single-occurrence: $className carries $sectionIdCount '
        'class-level @SectionId annotations — a class may declare @SectionId '
        'at most once',
      );
    }

    // @SectionId uniqueness — class-level annotation
    final sectionIdAnno = cls.getAnnotation('SectionId');
    if (sectionIdAnno != null) {
      final id = sectionIdAnno.arguments['id'] as String? ?? '';
      if (id.isNotEmpty) {
        if (sectionIdSeen.containsKey(id)) {
          errors.add(
            '$_invariants @SectionId uniqueness: id "$id" used by both '
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
        '$_invariants @SectionId coverage: $className is reachable from '
        'D00SolutionBlueprint but has no class-level @SectionId and is not '
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
            '$_invariants @SectionId consistency: container id "$lstId" used for both '
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
          '$_invariants @SectionId per-class uniqueness: container id "$lstId" used by '
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
            '$_invariants @SectionId/@SectionIdPattern pairing: '
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
  // The check walks the real reachable type graph via the analyzer, so unlike a
  // textual scan of the sources it cannot produce line-proximity false
  // negatives.
  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    for (final field in cls.fields) {
      if (!field.isList || !field.listElementIsComplex) continue;
      if (field.getAnnotation('Reference') != null) continue;
      if (field.getAnnotation('SectionIdPattern') == null) {
        errors.add(
          '$_invariants @SectionIdPattern list-coverage: $className.${field.name} '
          '(List<${field.listElementTypeName}>) has no @SectionIdPattern and '
          'is not @Reference — repeated sections must carry a numbering pattern',
        );
      }
    }
  }

  // --- 3. @DetailedIn → ancestor @MapsTo check ----------------------------

  // Build a reverse-adjacency (parent) map for the SBP-reachable subgraph.
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
          '$_invariants @DetailedIn ancestor check: $className has '
          '@DetailedIn($docType) but no @MapsTo($docType) on itself or '
          'any ancestor in the D00SolutionBlueprint tree',
        );
      }
    }
  }

  // --- 4. Detail-count per @Document class (warn if 0) --------------------

  for (final docClassName in documentClasses) {
    if (docClassName == sbpRoot) continue; // SBP is the root, not a target
    // A CodeSpecs generation projection is `@CodeSpecKind`-driven, not
    // `@DetailedIn`-driven: the single-valued `@DetailedIn`/`@MapsTo` pair on
    // each subtree root is already spent on its Phase-3 document, so no SBP
    // section carries `@DetailedIn(<projection>)`. The `@CodeSpecsProjection()`
    // marker exempts such a projection from the detail-count check (it still
    // satisfies the `tom_specs_model_rules.md` §10.2 pure-projection invariant
    // checked below).
    if (classes[docClassName]?.getAnnotation('CodeSpecsProjection') != null) {
      continue;
    }
    final count = reachable
        .where((c) => detailedInByClass[c]?.contains(docClassName) ?? false)
        .length;
    if (count == 0) {
      warnings.add(
        '$_invariants detail-count: @Document class $docClassName has no '
        '@DetailedIn($docClassName) entries in the D00SolutionBlueprint tree',
      );
    }
  }

  // --- 5. Pure-projection invariant (T2, N12) ------------------------------
  //
  // The twelve Phase 3 roots are `@Document(basedOn: [D00SolutionBlueprint])`
  // *projections*: they aggregate SBP00 sections and own no content of their own
  // (`tom_specs_editor_specification.md` §14). The single-tree model is sound
  // only if a projection root contains
  // **no content absent from the Project Definition** — otherwise the global
  // `toYaml` could not emit each section exactly once, and the connect pass
  // (`tom_specs_editor_specification.md` §15.1) would have to invent or drop
  // content.
  //
  // Check: every type reachable from a projection root (other than the root
  // class itself) must also be reachable from D00SolutionBlueprint. A reachable
  // type with no SBP counterpart is projection-local content — a violation.
  // The unannotated container is structural, never a projection target, so it
  // is excluded here.
  for (final docClassName in documentClasses) {
    if (docClassName == sbpRoot) continue;
    final projectionReachable = _findReachableTypes(classes, docClassName);
    for (final type in projectionReachable) {
      if (type == docClassName) continue; // the projection root class itself
      if (reachable.contains(type)) continue; // has a SBP counterpart
      errors.add(
        '$_invariants pure-projection: projection root $docClassName reaches "$type", '
        'which is not present in the D00SolutionBlueprint tree — a projection '
        'root must contain no content without a SBP counterpart (N12)',
      );
    }
  }

  // --- 6. Collapsible-wrapper detection ------------------------------------
  // `tom_specs_model_rules.md` §5.8 / TSMA4–TSMA5.
  //
  // The dual of the TSMA1/TSMA2 leaf collapse: a *single-subsection wrapper*
  // adds a redundant hierarchy level when its own content carries no meaning of
  // its own. Such a wrapper W:
  //   * is referenced by EXACTLY ONE parent field as a single complex field
  //     (one complex referrer, never a list element) — unshared (TSMA3 rule),
  //   * has EXACTLY ONE subsection field (list / complex / section type),
  //   * whose every OTHER field is a leaf (String/enum),
  //   * carries NO `@Form` (class- or field-level) — form structure would be
  //     lost by promotion,
  //   * carries NO substantive `@ContentHelp` / `@StandardReferences` / non-Form
  //     `@ContentType` on a leaf — such content documents a distinct concept,
  //   * declares NO named leaf besides `content` — a named scalar is
  //     independent meaning that would be orphaned.
  // When all hold, the wrapper level is pure indirection and should be
  // collapsed (promote the subsection onto the parent field — TSMA4). This is
  // the operational "content has no meaning by itself" test: content is absent
  // or a bare `content` with no form / help / refs / non-Form type and no
  // sibling named scalar. The keep-a-level exemptions
  // (`tom_specs_model_rules.md` §5.8 / TSMA5) — a form-bearing wrapper, a
  // meaningful-content wrapper, or a shared/multi-referrer wrapper — are
  // canonical `tom_specs_model_rules.md` §5.1 shape (4)/(5) sections and are
  // NOT
  // flagged. Reported as a WARNING (a design smell, not a correctness error):
  // generation still proceeds. This mirrors `tsma4_census.dart`; after TSMA4
  // the real model yields zero of these.
  final containerRootName = findContainerRoot(classes);

  // Referrer counts across the whole model (matches keep-a-class / TSMA3
  // sharing semantics): a class reached by >1 field anywhere is shared.
  final complexReferrers = <String, int>{};
  final listReferrers = <String, int>{};
  final soleComplexParent = <String, ({String parent, String field})>{};
  for (final owner in classes.values) {
    for (final field in owner.fields) {
      if (field.isList) {
        final el = field.listElementTypeName;
        if (el != null && field.listElementIsComplex && classes.containsKey(el)) {
          listReferrers[el] = (listReferrers[el] ?? 0) + 1;
        }
      } else if (field.isComplex) {
        final t = field.typeName.replaceAll('?', '');
        if (classes.containsKey(t)) {
          complexReferrers[t] = (complexReferrers[t] ?? 0) + 1;
          soleComplexParent[t] = (parent: owner.name, field: field.name);
        }
      }
    }
  }

  bool isSubsectionField(ModelField f) =>
      f.isList || f.isComplex || f.isSectionType;

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;
    if (className == containerRootName) continue;
    if (className == sbpRoot) continue; // the master-blueprint anchor is not a wrapper
    if (cls.getAnnotation('Document') != null) continue;
    // Unshared: exactly one complex referrer, never a list element.
    if ((complexReferrers[className] ?? 0) != 1) continue;
    if ((listReferrers[className] ?? 0) != 0) continue;

    final subs = cls.fields.where(isSubsectionField).toList();
    if (subs.length != 1) continue;
    final others = cls.fields.where((f) => !isSubsectionField(f)).toList();
    // Every non-subsection field must be a leaf (String/enum).
    if (others.any((f) => !f.isLeaf)) continue;

    // Keep-a-level exemptions (TSMA5) — do NOT flag these.
    final classForm =
        cls.getAnnotation('Form') != null || cls.formFields.isNotEmpty;
    final anyFieldForm = cls.fields
        .any((f) => f.getAnnotation('Form') != null || f.formFields.isNotEmpty);
    if (classForm || anyFieldForm) continue; // form-bearing wrapper stays
    final anyHelpRefs = others.any((f) {
      if (f.getAnnotation('ContentHelp') != null) return true;
      if (f.getAnnotation('StandardReferences') != null) return true;
      final ct = f.getAnnotation('ContentType');
      return ct != null && (ct.arguments['type'] as String? ?? 'Form') != 'Form';
    });
    if (anyHelpRefs) continue; // meaningful-content wrapper stays
    if (others.any((f) => f.name != 'content')) continue; // named scalar stays

    // Collapsible — vacuous content, single subsection, single referrer.
    final sub = subs.single;
    final subKind = sub.isList
        ? 'list<${sub.listElementTypeName}>'
        : sub.isSectionType
            ? 'section:${sub.typeName}'
            : 'complex:${sub.typeName.replaceAll('?', '')}';
    final origin = soleComplexParent[className];
    final where =
        origin == null ? '(unknown parent)' : '${origin.parent}.${origin.field}';
    warnings.add(
      '$_keepRules collapsible-wrapper: $className is a single-subsection wrapper '
      'with vacuous content, referenced only by $where — collapse it by '
      'promoting ${sub.name} ($subKind) onto the parent field (TSMA4)',
    );
  }

  // --- 7. Root-independent section-id resolution (dsa4) --------------------
  //
  // A class reachable from more than one @Document root must resolve to the
  // SAME section id from every root. Both id mechanisms are root-independent by
  // construction: a class-level @SectionId is a property of the class (and
  // globally unique — check 2), while a @SectionIdPattern lives on the parent
  // list field, so its instance id is a pure function of the field position.
  // The field-suffixed scheme deliberately lets the same element type appear
  // under several list fields — and the element's class-level @SectionId is the
  // mnemonic `<E>` prefix of every such container/pattern id (e.g. `STKNT` →
  // `STKNT-PRIM-LST` / `STKNT-PRIM-xxx`); that is NOT a conflict.
  //
  // The one genuine cross-root divergence is a class reached in TWO different
  // STRUCTURAL modes: as a direct @SectionIdPattern list element (→ resolves to
  // the field's instance pattern) AND as a direct standalone complex field
  // (→ resolves to its own class @SectionId). Such a class resolves to a
  // different id depending on which position/root reached it. A class must be
  // reached in a single structural mode. @Reference fields are cross-references
  // (not owned sub-sections) and are excluded from the standalone set.
  //
  // Both sets are collected across ALL roots — the SBP tree plus every
  // @Document projection root (which may re-reference an SBP type).
  final allRootsReachable = <String>{...reachable};
  for (final doc in documentClasses) {
    allRootsReachable.addAll(_findReachableTypes(classes, doc));
  }
  final directPatternElementsAllRoots = <String>{};
  final standaloneComplexTypes = <String>{};
  for (final className in allRootsReachable) {
    final cls = classes[className];
    if (cls == null) continue;
    for (final field in cls.fields) {
      if (field.getAnnotation('Reference') != null) continue;
      if (field.isList && field.listElementIsComplex) {
        if (field.getAnnotation('SectionIdPattern') == null) continue;
        final el = field.listElementTypeName;
        if (el != null) directPatternElementsAllRoots.add(el);
      } else if (field.isComplex) {
        standaloneComplexTypes.add(field.typeName.replaceAll('?', ''));
      }
    }
  }
  for (final className in directPatternElementsAllRoots) {
    if (!standaloneComplexTypes.contains(className)) continue;
    errors.add(
      '$_invariants root-independent id: $className is reached both as a direct '
      '@SectionIdPattern list element (→ the list instance pattern) and as a '
      'standalone complex section field (→ its own class @SectionId) — its id '
      'resolves differently depending on the traversal root; a class must be '
      'reached in a single structural mode (list element XOR standalone '
      'section)',
    );
  }

  // --- 8. @OneOf / @Case discriminated subsection groups -------------------
  //
  // A container section that resolves to exactly one of a closed set of typed
  // alternatives carries `@OneOf(discriminator: '<formField>')`; each
  // alternative complex-subsection field carries one or more `@Case(<const>)`
  // bindings; un-@Case'd subsections are *common* (present for every case).
  // The static tier checks (`codespecs_mapping.md` §8.2):
  //   (i)   the discriminator resolves to a `@Form` field of the container
  //         whose type is a model enum;
  //   (ii)  every `@Case` value is a constant of that discriminator enum;
  //   (iii) the cases *cover* the enum (an uncovered constant is a WARNING — a
  //         kind with no attributes yet is legal);
  //   (iv)  every `@Case`-bound field is a complex subsection of the same
  //         container; and a `@Case` outside any `@OneOf` container is rejected.
  _validateOneOfGroups(classes, reachable, errors, warnings);

  // --- 9. Cross-registry id references (`Field.refersTo`) -------------------
  //
  // A form field whose String value is an *id declared elsewhere* names its
  // target registry key(s) as `<SECTIONID>.<formFieldName>`. The static tier
  // checks the declaration is resolvable; the dangling-id check proper is the
  // instance tier's job (`spec_validator.dart`), which needs document values
  // the class graph cannot see.
  _validateReferenceTargets(classes, reachable, errors, warnings);
}

/// Gathers every `@Form` field of [cls], from the class-level `@Form` and from
/// each member's field-level `@Form` (the discriminator of a `@OneOf` group may
/// live on the reserved `content` member's form, e.g. `ScreenElementEntry`).
List<FormFieldInfo> _allFormFields(ModelClass cls) => [
      ...cls.formFields,
      for (final field in cls.fields) ...field.formFields,
    ];

/// Splits a qualified `EnumType.constant` token (as carried by `@Case`) into
/// its `(enumType, constant)` parts, or `null` if it is not qualified.
({String enumType, String constant})? _splitEnumToken(Object? value) {
  if (value is! String) return null;
  final dot = value.indexOf('.');
  if (dot <= 0 || dot == value.length - 1) return null;
  return (enumType: value.substring(0, dot), constant: value.substring(dot + 1));
}

/// Static enforcement of the `@OneOf`/`@Case` closed-choice mechanism
/// (`codespecs_mapping.md` §8.2).
void _validateOneOfGroups(
  Map<String, ModelClass> classes,
  Set<String> reachable,
  List<String> errors,
  List<String> warnings,
) {
  // A case-bound field must be a genuine *subsection* whose presence/absence
  // is meaningful under the chosen case: a complex class field, a complex list,
  // a known section type, or an inline content/form sub-section (a
  // `DocSpecsSection` member carrying its own field-level `@SectionId`, shape 3
  // — distinct from the reserved unmarked `content` member).
  bool isSubsection(ModelField f) =>
      f.isComplex ||
      (f.isList && f.listElementIsComplex) ||
      f.isSectionType ||
      (f.isContentSection && f.getAnnotation('SectionId') != null);

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;

    final oneOf = cls.getAnnotation('OneOf');

    // (iv-b) A `@Case` outside any `@OneOf` container is dangling.
    if (oneOf == null) {
      for (final field in cls.fields) {
        if (field.annotations.any((a) => a.name == 'Case')) {
          errors.add(
            '$_invariants one-of: $className.${field.name} carries @Case but its class '
            'declares no @OneOf group — @Case is only valid on a subsection of '
            'an @OneOf container',
          );
        }
      }
      continue;
    }

    final discriminator = oneOf.arguments['discriminator'] as String?;
    if (discriminator == null || discriminator.isEmpty) {
      errors.add(
        '$_invariants one-of: $className carries @OneOf without a discriminator name',
      );
      continue;
    }

    // (i) The discriminator resolves to a @Form field whose type is a model
    // enum (its enum constants are resolved at read time — YRD7).
    final formFields = _allFormFields(cls);
    FormFieldInfo? discField;
    for (final f in formFields) {
      if (f.name == discriminator) {
        discField = f;
        break;
      }
    }
    if (discField == null) {
      errors.add(
        '$_invariants one-of: $className @OneOf discriminator "$discriminator" is not a '
        '@Form field of the class',
      );
      continue;
    }
    if (discField.enumValues.isEmpty) {
      errors.add(
        '$_invariants one-of: $className @OneOf discriminator "$discriminator" '
        '(type ${discField.typeName}) is not a model enum — the discriminator '
        'must be an enum @Form field so cases can be checked and resolved',
      );
      continue;
    }
    final enumType = discField.typeName;
    final enumConstants = discField.enumValues.toSet();

    final coveredConstants = <String>{};
    for (final field in cls.fields) {
      final caseAnnos =
          field.annotations.where((a) => a.name == 'Case').toList();
      if (caseAnnos.isEmpty) continue;

      // (iv) Every @Case-bound field is a complex subsection of the container.
      if (!isSubsection(field)) {
        errors.add(
          '$_invariants one-of: $className.${field.name} carries @Case but is not a '
          'complex subsection — only subsection fields can be case-bound',
        );
      }

      for (final caseAnno in caseAnnos) {
        final token = _splitEnumToken(caseAnno.arguments['value']);
        if (token == null) {
          errors.add(
            '$_invariants one-of: $className.${field.name} @Case value is not a '
            'qualified enum constant',
          );
          continue;
        }
        // (ii) Every @Case value is a constant of the discriminator enum.
        if (token.enumType != enumType) {
          errors.add(
            '$_invariants one-of: $className.${field.name} @Case(${token.enumType}.'
            '${token.constant}) does not belong to the discriminator enum '
            '"$enumType"',
          );
          continue;
        }
        if (!enumConstants.contains(token.constant)) {
          errors.add(
            '$_invariants one-of: $className.${field.name} @Case value '
            '"$enumType.${token.constant}" is not a constant of "$enumType"',
          );
          continue;
        }
        coveredConstants.add(token.constant);
      }
    }

    // (iii) Cases should cover the enum — uncovered constants are a WARNING.
    final uncovered = enumConstants.difference(coveredConstants).toList()
      ..sort();
    if (uncovered.isNotEmpty) {
      warnings.add(
        '$_invariants one-of: $className @OneOf on "$discriminator" leaves '
        '${uncovered.length} enum constant(s) uncovered by any @Case '
        '(${uncovered.join(', ')}) — legal for kinds with no extra attributes',
      );
    }
  }
}

/// Static enforcement of the cross-registry id reference declaration
/// (`Field.refersTo`, csrb3).
///
/// A `refersTo` entry is a *registry key* written `<SECTIONID>.<formFieldName>`
/// — e.g. `'SCRTEN.routeId'`. The check confirms the declaration is resolvable
/// end to end, so the instance tier can actually run it:
///
///   (i)   the entry parses as `<SECTIONID>.<formFieldName>`;
///   (ii)  the section id resolves to exactly one class in the graph;
///   (iii) that class declares a `@Form` field of that name;
///   (iv)  that form field is `required`, because an entry allowed to omit its
///         id declares no id to resolve against;
///   (v)   that class is *enumerated* — it is used somewhere as the element
///         type of a list, or it sits inside such a class as a singleton
///         subsection — because an id is only meaningful when the entries
///         that declare it can be enumerated.
///
/// (v) is what stops a reference from pointing at a form section that happens
/// to carry a like-named field but exists once per document: nothing there
/// would ever declare a set of ids to resolve against.
///
/// The singleton-subsection arm of (v) matters because a registry entry
/// usually decomposes: `BusinessProcessEntry` is the list element, but the
/// process id lives one level down in its `ProcessIdentification` section.
/// That section is instantiated exactly once per entry, so its required form
/// fields enumerate 1:1 with the entries — it is the precise target, and
/// naming the outer entry instead would fail (iii), since the outer class
/// declares no such form field.
void _validateReferenceTargets(
  Map<String, ModelClass> classes,
  Set<String> reachable,
  List<String> errors,
  List<String> warnings,
) {
  // Section id → class name(s). A duplicate section id is already an error of
  // its own (§8.6 global uniqueness); here it only makes the target ambiguous.
  final bySectionId = <String, List<String>>{};
  for (final entry in classes.entries) {
    final id = entry.value.getAnnotation('SectionId')?.arguments['id'];
    if (id is String && id.isNotEmpty) {
      bySectionId.putIfAbsent(id, () => []).add(entry.key);
    }
  }

  // Classes whose instances are enumerated — the registry entries and the
  // singleton subsections they decompose into. Computed over the whole graph,
  // not just [reachable], so a single-document validation run judges the
  // target the same way a whole-model run does.
  //
  // Seed: every class used as a list element type anywhere in the model.
  // Closure: every class reached from a seed through singleton complex
  // members, since such a member is instantiated exactly once per entry and
  // therefore enumerates 1:1 with it.
  final enumeratedTypes = <String>{};
  final pending = <String>[];
  for (final cls in classes.values) {
    for (final field in cls.fields) {
      if (field.isList && field.listElementIsComplex) {
        final inner = field.listElementTypeName;
        if (inner != null && enumeratedTypes.add(inner)) pending.add(inner);
      }
    }
  }
  while (pending.isNotEmpty) {
    final owner = classes[pending.removeLast()];
    if (owner == null) continue;
    for (final field in owner.fields) {
      if (!field.isComplex) continue;
      if (enumeratedTypes.add(field.typeName)) pending.add(field.typeName);
    }
  }

  for (final className in reachable) {
    final cls = classes[className];
    if (cls == null) continue;

    for (final formField in _allFormFields(cls)) {
      for (final target in formField.refersTo) {
        final where = '$className.${formField.name}';

        // (i) Grammar. The qualified form is required: a bare section id says
        // where to look but not what to compare against, so the instance tier
        // could not run and the contract would stay unenforced for exactly the
        // fields it exists to protect.
        final dot = target.indexOf('.');
        if (dot <= 0 || dot == target.length - 1 ||
            target.indexOf('.', dot + 1) != -1) {
          errors.add(
            '$_invariants refersTo: $where declares target "$target" — a target '
            'must be written <SECTIONID>.<formFieldName>',
          );
          continue;
        }
        final sectionId = target.substring(0, dot);
        final fieldName = target.substring(dot + 1);

        // (ii) The section id resolves.
        final owners = bySectionId[sectionId];
        if (owners == null || owners.isEmpty) {
          errors.add(
            '$_invariants refersTo: $where targets "$target" but no class carries '
            '@SectionId(\'$sectionId\')',
          );
          continue;
        }
        if (owners.length > 1) {
          errors.add(
            '$_invariants refersTo: $where targets "$target" but section id '
            '"$sectionId" is carried by ${owners.length} classes '
            '(${(owners.toList()..sort()).join(', ')}) — the target is ambiguous',
          );
          continue;
        }
        final targetClass = classes[owners.single]!;

        // (iii) The target declares that form field.
        final targetFields = _allFormFields(targetClass);
        final targetField =
            targetFields.where((f) => f.name == fieldName).firstOrNull;
        if (targetField == null) {
          errors.add(
            '$_invariants refersTo: $where targets "$target" but '
            '${targetClass.name} declares no @Form field "$fieldName"',
          );
          continue;
        }

        // (iv) The target form field is required. An optional id cannot be a
        // registry key: an entry that omits it declares no id, so a reference
        // that names it would be unresolvable through no fault of its own.
        if (!targetField.required) {
          errors.add(
            '$_invariants refersTo: $where targets "$target" but '
            '${targetClass.name}.$fieldName is not required — a registry key '
            'must be required, or entries could omit it',
          );
          continue;
        }

        // (v) The target really is enumerated.
        if (!enumeratedTypes.contains(targetClass.name)) {
          errors.add(
            '$_invariants refersTo: $where targets "$target" but '
            '${targetClass.name} is not enumerated (it is never a list element '
            'type, nor a subsection of one) — an id reference needs a set of '
            'entries to resolve against',
          );
          continue;
        }

        // The reference itself must be free text: an id is authored as a
        // String, never as an enum or a number.
        if (formField.typeName != 'String') {
          warnings.add(
            '$_invariants refersTo: $where declares a reference but its form '
            'field type is ${formField.typeName} — id references are String-valued',
          );
        }
      }
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

