# Field Classification Document

Classification of every non-content `String?` field in `tom_specs_model`.
Categories: **form** (short value), **text** (short description, 1-3 sentences),
**long** (narrative, multi-paragraph → TextSection in Stage 3),
**ref** (cross-reference → @Reference in Stage 3).

## document_header.dart

| Class | Field | Category |
|-------|-------|----------|
| DocumentHeader | documentId | form |
| DocumentHeader | project | form |
| DocumentHeader | version | form |
| DocumentHeader | date | form |
| DocumentHeader | author | form |
| DocumentHeader | status | form |

## requirement.dart

| Class | Field | Category |
|-------|-------|----------|
| Requirement | requirementId | form |
| Requirement | title | form |
| Requirement | description | text |
| Requirement | priority:Priority | form |
| Requirement | source | form |
| Requirement | rationale | text |
| Requirement | acceptanceCriteria | form |

## risk.dart

| Class | Field | Category |
|-------|-------|----------|
| Risk | riskId | form |
| Risk | name | form |
| Risk | description | text |
| Risk | probability:Probability | form |
| Risk | impact:Impact | form |
| Risk | mitigation | text |
| Risk | riskOwner | form |
| Risk | reviewFrequency | form |

## section_meta.dart

| Class | Field | Category |
|-------|-------|----------|
| SectionMeta | sectionId | form |
| SectionMeta | type:SectionType | form |
| SectionMeta | seeds | form |

## access_authorization.dart

| Class | Field | Category |
|-------|-------|----------|
| UserManagement | userLifecycle | long |
| UserCategoryDefinition | categoryName | form |
| UserCategoryDefinition | description | text |
| UserCategoryDefinition | accessLevel | form |
| UserCategoryDefinition | estimatedCount | form |
| UserAttributeEntry | attributeName | form |
| UserAttributeEntry | dataType | form |
| UserAttributeEntry | source | form |
| UserAttributeEntry | required | form |
| Identification | identitySources | long |
| Identification | identityVerification | long |
| Identification | identityProviders | long |
| Identification | singleSignOn | long |
| Authentication | authenticationFlow | long |
| Authentication | passwordPolicy | long |
| Authentication | sessionManagement | long |
| AuthenticationMethodEntry | methodName | form |
| AuthenticationMethodEntry | methodType | form |
| AuthenticationMethodEntry | applicableUserCategories | form |
| AuthenticationMethodEntry | securityLevel | form |
| AuthenticationMethodEntry | description | text |
| ResourceProtection | dataLevelSecurity | long |
| ResourceProtection | apiSecurity | long |
| ResourceProtection | fileAndStorageSecurity | long |
| UserAuthorization | authorizationModel | long |
| UserAuthorization | roleHierarchy | long |
| UserAuthorization | tenantIsolation | long |
| AuthorizationGroupEntry | groupName | form |
| AuthorizationGroupEntry | description | text |
| AuthorizationGroupEntry | membershipCriteria | form |
| RoleReferenceEntry | roleName | form |
| AuthorizationRoleEntry | roleName | form |
| AuthorizationRoleEntry | description | text |
| AuthorizationRoleEntry | inheritsFrom | form |
| ResponsibilityReferenceEntry | responsibility | form |
| ResponsibilityReferenceEntry | description | text |
| EntitlementReferenceEntry | entitlementName | form |
| RoleExclusionEntry | excludedRole | form |
| RoleExclusionEntry | reason | form |
| RoleHolderEntry | holderDescription | form |
| RoleHolderEntry | department | form |
| EntitlementEntry | entitlementName | form |
| EntitlementEntry | description | text |
| EntitlementEntry | accessType | form |
| EntitlementEntry | conditions | form |
| ResourceKeyReferenceEntry | resourceKey | form |
| ResourceKeyEntry | resourceKey | form |
| ResourceKeyEntry | resourceType | form |
| ResourceKeyEntry | description | text |
| ResourceKeyEntry | protectionLevel | form |
| SensitiveDataEncryption | encryptionAtRest | long |
| SensitiveDataEncryption | encryptionInTransit | long |
| SensitiveDataEncryption | keyManagement | long |
| Audit | auditTrail | long |
| Audit | complianceReporting | long |
| Audit | retentionPolicy | long |
| Logging | logFormat | long |
| Logging | logLevels | long |
| SecurityEventEntry | eventName | form |
| SecurityEventEntry | eventType | form |
| SecurityEventEntry | description | text |
| SecurityEventEntry | severity | form |
| SecurityEventEntry | responseAction | form |

## administrative.dart

