import 'package:tom_specs_core/tom_specs_core.dart';

import '../snapshot/spec_node.dart';

/// Standard document header present at the top of every TomSpecs document.
///
/// All fields are optional strings representing the document's form fields.
/// The revision history is the holder of the document's version, date and
/// author: the header shows those of its newest revision entry (`RVENT`, the
/// last of the list, which is ordered newest last), derived from each
/// document's own history. A document without a revision entry derives
/// nothing. The id, the project and the status are the header's own.
///
/// A leaf `SpecNode`: it owns only a scalar [content] field, so snapshots share
/// an unchanged header by identity and `cloneShallow` needs no child handling.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — document front matter and identification'],
  'The standard document control header identifying the document, its project, version, date, author, and status.',
)
@SectionId('DOCHD')
@FollowUpKind(
  [FollowUpProcess.doc],
  note:
      'front matter — it identifies the document, not the system. Reached '
      'under DocumentControl in the SBP and directly as the header of each '
      'of the other thirteen @Document roots; the doc process owns it on '
      'every one of those paths',
)
class DocumentHeader extends DocSpecsSection with SpecNode {
  @Form([
    Field('documentId', String, 'Document Id'),
    Field('project', String, 'Project'),
    Field(
      'version',
      String,
      'Version',
      hint:
          'Derived from the newest revision entry; add a revision, not this '
          'field.',
      derivedFrom: DerivedFrom.lookup('RVENT', take: ['RVENT.version']),
    ),
    Field(
      'date',
      String,
      'Date',
      hint:
          'Derived from the newest revision entry; add a revision, not this '
          'field.',
      derivedFrom: DerivedFrom.lookup('RVENT', take: ['RVENT.date']),
    ),
    Field(
      'author',
      String,
      'Author',
      hint:
          'Derived from the newest revision entry; add a revision, not this '
          'field.',
      derivedFrom: DerivedFrom.lookup('RVENT', take: ['RVENT.author']),
    ),
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
