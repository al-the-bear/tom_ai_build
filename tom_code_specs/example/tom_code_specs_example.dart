import 'package:tom_code_specs/tom_code_specs.dart';

/// Builds a small CodeSpecs document and prints a one-line summary.
void main() {
  final codeSpecs = CodeSpecsDocument()
    ..tagline = 'Skeletal application — compiles but does not execute'
    ..inputs.add(CodeSpecsInput()..content = 'All Phase 3 documents')
    ..components.add(CodeSpecsComponent()
      ..content = 'UI Elements — Flutter widgets — UP (UI Prototype)');

  print('CodeSpecs tagline: ${codeSpecs.tagline}');
  print('inputs: ${codeSpecs.inputs.length}, '
      'components: ${codeSpecs.components.length}');
}