| Class | Field | Category |
|-------|-------|----------|
| Administrative | otherAdministrative | long |
| OrganizationStructure | orgChartExplanation | long |
| CommitteeMemberEntry | name | form |
| CommitteeMemberEntry | organizationRole | form |
| CommitteeMemberEntry | committeeRole | form |
| CommitteeMemberEntry | decisionAuthority | form |
| CommitteeMemberEntry | meetingAttendance | form |
| TeamMemberEntry | name | form |
| TeamMemberEntry | projectRole | form |
| TeamMemberEntry | organization | form |
| TeamMemberEntry | allocation | form |
| TeamMemberEntry | startDate | form |
| TeamMemberEntry | endDate | form |
| TeamMemberEntry | specialSkills | form |
| TeamMemberEntry | reportingTo | form |
| DistributionRecipientEntry | name | form |
| DistributionRecipientEntry | role | form |
| DistributionRecipientEntry | organization | form |
| DistributionRecipientEntry | distributionMethod | form |
| ChangeProcess | approvalAuthority | form |
| ChangeProcess | escalationPath | form |
| ChangeRoleEntry | roleName | form |
| ChangeRoleEntry | responsibility | form |
| ChangeStepEntry | stepName | form |
| ChangeStepEntry | description | text |
| ChangeStepEntry | responsibleRole | form |
| ChangeStepEntry | inputArtifacts | form |
| ChangeStepEntry | outputArtifacts | form |
| ChangeStepEntry | approvalCriteria | form |
| ChangeImpactCriterionEntry | criterion | form |
| ChangeImpactCriterionEntry | impactLevel | form |
| ChangeImpactCriterionEntry | description | text |
| ChangeImpactCriterionEntry | approvalRequired | form |
| ReferenceDocumentEntry | documentTitle | form |
| ReferenceDocumentEntry | version | form |
| ReferenceDocumentEntry | author | form |
| ReferenceDocumentEntry | date | form |
| ReferenceDocumentEntry | purpose | text |
| ReferenceDocumentEntry | location | form |

## business_data_model.dart

| Class | Field | Category |
|-------|-------|----------|
| DataEntityEntry | entityName | form |
| DataEntityEntry | description | text |
| DataEntityEntry | category | form |
| DataEntityEntry | estimatedRecordCount | form |
| DataEntityEntry | growthRate | form |
| DataEntityEntry | retentionPolicy | long |
| DataAttributeEntry | attributeName | form |
| DataAttributeEntry | dataType | form |
| DataAttributeEntry | length | form |
| DataAttributeEntry | format | form |
| DataAttributeEntry | mandatory | form |
| DataAttributeEntry | description | text |
| KeyAttributeEntry | attributeName | form |
| KeyAttributeEntry | keyType | form |
| KeyAttributeEntry | referencedEntity | ref |
| KeyAttributeEntry | description | text |
| EntityRelationshipEntry | sourceEntity | ref |
| EntityRelationshipEntry | targetEntity | ref |
| EntityRelationshipEntry | relationshipType | form |
| EntityRelationshipEntry | cardinality | form |
| EntityRelationshipEntry | description | text |
| DataClassificationEntry | classification | form |
| DataClassificationEntry | description | text |
| DataClassificationEntry | retentionPolicy | long |
| HandlingRequirementEntry | requirement | form |
| HandlingRequirementEntry | description | text |
| AccessRestrictionEntry | restriction | form |
| AccessRestrictionEntry | enforcement | form |
| BusinessObjectEntry | objectName | form |
| BusinessObjectEntry | category | form |
| BusinessObjectEntry | description | text |
| BusinessObjectAttributeEntry | attributeName | form |
| BusinessObjectAttributeEntry | type | form |
| BusinessObjectAttributeEntry | length | form |
| BusinessObjectAttributeEntry | format | form |
| BusinessObjectAttributeEntry | description | text |
| BusinessObjectAttributeEntry | mandatory | form |
| BusinessObjectAttributeEntry | defaultValue | form |
| BusinessObjectAttributeEntry | validationRules | form |
| ObjectStateEntry | stateName | form |
| ObjectStateEntry | description | text |
| BusinessRuleReferenceEntry | ruleName | form |
| BusinessRuleReferenceEntry | description | text |
| LifecycleTransitionEntry | fromState | form |
| LifecycleTransitionEntry | toState | form |
| LifecycleTransitionEntry | trigger | form |
| FunctionModel | functionDecomposition | form |
| FunctionModel | functionToDataMatrix | form |
| BusinessRuleEntry | ruleId | form |
| BusinessRuleEntry | ruleName | form |
| BusinessRuleEntry | description | text |
| BusinessRuleEntry | enforcement | form |
| BusinessRuleEntry | exceptionHandling | form |
| AffectedObjectEntry | objectName | form |
| AffectedObjectEntry | impact | text |
| AffectedFunctionEntry | functionName | form |
| AffectedFunctionEntry | impact | text |

## components.dart

