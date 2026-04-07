/// Standard document header present in all TomSpecs documents.
class DocumentHeader {
  final String documentId;
  final String project;
  final String version;
  final DateTime date;
  final String author;
  final String status;

  const DocumentHeader({
    required this.documentId,
    required this.project,
    required this.version,
    required this.date,
    required this.author,
    required this.status,
  });
}
