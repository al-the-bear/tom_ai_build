import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final pd = SolutionBlueprint()
    ..header = (DocumentHeader()
      ..content = 'PD00 — Example Project v0.1 by Author (Draft)');
  print('Document: ${pd.header.content}');
}
