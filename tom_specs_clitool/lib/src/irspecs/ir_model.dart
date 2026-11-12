/// The IR Specs intermediate representation (`irspecs_ir.md`): everything a
/// CodeSpecs trio expresses, as language-neutral data, one document per area.
///
/// The IR does not have a second set of value classes. Its content is the
/// [CsModel](cs_model.dart) reading of the trio — declarations, markers and
/// their argument values, back-links, doc comments, bodies and statements —
/// and this library adds only the envelope that makes it a document set: which
/// area a file belongs to ([IrDocument.area]), which project it sits in
/// ([IrFile.locus], [IrFile.packageName]) and the three projects' names
/// ([IrDocument.projects]). Keeping one model means a field added to CsModel
/// reaches the IR by being written into the codec (`ir_codec.dart`), and the
/// field-coverage test fails until it is.
library;

import 'package:path/path.dart' as p;
import 'package:tom_som_dart_runtime/tom_som_dart_runtime.dart'
    show CodeSpecsAreaCatalog;

import '../codespecs/cs_model.dart';
import 'ir_steps.dart';

/// The `format` of an IR document.
const String kIrSpecsFormat = 'irspecs-ir';

/// The `formatVersion` of an IR document. Bumped only on a change an older
/// reader cannot read.
const int kIrSpecsFormatVersion = 1;

/// The [IrDocument.area] of the document holding the files no area claims —
/// a project's barrel library, for one.
const String kIrPackageArea = 'package';

/// The file name of the IR document for [area]: `<CE-CODE>.ir.yaml`, or
/// `package.ir.yaml`.
String irDocumentFileName(String area) => '$area.ir.yaml';

/// One project of the trio, named in every document's header so a single
/// document still says which package each locus is.
class IrProject {
  /// Which project.
  final CsLocus locus;

  /// Its package name.
  final String packageName;

  /// Creates a project entry.
  const IrProject(this.locus, this.packageName);
}

/// One generated file in an IR document: its place, and the CsModel reading of
/// its content.
class IrFile {
  /// The project the file belongs to.
  final CsLocus locus;

  /// The file's CsModel reading. Its `source` is not carried by the IR (see
  /// `irspecs_ir.md`, § Every field, and the one left out): a file read back from the IR
  /// has an empty source.
  final CsFile file;

  /// The steps of the file's form-3b bodies (`irspecs_ir.md`, § Steps), one
  /// record per body — or the B-rule that kept a body from being steps.
  final List<IrBodySteps> steps;

  /// Creates a file entry.
  const IrFile(this.locus, this.file, [this.steps = const []]);
}

/// One IR document: the files of one area, across the three projects.
class IrDocument {
  /// The area code (`CE-DB`), or [kIrPackageArea].
  final String area;

  /// The trio's three projects, in emission order (shared, client, server).
  final List<IrProject> projects;

  /// The area's files, ordered by project (emission order), then by path.
  final List<IrFile> files;

  /// Creates a document.
  const IrDocument({
    required this.area,
    required this.projects,
    required this.files,
  });

  /// The file name this document is written to.
  String get fileName => irDocumentFileName(area);
}

/// Raised when an IR document set cannot be turned back into a trio.
class IrSpecsException implements Exception {
  /// What is wrong.
  final String message;

  /// Creates the exception.
  const IrSpecsException(this.message);

  @override
  String toString() => 'IrSpecsException: $message';
}

/// Which area a generated file belongs to, decided from the area catalogue.
///
/// Four rules, first match wins (`irspecs_ir.md`, § One document per area):
///
/// 1. **The folder.** `codespecs_derivation_contract.md` §2.1 N7 writes a
///    part's files under `lib/src/<canonical id, snake_case>/`, so a file
///    there belongs to that canonical id's area.
/// 2. **The back-links.** Otherwise the first `@CodeSpec` id in the file, in
///    source order, names its part before the dot (`serverApi.OrderDto`), and
///    the file belongs to that part's area. A trio written before N7 settled
///    its folder names (`api/`, `error/`) still sorts correctly, the
///    marker-less DTOs and the result envelope included.
/// 3. **The markers.** Otherwise the first part marker written in the file
///    names the area whose annotations include it.
/// 4. Otherwise the file belongs to no area and goes into [kIrPackageArea].
class IrAreaIndex {
  final Map<String, String> _byFolder;
  final Map<String, String> _byPart;
  final Map<String, String> _byMarker;
  final List<String> _order;