| Class | Field | Category |
|-------|-------|----------|
| ComponentsToUse | componentRoleInSystem | long |
| ReuseGoalEntry | goal | form |
| ReuseGoalEntry | rationale | text |
| EvaluationCriterionEntry | criterion | form |
| EvaluationCriterionEntry | weight | form |
| EvaluationCriterionEntry | description | text |
| DependencyEntry | dependencyName | ref |
| DependencyEntry | version | form |
| DependencyEntry | purpose | text |
| DependencyEntry | criticality | form |
| DependencyEntry | alternative | form |
| ComponentEntry | componentName | form |
| ComponentEntry | version | form |
| ComponentEntry | category | form |
| ComponentEntry | purpose | text |
| ComponentEntry | documentation | form |
| ComponentEntry | usageRights | long |
| ComponentInterfaceEntry | interfaceName | form |
| ComponentInterfaceEntry | interfaceType | form |
| ComponentInterfaceEntry | description | text |
| ComponentLicensingEntry | licenseModel | form |
| ComponentLicensingEntry | annualCost | form |
| ComponentLicensingEntry | renewal | form |
| ComponentLicensingEntry | redistribution | form |
| ComponentResponsibilitiesEntry | technicalContact | form |
| ComponentResponsibilitiesEntry | supportModel | form |
| ComponentResponsibilitiesEntry | escalation | form |
| ComponentResponsibilitiesEntry | updateCadence | form |
| ContingencyPlanEntry | component | form |
| ContingencyPlanEntry | triggerCondition | form |
| ContingencyPlanEntry | action | form |
| ContingencyPlanEntry | responsibleParty | form |
| ComponentRiskEntry | riskId | form |
| ComponentRiskEntry | component | form |
| ComponentRiskEntry | risk | form |
| ComponentRiskEntry | probability | form |
| ComponentRiskEntry | impact | text |
| ComponentRiskEntry | mitigation | text |
| ComponentRiskEntry | contingencyTrigger | form |

## current_state_analysis.dart

| Class | Field | Category |
|-------|-------|----------|
| ExistingSystemsLandscape | currentArchitecture | long |
| ExistingSystemEntry | systemName | form |
| ExistingSystemEntry | technology | form |
| ExistingSystemEntry | purpose | text |
| ExistingSystemEntry | activeUsers | form |
| ExistingSystemEntry | dataVolume | form |
| ExistingSystemEntry | operationalSince | form |
| ExistingSystemEntry | supportStatus | form |
| LimitationEntry | limitation | form |
| LimitationEntry | impact | text |
| SystemDependencyEntry | sourceSystem | ref |
| SystemDependencyEntry | targetSystem | ref |
| SystemDependencyEntry | dependencyType | form |
| SystemDependencyEntry | criticality | form |
| SystemIntegrationEntry | sourceSystem | ref |
| SystemIntegrationEntry | targetSystem | ref |
| SystemIntegrationEntry | protocol | form |
| SystemIntegrationEntry | dataExchanged | form |
| SystemIntegrationEntry | direction | form |
| SystemIntegrationEntry | frequency | form |
| CurrentBusinessProcess | processName | form |
| CurrentWorkflowEntry | processName | form |
| CurrentWorkflowEntry | trigger | form |
| CurrentWorkflowEntry | output | form |
| CurrentWorkflowEntry | cycleTime | form |
| WorkflowStepEntry | stepName | form |
| WorkflowStepEntry | description | text |
| WorkflowActorEntry | actorName | form |
| WorkflowActorEntry | role | form |
| ProcessMetricEntry | metricName | form |
| ProcessMetricEntry | processReference | ref |
| ProcessMetricEntry | currentValue | form |
| ProcessMetricEntry | unit | form |
| ProcessMetricEntry | measurementMethod | form |
| ProcessMetricEntry | frequency | form |
| PainPointEntry | painPoint | form |
| PainPointEntry | description | text |
| PainPointEntry | impact | text |
| PainPointEntry | affectedProcess | form |
| PainPointEntry | severity | form |
| PainPointEntry | workaround | form |
| GapEntry | gapName | form |
| GapEntry | description | text |
| GapEntry | businessImpact | form |
| GapEntry | affectedProcess | form |
| GapEntry | priority | form |
| GapEntry | proposedResolution | form |
| CurrentDataLandscape | dataQualityAssessment | long |
| DataSourceEntry | dataStoreName | form |
| DataSourceEntry | storeType | form |
| DataSourceEntry | technology | form |
| DataSourceEntry | dataFormat | form |
| DataSourceEntry | estimatedVolume | form |
| DataSourceEntry | growthRate | form |
| DataSourceEntry | qualityLevel | form |
| DataSourceEntry | owner | form |
| DataSourceEntry | retentionPolicy | long |

