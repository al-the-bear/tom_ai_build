import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final pd = ProjectDefinition(
    header: DocumentHeader(
      documentId: 'PD00',
      project: 'Example Project',
      version: '0.1',
      date: DateTime(2026, 4, 7),
      author: 'Author',
      status: 'Draft',
    ),
  );
  print('Document: ${pd.header.documentId} — ${pd.header.project}');
}
