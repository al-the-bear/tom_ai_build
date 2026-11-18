/// The Meridian trio held to its extracts: `tomspecs :codespecs-validate` over
/// tom_som_conformance's sample trio with the committed conformance extracts
/// (`generated-doc/codespecs_extracts`) and `tom_code_specs`' vocabulary
/// reports no violation. With the extracts, checks 32–36 compare the trio
/// with the specification's routed values: every entry an area is held to
/// reaches a back-link (check 35), every back-link names an extracted token
/// (check 36), and every comment is the extract's text (checks 32–34).
@TestOn('vm')
library;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_specs_clitool/tom_specs_clitool.dart';

final _meridian = p.absolute(
  '../tom_som_conformance/samples/meridian_codespecs',
);
final _extracts = p.absolute(
  '../tom_som_conformance/generated-doc/codespecs_extracts',
);
final _vocabulary = p.absolute('../tom_code_specs/lib');

void main() {
  test('MEX1: the Meridian trio is clean against its extracts', () async {
    final out = StringBuffer();
    final err = StringBuffer();
    final code = await runValidateCodespecs(
      [
        '--shared',
        p.join(_meridian, 'meridian_codespec_shared'),
        '--client',
        p.join(_meridian, 'meridian_codespec_client'),
        '--server',
        p.join(_meridian, 'meridian_codespec_server'),
        '--extracts',
        _extracts,
        '--cs-vocabulary',
        _vocabulary,
      ],
      out: out,
      err: err,
    );
    expect(code, 0, reason: '$out$err');
    expect('$out', contains('checks passed'));
    expect('$out', isNot(contains('violation')), reason: '$out');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