## delivery_acceptance.dart

| Class | Field | Category |
|-------|-------|----------|
| DeliverableEntry | deliverableName | form |
| DeliverableEntry | description | text |
| DeliverableEntry | deliveryDate | form |
| DeliverableEntry | format | form |
| DeliverableEntry | acceptanceCriteria | form |
| AcceptancePlan | defectResolution | long |
| AcceptancePlan | signOffProcess | long |
| AcceptancePlan | warranty | long |
| DeliveryAcceptanceCriterionEntry | criterion | form |
| DeliveryAcceptanceCriterionEntry | category | form |
| DeliveryAcceptanceCriterionEntry | verificationMethod | form |
| DeliveryAcceptanceCriterionEntry | acceptanceThreshold | form |
| AcceptanceProcess | timeline | long |
| AcceptanceProcess | participants | form |
| AcceptanceProcess | escalationProcess | form |
| AcceptanceStepEntry | stepName | form |
| AcceptanceStepEntry | description | text |
| UserAcceptanceTesting | scope | text |
| UserAcceptanceTesting | environment | form |
| UserAcceptanceTesting | participants | form |
| UserAcceptanceTesting | schedule | form |
| UserAcceptanceTesting | exitCriteria | form |
| TestScenarioEntry | scenarioName | form |
| TestScenarioEntry | description | text |
| TestScenarioEntry | expectedResult | form |

## organizational_framework.dart

| Class | Field | Category |
|-------|-------|----------|
| NewOrganizationStructure | transitionTimeline | long |
| OrganizationalChangeEntry | area | form |
| OrganizationalChangeEntry | currentState | form |
| OrganizationalChangeEntry | targetState | form |
| OrganizationalChangeEntry | rationale | text |
| OrganizationalChangeEntry | impact | text |
| StaffingPlan | headcountSummary | long |
| StaffingPlan | recruitmentTimeline | long |
| StaffingPlan | budget | long |
| StaffingEntry | roleTitle | form |
| StaffingEntry | department | form |
| StaffingEntry | fteCount | form |
| StaffingEntry | recruitmentStatus | form |
| StaffingEntry | targetStartDate | form |
| NewRoleEntry | roleTitle | form |
| NewRoleEntry | department | form |
| NewRoleEntry | reportingLine | form |
| NewRoleEntry | fteAllocation | form |
| NewRoleEntry | startDate | form |
| RoleResponsibilityEntry | responsibility | form |
| RoleResponsibilityEntry | description | text |
| SkillEntry | skillName | form |
| SkillEntry | proficiencyLevel | form |
| ChangedRoleEntry | roleTitle | form |
| ChangedRoleEntry | currentDepartment | form |
| ChangedRoleEntry | changedReportingLine | form |
| ChangedRoleEntry | trainingRequired | form |
| WorkplaceDescriptionEntry | userCategory | form |
| EquipmentRequirementEntry | equipmentType | form |
| EquipmentRequirementEntry | specification | form |
| EquipmentRequirementEntry | quantity | form |
| EquipmentRequirementEntry | purpose | text |
| TrainingRequirementEntry | trainingTopic | form |
| TrainingRequirementEntry | targetAudience | form |
| TrainingRequirementEntry | format | form |
| TrainingRequirementEntry | duration | form |
| TrainingRequirementEntry | schedule | form |

## project_organization_process.dart

| Class | Field | Category |
|-------|-------|----------|
| RoleAdjustmentEntry | roleName | form |
| RoleAdjustmentEntry | adjustment | form |
| RoleAdjustmentEntry | rationale | text |
| QualityGateAdjustmentEntry | gateName | form |
| QualityGateAdjustmentEntry | adjustment | form |
| QualityGateAdjustmentEntry | rationale | text |
| ProcessAdjustmentEntry | processName | form |
| ProcessAdjustmentEntry | adjustment | form |
| ProcessAdjustmentEntry | rationale | text |
| ToolEntry | toolName | form |
| ToolEntry | purpose | text |
| ToolEntry | version | form |
| ToolEntry | category | form |
| EnvironmentEntry | environmentName | form |
| EnvironmentEntry | purpose | text |
| EnvironmentEntry | infrastructure | form |
| EnvironmentEntry | accessPolicy | form |
| EnvironmentEntry | dataPolicy | form |

## system_overview.dart

