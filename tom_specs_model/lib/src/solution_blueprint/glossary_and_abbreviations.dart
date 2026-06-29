/// SBP.3 — Glossary & Abbreviations.
///
/// Defines the terms, acronyms, and abbreviations used throughout the
/// Solution Blueprint. Closes the prior-review completeness gap (§5:
/// "Glossary / acronyms").
///
/// Public anchor: ISO/IEC/IEEE 29148 §6 definitions/abbreviations.
library;

import 'package:tom_specs_core/tom_specs_core.dart';

/// SBP.3 Glossary & Abbreviations.
@SectionId('GLAB')
class GlossaryAndAbbreviations {
  @ContentType('description', 'Introduce the glossary: scope, conventions, '
      'and how terms are maintained.')
  String? content;

  /// The set of defined terms and abbreviations.
  Glossary glossary = Glossary();
}

/// An ordered collection of glossary entries.
@SectionId('GLOSS')
class Glossary {
  @Unused()
  String? content;

  /// One entry per defined term or acronym.
  @SectionId('GLOSS-ENTR-LST')
  @SectionIdPattern('GLOSS-ENTR-xxx')
  @ContentHelp('Add one entry per term or acronym, alphabetically ordered.')
  List<GlossaryEntry> entries = [];
}

/// A single glossary entry (form).
@SectionId('GLENT')
class GlossaryEntry {
  @Form([
    Field('term', String, 'Term', required: true),
    Field('definition', String, 'Definition', required: true),
    Field('acronym', String, 'Acronym / Abbreviation'),
    Field('seeAlso', String, 'See Also (related terms)'),
  ])
  String? content;
}
