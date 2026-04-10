"""Stage 2 migration script: add section IDs and cardinality to model files.

This script:
1. Adds section IDs to entry/form classes that lack them
2. Adds 'contains 0+x' cardinality to list fields that lack it
3. Writes modified files in-place

Run from tom_specs_model directory.
"""
import re, os, glob

MODEL_DIR = 'lib/src/pd_project_definition'
COMMON_DIR = 'lib/src/common'

# ── Manual ID assignments (for classes the auto-resolver can't reach) ──
MANUAL_IDS = {
    'ProjectDefinition': 'PD00',
    'PrimaryInteractions': 'PD00-TAR-CAT-nn-ACT-nn-PRI',
    'PrimaryInteractionEntry': 'PD00-TAR-CAT-nn-ACT-nn-PRI-nn',
    'ScenarioStepEntry': 'PD00-TAR-CAT-nn-SCE-nn-SST-nn',
    'AlternativeFlowEntry': 'PD00-TAR-CAT-nn-SCE-nn-AFL-nn',
}

# Common types - these are shared across documents, no PD00 ID
COMMON_TYPES = {'DocumentHeader', 'Requirement', 'Risk', 'SectionMeta'}

# ── Auto-resolved IDs (from the analysis script) ──
AUTO_IDS = {
    'AcceptanceCriterionEntry': 'PD00-SYO-REQ-FUN-nn-ACR-nn',
    'AcceptanceStepEntry': 'PD00-DEL-ACC-PRO-nn',
    'AccessRestrictionEntry': 'PD00-BUS-DAT-CLA-nn-ARE-nn',
    'AccessibilityCheckEntry': 'PD00-USE-ACC-CHK-nn',
    'ActorEntry': 'PD00-TAR-CAT-nn-ACT-nn',
    'AffectedFunctionEntry': 'PD00-BUS-FUN-RUL-nn-AFU-nn',
    'AffectedObjectEntry': 'PD00-BUS-FUN-RUL-nn-AOB-nn',
    'AuthenticationMethodEntry': 'PD00-ACC-IDE-AUT-MET-nn',
    'BreakpointEntry': 'PD00-USE-RES-BRE-nn',
    'BusinessObjectAttributeEntry': 'PD00-BUS-BUS-CAT-nn-BOA-nn',
    'BusinessRuleReferenceEntry': 'PD00-BUS-BUS-CAT-nn-BRR-nn',
    'ChangeImpactCriterionEntry': 'PD00-ADM-CHA-CRI-nn',
    'ChangeRoleEntry': 'PD00-ADM-CHA-PRO-ROL-nn',
    'ChangeStepEntry': 'PD00-ADM-CHA-PRO-STP-nn',
    'CompatibilityRequirementEntry': 'PD00-TEC-STA-COM-nn',
    'ComponentInterfaceEntry': 'PD00-COM-COM-nn-INT-nn',
    'ComponentStateEntry': 'PD00-USE-COM-SPE-nn-STA-nn',
    'ComponentVariantEntry': 'PD00-USE-COM-SPE-nn-VAR-nn',
    'ContingencyPlanEntry': 'PD00-COM-RIS-CON-nn',
    'DataAttributeEntry': 'PD00-BUS-DAT-ENT-nn-ATT-nn',
    'DataClassificationEntry': 'PD00-BUS-DAT-CLA-nn',
    'DataEntityReferenceEntry': 'PD00-SYO-REQ-FUN-nn-DER-nn',
    'DataSourceEntry': 'PD00-CUR-DAT-SRC-nn',
    'DecisionOptionEntry': 'PD00-SSP-GOV-DEC-nn-OPT-nn',
    'DecisionPointEntry': 'PD00-SSP-GOV-DEC-nn',
    'DeliverableEntry': 'PD00-DEL-DEL-nn',
    'DeliveryAcceptanceCriterionEntry': 'PD00-DEL-ACC-CRI-nn',
    'DependencyEntry': 'PD00-COM-RUN-nn',
    'DesignGoalEntry': 'PD00-USE-VIS-GOA-nn',
    'DesignPatternEntry': 'PD00-TEC-BAS-PAT-nn',
    'DesignPrincipleEntry': 'PD00-TAR-PRI-nn',
    'DistributionRecipientEntry': 'PD00-ADM-DIS-nn',
    'EntitlementReferenceEntry': 'PD00-ACC-USA-ROL-nn-ENT-nn',
    'EntityRelationshipEntry': 'PD00-BUS-DAT-REL-nn',
    'EntryPointEntry': 'PD00-USE-SCR-INV-nn-EPT-nn',
    'EnvironmentEntry': 'PD00-POP-TOO-ENV-nn',
    'EquipmentRequirementEntry': 'PD00-ORG-WOR-nn-EQU-nn',
    'EvaluationCriterionEntry': 'PD00-COM-STR-EVA-nn',
    'ExportFormatEntry': 'PD00-USE-PRI-EXP-nn',
    'GapEntry': 'PD00-CUR-PAI-GAP-nn',
    'HandlingRequirementEntry': 'PD00-BUS-DAT-CLA-nn-HAN-nn',
    'IntegrationConstraintEntry': 'PD00-SYO-RES-TEC-INT-nn',
    'InteractionChannelEntry': 'PD00-SYO-SYD-USI-CHA-nn',
    'InteractionEntry': 'PD00-TAR-CAT-nn-INT-nn',
    'InteractionPatternEntry': 'PD00-SYO-SYD-USI-PAT-nn',
    'KeyAttributeEntry': 'PD00-BUS-DAT-ENT-nn-KEY-nn',
    'LifecycleTransitionEntry': 'PD00-BUS-BUS-CAT-nn-LIF-nn',
    'LimitationEntry': 'PD00-CUR-SYS-INV-nn-LIM-nn',
    'MigrationPhaseEntry': 'PD00-SSP-MIG-PHA-nn',
    'MigrationRiskEntry': 'PD00-SYO-SYR-MIG-RIS-nn',
    'MigrationRiskReferenceEntry': 'PD00-SYO-SYR-INV-nn-MRR-nn',
    'MustPassCriterionEntry': 'PD00-SYQ-ACC-MUS-nn',
    'ObjectStateEntry': 'PD00-BUS-BUS-CAT-nn-STA-nn',
    'OrganizationalChangeEntry': 'PD00-ORG-STR-CHA-nn',
    'PainPointEntry': 'PD00-CUR-PAI-nn',
    'PersonaGoalEntry': 'PD00-USE-VIS-PER-nn-GOA-nn',
    'PersonaPainPointEntry': 'PD00-USE-VIS-PER-nn-PAI-nn',
    'PhaseGateReviewEntry': 'PD00-SSP-GOV-GAT-nn',
    'ProcessAdjustmentEntry': 'PD00-POP-PRC-nn',
    'ProcessMetricEntry': 'PD00-CUR-PRO-nn-MET-nn',
    'ProcessRelationshipEntry': 'PD00-TAR-REL-nn',
    'ProtocolEntry': 'PD00-TEC-COM-PRO-nn',
    'PrototypeGoalEntry': 'PD00-USE-PRO-GOA-nn',
    'QualityCategoryEntry': 'PD00-SYQ-FRA-CAT-nn',
    'QualityGateAdjustmentEntry': 'PD00-POP-QGA-nn',
    'QualityGateCheckEntry': 'PD00-SYQ-ACC-GAT-nn',
    'RecipientEntry': 'PD00-USE-PRI-REP-nn-REC-nn',
    'ResourceKeyReferenceEntry': 'PD00-ACC-USA-ENT-nn-RKR-nn',
    'ResponsibilityReferenceEntry': 'PD00-ACC-USA-ROL-nn-RSP-nn',
    'ReusableComponentEntry': 'PD00-TEC-SOF-REU-nn',
    'ReuseGoalEntry': 'PD00-COM-STR-GOA-nn',
    'ReviewCriterionEntry': 'PD00-SSP-GOV-GAT-nn-RCR-nn',
    'RoleAdjustmentEntry': 'PD00-POP-ROL-nn',
    'RoleExclusionEntry': 'PD00-ACC-USA-ROL-nn-EXC-nn',
    'RoleHolderEntry': 'PD00-ACC-USA-ROL-nn-HOL-nn',
    'RoleReferenceEntry': 'PD00-ACC-USA-GRP-nn-ROL-nn',
    'RoleResponsibilityEntry': 'PD00-ORG-JOB-nn-RSP-nn',
    'ScenarioEntry': 'PD00-TAR-CAT-nn-SCE-nn',
    'ScreenElementEntry': 'PD00-USE-SCR-INV-nn-ELE-nn',
    'ScreenUserCategoryEntry': 'PD00-USE-SCR-INV-nn-UCT-nn',
    'SecurityAuditEntry': 'PD00-TEC-SEC-AUD-nn',
    'SecurityEventEntry': 'PD00-ACC-AUD-LOG-EVE-nn',
    'SecurityStandardEntry': 'PD00-TEC-SEC-ITS-nn',
    'SkillEntry': 'PD00-ORG-JOB-nn-SKL-nn',
    'StaffingEntry': 'PD00-ORG-JOB-STA-nn',
    'StageMigrationRiskEntry': 'PD00-SSP-MIG-RIS-nn',
    'StageSuccessCriterionEntry': 'PD00-SSP-STG-nn-SUC-nn',
    'SubStageEntry': 'PD00-SSP-STG-nn-SUB-nn',
    'SystemDependencyEntry': 'PD00-CUR-SYS-DEP-DEP-nn',
    'SystemDependencyReferenceEntry': 'PD00-SYO-SYR-INV-nn-DEP-nn',
    'SystemIntegrationEntry': 'PD00-CUR-SYS-DEP-INT-nn',
    'SystemMigrationConsiderations': 'PD00-SYO-SYR-INV-nn-MIG',
    'SystemTaskEntry': 'PD00-SYO-SYD-USR-nn-TSK-nn',
    'TechnologyStandardEntry': 'PD00-SYO-RES-TEC-STD-nn',
    'TestScenarioEntry': 'PD00-DEL-ACC-UAT-nn',
    'ToolEntry': 'PD00-POP-TOO-TOO-nn',
    'TradeOffDecisionEntry': 'PD00-SYQ-PRI-TRA-nn',
    'TrainingRequirementEntry': 'PD00-ORG-WOR-nn-TRA-nn',
    'UiDesignPrincipleEntry': 'PD00-USE-VIS-PRI-nn',
    'UserAttributeEntry': 'PD00-ACC-USE-ATT-nn',
    'UserCategoryDefinition': 'PD00-ACC-USE-CAT-nn',
    'WorkflowActorEntry': 'PD00-CUR-PRO-nn-WOR-nn-ACT-nn',
    'WorkflowStepEntry': 'PD00-CUR-PRO-nn-WOR-nn-STP-nn',
}

