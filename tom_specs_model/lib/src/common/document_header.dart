import 'package:tom_specs_core/tom_specs_core.dart';

import '../snapshot/spec_node.dart';

/// Standard document header present at the top of every TomSpecs document.
///
/// All fields are optional strings representing the document's form fields.
///
/// A leaf [SpecNode]: it owns only a scalar [content] field, so snapshots share
/// an unchanged header by identity and [cloneShallow] needs no child handling.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — document front matter and identification'],
  'The standard document control header identifying the document, its project, version, date, author, and status.',
)
@SectionId('DOCHD')
class DocumentHeader extends DocSpecsSection with SpecNode {
  @Form([
    Field('documentId', String, 'Document Id'),
    Field('project', String, 'Project'),
    Field('version', String, 'Version'),
    Field('date', String, 'Date'),
    Field('author', String, 'Author'),
    Field('status', String, 'Current status'),
  ])
  @override
  @SerializationOrder(0)
  String? content;

  @override
  DocumentHeader cloneShallow() => DocumentHeader()..content = content;

  @override
  String? yamlScalar() => content;
}
