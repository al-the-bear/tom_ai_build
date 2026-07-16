/// SBP.3 — Glossary & Abbreviations.
///
/// Defines the terms, acronyms, and abbreviations used throughout the
/// Solution Blueprint. Closes the prior-review completeness gap (§5:
/// "Glossary / acronyms").
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// SBP.3 Glossary & Abbreviations.
@StandardReferences(
  ['ISO/IEC/IEEE 29148:2018 §6 — definitions and abbreviations'],
  'The controlled vocabulary — terms, acronyms, and abbreviations — used '
  'consistently throughout the specification.',
)
@SectionId('GLAB')
class GlossaryAndAbbreviations {
  @ContentType(
    'description',
    'Introduce the glossary: scope, conventions, '
        'and how terms are maintained.',
  )
  @SerializationOrder(0)
  String? content;

  /// The set of defined terms and abbreviations.
  @StandardReferences([
    'ISO/IEC/IEEE 29148:2018 §6 — definitions and abbreviations',
  ], 'The ordered collection of defined terms and abbreviations.')
  @SectionId('GLOSS-ENTR-LST')
  @SectionIdPattern('GLOSS-ENTR-xxx')
  @ContentHelp('Add one entry per term or acronym, alphabetically ordered.')
  @SerializationOrder(1)
  List<GlossaryEntry> glossary = [];
}

/// A single glossary entry (form).
@StandardReferences([
  'ISO/IEC/IEEE 29148:2018 §6 — definitions and abbreviations',
], 'A single defined term or acronym with its definition and related terms.')
@SectionId('GLENT')
class GlossaryEntry {
  @Form([
    Field('term', String, 'Term', required: true),
    Field('definition', String, 'Definition', required: true),
    Field('acronym', String, 'Acronym / Abbreviation'),
    Field('seeAlso', String, 'See Also (related terms)'),
  ])
  @SerializationOrder(0)
  String? content;
}
