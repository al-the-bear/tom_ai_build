/// The generation-unit register of a document (SOM §11.2): the units Phase 4
/// writes code into, each with the mapper of every area it holds.
///
/// The register is recognised by its annotations, never by class name, exactly
/// as validation phase 8 recognises it: a **unit** is a list item whose class
/// carries `@NoArtifact(generation)` and declares the form field `unitId`; a
/// **mapping** is such a list item declaring the form field `area`, and belongs
/// to the nearest unit whose path is a prefix of its own; an **emitter** is
/// such a list item declaring the form field `emitter`, and belongs to its
/// unit the same way.
library;

import 'spec_document.dart';
import 'spec_model.dart';
import 'spec_paths.dart';
import 'spec_reflection.dart';

/// One mapping of a generation unit: the area it holds and the mapper that
/// writes that area's code for it.
class SpecGenerationUnitMapping {
  /// The area code, `CE-…`, as stored (trimmed).
  final String area;

  /// The mapper id, e.g. `dart-tom`, as stored (trimmed); empty when unset.
  final String mapping;

  /// Creates a mapping of [area] by [mapping].
  const SpecGenerationUnitMapping({required this.area, required this.mapping});
}

/// The standard emitters a unit's `emitters` may name (`irspecs_ir.md` §10),
/// in the order `irspecs emit` lists them. Validation phase 8 reports any other
/// id as `unitEmitterUnknown`.
const List<String> kSpecStandardEmitters = [
  'openapi',
  'jsonschema',
  'icu',
  'asyncapi',
];

/// One generation unit the document declares.
class SpecGenerationUnit {
  /// The unit's id — what a section's `units` names, usually the package name.
  final String unitId;

  /// `client`, `server`, `shared` or `other`, as stored; empty when unset.
  final String kind;

  /// The unit's list-item path in the document.
  final String path;

  /// The unit's mappings, in stored order.
  final List<SpecGenerationUnitMapping> mappings;

  /// The standard emitters the unit ships (`irspecs_ir.md` §10), as stored
  /// (trimmed), in stored order; an emitter with no id is left out.
  final List<String> emitters;

  /// Creates a unit.
  const SpecGenerationUnit({
    required this.unitId,
    required this.kind,
    required this.path,
    required this.mappings,
    this.emitters = const [],
  });

  /// Whether one of the unit's mappings holds [areaCode].
  bool maps(String areaCode) => mappings.any((m) => m.area == areaCode);

  /// The mapper of [areaCode] — the first mapping that holds it — or `null`.
  String? mappingFor(String areaCode) {
    for (final m in mappings) {
      if (m.area == areaCode) return m.mapping;
    }
    return null;
  }
}

/// The generation units [doc] declares, in register order: sorted list-path
/// order, each list's items in their stored order — the order validation phase
/// 8 visits them in. A unit without a `unitId` is left out; a second unit with
/// an id already seen is left out too (phase 8 reports it as
/// `duplicateUnitId`). A document without a register declares none.
List<SpecGenerationUnit> specGenerationUnits(
  SpecModel model,
  SpecDocument doc,
) {
  final refl = SpecReflection(model);
  final units = <({String id, String kind, String path})>[];
  final mappings = <({String path, String area, String mapping})>[];
  final emitters = <({String path, String emitter})>[];
  for (final listPath in doc.listPaths.toList()..sort()) {
    for (final item in doc.listItems(listPath)) {
      final cls = refl.resolve(item)?.targetClass;
      if (cls == null || cls.noArtifact?.reason != 'generation') continue;
      final unitForm = _formDeclaring(cls, 'unitId');
      if (unitForm != null) {
        final formPath = specPathJoin(item, refl.fieldSegment(unitForm));
        final id = doc.formField(formPath, 'unitId')?.trim() ?? '';
        if (id.isNotEmpty) {
          units.add((
            id: id,
            kind: doc.formField(formPath, 'kind')?.trim() ?? '',
            path: item,
          ));
        }
      }
      final areaForm = _formDeclaring(cls, 'area');
      if (areaForm != null) {
        final formPath = specPathJoin(item, refl.fieldSegment(areaForm));
        final area = doc.formField(formPath, 'area')?.trim() ?? '';
        if (area.isNotEmpty) {
          mappings.add((
            path: item,
            area: area,
            mapping: doc.formField(formPath, 'mapping')?.trim() ?? '',
          ));
        }
      }
      final emitterForm = _formDeclaring(cls, 'emitter');
      if (emitterForm != null) {
        final formPath = specPathJoin(item, refl.fieldSegment(emitterForm));
        final emitter = doc.formField(formPath, 'emitter')?.trim() ?? '';
        if (emitter.isNotEmpty) {
          emitters.add((path: item, emitter: emitter));
        }
      }
    }
  }

  final seen = <String>{};
  return [
    for (final u in units)
      if (seen.add(u.id))
        SpecGenerationUnit(
          unitId: u.id,
          kind: u.kind,
          path: u.path,
          mappings: [
            for (final m in mappings)
              if (_owner(m.path, units) == u.path)
                SpecGenerationUnitMapping(area: m.area, mapping: m.mapping),
          ],
          emitters: [
            for (final e in emitters)
              if (_owner(e.path, units) == u.path) e.emitter,
          ],
        ),
  ];
}

/// The units of [units] whose mappings hold [areaCode], in register order —
/// the default destination of a section routed to that area (SOM §11.2).
List<String> specDefaultUnits(
  List<SpecGenerationUnit> units,
  String areaCode,
) => [
  for (final u in units)
    if (u.maps(areaCode)) u.unitId,
];

/// The path of the unit a mapping or emitter at [mappingPath] belongs to: the longest unit
/// path that is a proper prefix of it, or `null`.
String? _owner(
  String mappingPath,
  List<({String id, String kind, String path})> units,
) {
  String? best;
  for (final u in units) {
    if (mappingPath.startsWith('${u.path}/') &&
        (best == null || u.path.length > best.length)) {
      best = u.path;
    }
  }
  return best;
}

/// The form field of [cls] that declares a form field named [name], or `null`.
SpecField? _formDeclaring(SpecClass cls, String name) {
  for (final f in cls.fields) {
    if (f.kind == SpecFieldKind.form &&
        f.formFields.any((ff) => ff.name == name)) {
      return f;
    }
  }
  return null;
}
