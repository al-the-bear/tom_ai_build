/// Section 7: Business Object and Data Model [PD00-BUS]. Seeds → BDM.
///
/// Conceptual overview of the business data the system manages.
library;

import 'package:tom_core_kernel/tom_core_kernel.dart';


/// 7. Business Object and Data Model [PD00-BUS]. Seeds → BDM.
@tomReflector
class BusinessObjectAndDataModel {
  final String? content;

  /// 7.1. Data Model [PD00-BUS-DAT].
  final DataModel dataModel;

  /// 7.2. Business Object Model [PD00-BUS-BUS].
  final BusinessObjectModel businessObjectModel;

  /// 7.3. Function Model [PD00-BUS-FUN].
  final FunctionModel functionModel;

  const BusinessObjectAndDataModel({
    this.content,
    this.dataModel = const DataModel(),
    this.businessObjectModel = const BusinessObjectModel(),
    this.functionModel = const FunctionModel(),
  });
}

// ---------------------------------------------------------------------------
// 7.1 Data Model
// ---------------------------------------------------------------------------

/// 7.1. Data Model [PD00-BUS-DAT].
@tomReflector
class DataModel {
  final String? content;

  /// 7.1.1. Entity Overview [PD00-BUS-DAT-ENT] — contains 1+× Data Entity.
  final List<DataEntityEntry> entities;

  /// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
  final String? entityRelationships;

  /// 7.1.3. Entity-Relationship Diagram [PD00-BUS-DAT-DIA] (mermaid).
  final String? erDiagram;

  /// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
  final DataClassification dataClassification;

  const DataModel({
    this.content,
    this.entities = const [],
    this.entityRelationships,
    this.erDiagram,
    this.dataClassification = const DataClassification(),
  });
}

/// A data entity entry [PD00-BUS-DAT-ENT-nn] (form).
@tomReflector
class DataEntityEntry {
  final String? content;
  final String? entityName;
  final String? description;
  final String? category;
  final String? keyAttributes;
  final String? estimatedRecordCount;
  final String? growthRate;
  final String? retentionPolicy;

  const DataEntityEntry({
    this.content,
    this.entityName,
    this.description,
    this.category,
    this.keyAttributes,
    this.estimatedRecordCount,
    this.growthRate,
    this.retentionPolicy,
  });
}

/// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
@tomReflector
class DataClassification {
  final String? content;
  final List<DataClassificationEntry> items;

  const DataClassification({this.content, this.items = const []});
}

/// A data classification entry (form).
@tomReflector
class DataClassificationEntry {
  final String? content;
  final String? classification;
  final String? description;
  final String? handlingRequirements;
  final String? retentionPolicy;
  final String? accessRestrictions;

  const DataClassificationEntry({
    this.content,
    this.classification,
    this.description,
    this.handlingRequirements,
    this.retentionPolicy,
    this.accessRestrictions,
  });
}

// ---------------------------------------------------------------------------
// 7.2 Business Object Model
// ---------------------------------------------------------------------------

/// 7.2. Business Object Model [PD00-BUS-BUS].
@tomReflector
class BusinessObjectModel {
  final String? content;

  /// 7.2.1. Object Catalog [PD00-BUS-BUS-CAT] — contains 1+× Business Object.
  final List<BusinessObjectEntry> objects;

  /// 7.2.2. Business Object Diagram [PD00-BUS-BUS-DIA] (mermaid).
  final String? objectDiagram;

  const BusinessObjectModel({
    this.content,
    this.objects = const [],
    this.objectDiagram,
  });
}

/// A business object entry [PD00-BUS-BUS-CAT-nn] (form).
///
/// Includes optional lifecycle state transitions subsection.
@tomReflector
class BusinessObjectEntry {
  final String? content;
  final String? objectName;
  final String? category;
  final String? description;
  final List<String> keyStates;
  final List<String> keyBusinessRules;

  /// Lifecycle State Transitions [PD00-BUS-BUS-CAT-nn-LIF] (description).
  final String? lifecycleTransitions;

  const BusinessObjectEntry({
    this.content,
    this.objectName,
    this.category,
    this.description,
    this.keyStates = const [],
    this.keyBusinessRules = const [],
    this.lifecycleTransitions,
  });
}

// ---------------------------------------------------------------------------
// 7.3 Function Model
// ---------------------------------------------------------------------------

/// 7.3. Function Model [PD00-BUS-FUN].
@tomReflector
class FunctionModel {
  final String? content;

  /// 7.3.1. Function Decomposition [PD00-BUS-FUN-DEC].
  final String? functionDecomposition;

  /// 7.3.2. Function-to-Data Matrix [PD00-BUS-FUN-MAT].
  final String? functionToDataMatrix;

  /// 7.3.3. Business Rules [PD00-BUS-FUN-RUL] — contains 1+× Business Rule.
  final List<BusinessRuleEntry> businessRules;

  const FunctionModel({
    this.content,
    this.functionDecomposition,
    this.functionToDataMatrix,
    this.businessRules = const [],
  });
}

/// A business rule entry [PD00-BUS-FUN-RUL-nn] (form).
@tomReflector
class BusinessRuleEntry {
  final String? content;
  final String? ruleId;
  final String? ruleName;
  final String? description;
  final String? affectedObjects;
  final String? affectedFunctions;
  final String? enforcement;
  final String? exceptionHandling;

  const BusinessRuleEntry({
    this.content,
    this.ruleId,
    this.ruleName,
    this.description,
    this.affectedObjects,
    this.affectedFunctions,
    this.enforcement,
    this.exceptionHandling,
  });
}