| Class | Field | Category |
|-------|-------|----------|
| SystemDescription | systemPurpose | long |
| SystemDescription | systemContext | long |
| SystemDescription | taskArea | long |
| UserInteractionModel | sessionModel | long |
| UserInteractionModel | concurrencyModel | long |
| InteractionPatternEntry | patternName | form |
| InteractionPatternEntry | description | text |
| InteractionChannelEntry | channelName | form |
| InteractionChannelEntry | channelType | form |
| InteractionChannelEntry | targetUserCategories | form |
| InteractionChannelEntry | description | text |
| InteractionChannelEntry | availabilityRequirement | form |
| UserCategoryEntry | categoryName | form |
| UserCategoryEntry | description | text |
| UserCategoryEntry | technicalProficiency | form |
| UserCategoryEntry | frequencyOfUse | form |
| UserCategoryEntry | accessChannel | form |
| UserCategoryEntry | estimatedUserCount | form |
| UserCategoryRoleEntry | roleName | form |
| UserCategoryRoleEntry | roleDescription | form |
| UserCategoryRoleEntry | organizationUnit | form |
| UserCategoryRoleEntry | reportsTo | form |
| SystemTaskEntry | taskName | form |
| SystemTaskEntry | description | text |
| SystemTaskEntry | frequency | form |
| SystemTaskEntry | relatedUseCase | ref |
| BusinessGoalEntry | goalId | form |
| BusinessGoalEntry | goalName | form |
| BusinessGoalEntry | description | text |
| BusinessGoalEntry | successMetric | form |
| BusinessGoalEntry | currentValue | form |
| BusinessGoalEntry | targetValue | form |
| BusinessGoalEntry | measurementMethod | form |
| BusinessGoalEntry | targetDate | form |
| TechnicalGoalEntry | goalId | form |
| TechnicalGoalEntry | goalName | form |
| TechnicalGoalEntry | description | text |
| TechnicalGoalEntry | successMetric | form |
| TechnicalGoalEntry | targetValue | form |
| TechnicalGoalEntry | measurementMethod | form |
| TechnicalGoalEntry | verificationPoint | form |
| SuccessCriterionEntry | criterion | form |
| SuccessCriterionEntry | metric | form |
| SuccessCriterionEntry | targetValue | form |
| SuccessCriterionEntry | measurementMethod | form |
| SuccessCriterionEntry | verificationPoint | form |
| FunctionalRequirementEntry | requirementId | form |
| FunctionalRequirementEntry | title | form |
| FunctionalRequirementEntry | description | text |
| FunctionalRequirementEntry | priority | form |
| FunctionalRequirementEntry | source | form |
| FunctionalRequirementEntry | rationale | text |
| FunctionalRequirementEntry | relatedUseCase | ref |
| FunctionalRequirementEntry | relatedBusinessProcess | ref |
| FunctionalRequirementEntry | status | form |
| AcceptanceCriterionEntry | criterion | form |
| AcceptanceCriterionEntry | verificationMethod | form |
| DataEntityReferenceEntry | entityName | form |
| DataEntityReferenceEntry | relationship | form |
| TechnicalRequirementEntry | requirementId | form |
| TechnicalRequirementEntry | title | form |
| TechnicalRequirementEntry | description | text |
| TechnicalRequirementEntry | priority | form |
| TechnicalRequirementEntry | source | form |
| TechnicalRequirementEntry | rationale | text |
| TechnicalRequirementEntry | verificationApproach | form |
| TechnicalRequirementEntry | status | form |
| SecurityRequirementEntry | requirementId | form |
| SecurityRequirementEntry | title | form |
| SecurityRequirementEntry | description | text |
| SecurityRequirementEntry | priority | form |
| SecurityRequirementEntry | source | form |
| SecurityRequirementEntry | rationale | text |
| SecurityRequirementEntry | complianceReference | ref |
| SecurityRequirementEntry | status | form |
| OrganizationalRequirementEntry | requirementId | form |
| OrganizationalRequirementEntry | title | form |
| OrganizationalRequirementEntry | description | text |
| OrganizationalRequirementEntry | priority | form |
| OrganizationalRequirementEntry | source | form |
| OrganizationalRequirementEntry | rationale | text |
| OrganizationalRequirementEntry | status | form |
| SystemToReplaceEntry | systemName | form |
| SystemToReplaceEntry | currentTechnology | form |
| SystemToReplaceEntry | replacementStrategy | form |
| SystemToReplaceEntry | dataMigrationScope | form |
| SystemToReplaceEntry | migrationComplexity | form |
| SystemToReplaceEntry | decommissionDate | form |
| SystemDependencyReferenceEntry | dependencyName | ref |
| SystemDependencyReferenceEntry | dependencyType | form |
| SystemMigrationConsiderations | migrationApproach | form |
| SystemMigrationConsiderations | dataTransformationNeeds | form |
| SystemMigrationConsiderations | estimatedEffort | form |
| SystemMigrationConsiderations | rollbackStrategy | long |
| MigrationRiskReferenceEntry | riskDescription | form |
| MigrationRiskReferenceEntry | mitigation | text |
| MigrationConsiderations | strategy | long |
| MigrationConsiderations | timeline | long |
| MigrationConsiderations | dataMapping | long |
| MigrationConsiderations | rollbackStrategy | long |
| MigrationRiskEntry | riskDescription | form |
| MigrationRiskEntry | probability | form |
| MigrationRiskEntry | impact | text |
| MigrationRiskEntry | mitigation | text |
| ExternalInterfaceEntry | interfaceId | form |
| ExternalInterfaceEntry | externalSystem | form |
| ExternalInterfaceEntry | direction | form |
| ExternalInterfaceEntry | purpose | text |
| ExternalInterfaceEntry | dataExchanged | form |
| ExternalInterfaceEntry | protocol | form |
| ExternalInterfaceEntry | frequency | form |
| ExternalInterfaceEntry | volume | form |
| ExternalInterfaceEntry | authentication | form |
| OutOfScopeEntry | item | form |
| OutOfScopeEntry | rationale | text |
| OutOfScopeEntry | futureConsideration | form |
| AssumptionEntry | assumption | form |
| AssumptionEntry | rationale | text |
| AssumptionEntry | riskIfWrong | form |
| AssumptionEntry | validationApproach | form |
| OrganizationalEnvironment | structure | long |
| OrganizationalEnvironment | decisionMaking | long |
| OrganizationalEnvironment | culturalConsiderations | long |
| ResponsibilityEntry | area | form |
| ResponsibilityEntry | owner | form |
| ResponsibilityEntry | description | text |
| ResponsibilityEntry | scope | text |
| TechnicalFrameworkConditions | existingInfrastructure | long |
| TechnologyStandardEntry | standard | form |
| TechnologyStandardEntry | description | text |
| IntegrationConstraintEntry | constraint | form |
| IntegrationConstraintEntry | impactedSystem | form |
| ConstraintEntry | constraint | form |
| ConstraintEntry | type | form |
| ConstraintEntry | impact | text |
| ConstraintEntry | mitigation | text |
| FrameworkDependencyEntry | dependency | form |
| FrameworkDependencyEntry | type | form |
| FrameworkDependencyEntry | impact | text |
| FrameworkDependencyEntry | mitigation | text |
| RiskEntry | riskId | form |
| RiskEntry | riskName | form |
| RiskEntry | description | text |
| RiskEntry | probability | form |
| RiskEntry | impact | text |
| RiskEntry | mitigation | text |
| RiskEntry | riskOwner | form |
| RiskEntry | reviewFrequency | form |

