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
}

/// One problem found while validating a document.
class SpecValidationError {
  /// The document path the problem is anchored at.
  final String path;

  /// The category of problem.
  final SpecValidationCode code;

  /// A human-readable description.
  final String message;

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
    if (!res.isValueLeaf) {
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.kindMismatch,
        message: 'expected a value leaf but path resolves to ${res.kind.name}',
      ));
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
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.kindMismatch,
        message: 'expected a form section but path resolves to ${res.kind.name}',
      ));
      continue;
    }
    final declared = {for (final ff in res.field!.formFields) ff.name};
    for (final name in sorted(doc.formFieldNames(path))) {
      if (!declared.contains(name)) {
        errors.add(SpecValidationError(
          path: path,
          code: SpecValidationCode.unknownFormField,
          message: 'form field "$name" is not declared on ${res.field!.name}',
        ));
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
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.kindMismatch,
        message: 'expected a list but path resolves to ${res.kind.name}',
      ));
      continue;
    }
    final min = res.field!.min;
    final count = doc.listItemCount(path);
    if (min != null && count < min) {
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.minItems,
        message: 'list holds $count item(s) but requires at least $min',
      ));
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
    final chosen =
        doc.formField('$path/${refl.fieldSegment(formHolder)}', discriminator);
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
        errors.add(SpecValidationError(
          path: childPath,
          code: SpecValidationCode.oneOfCaseMismatch,
          message: 'subsection "${f.name}" is present but the chosen '
              '$discriminator="$chosen" does not select it '
              '(cases: ${(caseConstants.toList()..sort()).join(', ')})',
        ));
      }
    }
    if (presentForChosen.length > 1) {
      presentForChosen.sort();
      errors.add(SpecValidationError(
        path: path,
        code: SpecValidationCode.oneOfCaseMismatch,
        message: 'chosen $discriminator="$chosen" selects more than one '
            'populated subsection (${presentForChosen.join(', ')}) — at most '
            'one case subsection may be present',
      ));
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
List<SpecValidationError> _validateReferenceInstances(
  SpecReflection refl,
  SpecDocument doc,
) {
  final errors = <SpecValidationError>[];

  // Resolve every form path once; both sweeps read the same resolutions.
  //
  // A form resolution names the form *field*, not a class — the section id a
  // registry key is written against belongs to the class the form sits on, so
  // the owner is resolved from the parent path (root, complex, section and
  // list-item resolutions all carry their class).
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
      declared.putIfAbsent('$sectionId.$kSectionIdSlot', () => <String>{}).add(
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

      for (final segment in value.split(',')) {
        final id = segment.trim();
        if (id.isEmpty) continue;
        final resolves =
            ff.refersTo.any((target) => declared[target]?.contains(id) ?? false);
        if (resolves) continue;
        errors.add(SpecValidationError(
          path: form.path,
          code: SpecValidationCode.danglingReference,
          message: 'form field "${ff.name}" references "$id", which no entry of '
              '${ff.refersTo.length == 1 ? 'registry' : 'registries'} '
              '${ff.refersTo.join(', ')} declares',
        ));
      }
    }
  }

  return errors;
}

SpecValidationError _dangling(String path) => SpecValidationError(
      path: path,
      code: SpecValidationCode.danglingPath,
      message: 'path does not resolve to any model node',
    );
