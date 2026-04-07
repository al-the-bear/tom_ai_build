import '../common/enums.dart';

/// Section 7: Business Object and Data Model [PD00-BUS]. Seeds → BDM.
///
/// Conceptual overview of the business data the system manages.
class BusinessObjectAndDataModel {
  /// 7.1. Data Model [PD00-BUS-DAT].
  final DataModel dataModel;

  /// 7.2. Business Object Model [PD00-BUS-BUS].
  final BusinessObjectModel businessObjectModel;

  /// 7.3. Function Model [PD00-BUS-FUN].
  final FunctionModel functionModel;

  const BusinessObjectAndDataModel({
    this.dataModel = const DataModel(),
    this.businessObjectModel = const BusinessObjectModel(),
    this.functionModel = const FunctionModel(),
  });
}

// ---------------------------------------------------------------------------
// 7.1 Data Model
// ---------------------------------------------------------------------------

/// 7.1. Data Model [PD00-BUS-DAT].
class DataModel {
  /// 7.1.1. Entity Overview [PD00-BUS-DAT-ENT] — contains 1+× DataEntity.
  final List<DataEntity> entities;

  /// 7.1.2. Entity Relationships [PD00-BUS-DAT-REL].
  final String? entityRelationships;

  /// 7.1.3. Entity-Relationship Diagram [PD00-BUS-DAT-DIA] (mermaid).
  final String? erDiagram;

  /// 7.1.4. Data Classification [PD00-BUS-DAT-CLA].
  final String? dataClassificationDescription;

  const DataModel({
    this.entities = const [],
    this.entityRelationships,
    this.erDiagram,
    this.dataClassificationDescription,
  });
}

/// A data entity [PD00-BUS-DAT-ENT-nn].
class DataEntity {
  final String entityName;
  final String description;
  final DataCategory? category;
  final String keyAttributes;
  final String? estimatedRecordCount;
  final String? growthRate;
  final String? retentionPolicy;

  const DataEntity({
    required this.entityName,
    required this.description,
    this.category,
    required this.keyAttributes,
    this.estimatedRecordCount,
    this.growthRate,
    this.retentionPolicy,
  });
}

// ---------------------------------------------------------------------------
// 7.2 Business Object Model
// ---------------------------------------------------------------------------

/// 7.2. Business Object Model [PD00-BUS-BUS].
class BusinessObjectModel {
  /// 7.2.1. Object Catalog [PD00-BUS-BUS-CAT] — contains 1+× BusinessObject.
  final List<BusinessObject> objects;

  /// 7.2.2. Business Object Diagram [PD00-BUS-BUS-DIA] (mermaid).
  final String? objectDiagram;

  const BusinessObjectModel({
    this.objects = const [],
    this.objectDiagram,
  });
}

/// A business object [PD00-BUS-BUS-CAT-nn].
class BusinessObject {
  final String objectName;
  final String category;
  final String description;
  final String keyStates;
  final String? keyBusinessRules;

  /// Optional lifecycle state transitions description.
  final String? lifecycleTransitions;

  const BusinessObject({
    required this.objectName,
    required this.category,
    required this.description,
    required this.keyStates,
    this.keyBusinessRules,
    this.lifecycleTransitions,
  });
}

// ---------------------------------------------------------------------------
// 7.3 Function Model
// ---------------------------------------------------------------------------

/// 7.3. Function Model [PD00-BUS-FUN].
class FunctionModel {
  /// 7.3.1. Function Decomposition [PD00-BUS-FUN-DEC].
  final String? functionDecomposition;

  /// 7.3.2. Function-to-Data Matrix [PD00-BUS-FUN-MAT].
  final String? functionToDataMatrix;

  /// 7.3.3. Business Rules [PD00-BUS-FUN-RUL] — contains 1+× BusinessRule.
  final List<BusinessRule> businessRules;

  const FunctionModel({
    this.functionDecomposition,
    this.functionToDataMatrix,
    this.businessRules = const [],
  });
}

/// A business rule [PD00-BUS-FUN-RUL-nn].
class BusinessRule {
  final String ruleId;
  final String ruleName;
  final String description;
  final String affectedObjects;
  final String affectedFunctions;
  final String enforcement;
  final String? exceptionHandling;

  const BusinessRule({
    required this.ruleId,
    required this.ruleName,
    required this.description,
    required this.affectedObjects,
    required this.affectedFunctions,
    required this.enforcement,
    this.exceptionHandling,
  });
}
