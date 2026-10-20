/// Validates a concrete [SpecDocument]'s values against a [SpecModel] via the
/// [SpecReflection] resolver ("validation against meta-data").
///
/// The check is over the values a document *holds*: every set path must resolve
/// to a node of a compatible kind, every form sub-key must name a real form
/// field, and every populated list must meet its `@Min` item count. Schema
/// completeness (mandatory-but-absent nodes) is a separate concern and is not
/// reported here.
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_reflection.dart';
import 'spec_section_id.dart';
import 'spec_typed_values.dart';

/// Why a single value in a document is invalid against the model.
enum SpecValidationCode {
  /// The path does not resolve to any reachable model node.
  danglingPath,

  /// The path resolves, but to a node that cannot hold this kind of value.
  kindMismatch,

  /// A form sub-key names a field the form section does not declare.
  unknownFormField,

  /// A populated list holds fewer items than its `@Min` requires.
  minItems,

  /// A `@OneOf` container carries a case-bound subsection that the chosen
  /// discriminator value does not select, or more than one subsection for the
  /// chosen case (`codespecs_mapping.md` §8.2, csmb6).
  oneOfCaseMismatch,

  /// A reference form field (`Field.refersTo`) holds an id that no entry of any
  /// of its target registries declares (csrb3).
  danglingReference,

  /// A form field whose model type is an enum holds a token the enum does not
  /// declare.
  ///
  /// A closed vocabulary that nothing closes is a documentation convention
  /// rather than a type: the typed accessor's read is deliberately forgiving
  /// (an unknown token answers null), and since a document is *loaded* far more
  /// often than it is written through a setter, the forgiving half is the one
  /// that runs. Seven such values sat in a committed sample from the day they
  /// were written, each silently absent to every typed reader.
  ///
  /// The **empty** value is not reported: an absent field is absence, not a bad
  /// value, and every other tier treats it that way.
  enumValueUnknown,

  /// A form field that states a count (`Field.countOf`) holds a number that
  /// is not the number of entries the document holds, or no whole number at
  /// all (vsctsa43). A total kept by hand drifts from the list it describes
  /// the first time the list changes and the total does not.
  countMismatch,

  /// A typed field (`int`, `double`, `num` or `bool`) — a form field or a
  /// scalar leaf — holds text its type cannot read (`lots` in an `int`).
  ///
  /// The typed read refuses such text rather than answering null, and the
  /// setters refuse to store it, but a document edited by hand or by another
  /// tool can still carry it; this is where it is reported. Empty text is
  /// absence, not a bad value, and is not reported.
  valueTypeMismatch,

  /// A form field whose value is derived from other fields — a product
  /// (`Field.productOf`) or a rank by a sibling field (`Field.rankOf`) — holds
  /// a value the fields it is derived from do not give, or no number at all
  /// (uamtc10). A risk score kept by hand drifts the first time probability or
  /// impact changes and the score does not.
  derivedValueMismatch,

  /// A form the document holds leaves a `required` field empty (uamtc16).
  ///
  /// Checked for every form instance that holds at least one field value —
  /// a class-level form, a form declared on a section member, in a list item
  /// or not — so an absent form is absence, not an incomplete one. The schema
  /// tier checks class-level forms of the rendition only; this is the check
  /// that reaches every form.
  missingRequiredField,

  /// A reference field that holds one id (no `Field.multiple`) holds a
  /// comma-separated list (uamtc17). A field meant for one reference must not
  /// silently hold several; each id of the list is still resolved, so a
  /// dangling one is a `danglingReference` as well.
  multipleReferences,
}

/// One problem found while validating a document.
class SpecValidationError {
  /// The document path the problem is anchored at.
  final String path;

  /// The category of problem.
  final SpecValidationCode code;

  /// A human-readable description.
  final String message;

  /// All three are required, so no finding can be reported without saying
  /// where it is — validation returns a list rather than throwing, and an
  /// entry with no [path] would be unactionable among dozens. [code] is the
  /// stable half of the pair: the wording of [message] is free to improve, so
  /// callers that group, count or suppress findings must key on the code.
  const SpecValidationError({
    required this.path,
    required this.code,
    required this.message,
  });

  @override
  String toString() => '[${code.name}] $path: $message';
}