## system_quality_goals.dart

| Class | Field | Category |
|-------|-------|----------|
| QualityFramework | qualityObjectivesOverview | long |
| QualityCategoryEntry | categoryName | form |
| QualityCategoryEntry | description | text |
| UserQualityCriteria | usability | long |
| UserQualityCriteria | functionalCompleteness | long |
| UserQualityCriteria | correctness | long |
| TechnicalQualityCriteria | efficiency | long |
| TechnicalQualityCriteria | portability | long |
| TechnicalQualityCriteria | flexibility | long |
| TechnicalQualityCriteria | security | long |
| TechnicalQualityCriteria | maintainability | long |
| TechnicalQualityCriteria | reliability | long |
| OperationsQualityCriteria | availability | long |
| OperationsQualityCriteria | serviceLevelRequirements | long |
| OperationsQualityCriteria | monitoringAndPrevention | long |
| OperationsQualityCriteria | itSecurityOperations | long |
| DocumentationQualityCriteria | readability | long |
| DocumentationQualityCriteria | completeness | long |
| DocumentationQualityCriteria | correctness | long |
| DocumentationQualityCriteria | changeability | long |
| QualityPrioritization | weightedQualityMatrix | long |
| TradeOffDecisionEntry | decision | form |
| TradeOffDecisionEntry | qualitiesInConflict | form |
| TradeOffDecisionEntry | rationale | text |
| TradeOffDecisionEntry | impact | text |
| MustPassCriterionEntry | criterion | form |
| MustPassCriterionEntry | verificationMethod | form |
| MustPassCriterionEntry | acceptanceThreshold | form |
| QualityGateCheckEntry | checkItem | form |
| QualityGateCheckEntry | qualityCategory | form |
| QualityGateCheckEntry | verificationMethod | form |
| QualityGateCheckEntry | responsibleParty | form |

## system_stage_plan.dart

