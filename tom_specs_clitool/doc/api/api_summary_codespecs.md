# TomSpecs CLI Tool API Reference: CodeSpecs

The Phase-4 validation pass: reading a generated trio, resolving it into a
model, running the thirty-seven contract checks, and the area catalogue the
nine-runtime extract surface consumes.

For task-oriented guidance see
[gates.md § The CodeSpecs validator](../gates.md#the-codespecs-validator). For
the checks themselves, see
[`codespecs_derivation_contract.md`](../../../tom_specs_model/doc/codespecs_derivation_contract.md)
§6.

## Table of Contents

- [Overview](#overview)
- [Class Hierarchy](#class-hierarchy)
- [Classes](#classes)
  - [CsExcludedArea](#csexcludedarea)
  - [CsExtractException](#csextractexception)
  - [CsExtractEntry](#csextractentry)
  - [CsExtract](#csextract)
  - [CsExtractSet](#csextractset)
  - [CsLocation](#cslocation)
  - [CsStringValue](#csstringvalue)
  - [CsBoolValue](#csboolvalue)
  - [CsIntValue](#csintvalue)
  - [CsNullValue](#csnullvalue)
  - [CsQualifiedValue](#csqualifiedvalue)
  - [CsConstructionValue](#csconstructionvalue)
  - [CsListValue](#cslistvalue)
  - [CsUnknownValue](#csunknownvalue)
  - [CsMarker](#csmarker)
  - [CsDocRef](#csdocref)
  - [CsCodeSpecLink](#cscodespeclink)
  - [CsCall](#cscall)
  - [CsStatement](#csstatement)
  - [CsParameter](#csparameter)
  - [CsMethodBody](#csmethodbody)
  - [CsDocComment](#csdoccomment)
  - [CsComment](#cscomment)
  - [CsDeclaration](#csdeclaration)
  - [CsConstruction](#csconstruction)
  - [CsFile](#csfile)
  - [CsLocusProject](#cslocusproject)
  - [CsEnumMirror](#csenummirror)
  - [CodeSpecsRegeneration](#codespecsregeneration)
  - [CodeSpecsValidationInput](#codespecsvalidationinput)
  - [CodeSpecsViolation](#codespecsviolation)
  - [CodeSpecsCheck](#codespecscheck)
  - [CsIdentifierCollisionCheck](#csidentifiercollisioncheck)
  - [CsReferenceResolutionCheck](#csreferenceresolutioncheck)
  - [CsMissingNameCheck](#csmissingnamecheck)
  - [CsMissingAuthoredKeyCheck](#csmissingauthoredkeycheck)
  - [CsEmptyExplicationCheck](#csemptyexplicationcheck)
  - [CsFabricatedValueCheck](#csfabricatedvaluecheck)
  - [CsBackLinkAgreementCheck](#csbacklinkagreementcheck)
  - [CsSlotExclusivityCheck](#csslotexclusivitycheck)
  - [CsMirroredCatalogueCheck](#csmirroredcataloguecheck)
  - [CsErrorCopyCategoryCheck](#cserrorcopycategorycheck)
  - [CsLocusArrowCheck](#cslocusarrowcheck)
  - [CsOperationAgreementCheck](#csoperationagreementcheck)
  - [CsMigrationConvergenceCheck](#csmigrationconvergencecheck)
  - [CsComposeTokenCheck](#cscomposetokencheck)
  - [CsOverridableScopeCheck](#csoverridablescopecheck)
  - [CsSecretInitialiserCheck](#cssecretinitialisercheck)
  - [CsFallbackChannelCheck](#csfallbackchannelcheck)
  - [CsDrillThroughRouteCheck](#csdrillthroughroutecheck)
  - [CsSecretIsDeclaredCheck](#cssecretisdeclaredcheck)
  - [CsSettingKeyCollisionCheck](#cssettingkeycollisioncheck)
  - [CsGradedDepthCheck](#csgradeddepthcheck)
  - [CsColumnNotObservableCheck](#cscolumnnotobservablecheck)
  - [CsCollaboratorCallResolutionCheck](#cscollaboratorcallresolutioncheck)
  - [CsCollaboratorShapeCheck](#cscollaboratorshapecheck)
  - [CsMethodCommentCheck](#csmethodcommentcheck)
  - [CsNoInBodyCommentCheck](#csnoinbodycommentcheck)
  - [CsDocCommentShapeCheck](#csdoccommentshapecheck)
  - [CsBodyStatementShapeCheck](#csbodystatementshapecheck)
  - [CsBranchConditionCheck](#csbranchconditioncheck)
  - [CsCollaboratorSignatureCheck](#cscollaboratorsignaturecheck)
  - [CsDeterminismCheck](#csdeterminismcheck)
  - [CsCommentSourceCheck](#cscommentsourcecheck)
  - [CsGroupedHolderCommentCheck](#csgroupedholdercommentcheck)
  - [CsCommentFidelityCheck](#cscommentfidelitycheck)
  - [CsExtractCoverageCheck](#csextractcoveragecheck)
  - [CsBackLinkExtractedCheck](#csbacklinkextractedcheck)
  - [CsReflectionWrittenNotFinalCheck](#csreflectionwrittennotfinalcheck)
  - [CodeSpecsValidationReport](#codespecsvalidationreport)
  - [CodeSpecsValidationException](#codespecsvalidationexception)
  - [AreasCatalogException](#areascatalogexception)
  - [AreasCatalog](#areascatalog)
- [Enums](#enums)
  - [CsGateVerdict](#csgateverdict)
  - [CsLocus](#cslocus)
  - [CsBodyShape](#csbodyshape)
  - [CsStatementKind](#csstatementkind)
  - [CsDeclarationKind](#csdeclarationkind)
  - [CsCallPosition](#cscallposition)
- [Global Functions and Constants](#global-functions-and-constants)

## Overview

The module declares **73 classes** and **6 enums** across 6 source file(s).

| Source file | Holds |
|-------------|-------|
| `cs_reader.dart` | Reading the trio — *(no public types)* |
| `cs_extract.dart` | Reading the extracts — `CsExcludedArea`, `CsExtractException`, `CsExtractEntry`, `CsExtract`, `CsExtractSet`, `CsGateVerdict` |
| `cs_model.dart` | The resolved model the checks read — `CsLocation`, `CsStringValue`, `CsBoolValue`, `CsIntValue`, `CsNullValue`, `CsQualifiedValue`, `CsConstructionValue`, `CsListValue`, `CsUnknownValue`, `CsMarker`, `CsDocRef`, `CsCodeSpecLink`, `CsCall`, `CsStatement`, `CsParameter`, `CsMethodBody`, `CsDocComment`, `CsComment`, `CsDeclaration`, `CsConstruction`, `CsFile`, `CsLocusProject`, `CsEnumMirror`, `CodeSpecsRegeneration`, `CodeSpecsValidationInput`, `CsLocus`, `CsBodyShape`, `CsStatementKind`, `CsDeclarationKind` |
| `cs_checks.dart` | The thirty-seven checks — `CodeSpecsViolation`, `CodeSpecsCheck`, `CsIdentifierCollisionCheck`, `CsReferenceResolutionCheck`, `CsMissingNameCheck`, `CsMissingAuthoredKeyCheck`, `CsEmptyExplicationCheck`, `CsFabricatedValueCheck`, `CsBackLinkAgreementCheck`, `CsSlotExclusivityCheck`, `CsMirroredCatalogueCheck`, `CsErrorCopyCategoryCheck`, `CsLocusArrowCheck`, `CsOperationAgreementCheck`, `CsMigrationConvergenceCheck`, `CsComposeTokenCheck`, `CsOverridableScopeCheck`, `CsSecretInitialiserCheck`, `CsFallbackChannelCheck`, `CsDrillThroughRouteCheck`, `CsSecretIsDeclaredCheck`, `CsSettingKeyCollisionCheck`, `CsGradedDepthCheck`, `CsColumnNotObservableCheck`, `CsCollaboratorCallResolutionCheck`, `CsCollaboratorShapeCheck`, `CsMethodCommentCheck`, `CsNoInBodyCommentCheck`, `CsDocCommentShapeCheck`, `CsBodyStatementShapeCheck`, `CsBranchConditionCheck`, `CsCollaboratorSignatureCheck`, `CsDeterminismCheck`, `CsCommentSourceCheck`, `CsGroupedHolderCommentCheck`, `CsCommentFidelityCheck`, `CsExtractCoverageCheck`, `CsBackLinkExtractedCheck`, `CsReflectionWrittenNotFinalCheck`, `CsCallPosition` |
| `codespecs_validator.dart` | The validation pass — `CodeSpecsValidationReport`, `CodeSpecsValidationException` |
| `areas_catalog.dart` | The 27-area catalogue — `AreasCatalogException`, `AreasCatalog` |

## Class Hierarchy

```
Object
├── CsExcludedArea
├── CsExtractException  implements Exception
├── CsExtractEntry
├── CsExtract
├── CsExtractSet
├── CsLocation
├── CsStringValue  extends CsValue
├── CsBoolValue  extends CsValue
├── CsIntValue  extends CsValue
├── CsNullValue  extends CsValue
├── CsQualifiedValue  extends CsValue
├── CsConstructionValue  extends CsValue
├── CsListValue  extends CsValue
├── CsUnknownValue  extends CsValue
├── CsMarker
├── CsDocRef
├── CsCodeSpecLink
├── CsCall
├── CsStatement
├── CsParameter
├── CsMethodBody
├── CsDocComment
├── CsComment
├── CsDeclaration
├── CsConstruction
├── CsFile
├── CsLocusProject
├── CsEnumMirror
├── CodeSpecsRegeneration
├── CodeSpecsValidationInput
├── CodeSpecsViolation
├── CodeSpecsCheck
├── CsIdentifierCollisionCheck  extends CodeSpecsCheck
├── CsReferenceResolutionCheck  extends CodeSpecsCheck
├── CsMissingNameCheck  extends CodeSpecsCheck
├── CsMissingAuthoredKeyCheck  extends CodeSpecsCheck
├── CsEmptyExplicationCheck  extends CodeSpecsCheck
├── CsFabricatedValueCheck  extends CodeSpecsCheck
├── CsBackLinkAgreementCheck  extends CodeSpecsCheck
├── CsSlotExclusivityCheck  extends CodeSpecsCheck
├── CsMirroredCatalogueCheck  extends CodeSpecsCheck
├── CsErrorCopyCategoryCheck  extends CodeSpecsCheck
├── CsLocusArrowCheck  extends CodeSpecsCheck
├── CsOperationAgreementCheck  extends CodeSpecsCheck
├── CsMigrationConvergenceCheck  extends CodeSpecsCheck
├── CsComposeTokenCheck  extends CodeSpecsCheck
├── CsOverridableScopeCheck  extends CodeSpecsCheck
├── CsSecretInitialiserCheck  extends CodeSpecsCheck
├── CsFallbackChannelCheck  extends CodeSpecsCheck
├── CsDrillThroughRouteCheck  extends CodeSpecsCheck
├── CsSecretIsDeclaredCheck  extends CodeSpecsCheck
├── CsSettingKeyCollisionCheck  extends CodeSpecsCheck
├── CsGradedDepthCheck  extends CodeSpecsCheck
├── CsColumnNotObservableCheck  extends CodeSpecsCheck
├── CsCollaboratorCallResolutionCheck  extends CodeSpecsCheck
├── CsCollaboratorShapeCheck  extends CodeSpecsCheck
├── CsMethodCommentCheck  extends CodeSpecsCheck
├── CsNoInBodyCommentCheck  extends CodeSpecsCheck
├── CsDocCommentShapeCheck  extends CodeSpecsCheck
├── CsBodyStatementShapeCheck  extends CodeSpecsCheck
├── CsBranchConditionCheck  extends CodeSpecsCheck
├── CsCollaboratorSignatureCheck  extends CodeSpecsCheck
├── CsDeterminismCheck  extends CodeSpecsCheck
├── CsCommentSourceCheck  extends CodeSpecsCheck
├── CsGroupedHolderCommentCheck  extends CodeSpecsCheck
├── CsCommentFidelityCheck  extends CodeSpecsCheck
├── CsExtractCoverageCheck  extends CodeSpecsCheck
├── CsBackLinkExtractedCheck  extends CodeSpecsCheck
├── CsReflectionWrittenNotFinalCheck  extends CodeSpecsCheck
├── CodeSpecsValidationReport
├── CodeSpecsValidationException  implements Exception
├── AreasCatalogException  implements Exception
└── AreasCatalog
```

## Classes

### CsExcludedArea

One area the gate record excluded from the obligation set.

#### Constructors
```dart
const CsExcludedArea({
  required this.areaCode,
  required this.verdict,
  this.descoped = false,
  this.entryCount = 0,
  this.source = '',
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `areaCode` | `String` | The `CE-*` code. |
| `verdict` | `CsGateVerdict` | The recorded verdict — [CsGateVerdict.notApplicable] or [CsGateVerdict.insufficient] (a sufficient area is never excluded). |
| `descoped` | `bool` | Whether an insufficient verdict was resolved by descoping. |
| `entryCount` | `int` | How many routed entries the excluded extract carried (0 when the record names an area with no extract file). |
| `source` | `String` | Where the excluded extract was read from, or '' when there was none. |

### CsExtractException

A malformed or unreadable extract.

**implements Exception**

#### Constructors
```dart
const CsExtractException(this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What is wrong. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsExtractEntry

One routed value of one section.

#### Constructors
```dart
const CsExtractEntry({
  required this.areaCode,
  required this.sectionId,
  required this.value,
  this.headline,
  this.instanceId,
  this.path = '',
  this.className = '',
  this.fieldName = '',
  this.formField,
  this.routedBy = '',
  this.routedAt = '',
  this.routingNote,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `areaCode` | `String` | The `CE-*` code of the area this entry was routed to. |
| `sectionId` | `String` | The section id the value belongs to — the key a `DocRef` names. |
| `headline` | `String?` | The enclosing section instance's headline, copy-only: the stored headline, else the `@Headline` type default, else null. |
| `instanceId` | `String?` | The nearest enclosing list-item instance's **stored** section id — the `<!--[…]-->` id the document serializes — or null when no enclosing instance stores one. |
| `path` | `String` | The document path of the node the value was read from. |
| `className` | `String` | The model class that declared it. |
| `fieldName` | `String` | The model field that held it. |
| `formField` | `String?` | The `@Form` field label, when the value is one field of a form section. |
| `routedBy` | `String` | The annotation that routed the section to the area. |
| `routedAt` | `String` | Where the routing annotation sits. |
| `routingNote` | `String?` | The routing annotation's note, when it carries one. |
| `value` | `String` | The stored value, verbatim as the specification holds it. |
| `rawLines` | `List<String> get` | [value] split into lines, exactly as authored. |
| `escapedLines` | `List<String> get` | [value] split into lines with `codespecs_derivation_contract.md` §2.8 C4.4's two escapes applied. |

### CsExtract

One area's extract.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What is wrong. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsExtractSet

Every extract the caller supplied, indexed by section id.

#### Constructors
```dart
CsExtractSet._(this.extracts, this._bySection,
    {this.excluded = const []});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `extracts` | `List<CsExtract>` | The in-scope extracts, in the order they were read. |
| `excluded` | `List<CsExcludedArea>` | The areas a gate record excluded — empty when no record was supplied. |
| `empty` | `CsExtractSet` | An empty set — the state every check treats as "no second input", so a caller that supplied no extracts sees the trio-only checks and nothing else. |
| `entries` | `Iterable<CsExtractEntry> get` | Every entry across every extract. |
| `sectionIds` | `Iterable<String> get` | The section ids the extracts know about. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `knowsSection(String sectionId)` | `bool` | Whether any extract routed a value of [sectionId]. |
| `entriesFor(String sectionId)` | `List<CsExtractEntry>` | The values routed from [sectionId], across every area. |
| `entriesForAll(Iterable<String> sectionIds)` | `List<CsExtractEntry>` | The values routed from any of [sectionIds], in the given order. |

### CsLocation

Where a violation is (file plus 1-based line).

#### Constructors
```dart
const CsLocation(this.file, this.line);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `file` | `String` | The file the element was read from, as given to the reader. |
| `line` | `int` | The 1-based line of the element. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsStringValue

A string literal.

**extends CsValue**

#### Constructors
```dart
const CsStringValue(this.value);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `value` | `String` | The literal text. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsBoolValue

A boolean literal.

**extends CsValue**

#### Constructors
```dart
const CsBoolValue(this.value);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `value` | `bool` | The literal value. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsIntValue

An integer literal.

**extends CsValue**

#### Constructors
```dart
const CsIntValue(this.value);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `value` | `int` | The literal value. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsNullValue

A `null` literal — written where a per-kind slot is deliberately absent.

**extends CsValue**

#### Constructors
```dart
const CsNullValue();
```

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsQualifiedValue

A qualified identifier: an enum access (`CsTextRole.error`) or a catalogue const reference (`SharedOperations.login`).

**extends CsValue**

#### Constructors
```dart
const CsQualifiedValue(this.prefix, this.name);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `prefix` | `String` | The part before the dot — an enum type or a catalogue holder. |
| `name` | `String` | The part after the dot — an enum constant or a const member. |
| `path` | `String get` | The dotted source form. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsConstructionValue

A constructor call — a `Cs*Ref` const, a value class such as `CsGradedAccess`, or a `tom_core` substrate construction.

**extends CsValue**

#### Constructors
```dart
const CsConstructionValue(this.type, this.positional, this.named);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | The constructed type name. |
| `positional` | `List<CsValue>` | Positional arguments, in source order. |
| `named` | `Map<String, CsValue>` | Named arguments. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsListValue

A list literal.

**extends CsValue**

#### Constructors
```dart
const CsListValue(this.values);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `values` | `List<CsValue>` | The elements, in source order. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsUnknownValue

An expression the reader did not model — kept with its source text so a message can quote it rather than say "something".

**extends CsValue**

#### Constructors
```dart
const CsUnknownValue(this.source);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `source` | `String` | The source text of the expression. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsMarker

One `Cs*` part marker as written on a declaration.

#### Constructors
```dart
const CsMarker(this.name, this.positional, this.named, this.location);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The marker name without the `@` (`CsTrigger`). |
| `positional` | `List<CsValue>` | Positional arguments, in source order. |
| `named` | `Map<String, CsValue>` | Named arguments. |
| `location` | `CsLocation` | Where the marker is written. |

### CsDocRef

One `DocRef` tuple of a `@DocSpec` annotation.

#### Constructors
```dart
const CsDocRef(this.sectionId, this.description);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sectionId` | `String` | The SOM section id, verbatim. |
| `description` | `String` | The one-sentence edge description. |

### CsCodeSpecLink

A `@CodeSpec` back-link.

#### Constructors
```dart
const CsCodeSpecLink(this.id, this.source, this.location);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | `String` | The stable CodeSpec id, `<canonical id>.<identifier>`. |
| `source` | `List<String>` | The flat set of SOM sections that fed the element. |
| `location` | `CsLocation` | Where the annotation is written. |

### CsCall

One call site inside a generated body.

#### Constructors
```dart
const CsCall({
  required this.method,
  required this.location,
  this.receiver,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `receiver` | `String?` | The receiver as written (`collaborator`), or `null` for an unqualified call. |
| `method` | `String` | The invoked method name. |
| `location` | `CsLocation` | Where the call is written. |

### CsStatement

One statement of a generated body.

#### Constructors
```dart
const CsStatement({
  required this.kind,
  required this.source,
  required this.location,
  this.call,
  this.valueIdentifier,
  this.valueSource,
  this.boundName,
  this.isFinal = false,
  this.nested = const [],
  this.keyword,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `kind` | `CsStatementKind` | Which of the `codespecs_derivation_contract.md` §2.4 statement kinds this is. |
| `source` | `String` | The statement as written, whitespace-collapsed, so a message can quote it. |
| `call` | `CsCall?` | The call the statement's value comes out of — the returned expression, the binding's initialiser, the branch condition — unwrapped from any `await`. |
| `valueIdentifier` | `String?` | The bare identifier the value expression is, when it is one. |
| `valueSource` | `String?` | The source text of the value expression, when the statement has one. |
| `boundName` | `String?` | The name a [CsStatementKind.localBinding] binds. |
| `isFinal` | `bool` | Whether a local binding is declared `final`. |
| `nested` | `List<CsStatement>` | The statements inside a control-flow statement's blocks, in source order. |
| `keyword` | `String?` | Which control-flow construct a [CsStatementKind.controlFlow] statement is — `if`, `for`, `while`, `switch`, or `block` for a bare nested block. |
| `location` | `CsLocation` | Where the statement is written. |

### CsParameter

One formal parameter of a generated method, as written.

#### Constructors
```dart
const CsParameter(this.name, [this.type]);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The parameter name. |
| `type` | `String?` | The declared type as written, or `null` when the parameter declares none. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsMethodBody

A method or accessor body of a generated declaration.

#### Constructors
```dart
const CsMethodBody({
  required this.name,
  required this.shape,
  required this.location,
  this.calls = const [],
  this.statements = const [],
  this.parameters = const [],
  this.returnType,
  this.thrownMessage,
  this.thrownType,
  this.isAsync = false,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `name` | `String` | The method name. |
| `shape` | `CsBodyShape` | What the body does. |
| `calls` | `List<CsCall>` | The call sites the body contains, in source order. |
| `statements` | `List<CsStatement>` | The body's statements, in source order. |
| `parameters` | `List<CsParameter>` | The declared formal parameters, in source order. |
| `returnType` | `String?` | The declared return type as written, or `null` when there is none. |
| `thrownMessage` | `String?` | The literal argument of the `throw`, when the body is a single throw of a constructor call with a string literal. |
| `thrownType` | `String?` | The thrown type, when the body is a single throw of a constructor call. |
| `isAsync` | `bool` | Whether the method is declared `async` / `async*`. |
| `location` | `CsLocation` | Where the method is declared. |

### CsDocComment

A `///` documentation block, as written.

#### Constructors
```dart
const CsDocComment(this.lines, this.location);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `lines` | `List<String>` | The comment lines as written, each including its leading `///`. |
| `location` | `CsLocation` | Where the first line is. |

### CsComment

One comment token of a generated file.

#### Constructors
```dart
const CsComment({
  required this.text,
  required this.isDocumentation,
  required this.isBanner,
  required this.location,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | The comment as written, including its marker. |
| `isDocumentation` | `bool` | Whether it is a `///` doc comment. |
| `isBanner` | `bool` | Whether it precedes the file's very first token — `codespecs_derivation_contract.md` §2.7's banner position. |
| `location` | `CsLocation` | Where the comment is. |

### CsDeclaration

A generated declaration — a top-level class/enum/variable, or a member of one.

#### Constructors
```dart
const CsDeclaration({
  required this.locus,
  required this.name,
  required this.markers,
  required this.location,
  required this.kind,
  this.owner,
  this.codeSpec,
  this.docSpec,
  this.docSpecLocation,
  this.hasInitialiser = false,
  this.isFinal = false,
  this.isLate = false,
  this.declaredType,
  this.bodies = const [],
  this.isAbstract = false,
  this.isStatic = false,
  this.docComment,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `locus` | `CsLocus` | The locus project the declaration belongs to. |
| `name` | `String` | The declaration name (`Customer`, `save`). |
| `owner` | `String?` | The owning declaration name for a member; `null` for a top-level one. |
| `markers` | `List<CsMarker>` | The `Cs*` part markers written on the declaration. |
| `codeSpec` | `CsCodeSpecLink?` | The `@CodeSpec` back-link, when present. |
| `docSpec` | `List<CsDocRef>?` | The `@DocSpec` tuples, or `null` when the annotation is absent. |
| `docSpecLocation` | `CsLocation?` | Where the `@DocSpec` annotation itself is written, or `null` when it is absent. |
| `hasInitialiser` | `bool` | Whether a variable declaration carries an initialiser. |
| `isFinal` | `bool` | Whether a variable declaration is written `final`. |
| `isLate` | `bool` | Whether a variable declaration is written `late`. |
| `declaredType` | `String?` | The declared type of a variable, as written; `null` when there is none — either because it is inferred (`final x = …`) or because the declaration is not a variable at all. |
| `bodies` | `List<CsMethodBody>` | The method bodies this declaration declares. |
| `kind` | `CsDeclarationKind` | Which Dart declaration shape this is. |
| `isAbstract` | `bool` | Whether a class carries the `abstract` keyword. |
| `isStatic` | `bool` | Whether a member is declared `static`. |
| `docComment` | `CsDocComment?` | The `///` block above the declaration, or `null` when there is none (`codespecs_derivation_contract.md` §2.8 C2). |
| `location` | `CsLocation` | Where the declaration is written. |
| `path` | `String get` | The `<owner>.<member>` path for a member, the bare name for a top-level declaration — the N9 form of a reference target. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `marker(String markerName)` | `CsMarker?` | The first marker with [markerName], or `null`. |
| `has(String markerName)` | `bool` | Whether the declaration carries [markerName]. |

### CsConstruction

A `tom_core`-family construction in generated code — read for the checks whose subject is a substrate constructor argument rather than a marker one.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `type` | `String` | The constructed type name. |
| `positional` | `List<CsValue>` | Positional arguments, in source order. |
| `named` | `Map<String, CsValue>` | Named arguments. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CsFile

One generated Dart file.

#### Constructors
```dart
const CsFile({
  required this.path,
  required this.source,
  required this.imports,
  required this.declarations,
  required this.constructions,
  this.comments = const [],
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The file path as given to the reader. |
| `source` | `String` | The file's source text, verbatim. |
| `imports` | `List<String>` | The `import` URIs the file declares. |
| `declarations` | `List<CsDeclaration>` | The declarations the file contributes. |
| `constructions` | `List<CsConstruction>` | The substrate constructions the file contains. |
| `comments` | `List<CsComment>` | Every comment token in the file, in source order. |

### CsLocusProject

One generated project of the `codespecs_mapping.md` §4.2 trio.

#### Constructors
```dart
const CsLocusProject({
  required this.locus,
  required this.packageName,
  required this.files,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `locus` | `CsLocus` | Which project this is. |
| `packageName` | `String` | The package name, used by the locus-arrow check to recognise an import of a sibling project. |
| `files` | `List<CsFile>` | The files the project contributes. |

### CsEnumMirror

A closed catalogue and the `tom_core` catalogue it mirrors (`codespecs_derivation_contract.md` §5.3).

#### Constructors
```dart
const CsEnumMirror({
  required this.csEnumName,
  required this.coreEnumName,
  required this.csValues,
  required this.coreValues,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `csEnumName` | `String` | The `tom_code_specs` enum name. |
| `coreEnumName` | `String` | The `tom_core` enum name it mirrors. |
| `csValues` | `List<String>` | The mirror's values, in declaration order. |
| `coreValues` | `List<String>` | The counterpart's values, in declaration order. |

### CodeSpecsRegeneration

A second generation run over the same spec model, for the determinism check.

#### Constructors
```dart
const CodeSpecsRegeneration({
  required this.shared,
  required this.client,
  required this.server,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `shared` | `CsLocusProject` | The second run's shared project. |
| `client` | `CsLocusProject` | The second run's client project. |
| `server` | `CsLocusProject` | The second run's server project. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `project(CsLocus locus)` | `CsLocusProject` | The project for [locus]. |

### CodeSpecsValidationInput

Everything the thirty-seven checks read.

#### Constructors
```dart
CodeSpecsValidationInput({
  required this.shared,
  required this.client,
  required this.server,
  this.migrations = const {},
  this.enumMirrors = const [],
  this.regeneration,
  CsExtractSet? extracts,
}) : extracts = extracts ?? CsExtractSet.empty;
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `shared` | `CsLocusProject` | The shared project. |
| `client` | `CsLocusProject` | The client project. |
| `server` | `CsLocusProject` | The server project. |
| `migrations` | `Map<String, String>` | The CE-MG migration artifacts, relative path → SQL text, for the cumulative-DDL convergence check. |
| `enumMirrors` | `List<CsEnumMirror>` | The mirrored-catalogue pairs, for the mirror-completeness check. |
| `regeneration` | `CodeSpecsRegeneration?` | A second generation run over the same model, for the determinism check. |
| `extracts` | `CsExtractSet` | The per-area extracts the trio was authored from, for the comment checks. |
| `projects` | `List<CsLocusProject> get` | The three projects, in emission order. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `project(CsLocus locus)` | `CsLocusProject` | The project for [locus]. |

### CodeSpecsViolation

One failed check.

#### Constructors
```dart
const CodeSpecsViolation({
  required this.check,
  required this.definedIn,
  required this.message,
  this.location,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `check` | `int` | The `codespecs_derivation_contract.md` §6 check number. |
| `definedIn` | `String` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or the trailing form `§N of <file>.md` for a rule another document owns. |
| `message` | `String` | What is wrong, in the vocabulary of the rule. |
| `location` | `CsLocation?` | Where in the generated tree, when the check has a single site. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### CodeSpecsCheck

One `codespecs_derivation_contract.md` §6 check.

#### Constructors
```dart
const CodeSpecsCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule, in the same two forms [CodeSpecsViolation.definedIn] takes. |
| `title` | `String get` | The rule, in one line — the `codespecs_derivation_contract.md` §6 row text. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs the check, returning one violation per breach. |
| `fail(String message, [CsLocation? at])` | `CodeSpecsViolation` | Builds a violation attributed to this check. |

### CsIdentifierCollisionCheck

`codespecs_derivation_contract.md` §6 check 1.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsIdentifierCollisionCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsReferenceResolutionCheck

`codespecs_derivation_contract.md` §6 check 2.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsReferenceResolutionCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |
| `title` | `String get` | The human-readable title. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsMissingNameCheck

`codespecs_derivation_contract.md` §6 check 3.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsMissingNameCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsMissingAuthoredKeyCheck

`codespecs_derivation_contract.md` §6 check 4.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsMissingAuthoredKeyCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsEmptyExplicationCheck

`codespecs_derivation_contract.md` §6 check 5.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsEmptyExplicationCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |
| `title` | `String get` | The human-readable title. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsFabricatedValueCheck

`codespecs_derivation_contract.md` §6 check 6.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsFabricatedValueCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsBackLinkAgreementCheck

`codespecs_derivation_contract.md` §6 check 7.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsBackLinkAgreementCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsSlotExclusivityCheck

`codespecs_derivation_contract.md` §6 check 8.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsSlotExclusivityCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsMirroredCatalogueCheck

`codespecs_derivation_contract.md` §6 check 9.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsMirroredCatalogueCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsErrorCopyCategoryCheck

`codespecs_derivation_contract.md` §6 check 10.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsErrorCopyCategoryCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |
| `title` | `String get` | The human-readable title. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsLocusArrowCheck

`codespecs_derivation_contract.md` §6 check 11.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsLocusArrowCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsOperationAgreementCheck

`codespecs_derivation_contract.md` §6 check 12.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsOperationAgreementCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsMigrationConvergenceCheck

`codespecs_derivation_contract.md` §6 check 13.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsMigrationConvergenceCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsComposeTokenCheck

`codespecs_derivation_contract.md` §6 check 14.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsComposeTokenCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |
| `title` | `String get` | The human-readable title. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsOverridableScopeCheck

`codespecs_derivation_contract.md` §6 check 15.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsOverridableScopeCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsSecretInitialiserCheck

`codespecs_derivation_contract.md` §6 check 16.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsSecretInitialiserCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsFallbackChannelCheck

`codespecs_derivation_contract.md` §6 check 17.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsFallbackChannelCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsDrillThroughRouteCheck

`codespecs_derivation_contract.md` §6 check 18.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsDrillThroughRouteCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsSecretIsDeclaredCheck

`codespecs_derivation_contract.md` §6 check 19.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsSecretIsDeclaredCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsSettingKeyCollisionCheck

`codespecs_derivation_contract.md` §6 check 20.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsSettingKeyCollisionCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsGradedDepthCheck

`codespecs_derivation_contract.md` §6 check 21.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsGradedDepthCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsColumnNotObservableCheck

`codespecs_derivation_contract.md` §6 check 22.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsColumnNotObservableCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsCollaboratorCallResolutionCheck

`codespecs_derivation_contract.md` §6 check 23.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsCollaboratorCallResolutionCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsCollaboratorShapeCheck

`codespecs_derivation_contract.md` §6 check 24.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsCollaboratorShapeCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsMethodCommentCheck

`codespecs_derivation_contract.md` §6 check 25.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsMethodCommentCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsNoInBodyCommentCheck

`codespecs_derivation_contract.md` §6 check 26.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsNoInBodyCommentCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsDocCommentShapeCheck

`codespecs_derivation_contract.md` §6 check 27.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsDocCommentShapeCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsBodyStatementShapeCheck

`codespecs_derivation_contract.md` §6 check 28.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsBodyStatementShapeCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsBranchConditionCheck

`codespecs_derivation_contract.md` §6 check 29.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsBranchConditionCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsCollaboratorSignatureCheck

`codespecs_derivation_contract.md` §6 check 30.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsCollaboratorSignatureCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsDeterminismCheck

`codespecs_derivation_contract.md` §6 check 31.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsDeterminismCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsCommentSourceCheck

`codespecs_derivation_contract.md` §6 check 32.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsCommentSourceCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsGroupedHolderCommentCheck

`codespecs_derivation_contract.md` §6 check 33.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsGroupedHolderCommentCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsCommentFidelityCheck

`codespecs_derivation_contract.md` §6 check 34.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsCommentFidelityCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsExtractCoverageCheck

`codespecs_derivation_contract.md` §6 check 35.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsExtractCoverageCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsBackLinkExtractedCheck

`codespecs_derivation_contract.md` §6 check 36.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsBackLinkExtractedCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CsReflectionWrittenNotFinalCheck

`codespecs_derivation_contract.md` §6 check 37.

**extends CodeSpecsCheck**

#### Constructors
```dart
const CsReflectionWrittenNotFinalCheck();
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `definedIn` | `String get` | The section that defines the rule — a bare `§N` of `codespecs_derivation_contract.md`, or `§N of <file>.md` when another document owns it. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `run(CodeSpecsValidationInput input)` | `List<CodeSpecsViolation>` | Runs this check over the resolved trio and returns every violation it finds. |

### CodeSpecsValidationReport

The outcome of one validation pass.

#### Constructors
```dart
const CodeSpecsValidationReport({
  required this.violations,
  required this.checks,
});
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `violations` | `List<CodeSpecsViolation>` | Every violation found, in check order then discovery order. |
| `checks` | `List<CodeSpecsCheck>` | The checks that ran, in `codespecs_derivation_contract.md` §6 table order. |
| `lines` | `List<String> get` | The report as lines, one per violation, each naming its rule. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `forCheck(int number)` | `List<CodeSpecsViolation>` | The violations of one `codespecs_derivation_contract.md` §6 check number. |

### CodeSpecsValidationException

Thrown when a validation pass fails, so a caller that treats generation as a single operation can let the failure propagate.

**implements Exception**

#### Constructors
```dart
const CodeSpecsValidationException(this.report);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `report` | `CodeSpecsValidationReport` | The failing report. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### AreasCatalogException

A failure to transcribe the mapping document — a missing table, a row that does not parse, or a cross-table disagreement.

**implements Exception**

#### Constructors
```dart
const AreasCatalogException(this.message);
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What went wrong, in one sentence. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

### AreasCatalog

The transcribed catalogue, ready to serialize.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `message` | `String` | What went wrong, in one sentence. |

#### Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `toString()` | `String` | A compact diagnostic rendering. |

## Enums

### CsGateVerdict

One of `codespecs_prompt.md` §6.2's three per-area verdicts.

| Value | Meaning |
|-------|---------|
| `sufficient` | The extract carries every input `codespecs_derivation_contract.md` §3 requires — the area is in scope. |
| `notApplicable` | The area does not apply to this project — nothing was routed, with positive evidence of absence (`codespecs_prompt.md` §6.4). |
| `insufficient` | The extract is missing required inputs — the run stops for this area until its L0 decision resolves. |

### CsLocus

One of the three generated projects (`codespecs_mapping.md` §4.2).

| Value | Meaning |
|-------|---------|
| `shared` | The project both others depend on. |
| `client` | The client-only project. |
| `server` | The server-only project. |

### CsBodyShape

What a method body does, as far as the "compiles but does not execute" invariants of `codespecs_derivation_contract.md` §2.4 care.

| Value | Meaning |
|-------|---------|
| `none` | No body at all — abstract, external, or a field/getter declaration. |
| `throwOnly` | The entire body is a single `throw`. |
| `returnsValue` | The body returns a value. |
| `other` | A body that is neither of the above. |

### CsStatementKind

What kind of statement one line of a generated body is.

| Value | Meaning |
|-------|---------|
| `call` | `codespecs_derivation_contract.md` §2.4 kind 1 or 2 — a call on the collaborator or on a named substrate. |
| `localBinding` | `codespecs_derivation_contract.md` §2.4 kind 3 — a `final` local binding of a call's result. |
| `controlFlow` | `codespecs_derivation_contract.md` §2.4 kind 4 — `if` / `for` / `switch` / `while`. |
| `returned` | `codespecs_derivation_contract.md` §2.4 kind 5 — a `return`. |
| `thrown` | A `throw`. |
| `other` | Anything else, which `codespecs_derivation_contract.md` §2.4 admits nowhere. |

### CsDeclarationKind

What kind of Dart declaration a [CsDeclaration] stands for.

| Value | Meaning |
|-------|---------|
| `classType` | A top-level `class`. |
| `enumType` | A top-level `enum`. |
| `mixinType` | A top-level `mixin`. |
| `topLevelVariable` | A top-level variable. |
| `topLevelFunction` | A top-level function. |
| `field` | An instance or static field of a class. |
| `method` | A method, getter or setter of a class. |
| `constructor` | A constructor of a class. |

### CsCallPosition

Where a collaborator call sits in the body that makes it.

| Value | Meaning |
|-------|---------|
| `returned` | The call is the body's `return` — `codespecs_derivation_contract.md` §2.4 B3's last contributing step. |
| `statement` | The call is a statement of its own — an earlier contributing step. |
| `guard` | The call is a branch condition — a `codespecs_derivation_contract.md` §2.4 B4 guard. |
| `binding` | The call initialises a local binding, which `codespecs_derivation_contract.md` §2.4 B3 does not emit; check 28 owns that breach, so check 30 does not judge the signature. |

## Global Functions and Constants