  IrAreaIndex._(this._byFolder, this._byPart, this._byMarker, this._order);

  /// Builds the index from [catalog]'s areas.
  factory IrAreaIndex(CodeSpecsAreaCatalog catalog) {
    final byFolder = <String, String>{};
    final byPart = <String, String>{};
    final byMarker = <String, String>{};
    final order = <String>[];
    for (final area in catalog.areas) {
      order.add(area.code);
      byFolder[snakeCase(area.canonicalId)] = area.code;
      byPart[area.part] = area.code;
      for (final annotation in area.annotations) {
        byMarker.putIfAbsent(annotation, () => area.code);
      }
    }
    return IrAreaIndex._(byFolder, byPart, byMarker, order);
  }

  /// The area codes in catalogue order — the order documents are written in.
  List<String> get areaOrder => List.unmodifiable(_order);

  /// The area of [file].
  String areaOf(CsFile file) {
    final segments = p.posix.split(file.path.replaceAll(r'\', '/'));
    final src = segments.indexOf('src');
    if (src >= 0 && src + 2 < segments.length) {
      final byFolder = _byFolder[segments[src + 1]];
      if (byFolder != null) return byFolder;
    }
    final links = [for (final d in file.declarations) ?d.codeSpec]
      ..sort((a, b) => a.location.line.compareTo(b.location.line));
    for (final link in links) {
      final area = _byPart[link.canonicalId];
      if (area != null) return area;
    }
    final markers = [for (final d in file.declarations) ...d.markers]
      ..sort((a, b) => a.location.line.compareTo(b.location.line));
    for (final marker in markers) {
      final area = _byMarker[marker.name];
      if (area != null) return area;
    }
    return kIrPackageArea;
  }
}

/// `DataAccess` → `data_access`: the N7 folder of a canonical id.
String snakeCase(String pascal) => pascal
    .replaceAllMapped(RegExp('(?<=[a-z0-9])([A-Z])'), (m) => '_${m.group(1)}')
    .toLowerCase();

/// The IR of a CodeSpecs trio: one [IrDocument] per area holding files, in
/// catalogue order, then the [kIrPackageArea] document when any file is in it.
///
/// Areas with no file get no document.
List<IrDocument> irFromCsModel({
  required CsLocusProject shared,
  required CsLocusProject client,
  required CsLocusProject server,
  required IrAreaIndex areas,
}) {
  final trio = [shared, client, server];
  final projects = [
    for (final project in trio) IrProject(project.locus, project.packageName),
  ];
  final byArea = <String, List<IrFile>>{};
  for (final project in trio) {
    final files = [...project.files]..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      byArea
          .putIfAbsent(areas.areaOf(file), () => [])
          .add(IrFile(project.locus, file, stepBodiesOf(file)));
    }
  }
  return [
    for (final area in [...areas.areaOrder, kIrPackageArea])
      if (byArea[area] != null)
        IrDocument(area: area, projects: projects, files: byArea[area]!),
  ];
}

/// The trio an IR document set describes — the inverse of [irFromCsModel],
/// except for each file's `source`, which the IR does not carry.
///
/// Throws [IrSpecsException] when [documents] is empty or its documents name
/// different projects.
({CsLocusProject shared, CsLocusProject client, CsLocusProject server})
csModelFromIr(List<IrDocument> documents) {
  if (documents.isEmpty) {
    throw const IrSpecsException('no IR document to read the trio from');
  }
  final names = {
    for (final project in documents.first.projects)
      project.locus: project.packageName,
  };
  for (final document in documents.skip(1)) {
    for (final project in document.projects) {
      if (names[project.locus] != project.packageName) {
        throw IrSpecsException(
          '${document.fileName} names ${project.locus.label} package '
          '"${project.packageName}", another document "${names[project.locus]}"',
        );
      }
    }
  }
  CsLocusProject project(CsLocus locus) {
    final name = names[locus];
    if (name == null) {
      throw IrSpecsException('no document names the ${locus.label} package');
    }
    final files = [
      for (final document in documents)
        for (final entry in document.files)
          if (entry.locus == locus) entry.file,
    ]..sort((a, b) => a.path.compareTo(b.path));
    return CsLocusProject(locus: locus, packageName: name, files: files);
  }

  return (
    shared: project(CsLocus.shared),
    client: project(CsLocus.client),
    server: project(CsLocus.server),
  );
}