/// Validates [doc] against [model]. Returns an empty list when the document is
/// valid; otherwise one [SpecValidationError] per problem, in a stable order
/// (content paths, then forms, then lists; each group sorted by path).
List<SpecValidationError> validateDocument(SpecModel model, SpecDocument doc) {
  final refl = SpecReflection(model);
  final errors = <SpecValidationError>[];

  List<String> sorted(Iterable<String> keys) => keys.toList()..sort();

  // 1. Content/scalar/enum leaves.
  for (final path in sorted(doc.contentPaths)) {
    final res = refl.resolve(path);
    if (res == null) {
      errors.add(_dangling(path));
      continue;
    }
    // A form node is the one non-leaf that legitimately carries content: it is
    // the form's preamble, the free text before the first field line (SOM §11.4
    // rule 7), stored in the same `content` slot a plain section's body uses.
    // A wrapper section (`TextSection`, …) is the other: its class is not
    // exported, so it resolves to no class and its text is stored at its own
    // path, the way the YAML codec writes it (SpecFieldKind.section).
    final isWrapperSection =
        res.kind == SpecNodeKind.section && res.targetClass == null;
    if (!res.isValueLeaf &&
        res.kind != SpecNodeKind.form &&
        !isWrapperSection) {
      errors.add(
        SpecValidationError(
          path: path,
          code: SpecValidationCode.kindMismatch,
          message:
              'expected a value leaf but path resolves to ${res.kind.name}',
        ),
      );
      continue;
    }
    if (res.kind == SpecNodeKind.scalar) {
      final type = res.field?.type;
      final value = doc.content(path);
      if (!somTypedTextReadable(type, value)) {
        errors.add(
          SpecValidationError(
            path: path,
            code: SpecValidationCode.valueTypeMismatch,
            message:
                'holds "$value", which is not readable as '
                '${somScalarBase(type)}',
          ),
        );
      }
    }
  }

  // 2. Form sections.
  for (final path in sorted(doc.formPaths)) {
    final res = refl.resolve(path);
    if (res == null) {
      errors.add(_dangling(path));
      continue;
    }
    if (res.kind != SpecNodeKind.form || res.field == null) {
      errors.add(
        SpecValidationError(
          path: path,
          code: SpecValidationCode.kindMismatch,
          message:
              'expected a form section but path resolves to ${res.kind.name}',
        ),
      );
      continue;
    }
    final declared = {for (final ff in res.field!.formFields) ff.name: ff};
    for (final name in sorted(doc.formFieldNames(path))) {
      final spec = declared[name];
      if (spec == null) {
        errors.add(
          SpecValidationError(
            path: path,
            code: SpecValidationCode.unknownFormField,
            message: 'form field "$name" is not declared on ${res.field!.name}',
          ),
        );
        continue;
      }
      if (spec.enumValues.isEmpty) {
        final text = doc.formField(path, name);
        // A stated count (`countOf`) is checked by `countMismatch`, which
        // already reports text that is no whole number; one finding is enough.
        if (spec.countOf.isEmpty &&
            spec.productOf.isEmpty &&
            spec.rankOf == null &&
            !somTypedTextReadable(spec.type, text)) {
          errors.add(
            SpecValidationError(
              path: path,
              code: SpecValidationCode.valueTypeMismatch,
              message:
                  'form field "$name" holds "$text", which is not readable '
                  'as ${somScalarBase(spec.type)}',
            ),
          );
        }
        continue;
      }
      final value = doc.formField(path, name);
      // Absence is not a bad value: an empty field is what every other tier
      // reads as "not set", and reporting it here would make a half-filled
      // document unloadable rather than incomplete.
      if (value == null || value.isEmpty) continue;
      if (!spec.enumValues.contains(value)) {
        errors.add(
          SpecValidationError(
            path: path,
            code: SpecValidationCode.enumValueUnknown,
            message:
                'form field "$name" holds "$value", which ${spec.type} does '
                'not declare (${spec.enumValues.join(', ')})',
          ),
        );
      }
    }
    // A form the document holds must fill its required fields; the declared
    // order makes the findings for one form stable.
    final slash = path.lastIndexOf('/');
    final owner = slash > 0
        ? refl.resolve(path.substring(0, slash))?.targetClass?.name
        : null;
    final formName = owner == null
        ? res.field!.name
        : '$owner.${res.field!.name}';
    for (final ff in res.field!.formFields) {
      if (!ff.required) continue;
      final value = doc.formField(path, ff.name)?.trim();
      if (value == null || value.isEmpty) {
        errors.add(
          SpecValidationError(
            path: path,
            code: SpecValidationCode.missingRequiredField,
            message:
                'form field "${ff.name}" is required on $formName but empty',
          ),
        );
      }
    }
  }

  // 3. Lists (container kind + `@Min` count on populated lists).
  for (final path in sorted(doc.listPaths)) {
    final res = refl.resolve(path);
    if (res == null) {
      errors.add(_dangling(path));
      continue;
    }
    if (res.kind != SpecNodeKind.list || res.field == null) {
      errors.add(
        SpecValidationError(
          path: path,
          code: SpecValidationCode.kindMismatch,
          message: 'expected a list but path resolves to ${res.kind.name}',
        ),
      );
      continue;
    }
    final min = res.field!.min;
    final count = doc.listItemCount(path);
    if (min != null && count < min) {
      errors.add(
        SpecValidationError(
          path: path,
          code: SpecValidationCode.minItems,
          message: 'list holds $count item(s) but requires at least $min',
        ),
      );
    }
  }

  // 4. @OneOf discriminated subsection groups (instance tier, csmb6).
  //
  // A concrete `@OneOf` container must carry ONLY the subsections whose `@Case`
  // matches the chosen discriminator value (plus the common, un-`@Case`d ones),
  // and at most one case subsection for the chosen case
  // (`codespecs_mapping.md` §8.2). The static tier (validator.dart) has
  // already checked the annotations are well-formed; here we check a document's
  // *values* against them.
  errors.addAll(_validateOneOfInstances(refl, doc));

  // 5. Cross-registry id references (instance tier, csrb3).
  //
  // A reference form field holds an id that must already be declared by some
  // entry of a target registry. The static tier (validator.dart) has checked
  // the `refersTo` targets are resolvable; only here can we see whether the id
  // a document actually wrote is one the document also declares.
  errors.addAll(_validateReferenceInstances(refl, doc));

  // 6. Stated counts (instance tier, vsctsa43).
  //
  // A form field declaring `countOf` states how many entries the document
  // holds; only the instance tier can count them.
  errors.addAll(_validateCountInstances(refl, doc));
  errors.addAll(_validateDerivedValues(refl, doc));

  return errors;
}

