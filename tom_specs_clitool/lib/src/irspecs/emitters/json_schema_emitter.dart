/// The JSON Schema 2020-12 emitter (`irspecs_ir.md` §10.1): every wire and
/// storage type of the IR as one schema document — the domain enums (CE-EN),
/// the error-code catalogue and the `Result` envelope (CE-ER), the wire types
/// (CE-API) and the entities (CE-DB), each field's `@CsValidation` rules as
/// JSON Schema keywords.
library;

import 'emit_common.dart';
import '../ir_model.dart';

/// The URI of the JSON Schema dialect the document is written in.
const String kJsonSchema202012 = 'https://json-schema.org/draft/2020-12/schema';

/// The file the JSON Schema emitter writes.
const String kJsonSchemaFile = 'schema.json';

/// Emits [documents] as one JSON Schema 2020-12 document, `schema.json`, its
/// types under `$defs`.
IrEmission emitJsonSchema(List<IrDocument> documents) {
  final index = IrIndex(documents);
  final notExpressed = <String>[];
  final defs = IrSchemaBuilder(
    index,
    refBase: r'#/$defs/',
    notExpressed: notExpressed,
  ).build();
  return IrEmission({
    kJsonSchemaFile: irJson({
      r'$schema': kJsonSchema202012,
      'title': index.title,
      'description':
          'The wire and storage types of ${index.title}, from its IR '
          '(irspecs_ir.md §10.1).',
      r'$defs': defs,
    }),
  }, notExpressed);
}