| Class | Field | Category |
|-------|-------|----------|
| StagingStrategy | stagingApproach | long |
| StagingStrategy | rationale | text |
| StageOverview | stageSummary | long |
| StageEntry | stageNumber | form |
| StageEntry | stageName | form |
| StageEntry | targetGoLive | form |
| StageEntry | scopeSummary | form |
| StageEntry | featureScope | long |
| StageEntry | timeline | long |
| StageEntry | rolloutPlan | long |
| SubStageEntry | name | form |
| SubStageEntry | description | text |
| SubStageEntry | targetDate | form |
| StageSuccessCriterionEntry | criterion | form |
| StageSuccessCriterionEntry | measurementMethod | form |
| FeaturePrioritization | moscowAnalysis | long |
| FeaturePrioritization | featureStageMatrix | long |
| MigrationPhaseEntry | phaseName | form |
| MigrationPhaseEntry | description | text |
| MigrationPhaseEntry | dataScope | form |
| MigrationPhaseEntry | targetStage | form |
| MigrationPhaseEntry | verificationApproach | form |
| StageMigrationRiskEntry | risk | form |
| StageMigrationRiskEntry | probability | form |
| StageMigrationRiskEntry | impact | text |
| StageMigrationRiskEntry | mitigation | text |
| PhaseGateReviewEntry | gateName | form |
| PhaseGateReviewEntry | stage | form |
| PhaseGateReviewEntry | decisionAuthority | form |
| ReviewCriterionEntry | criterion | form |
| ReviewCriterionEntry | description | text |
| DecisionPointEntry | decisionPoint | form |
| DecisionPointEntry | timing | form |
| DecisionPointEntry | criteria | form |
| DecisionPointEntry | decisionAuthority | form |
| DecisionOptionEntry | option | form |
| DecisionOptionEntry | description | text |
| DecisionOptionEntry | implications | form |

## target_business_process.dart

| Class | Field | Category |
|-------|-------|----------|
| TargetBusinessProcessModel | processVision | long |
| TargetBusinessProcessModel | improvementSummary | long |
| DesignPrincipleEntry | principle | form |
| DesignPrincipleEntry | description | text |
| DesignPrincipleEntry | rationale | text |
| ProcessRelationshipEntry | sourceProcess | ref |
| ProcessRelationshipEntry | targetProcess | ref |
| ProcessRelationshipEntry | relationshipType | form |
| ProcessRelationshipEntry | description | text |
| BusinessProcessDescription | processId | form |
| BusinessProcessDescription | processName | form |
| BusinessProcessDescription | trigger | form |
| BusinessProcessDescription | primaryActor | form |
| BusinessProcessDescription | description | text |
| BusinessProcessDescription | expectedOutcome | form |
| BusinessProcessDescription | estimatedFrequency | form |
| BusinessProcessDescription | estimatedDuration | form |
| ActorEntry | actorName | form |
| ActorEntry | actorType | form |
| ActorEntry | description | text |
| ActorEntry | accessChannel | form |
| PrimaryInteractionEntry | useCaseReference | ref |
| PrimaryInteractionEntry | description | text |
| PrimaryInteractionEntry | frequency | form |
| PrimaryInteractionEntry | criticality | form |
| InteractionEntry | interactionId | form |
| InteractionEntry | processReference | ref |
| InteractionEntry | actor | form |
| InteractionEntry | action | form |
| InteractionEntry | systemResponse | form |
| InteractionEntry | expectedOutcome | form |
| InteractionEntry | precondition | form |
| InteractionEntry | postcondition | form |
| InteractionEntry | relatedUseCase | ref |
| ScenarioEntry | scenarioName | form |
| ScenarioEntry | description | text |
| ScenarioEntry | successCondition | form |
| ScenarioStepEntry | stepNumber | form |
| ScenarioStepEntry | description | text |
| ScenarioStepEntry | expectedResult | form |
| AlternativeFlowEntry | flowName | form |
| AlternativeFlowEntry | triggerCondition | form |
| AlternativeFlowEntry | outcome | form |
| AlternativeFlowEntry | returnPoint | form |

## technical_framework.dart

| Class | Field | Category |
|-------|-------|----------|
| BasicTechnicalRequirements | platformAndLanguage | long |
| BasicTechnicalRequirements | architectureStyle | long |
| DesignPatternEntry | patternName | form |
| DesignPatternEntry | purpose | text |
| SoftwareDesignRequirements | layeringAndModuleStructure | long |
| SoftwareDesignRequirements | developmentEnvironment | long |
| ReusableComponentEntry | componentName | form |
| ReusableComponentEntry | source | form |
| ReusableComponentEntry | purpose | text |
| StandardSoftwareRequirements | standardsCompliance | long |
| CompatibilityRequirementEntry | requirement | form |
| CompatibilityRequirementEntry | system | form |
| HardwareRequirements | serverRequirements | long |
| HardwareRequirements | clientRequirements | long |
| HardwareRequirements | networkRequirements | long |
| OperationsRequirements | backupAndRecovery | long |
| OperationsRequirements | deploymentStrategy | long |
| OperationsRequirements | monitoringAndAlerting | long |
| OperationsRequirements | maintenanceWindows | long |
| CommunicationRequirements | externalConnectivity | long |
| ProtocolEntry | protocolName | form |
| ProtocolEntry | purpose | text |
| SystemOperation | administrationRequirements | long |
| SystemOperation | maintenanceProcedures | long |
| Monitoring | healthChecksAndDiagnostics | long |
| Monitoring | capacityPlanning | long |
| Monitoring | alerting | long |
| TechnicalSecurityRequirements | dataProtectionAndPrivacy | long |
| SecurityStandardEntry | standardName | form |
| SecurityStandardEntry | version | form |
| SecurityStandardEntry | scope | text |
| SecurityAuditEntry | requirement | form |
| SecurityAuditEntry | frequency | form |

