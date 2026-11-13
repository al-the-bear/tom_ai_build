/// One generation unit's share of an IR document set (`irspecs_ir.md` §8.1):
/// what `irspecs map --unit` writes.
///
/// A unit is a package of one kind — shared, client or server, the three loci
/// of the trio — whose register entry names, per area, the mapper that writes
/// it (SOM §11.2, `codespecs_mapping.md` §1.1.1 item 4). Its files are the IR
/// files of its locus in the documents of the areas the given mapper holds for
/// it, plus the `package` document's files of its locus, less any file whose
/// own `units` leaves it out.
library;

import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show SpecGenerationUnit;

import '../codespecs/cs_model.dart';
import 'ir_model.dart';

/// A generation unit as the mapper sees it.
class IrUnit {
  /// The unit's id, which is also the package it is written into.
  final String unitId;

  /// The trio locus whose IR files the unit takes.
  final CsLocus locus;

  /// The mapper of each area the unit holds: area code → mapper id.
  final Map<String, String> mappings;

  /// Creates a unit.
  const IrUnit({
    required this.unitId,
    required this.locus,
    required this.mappings,
  });

  /// The unit a register entry declares. Throws [IrSpecsException] when its
  /// kind is not one of the trio's three loci: a unit of kind `other` has no
  /// IR files to take.
  factory IrUnit.fromRegister(SpecGenerationUnit unit) {
    final locus = CsLocus.values.where((l) => l.name == unit.kind);
    if (locus.isEmpty) {
      throw IrSpecsException(
        'generation unit "${unit.unitId}" is of kind '
        '"${unit.kind.isEmpty ? '(none)' : unit.kind}"; only shared, client '
        'and server units are written from the IR',
      );
    }
    return IrUnit(
      unitId: unit.unitId,
      locus: locus.single,
      mappings: {for (final m in unit.mappings.reversed) m.area: m.mapping},
    );
  }
}

/// The share of [documents] that [mapper] writes for [unit]: per document, the
/// files of the unit's locus — for an area document only when the unit maps
/// that area to [mapper], for the `package` document always — that either
/// carry no `units` or name the unit. Each document's project of the unit's
/// locus is renamed to the unit's id and is its only project, so the mapper
/// writes the unit's package and nothing else. Documents left without a file
/// are dropped.
List<IrDocument> irDocumentsForUnit(
  List<IrDocument> documents,
  IrUnit unit, {
  required String mapper,
}) => [
  for (final d in documents)
    if (d.area == kIrPackageArea || unit.mappings[d.area] == mapper)
      if (_filesFor(d, unit) case final files when files.isNotEmpty)
        IrDocument(
          area: d.area,
          projects: [IrProject(unit.locus, unit.unitId)],
          files: files,
        ),
];

List<IrFile> _filesFor(IrDocument d, IrUnit unit) => [
  for (final f in d.files)
    if (f.locus == unit.locus &&
        (f.units.isEmpty || f.units.contains(unit.unitId)))
      f,
];