ALL_IDS = {**AUTO_IDS, **MANUAL_IDS}

def process_file(filepath):
    """Process a single Dart file to add section IDs and cardinality."""
    with open(filepath) as f:
        lines = f.readlines()
    
    modified = False
    result = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Check if this is a class declaration
        class_match = re.match(r'^class\s+(\w+)', line)
        if class_match:
            cls_name = class_match.group(1)
            if cls_name in ALL_IDS and cls_name not in COMMON_TYPES:
                # Check if doc comment already has a section ID
                has_id = False
                j = len(result) - 1
                while j >= 0 and (result[j].strip().startswith('///') or result[j].strip() == ''):
                    if '[PD00-' in result[j] or '[PD00]' in result[j]:
                        has_id = True
                        break
                    j -= 1
                
                if not has_id:
                    # Find the last doc comment line before this class
                    j = len(result) - 1
                    while j >= 0 and result[j].strip() == '':
                        j -= 1
                    
                    if j >= 0 and result[j].strip().startswith('///'):
                        # Modify the last doc comment line to include the ID
                        old_comment = result[j].rstrip()
                        sid = ALL_IDS[cls_name]
                        
                        # Determine the comment type suffix
                        is_entry = '-nn' in sid
                        
                        # Check if comment already ends with a period or parenthetical
                        if old_comment.endswith('.'):
                            # Insert ID before the period
                            new_comment = old_comment[:-1] + f' [{sid}].\n'
                        elif old_comment.endswith(').'):
                            new_comment = old_comment[:-2] + f' [{sid}]).\n'
                        elif old_comment.endswith(')'):
                            new_comment = old_comment + f' [{sid}].\n'
                        else:
                            new_comment = old_comment + f' [{sid}].\n'
                        
                        result[j] = new_comment
                        modified = True
                    else:
                        # No doc comment exists - add one
                        sid = ALL_IDS[cls_name]
                        result.append(f'/// [{sid}].\n')
                        modified = True
        
        # Check if this is a List field without cardinality
        list_match = re.match(r'(\s+)List<(\w+)>\s+(\w+)\s*=\s*\[\];', line)
        if list_match:
            indent = list_match.group(1)
            type_name = list_match.group(2)
            field_name = list_match.group(3)
            
            # Check if preceding comment has cardinality
            has_card = False
            j = len(result) - 1
            while j >= 0 and (result[j].strip().startswith('///') or result[j].strip() == ''):
                content = result[j].lower()
                if 'contains' in content or '+×' in content or '+x' in content:
                    has_card = True
                    break
                if not result[j].strip().startswith('///') and result[j].strip() != '':
                    break
                j -= 1
            
            if not has_card:
                # Find the last doc comment line
                j = len(result) - 1
                while j >= 0 and result[j].strip() == '':
                    j -= 1
                
                if j >= 0 and result[j].strip().startswith('///'):
                    old_line = result[j].rstrip()
                    # Add cardinality marker
                    if old_line.endswith('.'):
                        # Remove period and add cardinality
                        type_display = type_name.replace('Entry', '')
                        new_line = old_line[:-1] + f' \u2014 contains 0+\u00d7 {type_display}.\n'
                    else:
                        type_display = type_name.replace('Entry', '')
                        new_line = old_line + f' \u2014 contains 0+\u00d7 {type_display}.\n'
                    result[j] = new_line
                    modified = True
                else:
                    # No doc comment - add one
                    type_display = type_name.replace('Entry', '')
                    result.append(f'{indent}/// Contains 0+\u00d7 {type_display}.\n')
                    modified = True
        
        result.append(line)
        i += 1
    
    if modified:
        with open(filepath, 'w') as f:
            f.writelines(result)
        return True
    return False


# Process all files
files = sorted(glob.glob(f'{MODEL_DIR}/*.dart') + glob.glob(f'{COMMON_DIR}/*.dart'))
changed = 0
for f in files:
    if process_file(f):
        changed += 1
        print(f'  Modified: {os.path.basename(f)}')
    else:
        print(f'  Unchanged: {os.path.basename(f)}')

print(f'\nDone. Modified {changed} files.')
