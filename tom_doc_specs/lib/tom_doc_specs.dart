/// Tom Doc Specs - Document schema validation for structured markdown.
///
/// Provides schema definitions and validation for markdown documents,
/// extending DocScanner with typed section access.
///
/// ## Usage
///
/// ```dart
/// import 'package:tom_doc_specs/tom_doc_specs.dart';
///
/// final doc = await DocSpecs.scanDocument(
///   filePath: 'quest_overview.docspec.md',
/// );
/// if (!doc.isValid) {
///   print('Errors: ${doc.validationErrors}');
/// }
/// ```
library;

// Main API
export 'src/doc_specs.dart';
export 'src/doc_specs_factory.dart';

// Re-export Section and Document from doc_scanner (used by SpecSection and SpecDoc)
export 'package:tom_doc_scanner/tom_doc_scanner.dart' show Section, Document;

// Models
export 'src/models/spec_section.dart';
export 'src/models/spec_doc.dart';
export 'src/models/spec_section_type.dart';

// Schema models
export 'src/models/schema/doc_spec_schema.dart';
export 'src/models/schema/section_type_def.dart';
export 'src/models/schema/document_structure.dart';
export 'src/models/schema/form_type_def.dart';
export 'src/models/schema/schema_info.dart';

// Schema loading
export 'src/schema/schema_loader.dart';
export 'src/schema/schema_expander.dart';

// Skeleton generation
export 'src/skeleton/skeleton_generator.dart';

// Validation
export 'src/validation/ai_validator.dart';
export 'src/validation/prompt_expander.dart';
export 'src/validation/validation_error.dart';
export 'src/validation/validator.dart';

// Insert markers
export 'src/markers/insert_markers.dart';
