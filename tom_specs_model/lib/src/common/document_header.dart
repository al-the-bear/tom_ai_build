import 'package:tom_core_kernel/tom_core_kernel.dart';

/// Standard document header present at the top of every TomSpecs document.
///
/// All fields are optional strings representing the document's form fields.
@tomReflector
class DocumentHeader {
  String? content;
  String? documentId;
  String? project;
  String? version;
  String? date;
  String? author;
  String? status;
}
