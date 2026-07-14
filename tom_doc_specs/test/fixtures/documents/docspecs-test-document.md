<!-- docspec: specification/1.0 -->
# [overview-title] DocSpecs Test Document <!-- schema=specification/1.0 -->

This is a test document to exercise the DocSpecs schema validation features of the Tom Markdown Editor. This document follows the `specification.1.0.docspecs-schema.yaml` schema.

## [contents] Contents

- [Overview](#overview-main)
- [Terminology](#terminology-main)
- [Data Structures](#data-main)
- [Processing Flow](#flow-main)
- [Error Handling](#error-main)
- [Examples](#example-main)
- [Edge Cases](#edge-main)
- [Test Scenarios](#test-main)

## [overview-main] Overview

The DocSpecs validation system provides schema-based structure validation for markdown documents. It ensures documents follow a defined structure with required and optional sections.

Key features:
- **Schema declaration** — Documents declare their schema in the first heading field
- **Section type validation** — Each section matches a defined section type
- **Structure enforcement** — Required sections, ordering, and nesting rules
- **Skeleton generation** — Automatically scaffold documents from schemas

## [terminology-main] Terminology

### [term-01] Section Type

A named category of sections with specific rules about prefix, content, and nesting.

### [term-02] Prefix

A short identifier that appears at the start of section IDs to indicate their type (e.g., `overview`, `data`, `flow`).

### [term-03] Subsection Constraint

A rule defining which section types can appear as children and how many.

### [term-04] Skeleton Document

A document with all required sections created with placeholder text, ready to be filled in.

## [data-main] Data Structures

### [data-schema] Schema Definition

A schema is defined in YAML format with these components:

```yaml
section-types:
  overview:
    prefix: overview
    max-count-in-document: 1
    text-required: true
    
document:
  sections:
    title:
      section-type: overview
      access-key: title
    overview:
      section-type: overview
```

### [field-schema] Field Reference

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `section-types` | Map | Yes | Section type definitions |
| `document` | Object | Yes | Document structure definition |
| `form-types` | Map | No | Form field validation definitions |

## [flow-main] Processing Flow

### [step-01] Load Schema

**Input:** Schema file path or ID  
**Process:** Parse YAML file, extract section types and document structure  
**Output:** `DocSpecSchema` object with id, version, and parsed definitions

### [step-02] Parse Document

**Input:** Markdown document content  
**Process:** Parse into section tree using DocScanner  
**Output:** `Document` with hierarchical `Section` objects

### [step-03] Validate Structure

**Input:** Parsed document and schema  
**Process:** Compare section IDs against schema rules  
**Output:** List of `ValidationError` objects

### [step-04] Report Results

**Input:** Validation errors  
**Process:** Map errors to source locations, generate markers  
**Output:** Visual error indicators in editor tree and preview

## [error-main] Error Handling

### Common Validation Errors

| Error Code | Description | Resolution |
|------------|-------------|------------|
| `MISSING_REQUIRED` | Required section not present | Add section with correct ID prefix |
| `INVALID_PREFIX` | Section ID doesn't match any type | Fix the section ID to use valid prefix |
| `EXCEEDS_MAX` | Too many sections of this type | Remove duplicate sections |
| `INVALID_NESTING` | Child section type not allowed | Move section to valid parent |

### Error Display

Errors appear as:
- Red warning icons in the tree view
- Inline highlights in the preview panel
- Tooltip details on hover

## [example-main] Examples

### [example-basic] Basic Schema Usage

```dart
import 'package:tom_doc_specs/tom_doc_specs.dart';

void main() async {
  // Load schema
  final schema = await SchemaLoader.load('schemas/specification-1.0.docspecs-schema.yaml');
  
  // Parse and validate document
  final doc = await DocSpecs.scanDocument(
    path: 'my_spec.md',
    schemaId: schema.fullId,
  );
  
  if (!doc.isValid) {
    for (final error in doc.validationErrors) {
      print('${error.code}: ${error.message}');
    }
  }
}
```

### [example-skeleton] Skeleton Generation

```dart
// Generate skeleton document from schema
final skeleton = DocSpecsSkeletonGenerator.generate(schema);
print(skeleton);
// Output:
// # [overview-title] Document Title
//
// Overview text here.
//
// ## [terminology-main] Terminology
//
// ...
```

## [edge-main] Edge Cases

### [edge-01] Empty Document

An empty document should fail validation with `MISSING_REQUIRED` errors for all non-optional sections.

### [edge-02] Unknown Section IDs

Sections with IDs that don't match any prefix should generate `UNKNOWN_TYPE` warnings.

### [edge-03] Deeply Nested Sections

Sections should respect `max-subsection-levels` constraints; excess nesting generates errors.

## [test-main] Test Scenarios

### [test-01] Valid Document Passes

**Given:** A document with all required sections properly formatted  
**When:** Validated against its declared schema  
**Then:** No errors returned, `isValid` is true

### [test-02] Missing Required Section Fails

**Given:** A document missing the `## Overview` section  
**When:** Validated against specification schema  
**Then:** Error with code `MISSING_REQUIRED` for overview section

### [test-03] Schema Not Found

**Given:** Document declares `<!-- docspec: nonexistent/1.0 -->`  
**When:** Schema resolution attempted  
**Then:** Graceful failure with warning, validation skipped