/// The constant part of a qualified `EnumType.constant` `@Case` token (or the
/// whole string when it is not qualified).
String _caseConstant(String token) {
  final dot = token.indexOf('.');
  return dot >= 0 ? token.substring(dot + 1) : token;
}

/// Instance-tier `@OneOf`/`@Case` check (csmb6): for every `@OneOf` container
/// instance present in [doc], verify the populated case subsections match the
/// chosen discriminator value.
List<SpecValidationError> _validateOneOfInstances(
  SpecReflection refl,
  SpecDocument doc,
) {
  final errors = <SpecValidationError>[];

  // Every section-instance path present in the document: each stored value path
  // plus all of its ancestor prefixes (a container's own discriminator form
  // lives at `<container>/content`, so the container path is always a prefix of
  // a populated path).
  final sectionPaths = <String>{};
  void addPrefixes(String full) {
    final segs = full.split('/');
    final buf = StringBuffer();
    for (var i = 0; i < segs.length; i++) {
      if (i > 0) buf.write('/');
      buf.write(segs[i]);
      sectionPaths.add(buf.toString());
    }
  }

  for (final p in doc.contentPaths) {
    addPrefixes(p);
  }
  for (final p in doc.formPaths) {
    addPrefixes(p);
  }
  for (final p in doc.listPaths) {
    addPrefixes(p);
  }
  for (final p in doc.headlinePaths) {
    addPrefixes(p);
  }

  for (final path in sectionPaths.toList()..sort()) {
    final res = refl.resolve(path);
    final cls = res?.targetClass;
    if (cls == null) continue;
    final oneOf = cls.annotation('OneOf');
    if (oneOf == null) continue;
    final discriminator = oneOf.argument('discriminator') as String?;
    if (discriminator == null || discriminator.isEmpty) continue;

    // Read the chosen discriminator value from the container's own @Form.
    SpecField? formHolder;
    for (final f in cls.fields) {
      if (f.kind == SpecFieldKind.form &&
          f.formFields.any((ff) => ff.name == discriminator)) {
        formHolder = f;
        break;
      }
    }
    if (formHolder == null) continue; // static tier flagged the mismatch
    final chosen = doc.formField(
      '$path/${refl.fieldSegment(formHolder)}',
      discriminator,
    );
    if (chosen == null || chosen.isEmpty) continue; // no case chosen yet

    // Inspect each case-bound subsection: present + not-selected → mismatch.
    final presentForChosen = <String>[];
    for (final f in cls.fields) {
      final caseConstants = <String>{
        for (final a in f.annotations)
          if (a.name == 'Case' && a.argument('value') is String)
            _caseConstant(a.argument('value') as String),
      };
      if (caseConstants.isEmpty) continue; // common subsection — always allowed
      final childPath = '$path/${refl.fieldSegment(f)}';
      if (!doc.hasValuesUnder(childPath)) continue;
      if (caseConstants.contains(chosen)) {
        presentForChosen.add(f.name);
      } else {
        errors.add(
          SpecValidationError(
            path: childPath,
            code: SpecValidationCode.oneOfCaseMismatch,
            message:
                'subsection "${f.name}" is present but the chosen '
                '$discriminator="$chosen" does not select it '
                '(cases: ${(caseConstants.toList()..sort()).join(', ')})',
          ),
        );
      }
    }
    if (presentForChosen.length > 1) {
      presentForChosen.sort();
      errors.add(
        SpecValidationError(
          path: path,
          code: SpecValidationCode.oneOfCaseMismatch,
          message:
              'chosen $discriminator="$chosen" selects more than one '
              'populated subsection (${presentForChosen.join(', ')}) — at most '
              'one case subsection may be present',
        ),
      );
    }
  }

  return errors;
}

