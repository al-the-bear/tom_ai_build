import 'package:tom_specs_model/tom_specs_model.dart';

void main() {
  final pd = SolutionBlueprint()
    ..documentControl.header.content =
        'SBP — Example Project v0.1 by Author (Draft)';
  print('Document: ${pd.documentControl.header.content}');
}
