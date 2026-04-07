/// Standard document header present at the top of every TomSpecs document.
///
/// All fields are optional strings representing the document's form fields.
class DocumentHeader {
  final String? content;
  final String? documentId;
  final String? project;
  final String? version;
  final String? date;
  final String? author;
  final String? status;

  const DocumentHeader({
    this.content,
    this.documentId,
    this.project,
    this.version,
    this.date,
    this.author,
    this.status,
  });
}