/// Instance-tier cross-registry reference check (csrb3): every id written into
/// a `refersTo` form field must be declared by some entry of one of its target
/// registries *in this document*.
///
/// The pass is two sweeps over the document's form sections, so it costs one
/// extra walk rather than a resolve per reference:
///
///  1. **Declare.** Every form instance whose class carries `@SectionId(X)` and
///     declares form field `f` contributes its value of `f` to the registry key
///     `X.f`. Every item of a list whose element class carries `@SectionId(X)`
///     additionally contributes its *effective* section id — stored, else
///     positional, see [effectiveListItemSectionId] — to the reserved key
///     `X.@sectionId`. That second half is what makes a registry keeping its id
///     nowhere but the section id (a functional requirement) referenceable at
///     all. Registries are keyed by `<SECTIONID>.<slot>` exactly as
///     `Field.refersTo` writes them, so the lookup is a map hit.
///  2. **Resolve.** Every form instance holding a `refersTo` field checks its
///     value against those sets. A value naming several ids writes them
///     comma-separated, so each segment resolves independently — a single- and
///     a multi-valued reference need no different declaration.
///
/// A value is valid when it resolves in **any** listed registry: some fields
/// legitimately accept an id from more than one (a screen transition outcome is
/// a system error code *or* a validation message template).
///
/// An empty value is not a dangling reference — it means "not filled in yet",
/// which is the schema-completeness concern this validator deliberately leaves
/// to its caller.
///
/// **Cross-document references (csre2).** A reference whose target registry the
/// document's own root cannot reach is skipped rather than reported. Such a
/// reference is a *cross-document* one — a delivery acceptance criterion citing
/// a functional requirement, a screen citing an authorization role — and the
/// registry it names is absent from the document by construction, not
/// undeclared. Reporting it would fail a specification the author wrote
/// correctly. The check therefore runs only where it can actually decide, which
/// is where every target registry is in scope; see [_registryScope]. Its
/// counterpart is a static rule (`tom_specs_model_rules.md` §6.2): every target
/// must be reachable from at least one root that reaches the referring field,
/// so no declaration ends up unverifiable everywhere.
List<SpecValidationError> _validateReferenceInstances(
  SpecReflection refl,
  SpecDocument doc,
) {
  final errors = <SpecValidationError>[];
  final scope = _registryScope(refl, doc);

  // Resolve every form path once; both sweeps read the same resolutions.
  // A form resolution names the form *field*, not a class — the section id a
  // registry key is written against belongs to the class the form sits on, so
  // [_resolvedForms] resolves the owner from the parent path.
  final forms = _resolvedForms(refl, doc);

  // 1. Declare.
  final declared = <String, Set<String>>{};
  for (final form in forms) {
    final sectionId = form.cls.sectionId;
    if (sectionId == null || sectionId.isEmpty) continue;
    for (final ff in form.field.formFields) {
      final value = doc.formField(form.path, ff.name);
      if (value == null || value.trim().isEmpty) continue;
      declared
          .putIfAbsent('$sectionId.${ff.name}', () => <String>{})
          .add(value.trim());
    }
  }

  // 1b. Declare the per-item section ids under the reserved `@sectionId` slot.
  // The key is the *element class's* section id, not the `-LST` container's:
  // a target names the entry, so `FRE.@sectionId` reads as "an id of some
  // functional-requirement entry".
  for (final listPath in doc.listPaths.toList()..sort()) {
    final listRes = refl.resolve(listPath);
    final pattern = listRes?.field?.sectionIdPattern;
    final stem = listRes?.field?.name ?? listPath.split('/').last;
    final items = doc.listItems(listPath);
    for (var i = 0; i < items.length; i++) {
      final elementClass = refl.resolve(items[i])?.targetClass;
      final sectionId = elementClass?.sectionId;
      if (sectionId == null || sectionId.isEmpty) continue;
      declared
          .putIfAbsent('$sectionId.$kSectionIdSlot', () => <String>{})
          .add(
            effectiveListItemSectionId(
              storedId: doc.itemSectionId(items[i]),
              pattern: pattern,
              position: i + 1,
              fallbackStem: stem,
            ),
          );
    }
  }

  // 2. Resolve.
  for (final form in forms) {
    for (final ff in form.field.formFields) {
      if (ff.refersTo.isEmpty) continue;
      final value = doc.formField(form.path, ff.name);
      if (value == null || value.trim().isEmpty) continue;

      // One id, unless the field says it holds several. Decidable without the
      // registries, so it is checked before the scope test below.
      if (!ff.multiple) {
        final ids = [
          for (final s in value.split(','))
            if (s.trim().isNotEmpty) s.trim(),
        ];
        if (ids.length > 1) {
          errors.add(
            SpecValidationError(
              path: form.path,
              code: SpecValidationCode.multipleReferences,
              message:
                  'form field "${ff.name}" holds ${ids.length} references '
                  '(${ids.join(', ')}) but takes one',
            ),
          );
        }
      }

      // Every target must be in scope, not merely one of them: a disjunction
      // says the id may come from any of the listed registries, so one absent
      // registry is enough to make "no registry declares it" unsound — the id
      // could legitimately be declared by the one this document cannot see.
      if (!ff.refersTo.every((t) => scope.contains(_registrySectionId(t)))) {
        continue;
      }

      for (final segment in value.split(',')) {
        final id = segment.trim();
        if (id.isEmpty) continue;
        final resolves = ff.refersTo.any(
          (target) => declared[target]?.contains(id) ?? false,
        );
        if (resolves) continue;
        errors.add(
          SpecValidationError(
            path: form.path,
            code: SpecValidationCode.danglingReference,
            message:
                'form field "${ff.name}" references "$id", which no entry of '
                '${ff.refersTo.length == 1 ? 'registry' : 'registries'} '
                '${ff.refersTo.join(', ')} declares',
          ),
        );
      }
    }
  }

  return errors;
}