## user_interface_design.dart

| Class | Field | Category |
|-------|-------|----------|
| UserInterfaceDesign | dataStructureAlignment | long |
| UserInterfaceDesign | authorizationCompliance | long |
| DesignGoalEntry | goal | form |
| DesignGoalEntry | description | text |
| UiDesignPrincipleEntry | principle | form |
| UiDesignPrincipleEntry | rationale | text |
| PersonaEntry | personaName | form |
| PersonaEntry | age | form |
| PersonaEntry | role | form |
| PersonaEntry | technicalProficiency | form |
| PersonaEntry | typicalUsage | form |
| PersonaEntry | device | form |
| PersonaGoalEntry | goal | form |
| PersonaGoalEntry | priority | form |
| PersonaPainPointEntry | painPoint | form |
| PersonaPainPointEntry | impact | text |
| ScreenDescriptions | informationArchitecture | long |
| ScreenEntry | screenId | form |
| ScreenEntry | screenName | form |
| ScreenEntry | purpose | text |
| ScreenEntry | accessLevel | form |
| ScreenEntry | layout | form |
| ScreenElementEntry | elementName | form |
| ScreenElementEntry | elementType | form |
| ScreenUserCategoryEntry | categoryName | form |
| ScreenUserCategoryEntry | description | text |
| EntryPointEntry | entryPoint | form |
| EntryPointEntry | source | form |
| ScreenFlowStructure | navigationModel | long |
| ExportFormatEntry | formatName | form |
| ExportFormatEntry | description | text |
| ReportEntry | reportName | form |
| ReportEntry | purpose | text |
| ReportEntry | reportContent | form |
| ReportEntry | format | form |
| ReportEntry | generationTrigger | form |
| ReportEntry | customization | form |
| RecipientEntry | recipientName | form |
| RecipientEntry | role | form |
| ErrorHandlingConcept | validationFeedback | long |
| ErrorHandlingConcept | systemErrorDisplay | long |
| ErrorHandlingConcept | errorRecovery | long |
| HelpConcept | contextualHelp | long |
| HelpConcept | onboarding | long |
| HelpConcept | supportAccess | long |
| Accessibility | wcagComplianceLevel | long |
| AccessibilityCheckEntry | checkItem | form |
| AccessibilityCheckEntry | wcagCriterion | form |
| AccessibilityCheckEntry | complianceLevel | form |
| AccessibilityCheckEntry | verificationMethod | form |
| ResponsiveDesign | responsiveBehavior | long |
| BreakpointEntry | breakpointName | form |
| BreakpointEntry | minWidth | form |
| BreakpointEntry | layoutBehavior | form |
| UiComponents | componentLibrary | long |
| UiComponentEntry | componentName | form |
| UiComponentEntry | purpose | text |
| UiComponentEntry | behavior | form |
| UiComponentEntry | responsive | form |
| ComponentStateEntry | stateName | form |
| ComponentStateEntry | description | text |
| ComponentVariantEntry | variantName | form |
| ComponentVariantEntry | description | text |
| MultiLanguageSupport | localizationProcess | long |
| MultiLanguageSupport | translationProcess | long |
| MultiLanguageSupport | languageAndCountrySelection | long |
| MultiLanguageSupport | translationHandlingRequirements | long |
| RolloutSupport | userDocumentation | long |
| RolloutSupport | trainingPlan | long |
| RolloutSupport | phasedDeploymentStrategy | long |
| RolloutSupport | communicationPlan | long |
| Prototype | selectedFeatureSubset | long |
| PrototypeTypeSection | reusablePrototype | long |
| PrototypeTypeSection | trainingPrototype | long |
| PrototypeTypeSection | throwawayPrototype | long |
| PrototypeGoalEntry | goal | form |
| PrototypeGoalEntry | description | text |

## Summary

| Category | Count |
|----------|-------|
| form | 470 |
| text (short description) | 117 |
| long (narrative → TextSection) | 125 |
| ref (cross-reference → @Reference) | 19 |
| content (skip) | 300 |
| **Total non-content String?** | **731** |
