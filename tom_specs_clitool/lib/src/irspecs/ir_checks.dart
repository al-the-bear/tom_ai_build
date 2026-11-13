/// The forty-four CodeSpecs checks (`codespecs_derivation_contract.md` §6) on
/// the IR (`irspecs_ir.md` §7): the trio an IR document set describes, in the
/// CsModel shape the checks read.
///
/// The checks need no change to run here. An IR document *is* the CsModel
/// reading of a trio, so [csModelFromIr] gives every check the model it reads
/// from Dart — with one field different: a file's `source`, which the IR does
/// not carry. Only check 31 reads it, comparing two generation runs; on the IR
/// the two runs are two IR document sets, so a file's `source` here is its IR
/// record, and check 31 compares records. Whatever the IR holds is compared;
/// the layout, which `codespecs_derivation_contract.md` §2.7 leaves to
/// `dart format`, is not.
library;

import 'dart:convert';

import '../codespecs/cs_model.dart';
import 'ir_codec.dart';
import 'ir_model.dart';

/// The trio [documents] describe, each file's `source` its IR record.
({CsLocusProject shared, CsLocusProject client, CsLocusProject server})
csModelForChecks(List<IrDocument> documents) {
  final records = <String, String>{
    for (final document in documents)
      for (final entry in document.files)
        '${entry.locus.name}:${entry.file.path}': const JsonEncoder.withIndent(
          '  ',
        ).convert(irFileToData(entry)),
  };
  CsLocusProject withRecords(CsLocusProject project) => CsLocusProject(
    locus: project.locus,
    packageName: project.packageName,
    files: [
      for (final f in project.files)
        CsFile(
          path: f.path,
          source: records['${project.locus.name}:${f.path}'] ?? '',
          imports: f.imports,
          exports: f.exports,
          declarations: f.declarations,
          constructions: f.constructions,
          comments: f.comments,
        ),
    ],
  );
  final trio = csModelFromIr(documents);
  return (
    shared: withRecords(trio.shared),
    client: withRecords(trio.client),
    server: withRecords(trio.server),
  );
}