/// Instance-tier stated-count check (vsctsa43): every non-empty value of a
/// `countOf` form field must be a whole number equal to the number of entries
/// the document holds.
///
/// An **entry** is a list item whose element class carries `@SectionId(X)`.
/// A target `X` counts every such entry; `X.f=v` counts only the entries one of
/// whose own forms — a form member of the entry, at `<item>/<member>` — holds
/// `v` in form field `f`. The count is the sum over the targets. As with the
/// reference check, a target whose section id the document's root cannot
/// reach makes the field undecidable here, so it is skipped rather than
/// reported, and an empty value is completeness, not a count.
List<SpecValidationError> _validateCountInstances(
  SpecReflection refl,
  SpecDocument doc,
) {
  final forms = _resolvedForms(refl, doc);
  if (!forms.any(
    (f) => f.field.formFields.any((ff) => ff.countOf.isNotEmpty),
  )) {
    return const [];
  }
  final scope = _registryScope(refl, doc);

  // Every entry, by its class's section id, with the form values its own form
  // members hold.
  final entriesById = <String, List<String>>{};
  for (final listPath in doc.listPaths.toList()..sort()) {
    for (final item in doc.listItems(listPath)) {
      final id = refl.resolve(item)?.targetClass?.sectionId;
      if (id == null || id.isEmpty) continue;
      (entriesById[id] ??= []).add(item);
    }
  }
  final valuesByItem = <String, Map<String, Set<String>>>{};
  for (final path in doc.formPaths) {
    final slash = path.lastIndexOf('/');
    if (slash <= 0) continue;
    final owner = path.substring(0, slash);
    final res = refl.resolve(path);
    if (res == null || res.field == null) continue;
    for (final ff in res.field!.formFields) {
      final v = doc.formField(path, ff.name)?.trim();
      if (v == null || v.isEmpty) continue;
      ((valuesByItem[owner] ??= {})[ff.name] ??= {}).add(v);
    }
  }

  // A target written `./…` counts only the entries beneath [owner], the
  // section holding the form; any other target counts the whole document.
  int countTarget(String target, String owner) {
    final scoped = target.startsWith('./');
    if (scoped) target = target.substring(2);
    bool inScope(String item) => !scoped || item.startsWith('$owner/');
    final dot = target.indexOf('.');
    if (dot < 0) {
      return (entriesById[target] ?? const <String>[]).where(inScope).length;
    }
    final id = target.substring(0, dot);
    final eq = target.indexOf('=', dot);
    final field = target.substring(dot + 1, eq < 0 ? target.length : eq);
    final value = eq < 0 ? '' : target.substring(eq + 1);
    return (entriesById[id] ?? const <String>[])
        .where(inScope)
        .where((item) => valuesByItem[item]?[field]?.contains(value) ?? false)
        .length;
  }

  final errors = <SpecValidationError>[];
  for (final form in forms) {
    for (final ff in form.field.formFields) {
      if (ff.countOf.isEmpty) continue;
      final stated = doc.formField(form.path, ff.name)?.trim();
      if (stated == null || stated.isEmpty) continue;
      if (!ff.countOf.every(
        (t) => scope.contains(_registrySectionId(_countTargetId(t))),
      )) {
        continue;
      }
      final owner = form.path.substring(0, form.path.lastIndexOf('/'));
      final counted = ff.countOf
          .map((t) => countTarget(t, owner))
          .fold(0, (a, b) => a + b);
      final targets = ff.countOf.join(' + ');
      if (!RegExp(r'^[0-9]+$').hasMatch(stated)) {
        errors.add(
          SpecValidationError(
            path: form.path,
            code: SpecValidationCode.countMismatch,
            message:
                'form field "${ff.name}" states "$stated", which is not a whole '
                'number — it counts $targets, of which the document holds '
                '$counted',
          ),
        );
      } else if (int.parse(stated) != counted) {
        errors.add(
          SpecValidationError(
            path: form.path,
            code: SpecValidationCode.countMismatch,
            message:
                'form field "${ff.name}" states $stated, but the document '
                'holds $counted (counting $targets)',
          ),
        );
      }
    }
  }
  return errors;
}

