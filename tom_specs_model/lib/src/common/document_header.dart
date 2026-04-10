import 'package:tom_specs_core/tom_specs_core.dart';


/// Standard document header present at the top of every TomSpecs document.
///
/// All fields are optional strings representing the document's form fields.
class DocumentHeader {
  @Form([
    Field('documentId', String, 'Document Id'),
    Field('project', String, 'Project'),
    Field('version', String, 'Version'),
    Field('date', String, 'Date'),
    Field('author', String, 'Author'),
    Field('status', String, 'Current status'),
  ])

  String? content;
}