/// Instance-tier derived-value check (uamtc10): a `productOf` field must hold
/// the product of its operands, and a `rankOf` field must rank the instances
/// of its form by their score, highest first.
///
/// **Operands.** A plain operand is a field of the same form; `F.x` is field
/// `x` of the form `F` beside it, at `<owner>/F` where `<owner>` is the
/// section holding this form. A numeric operand contributes its number, an
/// enum operand its 1-based position among the enum's values. When the value
/// or any operand is empty — or an operand is unreadable, which other checks
/// report — the product is undecidable and is skipped.
///
/// **Precision.** The stated number is held to the precision it is written
/// in: `2.8` matches 0.7 × 4.0, and `15` matches 3 × 5, but `2.9` does not.
///
/// **Ranks.** Over every instance of the same form whose rank and score are
/// both filled, the ranks must be the whole numbers 1 to n, each once, and an
/// instance may not rank below one that scores lower. Equal scores take their
/// ranks in any order. Each offending instance is reported once.
List<SpecValidationError> _validateDerivedValues(
  SpecReflection refl,
  SpecDocument doc,
) {
  final forms = _resolvedForms(refl, doc);
  if (!forms.any(
    (f) => f.field.formFields.any(
      (ff) => ff.productOf.isNotEmpty || ff.rankOf != null,
    ),
  )) {
    return const [];
  }
  final errors = <SpecValidationError>[];
  final numberPattern = RegExp(r'^-?[0-9]+(\.[0-9]+)?$');

  // The number a filled form field contributes, or null when it is empty or
  // unreadable.
  double? numberOf(String formPath, FormFieldSpec spec) {
    final v = doc.formField(formPath, spec.name)?.trim();
    if (v == null || v.isEmpty) return null;
    if (spec.enumValues.isNotEmpty) {
      final i = spec.enumValues.indexOf(v);
      return i < 0 ? null : (i + 1).toDouble();
    }
    return numberPattern.hasMatch(v) ? double.parse(v) : null;
  }

  // The form at [path] and the spec of its field [name], or null.
  FormFieldSpec? specAt(String path, String name) {
    final res = refl.resolve(path);
    if (res == null || res.kind != SpecNodeKind.form) return null;
    for (final ff in res.field?.formFields ?? const <FormFieldSpec>[]) {
      if (ff.name == name) return ff;
    }
    return null;
  }

  final ranked =
      <
        String,
        List<({String path, String name, String stated, double score})>
      >{};

  for (final form in forms) {
    final owner = form.path.substring(0, form.path.lastIndexOf('/'));
    for (final ff in form.field.formFields) {
      if (ff.productOf.isNotEmpty) {
        final stated = doc.formField(form.path, ff.name)?.trim();
        if (stated != null && stated.isNotEmpty) {
          double? product = 1;
          for (final operand in ff.productOf) {
            final dot = operand.indexOf('.');
            final path = dot < 0
                ? form.path
                : '$owner/${operand.substring(0, dot)}';
            final name = dot < 0 ? operand : operand.substring(dot + 1);
            final spec = specAt(path, name);
            final n = spec == null ? null : numberOf(path, spec);
            if (n == null) {
              product = null;
              break;
            }
            product = product! * n;
          }
          final operands = ff.productOf.join(' × ');
          if (!numberPattern.hasMatch(stated)) {
            errors.add(
              SpecValidationError(
                path: form.path,
                code: SpecValidationCode.derivedValueMismatch,
                message:
                    'form field "${ff.name}" states "$stated", which is not a '
                    'number — it is the product $operands',
              ),
            );
          } else if (product != null) {
            final dot = stated.indexOf('.');
            final decimals = dot < 0 ? 0 : stated.length - dot - 1;
            final tolerance = 0.5 * _pow10(-decimals) + 1e-9;
            if ((double.parse(stated) - product).abs() > tolerance) {
              errors.add(
                SpecValidationError(
                  path: form.path,
                  code: SpecValidationCode.derivedValueMismatch,
                  message:
                      'form field "${ff.name}" states $stated, but $operands '
                      'gives ${_formatNumber(product)}',
                ),
              );
            }
          }
        }
      }
      final by = ff.rankOf;
      if (by != null) {
        final stated = doc.formField(form.path, ff.name)?.trim();
        final scoreSpec = specAt(form.path, by);
        final score = scoreSpec == null ? null : numberOf(form.path, scoreSpec);
        if (stated != null && stated.isNotEmpty && score != null) {
          (ranked['${form.cls.name}#${form.field.name}#${ff.name}'] ??= []).add(
            (path: form.path, name: ff.name, stated: stated, score: score),
          );
        }
      }
    }
  }

  for (final group in ranked.values) {
    final n = group.length;
    final rankOf = <String, int>{};
    final seen = <int, int>{};
    for (final e in group) {
      if (!RegExp(r'^[0-9]+$').hasMatch(e.stated)) continue;
      final r = int.parse(e.stated);
      rankOf[e.path] = r;
      seen[r] = (seen[r] ?? 0) + 1;
    }
    for (final e in group) {
      final r = rankOf[e.path];
      String? problem;
      if (r == null) {
        problem = 'states "${e.stated}", which is not a whole number';
      } else if (r < 1 || r > n || seen[r]! > 1) {
        problem =
            'states rank $r, but the $n ranked entries take the ranks '
            '1 to $n, each once';
      } else {
        for (final o in group) {
          final ro = rankOf[o.path];
          if (ro != null && o.score < e.score && ro < r) {
            problem =
                'ranks $r with score ${_formatNumber(e.score)}, below '
                'an entry ranked $ro with the lower score '
                '${_formatNumber(o.score)}';
            break;
          }
        }
      }
      if (problem != null) {
        errors.add(
          SpecValidationError(
            path: e.path,
            code: SpecValidationCode.derivedValueMismatch,
            message: 'form field "${e.name}" $problem',
          ),
        );
      }
    }
  }
  // Like every phase's group, the findings are ordered by path; the sort is
  // stable, so a path's own findings keep the order they were found in.
  final ordered = [for (var i = 0; i < errors.length; i++) (i, errors[i])]
    ..sort((a, b) {
      final byPath = a.$2.path.compareTo(b.$2.path);
      return byPath != 0 ? byPath : a.$1.compareTo(b.$1);
    });
  return [for (final e in ordered) e.$2];
}

double _pow10(int exponent) {
  var v = 1.0;
  for (var i = 0; i < exponent.abs(); i++) {
    v *= 10;
  }
  return exponent < 0 ? 1 / v : v;
}

String _formatNumber(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// The section id of a `countOf` target — the part before any `.field=value`,
/// without the `./` scope prefix.
String _countTargetId(String target) {
  if (target.startsWith('./')) target = target.substring(2);
  final dot = target.indexOf('.');
  return dot < 0 ? target : target.substring(0, dot);
}

/// Every form instance in [doc] with its field and the class it sits on, in
/// path order — the shape both the reference and the count check sweep.
List<({String path, SpecClass cls, SpecField field})> _resolvedForms(
  SpecReflection refl,
  SpecDocument doc,
) {
  final forms = <({String path, SpecClass cls, SpecField field})>[];
  for (final path in doc.formPaths.toList()..sort()) {
    final res = refl.resolve(path);
    if (res == null || res.kind != SpecNodeKind.form || res.field == null) {
      continue;
    }
    final slash = path.lastIndexOf('/');
    if (slash <= 0) continue;
    final cls = refl.resolve(path.substring(0, slash))?.targetClass;
    if (cls == null) continue;
    forms.add((path: path, cls: cls, field: res.field!));
  }
  return forms;
}

/// The section id part of a registry key written `<SECTIONID>.<slot>`. A key
/// with no dot is malformed — the static tier reports it — and is treated whole
/// here so it simply fails to match any section id.
String _registrySectionId(String target) {
  final dot = target.indexOf('.');
  return dot <= 0 ? target : target.substring(0, dot);
}

/// The registry section ids that are **in scope** for [doc]: the `@SectionId`
/// of every class reachable from a document root the document actually uses
/// (csre2).
///
/// A `refersTo` target names its registry by section id, and a document can
/// only ever declare entries of registries its own root reaches. Anything
/// outside this set is absent from the document by construction — which is
/// precisely the case the dangling-reference check must not call an error.
///
/// The roots are read off the document rather than passed in: every path begins
/// with its root's segment, so the document already says which root(s) it
/// belongs to and no caller has to know. A document spanning several roots
/// (the whole-project container) contributes the union, which is what makes a
/// project-wide validation see every sibling registry.
Set<String> _registryScope(SpecReflection refl, SpecDocument doc) {
  final rootTypes = <String>{};
  void addRootOf(String path) {
    final slash = path.indexOf('/');
    final segment = slash < 0 ? path : path.substring(0, slash);
    final root = refl.rootForSegment(segment);
    if (root != null) rootTypes.add(root.type);
  }

  for (final p in doc.contentPaths) {
    addRootOf(p);
  }
  for (final p in doc.formPaths) {
    addRootOf(p);
  }
  for (final p in doc.listPaths) {
    addRootOf(p);
  }
  for (final p in doc.headlinePaths) {
    addRootOf(p);
  }

  final ids = <String>{};
  for (final type in rootTypes) {
    for (final name in refl.reachableClassNames(type)) {
      final id = refl.classNamed(name)?.sectionId;
      if (id != null && id.isNotEmpty) ids.add(id);
    }
  }
  return ids;
}

SpecValidationError _dangling(String path) => SpecValidationError(
  path: path,
  code: SpecValidationCode.danglingPath,
  message: 'path does not resolve to any model node',
);
